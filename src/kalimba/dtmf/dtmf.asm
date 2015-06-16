// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Revision$  $Date$
// *****************************************************************************

// *****************************************************************************
// NAME:
//    DTMF tone generation library
//
// DESCRIPTION:
//    This library contains function to initialise routines, receive messages
//    and generate DTMF tones. These tones can then be inserted into data
//    streams such as audio SCO streams.
//
//    The library is initialised by calling $dtmf.initialise and passing the
//    address of a DTMF structure in r8. Subsequent requests from the VM in the
//    form of messages are received, queued if necessary, converted into tone
//    sequences and written into a cbuffer.
//
// *****************************************************************************

#ifndef DTMF_INCLUDED
#define DTMF_INCLUDED

#include "stack.h"
#include "message.h"
#include "kalimba_standard_messages.h"
#include "dtmf.h"

.MODULE $dtmf;
   .DATASEGMENT DM;

   .VAR struc_address;

   .VAR tone_frequencies[$dtmf.NUM_KEYS] =
        (1336 << 12)   +  941,   // Button '0'
        (1209 << 12)   +  697,   // Button '1'
        (1336 << 12)   +  697,   // Button '2'
        (1477 << 12)   +  697,   // Button '3'
        (1209 << 12)   +  770,   // Button '4'
        (1336 << 12)   +  770,   // Button '5'
        (1477 << 12)   +  770,   // Button '6'
        (1209 << 12)   +  852,   // Button '7'
        (1336 << 12)   +  852,   // Button '8'
        (1477 << 12)   +  852,   // Button '9'
        (1209 << 12)   +  941,   // Button '*'
        (1477 << 12)   +  941,   // Button '#'
        (1633 << 12)   +  697,   // Button 'A'
        (1633 << 12)   +  770,   // Button 'B'
        (1633 << 12)   +  852,   // Button 'C'
        (1633 << 12)   +  941;   // Button 'D'

   // allocate memory for new tone message handler
   .VAR new_tone_message_struc[$message.STRUC_SIZE];

.ENDMODULE;

.MODULE $M.dtmf.parameters.8kHz;
   .DATASEGMENT DM;

   .VAR $dtmf.parameters.8kHz[$dtmf.parameters.STRUC_SIZE] =
        (1<<24)/8000,   // phase step size per Hz
        8,              // samples per ms
        1600,           // number of tone samples = 0.2secs * 8kHz
        480,            // number of silence samples = 60msecs * 8kHz
        3500;           // timer period (msecs)

.ENDMODULE;

.MODULE $M.dtmf.parameters.16kHz;
   .DATASEGMENT DM;

   .VAR $dtmf.parameters.16kHz[$dtmf.parameters.STRUC_SIZE] =
        (1<<24)/16000,  // phase step size per Hz
        16,             // samples per ms
        3200,           // number of tone samples = 0.2secs * 16kHz
        960,            // number of silence samples = 60msecs * 16kHz
        3500;           // timer period (msecs)

.ENDMODULE;

.MODULE $M.dtmf.parameters.32kHz;
   .DATASEGMENT DM;

   .VAR $dtmf.parameters.32kHz[$dtmf.parameters.STRUC_SIZE] =
        (1<<24)/32000,  // phase step size per Hz
        32,             // samples per ms
        6400,           // number of tone samples = 0.2secs * 32kHz
        1920,           // number of silence samples = 60msecs * 32kHz
        3500;           // timer period (msecs)

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $dtmf.initialise
//
// DESCRIPTION:
//    This routine initialises the DTMF library. It registers
//    $dtmf.received_message_handler to receive messages from the VM,
//    initialises the supplied DTMF structure and stores the address of the
//    structure.
//
// INPUTS:
//    - r8 = pointer to dtmf structure to use
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0, r1, r2, r3,
//
// *****************************************************************************
.MODULE $M.dtmf.initialise;
   .CODESEGMENT DTMF_INITIALIZE_PM;
   .DATASEGMENT DM;

   $dtmf.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // save the structure address
   M[$dtmf.struc_address] = r8;

   r1 = &$dtmf.new_tone_message_struc;
   r2 = $MESSAGE_DTMF_NEW_TONE_MESSAGE_ID;
   r3 = &$dtmf.received_message_handler;
   call $message.register_handler;

   // reset the stack
   r0 = r8 + $dtmf.STACK_START_OFFSET;
   M[r8 + $dtmf.STACK_READ_POINTER_FIELD] = r0;
   M[r8 + $dtmf.STACK_WRITE_POINTER_FIELD] = r0;

   //pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $dtmf.received_message_handler
//
// DESCRIPTION:
//    Message handler routine to receive messages from the VM, determine the
//    DTMF frequencies corresponding to the key press and store them on the
//    stack. If they are the only entries on the stack call $dtmf.make_tones
//    routine.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0, r1, r2, r3, r3, r5, r8
//
// NOTES:
//    The routine is registered as a message handler by $dtmf.initialise.
// @verbatim
//    r1 = Tone to play
//    r2 = Tone duration (ms)
//    r3 = Silence duration (ms)
// @endverbatim
//
// *****************************************************************************
.MODULE $M.dtmf.received_message_handler;
   .CODESEGMENT DTMF_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

   $dtmf.received_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // get the structure address
   r8 = M[$dtmf.struc_address];

   // get the address of the parameters structure
   r4 = M[r8 + $dtmf.PARAMETERS_FIELD];

   // get the sample rate
   r5 = M[r4 + $dtmf.parameters.SAMPLES_PER_MS_FIELD];  
   // and the default number of samples
   r6 = M[r4 + $dtmf.parameters.TONE_DURATION_FIELD];
   r7 = M[r4 + $dtmf.parameters.SILENCE_DURATION_FIELD];

   // convert from ms to samples
   r2 = r2 * r5 (int) (sat);
   if NZ r6 = r2;
   r3 = r3 * r5 (int) (sat);
   if NZ r7 = r3;


   // get the frequencies for the key ID held in r1
   r2 = M[$dtmf.tone_frequencies + r1];

   // unpack the two frequencies
   r3 = r2 AND 0x000FFF;
   r2 = r2 LSHIFT -12;

   // get the frequency to phase multipliers
   r5 = M[r4 + $dtmf.parameters.PHASE_STEP_PER_HZ_FIELD];

   r3 = r3 * r5 (int);
   r4 = r2 * r5 (int);

   // calculate the amount of space in the stack
   r0 = M[r8 + $dtmf.STACK_WRITE_POINTER_FIELD];
   r1 = M[r8 + $dtmf.STACK_READ_POINTER_FIELD];
   r2 = $dtmf.STACK_SIZE;

   r1 = r1 - r0;
   if LE r1 = r1 + r2;

   Null = r1 - 2;
   if LE jump exit;

   // store the row and column frequencies on the stack
   M[r0] = r3;
   M[r0 + 1] = r4;

   // update the stack write pointer
   r0 = r0 + 2;
   r1 = r8 + $dtmf.STACK_END_OFFSET;
   r2 = $dtmf.STACK_START_OFFSET;

   Null = r0 - r1;
   if POS r0 = r8 + r2;

   M[r8 + $dtmf.STACK_WRITE_POINTER_FIELD] = r0;

   // calculate the amount of data on the stack
   r1 = M[r8 + $dtmf.STACK_READ_POINTER_FIELD];
   r2 = $dtmf.STACK_SIZE;

   r0 = r0 - r1;
   if NEG r0 = r0 + r2;

   // generate the tone if there are no other tones waiting in the queue
   r0 = r0 - 2;
   if NZ jump exit;
      M[r8 + $dtmf.TONES_LEFT_TO_GENERATE_FIELD] = r6;
      M[r8 + $dtmf.SILENCE_LEFT_TO_GENERATE_FIELD] = r7;
      // make the tones
      call $dtmf.make_tones;

   exit:

   //pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $dtmf.make_tones
//
// DESCRIPTION:
//    Routine to generate DTMF tones and following silence data.
//
// INPUTS:
//    - r8 = pointer to dtmf structure to use
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0, r1, r2, r3, r4, r5, r6, r7, r8, r10, I0, I1, L1, M1, DoLoop,
//
// NOTES:
//    Do not call directly $dtmf.initialise will register a message handler
//    which will in turn call $dtmf.make_tones as required.
//
// *****************************************************************************
.MODULE $M.dtmf.make_tones;
   .CODESEGMENT DTMF_MAKE_TONES_PM;
   .DATASEGMENT DM;

   $dtmf.make_tones:

   // push rLink onto stack
   $push_rLink_macro;

   // get the structure address
   r8 = M[$dtmf.struc_address];

   // how much space is there for tone or silence data?
   r0 = M[r8 + $dtmf.TONE_IN_CBUFFER_STRUC_FIELD];
   call $cbuffer.calc_amount_space;

   // if none then check the amount of space again later
   r10 = r0;
   if Z jump set_timer_and_exit;

   // has all the required tone data been generated?
   r1 = M[r8 + $dtmf.TONES_LEFT_TO_GENERATE_FIELD];
   if Z jump generate_silence;

   // is this the last set of tone data to be generated?
   r2 = r1 - r10;
   if POS jump not_last_generate;
      r10 = r1;
      r2 = 0;
   not_last_generate:

   // update the counters
   M[r8 + $dtmf.TONES_LEFT_TO_GENERATE_FIELD] = r2;

   // get the read address of the message stack
   r0 = M[r8 + $dtmf.STACK_READ_POINTER_FIELD];
   I2 = r0;

   // get the current phases
   r4 = M[r8 + $dtmf.CURRENT_PHASE_FREQ_1_FIELD];
   r5 = M[r8 + $dtmf.CURRENT_PHASE_FREQ_2_FIELD];

   // get the write address of the cbuffer for tone data
   r0 = M[r8 + $dtmf.TONE_IN_CBUFFER_STRUC_FIELD];
   call $cbuffer.get_write_address_and_size;
   I1 = r0;
   L1 = r1;

   M1 = 1;

   // r6 used to saturate additions
   r6 = 0x800000;

   do loop_tones;

      // generate the next sample value for frequency 1
      r0 = r4;
      call $math.sin;

      // get the volume
      r2 = M[r8 + $dtmf.VOL_FIELD];

      // apply the volume and get the phase increment
      r7 = r1 * r2 (frac),
       r3 = M[I2, M1];

      // increment the phase
      r4 = r4 + r3;

      // generate the next sample value for frequency 2
      r0 = r5;
      call $math.sin;

      // get the volume
      r2 = M[r8 + $dtmf.VOL_FIELD];

      // apply the volume and get the phase increment
      r1 = r1 * r2 (frac),
       r3 = M[I2, -1];

      // increment the phase
      r5 = r5 + r3;

      // sum the two samples and saturate if required
      r0 = r7 + r1;
      if V r0 = r0 * r6 (int) (sat);
      r0 = r0 ASHIFT -8;
      // store the result
      M[I1, 1] = r0;

   loop_tones:


   // update the cbuffer write pointer
   r0 = M[r8 + $dtmf.TONE_IN_CBUFFER_STRUC_FIELD];
   r1 = I1;
   call $cbuffer.set_write_address;
   L1 = 0;

   // update the current phases
   M[r8 + $dtmf.CURRENT_PHASE_FREQ_1_FIELD] = r4;
   M[r8 + $dtmf.CURRENT_PHASE_FREQ_2_FIELD] = r5;

   // if there is more tone data to be generated then set a timer to generate more
   Null = M[r8 + $dtmf.TONES_LEFT_TO_GENERATE_FIELD];
   if NZ jump set_timer_and_exit;

   // else - how much space is there for silence data?
   r0 = M[r8 + $dtmf.TONE_IN_CBUFFER_STRUC_FIELD];
   call $cbuffer.calc_amount_space;

   // if none then check the amount of space again later
   r10 = r0;
   if Z jump set_timer_and_exit;

   generate_silence:

   // is this the last set of silence data to be generated?
   r1 = M[r8 + $dtmf.SILENCE_LEFT_TO_GENERATE_FIELD];
   r2 = r1 - r10;
   if POS jump not_last_generate_silence;
      r10 = r1;
      r2 = 0;
   not_last_generate_silence:

   // update the counters
   M[r8 + $dtmf.SILENCE_LEFT_TO_GENERATE_FIELD] = r2;

   // get the write address of the cbuffer for silence data
   r0 = M[r8 + $dtmf.TONE_IN_CBUFFER_STRUC_FIELD];
   call $cbuffer.get_write_address_and_size;
   I1 = r0;
   L1 = r1;

   // r4 used to hold the silence sample value
   r4 = 0;

   do loop_silence;
        M[I1,1] =  r4;
   loop_silence:


   // update the cbuffer write pointer
   r0 = M[r8 + $dtmf.TONE_IN_CBUFFER_STRUC_FIELD];
   r1 = I1;
   call $cbuffer.set_write_address;
   L1 = 0;

   // if there is more silence data to be generated then set a timer to generate more
   Null = M[r8 + $dtmf.SILENCE_LEFT_TO_GENERATE_FIELD];
   if NZ jump set_timer_and_exit;

   // if we are here we have played all the tone and silence data for
   // one message, are there any more messages in the queue

   // get the read address of the message stack
   r0 = M[r8 + $dtmf.STACK_READ_POINTER_FIELD];
   // increment by the number we have just read
   r0 = r0 + 2;

   r1 = r8 + $dtmf.STACK_END_OFFSET;
   r2 = $dtmf.STACK_START_OFFSET;

   Null = r0 - r1;
   if POS r0 = r8 + r2;

   M[r8 + $dtmf.STACK_READ_POINTER_FIELD] = r0;

   // is there any more messages in the stack?
   r1 = M[r8 + $dtmf.STACK_WRITE_POINTER_FIELD];

   Null = r1 - r0;
   // if the stack is empty don't set another timer
   if Z jump exit_no_timer;

   // reset the counts of tone and silence data to be generated
   r5 = M[r8 + $dtmf.PARAMETERS_FIELD];
   r0 = M[r5 + $dtmf.parameters.TONE_DURATION_FIELD];
   M[r8 + $dtmf.TONES_LEFT_TO_GENERATE_FIELD] = r0;

   r0 = M[r5 + $dtmf.parameters.SILENCE_DURATION_FIELD];
   M[r8 + $dtmf.SILENCE_LEFT_TO_GENERATE_FIELD] = r0;
   
   set_timer_and_exit:

   // set another timer
   r5 = M[r8 + $dtmf.PARAMETERS_FIELD];
   r1 = M[r8 + $dtmf.TONE_TIMER_STRUC_FIELD];
   r2 = M[r5 + $dtmf.parameters.TIMER_PERIOD_FIELD];
   r3 = &$dtmf.make_tones;
   call $timer.schedule_event_in;

   exit_no_timer:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif