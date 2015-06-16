// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef AUDIO_PEQ_HEADER_INCLUDED
#define AUDIO_PEQ_HEADER_INCLUDED

#include "cbuffer.h"

// PEQ Parameters

   // PEQ config word: metadata(upper bits) + number of stages (LSBs)
   // Number of stage at lower LSBs should be masked out before any use
   // Use $audio_proc.peq.const.NUM_STAGES_MASK for masking

    .CONST $audio_proc.peq.parameter.NUM_STAGES_FIELD               0;
    .CONST $audio_proc.peq.parameter.GAIN_EXPONENT_FIELD            1;
    .CONST $audio_proc.peq.parameter.GAIN_MANTISA__FIELD            2;
    .CONST $audio_proc.peq.parameter.STAGES_SCALES                  3;
    // STAGES = <MAX_STAGES * 5> fields
    // SCALE FACTORS = <MAX_STAGES> fields
    
    
// PEQ Data Structure    
    
   // Pointer to input audio stream
   .CONST $audio_proc.peq.INPUT_ADDR_FIELD               0;
   
   // Pointer to output audio stream
   .CONST $audio_proc.peq.OUTPUT_ADDR_FIELD              1;
   
   // Maximum stages for PEQ
   .CONST $audio_proc.peq.MAX_STAGES_FIELD               2;
   
   .CONST $audio_proc.peq.PARAM_PTR_FIELD                3;  
   
   // Pointer to PEQ delay buffer
   // Minimum size of the buffer: 2 * (number of stages + 1)
   .CONST $audio_proc.peq.DELAYLINE_ADDR_FIELD           4;
   
   // Pointer to PEQ filter coefficients buffer, 
   // Minimum size of the buffer: 5 * (number of stages)
   // The filter coefficients should be arranged in the following order:
   // - stage 1: b2(1), b1(1), b0(1), a2(1), a1(1)
   // - stage 2: b2(2), b1(2), b0(2), a2(2), a1(2)
   // . .......: ....., ....., ....., ....., .....
   // - stage n: b2(n), b1(n), b0(n), a2(n), a1(n)
   .CONST $audio_proc.peq.COEFS_ADDR_FIELD               5;
   
   // PEQ config word: metadata(upper bits) + number of stages (LSBs)
   // Number of stage at lower LSBs should be masked out before any use
   // Use $audio_proc.peq.const.NUM_STAGES_MASK for masking
   .CONST $audio_proc.peq.NUM_STAGES_FIELD               6;

   // Size of delay line circular buffer
   // This field is set by initialization routine based on NUM_STAGES_FIELD
   .CONST $audio_proc.peq.DELAYLINE_SIZE_FIELD           7;
   
   // Size of filter coefficients circular buffer
   // This field is set by initialization routine based on NUM_STAGES_FIELD
   .CONST $audio_proc.peq.COEFS_SIZE_FIELD               8;
    
    // Structure size of PEQ data object
   .CONST $audio_proc.peq.STRUC_SIZE                     9;

  
    //  If using base register append delay buffer to data object  
    #define PEQ_OBJECT_SIZE(x)  ($audio_proc.peq.STRUC_SIZE + 2*((x)+1) )

   // Number of Stage Mask
   .CONST $audio_proc.peq.const.NUM_STAGES_MASK          0xFF;

#endif // AUDIO_PEQ_HEADER_INCLUDED
