// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

#ifndef DTMF_HEADER_INCLUDED
#define DTMF_HEADER_INCLUDED

   .CONST    $dtmf.NUM_KEYS                                 16;

   .CONST    $dtmf.STACK_SIZE                               40;

   .CONST    $dtmf.VOL_FIELD                                0;
   .CONST    $dtmf.TONE_IN_CBUFFER_STRUC_FIELD              1;
   .CONST    $dtmf.PARAMETERS_FIELD                         2;
   .CONST    $dtmf.TONE_TIMER_STRUC_FIELD                   3;
   .CONST    $dtmf.TONES_LEFT_TO_GENERATE_FIELD             4;
   .CONST    $dtmf.SILENCE_LEFT_TO_GENERATE_FIELD           5;
   .CONST    $dtmf.CURRENT_PHASE_FREQ_1_FIELD               6;
   .CONST    $dtmf.CURRENT_PHASE_FREQ_2_FIELD               7;
   .CONST    $dtmf.STACK_READ_POINTER_FIELD                 8;
   .CONST    $dtmf.STACK_WRITE_POINTER_FIELD                9;
   .CONST    $dtmf.STACK_START_OFFSET                       10;
   .CONST    $dtmf.STACK_END_OFFSET                         $dtmf.STACK_START_OFFSET + $dtmf.STACK_SIZE - 1;
   .CONST    $dtmf.STRUC_SIZE                               $dtmf.STACK_END_OFFSET + 1;

   .CONST    $dtmf.parameters.PHASE_STEP_PER_HZ_FIELD       0;
   .CONST    $dtmf.parameters.SAMPLES_PER_MS_FIELD          1;
   .CONST    $dtmf.parameters.TONE_DURATION_FIELD           2;
   .CONST    $dtmf.parameters.SILENCE_DURATION_FIELD        3;
   .CONST    $dtmf.parameters.TIMER_PERIOD_FIELD            4;
   .CONST    $dtmf.parameters.STRUC_SIZE                    5;

#endif

