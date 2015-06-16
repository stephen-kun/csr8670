// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************


#ifndef CBOPS_DC_REMOVE_HEADER_INCLUDED
#define CBOPS_DC_REMOVE_HEADER_INCLUDED

   .CONST   $cbops.dc_remove.INPUT_START_INDEX_FIELD                0;
   .CONST   $cbops.dc_remove.OUTPUT_START_INDEX_FIELD               1;
   .CONST   $cbops.dc_remove.DC_ESTIMATE_FIELD                      2;
   .CONST   $cbops.dc_remove.STRUC_SIZE                             3;

   // with fs=48KHz. Value of 0.0005 gives a 3dB point at 4Hz. (0.1dB @ 25Hz)
   // this is assumed to be acceptable for all sample rates
   // value of 0.0003 gives better than 0.1dB at 20Hz which is required by
   // some applications
   .CONST   $cbops.dc_remove.FILTER_COEF                            0.0003;

#endif // CBOPS_DC_REMOVE_HEADER_INCLUDED
