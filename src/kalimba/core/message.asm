// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Messaging Library
//
// DESCRIPTION:
//    This library contains functions to send and receive messages from the MCU
//    or VM application.
//
//    Messages are sent using interrupts and a shared memory window to carry the
//    message payload. Messages have a 16-bit ID, with up to four 16-bit words
//    of data.
//
//    <H3>Reserved message IDs</H3>
//    Messages with an ID greater than 0x8000 are reserved for use by the
//    firmware and VM for background maintenance.  When a message is received by
//    the Kalimba, a subroutine is called to process the message.  Up to 50
//    such message types may be 'registered' in this way.  This may be changed
//    by editing the definition of $message.MAX_MESSAGE_HANDLERS in message.h.
//
//    On the Kalimba side, up to 20 'short' messages may be queued for
//    processing by the MCU defined by $message.QUEUE_SIZE_IN_MSGS in message.h.
//    The queue fullness and space can be determined by calling
//    $message.send_queue_fullness and $message.send_queue_space respectively.
//    If the queue is full and a further message send is attempted the error
//    routine will be called if MESSAGE_ERROR_IF_QUEUE_FULL is defined (debug
//    mode). Otherwise the further message is silently discarded.  Messages from
//    the VM are not queued, however calls to KalimbaSendMessage will fail until
//    the previous message has been processed by the Kalimba.
//
//    <H3>Long messages</H3>
//    The message library has been extended to support sending and receiving of
//    'long messages', these are transported using the underlying 'short'
//    message system.  Long messages can be of variable length. For details of
//    sending and receiving long messages look at $message.send_long and
//    $message.received_service_routine respectively.  There is an example app
//    to demonstrate long message support, as well as reading PS keys, in
//    [BlueLab]/apps/examples/kalimba_long_message_example/
//
//    When sending a long message the data is buffered through the system as it
//    is broken up into and then reconstructed from short messages. Typically
//    the message is buffered as {ID, length, payload}. Consequently the size of
//    a message is really (payload + 2).
//
//    <H3>Sending messages</H3>
//    When sending a long message from the DSP to the VM, it is buffered in two
//    places before delivery to the VM application. Firstly within the DSP in
//    $message.queue where it is stored as a series of 4-word short messages for
//    sending, secondly it is buffered in the Firmware as it is reconstructed
//    from these short messages. The Firmware buffer is dynamically allocated
//    and so is limited by the available resources when you send your message.
//
//    The size of the message queue ($message.queue) is defined interms of the
//    largest long message payload that can be sent -
//    $message.MAX_LONG_MESSAGE_TX_PAYLOAD_SIZE, defined in message.h, currently
//    set to 80. Note, this figure does not include the ID and length, so the
//    XAP needs to allocate a buffer of size 82 to receive such a message.
//
//    Changing this value will allow the DSP to send larger or smaller messages
//    however it does not guarantee resources in the XAP to receive the message.
//    If you wish to send larger messages, change the value and rebuild your DSP
//    libraries. Then you will have to test your applicattion has suitable
//    resources available at run time.
//
//    <H3>Receiving messages</H3>
//    When receiving a long message from the VM, the message is buffered in the
//    firmware buffer and then in the DSP in $message.long_message_data, which
//    is of size $message.LONG_MESSAGE_BUFFER_SIZE. This figure is calculated so
//    it is large enough to receive a message with a payload size of
//    $message.MAX_LONG_MESSAGE_RX_PAYLOAD_SIZE - currently set to 80 in
//    message.h. Again this figure does not include the ID and length so the XAP
//    needs to be able to allocate an 82 word bufffer to send the message.
//
//    <H3>PS key requests</H3>
//    When the DSP requests a PS key, the firmware uses a special buffer of size
//    64. This contains the PS key ID as the first word and the PS key body as
//    the payload meaning the largest key that can be retrieved is of size 63.
//    This is then sent directly to the DSP which receives the message in
//    $message.long_message_data, consequently the Firmware buffer is the
//    limiting buffer and so the largest PS key that the DSP can request the
//    Firmware to retrieve is of size 63.
//
//    Typically, latencies of less than 1ms are encountered by messages passed
//    from the MCU to the Kalimba.  In the other direction, the MCU may take
//    upto 20ms to process a message.
//
// *****************************************************************************

#ifndef MESSAGE_INCLUDED
#define MESSAGE_INCLUDED

#include "stack.h"
#include "message.h"
#include "timer.h"
#include "kalimba_standard_messages.h"

#ifdef DEBUG_ON
   #define MESSAGE_ERROR_IF_UNKNOWN_MESSAGE_ID
   #define MESSAGE_ERROR_IF_QUEUE_FULL
   #define MESSAGE_ERROR_IF_MESSAGE_TOO_LONG
   #define MESSAGE_ERROR_IF_MASK_ID_WRONG
   #define MESSAGE_ERROR_IF_MULTIPLE_DEFAULT_HANDLERS
#endif

// comment out this define to remove long message support
#define MESSAGE_LONG_MESSAGE_SUPPORT

.MODULE $message;
   .DATASEGMENT DM;

   .VAR     last_addr = $message.LAST_ENTRY;
   .VAR     reattempt_timer_struc[$timer.STRUC_SIZE];

   .VAR     queue[$message.QUEUE_SIZE_IN_WORDS];
   .VAR     queue_read_ptr = 0;
   .VAR     queue_write_ptr = 0;
   .VAR     last_seq_sent;

   .VAR     long_message_data[$message.LONG_MESSAGE_BUFFER_SIZE];
   .VAR     long_message_size;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.initialise
//
// DESCRIPTION:
//    Initialise message system
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0
//
// NOTES:
//    Should be called before interrupts are initialised (or at least before any
//    messages will be sent/received)
//
// *****************************************************************************
.MODULE $M.message.initialise;
   .CODESEGMENT MESSAGE_INITIALISE_PM;

   $message.initialise:

   // initialise $message.last_seq_sent
   r0 = M[$message.ACK_FROM_MCU];
   M[$message.last_seq_sent] = r0;
   rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.register_handler
//
// DESCRIPTION:
//    Register a message handler function
//
// INPUTS:
//    - r1 = pointer to a variable that stores the message handler structure,
//         should be of length $message.STRUC_SIZE
//    - r2 = message ID
//    - r3 = message handler address for this message ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1
//
// *****************************************************************************
// *****************************************************************************
// MODULE:
//    $message.register_handler_with_mask
//
// DESCRIPTION:
//    Register a message handler function with a mask
//
// INPUTS:
//    - r1 = pointer to a variable that stores the message handler structure,
//         should be of length $message.STRUC_SIZE
//    - r2 = message ID
//    - r3 = message handler address for this message ID
//    - r4 = mask to apply to received ID before comparing
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r4
//
// NOTES:
//    This function allows you to specify a mask to apply to the received
// message ID before comparing it. This allows a single handler to be registered
// to receive a range of IDs:
// @verbatim
//    IDs:            0x2000 - 0x20FF          0x0000-0x0003
//
//    Registered ID:  0x2000                   0x0000
//    Mask:           0x00FF                   0x0003
// @endverbatim
//
//    As with $message.register_handler, the handler is passed the ACTUAL ID
// received by the service routine NOT the masked version.
//
// *****************************************************************************
.MODULE $M.message.register_handler;
   .CODESEGMENT MESSAGE_REGISTER_HANDLER_PM;

   $message.register_handler_with_mask:
   r4 = r4 XOR 0xFFFF;
   M[r1 + $message.MASK_FIELD] = r4;
   jump mask_field_set;

   $message.register_handler:

   // zero the mask field
   r0 = Null OR 0xFFFF;
   M[r1 + $message.MASK_FIELD] = r0;

   mask_field_set:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // set the next address field of this structure to the previous last_addr
   r0 = M[$message.last_addr];
   M[r1 + $message.NEXT_ADDR_FIELD] = r0;
   // set new last_addr to the address of this structure
   M[$message.last_addr] = r1;

   #ifdef MESSAGE_ERROR_IF_MASK_ID_WRONG
      // check the address is correct for the mask
      r0 = M[r1 + $message.MASK_FIELD];
      // mask off the bits we don't care about
      r0 = r0 AND r2;
      // check that's the same as the ID we were given
      Null = r2 - r0;
      if NZ call $error;
   #endif

   // store new entry's ID and handler address in this structre
   M[r1 + $message.ID_FIELD] = r2;
   M[r1 + $message.HANDLER_ADDR_FIELD] = r3;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.register_default_handler
//
// DESCRIPTION:
//    Register a message handler function
//
// INPUTS:
//    - r1 = pointer to a variable that stores the message handler structure,
//         should be of length $message.STRUC_SIZE
//    - r3 = message handler address for this message ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r3
//
// *****************************************************************************
.MODULE $M.message.register_handler;
   .CODESEGMENT MESSAGE_REGISTER_DEFAULT_HANDLER_PM;

   $message.register_default_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // populate the block
   M[r1 + $message.NEXT_ADDR_FIELD]    = 0;
   M[r1 + $message.ID_FIELD]           = 0;
   M[r1 + $message.MASK_FIELD]         = 0;
   M[r1 + $message.HANDLER_ADDR_FIELD] = r3;

   // find the tail of the list
   r0 = $message.last_addr;
   find_tail_loop:
      r3 = M[r0 + $message.NEXT_ADDR_FIELD];
      Null = r3 - $message.LAST_ENTRY;
      if Z jump found_tail;
      r0 = r3;
   jump find_tail_loop;

   found_tail:

   #ifdef MESSAGE_ERROR_IF_MULTIPLE_DEFAULT_HANDLERS
      // now check if the tail is a default also
      Null = r0 - &$message.last_addr;
      if Z jump default_okay;
      Null = M[r0 + $message.ID_FIELD];
      if NZ jump default_okay;
      Null = M[r0 + $message.MASK_FIELD];
      if Z call $error;
      default_okay:
   #endif

   // put this on the end
   M[r0 + $message.NEXT_ADDR_FIELD] = r1;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.unregister_handler
//
// DESCRIPTION:
//    Unregister a message handler function
//
// INPUTS:
//    - r3 = message ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// *****************************************************************************
.MODULE $M.message.unregister_handler;
   .CODESEGMENT MESSAGE_UNREGISTER_HANDLER_PM;

   $message.unregister_handler:

   r10 = $message.MAX_MESSAGE_HANDLERS;
   r1 = M[$message.last_addr];
   r2 = &$message.last_addr;

   do find_id_loop;
      Null = r1 - $message.LAST_ENTRY;
      if EQ jump id_not_found;

      r0 = M[r1 + $message.ID_FIELD];
      Null = r0 - r3;
      if NE jump get_next;
         r0 = M[r1 + $message.NEXT_ADDR_FIELD];
         M[r2] = r0;
         rts;
      get_next:
      r2 = r1 + $message.NEXT_ADDR_FIELD;
      r1 = M[r1 + $message.NEXT_ADDR_FIELD];
   find_id_loop:

   id_not_found:
   #ifdef DEBUG_ON
      // Message ID not found
      call $error;
   #endif

   rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.send
//
// DESCRIPTION:
//    Send a short or long message to the mcu/vm.  If a previous message is
// waiting to be acknowledged then the new message is placed in the queue and a
// timer is set to attempt to resend it after a small period of time.
//
// INPUTS:
//    - Standard (short) message mode:
//      - r2 = message ID
//      - r3 = message Data 0
//      - r4 = message Data 1
//      - r5 = message Data 2
//      - r6 = message Data 3
//    - Long message mode:
//      - r2 = $message.LONG_MESSAGE_MODE_ID (a special flag to imply long
//                                                            message mode)
//      - r3 = long message ID (the actual ID of the message to send)
//      - r4 = long message size (in words)
//      - r5 = long message address of payload
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r5, r6, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.message.send;
   .CODESEGMENT MESSAGE_SEND_PM;

   $message.send:

#ifdef MESSAGE_LONG_MESSAGE_SUPPORT
   Null = r2 - $message.LONG_MESSAGE_MODE_ID;
   if Z jump $message.send_long;
#endif

   jump $message.send_short;

.ENDMODULE;







#ifdef MESSAGE_LONG_MESSAGE_SUPPORT
// *****************************************************************************
// MODULE:
//    $message.send_long
//
// DESCRIPTION:
//    Send a long message to the mcu/vm.  If a previous message is waiting to
// be acknowledged then the new message is placed in the queue and a timer is
// set to attempt to resend it after a small period of time.
//
// INPUTS:
//    - r3 = long message ID (the actual ID of the message to send)
//    - r4 = long message size (in words)
//    - r5 = long message address of payload
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r5, r6, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.message.send_long;
   .CODESEGMENT MESSAGE_SEND_LONG_PM;

   $message.send_long:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   r2 = $message.LONG_MESSAGE_MODE_ID;

   // number of short messages to send, r10 = payload length + 2 (id + length)
   // +3 because LSHIFT will round down not round up
   r10 = r4 + (2 + 3);
   r10 = r10 LSHIFT -2;

   r1 = M[$message.queue_write_ptr];

   // r6 = short message ID to use (0xFFF0 then also bit 0 set if 1st packet
   //                                            and bit 1 set if last packet)
   r6 = Null OR ($MESSAGE_PART_BASE + 1);
   do long_message_loop;
      // r0 = incremented message queue write pointer
      r0 = r1 + $message.QUEUE_WORDS_PER_MSG;
      Null = r0 - $message.QUEUE_SIZE_IN_WORDS;
      if Z r0 = 0;
      // see if message queue is full (read_ptr=write_ptr)
      Null = r0 - M[$message.queue_read_ptr];
      #ifdef MESSAGE_ERROR_IF_QUEUE_FULL
         // the message queue is full we just error!
         if Z call $error;
      #else
         // the message queue is full we just dont send any of the long message
         if Z jump all_done;
      #endif

      // -- add the message to the queue --

      // if last packet then set bit 1 of short message ID
      Null = r10 - 1;
      if NZ jump not_last_packet;
         r6 = r6 OR 2;
      not_last_packet:

      // write short message ID into the queue
      M[$message.queue + r1] = r6;

      // if first packet then handle it differently
      Null = r6 AND 1;
      if Z jump not_first_message;
         // clear bit 0 from short message ID for next time
         r6 = r6 - 1;
         M[($message.queue + 1) + r1] = r3;
         M[($message.queue + 2) + r1] = r4;
         r5 = r5 - 2;
         jump last_two_words;

      // write payload for short message into message queue
      not_first_message:
      r2 = M[r5];
      M[($message.queue + 1) + r1] = r2;
      r2 = M[r5 + 1];
      M[($message.queue + 2) + r1] = r2;

      last_two_words:
      r2 = M[r5 + 2];
      M[($message.queue + 3) + r1] = r2;
      r2 = M[r5 + 3];
      M[($message.queue + 4) + r1] = r2;
      r5 = r5 + 4;
      // r1 = temporary copy of message queue write pointer
      r1 = r0;
   long_message_loop:

   M[$message.queue_write_ptr] = r0;

   call $message.private.try_to_send_message;

   all_done:
   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif







// *****************************************************************************
// MODULE:
//    $message.send_short
//
// DESCRIPTION:
//    Send a short message to the mcu/vm.  If a previous message is  waiting to
// be acknowledged then the new message is placed in the queue and a timer is
// set to attempt to resend it after a small period of time.
//
// INPUTS:
//    - r2 = message ID
//    - r3 = message Data 0
//    - r4 = message Data 1
//    - r5 = message Data 2
//    - r6 = message Data 3
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r5, r6, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.message.send_short;
   .CODESEGMENT MESSAGE_SEND_SHORT_PM;

   $message.send_short:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // r0 = incremented message queue write pointer
   r1 = M[$message.queue_write_ptr];
   r0 = r1 + $message.QUEUE_WORDS_PER_MSG;
   Null = r0 - $message.QUEUE_SIZE_IN_WORDS;
   if Z r0 = 0;
   // see if message queue is full (read_ptr=write_ptr)
   Null = r0 - M[$message.queue_read_ptr];
   #ifdef MESSAGE_ERROR_IF_QUEUE_FULL
      // the message queue is full we just error!
      if Z call $error;
   #else
      // the message queue is full we just dont send the message
      if Z jump all_done;
   #endif
   // store updated write pointer
   M[$message.queue_write_ptr] = r0;

   // add the message to the queue
   M[($message.queue + 0) + r1] = r2;
   M[($message.queue + 1) + r1] = r3;
   M[($message.queue + 2) + r1] = r4;
   M[($message.queue + 3) + r1] = r5;
   M[($message.queue + 4) + r1] = r6;

   // try sending the message
   call $message.private.try_to_send_message;

   all_done:
   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;









// $****************************************************************************
// PRIVATE FUNCTION:
//    $message.private.try_to_send_message
//
// DESCRIPTION:
//    Sends a message from the message queue to the mcu/vm.  If their are more
// messages in the queue or the mcu hasn't acknowledged the last messsage yet
// then we post a timer to call this function a little while later.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// NOTES:
//    This is a private function don't call it directly from your application
// code.
//
// *****************************************************************************
.MODULE $M.message.private.try_to_send_message;
   .CODESEGMENT MESSAGE_PRIVATE_TRY_TO_SEND_MESSAGE_PM;

   $message.private.try_to_send_message:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   r0 = M[$message.ACK_FROM_MCU];
   // see if sequence numbers are the same
   // otherwise we'll have to post another timer
   r0 = r0 - M[$message.last_seq_sent];

   // mask off just the ls-16bits
   Null = r0 AND 0xFFFF;
   if NZ jump queue_not_empty;

   // get the message from the queue and copy payload
   r1 = M[$message.queue_read_ptr];
   r0 = M[($message.queue + 1) + r1];   M[$message.DATA_TO_MCU + 0] = r0;
   r0 = M[($message.queue + 2) + r1];   M[$message.DATA_TO_MCU + 1] = r0;
   r0 = M[($message.queue + 3) + r1];   M[$message.DATA_TO_MCU + 2] = r0;
   r0 = M[($message.queue + 4) + r1];   M[$message.DATA_TO_MCU + 3] = r0;

   // increment local sequence number
   r0 = M[$message.last_seq_sent];
   r0 = r0 + 1;
   M[$message.last_seq_sent] = r0;

   // raise interrupt by writing the event ID
   r0 = M[$message.queue + r1];

   M[$DSP2MCU_EVENT_DATA] = r0;

   // increment the message queue read pointer
   r1 = r1 + $message.QUEUE_WORDS_PER_MSG;
   Null = r1 - $message.QUEUE_SIZE_IN_WORDS;
   if Z r1 = 0;
   M[$message.queue_read_ptr] = r1;
   Null = r1 - M[$message.queue_write_ptr];
   // if message queue is empty we just exit
   if Z jump all_done;

   queue_not_empty:

   // schedule a timer event as there are still messages in the queue
   // we must first cancel a possible previous timer using this struc
   r2 = M[$message.reattempt_timer_struc + $timer.ID_FIELD];
   call $timer.cancel_event;

   r1 = &$message.reattempt_timer_struc;
   r2 = $message.REATTEMPT_SEND_PERIOD;
   r3 = &$message.private.try_to_send_message;
   call $timer.schedule_event_in;

   all_done:

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $message.send_queue_fullness
//
// DESCRIPTION:
//    See how full the Kalimba side send message queue is.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - r0 = Queue fullness (number of words still to be sent)
//
// TRASHED REGISTERS:
//    none
//
// *****************************************************************************
.MODULE $M.message.send_queue_fullness;
   .CODESEGMENT MESSAGE_SEND_QUEUE_FULLNESS_PM;

   $message.send_queue_fullness:

   r0 = M[$message.queue_write_ptr];
   r0 = r0 - M[$message.queue_read_ptr];
   if POS rts;
   r0 = r0 + $message.QUEUE_SIZE_IN_WORDS;
   rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.send_queue_space
//
// DESCRIPTION:
//    See how much space there is in the Kalimba side send message queue.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - r0 = Queue space (number of words available)
//
// TRASHED REGISTERS:
//    none
//
// *****************************************************************************
.MODULE $M.message.send_queue_space;
   .CODESEGMENT MESSAGE_SEND_QUEUE_SPACE_PM;

   $message.send_queue_space:

   r0 = M[$message.queue_read_ptr];
   r0 = r0 - M[$message.queue_write_ptr];
   r0 = r0 - 1;
   if POS rts;
   r0 = r0 + $message.QUEUE_SIZE_IN_WORDS;
   rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.received_service_routine
//
// DESCRIPTION:
//    Receive a message from the MCU/VM once an interrupt has occured and call
//    the appropriate message handler function.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTES:
//    The handler function is passed:
//    - Standard (short) message mode:
//      - r0 = message ID
//      - r1 = message Data 0
//      - r2 = message Data 1
//      - r3 = message Data 2
//      - r4 = message Data 3
//    - Long message mode:
//      - r0 = $message.LONG_MESSAGE_MODE_ID (a special flag to imply long message mode)
//      - r1 = long message ID (the actual ID of the message to send)
//      - r2 = long message size (in words)
//      - r3 = long message address of payload
//
//    The handler function can trash any register (the ISR will restore everything)
//
// *****************************************************************************
.MODULE $M.message.received_service_routine;
   .CODESEGMENT MESSAGE_RECEIVED_SERVICE_ROUTINE_PM;

   $message.received_service_routine:

   // push rLink onto stack
   $push_rLink_macro;

   // by default set flag to imply standard (short) message mode
   M0 = 0;

   // copy ID
   r0 = M[$MCU2DSP_EVENT_DATA];

#ifdef MESSAGE_LONG_MESSAGE_SUPPORT
   // see if special ID for long message protocol (ID's 0xFFF0,0xFFF1,0xFFF2,0xFFF3)
   r1 = r0 AND $MESSAGE_PART_BASE;
   Null = r1 XOR $MESSAGE_PART_BASE;
   if NZ jump non_long_message;

      // see if initial packet of message
      Null = r0 AND 1;
      if Z jump not_initial_packet;
         // if initial packet set size to 0
         M[$message.long_message_size] = Null;
      not_initial_packet:

      r1 = M[$message.long_message_size];
      Null = r1 - $message.MAX_LONG_MESSAGE_RX_SIZE;
      #ifdef MESSAGE_ERROR_IF_MESSAGE_TOO_LONG
         // if message too long just error
         if POS call $error;
      #else
         // if message too long just throw away middle fragments
         if NEG jump message_not_too_long;
            r1 = r1 - 4;
         message_not_too_long:
      #endif

      // store message data in buffer
      r2 = M[$message.DATA_TO_DSP + 0];
      M[r1 + ($message.long_message_data + 0)] = r2;
      r2 = M[$message.DATA_TO_DSP + 1];
      M[r1 + ($message.long_message_data + 1)] = r2;
      r2 = M[$message.DATA_TO_DSP + 2];
      M[r1 + ($message.long_message_data + 2)] = r2;
      r2 = M[$message.DATA_TO_DSP + 3];
      M[r1 + ($message.long_message_data + 3)] = r2;

      // increment message size
      r1 = r1 + 4;
      M[$message.long_message_size] = r1;

      // see if final packet of message
      Null = r0 AND 2;
      if NZ jump final_packet;

         not_final_packet:
         // increment ack number so that mcu can send another interrupt
         r5 = M[$message.ACK_FROM_DSP];
         r5 = r5 + 1;
         M[$message.ACK_FROM_DSP] = r5;

         // pop rLink from stack
         jump $pop_rLink_and_rts;

      final_packet:
      // final packet of a long message
      // r0 = long message ID
      r0 = M[($message.long_message_data + 0)];
      // remove any sign extension added by the MCU window access
      r0 = r0 AND 0xFFFF;
      // set flag to imply long message mode
      M0 = 1;

   non_long_message:
#endif

   // search through all message handlers to find the matching ID
   r10 = $message.MAX_MESSAGE_HANDLERS;
   r1 = M[$message.last_addr];
   do loop;
      // if we're at the last structure in the linked list then this message
      // ID is unknown
      Null = r1 - $message.LAST_ENTRY;
      if Z jump no_handler;

      // see if ID's matches
      r2 = M[r1 + $message.MASK_FIELD];
      r3 = r0 AND r2;
      r2 = M[r1 + $message.ID_FIELD];
      Null = r3 - r2;
      if Z jump found;

      // read the adddress of the next profiler
      r1 = M[r1 + $message.NEXT_ADDR_FIELD];
   loop:

   // something's gone wrong - either too many handlers,
   // or more likely the linked list has got corrupt.
   call $error;

   no_handler:
      // If unknown ID either error or ignore the message
      #ifdef MESSAGE_ERROR_IF_UNKNOWN_MESSAGE_ID
         call $error;
      #else
         // increment ack number so that mcu can send another interrupt
         r5 = M[$message.ACK_FROM_DSP];
         r5 = r5 + 1;
         M[$message.ACK_FROM_DSP] = r5;
         // pop rLink from stack
         jump $pop_rLink_and_rts;
      #endif

   found:

   // lookup address of handler
   rLink = M[r1 + $message.HANDLER_ADDR_FIELD];

#ifdef MESSAGE_LONG_MESSAGE_SUPPORT
   Null = M0;
   if Z jump short_message_mode;
      // long message mode
      // set:
      //   r0 = $message.LONG_MESSAGE_MODE_ID;
      //   r1 = ID,
      //   r2 = message length,
      //   r3 = message data address
      r1 = r0;
      r2 = M[($message.long_message_data + 1)];
      r3 = (&$message.long_message_data + 2);
      r0 = $message.LONG_MESSAGE_MODE_ID;
      jump message_mode_done;
#endif

   short_message_mode:
      // copy short message payload
      r1 = M[$message.DATA_TO_DSP + 0];
      r2 = M[$message.DATA_TO_DSP + 1];
      r3 = M[$message.DATA_TO_DSP + 2];
      r4 = M[$message.DATA_TO_DSP + 3];

   message_mode_done:
   // increment ack number so that mcu can send another interrupt
   r5 = M[$message.ACK_FROM_DSP];
   r5 = r5 + 1;
   M[$message.ACK_FROM_DSP] = r5;

   // now call the handler
   call rLink;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;







// *****************************************************************************
// MODULE:
//    $message.send_ready_wait_for_go
//
// DESCRIPTION:
//    Send the $MESSAGE_KALIMBA_READY message and wait for the
//    $MESSAGE_GO message
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r5, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.message.send_ready_wait_for_go;
   .CODESEGMENT MESSAGE_SEND_READY_WAIT_FOR_GO_PM;
   .DATASEGMENT DM;

   .VAR go_from_vm_message_struc[$message.STRUC_SIZE];
   .VAR go_from_vm = 0;

   $message.send_ready_wait_for_go:

   // push rLink onto stack
   $push_rLink_macro;

   // set up message handler for GO message
   r1 = &go_from_vm_message_struc;
   r2 = $MESSAGE_GO;
   r3 = &go_from_vm_handler;
   call $message.register_handler;
   jump go_from_vm_setup_done;
      // inline simple message handler
      go_from_vm_handler:
      r0 = 1;
      M[go_from_vm] = r0;
      rts;
   go_from_vm_setup_done:

   // send message saying we're up and running!
   r2 = Null OR $MESSAGE_KALIMBA_READY;
   call $message.send_short;

   // wait until GO message from the VM has been received;
   vm_go_wait:
      Null = M[go_from_vm];
   if Z jump vm_go_wait;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
