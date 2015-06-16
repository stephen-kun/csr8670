// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// C stubs for "core" library
// These obey the C compiler calling convention (see documentation)
// Comments show the syntax to call the routine also see matching header file



// C stubs for "core" library
// These obey the C compiler calling convention (see documentation)
// Comments show the syntax to call the routine also see matching header file


// Interrupt.asm


.MODULE $M.core_c_stubs;
   .CODESEGMENT PM;

// interrupt_initialise();
$_interrupt_initialise:
   jump $interrupt.initialise;


// block_interrupts(); or interrupt_block();
$_interrupt_block:
   jump $interrupt.block;


// unblock_interrupts(); or interrupt_unblock();
$_interrupt_unblock:
   jump $interrupt.unblock;


// interrupt_register(int int_source, int int_priority, void (*IntFunction) (void));
// Registers and interrupt handler for a particular source, and sets the priority as erquired
$_interrupt_register:
   jump $interrupt.register;



// Timer.asm

// timer_schedule_event_at(tTimerStruct *pTimerStruc, int time_absolute, void (*TimerEventFunction) (void));
$_timer_schedule_event_at:
   pushm <r4, r5, rLink>;
   r3 = r2;
   r2 = r1;
   r1 = r0;
   call $timer.schedule_event_at;
   popm <r4, r5, rLink>;
   rts;


// timer_schedule_event_in(tTimerStruct *pTimerStruc, int time_in, void (*TimerEventFunction) (void));
$_timer_schedule_event_in:
   pushm <r4, r5, rLink>;
   r3 = r2;
   r2 = r1;
   r1 = r0;
   call $timer.schedule_event_in;
   popm <r4, r5, rLink>;
   rts;


// timer_schedule_event_in_period(tTimerStruct *pTimerStruc, int time_period, void (*TimerEventFunction) (void));
// Note this function should only be used with a timer structure that has already been
// used previously (e.g. using timer_schedule_event_in)
$_timer_schedule_event_in_period:
   pushm <r4, r5, rLink>;
   call $timer.schedule_event_in_period;
   popm <r4, r5, rLink>;
   rts;


// timer_cancel_event(int event_id);
// Note the event_id is given in timer_struc element 3
$_timer_cancel_event:
   pushm <r4, r5, rLink>;
   r0 = r2;
   call $timer.cancel_event;
   popm <r4, r5, rLink>;
   rts;


// timer_1ms_delay();
$_timer_1ms_delay:
   jump $timer.1ms_delay;


// timer_n_ms_delay(int delay_duration_ms);
$_timer_n_ms_delay:
   push rLink;
   call $timer.n_ms_delay;
   pop rLink;
   rts;


// timer_n_us_delay(int delay_duration_us);
$_timer_n_us_delay:
   push rLink;
   call $timer.n_us_delay;
   pop rLink;
   rts;





// Cbuffer.asm

// cbuffer_initialise();
// Note this should be called after message_initialise();
$_cbuffer_initialise:
   jump $cbuffer.initialise;


// int cbuffer_is_it_enabled();
// Returns "1" if port/buffer is enabled/valid
// Returns "0" if port/buffer is disabled/invalid
$_cbuffer_is_it_enabled:
   push rLink;
   call $cbuffer.is_it_enabled;
   r0 = rFlags AND 0x2;
   r0 = r0 XOR 0x2;
   r0 = r0 LSHIFT -1;
   pop rLink;
   rts;


// cbuffer_get_read_address_and_size(tCbuffer *cbuffer, int * read_address, int * buffer_size);
$_cbuffer_get_read_address_and_size:
   pushm <r1, r2, rLink>;
   call $cbuffer.get_read_address_and_size;
   r2 = M[SP - 3]; // pointer to read_address
   M[r2] = r0;
   r2 = M[SP - 2]; // pointer to buffer_size
   M[r2] = r1;
   popm <r1, r2, rLink>;
   rts;


// cbuffer_get_write_address_and_size(tCbuffer *cbuffer, int * write_address, int * buffer_size);
$_cbuffer_get_write_address_and_size:
   pushm <r1, r2, rLink>;
   call $cbuffer.get_write_address_and_size;
   r2 = M[SP - 3]; // pointer to write_address
   M[r2] = r0;
   r2 = M[SP - 2]; // pointer to buffer_size
   M[r2] = r1;
   popm <r1, r2, rLink>;
   rts;


// cbuffer_set_read_address(tCbuffer *cbuffer, int read_address);
$_cbuffer_set_read_address:
   pushm <r4, r5, rLink>;
   call $cbuffer.set_read_address;
   popm <r4, r5, rLink>;
   rts;


// cbuffer_set_write_address(tCbuffer *cbuffer, int write_address);
$_cbuffer_set_write_address:
   pushm <r4, r5, rLink>;
   call $cbuffer.set_write_address;
   popm <r4, r5, rLink>;
   rts;


// amount_space = cbuffer_calc_amount_space(tCbuffer *cbuffer);
// The amount of space for new data (in words) is returned,
$_cbuffer_calc_amount_space:
   jump $cbuffer.calc_amount_space;


// amount = cbuffer_calc_amount_data(tCbuffer *cbuffer);
// The amount of data already present (in words) is returned
$_cbuffer_calc_amount_data:
   jump $cbuffer.calc_amount_data;


// amount = cbuffer_read(tCbuffer *cbuffer, int* buffer, int size);
// reads data from a cbuffer into 'buffer'.  The amount read is min(size,amount_in_cbuffer), and it is returned in 'amount'.
$_cbuffer_read:
   push rLink;
   push r0;       // save *cbuffer for later (this stack location will hold the return value as well)
   pushm <I0, I2, L0>;
   I2 = r1;
   r10 = r2;
   call $cbuffer.calc_amount_data;
   Null = r10 - r0;
   if POS r10 = r0;
   r0 = M[SP - 4];      // restore cbuffer pointer
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;
   r0 = M[SP - 4];      // restore cbuffer pointer
   M[SP - 4] = r10;     // store the return value in the stack
   do rd_loop;
      r1 = M[I0,1];
      M[I2,1] = r1;     // optimise?
   rd_loop:
   r1 = I0;
   call $cbuffer.set_read_address;
   popm <I0, I2, L0>;
   pop r0;
   pop rLink;
   rts;


// written = cbuffer_write(tCbuffer *cbuffer, int* buffer, int size);
// writes data from a 'buffer' into cbuffer.  The amount written is min(size,space_in_cbuffer), and it is returned in 'written'.
$_cbuffer_write:
   push rLink;
   push r0;       // save *cbuffer for later (this stack location will hold the return value as well)
   pushm <I0, I2, L0>;
   I2 = r1;
   r10 = r2;
   call $cbuffer.calc_amount_space;
   Null = r10 - r0;
   if POS r10 = r0;
   r0 = M[SP - 4];      // restore cbuffer pointer
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   r0 = M[SP - 4];      // restore cbuffer pointer
   M[SP - 4] = r10;     // store the return value in the stack
   do wr_loop;
      r1 = M[I2,1];
      M[I0,1] = r1;     // optimise?
   wr_loop:
   r1 = I0;
   call $cbuffer.set_write_address;
   popm <I0, I2, L0>;
   pop r0;
   pop rLink;
   rts;


// Message.asm

// message_initialise();
$_message_initialise:
   jump $message.initialise;


// message_register_handler(int * message_handler_address_for_this_id, int * message_handler_struc_ptr, int message_id);
$_message_register_handler:
   jump $message.register_handler;


// message_send_ready_wait_for_go();
$_message_send_ready_wait_for_go:
   pushm <r4, r5, rLink>;
   call $message.send_ready_wait_for_go;
   popm <r4, r5, rLink>;
   rts;


// message_send_short(int message_id, int p0, int p1, int p2, int p3);
// payload is in the 4 ints p0-p4, containing the message data
$_message_send_short:
   pushm <r4, r5, r6, rLink>;
   r6 = M[SP - 6];
   r5 = r3;
   r4 = r2;
   r3 = r1;
   r2 = r0;
   call $message.send_short;
   popm <r4, r5, r6, rLink>;
   rts;


// message_send_long(int long_message_id, int long_message_size_words, int * payload_pointer);
// payload contains the number of ints sent in long_message_size_words
$_message_send_long:
   pushm <r4, r5, r6, rLink>;
   // Put the arguments into the correct registers
   r3 = r0;
   r4 = r1;
   r5 = r2;
   call $message.send_long;
   popm <r4, r5, r6, rLink>;
   rts;

.ENDMODULE;


