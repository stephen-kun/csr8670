// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1921919 $  $DateTime: 2014/06/18 21:18:28 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Shift operator
//
// DESCRIPTION:
//  This operator shifts the data by the supplied amount, using the arithmetic
//  shift operator (ASHIFT).
//
//  Note as Kalimba typically reads data from periphals as 16 bit words using
//  the ASHIFT operator can generate unexpected results.
//
//  If a positive number is shifted and the result becomes negative, the ASHIFT
//  operator will saturate the result. If external data is read by Kalimba as
//  16 bit data and zero padded to 24 bit, the values will all be interpreted as
//  positive numbers, even if they were negative 16 bit numbers.
//
//  Therefore if data read from peripherals is to be shifted to 24 bit data it
//  is recommended you use the $cbuffer.FORCE_SIGN_EXTEND flag to force Kalimba
//  to sign extend the data as it reads it.
//
// When using the operator the following data structure is used:
//    - $cbops.shift.INPUT_START_INDEX_FIELD = the index of the input buffer
//    - $cbops.shift.OUTPUT_START_INDEX_FIELD = the index of the output
//       buffer
//    - $cbops.shift.SHIFT_AMOUNT_FIELD = amount to shift input value by
//       (eg. 8, -8)
// *****************************************************************************

#include "stack.h"
#include "cbops.h"

.MODULE $M.cbops.shift;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.shift[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,   // reset function
      $cbops.function_vector.NO_FUNCTION,   // amount to use function
      &$cbops.shift.main;                   // main function

   .VAR $cbops.shift_24bit[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,   // reset function
      $cbops.function_vector.NO_FUNCTION,   // amount to use function
      &$cbops.shift_24bit.main;                   // main function
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.shift.main
//
// DESCRIPTION:
//    Operator that shifts the input word
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
//    r0-2, r10, I0, I4, L0, L4, DoLoop
//
// *****************************************************************************
// *****************************************************************************
// MODULE:
//    $cbops.shift.main
//
// DESCRIPTION:
//    Operator that copies 24 bit audio samples from a cbuffer into an output
// port and applies a specified shift. The port should be configured as
// $cbuffer.FORCE_24B_PCM_AUDIO.
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
//    r0-3, r10, I0, I4, L0, L4, DoLoop
//
// *****************************************************************************
.MODULE $M.cbops.shift.main;
   .CODESEGMENT CBOPS_SHIFT_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.shift_24bit.main:
      M0 = 1;
      jump ready;

   $cbops.shift.main:
      M0 = 0;
      // fallthrough

   ready:
   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $cbops.profile_shift[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      $push_rLink_macro;
      r0 = &$cbops.profile_shift;
      call $profiler.start;
   #endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.shift.INPUT_START_INDEX_FIELD];

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

   // get the offset to the write buffer to use
   r0 = M[r8 + $cbops.shift.OUTPUT_START_INDEX_FIELD];

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

   // read the shift amount to use from the parameter area
   r2 = M[r8 + $cbops.shift.SHIFT_AMOUNT_FIELD];

   // for speed pipeline the: read -> shift -> write
   r10 = r10 - 1;
   r0 = M[I0,1];
   r0 = r0 ASHIFT r2;
   
   Null = M0;
   if NZ jump do_double_write;
      do loop;
         r0 = M[I0,1], M[I4,1] = r0;
         r0 = r0 ASHIFT r2;
      loop:
   jump done;

   do_double_write:
      #ifdef DEBUG_ON
         // in this mode we only support ports so check the output is actually
         // a port
         Null = L4 - 1;
         if NZ call $error;
      #endif
      r1 = r0 LSHIFT 8;
      r0 = r0 LSHIFT -8;
      do two_write_loop;
         r3 = M[I0,1], M[I4,1] = r1;
         M[I4, 1] = r0;
         r3 = r3 ASHIFT r2;
         r1 = r3 LSHIFT 8;
         r0 = r3 LSHIFT -8;
      two_write_loop:
      // write the first half of the last sample
      M[I4,1] = r1;
   // fallthrough

   done:
   // zero the length registers and write the last sample
   L0 = 0, M[I4,1] = r0;
   L4 = 0;
   #ifdef BASE_REGISTER_MODE
      // Zero the base registers
      push Null;
      B4 = M[SP-1];
      pop B0;
   #endif

   // stop profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      r0 = &$cbops.profile_shift;
      call $profiler.stop;
      $pop_rLink_macro;
   #endif
   rts;

.ENDMODULE;


