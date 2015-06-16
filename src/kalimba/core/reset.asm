// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef RESET_INCLUDED
#define RESET_INCLUDED

// *****************************************************************************
// MODULE:
//    $reset.reset
//
// DESCRIPTION:
//    Kalimba DSP reset routine.  This routine calls your $main function upon
// Kalimba starting.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    It must be located in memory at PM address 0.  This is done by the use of
// the codesegment named 'PM_RST' which is first in the link order set by the
// default.asm file
//
// *****************************************************************************
.MODULE $M.reset;
   .CODESEGMENT RESET_PM;

   $reset:
   nop;
   jump $pre_main;

.ENDMODULE;


// This module exists and is in codesegment PM_RAM so that the "jump $main" in $reset above
// is guaranteed to not require a prefix.  Hence allowing PM_ISR to start at location 0x2.
.MODULE $M.pre_main;
   .CODESEGMENT PM_RAM;

   $pre_main:

   // map PM flash bank
   call $flash.init_pm;

   #if defined(BUILD_WITH_C_SUPPORT)
      jump $_crt0;
   #else
      jump $main;
   #endif

.ENDMODULE;

#endif
