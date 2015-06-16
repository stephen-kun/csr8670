// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Frame Process Library
//
// DESCRIPTION:
//    This library provides a framework for custom processes operating on frames
//    of data per instance
//
//    When using frame_process, the following data structure is used:
//
//       - AMT_READY_BUFFER_PTR_FIELD =
//                               Pointer to buffer which stores amount ready for
//                               all input streams
//       - MIN_AMOUNT_READY_FIELD =
//                               Minimum of all values in buffers which store
//                               amount ready for all input and output streams
//       - NUM_OUTPUT_RATE_OBJECTS_FIELD =
//                               Number of output Rate Matching paramete objects
//       - NUM_RATE_OBJECTS_FIELD =
//                               Number of Rate Matching paramete objects
//       - FIRST_CBUFFER_STRUC_FIELD =
//                               pointer to first cbuffer structure
//       - *** Continuing list of rate matching data object pointers ***
//
// *****************************************************************************

#ifndef FRAME_SYNC_FRAME_PROCESS_INCLUDED
#define FRAME_SYNC_FRAME_PROCESS_INCLUDED

// includes
#include "core_library.h"
#include "architecture.h"
#include "frame_sync_tsksched.h"

.CONST   $frame_sync.MAX_CLK_DIV_RATE       ($CLK_DIV_MAX < $CLK_DIV_1024) ? $CLK_DIV_MAX : $CLK_DIV_1024;


// *****************************************************************************
// MODULE:
//    $frame_sync.frame_process
//
// DESCRIPTION:
//    The main framework routine for custom processing for eg: voice
//
// INPUTS:
//    - r8 = pointer to frame process object
//
// OUTPUTS:
//    - AMT_READY_BUFFER_PTR_FIELD in frame process object points to an array
//      which is updated
//    - MIN_AMOUNT_READY_FIELD in frame process object is updated
//
// TRASHED REGISTERS:
//    r0, r1, r3, r5, r6, r10, I0, I1, M1, DoLoop
//
//
// NOTES:
//    This routine updates the amount_ready buffer based on
//    amount of data and space in the ports/cbuffers pointed to by frame process
//    object. It also calculates minimum amount ready across all ports/cbuffers.
//    The output of this function is the amount ready buffer and the
//    min_amount_ready information. The custom process can then write code to
//    make use of this information along with app specific info and integrate
//    the custom process into this framework.
//    A flag-based delay should be used to synchronize frame based processing
//    with the audio interrupt. Functions to perform the sync are included in
//    this file
// *****************************************************************************
.MODULE $M.frame_sync.frame_process;
   .CODESEGMENT FRAME_SYNC_FRAME_PROCESS_PM;
   .DATASEGMENT DM;

$frame_sync.frame_process:
   $push_rLink_macro;
   // GPR to facilitate Type A instr.
   M1 = 1;
   r6 = M[r8 + $frame_sync.frame_process.NUM_OUTPUT_RATE_OBJECTS_FIELD];
   // r10 = number of rate objects
   r10 = M[r8 + $frame_sync.frame_process.NUM_RATE_OBJECTS_FIELD];
   // I0 points to first cbuffer structure
   I0 = r8 + $frame_sync.frame_process.FIRST_CBUFFER_STRUC_FIELD;
   // r0 points to amount ready [] buffer
   r0 = M[r8 + $frame_sync.frame_process.AMT_RDY_BUFFER_PTR_FIELD];
   // I1 points to amt ready buffer, r3 points to first rate object
   I1 = r0, r3 = M[I0,M1];
   // initalize r5 to cbuffer size
   // r5 will be used to calculate minimum amt ready
   r5 = M[r3 + $cbuffer.SIZE_FIELD];

   // update current stream state, amount ready[] and min amount ready
   do update_amt_rdy;
      // Calculate data/space
      r0 = r3;
      Null = r10 - r6;
      if GT call $cbuffer.calc_amount_data;
      Null = r10 - r6;
      if LE call $cbuffer.calc_amount_space;

      Null = r5 - r0, r3 = M[I0,M1];
      // r5 = minimum amt ready
      if GT r5 = r0,  M[I1,M1] = r0;
update_amt_rdy:

   // update min amt ready field in frame process struc
   M[r8 + $frame_sync.frame_process.MIN_AMOUNT_READY_FIELD] = r5;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.1ms_delay
//
// DESCRIPTION:
//    This function synchronizes frame process to audio timer interrupt
//
// INPUTS:
//    - None
//
// OUTPUTS:
//    - None
//
// TRASHED REGISTERS:
//    r0, r1
//
// NOTES:
//    The application would call this function before calling
//    frame based processing in the main loop. This allows frame based
//    processing to be synced with audio interrupt
//
// *****************************************************************************
.MODULE $M.frame_sync.1ms_delay;
   .CODESEGMENT FRAME_SYNC_1MS_DELAY_PM;
   .DATASEGMENT DM;

   .VAR $frame_sync.sync_flag;

$frame_sync.1ms_delay:
   // set sync_flag at start of frame process
   r1 = 1;
   M[$frame_sync.sync_flag] = r1;

   // go to slower clock and wait up to 1 interrupt time
   // save current clock rate
   r1 = M[$CLOCK_DIVIDE_RATE];

   r0 = $frame_sync.MAX_CLK_DIV_RATE;

   // go to slower clock
   M[$CLOCK_DIVIDE_RATE] = r0;

   // wait in loop (delay) till sync flag is reset in rate match amount to use
frame_operator_sync_loop:
      Null = M[$frame_sync.sync_flag];
   if NZ jump frame_operator_sync_loop;   // wait in loop till flag reset

   // restore clock rate
   M[$CLOCK_DIVIDE_RATE] = r1;

   rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frame_sync.reset_sync_flag
//
// DESCRIPTION:
//    This function resets sync flag.
//
// INPUTS:
//    - None
//
// OUTPUTS:
//    - None
//
// TRASHED REGISTERS:
//    - None
//
// NOTES:
//    $frame_sync.1ms_delay function sets the sync flag and then waits till the
//    sync flag is reset by this function
// *****************************************************************************
.MODULE $M.frame_sync.reset_sync_flag;
   .CODESEGMENT FRAME_SYNC_RESET_SYNC_FLAG_PM;

   $frame_sync.reset_sync_flag:

   // clear the sync flag
   M[$frame_sync.sync_flag] = Null;

   rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $M.frame_sync.task_scheduler_isr
//
// DESCRIPTION:
//    This function schedules the applications tasks
//
// INPUTS:
//    r8 = Pointer to the task list
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//    
//
// *****************************************************************************
.MODULE $M.frame_sync.task_scheduler_isr;
   .CODESEGMENT   FRAME_SYNC_TASK_SCHED_ISR_PM;

$frame_sync.task_scheduler_isr:

    r7  = M[r8 + $FRM_SCHEDULER.COUNT_FIELD];      // Frame Counter
    r10 = M[r8 + $FRM_SCHEDULER.NUM_TASKS_FIELD];  // Number of Tasks
    I0 = r8 +  $FRM_SCHEDULER.TASKS_FIELD + 1;     // Task trigger points
    r1 = 0x400000;
    
    // Update Task Triggers
    r2  = M[r8 + $FRM_SCHEDULER.TRIGGER_FIELD];    // Trigger
do  lp_sched;
    r0 = M[I0,2];       // Scheduled Time
    NULL = r0 - r7;
    if Z r2 = r2 OR r1;
    r1 = r1 LSHIFT -1;
lp_sched:
    M[r8 + $FRM_SCHEDULER.TRIGGER_FIELD]=r2;

   // cycle timer
   r0 = r7 + 1;
   r1 = M[r8 + $FRM_SCHEDULER.MAX_COUNT_FIELD];
   NULL = r0 - r1;
   if POS r0=NULL;
   M[r8 + $FRM_SCHEDULER.COUNT_FIELD] = r0; 
   rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.frame_sync.task_scheduler_run
//
// DESCRIPTION:
//    This function calls the scheduled application task and tasks MIPs
//
//
// INPUTS:
//    r8    = Pointer to the task list
//
// OUTPUTS:
//
//
// TRASHED REGISTERS:
//    
//
// *****************************************************************************
.MODULE $M.frame_sync.task_scheduler_run;
   .CODESEGMENT   FRAME_SYNC_TASK_SCHED_RUN_PM;
   .DATASEGMENT   DM;
   

$frame_sync.task_scheduler_run: 

     // Timer status for MIPs estimate
     r1 = M[$TIMER_TIME]; 
     r4 = M[$interrupt.total_time];
     
     // save current clock rate
     r6 = M[$CLOCK_DIVIDE_RATE];
     // go to slower clock and wait for task event
     r0 = $frame_sync.MAX_CLK_DIV_RATE;
     M[$CLOCK_DIVIDE_RATE] = r0;
jp_wait:
     r2 = M[r8 + $FRM_SCHEDULER.TRIGGER_FIELD];
     if Z jump jp_wait;
     // restore clock rate
     M[$CLOCK_DIVIDE_RATE] = r6; 
   
     // r1 is total idel time
     r3 = M[$TIMER_TIME];
     r0 = M[r8 + $FRM_SCHEDULER.TOTALTM_FIELD];          
     r1 = r3 - r1; 
     r4 = r4 - M[$interrupt.total_time];
     r1 = r1 + r4;
     r1 = r1 + r0;
     M[r8 + $FRM_SCHEDULER.TOTALTM_FIELD]=r1; 

     // Check for MIPs update  <reserve r2,r8>
     r0 = M[r8 + $FRM_SCHEDULER.TIMER_FIELD];
     r5 = r3 - r0;
     rMAC = 1000000;
     NULL = r5 - rMAC;
     if NEG jump jp_mips_done;
     
    // Time Period
	rMAC = rMAC ASHIFT -1;
	Div = rMAC/r5;       
    // Total Processing (Time Period - Idle Time)
    rMAC = r5 - r1;
    // Total Send Processing
    r5 = M[r8 + $FRM_SCHEDULER.TOTALSND_FIELD];
    // Last Trigger Time 
    M[r8 + $FRM_SCHEDULER.TIMER_FIELD]=r3;
    // Reset total time count
    M[r8 + $FRM_SCHEDULER.TOTALTM_FIELD] =NULL;     // Idle Time
    M[r8 + $FRM_SCHEDULER.TOTALSND_FIELD]=NULL;     // Send Processing Time

    // MIPS
    r3  = DivResult;
    rMAC  = r3 * rMAC (frac);	   
    r5    = r3 * r5 (frac);
    // SP. convert for UFE format
	// UFE uses STAT_FORMAT_MIPS - Displays (m_ulCurrent/8000.0*m_pSL->GetChipMIPS()) 
	// Multiply by 0.008 = 1,000,000 --> 8000 = 100% of MIPs  
	r3 = 0.008;
	
    rMAC = rMAC * r3 (frac);                        // Total MIPs Est
    r5 = r5 * r3 (frac);                            // Send MIPs Est
    M[r8 + $FRM_SCHEDULER.TOTAL_MIPS_FIELD]=rMAC;         
    M[r8 + $FRM_SCHEDULER.SEND_MIPS_FIELD]=r5;  
jp_mips_done:
    
     // Determine Trigger Function (r2)
     r2 = SIGNDET r2;       // 0=0x400000,1=0x200000,2=0x100000, etc.
     r3 = r2 LSHIFT 1;  
     r3 = r3 + $FRM_SCHEDULER.TASKS_FIELD;
     r3 = M[r8 + r3];
     // Generate Mask
     r4 = 0xBFFFFF;     // ~0x400000
     r2 = NULL - r2;
     r2 = r4 ASHIFT r2;
     // Clear Trigger	 
     $push_rLink_macro;
	 call $block_interrupts;     
     r4 = M[r8 + $FRM_SCHEDULER.TRIGGER_FIELD];
     r4 = r4 AND r2;
     M[r8 + $FRM_SCHEDULER.TRIGGER_FIELD]=r4;
     call $unblock_interrupts;
     
     // Call scheduled Task
     call r3;
     jump $pop_rLink_and_rts;


.ENDMODULE;

#endif // FRAME_SYNC_FRAME_PROCESS_INCLUDED
