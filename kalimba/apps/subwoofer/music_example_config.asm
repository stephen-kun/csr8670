// *****************************************************************************
// %%fullcopyright(2009)        http://www.csr.com
// %%version
//
// $Change: 1905219 $  $DateTime: 2014/05/27 11:22:10 $
// *****************************************************************************


// *****************************************************************************
// DESCRIPTION
//    Static configuration file that includes function references and data
//    objects for the subwoofer system.
//
//    This file, as shipped in the SDK, includes support for four modes.
//    STANDBY --
//    ADC -- User EQ, Speaker EQ, compander, and dither
//    Bluetooth -- Speaker EQ, compander, and dither
//
//    INTERRUPT DRIVEN PROCESSES:
//    Data is transfered between firmware mmu buffers and dsp cbuffers via
//    operators, which run in the timer interrupt driven $audio_copy_handler
//    routines.
//
//    Data streams are synchronized using rate_match operators provided by
//    the frame_sync library.
//
//
// *****************************************************************************
#include "subwoofer.h"
#include "subwoofer_config.h"
#include "stream_copy.h"
#include "audio_proc_library.h"
#include "cbops_library.h"
#include "codec_library.h"
#include "core_library.h"
#include "peq.h"
#include "frame_sync_buffer.h"


#define MAX_NUM_SPKR_EQ_STAGES      (3)
#define MAX_NUM_USER_EQ_STAGES      (5)

#define MAX_NUM_SPKR_EQ_BANKS       (1)
#define MAX_NUM_USER_EQ_BANKS       (7)

#define NUMBER_OF_EQ_SAMPLE_RATES   (1)
#define NUMBER_OF_FLAT_EQS          (1)

#if (MAX_NUM_SPKR_EQ_BANKS != 1)
    #error Number of Speaker Eq banks is not 1 - Mulitple bank switching not supported for Speaker Eq
#endif


.MODULE $M.system_config.data;
   .DATASEGMENT DM;

   // Temp Variable to handle disabled modules.
   .VAR  ZeroValue = 0;
   .VAR  OneValue = 1.0;
   .VAR  config;

   .VAR/DMCONST16  DefaultParameters[] =
   #include "subwoofer_defaults.dat"
   ;

   // Parameter to Module Map
   .VAR/DM2 ParameterMap[] =



#if uses_COMPANDER
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_CONFIG,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_EXPAND_THRESHOLD,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_LINEAR_THRESHOLD,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_COMPRESS_THRESHOLD,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_LIMIT_THRESHOLD,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_INV_EXPAND_RATIO,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_INV_LINEAR_RATIO,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_INV_COMPRESS_RATIO,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_INV_LIMIT_RATIO,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_EXPAND_ATTACK_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_EXPAND_DECAY_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_LINEAR_ATTACK_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_LINEAR_DECAY_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_COMPRESS_DECAY_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_LIMIT_ATTACK_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_LIMIT_DECAY_TC,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_MAKEUP_GAIN,
      &cmpd100_obj_48kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
#endif
#if uses_DITHER
      // Update both the stereo and mono operators with the noise shape field
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE,
      &$audio_out_dither_and_shift_op.param + $cbops.dither_and_shift.DITHER_TYPE_FIELD,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE,
      &$audio_in_rate_adjustment_and_shift_op_mono2.param + $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD,
#endif
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_SIGNAL_DETECT_THRESH,
      &$signal_detect_op_coefs + $cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_SIGNAL_DETECT_TIMEOUT,
      &$signal_detect_op_coefs + $cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_SIGNAL_DETECT_THRESH,
      &$signal_detect_adc_op_coefs + $cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_SIGNAL_DETECT_TIMEOUT,
      &$signal_detect_adc_op_coefs + $cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME,
      &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_NOISE_GATE_THRESH,
      &$cbops.noise_gate.monostable_trigger_level,
      0;
   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.SUBWOOFER.PARAMETERS.STRUCT_SIZE)];
// -----------------------------------------------------------------------------
// DATA OBJECTS USED WITH PROCESSING MODULES
//
// This section would be updated if more processing modules with data objects
// were to be added to the system.

#ifdef uses_SPKR_EQ

    /* object for currently running EQs */
    // SP.  Bypass mask moved to (r8) input of processing function

   .VAR/DM2 spkr_eq_left_dm2[PEQ_OBJECT_SIZE(MAX_NUM_SPKR_EQ_STAGES)] =
      &stream_map_left_in,            // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_in,            // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_SPKR_EQ_STAGES,         // MAX_STAGES_FIELD
      0,                              // PARAM_PTR_FIELD
      0 ...;

    .VAR/DM2 spkr_eq_bank_select[1 + (MAX_NUM_SPKR_EQ_BANKS)] =
        MAX_NUM_SPKR_EQ_BANKS,
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_SPKR_EQ1_CONFIG;

#endif  // uses_SPKR_EQ

#ifdef uses_USER_EQ

    /* object for currently running EQs */
   .VAR/DM2 user_eq_left_dm2[PEQ_OBJECT_SIZE(MAX_NUM_USER_EQ_STAGES)] =
      &stream_map_left_in,          // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_in,          // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_USER_EQ_STAGES,       // MAX_STAGES_FIELD
      &UserEqCoefsA,                // PARAM_PTR_FIELD
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

     // 6 configs
    .VAR/DM2 user_eq_bank_select[1 + MAX_NUM_USER_EQ_BANKS] =
        MAX_NUM_USER_EQ_BANKS,
        0,  // index 0 = flat response (no eq)
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ1_NUM_BANDS,
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ2_NUM_BANDS,
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ3_NUM_BANDS,
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ4_NUM_BANDS,
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ5_NUM_BANDS,
        &CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ6_NUM_BANDS;

#endif

#if uses_COMPANDER
    .VAR/DM $cmpd_gain;

.VAR cmpd100_obj_48kHz[$cmpd100.STRUC_SIZE] =
     64,                                                // OFFSET_CONTROL_WORD                0
     $M.SUBWOOFER.CONFIG.COMPANDER_BYPASS,              // OFFSET_BYPASS_BIT_MASK             1
     &stream_map_left_out,                              // OFFSET_INPUT_CH1_PTR               2
     &stream_map_left_out,                              // OFFSET_INPUT_CH2_PTR               3
     &stream_map_left_out,                              // OFFSET_OUTPUT_CH1_PTR              4
     &stream_map_left_out,                              // OFFSET_OUTPUT_CH2_PTR              5
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
     27915;                                             // OFFSET_LIMIT_DECAY_TIME            28
#endif

   .VAR dithertype = 0;

   .VAR pcmin_l_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_left_in,                 // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL


   .VAR dac_l_pk_dtct[] =
      &stream_map_left_out,                // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

   .VAR adc_gain_db = 0;
   .VAR adc_gain_mantissa  = 1.0;
   .VAR adc_gain_exponent  = 0;
   .VAR adc_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_left_in,                  // OFFSET_INPUT_PTR
      &stream_map_left_out,                 // OFFSET_OUTPUT_PTR
      &adc_gain_mantissa,
      &adc_gain_exponent;

   .VAR adc_gain_ramp[$audio_proc.stream_gain_ramp.STRUC_SIZE] =
      0.000208333,                          // RAMP_STEP_FIELD
      0,                                    // RAMP_GAIN_FIELD
      0,                                    // PREV_MANTISSA_FIELD
      0;                                    // PREV_EXPONENT_FIELD

   .VAR swat_system_gain_db = 0;
   .VAR swat_system_gain_mantissa  = 0.5;
   .VAR swat_system_gain_exponent  = 1;
   .VAR swat_system_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_left_out,                 // OFFSET_INPUT_PTR
      &stream_map_left_out,                 // OFFSET_OUTPUT_PTR
      &swat_system_gain_mantissa,
      &swat_system_gain_exponent;

   .VAR swat_system_gain_ramp[$audio_proc.stream_gain_ramp.STRUC_SIZE] =
      0.000208333,                          // RAMP_STEP_FIELD
      0,                                    // RAMP_GAIN_FIELD
      0,                                    // PREV_MANTISSA_FIELD
      0;                                    // PREV_EXPONENT_FIELD

   .VAR swat_trim_gain_db = 0;
   .VAR swat_trim_gain_mantissa  = 0.5;
   .VAR swat_trim_gain_exponent  = 1;
   .VAR swat_trim_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_left_in,                  // OFFSET_INPUT_PTR
      &stream_map_left_out,                 // OFFSET_OUTPUT_PTR
      &swat_trim_gain_mantissa,
      &swat_trim_gain_exponent;

   .VAR swat_trim_gain_ramp[$audio_proc.stream_gain_ramp.STRUC_SIZE] =
      0.000208333,                          // RAMP_STEP_FIELD
      0,                                    // RAMP_GAIN_FIELD
      0,                                    // PREV_MANTISSA_FIELD
      0;                                    // PREV_EXPONENT_FIELD

   .VAR/DMCIRC delay_buf_left[4000];
   .VAR delay_buf_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH(delay_buf_left),             // size
      &delay_buf_left,                    // read pointer
      &delay_buf_left;                    // write pointer

   .VAR delay_left[$audio_proc.delay.STRUC_SIZE] =
      &stream_map_left_out,                 // OFFSET_INPUT_PTR
      &stream_map_left_out,                 // OFFSET_OUTPUT_PTR
      &delay_buf_left_cbuffer_struc,
      0;

 // Statistics from Modules sent via SPI
   // ------------------------------------------------------------------------
   .VAR StatisticsPtrs[$M.SUBWOOFER.STATUS.BLOCK_SIZE] =
      &$music_example.CurMode,
      &$music_example.PeakMipsFunc,
      &$M.MUSIC_EXAMPLE_MODULES_STAMP.CompConfig,
      &pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &dac_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &adc_gain_db,
      &swat_system_gain_db,
      &swat_trim_gain_db,
      &ZeroValue, // TODO: remove from here and UFE
#ifdef uses_USER_EQ // TODO: see if this is USER_EQ_BANK
      &$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_CONFIG,
#else
      &ZeroValue,
#endif
      &$subwoofer.packet_fail_counter,
      &$music_example.link_type,
      &$music_example.output_type; // TODO: Output type


// -----------------------------------------------------------------------------

// STREAM MAPS
//
// A stream object is created for each stream: IN_L and DAC_L.
// These objects are used to populate processing module data objects with input
// pointers and output pointers so that processing modules where to get and
// write their data.
//
// Entries would be added to these objects if more processing modules were to be
// added to the system.

// left input stream map
   .VAR   stream_map_left_in[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$frame_process_in_cbuffer_struc,         // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_input_stream_ind,  // Distribute Function
          $frame_sync.update_input_streams_ind,     // Update Function
          0 ...;

// left output stream map
    .VAR  stream_map_left_out[$framesync_ind.ENTRY_SIZE_FIELD] =
          $dac_out_cbuffer_struc,                   // $framesync_ind.CBUFFER_PTR_FIELD
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $music_example.NUM_SAMPLES_PER_FRAME,     // $framesync_ind.FRAME_SIZE_FIELD
          $music_example.JITTER,                    // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_output_stream_ind, // Distribute Function
          $frame_sync.update_output_streams_ind,    // Update Function
          0 ...;

// ----------------------------------------------------------------------------
// STREAM SETUP TABLE
// This table is used with $frame.distribute_streams and $frame.update_streams.

// $frame.distribute_streams populates processing module data objects with
// current address into the cbuffers so modules know where to get and write
// their data.
//
// $frame.update_streams updates the cbuffer read and write addresses into the
// the cbuffers after modules have finished their processing so that the
// pointers are in the correct positions for the next time the processing
// modules are called.

.VAR rcv_process_streams[] =
        &stream_map_left_in,
        &stream_map_left_out,
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
#endif
#ifdef uses_USER_EQ
    $user_eq.initialize,                &user_eq_left_dm2,    &user_eq_bank_select,
#endif
#if uses_COMPANDER
    $cmpd100.initialize,                0,                    &cmpd100_obj_48kHz,
#endif
    $audio_proc.delay.initialize,       0,                    &delay_left,
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
   .VAR mode_table[$M.SUBWOOFER.SYSMODE.MAX_MODES] =
    &bt_proc_funcs,      // potential slot for standby
    &adc_proc_funcs,
    &bt_proc_funcs,
    &bt_proc_funcs;      // potential slot for pass-through

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
   .VAR bt_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $music_example.signal_detect,            0,                   &$signal_detect_op_coefs,
#ifdef uses_SPKR_EQ
       $music_example.peq.process,              &spkr_eq_left_dm2,   $M.SUBWOOFER.CONFIG.SPKR_EQ_BYPASS,
#endif
       $M.audio_proc.stream_gain.Process.func,  &swat_trim_gain,     &swat_trim_gain_ramp,
       $M.audio_proc.stream_gain.Process.func,  &swat_system_gain,   &swat_system_gain_ramp,
#if uses_COMPANDER
       $cmpd100.analysis,                       0,                   &cmpd100_obj_48kHz,
       $cmpd100.applygain,                      0,                   &cmpd100_obj_48kHz,
#endif
       $audio_proc.delay.process,               0,                   &delay_left,
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;


   .VAR adc_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $music_example.signal_detect,            0,                   &$signal_detect_adc_op_coefs,
#ifdef uses_SPKR_EQ
       $music_example.peq.process,              &spkr_eq_left_dm2,   $M.SUBWOOFER.CONFIG.SPKR_EQ_BYPASS,
#endif
#ifdef uses_USER_EQ
       $music_example.peq.process,              &user_eq_left_dm2,   $M.SUBWOOFER.CONFIG.USER_EQ_BYPASS,
#endif
       $M.audio_proc.stream_gain.Process.func,  &adc_gain,           &adc_gain_ramp,
#if uses_COMPANDER
       $cmpd100.analysis,                       0,                   &cmpd100_obj_48kHz,
       $cmpd100.applygain,                      0,                   &cmpd100_obj_48kHz,
#endif
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;

.ENDMODULE;

// input: r8 = signal_detect parameter object
.MODULE $M.music_example.signal_detect;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR frame_counter = 0;
   .VAR one_second = 133; /* TODO - may need to change for L2CAP and/or ADC */

$music_example.signal_detect:
   $push_rLink_macro;

   r0 = M[frame_counter];
   r0 = r0 + 1;
   M[frame_counter] = r0;

   Null = r0 - M[one_second];
   if NZ jump done;
   // one second has elapsed, call signal detect handler
   call $cbops.signal_detect_op.timer_handler;
   M[frame_counter] = Null;

done:
    // pop rLink from stack
    jump $pop_rLink_and_rts;

.ENDMODULE;

.MODULE $M.calc_time_to_play;
   .DATASEGMENT DM;
   .CODESEGMENT PM;

    $calc_time_to_play:

    // push rLink onto stack
    $push_rLink_macro;

    call $block_interrupts;

    // Count the number of cbuffer samples, which will be played before this frame.
    // Each buffer can have its own sample rate associated with it.  The data structure
    // is populated with inverse sample rates so we can use a multiplication.

    r6 = 0;
    proc_loop:
       r0 = M[r7];
       // NULL value terminates List
       if Z jump done_counting_cbuffer_data;
       // calculate amount in buffer
       call $cbuffer.calc_amount_data;
       // get inverse of sample rate
       r1 = M[r7 + 1];
       r1 = M[r1];
       // compute q29.19 result
       rMAC = r0 * r1;
       // convert to 24.24
       rMAC = rMAC ASHIFT 5;
       // upper 24 bits is the amount of time it will take the data to play out of this cbuffer
       r1 = rMAC1;
       // accumulate time
       r6 = r6 + r1;
       // point to next cbuffer
       r7 = r7 + 2;
    jump proc_loop;
done_counting_cbuffer_data:

    // Now determine how many samples are in the output port.
    // Warning: If we've just started streaming we need to consider the impact
    // of the output port's free running read pointer:
    // Between determining the number of samples in the port and actually writing
    // our new samples into the port the read pointer could pass the write pointer,
    // which would invalidate our time-to-play calculation.
    // For example, we could determine that one sample is in the port,
    // but by time the operator copies audio to the port, the read pointer would
    // have passed the write pointer, which would make the output port appear to
    // be full.  This situation can be avoided by filling the output port if (and
    // only if) the output cbuffers are empty.

    // r6 contains the amount of time it will take to play data currently in
    // the cbuffers.  It's in microsecods.
    
    Null = M[$just_started_streaming_flag];
    if Z jump calculate_num_samples_in_port;


    // fill output port so it doesn't wrap and cause us to calculate an invalid
    // time-to-play.
    r0 = M[r8];
    r0 = M[r0];
    r3 = r0;
    call $cbuffer.calc_amount_space;
    r10 = r0;
    call $audio_insert_silence2;

calculate_num_samples_in_port:
    // else calculate the amount of samples in the port
    r0 = M[r8];
    r0 = M[r0];
    call $cbuffer.calc_amount_space;
    r0 = r0 + 1;        // compensate for routine reporting 1 less that true amount of space
    r2 = r2 ASHIFT -1;  // size of port in 16-bit words
    r0 = r2 - r0;       // number of samples in port = size of buffer - amount of space

    // get inverse of port sample rate
    r1 = M[r8 + 1];
    r1 = M[r1];
    // compute q29.19 result
    rMAC = r0 * r1;
    // convert to 24.24
    rMAC = rMAC ASHIFT 5;
    // upper 24 bits is the amount of time it will take the data to play out of this cbuffer
    r1 = rMAC1;

    // push time in port
    push r1;

    // add latency of delay buffer
    r0 = M[r8 + 2];
    // get inverse of delay sample rate
    r1 = M[r8 + 3];
    r1 = M[r1];
    // compute q29.19 result
    rMAC = r0 * r1;
    // convert to 24.24
    rMAC = rMAC ASHIFT 5;
    // upper 24 bits is the amount of time it will take the data to play out of this cbuffer
    r1 = rMAC1;

    // Compute total amount of time ahead of this current frame in cbuffers and delay buffer
    r6 = r6 + r1;

    // time modified by current warp value = time * (1 + sra_rate)
    r0 = M[$current_rate];
    r0 = r6 * r0 (frac);
    r6 = r0 + r6;

    // add up times from cbuffers, delay buffer, and output port
    pop r1;
    r6 = r1 + r6;

    // Add absolute time in front of this frame to wall clock time.  This
    // value will be sent to the slave so it knows when to play the frame.
    r1 = M[$wall_clock_adjustment];
    r1 = r1 + M[$TIMER_TIME];
    r6 = r6 + r1;
    M[r8 + 5] = r6;  // Store TIME_TO_PLAY

done:
    // calculate amount of data

    call $unblock_interrupts;

    jump $pop_rLink_and_rts;

.ENDMODULE;


.MODULE $M.audio_insert_silence2;
    .CODESEGMENT PM;
    .DATASEGMENT DM;

$audio_insert_silence2:

    $push_rLink_macro;

    // get audio port write address
    r0 = r3;
    call $cbuffer.get_write_address_and_size;
    I0 = r0;
    L0 = r1;

    r0 = 0;
    // generate silence
    do audio_fill_loop;
        M[I0,1] = r0;
    audio_fill_loop:

    // set new write address
    r0 = r3;
    r1 = I0;
    call $cbuffer.set_write_address;
    L0 = 0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.ENDMODULE;
