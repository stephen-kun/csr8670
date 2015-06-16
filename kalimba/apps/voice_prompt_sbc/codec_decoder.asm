// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// DESCRIPTION
//    Decoder (SBC/MP3) for an audio playing device (non USB)
//
// *****************************************************************************
#define SELECTED_CODEC_FRAME_DECODE_FUNCTION          $sbcdec.frame_decode
#define SELECTED_CODEC_RESET_DECODER_FUNCTION         $sbcdec.reset_decoder
#define SELECTED_CODEC_SILENCE_DECODER_FUNCTION       $sbcdec.silence_decoder
#define SELECTED_CODEC_INITIALISE_DECODER_FUNCTION    $sbcdec.init_decoder

// 1.5ms is chosen as the interrupt rate for the audio input/output because:
// adc/dac mmu buffer is 256byte = 128samples
//                               - upto 8 sample fifo in voice interface
//                               = 120samples = 2.5ms @ 48KHz
// assume absolute worst case jitter on interrupts = 1.0ms
// Hence choose 1.5ms between audio input/output interrupts
#define TMR_PERIOD_AUDIO_COPY                         1500

// 8ms is chosen as the interrupt rate for the codec input/output as this is a
// good compromise between not overloading the xap with messages and making
// sure that the xap side buffer is emptied relatively often.
#define TMR_PERIOD_CODEC_COPY                         250

// includes
#include "core_library.h"
#include "cbops_library.h"
#include "codec_library.h"
#include "sbc_library.h"

#define VM_DAC_RATE_MESSAGE_ID                        0x7050
#define PLAY_BACK_FINISHED_MSG                        0x1080

.MODULE $M.main;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $main:

   // ** setup ports that are to be used **
   .CONST $AUDIO_LEFT_OUT_PORT                        ($cbuffer.WRITE_PORT_MASK + 0);
   .CONST $AUDIO_RIGHT_OUT_PORT                       ($cbuffer.WRITE_PORT_MASK + 1);
   .CONST $CODEC_IN_PORT                              ($cbuffer.READ_PORT_MASK  + 0);

   // ** allocate memory for cbuffers **
   .VAR/DMCIRC $audio_out_left[AUDIO_CBUFFER_SIZE];

   #ifndef FORCE_MONO
      .VAR/DMCIRC $audio_out_right[AUDIO_CBUFFER_SIZE];
   #endif //#ifndef FORCE_MONO

   .VAR/DMCIRC $codec_in[CODEC_CBUFFER_SIZE];

   // define memory location to receive dac sampling frequency from vm
   // zero(address or value) means not received
   .VAR $current_dac_sampling_frequency = 0;

   .VAR $get_dac_rate_from_vm_message_struc[$message.STRUC_SIZE];
   // ** allocate memory for cbuffer structures **
   .VAR $codec_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($codec_in),                     // size
         &$codec_in,                            // read pointer
         &$codec_in;                            // write pointer

   .VAR $audio_out_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_left),               // size
         &$audio_out_left,                      // read pointer
         &$audio_out_left;                      // write pointer

   #ifndef FORCE_MONO
      .VAR $audio_out_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_right),              // size
         &$audio_out_right,                     // read pointer
         &$audio_out_right;                     // write pointer
   #endif //#ifndef FORCE_MONO

   // ** allocate memory for timer structures **
   .VAR $codec_in_timer_struc[$timer.STRUC_SIZE];
   .VAR $audio_out_timer_struc[$timer.STRUC_SIZE];

   // ** allocate memory for codec input cbops copy routine **
   .VAR $codec_in_copy_struc[] =
      &$codec_in_copy_op,                       // first operator block
      1,                                        // number of inputs
      $CODEC_IN_PORT,                           // input
      1,                                        // number of outputs
      &$codec_in_cbuffer_struc;                 // output

   .BLOCK $codec_in_copy_op;
      .VAR $codec_in_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $codec_in_copy_op.func = &$cbops.copy_op;
      .VAR $codec_in_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         0,                                     // Input index
         1;                                     // Output index
   .ENDBLOCK;

#ifndef FORCE_MONO
   // ** allocate memory for stereo audio out cbops copy routine **
  .VAR $stereo_out_copy_struc[] =
      &$audio_out_dc_remove_op_left,            // first operator block
      2,                                        // number of inputs
      &$audio_out_left_cbuffer_struc,           // input
      &$audio_out_right_cbuffer_struc,          // input
      2,                                        // number of outputs
      $AUDIO_LEFT_OUT_PORT,                     // output
      $AUDIO_RIGHT_OUT_PORT;                    // output

   .BLOCK $audio_out_dc_remove_op_left;
      .VAR audio_out_dc_remove_op_left.next = &$audio_out_dc_remove_op_right;
      .VAR audio_out_dc_remove_op_left.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_left.param[$cbops.dc_remove.STRUC_SIZE] =
         0,                                     // Input index (left cbuffer)
         0,                                     // Output index (left cbuffer)
         0;                                     // DC estimate field
   .ENDBLOCK;

   .BLOCK $audio_out_dc_remove_op_right;
      .VAR audio_out_dc_remove_op_right.next = &$audio_out_compress_and_shift_op_left;
      .VAR audio_out_dc_remove_op_right.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_right.param[$cbops.dc_remove.STRUC_SIZE] =
         1,                                     // Input index (right cbuffer)
         1,                                     // Output index (right cbuffer)
         0;                                     // DC estimate field
   .ENDBLOCK;

  .BLOCK $audio_out_compress_and_shift_op_left;
      .VAR audio_out_compress_and_shift_op_left.next = &$audio_out_compress_and_shift_op_right;
      .VAR audio_out_compress_and_shift_op_left.func = &$cbops.compress_copy_op;
      .VAR audio_out_compress_and_shift_op_left.param[$cbops.compress_copy_op.STRUC_SIZE] =
         0,                                     // Input index (left cbuffer)
         2,                                     // Output index (left output port)
         -8;                                    // Shift right by 8bits
   .ENDBLOCK;

   .BLOCK $audio_out_compress_and_shift_op_right;
      .VAR audio_out_compress_and_shift_op_right.next = $cbops.NO_MORE_OPERATORS;
      .VAR audio_out_compress_and_shift_op_right.func = &$cbops.compress_copy_op;
      .VAR audio_out_compress_and_shift_op_right.param[$cbops.compress_copy_op.STRUC_SIZE] =
         1,                                     // Input index (right cbuffer)
         3,                                     // Output index (right output port)
         -8;                                    // Shift right by 8bits
   .ENDBLOCK;
#endif //#ifndef FORCE_MONO

  // ** allocate memory for mono audio out cbops copy routine **
   .VAR $mono_out_copy_struc[] =
      &$audio_out_dc_remove_op_mono,            // first operator block
      1,                                        // number of inputs
      &$audio_out_left_cbuffer_struc,           // input
      1,                                        // number of outputs
      $AUDIO_LEFT_OUT_PORT;                     // output

  .BLOCK $audio_out_dc_remove_op_mono;
      .VAR audio_out_dc_remove_op_mono.next = &$audio_out_compress_and_shift_op_mono;
      .VAR audio_out_dc_remove_op_mono.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_mono.param[$cbops.dc_remove.STRUC_SIZE] =
         0,                                     // Input index
         0,                                     // Output index
         0;                                     // DC estimate field
   .ENDBLOCK;
   .BLOCK $audio_out_compress_and_shift_op_mono;
      .VAR audio_out_compress_and_shift_op_mono.next = $cbops.NO_MORE_OPERATORS;
      .VAR audio_out_compress_and_shift_op_mono.func = &$cbops.compress_copy_op;
      .VAR audio_out_compress_and_shift_op_mono.param[$cbops.compress_copy_op.STRUC_SIZE] =
         0,                                     // Input index
         1,                                     // Output index
         -8;                                    // Shift right by 8bits
   .ENDBLOCK;

   //allocatiing memory for
   .VAR/DM1 $decoder_codec_stream_struc[$codec.av_decode.STRUC_SIZE] =
      SELECTED_CODEC_FRAME_DECODE_FUNCTION,     // frame_decode function
      SELECTED_CODEC_RESET_DECODER_FUNCTION,    // reset_decoder function
      SELECTED_CODEC_SILENCE_DECODER_FUNCTION,  // silence_decoder function
      &$codec_in_cbuffer_struc,                 // in cbuffer
      &$audio_out_left_cbuffer_struc,           // out left cbuffer
      #ifndef FORCE_MONO
         &$audio_out_right_cbuffer_struc,       // out right cbuffer
      #else
         0,
      #endif //#ifndef FORCE_MONO
      0,                                        // MODE_FIELD
      0,                                        // DECODER_NUM_OUTPUT_SAMPLES_FIELD
      0,
      GOOD_WORKING_BUFFER_LEVEL,
      POORLINK_DETECT_LEVEL,
      1,                                        // Enable codec in buffer purge when in pause
      &$master_app_reset,
      0 ...;                                    // Pad out remaining items with zeros

   // initialise the stack library
   call $stack.initialise;
   // initialise the interrupt library
   call $interrupt.initialise;
   // initialise the message library
   call $message.initialise;
   // initialise the cbuffer library
   call $cbuffer.initialise;

#if defined(DEBUG_ON)
   // initialise the profiler library
   call $profiler.initialise;
#endif

   // initialise the codec decoder library
   call SELECTED_CODEC_INITIALISE_DECODER_FUNCTION;

  // set up message handler for VM_DAC_SAMPLING_FREQUENCY_MESSAGE_ID message
   r1 = &$get_dac_rate_from_vm_message_struc;
   r2 = VM_DAC_RATE_MESSAGE_ID;
   r3 = &$get_dac_rate_from_vm;
   call $message.register_handler;

   // send music ready message, necessary to be compatible with vm
   r2 = 0x1000;
   call $message.send_short;

   // tell vm we're ready and wait for the go message
   call $message.send_ready_wait_for_go;

   // see if right output port is connected
   #ifndef FORCE_MONO
      r0 = $AUDIO_RIGHT_OUT_PORT;
      call $cbuffer.is_it_enabled;
      if NZ jump right_port_connected;
         // tell codec library that no right buffer
         M[$decoder_codec_stream_struc + $codec.stream_decode.OUT_RIGHT_BUFFER_FIELD] = 0;
      right_port_connected:
   #endif //#ifndef FORCE_MONO

   // wait for DAC buffers to have just wrapped around
   wait_for_dac_buffer_wraparound:
      r0 = $AUDIO_LEFT_OUT_PORT;
      call $cbuffer.calc_amount_space;
      // if the amount of space in the buffer is less than 16 bytes then a
      // buffer wrap around must have just ocurred.
      Null = r0 - 16;
   if POS jump wait_for_dac_buffer_wraparound;

    // start timer that copies codec input data
   r1 = &$codec_in_timer_struc;
   r2 = TMR_PERIOD_CODEC_COPY;
   r3 = &$codec_in_copy_handler;
   call $timer.schedule_event_in;

   // start timer that copies output samples
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in;

   // continually decode codec frames
   frame_loop:

      r5 = &$decoder_codec_stream_struc;
      call $codec.av_decode;

      r0 = M[&$decoder_codec_stream_struc + $codec.av_decode.MODE_FIELD];
      Null = r0 - $codec.SUCCESS;
      if NZ call $timer.1ms_delay;

   jump frame_loop;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $audio_out_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the mono or stereo copying
//    of decoded samples to the output.
//
// *****************************************************************************
.MODULE $M.audio_out_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $audio_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   #ifndef FORCE_MONO
      r8 = &$stereo_out_copy_struc;
      r7 = &$mono_out_copy_struc;
      // see if mono or stereo connection, based on whether the right output port
      // is enabled
      r0 = $AUDIO_RIGHT_OUT_PORT;
      call $cbuffer.is_it_enabled;
      if Z r8 = r7;
   #else
      r8 = &$mono_out_copy_struc;
   #endif

   // Call the copy routine
   call $cbops.dac_av_copy;

   // post another timer event
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $codec_in_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the copying of encoded
//    samples from the input.
//
// *****************************************************************************
.MODULE $M.codec_in_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec_in_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // copy data from the port to the cbuffer
   r8 = &$codec_in_copy_struc;
   call $cbops.copy;

   // post another timer event
   r1 = &$codec_in_timer_struc;
   r2 = TMR_PERIOD_CODEC_COPY;
   r3 = &$codec_in_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $get_dac_rate_from_vm
//
// DESCRIPTION: message handler for receiving DAC rate from VM
//
//
//  r1 = dac sampling rate
//  r4 = NZ means local file play back
// *****************************************************************************
.MODULE $M.get_dac_rate_from_vm;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $get_dac_rate_from_vm:

   .VAR $local_play_back = 1;

   r1 = r1 AND 0xFFFF;
   M[$current_dac_sampling_frequency] = r1;
   M[$local_play_back] = r4;
   rts;
.ENDMODULE;

// *****************************************************************************
//
// Master reset routine, called to clear garbage samples during a pause
// for local files, its sends a message to VM when playing finishes
//
// *****************************************************************************
.MODULE $M.master_app_reset;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $master_app_reset:
   // push rLink onto stack
   $push_rLink_macro;

   // local play back?
   Null = M[$local_play_back];
   if Z jump pause_happened;

      // notify VM about end of play_back
      r2 = PLAY_BACK_FINISHED_MSG;
      r3 = 0;
      r4 = 0;
      r5 = 0;
      r6 = 0;
      call $message.send_short;

   pause_happened:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
