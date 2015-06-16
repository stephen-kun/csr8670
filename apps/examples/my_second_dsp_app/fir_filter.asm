// *******************************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2003-2014 http://www.csr.com
//
// FIR Filter Operator performs FIR filter
//
// When using this operator, the following data structure is used:
//    - $user_code.fir_filter.INPUT_START_INDEX_FIELD = Pointer to the input buffer
//    - $user_code.fir_filter.OUTPUT_START_INDEX_FIELD = Pointer to the output buffer
//    - $user_code.fir_filter.COEFFICIENT_BUFFER_ADDR = Pointer to the coefficient buffer
//    - $user_code.fir_filter.HISTORY_BUFFER_ADDR = Pointer to the history buffer
//    - $user_code.fir_filter.FILTER_LENGTH = Length of FIR filter
//    - $user_code.fir_filter.SHIFT_AMOUNT = Shift amount
//
// *******************************************************************************************

#include "stack.h"
#include "user_code.h"


.PUBLIC $user_code.fir_filter;

.MODULE $M.user_code.fir_filter;
   .PRIVATE;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   // ** Function vector **
   .VAR $user_code.fir_filter[$user_code.function_vector.STRUC_SIZE] =
      $user_code.function_vector.NO_FUNCTION,         // Reset function, not used
      $user_code.function_vector.NO_FUNCTION,         // Amount to use function, not used
      $user_code.fir_filter.main;                     // Main function

.ENDMODULE;


// *******************************************************************************************
// MODULE:
//    $user_code.fir_filter.main
//
// DESCRIPTION:
//    Single channel FIR filter function
//
// INPUTS:
//    - r6 = Pointer to the list of input and output buffer pointers
//    - r7 = Pointer to the list of buffer lengths
//    - r8 = Pointer to operator structure
//    - r10 = Number of samples to process
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-5, r10, rMAC, I0, I1, I4, I5, L0, L1, L4, L5, DoLoop
//
// *******************************************************************************************
.MODULE $M.user_code.fir_filter.main;
   .PRIVATE;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $user_code.fir_filter.main:
   // push rLink onto stack
   $push_rLink_macro;

   // Get the offset to the read buffer to use
   r0 = M[r8 + $user_code.fir_filter.INPUT_START_INDEX_FIELD];

   // Get the input buffer read address
   r1 = M[r6 + r0];
   // Store the value in I0
   I0 = r1;
   // Get the input buffer length
   r1 = M[r7 + r0];
   // Store the value in
   L0 = r1;

   // Get the offset to the write buffer to use
   r0 = M[r8 + $user_code.fir_filter.OUTPUT_START_INDEX_FIELD];

   // Get the output buffer write address
   r1 = M[r6 + r0];
   // Store the value in I4
   I4 = r1;
   // Get the output buffer length
   r1 = M[r7 + r0];
   // Store the value in L4
   L4 = r1;

   // Set coefficient buffer's base address
   r0 = M[r8 + $user_code.fir_filter.COEFFICIENT_BUFFER_ADDR];
   I1 = r0;

   // Load shift amount
   r3 = M[r8 + $user_code.fir_filter.SHIFT_AMOUNT];

   // Load history buffer pointer
   r0 = M[r8 + $user_code.fir_filter.HISTORY_BUFFER_ADDR];
   I5 = r0;

   r0 = M[r8 + $user_code.fir_filter.FILTER_LENGTH];
   L5 = r0;
   L1 = r0;

   do loop;
      r0 = M[I0,1];

      r0 = r0 ASHIFT r3;
      // Store sample into memory address I5 circular buffer;
      M[I5, 0] = r0;

      // Start loop for summing (filter length samples * filter coefficients)
      r5 = L5;
      rMAC = 0.0;                         // Clear rMAC
      sum_loop1:
         r1 = M[I1,1],   r2 = M[I5,1],     // r1 = h(0)   r2 = x(n)
         rMAC = rMAC + r1 * r2;
         r5 = r5 - 1;
      if NZ jump sum_loop1;

      // Dummy read to decrement I5
      r2 = M[I5, -1];

      // Output sample from delay loop buffer
      M[I4,1] = rMAC;
   loop:

   // Update history buffer pointer
   r0 = I5;
   M[r8 + $user_code.fir_filter.HISTORY_BUFFER_ADDR] = r0;

   // Zero the length registers and write the last sample
   L0 = 0;
   L1 = 0;
   L5 = 0;
   L4 = 0;

   // pop rLink from stack
   $pop_rLink_macro;

   rts;

.ENDMODULE;
