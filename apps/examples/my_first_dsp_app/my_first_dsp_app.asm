//******************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2006 ~ 2014 http://www.csr.com
// *****************************************************************************
// *****************************************************************************
// DESCRIPTION 
// An example app for routing audio through the Kalimba DSP from ADC to DAC
//
// NOTES  
//
// What the code does:
//    Sets up cbuffers (circular connection buffers) for reading audio from
//    the ADC and routing to the DAC. Cbuffers are serviced by timer
//    interrupts.
// *****************************************************************************

// 1.5ms is chosen as the interrupt rate for the audio input/output
// because: ADC/DAC MMU buffer is 256byte = 128samples
//                               - up to 8 sample FIFO in voice interface
//                               = 120samples = 2.5ms @ 48kHz
// Assume absolute worst case jitter on interrupts = 1ms
// Hence choose 1.5ms between audio input/output interrupts

#define $TMR_PERIOD_AUDIO_COPY         1500
#define $AUDIO_CBUFFER_SIZE            512
#define $DATA_COPIED                   0
#define $DATA_NOT_COPIED               1
#define $TONES_BLOCK_SIZE              $AUDIO_CBUFFER_SIZE/2

// Standard includes
#include "core_library.h"
#include "cbops_library.h"

.MODULE $M.main;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $main:

   // ** Setup ports that are to be used **
   .CONST  $AUDIO_LEFT_IN_PORT     ($cbuffer.READ_PORT_MASK + 0);
   .CONST  $AUDIO_RIGHT_IN_PORT    ($cbuffer.READ_PORT_MASK + 1);
   .CONST  $AUDIO_LEFT_OUT_PORT    ($cbuffer.WRITE_PORT_MASK + 0);
   .CONST  $AUDIO_RIGHT_OUT_PORT   ($cbuffer.WRITE_PORT_MASK + 1);

   // ** Allocate memory for cbuffers **
   // cbuffers are 'circular connection buffers'
   .VAR/DMCIRC $audio_in_left[$AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_in_right[$AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_out_left[$AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_out_right[$AUDIO_CBUFFER_SIZE];

   // ** Allocate memory for cbuffer structures **
   .VAR $audio_in_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
       LENGTH($audio_in_left),         // Size
       &$audio_in_left,                // Read pointer
       &$audio_in_left;                // Write pointer
   .VAR $audio_in_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
       LENGTH($audio_in_right),        // Size
       &$audio_in_right,               // Read pointer
       &$audio_in_right;               // Write pointer
   .VAR $audio_out_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
       LENGTH($audio_out_left),        // Size
       &$audio_out_left,               // Read pointer
       &$audio_out_left;               // Write pointer
   .VAR $audio_out_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
       LENGTH($audio_out_right),       // Size
       &$audio_out_right,              // Read pointer
       &$audio_out_right;              // Write pointer

   // ** Allocate memory for timer structures **
   .VAR $audio_in_timer_struc[$timer.STRUC_SIZE];
   .VAR $audio_out_timer_struc[$timer.STRUC_SIZE];

   // Input:
   // ------
   // ** Allocate memory for cbops stereo input copy routines **
   .VAR $audio_in_copy_struc[] =
      &$audio_in_left_shift_op,        // First operator block
      2,                               // Number of inputs
      $AUDIO_LEFT_IN_PORT,             // Input
      $AUDIO_RIGHT_IN_PORT,            // Input
      2,                               // Number of outputs
      &$audio_in_left_cbuffer_struc,   // Output
      &$audio_in_right_cbuffer_struc;  // Output

   .BLOCK $audio_in_left_shift_op;
      .VAR $audio_in_left_shift_op.next = &$audio_in_left_dc_remove_op;
      .VAR $audio_in_left_shift_op.func = &$cbops.shift;
      .VAR $audio_in_left_shift_op.param[$cbops.shift.STRUC_SIZE] =
         0,                            // Input index
         2,                            // Output index
         8;                            // Shift amount
   .ENDBLOCK;

   .BLOCK $audio_in_left_dc_remove_op;
      .VAR $audio_in_left_dc_remove_op.next = &$audio_in_right_shift_op;
      .VAR $audio_in_left_dc_remove_op.func = &$cbops.dc_remove;
      .VAR $audio_in_left_dc_remove_op.param[$cbops.dc_remove.STRUC_SIZE] =
         2,                            // Input index
         2,                            // Output index
         0;                            // DC estimate
   .ENDBLOCK;

   .BLOCK $audio_in_right_shift_op;
      .VAR $audio_in_right_shift_op.next = &$audio_in_right_dc_remove_op;
      .VAR $audio_in_right_shift_op.func = &$cbops.shift;
      .VAR $audio_in_right_shift_op.param[$cbops.shift.STRUC_SIZE] =
         1,                            // Input index
         3,                            // Output index
         8;                            // Shift amount
   .ENDBLOCK;

   .BLOCK $audio_in_right_dc_remove_op;
      .VAR $audio_in_right_dc_remove_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_in_right_dc_remove_op.func = &$cbops.dc_remove;
      .VAR $audio_in_right_dc_remove_op.param[$cbops.dc_remove.STRUC_SIZE] =
         3,                            // Input index
         3,                            // Output index
         0;                            // DC estimate
   .ENDBLOCK;

   // Output:
   // ------
   // ** Allocate memory for cbops stereo output copy routines **
   .VAR $audio_out_copy_struc[] =
      &$audio_out_left_dc_remove_op,   // First operator block
      2,                               // Number of inputs
      &$audio_out_left_cbuffer_struc,  // Input
      &$audio_out_right_cbuffer_struc, // Input
      2,                               // Number of outputs
      $AUDIO_LEFT_OUT_PORT,            // Output
      $AUDIO_RIGHT_OUT_PORT;           // Output

   .BLOCK $audio_out_left_dc_remove_op;
      .VAR $audio_out_left_dc_remove_op.next = &$audio_out_left_shift_op;
      .VAR $audio_out_left_dc_remove_op.func = &$cbops.dc_remove;
      .VAR $audio_out_left_dc_remove_op.param[$cbops.dc_remove.STRUC_SIZE] =
         0,                            // Input index
         0,                            // Output index
         0;                            // DC estimate
   .ENDBLOCK;

   .BLOCK $audio_out_left_shift_op;
      .VAR $audio_out_left_shift_op.next = &$audio_out_right_dc_remove_op;
      .VAR $audio_out_left_shift_op.func = &$cbops.shift;
      .VAR $audio_out_left_shift_op.param[$cbops.shift.STRUC_SIZE] =
         0,                            // Input index.
         2,                            // Output index
         -8;                           // Shift amount
   .ENDBLOCK;

   .BLOCK $audio_out_right_dc_remove_op;
      .VAR $audio_out_right_dc_remove_op.next = &$audio_out_right_shift_op;
      .VAR $audio_out_right_dc_remove_op.func = &$cbops.dc_remove;
      .VAR $audio_out_right_dc_remove_op.param[$cbops.dc_remove.STRUC_SIZE] =
         1,                            // Input index
         1,                            // Output index
         0;                            // DC estimate
   .ENDBLOCK;

   .BLOCK $audio_out_right_shift_op;
      .VAR $audio_out_right_shift_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_right_shift_op.func = &$cbops.shift;
      .VAR $audio_out_right_shift_op.param[$cbops.shift.STRUC_SIZE] =
         1,                            // Input index
         3,                            // Output index
         -8;                           // Shift amount
   .ENDBLOCK;

   // Input to Output:
   // ----------------
   // ** Allocate memory for cbops stereo loopback copy routines **
   .VAR $audio_loopback_copy_struc[] =
      &$audio_loopback_left_copy_op,   // First operator block
      2,                               // Number of inputs
      &$audio_in_left_cbuffer_struc,   // Input
      &$audio_in_right_cbuffer_struc,  // Input
      2,                               // Number of outputs
      &$audio_out_left_cbuffer_struc,  // Output
      &$audio_out_right_cbuffer_struc; // Output

   .BLOCK $audio_loopback_left_copy_op;
      .VAR $audio_loopback_left_copy_op.next = &$audio_loopback_right_copy_op;
      .VAR $audio_loopback_left_copy_op.func = &$cbops.copy_op;
      .VAR $audio_loopback_left_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         0,                            // Input index
         2;                            // Output index
   .ENDBLOCK;

   .BLOCK $audio_loopback_right_copy_op;
      .VAR $audio_loopback_right_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_loopback_right_copy_op.func = &$cbops.copy_op;
      .VAR $audio_loopback_right_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         1,                            // Input index
         3;                            // Output index
   .ENDBLOCK;

   // Initialise the stack library
   call $stack.initialise;
   // Initialise the interrupt library
   call $interrupt.initialise;
   // Initialise the message library
   call $message.initialise;
   // Initialise the cbuffer library
   call $cbuffer.initialise;

   // Tell VM we're ready and wait for the go message
   call $message.send_ready_wait_for_go;

   // Left and right audio channels from the MMU have been synced to each
   // other by the VM app but are free running in that the DSP doesn't tell
   // them to start.  We need to make sure that our copying between the
   // cbuffers and the MMU buffers starts off in sync with respect to left
   // and right channels.  To do this we make sure that when we start the
   // copying timers that there is no chance of a buffer wrap around
   // occurring within the timer period. The easiest way to do this is to
   // start the timers just after a buffer wrap around occurs.
   // Wait for ADC buffers to have just wrapped around
   wait_for_adc_buffer_wraparound:
      r0 = $AUDIO_LEFT_IN_PORT;
      call $cbuffer.calc_amount_data;
      // If the amount of data in the buffer is less than 32 bytes then a
      // buffer wrap around must have just occurred.
      Null = r0 - 32;
   if POS jump wait_for_adc_buffer_wraparound;

   // Start timer that copies input samples
   r1 = &$audio_in_timer_struc;
   r2 = $TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_in_copy_handler;
   call $timer.schedule_event_in;

   // Wait for DAC buffers to have just wrapped around
   wait_for_dac_buffer_wraparound:
      r0 = $AUDIO_LEFT_OUT_PORT;
      call $cbuffer.calc_amount_space;
      // If the amount of space in the buffer is less than 32 bytes then a
      // buffer wrap around must have just occurred.
      Null = r0 - 32;
   if POS jump wait_for_dac_buffer_wraparound;

   // Start timer that copies output samples
   r1 = &$audio_out_timer_struc;
   r2 = $TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in;

   // Start a loop to copy the data from the input through to the output
   // buffers
   copy_loop:

   call $loopback_copy;
   Null = r0 - $DATA_NOT_COPIED;
   if Z call $timer.1ms_delay;

   jump copy_loop;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $audio_in_copy_handler
//
// DESCRIPTION:
//    Function called on an interrupt timer to copy samples from MMU
//    input ports to internal cbuffers.
//
// *****************************************************************************
.MODULE $M.audio_in_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $audio_in_copy_handler:

   // Push rLink onto stack
   $push_rLink_macro;

   // Copy data whatever mode we are in to keep in sync
   // transfer data from mmu port to internal cbuffer
   r8 = &$audio_in_copy_struc;
   call $cbops.copy;

   // Post another timer event
   r1 = &$audio_in_timer_struc;
   r2 = $TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_in_copy_handler;
   call $timer.schedule_event_in;

   // Pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $audio_out_copy_handler
//
// DESCRIPTION:
//    Function called on an interrupt timer to copy samples from internal
//    cbuffers to output MMU ports.
//
// *****************************************************************************
.MODULE $M.audio_out_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $audio_out_copy_handler:

   // Push rLink onto stack
   $push_rLink_macro;

   // Transfer data from internal cbuffer to MMU port
   r8 = &$audio_out_copy_struc;
   call $cbops.copy;

   // Post another timer event
   r1 = &$audio_out_timer_struc;
   r2 = $TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in;

   // Pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $loopback_copy
//
// DESCRIPTION:
//    Routine to copy data from both input channels into the corresponding
//    output buffer.  Routine is on a long delay between calls so need to
//    ensure we copy enough data.
//
// INPUTS:
//    none
//
// OUTPUTS:
//    r0 = DATA_COPIED / DATA_NOT_COPIED
//
// TRASHED REGISTERS:
//    r8
//    Called buffer routines called also trash:
//    r1, r2, r3, r4, I0, L0, I1, L1, r10, DO LOOP
//
// *****************************************************************************
.MODULE $M.loopback_copy;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $loopback_copy:

   // push rLink onto stack
   $push_rLink_macro;

   // Check if there is enough data in the input buffer
   r0 = &$audio_in_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   Null = r0 - $TONES_BLOCK_SIZE;
   if NEG jump dont_copy;

   r0 = &$audio_in_right_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   Null = r0 - $TONES_BLOCK_SIZE;
   if NEG jump dont_copy;

   // Check if there is enough data in the output buffer
   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $TONES_BLOCK_SIZE;
   if NEG jump dont_copy;

   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $TONES_BLOCK_SIZE;
   if NEG jump dont_copy;

   // Block interrupts when copying sample data
   call $interrupt.block;

   // Copy the data between the buffers
   r8 = &$audio_loopback_copy_struc;
   call $cbops.copy;

   // Now unblock interrupts
   call $interrupt.unblock;

   // Indicate DATA_COPIED and return
   r0 = $DATA_COPIED;
   // pop rLink from stack
   jump $pop_rLink_and_rts;

   // Indicate DATA_NOT_COPIED and return
   dont_copy:
   r0 = $DATA_NOT_COPIED;
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
