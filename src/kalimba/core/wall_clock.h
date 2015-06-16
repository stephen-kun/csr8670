// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef WALL_CLOCK_HEADER_INCLUDED
#define WALL_CLOCK_HEADER_INCLUDED

#include "timer.h"

   .CONST   $wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_VALUE    625;
   .CONST   $wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_SHIFT    -1;

   .CONST   $wall_clock.UPDATE_TIMER_PERIOD          100000;

   // Set the maximum possible number of individual 'wall clocks'
   // - This is only used to detect corruption in the linked list.
   // - It is set to 7 as this is the max number of BT slaves that
   //   can have 'wall clocks'
   .CONST   $wall_clock.MAX_WALL_CLOCKS              7;

   .CONST   $wall_clock.LAST_ENTRY                   -1;

   .CONST   $wall_clock.NEXT_ADDR_FIELD              0;
   .CONST   $wall_clock.BT_ADDR_TYPE_FIELD           1;
   .CONST   $wall_clock.BT_ADDR_WORD0_FIELD          2;
   .CONST   $wall_clock.BT_ADDR_WORD1_FIELD          3;
   .CONST   $wall_clock.BT_ADDR_WORD2_FIELD          4;
   .CONST   $wall_clock.ADJUSTMENT_VALUE_FIELD       5;
   .CONST   $wall_clock.CALLBACK_FIELD               6;
   .CONST   $wall_clock.TIMER_STRUC_FIELD            7;
   .CONST   $wall_clock.STRUC_SIZE                   8 + $timer.STRUC_SIZE;

   .CONST   $wall_clock.BT_TICKS_IN_7500_US          24; // 7.5 ms in 312.5us ticks, according to http://wiki/Kalimba_stream_metadata_format#Metadata_for_SCO_from-air_connections

#ifdef DEBUG_ON
    #ifndef WALL_CLOCK_FAIL_OK
        #define ERROR_ON_WALL_CLOCK_FAIL
    #endif
#endif


 #endif
