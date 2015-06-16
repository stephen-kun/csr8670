// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef CODEC_STREAM_DECODE_INCLUDED
#define CODEC_STREAM_DECODE_INCLUDED

#include "codec_library.h"

// *****************************************************************************
// MODULE:
//    $codec.stream_decode
//
// DESCRIPTION:
//    Decodes a codec stream (deals with overflow/underflow and attempts to
// handle the 'real' BT issues such as: packet jitter, non-perfect sample rates,
// going out of range, etc)
//
// MODIFICATIONS:
//    3.3    04/10/05    DRH     BlueLab 3.3 release
//
// INPUTS:
//    - r5 = pointer to a codec.stream_decode structure
//        - ADDR_FIELD
//           - frame_decode function - routine to call to decode a frame of
//             codec data.
//        - RESET_ADDR_FIELD
//           - reset decoder function - routine to call to reset the decoder.
//        - SILENCE_ADDR_FIELD
//           - silence decoder function - routine to call to clear internal codec
//             buffers, used to clear any audio remains from a previous decode.
//        - IN_BUFFER_FIELD
//           - input codec cbuffer structure - cbuffer from where the decoder
//             should read the input compressed codec data.
//        - OUT_LEFT_BUFFER_FIELD
//           - left output cbuffer structure - cbuffer where the decoder should
//             write the decoded left audio samples.
//        - OUT_RIGHT_BUFFER_FIELD
//           - right output cbuffer structure - cbuffer where the decoder should
//             write the decoded right audio samples.
//        - MODE_FIELD
//           - internal mode data - initialise to 0.
//        - NUM_OUTPUT_SAMPLES_FIELD
//           - internal state data - initialise to 0.
//        - DECODER_DATA_OBJECT_FIELD 
//           - decoder data object pointer  
//        - COMFORT_NOISE_GAIN_FIELD
//           - comfort noise gain - when the data supplied to the decoder fails
//             for some reason, eg out of Bluetooth range, the volume of comfort
//             noise that should be played. Set to 0 to output silence in the
//             abscence of data. Range (0 - 1.0).
//        - GOOD_WORKING_BUFLEVEL_FIELD
//           - good working buffer level - input codec buffer level (%) required
//             before decoding starts. Decreasing this value will reduce the
//             latency of the decoder but will also reduce the tolerance to
//             jitter in the average data rate. This should be modified in
//             parallel with considerations of the size of input codec cbuffer,
//             see below.
//        - POORLINK_DETECT_BUFLEVEL_FIELD
//           - poorlink detect buffer level - if the codec buffer empties the
//             decoder will examine the buffer level history and determine if
//             the link is poor. The decoder may have simply reached the end of
//             the current audio track. If historical level was below the value
//             specified by this parameter the link is deemed to be poor and
//             poorlink is flagged, see below. Note this value is a percentage
//             of the good working buffer level, not the actual buffer size.
//        - POORLINK_PERIOD_FIELD
//           - poorlink period - when poorlink has been flagged the decoder will
//             not release the flag until a good data rate has been continuously
//             sustained for this duration, measured in micro-seconds.
//        - PLAYING_ZERO_DATARATE_PERIOD_FIELD
//           - zero data period - during the "playing" state if no data is
//             received for this duration of time the decoder enters the
//             "buffering" state. It assumes the source has "paused" and so
//             should output silence until the good working buffer level is
//             restored.
//        - BUFFERING_ZERO_DATARATE_PERIOD_FIELD
//           - zero datarate period - if the input buffer has some data in it,
//             and the decoder is in the "buffering" state for this period of
//             time without receiving any further data, then the decoder plays
//             out the input buffer. This is mode of operation is required so
//             that small audio clips which would otherwise not reach the good
//             working buffer level are played out as they are received (i.e. not
//             queued up until the good working level is reached).
//        - POORLINK_DETECT_TABLE_ADDR_FIELD
//           - address of the poorlink table - a table used to store the buffer
//             level history, used to detect the poorlink condition.
//        - POORLINK_DETECT_TABLE_SIZE_FIELD
//           - size of the poorlink table
//        - WARP_RATE_HIGH_COEF_FIELD
//           - high warp rate coefficient - a measure of the amount of warp to
//             apply, when the buffer level is quite far out from the good
//             working buffer level, see below.
//        - WARP_RATE_LOW_COEF_FIELD
//           - low warp rate coefficient - a measure of the amount of warp to
//             apply, when the buffer level is quite close to the good working
//             buffer level, see below.
//        - WARP_RATE_TRANSITION_LEVEL_FIELD
//           - warp transition level (between high and low coefs being used) -
//             sets the buffer difference in words at which point coef 'HIGH'
//             starts to be used.
//
// OUTPUTS:
//    - r0 = $codec.STREAM_CAN_IDLE / $codec.STREAM_DONT_IDLE
//    (this can be used to decide whether to have an idle period to save power)
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTES:
//
//    @verbatim
//                                GOOD_WORKING_BUFLEVEL
//                                             |
//          ___________________________________V___________________
//         |                 decoder input buffer                  |
//         |_______________________________________________________|
//        Empty                                                  Full
//     (0 bytes)                                              (N bytes)
//    @endverbatim
//
//  GOOD_WORKING_BUFLEVEL - decoding starts when at least this amount of data is
//  in the cbuffer.  This is the main buffer in the system to accomodate jitter
//  from packet retries etc.
//
//  POOR_LINK detection - If it appears that the BT link is not sustaining the
//  required rate for realtime audio, then the POORLINK condition is flagged.
//  This causes the output to be muted for a certain period.  If during this
//  period no further POORLINK conditions have been detected then the audio
//  will start playing again, otherwise it will continue muting the audio.
//
//  WARP_RATE_HIGH/LOW_COEF - this follows the equation:
//  @verbatim
//  RequestedWarpRate(%) = WarpRateCoef/167772 * (buffer level difference in bytes)
//
//  Example: suppose 1% warping is required when the buffer level discrepency is
//  500 bytes, applying the above equation gives a warp rate coefficient of 336.
//  @endverbatim
//
// *****************************************************************************
.MODULE $M.codec_stream_decode;
   .CODESEGMENT CODEC_STREAM_DECODE_PM;
   .DATASEGMENT DM;

   .VAR struc_ptr;
   .CONST RAND_M   -4508331;
   .CONST RAND_C   11;


   $codec.stream_decode:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_0, r1)
#endif

   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $codec.profile_stream_decode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED;
      r0 = &$codec.profile_stream_decode;
      call $profiler.start;
   #endif

   // store the pointer to the codec structure
   M[struc_ptr] = r5;

   // if debugging store buffer level
   #ifdef DEBUG_ON
     .VAR/DM1 $codec.stream_decoder_buflevel;
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      M[$codec.stream_decoder_buflevel] = r0;
   #endif


   // -- Jump to current state --
   r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
   r0 = r0 AND $codec.stream_decode.STATE_MASK;
   Null = r0 - $codec.stream_decode.STATE_PLAYING;
   if Z jump playing_state;


   // -- BUFFERING state --
   buffering_state:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_1, r1)
#endif

      // If (DETECT_POORLINK_ENABLE) then see if the poorlink condition is met.
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
      Null = r0 AND $codec.stream_decode.CONDITION_DETECT_POORLINK_ENABLE;
      if Z jump dont_detect_poorlink;

         // turn off DETECT_POORLINK until retriggered
         r0 = r0 AND (0xFFFF - $codec.stream_decode.CONDITION_DETECT_POORLINK_ENABLE);
         M[r5 + $codec.stream_decode.STATE_FIELD] = r0;

         // -- Detect poorlink condition --
         // We look at the buffer level at the time that the BT data
         // should have stopped (we define this as the time when the sbc read
         // pointer was SBC_START_DECODING_LIMIT_IN_BYTES less).  If we find
         // that the average buffer level at this point was too low then we
         // flag the poorlink condition.

         // subtract GOOD_WORKING_BUFLEVEL off current read pointer;
         r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_read_address_and_size_and_start_address;
         push r2;
         pop B0;
#else
         call $cbuffer.get_read_address_and_size;
#endif
         L0 = r1;
         I0 = r0;
         r0 = M[r5 + $codec.stream_decode.GOOD_WORKING_BUFLEVEL_FIELD];
         rMAC = r1 * r0 (frac);
         M0 = -rMAC;
         // dummy read to adjust pointer
         r0 = M[I0,M0];
         // r4 = P
         r4 = I0;
         L0 = 0;

         // now find table value that matches
         //     (readptr(i) - P) > 0          AND   (readptr(i-1) - P) < 0
         // OR  (readptr(i) - P) > 0          AND   (readptr(i) < readptr(i-1))
         // OR  (readptr(i) < readptr(i-1))   AND   (readptr(i-1) - P) < 0
         r10 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_SIZE_FIELD];
         r10 = r10 ASHIFT -1;
         r10 = r10 - 1;
         r6 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_ADDR_FIELD];
         r0 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_OFFSET_FIELD];
         // r1 = readptr(i)
         r1 = M[r6 + r0];
         do poorlink_detect_loop;
            r0 = r0 - 2;
            if POS jump dont_reset_offset;
               r0 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_SIZE_FIELD];
               r0 = r0 - 2;
            dont_reset_offset:
            // r2 = readptr(i-1)
            r2 = M[r6 + r0];
            r3 = 1;
            Null = r1 - r4;
            if POS r3 = r3 + r3;
            Null = r2 - r4;
            if LE r3 = r3 + r3;
            Null = r1 - r2;
            if NEG r3 = r3 + r3;

            Null = r3 - 4;
            if Z jump poorlink_detect_found_match;
            r1 = r2;  // old = new
         poorlink_detect_loop:

         // didn't find a match assume not poor link
         jump poorlink_detect_done;

         poorlink_detect_found_match:
         // look up the amount of data entry that corresponds to the matched read_ptr
         r0 = r0 + 1;
         r1 = M[r6 + r0];
         // if the amount of data has drifted away from GOOD_WORKING_BUFLEVEL by
         // more than a certain amount then jump to the GOBBLING state with
         // poorlink condition set
         r0 = M[r5 + $codec.stream_decode.POORLINK_DETECT_BUFLEVEL_FIELD];
         r0 = rMAC * r0 (frac);
         Null = r1 - r0;
         if NEG jump switch_to_buffering_state_with_poorlink_immediately;

         poorlink_detect_done:
      dont_detect_poorlink:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_2, r1)
#endif

      // if buffer is at a good working level go straight to playing_state
      // else insert silence
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      push r2;
      call $cbuffer.get_read_address_and_size_and_start_address;
      push r2;
      pop B0;
      pop r2;
#else
      call $cbuffer.get_read_address_and_size;
#endif
      r0 = M[r5 + $codec.stream_decode.GOOD_WORKING_BUFLEVEL_FIELD];
      r4 = r0 * r1 (frac);
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      Null = r0 - r4;
      if POS jump switch_to_playing;

         // only check for zero datarate condition if buffer has > 10 words of data
         Null = r0 - 10;
         if NEG jump buffering_zero_datarate_test_done;


         // If (ZERO_DATARATE condition for so long) --> PLAY out the buffer
         // this allows us to play very small audio samples which aren't of
         // long enough duration to get to the good working buffer level.
         r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_write_address_and_size_and_start_address;
#else
         call $cbuffer.get_write_address_and_size;
#endif
         // see if current write_ptr is the same as the previous one
         r1 = M[r5 + $codec.stream_decode.PREV_WRITE_PTR_FIELD];
         M[r5 + $codec.stream_decode.PREV_WRITE_PTR_FIELD] = r0;
         Null = r0 - r1;
         if NZ jump buffering_not_zero_datarate_condition;

            // see if ZERO_DATARATE already set
            r1 = M[r5 + $codec.stream_decode.STATE_FIELD];
            Null = r1 AND $codec.stream_decode.CONDITION_ZERO_DATARATE;
            if Z jump buffering_zero_datarate_not_already_set;

               // see if zero_datarate endtime has been reached
               r0 = M[r5 + $codec.stream_decode.ZERO_DATARATE_ENDTIME_FIELD];
               Null = r0 - M[$TIMER_TIME];
               if POS jump buffering_zero_datarate_test_done;

                  // set STOPPING condition and clear ZERO_DATARATE condition
                  r1 = r1 OR $codec.stream_decode.CONDITION_STOPPING;
                  r1 = r1 AND (0xFFFF - $codec.stream_decode.CONDITION_ZERO_DATARATE);
                  M[r5 + $codec.stream_decode.STATE_FIELD] = r1;

                  // set PLAYING state - don't enable poorlink as the buffer level
                  // will be too low and it'll always trigger
                  r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
                  r0 = r0 AND (0xFFFF - $codec.stream_decode.STATE_MASK);
                  r0 = r0 OR $codec.stream_decode.STATE_PLAYING;
                  M[r5 + $codec.stream_decode.STATE_FIELD] = r0;
                  jump playing_state;


            buffering_zero_datarate_not_already_set:
            // set ZERO_DATARATE condition and store possible end time for playing
            r1 = r1 OR $codec.stream_decode.CONDITION_ZERO_DATARATE;
            M[r5 + $codec.stream_decode.STATE_FIELD] = r1;
            r0 = M[r5 + $codec.stream_decode.BUFFERING_ZERO_DATARATE_PERIOD_FIELD];
            r0 = r0 + M[$TIMER_TIME];
            M[r5 + $codec.stream_decode.ZERO_DATARATE_ENDTIME_FIELD] = r0;
            jump buffering_zero_datarate_test_done;

         buffering_not_zero_datarate_condition:
         // clear ZERO_DATARATE_CONDITION
         r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
         r0 = r0 AND (0xFFFF - $codec.stream_decode.CONDITION_ZERO_DATARATE);
         M[r5 + $codec.stream_decode.STATE_FIELD] = r0;
         buffering_zero_datarate_test_done:


         // set the average buffer levels to the value of GOOD_WORKING_BUFLEVEL
         r0 = r4 * (1 << (-$codec.stream_decode.FAST_AVERAGE_SHIFT_CONST)) (int);
         M[r5 + $codec.stream_decode.FAST_AVERAGE_BUFLEVEL_FIELD] = r0;
         r0 = r4 * (1 << (-$codec.stream_decode.SLOW_AVERAGE_SHIFT_CONST)) (int);
         M[r5 + $codec.stream_decode.SLOW_AVERAGE_BUFLEVEL_FIELD] = r0;
         // set sample time for slow average
         r0 = M[r5 + $codec.stream_decode.SLOW_AVERAGE_SAMPLE_TIME_FIELD];
         r0 = r0 + M[$TIMER_TIME];
         M[r5 + $codec.stream_decode.SLOW_AVERAGE_SAMPLE_TIME_FIELD] = r0;

         // keep output buffers full
         r6 = 0x7FFF;
         call insert_silence;
         jump all_done_can_idle;


      switch_to_playing:
      // set state to PLAYING,  set DETECT_POORLINK_ENABLE, clear STOPPING
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
      r0 = r0 AND (0xFFFF - $codec.stream_decode.STATE_MASK
                          - $codec.stream_decode.CONDITION_STOPPING);
      r0 = r0 OR ($codec.stream_decode.STATE_PLAYING + $codec.stream_decode.CONDITION_DETECT_POORLINK_ENABLE);
      M[r5 + $codec.stream_decode.STATE_FIELD] = r0;

      // update the POORLINK end time so that they only time during the PLAYING state.
      r1 = M[r5 + $codec.stream_decode.PLAYING_STARTTIME_FIELD];
      r0 = M[r5 + $codec.stream_decode.POORLINK_ENDTIME_FIELD];
      r0 = r0 + M[$TIMER_TIME];
      r0 = r0 - r1;
      M[r5 + $codec.stream_decode.POORLINK_ENDTIME_FIELD] = r0;





   // -- PLAYING state --
   playing_state:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_3, r1)
#endif

      // store the start time of the PLAYING state so that we can update
      // the POORLINK and ZERO_DATARATE end times.
      r0 = M[$TIMER_TIME];
      M[r5 + $codec.stream_decode.PLAYING_STARTTIME_FIELD] = r0;


      // Update fast average buffer level stats
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      r1 = M[r5 + $codec.stream_decode.FAST_AVERAGE_BUFLEVEL_FIELD];
      r3 = r1 ASHIFT $codec.stream_decode.FAST_AVERAGE_SHIFT_CONST;
      r1 = r1 - r3;
      r1 = r1 + r0;
      M[r5 + $codec.stream_decode.FAST_AVERAGE_BUFLEVEL_FIELD] = r1;

      /*
      // warp target generation - proportional to the buffer level difference
      // now with 2 coefficients used depending on the buffer level difference
      //
      //       ^
      //       |  \
      //       |   \
      //       |    \                t = WARP_RATE_TRANSITION_LEVEL
      //       |     \
      //       |      \
      //   +ve |       \
      //       |        \
      //       |          \
      //  W    |            \
      //  A  0 |              \   WARP_RATE_LOW_COEF
      //  R    |                \
      //  P    |                  \
      //       |                    \
      //   -ve |                      \
      //       |                     . \
      //       |                     .  \
      //       |                     .   \   WARP_RATE_HIGHCOEF
      //       |                     .    \
      //       |                  t  .     \
      //       |                <--->.      \
      //        ---------------------------------->
      //             -ve       0       +ve
      //       buffer level difference from GOOD_WORKING_BUFLEVEL
      */

      r1 = M[r5 + $codec.stream_decode.SLOW_AVERAGE_BUFLEVEL_FIELD];
      r1 = r1 ASHIFT $codec.stream_decode.SLOW_AVERAGE_SHIFT_CONST;
      r0 = M[r5 + $codec.stream_decode.GOOD_WORKING_BUFLEVEL_FIELD];
      r0 = r0 * r2 (frac);
      r2 = M[r5 + $codec.stream_decode.WARP_RATE_TRANSITION_LEVEL_FIELD];
      r3 = M[r5 + $codec.stream_decode.WARP_RATE_LOW_COEF_FIELD];
      r0 = r0 - r1;
      // r0 = number of words difference in buffer level: +ve means buffer lower than ideal

      if NEG jump warp_negative;
         // warp amount is positive
         Null = r0 - r2;
         if POS jump warp_positive_high_rate;
            // warp amount is positive in the low rate section
            r0 = r0 * r3 (int);
            jump warp_amount_chosen;

         warp_positive_high_rate:
            // warp amount is positive in the high rate section
            r3 = r3 * r2 (int);
            r0 = r0 - r2;
            r1 = M[r5 + $codec.stream_decode.WARP_RATE_HIGH_COEF_FIELD];
            r0 = r0 * r1 (int);
            r0 = r0 + r3;
            jump warp_amount_chosen;

      warp_negative:
         // warp amount is negative
         Null = r0 + r2;
         if NEG jump warp_negative_high_rate;
            // warp amount is negative in the low rate section
            r0 = r0 * r3 (int);
            jump warp_amount_chosen;

         warp_negative_high_rate:
            // warp amount is negative in the high rate section
            r3 = r3 * r2 (int);
            r0 = r0 + r2;
            r1 = M[r5 + $codec.stream_decode.WARP_RATE_HIGH_COEF_FIELD];
            r0 = r0 * r1 (int);
            r0 = r0 - r3;

      warp_amount_chosen:
      M[r5 + $codec.stream_decode.WARP_TARGET_FIELD] = r0;


      // If (POORLINK condition ended) --> BUFFERING state with POORLINK cleared
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
      Null = r0 AND $codec.stream_decode.CONDITION_POORLINK;
      if Z jump playing_not_poorlink;

         r1 = M[r5 + $codec.stream_decode.POORLINK_ENDTIME_FIELD];
         Null = r1 - M[$TIMER_TIME];
         if POS jump playing_poorlink_not_ended;
            r0 = r0 AND (0xFFFF - $codec.stream_decode.CONDITION_POORLINK);
            M[r5 + $codec.stream_decode.STATE_FIELD] = r0;
            jump switch_to_buffering_state_immediately;

         playing_poorlink_not_ended:
         // If (POORLINK condition)
         //   dummy decode the frame
         call poorlink_detect_add_entry;
         r0 = $codec.NO_OUTPUT_DECODE;
         M[r5 + $codec.stream_decode.MODE_FIELD] = r0;
         r0 = M[r5 + $codec.stream_decode.ADDR_FIELD];
         // decoder function to receive r5 pointer to decoder structure
         r5 = r5 + $codec.stream_decode.DECODER_STRUC_FIELD;
         call r0;
         // reload r5
         r5 = M[struc_ptr];
         // if not enough output space -> exit, can idle
         r0 = M[r5 + $codec.stream_decode.MODE_FIELD];
         Null = r0 - $codec.NOT_ENOUGH_OUTPUT_SPACE;
         if Z jump all_done_can_idle;
         // if input buffer underflow -> BUFFERING state
         Null = r0 - $codec.NOT_ENOUGH_INPUT_DATA;
         if Z jump switch_to_buffering_state_immediately;
         // else insert appropriate amount of silence into output stream
         r6 = M[r5 + $codec.stream_decode.NUM_OUTPUT_SAMPLES_FIELD];
         call insert_silence;
         // dont allow stopping when in poorlink
         jump all_done_dont_idle;


      playing_not_poorlink:
         // It's a good link do a normal frame decode
         call poorlink_detect_add_entry;
         r0 = $codec.NORMAL_DECODE;
         M[r5 + $codec.stream_decode.MODE_FIELD] = r0;
         r0 = M[r5 + $codec.stream_decode.ADDR_FIELD];
         // decoder function to receive r5 pointer to decoder structure
         r5 = r5 + $codec.stream_decode.DECODER_STRUC_FIELD;
         call r0;
         // reload r5
         r5 = M[struc_ptr];
         // if not enough output space -> exit, can idle
         r0 = M[r5 + $codec.stream_decode.MODE_FIELD];
         Null = r0 - $codec.NOT_ENOUGH_OUTPUT_SPACE;
         if Z jump all_done_can_idle;
         // if buffer underflow -> BUFFERING state
         Null = r0 - $codec.NOT_ENOUGH_INPUT_DATA;
         if Z jump switch_to_buffering_state_immediately;

      decode_done:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_4, r1)
#endif

      // Update slow average buffer level stats
      r0 = M[r5 + $codec.stream_decode.SLOW_AVERAGE_SAMPLE_TIME_FIELD];
      Null = r0 - M[$TIMER_TIME];
      if POS jump dont_update_slow_average_yet;
         // update the new sample time
         r0 = r0 + $codec.stream_decode.SLOW_AVERAGE_SAMPLE_PERIOD;
         M[r5 + $codec.stream_decode.SLOW_AVERAGE_SAMPLE_TIME_FIELD] = r0;

         // calc the new slow average
         r0 = M[r5 + $codec.stream_decode.FAST_AVERAGE_BUFLEVEL_FIELD];
         r0 = r0 ASHIFT $codec.stream_decode.FAST_AVERAGE_SHIFT_CONST;
         r1 = M[r5 + $codec.stream_decode.SLOW_AVERAGE_BUFLEVEL_FIELD];
         r2 = r1 ASHIFT $codec.stream_decode.SLOW_AVERAGE_SHIFT_CONST;
         r1 = r1 - r2;
         r1 = r1 + r0;
         M[r5 + $codec.stream_decode.SLOW_AVERAGE_BUFLEVEL_FIELD] = r1;
      dont_update_slow_average_yet:

      // If (STOPPING condition  &  read_ptr caught up) --> BUFFERING state next time
      r1 = M[r5 + $codec.stream_decode.STATE_FIELD];
      Null = r1 AND $codec.stream_decode.CONDITION_STOPPING;
      if Z jump not_stopping;

         // if the read_ptr has gone past prev_write_addr -> BUFFERING state
         // because of wrapping the condition is a little more complicated
         //     Write     <  WritePrev <=  Read      (undrflw catches '=' case)
         //  or
         //     Read      <= Write     <   WritePrev (undrflw catches '=' case)
         //  or
         //     WritePrev <= Read      <=  Write
         r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_read_address_and_size_and_start_address;
#else
         call $cbuffer.get_read_address_and_size;
#endif
         r2 = r0;
         r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_write_address_and_size_and_start_address;
#else
         call $cbuffer.get_write_address_and_size;
#endif
         r1 = M[r5 + $codec.stream_decode.PREV_WRITE_PTR_FIELD];
         // r0 = Write,  r1 = Writeprev, r2 = Read
         Null = r0 - r1;
         if NEG jump write_LE_writeprev;
         Null = r1 - r2;
         if LE jump check_read_LE_write;
         jump all_done_dont_idle;
         write_LE_writeprev:
         Null = r1 - r2;
         if LE jump switch_to_buffering_state_immediately;
         check_read_LE_write:
         Null = r2 - r0;
         if LE jump switch_to_buffering_state_immediately;
         jump all_done_dont_idle;
      not_stopping:


      // If (ZERO_DATARATE condition for so long) --> STOPPING = 1;
      // see if current write_ptr is the same as the previous one
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_write_address_and_size_and_start_address;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      r1 = M[r5 + $codec.stream_decode.PREV_WRITE_PTR_FIELD];
      M[r5 + $codec.stream_decode.PREV_WRITE_PTR_FIELD] = r0;
      Null = r0 - r1;
      if NZ jump playing_not_zero_datarate_condition;

         // see if ZERO_DATARATE already set
         r1 = M[r5 + $codec.stream_decode.STATE_FIELD];
         Null = r1 AND $codec.stream_decode.CONDITION_ZERO_DATARATE;
         if Z jump playing_zero_datarate_not_already_set;

            // see if zero_datarate endtime has been reached
            r0 = M[r5 + $codec.stream_decode.ZERO_DATARATE_ENDTIME_FIELD];
            Null = r0 - M[$TIMER_TIME];
            if POS jump all_done_dont_idle;

               // set STOPPING condition and clear ZERO_DATARATE condition
               r1 = r1 OR $codec.stream_decode.CONDITION_STOPPING;
               r1 = r1 AND (0xFFFF - $codec.stream_decode.CONDITION_ZERO_DATARATE);
               M[r5 + $codec.stream_decode.STATE_FIELD] = r1;
               jump all_done_dont_idle;

         playing_zero_datarate_not_already_set:
         // set ZERO_DATARATE condition and store end time for re-BUFFERING
         r1 = r1 OR $codec.stream_decode.CONDITION_ZERO_DATARATE;
         M[r5 + $codec.stream_decode.STATE_FIELD] = r1;
         r0 = M[r5 + $codec.stream_decode.PLAYING_ZERO_DATARATE_PERIOD_FIELD];
         r0 = r0 + M[$TIMER_TIME];
         M[r5 + $codec.stream_decode.ZERO_DATARATE_ENDTIME_FIELD] = r0;
         jump all_done_dont_idle;

      playing_not_zero_datarate_condition:
      // clear ZERO_DATARATE_CONDITION
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
      r0 = r0 AND (0xFFFF - $codec.stream_decode.CONDITION_ZERO_DATARATE);
      M[r5 + $codec.stream_decode.STATE_FIELD] = r0;
      jump all_done_dont_idle;






   // switch to BUFFERING state immediately
   switch_to_buffering_state_immediately:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_5, r1)
#endif

      // set warp target to default of zero
      M[r5 + $codec.stream_decode.WARP_TARGET_FIELD] = Null;

      // set state to BUFFERING,  clear ZERO_DATARATE conidition, clear STOPPING condition
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];

      r0 = r0 AND (0xFFFF - $codec.stream_decode.STATE_MASK
                          - $codec.stream_decode.CONDITION_STOPPING
                          - $codec.stream_decode.CONDITION_ZERO_DATARATE);
      r0 = r0 OR $codec.stream_decode.STATE_BUFFERING;
      M[r5 + $codec.stream_decode.STATE_FIELD] = r0;
      jump buffering_state;





   // switch to BUFFERING state with poorlink set immediately
   switch_to_buffering_state_with_poorlink_immediately:
      // set POORLINK condition
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
      r0 = r0 OR $codec.stream_decode.CONDITION_POORLINK;
      M[r5 + $codec.stream_decode.STATE_FIELD] = r0;
      // set poorlink endtime
      r0 = M[r5 + $codec.stream_decode.POORLINK_PERIOD_FIELD];
      r0 = r0 + M[$TIMER_TIME];
      M[r5 + $codec.stream_decode.POORLINK_ENDTIME_FIELD] = r0;
      jump switch_to_buffering_state_immediately;






   // exit and flag that we can idle as the audio buffer is already quite full
   all_done_can_idle:
      // stop profiling if enabled
      #ifdef ENABLE_PROFILER_MACROS
         r0 = &$codec.profile_stream_decode;
         call $profiler.stop;
      #endif
      r0 = $codec.STREAM_CAN_IDLE;
      // pop rLink from stack
      jump $pop_rLink_and_rts;


   // exit and flag that we shoudn't idle as the audio buffer still needs filling
   all_done_dont_idle:
      // stop profiling if enabled
      #ifdef ENABLE_PROFILER_MACROS
         r0 = &$codec.profile_stream_decode;
         call $profiler.stop;
      #endif
      r0 = $codec.STREAM_DONT_IDLE;
      // pop rLink from stack
      jump $pop_rLink_and_rts;





   poorlink_detect_add_entry:
      // push rLink onto stack
      $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_6, r1)
#endif
      // -- Store table of read pointers and amounts of data --

      // if current current read address is the same as the last on in the
      // table then skip storing an entry
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_read_address_and_size_and_start_address;
#else
      call $cbuffer.get_read_address_and_size;
#endif
      r7 = r0;
      r0 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_OFFSET_FIELD];
      r6 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_ADDR_FIELD];
      r0 = r0 + r6;
      Null = r7 - M[r0];
      if Z jump $pop_rLink_and_rts;

      // increment table pointer
      r0 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_OFFSET_FIELD];
      r0 = r0 + 2;
      r1 = M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_SIZE_FIELD];
      Null = r0 - r1;
      if Z r0 = 0;
      M[r5 + $codec.stream_decode.POORLINK_DETECT_TABLE_OFFSET_FIELD] = r0;
      // store list of amounts of data
      r6 = r6 + r0;
      r0 = M[r5 + $codec.stream_decode.IN_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      M[r6 + 1] = r0;
      // store list of read pointers
      M[r6] = r7;

      // pop rLink from stack
      jump $pop_rLink_and_rts;




   // -- Insert silence --
   // r6 = maximum amount to output
   insert_silence:
      // push rLink onto stack
      $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_DECODE_ASM.STREAM_DECODE.PATCH_ID_7, r2)
#endif

      // set r6 to minimum amount of space available
      r0 = M[r5 + $codec.stream_decode.OUT_LEFT_BUFFER_FIELD];
      if Z jump dont_check_left;
         call $cbuffer.calc_amount_space;
         Null = r6 - r0;
         if POS r6 = r0;
      dont_check_left:
      r0 = M[r5 + $codec.stream_decode.OUT_RIGHT_BUFFER_FIELD];
      if Z jump dont_check_right;
         call $cbuffer.calc_amount_space;
         Null = r6 - r0;
         if POS r6 = r0;
      dont_check_right:


      // load starting random number
      r2 = M[r5 + $codec.stream_decode.RAND_LAST_VAL_FIELD];
      // a good random number generating constant
      r3 = RAND_M;
      // gain for white noise insertion
      r4 = M[r5 + $codec.stream_decode.COMFORT_NOISE_GAIN_FIELD];
      // if not POORLINK condition then set gain to 0 so silence instead
      r0 = M[r5 + $codec.stream_decode.STATE_FIELD];
      Null = r0 AND $codec.stream_decode.CONDITION_POORLINK;
      if Z r4 = 0;


      // add r6 words of zeros to each buffer
      r0 = M[r5 + $codec.stream_decode.OUT_LEFT_BUFFER_FIELD];
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
         r10 = r6;
         I0 = r0;   L0 = r1;
         do add_comfort_noise_left_loop;
            r2 = r2 * r3 (int);
            r2 = r2 + RAND_C;
            r0 = r2 * r4 (frac);
            M[I0,1] = r0;
         add_comfort_noise_left_loop:
         // store updated cbuffer pointers for left audio output
         r0 = M[r5 + $codec.stream_decode.OUT_LEFT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_write_address;
      dont_add_comfort_noise_left:

      r0 = M[r5 + $codec.stream_decode.OUT_RIGHT_BUFFER_FIELD];
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
         r10 = r6;
         I0 = r0;   L0 = r1;
         do add_comfort_noise_right_loop;
            r2 = r2 * r3 (int);
            r2 = r2 + RAND_C;
            r0 = r2 * r4 (frac);
            M[I0,1] = r0;
         add_comfort_noise_right_loop:
         // store updated cbuffer pointers for right audio input
         r0 = M[r5 + $codec.stream_decode.OUT_RIGHT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_write_address;
      dont_add_comfort_noise_right:
      L0 = 0;

      // store final random number
      M[r5 + $codec.stream_decode.RAND_LAST_VAL_FIELD] = r2;

      // silence the decoder to avoid pops and squeeks when it starts decoding again
      r0 = M[r5 + $codec.stream_decode.SILENCE_ADDR_FIELD];
      // silence decoder function expects r9 pointer to decoder data object
      // r5 is to be the decoder structure pointer
      // TODO: Should we remove this pushing and popping?
      push r5;
      push r9;
      r5 = r5 + $codec.stream_decode.DECODER_STRUC_FIELD;
      r9 = M[r5 + $codec.DECODER_DATA_OBJECT_FIELD];
      call r0;
      pop r9;
      pop r5;

      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
