// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Revision$  $Date$
// *****************************************************************************

#ifndef PULSE_LED_INCLUDED
#define PULSE_LED_INCLUDED

#include "stack.h"
#include "timer.h"
#include "message.h"
#include "interrupt.h"
#include "kalimba_standard_messages.h"

// Using timer2 interrupts at a high priority for the LED pulsing gives less
// flicker at low intensity levels, we need nested_interrupt_support for this
// so that it can block other lower priority interrupts
#define PULSE_LED_USE_TIMER2


.MODULE $pulse_led;
   .CODESEGMENT PULSE_LED_PM;
   .DATASEGMENT DM;

   .VAR pio_mask;
   .VAR message_struc[$message.STRUC_SIZE];
   .VAR timer_struc[$timer.STRUC_SIZE];

   #ifdef PULSE_LED_USE_TIMER2
      .CONST PWM_PERIOD     12000;
      .CONST MIN_MARK_DELAY 100;
      .CONST MIN_STEP_SIZE  30;
   #else
      .CONST PWM_PERIOD     18000;
      .CONST MIN_MARK_DELAY 400;
      .CONST MIN_STEP_SIZE  100;
   #endif

   .VAR pulsing_period;
   .VAR count;
   .VAR step_size   = MIN_STEP_SIZE;
   .VAR mark_delay  = MIN_MARK_DELAY;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pulse_led.initialise
//
// DESCRIPTION:
//    Initialise the pulse_led library
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
// *****************************************************************************
.MODULE $M.pulse_led.initialise;
   .CODESEGMENT PULSE_LED_INITIIALISE_PM;
   .DATASEGMENT DM;

   $pulse_led.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // register the message handler for the VM to request for a pulsing led
   r1 = &$pulse_led.message_struc;
   r2 = $MESSAGE_PULSE_LED;
   r3 = &$pulse_led.message_handler;
   call $message.register_handler;

#ifdef PULSE_LED_USE_TIMER2
   // use just TIMER2 for the led so that fast interrupt handling (priority 2)
   r0 = $INT_SOURCE_TIMER2_EVENT;
   r1 = 2;
   r2 = &$pulse_led.service_routine;
   call $interrupt.register;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pulse_led.message_handler
//
// DESCRIPTION:
//    Message handler for the $MESSAGE_PULSE_LED message from the VM
//    1st message argument - PIO_MASK to use for pulsing LED
//    2nd message argument - pulsing period (units are approx 0.35secs,
//                           e.g. 4 equates to a 1.4sec pulsing period)
//
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r5, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.pulse_led.message_handler;
   .CODESEGMENT PULSE_LED_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

   $pulse_led.message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // Message content:
   //  1st argurment - PIO_MASK to use for the pulsing LED
   //  2nd argurment - pulsing period
   //  (units are approx 0.35secs, eg 4 equates to a 1.4sec pulsing period)

   // set PIO bits to 0 if the previous mask is set and the new mask is not
   r0 = M[$pulse_led.pio_mask];
   // invert the previous mask
   r0 = r0 XOR 0xFFFF;
   // OR with the new mask
   r0 = r0 OR r1;
   // AND with the current $PIO_OUT state
   r3 = M[$PIO_OUT];
   r0 = r0 AND r3;
   M[$PIO_OUT] = r0;

   // store the message information
   M[$pulse_led.pio_mask] = r1;
   M[$pulse_led.pulsing_period] = r2;

   call $pulse_led.service_routine;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $pulse_led.service_routine
//
// DESCRIPTION:
//    Routine driven by a timer event to PWM the LED so that the brightness
//    ramps up and down.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r5, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.pulse_led.service_routine;
   .CODESEGMENT PULSE_LED_SERVICE_ROUTINE_PM;
   .DATASEGMENT DM;

   $pulse_led.service_routine:

   // push rLink onto stack
   $push_rLink_macro;

   // if pio_mask = 0 then exit without setting a new timer event
   Null = M[$pulse_led.pio_mask];
   if Z jump $pop_rLink_and_rts;

   // only update the mark delay every pulsing_period times
   r0 = M[$pulse_led.count];
   r0 = r0 + 1;
   M[$pulse_led.count] = r0;
   Null = r0 - M[$pulse_led.pulsing_period];
   if NEG jump delay_update_done;
   M[$pulse_led.count] = Null;

   // update the mark_delay
   r1 = M[$pulse_led.mark_delay];
   r0 = M[$pulse_led.step_size];
   r1 = r1 + r0;
   Null = r1 - $pulse_led.MIN_MARK_DELAY;
   if LE jump at_min_delay;
   Null = r1 - $pulse_led.PWM_PERIOD;
   if GE jump at_max_delay;
   M[$pulse_led.mark_delay] = r1;

   // accomodate for brightness being logarithmic by tweaking the step_size amount
   r2 = r0;
   if NEG r2 = -r2;
   r2 = r2 ASHIFT -4;
   M[$pulse_led.step_size] = r0 + r2;
   jump delay_update_done;

   at_min_delay:
      // reset mark_delay and step_size for +ve ramping
      r0 = $pulse_led.MIN_STEP_SIZE;
      M[$pulse_led.step_size] = r0;
      r0 = $pulse_led.MIN_MARK_DELAY;
      M[$pulse_led.mark_delay] = r0;
      jump delay_update_done;

   at_max_delay:
      // just negate step_size for -ve ramping
      M[$pulse_led.step_size] = -r0;

   delay_update_done:

   // if led currently on then stop_delay = PWM_PERIOD - mark_delay
   r0 = $pulse_led.PWM_PERIOD;
   r1 = M[$PIO_OUT];
   r2 = M[$pulse_led.mark_delay];
   r3 = M[$pulse_led.pio_mask];
   Null = r1 AND r3;
   if NZ r2 = r0 - r2;

   // change state of the led
   r1 = r1 XOR r3;
   M[$PIO_OUT] = r1;


   // post another timer event with the chosen mark/space delay
#ifdef PULSE_LED_USE_TIMER2
   // if using TIMER2 set trigger time manually
   M[$TIMER2_EN] = Null;
   r2 = M[$TIMER_TIME] + r2;
   M[$TIMER2_TRIGGER] = r2;
   r0 = 1;
   M[$TIMER2_EN] = r0;
#else
   // else use standard timer library
   r1 = &$pulse_led.timer_struc;
   r3 = &$pulse_led.service_routine;
   call $timer.schedule_event_in;
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif