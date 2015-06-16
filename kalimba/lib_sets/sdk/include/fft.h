// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef MATH_FFT_HEADER_INCLUDED
#define MATH_FFT_HEADER_INCLUDED

   .CONST   $fft.STRUC_SIZE            3;
   .CONST   $fft.NUM_POINTS_FIELD      0;
   .CONST   $fft.REAL_ADDR_FIELD       1;
   .CONST   $fft.IMAG_ADDR_FIELD       2;

// In this variant, fft twiddle factors are stored externally ...   
   #if defined(FFT_LOW_RAM)
      .CONST $FFT_LOW_RAM_USED       1;
   #endif

#endif
