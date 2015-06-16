// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CBOPS_CROSS_MIX_INCLUDED
#define CBOPS_CROSS_MIX_INCLUDED

    // defining operator structure
   .CONST   $cbops.cross_mix.INPUT1_START_INDEX_FIELD               0;  // index of the input1  buffer
   .CONST   $cbops.cross_mix.INPUT2_START_INDEX_FIELD               1;  // index of the input2  buffer
   .CONST   $cbops.cross_mix.OUTPUT1_START_INDEX_FIELD              2;  // index of the output1 buffer
   .CONST   $cbops.cross_mix.OUTPUT2_START_INDEX_FIELD              3;  // index of the output2 buffer
   .CONST   $cbops.cross_mix.COEFF11_FIELD                          4;  // a11
   .CONST   $cbops.cross_mix.COEFF12_FIELD                          5;  // a12
   .CONST   $cbops.cross_mix.COEFF21_FIELD                          6;  // a21
   .CONST   $cbops.cross_mix.COEFF22_FIELD                          7;  // a22

   .CONST   $cbops.cross_mix.STRUC_SIZE                             8;

#endif // CBOPS_CROSS_MIX_INCLUDED
