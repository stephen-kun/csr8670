// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1297331 $  $DateTime: 2012/05/07 17:19:34 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    CVC static configuration file that includes tables of function pointers
//    and their corresponding data objects.adapt_eq
//
//    Customer modification to this file is NOT SUPPORTED.
//
//    CVC configuration should be handled from within the cvc_headset_config.h
//    header file.
//
// *****************************************************************************

#include "stack.h"
#include "timer.h"
#include "frame_codec.h"
#include "cbops_multirate_library.h"
#include "cvc_modules.h"
#include "cvc_handsfree_2mic.h"
#include "cvc_system_library.h"
#include "frame_sync_buffer.h"
#include "cbuffer.h"
#include "frame_sync_tsksched.h"
#include "frame_sync_stream_macros.h"

// SP. Needs for Sample Rate converters
#include "operators\iir_resamplev2\iir_resamplev2_header.h"

#ifndef BUILD_MULTI_KAPS   // SP. moved to dsp_core
// declare twiddle factors
#include "fft_twiddle.h"
#endif
// temporary until application linkfile can configure this segment
#define USE_FLASH_ADDR_TABLES
#ifdef USE_FLASH_ADDR_TABLES
      #define ADDR_TABLE_DM DMCONST
#else
   #define ADDR_TABLE_DM DM
#endif


   .CONST $M.CVC.AEC.Num_FFT_Window       $M.CVC.Num_FFT_Window * AEC_WINDOW_FACTOR;

// Generate build error messages if necessary.

#if !uses_NSVOLUME && uses_VCAEC
   .error "VCAEC cannot be enabled without NDVC"
#endif

#if !uses_AEQ && uses_RCV_NS
   .warning "RCV_NS cannot be enabled without AEQ in BEX mode"
#endif

#if !uses_SND_NS
   #if uses_ADF
      .error "ADF cannot be enabled without SND_NS"
   #endif

   #if uses_AEC
      .error "AEC cannot be enabled without SND_NS"
   #endif
#endif

#define MAX_NUM_PEQ_STAGES             (5)


// System Configuration is saved in kap file.
.MODULE $M.CVC_MODULES_STAMP;
   .DATASEGMENT DM;
   .BLOCK ModulesStamp;
      .VAR  s1 = 0xfeeb;
      .VAR  s2 = 0xfeeb;
      .VAR  s3 = 0xfeeb;
      .VAR  CompConfig = CVC_HANDSFREE_2MIC_CONFIG_FLAG;
      .VAR  s4 = 0xfeeb;
      .VAR  s5 = 0xfeeb;
      .VAR  s6 = 0xfeeb;
   .ENDBLOCK;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.CVC_VERSION_STAMP
//
// DESCRIPTION:
//    This data module is used to write the CVC algorithm ID and build version
//    into the kap file in a readable form.
// *****************************************************************************

.MODULE $M.CVC_VERSION_STAMP;
   .DATASEGMENT DM;
   .BLOCK VersionStamp;
   .VAR  h1 = 0xfebeef;
   .VAR  h2 = 0x01beef;
   .VAR  h3 = 0xbeef;
   .VAR  SysID = $CVC_HEADSET_2MIC_SYSID;
   .VAR  BuildVersion = $CVC_VERSION;
   .VAR  h4 = 0xccbeef;
   .VAR  h5 = 0xbeef;
   .VAR  h6 = 0xbeef;
   .ENDBLOCK;
.ENDMODULE;


.MODULE $M.CVC.data;
   .DATASEGMENT DM;

   // Temp Variable to handle disabled modules.
   .VAR  ZeroValue = 0;
   .VAR  OneValue = 1.0;
   .VAR  $snd_agc_vad_reverse;
   
   // These lines write module and version information to the kap file.
   .VAR kap_version_stamp = &$M.CVC_VERSION_STAMP.VersionStamp;
   .VAR kap_modules_stamp = &$M.CVC_MODULES_STAMP.ModulesStamp;


   // Default Block
   .VAR/DMCONST16  DefaultParameters_wb[] =
        #include "cvc_handsfree_2mic_defaults_WB.dat"
   ;
   .VAR/DMCONST16  DefaultParameters_fe[] =
        #include "cvc_handsfree_2mic_defaults_FE.dat"
   ;
   .VAR/DMCONST16  DefaultParameters_nb[] =
        #include "cvc_handsfree_2mic_defaults_NB.dat"
   ;

   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.CVC_HANDSFREE_2MIC.PARAMETERS.STRUCT_SIZE)];

//  ******************  Define circular Buffers ************************

 .VAR/DM1     ref_delay_buffer[Max_RefDelay_Sample];
 .VAR/DM2     fft_circ[FFT_BUFFER_SIZE];
    #if uses_SND_NS
   .VAR/DM1 sndLpX_queue[$M.oms270.QUE_LENGTH];
    #endif
    #if uses_RCV_NS
   .VAR/DM1 rcvLpX_queue[$M.oms270.QUE_LENGTH];
    #endif


//  ******************  Define Scratch/Shared Memory ************************

    // Frequency Domain Shared working buffers
    .BLOCK/DM1   FFT_DM1;
      .VAR  fft_real[FFT_BUFFER_SIZE];              // SPTBD - check for scratch usage
      .VAR  D_r_real[$M.CVC.Num_FFT_Freq_Bins];
      .VAR  D_rcv_real[$M.CVC.ADC_DAC_Num_FFT_Freq_Bins];
      // D_l_real also be higher bins of D_rcv_real for BEX (FE)
      .VAR  D_l_real[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2 FFT_DM2;
      .VAR  fft_imag[FFT_BUFFER_SIZE];              // SPTBD - check for scratch usage
      .VAR  D_rcv_imag[$M.CVC.ADC_DAC_Num_FFT_Freq_Bins];
      // D_l_imag also be higher bins of D_rcv_imag for BEX (FE)
      .VAR  D_l_imag[$M.CVC.Num_FFT_Freq_Bins];
      .VAR  D_r_imag[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;


#ifndef BUILD_MULTI_KAPS
   .BLOCK/DM1 $scratch.s;
      .VAR    $scratch.s0;
      .VAR    $scratch.s1;
      .VAR    $scratch.s2;
      .VAR    $scratch.s3;
      .VAR    $scratch.s4;
      .VAR    $scratch.s5;
      .VAR    $scratch.s6;
      .VAR    $scratch.s7;
      .VAR    $scratch.s8;
      .VAR    $scratch.s9;
   .ENDBLOCK;

   .BLOCK/DM2 $scratch.t;
      .VAR    $scratch.t0;
      .VAR    $scratch.t1;
      .VAR    $scratch.t2;
      .VAR    $scratch.t3;
      .VAR    $scratch.t4;
      .VAR    $scratch.t5;
      .VAR    $scratch.t6;
      .VAR    $scratch.t7;
      .VAR    $scratch.t8;
      .VAR    $scratch.t9;
   .ENDBLOCK;
#endif




    .BLOCK/DM1  $M.dm1_scratch;
         // real,imag interlaced
         .VAR  W_ri[2 * $M.CVC.Num_FFT_Freq_Bins +1];
         .VAR  Attenuation[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  L_adaptA[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  L_adaptR[$M.CVC.Num_FFT_Freq_Bins];
    .ENDBLOCK;
// The Attenuation buffer needed to be pulled out of scratch memory,
// since the data needed by the CNG was being corrupted by other modules.
// The same happens with L_adaptA. fdnlp uses it but it is overwritten by the TMP
// because it was defined as scratch.
   .VAR  AttenuationPersist[$M.CVC.Num_FFT_Freq_Bins];
   .VAR  L_adaptAPersist[$M.CVC.Num_FFT_Freq_Bins];

// AEC
    .BLOCK/DM2  $M.dm2_scratch;
         // real,imag interlaced
         .VAR  Exp_Mts_adapt[2*$M.CVC.Num_FFT_Freq_Bins + 1];
         // L_RatSqGt - handsfree only
         .VAR  L_RatSqGt[$M.AEC_500.RER_dim];
         .VAR rerdt_dtc[$M.CVC.Num_FFT_Freq_Bins];
    .ENDBLOCK;


    // The oms_scratch buffer reuses the AEC buffer to reduce the data memory usage.
#define oms_scratch $M.dm1_scratch

   // reuse oms/aec scratch = 3 * number of frequency bins
#define adf_dm1_scratch $M.dm1_scratch
#define adf_dm2_scratch $M.dm2_scratch

#define fft_circ_scratch fft_circ

    // The aeq_scratch buffer reuses the AEC buffer to reduce the data memory usage.
#define aeq_scratch $M.dm1_scratch
#define vad_scratch $M.dm1_scratch
#define bf_dm1_scratch $M.dm1_scratch
#define bf_dm2_scratch $M.dm2_scratch

// ***************  Shared Send & Receive Side Processing **********************


   // FFT data object, common to all filter_bank cases
   // The three buffers in this object are temporary to FFT and could be shared
   .VAR fft_obj[$M.filter_bank.fft.STRUC_SIZE] =
      0,
      &fft_real,
      &fft_imag,
      &fft_circ_scratch,
      BITREVERSE(&fft_circ_scratch),
      $filter_bank.config.fftsplit_table, // PTR_FFTSPLIT
#if (uses_ADF || uses_AEQ)
         -1,                  // FFT_EXTRA_SCALE
         1,                   // IFFT_EXTRA_SCALE
#endif
      0 ...;

#if uses_DCBLOCK
   // DC Blocker
   .VAR dcblock_parameters_nb[] =
        1,          // NUM_STAGES_FIELD
        1,          // GAIN_EXPONENT_FIELD
        0.5,        // GAIN_MANTISA__FIELD
        // Coefficients.        Filter format: b2,b1,b0,a2,a1
        0.948607495176447/2, -1.897214990352894/2, 0.948607495176447/2,
        0.899857926182383/2, -1.894572054523406/2,
        // Scale Factor
        1;

   .VAR dcblock_parameters_wb[] =
        1,          // NUM_STAGES_FIELD
        1,          // GAIN_EXPONENT_FIELD
        0.5,        // GAIN_MANTISA__FIELD
        // Coefficients.        Filter format: b2,b1,b0,a2,a1
        0.973965227469013/2,-1.947930454938026/2,0.973965227469013/2,
        0.948608379214097/2,-1.947252530661955/2,
        // Scale Factor
        1;
#endif

#if uses_SND_AGC || uses_RCV_VAD
   // Internal Stream Buffer

   // Declare a dummy cbuffer structure, i.e., vad_peq_output_cbuffer_struc
   // It is intended for linear buffer could be used
   // by '$frmbuffer.get_buffer_with_start_address'
   // or by '$frmbuffer.get_buffer'
   // to return '0' length of a cbuffer
   .VAR vad_peq_output_cbuffer_struc[$cbuffer.STRUC_SIZE] = 0 ...;

    .VAR  vad_peq_output[$frmbuffer.STRUC_SIZE]  =
            &vad_peq_output_cbuffer_struc,
            &vad_scratch,
            0;

    .VAR    vad_peq_parameters_nb[] =
        3,          // NUM_STAGES_FIELD
        1,          // GAIN_EXPONENT_FIELD
        0.5,        // GAIN_MANTISA__FIELD
        // Coefficients.        Filter format: (b2,b1,b0,a2,a1)/2
      3658586,    -7303920,     3662890,     3363562,    -7470041,
      3874204,    -7787540,     4194304,     3702500,    -7573428,
      4101184,    -7581562,     4194304,     4082490,    -7559795,
       // Scale Factors
      1,1,1;

    .VAR    vad_peq_parameters_wb[] =
        3,          // NUM_STAGES_FIELD
        1,          // GAIN_EXPONENT_FIELD
        0.5,        // GAIN_MANTISA__FIELD
        // Coefficients.        Filter format: (b2,b1,b0,a2,a1)/2
      3597684,    -7593996,     4029366,     3454473,    -7592720,
      3621202,    -7734660,     4194304,     3639878,    -7733107,
      4126472,    -8041639,     4194304,     4107363,    -8020823,
       // Scale Factors
      1,1,1;

#endif   // uses_XXX_AGC

// ***************  Common Test Mode Control Structure **************************
   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT       0;
   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT      1;
   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_EXP             2;
   .CONST   $M.SET_MODE_GAIN.SCO_GAIN_MANT             3;
   .CONST   $M.SET_MODE_GAIN.SCO_GAIN_EXP              4;
   .CONST   $M.SET_MODE_GAIN.STRUC_SIZE                5;

   .VAR     ModeControl[$M.SET_MODE_GAIN.STRUC_SIZE];

   .VAR/DM2     adc_mixer[$M.audio_proc.stream_mixer.STRUC_SIZE] =
      &stream_map_left_adc,      // $M.audio_proc.stream_mixer.OFFSET_INPUT_CH1_PTR
      &stream_map_right_adc,     // $M.audio_proc.stream_mixer.OFFSET_INPUT_CH2_PTR
      0,                         // $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR   <set in passthrough & loopback>
      &ModeControl + $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT,   // $M.audio_proc.stream_mixer.OFFSET_PTR_CH1_MANTISSA
      &ModeControl + $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT,  // $M.audio_proc.stream_mixer.OFFSET_PTR_CH2_MANTISSA
      &ModeControl + $M.SET_MODE_GAIN.ADC_MIXER_EXP;         // $M.audio_proc.stream_mixer.OFFSET_PTR_EXPONENT


    .VAR/DM2     passthru_rcv_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_rcvin,                             // OFFSET_INPUT_PTR
      0,                                             // OFFSET_OUTPUT_PTR  <set in passthrough & loopback>
      &ModeControl + $M.SET_MODE_GAIN.SCO_GAIN_MANT, // OFFSET_PTR_MANTISSA
      &ModeControl + $M.SET_MODE_GAIN.SCO_GAIN_EXP;  // OFFSET_PTR_EXPONENT

// ************************  Receive Side Processing   **************************

// SP.  OMS requires 3 frames for harmonicity (window is only 2 frame)
#if uses_RCV_NS
.CONST $RCV_HARMANCITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
#else
.CONST $RCV_HARMANCITY_HISTORY_EXTENSION  0;
#endif

#if uses_RCV_FREQPROC

    // Analysis Filter Bank Config Block
   .VAR/DM1  bufd_rcv_inp[$M.CVC.Num_FFT_Window+ $RCV_HARMANCITY_HISTORY_EXTENSION];

   .VAR/DM1 RcvAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_RCVIN,           // OFFSET_CONFIG_OBJECT
      &stream_map_rcvin,                                        // CH1_PTR_FRAME
      &bufd_rcv_inp+$RCV_HARMANCITY_HISTORY_EXTENSION,          // OFFSET_CH1_PTR_HISTORY
      0,                               // CH1_BEXP
      &D_rcv_real,                     // CH1_PTR_FFTREAL
      &D_rcv_imag,                     // CH1_PTR_FFTIMAG
      0 ...;                           // No Channel Delay

   .VAR/DM1  bufdr_outp[$M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY];

    // Syntheseis Filter Bank Config Block
   .VAR/DM2 RcvSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_RCVOUT,          // OFFSET_CONFIG_OBJECT
      &stream_map_rcvout,              // OFFSET_PTR_FRAME
      &bufdr_outp,                     // OFFSET_PTR_HISTORY
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,
      &D_rcv_real,                     // OFFSET_PTR_FFTREAL
      &D_rcv_imag,                     // OFFSET_PTR_FFTIMAG
      0 ...;
#endif

#if uses_RCV_NS
   // <start> of memory declared per instance of oms270
   .VAR/DM1 rcvoms_G[$M.oms270.FFT_NUM_BIN];
   .VAR rcvoms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR rcvoms_state[$M.oms270.STATE_LENGTH];

   .VAR oms270rcv_obj[$M.oms270.STRUC_SIZE] =
      M_oms270_mode_object,   //$M.oms270.PTR_MODE_FIELD
      0,                      // $M.oms270.CONTROL_WORD_FIELD
      $M.CVC_HANDSFREE_2MIC.CONFIG.RCVOMSENA,
                              // $M.oms270.BYPASS_BIT_MASK_FIELD
      1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
      1,                      // $M.oms270.HARM_ON_FIELD
      1,                      // $M.oms270.MMSE_LSA_ON_FIELD
      $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
      &bufd_rcv_inp,          // $M.oms270.PTR_INP_X_FIELD
      &D_rcv_real,            // $M.oms270.PTR_X_REAL_FIELD
      &D_rcv_imag,            // $M.oms270.PTR_X_IMAG_FIELD
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,
                              // $M.oms270.PTR_BEXP_X_FIELD
      &D_rcv_real,            // $M.oms270.PTR_Y_REAL_FIELD
      &D_rcv_imag,            // $M.oms270.PTR_Y_IMAG_FIELD
      0xD00000,               // $M.oms270.INITIAL_POWER_FIELD
      &rcvLpX_queue,          // $M.oms270.LPX_QUEUE_START_FIELD
      &rcvoms_G,              // $M.oms270.G_FIELD;
      &rcvoms_LpXnz,          // $M.oms270.LPXNZ_FIELD,
      &rcvoms_state,          // $M.oms270.PTR_STATE_FIELD
      &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
      0.036805582279178,      // $M.oms270.ALFANZ_FIELD  SP.  CHanged due to frame size
      0xFF13DE,               // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
      0xFEEB01,               // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size
      0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
      $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
      0.9,                    // $M.oms270.AGRESSIVENESS_FIELD
#if uses_AEQ                  // $M.oms270.PTR_TONE_FLAG_FIELD
      &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TEST_FIELD,
#else
      0,
#endif
      0 ...;
#endif

   // wmsn: only executed when FE/BEX
    .VAR/DM1 dac_upsample_dm1[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
        &stream_map_rcvin,                             // INPUT_PTR_FIELD
        &stream_map_rcvout,                            // OUTPUT_PTR_FIELD
        &$M.iir_resamplev2.Up_2_Down_1.filter, // CONVERSION_OBJECT_PTR_FIELD
        -8,                                    // INPUT_SCALE_FIELD
        8,                                     // OUTPUT_SCALE_FIELD
        0,                                     // INTERMEDIATE_CBUF_PTR_FIELD
        0,                                     // INTERMEDIATE_CBUF_LEN_FIELD
        0 ...;


#if uses_DCBLOCK
   .VAR/DM2 sco_dcblock_dm2[PEQ_OBJECT_SIZE(1)] =
      &stream_map_rcvin,               // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_rcvin,               // PTR_OUTPUT_DATA_BUFF_FIELD
      1,                               // MAX_STAGES_FIELD
      CVC_DCBLOC_PEQ_PARAM_PTR,        // PARAM_PTR_FIELD
      0 ...;
#endif

#if uses_RCV_PEQ
   .VAR/DM2 rcv_peq_dm2[PEQ_OBJECT_SIZE(MAX_NUM_PEQ_STAGES)] =
      &stream_map_rcvout,              // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_rcvout,              // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,              // MAX_STAGES_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCV_PEQ_CONFIG,  // PARAM_PTR_FIELD
      0 ...;
#endif

   // Pre RCV AGC gain stage
   .VAR/DM1 rcvout_gain_dm2[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_rcvout,                       // OFFSET_INPUT_PTR
      &stream_map_rcvout,                       // OFFSET_OUTPUT_PTR
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCVGAIN_MANTISSA, // OFFSET_PTR_MANTISSA
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCVGAIN_EXPONENT; // OFFSET_PTR_EXPONENT

#if uses_RCV_VAD
   .VAR/DM rcv_vad_peq[PEQ_OBJECT_SIZE(3)] =
      &stream_map_rcvin,                        // PTR_INPUT_DATA_BUFF_FIELD
      &vad_peq_output,                          // INPUT_CIRCBUFF_SIZE_FIELD
      3,                                        // MAX_STAGES_FIELD
      CVC_VAD_PEQ_PARAM_PTR,                    // PARAM_PTR_FIELD
      0 ...;

   // RCV VAD
   .VAR/DM1 rcv_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,     // INPUT_PTR_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC, // Parameter Ptr
      0 ...;

#endif

#if uses_RCV_AGC
   // RCV AGC
   .VAR/DM rcv_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_RCVAGC,       //OFFSET_BYPASS_BIT_MASK_FIELD
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_AGCPERSIST,   // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCV_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
      &stream_map_rcvout,  //OFFSET_PTR_INPUT_FIELD
      &stream_map_rcvout,  //OFFSET_PTR_OUTPUT_FIELD
      &rcv_vad400 + $M.vad400.FLAG_FIELD,
                           //OFFSET_PTR_VAD_VALUE_FIELD
      0x7FFFFF,            //OFFSET_HARD_LIMIT_FIELD
#if uses_AEQ               //OFFSET_PTR_TONE_FLAG_FIELD
      &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TEST_FIELD,
#else
      0,
#endif
      0 ...;
#endif

#if uses_AEQ
   .VAR/DM aeq_band_pX[$M.AdapEq.Bands_Buffer_Length];
   .VAR/DM AEQ_DataObject[$M.AdapEq.STRUC_SIZE] =
      0,                                        // CONTROL_WORD_FIELD
      $M.CVC_HANDSFREE_2MIC.CONFIG.AEQENA,      // BYPASS_BIT_MASK_FIELD
      $M.CVC_HANDSFREE_2MIC.CONFIG.BEXENA,      // BEX_BIT_MASK_FIELD
      $M.CVC.Num_FFT_Freq_Bins,                 // NUM_FREQ_BINS
      0x000000,                                 // BEX_NOISE_LVL_DISABLE
      &D_rcv_real,                              // PTR_X_REAL_FIELD             2
      &D_rcv_imag,                              // PTR_X_IMAG_FIELD             3
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,   // PTR_BEXP_X_FIELD             4
      &D_rcv_real,                              // PTR_Z_REAL_FIELD             5
      &D_rcv_imag,                              // PTR_Z_IMAG_FIELD             6
      6-1,                                      // LOW_INDEX_FIELD              7
      8,                                        // LOW_BW_FIELD                 8
      8388608/8,                                // LOW_INV_INDEX_DIF_FIELD      9
      19,                                       // MID_BW_FIELD                 10
      (8388608/19),                             // MID_INV_INDEX_DIF_FIELD      11
      24,                                       // HIGH_BW_FIELD                12
      (8388608/24),                             // HIGH_INV_INDEX_DIF_FIELD     13
      0,                                        // AEQ_EQ_COUNTER_FIELD         14
      267,                                      // AEQ_EQ_INIT_FRAME_FIELD      15
      0,                                        // AEQ_GAIN_LOW_FIELD           16
      0,                                        // AEQ_GAIN_HIGH_FIELD          17
      &rcv_vad400 + $M.vad400.FLAG_FIELD,       // VAD_AGC_FIELD                18
      0.001873243285618,                        // ALFA_A_FIELD                 19
      1.0-0.001873243285618,                    // ONE_MINUS_ALFA_A_FIELD       20
      0.001873243285618,                        // ALFA_D_FIELD                 21
      1.0-0.001873243285618,                    // ONE_MINUS_ALFA_D_FIELD       22
      0.036805582279178,                        // ALFA_ENV_FIELD               23
      1.0-0.036805582279178,                    // ONE_MINUS_ALFA_ENV_FIELD     24
      &aeq_band_pX,                             // PTR_AEQ_BAND_PX_FIELD        25
      0,                                        // STATE_FIELD                  26
#if uses_NSVOLUME
      &ndvc_obj + $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL,    // PTR_VOL_STEP_UP_FIELD        27
#else
      &$M.CVC.data.ZeroValue,
#endif
      1,                                        // VOL_STEP_UP_TH1_FIELD        28
      2,                                        // VOL_STEP_UP_TH2_FIELD        29
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LO_GOAL_LOW,    // PTR_GOAL_LOW_FIELD           30
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_HI_GOAL_LOW,    // PTR_GOAL_HIGH_FIELD          31
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BEX_TOTAL_ATT_LOW,  // PTR_BEX_ATT_TOTAL_FIELD      32 wmsn: not used in WB
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BEX_HI2_GOAL_LOW,   // PTR_BEX_GOAL_HIGH2_FIELD     33 wmsn: not used in WB
      0,                                        // BEX_PASS_LOW_FIELD           34 wmsn: not used in WB
      21771,                                    // BEX_PASS_HIGH_FIELD          35 wmsn: not used in WB
      14,                                       // MID1_INDEX_FIELD             36
      33,                                       // MID2_INDEX_FIELD             37
      57,                                       // HIGH_INDEX_FIELD             38
      98642,                                    // INV_AEQ_PASS_LOW_FIELD       39
      197283,                                   // INV_AEQ_PASS_HIGH_FIELD      40
      43541,                                    // AEQ_PASS_LOW_FIELD Q8.16     41
      21771,                                    // AEQ_PASS_HIGH_FIELD Q8.16    42
      544265,                                   // AEQ_POWER_TH_FIELD Q8.16     43
      0,                                        // AEQ_TONE_POWER_FIELD Q8.16   44
      -326559,                                  // AEQ_MIN_GAIN_TH_FIELD Q8.16  45
      326559,                                   // AEQ_MAX_GAIN_TH_FIELD Q8.16  46
      0,                                        // AEQ_POWER_TEST_FIELD         47
      &aeq_scratch;                             // PTR_SCRATCH_G_FIELD
#endif

   .VAR sco_in_pk_dtct[] =
      &stream_map_rcvin,               // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL

// ************************  Send Side Processing   **************************

#if !defined(AEC_HANNING_WINDOW)
   .CONST $SND_HARMONICITY_HISTORY_OFFSET     $M.CVC.Num_Samples_Per_Frame;
   .CONST $SND_HARMONICITY_HISTORY_EXTENSION  0;

#else // AEC_HANNING_WINDOW

   .CONST $SND_HARMONICITY_HISTORY_OFFSET     0;
   // SP.  OMS requires 3 frames for harmonicity (window is only 2 frames)
   #if uses_SND_NS
      .CONST $SND_HARMONICITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
   #else
      .CONST $SND_HARMONICITY_HISTORY_EXTENSION  0;
   #endif

#endif // AEC_HANNING_WINDOW

 .VAR/DM2  bufd_l_inp[$M.CVC.AEC.Num_FFT_Window + $SND_HARMONICITY_HISTORY_EXTENSION];
 .VAR/DM2  bufd_r_inp[$M.CVC.AEC.Num_FFT_Window + $SND_HARMONICITY_HISTORY_EXTENSION];


#ifdef uses_SSR
// for feature extraction
   .VAR/DM fbankCoeffs[$M.SSR.NUM_FILTERS];
   .VAR/DM mfcCoeffs[$M.SSR.MFCC_ORDER+1];               // 1 extra for c0

// Viterbi decoder storage
   .VAR/DM obs[$M.SSR.OBS_SIZE];
   .VAR/DM obs_regress[$M.SSR.NPARAMS*$M.SSR.REGRESS_COLS];     // NPARAMS x (2*DELTAWIN+1) : TODO if no deltas, should not allocate regress
   .VAR/DM partial_like[$M.SSR.NMODELS*$M.SSR.NSTATES];         // NMODELS x NSTATES        : current frame (prev for the purpose of computing the patial scores)
   .VAR/DM partial_like_next[$M.SSR.NMODELS*$M.SSR.NSTATES];    // NMODELS x NSTATES        : next frame (current for the purpose of computing outputProb)
   .VAR/DM nr_best_frames[$M.SSR.NMODELS-1];

   // Private instance structure for ASR Viterbi decoder
   .VAR asr_decoder[$M.SSR.DECODER_STRUCT.BLOCK_SIZE ] =
         0,                         // HMM_SET_OFFSET
         0,                         // FINISH_OFFSET
         0,                         // RESET_OFFSET
         0,                         // BEST_WORD_OFFSET
         0,                         // BEST_SCORE_OFFSET
         0,                         // BEST_STATE_OFFSET
         &obs,                      // OBS_OFFSET
         &obs_regress,              // OBS_REGRESS_OFFSET
         0,                         // LOG_ENERGY_OFFSET
         0,                         // CONFIDENCE_SCORE_OFFSET
         &nr_best_frames,           // NR_BEST_FRAMES_OFFSET
         0,                         // SUCC_STA_CNT_OFFSET
         0,                         // NR_MAIN_STATE_OFFSET
         0,                         // FINISH_CNT_OFFSET
         0,                         // RELIABILITY_OFFSET
         0,                         // DECODER_STARTED_OFFSET
         0,                         // FRAME_COUNTER_OFFSET
         0,                         // VOICE_GONE_CNT_OFFSET
         0,                         // AFTER_RESET_CNT_OFFSET
         0,                         // SCORE_OFFSET
         0,                         // SUM_RELI_OFFSET
         0,                         // NOISE_ESTIMATE_OFFSET
         0,                         // NOISE_FRAME_COUNTER_OFFSET
         0,                         // INITIALIZED_OFFSET
         &fbankCoeffs,              // FBANK_COEFFS_OFFSET
         &mfcCoeffs,                // MFC_COEFFS_OFFSET
         &partial_like,             // PARTIAL_LIKE_OFFSET
         &partial_like_next;        // PARTIAL_LIKE_NEXT_OFFSET

   // Private pre-processing instance - input cbuffer, multi-bank FFT buffers, OMS exported variables
   // ASR public structure
   .VAR asr_obj[$M.SSR.SSR_STRUC.BLOCK_SIZE] =
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         &asr_decoder,
         &D_l_real,                                               // FFT_REAL_OFFSET
         &D_l_imag,                                               // FFT_IMAG_OFFSET
         &AnalysisBank_ASR + $M.filter_bank.Parameters.OFFSET_PTR_BEXP,   // SCALE_FACTOR_OFFSET
         &oms270ssr_obj + $M.oms270.VOICED_FIELD,                 // VOICED_OFFSET
         &out0_oms_G,                                             // GAIN_OFFSET
         &oms270ssr_obj + $M.oms270.LIKE_MEAN_FIELD,              // LIKE_MEAN_OFFSET
         &out0_oms_LpXnz;                                         // LPX_NZ_OFFSET


   .VAR oms270ssr_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,  //$M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HANDSFREE_2MIC.CONFIG.SNDOMSENA,
                                // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                      // $M.oms270.HARM_ON_FIELD
        1,                      // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.AEC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_l_inp + $SND_HARMONICITY_HISTORY_OFFSET,              // $M.oms270.PTR_INP_X_FIELD
        &D_l_real,                // $M.oms270.PTR_X_REAL_FIELD
        &D_l_imag,                // $M.oms270.PTR_X_IMAG_FIELD
        &AnalysisBank_ASR + $M.filter_bank.Parameters.OFFSET_PTR_BEXP,
                                // $M.oms270.PTR_BEXP_X_FIELD
        &D_l_real,                // $M.oms270.PTR_Y_REAL_FIELD
        &D_l_imag,                // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,                 // $M.oms270.INITIAL_POWER_FIELD
        &sndLpX_queue,          // $M.oms270.LPX_QUEUE_START_FIELD
        &out0_oms_G,             // $M.oms270.G_FIELD;
        &out0_oms_LpXnz,         // $M.oms270.LPXNZ_FIELD,
        &out0_oms_state,         // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,       // $M.oms270.ALFANZ_FIELD      SP.  Changed due to frame size
        0xFF13DE,               // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,               // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size
        0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        1.0,                    // $M.oms270.AGRESSIVENESS_FIELD
        0,                      // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;
        
   .VAR/DM1 ssr_muted=$M.CVC_HANDSFREE_2MIC.CALLST.MUTE;

   .VAR/DM1 mute_ssr_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,               // OFFSET_INPUT_PTR
      &ssr_muted,                       // OFFSET_PTR_STATE
      $M.CVC_HANDSFREE_2MIC.CALLST.MUTE;       // OFFSET_MUTE_VAL
#endif //uses_SSR




   // Analysis Filter Bank Config Block
   .VAR/DM1 MicAnalysisBank[$M.filter_bank.Parameters.TWO_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,                             // OFFSET_CONFIG_OBJECT
      &stream_map_left_adc,                            // CH1_PTR_FRAME
      &stream_map_right_adc,                           // CH2_PTR_FRAME
      &bufd_l_inp + $SND_HARMONICITY_HISTORY_EXTENSION,   // OFFSET_CH1_PTR_HISTORY
      &bufd_r_inp + $SND_HARMONICITY_HISTORY_EXTENSION,   // OFFSET_CH2_PTR_HISTORY
      0,                               // CH1_BEXP
      0,                               // CH2_BEXP
      &D_l_real,                                // CH1_PTR_FFTREAL
      &D_l_imag,                                // CH1_PTR_FFTIMAG
      &D_r_real,                                // CH2_PTR_FFTREAL
      &D_r_imag,                                // CH2_PTR_FFTIMAG
      0 ...;

#ifdef uses_SSR
  .VAR/DM1 AnalysisBank_ASR[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_left_adc,            // CH1_PTR_FRAME
      &bufd_l_inp + $SND_HARMONICITY_HISTORY_EXTENSION,  // OFFSET_CH1_PTR_HISTORY
      0,                               // CH1_BEXP
      &D_l_real,                       // CH1_PTR_FFTREAL
      &D_l_imag,                       // CH1_PTR_FFTIMAG
      0 ...;
#endif

   // SP.  Analysis for AEC Reference
   .VAR/DM2  bufd_aec_inp[$M.CVC.AEC.Num_FFT_Window];

   .VAR/DM1 AecAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_refin,               // CH1_PTR_FRAME
      &bufd_aec_inp,                   // OFFSET_CH1_PTR_HISTORY
      0,                               // CH1_BEXP
      &D_rcv_real,                     // CH1_PTR_FFTREAL
      &D_rcv_imag,                     // CH1_PTR_FFTIMAG
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_REF_DELAY,  //OFFSET_DELAY_PTR
      &ref_delay_buffer,               // OFFSET_CH2_DELAY_BASE
      &ref_delay_buffer,               // OFFSET_CH2_DELAY_BUF_PTR
      LENGTH(ref_delay_buffer);        // OFFSET_CH2_DELAY_BUF_LEN

   // Syntheseis Filter Bank Config Block
   .VAR  bufd_outp[($M.CVC.AEC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame)];

   .VAR/DM2 SndSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,                      // OFFSET_CONFIG_OBJECT
      &stream_map_sndout,                       // OFFSET_PTR_FRAME
      &bufd_outp,                               // OFFSET_PTR_HISTORY
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP, // OFFSET_PTR_BEXP
      &D_r_real,                                // OFFSET_PTR_FFTREAL
      &D_r_imag,                                // OFFSET_PTR_FFTIMAG
      0 ...;

#if uses_SND_NS
   // <start> of memory declared per instance of oms270
   .VAR in_oms_G[$M.oms270.FFT_NUM_BIN];
   .VAR/DM1 in_oms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR in_oms_state[$M.oms270.STATE_LENGTH];
   .VAR/DM1 insndLpX_queue[$M.oms270.QUE_LENGTH];

   .VAR in_oms270snd_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,    //$M.oms270.PTR_MODE_FIELD
        0,                       // $M.oms270.CONTROL_WORD_FIELD
        0,                       // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                       // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                       // $M.oms270.HARM_ON_FIELD
        1,                       // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.AEC.Num_FFT_Window,   // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_l_inp + $SND_HARMONICITY_HISTORY_OFFSET,             // $M.oms270.PTR_INP_X_FIELD
        &D_l_real,               // $M.oms270.PTR_X_REAL_FIELD
        &D_l_imag,               // $M.oms270.PTR_X_IMAG_FIELD
        &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
                                 // $M.oms270.PTR_BEXP_X_FIELD
        &D_l_real,               // $M.oms270.PTR_Y_REAL_FIELD
        &D_l_imag,               // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,                // $M.oms270.INITIAL_POWER_FIELD
        &insndLpX_queue,           // $M.oms270.LPX_QUEUE_START_FIELD
        &in_oms_G,               // $M.oms270.G_FIELD;
        &in_oms_LpXnz,           // $M.oms270.LPXNZ_FIELD,
        &in_oms_state,           // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,            // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,       // $M.oms270.ALFANZ_FIELD      SP.  Changed due to frame size
        0xFF13DE,                // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,                // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size
        0.45,                    // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        0.95,                    // $M.oms270.AGRESSIVENESS_FIELD
        0,                       // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;

   // <start> of memory declared per instance of oms270
   .VAR out0_oms_G[$M.oms270.FFT_NUM_BIN];
   .VAR/DM1 out0_oms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR out0_oms_state[$M.oms270.STATE_LENGTH];
   .VAR/DM1 out0sndLpX_queue[$M.oms270.QUE_LENGTH];

   .VAR out0_oms270snd_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,    //$M.oms270.PTR_MODE_FIELD
        0,                       // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HANDSFREE_2MIC.CONFIG.SNDOMSENA,
                                 // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                       // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                       // $M.oms270.HARM_ON_FIELD
        1,                       // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.AEC.Num_FFT_Window,   // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_l_inp + $SND_HARMONICITY_HISTORY_OFFSET,             // $M.oms270.PTR_INP_X_FIELD
        &D_l_real,               // $M.oms270.PTR_X_REAL_FIELD
        &D_l_imag,               // $M.oms270.PTR_X_IMAG_FIELD
        &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
                                 // $M.oms270.PTR_BEXP_X_FIELD
        &D_l_real,               // $M.oms270.PTR_Y_REAL_FIELD
        &D_l_imag,               // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,                // $M.oms270.INITIAL_POWER_FIELD
        &out0sndLpX_queue,       // $M.oms270.LPX_QUEUE_START_FIELD
        &out0_oms_G,             // $M.oms270.G_FIELD;
        &out0_oms_LpXnz,         // $M.oms270.LPXNZ_FIELD,
        &out0_oms_state,         // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,            // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,       // $M.oms270.ALFANZ_FIELD      SP.  Changed due to frame size
        0xFF13DE,                // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,                // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size
        0.45,                    // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        0.95,                    // $M.oms270.AGRESSIVENESS_FIELD
        0,                       // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;

   // <start> of memory declared per instance of oms270
   .VAR out1_oms_G[$M.oms270.FFT_NUM_BIN];
   .VAR/DM1 out1_oms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR out1_oms_state[$M.oms270.STATE_LENGTH];
   .VAR/DM1 out1sndLpX_queue[$M.oms270.QUE_LENGTH];

   .VAR out1_oms270snd_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,    //$M.oms270.PTR_MODE_FIELD
        0,                       // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HANDSFREE_2MIC.CONFIG.SNDOMSENA,
                                 // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                       // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                       // $M.oms270.HARM_ON_FIELD
        1,                       // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.AEC.Num_FFT_Window,   // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_r_inp + $SND_HARMONICITY_HISTORY_OFFSET,             // $M.oms270.PTR_INP_X_FIELD
        &D_r_real,               // $M.oms270.PTR_X_REAL_FIELD
        &D_r_imag,               // $M.oms270.PTR_X_IMAG_FIELD
        &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_BEXP,
                                 // $M.oms270.PTR_BEXP_X_FIELD
        &D_r_real,               // $M.oms270.PTR_Y_REAL_FIELD
        &D_r_imag,               // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,                // $M.oms270.INITIAL_POWER_FIELD
        &out1sndLpX_queue,       // $M.oms270.LPX_QUEUE_START_FIELD
        &out1_oms_G,                // $M.oms270.G_FIELD;
        &out1_oms_LpXnz,            // $M.oms270.LPXNZ_FIELD,
        &out1_oms_state,            // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,               // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,          // $M.oms270.ALFANZ_FIELD      SP.  Changed due to frame size
        0xFF13DE,                   // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,                   // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size
        0.45,                       // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        0.95,                       // $M.oms270.AGRESSIVENESS_FIELD
        0,                          // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;
#endif // uses_RCV_NS

#if uses_AEC

    .BLOCK/DM1;
        // Internal Zero Initialize
        // taps x bin
        .VAR  RcvBuf_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500_HF.Num_Primary_Taps];
        // taps x bin
        .VAR  Ga_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500_HF.Num_Primary_Taps];
        .VAR  Gb_imag[$M.AEC_500.RER_dim * $M.AEC_500_HF.Num_Auxillary_Taps];
        .VAR  L2PxR[4];
        // Internal Non-Zero Initialize
        .VAR  Gr_imag[$M.AEC_500.RER_dim];
        // Bin Reversed Ordering
        .VAR  SqGr[$M.AEC_500.RER_dim];
        .VAR  BExp_Ga[$M.CVC.Num_FFT_Freq_Bins];
        .VAR  BExp_Gb[$M.AEC_500.RER_dim];
        .VAR  LPwrX0[$M.CVC.Num_FFT_Freq_Bins];
        .VAR  RatFE[$M.AEC_500.RER_dim];
        .VAR  Cng_Nz_Shape_Tab[$M.CVC.Num_FFT_Freq_Bins];
    .ENDBLOCK;

    .BLOCK/DM2;
        // Internal Zero Initialize
        // taps x bin
        .VAR  RcvBuf_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500_HF.Num_Primary_Taps];
        // taps x bin
        .VAR  Ga_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500_HF.Num_Primary_Taps];
        .VAR  Gb_real[$M.AEC_500.RER_dim * $M.AEC_500_HF.Num_Auxillary_Taps];
        .VAR  L2absGr[$M.AEC_500.RER_dim];
        // Internal Non-Zero Initialize
        .VAR  Gr_real[$M.AEC_500.RER_dim];
        .VAR  LPwrD[$M.AEC_500.RER_dim];
        .VAR  BExp_X_buf[$M.AEC_500_HF.Num_Primary_Taps+1];
        .VAR  LpZ_nz[$M.CVC.Num_FFT_Freq_Bins];
        .VAR  LPwrX1[$M.CVC.Num_FFT_Freq_Bins];
    .ENDBLOCK;

    .BLOCK/DM1;
        // Internal Zero Initialize
        // taps x bin
        .VAR  GaMic1_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500_HF.Num_Primary_Taps];
        // Internal Non-Zero Initialize
        // Bin Reversed Ordering
        .VAR  BExp_GaMic1[$M.CVC.Num_FFT_Freq_Bins];
    .ENDBLOCK;

    .BLOCK/DM2;
        // Internal Zero Initialize
        // taps x bin
        .VAR  GaMic1_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500_HF.Num_Primary_Taps];
    .ENDBLOCK;

   .VAR/DM1 aec_dm1[$M.AEC_500.STRUCT_SIZE] =
      &fft_real,                          // OFFSET_E_REAL_PTR
      &fft_imag,                          // OFFSET_E_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_BEXP, // OFFSET_D_EXP_PTR
      &D_l_real,                          // OFFSET_D_REAL_PTR (initialized internally)
      &D_l_imag,                          // OFFSET_D_IMAG_PTR (initialized internally)
      &Exp_Mts_adapt,                     // OFFSET_SCRPTR_Exp_Mts_adapt
      $AEC_500.rer_handsfree,             // OFFSET_RER_EXT_FUNC_PTR
      0,                                  // OFFSET_RER_D_REAL_PTR, (set internally)
      0,                                  // OFFSET_RER_D_IMAG_PTR, (set internally)
      &Gr_imag,                           // OFFSET_PTR_Gr_imag
      &Gr_real,                           // OFFSET_PTR_Gr_real
      &SqGr,                              // OFFSET_PTR_SqGr
      &L2absGr,                           // OFFSET_PTR_L2absGr
      &LPwrD,                             // OFFSET_PTR_LPwrD
      &W_ri,                              // OFFSET_SCRPTR_W_ri
      &L_adaptR,                          // OFFSET_SCRPTR_L_adaptR
      0x040000,                           // OFFSET_RER_SQGRDEV (handsfree/adfrnr)
      &D_rcv_real,                        // OFFSET_X_REAL_PTR
      &D_rcv_imag,                        // OFFSET_X_IMAG_PTR
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_BEXP, // OFFSET_X_EXP_PTR
      &in_oms_G,                          // OFFSET_OMS1_G_PTR
      &in_oms_LpXnz,                      // OFFSET_OMS1_D_NZ_PTR
      &in_oms_G,                          // OFFSET_oms_adapt_G_PTR
      &out0_oms_G,                        // OFFSET_OMS2_G_PTR
      1.0,                                // OFFSET_OMS_AGGRESSIVENESS
      0x200000,                           // OFFSET_CNG_Q_ADJUST
      0x6Ed9eb,                           // OFFSET_CNG_G_ADJUST(unused) 17
      0.5,                                // OFFSET_DTC_AGRESSIVENESS
      0.5,                                // OFFSET_RER_WGT_L2PXR
      0.5,                                // OFFSET_RER_WGT_L2PDR
      1,                                  // OFFSET_ENABLE_AEC_REUSE
      0,                                  // OFFSET_CONFIG
      0x028000,                           // OFFSET_MAX_LPWR_MARGIN
      $M.AEC_500_HF.Num_Auxillary_Taps,   // OFFSET_NUM_AUXILLARY_TAPS
      $M.AEC_500_HF.Num_Primary_Taps,     // OFFSET_NUM_PRIMARY_TAPS
      $M.CVC.Num_FFT_Freq_Bins,           // OFFSET_NUM_FREQ_BINS
      CVC_AEC_LPWRX_MARGIN_OVFL,       // OFFSET_LPWRX_MARGIN_OVFL
      CVC_AEC_LPWRX_MARGIN_SCL,        // OFFSET_LPWRX_MARGIN_SCL
      0,                 		// OFFSET_RERCBA_ENABLE_MASK    
      0x200000,                           // OFFSET_RER_AGGRESSIVENESS     (handsfree)
      0x200000,                           // OFFSET_RER_WGT_SY             (handsfree)
      0,                                  // OFFSET_RER_OFFSET_SY          (handsfree)
      2,                                  // OFFSET_RER_POWER              (handsfree)
      0xF80000,                           // OFFSET_AEC_REF_LPWR_UB        (handsfree)
      &rerdt_dtc,                         // OFFSET_SCRPTR_RERDT_DTC       (handsfree)
      $M.AEC_500.L2TH_RERDT_OFF,          // OFFSET_L2TH_RERDT_OFF         (handsfree)
      $M.AEC_500.RERDT_ADJUST,            // OFFSET_RERDT_ADJUST           (handsfree)
      $M.AEC_500.RERDT_POWER,             // OFFSET_RERDT_POWER            (handsfree)
      $M.AEC_500_HF.L_MUA_ON,             //  OFFSET_AEC_L_MUA_ON
      $M.AEC_500_HF.L_ALFA_A,             //  OFFSET_AEC_L_ALFA_A
      // Mode Specific Functions for Commom source
      $M.AEC_500.dbl_talk_control_handsfree.normal_op,      // OFFSET_DT_FUNC1_PTR
      $M.AEC_500.dbl_talk_control_handsfree.normal_op_else, // OFFSET_DT_FUNC2_PTR
      $AEC_500.handsfree_dtc_aggressiveness,                // OFFSET_DTC_AGRESS_FUNC_PTR
      $AEC_500.LPwrX_update_handsfree,                      // OFFSET_LPWRX_UPDT_FUNC_PTR
      $M.AEC_500.divergence_control.func,                   // OFFSET_RER_DIVERGE_FUNC_PTR
      // Constant Arrays
      &$AEC_500_HF.Const,                 // OFFSET_CONST_DM1
      &RcvBuf_real,                       // OFFSET_PTR_RcvBuf_real
      &RcvBuf_imag,                       // OFFSET_PTR_RcvBuf_imag
      &Ga_imag,                           // OFFSET_PTR_Ga_imag
      &Ga_real,                           // OFFSET_PTR_Ga_real
      &Gb_imag,                           // OFFSET_PTR_Gb_imag
      &Gb_real,                           // OFFSET_PTR_Gb_real
      &L2PxR,                             // OFFSET_PTR_L2PxR
      &BExp_Ga,                           // OFFSET_PTR_BExp_Ga
      &BExp_Gb,                           // OFFSET_PTR_BExp_Gb
      &LPwrX0,                            // OFFSET_PTR_LPwrX0
      &RatFE,                             // OFFSET_PTR_RatFE
      &BExp_X_buf,                        // OFFSET_PTR_BExp_X_buf
      &LpZ_nz,                            // OFFSET_PTR_LpZ_nz
      &LPwrX1,                            // OFFSET_PTR_LPwrX1

      &AttenuationPersist,                // OFFSET_SCRPTR_Attenuation
      &L_adaptAPersist,                   // OFFSET_SCRPTR_L_adaptA
      &L_RatSqGt,                         // OFFSET_SCRPTR_L_RatSqGt
      -268,                               // $M.AEC_500.OFFSET_L_DTC 2.0*fs/L
      3,                                  // OFFSET_CNG_NOISE_COLOR (-1=wht,0=brn,1=pnk,2=blu,3=pur)
      CVC_AEC_PTR_NZ_TABLES,              // OFFSET_PTR_NZ_TABLES
      &Cng_Nz_Shape_Tab,                  // OFFSET_PTR_CUR_NZ_TABLE
      0 ...;

   .VAR/DM1 aec2Mic_dm1[$M.TWOMIC_AEC.STRUCT_SIZE] =
      &fft_real,                          // OFFSET_E_REAL_PTR
      &fft_imag,                          // OFFSET_E_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_PTR_BEXP, // OFFSET_D_EXP_PTR
      0,                                  // OFFSET_D_REAL_PTR (initialized internally)
      0,                                  // OFFSET_D_IMAG_PTR (initialized internally)
      &Exp_Mts_adapt,                     // OFFSET_SCRPTR_Exp_Mts_adapt
      &aec_dm1,                           // OFFSET_PTR_MAIN_AEC
      0,                                  // OFFSET_PTR_BYPASS_AEC1
      &GaMic1_real,
      &GaMic1_imag,
      &BExp_GaMic1,
      &RcvBuf_real,
      &RcvBuf_imag
      ;

   .VAR/DM1 vsm_fdnlp_dm1[$M.AEC_500_HF.STRUCT_SIZE] =
      &D_r_real,                       // OFFSET_D_REAL_PTR
      &D_r_imag,                       // OFFSET_D_IMAG_PTR
      $M.CVC.Num_FFT_Freq_Bins,        // OFFSET_NUM_FREQ_BINS
      0,                               // OFFSET_HD_THRESH_GAIN
      &$M.CVC_SYS.CurCallState,        // OFFSET_CALLSTATE_PTR
      0,                               // OFFSET_TIER2_THRESH
      0,                               // OFFSET_HC_TIER_STATE
#if uses_HOWLING_CONTROL
      &rcv_vad400 + $M.vad400.FLAG_FIELD,   // OFFSET_PTR_RCV_DETECT, only used for HD/HC
#else
     &ZeroValue,
#endif
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_VSM_HB_TIER1, // OFFSET_PTR_TIER1_CONFIG
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_VSM_HB_TIER2, // OFFSET_PTR_TIER2_CONFIG
#if uses_HOWLING_CONTROL
      $AEC_500.ApplyHalfDuplex,        // HOWLING_CNTRL_FUNCPTR
#else
      0,
#endif
#if uses_NONLINEAR_PROCESSING
     $AEC_500.FdnlpProcess,            // FDNLP_FUNCPTR
     $AEC_500.VsmProcess,              // VSM_FUNCPTR
#else
      0,
      0,
#endif
      &RatFE,                          // OFFSET_PTR_RatFE
      &SqGr,                           // OFFSET_PTR_SqGr
      &AttenuationPersist,             // OFFSET_SCRPTR_Attenuation
      &L_adaptAPersist,                // OFFSET_SCRPTR_absGr         (shares L_adaptA)
      &L_adaptR ,                      // OFFSET_SCRPTR_temp
      0 ...;
#endif

    // wmsn: only executed when FE/BEX
    .VAR/DM1 adc_downsample_dm1[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
        &stream_map_sndin,                   // INPUT_PTR_FIELD
        &stream_map_sndin,                   // OUTPUT_PTR_FIELD
        &$M.iir_resamplev2.Up_1_Down_2.filter,     // CONVERSION_OBJECT_PTR_FIELD
        -8,                                 // INPUT_SCALE_FIELD
        8,                                  // OUTPUT_SCALE_FIELD
        0,                                  // INTERMEDIATE_CBUF_PTR_FIELD
        0,                                  // INTERMEDIATE_CBUF_LEN_FIELD
        0 ...;


    .VAR/DM1 ref_downsample_dm1[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
        &stream_map_refin,                   // INPUT_PTR_FIELD
        &stream_map_refin,                   // OUTPUT_PTR_FIELD
        &$M.iir_resamplev2.Up_1_Down_2.filter,     // CONVERSION_OBJECT_PTR_FIELD
        -8,                                 // INPUT_SCALE_FIELD
        8,                                  // OUTPUT_SCALE_FIELD
        0,                                  // INTERMEDIATE_CBUF_PTR_FIELD
        0,                                  // INTERMEDIATE_CBUF_LEN_FIELD
        0 ...;


#if uses_DCBLOCK
   .VAR/DM2 in_l_dcblock_dm2[PEQ_OBJECT_SIZE(1)] =
      &stream_map_left_adc,            // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_left_adc,            // PTR_OUTPUT_DATA_BUFF_FIELD
      1,                               // MAX_STAGES_FIELD
      CVC_DCBLOC_PEQ_PARAM_PTR,        // PARAM_PTR_FIELD
      0 ...;
#endif

   .VAR/DM2 in_r_dcblock_dm2[PEQ_OBJECT_SIZE(1)] =
      &stream_map_right_adc,           // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_right_adc,           // PTR_OUTPUT_DATA_BUFF_FIELD
      1,                               // MAX_STAGES_FIELD
      CVC_DCBLOC_PEQ_PARAM_PTR,        // PARAM_PTR_FIELD
      0 ...;



   .VAR/DM1 mute_cntrl_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,                       // OFFSET_INPUT_PTR
      &$M.CVC_SYS.CurCallState,                 // OFFSET_PTR_STATE
      $M.CVC_HANDSFREE_2MIC.CALLST.MUTE;        // OFFSET_MUTE_VAL



#if uses_SND_PEQ
   // Parameteric EQ
   .VAR/DM2 snd_peq_dm2[PEQ_OBJECT_SIZE(MAX_NUM_PEQ_STAGES)] =
      &stream_map_sndout,              // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndout,              // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,              // MAX_STAGES_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG,  // PARAM_PTR_FIELD
      0 ...;
#endif

   // SND AGC Pre-Gain stage
   .VAR/DM1 out_gain_dm1[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndout,                               // OFFSET_INPUT_PTR
      &stream_map_sndout,                               // OFFSET_OUTPUT_PTR
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA, // OFFSET_PTR_MANTISSA
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT; // OFFSET_PTR_EXPONENT


#if uses_SND_AGC
   #if uses_ADF && uses_SND_NS && uses_SND_AGC
   .VAR snd_agc_vad_recalc[$M.CVC.oms_vad_recalc.STRUC_SIZE] =
      &aed_object + $M.AED.OFFSET_VAD,
                           // PTR_VAD_VALUE_FIELD
   #if uses_RCV_VAD
      &rcv_vad400 + $M.vad400.FLAG_FIELD,
   #else
      &ZeroValue,
   #endif                     // PTR_RCV_VAD_FIELD
      0,                   // HOLD_COUNTER_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME,    // PTR_HOLD_TIME_FRAMES_FIELD
      &in_oms_G,           
                           // PTR_G_OMS_FIELD
      0.3,                 // MEAN_OMS_THRESH_FIELD
      &ZeroValue;

   #endif

   .VAR vad_noise_hold[$M.CVC.oms_vad_recalc.STRUC_SIZE] =
      &aed_object + $M.AED.OFFSET_VAD,      // PTR_VAD_VALUE_FIELD
      &$snd_agc_vad_reverse,                // PTR_EVENT_VAD_FIELD
      0,                                    // HOLD_COUNTER_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SND_AGC_NOISE_HOLD_TIME,    // PTR_HOLD_TIME_FRAMES_FIELD
      0,
      0,
      0;
   

   .VAR/DM1CIRC snd_vad_peq_coeffs[15];
   .VAR/DMCIRC snd_vad_delaybuf[8];           // SIZE = (NUM_STAGES_FIELD+1)*2
   .VAR snd_vad_peq_output_cbuffer_struc[$cbuffer.STRUC_SIZE] = 0 ...;
   .VAR snd_vad_peq_output[$frmbuffer.STRUC_SIZE]  =
            &snd_vad_peq_output_cbuffer_struc,
            &vad_scratch,
            0;

   .VAR/DM snd_vad_peq[PEQ_OBJECT_SIZE(3)] =
      &stream_map_sndout,                       // PTR_INPUT_DATA_BUFF_FIELD
      &snd_vad_peq_output,                          // INPUT_CIRCBUFF_SIZE_FIELD
      3,                                        // MAX_STAGES_FIELD
      CVC_VAD_PEQ_PARAM_PTR,                    // PARAM_PTR_FIELD
      0 ...;

   // SND VAD
   .VAR/DM1 snd_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &snd_vad_peq_output,     // INPUT_PTR_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC, // Parameter Ptr
      0 ...;

   // SND AGC
   .VAR/DM snd_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_SNDAGC,  //OFFSET_BYPASS_BIT_MASK_FIELD
      0,                                          // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
      &stream_map_sndout,  //OFFSET_PTR_INPUT_FIELD
      &stream_map_sndout,  //OFFSET_PTR_OUTPUT_FIELD
#if uses_ADF
      &adf_object + $M.adf_alg_1_0_0.OFFSET_PP_VAD_DETECT,
#else
      &ZeroValue,
#endif
                           //OFFSET_PTR_VAD_VALUE_FIELD
      0x7FFFFF,            //OFFSET_HARD_LIMIT_FIELD
      0,                   //OFFSET_PTR_TONE_FLAG_FIELD
      0 ...;
#endif

   .VAR/DM1 $M.beamformer0.dm1[$M.BEAMFORMER.DATA_SIZE_DM1];
   .VAR beamformer0_obj[$M.BEAMFORMER.STRUC_SIZE] =
      0,                   // $M.BEAMFORMER.OFFSET_X0_REAL_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_X0_IMAG_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_BEXP_X0_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_X1_REAL_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_X1_IMAG_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_BEXP_X1_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_Z_REAL_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_Z_IMAG_PTR (initialized internally from 2mic_hf_object)
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BF_STEP_SIZE,   // $M.BEAMFORMER.OFFSET_MU_PTR
      1,                   // $M.BEAMFORMER.OFFSET_BEAM_MODE_PTR
      0.024*2,             // $M.BEAMFORMER.OFFSET_ELEMENT_D
      30,                  // $M.BEAMFORMER.OFFSET_DOA
      $M.beamformer0.dm1,  // $M.BEAMFORMER.OFFSET_PTR_DM1data
      bf_dm1_scratch,
      bf_dm2_scratch;

   .VAR/DM1 $M.beamformer1.dm1[$M.BEAMFORMER.DATA_SIZE_DM1];
   .VAR beamformer1_obj[$M.BEAMFORMER.STRUC_SIZE] =
      0,                   // $M.BEAMFORMER.OFFSET_X0_REAL_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_X0_IMAG_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_BEXP_X0_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_X1_REAL_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_X1_IMAG_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_BEXP_X1_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_Z_REAL_PTR (initialized internally from 2mic_hf_object)
      0,                   // $M.BEAMFORMER.OFFSET_Z_IMAG_PTR (initialized internally from 2mic_hf_object)
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BF_STEP_SIZE,   // $M.BEAMFORMER.OFFSET_MU_PTR
      1,                   // $M.BEAMFORMER.OFFSET_BEAM_MODE
      0.024*2,             // $M.BEAMFORMER.OFFSET_ELEMENT_D
      -30,                 // $M.BEAMFORMER.OFFSET_DOA
      $M.beamformer1.dm1,  // $M.BEAMFORMER.OFFSET_PTR_DM1data
      bf_dm1_scratch,
      bf_dm2_scratch;

#if uses_NSVOLUME
   // NDVC - Noise Controled Volume
   .VAR/DM1 ndvc_obj[$M.NDVC_Alg1_0_0.BLOCK_SIZE +$M.NDVC_Alg1_0_0.MAX_STEPS] =
      0,                               // OFFSET_CONTROL_WORD
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_NDVC,                    //OFFSET_BITMASK_BYPASS
      $M.NDVC_Alg1_0_0.MAX_STEPS,      // OFFSET_MAXSTEPS
      &out0_oms_LpXnz,  // OFFSET_PTR_LPDNZ
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_NDVC_HYSTERESIS,  // OFFSET_PTR_PARAMS
      0 ...;
#endif

   .VAR     mic_in_l_pk_dtct[] =
      &stream_map_left_adc,            // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL_PTR

   .VAR     mic_in_r_pk_dtct[] =
      &stream_map_right_adc,           // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL_PTR

   .VAR sco_out_pk_dtct[] =
      &stream_map_sndout,              // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL_PTR

#if uses_ADF
    .VAR/DM1 ADF_L_PostP_ctrl[$M.adf_alg_1_0_0.ADF_num_proc];
    .VAR/DM1 $M.adf_alg_1_0_0.dm1[$M.adf_alg_1_0_0.DATA_SIZE_DM1];
    .VAR/DM2 $M.adf_alg_1_0_0.dm2[$M.adf_alg_1_0_0.DATA_SIZE_DM2];
    // PreP_delay:  (initialized in algorithm)
    .VAR/DM1 $M.adf_alg_1_0_0.dm1const[2*$M.CVC.Num_FFT_Freq_Bins];

   .VAR/DM1 adf_object[$M.adf_alg_1_0_0.STRUCT_SIZE] =
      &D_l_real,                 // OFFSET_FNLMS_E_REAL_PTR (set internally)
      &D_l_imag,                 // OFFSET_FNLMS_E_IMAG_PTR (set internally)
      0,                         // OFFSET_FNLMS_D_EXP_PTR (set internally)
      0,                         // OFFSET_FNLMS_D_REAL_PTR (set internally)
      0,                         // OFFSET_FNLMS_D_IMAG_PTR (set internally)
      &Exp_Mts_adapt,            // OFFSET_SCRPTR_Exp_Mts_adapt
      $AEC_500.rer_adfrnr,       // OFFSET_RER_EXT_FUNC_PTR
      0,                         // OFFSET_RER_D_REAL_PTR, (set internally)
      0,                         // OFFSET_RER_D_IMAG_PTR, (set internally)
      0,                         // OFFSET_PTR_Gr_imag (set internally)
      0,                         // OFFSET_PTR_Gr_real (set internally)
      0,                         // OFFSET_PTR_SqGr (set internally)
      0,                         // OFFSET_PTR_L2absGr (set internally)
      0,                         // OFFSET_PTR_LPwrD (set internally)
      0,                         // OFFSET_SCRPTR_W_ri (set internally)
      0,                         // OFFSET_SCRPTR_L_adaptR (set internally)
      4,                         // OFFSET_RER_SQGRDEV
      &D_l_real,                 // OFFSET_X0_REAL_PTR
      &D_l_imag,                 // OFFSET_X0_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,            // OFFSET_X0_EXP_PTR
      0,                         // OFFSET_ADF_LPx0
      &D_r_real,                 // OFFSET_X1_REAL_PTR
      &D_r_imag,                 // OFFSET_X1_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_BEXP,            // OFFSET_X1_EXP_PTR
      0,                               // OFFSET_ADF_LPx1
      &$M.adf_alg_1_0_0.dm1,           // OFFSET_PTR_DM1data
      &$M.adf_alg_1_0_0.dm2,           // OFFSET_PTR_DM2data
      &$M.adf_alg_1_0_0.dm1const,      // OFFSET_PTR_DM1const
      &$adf.dm1_table,                 // OFFSET_PTR_DM1tables
      &adf_dm1_scratch,                // OFFSET_SCRATCH_DM1
      &adf_dm2_scratch,                // OFFSET_SCRATCH_DM2
      0,                               // OFFSET_OMS_G_PTR
      &D_l_real,                       // OFFSET_E_OUT_REAL_PTR
      &D_l_imag,                       // OFFSET_E_OUT_IMAG_PTR
      &$M.cvc.twoMicHF_control.adf_postProc, // OFFSET_POSTPROC_FUNCPTR
      &ADF_L_PostP_ctrl,               // OFFSET_L_POSTP_CTRL_PTR
      $M.CVC.Num_FFT_Freq_Bins,        // OFFSET_NUMFREQ_BINS

      0x0003,              // OFFSET_CONTROL
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_PREP,      // OFFSET_BITMASK_BYPASS_PREP
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_MGDC,      // OFFSET_BITMASK_BYPASS_MGDC
      $M.CVC_HANDSFREE_2MIC.CONFIG.WIDE_MIC_ENA,     // OFFSET_BITMASK_WIDE_MIC_ENA
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_RPT_POSTP, // OFFSET_BITMASK_BYPASS_RPT_POSTP
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_ADFPS,     // OFFSET_BITMASK_BYPASS_ADFPS
      $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_ADFRNR,    // OFFSET_BITMASK_BYPASS_ADFRNR 
      0xFD95C1,            // OFFSET_PP_GAMMAP log2(gammaP/Np_sb), gammaP=0.75,Np_sb=4 : signed Q8.16
      0.5,                 // OFFSET_PP_THRES  1.0 - 0.65;  // threshold for high freq adapt decision
      1,                   // OFFSET_PP_VAD_DETECT
      0.35,                // OFFSET_PP_VAD_THRES
      0,                   // OFFSET_PP_CTRL_BIAS (0.0 dB)
      0x100000,            // OFFSET_PP_CTRL_TRANS (2.0 in Q19)
      0.000374929696288273,// OFFSET_MGDC_ALFAD             // SP.  Changed due to frame size
      0.00259525632413075, // OFFSET_MGDC_FRONTMICBIAS  Q8.16
      0.0155715379447845,  // OFFSET_MGDC_MAXCOMP       Q8.16
      0xE01C08,            // OFFSET_MGDC_ADAPT_THRESH  Q8.16
      10,                  // OFFSET_MGDC_K_LB
      32,                  // OFFSET_MGDC_K_HB
      -4,                  // OFFSET_MGDC_MEAN_SCL_EXP
      0.727272727272727,   // OFFSET_MGDC_MEAN_SCL_MTS
      $M.adf_alg_1_0_0.MGDC_param.Th0, // OFFSET_MGDC_TH0
      $M.adf_alg_1_0_0.MGDC_param.Th1, // OFFSET_MGDC_TH1
      &ZeroValue,          // OFFSET_PTR_WIND_DETECT
      &ZeroValue,          // OFFSET_PTR_ADF_HOLD
      1.0,                 // OFFSET_DMSS_WEIGHT
      0,                   // OFFSET_OMS_LPXNZ_PTR
      -29.0/128,           // OFFSET_L2TH_ADFPS_ON
      -25.0/128,           // OFFSET_L2TH_ADFPS_OFF
      3.0/128,             // OFFSET_L2TH_ADFPSV_CLEAN
      -3.0/128,            // OFFSET_L2TH_ADFPSV_NOISY
      4.0/128,             // OFFSET_L2TH_ADFPSV_POSTP
      2.98973528539863/128,// OFFSET_TH_ADF_DLPZ
      2.0/32,              // OFFSET_PREP_DT_MIC
      0.836660026534076,   // OFFSET_SQRT_PREP_SUBFACTOR   sqrt(0.7)=0.83666
      0/128,               // OFFSET_REPL_ADJUST
      2.0/8,               // OFFSET_REPL_POWER
      0.208934889149704,   // OFFSET_RNR_ALFA, ADFRNR time constant in Q23  // SP  Change due to frame size
      0.125,               // OFFSET_RNR_ADJUST, Q20
      0,                   // OFFSET_RNR_BIAS   ADFRNR_bias = ADFRNR_bias_dB * (log2(10)/10) in Q16
      0.125,               // OFFSET_RNR_TRANS, Q20
      0,                   // OFFSET_L2FBpXD (63)
      0 ...;
#endif

   .VAR/DM1 $M.aed.dm1[$M.AED.DATA_SIZE_DM1];
   .VAR aed_object[$M.AED.STRUC_SIZE] =
      &out0_oms_G,                                    // $M.AED.OFFSET_G_OMS0
      &out0_oms270snd_obj + $M.oms270.VOICED_FIELD,   // $M.AED.OFFSET_VOICED_OMS0
      &out1_oms_G,                                    // $M.AED.OFFSET_G_OMS1
      &out1_oms270snd_obj + $M.oms270.VOICED_FIELD,   // $M.AED.OFFSET_VOICED_OMS1
      0,                   // $M.AED.OFFSET_VOICEFLAG
      0,                   // $M.AED.OFFSET_MODE
      0,                   // $M.AED.OFFSET_STATE_T
      0,                   // $M.AED.OFFSET_VAD;
      0,                   // $M.AED.OFFSET_CHANNEL;
      0,                   // $M.AED.OFFSET_G_AED;
      0x020000,            // $M.AED.OFFSET_Noise_Th  // 2 in Q16
      0.846644997596741,   // $M.AED.OFFSET_alphaA
      0.0423322916030884,  // $M.AED.OFFSET_alphaN
      400,                 // $M.AED.OFFSET_NR_defer_Count
      110,                 // $M.AED.OFFSET_NR_max_Count
      -0.015,              // $M.AED.OFFSET_NR_alpha
      67,                  // $M.AED.OFFSET_S_ACTIVE_COUNT
      12,                  // $M.AED.OFFSET_S_ACTIVE_COUNT_DIV_6
      $M.aed.dm1;          // $M.AED.OFFSET_PTR_DM1data

   .VAR/DM1 $M.two_ch_nc.dm1[$M.TWOCHANNEL_NC.DATA_SIZE_DM1];
   .VAR/DM2 $M.two_ch_nc.dm2[$M.TWOCHANNEL_NC.DATA_SIZE_DM2];
   .VAR/DM1 TwoChNC[$M.TWOCHANNEL_NC.STRUC_SIZE] =
      &fft_real,                       // OFFSET_E_REAL_PTR
      &fft_imag,                       // OFFSET_E_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_BEXP, // OFFSET_Z0_EXP_PTR
      &Z0_real,                        // OFFSET_Z0_REAL_PTR
      &Z0_imag,                        // OFFSET_Z0_IMAG_PTR
      &Exp_Mts_adapt,                  // OFFSET_SCRPTR_Exp_Mts_adapt
      &Z1_real,                        // OFFSET_Z1_REAL_PTR
      &Z1_imag,                        // OFFSET_Z1_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_PTR_BEXP, // OFFSET_Z1_EXP_PTR
      0,                               // (set internally)
      0xFE95C1,                        // OFFSET_PP_GAMMAP = log2(gammaP/NC_p.NTaps)
      1,                               // OFFSET_bypass_postp_rpt
      2,                               // (set internally)
      0,                               // OFFSET_SCRATCH_DM1
      &Exp_Mts_adapt,                  // OFFSET_SCRATCH_DM2
      $M.two_ch_nc.dm1,                //
      $M.two_ch_nc.dm2                 //
      ;

   // Inputs/Outputs
   .VAR mu = 0.02;

   .VAR Z0_real[$M.BEAMFORMER.BIN_H];
   .VAR Z0_imag[$M.BEAMFORMER.BIN_H];
   .VAR Z1_real[$M.BEAMFORMER.BIN_H];
   .VAR Z1_imag[$M.BEAMFORMER.BIN_H];


   .VAR/DM1 $M.twomic_hf_500.dm1[$M.TWOMIC_HF_500.DATA_SIZE_DM1];
   .VAR twomic_hf_500_obj[$M.TWOMIC_HF_500.STRUC_SIZE] =
      0x000000,         // $M.TWOMIC_HF_500.OFFSET_CONFIG
      0,                // $M.TWOMIC_HF_500.OFFSET_MIC_MODE
      1,                // $M.TWOMIC_HF_500.OFFSET_MGDC_CTRL
      &beamformer0_obj,
      &beamformer1_obj,
      &aec2Mic_dm1,
      &aed_object,
      &TwoChNC,
      &in_oms_G,
      &out0_oms_G,
      &out1_oms_G,
      0,                   // $M.TWOMIC_HF_500.OFFSET_NUM_BINS (filled internally)
      &D_l_real,           // $M.TWOMIC_HF_500.OFFSET_X0_REAL_PTR
      &D_l_imag,           // $M.TWOMIC_HF_500.OFFSET_X0_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_BEXP,
                           // $M.TWOMIC_HF_500.OFFSET_BEXP_X0_PTR
      &D_r_real,           // $M.TWOMIC_HF_500.OFFSET_X1_REAL_PTR
      &D_r_imag,           // $M.TWOMIC_HF_500.OFFSET_X1_IMAG_PTR
      &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_PTR_BEXP,
                           // $M.TWOMIC_HF_500.OFFSET_BEXP_X1_PTR
      &Z0_real,            // $M.TWOMIC_HF_500.OFFSET_Z0_REAL_PTR
      &Z0_imag,            // $M.TWOMIC_HF_500.OFFSET_Z0_IMAG_PTR
      &Z1_real,            // $M.TWOMIC_HF_500.OFFSET_Z1_REAL_PTR
      &Z1_imag,            // $M.TWOMIC_HF_500.OFFSET_Z1_IMAG_PTR
      -0.0275949239730835, // $M.TWOMIC_HF_500.OFFSET_TMP_LalfaLPz
      0,                   // (initialized internally)
      0,                   // (initialized internally)
      0,                   // (initialized internally)
      0,                   // (initialized internally)
      $M.twomic_hf_500.dm1    // Phase buffer
      ;


   // -----------------------------------------------------------------------------

   // Parameter to Module Map
   .VAR/ADDR_TABLE_DM   ParameterMap[] =

#if uses_AEC
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SND_OMS_HFK_AGGR,     &aec_dm1 + $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_CNG_Q,                &aec_dm1 + $M.AEC_500.OFFSET_CNG_Q_ADJUST,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_CNG_SHAPE,            &aec_dm1 + $M.AEC_500.OFFSET_CNG_NOISE_COLOR,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_DTC_AGGR,             &aec_dm1 + $M.AEC_500.OFFSET_DTC_AGRESSIVENESS,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MAX_LPWRX_MARGIN,     &aec_dm1 + $M.AEC_500.OFFSET_MAX_LPWR_MARGIN,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE,     &aec_dm1 + $M.AEC_500.OFFSET_ENABLE_AEC_REUSE,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEC_REF_LPWR_HB,      &aec_dm1 + $M.AEC_500.OFFSET_AEC_REF_LPWR_HB,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,           &aec_dm1 + $M.AEC_500.OFFSET_CONFIG,
	   &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RER_AGGRESSIVENESS,   &aec_dm1 + $M.AEC_500.OFFSET_RER_AGGRESSIVENESS,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RER_WGT_SY,           &aec_dm1 + $M.AEC_500.OFFSET_RER_WGT_SY,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RER_OFFSET_SY,        &aec_dm1 + $M.AEC_500.OFFSET_RER_OFFSET_SY,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RER_POWER,            &aec_dm1 + $M.AEC_500.OFFSET_RER_POWER,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RER_VAR_THRESH,       &aec_dm1 + $M.AEC_500.OFFSET_RER_VAR_THRESH,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RERDT_OFF_THRESHOLD,  &aec_dm1 + $M.AEC_500.OFFSET_L2TH_RERDT_OFF,
	   &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RERDT_AGGRESSIVENESS, &aec_dm1 + $M.AEC_500.OFFSET_RERDT_ADJUST,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RERDT_POWER,          &aec_dm1 + $M.AEC_500.OFFSET_RERDT_POWER,
   #if uses_NONLINEAR_PROCESSING
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_TIER2_THRESH,      &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_TIER2_THRESH,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN,    &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,
   #endif // Nonlinear Processing
#endif

#if uses_SND_NS
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &out0_oms270snd_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_OMS_HARMONICITY,   &out0_oms270snd_obj + $M.oms270.HARM_ON_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &out1_oms270snd_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_OMS_HARMONICITY,   &out1_oms270snd_obj + $M.oms270.HARM_ON_FIELD,
#endif
#if uses_SSR
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &oms270ssr_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_OMS_HARMONICITY,   &oms270ssr_obj + $M.oms270.HARM_ON_FIELD,
#endif

#if uses_RCV_NS
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &oms270rcv_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_RCV_OMS_HFK_AGGR,  &oms270rcv_obj + $M.oms270.AGRESSIVENESS_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_OMS_HI_RES_MODE,   &oms270rcv_obj + $M.oms270.HARM_ON_FIELD,
#endif

#if uses_RCV_AGC
      // RCV AGC parameters
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &rcv_agc400_dm + $M.agc400.OFFSET_SYS_CON_WORD_FIELD,
#endif

#if uses_NSVOLUME
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &ndvc_obj + $M.NDVC_Alg1_0_0.OFFSET_CONTROL_WORD,   //control word for bypass
#endif

#if uses_SND_AGC
      // SND AGC parameters
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &snd_agc400_dm + $M.agc400.OFFSET_SYS_CON_WORD_FIELD,
#endif

#if uses_AEQ
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,           &AEQ_DataObject + $M.AdapEq.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_ATK_TC,           &AEQ_DataObject + $M.AdapEq.ALFA_A_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_ATK_1MTC,         &AEQ_DataObject + $M.AdapEq.ONE_MINUS_ALFA_A_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_DEC_TC,           &AEQ_DataObject + $M.AdapEq.ALFA_D_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_DEC_1MTC,         &AEQ_DataObject + $M.AdapEq.ONE_MINUS_ALFA_D_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BEX_NOISE_LVL_FLAGS,  &AEQ_DataObject + $M.AdapEq.BEX_NOISE_LVL_FLAGS,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BEX_LOW_STEP,         &AEQ_DataObject + $M.AdapEq.BEX_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BEX_HIGH_STEP,        &AEQ_DataObject + $M.AdapEq.BEX_PASS_HIGH_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_POWER_TH,         &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TH_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_MIN_GAIN,         &AEQ_DataObject + $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_MAX_GAIN,         &AEQ_DataObject + $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH1,  &AEQ_DataObject + $M.AdapEq.VOL_STEP_UP_TH1_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH2,  &AEQ_DataObject + $M.AdapEq.VOL_STEP_UP_TH2_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOW_STEP,         &AEQ_DataObject + $M.AdapEq.AEQ_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOW_STEP_INV,     &AEQ_DataObject + $M.AdapEq.INV_AEQ_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_STEP,        &AEQ_DataObject + $M.AdapEq.AEQ_PASS_HIGH_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_STEP_INV,    &AEQ_DataObject + $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD,

      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOW_BAND_INDEX,      &AEQ_DataObject + $M.AdapEq.LOW_INDEX_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOW_BANDWIDTH,       &AEQ_DataObject + $M.AdapEq.LOW_BW_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOG2_LOW_BANDWIDTH,  &AEQ_DataObject + $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_MID_BANDWIDTH,       &AEQ_DataObject + $M.AdapEq.MID_BW_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOG2_MID_BANDWIDTH,  &AEQ_DataObject + $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_BANDWIDTH,      &AEQ_DataObject + $M.AdapEq.HIGH_BW_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_LOG2_HIGH_BANDWIDTH, &AEQ_DataObject + $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_MID1_BAND_INDEX,     &AEQ_DataObject + $M.AdapEq.MID1_INDEX_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_MID2_BAND_INDEX,     &AEQ_DataObject + $M.AdapEq.MID2_INDEX_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_BAND_INDEX,     &AEQ_DataObject + $M.AdapEq.HIGH_INDEX_FIELD,
#endif

#if uses_PLC
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PLC_STAT_INTERVAL,       &$sco_data.object + $sco_pkt_handler.STAT_LIMIT_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,              &$sco_data.object + $sco_pkt_handler.CONFIG_FIELD,
#endif

      // Auxillary Audio Settings
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_CLIP_POINT,           &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.CLIP_POINT_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BOOST_CLIP_POINT,     &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.BOOST_CLIP_POINT_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BOOST,                &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.BOOST_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SCO_STREAM_MIX,       &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PRIM_GAIN_FIELD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AUX_STREAM_MIX,       &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.AUX_GAIN_FIELD,


#if uses_ADF
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,           &adf_object + $M.adf_alg_1_0_0.OFFSET_CONTROL,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PREP_DT_MIC,          &adf_object + $M.adf_alg_1_0_0.OFFSET_PREP_DT_MIC,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SQRT_PREP_SUBFACTOR,  &adf_object + $M.adf_alg_1_0_0.OFFSET_SQRT_PREP_SUBFACTOR,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_DMSS_REPL_ADJUST,     &adf_object + $M.adf_alg_1_0_0.OFFSET_REPL_ADJUST,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_DMSS_REPL_POWER,      &adf_object + $M.adf_alg_1_0_0.OFFSET_REPL_POWER,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MGDC_ALFAD,           &adf_object + $M.adf_alg_1_0_0.OFFSET_MGDC_ALFAD,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MGDC_FRONTMICBIAS,    &adf_object + $M.adf_alg_1_0_0.OFFSET_MGDC_FRONTMICBIAS,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MGDC_MAXCOMP,         &adf_object + $M.adf_alg_1_0_0.OFFSET_MGDC_MAXCOMP,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MGDC_ADAPT_THRESH,    &adf_object + $M.adf_alg_1_0_0.OFFSET_MGDC_ADAPT_THRESH,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MGDC_TH0,             &adf_object + $M.adf_alg_1_0_0.OFFSET_MGDC_TH0,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_MGDC_TH1,             &adf_object + $M.adf_alg_1_0_0.OFFSET_MGDC_TH1,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_TH_ADF_DLPZ,          &adf_object + $M.adf_alg_1_0_0.OFFSET_TH_ADF_DLPZ,
#endif

#if uses_AEC
      // HD threshold
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN,       &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,
#endif

#if uses_TMP
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_TMP_CONFIG,        &twomic_hf_500_obj + $M.TWOMIC_HF_500.OFFSET_CONFIG,

   #if uses_BF
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BF_0_DOA,             &beamformer0_obj + $M.BEAMFORMER.OFFSET_DOA,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BF_1_DOA,             &beamformer1_obj + $M.BEAMFORMER.OFFSET_DOA,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BF_BEAM_MODE,         &beamformer0_obj + $M.BEAMFORMER.OFFSET_BEAM_MODE,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_BF_BEAM_MODE,         &beamformer1_obj + $M.BEAMFORMER.OFFSET_BEAM_MODE,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PREP_DT_MIC_IN_MM,    &beamformer0_obj + $M.BEAMFORMER.OFFSET_ELEMENT_D,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PREP_DT_MIC_IN_MM,    &beamformer1_obj + $M.BEAMFORMER.OFFSET_ELEMENT_D,
   #endif

   #if uses_AED
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AED_ALPHAA,                 &aed_object + $M.AED.OFFSET_alphaA,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AED_ALPHAN,                 &aed_object + $M.AED.OFFSET_alphaN,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AED_NOISE_TH,               &aed_object + $M.AED.OFFSET_Noise_Th,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AED_NR_MAX_COUNT,           &aed_object + $M.AED.OFFSET_NR_max_Count,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AED_S_ACTIVE_COUNT,         &aed_object + $M.AED.OFFSET_S_ACTIVE_COUNT,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_AED_S_ACTIVE_COUNT_DIV_6,   &aed_object + $M.AED.OFFSET_S_ACTIVE_COUNT_DIV_6,
   #endif

   #if uses_TWOCH_NC
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_TWOCH_NC_GAMMAP,     &TwoChNC + $M.TWOCHANNEL_NC.OFFSET_PP_GAMMAP,
      &CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_TWOCH_NC_RPTP,       &TwoChNC + $M.TWOCHANNEL_NC.OFFSET_bypass_postp_rpt,
   #endif

#endif

     // End of Parameter Map
      0;

   // Statistics from Modules sent via SPI
   // -------------------------------------------------------------------------------
   .VAR/ADDR_TABLE_DM  StatisticsPtrs[]=//[$M.CVC_HANDSFREE_2MIC.STATUS.BLOCK_SIZE+2] =
      $M.CVC_HANDSFREE_2MIC.STATUS.BLOCK_SIZE,
      &StatisticsClrPtrs,
      // Statistics
      &$M.CVC_SYS.cur_mode,                             // $M.CVC_HANDSFREE_2MIC.STATUS.CUR_MODE_OFFSET
      &$M.CVC_SYS.CurCallState,                         // $M.CVC_HANDSFREE_2MIC.STATUS.CALL_STATE_OFFSET
      &$M.CVC_SYS.SysControl,                           // $M.CVC_HANDSFREE_2MIC.STATUS.SYS_CONTROL_OFFSET
      &$M.CVC_SYS.CurDAC,                               // $M.CVC_HANDSFREE_2MIC.STATUS.CUR_DAC_OFFSET
      &$M.CVC_SYS.Last_PsKey,                           // $M.CVC_HANDSFREE_2MIC.STATUS.PRIM_PSKEY_OFFSET
      &$M.CVC_SYS.SecStatus,                            // $M.CVC_HANDSFREE_2MIC.STATUS.SEC_STAT_OFFSET
      &$dac_out.spkr_out_pk_dtct,
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.CVC.app.scheduler.tasks+$FRM_SCHEDULER.TOTAL_MIPS_FIELD,   // $M.CVC_HANDSFREE_2MIC.STATUS.PEAK_MIPS_OFFSET

#if uses_NSVOLUME
      &ndvc_obj + $M.NDVC_Alg1_0_0.OFFSET_FILTSUMLPDNZ,
      &ndvc_obj + $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL,
#else
      &ZeroValue,&ZeroValue,
#endif
      $dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PEAK_AUXVAL_FIELD,
      &$M.CVC_MODULES_STAMP.CompConfig,                  // $M.CVC_HANDSFREE_2MIC.STATUS.COMPILED_CONFIG
      &$M.CVC_SYS.Volume,
      &$M.CVC_SYS.ConnectStatus,                         // $M.CVC_HANDSFREE_2MIC.STATUS.CONNSTAT
#if uses_PLC
      &$sco_data.object + $sco_pkt_handler.PACKET_LOSS_FIELD,    // PLC Loss Rate
#else
      &ZeroValue,
#endif
#if uses_AEQ
      &AEQ_DataObject + $M.AdapEq.AEQ_GAIN_LOW_FIELD,          // AEQ Gain Low
      &AEQ_DataObject + $M.AdapEq.AEQ_GAIN_HIGH_FIELD,         // AEQ Gain High
      &AEQ_DataObject + $M.AdapEq.STATE_FIELD,                 // AEQ State
      &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TEST_FIELD,        // AEQ Tone Detection
      &AEQ_DataObject + $M.AdapEq.AEQ_TONE_POWER_FIELD,        // AEQ Tone Power
#else
      &ZeroValue,&ZeroValue,&ZeroValue,&ZeroValue,&ZeroValue,
#endif
#if uses_AEC
      &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HC_TIER_STATE,
      &aec_dm1 + $M.AEC_500.OFFSET_AEC_COUPLING,
#else
      &ZeroValue,&ZeroValue,
#endif
#if uses_RCV_VAD
      &rcv_vad400 + $M.vad400.FLAG_FIELD,
#else
      &ZeroValue,
#endif
#if uses_SND_AGC
      &snd_agc400_dm + $M.agc400.OFFSET_INPUT_LEVEL_FIELD,   // AGC Speech Power Level
      &snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD,        // AGC Applied Gain
#else
      &OneValue,&OneValue,
#endif

#if uses_RCV_AGC
      &rcv_agc400_dm + $M.agc400.OFFSET_INPUT_LEVEL_FIELD,   // AGC Speech Power Level (Q8.16 log2 power)
      &rcv_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD,        // AGC Applied Gain (Q6.17 linear gain [0 - 64.0])
#else
      &OneValue,&OneValue,
#endif


    // Resampler related stats - SPTBD - add to XML
    $M.audio_config.audio_if_mode,
    $M.audio_config.adc_sampling_rate,
    $M.audio_config.dac_sampling_rate,
    $M.FrontEnd.frame_adc_sampling_rate;

// Clear These statistics
.VAR/ADDR_TABLE_DM StatisticsClrPtrs[] =
      &$dac_out.spkr_out_pk_dtct,
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &sco_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      $dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PEAK_AUXVAL_FIELD,
      0;

   // Processing Tables
   // ----------------------------------------------------------------------------
   .VAR/DM ReInitializeTable[] =

      // Function                                           r7                 r8

      // wmsn: only executed when FE/BEX
      $frame.iir_resamplev2.Initialize,                  &ref_downsample_dm1,   0 ,
      $frame.iir_resamplev2.Initialize,                  &dac_upsample_dm1,   0 ,

#ifdef uses_SSR
      $filter_bank.one_channel.analysis.initialize,  &fft_obj,         &AnalysisBank_ASR,
#endif
      $filter_bank.two_channel.analysis.initialize,  &fft_obj,         &MicAnalysisBank,
      $filter_bank.one_channel.synthesis.initialize, &fft_obj,         &SndSynthesisBank,

#if uses_RCV_FREQPROC
      $filter_bank.one_channel.analysis.initialize,  &fft_obj,         &RcvAnalysisBank,
      $filter_bank.one_channel.synthesis.initialize, &fft_obj,     &RcvSynthesisBank,
#if uses_RCV_NS
      $M.oms270.initialize.func,           &oms270rcv_obj,           0,
#endif
#if uses_AEQ
     $M.AdapEq.initialize.func,                0,                 &AEQ_DataObject,
#endif
#endif

   $M.2Mic_hf_500.initialize,             &twomic_hf_500_obj,        0,
   $M.oms270.initialize.func,             &in_oms270snd_obj,         	0,
   $M.oms270.initialize.func,             &out0_oms270snd_obj,         	0,
   $M.oms270.initialize.func,             &out1_oms270snd_obj,         	0,
   $twoMicHF.AEC.init,                    &twomic_hf_500_obj,           0,
   $M.adf_alg_1_0_0.Initialize.func,      &adf_object,                  0,
   $filter_bank.one_channel.analysis.initialize,  &fft_obj, &AecAnalysisBank,

#if uses_DCBLOCK
      $audio_proc.peq.initialize,         &in_l_dcblock_dm2,        0,
      $audio_proc.peq.initialize,         &in_r_dcblock_dm2,        0,
      $audio_proc.peq.initialize,         &sco_dcblock_dm2,         0,
#endif

#if uses_SND_PEQ
      $audio_proc.peq.initialize,     &snd_peq_dm2,             0,
#endif

#if uses_RCV_PEQ
      $audio_proc.peq.initialize,     &rcv_peq_dm2,             0,
#endif


#if uses_RCV_VAD
      $audio_proc.peq.initialize,          &rcv_vad_peq,             0,
      $M.vad400.initialize.func,           &rcv_vad400,              0,
#endif
#if uses_RCV_AGC
      $M.agc400.initialize.func,           0,                        &rcv_agc400_dm,
      $agc400.persist_gain_load,           0,                        0,   
#endif

#if uses_NSVOLUME
      $M.NDVC_alg1_0_0.Initialize.func,   &ndvc_obj,                    0,
#endif

#if uses_SND_AGC
      $audio_proc.peq.initialize,          &snd_vad_peq,             0,
      $M.vad400.initialize.func,           &snd_vad400,              0,
      $M.agc400.initialize.func,                0,                 &snd_agc400_dm,
#endif


//wq      $frame_sync.sidestone_filter_op.InitializeFilter,     &$adc_in.sidetone_copy_op.param,  0,

      0;                                    // END OF TABLE

   // -------------------------------------------------------------------------------
   // Table of functions for current mode
   .VAR  ModeProcTableSnd[$M.CVC_HANDSFREE_2MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsSnd,             // standby-mode
      &hfk_proc_funcsSnd,              // hfk mode
#if uses_SSR
      &ssr_proc_funcsSnd,              // ssr mode
#else
      &copy_proc_funcsSnd,             // undefined mode
#endif
      &copy_proc_funcsSnd,             // pass-thru left mode
      &copy_proc_funcsSnd,             // pass-thru right mode
      &copy_proc_funcsLpbk,            // loop-back mode
      &copy_proc_funcsSnd;             // unknown state

   .VAR  ModeProcTableRcv[$M.CVC_HANDSFREE_2MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsRcv,             // standby-mode
      &hfk_proc_funcsRcv,              // hfk mode
      &hfk_proc_funcsRcv,              // ssr mode
      &copy_proc_funcsRcv,             // pass-thru left mode
      &copy_proc_funcsRcv,             // pass-thru right mode
      0,                               // loop-back mode       // SP. Loopback does all processing in Send
      &copy_proc_funcsRcv;             // standby-mode


   // -----------------------------------------------------------------------------
   .VAR/DM hfk_proc_funcsRcv[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,      &rcv_process_streams,    0,

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &sco_dcblock_dm2,       0,      // Ri --> Ri
#endif

      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,        0,

#if uses_RCV_VAD
      $audio_proc.peq.process,                  &rcv_vad_peq,           0,
      $M.vad400.process.func,                   &rcv_vad400,            0,
#endif

#if uses_RCV_FREQPROC
      $filter_bank.one_channel.analysis.process, &fft_obj,        &RcvAnalysisBank,

#if uses_AEQ
      $M.AdapEq.process.tone_detect,            0,                &AEQ_DataObject,
#endif

#if uses_RCV_NS
      $M.oms270.process.func,                   &oms270rcv_obj,         0,
      $M.oms270.apply_gain.func,                &oms270rcv_obj,         0,
#endif

#if uses_AEQ
      $M.AdapEq.process.func,                   0,                &AEQ_DataObject,
#endif

      // wmsn: for NB/WB only, not for FE/BEX
      $cvc.non_fe.Zero_DC_Nyquist,              &$M.CVC.data.D_rcv_real,        &$M.CVC.data.D_rcv_imag,

      $filter_bank.one_channel.synthesis.process, &fft_obj,       &RcvSynthesisBank,
#else
      // SP.  No Freq domain processing, need explicit upsampling to 16 kHz
      // wmsn: only for FE/BEX
      $cvc.fe.frame_resample_process,         &dac_upsample_dm1, 0 ,
#endif

#if uses_RCV_PEQ
      // wmsn: for NB/FE only (not WB)
      $cvc.rcv_peq.process,                     &rcv_peq_dm2,           0,
#endif

      $M.audio_proc.stream_gain.Process.func,   &rcvout_gain_dm2,       0,

#if uses_RCV_AGC
      $M.agc400.process.func,                       0,              &rcv_agc400_dm,
#endif

#if uses_RCV_PEQ
      // wmsn: for WB only
      $cvc.rcv_peq.process_wb,                  &rcv_peq_dm2,           0,
#endif

      $frame_sync.update_streams_ind,           &rcv_process_streams,   0,

      0;                                     // END OF TABLE
   // -----------------------------------------------------------------------------

 .VAR/DM hfk_proc_funcsSnd[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,      &snd_process_streams,  0,

#if uses_DCBLOCK
      $audio_proc.peq.process,            &in_l_dcblock_dm2,            0,      // Si_L --> Si_L
      $audio_proc.peq.process,            &in_r_dcblock_dm2,            0,      // Si_R --> Si_R
#endif

      $M.audio_proc.peak_monitor.Process.func,           &mic_in_l_pk_dtct,            0,   // Si_L
      $M.audio_proc.peak_monitor.Process.func,           &mic_in_r_pk_dtct,            0,

      $twoMicHF.swapMics.process,               &twomic_hf_500_obj,     MicAnalysisBank,

      $filter_bank.two_channel.analysis.process, &fft_obj, &MicAnalysisBank,     // Si_R --> [D_r_real,D_r_imag]
                                                                                      // Si_L --> [D_l_real,D_l_imag]

      $twoMicHF.mgdc.process,          &twomic_hf_500_obj,        0,
      $M.oms270.process.func,          &in_oms270snd_obj,         0,

      #if uses_NSVOLUME
      $M.NDVC_alg1_0_0.Process.func,   &ndvc_obj,                 0,
      #endif

      $twoMicHF.aec.process,           &twomic_hf_500_obj,        0,
      $M.2Mic_hf_500.TMP.process,      &twomic_hf_500_obj,        0,
      $twoMicHF.ADF.process,           &twomic_hf_500_obj,        0,
      $M.TMPPwrMonitoring.output,      0,                         &twomic_hf_500_obj,

      #if uses_SND_NS
      $twoMicHF.OMS.process,           &twomic_hf_500_obj,        0,
      #endif

      $twoMicHF.beamformpost.process,  &twomic_hf_500_obj,        0,
      $M.2Mic_hf_500.AED.process,      &twomic_hf_500_obj,        0,
      $M.2Mic_hf_500.TwoMicNC.process, &twomic_hf_500_obj,        0,

      #if uses_SND_NS
      $M.oms270.apply_gain.func,       out0_oms270snd_obj,        0,
      $M.oms270.apply_gain.func,       out1_oms270snd_obj,        0,
      #endif

      $twoMicHF.NLP.process,           &twomic_hf_500_obj,        0,
      $CVC.CopyLeft_to_Right,          0,                         0,

      $M.CVC.Zero_DC_Nyquist.func,              &$M.CVC.data.D_r_real,        &$M.CVC.data.D_r_imag,
      $filter_bank.one_channel.synthesis.process, &fft_obj,   &SndSynthesisBank,

   #if uses_SND_PEQ
      $audio_proc.peq.process,                  &snd_peq_dm2,               0,
   #endif

      $M.audio_proc.stream_gain.Process.func,   &out_gain_dm1,              0,

   #if uses_ADF && uses_SND_NS && uses_SND_AGC
      $M.CVC.snd_agc_vad_recalc.func,  &twomic_hf_500_obj,        &snd_agc_vad_recalc,
   #endif

   #if uses_SND_AGC
      $M.agc400.process.func,                   0,                   &snd_agc400_dm,
   #endif

      $M.MUTE_CONTROL.Process.func,             &mute_cntrl_dm1,            0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,           0,

      $frame_sync.update_streams_ind,            &snd_process_streams,        0,

      0;                                     // END OF TABLE

   // -------------------------------------------------------------------------------
#if uses_SSR // Simple Speech Recognition
   .VAR/DM ssr_proc_funcsSnd[] =
      // Function                               r7                      r8
      $frame_sync.distribute_streams_ind, &snd_process_streams,         0,


   #if uses_DCBLOCK
      $audio_proc.peq.process,            &in_l_dcblock_dm2,            0,    // Si_L --> Si_L
      $audio_proc.peq.process,            &in_r_dcblock_dm2,            0,    // Si_R --> Si_R
   #endif

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,      0,    // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,      0,    // Si_R

      $filter_bank.one_channel.analysis.process, &fft_obj, &AnalysisBank_ASR, // Si_L --> [D_l_real,D_l_imag]

      $M.CVC.data.setSynthBExp,                 0,            &AnalysisBank_ASR + $M.filter_bank.Parameters.OFFSET_PTR_BEXP,
      $CVC.CopyLeft_to_Right,                   0,                      0,

   #if uses_SND_NS
      $M.oms270.process.func,                &oms270ssr_obj,            0,    // [D_r_real,D_r_imag]

    // Vector D_l_real has the OMS processed signal, so we have to copy it to D_r_real
      $CVC.CopyLeft_to_Right,                   0,                      0,
   #endif

      // SP.  ASR uses oms data object
      $M.wrapper.ssr.process,                   &asr_obj,               0,
      
      $M.MUTE_CONTROL.Process.func,             &mute_ssr_dm1,            0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,       0,

      $frame_sync.update_streams_ind,           &snd_process_streams,   0,
      0;                                     // END OF TABLE

#endif

   // -------------------------------------------------------------------------------

   .VAR/DM copy_proc_funcsSnd[] =
      // Function                               r7                      r8
      $frame_sync.distribute_streams_ind,       &snd_process_streams,   0,

      $cvc_Set_PassThroughGains,                &ModeControl,           0,

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,      0,    // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,      0,    // Si_R
      $M.audio_proc.stream_mixer.Process.func,  &adc_mixer,             0,    // Si_L,Si_R --> So
      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,       0,

      $frame_sync.update_streams_ind,           &snd_process_streams,   0,
      0;                                     // END OF TABLE

   .VAR/DM copy_proc_funcsRcv[] =
      // Function                               r7                      r8
      $frame_sync.distribute_streams_ind,       &rcv_process_streams,   0,

      $cvc_Set_PassThroughGains,                &ModeControl,           0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,        0,
      $M.audio_proc.stream_gain.Process.func,   &passthru_rcv_gain,     0,    // Ri --> Ro

      // SP.  passthru_rcv_gain must be before passthru_snd_gain for loopback.
      // passthru_snd_gain overwrites rcv_in. upsample is from rcv_in to rcv_out
      // wmsn: only executed when FE/BEX
      $cvc.fe.frame_resample_process,         &dac_upsample_dm1, 0 ,

      $frame_sync.update_streams_ind,           &rcv_process_streams,   0,
      0;                                     // END OF TABLE

// -----------------------------------------------------------------------------
   .VAR/DM copy_proc_funcsLpbk[] =
      // Function                               r7                      r8
      $frame_sync.distribute_streams_ind,       &lpbk_process_streams,  0,

      $cvc_Set_LoopBackGains,                   &ModeControl,           0,

     $M.audio_proc.peak_monitor.Process.func,   &mic_in_l_pk_dtct,      0,   // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,      0,   // Si_R
      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,        0,
      // SP.  Rcv gain must be applied before send mix for upsampling
      $M.audio_proc.stream_gain.Process.func,   &passthru_rcv_gain,     0,   // ri --> so
     $M.audio_proc.stream_mixer.Process.func,   &adc_mixer,             0,   // si --> ro or si->ri (BEX)


      // SP.  passthru_rcv_gain must be before adc_mixer. adc_mixer overwrites Ri.
      // upsample is from rcv_in to rcv_out
      // wmsn: only executed when FE/BEX
      $cvc.fe.frame_resample_process,         &dac_upsample_dm1, 0 ,             // Ri --> Ro (BEXT)

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,       0,

      $frame_sync.update_streams_ind,           &lpbk_process_streams,  0,
      0;                                     // END OF TABLE


// ***************  Stream Definitions  ************************/

// reference stream map
   .VAR	stream_map_refin[$framesync_ind.ENTRY_SIZE_FIELD] =
      $dac_out.reference_cbuffer_struc,         // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.DAC_Num_Samples_Per_Frame,         // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD     [--CONFIG--]
      $frame_sync.distribute_sync_stream_ind,   // Distribute Function
      $frame_sync.update_sync_streams_ind,      // Update Function
      &stream_map_left_adc,                     // $framesync_ind.SYNC_POINTER_FIELD
      2,                                        // $framssync_ind.SYNC_MULTIPLIER_FIELD
      0 ...;
    // SP.  Constant links.  Set in data objects
    //   &ref_downsample_dm1 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //   &ref_downsample_dm1 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,
    //   &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,


   // sndin stream map
   .VAR     stream_map_left_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
      $adc_in.left.cbuffer_struc,               // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
    // SP.  Constant links.  Set in data objects
    //  &in_l_dcblock_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &in_l_dcblock_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_FRAME,
    //  &AnalysisBank_ASR + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &adc_mixer + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH1_PTR,
    //  &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

   // sndin right stream map
   .VAR     stream_map_right_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
      $adc_in.right.cbuffer_struc,              // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
    // SP.  Constant links.  Set in data objects
    //  &in_r_dcblock_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &in_r_dcblock_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &MicAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_PTR_FRAME,
    //  &adc_mixer + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH2_PTR,
    //  &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,


   // sndout stream map.
   .VAR	stream_map_sndout[$framesync_ind.ENTRY_SIZE_FIELD] =
      0,                                        // $framesync_ind.CBUFFER_PTR_FIELD     [---CONFIG---]
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_output_stream_ind, // Distribute Function
      $frame_sync.update_output_streams_ind,    // Update Function
      0 ...;
    // SP.  Constant links.  Set in data objects
    //  &adc_mixer + $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR,
    //  &SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &out_gain_dm1 + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //  &out_gain_dm1 + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR,
    //  &snd_agc400_dm + $M.agc400.OFFSET_PTR_INPUT_FIELD,
    //  &snd_agc400_dm + $M.agc400.OFFSET_PTR_OUTPUT_FIELD,
    //  &snd_peq_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &snd_peq_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &mute_cntrl_dm1 + $M.MUTE_CONTROL.OFFSET_INPUT_PTR,
    //  &sco_out_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

  // rcvin stream map
   .VAR   stream_map_rcvin[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$far_end.in.output.cbuffer_struc,        // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
    // SP.  Constant links.  Set in data objects
    //  &sco_dcblock_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &sco_dcblock_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &rcv_vad_peq + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //  &passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR,
    //  &dac_upsample_dm1 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //  &sco_in_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

    // rcvout stream map
   .VAR stream_map_rcvout[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$dac_out.cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.DAC_Num_Samples_Per_Frame,         // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_output_stream_ind, // Distribute Function
      $frame_sync.update_output_streams_ind,    // Update Function
      0 ...;
    // SP.  Constant links.  Set in data objects
    //  &RcvSynthesisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &rcvout_gain_dm2 + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //  &rcvout_gain_dm2 + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR,
    //  &rcv_peq_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &rcv_peq_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &rcv_agc400_dm + $M.agc400.OFFSET_PTR_INPUT_FIELD,
    //  &rcv_agc400_dm + $M.agc400.OFFSET_PTR_OUTPUT_FIELD,
    //  &dac_upsample_dm1 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,
    //  &passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR,

   // -----------------------------------------------------------------------------

// Stream List for Receive Processing
.VAR/ADDR_TABLE_DM    rcv_process_streams[] =
   &stream_map_rcvin,
   &stream_map_rcvout,
   0;

// Stream List for Send Processing
.VAR/ADDR_TABLE_DM    snd_process_streams[] =
   &stream_map_left_adc,
   &stream_map_right_adc,
   &stream_map_refin,
   &stream_map_sndout,
   0;

// Stream List for Loopback Processing
.VAR/ADDR_TABLE_DM    lpbk_process_streams[] =
   &stream_map_left_adc,
   &stream_map_right_adc,
   &stream_map_refin,
   &stream_map_sndout,
   &stream_map_rcvin,
   &stream_map_rcvout,
   0;

// *****************************************************************************
// MODULE:
//          $M.CVC.data.setSynthBExp
//DESCRIPTION:
//       Sets the BExp pointer for OMS and Synthesis to the value located in r8.
//       It is used by the ASR mode to avoid creating new structures due to the
//       one channel filterbank.
// INPUTS:
//      r8 - Pointer to the desired BExp
// OUTPUT:
//      None
// MODIFIED REGISTERS:
//
// *****************************************************************************

   .CODESEGMENT PM_RAM;

setSynthBExp:
#if uses_SND_NS
   M[$M.CVC.data.in_oms270snd_obj + $M.oms270.PTR_BEXP_X_FIELD] = r8;
#endif
   M[$M.CVC.data.SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_PTR_BEXP] = r8;
   rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $M.purge_cbuffer
//
// DESCRIPTION:
//    Purge cbuffers by writing zeros into the cbuffer.
//    Without this function the DAC port would continuously be fed stale data
//    from DSP cbuffers when switching from HFK to SSR mode.
//
// INPUTS:
//    - r7 = Pointer to cbuffer struc
//
// OUTPUTS:
//    - none
//
// *****************************************************************************
#if uses_SSR
.MODULE $M.purge_cbuffer;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$purge_cbuffer:
   $push_rLink_macro;
   call $block_interrupts;
   r0 = r7;
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I0 = r0;
   L0 = r1;

   r10 = L0;
   r5 = Null;
   do clear_buffer;
      M[I0, 1] = r5;
   clear_buffer:

   L0 = 0;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif

   call $unblock_interrupts;
   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif


// Always called for a MODE change
.MODULE $M.CVC_HANDSFREE_2MIC.SystemReInitialize;


   .CODESEGMENT CVC_SYSTEM_REINITIALIZE_PM;
   .DATASEGMENT DM;

 func:
   // Clear Re-Initialize Flag
   M[$M.CVC_SYS.AlgReInit]    = Null;
   M[$M.CVC_SYS.FrameCounter] = Null;

   // Transfer Parameters to Modules.
   // Assumes at least one value is copied
   M1 = 1;
   I0 = &$M.CVC.data.ParameterMap;
   // Get Source (Pre Load)
   r0 = M[I0,M1];
lp_param_copy:
      // Get Destination
      r1 = M[I0,M1];
      // Read Source,
      r0 = M[r0];
      // Write Destination,  Get Source (Next)
      M[r1] = r0, r0 = M[I0,M1];
      // Check for NULL termination
      Null = r0;
   if NZ jump lp_param_copy;

    // Configure Send OMS aggresiveness
    r0 = M[&$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SND_OMS_HFK_AGGR];
#if uses_SND_NS
    r1 = M[&$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_SSR_OMS_AGGR];
    r2 = M[$M.CVC_SYS.cur_mode];
    NULL = r2 - $M.CVC_HANDSFREE_2MIC.SYSMODE.SSR;
    if NZ r1=r0;
    M[&$M.CVC.data.out0_oms270snd_obj + $M.oms270.AGRESSIVENESS_FIELD] = r1;
    M[&$M.CVC.data.out1_oms270snd_obj + $M.oms270.AGRESSIVENESS_FIELD] = r1;
#endif

#if uses_AEC
   // Configure CNG
   r1 = $M.AEC_500.CNG_G_ADJUST;
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.CNGENA;
   if Z r1 = Null;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_CNG_G_ADJUST] = r1;

   // Configure RER
   r2 = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.RERENA;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_RER_func] = r2;
#endif


   // Call Module Initialize Functions
   $push_rLink_macro;

// Configure PLC and Codecs
   r7 = &$sco_data.object;
   NULL = M[$M.BackEnd.sco_streaming];
   if NZ call $frame_sync.sco_initialize;

   r0 = M[$M.BackEnd.wbs_init_func];
   if NZ call r0;
   r4 = &$M.CVC.data.ReInitializeTable;
   call $frame_sync.run_function_table;
   // Clear Re-Initialize Flag

   // refresh from persistence
#if uses_ADF
   r1 = M[$M.2micHF.LoadPersistResp.persistent_mgdc];
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_MGDCPERSIST;
   if NZ r1 = NULL;
   M[$M.CVC.data.adf_object + $M.adf_alg_1_0_0.OFFSET_L2FBpXD] = r1;
#endif

   // USB rate match persistence
   // --------------------------

   call $block_interrupts;

   // Load the USB rate match info previously acquired from the persistence store
   r1 = M[$M.2micHF.LoadPersistResp.persistent_current_alpha_index];

   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD] = r1;

   r1 = M[$M.2micHF.LoadPersistResp.persistent_average_io_ratio];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD] = r1;

   r1 = M[$M.2micHF.LoadPersistResp.persistent_warp_value];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD] = r1;

   r1 = M[$M.2micHF.LoadPersistResp.persistent_inverse_warp_value];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD] = r1;

   r1 = M[$M.2micHF.LoadPersistResp.persistent_sra_current_rate];
   M[$far_end.in.sw_copy_op.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD] = r1;

   // Further initialisation
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.ACCUMULATOR_FIELD] = 0;

   r1 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.IDLE_PERIODS_AFTER_STALL_FIELD];
   r1 = 0 - r1;
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.COUNTER_FIELD] = r1;
   r1 = $cbops.rate_monitor_op.NO_DATA_PERIODS_FOR_STALL;
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.STALL_FIELD] = r1;
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.WARP_MSG_COUNTER_FIELD] = 0;

   call $unblock_interrupts;

   // r0 = &$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_DSP_USER_0;
   // SP.  Add any special initialization here

   jump $pop_rLink_and_rts;
.ENDMODULE;

.MODULE  $M.CVC.Zero_DC_Nyquist;
   .CODESEGMENT CVC_ZERO_DC_NYQUIST_PM;
func:
   // Zero DC/Nyquist  -
   r0 = M[$cvc_fftbins];
   r0 = r0 - 1;
   M[r7] = Null;
   M[r8] = Null;
   M[r7 + r0] = Null;
   M[r8 + r0] = Null;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.CVC.snd_agc_vad_recalc;
//
// DESCRIPTION:
//    This function takes calculates the SEND_AGC VAD based on whether we are
//    using 2 mics (two_mic_mode=0) and the RCV VAD.
//
// INPUTS:
//    -
//    -
//
// OUTPUTS:
//    -
//
// TRASHED REGISTERS:
//
//
// CPU USAGE:
//    cycles =
//    CODE memory:
//
// NOTES:
//
//
// *****************************************************************************
.MODULE $M.CVC.snd_agc_vad_recalc;
   .CODESEGMENT CVC_OMS_VAD_RECALC_PM;

func:
   $push_rLink_macro;

      push r8;
   push r7;
      r7 = $M.CVC.data.snd_vad_peq;
      r8 = 0;
      call $audio_proc.peq.process;
      r7 = $M.CVC.data.snd_vad400;
      r8 = 0;
      call $M.vad400.process.func;
   
      r2 = M[$M.CVC.data.snd_vad400 + $M.vad400.FLAG_FIELD];;
   pop r7;         
      pop r8;

   r1 = M[r8 + $M.CVC.oms_vad_recalc.PTR_VAD_VALUE_FIELD];
   r1 = M[r1];                                             // r1: VAD_AGC = AED_b.VAD;
   Null = M[r7 + $M.TWOMIC_HF_500.OFFSET_MIC_MODE];
   if Z r2 = r2 AND r1;
   
   //echo hold process
   call $M.CVC.vad_hold.process.func;                      //output in r2
   r5 = r2;

   //noise hold process
   r1 = M[r8 + $M.CVC.oms_vad_recalc.PTR_VAD_VALUE_FIELD]; //get VAD_AGC flag
   r1 = M[r1];
   r0 = 1;
   r1 = r0 - r1;
   M[&$snd_agc_vad_reverse] = r1;                          //r1 = !r1 
   r8 = &$M.CVC.data.vad_noise_hold;
   call $M.CVC.vad_hold.process.func;                      //output in r2
   
   //echo_hold && noise_hold 
   r2 = r2 AND r5;
   M[$M.CVC.data.adf_object + $M.adf_alg_1_0_0.OFFSET_PP_VAD_DETECT] = r2;

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.CVC.vad_hold.process
//
// DESCRIPTION:
//    Delay VAD transition to zero after echo or noise event. Logic:
//    if EchoFlag
//        SND.DMSS_b.AGC_Echo_hold = -SND.AGC400snd_p.AGC_Th_hang_Echo;
//    else
//        SND.DMSS_b.AGC_Echo_hold = min(SND.DMSS_b.AGC_Echo_hold + 1,0);
//    end 
//
//    or
//
//    if  ~VAD_AGC
//       SND.DMSS_b.AGC_Noise_hold = -SND.AGC400snd_p.AGC_Th_hang_Noise;
//    else
//       SND.DMSS_b.AGC_Noise_hold = min(SND.DMSS_b.AGC_Noise_hold +1,0);
//    end 
   
//    VAD_AGC =  (SND.DMSS_b.AGC_Echo_hold >= 0) && (SND.DMSS_b.AGC_Noise_hold>=0);
//
// INPUTS:
//    r8 - Pointer to the data structure
//
// OUTPUTS:
//    VAD_AGC flag

// *****************************************************************************
.MODULE $M.CVC.vad_hold.process;
   .CODESEGMENT CVC_OMS_VAD_RECALC_PM;
func:
   // update hold counter, r2=SND_VAD
   r1 = M[r8 + $M.CVC.oms_vad_recalc.PTR_EVENT_VAD_FIELD];
   r1 = M[r1];
   r0 = M[r8 + $M.CVC.oms_vad_recalc.HOLD_COUNTER_FIELD];
   r3 = M[r8 + $M.CVC.oms_vad_recalc.PTR_HOLD_TIME_FRAMES_FIELD]; 
   r3 = M[r3];    // r3 = reset value for counter
   r0 = r0 - 1;   // decrement counter
   if NEG r0 = 0; 
   Null = r1;     // test for event
   if NZ r0 = r3; // if event, reset counter
   M[r8 + $M.CVC.oms_vad_recalc.HOLD_COUNTER_FIELD] = r0; 
   if NZ r2 = Null; // dont allow VAD to activate until countdown competed
   rts;
.ENDMODULE;


.MODULE $M.CVC.CopyLeft_to_Right;
   .CODESEGMENT CVC_COPY_LEFT_TO_RIGHT_PM;
$CVC.CopyLeft_to_Right:
   // Copy Left to Right
   r10 = M[$cvc_fftbins];
   I0 = &$M.CVC.data.D_l_real;
   I4 = &$M.CVC.data.D_l_imag;
   I1 = &$M.CVC.data.D_r_real;
   I5 = &$M.CVC.data.D_r_imag;
   do copyLoop;
      r0 = M[I0,1], r1 = M[I4,1];
      M[I1,1] = r0, M[I5,1] = r1;
   copyLoop:
   rts;
.ENDMODULE;

.CONST $CVC_2MIC_PERSIST_MGDC_OFFSET                              0;
.CONST $CVC_2MIC_PERSIST_AGC_OFFSET                               1;
.CONST $CVC_2MIC_PERSIST_CURRENT_ALPHA_INDEX_OFFSET               2;
.CONST $CVC_2MIC_PERSIST_AVERAGE_IO_RATIO_HI_OFFSET               3;
.CONST $CVC_2MIC_PERSIST_AVERAGE_IO_RATIO_LO_OFFSET               4;

.CONST $CVC_2MIC_PERSIST_WARP_VALUE_HI_OFFSET                     5;
.CONST $CVC_2MIC_PERSIST_WARP_VALUE_LO_OFFSET                     6;
.CONST $CVC_2MIC_PERSIST_INVERSE_WARP_VALUE_HI_OFFSET             7;
.CONST $CVC_2MIC_PERSIST_INVERSE_WARP_VALUE_LO_OFFSET             8;

.CONST $CVC_2MIC_PERSIST_SRA_CURRENT_RATE_HI_OFFSET               9;
.CONST $CVC_2MIC_PERSIST_SRA_CURRENT_RATE_LO_OFFSET               10;

.CONST $CVC_2MIC_PERSIST_NUM_ELEMENTS                             11; // Number of persistance elements

// *****************************************************************************
// DESCRIPTION: Response to persistence load request
// r2 = length of persistence block / zero for error[?]
// r3 = address of persistence block
// *****************************************************************************
.MODULE $M.2micHF.LoadPersistResp;

   .CODESEGMENT PM;
   .DATASEGMENT DM;

   // AGC persistence
   .VAR persistent_mgdc = 0;
   .VAR persistent_agc = 0x20000;
   .VAR persistent_agc_init = 0x20000;

   // USB rate match  persistence
   .VAR persistent_current_alpha_index = 0;
   .VAR persistent_average_io_ratio = 0.0;
   .VAR persistent_warp_value = 0.0;
   .VAR persistent_inverse_warp_value = 0.0;
   .VAR persistent_sra_current_rate = 0.0;

func:

   Null = r2 - $CVC_2MIC_PERSIST_NUM_ELEMENTS;
   if NZ rts; // length must be correct

#if uses_ADF
   r0 = M[r3 + $CVC_2MIC_PERSIST_MGDC_OFFSET];
   r0 = r0 ASHIFT 8; // 16 msb, 8lsbs trucated
   M[persistent_mgdc] = r0;
#endif

#if uses_RCV_AGC
   r0 = M[r3 + $CVC_2MIC_PERSIST_AGC_OFFSET];
   r0 = r0 ASHIFT 8; // 16 msb, 8lsbs trucated
   M[persistent_agc] = r0;
   M[persistent_agc_init] = r0;
#endif

   // USB rate match persistence
   // --------------------------

   // CURRENT_ALPHA_INDEX
   r0 = M[r3 + $CVC_2MIC_PERSIST_CURRENT_ALPHA_INDEX_OFFSET];
   M[persistent_current_alpha_index] = r0;

   // AVERAGE_IO_RATIO
   r0 = M[r3 + $CVC_2MIC_PERSIST_AVERAGE_IO_RATIO_HI_OFFSET];
   r1 = M[r3 + $CVC_2MIC_PERSIST_AVERAGE_IO_RATIO_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_average_io_ratio] = r0;

   // WARP_VALUE
   r0 = M[r3 + $CVC_2MIC_PERSIST_WARP_VALUE_HI_OFFSET];
   r1 = M[r3 + $CVC_2MIC_PERSIST_WARP_VALUE_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_warp_value] = r0;

   // INVERSE_WARP_VALUE
   r0 = M[r3 + $CVC_2MIC_PERSIST_INVERSE_WARP_VALUE_HI_OFFSET];
   r1 = M[r3 + $CVC_2MIC_PERSIST_INVERSE_WARP_VALUE_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_inverse_warp_value] = r0;

   // SRA_CURRENT_RATE
   r0 = M[r3 + $CVC_2MIC_PERSIST_SRA_CURRENT_RATE_HI_OFFSET];
   r1 = M[r3 + $CVC_2MIC_PERSIST_SRA_CURRENT_RATE_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_sra_current_rate] = r0;

   // Re-Initialize System (this will result in a load of the persistent values)
   M[$M.CVC_SYS.AlgReInit] = r2;
   rts;
.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $M.pblock_send_handler
//
// DESCRIPTION:
//    This module periodically sends the persistence block to HSV5 for storage
//
//
// *****************************************************************************
.MODULE $M.pblock_send_handler;
   .CODESEGMENT PBLOCK_SEND_HANDLER_PM;
   .DATASEGMENT DM;

   .CONST $CVC_2MIC_PERSIST_STORE_MSG_SIZE         ($CVC_2MIC_PERSIST_NUM_ELEMENTS + 1); // Need 1 extra for the SysID
   // SysID(1), MGDC(1), AGC(1), Alpha index(1), IO ratio(2), USB warp value(2), USB inverse warp value(2), sra current rate(2)

   // Pblock re-send timer data structure
   .VAR $pblock_send_timer_struc[$timer.STRUC_SIZE];

   // Persistence message data
   .VAR persist_data_2mic[$CVC_2MIC_PERSIST_STORE_MSG_SIZE];            // Need 1 extra for the SysID

$pblock_send_handler:

   $push_rLink_macro;

   r0 = M[$pblock_key];
   M[&persist_data_2mic] = r0;

#if uses_ADF
   r0 = M[$M.CVC.data.adf_object + $M.adf_alg_1_0_0.OFFSET_L2FBpXD];
   M[$M.2micHF.LoadPersistResp.persistent_mgdc] = r0;
   r0 = M[$M.2micHF.LoadPersistResp.persistent_mgdc];
   r0 = r0 ASHIFT -8;                                                   // to 16-bit, truncate 8 lsbs
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_MGDC_OFFSET] = r0;
#endif

#if uses_RCV_AGC
   r0 = M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD];
   M[$M.2micHF.LoadPersistResp.persistent_agc] = r0;
   r0 =  M[$M.2micHF.LoadPersistResp.persistent_agc];
   r0 = r0 ASHIFT -8;                                                   // to 16-bit, truncate 8 lsbs
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_AGC_OFFSET] = r0;
#endif

   // USB rate match persistence
   // --------------------------

   // CURRENT_ALPHA_INDEX
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD];
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_CURRENT_ALPHA_INDEX_OFFSET] = r0;

   // AVERAGE_IO_RATIO
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_AVERAGE_IO_RATIO_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_2mic  + 1 + $CVC_2MIC_PERSIST_AVERAGE_IO_RATIO_LO_OFFSET] = r1;

   // WARP_VALUE_FIELD
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_WARP_VALUE_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_WARP_VALUE_LO_OFFSET] = r1;

   // INVERSE_WARP_VALUE_FIELD
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_INVERSE_WARP_VALUE_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_INVERSE_WARP_VALUE_LO_OFFSET] = r1;

   // SRA_CURRENT_RATE
   r0 = M[$far_end.in.sw_copy_op.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_SRA_CURRENT_RATE_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_SRA_CURRENT_RATE_LO_OFFSET] = r1;
   r3 = $M.CVC.VMMSG.STOREPERSIST;
   r4 = $CVC_2MIC_PERSIST_STORE_MSG_SIZE;
   r5 = &persist_data_2mic;
   call $message.send_long;

   // post another timer event
   r1 = &$pblock_send_timer_struc;
   r2 = $TIMER_PERIOD_PBLOCK_SEND_MICROS;
   r3 = &$pblock_send_handler;
   call $timer.schedule_event_in_period;

   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
//
// MODULE:
//    $M.set_mode_gains.func
//
// DESCRIPTION:
//    Sets input gains (ADC and SCO) based on the current mode.
//    (Note: this function should only be called from within standy,
//    loopback, and pass-through modes).
//
//    MODE              ADC GAIN        SCO GAIN
//    pass-through      user specified  unity
//    standby           zero            zero
//    loopback          unity           unity
//
//
// INPUTS:
//    r7 - Pointer to the data structure
//
//   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT       0;
//   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT      1;
//   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_EXP             2;
//   .CONST   $M.SET_MODE_GAIN.SCO_GAIN_MANT             3;
//   .CONST   $M.SET_MODE_GAIN.SCO_GAIN_EXP              4;
//   .CONST   $M.SET_MODE_GAIN.STRUC_SIZE                5;
//
// *****************************************************************************

.MODULE $M.set_mode_gains;
    .CODESEGMENT SET_MODE_GAIN_PM;

$cvc_Set_LoopBackGains:

   r9 = M[$M.ConfigureSystem.Variant];
   r1 = &$M.CVC.data.stream_map_sndout;
   // Gain --> so
   M[&$M.CVC.data.passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR]=r1;
   // Mixer --> ro/ri
   r2 = &$M.CVC.data.stream_map_rcvin;
   r3 = &$M.CVC.data.stream_map_rcvout;
   Null = r9 - $M.CVC.BANDWIDTH.FE;
   if Z r3=r2;
   M[&$M.CVC.data.adc_mixer + $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR]=r3;

   // Unity (0 db)
   r0 = 0.5;
   r1 = 1;
   r2 = r0;
   r3 = r1;
   r5 = NULL;
   jump setgains;

$cvc_Set_PassThroughGains:
   r9 = M[$M.ConfigureSystem.Variant];

   r1 = &$M.CVC.data.stream_map_sndout;
   // Mixer --> so
   M[&$M.CVC.data.adc_mixer + $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR]=r1;
   // Gain --> ro/ri
   r2 = &$M.CVC.data.stream_map_rcvin;
   r3 = &$M.CVC.data.stream_map_rcvout;
   Null = r9 - $M.CVC.BANDWIDTH.FE;
   if Z r3=r2;
   M[&$M.CVC.data.passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR]=r3;


   r0 = M[$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA];
   r5 = r0;

   r4 = M[$M.CVC_SYS.cur_mode];
   NULL = r4 - $M.CVC_HANDSFREE_2MIC.SYSMODE.PSTHRGH_LEFT;
   if Z r5 = NULL;
   if Z jump passthroughgains;
   NULL = r4 - $M.CVC_HANDSFREE_2MIC.SYSMODE.PSTHRGH_RIGHT;
   if Z r0 = NULL;
   if Z jump passthroughgains;

   // Standby - Zero Signal
   r5 = NULL;
   r0 = NULL;
   r2 = NULL;
   r1 = 1;
   r3 = r1;
   jump setgains;
passthroughgains:
   // PassThrough Gains set from Parameters
   r1 = M[$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT];
   r2 = M[$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PT_RCVGAIN_MANTISSA];
   r3 = M[$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_PT_RCVGAIN_EXPONENT];
setgains:
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT]    = r0;
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT]   = r5;
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_EXP]          = r1;
   M[r7 + $M.SET_MODE_GAIN.SCO_GAIN_MANT] = r2;
   M[r7 + $M.SET_MODE_GAIN.SCO_GAIN_EXP]  = r3;
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.cvc.rcv_peq
//
// DESCRIPTION:
//    CVC receive PEQ process depending on WB/NB setting
//
// *****************************************************************************
.MODULE $M.cvc.rcv_peq;
   .CODESEGMENT CVC_BANDWIDTH_PM;
   .DATASEGMENT DM;

$cvc.rcv_peq.process_wb:
   r0 = M[$M.ConfigureSystem.Variant];
   Null = r0 - $M.CVC.BANDWIDTH.WB;
   if NZ rts;
   jump $audio_proc.peq.process;

$cvc.rcv_peq.process:
   r0 = M[$M.ConfigureSystem.Variant];
   Null = r0 - $M.CVC.BANDWIDTH.WB;
   if Z rts;
   jump $audio_proc.peq.process;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.cvc.fe_utility
//
// DESCRIPTION:
//    FE/BEX utility functions
//
// *****************************************************************************
.MODULE $M.cvc.fe_utility;
   .CODESEGMENT CVC_BANDWIDTH_PM;
   .DATASEGMENT DM;


$cvc.fe.frame_resample_process:
   r0 = M[$fe_frame_resample_process];
   if NZ jump r0;
   rts;

$cvc.non_fe.Zero_DC_Nyquist:
   r0 = M[$M.ConfigureSystem.Variant];
   Null = r0 - $M.CVC.BANDWIDTH.FE;
   if Z rts;
   jump $M.CVC.Zero_DC_Nyquist.func;

.ENDMODULE;

.MODULE  $M.cvc.twoMicHF_control;
   .CODESEGMENT PM;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
adf_postProc:
   push rlink;

   r0 = $M.CVC.data.twomic_hf_500_obj;
   push r0;
   pop FP;

   r8 = &$M.CVC.data.adf_object;
   push r8;
   r0 = M[r8 + $M.adf_alg_1_0_0.OFFSET_PTR_V1_real];
   I1 = r0;
   r0 = M[r8 + $M.adf_alg_1_0_0.OFFSET_PTR_V1_imag];
   I4 = r0;
   r0 = M[FP + $M.TWOMIC_HF_500.OFFSET_PTR_DM1data];
   I3 = r0 + $M.TWOMIC_HF_500.DM1.Phase_E1;
   I2 = M[FP + $M.TWOMIC_HF_500.OFFSET_X1_REAL_PTR];
   I5 = M[FP + $M.TWOMIC_HF_500.OFFSET_X1_IMAG_PTR];

   r10 = $M.adf_alg_1_0_0.ADF_num_proc;
   call $M.2Mic_hf_500.restorePhaseAndCopy;

   pop FP;
   call $adf.no_postp;
   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.mgdc.process:
    $push_rLink_macro;
// %% MGDC

   push r7;
   pop FP;

   Null = M[FP + $M.TWOMIC_HF_500.OFFSET_MGDC_CTRL];
   if Z jump no_mgdc;

   // Copy Mic 1 data (d1 and Exp1) before MGDC is called and modifies them.
   r10 = M[$cvc_fftbins];
   I0 = &$M.CVC.data.D_r_real;
   I4 = &$M.CVC.data.D_r_imag;
   I1 = &$M.CVC.data.fft_real;
   I5 = &$M.CVC.data.fft_imag;
   do copyLoop;
      r0 = M[I0,1], r1 = M[I4,1];
      M[I1,1] = r0, M[I5,1] = r1;
   copyLoop:

// Before calling the MGDC function, the pointer G_Oms
// need to be changed, because the ADF bypasses the OMS, while MGDC uses the input OMS.
   r8 = $M.CVC.data.adf_object;
   r0 = r8 + $M.adf_alg_1_0_0.OFFSET_OMS_G_PTR;
   r1 = M[FP + $M.TWOMIC_HF_500.OFFSET_OMS_IN_PTR];
   M[r0] = r1;

   // Call MGDC;
   push FP;
   push r8;
   r7 = $M.CVC.data.adf_object;
   call $adf.mgdc;
   pop r8;
   pop FP;

   // if (MGDC_b.hold_adapt)
   r0 = M[r8 + $M.adf_alg_1_0_0.OFFSET_MGDC_hold_adapt];
   if Z jump twoMicMode;
   oneMicMode:
      // S.MIC_mode = 1;            % One Mic Mode
      r1 = 1;
      M[FP + $M.TWOMIC_HF_500.OFFSET_MIC_MODE] = r1;
      M[$M.CVC.data.aec2Mic_dm1 + $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1] = r1;

      // if MGDC_b.switch_output    % Switch from Mic 0 to Mic 1
      r0 = M[r8 + $M.adf_alg_1_0_0.OFFSET_MGDC_switch_output];
      if Z jump endMicMode;
         //swap D0,D1,BExp_D0,BExp_D1;
         // Original D1 is stored in fft_real, so it needs to be restored.
         r0 = M[FP + $M.TWOMIC_HF_500.OFFSET_BEXP_X0_PTR];
         r2 = M[r0];
         r1 = M[FP + $M.TWOMIC_HF_500.OFFSET_BEXP_X1_PTR];
         r3 = M[r1];
         M[r1] = r2;
         M[r0] = r3;

         I0 = M[FP + $M.TWOMIC_HF_500.OFFSET_X0_REAL_PTR];
         I4 = M[FP + $M.TWOMIC_HF_500.OFFSET_X0_IMAG_PTR];
         I1 = M[FP + $M.TWOMIC_HF_500.OFFSET_X1_REAL_PTR];
         I5 = M[FP + $M.TWOMIC_HF_500.OFFSET_X1_IMAG_PTR];

         I2 = &$M.CVC.data.fft_real;
         I6 = &$M.CVC.data.fft_imag;
         r10 = M[$cvc_fftbins];
         do swapChannels;
            r0 = M[I0,0], r1 = M[I4,0];   // Read from MIC0
            r2 = M[I2,1], r3 = M[I6,1];   // Read from temp (original Mic1)
            M[I0,1] = r2, M[I4,1] = r3;   // Write over Mic0
            M[I1,1] = r0, M[I5,1] = r1;   // Write over Mic1
         swapChannels:
      // end
      jump endMicMode;
   // else
   twoMicMode:
      // S.MIC_mode = 0;            % Two Mic Mode
      M[FP + $M.TWOMIC_HF_500.OFFSET_MIC_MODE] = Null;
      M[$M.CVC.data.aec2Mic_dm1 + $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1] = Null;

      // D1 = D1_tmp;
      // BExp_D1 = BExp_D1_tmp;
      // D1 already contains the correct value
   // end
   endMicMode:
   no_mgdc:

   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.aec.process:

   push rLink;

   push r7;
   pop FP;

   push FP;
   // wmsn: only executed when FE/BEX
   r7 = &$M.CVC.data.ref_downsample_dm1;
   call $cvc.fe.frame_resample_process;
   r7 = &$M.CVC.data.fft_obj;
   r8 = &$M.CVC.data.AecAnalysisBank;
   call $filter_bank.one_channel.analysis.process; // ref --> [D_rcv_real,D_rcv_imag]
   pop FP;

   // Check if AEC has been enabled globally
   r7 = $M.CVC.data.aec_dm1;
   r0 = M[r7 + $M.AEC_500.OFFSET_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.AECENA;
   if Z jump no_aec;
   // %% Two Mic AEC
      r7 = &$M.CVC.data.aec2Mic_dm1;
      call $M.2Mic_aec.func;
   aec_done:
   no_aec:

   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.NLP.process:
   push rLink;

   push r7;
   pop FP;

   // Check if AEC has been enabled globally
   r7 = $M.CVC.data.aec_dm1;
   r0 = M[r7 + $M.AEC_500.OFFSET_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.AECENA;
   if Z jump no_aec2;

   // Copy buffer to output of AEC.
   r10 = M[$cvc_fftbins];
   I0 = &$M.CVC.data.D_l_real;
   I4 = &$M.CVC.data.D_l_imag;
   I1 = &$M.CVC.data.fft_real;
   I5 = &$M.CVC.data.fft_imag;

   do copyLoop1;
      r0 = M[I0,1], r1 = M[I4,1];
      M[I1,1] = r0, M[I5,1] = r1;
   copyLoop1:
   // half-duplex function
   r7 = &$M.CVC.data.vsm_fdnlp_dm1;
   r8 = &$M.CVC.data.aec_dm1;
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HANDSFREE_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.HDBYP;
   if Z call $AEC_500.NonLinearProcess;

   r7 = &$M.CVC.data.aec_dm1;
   call $M.AEC_500.comfort_noise_generator.func;

   // Copy output of AEC to input of Synthesis filter.
   r10 = M[$cvc_fftbins];
   I0 = &$M.CVC.data.fft_real;
   I4 = &$M.CVC.data.fft_imag;
   I1 = &$M.CVC.data.D_l_real;
   I5 = &$M.CVC.data.D_l_imag;

   do copyLoop2;
      r0 = M[I0,1], r1 = M[I4,1];
      M[I1,1] = r0, M[I5,1] = r1;
   copyLoop2:

   aec_done2:
   no_aec2:
   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.ADF.process:
   push rLink;

   push r7;
   pop FP;

// %% Adaptive Decorrelation Filter
// Before calling the ADF function, the pointer to G_Oms
// need to be changed. Set G_oms to NULL pointer to bypass

   r8 = $M.CVC.data.adf_object;
   r0 = r8 + $M.adf_alg_1_0_0.OFFSET_OMS_G_PTR;
   M[r0] = Null;

   // Check if ADF has been enabled globally
   r0 = M[FP + $M.TWOMIC_HF_500.OFFSET_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_ADF;
   if NZ jump no_adf;

   r7 = $M.CVC.data.adf_object;
   push FP;
   call $M.adf_alg_1_0_0.Process.func;
   pop FP;
   
   Null = M[FP + $M.TWOMIC_HF_500.OFFSET_MIC_MODE];
   if NZ jump no_adf;

   // Restore phase for bins [1 (1),$M.adf_alg_1_0_0.ADF_num_proc (55)]
   r8 = $M.CVC.data.adf_object;
   r0 = M[r8 + $M.adf_alg_1_0_0.OFFSET_PTR_V0_real];
   I1 = r0;
   r0 = M[r8 + $M.adf_alg_1_0_0.OFFSET_PTR_V0_imag];
   I4 = r0;
   r0 = M[FP + $M.TWOMIC_HF_500.OFFSET_PTR_DM1data];
   I3 = r0 + $M.TWOMIC_HF_500.DM1.Phase_E0;
   I2 = M[FP + $M.TWOMIC_HF_500.OFFSET_X0_REAL_PTR];
   I5 = M[FP + $M.TWOMIC_HF_500.OFFSET_X0_IMAG_PTR];

   r10 = $M.adf_alg_1_0_0.ADF_num_proc;
   call $M.2Mic_hf_500.restorePhaseAndCopy;

// if S.Beam_on
//    TMP_L_PostP_ctrl(ADF_p.ADF_idx_proc) = TMP_L_PostP_ctrl(ADF_p.ADF_idx_proc) + ADF_b.L_PostP_ctrl;
// else
//    TMP_L_PostP_ctrl(ADF_p.ADF_idx_proc) = ADF_b.L_PostP_ctrl;
// end

   r7 = FP;
   r8 = $M.CVC.data.ADF_L_PostP_ctrl;
   call $M.2Mic_hf_500.TMP_L_PostP_ctrl.calc;

no_adf:
   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.beamformpost.process:
   push rLink;
   // r7 has main object (2mic_hf_object)
   // if S.Beam_on && (S.MIC_mode == 0)
   // Check if BF has been enabled globally
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.BYPASS_BF;
   if NZ jump no_bfpp;
   // Check if MIC_mode == 0
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_MIC_MODE];
   if NZ jump no_bfpp;
      call $M.beamformpost.func;
   no_bfpp:
   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.OMS.process:
   push rlink;
   // Save r7 = twomic object
   push r7;

   r7 = $M.CVC.data.out0_oms270snd_obj;
   r8 = 0;
   call $M.oms270.process.func;

   pop r7;
   // if S.MIC_mode == 0
      // Execute OMS
   // Check if MIC_mode == 0
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_MIC_MODE];
   if NZ jump no_OMS1;

   r7 = $M.CVC.data.out1_oms270snd_obj;
   r8 = 0;
   call $M.oms270.process.func;

   no_OMS1:
   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.AEC.init:
   push rLink;
   // r7 has main object (2mic_hf_object)

   // Populate pointers to input data for AEC0
   r8 = $M.CVC.data.aec_dm1;
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_X0_REAL_PTR];
   M[r8 + $M.AEC_500.OFFSET_D_REAL_PTR] = r0;
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_X0_IMAG_PTR];
   M[r8 + $M.AEC_500.OFFSET_D_IMAG_PTR] = r0;
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_BEXP_X0_PTR];
   M[r8 + $M.AEC_500.OFFSET_D_EXP_PTR] = r0;

   // Initialize AEC0
   push r7;
   r8 = $M.CVC.data.aec_dm1;
   r7 = $M.CVC.data.vsm_fdnlp_dm1;
   call $M.AEC_500.Initialize.func;
   pop r7;

   // Populate pointers to input data for AEC1
   r8 = $M.CVC.data.aec2Mic_dm1;
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_X1_REAL_PTR];
   M[r8 + $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR] = r0;
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_X1_IMAG_PTR];
   M[r8 + $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR] = r0;
   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_BEXP_X1_PTR];
   M[r8 + $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR] = r0;

   // Initialize AEC1
   push r7;
   r8 = $M.CVC.data.aec2Mic_dm1;
   r7 = 0;
   call $M.AEC_500.InitializeAEC1.func;
   pop r7;

//wz This shouldn't be here (needs to be added to the library),
//   but I need a place to put it temporarily.
   r10 = $M.oms270.FFT_NUM_BIN;
   I0 = $M.CVC.data.in_oms_G;
   r0 = 1.0;
   do initOMS;
      M[I0,1] = r0;
   initOMS:
   jump $pop_rLink_and_rts;



// *****************************************************************************
// MODULE:
//    $
//
// DESCRIPTION:
//
//
// *****************************************************************************
$twoMicHF.swapMics.process:
   push rLink;
   // r7 has main object (2mic_hf_object)
   // r8 has $M.CVC.data.MicAnalysisBank;
   r1 = $M.CVC.data.stream_map_left_adc;
   r2 = $M.CVC.data.stream_map_right_adc;

   r0 = M[r7 + $M.TWOMIC_HF_500.OFFSET_CONFIG];
   Null = r0 AND $M.CVC_HANDSFREE_2MIC.CONFIG.DRIVER_LEFT_FLAG;
   if Z jump driverLeftSide;
   driverRightSide:
      M[r8 + $M.filter_bank.Parameters.OFFSET_CH1_PTR_FRAME] = r2;
      M[r8 + $M.filter_bank.Parameters.OFFSET_CH2_PTR_FRAME] = r1;
   jump endSwap;
   driverLeftSide:
      M[r8 + $M.filter_bank.Parameters.OFFSET_CH1_PTR_FRAME] = r1;
      M[r8 + $M.filter_bank.Parameters.OFFSET_CH2_PTR_FRAME] = r2;
   endSwap:

   jump $pop_rLink_and_rts;

.ENDMODULE;

//******************************************************************************
// MODULE:
//    $M.agc400.persist_gain_load
//
// DESCRIPTION:
// Load the persisted gain into the appropriate field in the AGC data object
//
// INPUTS:
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//    
//
// CPU USAGE:
//
// Notes
//******************************************************************************
.MODULE $M.agc400.persist_gain_load;

   .CODESEGMENT PM;

$agc400.persist_gain_load:

   push rLink;

   // refresh from persistence
   r1 = M[$M.2micHF.LoadPersistResp.persistent_agc_init];
   M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_PERSISTED_GAIN_FIELD] = r1;

   jump $pop_rLink_and_rts;

.ENDMODULE;

