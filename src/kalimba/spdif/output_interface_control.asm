// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.comes/ Part of ADK 3.5
//
// $Change$  $DateTime$
// $Revision$
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//
// *****************************************************************************
#ifndef SPDIF_HANDLE_OUTPUT_INTERFACE_ASM_INCLUDED
#define SPDIF_HANDLE_OUTPUT_INTERFACE_ASM_INCLUDED
#include "core_library.h"
#include "spdif.h"
#include "spdif_stream_decode.h"
#ifdef SPDIF_OUTPUT_INTERFACE_CONTROL
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control
//
// DESCRIPTION:
//    controlling output interface in DSP:
//    - rate configuration
//    - smooth activating/deactivating
//    - switching output interface
//  see event process function header for more details
// *****************************************************************************
.MODULE $spdif.output_interface_control;
   .DATASEGMENT DM;

   // defining message structures for fw responses
   .VAR audio_configure_response_message_struc[$message.STRUC_SIZE];       // for $MESSAGE_AUDIO_CONFIGURE_RESPONSE message
   .VAR activate_audio_response_message_struc[$message.STRUC_SIZE];        // for MESSAGE_ACTIVATE_AUDIO_RESPONSE

   // used for general time-out
   .VAR timer_struc[$timer.STRUC_SIZE];

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control.init
//
// DESCRIPTION:
//    initialisations needed for output interface control
//
// INPUTS:
//    None
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.output_interface_control.init;
   .CODESEGMENT SPDIF_OUTPUT_INTERFACE_CONTROL_INIT_PM;
   .DATASEGMENT DM;

   $spdif.output_interface_control.init:

   // push rLink onto stack
   $push_rLink_macro;

   call $block_interrupts;


   // set up message handler for $MESSAGE_AUDIO_CONFIGURE_RESPONSE firmware response message
   r1 = &$spdif.output_interface_control.audio_configure_response_message_struc;
   r2 = $MESSAGE_AUDIO_CONFIGURE_RESPONSE;
   r3 = &$spdif.output_interface_control.audio_configure_response_message_handler;
   call $message.register_handler;

   // set up message handler for $MESSAGE_ACTIVATE_AUDIO_RESPONSE firmware response message
   r1 = &$spdif.output_interface_control.activate_audio_response_message_struc;
   r2 = $MESSAGE_ACTIVATE_AUDIO_RESPONSE;
   r3 = &$spdif.output_interface_control.activate_audio_response_message_handler;
   call $message.register_handler;

   // get input structure
   r8 = M[$spdif.stream_decode.stream_decode_struct];
       
   // get input structure
   r8 = M[$spdif.stream_decode.stream_decode_struct];
   Null = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_INIT_ACTIVE_FIELD];
   if Z jump done;
   
   output_already_active:
      // output is active and we want them to stay active
      r3 = $spdif.STATE_FULL_ACTIVE;
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_PROCESSING_STATE_FIELD] = r3;
      r1 = $spdif.OUTPUT_INTERFACE_STATE_ACTIVE|$spdif.OUTPUT_INTERFACE_STATE_UNMUTE;
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD] = r1;
      // and the rate is expected to be 48khz
      r1 = 48000;
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CURRENT_RATE_FIELD] = r1;
      call $spdif.output_interface_control.event_process;
      jump done;

   deactivate:
      // active interface connected, de activate it  
      r3 = $spdif.STATE_WAIT_OUTPUT_INTERFACE_DEACTIVATE;
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_PROCESSING_STATE_FIELD] = r3;
      r1 = $spdif.OUTPUT_INTERFACE_STATE_ACTIVE;
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD] = r1;
      r4 = 0;
      call $spdif.output_interface_control.activate_interface;
   done:
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control.event_process
//
//
// DESCRIPTION:
//   Handles any interesting event for input (SPDIF) or output (DACs/SPDIF/I2S)
//   interfaces.
//
//   DSP may receive one of this messages from fw:
//
//   1- $KAL_MSG_VALID_STREAM_EVENT_MESSAGE_ID
//      This is by far the most important message that receives from fw. The message
//      says whether SPDIF input stream is valid, and if valid what the rate is. An
//      invalid stream means that the input is no longer valid(DSP doesn't care why)
//      and  the incoming data must be discarded and the output interfaces must be muted
//      and in longer term it must be de-activated. A valid message on the other side
//      means that a valid stream is coming to DSP, however DSP wont start playing the
//      stream at output interface until it receives $KAL_MSG_SPDIF_BLOCK_START_EVENT_MESSAGE_ID
//      message.
//
//   2- $KAL_MSG_CHNL_STS_EVENT_MESSAGE_ID
//      fw sends the channel status info via this message, it includes sample rate and
//      Audio/Data flag. DSP only uses Audio/Data flag.
//
//   3- $KAL_MSG_SPDIF_BLOCK_START_EVENT_MESSAGE_ID
//      Tells DSP that incoming SPDIF stream can be played at the output. DSP wont activate the
//      outputs until it receives this message, however the output sample can be configured
//      even before receiving message (and after receiving valid message)
//
//   4- $KAL_MSG_AUDIO_CONFIGURE_RESPONSE_MESSAGE_ID
//   5- $KAL_MSG_VALID_STREAM_EVENT_MESSAGE_ID
//      These two are confirmation response to DSP messages, DSP wont handle any event
//      until all pending confirmations have been received from fw.
//
//   An example of interaction between DSP and Fw:
//
//                  FW                                              DSP
//    -> spdif connected
//                  |    STREAM VALID, SAMPLE RATE = 48000          |
//                  |---------------------------------------------->|
//                  |                                               |
//                  |  CONFIGURE OUTPUT INTERFACE DAC0 RATE=48000   |  <-- DSP tries to set the DAC rates
//                  |<----------------------------------------------|
//                  |  CONFIGURE OUTPUT INTERFACE DAC1 RATE=48000   |
//                  |<--------------------------------------------- |
//                  |                                               |
//                  | CONFIGURE DAC0 RATE RESPONSE, SUCCESS         |
//                  |---------------------------------------------->|
//                  | CONFIGURE DAC1 RATE RESPONSE, SUCCESS         |
//                  |---------------------------------------------->|
//                  |                                               |
//                  | BLOCK START MESSAGE                           |
//                  |---------------------------------------------->|
//                  |                                               |
//                  |  ACTIVATE OUTPUT INTERFACE DAC0               |
//                  |<----------------------------------------------| <-- DSP tries to unmute DACs
//                  |  ACTIVATE OUTPUT INTERFACE DAC1               |
//                  |<----------------------------------------------|
//                  |                                               |
//                  | ACTIVATE DAC0 RESPONSE, SUCCESS               |
//                  |---------------------------------------------->|
//                  | ACTIVATE DAC1 RESPONSE, SUCCESS               |
//                  |---------------------------------------------->|
//                  |                                               |
//                  |                                               |
//                  |                                               |
//                  |  UNMUTE OUTPUT INTERFACE DAC0                 |
//                  |<----------------------------------------------|  <-- DSP tries to activate DACs
//                  |  UNMUTE OUTPUT INTERFACE DAC1                 |
//                  |<----------------------------------------------|
//                  |                                               |
//                  | UNMUTE DAC0 RESPONSE, SUCCESS                 |
//                  |---------------------------------------------->|
//                  | UNMUTE DAC1 RESPONSE, SUCCESS                 |
//                  |---------------------------------------------->|
//                                                                  |  <-- full active interface
//   spdif disconnected
//
//                  |    STREAM IVALID                              |
//                  |---------------------------------------------->|
//                  |                                               | <-- DSP starts fading out on whatever left to play
//                  |                                               |
//                  |  MUTE OUTPUT INTERFACE DAC0                   |
//                  |<----------------------------------------------| <-- DSP tries to mute DACs
//                  |  MUTE OUTPUT INTERFACE DAC1                   |
//                  |<----------------------------------------------|
//                  |                                               |
//                  | MUTE DAC0 RESPONSE, SUCCESS                   |
//                  |---------------------------------------------->|
//                  | MUTE DAC1 RESPONSE, SUCCESS                   |
//                  |---------------------------------------------->|
//                  |                                               |
//                  |                                               |
//                  |  DE-ACTIVATE OUTPUT INTERFACE DAC0            |
//                  |<----------------------------------------------| <-- DSP tries to deactivate DACs
//                  |  DE-ACTIVATE OUTPUT INTERFACE DAC1            |
//                  |<----------------------------------------------|
//                  |                                               |
//                  | DE-ACTIVATE DAC0 RESPONSE, SUCCESS            |
//                  |---------------------------------------------->|
//                  | DE-ACTIVATE DAC1 RESPONSE, SUCCESS            |
//                  |---------------------------------------------->|
//                  |                                               |
//                  |                                               | <-- Idle interface
//
// INPUTS:
//
//
// OUTPUTS:
//
//
// TRASHED REGISTERS:
//    assume everything
// ********************************************************************************
.MODULE $M.spdif.output_interface_control.event_process;
   .CODESEGMENT SPDIF_OUTPUT_INTERFACE_CONTROL_EVENT_PROCESS_PM;
   .DATASEGMENT DM;

   $spdif.output_interface_control.event_process:

   // push rLink onto stack
   $push_rLink_macro;

   // get input structure
   r8 = M[$spdif.stream_decode.stream_decode_struct];
   r7 = M[r8 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];

   // exit immediately if not all confirmations responded yet
   Null = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD];
   if NZ jump $pop_rLink_and_rts;

   // see if output interface is valid
   Null = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_FIELD];
   if NZ jump valid_output_interface;

   // If the output interface type is $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_NONE
   // theng there will be no interaction with firmware, and the interface can go
   // full active immediately
   output_interface_none:
   r3 = M[r7 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   NULL = r3 AND $spdif.STREAM_INVALID_SWITCHING;
   if NZ jump switching_from_none;

   // for NONE type, always full active regardless of input state
   force_full_active:
   r0 = $spdif.OUTPUT_INTERFACE_STATE_ACTIVE |
        $spdif.OUTPUT_INTERFACE_STATE_UNMUTE;
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD] = r0;
   r3 = $spdif.STATE_FULL_ACTIVE;
   jump end;

   // it's NONE now, but switching to valid output interface
   // doesn't need deactivation process for current interface
   switching_from_none:
   r0 = $spdif.OUTPUT_INTERFACE_STATE_FADING_DONE;
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD] = r0;
   jump switch_to_new_interface;

   // input interface is valid
   valid_output_interface:
   // Decision on what to do is based on the following parameters
   //   -latest state of input port, valid or invalid
   //   -current state of output interface (active/deactive, mute/unmute, etc)
   //   -sampling rate changed or not
   // valid or invalid?
   r0 = M[r7 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   r1 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD];
   r0 = r0 AND (~$spdif.STREAM_INVALID_FROM_FW);
   if NZ jump stream_is_invalid;

   // input stream is valid
   stream_is_valid:

   // if in fading out mode, have to wait until it ends
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_FADING;
   if NZ jump $pop_rLink_and_rts;

   check_output_rate:
   // output rate = setting_rate if setting_rate !=0 else input_rate
   // also when input rate is rare 32khz, we use more common rate of
   // 48khz at the output
   r3 = 48000;
   r2 = M[r7 + $spdif.frame_copy.SAMPLING_FREQ_FIELD];
   Null = r2 - 44100;
   if NEG r2 = r3;
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_SETTING_RATE_FIELD];
   if NZ r2 = r3;

   // check see whether rate has changed, if so config rates
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CONFIG_RATE_FIELD] = r2;
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CURRENT_RATE_FIELD];
   Null = r3 - r2;
   if NZ jump start_config_rates;

   stream_valide_rates_fine:
   // rates are fine, if not active then activate the output interface
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_ACTIVE;
   if Z jump start_activating_output_interface;

   stream_valid_output_interface_active:
   // output interface is active, it must be unmuted
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_UNMUTE;
   if Z jump start_unmting_output_interface;
   //  disable soft mute
   r3 = 1;
   r2 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FADING_DIRECTION_PTR_FIELD];
   if NZ M[r2] = r3;

   // otherwise we should be full active, it normally shouldn't come
   // to this point, but for state recovery this is needed
   r3 = $spdif.STATE_FULL_ACTIVE;
   jump end;

   start_unmting_output_interface:
   // unmuting output interfaces by sending config message to fw
   r4 = 0x700;
   r5 = 0;
   call $spdif.output_interface_control.configure_interface;
   r3 = $spdif.STATE_WAIT_OUTPUT_INTERFACE_UNMUTE;
   jump end;

   start_activating_output_interface:
   // activating output interfaces by sending message to fw
   r4 = 1;
   call $spdif.output_interface_control.activate_interface;
   r3 = $spdif.STATE_WAIT_OUTPUT_INTERFACE_ACTIVATE;
   jump end;

   start_config_rates:
   // output interface has to be deactivated when rate is configured,
   // if active it needs to be de-activated first
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_ACTIVE;
   if NZ jump stream_is_invalid_output_interface_active;

   // config words for different type of output interfaces
   .VAR rate_config [] = 0,
                         0x301,     // DACs
                         0x201,     // I2S
                         0x500,     // SPDIF
                         0;
   r5 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CONFIG_RATE_FIELD];
   r4 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_FIELD];
   r4 = M[r4 + rate_config];
   if Z call $error;
   call $spdif.output_interface_control.configure_interface;
   r3 = $spdif.STATE_WAIT_OUTPUT_INTERFACE_RATE;
   jump end;

   stream_is_invalid:
   // stream can be invalid for various reasons: directly by
   // firmware via message, or because of switching the output
   // interface or because the start message has not yet received.
   //
   // in any case it needs to move towards becoming
   // idle, but before that we need to make sure that everything is
   // ready to become idle

   // if invalid only because start message has not yet received
   // then we can configure the output rate, as we expect to receive
   // the start message soon
   // start fading out, it might have already started
   r3 = -1;
   r2 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FADING_DIRECTION_PTR_FIELD];
   if NZ M[r2] = r3;

   // if already in-active output, can go to idle now
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_ACTIVE;
   if Z jump go_idle;

   stream_is_invalid_output_interface_active:
   // output is active, see if fading out period has finished
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_FADING_DONE;
   if Z jump start_fading_process;

   stream_is_invalid_output_interface_fading_done:
   // output active, fading finished, see if it also muted
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_UNMUTE;
   if NZ jump start_muting_process;

   stream_is_invalid_output_interface_mute:
   start_deactivating_output_interface:
   // everything is ready to start de-activating output interface
   r4 = 0;
   call $spdif.output_interface_control.activate_interface;
   r3 = $spdif.STATE_WAIT_OUTPUT_INTERFACE_DEACTIVATE;
   jump end;

   start_muting_process:
   // mute the interface by sending message to fw
   r4 = 0x700;
   r5 = 1;
   call $spdif.output_interface_control.configure_interface;
   r3 = $spdif.STATE_WAIT_OUTPUT_INTERFACE_MUTE;
   jump end;

   start_fading_process:
   // fading is done by setting the soft mute operator direction
   // and schedule a new event in 5ms
   Null = r1 AND $spdif.OUTPUT_INTERFACE_STATE_FADING;
   if NZ jump set_fading_state;
   // go to fading state
   r1 = r1 OR $spdif.OUTPUT_INTERFACE_STATE_FADING;
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD] = r1;
   r1 = &$spdif.output_interface_control.timer_struc;
   r2 = $spdif.OUTPUT_INTERFACE_FADE_OUT_TIME_MS*1000;
   r3 = &$spdif.output_interface_control.all_confirms_received;
   call $timer.schedule_event_in;
   r3 = -1;
   r2 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FADING_DIRECTION_PTR_FIELD];
   if NZ M[r2] = r3;

   set_fading_state:
   // it will state in fading mode until timer expires
   r3 = $spdif.STATE_OUTPUT_INTERFACE_FADING_OUT;
   jump end;

   go_idle:
   // it can go idle now, but check whether invalidity is
   // due to output interface switch request
   r3 = M[r7 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   NULL = r3 AND $spdif.STREAM_INVALID_SWITCHING;
   if Z jump switch_done;
   switch_to_new_interface:

      // output interface switch has been requested, copy new
      // interface info
      r2 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_NEW_TYPE_FIELD];
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_FIELD] = r2;

      r2 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_NEW_LEFT_PORT_FIELD];
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_LEFT_PORT_FIELD] = r2;

      r2 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_NEW_RIGHT_PORT_FIELD];
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_RIGHT_PORT_FIELD] = r2;

      r3 = r3 AND (~$spdif.STREAM_INVALID_SWITCHING);
      M[r7 + $spdif.frame_copy.STREAM_INVALID_FIELD] = r3;
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CURRENT_RATE_FIELD] = 0;

      // create an immediate even to see whether it can switch to
      // new output interface
      r1 = &$spdif.output_interface_control.timer_struc;
      r2 = 0;
      r3 = &$spdif.output_interface_control.event_process;
      call $timer.schedule_event_in;

   switch_done:
   // go to idle now
   r3 = $spdif.STATE_IDLE;
   jump end;

   end:
   // set the new state
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_PROCESSING_STATE_FIELD] = r3;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control.response_message_handler
//
// DESCRIPTION:
//    handler for $MESSAGE_AUDIO_CONFIGURE_RESPONSE and
//    $MESSAGE_ACTIVATE_AUDIO_RESPONSE messages from firmware
//
// INPUTS:
//   r1 = port number
//   r2 = response (0 means failure)
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.output_interface_control.response_message_handler;
   .CODESEGMENT SPDIF_OUTPUT_INTERFACE_CONTROL_RESPONSE_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

   $spdif.output_interface_control.audio_configure_response_message_handler:
   $spdif.output_interface_control.activate_audio_response_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // get input structure
   r8 = M[$spdif.stream_decode.stream_decode_struct];

   // decrement pending responses counter
   call $spdif.output_interface_control.decrement_pending_confirms;

   // A failure is fatal
   Null = r2;
   if Z call $error;

   // let state machine knows if all pending responses received
   Null =  M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD];
   if Z call $spdif.output_interface_control.all_confirms_received;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control.all_confirms_received
//
// DESCRIPTION:
//   Does the proper operation when confirmations to DSP messages are received
//   from fw. It generates error if confirmation is received unexpectedly, i.e.
//   in a state that DSP is not waiting for confirmations.
//
// INPUTS:
//   None
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.output_interface_control.all_confirms_received;
   .CODESEGMENT SPDIF_OUTPUT_INTERFACE_CONTROL_ALL_CONFIRMS_RECEIVED_PM;
   .DATASEGMENT DM;

   $spdif.output_interface_control.all_confirms_received:

   // push rLink onto stack
   $push_rLink_macro;

   .VAR confirm_table[] = confirm_error,
                          output_interface_rate_done,
                          output_interface_activation_done,
                          confirm_error,
                          output_interface_fading_done,
                          output_interface_deactivation_done,
                          output_interface_mute_done,
                          output_interface_unmute_done;

   r8 = M[$spdif.stream_decode.stream_decode_struct];
   r1 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_PROCESSING_STATE_FIELD];
   r4 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD];
   r1 = M[confirm_table + r1];
   jump r1;

   // IDLE and FULL_ACTIVE states
   confirm_error:
   call $error;

   // WAIT_OUTPUT_INTERFACE_RATE
   output_interface_rate_done:
      r0 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CONFIG_RATE_FIELD];
      M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_CURRENT_RATE_FIELD] = r0;
   jump end_confirm;

   // WAIT_OUTPUT_INTERFACE_ACTIVATE
   output_interface_activation_done:
      r4 = r4 OR $spdif.OUTPUT_INTERFACE_STATE_ACTIVE;
      r4 = r4 AND ~($spdif.OUTPUT_INTERFACE_STATE_FADING_DONE);
   jump end_confirm;

   // OUTPUT_INTERFACE_FADING_OUT
   output_interface_fading_done:
      r4 = r4 OR $spdif.OUTPUT_INTERFACE_STATE_FADING_DONE;
      r4 = r4 AND (~$spdif.OUTPUT_INTERFACE_STATE_FADING);
   jump end_confirm;

   // WAIT_OUTPUT_INTERFACE_DEACTIVATE
   output_interface_deactivation_done:
      r4 = r4 AND (~$spdif.OUTPUT_INTERFACE_STATE_ACTIVE);
   jump end_confirm;

   // WAIT_OUTPUT_INTERFACE_MUTE
   output_interface_mute_done:
      r4 = r4 AND (~$spdif.OUTPUT_INTERFACE_STATE_UNMUTE);
   jump end_confirm;

   // WAIT_OUTPUT_INTERFACE_UNMUTE
   output_interface_unmute_done:
      r4 = r4 OR ($spdif.OUTPUT_INTERFACE_STATE_UNMUTE);
   jump end_confirm;

   end_confirm:
   // set the latest state of output interface and call the event handler
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD] = r4;

   // all confirms received and updates done, now run event handler
   call $spdif.output_interface_control.event_process;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

   $spdif.output_interface_control.increment_pending_confirms:
   r0 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD];
   r0 = r0 + 1;
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD]= r0;
   rts;

   $spdif.output_interface_control.decrement_pending_confirms:
   r0 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD];
   r0 = r0 - 1;
   M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD]= r0;
   rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control.configure_interface
//
// DESCRIPTION:
//    Sending message to fw to configure output interface ports,
//    this message is used for both muting/unmuting and also
//    for configuring the rate of output interface.
//
// INPUTS:
//   r8 = input structure structure
//   r4, r5: first and second word of config message
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.output_interface_control.configure_interface;
   .CODESEGMENT SPDIF_OUTPUT_INTERFACE_CONTROL_CONFIGURE_INTERFACE_PM;
   .DATASEGMENT DM;

   $spdif.output_interface_control.configure_interface:

   // push rLink onto stack
   $push_rLink_macro;

   // save structure in stack
   push r8;

   // block interrupts (normally already blocked)
   call $block_interrupts;

   // configure LEFT port
   r2 = $MESSAGE_AUDIO_CONFIGURE;
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_LEFT_PORT_FIELD];
   r3 = r3 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   r6 = 0;
   push r4;
   push r5;
   call $message.send_short;
   pop r5;
   pop r4;

   // increment pending confirms
   call $spdif.output_interface_control.increment_pending_confirms;

   // see if RIGHT port is non 0
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_RIGHT_PORT_FIELD];
   if Z jump end;

   // configure RIGHT port
   r2 = $MESSAGE_AUDIO_CONFIGURE;
   r3 = r3 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   r6 = 0;
   call $message.send_short;

   // increment pending confirms
   call $spdif.output_interface_control.increment_pending_confirms;

   end:
   call $unblock_interrupts;

   // restore input structure
   pop r8;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.output_interface_control.activate_interface
//
// DESCRIPTION:
//    Sending message to fw to activate/de-activate
//    output interface ports
//
// INPUTS:
//   r8 = input structure structure
//   r4 = 0/1 activate/de-activate
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.output_interface_control.activate_interface;
   .CODESEGMENT SPDIF_OUTPUT_INTERFACE_CONTROL_ACTIVATE_INTERFACE_PM;
   .DATASEGMENT DM;

   $spdif.output_interface_control.activate_interface:

   // push rLink onto stack
   $push_rLink_macro;

   // save structure in stack
   push r8;

   // block interrupts (normally already blocked)
   call $block_interrupts;

   // activate LEFT port
   r2 = $MESSAGE_ACTIVATE_AUDIO;
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_LEFT_PORT_FIELD];
   r3 = r3 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   r5 = 0;
   r6 = 0;
   push r4;
   call $message.send_short;
   pop r4;

   // increment pending confirms
   call $spdif.output_interface_control.increment_pending_confirms;

   // see if RIGHT port is non 0
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_RIGHT_PORT_FIELD];
   if Z jump end;

   // activate RIGHT port
   r2 = $MESSAGE_ACTIVATE_AUDIO;
   r3 = M[r8 + $spdif.stream_decode.OUTPUT_INTERFACE_RIGHT_PORT_FIELD];
   r3 = r3 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   r5 = 0;
   r6 = 0;
   call $message.send_short;

   // increment pending confirms
   call $spdif.output_interface_control.increment_pending_confirms;

   end:
   call $unblock_interrupts;
   pop r8;
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif // #ifdef STIFF_OUTPUT_INTERFACE_CONTROL
#endif // #ifndef SPDIF_HANDLE_OUTPUT_INTERFACES_ASM_INCLUDED
