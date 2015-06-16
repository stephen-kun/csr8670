// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Revision$  $Date$
// *****************************************************************************

#ifndef ROTARY_ENCODER_HEADER_INCLUDED
#define ROTARY_ENCODER_HEADER_INCLUDED

#include "pio.h"
#include "timer.h"

   // rotary encoder structure fields
   .CONST      $rotary_enc.NEXT_ADDR_FIELD                   0;
   .CONST      $rotary_enc.PIO_ENC_A_FIELD                   1;
   .CONST      $rotary_enc.PIO_ENC_B_FIELD                   2;
   .CONST      $rotary_enc.MSG_RETURN_ID_FIELD               3;
   .CONST      $rotary_enc.MIN_PERIOD_FIELD                  4;
   .CONST      $rotary_enc.MAX_BOUNCE_US_FIELD               5;
   .CONST      $rotary_enc.ROTATION_FIELD                    6;
   .CONST      $rotary_enc.TOTAL_ROTATION_IN_INTERVAL_FIELD  7;
   .CONST      $rotary_enc.SIGNAL_FLAG_FIELD                 8;
   .CONST      $rotary_enc.SEND_FLAG_FIELD                   9;
   .CONST      $rotary_enc.ENCODER_NUMBER_FIELD              10;
   .CONST      $rotary_enc.PIO_STRUC_FIELD                   11;
   .CONST      $rotary_enc.DEBOUCE_TIMER_STRUC_FIELD         (11 + $pio.STRUC_SIZE);
   .CONST      $rotary_enc.MSG_TIMER_STRUC_FIELD             (11 + $pio.STRUC_SIZE + $timer.STRUC_SIZE);
   .CONST      $rotary_enc.STRUC_SIZE                        (11 + $pio.STRUC_SIZE + 2*$timer.STRUC_SIZE);

   // set the maximum possible number of rotary encoders handlers - this is only
   // used to detect corruption in the linked list, and so can be quite large
   .CONST      $rotary_enc.MAX_ROTARY_ENCODERS               10;

   .CONST      $rotary_enc.LAST_ENTRY                       -1;

#endif

