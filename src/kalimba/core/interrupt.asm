// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Interrupt Library
//
// DESCRIPTION:
//    This library has functions to setup the interrupt controller, block and
//    unblock interrupts, and also a standard interrupt service routine (ISR).
//    The ISR currently handles just MCU and timer1 interrupt sources, but may
//    be extended if required.
//
//    Upon an interrupt, the Kalimba DSP jumps to location 0x0002,
//    copies the user mode flags values to the interrupt mode bits (MSbyte).
//
//    The Kalimba supports four interrupt priority levels. Level zero does
//    not interrupt the Kalimba but will wake it up from a sleep instruction.
//    An interrupt source with a higher interrupt priority may interrupt the
//    ISR if the UM flag is set.
//
//    The Kalimba DSP has eight interrupt sources: four software based events;
//    two timer events; a PIO event and an MCU event.  To enable an interrupt
//    source, enable its bitfield in $INT_SOURCES_EN, set its priority to
//    greater than 0 in $INT_PRIORITIES and write 1 to $INT_GBL_ENABLE and
//    $INT_ENABLE to enable Kalimba DSP interrupts.  $INT_GBL_ENABLE is used
//    to reset the interrupt handler; no interrupts are recorded or allowed
//    when this is zero. $INT_ENABLE is used to prevent interrupts firing,
//    when $INT_ENABLE is high, any interrupts will then trigger.
//
//    To block and unblock interrupts, call the $block_interrupts and
//    $unblock_interrupts subroutines; for interrupts to be enabled, the
//    $unblock_interrupts must be called as many times as $block_interrupts
//    has been called.  This allows for nested subroutines to block and
//    unblock interrupts in a consistent manner.
//
// *****************************************************************************

#ifndef INTERRUPT_INCLUDED
#define INTERRUPT_INCLUDED

#include "interrupt.h"
#include "profiler.h"
#include "stack.h"
#include "architecture.h"

.MODULE $interrupt;
   .DATASEGMENT DM;

    // Store as a constant the size of the stack required to store the
    // processor's state.  Also create a constant to hold the nested
    // interrupt state
   .CONST   STORE_STATE_SIZE       $INTERRUPT_STORE_STATE_SIZE;

   #ifdef NESTED_INTERRUPT_SUPPORT
      .CONST   NESTED_INTERRUPTS_ENABLE 1;
   #else
      .CONST   NESTED_INTERRUPTS_ENABLE 0;
   #endif


   // counter to support nested blocking/unblocking of interrupts
   .VAR block_count = 0;

    // always track time in interupt
   .VAR/DM1 start_time;              // DM1 to avoid possible stalls
   .VAR total_time = 0;

   #ifdef INTERRUPT_PROFILER_ON
      #ifdef DETAILED_PROFILER_ON
         .VAR     start_clocks_ls;
         .VAR/DM1 start_clocks_ms;      // DM1 to avoid possible stalls
         .VAR     total_clocks_ls = 0;
         .VAR/DM1 total_clocks_ms = 0;  // DM1 to avoid possible stalls
         .VAR     start_stalls_ls;
         .VAR     start_stalls_ms;
         .VAR     total_stalls_ls = 0;
         .VAR/DM1 total_stalls_ms = 0;  // DM1 to avoid possible stalls
         .VAR     start_instrs_ls;
         .VAR     start_instrs_ms;
         .VAR     total_instrs_ls = 0;
         .VAR/DM1 total_instrs_ms = 0;  // DM1 to avoid possible stalls
      #endif
      .VAR period_start_time;
      .VAR/DM1 cpu_fraction;
   #endif

   #if defined(RICK)
      .VAR isr_call_table[11] =
            $timer.service_routine,            // SOURCE_TIMER1
            $error,                            // SOURCE_TIMER2
            $error,                            // SOURCE_SW_ERROR
            $error,                            // SOURCE_SW0
            $error,                            // SOURCE_SW1
            $error,                            // SOURCE_SW2
            $error,                            // SOURCE_SW3
            $message.received_service_routine, // SOURCE_MCU_TO_DSP
            $error,                            // SOURCE_PIO
            $error,                            // SOURCE_UNUSED
            $error;                            // SOURCE_MMU_UNMAPPED

      #ifdef OPTIONAL_FAST_INTERRUPT_SUPPORT
         .VAR isr_fast_call_table[10] =
               $timer.service_routine,            // SOURCE_TIMER1
               $error,                            // SOURCE_TIMER2
               $error,                            // SOURCE_SW_ERROR
               $error,                            // SOURCE_SW0
               $error,                            // SOURCE_SW1
               $error,                            // SOURCE_SW2
               $error,                            // SOURCE_SW3
               $message.received_service_routine, // SOURCE_MCU_TO_DSP
               $error,                            // SOURCE_PIO
               $error,                            // SOURCE_UNUSED
               $error;                            // SOURCE_MMU_UNMAPPED
      #endif
   #else
      .VAR isr_call_table[9] =
              $timer.service_routine,            // SOURCE_TIMER1
              $error,                            // SOURCE_TIMER2
              $message.received_service_routine, // SOURCE_MCU
              $error,                            // SOURCE_PIO
              $error,                            // SOURCE_MMU_UNMAPPED
              $error,                            // SOURCE_SW0
              $error,                            // SOURCE_SW1
              $error,                            // SOURCE_SW2
              $error;                            // SOURCE_SW3

      #ifdef OPTIONAL_FAST_INTERRUPT_SUPPORT
         .VAR isr_fast_call_table[9] =
                 0,                                 // SOURCE_TIMER1
                 0,                                 // SOURCE_TIMER2
                 0,                                 // SOURCE_MCU
                 0,                                 // SOURCE_PIO
                 0,                                 // SOURCE_MMU_UNMAPPED
                 0,                                 // SOURCE_SW0
                 0,                                 // SOURCE_SW1
                 0,                                 // SOURCE_SW2
                 0;                                 // SOURCE_SW3
      #endif
   #endif
.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $interrupt.initialise
//
// DESCRIPTION:
//    Initialise the interrupt controller
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
// *****************************************************************************
.MODULE $M.interrupt.initialise;
   .CODESEGMENT INTERRUPT_INITIALISE_PM;

   $interrupt.initialise:

   // -- setup interrupt controller --

#ifdef KAL_ARCH5
   // low priority inerrupts     : timer1 and XAP
   r0 = ($INT_LOW_PRI_SOURCES_EN_TIMER1_MASK +
         $INT_LOW_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_MASK);
   M[$INT_LOW_PRI_SOURCES_EN] = r0;
   // medium priority interrupts : none
   M[$INT_MED_PRI_SOURCES_EN] = 0;
   // high priority interrupts   : unmapped / error
   r0 = $INT_HIGH_PRI_SOURCES_EN_SW_ERROR_MASK;
   M[$INT_HIGH_PRI_SOURCES_EN] = r0;
#else
   // enable interrupts for: timer1, mcu/arm, and mmu_unmapped
   r0 = ($INT_SOURCE_TIMER1_MASK +
         $INT_SOURCE_MCU_MASK +
         $INT_SOURCE_MMU_UNMAPPED_MASK);

   M[$INT_SOURCES_EN] = r0;

   // set int priorities: timer1 = 1,  mcu/arm = 1,  unmapped = 3,
   r0 = ((1 << $INT_SOURCE_TIMER1_POSN*2) +
         (1 << $INT_SOURCE_MCU_POSN*2) +
         (3 << $INT_SOURCE_MMU_UNMAPPED_POSN*2));

   M[$INT_PRIORITIES] = r0;
#endif

   // enable interrupts
   r0 = 1;
   M[$INT_GBL_ENABLE] = r0;
   M[$INT_UNBLOCK] = r0;

   // enable switching to the maximum clock frequency during an interrupt
   M[$INT_CLK_SWITCH_EN] = r0;
   M[$INT_CLOCK_DIVIDE_RATE] = $CLK_DIV_1;

   // switch to user mode
   rFlags = rFlags OR $UM_FLAG;
   rts;

   // force the reset and interrupt handler functions to be pulled in by kalasm2
   // don't remove these lines!!
   jump $reset;
   jump $interrupt.handler;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $block_interrupts
//
// DESCRIPTION:
//    Block interrupts subroutine, NOTE this may also be called using $interrupt.block
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
// *****************************************************************************
.MODULE $M.interrupt.block;
   .CODESEGMENT INTERRUPT_BLOCK_PM;

   $block_interrupts:
   $interrupt.block:

   r0 = M[$interrupt.block_count];
   r0 = r0 + 1;
   M[$interrupt.block_count] = r0;
   M[$INT_UNBLOCK] = Null;
   nop;
   nop;
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $unblock_interrupts
//
// DESCRIPTION:
//    Unblock interrupts subroutine, NOTE this may also be called using $interrupt.unblock
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
// *****************************************************************************
.MODULE $M.interrupt.unblock;
   .CODESEGMENT INTERRUPT_UNBLOCK_PM;

   $unblock_interrupts:
   $interrupt.unblock:

   r0 = M[$interrupt.block_count];
   if Z call $error;

   // decrement the count
   r0 = r0 - 1;
   M[$interrupt.block_count] = r0;
   // only unblock interrupts if at outer part of nesting
   if NZ rts;
   // unblock interrupts
   r0 = 1;
   M[$INT_UNBLOCK] = r0;
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $interrupt.register
//
// DESCRIPTION:
//    Registers an interrupt handler for a particular interrupt source, and
//    sets the priority as required.
//
// INPUTS:
//    - r0 - Interrupt Source (eg. $INT_SOURCE_PIO_EVENT)
//    - r1 - Interrupt Priority (1 lowest -> 3 highest, 0 wakeup)
//    - r2 - Function address to call upon interrupt
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r3, r5
//
// *****************************************************************************
.MODULE $M.interrupt.register;
   .CODESEGMENT INTERRUPT_REGISTER_PM;

   $interrupt.register:

   // push rLink onto stack
   $push_rLink_macro;

   // r0 is trashed by blocking interrupts, so set r3 = r0
   r3 = r0;

   // block interrupts first to be safe
   call $block_interrupts;

   // fill in isr_call_table as required
   M[$interrupt.isr_call_table + r3] = r2;

   $interrupt.private.register.call_table_set:

#ifdef KAL_ARCH5
   // enable interrupt source
   r1 = r1 - 1;
   r5 = M[$INT_LOW_PRI_SOURCES_EN + r1];
   r0 = 1 LSHIFT r3;
   r5 = r5 OR r0;
   M[$INT_LOW_PRI_SOURCES_EN + r1] = r5;
#else
   // enable interrupt source
   r5 = M[$INT_SOURCES_EN];
   r0 = 1 LSHIFT r3;
   r5 = r5 OR r0;
   M[$INT_SOURCES_EN] = r5;


   // form mask for priority
   r3 = r3 * 2 (int);
   r0 = 3 LSHIFT r3;
   r1 = r1 LSHIFT r3;

   // set interrupt priority as requested
   r5 = M[$INT_PRIORITIES];
   r5 = r5 OR r0;
   r5 = r5 - r0;
   M[$INT_PRIORITIES] = r5 + r1;
#endif

   // unblock interrupts and exit
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;




#ifdef OPTIONAL_FAST_INTERRUPT_SUPPORT
// *****************************************************************************
// MODULE:
//    $interrupt.register_fast
//
// DESCRIPTION:
//    Registers a fast interrupt handler for a particular interrupt source, and
//    sets the priority as required.
//
// INPUTS:
//    - r0 - Interrupt Source (eg. $INT_SOURCE_PIO_EVENT)
//    - r1 - Interrupt Priority (1 lowest -> 3 highest, 0 wakeup)
//    - r2 - Function address to call upon interrupt
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r3, r5
//
// *****************************************************************************
.MODULE $M.interrupt.register_fast;
   .CODESEGMENT INTERRUPT_REGISTER_FAST_PM;

   $interrupt.register_fast:

   // push rLink onto stack
   $push_rLink_macro;

   // r0 is trashed by blocking interrupts, so set r3 = r0
   r3 = r0;

   // block interrupts first to be safe
   call $block_interrupts;

   // fill in isr_fast_call_table as required
   M[$interrupt.isr_fast_call_table + r3] = r2;

   // reuse the last part of the standard $interrupt.register routine
   jump $interrupt.private.register.call_table_set;

.ENDMODULE;
#endif





// *****************************************************************************
// MODULE:
//    $interrupt.handler
//
// DESCRIPTION:
//    Interrupt handler that's compatible with the various library functions
//    CSR supply.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    none (all are saved and restored)
//
// NOTES:
//    The ISR code now supports both single interrupt priority mode (no nested
// interrupts) and also multiple priority (nested interrupts).  By default
// the non nested interrupt mode is selected.  To use the nested interrupt
// version you need to enable the define of NESTED_INTERRUPT_SUPPORT in interrupt.h
//
// *****************************************************************************
.MODULE $M.interrupt.handler;
   .CODESEGMENT INTERRUPT_HANDLER_PM;
   .DATASEGMENT DM;

   #ifdef OXYGEN
      .VAR $_PlEnterIrqRoutine = 0;  // TODO FIX ME - GPS SPECIFIC
      .VAR $_PlExitIrqCheckContextSwitchRoutine = 0;  // TODO FIX ME - GPS SPECIFIC
   #endif

// NOTE: be careful when changing code in here to allow for it in the calculations
//       in the DETAILED_PROFILER section at the bottom

   $interrupt.handler:

   #ifdef DEBUG_STACK_OVERFLOW
      // check the interrupt hasn't fired because of stack overflow
      Null = M[$STACK_OVERFLOW_PC];
      if NZ call $error;
   #endif

   pushm <r0, r1, r2>;
   // save current non-interrupt clock rate
   r0 = M[$CLOCK_DIVIDE_RATE];
   push r0;
   // set to fastest non-interrupt clock rate
   M[$CLOCK_DIVIDE_RATE] = $CLK_DIV_1;

   // save and reset the arithmetic mode
   r0 = M[$ARITHMETIC_MODE];
   push r0;
   M[$ARITHMETIC_MODE] = Null;

   // store the time at which the ISR was called
   r0 = M[$TIMER_TIME];
   M[$interrupt.start_time] = r0;

   #ifdef INTERRUPT_PROFILER_ON
      #ifdef DETAILED_PROFILER_ON
         r0 = M[$NUM_RUN_CLKS_MS];
         r2 = M[$NUM_RUN_CLKS_MS];
         r1 = M[$NUM_RUN_CLKS_LS];
         r1 = r1 - 1;
         r2 = r2 - Borrow;
         Null = r2 - r0;
         if LT r2 = r0;
         M[$interrupt.start_clocks_ls] = r1;
         M[$interrupt.start_clocks_ms] = r2;
         r1 = M[$NUM_STALLS_LS];
         r2 = M[$NUM_STALLS_MS];
         M[$interrupt.start_stalls_ls] = r1;
         M[$interrupt.start_stalls_ms] = r2;
         r0 = M[$NUM_INSTRS_MS];
         r2 = M[$NUM_INSTRS_MS];
         r1 = M[$NUM_INSTRS_LS];
         r1 = r1 - 1;
         r2 = r2 - Borrow;
         Null = r2 - r0;
         if LT r2 = r0;
         M[$interrupt.start_instrs_ls] = r1;
         M[$interrupt.start_instrs_ms] = r2;
      #endif
   #endif


   #ifdef OPTIONAL_FAST_INTERRUPT_SUPPORT
       // -- fast support code --

      // see if fast support required on this interrupt source
      r0 = M[$INT_SOURCE];

      #ifdef KAL_ARCH5
         // On this architecture the interrupt source is a combination of the
         // source and its priority. Low priority interrupts start at 0 and run to
         // ($INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP-1). Medium priority interrupts
         //
         //   Low priority:
         //     0                                    -> ($INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP-1)
         //   Medium priority:
         //     $INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP  -> ($INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP-1)
         //   High priority:
         //     $INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP ->
         //
         // On current chips these are the same, so a divide could be used to
         // calculate the remainder. But it's actually quicker to loop unrolled
         // repeated subtraction and have the opportunity for different numbers of
         // low, medium and high priority interrupts.
         r1 = r0 - $INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP;
         if GE r0 = r1;
         r1 = r0 - $INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP;
         if GE r0 = r1;
      #endif

      r0 = M[r0 + $interrupt.isr_fast_call_table];
      if Z jump not_a_fast_interrupt;

         // acknowledge interrupt and clear it
         M[$INT_ACK] = Null;

         // call the appropriate fast handler code
         push rLink;
         call r0;
         popm <r0, r2, rLink>;

         // clear active interrupt - but leave other requests
         r1 = $INT_LOAD_INFO_CLR_REQ_MASK;
         M[$INT_LOAD_INFO] = r1;

         // restore the arithmetic mode
         M[$ARITHMETIC_MODE] = r2;

         // restore the non-interrupt clock rate
         M[$CLOCK_DIVIDE_RATE] = r0;

         // pop and return from the interrupt
         popm <r0, r1, r2>;
         rti;

      not_a_fast_interrupt:
   #endif


   // disable any bit reverse addressing on AG1
   rFlags = rFlags AND $NOT_BR_FLAG;
   #ifdef DEBUG_STACK_OVERFLOW
      // check we've space on the stack for storing the processors state
      r0 = M[$STACK_POINTER];
      r0 = r0 + ($interrupt.STORE_STATE_SIZE - 1);
      Null = r0 - M[$STACK_END_ADDR];
      if GT call $error;
   #endif


   #ifdef NESTED_INTERRUPT_SUPPORT
      // block interrupts
      M[$INT_UNBLOCK] = Null;
      // save interrupt controller state, rIntLink, rFlags, and virtually all other registers!
      r1 = M[$INT_SAVE_INFO];
      r2 = M[$MM_RINTLINK];
      pushm <r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, rLink, rFlags>;
      pushm <I0, I1, I2, I3, I4, I5, I6, I7, M0, M1, M2, M3, L0, L1, L4, L5>;
      pushm <rMAC2, rMAC1, rMAC0, DoLoopStart, DoLoopEnd, DivResult, DivRemainder, rMACB2, rMACB1, rMACB0, B0, B1, B4, B5>;
   #else
      // push registers onto the stack
      pushm <r3, r4, r5, r6, r7, r8, r9, r10, rLink>;
      pushm <I0, I1, I2, I3, I4, I5, I6, I7, M0, M1, M2, M3, L0, L1, L4, L5>;
      pushm <rMAC2, rMAC1, rMAC0, DoLoopStart, DoLoopEnd, DivResult, DivRemainder, rMACB2, rMACB1, rMACB0, B0, B1, B4, B5>;
   #endif

   // Acknowledge interrupt and clear it:
   // - This will allow another interrupt to occur if we were in user mode,
   //     but we're not, so it will allow them after the ISR finishes, or once the
   //     UM flag is set (for nested interrupts below).
   // - For nested interrupt the INT_SOURCE register will now be valid up until we
   //     re-enable the INT_ENABLE register.
   M[$INT_ACK] = Null;

   // clear the length registers
   L0 = 0;
   L1 = 0;
   L4 = 0;
   L5 = 0;

   // clear the base registers
   push Null;
   B5 = M[SP - 1];
   B4 = M[SP - 1];
   B1 = M[SP - 1];
   pop B0;


   #ifdef OXYGEN
      // TODO FIX ME.  IDEALLY DON'T WANT THIS CHANGE TO THE STANDARD ISR ROUTINE FOR GPS PLATFORM CODE
      // Call the PlEnterIrqRountine to inform the scheduler we've had an IRQ
      r0 = M[$_PlEnterIrqRoutine];
      if NZ call r0;
   #endif

   // see what the interrupt source was - load appropriate routine into r2 for later
   r2 = M[$INT_SOURCE];
   #ifdef KAL_ARCH5
      // On this architecture the interrupt source is a combination of the
      // source and its priority. Low priority interrupts start at 0 and run to
      // ($INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP-1). Medium priority interrupts
      //
      //   Low priority:
      //     0                                    -> ($INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP-1)
      //   Medium priority:
      //     $INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP  -> ($INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP-1)
      //   High priority:
      //     $INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP ->
      //
      // On current chips these are the same, so a divide could be used to
      // calculate the remainder. But it's actually quicker to loop unrolled
      // repeated subtraction and have the opportunity for different numbers of
      // low, medium and high priority interrupts.
      r1 = r0 - $INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP;
      if GE r0 = r1;
      r1 = r0 - $INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP;
      if GE r0 = r1;
   #endif
   r3 = M[r2 + &$interrupt.isr_call_table];

   #ifdef NESTED_INTERRUPT_SUPPORT
      // switch to user mode
      rFlags = $UM_FLAG;
      // unblock interrupts if already unblocked before interrupt occured
      r0 = 1;
      Null = M[$interrupt.block_count];
      if NZ r0 = 0;
      M[$INT_UNBLOCK] = r0;
   #endif


   // call the appropriate interrupt source service routine
   call r3;

   #ifdef OXYGEN
      // TODO FIX ME.  IDEALLY DON'T WANT THIS CHANGE TO THE STANDARD ISR ROUTINE FOR GPS PLATFORM CODE
      // Reset the irq active flag used by the scheduler, and check for any context switch
      r0 = M[$_PlExitIrqCheckContextSwitchRoutine];
      if NZ call r0;
   #endif

   #ifdef DEBUG_STACK_OVERFLOW
      // check we've enough data on the stack for restoring the processor's state
      r0 = M[$STACK_POINTER];
      r0 = r0 - $interrupt.STORE_STATE_SIZE;
      Null = r0 - M[$STACK_START_ADDR];
      if LT call $error;
   #endif

   // pop processor state from the stack
   #ifdef NESTED_INTERRUPT_SUPPORT
      // we must block interrupts (by clearing UM flag) before popping rFlags otherwise
      // if an interrupt occurs the MS 8bit of rFlags (the interrupt copy) will get lost
      rFlags = 0;

      // restore registers from the stack
      popm <rMAC2, rMAC12, rMAC0, DoLoopStart, DoLoopEnd, DivResult, DivRemainder, rMACB2, rMACB12, rMACB0, B0, B1, B4, B5>;
      popm <I0, I1, I2, I3, I4, I5, I6, I7, M0, M1, M2, M3, L0, L1, L4, L5>;
      popm <r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, rLink, rFlags>;
      M[$MM_RINTLINK] = r2;
      r1 = r1 OR $INT_LOAD_INFO_CLR_REQ_MASK;
      M[$INT_LOAD_INFO] = r1;

   #else
      // restore registers from the stack
      popm <rMAC2, rMAC12, rMAC0, DoLoopStart, DoLoopEnd, DivResult, DivRemainder, rMACB2, rMACB12, rMACB0, B0, B1, B4, B5>;
      popm <I0, I1, I2, I3, I4, I5, I6, I7, M0, M1, M2, M3, L0, L1, L4, L5>;
      popm <r3, r4, r5, r6, r7, r8, r9, r10, rLink>;

      // Clear active interrupt - but leave other requests
      r1 = $INT_LOAD_INFO_CLR_REQ_MASK;
      M[$INT_LOAD_INFO] = r1;
   #endif

   // increment the total time that we've serviced interrupts for
   // TotalTime = TotalTime + (TIMER_TIME - StartTime)
   r1 = M[$interrupt.total_time];
   r1 = r1 - M[$interrupt.start_time];
   r1 = r1 + M[$TIMER_TIME];
   M[$interrupt.total_time] = r1;

   #ifdef INTERRUPT_PROFILER_ON
      #ifdef DETAILED_PROFILER_ON
         r0 = M[$NUM_RUN_CLKS_MS];
         r2 = M[$NUM_RUN_CLKS_MS];
         r1 = M[$NUM_RUN_CLKS_LS];
         r1 = r1 - 1;
         r2 = r2 - Borrow;
         Null = r2 - r0;
         if LT r2 = r0;
         r1 = r1 + (45 + 9 + 1);        // extra clocks around NUM_RUN_CLKS_LS reads in this function
         r2 = r2 + Carry;
         r1 = r1 + M[$interrupt.total_clocks_ls];
         r2 = r2 + M[$interrupt.total_clocks_ms] + Carry;
         r1 = r1 - M[$interrupt.start_clocks_ls];
         r2 = r2 - M[$interrupt.start_clocks_ms] - Borrow;
         M[$interrupt.total_clocks_ls] = r1;
         M[$interrupt.total_clocks_ms] = r2;
         r0 = M[$NUM_INSTRS_MS];
         r2 = M[$NUM_INSTRS_MS];
         r1 = M[$NUM_INSTRS_LS];
         r1 = r1 - 1;
         r2 = r2 - Borrow;
         Null = r2 - r0;
         if LT r2 = r0;
         r1 = r1 + (30 + 22 + 1);       // extra instructions around NUM_INSTRS_LS reads in this function
         r2 = r2 + Carry;
         r1 = r1 + M[$interrupt.total_instrs_ls];
         r2 = r2 + M[$interrupt.total_instrs_ms] + Carry;
         r1 = r1 - M[$interrupt.start_instrs_ls];
         r2 = r2 - M[$interrupt.start_instrs_ms] - Borrow;
         M[$interrupt.total_instrs_ls] = r1;
         M[$interrupt.total_instrs_ms] = r2;
         r1 = M[$NUM_STALLS_LS];
         r2 = M[$NUM_STALLS_MS];
         r1 = r1 + M[$interrupt.total_stalls_ls];
         r2 = r2 + M[$interrupt.total_stalls_ms] + Carry;
         r1 = r1 - M[$interrupt.start_stalls_ls];
         r2 = r2 - M[$interrupt.start_stalls_ms] - Borrow;
         M[$interrupt.total_stalls_ls] = r1;
         M[$interrupt.total_stalls_ms] = r2;
         nop;
      #endif
   #endif

   // restore the non-interrupt clock rate
   popm <r0, r1>;
   M[$ARITHMETIC_MODE] = r1;
   M[$CLOCK_DIVIDE_RATE] = r0;

   popm <r0, r1, r2>;
   rti;

.ENDMODULE;


#endif // INTERRUPT_INCLUDED
