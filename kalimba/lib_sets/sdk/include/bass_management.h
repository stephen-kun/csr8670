//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio Ltd 2012             http://www.csr.com
// Part of ADK 3.5
//
// $Revision: #1 $
//------------------------------------------------------------------------------



#ifndef BASS_MANAGEMENT_HEADER_INCLUDED
#define BASS_MANAGEMENT_HEADER_INCLUDED

    // structure definition

    .const   $bass_management.LEFT_INPUT_PTR            0;
    .const   $bass_management.RIGHT_INPUT_PTR           1;
    .const   $bass_management.LEFT_OUTPUT_PTR           2;
    .const   $bass_management.RIGHT_OUTPUT_PTR          3;
    .const   $bass_management.LFE_INPUT_PTR             4; 
    .const   $bass_management.SUB_OUTPUT_PTR            5;
    .const   $bass_management.BASS_BUFFER_PTR           6; 
    .const   $bass_management.COEFS_PTR                 7; 
    .const   $bass_management.DATA_MEM_PTR              8; 
    .const   $bass_management.BYPASS_WORD_PTR           9; 
    .const   $bass_management.BYPASS_BIT_MASK_FIELD    10; 
    .const   $bass_management.CODEC_RATE_PTR           11; 
    .const   $bass_management.STRUCT_SIZE              12; 


    // coefficients
    
    .const   $bass_management.COEF_CONFIG               0;
    .const   $bass_management.COEF_A1                   1;
    .const   $bass_management.COEF_A2                   2;
    .const   $bass_management.COEF_A3                   3;
    .const   $bass_management.COEF_A4                   4;
    .const   $bass_management.COEF_A5                   5;
    .const   $bass_management.COEF_FREQ_PARAM           6;
    .const   $bass_management.COEF_FREQ                 7;
    
    .const   $bass_management.COEF_NUM_HF_STAGES        8;
    .const   $bass_management.COEF_NUM_LF_STAGES        9;

    .const   $bass_management.COEF_STRUCT_BASE_SIZE    10;
    
    .const   $bass_management.COEF_CONFIG.ENABLE_HPF   0x000001;
    .const   $bass_management.COEF_CONFIG.ENABLE_LPF   0x000002;

#endif // BASS_MANAGEMENT_HEADER_INCLUDED
