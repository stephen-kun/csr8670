// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef AUDIO_DELAY_HEADER_INCLUDED
#define AUDIO_DELAY_HEADER_INCLUDED

   // Pointer to input audio stream
   .CONST $audio_proc.delay.INPUT_ADDR_FIELD             0;
   // Pointer to output audio stream
   .CONST $audio_proc.delay.OUTPUT_ADDR_FIELD            1;
   // Pointer to delay buffer
   // Allocate to different data bank with input/output stream for lower cycles
   .CONST $audio_proc.delay.DBUFF_ADDR_FIELD             2;
   // Delay length in samples
   .CONST $audio_proc.delay.DELAY_FIELD                  3;
   // Structure size of delay data object
   .CONST $audio_proc.delay.STRUC_SIZE                   4;

#endif // AUDIO_DELAY_HEADER_INCLUDED
