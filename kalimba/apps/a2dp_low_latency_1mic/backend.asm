// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2003)        http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************
// *****************************************************************************
// Backend for a2dp_low_latency_1mic
//
// Configuration : 
//      mSBC/WBS Encoder @ 16kHz
//      APTX-LL Decoder @ 44.1 or 48kHz stereo (APTX_ACL_SPRINT_ENABLE)
//      Faststream Decoder @ 44.1 or 48kHz Joint stereo (FASTSTREAM_ENABLE)
//      Timer Task @ 1ms
//
// Interface points :
//      decoder_in_cbuffer_struc
//      decoder_out_left_cbuffer_struc
//      decoder_out_right_cbuffer_struc
//
// Ports : 
//      CODEC_OUT_PORT
//      CODEC_IN_PORT
// *****************************************************************************
// *****************************************************************************
#include "codec_library.h"
#include "core_library.h"
#include "cbops_multirate_library.h"
#include "sr_adjustment_gaming.h"
#include "sbc_library.h"
#include "mips_profile.h"
#include "audio_proc_library.h"
#include "frame_sync_library.h"

#define FAST_STREAM_FRAME_LENGTH      36
#define MONITOR_CODEC_BUFFER_LEVEL    324    // in WORDS 
#define TARGET_CODEC_BUFFER_LEVEL_FS  288    // in WORDS 
#define TARGET_CODEC_BUFFER_LEVEL_LL  280    // in WORDS
#define SRA_MAXIMUM_RATE              0.005  // max value of SRA rate to compensate for drift between SRC & SNK(~+-250Hz)and jitter
#define SRA_AVERAGING_TIME            1      // in seconds (this is optimal value, smaller values might handle jitter better but might cause warping effect)
#define ABSOLUTE_MAXIMUM_CLOCK_MISMATCH_COMPENSATION    0.03     // this is absolute maximum value(3%), it is also capped to value received from vm

#define TMR_PERIOD_CODEC_COPY         1000   

.CONST  $CODEC_OUT_PORT         ($cbuffer.WRITE_PORT_MASK + 2);
.CONST  $CODEC_IN_PORT          (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_NO_SIGN_EXTEND) + 2);

// Run-time control of configuration
.MODULE $app_config;
   .DATASEGMENT DM;

   .VAR io = $INVALID_IO;
   .VAR flg = -1;
   
.ENDMODULE;

// VM message handlers for set_plugin, Set Codec rate, APTX-LL params
// *****************************************************************************
// MODULE:
//    $M.set_plugin
//
// FUNCTION
//    $M.set_plugin.func
//
// DESCRIPTION:
//    Handle the set plugin VM message
//    (this sets the connection type)
//
// INPUTS:
//    r1 = connection type:
//       FASTSTREAM       = 4
//       APTX_ACL_SPRINT  = 7
//
// OUTPUTS:
//    none
//
// TRASHES: r0
//
// *****************************************************************************
.MODULE $M.set_plugin;
   .CODESEGMENT   PM;
   .DATASEGMENT   DM;

   .VAR codec_type   = -1;
   .VAR codec_config = -1;

func:
   // Allow only the first message ($app_config.io is initialised to -1)
   Null = M[$app_config.io];
   if POS rts;

   // Set the plugin type
   M[$app_config.io] = r1;

#ifdef FASTSTREAM_ENABLE

   Null = r1 - $FASTSTREAM_IO;
   if NZ jump skip_faststream;

      // Set the codec type to FASTSTREAM
      r0 = $FASTSTREAM_CODEC_TYPE;
      M[codec_type] = r0;

      // Set the codec config
      r0 = $FASTSTREAM_CODEC_CONFIG;
      M[codec_config] = r0;

      jump exit;

   skip_faststream:
#endif

#ifdef APTX_ACL_SPRINT_ENABLE

   Null = r1 - $APTX_ACL_SPRINT_IO;
   if NZ jump skip_aptx_acl_sprint;
   
      // Set the codec type to SPRINT
      r0 = $APTX_ACL_SPRINT_CODEC_TYPE;
      M[codec_type] = r0;
      
      // Set the codec config
      r0 = $APTX_ACL_SPRINT_CODEC_CONFIG;
      M[codec_config] = r0;
      
      jump exit;
   skip_aptx_acl_sprint:
#endif

   // Unknown codec
   jump $error;

   exit:
   rts;
   
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $set_codec_rate
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
.MODULE $M.set_codec_rate;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   .VAR current_codec_sampling_rate = 48000;
   .VAR current_voice_codec_sampling_rate = 0;

func:

   // Mask sign extension
   r1 = r1 AND 0xffff;
   // Scale to get sampling rate in Hz
   r1 = r1 * 10 (int);
   // Mask sign extension
   r2 = r2 AND 0xffff;
   // Scale to get sampling rate in Hz
   r2 = r2 * 10 (int);
   // Store the music forward channel codec sampling rate
   M[current_codec_sampling_rate] = r1;
   // Store the voice back channel codec sampling rate
   M[current_voice_codec_sampling_rate] = r2;

#ifdef LATENCY_REPORTING
        // update inverse of codec sample rate
        push rLink;
        r0 = M[current_codec_sampling_rate];
        call $latency.calc_inv_fs;
        M[$inv_codec_fs] = r0;
        pop rLink;
#endif 

   r0=1; 
   M[$M.A2DP_IN.codec_sr_flag] = r0;
   rts;
   
.ENDMODULE;

#ifdef APTX_ACL_SPRINT_ENABLE
// *****************************************************************************
// MODULE:
//    $aptx_ll_params1
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
.MODULE $M.aptx_ll_params1;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   .VAR target_codec_level  = TARGET_CODEC_BUFFER_LEVEL_LL;
   .VAR sra_max_rate        = SRA_MAXIMUM_RATE;
   .VAR sra_averaging_time  = SRA_AVERAGING_TIME;
   
func:

   M[target_codec_level]  = r1;
   M[sra_averaging_time]  = r4;
   rMac = r3;
   r0 = 20000;     // Divide by 10000 in rMac
   Div = rMac/r0;
   r3 = DivResult;
   M[sra_max_rate] = r3;
   
   rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $aptx_ll_params2
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
.MODULE $M.aptx_ll_params2;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   .VAR good_working_level  = GOOD_WORKING_BUFFER_LEVEL;
   
func:

   rMac = r1;
   if Z jump default_good_level;
   r0 = 2 * CODEC_CBUFFER_SIZE; // Divide by CBUFFER_SIZE to get as a fraction
   Div = rMac/r0;
   r1 = DivResult;
   jump updated_good_level;
   default_good_level:
   r1 = GOOD_WORKING_BUFFER_LEVEL;
   updated_good_level:
   M[good_working_level] = r1;
   
   rts;
.ENDMODULE;

#endif

// *****************************************************************************
.MODULE $M.A2DP_OUT;
   .DATASEGMENT DM;
   
    DeclareCBuffer(codec_out_cbuffer_struc,codec_out,CODEC_CBUFFER_SIZE);
    DeclareCBuffer(encoder_in_cbuffer_struc,encoder_in,CODEC_CBUFFER_SIZE);
    
    
   // allocate memory for codec stream structure
   .VAR/DM1 encoder_codec_stream_struc[$codec.av_encode.STRUC_SIZE] =
            0,                          // frame_encode function
            0,                          // reset_encoder function
            &codec_out_cbuffer_struc,   // out cbuffer
            &encoder_in_cbuffer_struc,  // in mono cbuffer
            0,
            0 ...;
            
    .VAR codec_out_copy_struc[] =
        $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
        &codec_out_copy_op,             // MAIN_FIRST_OPERATOR_FIELD
        &codec_out_copy_op,             // MTU_FIRST_OPERATOR_FIELD
        1,                              // NUM_INPUTS_FIELD
        &codec_out_cbuffer_struc,       // INPUT
        1,                              // NUM_OUTPUTS_FIELD
        $CODEC_OUT_PORT,                // OUTPUT
        0;                              // NUM_INTERNAL_FIELD
    
    .BLOCK codec_out_copy_op;
        .VAR codec_out_copy_op.prev_op = $cbops.NO_MORE_OPERATORS;
        .VAR codec_out_copy_op.next_op = $cbops.NO_MORE_OPERATORS; 
        .VAR codec_out_copy_op.func      = &$cbops.copy_op;
        .VAR codec_out_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
            0,                         // Input index
            1;                         // Output index
    .ENDBLOCK;      
    
.ENDMODULE;

// *****************************************************************************
.MODULE $M.A2DP_IN;
   .DATASEGMENT DM;
   .CODESEGMENT PM;

    DeclareCBuffer(decoder_out_left_cbuffer_struc,decoder_out_left,AUDIO_CBUFFER_SIZE);
    DeclareCBuffer(decoder_out_right_cbuffer_struc,decoder_out_right,AUDIO_CBUFFER_SIZE);
    DeclareCBuffer(decoder_in_cbuffer_struc,decoder_in,CODEC_CBUFFER_SIZE);
    
   .VAR codec_sr_flag = 0;
    
   .VAR codec_timer_struc[$timer.STRUC_SIZE]; 
   .VAR $sra_struct[$sra.STRUC_SIZE];
   
   // allocate memory for codec stream structure   
   .VAR/DM1 decoder_codec_stream_struc[$codec.av_decode.STRUC_SIZE] =
            0,                               // frame_decode function
            0,                               // reset_decoder function
            0,                               // silence_decoder function
            &decoder_in_cbuffer_struc,       // in cbuffer
            &decoder_out_left_cbuffer_struc, // out left cbuffer
            &decoder_out_right_cbuffer_struc,// out right cbuffer
            0,                               // MODE_FIELD
            0,                               // number of output samples
            0,                               // data object pointer placeholder
            30000,                           // DECODE_TO_STALL_THRESHOLD
            GOOD_WORKING_BUFFER_LEVEL,       // STALL_BUFFER_LEVEL_FIELD
            0,                               // NORMAL_BUFFER_LEVEL , POORLINK_DETECT_LEVEL - no longer used
            1,                               // Enable codec in buffer purge when in pause
            &$master_app_reset,              // Clear garbage samples during pause 
            0 ...;                           // Pad out remaining items with zeros   

#ifdef LATENCY_REPORTING

    // allocate meory for inverse of dac and codec sample rates
    .VAR $inv_codec_fs = $latency.INV_FS(48000);
    .VAR $inv_dac_fs = $latency.INV_FS(48000);
    
    .VAR $latency_calc_current_warp = &$M.dac_out_resample.sw_rate_left_op.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
        #define CURRENT_PORT_WARP 0
    
    .VAR cbuffers_latency_measure[] =
       &decoder_out_left_cbuffer_struc, &$inv_codec_fs, &$latency_calc_current_warp,
       &$M.dac_out_resample.left_cbuffer_struc, &$inv_dac_fs, &$latency_calc_current_warp,
       &$M.dac_out.left_cbuffer_struc, &$inv_dac_fs, &$latency_calc_current_warp,
       $AUDIO_LEFT_OUT_PORT, &$inv_dac_fs, CURRENT_PORT_WARP,
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
      &decoder_in_cbuffer_struc,
      &decoder_out_left_cbuffer_struc, &$inv_codec_fs, &$latency_calc_current_warp,
      3, // minimum over last three
      0 ...;
     // define cbuffers structure involved in pcm latency
     
#endif 

   .VAR codec_in_copy_struc[] =
          $cbops.scratch.BufferTable,        // BUFFER_TABLE_FIELD
          &codec_in_copy_op,                 // MAIN_FIRST_OPERATOR_FIELD
          &codec_in_copy_op,                 // MTU_FIRST_OPERATOR_FIELD
          1,                                 // NUM_INPUTS_FIELD
          $CODEC_IN_PORT,                    // INPUT
          1,                                 // NUM_OUTPUTS_FIELD
          &decoder_in_cbuffer_struc,         // OUTPUT
          0;                                 // NUM_INTERNAL_FIELD
          
   .BLOCK  codec_in_copy_op;
      .VAR codec_in_copy_op.prev_op = $cbops.NO_MORE_OPERATORS;
      .VAR codec_in_copy_op.next_op = $cbops.NO_MORE_OPERATORS;
      .VAR codec_in_copy_op.func = &$cbops.copy_op;
      .VAR codec_in_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
           0,                                // Input index
           1;                                // Output index
   .ENDBLOCK;
   
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $back_end
//
// DESCRIPTION:
//    Set up the system Back End for Faststream or APTX-LL codec
//
// INPUTS:
//    none
// OUTPUTS:
//    none
// *****************************************************************************
.MODULE $M.back_end;  
   .CODESEGMENT PM;
   .DATASEGMENT DM;
    
    .VAR codec_reset_needed=1;
    .VAR monitor_level = MONITOR_CODEC_BUFFER_LEVEL;
    .VAR PeakMipsDecoder = 0;
    .VAR PeakMipsEncoder  = 0;
    
    .VAR DecoderMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
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
     
    .VAR EncoderMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
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

$ConfigureBackEnd: 
   // push rLink onto stack
   $push_rLink_macro;
   
   r1 = M[$app_config.io];
   Null = r1 - $FASTSTREAM_IO;
   if NZ jump skip_faststream;
   
#ifdef FASTSTREAM_ENABLE

     // Set up the Rate Adaptation 
     // Set up the SRA struc for the A2DP connection
      r0 = (SRA_AVERAGING_TIME*1000000)/TMR_PERIOD_CODEC_COPY;
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      
      r0 = $CODEC_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = r0;
      
      r0 = &$M.A2DP_IN.decoder_in_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      
      r0 = &$M.A2DP_IN.decoder_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      
      r1 = M[&$M.set_codec_rate.current_codec_sampling_rate];
      null = r1 - 44100;
      if NZ jump not_44100_fs;
      
         // 44.1kHz codec operation
         // Set the maximum rate (fractional max rate adjustment, nominal 0.005)
         r0 = SRA_MAXIMUM_RATE;
         M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
         
         // Number of samples collected over averaging time
         r0 = r1 * SRA_AVERAGING_TIME (int);
         M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;
         
         // Set the desired monitor buffer level
         r0 = MONITOR_CODEC_BUFFER_LEVEL;
         M[&$M.back_end.monitor_level] = r0;
         
         // Set the target level
         r0 = ((TARGET_CODEC_BUFFER_LEVEL_FS*1.0)/(2.0*CODEC_CBUFFER_SIZE))+0.02;
         M[$sra_struct + $sra.TARGET_LEVEL_FIELD] = r0;
         
         jump sra_conf_done_fs;
         
 not_44100_fs:
 
      null = r1 - 48000;
      if NZ jump not_48000_fs;
      
         // 48kHz codec operation
         // Set the maximum rate (fractional max rate adjustment, nominal 0.005)
         r0 = SRA_MAXIMUM_RATE;
         M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
         
         // Number of samples collected over averaging time
         r0 = r1 * SRA_AVERAGING_TIME (int);
         M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;
         
         // Set the desired monitor buffer level
         r0 = MONITOR_CODEC_BUFFER_LEVEL + FAST_STREAM_FRAME_LENGTH;
         M[&$M.back_end.monitor_level] = r0;
         
         // Set the target level
         r0 = 1.0884*(((TARGET_CODEC_BUFFER_LEVEL_FS*1.0)/(2.0*CODEC_CBUFFER_SIZE))+0.02);
         M[$sra_struct + $sra.TARGET_LEVEL_FIELD] = r0;
         jump sra_conf_done_fs;
         
      not_48000_fs:
      // Unsupported codec rate (must be 44.1kHz or 48kHz)
      jump $error;
      sra_conf_done_fs:
      
     // Set up the decoder structure for SBC
     r0 = $sbcdec.frame_decode;
     M[$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
     
     r0 = $sbcdec.reset_decoder;
     M[$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
     
     r0 = $sbcdec.silence_decoder;
     M[$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;

     // Initialise the SBC decoder library, this will also set memory pointer
     // pass in the start of the decoder structure nested inside av_decode structure,
     // so init function will set the data object pointer field of it.
     r5 = $M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.DECODER_STRUC_FIELD;
     call $sbcdec.init_static_decoder;
     
     // Set up the encoder structure for SBC
     r0 = $sbcenc.frame_encode;
     M[$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.ADDR_FIELD] = r0;
     
     r0 = $sbcenc.reset_encoder;
     M[$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.RESET_ADDR_FIELD] = r0;
     
     r5 = &$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.ENCODER_STRUC_FIELD;
     call $sbcenc.init_static_encoder;
   
     //set sbc encoder for fast stream
     r0 = &$faststream.sbcenc_post_func;
     M[&$sbcenc.pre_post_proc_struc + $codec.pre_post_proc.POST_PROC_FUNC_ADDR_FIELD] = r0;

#endif

skip_faststream:

   Null = r1 - $APTX_ACL_SPRINT_IO;
   if NZ jump skip_aptx_acl_sprint;
   
#ifdef APTX_ACL_SPRINT_ENABLE
     // Set up the Rate Adaptation for sprint
     // Set up the SRA struc for the A2DP connection
      r0 = (SRA_AVERAGING_TIME*1000000)/TMR_PERIOD_CODEC_COPY;
      M[$sra_struct + $sra.TAG_DURATION_FIELD] = r0;
      
      r0 = $CODEC_IN_PORT;
      M[$sra_struct + $sra.CODEC_PORT_FIELD] = r0;
      
      r0 = &$M.A2DP_IN.decoder_in_cbuffer_struc;
      M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD] = r0;
      
      r0 = &$M.A2DP_IN.decoder_out_left_cbuffer_struc;
      M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD] = r0;
      
      r0 = M[&$M.aptx_ll_params1.sra_max_rate];
      M[$sra_struct + $sra.MAX_RATE_FIELD] = r0;
      
      r1 = M[&$M.set_codec_rate.current_codec_sampling_rate];
      r0 = M[&$M.aptx_ll_params1.sra_averaging_time];
      r0 = r1 * r0 (int); 
      // Number of samples collected over averaging time
      M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r0;
      
      r0 = M[&$M.aptx_ll_params2.good_working_level];
      M[&$M.A2DP_IN.decoder_codec_stream_struc + $codec.stream_decode.GOOD_WORKING_BUFLEVEL_FIELD] = r0;
      
      Null = r1 - 44100;
      if NZ jump not_44100_sp;
         // 44.1kHz codec operation
         // Set the target level
         r2 = M[&$M.aptx_ll_params1.target_codec_level];
         r2 = r2 + 20;                // Add a fraction more to target (0.02)
         r0 = 2 * CODEC_CBUFFER_SIZE; // Divide by CBUFFER_SIZE
         rMac = r2;
         Div = rMac/r0;
         r0 = DivResult;
         M[$sra_struct + $sra.TARGET_LEVEL_FIELD] = r0;
         jump sra_conf_done_sp;
         
 not_44100_sp:

      Null = r1 - 48000;
      if NZ jump not_48000_sp;
      
         // 48kHz codec operation
         // Set the target level
         r2 = M[&$M.aptx_ll_params1.target_codec_level];
         r2 = r2 + 20;                // Add a fraction more to target (0.02)
         r0 = 2 * CODEC_CBUFFER_SIZE; // Divide by CBUFFER_SIZE
         rMac = r2;
         Div = rMac/r0;
         r0 = DivResult;
         r1 = r1 * 0.0884 (frac);
         M[$sra_struct + $sra.TARGET_LEVEL_FIELD] = r0 + r1;
         jump sra_conf_done_sp;
         
      not_48000_sp:
      // Unsupported codec rate (must be 44.1kHz or 48kHz)
      jump $error;
      sra_conf_done_sp:

     // Set up the decoder structure for APTX_ACL_SPRINT
     r0 = $aptx_sprint.decode;
     M[$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
     
     r0 = $aptx_sprint.reset_decoder;
     M[$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
     
     r0 = $aptx_sprint.silence_decoder;
     M[$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;
     
     // Initialise the APTX_ACL_SPRINT decoder library
     call $aptx_sprint.init_decoder;
     
     // Set up the encoder structure for WB SBC
     r0 = $wbsenc.wbs_frame_encode;
     M[$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.ADDR_FIELD] = r0;
     
     r0 = $sbcenc.reset_encoder;
     M[$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.RESET_ADDR_FIELD] = r0;
     
     r5 = &$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.ENCODER_STRUC_FIELD;
     call $sbcenc.init_static_encoder;
  
     r5 = &$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.ENCODER_STRUC_FIELD;
     call $wbsenc.init_encoder;
     
     //set sbc encoder for fast stream
     r0 = &$faststream.sbcenc_post_func;
     M[&$sbcenc.pre_post_proc_struc + $codec.pre_post_proc.POST_PROC_FUNC_ADDR_FIELD] = r0;  
        
#endif
skip_aptx_acl_sprint:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

$BackEndStart:
   // push rLink onto stack
    $push_rLink_macro;

   // Get the codec sampling rate
   r1 = M[&$M.set_codec_rate.current_codec_sampling_rate];

   r1 = r1 * SRA_AVERAGING_TIME (int);
   M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD] = r1;

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
   // bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
   r3 = M[&$M.set_dac_rate.long_term_mismatch];   
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

   end:
   // start timer that copies codec data
   r1 = &$M.A2DP_IN.codec_timer_struc;
   r2 = TMR_PERIOD_CODEC_COPY;
   r3 = &$codec_copy_handler;
   call $timer.schedule_event_in;

   r1 = M[$app_config.io];
   Null = r1 - $APTX_ACL_SPRINT_IO;
   if NZ jump skip_aptx_acl_sprint1;
   
#ifdef APTX_ACL_SPRINT_ENABLE
   // Start in stalled mode until data arrives
   r5 = &$M.A2DP_IN.decoder_codec_stream_struc;
   r0 = $codec.NOT_ENOUGH_INPUT_DATA;
   M[r5 + $codec.av_decode.MODE_FIELD] = r0;
#endif

skip_aptx_acl_sprint1:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

$EncodeOutput: 
   // push rLink onto stack
   $push_rLink_macro;
    
    // Latency control will be handled by frame process selection of "Jitter"       
    // reset encoder if needed
    Null = M[codec_reset_needed];
    if Z jump no_codec_reset;
        r5 = &$M.A2DP_OUT.encoder_codec_stream_struc;
        r0 = M[r5 + $codec.av_encode.RESET_ADDR_FIELD];
        r5 = r5 + $codec.av_encode.ENCODER_STRUC_FIELD;
        call r0;
        M[codec_reset_needed] = 0;
    no_codec_reset:
    
    r8 = &EncoderMips_data_block;
    call $M.mips_profile.mainstart;
          
    // call encoder for voice channel
    r5 = &$M.A2DP_OUT.encoder_codec_stream_struc;
    call $codec.av_encode;
    
    r8 = &EncoderMips_data_block;
    call $M.mips_profile.mainend;
    
    r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
    M[&PeakMipsEncoder] = r0;
    
   // pop rLink from stack
   jump $pop_rLink_and_rts;

$DecodeInput:

   // push rLink onto stack
   $push_rLink_macro;

      r8 = &DecoderMips_data_block;
      call $M.mips_profile.mainstart;
      
      // decode a frame
      r5 = &$M.A2DP_IN.decoder_codec_stream_struc;
      call $codec.av_decode;
      
#ifdef LATENCY_REPORTING
      Null = M[$M.configure_latency_reporting.enabled];
      if Z jump skip_latency_measurement;
         r7 = &$encoded_latency_struct;
         call $latency.calc_encoded_latency;
      skip_latency_measurement:
#endif 
      
      // Stop profiler
      r8 = &DecoderMips_data_block;
      call $M.mips_profile.mainend;
      
      // Store Decoder MIPS
      r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
      M[&PeakMipsDecoder] = r0;
      
      call $sra_calcrate;
      
      // Check for Successful decode operation
      r0 = M[&$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.MODE_FIELD ];
      Null = r0 - $codec.SUCCESS;
      if NZ jump $pop_rLink_and_rts;
      
   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $codec_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the copying of encoded
//    samples from the input, and decoded samples to the output.
//
// *****************************************************************************
.MODULE $M.codec_copy_handler;
   .CODESEGMENT CODEC_COPY_HANDLER_PM;
   .DATASEGMENT DM;

   .VAR glob_counter_removeframe;  
   .VAR byte0;
   .VAR byte1;
   .VAR byte0_flag;
   .VAR packet_size_obtained;
   .VAR frame_proc_num_samples = 160;
   .VAR initial_write_pos = 0;
   
$codec_copy_handler:

    // push rLink onto stack
    $push_rLink_macro;
    
    r0 = M[&$M.A2DP_IN.decoder_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD]; 
    M[initial_write_pos] = r0;
    
#ifdef LATENCY_REPORTING
    M[$codec_packets_info_last_write_address] = r0;
#endif
    
   //calculate mismatch rate
   call $sra_tagtimes;
   
   r1 = M[$app_config.io];
   Null = r1 - $FASTSTREAM_IO;
   if NZ jump skip_faststream1;
    
#ifdef FASTSTREAM_ENABLE
        
   // Monitoring the level of input buffer, as the delay that can be tolerated is limited
   // the buffer level needs to have an upper limit, if it passes this limit and audio buffers are also virtually full, then
   // some audio samples are discarded from buffers as sra cannot compensate this, in normal operation this doesnt happen, but if for any reason
   // the buffer sizes becomes large, this operation gaurantees to keep the delay less than a limit
   
   // check the codec buffer level
   r0 = &$M.A2DP_IN.decoder_in_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r10 = r0- M[&$M.back_end.monitor_level];
   if NEG jump no_need_to_discard;

   // check the left audio buffer space level
   r0 = &$M.A2DP_IN.decoder_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   r10 = r0 - 64;
   if POS jump no_need_to_discard;

   // check the left right buffer space level
   r0 = &$M.A2DP_IN.decoder_out_right_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   r10 = r0 - 64;
   if POS jump no_need_to_discard;
   
     // both codec and audio buffers are full, so throw away some audio samples
      r0 = M[glob_counter_removeframe];
     r0 =  r0 + 1;
      M[glob_counter_removeframe] = r0;

     //left buffer
     r0 = &$M.A2DP_IN.decoder_out_left_cbuffer_struc;
     call $cbuffer.get_read_address_and_size;
     I0 = r0;
     L0 = r1;
     M0 = 128;
     r0 = M[I0, M0];
     r0 = &$M.A2DP_IN.decoder_out_left_cbuffer_struc;
     r1 = I0;
     call $cbuffer.set_read_address;

     //right buffer
     r0 = &$M.A2DP_IN.decoder_out_right_cbuffer_struc;
     call $cbuffer.get_read_address_and_size;
     I0 = r0;
     L0 = r1;
     M0 = 128;
     r0 = M[I0, M0];
     r0 = &$M.A2DP_IN.decoder_out_right_cbuffer_struc;
     r1 = I0;
     call $cbuffer.set_read_address;
     L0 = 0;

   no_need_to_discard:
   
#endif

skip_faststream1:

   r1 = M[$app_config.io];
   Null = r1 - $APTX_ACL_SPRINT_IO;
   if NZ jump skip_aptx_acl_sprint;
   
#ifdef APTX_ACL_SPRINT_ENABLE

   // Force an MMU buffer set 
   Null = M[$PORT_BUFFER_SET];
   
   // Get amount of data (in bytes) in input port
   r0 = $CODEC_IN_PORT;
   call $cbuffer.calc_amount_data;
   Null = r1;
   if Z jump copy_done; // Don't do anything if no data available
   
   // Was there an odd byte (byte0) remaining on the last copy from the port
   Null = M[byte0_flag];
   if Z jump no_odd_byte;
   
      // Get amount of space (in words) in output buffer
      r0 = &$M.A2DP_IN.decoder_in_cbuffer_struc;
      call $cbuffer.calc_amount_space;
      Null = r0;
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
      r0 = &$M.A2DP_IN.decoder_in_cbuffer_struc;
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
      r0 = &$M.A2DP_IN.decoder_in_cbuffer_struc;
      r1 = I0;
      call $cbuffer.set_write_address;
      
      // Clear the flag
      M[byte0_flag] = 0;
      
   no_odd_byte:

#endif

skip_aptx_acl_sprint: 

   // copy data from the port to the cbuffer
   r8 = &$M.A2DP_IN.codec_in_copy_struc;
   call $cbops_multirate.copy;
   
   r1 = M[$app_config.io];
   Null = r1 - $APTX_ACL_SPRINT_IO;
   if NZ jump skip_aptx_acl_sprint1;
   
#ifdef APTX_ACL_SPRINT_ENABLE

   // Force an MMU buffer set 
   Null = M[$PORT_BUFFER_SET];
   
   // Get amount of data (in bytes) in input port
   r0 = $CODEC_IN_PORT;
   call $cbuffer.calc_amount_data;
   
   // Only 1 byte left?
   Null = r1 - 1;
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

#endif
skip_aptx_acl_sprint1:

#ifdef LATENCY_REPORTING
   Null = M[$M.configure_latency_reporting.enabled];
   if Z jump skip_packet_detection;
        call $media_packet_boundary_detection;
   skip_packet_detection:
#endif 

   Null = M[packet_size_obtained];
   if NZ jump packet_length_obtained;
   
   r2 = M[&$M.A2DP_IN.decoder_in_cbuffer_struc + $cbuffer.SIZE_FIELD]; 
   r0 = M[&$M.A2DP_IN.decoder_in_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD]; 
   r0 = r0 - M[initial_write_pos];
   if Z jump packet_length_obtained;
   if NEG r0 = r0 + r2; 
   
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
      if Z jump packet_length_obtained;

      M[frame_proc_num_samples] = r1;
    
      M[$M.system_config.data.stream_map_left_in + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      M[$M.system_config.data.stream_map_right_in + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      M[$M.system_config.data.stream_map_left_out + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      M[$M.system_config.data.stream_map_right_out + $framesync_ind.FRAME_SIZE_FIELD] = r1;
      
   packet_length_obtained:
   
   // copy coded data in multiple frame chunks
   r8 = $M.A2DP_OUT.codec_out_copy_struc;
   r0 = M[$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.OUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   NULL = r0 - (200/2);
   if GE call $cbops_multirate.copy;

   // post another timer event
   r1 = &$M.A2DP_IN.codec_timer_struc;
   r2 = TMR_PERIOD_CODEC_COPY;
   r3 = &$codec_copy_handler;
   call $timer.schedule_event_in_period;
   jump $pop_rLink_and_rts;

.ENDMODULE;
