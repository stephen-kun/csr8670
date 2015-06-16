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
//    This is a music quality sample rate convertor.
//
// When using the operator the following data structure is used:
//
//   $cbops.mono_resample.INPUT_1_START_INDEX_FIELD
//   $cbops.mono_resample.OUTPUT_1_START_INDEX_FIELD
//   $cbops.mono_resample.COEF_BUF_INDEX_FIELD
//   $cbops.mono_resample.CONVERT_RATIO
//   $cbops.mono_resample.RATIO_IN
//   $cbops.mono_resample.RATIO_OUT
//
//
// *****************************************************************************

#include "stack.h"
#include "cbops.h"

.MODULE $M.cbops.stereo_downsample_int;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.stereo_downsample_int[$cbops.function_vector.STRUC_SIZE] =
       $cbops.function_vector.NO_FUNCTION,         // reset function
       &$cbops.resample.downsample_amount_to_use,  // amount to use function
       &$cbops.stereo_downsample_int.main;               // main function

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbops.stereo_downsample_int.main
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


.MODULE $M.cbops.stereo_downsample_int.main;
   .CODESEGMENT CBOPS_STEREO_DOWNSAMPLE_INT_MAIN_PM;

   $cbops.stereo_downsample_int.main:

   $push_rLink_macro;


#ifdef ENABLE_PROFILER_MACROS
   // start profiling if enabled
   .VAR/DM1 $cbops.profile_stereo_downsample_int[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;

   r0 = &$cbops.profile_stereo_downsample_int;
   call $profiler.start;
#endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.resample.INPUT_1_START_INDEX_FIELD];
   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I4
   I4 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L4
   L4 = r1;

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.resample.INPUT_2_START_INDEX_FIELD];
   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I5
   I5 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L5
   L5 = r1;


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

   // get the offset to the first write buffer to use
   r0 = M[r8 + $cbops.resample.OUTPUT_2_START_INDEX_FIELD];
   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I1
   I1 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L1
   L1 = r1;


   // get the index to coefficient buffer
   r5 = M[r8 + $cbops.resample.COEF_BUF_INDEX_FIELD];
   r5 = r5 + 340;

   // the gain level of the resampler
   r4 = M[r5];

   // get the sampling conversion ratio, Ratio_in/Ratio_out
   // it is the integral fraction of Freq_in/Freq_out
   // for upsampling, it is a fraction.
   // M3 holds the integer part of downsample ratio
   r5 = M[r8 + $cbops.resample.CONVERT_RATIO_INT_FIELD];
   M3 = r5;

   M1 = 1;

   // *** start of main loop
   // loop all the available samples in the buffer
   r5 = 0;
   r10 = r10 - 1;
   r1 = M[I4,M3];
   r2 = M[I5,M3];

   do loop;
      // apply gain level
      r1 = r1 * r4 (frac);
      //                   write result1  read next input1
      r2 = r2 * r4 (frac), M[I0,M1] = r1, r1 = M[I4,M3];

      // increment  write result2  read next input2
      // counter
      r5 = r5 + M3, M[I1,M1] = r2, r2 = M[I5,M3];
   loop:

   r1 = r1 * r4 (frac);
   r4 = r4 + M3, M[I0,M1] = r1;
   r2 = r2 * r4 (frac);
   M[I1,M1] = r2;

   // end of loop available samples in the buffer
   L5 = 0;
   L4 = 0;
   L1 = 0;
   L0 = 0;
   // *** end of main loop

   // amount of input used ###
   M[$cbops.amount_to_use] = r5;


#ifdef ENABLE_PROFILER_MACROS
   // stop profiling if enabled
   r0 = &$cbops.profile_stereo_downsample_int;
   call $profiler.stop;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
