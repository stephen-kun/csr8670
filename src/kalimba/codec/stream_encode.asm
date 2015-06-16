// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef CODEC_STREAM_ENCODE_INCLUDED
#define CODEC_STREAM_ENCODE_INCLUDED

#include "codec_library.h"

// *****************************************************************************
// MODULE:
//    $codec.stream_encode
//
// DESCRIPTION:
//    Encodes a codec stream (deals with overflow/underflow ie. real BT issues)
//
// INPUTS:
//    - r5 = pointer to codec_stream_ENCODER_STRUC
//
// OUTPUTS:
//    - r0 = $codec.STREAM_CAN_IDLE / $codec.STREAM_DONT_IDLE
//    (this can be used to decide whether to have an idle period to save power)
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTES:
//
//    @verbatim
//   GOOD WORKING LEVEL TO                                 BUFFER OVERFLOW
//   HANDLE BT PACKET RETRIES                              ABOUT TO OCCUR
//             |                                                  |
//          ___V__________________________________________________V_
//         |                 encoder output buffer                 |
//         |_______________________________________________________|
//        Empty                                                  Full
//     (0 bytes)                                              (N bytes)
//    @endverbatim
//
//  This is the main buffer in the system to accomodate jitter from packet
//  retries over BT having to occur.
//
//  If we don't have enough space in this buffer for a new codec frame then we
//  throw away blocks of audio data so as to stop an audio buffer overflow
//  occuring.  We also reset the encoder to reduce the pops and clicks heard at
//  the decoder after the overflow.  We then don't start encoding again until
//  the buffer is virtually empty.
//
// *****************************************************************************
.MODULE $M.codec_stream_encode;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $codec.stream_encode.mux.output_sinks = 0;
   .VAR $codec.struc_ptr;

   $codec.stream_encode:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.STREAM_ENCODE.PATCH_ID_0, r1)
#endif

   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $codec.profile_stream_encode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED;
      r0 = &$codec.profile_stream_encode;
      call $profiler.start;
   #endif

   // store the pointer to the codec structure
   M[$codec.struc_ptr] = r5;

   // if debugging store buffer level
   #ifdef DEBUG_ON
     .VAR/DM1 $codec.stream_encoder_buflevel;
      r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      M[$codec.stream_encoder_buflevel] = r0;
   #endif

   // update the codec buffer's read pnter in case there have been any copies
#if 1
   r0 = M[$codec.stream_encode.mux.output_sinks];
   if NE call $codec.stream_encode.mux.update_cbuffer_read_pointer;
#endif

   // -- Only allow encoding to start when buffer is virtually empty --
   // this gives us some headroom to accomodate jitter and packet retries
   Null = M[r5 + $codec.stream_encode.STATE_FIELD];
   if NZ jump do_frame_encode;
      r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      Null = r0 - 4;
      if POS jump stream_overflow_detected;
      r1 = $codec.stream_encode.STATE_STREAMING;
      M[r5 + $codec.stream_encode.STATE_FIELD] = r1;
      // reset encoder before we start streaming
      // NOTE: the encoder needs r5 to point to encoder-specific structure, not stream_encoder struct
      r0 = M[r5 + $codec.stream_encode.RESET_ADDR_FIELD];
      r5 = r5 + $codec.stream_encode.ENCODER_STRUC_FIELD;
      call r0;
      r5 = r5 - $codec.stream_encode.ENCODER_STRUC_FIELD;
   #if defined(L2CAP_FRAME)
      // Init Media Header Params
      r6 = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];
      Null = r6;
      if Z jump do_frame_encode;
      r0 = M[$NUM_RUN_CLKS_LS];
      M[r6 + $codec.media_header.RTP_TIMESTAMP_LS_FIELD] = r0;
      r0 = M[$NUM_STALLS_LS];
      M[r6 + $codec.media_header.RTP_TIMESTAMP_MS_FIELD] = r0;
      r0 = M[$NUM_INSTRS_LS];
      M[r6 + $codec.media_header.RTP_SEQUENCE_NUM_FIELD] = r0;
   #endif
   // -- Do the frame encode --
   do_frame_encode:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.STREAM_ENCODE.PATCH_ID_1, r1)
#endif

   #if defined(L2CAP_FRAME)
      // Check whether RTP header needs to be added
      r6 = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];
      if Z jump no_transform;

      // Check if header is already added
      Null = M[r6 + $codec.media_header.WRITE_HDR_FIELD];
      if NZ call $codec.write_rtp_header;

   no_transform:
   #endif

      r0 = M[r5 + $codec.stream_encode.ADDR_FIELD];
      // set r5 to the start of encoder structure
      r5 = r5 + $codec.stream_encode.ENCODER_STRUC_FIELD;
      // call the appropriate frame_encode function, which needs r5 to point to encoder struct
      call r0;
      r5 = M[$codec.struc_ptr];
      r0 = M[r5 + $codec.stream_encode.MODE_FIELD];
      Null = r0 - $codec.SUCCESS;
      if Z jump all_done_dont_idle;
      // if not enough input data we can safely idle for some time
      Null = r0 - $codec.NOT_ENOUGH_INPUT_DATA;
      if Z jump all_done_can_idle;
      // else an output buffer overflow is about to occur


   // -- Stream overflow --
   stream_overflow_detected:
      // The output buffer would overflow if we tried to encode a frame,
      // so instead of encoding a frame we empty the audio buffer to stop it
      // also overflowing.  If we've come to this state from correctly streaming
      // we reset the encoder state so as to remove unwanted audio pops upon the
      // encoder starting again.

      // work out which AV Sink is falling behind and reset it.
#if 1
      r0 = M[$codec.stream_encode.mux.output_sinks];
      if Z jump flsuh_audio_and_idle;
         call $codec.stream_encode.mux.find_tail_pointer_and_reset;
         // See if all sinks are stopped
         Null = r3;
         if Z jump all_done_no_transform;
         // all sinks/streams are stopped :-(
#endif

      flsuh_audio_and_idle:
         call $codec.stream_encode.overflow_audio_flush;
      // and now we can exit and safely idle for some time


   all_done_can_idle:
      // stop profiling if enabled
      #ifdef PROFILE_STREAM_ENCODE
         r0 = &$codec.profile_stream_encode;
         call $profiler.stop;
      #endif
      r0 = $codec.STREAM_CAN_IDLE;
      // pop rLink from stack
      jump $pop_rLink_and_rts;


   all_done_dont_idle:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.STREAM_ENCODE.PATCH_ID_2, r1)
#endif

      // update the codec cbuffer struc
#if 1
      r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
      call $codec.stream_encode.mux.update_cbuffer_write_pointer;
#endif

      #if defined(L2CAP_FRAME)
         r6 = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];
         if Z jump all_done_no_transform;
            r1 = M[r6 + $codec.media_header.FRAME_COUNT_FIELD];
            r1 = r1 + 1;
            M[r6 + $codec.media_header.FRAME_COUNT_FIELD] = r1;
            r2 = M[r6 + $codec.media_header.NUM_FRAMES_FIELD];
            if Z jump $error; //num frames unknown. Not handled

            Null = r2 - r1;
            if NZ jump all_done_no_transform;
               M[r6 + $codec.media_header.FRAME_COUNT_FIELD] = Null;
               M[r6 + $codec.media_header.NUM_FRAMES_FIELD] = Null;
               // write_hdr = TRUE
               r0 = 1;
               M[r6 + $codec.media_header.WRITE_HDR_FIELD] = r0;
      #endif

      all_done_no_transform:
      // stop profiling if enabled
      #ifdef PROFILE_STREAM_ENCODE
         r0 = &$codec.profile_stream_encode;
         call $profiler.stop;
      #endif
      r0 = $codec.STREAM_DONT_IDLE;
      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $codec.stream_encode.overflow_audio_flush
//
// DESCRIPTION:
//    This function flushes equal amounts of audio (maximum amount possible) from
//    both audio buffers. It also resets the encoder if previously streaming.
//
// INPUTS:
//    - r5 = pointer to codec_stream_ENCODER_STRUC
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    Depends on the reset function
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.overflow_audio_flush;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.overflow_audio_flush:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.OVERFLOW_AUDIO_FLUSH.PATCH_ID_0, r3)
#endif

   // Check to see if previously streaming
   Null = M[r5 + $codec.stream_encode.STATE_FIELD];
   if Z jump previously_not_streaming;
      M[r5 + $codec.stream_encode.STATE_FIELD] = $codec.stream_encode.STATE_STOPPED;
      r0 = M[r5 + $codec.stream_encode.RESET_ADDR_FIELD];
      // call the appropriate encoder_reset function
      call r0;
   previously_not_streaming:

      r5 = M[$codec.struc_ptr];
      r3 = 0x7FFF;  // a big number
      r0 = M[r5 + $codec.stream_encode.IN_LEFT_BUFFER_FIELD];
      if Z jump dont_check_left;
         call $cbuffer.calc_amount_data;
         r3 = r0;
      dont_check_left:
      M0 = 0x7FFF;  // a big number
      r0 = M[r5 + $codec.stream_encode.IN_RIGHT_BUFFER_FIELD];
      if Z jump dont_check_right;
         call $cbuffer.calc_amount_data;
         M0 = r0;
      dont_check_right:

      // set M0 to the smallest
      Null = M0 - r3;
      if POS M0 = r3;

      // remove M0 words from each buffer
      r0 = M[r5 + $codec.stream_encode.IN_LEFT_BUFFER_FIELD];
      if Z jump dont_throw_away_left;
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_read_address_and_size_and_start_address;
         push r2;
         pop B0;
#else
         call $cbuffer.get_read_address_and_size;
#endif
         I0 = r0;   L0 = r1;
         // dummy read to increment I0 by M0
         L0 = 0,
          r0 = M[I0,M0];
         // store updated cbuffer pointers for left audio input
         r0 = M[r5 + $codec.stream_encode.IN_LEFT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_read_address;
      dont_throw_away_left:

      r0 = M[r5 + $codec.stream_encode.IN_RIGHT_BUFFER_FIELD];
      if Z jump dont_throw_away_right;
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_read_address_and_size_and_start_address;
         push r2;
         pop B0;
#else
         call $cbuffer.get_read_address_and_size;
#endif
         I0 = r0;   L0 = r1;
         // dummy read to increment I0 by M0
         L0 = 0,
          r0 = M[I0,M0];
         // store updated cbuffer pointers for right audio input
         r0 = M[r5 + $codec.stream_encode.IN_RIGHT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_read_address;
      dont_throw_away_right:
      // and now we can exit and safely idle for some time

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#if defined(L2CAP_FRAME)
// *****************************************************************************
// MODULE:
//    $codec.write_rtp_header
//
// DESCRIPTION:
//    Write RTP header and Pay load header
//
// INPUTS:
//    - r5 = pointer to codec_stream_ENCODER_STRUC
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//   r0, r1, r2, r6, r8, r9, rMAC, I0, L0
// NOTES:
//    @verbatim
//         ________________________________________
//                 MEDIA PACKET HEADER (RTP)
//         ----------------------------------------
//         |  Octet1   | Octet2  | Octet3 | Octet4 |
//         ----------------------------------------
// Bits    |01|2|3|4567|0|1234567|01234567|01234567|
//         ----------------------------------------
//         |V |P|X| CC |M|  PT   | Sequence Number |
//         ----------------------------------------
//         |             Time Stamp                |
//         ----------------------------------------
//         |                SSRC                   |
//         ----------------------------------------
//         |          Media Pay load               |
//         ----------------------------------------
//            ______________________________
//                     PAY LOAD HEADER
//            ------------------------------
// Bits       |0 1 2 3   |  4  5   6   7   |
//            |F S L RFA |Number of frames |
//            ------------------------------
//    @endverbatim
//
// *****************************************************************************
.MODULE $M.codec_write_rtp_header;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR encoder_struc_ptr;

   $codec.write_rtp_header:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.WRITE_RTP_HEADER.PATCH_ID_0, r1)
#endif

      // store the pointer to the codec stream encoder structure (note: naming of encoder_struc_ptr misleading in this sense)
      M[encoder_struc_ptr] = r5;

      // Calculate the frame length
      // R5 to first point to endoder-specific structure rather than stream encoder structure. 
      // Encoder's frame length calculation function will use it to get to data object pointer.
      r5 = r5 + $codec.stream_encode.ENCODER_STRUC_FIELD;
      // R9 is expected by encoder's function to be set to data object address. 
      r9 = M[r5 + $codec.ENCODER_DATA_OBJECT_FIELD];

      call $codec.get_encoded_frame_info;
      r5 = M[encoder_struc_ptr];
      r8 = r0;
      if Z jump dont_calc_num_frames;
         // start calculating the number of frames
         r6 = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];
         // Calculate how many encoded frames fit in one L2CAP packet
         rMAC = M[r6 + $codec.media_header.L2CAP_ATU_SIZE_FIELD];
         // RTP header 12 bytes, Pay load header depends on codec - don't include 4 byte L2CAP header as this is outside the ATU
         r1 = M[r6 + $codec.media_header.RTP_AND_PAYLOAD_HEADER_SIZE_FIELD];
         if NEG r1 = 0;
         Null = M[r6 + $codec.media_header.FASTSTREAM_ENABLED_FIELD];
         if Z rMAC = rMAC - r1;
         rMAC = rMAC LSHIFT 0 (LO);
         Div = rMAC / r8;
         //Div takes 12 cycles. Read result later
      dont_calc_num_frames:

      // get write address of output buffer
      r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_write_address_and_size_and_start_address;
      push r2;
      pop B0;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      I0 = r0;
      L0 = r1;

      // Get address of Media Header structure
      r6 = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];

      // Get address of putbits function
      // Assume r9 is not thrashed by called functions
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];

      // Frame size could be unknown
      r1 = 0;
      r0 = r8;
      if Z jump frame_length_unknown;
      r8 = DivResult;
      // RTP header + Payload header
      r2 = M[r6 + $codec.media_header.RTP_AND_PAYLOAD_HEADER_SIZE_FIELD];
      // r1 = Num frames * frame length. if r8 is zero. r0 = r0 * 0 = 0
      r1 = r8 * r0 (int);
      // Data len + Header len (excluding L2CAP header)
      if Z jump frame_length_unknown;
         Null = M[r6 + $codec.media_header.FASTSTREAM_ENABLED_FIELD];
         if Z r1 = r1 + r2;

frame_length_unknown:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.WRITE_RTP_HEADER.PATCH_ID_1, r9)
#endif

      // Write L2CAP header (length)
      r0 = 16;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      // set r5 consistent with start of encoder-specific structure, needed by called encoder functions
      r5 = r5 + $codec.stream_encode.ENCODER_STRUC_FIELD;

      call r9;
      // Write L2CAP header (CID)
      r0 = 16;
      r1 = 0;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;

      // If faststream is enabled then we do not send the RTP header.
      Null = M[r6 + $codec.media_header.FASTSTREAM_ENABLED_FIELD];
      if NZ jump done;

      // write RTP header
      // RTP header 0x80 0x60
      r0 = 16;
      r1 = 0x8060;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;

      // RTP sequence number
      r1 = M[r6 + $codec.media_header.RTP_SEQUENCE_NUM_FIELD];
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;

      // increment seq number
      r1 = r1 + 1;
      r1 = r1 AND 0xFFFF;
      M[r6 + $codec.media_header.RTP_SEQUENCE_NUM_FIELD] = r1;

      // RTP timestamp MS
      r1 = M[r6 + $codec.media_header.RTP_TIMESTAMP_LS_FIELD];
      r1 = r1 LSHIFT -16;
      r2 = M[r6 + $codec.media_header.RTP_TIMESTAMP_MS_FIELD];
      r2 = r2 LSHIFT 8;
      r1 = r2 OR r1;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;

      // RTP timestamp LS
      r1 = M[r6 + $codec.media_header.RTP_TIMESTAMP_LS_FIELD];
      r1 = r1 AND 0xFFFF;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.WRITE_RTP_HEADER.PATCH_ID_2, r1)
#endif

      // write SSRC
      r0 = 16;
      // RTP dummy SSRC_MS. SSRC is ignored by sink
      r1 = 0xBEEF;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;
      // RTP dummy SSRC_LS. SSRC is ignored by sink
      r1 = 0xBEEF;
      r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
      call r9;

      // If frame length is unknown don't increment timestamp
      Null = r8;
      if Z jump dont_increment_timestamp;

      // inc time stamp
      r0 = M[r6 + $codec.media_header.RTP_TIMESTAMP_LS_FIELD];
      r1 = M[r6 + $codec.media_header.RTP_TIMESTAMP_MS_FIELD];

      // increment time stamp (assume 128sample packets for now)
      // Timestamp represents sampling instant. Increment by number of samples
      r2 = M[r6 + $codec.media_header.SAMPLES_PER_FRAME];
      r2 = r8 * r2 (int);
      r0 = r0 + r2;
      r1 = r1 + Carry;
      // Only 8 bits of MS are valid
      r1 = r1 AND 0xFF;
      // store the time stamp
      M[r6 + $codec.media_header.RTP_TIMESTAMP_LS_FIELD] = r0;
      M[r6 + $codec.media_header.RTP_TIMESTAMP_MS_FIELD] = r1;

   dont_increment_timestamp:
      // Could be zero if frame length is not known - save for later
      r0 = M[r6 + $codec.media_header.RTP_AND_PAYLOAD_HEADER_SIZE_FIELD];
      Null = r0 - $codec.SBC_RTP_AND_PAYLOAD_HEADER_SIZE;
      if NE jump not_sbc;
         // write Media payload header (just number of SBC frames in this rtp packet)
         r0 = 8;
         // write into stream
         r1 = r8;
         r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
         call r9;
         jump done;
      not_sbc:

      Null = r0 - $codec.MP3_RTP_AND_PAYLOAD_HEADER_SIZE;
      // at the moment we only support sbc and mp3 -
      // if you get an error here and you don't know why, it is probably because
      // you have not initialised the RTP_AND_PAYLOAD_HEADER_SIZE_FIELD field of
      // your media_header structure.
      if NE jump done;

         // 2 bytes unused
         r0 = 16;
         r1 = 0;
         r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
         call r9;
         // fragment offset (2 bytes) - we are not allowing fragmentation
         r1 = 0;
         r9 = M[r6 + $codec.media_header.PUT_BITS_ADDR_FIELD];
         call r9;
   done:
      // Could be zero if frame length is not known - save for later
      M[r6 + $codec.media_header.NUM_FRAMES_FIELD] = r8;
      // write_hdr = FALSE
      M[r6 + $codec.media_header.WRITE_HDR_FIELD] = Null;

      r5 = M[encoder_struc_ptr];
      // set write address
      r1 = I0;
      r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
      call $cbuffer.set_write_address;
      L0 = 0;

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $codec.get_encoded_frame_info
//
// DESCRIPTION:
//    Get the frame length and number of samples per frame
//
// INPUTS:
//    - r6 = pointer to media header structure
//
// OUTPUTS:
//    r0 = frame length
//
// TRASHED REGISTERS:
//    r2
//
// NOTES:
//
//    @verbatim
//
// *****************************************************************************
.MODULE $M.codec_get_encoded_frame_info;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR media_header_struc_ptr;

   $codec.get_encoded_frame_info:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_ASM.GET_ENCODED_FRAME_INFO.PATCH_ID_0, r2)
#endif

      M[media_header_struc_ptr] = r6;
      // Check if frame length and number of samples can be calculated
      r0 = M[r6 + $codec.media_header.GET_ENCODED_FRAME_INFO];
      // Exit if no function to get info. Use default samples per frame
      if Z jump $pop_rLink_and_rts;

         r1 = M[r6 + $codec.media_header.GET_ENCODED_FRAME_INFO];
         // Calc frame length and get number of samples per frame
         call r1;
         // restore r6
         r6 = M[media_header_struc_ptr];
         // Number of samples cannot be zero
         Null = r1;
         if Z jump $error;

            // Store the number of samples per frame
            M[r6 + $codec.media_header.SAMPLES_PER_FRAME] = r1;
            // frame length cannot be 0
            Null = r0;
            if Z jump $pop_rLink_and_rts;

               // Currently we don't support audio frames larger than the MTU size
               r2 = M[r6 + $codec.media_header.L2CAP_ATU_SIZE_FIELD];
               // L2CAP header (4) + Subtract RTP header(12) + Payload header (1)
               r1 = M[r6 + $codec.media_header.RTP_AND_PAYLOAD_HEADER_SIZE_FIELD];
               Null = M[r6 + $codec.media_header.FASTSTREAM_ENABLED_FIELD];
               if Z r2 = r2 - r1;
               // Check if ATU (MTU - header) size is greater than frame size
               Null = r2 - r0;
               // Frame needs to be fragmented. Not handled
               if NEG jump $error;

   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif

#endif



