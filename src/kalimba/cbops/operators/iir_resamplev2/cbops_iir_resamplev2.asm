// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1172207 $  $DateTime: 2011/12/09 20:46:31 $
// *****************************************************************************

#include "cbops.h"
#include "core_library.h"
#include "iir_resamplev2_header.h"

// *****************************************************************************
// NAME:
//    IIR resampler cbops operator
//
// DESCRIPTION:
//    This operator uses an IIR and a FIR filter combination to
//    perform sample rate conversion.  The utilization of the IIR
//    filter allows a lower order FIR filter to be used to obtain
//    an equivalent frequency response.  The result is that the
//    IIR resampler uses less MIPs than the current polyphase FIR method.
//    It also provides a better frequency response.
//
//    To further reduce coefficients for a given resampling up to two
//    complete filter stages are supported.  The configurations include.
//          IIR --> FIR(10)
//          FIR(10) --> IIR
//          FIR(6) --> FIR(10) --> IIR
//          FIR(6) --> IIR --> FIR(10)
//          IIR --> FIR(10) --> IIR --> FIR(10)
//          IIR --> FIR(10) --> FIR(10) --> IIR
//          FIR(10) --> IIR --> IIR --> FIR(10)
//          FIR(10) --> IIR --> FIR(10) --> IIR
//
//    The IIR filter may be from 9th order to 19 order.
//
//    The FIR filters are implemented in a polyphase configuration. The FIR(6)
//    filter uses a 6th order polyphase kernal and the FIR(10) filter uses a
//    10th order polyphase kernal.  The filters are symetrical so only half the
//    coefficients need to be stored.
//
//    The operator utilizes its own history buffers.  As a result the input and/or
//    output may be a port.  Also, for downsampling, in-place operation is supported.
//
//    If the resampler operator is not the last operator in the cbops chain and the
//    input is not a port, the "$cbops.iir_resamplev2_complete" must be included at
//    the end of the operator chain.  The completion operator resets M[$cbops.amount_to_use]
//    to the amount of input processed so the input cBuffer can be correctly advanced.
//
// When using the operator the following data structure is used:
//
//  $iir_resamplev2.INPUT_1_START_INDEX_FIELD    = The index of the input
//       buffer
//
//  $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD   = The index of the output
//       buffer
//
//  $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD  = Pointer to configuration
//       object defining the supported sample rate conversions.  These objects are
//       constants in defined iir_resamplev2_coefs.asm
//
//  $iir_resamplev2.INPUT_SCALE_FIELD = A power of 2 scale factor applied
//       to the input signal to scale it to a Q8.15 resolution (i.e 16-bits).
//
//  $iir_resamplev2.OUTPUT_SCALE_FIELD  = A power of 2 scale factor applied
//       to the output signal to scale it from the internally used Q8.15 resolution
//
//  $iir_resamplev2.INTERMEDIATE_CBUF_PTR_FIELD = Pointer to a temporary buffer
//      used between stages.  This buffer may be allocaed from scratch memory.  If the
//      desired resampling is single stage this pointer may be NULL.
//
//  $iir_resamplev2.INTERMEDIATE_CBUF_LEN_FIELD = Length of temporary buffer
//
//  $iir_resamplev2.PARTIAL1_FIELD = Internal parameter used for 1st stage
//      downsampling
//
//  $iir_resamplev2.SAMPLE_COUNT1_FIELD = Internal parameter used for 1st stage
//      polyphase tracking
//
//  $iir_resamplev2.FIR_HISTORY_BUF1_PTR_FIELD = Pointer for 1st stage FIR filter.
//      For elvis this is a seperate circular buffer.  Otherewise, it is allocated
//      from the end of this data structure in the reset operation.  If the
//      desired resampling is single stage this pointer may be NULL.
//
//  $iir_resamplev2.IIR_HISTORY_BUF1_PTR_FIELD  = Pointer for 1st stage IIR filter.
//      For elvis this is a seperate circular buffer.  Otherewise, it is allocated
//      from the end of this data structure in the reset operation.  If the
//      desired resampling is single stage this pointer may be NULL.
//
//  $iir_resamplev2.PARTIAL2_FIELD  = Internal parameter used for 2nd stage
//      downsampling
//
//  $iir_resamplev2.SAMPLE_COUNT2_FIELD = Internal parameter used for 2nd stage
//      polphase tracking
//
//  $iir_resamplev2.FIR_HISTORY_BUF2_PTR_FIELD  = Pointer for 2nd stage FIR filter.
//      For elvis this is a seperate circular buffer.  Otherewise, it is allocated
//      from the end of this data structure in the reset operation.
//
//  $iir_resamplev2.IIR_HISTORY_BUF2_PTR_FIELD  = Pointer for 1st stage IIR filter.
//      For elvis this is a seperate circular buffer.  Otherewise, it is allocated
//      from the end of this data structure in the reset operation.
//
//  $iir_resamplev2.RESET_FLAG_FIELD = Zero to indicate that the resampler needs
//      to be re-initialied
//
// *****************************************************************************


.MODULE $M.cbops.iir_resamplev2;
   .DATASEGMENT DM;

    .VAR amount_used;

   // ** function vector **
   .VAR $cbops_iir_resamplev2[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,         // reset function
      &$cbops.iir_resamplev2.amount_to_use,  // amount to use function
      &$cbops.iir_resamplev2.main;           // main function

.ENDMODULE;

.MODULE $M.cbops.iir_resamplev2_complete;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops_iir_resamplev2_complete[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,         // reset function
      $cbops.function_vector.NO_FUNCTION,         // amount to use function
      $cbops.iir_resamplev2.complete;             // main function

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbops.iir_resamplev2.complete
//
// DESCRIPTION:
//    operator main function to complete resampling
//    This operator is the last in the chain.  Reseting $cbops.amount_to_use
//    to correctly advance the input buffer
//
// INPUTS:
//    - r6  = pointer to the list of input and output buffer pointers
//    - r7  = pointer to the list of buffer lengths
//    - r8  = pointer to operator structure
//    - r10 = the number of samples to generate
//
// OUTPUTS:
//    - r8  = pointer to operator structure
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************
.MODULE $M.cbops.iir_resamplev2.complete;
   .CODESEGMENT IIR_RESAMPLEV2_CBOPS_PM;
$cbops.iir_resamplev2.complete:
    // If Last operator in chain then set $cbops.amount_to_use to advance input buffer
    r4 = M[$M.cbops.iir_resamplev2.amount_used];
    M[$cbops.amount_to_use] = r4;
    rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops_iir_resamplev2.amount_to_use
//
// DESCRIPTION:
//    operator amount_to_use function for IIR resampler operator
//
// INPUTS:
//    - r5 = amount of input data to use
//    - r6 = minimum available input amount
//    - r7 = minimum available output amount
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    - r5 = amount of input data to use
//    - r8  = pointer to operator structure
//
// TRASHED REGISTERS:
//    r0, r1, r2, r10, I0
//
// *****************************************************************************
.MODULE $M.cbops_iir_resamplev2.amount_to_use;
   .CODESEGMENT IIR_RESAMPLEV2_CBOPS_PM;

$cbops.iir_resamplev2.amount_to_use:
   // Clear Amount to use (stereo support)
   M[$M.cbops.iir_resamplev2.amount_used]=NULL;

$iir_resamplev2.amount_to_use:
   // Get resampling configuration
   r2 = M[r8 + $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD];
   if Z rts;
   M0 = 1;
   // Check Output
   I2 = r2;
   // Limit Input by space for resampled output
   r2 = r2-r2,              r0 = M[I2,M0];     // resample int_ratio
   rMAC  = r0 * r7 (int),   r1 = M[I2,M0];     // resample frac_ratio
   rMAC  = rMAC  + r1*r7;
   rMAC=rMAC-M0;
   if NEG rMAC = NULL;
   // Limit Transfer
   Null = r5 - rMAC,        r0 = M[I2,M0];     // resample int_ratio, 1st Stage
   if POS r5 = rMAC;
   // Check 1st Stage
   r4 = M[r8 + $iir_resamplev2.INTERMEDIATE_CBUF_LEN_FIELD];
   // Limit Input by space in temp buffer
   rMAC  = r0 * r4 (int),   r1 = M[I2,M0];     // resample frac_ratio
   rMAC  = rMAC  + r1*r4;
   if Z jump jp_done;
       rMAC=rMAC-M0;
       if NEG rMAC = NULL;
       // Limit Transfer
       Null = r5 - rMAC;
       if POS r5 = rMAC;
jp_done:

   // Check Reset flag
   Null = M[r8 + $iir_resamplev2.RESET_FLAG_FIELD];
   if NZ rts;

   $push_rLink_macro;
   r3 = M[r8 + $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD];
   M[r8 + $iir_resamplev2.RESET_FLAG_FIELD] = r3;

   // History Buffers appended to end of data structure
   r4 = r8 + $iir_resamplev2.STRUC_SIZE;

   // 1st Stage Function Pointer
   I2 = r8 + $iir_resamplev2.PARTIAL2_FIELD;
   I3 = r3 + 5;
   NULL = M[r3+4];
   if Z jump Reset2ndStage;
      I2 = r8 + $iir_resamplev2.PARTIAL1_FIELD;
      call $reset_iir_resampler;
Reset2ndStage:
      I3 = I3 + M0;  // Skip Function Pointer
      call $reset_iir_resampler;
   L0 = NULL;
   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops_iir_resamplev2.main
//
// DESCRIPTION:
//    operator main function for IIR resampler operator
//
// INPUTS:
//    - r6  = pointer to the list of input and output buffer pointers
//    - r7  = pointer to the list of buffer lengths
//    - r8  = pointer to operator structure
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - r8  = pointer to operator structure
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************
.MODULE $M.cbops_iir_resamplev2.main;      // Upsample
   .CODESEGMENT IIR_RESAMPLEV2_CBOPS_PM;
   .DATASEGMENT DM;

$cbops.iir_resamplev2.main:
   $push_rLink_macro;
   push FP;

   M0 = 1;
   r9 = 1.0;
   I0 = r8;
   push r8,             r0=M[I0,M0];      //INPUT_1_START_INDEX_FIELD
   r1 = M[r6 + r0];
   I1 = r1,             r4=M[I0,M0];      //OUTPUT_1_START_INDEX_FIELD
   r1 = M[r7 + r0];
   L1 = r1,             r3=M[I0,M0];      //FILTER_DEFINITION_PTR_FIELD
   r1 = M[r6 + r4];
   I5 = r1,             r2=M[I0,M0];      //INPUT_SCALE_FIELD 
   r1 = M[r7 + r4];
   L5 = r1;
#ifdef BASE_REGISTER_MODE 
   // Set base registers for IO
   r1 = M[r5 + r0];
   push r1;
   pop  B1;
   r1 = M[r5 + r4];
   push r1;
   pop  B5;
#endif  
   
   // r8 - operarator params
   // r3 - Filter Definitions
   // r2 - Input Scale
   // r5 - Output Scale
   // r10 - Amount of Input
   // I1,L1,B1 - Input buffers
   // I5,L5,B5 - Output Buffers

   // Check and update amount of input (stereo support)
   r1 = M[$M.cbops.iir_resamplev2.amount_used];
   if NZ r10=r1, r5=M[I0,M0];      //OUTPUT_SCALE_FIELD
   M[$M.cbops.iir_resamplev2.amount_used] = r10;

   // Check for Bypass?
   NULL = r3;
   if Z jump jp_passthrough;


   // History Buffers appended to end of data structure
   r4 = r8 + $iir_resamplev2.STRUC_SIZE;
   push r4;
   pop FP;

   // 1st Stage Function Pointer
   I2 = r8 + $iir_resamplev2.PARTIAL2_FIELD;
   I3 = r3 + 5;     // Points to Field After Function Pointer
   r7 = M[r3+4];    // First Function Pointer
   if Z jump Perform2ndStage;
      r0 = M[r8+$iir_resamplev2.INTERMEDIATE_CBUF_PTR_FIELD];
      // Save Buffers on stack
#ifdef BASE_REGISTER_MODE
      push B5;
#endif
      pushm <r0,r5>;
      pushm <I5,L5>;

      // Set Temp Buffer (r0) as output
      I5 = r0;
      L5 = NULL;
      r5 = NULL;    // Make Output Is Q8.15
      I2 = r8 + $iir_resamplev2.PARTIAL1_FIELD;

      //    I1  - Input (Circ)
      //    I5  - Output (Temp - Linear)
      //    r2  - Input Scaling Factor
      //    r5  - Output Scaling Factor
      //    r10 - amount of input (consumed)
      //    M0  = 1
      //    r9  = 1.0
      //    I3  - Config Pointer
      //    I2  - State Variable Pointer
      call r7;
      // Use Temp Buffer for next Stage Input (Linear)
      L1  = NULL;
      r10 = r7;
      r2  = NULL;      // Input is Q8.15

      // Restore Buffers from Stack
      popm <I5,L5>;
      popm <r0,r5>;
      I1 = r0;

#ifdef BASE_REGISTER_MODE
      pop B5;
#endif

Perform2ndStage:
   r0=M[I3,M0];   // Function Pointer
   nop;
   //    I1  - Input (Circ)
   //    I5  - Output (Circ)
   //    r2  - Input Scaling Factor
   //    r5  - Output Scaling Factor
   //    r10 - amount of input (consumed)
   //    M0  = 1
   //    r9  = 1.0
   //    I3  - Config Pointer
   //    I2  - State Variable Pointer
   call r0;

   // number of output samples generated
   M[$cbops.amount_written] = r7;

   // Restore Data Object
jp_done:
   pop r8;

   // Clear Circular Registsers
   L1 = NULL;
   L5 = NULL;

   push NULL;
   B0 = M[SP-1];
   B1 = M[SP-1];
   B4 = M[SP-1];
   pop   B5;

   // If not Last operator in chain then set M[$cbops.amount_to_use] to amount of output generated
   // Othwerise, set it to the amount of input consumed.
   // Will need completion operator to reset M[$cbops.amount_to_use] if input is not a port
   // and a resampler operator is not the last operator in the chain.
   r1 = M[$M.cbops.iir_resamplev2.amount_used];

   r0 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];
   Null = r0 - $cbops.NO_MORE_OPERATORS;
   if Z r7=r1;
   M[$cbops.amount_to_use] = r7;

   pop FP;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

jp_passthrough:

   r7=r10;
   do lp_copy;
        rMAC=M[I1,M0];
        rMAC = rMAC ASHIFT r2;
        rMAC = rMAC ASHIFT r5;
        M[I5,M0]=rMAC;
   lp_copy:

   jump jp_done;

.ENDMODULE;








