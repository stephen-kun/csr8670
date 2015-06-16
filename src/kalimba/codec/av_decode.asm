// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2009-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#include "stack.h"
#include "cbuffer.h"
#include "codec_library.h"



// *****************************************************************************
// MODULE:
//    $codec.av_decode
//
// DESCRIPTION:
//    Abstraction Layer for Decoders
//
// INPUTS:
//    - r5 = pointer to frame.decoder structure:
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything (calls decoder)
//
// NOTES:
// *****************************************************************************

.MODULE $M.codec_av_decode;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   // Save Data Structure passed in r5
   .VAR data_ptr = 0;

   // Previous state variable (just to support older apps)
   .VAR $master_reset_needed = 1;

   $codec.av_decode:

   // push rLink onto stack
   $push_rLink_macro;

   // Save Data Structure passed in r5
   M[data_ptr] = r5;
   
   
   // Makes sure initial mode is not SUCCESS
   r0 = $codec.NOT_ENOUGH_INPUT_DATA;
   M[r5 + $codec.av_decode.MODE_FIELD] = r0;

   // calc the time between two calls
   r6 = M[$TIMER_TIME];
   r0 = M[r5 + $codec.av_decode.PREV_TIME_FIELD];
   M[r5 + $codec.av_decode.PREV_TIME_FIELD] = r6;
   r6 = r6 - r0;
   if NEG r6 = -r6;

#ifdef DEBUG_AV_DECODE_ENABLE
   .VAR $debug_max_time_between_decode_calls;
   r0 = M[$debug_max_time_between_decode_calls];
   null = r6 - r0;
   if POS r0 = r6;
   M[$debug_max_time_between_decode_calls] = r0;
#endif

   // any new data written to the buffer?
   r0 = M[r5 + $codec.av_decode.IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   r1 = M[r5 + $codec.av_decode.CODEC_PREV_WADDR_FIELD];
   //if Z r6 = 0;
   M[r5 + $codec.av_decode.CODEC_PREV_WADDR_FIELD] = r0;

   // if new data arrived reset pause timer, else update it
   rMAC = 0x7FFFFF;
   r3 = M[r5 + $codec.av_decode.PAUSE_TIMER_FIELD];
   r2 = r3 + r6;
   if V r2 = rMAC;
   Null = r1 - r0;
   if NZ r2 = Null;
   M[r5 + $codec.av_decode.PAUSE_TIMER_FIELD] = r2;

#ifdef DEBUG_AV_DECODE_ENABLE
   .VAR $debug_max_pause_time;
   r0 = M[$debug_max_pause_time];
   null = r2 - r0;
   if POS r0 = r2;
   M[$debug_max_pause_time] = r0;
#endif

   // do we need to handle pause?
   Null =M[r5 + $codec.av_decode.CODEC_PURGE_ENABLE_FIELD];
   if Z jump no_pause_handling;

   // time to clear the buffer?
   Null = r2 - ($codec.av_decode.PAUSE_TO_CLEAR_THRESHOLD*1000);
   if NEG jump no_pause_handling;
   Null = r3 - ($codec.av_decode.PAUSE_TO_CLEAR_THRESHOLD*1000);
   if NEG jump cleare_buffers;

   no_pause_handling:
   // jump to proper point
   NULL = M[r5 + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
   if NZ jump decoding_proc;

   process_stalled:
      r0 = 1;
      r1 = M[r5 + $codec.av_decode.CAN_SWITCH_FIELD];
      Null = r2;
      if Z r1 = r0;
      M[r5 + $codec.av_decode.CAN_SWITCH_FIELD] = r1;
      if Z jump check_buf_level;
      // limit waiting in stall mode
      Null = r2 - ($codec.av_decode.STALL_TO_DECODE_THRESHOLD*1000);
      if NEG jump check_buf_level;
      Null = r3 - ($codec.av_decode.STALL_TO_DECODE_THRESHOLD*1000);
      if NEG jump switchto_decode;

      check_buf_level:
      // buffer reached good level? get back to decode
      r0 = M[r5 + $codec.av_decode.IN_BUFFER_FIELD];
      r4 = M[r0 + $cbuffer.SIZE_FIELD];
      call $cbuffer.calc_amount_data;
      r2 = M[r5 + $codec.av_decode.STALL_BUFFER_LEVEL_FIELD];
      r2 = r2 * r4 (frac);
      Null = r0 - r2;
      if NEG jump end;

   switchto_decode:
      // switch from stall to decode
      M[r5 + $codec.av_decode.CAN_SWITCH_FIELD] = NULL;
      r1 = 1;
      M[r5 + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD] = r1;

   decoding_proc:

      // run the decoder
      r0 = $codec.NORMAL_DECODE;
      M[r5 + $codec.av_decode.MODE_FIELD] = r0;
      r0 = M[r5 + $codec.av_decode.ADDR_FIELD];
      r5 = r5 + $codec.av_decode.DECODER_STRUC_FIELD;
      call r0;
      r5 = M[data_ptr];

      // if success reset pause timer
      r1 = M[r5 + $codec.av_decode.PAUSE_TIMER_FIELD];
      r0 = M[r5 + $codec.av_decode.MODE_FIELD];
      Null = r0 - $codec.SUCCESS;
      if NZ jump check_not_enough_input_data;
      // Success, reset pause timer
      if Z r1 = NULL;
      M[r5 + $codec.av_decode.PAUSE_TIMER_FIELD] = r1; 
      
   check_not_enough_input_data:
      // if not enough data switch to stall
      r0 = M[r5 + $codec.av_decode.MODE_FIELD];
      Null = r0 -  $codec.NOT_ENOUGH_INPUT_DATA;
      if NZ jump end;

      // time to switch to stall mode
      r1 = M[r5 + $codec.av_decode.PAUSE_TIMER_FIELD];
      r0 = M[r5 + $codec.av_decode.DECODE_TO_STALL_THRESHOLD];
      Null = r1 - r0;
      if POS jump switchto_stall;

   jump end;

   cleare_buffers:

      // pause happened, clear buffers
      call $block_interrupts;

      // Purge codec in buffer
      r1 = M[r5 + $codec.av_decode.IN_BUFFER_FIELD];
      r0 = M[r1 + $cbuffer.WRITE_ADDR_FIELD];
      M[r1 + $cbuffer.READ_ADDR_FIELD] = r0;
      M[r5 + $codec.av_decode.CODEC_PREV_WADDR_FIELD] = r0;

      // Purge audio out left buffer
      r1 = M[r5 + $codec.av_decode.OUT_LEFT_BUFFER_FIELD];
      r0 = M[r1 + $cbuffer.READ_ADDR_FIELD];
      M[r1 + $cbuffer.WRITE_ADDR_FIELD] = r0;

      // Purge audio out right buffer
      r1 = M[r5 + $codec.av_decode.OUT_RIGHT_BUFFER_FIELD];
      r0 = M[r1 + $cbuffer.READ_ADDR_FIELD];
      M[r1 + $cbuffer.WRITE_ADDR_FIELD] = r0;

      // r5 must point to decoder structure rather than av_decode structure! see also 
      // av_encode where this was done similarly. 
      r5 = r5 + $codec.av_decode.DECODER_STRUC_FIELD;
      // reset the decoder and silence the decoder
      r0 = M[r5 +($codec.av_decode.RESET_ADDR_FIELD-$codec.av_decode.DECODER_STRUC_FIELD)];

      if NZ call r0;
      r5 = M[data_ptr];

      // run master reset function
      r0 = M[r5 + $codec.av_decode.MASTER_RESET_FUNC_FIELD];
      if NZ call r0;
      r5 = M[data_ptr];

      // to support older apps
      r0 = 1;
      M[$master_reset_needed] = r0;

      call $unblock_interrupts;

   switchto_stall:
      // switch from decode to stall
      M[r5 + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD] = NULL;
 end:
   jump $pop_rLink_and_rts;

.ENDMODULE;
