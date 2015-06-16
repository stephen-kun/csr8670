// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    copy operator
//
// DESCRIPTION:
//    This operator does a straight forward copy of samples from the input
// buffer to the output buffer.
//
// When using the operator the following data structure is used:
//
//   $cbops.mono_resample.INPUT_1_START_INDEX_FIELD
//   $cbops.mono_resample.OUTPUT_1_START_INDEX_FIELD
//   $cbops.mono_resample.COEF_BUF_INDEX_FIELD
//   $cbops.mono_resample.CONVERT_RATIO
//   $cbops.mono_resample.RATIO_OUT
//
//
// *****************************************************************************

#include "stack.h"
#include "cbops.h"

.MODULE $M.cbops.stereo_upsample_int;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.stereo_upsample_int[$cbops.function_vector.STRUC_SIZE] =
       $cbops.function_vector.NO_FUNCTION,         // reset function
       &$cbops.resample.upsample_amount_to_use,    // amount to use function
       &$cbops.stereo_upsample_int.main;           // main function

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbops.stereo_upsample_int.main
//
// DESCRIPTION:
//    Operator that copies the input sample to the output
//
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************


.MODULE $M.cbops.stereo_upsample_int.main;
   .CODESEGMENT CBOPS_STEREO_UPSAMPLE_INT_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.stereo_upsample_int.main:

   $push_rLink_macro;

   .VAR sample_count   = 0;
   .VAR temp_index_1   = 0;
   .VAR temp_index_2   = 0;


#ifdef ENABLE_PROFILER_MACROS
   // start profiling if enabled
   .VAR/DM1 $cbops.profile_stereo_upsample_int[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;

   r0 = &$cbops.profile_stereo_upsample_int;
   call $profiler.start;
#endif


   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.resample.INPUT_1_START_INDEX_FIELD];
   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I4
   // an increment will be added later then assign the sum to another AG
   I4 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L4
   L4 = r1;

   // dummy read to move the pointer back by 33 elements
   M0 = -33;
   r2 = M[I4,M0];
   r2 = I4;
   M[&temp_index_1] = r2;

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.resample.INPUT_2_START_INDEX_FIELD];
   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I1
   // an increment will be added later then assign the sum to another AG
   I1 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L1
   L1 = r1;

   // dummy read to move the pointer back by 33 elements
   r2 = M[I1,M0];
   r2 = I1;
   M[&temp_index_2] = r2;

   // get the offset to the first write buffer to use
   r0 = M[r8 + $cbops.resample.OUTPUT_1_START_INDEX_FIELD];
   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I5
   I5 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L5
   L5 = r1;

   // get the offset to the first write buffer to use
   r0 = M[r8 + $cbops.resample.OUTPUT_2_START_INDEX_FIELD];
   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I0
   I0 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L0
   L0 = r1;

   // get the index to coefficient buffer
   r5 = M[r8 + $cbops.resample.COEF_BUF_INDEX_FIELD];
   // store in I3, an increment will be added later, then
   // assign the sum to I2;
   I3 = r5;

   // get the sampling conversion ratio, Ratio_in/Ratio_out
   // it is the integral fraction of Freq_in/Freq_out
   // for upsampling, it is a fraction.
   r5 = M[r8 + $cbops.resample.CONVERT_RATIO_FRAC_FIELD];

   // get the R_out, which is a integer
   r6 = M[r8 + $cbops.resample.RATIO_OUT_FIELD];

   // load the sample counter
   r3 = M[&sample_count];

   // set the M3 to used in mirroring
   I6 = I3 + 680;
   I6 = I6 + I3;

   // for sign invertion
   r7 = 1.0;

   M0 = 1;

   // M reg for use in coef calculation
   // setup M1, = 2 * Filter_coef_interpolation_factor
   M1 = 20;
   M2 = -20;

   // M reg for zero offset data indexing
   M3 = 16;

   // *** start of main loop

   // loop all the available samples in the buffer
   r4 = 0;

   do loop;
      // restore the input starting index
      r0 = M[&temp_index_1];
      I4 = r0;
      r0 = M[&temp_index_2];
      I1 = r0;

      // input sample counter
      // r3 = 0,1,2,,,(R_out-1),0,1,,,(repeats),,,
      Null = r3 - r6;
      // skip all the zero multiplication if r3 should become zero
      if GE jump zero_offset;

         // mod[ input_sample_counter * convert_ratio, 1]
         r2 = r3 * r5 (int);
         if NEG r2 = r7 + r2;

         // determine whether move onto next input sample
         Null = r5 - r2;
         if LE jump not_move_ip_fw;
            rMAC = M[I1,M0], r0 = M[I4,M0];

            r0 = I4;
            M[&temp_index_1] = r0;
            r0 = I1;
            M[&temp_index_2] = r0;
         not_move_ip_fw:

         // stop the loop counter when input sample not incremented
         Null = r5 - r2;
         if LE r10 = r10 + M0;

         // Rb = 1 - Rb
         r2 = r7 - r2;

         // int[ Rb * 20]
         // NOTE: unwanted rounding is applied in this instruction
         r0 = r2 * 20 (frac);

         I2 = I3 + r0;
         I7 = I2;

         // * call subroutine to calculate the output
         call $cbops.resample.mono_int_upsample;

         // Coef 33
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];

         // output result
         M[I5,M0] = rMAC;

         // same processing for the other channel
         // Coef 1
         rMAC = r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 2
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 3
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 4
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 5
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 6
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 7
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 8
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 9
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 10
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 11
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 12
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 13
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 14
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 15
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];
         // Coef 16
         rMAC = rMAC + r0 * r2, r0 = M[I7,M1], r2 = M[I1,M0];

         // invert the M reg to perform coef mirroring
         I7 = I6 - I7;

         // Coef 17
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 18
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 19
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 20
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 21
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 22
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 23
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 24
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 25
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 26
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 27
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 28
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 29
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 30
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 31
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 32
         rMAC = rMAC + r0 * r2, r0 = M[I7,M2], r2 = M[I1,M0];
         // Coef 33
         rMAC = rMAC + r0 * r2;

         jump output_result;

      zero_offset:

         r3 = r3 - r3, r0 = M[I1,M0], r2 = M[I4,M0];

         // store the input starting point
         r0 = I4;
         M[&temp_index_1] = r0;
         r0 = I1;
         M[&temp_index_2] = r0;

         r0 = M[I4,M3], r2 = M[I1,M3];
         I2 = I3 + 340;
         r3 = r3 + M0, r0 = M[I2,M0], r2 = M[I4,M0];
         // calculate the first result
         rMAC = r0 * r2, r2 = M[I1,M0];

         //calculate second result and write the first result
         rMAC = r0 * r2, M[I5,M0] = rMAC;

      output_result:

      //increment counter   write the result
      r4 = r4 + M0, M[I0,M0] = rMAC;
   loop:
   // end of loop available samples in the buffer
   L5 = 0;
   L4 = 0;
   L1 = 0;
   L0 = 0;

   // *** end of main loop

   // store the sample counter
   M[&sample_count] = r3;

   // write the amount to write value
   M[$cbops.amount_written] = r4;


#ifdef ENABLE_PROFILER_MACROS
   // stop profiling if enabled
   r0 = &$cbops.profile_stereo_upsample_int;
   call $profiler.stop;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
