// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Wall clock Library
//
// DESCRIPTION:
//    Provides a function to be able to view a time (in us) of a 'wall clock'
//    that is synchronised between 2 BT devices.
//
// *****************************************************************************

#ifndef WALL_CLOCK_INCLUDED
#define WALL_CLOCK_INCLUDED

#ifdef DEBUG_ON
#endif

#include "wall_clock.h"
#include "stack.h"
#include "profiler.h"
#include "message.h"

.MODULE $wall_clock;
   .DATASEGMENT DM;

   .VAR last_addr = $wall_clock.LAST_ENTRY;
   .VAR message_struc[$message.STRUC_SIZE];
   .VAR message_failed_struc[$message.STRUC_SIZE];

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.initialise
//
// DESCRIPTION:
//    Initialise the wall clock library.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3
//
// NOTES:
//    Should be called after $message.initialise since it sets up a message
// handler for the firmware 'wall clock' message.
//
// *****************************************************************************
.MODULE $M.wall_clock.initialise;
   .CODESEGMENT WALL_CLOCK_INITIALISE_PM;

   $wall_clock.initialise:

   // push rLink onto stack
   $push_rLink_macro;

#ifndef OLD_BT_ADDRESS
   // set up message hander for $LONG_MESSAGE_WALL_CLOCK_RESPONSE message
   r1 = &$wall_clock.message_struc;
   r2 = Null OR $LONG_MESSAGE_WALL_CLOCK_RESPONSE_TBTA;
   r3 = &$wall_clock.message_handler;
   call $message.register_handler;

   // set up message hander for $MESSAGE_WALL_CLOCK_FAILED message
   r1 = &$wall_clock.message_failed_struc;
   r2 = Null OR $MESSAGE_WALL_CLOCK_FAILED_TBTA;
   r3 = &$wall_clock.message_handler_failed;
   call $message.register_handler;
#else
   // set up message hander for $LONG_MESSAGE_WALL_CLOCK_RESPONSE message
   r1 = &$wall_clock.message_struc;
   r2 = Null OR $LONG_MESSAGE_WALL_CLOCK_RESPONSE;
   r3 = &$wall_clock.message_handler;
   call $message.register_handler;

   // set up message hander for $MESSAGE_WALL_CLOCK_FAILED message
   r1 = &$wall_clock.message_failed_struc;
   r2 = Null OR $MESSAGE_WALL_CLOCK_FAILED;
   r3 = &$wall_clock.message_handler_failed;
   call $message.register_handler;

#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.enable
//
// DESCRIPTION:
//    Enables the 'wall clock' on a particular BT link.
//
// INPUTS:
//    - r1 = pointer to a variable that stores the 'wall clock' structure,
//           should be of length $wall_clock.STRUC_SIZE
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-5, r10, DoLoop
//
// NOTES:
//    This must be called before a call to $wall_clock.get_time.  The structure
// should be filled out with the BT address prior to the call:
//
//     M[r1 + $wall_clock.BT_ADDR_WORD0_FIELD] = 16bit NAP address
//     M[r1 + $wall_clock.BT_ADDR_WORD1_FIELD] = UAP in MS byte,
//                                               MS byte of LAP in LS byte
//     M[r1 + $wall_clock.BT_ADDR_WORD2_FIELD] = LS 16bits of LAP address
//
// *****************************************************************************
.MODULE $M.wall_clock.enable;
   .CODESEGMENT WALL_CLOCK_ENABLE_PM;

   $wall_clock.enable:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // set the next address field of this structure to the previous last_addr
   r0 = M[$wall_clock.last_addr];
   M[r1 + $wall_clock.NEXT_ADDR_FIELD] = r0;
   // set new last_addr to the address of this structure
   M[$wall_clock.last_addr] = r1;

   // fire timer to obtain the clock immediately
   r1 = r1 + $wall_clock.TIMER_STRUC_FIELD;
   r2 = 0;
   r3 = &$wall_clock.timer_handler;
   call $timer.schedule_event_in;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.disable
//
// DESCRIPTION:
//    Disables the 'wall clock' on a particular BT link.
//
// INPUTS:
//    - r1 = pointer to a variable that stores the 'wall clock' structure,
//           should be of length $wall_clock.STRUC_SIZE
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-5, r10, DoLoop
//
// NOTES:
//    This should be called once the 'wall clock' is not needed anymore on a
// particular link
//
// *****************************************************************************
.MODULE $M.wall_clock.disable;
   .CODESEGMENT WALL_CLOCK_DISABLE_PM;

   $wall_clock.disable:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // search through the 'wall clock' linked list to find the struc to cancel
   r10 = $wall_clock.MAX_WALL_CLOCKS;
   r0 = &$wall_clock.last_addr;
   r2 = M[$wall_clock.last_addr];
   do loop;
      // if we're at the last structure in the linked list then the struc
      // hasn't been found
      Null = r2 - $wall_clock.LAST_ENTRY;
      if Z jump not_found;

      // if the addresses match then delete entry from linked list
      Null = r2 - r1;
      if Z jump delete_this_entry;

      // set r0 = address of this struc
      r0 = r2;
      // read the address of the next 'wall clock' structure
      r2 = M[r2 + $wall_clock.NEXT_ADDR_FIELD];
   loop:

   not_found:
   // If it wasn't found, lets assume it was already disabled hence we just
   // continue
   jump entry_removed;

   delete_this_entry:
      // delete the 'wall clock' structure from the linked list
      // previous structure -> this structure's next addr field
      r2 = M[r1 + $wall_clock.NEXT_ADDR_FIELD];
      M[r0 + $wall_clock.NEXT_ADDR_FIELD] = r2;

   entry_removed:

   // cancel the timer for this 'wall clock'
   r2 = M[r1 + ($wall_clock.TIMER_STRUC_FIELD + $timer.ID_FIELD)];
   call $timer.cancel_event;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.get_time
//
// DESCRIPTION:
//    Get the 'wall clock' time on a particular BT link.
//
// INPUTS:
//    - r1 = pointer to a variable that stores the 'wall clock' structure,
//           should be of length $wall_clock.STRUC_SIZE
//
// OUTPUTS:
//    - r1 = 'wall clock' time
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    Before calling this function for the first time the $wall_clock.init_time
// function should be run.
//
// *****************************************************************************
.MODULE $M.wall_clock.get_time;
   .CODESEGMENT WALL_CLOCK_GET_TIME_PM;

   $wall_clock.get_time:

   // 'wall clock' = (TIMER_TIME - adjustment_value)
   r1 = M[r1 + $wall_clock.ADJUSTMENT_VALUE_FIELD];
   r1 = r1 + M[$TIMER_TIME];
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.message_handler
//
// DESCRIPTION:
//    Message handler for $LONG_MESSAGE_WALL_CLOCK_RESPONSE and
//    $LONG_MESSAGE_WALL_CLOCK_RESPONSE_TBTA messages
//
// INPUTS:
//    - r0 = message ID
//    - r3 = message pointer:
//              Data 0      (BT address: Type) If LONG_MESSAGE_WALL_CLOCK_RESPONSE_TBTA. 
//                           The rest the same as below.
//              Data 0 or 1 (BT address: NAP)
//              Data 1 or 2 (BT address: UAP (in MS 8 bits) + MS byte of LAP)
//              Data 2 or 3 (BT address: LS word of LAP)
//              Data 3 or 4 (Wall clock MSW)
//              Data 4 or 5 (Wall clock LSW)
//              Data 5 or 6 (Timestamp MSW)
//              Data 6 or 7 (Timestamp LSW)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    assume all
//
// NOTES:
//    In case of the _TBTA message one extra word will be placed at the top of
//    the message.
// *****************************************************************************
.MODULE $M.wall_clock.message_handler;
   .CODESEGMENT WALL_CLOCK_MESSAGE_HANDLER_PM;

   $wall_clock.message_handler:
   
   // push rLink onto stack
   $push_rLink_macro;

   // find the 'wall clock' struc that this message relates to
   // set r6 to point to it.
#ifndef OLD_BT_ADDRESS
   // move the pointer to the second entry for minimum change to the old code
   // when this new code is to replace the old one, this can be undone and
   // written properly.
   r3 = r3 + 1;
#endif

   r10 = $wall_clock.MAX_WALL_CLOCKS;
   r6 = M[$wall_clock.last_addr];
   do loop;
      // if we're at the last structure in the linked list then this message
      // ID is unknown
      Null = r6 - $wall_clock.LAST_ENTRY;
      if Z jump no_handler;

      // see if BT address matches
#ifndef OLD_BT_ADDRESS
      r0 = M[r6 + $wall_clock.BT_ADDR_TYPE_FIELD];
      r1 = M[r3 - 1];
      r1 = r1 AND 0xFF;
      Null = r0 - r1;
      if NZ jump no_match;
#endif

      r0 = M[r6 + $wall_clock.BT_ADDR_WORD0_FIELD];
      Null = r0 - M[r3];
      if NZ jump no_match;
      r0 = M[r6 + $wall_clock.BT_ADDR_WORD1_FIELD];
      r1 = M[r3 + 1];
      Null = r0 - r1;
      if NZ jump no_match;
      r0 = M[r6 + $wall_clock.BT_ADDR_WORD2_FIELD];
      r1 = M[r3 + 2];
      Null = r0 - r1;
      if Z jump found;

      no_match:

      // read the adddress of the next profiler
      r6 = M[r6 + $wall_clock.NEXT_ADDR_FIELD];
   loop:

   // something's gone wrong - either too many handlers,
   // or more likely the linked list has got corrupt.
   call $error;

   no_handler:
      // If unknown BT address either error or ignore the message
      #ifdef WALL_CLOCK_ERROR_IF_UNKNOWN_BT_ADDRESS
         call $error;
      #else
         rts;
      #endif

   found:

   // form 24bit ADJUSTMENT_VALUE value:
   //   r2 = 'firmware wall clock' x FIRMWARE_WALL_CLOCK_PERIOD
   //         - 'firmware timer time'

   // calc: 'firmware wall clock' x FIRMWARE_WALL_CLOCK_PERIOD
   r1 = M[r3 + 3];
   r2 = M[r3 + 4];
   rMAC = r1 LSHIFT -8;
   rMAC = rMAC AND 0xFF;
   rMAC = rMAC * ($wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_VALUE * 2) (int);
   r1 = r1 LSHIFT 16;
   r2 = r2 AND 0xFFFF;
   r2 = r2 + r1;
   rMAC = rMAC + r2 * ($wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_VALUE) (UU);
   r2 = rMAC LSHIFT (23 + $wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_SHIFT);

   // calc:  - 'firmware timer time'
   r4 = M[r3 + 6];
   r3 = M[r3 + 5];
   r3 = r3 LSHIFT 16;
   r4 = r4 AND 0xFFFF;
   r4 = r4 + r3;
   r2 = r2 - r4;

   // store ADJUSTMENT_VALUE
   M[r6 + $wall_clock.ADJUSTMENT_VALUE_FIELD] = r2;
   r0 = M[r6 + $wall_clock.CALLBACK_FIELD];
   if NZ call r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.message_handler_failed
//
// DESCRIPTION:
//    Message handler for $MESSAGE_WALL_CLOCK_FAILED  and 
//    $MESSAGE_WALL_CLOCK_FAILED_TBTA messages
//
// INPUTS:
//    - r0 = message ID
//    $MESSAGE_WALL_CLOCK_FAILED:
//       - r1 = message Data 0  (BT address: NAP)
//       - r2 = message Data 1  (BT address: UAP (in MS 8 bits) + MS byte of LAP)
//       - r3 = message Data 2  (BT address: LS word of LAP)
//    $MESSAGE_WALL_CLOCK_FAILED_TBTA:
//       - r1 = message Data 0  (BT address: Type)
//       - r2 = message Data 0  (BT address: NAP)
//       - r3 = message Data 1  (BT address: UAP (in MS 8 bits) + MS byte of LAP)
//       - r4 = message Data 2  (BT address: LS word of LAP)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// *****************************************************************************
.MODULE $M.wall_clock.message_handler_failed;
   .CODESEGMENT WALL_CLOCK_MESSAGE_HANDLER_FAILED_PM;

   $wall_clock.message_handler_failed:

   // we don't have an active connection on this BT link

#ifdef ERROR_ON_WALL_CLOCK_FAIL
   call $error;
#endif

   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $wall_clock.timer_handler
//
// DESCRIPTION:
//    Timer handler for a 'wall clock' struc
//
// INPUTS:
//    - r0 = the event ID
//    - r1 = address of the timer structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// *****************************************************************************
.MODULE $M.wall_clock.timer_handler;
   .CODESEGMENT WALL_CLOCK_TIMER_HANDLER_PM;

   $wall_clock.timer_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // save address of 'wall clock' struc for later
   r6 = r1 - $wall_clock.TIMER_STRUC_FIELD;

   // fire another timer
   r1 = r1;
   r2 = $wall_clock.UPDATE_TIMER_PERIOD;
   r3 = &$wall_clock.timer_handler;
   call $timer.schedule_event_in;

   // request the 'wall clock' on this link from the firmware again
#ifndef OLD_BT_ADDRESS
   r2 = Null OR $MESSAGE_GET_WALL_CLOCK_TBTA;
   r3 = M[r6 + $wall_clock.BT_ADDR_TYPE_FIELD];
   r4 = M[r6 + $wall_clock.BT_ADDR_WORD0_FIELD];
   r5 = M[r6 + $wall_clock.BT_ADDR_WORD1_FIELD];
   r6 = M[r6 + $wall_clock.BT_ADDR_WORD2_FIELD];
#else
   r2 = Null OR $MESSAGE_GET_WALL_CLOCK;
   r3 = M[r6 + $wall_clock.BT_ADDR_WORD0_FIELD];
   r4 = M[r6 + $wall_clock.BT_ADDR_WORD1_FIELD];
   r5 = M[r6 + $wall_clock.BT_ADDR_WORD2_FIELD];
#endif
   call $message.send_short;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif

