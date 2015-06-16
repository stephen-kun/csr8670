// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
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
#include "cvc_headset_2mic.h"
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


// Generate build error messages if necessary.

#if !uses_NSVOLUME && uses_VCAEC
   .error "VCAEC cannot be enabled without NDVC"
#endif

#if !uses_AEQ && uses_RCV_NS
   .warning "RCV_NS cannot be enabled without AEQ in BEX mode"
#endif

#if !uses_SND_NS
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
      .VAR  CompConfig = CVC_HEADSET_2MIC_CONFIG_FLAG;
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

   // These lines write module and version information to the kap file.
   .VAR kap_version_stamp = &$M.CVC_VERSION_STAMP.VersionStamp;
   .VAR kap_modules_stamp = &$M.CVC_MODULES_STAMP.ModulesStamp;


   // Default Block
   .VAR/DMCONST16  DefaultParameters_wb[] =
        #include "cvc_headset_2mic_defaults_WB.dat"
   ;
   .VAR/DMCONST16  DefaultParameters_fe[] =
        #include "cvc_headset_2mic_defaults_FE.dat"
   ;
   .VAR/DMCONST16  DefaultParameters_nb[] =
        #include "cvc_headset_2mic_defaults_NB.dat"
   ;

   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.CVC_HEADSET_2MIC.PARAMETERS.STRUCT_SIZE)];

//  ******************  Define circular Buffers ************************

 .VAR/DM1     ref_delay_buffer[Max_RefDelay_Sample];
 .VAR/DM2     fft_circ[FFT_BUFFER_SIZE];

    #if uses_IN0_OMS
   .VAR/DM1 in0oms_LpX_queue[$M.oms270.QUE_LENGTH];
    #endif

    #if uses_RCV_NS
   .VAR/DM1 rcvLpX_queue[$M.oms270.QUE_LENGTH];
    #endif


//  ******************  Define Scratch/Shared Memory ************************

    // Frequency Domain Shared working buffers
    .BLOCK/DM1   FFT_DM1;
      .VAR  X_real[$M.CVC.Num_FFT_Freq_Bins];
      // D_l_real also be higher bins of X_real for BEX (FE)
      .VAR  D_l_real[$M.CVC.Num_FFT_Freq_Bins];
      .VAR  D_r_real[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2 FFT_DM2;
      .VAR  X_imag[$M.CVC.Num_FFT_Freq_Bins];
      // D_l_imag also be higher bins of X_imag for BEX (FE)
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
         .VAR  Attenuation_not_used[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  L_adaptA[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  L_adaptR[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  scratch_extra_dm1[$asf100.SCRATCH_SIZE_DM1 - ( 5*$M.CVC.Num_FFT_Freq_Bins+1 )];
   .ENDBLOCK;

   // The Attenuation buffer needed to be pulled out of scratch memory,
   // since the data needed by the CNG was being corrupted by other modules.
   .VAR  AttenuationPersist[$M.CVC.Num_FFT_Freq_Bins];

   .BLOCK/DM2  $M.dm2_scratch;
         // real,imag interlaced
         .VAR  Exp_Mts_adapt[2*$M.CVC.Num_FFT_Freq_Bins + 1];
         .VAR  scratch_extra_dm2[$asf100.SCRATCH_SIZE_DM2 - ( 2*$M.CVC.Num_FFT_Freq_Bins + 1 )];
   .ENDBLOCK;


// Scratch memory sharing, making sure that the actual size of the memory is enough for each module
#define oms_scratch              $M.dm1_scratch
#define dms_scratch              $M.dm1_scratch

#define adf200_scratch_dm1       $M.dm1_scratch
#define adf200_scratch_dm2       $M.dm2_scratch

#define asf100_scratch_dm1       $M.dm1_scratch
#define asf100_scratch_dm2       $M.dm2_scratch

#define aeq_scratch              $M.dm1_scratch
#define vad_scratch              $M.dm1_scratch

#define fft_real_scratch         $M.dm1_scratch
#define fft_imag_scratch         $M.dm2_scratch
#define fft_circ_scratch         fft_circ

#define E_real                   X_real
#define E_imag                   X_imag
#define E                        aec_dm1 + $M.AEC_500.OFFSET_E_REAL_PTR



   // FFT data object, common to all filter_bank cases
   // The three buffers in this object are temporary to FFT and could be shared
   .VAR fft_obj[$M.filter_bank.fft.STRUC_SIZE] =
      0,
      &fft_real_scratch,
      &fft_imag_scratch,
      &fft_circ_scratch,
      BITREVERSE(&fft_circ_scratch),
      $filter_bank.config.fftsplit_table, // PTR_FFTSPLIT
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

#if uses_SND_VAD || uses_RCV_VAD
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
.CONST $RCV_HARMONICITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
#else
.CONST $RCV_HARMONICITY_HISTORY_EXTENSION  0;
#endif

#if uses_RCV_FREQPROC

    // Analysis Filter Bank Config Block
   .VAR/DM1  bufd_rcv_inp[$M.CVC.Num_FFT_Window+ $RCV_HARMONICITY_HISTORY_EXTENSION];

   .VAR/DM1 RcvAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_RCVIN,           // OFFSET_CONFIG_OBJECT
      &stream_map_rcvin,               // OFFSET_PTR_FRAME
      &bufd_rcv_inp+$RCV_HARMONICITY_HISTORY_EXTENSION,          // OFFSET_PTR_HISTORY
      0,                               // OFFSET_BEXP
      &X_real,                         // OFFSET_PTR_FFTREAL
      &X_imag,                         // OFFSET_PTR_FFTIMAG
      0 ...;                           // No Channel Delay

   .VAR/DM1  bufdr_outp[$M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY];

    // Syntheseis Filter Bank Config Block
   .VAR/DM2 RcvSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_RCVOUT,          // OFFSET_CONFIG_OBJECT
      &stream_map_rcvout,              // OFFSET_PTR_FRAME
      &bufdr_outp,                     // OFFSET_PTR_HISTORY
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,
      &X_real,                         // OFFSET_PTR_FFTREAL
      &X_imag,                         // OFFSET_PTR_FFTIMAG
      0 ...;
#endif

#if uses_RCV_NS
   // <start> of memory declared per instance of oms270
   .VAR/DM1 rcvoms_G[$M.oms270.FFT_NUM_BIN];
   .VAR rcvoms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR rcvoms_state[$M.oms270.STATE_LENGTH];

   .VAR oms270rcv_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,  //$M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HEADSET_2MIC.CONFIG.RCVOMSENA,
                                // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                      // $M.oms270.HARM_ON_FIELD
        1,                      // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_rcv_inp, 			// $M.oms270.PTR_INP_X_FIELD
        &X_real,            // $M.oms270.PTR_X_REAL_FIELD
        &X_imag,            // $M.oms270.PTR_X_IMAG_FIELD
        &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,
                                // $M.oms270.PTR_BEXP_X_FIELD
        &X_real,            // $M.oms270.PTR_Y_REAL_FIELD
        &X_imag,            // $M.oms270.PTR_Y_IMAG_FIELD
        0xD00000,               // $M.oms270.INITIAL_POWER_FIELD
        &rcvLpX_queue,          // $M.oms270.LPX_QUEUE_START_FIELD
        &rcvoms_G,                 // $M.oms270.G_FIELD;
        &rcvoms_LpXnz,             // $M.oms270.LPXNZ_FIELD,
        &rcvoms_state,             // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,       // $M.oms270.ALFANZ_FIELD  SP.  CHanged due to frame size
        0xFF13DE,               // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,               // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size
        0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        0.9,                    // $M.oms270.AGRESSIVENESS_FIELD
#if uses_AEQ                    // $M.oms270.PTR_TONE_FLAG_FIELD
        &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TEST_FIELD,
#else
        0,
#endif
         oms270rcv_obj + $M.oms270.PTR_Y_REAL_FIELD,  // Y_FIELD
         oms270rcv_obj + $M.oms270.PTR_X_REAL_FIELD,  // X_FIELD
         0,                      // D_FIELD
         &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_RCV_OMS_HFK_AGGR, // PARAM_FIELD
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
      &stream_map_rcvout,             // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_rcvout,             // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,             // MAX_STAGES_FIELD
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_RCV_PEQ_CONFIG,  // PARAM_PTR_FIELD
      0 ...;
#endif

   // Pre RCV AGC gain stage
   .VAR/DM1 rcvout_gain_dm2[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_rcvout,                       // OFFSET_INPUT_PTR
      &stream_map_rcvout,                       // OFFSET_OUTPUT_PTR
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_RCVGAIN_MANTISSA, // OFFSET_PTR_MANTISSA
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_RCVGAIN_EXPONENT; // OFFSET_PTR_EXPONENT

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
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC, // Parameter Ptr
      0 ...;

#endif


#if uses_RCV_AGC
   // RCV AGC
   .VAR/DM rcv_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      0,                   //OFFSET_BYPASS_BIT_MASK_FIELD
      $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_AGCPERSIST,   // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_RCV_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
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
      $M.CVC_HEADSET_2MIC.CONFIG.AEQENA,        // BYPASS_BIT_MASK_FIELD
      $M.CVC_HEADSET_2MIC.CONFIG.BEXENA,                                        // BEX_BIT_MASK_FIELD
      $M.CVC.Num_FFT_Freq_Bins,                 // NUM_FREQ_BINS
      0x000000,                                 // BEX_NOISE_LVL_DISABLE
      &X_real,                                  // PTR_X_REAL_FIELD             2
      &X_imag,                                  // PTR_X_IMAG_FIELD             3
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,   // PTR_BEXP_X_FIELD             4
      &X_real,                                  // PTR_Z_REAL_FIELD             5
      &X_imag,                                  // PTR_Z_IMAG_FIELD             6
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
      &rcv_vad400 + $M.vad400.FLAG_FIELD,   // VAD_AGC_FIELD                18
      0.001873243285618,                        // ALFA_A_FIELD                 19
      1.0-0.001873243285618,                    // ONE_MINUS_ALFA_A_FIELD       20
      0.001873243285618,                        // ALFA_D_FIELD                 21
      1.0-0.001873243285618,                    // ONE_MINUS_ALFA_D_FIELD       22
      0.036805582279178,                        // ALFA_ENV_FIELD               23
      1.0-0.036805582279178,                    // ONE_MINUS_ALFA_ENV_FIELD     24
      &aeq_band_pX,                             // PTR_AEQ_BAND_PX_FIELD        25
      0,                                        // STATE_FIELD                  26
#if uses_NSVOLUME
      &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL,    // PTR_VOL_STEP_UP_FIELD        27
#else
      &$M.CVC.data.ZeroValue,
#endif
      1,                                        // VOL_STEP_UP_TH1_FIELD        28
      2,                                        // VOL_STEP_UP_TH2_FIELD        29
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LO_GOAL_LOW,    // PTR_GOAL_LOW_FIELD           30
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_HI_GOAL_LOW,    // PTR_GOAL_HIGH_FIELD          31
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BEX_TOTAL_ATT_LOW,  // PTR_BEX_ATT_TOTAL_FIELD      32 wmsn: not used in WB
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BEX_HI2_GOAL_LOW,   // PTR_BEX_GOAL_HIGH2_FIELD     33 wmsn: not used in WB
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
         &BExp_D0,                                                // SCALE_FACTOR_OFFSET
         &dms100_obj + $dms100.VAD_VOICED_FIELD,                 // VOICED_OFFSET
         &G_dmsZ,                                              // GAIN_OFFSET
         &dms100_obj + $M.oms270.LIKE_MEAN_FIELD,              // LIKE_MEAN_OFFSET
         &LpXnz_dms;                                           // LPX_NZ_OFFSET
         
   .VAR/DM1 ssr_muted=$M.CVC_HEADSET_2MIC.CALLST.MUTE;

   .VAR/DM1 mute_ssr_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,               // OFFSET_INPUT_PTR
      &ssr_muted,                       // OFFSET_PTR_STATE
      $M.CVC_HEADSET_2MIC.CALLST.MUTE;  // OFFSET_MUTE_VAL
      
#endif

// SP.  OMS requires 3 frames for harmonicity (window is only 2 frame)
#if uses_SND_NS
.CONST $SND_HARMONICITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
#else
.CONST $SND_HARMONICITY_HISTORY_EXTENSION  0;
#endif

 .VAR/DM2  bufd_l_inp[$M.CVC.Num_FFT_Window + $SND_HARMONICITY_HISTORY_EXTENSION];
 .VAR/DM2  bufd_r_inp[$M.CVC.Num_FFT_Window];

#if !defined(uses_FBADM)
   // Filter Bank Analysis Left Channel
  .VAR fba_left[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_left_adc,            // OFFSET_PTR_FRAME
      &bufd_l_inp + $SND_HARMONICITY_HISTORY_EXTENSION,  // OFFSET_PTR_HISTORY
      0,                               // OFFSET_BEXP
      &D_l_real,                       // OFFSET_PTR_FFTREAL
      &D_l_imag,                       // OFFSET_PTR_FFTIMAG
      0 ...;

   // Filter Bank Analysis Right Channel
  .VAR fba_right[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_right_adc,           // OFFSET_PTR_FRAME
      &bufd_r_inp,                     // OFFSET_PTR_HISTORY
      0,                               // OFFSET_BEXP
      &D_r_real,                       // OFFSET_PTR_FFTREAL
      &D_r_imag,                       // OFFSET_PTR_FFTIMAG
      0 ...;
#else
  .VAR fba_dm[$M.filter_bank.Parameters.TWO_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,                             // OFFSET_CONFIG_OBJECT
      &stream_map_left_adc,                            // CH1_PTR_FRAME
      &stream_map_right_adc,                           // CH2_PTR_FRAME
      &bufd_l_inp + $SND_HARMONICITY_HISTORY_EXTENSION, // OFFSET_CH1_PTR_HISTORY
      &bufd_r_inp,                     // OFFSET_CH2_PTR_HISTORY
      0,                               // CH1_BEXP
      0,                               // CH2_BEXP
      &D_l_real,                                // CH1_PTR_FFTREAL
      &D_l_imag,                                // CH1_PTR_FFTIMAG
      &D_r_real,                                // CH2_PTR_FFTREAL
      &D_r_imag,                                // CH2_PTR_FFTIMAG
      0 ...;
#endif

   // SP.  Analysis for AEC Reference
   .VAR/DM2  bufd_aec_inp[$M.CVC.Num_FFT_Window];

   .VAR/DM1 AecAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_refin,               // CH1_PTR_FRAME
      &bufd_aec_inp,                   // OFFSET_PTR_HISTORY
      0,                               // OFFSET_BEXP
      &X_real,                         // OFFSET_PTR_FFTREAL
      &X_imag,                         // OFFSET_PTR_FFTIMAG
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_REF_DELAY,  //OFFSET_DELAY_PTR
      &ref_delay_buffer,               // OFFSET_DELAY_BUF_BASE
      &ref_delay_buffer,               // OFFSET_DELAY_BUF_PTR
      LENGTH(ref_delay_buffer);        // OFFSET_DELAY_BUF_LEN

   // Syntheseis Filter Bank Config Block
   .VAR  bufd_outp[($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame)];

   .VAR/DM2 SndSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,                      // OFFSET_CONFIG_OBJECT
      &stream_map_sndout,                       // OFFSET_PTR_FRAME
      &bufd_outp,                               // OFFSET_PTR_HISTORY
      &BExp_D0,                                 // OFFSET_PTR_BEXP
      &E_real,                                  // OFFSET_PTR_FFTREAL
      &E_imag,                                  // OFFSET_PTR_FFTIMAG
      0 ...;

      .VAR D0[] = &D_l_real,  // D0 real
                  &D_l_imag,  // D0 image
                  &BExp_D0;   // BExp_D0

      .VAR D1[] = &D_r_real,  // D1 real
                  &D_r_imag,  // D1 image
                  &BExp_D1;   // BExp_D1

      .VAR dmss_obj[$dmss.STRUC_SIZE] =
               &D0,                       // X0_FIELD
               &D1,                       // X1_FIELD
               0 ...;

#if uses_MGDC
      .VAR mgdc100_obj[$mgdc100.STRUC_SIZE] =
               &D0,                       // X0_FIELD
               &D1,                       // X1_FIELD
               &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_MGDC_MAXCOMP,   // PARAM_FIELD
               &$cvc_fftbins,             // PTR_NUMFREQ_BINS_FIELD
               &in0oms_G,                 // PTR_G_OMS_FIELD 
               0,                         // FRONTMICBIAS_FIELD
               &$cvc.dmss_mode,           // PTR_MICMODE_FIELD
               &oms270in0_obj + $M.oms270.VOICED_FIELD, // PTR_OMS_VAD_FIELD
               0 ...;                     // HOLD_ADAPT_FIELD
#endif

#if uses_NC
         .VAR/DM1 nc_scratch_dm1[$nc100.DM1_SCRATCH_SIZE];
         .VAR/DM2 nc_ctrl[$nc100.NUM_PROC];
         .VAR nc100_dm1[$nc100.DM1_DATA_SIZE];
         .VAR nc100_dm2[$nc100.DM2_DATA_SIZE];
         .VAR nc100_obj[$nc100.STRUCT_SIZE] = 
               &D0,                       // X0_FIELD
               &D1,                       // X1_FIELD
               &nc100_dm1,                // DM1_DATA_FIELD
               &nc100_dm2,                // DM2_DATA_FIELD
               &nc_scratch_dm1,           // DM1_SCRATCH_FIELD
               &nc_ctrl,                  // NC_CTRL_FIELD (DM2)
               &$cvc.user.nc100_prep,     // FUNC_APP_PREP_FIELD
               &$cvc.user.nc100_pp,       // FUNC_APP_PP_FIELD
               0,                         // RPTP_FIELD
               0 ...;
#endif

#if uses_IN0_OMS
   // <start> of memory declared per instance of oms270
   .VAR in0oms_G[$M.CVC.Num_FFT_Freq_Bins];
   .VAR in0oms_LpXnz[$M.CVC.Num_FFT_Freq_Bins];
   .VAR in0oms_state[$M.oms270.STATE_LENGTH];

   .VAR oms270in0_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,   // $M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        0,                      // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
        0,                      // $M.oms270.HARM_ON_FIELD
        0,                      // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
        0,                      // $M.oms270.PTR_INP_X_FIELD   ( SP. Harmonicity not used)
        &D_l_real,              // $M.oms270.PTR_X_REAL_FIELD
        &D_l_imag,              // $M.oms270.PTR_X_IMAG_FIELD
        &BExp_D0,               // $M.oms270.PTR_BEXP_X_FIELD
        &D_l_real,              // $M.oms270.PTR_Y_REAL_FIELD
        &D_l_imag,              // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,               // $M.oms270.INITIAL_POWER_FIELD
        &in0oms_LpX_queue,      // $M.oms270.LPX_QUEUE_START_FIELD
        &in0oms_G,               // $M.oms270.G_FIELD;
        &in0oms_LpXnz,           // $M.oms270.LPXNZ_FIELD,
        &in0oms_state,           // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
        0.03921056084768,       // $M.oms270.ALFANZ_FIELD
        0xFF23A7,               // $M.oms270.LALFAS_FIELD
        0xFED889,               // $M.oms270.LALFAS1_FIELD
        0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        0.95,                   // $M.oms270.AGRESSIVENESS_FIELD
        0,                      // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;

#endif

#if uses_SND_NS
   .VAR/DM sndLpX_queue[$dms100.QUE_LENGTH];

   .VAR G_dmsZ[$M.CVC.Num_FFT_Freq_Bins];
   .VAR LpXnz_dms[$M.CVC.Num_FFT_Freq_Bins];
   .VAR spp[$dms100.DIM];
   .VAR dms_state[$dms100.STATE_LENGTH];

   .VAR dms100_obj[$dms100.STRUC_SIZE] =
         M_dms100_mode_object,   //$M.oms270.PTR_MODE_FIELD
         0,                      // $M.oms270.CONTROL_WORD_FIELD
         0,                      // $M.oms270.BYPASS_BIT_MASK_FIELD
         1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
         0,                      // $M.oms270.HARM_ON_FIELD
         1,                      // $M.oms270.MMSE_LSA_ON_FIELD
         $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
         &bufd_l_inp,            // $M.oms270.PTR_INP_X_FIELD
         &D_l_real,              // $M.oms270.PTR_X_REAL_FIELD
         &D_l_imag,              // $M.oms270.PTR_X_IMAG_FIELD
         &BExp_D0,               // $M.oms270.PTR_BEXP_X_FIELD
         &D_l_real,              // $M.oms270.PTR_Y_REAL_FIELD
         &D_l_imag,              // $M.oms270.PTR_Y_IMAG_FIELD
         0xFF0000,               // $M.oms270.INITIAL_POWER_FIELD
         &sndLpX_queue,          // $M.oms270.LPX_QUEUE_START_FIELD
         &G_dmsZ,                // $M.oms270.G_FIELD;
         &LpXnz_dms,             // $M.oms270.LPXNZ_FIELD,
         &dms_state,             // $M.oms270.PTR_STATE_FIELD
         &dms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
         0.036805582279178,      // $M.oms270.ALFANZ_FIELD
         0xFF13DE,               // $M.oms270.LALFAS_FIELD
         0xFEEB01,               // $M.oms270.LALFAS1_FIELD
         0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
         $dms100.NOISE_THRESHOLD,// $M.oms270.VAD_THRESH_FIELD
         0.95,                   // $M.oms270.AGRESSIVENESS_FIELD
         0,                      // $M.oms270.PTR_TONE_FLAG_FIELD
         &E,                     // Y_FIELD
         &D0,                    // X_FIELD
         &D1,                    // D_FIELD
         &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMS_AGGR,   // PARAM_FIELD
         &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC, // PTR_POWR_ADJUST_FIELD
         &$cvc.dmss_mode,        // PTR_DMS_MODE_FIELD
         &spp,                   // SPP_FIELD
         0 ...;

#endif // uses_SND_NS


#if uses_AEC
   .BLOCK/DM1;
        // Internal Zero Initialize
        // taps x bin
        .VAR  RcvBuf_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        // taps x bin
        .VAR  Ga_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        .VAR  L2PxR[4];
        // Internal Non-Zero Initialize
        .VAR  Gr_imag[$M.AEC_500.RER_dim];
        // Bin Reversed Ordering
        .VAR  SqGr[$M.AEC_500.RER_dim];
        .VAR  BExp_Ga[$M.CVC.Num_FFT_Freq_Bins];
        .VAR  LPwrX0[$M.CVC.Num_FFT_Freq_Bins];
        .VAR  RatFE[$M.AEC_500.RER_dim];
        .VAR  Cng_Nz_Shape_Tab[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;
   
   .BLOCK/DM2;
        // Internal Zero Initialize
        // taps x bin
        .VAR  RcvBuf_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        // taps x bin
        .VAR  Ga_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        .VAR  L2absGr[$M.AEC_500.RER_dim];
        // Internal Non-Zero Initialize
        .VAR  Gr_real[$M.AEC_500.RER_dim];
        .VAR  LPwrD[$M.AEC_500.RER_dim];
        .VAR  BExp_X_buf[$M.AEC_500.Num_Primary_Taps+1];
        .VAR  LpZ_nz[$M.CVC.Num_FFT_Freq_Bins];
        .VAR  LPwrX1[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;
   
   .BLOCK/DM1;
        // Internal Zero Initialize
        // taps x bin
        .VAR  GaMic1_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        // Internal Non-Zero Initialize
        .VAR  BExp_GaMic1[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;
   
   .BLOCK/DM2;
        // Internal Zero Initialize
        // taps x bin
        .VAR  GaMic1_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
   .ENDBLOCK;
   
   .VAR/DM1 aec_dm1[$M.AEC_500.STRUCT_SIZE] =
      &E_real,                            // OFFSET_E_REAL_PTR
      &E_imag,                            // OFFSET_E_IMAG_PTR
      &BExp_D0,                           // OFFSET_D_EXP_PTR
      &D_l_real,                         // OFFSET_D_REAL_PTR
      &D_l_imag,                         // OFFSET_D_IMAG_PTR
      &Exp_Mts_adapt,                     // OFFSET_SCRPTR_Exp_Mts_adapt
      $AEC_500.rer_headset,               // OFFSET_RER_EXT_FUNC_PTR
      0,                                  // OFFSET_RER_D_REAL_PTR, (set internally)
      0,                                  // OFFSET_RER_D_IMAG_PTR, (set internally)
      &Gr_imag,                           // OFFSET_PTR_Gr_imag
      &Gr_real,                           // OFFSET_PTR_Gr_real
      &SqGr,                              // OFFSET_PTR_SqGr
      &L2absGr,                           // OFFSET_PTR_L2absGr
      &LPwrD,                             // OFFSET_PTR_LPwrD
      &W_ri,                              // OFFSET_SCRPTR_W_ri
      &L_adaptR,                          // OFFSET_SCRPTR_L_adaptR
      0,                                  // OFFSET_RER_SQGRDEV (handsfree/adfrnr)

      &X_real,                         // OFFSET_X_REAL_PTR
      &X_imag,                         // OFFSET_X_IMAG_PTR
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_BEXP, // OFFSET_X_EXP_PTR
      &G_dmsZ,                         // OFFSET_OMS1_G_PTR
      &in0oms_LpXnz,                   // OFFSET_OMS1_D_NZ_PTR
      &in0oms_G,                       // OFFSET_oms_adapt_G_PTR
      &G_dmsZ,                         // OFFSET_OMS2_G_PTR
      0,                               // OFFSET_OMS_AGGRESSIVENESS
      0x200000,                        // OFFSET_CNG_Q_ADJUST
      $M.AEC_500.CNG_G_ADJUST,         // OFFSET_CNG_G_ADJUST(unused) 17
      0.5,                             // OFFSET_DTC_AGRESSIVENESS
      0.5,                             // OFFSET_RER_WGT_L2PXR
      0.5,                             // OFFSET_RER_WGT_L2PDR
      0,                               // OFFSET_ENABLE_AEC_REUSE
      0,                               // OFFSET_CONFIG
      0x028000,                        // OFFSET_MAX_LPWR_MARGIN
      $M.AEC_500.Num_Auxillary_Taps,   // OFFSET_NUM_AUXILLARY_TAPS
      $M.AEC_500.Num_Primary_Taps,     // OFFSET_NUM_PRIMARY_TAPS
      $M.CVC.Num_FFT_Freq_Bins,        // OFFSET_NUM_FREQ_BINS
      CVC_AEC_LPWRX_MARGIN_OVFL,       // OFFSET_LPWRX_MARGIN_OVFL
      CVC_AEC_LPWRX_MARGIN_SCL,        // OFFSET_LPWRX_MARGIN_SCL
      0,                                // OFFSET_RERCBA_ENABLE_MASK     (handsfree)
      0,                                // OFFSET_RER_AGGRESSIVENESS     (handsfree)
      0,                                // OFFSET_RER_WGT_SY             (handsfree)
      0,                                // OFFSET_RER_OFFSET_SY          (handsfree)
      0,                                // OFFSET_RER_POWER              (handsfree)
      0,                                // OFFSET_AEC_REF_LPWR_HB        (handsfree)
      0,                                // OFFSET_SCRPTR_RERDT_DTC       (handsfree)
      0,                                // OFFSET_L2TH_RERDT_OFF         (handsfree)
      0,                                // OFFSET_RERDT_ADJUST           (handsfree)
      0,                                // OFFSET_RERDT_POWER            (handsfree)

      $M.AEC_500.L_MUA_ON,              //  OFFSET_AEC_L_MUA_ON
      $M.AEC_500.L_ALFA_A,              //  OFFSET_AEC_L_ALFA_A
      // Mode Specific Functions for Commom source
      $M.AEC_500.dbl_talk_control_headset.normal_op,        // OFFSET_DT_FUNC1_PTR
      $M.AEC_500.dbl_talk_control_headset.normal_op_else,   // OFFSET_DT_FUNC2_PTR
      0,                                                    // OFFSET_DTC_AGRESS_FUNC_PTR
      $AEC_500.LPwrX_update_headset,                        // OFFSET_LPWRX_UPDT_FUNC_PTR
      0,                                                    // OFFSET_RER_DIVERGE_FUNC_PTR
      // Constant Arrays
      &$AEC_500.Const,              // OFFSET_CONST_DM1
      &RcvBuf_real,                         // OFFSET_PTR_RcvBuf_real
      &RcvBuf_imag,                         // OFFSET_PTR_RcvBuf_imag
      &Ga_imag,                             // OFFSET_PTR_Ga_imag
      &Ga_real,                             // OFFSET_PTR_Ga_real
      0,                                    // OFFSET_PTR_Gb_imag
      0,                                    // OFFSET_PTR_Gb_real
      &L2PxR,                               // OFFSET_PTR_L2PxR
      &BExp_Ga,                             // OFFSET_PTR_BExp_Ga
      0,                                    // OFFSET_PTR_BExp_Gb
      &LPwrX0,                              // OFFSET_PTR_LPwrX0
      &RatFE,                               // OFFSET_PTR_RatFE
      &BExp_X_buf,                          // OFFSET_PTR_BExp_X_buf
      &LpZ_nz,                              // OFFSET_PTR_LpZ_nz
      &LPwrX1,                              // OFFSET_PTR_LPwrX1

      &AttenuationPersist,                  // OFFSET_SCRPTR_Attenuation
      &L_adaptA,                            // OFFSET_SCRPTR_L_adaptA //wmsn: shold be persist if FDNLP/VSM is used
      0,                                    // OFFSET_SCRPTR_L_RatSqGt
      -268,                                 // $M.AEC_500.OFFSET_L_DTC 2.0*fs/L
      3,                                    // OFFSET_CNG_NOISE_COLOR (-1=wht,0=brn,1=pnk,2=blu,3=pur)
      CVC_AEC_PTR_NZ_TABLES,                 // OFFSET_PTR_NZ_TABLES
      &Cng_Nz_Shape_Tab,                      // OFFSET_PTR_CUR_NZ_TABLE
      0 ...;

   .VAR/DM1 aec2Mic_dm1[$M.TWOMIC_AEC.STRUCT_SIZE] =
      &E_real,                            // OFFSET_E_REAL_PTR
      &E_imag,                            // OFFSET_E_IMAG_PTR
      &BExp_D1,                           // OFFSET_D_EXP_PTR
      &D_r_real,                          // OFFSET_D_REAL_PTR
      &D_r_imag,                          // OFFSET_D_IMAG_PTR
      &Exp_Mts_adapt,                     // OFFSET_SCRPTR_Exp_Mts_adapt
      &aec_dm1,                           // OFFSET_PTR_MAIN_AEC
      0,                                  // OFFSET_PTR_BYPASS_AEC1
      &GaMic1_real,
      &GaMic1_imag,
      &BExp_GaMic1,
      &RcvBuf_real,
      &RcvBuf_imag;

   .VAR/DM1 vsm_fdnlp_dm1[$M.AEC_500_HF.STRUCT_SIZE] =
      0,                                    // OFFSET_D_REAL_PTR
      0,                                    // OFFSET_D_IMAG_PTR
      $M.CVC.Num_FFT_Freq_Bins,             // OFFSET_NUM_FREQ_BINS
      0,                                    // OFFSET_HD_THRESH_GAIN
      &$M.CVC_SYS.CurCallState,         // OFFSET_CALLSTATE_PTR
      0,                                    // OFFSET_TIER2_THRESH
      0,                                    // OFFSET_HC_TIER_STATE
      &rcv_vad400 + $M.vad400.FLAG_FIELD,   // OFFSET_PTR_RCV_DETECT, only used for HD/HC
      0,                                    // OFFSET_PTR_TIER1_CONFIG
      0,                                    // OFFSET_PTR_TIER2_CONFIG
      $AEC_500.ApplyHalfDuplex,             // HOWLING_CNTRL_FUNCPTR
      0,                                    // FDNLP_FUNCPTR
      0,                                    // VSM_FUNCPTR
      0,                                    // OFFSET_PTR_RatFE
      0,                                    // OFFSET_PTR_SqGr
      &AttenuationPersist,                  // OFFSET_SCRPTR_Attenuation
      0 ...;
#endif

   // wmsn: only executed when FE/BEX
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
      $M.CVC_HEADSET_2MIC.CALLST.MUTE;          // OFFSET_MUTE_VAL



#if uses_SND_PEQ
   // Parameteric EQ
   .VAR/DM2 snd_peq_dm2[PEQ_OBJECT_SIZE(MAX_NUM_PEQ_STAGES)] =
      &stream_map_sndout,             // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndout,             // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,             // MAX_STAGES_FIELD
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG,  // PARAM_PTR_FIELD
      0 ...;
#endif

#if uses_SND_VAD
   .VAR/DM2 snd_vad_peq[PEQ_OBJECT_SIZE(3)] =   // 3 stages
      &stream_map_sndout,                       // PTR_INPUT_DATA_BUFF_FIELD
      &vad_peq_output,                          // PTR_OUTPUT_DATA_BUFF_FIELD
      3,                                        // MAX_STAGES_FIELD
      CVC_VAD_PEQ_PARAM_PTR,                    // PARAM_PTR_FIELD
      0 ...;

   .VAR vad_default_param[] =
         0x0051D1, 0x0051D1, 0x1ABE60, 0x00001A,
         0x400000, 0x008000, 0xFD4000, 0x005000,
         0x00003C;

   .VAR/DM1 snd_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,     // INPUT_PTR_FIELD
      &vad_default_param,  // Parameter Ptr
      0 ...;

   .VAR vad_echo_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &$cvc.snd_agc_vad,                  // PTR_VAD_FLAG_FIELD
      &rcv_vad400 + $M.vad400.FLAG_FIELD, // PTR_EVENT_FLAG_FIELD
      0,                                  // FLAG_FIELD
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME,    // HOLD_TIME_FRAMES_FIELD
      0 ...;                              //HOLD_COUNTDOWN_FIELD

   .VAR vad_noise_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &$cvc.snd_agc_vad,                  // PTR_VAD_FLAG_FIELD
      &$cvc.snd_agc_vad_reverse,          // PTR_EVENT_FLAG_FIELD
      0,                                  // FLAG_FIELD
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SND_AGC_NOISE_HOLD_TIME,    // HOLD_TIME_FRAMES_FIELD
      0 ...;                              //HOLD_COUNTDOWN_FIELD 
#endif

   // SND AGC Pre-Gain stage
   .VAR/DM1 out_gain_dm1[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndout,                               // OFFSET_INPUT_PTR
      &stream_map_sndout,                               // OFFSET_OUTPUT_PTR
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA, // OFFSET_PTR_MANTISSA
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT; // OFFSET_PTR_EXPONENT


#if uses_SND_AGC
   // SND AGC
   .VAR/DM snd_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      0,                   //OFFSET_BYPASS_BIT_MASK_FIELD
      0,                  // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
      &stream_map_sndout,  //OFFSET_PTR_INPUT_FIELD
      &stream_map_sndout,  //OFFSET_PTR_OUTPUT_FIELD
      &vad_noise_hold + $M.CVC.vad_hold.FLAG_FIELD, //OFFSET_PTR_VAD_VALUE_FIELD
      0x7FFFFF,            //OFFSET_HARD_LIMIT_FIELD
      0,                   //OFFSET_PTR_TONE_FLAG_FIELD
      0 ...;
#endif

#if uses_NSVOLUME
   // NDVC - Noise Controled Volume
   .VAR/DM1 ndvc_dm1[$M.NDVC_Alg1_0_0.BLOCK_SIZE +$M.NDVC_Alg1_0_0.MAX_STEPS] =
      0,                               // OFFSET_CONTROL_WORD
      $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_NDVC,                    //OFFSET_BITMASK_BYPASS
      $M.NDVC_Alg1_0_0.MAX_STEPS,      // OFFSET_MAXSTEPS
      &in0oms_LpXnz,  // OFFSET_PTR_LPDNZ
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_NDVC_HYSTERESIS,  // OFFSET_PTR_PARAMS
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

#if uses_ASF

.BLOCK/DM;
   .VAR pX0[$asf100.NUM_PROC * 2];
   .VAR pX1[$asf100.NUM_PROC * 2];
   .VAR pXcR[$asf100.NUM_PROC * 2];
   .VAR pXcI[$asf100.NUM_PROC * 2];
   .VAR coh[$asf100.NUM_PROC * 2];
   .VAR wnr_g[$asf100.NUM_PROC * 2];
.ENDBLOCK;

.BLOCK/DM1;
   .VAR cc0_real[$asf100.NUM_PROC];
   .VAR phi0_real[$asf100.NUM_PROC]; 
   .VAR fd_w0_real[$asf100.NUM_PROC];
   .VAR fd_w1_real[$asf100.NUM_PROC];
   .VAR fw_w1_real[$asf100.NUM_PROC];
   .VAR comp_t_real[$asf100.NUM_PROC];
   .VAR beam_tr0[$asf100.NUM_PROC];      
   .VAR coh_real[$asf100.NUM_PROC];
   .VAR coh_cos[$asf100.NUM_PROC];
.ENDBLOCK;

.BLOCK/DM2;
   .VAR cc0_imag[$asf100.NUM_PROC];
   .VAR phi0_imag[$asf100.NUM_PROC];
   .VAR fd_w0_imag[$asf100.NUM_PROC];
   .VAR fd_w1_imag[$asf100.NUM_PROC];
   .VAR fw_w1_imag[$asf100.NUM_PROC];
   .VAR comp_t_imag[$asf100.NUM_PROC];
   .VAR beam_tr1[$asf100.NUM_PROC];
   .VAR coh_sin[$asf100.NUM_PROC];
.ENDBLOCK;   


   .VAR/DM1 asf_object[$asf100.STRUC_SIZE] =
      &D0,                          // X0_FIELD
      &D1,                          // X1_FIELD
      M_asf_mode_object,            // MODE_FIELD     
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_ASF_MIC_DISTANCE,                 // PARAM_FIELD 
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC,                     // PTR_POWR_ADJUST_FIELD
      asf100_scratch_dm1,           // SCRATCH_DM1_FIELD
      asf100_scratch_dm2,           // SCRATCH_DM2_FIELD
      $asf100.app_prep,             // FUNC_APP_PREP_FIELD 
      $asf100.app_pp,               // FUNC_APP_PP_FIELD 
      &$asf100.bf.adaptive_2mic_beam_nearfield,  // BEAM_FUNC_FIELD
      $cvc.DMSS_ASF_BEAM_MODE,      // BEAM_MODE_FIELD
      &pX0,                         // PX0N_FIELD
      &pX1,                         // PX1N_FIELD
      &pXcR,                        // PXCRN_FIELD
      &pXcI,                        // PXCIN_FIELD
      &coh,                         // COH_FIELD 
      &wnr_g,                       // WNR_G_FIELD 
      &cc0_real,                    // BEAM_CC0_REAL_FIELD 
      &cc0_imag,                    // BEAM_CC0_IMAG_FIELD 
      &phi0_real,                   // BEAM_PHI0_REAL_FIELD 
      &phi0_imag,                   // BEAM_PHI0_IMAG_FIELD 
      &fd_w0_real,                  // BEAM_FD_W0_REAL 
      &fd_w0_imag,                  // BEAM_FD_W0_REAL 
      &fd_w1_real,                  // BEAM_FD_W1_REAL 
      &fd_w1_imag,                  // BEAM_FD_W1_REAL 
      &fw_w1_real,                  // BEAM_FW_W1_REAL 
      &fw_w1_imag,                  // BEAM_FW_W1_IMAG 
      &comp_t_real,                 // BEAM_COMP_T_REAL_FIELD
      &comp_t_imag,                 // BEAM_COMP_T_IMAG_FIELD
      &beam_tr0,                    // BEAM_TR0_FIELD
      &beam_tr1,                    // BEAM_TR1_FIELD
      &coh_cos,                     // COH_COS_FIELD
      &coh_sin,                     // COH_SIN_FIELD
      &spp + $asf100.BIN_SKIPPED,   // COH_G_FIELD
      0 ...;                        // rest zeros
#endif   // uses_ASF


#if uses_ADF
    .VAR/DM1 $adf200_data_dm1[$adf200.DATA_SIZE_DM1];
    .VAR/DM2 $adf200_data_dm2[$adf200.DATA_SIZE_DM2];

   .VAR adf_IntRatio0[$adf200.ADF_num_proc];
   .VAR adf_IntRatio1[$adf200.ADF_num_proc];

   .VAR adf200_obj[$adf200.STRUCT_SIZE] =
         &D0,                       // X0_FIELD
         &D1,                       // X1_FIELD
         &$adf200_data_dm1,         // OFFSET_PTR_DM1data
         &$adf200_data_dm2,         // OFFSET_PTR_DM2data
         &adf200_scratch_dm1,       // OFFSET_SCRATCH_DM1
         &adf200_scratch_dm2,       // OFFSET_SCRATCH_DM2
         &adf_IntRatio0,            // PTR_INTRATIO0_FIELD
         &adf_IntRatio1,            // PTR_INTRATIO1_FIELD
#if uses_NC                         // OFFSET_L_POSTP_CTRL_PTR
         &nc_ctrl,
#else
         0,
#endif
         &$cvc.user.adf200_prep,    // FUNC_APP_PREP_FIELD
         &$cvc.user.adf200_pp,      // FUNC_APP_PP_FIELD
         0 ...;
#endif // uses_ADF

   // -----------------------------------------------------------------------------

   // Parameter to Module Map
   .VAR/ADDR_TABLE_DM   ParameterMap[] =

#if uses_AEC
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_CNG_Q,             &aec_dm1 + $M.AEC_500.OFFSET_CNG_Q_ADJUST,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_CNG_SHAPE,         &aec_dm1 + $M.AEC_500.OFFSET_CNG_NOISE_COLOR,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DTC_AGGR,          &aec_dm1 + $M.AEC_500.OFFSET_DTC_AGRESSIVENESS,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE,  &aec_dm1 + $M.AEC_500.OFFSET_ENABLE_AEC_REUSE,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &aec_dm1 + $M.AEC_500.OFFSET_CONFIG,
#endif

#if uses_RCV_NS
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_OMS_HI_RES_MODE, &oms270rcv_obj + $M.oms270.HARM_ON_FIELD,
#endif


#if uses_NSVOLUME
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,         &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_CONTROL_WORD,   //control word for bypass
#endif


#if uses_AEQ
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,             &AEQ_DataObject + $M.AdapEq.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_ATK_TC,             &AEQ_DataObject + $M.AdapEq.ALFA_A_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_ATK_1MTC,           &AEQ_DataObject + $M.AdapEq.ONE_MINUS_ALFA_A_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_DEC_TC,             &AEQ_DataObject + $M.AdapEq.ALFA_D_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_DEC_1MTC,           &AEQ_DataObject + $M.AdapEq.ONE_MINUS_ALFA_D_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BEX_NOISE_LVL_FLAGS,    &AEQ_DataObject + $M.AdapEq.BEX_NOISE_LVL_FLAGS,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BEX_LOW_STEP,           &AEQ_DataObject + $M.AdapEq.BEX_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BEX_HIGH_STEP,          &AEQ_DataObject + $M.AdapEq.BEX_PASS_HIGH_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_POWER_TH,           &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TH_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_MIN_GAIN,           &AEQ_DataObject + $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_MAX_GAIN,           &AEQ_DataObject + $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH1,    &AEQ_DataObject + $M.AdapEq.VOL_STEP_UP_TH1_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH2,    &AEQ_DataObject + $M.AdapEq.VOL_STEP_UP_TH2_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOW_STEP,           &AEQ_DataObject + $M.AdapEq.AEQ_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOW_STEP_INV,       &AEQ_DataObject + $M.AdapEq.INV_AEQ_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_STEP,          &AEQ_DataObject + $M.AdapEq.AEQ_PASS_HIGH_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_STEP_INV,      &AEQ_DataObject + $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD,

      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOW_BAND_INDEX,     &AEQ_DataObject + $M.AdapEq.LOW_INDEX_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOW_BANDWIDTH,      &AEQ_DataObject + $M.AdapEq.LOW_BW_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOG2_LOW_BANDWIDTH, &AEQ_DataObject + $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_MID_BANDWIDTH,      &AEQ_DataObject + $M.AdapEq.MID_BW_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOG2_MID_BANDWIDTH, &AEQ_DataObject + $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_BANDWIDTH,     &AEQ_DataObject + $M.AdapEq.HIGH_BW_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_LOG2_HIGH_BANDWIDTH,&AEQ_DataObject + $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_MID1_BAND_INDEX,    &AEQ_DataObject + $M.AdapEq.MID1_INDEX_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_MID2_BAND_INDEX,    &AEQ_DataObject + $M.AdapEq.MID2_INDEX_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AEQ_HIGH_BAND_INDEX,    &AEQ_DataObject + $M.AdapEq.HIGH_INDEX_FIELD,
#endif

#if uses_PLC
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_PLC_STAT_INTERVAL,      &$sco_data.object + $sco_pkt_handler.STAT_LIMIT_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,             &$sco_data.object + $sco_pkt_handler.CONFIG_FIELD,
#endif

      // Auxillary Audio Settings
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_CLIP_POINT,        	&$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.CLIP_POINT_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BOOST_CLIP_POINT,    	&$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.BOOST_CLIP_POINT_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_BOOST,           		&$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.BOOST_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_SCO_STREAM_MIX,   &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PRIM_GAIN_FIELD,
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_AUX_STREAM_MIX,   &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.AUX_GAIN_FIELD,

#if uses_AEC
      // HD threshold
      &CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN,         &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,
#endif

     // End of Parameter Map
      0;

   // Statistics from Modules sent via SPI
   // -------------------------------------------------------------------------------
   .VAR/ADDR_TABLE_DM  StatisticsPtrs[] = //[$M.CVC_HEADSET_2MIC.STATUS.BLOCK_SIZE+2] =
      $M.CVC_HEADSET_2MIC.STATUS.BLOCK_SIZE,
      &StatisticsClrPtrs,
      // Statistics
      &$M.CVC_SYS.cur_mode,                             // $M.CVC_HEADSET_2MIC.STATUS.CUR_MODE_OFFSET
      &$M.CVC_SYS.CurCallState,                         // $M.CVC_HEADSET_2MIC.STATUS.CALL_STATE_OFFSET
      &$M.CVC_SYS.SysControl,                           // $M.CVC_HEADSET_2MIC.STATUS.SYS_CONTROL_OFFSET
      &$M.CVC_SYS.CurDAC,                               // $M.CVC_HEADSET_2MIC.STATUS.CUR_DAC_OFFSET
      &$M.CVC_SYS.Last_PsKey,                           // $M.CVC_HEADSET_2MIC.STATUS.PRIM_PSKEY_OFFSET
      &$M.CVC_SYS.SecStatus,                            // $M.CVC_HEADSET_2MIC.STATUS.SEC_STAT_OFFSET
      &$dac_out.spkr_out_pk_dtct,
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &sco_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL,
	  &$M.CVC.app.scheduler.tasks+$FRM_SCHEDULER.TOTAL_MIPS_FIELD,  // $M.CVC_HEADSET_2MIC.STATUS.PEAK_MIPS_OFFSET

#if uses_NSVOLUME
      &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_FILTSUMLPDNZ,
                                                                 // $M.CVC_HEADSET_2MIC.STATUS.NDVC_NOISE_EST_OFFSET
#else
      &ZeroValue,                                                // $M.CVC_HEADSET_2MIC.STATUS.NDVC_NOISE_EST_OFFSET
#endif
      $dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PEAK_AUXVAL_FIELD,
	  &$M.CVC_MODULES_STAMP.CompConfig,                          // $M.CVC_HEADSET_2MIC.STATUS.COMPILED_CONFIG
      &$M.CVC_SYS.ConnectStatus,                        // $M.CVC_HEADSET_2MIC.STATUS.CONNSTAT
      &$adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN,               // $M.CVC_HEADSET_2MIC.STATUS.SIDETONE_GAIN
#if uses_NSVOLUME
      &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL,
#else
      &ZeroValue,
#endif

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
      &ZeroValue,&ZeroValue,&ZeroValue, &ZeroValue,&ZeroValue,
#endif
      &$adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,

#if uses_SND_AGC
      &snd_agc400_dm + $M.agc400.OFFSET_INPUT_LEVEL_FIELD,   // AGC SPeach Power Level
      &snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD,        // AGC Applied Gain
#else
      &OneValue,&OneValue,
#endif

#if uses_RCV_AGC
      &rcv_agc400_dm + $M.agc400.OFFSET_INPUT_LEVEL_FIELD,   // AGC SPeach Power Level (Q8.16 log2 power)
      &rcv_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD,        // AGC Applied Gain (Q6.17 linear gain [0 - 64.0])
#else
      &OneValue,&OneValue,
#endif

#if uses_AEC
   &aec_dm1 + $M.AEC_500.OFFSET_AEC_COUPLING,
#else
    &$M.CVC.data.ZeroValue,
#endif
#if uses_ASF
      &asf_object + $asf100.wnr.MEAN_PWR_FIELD,
      &asf_object + $asf100.wnr.MEAN_G_FIELD,
      &asf_object + $asf100.wnr.WIND_FIELD,
#else
      &ZeroValue,
      &ZeroValue, 
      &ZeroValue,
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
      &$adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,
      0;

   // Processing Tables
   // ----------------------------------------------------------------------------
   .VAR/DM ReInitializeTable[] =

      // Function                                     r7                r8

      // wmsn: only executed when FE/BEX
      $frame.iir_resamplev2.Initialize,                  &ref_downsample_dm1,   0 ,
      $frame.iir_resamplev2.Initialize,                  &dac_upsample_dm1,   0 ,

#if !defined(uses_FBADM)
      $filter_bank.one_channel.analysis.initialize,   &fft_obj,         &fba_left,
      $filter_bank.one_channel.analysis.initialize,   &fft_obj,         &fba_right,
#else
      $filter_bank.two_channel.analysis.initialize,   &fft_obj,         &fba_dm,
#endif
      $filter_bank.one_channel.synthesis.initialize,  &fft_obj,         &SndSynthesisBank,

#if uses_RCV_FREQPROC
      $filter_bank.one_channel.analysis.initialize,  &fft_obj,         &RcvAnalysisBank,
      $filter_bank.one_channel.synthesis.initialize, &fft_obj,     &RcvSynthesisBank,
#if uses_RCV_NS
      $oms270.initialize,                       0,                &oms270rcv_obj,
#endif
#if uses_AEQ
     $M.AdapEq.initialize.func,                0,                 &AEQ_DataObject,
#endif
#endif

#if uses_SND_NS
      $dms100.initialize,                       0,                &dms100_obj,
#endif

#if uses_AEC
      $filter_bank.one_channel.analysis.initialize,  &fft_obj, &AecAnalysisBank,
      $M.AEC_500.Initialize.func,      &vsm_fdnlp_dm1,                   &aec_dm1,
      $M.AEC_500.InitializeAEC1.func,           0,                &aec2Mic_dm1,
#endif

#if uses_ASF
      $asf100.initialize,                       0,                &asf_object,
#endif

#if uses_SSR
   $M.wrapper.ssr.initialize,             &asr_obj,                     0,
   $purge_cbuffer,                        &$dac_out.cbuffer_struc,      0,
#endif

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
#endif

#if uses_IN0_OMS
      $oms270.initialize,                             0,                &oms270in0_obj,
#endif

#if uses_NSVOLUME
      $M.NDVC_alg1_0_0.Initialize.func,   &ndvc_dm1,                    0,
#endif

#if uses_SND_VAD
      $audio_proc.peq.initialize,          &snd_vad_peq,             0,
      $M.vad400.initialize.func,           &snd_vad400,              0,
#endif

#if uses_SND_AGC
      $M.agc400.initialize.func,                      0,                &snd_agc400_dm,
#endif

      $dmss.initialize,                               0,                &dmss_obj,

#if uses_MGDC
      $mgdc100.initialize,                            0,                &mgdc100_obj,
#endif

#if uses_ADF
      $adf200.initialize,                             0,                &adf200_obj,
#endif

#if uses_NC
      $nc100.initialize,                              0,                &nc100_obj,
#endif

      $frame_sync.sidestone_filter_op.InitializeFilter,     &$adc_in.sidetone_copy_op.param,  0,

      $cvc.mc.reset,                                  0,                0,

      0;                                    // END OF TABLE

   // -------------------------------------------------------------------------------
   // Table of functions for current mode
   .VAR  ModeProcTableSnd[$M.CVC_HEADSET_2MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsSnd,              // undefined state
      &hfk_proc_funcsSnd,               // hfk mode
#if uses_SSR
      &ssr_proc_funcsSnd,               // ssr mode
#else
      &copy_proc_funcsSnd,              // undefined mode
#endif
      &copy_proc_funcsSnd,      		// pass-thru left mode
      &copy_proc_funcsSnd,      		// pass-thru right mode
      &copy_proc_funcsLpbk,    			// loop-back mode
      &copy_proc_funcsSnd,              // standby-mode
      &hfk_proc_funcsSnd;               // low volume mode

   .VAR  ModeProcTableRcv[$M.CVC_HEADSET_2MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsRcv,              // undefined state
      &hfk_proc_funcsRcv,               // hfk mode
      &hfk_proc_funcsRcv,               // ssr mode
      &copy_proc_funcsRcv,      		// pass-thru left mode
      &copy_proc_funcsRcv,      		// pass-thru right mode
      0,                                // loop-back mode       // SP. Loopback does all processing in Send
      &copy_proc_funcsRcv,              // standby-mode
      &hfk_proc_funcsRcv;               // low volume mode


   // -----------------------------------------------------------------------------
   .VAR/DM hfk_proc_funcsRcv[] =
      // Function                               r7                   r8

      $frame_sync.distribute_streams_ind,      &rcv_process_streams,  0,

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &sco_dcblock_dm2,             0,      // Ri --> Ri
#endif

      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,        0,

#if uses_RCV_VAD
      $audio_proc.peq.process,                  &rcv_vad_peq,           0,
      $M.vad400.process.func,                   &rcv_vad400,            0,
      $cvc.mc.echo_detect,                      0,                      0,
#endif

#if uses_RCV_FREQPROC
      $filter_bank.one_channel.analysis.process, &fft_obj,   &RcvAnalysisBank,

#if uses_AEQ
      $M.AdapEq.process.tone_detect,            0,                   &AEQ_DataObject,
#endif

#if uses_RCV_NS
      $oms270.process,                          $cvc.mc.rcv_oms,        &oms270rcv_obj,
      $oms270.apply_gain,                       $cvc.mc.rcv_oms,        &oms270rcv_obj,
#endif

#if uses_AEQ
      $cvc.channel.add_headroom,   (&AEQ_DataObject + $M.AdapEq.PTR_X_REAL_FIELD),    &$cvc_fftbins,
      $M.AdapEq.process.func,                   0,                   &AEQ_DataObject,
#endif

      // wmsn: for NB/WB only, not for FE/BEX
      $cvc.non_fe.Zero_DC_Nyquist,              &$M.CVC.data.X_real,        &$M.CVC.data.X_imag,

      $filter_bank.one_channel.synthesis.process, &fft_obj,   &RcvSynthesisBank,
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
      $cvc.user.agc_rcv.process,                0,             &rcv_agc400_dm,
#endif

#if uses_RCV_PEQ
      // wmsn: for WB only
      $cvc.rcv_peq.process_wb,                  &rcv_peq_dm2,           0,
#endif

      $frame_sync.update_streams_ind,            &rcv_process_streams, 0,

      0;                                     // END OF TABLE

   // -----------------------------------------------------------------------------
 .VAR/DM hfk_proc_funcsSnd[] =
      // Function                               r7                   r8

      $frame_sync.distribute_streams_ind,       &snd_process_streams,0,

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &in_l_dcblock_dm2,   0,             // Si_L --> Si_L
      $audio_proc.peq.process,                  &in_r_dcblock_dm2,   0,             // Si_R --> Si_R
#endif

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,   0,
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,   0,

#if !defined(uses_FBADM)
      $filter_bank.one_channel.analysis.process, &fft_obj,           &fba_left,     // Si_L -> D0
      $filter_bank.one_channel.analysis.process, &fft_obj,           &fba_right,    // Si_R -> D1
#else
      $filter_bank.two_channel.analysis.process, &fft_obj,           &fba_dm,
#endif

#if uses_MGDC
      $mgdc100.process,                         &$cvc.mc.mgdc100,    &mgdc100_obj,  // [D0,D1]
#endif

#if uses_IN0_OMS
      $oms270.process,                          $cvc.mc.in0oms,      &oms270in0_obj, // D0
#endif

#if uses_NSVOLUME
      $M.NDVC_alg1_0_0.Process.func,            &ndvc_dm1,           0,
#endif

#if uses_AEC
      $cvc.user.aec_ref.fe_downsample_process,  &ref_downsample_dm1, 0,
      $cvc.user.aec_ref.filter_bank_analysis,   &fft_obj,            &AecAnalysisBank,  // ref --> [X_real,X_imag]
      $cvc.user.aec500_dm.fnmls_process,        &aec2Mic_dm1,        0,
#endif

#if uses_MGDC
      $dmss.input_power_monitor,                0,                   &dmss_obj,
#endif

#if uses_ASF
      $asf100.process,                          &$cvc.mc.asf100,     &asf_object,   // [D0,D1]
#endif

#if uses_ADF
      $cvc.channel.add_headroom,                &D0,                 &$cvc_fftbins,
      $cvc.channel.add_headroom,                &D1,                 &$cvc_fftbins,
      $adf200.process,                          &$cvc.mc.adf200,     &adf200_obj,   // [D0,D1]
#endif

#if uses_MGDC
      $dmss.output_power_monitor,               0,                   &dmss_obj,
#endif

#if uses_NC
      $nc100.process,                           &$cvc.mc.nc100,      &nc100_obj,    // D0
#endif

#if uses_SND_NS
      $dms100.process,                          $cvc.mc.dms100,      &dms100_obj,   // [D0,D1]
      $dms100.apply_gain,                       $cvc.mc.dms_out,     &dms100_obj,   // [D0 -> E]
#endif

#if uses_ASF
      $cvc.user.dmss_TR,                        0,                   0,
#endif

#if uses_AEC
      $cvc.user.aec500_nlp_process,             &vsm_fdnlp_dm1,      &aec_dm1,
      $cvc.user.aec500_cng_process,             &aec_dm1,            0,             // E
#endif

      $M.CVC.Zero_DC_Nyquist.func,              &E_real,             &E_imag,
      $filter_bank.one_channel.synthesis.process,  &fft_obj,  &SndSynthesisBank,    // [E -> So]

#if uses_SND_PEQ
      $audio_proc.peq.process,                  &snd_peq_dm2,        0,
#endif

#if uses_SND_VAD
      $cvc.user.snd_vad.peq_process,            &snd_vad_peq,        0,
      $cvc.user.snd_vad.vad_process,            &snd_vad400,         0,
#endif

      $M.audio_proc.stream_gain.Process.func,   &out_gain_dm1,       0,

#if uses_SND_AGC
      $cvc.user.agc_snd.process,                0,                   &snd_agc400_dm,
#endif

      $M.MUTE_CONTROL.Process.func,             &mute_cntrl_dm1,     0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,    0,

      $frame_sync.update_streams_ind,           &snd_process_streams,0,

      0;                                     // END OF TABLE

   // -------------------------------------------------------------------------------
#if uses_SSR // Simple Speech Recognition
   .VAR/DM ssr_proc_funcsSnd[] =
      // Function                               r7                   r8

      $frame_sync.distribute_streams_ind,       &snd_process_streams,0,

   #if uses_DCBLOCK
      $audio_proc.peq.process,                  &in_l_dcblock_dm2,   0,             // Si_L --> Si_L
      $audio_proc.peq.process,                  &in_r_dcblock_dm2,   0,             // Si_R --> Si_R
   #endif

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,   0,             // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,   0,             // Si_R

#if !defined(uses_FBADM)
      $filter_bank.one_channel.analysis.process, &fft_obj,           &fba_left,     // Si_L -> D0
      $filter_bank.one_channel.analysis.process, &fft_obj,           &fba_right,    // Si_R -> D1
#else
      $filter_bank.two_channel.analysis.process, &fft_obj,           &fba_dm,
#endif

   #if uses_SND_NS
      $dms100.process,                          $cvc.mc.dms_out,     &dms100_obj,   // [D0,D1]
   #endif

      // SP.  ASR uses dms data object
      $M.wrapper.ssr.process,                   &asr_obj,            0,
      
      $M.MUTE_CONTROL.Process.func,             &mute_ssr_dm1,       0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,    0,

      $frame_sync.update_streams_ind,           &snd_process_streams,0,

      0;                                     // END OF TABLE

#endif

   // -------------------------------------------------------------------------------

   .VAR/DM copy_proc_funcsSnd[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,        &snd_process_streams,  0,

      $cvc_Set_PassThroughGains,                &ModeControl,         0,

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,            0,    // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,            0,    // Si_R
      $M.audio_proc.stream_mixer.Process.func,  &adc_mixer,                   0,    // Si_L,Si_R --> So
      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,     0,

      $frame_sync.update_streams_ind,           &snd_process_streams,  0,
      0;                                     // END OF TABLE

   .VAR/DM copy_proc_funcsRcv[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,       &rcv_process_streams,  0,

      $cvc_Set_PassThroughGains,                &ModeControl,         0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,      0,
      $M.audio_proc.stream_gain.Process.func,   &passthru_rcv_gain,                    0,    // Ri --> Ro

      // SP.  passthru_rcv_gain must be before passthru_snd_gain for loopback.
      // passthru_snd_gain overwrites rcv_in. upsample is from rcv_in to rcv_out
      // wmsn: only executed when FE/BEX
      $cvc.fe.frame_resample_process,         &dac_upsample_dm1, 0 ,

      $frame_sync.update_streams_ind,           &rcv_process_streams,  0,
      0;                                     // END OF TABLE

// -----------------------------------------------------------------------------
   .VAR/DM copy_proc_funcsLpbk[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,        &lpbk_process_streams,  0,

      $cvc_Set_LoopBackGains,                   &ModeControl,         0,

	  $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,         0,   // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,         0,   // Si_R
      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,           0,
      // SP.  Rcv gain must be applied before send mix for upsampling
      $M.audio_proc.stream_gain.Process.func,   &passthru_rcv_gain,        0,   // ri --> so
	  $M.audio_proc.stream_mixer.Process.func,  &adc_mixer,                0,   // si --> ro or si->ri (BEX)


      // SP.  passthru_rcv_gain must be before adc_mixer. adc_mixer overwrites Ri.
      // upsample is from rcv_in to rcv_out
      // wmsn: only executed when FE/BEX
      $cvc.fe.frame_resample_process,         &dac_upsample_dm1, 0 ,             // Ri --> Ro (BEXT)

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,     0,

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
    //   &ref_downsample_dm1 +  $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //   &ref_downsample_dm1 +  $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,
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
    //  &fba_left + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
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
    //  &fba_right + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &adc_mixer + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH2_PTR,
	 //  &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,


   // sndout stream map .
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
   .VAR	stream_map_rcvin[$framesync_ind.ENTRY_SIZE_FIELD] =
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
.MODULE $M.CVC_HEADSET_2MIC.SystemReInitialize;


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

#if uses_AEC
   // Configure CNG
   r1 = $M.AEC_500.CNG_G_ADJUST;
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.CVC_HEADSET_2MIC.CONFIG.CNGENA;
   if Z r1 = Null;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_CNG_G_ADJUST] = r1;

   // Configure RER
   r2 = r0 AND $M.CVC_HEADSET_2MIC.CONFIG.RERENA;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_RER_func] = r2;
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMS_AGGR]; 
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS] = r0;
#endif


#if uses_RCV_AGC
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_SYS_CON_WORD_FIELD] = r0;
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
#if uses_AEC   
   r0 = Null;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS] = r0;   
#endif

   // USB rate match persistence
   // --------------------------

   call $block_interrupts;

   // Load the USB rate match info previously acquired from the persistence store
   r1 = M[$M.2mic.LoadPersistResp.persistent_current_alpha_index];

   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD] = r1;

   r1 = M[$M.2mic.LoadPersistResp.persistent_average_io_ratio];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD] = r1;

   r1 = M[$M.2mic.LoadPersistResp.persistent_warp_value];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD] = r1;

   r1 = M[$M.2mic.LoadPersistResp.persistent_inverse_warp_value];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD] = r1;

   r1 = M[$M.2mic.LoadPersistResp.persistent_sra_current_rate];
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
// r2 = length of persistence block
// r3 = address of persistence block
// *****************************************************************************
.MODULE $M.2mic.LoadPersistResp;

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
   r0 = M[$M.CVC.data.mgdc100_obj + $mgdc100.L2FBPXD_FIELD];
   M[$M.2mic.LoadPersistResp.persistent_mgdc] = r0;
   r0 = M[$M.2mic.LoadPersistResp.persistent_mgdc];
   r0 = r0 ASHIFT -8;                                                   // to 16-bit, truncate 8 lsbs
   M[&persist_data_2mic + 1 + $CVC_2MIC_PERSIST_MGDC_OFFSET] = r0;
#endif

#if uses_RCV_AGC
   r0 = M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD];
   M[$M.2mic.LoadPersistResp.persistent_agc] = r0;
   r0 =  M[$M.2mic.LoadPersistResp.persistent_agc];
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


   r0 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA];
   r5 = r0;

   r4 = M[$M.CVC_SYS.cur_mode];
   NULL = r4 - $M.CVC_HEADSET_2MIC.SYSMODE.PSTHRGH_LEFT;
   if Z r5 = NULL;
   if Z jump passthroughgains;
   NULL = r4 - $M.CVC_HEADSET_2MIC.SYSMODE.PSTHRGH_RIGHT;
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
   r1 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT];
   r2 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_PT_RCVGAIN_MANTISSA];
   r3 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_PT_RCVGAIN_EXPONENT];
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


// *****************************************************************************
// MODULE:
//    $M.cvc_headset_2mic.user_process
//
// DESCRIPTION:
//    CVC headset 2mic modules user processes
//
// INPUT:
//
// OUTPUT:
//
// NOTES:
//
// *****************************************************************************
.CONST $cvc.DMSS_AGGR                  0.4;
.CONST $cvc.DMSS_GMAX                  1.0;
.CONST $cvc.DMSS_GMIN                 (1.0 - $cvc.DMSS_AGGR);
.CONST $cvc.DMSS_NC_CTRL_BIAS          5.0/(1<<7); // 5.0 in Q8.16
.CONST $cvc.DMSS_NC_CTRL_TRANS         2.0/(1<<4); // 2.0 in Q5.19
.CONST $cvc.DMSS_ASF_BEAM_MODE         1;

.MODULE $M.cvc_headset_2mic.user_process;
   .CODESEGMENT CVC_USER_PROC_PM;
   .DATASEGMENT DM;

#if uses_ADF
   $cvc.user.adf200_prep:
   // if Beam_mode && ~bypass_bf
   //     adf_prep
   // end
   Null = M[$cvc.bypass_bf];
   if NZ rts;
   Null = $cvc.DMSS_ASF_BEAM_MODE;
   if Z rts;

   jump $adf200.phase_synchronize;

   $cvc.user.adf200_pp:
   // if Beam_mode && (G_min > 0)
   //     adf_pp
   // end
   Null = $cvc.DMSS_ASF_BEAM_MODE;
   if Z rts;
   Null = $cvc.DMSS_GMIN;
   if Z rts;

   r5 = $cvc.DMSS_GMIN;
   r6 = $cvc.DMSS_GMAX;
   jump $adf200.gain_regulation;
#endif // uses_ADF


#if uses_NC
   $cvc.user.nc100_prep:
   push rLink;

   // ADF ON?
   call $cvc.mc.adf200;

   // r0 -> ADF bypass flag from avove
   // r1 -> Beam_TR0
   // r2 -> Beam_TR1
   // r3 -> Ctrl_bias
   // r4 -> Ctrl_Trans
   r1 = &$M.CVC.data.beam_tr0 - $asf100.BIN_SKIPPED + $nc100.BIN_SKIPPED;
   r2 = &$M.CVC.data.beam_tr1 - $asf100.BIN_SKIPPED + $nc100.BIN_SKIPPED;
   r3 = $cvc.DMSS_NC_CTRL_BIAS;
   r4 = $cvc.DMSS_NC_CTRL_TRANS;
   call $nc100.compara;

   jump $pop_rLink_and_rts;

   $cvc.user.nc100_pp:
   // if (G_min > 0)
   //     nc_pp
   // end
   Null = $cvc.DMSS_GMIN;
   if Z rts;

   r5 = $cvc.DMSS_GMIN;
   r6 = $cvc.DMSS_GMAX;
   jump $nc100.gain_regulation;
#endif // uses_NC


#if uses_ASF
   $cvc.user.dmss_TR:
   push rLink;

   // if SND.DMSS_b.Mode_t == 0 ?
   call $cvc.mc.dmss_mode;
   Null = r0;
   if NZ jump $pop_rLink_and_rts;

      r2 = &$M.CVC.data.G_dmsZ;
      r4 = &$M.CVC.data.beam_tr0;
      r5 = &$M.CVC.data.beam_tr1;
   #if uses_ADF
      r6 = &$M.CVC.data.adf_IntRatio0;
      r7 = &$M.CVC.data.adf_IntRatio1;
      call $cvc.mc.adf200;
      r8 = r0; // r8 = ADF status (nonzero=bypass, 0=process)
   #else
      r8 = 1;  // ADF is not compiled. calc_TR to ignore adf_IntRatio0/1
   #endif      
      call $dmss.calc_TR;
   
      jump $pop_rLink_and_rts;
#endif // uses_ASF


#if uses_RCV_AGC
   $cvc.user.agc_rcv.process:
   r5 = $cvc.mc.agc_rcv;
   r6 = $M.agc400.process.func;
   jump $cvc.module_process;
#endif // uses_RCV_AGC


#if uses_SND_AGC
   $cvc.user.agc_snd.process:
   r5 = $cvc.mc.agc_snd;
   r6 = $M.agc400.process.func;
   jump $cvc.module_process;
#endif // uses_SND_AGC


#if uses_AEC
   $cvc.user.aec_ref.fe_downsample_process:
   r5 = $cvc.mc.aec500;
   r6 = $cvc.fe.frame_resample_process;
   jump $cvc.module_process;

   $cvc.user.aec_ref.filter_bank_analysis:
   r5 = $cvc.mc.aec500;
   r6 = $filter_bank.one_channel.analysis.process;
   jump $cvc.module_process;

   $cvc.user.aec500_dm.fnmls_process:
   r5 = $cvc.mc.aec500_dm;
   r6 = $M.2Mic_aec.func;
   jump $cvc.module_process;

   $cvc.user.aec500_nlp_process:
   r5 = $cvc.mc.aec500_nlp;
   r6 = $AEC_500.NonLinearProcess;
   jump $cvc.module_process;

   $cvc.user.aec500_cng_process:
   r5 = $cvc.mc.aec500_cng;
   r6 = $M.AEC_500.comfort_noise_generator.func;
   jump $cvc.module_process;
#endif // uses_AEC

#if uses_SND_VAD
   $cvc.user.snd_vad.peq_process:
   r5 = $cvc.mc.snd_vad;
   r6 = $audio_proc.peq.process;
   jump $cvc.module_process;

   $cvc.user.snd_vad.vad_process:
   r5 = $cvc.mc.snd_vad;
   r6 = $M.vad400.process.func;
   jump $cvc.module_process;
#endif

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cvc.mc.reset
//
// DESCRIPTION:
//    CVC module bypass/hold control reset and initialization.
//
// INPUT:
//    - none
//
// OUTPUT:
//    - none
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.cvc_headset_2mic.module_control.initialize;
   .CODESEGMENT CVC_MODULE_CONTROL_INIT_PM;
   .DATASEGMENT DM;

   // Non re-initialiable flags
   .VAR $cvc.powerup_hold_count = 15;
   .VAR $cvc.powerup_flag = 1;
   .VAR $cvc.bypass_bf = 0;
   .VAR $cvc.bypass_dms = 0;

   // Re-initialiable flags
   .VAR $cvc.dmss_mode;
   .VAR $cvc.echo_flag;
   .VAR $cvc.snd_agc_vad;
   .VAR $cvc.snd_agc_vad_reverse;   
   .VAR $cvc.asf_bypassed;

// -----------------------------------------------------------------------------
// reset module control flags
// -----------------------------------------------------------------------------
$cvc.mc.reset:
   // Reset CVC dmss_mode to system dmss_mode
   // system_dmss_mode : 0 - Dural Microphone Mode
   //                    1 - Single Microphone Mode
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.DMSS_MODE;
   M[$cvc.dmss_mode] = r0;

   // Reset echo, vad and other flags
   M[$cvc.echo_flag] = 0;
   M[$cvc.snd_agc_vad] = 0;
   M[$cvc.snd_agc_vad_reverse] = 0;   
   M[$cvc.asf_bypassed] = 0;

   // Reset CVC specific module control flags, and other initial values
#if uses_MGDC
   // refresh from persistence
   r1 = M[$M.2mic.LoadPersistResp.persistent_mgdc];
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   Null = r0 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_MGDCPERSIST;
   if NZ r1 = NULL;
   M[$M.CVC.data.mgdc100_obj + $mgdc100.L2FBPXD_FIELD] = r1;
#endif


#if uses_RCV_AGC
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_RCVAGC;
   if Z jump next1;
   r1 = 0;
   M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD] = r1;
next1:   
#endif // uses_RCV_AGC
#if uses_SND_AGC
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_SNDAGC;
   if Z jump next2;
   r1 = 0;
   M[$M.CVC.data.snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD] = r1;
next2:   
#endif // uses_SND_AGC
#if uses_ASF
   // ASF internal module control
   r2 = M[$cvc.bypass_bf];
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_BF_FIELD] = r2;

   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];

   r0 = r1 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_WNR;
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_WNR_FIELD] = r0;
   if Z r2 = 0;

   r0 = r1 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_SPP;
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_COH_FIELD] = r0;
   if Z r2 = 0;

   M[$cvc.asf_bypassed] = r2;
#endif

#if uses_SND_NS
    r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMS_AGGR];
    r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_ASR_OMS_AGGR];
    r2 = M[$M.CVC_SYS.cur_mode];
    NULL = r2 - $M.CVC_HEADSET_2MIC.SYSMODE.SSR;
    if NZ r1=r0;

   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r1 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_SPP;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_SPP_FIELD] = r0;
   r0 = r1 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_NFLOOR;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_NFLOOR_FIELD] = r0;
   r0 = r1 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_GSMOOTH;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_GSMOOTH_FIELD] = r0;
   r0 = r1 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.GSCHEME;
   M[$M.CVC.data.dms100_obj + $dms100.GSCHEME_FIELD] = r0;
#endif

#if uses_RCV_AGC
   // refresh from persistence
   r1 = M[$M.2mic.LoadPersistResp.persistent_agc_init];
   M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_PERSISTED_GAIN_FIELD] = r1;
#endif

   rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.cvc_headset_2mic.module_control
//
// DESCRIPTION:
//    CVC module bypass/hold control logic.
//
// INPUT:
//    - none
//
// OUTPUT:
//    - r0: 0 -> process is requested.
//          1 -> bypass is requested
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.cvc_headset_2mic.module_control;
   .CODESEGMENT CVC_MODULE_CONTROL_PM;
   .DATASEGMENT DM;

// -----------------------------------------------------------------------------
// Power up detection
// -----------------------------------------------------------------------------
$cvc.mc.powerup_detect:
   // do nothing if not power up
   r0 = M[$cvc.powerup_hold_count];
   if Z rts;
   // count down
   r0 = r0 - 1;
   M[$cvc.powerup_hold_count] = r0;
   if NZ rts;
   // clear flag
   M[$cvc.powerup_flag] = 0;
   rts;

// -----------------------------------------------------------------------------
// Echo detection
// -----------------------------------------------------------------------------
$cvc.mc.echo_detect:
#if uses_RCV_VAD
   r1 = M[&$M.CVC.data.rcv_vad400 + $M.vad400.FLAG_FIELD];
   r2 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r2 AND $M.CVC_HEADSET_2MIC.CONFIG.HDBYP;
   if NZ r1 = 0;
#else
   r1 = 0;
#endif

   M[$cvc.echo_flag] = r1;
   rts;

// -----------------------------------------------------------------------------
// Receive AGC hold control
// -----------------------------------------------------------------------------
$cvc.mc.agc_rcv:
   // if AGCrcv_on ?
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_RCVAGC;
   rts;

// -----------------------------------------------------------------------------
// Send AGC bypass and VAD control
// -----------------------------------------------------------------------------
$cvc.mc.agc_snd:
   // if AGCsnd_on ?
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_SNDAGC;
   if NZ rts;

   // if DMSout_b.Mode == 0
   //    VAD_AGC = DMSout_b.VAD_voiced;
   // else
   //    VAD_AGC = VAD400.VAD
   // end

#if uses_SND_VAD
   r1 = M[&$M.CVC.data.snd_vad400 + $M.vad400.FLAG_FIELD];
#else
   r1 = 1;
#endif

#if uses_SND_NS

   Null = M[&$M.CVC.data.dms100_obj + $dms100.DMS_MODE_FIELD];
   if NZ jump no_update_snd_agc_vad;
   r1 = M[&$M.CVC.data.dms100_obj + $dms100.VAD_VOICED_FIELD];
   
   r7 = M[&$M.CVC.data.dmss_obj + $dmss.DIFF_LP_FIELD];
   r7 = r7 - 98304;
   if LE r1 = 0;
   
   r7 = M[&$M.CVC.data.dms100_obj + $M.oms270.PTR_G_FIELD];
   I0 = r7;
   I0 = I0 + 1;
   r0 = M[I0,1];
   r10 = 51;
   r7 = 0.0196078; 
   rMAC = 0;
   do mean_loop;
      rMAC = rMAC + r0 * r7 , r0 = M[I0,1];
   mean_loop: 
   Null = rMAC - 0.45;
   if LE r1 = 0;
  
no_update_snd_agc_vad:
#endif
   
   
   M[$cvc.snd_agc_vad] = r1;

   r0 = 1;
   r1 = r0 - r1;                                     //r1 = !r1
   M[$cvc.snd_agc_vad_reverse] = r1;

   push rLink;
   //call vad_echo_hold
   r7 = &$M.CVC.data.vad_echo_hold;
   call $M.vad_hold.process.func;   

   //call vad_noise_hold
   r7 = &$M.CVC.data.vad_noise_hold;
   call $M.vad_hold.process.func;                    //output r0 
   
   //AND two flags
   r7 = &$M.CVC.data.vad_echo_hold;
   r1 = M[r7 + $M.CVC.vad_hold.FLAG_FIELD];
   r0 = r0 AND r1;                                  
   r7 = &$M.CVC.data.vad_noise_hold;
   M[r7 + $M.CVC.vad_hold.FLAG_FIELD] = r0;

   r0 = 0;

   jump $pop_rLink_and_rts;
   
// -----------------------------------------------------------------------------
// Send VAD bypass/hold control
// -----------------------------------------------------------------------------
$cvc.mc.snd_vad:
   r0 = 0;
#if uses_SND_NS
   // Disable snd_VAD if dms100 is in dural microphone mode
   r1 = 1;
   Null = M[&$M.CVC.data.dms100_obj + $dms100.DMS_MODE_FIELD];
   if Z r0 = r1;
#endif
   rts;

// -----------------------------------------------------------------------------
// OMSin0 module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.in0oms:
   $push_rLink_macro;

   // AEC disabled?
   call $cvc.mc.aec500;
   Null = r0;
   if Z jump $pop_rLink_and_rts;

   // NDVC disabled?
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_NDVC;
   if Z jump $pop_rLink_and_rts;

   // MGDC disabled?
   call $cvc.mc.mgdc100;

   jump $pop_rLink_and_rts;

// -----------------------------------------------------------------------------
// OMS rcv module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.rcv_oms:
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.CONFIG.BYPASS_RCVOMS;
   rts;

// -----------------------------------------------------------------------------
// AEC500 dural micrpohne module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.aec500_dm:
   // DMSS mode
   r0 = M[$cvc.dmss_mode];
   M[&$M.CVC.data.aec2Mic_dm1 + $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1] = r0;

   // AEC_on ?
   // Continuie on $cvc.mc.aec500 below

// -----------------------------------------------------------------------------
// AEC500 module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.aec500:
   r0 = 1;

   // Bypass AEC for LV mode
   r1 = M[$M.CVC_SYS.cur_mode];
   NULL = r1 - $M.CVC_HEADSET_2MIC.SYSMODE.LOWVOLUME;
   if Z rts;

   // Check if AEC has been enabled globally
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.AECENA;
   if Z rts;

   // AEC should run
   r0 = 0;
   rts;

// -----------------------------------------------------------------------------
// AEC500 NLP module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.aec500_nlp:
   // AEC_HD_on ?
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.CONFIG.HDBYP;
   if NZ rts;

   // AEC_on ?
   jump $cvc.mc.aec500;

// -----------------------------------------------------------------------------
// AEC500 CNG module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.aec500_cng:
/*
   // CNG_on ?
   r0 = 1;
   r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r1 AND $M.CVC_HEADSET_2MIC.CONFIG.CNGENA;
   if Z rts;
*/

   // AEC_on ?
   jump $cvc.mc.aec500;

// -----------------------------------------------------------------------------
// MGDC module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.mgdc100:
   // if (MGDC_on && ~SYS_DMSS_MODE)
   //    MGDC
   // end

   // MGDC bypass control
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_MGDC;
   if NZ rts;

   //figure out MGDC_update  
   // if ~EchoFlag && ~Wind_Flag
   //     if SND.OMSin0_b.voiced
   //         MGDC_update = 1;  % MGDC gain calibration + Channel lost detection
   //     else
   //         MGDC_update = 2;  % MGDC gain calibration + gain updation + Channel lost detection
   //     end
   // else
   //     MGDC_update = 0;  % MGDC only gain calibration
   // end
   r0 = 0;                             //MGDC_update = 0;
   r1 = M[$cvc.echo_flag];                                       // EchoFlag
   r2 = M[&$M.CVC.data.asf_object + $asf100.wnr.WIND_FIELD];     // WindFlag
   Null = r1 + r2;
   if NZ jump hs_mgdc_update_done;
      r0 = 1;                          //MGDC_update = 1;
      r2 = 2;
      r1 = M[$M.CVC.data.mgdc100_obj + $mgdc100.PTR_OMS_VAD_FIELD];
      r1 = M[r1];
      if Z r0 = r2;                //MGDC_update = 2;
   hs_mgdc_update_done:
   M[$M.CVC.data.mgdc100_obj + $mgdc100.MGDC_UPDATE_FIELD] = r0; //save  MGDC_update

   // SYS_DMSS_MODE control
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.DMSS_MODE;
   rts;

// -----------------------------------------------------------------------------
// ASF module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.asf100:
   // if (DMSS_Mode_t == 0) && ASF_on
   //      ASF
   // end

   // ASF bypass control
   r0 = M[$cvc.asf_bypassed];
   if NZ rts;

   // DMSS mode
   jump $cvc.mc.dmss_mode;
   
// -----------------------------------------------------------------------------
// ADF module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.adf200:
   // if (DMSS_Mode_t == 0) && ADF_on
   //      ADF
   // end

   // ADF bypass control
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_ADF;
   if NZ rts;

   // DMSS mode
   r0 = M[$cvc.dmss_mode];
   if NZ rts;

   // power up hold
   jump $cvc.mc.powerup_detect;

// -----------------------------------------------------------------------------
// NC module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.nc100:
   // if (DMSS_Mode_t == 0) && NC_on && ~Wind_Flag
   //      NC
   // end

   // NC bypass control
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_NC;
   if NZ rts;

   // Wind_Flag
   r0 = M[&$M.CVC.data.asf_object + $asf100.wnr.WIND_FIELD];
   if NZ rts;

   // DMSS mode
   jump $cvc.mc.dmss_mode;

// -----------------------------------------------------------------------------
// DMS100 module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.dms100:
   r0 = M[$cvc.bypass_dms];
   rts;

$cvc.mc.dms_out:
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.CVC_HEADSET_2MIC.DMSS_CONFIG.BYPASS_DMS;
   rts;

// -----------------------------------------------------------------------------
// Global mode control
// -----------------------------------------------------------------------------
$cvc.mc.dmss_mode:
   // CVC dmss_mode control
   // module bypassed if dmss_mode == 1 (one of the channel is lost)
   r0 = M[$cvc.dmss_mode];
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.vad_hold.process
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
//    r7 - Pointer to the data structure
//
// OUTPUTS:
//    VAD_AGC flag

// *****************************************************************************
.MODULE $M.vad_hold.process;
   .CODESEGMENT PM;

func:
   r0 = M[r7 + $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD];
   r0 = M[r0]; // VAD status
   r1 = M[r7 + $M.CVC.vad_hold.PTR_EVENT_FLAG_FIELD];
   r1 = M[r1]; // event status
   r2 = M[r7 + $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD]; // count
   r3 = M[r7 + $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD]; 
   r3 = M[r3]; // reset value

   // update hold counter
   r2 = r2 - 1;
   if NEG r2 = 0;
   Null = r1; 
   if NZ r2 = r3;
   M[r7 + $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD] = r2;
   if NZ r0 = Null; // dont allow VAD to activate until countdown competed
   M[r7 + $M.CVC.vad_hold.FLAG_FIELD] = r0;
   rts;

.ENDMODULE;



