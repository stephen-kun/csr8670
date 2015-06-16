// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Timer Library
//
// DESCRIPTION:
//    There are 2 hardware timers attached to the Kalimba DSP that can
//    trigger interrupts.  Often, more than two timer driven events are
//    required and this library provides software supported timer events.
//
//    The library provides support for subroutines to be executed at some
//    point in the future.  Times are specified in microseconds either
//    relative to the current time or at a particular absolute time based
//    on the value of $TIMER_TIME. $TIMER_TIME is a memory mapped register
//    that may always be read and automatically increments every microsecond
//
//    Each event submitted to the library is identified using a unique ID,
//    this is passed to the subroutine when it is triggered. An event may also
//    be cancelled by calling $timer.cancel_event with the event ID. Note
//    that if, when cancelled, the subroutine was the next to trigger, the
//    interrupt still occurs but the subroutine is not called.
//
// *****************************************************************************

#ifndef TIMER_INCLUDED
#define TIMER_INCLUDED

#ifdef DEBUG_ON
   #ifndef TIMER_PROFILER_ON
      #define TIMER_PROFILER_ON
   #endif
   #ifndef TIMER_CHECK_ZERO_IF_FIELD
      #define TIMER_CHECK_ZERO_IF_FIELD
   #endif
#endif

#include "timer.h"
#include "stack.h"
#include "profiler.h"
#include "architecture.h"


.MODULE $timer;
   .DATASEGMENT DM;

   .VAR     id = 1;
   .VAR     last_addr = $timer.LAST_ENTRY;

   .CONST   MAX_CLK_DIV_RATE       ($CLK_DIV_MAX < $CLK_DIV_1024) ? $CLK_DIV_MAX : $CLK_DIV_1024;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $timer.schedule_event_at
//
// DESCRIPTION:
//    Schedule a timed event to occur at a particular absolute $TIMER_TIME value.
//    When the event occurs a selected handler function will be called.
//
// INPUTS:
//    - r1 = pointer to a variable that stores the timer handler structure,
//           should be of length $timer.STRUC_SIZE
//    - r2 = $TIMER_TIME value (in us) at which to trigger an event
//    - r3 = timer handler program address for this event;
//
// OUTPUTS:
//    - r3 = an ID that can be used to cancel the timer event
//
// TRASHED REGISTERS:
//    r0, r1, r3, r4, r5, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.timer.schedule_event_at;
   .CODESEGMENT TIMER_SCHEDULE_EVENT_AT_PM;

   $timer.schedule_event_at:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   #ifdef TIMER_CHECK_ZERO_IF_FIELD
      // check this handler isn't currently being used
      Null = M[r1 + $timer.ID_FIELD];
      if NZ call $error;
   #endif

   // search through the timer linked list to find where to insert this new
   // timer event
   r10 = $timer.MAX_TIMER_HANDLERS;
   r4 = (&$timer.last_addr - $timer.NEXT_ADDR_FIELD);
   r0 = M[$timer.last_addr];
   do loop;
      // if we're at the last structure in the linked list then this timer
      // will be the last one to fire
      Null = r0 - $timer.LAST_ENTRY;
      if Z jump insert_here;

      // if new trigger time < this entry's trigger time then add timer here
      r5 = M[r0 + $timer.TIME_FIELD];
      Null = r2 - r5;
      if NEG jump insert_here;

      // set r4 = previous timer structure
      r4 = r0;
      // read the adddress of the next timer structure
      r0 = M[r0 + $timer.NEXT_ADDR_FIELD];
   loop:

   // something's gone wrong - either too many handlers,
   // or more likely the linked list has got corrupt.
   call $error;

   insert_here:
   // insert the new timer structure into the linked list
   // previous structure -> new structure
   M[r4 + $timer.NEXT_ADDR_FIELD] = r1;
   // new structure -> next structure
   M[r1 + $timer.NEXT_ADDR_FIELD] = r0;

   // store new entry
   M[r1 + $timer.TIME_FIELD] = r2;
   M[r1 + $timer.HANDLER_ADDR_FIELD] = r3;
   r3 = M[$timer.id];
   M[r1 + $timer.ID_FIELD] = r3;

   //increment $timer.id for next time
   r0 = r3 + 1;
   // if zero set it to 1
   if Z r0 = -r3;
   M[$timer.id] = r0;

   // find the next timer event to set the hardware timer to trigger at
   Null = M[$TIMER1_EN];
   if Z jump no_current_timer_set;

      Null = r2 - M[$TIMER1_TRIGGER];
      if POS jump done;       // new event isn't the next so exit

   no_current_timer_set:

      // new event is the next event so update timer trigger value
      M[$TIMER1_TRIGGER] = r2;

      // enable the timer
      r0 = 1;
      M[$TIMER1_EN] = r0;

   done:

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $timer.schedule_event_in
//
// DESCRIPTION:
//    Schedule a timed event to occur at a particular relative time from the
//    current value of $TIMER_TIME.  When the event occurs a selected handler
//    function will be called.
//
// INPUTS:
//    - r1 = pointer to a variable that stores the timer handler structure,
//           should be of length $timer.STRUC_SIZE
//    - r2 = a relative $TIMER_TIME value (in us) at which to trigger an event
//    - r3 = timer handler program address for this event;
//
// OUTPUTS:
//    - r3 = an ID that can be used to cancel the timer event
//
// TRASHED REGISTERS:
//    r0, r1, r3, r4, r5, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.timer.schedule_event_in;
   .CODESEGMENT TIMER_SCHEDULE_EVENT_IN_PM;

   $timer.schedule_event_in:

   r2 = r2 + M[$TIMER_TIME];
   jump $timer.schedule_event_at;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $timer.schedule_event_in_period
//
// DESCRIPTION:
//    Schedule a timed event to occur at a time relative to the time that this
//    timer previously occured.  When the event occurs a selected handler
//    function will be called.
//
// INPUTS:
//    - r1 = pointer to a variable that stores the timer handler structure,
//           should be of length $timer.STRUC_SIZE
//    - r2 = a relative $TIMER_TIME value (in us) at which to trigger an event
//    - r3 = timer handler program address for this event;
//
// OUTPUTS:
//    - r3 = an ID that can be used to cancel the timer event
//
// TRASHED REGISTERS:
//    r0, r1, r3, r4, r5, r10, DoLoop
//
// NOTES:
//    This routine should only be called passing a timer structure that has been
// used previously - eg. by a previous call to $timer.schedule_event_in.  This
// is because it bases the new time to set the timer to trigger at based on the
// previous time the timer was set for.
//
// *****************************************************************************

.MODULE $M.timer.schedule_event_in_period;
   .CODESEGMENT TIMER_SCHEDULE_EVENT_IN_PERIOD_PM;

   $timer.schedule_event_in_period:

   r0 = M[r1 + $timer.TIME_FIELD];
   r2 = r2 + r0;
   jump $timer.schedule_event_at;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $timer.cancel_event
//
// DESCRIPTION:
//    Cancel all scheduled timer events with the selected ID
//
// INPUTS:
//    - r2 = ID of the event that needs to be canceled
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r4, r5, r10, DoLoop
//
// NOTES:
//    If the ID couldn't be found then the routine exits without error
//
// *****************************************************************************
.MODULE $M.timer.cancel_event;
   .CODESEGMENT TIMER_CANCEL_EVENT_PM;

   $timer.cancel_event:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // search through the timer linked list to find the ID to cancel
   r10 = $timer.MAX_TIMER_HANDLERS;
   r4 = (&$timer.last_addr - $timer.NEXT_ADDR_FIELD);
   r0 = M[$timer.last_addr];
   do loop;
      // if we're at the last structure in the linked list then the ID hasn't
      // been found
      Null = r0 - $timer.LAST_ENTRY;
      if Z jump not_found;

      // if ID's match then delete entry from linked list
      r5 = M[r0 + $timer.ID_FIELD];
      Null = r2 - r5;
      if Z jump delete_this_entry;

      // set r4 = previous timer structure
      r4 = r0;
      // read the adddress of the next timer structure
      r0 = M[r0 + $timer.NEXT_ADDR_FIELD];
   loop:

   not_found:
   // If ID wasn't found, lets assume it occured before they cancelled it
   // or that it just didn't exist hence we just return
   jump done;

   delete_this_entry:

      // delete the timer structure from the linked list
      // previous structure -> this structure's next addr field
      r1 = M[r0 + $timer.NEXT_ADDR_FIELD];
      M[r4 + $timer.NEXT_ADDR_FIELD] = r1;
      M[r0 + $timer.ID_FIELD] = Null;

   done:

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $timer.service_routine
//
// DESCRIPTION:
//    Service the timer interrupt - call the appropriate handler functions for
//    timer events that should occur now and set the hardware timer interrupt
//    for any further timer events that should occur in the future.
//
// INPUTS:
//    - provided by interrupt service routine
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTES:
//    The handler function is passed:
//       - r0 = the event ID
//       - r1 = address of the timer structure
//
//    It can trash, without saving, any register
//
// *****************************************************************************
.MODULE $M.timer.service_routine;
   .CODESEGMENT TIMER_SERVICE_ROUTINE_PM;

   $timer.service_routine:

   // push rLink onto stack
   $push_rLink_macro;


   search_again:
      // if the linked list is empty then we're all done
      r1 = M[$timer.last_addr];
      Null = r1 - $timer.LAST_ENTRY;
      if Z jump no_more_timers;

      // see if the first timer in the list should be called now
      r0 = M[r1 + $timer.TIME_FIELD];
      r2 = r0 - M[$TIMER_TIME];
      Null = r2 - 0;
      if GT jump setup_a_new_hardware_timer;
      rLink = M[r1 + $timer.HANDLER_ADDR_FIELD];
      r0 = M[r1 + $timer.ID_FIELD];
      // now zero its ID
      M[r1 + $timer.ID_FIELD] = Null;
      // before calling the handler - remove the structure from the linked list
      r2 = M[r1 + $timer.NEXT_ADDR_FIELD];
      M[$timer.last_addr] = r2;
      call rLink;

      // loop until we've processed all current timers
   jump search_again;

   setup_a_new_hardware_timer:

      // disable the timer
      M[$TIMER1_EN] = Null;
      // set a new timer trigger value for the next timer
      M[$TIMER1_TRIGGER] = r0;
      // re-enable the timer enable
      r3 = 1;
      M[$TIMER1_EN] = r3;
      // pop rLink from stack
      jump $pop_rLink_and_rts;

   no_more_timers:

      // disable the timer
      M[$TIMER1_EN] = Null;
      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $timer.1ms_delay
//
// DESCRIPTION:
//    Cause a delay of 1ms (uses a slow clock to save power, but interrupts can
// still occur)
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, (r2 if profiling)
//
// NOTES:
//    To save power this routine should be called whenever your main routine
// has no work to do (eg. buffers don't need servicing yet for more data).
//
//    If profiling is enabled this routine can be used to estimate the amount of
// CPU power required for your program. This is achieved by structuring your
// program such that any spare processing time is consumed by this routine. See
// the Matlab function kalprofilers for more information.
//
// *****************************************************************************
.MODULE $M.timer.1ms_delay;
   .CODESEGMENT TIMER_1MS_DELAY_PM;
   .DATASEGMENT DM;

   $timer.1ms_delay:

   // -- Start profiling if enabled --
   #ifdef TIMER_PROFILER_ON
      // push rLink onto stack
      $push_rLink_macro;
      .VAR/DM1 $profiler.1ms_delay[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      r0 = &$profiler.1ms_delay;
      call $profiler.start;
   #endif

   // save current clock rate
   r1 = M[$CLOCK_DIVIDE_RATE];

   // go to slowest clock and wait 1ms
   r0 = $timer.MAX_CLK_DIV_RATE;
   M[$CLOCK_DIVIDE_RATE] = r0;

   r0 = M[$TIMER_TIME];
   r0 = r0 + 999;
   wait:
      Null = r0 - M[$TIMER_TIME];
   if POS jump wait;

   // restore clock rate
   M[$CLOCK_DIVIDE_RATE] = r1;

   // -- Stop profiling if enabled --
   #ifdef TIMER_PROFILER_ON
      r0 = &$profiler.1ms_delay;
      call $profiler.stop;
      // pop rLink from stack
      jump $pop_rLink_and_rts;
   #endif
   #ifndef PROFILER_ON
      rts;
   #endif

.ENDMODULE;






// *****************************************************************************
// MODULE:
//    $timer.n_ms_delay
//
// DESCRIPTION:
//    Cause a delay of n ms (uses a slow clock to save power, but interrupts can
// still occur)
//
// INPUTS:
//    - r0 - duration of delay in miliseconds
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, rMAC
//
// NOTES:
//    To save power this routine uses a slower clock rate, running at 62.5 kHz
// for the duration of the delay.
//
//    If profiling is enabled this routine can be used to estimate the amount of
// CPU power required for your program. This is achieved by structuring your
// program such that any spare processing time is consumed by this routine. See
// the Matlab function kalprofilers for more information.
//
// *****************************************************************************
.MODULE $M.timer.n_ms_delay;
   .CODESEGMENT TIMER_N_MS_DELAY_PM;
   .DATASEGMENT DM;

   $timer.n_ms_delay:

   // value is in ms, convert to MS and LS in us
   rMAC = r0 * 500 (uu);

      // -- Start profiling if enabled --
   #ifdef TIMER_PROFILER_ON
      // push rLink onto stack
      $push_rLink_macro;
      .VAR/DM1 $profiler.n_ms_delay[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      r0 = &$profiler.n_ms_delay;
      call $profiler.start;
   #endif

   // save current clock rate
   r2 = M[$CLOCK_DIVIDE_RATE];

   // retrieve the MS and LS words
   r1 = rMAC1;
   r0 = rMAC0;

   // work out the end time
   r0 = r0 + M[$TIMER_TIME];

   // subtract off the amount of time it takes to 'wake up'
   r0 = r0 - 140;

   // drop the clock rate
   rMAC = $timer.MAX_CLK_DIV_RATE;
   M[$CLOCK_DIVIDE_RATE] = rMAC;

   outer_waiting_loop:

      negative_waiting_loop:
         Null = r0 - M[$TIMER_TIME];
      if NEG jump negative_waiting_loop;

      positive_waiting_loop:
         Null = r0 - M[$TIMER_TIME];
      if POS jump positive_waiting_loop;

      r1 = r1 - 1;
   if POS jump outer_waiting_loop;

   // restore the clock and exit
   M[$CLOCK_DIVIDE_RATE] = r2;

   // -- Stop profiling if enabled --
   #ifdef TIMER_PROFILER_ON
      r0 = &$profiler.n_ms_delay;
      call $profiler.stop;
      // pop rLink from stack
      jump $pop_rLink_and_rts;
   #else
      rts;
   #endif

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $timer.n_us_delay
//
// DESCRIPTION:
//    Cause a delay of n us (uses a slow clock to save power, but interrupts can
// still occur)
//
// INPUTS:
//    - r0 = delay in microseconds
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3
//
// NOTES:
//    To save power this routine uses slower clock rates. If a large delay is
// requested a 62.5kHz clock is used, stepping up to 1 MHz clock and finally
// runnnig at full speed to ensure an accurate result is achieved.
//
//    The longest delay supported is 4 s, if a longer delay is required use
// $timer.n_ms_delay
//
//    If profiling is enabled this routine can be used to estimate the amount of
// CPU power required for your program. This is achieved by structuring your
// program such that any spare processing time is consumed by this routine. See
// the Matlab function kalprofilers for more information.
//
// *****************************************************************************
.MODULE $M.timer.n_us_delay;
   .CODESEGMENT TIMER_N_US_DELAY_PM;
   .DATASEGMENT DM;

   $timer.n_us_delay:

   // work out when we want to stop
   r2 = r0 + M[$TIMER_TIME];
   r2 = r2 - 1;

      // -- Start profiling if enabled --
   #ifdef TIMER_PROFILER_ON
      // push rLink onto stack
      r3 = r0;
      $push_rLink_macro;
      .VAR/DM1 $profiler.n_us_delay[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      r0 = &$profiler.n_us_delay;
      call $profiler.start;
      r0 = r3;
   #endif

   // preserve the current sample rate
   r1 = M[$CLOCK_DIVIDE_RATE];

   // work out how large a delay we have been asked for
   Null = r0 - $timer.n_us_delay.SHORT_DELAY;
   if NEG jump full_rate;

   Null = r0 - $timer.n_us_delay.MEDIUM_DELAY;
   if NEG jump medium_rate;

   slow_rate:

      // drop the clock rate
      r3 = $timer.MAX_CLK_DIV_RATE;
      M[$CLOCK_DIVIDE_RATE] = r3;

      // work out when we want to switch up to the faster clock
      r0 = r2 - $timer.n_us_delay.MEDIUM_DELAY;

      slow_waiting_loop:
         Null = r0 - M[$TIMER_TIME];
      if POS jump slow_waiting_loop;

   medium_rate:

      // medium clock rate
      r3 = $CLK_DIV_64;
      M[$CLOCK_DIVIDE_RATE] = r3;

      r0 = r2 - $timer.n_us_delay.SHORT_DELAY;

      medium_waiting_loop:
         Null = r0 - M[$TIMER_TIME];
      if POS jump medium_waiting_loop;

   full_rate:

      // full rate
      M[$CLOCK_DIVIDE_RATE] = Null;

      full_rate_waiting_loop:
         Null = r2 - M[$TIMER_TIME];
      if POS jump full_rate_waiting_loop;

   done:

   // restore the clock rate and exit
   M[$CLOCK_DIVIDE_RATE] = r1;

   // -- Stop profiling if enabled --
   #ifdef TIMER_PROFILER_ON
      r0 = &$profiler.n_us_delay;
      call $profiler.stop;
      // pop rLink from stack
      jump $pop_rLink_and_rts;
   #else
      rts;
   #endif

.ENDMODULE;


#endif



