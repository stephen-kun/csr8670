// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef cvc_headset_2mic_LIB_H
#define cvc_headset_2mic_LIB_H

#include "a2dp_low_latency_2mic_config.h"
#include "a2dp_low_latency_2mic_library_gen.h"

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
.CONST $FASTSTREAM_CODEC_CONFIG              $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC1_CONFIG;
.CONST $APTX_ACL_SPRINT_CODEC_CONFIG         $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC2_CONFIG;

// Codec types
.CONST  $FASTSTREAM_CODEC_TYPE               0;
.CONST  $APTX_ACL_SPRINT_CODEC_TYPE          1;

// Defines needed in both main and config file are unified here, instead of replicating them on each file.
#define uses_RCV_VAD       (uses_AEC)
#define uses_SND_VAD       (uses_SND_AGC)
#define uses_IN0_OMS       (uses_MGDC || uses_NSVOLUME || uses_AEC)
// Define below to place code segments in flash
#include "flash.h"

.CONST   $CVC.BW.PARAM.SYS_FS                            0;
.CONST   $CVC.BW.PARAM.Num_Samples_Per_Frame             1;
.CONST   $CVC.BW.PARAM.Num_FFT_Freq_Bins                 2;
.CONST   $CVC.BW.PARAM.Num_FFT_Window                    3;
//.CONST   $CVC.BW.PARAM.SND_PROCESS_TRIGGER               4;
.CONST   $CVC.BW.PARAM.OMS_MODE_OBJECT                   5;
.CONST   $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL             6;
.CONST   $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL              7;
.CONST   $CVC.BW.PARAM.AEC_PTR_NZ_TABLES                 8;
.CONST   $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR                 9;
.CONST   $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR              10;
.CONST   $CVC.BW.PARAM.FB_CONFIG_RCV_ANALYSIS            11;
.CONST   $CVC.BW.PARAM.FB_CONFIG_RCV_SYNTHESIS           12;
.CONST   $CVC.BW.PARAM.FB_CONFIG_AEC                     13;
// Only for 2mic
.CONST   $CVC.BW.PARAM.BANDWIDTDH_ID                     14;
.CONST   $CVC.BW.PARAM.ASF_MODE                          15;
.CONST   $CVC.BW.PARAM.DMS_MODE                          16;
.CONST   $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD        0;
.CONST   $M.CVC.vad_hold.PTR_EVENT_FLAG_FIELD             1;
.CONST   $M.CVC.vad_hold.FLAG_FIELD                2;
.CONST   $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD    3;
.CONST   $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD      4;
.CONST   $M.CVC.vad_hold.STRUC_SIZE                5;

// -----------------------------------------------------------------------------
// FILTER_BANK CONFIG
// -----------------------------------------------------------------------------
#define CVC_BANK_CONFIG_HANNING_NB                 $filter_bank.config.frame60_proto120_fft128
#define CVC_BANK_CONFIG_HANNING_WB                 $filter_bank.config.frame120_proto240_fft256
#define CVC_BANK_CONFIG_NONHANNING_NB              $filter_bank.config.frame60_proto240_fft128
#define CVC_BANK_CONFIG_NONHANNING_WB              $filter_bank.config.frame120_proto480_fft256

#define uses_FBADM
#if !defined(uses_FBADM)
   #define FBA_CHNUM    1
   #define BExp_D0      fba_left + $M.filter_bank.Parameters.OFFSET_BEXP
   #define BExp_D1      fba_right + $M.filter_bank.Parameters.OFFSET_BEXP
#else
   #define FBA_CHNUM    2
   #define BExp_D0      fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_BEXP
   #define BExp_D1      fba_dm + $M.filter_bank.Parameters.OFFSET_CH2_BEXP
#endif
   // --------------------------------------------------------------------------
   // Memory Allocation: WB 
   // --------------------------------------------------------------------------
   .CONST $M.CVC.Num_FFT_Freq_Bins                 129;
   .CONST $M.CVC.Num_Samples_Per_Frame             120;
   .CONST $M.CVC.Num_FFT_Window                    240;
   .CONST $M.CVC.DAC_Num_Samples_Per_Frame         $M.CVC.Num_Samples_Per_Frame;
   .CONST $M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY  ($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame);
   .CONST $SAMPLE_RATE_DAC                         16000;
   .CONST $SAMPLE_RATE                             16000;
   .CONST $BLOCK_SIZE_ADC_DAC                      120;
   .CONST $M.oms270.FFT_NUM_BIN                    $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.oms270.STATE_LENGTH                   $M.oms270.wide_band.STATE_LENGTH;
   .CONST $M.oms270.SCRATCH_LENGTH                 $M.oms270.wide_band.SCRATCH_LENGTH;

   #if !defined(uses_FBADM)
      #define FFT_TWIDDLE_NEED_128_POINT
   #else
      #define FFT_TWIDDLE_NEED_256_POINT
   #endif

   // Reserve buffers for n-channel fft256 filter_bank
   #define FFT_BUFFER_SIZE                         ($M.filter_bank.Parameters.FFT256_BUFFLEN * FBA_CHNUM)
   // Number of sample needed for reference delay buffer
   #define Max_RefDelay_Sample                     ($M.CVC.Num_Samples_Per_Frame * 2)

   // --------------------------------------------------------------------------
   // Bandwidth Selection: WB
   // --------------------------------------------------------------------------
   #define $M.CVC.BANDWIDTH.DEFAULT                $M.CVC.BANDWIDTH.WB
   #define $FAR_END.AUDIO.DEFAULT_CODING           $FAR_END.AUDIO.SCO_SBC
   #define CVC_SYS_FS                              $M.CVC.BANDWIDTH.WB_FS
   #define CVC_DEFAULT_PARAMETERS                  &$M.CVC.data.DefaultParameters_wb
   #define CVC_SND_PROCESS_TRIGGER                 SND_PROCESS_TRIGGER_WB
   #define CVC_AEC_LPWRX_MARGIN_OVFL               &$M.AEC_500_WB.LPwrX_margin.overflow_bits
   #define CVC_AEC_LPWRX_MARGIN_SCL                &$M.AEC_500_WB.LPwrX_margin.scale_factor
   #define CVC_AEC_PTR_NZ_TABLES                   &$M.AEC_500.wb_constants.nzShapeTables
   #define CVC_VAD_PEQ_PARAM_PTR                   &$M.CVC.data.vad_peq_parameters_wb
   #define CVC_DCBLOC_PEQ_PARAM_PTR                &$M.CVC.data.dcblock_parameters_wb
   #define M_oms270_mode_object                    &$M.oms270.mode.wide_band.object
   #define M_dms100_mode_object                    &$dms100.wide_band.mode
   #define M_asf_mode_object                       &$asf100.mode.wide_band
   #define CVC_BANK_CONFIG_AEC                     CVC_BANK_CONFIG_HANNING_WB
   #define CVC_BANK_CONFIG_RCVIN                   CVC_BANK_CONFIG_HANNING_WB
   #define CVC_BANK_CONFIG_RCVOUT                  CVC_BANK_CONFIG_HANNING_WB
   
// -----------------------------------------------------------------------------
// DMSS Module Bypass Bit Mask
// -----------------------------------------------------------------------------
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.DMSS_MODE            $M.A2DP_LOW_LATENCY_2MIC.CONFIG.DMSS_MODE;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_MGDC          $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDC;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_WNR        	 $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_WNR;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_ADF        	 $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_ADF;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NC         	 $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_NC;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_DMS        	 $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_DMS;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_SPP        	 $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SPP;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NFLOOR        $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_NFLOOR;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_GSMOOTH       $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_GSMOOTH;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.GSCHEME              $M.A2DP_LOW_LATENCY_2MIC.CONFIG.GSCHEME;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_MGDCPERSIST   $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDCPERSIST;

#endif 
