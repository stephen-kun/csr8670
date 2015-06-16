
// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2005)        http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************

// **********************************************************************************************
// NAME:
//    DSP A2DP Source Application
//
// DESCRIPTION:
//   This is DSP A2DP Source Application which encodes data to stream over the
//   air, the audio input for the codec can be one of these sources:
//   - USB (from PC for example)
//   - Analogue (e.g. internal ADC)
//   - S/PDIF, only PCM is supported, any coded SPDIF input will mute the link.
//
//   in all input modes it supports SBC, aptX and CSR proprietary FastStream codecs, MP3 encoding
//   is also possible but not included in the release.
//   The application is configured by vm so it knows what type of input it will receive and
//   what would be the coded type.
//
// Sample Rate Converter:
//  The configuration also determines whether the application needs to resample the input
//  audio before encoding them. USB audio from PC is assumed to be 48khz stereo, S/PDIF
//  audio can be 32, 44.1 or 48KHz. To enable encoding in other sample rates,
//  sample-rate-converter(SRC) is used before passing audio data to codecs, SRC isn't active
//  in for analogue input, as the codec and input sample rates are expected to be the same.
//
// ***********************************************************************************************

//#define WOODSTOCK
#ifdef WOODSTOCK
    #define USES_PEQ
#endif // WOODSTOCK

// ** defining timer interrupt periods **
#define $TMR_PERIOD_USB_COPY                     625    // timer period to read the USB port data
#define $TMR_PERIOD_AUDIO_COPY                   1000   // timer period to read the audio data in analogue mode (for MP3 and SBC)
#define $FASTSTREAM_TMR_PERIOD_AUDIO_COPY        500    // timer period to read the audio data in analogue mode (for faststream only)
#define $TMR_PERIOD_USB_OUT_AUDIO_COPY           1000   // timer period to write audio data into USB port
#define $TMR_PERIOD_CODEC_COPY                   8000   // timer period to write codec output to codec port (for MP3 and SBC)
#define $FASTSTREAM_TMR_PERIOD_CODEC_COPY        1000   // timer period to write codec output to codec port (for faststream only)

#define $PEQ_COPY_MINIMUM                        25  // based on 1000 audio copy timer period
#define $PEQ_COPY_MAXIMUM                        50  // based on 1000 audio copy timer period

#define $BLOCK_SIZE                              16
#define $RESAMPLER_READ_BACK                     50
#define $USB_SAMPLE_RATE                         48000
#define $DEFAULT_MINIMIMUM_CODEC_DATA_TO_COPY    1
#define $FASTSTREAM_MINIMUM_CODEC_DATA_TO_COPY   100 //this limit is for faststream copying codec data into the port (slightly less than 3 frames = 3*36=108 words
#define $USB_STALL_TIME_BEFORE_SILENCE_INSERTION 5  // minimum no activity time(in ms) in usb in port before sending silence

#ifdef SELECTED_ENCODER_SBC
   #define SELECTED_CODEC_FRAME_ENCODE_FUNCTION        &$sbcenc.frame_encode
   #define SELECTED_CODEC_RESET_ENCODER_FUNCTION       &$sbcenc.reset_encoder
   #define SELECTED_CODEC_INITIALISE_ENCODER_FUNCTION  $sbcenc.init_static_encoder
   #define SELECTED_ENCODER_LIBRARY_HEADER             "sbc_library.h"
   #define SBC_BITPOOL_CHANGE_MESSAGE                  0x7070
   #define SBC_BITPOOL_SET_LOW_MESSAGE                 0x7080
   #define $PAUSE_SILENCE_DURATION_TO_SEND_MS          200 // amount of silence (in ms) streamed when inactivity in USB port is detected
   #define ENABLE_FASTSTREAM_VOICE                     // define this option to enable bidirectional faststream
   #ifdef ENABLE_FASTSTREAM_VOICE
      #define SELECTED_DECODER_FRAME_DECODE_FUNCTION        &$sbcdec.frame_decode
      #define SELECTED_DECODER_RESET_DECODER_FUNCTION       &$sbcdec.reset_decoder
      #define SELECTED_DECODER_SILENCE_DECODER_FUNCTION     &$sbcdec.silence_decoder
      #define SELECTED_DECODER_INITIALISE_DECODER_FUNCTION  $sbcdec.init_static_decoder
      #define MONITOR_CODEC_BUFFER_LEVEL               253
      #define FAST_STREAM_FRAME_LENGTH                 36
   #endif
#endif

#ifdef SELECTED_ENCODER_MP3
   #define SELECTED_CODEC_FRAME_ENCODE_FUNCTION        &$mp3enc.frame_encode
   #define SELECTED_CODEC_RESET_ENCODER_FUNCTION       &$mp3enc.reset_encoder
   #define SELECTED_CODEC_INITIALISE_ENCODER_FUNCTION  &$mp3enc.init_encoder
   #define SELECTED_ENCODER_LIBRARY_HEADER             "mp3enc_library.h"
    .CONST $MESSAGE_MP3ENC_UPDATE_SETTING               0x7060;
   #define $PAUSE_SILENCE_DURATION_TO_SEND_MS          700 // amount of silence (in ms) streamed when inactivity in USB port is detected
#endif

#ifdef SELECTED_ENCODER_APTX
   #define SELECTED_CODEC_FRAME_ENCODE_FUNCTION        &$aptx.encode
   #define SELECTED_CODEC_RESET_ENCODER_FUNCTION       &$aptx.reset_encoder
   #define SELECTED_CODEC_INITIALISE_ENCODER_FUNCTION  0
   .CONST  $MESSAGE_SET_SAMPLE_RATE                   0x7050;
   #define $PAUSE_SILENCE_DURATION_TO_SEND_MS          200 // amount of silence (in ms) streamed when inactivity in USB port is detected
#endif

#ifdef WOODSTOCK
   #define WOODSTOCK_PEQ_SELECT_CURVE_MESSAGE          0x7090
   #define WOODSTOCK_MUTE_SPEAKER_MESSAGE              0x70a0
   #define WOODSTOCK_MUTE_MICROPHONE_MESSAGE           0x70b0
#endif // WOODSTOCK

#define $PAUSE_SILENCE_DURATION_TO_SEND ($PAUSE_SILENCE_DURATION_TO_SEND_MS*1000/$TMR_PERIOD_USB_COPY)

// includes required header files
#include "core_library.h"
#include "cbops_library.h"
#include "codec_library.h"
#include "mv_codec_encoder.h"
#include "src.h"
#include "sbc_library.h"
#ifndef SELECTED_ENCODER_APTX
    #include SELECTED_ENCODER_LIBRARY_HEADER
#endif
#ifdef WOODSTOCK
    #include "kalimba_standard_messages.h"
#endif // WOODSTOCK

#ifdef SPDIF_ENABLE
   #include "spdif_library.h"

   #define VM_CONFIG_SPDIF_APP_MESSAGE_ID             0x1073  // VM to DSP, to configure the spdif sink app
   .CONST $SPDIF_EVENT_MSG                            0x1075; // DSP to VM. to notify events in the input stream
   #define $TMR_PERIOD_SPDIF_COPY                     1000    // timer period to reads the spdif data
   #define SPDIF_PAUSE_THRESHOLD_US                   3000    // pause detection threshold in micro seconds

   // Port used for SPDIF inputs
   .CONST $SPDIF_IN_LEFT_PORT        ($cbuffer.READ_PORT_MASK  + 0 + $cbuffer.FORCE_NO_SIGN_EXTEND);
   .CONST $SPDIF_IN_RIGHT_PORT       ($cbuffer.READ_PORT_MASK  + 1 + $cbuffer.FORCE_NO_SIGN_EXTEND);

#endif // #ifdef SPDIF_ENABLE

#ifdef USES_PEQ

   .CONST $mv_dongle.peq.INPUT_ADDR_FIELD               0;

   // Size of input audio stream circular buffer size, '0' if linear buffer
   .CONST $mv_dongle.peq.INPUT_SIZE_FIELD               1;

   // Pointer to output audio stream
   .CONST $mv_dongle.peq.OUTPUT_ADDR_FIELD              2;

   // Size of output audio stream circular buffer size, '0' if linear buffer
   .CONST $mv_dongle.peq.OUTPUT_SIZE_FIELD              3;

   // Pointer to PEQ delay buffer, MUST be circular
   // Minimum size of the buffer: 2 * (number of stages + 1)
   .CONST $mv_dongle.peq.DELAYLINE_ADDR_FIELD           4;

   // Pointer to PEQ filter coefficients buffer, MUST be circular
   // Minimum size of the buffer: 5 * (number of stages)
   // The filter coefficients should be arranged in the following order:
   // - stage 1: b2(1), b1(1), b0(1), a2(1), a1(1)
   // - stage 2: b2(2), b1(2), b0(2), a2(2), a1(2)
   // . .......: ....., ....., ....., ....., .....
   // - stage n: b2(n), b1(n), b0(n), a2(n), a1(n)
   .CONST $mv_dongle.peq.COEFS_ADDR_FIELD               5;

   // Number of stage
   .CONST $mv_dongle.peq.NUM_STAGES_FIELD               6;

   // Size of delay line circular buffer
   // This field is set by initialisation routine based on NUM_STAGES_FIELD
   .CONST $mv_dongle.peq.DELAYLINE_SIZE_FIELD           7;

   // Size of filter coefficients circular buffer
   // This field is set by initialisation routine based on NUM_STAGES_FIELD
   .CONST $mv_dongle.peq.COEFS_SIZE_FIELD               8;

   // Size of data block to be processed
   .CONST $mv_dongle.peq.BLOCK_SIZE_FIELD               9;

   // Pointer to scaling buffer
   // Minimum size of the buffer: (number of stages), scaling for each stage
   .CONST $mv_dongle.peq.SCALING_ADDR_FIELD             10;

   // Pointer to 'gain exponent' variable
   .CONST $mv_dongle.peq.GAIN_EXPONENT_ADDR_FIELD       11;

   // Pointer to 'gain mantissa' variable
   .CONST $mv_dongle.peq.GAIN_MANTISA_ADDR_FIELD        12;

   // Structure size of PEQ data object
   .CONST $mv_dongle.peq.STRUC_SIZE                     13;

#endif

#ifdef SELECTED_ENCODER_APTX
   // Port limit to prevent "lone" byte issue in the sink side
   .CONST  $OUT_PORT_FILL_LIMIT    425;         // Limit on the output port fill level (in words)
#endif

// *****************************************************************************
// DESCRIPTION
//    Main routine for DSP a2dp source application
//
//    Input: none
//    Output: none
//    Trash: Everything
//
// *****************************************************************************
.MODULE $M.main;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   // These scratch "registers" are used by various libraries (e.g. SBC)
   .VAR $scratch.s0;
   .VAR $scratch.s1;
   .VAR $scratch.s2;

   $main:


   .CONST  $USB_IN_PORT         ($cbuffer.READ_PORT_MASK  + 0);
   .CONST  $USB_OUT_PORT        ($cbuffer.WRITE_PORT_MASK + 1);

   .CONST  $AUDIO_LEFT_IN_PORT  ($cbuffer.READ_PORT_MASK + 0);
   .CONST  $AUDIO_RIGHT_IN_PORT ($cbuffer.READ_PORT_MASK + 1);

   .CONST  $CODEC_OUT_PORT      ($cbuffer.WRITE_PORT_MASK + 2);
   .CONST  $CODEC_OUT_PORT_TWO  ($cbuffer.WRITE_PORT_MASK + 3);
   .CONST  $CODEC_IN_PORT       ($cbuffer.READ_PORT_MASK  + 2);


#ifdef ENABLE_FASTSTREAM_VOICE
   .VAR $fs_voice_enabled;                        // flag showing bidir faststream is active
   .VAR $port_inactive_hist;                      // variable showing USB voice port activity history
   .VAR/DMCIRC $codec_in[1024];                   // buffer for received encoded voice from sink side
   .VAR/DMCIRC $audio_out_mono[256];              // buffer for decoded audio (16khz)
   .VAR/DMCIRC $audio_out_mono_resampled[256*3];  // buffer for decoded audio after resampling

   // ** allocate memory cbuffer structures for voice channels
   .VAR $codec_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
          LENGTH($codec_in),              // size
          &$codec_in,                     // read pointer
          &$codec_in;                     // write pointer
   .VAR $audio_out_mono_cbuffer_struc[$cbuffer.STRUC_SIZE] =
          LENGTH($audio_out_mono),        // size
          &$audio_out_mono,               // read pointer
          &$audio_out_mono;               // write pointer
    .VAR $audio_out_mono_resampled_cbuffer_struc[$cbuffer.STRUC_SIZE] =
          LENGTH($audio_out_mono_resampled),       // size
          &$audio_out_mono_resampled,              // read pointer
          &$audio_out_mono_resampled;              // write pointer

   // ** allocate memory for codec input cbops copy routine **
   .VAR $codec_in_copy_struc[] =
          &$codec_in_copy_op,             // first operator block
          1,                              // number of inputs
          $CODEC_IN_PORT,                 // input
          1,                              // number of outputs
          &$codec_in_cbuffer_struc;       // output

   .BLOCK $codec_in_copy_op;
      .VAR $codec_in_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $codec_in_copy_op.func = &$cbops.copy_op;
      .VAR $codec_in_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
               0,                         // Input index
               1;                         // Output index
   .ENDBLOCK;

  .VAR/DM1CIRC $hist_16kup[24];
  .VAR    $audio_out_upsample_16_to_48_struct[$src.upsample_downsample.STRUC_SIZE] =
         &$audio_out_mono_cbuffer_struc,          // left channel input
         0,                              // no right channel input
         &$audio_out_mono_resampled_cbuffer_struc,     // left channel output
            0,                           // no right channel output
         &$coeffs_16kup,                       // anti-aliasing filter coefficients (must be in DM2)
         &$hist_16kup,                          // left input history
         0,                                    // no right input history
         24,                                   // (size of coeffs)/L
         1,                                    // decimation factor (M)
         3,                           // pre upsampling factor (L)
         0,                           // Int(M/L)
         1.0/3.0,                     // Frac(M/L)
         1.0,                         // 1.0/M.0
         0 ...;

  .VAR/DM1 $decoder_codec_stream_struc[$codec.av_decode.STRUC_SIZE] =
            SELECTED_DECODER_FRAME_DECODE_FUNCTION,    // frame_decode function
            SELECTED_DECODER_RESET_DECODER_FUNCTION,   // reset_decoder function
            SELECTED_DECODER_SILENCE_DECODER_FUNCTION, // silence_decoder function
            &$codec_in_cbuffer_struc,                // in cbuffer
#ifdef USB_MIC_16K      /* Back channel is output at 16 kHz over USB */
            &$audio_out_mono_resampled_cbuffer_struc,          // out left cbuffer
#else                   /* Back channel is output at 48 kHz over USB using upsampler */
            &$audio_out_mono_cbuffer_struc,                    // out left cbuffer
#endif
            0,                               // out right cbuffer
            0,                               // MODE_FIELD
            0,                               // number of output samples
            0,                               // data object pointer
            60000,                           // DECODE_TO_STALL_THRESHOLD
            0.12,                            // STALL_BUFFER_LEVEL_FIELD
            0 ...;                           // NORMAL_BUFFER_LEVEL_FIELD not used

        /* USB out copy operator structure */
   .VAR $faststream_voice_copy_struc[] =
            &$faststream_voice_shift_op,
            1,
            &$audio_out_mono_resampled_cbuffer_struc,
            1,
            $USB_OUT_PORT;
   .BLOCK $faststream_voice_shift_op;
      .VAR $faststream_voice_shift_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $faststream_voice_shift_op.func = &$cbops.shift;
      .VAR $faststream_voice_shift_op.param[$cbops.shift.STRUC_SIZE] =
            0,
            1,
            -8;
   .ENDBLOCK;
#endif       //.ifdef ENABLE_FASTSTREAM_VOICE
   // ** allocate memory for cbuffers and structures **

   // ** defining cbuffers for input audio

#ifdef USES_PEQ
   declare_cbuf_and_struc($peq_in_left,    $peq_in_left_cbuffer_struc,    AUDIO_CBUFFER_SIZE)
   declare_cbuf_and_struc($peq_in_right,   $peq_in_right_cbuffer_struc,   AUDIO_CBUFFER_SIZE)
#endif

   // ** if sampling rate is 48000 they are directly passed to the codec other wise used as input of resampler **
   declare_cbuf_and_struc($audio_in_left,    $audio_in_left_cbuffer_struc,    AUDIO_CBUFFER_SIZE)
   declare_cbuf_and_struc($audio_in_right,   $audio_in_right_cbuffer_struc,   AUDIO_CBUFFER_SIZE)

   // ** $usb_out_resample is used to upsample voice channel before copying to $USB_OUT_PORT **
   declare_cbuf_and_struc($usb_out_resample, $usb_out_resample_cbuffer_struc, USB_OUT_CBUFFER_SIZE)

   // ** defining cbuffers for resampled input audio **
   // ** these cbuffers are used as final input to codec when sampling rate is not 48000 **
   declare_cbuf_and_struc($audio_in_left_resample,    $audio_in_left_resample_cbuffer_struc,    AUDIO_CBUFFER_SIZE)
   declare_cbuf_and_struc($audio_in_right_resample,   $audio_in_right_resample_cbuffer_struc,   AUDIO_CBUFFER_SIZE)

   // ** defining cbuffers for codec output **
   declare_cbuf_and_struc($codec_out,        $codec_out_cbuffer_struc,        CODEC_CBUFFER_SIZE)

   // define memory for src coefficients, maximum needed size is defined
   // coeffs are read from flash memory into this buffer when required
   .VAR/DM $src.coeffs[$src.SRC_MAX_UPSAMPLE_RATE*$src.SRC_MAX_FILTER_LEN];


   // ** allocate memory for timer structures **
   .VAR $audio_copy_timer_struc[$timer.STRUC_SIZE];         /* DSP -> $USB_OUT_PORT */
   .VAR $av_copy_timer_struc[$timer.STRUC_SIZE];            /* Codec output -> $CODEC_OUT_PORT */
   .VAR $audio_in_timer_struc[$timer.STRUC_SIZE];           /* Analogue input -> DSP */
   .VAR $usb_copy_timer_struc[$timer.STRUC_SIZE];              /* $USB_IN_PORT -> DSP */


   // ** Audio PEQ buffers **
   #define MAX_NUM_PEQ_STAGES (5)

#ifdef WOODSTOCK
    #if (MAX_NUM_PEQ_STAGES != 5)
        .error WOODSTOCK MODS REQUIRE NUMBER OF PEQ STAGES TO BE 5
    #endif
#endif // WOODSTOCK

#ifdef USES_PEQ
   .VAR  ZeroValue = 0;
   .VAR  OneValue = 1.0;

   .VAR/DM2CIRC left_peq_delaybuf_dm2[2 * (MAX_NUM_PEQ_STAGES + 1)];
   .VAR/DM2CIRC right_peq_delaybuf_dm2[2 * (MAX_NUM_PEQ_STAGES + 1)];
   .VAR/DM1CIRC peq_coeffs1[6 * MAX_NUM_PEQ_STAGES] =
    #ifdef WOODSTOCK
               0x000000, 0x000000, 0x7fffff, 0x000000, 0x000000,
               0x000000, 0x000000, 0x7fffff, 0x000000, 0x000000,
               0x000000, 0x000000, 0x7fffff, 0x000000, 0x000000,
               0x000000, 0x000000, 0x7fffff, 0x000000, 0x000000,
               0x000000, 0x000000, 0x7fffff, 0x000000, 0x000000,
               0,0,0,0,0;
    #else // WOODSTOCK
                0x33E7EF,
                0x8CAB31,
                0x42116A,
                0x35F95A,
                0x8CAB31,
                0x2BE882,
                0x9AF23F,
                0x4127C1,
                0x2D1044,
                0x9AF23F,
                0x1FC756,
                0xB6E2D3,
                0x3FFFFF,
                0x1FC756,
                0xB6E2D3,
                0x1D7F9A,
                0xD2A8DE,
                0x7FFFFF,
                0x1D7F9A,
                0xD2A8DE,
                0xE658C4,
                0x465179,
                0x7FFFFF,
                0xE658C4,
                0x465179,
                1,1,1,0,0;
    #endif // WOODSTOCK



   .VAR $left_peq_struc[$mv_dongle.peq.STRUC_SIZE] =
      0,                                    // PTR_INPUT_DATA_BUFF_FIELD
      0,                                    // INPUT_CIRCBUFF_SIZE_FIELD
      0,                                    // PTR_OUTPUT_DATA_BUFF_FIELD
      0,                                    // OUTPUT_CIRCBUFF_SIZE_FIELD
      &left_peq_delaybuf_dm2,               // PTR_DELAY_LINE_FIELD
      &peq_coeffs1,                         // PTR_COEFS_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,                   // NUM_STAGES_FIELD
      0,                                    // DELAY_BUF_SIZE
      0,                                    // COEFF_BUF_SIZE
      0,                                    // BLOCK_SIZE_FIELD
      &peq_coeffs1+5*MAX_NUM_PEQ_STAGES,    // PTR_SCALE_BUFF_FIELD
      &ZeroValue,                           // INPUT_GAIN_EXPONENT_PTR
      &OneValue;                            // INPUT_GAIN_MANTISSA_PTR

   .VAR $right_peq_struc[$mv_dongle.peq.STRUC_SIZE] =
      0,                                    // PTR_INPUT_DATA_BUFF_FIELD
      0,                                    // INPUT_CIRCBUFF_SIZE_FIELD
      0,                                    // PTR_OUTPUT_DATA_BUFF_FIELD
      0,                                    // OUTPUT_CIRCBUFF_SIZE_FIELD
      &right_peq_delaybuf_dm2,              // PTR_DELAY_LINE_FIELD
      &peq_coeffs1,                         // PTR_COEFS_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,                   // NUM_STAGES_FIELD
      0,                                    // DELAY_BUF_SIZE
      0,                                    // COEFF_BUF_SIZE
      0,                                    // BLOCK_SIZE_FIELD
      &peq_coeffs1+5*MAX_NUM_PEQ_STAGES,    // PTR_SCALE_BUFF_FIELD
      &ZeroValue,                           // INPUT_GAIN_EXPONENT_PTR
      &OneValue;                            // INPUT_GAIN_MANTISSA_PTR
#endif

   .VAR/DM  $codec_sample_rate = 48000;            // default codec sample rate = 48000
   .VAR/DM  $input_sample_rate = 48000;            // default input sample rate = 48000
   .VAR/DM  $codec_sample_rate_from_vm = 48000;
   .VAR/DM  $codec_type = 0;                       // default codec type = SBC


   /* USB in copy operator structure */

   .VAR/DM1 $usb_audio_in_copy_struc[$mvdongle.STEREO_COPY_STRUC_SIZE] =
            $USB_IN_PORT,                    // $USB_IN.STEREO_COPY_SOURCE_FIELD
#ifdef USES_PEQ
            &$peq_in_left_cbuffer_struc,   // $USB_IN.STEREO_COPY_LEFT_SINK_FIELD
            &$peq_in_right_cbuffer_struc,  // $USB_IN.STEREO_COPY_RIGHT_SINK_FIELD
#else
            &$audio_in_left_cbuffer_struc,   // $USB_IN.STEREO_COPY_LEFT_SINK_FIELD
            &$audio_in_right_cbuffer_struc,  // $USB_IN.STEREO_COPY_RIGHT_SINK_FIELD
#endif
            $USB_SAMPLE_RATE/250,            // $USB_IN.STEREO_COPY_PACKET_LENGTH_FIELD
            8,                               // $USB_IN.STEREO_COPY_SHIFT_AMOUNT_FIELD
            0 ...;



    /* USB out copy operator structure */
   .VAR $usb_audio_out_copy_struc[] =
            &$usb_out_shift_op,
            1,
            &$usb_out_resample_cbuffer_struc,
            1,
            $USB_OUT_PORT;
   .BLOCK $usb_out_shift_op;
      .VAR usb_out_shift_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR usb_out_shift_op.func = &$cbops.shift;
      .VAR usb_out_shift_op.param[$cbops.shift.STRUC_SIZE] =
            0,
            1,
            -8;
   .ENDBLOCK;

   // ** allocate memory for codec output cbops copy routine **
   .VAR $codec_out_copy_struc[] =
#ifdef SELECTED_ENCODER_APTX
            &$codec_fill_limit,                 // first operator block
#else
            &$codec_out_copy_op,                // first operator block
#endif
            1,                                  // number of inputs
            &$codec_out_cbuffer_struc,          // input
            1,                                  // number of outputs
            $CODEC_OUT_PORT;                    // output

#ifdef SELECTED_ENCODER_APTX
   // This restricts copy operations so that the output port will not
   // contain more than the number of words of data in the
   // operator FILL_LIMIT_FIELD field. This is a source side workaround
   // for ACBU-2436.
   //
   // This limits the size of a packet so it is smaller than the MTU.
   // This prevents the situation where the decoder has an input port
   // containing a single byte and the FW attempts to put an MTU size
   // packet (=buffer size) into the port.
   .BLOCK $codec_fill_limit;
      .VAR $codec_fill_limit.next = $codec_out_copy_op;
      .VAR $codec_fill_limit.func = &$cbops.fill_limit;
      .VAR $codec_fill_limit.param[$cbops.fill_limit.STRUC_SIZE] =
      $OUT_PORT_FILL_LIMIT,         // Output data limit in words
      $CODEC_OUT_PORT;              // Need to specify the output port
   .ENDBLOCK;
#endif

   .BLOCK $codec_out_copy_op;
      .VAR $codec_out_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $codec_out_copy_op.func = &$cbops.copy_op;
      .VAR $codec_out_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
               0,                         // Input index
               1;                         // Output index
   .ENDBLOCK;

   .VAR $codec_out_copy_two_struc[] =
#ifdef SELECTED_ENCODER_APTX
            &$codec_fill_limit2,                // first operator block
#else
            &$codec_out_copy_two_op,            // first operator block
#endif
            1,                                  // number of inputs
            &$codec_out_cbuffer_struc,          // input
            1,                                  // number of outputs
            $CODEC_OUT_PORT_TWO;                // output

#ifdef SELECTED_ENCODER_APTX
   .BLOCK $codec_fill_limit2;
      .VAR $codec_fill_limit2.next = $codec_out_copy_two_op;
      .VAR $codec_fill_limit2.func = &$cbops.fill_limit;
      .VAR $codec_fill_limit2.param[$cbops.fill_limit.STRUC_SIZE] =
      $OUT_PORT_FILL_LIMIT,         // Output data limit in words
      $CODEC_OUT_PORT_TWO;          // Need to specify the output port
   .ENDBLOCK;
#endif

   .BLOCK $codec_out_copy_two_op;
      .VAR $codec_out_copy_two_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $codec_out_copy_two_op.func = &$cbops.copy_op;
      .VAR $codec_out_copy_two_op.param[$cbops.copy_op.STRUC_SIZE] =
               0,                         // Input index
               1;                         // Output index
   .ENDBLOCK;


// *** Dual Stream ***
   .VAR $ds_codec_out_copy_one_struc[] =
#ifdef SELECTED_ENCODER_APTX
            &$ds_codec_fill_limit,              // first operator block
#else
            &$ds_codec_out_copy_one_op,         // first operator block
#endif
            1,                                  // number of inputs
            &$codec_out_cbuffer_struc,          // input
            1,                                  // number of outputs
            $CODEC_OUT_PORT;                    // output

#ifdef SELECTED_ENCODER_APTX
   .BLOCK $ds_codec_fill_limit;
      .VAR $ds_codec_fill_limit.next = $ds_codec_out_copy_one_op;
      .VAR $ds_codec_fill_limit.func = &$cbops.fill_limit;
      .VAR $ds_codec_fill_limit.param[$cbops.fill_limit.STRUC_SIZE] =
      $OUT_PORT_FILL_LIMIT,         // Output data limit in words
      $CODEC_OUT_PORT;              // Need to specify the output port
   .ENDBLOCK;
#endif

   .BLOCK $ds_codec_out_copy_one_op;
      .VAR $ds_codec_out_copy_one_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $ds_codec_out_copy_one_op.func = &$cbops.copy_op;
      .VAR $ds_codec_out_copy_one_op.param[$cbops.copy_op.STRUC_SIZE] =
            0,                         // Input index
            1;                         // Output index
   .ENDBLOCK;

   .VAR $ds_codec_out_copy_two_struc[] =
#ifdef SELECTED_ENCODER_APTX
            &$ds_codec_fill_limit2,              // first operator block
#else
            &$ds_codec_out_copy_two_op,         // first operator block
#endif
            1,                                  // number of inputs
            &$codec_out_cbuffer_struc,          // input
            1,                                  // number of outputs
            $CODEC_OUT_PORT_TWO;                // output

#ifdef SELECTED_ENCODER_APTX
   .BLOCK $ds_codec_fill_limit2;
      .VAR $ds_codec_fill_limit2.next = $ds_codec_out_copy_two_op;
      .VAR $ds_codec_fill_limit2.func = &$cbops.fill_limit;
      .VAR $ds_codec_fill_limit2.param[$cbops.fill_limit.STRUC_SIZE] =
      $OUT_PORT_FILL_LIMIT,         // Output data limit in words
      $CODEC_OUT_PORT_TWO;          // Need to specify the output port
   .ENDBLOCK;
#endif

   .BLOCK $ds_codec_out_copy_two_op;
      .VAR $ds_codec_out_copy_two_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $ds_codec_out_copy_two_op.func = &$cbops.copy_op;
      .VAR $ds_codec_out_copy_two_op.param[$cbops.copy_op.STRUC_SIZE] =
            0,                         // Input index
            1;                         // Output index
   .ENDBLOCK;
// *** *** *** ***



   // ** allocate memory for stereo audio out cbops copy routine **
   .VAR $stereo_audio_in_copy_struc[] =
         &$audio_in_shift_op_left,        // first operator block
         2,                               // number of inputs
         $AUDIO_LEFT_IN_PORT,             // input
         $AUDIO_RIGHT_IN_PORT,            // input
         2,                               // number of outputs
#ifdef USES_PEQ
         &$peq_in_left_cbuffer_struc,     // output
         &$peq_in_right_cbuffer_struc;    // output
#else
         &$audio_in_left_cbuffer_struc,   // output
         &$audio_in_right_cbuffer_struc;  // output
#endif


   .BLOCK $audio_in_shift_op_left;
         .VAR audio_in_shift_op_left.next = &$audio_in_dc_remove_op_left;
         .VAR audio_in_shift_op_left.func = &$cbops.shift;
         .VAR audio_in_shift_op_left.param[$cbops.shift.STRUC_SIZE] =
                  0,                      // Input index (left input port)
                  2,                      // Output index (left cbuffer)
                  8;                      // Shift amount
   .ENDBLOCK;

   .BLOCK $audio_in_dc_remove_op_left;
         .VAR audio_in_dc_remove_op_left.next = &$audio_in_shift_op_right;
         .VAR audio_in_dc_remove_op_left.func = &$cbops.dc_remove;
         .VAR audio_in_dc_remove_op_left.param[$cbops.dc_remove.STRUC_SIZE] =
                  2,                      // Input index (left cbuffer)
                  2,                      // Output index (left cbuffer)
                  0 ...;
   .ENDBLOCK;

   .BLOCK $audio_in_shift_op_right;
         .VAR audio_in_shift_op_right.next = &$audio_in_dc_remove_op_right;
         .VAR audio_in_shift_op_right.func = &$cbops.shift;
         .VAR audio_in_shift_op_right.param[$cbops.shift.STRUC_SIZE] =
                  1,                      // Input index (right input port)
                  3,                      // Output index (right cbuffer)
                  8;                      // Shift amount
   .ENDBLOCK;

#ifdef ANALOGUE_NOISE_GATE_OFF

   .BLOCK $audio_in_dc_remove_op_right;
         .VAR audio_in_dc_remove_op_right.next = $cbops.NO_MORE_OPERATORS;
         .VAR audio_in_dc_remove_op_right.func = &$cbops.dc_remove;
         .VAR audio_in_dc_remove_op_right.param[$cbops.dc_remove.STRUC_SIZE] =
                  3,                      // Input index (right cbuffer)
                  3,                      // Output index (right cbuffer)
                  0 ...;

   .ENDBLOCK;

#else // .ifdef ANALOGUE_NOISE_GATE_OFF

  .BLOCK $audio_in_dc_remove_op_right;
         .VAR audio_in_dc_remove_op_right.next = &$audio_in_noise_gate_op_left;
         .VAR audio_in_dc_remove_op_right.func = &$cbops.dc_remove;
         .VAR audio_in_dc_remove_op_right.param[$cbops.dc_remove.STRUC_SIZE] =
                  3,                      // Input index (right cbuffer)
                  3,                      // Output index (right cbuffer)
                  0 ...;

   .ENDBLOCK;

   .BLOCK $audio_in_noise_gate_op_left;
         .VAR audio_in_noise_gate_op_left.next = &$audio_in_noise_gate_op_right;
         .VAR audio_in_noise_gate_op_left.func = &$cbops.noise_gate;
         .VAR audio_in_noise_gate_op_left.param[$cbops.noise_gate.STRUC_SIZE] =
                  2,                      // Input index (left cbuffer)
                  2,                      // Output index (left cbuffer)
                  0 ...;

   .ENDBLOCK;

   .BLOCK $audio_in_noise_gate_op_right;
         .VAR audio_in_noise_gate_op_right.next = $cbops.NO_MORE_OPERATORS;
         .VAR audio_in_noise_gate_op_right.func = &$cbops.noise_gate;
         .VAR audio_in_noise_gate_op_right.param[$cbops.noise_gate.STRUC_SIZE] =
                  3,                      // Input index (right cbuffer)
                  3,                      // Output index (right cbuffer)
                  0 ...;

   .ENDBLOCK;

#endif // .ifdef ANALOGUE_NOISE_GATE_OFF

   // ** allocate memory for mono audio out cbops copy routine **

   .VAR $mono_audio_in_copy_struc[] =
         &$audio_in_shift_op_mono,
         1,     // number of inputs
         $AUDIO_LEFT_IN_PORT,
         1,     // number of outputs
#ifdef USES_PEQ
         &$peq_in_left_cbuffer_struc;
#else
         &$audio_in_left_cbuffer_struc;
#endif

   .BLOCK $audio_in_shift_op_mono;
         .VAR audio_in_shift_op_mono.next = &$audio_in_dc_remove_op_mono;
         .VAR audio_in_shift_op_mono.func = &$cbops.shift;
         .VAR audio_in_shift_op_mono.param[$cbops.shift.STRUC_SIZE] =
                  0,                      // Input index (left input port)
                  1,                      // Output index (left cbuffer)
                  8;                      // Shift amount
   .ENDBLOCK;

#ifdef ANALOGUE_NOISE_GATE_OFF

   .BLOCK $audio_in_dc_remove_op_mono;
         .VAR audio_in_dc_remove_op_mono.next = $cbops.NO_MORE_OPERATORS;
         .VAR audio_in_dc_remove_op_mono.func = &$cbops.dc_remove;
         .VAR audio_in_dc_remove_op_mono.param[$cbops.dc_remove.STRUC_SIZE] =
                  1,                      // Input index (left cbuffer)
                  1;                      // Output index (left cbuffer)
   .ENDBLOCK;

#else // .ifdef ANALOGUE_NOISE_GATE_OFF

   .BLOCK $audio_in_dc_remove_op_mono;
         .VAR audio_in_dc_remove_op_mono.next = &$audio_in_noise_gate_op_mono;
         .VAR audio_in_dc_remove_op_mono.func = &$cbops.dc_remove;
         .VAR audio_in_dc_remove_op_mono.param[$cbops.dc_remove.STRUC_SIZE] =
                  1,                      // Input index (left cbuffer)
                  1,                      // Output index (left cbuffer)
                  0 ...;
   .ENDBLOCK;

   .BLOCK $audio_in_noise_gate_op_mono;
         .VAR audio_in_noise_gate_op_mono.next = $cbops.NO_MORE_OPERATORS;
         .VAR audio_in_noise_gate_op_mono.func = &$cbops.noise_gate;
         .VAR audio_in_noise_gate_op_mono.param[$cbops.noise_gate.STRUC_SIZE] =
                  1,                      // Input index (left cbuffer)
                  1,                      // Output index (left cbuffer)
                  0 ...;

   .ENDBLOCK;

#endif //.ifdef ANALOGUE_NOISE_GATE_OFF

   // memory definitions for SRC left and right history buffers
  .VAR/DM1CIRC $hist_left[$src.SRC_MAX_FILTER_LEN];
  .VAR/DM1CIRC $hist_right[$src.SRC_MAX_FILTER_LEN];



  .VAR $audio_in_src_struct[$src.upsample_downsample.STRUC_SIZE] =
         &$audio_in_left_cbuffer_struc,           //left channel input
         &$audio_in_right_cbuffer_struc,           //right channel input
         &$audio_in_left_resample_cbuffer_struc,   //left channel output
         &$audio_in_right_resample_cbuffer_struc,  //right channel output
         &$src.coeffs,                   // anti-aliasing filter coefficients
         &$hist_left,                    // left input history
         &$hist_right,                   // right input history
         0 ...;                          // rest of the structure is configured by $setup_downsampler



   // ** allocate memory for message handlers **
   .VAR/DM1 $mv.initialise_message_struc[$message.STRUC_SIZE];
   .VAR $mv.codec_type_message_struc[$message.STRUC_SIZE];  //receive codec type from VM
   .VAR $mv.change_mode_message_struc[$message.STRUC_SIZE]; //receive operating mode from vm
#ifdef SELECTED_ENCODER_SBC
   .VAR $sbc_bitpool_message_struc[$message.STRUC_SIZE];    //SBC bitpool change message struct
   .VAR $set_low_bitpool_size_message_struc[$message.STRUC_SIZE]; // SBC set bitpool low value message sturct
#endif

#ifdef WOODSTOCK
   .VAR $woodstock_peq_message_struc[$message.STRUC_SIZE];  //receive PEQ index from VM
   .VAR $WOODSTOCK_MUTE_SPEAKER_MESSAGE_struc[$message.STRUC_SIZE]; //receive mute speaker flag from VM
   .VAR $WOODSTOCK_MUTE_MICROPHONE_MESSAGE_struc[$message.STRUC_SIZE]; //receive mute microphone flag from VM
   .var $woodstock_mute_spkr_flag = 0 ;                            // default mute spkr status is to pass audio
   .var $woodstock_mute_mic_flag = 0 ;                            // default mute mic status is to pass audio
#endif // WOODSTOCK
   // ** allocate memory for av encoder structure **
   .VAR/DM1 $av_encoder_codec_stream_struc[$codec.av_encode.STRUC_SIZE] =
            SELECTED_CODEC_FRAME_ENCODE_FUNCTION,     // frame_encode function
            SELECTED_CODEC_RESET_ENCODER_FUNCTION,    // reset_encoder function
            &$codec_out_cbuffer_struc,                // out cbuffer
            &$audio_in_left_cbuffer_struc,            // in left cbuffer
            &$audio_in_right_cbuffer_struc,           // in right cbuffer
            0 ...;                                    // will also contain new pointer to data object field


   .VAR $codec_reset_needed = 1;

    // ** allocate required variables **
   .VAR $mv.mode = $mv.mode.IDLE_MODE;

    // codec type is used to configure sbc encoder for fast stream
    // faststream in encoder side can be configured directly from vm by setting the bit 8th
    // of the setting word, however as we will add wbs this message would be required
   .VAR $mv.codec_type = -1;
   .VAR $vm.codec_type.timer_period =  $TMR_PERIOD_CODEC_COPY;
   .VAR $vm.codec_type.audio_timer_period =  $TMR_PERIOD_AUDIO_COPY;
   .VAR $vm.codec_type.minimum_data_to_copy = $DEFAULT_MINIMIMUM_CODEC_DATA_TO_COPY;

#ifdef SPDIF_ENABLE
   // ** defining cbuffers for spdif input **
   declare_cbuf_and_struc($spdif_in, $spdif_in_cbuffer_struc, SPDIF_CBUFFER_SIZE)

   // define spdif input structure
   .VAR $spdif_copy_struct[$spdif.frame_copy.STRUC_SIZE] =
      $SPDIF_IN_LEFT_PORT,                                      //LEFT_INPUT_PORT_FIELD
      $SPDIF_IN_RIGHT_PORT,                                     //RIGHT_INPUT_PORT_FIELD
      &$spdif_in_cbuffer_struc,                                 //SPDIF_INPUT_BUFFER_FIELD
      #ifdef USES_PEQ
      &$peq_in_left_cbuffer_struc,                              //LEFT_PCM_BUFFER_FIELD
      &$peq_in_right_cbuffer_struc,                             //RIGHT_PCM_BUFFER_FIELD
      #else
      &$audio_in_left_cbuffer_struc,                            //LEFT_PCM_BUFFER_FIELD
      &$audio_in_right_cbuffer_struc,                           //RIGHT_PCM_BUFFER_FIELD
      #endif
       
      0 ...;

   .VAR $spdif_stream_decode_struct[$spdif.stream_decode.STRUC_SIZE] =
      &$spdif_copy_struct,                                                   // SPDIF_FRAME_COPY_STRUCT_FIELD
      0 ...;
   .VAR $spdif_in_timer_struc[$timer.STRUC_SIZE];
   .VAR $spdif_pause_timer;
   .VAR $spdif_silence_to_insert;

   // default SPDIF config for source app, vm doesn't sent SPDIF config message
   // Always report events to VM
   r0 = 1;
   M[$spdif_copy_struct + $spdif.frame_copy.ENABLE_EVENT_REPORT_FIELD] = r0;
   // postpone disconnection for 15 seconds
   r0 = 15;
   M[$spdif_copy_struct + $spdif.frame_copy.INVALID_MESSAGE_POSTPONE_TIME_FIELD] = r0;
#endif

   // initialise the stack library
   call $stack.initialise;
   // initialise the interrupt library
   call $interrupt.initialise;
   // initialise the message library
   call $message.initialise;
   // initialise the cbuffer library
   call $cbuffer.initialise;
   // init DM_flash
   call $flash.init_dmconst;

   // Default to analog mode
   r1 = $mv.mode.ANALOG_MODE;
   call $change_mode_message_handler;

#ifdef WOODSTOCK
    // initialise the pskey library
    call $pskey.initialise;
#endif // WOODSTOCK

   // PEQ initialisation
#ifdef USES_PEQ
   r7 = $left_peq_struc;
   call $mv_dongle.peq.initialize;
   r7 = $right_peq_struc;
   call $mv_dongle.peq.initialize;
#endif

   // Initialise the codec library. Stream codec structure has codec structure nested
   // inside it, so can pass start of codec structure to init, where data object pointer
   // is also set.
   r5 = &$av_encoder_codec_stream_struc + $codec.av_encode.ENCODER_STRUC_FIELD;
   r0 = SELECTED_CODEC_INITIALISE_ENCODER_FUNCTION;
   if NZ call r0;

   // Initialise decoder for bidirectional codec
   #ifdef ENABLE_FASTSTREAM_VOICE
      r5 = &$decoder_codec_stream_struc + $codec.av_decode.DECODER_STRUC_FIELD;
      call SELECTED_DECODER_INITIALISE_DECODER_FUNCTION;
   #endif


   // register codec type message handler
   r1 = &$mv.codec_type_message_struc;
   r2 = $mv.message_from_vm.CODEC_TYPE;
   r3 = &$codec_type_message_handler;
   call $message.register_handler;


   #ifdef DEBUG_ON
      // initialise the profiler library
      call $profiler.initialise;
   #endif


   // *** register handlers to receive reset & change mode commands ***
   r1 = &$mv.change_mode_message_struc;
   r2 = $mv.message_from_vm.CHANGE_MODE;
   r3 = &$change_mode_message_handler;
   call $message.register_handler;

#ifdef SELECTED_ENCODER_SBC
   // set up an interupt for SBC bitpool size change
   r1 = &$sbc_bitpool_message_struc;
   r2 = SBC_BITPOOL_CHANGE_MESSAGE;
   r3 = &$sbc_bitpool_handler;
   call $message.register_handler;

   r1 = &$set_low_bitpool_size_message_struc;
   r2 = SBC_BITPOOL_SET_LOW_MESSAGE;
   r3 = &$sbc_set_low_bitpool_size;
   call $message.register_handler;
#endif

#ifdef WOODSTOCK
   r1 = &$woodstock_peq_message_struc;
   r2 = WOODSTOCK_PEQ_SELECT_CURVE_MESSAGE;
   r3 = &$woodstock_peq_message_handler;
   call $message.register_handler;

   r1 = &$WOODSTOCK_MUTE_SPEAKER_MESSAGE_struc;
   r2 = WOODSTOCK_MUTE_SPEAKER_MESSAGE;
   r3 = &$WOODSTOCK_MUTE_SPEAKER_MESSAGE_handler;
   call $message.register_handler;

   r1 = &$WOODSTOCK_MUTE_MICROPHONE_MESSAGE_struc;
   r2 = WOODSTOCK_MUTE_MICROPHONE_MESSAGE;
   r3 = &$WOODSTOCK_MUTE_MICROPHONE_MESSAGE_handler;
   call $message.register_handler;
#endif // WOODSTOCK

   // *** tell vm we're ready and wait for the go message ***
   call $message.send_ready_wait_for_go;

   // in vm side care has been taken that mode and codec type messages are sent before go message
   // this is just to make sure that all messages have been handled when reaching to this point
   call $timer.1ms_delay;

   /* Start the timer handlers */
   r0 = M[$mv.mode];
#ifdef SPDIF_ENABLE
   Null = r0 - $mv.mode.SPDIF_MODE;
   if NZ jump no_spdif_source_mode;

      // Start a timer that copies spdif input
      r1 = &$spdif_in_timer_struc;
      r2 = $TMR_PERIOD_SPDIF_COPY;
      r3 = &$spdif_in_copy_handler;
      call $timer.schedule_event_in;
      jump codec_copy_timer_handler;

   no_spdif_source_mode:
#endif
   Null = r0 - $mv.mode.ANALOG_MODE;

   if NZ jump no_analog_source_mode;

      r0 = $AUDIO_RIGHT_IN_PORT;
      call $cbuffer.is_it_enabled;
      if NZ jump right_port_connected;
         // tell codec library that no right buffer
         M[$av_encoder_codec_stream_struc + $codec.stream_encode.IN_RIGHT_BUFFER_FIELD] = 0;
      right_port_connected:

      // left and right audio channels from the mmu have been synced to each other
      // by the vm app but are free running in that the dsp doesn't tell them to
      // start.  We need to make sure that our copying between the cbuffers and
      // the mmu buffers starts off in sync with respect to left and right
      // channels.  To do this we make sure that when we start the copying timers
      // that there is no chance of a buffer wrap around occurring within the timer
      // period.  The easiest way to do this is to start the timers just after a
      // buffer wrap around occurs.

      // wait for ADC buffers to have just wrapped around
      wait_for_adc_buffer_wraparound:
         r0 = $AUDIO_LEFT_IN_PORT;
         call $cbuffer.calc_amount_data;
         // if the amount of data in the buffer is less than 16 samples then a
         // buffer wrap around must have just occurred.
         Null = r0 - 16;
      if POS jump wait_for_adc_buffer_wraparound;

      // start timer that copies input samples
      r1 = &$audio_in_timer_struc;
      r2 = M[$vm.codec_type.audio_timer_period];
      r3 = &$audio_in_copy_handler;
      call $timer.schedule_event_in;
      jump codec_copy_timer_handler;

   no_analog_source_mode:

   // post a timer event for the audio copy routines to USB output port
   r1 = &$audio_copy_timer_struc;
   r2 = $TMR_PERIOD_USB_OUT_AUDIO_COPY;
   r3 = &$audio_copy_handler;
   call $timer.schedule_event_in;

   // post a timer event for the audio copy routines from USB input port
   r1 = &$usb_copy_timer_struc;
   r2 = $TMR_PERIOD_USB_COPY;
   r3 = &$usb_copy_handler;
   call $timer.schedule_event_in;

   codec_copy_timer_handler:

   // post a timer event for copying codec output to CODEC output port
   r1 = &$av_copy_timer_struc;
   r2 = M[$vm.codec_type.timer_period];
   r3 = &$av_copy_handler;
   call $timer.schedule_event_in;

   .VAR running_mode = -1;
   .VAR running_mode_function;
   .VAR running_mode_function_table [$mv.mode.TOTAL_MODES] =
                             -1,                     //idle mode: no background function
                             &usb_function,          //av_mode: src+encoder
                             &analogue_function,     //analogue: encoder only
                             &spdif_function;        //spdif mode: spdif decode + src + encoder

   // ----------------------
   // Main Encoding loop
   // ------------------------
   frame_loop:

      #ifdef ENABLE_FASTSTREAM_VOICE
         r0 = 1;
         r1 = M[$codec_type];
         Null = r1 - $mv.codec_type.FASTSTREAM_BIDIR_CODEC;
         if NZ r0 = Null;
         M[$fs_voice_enabled] = r0;
      #endif

      // get the latest mode that received from vm
      r0 = M[$mv.mode];

      // if running mode is not the same as latest one ..
      Null = r0 - M[running_mode];

      // update running mode
      if NZ call change_mode;

      // jump to the appropriate function
      r0 = M[running_mode_function];
      if GT jump r0;

      // else just wait 1ms
      call $timer.1ms_delay;
      jump frame_loop;

   // -------------------------------------
   //  function that runs for spdif mode
   //
   //  SPDIF DECODE + SRC + ENCODER
   // -------------------------------------
   spdif_function:
   #ifdef SPDIF_ENABLE
       // run spdif decode
       r5 = $spdif_stream_decode_struct;
       call $spdif.decode;

       // Call the PEQ processing routine
       #ifdef USES_PEQ
          call $mv_dongle.peq.caller;
       #endif

       // get the input sample rate
       r2 = 48000;
       r1 = M[$spdif_copy_struct + $spdif.frame_copy.SAMPLING_FREQ_FIELD];
       if Z r1 = r2;
       jump check_resampler;
   #else
       // spdif mode is not expected
       call $error;
   #endif
   // -------------------------------------
   //  function that runs for USB mode
   //
   //  SRC + ENCODER
   // -------------------------------------
   usb_function:
      // get the input sample rate
      r1 = $USB_SAMPLE_RATE;
      jump check_resampler;

   // -------------------------------------
   //  function that runs for USB mode
   //
   //  just ENCODER
   // -------------------------------------
   analogue_function:
      // get the input sample rate
      // same as codec rate for analogue mode
      r1 = M[$codec_sample_rate_from_vm];

   check_resampler:
      // r1 = latest input sample rate
      // update input sample rate
      r2 = M[$input_sample_rate];
      M[$input_sample_rate] = r1;
      r0 = r1 - r2;

      // update codec sample rate
      r1 = M[$codec_sample_rate];
      r2 = M[$codec_sample_rate_from_vm];
      M[$codec_sample_rate] = r2;
      r1 = r1 - r2;

      // set up resampler if input or codec rate has changed
      r0 = r0 OR r1;
      if NZ call $setup_resampler;

      // running resampler function if needed
      r8 = $audio_in_src_struct;
      r0 = M[$resample_function];
      if NZ call r0;

   run_encoder:
      // running reset function if required
      Null = M[$codec_reset_needed];
      if Z jump no_codec_reset;
         r5 = &$av_encoder_codec_stream_struc;
         r0 = M[r5 + $codec.stream_encode.RESET_ADDR_FIELD];
         r5 = r5 + $codec.av_encode.ENCODER_STRUC_FIELD;
         call r0;
         M[$codec_reset_needed] = 0;
      no_codec_reset:

      // encode a frame
      r5 = &$av_encoder_codec_stream_struc;
      call $codec.av_encode;
      // if for any reason (not enough input/output data/space) codec
      // doesn't generate any output then wait one millisecond, so conditions to
      // call the encoder would be met in next try
      r5 = &$av_encoder_codec_stream_struc;
      r0 = M[r5 + $codec.av_encode.MODE_FIELD];
      r0 = r0 - $codec.SUCCESS;
      #ifdef ENABLE_FASTSTREAM_VOICE
         .VAR enc_ret_val;
         // run decoder if voice channel enabled
         NULL = M[$fs_voice_enabled];
         if Z jump no_voice_channel;
         M[enc_ret_val]= r0;
         r5 = &$decoder_codec_stream_struc;
         r0 = 1;
         M[r5 + $codec.av_decode.MODE_FIELD] = r0;
         call $codec.av_decode;

         #ifndef USB_MIC_16K      /* Back channel is output at 48 kHz over USB */
            // upsample voice from 16khz to 48 khz
            r8 = &$audio_out_upsample_16_to_48_struct;
            call $src.upsample_downsample;
         #endif

         // see if 1ms delay is required
         r5 = &$decoder_codec_stream_struc;
         r1 = M[r5 + $codec.av_decode.MODE_FIELD];
         r1 = r1 - $codec.SUCCESS;
         r0 = M[enc_ret_val];
         // delay if decoder and encoder both unsuccessful
         r0 = r0 OR r1;
         no_voice_channel:
      #endif

      // all mode functions return here (r0=0 if successful)
      Null = r0;
      // if not successful wait for a millisecond
      if NZ call $timer.1ms_delay;

   jump frame_loop;

// ** function that runs for av mode
  change_mode:
   $push_rLink_macro;
   // reset the codec (effective in analogue and av modes)
   r0 = 1;
   M[$codec_reset_needed] = r0;

   //update the running mode
   r0 = M[$mv.mode];
   M[running_mode] = r0;

   // update running function
   r0 = M[r0 + running_mode_function_table];
   M[running_mode_function] = r0;

   // as some cbuffers changes functionality when mode changes
   // it is required to purge all data before starting new mode

   // first block interrupts, this prevent ISR to alter R/W pointer while purging is done
   call $block_interrupts;

   r5 =$PAUSE_SILENCE_DURATION_TO_SEND;
   #ifdef ENABLE_FASTSTREAM_VOICE
      // purge $codec_in_cbuffer_struc
      r0 = $codec_in_cbuffer_struc;
      r1 = M[r0 + $cbuffer.READ_ADDR_FIELD];
      M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r1;

      // purge $audio_out_mono_cbuffer_struc
      r0 = $audio_out_mono_cbuffer_struc;
      r1 = M[r0 + $cbuffer.READ_ADDR_FIELD];
      M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r1;

      // purge $audio_out_mono_resampled_cbuffer_struc
      r0 = $audio_out_mono_resampled_cbuffer_struc;
      r1 = M[r0 + $cbuffer.READ_ADDR_FIELD];
      M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r1;

      // see if bidir flag must get active
      r0 = M[$mv.mode];
      // if bidir faststream and av_mode then set the flag
      Null = r0 - $mv.mode.USB_MODE;
      if NZ jump end_bidir_action;
      r0 = M[$codec_type];
      Null = r0 - $mv.codec_type.FASTSTREAM_BIDIR_CODEC;
      if NZ jump end_bidir_action;
      // get the music channel active for minimum 5 seconds
      // this is required in headset side
      r5 = -(5000*1000/$TMR_PERIOD_USB_COPY);
      end_bidir_action:
 #endif
   M[$usb_audio_in_copy_struc + $mvdongle.STEREO_COPY_SILENCE_CNT_FIELD] = r5;

   //reset resampler (this is necessary if $audio_in_mix and $src.coeffs share physical memory)
   M[$codec_sample_rate] = 0;

   // unblock interrupts
   call $unblock_interrupts;

 jump $pop_rLink_and_rts;


.ENDMODULE;



// *********************************************************************************
// MODULE:
//    $setup_resampler
//
// DESCRIPTION:
//   configure resample structure based on desired output rate, this function
//   configure the application to use either integer or fractional resample
//   function, it also loads the relevant coeffs from flash, it is called when the
//   codec sampling rate changes and normally run once
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r3, r4, r5, I1, I0, r10, DoLoop
//
// NOTES:
//    -Assumes that USB input sampling rate is 48000hz
//   - Should be called after codec has been configured to avoid calling twice
// **********************************************************************************
.MODULE $M.setup_resampler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $setup_resampler:

   // defining pointer to resampler function
   .VAR $resample_function;

   // look-up table containing all data needed for resampler to operate for appropriate sample rate
   .VAR src_operator_lookuptable [] =
   // fin   fout   filter length         down_rate/r_out        uprate           Int(R)   Frac(R)                          1/DOWNRATE       int(1/R)  Coeffs to load
     48000, 44100, $src.SrcCoeff44K1.SIZE,  147,        $src.SrcCoeff44K1.UPRATE,  1,   (48000.0/44100.0 - 1.0)+0.0000001, 44100.0/48000.0, 0, &$src.SrcCoeff44K1,
     48000, 32000, $src.SrcCoeff32K.SIZE,   3,          $src.SrcCoeff32K.UPRATE,   1,   (48000.0/32000.0 - 1.0)+0.0000001, 1.0/3.0,         0, &$src.SrcCoeff32K,
     48000, 22050, $src.SrcCoeff22K05.SIZE, 147,        $src.SrcCoeff22K05.UPRATE, 2,   (48000.0/22050.0 - 2.0)+0.0000001, 22050.0/48000.0, 0, &$src.SrcCoeff22K05,
     48000, 24000, $src.SrcCoeff24K.SIZE,   2,          $src.SrcCoeff24K.UPRATE,   2,   0,                                 1.0/2.0,         0, &$src.SrcCoeff24K,
     48000, 16000, $src.SrcCoeff16K.SIZE,   3,          $src.SrcCoeff16K.UPRATE,   3,   0,                                 1.0/3.0,         0, &$src.SrcCoeff16K,
     44100, 48000, $src.SrcCoeffFracUpsample.SIZE, 160, $src.SrcCoeffFracUpsample.UPRATE, 0, (44100.0/48000.0)+0.0000001,  48.0/44.1 - 1.0, 1, &$src.SrcCoeffFracUpsample,
     32000, 48000, $src.SrcCoeffFracUpsample.SIZE, 3,   $src.SrcCoeffFracUpsample.UPRATE, 0, (32000.0/48000.0)+0.0000001,  48.0/32.0 - 1.0, 1, &$src.SrcCoeffFracUpsample,
     32000, 44100, $src.SrcCoeffFracUpsample.SIZE, 441, $src.SrcCoeffFracUpsample.UPRATE, 0, (32000.0/44100.0)+0.0000001,  44.1/32.0 - 1.0, 1, &$src.SrcCoeffFracUpsample;

   $push_rLink_macro;
   //     r0 = output rate
   //     r4 = input rate
   r4 =   M[$input_sample_rate];
   r0 = M[$codec_sample_rate];

   // no resampler if input rate == output rate
   Null = r0 - r4;
   if Z jump set_default_resample;
   // search for coeffs
   I0 = src_operator_lookuptable;
   M0 = 8;
   r10 = length(src_operator_lookuptable)/9;
   do search_coeffs_loop;
      r2 = M[I0, 1];
      r3 = M[I0, 1];
      Null = r2 - r4;
      if NZ jump continue_search;
      Null = r3 - r0;
      if Z jump coeffs_found;
      continue_search:
      r2 = M[I0, M0];
   search_coeffs_loop:
   set_default_resample:
   // no src by default
   r1 = 0;
   // set default input cbuffers for codec
   r2 = &$audio_in_left_cbuffer_struc;
   r3 = &$audio_in_right_cbuffer_struc;
   jump set_resample;

   coeffs_found:
   // config the interpolator now
   r10 = 7;
   I1 = $audio_in_src_struct + $src.upsample_downsample.COEFFSIZE_FIELD;
   do config_op;
      r0 = M[I0, 1];
      M[I1, 1] = r0;
   config_op:
   // load coeffs from flash
   r0 = M[I0, 1];
   r1 = M[$audio_in_src_struct + $src.upsample_downsample.COEFFSIZE_FIELD];
   r2 = M[$audio_in_src_struct + $src.upsample_downsample.UPSAMPLE_RATE_FIELD];
   // size of filter must be coeff_size*uprate
   r1 = r1*r2 (int);
   I0 = &$src.coeffs;
   r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_32_to_24;

   // decide fractional or integer downsampling
   r1 = &$src.upsample_downsample; //integer resampling
   r0 = M[$audio_in_src_struct + $src.upsample_downsample.DECIMATION_RATE_FIELD];
   Null = r0 - 4; // if downrate field is too big then it probably is a fractional downsampling
   if NEG jump no_fractional;
   r1 = &$src.fractional_resample; //fractional downsampling
   M[$audio_in_src_struct + $src.upsample_downsample.OUT_COUNTER] = r0;
   r0 = -1.0;
   M[$audio_in_src_struct + $src.upsample_downsample.RF] = r0;
   no_fractional:

   // set the codec to use resample buffers as input
   r2 = &$audio_in_left_resample_cbuffer_struc;
   r3 = &$audio_in_right_resample_cbuffer_struc;

   set_resample:
   // configure the resample function, also codec input buffers
   M[$resample_function] = r1;
   M[$av_encoder_codec_stream_struc + $codec.stream_encode.IN_LEFT_BUFFER_FIELD] = r2;
   M[$av_encoder_codec_stream_struc + $codec.stream_encode.IN_RIGHT_BUFFER_FIELD] = r3;

   jump $pop_rLink_and_rts;

.ENDMODULE;
// *********************************************************************************
// MODULE:
//    $codec_type_message_handler
//
// DESCRIPTION:
//   handler function for receiving codec type from vm and
//   configuring sbc codec for WBS or faststream if required
//
// INPUTS:
//     - r1 =  codec type
//     - r2 =  codec sample rate
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r4
// **********************************************************************************
.MODULE $M.codec_type_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

    $codec_type_message_handler:
   M[$codec_type] = r1;
   r2 = r2 AND 0xFFFF;
   M[$codec_sample_rate_from_vm] = r2;
   #ifdef SELECTED_ENCODER_SBC
      r0 = 0;  //no post function
      r2 = $TMR_PERIOD_CODEC_COPY; //normal sbc period
     r3 = $TMR_PERIOD_AUDIO_COPY; //normal sbc
     r4 = $DEFAULT_MINIMIMUM_CODEC_DATA_TO_COPY;
     Null = r1 - $mv.codec_type.FASTSTREAM_CODEC;
    if NEG jump no_faststream;
     r0 = &$faststream.sbcenc_post_func;     //faststream codec copy period is 1ms
      r2 = $FASTSTREAM_TMR_PERIOD_CODEC_COPY; //post function
     r3 = $FASTSTREAM_TMR_PERIOD_AUDIO_COPY;
     r4= $FASTSTREAM_MINIMUM_CODEC_DATA_TO_COPY;
   no_faststream:
     // update timer period for copying codec data
     M[$vm.codec_type.timer_period] = r2;

     // update timer period for copying audio data
     M[$vm.codec_type.audio_timer_period]=r3;

     // update post function
      M[&$sbcenc.pre_post_proc_struc + $codec.pre_post_proc.POST_PROC_FUNC_ADDR_FIELD] = r0;

     // update minimum codec data to copy to codec port
     M[$vm.codec_type.minimum_data_to_copy] = r4;

   #endif
    rts;
.ENDMODULE;

// *********************************************************************************
// MODULE:
//    $change_mode_message_handler
//
// DESCRIPTION:
//   Mode change messege handler
//
// INPUTS:
//     - r1 = new mode ID
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//
// **********************************************************************************
.MODULE $M.change_mode_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $change_mode_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // store the new input mode
   M[$mv.mode] = r1;

   #ifdef SPDIF_ENABLE
      // initialise for SPDIF mode
      r5 = $spdif_stream_decode_struct;
      Null = r1 - $mv.mode.SPDIF_MODE;
      if Z call $spdif.init;
   #else
      // spdif mode is not expected
      Null = r1 - $mv.mode.SPDIF_MODE;
      if Z call $error;
   #endif

   // pop rLink onto stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#ifdef WOODSTOCK

    // *********************************************************************************
    // MODULE:
    //    $woodstock_peq_message_handler
    //
    // DESCRIPTION:
    //   change eq curve
    //
    // INPUTS:
    //    - r0 = message_ID
    //    - r1 = data[0] = new EQ curve ID
    // OUTPUTS:
    //    - none
    //
    // TRASHED REGISTERS:
    //
    // **********************************************************************************
    .MODULE $M.woodstock_peq_message_handler;
        .CODESEGMENT PM;
        .DATASEGMENT DM;

        .VAR $current_key;
        .VAR $ps_key_struc[$pskey.STRUC_SIZE];

        //-------------------------------------------------------------------
        $woodstock_peq_message_handler:
        //-------------------------------------------------------------------
        // peq change curve message.  Sends get PSKey message to VM
        //-------------------------------------------------------------------
        // PSKey = PSKEY_DSP0 + r1
        // Send Get PSKey message to VM

        // push rLink onto stack
        $push_rLink_macro;

        // http://intranet01/group/software/psbc/key_pskey_dsp0.html
        #define PSKEY_DSP0 0x2258

        r2 = PSKEY_DSP0;
        r2 = r2 + r1;
        r1 = &$ps_key_struc;
        r3 = &$woodstock_PsKeyReadHandler;
        call $pskey.read_key;
        nop;

        // pop rLink onto stack
        jump $pop_rLink_and_rts;

        //-------------------------------------------------------------------
        $woodstock_PsKeyReadHandler:
        //-------------------------------------------------------------------
        // Extract PSKey into Coefficient memory for PEQ
        //-------------------------------------------------------------------
        // r1 = Key ID
        // r2 = Buffer Length; $pskey.FAILED_READ_LENGTH on failure
        // r3 = Payload. Key ID Plus data

        NULL = r2 - $pskey.FAILED_READ_LENGTH;
        if Z rts;

        // bomb out if key length is wrong
        NULL = r2 - 46;
        if NZ rts;

        // push rLink onto stack
        $push_rLink_macro;

        I0 = r3;
        r0 = M[I0,1];            // read current key
        M[$current_key]=r0;

        // copy coefficients from PSKEY into coefficient buffer

        I4 = &$M.main.peq_coeffs1;
        r10 = 15 ;
        do woodstock_read_coefficients_pskey_loop;
            r0 = M[I0,1] ;
            r1 = M[I0,1] ;
            r2 = M[I0,1] ;

            r0 = r0 LSHIFT 8;
            r3 = r1 LSHIFT 8;       // gets rid of 8 bits of sign extension
            r3 = r3 LSHIFT -16;
            r0 = r0 OR r3 ;

            r1 = r1 LSHIFT 16;
            r2 = r2 LSHIFT 8;
            r2 = r2 LSHIFT -8;
            r1 = r1 OR r2 ;

            M[I4,1] = r0 ;
            M[I4,1] = r1 ;
        woodstock_read_coefficients_pskey_loop:

        // pop rLink onto stack
        jump $pop_rLink_and_rts;

    .ENDMODULE;


    // *********************************************************************************
    // MODULE:
    //    $WOODSTOCK_MUTE_SPEAKER_MESSAGE_handler
    //
    // DESCRIPTION:
    //   change speaker mute status
    //
    // INPUTS:
    //    - r0 = message_ID
    //    - r1 = data[0] = mute state
    // OUTPUTS:
    //    - none
    //
    // TRASHED REGISTERS:
    //
    // **********************************************************************************
    .MODULE $M.WOODSTOCK_MUTE_SPEAKER_MESSAGE_handler;
       .CODESEGMENT PM;
       .DATASEGMENT DM;

       $WOODSTOCK_MUTE_SPEAKER_MESSAGE_handler:

       // store the new state
       M[$woodstock_mute_spkr_flag] = r1;

       rts;

    .ENDMODULE;


    // *********************************************************************************
    // MODULE:
    //    $WOODSTOCK_MUTE_MICROPHONE_MESSAGE_handler
    //
    // DESCRIPTION:
    //   change microphone mute status
    //
    // INPUTS:
    //    - r0 = message_ID
    //    - r1 = data[0] = mute state
    // OUTPUTS:
    //    - none
    //
    // TRASHED REGISTERS:
    //
    // **********************************************************************************
    .MODULE $M.WOODSTOCK_MUTE_MICROPHONE_MESSAGE_handler;
       .CODESEGMENT PM;
       .DATASEGMENT DM;

       $WOODSTOCK_MUTE_MICROPHONE_MESSAGE_handler:

       // store the new state
       M[$woodstock_mute_mic_flag] = r1;

#ifdef ENABLE_FASTSTREAM_VOICE
       // if mute, then change usb output shift to 24 (effectively mutes audio)
       r2 = -8;
       r3 = -24;
       r1 = M[$woodstock_mute_mic_flag] ;
       if NZ r2 = r3 ;
       M[$faststream_voice_shift_op.param+2]=r2;
#endif
       rts;

    .ENDMODULE;


#endif // WOODSTOCK




// *********************************************************************************
// MODULE:
//    $av_copy_handler
//
// DESCRIPTION:
//   Copies codec output into CODEC output port
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// **********************************************************************************
.MODULE $M.av_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $av_copy_handler:

#ifdef DEBUG_ON
    // debug info to measure average bitrate over the air
   .VAR $time_elapsed;
   .VAR $total_bytes_sent[2]=0,0; //48 bit
   // average bitrate(kbps) = ($total_bytes_sent * 8000) / ($time_elapsed*$vm.codec_type.timer_period)
#endif

   // push rLink onto stack
   $push_rLink_macro;

 #ifdef DEBUG_ON
   M[$cbops.amount_to_use] = 0;
 #endif

   // copy data from cbuffer to the port
   //r8 = &$codec_out_copy_struc;

   // conditional copy is to cover faststream
   // in fast stream timer period = 1ms, we copy only when at least 108 words of data is available to copy
   // this condition must not be used together with old codec library, as it might cause deadlock
   r0 = M[$av_encoder_codec_stream_struc + $codec.av_encode.OUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   NULL = r0 - M[$vm.codec_type.minimum_data_to_copy];
   if LT jump no_codec_copy;



      #define SINGLE_STREAM_MODE    0
      #define DUAL_STREAM_MODE      1
      .VAR last_stream_state = -1;


      r2 = 1;
      r0 = $CODEC_OUT_PORT;
      call $cbuffer.is_it_enabled;
      // NULL = r0;
      if Z r2 = r2 - r2;
      r0 = $CODEC_OUT_PORT_TWO;
      call $cbuffer.is_it_enabled;
      // NULL = r0;
      if NZ r2 = r2 + r2;
      NULL = r2 - 2;
      if EQ jump dual_stream_codec_copy;

      // Single stream copy, this single stream can be the first one or second one.

         r1 = M[&last_stream_state];
         NULL = r1 - DUAL_STREAM_MODE;
         if NZ jump not_from_ds_mode;

         // Need to handle the transition from two streams to one stream.
         r1 = M[ds_codec_out_one_read_prt];
         r2 = M[ds_codec_out_two_read_prt];
         // r0 == second port enable
         NULL = r0;
         if NZ r1 = r2;
         r0 = &$codec_out_cbuffer_struc;
         call $cbuffer.set_read_address;  // update the read pointer


      not_from_ds_mode:
         r8 = &$codec_out_copy_struc;
         r7 = &$codec_out_copy_two_struc;
         r0 = $CODEC_OUT_PORT_TWO;
         call $cbuffer.is_it_enabled;
         if NZ r8 = r7;
         call $cbops.copy;

         r0 = SINGLE_STREAM_MODE;
         M[&last_stream_state] = r0;
         jump no_codec_copy_with_bitpool_control;


     // ************* Dual Stream ****************
     // Copy codec out data, handle dual stream special case

      dual_stream_codec_copy:

       .VAR ds_codec_out_one_read_prt = 0;
       .VAR ds_codec_out_two_read_prt = 0;

       .VAR $ds_codec_out_gap_threshold = 500;



       r1 = M[&last_stream_state];
       r0 = DUAL_STREAM_MODE;
       M[&last_stream_state] = r0;

       // *** if first time enter dual stream mode, setup read pointer first
       NULL = r1 - DUAL_STREAM_MODE;
       if Z jump already_in_dual_stream;

       // First time into dual stream mode
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.get_read_address_and_size;
       M[&ds_codec_out_two_read_prt] = r0;
       M[&ds_codec_out_one_read_prt] = r0;


    already_in_dual_stream:


   // Daul Stream free run, read points can drift away.
   dual_free_run_mode:


       r8 = &$ds_codec_out_copy_one_struc;
       r1 = M[&ds_codec_out_one_read_prt];
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.set_read_address;
       call $cbops.copy;
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.get_read_address_and_size;
       M[&ds_codec_out_one_read_prt] = r0;

       r8 = &$ds_codec_out_copy_two_struc;
       r1 = M[&ds_codec_out_two_read_prt];
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.set_read_address;
       call $cbops.copy;
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.get_read_address_and_size;
       M[&ds_codec_out_two_read_prt] = r0;

       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.get_write_address_and_size;
       // r0 = write address
       // r1 = buffer size
       r4 = M[&ds_codec_out_one_read_prt];
       r5 = M[&ds_codec_out_two_read_prt];

       r2 = r0 - r4;
       if NEG r2 = r2 + r1;  // r2 == stream one copy amount
       r3 = r0 - r5;
       if NEG r3 = r3 + r1;  // r3 == stream two copy amount
       r1 = r2 - r3;
       if NEG r4 = r5;
       // r4 = tail read pointer address
       // r1 = the gap between two read pointers

       // *** force the slow read pointer to keep up if the gap becomes too large
       r2 = M[&$ds_codec_out_gap_threshold];
       NULL = r1;
       if NEG jump output_one_faster;
          // codec out two is faster (read pointer is closer to write pointer)
          NULL = r1 - r2;
          if LT jump update_combined_read_pointer;
          r4 = M[&ds_codec_out_two_read_prt];
          M[&ds_codec_out_one_read_prt] = r4;
          jump update_combined_read_pointer;

       output_one_faster:
          // codec out one is faster
          NULL = r2 + r1;
          if POS jump update_combined_read_pointer;
          r4 = M[&ds_codec_out_one_read_prt];
          M[&ds_codec_out_two_read_prt] = r4;


    update_combined_read_pointer:
       r1 = r4;
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.set_read_address;


       // Adaptive SBC bitpool for handling poor connection

no_codec_copy_with_bitpool_control:

#ifdef SELECTED_ENCODER_SBC

       #define BITPOOL_DOWNGRADE_TH 300
       #define BITPOOL_RESTORE_TH   180
       #define BITPOOL_DELAY_PERIOD 3000
       #define BITPOOL_RST_PERIOD   300


       .VAR link_qua_sta = 0;  // 0 - normal quality, 1 - low bitrate quality
       .VAR org_bitpool_size = 0;
       .VAR delay_counter = 0;
       .VAR $low_bitpool_size = 30;

       r0 = M[&delay_counter];
       if Z jump normal_routine;
          // within delay time, do no checking
          r0 = r0 - 1;
          M[&delay_counter] = r0;
          jump no_codec_copy;

    normal_routine:
       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.calc_amount_space;
       NULL = r0 - BITPOOL_DOWNGRADE_TH;
       if LT jump downgrade_link;

       r0 = &$codec_out_cbuffer_struc;
       call $cbuffer.calc_amount_data;
       NULL = r0 - BITPOOL_RESTORE_TH;
       if LT jump restore_link;
       jump no_codec_copy;

    downgrade_link:
       NULL = M[&link_qua_sta];
       if NZ jump no_codec_copy;  // already in low bitrate quality

       r0 = M[&$sbc.sbc_common_data_array + $sbc.mem.BITPOOL_FIELD];
       M[&org_bitpool_size] = r0;
       r0 = M[$low_bitpool_size]; // LOWRATE_BITPOOL;
       M[&$sbc.sbc_common_data_array + $sbc.mem.BITPOOL_FIELD] = r0;
       r0 = 1;
       M[&link_qua_sta] = r0;
       r0 = BITPOOL_DELAY_PERIOD;
       M[&delay_counter] = r0;
       jump no_codec_copy;

    restore_link:
       NULL = M[&link_qua_sta];
       if Z jump no_codec_copy;  // already in normal quality

       r0 = M[&org_bitpool_size];
       r1 = M[&$sbc.sbc_common_data_array + $sbc.mem.BITPOOL_FIELD];
       NULL = r1 - r0;
       if GT r0 = r1;            // Choose the higher one between stored value and current value
       M[&$sbc.sbc_common_data_array + $sbc.mem.BITPOOL_FIELD] = r0;
       M[&link_qua_sta] = NULL;
       r0 = BITPOOL_RST_PERIOD;
       M[&delay_counter] = r0;

#endif

   // ************* Dual Stream ****************


   no_codec_copy:

#ifdef DEBUG_ON
   // increment timer count
   r0 = M[$time_elapsed];
   r0 = r0 + 1;
   M[$time_elapsed]=r0;

   // update total number of bytes sent to be used for measuring bitrate
   // *** This might not be correct in dual stream ***
   r0 = M[$cbops.amount_to_use];
   r0 = r0 + r0; // word to byte
   // add to 48-bit accumulator
   r1 = M[$total_bytes_sent];
   r2 = M[$total_bytes_sent+1];
   r1 = r1 + r0;
   r2 = r2 + carry;
   M[$total_bytes_sent] = r1;
   M[$total_bytes_sent+1] = r2;
#endif

#ifdef ENABLE_FASTSTREAM_VOICE
   r0 = M[$fs_voice_enabled];
   if Z jump no_voice_chan;
  #ifdef MONITOR_CODEC_BUFFER_LEVEL
   .VAR $glob_counter_removeframe;
   // Monitoring the level of input buffer, as the delay that can be tolerated is limited
   // the buffer level needs to have an upper limit, if it passes this limit then the latest
   // received frame is removed, in normal operation this doesn't happen, but if for any reason
   // the buffer sizes becomes large, this operation guarantees to keep the delay less than a limit
   r0 = &$codec_in_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r10 = r0-MONITOR_CODEC_BUFFER_LEVEL;
   if NEG jump no_need_to_discard;
      r0 = M[$glob_counter_removeframe];
     r0 =  r0 + 1;
     M[$glob_counter_removeframe] = r0;
      r0 = &$codec_in_cbuffer_struc;
      call $cbuffer.get_write_address_and_size;
      I0 = r0;
      L0 = r1;
      M0 = -FAST_STREAM_FRAME_LENGTH;
      r0 = M[I0, M0];
      L0 = 0;
      r1 = I0;
      r0 = &$codec_in_cbuffer_struc;
      call $cbuffer.set_write_address;
   no_need_to_discard:
  #endif
   // copy data from the port to the cbuffer
   r8 = &$codec_in_copy_struc;
   call $cbops.copy;
   no_voice_chan:
#endif
   // post another timer event
   r1 = &$av_copy_timer_struc;
   r2 = M[$vm.codec_type.timer_period];
   r3 = &$av_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *********************************************************************************
// MODULE:
//    $audio_in_copy_handler
//
// DESCRIPTION:
//   Copies ADC input ports into audio cbuffers in Analogue mode
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// **********************************************************************************
.MODULE $M.audio_in_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $audio_in_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // copy audio data from the port to the cbuffer
   // (selecting either mono or stereo)
   r8 = &$stereo_audio_in_copy_struc;
   r7 = &$mono_audio_in_copy_struc;
   r0 = $AUDIO_RIGHT_IN_PORT;
   call $cbuffer.is_it_enabled;
   if Z r8 = r7;

   // Copy data from the port(s) to the cbuffer(s)
   call $cbops.adc_av_copy;


   // Call the PEQ processing routine
#ifdef USES_PEQ
   call $mv_dongle.peq.caller;
#endif


   // post another timer event
   r1 = &$audio_in_timer_struc;
   r2 = M[$vm.codec_type.audio_timer_period];
   r3 = &$audio_in_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// ***************************************************************************************
// MODULE:
//     $idle_copy_handler
//
// DESCRIPTION:
//    Idle mode audio copy handler
//   - purging possible audio data received fom USB
//   - keep copying silence to USB output port if consumed
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// *****************************************************************************************
.MODULE $M.idle_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $idle_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

    // empty left input buffer
    r0 = &$audio_in_left_cbuffer_struc;
    call $cbuffer.empty_buffer;

    // empty right input buffer
    r0 = &$audio_in_right_cbuffer_struc;
    call $cbuffer.empty_buffer;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// ***************************************************************************************
// MODULE:
//     $audio_copy_handler
//
// DESCRIPTION:
//     Handler to copy audio between the USB ports and the DSP
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// *****************************************************************************************
.MODULE $M.audio_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR port_data = 0;
   .VAR $wbs_count = 0;
   .VAR usb_out_cbuffer_is_empty = 1;

   $audio_copy_handler:

   .VAR audio_copy_function_table[$mv.mode.TOTAL_MODES] =
                                      &$idle_copy_handler,    //idle mode = 0
                                      &$usb_out_copy_handler, //usb mode
                                      0 ...;                  // no function for analogue mode

   // push rLink onto stack
   $push_rLink_macro;
   #ifdef ENABLE_FASTSTREAM_VOICE
      // special operation for bidirectional faststream
      r0 = M[$fs_voice_enabled];
      if Z jump no_audio_out;
      // copy voice data to USB mic,
      // a proper rate matching between source headset and PC USB clocks might be required
      r0 = $USB_OUT_PORT;
      call $cbuffer.calc_amount_space;
      Null = r0;
      // port full, means data are not read from PC side
      if Z jump port_inactive;
         // port is active
         M[$port_inactive_hist] = 0;

         // calculate number of words in port
         r2 = r2 LSHIFT -1; // buffer size in words
         r0 = r2 - r0;
         r0 = r0 - 1;       // r0 = # of words in port
         M[port_data] = r0;

         // copy voice data to USB voice channel
         r8 = &$faststream_voice_copy_struc;
         call $cbops.copy;

         // if non-zero we've copied data to the port
         // need to reset usb_out_cbuffer_is_empty
         r1 = M[usb_out_cbuffer_is_empty];
         r2 = 1;
         r0 = M[$cbops.amount_to_use];
         if NZ r1 = r2;
         M[usb_out_cbuffer_is_empty] = r1;
         r0 = M[$cbops.amount_to_use];
         if NZ jump copy_finished;

            // cbuffer that feeds port is empty
            // if this happens twice AND we don't have a USB packet of data in
            // the USB MMU buffer we need to feed silence to the port
            r0 = M[usb_out_cbuffer_is_empty];
            if Z jump check_if_port_is_starving;
               // first time cbuffer feeding port is empty, set flag to zero
               M[usb_out_cbuffer_is_empty] = Null;
               jump copy_finished;

            check_if_port_is_starving:
               // cbuffer feeding USB MMU buffer has not had data at least two
               // times in a row. call $insert_silence_to_cbuffer and insert
               // a USB packet of zeros
               r0 = &$usb_out_resample_cbuffer_struc;
               r1 = M[r0 + $cbuffer.READ_ADDR_FIELD];
               M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r1;
               // insert silence into the cbuffer that feeds the MMU buffer
               r10 = 0;
               r3 = M[port_data];
               r3 = 48 - r3;
               if POS r10 = r3;
               call $insert_silence_to_cbuffer;
               // go to the point for copying silence
               jump usb_out_update;

      port_inactive:
         M[$cbops.amount_to_use] = 0;
         // port is inactive, increment the counter
         r0 = M[$port_inactive_hist];
         r0 = r0 + 1;
         M[$port_inactive_hist] = r0;

         // if it is inactive more than 10ms, then start purging voice data
         // from the audio buffer, therefore stream can keep coming
         //Null = r0 - 10;
         //if NEG jump copy_finished;
         // remove 1ms audio from the buffer, if there is at least 10ms data
         r0 = $audio_out_mono_resampled_cbuffer_struc;
         call $cbuffer.calc_amount_data;
         Null = r0 - 480;
         if NEG jump copy_finished;
            remove_samples:
            // remove 1ms voice data
            r0 = $audio_out_mono_resampled_cbuffer_struc;
            call $cbuffer.get_read_address_and_size;
            I0 = r0;
            L0 = r1;
            M0 = 48;
            r0 = M[I0, M0];
            r1 = I0;
            L0 = 0;
            r0 = $audio_out_mono_resampled_cbuffer_struc;
//          call $cbuffer.set_read_address;
            nop;
            jump copy_finished;

   no_audio_out:
 #endif
   // call the proper function based on  the current mode
   r0 = M[$mv.mode];
   r0 = M[r0 + audio_copy_function_table];
   if NZ call r0;

   usb_out_update:
   // copy data to the USB port if there is any
   r8 = &$usb_audio_out_copy_struc;
   call $cbops.copy;

   copy_finished:

   // post another timer event
   r1 = &$audio_copy_timer_struc;
   r2 = $TMR_PERIOD_USB_OUT_AUDIO_COPY;
   r3 = &$audio_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// ***************************************************************************************
// MODULE:
//     $usb_copy_handler
//
// DESCRIPTION:
//     USB audio input copy handler
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// *****************************************************************************************
.MODULE $M.usb_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $usb_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // copy the receive data in from the USB
   r8 = &$usb_audio_in_copy_struc;
   call $mvdongle.usb_stereo_audio_copy;


   // call the PEQ processing routine
#ifdef USES_PEQ
   call $mv_dongle.peq.caller;
#endif

   // post another timer event
   r1 = &$usb_copy_timer_struc;
   // The USB timer is set by the USB copy process!
   r2 = $TMR_PERIOD_USB_COPY;
   r3 = &$usb_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// ***************************************************************************************
// MODULE:
//     $usb_out_copy_handler
//
// DESCRIPTION:
//     inserts silence to USB output port
//
// INPUTS:
//     - none
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// *****************************************************************************************

.MODULE $M.usb_out_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $usb_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // Make sure the buffer has enough data
   // to copy to output port
   r0 = &$usb_out_resample_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   r1 = r0;
   r0 = &$usb_out_resample_cbuffer_struc;
   r10 = r1 - (( $BLOCK_SIZE + $RESAMPLER_READ_BACK + 8 )*6);
   if GT call $insert_silence_to_cbuffer;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// ***************************************************************************************
// MODULE:
//     $insert_silence_to_cbuffer
//
// DESCRIPTION:
//     utility function to insert silence into a cbuffer
//
// INPUTS:
//     - r0: cbuffer structure address to insert silence
//     - r10: number of silence samples to insert
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    Assume everything
// NOTE:
// this function assumes that there is enough space to insert samples
// *****************************************************************************************
.MODULE $M.insert_silence_to_cbuffer;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
$insert_silence_to_cbuffer:
      // push rLink onto stack
      $push_rLink_macro;

      push r0; // store buffer address in stack
      call $cbuffer.get_write_address_and_size;
      I0 = r0;
      L0 = r1;

      r0 = 0;
      // if we've got to here we just do the copies
      do copy_silence;
           M[I0, 1] = r0;
      copy_silence:

      pop r0; // restore buffer address
      r1 = I0;
      call $cbuffer.set_write_address;

      L0 = 0;
      // pop rLink from stack
      jump $pop_rLink_and_rts;

 .ENDMODULE;

// *****************************************************************************
// MODULE:
//    $USB_IN.stereo_audio_in_copy
//
// DESCRIPTION:
//    Copy available usb audio data from a read port 2 cbuffers.
//
// INPUTS:
//    - r8 = pointer to operator structure:
//       - STEREO_COPY_SOURCE_FIELD:         usb source port (port ID)
//       - STEREO_COPY_LEFT_SINK_FIELD:      left sink cbuffer (address of
//                                              cbuffer structure)
//       - STEREO_COPY_RIGHT_SINK_FIELD      right sink cbuffer (address of
//                                              cbuffer structure)
//       - STEREO_COPY_PACKET_LENGTH_FIELD   USB Packet Size (4 time sample
//                                              rate)
//       - STEREO_COPY_SHIFT_AMOUNT_FIELD    Amount to Shift audio data after
//                                              reading from
//                                           USB MMU port
//       - STEREO_COPY_LAST_HEADER_FIELD     USB header info for sync detection
//       - STEREO_COPY_SILENCE_CNT_FIELD     Number of msec of silence. Used to
//                                              detect when USB data has halted.
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r6, r7, I0, I4, I5, L0 = 0, L5 = 0, r10, DoLoop
//
// NOTES:
//    When enumerating on usb as a sound device we get a single byte stream of
//    data.  This consists of a byte of header followed by a number of
//    16bit samples.  If stereo mode is selected then samples are alternately
//    left and then right.  USB 16bit samples are LSbyte first which is the MMU
//    port's default mode.
//
// *****************************************************************************
.MODULE $M.mvdongle.stereo_audio_in_copy;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   // Constant used as silence buffer
   .VAR  ZeroBuff = 0;
#ifdef DEBUG_ON
   .VAR $debug_usb_silence_sent = 0;
    .VAR $debug_usb_in_sync_count = 0;
    .VAR $debug_usb_out_sync_count = 0;
#endif
$mvdongle.usb_stereo_audio_copy:
   // push rLink onto stack
   $push_rLink_macro;

   // *** Only Transfer Complete USB packets per iteration ***
   // *** (expect 1 msec of audio) ***

   // find amount of space in left sink
   r0 = M[r8 + $mvdongle.STEREO_COPY_LEFT_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r3 = r0;
   // find amount of space in right sink
   r0 = M[r8 + $mvdongle.STEREO_COPY_RIGHT_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   // calculate max number of locations that we could write to the sinks
   Null = r3 - r0;
   if POS r3 = r0;

   // r7 = samples per channel per USB packet (i.e. 1 msec of audio)
   r7 = M[r8 + $mvdongle.STEREO_COPY_PACKET_LENGTH_FIELD];
   r7 = r7 LSHIFT -2;
   NULL = r3 - r7;
   if NEG jump $pop_rLink_and_rts;

   // Assume USB Available - Use Silence Value
   I4 = &ZeroBuff;

   // Check amount of data in USB Port
   r0 = M[r8 + $mvdongle.STEREO_COPY_SOURCE_FIELD];
   // get the DSP port number
   r6 = r0 AND $cbuffer.PORT_NUMBER_MASK;

   // force an MMU buffer set
   Null = M[$PORT_BUFFER_SET];
   // Get amount of data from port
   call $cbuffer.calc_amount_data;

   // r10 is bytes to transfer
   r10 = r1;
   // Verify at least one USB Packet is available
   r2 = M[r8 + $mvdongle.STEREO_COPY_PACKET_LENGTH_FIELD];
   Null = r1 - r2;
   if POS jump jp_has_data;
     // See if data was transferred in previous period
     r2 = M[r8 + $mvdongle.STEREO_COPY_STALL_FIELD];
     r2 = r2 + 1;
     Null = r2 - $USB_STALL_TIME_BEFORE_SILENCE_INSERTION;
     if POS jump insert_silence;
     M[r8 + $mvdongle.STEREO_COPY_STALL_FIELD] = r2;
     jump $pop_rLink_and_rts;
insert_silence:
     r4 = r10;
     if Z jump end_discard;
     // switch to 8bit read mode
     M[r6 + $READ_PORT0_CONFIG] = 0;
     discard_loop:
         Null = M[r6 + $READ_PORT0_DATA];
         r4 = r4 - 1;
     if GT jump discard_loop;
     r0 = M[r8 + $mvdongle.STEREO_COPY_SOURCE_FIELD];
     r1 = I4;
     call $cbuffer.set_read_address;
     end_discard:
      r0 = M[$mv.mode];
      Null = r0 - $mv.mode.USB_MODE;
      if NZ jump $pop_rLink_and_rts;

      // limit the silence duration
      r0 = M[r8 + $mvdongle.STEREO_COPY_SILENCE_CNT_FIELD];
      Null = r0 - $PAUSE_SILENCE_DURATION_TO_SEND;
      if POS jump $pop_rLink_and_rts;

      // increment silence counter
      r0 = r0 + 1;
     M[r8 + $mvdongle.STEREO_COPY_SILENCE_CNT_FIELD] = r0;

     r7 = ($TMR_PERIOD_USB_COPY*$USB_SAMPLE_RATE/1000)/1000;
#ifdef DEBUG_ON
   r0 = M[$debug_usb_silence_sent];
   M[$debug_usb_silence_sent] = r0 + r7;
#endif

      jump jp_transfer_data;

jp_has_data:

   // Signal Packet is being transfer-ed
   M[r8 + $mvdongle.STEREO_COPY_STALL_FIELD] = 0;
   M[r8 + $mvdongle.STEREO_COPY_SILENCE_CNT_FIELD] = 0;

   // switch to 8bit read mode
   M[r6 + $READ_PORT0_CONFIG] = 0;

   // Increment Previous header
   r1 = M[r8 + $mvdongle.STEREO_COPY_LAST_HEADER_FIELD];
   r1 = r1 + 1;
   r1 = r1 AND 0x7F;
   // read one byte, should be the packet header
   r0 = M[r6 + $READ_PORT0_DATA];
   r0 = r0 AND 0x7F;

   M[r8 + $mvdongle.STEREO_COPY_LAST_HEADER_FIELD] = r0;

   // check synchronisation
   Null = r0 - r1;
   if NZ jump usb_out_of_sync;
      // set up index register for the usb port and switch to 16bit read mode
      I4 = r6 + $READ_PORT0_DATA;
      r1 = $BITMODE_16BIT_ENUM;
      M[r6 + $READ_PORT0_CONFIG] = r1;

#ifdef DEBUG_ON
   r0 = M[$debug_usb_in_sync_count];
   r0 = r0 + 1;
   M[$debug_usb_in_sync_count] = r0;
#endif

      jump jp_transfer_data;
usb_out_of_sync:

#ifdef DEBUG_ON
   r0 = M[$debug_usb_out_sync_count];
   r0 = r0 + 1;
   M[$debug_usb_out_sync_count] = r0;
#endif

   // r6=USB Port, r10=bytes in usb
   // Already Read header byte
   r10 = r10 -1;
   // Purge USB Buffer
lp_loop:
      Null = M[r6 + $READ_PORT0_DATA];
      r10 = r10 - 1;
   if GT jump lp_loop;

   // Port Purged.  Now add 1 msec of silence to buffer
jp_transfer_data:

   // ***** Get Output Buffers
   r10 = r7;
   // set up index and length registers for the left channel
   r0 = M[r8 + $mvdongle.STEREO_COPY_LEFT_SINK_FIELD];
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   // set up index and length registers for the right channel
   r0 = M[r8 + $mvdongle.STEREO_COPY_RIGHT_SINK_FIELD];
   call $cbuffer.get_write_address_and_size;
   I5 = r0;
   L5 = r1;

   r3 = M[r8 + $mvdongle.STEREO_COPY_SHIFT_AMOUNT_FIELD];

   do lp_stereo_loop;
      // read and write the left channel sample
      r0 = M[I4,0];
      r0 = r0 ASHIFT r3;
      // read and write the right channel sample
      r1 = M[I4,0];
      r1 = r1 ASHIFT r3;
#ifdef WOODSTOCK
      // Woodstock mute
      r2 = M[$woodstock_mute_spkr_flag] ;
      if NZ r0 = NULL ;
      r2 = M[$woodstock_mute_spkr_flag] ;
      if NZ r1 = NULL ;
#endif
      // Write Outputs
      M[I0,1] = r0, M[I5,1] = r1;
lp_stereo_loop:

   // update buffer write address for the left channel
   // and amount of data for frame sync
   r0 = M[r8 + $mvdongle.STEREO_COPY_LEFT_SINK_FIELD];
   r1 = I0;
   call $cbuffer.set_write_address;
   L0 = 0;

   // update buffer write address for the right channel
   r0 = M[r8 + $mvdongle.STEREO_COPY_RIGHT_SINK_FIELD];
   r1 = I5;
   call $cbuffer.set_write_address;
   L5 = 0;

   // If Silence then done
   Null = I4 - &ZeroBuff;
   if Z jump $pop_rLink_and_rts;

   // Not silence.  Reset Counter
   M[r8 + $mvdongle.STEREO_COPY_SILENCE_CNT_FIELD] = Null;

   //*******************************************

   // Update USB buffer

   r0 = M[r8 + $mvdongle.STEREO_COPY_SOURCE_FIELD];
   r1 = I4;
   call $cbuffer.set_read_address;

   // If we have sufficient USB data remaining for a packet then repeat
   r0 = M[r8 + $mvdongle.STEREO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;
   $pop_rLink_macro;
   r2 = M[r8 + $mvdongle.STEREO_COPY_PACKET_LENGTH_FIELD];
   r2 = r2 ASHIFT 1;   // double packet size to adjust for jitter
   NULL = r1 - r2;
   if POS jump $mvdongle.usb_stereo_audio_copy;             // More to Transfer
   rts;
.ENDMODULE;



// $****************************************************************************
// SBC bitpool change handler
// $****************************************************************************

#ifdef SELECTED_ENCODER_SBC

.MODULE $M.sbc_bitpool_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $sbc_bitpool_handler:

   NULL = r1 - 30;
   if LT jump $error;
   NULL = r1 - 50;
   if GT jump $error;
   M[&$sbc.sbc_common_data_array + $sbc.mem.BITPOOL_FIELD] = r1;

   rts;

.ENDMODULE;


.MODULE $M.sbc_set_low_bitpool_size;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $sbc_set_low_bitpool_size:

   M[&$low_bitpool_size] = r1;

   rts;

.ENDMODULE;



#endif



// $****************************************************************************
// NAME:
//    Audio Processing Library PEQ Module (version 2.0.0)
//
// DESCRIPTION:
//    Parametric Equaliser based on multi-stage biquad filter
//
// MODULES:
//    $mv_dongle.peq.initialize
//    $mv_dongle.peq.process
// *****************************************************************************

#ifdef USES_PEQ

.MODULE $M.mv_dongle.peq.initialize;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$mv_dongle.peq.initialize:

   //number of stages
   r0 = M[r7 + $mv_dongle.peq.NUM_STAGES_FIELD];

   // size of delay buffer = (num_stage+1)*2
   r1 = r0 + 1;
   r1 = r1 ASHIFT 1;
   M[r7 + $mv_dongle.peq.DELAYLINE_SIZE_FIELD] = r1;

   // size of coef buffer = (num_stage) * 5
   r1 = r0 ASHIFT 2;
   r1 = r1 + r0;
   M[r7 + $mv_dongle.peq.COEFS_SIZE_FIELD] = r1;

   // Initialise delay buffer to zero
   r1 = M[r7 + $mv_dongle.peq.DELAYLINE_ADDR_FIELD];
   I0 = r1;
   r10 = M[r7 + $mv_dongle.peq.DELAYLINE_SIZE_FIELD];
   // to zero the delay buffer
   r0 = 0;
   do init_dly_ln_loop;
      M[I0, 1] = r0;
   init_dly_ln_loop:

   rts;
.ENDMODULE;



.MODULE $M.mv_dongle.peq.caller;
   .CODESEGMENT   PM;
   .DATASEGMENT DM;

   $mv_dongle.peq.caller:

   $push_rLink_macro;

   // PEQ the left channel

   r7 = $left_peq_struc;

   r0 = &$peq_in_left_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   M[r7 + $mv_dongle.peq.INPUT_ADDR_FIELD] = r0;
   M[r7 + $mv_dongle.peq.INPUT_SIZE_FIELD] = r1;

   r0 = &$audio_in_left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   M[r7 + $mv_dongle.peq.OUTPUT_ADDR_FIELD] = r0;
   M[r7 + $mv_dongle.peq.OUTPUT_SIZE_FIELD] = r1;

   r0 = &$peq_in_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r4 = r0;
   r0 = $audio_in_left_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   NULL = r0 - r4;
   if GT r0 = r4;

   // Keep each copy amount within a reasonable range
   NULL = r0 - $PEQ_COPY_MINIMUM;
   if LT jump right_channel;
   NULL = r0 - $PEQ_COPY_MAXIMUM;
   if LT jump skip_overwrite_1;
      r0 = $PEQ_COPY_MAXIMUM;
   skip_overwrite_1:

   M[r7 + $mv_dongle.peq.BLOCK_SIZE_FIELD] = r0;

   call $mv_dongle.peq.process;

   //r7 = $left_peq_struc;

   r1 = M[r7 + $mv_dongle.peq.INPUT_ADDR_FIELD];
   r0 = &$peq_in_left_cbuffer_struc;
   call $cbuffer.set_read_address;

   r1 = M[r7 + $mv_dongle.peq.OUTPUT_ADDR_FIELD];
   r0 = &$audio_in_left_cbuffer_struc;
   call $cbuffer.set_write_address;


   // PEQ the right channel
right_channel:
   r7 = $right_peq_struc;

   r0 = $peq_in_right_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   M[r7 + $mv_dongle.peq.INPUT_ADDR_FIELD] = r0;
   M[r7 + $mv_dongle.peq.INPUT_SIZE_FIELD] = r1;

   r0 = $audio_in_right_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   M[r7 + $mv_dongle.peq.OUTPUT_ADDR_FIELD] = r0;
   M[r7 + $mv_dongle.peq.OUTPUT_SIZE_FIELD] = r1;

   r0 = $peq_in_right_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r4 = r0;
   r0 = $audio_in_right_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   NULL = r0 - r4;
   if GT r0 = r4;

   // Keep each copy amount within a reasonable range
   NULL = r0 - $PEQ_COPY_MINIMUM;
   if LT jump all_done;
   NULL = r0 - $PEQ_COPY_MAXIMUM;
   if LT jump skip_overwrite_2;
      r0 = $PEQ_COPY_MAXIMUM;
   skip_overwrite_2:

   M[r7 + $mv_dongle.peq.BLOCK_SIZE_FIELD] = r0;

   call $mv_dongle.peq.process;

   r1 = M[r7 + $mv_dongle.peq.INPUT_ADDR_FIELD];
   r0 = &$peq_in_right_cbuffer_struc;
   call $cbuffer.set_read_address;

   r1 = M[r7 + $mv_dongle.peq.OUTPUT_ADDR_FIELD];
   r0 = &$audio_in_right_cbuffer_struc;
   call $cbuffer.set_write_address;

all_done:
   jump $pop_rLink_and_rts;

.ENDMODULE;



.MODULE $M.mv_dongle.peq.process;
   .CODESEGMENT   PM;
   .DATASEGMENT DM;

$mv_dongle.peq.process:

   M1 = 1;
   I3 = r7;
   M0 = -1;
   // Read INPUT_ADDR_FIELD
   r0 = M[I3,M1];
   // I4 = ptr to ip buffer,   Read INPUT_SIZE_FIELD
   I4 = r0, r0 = M[I3,M1];
   // L4 = length of buffer,   Read OUTPUT_ADDR_FIELD
   L4 = r0, r0 = M[I3,M1];
   // I0 = ptr to op buffer,   Read OUTPUT_SIZE_FIELD
   I0 = r0, r0 = M[I3,M1];
   // L0 = length of buffer,   Read DELAYLINE_ADDR_FIELD
   L0 = r0, r0 = M[I3,M1];
   // I5 = ptr to delay line,  Read COEFS_ADDR_FIELD
   I5 = r0, r0 = M[I3,M1];
   // I1 = ptr to coefs buffer,Read NUM_STAGES_FIELD
   I1 = r0, r1 = M[I3,M1];
   // M2 = num stages,        Read DELAYLINE_SIZE_FIELD
   M2 = r1, r1 = M[I3,M1];
   // L5 = delay buffer size, Read COEFS_SIZE_FIELD
   L5 = r1, r1 = M[I3,M1];
   // L1 = coeff buffer size, Read BLOCK_SIZE_FIELD
   L1 = r1, r4 = M[I3,M1];
   // Read SCALING_ADDR_FIELD
   r10 = Null, r1 = M[I3,M1];
   // I2 = scale buffer,      Read GAIN_EXPONENT_ADDR_FIELD
   I2 = r1 + M2, r1 = M[I3,M1];
   // needed for bug in index feed forward, M2 = -num stages
   M2 = Null - M2;
   // INPUT_GAIN_EXPONENT
   r6 = M[r1];
   // Add 2-bit head room     Read GAIN_MANTISA_ADDR_FIELD
   r6 = r6 + M0, r5 = M[I3,M1];
   r6 = r6 + M0;
   // INPUT_GAIN_MANTISA
   r5 = M[r5];
   // this loop excutes for each sample in the block
peq_block_loop:
      // get new input sample
      // number of Biquad stages used, get new input sample
      r10 = r10 - M2, r0 = M[I4,M1];
      // Apply mantissa,Exp to front end gain
      rMAC = r0 * r5, r0 = M[I2,M2];
      r0 = rMAC ASHIFT r6;
      do biquad_loop;
         // get x(n-2), get coef b2
         r1 = M[I5,M1], r2 = M[I1,M1];
         // b2*x(n-2), get x(n-1), get coef b1
         rMAC = r1 * r2, r1 = M[I5,M0], r2 = M[I1,M1];
         // +b1*x(n-1), store new x(n-2), get coef b0
         rMAC = rMAC + r1 * r2, M[I5,M1] = r1, r2 = M[I1,M1];
         // +b0*x(n),store new x(n-1)
         rMAC = rMAC + r0 * r2, M[I5,M1] = r0;
         // get y(n-2), get coef a2
         r1 = M[I5,M1], r2 = M[I1,M1];
         // -a2*y(n-2), get y(n-1), get coef a1
         rMAC = rMAC - r1 * r2, r1 = M[I5,M0], r2 = M[I1,M1];
         // -a1*y(n-1),get the scalefactor
         rMAC = rMAC - r1 * r2, r3 = M[I2,M1];
         // get y(n)
         r0 = rMAC ASHIFT r3;
biquad_loop:
      // store new y(n-2)
      M[I5,M1] = r1;
      // store new y(n-1)
      M[I5,M1] = r0;
      // Restore Head room
      r0 = r0 ASHIFT 2;
      // Decrement the block counter,write back o/p sample
      r4 = r4 - M1,  M[I0,M1] = r0;
   if NZ jump peq_block_loop;

   // Update the I/O buffer pointers back into PEQ data object before leaving.
   L0 = Null;
   L4 = Null;
   L1 = Null;
   L5 = Null;
   r0 = I4;
   // Update the input buffer pointer field
   M[r7 + $mv_dongle.peq.INPUT_ADDR_FIELD] = r0;
   r0 = I0;
   // Update the output buffer pointer field
   M[r7 + $mv_dongle.peq.OUTPUT_ADDR_FIELD] = r0;

   rts;

.ENDMODULE;

#endif

#ifdef SPDIF_ENABLE
// *****************************************************************************
// MODULE:
//    $spdif_pause_detect
//
// DESCRIPTION:
//   when spdif stream is paused some encoded data stays in
//   the firmware, just like usb mode we insert a small amount
//   of silence to make sure when the stream is resumed no old
//   audio is sent to the sink device.
// INPUT:
//   r7 = amount of data read from ports in last read
// TRASHED REGISTERS
//   r0-r4, r10, rMAC, DoLoop, I0
// *****************************************************************************
.MODULE $M.spdif_pause_detect;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $spdif_pause_detect:

   // push rLink onto stack
   $push_rLink_macro;

   // r7 = 0 means no data read from spdif input ports
   Null = r7;
   if NZ jump spdif_stream_active;

   // see if pause threshold has reached
   r0 = M[$spdif_pause_timer];
   r0 = r0 + $TMR_PERIOD_SPDIF_COPY;
   Null = r0 - SPDIF_PAUSE_THRESHOLD_US;
   if POS jump insert_silence;

   // pause time not passed the threshold yet
   M[$spdif_pause_timer] = r0;
   jump end;

   insert_silence:
   // pause detected
   r3 = M[$spdif_copy_struct + $spdif.frame_copy.SAMPLING_FREQ_FIELD];
   if Z jump end;
   r4 = M[$spdif_silence_to_insert];
   if LE jump end;

   // if buffer is almost full skip this copy
   r0 = M[$spdif_copy_struct + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r0 = r0 - $spdif.INPUT_BUFFER_MIN_SPACE;
   if NEG jump end;

   // work out how much silence to add this time
   rMAC = r3 * $TMR_PERIOD_SPDIF_COPY;
   rMAC = rMAC ASHIFT 5 (56bit);
   r10 = rMAC * 0.52428799999999998(frac);
   r2 = 250000;
   rMAC = r2 * r10;
   Div = rMAC / r3;
   r3 = DivResult;
   M[$spdif_silence_to_insert] = r4 - r3;
   r10 = MIN r0;
   // even number of samples (L+R)
   r10 = r10 AND (~0x1);
   if Z  jump end;

   // insert silence to buffer, r10 samples
   r0 = M[$spdif_copy_struct + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   r0 = 0;
   do sil_loop;
      M[I0, 1] = r0;
   sil_loop:
   L0 = 0;
   r0 = &$spdif_in_cbuffer_struc;
   r1 = I0;
   call $cbuffer.set_write_address;
   jump end;

   spdif_stream_active:
   // stream is active, reset threshold
   M[$spdif_pause_timer] = 0;
   r0 = ($PAUSE_SILENCE_DURATION_TO_SEND_MS*1000);
   M[$spdif_silence_to_insert] = r0;

   end:
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif_in_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the copying of data
//    from the spdif input ports
//
// *****************************************************************************
.MODULE $M.spdif_in_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $spdif_in_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // read raw data from spdif LEFT and RIGHT ports
   r8 = &$spdif_copy_struct;
   call $spdif.copy_raw_data;

   // insert some silence if
   // pause detected
   call $spdif_pause_detect;

   // post another timer event
   r1 = &$spdif_in_timer_struc;
   r2 = $TMR_PERIOD_SPDIF_COPY;
   r3 = &$spdif_in_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif
