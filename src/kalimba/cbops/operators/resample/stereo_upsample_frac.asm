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

.MODULE $M.cbops.stereo_upsample_frac;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.stereo_upsample_frac[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,         // reset function
      &$cbops.resample.upsample_amount_to_use,    // amount to use function
      &$cbops.stereo_upsample_frac.main;          // main function

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbops.stereo_upsample_frac.main
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


.MODULE $M.cbops.stereo_upsample_frac.main;
   .CODESEGMENT CBOPS_STEREO_UPSAMPLE_FRAC_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.stereo_upsample_frac.main:

   $push_rLink_macro;


   .VAR sample_count   = 0;
   .VAR temp_index_1   = 0;
   .VAR temp_index_2   = 0;
   .VAR temp_r8        = 0;
   .VAR temp_ratio     = 0;

   // used for temp store of coef
   .VAR/DM1 temp_buf[33];


#ifdef ENABLE_PROFILER_MACROS
   // start profiling if enabled
   .VAR/DM1 $cbops.profile_stereo_upsample_frac[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;

   r0 = &$cbops.profile_stereo_upsample_frac;
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
   // assign the sum to another AG;
   I3 = r5;

   // get the R_out, which is a integer
   r6 = M[r8 + $cbops.resample.RATIO_OUT_FIELD];

   // load the sample counter
   r3 = M[&sample_count];

   // get the sampling conversion ratio, Ratio_in/Ratio_out
   // it is the integral fraction of Freq_in/Freq_out
   // for upsampling, it is a fraction.
   r5 = M[r8 + $cbops.resample.CONVERT_RATIO_FRAC_FIELD];
   // store the convertion ratio
   M[&temp_ratio] = r5;

   // store r8 to free r8
   M[&temp_r8] = r8;

   // set the M3 to used in mirroring
   r8 = I3 + 680;
   r8 = r8 + I3;

   // for sign invertion
   r7 = 1.0;

   M0 = 1;

   // M reg for use in coef calculation
   // setup M1, = 2 * Filter_coef_interpolation_factor
   M1 = 20;
   M2 = -20;

   // *** start of main loop

   // loop all the available samples in the buffer
   r4 = 0;

   do loop;
      // load conversion ratio
      r5 = M[&temp_ratio];

      // input sample counter
      // r3 = 0,1,2,,,(R_out-1),0,1,,,(repeats),,,
      Null = r3 - r6;
      if GE r3 = r3 - r3;

      // mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int);
      if NEG r2 = r7 + r2;

      // determine whether move onto next input sample
      r0 = M[&temp_index_1];
      I4 = r0;
      r0 = M[&temp_index_2];
      I1 = r0;

      Null = r5 - r2;
      if LE jump not_move_ip_fw;
         rMAC = M[I4,M0], r0 = M[I1,M0];
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

      // Rd = mod[ Rb * 20, 1]
      r1 = r2 * 20 (int);
      if NEG r1 = r7 + r1;

      // int[ Rb * 20]
      // NOTE: unwanted rounding is applied in this instruction
      r0 = r2 * 20 (frac);
      Null = r1 - 0.5;
      if GT r0 = r0 - M0;

      I2 = I3 + r0;

      I7 = I3;
      I3 = &temp_buf;

      // * call subroutine to calculate the first channel
      call $cbops.resample.stereo_frac_1st_channel;

      // move the pointer back to start of temp_buf
      I3 = I7;
      I7 = &temp_buf;

      // calculate the 33 coef and load the data for next one
      rMAC =rMAC + r0 * r2(SS), r0 = M[I7,M0], r2 = M[I1,M0];

      //increment counter       write the result
      r4 = r4 + M0, M[I5,M0] = rMAC;

      // * call subroutine to calculate the second channel
      call $cbops.resample.stereo_frac_2nd_channel;

      M[I0,M0] = rMAC;
   loop:
   // end of loop available samples in the buffer
   L0 = 0;
   L1 = 0;
   L4 = 0;
   L5 = 0;

   // *** end of main loop

   // restore r8 value
   r8 = M[&temp_r8];

   // store the sample counter
   M[&sample_count] = r3;

   // write the amount to write value
   M[$cbops.amount_written] = r4;

#ifdef ENABLE_PROFILER_MACROS
   // stop profiling if enabled
   r0 = &$cbops.profile_stereo_upsample_frac;
   call $profiler.stop;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
