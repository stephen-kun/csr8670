// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CBOPS_RESAMPLE_HEADER_INCLUDED
#define CBOPS_RESAMPLE_HEADER_INCLUDED

   .CONST   $cbops.resample.INPUT_1_START_INDEX_FIELD      0;
   .CONST   $cbops.resample.INPUT_2_START_INDEX_FIELD      1;
   .CONST   $cbops.resample.OUTPUT_1_START_INDEX_FIELD     2;
   .CONST   $cbops.resample.OUTPUT_2_START_INDEX_FIELD     3;
   .CONST   $cbops.resample.COEF_BUF_INDEX_FIELD           4;
   .CONST   $cbops.resample.CONVERT_RATIO_INT_FIELD        5;
   .CONST   $cbops.resample.CONVERT_RATIO_FRAC_FIELD       6;
   .CONST   $cbops.resample.INV_CONVERT_RATIO_FIELD        7;
   .CONST   $cbops.resample.RATIO_IN_FIELD                 8;
   .CONST   $cbops.resample.RATIO_OUT_FIELD                9;
   .CONST   $cbops.resample.STRUC_SIZE                     10;

   // resmaple and mix structure, used for tone and voice prompts mixing
   .CONST   $cbops.auto_resample_mix.IO_LEFT_INDEX_FIELD            0;
   .CONST   $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD           1;
   .CONST   $cbops.auto_resample_mix.TONE_CBUFFER_FIELD             2;
   .CONST   $cbops.auto_resample_mix.COEF_BUF_INDEX_FIELD           3;
   .CONST   $cbops.auto_resample_mix.OUTPUT_RATE_ADDR_FIELD         4;
   .CONST   $cbops.auto_resample_mix.HIST_BUF_FIELD                 5;
   .CONST   $cbops.auto_resample_mix.INPUT_RATE_ADDR_FIELD          6;
   .CONST   $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD        7;
   .CONST   $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD       8;
   .CONST   $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD       9;
   .CONST   $cbops.auto_resample_mix.CURRENT_OUTPUT_RATE_FIELD      10;
   .CONST   $cbops.auto_resample_mix.CURRENT_INPUT_RATE_FIELD       11;
   .CONST   $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD        12;
   .CONST   $cbops.auto_resample_mix.IR_RATIO_FIELD                 13;
   .CONST   $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD           14;
   .CONST   $cbops.auto_resample_mix.INPUT_STATE_FIELD              15;
   .CONST   $cbops.auto_resample_mix.INPUT_COUNTER_FIELD            16;
   .CONST   $cbops.auto_resample_mix.OPERATION_MODE_FIELD           17;
   .CONST   $cbops.auto_resample_mix.STRUC_SIZE                     18;

   // defining input state
   .CONST  $cbops.auto_resample_mix.TONE_MIXING_NOTONE_STATE        0;  // no tone is seen in the input buffer
   .CONST  $cbops.auto_resample_mix.TONE_MIXING_NORMAL_STATE        1;  // tone are being seen in the input buffer

   // defining operation actions
   .CONST  $cbops.auto_resample_mix.TONE_MIXING_RESAMPLE_ACTION     0;  // tone is resampled before mixing (fin != fout)
   .CONST  $cbops.auto_resample_mix.TONE_MIXING_IGNORE_ACTION       1;  // tone is ignored (fout < 0.9fin)
   .CONST  $cbops.auto_resample_mix.TONE_MIXING_JUSTMIX_ACTION      2;  // tone is just mixed (fin = fout)

   // tone mixing uses same filter as SRA op uses
   .CONST  $cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH         $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE;
   .CONST  $cbops.auto_resample_mix.TONE_FILTER_UPRATE              $cbops.rate_adjustment_and_shift.SRA_UPRATE;

#endif // CBOPS_RESAMPLE_HEADER_INCLUDED

