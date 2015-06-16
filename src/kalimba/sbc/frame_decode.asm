// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBC_FRAME_DECODE_INCLUDED
#define SBC_FRAME_DECODE_INCLUDED

#include "core_library.h"
#include "codec_library.h"
#include "sbc_profiler_macros.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.frame_decode
//
// DESCRIPTION:
//    Decode an SBC frame
//
// INPUTS:
//    - r5 = pointer to a $codec.DECODER_STRUC structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTES:
//    To support mono, stereo, and dual mono decoding the operation of the
//    routine is as follows:
//
//    @verbatim
//    nrof_ch | left_buf | right_buf
//    --------|----------|-----------
//       1    | enabled  | disabled    - Mono decoding to left
//       1    | disabled | enabled     - Mono decoding to right
//       1    | enabled  | enabled     - Mono decoding to both left and right
//       2    | enabled  | enabled     - Standard stereo decoding
//       2    | enabled  | disabled    - Stereo decoding but with just left [1]
//       2    | disabled | enabled     - Stereo decoding but with just right [1]
//    @endverbatim
//
//
//  [1] If decoder convert_to_mono = 1 then the audio output is
//  the stereo signal converted to mono.  Otherwise it is the individual channel
//  of the stereo signal.
//
//
//  @verbatim
//  audio_frame()
//  (
//     frame_header()
//     scale_factors()
//     audio_samples()
//     padding()
//  )
//  @endverbatim
//
// *****************************************************************************

.MODULE $M.sbcdec.frame_decode;
   .CODESEGMENT SBCDEC_FRAME_DECODE_PM;
   .DATASEGMENT DM;

   $sbcdec.frame_decode:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.FRAME_DECODE_ASM.FRAME_DECODE.PATCH_ID_0, r1)
#endif

   // -- Start overall profiling if enabled --
   PROFILER_START_SBCDEC(&$sbcdec.profile_frame_decode)

   // -- Save $codec.DECODER_STRUC pointer --
   M[$sbcdec.codec_struc] = r5;


   // -- Load memory structure pointer
   // This pointer should have been initialised externally
   r9 = M[r5 + $codec.DECODER_DATA_OBJECT_FIELD];



   reattempt_decode:

   // -- Setup SBC input stream buffer info --
   // set I0 to point to cbuffer for sbc input stream
   r5 = M[$sbcdec.codec_struc];
   r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0;
   L0 = r1;


   r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   r10 = r0 + r0;
   r10 = r10 - 2;
   if LE jump buffer_underflow;
   r4 = r10;
   call $sbcdec.find_sync;
   NULL = r6 - $sbc.SBC_NOT_SYNC;
   if EQ jump buffer_underflow;
      // I2 & r6 holding the bitstream buffer pointer of
      // the location before sync word
      r4 = r4 - r10;

   // -- Check that we have enough output audio space --
   // only if not GOBBLING though
   r0 = M[r5 + $codec.DECODER_MODE_FIELD];
   Null = r0 - $codec.GOBBLE_DECODE;
   if Z jump no_output_check_needed;

      // -- Check that we have enough output audio space --
      r0 = M[r5 + $codec.DECODER_OUT_LEFT_BUFFER_FIELD];
      if Z jump output_check_no_left_channel;
         call $cbuffer.calc_amount_space;
         Null = r0 - $sbc.MAX_AUDIO_FRAME_SIZE_IN_WORDS;
         if POS jump enough_output_space_left;
            jump not_enough_data_exit;
         enough_output_space_left:
      output_check_no_left_channel:

      r0 = M[r5 + $codec.DECODER_OUT_RIGHT_BUFFER_FIELD];
      if Z jump output_check_no_right_channel;
         call $cbuffer.calc_amount_space;
         Null = r0 - $sbc.MAX_AUDIO_FRAME_SIZE_IN_WORDS;
         if POS jump enough_output_space_right;
         not_enough_data_exit:
            r0 = $codec.NOT_ENOUGH_OUTPUT_SPACE;
            M[r5 + $codec.DECODER_MODE_FIELD] = r0;
            jump exit;
         enough_output_space_right:
      output_check_no_right_channel:
   no_output_check_needed:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.FRAME_DECODE_ASM.FRAME_DECODE.PATCH_ID_1, r1)
#endif

   // -- Store number of bytes of data available in the SBC stream --
   r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   r0 = r0 + r0;
   r0 = r0 - r4;
   // "+2": adjust by the number of bits we've currently read
   Null = r0 - ($sbc.MIN_SBC_FRAME_SIZE_IN_BYTES + 2);
   if POS jump no_buffer_underflow;

   buffer_underflow:
      // indicate that not enough input data
      r5 = M[$sbcdec.codec_struc];
      r0 = $codec.NOT_ENOUGH_INPUT_DATA;
      M[r5 + $codec.DECODER_MODE_FIELD] = r0;
      // store updated cbuffer pointers for sbc input stream
      r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
      r1 = I0;
      call $cbuffer.set_read_address;
      jump exit;
   no_buffer_underflow:

   M[r9 + $sbc.mem.NUM_BYTES_AVAILABLE_FIELD] = r0;



   // -- Read in header --
   call $sbcdec.read_frame_header;

   r0 = M[r9 + $sbc.mem.CUR_FRAME_LENGTH_FIELD];
   r1 = M[r9 + $sbc.mem.NUM_BYTES_AVAILABLE_FIELD];
   Null = r0 - r1;

   if LE jump enough_frame_data;

      // restore buffer pointer back to the sync word
      I0 = I2;

      M[r9 + $sbc.mem.GET_BITPOS_FIELD] = r6;

      jump buffer_underflow;

   enough_frame_data:


   // if corruption in frame then deal with it cleanly

   Null = M[r9 + $sbc.mem.FRAME_CORRUPT_FIELD];


   if NZ jump crc_fail_or_corrupt;


   // -- Read in scalefactors --
   call $sbcdec.read_scale_factors;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.FRAME_DECODE_ASM.FRAME_DECODE.PATCH_ID_2, r1)
#endif

   // -- Check CRC --

   r0 = M[r9 + $sbc.mem.FRAMECRC_FIELD];
   r1 = M[r9 + $sbc.mem.CRC_CHECKSUM_FIELD];
   r0 = r0 - r1;

   r0 = r0 AND 0xff;
   if Z jump crc_correct;

      crc_fail_or_corrupt:
      #ifdef DEBUG_SBCDEC
         r0 = M[$sbcdec.framecrc_errors];
         r0 = r0 + 1;
         M[$sbcdec.framecrc_errors] = r0;
      #endif

      // -- Save back SBC input stream buffer info --
      // store updated cbuffer pointers for sbc input stream
      r5 = M[$sbcdec.codec_struc];
      r1 = I0;
      r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
      call $cbuffer.set_read_address;
      L0 = 0;


      r0 = M[r9 + $sbc.mem.RETURN_ON_CORRUPT_FRAME_FIELD];

      if Z jump reattempt_decode;

      r0 = $codec.FRAME_CORRUPT;
      M[r5 + $codec.DECODER_MODE_FIELD] = r0;
      jump exit;

   crc_correct:


   // -- Calculate bit allocation --
   call $sbc.calc_bit_allocation;


   // -- Read audio samples --
   call $sbcdec.read_audio_samples;


   // -- Read padding bits --
   call $sbcdec.read_padding_bits;


   // -- Save back SBC input stream buffer info --
   // store updated cbuffer pointers for sbc input stream
   r5 = M[$sbcdec.codec_struc];
   r1 = I0;
   r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
   call $cbuffer.set_read_address;
   L0 = 0;


   // -- Skip further decoding if just doing a dummy frame read --
   r0 = M[r5 + $codec.DECODER_MODE_FIELD];
   Null = r0 - $codec.NORMAL_DECODE;
   if NZ jump all_done;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.FRAME_DECODE_ASM.FRAME_DECODE.PATCH_ID_3, r1)
#endif

   // -- Subband sample reconstruction --
   PROFILER_START_SBCDEC(&$sbcdec.profile_sample_reconstruction)
   call $sbcdec.sample_reconstruction;
   PROFILER_STOP_SBCDEC(&$sbcdec.profile_sample_reconstruction)


   // -- Joint stereo processing --

   r0 = M[r9 + $sbc.mem.CHANNEL_MODE_FIELD];

   Null = r0 - $sbc.JOINT_STEREO;
   if Z call $sbcdec.joint_stereo_decode;

   // -- Synthesis subband filtering Left --
   // set I1 to point to cbuffer for left audio output
   r5 = M[$sbcdec.codec_struc];
   r0 = M[r5 + $codec.DECODER_OUT_LEFT_BUFFER_FIELD];
   if Z jump no_left_buffer;

#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_write_address_and_size_and_start_address;
      push r2;
      pop B1;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      I1 = r0;
      L1 = r1;

      // select left channel
      r5 = 0;

      // generate output samples
      PROFILER_START_SBCDEC(&$sbcdec.profile_synthesis_subband_filter)
      call $sbcdec.synthesis_subband_filter;
      PROFILER_STOP_SBCDEC(&$sbcdec.profile_synthesis_subband_filter)

      // store updated cbuffer pointers for left audio output
      r5 = M[$sbcdec.codec_struc];
      r1 = I1;
      r0 = M[r5 + $codec.DECODER_OUT_LEFT_BUFFER_FIELD];
      call $cbuffer.set_write_address;
      L1 = 0;
   no_left_buffer:


   // -- Synthesis subband filtering Right --
   // set I1 to point to cbuffer for right audio output
   r5 = M[$sbcdec.codec_struc];
   r0 = M[r5 + $codec.DECODER_OUT_RIGHT_BUFFER_FIELD];
   if Z jump no_right_buffer;

#ifdef BASE_REGISTER_MODE
      call $cbuffer.get_write_address_and_size_and_start_address;
      push r2;
      pop B1;
#else
      call $cbuffer.get_write_address_and_size;
#endif
      I1 = r0;
      L1 = r1;

      // select right channel
      r5 = 1;

      // generate output samples
      PROFILER_START_SBCDEC(&$sbcdec.profile_synthesis_subband_filter)
      call $sbcdec.synthesis_subband_filter;
      PROFILER_STOP_SBCDEC(&$sbcdec.profile_synthesis_subband_filter)

      // store updated cbuffer pointers for right audio output
      r5 = M[$sbcdec.codec_struc];
      r1 = I1;
      r0 = M[r5 + $codec.DECODER_OUT_RIGHT_BUFFER_FIELD];
      call $cbuffer.set_write_address;
      L1 = 0;
   no_right_buffer:



   all_done:

   #ifdef DEBUG_SBCDEC
      // -- increment frame counter --
      r0 = M[$sbcdec.framecount];
      r0 = r0 + 1;
      M[$sbcdec.framecount] = r0;
   #endif


   // -- update $codec.DECODER_STRUC --
   r0 = $codec.SUCCESS;
   M[r5 + $codec.DECODER_MODE_FIELD] = r0;


   r0 = M[r9 + $sbc.mem.NROF_BLOCKS_FIELD];
   r1 = M[r9 + $sbc.mem.NROF_SUBBANDS_FIELD];


   r0 = r0 * r1 (int);
   M[r5 + $codec.DECODER_NUM_OUTPUT_SAMPLES_FIELD] = r0;


   exit:
   L0 = 0;
   // -- Stop overall profiling if enabled --
   PROFILER_STOP_SBCDEC(&$sbcdec.profile_frame_decode)

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
#endif
