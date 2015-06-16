// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2003)        http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    Encoder & Decoder for a gaming headset
//
// aptX low latency sink application with optional back channel.
// It expects the following parameters to work properly:
// Music Sampling rate : 44100 or 48000Hz from codec, 44100 or 48000Hz at DAC/I2S
// Voice Sampling rate: 16000Hz to codec, 44100 or 48000Hz at ADC/I2S
// The ADC rate (I2S in) and DAC rate (I2S out) must be the same.
//
// Music is stereo aptX low latency (32ms)
// Voice is WBS/mSBC with parameters: bitpool=32, subbands=8, blocks=16, loudness and mono mode
//
// *****************************************************************************
#define DEBUG_STATSx

// includes
#include "frame_sync_library.h"
#include "music_example.h"
#include "spi_comm_library.h"
#include "mips_profile.h"
#include "sr_adjustment_gaming.h"
#include "codec_library.h"
#include "codec_decoder_aptx_acl_sprint.h"
#include "audio_proc_library.h"


// unused, but 'mute_direction' is referenced in vm_message.asm
.module $M.downsample_sub_to_1k2;
    .datasegment dm;
    .var mute_direction = 0;
.endmodule;

// Run-time control of configuration
.MODULE $app_config;
   .DATASEGMENT DM;

// Plugin type set from VM at run-time
   .VAR io = $INVALID_IO;                                                  // Control app i/o
.ENDMODULE;

// includes
#include "core_library.h"
#include "cbops_library.h"
#include "codec_library.h"


#include "sbc_library.h"

.MODULE $M.main;
   .CODESEGMENT MAIN_PM;
   .DATASEGMENT DM;

   $main:

   // ** allocate memory for cbuffers **
   .VAR/DMCIRC $audio_out_left[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_out_right[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out_left[$OUTPUT_AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out_right[$OUTPUT_AUDIO_CBUFFER_SIZE];
   // Codec in data buffer
   .VAR/DMCIRC $codec_in[CODEC_CBUFFER_SIZE];

   .VAR/DMCIRC $audio_in_mono[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $codec_out[CODEC_CBUFFER_SIZE];

   // Tone/Prompt data buffers, $tone_in_right
   // is used for stereo voice prompts
   .VAR/DM1CIRC $tone_in[TONE_BUFFER_SIZE];
   .VAR/DM1CIRC $tone_in_right[TONE_BUFFER_SIZE];

   // Variables to receive dac and codec sampling rates from the vm
   .VAR $current_dac_sampling_rate = 0;                            // Dac sample rate, set by message from VM
   .VAR $set_dac_rate_from_vm_message_struc[$message.STRUC_SIZE];  // Message structure for VM_SET_DAC_RATE_MESSAGE_ID message
   .VAR $current_codec_sampling_rate = 0;                          // codec data sample rate, set by vm
   .VAR $set_codec_rate_from_vm_message_struc[$message.STRUC_SIZE];// Message structure for VM_SET_CODEC_RATE_MESSAGE_ID message
   .VAR $set_tone_rate_from_vm_message_struc[$message.STRUC_SIZE]; // Message structure for VM_SET_TONE_RATE_MESSAGE_ID message
   .VAR $current_tone_sampling_rate = 8000;                        // input tone/prompt sample rate, set by VM before tone starts
   .VAR $stereo_tone;                                              // flag showing input tone/prompt is stereo
   .VAR $current_adc_sampling_rate = 0;                            // Initially zero - set by message from VM ***
   .VAR $current_voice_codec_sampling_rate = 0;
   .VAR $get_aptx_ll_params_from_vm_message_struc1[$message.STRUC_SIZE];
   .VAR $get_aptx_ll_params_from_vm_message_struc2[$message.STRUC_SIZE];

   // Rate matching control variables
   .VAR $local_play_back;
   .VAR $audio_if_mode; // output interface type
   .VAR $max_clock_mismatch;
   .VAR $long_term_mismatch;
   .VAR $aux_input_stream_available;       // local pcm file is being mixed

   // ** allocate memory for cbuffer structures **

   // Codec in cbuffer
   .VAR $codec_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($codec_in),              // size
         &$codec_in,                     // read pointer
         &$codec_in;                     // write pointer


   .VAR $audio_out_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_left),        // size
         &$audio_out_left,               // read pointer
         &$audio_out_left;               // write pointer
   .VAR $audio_out_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_out_right),       // size
         &$audio_out_right,              // read pointer
         &$audio_out_right;              // write pointer
   .VAR $dac_out_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($dac_out_left),          // size
         &$dac_out_left,                 // read pointer
         &$dac_out_left;                 // write pointer
   .VAR $dac_out_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($dac_out_right),         // size
         &$dac_out_right,                // read pointer
         &$dac_out_right;                // write pointer
   .VAR $tone_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($tone_in),               // size
         &$tone_in,                      // read pointer
         &$tone_in;                      // write pointer
   // used for stereo tones
   .VAR $tone_in_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($tone_in_right),               // size
         &$tone_in_right,                      // read pointer
         &$tone_in_right;                      // write pointer

   .VAR $audio_in_mono_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($audio_in_mono),         // size
         &$audio_in_mono,                // read pointer
         &$audio_in_mono;                // write pointer
   .VAR $codec_out_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($codec_out),             // size
         &$codec_out,                    // read pointer
         &$codec_out;                    // write pointer


   // ** allocate memory for timer structures **
   .VAR $codec_timer_struc[$timer.STRUC_SIZE];
   .VAR $audio_out_timer_struc[$timer.STRUC_SIZE];
   .VAR $audio_in_timer_struc[$timer.STRUC_SIZE];
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
         1,                         // Output 0 index
         2,                         // output 1 index
         8;                         // and 8 bits to convert from 16-bit to 24-bit
   .ENDBLOCK;

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


   // ** allocate memory for codec cbops copy routine **
   .VAR $codec_out_copy_struc[] =
      &$codec_out_copy_op,                // first operator block
      1,                                  // number of inputs
      &$codec_out_cbuffer_struc,          // input
      1,                                  // number of outputs
      $CODEC_OUT_PORT;                    // output

   .BLOCK $codec_out_copy_op;
      .VAR $codec_out_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $codec_out_copy_op.func = &$cbops.copy_op;
      .VAR $codec_out_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
               0,                         // Input index
               1;                         // Output index
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

  .VAR $stereo_out_no_resampler_copy_struc[] =
      &$audio_out_tone_upsample_stereo_mix, // first operator block
      2,                                    // number of inputs
      &$dac_out_left_cbuffer_struc,    // input
      &$dac_out_right_cbuffer_struc,   // input
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

#if !defined(HARDWARE_RATE_MATCH)
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
      .VAR rm_stereo_switch_op.next = &$audio_out_rate_adjustment_and_shift_op_stereo;
      .VAR rm_stereo_switch_op.func = $cbops.switch_op;
      .VAR rm_stereo_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
         $rate_match_disable,                   // Pointer to switch (non-zero selects resampler)
         $audio_out_dither_and_shift_op_left,   // ALT_NEXT_FIELD, pointer to alternate cbops chain
         0,                                     // SWITCH_MASK_FIELD
         $cbops.switch_op.INVERT_CONTROL;       // INVERT_CONTROL_FIELD
   .ENDBLOCK;

   .VAR/DM1CIRC $sr_hist_left[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];
   .VAR/DM1CIRC $sr_hist_right[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];

   .BLOCK $audio_out_rate_adjustment_and_shift_op_stereo;
      .VAR $audio_out_rate_adjustment_and_shift_op_stereo.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_rate_adjustment_and_shift_op_stereo.func = &$cbops.rate_adjustment_and_shift;
      .VAR $audio_out_rate_adjustment_and_shift_op_stereo.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
      0,  //   INPUT1_START_INDEX_FIELD
      2,  //   OUTPUT1_START_INDEX_FIELD
      1,  //   INPUT2_START_INDEX_FIELD
      3,  //   OUTPUT2_START_INDEX_FIELD
      -8, //   SHIFT_AMOUNT_FIELD
      &$sra_coeffs,
      &$sr_hist_left,
      &$sr_hist_right,
      &$sra_struct + $sra.SRA_RATE_FIELD,
      $cbops.dither_and_shift.DITHER_TYPE_NONE, //    DITHER_TYPE_FIELD
      0 ...;                                    // Pad out remaining items with zeros
    .ENDBLOCK;
#else
   // *** Hardware rate-match ***
   .BLOCK $audio_out_dc_remove_op_right;
      .VAR audio_out_dc_remove_op_right.next = &$audio_out_dither_and_shift_op_left;
      .VAR audio_out_dc_remove_op_right.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_right.param[$cbops.dc_remove.STRUC_SIZE] =
         1,                                 // Input index (right cbuffer)
         1,                                 // Output index (right cbuffer)
         0;                                 // DC estimate field
   .ENDBLOCK;
#endif

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
      &$audio_out_mix_op,                          // first operator block
      2,                                           // number of inputs
      &$dac_out_temp_left_cbuffer_struc,           // input
      &$dac_out_temp_right_cbuffer_struc,          // input
      1,                                           // number of outputs
      $AUDIO_LEFT_OUT_PORT;                        // output

   .VAR $mono_out_no_resampler_copy_struc[] =
      &$audio_out_mix_op,                          // first operator block
      2,                                           // number of inputs
      &$dac_out_left_cbuffer_struc,                // input
      &$dac_out_right_cbuffer_struc,               // input
      1,                                           // number of outputs
      $AUDIO_LEFT_OUT_PORT;                        // output
   .BLOCK $audio_out_mix_op;
      .VAR $audio_out_mix_op.next = &$audio_out_tone_upsample_mono_mix;
      .VAR $audio_out_mix_op.func = &$cbops.cross_mix;
      .VAR $audio_out_mix_op.param[$cbops.cross_mix.STRUC_SIZE] =
            0,                            // Input index (left)
            1,                            // Input index (right)
            0,                            // output left
            -1,                           // output right
            0.5,                          // Left gain
            0.5,                          // Right gain
            0 ...;
   .ENDBLOCK;

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
    
#if !defined(HARDWARE_RATE_MATCH)
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
      .VAR rm_mono_switch_op.next = $audio_out_rate_adjustment_and_shift_op_mono;
      .VAR rm_mono_switch_op.func = $cbops.switch_op;
      .VAR rm_mono_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
         $rate_match_disable,                   // Pointer to switch (non-zero selects resampler)
         $audio_out_dither_and_shift_op_mono,   // ALT_NEXT_FIELD, pointer to alternate cbops chain
         0,                                     // SWITCH_MASK_FIELD
         $cbops.switch_op.INVERT_CONTROL;       // INVERT_CONTROL_FIELD
   .ENDBLOCK;

   .BLOCK $audio_out_rate_adjustment_and_shift_op_mono;
      .VAR $audio_out_rate_adjustment_and_shift_op_mono.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_rate_adjustment_and_shift_op_mono.func = &$cbops.rate_adjustment_and_shift;
      .VAR $audio_out_rate_adjustment_and_shift_op_mono.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
      0,  //INPUT1_START_INDEX_FIELD
      2,  //   OUTPUT1_START_INDEX_FIELD
      -1, //   INPUT2_START_INDEX_FIELD
      -1, //   OUTPUT2_START_INDEX_FIELD
      -8, //   SHIFT_AMOUNT_FIELD
      &$sra_coeffs,
      &$sr_hist_left,
      0,
      &$sra_struct + $sra.SRA_RATE_FIELD,
      $cbops.dither_and_shift.DITHER_TYPE_NONE,  //   DITHER_TYPE_FIELD
      0 ...;                           // Pad out remaining items with zeros
    .ENDBLOCK;
#else
   // *** Hardware rate-match ***
   .BLOCK $audio_out_dc_remove_op_mono;
      .VAR audio_out_dc_remove_op_mono.next = &$audio_out_dither_and_shift_op_mono;
      .VAR audio_out_dc_remove_op_mono.func = &$cbops.dc_remove;
      .VAR audio_out_dc_remove_op_mono.param[$cbops.dc_remove.STRUC_SIZE] =
         0,                               // Input index
         0,                               // Output index
         0;                               // DC estimate field
   .ENDBLOCK;
#endif

   .BLOCK $audio_out_dither_and_shift_op_mono;
      .VAR $audio_out_dither_and_shift_op_mono.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_dither_and_shift_op_mono.func = &$cbops.dither_and_shift;
      .VAR $audio_out_dither_and_shift_op_mono.param[$cbops.dither_and_shift.STRUC_SIZE] =
         0,                                        // Input index
         2,                                        // Output index
        -8,                                        // amount of shift after dithering
         $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
         &$dither_hist_left,                       // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
         0;                                        // Enable compressor
   .ENDBLOCK;

   .VAR $voice_enabled = 1;

   // ** allocate memory for mono audio in cbops copy routine **
   .VAR $mono_audio_in_copy_struc[] =
      &$audio_in_shift_op_mono,
      1,     // number of inputs
      $AUDIO_LEFT_IN_PORT,
      1,     // number of outputs
      &$adc_in_temp_mono_cbuffer_struc;

   .BLOCK $audio_in_shift_op_mono;
      .VAR audio_in_shift_op_mono.next = &$audio_in_dc_remove_op_mono;
      .VAR audio_in_shift_op_mono.func = &$cbops.shift;
      .VAR audio_in_shift_op_mono.param[$cbops.shift.STRUC_SIZE] =
               0,                      // Input index (left input port)
               1,                      // Output index (left cbuffer)
               8;                      // Shift amount
   .ENDBLOCK;

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

   // Allocating memory for decoder codec stream struc
   .VAR/DM1 $decoder_codec_stream_struc[$codec.av_decode.STRUC_SIZE] =
      0,                                           // frame_decode function (set by conn_init function)
      0,                                           // reset_decoder function (set by conn_init function)
      0,                                           // silence_decoder function (set by conn_init function)
      &$codec_in_cbuffer_struc,                    // in cbuffer
      &$audio_out_left_cbuffer_struc,              // out left cbuffer
      &$audio_out_right_cbuffer_struc,             // out right cbuffer
      0,                                           // MODE_FIELD
      0,                                           // number of output samples
      0,                                           // data object pointer placeholder
      30000,                                           // DECODE_TO_STALL_THRESHOLD
      GOOD_WORKING_BUFFER_LEVEL,                   // STALL_BUFFER_LEVEL_FIELD
      0,                                           // NORMAL_BUFFER_LEVEL , POORLINK_DETECT_LEVEL - no longer used
      1,                                           // Enable codec in buffer purge when in pause
      &$master_app_reset,
      0 ...;                                       // Pad out remaining items with zeros   

   // Allocating memory for encoder codec stream struc
   .VAR/DM1 $encoder_codec_stream_struc[$codec.av_encode.STRUC_SIZE] =
      0,                                           // frame_encode function (set by conn_init function)
      0,                                           // reset_encoder function (set by conn_init function)
      &$codec_out_cbuffer_struc,                   // out cbuffer
      &$audio_in_mono_cbuffer_struc,               // in mono cbuffer
      0,
      0 ...;



#ifdef LATENCY_REPORTING

    // allocate meory for inverse of dac and codec sample rates
    .VAR $inv_codec_fs = $latency.INV_FS(48000);
    .VAR $inv_dac_fs = $latency.INV_FS(48000);
    .VAR zero = 0;
   
    #ifdef HARDWARE_RATE_MATCH
        .VAR $latency_calc_current_warp = &$current_hw_rate;
        .VAR $latency_calc_port_warp = &$current_hw_rate;
    #else 
        .VAR $latency_calc_current_warp = &$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
        .VAR $latency_calc_port_warp = &zero;
    #endif
    
    .VAR cbuffers_latency_measure[] =
       &$audio_out_left_cbuffer_struc, &$inv_codec_fs, &$latency_calc_current_warp,
       $dac_out_left_cbuffer_struc, &$inv_codec_fs, &$latency_calc_current_warp,
       $dac_out_temp_left_cbuffer_struc, &$inv_dac_fs, &$latency_calc_current_warp,
       $AUDIO_LEFT_OUT_PORT, &$inv_dac_fs, &$latency_calc_port_warp,
       0;
    // define samples structure involved in pcm latency
    .VAR samples_latency_measure[] =
       0, &$inv_codec_fs, &$latency_calc_current_warp,
       0;
    // define pcm latency structure
    .VAR $pcm_latency_input_struct[$pcm_latency.STRUC_SIZE] =
      &cbuffers_latency_measure,
      &samples_latency_measure;

    // define encoded latency structure
    .VAR $encoded_latency_struct[$encoded_latency.STRUC_SIZE] =
      $pcm_latency_input_struct,
      &$codec_packets_info_cbuffer_struc,
      $codec_in_cbuffer_struc,
      &$audio_out_left_cbuffer_struc, &$inv_codec_fs, &$latency_calc_current_warp,
      3, // minimum over last three
      0 ...;
     // define cbuffers structure involved in pcm latency
     
#endif // LATENCY_REPORTING




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

   .VAR $EncoderMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
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

   // Timer period variable for reading codec data
   // (this is modified according to the connection type and also to support local playback)
   .VAR $tmr_period_con_copy;

   // Timer period variable for reading tone/prompt data
   // (this is modified according to the connection type and also to support local playback)
   .VAR $tmr_period_tone_copy = TMR_PERIOD_TONE_COPY;

   .VAR $codec_reset_needed;

   // Rate matching data structure
   .VAR $sra_struct[$sra.STRUC_SIZE];
   .VAR $rate_match_disable = 0;

   // APTX-LL tuning parameters (set from the VM)
   .BLOCK $headset_tuning_params;
      .VAR $target_codec_level  = TARGET_CODEC_BUFFER_LEVEL;
      .VAR $good_working_level  = GOOD_WORKING_BUFFER_LEVEL;
      .VAR $sra_max_rate        = SRA_MAXIMUM_RATE;
      .VAR $sra_averaging_time  = SRA_AVERAGING_TIME;
   .ENDBLOCK;

   // Statistics pointer tables (these pointers are copied to the statistics pointer array by the conn_init function)
   // (this fixed size array contains pointers to codec specific information)
#ifdef APTX_ACL_SPRINT_ENABLE
   .VAR $codec_stats[$music_example.CODEC_STATS_SIZE] =
      &$music_example.SamplingRate,
      &$music_example.aptx_channel_mode,
      &$music_example.aptx_security_status,
      &$music_example.aptx_decoder_version,
      &$M.system_config.data.ZeroValue,
      &$M.system_config.data.ZeroValue,
      &$M.system_config.data.ZeroValue,
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT6
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT7
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT8
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT9
      &$M.system_config.data.ZeroValue,                        // CODEC_STATA
      &$M.system_config.data.ZeroValue,                        // CODEC_STATB
      &$audio_if_mode,                                         // INTERFACE_TYPE
      &$music_example.SamplingRate,                            // INPUT_RATE
      &$current_dac_sampling_rate,                             // OUTPUT_RATE
      &$current_codec_sampling_rate;                           // CODEC_RATE
#endif

//------------------------------------------------------------------------------
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
   // initialise licensing subsystem
   call $Security.Initialize;
   // initialise the wallclock library
   call $wall_clock.initialise;
#if defined(DEBUG_ON)
   // initialise the profiler library
   call $profiler.initialise;
#endif
   // init DM_flash
   call $flash.init_dmconst;

   // set up message handler for VM_SET_DAC_RATE_MESSAGE_ID message
   r1 = &$set_dac_rate_from_vm_message_struc;
   r2 = VM_SET_DAC_RATE_MESSAGE_ID;
   r3 = &$set_dac_rate_from_vm;
   call $message.register_handler;

   // set up message handler for VM_SET_CODEC_RATE_MESSAGE_ID message
   r1 = &$set_codec_rate_from_vm_message_struc;
   r2 = VM_SET_CODEC_RATE_MESSAGE_ID;
   r3 = &$set_codec_rate_from_vm;
   call $message.register_handler;

   // set up message handler for VM_SET_CODEC_RATE_MESSAGE_ID message
   r1 = &$set_tone_rate_from_vm_message_struc;
   r2 = VM_SET_TONE_RATE_MESSAGE_ID;
   r3 = &$set_tone_rate_from_vm;
   call $message.register_handler;

   // set up message handlers for VM_APTX_LL_PARAMS_MESSAGE_ID messages
   r1 = &$get_aptx_ll_params_from_vm_message_struc1;
   r2 = VM_APTX_LL_PARAMS_MESSAGE1_ID;
   r3 = &$get_aptx_ll_params_from_vm1;
   call $message.register_handler;

   r1 = &$get_aptx_ll_params_from_vm_message_struc2;
   r2 = VM_APTX_LL_PARAMS_MESSAGE2_ID;
   r3 = &$get_aptx_ll_params_from_vm2;
   call $message.register_handler;

   // intialize SPI communications library
   call $spi_comm.initialize;

   // Power Up Reset needs to be called once during program execution
   call $music_example.power_up_reset;

   // Send Ready Message to VM so it can connect streams to the Kalimba
   r2 = $music_example.VMMSG.READY;
   r3 = $MUSIC_MANAGER_SYSID;
   // status
   r4 = M[$music_example.Version];
   r4 = r4 LSHIFT -8;
   call $message.send_short;

#ifdef LATENCY_REPORTING
   // reset encoded latency module
   r7 = &$encoded_latency_struct;
   call $latency.reset_encoded_latency;
#endif // LATENCY_REPORTING

   // Set sbc encoder for back channel
   r0 = &$faststream.sbcenc_post_func;
   r1 = &$sbcenc.pre_post_proc_struc;
   M[r1 + $codec.pre_post_proc.POST_PROC_FUNC_ADDR_FIELD] = r0;

   // tell vm we're ready and wait for the go message
   call $message.send_ready_wait_for_go;

   // Initialize the connection type (only A2DP supported here)
   // (allows run-time selection of connection type)
   call $conn_init;

   // Configure the resampler according to the codec and DAC sampling rates
   call $config_resampler;

   // Configure the rate matching algorithm
   call $config_rate_matching;

   // if $CODEC_OUT_PORT is disconnected then it means no voice channel is requested
   r5 = 1;
   r0 = $CODEC_OUT_PORT;
   call $cbuffer.is_it_enabled;
   if Z r5 = 0;
   M[$voice_enabled] = r5;
   if Z jump no_voice_channel;

   // see if left input port is connected
   r0 = $AUDIO_LEFT_IN_PORT;
   call $cbuffer.is_it_enabled;
   if NZ jump left_in_port_connected;
      // tell codec library that no left buffer
      M[$encoder_codec_stream_struc + $codec.av_encode.IN_LEFT_BUFFER_FIELD] = 0;
   left_in_port_connected:

   // left and right audio channels from the mmu have been synced to each other
   // by the vm app but are free running in that the dsp doesn't tell them to
   // start.  We need to make sure that our copying between the cbuffers and
   // the mmu buffers starts off in sync with respect to left and right
   // channels.  To do this we make sure that when we start the copying timers
   // that there is no chance of a buffer wrap around occuring within the timer
   // period.  The easiest way to do this is to start the timers just after a
   // buffer wrap around occurs.

      // wait for ADC buffers to have just wrapped around
      wait_for_adc_buffer_wraparound:
         r0 = $AUDIO_LEFT_IN_PORT;
         call $cbuffer.calc_amount_data;
         // if the amount of data in the buffer is less than 16 samples then a
         // buffer wrap around must have just ocurred.
         Null = r0 - 16;
      if POS jump wait_for_adc_buffer_wraparound;

   // start timer that copies audio samples
   r1 = &$audio_in_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_in_copy_handler;
   call $timer.schedule_event_in;

no_voice_channel:

   // for 200ms, clear all incomming codec data
   // this causes to synchronise source and sink
   // and having consistent delay
   r7 = 200;
   loop_discard_all_codec_data:
      call $timer.1ms_delay;
      r0 = $CODEC_IN_PORT;
      call $cbuffer.calc_amount_data;
      r10 = r0;
      r0 = $CODEC_IN_PORT;
      call $cbuffer.get_read_address_and_size;
      I0 = r0;
      L0 = r1;
      do lp_read_port_data;
         r0 = M[I0, 1];
         nop;
      lp_read_port_data:
      L0=0;
      r0 = $CODEC_IN_PORT;
      r1 = I0;
      call $cbuffer.set_read_address;
      r7 = r7 -1;
   if GT jump loop_discard_all_codec_data;


   // start timer that copies codec data
   r1 = &$codec_timer_struc;
   r2 = M[$tmr_period_con_copy];
   r3 = &$codec_copy_handler;
   call $timer.schedule_event_in;

   // Start in stalled mode until data arrives
   r5 = &$decoder_codec_stream_struc;
   r0 = $codec.NOT_ENOUGH_INPUT_DATA;
   M[r5 + $codec.av_decode.MODE_FIELD] = r0;

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

   // wait for DAC buffers to have just wrapped around
   wait_for_dac_buffer_wraparound:
      r0 = $AUDIO_LEFT_OUT_PORT;
      call $cbuffer.calc_amount_space;
      // if the amount of space in the buffer is less than 16 bytes then a
      // buffer wrap around must have just ocurred.
      Null = r0 - 16;
   if POS jump wait_for_dac_buffer_wraparound;

   // start timer that copies audio samples
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in;

   // continually decode and encode codec frames
   frame_loop:

      // Check Communication
      call $spi_comm.polled_service_routine;

      // Check the connection type (A2DP or USB/ANALOGUE) and process accordingly
      r0 = M[$app_config.io];

      // Fatal error if not A2DP APTX_ACL_SPRINT_IO connection type
      null = r0 - $APTX_ACL_SPRINT_IO;
      if NZ jump $error;

      // Start profiler
      r8 = &$DecoderMips_data_block;
      call $M.mips_profile.mainstart;   // start profiler

      // decode a frame
      r5 = &$decoder_codec_stream_struc;
      call $codec.av_decode;
      call $sra_calcrate;
      #ifdef LATENCY_REPORTING
          Null = M[$M.configure_latency_reporting.enabled];
          if Z jump skip_latency_measurement;
              r7 = &$encoded_latency_struct;
              call $latency.calc_encoded_latency;
          skip_latency_measurement:
      #endif // LATENCY_REPORTING
skip_decode:

      // Stop profiler
      r8 = &$DecoderMips_data_block;
      call $M.mips_profile.mainend;

      // Store Decoder MIPS
      r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
      M[&$music_example.PeakMipsDecoder] = r0;

      // Synchronize frame process to audio interrupt
      r5 = &$decoder_codec_stream_struc;
      r0 = M[r5 + $codec.av_decode.MODE_FIELD];
      Null = r0 - $codec.SUCCESS;
      if NZ call $frame_sync.1ms_delay;
        r3 = M[$M.codec_copy_handler.frame_proc_num_samples];
   
        r0 = $audio_out_left_cbuffer_struc;
        call $cbuffer.calc_amount_data;
        null = r0 - r3;
        if NEG jump frame_loop;
        r0 = $audio_out_right_cbuffer_struc;
        call $cbuffer.calc_amount_data;
        null = r0 - r3;
        if NEG jump frame_loop;
        // check for space
        r0 = $dac_out_left_cbuffer_struc;
        call $cbuffer.calc_amount_space;
        null = r0 - r3;
        if NEG jump frame_loop;

        r0 = $dac_out_right_cbuffer_struc;
        call $cbuffer.calc_amount_space;
        null = r0 - r3;
        if NEG jump frame_loop; 

      // call processing function if block-size worth of data/space available
      if POS call $music_example_process;

      // reset encoder if needed
      Null = M[$codec_reset_needed];
      if Z jump no_codec_reset;
         r5 = &$encoder_codec_stream_struc;
         r0 = M[r5 + $codec.av_encode.RESET_ADDR_FIELD];
         r5 = r5 + $codec.av_encode.ENCODER_STRUC_FIELD;
         call r0;
         M[$codec_reset_needed] = 0;
      no_codec_reset:

      // encode a frame
      Null = M[$voice_enabled];
      if Z jump no_encoder_run;

      r8 = &$EncoderMips_data_block;
      call $M.mips_profile.mainstart;   // start profiler for encoder

      // call encoder for voice channel
      r5 = &$encoder_codec_stream_struc;
      call $codec.av_encode;

      r8 = &$EncoderMips_data_block;
      call $M.mips_profile.mainend;     // end profiler for encoder

      r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
      // M[&$music_example.PeakMipsEncoder] = r0;
      r5 = &$encoder_codec_stream_struc;
      r0 = M[r5 + $codec.av_encode.MODE_FIELD];
      Null = r0 - $codec.SUCCESS;
      if Z jump frame_loop;
   no_encoder_run:

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
// INPUTS:
//  - none
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.audio_out_copy_handler;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $audio_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // If not using cbops.stream_copy, need to manually
   // reset the sync flag.
   M[$frame_sync.sync_flag] = Null;

   // Mono or stereo connection? (based on whether the right output port is enabled)
   r0 = $AUDIO_RIGHT_OUT_PORT;
   call $cbuffer.is_it_enabled;
#if defined(FORCE_MONO_OUTPUT)
   r0 = 0;
#endif
   if Z jump mono;
   #ifdef LATENCY_REPORTING
      #if defined(HARDWARE_RATE_MATCH)
         r8 = &$current_hw_rate;
      #else
         r8 = &$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
      #endif
      M[$latency_calc_current_warp] = r8;
   #endif //LATENCY_REPORTING
 
      Null = M[$dac_resampler.resampler_active];
      if Z jump no_resampler; // this causes extra buffering, which increases latency
         r8 = &$dac_out_resampler_stereo_copy_struc;
         call $cbops.copy;
         r8 = &$stereo_out_copy_struc;
         call $cbops.dac_av_copy;
         jump repost;
      no_resampler:

      r8 = &$stereo_out_no_resampler_copy_struc;
      call $cbops.dac_av_copy;
      jump repost;

   mono:
   #ifdef LATENCY_REPORTING
      #if defined(HARDWARE_RATE_MATCH)
         r8 = &$current_hw_rate;
      #else
         r8 = &$audio_out_rate_adjustment_and_shift_op_mono.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
      #endif
      M[$latency_calc_current_warp] = r8;
   #endif //LATENCY_REPORTING
   
      Null = M[$dac_resampler.resampler_active];
      if Z jump no_resample_mono; // this causes extra buffering, which increases latency
         r8 = &$dac_out_resampler_mono_copy_struc;
         call $cbops.copy;
         r8 = &$mono_out_copy_struc;
         call $cbops.dac_av_copy;
         jump repost;
      no_resample_mono:   
      r8 = &$mono_out_no_resampler_copy_struc;
      call $cbops.dac_av_copy;

   repost:

   // Post another timer event
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $audio_in_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the mono or stereo copying
//    of decoded samples to the output and from the input.
//
// INPUTS:
//  - none
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.audio_in_copy_handler;
   .CODESEGMENT AUDIO_IN_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $audio_in_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // copy audio data from the port to the cbuffer
   r8 = &$mono_audio_in_copy_struc;
   call $cbops.adc_av_copy;

   // Resample voice channel if required
   r8 = &$adc_in_resampler_mono_copy_struc;
   call $cbops.copy;

   // post another timer event
   r1 = &$audio_in_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_in_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $codec_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the copying of encoded
//    samples from the input.
//    Includes code to handle 1 byte being stuck in the MMU which would otherwise
//    not be read and may cause flow control to be asserted indefinitely.
//
// INPUTS:
//  - none
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.codec_copy_handler;
   .CODESEGMENT CODEC_COPY_HANDLER_PM;
   .DATASEGMENT DM;
   .VAR packet_size_obtained;
   .VAR frame_proc_num_samples = 160;
   .VAR initial_write_pos = 0;

   $codec_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

   #ifdef LATENCY_REPORTING
        r0 = M[&$codec_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
        M[$codec_packets_info_last_write_address] = r0;
    #endif // LATENCY_REPORTING

   //calculate mismatch rate
   call $sra_tagtimes;

   .VAR byte0;
   .VAR byte1;
   .VAR byte0_flag;

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   r0 = M[&$codec_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD]; 
   M[initial_write_pos] = r0;

   // Get amount of data (in bytes) in input port
   r0 = $CODEC_IN_PORT;
   call $cbuffer.calc_amount_data;
   null = r1;
   if Z jump copy_done; // Don't do anything if no data available

   // Was there an odd byte (byte0) remaining on the last copy from the port
   null = M[byte0_flag];
   if Z jump no_odd_byte;

      // Get amount of space (in words) in output buffer
      r0 = $codec_in_cbuffer_struc;
      call $cbuffer.calc_amount_space;
      null = r0;
      if Z jump copy_done; // Don't do anything if no space available

      // Switch to 8bit read mode
      M[($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = $BITMODE_8BIT_ENUM;

      // Read the second byte to complete the 16bit word
      r0 = M[($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA];
      r0 = r0 AND 0xff;
      M[byte1] = r0;

      // Update input port
      r0 = $CODEC_IN_PORT;
      r1 = ($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA;
      call $cbuffer.set_read_address;

      r0 = $CODEC_IN_PORT;
      call $cbuffer.calc_amount_data;

      // Switch to 16bit read mode
      r0 = $BITMODE_16BIT_ENUM + $BYTESWAP_MASK + $NOSIGNEXT_MASK;
      M[($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = r0;

      // Get the write address for the output buffer
      r0 = $codec_in_cbuffer_struc;
      call $cbuffer.get_write_address_and_size;
      I0 = r0;
      L0 = r1;

      // Combine bytes to form 16bit word to be written
      r0 = M[byte1];
      r1 = M[byte0];
      r1 = r1 LSHIFT 8;
      r0 = r1 OR r0;

      // Write the word of data (byte1 OR byte0)
      M[I0,1] = r0;

      // Reset for linear addressing
      L0 = 0;

      // Update output buffer
      r0 = $codec_in_cbuffer_struc;
      r1 = I0;
      call $cbuffer.set_write_address;

      // Clear the flag
      M[byte0_flag] = 0;

   no_odd_byte:


   // copy data from the port to the cbuffer
   r8 = &$codec_in_copy_struc;
   call $cbops.copy;

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get amount of data (in bytes) in input port
   r0 = $CODEC_IN_PORT;
   call $cbuffer.calc_amount_data;

   // Only 1 byte left?
   null = r1 - 1;
   if NZ jump skip_odd_byte;

      // Switch to 8bit read mode
      M[($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = $BITMODE_8BIT_ENUM;

      // Read the odd byte (byte0)
      r0 = M[($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA];
      r0 = r0 AND 0xff;
      M[byte0] = r0;

      // Update input port (this lets the firmware send more data)
      r0 = $CODEC_IN_PORT;
      r1 = ($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA;
      call $cbuffer.set_read_address;

      // Switch to 16bit read mode
      r0 = $BITMODE_16BIT_ENUM + $BYTESWAP_MASK + $NOSIGNEXT_MASK;
      M[($CODEC_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = r0;

      // Flag an odd byte (byte0) has been read
      r0 = 1;
      M[byte0_flag] = r0;

   skip_odd_byte:
   copy_done:

  #if defined(HARDWARE_RATE_MATCH)
      // If rate matching is disabled don't apply H/W rate correction
      null = M[&$rate_match_disable];
      if Z call $apply_hardware_warp_rate;
  #endif

// DEBUG stats
#ifdef DEBUG_STATS
#define SAMPLE_SIZE 1000
.VAR $buffer_post_copy_data = 0;
.VAR $buff_post_copy_ptr = &$buff_post_copy_buffer;
.VAR/DMCIRC $buff_post_copy_buffer[SAMPLE_SIZE];
.VAR $codec_in_buffer_empty_count = 0;


r0 = $codec_in_cbuffer_struc;
call $cbuffer.calc_amount_data;

M[$buffer_post_copy_data] = r0;

Null = r0;
if NZ jump not_empty;
r0 = M[$codec_in_buffer_empty_count];
r0 = r0 + 1;
M[$codec_in_buffer_empty_count] = r0;
not_empty:

// Store last 100 values of fill level
r5 = M[$buffer_post_copy_data];
r0 = M[$buff_post_copy_ptr];
I0 = r0;
L0 = SAMPLE_SIZE;
M[I0,1] = r5;
r0 = I0;
M[$buff_post_copy_ptr] = r0;
L0 = 0;
#endif

   // copy coded data in multiple frame chunks
   r8 = &$codec_out_copy_struc;
   r0 = M[r8 + $codec.av_encode.OUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   NULL = r0 - (200/2);
   if GE call $cbops.copy;

    #ifdef LATENCY_REPORTING
        Null = M[$M.configure_latency_reporting.enabled];
        if Z jump skip_packet_detection;
            call $media_packet_boundary_detection;
        skip_packet_detection:
    #endif // LATENCY_REPORTING
  
   r0 = M[&$codec_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD]; 
   r0 = r0 - M[initial_write_pos];
   if Z jump packet_length_obtained;
   Null = M[packet_size_obtained];
   if NZ jump packet_length_obtained;
      r1 = 0;
      r2 = 150;
      Null = r0 - 300;
      if Z r1 = r2;
      Null = r0 - 150;
      if Z r1 = r2;
      r2 = 138;
      Null = r0 - 276;
      if Z r1 = r2;
      Null = r0 - 138;
      if Z r1 = r2;
      M[packet_size_obtained] = r1;
      Null = M[packet_size_obtained];
      if Z jump packet_length_obtained;
      M[frame_proc_num_samples] = r1;
      M[$M.system_config.data.stream_map_left_in + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      M[$M.system_config.data.stream_map_right_in + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      M[$M.system_config.data.stream_map_left_out + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      M[$M.system_config.data.stream_map_right_out + $framesync_ind.FRAME_SIZE_FIELD] = r1;
   packet_length_obtained:

   // post another timer event
   r1 = &$codec_timer_struc;
   r2 = M[$tmr_period_con_copy];
   r3 = &$codec_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $get_aptx_ll_params_from_vm1
//
// DESCRIPTION: message handler for receiving aptX ll parameters from VM
//
// INPUTS:
//    r1 = Target Codec Level
//    r2 = Initial Codec Level
//    r3 = SRA Max Rate
//    r4 = SRA averaging time
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.get_aptx_ll_params_from_vm1;
   .CODESEGMENT GET_APTX_LL_PARAMS_FROM_VM1_PM;
   .DATASEGMENT DM;

$get_aptx_ll_params_from_vm1:

   M[$target_codec_level]  = r1;
   M[$sra_averaging_time]  = r4;

   rMac = r3;
   r0 = 20000;     // Divide by 10000 in rMac
   Div = rMac/r0;
   r3 = DivResult;
   M[$sra_max_rate] = r3;

   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $get_aptx_ll_params_from_vm2
//
// DESCRIPTION: message handler for receiving aptX ll parameters from VM
//
// INPUTS:
//    r1 = Good working Level
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.get_aptx_ll_params_from_vm2;
   .CODESEGMENT GET_APTX_LL_PARAMS_FROM_VM2_PM;
   .DATASEGMENT DM;

$get_aptx_ll_params_from_vm2:

   rMac = r1;
   if Z jump default_good_level;
   r0 = 2 * CODEC_CBUFFER_SIZE; // Divide by CBUFFER_SIZE to get as a fraction
   Div = rMac/r0;
   r1 = DivResult;
   jump updated_good_level;
   default_good_level:
   r1 = GOOD_WORKING_BUFFER_LEVEL;
   updated_good_level:
   M[$good_working_level] = r1;

   rts;
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
//    $set_dac_rate_from_vm
//
// DESCRIPTION: message handler for receiving DAC rate from VM
//
// INPUTS:
//  r1 = dac sampling rate/10 (e.g. 44100Hz is given by r1=4410)
//  r2 = maximum clock mismatch to compensate (r2/10)%
//       (Bit7==1 disables the rate control, e.g 0x80)
//  r3 = bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
//  r4 = bits(1:0): audio output interface type:
//                  0 -> None (not expected)
//                  1 -> Analogue output (DAC)
//                  2 -> I2S output
//                  3 -> SPDIF output
//       bit8: playback mode (0: remote playback, 1: local file play back)
//             local play back isn't relevant in this app and shall not be used
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.set_dac_rate_from_vm;
   .CODESEGMENT SET_DAC_RATE_FROM_VM_PM;

$set_dac_rate_from_vm:

   // Mask sign extension
   r1 = r1 AND 0xffff;

   // Scale to get sampling rate in Hz
   r1 = r1 * 10 (int);

   // Store the parameters
   M[$current_dac_sampling_rate] = r1;                // DAC sampling rate (e.g. 44100Hz is given by r1=44100)
   M[$current_adc_sampling_rate] = r1;                // ADC sampling rate is set to the same as the DAC
   M[$max_clock_mismatch] = r2;                       // Maximum clock mismatch to compensate (r2/10)% (Bit7==1 disables the rate control, e.g 0x80)
   M[$long_term_mismatch] = r3;                       // bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
   r0 = r4 AND $LOCAL_PLAYBACK_MASK;                  // Mask for local file play back info
   M[$local_play_back] = r0;                          // NZ means local file play back (local file play back not used here)
   r0 = r4 AND $AUDIO_IF_MASK;                        // Mask for audio i/f info
   M[$audio_if_mode] = r0;                            // Set audio output interface type

    #ifdef LATENCY_REPORTING
        // update inverse of dac sample rate
        push rLink;
        r0 = M[$current_dac_sampling_rate];
        call $latency.calc_inv_fs;
        M[$inv_dac_fs] = r0;
        pop rLink;
    #endif // LATENCY_REPORTING

   rts;
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
//    $set_codec_rate_from_vm
//
// DESCRIPTION: message handler for receiving codec rate from VM
//
// INPUTS:
//  r1 = forward channel codec sampling rate/10 (e.g. music @44100Hz is given by r1=4410)
//  r2 = back channel codec sampling rate/10 (e.g. voice @16000Hz is given by r2=1600)
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.set_codec_rate_from_vm;
   .CODESEGMENT SET_CODEC_RATE_FROM_VM_PM;

$set_codec_rate_from_vm:

   // Mask sign extension
   r1 = r1 AND 0xffff;

   // Scale to get sampling rate in Hz
   r1 = r1 * 10 (int);

   // Mask sign extension
   r2 = r2 AND 0xffff;

   // Scale to get sampling rate in Hz
   r2 = r2 * 10 (int);

   // Store the music forward channel codec sampling rate
   M[$current_codec_sampling_rate] = r1;

   //r2 = 16000;
   // Store the voice back channel codec sampling rate
   M[$current_voice_codec_sampling_rate] = r2;

    #ifdef LATENCY_REPORTING
        // update inverse of codec sample rate
        push rLink;
        r0 = M[$current_codec_sampling_rate];
        call $latency.calc_inv_fs;
        M[$inv_codec_fs] = r0;
        pop rLink;
    #endif // LATENCY_REPORTING

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
// NOTES:
//    The DAC and codec sampling rates need to be set before calling this routine
//    The VM should send 2 messages that should result in the following handlers being
//    called: $set_dac_rate_from_vm $set_codec_rate_from_vm.
// *****************************************************************************
.MODULE $M.config_rate_matching;
   .CODESEGMENT CONFIG_RATE_MATCHING_PM;

$config_rate_matching:

   // push rLink onto stack
   $push_rLink_macro;

   // Get the codec sampling rate
   r1 = M[$current_codec_sampling_rate];     // Codec sampling rate (e.g. 44100Hz is given by r1=44100)

   r1 = r1 * SRA_AVERAGING_TIME (int);
   M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r1;

   // Check if the rate matching is disabled (bit7==1 disables the rate matching e.g. r2=0x80)
   r2 = M[$max_clock_mismatch];              // Maximum clock mismatch to compensate (r2/10)% (Bit7==1 disables the rate control, e.g 0x80)
   r0 = r2 LSHIFT -7;
   r0 = r0 AND 1;
   M[&$rate_match_disable] = r0; // Enable: 0, Disable: 1

   // Local playback?
   r4 = M[$local_play_back];                 // NZ means local file play back
   if NZ jump $error;                        // Local playback not supported in this app.

   // If rate matching is disabled don't update rate
   null = M[&$rate_match_disable];
   if NZ jump end;

   // set maximum rate for clock mismatch compensation
   r2 = r2 AND 0x7F;
   r1 = r2 - 3;         // min 0.3% percent by default
   if NEG r2 = r2 -r1;
   r2 = r2 * 0.001(int);
   r1 = r2 * 0.25(frac); // to cover jitter
   r2 = r2 + r1;
   r1 = r2 - ABSOLUTE_MAXIMUM_CLOCK_MISMATCH_COMPENSATION;
   if POS r2 = r2 - r1;
   M[$sra_struct + $sra.MAX_RATE_FIELD] = r2;
   r2 = 0.5; // just a big number
   M[$sra_struct + $sra.LONG_TERM_RATE_FIELD] = r2;

   // see if clock mismatch rate received from vm
   r3 = M[$long_term_mismatch];              // bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
   r0 = r3 AND 0x1;
   if Z jump end;

   // get saved clock mismatch rate
   r3 = r3 ASHIFT -1;
   r3 = r3 ASHIFT 6;

   // make sure it is not out of range
   Null = r3 - M[$sra_struct + $sra.MAX_RATE_FIELD];
   if POS jump end;
   Null = r3 + M[$sra_struct + $sra.MAX_RATE_FIELD];
   if NEG jump end;

   // initialize some variables based on the saved rate
   M[$sra_struct + $sra.RATE_BEFORE_FIX_FIELD ] = r3;
   M[$sra_struct + $sra.SRA_RATE_FIELD ] = r3;
   r0 = M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD];
   r0 = r0 * r3 (frac);
   M[$sra_struct + $sra.HIST_BUFF_FIELD + 0] = r0;
   M[$sra_struct + $sra.HIST_BUFF_FIELD + 1] = r0;
   r0 = 2;
   M[$sra_struct + $sra.HIST_INDEX_FIELD] = r0;
   r0 = 1;
   M[$sra_struct + $sra.LONG_TERM_RATE_DETECTED_FIELD] = r0;

   #if defined(HARDWARE_RATE_MATCH)
      // Initial hardware rate adjustment
      M[$current_hw_rate] = r3;
      r4 = r3 * (-1.0/64.0)(frac);
      r2 = &$MESSAGE_WARP_DAC;
      r3 = 3;
      call $message.send_short;
   #endif

   end:
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

#if defined(HARDWARE_RATE_MATCH)
// *****************************************************************************
// MODULE:
//   $apply_hardware_warp_rate
// DESCRIPTION:
//   Applies hardware warp rate by sending message to the firmware
//
// INPUTS:
//  - none
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.apply_hardware_warp_rate;
   .CODESEGMENT APPLY_WARP_RATE_PM;
   .DATASEGMENT DM;

   $apply_hardware_warp_rate:

   // push rLink onto stack
   $push_rLink_macro;

  .CONST HW_APPLY_WARP_RATE_TMR_MS                64;   // timer period to apply hardware warp rate (ms)
  .CONST HW_APPLY_WARP_MOVING_STEP                64;   // max rate change in each period (Q.23)

  .VAR $current_hw_rate = 0;
  .VAR $rate_apply_cntr;

   // see if time to apply hw warp rate
   r0 = M[$rate_apply_cntr];
   r0 = r0 + 1;
   M[$rate_apply_cntr] = r0;
   Null = r0 - ((HW_APPLY_WARP_RATE_TMR_MS*1000)/TMR_PERIOD_CODEC_COPY);
   if NEG jump end_hw_rate_apply;
      // reset counter
      M[$rate_apply_cntr] = 0;

      // slowly move towards the target rate
      r5 = M[$current_hw_rate];
      r4 = M[$sra_struct + $sra.SRA_RATE_FIELD]; // maximum 3%, otherwise overflow happens

      // calculate moving step (logarithmic then linear)
      r1 = HW_APPLY_WARP_MOVING_STEP;
      r0 = r5 - r4;
      if NEG r0 = -r0;
      r2 = r0 * (0.001*HW_APPLY_WARP_RATE_TMR_MS)(frac);
      Null = r0 - 0.0015;
      if NEG r2 = r1;
      r1 = r2 - (20*HW_APPLY_WARP_MOVING_STEP);
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
      r1 = r5 - M[$current_hw_rate];
      if Z jump end_hw_rate_apply;
         //  apply harware warp rate
         M[$current_hw_rate] = r5;
         r4 = -r4;
         r2 = $MESSAGE_WARP_DAC;
         r3 = 3;
         call $message.send_short;
   end_hw_rate_apply:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif

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
//    $M.conn_init_cbuffers
//
// DESCRIPTION:
//    Helper function to set up the cbuffers with given sizes
//    (note: the data buffer must start at an address that
//    is appropriate for the size of cbuffer requested)
//
// INPUTS:
//    r3 = Audio cbuffer size
//    r4 = Codec cbuffer size
//
// OUTPUTS:
//    none
//
// TRASHES: r0, r1, r2
//
// *****************************************************************************
.MODULE $M.conn_init_cbuffers;
   .CODESEGMENT PM;

$conn_init_cbuffers:

   $push_rLink_macro;

   // Set up the cbuffers specifically for the codec type
   r0 = $audio_out_left_cbuffer_struc;
   r1 = $audio_out_left;
   r2 = r3;
   call $cbuffer.buffer_configure;

   r0 = $audio_out_right_cbuffer_struc;
   r1 = $audio_out_right;
   r2 = r3;
   call $cbuffer.buffer_configure;

   r0 = $codec_in_cbuffer_struc;
   r1 = $codec_in;
   r2 = r4;
   call $cbuffer.buffer_configure;

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    conn_init
//
// DESCRIPTION:
//    Helper routine to allow run-time selection of USB/A2DP operation
//
//    Sets up the cbuffer sizes according to the codec/USB
//
//    Sets the inputs in the Rate Adaptation (SRA) structure:
//
//    $sra.TAG_DURATION_FIELD                     0;    //input: duration of the rate calc (in number of interrupts)
//    $sra.CODEC_PORT_FIELD                       1;    //input: codec input port to check activity
//    $sra.CODEC_CBUFFER_TO_TAG_FIELD             2;    //input: codec input cbuffer to tag the times
//    $sra.AUDIO_CBUFFER_TO_TAG_FIELD             3;    //input: audio output cbuffer to count PCM samples
//    $sra.MAX_RATE_FIELD                         4;    //input: maximum possible rate adjustment
//    $sra.AUDIO_AMOUNT_EXPECTED_FIELD            5;    //input: amount of PCM sample expected to receive in one period (FS*TAG_DURATION_FIELD*interrupt_time)
//
//    Override the statistics table pointers
//
//    Initialize the USB/codec timer and codec_type
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHES: r0, r1, r2, r3, r4, r10, I0 and those trashed by the codec initialise functions
//
// *****************************************************************************
.MODULE $M.conn_init;

   .CODESEGMENT PM;

$conn_init:

   $push_rLink_macro;

   // Set up the cbuffers for the codec
   r3 = AUDIO_CBUFFER_SIZE;
   r4 = CODEC_CBUFFER_SIZE;
   call $conn_init_cbuffers;

   // Get the connection type
   r0 = M[$app_config.io];

   // Check the connection type (only A2DP APTX_ACL_SPRINT allowed here) and initialize accordingly
   null = r0 - $APTX_ACL_SPRINT_IO;
   if NZ jump $error;

      // ------------------------------------------------------------------------
      // Set up the Rate Adaptation for A2DP

      #define TAG_DURATION_SCALE (1000000/TMR_PERIOD_CODEC_COPY)

      r0 = M[$sra_averaging_time];
      r0 = r0 * TAG_DURATION_SCALE (int);
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      r0 = $CODEC_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = r0;
      r0 = &$codec_in_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = &$audio_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = M[$sra_max_rate];
      M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;

      r1 = M[$current_codec_sampling_rate];
      r0 = M[$sra_averaging_time];
      r0 = r1 * r0 (int); // Fs x SRA_AVERAGING_TIME
      // Number of samples collected over averaging time
      M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;

      r0 = M[$good_working_level];
      M[$decoder_codec_stream_struc + $codec.stream_decode.GOOD_WORKING_BUFLEVEL_FIELD] = r0;

      // Target buffer level is dependent on the codec sampling rate
      null = r1 - 44100;
      if NZ jump not_44100;

         // 44.1kHz codec operation

         // Set the target level
         r2 = M[$target_codec_level];
         r2 = r2 + 20;                // Add a fraction more to target (0.02)
         r0 = 2 * CODEC_CBUFFER_SIZE; // Divide by CBUFFER_SIZE
         rMac = r2;
         Div = rMac/r0;
         r0 = DivResult;
         M[$sra_struct + $sra.TARGET_LEVEL_FIELD] = r0;

         jump sra_conf_done;

      not_44100:

      null = r1 - 48000;
      if NZ jump not_48000;

         // 48kHz codec operation

         // Set the target level
         r2 = M[$target_codec_level];
         r2 = r2 + 20;                // Add a fraction more to target (0.02)
         r0 = 2 * CODEC_CBUFFER_SIZE; // Divide by CBUFFER_SIZE
         rMac = r2;
         Div = rMac/r0;
         r0 = DivResult;
         r1 = r1 * 0.0884 (frac);
         M[$sra_struct + $sra.TARGET_LEVEL_FIELD] = r0 + r1;

         jump sra_conf_done;

      not_48000:

      // Unsupported codec rate (must be 44.1kHz or 48kHz)
      jump $error;

      sra_conf_done:

      // ------------------------------------------------------------------------
      // Initialize the codec timer and codec type for A2DP

      // Initialize the timer period
      r0 = TMR_PERIOD_CODEC_COPY;
      M[$tmr_period_con_copy] = r0;

      // ------------------------------------------------------------------------
      // Codec specific initialisation

      // Get the connection type
      r0 = M[$app_config.io];

#ifdef APTX_ACL_SPRINT_ENABLE
      // Check the codec type and initialize accordingly
      null = r0 - $APTX_ACL_SPRINT_IO;
      if NZ jump skip_aptx_acl_sprint;

         // Set up the decoder structure for APTX_ACL_SPRINT
         r0 = $aptx_sprint.decode;
         M[$decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
         r0 = $aptx_sprint.reset_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
         r0 = $aptx_sprint.silence_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;

         // Initialise the APTX_ACL_SPRINT decoder library
         call $aptx_sprint.init_decoder;

         // Set up the encoder structure for WB SBC
         r0 = $wbsenc.wbs_frame_encode;
         M[$encoder_codec_stream_struc + $codec.av_encode.ADDR_FIELD] = r0;
         r0 = $sbcenc.reset_encoder;
         M[$encoder_codec_stream_struc + $codec.av_encode.RESET_ADDR_FIELD] = r0;
         r5 = &$encoder_codec_stream_struc + $codec.av_encode.ENCODER_STRUC_FIELD;
         call &$sbcenc.init_static_encoder;
         // Initialise the WB SBC encoder library
         r5 = &$encoder_codec_stream_struc + $codec.av_encode.ENCODER_STRUC_FIELD;
         call $wbsenc.init_encoder;

         // Initialise the statistics pointer table
         I0 = $codec_stats;
         call $copy_codec_stats_pointers;

         jump exit;

      skip_aptx_acl_sprint:
#endif

      // Unknown codec
      jump $error;

   exit:

   jump $pop_rLink_and_rts;
.ENDMODULE;


.MODULE $M.master_app_reset;
   .CODESEGMENT MASTER_APP_RESET_PM;
   .DATASEGMENT DM;
   $master_app_reset:
   // push rLink onto stack
   $push_rLink_macro;
   // local play back?
   Null = M[$local_play_back];
   if Z jump pause_happened;
   // notify VM about end of play_back
   r2 = PLAY_BACK_FINISHED_MSG;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send_short;
   pause_happened:
   call $block_interrupts;
   // Purge dac out left buffer
   r0 = M[&$dac_out_left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$dac_out_left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   // Purge dac out right buffer
   r0 = M[&$dac_out_right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$dac_out_right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   // Purge dac out temp resampler left buffer
   r0 = M[&$dac_out_temp_left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$dac_out_temp_left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   // Purge dac out temp resampler right buffer
   r0 = M[&$dac_out_temp_right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$dac_out_temp_right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   // Clear EQ operator
   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;
   
    #ifdef LATENCY_REPORTING
        r7 = &$encoded_latency_struct;
        call $latency.reset_encoded_latency;
        M[$first_packet_received] = 0;
    #endif // LATENCY_REPORTING

   call $unblock_interrupts;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
