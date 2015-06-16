// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 762921 $  $DateTime: 2011/04/07 16:29:18 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Frame Sync Sidetone filter operator
//
// DESCRIPTION:
//    It is desireable to apply a filter to the sidetone.  Also, clipping may need
//    to be applied to address issues in the DAC.
//
//
// When using the operator the following data structure is used:
//    - $frame_sync.sidetone_mix_op.INPUT_START_INDEX_FIELD = the input buffer
//       index
//    - $frame_sync.sidetone_mix_op.OUTPUT_START_INDEX_FIELD = the output
//       buffer index
//    - $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD = the address of the
//       sidetone cbuffer struc
//    - $frame_sync.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD = the number of
//       samples allowed to build up in the sidetone buffer
//    - $frame_sync.sidetone_mix_op.GAIN_FIELD = the address of the gain to
//       apply to the sidetone samples
//
// *****************************************************************************

#include "stack.h"
#include "cbops_vector_table.h"
#include "frame_sync_sidetone_filter_operator.h"
#ifdef PATCH_LIBS
   #include "patch_library.h"
#endif

.MODULE $M.frame_sync.sidetone_filter_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $frame_sync.sidetone_filter_op[$cbops.function_vector.STRUC_SIZE] =
      // reset function
      $cbops.function_vector.NO_FUNCTION,
      // amount to use function
      $cbops.function_vector.NO_FUNCTION,
      // main function
      &$frame_sync.sidetone_filter_op.main;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $frame_sync.sidetone_mix_op.main
//
// DESCRIPTION:
//    Operator that mixes the auxillary audio with the main input
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
//    r0, r1, r2, r3, r5, r6, r10, rMAC, M1, I0, I1, I4, L0, L1, L4, DoLoop
//
// *****************************************************************************


.MODULE $M.frame_sync.sidetone_filter_op.main;
   .CODESEGMENT FRAME_SYNC_SIDETONE_FILTER_OP_MAIN_PM;
   .DATASEGMENT DM;

   $frame_sync.sidetone_filter_op.main:
#if defined(PATCH_LIBS)
   LIBS_PUSH_REGS_SLOW_SW_ROM_PATCH_POINT($frame_sync.FRAME_SYNC_SIDETONE_FILTER_OPERATOR_ASM.MAIN.PATCH_ID_0) // af05_CVC_patches1
#endif

    // If gain is zero skip copy.  SideTone will be zeroed in mix operator

    NULL = M[r8 + $frame_sync.sidetone_filter_op.APPLY_GAIN_FIELD];
    if Z rts;

   // get the offset to the read buffer to use
   r0 = M[r8 + $frame_sync.sidetone_filter_op.INPUT_START_INDEX_FIELD];
   r1 = M[r6 + r0];
   r2 = M[r7 + r0];
   // Input
   I4 = r1;
   L4 = r2;
#ifdef BASE_REGISTER_MODE 
   r1 = M[r5 + r0];
   push r1;
   pop  B4;
#endif   
   
   // get the offset to the write buffer to use
   r0 = M[r8 + $frame_sync.sidetone_filter_op.OUTPUT_START_INDEX_FIELD];
   r3 = M[r6 + r0];
   r4 = M[r7 + r0];
#ifdef BASE_REGISTER_MODE 
   r1 = M[r5 + r0];
   push r1;
   pop  B0;
#endif  
   // Output
   I0 = r3;
   L0 = r4;
     
   NULL = M[r8 + $frame_sync.sidetone_filter_op.APPLY_FILTER];
   if Z jump ApplyGain;
  
#ifdef BASE_REGISTER_MODE 
    // Save output base address
    push B0;
#endif

   // Save Transfer amount, data pointer, and output buffer
   pushm <r3,r4,r8,r10,rLink>;

   // get PEQ filter data object
   r7 = r8 + $frame_sync.sidetone_filter_op.PEQ_START_FIELD;
   // Samples to process
   r4 = r10;
   // PEQ execution
   // Input:  I4,L4,B4      Output:    I0,L0,B0
   call $audio_proc.peq.process_op;
   
   // Restore Registers
   popm <r3,r4,r8,r10,rLink>;

   // Use output as input for Gain operation
   I4 = r3;     
   I0 = r3;     
   L4 = r4;   
   L0 = r4;

#ifdef BASE_REGISTER_MODE 
   // Restore output base address (Also, use output as input) 
   B4 = M[SP-1];
   pop B0;
#endif  
   
ApplyGain:
    // Input:  I4,L4,B4      Output:    I0,L0,B0

    // Parameters for sidetone
    r7 = M[r8 + $frame_sync.sidetone_filter_op.PARAM_PTR_FIELD];

    // Get gain mantisa/exponent for sidetone
    r2 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_GAIN_EXP];
    r3 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_GAIN_MANTISSA];

   // Get inverse of Current DAC gain
    r0 = M[r8 + $frame_sync.sidetone_filter_op.OFFSET_PTR_INV_DAC_GAIN];
    r5 = M[r0];

    // Verify that inverse gain is not greater than the limit value
    // limit is Q9.15, same as the inverse gain.
    r1 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_ST_ADJUST_LIMIT];
    Null = r5 - r1;
    if GT r5 = r1;

    // Consolidated gains in just one value.
    rMAC = r3 * r5;
    // Store rMAC in [current_sidetone_gain] for statistics
    // Note that the format is Q15
    r1 = rMAC;
    r1 = r1 ASHIFT r2;
    M[r8 + $frame_sync.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN]=r1;

    // Result in rMAC is Q15 with leading zeros, so we need to normalize the value and modify the exponent.
    r1 = SIGNDET rMAC;
    r5 = r1 - 8;
    r3 = rMAC ASHIFT r1;
    r6 = r2 - r5;
    // Get clipper limit
    r5 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_ST_CLIP_POINT];

    // Get PeakSideTone Address
    I1 = r8 + $frame_sync.sidetone_filter_op.OFFSET_PEAK_ST;
    M0 = 0;
      // apply gain
      r0 = M[I4,1];
      do gain_loopClip;
         rMAC = r0 * r3, r0 = M[I4,1];
         r1 = rMAC ASHIFT r6;
         // do clipping
         // r4 = sign
         r4 = rMAC ASHIFT 56;
         // Magnitude
         // r1 = abs(r1)
         r1 = r1 * r4 (frac),       r2 = M[I1,M0];
         // Test if magnitude is greater than limit
         Null = r1 - r5;
         if POS r1 = r5;
         // Compare current abs(value) with max(value)
         Null = r2 - r1;
         if LT r2 = r1;
         // Reset sign
         r1 = r1 * r4 (frac),   M[I1,M0] = r2;
         M[I0,1] = r1;
      gain_loopClip:

   // reset L registers
   L0 = 0;
   L4 = 0;
#ifdef BASE_REGISTER_MODE  
   // clear base registers
   push Null;
   B0 = M[SP-1];
   pop B4;
#endif
   rts;

.ENDMODULE;



// INPUTS:
//     r8   - Data structure

.MODULE $M.frame_sync.sidetone_filter_op.SetMode;
   .CODESEGMENT FRAME_SYNC_SIDETONE_FILTER_OP_MODE_PM;

$frame_sync.sidetone_filter_op.SetMode:
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($frame_sync.FRAME_SYNC_SIDETONE_FILTER_OPERATOR_ASM.SETMODE.PATCH_ID_0,r2) // af05_CVC_patches1
#endif

   // Check if SideTone has been enabled globally
   r2 = M[r8 + $frame_sync.sidetone_filter_op.ENABLE_MASK_FIELD];
   r0 = M[r8 + $frame_sync.sidetone_filter_op.OFFSET_ST_CONFIG_FIELD];
   r0 = r0 AND r2;
   // ST disabled if zero
   M[r8 + $frame_sync.sidetone_filter_op.APPLY_GAIN_FIELD] = r0;
   if Z rts;
   // Unity Gain
   r0 = 0x7FFFFF;
   M[r8 + $frame_sync.sidetone_filter_op.APPLY_GAIN_FIELD] = r0;
   
   // Parameter Pointer
   r7 = M[r8 + $frame_sync.sidetone_filter_op.PARAM_PTR_FIELD]; 

   r0 = Null;
   // Check number of stages.  If zero then bypass filter
   NULL = M[r7 + ($frame_sync.sidetone_filter_op.PEQ_START_FIELD + $audio_proc.peq.NUM_STAGES_FIELD)];
   if Z jump exit_filter_update;
   
   // if switch==0, bypass filter
   // if switch==1, apply filter
   r0 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_SWITCH];
   NULL = r0 AND 0xFFFFFE;
   if Z jump exit_filter_update;
   // SP.  r0 is non-zero here

   // get noise level
   r2 = M[r8 + $frame_sync.sidetone_filter_op.NOISE_LEVEL_PTR_FIELD];
   r2 = M[r2];

   // if noise level is above high threshold, apply PEQ filter
   r3 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_NOISE_HIGH_THRES];
   Null = r2 - r3;
   if GT jump exit_filter_update;

   // if noise level is below low threshold, bypass filter
   r0 = 0;
   r3 = M[r7 + $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_NOISE_LOW_THRES];
   Null = r2 - r3;
   if POS rts;
  

   exit_filter_update:
   M[r8 + $frame_sync.sidetone_filter_op.APPLY_FILTER] = r0;
   rts;
      
$frame_sync.sidestone_filter_op.InitializeFilter:
   // initialize sidetone PEQ filter
   r7 = r7 + $frame_sync.sidetone_filter_op.PEQ_START_FIELD;
   jump $audio_proc.peq.initialize;

   
.ENDMODULE;

