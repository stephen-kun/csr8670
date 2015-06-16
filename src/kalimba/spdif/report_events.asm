// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.comes/ Part of ADK 3.5
//
// $Change$  $DateTime$
// $Revision$
// *****************************************************************************
// *****************************************************************************
// DESCRIPTION
//   Reporting SPDIF input events to VM
// *****************************************************************************
#ifndef SPDIF_REPORT_EVENTS_ASM_INCLUDED
#define SPDIF_REPORT_EVENTS_ASM_INCLUDED
#include "core_library.h"
#include "spdif.h"
#include "spdif_stream_decode.h"
#ifdef SPDIF_REPORT_EVENTS
// *****************************************************************************
// MODULE:
//    $spdif.report_event
//
// DESCRIPTION:
//    This function is called whenever an interesting event happens for the
//    spdif input interface. shall be called only when one of the following
//    events happens:
//
//      - spdif becomes active
//      - spdif becomes inactive
//      - data type of spdif stream changes
//      - sample rate of spdif stream changes
//      - spdif channel status changes
//    format of sent message:
//       - Word0
//         bit0: input is active(valid) or inactive(invalid)
//               0 -> valid
//               1 -> invalid (the rest of message shall be ignored)
//               bit 1:15 -> reserved
//        - Word1: sampling rate in Hz
//        - Word2:
//             bit 0:7: first byte of channel status
//             bit 8:15: reserved
//        - Word3: codec type
//          bit 0:4: data type
//          bit 5:15: reserved
//
//   INPUTS:
//      None
//
//   OUTPUTS:
//      None
//
//   TRASHED REGISTERS:
//   r0-r7, r10, DoLoop
// *****************************************************************************
.MODULE $M.spdif.report_event;

   .CODESEGMENT SPDIF_REPORT_EVENT_PM;
   .DATASEGMENT DM;
   $spdif.report_event:

   // push rLink onto stack
   $push_rLink_macro;

   push r8;
   // get the input structure
   r8 = M[$spdif.stream_decode.stream_decode_struct];
   r7 = M[r8 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];

   // see if this feature is enabled
   Null = M[r7 + $spdif.frame_copy.ENABLE_EVENT_REPORT_FIELD];
   if Z jump end;

   // default params for invalid stream
   r5 = 0;
   r6 = 0;
   r4 = 0;
   r2 = $SPDIF_EVENT_MSG;
   r3 = M[r7 + $spdif.frame_copy.STREAM_INVALID_FIELD];
   r3 = r3 AND $spdif.STREAM_INVALID_FROM_FW;
   if NZ jump send_message;

   // stream is valid
   r4 = M[r7 + $spdif.frame_copy.SAMPLING_FREQ_FIELD];
   if Z jump end;
   r6 = M[r7 + $spdif.frame_copy.CODEC_TYPE_FIELD];
   r6 = r6 AND 0xFF;
   r5 = M[r7 + $spdif.frame_copy.CHSTS_FIRST_WORD_FIELD];
   r5 = r5 AND 0xFF;

   // report to to VM now
   send_message:
   r1 = 1;
   // save parameters for next time, if they are the same
   // new message is not sent
   // save word0
   r0 = M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+0)];
   M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+0)] = r3;
   Null = r3 - r0;
   if NZ r1 = 0;

   // save word1
   r0 = M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+1)];
   M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+1)] = r4;
   Null = r4 - r0;
   if NZ r1 = 0;

   // save word2
   r0 = M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+2)];
   M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+2)] = r5;
   Null = r5 - r0;
   if NZ r1 = 0;

   // save word3
   r0 = M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+3)];
   M[r7 + ($spdif.frame_copy.LAST_REPORTED_WORDS_FIELD+3)] = r6;
   Null = r6 - r0;
   if NZ r1 = 0;

   // send the message, only if at least one parameter has changed
   Null = r1;
   if Z call $message.send_short;

   end:
   pop r8;
   // pop lank from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

#endif // SPDIF_REPORT_EVENTS
#endif // SPDIF_REPORT_EVENTS_ASM_INCLUDED
