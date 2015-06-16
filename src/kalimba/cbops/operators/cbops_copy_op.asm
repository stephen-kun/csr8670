// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1921919 $  $DateTime: 2014/06/18 21:18:28 $
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
//    - $cbops.copy_op.INPUT_START_INDEX_FIELD = the index of the input
//       buffer
//    - $cbops.copy_op.OUTPUT_START_INDEX_FIELD = the index of the output
//       buffer
//
// *****************************************************************************

#include "cbops.h"
#include "stack.h"

.MODULE $M.cbops.copy_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.copy_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,   // reset function
      $cbops.function_vector.NO_FUNCTION,   // amount to use function
      &$cbops.copy_op.main;                 // main function
      
   .VAR $cbops.copy_op_24bit_audio[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,   // reset function
      $cbops.function_vector.NO_FUNCTION,   // amount to use function
      &$cbops.copy_op_24bit_audio.main;     // main function

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.copy_op.main
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
//    r0-2, r10, I0, L0, I4, L4, DoLoop
//
// *****************************************************************************
// *****************************************************************************
// MODULE:
//    $cbops.copy_op_24bit_audio.main
//
// DESCRIPTION:
//    Operator that copies 24 bit audio samples from a cbuffer into an output
// port. The port should be configured as $cbuffer.FORCE_24B_PCM_AUDIO.
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
//    r0-2, r10, I0, L0, I4, L4, DoLoop
//
// *****************************************************************************
.MODULE $M.cbops.copy_op.main;
   .CODESEGMENT CBOPS_COPY_OP_MAIN_PM;
   .DATASEGMENT DM;
   
   $cbops.copy_op_24bit_audio.main:
      M0 = 1;
      jump ready;
   
   $cbops.copy_op.main:
      M0 = 0;
      // fallthrough

   ready:
   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $cbops.profile_copy_op[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      $push_rLink_macro;
      r0 = &$cbops.profile_copy_op;
      call $profiler.start;
   #endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.copy_op.INPUT_START_INDEX_FIELD];

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
   r0 = M[r8 + $cbops.copy_op.OUTPUT_START_INDEX_FIELD];

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

   // for speed pipeline the: read -> shift -> write
   r10 = r10 - 1;
   r0 = M[I0,1];
   Null = M0;
   if NZ jump do_double_write;
      do loop;
         r0 = M[I0,1], M[I4,1] = r0;
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
         r2 = M[I0,1], M[I4,1] = r1;
         M[I4, 1] = r0;
         r1 = r2 LSHIFT 8;
         r0 = r2 LSHIFT -8;
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
      r0 = &$cbops.profile_copy_op;
      call $profiler.stop;
      $pop_rLink_macro;
   #endif
   rts;

.ENDMODULE;


