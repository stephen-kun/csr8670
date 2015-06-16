// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CBOPS_IIR_RESAMPLE_HEADER_INCLUDED
#define CBOPS_IIR_RESAMPLE_HEADER_INCLUDED

   .CONST   $cbops.mono.iir_resample.INPUT_1_START_INDEX_FIELD              0;
   .CONST   $cbops.mono.iir_resample.OUTPUT_1_START_INDEX_FIELD             1;
   .CONST   $cbops.mono.iir_resample.FILTER_DEFINITION_PTR_FIELD            2;
   .CONST   $cbops.mono.iir_resample.INPUT_SCALE_FIELD                      3;
   .CONST   $cbops.mono.iir_resample.OUTPUT_SCALE_FIELD                     4;
   .CONST   $cbops.mono.iir_resample.SAMPLE_COUNT_FIELD                     5;
   .CONST   $cbops.mono.iir_resample.IIR_HISTORY_BUF_PTR_FIELD              6;
   .CONST   $cbops.mono.iir_resample.FIR_HISTORY_BUF_PTR_FIELD              7;
   .CONST   $cbops.mono.iir_resample.RESET_FLAG_FIELD                       8;
   .CONST   $cbops.mono.iir_resample.STRUC_SIZE                             9;   
   
   .CONST   $cbops.stereo.iir_resample.INPUT_2_START_INDEX_FIELD            0;
   .CONST   $cbops.stereo.iir_resample.OUTPUT_2_START_INDEX_FIELD           1;
   .CONST   $cbops.stereo.iir_resample.INPUT_1_START_INDEX_FIELD            2;
   .CONST   $cbops.stereo.iir_resample.OUTPUT_1_START_INDEX_FIELD           3;
   .CONST   $cbops.stereo.iir_resample.FILTER_DEFINITION_PTR_FIELD          4;
   .CONST   $cbops.stereo.iir_resample.INPUT_SCALE_FIELD                    5;
   .CONST   $cbops.stereo.iir_resample.OUTPUT_SCALE_FIELD                   6;
   .CONST   $cbops.stereo.iir_resample.CH1_SAMPLE_COUNT_FIELD               7;
   .CONST   $cbops.stereo.iir_resample.CH1_IIR_HISTORY_BUF_PTR_FIELD        8;
   .CONST   $cbops.stereo.iir_resample.CH1_FIR_HISTORY_BUF_PTR_FIELD        9;
   .CONST   $cbops.stereo.iir_resample.CH2_SAMPLE_COUNT_FIELD               10;
   .CONST   $cbops.stereo.iir_resample.CH2_IIR_HISTORY_BUF_PTR_FIELD        11;
   .CONST   $cbops.stereo.iir_resample.CH2_FIR_HISTORY_BUF_PTR_FIELD        12;   
   .CONST   $cbops.stereo.iir_resample.RESET_FLAG_FIELD                     13;
   .CONST   $cbops.stereo.iir_resample.STRUC_SIZE                           14;
   
   .CONST   $cbops.iir_resample_complete.STRUC_SIZE                         0;
   
   
   // field definitions for downsample data object in dm1
   .CONST   $cbops.frame.resample.CONVERSION_OBJECT_PTR_FIELD  0;
   .CONST   $cbops.frame.resample.INPUT_PTR_FIELD              1;
   .CONST   $cbops.frame.resample.INPUT_LENGTH_FIELD           2;
   .CONST   $cbops.frame.resample.OUTPUT_PTR_FIELD             3;
   .CONST   $cbops.frame.resample.OUTPUT_LENGTH_FIELD          4;
   .CONST   $cbops.frame.resample.NUM_SAMPLES_FIELD            5;
   .CONST   $cbops.frame.resample.SAMPLE_COUNT_FIELD           6;
   .CONST   $cbops.frame.resample.IIR_HISTORY_BUF_PTR_FIELD    7;
   .CONST   $cbops.frame.resample.FIR_HISTORY_BUF_PTR_FIELD    8;
   .CONST   $cbops.frame.resample.DM1_OBJECT_SIZE_FIELD        9;


   .CONST   $cbops.IIR_RESAMPLE_IIR_BUFFER_SIZE        9;
   .CONST   $cbops.IIR_DOWNSAMPLE_FIR_BUFFER_SIZE      10;
   .CONST   $cbops.IIR_UPSAMPLE_FIR_BUFFER_SIZE        7;


#endif // CBOPS_IIR_RESAMPLE_HEADER_INCLUDED

