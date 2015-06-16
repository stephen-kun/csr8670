// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Stereo IIR downsample operator
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
//    ******* WARNING *********  
//    When using these modules in a frame only integer conversion ratios are supported.
//    Furthermore, the input/output frame sizes must be divisible by the conversion ratio.
//
// When using the operator the following data structure is used:
//
//   $cbops.frame.resample.CONVERSION_OBJECT_PTR_FIELD  = Pointer to configuration 
//       object defining the supported sample rate conversions.  These objects are 
//       constants in defined iir_resample_coefs.asm:
//            $M.cbops.iir_resample.8_to_16.filter
//            $M.cbops.iir_resample.8_to_32.filter
//            $M.cbops.iir_resample.8_to_48.filter
//            $M.cbops.iir_resample.16_to_8.filter
//            $M.cbops.iir_resample.16_to_32.filter
//            $M.cbops.iir_resample.16_to_48.filter
//            $M.cbops.iir_resample.22_05_to_44_1.filter
//            $M.cbops.iir_resample.32_to_8.filter
//            $M.cbops.iir_resample.32_to_16.filter
//            $M.cbops.iir_resample.44_1_to_22_05.filter
//   $cbops.frame.resample.INPUT_PTR_FIELD = Pointer to input circular buffer
//   $cbops.frame.resample.INPUT_LENGTH_FIELD = Length of input circular buffer
//   $cbops.frame.resample.OUTPUT_PTR_FIELD = Pointer to output circular buffer
//   $cbops.frame.resample.OUTPUT_LENGTH_FIELD = Length of output circular buffer
//   $cbops.frame.resample.NUM_SAMPLES_FIELD = For upsample this is the number of
//        input samples to consume.  For Downsample this is the number of output
//        samples to generate.
//   $cbops.frame.resample.SAMPLE_COUNT_FIELD = Internal parameter
//       tracking the polyphase operation.  Initialize to zero.
//   $cbops.frame.resample.IIR_HISTORY_BUF_PTR_FIELD = Pointer to
//        a circular memory buffer of length $cbops.IIR_RESAMPLE_IIR_BUFFER_SIZE.
//   $cbops.frame.resample.FIR_HISTORY_BUF_PTR_FIELD = Pointer to
//        a circular memory buffer of length $cbops.IIR_DOWNSAMPLE_FIR_BUFFER_SIZE.
// *****************************************************************************
   


// *****************************************************************************
// MODULE:
//    $M.cbops.frame_resample_initialize
//
// DESCRIPTION:
//    Initialize function for IIR downsampler processing module
//
// INPUTS:
//    - r7 = pointer to module structure
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r10, I0, I4
//
// *****************************************************************************
.MODULE $M.cbops.frame_resample_initialize;
   .CODESEGMENT CBOPS_FRAME_RESAMPLE_INITIALIZE_PM;
   
   $cbops.frame_resample_initialize:
   r2 = M[r7 + $cbops.frame.resample.IIR_HISTORY_BUF_PTR_FIELD];
   // Clear IIR buffer
   r10 = 9;
   I0 = r2;
   L0 = r10;
   r0 = Null;
   do lp_clr_iir;
      M[I0,1] = r0;
   lp_clr_iir:
   L0 = NULL;
   rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.cbops.frame_downsample_process
//
// DESCRIPTION:
//    Process function for IIR downsampler processing module
//
// INPUTS:
//    - r7  = pointer to module structure
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************

.MODULE $M.cbops.frame_downsample_process;
   .CODESEGMENT CBOPS_FRAME_DOWNSAMPLE_PROCESS_PM;
   
   $cbops.frame_downsample_process:
   r3 = 8; 
   I2 = r7;
   M0 = 1;
   r1=M[I2,M0];         // CONVERSION_OBJECT_PTR_FIELD
   I3 = r1,             r1=M[I2,M0];         // INPUT_PTR_FIELD
   I0 = r1,             r1=M[I2,M0];         // INPUT_LENGTH_FIELD
   L0 = r1,             r1=M[I2,M0];         // OUTPUT_PTR_FIELD
   I4 = r1,				   r1=M[I2,M0];         // OUTPUT_LENGTH_FIELD
   L4 = r1,             r2=M[I3,M0];         // fir increment
   M1 = r2,             r4=M[I3,M0];         // fir coefficients
   M2 = NULL - M1,      r1=M[I3,M0];		   // Input_Scale 
   r2 = r2 * 10 (int);
   M3 = r2 - M0;                             // (fir increment)*10 -1
   // get FIR scaling factor
   r6 = r1-r3,          r1=M[I3,M0];		 // Output_Scale
   r8 = r1+r3,          r1=M[I3,M0];		 // R_out
   // get the R_out, which is a integer
   r7 = r1,             r1=M[I2,M0];         // NUM_SAMPLES_FIELD
   r10 = r1,            r5=M[I3,M0];		 // frac_ratio 
   I6 = I3+M0;          
   // set up M3 to be used in mirroring fir coefficients
   I3 = r4;
   M3 = M3 + I3;
   M3 = M3 + I3;
   jump $cbops.iir_downsample_common;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.cbops.frame_upsample_process
//
// DESCRIPTION:
//    Process function for IIR upsampler processing module
//
// INPUTS:
//    - r7 = pointer to module structure
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************
.MODULE $M.cbops.frame_upsample_process;
   .CODESEGMENT CBOPS_FRAME_UPSAMPLE_PROCESS_PM;

   $cbops.frame_upsample_process:
   r3 = 8;
   M0 = 1;
   I0 = r7;
   r0=M[I0,M0];         // CONVERSION_OBJECT_PTR_FIELD
   I2 = r0,             r0=M[I0,M0];         // INPUT_PTR_FIELD
   I1 = r0,             r0=M[I0,M0];         // INPUT_LENGTH_FIELD
   L1 = r0,             r0=M[I0,M0];         // OUTPUT_PTR_FIELD
   I5 = r0,             r0=M[I0,M0];         // OUTPUT_LENGTH_FIELD
   L5 = r0,             r2=M[I2,M0];         // fir increment
   M1 = r2,             r4=M[I2,M0];         // fir coefficients
   M2 = NULL - M1,      r0=M[I2,M0];		   // input scale
   r2 = r2 * 7 (int);
   M3 = r2 - M0;                             // (fir increment)*7 -1
   // get FIR scaling factor
   r6  = r0-r3,         r0=M[I0,M0];         // NUM_SAMPLES_FIELD
   r10 = r0,            r1=M[I2,M0];	      // output scale
   // set IIR scaling factor
   r8 = r1+r3; 
   // get the index to FIR coefficient buffer
   // set up M3 to be used in mirroring
   I3 = r4;
   M3 = M3 + I3,       r1=M[I2,M0];         // R_out
   M3 = M3 + I3;
   // get the R_out, which is a integer
   r7 = r1,            r5=M[I2,M0];		    // fractional ratio 
   I6 = I2;                         // Pointer to iir_scale
   jump $cbops.iir_upsample_common;
.ENDMODULE;


