// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    CPU usage Profiler
//
// DESCRIPTION:
//    This library contains functions to calculate the percentage of cpu
//    time that particular parts of an application are using.
//
//    A five word variable is used by the profiler to maintain book keeping
//    information. When registering an section of code for profiling, a pointer
//    is passed to $profiler.register of this variable.  Alternatively if the
//    variable has it's first location initialised to $profiler.UNINITIALISED
//    then you don't need to call $profiler.register.
//
//    To then profile an area of code, it should be surrounded by calls to
//    $profiler.start and $profiler.stop. Since these subroutines consume
//    some processing power, profiling of code that is commonly called but
//    quick to execute may give inaccurate results.
//
//    The profiling information is updated once a second and a value between
//    zero and one thousand stored in your_var[$profiler.CPU_FRACTION_FIELD].
//    One thousand equates to 100% cpu usage.
//
// *****************************************************************************

#ifndef PROFILER_INCLUDED
#define PROFILER_INCLUDED

#include "stack.h"
#include "interrupt.h"
#include "profiler.h"
#include "timer.h"

.MODULE $profiler;
   .DATASEGMENT DM;

   .VAR/DM1 last_addr = $profiler.LAST_ENTRY;
   .VAR     timer_struc[$timer.STRUC_SIZE];
   #ifdef DETAILED_PROFILER_ON
      .VAR temp_clks_ls;
      .VAR temp_clks_ms;
      .VAR temp_instrs_ls;
      .VAR temp_instrs_ms;
   #endif

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $profiler.initialise
//
// DESCRIPTION:
//    Initialise the profiler library
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
// NOTES:
//    Should be called before the timer library has been initialised.
//
// *****************************************************************************
.MODULE $M.profiler.initialise;
   .CODESEGMENT PROFILER_INITIALISE_PM;

   $profiler.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // initialise profiler timer handler for servicing profiler in 1.024secs
   r1 = &$profiler.timer_struc;
   r2 = 1024000;
   r3 = &$profiler.timer_service_routine;
   call $timer.schedule_event_in;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $profiler.register
//
// DESCRIPTION:
//    Register a routine to be profiled
//
// INPUTS:
//    - r0 = pointer to a variable that stores the profiling structure,
//         should be of length $profiler.STRUC_SIZE
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r1
//
// *****************************************************************************
.MODULE $M.profiler.register;
   .CODESEGMENT PROFILER_REGISTER_PM;

   $profiler.register:

   // set next profiler address to the previous last_addr
   r1 = M[$profiler.last_addr];
   M[r0 + $profiler.NEXT_ADDR_FIELD] = r1;
   // set new last_addr to the address of this profiler structure
   M[$profiler.last_addr] = r0;

   // clear TotalTime, and CPU_Faction fields
   M[r0 + $profiler.TOTAL_TIME_FIELD] = Null;
   M[r0 + $profiler.CPU_FRACTION_FIELD] = Null;

   #ifdef DETAILED_PROFILER_ON
      M[r0 + $profiler.RUN_CLKS_MS_TOTAL_FIELD] = Null;
      M[r0 + $profiler.RUN_CLKS_LS_TOTAL_FIELD] = Null;
      M[r0 + $profiler.RUN_CLKS_AVERAGE_FIELD] = Null;
      M[r0 + $profiler.RUN_CLKS_MS_MAX_FIELD] = Null;
      M[r0 + $profiler.RUN_CLKS_LS_MAX_FIELD] = Null;
      M[r0 + $profiler.INSTRS_MS_TOTAL_FIELD] = Null;
      M[r0 + $profiler.INSTRS_LS_TOTAL_FIELD] = Null;
      M[r0 + $profiler.INSTRS_AVERAGE_FIELD] = Null;
      M[r0 + $profiler.INSTRS_MS_MAX_FIELD] = Null;
      M[r0 + $profiler.INSTRS_LS_MAX_FIELD] = Null;
      M[r0 + $profiler.STALLS_MS_TOTAL_FIELD] = Null;
      M[r0 + $profiler.STALLS_LS_TOTAL_FIELD] = Null;
      M[r0 + $profiler.STALLS_AVERAGE_FIELD] = Null;
      M[r0 + $profiler.STALLS_MS_MAX_FIELD] = Null;
      M[r0 + $profiler.STALLS_LS_MAX_FIELD] = Null;
   #endif

   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $profiler.start
//
// DESCRIPTION:
//    Start profiling of a particular routine
//
// INPUTS:
//    - r0 = address of structure to use for profiling
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r1
//
// *****************************************************************************
.MODULE $M.profiler.start;
   .CODESEGMENT PROFILER_START_PM;

   $profiler.start:

   r1 = M[r0 + $profiler.NEXT_ADDR_FIELD];
   Null = r1 - $profiler.UNINITIALISED;
   if NZ jump already_initialised;
      // the profiler is uninitialised so we'll automatically register it
      // push rLink onto stack
      $push_rLink_macro;
      call $profiler.register;
      $pop_rLink_macro;
   already_initialised:

   r1 = M[$TIMER_TIME];
   M[r0 + $profiler.START_TIME_FIELD] = r1;

   #ifdef INTERRUPT_PROFILER_ON
      r1 = M[$interrupt.total_time];
      M[r0 + $profiler.INT_START_TIME_FIELD] = r1;
   #endif

   #ifdef DETAILED_PROFILER_ON
   #ifdef INTERRUPT_PROFILER_ON
      push r2;
      push r3;
      r1 = r0;
      $block_interrupts_macro;
      r0 = M[r1 + $profiler.TEMP_COUNT_FIELD];
      r0 = r0 + 1;
      M[r1 + $profiler.TEMP_COUNT_FIELD] = r0;
      r0 = M[$NUM_RUN_CLKS_MS];
      r2 = M[$NUM_RUN_CLKS_LS];
      r3 = M[$NUM_RUN_CLKS_MS];
      r2 = M[$NUM_RUN_CLKS_LS];
      r2 = r2 - 2;
      r3 = r3 - Borrow;
      Null = r3 - r0;
      if LT r3 = r0;
      M[r1 + $profiler.RUN_CLKS_MS_START_FIELD] = r3;
      M[r1 + $profiler.RUN_CLKS_LS_START_FIELD] = r2;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$interrupt.total_clocks_ms];
      M[r1 + $profiler.INT_START_CLKS_MS_FIELD] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$interrupt.total_clocks_ls];
      M[r1 + $profiler.INT_START_CLKS_LS_FIELD] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$NUM_INSTRS_MS];
      r2 = M[$NUM_INSTRS_LS];
      r3 = M[$NUM_INSTRS_MS];
      r2 = M[$NUM_INSTRS_LS];
      r2 = r2 - 2;
      r3 = r3 - Borrow;
      Null = r3 - r0;
      if LT r3 = r0;
      M[r1 + $profiler.INSTRS_MS_START_FIELD] = r3;
      M[r1 + $profiler.INSTRS_LS_START_FIELD] = r2;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$interrupt.total_instrs_ms];
      M[r1 + $profiler.INT_START_INSTRS_MS_FIELD] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$interrupt.total_instrs_ls];
      M[r1 + $profiler.INT_START_INSTRS_LS_FIELD] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r3 = M[$NUM_STALLS_MS];
      r2 = M[$NUM_STALLS_LS];
      M[r1 + $profiler.STALLS_MS_START_FIELD] = r3;
      M[r1 + $profiler.STALLS_LS_START_FIELD] = r2;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$interrupt.total_stalls_ms];
      M[r1 + $profiler.INT_START_STALLS_MS_FIELD] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$interrupt.total_stalls_ls];
      M[r1 + $profiler.INT_START_STALLS_LS_FIELD] = r0;
      pop r3;
      $unblock_interrupts_macro;  // 7 instructions, 8 cycles, 1 BC5 style stall
      pop r2;
   #endif
   #endif

   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $profiler.stop
//
// DESCRIPTION:
//    Stop profiling of a particular routine
//
// INPUTS:
//    - r0 = address of structure to use for profiling
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r1, r2, r3, r4
//
// *****************************************************************************
.MODULE $M.profiler.stop;
   .CODESEGMENT PROFILER_STOP_PM;

   $profiler.stop:

   r1 = r0;
   $block_interrupts_macro;  // 6 instructions, 7 cycles (0 BC5 style stall)
   // TotalTime  = TotalTime + (TimerTime - StartTime) - (delta_InterruptTime);
   r0 = M[r1 + $profiler.TOTAL_TIME_FIELD];
   r2 = M[r1 + $profiler.START_TIME_FIELD];
   r0 = r0 - r2;
   r2 = M[r1 + $profiler.INT_START_TIME_FIELD];
   r0 = r0 + r2;
   #ifdef INTERRUPT_PROFILER_ON
      r0 = r0 - M[$interrupt.total_time];
   #endif
   r0 = r0 + M[$TIMER_TIME];
   M[r1 + $profiler.TOTAL_TIME_FIELD] = r0;

   #ifdef DETAILED_PROFILER_ON
   #ifdef INTERRUPT_PROFILER_ON
      push r3;
      push r4;

      r0 = M[$NUM_RUN_CLKS_MS];
      r2 = M[$NUM_RUN_CLKS_LS];
      r3 = M[$NUM_RUN_CLKS_MS];
      r2 = M[$NUM_RUN_CLKS_LS];
      r2 = r2 - 2;
      r3 = r3 - Borrow;
      Null = r3 - r0;
      if LT r3 = r0;
      r4 = M[r1 + $profiler.RUN_CLKS_LS_START_FIELD];
      r0 = M[r1 + $profiler.RUN_CLKS_MS_START_FIELD];
      r2 = r2 - r4; // Instruction moved here to avoid resetting of flags from r0 = M[...]
      r0 = r3 - r0 - Borrow;
      r4 = M[$interrupt.total_clocks_ls];
      r3 = M[$interrupt.total_clocks_ms];
      r2 = r2 - r4; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      r0 = r0 - r3 - Borrow;
      r4 = M[r1 + $profiler.INT_START_CLKS_LS_FIELD];
      r3 = M[r1 + $profiler.INT_START_CLKS_MS_FIELD];
      r2 = r2 + r4; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      r0 = r0 + r3 + Carry;
      r2 = r2 - (53+18+3+5);        // extra clocks between NUM_RUN_CLKS_LS reads in profiler.start and profiler.stop
      r0 = r0 - Borrow;
      r3 = M[r1 + $profiler.RUN_CLKS_LS_TOTAL_FIELD];
      r4 = M[r1 + $profiler.RUN_CLKS_MS_TOTAL_FIELD];
      r3 = r3 + r2; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      M[r1 + $profiler.RUN_CLKS_LS_TOTAL_FIELD] = r3;
      r3 = r4 + r0 + Carry;
      M[r1 + $profiler.RUN_CLKS_MS_TOTAL_FIELD] = r3;
      M[$profiler.temp_clks_ls] = r2;
      M[$profiler.temp_clks_ms] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r0 = M[$NUM_INSTRS_MS];
      r2 = M[$NUM_INSTRS_LS];
      r3 = M[$NUM_INSTRS_MS];
      r2 = M[$NUM_INSTRS_LS];
      r2 = r2 - 2;
      r3 = r3 - Borrow;
      Null = r3 - r0;
      if LT r3 = r0;
      r4 = M[r1 + $profiler.INSTRS_LS_START_FIELD];
      r0 = M[r1 + $profiler.INSTRS_MS_START_FIELD];
      r2 = r2 - r4; // Instruction moved here to avoid resetting of flags from r0 = M[...]
      r0 = r3 - r0 - Borrow;
      r4 = M[$interrupt.total_instrs_ls];
      r3 = M[$interrupt.total_instrs_ms];
      r2 = r2 - r4; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      r0 = r0 - r3 - Borrow;
      r4 = M[r1 + $profiler.INT_START_INSTRS_LS_FIELD];
      r3 = M[r1 + $profiler.INT_START_INSTRS_MS_FIELD];
      r2 = r2 + r4; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      r0 = r0 + r3 + Carry;
      r2 = r2 - (35+48+3+5);        // extra instructions between NUM_INSTRS_LS reads in profiler.start and profiler.stop
      r0 = r0 - Null -  Borrow;
      r3 = M[r1 + $profiler.INSTRS_LS_TOTAL_FIELD];
      r4 = M[r1 + $profiler.INSTRS_MS_TOTAL_FIELD];
      r3 = r3 + r2; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      M[r1 + $profiler.INSTRS_LS_TOTAL_FIELD] = r3;
      r3 = r4 + r0 + Carry;
      M[r1 + $profiler.INSTRS_MS_TOTAL_FIELD] = r3;
      M[$profiler.temp_instrs_ls] = r2;
      M[$profiler.temp_instrs_ms] = r0;
      nop; // to guard against stall if profiler structure is in DM2
      r3 = M[$NUM_STALLS_MS];
      r2 = M[$NUM_STALLS_LS];
      r4 = M[r1 + $profiler.STALLS_LS_START_FIELD];
      r0 = M[r1 + $profiler.STALLS_MS_START_FIELD];
      r2 = r2 - r4; // Instruction moved here to avoid resetting of flags from r0 = M[...]
      r0 = r3 - r0 - Borrow;
      r4 = M[$interrupt.total_stalls_ls];
      r3 = M[$interrupt.total_stalls_ms];
      r2 = r2 - r4; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      r0 = r0 - r3 - Borrow;
      r4 = M[r1 + $profiler.INT_START_STALLS_LS_FIELD];
      r3 = M[r1 + $profiler.INT_START_STALLS_MS_FIELD];
      r2 = r2 + r4; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      r0 = r0 + r3 + Carry;
      r2 = r2 - (1);        // extra BC5 stalls between NUM_STALLS_LS reads in profiler.start and profiler.stop
      r0 = r0 - Borrow;
      r3 = M[r1 + $profiler.STALLS_LS_TOTAL_FIELD];
      r4 = M[r1 + $profiler.STALLS_MS_TOTAL_FIELD];
      r3 = r3 + r2; // Instruction moved here to avoid resetting of flags from r3 = M[...]
      M[r1 + $profiler.STALLS_LS_TOTAL_FIELD] = r3;
      r3 = r4 + r0 + Carry;
      M[r1 + $profiler.STALLS_MS_TOTAL_FIELD] = r3;
      r3 = M[r1 + $profiler.STALLS_MS_MAX_FIELD];
      Null = r3 - r0;
      if GT jump not_s_max;
         if LT jump s_max;
            r3 = M[r1 + $profiler.STALLS_LS_MAX_FIELD];
            Null = r3 - r2;
            if GE jump not_s_max;
         s_max:
            M[r1 + $profiler.STALLS_MS_MAX_FIELD] = r0;
            M[r1 + $profiler.STALLS_LS_MAX_FIELD] = r2;
      not_s_max:

      r0 = M[$profiler.temp_clks_ms];
      r3 = M[r1 + $profiler.RUN_CLKS_MS_MAX_FIELD];
      Null = r3 - r0;
      if GT jump not_rc_max;
         if LT jump rc_max;
            r2 = M[$profiler.temp_clks_ls];
            r3 = M[r1 + $profiler.RUN_CLKS_LS_MAX_FIELD];
            Null = r3 - r2;
            if GE jump not_rc_max;
         rc_max:
            M[r1 + $profiler.RUN_CLKS_MS_MAX_FIELD] = r0;
            M[r1 + $profiler.RUN_CLKS_LS_MAX_FIELD] = r2;
      not_rc_max:

      r0 = M[$profiler.temp_instrs_ms];
      r3 = M[r1 + $profiler.INSTRS_MS_MAX_FIELD];
      Null = r3 - r0;
      if GT jump not_i_max;
         if LT jump i_max;
            r2 = M[$profiler.temp_instrs_ls];
            r3 = M[r1 + $profiler.INSTRS_LS_MAX_FIELD];
            Null = r3 - r2;
            if GE jump not_i_max;
         i_max:
            M[r1 + $profiler.INSTRS_MS_MAX_FIELD] = r0;
            M[r1 + $profiler.INSTRS_LS_MAX_FIELD] = r2;
      not_i_max:

      pop r4;
      pop r3;
   #endif
   #endif

   $unblock_interrupts_macro;
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $profiler.timer_service_routine
//
// DESCRIPTION:
//    Timer handler for profiler.
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
// NOTES:
//    This computes the cpu usage of each routine being profiled.  This
// information of cpu usage can then be read from the chip using the Matlab
// tool 'kalprofiler'
//
// *****************************************************************************
.MODULE $M.profiler.timer_service_routine;
   .CODESEGMENT PROFILER_TIMER_SERVICE_ROUTINE_PM;

   $profiler.timer_service_routine:

   // push rLink onto stack
   $push_rLink_macro;

   #ifdef INTERRUPT_PROFILER_ON
      // Calc CPU fraction of interrupt servicing
      r0 = M[$interrupt.total_time];
      r1 = M[$interrupt.period_start_time];

      // Interrupt CPU fraction = (TotalTime - PeriodStartTime) >> 10
      r1 = r0 - r1;
      r1 = r1 ASHIFT - 10;
      M[$interrupt.cpu_fraction] = r1;

      // set PeriodStartTime = TotalTime
      M[$interrupt.period_start_time] = r0;
   #endif

   // Go through and calc CPU fraction of all routines being monitored
   r10 = $profiler.MAX_PROFILER_HANDLERS;
   r0 = M[$profiler.last_addr];
   do loop;
      // if we're at the last structure in the linked list then finish
      Null = r0 - $profiler.LAST_ENTRY;
      if Z jump done;

      // CPU fraction = TotalTime >> 10
      // 1000 equates to 100% CPU
      r1 = M[r0 + $profiler.TOTAL_TIME_FIELD];
      r1 = r1 ASHIFT - 10;
      M[r0 + $profiler.CPU_FRACTION_FIELD] = r1;

      #ifdef DETAILED_PROFILER_ON
         r1 = M[r0 + $profiler.TEMP_COUNT_FIELD];
         M[r0 + $profiler.COUNT_FIELD] = r1;
         M[r0 + $profiler.TEMP_COUNT_FIELD] = Null;

         // Average k clocks per second = Total >> 10
         // 5 equates to 5000 clocks per second
         r1 = M[r0 + $profiler.RUN_CLKS_LS_TOTAL_FIELD];
         r1 = r1 LSHIFT - 10;
         r2 = M[r0 + $profiler.RUN_CLKS_MS_TOTAL_FIELD];
         r2= r2 LSHIFT 14;
         r1 = r1 + r2;
         M[r0 + $profiler.RUN_CLKS_AVERAGE_FIELD] = r1;
         // set Totals = 0
         M[r0 + $profiler.RUN_CLKS_LS_TOTAL_FIELD] = Null;
         M[r0 + $profiler.RUN_CLKS_MS_TOTAL_FIELD] = Null;

         // Average k instructions per second = Total >> 10
         // 5 equates to 5000 instructions per second
         r1 = M[r0 + $profiler.INSTRS_LS_TOTAL_FIELD];
         r1 = r1 LSHIFT - 10;
         r2 = M[r0 + $profiler.INSTRS_MS_TOTAL_FIELD];
         r2= r2 LSHIFT 14;
         r1 = r1 + r2;
         M[r0 + $profiler.INSTRS_AVERAGE_FIELD] = r1;
         // set Totals = 0
         M[r0 + $profiler.INSTRS_LS_TOTAL_FIELD] = Null;
         M[r0 + $profiler.INSTRS_MS_TOTAL_FIELD] = Null;

         // Average k stalls per second = Total >> 10
         // 5 equates to 5000 stalls per second
         r1 = M[r0 + $profiler.STALLS_LS_TOTAL_FIELD];
         r1 = r1 LSHIFT - 10;
         r2 = M[r0 + $profiler.STALLS_MS_TOTAL_FIELD];
         r2= r2 LSHIFT 14;
         r1 = r1 + r2;
         M[r0 + $profiler.STALLS_AVERAGE_FIELD] = r1;
         // set Totals = 0
         M[r0 + $profiler.STALLS_LS_TOTAL_FIELD] = Null;
         M[r0 + $profiler.STALLS_MS_TOTAL_FIELD] = Null;
      #endif

      // set TotalTime = 0
      M[r0 + $profiler.TOTAL_TIME_FIELD] = Null;

      // read the adddress of the next profiler
      r0 = M[r0 + $profiler.NEXT_ADDR_FIELD];
   loop:

   // something's gone wrong - either too many handlers,
   // or more likely the linked list has got corrupt.
   call $error;

   done:

   // kick the timer off again to service profiler in 1.024secs
   r1 = &$profiler.timer_struc;
   r2 = 1024000;
   r3 = &$profiler.timer_service_routine;
   call $timer.schedule_event_in;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif
