// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change: 1667166 $  $DateTime: 2013/07/18 13:34:33 $
// *****************************************************************************

// ******************************************************************************************
// DESCRIPTION
//
//    This application plays audio streams coming from S/PDIF input
// ports. The input to the DSP app comes from two spdif LEFT and RIGHT ports,
// the SPDIF data can be either coded(IEC_61937 format) or PCM type. The coded
// data is decoded by proper decoder then played at the output interface. This
// application can also supports AC-3, MPEG2 AAC(stereo only) and MPEG1 MP3
// (stereo only) coded data types, any other coded data type will mute the output.
// Supporting codec data types must be enabled both in build time and in run time by VM.
//
// For AC-3 coded stream, The application can optionally mix the decoded LFE
// output channel into both output LEFT and RIGHT channels.
//
// Figure below shows how the spdif audio can be integrated into music manager
// system.
//                                                             +------------------+ LEFT output
//               +------------------+  PCM LEFT                |                  |----------->
// SPDIF IN LEFT |                  |---->------->+----------->|                  | RIGHT output
// ------------->|  SPDIF DECODE    | PCM RIGHT   |            |    Music         |----------->
//               |  PCM/IEC_61937   |---->--------|-->+------->|    Manager       |
// SPDIF IN RIGTH|  detection       |             |   |        |  (Time Domain)   | SUB output (optional)
// ------------->|                  |------->+    |   |        |                  |----------->
//               +------------------+ CODED  |    |   |        +-------^----------+
//                                    AUDIO  |    |   |                | LFE input
//       +-----------------------<-----------+    |   |                |
//       |                                        |   |                |
//       |                                        |   |                |
//       |                                        |   |                |
//       |                                        |   |                |
//       |                                        |   |                |
//       |        +------------------+            |   |                |
//       |        |                  | L          |   |                |
//       |        |                  |----------->+   |                |
//       |        |     DECODER      |                |                |
//       |        |                  |                |                |
//       |        |                  | R              |                |
//       +------->|                  |--------------->+                |
//  Coded Audio   | (5.1 to stereo   |                                 |
//                |    Downmix       |                                 |
//                |    for AC-3)     |                                 |
//                |                  | LFE (AC-3 only)                 |
//                |                  |------------------------>--------+
//                +------------------+
//
// ***********************************************************************************************

#include "frame_sync_library.h"
#include "music_example.h"
#include "spi_comm_library.h"
#include "mips_profile.h"
#include "spdif_sink.h"
#include "codec_library.h"
#include "codec_decoder.h"
#include "audio_proc_library.h"
#include "core_library.h"
#include "cbops_library.h"
#include "spdif_library.h"

#ifdef AC3_ENABLE
   #include "ac3_library.h"
#endif

#ifdef MP3_ENABLE
   #include "mp3_library.h"
#endif

#ifdef AAC_ENABLE
   #include "aac_library.h"
#endif

#if (defined(AC3_ENABLE)) && (!defined(AAC_ENABLE))
   // -- Required for using the fft library
   #define FFT_TWIDDLE_NEED_128_POINT
   #include "fft_twiddle.h"
#endif

// Run-time control of configuration
.MODULE $app_config;
   .DATASEGMENT DM;

// Plugin type set from VM at run-time
   .VAR io = $INVALID_IO;             // Control app i/o
.ENDMODULE;

.MODULE $M.main;
   .CODESEGMENT MAIN_PM;
   .DATASEGMENT DM;

   $main:

   // ** allocate memory for cbuffers **
   .VAR/DMCIRC $audio_out_left[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_out_right[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_out_lfe[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out_left[$OUTPUT_AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out_right[$OUTPUT_AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $codec_in[CODEC_CBUFFER_SIZE];

   // Tone/Prompt data buffers, $tone_in_right
   // is used for stereo voice prompts
   .VAR/DM1CIRC $tone_in[TONE_BUFFER_SIZE];
   .VAR/DM1CIRC $tone_in_right[TONE_BUFFER_SIZE];
   // Timer period variable for reading tone/prompt data
   // (this is modified according to the connection type and also to support local playback)
   .VAR $tmr_period_tone_copy = TMR_PERIOD_TONE_COPY;

   // Variables to receive dac and codec sampling rates from the vm
   .VAR $current_dac_sampling_rate = 0;                            // sampling rate of DAC
   .VAR $current_codec_sampling_rate = 0;                          // sampling rate of spdif input
   .VAR $config_spdif_sink_vm_message_struc[$message.STRUC_SIZE];  // Message structure for VM_CONFIG_SPDIF_APP_MESSAGE_ID message
   .VAR $set_tone_rate_from_vm_message_struc[$message.STRUC_SIZE]; // Message structure for VM_SET_TONE_RATE_MESSAGE_ID message
   .VAR $current_tone_sampling_rate = 8000;                        // input tone/prompt sample rate, set by VM before tone starts
   .VAR $stereo_tone;                                              // flag showing input tone/prompt is stereo
   .VAR $spdif_target_latency_setting = SPDIF_DEFAULT_LATENCY_MS;  // target latency

   // Rate matching control variables
   .VAR $audio_if_mode;
   .VAR $max_clock_mismatch;
   .VAR $aux_input_stream_available;       // local pcm file is being mixed


   // ** allocate memory for cbuffer structures **

   .VAR $audio_out_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_left),        // size
         &$audio_out_left,               // read pointer
         &$audio_out_left;               // write pointer
   .VAR $audio_out_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_right),       // size
         &$audio_out_right,              // read pointer
         &$audio_out_right;              // write pointer
   .VAR $audio_out_lfe_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_lfe),        // size
         &$audio_out_lfe,               // read pointer
         &$audio_out_lfe;               // write pointer
   .VAR $dac_out_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($dac_out_left),          // size
         &$dac_out_left,                 // read pointer
         &$dac_out_left;                 // write pointer
   .VAR $dac_out_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($dac_out_right),         // size
         &$dac_out_right,                // read pointer
         &$dac_out_right;                // write pointer
   .VAR $codec_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($codec_in),              // size
         &$codec_in,                     // read pointer
         &$codec_in;                     // write pointer
   .VAR $tone_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($tone_in),               // size
         &$tone_in,                      // read pointer
         &$tone_in;                      // write pointer
   // used for stereo tones
   .VAR $tone_in_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($tone_in_right),               // size
         &$tone_in_right,                      // read pointer
         &$tone_in_right;                      // write pointer

   .VAR/DMCIRC $spdif_in[SPDIF_CBUFFER_SIZE];
   .VAR $spdif_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
          LENGTH($spdif_in),            // size
          &$spdif_in,                   // read pointer
          &$spdif_in;                   // write pointer

   // ** allocate memory for timer structures **
   .VAR $spdif_in_timer_struc[$timer.STRUC_SIZE];
   .VAR $audio_out_timer_struc[$timer.STRUC_SIZE];
   .VAR $tone_copy_timer_struc[$timer.STRUC_SIZE];
   .var $signal_detect_timer_struc[$timer.STRUC_SIZE];

   // ** allocate memory for tone input cbops copy routine **
   .VAR $tone_in_copy_struc[] =
      &$tone_in_copy_op,              // first operator block
      1,                               // number of inputs
      $TONE_IN_PORT,                   // input
      1,                               // number of outputs
      &$tone_in_cbuffer_struc;         // output

   .BLOCK $tone_in_copy_op;
      .VAR $tone_in_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $tone_in_copy_op.func = &$cbops.shift;
      .VAR $tone_in_copy_op.param[$cbops.shift.STRUC_SIZE] =
         0,                         // Input index
         1,                         // Output index
         3+8;                       // 3 bits amplification for tone(was in original file)
                                    // and 8 bits to convert from 16-bit to 24-bit
   .ENDBLOCK;

   // ** allocate memory for stereo tone input cbops copy routine **
   // This replaces  $tone_in_copy_struc when the input tone is stereo
   .VAR $stereo_tone_in_copy_struc[] =
      &$stereo_tone_in_copy_op,       // first operator block
      1,                               // number of inputs
      $TONE_IN_PORT,                   // input
      2,                               // number of outputs
      &$tone_in_cbuffer_struc,         // output 1
      &$tone_in_right_cbuffer_struc;   // output 2

   .BLOCK  $stereo_tone_in_copy_op;
      .VAR $stereo_tone_in_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $stereo_tone_in_copy_op.func = &$cbops.deinterleave;
      .VAR $stereo_tone_in_copy_op.param[$cbops.deinterleave.STRUC_SIZE] =
         0,                         // Input index
         1,                         // Output 1 index
         2,                         // output 2 index
         8;                         // and 8 bits to convert from 16-bit to 24-bit
   .ENDBLOCK;

   // ** allocate memory for stereo audio out cbops copy routine **
  .VAR $stereo_out_copy_struc[] =
      &$audio_out_tone_upsample_stereo_mix, // first operator block
      2,                                    // number of inputs
      &$dac_out_temp_left_cbuffer_struc,    // input
      &$dac_out_temp_right_cbuffer_struc,   // input
      2,                                    // number of outputs
      $AUDIO_LEFT_OUT_PORT,                 // output
      $AUDIO_RIGHT_OUT_PORT;                // output

   //tone mixing can not be the last operator as it does upsampling and mixing in place
   .VAR/DM1CIRC $tone_hist[$cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH];
   .VAR/DM1CIRC $tone_right_hist[$cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH];
   // if input tone is mono it will be mixed to both
   // left and right audio channels, for stereo tones
   // left tone is mixed into left audio channel and
   // right tone is mixed into right audio channel only.
   .BLOCK $audio_out_tone_upsample_stereo_mix;
      .VAR $audio_out_tone_upsample_stereo_mix.next = &$audio_out_tone_right_upsample_stereo_mix;
      .VAR $audio_out_tone_upsample_stereo_mix.func = &$cbops.auto_upsample_and_mix;
      .VAR $audio_out_tone_upsample_stereo_mix.param[$cbops.auto_resample_mix.STRUC_SIZE] =
         0,                                 // Input index to first channel(left channel)
         1,                                 // Index to second channel, right channel for mono tones, -1 for stereo tones
         &$tone_in_cbuffer_struc,           // cbuffer structure containing tone samples
         &$sra_coeffs,                      // coefs for resampling
         &$current_dac_sampling_rate,       // pointer to variable containing dac rate received from vm (if 0, default 48000hz will be used)
         &$tone_hist,                       // history buffer for resampling
         &$current_tone_sampling_rate,      // pointer to variable containing tone rate received from vm (if 0, default 8000hz will be used)
         0.5,                               // tone volume mixing (set by vm)
         0.5,                               // audio volume mixing
         0 ...;                             // Pad out remaining items with zeros
   .ENDBLOCK;

   .BLOCK $audio_out_tone_right_upsample_stereo_mix;
      .VAR $audio_out_tone_right_upsample_stereo_mix.next = &$signal_detect_op_stereo;
      .VAR $audio_out_tone_right_upsample_stereo_mix.func = &$cbops.auto_upsample_and_mix;
      .VAR $audio_out_tone_right_upsample_stereo_mix.param[$cbops.auto_resample_mix.STRUC_SIZE] =
         1,                                 // Input index to first channel (right channel)
         -1,                                // Index to second channel (no channel)
         &$tone_in_right_cbuffer_struc,     // cbuffer structure containing tone samples
         &$sra_coeffs,                      // coefs for resampling
         &$current_dac_sampling_rate,       // pointer to variable containing dac rate received from vm (if 0, default 48000hz will be used)
         &$tone_right_hist,                 // history buffer for resampling
         &$current_tone_sampling_rate,      // pointer to variable containing tone rate received from vm (if 0, default 8000hz will be used)
         0.5,                               // tone volume mixing (same as left structure)
         0.5,                               // audio volume mixing
         0 ...;                             // Pad out remaining items with zeros
   .ENDBLOCK;

   .block $signal_detect_op_stereo;
      .var $signal_detect_op_stereo.next = &$audio_mute_op_stereo;
      .var $signal_detect_op_stereo.func = &$cbops.signal_detect_op;
      .var $signal_detect_op_stereo.param[$cbops.signal_detect_op.STRUC_SIZE_STEREO] =
         &$signal_detect_op_coefs,        // pointer to coefficients
         2,                               // number of channels to process
         0,                               // left index
         1;                               // right index
   .endblock;

    .var $signal_detect_op_coefs[$cbops.signal_detect_op_coef.STRUC_SIZE] = 
         SIGNAL_DETECT_THRESHOLD,         // detection threshold
         SIGNAL_DETECT_TIMEOUT,           // trigger time
         0,                               // current max value
         0,                               // signal detected timeout timer
         1,                               // signal status (1 = playing audio)
         $music_example.VMMSG.SIGNAL_DETECT_STATUS; // ID for status message sent to VM

    .block $audio_mute_op_stereo;
        .var $audio_mute_op_stereo.next = &$audio_out_dc_remove_op_left;
        .var $audio_mute_op_stereo.func = &$cbops.soft_mute;
        .var $audio_mute_op_stereo.param[$cbops.soft_mute_op.STRUC_SIZE_STEREO] =
            1,      // mute direction (1 = unmute audio)
            0,      // index
            2,      // number of channels
            0,      // left input index
            0,      // left output index
            1,      // right input index
            1;      // right output index
    .endblock;

   .BLOCK $audio_out_dc_remove_op_left;
      .VAR audio_out_dc_remove_op_left.next = &$audio_out_dc_remove_op_right;
      .VAR audio_out_dc_remove_op_left.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_left.param[$cbops.dc_remove.STRUC_SIZE] =
         0,                                 // Input index (left cbuffer)
         0,                                 // Output index (left cbuffer)
         0;                                 // DC estimate field
   .ENDBLOCK;

   // *** Software rate-match ***
   .BLOCK $audio_out_dc_remove_op_right;
      .VAR audio_out_dc_remove_op_right.next = &rm_stereo_switch_op;
      .VAR audio_out_dc_remove_op_right.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_right.param[$cbops.dc_remove.STRUC_SIZE] =
         1,                                 // Input index (right cbuffer)
         1,                                 // Output index (right cbuffer)
         0;                                 // DC estimate field
   .ENDBLOCK;

   // Switch operator chains according to whether rate matching is enabled
   .BLOCK rm_stereo_switch_op;
      .VAR rm_stereo_switch_op.next = &$audio_out_dither_and_shift_op_left;
      .VAR rm_stereo_switch_op.func = $cbops.switch_op;
      .VAR rm_stereo_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
         $sw_rate_match_disable,                // Pointer to switch (non-zero to disable sw rate matching)
         &$audio_out_rate_adjustment_and_shift_op_stereo, // ALT_NEXT_FIELD, pointer to alternate cbops chain
         0xFFFF,                                // SWITCH_MASK_FIELD
         0 ...;
   .ENDBLOCK;

   // set up rate adjustment operator for software rate matching, this is used only for
   // SPDIF output interface
   .VAR/DM1CIRC $sr_hist_left[$cbops.rate_adjustment_and_shift.SRA_HD_QUALITY_COEFFS_SIZE];
   .VAR/DM1CIRC $sr_hist_right[$cbops.rate_adjustment_and_shift.SRA_HD_QUALITY_COEFFS_SIZE];
   .BLOCK $audio_out_rate_adjustment_and_shift_op_stereo;
      .VAR $audio_out_rate_adjustment_and_shift_op_stereo.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_rate_adjustment_and_shift_op_stereo.func = &$cbops.rate_adjustment_and_shift;
      .VAR $audio_out_rate_adjustment_and_shift_op_stereo.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
      0,  //   INPUT1_START_INDEX_FIELD
      2,  //   OUTPUT1_START_INDEX_FIELD
      1,  //   INPUT2_START_INDEX_FIELD
      3,  //   OUTPUT2_START_INDEX_FIELD
      -8, //   SHIFT_AMOUNT_FIELD
      &$sra_coeffs_hd_quality,
      &$sr_hist_left,
      &$sr_hist_right,
      $spdif_sra_struct + $spdif_sra.SRA_RATE_FIELD,
      $cbops.dither_and_shift.DITHER_TYPE_TRIANGULAR, // DITHER_TYPE_FIELD
      0,                                              // no compression
      length($sr_hist_left),
      0 ...;                                          // Pad out remaining items with zeros
    .ENDBLOCK;

   .VAR/DM1CIRC $dither_hist_left[$cbops.dither_and_shift.FILTER_COEFF_SIZE];
   .VAR/DM1CIRC $dither_hist_right[$cbops.dither_and_shift.FILTER_COEFF_SIZE];

   .BLOCK $audio_out_dither_and_shift_op_left;
      .VAR $audio_out_dither_and_shift_op_left.next = &$audio_out_dither_and_shift_op_right;
      .VAR $audio_out_dither_and_shift_op_left.func = &$cbops.dither_and_shift;
      .VAR $audio_out_dither_and_shift_op_left.param[$cbops.dither_and_shift.STRUC_SIZE] =
         0,                                        // Input index
         2,                                        // Output index
        -8,                                        // amount of shift after dithering
         $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
         $dither_hist_left,                        // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
         0;                                        // Enable compressor
   .ENDBLOCK;

   .BLOCK $audio_out_dither_and_shift_op_right;
      .VAR $audio_out_dither_and_shift_op_right.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_dither_and_shift_op_right.func = &$cbops.dither_and_shift;
      .VAR $audio_out_dither_and_shift_op_right.param[$cbops.dither_and_shift.STRUC_SIZE] =
         1,                                        // Input index
         3,                                        // Output index
        -8,                                        // amount of shift after dithering
         $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
         $dither_hist_right,                       // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
         0;                                        // Enable compressor
   .ENDBLOCK;

   // ** allocate memory for mono audio out cbops copy routine **
   .VAR $mono_out_copy_struc[] =
      &$audio_out_tone_upsample_mono_mix, // first operator block
      1,                                  // number of inputs
      &$dac_out_temp_left_cbuffer_struc,  // input
      1,                                  // number of outputs
      $AUDIO_LEFT_OUT_PORT;               // output

   //tone mixing can not be the last operator as it does upsamling and mixing in place
   // In mono mode if the tone is stereo, both left and right tone channels will be mixed
   // to audio output channel.
   .BLOCK $audio_out_tone_upsample_mono_mix;
      .VAR $audio_out_tone_upsample_mono_mix.next = $audio_out_tone_right_upsample_mono_mix;
      .VAR $audio_out_tone_upsample_mono_mix.func = &$cbops.auto_upsample_and_mix;
      .VAR $audio_out_tone_upsample_mono_mix.param[$cbops.auto_resample_mix.STRUC_SIZE] =
         0,                                 // Input index to first channel (left channel)
         -1,                                // Index to second channel (no right cchannel)
         &$tone_in_cbuffer_struc,           // cbuffer structure containing tone samples
         &$sra_coeffs,                      // coefs for resampling
         &$current_dac_sampling_rate,       // pointer to variable containing dac rate received from vm (if 0, default 48000hz will be used)
         &$tone_hist,                       // history buffer for resampling
         &$current_tone_sampling_rate,      // pointer to variable containing tone rate received from vm (if 0, default 8000hz will be used)
         0.5,                               // tone volume mixing (set by vm, halved for stereo prompts)
         0.5,                               // audio volume mixing
         0 ...;                             // Pad out remaining items with zeros
   .ENDBLOCK;

   .BLOCK $audio_out_tone_right_upsample_mono_mix;
      .VAR $audio_out_tone_right_upsample_mono_mix.next = &$signal_detect_op_mono;
      .VAR $audio_out_tone_right_upsample_mono_mix.func = &$cbops.auto_upsample_and_mix;
      .VAR $audio_out_tone_right_upsample_mono_mix.param[$cbops.auto_resample_mix.STRUC_SIZE] =
         0,                                 // Input index to first channel (left channel)
         -1,                                // Index to second channel (no right cchannel)
         &$tone_in_right_cbuffer_struc,     // cbuffer structure containing tone samples
         &$sra_coeffs,                      // coefs for resampling
         &$current_dac_sampling_rate,       // pointer to variable containing dac rate received from vm (if 0, default 48000hz will be used)
         &$tone_right_hist,                 // history buffer for resampling
         &$current_tone_sampling_rate,      // pointer to variable containing tone rate received from vm (if 0, default 8000hz will be used)
         0.25,                              // tone volume mixing (same as for left structure)
         1.0,                               // audio volume mixing
         0 ...;                             // Pad out remaining items with zeros
   .ENDBLOCK;

   .BLOCK $signal_detect_op_mono;
      .VAR $signal_detect_op_mono.next = &$audio_mute_op_mono;
      .VAR $signal_detect_op_mono.func = &$cbops.signal_detect_op;
      .VAR $signal_detect_op_mono.param[$cbops.signal_detect_op.STRUC_SIZE_MONO] =
         &$signal_detect_op_coefs,        // pointer to coefficients
         1,                               // number of channels to process
         0;                               // channel index
   .ENDBLOCK;

   .BLOCK $audio_mute_op_mono;
        .VAR $audio_mute_op_mono.next = &$audio_out_dc_remove_op_mono;
        .VAR $audio_mute_op_mono.func = &$cbops.soft_mute;
        .VAR $audio_mute_op_mono.param[$cbops.soft_mute_op.STRUC_SIZE_MONO] =
            1,      // mute direction (1 = unmute audio)
            0,      // index
            1,      // number of channels
            0,      // input index
            0;      // output index
    .ENDBLOCK;
    
   // *** Software rate-match ***
   .BLOCK $audio_out_dc_remove_op_mono;
      .VAR audio_out_dc_remove_op_mono.next = rm_mono_switch_op;
      .VAR audio_out_dc_remove_op_mono.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_mono.param[$cbops.dc_remove.STRUC_SIZE] =
         0,                               // Input index
         0,                               // Output index
         0;                               // DC estimate field
   .ENDBLOCK;

   // Switch operator chains according to whether rate matching is enabled
   .BLOCK rm_mono_switch_op;
      .VAR rm_mono_switch_op.next = &$audio_out_dither_and_shift_op_mono;
      .VAR rm_mono_switch_op.func = $cbops.switch_op;
      .VAR rm_mono_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
         $sw_rate_match_disable,                // Pointer to switch (non-zero to disabble sw rate matching
         $audio_out_rate_adjustment_and_shift_op_mono,// ALT_NEXT_FIELD, pointer to alternate cbops chain
         0xFFFF,                                // SWITCH_MASK_FIELD
         0 ...;
   .ENDBLOCK;

   .BLOCK $audio_out_rate_adjustment_and_shift_op_mono;
      .VAR $audio_out_rate_adjustment_and_shift_op_mono.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_rate_adjustment_and_shift_op_mono.func = &$cbops.rate_adjustment_and_shift;
      .VAR $audio_out_rate_adjustment_and_shift_op_mono.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
      0,  //   INPUT1_START_INDEX_FIELD
      1,  //   OUTPUT1_START_INDEX_FIELD
      -1, //   INPUT2_START_INDEX_FIELD
      -1, //   OUTPUT2_START_INDEX_FIELD
      -8, //   SHIFT_AMOUNT_FIELD
      &$sra_coeffs_hd_quality,
      &$sr_hist_left,
      0,
      $spdif_sra_struct + $spdif_sra.SRA_RATE_FIELD,
      $cbops.dither_and_shift.DITHER_TYPE_NONE,  //   DITHER_TYPE_FIELD
      0,                                              // no compression
      length($sr_hist_left),
      0 ...;                           // Pad out remaining items with zeros
    .ENDBLOCK;

    .BLOCK $audio_out_dither_and_shift_op_mono;
      .VAR $audio_out_dither_and_shift_op_mono.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_dither_and_shift_op_mono.func = &$cbops.dither_and_shift;
      .VAR $audio_out_dither_and_shift_op_mono.param[$cbops.dither_and_shift.STRUC_SIZE] =
         0,                                        // Input index
         1,                                        // Output index
        -8,                                        // amount of shift after dithering
         $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
         &$dither_hist_left,                       // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
         0;                                        // Enable compressor
   .ENDBLOCK;

   .VAR $DecoderMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
     0,                                 // STAT
     0,                                 // TMAIN
     0,                                 // SMAIN
     0,                                 // TINT
     0,                                 // SINT
     0,                                 // SMAIN_INT
     0,                                 // MAIN_CYCLES
     0,                                 // INT_CYCLES
     0,                                 // TOT_CYCLES
     0;                                 // TEVAL

   .VAR $FunctionMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
     0,                                 // STAT
     0,                                 // TMAIN
     0,                                 // SMAIN
     0,                                 // TINT
     0,                                 // SINT
     0,                                 // SMAIN_INT
     0,                                 // MAIN_CYCLES
     0,                                 // INT_CYCLES
     0,                                 // TOT_CYCLES
     0;                                 // TEVAL

   // This is the codec type being used
   .VAR $codec_type = -1;

   // This is the codec config being used
   .VAR $codec_config = -1;

   .VAR $sw_rate_match_disable = $DISABLE_SW_RATE_MATCH_HW_PREFERED;
   .VAR $hw_rate_match_disable = $ENABLE_RATE_MATCH;
   .VAR $rate_match_disable = 0;
   .VAR $spdif_config_word;
   .VAR $spdif_stat_word;

   .VAR $spdif_stats[$music_example.CODEC_STATS_SIZE] =
      &$spdif_config_word,
      &$spdif_stat_word,
      $spdif_copy_struct + $spdif.frame_copy.UNSUPPORTED_BURST_COUNT_FIELD,
#ifdef AC3_ENABLE
     &$ac3dec_config_words +0,
     &$ac3dec_config_words +1,
#else
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT2
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT3
#endif
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT4
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT5
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT6
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT7
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT8
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT9
      &$M.system_config.data.ZeroValue,                        // CODEC_STATA
      &$M.system_config.data.ZeroValue,                        // CODEC_STATB
      &$audio_if_mode,                                         // INTERFACE_TYPE
      $current_codec_sampling_rate,                            // INPUT_RATE
      &$current_dac_sampling_rate,                             // OUTPUT_RATE
      &$current_codec_sampling_rate;                           // CODEC_RATE

#ifdef AC3_ENABLE
// AC-3 specific stats
.VAR $ac3_stats[8] =
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_LENGTH_FIELD,              // CODEC_STAT4
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_ACMODE_FIELD,              // CODEC_STAT5
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_DIALNORM_FIELD,            // CODEC_STAT6
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_LFE_ON_FIELD,              // CODEC_STAT7
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_DSURMOD_FIELD,             // CODEC_STAT8
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_BSID_FIELD,                // CODEC_STAT9
     $ac3dec_user_info_struct + $ac3dec.info.TOTAL_CORRUPT_FRAME_FIELD,       // CODEC_STATA
     $ac3dec_user_info_struct + $ac3dec.info.FRAME_ANNEXD_INFO_FIELD;         // CODEC_STATB
#endif

#ifdef AAC_ENABLE
// AAC specific stats
.VAR $aac_stats[8] =
      &$aacdec.sf_index,                                // CODEC_STAT4
      &$aacdec.channel_configuration,                   // CODEC_STAT5
      &$aacdec.audio_object_type,                       // CODEC_STAT6
      &$aacdec.extension_audio_object_type,             // CODEC_STAT7
      &$aacdec.sbr_present,                             // CODEC_STAT8
      &$aacdec.mp4_frame_count,                         // CODEC_STAT9
      &$M.system_config.data.ZeroValue,                 // CODEC_STATA
      &$M.system_config.data.ZeroValue;                 // CODEC_STATB
#endif

#ifdef MP3_ENABLE
// MP3 specific stats
.VAR $mp3_stats[8] =
      &$mp3dec.mode,                                    // CODEC_STAT4
      &$mp3dec.framelength,                             // CODEC_STAT5
      &$mp3dec.bitrate,                                 // CODEC_STAT6
      &$mp3dec.frame_version,                           // CODEC_STAT7
      &$mp3dec.frame_layer,                             // CODEC_STAT8
      &$M.system_config.data.ZeroValue,                 // CODEC_STAT9
      &$M.system_config.data.ZeroValue,                 // CODEC_STATA
      &$M.system_config.data.ZeroValue;                 // CODEC_STATB
#endif

   // define spdif i   nput structure
   .VAR $spdif_copy_struct[$spdif.frame_copy.STRUC_SIZE] =
      $SPDIF_IN_LEFT_PORT,                                      //LEFT_INPUT_PORT_FIELD
      $SPDIF_IN_RIGHT_PORT,                                     //RIGHT_INPUT_PORT_FIELD
      &$spdif_in_cbuffer_struc,                                 //SPDIF_INPUT_BUFFER_FIELD
      &$audio_out_left_cbuffer_struc,                           //LEFT_PCM_BUFFER_FIELD
      &$audio_out_right_cbuffer_struc,                          //RIGHT_PCM_BUFFER_FIELD
      &$codec_in_cbuffer_struc,                                 //CODED_BUFFER_FIELD
      0,                                                        //SUPPORTED_CODEC_TYPES_BITS_FIELD
      0 ...;

   .VAR $spdif_stream_decode_struct[$spdif.stream_decode.STRUC_SIZE] =
      &$spdif_copy_struct,                                                   // SPDIF_FRAME_COPY_STRUCT_FIELD
      &$spdif_get_decoder_call_back,                                         // GET_DECODER_FUNCTION_PTR_FIELD
      &$spdif_codec_change_master_reset,                                     // MASTER_RESET_FUNCTION_FIELD
      $spdif.OUTPUT_INTERFACE_TYPE_NONE,                                     // OUTPUT_INTERFACE_TYPE_FIELD
      $AUDIO_LEFT_OUT_PORT,                                                  // OUTPUT_INTERFACE_LEFT_PORT_FIELD
      $AUDIO_RIGHT_OUT_PORT,                                                 // OUTPUT_INTERFACE_RIGHT_PORT_FIELD
      ($audio_mute_op_stereo.param + $cbops.soft_mute_op.MUTE_DIRECTION), // OUTPUT_INTERFACE_FADING_DIRECTION_PTR_FIELD
      0,                                                                     // OUTPUT_INTERFACE_SETTING_RATE_FIELD
      $encoded_latency_struct,                                                 // LATENCY_MEASUREMENT_STRUCT_FIELD
      0 ...;

      .VAR $sra_rate_addr = $spdif_sra_struct + $spdif_sra.SRA_RATE_FIELD;

#if  defined(AC3_ENABLE) || defined(MP3_ENABLE) || defined(AAC_ENABLE)
   .VAR/DM1 $decoder_struct[$codec.DECODER_STRUC_SIZE] =
      &$codec_in_cbuffer_struc,                    // in cbuffer
      &$audio_out_left_cbuffer_struc,              // out left cbuffer
      &$audio_out_right_cbuffer_struc,             // out right cbuffer
      0 ...;
#endif

#ifdef AC3_ENABLE
   // user AC-3 decoder configuration
   .VAR $ac3dec_user_config[$ac3dec.config.STRUCT_SIZE] =
       0,                                   // cbuffer for output LFE channel
       $ac3dec.ACMOD_20,                    // the output mode, dictates how the input channel should be downmixed if needed
       $ac3dec.STEREO_LORO_MODE,            // stereo mode that should be used when downmixng to 2.0 output mode
       $ac3dec.DUAL_STEREO_MODE,            // dual mode
       $ac3dec.COMP_LINE_MODE,              // the compression mode that should be used for decoded audio samples
       $ac3dec.UNITY_SCALE,                 // optional compression scale
       $ac3dec.UNITY_SCALE,                 // optional compression scale
       $ac3dec.UNITY_SCALE,                 // pcm scale
       0 ...;

   // defining ac3 user info structure
   .VAR $ac3dec_user_info_struct[$ac3dec.info.STRUCT_SIZE];
   .VAR $config_ac3_decoder_vm_message_struc[$message.STRUC_SIZE];
   .VAR $ac3_user_info_request_vm_message_struc[$message.STRUC_SIZE];
   .VAR $ac3dec_reconfig_needed = 1;
   .VAR $ac3dec_config_words[2];
#endif

   .VAR $hw_warp_struct[$hw_warp.STRUC_SIZE] =
       32000,
       $spdif_sra_struct + $spdif_sra.SRA_RATE_FIELD,
       128,
       0 ...;

   // Rate matching data structure
   .VAR $spdif_sra_struct[$spdif_sra.STRUC_SIZE] =
       MAX_SPDIF_SRA_RATE,       //MAX_RATE_FIELD
       SPDIF_DEFAULT_LATENCY_MS, //TARGET_LATENCY_MS_FIELD
       &$encoded_latency_struct + $encoded_latency.TOTAL_LATENCY_US_FIELD, //CURRENT_LATENCY_PTR_FIELD
       0,                     //OFFSET_LATENCY_US_FIELD
       0 ...;

   .VAR/DMCIRC $encoded_packet_info[SPDIF_PACKET_BOUNDARY_INFO_SIZE];

   // packet info cbufer structure
   .VAR $encoded_packet_info_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($encoded_packet_info),            // size
      &$encoded_packet_info,                   // read pointer
      &$encoded_packet_info;                   // write pointer

   .VAR $latency_calc_current_warp = &$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;

   // inverse of dac samole rate, used for latency calculation
   .VAR $inv_dac_fs = $latency.INV_FS(48000);

   // define latency structure, spdif needs coded structure
   .VAR $encoded_latency_struct[$encoded_latency.STRUC_SIZE] =
      $pcm_latency_input_struct,
      $encoded_packet_info_cbuffer_struc,
      $codec_in_cbuffer_struc,
      &$audio_out_left_cbuffer_struc,
      $spdif_copy_struct + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD, &$latency_calc_current_warp,
      0 ...;

    // define cbuffers structure involved in pcm latency
    .VAR cbuffers_latency_measure[] =
       &$audio_out_left_cbuffer_struc,
       $spdif_copy_struct + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD, &$latency_calc_current_warp,
       $dac_out_left_cbuffer_struc,
       $spdif_copy_struct + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD, &$latency_calc_current_warp,
       $dac_out_temp_left_cbuffer_struc,
       $inv_dac_fs, &$latency_calc_current_warp,
       $AUDIO_LEFT_OUT_PORT,
       $inv_dac_fs, 0,
       0;

    // define samples structure involved in pcm latency
    .VAR samples_latency_measure[] =
       // place holder for delay buffer when sub is connected
       0,$spdif_copy_struct + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD, &$latency_calc_current_warp,
       0;

    // define pcm latency structure
    .VAR $pcm_latency_input_struct[$pcm_latency.STRUC_SIZE] =
      &cbuffers_latency_measure,
      &samples_latency_measure;

// Program code
//------------------------------------------------------------------------------

   // initialise the stack library
   call $stack.initialise;
   // initialise the interrupt library
   call $interrupt.initialise;
   // initialise the message library
   call $message.initialise;
   // initialise the cbuffer library
   call $cbuffer.initialise;
   // initialise the pskey library
   call $pskey.initialise;
   // initialise the wallclock library
   call $wall_clock.initialise;
#if defined(DEBUG_ON)
   // initialise the profiler library
   call $profiler.initialise;
#endif
   // init DM_flash
   call $flash.init_dmconst;

   // intialize SPI communications library
   call $spi_comm.initialize;

#ifdef AC3_ENABLE
   // initialise ac3 decoder
   call $ac3dec.init_decoder;

   // set up message handler for VM_AC3_DECODER_CONFIG_MESSAGE_ID message
   r1 = &$config_ac3_decoder_vm_message_struc;
   r2 = VM_AC3_DECODER_CONFIG_MESSAGE_ID;
   r3 = &$config_ac3_decoder_message_handler;
   call $message.register_handler;

   // set up message handler for VM_AC3_USER_INFO_REQUEST_MESSGE_ID message
   r1 = &$ac3_user_info_request_vm_message_struc;
   r2 = VM_AC3_USER_INFO_REQUEST_MESSGE_ID;
   r3 = &$ac3_user_info_request_message_handler;
   call $message.register_handler;

#endif

#ifdef AAC_ENABLE
   // initialise aac decoder
   call $aacdec.init_decoder;
   r0 = &$aacdec.adts_read_frame;
   M[$aacdec.read_frame_function] = r0;
#endif

#ifdef MP3_ENABLE
   // initialise mp3 decoder
   call $mp3dec.init_decoder;;
#endif

   // set up message handler for VM_SET_CODEC_RATE_MESSAGE_ID message
   r1 = &$set_tone_rate_from_vm_message_struc;
   r2 = VM_SET_TONE_RATE_MESSAGE_ID;
   r3 = &$set_tone_rate_from_vm;
   call $message.register_handler;

   // set up message handler for VM_CONFIG_SPDIF_APP_MESSAGE_ID message
   r1 = &$config_spdif_sink_vm_message_struc;
   r2 = VM_CONFIG_SPDIF_APP_MESSAGE_ID;
   r3 = &$config_spdif_sink_message_handler;
   call $message.register_handler;

   // Power Up Reset needs to be called once during program execution
   call $music_example.power_up_reset;

   r2 = $music_example.VMMSG.READY;
   r3 = $MUSIC_MANAGER_SYSID;
   // status
   r4 = M[$music_example.Version];
   r4 = r4 LSHIFT -8;
   call $message.send_short;

#ifdef SUB_ENABLE
   r0 = $spdif_sub_esco_process;
   M[$sub_app_esco_func] = r0;
   call $M.Subwoofer.subwoofer_init;
#endif // SUB_ENABLE

   // tell vm we're ready and wait for the go message
   call $message.send_ready_wait_for_go;

   // start timer that copies output samples
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in;

   // Start a timer that copies spdif input
   r1 = &$spdif_in_timer_struc;
   r2 = TMR_PERIOD_SPDIF_COPY;
   r3 = &$spdif_in_copy_handler;
   call $timer.schedule_event_in;

   // start timer that copies tone samples
   r1 = &$tone_copy_timer_struc;
   r2 = M[$tmr_period_tone_copy];
   r3 = &$tone_copy_handler;
   call $timer.schedule_event_in;

    // post timer event for standby level detector
    r1 = &$signal_detect_timer_struc;
    r2 = SIGNAL_DETECT_TIMER_PERIOD;
    r3 = &$signal_detect_timer_handler;
    call $timer.schedule_event_in;

    // continually decode codec frames
    frame_loop:

      #ifdef AC3_ENABLE
         // configure AC-3 decoder
         call $block_interrupts;
         r0 = $ac3dec_user_config;
         r1 = $ac3dec_user_info_struct;
         Null = M[$ac3dec_reconfig_needed];
         if NZ call $ac3dec.set_user_config;
         M[$ac3dec_reconfig_needed] = 0;
         call $unblock_interrupts;
      #endif

       // Check Communication
       call $spi_comm.polled_service_routine;

       // Start profiler
       r8 = &$DecoderMips_data_block;
       call $M.mips_profile.mainstart;

       // run spdif decode
       r5 = $spdif_stream_decode_struct;
       call $spdif.decode;

       // Stop profiler
       r8 = &$DecoderMips_data_block;
       call $M.mips_profile.mainend;

       // Store Decoder MIPS
       r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
       M[&$music_example.PeakMipsDecoder] = r0;

       // Synchronize frame process to audio
       Null = M[$spdif_stream_decode_struct + $spdif.stream_decode.MODE_FIELD];
       if NZ call $frame_sync.1ms_delay;

       // syncronise LFE to L/R channels
       call $syncronise_lfe_to_LR_channels;


       r3 = M[$music_example.frame_processing_size];

       r0 = $audio_out_left_cbuffer_struc;
       call $cbuffer.calc_amount_data;
       null = r0 - r3;
       if NEG jump frame_loop;

       r0 = $audio_out_right_cbuffer_struc;
       call $cbuffer.calc_amount_data;
       null = r0 - r3;
       if NEG jump frame_loop;

       r0 = $audio_out_lfe_cbuffer_struc;
       call $cbuffer.calc_amount_data;
       null = r0 - r3;
       if NEG jump frame_loop;

       // check for space
       r0 = $dac_out_left_cbuffer_struc;
       call $cbuffer.calc_amount_space;
       null = r0 - r3;
       if NEG jump frame_loop;

       Null = M[$music_example.stereo_processing];
       if Z jump mono_process;
          r0 = $dac_out_right_cbuffer_struc;
          call $cbuffer.calc_amount_space;
          null = r0 - r3;
          if NEG jump frame_loop;
       mono_process:
       call $music_example_process;

   jump frame_loop;

.ENDMODULE;

//------------------------------------------------------------------------------
.module $M.signal_detect_timer_handler;
//------------------------------------------------------------------------------
// timer handler to call signal detector processing every second
//------------------------------------------------------------------------------

    .codesegment pm;
    .datasegment dm;

    $signal_detect_timer_handler:

    // push rLink onto stack
    $push_rLink_macro;

    r8 = &$signal_detect_op_coefs;
    call $cbops.signal_detect_op.timer_handler;

    // post another timer event
    r1 = &$signal_detect_timer_struc;
    r2 = SIGNAL_DETECT_TIMER_PERIOD;
    r3 = &$signal_detect_timer_handler;
    call $timer.schedule_event_in_period;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.endmodule;
// *****************************************************************************
// MODULE:
//    $audio_out_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the mono or stereo copying
//    of decoded samples to the output.
//
// *****************************************************************************
.MODULE $M.audio_out_copy_handler;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $audio_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   .VAR $mono_copy_struc_ptr = &$mono_out_copy_struc;
   .VAR $stereo_copy_struc_ptr = &$stereo_out_copy_struc;
   .VAR $mono_stereo_mode;  // 0 -> mono, 1 -> stereo


   // If not using cbops.stream_copy, need to manually
   // reset the sync flag.
   M[$frame_sync.sync_flag] = Null;

   // Mono or stereo connection? (based on whether the right output port is enabled)
#if defined(FORCE_MONO)
   r2 = 0;
#else
   r0 = $AUDIO_RIGHT_OUT_PORT;
   r2 = 1;
   call $cbuffer.is_it_enabled;
   if Z r2 = 0;
#endif

   M[$mono_stereo_mode] = r2;

   // update dac sampling rate
   r3 = 48000;
   r0 = M[$spdif_stream_decode_struct + $spdif.stream_decode.OUTPUT_INTERFACE_CURRENT_RATE_FIELD];
   if Z r0 = r3;
   r1 = M[$current_dac_sampling_rate];
   M[$current_dac_sampling_rate] = r0;
   r1 = r1 - r0;

   // update codec sampling rate
   r0 = M[$spdif_copy_struct + $spdif.frame_copy.SAMPLING_FREQ_FIELD];
   if Z r0 = r3;
   r2 = M[$current_codec_sampling_rate];
   M[$current_codec_sampling_rate] = r0;
   r2 = r2 - r0;

   // reconfig resampler if needed
   r2 = r2 OR r1;
   if Z jump resmaple_config_done;

   r0 = M[$current_dac_sampling_rate];
   call $latency.calc_inv_fs;
   M[$inv_dac_fs] = r0;

   call $config_resampler;

   resmaple_config_done:

   // configure rate matching
   call $config_rate_matching;


   // set latency calculation to point to the correct SRA value (software mono, software stereo, or hardware)
   r8 = &$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
   r7 = &$audio_out_rate_adjustment_and_shift_op_mono.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
   Null = M[$mono_stereo_mode];
   if Z r8 = r7;
   r7 = $hw_warp_struct + $hw_warp.CURRENT_RATE_FIELD;
   Null = M[$hw_rate_match_disable];
   if Z r8 = r7;
   M[$latency_calc_current_warp] = r8;

   // run resampler
   r8 = &$dac_out_resampler_stereo_copy_struc;
   r7 = &$dac_out_resampler_mono_copy_struc;
   Null = M[$mono_stereo_mode];
   if Z r8 = r7;
   call $cbops.copy;

   // care for initial latency
   call $adjust_initial_latency;

   // copy to DACs
   r8 = M[$stereo_copy_struc_ptr];
   r7 = M[$mono_copy_struc_ptr];
   Null = M[$mono_stereo_mode];
   if Z r8 = r7;
   call $cbops.dac_av_copy;

   // Post another timer event
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#ifdef SUB_ENABLE
// *****************************************************************************
// MODULE:
//    $spdif_sub_esco_process
//
// DESCRIPTION:
//    called in sub esco timer handler to process and copy sub data
//
// *****************************************************************************
.MODULE $M.spdif_sub_esco_process;
   .CODESEGMENT SPDIF_SUB_ESCO_PROCESS_PM;
   .DATASEGMENT DM;
   $spdif_sub_esco_process:

   // push rLink onto stack
   $push_rLink_macro;
   r0 = M[$sub_link_port];
   Null = r0 - $AUDIO_ESCO_SUB_OUT_PORT;
   if NZ jump not_esco_sub;

   // see if we are in pause mode
   r0 = M[$init_latency_state];
   Null = r0 - 1;
   if NZ jump send_sub;

   // if so wait just before
   // soundbar starts playback
   r0 = M[$time_left_to_play];
   Null = r0 - 5; // 5ms
   if GT jump not_esco_sub;

   send_sub:
         call $M.Subwoofer.esco_preprocess;
         call $M.Subwoofer.esco_post_process;
   not_esco_sub:
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif
// *****************************************************************************
// MODULE:
//    $spdif_pause_detect
//
// DESCRIPTION:
//   when spdif stream is paused for any reason this function
//   generate some silence enough to push all the current audio
//   into the output interface.
// INPUT:
//   r7 = amount of data read from ports in last read
// TRASHED REGISTERS
//   r0-r4, r10, rMAC, DoLoop, I0
// *****************************************************************************
.MODULE $M.spdif_pause_detect;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $spdif_silence_to_insert;
   .VAR $spdif_pause_timer;

   $spdif_pause_detect:

   // push rLink onto stack
   $push_rLink_macro;

   // r7 = 0 means no data read from spdif input ports
   Null = r7;
   if NZ jump spdif_stream_active;

   // see if pause threshold has reached
   r0 = M[$spdif_pause_timer];
   r0 = r0 + TMR_PERIOD_SPDIF_COPY;
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
   rMAC = r3 * TMR_PERIOD_SPDIF_COPY;
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
   r0 = (SPDIF_PAUSE_SILENCE_TO_ADD_MS*1000);
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
   .CODESEGMENT SPDIF_IN_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $spdif_in_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // read raw data from spdif LEFT and RIGHT ports
   r8 = &$spdif_copy_struct;
   call $spdif.copy_raw_data;

   // Note: r7 = amount copied,
   // used by next functions

   // set some variables used to adjust initial latency
   .VAR $first_audio_received;           // flag showing first valid SPDIF input audio received after an inactivity period
   .VAR $first_audio_time;               // the time of receiving first audio samples
   .VAR $first_audio_init_latency_offset;// latency ahead of first audio burst
   // mark the arrival of first packet
   Null = M[$first_audio_received];
   if NZ jump first_audio_done;
      Null = r7;  // new data received?
      if Z jump first_audio_done;
         // set the flag
         r0 = 1;
         M[$first_audio_received] = r0;
         // set arrival time
         r2 = M[$TIMER_TIME];
         M[$first_audio_time] = r2;
         r2 = M[$encoded_latency_struct + $encoded_latency.TOTAL_LATENCY_US_FIELD];
         M[$first_audio_init_latency_offset] = r0;
   first_audio_done:

   // insert some silence if
   // pause detected
   call $spdif_pause_detect;

   // update stat word for UFE
   call $spdif_update_stat_word;

   // calculate rate
   Null = M[$rate_match_disable];
   if Z call $spdif_sra.calc_rate;

   // apply hw rate matching
   call $apply_hardware_warp_rate;

   // just for debugging
   .VAR $codec_level;
   r0 = &$codec_in_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   M[$codec_level] = r0;

   // post another timer event
   r1 = &$spdif_in_timer_struc;
   r2 = TMR_PERIOD_SPDIF_COPY;
   r3 = &$spdif_in_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $detect_end_of_aux_stream
//
// DESCRIPTION:
//    detects end of pcm tone/prompts and notifies vm
// *****************************************************************************

.MODULE $M.detect_end_of_aux_stream;
   .CODESEGMENT DETECT_END_OF_AUX_STREAM_PM;
   .DATASEGMENT DM;
   .VAR $no_tone_timer;

   $detect_end_of_aux_stream:

   $push_rLink_macro;

   // detect end of tone/prompt auxiliary pcm input stream
   r3 = M[$aux_input_stream_available];
   if Z jump $pop_rLink_and_rts;

   // see if the input is active
   r0 = $tone_in_cbuffer_struc;
   call $cbuffer.calc_amount_data;

   // check if input activity has been seen before
   Null = r3 AND 0x2;
   if NZ jump input_has_received;

   // input hasn't started yet, so no end check
   Null = r0;
   if Z jump $pop_rLink_and_rts;

   // input just received
   r3 = r3 OR 0x2;
   M[$aux_input_stream_available] = r3;
   M[$no_tone_timer] = 0;
   jump $pop_rLink_and_rts;

   input_has_received:
   // see if input has become inactive
   r1 = M[$no_tone_timer];
   r1 = r1 + M[$tmr_period_tone_copy];
   Null = r0;
   if NZ r1 = 0;
   M[$no_tone_timer] = r1;
   // has it been inactive in past predefined time?
   Null = r1 - $PCM_END_DETECTION_TIME_OUT;
   if NEG jump $pop_rLink_and_rts;

   // inactive more than a threshold
   // notify VM about end of play back of aux input
   r2 = PLAY_BACK_FINISHED_MSG;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send_short;
   M[$aux_input_stream_available] = 0;
   M[$no_tone_timer] = 0;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $tone_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the copying of tone
//    samples.
//
// *****************************************************************************

.MODULE $M.tone_copy_handler;
   .CODESEGMENT TONE_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $tone_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // copy tone data from the port
   r8 = &$tone_in_copy_struc;
   r7 = $stereo_tone_in_copy_struc;
   Null = M[$stereo_tone];
   if NZ r8 = r7;
   call $cbops.copy;

   // detect end of tone/prompt stream
   call $detect_end_of_aux_stream;

   // post another timer event
   r1 = &$tone_copy_timer_struc;
   r2 = M[$tmr_period_tone_copy];
   r3 = &$tone_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $set_tone_rate_from_vm
//
// DESCRIPTION: message handler for receiving tone rate from VM
//
// INPUTS:
//  r1 = (tone rate)
//  r2 = bit 0: mono / stereo
//       bit 1: tone / prompt
//  r3 = Not used
//  r4 = Not used
//
// OUTPUTS:
//    None
// TRASHED RGISTERS:
//    rMAC, Div, r1
// *****************************************************************************
.MODULE $M.set_tone_rate_from_vm;
   .CODESEGMENT SET_TONE_RATE_FROM_VM_PM;

   $set_tone_rate_from_vm:

   // extract tone rate
   r1 = r1 AND 0xFFFF;

   // timer period = TMR_PERIOD_TONE_COPY/(freq/8000.0)
   rMAC = (TMR_PERIOD_TONE_COPY/4);
   rMAC = rMAC * 8000;
   Div = rMAC / r1;

   // Store the tone sampling rate
   M[$current_tone_sampling_rate] = r1;

   // prompts are normalised
   // tones need 3 bits amplification
   r0 = 3;
   Null = r2 AND 2;
   if NZ r0 = 0;
   r0 = r0 + 8;
   M[$tone_in_copy_op.param + $cbops.shift.SHIFT_AMOUNT_FIELD] = r0;
   M[$stereo_tone_in_copy_op.param + $cbops.deinterleave.SHIFT_AMOUNT_FIELD] = r0;

   // Store the tone timer period
   r3 = DivResult;
   // extract stereo flag
   r0 = r2 AND 1;
   // timer period is halved for stereo prompts
   if Z r3 = r3 + r3;
   M[$tmr_period_tone_copy] = r3;
   M[$stereo_tone] = r0;
   if Z jump mono_tone;
   stereo_tone:
      // stereo main mix op right index
      r0 = -1;
      // stereo right mix op tone ratio
      r1 = M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD];
      // mono main mix op tone ratio
      r2 = r1 ASHIFT -1;
      // mono right mix op tone ratio
      r3 = r2;
   jump set_op;
   mono_tone:
      // stereo main mix op right index
      r0 = 1;
      // stereo right mix op tone ratio
      r1 = 0;
      // mono main mix op tone ratio
      r2 = M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD];
      // mono right mix op tone ratio
      r3 = 0;
   set_op:
   // set stereo main mix op right index
   M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD] = r0;
   // set stereo right mix op tone ratio
   M[$audio_out_tone_right_upsample_stereo_mix.param + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD] = r1;
   // set mono main mix op tone ratio
   M[$audio_out_tone_upsample_mono_mix.param + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD] = r2;
   // set mono right mix op tone ratio
   M[$audio_out_tone_right_upsample_mono_mix.param +  $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD] = r3;

   // purge tone buffers, safegaurd to make sure left and
   // right channels are syncronised
   r0 = M[&$tone_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$tone_in_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   r0 = M[&$tone_in_right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$tone_in_right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;

   // auxiliary input expected now
   r0 = 1;
   M[$aux_input_stream_available] = r0;

   rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $config_rate_matching
//
// DESCRIPTION: Configure the rate matching algorithm
//
// INPUTS:
//  - none
//
// OUTPUTS:
//  - none
//
// *****************************************************************************
.MODULE $M.config_rate_matching;
   .CODESEGMENT CONFIG_RATE_MATCHING_PM;

   $config_rate_matching:

   // r1 = hardware rate match disable
   // r2 = software rate match disable
   // r3 = minimum target latency
   // disable both if overal rate match is disabled
   r1 = M[$rate_match_disable];
   r2 = r1;
   r3 = MIN_SPDIF_LATENCY_MS;
   #ifdef SUB_ENABLE
      // if esco sub is connected then timing is controlled by sco connection
      r0 = M[$sub_link_port];
      Null = r0 - $AUDIO_ESCO_SUB_OUT_PORT;
      if NZ jump sub_check_done;
      // extra latency happens when sub is connected
      r3 = MIN_SPDIF_LATENCY_WITH_SUB_MS;
      // hardware rate matching not suitable for sub
      r1 = r1 OR ($DISABLE_HW_RATE_MATCH_SUB_NEEDS);
      jump set_config;
   sub_check_done:
   #endif // SUB_ENABLE

   // for DAC, hardware rate match is prefered
   r3 = M[$spdif_stream_decode_struct + $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_FIELD];
   Null = r3 - $spdif.OUTPUT_INTERFACE_TYPE_DAC;
   if NZ jump disable_hw;

      // hardware rate matching is not doable
      r2 = r2 OR ($DISABLE_SW_RATE_MATCH_HW_PREFERED);
   jump set_config;

   disable_hw:
      // hardware rate matching is prefered
      r1 = r1 OR ($DISABLE_HW_RATE_MATCH_NOT_DOABLE);
   set_config:
   M[$hw_rate_match_disable] = r1;
   M[$sw_rate_match_disable] = r2;

   // at least one of them must be disabled
   Null = r1 OR r2;
   if Z call $error;

   // check minimum target latency
   r0 = M[$spdif_target_latency_setting];
   r0 = MAX r3;

   // check maximum target latency
   r3 = MAX_SPDIF_LATENCY_PCM_MS;
   r2 = MAX_SPDIF_LATENCY_CODED_MS;
   r1 = M[$spdif_stream_decode_struct + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD];
   Null = r1 - $spdif.DECODER_TYPE_PCM;
   if GT r3 = r2;
   r0 = MIN r3;

   // set target latency
   M[$spdif_sra_struct + $spdif_sra.TARGET_LATENCY_MS_FIELD] = r0;

   rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//   $apply_hardware_warp_rate
//
// DESCRIPTION:
//   Applies hardware warp rate by sending message to the firmware
//
// *****************************************************************************
.MODULE $M.apply_hardware_warp_rate;
   .CODESEGMENT APPLY_WARP_RATE_PM;
   .DATASEGMENT DM;

   $apply_hardware_warp_rate:

   // push rLink onto stack
   $push_rLink_macro;

   // see if it's time to update hardware warp
   r0 = M[$TIMER_TIME];
   r1 = M[$hw_warp_struct + $hw_warp.LAST_TIME_FIELD];
   r2 = r0 - r1;
   if NEG r2 = -r2;
   r3 = M[$hw_warp_struct + $hw_warp.TIMER_PERIOD_FIELD];
   Null = r2 - r3;
   if NEG jump $pop_rLink_and_rts;

   // update last update time
   r1 = r1 + r3;
   r2 = r1 - r0;
   if NEG r2 = -r2;
   Null = r2 - 2000;
   if POS r1 = r0;
   M[$hw_warp_struct + $hw_warp.LAST_TIME_FIELD] = r1;

   // slowly move towards the target rate
   r4 = M[$hw_warp_struct + $hw_warp.TARGET_RATE_PTR_FIELD];
   r5 = M[$hw_warp_struct + $hw_warp.CURRENT_RATE_FIELD];
   r4 = M[r4];
   Null = M[$hw_rate_match_disable];
   if NZ r4 = 0;

   // calculate moving step (logarithmic then linear)
   r0 = r5 - r4;
   if Z jump $pop_rLink_and_rts;
   if NEG r0 = -r0;
   r1 = M[$hw_warp_struct + $hw_warp.MOVING_STEP_FIELD];
   rMAC = r3 * 274878;
   r3 = rMAC ASHIFT 8;
   r2 = r0 * r3(frac);
   Null = r0 - 0.0015;
   if NEG r2 = r1;
   r3 = r1 * 20 (int);
   r1 = r2 - r3;
   if POS r2 = r2 - r1;
   r1 = r5 - r4;
   r0 = r1 - r2;
   if POS r1 = r1 - r0;
   r0 = r1 + r2;
   if NEG r1 = r1 - r0;

   // update the current rate
   r5 = r5 - r1;
   r4 = r5 ASHIFT -6;
   r5 = r4 ASHIFT 6;

   // Has the rate changed? - only send rate update message if changed
   r0 = M[$hw_warp_struct + $hw_warp.CURRENT_RATE_FIELD];
   r1 = r5 - r0;
   if Z jump end_hw_rate_apply;
      //  apply harware warp rate
      M[$hw_warp_struct + $hw_warp.CURRENT_RATE_FIELD] = r5;
      r4 = -r4;
      r2 = &$MESSAGE_WARP_DAC;
      r3 = 3;
      call $message.send_short;
   end_hw_rate_apply:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.mute_control.Process.func
//
// DESCRIPTION:
// Control the codec mute function
//
// MODIFICATIONS:
//
//  INPUT:
//      r7 - Pointer to the $music_example.MUTE_CONTROL data buffer.
//  OUTPUT:
//    none
// TRASHED REGISTERS:
//      r0, M1,I0,L0,I2,M0,M1
//
// CPU USAGE:
// *****************************************************************************
.MODULE $M.mute_control.Process.func;

   .CODESEGMENT MUTE_CONTROL_FUNC_PM;

$mute_control.Process.func:
   // Pointer to the data struc
   I2 = r7;
   M1 = 1;

   r0 = M[I2,M1];             // OFFSET_INPUT_PTR
   I0 = r0, r0 = M[I2,M1];    // OFFSET_INPUT_LEN

   L0 = r0, r0 = M[I2,M1];    // OFFSET_NUM_SAMPLES
   r10 = r0;

   M0 = r0;
   r0 = M[I2,M1];             // OFFSET_MUTE_VAL
   if NZ jump jp_mute;
      // dummy ready to advance pointer if not mute
      r0 = M[I0,M0];

jp_save_pointer:
      // Save back pointer and return
      r0 = I0;
      L0 = 0;
      M[r7+$music_example.MUTE_CONTROL.OFFSET_INPUT_PTR] = r0;
      rts;

jp_mute:
   // zero buffer
   do loop_mute;
      M[I0,M1] = r0;

loop_mute:
   jump jp_save_pointer;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.copy_codec_stats_pointers
//
// DESCRIPTION:
//    Helper function to copy the codec specific stats pointers into the
//    music_example statistics pointer table
//
// INPUTS:
//    I0 = pointer to codec specific stats pointer table
//
// OUTPUTS:
//    none
//
// TRASHES: r0, r10, I0, I4
//
// *****************************************************************************
.MODULE $M.copy_codec_stats_pointers;
   .CODESEGMENT COPY_CODEC_STATS_POINTERS_PM;

$copy_codec_stats_pointers:

   // Length of the codec specific statistics pointer table
   r10 = $music_example.CODEC_STATS_SIZE;

   // Start of the codec statistics part of the table
   I4 = &$M.system_config.data.StatisticsPtrs + $M.MUSIC_MANAGER.STATUS.CODEC_FS_OFFSET;

   do assign_loop;

      // Copy over the stats pointer
      r0 = M[I0, 1];
      M[I4, 1] = r0;

   assign_loop:

   rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $syncronise_lfe_to_LR_channels
//
// DESCRIPTION:
//    LFE channel migh become available and unavailable in run time, for example
//    when switching from PCM to coded and vice versa, this function makes sure
//    that LFE is always syncronised to LEFT and RIGHT channels
//
// *****************************************************************************
.MODULE $M.syncronise_lfe_to_LR_channels;
   .CODESEGMENT SYNCRONISE_LFE_TO_LR_CHANNELS_PM;
   .DATASEGMENT DM;

$syncronise_lfe_to_LR_channels:

   // push rLink onto stack
   $push_rLink_macro;

   // see if LFE has data
   r0 = $audio_out_lfe_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r6 = r0;

   // amount of data in left input buffer
   r0 = $audio_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r7 = r0;

   // amount of data in right input buffer
   r0 = $audio_out_right_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r7 = MIN r0;

   // already synced?
   r10 = r7 - r6;
   if Z jump $pop_rLink_and_rts;

   // Move LFE read pointer, write pointer
   // is always syncronised
   r0 = $audio_out_lfe_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r10;
   r0 = M[I0, M0];
   r6 = I0;

   // in case of increase, new
   // samples must be silenced
   Null = r10;
   if NEG jump set_buf_address;

   // insert silence
   r0 = 0;
   do insert_silence;
      M[I0, 1] = r0;
   insert_silence:
   set_buf_address:
   r0 = $audio_out_lfe_cbuffer_struc;
   r1 = r6;
   call $cbuffer.set_read_address;

   L0 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//   $spdif_get_decoder_call_back
//
// DESCRIPTION:
//    Call back function for providing decoder functions to SPDIF library. The
//    function is called by the spdif library when the coded data changes, it
//    should provide the library with proper decoder function, so the library
//    can decode the coded data properl.
//
// INPUTS:
//    r1 = coded data type
//
//  OUTPUTS:
//     r0 = decoder input structure
//     r1 = decoder frame decode function
//     r2 = decoder reset function
//
//  NOTES:
//     decoder library is not initialised by spdif library, application needs
//     to make sure it is initialised before passing info to spdif library
//
// *****************************************************************************
.MODULE $M.spdif_get_decoder_call_back;
   .CODESEGMENT SPDIF_GET_DECODER_CALL_BACK_PM;
   .DATASEGMENT DM;

   $spdif_get_decoder_call_back:
   #ifdef AC3_ENABLE
      // r1 = codec type:
      Null = r1 - $spdif.DECODER_TYPE_AC3;
      if NZ jump ac3_type_checked;
      I2 = $ac3_stats;
      r0 = &$decoder_struct;        //  decoder input struture
      r1 = &$ac3dec.frame_decode;   //  decoder frame decode function
      r2 = &$ac3dec.reset_decoder;  //  decoder reset function
      jump update_stats;
      ac3_type_checked:
   #endif

   #ifdef AAC_ENABLE
      // r1 = codec type:
      Null = r1 - $spdif.DECODER_TYPE_MPEG2_AAC;
      if NZ jump aac_type_checked;
      I2 = $aac_stats;
      r0 = &$decoder_struct;        //  decoder input struture
      r1 = &$aacdec.frame_decode;    //  decoder frame decode function
      r2 = &$aacdec.reset_decoder;  //  decoder reset function
      jump update_stats;
      aac_type_checked:
   #endif

   #ifdef MP3_ENABLE
      // r1 = codec type:
      Null = r1 - $spdif.DECODER_TYPE_MPEG1_LAYER23;
      if NZ jump mp3_type_checked;
      I2 = $mp3_stats;
      r0 = &$decoder_struct;        //  decoder input struture
      r1 = &$mp3dec.frame_decode;    //  decoder frame decode function
      r2 = &$mp3dec.reset_decoder;  //  decoder reset function
      jump update_stats;
      mp3_type_checked:
   #endif

   // we don't support any other codecs
   call $error;

   update_stats:
   // update the structure to use codec specific stats
   I6 = &$M.system_config.data.StatisticsPtrs + $M.MUSIC_MANAGER.STATUS.CODEC_FS_OFFSET + 5;
   r10 = 8;
   do update_codec_stars;
      r4 = M[I2, 1];
      M[I6, 1] = r4;
   update_codec_stars:
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//   $fade_out_buffer
// DESCRIPTION:
//   utility function, to apply a fade out on the remaining samples in a buffer
//
// INPUT:
//    r3 = input cbuffer
// *****************************************************************************
.MODULE $M.fade_out_buffer;
   .CODESEGMENT FADE_OUT_BUFFER_PM;
   .DATASEGMENT DM;

$fade_out_buffer:
   // push rLink onto stack
   $push_rLink_macro;
   #define pi 3.1415926535897931
   .VAR coefs[] = cos(2*pi/4.0/16),  cos(2*pi/4.0/32),  cos(2*pi/4.0/48),  cos(2*pi/4.0/64),
                  cos(2*pi/4.0/80),  cos(2*pi/4.0/96),  cos(2*pi/4.0/112), cos(2*pi/4.0/128),
                  cos(2*pi/4.0/144), cos(2*pi/4.0/160), cos(2*pi/4.0/176), cos(2*pi/4.0/192),
                  cos(2*pi/4.0/208), cos(2*pi/4.0/224), cos(2*pi/4.0/240), cos(2*pi/4.0/256);

   // see how much data is available for fading out
   r0 = r3;
   call $cbuffer.calc_amount_data;
   r4 = r0;

   r0 = r3;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   // maximum 256 samples to fade
   r2 = r4 LSHIFT -4;
   r1 = r2 - 15;
   if POS r2 = r2 - r1;
   r0 = r4 - 256;
   if POS r4 = r4 - r0;
   r10 = r4;
   if Z jump end_fade;

   M0 = Null - r4;
   r0 = M[I4,M0];

   // get the filter coef (c)
   r2 = M[r2 + coefs];
   r3 = 1.0;
   rMAC = r3;
   r0 = r2;
   r1 = M[I4,0];

   do fade_loop;
       // apply fading
       r4 = rMAC * rMAC (frac);
       r1 = r1 * r4 (frac);
       // calculate next sample fading coeff
       // alpha[n] = 2*alpha[n-1]*c - alpha[n-2]
       r4 = rMAC;
       rMAC = rMAC * r2,  M[I4,1] = r1;
       rMAC = rMAC + rMAC*r3;
       rMAC = rMAC - r0*r3, r1 = M[I4,0];
       r0 = r4;
    fade_loop:

   end_fade:
   L4 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//   $spdif_codec_change_master_reset
// DESCRIPTION:
//   external reset function when codec is changed in the spdif stream, or
//   switch betweeen PCM and coded data happens
//
// *****************************************************************************
.MODULE $M.spdif_codec_change_master_reset;
   .CODESEGMENT SPDIF_CODEC_CHANGE_MASTER_RESET_PM;
   .DATASEGMENT DM;

$spdif_codec_change_master_reset:

   // push rLink onto stack
   $push_rLink_macro;

   // block interrupts
   call $block_interrupts;

   // fade out left buffer
   r3 = $audio_out_left_cbuffer_struc;
   call $fade_out_buffer;

   // fade out right buffer
   r3 = $audio_out_right_cbuffer_struc;
   call $fade_out_buffer;

   // fade out lfe buffer
   r3 = $audio_out_lfe_cbuffer_struc;
   call $fade_out_buffer;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//   $spdif_apply_realtime_config
// DESCRIPTION:
//  Not all spdif config parameters can change on the fly, at the moment only
//  target latency and supported codecs.
//
// Inputs:
//    r1: bit 7:0  -> Supported codec types
//        bit 15:8 ->  target latency in ms
//    r2: ac3 config word 1
//    r3: ac3 config word 2
// Outputs:
//    None
//
// *****************************************************************************
.MODULE $M.spdif_apply_realtime_config;
   .CODESEGMENT SPDIF_APPLY_REALTIME_CONFIG_PM;
   .DATASEGMENT DM;

$spdif_apply_realtime_config:

   // push rLink onto stack
   $push_rLink_macro;

   // extract target latency
   r0 = r1 LSHIFT -8;
   r0 = r0 AND 0xFF;
   M[$spdif_target_latency_setting] = r0;

   // set the supported data types
   r5 = 0;
   #ifdef AC3_ENABLE
      // Enable AC-3 data type if requested by VM
      r0 = $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_AC3);
      Null = r1 AND 1;
      if NZ r5 = r5 OR r0;
   #endif
   #ifdef AAC_ENABLE
      // Enable MPEG2 AAC data type if requested by VM
      r0 = $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_MPEG2_AAC);
      Null = r1 AND 2;
      if NZ r5 = r5 OR r0;
   #endif
   #ifdef MP3_ENABLE
      // Enable MP3(MPEG1 Layer3 only) data type if requested by VM
      r0 = $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_MPEG1_LAYER23);
      Null = r1 AND 4;
      if NZ r5 = r5 OR r0;
   #endif
   M[$spdif_copy_struct + $spdif.frame_copy.SUPPORTED_CODEC_TYPES_BITS_FIELD] = r5;

#ifdef AC3_ENABLE
   // configure AC3 decoder
   r1 = r2;
   r2 = r3;
   call $config_ac3_decoder_message_handler;
#endif

   // update spdif config word for UFE
   call $spdif_update_config_word;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//   $spdif_update_stat_word
// DESCRIPTION:
//  SPDIF status is sent compressed to UFE, this function builds
//  the stat word
//
// INPUTS:
//    None
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS
//   r0, r1
// *****************************************************************************
.MODULE $M.spdif_update_stat_word;
   .CODESEGMENT SPDIF_UPDATE_STAT_WORD_PM;
   .DATASEGMENT DM;

$spdif_update_stat_word:

   // valid flag b0, 0 -> valid, 1 -> invalid
   r1 = M[$spdif_copy_struct + $spdif.frame_copy.STREAM_INVALID_FIELD];
   r1 = r1 AND 1;

   // data type, bit 7:1
   r0 = M[$spdif_stream_decode_struct + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD];
   r0 = r0 AND 0x7F;
   r0 = r0 LSHIFT 1;
   r1 = r1 OR r0;

   // current latency in ms, bit 15:8
   r0 = M[$encoded_latency_struct + $encoded_latency.TOTAL_LATENCY_US_FIELD];
   r0 = r0 * 0.001(frac);
   r0 = r0 AND 0xFF;
   r0 = r0 LSHIFT 8;
   r1 = r1 OR r0;

   // channel status, bit 23:16
   r0 = M[$spdif_copy_struct + $spdif.frame_copy.CHSTS_FIRST_WORD_FIELD];
   r2 = r0 LSHIFT -8;
   r2 = r2 AND 0x80;
   r0 = r0 AND 0x7F;
   r0 = r0 OR r2;
   r0 = r0 LSHIFT 16;
   r1 = r1 OR r0;

   // save stat
   M[$spdif_stat_word] = r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//   $spdif_update_config_word
// DESCRIPTION:
//  SPDIF config is sent compressed to UFE, this function builds
//  the config word
//
// INPUTS:
//    None
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS
//   r0, r1
// *****************************************************************************
.MODULE $M.spdif_update_config_word;
   .CODESEGMENT SPDIF_UPDATE_CONFIG_WORD_PM;
   .DATASEGMENT DM;

$spdif_update_config_word:

   // target latency
   r0 = M[$spdif_target_latency_setting];
   r0 = r0 LSHIFT 8;

   // set the supported data types
   r2 = M[$spdif_copy_struct + $spdif.frame_copy.SUPPORTED_CODEC_TYPES_BITS_FIELD];
   #ifdef AC3_ENABLE
      // see if AC-3 enabled
      r1 = 1;
      Null = r2 AND $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_AC3);
      if NZ r0 = r0 OR r1;
   #endif

   #ifdef AAC_ENABLE
      // see if AAC enabled
      r1 = 2;
      Null = r2 AND $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_MPEG2_AAC);
      if NZ r0 = r0 OR r1;
   #endif

   #ifdef MP3_ENABLE
      // see if MP3 enabled
      r1 = 4;
      Null = r2 AND $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_MPEG1_LAYER23);
      if NZ r0 = r0 OR r1;
   #endif

   // update config word
   M[$spdif_config_word] = r0;
   rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//   $config_spdif_sink_message_handler
// DESCRIPTION:
//   handling of VM_CONFIG_SPDIF_APP_MESSAGE message received from VM
//
// INPUTS:
//    r1 = config word 0
//         bit0      -> enable AC-3 data type support
//         bit1      -> enable MPEG2 AAC data type support
//         bit2      -> enable MP3 data type support
//         bits 3:4  -> reserved for future more data type support
//         bits 5:6  -> output interface type
//                      0 -> none
//                      1 -> DAC
//                      2 -> spdif
//                      3 -> I2S
//         bit 7     -> fix output rate
//                      0 -> output rate follows input rate
//                      1 -> output rate always set at 48KHz
//         bit 8:15  -> desired latency in ms
//
//    r2 = config word 1
//         bit0      -> if set, vm will receive DSP_SPDIF_EVENT_MESSAGE
//                      whenever an interesting event happens, interesting
//                      events are:
//                         - spdif becomes active
//                         - spdif becomes inactive
//                         - data type of spdif stream changes
//                         - sample rate of spdif stream changes
//                       other changes wont trig an event
//
//         bit 1:7:  -> delay time for reporting invalid stream (in seconds)
//         bit 8:    -> if set means disable rate matching
//
//   r3 = config word 2 (reserved)
//   r4 = config word 3 (reserved)
//
//  OUTPUTS:
//     None
//
// TRASHED REGISTERS:
//    Assume everything
//
// *****************************************************************************
.MODULE $M.config_spdif_sink_message_handler;
   .CODESEGMENT CONFIG_SPDIF_SINK_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

$config_spdif_sink_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   r1 = r1 AND 0xFFFF;

   // set the supported data types
   r5 = 0;
   #ifdef AC3_ENABLE
      // Enable AC-3 data type if requested by VM
      r0 = $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_AC3);
      Null = r1 AND 1;
      if NZ r5 = r5 OR r0;
   #endif
   #ifdef AAC_ENABLE
      // Enable AC-3 data type if requested by VM
      r0 = $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_MPEG2_AAC);
      Null = r1 AND 2;
      if NZ r5 = r5 OR r0;
   #endif
   #ifdef MP3_ENABLE
      // Enable MP3(MPEG1 Layer3 only) data type if requested by VM
      r0 = $spdif.DATA_TYPE_SUPPORT($spdif.IEC_61937_DATA_TYPE_MPEG1_LAYER23);
      Null = r1 AND 4;
      if NZ r5 = r5 OR r0;
   #endif
   M[$spdif_copy_struct + $spdif.frame_copy.SUPPORTED_CODEC_TYPES_BITS_FIELD] = r5;

   // extract output interface type
   r0 = r1 AND 0x60;
   r0 = r0 LSHIFT -5;
   M[$spdif_stream_decode_struct + $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_FIELD] = r0;
   M[$audio_if_mode] = r0;

   // set the output rate
   r0 = 48000;
   Null = r1 AND 0x80;
   if Z r0 = 0;
   M[$spdif_stream_decode_struct + $spdif.stream_decode.OUTPUT_INTERFACE_SETTING_RATE_FIELD] = r0;

   // set the latency level
   r0 = r1 LSHIFT -8;
   M[$spdif_target_latency_setting] = r0;

   // Enable/Disable event reporting
   r0 = r2 AND 1;
   M[$spdif_copy_struct + $spdif.frame_copy.ENABLE_EVENT_REPORT_FIELD] = r0;

   // invalid message postpone time
   r0 = r2 LSHIFT -1;
   r0 = r0 AND 0x3F;
   M[$spdif_copy_struct + $spdif.frame_copy.INVALID_MESSAGE_POSTPONE_TIME_FIELD] = r0;

   // invalid message postpone time
   r0 = r2 LSHIFT -8;
   r0 = r0 AND 0x1;
   M[$rate_match_disable] = r0;

   // A SPDIF config message means spdif mode
   r0 = $SPDIF_IO;
   M[$app_config.io] = r0;

   // Initialise the statistics pointer table
   I0 = $spdif_stats;
   call $copy_codec_stats_pointers;

#ifdef OUTPUT_INTERFACE_INIT_ACTIVE
   // output interface initially is active at 48khz
   r0 = 1;
   M[$spdif_stream_decode_struct + $spdif.stream_decode.OUTPUT_INTERFACE_INIT_ACTIVE_FIELD] = r0;
#endif

   // see if it's mono or stereo
   r0 = $AUDIO_RIGHT_OUT_PORT;
   r1 = r0;
   call $cbuffer.is_it_enabled;
   if Z r1 = 0;
   M[$spdif_stream_decode_struct + $spdif.stream_decode.OUTPUT_INTERFACE_RIGHT_PORT_FIELD] = r1;

   // update spdif config word for UFE
   call $spdif_update_config_word;

   // init library
   r5 = $spdif_stream_decode_struct;
   call $spdif.init;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#ifdef AC3_ENABLE
// *****************************************************************************
// MODULE:
//   $config_ac3_decoder_message_handler
// DESCRIPTION:
//   configures ac-3 decoder
//
// INPUTS:
//Word1 and Word2
//- cut and boost: each 7 bits
//- stereo mixing mode 2bit
//
//- channel routing 6bit
//- lfe on/off 1bit
//- karaoke mode 2
//- dual mode 2bit
//- compression mode 2bit
//- output mode 1bit
//
// handling of VM_CONFIG_SPDIF_APP_MESSAGE message received from VM
//    r1 = config word 0
//         bits 0:6    -> cut compression ratio
//            cut = (val/100.0)
//         bits 7:13    -> boost compression ratio
//            boost = (val/100.0)
//         bits 14:15   -> compression mode
//            0 -> custom 1
//            1 -> custom 2
//            2 -> line out
//            3 -> rf
//
//    r2 = config word 1
//         bit 0      -> lef output on/off flag
//         bit 1      -> karaoke on/off flag
//         bits 2:3   -> dual mono mode bit
//            0 -> stereo
//            1 -> left only
//            2 -> right only
//            3 -> mix//
//         bits 4:10  -> channel routing info
//           bit 4:  enable channel routing
//           bit 5:7 channel to be routed to left
//           bit 8:10 channel to be routed to right
//         bits 11:12   -> stereo mixing mode
//            0 -> auto mixing mode
//            1 -> Lt/Rt mixing mode
//            2 -> Lo/Ro mixing mode
//            3 -> reserved
//         bit 13   -> output mode
//            0 -> 2/0
//            1 -> multi channel (not supported in ADK3.0)
//
//         bits 14:15 -> unused
//
//   r3 = config word 2 (reserved)
//   r4 = config word 3 (reserved)
//
//  OUTPUTS:
//     None
//
// TRASHED REGISTERS:
//    Assume everything
//
// *****************************************************************************
.MODULE $M.config_ac3_decoder_message_handler;
   .CODESEGMENT CONFIG_AC3_DECODER_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

$config_ac3_decoder_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // save config words
   M[$ac3dec_config_words + 0] = r1;
   M[$ac3dec_config_words + 1] = r2;

   // compression cut scale
   r0 = r1 AND 0x7F;
   rMAC = r0 * 0.64;
   rMAC = rMAC ASHIFT 17 (56bit);
   M[$ac3dec_user_config + $ac3dec.config.COMP_CUT_SCALE_FIELD] = rMAC;

   // compression boost scale
   r0 = r1 LSHIFT -7;
   r0 = r0 AND 0x7F;
   rMAC = r0 * 0.64;
   rMAC = rMAC ASHIFT 17 (56bit);
   M[$ac3dec_user_config + $ac3dec.config.COMP_BOOST_SCALE_FIELD] = rMAC;

   // compression mode
   r0 = r1 LSHIFT -14;
   r0 = r0 AND 0x3;
   M[$ac3dec_user_config + $ac3dec.config.COMPRESSION_MODE_FIELD] = r0;

   // lfe mode
   r0 = 0;
   r1 = $audio_out_lfe_cbuffer_struc;
   Null = r2 AND 1;
   if NZ r0 = r1;
   M[$ac3dec_user_config + $ac3dec.config.DECODER_OUT_LFE_BUFFER_FIELD] = r0;

   // dual mono bits
   r0 = r2 LSHIFT -2;
   r0 = r0 AND 0x3;
   M[$ac3dec_user_config + $ac3dec.config.DUAL_MODE_FIELD] = r0;

   // channel routing
   r1 =	1<<23;
   r0 = r2 LSHIFT -5;
   r0 = r0 AND 0x3F;
   Null = r2 AND (1<<4);
   if Z r0 = 0;
   if NZ r0 = r0 OR r1;
   M[$ac3dec_user_config + $ac3dec.config.ROUTE_CHANNELS_FIELD] = r0;

   // stereo mixing mode
   r0 = r2 LSHIFT -11;
   r0 = r0 AND 0x3;
   M[$ac3dec_user_config + $ac3dec.config.STEREO_MODE_FIELD] = r0;

   // output mode
   r0 = $ac3dec.ACMOD_20;
   r5 = $ac3dec.ACMOD_32;
   Null = r2 AND (0x2000);
   if NZ r0 = r5;
   M[$ac3dec_user_config + $ac3dec.config.OUTPUT_MODE_FIELD] = r0;

   // enable reconfiguring the decoder
   r0 = 1;
   M[$ac3dec_reconfig_needed] = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//   $ac3_user_info_request_message_handler
// DESCRIPTION:
//   handle request for ac-3 user info
//
// INPUTS:
//    None
//  OUTPUTS:
//     None
//
// TRASHED REGISTERS:
//    Assume everything
//
// *****************************************************************************
.MODULE $M.ac3_user_info_request_message_handler;
   .CODESEGMENT AC3_USER_INFO_REQUEST_MESSAGE_HANDLER_PM;
   .DATASEGMENT DM;

$ac3_user_info_request_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // send ac-3 user info to vm
   r3 = AC3_USER_INFO_MSG;
   r4 = length($ac3dec_user_info_struct);
   r5 = $ac3dec_user_info_struct;
   call $message.send_long;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif

// *****************************************************************************
// MODULE:
//    $spdif_sra.calc_rate
//
// DESCRIPTION:
//   calculate the mismatch between the input SPDIF interface and the
//   output interface, the result is used to perform rate matching between
//   source and sink devices.
//
// INPUTS:
//   r7 = amount of new data copied from spdif ports
//
// OUTPUTS:
//   None
//
// TRASHED REGISTERS:
//    assume everything
//
//  NOTE:
//   mismatch rate is calculated based on the average flow of data received
//   from spdif input interface compared the sampling rate. It assumes the
//   consumer clock is synchronised to local clock.
//
//   It also adds a fixing value to mismatch rate in order to keep the latency
//   of the system close to a target level. The fixing value is only temprarily
//   and should converge to zero when the target latency is achived.
// *****************************************************************************
.MODULE $M.spdif_sra_calc_rate;
   .CODESEGMENT SPDIF_SRA_CALC_RATE_PM;
   .DATASEGMENT DM;

   $spdif_sra.calc_rate:

   // push rLink onto stack
   $push_rLink_macro;

   // r8 = input structure
   r8 = &$spdif_sra_struct;

   // when stream is invalid no further data is received
   Null = M[$spdif_copy_struct + $spdif.frame_copy.STREAM_INVALID_FIELD];
   if Z jump calc_sra_rate;

   // reset sra hist
   M[r8 + $spdif_sra.RATE_BEFORE_FIX_FIELD] = 0;

   // gradually reset the fix rate
   r1 = M[r8 + $spdif_sra.FIX_RATE_FIELD];
   r1 = r1 ASHIFT -1;
   M[r8 + $spdif_sra.FIX_RATE_FIELD] = r1;
   jump rate_calc_done;

   calc_sra_rate:

   // calc the average latency
   r4 = M[r8 + $spdif_sra.CURRENT_LATENCY_PTR_FIELD];
   r1 = M[r8 + $spdif_sra.AVERAGE_LATENCY_FIELD];
   r4 = M[r4];
   rMAC = r4 * 0.3;
   rMAC = rMAC + r1*0.7;
   M[r8 + $spdif_sra.AVERAGE_LATENCY_FIELD] = rMAC;

   // see how far latency can be increased
   r0 = $spdif_in_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   r2 = M[$spdif_copy_struct + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD];
   rMAC = r0 * r2;
   rMAC = rMAC ASHIFT 6;
   r0 = rMAC;

   // r0 = latency left in the input buffer
   // do an averaging
   r1 = M[r8 + $spdif_sra.AVERAGE_LATENCY_LEFT_FIELD];
   r2 = 0.99;     // fast track for low space
   r3 = 0.01;     // slow track for high space
   Null = r1 - r0;
   if POS r3 = r2;
   r2 = 1.0 - r3;
   rMAC = r0 * r3;
   rMAC = rMAC + r1*r2;
   M[r8 + $spdif_sra.AVERAGE_LATENCY_LEFT_FIELD] = rMAC;

   // set the target latency
   // modified target latency =
   //     min (requested_target_letency,
   //          current_latency + space_left - 10ms)
   //
   r0 = M[r8 + $spdif_sra.AVERAGE_LATENCY_FIELD];
   r0 = r0 + rMAC;
   r4 = r0 - 10000;
   r3 = M[r8 + $spdif_sra.TARGET_LATENCY_MS_FIELD];
   r3 = r3 * 1000 (int);
   Null = r3 - r4;
   if POS r3 = r4;

   // r3 = modified target latency
   rMAC = M[r8 + $spdif_sra.AVERAGE_LATENCY_FIELD];
   r0 = r3 - rMAC;

   // stop fixing the rate if the latency is very
   // close to the target
   r2 = ABS r0;

   // scale, how fast we want to fix it
   r0 = r0 * 200 (int)(sat);
   r0 = r0 ASHIFT -1;

   NULL = M[r8 + $spdif_sra.LATENCY_CONVERGED_FIELD];
   if Z jump not_converged;
   converged:
      // see if exited the convergence outer limits
      Null = r2 - (SPDIF_LATENCY_CONVERGE_US*3);
      if POS jump not_converged;
      r0 = r0 * 5 (int);
      r6 = r0 * r0 (frac);
      r0 = r0 * r6 (frac);
      r2 = 1;
      M[r8 + $spdif_sra.LATENCY_CONVERGED_FIELD] = r2;
      jump converge_check_done;

   not_converged:
      // see if entered converged inner limits
      Null = r2 - SPDIF_LATENCY_CONVERGE_US;
      if NEG jump converged;
      r6 = r0 ASHIFT 24;
      r0 = r0 * r0(frac);
      r0 = r0 * r6(frac);
      M[r8 + $spdif_sra.LATENCY_CONVERGED_FIELD] = 0;
   converge_check_done:

   // limit fixing range,
   // capped at compensation for max 10ms diff
   r1 = r0 - 0.01;
   if POS r0 = r0 - r1;
   r1 = r0 + 0.01;
   if NEG r0 = r0 - r1;

   // get current fixing value
   r1 = M[r8 + $spdif_sra.FIX_RATE_FIELD];

   // r0 = new fixing value
   // r1 = old fixing value
   // move slightly towards new value
   r4 = r0 - r1;
   r4 = r4 *(1.0/32)(frac);
   r1 = r1 + r4;
   Null = r4;
   if Z r1 = r0;
   M[r8 + $spdif_sra.FIX_RATE_FIELD] = r1;

   // mismatch-rate = 1.0 - measured_rate/expected_rate;
   r0 = M[$spdif_copy_struct + $spdif.frame_copy.MEASURED_SAMPLING_FREQ_FIELD];
   rMAC = M[$spdif_copy_struct + $spdif.frame_copy.SAMPLING_FREQ_FIELD];
   rMAC = rMAC - r0;
   r0 = M[$spdif_copy_struct + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD];
   rMAC = rMAC * r0;
   rMAC = rMAC ASHIFT 15 (56bit);
   r0 = rMAC * 0.524288(frac);
   r4 = M[r8 + $spdif_sra.RATE_BEFORE_FIX_FIELD];
   rMAC = r0 * 0.005;
   rMAC = rMAC + r4*0.995;
   M[r8 + $spdif_sra.RATE_BEFORE_FIX_FIELD] = rMAC;

   rate_calc_done:
   // get the mismatch rate
   r4 = M[r8 + $spdif_sra.RATE_BEFORE_FIX_FIELD];
   r4 = r4 * (1/16.0)(frac);

   // add previously computed fixing value
   r3 = M[r8 + $spdif_sra.FIX_RATE_FIELD];
   r4 = r4 + r3;

   // limit max and min mismatch rate to compensate
   r0 = M[r8 + $spdif_sra.MAX_RATE_FIELD];
   r3 = r4 - r0;
   if POS r4 = r4 - r3;
   r3 = r4 + r0;
   if NEG r4 = r4 - r3;

   // store mismatch value, this will be used by rate matching module
   M[r8 + $spdif_sra.SRA_RATE_FIELD] = r4;


   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $adjust_initial_latency
//
// DESCRIPTION:
//    adjusts the initial latency
// ******************************************************************************
.MODULE $M.adjust_initial_latency;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $adjust_initial_latency:

   // define dummy silence buffers
   .VAR/DMCIRC $dac_sil_left[5];
   .VAR/DMCIRC $dac_sil_right[5];

   // define silence cbuffer stuctures
   .VAR $dac_sil_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($dac_sil_left),              // size
      &$dac_sil_left,                     // read pointer
      &$dac_sil_left;                     // write pointer
   .VAR $dac_sil_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($dac_sil_right),              // size
      &$dac_sil_right,                     // read pointer
      &$dac_sil_right;                     // write pointer

   // define silence copy structure for stereo mode
   .VAR $stereo_sil_out_copy_struc[] =
      &$audio_out_tone_upsample_stereo_mix, // first operator block
      2,                                    // number of inputs
      &$dac_sil_left_cbuffer_struc,         // input
      &$dac_sil_right_cbuffer_struc,        // input
      2,                                    // number of outputs
      $AUDIO_LEFT_OUT_PORT,                 // output
      $AUDIO_RIGHT_OUT_PORT;                // output

   // define silence copy structure for mono mode
   .VAR $mono_sil_out_copy_struc[] =
      &$audio_out_tone_upsample_mono_mix, // first operator block
      1,                                  // number of inputs
      &$dac_sil_left_cbuffer_struc,       // input
      1,                                  // number of outputs
      $AUDIO_LEFT_OUT_PORT;               // output

   .VAR $init_latency_state = 0;
   .VAR $init_latency_table[] = il_idle, il_wait, il_play, il_pause;
   .VAR $no_audio_counter = 0;
   .VAR $time_left_to_play;

   $push_rLink_macro;

   // jump to proper state handler
   r6 = M[$init_latency_state];
   r0 = M[$init_latency_table + r6];
   jump r0;

   il_idle:
   // idle state:
   // copy silence and
   // stay here until first packet received
   r6 = 0;
   r8 = $stereo_sil_out_copy_struc;
   r7 = $mono_sil_out_copy_struc;
   Null = M[$first_audio_received];
   if Z jump init_latency_done;

   il_wait:
   // wait state:
   // play silence and
   // wait until 'target_latency' has passed since receiving first packet
   // then go to play mode
   r6 = 1;
   r8 = $stereo_sil_out_copy_struc;
   r7 = $mono_sil_out_copy_struc;

   // if latency cannot increase any more then go to play
   r0 = $spdif_in_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - 512;
   if NEG jump il_play;

   // stay in this mode up to "target latency" time
   r0 = M[$first_audio_time];
   r1 = M[$TIMER_TIME];
   r1 = r1 - r0;
   if NEG r1 = -r1;
   // add the init offset
   r1 = r1 + M[$first_audio_init_latency_offset];
   r1 = r1 - TMR_PERIOD_AUDIO_COPY;
   r2 = M[$encoded_latency_struct + $encoded_latency.TOTAL_LATENCY_US_FIELD];
   r1 = MAX r2;
   r1 = r1 * 0.001(frac);
   r0 = M[$spdif_sra_struct + $spdif_sra.TARGET_LATENCY_MS_FIELD];
   r0 = r0 - r1;
   M[$time_left_to_play] = r0;
   if POS jump init_latency_done;
   il_play:
   // play mode:
   // play audio
   // go tpo pause mode when stream becomes invalid
   r6 = 2;
   r8 = &$stereo_out_copy_struc;
   r7 = &$mono_out_copy_struc;
   // exit play mode if the input has become invalide
   M[$no_audio_counter] = 0;
   Null = M[$spdif_copy_struct + $spdif.frame_copy.STREAM_INVALID_FIELD];
   if Z jump init_latency_done;
   M[$first_audio_received] = 0;

   il_pause:
   // pause mode:
   // play remaining audio
   // if stall ends return back to play mode
   // if no audio to play go to idle and wait for new valid stream to arrive
   r6 = 3;
   r8 = &$stereo_out_copy_struc;
   r7 = &$mono_out_copy_struc;

   // return to playing if stream becomes valid
   Null = M[$spdif_copy_struct + $spdif.frame_copy.STREAM_INVALID_FIELD];
   if Z jump il_play;

   // see if the final buffer is almost empty
   r0 = &$dac_out_temp_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r1 = M[$no_audio_counter];
   r1 = r1 + 1;
   Null = r0 - 2;
   if POS r1 = 0;
   M[$no_audio_counter] = r1;
   Null = r1 - 2;
   if NEG jump init_latency_done;

   // no audio to play,
   // clear input buffers
   // and go idle
   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.empty_buffer;
   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.empty_buffer;
   r0 = &$audio_out_lfe_cbuffer_struc;
   call $cbuffer.empty_buffer;
   jump il_idle;

   init_latency_done:
   // set audio or silence buffer to play
   M[$stereo_copy_struc_ptr] = r8;
   M[$mono_copy_struc_ptr] = r7;
   M[$init_latency_state] = r6;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.ENDMODULE;
