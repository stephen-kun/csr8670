// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1394096 $  $DateTime: 2012/09/04 20:58:36 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    IIR resampler stand-alone Processing Module
//
// DESCRIPTION:
//    This processing module uses an IIR and a FIR filter combination to
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
//    The function utilizes its own history buffers and in-place operation is supported
//    for downsampling.  It is designed to operate stand-alone seperate from the
//    cbops and frame sync frameworks.
//    resampling ratios where the numerator or denominator is one are supported.
//      Such as 1:2, 2:1, 1:4, etc.
//    As the frame size is fixed available data/space in buffers is not validated
//
// When using the operator the following data structure is used:
//
//  $iir_resamplev2.INPUT_1_START_INDEX_FIELD    = Port ID or Pointer to cBuffer 
//       for input
//
//  $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD   = Port ID or Pointer to cBuffer
//       for output
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
//      used between stages.  This buffer be allocaed from scratch memory.  If the
//      desired resampling is single stage this pointer may be NULL.
//
//  $iir_resamplev2.INTERMEDIATE_CBUF_LEN_FIELD = Length of temporary buffer 
//
//  $iir_resamplev2.PARTIAL1_FIELD = Internal parameter used for 1st stage
//      downsampling
//
//  $iir_resamplev2.SAMPLE_COUNT1_FIELD = Internal parameter used for 1st stage
//      polphase tracking
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
#include "cbuffer.h"   
#include "stack.h"

// *****************************************************************************
// MODULE:
//    $iir_resamplev2.Process
//
// DESCRIPTION:
//    Process function for IIR resampler processing module
//
// INPUTS:
//    - r8  = pointer to module structure
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************

.MODULE $M.iir_resamplev2.process;
   .CODESEGMENT IIR_RESAMPLEV2_COPY_PM;
     
$iir_resamplev2.Process:   
   $push_rLink_macro;
   
   // Get Data/Space
   r0 = M[r8 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD];
   call $cbuffer.calc_amount_data;
   r5 = r0;
   r0 = M[r8 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD];
   call $cbuffer.calc_amount_space;
   r7 = r0;
   NULL = r5 - r7;
   if POS r5=r7;
   call $iir_resamplev2.amount_to_use;
   // Set Transfer.  Exit if None
   r10 = r5;
   if LE jump $pop_rLink_and_rts;

   M0 = 1;
   r9 = 1.0;
   I0 = r8;
   push r8,             r0=M[I0,M0];      //INPUT_PTR_FIELD  
   // Get Input Buffer
#ifdef BASE_REGISTER_MODE  
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B1;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I1  = r0;
   L1  = r1,            r0=M[I0,M0];      // OUTPUT_PTR_FIELD     
   // Get output buffer
#ifdef BASE_REGISTER_MODE  
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B5;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   L5 = r1,             r3=M[I0,M0];      //FILTER_DEFINITION_PTR_FIELD 
   I5 = r0,             r2=M[I0,M0];      //INPUT_SCALE_FIELD 
  
   // Check for Bypass?
   NULL = r3,           r5=M[I0,M0];      //OUTPUT_SCALE_FIELD 
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
      call r7;   
      L1  = NULL;
      r10 = r7,     r4=M[I3,M0];   // Function Pointer
      r2  = I1;
      // Restore Buffers from Stack 
      popm <I5,L5>;
      popm <r0,r5>;
      I1 = r0;

#ifdef BASE_REGISTER_MODE 
      pop B5;
#endif   
      
      push r2;      // Store Updated Input Ptr
      r2  = NULL;   // Input is Q8.15
      call r4;
      push I5;      // Store Updated Output Ptr
      jump jp_done;

Perform2ndStage:
   r0=M[I3,M0];   // Function Pointer
   nop;
   call r0;
   push I1;       // Store Updated Input Ptr
   push I5;       // Store Updated Output Ptr
jp_done:
   // Restore Data Object
   pop I5;
   pop I1;
jp_done2:   
   pop r8;
   
   // Clear Circular Registsers
   L1 = NULL;
   L5 = NULL;

   push NULL;
   B0 = M[SP-1];
   B1 = M[SP-1];
   B4 = M[SP-1];
   pop   B5;
    
   // Update output frame size 
   r0 = M[r8 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD];
   r1 = I5;
   call $cbuffer.set_write_address;
   
   r0 = M[r8 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD];
   r1 = I1;
   call $cbuffer.set_read_address;
   
   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
jp_passthrough:

   do lp_copy;
        rMAC=M[I1,M0];
        rMAC = rMAC ASHIFT r2;
        rMAC = rMAC ASHIFT r5;
        M[I5,M0]=rMAC;
   lp_copy:
   jump jp_done2;

.ENDMODULE;



