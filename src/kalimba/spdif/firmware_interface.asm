// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.comes/ Part of ADK 3.5
//
// $Change$  $DateTime$
// $Revision$
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//
//   DSP receives messages from firmware about the status of the spdif Rx
//   stream. Vm needs to enable this feature in order to firmware sending DSP
//   the releavant messages.
//
//   Messages that are processed by DSP are:
//   $MESSAGE_SPDIF_CHNL_STS_EVENT: channel status words for spdif Rx stream
//   $MESSAGE_AUDIO_STREAM_RATE_EVENT: Indicates the rate of audio stream
//   $MESSAGE_SPDIF_BLOCK_START_EVENT: Indicates that the block start has been
//   received
//
// *****************************************************************************
#ifndef SPDIF_FIRMARE_INTERFACE_ASM_INCLUDED
#define SPDIF_FIRMARE_INTERFACE_ASM_INCLUDED
#include "core_library.h"
#include "spdif.h"
#include "spdif_stream_decode.h"

// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.register_spdif_stream_messages_handlers
//
// DESCRIPTION:
//    registering handlers for spdif Rx messages from firmware
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
.MODULE $M.spdif.frame_copy.register_spdif_stream_messages_handlers;
   .CODESEGMENT SPDIF_FRAME_COPY_RGISTER_SPDIF_STREAM_MESSAGE_HANDLERS_PM;
   .DATASEGMENT DM;

   $spdif.frame_copy.register_spdif_stream_messages_handlers:

   // push rLink onto stack
   $push_rLink_macro;

   // set up message handler for  $MESSAGE_SPDIF_CHNL_STS_EVENT fw message
   r1 = &$spdif.frame_copy.chnl_sts_event_message_struc;
   r2 = $MESSAGE_SPDIF_CHNL_STS_EVENT;
   r3 = &$spdif.frame_copy.chnl_sts_event_message_handler;
   call $message.register_handler;

   // set up message handler for $MESSAGE_AUDIO_STREAM_RATE_EVENT firmware message
   r1 = &$spdif.frame_copy.valid_stream_event_message_struc;
   r2 = $MESSAGE_AUDIO_STREAM_RATE_EVENT;
   r3 = &$spdif.frame_copy.valid_stream_event_message_handler;
   call $message.register_handler;

   // set up message handler for $MESSAGE_SPDIF_BLOCK_START_EVENT firmware message
   r1 = &$spdif.frame_copy.block_start_message_struc;
   r2 = $MESSAGE_SPDIF_BLOCK_START_EVENT;
   r3 = &$spdif.frame_copy.block_start_message_handler;
   call $message.register_handler;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.chnl_sts_stream_event_message_handler
//
// DESCRIPTION:
//    handler for $MESSAGE_SPDIF_CHNL_STS_EVENT message from firmware
//
// INPUTS:
//   None
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.chnl_sts_event_message_handler;
   .CODESEGMENT SPDIF_FRAME_COPY_CHNL_STS_EVENT_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

 $spdif.frame_copy.chnl_sts_event_message_handler:
   // push rLink onto stack
   $push_rLink_macro;

   .VAR chts_fs[] = 44100,-1,48000,32000;
   r8 = M[$spdif.frame_copy.frame_copy_struct];
   #ifdef DEBUG_ON
      // number of ports must be 2
      r0 = M[r3 + 0];
      Null = r0 - 2;
      if NZ call $error;

      // check LEFT port
      r1 = M[r3 + 1];
      r2 = M[r8 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
      r2 = r2 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - r2;
      if NZ call $error;

      // check right port
      r1 = M[r3 + 2];
      r2 = M[r8 + $spdif.frame_copy.RIGHT_INPUT_PORT_FIELD];
      r2 = r2 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - r2;
      if NZ call $error;
   #endif

   // extract sampling frequency and audio/data mode bit
   r0 = M[r3 + 3];
   M[r8 + $spdif.frame_copy.CHSTS_FIRST_WORD_FIELD] = r0;
   r0 = r0 AND 0x2;
   r4 = M[r3 + 4];
   r4 = r4 LSHIFT -8;
   r4 = r4 AND 0x3;
   r4 = M[chts_fs + r4];
   r3 = r0 LSHIFT -1;
   M[r8 + $spdif.frame_copy.CHSTS_DATA_MODE_FIELD] = r3;
   M[r8 + $spdif.frame_copy.CHSTS_SAMPLE_RATE_FIELD] = r4;

   #ifdef SPDIF_REPORT_EVENTS
      // channel status received,
      // report changes
      call $spdif.report_event;
   #endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.valid_stream_event_message_handler
//
// DESCRIPTION:
//    handler for $MESSAGE_AUDIO_STREAM_RATE_EVENT message from firmware
//
// INPUTS:
//   None
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.valid_stream_event_message_handler;
   .CODESEGMENT SPDIF_FRAME_COPY_VALID_STREAM_EVENT_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

 $spdif.frame_copy.valid_stream_event_message_handler:
   // push rLink onto stack
   $push_rLink_macro;

   r8 = M[$spdif.frame_copy.frame_copy_struct];

   #ifdef DEBUG_ON
      // number of ports must be 2
      r0 = M[r3 + 0];
      Null = r0 - 2;
      if NZ call $error;

      // check LEFT port
      r1 = M[r3 + 1];
      r2 = M[r8 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
      r2 = r2 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - r2;
      if NZ call $error;

      // check right port
      r1 = M[r3 + 2];
      r2 = M[r8 + $spdif.frame_copy.RIGHT_INPUT_PORT_FIELD];
      r2 = r2 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - r2;
      if NZ call $error;
      #endif

   // extract sample rate and valid flag
   r0 = M[r3 + 3];
   r0 = r0 AND 0xFFFF;
   r1 = M[r3 + 4];
   r1 = r1 LSHIFT 16;
   r3 = r1 + r0;
   M[r8 + $spdif.frame_copy.FW_SAMPLING_FREQ_FIELD] = r3;
#ifdef $spdif.DSP_SPDIF_RATE_MEASUREMENT
   M[r8 + $spdif.frame_copy.RATE_DETECT_HIST_FW_RATE_CHNAGED_FIELD] = r3;
#endif
   call $spdif.frame_copy.process_valid_rate_message;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

   $spdif.frame_copy.process_valid_rate_message:

   // push rLink onto stack
   $push_rLink_macro;

   r3 = M[r8 + $spdif.frame_copy.FW_SAMPLING_FREQ_FIELD];
#ifdef $spdif.DSP_SPDIF_RATE_CHECK
   r0 = M[r8 + $spdif.frame_copy.DSP_SAMPLING_FREQ_FIELD];
   Null = r0 - r3;
   if NZ r3 = 0;
#endif
   Null = r3;
   if Z jump is_invalid;

      // update the sampling rate
      M[r8 + $spdif.frame_copy.SAMPLING_FREQ_FIELD] = r3;

      #ifdef SPDIF_LATENCY_MEASUREMENT
         // calculate inverse sample rate
         // in suitable format for latency measurements
         r0 = r3;
         call $latency.calc_inv_fs;
         M[r8 + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD] = r0;
      #endif

      // stream is valid from fw side, clear related flag
      r4 = M[r8 + $spdif.frame_copy.STREAM_INVALID_FIELD];
      r4 = r4 AND (~$spdif.STREAM_INVALID_FROM_FW);

      // stream is valid
      M[r8 + $spdif.frame_copy.STREAM_INVALID_FIELD] = r4;
      jump message_process_done;

   is_invalid:
      // stream is invalid from fw side, clear related flag
      r4 = 1;
      M[r8 + $spdif.frame_copy.RESET_NEEDED_FIELD] = r4;

   // now invalidate the stream
   r4 = M[r8 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   r4 = r4 OR $spdif.STREAM_INVALID_FROM_FW;
   M[r8 + $spdif.frame_copy.STREAM_INVALID_FIELD] = r4;

   message_process_done:
   #ifdef SPDIF_REPORT_EVENTS
      // report the event
      call $spdif.report_event;
   #endif

   // inform output interface handler of the event
   #ifdef SPDIF_OUTPUT_INTERFACE_CONTROL
       call $spdif.output_interface_control.event_process;
   #endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.frame_copy.block_start_message_handler
//
// DESCRIPTION:
//    handler for $KAL_MSG_BLOCK_START_MESSAGE_ID message from firmware
//
// INPUTS:
//   None
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.frame_copy.block_start_message_handler;
   .CODESEGMENT SPDIF_FRAME_COPY_BLOCK_START_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

 $spdif.frame_copy.block_start_message_handler:
 rts;

.ENDMODULE;

#endif // #ifndef SPDIF_FIRMARE_INTERFACE_ASM_INCLUDED
