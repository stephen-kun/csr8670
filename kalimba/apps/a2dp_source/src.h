// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Ltd %%copyright(2005)             http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************
#ifndef SRC_HEADER
#define SRC_HEADER

    .CONST  $src.SRC_MAX_FILTER_LEN     64; // maximum value for FIR filter length
    .CONST  $src.SRC_MAX_UPSAMPLE_RATE  20; // maximum value for up sample rate when fractinal downsampling

   .CONST   $src.upsample_downsample.INPUT_1_CBUFFER_FIELD            0; // cbuffer containing left input
   .CONST   $src.upsample_downsample.INPUT_2_CBUFFER_FIELD            1; // cbuffer containing righ input (if mono set to zero)
   .CONST   $src.upsample_downsample.OUTPUT_1_CBUFFER_FIELD           2; // cbuffer containing left output
   .CONST   $src.upsample_downsample.OUTPUT_2_CBUFFER_FIELD           3; // buffer containing righ output (if mono set to zero)
   .CONST   $src.upsample_downsample.FILTER_COEFFS_FIELD	          4; // buffer address contatining anti aliasing filter coeffs
   .CONST   $src.upsample_downsample.HIST1_BUF_FIELD                  5; // history cirular buffer for left channlel, size must be  $src.upsample_downsample.COEFFSIZE_FIELD
   .CONST   $src.upsample_downsample.HIST2_BUF_FIELD                  6; // history cirular buffer for right channlel (set zero if mono)
   .CONST   $src.upsample_downsample.COEFFSIZE_FIELD                  7; // lenght of antialiasing filter
   .CONST   $src.upsample_downsample.DECIMATION_RATE_FIELD            8; // decimation factor (M)
   // for fractional
   .CONST   $src.upsample_downsample.ROUT_FIELD                       8; // for fractional it is FO/gcd(FI, FO)
   
   .CONST   $src.upsample_downsample.UPSAMPLE_RATE_FIELD              9; // upsampling rate (L)
   .CONST   $src.upsample_downsample.INV_RATIO_INT_FIELD              10;// int(M/L) 
   .CONST   $src.upsample_downsample.INV_RATIO_FRAC_FIELD             11;// frac(M/L)
   .CONST   $src.upsample_downsample.INV_DOWN_RATIO_FIELD             12;// 1.0/M.0
   .CONST   $src.upsample_downsample.INV_DOWN_RATIO_INT_FIELD         13;// 1.0/M.0
   
    // internal states for fractional 
   .CONST   $src.upsample_downsample.OUT_COUNTER                      14;//better to initialized to ROUT_FIELD, however 0 is okay
   .CONST   $src.upsample_downsample.RF                               15;//init to 0
   
   .CONST   $src.upsample_downsample.STRUC_SIZE                       16;
   
   // to reduce the overhead 
   .CONST   $src.MINIMUM_OUTPUT_SAMPLES 48;         
   .CONST   $src.MINIMUM_INPUT_SAMPLES  48;
   
#endif
