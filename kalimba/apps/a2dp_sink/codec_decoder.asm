// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change: 1951915 $  $DateTime: 2014/07/30 16:19:13 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    Decoder (SBC/MP3/FASTSTREAM/AAC/APTX/APTX ACL SPRINT) or wired USB for an audio playing device
//
// *****************************************************************************
#include "frame_sync_library.h"
#include "music_example.h"
#include "spi_comm_library.h"
#include "mips_profile.h"
#include "sr_adjustment.h"
#include "codec_library.h"
#include "codec_decoder.h"
#include "audio_proc_library.h"

#ifdef USB_ENABLE
#include "usbio.h"
#endif

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

#if defined(SHAREME_ENABLE) || defined(TWS_ENABLE)
   #include "relay_conn.h"
#endif


#ifdef SBC_ENABLE
   #include "sbc_library.h"
#endif

#ifdef MP3_ENABLE
   #include "mp3_library.h"
   #include "mp3.h"
#endif

#ifdef AAC_ENABLE
   #include "aac_library.h"
   #include "aac.h"
#endif

.MODULE $M.main;
   .CODESEGMENT MAIN_PM;
   .DATASEGMENT DM;

   $main:

// In order to share memory between the decoders use build libraries with the external memory
// option selected and enable application static allocation below
#ifdef MP3_USE_EXTERNAL_MEMORY
   .VAR $mp3_ext_memory_ptrs[$mp3dec.mem.NUM_FIELDS];
#endif

   // ** allocate memory for cbuffers **
   .VAR/DMCIRC $audio_out_left[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $audio_out_right[AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out_left[$OUTPUT_AUDIO_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out_right[$OUTPUT_AUDIO_CBUFFER_SIZE];

   // Codec in data buffer (not used for USB)
   .VAR/DMCIRC $codec_in[CODEC_CBUFFER_SIZE];

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

   // Rate matching control variables
   .VAR $local_encoded_play_back;   // local encoded(sbc, mp3 or aac) file is being played
   .VAR $aux_input_stream_available;       // local pcm file is being mixed
   .VAR $audio_if_mode; // output interface type
   .VAR $max_clock_mismatch;
   .VAR $long_term_mismatch;

   // ** allocate memory for cbuffer structures **

   // Codec in cbuffer (not used for USB)
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

   // ** allocate memory for timer structures **
   .VAR $con_in_timer_struc[$timer.STRUC_SIZE];
   .VAR $audio_out_timer_struc[$timer.STRUC_SIZE];
   .VAR $tone_copy_timer_struc[$timer.STRUC_SIZE];
   .VAR $signal_detect_timer_struc[$timer.STRUC_SIZE];

#ifdef USB_ENABLE
   // ** allocate memory for USB input (non-cbops) copy routine **
   .VAR/DM1 $usb_audio_in_copy_struc[$frame_sync.USB_IN_STEREO_COPY_STRUC_SIZE] =
      $CON_IN_PORT,                       // USB source buffer
      &$audio_out_left_cbuffer_struc,     // Left sink buffer
      &$audio_out_right_cbuffer_struc,    // Right sink buffer
      $USB_PACKET_LEN,                    // "large" packet length (Number of audio data bytes in a "large" USB packet for all channels)
      8,                                  // Shift amount
      0 ...;                              // Sync byte counter
#endif

#ifdef ANALOGUE_ENABLE
   // ** allocate memory for Analogue input (ADC inputs) copy routine **
   .VAR/DM1 $analogue_audio_in_copy_struc[] =
      $analogue_in_left_copy_op,        // Start of operator chain
      2,                                // 2 inputs
      $CON_IN_LEFT_PORT,                // ADC left input port
      $CON_IN_RIGHT_PORT,               // ADC right input port
      2,                                // 2 outputs
      &$audio_out_left_cbuffer_struc,   // Left sink buffer
      &$audio_out_right_cbuffer_struc;  // Right sink buffer

   .BLOCK $analogue_in_left_copy_op;
      .VAR $analogue_in_left_copy_op.next = $analogue_in_right_copy_op;
      .VAR $analogue_in_left_copy_op.func = &$cbops.shift;
      .VAR $analogue_in_left_copy_op.param[$cbops.shift.STRUC_SIZE] =
         0,                               // Input index
         2,                               // Output index
         8;                               // Scale up 16bit input word to MSB align with 24bit word
   .ENDBLOCK;

   .BLOCK $analogue_in_right_copy_op;
      .VAR $analogue_in_right_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $analogue_in_right_copy_op.func = &$cbops.shift;
      .VAR $analogue_in_right_copy_op.param[$cbops.shift.STRUC_SIZE] =
         1,                               // Input index
         3,                               // Output index
         8;                               // Scale up 16bit input word to MSB align with 24bit word
   .ENDBLOCK;
#endif

   // ** allocate memory for codec input cbops copy routine **
   .VAR $codec_in_copy_struc[] =
      &$codec_in_copy_op,              // first operator block
      1,                               // number of inputs
      $CON_IN_PORT,                    // input
      1,                               // number of outputs
      &$codec_in_cbuffer_struc;        // output

   .BLOCK $codec_in_copy_op;
      .VAR $codec_in_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $codec_in_copy_op.func = &$cbops.copy_op;
      .VAR $codec_in_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         0,                            // Input index
         1;                            // Output index
   .ENDBLOCK;


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
      &$tone_in_cbuffer_struc,         // output 0
      &$tone_in_right_cbuffer_struc;   // output 1

   .BLOCK  $stereo_tone_in_copy_op;
      .VAR $stereo_tone_in_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $stereo_tone_in_copy_op.func = &$cbops.deinterleave;
      .VAR $stereo_tone_in_copy_op.param[$cbops.deinterleave.STRUC_SIZE] =
         0,                         // Input index
         1,                         // Output 0 index
         2,                         // output 1 index
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
      0,  //   INPUT1_START_INDEX_FIELD
      1,  //   OUTPUT1_START_INDEX_FIELD
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
         1,                                        // Output index
        -8,                                        // amount of shift after dithering
         $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
         &$dither_hist_left,                       // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
         0;                                        // Enable compressor
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
#if defined(MP3_ENABLE) && defined(TWS_ENABLE)
      &$tws.bin_headers,
#else
      0,
#endif      
      0,                                           // DECODE_TO_STALL_THRESHOLD
      GOOD_WORKING_BUFFER_LEVEL,                   // STALL_BUFFER_LEVEL_FIELD
      0,                                           // NORMAL_BUFFER_LEVEL , POORLINK_DETECT_LEVEL - no longer used
      1,                                           // Enable codec in buffer purge when in pause
      &$master_app_reset,
      0 ...;                                       // Pad out remaining items with zeros

#if defined(SUB_ENABLE) || defined(LATENCY_REPORTING) || defined(TWS_ENABLE)
   // allocate meory for inverse of dac and codec sample rates
   .VAR $inv_codec_fs = $latency.INV_FS(48000);
   .VAR $inv_dac_fs = $latency.INV_FS(48000);
   .VAR zero = 0;

 #if defined(HARDWARE_RATE_MATCH)
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
#endif

#ifdef LATENCY_REPORTING
   // define encoded latency structure
   .VAR $encoded_latency_struct[$encoded_latency.STRUC_SIZE] =
      $pcm_latency_input_struct,
      &$codec_packets_info_cbuffer_struc,
      $codec_in_cbuffer_struc,
      &$audio_out_left_cbuffer_struc, &$inv_codec_fs, &$latency_calc_current_warp,
      3, // minimum over last three
      0 ...;
    // define cbuffers structure involved in pcm latency
#endif

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

   // Timer period variable for reading codec data
   // (this is modified according to the connection type and also to support local playback)
   .VAR $tmr_period_con_copy;

   // Timer period variable for reading tone/prompt data
   // (this is modified according to the connection type and also to support local playback)
   .VAR $tmr_period_tone_copy = TMR_PERIOD_TONE_COPY;

   // Rate matching data structure
   .VAR $sra_struct[$sra.STRUC_SIZE];
   .VAR $rate_match_disable = 0;
   .VAR $sra_rate_addr = $sra_struct + $sra.SRA_RATE_FIELD;

   // Statistics pointer tables (these pointers are copied to the statistics pointer array by the conn_init function)
   // (this fixed size array contains pointers to codec specific information)

#ifdef SBC_ENABLE
   .VAR $sbc_stats[$music_example.CODEC_STATS_SIZE] =
      &$sbc.sbc_common_data_array + $sbc.mem.SAMPLING_FREQ_FIELD,
      &$sbc.sbc_common_data_array + $sbc.mem.CHANNEL_MODE_FIELD,
      &$sbc.sbc_common_data_array + $sbc.mem.BITPOOL_FIELD,
      &$sbc.sbc_common_data_array + $sbc.mem.NROF_BLOCKS_FIELD,
      &$sbc.sbc_common_data_array + $sbc.mem.NROF_CHANNELS_FIELD,
      &$sbc.sbc_common_data_array + $sbc.mem.NROF_SUBBANDS_FIELD,
      &$sbc.sbc_common_data_array + $sbc.mem.ALLOCATION_METHOD_FIELD,
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

#ifdef MP3_ENABLE
   .VAR $mp3_stats[$music_example.CODEC_STATS_SIZE] =
      &$mp3dec.sampling_freq,                                  //
      &$mp3dec.mode,                                           //
      &$mp3dec.framelength,                                    // CODEC_STAT1
      &$mp3dec.bitrate,                                        // CODEC_STAT2
      &$mp3dec.frame_version,                                  // CODEC_STAT3
      &$mp3dec.frame_layer,                                    // CODEC_STAT4
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT5
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

#ifdef USB_ENABLE
   .VAR $usb_stats[$music_example.CODEC_STATS_SIZE] =
      &$music_example.SamplingRate,                            //
      &$M.system_config.data.ZeroValue,                        //
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT1
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT2
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT3
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT4
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT5
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

#ifdef ANALOGUE_ENABLE
   .VAR $analogue_stats[$music_example.CODEC_STATS_SIZE] =
      &$music_example.SamplingRate,                            //
      &$M.system_config.data.ZeroValue,                        //
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT1
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT2
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT3
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT4
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT5
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

#ifdef APTX_ENABLE
   .VAR $aptx_stats[$music_example.CODEC_STATS_SIZE] =
      &$music_example.SamplingRate,                            //
      &$music_example.aptx_channel_mode,                       //
      &$music_example.aptx_security_status,                    // CODEC_STAT1
      &$music_example.aptx_decoder_version,                    // CODEC_STAT2
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT3
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT4
      &$M.system_config.data.ZeroValue,                        // CODEC_STAT5
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

#ifdef AAC_ENABLE
   .VAR $aac_stats[$music_example.CODEC_STATS_SIZE] =
      &$music_example.SamplingRate,                            // Sampling frequency (from DAC config!)
      &$aacdec.sf_index,                                       // 0..15 - Index for sampling frequency
      &$aacdec.channel_configuration,                          // 1: mono, 2: stereo
      &$aacdec.audio_object_type,                              // 2: LC, 4: LTP, 5: SBR
      &$aacdec.extension_audio_object_type,                    //
      &$aacdec.sbr_present,                                    // 0: not SBR, 1: SBR
      &$aacdec.mp4_frame_count,                                // Count of MP4 frames
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
#ifdef APTX_ENABLE
   // initialise licensing subsystem
   call $Security.Initialize;
#endif
   // initialise the wallclock library
   call $wall_clock.initialise;
#if defined(DEBUG_ON)
   // initialise the profiler library
   call $profiler.initialise;
#endif
   // init DM_flash
   call $flash.init_dmconst;

#ifdef MP3_USE_EXTERNAL_MEMORY
   // Set up the external memory pointer tables (MP3 shares AAC memory)
   r1 = $mp3_ext_memory_ptrs;
   r0 = $aacdec.overlap_add_left;                  // 576
   M[r1 + $mp3dec.mem.OABUF_LEFT_FIELD] = r0;      // 576
   r0 = $aacdec.overlap_add_right;                 // 576
   M[r1 + $mp3dec.mem.OABUF_RIGHT_FIELD] = r0;     // 576
   r0 = $aacdec.buf_left;                          // 1024  Circular
   M[r1 + $mp3dec.mem.SYNTHV_LEFT_FIELD] = r0;     // 1024  Circular
   r0 = $aacdec.buf_right;                         // 1024  Circular
   M[r1 + $mp3dec.mem.SYNTHV_RIGHT_FIELD] = r0;    // 1024  Circular
   r0 = $aacdec.frame_mem_pool;                    // 1697
   M[r1 + $mp3dec.mem.GENBUF_FIELD] = r0;          // 576
   r0 = $aacdec.tmp_mem_pool;                      // 2504  Circular
   M[r1 + $mp3dec.mem.BITRES_FIELD] = r0;          // 650   Circular
#endif

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

   // intialize SPI communications library
   call $spi_comm.initialize;

   // Power Up Reset needs to be called once during program execution
   call $music_example.power_up_reset;

   r2 = $music_example.VMMSG.READY;
   r3 = $MUSIC_MANAGER_SYSID;
   // status
   r4 = M[$music_example.Version];
   r4 = r4 LSHIFT -8;
   call $message.send_short;

#ifdef SUB_ENABLE
   call $M.Subwoofer.subwoofer_init;
#endif // SUB_ENABLE

#ifdef LATENCY_REPORTING
   // reset encoded latency module
   r7 = &$encoded_latency_struct;
   call $latency.reset_encoded_latency;
#endif

#if defined SHAREME_ENABLE || defined TWS_ENABLE
   call $relay.init;
#endif


   // tell vm we're ready and wait for the go message
   call $message.send_ready_wait_for_go;

   // Initialize the USB/decoder according to the connection type (A2DP or USB)
   // (allows run-time selection of connection type)
   call $conn_init;

   // Configure the resampler according to the codec and DAC sampling rates
   call $config_resampler;

   // Configure the rate matching algorithm
   call $config_rate_matching;

#ifdef USB_ENABLE
   r8 = $usb_audio_in_copy_struc;
   call $config_usb;
#endif

   // start timer that copies output samples
   r1 = &$audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in;

   // Start a timer that copies USB/codec input data according to the connection type
   r1 = &$con_in_timer_struc;
   r2 = M[$tmr_period_con_copy];
   r3 = &$con_in_copy_handler;
   call $timer.schedule_event_in;

   // start timer that copies tone/prompt samples
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

      // Check Communication
      call $spi_comm.polled_service_routine;

        // Check the connection type (A2DP or USB/ANALOGUE) and process accordingly
        r0 = M[$app_config.io];

        #ifdef USB_ENABLE
            null = r0 - $USB_IO;
            if Z jump skip_a2dp_decode;
        #endif

        #ifdef ANALOGUE_ENABLE
            null = r0 - $ANALOGUE_IO;
            if Z jump skip_a2dp_decode;
        #endif

     start_profiler:
        // Start profiler
        r8 = &$DecoderMips_data_block;
        call $M.mips_profile.mainstart;

#if defined SHAREME_ENABLE || defined TWS_ENABLE
        r5 = &$relay_struc;
        call $relay.start;
#endif
        r5 = &$decoder_codec_stream_struc;
        call $codec.av_decode;

#if defined(TWS_ENABLE)
        // Do not perform silence insertion when TWS is active
        r0 = M[$relay.mode];
        null = r0 - $TWS_MASTER_MODE;
        if Z jump skip_silence_insertion;
        null = r0 - $TWS_SLAVE_MODE;
        if Z jump skip_silence_insertion;
#endif
           // If not stalled prime the number of samples for zero insertion
           r0 = M[$decoder_codec_stream_struc + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
           if NZ call $av_audio_out_silence_prime;

           // If stalled insert given number of zeros into audio buffer
           r0 = M[$decoder_codec_stream_struc + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
           if Z call $av_audio_out_silence_insert;

#if defined(TWS_ENABLE)
        skip_silence_insertion:
#endif

#if defined SHAREME_ENABLE || defined TWS_ENABLE
        r5 = &$relay_struc;
        call $relay.stop;
#endif

#ifdef TWS_WIRED_MODE_ENABLE
        null = M[$tws.wired_mode_enabled];
        if Z call $sra_calcrate;
#else
        call $sra_calcrate;
#endif

        #ifdef LATENCY_REPORTING
        Null = M[$M.configure_latency_reporting.enabled];
        if Z jump skip_latency_measurement;
           r7 = &$encoded_latency_struct;
           call $latency.calc_encoded_latency;
        skip_latency_measurement:
        #endif

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

        jump done_decode;

    skip_a2dp_decode:

    #if defined(USB_ENABLE) || defined(ANALOGUE_ENABLE)
        call $sra_calcrate;
        #ifdef TWS_WIRED_MODE_ENABLE
        r0 = M[$relay.mode];
        null = r0 - $TWS_MASTER_MODE;
        if Z jump start_profiler;
        #endif
    #endif

    done_decode:

    #ifdef SUB_ENABLE
       // if esco sub is connected then timing is controlled by sco connection
       r0 = M[$sub_link_port];
       Null = r0 - $AUDIO_ESCO_SUB_OUT_PORT;
       if NZ jump not_esco_sub;
          // if we have ADC input, the DSP's processing is scheduled.
          // if we have USB input, USB runs when we have enough data
          r0 = M[$app_config.io];
          null = r0 - $USB_IO;
          if Z jump usb_input;
          call $frame_sync.1ms_delay;
          call $M.Subwoofer.esco_preprocess;
          jump not_esco_sub;
       usb_input:
          r0 = &$usb_sub_esco_process;
          M[$sub_app_esco_func] = r0;
       not_esco_sub:
    #endif // SUB_ENABLE

      r3 = M[$music_example.frame_processing_size];

      r0 = $audio_out_left_cbuffer_struc;
      call $cbuffer.calc_amount_data;
      null = r0 - r3;
      if NEG jump frame_loop;

      // check for space
      r0 = $dac_out_left_cbuffer_struc;
      call $cbuffer.calc_amount_space;
      null = r0 - r3;
      if NEG jump frame_loop;

      r0 = $audio_out_right_cbuffer_struc;
      call $cbuffer.calc_amount_data;
      null = r0 - r3;
      if NEG jump frame_loop;
      Null = M[$music_example.stereo_processing];
      if Z jump mono_process;

        r0 = $dac_out_right_cbuffer_struc;
        call $cbuffer.calc_amount_space;
        null = r0 - r3;
        if NEG jump frame_loop;

mono_process:
   #ifdef SUB_ENABLE
      call $M.Subwoofer.synchronise;
   #endif

   process:
   #if defined(USB_ENABLE)
      call $jitter_buffering;
      Null = M[$M.jitter_buffering.is_buffering];
      if NZ jump frame_loop;
   #endif
      call $music_example_process;

   #ifdef SUB_ENABLE
      r0 = M[$sub_link_port];
      Null = r0 - $AUDIO_ESCO_SUB_OUT_PORT;
      if NZ jump check_l2cap_sub;

      Null = M[$sub_app_esco_func];
      if Z call $M.Subwoofer.esco_post_process;

      check_l2cap_sub:
      // if we have an L2CAP port open for sub channel, downsample output from frame processing sub channel
      r0 = M[$sub_link_port];
      Null = r0 - $AUDIO_L2CAP_SUB_OUT_PORT;
      if NZ jump frame_loop;

      call $downsample_sub_to_1k2;
      
      // if don't have enough data in 'sub_out_1k2' buffer for an L2CAP sub packet, then keep calm and carry on
      r0 = &$sub_out_1k2_cbuffer_struc;
      call $cbuffer.calc_amount_data;
      null = r0 - 18;
      if neg jump frame_loop;
      call $M.Subwoofer.l2cap_handler;      // create sub packet and copy to port
      
      // check again if have enough data for another packet
      r0 = &$sub_out_1k2_cbuffer_struc;
      call $cbuffer.calc_amount_data;
      null = r0 - 18;
      if neg jump frame_loop;
      call $M.Subwoofer.l2cap_handler;      // create sub packet and copy to port
      
   #endif // SUB_ENABLE

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

   // reset the sync flag to wake from idling in low power mode
   r0 = M[$music_example.sync_flag_ptr];
   M[r0] = Null;

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

   #if defined(SUB_ENABLE) || defined(LATENCY_REPORTING) || defined(TWS_ENABLE)
      #if defined(HARDWARE_RATE_MATCH)
         r8 = &$current_hw_rate;
         M[$latency_calc_current_warp] = r8;
      #else
         r8 = &$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
         r7 = &$audio_out_rate_adjustment_and_shift_op_mono.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
         Null = r2;
         if Z r8 = r7;
         M[$latency_calc_current_warp] = r8;
      #endif
   #endif //defined(SUB_ENABLE) || defined(LATENCY_REPORTING) || defined(TWS_ENABLE)    

   // run resampler
   r8 = &$dac_out_resampler_stereo_copy_struc;
   r7 = &$dac_out_resampler_mono_copy_struc;
   Null = M[$mono_stereo_mode];
   if Z r8 = r7;
   call $cbops.copy;

   // care for initial latency
   #ifdef SRA_TARGET_LATENCY
      call $adjust_initial_latency;
   #endif




   // aux data are read in another ISR,
   // if aux level is low do another read
   // here, no action if we already have good
   // amount of aux data
   call $tone_copy_extra;
  
   // copy to DACs
   r8 = M[$stereo_copy_struc_ptr];
   r7 = M[$mono_copy_struc_ptr];
   Null = M[$mono_stereo_mode];
   if Z r8 = r7;
   call $cbops.dac_av_copy;

   // Relay copy operatoin for ShareMe and TWS
#if  defined SHAREME_ENABLE || defined TWS_ENABLE
   
   
   // Check Relay Port
   r0 = $RELAY_PORT;
   call $cbuffer.is_it_enabled;
   if Z jump done_with_relay;
      // copy data to relay port
         
#ifdef TWS_ENABLE       
#ifdef TWS_RELAY_TIME
      r2 = M[$relay.mode];
      null = r2 - $TWS_MASTER_MODE;
      if NZ jump relay_only;

      r2 = M[$tws.timeout_cnt]; 
      r0 = r2+1;
      M[$tws.timeout_cnt] = r0;
      null = r2 - $TWS_RELAY_TIMEOUT;
      if NZ jump done_with_relay;
      
      M[$tws.timeout_cnt] = 0;
      relay_only:
#endif      
#endif
  
      r8 = &$relay_copy_struc;
      call $cbops.copy;

   done_with_relay:
        
#endif

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

// *****************************************************************************
// MODULE:
//    $tone_copy_extra
//
// DESCRIPTION:
//  extra copy from tone port
//
// *****************************************************************************
   $tone_copy_extra:
   // push rLink onto stack
   $push_rLink_macro;

   // no action if tone isn't active
   r0 = M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.INPUT_STATE_FIELD];
   r1 = M[$audio_out_tone_upsample_mono_mix.param + $cbops.auto_resample_mix.INPUT_STATE_FIELD];
   Null = M[$mono_stereo_mode];
   if Z r0 = r1;
   Null = r0;
   if Z jump $pop_rLink_and_rts;;
   
   // see if level is already good
   r0 = $tone_in_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r2 = M[$current_tone_sampling_rate];
   rMAC = r2 * (TMR_PERIOD_AUDIO_COPY);
   r2 = rMAC ASHIFT 13;
   r2 = r2 * (0.001536) (frac);
   Null = r0 - r2;
   if POS jump $pop_rLink_and_rts;
   
   // copy tone data from the port
   r8 = &$tone_in_copy_struc;
   r7 = $stereo_tone_in_copy_struc;
   Null = M[$stereo_tone];
   if NZ r8 = r7;
   call $cbops.copy;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
.ENDMODULE;

#ifdef AAC_ENABLE
// *****************************************************************************
// MODULE:
//    $set_aac_read_frame_function
//
// DESCRIPTION: set aac read frame function
//
// INPUTS:
//    None
// OUTPUTS:
//    None
// *****************************************************************************
.MODULE $M.set_aac_read_frame_function;
   .CODESEGMENT PM;
$set_aac_read_frame_function:
   // LATM for a2dp
   r0 = &$aacdec.latm_read_frame;
   // ADTS for local play back
   r1 = &$aacdec.adts_read_frame;
   Null = M[$local_encoded_play_back];
   if NZ r0 = r1;
   M[$aacdec.read_frame_function] = r0;
   rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $read_bytes_from_port
//
// DESCRIPTION: reads input data from 8-bit port
//
// INPUTS:
//  r8 = port_byte_read structure
// OUTPUTS:
//  None
// NOTES:
//   - assume trashes every register
//   - run this only inside an ISR
//   - this is for reading aac data from port
// *****************************************************************************
   .CONST $port_byte_read.INPUT_PORT_FIELD               0; // 8-bit configured data port
   .CONST $port_byte_read.OUTPUT_BUFFER_FIELD            1; // buffer to write (16-bit) words
   .CONST $port_byte_read.HALF_WORD_VALID_PTR_FIELD      2; // address holding half word validity
   .CONST $port_byte_read.STRUCT_SIZE                    3;

.MODULE $M.read_bytes_from_port;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
$read_bytes_from_port:
   // push rLink onto stack
   $push_rLink_macro;

   // read port level
   r0 = M[r8 + $port_byte_read.INPUT_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r7 = r0;

   // read space in the buffer
   r0 = M[r8 + $port_byte_read.OUTPUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   r6 = r0 + r0;

   // get half word pointers
   r5 = M[r8 + $port_byte_read.HALF_WORD_VALID_PTR_FIELD];

   // minus one byte if half word remained from previous write
   r6 = r6 + M[r5];

   // get number of bytes can read from port
   r2 = r6 - r7;
   if POS r6 = r6 - r2;

   // continue only if at least one byte to read
   r10 = r6;
   if LE jump end_read_data_port;

   // get codec input port read pointer
   r0 = M[r8 + $port_byte_read.INPUT_PORT_FIELD];
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   // get codec buffer write pointer
   r0 = M[r8 + $port_byte_read.OUTPUT_BUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   // see if a byte left in previous read
   Null = M[r5];
   if Z jump prev_half_word_done;
      // write (prev byte)|a new byte
      r0 = M[I4,-1];
      r0 = M[I4,0];
      r1 = M[I0,1];
      r0 = r0 + r1;
      M[I4,1] = r0;
      // reduce number of bytes to read
      r10 = r10 - 1;
      M[r5] = Null;
   prev_half_word_done:


   r4 = r10 AND 1;
   r10 = r10 LSHIFT -1;
   if Z jump read_loop_done;
   // read 2*r10 bytes
   // write r10 words
   r10 = r10 - 1;
   r2 = 8;
   M0 = 1;
   r0 = M[I0,M0];
   r1 = M[I0,M0];
   do read_port_loop;
      // wordn = byte2n|byte2n+1
      r3 = r0 LSHIFT r2, r0 = M[I0,M0];
      r3 = r3 + r1, r1 = M[I0,M0];
      M[I4,1] = r3;
   read_port_loop:
      // build and write last word
      r3 = r0 LSHIFT r2;
      r3 = r3 + r1;
      M[I4,1] = r3;
   read_loop_done:
   // update half word valid flag
   M[r5] = r4;
   if Z jump read_half_word_done;
      // write last byte in the port into half word var
      r0 = M[I0,1];
      r0 = r0 LSHIFT 8;
      M[I4,1] = r0;
   read_half_word_done:

   // update input port
   r0 = M[r8 + $port_byte_read.INPUT_PORT_FIELD];
   r1 = I0;
   call $cbuffer.set_read_address;
   L0 = 0;

   // update output buffer
   r0 = M[r8 + $port_byte_read.OUTPUT_BUFFER_FIELD];
   r1 = I4;
   call $cbuffer.set_write_address;
   L4 = 0;

   end_read_data_port:

  // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif
// *****************************************************************************
// MODULE:
//    $con_in_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the copying of data
//    from the input port (USB or A2DP)
//
// *****************************************************************************
.MODULE $M.con_in_copy_handler;
   .CODESEGMENT CON_IN_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   $con_in_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;

#ifdef LATENCY_REPORTING
   r0 = M[&$codec_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[$codec_packets_info_last_write_address] = r0;
#endif
   call $sra_tagtimes;

   // Get the connection type
   r0 = M[$app_config.io];

   // Check the connection type (A2DP or USB/ANALOGUE) and set the structure inputs appropriately
#ifdef USB_ENABLE
   null = r0 - $USB_IO;
   if NZ jump skip_usb_copy;

      // Copy encoded data from the USB port to the cbuffer
      r8 = &$usb_audio_in_copy_struc;
      r7 = $frame_sync.usb_in_stereo_audio_copy;
      call $run_usb_state_mc;

      jump copy_done;

   skip_usb_copy:
#endif

#ifdef ANALOGUE_ENABLE
   null = r0 - $ANALOGUE_IO;
   if NZ jump skip_analogue_copy;

      // Copy stereo pcm input data from the ports to the cbuffers
      r8 = &$analogue_audio_in_copy_struc;
      call $cbops.copy;

      jump copy_done;

   skip_analogue_copy:
#endif

#ifdef APTX_ENABLE
   .VAR byte0;
   .VAR byte1;
   .VAR byte0_flag;

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get amount of data (in bytes) in input port
   r0 = $CON_IN_PORT;
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
      M[($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = $BITMODE_8BIT_ENUM;

      // Read the second byte to complete the 16bit word
      r0 = M[($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA];
      r0 = r0 AND 0xff;
      M[byte1] = r0;

      // Update input port
      r0 = $CON_IN_PORT;
      r1 = ($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA;
      call $cbuffer.set_read_address;

      r0 = $CON_IN_PORT;
      call $cbuffer.calc_amount_data;

      // Switch to 16bit read mode
      r0 = $BITMODE_16BIT_ENUM + $BYTESWAP_MASK + $NOSIGNEXT_MASK;
      M[($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = r0;

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
#endif


#ifdef AAC_ENABLE
   r0 = M[$app_config.io];        // Get the run-time selection
   null = r0 - $AAC_IO;           // Is the AAC codec selected
   if NZ jump skip_aac_byte_read; // Skip if not AAC

   // for AAC read from 8-bit port, this will make sure no data will be left
   // in the port during pause mode
   .CONST $CODEC_IN_PORT_8BIT            ($CON_IN_PORT|$cbuffer.FORCE_8BIT_WORD);
   .VAR $aac_port_byte_read_struct[$port_byte_read.STRUCT_SIZE] =
      $CODEC_IN_PORT_8BIT,
      &$codec_in_cbuffer_struc,
      &$aacdec.write_bytepos;

   r8 = &$aac_port_byte_read_struct;
   call $read_bytes_from_port;

   jump input_read_done;
   skip_aac_byte_read:
#endif



   // Codec handling
   // Copy encoded data from the port to the cbuffer
   r8 = &$codec_in_copy_struc;
   call $cbops.copy;
   
input_read_done:


#ifdef APTX_ENABLE
   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get amount of data (in bytes) in input port
   r0 = $CON_IN_PORT;
   call $cbuffer.calc_amount_data;

   // Only 1 byte left?
   null = r1 - 1;
   if NZ jump skip_odd_byte;

      // Switch to 8bit read mode
      M[($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = $BITMODE_8BIT_ENUM;

      // Read the odd byte (byte0)
      r0 = M[($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA];
      r0 = r0 AND 0xff;
      M[byte0] = r0;

      // Update input port (this lets the firmware send more data)
      r0 = $CON_IN_PORT;
      r1 = ($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_DATA;
      call $cbuffer.set_read_address;

      // Switch to 16bit read mode
      r0 = $BITMODE_16BIT_ENUM + $BYTESWAP_MASK + $NOSIGNEXT_MASK;
      M[($CON_IN_PORT & $cbuffer.PORT_NUMBER_MASK) + $READ_PORT0_CONFIG] = r0;

      // Flag an odd byte (byte0) has been read
      r0 = 1;
      M[byte0_flag] = r0;

   skip_odd_byte:
#endif

   // just for debugging, will be removed
   .VAR $codec_level;
   r0 = &$codec_in_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   M[$codec_level] = r0;

   #ifdef SRA_TARGET_LATENCY
      // mark the arrival of first packet
      Null = M[$first_packet_received];
      if NZ jump first_packet_done;
      r0 = M[&$codec_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
      Null = r0 - M[$codec_packets_info_last_write_address];
      if Z jump first_packet_done;
         r0 = 1;
         r2 = M[$TIMER_TIME];
         M[$first_packet_received] = r0;
         M[$first_packet_time] = r2;
     first_packet_done:
   #endif

   copy_done:

  #if defined(HARDWARE_RATE_MATCH)
      // If rate matching is disabled don't apply H/W rate correction
      null = M[&$rate_match_disable];
      if Z call $apply_hardware_warp_rate;
  #endif

#ifdef LATENCY_REPORTING
   Null = M[$M.configure_latency_reporting.enabled];
   if Z jump skip_packet_detection;
      call $media_packet_boundary_detection;
   skip_packet_detection:
#endif
   // post another timer event
   r1 = &$con_in_timer_struc;
   r2 = M[$tmr_period_con_copy];
   r3 = &$con_in_copy_handler;
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
//       bit9: pcm playback, releavant only when b8==1
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
   M[$max_clock_mismatch] = r2;                       // Maximum clock mismatch to compensate (r2/10)% (Bit7==1 disables the rate control, e.g 0x80)
   M[$long_term_mismatch] = r3;                       // bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
   // b8 b9    encoded   pcm
   // 0  x       N        N
   // 1  0       Y        N
   // 1  1       N        Y
   r1 = r4 AND $PCM_PLAYBACK_MASK;                    // Mask for pcm/coded bit
   r2 = r1 XOR $PCM_PLAYBACK_MASK;
   r0 = r4 AND $LOCAL_PLAYBACK_MASK;                  // Mask for local file play back info
   r2 = r2 * r0 (int)(sat);
   M[$local_encoded_play_back] = r2;                  // encoded play back
   r3 = 0x1;
   r1 = r1 * r0 (int)(sat);
   if NZ r1 = r3;
   M[$aux_input_stream_available] = r1;               // aux pcm stream play back

   r0 = r4 AND $AUDIO_IF_MASK;                        // Mask for audio i/f info
   M[$audio_if_mode] = r0;                            // Set audio output interface type

#if defined(SUB_ENABLE) || defined(LATENCY_REPORTING) || defined(TWS_ENABLE)
      // update inverse of dac sample rate
      push rLink;
      r0 = M[$current_dac_sampling_rate];
      call $latency.calc_inv_fs;
      M[$inv_dac_fs] = r0;
      pop rLink;
#endif
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
//  r1 = codec sampling rate/10 (e.g. 44100Hz is given by r1=4410)
//  r2 =
//  r3 =
//  r4 =
// *****************************************************************************
.MODULE $M.set_codec_rate_from_vm;
   .CODESEGMENT SET_CODEC_RATE_FROM_VM_PM;

$set_codec_rate_from_vm:

   // Mask sign extension
   r1 = r1 AND 0xffff;

   // Scale to get sampling rate in Hz
   r1 = r1 * 10 (int);

   // Store the codec sampling rate
   M[$current_codec_sampling_rate] = r1;
#if defined(SUB_ENABLE) || defined(LATENCY_REPORTING) || defined(TWS_ENABLE)
      // update inverse of codec sample rate
      push rLink;
      r0 = M[$current_codec_sampling_rate];
      call $latency.calc_inv_fs;
      M[$inv_codec_fs] = r0;
      pop rLink;
   #endif

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
   r4 = M[$local_encoded_play_back];                 // NZ means local file play back
   if Z jump is_remote_stream;
      // Set the timer period for local play back
      r0 = LOCAL_TMR_PERIOD_CODEC_COPY;
      M[$tmr_period_con_copy] = r0;

      // Force rate matching to be disabled for local playback
      r0 = 1;
      M[&$rate_match_disable] = r0; // Enable: 0, Disable: 1

   is_remote_stream:

   // If rate matching is disabled don't update rate
   null = M[&$rate_match_disable];
   if NZ jump end;

   // set maximum rate for clock mismatch compensation
   r2 = r2 AND 0x7F;
   r1 = r2 - 4;         // min 0.3% percent by default
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

// *****************************************************************************
//
// Master reset routine, called to clear garbage samples during a pause
//
// *****************************************************************************
.MODULE $M.master_app_reset;
   .CODESEGMENT MASTER_APP_RESET_PM;
   .DATASEGMENT DM;


   $master_app_reset:

   // push rLink onto stack
   $push_rLink_macro;

   // local play back?
   Null = M[$local_encoded_play_back];
   if Z jump pause_happened;

   // notify VM about end of play_back
   r2 = PLAY_BACK_FINISHED_MSG;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send_short;
   M[$local_encoded_play_back] = 0;
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

   // re-initialise audio processing
   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;

   // Clear EQ delay memories
   r4 = &$M.system_config.data.filter_reset_table;
   call $frame_sync.run_function_table;

   #ifdef LATENCY_REPORTING
      r7 = &$encoded_latency_struct;
      call $latency.reset_encoded_latency;
      M[$first_packet_received] = 0;
      M[$sra_struct +  $sra.TARGET_LATENCY_MS_FIELD] = 0;
   #endif

   call $unblock_interrupts;

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
// *****************************************************************************
.MODULE $M.apply_hardware_warp_rate;
   .CODESEGMENT APPLY_WARP_RATE_PM;
   .DATASEGMENT DM;

   $apply_hardware_warp_rate:

   // push rLink onto stack
   $push_rLink_macro;

  .CONST HW_APPLY_WARP_RATE_TMR_MS              64;   // timer period to apply hardware warp rate (ms)
  .CONST HW_APPLY_WARP_MOVING_STEP              64;   // max rate change in each period (Q.23)

  .VAR $current_hw_rate = 0;
  .VAR $rate_apply_cntr;

   // see if time to apply hw warp rate
   r0 = M[$rate_apply_cntr];
   r0 = r0 + 1;
   M[$rate_apply_cntr] = r0;

   // Get the connection type
   r2 = M[$app_config.io];

// Check the connection type (A2DP or USB/ANALOGUE) and set the warp
#ifdef USB_ENABLE
   null = r2 - $USB_IO;
   if NZ jump skip_usb_warp;

      r1 = r0 - ((HW_APPLY_WARP_RATE_TMR_MS*1000)/TMR_PERIOD_USB_IN_COPY);

      jump warp_done;

   skip_usb_warp:
#endif

#ifdef ANALOGUE_ENABLE
   null = r2 - $ANALOGUE_IO;
   if NZ jump skip_analogue_warp;

      r1 = r0 - ((HW_APPLY_WARP_RATE_TMR_MS*1000)/TMR_PERIOD_ANALOGUE_IN_COPY);

      jump warp_done;

   skip_analogue_warp:
#endif

   // Handle CODECs
   r1 = r0 - ((HW_APPLY_WARP_RATE_TMR_MS*1000)/TMR_PERIOD_CODEC_COPY);

   warp_done:

   Null = r1;
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
//    $sra.MAX_RATE_FIELD                         4;    //input: maximum possible rate
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
// TRASHES: r0, r10, I0 and those trashed by the codec initialise functions
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

#ifdef USB_ENABLE
   // Check the connection type (A2DP or USB) and initialize accordingly
   null = r0 - $USB_IO;
   if NZ jump skip_usb_conn_init;

      // ------------------------------------------------------------------------
      // Set up the Rate Adaptation for USB

      // Set up the SRA struc for the USB connection
      r0 = (SRA_AVERAGING_TIME*1000000)/TMR_PERIOD_USB_IN_COPY;
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      r0 = $CON_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = r0;
      r0 = &$audio_out_left_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = &$dac_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = DEFAULT_MAXIMUM_CLOCK_MISMATCH_COMPENSATION;
      M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
      r0 = 48000*SRA_AVERAGING_TIME;
      M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;

      // ------------------------------------------------------------------------
      // Initialize the USB timer and codec type for USB

      // Initialize the timer period
      r0 = TMR_PERIOD_USB_IN_COPY;
      M[$tmr_period_con_copy] = r0;

      // ------------------------------------------------------------------------
      // Override the statistics table pointers for USB

      // Initialise the statistics pointer table
      I0 = $usb_stats;
      call $copy_codec_stats_pointers;

#if defined(TWS_ENABLE)
      // Should Shareme handle Analogue and USB??
   #ifdef SBC_ENABLE
      r0 = $sbc.sbc_common_data_array + $sbc.mem.GET_BITPOS_FIELD;
      M[$relay_struc + $relay.CODEC_GET_BITPOS] = r0;
      r0 = $sbcdec.getbits;
      M[$relay_struc + $relay.CODEC_GETBITS] = r0;
   #endif
   
      // Set up the SRA struc for the A2DP connection
      r0 = (SRA_AVERAGING_TIME*1000000)/TMR_PERIOD_USB_IN_COPY;
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      r0 = $CON_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = Null;
      
      r0 = &$codec_in_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      
      r0 = &$audio_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      
      Null = M[$current_dac_sampling_rate];
      if NZ jump sra_conf_done1;
         r0 = DEFAULT_MAXIMUM_CLOCK_MISMATCH_COMPENSATION;
         M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
         r0 = 48000*SRA_AVERAGING_TIME;
         M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;
         
   sra_conf_done1:
#endif

      jump exit;

   skip_usb_conn_init:
#endif

#ifdef ANALOGUE_ENABLE
   null = r0 - $ANALOGUE_IO;
   if NZ jump skip_analogue_conn_init;

      // ------------------------------------------------------------------------
      // Set up the Rate Adaptation for analogue input

      // Set up the SRA struc for the analogue connection
      r0 = (SRA_AVERAGING_TIME*1000000)/TMR_PERIOD_ANALOGUE_IN_COPY;
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      r0 = $CON_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = r0;
      r0 = &$audio_out_left_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = &$dac_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = DEFAULT_MAXIMUM_CLOCK_MISMATCH_COMPENSATION;
      M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
      r0 = 48000*SRA_AVERAGING_TIME;
      M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;

      // ------------------------------------------------------------------------
      // Initialize the analogue timer and codec type for analogue

      // Initialize the timer period
      r0 = TMR_PERIOD_ANALOGUE_IN_COPY;
      M[$tmr_period_con_copy] = r0;

      // ------------------------------------------------------------------------
      // Override the statistics table pointers for analogue input

      // Initialise the statistics pointer table
      I0 = $analogue_stats;
      call $copy_codec_stats_pointers;

#if defined(TWS_ENABLE)
      // Should Shareme handle Analogue and USB??
   #ifdef SBC_ENABLE
      r0 = $sbc.sbc_common_data_array + $sbc.mem.GET_BITPOS_FIELD;
      M[$relay_struc + $relay.CODEC_GET_BITPOS] = r0;
      r0 = $sbcdec.getbits;
      M[$relay_struc + $relay.CODEC_GETBITS] = r0;
   #endif

#endif

      jump exit;

   skip_analogue_conn_init:
#endif

      // ------------------------------------------------------------------------
      // Set up the Rate Adaptation for A2DP

      // Set up the SRA struc for the A2DP connection
      r0 = (SRA_AVERAGING_TIME*1000000)/TMR_PERIOD_CODEC_COPY;
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      r0 = $CON_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = r0;
      r0 = &$codec_in_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      r0 = &$audio_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      Null = M[$current_dac_sampling_rate];
      if NZ jump sra_conf_done;
         r0 = DEFAULT_MAXIMUM_CLOCK_MISMATCH_COMPENSATION;
         M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
         r0 = 48000*SRA_AVERAGING_TIME;
         M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;
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

#ifdef SBC_ENABLE
      // Check the codec type and initialize accordingly
      null = r0 - $SBC_IO;
      if NZ jump skip_sbc;

         // Set up the decoder structure for SBC
         r0 = $sbcdec.frame_decode;
         M[$decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
         r0 = $sbcdec.reset_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
         r0 = $sbcdec.silence_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;

         // Initialise the SBC decoder library, this will also set memory pointer
         // pass in the start of the decoder structure nested inside av_decode structure,
         // so init function will set the data object pointer field of it.
         r5 = $decoder_codec_stream_struc + $codec.av_decode.DECODER_STRUC_FIELD;
         call $sbcdec.init_static_decoder;

         // Initialise the statistics pointer table
         I0 = $sbc_stats;
         call $copy_codec_stats_pointers;

#if defined(SHAREME_ENABLE) || defined(TWS_ENABLE)
         r0 = $sbc.sbc_common_data_array + $sbc.mem.GET_BITPOS_FIELD;
         M[$relay_struc + $relay.CODEC_GET_BITPOS] = r0;
         r0 = $sbcdec.getbits;
         M[$relay_struc + $relay.CODEC_GETBITS] = r0;
#endif
         jump exit;

      skip_sbc:
#endif

#ifdef MP3_ENABLE
      null = r0 - $MP3_IO;
      if NZ jump skip_mp3;

#ifdef MP3_USE_EXTERNAL_MEMORY
         // Set up the external memory pointer tables
         r9 = $mp3_ext_memory_ptrs;
#endif
         // Set up the decoder structure for MP3
         r0 = $mp3dec.frame_decode;
         M[$decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
         r0 = $mp3dec.reset_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
         r0 = $mp3dec.silence_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;

         // Initialise the MP3 decoder library
         call $mp3dec.init_decoder;

         // Initialise the statistics pointer table
         I0 = $mp3_stats;
         call $copy_codec_stats_pointers;

#if defined(SHAREME_ENABLE) || defined(TWS_ENABLE)
         r0 = &$mp3dec.get_bitpos;
         M[$relay_struc + $relay.CODEC_GET_BITPOS] = r0;
         r0 = &$mp3dec.getbits;
         M[$relay_struc + $relay.CODEC_GETBITS] = r0;
#endif

         jump exit;

      skip_mp3:
#endif

#ifdef APTX_ENABLE
      null = r0 - $APTX_IO;
      if NZ jump skip_aptx;

         // Set up the decoder structure for APTX
         r0 = $aptx.decode;
         M[$decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
         r0 = $aptx.reset_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
         r0 = $aptx.silence_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;

         // Initialise the APTX decoder library
         call $aptx.init_decoder;

         // Initialise the statistics pointer table
         I0 = $aptx_stats;
         call $copy_codec_stats_pointers;

#if defined(SHAREME_ENABLE) || defined(TWS_ENABLE)
         r0=1;
         M[$relay_struc+$relay.IS_APTX_FIELD]=r0;     //Set APTX enabled in  relay struc
         r0 = $aptxdec.get_bitpos;
         M[$relay_struc + $relay.CODEC_GET_BITPOS] = r0;
         r0 = $aptxdec.getbits;
         M[$relay_struc + $relay.CODEC_GETBITS] = r0;
#endif
         jump exit;

      skip_aptx:
#endif

#ifdef AAC_ENABLE
      null = r0 - $AAC_IO;
      if NZ jump skip_aac;

         // Set up the decoder structure for AAC
         r0 = $aacdec.frame_decode;
         M[$decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
         r0 = $aacdec.reset_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
         r0 = $aacdec.silence_decoder;
         M[$decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;

         // Initialise the AAC decoder library
         call $aacdec.init_decoder;

         // set read frame function
         call $set_aac_read_frame_function;

         // Initialise the statistics pointer table
         I0 = $aac_stats;
         call $copy_codec_stats_pointers;

#if defined(SHAREME_ENABLE) || defined(TWS_ENABLE)
         r0 = $aacdec.get_bitpos;
         M[$relay_struc + $relay.CODEC_GET_BITPOS] = r0;
         r0 = $aacdec.getbits;
         M[$relay_struc + $relay.CODEC_GETBITS] = r0;
#endif


         jump exit;

      skip_aac:
#endif



         // Unknown codec
         jump $error;
   exit:

   jump $pop_rLink_and_rts;
.ENDMODULE;

#ifdef SRA_TARGET_LATENCY
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

   $push_rLink_macro;

   // no action if target latency has not been defined from vm
   r6 = 0;
   r8 = &$stereo_out_copy_struc;
   r7 = &$mono_out_copy_struc;
   Null = M[$target_latency_from_vm];
   if Z jump init_latency_done;

   // feature enabled for A2DP (SBC/MP3/AAC) only
   r0 = M[$app_config.io];
   #ifdef SBC_ENABLE
      // Check the codec type and initialize accordingly
      null = r0 - $SBC_IO;
      if Z jump init_latency_start;
   #endif

   #ifdef MP3_ENABLE
      // Check the codec type and initialize accordingly
      null = r0 - $MP3_IO;
      if Z jump init_latency_start;
   #endif

   #ifdef AAC_ENABLE
      // Check the codec type and initialize accordingly
      null = r0 - $AAC_IO;
      if Z jump init_latency_start;
   #endif
   jump init_latency_done;
  init_latency_start:

   // jump to proper state handler
   r6 = M[$init_latency_state];
   r0 = M[$init_latency_table + r6];
   jump r0;

   il_idle:
   // idle state:
   // copy silence and
   // stay here until first packet received
   r8 = $stereo_sil_out_copy_struc;
   r7 = $mono_sil_out_copy_struc;
   Null = M[$first_packet_received];
   if Z jump init_latency_done;

   il_wait:
   // wait state:
   // play silence and
   // wait until 'target_latency' has passed since receiving first packet
   // then go to play mode
   r6 = 1;
   r8 = $stereo_sil_out_copy_struc;
   r7 = $mono_sil_out_copy_struc;
   r0 = M[$first_packet_time];
   r1 = M[$TIMER_TIME];
   r1 = r1 - r0;
   if NEG r1 = -r1;
   r0 = M[$target_latency_from_vm];
   r1 = r1 * 0.001(frac);
   Null = r1 - r0;
   if NEG jump init_latency_done;
   // init time passed, enable target latency
   M[$sra_struct +  $sra.TARGET_LATENCY_MS_FIELD] = r0;
   r0 = &$encoded_latency_struct + $encoded_latency.TOTAL_LATENCY_US_FIELD;
   M[$sra_struct +  $sra.CURRENT_LATENCY_PTR_FIELD] = r0;
   // and start play

   il_play:
   // play mode:
   // play audio
   // go tpo pause mode when decoder stalls
   M[$no_audio_counter] = 0;
   r6 = 2;
   r8 = &$stereo_out_copy_struc;
   r7 = &$mono_out_copy_struc;
   Null = M[$decoder_codec_stream_struc + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
   if NZ jump init_latency_done;
   r6 = 3;
   M[$first_packet_received] = 0;

   il_pause:
   // pause mode:
   // play remaining audio
   // if stall ends return back to play mode
   // if no audio to play go to idle and wait for new packets to arrive
   r8 = &$stereo_out_copy_struc;
   r7 = &$mono_out_copy_struc;
   Null = M[$decoder_codec_stream_struc + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
   if NZ jump il_play;
   r0 = &$dac_out_temp_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r1 = M[$no_audio_counter];
   r1 = r1 + 1;
   Null = r0 - 2;
   if POS r1 = 0;
   M[$no_audio_counter] = r1;
   Null = r1 - 2;
   if NEG jump init_latency_done;
   M[$sra_struct +  $sra.TARGET_LATENCY_MS_FIELD] = 0; // move to pause?
   r6 = 0;
   jump il_idle;

   init_latency_done:
   // set audio or silence buffer to play
   M[$stereo_copy_struc_ptr] = r8;
   M[$mono_copy_struc_ptr] = r7;
   M[$init_latency_state] = r6;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.ENDMODULE;
#endif

// *****************************************************************************
// MODULE:
//    $M.jitter_buffering
//
// DESCRIPTION:
//    Used to buffer data in front of frame processing to overcome jitter.
//    Currently used on USB input, but could be used on any input.
// ******************************************************************************
.MODULE $M.jitter_buffering;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR is_buffering = 1;

   $jitter_buffering:

   $push_rLink_macro;

   Null = M[is_buffering];
   if Z jump done;

   r0 = M[$app_config.io];
   Null = r0 - $USB_IO;
   if NZ jump clear_buffering_flag;

   // Set amount of jitter based on sampling rate.
   r0 = M[$current_codec_sampling_rate];
   Null = r0 - 48000;
   if NZ jump check_fs_44100;
   r4 = 0;  // 0 USB packets @ 48 kHz
   jump buffering_state;

check_fs_44100:
   Null = r0 - 44100;
   if NZ jump check_fs_32000;
   r4 = 132;  // 3 USB packets @ 44.1 kHz
   jump buffering_state;

check_fs_32000:
   Null = r0 - 32000;
   if NZ jump check_fs_22050;
   r4 = 0;  // 0 USB packets @ 32 kHz
   jump buffering_state;

check_fs_22050:
   Null = r0 - 22050;
   if NZ jump check_fs_16000;
   r4 = 132;  // 6 USB packets @ 22.050 kHz
   jump buffering_state;

check_fs_16000:
   Null = r0 - 16000;
   if NZ jump check_fs_8000;
   r4 = 0;  // 0 USB packets @ 16 kHz
   jump buffering_state;

check_fs_8000:
   Null = r0 - 8000;
   if NZ jump clear_buffering_flag;
   r4 = 0;  // 0 USB packets @ 8 kHz

buffering_state:
   // buffering state
   // stop buffering once extra data has been buffered
   r3 = M[$music_example.frame_processing_size];
   r3 = r3 + r4;
   r0 = $audio_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   null = r0 - r3;
   if NEG jump done;

clear_buffering_flag:
   // we've buffered enough or don't require a jitter buffer.
   M[is_buffering] = Null;

done:
    // pop rLink from stack
    jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $usb_sub_esco_process
//
// DESCRIPTION:
//    called in sub esco timer handler to process and copy sub data
//
// *****************************************************************************
.MODULE $M.usb_sub_esco_process;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   $usb_sub_esco_process:

   // push rLink onto stack
   $push_rLink_macro;
   r0 = M[$sub_link_port];
   Null = r0 - $AUDIO_ESCO_SUB_OUT_PORT;
   if NZ jump not_esco_sub;
         call $M.Subwoofer.esco_preprocess;
         call $M.Subwoofer.esco_post_process;
   not_esco_sub:
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.av_audio_out_silence_prime
//
// DESCRIPTION:
//    Prime the number of zero samples to insert
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHES: r0
//
// *****************************************************************************
.MODULE $M.av_audio_out_silence_prime;
   .CODESEGMENT PM;

   $av_audio_out_silence_prime:

   // Prime the number of silence data samples (125msec)
   r0 = M[$current_codec_sampling_rate];
   r0 = r0 ASHIFT -3;
   M[$M.av_audio_out_silence_insert.left_zero_samples] = r0;
   M[$M.av_audio_out_silence_insert.right_zero_samples] = r0;

   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.av_audio_out_silence_insert
//
// DESCRIPTION:
//    Insert silence samples into the audio_out buffers
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHES: r0, r1, r2, r3, r4, r10, I0, L0, DoLoop
//
// *****************************************************************************
.MODULE $M.av_audio_out_silence_insert;
    .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR left_zero_samples;
   .VAR right_zero_samples;

   $av_audio_out_silence_insert:

   // Push rLink onto stack
   $push_rLink_macro;

   // Insert silence data into the audio buffers (r3=zero count pointer, r4=cbuffer pointer)
   r3 = left_zero_samples;
   r4 = $audio_out_left_cbuffer_struc;
   call $av_insert_silence;

   r3 = right_zero_samples;
   r4 = $audio_out_right_cbuffer_struc;
   call $av_insert_silence;

   // Pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.av_insert_silence
//
// DESCRIPTION:
//    Insert silence samples into buffer
//
// INPUTS:
//    r3 = pointer to number of samples to insert
//    r4 = cbuffer structure address
//
// OUTPUTS:
//    none
//
// TRASHES: (for a cbuffer) r0, r1, r2, r10, I0, L0, DoLoop
//
// *****************************************************************************
.MODULE $M.av_insert_silence;
    .CODESEGMENT PM;

   $av_insert_silence:

   // Push rLink onto stack
   $push_rLink_macro;

   // Check for buffer space (and use as number of samples to insert)
   r0 = r4;
   call $cbuffer.calc_amount_space;

   // Get the number of zero samples to insert
   r1 = M[r3];
   r10 = r1;

   // Calculate max(number of samples to insert, buffer space)
   null = r0 - r10;
   if NEG r10 = r0;

   // Calculate and save the number of zero samples still to insert
   r0 = r1 - r10;
   M[r3] = r0;

   // Get audio cbuffer write address
   r0 = r4;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;

   // Zero words give silence
   r0 = 0;

   // Generate silence
   do audio_fill_loop;
     M[I0,1] = r0;
   audio_fill_loop:

   // Set new write address
   r0 = r4;
   r1 = I0;
   call $cbuffer.set_write_address;
   L0 = 0;

   // Pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
