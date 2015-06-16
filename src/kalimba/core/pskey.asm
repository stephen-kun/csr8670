// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2006-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//   PS key library
//
// DESCRIPTION:
//   BlueCore chips include a Persistent Store area where parameters may be
// stored and retrieved. Such parameters include the device Bluetooth address
// but may include parameters such as volume levels, filter coefficients, etc..
// Consequently it is useful for Kalimba to be able to retrieve values from the
// persistent store.
//
//   This library presents an API for DSP applications to request the BlueCore
// firmware to retrieve a key from the Persistent Store. DSP applications
// request a key and when the key has been retrieved the associated handler is
// called.
//
//   The library uses structures to hold the information it requires for each
// request. Each structure should be of size $pskey.STRUC_SIZE and contains the
// following fields:
// @verbatim
//     Name                              Index
//     $pskey.NEXT_ENTRY_FIELD           0
//     $pskey.KEY_NUM_FIELD              1
//     $pskey.HANDLER_ADDR_FIELD         2
// @endverbatim
//
// *****************************************************************************

#ifndef PSKEY_INCLUDED
#define PSKEY_INCLUDED

#include "pskey.h"
#include "stack.h"
#include "message.h"
#include "kalimba_messages.h"
#include "timer.h"

.MODULE $pskey;
   .DATASEGMENT DM;

   .VAR request_in_progress;
   .VAR last_addr = $pskey.LAST_ENTRY;
   .VAR result_pass_message_struc[$message.STRUC_SIZE];
   .VAR result_fail_message_struc[$message.STRUC_SIZE];
   .VAR reattempt_timer_struc[$timer.STRUC_SIZE];

   #ifdef PSKEY_DEBUG_ON
      .VAR debug_count;
   #endif

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pskey.initialise
//
// DESCRIPTION:
//    Initialises the PS key library.
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
.MODULE $M.pskey.initialise;
   .CODESEGMENT PSKEY_INITIALISE_PM;

   $pskey.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // set up message handler for LONG_MESSAGE_PS_RESULT message
   r1 = &$pskey.result_pass_message_struc;
   r2 = $LONG_MESSAGE_PS_RESULT;
   r3 = &$pskey.result_message_handler;
   call $message.register_handler;

   // set up message handler for failure messages
   r1 = &$pskey.result_fail_message_struc;
   r2 = Null OR $MESSAGE_PS_FAIL;
   r3 = &$pskey.result_message_handler;
   call $message.register_handler;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pskey.read_key
//
// DESCRIPTION:
//    Registers a request to the firmware to read a PS key.
//
//  INPUTS
//    - r1 = pointer to a structure that stores the pskey handler structure,
//           should be of length $pskey.STRUC_SIZE
//    - r2 = PS key to retrieve
//    - r3 = address of PS key handler for this PS key
//
//  OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-6, r10, DoLoop
//
// NOTES:
//    This is a request to the Firmware to retrieve a PS key's value from the
// persistent store. This is not an instantaneous process. When you request a
// key the data is retrieved and a message is sent to Kalimba. Once the payload
// is complete the data is delivered to your registered handler.
//
//    If the information you require is larger than 64 words (128 bytes) you
// cannot retrieve it with this method, split the data over several keys.
//
//    This library allows queuing of requests, the structure you supply is used
// in a linked list, consequently you cannot use the same structure until it has
// been freed from the list by the library. When the handler is called the
// structure will have already been freed so you may use it to request another
// read at that point.
//
// NOTE: Values are stored in the PS as 16 bit numbers and are then sign
// extended to 24 bits as they are read from the MCU, ie 16 bit 0x8000, will be
// returned as 24 bit 0xFF8000.
//
// *****************************************************************************
.MODULE $M.pskey.read_key;
   .CODESEGMENT PSKEY_READ_KEY_PM;

   $pskey.read_key:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // save the PS key to retrieve
   M[r1 + $pskey.KEY_NUM_FIELD] = r2;
   M[r1 + $pskey.HANDLER_ADDR_FIELD] = r3;
   // mark this as the end of the list
   r3 = $pskey.LAST_ENTRY;
   M[r1 + $pskey.NEXT_ENTRY_FIELD] = r3;

   // load up the start of the list
   r0 = &$pskey.last_addr;

   #ifdef PSKEY_DEBUG_ON
      r3 = $pskey.MAX_HANDLERS;
      M[$pskey.debug_count] = r3;
   #endif

   find_end_of_list:
      #ifdef PSKEY_DEBUG_ON
         // have we been round too many times
         r3 = M[$pskey.debug_count];
         r3 = r3 - 1;
         if NEG call $error;
         M[$pskey.debug_count] = r3;
      #endif

      r2 = r0;

      // get the next address in the list
      r0 = M[r2 + $pskey.NEXT_ENTRY_FIELD];

      // is it the last one?
      Null = r0 - $pskey.LAST_ENTRY;
   if NZ jump find_end_of_list;

   // r2 should now point to the last element in the list
   M[r2 + $pskey.NEXT_ENTRY_FIELD] = r1;

   // are we fetching a PS key
   Null = r2 - &$pskey.last_addr;
   if Z call $pskey.private.send_request;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pskey.result_message_handler
//
// DESCRIPTION:
//    Handler to receive messages from Firmware and forward onto registered
//  PS key handler.
//
//  INPUTS:
//    - r0 = Message ID ($LONG_MESSAGE_PS_RESULT or $MESSAGE_PS_FAIL)
//    - r1 = PS key ID        (if failure)
//    - r2 = payload length   (if pass)
//    - r3 = payload address  (if pass)
//
//  OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
//
// NOTES:
//    The registered handler is called with the PS key ID, payload length and
// address of the payload in registers (see below). For example if you request
// the device's Bluetooth address you will get:
//@verbatim
//  r1 = 0x0001;
//  r2 = 5;
//  r3 = &buf; => 000001 0000BB FFA5A5 00005B 000002
//                  ID   Payload (4 words)
//@endverbatim
// Therefore the BT address for this device is: 0002 5B BBA5A5
//
//    The registered handler is called with the registers populated:
//@verbatim
//    Register         Pass                    Failure
//    --------         ---------------         -------------------------
//       r1            PS key ID               PS key ID
//       r2            Payload length          $pskey.FAILED_READ_LENGTH
//                     (key, value)            (-1)
//       r3            Payload address         N/A
//@endverbatim
//    The handler must check the length to determine if the request passed or
// failed.
//
//    Reads can fail, however they will only fail if the VM has attempted to
// send a large number of long messages to the DSP while the DSP has interrupts
// blocked. Typically this will not happen, however the handler MUST check the
// length of the key in case of failure. If a fail does occur your handler
// should probably just request the key again.
//
// NOTE: Values are stored in the PS as 16 bit numbers and are then sign
// extended to 24 bits as they are read from the MCU, ie 16 bit 0x8000, will be
// returned as 24 bit 0xFF8000.
//
// *****************************************************************************
.MODULE $M.pskey.result_message_handler;
   .CODESEGMENT PSKEY_RESULT_MESSAGE_HANDLER_PM;

   $pskey.result_message_handler:

   // is it a failure or pass message
   Null = r0 - $MESSAGE_PS_FAIL;
   if Z jump failure;
      // it was a pass get the Key's ID
      r1 = M[r3];
   jump ready;

   failure:
      // set the length to -1 to indicate it was a failure
      r2 = $pskey.FAILED_READ_LENGTH;
   ready:

   // clear the read in progress flag
   M[$pskey.request_in_progress] = Null;

   // ** work out who to forward the message to **
   r5 = &$pskey.last_addr;
   r0 = M[$pskey.last_addr + $pskey.NEXT_ENTRY_FIELD];

   #ifdef PSKEY_DEBUG_ON
      Null = r0 - $pskey.LAST_ENTRY;
      if Z call $error;

      r6 = $pskey.MAX_HANDLERS;
      M[$pskey.debug_count] = r6;
   #endif

   // this should always be the first one but might not be
   find_structure_loop:
      #ifdef PSKEY_DEBUG_ON
         // have we been round too many times
         r6 = M[$pskey.debug_count];
         r6 = r6 - 1;
         if NEG call $error;
         M[$pskey.debug_count] = r6;
      #endif

      r4 = M[r0 + $pskey.KEY_NUM_FIELD];
      Null = r1 - r4;
      if Z jump structure_found;

      // store the previous structure address
      r5 = r0;

      r0 = M[r0 + $pskey.NEXT_ENTRY_FIELD];
      Null = r0 - $pskey.LAST_ENTRY;
   if NZ jump find_structure_loop;

   // ** we don't appear to have asked for this ID **
   #ifdef PSKEY_DEBUG_ON
      call $error;
   #else
      rts;
   #endif

   structure_found:
   // push rLink onto stack
   $push_rLink_macro;

   // remove this handler from the list
   r4 = M[r0 + $pskey.NEXT_ENTRY_FIELD];
   M[r5 + $pskey.NEXT_ENTRY_FIELD] = r4;

   // call the relevant handler
   r0 = M[r0 + $pskey.HANDLER_ADDR_FIELD];
   call r0;

   // check if there are any more keys to retrieve
   r1 = M[$pskey.last_addr];
   Null = r1 - $pskey.LAST_ENTRY;
   if NZ call $pskey.private.send_request;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// $****************************************************************************
// MODULE:
//    $pskey.private.send_request
//
// DESCRIPTION:
//    This routine handles the sending of the message request to the firmware,
// if the message queue is full it will set a re-attempt timer and continue to
// try and send the message until it succeeds.
//
//    This is a private function within the PS key library and should never be
// called by an application - use $pskey.read_key instead.
//
//  INPUTS:
//    - none
//
//  OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-6, r10, DoLoop
//
// NOTES:
//    This is a private function, use $pskey.read_key instead.
//
// *****************************************************************************
.MODULE $M.pskey.private.send_request;
   .CODESEGMENT PSKEY_PRIVATE_SEND_REQUEST_PM;

   $pskey.private.send_request:

   // are we doing an access
   Null = M[$pskey.request_in_progress];
   if NZ rts;

   // push rLink onto stack
   $push_rLink_macro;

   // remove this timer from the list
   r2 = M[$pskey.reattempt_timer_struc + $timer.ID_FIELD];
   call $timer.cancel_event;

   // check there is space in the message queue
   call $message.send_queue_space;
   Null = r0 - 5;
   if NEG jump try_to_send_later;
      // send a message to the firmware requesting the key
      r1 = M[$pskey.last_addr];
      r2 = Null OR $MESSAGE_PS_READ;
      r3 = M[r1 + $pskey.KEY_NUM_FIELD];
      call $message.send_short;

      // set read in progress
      r0 = 1;
      M[$pskey.request_in_progress] = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

   try_to_send_later:
      // set a timer to call us again
      r1 = &$pskey.reattempt_timer_struc;
      r2 = $pskey.REATTEMPT_TIME_PERIOD;
      r3 = &$pskey.private.send_request;
      call $timer.schedule_event_in;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif

