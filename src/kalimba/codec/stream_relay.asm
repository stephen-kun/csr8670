// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#include "core_library.h"
#include "codec_library.h"

.MODULE $M.codec.stream_relay;
   .CODESEGMENT CODEC_STREAM_RELAY_PM;
   .DATASEGMENT DM;

   $codec.stream_relay:

   .VAR struc_ptr;
   .VAR amount_space;

   // push rLink onto stack
   $push_rLink_macro;

   // store the pointer to the codec structure
   M[struc_ptr] = r5;

   // how much space have we got
   r0 = M[r5 + $codec.stream_relay.LOCAL_RELAY_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r3 = r0;

   r0 = M[r5 + $codec.stream_relay.REMOTE_RELAY_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   Null = r3 - r0;
   if POS r3 = r0;
   M[amount_space] = r3;

   // have we got a frame of data
   r0 = M[r5 + $codec.stream_relay.GET_FRAME_INFO_ADDR_FIELD];
   r5 = r5 + $codec.stream_relay.IN_BUFFER_FIELD;
   call r0;

   // restore the structure pointer
   r5 = M[struc_ptr];

   // check there was enough data
   Null = r0;
   if NZ jump enough_data;
      // there wasn't enough data if we don't get any for 50ms reset
      .VAR $already_stopped;
      .VAR $stop_time;
      r0 = M[$TIMER_TIME];
      Null = M[$already_stopped];
      if NEG jump all_done_can_idle;
      if NZ jump check_time;
         M[$stop_time] = r0;
         r1 = 1;
         M[$already_stopped] = r1;
      check_time:
      r0 = r0 - M[$stop_time];
      Null = r0 - 50000;
      if NEG jump all_done_can_idle;
      // stop
      r0 = -1;
      M[$already_stopped] = r0;
      M[r5 + $codec.stream_relay.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD] = Null;
      r0 = M[r5 + $codec.stream_relay.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      push r2;
      call $cbuffer.get_write_address_and_size_and_start_address;
      push r2;
      pop B0;
      pop r2;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      r1 = r0;
      r0 = M[r5 + $codec.stream_relay.IN_BUFFER_FIELD];
      call $cbuffer.set_read_address;
      if NEG jump all_done_can_idle;
   enough_data:
   M[$already_stopped] = Null;

   // save the word aligned state
   r7 = r2 * 3 (int);
   r8 = r0 AND 1;
   r8 = r8 + 2;
   r7 = r7 XOR r8;

   // get the previous frame size and save this one
   r8 = M[r5 + $codec.stream_relay.PREVIOUS_AUDIO_FRAME_LENGTH_FIELD];
   M[r5 + $codec.stream_relay.PREVIOUS_AUDIO_FRAME_LENGTH_FIELD] = r3;

   // work out how many words of space we need
   r6 = r0 - r2;
   // add on for sync header (8) and round up (1)
   r6 = r6 + (8+1);
   // convert to words
   r6 = r6 LSHIFT -1;

   // is there space for the frame (allow for sync header & padding)
   r10 = M[amount_space];
   Null = r10 - r6;
   if NEG jump all_done_can_idle;
   // set r10 to be the amount to copy
   r10 = r6;

   // update the read address
   r0 = M[r5 + $codec.stream_relay.IN_BUFFER_FIELD];
   // r1 set by the frame info function
   call $cbuffer.set_read_address;


   // convert frame length in bytes to a length in time
   r0 = M[r5 + $codec.stream_relay.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD];
   if NZ jump initialised;
      // invert the sample rate
      r0 = 0x3D09;
      rMAC0 = r0 LSHIFT 16;
      rMAC12 = r0 ASHIFT -8;
      Div = rMAC / r4;

      // set the playing state to buffering
      r0 = $codec.stream_relay.STATE_BUFFERING;
      M[r5 + $codec.stream_relay.STATE_FIELD] = r0;

      // make the playing time now plus a transmit delay
      r1 = r5 + $codec.stream_relay.NUM_AUDIO_SAMPLES_CONSUMED_PNTR_FIELD;
      r1 = M[r1 + ($codec.stream_decode_sync.WALL_CLOCK_STRUC_FIELD - $codec.stream_decode_sync.AUDIO_SAMPLES_CONSUMED_FIELD)];
      call $wall_clock.get_time;
      r0 = M[r5 + $codec.stream_relay.BUFFER_DELAY_IN_US_FIELD];
      r1 = r1 + r0;
      M[r5 + $codec.stream_relay.TIME_TO_PLAY_FIELD] = r1;

      // convert the buffer amount from a value in time to a value in samples
      r4 = r4 * 0.001 (frac);
      // r0 has the buffer delay in us from above
      r0 = r0 * 0.001 (frac);  // TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1 more accuracy needed here
      r0 = r0 * r4 (int);
      M[r5 + $codec.stream_relay.GOOD_WORKING_BUFLEVEL_FIELD] = r0;

      r0 = DivResult;
      M[r5 + $codec.stream_relay.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD] = r0;

      jump copy_header_info;

   initialised:

      // work out how many samples are in the buffer
      r1 = M[r5 + $codec.stream_relay.NUM_AUDIO_SAMPLES_CONSUMED_PNTR_FIELD];
      r0 = M[r5 + $codec.stream_relay.NUM_AUDIO_SAMPLES_IN_BUFFER_FIELD];
      r1 = M[r1];
      r0 = r0 - r1;

      r2 = M[r5 + $codec.stream_relay.GOOD_WORKING_BUFLEVEL_FIELD];
      r1 = r0 - r2;

      // are we playing
      r3 = M[r5 + $codec.stream_relay.STATE_FIELD];
      Null = r3 - $codec.stream_relay.STATE_PLAYING;
      if Z jump playing;

         // is there enough data to change state to playing
         Null = r1;
         if POS jump switch_to_playing;

         // playing time = previous playing time + previous duration (r8)
         r0 = M[r5 + $codec.stream_relay.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD];
         rMAC = r0 * r8;
         r0 = rMAC LSHIFT 13;
         r1 = M[r5 + $codec.stream_relay.TIME_TO_PLAY_FIELD];
         r0 = r0 + r1;
         M[r5 + $codec.stream_relay.TIME_TO_PLAY_FIELD] = r0;

         jump copy_header_info;


      switch_to_playing:
         // change the state to playing
         r0 = $codec.stream_relay.STATE_PLAYING;
         M[r5 + $codec.stream_relay.STATE_FIELD] = r0;

         // initialise values for playing
         M[r5 + $codec.stream_relay.SLOW_AVERAGE_BUFLEVEL_FIELD] = r1;
         r1 = M[$TIMER_TIME];
         r1 = r1 + $codec.stream_relay.SLOW_AVERAGE_SAMPLE_PERIOD;
         M[r5 + $codec.stream_relay.SLOW_AVERAGE_SAMPLE_TIME_FIELD] = r1;

      playing:

         // convert the offset into a warp amount and then a playing time
         r1 = M[r5 + $codec.stream_relay.SLOW_AVERAGE_SAMPLE_TIME_FIELD];
         Null = r1 - M[$TIMER_TIME];
         if POS jump dont_update_slow_average_yet;
            // update the new sample time
            r1 = r1 + $codec.stream_relay.SLOW_AVERAGE_SAMPLE_PERIOD;
            M[r5 + $codec.stream_relay.SLOW_AVERAGE_SAMPLE_TIME_FIELD] = r1;

            // calc the new slow average
            r1 = M[r5 + $codec.stream_relay.SLOW_AVERAGE_BUFLEVEL_FIELD];
            r3 = r1 ASHIFT $codec.stream_relay.SLOW_AVERAGE_SHIFT_CONST;
            r1 = r1 - r3;
            r1 = r1 + r0;
            M[r5 + $codec.stream_relay.SLOW_AVERAGE_BUFLEVEL_FIELD] = r1;

         dont_update_slow_average_yet:

         // get the average buffer level
         r0 = M[r5 + $codec.stream_relay.SLOW_AVERAGE_BUFLEVEL_FIELD];
         // get warp values
         r4 = M[r5 + $codec.stream_relay.WARP_RATE_COEF_FIELD];
         // calculate the offset (r2 has good working buffer level from above)
         r0 = r2 - r0;
         // r0 = number of words difference in buffer level
         //      +ve means buffer lower than ideal
         r0 = r0 * r4 (int);

         // now apply the warp to the previous frame size (r8)
         r1 = M[r5 + $codec.stream_relay.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD];
         rMAC = r1 * r8;

         // warp the length of the previous frame
//         rMAC = rMAC + rMAC * r0;
         r0 = rMAC LSHIFT 13;

         // update the playing time
         r1 = M[r5 + $codec.stream_relay.TIME_TO_PLAY_FIELD];
         r0 = r0 + r1;
         M[r5 + $codec.stream_relay.TIME_TO_PLAY_FIELD] = r0;


   copy_header_info:

      // get all the read and write addresses
      r0 = M[r5 + $codec.stream_relay.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_read_address_and_size_and_start_address;
      push r2;
      pop B0;
#else
      call $cbuffer.get_read_address_and_size;
#endif
      I0 = r0;
      L0 = r1;

      r0 = M[r5 + $codec.stream_relay.REMOTE_RELAY_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_write_address_and_size_and_start_address;
      push r2;
      pop B1;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      I1 = r0;
      L1 = r1;

      r0 = M[r5 + $codec.stream_relay.LOCAL_RELAY_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_write_address_and_size_and_start_address;
      push r2;
      pop B4;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      I4 = r0;
      L4 = r1;

      // decrement r10 for the header
      r10 = r10 - 5;

      // write in CS
      r0 = 0x4353;
      M[I1, 1] = r0,
       M[I4, 1] = r0;

      // write the R and padding
      r0 = r7 OR 0x5200;
      M[I1, 1] = r0,
       M[I4, 1] = r0;

      // write the playing time
      r1 = M[r5 + $codec.stream_relay.TIME_TO_PLAY_FIELD];
      r0 = r1 LSHIFT -8;
      M[I1, 1] = r0,
       M[I4, 1] = r0;

      // move the time along 8 bits and mask
      r1 = r1 AND 0xFF;
      r1 = r1 LSHIFT 8;

      // load M1
      M1 = 1;

      // do we need padding at the start
      Null = r7 AND 2;
      if NZ jump no_padding;
         // decrement r10
         r10 = r10 - M1,
          r0 = M[I0, 1];
         r0 = r0 AND 0xFF;
         r1 = r1 OR r0;
      no_padding:
      // write the word
      M[I1, 1] = r1,
       M[I4, 1] = r1;

      // now write the data
      do duplicate_data_loop;
         r0 = M[I0, 1];
         M[I1, 1] = r0,
          M[I4, 1] = r0;
      duplicate_data_loop:

      r7 = r7 AND 1;
      if NZ M1 = 0;
      L0 = 0,
       r0 = M[I0, M1];
      L1 = 0,
       M[I1, 1] = r0,
       M[I4, 1] = r0;
      L4 = 0;

      // update the read addresses
      r0 = M[r5 + $codec.stream_relay.IN_BUFFER_FIELD];
      r1 = I0;
      call $cbuffer.set_read_address;

      r0 = M[r5 + $codec.stream_relay.REMOTE_RELAY_BUFFER_FIELD];
      r1 = I1;
      call $cbuffer.set_write_address;

      r0 = M[r5 + $codec.stream_relay.LOCAL_RELAY_BUFFER_FIELD];
      r1 = I4;
      call $cbuffer.set_write_address;

      // at this point the previous frame size is actually this frame size
      r0 = M[r5 + $codec.stream_relay.PREVIOUS_AUDIO_FRAME_LENGTH_FIELD];
      // update the number of audio samples in the buffer
      r1 = M[r5 + $codec.stream_relay.NUM_AUDIO_SAMPLES_IN_BUFFER_FIELD];
      r1 = r1 + r0;
      M[r5 + $codec.stream_relay.NUM_AUDIO_SAMPLES_IN_BUFFER_FIELD] = r1;


   all_done_dont_idle:
      r0 = $codec.STREAM_DONT_IDLE;

      // pop rLink from stack
      jump $pop_rLink_and_rts;

   all_done_can_idle:
      r0 = $codec.STREAM_CAN_IDLE;

      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;
