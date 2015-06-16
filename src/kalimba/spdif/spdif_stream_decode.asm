// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.comes/ Part of ADK 3.5
//
// $Change$  $DateTime$
// $Revision$
// *****************************************************************************
#ifndef SPDIF_STREAM_DECODE_ASM_INCLUDED
#define SPDIF_STREAM_DECODE_ASM_INCLUDED
#include "core_library.h"
#include "spdif.h"
#include "spdif_stream_decode.h"
#include "codec_library.h"

// *****************************************************************************
// MODULE:
//    $spdif.stream_decode
//
// DESCRIPTION:
//
//    S/PDIF stream decode module is responsible for decoding audio data received
//  from S/PDIF input interface. The input stream is in IEC-61937 standard format,
//  S/PDIF stream decode module extract audio data from the input stream by calling
//  S/PDIF frame copy module. The input data can be either in PCM or CODED format,
//  PCM data are always extracted and routed to output stereo LEFT and RIGHT buffers.
//  For coded data, this library either invokes a proper decoder or simply mutes the
//  output while receiving coded data. User can configure what data types shall be
//  decoded and also shall provide proper decoder for the data types that wants to
//  support. The library also handles smooth transition between PCM and CODED data
//  or between two different CODED data types.
//
//  Some optional features that are or will be supported by this library:
//
//  Output Interface Control:
//     S/PDIF library can control output consuming interface,
//     This allows to activate and deactivate the output interface according to the
//     state of S/PDIF input interface, it also allows to configure the output rate
//     when the input rate changes. The library handles all low level communication
//     to firmware so handling the output interface will be hidden from the
//     application. The library only supports DAC, I2S and S/PDIF stereo output
//     interfaces.
//
//  Latency Measurement:
//     S/PDIF library can measure the latency that is presents due to S/PDIF
//     related buffers, these are input raw data buffer, PCM output buffer and
//     coded data buffer. The measured latency will be used by the application
//     to control the latency of the system.
//
//  VM message communication:
//     Various information might be needed by the vm about the S/PDIF input stream,
//     this info are not available directly from vm because its DSP that communicate
//     to firmware. S/PDIF stream decode can communicate to vm and let vm knows the
//     state of S/PDIF input stream.
//
//  NOTE:
//     This is only for decoding input spdif stream. There might be a S/PDIF
//     stream encode sub library in future, that will enable apps to send coded
//     data via S/PDIF output interface.
// *****************************************************************************
.MODULE $spdif.stream_decode;
   .DATASEGMENT DM;

   // storing the input structure, at the moment this library only
   // supports a single instance of spdif input stream, supporting
   // multiple instance needs a small amount of work in firmware interface
   // so the received messages can be distributed to proper input structure
   .VAR stream_decode_struct;

   #ifdef DEBUG_ON
       // define profile structure for stream decode function
      .VAR/DM1 $spdif.profile_stream_decode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED,
      0 ...;
   #endif

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif.stream_decode.init
//
// DESCRIPTION:
//    initialises spdif library
//
// INPUTS:
//   r5 = spdif stream decode structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.stream_decode.init;
   .CODESEGMENT SPDIF_STREAM_DECODE_INIT_PM;
   .DATASEGMENT DM;

   $spdif.stream_decode.init:
   $spdif.init:

   // push rLink onto stack
   $push_rLink_macro;

   // save input structure
   M[$spdif.stream_decode.stream_decode_struct] = r5;

   // initialise frame copy module
   r5 = M[r5 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];
   call $spdif.frame_copy.init;

   #ifdef SPDIF_OUTPUT_INTERFACE_CONTROL
      // initialisation for output interface
      call $spdif.output_interface_control.init;
   #endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.stream_decode
//
// DESCRIPTION:
//    decoding audio data received from S/PDIF input interface.
//
// INPUTS:
//    r8 = spdif stream decode structure, fields are described below:
//    SPDIF_FRAME_COPY_STRUCT_FIELD (config) =
//       pointer to spdif "frame copy" structure, frame copy module is invoked
//       by this function to extract PCM and coded data from spdif raw input. Some
//       of the user configuration will be via this structure.
//
//    GET_DECODER_FUNCTION_PTR_FIELD (config) =
//       call back function to get decoder info, this has to be configured by
//       the application. This field can be null if user wants PCM audio only.
//       The function is called whenever codec type changes, and the app is
//       supposed to provide the following info for the codec type:
//       1- decoder structure
//       2- frame decode function
//       3- reset decoder function (can be null)
//
//    MASTER_RESET_FUNCTION_FIELD (config) =
//       A master reset function that is supplied by the app, the function is called when
//       data type changes.
//
//    MODE_FIELD (output):
//       determines the output result, can be either $spdif.SUCCESS, $spdif.NOT_ENOUGH_INPUT_DATA,
//       or $spdif.NOT_ENOUGH_OUTPUT_SPACE, depending on the frame copy output and also
//       the decoder output when applicable
//
//       frame copy output          decoder output        output
//       x                          NA                    = frame copy output
//       Success                    X                     Success
//       Not Success                X                     decoder output
//
//    CURRENT_CODEC_TYPE_FIELD (internal state)
//       current CODED data type that is processed by this module
//
//    DECODER_DECODE_STRUCT_FIELD  (internal state)
//        decoder input structure received from app via call back function
//
//    DECODER_FRAME_DECODE_FUNCTION_FIELD (internal state)
//       decoder frame decode function received from app via call back function
//
//    DECODER_RESET_FUNCTION_FIELD (internal state)
//       decoder reset function received from app via call back function
//
//    CODEC_IS_DECODING_FIELD =
//       flag showing whether decoder is currently decoding or run out of data
//
//    STALL_COPYING_FIELD
//       flag showing copying shall be stalled now, stall happens when codec type
//       has to change and the decoder is still decoding old data type
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.stream_decode;
   .CODESEGMENT SPDIF_STREAM_DECODE_PM;
   .DATASEGMENT DM;

$spdif.stream_decode:
$spdif.decode:

   // push rLink onto stack
   $push_rLink_macro;

   // -- Start overall profiling if enabled --
   PROFILER_START_SPDIF(&$spdif.profile_stream_decode);

   // save stream decode structure
   M[$spdif.stream_decode.stream_decode_struct] = r5;
   r8 = r5;

   retry_copy:

   // get the copy structure
   r5 = M[r8 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];

   // default mode for frame copy
   r0 = $spdif.NOT_ENOUGH_INPUT_DATA;
   M[r5 + $spdif.frame_copy.MODE_FIELD] = r0;

   // copy if not in stall mode
   Null = M[r8 + $spdif.stream_decode.STALL_COPYING_FIELD];
   if Z call $spdif.frame_copy;
   r8 = M[$spdif.stream_decode.stream_decode_struct];
   r5 = M[r8 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];

   // copy 'frame copy' mode to 'stream decode' mode
   r0 = M[r5 + $spdif.frame_copy.MODE_FIELD];
   M[r8 + $spdif.stream_decode.MODE_FIELD] = r0;

#ifdef SPDIF_PCM_SUPPORT_ONLY
   r1 = M[r5 + $spdif.frame_copy.CODEC_TYPE_FIELD];
   r0 = M[r8 + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD];
   M[r8 + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD] = r1;
   // if codec type has changed,
   // call master reset function if provided by app
   r2 = M[r8 + $spdif.stream_decode.MASTER_RESET_FUNCTION_FIELD];
   r0 = r0 - r1;
   r0 = r0 * r2(int)(sat);
   if NZ call r2;
#else // #ifdef SPDIF_PCM_SUPPORT_ONLY

   // run the decoder if not stalled
   r0 = M[r8 + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD];
   Null = r0 - $spdif.DECODER_TYPE_PCM;
   if GT call $spdif.stream_decode.run_decoder;

   // see if codec type has changed
   r8 = M[$spdif.stream_decode.stream_decode_struct];
   r5 = M[r8 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];
   r1 = M[r5 + $spdif.frame_copy.CODEC_TYPE_FIELD];
   r0 = M[r8 + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD];

   // if codec type has not changed then continue normally
   Null = r0 - r1;
   if Z jump continue_normally;

   // see if the codec is still decoding
   r0 = M[r8 + $spdif.stream_decode.CODEC_IS_DECODING_FIELD];
   if NZ jump stall_copying;

   // time to switch to new data type
   switch_now:

      // get decoder info for new CODED data type
      M[r8 + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD] = r1;
      Null = r1 - $spdif.DECODER_TYPE_PCM;
      if GT call $spdif.stream_decode.get_new_decoder;

      // call master reset function if provided by app
      r0 = M[r8 + $spdif.stream_decode.MASTER_RESET_FUNCTION_FIELD];
      if NZ call r0;
      r8 = M[$spdif.stream_decode.stream_decode_struct];
     #ifdef SPDIF_LATENCY_MEASUREMENT
         // reset latency measurement process
         r4 = $spdif.latency_measurment.RESET;
         call $spdif.latency_measurement;
      #endif

      #ifdef SPDIF_REPORT_EVENTS
         // codec type has changed,
         // report this event
         call $spdif.report_event;
      #endif

      // if the stall flag is not cleared now, clear it and
      // retry copying
      Null = M[r8 + $spdif.stream_decode.STALL_COPYING_FIELD];
      if Z jump switch_done;
      M[r8 + $spdif.stream_decode.STALL_COPYING_FIELD] = NULL;
      jump retry_copy;

   // set stall copying flag, this will prevent to copy more data
   // to spdif output buffers
   stall_copying:
   r0 = 1;
   M[r8 + $spdif.stream_decode.STALL_COPYING_FIELD] = r0;
   jump switch_done;

   // normal exit point
   continue_normally:
   // this is not needed, for safeguarding only
   M[r8 + $spdif.stream_decode.STALL_COPYING_FIELD] = NULL;

   switch_done:
#endif // #ifndef SPDIF_PCM_SUPPORT_ONLY

   #ifdef SPDIF_LATENCY_MEASUREMENT
      // update latency
      r4 = $spdif.latency_measurment.UPDATE_LATENCY;
      call $spdif.latency_measurement;
   #endif

   // -- Stop overall profiling if enabled --
   PROFILER_STOP_SPDIF(&$spdif.profile_stream_decode)

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#ifndef SPDIF_PCM_SUPPORT_ONLY
// *****************************************************************************
// MODULE:
//    $spdif.stream_decode.run_decoder
//
// DESCRIPTION:
//    Runs a decoder function to decode the received and extracted CODED audio
//    data. The decoder function is supplied by the application.
//
// INPUTS:
//    r8 = spdif stream decode structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything except r8
// *****************************************************************************
.MODULE $M.spdif.stream_decode.run_decoder;
   .CODESEGMENT SPDIF_STREAM_DECODE_RUN_DECODER_PM;
   .DATASEGMENT DM;

   $spdif.stream_decode.run_decoder:
   // push rLink onto stack
   $push_rLink_macro;

   // save the structure in stack
   push r8;

   // get decoder input structure
   r5 = M[r8 + $spdif.stream_decode.DECODER_DECODE_STRUCT_FIELD];

   // get decoder frame decode function
   r0 = M[r8 + $spdif.stream_decode.DECODER_FRAME_DECODE_FUNCTION_FIELD];

   // decode normally
   r1 = $codec.NORMAL_DECODE;
   M[r5 + $codec.DECODER_MODE_FIELD] = r1;

   // call the decoder frame decode function
   call r0;

   // get the input structure from stack
   pop r8;

   // if decoder is run out of data, it means that it wont generate
   // any output until receiving new input data. Any other output means
   // that decoder is still active.
   r5 = M[r8 + $spdif.stream_decode.DECODER_DECODE_STRUCT_FIELD];
   r0 = M[r5 + $codec.DECODER_MODE_FIELD];
   r1 = 1;
   Null = r0 - $codec.NOT_ENOUGH_INPUT_DATA;
   if Z r1 = 0;
   M[r8 +  $spdif.stream_decode.CODEC_IS_DECODING_FIELD] = r1;

   // update output result
   r1 = M[r8 + $spdif.stream_decode.MODE_FIELD];
   if NZ r1 = r0;
   M[r8 + $spdif.stream_decode.MODE_FIELD] = r1;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.stream_decode.get_new_decoder
//
// DESCRIPTION:
//    When codec type change, the library asks the application to provide a
//    proper decoder function for the new coded data type. The app shall provide
//    standards frame_decode and reset_decoder functions and also the proper input
//    structure to the decoder.
//
// INPUTS:
//    r8 = spdif stream decode structure
//    r1 = new coded data type (see spdif.h for data type definitions)
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything except r8
// *****************************************************************************
.MODULE $M.spdif.stream_decode.get_new_decoder;
   .CODESEGMENT SPDIF_STREAM_DECODE_GET_NEW_DECODER_PM;
   .DATASEGMENT DM;

   $spdif.stream_decode.get_new_decoder:

   // push rLink onto stack
   $push_rLink_macro;

   // run call back function to get decoder info from app
   r0 = M[r8 + $spdif.stream_decode.GET_DECODER_FUNCTION_PTR_FIELD];
   if Z call $error; // codec is supported by app but no call back provided
   call r0;

   // r0 = decoder structure
   // r1 = frame decode function
   // r2 = reset decoder function (can be Null)
   M[r8 + $spdif.stream_decode.DECODER_DECODE_STRUCT_FIELD] = r0;
   M[r8 + $spdif.stream_decode.DECODER_FRAME_DECODE_FUNCTION_FIELD] = r1;
   M[r8 + $spdif.stream_decode.DECODER_RESET_FUNCTION_FIELD] = r2;

   // save the input structure
   push r8;

   // reset decoder
   r5 = M[r8 + $spdif.stream_decode.DECODER_DECODE_STRUCT_FIELD];
   r0 = M[r8 + $spdif.stream_decode.DECODER_RESET_FUNCTION_FIELD];
   if NZ call r0;

   // restore the input structure
   pop r8;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif // #ifndef SPDIF_PCM_SUPPORT_ONLY

#endif // #ifndef SPDIF_STREAM_DECODE_ASM_INCLUDED
