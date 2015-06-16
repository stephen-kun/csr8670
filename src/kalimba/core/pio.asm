// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2006-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//   PIO library
//
// DESCRIPTION:
//   TODO
//
//   The library uses structures to hold the information it requires for each
// request. Each structure should be of size $pio.STRUC_SIZE and contains the
// following fields:
// @verbatim
//     Name                          Index
//     $pio.NEXT_ADDR_FIELD            0
//     $pio.PIO_BITMASK_FIELD          1
//     $pio.HANDLER_ADDR_FIELD         2
// @endverbatim
//
// *****************************************************************************

#ifndef PIO_INCLUDED
#define PIO_INCLUDED

#include "pio.h"
#include "stack.h"
#include "interrupt.h"

.MODULE $pio;
   .DATASEGMENT DM;

   .VAR last_addr = $pio.LAST_ENTRY;
   .VAR prev_pio_state;
   .VAR saved_r0;
   .VAR saved_r1;

   #ifdef PIO_DEBUG_ON
      .VAR debug_count;
   #endif

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pio.initialise
//
// DESCRIPTION:
//    Initialises the monitoring of PIOs.
//
//  INPUTS:
//    - none
//
//  OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r1, r2, r3
//
// *****************************************************************************
.MODULE $M.pio.initialise;
   .CODESEGMENT PIO_INITIALISE_PM;

   $pio.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // set up handler for pio interrupts (priority 2)
   r0 = $INT_SOURCE_PIO_EVENT;
   r1 = 2;
   r2 = &$pio.event_service_routine;
   #ifdef OPTIONAL_FAST_INTERRUPT_SUPPORT
      call $interrupt.register_fast;
   #else
      call $interrupt.register;
   #endif

   // save previous PIO state for the very first time
   r0 = M[$PIO_IN];
   M[$pio.prev_pio_state] = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pio.register_handler
//
// DESCRIPTION:
//    Registers a PIO event handler.
//
//  INPUTS
//    - r0 = pointer to a structure that stores the pio handler structure,
//           should be of length $pio.STRUC_SIZE
//    - r1 = bitmask of PIOs to monitor
//    - r2 = address of PS key handler for this PS key
//
//  OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-6, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.pio.register_handler;
   .CODESEGMENT PIO_REGISTER_HANDLER_PM;

   $pio.register_handler:

   // set the next address field of this structure to the previous last_addr
   r3 = M[$pio.last_addr];
   M[r0 + $pio.NEXT_ADDR_FIELD] = r3;
   // set new last_addr to the address of this structure
   M[$pio.last_addr] = r0;

   // store new entry's bitmaskand handler address in this structre
   M[r0 + $pio.PIO_BITMASK_FIELD] = r1;
   M[r0 + $pio.HANDLER_ADDR_FIELD] = r2;

   // adjust the PIO event register to detect changes on these PIOs
   r0 = M[$PIO_EVENT_EN_MASK];
   r0 = r0 OR r1;
   M[$PIO_EVENT_EN_MASK] = r0;

   rts;

.ENDMODULE;








// *****************************************************************************
// MODULE:
//    $pio.event_service_routine
//
// DESCRIPTION:
//    Process a PIO interrupt event by calling the appropriate handler functions
// that have been configured to monitor the PIOs that have changed.
//
//  INPUTS:
//    - none
//
//  OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
//
// NOTES:
//    The Handler is passed:
//       - r0 = PIOs that have changed
//       - r1 = address of the PIO handler struc
//
//    In all cases:
//       The handler function is allowed to trash r0, r1, and r2.
//
//    If OPTIONAL_FAST_INTERRUPT_SUPPORT is defined (in interrupt.h):
//       All other registers must be saved and restored if used.
//
//    If OPTIONAL_FAST_INTERRUPT_SUPPORT is NOT defined (in interrupt.h):
//       All other registers can be trashed as required.
//
// *****************************************************************************
.MODULE $M.pio.event_service_routine;
   .CODESEGMENT PIO_EVENT_SERVICE_ROUTINE_PM;

   $pio.event_service_routine:

   // push rLink onto stack
   $push_rLink_macro;

   // detect which PIOs have changed
   r0 = M[$pio.prev_pio_state];
   r1 = M[$PIO_IN];
   M[$pio.prev_pio_state] = r1;
   r0 = r0 XOR r1;

   // ** work out which handler functions to call **
   r1 = M[$pio.last_addr];

   #ifdef PIO_DEBUG_ON
      r2 = $pio.MAX_HANDLERS;
      M[$pio.debug_count] = r2;
   #endif

   find_structure_loop:
      // see if we're at the end of the linked list
      Null = r1 - $pio.LAST_ENTRY;
      if Z jump $pop_rLink_and_rts;

      #ifdef PIO_DEBUG_ON
         // have we been round too many times
         r2 = M[$pio.debug_count];
         r2 = r2 - 1;
         if NEG call $error;
         M[$pio.debug_count] = r2;
      #endif

      r3 = M[r1 + $pio.HANDLER_ADDR_FIELD];
      r2 = M[r1 + $pio.PIO_BITMASK_FIELD];
      M[$pio.saved_r0] = r0;
      M[$pio.saved_r1] = r1;
      Null = r2 AND r0;
      if NZ call r3;
      r0 = M[$pio.saved_r0];
      r1 = M[$pio.saved_r1];

      r1 = M[r1 + $pio.NEXT_ADDR_FIELD];
   jump find_structure_loop;

.ENDMODULE;

#endif
