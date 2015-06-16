// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
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
//   $cbops.mono_upsample.INPUT_1_START_INDEX_FIELD
//   $cbops.mono_upsample.OUTPUT_1_START_INDEX_FIELD
//   $cbops.mono_upsample.COEF_BUF_INDEX_FIELD
//   $cbops.mono_upsample.CONVERT_RATIO
//   $cbops.mono_upsample.RATIO_OUT
//
//
// *****************************************************************************

#include "stack.h"
#include "cbops.h"

.MODULE $M.cbops.mono_upsample_frac;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.mono_upsample_frac[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,         // reset function
      &$cbops.resample.upsample_amount_to_use,    // amount to use function
      &$cbops.mono_upsample_frac.main;            // main function

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbops.mono_resample.main
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


.MODULE $M.cbops.mono_upsample_frac.main;
   .CODESEGMENT CBOPS_MONO_UPSAMPLE_FRAC_MAIN_PM;
   .DATASEGMENT DM;

$cbops.mono_upsample_frac.main:

   $push_rLink_macro;


   .VAR sample_count   = 0;

#ifdef ENABLE_PROFILER_MACROS
   // start profiling if enabled
   .VAR/DM1 $cbops.profile_mono_upsample_frac[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;

   r0 = &$cbops.profile_mono_upsample_frac;
   call $profiler.start;
#endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.resample.INPUT_1_START_INDEX_FIELD];

   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I1
   // an increment will be added later then assign the sum to I4
   I1 = r1;
   I4 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L1
   L1 = r1;
   L4 = r1;

   // dummy read to move the pointer back by 33 elements
   M0 = -33;
   r2 = M[I1,M0];


   // get the offset to the first write buffer to use
   r0 = M[r8 + $cbops.resample.OUTPUT_1_START_INDEX_FIELD];
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
   M3 = I3 + 680;
   M3 = M3 + I3;


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


      // input sample counter
      // r3 = 0,1,2,,,(R_out-1),0,1,,,(repeats),,,
      NULL = r3 - r6;
      if GE r3 = r3 - r3;

      // mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int);
      if NEG r2 = r7 + r2;

      // determine whether move onto next input sample
      NULL = r5 - r2;
      if LE jump not_move_ip_fw;
          rMAC = M[I1,M0];
not_move_ip_fw:

      I4 = I1;


      // stop the loop counter when input sample not incremented
      NULL = r5 - r2;
      if LE r10 = r10 + M0;

      // Rb = 1 - Rb
      r2 = r7 - r2;

      // Rd = mod[ Rb * 20, 1]
      r1 = r2 * 20 (int);
      if NEG r1 = r7 + r1;

      // int[ Rb * 20]
      // NOTE: unwanted rounding is applied in this instruction
      r0 = r2 * 20 (frac);
      NULL = r1 - 0.5;
      if GT r0 = r0 - M0;


      I2 = I3 + r0;

      // Coefficients 1-9 do not apply linear interpolation
      // Coef 1
      //            next coef      sample data
      r3 = r3 + M0, r0 = M[I2,M1], r2 = M[I4,M0];
      //                   next coef      sample data
      rMAC = r0 * r2 (SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 2
      //                         next coef      sample data
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 3
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 4
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 5
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 6
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 7
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // Coef 8
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M1], r2 = M[I4,M0];

      // I6 point to one data ahead of I2
      I6 = I2 + 1;

      // Coef 9                  r0=next coef,  r2=current coef
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];


      // Coefficients 10-24 require linear interpolation
      // Coef 10
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      //            sample data
      r0 = r0 + r2, r2 = M[I4,M0];
      //                         next coef      current coef
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

      // Coef 11
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

      // Coef 12
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

      // Coef 13
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

          // Coef 14
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

      // Coef 15
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

      // Coef 16
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M1], r2 = M[I2,M1];

      // Coef 17
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];


      // invert the M reg to perform coef mirroring
      I2 = M3 - I2;
      I6 = I2 - 1;


      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

          // Coef 18
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

      // Coef 19
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

      // Coef 20
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

      // Coef 21
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

      // Coef 22
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

      // Coef 23
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];
      rMAC = rMAC + r0 * r2(SS), r0 = M[I6,M2], r2 = M[I2,M2];

      // Coef 24
      r0 = r0 - r2;
      r0 = r0 * r1 (frac);
      r0 = r0 + r2, r2 = M[I4,M0];

      //                         next coef      sample data
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 25
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 26
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 27
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 28
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 29
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 30
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 31
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 32
      rMAC = rMAC + r0 * r2(SS), r0 = M[I2,M2], r2 = M[I4,M0];

      // Coef 33
      rMAC = rMAC + r0 * r2(SS);


      //increment
      //counter     write the result
      r4 = r4 + M0, M[I0,M0] = rMAC;



loop:
   // end of loop available samples in the buffer
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
   r0 = &$cbops.profile_mono_upsample_frac;
   call $profiler.stop;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
