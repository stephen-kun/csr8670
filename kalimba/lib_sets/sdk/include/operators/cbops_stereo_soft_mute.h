// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Ltd 2010             http://www.csr.com
// Part of ADK 3.5
//
// $Revision: #1 $  $Date: 2014/04/23 $
// *****************************************************************************


#ifndef CBOPS_STEREO_SOFT_MUTE_HEADER_INCLUDED
#define CBOPS_STEREO_SOFT_MUTE_HEADER_INCLUDED

    // Operator structure definition
   
    .const  $cbops.stereo_soft_mute_op.STRUC_SIZE                         6;

    .const  $cbops.stereo_soft_mute_op.INPUT_LEFT_START_INDEX_FIELD       0;
    .const  $cbops.stereo_soft_mute_op.INPUT_RIGHT_START_INDEX_FIELD      1;
    .const  $cbops.stereo_soft_mute_op.OUTPUT_LEFT_START_INDEX_FIELD      2;
    .const  $cbops.stereo_soft_mute_op.OUTPUT_RIGHT_START_INDEX_FIELD     3;
    .const  $cbops.stereo_soft_mute_op.MUTE_DIRECTION                     4;
    .const  $cbops.stereo_soft_mute_op.MUTE_INDEX                         5;
    
#endif // CBOPS_STEREO_SOFT_MUTE_HEADER_INCLUDED
