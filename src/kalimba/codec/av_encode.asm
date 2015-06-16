// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#include "stack.h"
#include "codec_library.h"

// *****************************************************************************
// MODULE:
//    $codec.av_encode
//
// DESCRIPTION:
//    Abstraction Layer for Encoder.
//
// INPUTS:
//    - r5 = pointer to frame.decoder structure:
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything (calls encoder)
//
// NOTES:
// *****************************************************************************

.MODULE $M.codec_av_encode;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   // Save Data Structure passed in r5
   .VAR data_ptr = 0;
   .VAR WritePointer;

$codec.av_encode:

   $push_rLink_macro;
   M[data_ptr] = r5;


   r0 = M[r5 + $codec.av_encode.OUT_BUFFER_FIELD];
   // Save Write Pointer
   r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   M[WritePointer] = r1;
   // Get Space in Output
   call $cbuffer.calc_amount_space;
   // If space is less than threshold, then stall.
   r1 = M[r5 + $codec.av_encode.BUFFERING_THRESHOLD_FIELD];
   Null = r0 - r1;
   if NEG jump $pop_rLink_and_rts;


   // Call Encoder
   r0 = M[r5 + $codec.av_encode.ADDR_FIELD];
   r5 = r5 + $codec.av_encode.ENCODER_STRUC_FIELD;
   call r0;


   r5 = M[data_ptr];

   // Check Encoding Result
   r0 = M[r5 + $codec.av_encode.MODE_FIELD];
   Null = r0 - $codec.SUCCESS;
   if Z jump jp_encode_successful;
      // If Not Enough data or error then done
      Null = r0 - $codec.NOT_ENOUGH_OUTPUT_SPACE;
      if NZ jump $pop_rLink_and_rts;

      // NOT_ENOUGH_OUTPUT_SPACE.  Test for Stall condition
      r0 = M[r5 + $codec.av_encode.STALL_COUNTER_FIELD];
      r0 = r0 + 1;
      M[r5 + $codec.av_encode.STALL_COUNTER_FIELD] = r0;
      Null = r0 - $codec.av_encode.STALL_THRESHOLD;
      if NEG jump $pop_rLink_and_rts;

      // Reset encoder
      r1 = r5;
      r5 = r5 + $codec.av_encode.ENCODER_STRUC_FIELD;
      r0 = M[r1 + $codec.av_encode.RESET_ADDR_FIELD];
      if NZ call r0;
      r5 = M[data_ptr];

      // Remove all the data in left input buffer
      r0 = M[r5 + $codec.av_encode.IN_LEFT_BUFFER_FIELD];
      if Z jump skip_left_channel;
      r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      M[r0 + $cbuffer.READ_ADDR_FIELD] = r1;
   skip_left_channel:

      // Remove all the data in left input buffer
      r0 = M[r5 + $codec.av_encode.IN_RIGHT_BUFFER_FIELD];
      if Z jump skip_right_channel;
      r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      M[r0 + $cbuffer.READ_ADDR_FIELD] = r1;
   skip_right_channel:

      // Stall condition detected. Increase Buffer Threshold to add hysteresis
      r0 = M[r5 + $codec.av_encode.OUT_BUFFER_FIELD];
      r2 = M[r0 + $cbuffer.SIZE_FIELD];
      r1 = r2 * 0.5 (frac);    // Output space threshold now becomes 50% of out buffer size

      jump update_threshold_and_exit;



jp_encode_successful:
   M[r5 + $codec.av_encode.STALL_COUNTER_FIELD] = NULL;

   // Determine Packet size
   r0 = M[r5 + $codec.av_encode.OUT_BUFFER_FIELD];
   r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   r2 = M[r0 + $cbuffer.SIZE_FIELD];
   r1 = r1 - M[WritePointer];
   if NEG r1 = r1 + r2;

   r0 = r1 * 0.2 (frac);   // Output space threshold is 1.2 times the last output amount
   r1 = r1 + r0;
   NULL = r1 - r2;         // make sure the threshold is less than buffer size
   if POS r1 = r2;

update_threshold_and_exit:
   M[r5 + $codec.av_encode.BUFFERING_THRESHOLD_FIELD] = r1;
   jump $pop_rLink_and_rts;


.ENDMODULE;
