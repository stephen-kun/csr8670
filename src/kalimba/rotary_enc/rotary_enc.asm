// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Revision$  $Date$
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Rotary Encoder Library
//
// DESCRIPTION:
//    This library controls multiple rotary encoders. It recieves a message
//    from the VM per rotary encoder it is to use and stores this data in a
//    memory structure defined in the DSP code.
//    The library is interrupt driven, and the output is a message to the VM,
//    where the minimum period between messages is defined in the VM and sent
//    to the DSP along with other information, such as the PIO lines that the
//    rotary encoder is on.
//
//    The A line is defined as the line which goes high first when the encoder
//    rotates clockwise, similarly the B line goes high first when the encoder
//    rotates anticlockwise:
//
//    @verbatim
//       A       _________       _________
//       ________|       |_______|       |_______
//
//       B          _________       _________            Clockwise
//       ___________|       |_______|       |____
//
//
//
//
//       A          _________       _________
//       ___________|       |_______|       |____
//
//       B       _________       _________               Anticlockwise
//       ________|       |_______|       |_______
//    @endverbatim
//
//
//    Each rotary encoder requires an allocation of memory in the DSP code of
//    size $rotary_enc.STRUC_SIZE. A rotary encoder is initialised from the
//    VM with a message:
//
//       KalimbaSendMessage(KALIMBA_MSG_ROTARY_ENCODER_CONFIGURE,
//                          uint16 PIO_bitmask_A,
//                          uint16 PIO_bitmask_B,
//                          uint16 min_period_and_max_bounce_period,
//                          uint16 message_response_id)
//
//     - PIO_bitmask_A is a bitmask for line A of the rotary encoder
//
//     - PIO_bitmask_B is a bitmask for line B of the rotary encoder
//
//     - min_period_and_max_bounce_period is split into 2 bytes.
//        - Bits 15:8 set the interval (in 10's of ms) to wait between
//          messages to the VM
//        - Bits 7:0 sets the maximum bounce period (in 100's of us) to be
//          sure to miss any bounce
//
//     - message_response_id, the message ID to be used by the DSP to pass
//                            messages back to the VM about rotation
//
//
//    The messages sent from the DSP to the VM has the following contents
//
//       word 0 - The total rotation recorded in the interval. This is a signed
//              integer, positive for clockwise, negative for anticlockwise,
//              of magnitude proportional to distance rotated. If the encoder
//              rotated at high speed some rotation data is dropped to prevent
//              overloading the timer structures in the DSP
//
//       word 1 - The encoder number. This number is allocated on registration
//              of the encoder, and enumerates the encoders in the order
//              that they were registered
//
// *****************************************************************************


#ifndef ROTARY_ENCODER_INCLUDED
#define ROTARY_ENCODER_INCLUDED

#include "stack.h"
#include "message.h"
#include "timer.h"
#include "kalimba_standard_messages.h"
#include "rotary_enc.h"
#include "pio.h"

.MODULE $rotary_enc;
   .CODESEGMENT ROTARY_ENC_PM;
   .DATASEGMENT DM;

   .VAR $message_struc[$message.STRUC_SIZE];
   .VAR/DM1 last_addr = $rotary_enc.LAST_ENTRY;

   #ifdef ROTARY_ENC_DEBUG_ON
      .VAR debug_count;
   #endif

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.initialise
//
// DESCRIPTION:
//    Initialise the rotary encoder library
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
// *****************************************************************************
.MODULE $M.rotary_enc.initialise;
   .CODESEGMENT ROTARY_ENC_INITIALISE_PM;
   .DATASEGMENT DM;

   $rotary_enc.initialise:

   //push rLink onto stack
   $push_rLink_macro;

   // register a message handler to receive messages about the rotary encoder(s)
   // from the VM
   r1 = &$message_struc;
   r2 = $MESSAGE_ROTARY_ENCODER_CONFIGURE;
   r3 = &$rotary_enc.message_handler;
   call $message.register_handler;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.register
//
// DESCRIPTION:
//    Register the memory structure of a rotary encoder and initialise it.
//
// INPUTS:
//    - r0 = pointer to a rotary_enc structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// NOTES:
//    All memory structures should be registered before the
// $message.send_ready_wait_for_go routine is called.
//
// *****************************************************************************
.MODULE $M.rotary_enc.register;
   .CODESEGMENT ROTARY_ENC_REGISTER_PM;
   .DATASEGMENT DM;

   $rotary_enc.register:

   r1 = M[$rotary_enc.last_addr];
   M[r0 + $rotary_enc.NEXT_ADDR_FIELD] = r1;
   M[$rotary_enc.last_addr] = r0;
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.message_handler
//
// DESCRIPTION:
//    Extracts the details (from the VM message) about the rotary encoder.
//
// INPUTS:
//    - r0 = Message ID of message from VM
//    - r1 = PIO mask
//    - r2 = min period
//    - r3 = max bounce
//    - r4 = msg return ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    All (ISR will restore)
// *****************************************************************************
.MODULE $M.rotary_enc.message_handler;
   .CODESEGMENT ROTARY_ENC_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

   $rotary_enc.message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   #ifdef ROTARY_ENC_DEBUG_ON
      r0 = $rotary_enc.MAX_HANDLERS;
      M[$rotary_enc.debug_count] = r0;
   #endif

   r5 = M[$rotary_enc.last_addr];

   // accumulate encoder number in r6
   r6 = 0;

   find_free_structure_loop:
      #ifdef ROTARY_ENC_DEBUG_ON
         // have we been round too many times? - corrupt linked list
         r0 = M[$rotary_enc.debug_count];
         r0 = r0 - 1;
         if NEG call $error;
         M[$rotary_enc.debug_count] = r0;
      #endif

      Null = r5 - $rotary_enc.LAST_ENTRY;
      #ifdef ROTARY_ENC_DEBUG_ON
         // too many VM messages, not enough rotary encoders have been
         // registered in the DSP
         if Z call $error;
      #else
         // silently ignore the message if in non-debug mode
         if Z jump $pop_rLink_and_rts;
      #endif

      // find an unassigned rotary encoder struture to use
      Null = M[r5 + $rotary_enc.ENCODER_NUMBER_FIELD];
      if Z jump free_structure_found;

      r6 = M[r5 + $rotary_enc.ENCODER_NUMBER_FIELD];

      // read the address of the next rotary encoder memory block
      r5 = M[r5 + $rotary_enc.NEXT_ADDR_FIELD];
   jump find_free_structure_loop;


   free_structure_found:

   // store the PIO masks from the message payload
   // encoder line A
   M[r5 + $rotary_enc.PIO_ENC_A_FIELD] = r1;
   M[r5 + $rotary_enc.PIO_ENC_B_FIELD] = r2;

   // store the message reply ID
   M[r5 + $rotary_enc.MSG_RETURN_ID_FIELD] = r4;

   // Extract bits 15:8 as the min_period (10's of ms)
   // Extract bits 7:0 as the max_bounce (100's of us)
   r0 = r3 AND 255;
   r3 = r3 LSHIFT -8;
   r3 = r3 AND 255;

   // store the minimum period between messages in us
   r3 = r3 * 10000 (int);
   M[r5 + $rotary_enc.MIN_PERIOD_FIELD] = r3;

   // store the maximum duration of bounce for the rotary encoder in us
   r0 = r0 * 100 (int);
   M[r5 + $rotary_enc.MAX_BOUNCE_US_FIELD] = r0;

   // store new encoder number
   r6 = r6 + 1;
   M[r5 + $rotary_enc.ENCODER_NUMBER_FIELD] = r6;


   // set up pio interrupt handler for the A and B rotary encoder lines
   r0 = r5 + $rotary_enc.PIO_STRUC_FIELD;
   r1 = r1 + r2;
   r2 = &$rotary_enc.service_routine;
   call $pio.register_handler;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.service_routine
//
// DESCRIPTION:
//    Responds to a PIO event by waiting for a debounce duration before
//    sampling the PIOs
//
// INPUTS:
//    - none (interrupt driven by the PIO handler)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r5, r10, DoLoop (ISR will restore)
// *****************************************************************************
.MODULE $M.rotary_enc.service_routine;
   .CODESEGMENT ROTARY_ENC_SERVICE_ROUTINE_PM;
   .DATASEGMENT DM;

   $rotary_enc.service_routine:

   // push rLink onto stack
   $push_rLink_macro;

   #ifdef OPTIONAL_FAST_INTERRUPT_SUPPORT
      .ERROR "The rotary_enc library doesn't support the OPTIONAL_FAST_INTERRUPT_SUPPORT mode yet!"
   #endif

   // r3 = rotary_enc structure (for which the PIOs have changed)
   // r1 has been set by the pio handler to point to the pio structure
   r3 = r1 - $rotary_enc.PIO_STRUC_FIELD;

   // cancel any current timers using the debounce timer structure
   r2 = M[r3 + ($rotary_enc.DEBOUCE_TIMER_STRUC_FIELD + $timer.ID_FIELD)];
   call $timer.cancel_event;

   // fire a timer in 'MAX_BOUNCE_US' time
   r1 = r3 + $rotary_enc.DEBOUCE_TIMER_STRUC_FIELD;
   r2 = M[r3 + $rotary_enc.MAX_BOUNCE_US_FIELD];
   r3 = &$rotary_enc.sample_pios;
   call $timer.schedule_event_in;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.sample_pios
//
// DESCRIPTION:
//    Sample $PIO_IN and log direction of the respective encoder
//
// INPUTS:
//    - none (interrupt driven by the timer handler)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume all (ISR will restore)
// *****************************************************************************
.MODULE $M.rotary_enc.sample_pios;
   .CODESEGMENT ROTARY_ENC_SAMPLE_PIOS_PM;
   .DATASEGMENT DM;

   $rotary_enc.sample_pios:

   // push rLink onto stack
   $push_rLink_macro;

   // r5 = rotary_enc structure (for which the PIOs have changed)
   // r1 has been set by the timer handler to point to the debounce timer
   // structure
   r5 = r1 - $rotary_enc.DEBOUCE_TIMER_STRUC_FIELD;

   // sample the $PIO_IN buffer
   r0 = M[$PIO_IN];

   r1 = M[r5 + $rotary_enc.PIO_ENC_A_FIELD];
   r2 = M[r5 + $rotary_enc.PIO_ENC_B_FIELD];

   Null = M[r5 + $rotary_enc.SIGNAL_FLAG_FIELD];
   if NZ jump second_sample;

      // set r3 = 1 if 'encoder A line' is high - clockwise
      r3 = 1;
      Null = r0 AND r1;
      if Z r3 = 0;

      // set r3 = -1 if 'encoder B line' is high - anticlockwise
      r4 = -1;
      Null = r0 AND r2;
      if NZ r3 = r4;

      M[r5 + $rotary_enc.ROTATION_FIELD] = r3;

      // set signal_flag to a non zero value
      M[r5 + $rotary_enc.SIGNAL_FLAG_FIELD] = r3;

      // pop rLink from stack
      jump $pop_rLink_and_rts;


   second_sample:
      M[r5 + $rotary_enc.SIGNAL_FLAG_FIELD] = Null;
      r1 = r1 + r2;   // r1 = combined PIO mask
      r0 = r0 AND r1;
      Null = r0 - r1;
      if Z jump $rotary_enc.try_to_send_message;

      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.try_to_send_message
//
// DESCRIPTION:
//    Add most recent rotation to the message that will be sent to the VM, and
//    schedule the sending event to occur at a maximum of every minimum period
//    (this value in ms is sent by the VM in the information message)
//    Send the first pulse, and then set a flag on a timer.  When the
//    timer expires its time to send rotation information accumulated in this
//    time.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Any (ISR will restore)
// *****************************************************************************
.MODULE $M.rotary_enc.try_to_send_message;
   .CODESEGMENT ROTARY_ENC_TRY_TO_SEND_MESSAGE_PM;
   .DATASEGMENT DM;

   $rotary_enc.try_to_send_message:

   // increment/decrement the total rotation
   r0 = M[r5 + $rotary_enc.TOTAL_ROTATION_IN_INTERVAL_FIELD];
   r1 = M[r5 + $rotary_enc.ROTATION_FIELD];
   r0 = r0 + r1;
   M[r5 + $rotary_enc.TOTAL_ROTATION_IN_INTERVAL_FIELD] = r0;
   if Z jump $pop_rLink_and_rts;

   // if send flag set then exit - wait until unlocked
   Null = M[r5 + $rotary_enc.SEND_FLAG_FIELD];
   if NZ jump $pop_rLink_and_rts;

   // set send flag
   r0 = 1;
   M[r5 + $rotary_enc.SEND_FLAG_FIELD] = r0;

   // send first rotation immediately and after the timer comes back send the rest
   r2 = M[r5 + $rotary_enc.MSG_RETURN_ID_FIELD];
   r3 = M[r5 + $rotary_enc.TOTAL_ROTATION_IN_INTERVAL_FIELD];
   r4 = M[r5 + $rotary_enc.ENCODER_NUMBER_FIELD];
   call $message.send;
   M[r5 + $rotary_enc.TOTAL_ROTATION_IN_INTERVAL_FIELD] = Null;

   r1 = r5 + $rotary_enc.MSG_TIMER_STRUC_FIELD;
   r2 = M[r5 + $rotary_enc.MIN_PERIOD_FIELD];
   r3 = &$rotary_enc.unlock_send_message;
   call $timer.schedule_event_in;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $rotary_enc.send_message_vm
//
// DESCRIPTION:
//    Lower the barrier-to-send flag
//
// INPUTS:
//    - none (interrupt driven by the timer handler)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Any (ISR will restore)
// *****************************************************************************
.MODULE $M.rotary_enc.unlock_send_flag;
   .CODESEGMENT ROTARY_ENC_UNLOCK_SEND_FLAG_PM;
   .DATASEGMENT DM;

   $rotary_enc.unlock_send_message:

   // push rLink onto stack
   $push_rLink_macro;

   // r5 = rotary_enc structure (for which the PIOs have changed)
   // r1 has been set by the timer handler to point to the debounce timer
   // structure
   r5 = r1 - $rotary_enc.MSG_TIMER_STRUC_FIELD;

   M[r5 + $rotary_enc.ROTATION_FIELD] = Null;
   M[r5 + $rotary_enc.SEND_FLAG_FIELD] = Null;

   jump $rotary_enc.try_to_send_message;

.ENDMODULE;

#endif
