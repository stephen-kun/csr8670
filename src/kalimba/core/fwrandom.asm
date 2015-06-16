// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//   Firmware's random number library
//
// DESCRIPTION:
//   The BlueCore MCU firmware includes a random number generator suitable for
// use in cryptography. Kalimba applications can register requests with this
// library to use this generator.
//
//   This library sequences as many messages as required to collect the required
// number bits, up to a maximum of $fwrandom.MAX_RAND_BITS (512).
//
//   Applications must supply a control structure of size $fwrandom.STRUC_SIZE
// and a buffer large enough to store the requested random bits. The routines
// will pack 16 bits into each word of the buffer, using the lower 16 bits of
// each word.
//
//   The control structure has the following fields:
// @verbatim
//     Name                              Index
//     $fwrandom.NEXT_ENTRY_FIELD           0
//     $fwrandom.NUM_REQ_FIELD              1
//     $fwrandom.NUM_RESP_FIELD             2
//     $fwrandom.RESP_BUF_FIELD             3
//     $fwrandom.HANDLER_ADDR_FIELD         4
// @endverbatim
//
// *****************************************************************************

#ifndef FWRANDOM_INCLUDED
#define FWRANDOM_INCLUDED

#include "fwrandom.h"
#include "stack.h"
#include "message.h"
#include "kalimba_messages.h"
#include "timer.h"

.MODULE $fwrandom;
   .DATASEGMENT DM;

   .VAR request_in_progress;
   .VAR last_addr = $fwrandom.LAST_ENTRY;
   .VAR result_pass_message_struc[$message.STRUC_SIZE];
   .VAR result_fail_message_struc[$message.STRUC_SIZE];
   .VAR reattempt_timer_struc[$timer.STRUC_SIZE];

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $fwrandom.initialise
//
// DESCRIPTION:
//    Initialises the fwrandom library.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r1, r2, r3
//
// *****************************************************************************
.MODULE $M.fwrandom.initialise;
   .CODESEGMENT FWRANDOM_INITIALISE_PM;

   $fwrandom.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // set up message handler for LONG_MESSAGE_FWRANDOM_RESULT message
   r1 = &$fwrandom.result_pass_message_struc;
   r2 = Null OR $LONG_MESSAGE_RAND_RESULT;
   r3 = &$fwrandom.result_message_handler;
   call $message.register_handler;

   // set up message handler for failure messages
   r1 = &$fwrandom.result_fail_message_struc;
   r2 = Null OR $MESSAGE_RAND_FAIL;
   r3 = &$fwrandom.result_message_handler;
   call $message.register_handler;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $fwrandom.get_rand_bits
//
// DESCRIPTION:
//    Registers a request to the MCU firmware to read random numbers.
//
// INPUTS:
//    - r1 = pointer to a structure that stores the fwrandom handler structure,
//           should be of length $fwrandom.STRUC_SIZE
//    - r2 = Number of random bits requested
//    - r3 = address of callback handler for this fwrandom request
//    - r4 = address of an array to write random bits into
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-6, r10, DoLoop
//
// NOTES:
//    This is a request to the MCU Firmware to retrieve random nummbers from the
// MCU firmware's internal random number generator. This is not an instantaneous
// process. When you request random numbers a message is sent by Kalimba
// requesting the bits and the supplied handler is called when the bits are
// available.
//
//    If the numbers requested from lib is larger than maximum allowed,
// $fwrandom.MAX_RAND_BITS (currently 512 bits), the request will be truncated
// to the $fwrandom.MAX_RAND_BITS. If more bits are required, the application
// should split the request into several.
//
//    This library allows queuing of requests, the structure you supply is used
// in a linked list, consequently you cannot use the same structure until it has
// been freed from the list by the library. When the handler is called the
// structure will have already been freed so you may use it to request another
// read at that point. Result are read from the buffer which was passed in  the
// structure.
//
// NOTE: Random numbers returned are grouped as 16 bit numbers and application
// should ignore the upper 8 bits, e.g. 160 bits are returned in 10 words.
//
// *****************************************************************************
.MODULE $M.fwrandom.get_rand_bits;
   .CODESEGMENT FWRANDOM_GET_RAND_BITS_PM;

   $fwrandom.get_rand_bits:

   // push rLink onto stack
   $push_rLink_macro;

   // limit the number of bits
   r0 = $fwrandom.MAX_RAND_BITS - r2;
   #ifdef FWRANDOM_DEBUG_ON
      if NEG call $error;
   #else
      if NEG r2 = r2 + r0;
   #endif

   // convert bits to XAP words
   r2 = r2 + 15;
   r2 = r2 ASHIFT -4;

   // save the number of random bits to retrieve
   M[r1 + $fwrandom.NUM_REQ_FIELD]      = r2;
   M[r1 + $fwrandom.HANDLER_ADDR_FIELD] = r3;
   M[r1 + $fwrandom.RESP_BUF_FIELD]     = r4;

   // Initialise num resp
   M[r1 + $fwrandom.NUM_RESP_FIELD] = 0;

   // block interrupts
   call $block_interrupts;

   // load up the start of the list
   r0 = &$fwrandom.last_addr;

   #ifdef FWRANDOM_DEBUG_ON
      r3 = $fwrandom.MAX_HANDLERS;
   #endif

   find_end_of_list:
      #ifdef FWRANDOM_DEBUG_ON
         // have we been round too many times
         r3 = r3 - 1;
         if NEG call $error;
      #endif

      r2 = r0;

      // get the next address in the list
      r0 = M[r0 + $fwrandom.NEXT_ENTRY_FIELD];

      // is it the last one?
      Null = r0 - $fwrandom.LAST_ENTRY;
   if NZ jump find_end_of_list;

   // mark this entry as the last, r0 is set to LAST_ENTRY
   M[r1 + $fwrandom.NEXT_ENTRY_FIELD] = r0;
   // r2 should now point to the last element in the list
   M[r2 + $fwrandom.NEXT_ENTRY_FIELD] = r1;

   // is there a request in progress
   Null = M[$fwrandom.request_in_progress];
   if Z call $fwrandom.private.send_request;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $fwrandom.result_message_handler
//
// DESCRIPTION:
//    Handler to receive messages from MCU firmware and forward to registered
//  response handler.
//
// INPUTS:
//    - r0 = Message ID ($LONG_MESSAGE_FWRANDOM_RESULT or $MESSAGE_FWRANDOM_FAIL)
//    - r1 = address of original structure
//    - r2 = payload length (Original request or $fwrandom.FAILED_READ_LENGTH)
//    - r3 = payload address
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
//
// NOTES:
//    The MCU firmware may not return all the bits requested. If this is the
// case, this routine will request the remaining bits and only call the
// registered handler once all the requested bits have been delivered.
//
//    When all the bits are available, the registered handler is called with the
// address of the payload in registers, see below:
//
//@verbatim
//    Register         Pass                      Failure
//    --------         ---------------           -------------------------
//       r2            Payload length            $fwrandom.FAILED_READ_LENGTH
//                     ( random no.s)            (-1)
//       r3            Payload address           Payload address
//@endverbatim
//
//    The handler must check the length to determine if the request passed or
// failed.
//
//    Requests can fail, however they will only fail if the VM has attempted to
// send a large number of long messages to the DSP while the DSP has interrupts
// blocked. Typically this will not happen, however the handler MUST check the
// length of the result in case of failure. If a fail does occur your handler
// should probably just request the random number again.
//
// NOTE: Values are returned from the MCU fimware as 16 bit numbers and are then
// sign extended to 24 bits as they are read from the MCU, ie 16 bit 0x8000,
// will be returned as 24 bit 0xFF8000.
//
// *****************************************************************************
.MODULE $M.fwrandom.result_message_handler;
   .CODESEGMENT FWRANDOM_RESULT_MESSAGE_HANDLER_PM;

   $fwrandom.result_message_handler:

   $push_rLink_macro;

   // ** work out who to forward the message to **
   r1 = M[$fwrandom.last_addr];

   #ifdef FWRANDOM_DEBUG_ON
      Null = r1 - $fwrandom.LAST_ENTRY;
      if Z call $error;
   #endif

   // is it a failure or pass message
   Null = r0 - $MESSAGE_RAND_FAIL;
   if NZ jump success;
      // set the length to -1 to indicate it was a failure
      r2 = $fwrandom.FAILED_READ_LENGTH;
      jump finish_this_request;

   success:

   // clear the read in progress flag
   M[$fwrandom.request_in_progress] = Null;

   // copy random numbers into the response buffer
   r0 = M[r1 + $fwrandom.NUM_RESP_FIELD];
   r10 = M[r1 + $fwrandom.RESP_BUF_FIELD];
   I0 = r10 + r0;

   // Add up the responses received so far, save in r4 for later
   r4 = r0 + r2;
   M[r1 + $fwrandom.NUM_RESP_FIELD] = r4;

   // get the number of random words returned in the response
   r10 = r2;

   I4 = r3;
   // Now copy
   do resp_copy_loop;
      r0 = M[I4,1];
      M[I0,1] = r0;
   resp_copy_loop:

   // Check if we have the accumulated required random numbers, r4 still set
   r0 = M[r1 + $fwrandom.NUM_REQ_FIELD];
   Null = r4 - r0;
   // If we've got required numbers then finish this request
   if POS jump finish_this_request;
      // Else send more request for the remaining and finish
      call $fwrandom.private.send_request;
      jump finish_processing_response;

   finish_this_request:
      // remove this structure from the list
      r0 = M[r1 + $fwrandom.NEXT_ENTRY_FIELD];
      M[$fwrandom.last_addr] = r0;

      //Convert back words to bits
      r0 = M[r1 + $fwrandom.NUM_RESP_FIELD];
      r0 = r0 * 16 (int);
      M[r1 + $fwrandom.NUM_RESP_FIELD] = r0;

      // call the relevant handler
      rLink = M[r1 + $fwrandom.HANDLER_ADDR_FIELD];

      // return the structure in r3
      r3 = M[r1 + $fwrandom.RESP_BUF_FIELD];

      call rLink;

      // check if there are any more fwrandom requests to retrieve
      r0 = M[$fwrandom.last_addr];
      Null = r0 - $fwrandom.LAST_ENTRY;
      if NZ call $fwrandom.private.send_request;

   finish_processing_response:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// $****************************************************************************
// MODULE:
//    $fwrandom.private.send_request
//
// DESCRIPTION:
//    This routine handles the sending of the message request to the firmware,
// if the message queue is full it will set a re-attempt timer and continue to
// try and send the message until it succeeds.
//
//    This is a private function within the fwrandom library and should never be
// called by an application - use $fwrandom.get_rand_bits instead.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-6, r10, DoLoop
//
// NOTES:
//    This is a private function, use $fwrandom.get_rand_bits instead.
//
// *****************************************************************************
.MODULE $M.fwrandom.private.send_request;
   .CODESEGMENT FWRANDOM_PRIVATE_SEND_REQUEST_PM;

   $fwrandom.private.send_request:

   // are we doing an access
   Null = M[$fwrandom.request_in_progress];
   if NZ rts;

   // push rLink onto stack
   $push_rLink_macro;

   // remove this timer from the list
   r2 = M[$fwrandom.reattempt_timer_struc + $timer.ID_FIELD];
   if NZ call $timer.cancel_event;

   // check there is space in the message queue
   call $message.send_queue_space;
   Null = r0 - 5;
   if NEG jump try_to_send_later;
      // send a message to the firmware requesting the random numbers
      r1 = M[$fwrandom.last_addr];
      r2 = Null OR $MESSAGE_RAND_REQ;
      r3 = M[r1 + $fwrandom.NUM_REQ_FIELD] ;
      r4 = M[r1 + $fwrandom.NUM_RESP_FIELD];
      r3 = r3 - r4;
      call $message.send_short;

      // set read in progress
      r0 = 1;
      M[$fwrandom.request_in_progress] = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

   try_to_send_later:
      // set a timer to call us again
      r1 = &$fwrandom.reattempt_timer_struc;
      r2 = $fwrandom.REATTEMPT_TIME_PERIOD;
      r3 = &$fwrandom.private.send_request;
      call $timer.schedule_event_in;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
