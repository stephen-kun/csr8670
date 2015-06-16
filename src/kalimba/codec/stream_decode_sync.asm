// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CODEC_STREAM_DECODE_SYNC_INCLUDED
#define CODEC_STREAM_DECODE_SYNC_INCLUDED

#include "codec_library.h"

// *****************************************************************************
// MODULE:
//    $codec.stream_decode_sync
//
// DESCRIPTION:
//    Decodes a codec stream (deals with overflow/underflow and attempts to
// handle the 'real' BT issues such as: packet jitter, non-perfect sample rates,
// going out of range, etc)
//
// INPUTS:
//    - r5 = pointer to a codec.stream_decode_sync structure
//          TODO fill this in
// *****************************************************************************
.MODULE $M.codec_stream_decode_sync;
   .CODESEGMENT CODEC_STREAM_DECODE_SYNC_PM;
   .DATASEGMENT DM;

   .VAR struc_ptr;

   $codec.stream_decode_sync:

   // push rLink onto stack
   $push_rLink_macro;

   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $codec.profile_stream_decode_sync[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED;
      r0 = &$codec.profile_stream_decode_sync;
      call $profiler.start;
   #endif

   // store the pointer to the codec structure
   M[struc_ptr] = r5;

   // go to where we left off
   r0 = M[r5 + $codec.stream_decode_sync.CURRENT_MODE_FIELD];
   if NZ jump r0;

      // if we are here this is startup, set the mode to stopped
      M[r5 + $codec.stream_decode_sync.STREAMING_FIELD] = $codec.stream_decode_sync.STREAMING_STOPPED;
      r0 = &read_sync_header;
      M[r5 + $codec.stream_decode_sync.CURRENT_MODE_FIELD] = r0;

   // --- read the sync head information ---
   read_sync_header:
/*
      // set the LED to 1 (6)
      r0 = M[$PIO_OUT];
      r0 = r0 AND (0xFFFF - 0x03C0);
      r0 = r0 OR  0x40;
      M[$PIO_OUT] = r0;
*/
      // how much data have we got
      r0 = M[r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      r4 = r0;
      if Z jump check_to_insert_silence_and_can_idle;

      // get the read address
      r0 = M[r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_read_address_and_size_and_start_address;
      push r2;
      pop B0;
#else
      call $cbuffer.get_read_address_and_size;
#endif
      I0 = r0;
      L0 = r1;

      // work through looking for the CS
      find_cs_loop:
         r4 = r4 - 1;
         // we need two words left over
         if LE jump set_read_address_and_check_silence;

         // look for ascii(CS) = 0x4353
         r0 = M[I0, 1];
         Null = r0 - 0x4353;
      if NZ jump find_cs_loop;

      // the next word should be asci(R?) = 0x52??
      r0 = M[I0, 0];
      r0 = r0 AND 0xFF00;
      Null = r0 - 0x5200;
      if NZ jump find_cs_loop;

      // check there is enough data left
      Null = r4 - 3;
      if NEG jump check_to_insert_silence_and_can_idle;

      // store the padding byte information
      r0 = M[I0, 1];
      M[r5 + $codec.stream_decode_sync.PADDING_BYTE_FIELD] = r0;

      // now get the time to play
      r0 = M[I0, 1];
      // don't increment over the last word
      r1 = M[I0, 0];
      r0 = r0 LSHIFT 8;
      r1 = r1 LSHIFT -8;
      r0 = r0 OR r1;

      // store this time
      M[r5 + $codec.stream_decode_sync.FRAME_PLAY_TIME_FIELD] = r0;

      // update the read pointer
      r0 = M[r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD];
      r1 = I0;
      call $cbuffer.set_read_address;
      L0 = 0;

      // change to decode if we have been initialised
      Null = M[r5 + $codec.stream_decode_sync.STREAMING_FIELD];
      if NZ jump calculate_warp_and_silence_amounts;

         // set the mode to initialise
         r0 = &do_initialise;
         M[r5 + $codec.stream_decode_sync.CURRENT_MODE_FIELD] = r0;

/*         // set the LED to 2 (7)
         r0 = M[$PIO_OUT];
         r0 = r0 AND (0xFFFF - 0x03C0);
         r0 = r0 OR  0x80;
         M[$PIO_OUT] = r0;
*/
      // -- re-initialise with info from the stream (samp rate etc.) --
      do_initialise:
         // call get frame info
         r0 = M[r5 + $codec.stream_decode_sync.GET_FRAME_INFO_ADDR_FIELD];
         r5 = r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD;
         call r0;

         // kick off the divide
         r5 = 0x3D09;
         rMAC0 = r5 LSHIFT 16;
         rMAC12 = r5 ASHIFT -8;
         Div = rMAC / r4;

         // was there enough data - the order may seem wrong but we should normally
         // pass this test so start the divide as soon as possible, then check
         Null = r0;
         if Z jump all_done_can_idle;

         // restore r5
         r5 = M[struc_ptr];

         // move the read address on to the start of the frame
         r0 = M[r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD];
         // r1 set by the frame info function
         call $cbuffer.set_read_address;

         // we have finished initialising set the current mode to do decode
         r0 = &decode_frame;
         M[r5 + $codec.stream_decode_sync.CURRENT_MODE_FIELD] = r0;

         // store the number of samples per micro-second i.e. divide by 1e6
         r4 = r4 * 8 (int);
         r0 = r4 * 407485 (frac);    // (2^23 - 8e6) / 8e6
         r4 = r4 + r0;
         M[r5 + $codec.stream_decode_sync.NUM_SAMPLES_PER_US_FIELD] = r4;
         // retrieve the result of the divide
         r4 = DivResult;
         M[r5 + $codec.stream_decode_sync.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD] = r4;

         // silence the decoder
         r0 = M[r5 + $codec.stream_decode_sync.SILENCE_ADDR_FIELD];
         call r0;

   // -- work out how much warp to request and if we need silence --
   calculate_warp_and_silence_amounts:

      // how many samples are in the system
      call calculate_samples_in_path;

      // convert the number of samples into a delay
      r0 = M[r5 + $codec.stream_decode_sync.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD];
      rMAC = r4 * r0;
      r4 = rMAC LSHIFT 13;

      // add this to the time
      r1 = r3 + r4;

      // get the time this frame should have been played
      r0 = M[r5 + $codec.stream_decode_sync.FRAME_PLAY_TIME_FIELD];

      // set to normal decode
      r4 = $codec.NORMAL_DECODE;

      // are we early or late?
      r0 = r0 - r1;

      // assume we are just slightly off - we only we need to warp
      r2 = M[r5 + $codec.stream_decode_sync.DELAY_TO_WARP_COEF_FIELD];
      r2 = r2 * r0 (int) (sat);
      r3 = r2 - 400000;   // MAX WARP TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      if GE r2 = r2 - r3;
      r3 = r2 + 400000;
      if LT r2 = r2 - r3;
      r3 = 0;

.VAR $out_by;
M[$out_by] = r0;

      if NEG jump we_are_late;
         // if we're stopped generate enough silence to start correctly
         Null = M[r5 + $codec.stream_decode_sync.STREAMING_FIELD];
         if Z jump generate_samples;
         // if we're playing and we've got too far off generate silence
         r1 = M[r5 + $codec.stream_decode_sync.MAX_PLAY_TIME_OFFSET_IN_US_FIELD];
         Null = r0 - r1;
         if NEG jump update_values;

         generate_samples:
            // set the warp to 0
            r2 = 0;
            // work out how many samples to generate
            r3 = M[r5 + $codec.stream_decode_sync.NUM_SAMPLES_PER_US_FIELD];
            r3 = r3 * r0 (frac);
         jump update_values;

      we_are_late:
         // if we're stopped gobble a frame to start correctly
         Null = M[r5 + $codec.stream_decode_sync.STREAMING_FIELD];
         if Z jump set_gobble_decode;
         // if we're playing and have got too far off gobble the next frame
         r1 = M[r5 + $codec.stream_decode_sync.MAX_PLAY_TIME_OFFSET_IN_US_FIELD];
         Null = r0 + r1;
         if POS jump update_values;

         set_gobble_decode:
            // we are too far off, don't decode the next frame
            r4 = $codec.GOBBLE_DECODE;
            r2 = 0;

      update_values:
         // store the values
         M[r5 + $codec.stream_decode_sync.REQUESTED_WARP_FIELD] = r2;
         M[r5 + $codec.stream_decode_sync.AMOUNT_OF_SILENCE_TO_GENERATE_FIELD] = r3;
         M[r5 + $codec.stream_decode_sync.DECODER_MODE_FIELD] = r4;

      // now set the state to decode frame
      r0 = &decode_frame;
      M[r5 + $codec.stream_decode_sync.CURRENT_MODE_FIELD] = r0;

   // -- attempt to decode the frame --
   decode_frame:
/*      // set the LED to 3 (8)
      r0 = M[$PIO_OUT];
      r0 = r0 AND (0xFFFF - 0x03C0);
      r0 = r0 OR  0x100;
      M[$PIO_OUT] = r0;
*/

      // if there is any silence to generate then do
      r6 = M[r5 + $codec.stream_decode_sync.AMOUNT_OF_SILENCE_TO_GENERATE_FIELD];
      if Z jump dont_generate_silence;
         call insert_silence;
         r0 = M[r5 + $codec.stream_decode_sync.AMOUNT_OF_SILENCE_TO_GENERATE_FIELD];
         r0 = r0 - r6;
         if NEG r0 = 0;
         M[r5 + $codec.stream_decode_sync.AMOUNT_OF_SILENCE_TO_GENERATE_FIELD] = r0;
         if NZ jump all_done_can_idle;
      dont_generate_silence:

      // set the mode
      r0 = M[r5 + $codec.stream_decode_sync.DECODER_MODE_FIELD];
      M[r5 + $codec.stream_decode_sync.MODE_FIELD] = r0;

      // attempt to decode a frame
      r0 = M[r5 + $codec.stream_decode_sync.ADDR_FIELD];
      r5 = r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD;
      call r0;

      // reload r5
      r5 = M[struc_ptr];

      // what mode did it end up in
      r0 = M[r5 + $codec.stream_decode_sync.MODE_FIELD];

      // if we didn't decode, must be out of space or data, if space we can idle
      Null = r0 - $codec.NOT_ENOUGH_OUTPUT_SPACE;
      if Z jump all_done_can_idle;

      // if data check if we need to generate silence and exit
      Null = r0 - $codec.NOT_ENOUGH_INPUT_DATA;
      if Z jump check_to_insert_silence_and_can_idle;

      // update the amount consumed
      r0 = M[r5 + ($codec.stream_decode_sync.IN_BUFFER_FIELD + $codec.DECODER_NUM_OUTPUT_SAMPLES_FIELD)];
      r1 = M[r5 + $codec.stream_decode_sync.AUDIO_SAMPLES_CONSUMED_FIELD];
      r1 = r1 + r0;
      M[r5 + $codec.stream_decode_sync.AUDIO_SAMPLES_CONSUMED_FIELD] = r1;

      // frame successfully decoded - set to playing in case we're not
      Null = M[r5 + $codec.stream_decode_sync.STREAMING_FIELD];
      if NZ jump already_playing;
         // only set to playing if we were not doing a frame gobble
         r0 = $codec.stream_decode_sync.STREAMING_PLAYING;
         r1 = M[r5 + $codec.stream_decode_sync.DECODER_MODE_FIELD];
         Null = r1 - $codec.GOBBLE_DECODE;
         if Z r0 = $codec.stream_decode_sync.STREAMING_STOPPED;
         M[r5 + $codec.stream_decode_sync.STREAMING_FIELD] = r0;

      already_playing:

      // change the mode to read sync header
      r1 = &read_sync_header;
      M[r5 + $codec.stream_decode_sync.CURRENT_MODE_FIELD] = r1;

      jump all_done_dont_idle;


   // set the read address of the in buffer and exit saying we can idle
   // on the next call we may flag out of input data
   set_read_address_and_check_silence:
      r0 = M[r5 + $codec.stream_decode_sync.IN_BUFFER_FIELD];
      r1 = I0;
      call $cbuffer.set_read_address;
      L0 = 0;

   // we are out of data check if we need to generate silence and exit
   check_to_insert_silence_and_can_idle:
      // we are short of data, how much data is in the system
      call calculate_samples_in_path;
      r0 = M[r5 + $codec.stream_decode_sync.GENERATE_SILENCE_THRESHOLD_FIELD];
      r4 = r4 - r0;
      if POS jump all_done_can_idle;

      // mark the stream as stopped and exit
      M[r5 + $codec.stream_decode_sync.STREAMING_FIELD] = $codec.stream_decode_sync.STREAMING_STOPPED;

      // insert silence - lots!
      r6 = -r4;
      call insert_silence;

      // Fall through...

   // exit and flag that we can idle as the audio buffer is already quite full
   all_done_can_idle:

      // Set for linear addressing
      L0 = 0;

      // stop profiling if enabled
      #ifdef ENABLE_PROFILER_MACROS
         r0 = &$codec.profile_stream_decode_sync;
         call $profiler.stop;
      #endif
      r0 = $codec.STREAM_CAN_IDLE;
      // pop rLink from stack
      jump $pop_rLink_and_rts;


   // exit and flag that we shoudn't idle as the audio buffer still needs filling
   all_done_dont_idle:

      // Set for linear addressing
      L0 = 0;

      // stop profiling if enabled
      #ifdef ENABLE_PROFILER_MACROS
         r0 = &$codec.profile_stream_decode_sync;
         call $profiler.stop;
      #endif
      r0 = $codec.STREAM_DONT_IDLE;
      // pop rLink from stack
      jump $pop_rLink_and_rts;




   // -- Insert silence --
   // r6 = maximum amount to output
   insert_silence:
      .CONST RAND_M   -4508331;
      .CONST RAND_C   11;

      // push rLink onto stack
      $push_rLink_macro;

      // set r6 to minimum amount of space available
      r0 = M[r5 + $codec.stream_decode_sync.OUT_LEFT_BUFFER_FIELD];
      if Z jump dont_check_left;
         call $cbuffer.calc_amount_space;
         Null = r6 - r0;
         if POS r6 = r0;
      dont_check_left:
      r0 = M[r5 + $codec.stream_decode_sync.OUT_RIGHT_BUFFER_FIELD];
      if Z jump dont_check_right;
         call $cbuffer.calc_amount_space;
         Null = r6 - r0;
         if POS r6 = r0;
      dont_check_right:

      // load starting random number
      r2 = M[r5 + $codec.stream_decode_sync.RAND_LAST_VAL_FIELD];
      // a good random number generating constant
      r3 = RAND_M;
      // gain for white noise insertion
      r4 = M[r5 + $codec.stream_decode_sync.COMFORT_NOISE_GAIN_FIELD];


      // add r6 words of zeros to each buffer
      r0 = M[r5 + $codec.stream_decode_sync.OUT_LEFT_BUFFER_FIELD];
      if Z jump dont_add_comfort_noise_left;
#ifdef BASE_REGISTER_MODE
         push r2;
         call $cbuffer.get_write_address_and_size_and_start_address;
         push r2;
         pop B0;
         pop r2;
#else
         call $cbuffer.get_write_address_and_size;
#endif
         I0 = r0;   L0 = r1;
         r10 = r6;
         do add_comfort_noise_left_loop;
            r2 = r2 * r3 (int);
            r2 = r2 + RAND_C;
            r0 = r2 * r4 (frac);
            M[I0,1] = r0;
         add_comfort_noise_left_loop:
         // store updated cbuffer pointers for left audio output
         r0 = M[r5 + $codec.stream_decode_sync.OUT_LEFT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_write_address;
      dont_add_comfort_noise_left:

      r0 = M[r5 + $codec.stream_decode_sync.OUT_RIGHT_BUFFER_FIELD];
      if Z jump dont_add_comfort_noise_right;
#ifdef BASE_REGISTER_MODE
         push r2;
         call $cbuffer.get_write_address_and_size_and_start_address;
         push r2;
         pop B0;
         pop r2;
#else
         call $cbuffer.get_write_address_and_size;
#endif
         I0 = r0;   L0 = r1;
         r10 = r6;
         do add_comfort_noise_right_loop;
            r2 = r2 * r3 (int);
            r2 = r2 + RAND_C;
            r0 = r2 * r4 (frac);
            M[I0,1] = r0;
         add_comfort_noise_right_loop:
         // store updated cbuffer pointers for right audio input
         r0 = M[r5 + $codec.stream_decode_sync.OUT_RIGHT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_write_address;
      dont_add_comfort_noise_right:
      L0 = 0;

      // store final random number
      M[r5 + $codec.stream_decode_sync.RAND_LAST_VAL_FIELD] = r2;

      // silence the decoder to avoid pops and squeeks when it starts decoding again
      r0 = M[r5 + $codec.stream_decode_sync.SILENCE_ADDR_FIELD];
      call r0;

      // pop rLink from stack
      jump $pop_rLink_and_rts;


   // -- calculate samples in data path --
   calculate_samples_in_path:
      // push rLink onto stack
      $push_rLink_macro;

      // block interrupts
      call $block_interrupts;

      // get the wall clock time
      r1 = r5 + $codec.stream_decode_sync.WALL_CLOCK_STRUC_FIELD;
      call $wall_clock.get_time;
      r3 = r1;
r0= M[$PIO_OUT];
r0 = r0 AND 0xFFF8;
r1 = r1 LSHIFT -13;
r1 = r1 AND 7;
r0 = r0 + r1;
M[$PIO_OUT] = r0;

      // should we look at the left or the right
      r4 = M[r5 + $codec.stream_decode_sync.LEFT_DAC_PORT_FIELD];
      r0 = M[r5 + $codec.stream_decode_sync.OUT_LEFT_BUFFER_FIELD];
      if NZ jump use_left;
         // use the right values instead
         r4 = M[r5 + $codec.stream_decode_sync.RIGHT_DAC_PORT_FIELD];
         r0 = M[r5 + $codec.stream_decode_sync.OUT_RIGHT_BUFFER_FIELD];
      use_left:

      // how much data in the cbuffer
      call $cbuffer.calc_amount_data;
      // store the number of samples
      r6 = r0;
      // load the port identifier
      r0 = r4;
      call $cbuffer.calc_amount_space;
      // convert from amount of space to amount of data
      r2 = r2 LSHIFT -1;
      r4 = r2 - r0;
      // minus 1 for wrapping
      r4 = r4 - 1;
      // add to the total
      r4 = r4 + r6;

      // unblock interrupts
      call $unblock_interrupts;

      // pop rLink from stack
      jump $pop_rLink_and_rts;


.ENDMODULE;

#endif
