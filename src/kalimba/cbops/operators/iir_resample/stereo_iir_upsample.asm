// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#include "cbops.h"
#include "core_library.h"

// *****************************************************************************
// NAME:
//    Stereo IIR upsample operator
//
// DESCRIPTION:
//    This operator uses an IIR and a FIR filter combination to
//    perform sample rate conversion.  The utilization of the IIR
//    filter allows a lower order FIR filter to be used to obtain
//    an equivalent frequency response.  The result is that the
//    IIR resampler uses less MIPs than the current polyphase FIR method.
//    It also provides a better frequency response.
//
//    The IIR component is a 9th order filter applied at the input sample
//    rate.  The IIR filter coefficients are unique for each conversion ratio.
//
//    The FIR component is implemented in a polyphase configuration.
//    Each phase is a 10 order filter applied at the output sample rate.  The filter
//    is symetrical so only half the coefficients need to be stored. The FIR filter
//    coefficients are the same for all conversion ratios. For all the
//    phases, 640 coefficients are stored.
//
//    The operator utilizes its own history buffers.  As a result the input and/or
//    output may be a port.  Also, for downsampling, in-place operation is supported.
//
//    MIPs for IIR downsamplig is approximatly:             26*output_rate + 15*input_rate
//    MIPs for FIR only downsampling is approximately:      97*output_rate
//
//
//    ***** WARNING *******
//        See $cbops.iir_resample_complete operator for usage
//
// When using the operator the following data structure is used:
//
//   $cbops.stereo.iir_resample.INPUT_2_START_INDEX_FIELD = The index of the input
//       buffer for CH2
//   $cbops.stereo.iir_resample.OUTPUT_2_START_INDEX_FIELD = The index of the output
//       buffer for CH2
//   $cbops.stereo.iir_resample.INPUT_1_START_INDEX_FIELD = The index of the input
//       buffer for CH1
//   $cbops.stereo.iir_resample.OUTPUT_1_START_INDEX_FIELD = The index of the output
//       buffer for CH1
//   $cbops.stereo.iir_resample.FILTER_DEFINITION_PTR_FIELD = Pointer to configuration
//       object defining the supported sample rate conversions.  These objects are
//       constants in defined iir_resample_coefs.asm:
//            $M.cbops.iir_resample.8_to_16.filter
//            $M.cbops.iir_resample.8_to_22_05.filter
//            $M.cbops.iir_resample.8_to_32.filter
//            $M.cbops.iir_resample.8_to_44_1.filter
//            $M.cbops.iir_resample.8_to_48.filter
//            $M.cbops.iir_resample.16_to_22_05.filter
//            $M.cbops.iir_resample.16_to_32.filter
//            $M.cbops.iir_resample.16_to_44_1.filter
//            $M.cbops.iir_resample.16_to_48.filter
//            $M.cbops.iir_resample.22_05_to_32.filter
//            $M.cbops.iir_resample.22_05_to_44_1.filter
//            $M.cbops.iir_resample.22_05_to_48.filter
//            $M.cbops.iir_resample.32_to_44_1.filter
//            $M.cbops.iir_resample.32_to_48.filter
//            $M.cbops.iir_resample.44_1_to_48.filter
//   $cbops.stereo.iir_resample.INPUT_SCALE_FIELD = A power of 2 scale
//       factor applied to the input signal.  The input should be
//       scaled to at Q8.16 resolution (i.e. 16-bit).
//   $cbops.stereo.iir_resample.OUTPUT_SCALE_FIELD = A power of 2 scale
//       factor applied to the output signal.  The signal before scaling
//       will be at Q8.16 resolution
//   $cbops.stereo.iir_resample.CH1_SAMPLE_COUNT_FIELD = Internal parameter
//       tracking the polyphase operation for CH1.  Initialize to zero.
//   $cbops.stereo.iir_resample.CH1_IIR_HISTORY_BUF_PTR_FIELD = Pointer to
//        a circular memory buffer of length $IIR_RESAMPLE_IIR_BUFFER_SIZE for CH1
//   $cbops.stereo.iir_resample.CH1_FIR_HISTORY_BUF_PTR_FIELD = Pointer to
//        a circular memory buffer of length $IIR_DOWNSAMPLE_FIR_BUFFER_SIZE for CH1
//   $cbops.stereo.iir_resample.CH2_SAMPLE_COUNT_FIELD = Internal parameter
//       tracking the polyphase operation for CH2.  Initialize to zero.
//   $cbops.stereo.iir_resample.CH2_IIR_HISTORY_BUF_PTR_FIELD = Pointer to
//        a circular memory buffer of length $IIR_RESAMPLE_IIR_BUFFER_SIZE for CH2
//   $cbops.stereo.iir_resample.CH2_FIR_HISTORY_BUF_PTR_FIELD = Pointer to
//        a circular memory buffer of length $IIR_DOWNSAMPLE_FIR_BUFFER_SIZE for CH2
//   $cbops.stereo.iir_resample.RESET_FLAG_FIELD = Flag indicating that the
//        IIR history buffer should be cleared.  This flag is self resetting
//        and should be initialized to non-zero.
// *****************************************************************************


.MODULE $M.cbops.stereo_iir_upsample;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.stereo_iir_upsample[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,         // reset function
      &$cbops.stereo_iir_upsample.amount_to_use,    // amount to use function
      &$cbops.stereo_iir_upsample.main;             // main function

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbops.stereo_iir_upsample.amount_to_use
//
// DESCRIPTION:
//    operator amount_to_use function for Stereo IIR upsampler
//
// INPUTS:
//    - r5 = amount of input data to use
//    - r6 = minimum available input amount
//    - r7 = minimum available output amount
//    - r8  = pointer to operator structure
//
// OUTPUTS:
//    - r5 = amount of input data to use
//    - r8  = pointer to operator structure
//
// TRASHED REGISTERS:
//    r0,r1,r2,r10,I0,I4
//
// *****************************************************************************
.MODULE $M.cbops.stereo_iir_upsample.amount_to_use;
   .CODESEGMENT CBOPS_STEREO_IIR_UPSAMPLE_AMOUNT_TO_USE_PM;

   $cbops.stereo_iir_upsample.amount_to_use:

   r2 = M[r8 + $cbops.stereo.iir_resample.FILTER_DEFINITION_PTR_FIELD];
   r0 = M[r2 + 5];   // filter.frac_ratio

   // Calculate maximum input for available space
   r1 = r0 * r7 (frac);
   r1 = r1 - 1;
   // prevent the number of samples being negative
   if NEG r1 = Null;

   // Limit input to available data
   r5 = r6;
   Null = r5 - r1;
   if GT r5 = r1;

   // Check Reset flag
   Null = M[r8 + $cbops.stereo.iir_resample.RESET_FLAG_FIELD];
   if Z rts;

   // Clear IIR buffer
   r10 = 9;
   r2 = M[r8 + $cbops.stereo.iir_resample.CH1_IIR_HISTORY_BUF_PTR_FIELD];
   I0 = r2;
   r2 = M[r8 + $cbops.stereo.iir_resample.CH2_IIR_HISTORY_BUF_PTR_FIELD];
   I4 = r2;
   L0 = r10;
   L4 = r10;
   r0 = Null;
   do lp_clr_iir;
      M[I0,1] = r0, M[I4,1]=r0;
   lp_clr_iir:

   L0 = Null;
   L4 = Null;
   // Sync phase count for channels
   M[r8 + $cbops.stereo.iir_resample.CH1_SAMPLE_COUNT_FIELD] = Null;
   M[r8 + $cbops.stereo.iir_resample.CH2_SAMPLE_COUNT_FIELD] = Null;

   // Clear reset flag
   M[r8 + $cbops.stereo.iir_resample.RESET_FLAG_FIELD] = Null;
   rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.stereo_iir_upsample.main
//
// DESCRIPTION:
//    operator main function for Stereo IIR upsampler
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
.MODULE $M.cbops.stereo_iir_upsample.main;
   .CODESEGMENT CBOPS_STEREO_IIR_UPSAMPLE_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.stereo_iir_upsample.main:

   $push_rLink_macro;

   // Temp variable
  .VAR save;
  .VAR samples_to_process;

   M[save] = r8;
   M[samples_to_process]=r10;
   I0 = r8;
   M0 = 1;

   // Save Channel 2 buffer information
   r1 = M[I0,M0];                   // INPUT_2_START_INDEX_FIELD
   r2 = M[I0,M0];                   // OUTPUT_2_START_INDEX_FIELD
   r0 = M[r6 + r1];                 // get the input buffer read address CH2
   push r0;
   r0 = M[r7 + r1];                 // get the input buffer length CH2
   push r0;
   r0 = M[r6 + r2];                 // get the output buffer write address CH2
   push r0;
   r0 = M[r7 + r2];                 // get the output buffer length CH2
   push r0;
   

   r0=M[I0,M0];         // INPUT_1_START_INDEX_FIELD
   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I1
   // an increment will be added later then assign the sum to I4
   I1 = r1,               r4=M[I0,M0];         // OUTPUT_1_START_INDEX_FIELD
   // get the input buffer length
   r1 = M[r7 + r0];  
   // store the value in L1
   L1 = r1,				  r3=M[I0,M0];         // FILTER_DEFINITION_PTR_FIELD 
   I2 = r3,				  r3=M[I0,M0];			  // INPUT_SCALE_FIELD
   // get the output buffer write address
   r1 = M[r6 + r4];
   // store the value in I0
   I5 = r1,				  r0=M[I2,M0];          // fir increment
   M1 = r0,            r5=M[I2,M0];          // fir coefficients
   M2 = NULL - M1,     r1=M[I2,M0];			   // input scale
   r0 = r0 * 7 (int);
   M3 = r0 - M0;                             // (fir increment)*7 - 1
	// get FIR scaling factor
   r6 = r1 + r3,		  r2=M[I0,M0];			  // OUTPUT_SCALE_FIELD
   // get the output buffer length
   r1 = M[r7 + r4];
   // store the value in L0
   L5 = r1,               r1=M[I2,M0];			  // output scale
   // get input scale and sample counter
   r8 = r2+r1;  
   // get the index to FIR coefficient buffer
   // set up M3 to be used in mirroring
   I3 = r5;
   M3 = M3 + I3,        r0=M[I2,M0];              // R_out
   M3 = M3 + I3;
   // get the R_out, which is a integer
   r7 = r0,             r5=M[I2,M0];		      // fractional ratio
   // get IIR history Buffer
   I6 = I2;			
  
   // r10 = number of input samples to process
   call $cbops.iir_upsample_common;

   // for stereo set R10, I1/L1 I5/L5 & I0 for second channel
   r0 = M[save];
   I0 = r0 + $cbops.stereo.iir_resample.CH2_SAMPLE_COUNT_FIELD;

   // Retrieve Channel 2 buffer information
   pop L5;
   pop I5;
   pop L1;
   pop I1;

   r10 = M[samples_to_process];
   // r10 = number of input samples to process
   M[$M.cbops.iir_resample_complete.amount_to_use] = r10;
   call $cbops.iir_upsample_common;
   // r4 = number of output samples generated
   M[$cbops.amount_written] = r4;

   r8 = M[save];

   // Check if last operator in chain
   r0 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];
   Null = r0 - $cbops.NO_MORE_OPERATORS;
   if Z jump $pop_rLink_and_rts;

   // If not Last operator in chain then set $cbops.amount_to_use to amount of output generated
   M[$cbops.amount_to_use] = r4;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;









