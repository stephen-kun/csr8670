// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef PIO_HEADER_INCLUDED
#define PIO_HEADER_INCLUDED

   #ifdef DEBUG_ON
      #define PIO_DEBUG_ON
   #endif

   // pio event handler structure fields
   .CONST   $pio.NEXT_ADDR_FIELD            0;
   .CONST   $pio.PIO_BITMASK_FIELD          1;
   .CONST   $pio.HANDLER_ADDR_FIELD         2;
   .CONST   $pio.STRUC_SIZE                 3;

   // set the maximum possible number of handlers - this is only used to detect
   // corruption in the linked list, and so can be quite large
   .CONST   $pio.MAX_HANDLERS               20;

   .CONST   $pio.LAST_ENTRY                 -1;

#endif

