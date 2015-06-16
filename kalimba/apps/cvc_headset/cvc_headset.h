// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef cvc_headset_SYS_H
#define cvc_headset_SYS_H

#include "plc100_library.h"
#include "audio_proc_library.h"
#include "cvc_headset_config.h"
#include "cvc_headset_library_gen.h"


// Defines needed in both main and config file are unified here, instead of replicating them on each file.
#define uses_RCV_FREQPROC  (uses_RCV_NS || uses_AEQ)
#define uses_RCV_VAD       (uses_RCV_AGC || uses_AEQ || uses_AEC)

// Send processing should be scheduled based on the peaks SEND_MIPS_FIELD (0-8000).
//     Trigger equals 11 - round[11*(SEND_MIPS_FIELD/8000)]
#define SND_PROCESS_TRIGGER_WB                           7   // 1788
#define SND_PROCESS_TRIGGER_FE                           8   // 1165
#define SND_PROCESS_TRIGGER_NB                           8   // 1062

.CONST   $CVC.TASK.OFFSET_SND_PROCESS                    0;
.CONST   $CVC.TASK.OFFSET_SND_PROCESS_TRIGGER            1;

.CONST   $CVC.BW.PARAM.SYS_FS                            0;
.CONST   $CVC.BW.PARAM.Num_Samples_Per_Frame             1;
.CONST   $CVC.BW.PARAM.Num_FFT_Freq_Bins                 2;
.CONST   $CVC.BW.PARAM.Num_FFT_Window                    3;
.CONST   $CVC.BW.PARAM.SND_PROCESS_TRIGGER               4;
.CONST   $CVC.BW.PARAM.OMS_MODE_OBJECT                   5;
.CONST   $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL             6;
.CONST   $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL              7;
.CONST   $CVC.BW.PARAM.AEC_PTR_NZ_TABLES                 8;
.CONST   $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR                 9;
.CONST   $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR              10;
.CONST   $CVC.BW.PARAM.FB_CONFIG_RCV_ANALYSIS            11;
.CONST   $CVC.BW.PARAM.FB_CONFIG_RCV_SYNTHESIS           12;
.CONST   $CVC.BW.PARAM.FB_CONFIG_AEC                     13;
// For ANC
.CONST   $CVC.BW.PARAM.BANDWIDTH_ID                      14;

.CONST   $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD        0;
.CONST   $M.CVC.vad_hold.PTR_ECHO_FLAG_FIELD       1;
.CONST   $M.CVC.vad_hold.FLAG_FIELD                2;
.CONST   $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD    3;
.CONST   $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD      4;
.CONST   $M.CVC.vad_hold.STRUC_SIZE                5;


#define CVC_BANK_CONFIG_HANNING_NB                 $filter_bank.config.frame60_proto120_fft128
#define CVC_BANK_CONFIG_HANNING_WB                 $filter_bank.config.frame120_proto240_fft256
#define CVC_BANK_CONFIG_NONHANNING_NB              $filter_bank.config.frame60_proto240_fft128
#define CVC_BANK_CONFIG_NONHANNING_WB              $filter_bank.config.frame120_proto480_fft256

#if defined(BLD_NB)
   // --------------------------------------------------------------------------
   // Memory Allocation: NB
   // --------------------------------------------------------------------------
   .CONST $M.CVC.Num_FFT_Freq_Bins                 65;
   .CONST $M.CVC.Num_Samples_Per_Frame             60;
   .CONST $M.CVC.Num_FFT_Window                    120;

   .CONST $M.CVC.ADC_DAC_Num_Samples_Per_Frame     $M.CVC.Num_Samples_Per_Frame;
   .CONST $M.CVC.ADC_DAC_Num_FFT_Freq_Bins         $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY  ($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame);

   .CONST $SAMPLE_RATE_ADC_DAC                     8000;
   .CONST $BLOCK_SIZE_ADC_DAC                      60;

   .CONST $SAMPLE_RATE                             8000;
   .CONST $BLOCK_SIZE_SCO                          60;

   .CONST $M.oms270.FFT_NUM_BIN                    $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.oms270.STATE_LENGTH                   $M.oms270.narrow_band.STATE_LENGTH;
   .CONST $M.oms270.SCRATCH_LENGTH                 $M.oms270.narrow_band.SCRATCH_LENGTH;

   .CONST $plc100.SP_BUF_LEN                       $plc100.SP_BUF_LEN_NB;
   .CONST $plc100.OLA_LEN                          $plc100.OLA_LEN_NB;

   #define FFT_TWIDDLE_NEED_128_POINT

   // Reserve buffers fo 2-channel fft128 filter_bank (or one at 256)
   #define FFT_BUFFER_SIZE                         ($M.filter_bank.Parameters.FFT128_BUFFLEN * 2)

   // Number of sample needed for reference delay buffer
   #define Max_RefDelay_Sample                     ($M.CVC.Num_Samples_Per_Frame * 8)

   // --------------------------------------------------------------------------
   // Bandwidth Selection: NB
   // --------------------------------------------------------------------------
   #define $M.CVC.BANDWIDTH.DEFAULT                $M.CVC.BANDWIDTH.NB
   #define $FAR_END.AUDIO.DEFAULT_CODING           $FAR_END.AUDIO.SCO_CVSD

   #define CVC_SYS_FS                              $M.CVC.BANDWIDTH.NB_FS
   #define CVC_DEFAULT_PARAMETERS                  &$M.CVC.data.DefaultParameters_nb
   #define CVC_SND_PROCESS_TRIGGER                 SND_PROCESS_TRIGGER_NB

   #define CVC_AEC_LPWRX_MARGIN_OVFL               &$M.AEC_500_NB.LPwrX_margin.overflow_bits
   #define CVC_AEC_LPWRX_MARGIN_SCL                &$M.AEC_500_NB.LPwrX_margin.scale_factor
   #define CVC_AEC_PTR_NZ_TABLES                   &$M.AEC_500.nb_constants.nzShapeTables

   #define CVC_VAD_PEQ_PARAM_PTR                   &$M.CVC.data.vad_peq_parameters_nb
   #define CVC_DCBLOC_PEQ_PARAM_PTR                &$M.CVC.data.dcblock_parameters_nb

   #define M_oms270_mode_object                    &$M.oms270.mode.narrow_band.object

   #define CVC_BANK_CONFIG_AEC                     CVC_BANK_CONFIG_HANNING_NB
   #define CVC_BANK_CONFIG_RCVIN                   CVC_BANK_CONFIG_HANNING_NB
   #define CVC_BANK_CONFIG_RCVOUT                  CVC_BANK_CONFIG_HANNING_NB

#elif defined(BLD_FE)
   // --------------------------------------------------------------------------
   // Memory Allocation: FE
   // --------------------------------------------------------------------------
   .CONST $M.CVC.Num_FFT_Freq_Bins                 65;
   .CONST $M.CVC.Num_Samples_Per_Frame             60;
   .CONST $M.CVC.Num_FFT_Window                    120;

   .CONST $M.CVC.ADC_DAC_Num_Samples_Per_Frame     2*$M.CVC.Num_Samples_Per_Frame;
   .CONST $M.CVC.ADC_DAC_Num_FFT_Freq_Bins         2*$M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY  2*($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame);

   .CONST $SAMPLE_RATE_ADC_DAC                     16000;
   .CONST $BLOCK_SIZE_ADC_DAC                      120;

   .CONST $SAMPLE_RATE                             8000;
   .CONST $BLOCK_SIZE_SCO                          60;

   .CONST $M.oms270.FFT_NUM_BIN                    $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.oms270.STATE_LENGTH                   $M.oms270.narrow_band.STATE_LENGTH;
   .CONST $M.oms270.SCRATCH_LENGTH                 $M.oms270.narrow_band.SCRATCH_LENGTH;

   .CONST $plc100.SP_BUF_LEN                       $plc100.SP_BUF_LEN_NB;
   .CONST $plc100.OLA_LEN                          $plc100.OLA_LEN_NB;

   #define FFT_TWIDDLE_NEED_256_POINT

   // Reserve buffers fo 2-channel fft128 filter_bank (or one at 256)
   #define FFT_BUFFER_SIZE                         ($M.filter_bank.Parameters.FFT128_BUFFLEN * 2)

   // Number of sample needed for reference delay buffer
   #define Max_RefDelay_Sample                     ($M.CVC.Num_Samples_Per_Frame * 8)

   // --------------------------------------------------------------------------
   // Bandwidth Selection: FE
   // --------------------------------------------------------------------------
   #define $M.CVC.BANDWIDTH.DEFAULT                $M.CVC.BANDWIDTH.FE
   #define $FAR_END.AUDIO.DEFAULT_CODING           $FAR_END.AUDIO.SCO_CVSD

   #define CVC_SYS_FS                              $M.CVC.BANDWIDTH.FE_FS
   #define CVC_DEFAULT_PARAMETERS                  &$M.CVC.data.DefaultParameters_fe
   #define CVC_SND_PROCESS_TRIGGER                 SND_PROCESS_TRIGGER_FE

   #define CVC_AEC_LPWRX_MARGIN_OVFL               &$M.AEC_500_NB.LPwrX_margin.overflow_bits
   #define CVC_AEC_LPWRX_MARGIN_SCL                &$M.AEC_500_NB.LPwrX_margin.scale_factor
   #define CVC_AEC_PTR_NZ_TABLES                   &$M.AEC_500.nb_constants.nzShapeTables

   #define CVC_VAD_PEQ_PARAM_PTR                   &$M.CVC.data.vad_peq_parameters_nb
   #define CVC_DCBLOC_PEQ_PARAM_PTR                &$M.CVC.data.dcblock_parameters_nb

   #define M_oms270_mode_object                    &$M.oms270.mode.narrow_band.object

   #define CVC_BANK_CONFIG_AEC                     CVC_BANK_CONFIG_HANNING_NB
   #define CVC_BANK_CONFIG_RCVIN                   CVC_BANK_CONFIG_HANNING_NB
   #define CVC_BANK_CONFIG_RCVOUT                  CVC_BANK_CONFIG_HANNING_WB

#else
   // --------------------------------------------------------------------------
   // Memory Allocation: WB and for combined NB/FE/WB run-time selectable
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

   .CONST $plc100.SP_BUF_LEN                       $plc100.SP_BUF_LEN_WB;
   .CONST $plc100.OLA_LEN                          $plc100.OLA_LEN_WB;

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
   #define CVC_SND_PROCESS_TRIGGER                 SND_PROCESS_TRIGGER_WB

   #define CVC_AEC_LPWRX_MARGIN_OVFL               &$M.AEC_500_WB.LPwrX_margin.overflow_bits
   #define CVC_AEC_LPWRX_MARGIN_SCL                &$M.AEC_500_WB.LPwrX_margin.scale_factor
   #define CVC_AEC_PTR_NZ_TABLES                   &$M.AEC_500.wb_constants.nzShapeTables

   #define CVC_VAD_PEQ_PARAM_PTR                   &$M.CVC.data.vad_peq_parameters_wb
   #define CVC_DCBLOC_PEQ_PARAM_PTR                &$M.CVC.data.dcblock_parameters_wb

   #define M_oms270_mode_object                    &$M.oms270.mode.wide_band.object

   #define CVC_BANK_CONFIG_AEC                     CVC_BANK_CONFIG_HANNING_WB
   #define CVC_BANK_CONFIG_RCVIN                   CVC_BANK_CONFIG_HANNING_WB
   #define CVC_BANK_CONFIG_RCVOUT                  CVC_BANK_CONFIG_HANNING_WB


#endif

// -----------------------------------------------------------------------------
// Bandwidth Configuration
// -----------------------------------------------------------------------------
#if defined(BLD_NB) || defined(BLD_FE) || defined(BLD_WB)
   // fixed bandwidth
   #define CVC_SET_BANDWIDTH                       0
#else
   // bandwidth run-time selectable
   #define CVC_SET_BANDWIDTH                       &$set_variant_from_vm
#endif

#endif //cvc_headset_LIB_H
