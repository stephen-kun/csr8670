// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.comes/ Part of ADK 3.5
//
// $Change$  $DateTime$
// $Revision$
// *****************************************************************************
#ifndef SPDIF_FRAME_COPY_ASM_INCLUDED
#define SPDIF_FRAME_COPY_ASM_INCLUDED
#include "core_library.h"
#include "spdif.h"
#include "spdif_frame_copy.h"
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy
//
// DESCRIPTION:
//  The second part of spdif library is frame copy, it is responsible for
//  - handling fw low level events
//  - reading raw input data from spdif mmu ports
//  - seamless extracting pcm and coded data from input(IEC 61937)
//  - sending interesting events to the spdif stream decode sub library
//
// *****************************************************************************
.MODULE $spdif.frame_copy;
   .DATASEGMENT DM;

   .VAR chnl_sts_event_message_struc[$message.STRUC_SIZE];     // handling spdif channel status message
   .VAR block_start_message_struc[$message.STRUC_SIZE];        // handling spdif block start message
   .VAR valid_stream_event_message_struc[$message.STRUC_SIZE]; // handling spdif valid/invalid message
   .VAR invalid_delay_timer_struc[$timer.STRUC_SIZE];          // hysteresis timer for going from valid to invalid state
   .VAR frame_copy_struct;                                     // address of main spdif frame copy structure (single instance only)

   #ifdef DEBUG_ON
      .VAR trashed_data;  // number of trashed samples from spdif input buffer

       // define profile structure for copy_raw_data function
      .VAR/DM1 $spdif.profile_copy_raw_data[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED,
         0 ...;

       // define profile structure for frame copy main function
      .VAR/DM1 $spdif.profile_frame_copy[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED,
      0 ...;
   #endif

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.init
//
// DESCRIPTION:
//    initialises spdif frame copy sub library
//
// INPUTS:
//    r5 = spdif frame copy structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.init;
   .CODESEGMENT SPDIF_FRAME_COPY_INIT_PM;
   .DATASEGMENT DM;

   $spdif.frame_copy.init:

   // push rLink onto stack
   $push_rLink_macro;

   // save spdif frame copy structure's address
   M[$spdif.frame_copy.frame_copy_struct] = r5;

   // a reset is needed for first time run
   r0 = 1;
   M[r5 + $spdif.frame_copy.RESET_NEEDED_FIELD] = r0;

   // invalid input stream
   r0 = $spdif.STREAM_INVALID_FROM_FW;
   M[r5 + $spdif.frame_copy.STREAM_INVALID_FIELD] = r0;

   // register handlers for events from firmware
   call $spdif.frame_copy.register_spdif_stream_messages_handlers;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.reset
//
// DESCRIPTION:
//    Initialisations needed for processing data received from spdif ports
//
// INPUTS:
//    r5: spdif frame copy structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
//
// *****************************************************************************
.MODULE $M.spdif.frame_copy.reset;
   .CODESEGMENT SPDIF_FRAME_COPY_RESET_PM;
   .DATASEGMENT DM;

   $spdif.frame_copy.reset:

   // save copy structure
   M[$spdif.frame_copy.frame_copy_struct] = r5;

   // init reading state (looking for sync info)
   M[r5 + $spdif.frame_copy.READING_STATE_FIELD] = 0;

   // set the counter that waits for a good number of samples
   // before unmuting pcm
   M[r5 + $spdif.frame_copy.PCM_COUNTER_FIELD] = 0;

   // reset frame unsync counter
   M[r5 + $spdif.frame_copy.UNSYNC_COUNTER_FIELD] = 0;

   // reset done, clear the flag
   M[r5 + $spdif.frame_copy.RESET_NEEDED_FIELD] = Null;

   rts;

.ENDMODULE;
#ifdef $spdif.DSP_SPDIF_RATE_MEASUREMENT
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.rate_detect
//
// DESCRIPTION:
//   detects the input rate
//
// IMPORTANT NOTE:
//  This function expects to receive S/PDIF data from the port
//  regularly, if no data received in 3 consecutive run, then the
//  stream will be regarded as valid. 1ms ISR period for reading
//  S/PDIF data is recommended.
//
// INPUTS:
//   r8 = spdif frame copy structure
//   r7 = amount of input data just received
//
// OUTPUTS:
//   rate is updated
//
// TRASHED REGISTERS:
//    assume everything except r7 and r8
// *****************************************************************************
.MODULE $M.spdif.frame_copy.rate_detect;
   .CODESEGMENT SPDIF_FRAME_COPY_RATE_DETECT_PM;
   .DATASEGMENT DM;

   $spdif.frame_copy.rate_detect:

   // push rLink onto stack
   $push_rLink_macro;

   .VAR sample_rates[] = 48000, 44100, 32000;

   // get the current time
   // and store previous time
   r5 = M[$TIMER_TIME];
   r4 = M[r8 +  $spdif.frame_copy.RATE_DETECT_HIST_LAST_TIME_FIELD];
   M[r8 +  $spdif.frame_copy.RATE_DETECT_HIST_LAST_TIME_FIELD] = r5;


   // skip this time if fw just changed the rate
   r0 = M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_FW_RATE_CHNAGED_FIELD];
   M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_FW_RATE_CHNAGED_FIELD] = 0;
   Null = r0;
   if NZ jump $pop_rLink_and_rts;

   // compute the moving average of the
   // amount of data seen in the input
   I2 = r8 + $spdif.frame_copy.RATE_DETECT_HIST_FIELD;
   r1 = 255;
   r1 = MIN r7;
   // invalid if no data in 3 consecutive read
   r0 = M[I2, 1];   // amount[n-1]
   r3 = M[I2, -1];  // amount[n-2]
   r3 = r3 AND 0xFF;
   r2 = r0 AND 0xFF;
   r2 = r2 + r3;
   r2 = r1 + r2;    // r2 = amount[n]+amount[n-1]+amount[n-2]
   if NZ jump input_received;
   // invalid sample rate
   M[r8 + $spdif.frame_copy.MEASURED_SAMPLING_FREQ_FIELD] = 0;
   // clear amount history
   M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_INDEX_FIELD] = 0;
   // input stream is invalid because of no data
   r4 = 0;
   jump fs_found;

   input_received:
   // we have received input
   Null = M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_INDEX_FIELD];
   if NZ jump reset_done;

   // reset the rate history
   r2 = 0;
   I2 = r8 + $spdif.frame_copy.RATE_DETECT_HIST_FIELD;
   r10 = $spdif.RATE_DETECT_RATE_HIST_LENGTH + $spdif.RATE_DETECT_AMOUNT_HIST_LENGTH;
   do reset_rate_loop;
      M[I2, 1] = r2;
   reset_rate_loop:
   reset_done:
   // input and its time is stored in
   // the hist buffer: 0xttttmm
   // mm: amount received
   // tttt: diff time (16-bit)
   r4 = r4 - r5;
   if NEG r4 = -r4;
   I2 = r8 + $spdif.frame_copy.RATE_DETECT_HIST_FIELD;
   r10 = M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_INDEX_FIELD];
   r2 = 0;
   M0 = 1;
   r3 = r4 LSHIFT 8;
   r3 = r3 OR r1;
   r5 = 0;
   do calc_total_loop;
      // accumulate received values, and diff times
      // r2: values
      // r5: diff times      
      r3 = r0, M[I2, M0] = r3;
      r2 = r2 + r1, r0 = M[I2, 0];
      r5 = r5 + r4;
      r1 = r3 AND 0xFF;
      r4 = r3 LSHIFT -8;
   calc_total_loop:
   r1 = M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_INDEX_FIELD];
   Null = r1 - $spdif.RATE_DETECT_AMOUNT_HIST_LENGTH;
   if POS jump calc_total_done;
      r1 = r1 + 1, M[I2, M0] = r3;
      M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_INDEX_FIELD] = r1;
   calc_total_done:
   r1 = r5;
   if Z r1 = r1 + 1;
   // r2 = total samples received
   // r1 = duration in microsecond
   // calculate fs = samples/seconds=r2*1e6/r1
   rMAC = r2 * 2000000;
   rMAC = rMAC + r1*1;
   r1 = r1 LSHIFT 2;
   Div = rMAC / r1;
   r2 = DivResult;
   M[r8 + $spdif.frame_copy.MEASURED_SAMPLING_FREQ_FIELD] = r2;

   // r2 = estimated sample rate
   //  the past RATE_DETECT_AMOUNT_HIST_LENGTH ms
   // find nearest rate
   r5 = M[r8 + $spdif.frame_copy.DSP_SAMPLING_FREQ_FIELD];
   I2 = sample_rates;
   r10 = length(sample_rates);
   r3 = 0x1<<0;
   do find_nearest_loop;
      r1 = M[I2, 1];     // get the next sample rate
      r0 = r2 - r1;      // compute the diff
      r0 = ABS r0;       // abs diff
      r4 = r1 * $spdif.RATE_DETECT_ACCURACY(frac);
      Null = r5 - r1;    // if already in valid fs
      if Z r4 = r4 + r4; // tolerance is doubled
      Null = r0 - r4;    // see if within tolerance range
      if LE jump fs_calculated;
      r3 = r3 LSHIFT 8;
   find_nearest_loop:
   // no proper rate calculated
   r3 = 0;
   fs_calculated:

   // store a short history of detected rates
   // and find the one with majority
   I2 = r8 + ($spdif.frame_copy.RATE_DETECT_HIST_FIELD + $spdif.RATE_DETECT_AMOUNT_HIST_LENGTH);
   r10 = $spdif.RATE_DETECT_RATE_HIST_LENGTH - 1;
   r0 = M[I2, 0];
   r1 = r3;
   do find_mod_loop;
      r1 = r0, M[I2, M0] = r1;
      r3 = r3 + r1, r0 = M[I2, 0];
   find_mod_loop:
   M[I2, M0] = r1;

   // see which rate has majority
   r2 = $spdif.RATE_DETECT_INVALID_THRESHOLD;
   I2 = sample_rates;
   r10 = length(sample_rates);
   do rate_decision_loop;
      r0 = $spdif.RATE_DETECT_VALID_THRESHOLD;
      r4 = M[I2, 1];     // get next sample rate
      Null = r4 - r5;    // lower threshold if
      if Z r0 = r2;      // already in this rate
      r1 = r3 AND 0xFF;
      Null = r1 - r0;    // see if it has good majority
      if POS jump fs_found;
      r3 = r3 LSHIFT -8;
   rate_decision_loop:
   // none has the majority,
   // input stream is invalid because of inaccurate rate
   r4 = 0;
   fs_found:

   // see if rate has changed
   r3 = M[r8 + $spdif.frame_copy.DSP_SAMPLING_FREQ_FIELD];
   Null = r3 - r4;
   if Z jump $pop_rLink_and_rts;

   // rate has changed, store new detected rate
   M[r8 + $spdif.frame_copy.DSP_SAMPLING_FREQ_FIELD] = r4;

#ifdef $spdif.DSP_SPDIF_RATE_CHECK
   // raise an event to update the system
   push r7;
   push r8;
   call $spdif.frame_copy.process_valid_rate_message;
   pop r8;
   pop r7;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.copy_raw_data
//
// DESCRIPTION:
//   reads raw spdif input from spdif input ports
//   This function reads samples from L and R ports and interleaves
//   them into spdif input buffer, the function is called in ISR and
//   in fact it can be written as a cbops operator too.
//
//   The function reads all the data available in ports, therefore if there is not enough
//   space in the output buffer it will trash some data.
//
// INPUTS:
//   r8 = spdif frame copy structure
//
// OUTPUTS:
//   r7 = number of samples read from each port
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.copy_raw_data;
   .CODESEGMENT SPDIF_FRAME_COPY_COPY_RAW_DATA_PM;
   .DATASEGMENT DM;

   $spdif.copy_raw_data:

   // push rLink onto stack
   $push_rLink_macro;

   // -- Start overall profiling if enabled --
   PROFILER_START_SPDIF(&$spdif.profile_copy_raw_data);

   // get amount data available in left input port
   r0 = M[r8 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r7 = r0;

   // get amount data available in right input port
   r0 = M[r8 + $spdif.frame_copy.RIGHT_INPUT_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r7 = MIN r0;

#ifdef $spdif.DSP_SPDIF_RATE_MEASUREMENT
   // detect input rate
   call $spdif.frame_copy.rate_detect;
#endif

   // end process if there isn't any input
   Null = r7;
   if Z jump end;

   // get left port read address
   r0 = M[r8 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   // get right port read address
   r0 = M[r8 + $spdif.frame_copy.RIGHT_INPUT_PORT_FIELD];
   call $cbuffer.get_read_address_and_size;
   I1 = r0;
   L1 = r1;

   // get the amount of space in the input buffer
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r6 = r0 LSHIFT -1;
   r6 = r6 - 2;
   if NEG r6 = 0;

   // trash all input data if stream is invalid
   Null = M[r8 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   if NZ r6 = 0;

   // see if there is enough space in the output buffer
   r0 = r7 - r6;
   if LE jump read_data;
      // throw away extra input to make sure all data from ports will be read
      #ifdef DEBUG_ON
         r2 = M[$spdif.frame_copy.trashed_data];
         r2 = r2 + r0;
         r2 = r2 + r0;
         M[$spdif.frame_copy.trashed_data] = r2;
      #endif
      r10 = r0;
      do trash_loop;
         r0 = M[I0,1];
         r1 = M[I1,1];
      trash_loop:
      r3 = r6;
      r4 = r7;
   read_data:
   r6 = MIN r7;
   if Z jump end_reading_input;

   // get output buffer write address
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   // read from left port and write to even positions of output interleaved buffer
   r10 = r6 - 1;
   I3 = I4;
   r0 = M[I0, 1];
   do read_left_raw_data_loop;
      r0 = M[I0,1], M[I4,2] = r0;
   read_left_raw_data_loop:
   M[I4,2] = r0;

   // read from right port and write to even positions of output interleaved buffer
   r10 = r6 - 1;
   I4 = I3;
   r0 = M[I1, 1], r1 = M[I4,1];
   do read_right_raw_data_loop;
      r0 = M[I1,1], M[I4,2] = r0;
   read_right_raw_data_loop:
   M[I4,1] = r0;

   // set output buffer write address
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   r1 = I4;
   call $cbuffer.set_write_address;
   L4 = 0;

   end_reading_input:
   // set left port read address
   r0 = M[r8 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
   r1 = I0;
   call $cbuffer.set_read_address;
   L0 = 0;

   // set right port read address
   r0 = M[r8 + $spdif.frame_copy.RIGHT_INPUT_PORT_FIELD];
   r1 = I1;
   call $cbuffer.set_read_address;
   L1 = 0;

   end:

   // no input is assume for invalid stream
   Null = M[r8 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   if NZ r7 = 0;

   // -- Stop overall profiling if enabled --
   PROFILER_STOP_SPDIF(&$spdif.profile_copy_raw_data)

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.open_buffers:
//
// DESCRIPTION:
//   open input and output buffers
//
// INPUTS:
//   r8 = spdif input structure
//
// OUTPUTS:
//   I4/L4 = coded buffer or left pcm write address for pcm mode
//   I5/L5 = write pcm write address for pcm mode
//   I0/L0 = read address for spdif input buffer
//   I1/L1 = same as I0, with one word circular shift
//   M2 = -2
//   M1 = 2
//   M0 = 1
//   M3 = 6
//   I2 = pcm counter
//
// TRASHED REGISTERS:
//   assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.open_buffers;
   .CODESEGMENT SPDIF_FRAME_COPY_OPEN_BUFFERS_PM;
   .DATASEGMENT DM;

   $spdif.frame_copy.open_buffers:

   // push rLink onto stack
   $push_rLink_macro;

   // make sure input buffer is not full
   M2 = $spdif.INPUT_BUFFER_MIN_SPACE;
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   Null = r0 - M2;
   if POS M2 = 0;
   // M2 now is the amount of data will be thrown away
   // from the buffer before processing

   // get the input buffer info buffer
   // I0 -> LEFT samples
   // I1 -> RIGHT samples
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;
   r0 = M[I0,M2];
   I1 = I0;
   L1 = L0;
   r0 = M[I1,1];

   // get the amount data available in the buffer
   // considering the amount that is needed to purge
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   r0 = r0 - M2;

#ifdef DEBUG_ON
   // always the amount of data in the buffer must
   // be an even number
   Null = r0 AND 1;
   if NZ call $error;

   r2 = M[$spdif.frame_copy.trashed_data];
   r2 = r2 + M2;
   M[$spdif.frame_copy.trashed_data] = r2;
#endif

   // r7 = amount of input L/R data to process
   r7 = r0 LSHIFT -1;

#ifndef SPDIF_PCM_SUPPORT_ONLY
   // see if in pcm mode
   r0 = M[r8 + $spdif.frame_copy.CODEC_TYPE_FIELD];
   Null = r0 - $spdif.DECODER_TYPE_PCM;
   if LE jump set_pcm_buffers;

   // in coded mode
   r0 = M[r8 + $spdif.frame_copy.CODED_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r6 = r0 LSHIFT -1;

   // open the coded buffer
   r0 = M[r8 + $spdif.frame_copy.CODED_BUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   jump end;
set_pcm_buffers:
#endif // #ifndef SPDIF_PCM_SUPPORT_ONLY
   // in pcm mode
   // open  left pcm buffers
   r0 = M[r8 + $spdif.frame_copy.LEFT_PCM_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r6 = r0;
   r0 = M[r8 + $spdif.frame_copy.LEFT_PCM_BUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;
   // open  right pcm buffers
   r0 = M[r8 + $spdif.frame_copy.RIGHT_PCM_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r6 = MIN r0;
   r0 = M[r8 + $spdif.frame_copy.RIGHT_PCM_BUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   I5 = r0;
   L5 = r1;

end:
   // set a few M registers that used during decode process
   M2 = -2;
   M1 = 2;
   M0 = 1;
   M3 = 6;
   r0 = M[r8 + $spdif.frame_copy.PCM_COUNTER_FIELD];
   I2 = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.close_buffers:
//
// DESCRIPTION:
//   closes input and output buffers, this might happen when switching buffers
//   or when decoding process ends
//
// INPUTS:
//   r8 = spdif input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//
// *****************************************************************************
.MODULE $M.spdif.frame_copy.close_buffers;
   .CODESEGMENT SPDIF_FRAME_COPY_CLOSE_BUFFERS_PM;
   .DATASEGMENT DM;

   $spdif.frame_copy.close_buffers:

   // push rLink onto stack
   $push_rLink_macro;

   // close input buffer
   r1 = I0;
   r0 = M[r8 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.set_read_address;
   L0 = 0;
   L1 = 0;

   // save pcm counter
   r0 = I2;
   M[r8 + $spdif.frame_copy.PCM_COUNTER_FIELD] = r0;

#ifndef SPDIF_PCM_SUPPORT_ONLY
   // if L5 != 0 it means pcm buffers are open
   Null = L5;
   if NZ jump close_pcm_buffers;

   // if only L4 != 0, it means coded buffer is open
   Null = L4;
   if Z jump $pop_rLink_and_rts;

   // close coded buffer
   r0 = M[r8 + $spdif.frame_copy.CODED_BUFFER_FIELD];
   r1 = I4;
   call $cbuffer.set_write_address;
   L4 = 0;
   jump $pop_rLink_and_rts;

   close_pcm_buffers:
#endif  // #ifndef SPDIF_PCM_SUPPORT_ONLY

   // close left pcm buffer
   r0 = M[r8 + $spdif.frame_copy.LEFT_PCM_BUFFER_FIELD];
   r1 = I4;
   call $cbuffer.set_write_address;
   L4 = 0;

   // close right pcm buffer
   r0 = M[r8 + $spdif.frame_copy.RIGHT_PCM_BUFFER_FIELD];
   r1 = I5;
   call $cbuffer.set_write_address;
   L5 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif.set_codec_type
//
// DESCRIPTION:
//    set the codec type, if codec type changes it forces exit,
//    smooth transition when switching from one codec type to another type
//    is managed by stream decode module
//
// INPUTS:
//   r3 = new codec type to set
//
// OUTPUTS:
//
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.set_codec_type;
   .CODESEGMENT SPDIF_FRAME_COPY_SET_CODEC_TYPE_PM;
   .DATASEGMENT DM;

$spdif.frame_copy.set_codec_type:

   // get current codec type
   r4 = M[r8 + $spdif.frame_copy.CODEC_TYPE_FIELD];
   M[r8 + $spdif.frame_copy.CODEC_TYPE_FIELD] = r3;
   Null = r4 - r3;
   if Z rts;

   // push rLink onto stack
   $push_rLink_macro;

   call $spdif.frame_copy.close_buffers;
   call $spdif.frame_copy.open_buffers;

   // force exit
   r7 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.decode
//
// DESCRIPTION:
//   extract audio data from spdif input and copy them into either pcm or
//   coded output buffers, input buffer contains interleaved LEFT and RIGHT samples
//   from SPDIF ports, either in PCM or Coded format.
//
// INPUTS:
//   r5 = spdif frame copy input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy;
   .CODESEGMENT SPDIF_FRAME_COPY_PM;
   .DATASEGMENT DM;
   $spdif.frame_copy:

   // jump table for processing input stream
   .VAR spdif_in_state_proc[] =
           looking_for_sync_info,    // looking for sync info
           handle_pcm,               // pcm mute
           handle_pcm,               // pcm fade-in
           handle_pcm                // pcm pass through
           #ifndef SPDIF_PCM_SUPPORT_ONLY
           ,loading_codec_data,      // copying coded data into coded buffer
           handle_IEC_61937_Pa_Pz,   // processing last word of IEC-61937 preamble for unaligned input
           read_stuffing_data        // reading stuffing data
           #endif
           ;


   // push rLink onto stack
   $push_rLink_macro;

   // -- Start overall profiling if enabled --
   PROFILER_START_SPDIF(&$spdif.profile_frame_copy);

   // see whether reset is needed
   Null = M[r5 + $spdif.frame_copy.RESET_NEEDED_FIELD];
   if NZ call $spdif.frame_copy.reset;

   // hereafter r8 is the structure address
   r8 = r5;

   // open input and output buffers, they will remain open until
   // end of processing or when a codec type change is
   // detected
   call $spdif.frame_copy.open_buffers;

   // set the output results:
   // we process input data as much as we can however
   // for efficiency we don't return success unless we
   // have a minimum amount of input data and a minimum
   // amount of output space in the buffers.
   r4 = $spdif.SUCCESS;
   r1 = $spdif.NOT_ENOUGH_OUTPUT_SPACE;
   r2 = $spdif.NOT_ENOUGH_INPUT_DATA;
   Null = r7 - $spdif.MIN_INPUT_DATA_SUCCESS;
   if NEG r4 = r2;
   Null = r6 - $spdif.MIN_OUTPUT_SPACE_SUCCESS;
   if NEG r4 = r1;
   M[r8 + $spdif.frame_copy.MODE_FIELD] = r4;

   // <--- AT This point and while in the processing loop -->
   // r8     =     spdif frame copy input structure
   // r7     =     amount data left in input ports
   // r6     =     amount space left in output buffer(s)
   // I0/L0  =     input LEFT samples
   // I1/L1  =     input RIGHT samples
   // I4/L4  =     output LEFT pcm buffer / output coded buffer
   // I5/L5  =     output RIGHT pcm buffer
   // M0     = 1
   // M1     = 2
   // M2     = -2
   // M3     = 6
   // I2     =     pcm counter

   procecssing_loop_start_point:

      // exit process loop if ran out of either input data or output space
      r1 = M[r8 + $spdif.frame_copy.READING_STATE_FIELD];
      r0 = r6*r7(int)(sat);
      if Z jump end_process;

      // call proper state handler
      r0 = M[r1 + spdif_in_state_proc];
      jump r0;

   end_process:

   // close output buffers
   call $spdif.frame_copy.close_buffers;

   // -- Stop overall profiling if enabled --
   PROFILER_STOP_SPDIF(&$spdif.profile_frame_copy)

   // pop rLink from stack
   jump $pop_rLink_and_rts;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.decode.handle_pcm
//
// DESCRIPTION:
// handling pcm mode:
// pcm mute:
//     writing silence into output buffers, input buffer is continuously being checked
//     for existing of IEC_61937 preambles, if seen it might switch to codec mode. if
//     activity is seen in either ports for a minimum predefined time it will switch to
//     unmute pcm mode.
//
// pcm_unmute:
//     writing pcm data into output buffers, input buffer is continuously being checked
//     for existing of IEC_61937 preambles, if seen it might switch to codec mode. it
//     will never switch back to pcm mute mode
//
// pcm_fade_in:
//     same as pcm_unmute, lasts only for a limited number of pcm samples and during that
//     time a fading in factor is applied
//
// INPUTS:
//   r8 = spdif input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTE:
//    PCM states are run per sample, so code size has been compromised in
//    favour of cpu cycles
// *****************************************************************************

   handle_pcm:
   .VAR handle_pcm_tab[] = handle_pcm_mute,handle_pcm_unmute,handle_pcm_fade_in;

   // read new L/R samples and also two older samples
   // r4 = L[n],   r5 = R[n]
   // r2 = L[n-1], r3 = R[n-1]
   r4 = M[I0,M2];
   r7 = r7 - M0, r5 = M[I1,M2];
   r0 = r4 OR r5, r2 = M[I0,M2];
   r0 = r0 OR r2, r3 = M[I1,M2];
   r0 = r0 OR r3, rMAC = M[I0,M3];
   r0 = r0 OR rMAC, rMAC = M[I1,M3];
   r0 = r0 OR rMAC;
   // if last three sample are zero
   // for both channels, then this shall
   // be muted
   if Z jump reset_pcm_counter;

   // check for the Pa preamble
   Null = r2 - $spdif.IEC_61937_Pa;
   if Z jump IEC_61937_Pa_Px_found;

   Null = r3 - $spdif.IEC_61937_Pa;
   if Z jump IEC_61937_Px_Pa_found;

   jump_to_pcm_handler:
   // no preamble seen, now jump to proper point
   r1 = M[r1 + (handle_pcm_tab-$spdif.state.PCM_MUTE)];
   jump r1;

// ****************************************************
// handle pcm mute state
// ****************************************************
handle_pcm_mute:
   r0 = 0;
   // if channel status shows data then ignore pcm detect,
   // the other way will not be enforced, i.e. if channel
   // status shows pcm, we still check for data
   r1 = M[r8 + $spdif.frame_copy.CHSTS_DATA_MODE_FIELD];
   if NZ jump reset_pcm_counter;

   // We need to see a minimum activity time in L/R
   // before unmuting PCM, we cannot have a look ahead
   // buffer due to memory needed, so we might loose around
   // 50ms of data at the beginning of playing
   I2 = I2 + M0;
   Null = I2 - ($spdif.MIN_PCM_ACTIVITY_SAMPLES);
   if NEG jump write_pcm_silence;
      // start playing pcm samples,
      r3 = $spdif.DECODER_TYPE_PCM;
      call $spdif.frame_copy.set_codec_type;
      // first a fade-in period
      r1 = $spdif.state.PCM_FADE_IN;
      M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r1;
      M[r8 + $spdif.frame_copy.PCM_FADE_IN_INDEX_FIELD] = 0;
   reset_pcm_counter:
   I2 = Null;
   write_pcm_silence:
   M[I4,M0] = r0;
   r6 = r6 - M0, M[I5,M0] = r0;
   jump procecssing_loop_start_point;

// ****************************************************
// handle pcm fade in state
// ****************************************************
handle_pcm_fade_in:
   // apply fade in factor for $spdif.frame_copy.PCM_FADE_IN_SAMPLES sample
   r0 = M[r8 + $spdif.frame_copy.PCM_FADE_IN_INDEX_FIELD];
   r1 = r0 * (1.0/$spdif.PCM_SWITCH_FADE_IN_SAMPLES)(int)(sat);
   r2 = r2 LSHIFT 8;
   r3 = r3 LSHIFT 8;
   r2 = r2 * r1 (frac);
   r3 = r3 * r1 (frac);
   r0 = r0 + M0, M[I4,M0] = r2;
   r6 = r6 - M0, M[I5,M0] = r3;
   M[r8 + $spdif.frame_copy.PCM_FADE_IN_INDEX_FIELD] = r0;
   Null = r0 - $spdif.PCM_SWITCH_FADE_IN_SAMPLES;
   if NEG jump procecssing_loop_start_point;
      // fade in time ended, now switch to full pcm
      r0 = $spdif.state.PCM_UNMUTE;
      M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r0;
  jump procecssing_loop_start_point;

// ****************************************************
// handle pcm unmute state
// ****************************************************
handle_pcm_unmute:
   r2 = r2 LSHIFT 8;
   r3 = r3 LSHIFT 8;
   M[I4,M0] = r2;
   r6 = r6 - M0, M[I5,M0] = r3;
   jump procecssing_loop_start_point;

// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.decode.looking_for_sync_info
//
// DESCRIPTION:
//   State handler for $spdif.state.LOOKING_FOR_SYNC_INFO spdif state, decoder
//   continuously is looking for IEC_61937 preambles, once found it will further
//   process them to see whether coded data are coming from spdif input ports.
//
// INPUTS:
//   r8 = spdif input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
looking_for_sync_info:

   // read new L/R samples and also two older samples
   // r4 = L[n],   r5 = R[n]
   // r2 = L[n-1], r3 = R[n-1]
   // r0 = L[n-2], r1 = R[n-2]
   r4 = M[I0,M2];
   r5 = M[I1,M2];
   r2 = M[I0,M2];
   r3 = M[I1,M2];
   r0 = M[I0,M3];
   r7 = r7 - M0, r1 = M[I1,M3];
   r1 = r0 OR r1;
   if NZ jump check_switch_to_pcm_time;

   // check for the Pa preamble
   Null = r2 - $spdif.IEC_61937_Pa;
   if Z jump IEC_61937_Pa_Px_found;

   Null = r3 - $spdif.IEC_61937_Pa;
   if NZ jump check_switch_to_pcm_time;

   IEC_61937_Px_Pa_found:
      // Px_Pa found, its probably a swapped stream
      r0 = r3;
      r1 = r2;
      r4 = r4 XOR r5;
      r5 = r4 XOR r5;
      r4 = r4 XOR r5;
      I6 = 1;
   jump IEC_61937_Pa_found;

   IEC_61937_Pa_Px_found:
   // Pa_Px found, stream is not swapped
   I6 = 0;
   r0 = r2;
   r1 = r3;
   IEC_61937_Pa_found:

   // I6 shows whether stream is swapped
   Null = r1 - $spdif.IEC_61937_Pb;
   if Z jump IEC_61937_Pa_Pb_found;

   IEC_61937_Pa_Pz_found:
   // L = Pa, R = Pz, see if Pb is seen
   // in next R sample, if not no pre-amble check.
   Null = r5 - $spdif.IEC_61937_Pb;
   if Z jump IEC_61937_Pb_Pa_found;

// ---------------------------------------------
// new input words processed, and no valid and
// supported data type found, now continue in
// the same state
// -----------------------------------------------
looking_for_sync_info_done:
   // if in pcm mode, stay in pcm mode
   r1 = M[r8 + $spdif.frame_copy.READING_STATE_FIELD];
   if NZ jump jump_to_pcm_handler;

   // see if time to switch to pcm(mute)
   check_switch_to_pcm_time:
   // increment unsync counter
   r3 = M[r8 + $spdif.frame_copy.UNSYNC_COUNTER_FIELD];
   r3 = r3 + 1;
   M[r8 + $spdif.frame_copy.UNSYNC_COUNTER_FIELD] = r3;

   // switch to PCM mode if unsynced for more than
   // certain number of samples
   Null = r3 - $spdif.MAX_UNSYNC_SAMPLES;
   if NEG jump pcm_switch_done;
         // switch to pcm mode
         r3 = $spdif.DECODER_TYPE_PCM_MUTE;
         call $spdif.frame_copy.set_codec_type;
         M[r8 + $spdif.frame_copy.UNSYNC_COUNTER_FIELD] = 0;
         r0 = $spdif.state.PCM_MUTE;
         M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r0;
         I2 = 0;
         M[r8 + $spdif.frame_copy.STUFFING_DATA_LENGTH_FIELD] = 0;
         M[r8 + $spdif.frame_copy.PAY_LOAD_LEFT_FIELD] = 0;
   pcm_switch_done:
   jump procecssing_loop_start_point;

#ifdef SPDIF_PCM_SUPPORT_ONLY
   IEC_61937_Pb_Pa_found:
   IEC_61937_Pa_Pb_found:
#endif
// --------------------------------------------
// invalid_pa_found, if no supported data type is
// seen nor is it detected as PCM input then the
// output will be muted.
// --------------------------------------------
invalid_pa_found:
   // star looking for a fresh new burst
   //r2 = $spdif.state.LOOKING_FOR_SYNC_INFO;
   //M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r2;
   r1 = $spdif.MAX_UNSYNC_SAMPLES;
   M[r8 + $spdif.frame_copy.UNSYNC_COUNTER_FIELD] = r1;
   I2 = 0;
   r0 = M[r8 + $spdif.frame_copy.READING_STATE_FIELD];
   if Z jump check_switch_to_pcm_time;
   r0 = $spdif.state.PCM_MUTE;
   M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r0;
   jump looking_for_sync_info_done;

#ifndef SPDIF_PCM_SUPPORT_ONLY
   IEC_61937_Pb_Pa_found:
   // stream is not aligned, R is shifted by one sample
   I7 = $spdif.STREAM_ALIGNMENT_SHIFTED;
   jump get_codec_type;

   IEC_61937_Pa_Pb_found:
   //r2 = Pa, r3 = Pb, r4 = Pc, r5 = Pd
   I7 = $spdif.STREAM_ALIGNMENT_NORMAL;

   // calculate burst pay load length in words
   r1 = r5 + 15;
   r1 = r1 LSHIFT -4;
   M[r8 + $spdif.frame_copy.PAY_LOAD_LENGTH_FIELD] = r1;
   M[r8 + $spdif.frame_copy.PAY_LOAD_LEFT_FIELD] = r1;

// -----------------------------------------------------------------
// A valid IEC-61937 header has been found, now decide what to do
// with the frame. Coded data are extracted only for some data types,
// otherwise they will be discarded and flagged as 'unsupported'. To
// extract coded data the data type must be supported by this library
// (see table below to see what codecs are supported, also the higher
// layer(stream decode) has to support the data type by properly
// configuring the input structure.
//
// ------------------------------------------------------------------
get_codec_type:
   // valid IEC_61937 has been found, pcm output
   // mut be muted now
   I2 = Null;

   // see if the burst is valid
   r1 = r4 AND 0x80;
   if NZ jump invalid_burst_found;

   // extract the data type
   r1 = r4 AND 0x1F;
   Null = r1 - 24;
   if POS jump unsupported_burst_found;

   // see whether the codec type is supported by stream-decode l
   r0 = M[r8 + $spdif.frame_copy.SUPPORTED_CODEC_TYPES_BITS_FIELD];
   r0 = r0 OR ($spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_NULL) | $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_PAUSE));
   r2 = 1 LSHIFT r1;
   r2 = r2 AND r0;
   if Z jump unsupported_burst_found;
   r0 = M[r1 + codec_support_jump_table];
   jump r0;

   // codec support jump table
   .VAR codec_support_jump_table[] =
      null_burst_found,           // NULL(0)
      ac3_burst_found,            // AC3(1)
      reserved_burst_found,       // RESERVED(2)
      pause_burst_found,          // PAUSE(3)
      unsupported_burst_found,    // MPEG1_LAYER1(4)
      mpeg1_layer23_burst_found,  // MPEG1_LAYER23(5)
      unsupported_burst_found,    // MPEG2_EXTENTION(6)
      mpeg2_aac_burst_found,      // MPEG2_AAC(7)
      unsupported_burst_found,    // MPEG2_LAYER1_LSF(8)
      unsupported_burst_found,    // MPEG2_LAYER2_LSF(9)
      unsupported_burst_found,    // MPEG2_LAYER3_LSF(10)
      unsupported_burst_found,    // DTS1(11)
      unsupported_burst_found,    // DTS2(12)
      unsupported_burst_found,    // DTS3(13)
      unsupported_burst_found,    // ATRAC(14)
      unsupported_burst_found,    // ATRAC3(15)
      unsupported_burst_found,    // ATRACX(16)
      unsupported_burst_found,    // DTSHD(17)
      unsupported_burst_found,    // WMAPRO(18)
      unsupported_burst_found,    // MPEG2_AAC_LSF(19)
      reserved_burst_found,       // RESERVED(20)
      unsupported_burst_found,    // EAC3(21)
      unsupported_burst_found,    // TRUEHD(22)
      reserved_burst_found;       // RESERVED(23)

// ------------------------------
// AC-3 data type
// ------------------------------
ac3_burst_found:
    r0 = $spdif.AC3_AUDIO_FRAME_LENGTH;
    r1 = $spdif.DECODER_TYPE_AC3;
    jump supported_coded_burst;

// ------------------------------
// MPEG1 Layer 2 and 3 data type
// ------------------------------
mpeg1_layer23_burst_found:
    r0 = $spdif.MPEG1_LAYER23_AUDIO_FRAME_LENGTH;
    r1 = $spdif.DECODER_TYPE_MPEG1_LAYER23;
    jump supported_coded_burst;

// ------------------------------
// MPEG2 AAC data type
// ------------------------------
mpeg2_aac_burst_found:
    r0 = $spdif.MPEG2_AAC_FRAME_LENGTH;
    r1 = $spdif.DECODER_TYPE_MPEG2_AAC;
    jump supported_coded_burst;

// -----------------------------------------
// common point for all supported  data types
// ----------------------------------------
supported_coded_burst:
    // r0 = number of audio samples
    // r1 = codec type
   M[r8 + $spdif.frame_copy.NEW_CODEC_AUDIO_FRAME_SIZE_FIELD] = r0;
   M[r8 + $spdif.frame_copy.NEW_CODEC_TYPE_FIELD] = r1;

   M[r8 + $spdif.frame_copy.UNSYNC_COUNTER_FIELD] = Null;
   r0 = I6;
   M[r8 + $spdif.frame_copy.STREAM_SWAPPED_FIELD] = r0;
   r1 = I7;
   M[r8 + $spdif.frame_copy.STREAM_ALIGNMENT_FIELD] = r1;
   if Z jump switch_to_loading_coded_data;

   supported_unaligned:
   r2 = $spdif.state.IEC_61937_Pa_Pz;
   M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r2;
   jump procecssing_loop_start_point;

// --------------------------------------------
// invalid burst
// --------------------------------------------
invalid_burst_found:
   // invalid burst detected, increment the counter
   // this is just for user info
   r1 = M[r8 + $spdif.frame_copy.INVALID_BURST_COUNT_FIELD];
   r1 = r1 + 1;
   M[r8 + $spdif.frame_copy.INVALID_BURST_COUNT_FIELD] = r1;
   jump invalid_pa_found;

// --------------------------------------------
// Null burst
// --------------------------------------------
null_burst_found:
   // null burst detected, increment the counter
   // this is just for user info
   r1 = M[r8 + $spdif.frame_copy.NULL_BURST_COUNT_FIELD];
   r1 = r1 + 1;
   M[r8 + $spdif.frame_copy.NULL_BURST_COUNT_FIELD] = r1;
jump invalid_pa_found;

// --------------------------------------------
// Pause burst
// --------------------------------------------
pause_burst_found:
   // pause buttes detected, treat it like invalid
   // burst, the pause period will be implemented
   // using muting pcm
   r1 = M[r8 + $spdif.frame_copy.PAUSE_BURST_COUNT_FIELD];
   r1 = r1 + 1;
   M[r8 + $spdif.frame_copy.PAUSE_BURST_COUNT_FIELD] = r1;
jump invalid_pa_found;
// --------------------------------------------
// common point for all unsupported data types
// -------------------------------------------
reserved_burst_found:
unsupported_burst_found:
   // unsupported codec type detected
   //r3 = $spdif.frame_copy.DECODER_TYPE_UNKNOWN;
   //call $spdif.frame_copy.set_codec_type;
   r1 = M[r8 + $spdif.frame_copy.UNSUPPORTED_BURST_COUNT_FIELD];
   r1 = r1 + 1;
   M[r8 + $spdif.frame_copy.UNSUPPORTED_BURST_COUNT_FIELD] = r1;
   jump invalid_pa_found;

// -----------------------------------------
// Supported data type detected, start
// loading coded data from input stream
// -----------------------------------------
switch_to_loading_coded_data:

   // next state: loading coded data
   r2 = $spdif.state.LOADING_CODED_DATA;
   M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r2;

   // update audio frame size
   r0 = M[r8 + $spdif.frame_copy.NEW_CODEC_AUDIO_FRAME_SIZE_FIELD];
   M[r8 + $spdif.frame_copy.CODEC_AUDIO_FRAME_SIZE_FIELD] = r0;

   // set the codec type
   r3 = M[r8 + $spdif.frame_copy.NEW_CODEC_TYPE_FIELD];
   call $spdif.frame_copy.set_codec_type;

   // compute the length of stuffing data
   r2 = M[r8 + $spdif.frame_copy.PAY_LOAD_LENGTH_FIELD];
   r3 = M[r8 + $spdif.frame_copy.CODEC_AUDIO_FRAME_SIZE_FIELD];
   r2 = r2 LSHIFT -1;
   r2 = r3 - r2;
   r2 = r2 - 3;
   if NEG r2 = 0;
   M[r8 + $spdif.frame_copy.STUFFING_DATA_LENGTH_FIELD] = r2;

   #ifdef SPDIF_LATENCY_MEASUREMENT
      // new frame just started,
      // update packet boundary infor buffer
      r4 = $spdif.latency_measurment.TAG_NEW_PACKET_ARRIVAL;
      call $spdif.latency_measurement;
   #endif

   jump procecssing_loop_start_point;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.decode.handle_IEC_61937_Pa_Pz
//
// DESCRIPTION:
//   short lived state handler to read coded data payload when stream is
//   no aligned
//
// INPUTS:
//   r8 = spdif input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
handle_IEC_61937_Pa_Pz:

   // read next L/R samples
   r4 = M[I0,M1];
   r7 = r7 - M0, r5 = M[I1,M1];

   // swap r0 and r5 if stream is swapped
   Null = M[r8 + $spdif.frame_copy.STREAM_SWAPPED_FIELD];
   if Z jump calc_payload_len;
   r0 = r4;
   r4 = r5;
   r5 = r0;

   // calculate payload length
   calc_payload_len:
   M[r8 + $spdif.frame_copy.PREV_UNALIGNED_WORD_FIELD] = r4;
   r2 = r5 + 15;
   r2 = r2 LSHIFT -4;
   M[r8 + $spdif.frame_copy.PAY_LOAD_LENGTH_FIELD] = r2;
   M[r8 + $spdif.frame_copy.PAY_LOAD_LEFT_FIELD] = r2;
   jump switch_to_loading_coded_data;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.decode.loading_codec_data
//
// DESCRIPTION:
//   in this state decoder loads the coded data from input buffer into the codec
//   buffer.
//
//
// INPUTS:
//   r8 = spdif input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
loading_codec_data:
   // work out the amount of payload that can be loaded this
   // time, and the amount that will be left for next runs
   r2 = M[r8 + $spdif.frame_copy.PAY_LOAD_LEFT_FIELD];
   r1 = r7;
   r1 = MIN r6;
   r1 = r1 + r1;
   r1 = MIN r2;
   r2 = r2 - r1;
   M[r8 + $spdif.frame_copy.PAY_LOAD_LEFT_FIELD] = r2;
   if NZ jump loading_proc;
      // next state would be reading stuffing data
      r2 = $spdif.state.READING_STUFFING_DATA;
      M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r2;

   loading_proc:
   // check whether stream is swapped
   Null = M[r8 + $spdif.frame_copy.STREAM_SWAPPED_FIELD];
   if Z jump start_loading;
      // for swapped stream, swap L <-> R
      r0 = I0;
      I0 = I1;
      I1 = r0;
   start_loading:

   // check for stream alignment
   Null = M[r8 + $spdif.frame_copy.STREAM_ALIGNMENT_FIELD];
   if Z jump align_load;
   unalign_load:
      r3 = M[r8 + $spdif.frame_copy.PREV_UNALIGNED_WORD_FIELD];
      // load from un-aligned stream
      r10 = r1 LSHIFT -1;
      if Z jump write_single_word_unalign;
      // read first L/R sample
      r6 = r6 - r10, r4 = M[I0,M1];
      r7 = r7 - r10, r5 = M[I1,M1];
      r10 = r10 -1;
      M[I4,1] = r3;
      do unalgined_loop;
         r5 = M[I1,2], M[I4,1] = r5;
         r4 = M[I0,2], M[I4,1] = r4;
      unalgined_loop:
      M[I4,1] = r5;
      r3 = r4;
      M[r8 + $spdif.frame_copy.PREV_UNALIGNED_WORD_FIELD] = r3;
      write_single_word_unalign:
      r1 = r1 AND 1;
      if Z jump end_loading;
      M[I4,1] = r3;
      r6 = r6 - 1;
      jump end_loading;

      align_load:
      // load from aligned stream
      r10 = r1 LSHIFT -1;
      if Z jump write_single_word_align;
      // read first L/R sample
      r6 = r6 - r10, r4 = M[I0,M1];
      r7 = r7 - r10, r5 = M[I1,M1];
      r10 = r10 -1;
      do algined_loop;
         r4 = M[I0,2], M[I4,1] = r4;
         r5 = M[I1,2], M[I4,1] = r5;
      algined_loop:
      M[I4,1] = r4;
      M[I4,1] = r5;
      write_single_word_align:
      r1 = r1 AND 1;
      if Z jump end_loading;
      r4 = M[I0,2];
      r5 = M[I1,2], M[I4,1] = r4;
      r6 = r6 - 1;
      r7 = r7 - 1;
   end_loading:

   // revert L<->R swap for swapped stream
   Null = M[r8 + $spdif.frame_copy.STREAM_SWAPPED_FIELD];
   if Z jump procecssing_loop_start_point;
      r0 = I0;
      I0 = I1;
      I1 = r0;
   jump procecssing_loop_start_point;

// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.decode.read_stuffing_data
//
// DESCRIPTION:
//   loading and discarding the stuffing data
//   buffer.
//
// INPUTS:
//   r8 = input structure
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
read_stuffing_data:
   // calculate the amount of stuffing data will be read this
   // time and the amount will be left
   r2 = M[r8 + $spdif.frame_copy.STUFFING_DATA_LENGTH_FIELD];
   r10 = r7;
   r10 = MIN r2;
   r2 = r2 - r10;
   M[r8 + $spdif.frame_copy.STUFFING_DATA_LENGTH_FIELD] = r2;
   if NZ jump continue_skipping_stuffing_data;
      // if no stuffing data left, look for new sync info
      r2 = $spdif.state.LOOKING_FOR_SYNC_INFO;
      M[r8 + $spdif.frame_copy.READING_STATE_FIELD] = r2;
   continue_skipping_stuffing_data:
   // skip stuffing data
   r7 = r7 - r10;
   M3 = r10 + r10;
   r4 = M[I0,M3];
   r5 = M[I1,M3];
   M3 = 6;
   jump procecssing_loop_start_point;
#endif // #ifndef SPDIF_PCM_SUPPORT_ONLY
.ENDMODULE;
#endif // #ifndef SPDIF_FRAME_COPY_ASM_INCLUDED
