// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    IIR resampler
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
//    MIPs for IIR downsampling is approximatly:          26*output_rate + 15*input_rate
//    MIPs for FIR only downsampling is approximately:    97*output_rate    
//
//    MIPs for IIR upsampling is approximatly:            21*output_rate + 14*input_rate
//    MIPs for FIR only upsampling is approximately:      99*output_rate + input_rate 
//
//            $M.cbops.iir_resample.8_to_16.filter
//            $M.cbops.iir_resample.8_to_22_05.filter
//            $M.cbops.iir_resample.8_to_32.filter
//            $M.cbops.iir_resample.8_to_44_1.filter
//            $M.cbops.iir_resample.8_to_48.filter
//            $M.cbops.iir_resample.16_to_8.filter
//            $M.cbops.iir_resample.16_to_22_05.filter
//            $M.cbops.iir_resample.16_to_32.filter
//            $M.cbops.iir_resample.16_to_44_1.filter
//            $M.cbops.iir_resample.16_to_48.filter
//            $M.cbops.iir_resample.22_05_to_8.filter
//            $M.cbops.iir_resample.22_05_to_16.filter
//            $M.cbops.iir_resample.22_05_to_32.filter
//            $M.cbops.iir_resample.22_05_to_44_1.filter
//            $M.cbops.iir_resample.22_05_to_48.filter
//            $M.cbops.iir_resample.32_to_8.filter
//            $M.cbops.iir_resample.32_to_16.filter
//            $M.cbops.iir_resample.32_to_22_05.filter
//            $M.cbops.iir_resample.32_to_44_1.filter
//            $M.cbops.iir_resample.32_to_48.filter
//            $M.cbops.iir_resample.44_1_to_8.filter
//            $M.cbops.iir_resample.44_1_to_16.filter
//            $M.cbops.iir_resample.44_1_to_22_05.filter
//            $M.cbops.iir_resample.44_1_to_32.filter
//            $M.cbops.iir_resample.44_1_to_48.filter
// *****************************************************************************
#include "stack.h"
#include "cbops.h"
#include "operators/iir_resample/iir_resample_header.h"


// *************************************************************************************************
// MODULE:
//    $M.cbops.iir_downsample_common
//
// DESCRIPTION:
//    Common processing code for IIR downsampling
//
// INPUTS:
//    - I0,L0  = Input buffer
//    - I2     = pointer to the "SAMPLE_COUNT_FIELD" field of the data object
//    - I3     = base address for fir filter coefficients
//    - I4,L4  = Output Buffer
//    - I6     = pointer to "int_ratio" field of the "filter" configuration object
//    - M0     = 1
//    - M1     = fir filter coefficient increment
//    - M2     = -M1
//    - M3     = fir filter coefficient reflection factor (Filter is symetrical, only half the coffiencts are stored)
//    - r5     = "frac_ratio" field from "filter" configuration object
//    - r6     = power of 2 scaling applied to input
//    - r7     = "R_out" field from "filter" configuration object
//    - r8     = power of 2 scaling applied to output
//    - R10    = Number of output samples to generate
//
// OUTPUTS:
//    - r4     = number of input samples consumed
//
// TRASHED REGISTERS:
//     everything
// *****************************************************************************************************
.MODULE $M.cbops.iir_downsample_common;
   .CODESEGMENT CBOPS_IIR_DOWNSAMPLE_COMMON_PM;

   $cbops.iir_downsample_common:

   push I2;
   L5 = 9;
   r4 = r4 XOR r4, r3 = M[I2,M0];         // SAMPLE_COUNT_FIELD, int_ratio
   L1 = L5 + M0, r1 = M[I2,M0];           // IIR_HISTORY_BUF_PTR_FIELD
   // get IIR History Buffer
   I5 = r1, r1 = M[I2,M0];                // FIR_HISTORY_BUF_PTR_FIELD
   // Set FIR History Buffer
   I1 = r1;

   // *** start of main loop
   // loop all the available samples in the buffer

   do loop;
      // input sample counter
      // r3 = 0,1,2,,,(R_out-1),0,1,,,(repeats),,,
      Null = r3 - r7;
      if GE r3 = r3 - r3;
   
      // mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int);
      if POS jump jp_not_neg;
           r2 = r2 + 1.0;
      jp_not_neg:

      // int[ Rb * 20]
      // NOTE: unwanted rounding is applied in this instruction
      rMAC = r2 * 112;
      r1 = rMAC1;
      I7 = I3 + r1;

      // move the input sample
      // also determine whether move a further input sample ###
      r0 = M[I6,M0];                      // int_ratio  
      Null = r5 - r2;
      if GT r0 = r0 + M0;
      r4 = r4 + r0;
       
      // r0,r3,r5,r6,r7,r8 ,M0,M1,M2,M3 ,I0,I1,I4,I6,I7    ,L1,L5
      // r1,r2,rMAC,I2,r4

      read_input:
      I2 = I6 + M0, r2 = M[I0,M0];                             // Get Input
      r2 = r2 ASHIFT r6, r1 = M[I2,M0];                        // Coefficient x(n)
      rMAC = r2 * r1, r1 = M[I2,1], r2 = M[I5,1];              // Coefficients and History y(n-9)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-8)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-7)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-6)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-5)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-4)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-3)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-2)
      rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I5,1];       // Coefficients and History y(n-1)
      rMAC = rMAC - r2 * r1, r2 = M[I6,0], r1 = M[I1,-1];      // IIR Scale, back up FIR history
      r1 = rMAC ASHIFT r2;                                     // Scale IIR output
      r0 = r0 - M0, M[I1,0] = r1, M[I5,1] =r1;                 // IIR history y(n),  FIR history x(n)
      if NZ jump read_input;
  
      r3 = r3 + M0, r1 = M[I7,M1], r2 = M[I1,M0];
      // Coef 1
      rMAC = r1 * r2, r1 = M[I7,M1], r2 = M[I1,M0];
      // Coef 2
      rMAC = rMAC + r1 * r2, r1 = M[I7,M1], r2 = M[I1,M0];
      // Coef 3
      rMAC = rMAC + r1 * r2, r1 = M[I7,M1], r2 = M[I1,M0];
      // Coef 4          
      rMAC = rMAC + r1 * r2, r1 = M[I7,M1], r2 = M[I1,M0];
      // Coef 5          
      // invert the M reg to perform coef mirroring
      I7 = M3 - I7;
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I1,M0];
      // Coef 6
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I1,M0];
      // Coef 7
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I1,M0];
      // Coef 8
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I1,M0];
      // Coef 9
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I1,M0];
      // Coef 10
      rMAC = rMAC + r1 * r2;
      r1 = rMAC ASHIFT r8;
      //write the result, Reset I6 to point to int_ratio
      I6 = I6 - M0, M[I4,M0] = r1;
   loop:

   pop I2;

   // save sample count and history buffers
   r1 = I5;
   r2 = I1;
   L4 = 0, M[I2,M0] = r3;   // SAMPLE_COUNT_FIELD
   L5 = 0, M[I2,M0] = r1;   // IIR_HISTORY_BUF_PTR_FIELD   
   L1 = 0, M[I2,M0] = r2;   // FIR_HISTORY_BUF_PTR_FIELD  
   L0 = 0;
   rts;

.ENDMODULE;


// *************************************************************************************************
// MODULE:
//    $M.cbops.iir_upsample_common
//
// DESCRIPTION:
//    Common processing code for IIR upsampling
//
// INPUTS:
//    - I1,L1  = Input buffer
//    - I3     = base address for fir filter coefficients
//    - I5,L5  = Output Buffer
//    - I0     = pointer to the "SAMPLE_COUNT_FIELD" field of the data object
//    - I6     = pointer to iir_scale field of the "filter" configuration object
//    - M0     = 1
//    - M1     = fir filter coefficient increment
//    - M2     = -M1
//    - M3     = fir filter coefficient reflection factor (Filter is symetrical, only half the coffiencts are stored)
//    - r5     = "frac_ratio" field from "filter" configuration object
//    - r6     = power of 2 scaling applied to input
//    - r7     = "R_out" field from "filter" configuration object
//    - r8     = power of 2 scaling applied to output
//    - R10    = Number of input samples consumed
//
// OUTPUTS:
//    - r4     = number of output samples generated
//
// TRASHED REGISTERS:
//     everything
// *****************************************************************************************************
.MODULE $M.cbops.iir_upsample_common;
   .CODESEGMENT CBOPS_IIR_UPSAMPLE_COMMON_PM;
   
   $cbops.iir_upsample_common:

   push I0;

   r4 = Null, r3 = M[I0,M0];                 // SAMPLE_COUNT_FIELD
   r0 = M1, r1 = M[I0,M0];                   // IIR_HISTORY_BUF_PTR_FIELD
   // get IIR History Buffer
   I4 = r1, r1 = M[I0,M0];                   // FIR_HISTORY_BUF_PTR_FIELD
   // Set FIR History Buffer
   I0 = r1;

   L4 = 9;
   L0 = 7;
   // Note: Put loop in function
   do loop;
      // input sample counter
      // r3 = 0,1,2,,,(R_out-1),0,1,,,(repeats),,,
      Null = r3 - r7;
      if GE r3 = r3 - r3;

      // rb = mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int);
      if POS jump jp_not_neg;
          r2 = r2 + 1.0;
      jp_not_neg:

      // stop the loop counter when input sample not incremented
      Null = r5 - r2;
      if LE r10 = r10 + M0;

      // int[ Rb * 160] // no rounding
      rMAC = r2 * r0;
      r1 = rMAC1;
      I7 = I3 + r1;

      // determine whether move onto next input sample
      Null = r5 - r2;
      if LE jump not_move_ip_fw;
         // IIR
         I2 = I6 + M0, r2 = M[I1,M0];                          // Input, Coefficient Ptr
         r2 = r2 ASHIFT r6, r1 = M[I2,1];                      // Shift Input. Input Coefficient
         rMAC = r2 * r1, r1 = M[I2,1], r2 = M[I4,1];           // Coefficients and History y(n-9)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-8)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-7)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-6)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-5)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-4)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-3)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-2)
         rMAC = rMAC - r2 * r1, r1 = M[I2,1], r2 = M[I4,1];    // Coefficients and History y(n-1)
         rMAC = rMAC - r2 * r1, r2 = M[I0,-1], r1 = M[I6,0];   // dummy read to back up fir history
         r2 = rMAC ASHIFT r1;
         M[I0,0] = r2, M[I4,1] =r2;                            // History y(n), FIR History
      not_move_ip_fw:
   
      r3 = r3 + M0, r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 1
      rMAC = r1 * r2, r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 2
      rMAC = rMAC + r1 * r2, r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 3
      rMAC = rMAC + r1 * r2, r1 = M[I7,M1], r2 = M[I0,M0];
      // invert the M reg to perform coef mirroring
      I7 = M3 - I7;
      // Coef 4
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 5
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 6
      rMAC = rMAC + r1 * r2, r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 7
      rMAC = rMAC + r1 * r2;

      r1 = rMAC ASHIFT r8;
      //increment counter write the result
      r4 = r4 + M0, M[I5,M0] = r1;

   loop:
   // end of loop available samples in the buffer
   pop I2;

   // save sample count and history buffers
   r1 = I4;
   r2 = I0;
   L4 = 0, M[I2,M0] = r3;   // SAMPLE_COUNT_FIELD
   L5 = 0, M[I2,M0] = r1;   // IIR_HISTORY_BUF_PTR_FIELD   
   L1 = 0, M[I2,M0] = r2;   // FIR_HISTORY_BUF_PTR_FIELD  
   L0 = 0;
   
   rts;
   
.ENDMODULE;





