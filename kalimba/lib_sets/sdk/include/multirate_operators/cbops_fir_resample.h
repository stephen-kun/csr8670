// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef CBOPS_FIR_RESAMPLE_INCLUDED
#define CBOPS_FIR_RESAMPLE_INCLUDED

   // define fir_resample input structure fields
   .CONST   $cbops.fir_resample.INPUT_INDEX_FIELD            0;   // (input) index of the input buffer
   .CONST   $cbops.fir_resample.OUTPUT_INDEX_FIELD           1;   // (input) index of the output buffer
   .CONST   $cbops.fir_resample.COEF_BUF_INDEX_FIELD         2;   // (input) coefficients
   .CONST   $cbops.fir_resample.INPUT_RATE_ADDR_FIELD        3;   // (input) address holding input rate
   .CONST   $cbops.fir_resample.OUTPUT_RATE_ADDR_FIELD       4;   // (input) address holding output rate
   .CONST   $cbops.fir_resample.HIST_BUF_FIELD               5;   // (input/state) history buffer
   .CONST   $cbops.fir_resample.CURRENT_OUTPUT_RATE_FIELD    6;   // (state) current output rate
   .CONST   $cbops.fir_resample.CURRENT_INPUT_RATE_FIELD     7;   // (state) current input rate
   .CONST   $cbops.fir_resample.CONVERT_RATIO_INT_FIELD      8;   // (state) integer part of input_rate/output_rate
   .CONST   $cbops.fir_resample.CONVERT_RATIO_FRAC_FIELD     9;   // (state) fractinal part of input_rate/output_rate
   .CONST   $cbops.fir_resample.IR_RATIO_FIELD               10;  // (state) current interpolation ratio
   .CONST   $cbops.fir_resample.INT_SAMPLES_LEFT_FIELD       11;  // (state) samples left to read before generating next output
   .CONST   $cbops.fir_resample.RESAMPLE_UNITY_RATIO_FIELD   12;  // (input) if NZ then always resampled even if fin=fo

   .CONST   $cbops.fir_resample.STRUC_SIZE                   13;

   // fir resampler uses same filter structure as does SRA op
   .CONST  $cbops.fir_resample.HIST_LENGTH         ($cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE+1);  // size of history buffer
   .CONST  $cbops.fir_resample.FILTER_LENGTH       $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE;      // length of fir filter
   .CONST  $cbops.fir_resample.FILTER_UPRATE       $cbops.rate_adjustment_and_shift.SRA_UPRATE;           // upsampling rate

#endif // #ifndef CBOPS_FIR_RESAMPLE_INCLUDED

