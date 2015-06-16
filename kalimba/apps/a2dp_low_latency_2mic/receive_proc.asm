// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change:  $  $DateTime:  $
// *****************************************************************************
// *****************************************************************************
// Music manager processing
//
// Configuration : 
//      Processing @ 44.1 or 48kHz 
//      Parameter tuning through UFE
// 
// Interface points :
//      stream_map_left_in                       
//      stream_map_right_in                        
//      stream_map_left_out                       
//      stream_map_right_out        
//
// NOTES
//      Data is copied from the Decoded Music Outuput cbuffers to the output 
//      cbuffers using the stereo_3d_enhancement function in full processing mode 
//      or through the stereo_copy function if stereo_3d_enhancement is not defined 
//      or in any other mode. These routines execute when a block size of data is 
//      available.
//
//      These modules can be included/excluded from the build using define the
//      define statements in a2dp_low_latency_2mic_config.h
// *****************************************************************************
// *****************************************************************************
#include "audio_proc_library.h"
#include "codec_library.h"
#include "core_library.h"
#include "frame_sync_buffer.h"
#include "a2dp_low_latency_2mic_library_gen.h"
#include "a2dp_low_latency_2mic_config.h"
#include "cbops_multirate_library.h"
#include "mips_profile.h"

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

.CONST $RCV_JITTER                            3000; 
.CONST $RCV_NUM_SAMPLES_PER_FRAME             160;
.CONST $MUTE_CONTROL.OFFSET_INPUT_PTR         0;

// *****************************************************************************
// MODULE:
//    $set_eq_bank
//
// DESCRIPTION: message handler for receiving user eq bank from VM
//
// INPUTS:
//  r1 = eq bank state 
//       0 = do not advance to next EQ bank
//       1 = advance to next EQ bank
//       2 = use eq Bank that is specified in r3
//  r2 = eq bank (only used if r1 = 2)
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.set_eq_bank;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
func:

   Null = r1;
   if Z jump do_not_advance_to_next_eq_bank;

   r4 = $M.A2DP_LOW_LATENCY_2MIC.CONFIG.USER_EQ_SELECT;
      r5 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAX_USER_EQ_BANKS];
      r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG];
      // calculate the current EQ bank
      r6 = r0 AND r4;
      // advance to the next EQ bank
      r6 = r6 + 1;
      // use specified index if r1==2
      Null = r1 - 2;
      if Z r6 = r2;
      r8 = $M.A2DP_LOW_LATENCY_2MIC.CONFIG.EQFLAT;
      // If EQFLAT bit is one it means a flat curve has been added to the system.
      // The flat curve is used when bank==0;
      // If EQFLAT bit is zero AND bank==0, bank must be forced to one.
      r2 = 0;
      r7 = 1;
      Null = r0 AND r8; // is zero if flat curve not allowed (i.e. Bank0 not allowed)
      if Z r2 = r7;
      Null = r5 - r6;
      // reset index to 0 or 1 depending on EQFLAT
      if LT r6 = r2;

      // If the VM sent r1=2 and r2=0, use Bank1 if a flat curve isn't included
      Null = r6 - 0;
      if Z r6 = r2;

      // Store bank index in Music Manager Config Parameter.
      // Invert EQSEL mask
      r7 = 0xffffff XOR r4;

      // Clear EQSEL bits from current CONFIG
      r7 = r0 AND r7;
      // Set new EQSEL bits
      r6 = r7 OR r6;
      M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG] = r6;
   do_not_advance_to_next_eq_bank:
   
   rts;

.ENDMODULE;

// *****************************************************************************
.MODULE $M.system_config.data;
   .DATASEGMENT DM;

// DATA OBJECTS USED WITH PROCESSING MODULES

   .VAR dithertype = 0;

// Data object used with $stream_copy.pass_thru function
   .VAR pass_thru_obj[$M.audio_proc.stereo_copy.STRUC_SIZE] =
    &stream_map_left_in,                   // INPUT_CH1_PTR_BUFFER_FIELD
    &stream_map_right_in,                  // INPUT_CH2_PTR_BUFFER_FIELD
    &stream_map_left_out,                  // OUTPUT_CH1_PTR_BUFFER_FIELD
    &stream_map_right_out;                 // OUTPUT_CH2_PTR_BUFFER_FIELD

   .VAR pcmin_l_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_left_in,                 // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

   .VAR pcmin_r_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_right_in,                // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

   .VAR dac_l_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_left_out,                // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL

   .VAR dac_r_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_right_out,               // PTR_INPUT_BUFFER_FIELD
      0;                                   // PEAK_LEVEL
         
   .VAR/DM1 mute_cntrl_l_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_left_out,                // OFFSET_INPUT_PTR
      &$M.CVC.data.ZeroValue,              // OFFSET_PTR_STATE
      0;                                   // OFFSET_MUTE_VAL (always mute)

   .VAR/DM1 mute_cntrl_r_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_right_out,               // OFFSET_INPUT_PTR
      &$M.CVC.data.ZeroValue,              // OFFSET_PTR_STATE
      0;                                   // OFFSET_MUTE_VAL (always mute)
 
#if uses_STEREO_ENHANCEMENT

   .VAR/DM1    stereo_3d_enhancement.coeff_buf[8] = -0.38, 0.74, -0.44, 0.31, -0.34, 0.68, -0.44, 0.31;
   .VAR/DMCIRC stereo_3d_enhancement.delay1[$stereo_3d_enhancement.DELAY_BUFFER_SIZE];
   .VAR/DMCIRC stereo_3d_enhancement.delay2[$stereo_3d_enhancement.DELAY_BUFFER_SIZE];

   .VAR stereo_3d_enhancement_delay1_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH(stereo_3d_enhancement.delay1),                                     // size
         &stereo_3d_enhancement.delay1,                                            // read pointer
         &stereo_3d_enhancement.delay1 + $stereo_3d_enhancement.REFLECTION_DELAY;  // write pointer
         
   .VAR stereo_3d_enhancement_delay2_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH(stereo_3d_enhancement.delay2),                                     // size
         &stereo_3d_enhancement.delay2,                                            // read pointer
         &stereo_3d_enhancement.delay2 + $stereo_3d_enhancement.REFLECTION_DELAY;  // write pointer
         
   .VAR/DM2 stereo_3d_obj[$stereo_3d_enhancement.STRUC_SIZE] =
      &stream_map_left_in,                                      // INPUT_CH1_PTR_BUFFER_FIELD
      &stream_map_right_in,                                     // INPUT_CH2_PTR_BUFFER_FIELD
      &stream_map_left_out,                                     // OUTPUT_CH1_PTR_BUFFER_FIELD
      stream_map_right_out,                                     // OUTPUT_CH2_PTR_BUFFER_FIELD
      &stereo_3d_enhancement_delay1_cbuffer_struc,              // DELAY_1_BUFFER_FIELD
      &stereo_3d_enhancement_delay2_cbuffer_struc,              // DELAY_2_BUFFER_FIELD
      &stereo_3d_enhancement.coeff_buf,                         // COEFF_STRUC_FIELD
      $stereo_3d_enhancement.REFLECTION_DELAY,                  // REFLECTION_DELAY_SAMPLES_FIELD
      0,                                                        // MIX (currently not used)
      0,                                                        // SE_CONFIG
      $M.A2DP_LOW_LATENCY_2MIC.CONFIG.SPATIAL_BYPASS;           // BYPASS_BIT_MASK_FIELD
#endif

#ifdef uses_SPKR_EQ
 
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
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_CONFIG;
#endif  

#ifdef uses_BASS_BOOST

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
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_CONFIG;
#endif  

#ifdef uses_USER_EQ

   .VAR/DM2 user_eq_left_dm2[PEQ_OBJECT_SIZE(MAX_NUM_USER_EQ_STAGES)] =
      &stream_map_left_out,         // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_out,         // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_USER_EQ_STAGES,       // MAX_STAGES_FIELD
      0,                            // PARAM_PTR_FIELD
      0 ...;

   /* object for currently running EQs */
    .VAR/DM2 user_eq_right_dm2[PEQ_OBJECT_SIZE(MAX_NUM_USER_EQ_STAGES)] =
      &stream_map_right_out,         // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_right_out,         // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_USER_EQ_STAGES,        // MAX_STAGES_FIELD
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_CONFIG,  // PARAM_PTR_FIELD
      0 ...;

     // 6 configs 44.1 kHz & 48 kHz      
    .VAR/DM2 user_eq_bank_select[1 + (2 * MAX_NUM_USER_EQ_BANKS)] =
      MAX_NUM_USER_EQ_BANKS,
      0,  // index 0 = flat response (no eq)
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_CONFIG,
      0,  // index 0 = flat response (no eq)
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_CONFIG,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_CONFIG;
#endif

#if uses_COMPANDER
    .VAR/DM $cmpd_gain;
    .VAR cmpd100_obj_44kHz[$cmpd100.STRUC_SIZE] =
     64,                                                // OFFSET_CONTROL_WORD                0
     $M.A2DP_LOW_LATENCY_2MIC.CONFIG.COMPANDER_BYPASS,  // OFFSET_BYPASS_BIT_MASK             1
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
     $cmpd100.HEADROOM_OFFSET(2);                       // OFFSET_HEADROOM_COMPENSATION       29

.VAR cmpd100_obj_48kHz[$cmpd100.STRUC_SIZE] =
     64,                                                // OFFSET_CONTROL_WORD                0
     $M.A2DP_LOW_LATENCY_2MIC.CONFIG.COMPANDER_BYPASS,  // OFFSET_BYPASS_BIT_MASK             1
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
     $cmpd100.HEADROOM_OFFSET(2);                       // OFFSET_HEADROOM_COMPENSATION       29
#endif

// *****************************************************************************
// STREAM MAPS
// A stream object is created for each stream: IN_L, IN_R, DAC_L, and DAC_R.
// These objects are used to populate processing module data objects (such as
// aux_mix_dm1 and pass_thru_obj) with input pointers and output pointers so
// that processing modules (such as $tone_mix and $stream_copy.pass_thru) know
// where to get and write their data.
//
// Entries would be added to these objects if more processing modules were to be
// added to the system.

// left input stream map
   .VAR	  stream_map_left_in[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$M.a2dp_in.decoder_out_left_cbuffer_struc,           // $framesync_ind.CBUFFER_PTR_FIELD     
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $RCV_NUM_SAMPLES_PER_FRAME,               // $framesync_ind.FRAME_SIZE_FIELD
          $RCV_JITTER,                              // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_input_stream_ind,  // Distribute Function
          $frame_sync.update_input_streams_ind,     // Update Function  
          0 ...;    

// right input stream map
    .VAR  stream_map_right_in[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$M.a2dp_in.decoder_out_right_cbuffer_struc, // $framesync_ind.CBUFFER_PTR_FIELD     
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $RCV_NUM_SAMPLES_PER_FRAME,               // $framesync_ind.FRAME_SIZE_FIELD
          $RCV_JITTER,                              // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_input_stream_ind,  // Distribute Function
          $frame_sync.update_input_streams_ind,     // Update Function  
          0 ...;    

// left output stream map
    .VAR  stream_map_left_out[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$M.dac_out_resample.left_cbuffer_struc,  // $framesync_ind.CBUFFER_PTR_FIELD  
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $RCV_NUM_SAMPLES_PER_FRAME,               // $framesync_ind.FRAME_SIZE_FIELD
          $RCV_JITTER,                              // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_output_stream_ind, // Distribute Function
          $frame_sync.update_output_streams_ind,    // Update Function
          0 ...;

// right output stream map
    .VAR  stream_map_right_out[$framesync_ind.ENTRY_SIZE_FIELD] =
          &$M.dac_out_resample.right_cbuffer_struc, // $framesync_ind.CBUFFER_PTR_FIELD  
          0,                                        // $framesync_ind.FRAME_PTR_FIELD
          0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
          $RCV_NUM_SAMPLES_PER_FRAME,               // $framesync_ind.FRAME_SIZE_FIELD
          $RCV_JITTER,                              // $framesync_ind.JITTER_FIELD
          $frame_sync.distribute_output_stream_ind, // Distribute Function
          $frame_sync.update_output_streams_ind,    // Update Function
          0 ...;

// *****************************************************************************
// STREAM SETUP TABLE
// This table is used with $frame.distribute_streams and $frame.update_streams.
// Null terminated list of streams to process

     .VAR rcv_process_streams[] = 
        &stream_map_left_in,
        &stream_map_right_in,
        &stream_map_left_out,
        &stream_map_right_out,
    0;
    
// *****************************************************************************

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
    .VAR ModeProcTableRcv[$M.A2DP_LOW_LATENCY_2MIC.SYSMODE.MAX_MODES] =
        &StandBy_proc_funcs,
        &pass_thru_proc_funcs,
        &pass_thru_proc_funcs,
        &full_proc_funcs,
        &full_proc_funcs;     
        
// *****************************************************************************
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
       $M.audio_proc.stereo_copy.Process.func,  &pass_thru_obj,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;
       
   .VAR full_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
#if uses_STEREO_ENHANCEMENT
       $stereo_3d_enhancement,                  0,                   &stereo_3d_obj,
#else
       $M.audio_proc.stereo_copy.Process.func,  &pass_thru_obj,      0,
#endif
#ifdef uses_SPKR_EQ
       $receive_proc.peq.process,               &spkr_eq_left_dm2,   $M.A2DP_LOW_LATENCY_2MIC.CONFIG.SPKR_EQ_BYPASS,
       $receive_proc.peq.process,               &spkr_eq_right_dm2,  $M.A2DP_LOW_LATENCY_2MIC.CONFIG.SPKR_EQ_BYPASS,
#endif
#ifdef uses_BASS_BOOST
       $receive_proc.peq.process,               &boost_eq_left_dm2,  $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BASS_BOOST_BYPASS,
       $receive_proc.peq.process,               &boost_eq_right_dm2, $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BASS_BOOST_BYPASS,
#endif
#ifdef uses_USER_EQ
       $receive_proc.peq.process,               &user_eq_left_dm2,   $M.A2DP_LOW_LATENCY_2MIC.CONFIG.USER_EQ_BYPASS,
       $receive_proc.peq.process,               &user_eq_right_dm2,  $M.A2DP_LOW_LATENCY_2MIC.CONFIG.USER_EQ_BYPASS,
#endif
#if uses_COMPANDER
       $receive_proc.cmpd100.analysis,          &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
       $receive_proc.cmpd100.applygain,         &cmpd100_obj_44kHz,  &cmpd100_obj_48kHz,
#endif
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;
       
   .VAR StandBy_proc_funcs[] =
    // Function                                 r7                   r8
       $frame_sync.distribute_streams_ind,      &rcv_process_streams,0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_l_pk_dtct,    0,
       $M.audio_proc.peak_monitor.Process.func, &pcmin_r_pk_dtct,    0,
       $M.MUTE_CONTROL.Process.func,            &mute_cntrl_l_dm1,   0,
       $M.MUTE_CONTROL.Process.func,            &mute_cntrl_r_dm1,   0,
       $M.audio_proc.peak_monitor.Process.func, &dac_l_pk_dtct,      0,
       $M.audio_proc.peak_monitor.Process.func, &dac_r_pk_dtct,      0,
       $frame_sync.update_streams_ind,          &rcv_process_streams,0,
       0;
       
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

   .CODESEGMENT PM;

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
      M[r7+$MUTE_CONTROL.OFFSET_INPUT_PTR] = r0;
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
//    $M.receive_proc.peq.process
//
// DESCRIPTION:
//    front end for peq's. Exits if 0-stage.
//
// INPUTS:
//    - r7 = pointer to peq object
//    - r8 = pointer to bank select object
//
// OUTPUTS:
//    - none
//
//
// *****************************************************************************
.MODULE $receive_proc.peq;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

//------------------------------------------------------------------------------
initialize:
//------------------------------------------------------------------------------
// initialise parametric filter
// - if user_eq, then need to select filter bank, and adjust it depending on
//   sample rate.  If filter bank is zero, then don't update coefficients as
//   filtering is put into bypass by peq processing wrapper (below).
//   Bank 0 means flat curve, but is only valid if EQFLAT is enabled.
//   Bank 1 means use the peq 1 for 44.1 kHz or peq 7 for 48 kHz etc...
// - if not user_eq, then force filter bank to zero.  sample rate bank switch is
//   still performed.
//------------------------------------------------------------------------------
// on entry r7 = pointer to filter object
//          r8 = pointer to bank selection object
//------------------------------------------------------------------------------

    r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG];
    r5 = M[r8];     // Number of banks per sample rate
   
    // running user_eq so get selected bank number
    // speaker and base boost only have one bank
    r3 = r0 and $M.A2DP_LOW_LATENCY_2MIC.CONFIG.USER_EQ_SELECT;
    Null = r5 - 1;
    if Z r3=Null;

    // Use sample rate to update bank
    r1 = M[&$M.set_codec_rate.current_codec_sampling_rate];
    Null = r1 - 48000;
    if Z r3 = r3 + r5;

    // Access the requested Bank
    // PARAM_PTR_FIELD=Null for no Peq
    r8 = r8 + 1;
    r0 = M[r8 + r3];
    M[r7 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
    if Z rts;
    jump $audio_proc.peq.initialize;

//------------------------------------------------------------------------------
process:
//------------------------------------------------------------------------------
// peq processing wrapper
// - return without processing if bypassed
// - if running user_eq (BYPASS_BIT_MASK_FIELD == USER_EQ_BYPASS)
//     then check whether user eq bank is 0
//------------------------------------------------------------------------------
// on entry r7 = pointer to filter object (used by audio_proc.peq.process)
//          r8 = bypass mask
//------------------------------------------------------------------------------

    r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG];
    
    // check if EQ is bypassed
    null = r0 and r8;
    if NZ rts;
    
    // if Parameters is Null then no Peq
    Null = M[r7 + $audio_proc.peq.PARAM_PTR_FIELD];
    if Z rts;

    jump $audio_proc.peq.process;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.receive_proc.cmpd100.initialize/analysis/applygain
//
// DESCRIPTION:
//    front end for cmpd100 functions
//
// INPUTS:
//    - r7 = pointer to 44.1kHz cmpd100 object
//    - r8 = pointer to 48kHz cmpd100 object
//
// OUTPUTS:
//    - none
//
// CPU USAGE:
//    CODE memory:    12  words
//    DATA memory:    0  words
//
// *****************************************************************************
.MODULE $receive_proc.cmpd100;
   .CODESEGMENT PM;

initialize:
   // Set r8 dependent on the sample rate
   // There are two data objects for the compander. One for 44.1kHz and the other
   // for 48kHz.
   r0 = M[&$M.set_codec_rate.current_codec_sampling_rate];
   Null = r0 - 48000;
   if NZ r8 = r7;

   jump $cmpd100.initialize;

analysis:
   // Set r8 dependent on the sample rate
   // There are two data objects for the compander. One for 44.1kHz and the other
   // for 48kHz.
   r0 = M[&$M.set_codec_rate.current_codec_sampling_rate];
   Null = r0 - 48000;
   if NZ r8 = r7;

   jump $cmpd100.analysis;

applygain:
   // Set r8 dependent on the sample rate
   // There are two data objects for the compander. One for 44.1kHz and the other
   // for 48kHz.
   r0 = M[&$M.set_codec_rate.current_codec_sampling_rate];
   Null = r0 - 48000;
   if NZ r8 = r7;

   jump $cmpd100.applygain;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.receive_process
//
// DESCRIPTION:
// This routine is called from the main loop when a frame of data is ready
// to be processed.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
// *****************************************************************************
.MODULE $M.receive_process;
 .CODESEGMENT  PM;
 .DATASEGMENT  DM;
 
   .VAR PeakMipsRxFunc = 0;

   .VAR RxFuncMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
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

$ReceiveProcRun:
   // push rLink onto stack
   $push_rLink_macro;
   
   r3 = M[$M.codec_copy_handler.frame_proc_num_samples];
    
    r0 = &$M.a2dp_in.decoder_out_left_cbuffer_struc;
    call $cbuffer.calc_amount_data;
    Null = r0 - r3;
    if NEG jump $pop_rLink_and_rts;
    
    r0 = &$M.a2dp_in.decoder_out_right_cbuffer_struc;
    call $cbuffer.calc_amount_data;
    Null = r0 - r3;
    if NEG jump $pop_rLink_and_rts;
    
   r0 = &$M.dac_out_resample.left_cbuffer_struc;
    call $cbuffer.calc_amount_space;
    Null = r0 - r3;
    if NEG jump $pop_rLink_and_rts;
        
   r0 = &$M.dac_out_resample.right_cbuffer_struc;
    call $cbuffer.calc_amount_space;
    Null = r0 - r3;
    if NEG jump $pop_rLink_and_rts;
    
    Null = M[$M.CVC_SYS.AlgReInit];
    if NZ call $M.A2DP_LOW_LATENCY_2MIC.SystemReInitialize.func;   
    
    r8 = &RxFuncMips_data_block;
    call $M.mips_profile.mainstart;
    
    // load the existing value of dither type
    r2 = M[$M.system_config.data.dithertype];
    
    M[$M.dac_out.dither_left_op.param + $cbops.dither_and_shift.DITHER_TYPE_FIELD] = r2; 
    M[$M.dac_out.dither_right_op.param + $cbops.dither_and_shift.DITHER_TYPE_FIELD]= r2; 

    r1 = M[$M.CVC_SYS.cur_mode];
    r4 = M[$M.system_config.data.ModeProcTableRcv + r1];
    call $frame_sync.run_function_table;   
    
    r8 = &RxFuncMips_data_block;
    call $M.mips_profile.mainend;
      
    r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
    M[&PeakMipsRxFunc] = r0;
    
   // pop rLink from stack    
  jump $pop_rLink_and_rts;

.ENDMODULE;
