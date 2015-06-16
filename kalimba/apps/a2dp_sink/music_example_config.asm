// *****************************************************************************
// %%fullcopyright(2009)        http://www.csr.com
// %%version
//
// $Change: 1905219 $  $DateTime: 2014/05/27 11:22:10 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    Static configuration file that includes function references and data
//    objects for the music_example system.
//
//    Developers can use the music_example system as a starting point for
//    development.
//
//    The functionality of the system can be expanded by adding entries to the
//    funtion table along with corresponding data object declarations.  New
//    modes of operation can be created by additional function tables.
//
//    This file, as shipped in the SDK, includes support for four modes.
//    STANDBY --
//    FULL -- Stereo 3d Enhancement, compander, dither, and PEQ are enabled
//    PASSTHROUGH -- Audio is routed from the decoded music stream to the dacs.
//                   No algorithms are enabled.
//    MONO -- The stereo decoded music stream is mixed down to one channel (left)
//            and is routed through the peq and compander and then to the dac.
//
//    INTERRUPT DRIVEN PROCESSES:
//    Data is transfered between firmware mmu buffers and dsp cbuffers via
//    operators, which run in the timer interrupt driven $audio_copy_handler
//    routines.
//
//    Data streams are synchronized using rate_match operators provided by
//    the frame_sync library.
//
//    MAIN APPLICATION PROCESSES:
//    Data is copied from the Decoded Music Outuput cbuffers to the output cbuffers
//    using the stereo_3d_enhancement function in full processing mode or through
//    the stream_copy function if stereo_3d_enhancement is not defined or in any other
//    mode.
//    These routines execute when a block size of data is available.
//
//    Tones are mixed with the left and right input signals using the
//    $cbops.auto_upsample_and_mix operator defined in codec_decoder.asm
//
// *****************************************************************************
#include "music_example.h"
#include "music_manager_config.h"
#include "audio_proc_library.h"
#include "cbops_library.h"
#include "codec_library.h"
#include "core_library.h"
#include "codec_decoder.h"
#include "sr_adjustment.h"
#include "frame_sync_buffer.h"
#include "relay_conn.h"

#define MAX_NUM_SPKR_EQ_STAGES      (5)
#define MAX_NUM_BOOST_EQ_STAGES     (1)
#define MAX_NUM_USER_EQ_STAGES      (5)

#define MAX_NUM_SPKR_EQ_BANKS       (1)
#define MAX_NUM_BOOST_EQ_BANKS      (1)
#define MAX_NUM_USER_EQ_BANKS       (7)

#if (MAX_NUM_SPKR_EQ_BANKS != 1)
    #error Number of Speaker Eq banks is not 1 - Mulitple bank switching not supported for Speaker Eq
#endif

#if (MAX_NUM_BOOST_EQ_BANKS != 1)
    #error Number of Bass Boost Eq banks is not 1 - Mulitple bank switching not supported for Bass boost Eq
#endif

.MODULE $M.system_config.data;
   .DATASEGMENT DM;

   // Temp Variable to handle disabled modules.
   .VAR  ZeroValue = 0;
   .VAR  OneValue = 1.0;
   .VAR  HalfValue = 0.5;
   .VAR  config;
   .VAR  MinusOne = -1;

   .VAR/DMCONST16  DefaultParameters[] =
   #include "music_manager_defaults.dat"
   ;

   // Parameter to Module Map
   .VAR/DM2 ParameterMap[] =

#if uses_STEREO_ENHANCEMENT
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,                  &stereo_3d_obj + $stereo_3d_enhancement.SE_CONFIG_FIELD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_REFLECTION_DELAY,        &stereo_3d_obj + $stereo_3d_enhancement.REFLECTION_DELAY_SAMPLES_FIELD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SE_MIX,                  &stereo_3d_obj + $stereo_3d_enhancement.MIX_FIELD,
#endif

#if uses_BASS_MANAGER
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_CONFIG,     &bass_manager_coefs + $bass_management.COEF_CONFIG,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_FREQ,  &bass_manager_coefs + $bass_management.COEF_FREQ_PARAM,
      #ifdef SPDIF_ENABLE
      // use set 2 for SPDIF app
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B1,    &bass_manager_coefs + $bass_management.COEF_A1,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B2,    &bass_manager_coefs + $bass_management.COEF_A2,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B3,    &bass_manager_coefs + $bass_management.COEF_A3,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B4,    &bass_manager_coefs + $bass_management.COEF_A4,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B5,    &bass_manager_coefs + $bass_management.COEF_A5,
      #else
      // use set 1 for apps with no LFE channel
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A1,    &bass_manager_coefs + $bass_management.COEF_A1,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A2,    &bass_manager_coefs + $bass_management.COEF_A2,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A3,    &bass_manager_coefs + $bass_management.COEF_A3,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A4,    &bass_manager_coefs + $bass_management.COEF_A4,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A5,    &bass_manager_coefs + $bass_management.COEF_A5,
      #endif
#endif

#if uses_COMPANDER
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,                  &cmpd100_obj_44kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,                  &cmpd100_obj_48kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_THRESHOLD1,       &cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_THRESHOLD1,       &cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1,     &cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_THRESHOLD1,        &cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_EXPAND_RATIO1,       &cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LINEAR_RATIO1,       &cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1,     &cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LIMIT_RATIO1,        &cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1,       &cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_DECAY_TC1,        &cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1,       &cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_DECAY_TC1,        &cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1,     &cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1,      &cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1,        &cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_DECAY_TC1,         &cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_MAKEUP_GAIN1,            &cmpd100_obj_44kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_THRESHOLD2,       &cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_THRESHOLD2,       &cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2,     &cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_THRESHOLD2,        &cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_EXPAND_RATIO2,       &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LINEAR_RATIO2,       &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2,     &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LIMIT_RATIO2,        &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2,       &cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_DECAY_TC2,        &cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2,       &cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_DECAY_TC2,        &cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2,     &cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2,      &cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2,        &cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_DECAY_TC2,         &cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_MAKEUP_GAIN2,            &cmpd100_obj_48kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
#endif

      // signal detector in stereo signal path for use in products which need to know whether signal is present (eg soundbars which need to comply with EUP directive in EU

      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SIGNAL_DETECT_THRESH,    &$signal_detect_op_coefs + $cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SIGNAL_DETECT_TIMEOUT,   &$signal_detect_op_coefs + $cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME,

#if uses_DITHER
      // Update both the stereo and mono operators with the noise shape field
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE,      &dithertype,
#endif

      // enable or disable the hard-limiter when applying volumes
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,                  &stereo_volume_and_limit_obj + $volume_and_limit.OFFSET_CONTROL_WORD_FIELD,
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,                  &mono_volume_and_limit_obj + $volume_and_limit.OFFSET_CONTROL_WORD_FIELD,
#ifdef SUB_ENABLE
      &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,                  &sub_volume_and_limit_obj + $volume_and_limit.OFFSET_CONTROL_WORD_FIELD,
#endif
      0;
   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.MUSIC_MANAGER.PARAMETERS.STRUCT_SIZE)];

// -----------------------------------------------------------------------------
// DATA OBJECTS USED WITH PROCESSING MODULES
//
// This section would be updated if more processing modules with data objects
// were to be added to the system.

// Data object used with $stream_copy.pass_thru function
     .VAR pass_thru_obj[$M.audio_proc.stereo_copy.STRUC_SIZE] =
    &stream_map_left_in,                          // INPUT_CH1_PTR_BUFFER_FIELD
    &stream_map_right_in,                         // INPUT_CH2_PTR_BUFFER_FIELD
    &stream_map_left_out,                         // OUTPUT_CH1_PTR_BUFFER_FIELD
    &stream_map_right_out;                        // OUTPUT_CH2_PTR_BUFFER_FIELD

// Data object used with $music_example.mix function
   .VAR One_Half = 0.5;
   .VAR mix_dm1[$M.audio_proc.stream_mixer.STRUC_SIZE] =
    &stream_map_left_in,                          // INPUT_CH1_PTR_BUFFER_FIELD
    &stream_map_right_in,                         // INPUT_CH2_PTR_BUFFER_FIELD
    &stream_map_left_out,                         // OUTPUT_CH1_PTR_BUFFER_FIELD
    &HalfValue,                                   // OFFSET_PTR_CH1_MANTISSA
    &HalfValue,                                   // OFFSET_PTR_CH2_MANTISSA
    &ZeroValue;                                   // OFFSET_PTR_EXPONENT

#ifdef SUB_ENABLE
   .VAR sub_mix_dm1[$M.audio_proc.stream_mixer.STRUC_SIZE] =
    &stream_map_left_out,                          // INPUT_CH1_PTR_BUFFER_FIELD
    &stream_map_right_out,                         // INPUT_CH2_PTR_BUFFER_FIELD
    &stream_map_left_out,                          // OUTPUT_CH1_PTR_BUFFER_FIELD
    &HalfValue,                                    // OFFSET_PTR_CH1_MANTISSA
    &HalfValue,                                    // OFFSET_PTR_CH2_MANTISSA
    &ZeroValue;
#endif // #ifdef SUB_ENABLE

#ifdef uses_SPKR_EQ

    /* object for currently running EQs */
    // SP.  Bypass mask moved to (r8) input of processing function

   .VAR/DM2 spkr_eq_left_dm2[PEQ_OBJECT_SIZE(MAX_NUM_SPKR_EQ_STAGES)] =
      &stream_map_left_out,           // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_out,           // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_SPKR_EQ_STAGES,         // MAX_STAGES_FIELD
      0,                              // PARAM_PTR_FIELD
      0 ...;

   .VAR/DM2 spkr_eq_right_dm2[PEQ_OBJECT_SIZE(MAX_NUM_SPKR_EQ_STAGES)] =
      &stream_map_right_out,          // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_right_out,          // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_SPKR_EQ_STAGES,         // MAX_STAGES_FIELD
      0,                              // PARAM_PTR_FIELD
      0 ...;

    .VAR/DM2 spkr_eq_bank_select[1 + (2 * MAX_NUM_SPKR_EQ_BANKS)] =
        MAX_NUM_SPKR_EQ_BANKS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_CONFIG,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_CONFIG;

#endif  // uses_SPKR_EQ


#ifdef uses_BASS_BOOST

    /* object for currently running EQs */
    // SP.  Bypass mask moved to (r8) input of processing function

   .VAR/DM2 boost_eq_left_dm2[PEQ_OBJECT_SIZE(MAX_NUM_BOOST_EQ_STAGES)] =
      &stream_map_left_out,           // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_out,           // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_BOOST_EQ_STAGES,        // MAX_STAGES_FIELD
      0,                              // PARAM_PTR_FIELD
      0 ...;

   .VAR/DM2 boost_eq_right_dm2[PEQ_OBJECT_SIZE(MAX_NUM_BOOST_EQ_STAGES)] =
      &stream_map_right_out,           // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_right_out,           // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_BOOST_EQ_STAGES,         // MAX_STAGES_FIELD
      0,                               // PARAM_PTR_FIELD
      0 ...;


    .VAR/DM2 boost_eq_bank_select[1 + (2 * MAX_NUM_BOOST_EQ_BANKS)] =
        MAX_NUM_BOOST_EQ_BANKS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_CONFIG,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_CONFIG;

#endif  // uses_BASS_BOOST


#ifdef uses_USER_EQ

    /* object for currently running EQs */
   .VAR/DM2 user_eq_left_dm2[PEQ_OBJECT_SIZE(MAX_NUM_USER_EQ_STAGES)] =
      &stream_map_left_out,          // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_out,          // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_USER_EQ_STAGES,        // MAX_STAGES_FIELD
      &UserEqCoefsA,                 // PARAM_PTR_FIELD
      0 ...;

    /* object for currently running EQs */
    .VAR/DM2 user_eq_right_dm2[PEQ_OBJECT_SIZE(MAX_NUM_USER_EQ_STAGES)] =
      &stream_map_right_out,         // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_right_out,         // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_USER_EQ_STAGES,        // MAX_STAGES_FIELD
      &UserEqCoefsA,                 // PARAM_PTR_FIELD
      0 ...;

    .var UserEqCoefsA[33] =
        0x000000,                                               // [0] = config (no eq bands)
        0x000001,                                               // [1] = gain exponent
        0x400000,                                               // [2] = gain mantissa
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [ 3... 7] = stage 1 (b2,b1,b0,a2,a1)
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [ 8...12] = stage 2
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [13...17] = stage 3
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [18...22] = stage 4
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [23...27] = stage 5
        0x000001, 0x000001, 0x000001, 0x000001, 0x000001;       // [28...32] = scales

    .var UserEqCoefsB[33] =
        0x000000,                                               // [0] = config (no eq bands)
        0x000001,                                               // [1] = gain exponent
        0x400000,                                               // [2] = gain mantissa
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [ 3... 7] = stage 1 (b2,b1,b0,a2,a1)
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [ 8...12] = stage 2
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [13...17] = stage 3
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [18...22] = stage 4
        0x000000, 0x000000, 0x400000, 0x000000, 0x000000,       // [23...27] = stage 5
        0x000001, 0x000001, 0x000001, 0x000001, 0x000001;       // [28...32] = scales

    .var UserEqInitTable[] =
        &user_eq_left_dm2,
        &user_eq_right_dm2;

     // 6 configs
    .VAR/DM2 user_eq_bank_select[1 + MAX_NUM_USER_EQ_BANKS] =
        MAX_NUM_USER_EQ_BANKS,
        0,  // index 0 = flat response (no eq)
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_NUM_BANDS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_NUM_BANDS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_NUM_BANDS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_NUM_BANDS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_NUM_BANDS,
        &CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_NUM_BANDS;

#endif


#if uses_STEREO_ENHANCEMENT
   // ** Algorithm coefficients buffer
   // $coef_1_le  0.31; // should be 1.31, the value here is minused 1
   // $coef_2_le  -0.44;
   // $coef_1_ri  0.31;
   // $coef_2_ri  -0.44;
   // $coef_3_le  0.74;
   // $coef_4_le  -0.38;
   // $coef_3_ri  0.68;
   // $coef_4_ri  -0.34;
   // Inside buffer, they must be placed in the order that used by the algorithm
   // From left to right, coef 4 to 1
   .VAR/DM1 $stereo_3d_enhancement.coeff_buf[8] = -0.38, 0.74, -0.44, 0.31, -0.34, 0.68, -0.44, 0.31;

   .VAR/DMCIRC $stereo_3d_enhancement.delay1[$stereo_3d_enhancement.DELAY_BUFFER_SIZE];
   .VAR/DMCIRC $stereo_3d_enhancement.delay2[$stereo_3d_enhancement.DELAY_BUFFER_SIZE];


   .VAR $stereo_3d_enhancement_delay1_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($stereo_3d_enhancement.delay1),                                     // size
         &$stereo_3d_enhancement.delay1,                                            // read pointer
         &$stereo_3d_enhancement.delay1 + $stereo_3d_enhancement.REFLECTION_DELAY;  // write pointer
   .VAR $stereo_3d_enhancement_delay2_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($stereo_3d_enhancement.delay2),                                     // size
         &$stereo_3d_enhancement.delay2,                                            // read pointer
         &$stereo_3d_enhancement.delay2 + $stereo_3d_enhancement.REFLECTION_DELAY;  // write pointer
   .VAR/DM2 stereo_3d_obj[$stereo_3d_enhancement.STRUC_SIZE] =
      &stream_map_left_in,                                      // INPUT_CH1_PTR_BUFFER_FIELD
      &stream_map_right_in,                                     // INPUT_CH2_PTR_BUFFER_FIELD
      &stream_map_left_out,                                     // OUTPUT_CH1_PTR_BUFFER_FIELD
      stream_map_right_out,                                     // OUTPUT_CH2_PTR_BUFFER_FIELD
      &$stereo_3d_enhancement_delay1_cbuffer_struc,             // DELAY_1_BUFFER_FIELD
      &$stereo_3d_enhancement_delay2_cbuffer_struc,             // DELAY_2_BUFFER_FIELD
      &$stereo_3d_enhancement.coeff_buf,                        // COEFF_STRUC_FIELD
      $stereo_3d_enhancement.REFLECTION_DELAY,                  // REFLECTION_DELAY_SAMPLES_FIELD
      0,                                                        // MIX (currently not used)
      0,                                                        // SE_CONFIG
      $M.MUSIC_MANAGER.CONFIG.SPATIAL_BYPASS;                   // BYPASS_BIT_MASK_FIELD
#endif



#if uses_BASS_MANAGER

#define xEIGHTH_ORDER_LR_FILTERING

    #ifdef EIGHTH_ORDER_LR_FILTERING
        #define NUM_HF_STAGES       3
        #define NUM_LF_STAGES       4
    #else // TWELFTH ORDER FILTERING
        #define NUM_HF_STAGES       5
        #define NUM_LF_STAGES       6
    #endif

   // data memory for filtering (2 words for each filter instance)
   .var bass_manager_data[4*NUM_HF_STAGES + 2*NUM_LF_STAGES];

   // coefficients

   .var bass_manager_coefs[$bass_management.COEF_STRUCT_BASE_SIZE + NUM_HF_STAGES + NUM_LF_STAGES] =
        $bass_management.COEF_CONFIG.ENABLE_HPF
        + $bass_management.COEF_CONFIG.ENABLE_LPF,       // CONFIG
        0x100000,                   // A1 - L/R to bass channel
        0x200000,                   // A2 - L/R gain
#ifdef SPDIF_ENABLE
        0x653161,                   // A3 - LFE gain (10dB default)
#else
        0x000000,                   // A3 - LFE gain
#endif
        0x000000,                   // A4 - bass channel to L/R
        0x200000,                   // A5 - bass channel to Sub
        80,                         // FREQ_PARAM - frequency parameter supplied by UFE
        0.010471976,                // FREQ - calculated by intialisation routine
        NUM_HF_STAGES,
        NUM_LF_STAGES,
        #ifdef EIGHTH_ORDER_LR_FILTERING
            1.0/(2.0*0.517638090),      // HPF_Q1
            1.0/(2.0*0.707106781),      // HPF_Q2
            1.0/(2.0*1.931851653),      // HPF_Q3

            1.0/(2.0*0.541196100),      // LPF_Q1
            1.0/(2.0*1.306562965),      // LPF_Q2
            1.0/(2.0*0.541196100),      // LPF_Q3
            1.0/(2.0*1.306562965);      // LPF_Q4
        #else
            1.0/(2.0*0.517638090),      // HPF_Q1
            1.0/(2.0*0.707106781),      // HPF_Q2
            1.0/(2.0*1.931851653),      // HPF_Q3
            1.0/(2.0*0.517638090),      // HPF_Q4
            1.0/(2.0*1.931851653),      // HPF_Q5

            1.0/(2.0*0.517638090),      // LPF_Q1
            1.0/(2.0*0.707106781),      // LPF_Q2
            1.0/(2.0*1.931851653),      // LPF_Q3
            1.0/(2.0*0.517638090),      // LPF_Q4
            1.0/(2.0*0.707106781),      // LPF_Q5
            1.0/(2.0*1.931851653);      // LPF_Q6
        #endif

    .var bass_manager_bass_buffer[$music_example.NUM_SAMPLES_PER_FRAME];     // doesn't need to be circular

    .var bass_manager_struct[$bass_management.STRUCT_SIZE] =
        &stream_map_left_out,                   // LEFT_INPUT_PTR
        &stream_map_right_out,                  // RIGHT_INPUT_PTR
        &stream_map_left_out,                   // LEFT_OUTPUT_PTR
        &stream_map_right_out,                  // RIGHT_OUTPUT_PTR
#ifdef SPDIF_ENABLE
        &stream_map_lfe_in,                     // LFE_INPUT_PTR
#else
        0,                                      // LFE_INPUT_PTR
#endif
        &stream_map_sub_out,
        bass_manager_bass_buffer,               // BASS_BUFFER_PTR
        bass_manager_coefs,                     // COEFS_PTR
        bass_manager_data,                      // DATA_MEM_PTR
        &$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,   // PTR TO CONFIG WORD WHICH CONTAINS BYPASS BIT
        $M.MUSIC_MANAGER.CONFIG.BASS_MANAGER_BYPASS,    // BYPASS_BIT_MASK_FIELD
        &$current_codec_sampling_rate;          // ptr to codec sample rate

#endif  // uses_BASS_MANAGER



#if uses_COMPANDER
    .VAR/DM $cmpd_gain;
    .VAR cmpd100_obj_44kHz[$cmpd100.STRUC_SIZE] =
     64,                                                // OFFSET_CONTROL_WORD                0
     $M.MUSIC_MANAGER.CONFIG.COMPANDER_BYPASS,          // OFFSET_BYPASS_BIT_MASK             1
     &stream_map_left_out,                              // OFFSET_INPUT_CH1_PTR               2
     &stream_map_right_out,                             // OFFSET_INPUT_CH2_PTR               3
     &stream_map_left_out,                              // OFFSET_OUTPUT_CH1_PTR              4
     &stream_map_right_out,                             // OFFSET_OUTPUT_CH2_PTR              5
     0x080000,                                          // OFFSET_MAKEUP_GAIN q4.19           6
     &$cmpd_gain,                                       // OFFSET_GAIN_PTR q4.19              7
     0x800000,                                          // OFFSET_NEG_ONE q.23                8
     0.0625,                                            // OFFSET_POW2_NEG4 q.23              9
     0xF9B037,                                          // OFFSET_EXPAND_THRESHOLD q.23       10
     0xFA0541,                                          // OFFSET_LINEAR_THRESHOLD q.23       11
     0xFE56CB,                                          // OFFSET_COMPRESS_THRESHOLD q.23     12
     0xFF8070,                                          // OFFSET_LIMIT_THRESHOLD q.23        13
     0x100000,                                          // OFFSET_INV_EXPAND_RATIO q4.19      14
     0x080000,                                          // OFFSET_INV_LINEAR_RATIO q4.19      15
     0x015555,                                          // OFFSET_INV_COMPRESS_RATIO q4.19    16
     0x00CCCD,                                          // OFFSET_INV_LIMIT_RATIO q4.19       17
     0,                                                 // OFFSET_EXPAND_CONSTANT q4.19       18
     0,                                                 // OFFSET_LINEAR_CONSTANT q4.19       19
     0,                                                 // OFFSET_COMPRESS_CONSTANT q4.19     20
     4328332,                                           // OFFSET_EXPAND_ATTACK_TIME          21
     200465,                                            // OFFSET_EXPAND_DECAY_TIME           22
     4328332,                                           // OFFSET_LINEAR_ATTACK_TIME          23
     60649,                                             // OFFSET_LINEAR_DECAY_TIME           24
     6423342,                                           // OFFSET_COMPRESS_ATTACK_TIME        25
     40482,                                             // OFFSET_COMPRESS_DECAY_TIME         26
     8165755,                                           // OFFSET_LIMIT_ATTACK_TIME           27
     30380,                                             // OFFSET_LIMIT_DECAY_TIME            28
     $cmpd100.HEADROOM_OFFSET(2);                       // OFFSET_HEADROOM_COMPENSATION       29;

.VAR cmpd100_obj_48kHz[$cmpd100.STRUC_SIZE] =
     64,                                                // OFFSET_CONTROL_WORD                0
     $M.MUSIC_MANAGER.CONFIG.COMPANDER_BYPASS,          // OFFSET_BYPASS_BIT_MASK             1
     &stream_map_left_out,                              // OFFSET_INPUT_CH1_PTR               2
     &stream_map_right_out,                             // OFFSET_INPUT_CH2_PTR               3
     &stream_map_left_out,                              // OFFSET_OUTPUT_CH1_PTR              4
     &stream_map_right_out,                             // OFFSET_OUTPUT_CH2_PTR              5
     0x080000,                                          // OFFSET_MAKEUP_GAIN q4.19           6
     &$cmpd_gain,                                       // OFFSET_GAIN_PTR q4.19              7
     0x800000,                                          // OFFSET_NEG_ONE q.23                8
     0.0625,                                            // OFFSET_POW2_NEG4 q.23              9
     0xF9B037,                                          // OFFSET_EXPAND_THRESHOLD q.23       10
     0xFA0541,                                          // OFFSET_LINEAR_THRESHOLD q.23       11
     0xFE56CB,                                          // OFFSET_COMPRESS_THRESHOLD q.23     12
     0xFF8070,                                          // OFFSET_LIMIT_THRESHOLD q.23        13
     0x100000,                                          // OFFSET_INV_EXPAND_RATIO q4.19      14
     0x080000,                                          // OFFSET_INV_LINEAR_RATIO q4.19      15
     0x015555,                                          // OFFSET_INV_COMPRESS_RATIO q4.19    16
     0x00CCCD,                                          // OFFSET_INV_LIMIT_RATIO q4.19       17
     0,                                                 // OFFSET_EXPAND_CONSTANT q4.19       18
     0,                                                 // OFFSET_LINEAR_CONSTANT q4.19       19
     0,                                                 // OFFSET_COMPRESS_CONSTANT q4.19     20
     4081753,                                           // OFFSET_EXPAND_ATTACK_TIME          21
     184358,                                            // OFFSET_EXPAND_DECAY_TIME           22
     4081753,                                           // OFFSET_LINEAR_ATTACK_TIME          23
     55738,                                             // OFFSET_LINEAR_DECAY_TIME           24
     6177395,                                           // OFFSET_COMPRESS_ATTACK_TIME        25
     37200,                                             // OFFSET_COMPRESS_DECAY_TIME         26
     8089353,                                           // OFFSET_LIMIT_ATTACK_TIME           27
     27915,                                             // OFFSET_LIMIT_DECAY_TIME            28
     $cmpd100.HEADROOM_OFFSET(2);                       // OFFSET_HEADROOM_COMPENSATION       29;
#endif

// Creating 12dB headroom for processing modules, the headroom will be
// compensated in volume module at the end of processing chain
.VAR headroom_mant = 0.25; // 2 bits attenuatiom
.VAR left_headroom_obj[$M.audio_proc.stream_gain.STRUC_SIZE] =
     &stream_map_left_in,     // OFFSET_INPUT_PTR
     &stream_map_left_in,     // OFFSET_OUTPUT_PTR
     &headroom_mant,          // OFFSET_PTR_MANTISSA
     &ZeroValue;              // OFFSET_PTR_EXPONENT

.VAR right_headroom_obj[$M.audio_proc.stream_gain.STRUC_SIZE] =
     &stream_map_right_in,    // OFFSET_INPUT_PTR
     &stream_map_right_in,    // OFFSET_OUTPUT_PTR
     &headroom_mant,          // OFFSET_PTR_MANTISSA
     &ZeroValue;              // OFFSET_PTR_EXPONENT

#ifdef SPDIF_ENABLE
.VAR lfe_headroom_obj[$M.audio_proc.stream_gain.STRUC_SIZE] =
     &stream_map_lfe_in,     // OFFSET_INPUT_PTR
     &stream_map_lfe_in,     // OFFSET_OUTPUT_PTR
     &headroom_mant,          // OFFSET_PTR_MANTISSA
     &ZeroValue;              // OFFSET_PTR_EXPONENT
#endif

// volume and limit object
.BLOCK stereo_volume_and_limit_block;
   .VAR stereo_volume_and_limit_obj[$volume_and_limit.STRUC_SIZE] =
        0x000000,                                         //OFFSET_CONTROL_WORD_FIELD
        $M.MUSIC_MANAGER.CONFIG.VOLUME_LIMITER_BYPASS,    //OFFSET_BYPASS_BIT_FIELD
        2,                                                //NROF_CHANNELS_FIELD
        &$current_codec_sampling_rate,                    //SAMPLE_RATE_PTR_FIELD
        $music_example.MUTE_MASTER_VOLUME,             //MASTER_VOLUME_FIELD
        $music_example.LIMIT_THRESHOLD,                   //LIMIT_THRESHOLD_FIELD
        $music_example.LIMIT_THRESHOLD_LINEAR,            //LIMIT_THRESHOLD_LINEAR_FIELD
        $music_example.LIMIT_RATIO,                       //LIMIT_RATIO_FIELD_FIELD
        0 ...;

   .VAR left_channel_vol_struc[ $volume_and_limit.channel.STRUC_SIZE] =
        &stream_map_left_out,                 // INPUT_PTR_FIELD
        &stream_map_left_out,                 // OUTPUT_PTR_FIELD
        $music_example.DEFAULT_TRIM_VOLUME,   // TRIM_VOLUME_FIELD
        0 ...;

   .VAR right_channel_vol_struc[ $volume_and_limit.channel.STRUC_SIZE] =
        &stream_map_right_out,                 // INPUT_PTR_FIELD
        &stream_map_right_out,                 // OUTPUT_PTR_FIELD
        $music_example.DEFAULT_TRIM_VOLUME,    // TRIM_VOLUME_FIELD
        0 ...;
   .ENDBLOCK;

// define headroom object for mono mode
.VAR mono_headroom_obj[$M.audio_proc.stream_gain.STRUC_SIZE] =
     &stream_map_left_out,    // OFFSET_INPUT_PTR
     &stream_map_left_out,    // OFFSET_OUTPUT_PTR
     &headroom_mant,          // OFFSET_PTR_MANTISSA
     &ZeroValue;              // OFFSET_PTR_EXPONENT

// volume and limit object for mono mode
.BLOCK mono_volume_and_limit_block;
   .VAR mono_volume_and_limit_obj[$volume_and_limit.STRUC_SIZE] =
        0x000000,                                         //OFFSET_CONTROL_WORD_FIELD
        $M.MUSIC_MANAGER.CONFIG.VOLUME_LIMITER_BYPASS,    //OFFSET_BYPASS_BIT_FIELD
        1,                                                //NROF_CHANNELS_FIELD
        &$current_codec_sampling_rate,                    //SAMPLE_RATE_PTR_FIELD
        $music_example.MUTE_MASTER_VOLUME,                //MASTER_VOLUME_FIELD
        $music_example.LIMIT_THRESHOLD,                   //LIMIT_THRESHOLD_FIELD
        $music_example.LIMIT_THRESHOLD_LINEAR,            //LIMIT_THRESHOLD_LINEAR_FIELD
        $music_example.LIMIT_RATIO,                       //LIMIT_RATIO_FIELD_FIELD
        0 ...;

   .VAR mono_channel_vol_struc[ $volume_and_limit.channel.STRUC_SIZE] =
        &stream_map_left_out,                 // INPUT_PTR_FIELD
        &stream_map_left_out,                 // OUTPUT_PTR_FIELD
        $music_example.DEFAULT_TRIM_VOLUME,   // TRIM_VOLUME_FIELD
        0 ...;
.ENDBLOCK;
#ifdef SUB_ENABLE
// define volume and limit object for sub out, there is no volume for
// sub, it's just headroom compensation and limiter
.BLOCK sub_volume_and_limit_block;
   .VAR sub_volume_and_limit_obj[$volume_and_limit.STRUC_SIZE] =
        0x000000,                                         //OFFSET_CONTROL_WORD_FIELD
        $M.MUSIC_MANAGER.CONFIG.VOLUME_LIMITER_BYPASS,    //OFFSET_BYPASS_BIT_FIELD
        1,                                                //NROF_CHANNELS_FIELD
        &$current_codec_sampling_rate,                    //SAMPLE_RATE_PTR_FIELD
        $music_example.DEFAULT_MASTER_VOLUME,             //MASTER_VOLUME_FIELD
        $music_example.LIMIT_THRESHOLD,                   //LIMIT_THRESHOLD_FIELD
        $music_example.LIMIT_THRESHOLD_LINEAR,            //LIMIT_THRESHOLD_LINEAR_FIELD
        $music_example.LIMIT_RATIO,                       //LIMIT_RATIO_FIELD_FIELD
        0 ...;

   .VAR sub_channel_vol_struc[ $volume_and_limit.channel.STRUC_SIZE] =
        &stream_map_sub_out,                 // INPUT_PTR_FIELD
        &stream_map_sub_out,                 // OUTPUT_PTR_FIELD
        $music_example.DEFAULT_TRIM_VOLUME,   // TRIM_VOLUME_FIELD
        0 ...;
   .ENDBLOCK;
#endif


#if defined(SUB_ENABLE) || (TWS_ENABLE)

#ifdef TWS_ENABLE
#define ALIGNMENT_DELAY 0
   .VAR/DMCIRC delay_buf_right[$TWS_ALIGNMENT_DELAY + 1];
#else
#define ALIGNMENT_DELAY $L2CAP_SUB_ALIGNMENT_DELAY
   .VAR/DMCIRC delay_buf_right[max($ESCO_SUB_ALIGNMENT_DELAY,$L2CAP_SUB_ALIGNMENT_DELAY) + 1];
#endif

   .VAR delay_buf_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH(delay_buf_right),             // size
      &delay_buf_right,                    // read pointer
      &delay_buf_right;                    // write pointer

   .VAR delay_right[$audio_proc.delay.STRUC_SIZE] =
      &stream_map_right_out,               // OFFSET_INPUT_PTR
      &stream_map_right_out,               // OFFSET_OUTPUT_PTR
      &delay_buf_right_cbuffer_struc,
      ALIGNMENT_DELAY;

#ifdef TWS_ENABLE
   .VAR/DMCIRC delay_buf_left[$TWS_ALIGNMENT_DELAY + 1];
#else
   .VAR/DMCIRC delay_buf_left[max($ESCO_SUB_ALIGNMENT_DELAY,$L2CAP_SUB_ALIGNMENT_DELAY) + 1];
#endif

   .VAR delay_buf_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH(delay_buf_left),              // size
      &delay_buf_left,                     // read pointer
      &delay_buf_left;                     // write pointer

  .VAR delay_left[$audio_proc.delay.STRUC_SIZE] =
      &stream_map_left_out,                // OFFSET_INPUT_PTR
      &stream_map_left_out,                // OFFSET_OUTPUT_PTR
      &delay_buf_left_cbuffer_struc,
      ALIGNMENT_DELAY;
#endif // SUB_ENABLE

   .VAR dithertype = 0;

   .VAR pcmin_l_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_left_in,                 // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

   .VAR pcmin_r_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_right_in,                // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL
#ifdef SPDIF_ENABLE
   .VAR pcmin_lfe_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_lfe_in,                  // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL
#endif

   .VAR dac_l_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_left_out,                // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

   .VAR dac_r_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_right_out,               // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

#ifdef SUB_ENABLE
   .VAR sub_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_sub_out,                 // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL_PTR
#endif

 // Statistics from Modules sent via SPI
   // ------------------------------------------------------------------------
   .VAR StatisticsPtrs[$M.MUSIC_MANAGER.STATUS.BLOCK_SIZE] =
      &$music_example.CurMode,
      &$music_example.SysControl,
      &$music_example.PeakMipsFunc,
      &$music_example.PeakMipsDecoder,
      &pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
#ifdef SPDIF_ENABLE
      &pcmin_lfe_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
#else
      &ZeroValue,
#endif
      &dac_l_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &dac_r_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
#ifdef SUB_ENABLE
      &sub_pk_dtct     + $M.audio_proc.peak_monitor.PEAK_LEVEL,
#else
      &ZeroValue,
#endif

      &$music_example.SystemVolume,
      &$music_example.MasterVolume,
      &$music_example.LeftTrimVolume,
      &$music_example.RightTrimVolume,

#ifdef uses_USER_EQ
      &$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG,
#else
      &ZeroValue,
#endif
      &$M.MUSIC_EXAMPLE_MODULES_STAMP.CompConfig,
#ifdef LATENCY_REPORTING
      &$M.configure_latency_reporting.average_latency,
#else
      &MinusOne,
#endif
      &$codec_type,
      0 ...;                                 // Rest of table contains codec specific statistics pointers

   // Mute control structures
   .VAR/DM1 mute_cntrl_l_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_left_out,                  // OFFSET_INPUT_PTR
      &ZeroValue,                            // OFFSET_PTR_STATE
      0;                                     // OFFSET_MUTE_VAL (always mute)

   .VAR/DM1 mute_cntrl_r_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_right_out,                 // OFFSET_INPUT_PTR
      &ZeroValue,                            // OFFSET_PTR_STATE
      0;                                     // OFFSET_MUTE_VAL (always mute)

// -----------------------------------------------------------------------------

// STREAM MAPS
//
// A stream object is created for each stream: IN_L, IN_R, DAC_L, and DAC_R.
// These objects are used to populate processing module data objects (such as
// aux_mix_dm1 and pass_thru_obj) with input pointers and output pointers so
// that processing modules (such as $tone_mix and $stream_copy.pass_thru) know
// where to get and write their data.
//
// Entries would be added to these objects if more processing modules were to be
// added to the system.

// left input stream map
   .VAR    stream_map_left_in[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$audio_out_left_cbuffer_struc,           // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_input_stream_ind,  // Distribute Function
          $frame_sync.update_input_streams_ind,     // Update Function
          0 ...;
          // SP.  Modules using this stream map
          //    &pass_thru_obj + $M.audio_proc.stereo_copy.INPUT_CH1_PTR_BUFFER_FIELD,
          //    &stereo_3d_obj + $stereo_3d_enhancement.INPUT_CH1_PTR_BUFFER_FIELD,
          //    &mix_dm1 + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH1_PTR,
          //    &pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

// right input stream map
    .VAR  stream_map_right_in[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$audio_out_right_cbuffer_struc,          // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_input_stream_ind,  // Distribute Function
          $frame_sync.update_input_streams_ind,     // Update Function
          0 ...;
          // SP.  Modules using this stream map
          //    &pass_thru_obj + $M.audio_proc.stereo_copy.INPUT_CH2_PTR_BUFFER_FIELD,
          //    &stereo_3d_obj + $stereo_3d_enhancement.INPUT_CH2_PTR_BUFFER_FIELD,
          //    &mix_dm1 + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH2_PTR,
          //    &pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,
#ifdef SPDIF_ENABLE
// LFE input stream map
    .VAR  stream_map_lfe_in[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$audio_out_lfe_cbuffer_struc,            // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_input_stream_ind,  // Distribute Function
          $frame_sync.update_input_streams_ind,     // Update Function
          0 ...;
#endif
// left output stream map
    .VAR  stream_map_left_out[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$dac_out_left_cbuffer_struc,             // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_output_stream_ind, // Distribute Function
          $frame_sync.update_output_streams_ind,    // Update Function
          0 ...;

// right output stream map
    .VAR  stream_map_right_out[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$dac_out_right_cbuffer_struc,            // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_output_stream_ind, // Distribute Function
          $frame_sync.update_output_streams_ind,    // Update Function
          0 ...;

#ifdef SUB_ENABLE
    // sub output stream map
    .VAR  stream_map_sub_out[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$sub_out_cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_output_stream_ind, // Distribute Function
          $frame_sync.update_output_streams_ind,    // Update Function
          0 ...;
#endif // SUB_ENABLE

// ----------------------------------------------------------------------------
// STREAM SETUP TABLE
// This table is used with $frame.distribute_streams and $frame.update_streams.

// SP.  Null terminated list of streams to process

     .VAR rcv_process_streams[] =
        &stream_map_left_in,
        &stream_map_right_in,
#ifdef SPDIF_ENABLE
        &stream_map_lfe_in,
#endif
        &stream_map_left_out,
        &stream_map_right_out,
#ifdef SUB_ENABLE
        &stream_map_sub_out,
#endif // SUB_ENABLE
    0;

// -----------------------------------------------------------------------------
// REINITIALIZATION FUNCTION TABLE
// Reinitialization functions and corresponding data objects can be placed
// in this table.  Functions in this table all called every time a frame of data
// is ready to be processed and the reinitialization flag is set.
// This table must be null terminated.

   .VAR reinitialize_table[] =
    // Function                          r7                   r8
#ifdef uses_SPKR_EQ
    $music_example.peq.initialize,      &spkr_eq_left_dm2,    &spkr_eq_bank_select,
    $music_example.peq.initialize,      &spkr_eq_right_dm2,   &spkr_eq_bank_select,
#endif
#ifdef uses_BASS_BOOST
    $music_example.peq.initialize,      &boost_eq_left_dm2,   &boost_eq_bank_select,
    $music_example.peq.initialize,      &boost_eq_right_dm2,  &boost_eq_bank_select,
#endif
#ifdef uses_USER_EQ
    $user_eq.initialize,                &UserEqInitTable,   &user_eq_bank_select,
#endif
#if uses_STEREO_ENHANCEMENT
    $stereo_3d_enhancement.initialize,  0,                    &stereo_3d_obj,
#endif
#if uses_COMPANDER
    $music_example.cmpd100.initialize,  &cmpd100_obj_44kHz,   &cmpd100_obj_48kHz,
#endif

    $volume_and_limit.initialize,  &stereo_volume_and_limit_obj,   &stereo_volume_and_limit_obj,
    $volume_and_limit.initialize,  &mono_volume_and_limit_obj,   &mono_volume_and_limit_obj,

#ifdef SUB_ENABLE
    $volume_and_limit.initialize,  &sub_volume_and_limit_obj,   &sub_volume_and_limit_obj,

    #if uses_BASS_MANAGER
            $bass_management.initialize,    &bass_manager_struct, $sub_out_cbuffer_struc,
    #endif
        $audio_proc.delay.initialize,   0,                    &delay_left,
        $audio_proc.delay.initialize,   0,                    &delay_right,
#endif // SUB_ENABLE
#ifdef TWS_ENABLE
        $audio_proc.delay.initialize,   0,                    &delay_left,
        $audio_proc.delay.initialize,   0,                    &delay_right,
#endif // SUB_ENABLE

    0;

   .VAR filter_reset_table[] =
    // Function                          r7                   r8
#ifdef uses_SPKR_EQ
    $audio_proc.peq.zero_delay_data,     &spkr_eq_left_dm2,    0,
    $audio_proc.peq.zero_delay_data,     &spkr_eq_right_dm2,   0,
#endif
#ifdef uses_BASS_BOOST
    $audio_proc.peq.zero_delay_data,     &boost_eq_left_dm2,   0,
    $audio_proc.peq.zero_delay_data,     &boost_eq_right_dm2,  0,
#endif
#ifdef uses_USER_EQ
    $audio_proc.peq.zero_delay_data,     &user_eq_left_dm2,    0,
    $audio_proc.peq.zero_delay_data,     &user_eq_right_dm2,   0,
#endif
#ifdef SUB_ENABLE
    #if uses_BASS_MANAGER
        $bass_management.zero_data,      &bass_manager_struct, 0,
    #endif
#endif // SUB_ENABLE
    0;

// -----------------------------------------------------------------------------

// MODE FUNCTION TABLE
// This table contains all of the modes in this system.  The VM plugin sends a
// message that contains a mode value, which is used as a pointer into this
// table.  As shipped, this file only contains one
// mode, which corresponds to pass_thru operation.  Developers can expand this
// table if they add additional processing modes to the system.  This table must
// be null terminated.
//
// Every time a frame of data is ready to process, the functions from the
// corresponding mode table are called.
    .VAR mode_table[] =
        &StandBy_proc_funcs,
        &pass_thru_proc_funcs,
        &full_proc_funcs,
        &mono_proc_funcs,
        &mono_pass_thru_proc_funcs,
        &mono_StandBy_proc_funcs,
#ifdef SUB_ENABLE
        &soundbar_2_1_proc_funcs,
        &soundbar_2_1_mono_proc_funcs,
#else // SUB_ENABLE
        &full_proc_funcs,       // use full procs instead of 2.1 processing
        &mono_proc_funcs,       // use mono instead of 2.1_mono processing
#endif // SUB_ENABLE
        // more entries can be added here
        0;

// ----------------------------------------------------------------------------
// MODE TABLES (aka FUNCTION TABLES)
// Modes are defined as tables that contain a list of functions with
// corresponding
// data objects.  The functions are called in the order that they appear.
//
// $frame.distribute_stream should always be first as it tells the processing
// modules where to get and write data.
//
// $frame.update_streams should always be last as it advances cbuffer pointers
// to the correct positions after the processing modules have read and written
// data.
//
// The processing modules are called by the function $frame.run_function_table,
// which is defined in the frame_sync library.
//
// Processing modules must be written to take input from r7 and r8.  A zero
// should be used if the module does not require input.
//
// Mode tables must be null terminated.
//
// Additional modes can be created by adding new tables.
   .VAR pass_thru_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
       $M.audio_proc.stream_gain.Process.func,  &lfe_headroom_obj, 0,
#endif
       $M.audio_proc.stream_gain.Process.func,  &left_headroom_obj, 0,
       $M.audio_proc.stream_gain.Process.func,  &right_headroom_obj, 0,
       $M.audio_proc.stereo_copy.Process.func,  &pass_thru_obj,      0,
       $volume_and_limit.apply_volume,         &stereo_volume_and_limit_obj, 0,

       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;


   .VAR full_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
       $M.audio_proc.stream_gain.Process.func,  &lfe_headroom_obj, 0,
#endif
       $M.audio_proc.stream_gain.Process.func,  &left_headroom_obj, 0,
       $M.audio_proc.stream_gain.Process.func,  &right_headroom_obj, 0,
#if uses_STEREO_ENHANCEMENT
       $stereo_3d_enhancement,                  0,                   &stereo_3d_obj,
#else
       $M.audio_proc.stereo_copy.Process.func,  &pass_thru_obj,      0,
#endif
#ifdef uses_SPKR_EQ
       $music_example.peq.process,              &spkr_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
       $music_example.peq.process,              &spkr_eq_right_dm2,  $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
#endif
#ifdef uses_BASS_BOOST
       $music_example.peq.process,              &boost_eq_left_dm2,  $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
       $music_example.peq.process,              &boost_eq_right_dm2, $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
#endif
#ifdef uses_USER_EQ
       $music_example.peq.process,              &user_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
       $music_example.peq.process,              &user_eq_right_dm2,  $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
#endif
#if uses_COMPANDER
       $music_example.cmpd100.analysis,         &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
       $music_example.cmpd100.applygain,        &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
#endif

#ifdef TWS_ENABLE
       $audio_proc.delay.process,               0,                   &delay_left,
       $audio_proc.delay.process,               0,                   &delay_right,
#endif

       $volume_and_limit.apply_volume,         &stereo_volume_and_limit_obj, 0,

       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;

#ifdef SUB_ENABLE
   .VAR soundbar_2_1_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
       $M.audio_proc.stream_gain.Process.func,  &lfe_headroom_obj, 0,
#endif
       $M.audio_proc.stream_gain.Process.func,  &left_headroom_obj, 0,
       $M.audio_proc.stream_gain.Process.func,  &right_headroom_obj, 0,
#if uses_STEREO_ENHANCEMENT
       $stereo_3d_enhancement,                  0,                   &stereo_3d_obj,
#else
       $M.audio_proc.stereo_copy.Process.func,  &pass_thru_obj,      0,
#endif
#ifdef uses_SPKR_EQ
       $music_example.peq.process,              &spkr_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
       $music_example.peq.process,              &spkr_eq_right_dm2,  $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
#endif
#ifdef uses_BASS_BOOST
       $music_example.peq.process,              &boost_eq_left_dm2,  $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
       $music_example.peq.process,              &boost_eq_right_dm2, $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
#endif
#ifdef uses_USER_EQ
       $music_example.peq.process,              &user_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
       $music_example.peq.process,              &user_eq_right_dm2,  $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
#endif
#if uses_BASS_MANAGER
        $bass_management,                       &bass_manager_struct, 0,
#endif
#if uses_COMPANDER
       $music_example.cmpd100.analysis,         &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
       $music_example.cmpd100.applygain,        &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
#endif
       $audio_proc.delay.process,               0,                   &delay_left,
       $audio_proc.delay.process,               0,                   &delay_right,

       $volume_and_limit.apply_volume,         &stereo_volume_and_limit_obj, 0,
       $volume_and_limit.apply_volume,         &sub_volume_and_limit_obj, 0,

       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &sub_pk_dtct,        0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;


   .VAR soundbar_2_1_mono_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
       $M.audio_proc.stream_gain.Process.func,  &lfe_headroom_obj, 0,
#endif
       $M.audio_proc.stream_gain.Process.func,  &left_headroom_obj, 0,
       $M.audio_proc.stream_gain.Process.func,  &right_headroom_obj, 0,
       $M.audio_proc.stereo_copy.Process.func,  &pass_thru_obj,      0,

#ifdef uses_SPKR_EQ
       $music_example.peq.process,              &spkr_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
       $music_example.peq.process,              &spkr_eq_right_dm2,  $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
#endif
#ifdef uses_BASS_BOOST
       $music_example.peq.process,              &boost_eq_left_dm2,  $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
       $music_example.peq.process,              &boost_eq_right_dm2, $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
#endif
#ifdef uses_USER_EQ
       $music_example.peq.process,              &user_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
       $music_example.peq.process,              &user_eq_right_dm2,  $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
#endif
#if uses_BASS_MANAGER
        $bass_management,                       &bass_manager_struct, 0,
#endif


#if uses_COMPANDER
       $music_example.cmpd100.analysis,         &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
       $music_example.cmpd100.applygain,        &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
#endif
       $audio_proc.delay.process,               0,                   &delay_left,
       $audio_proc.delay.process,               0,                   &delay_right,

       $M.audio_proc.stream_mixer.Process.func, &sub_mix_dm1,            0,
       $M.MUTE_CONTROL.Process.func,            &mute_cntrl_r_dm1,       0,

       $volume_and_limit.apply_volume,          &mono_volume_and_limit_obj, 0,
       $volume_and_limit.apply_volume,          &sub_volume_and_limit_obj, 0,

       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &sub_pk_dtct,        0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;
#endif // SUB_ENABLE

   .VAR StandBy_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
#endif
       // Always muted so no $stereo_copy is performed
       $M.MUTE_CONTROL.Process.func,            &mute_cntrl_l_dm1,   0,
       $M.MUTE_CONTROL.Process.func,            &mute_cntrl_r_dm1,   0,
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;

   .VAR mono_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
       $M.audio_proc.stream_gain.Process.func,  &lfe_headroom_obj, 0,
#endif
       $M.audio_proc.stream_mixer.Process.func, &mix_dm1,            0,
       $M.audio_proc.stream_gain.Process.func,  &mono_headroom_obj, 0,

#ifdef uses_SPKR_EQ
       $music_example.peq.process,              &spkr_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS,
#endif
#ifdef uses_BASS_BOOST
       $music_example.peq.process,              &boost_eq_left_dm2,  $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS,
#endif
#ifdef uses_USER_EQ
       $music_example.peq.process,              &user_eq_left_dm2,   $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS,
#endif
#if uses_COMPANDER
       $music_example.cmpd100.analysis,         &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
       $music_example.cmpd100.applygain,        &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
#endif
#ifdef TWS_ENABLE
       $audio_proc.delay.process,               0,                   &delay_left,
#endif
       $volume_and_limit.apply_volume,          &mono_volume_and_limit_obj, 0,

       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;

   .VAR mono_StandBy_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
#endif
       // Always muted so no $stereo_copy is performed
       $M.MUTE_CONTROL.Process.func,            &mute_cntrl_l_dm1,   0,
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;

   .VAR mono_pass_thru_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
#ifdef SPDIF_ENABLE
       $M.audio_proc.peak_monitor.Process.func, &pcmin_lfe_pk_dtct,  0,
#endif
       $M.audio_proc.stream_mixer.Process.func, &mix_dm1,            0,
       $M.audio_proc.stream_gain.Process.func,  &mono_headroom_obj, 0,
       $volume_and_limit.apply_volume,         &mono_volume_and_limit_obj, 0,
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;

.ENDMODULE;


