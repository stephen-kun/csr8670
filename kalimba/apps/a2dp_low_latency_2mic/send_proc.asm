// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change:  $  $DateTime:  $
// *****************************************************************************
// *****************************************************************************
// CVC 2mic send processing
//
// Configuration : 
//      Echo and Noise reduction processing @ 16kHz
//      Parameter tuning through UFE
// 
// Interface points :
//      stream_map_left_adc
//      stream_map_right_adc
//      stream_map_refin
//      stream_map_sndout    
// NOTES
//    CVC is comprised of the following processing modules:
//     - AEC (Acoustic Echo Canceller) applied to SCO output
//     - AGC (Automatic Gain Control) applied to SCO output
//     - NS (Noise Suppression) applied to SCO output
//     - NDVC (Noise Dependent Volume Control) applied to DAC output
//     - SCO out parametric equalizer
//     - ADC in DC-Block filters
//
//    These modules can be included/excluded from the build using define the
//    define statements in a2dp_low_latency_2mic_config.h
// *****************************************************************************
// *****************************************************************************
#include "stack.h"
#include "timer.h"
#include "frame_codec.h"
#include "cbops_multirate_library.h"
#include "cvc_modules.h"
#include "a2dp_low_latency_2mic.h"
#include "cvc_system_library.h"
#include "frame_sync_buffer.h"
#include "cbuffer.h"
#include "frame_sync_tsksched.h"
#include "frame_sync_stream_macros.h"
#include "fft_twiddle.h"
#include "operators\iir_resamplev2\iir_resamplev2_header.h"
#include "audio_proc_library.h"
#include "mips_profile.h"

#define MAX_NUM_PEQ_STAGES             (5)

#define USE_FLASH_ADDR_TABLES
#ifdef USE_FLASH_ADDR_TABLES
      #define ADDR_TABLE_DM DMCONST
#else
   #define ADDR_TABLE_DM DM
#endif

// Generate build error messages if necessary.
#if !uses_SND_NS
   #if uses_AEC
      .error "AEC cannot be enabled without SND_NS"
   #endif
#endif

.CONST $SND_IN_LEFT_JITTER           500; 
.CONST $SND_IN_RIGHT_JITTER          500; 
.CONST $REF_IN_JITTER                100; 
.CONST $SND_OUT_JITTER               1000;     
// *****************************************************************************
// MODULE:
//    $M.CVC_VERSION_STAMP
//
// DESCRIPTION:
//    This data module is used to write the CVC algorithm ID and build version
//    into the kap file in a readable form.
// *****************************************************************************
.MODULE $M.CVC_MODULES_STAMP;
   .DATASEGMENT DM;
   .BLOCK ModulesStamp;
      .VAR  s1 = 0xfeeb;
      .VAR  s2 = 0xfeeb;
      .VAR  s3 = 0xfeeb;
      .VAR  CompConfig = A2DP_LOW_LATENCY_2MIC_CONFIG_FLAG;
      .VAR  s4 = 0xfeeb;
      .VAR  s5 = 0xfeeb;
      .VAR  s6 = 0xfeeb;
   .ENDBLOCK;
.ENDMODULE;

.MODULE $M.CVC_VERSION_STAMP;
   .DATASEGMENT DM;
   .BLOCK VersionStamp;
   .VAR  h1 = 0xfebeef;
   .VAR  h2 = 0x01beef;
   .VAR  h3 = 0xbeef;
   .VAR  SysID = $A2DP_LOW_LATENCY_2MIC_SYSID;
   .VAR  BuildVersion = $CVC_VERSION;
   .VAR  h4 = 0xccbeef;
   .VAR  h5 = 0xbeef;
   .VAR  h6 = 0xbeef;
   .ENDBLOCK;
.ENDMODULE;

// *****************************************************************************
.MODULE $M.CVC.data;
   .DATASEGMENT DM;

   // Temp Variable to handle disabled modules.
   .VAR  ZeroValue = 0;
   .VAR  OneValue  = 1.0;
   .VAR  MinusOne  = -1;
   
   // These lines write module and version information to the kap file.
   .VAR kap_version_stamp = &$M.CVC_VERSION_STAMP.VersionStamp;
   .VAR kap_modules_stamp = &$M.CVC_MODULES_STAMP.ModulesStamp;

   // Default Block
   .VAR/DMCONST16  DefaultParameters_wb[] =
        #include "a2dp_low_latency_2mic_defaults_FA2M.dat"
   ;
   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.STRUCT_SIZE)];

//  ******************  Define circular Buffers ********************************
   .VAR/DM1     ref_delay_buffer[Max_RefDelay_Sample];
   .VAR/DM2     fft_circ[FFT_BUFFER_SIZE];

#if uses_IN0_OMS
   .VAR/DM1 in0oms_LpX_queue[$M.oms270.QUE_LENGTH];
#endif

//  ******************  Define Scratch/Shared Memory ***************************

    // Frequency Domain Shared working buffers
   .BLOCK/DM1   FFT_DM1;
      .VAR  X_real[$M.CVC.Num_FFT_Freq_Bins];  
      .VAR  D_l_real[$M.CVC.Num_FFT_Freq_Bins];
      .VAR  D_r_real[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2 FFT_DM2;
      .VAR  X_imag[$M.CVC.Num_FFT_Freq_Bins];
      .VAR  D_l_imag[$M.CVC.Num_FFT_Freq_Bins];
      .VAR  D_r_imag[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

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

   .BLOCK/DM1  $M.dm1_scratch;
      .VAR  W_ri[2 * $M.CVC.Num_FFT_Freq_Bins +1];    // real,imag interlaced
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

   // Scratch memory sharing, making sure that the 
   // actual size of the memory is enough for each module
#define oms_scratch              $M.dm1_scratch
#define dms_scratch              $M.dm1_scratch
#define adf200_scratch_dm1       $M.dm1_scratch
#define adf200_scratch_dm2       $M.dm2_scratch
#define asf100_scratch_dm1       $M.dm1_scratch
#define asf100_scratch_dm2       $M.dm2_scratch
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
#endif  

// ***************  Common Test Mode Control Structure *************************
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

#if uses_RCV_VAD
   .VAR/DM rcv_vad_peq[PEQ_OBJECT_SIZE(3)] =
      &stream_map_refin,                     // PTR_INPUT_DATA_BUFF_FIELD
      &vad_peq_output,                       // INPUT_CIRCBUFF_SIZE_FIELD
      3,                                     // MAX_STAGES_FIELD
      CVC_VAD_PEQ_PARAM_PTR,                 // PARAM_PTR_FIELD

      0 ...;

   // RCV VAD
   .VAR/DM1 rcv_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,     // INPUT_PTR_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC, // Parameter Ptr
        0 ...;
#endif

// ************************  Send Side Processing   **************************

// OMS requires 3 frames for harmonicity (window is only 2 frame)
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

   // Analysis for AEC Reference
   .VAR/DM2  bufd_aec_inp[$M.CVC.Num_FFT_Window];

   .VAR/DM1 AecAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_refin,               // CH1_PTR_FRAME
      &bufd_aec_inp,                   // OFFSET_PTR_HISTORY
      0,                               // OFFSET_BEXP
      &X_real,                         // OFFSET_PTR_FFTREAL
      &X_imag,                         // OFFSET_PTR_FFTIMAG
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_REF_DELAY,  //OFFSET_DELAY_PTR
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
               &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MGDC_MAXCOMP,   // PARAM_FIELD
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
        0,                      // $M.oms270.PTR_INP_X_FIELD (Harmonicity not used)
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
         &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMS_AGGR,        // PARAM_FIELD
         &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC,    // PTR_POWR_ADJUST_FIELD
         &$cvc.dmss_mode,        // PTR_DMS_MODE_FIELD
         &spp,                   // SPP_FIELD
         0 ...;
#endif 

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
      &D_l_real,                          // OFFSET_D_REAL_PTR
      &D_l_imag,                          // OFFSET_D_IMAG_PTR
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
      &$AEC_500.Const,                      // OFFSET_CONST_DM1
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
      CVC_AEC_PTR_NZ_TABLES,                // OFFSET_PTR_NZ_TABLES
      &Cng_Nz_Shape_Tab,                    // OFFSET_PTR_CUR_NZ_TABLE
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
      &$M.CVC_SYS.CurCallState,             // OFFSET_CALLSTATE_PTR
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
      $M.A2DP_LOW_LATENCY_2MIC.CALLST.MUTE;     // OFFSET_MUTE_VAL

#if uses_SND_PEQ
   // Parameteric EQ
   .VAR/DM2 snd_peq_dm2[PEQ_OBJECT_SIZE(MAX_NUM_PEQ_STAGES)] =
      &stream_map_sndout,             // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndout,             // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,             // MAX_STAGES_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG,  // PARAM_PTR_FIELD
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
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME,    // HOLD_TIME_FRAMES_FIELD
      0 ...;                              //HOLD_COUNTDOWN_FIELD

   .VAR vad_noise_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &$cvc.snd_agc_vad,                  // PTR_VAD_FLAG_FIELD
      &$cvc.snd_agc_vad_reverse,          // PTR_EVENT_FLAG_FIELD
      0,                                  // FLAG_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_NOISE_HOLD_TIME,    // HOLD_TIME_FRAMES_FIELD
      0 ...;                              //HOLD_COUNTDOWN_FIELD 
#endif

   // SND AGC Pre-Gain stage
   .VAR/DM1 out_gain_dm1[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndout,                               // OFFSET_INPUT_PTR
      &stream_map_sndout,                               // OFFSET_OUTPUT_PTR
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA, // OFFSET_PTR_MANTISSA
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT; // OFFSET_PTR_EXPONENT

#if uses_SND_AGC
   // SND AGC
   .VAR/DM snd_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      0,                   //OFFSET_BYPASS_BIT_MASK_FIELD
      0,                   // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
      &stream_map_sndout,  //OFFSET_PTR_INPUT_FIELD
      &stream_map_sndout,  //OFFSET_PTR_OUTPUT_FIELD
      &vad_noise_hold + $M.CVC.vad_hold.FLAG_FIELD, //OFFSET_PTR_VAD_VALUE_FIELD,
      0x7FFFFF,            //OFFSET_HARD_LIMIT_FIELD
      0,                   //OFFSET_PTR_TONE_FLAG_FIELD
      0 ...;
#endif

   .VAR mic_in_l_pk_dtct[] =
      &stream_map_left_adc,            // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL_PTR

   .VAR mic_in_r_pk_dtct[] =
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
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_MIC_DISTANCE, // PARAM_FIELD 
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC,     // PTR_POWR_ADJUST_FIELD
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

   // --------------------------------------------------------------------------
   // Parameter to Module Map
   .VAR/ADDR_TABLE_DM   ParameterMap[] =

#if uses_AEC
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CNG_Q,             &aec_dm1 + $M.AEC_500.OFFSET_CNG_Q_ADJUST,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CNG_SHAPE,         &aec_dm1 + $M.AEC_500.OFFSET_CNG_NOISE_COLOR,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DTC_AGGR,          &aec_dm1 + $M.AEC_500.OFFSET_DTC_AGRESSIVENESS,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE,  &aec_dm1 + $M.AEC_500.OFFSET_ENABLE_AEC_REUSE,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG,        &aec_dm1 + $M.AEC_500.OFFSET_CONFIG,
#endif

#if uses_AEC
      // HD threshold
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN,    &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,
#endif

#if uses_DITHER
      // Update both the stereo and mono operators with the noise shape field
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE,&$M.system_config.data.dithertype,
#endif

#if uses_STEREO_ENHANCEMENT
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG,           &$M.system_config.data.stereo_3d_obj + 9,//$stereo_3d_enhancement.SE_CONFIG_FIELD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_REFLECTION_DELAY, &$M.system_config.data.stereo_3d_obj + 10,//$stereo_3d_enhancement.REFLECTION_DELAY_SAMPLES_FIELD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SE_MIX,           &$M.system_config.data.stereo_3d_obj + 11,//$stereo_3d_enhancement.MIX_FIELD,
#endif

#if uses_COMPANDER
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG,                  &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG,                  &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1,     &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1,     &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1,     &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1,      &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC1,         &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAKEUP_GAIN1,            &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2,     &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2,     &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2,     &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2,      &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC2,         &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAKEUP_GAIN2,            &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
#endif

     // End of Parameter Map
      0;

   // Statistics from Modules sent via SPI
   // -------------------------------------------------------------------------------
   .VAR/ADDR_TABLE_DM  StatisticsPtrs[] = //[$M.A2DP_LOW_LATENCY_2MIC.STATUS.BLOCK_SIZE+2] =
      $M.A2DP_LOW_LATENCY_2MIC.STATUS.BLOCK_SIZE,
      &StatisticsClrPtrs,
      // Statistics
      &$M.CVC_SYS.cur_mode,                             // $M.A2DP_LOW_LATENCY_2MIC.STATUS.CUR_MODE_OFFSET
      &$M.CVC_SYS.SysControl,                           // $M.A2DP_LOW_LATENCY_2MIC.STATUS.SYS_CONTROL_OFFSET
      &$M.ConfigureSystem.PeakMipsTxFunc,               // $M.A2DP_LOW_LATENCY_2MIC.STATUS.FUNC_MIPS_OFFSET
      &$M.back_end.PeakMipsDecoder,                     // $M.A2DP_LOW_LATENCY_2MIC.STATUS.DECODER_MIPS_OFFSET
      &$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, // FOR PEAK_PCMINL_OFFSET 
	  &$M.system_config.data.pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, // FOR PEAK_PCMINR_OFFSET 
      &$M.system_config.data.dac_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,   // FOR PEAK_DACL_OFFSET 
	  &$M.system_config.data.dac_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,   // FOR PEAK_DACR_OFFSET 
      &ZeroValue,                                       // FOR PEAK_SUB_OFFSET 
      &$M.CVC_SYS.CurDAC,                               // $M.A2DP_LOW_LATENCY_2MIC.STATUS.CUR_DAC_OFFSET
#ifdef uses_USER_EQ
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG,// USER_EQ_BANK_OFFSET 
#else
      &ZeroValue,
#endif                  
      
      &$M.CVC_MODULES_STAMP.CompConfig,                 // $M.A2DP_LOW_LATENCY_2MIC.STATUS.COMPILED_CONFIG
     
#ifdef LATENCY_REPORTING
      &$M.configure_latency_reporting.average_latency,
#else 
      &MinusOne,
#endif   

      &$M.set_plugin.codec_type,                        // CODEC_TYPE_OFFSET 
      &ZeroValue,                                       // CODEC_FS_OFFSET 
      &ZeroValue,                                       // CODEC_CHANNEL_MODE
      &ZeroValue,                                       // CODEC_STAT1
      &ZeroValue,                                       // CODEC_STAT2
      &ZeroValue,                                       // CODEC_STAT3
      &ZeroValue,                                       // CODEC_STAT4
      &ZeroValue,                                       // CODEC_STAT5
      &ZeroValue,                                       // INTERFACE_TYPE
      &ZeroValue,                                       // INPUT_RATE
      &ZeroValue,                                       // OUTPUT_RATE
      &$M.set_codec_rate.current_codec_sampling_rate,   // CODEC_RATE
      &$M.CVC_SYS.CurCallState,                         // $M.CVC_HEADSET_2MIC.STATUS.CALL_STATE_OFFSET
      &$M.CVC_SYS.SecStatus,                            // $M.A2DP_LOW_LATENCY_2MIC.STATUS.SEC_STAT_OFFSET
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, //PEAK_ADC_LEFT_OFFSET
	  &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, //PEAK_ADC_RIGHT_OFFSET
      &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL, //PEAK_SCO_OUT_OFFSET
      &$M.Sleep.Mips,                                   // $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_MIPS_OFFSET
      &ZeroValue,                                       // PEAK_AUX_OFFSET
      &$M.CVC_SYS.ConnectStatus,                        // $M.A2DP_LOW_LATENCY_2MIC.STATUS.CONNSTAT
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN,  // SIDETONE_GAIN
      &ZeroValue,                                       // VOLUME
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,       // SIDETONE_PEAK
#if uses_SND_AGC
      &snd_agc400_dm + $M.agc400.OFFSET_INPUT_LEVEL_FIELD,   // AGC Speech Power Level
      &snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD,        // AGC Applied Gain
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
      &asf_object + $asf100.wnr.WIND_FIELD;
#else
      &ZeroValue,
      &ZeroValue, 
      &ZeroValue;
#endif

// Clear These statistics
.VAR/ADDR_TABLE_DM StatisticsClrPtrs[] =
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.dac_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.dac_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,
      0;

   // Processing Tables
   // ----------------------------------------------------------------------------
   .VAR/DM ReInitializeTable[] =

      // Function                                     r7                r8

#if !defined(uses_FBADM)
      $filter_bank.one_channel.analysis.initialize,   &fft_obj,         &fba_left,
      $filter_bank.one_channel.analysis.initialize,   &fft_obj,         &fba_right,
#else
      $filter_bank.two_channel.analysis.initialize,   &fft_obj,         &fba_dm,
#endif
      $filter_bank.one_channel.synthesis.initialize,  &fft_obj,         &SndSynthesisBank,

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

#if uses_DCBLOCK
      $audio_proc.peq.initialize,         &in_l_dcblock_dm2,        0,
      $audio_proc.peq.initialize,         &in_r_dcblock_dm2,        0,
#endif

#if uses_SND_PEQ
      $audio_proc.peq.initialize,     &snd_peq_dm2,             0,
#endif

#if uses_RCV_VAD
      $audio_proc.peq.initialize,          &rcv_vad_peq,             0,
      $M.vad400.initialize.func,           &rcv_vad400,              0,
#endif

#if uses_IN0_OMS
      $oms270.initialize,                             0,                &oms270in0_obj,
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

#if uses_STEREO_ENHANCEMENT
    $stereo_3d_enhancement.initialize,                0,                &$M.system_config.data.stereo_3d_obj,
#endif

#ifdef uses_SPKR_EQ
    $receive_proc.peq.initialize,      &$M.system_config.data.spkr_eq_left_dm2,    &$M.system_config.data.spkr_eq_bank_select,
    $receive_proc.peq.initialize,      &$M.system_config.data.spkr_eq_right_dm2,   &$M.system_config.data.spkr_eq_bank_select,
#endif

#ifdef uses_BASS_BOOST
    $receive_proc.peq.initialize,      &$M.system_config.data.boost_eq_left_dm2,   &$M.system_config.data.boost_eq_bank_select,
    $receive_proc.peq.initialize,      &$M.system_config.data.boost_eq_right_dm2,  &$M.system_config.data.boost_eq_bank_select,
#endif

#ifdef uses_USER_EQ
    $receive_proc.peq.initialize,      &$M.system_config.data.user_eq_left_dm2,    &$M.system_config.data.user_eq_bank_select,
    $receive_proc.peq.initialize,      &$M.system_config.data.user_eq_right_dm2,   &$M.system_config.data.user_eq_bank_select,
#endif

#if uses_COMPANDER
    $receive_proc.cmpd100.initialize,  &$M.system_config.data.cmpd100_obj_44kHz,   &$M.system_config.data.cmpd100_obj_48kHz,
#endif

#if uses_NC
      $nc100.initialize,                              0,                &nc100_obj,
#endif

      $cbops.sidestone_filter_op.InitializeFilter,     &$M.adc_in.sidetone_copy_op.param,  0,
      $cvc.mc.reset,                                  0,                0,

      0;                                    // END OF TABLE
// -----------------------------------------------------------------------------
   // Table of functions for current mode
   .VAR  ModeProcTableSnd[$M.A2DP_LOW_LATENCY_2MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsSnd,              // undefined state
      &copy_proc_funcsSnd,              // pass-thru left mode
      &copy_proc_funcsSnd,              // pass-thru right mode
      &hfk_proc_funcsSnd,      		    // hfk mode
      &hfk_proc_funcsSnd;               // low volume mode
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
 .VAR/DM hfk_proc_funcsSnd[] =
      // Function                               r7                   r8

      $frame_sync.distribute_streams_ind,       &snd_process_streams,0,

#if uses_RCV_VAD
      $audio_proc.peq.process,                  &rcv_vad_peq,           0,
      $M.vad400.process.func,                   &rcv_vad400,            0,
      $cvc.mc.echo_detect,                      0,                      0,
#endif

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

#if uses_AEC
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
   // -------------------------------------------------------------------------------

   .VAR/DM copy_proc_funcsSnd[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,       &snd_process_streams,  0,

      $cvc_Set_PassThroughGains,                &ModeControl,         0,

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_l_pk_dtct,            0,    // Si_L
      $M.audio_proc.peak_monitor.Process.func,  &mic_in_r_pk_dtct,            0,    // Si_R
      $M.audio_proc.stream_mixer.Process.func,  &adc_mixer,                   0,    // Si_L,Si_R --> So
      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,     0,

      $frame_sync.update_streams_ind,           &snd_process_streams,  0,
      0;                                     // END OF TABLE

// ***************  Stream Definitions  ************************/

// reference stream map
   .VAR	stream_map_refin[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.dac_out.Reference.cbuffer_struc,      // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.DAC_Num_Samples_Per_Frame,         // $framesync_ind.FRAME_SIZE_FIELD
      $REF_IN_JITTER,                           // $framesync_ind.JITTER_FIELD     [--CONFIG--]
      $frame_sync.distribute_sync_stream_ind,   // Distribute Function
      $frame_sync.update_sync_streams_ind,      // Update Function
      &stream_map_left_adc,                     // $framesync_ind.SYNC_POINTER_FIELD
      2,                                        // $framesync_ind.SYNC_MULTIPLIER_FIELD
      0 ...;
    // Constant links.  Set in data objects
    // &ref_downsample_dm1 +  $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    // &ref_downsample_dm1 +  $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,
    // &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,

   // sndin stream map
   .VAR stream_map_left_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.adc_in.audio_in_left_cbuffer_struc,   // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      $SND_IN_LEFT_JITTER,                      // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
    //  Constant links.  Set in data objects
    //  &in_l_dcblock_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &in_l_dcblock_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &fba_left + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &adc_mixer + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH1_PTR,
	//  &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

   // sndin right stream map
   .VAR stream_map_right_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.adc_in.audio_in_right_cbuffer_struc,  // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      $SND_IN_RIGHT_JITTER,                     // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
    //  Constant links.  Set in data objects
    //  &in_r_dcblock_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &in_r_dcblock_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &fba_right + $M.filter_bank.Parameters.OFFSET_PTR_FRAME,
    //  &adc_mixer + $M.audio_proc.stream_mixer.OFFSET_INPUT_CH2_PTR,
	//  &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

   // sndout stream map 
   .VAR	stream_map_sndout[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.a2dp_out.encoder_in_cbuffer_struc,    // $framesync_ind.CBUFFER_PTR_FIELD     [---CONFIG---]
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      $SND_OUT_JITTER,                          // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_output_stream_ind, // Distribute Function
      $frame_sync.update_output_streams_ind,    // Update Function
      0 ...;
    //  Constant links.  Set in data objects
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

   // -----------------------------------------------------------------------------

// Stream List for Send Processing
.VAR/ADDR_TABLE_DM    snd_process_streams[] =
   &stream_map_left_adc,
   &stream_map_right_adc,
   &stream_map_refin,
   &stream_map_sndout,
   0;

.ENDMODULE; // End of $M.CVC.data
// *****************************************************************************
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
// DESCRIPTION: Response to persistence load request
// r2 = length of persistence block
// r3 = address of persistence block
// *****************************************************************************
.MODULE $M.2mic.LoadPersistResp;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

.VAR persistent_mgdc = 0;
.VAR persistent_agc  = 0x20000;

.CONST $CVC_2MIC_PERSIST_MGDC_OFFSET   0;
.CONST $CVC_2MIC_PERSIST_AGC_OFFSET    1;
.CONST $CVC_2MIC_PERSIST_LOAD_MSG_SIZE 2; //mgdc + agc

func:
#if uses_ADF 

   Null = r2 - $CVC_2MIC_PERSIST_LOAD_MSG_SIZE;
   if NZ rts; // length must be 2
   r0 = M[r3 + $CVC_2MIC_PERSIST_MGDC_OFFSET];
   r0 = r0 ASHIFT 8; // 16 msb, 8lsbs trucated
   M[persistent_mgdc] = r0;

   // Re-Initialize System
   M[$M.CVC_SYS.AlgReInit] = r2;
   rts;
   
#endif

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.pblock_send_handler
//
// DESCRIPTION:
//    This module periodically sends the persistence block to HSV5 for storage
//
// *****************************************************************************
.MODULE $M.pblock_send_handler;
   .CODESEGMENT PBLOCK_SEND_HANDLER_PM;
   .DATASEGMENT DM;

   .CONST $CVC_2MIC_PERSIST_STORE_MSG_SIZE 3; //sysid + mgdc + agc
   // send the persistence block to the VM @ a 3s interval
   .CONST $TIMER_PERIOD_PBLOCK_SEND_MICROS      3000*1000; //3E6

    // ** allocate memory for timer structures **
   .VAR $pblock_send_timer_struc[$timer.STRUC_SIZE];

$pblock_send_handler:

#if uses_MGDC 

   .VAR persist_data_2mic[3];
   $push_rLink_macro;

   r0 = M[$M.CVC.data.mgdc100_obj + $mgdc100.L2FBPXD_FIELD];
   M[$M.2mic.LoadPersistResp.persistent_mgdc]=r0;

   r0 = M[$pblock_key];
   M[&persist_data_2mic] = r0;

   r0 = M[$M.2mic.LoadPersistResp.persistent_mgdc];
   r0 = r0 ASHIFT -8;                              // to 16-bit, truncate 8 lsbs
   M[&persist_data_2mic + 1] = r0;

   r0 =  M[$M.2mic.LoadPersistResp.persistent_agc];
   r0 = r0 ASHIFT -8;                              // to 16-bit, truncate 8 lsbs
   M[&persist_data_2mic + 2] = r0;

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
#else
   rts;
#endif

.ENDMODULE;

// *****************************************************************************
//
// MODULE:
//    $M.set_mode_gains.func
//
// DESCRIPTION:
//    Sets input gains (ADC) based on the current mode.
//    (Note: this function should only be called from within standy,
//    and pass-through modes).
//
//    MODE              ADC GAIN        
//    pass-through      user specified 
//    standby           zero            
//    loopback          unity           
//
//
// INPUTS:
//    r7 - Pointer to the data structure
//
//   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT       0;
//   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT      1;
//   .CONST   $M.SET_MODE_GAIN.ADC_MIXER_EXP             2;
//   .CONST   $M.SET_MODE_GAIN.STRUC_SIZE                5;
//
// *****************************************************************************

.MODULE $M.set_mode_gains;
    .CODESEGMENT SET_MODE_GAIN_PM;

$cvc_Set_PassThroughGains:
   r1 = &$M.CVC.data.stream_map_sndout;
   // Mixer --> so
   M[&$M.CVC.data.adc_mixer + $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR]=r1;

   r0 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA];
   r5 = r0;
   
   r4 = M[$M.CVC_SYS.cur_mode]; 
   Null = r4 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.PSTHRGH_LEFT;
   if Z r5 = Null;
   if Z jump passthroughgains;
   Null = r4 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.PSTHRGH_RIGHT;
   if Z r0 = Null;
   if Z jump passthroughgains;

   // Standby - Zero Signal 
   r5 = Null;
   r0 = Null;
   r1 = 1;
   jump setgains;
passthroughgains:
   // PassThrough Gains set from Parameters
   r1 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT];
setgains:
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT]    = r0;
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT]   = r5;
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_EXP]          = r1;
   rts;

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

#if uses_SND_AGC
   $cvc.user.agc_snd.process:
   r5 = $cvc.mc.agc_snd;
   r6 = $M.agc400.process.func;
   jump $cvc.module_process;
#endif // uses_SND_AGC

#if uses_AEC

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
   // system_dmss_mode : 0 - Dual Microphone Mode
   //                    1 - Single Microphone Mode
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.DMSS_MODE;
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
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   Null = r0 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDCPERSIST;
   if NZ r1 = Null;
   M[$M.CVC.data.mgdc100_obj + $mgdc100.L2FBPXD_FIELD] = r1;
#endif

#if uses_SND_AGC
   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SNDAGC;
   if Z jump next2;
   r1 = 0;
   M[$M.CVC.data.snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD] = r1;
next2:   
#endif // uses_SND_AGC

#if uses_ASF
   // ASF internal module control
   r2 = M[$cvc.bypass_bf];
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_BF_FIELD] = r2;

   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];

   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_WNR;
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_WNR_FIELD] = r0;
   if Z r2 = 0;

   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_SPP;
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_COH_FIELD] = r0;
   if Z r2 = 0;

   M[$cvc.asf_bypassed] = r2;
#endif

#if uses_SND_NS
   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_SPP;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_SPP_FIELD] = r0;
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NFLOOR;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_NFLOOR_FIELD] = r0;
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_GSMOOTH;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_GSMOOTH_FIELD] = r0;
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.GSCHEME;
   M[$M.CVC.data.dms100_obj + $dms100.GSCHEME_FIELD] = r0;
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
   r2 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r2 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.HDBYP;
   if NZ r1 = 0;
#else
   r1 = 0;
#endif
   M[$cvc.echo_flag] = r1;
   rts;
// -----------------------------------------------------------------------------
// Send AGC bypass and VAD control
// -----------------------------------------------------------------------------
$cvc.mc.agc_snd:
   // if AGCsnd_on ?
   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SNDAGC;
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

   // MGDC disabled?
   call $cvc.mc.mgdc100;

   jump $pop_rLink_and_rts;

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
   Null = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.LOWVOLUME;
   if Z rts;
   // Check if AEC has been enabled globally
   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.AECENA;
   if Z rts;

   // AEC should run
   r0 = 0;
   rts;

// -----------------------------------------------------------------------------
// AEC500 NLP module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.aec500_nlp:
   // AEC_HD_on ?
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.HDBYP;
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
   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.CNGENA;
   if Z rts;
*/

   // AEC_on ?
   jump $cvc.mc.aec500;

// -----------------------------------------------------------------------------
// MGDC module bypass/hold
// -----------------------------------------------------------------------------
$cvc.mc.mgdc100:
   // if (MGDC_on && ~EchoFlag && ~Wind_Flag && ~SYS_DMSS_MODE)
   //    MGDC
   // end

   // MGDC bypass control
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_MGDC;
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
      r1 = M[$M.CVC.data.mgdc100_obj + $mgdc100.PTR_OMS_VAD_FIELD];
      r1 = M[r1];
      if Z r0 = r0 + 1;                //MGDC_update = 2;
   hs_mgdc_update_done:
   M[$M.CVC.data.mgdc100_obj + $mgdc100.MGDC_UPDATE_FIELD] = r0; //save  MGDC_update

   // SYS_DMSS_MODE control
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.DMSS_MODE;
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
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_ADF;
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
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NC;
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
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_DMS;
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
//    $M.App.Codec.Apply
//
// DESCRIPTION:
//    A pointer to this function is passed in via the CVC_data_obj data object.
//    CVC uses the pointer to call this funcion to set the ADC and DAC gains.
//    Most users will probably keep the function as is, sending the
//    $M.CVC.VMMSG.CODEC message to the VM application.  However, this function
//    can be modified to set the gains directly using the BC5MM.
//
// INPUTS:
//    r3 - DAC Gain
//    r4 - ADC Gain
//
//    The DAC Gain is in a form suitable for the VM function CodecSetOutputGainNow.
//    The ADC Gain is the form described by T_mic_gain in csr_cvc_common_if.h
//
// OUTPUTS:
//    sends a CODEC message to the VM application
//
// REGISTER RESTRICTIONS:
//
// CPU USAGE:
//    cycles =
//    CODE memory:    5 words
//    DATA memory:    0  words
//
// *****************************************************************************
.MODULE $M.App.Codec.Apply;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$App.Codec.Apply:
   $push_rLink_macro;

// Low volume mode switching logic
   // r3 = CurDac
   // if (curdac <= LVMODE_THRS)
   //    volstate = SYSMODE.LOWV
   // else
   //    volstate = SYSMODE.FULLPROC;
   // end
   r0 = $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC;
#if uses_VCAEC
   r7 = $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.LOWVOLUME;
   r2 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LVMODE_THRES];
   Null = r2 - r3;
   if POS r0 = r7;
#endif
   M[&$M.CVC_SYS.VolState] = r0;

   // Select ADC gain based on Mode
   r4 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADC_GAIN_LEFT];
   r5 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADC_GAIN_RIGHT];
   r7 = M[$M.CVC_SYS.cur_mode];

//    r3 - DAC Gain
//    r4 - ADC Gain
//
//    The DAC Gain is in a form suitable for the VM function CodecSetOutputGainNow.
//    The ADC Gain is the form described by T_mic_gain in csr_cvc_common_if.h

   // r3=DAC gain r4=ADC gain left  r5=ADC Gain Right
   r2 = $M.CVC.VMMSG.CODEC;
   call $message.send_short;
   jump $pop_rLink_and_rts;
   
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $CVC_AppHandleConfig
//
// DESCRIPTION:
//    Set Config Flag in statistic
//
// *****************************************************************************
.MODULE $M.CVC_AppHandleConfig;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
$CVC_AppHandleConfig:
   // set mic-config bits (passed in r4)
   r1 = M[$M.CVC_MODULES_STAMP.CompConfig];
   r1 = r1 AND (~(flag_uses_R_DIGITAL_MIC));
   r0 = r4 LSHIFT ( round(log2(flag_uses_L_DIGITAL_MIC)) - 1);
   r0 = r0 AND flag_uses_L_DIGITAL_MIC;
   r1 = r1 OR r0;
   r0 = r4 LSHIFT ( round(log2(flag_uses_R_DIGITAL_MIC)));
   r0 = r0 AND flag_uses_R_DIGITAL_MIC;
   r1 = r1 OR r0;
   M[$M.CVC_MODULES_STAMP.CompConfig] = r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.CVC.app.config
//
// DESCRIPTION:
//
// *****************************************************************************
.MODULE $M.CVC.app.config;
   .DATASEGMENT DM; 
   .CONST  $CVC_TWOMIC_HEADSET_SECID     0x651F;   // CVC ID's

   // ** Memory Allocation for CVC config structure
   .VAR CVC_config_struct[$M.CVC.CONFIG.STRUC_SIZE] =
      &$App.Codec.Apply,                           // CODEC_CNTL_FUNC
      &$CVC_AppHandleConfig,                       // CONFIG_FUNC
      $M.2mic.LoadPersistResp.func,                // PERSIS_FUNC
      $CVC_TWOMIC_HEADSET_SECID,                   // SECURITY_ID
      $CVC_VERSION,                                // VERSION
      $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.STANDBY,    // STANDBY_MODE
      $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC,   // HFK_MODE
      $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.MAX_MODES,  // NUMBER of MODES
      $M.A2DP_LOW_LATENCY_2MIC.CALLST.MUTE,        // CALLST_MUTE
      $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.STRUCT_SIZE,  // NUM_PARAMS
      &$M.CVC.data.CurParams,                      // PARAMS_PTR
      &$M.CVC.data.DefaultParameters_wb,           // DEF_PARAMS_PTR
      $A2DP_LOW_LATENCY_2MIC_SYSID,                // SYS_ID
      $M.CVC.BANDWIDTH.WB_FS,                      // SYS_FS
      0,                                           // CVC_BANDWIDTH_INIT_FUNC (n/a)
      &$M.CVC.data.StatisticsPtrs,                 // STATUS_PTR
      &$M.dac_out.auxillary_mix_left_op.param,     // TONE_MIX_PTR
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE; // $M.CVC.CONFIG.PTR_INV_DAC_TABLE
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $ConfigureSystem
//
// DESCRIPTION:
//    Set up the system including Front End, Back End, and Algorithmm Variant
//
// INPUTS:
//    none
// OUTPUTS:
//    none
//
// NOTE:
//    This function is called by $M.cvc_message.LoadParams.func VM message
// *****************************************************************************
.MODULE $M.ConfigureSystem;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
  
   .VAR PeakMipsTxFunc = 0;

   .VAR TxFuncMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
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

   .VAR $cvc_fftbins = $M.CVC.Num_FFT_Freq_Bins;
   .VAR $pblock_key = ($A2DP_LOW_LATENCY_2MIC_SYSID >> 8) | (CVC_SYS_FS/2000); // unique key
   
 .VAR cvc_bandwidth_param_wb[] =
            $M.CVC.BANDWIDTH.WB_FS,             // SYS_FS
            120,                                // Num_Samples_Per_Frame
            129,                                // Num_FFT_Freq_Bins
            240,                                // Num_FFT_Window
            0,                                  // SND_PROCESS_TRIGGER
            &$M.oms270.mode.wide_band.object,            // OMS_MODE_OBJECT
            &$M.AEC_500_WB.LPwrX_margin.overflow_bits,   // AEC_LPWRX_MARGIN_OVFL
            &$M.AEC_500_WB.LPwrX_margin.scale_factor,    // AEC_LPWRX_MARGIN_SCL
            &$M.AEC_500.wb_constants.nzShapeTables,      // AEC_PTR_NZ_TABLES
#if uses_SND_VAD || uses_RCV_VAD
            &$M.CVC.data.vad_peq_parameters_wb,          // VAD_PEQ_PARAM_PTR
#else
            0,
#endif
#if uses_DCBLOCK
            &$M.CVC.data.dcblock_parameters_wb,          // DCBLOC_PEQ_PARAM_PTR
#else
            0,
#endif
            CVC_BANK_CONFIG_HANNING_WB,                  // FB_CONFIG_RCV_ANALYSIS
            CVC_BANK_CONFIG_HANNING_WB,                  // FB_CONFIG_RCV_SYNTHESIS
            CVC_BANK_CONFIG_HANNING_WB,                  // FB_CONFIG_AEC
            // 2mic specific
            $M.CVC.BANDWIDTH.WB_FS/2000,        // BANDWIDTDH_ID
#if uses_ASF
            &$asf100.mode.wide_band,          // $CVC.BW.PARAM.ASF_MODE
#else
            0,
#endif
#if uses_SND_NS
            &$dms100.wide_band.mode,      // $CVC.BW.PARAM.DMS_MODE
#else
            0,
#endif
            0;

$SendProcStart:

   $push_rLink_macro;
   // request persistence
   r0 = $M.CVC.BANDWIDTH.WB_FS/2000;
   r3 = r0 OR ($A2DP_LOW_LATENCY_2MIC_SYSID >> 8);
   M[$pblock_key] = r3;
   r2 = $M.CVC.VMMSG.LOADPERSIST;
   call $message.send_short;
   
   // start timer for persistence block
   r1 = &$pblock_send_timer_struc;
   r2 = $TIMER_PERIOD_PBLOCK_SEND_MICROS;
   r3 = &$pblock_send_handler;
   call $timer.schedule_event_in;
  
   call $ConfigureSystem;

   r8 = &$M.CVC.app.config.CVC_config_struct;
   call $CVC.PowerUpReset;
   call $CVC.Start;

   jump $pop_rLink_and_rts;
   
$ConfigureSystem:
   $push_rLink_macro;

   // select parameter set based on cvc bandwidth
   r6 = &cvc_bandwidth_param_wb;
   
   // Set SCO/USB Frame Size
   r1 = M[r6 + $CVC.BW.PARAM.Num_Samples_Per_Frame];
#if uses_SND_NS
#if !defined(uses_FBADM)
   r2 = M[$M.CVC.data.fba_left + $M.filter_bank.Parameters.OFFSET_PTR_HISTORY];
#else
   r2 = M[$M.CVC.data.fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_PTR_HISTORY];
#endif
   r2 = r2 - r1;
   M[$M.CVC.data.dms100_obj + $M.oms270.PTR_INP_X_FIELD] = r2;
#endif  

   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Freq_Bins];
   M[$cvc_fftbins] = r0;
#if uses_AEC
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_NUM_FREQ_BINS] = r0;
   M[&$M.CVC.data.vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS] = r0;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Window];
#if uses_SND_NS
   M[&$M.CVC.data.dms100_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;
#endif
#if uses_IN0_OMS
   M[&$M.CVC.data.oms270in0_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.OMS_MODE_OBJECT];
#if uses_IN0_OMS
   M[&$M.CVC.data.oms270in0_obj + $M.oms270.PTR_MODE_FIELD] = r0;
#endif
#if uses_SND_NS
   r0 = M[r6 + $CVC.BW.PARAM.DMS_MODE];
   M[&$M.CVC.data.dms100_obj + $M.oms270.PTR_MODE_FIELD] = r0;
#endif
#if uses_AEC
   r0 = M[r6 + $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL];
   r1 = M[r6 + $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL];
   r2 = M[r6 + $CVC.BW.PARAM.AEC_PTR_NZ_TABLES];
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_LPWRX_MARGIN_OVFL] = r0;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_LPWRX_MARGIN_SCL] = r1;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_PTR_NZ_TABLES] = r2;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR];
#if uses_RCV_VAD
   M[&$M.CVC.data.rcv_vad_peq + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
#endif   
#if uses_SND_VAD
   M[&$M.CVC.data.snd_vad_peq + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
#endif
#if uses_DCBLOCK
   r0 = M[r6 + $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR];
   M[&$M.CVC.data.in_l_dcblock_dm2 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
   M[&$M.CVC.data.in_r_dcblock_dm2 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.FB_CONFIG_AEC];
   M[&$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
   M[&$M.CVC.data.SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
#if !defined(uses_FBADM)
   M[&$M.CVC.data.fba_left + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
   M[&$M.CVC.data.fba_right + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
#else
   M[&$M.CVC.data.fba_dm + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
#endif
#if uses_ASF
   r0 = M[r6 + $CVC.BW.PARAM.ASF_MODE];
   M[&$M.CVC.data.asf_object + $asf100.MODE_FIELD] = r0;
#endif

   jump $pop_rLink_and_rts;
 
$SendProcRun:

   $push_rLink_macro;
     
    r0 = &$M.adc_in.audio_in_left_cbuffer_struc;
    call $cbuffer.calc_amount_data;
    Null = r0 - $M.CVC.Num_Samples_Per_Frame;
    if NEG jump $pop_rLink_and_rts;  

    Null = M[$M.CVC_SYS.AlgReInit];
    if NZ call $M.A2DP_LOW_LATENCY_2MIC.SystemReInitialize.func;

    // Update Count for Ping
    r3 = M[$M.CVC_SYS.FrameCounter];
    r3 = r3 + 1;
    M[$M.CVC_SYS.FrameCounter] = r3;
    
      // LowVol Mode switch logic: if (sysmode == SYSMODE.FULLPROC) curmode = VolState
      // This must be done here to timing (jitter) in mode value.
      // Security.ProcessFrame may alter current mode based on security fail
      // or UFE override
      r1 = M[$M.CVC_SYS.SysMode];
      r2 = M[$M.CVC_SYS.VolState];
      Null = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC;
      if Z r1 = r2;
      M[$M.CVC_SYS.cur_mode] = r1;

      r8 = &TxFuncMips_data_block;
      call $M.mips_profile.mainstart;
      
      // Run CVC (send)
      r2 = &$M.CVC.data.ModeProcTableSnd;    
      call $Security.ProcessFrame;
      
      r8 = &TxFuncMips_data_block;
      call $M.mips_profile.mainend;
      
      r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
      M[&PeakMipsTxFunc] = r0;


 // Update Side Tone Filter.   Disable if not HFK or Low-Volume Mode
   r7 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG ];
   r8 = &$M.adc_in.sidetone_copy_op.param;
   r1 = M[$M.CVC_SYS.cur_mode];
   NULL = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC;
   if Z jump jp_sidetone_enabled;
      NULL = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.LOWVOLUME;
      if NZ r7 = Null;
jp_sidetone_enabled:
   M[r8 + $cbops.sidetone_filter_op.OFFSET_ST_CONFIG_FIELD]=r7;
   call $cbops.sidetone_filter_op.SetMode;
    
   jump $pop_rLink_and_rts;
   
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
