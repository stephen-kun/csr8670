// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2013-2014        http://www.csr.com
// Part of ADK 3.5
// $File$
// $Change$  $DateTime$
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Deinterleave operator
//
// DESCRIPTION:
//  This operator de-interleaves input data into two output channels, it also can
//  (arithmatic) shift the output just like shift operator
//
// When using the operator the following data structure is used:
//    - $cbops.deinterleave.INPUT_START_INDEX_FIELD = the index of the input buffer
//    - $cbops.deinterleave.OUTPUT1_START_INDEX_FIELD = the index of the output1
//    - $cbops.deinterleave.OUTPUT2_START_INDEX_FIELD = the index of the output2
//    - $cbops.deinterleave.SHIFT_AMOUNT_FIELD = amount of shift
// *****************************************************************************
#include "stack.h"
#include "cbops.h"
.MODULE $M.cbops.deinterleave;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.deinterleave[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,          // reset function
      $cbops.deinterleave.amount_to_use,           // amount to use function
      &$cbops.deinterleave.main;                   // main function

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $cbops.deinterleave.main
//
// DESCRIPTION:
//    Operator that deinterleaves the input word
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
//    r0-2, r10, I0, I4, I5, L0, L4, L5 DoLoop
//
// *****************************************************************************
.MODULE $M.cbops.deinterleave.main;
   .CODESEGMENT CBOPS_DEINTERLEAVE_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.deinterleave.main:
   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $cbops.profile_deinterleave[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      $push_rLink_macro;
      r0 = &$cbops.profile_deinterleave;
      call $profiler.start;
   #endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.deinterleave.INPUT_START_INDEX_FIELD];

   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I0
   I0 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L0
   L0 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B0;
   #endif

   // get the offset to the first output buffer to use
   r0 = M[r8 + $cbops.deinterleave.OUTPUT1_START_INDEX_FIELD];
   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I4
   I4 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L4
   L4 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B4;
   #endif

   // get the offset to the second output buffer to use
   r0 = M[r8 + $cbops.deinterleave.OUTPUT2_START_INDEX_FIELD];
   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I4
   I5 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L4
   L5 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B5;
   #endif

   // read the shift amount to use from the parameter area
   r2 = M[r8 + $cbops.deinterleave.SHIFT_AMOUNT_FIELD];

   // set amount output
   r10 = r10 LSHIFT -1;
   M[$cbops.amount_written] = r10;

   // de-interleave loop
   r10 = r10 - 1;
   // read first even input
   r0 = M[I0,1];
   do interleave_loop;
      // shift even input, read odd input
      r0 = r0 ASHIFT r2, r1 = M[I0,1];
      // shift odd input, write even output
      r1 = r1 ASHIFT r2, M[I4, 1] = r0;
      // read even input, write odd output
      r0 = M[I0,  1], M[I5, 1] = r1;
   interleave_loop:
   // shift last even input, read last odd input
   r0 = r0 ASHIFT r2, r1 = M[I0,1];
   // shift last odd input, write last even output
   r1 = r1 ASHIFT r2, M[I4, 1] = r0;
   // write last odd output
   L4 = 0, M[I5, 1] = r1;
   L5 = 0;

   #ifdef BASE_REGISTER_MODE
      // Zero the base registers
      push Null;
      B4 = M[SP-1];
      B5 = M[SP-1];
      pop B0;
   #endif

   // stop profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      r0 = &$cbops.profile_deinterleave;
      call $profiler.stop;
      $pop_rLink_macro;
   #endif
   rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//   $cbops.deinterleave.amount_to_use
//
// DESCRIPTION:
//   set the amount of use for the operator, amount of use shall not exceed
//   twice of the available output space
//
// INPUTS:
//    - r5 = the minimum of the number of input samples available and the
//      amount of output space available
//    - r6 = the number of input samples available
//    - r7 = the amount of output space available
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    - r5 = the number of samples to process
//
// TRASHED REGISTERS:
//    r0
//
// *****************************************************************************
.MODULE $M.cbops.deinterleave.amount_to_use;
   .CODESEGMENT CBOPS_DEINTERLEAVE_AMOUNT_TO_USE_PM;
   .DATASEGMENT DM;

   $cbops.deinterleave.amount_to_use:
   // amount to use maximum twice of available output
   r5 = r5 LSHIFT -1;
   Null = r5 - r7;
   if POS r5 = r7;
   r5 = r5 LSHIFT 1;
   rts;
.ENDMODULE;
