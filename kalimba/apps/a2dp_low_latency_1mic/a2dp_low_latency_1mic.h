// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#ifndef cvc_headset_1mic_LIB_H
#define cvc_headset_1mic_LIB_H

#include "a2dp_low_latency_1mic_config.h"
#include "a2dp_low_latency_1mic_library_gen.h"

.CONST  $AUDIO_IF_MASK                       (0x00ff);       // Mask to select the audio i/f info
.CONST  $LOCAL_PLAYBACK_MASK                 (0x0100);       // Mask to select the local playback control bit

.CONST  $cmpd100.OFFSET_CONTROL_WORD            0;
.CONST  $cmpd100.OFFSET_ENABLE_BIT_MASK         1;
.CONST  $cmpd100.OFFSET_INPUT_CH1_PTR           2;
.CONST  $cmpd100.OFFSET_INPUT_CH2_PTR           3;
.CONST  $cmpd100.OFFSET_OUTPUT_CH1_PTR          4;
.CONST  $cmpd100.OFFSET_OUTPUT_CH2_PTR          5;
.CONST  $cmpd100.OFFSET_MAKEUP_GAIN             6;
.CONST  $cmpd100.OFFSET_GAIN_PTR                7;
.CONST  $cmpd100.OFFSET_NEG_ONE                 8;
.CONST  $cmpd100.OFFSET_POW2_NEG4               9;
.CONST  $cmpd100.OFFSET_EXPAND_THRESHOLD        10;
.CONST  $cmpd100.OFFSET_LINEAR_THRESHOLD        11;
.CONST  $cmpd100.OFFSET_COMPRESS_THRESHOLD      12;
.CONST  $cmpd100.OFFSET_LIMIT_THRESHOLD         13;
.CONST  $cmpd100.OFFSET_INV_EXPAND_RATIO        14;
.CONST  $cmpd100.OFFSET_INV_LINEAR_RATIO        15;
.CONST  $cmpd100.OFFSET_INV_COMPRESS_RATIO      16;
.CONST  $cmpd100.OFFSET_INV_LIMIT_RATIO         17;
.CONST  $cmpd100.OFFSET_EXPAND_CONSTANT         18;
.CONST  $cmpd100.OFFSET_LINEAR_CONSTANT         19;
.CONST  $cmpd100.OFFSET_COMPRESS_CONSTANT       20;
.CONST  $cmpd100.OFFSET_EXPAND_ATTACK_TC        21;
.CONST  $cmpd100.OFFSET_EXPAND_DECAY_TC         22;
.CONST  $cmpd100.OFFSET_LINEAR_ATTACK_TC        23;
.CONST  $cmpd100.OFFSET_LINEAR_DECAY_TC         24;
.CONST  $cmpd100.OFFSET_COMPRESS_ATTACK_TC      25;
.CONST  $cmpd100.OFFSET_COMPRESS_DECAY_TC       26;
.CONST  $cmpd100.OFFSET_LIMIT_ATTACK_TC         27;
.CONST  $cmpd100.OFFSET_LIMIT_DECAY_TC          28;
.CONST  $cmpd100.OFFSET_HEADROOM_COMPENSATION   29;
.CONST  $cmpd100.STRUC_SIZE                     30;

// I/O configuration enum matches the PLUGIN type from the VM
.CONST  $INVALID_IO                          -1;
.CONST  $FASTSTREAM_IO                       4;
.CONST  $APTX_ACL_SPRINT_IO                  7;

// Codec configuration offsets
.CONST $FASTSTREAM_CODEC_CONFIG              $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC1_CONFIG;
.CONST $APTX_ACL_SPRINT_CODEC_CONFIG         $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC2_CONFIG;

// Codec types
.CONST  $FASTSTREAM_CODEC_TYPE               0;
.CONST  $APTX_ACL_SPRINT_CODEC_TYPE          1;

// Defines needed in both main and config file are unified here, instead of replicating them on each file.

#define uses_RCV_VAD       (uses_AEC)

.CONST   $CVC.TASK.OFFSET_SND_PROCESS                    0;
.CONST   $CVC.TASK.OFFSET_SND_PROCESS_TRIGGER            1;

.CONST   $CVC.BW.PARAM.SYS_FS                            0;
.CONST   $CVC.BW.PARAM.Num_Samples_Per_Frame             1;
.CONST   $CVC.BW.PARAM.Num_FFT_Freq_Bins                 2;
.CONST   $CVC.BW.PARAM.Num_FFT_Window                    3;
.CONST   $CVC.BW.PARAM.OMS_MODE_OBJECT                   5;
.CONST   $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL             6;
.CONST   $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL              7;
.CONST   $CVC.BW.PARAM.AEC_PTR_NZ_TABLES                 8;
.CONST   $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR                 9;
.CONST   $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR              10;
.CONST   $CVC.BW.PARAM.FB_CONFIG_AEC                     13;
.CONST   $CVC.BW.PARAM.BANDWIDTH_ID                      14;

.CONST   $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD        0;
.CONST   $M.CVC.vad_hold.PTR_ECHO_FLAG_FIELD       1;
.CONST   $M.CVC.vad_hold.FLAG_FIELD                2;
.CONST   $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD    3;
.CONST   $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD      4;
.CONST   $M.CVC.vad_hold.STRUC_SIZE                5;
#define CVC_BANK_CONFIG_HANNING_WB                 $filter_bank.config.frame120_proto240_fft256
#define CVC_BANK_CONFIG_NONHANNING_WB              $filter_bank.config.frame120_proto480_fft256


   // --------------------------------------------------------------------------
   // Memory Allocation: WB 
   // --------------------------------------------------------------------------
   .CONST $M.CVC.Num_FFT_Freq_Bins                 129;
   .CONST $M.CVC.Num_Samples_Per_Frame             120;
   .CONST $M.CVC.Num_FFT_Window                    240;

   .CONST $M.CVC.ADC_DAC_Num_Samples_Per_Frame     $M.CVC.Num_Samples_Per_Frame;
   .CONST $M.CVC.ADC_DAC_Num_FFT_Freq_Bins         $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY  ($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame);

   .CONST $SAMPLE_RATE_ADC_DAC                     16000;
   .CONST $BLOCK_SIZE_ADC_DAC                      120;

   .CONST $SAMPLE_RATE                             16000;
   .CONST $BLOCK_SIZE_SCO                          120;

   .CONST $M.oms270.FFT_NUM_BIN                    $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.oms270.STATE_LENGTH                   $M.oms270.wide_band.STATE_LENGTH;
   .CONST $M.oms270.SCRATCH_LENGTH                 $M.oms270.wide_band.SCRATCH_LENGTH;

   #define FFT_TWIDDLE_NEED_256_POINT

   // Reserve buffers fo 2-channel fft128 filter_bank
   #define FFT_BUFFER_SIZE                         ($M.filter_bank.Parameters.FFT256_BUFFLEN *2)

   // Number of sample needed for reference delay buffer
   // wmsn: wideband may capable of more delay than original design
   #define Max_RefDelay_Sample                     ($M.CVC.Num_Samples_Per_Frame * 4)

   // --------------------------------------------------------------------------
   // Bandwidth Selection: WB
   // --------------------------------------------------------------------------
   #define $M.CVC.BANDWIDTH.DEFAULT                $M.CVC.BANDWIDTH.WB
   #define $FAR_END.AUDIO.DEFAULT_CODING           $FAR_END.AUDIO.SCO_SBC

   #define CVC_SYS_FS                              $M.CVC.BANDWIDTH.WB_FS
   #define CVC_DEFAULT_PARAMETERS                  &$M.CVC.data.DefaultParameters_wb

   #define CVC_AEC_LPWRX_MARGIN_OVFL               &$M.AEC_500_WB.LPwrX_margin.overflow_bits
   #define CVC_AEC_LPWRX_MARGIN_SCL                &$M.AEC_500_WB.LPwrX_margin.scale_factor
   #define CVC_AEC_PTR_NZ_TABLES                   &$M.AEC_500.wb_constants.nzShapeTables

   #define CVC_VAD_PEQ_PARAM_PTR                   &$M.CVC.data.vad_peq_parameters_wb
   #define CVC_DCBLOC_PEQ_PARAM_PTR                &$M.CVC.data.dcblock_parameters_wb

   #define M_oms270_mode_object                    &$M.oms270.mode.wide_band.object

   #define CVC_BANK_CONFIG_AEC                     CVC_BANK_CONFIG_HANNING_WB

   // bandwidth run-time selectable
   #define CVC_SET_BANDWIDTH                       &$set_variant_from_vm
   
#endif
