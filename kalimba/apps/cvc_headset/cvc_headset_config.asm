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
#include "frame_codec.h"
#include "cvc_modules.h"
#include "cvc_headset.h"
#include "cvc_system_library.h"
#include "cbops_multirate_library.h"
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
#if uses_SND_NS == 0
#if uses_AEC
   #error AEC cannot be enabled without OMS
#endif
#if uses_NSVOLUME
   #error NDVC cannot be enabled without OMS
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
      .VAR  CompConfig = CVC_HEADSET_CONFIG_FLAG;
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
   .VAR  h1 = 0xbeef;
   .VAR  h2 = 0xbeef;
   .VAR  h3 = 0xbeef;
   .VAR  SysID = $CVC_HEADSET_SYSID;
   .VAR  BuildVersion = $CVC_VERSION;
   .VAR  h4 = 0xbeef;
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
       #include "cvc_headset_defaults_wb.dat"
   ;
   .VAR/DMCONST16  DefaultParameters_fe[] =
       #include "cvc_headset_defaults_fe.dat"
   ;
   .VAR/DMCONST16  DefaultParameters_nb[] =
       #include "cvc_headset_defaults_nb.dat"
   ;

   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.CVC_HEADSET.PARAMETERS.STRUCT_SIZE)];
   

//  ******************  Define circular Buffers ************************ 

    // Declare Linear Buffers

    .VAR/DM2 ref_delay_buffer[Max_RefDelay_Sample];
    // SPTBD.  This buffer can be in scratch memory
    .VAR/DM2 fft_circ[FFT_BUFFER_SIZE];

    #if uses_RCV_NS
   .VAR/DM1 rcvLpX_queue[$M.oms270.QUE_LENGTH];
    #endif
    #if uses_SND_NS
   .VAR/DM1 sndLpX_queue[$M.oms270.QUE_LENGTH];
    #endif

   

//  ******************  Define Scratch/Shared Memory ************************ 

    // Frequency Domain Shared working buffers
    .BLOCK/DM1   FFT_DM1;
      .VAR  D_real[$M.CVC.Num_FFT_Freq_Bins];
#if (uses_SND_NS || uses_RCV_FREQPROC)
      .VAR  E_real[$M.CVC.ADC_DAC_Num_FFT_Freq_Bins]; 
#endif
        // X_real has to be immediately after E_real, so we can use it for the 
        // implicit overflow present in BW Extension for NB
      .VAR  X_real[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2 FFT_DM2;
      .VAR  D_imag[$M.CVC.Num_FFT_Freq_Bins];
#if (uses_SND_NS || uses_RCV_FREQPROC)
      .VAR  E_imag[$M.CVC.ADC_DAC_Num_FFT_Freq_Bins]; // shared E and rcv_harm buffer[1]
#endif      
        // X_imag has to be immediately after E_imag, so we can use it for the 
        // implicit overflow present in BW Extension for NB
      .VAR  X_imag[$M.CVC.Num_FFT_Freq_Bins];
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

// AEC
// SPTBD - combine with fft_circ_scratch
#if uses_AEC
    .BLOCK/DM2  $M.dm2_scratch;
         .VAR  Exp_Mts_adapt[2*$M.CVC.Num_FFT_Freq_Bins + 1];
    .ENDBLOCK;
#endif




    // The oms_scratch buffer reuses the AEC buffer to reduce the data memory usage.
#define oms_scratch $M.dm1_scratch
    // The following two scratch buffers for the fft_object
    // reuses the scratch buffer from the AEC module.  This allows
    // reduction in the requirement of data memory for the overall system.
    // To be noted: The same AEC scratch memory is also reused for the
    // OMS270 scratch.
#define fft_real_scratch $M.dm1_scratch
#define fft_imag_scratch $M.dm1_scratch + FFT_BUFFER_SIZE
#define fft_circ_scratch fft_circ


    // The aeq_scratch buffer reuses the AEC buffer to reduce the data memory usage.
#define aeq_scratch $M.dm1_scratch
#define vad_scratch $M.dm1_scratch
   

// ***************  Shared Send & Receive Side Processing **********************

   // Shared Data for CVC modules.
   
   // FFT data object, common to all filter_bank cases
   // The three buffers in this object are temporary to FFT and could be shared
   .VAR fft_obj[$M.filter_bank.fft.STRUC_SIZE] =
      0,
      &fft_real_scratch,
      &fft_imag_scratch,
      &fft_circ_scratch,
      BITREVERSE(&fft_circ_scratch),
      $filter_bank.config.fftsplit_table, // PTR_FFTSPLIT
#if uses_AEQ
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

   .CONST   $M.SET_MODE_GAIN.ADC_MANT                  0;
   .CONST   $M.SET_MODE_GAIN.ADC_EXP                   1;
   .CONST   $M.SET_MODE_GAIN.SCO_IN_MANT               2;
   .CONST   $M.SET_MODE_GAIN.SCO_IN_EXP                3;
   .CONST   $M.SET_MODE_GAIN.STRUC_SIZE                4;
   
   .VAR     ModeControl[$M.SET_MODE_GAIN.STRUC_SIZE];

   .VAR passthru_rcv_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_rcvin,                           // OFFSET_INPUT_PTR
      0,                                           // OFFSET_OUTPUT_PTR  <set in passthrough & loopback>
      &ModeControl + $M.SET_MODE_GAIN.SCO_IN_MANT, // OFFSET_PTR_MANTISSA
      &ModeControl + $M.SET_MODE_GAIN.SCO_IN_EXP;  // OFFSET_PTR_EXPONENT

   .VAR/DM1 passthru_snd_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndin,                        // OFFSET_INPUT_PTR
      0,                                        // OFFSET_OUTPUT_PTR     <set in passthrough & loopback>
      &ModeControl + $M.SET_MODE_GAIN.ADC_MANT, // OFFSET_PTR_MANTISSA
      &ModeControl + $M.SET_MODE_GAIN.ADC_EXP;  // OFFSET_PTR_EXPONENT
      
// ************************  Receive Side Processing   **************************

// SP.  OMS requires 3 frames for harmonicity (window is only 2 frame)
#if uses_RCV_NS 
.CONST $RCV_HARMANCITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
#else
.CONST $RCV_HARMANCITY_HISTORY_EXTENSION  0;
#endif

#if uses_RCV_FREQPROC

    // Analysis Filter Bank Config Block
    .VAR/DM2  bufdr_inp[$M.CVC.Num_FFT_Window + $RCV_HARMANCITY_HISTORY_EXTENSION];
    
   .VAR/DM1 RcvAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_RCVIN,           // OFFSET_CONFIG_OBJECT
      &stream_map_rcvin,               // CH1_PTR_FRAME   
      &bufdr_inp+$RCV_HARMANCITY_HISTORY_EXTENSION, // OFFSET_CH1_PTR_HISTORY
      0,                               // CH1_BEXP
      &D_real,                         // CH1_PTR_FFTREAL
      &D_imag,                         // CH1_PTR_FFTIMAG
      0 ...;                           // No Channel Delay
      
   .VAR/DM2  bufdr_outp[$M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY];

    // Syntheseis Filter Bank Config Block
   .VAR/DM2 RcvSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_RCVOUT,          // OFFSET_CONFIG_OBJECT
      &stream_map_rcvout,              // OFFSET_PTR_FRAME
      &bufdr_outp,                     // OFFSET_PTR_HISTORY
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,
      &E_real,                         // OFFSET_PTR_FFTREAL
      &E_imag,                         // OFFSET_PTR_FFTIMAG
      0 ...;
#endif

#if uses_RCV_NS
   // <start> of memory declared per instance of oms270
   .VAR rcvoms_G[$M.oms270.FFT_NUM_BIN];
   .VAR rcvoms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR rcvoms_state[$M.oms270.STATE_LENGTH];

   .VAR oms270rcv_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,  //$M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HEADSET.CONFIG.RCVOMSENA,
                                // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                      // $M.oms270.HARM_ON_FIELD
        1,                      // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufdr_inp,             // $M.oms270.PTR_INP_X_FIELD
        &D_real,                // $M.oms270.PTR_X_REAL_FIELD
        &D_imag,                // $M.oms270.PTR_X_IMAG_FIELD
        &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,
                                // $M.oms270.PTR_BEXP_X_FIELD
#if uses_AEQ
        &D_real,                // $M.oms270.PTR_Y_REAL_FIELD
        &D_imag,                // $M.oms270.PTR_Y_IMAG_FIELD
#else
        &E_real,                // $M.oms270.PTR_Y_REAL_FIELD
        &E_imag,                // $M.oms270.PTR_Y_IMAG_FIELD
#endif
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
        0 ...;
#endif

   // wmsn: for single kap, FE/BEX only
    .VAR/DM1 dac_upsample_dm1[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
        &stream_map_rcvin,                  // INPUT_PTR_FIELD
        &stream_map_rcvout,                 // OUTPUT_PTR_FIELD
        &$M.iir_resamplev2.Up_2_Down_1.filter, // CONVERSION_OBJECT_PTR_FIELD
        -8,                                    // INPUT_SCALE_FIELD 
        8,                                     // OUTPUT_SCALE_FIELD
        0 ...;


#if uses_DCBLOCK
   .VAR/DM2     sco_dc_block_dm1[PEQ_OBJECT_SIZE(1)] =  // 1 stage
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
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_RCV_PEQ_CONFIG,  // PARAM_PTR_FIELD
      0 ...;
#endif

   // Pre RCV AGC gain stage
   .VAR/DM1 rcvout_gain_dm2[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_rcvout,                       // OFFSET_INPUT_PTR
      &stream_map_rcvout,                       // OFFSET_OUTPUT_PTR
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_RCVGAIN_MANTISSA,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_RCVGAIN_EXPONENT;

#if uses_RCV_VAD
   .VAR/DM2 rcv_vad_peq[PEQ_OBJECT_SIZE(3)] =
      &stream_map_rcvin,                        // PTR_INPUT_DATA_BUFF_FIELD
      &vad_peq_output,                          // PTR_OUTPUT_DATA_BUFF_FIELD
      3,                                        // MAX_STAGES_FIELD
      CVC_VAD_PEQ_PARAM_PTR,                    // PARAM_PTR_FIELD
      0 ...;

   // RCV VAD
   .VAR/DM1 rcv_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,     // INPUT_PTR_FIELD
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC, // Parameter Ptr
      0 ...;
#endif

#if uses_RCV_AGC
   // RCV AGC
   .VAR/DM rcv_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      $M.CVC_HEADSET.CONFIG.RCV_AGCBYP, //OFFSET_BYPASS_BIT_MASK_FIELD
      $M.CVC_HEADSET.CONFIG.BYPASS_AGCPERSIST,   // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_RCV_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
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
      $M.CVC_HEADSET.CONFIG.AEQENA,             // BYPASS_BIT_MASK_FIELD
      $M.CVC_HEADSET.CONFIG.BEXENA,             // BEX_BIT_MASK_FIELD
      $M.CVC.Num_FFT_Freq_Bins,                 // NUM_FREQ_BINS
      0x000000,                                 // BEX_NOISE_LVL_DISABLE
      &D_real,                                  // PTR_X_REAL_FIELD             2
      &D_imag,                                  // PTR_X_IMAG_FIELD             3
      &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_BEXP,   // PTR_BEXP_X_FIELD             4
      &E_real,                                  // PTR_Z_REAL_FIELD             5
      &E_imag,                                  // PTR_Z_IMAG_FIELD             6
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
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LO_GOAL_LOW,    // PTR_GOAL_LOW_FIELD           30
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_HI_GOAL_LOW,    // PTR_GOAL_HIGH_FIELD          31
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BEX_TOTAL_ATT_LOW,  // PTR_BEX_ATT_TOTAL_FIELD      32 wmsn: not used in WB
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BEX_HI2_GOAL_LOW,   // PTR_BEX_GOAL_HIGH2_FIELD     33 wmsn: not used in WB
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

   .VAR sco_in_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_rcvin,           // PTR_INPUT_BUFFER_FIELD
      0;                           // PEAK_LEVEL

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
         &D_real,                                                 // FFT_REAL_OFFSET
         &D_imag,                                                 // FFT_IMAG_OFFSET
         &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,   // SCALE_FACTOR_OFFSET
         &oms270ssr_obj + $M.oms270.VOICED_FIELD,                 // VOICED_OFFSET
         &sndoms_G,                                               // GAIN_OFFSET
         &oms270ssr_obj + $M.oms270.LIKE_MEAN_FIELD,              // LIKE_MEAN_OFFSET
         &sndoms_LpXnz;                                           // LPX_NZ_OFFSET

   .VAR oms270ssr_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,  //$M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HEADSET.CONFIG.SNDOMSENA,
                                // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                      // $M.oms270.HARM_ON_FIELD
        1,                      // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_inp,              // $M.oms270.PTR_INP_X_FIELD
        &D_real,                // $M.oms270.PTR_X_REAL_FIELD
        &D_imag,                // $M.oms270.PTR_X_IMAG_FIELD
        &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
                                // $M.oms270.PTR_BEXP_X_FIELD
        &E_real,                // $M.oms270.PTR_Y_REAL_FIELD
        &E_imag,                // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,               // $M.oms270.INITIAL_POWER_FIELD
        &sndLpX_queue,          // $M.oms270.LPX_QUEUE_START_FIELD
        &sndoms_G,              // $M.oms270.G_FIELD;
        &sndoms_LpXnz,          // $M.oms270.LPXNZ_FIELD,
        &sndoms_state,          // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,      // $M.oms270.ALFANZ_FIELD       SP.  Changed due to frame size
        0xFF13DE,               // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,               // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size  
        0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        1.0,                    // $M.oms270.AGRESSIVENESS_FIELD
        0,                      // $M.oms270.PTR_TONE_FLAG_FIELD
        &rcv_vad400 + $M.vad400.FLAG_FIELD, // $M.oms270.PTR_RCVVAD_FLAG_FIELD
        &snd_vad400 + $M.vad400.FLAG_FIELD, // $M.oms270.PTR_SNDVAD_FLAG_FIELD
        0 ...;


   .VAR/DM1 ssr_muted=$M.CVC_HEADSET.CALLST.MUTE;

   .VAR/DM1 mute_ssr_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,               // OFFSET_INPUT_PTR
      &ssr_muted,                       // OFFSET_PTR_STATE
      $M.CVC_HEADSET.CALLST.MUTE;       // OFFSET_MUTE_VAL
#endif

// SP.  OMS requires 3 frames for harmonicity (window is only 2 frame)
#if uses_SND_NS 
.CONST $SND_HARMANCITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
#else
.CONST $SND_HARMANCITY_HISTORY_EXTENSION  0;
#endif

   .VAR/DM1  bufd_inp[$M.CVC.Num_FFT_Window + $SND_HARMANCITY_HISTORY_EXTENSION];
   .VAR/DM2  bufx_inp[$M.CVC.Num_FFT_Window];
   
   // Analysis Filter Bank Config Block
   .VAR/DM1 AecAnalysisBank[$M.filter_bank.Parameters.TWO_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_sndin,               // CH1_PTR_FRAME
      &stream_map_refin,               // CH2_PTR_FRAME    
      &bufd_inp+$SND_HARMANCITY_HISTORY_EXTENSION,// OFFSET_CH1_PTR_HISTORY
      &bufx_inp,                       // OFFSET_CH2_PTR_HISTORY
      0,                               // CH1_BEXP
      0,                               // CH2_BEXP
      &D_real,                         // CH1_PTR_FFTREAL
      &D_imag,                         // CH1_PTR_FFTIMAG
      &X_real,                         // CH2_PTR_FFTREAL
      &X_imag,                         // CH2_PTR_FFTIMAG
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_REF_DELAY,  //OFFSET_CH2_DELAY_PTR
      &ref_delay_buffer, 			   // OFFSET_CH2_DELAY_BASE
	  &ref_delay_buffer,               // OFFSET_CH2_DELAY_BUF_PTR
      LENGTH(ref_delay_buffer);        // OFFSET_CH2_DELAY_BUF_LEN

   // Syntheseis Filter Bank Config Block
     .VAR/DM1  bufd_outp[($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame)];

   .VAR/DM2 SndSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,             // OFFSET_CONFIG_OBJECT
      &stream_map_sndout,              // OFFSET_PTR_FRAME
      &bufd_outp,                      // OFFSET_PTR_HISTORY
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
#if uses_SND_NS
      &E_real,                         // OFFSET_PTR_FFTREAL
      &E_imag,                         // OFFSET_PTR_FFTIMAG
#else
      &D_real,                         // OFFSET_PTR_FFTREAL
      &D_imag,                         // OFFSET_PTR_FFTIMAG
#endif
      0 ...;


#if uses_SND_NS
   // <start> of memory declared per instance of oms270
   .VAR sndoms_G[$M.oms270.FFT_NUM_BIN];
   .VAR/DM1 sndoms_LpXnz[$M.oms270.FFT_NUM_BIN];
   .VAR sndoms_state[$M.oms270.STATE_LENGTH];

   .VAR oms270snd_obj[$M.oms270.STRUC_SIZE] =
        M_oms270_mode_object,  //$M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        $M.CVC_HEADSET.CONFIG.SNDOMSENA,
                                // $M.oms270.BYPASS_BIT_MASK_FIELD
        1,                      // $M.oms270.MIN_SEARCH_ON_FIELD
        1,                      // $M.oms270.HARM_ON_FIELD
        1,                      // $M.oms270.MMSE_LSA_ON_FIELD
        $M.CVC.Num_FFT_Window,  // $M.oms270.FFT_WINDOW_SIZE_FIELD
        &bufd_inp,              // $M.oms270.PTR_INP_X_FIELD
        &D_real,                // $M.oms270.PTR_X_REAL_FIELD
        &D_imag,                // $M.oms270.PTR_X_IMAG_FIELD
        &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
                                // $M.oms270.PTR_BEXP_X_FIELD
        &E_real,                // $M.oms270.PTR_Y_REAL_FIELD
        &E_imag,                // $M.oms270.PTR_Y_IMAG_FIELD
        0xFF0000,              // $M.oms270.INITIAL_POWER_FIELD
        &sndLpX_queue,          // $M.oms270.LPX_QUEUE_START_FIELD
        &sndoms_G,                 // $M.oms270.G_FIELD;
        &sndoms_LpXnz,             // $M.oms270.LPXNZ_FIELD,
        &sndoms_state,             // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,       // $M.oms270.ALFANZ_FIELD      SP.  Changed due to frame size
        0xFF13DE,               // $M.oms270.LALFAS_FIELD       SP.  Changed due to frame size
        0xFEEB01,               // $M.oms270.LALFAS1_FIELD      SP.  Changed due to frame size  
        0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        1.0,                    // $M.oms270.AGRESSIVENESS_FIELD
        0,                      // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;

   .VAR wnr_obj[$M.oms270.wnr.STRUC_SIZE] =
         &$M.oms270.wnr.initialize.func,  // FUNC_WNR_INIT_FIELD
         &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_WNR_AGGR, // PTR_WNR_PARAM_FIELD
         &rcv_vad400 + $M.vad400.FLAG_FIELD, // PTR_RCVVAD_FLAG_FIELD
         &snd_vad400 + $M.vad400.FLAG_FIELD, // PTR_SNDVAD_FLAG_FIELD
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

   .VAR/DM1 aec_dm1[$M.AEC_500.STRUCT_SIZE] =
      &E_real,                         // OFFSET_E_REAL_PTR
      &E_imag,                         // OFFSET_E_IMAG_PTR
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP, // OFFSET_D_EXP_PTR
      &D_real,                         // OFFSET_D_REAL_PTR
      &D_imag,                         // OFFSET_D_IMAG_PTR
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
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_BEXP, // OFFSET_X_EXP_PTR
      &sndoms_G,                       // OFFSET_OMS1_G_PTR
      &sndoms_LpXnz,                   // OFFSET_OMS1_D_NZ_PTR
      &sndoms_G,                       // OFFSET_oms_adapt_G_PTR
      &sndoms_G,                       // OFFSET_OMS2_G_PTR
      1.0,                             // OFFSET_OMS_AGGRESSIVENESS
      0x200000,                        // OFFSET_CNG_Q_ADJUST
      0x6Ed9eb,                        // OFFSET_CNG_G_ADJUST(unused) 17
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
      $AEC_500.handsfree_dtc_aggressiveness,                // OFFSET_DTC_AGRESS_FUNC_PTR
      $AEC_500.LPwrX_update_handsfree,                        // OFFSET_LPWRX_UPDT_FUNC_PTR
      $M.AEC_500.divergence_control.func,                   // OFFSET_RER_DIVERGE_FUNC_PTR
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

      &Attenuation,                         // OFFSET_SCRPTR_Attenuation
      &L_adaptA,                            // OFFSET_SCRPTR_L_adaptA
      0,                                    // OFFSET_SCRPTR_L_RatSqGt
      -268,                                 // $M.AEC_500.OFFSET_L_DTC 2.0*fs/L
      3,                                    // OFFSET_CNG_NOISE_COLOR (-1=wht,0=brn,1=pnk,2=blu,3=pur)
      CVC_AEC_PTR_NZ_TABLES,                 // OFFSET_PTR_NZ_TABLES
      &Cng_Nz_Shape_Tab,                      // OFFSET_PTR_CUR_NZ_TABLE
      0 ...;
#endif

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
      &Attenuation,                         // OFFSET_SCRPTR_Attenuation
      0 ...;

   // wmsn: for single kap, FE/BEX only
    .VAR/DM1 adc_downsample_dm1[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
        &stream_map_sndin,                  // INPUT_PTR_FIELD
        &stream_map_sndin,                  // OUTPUT_PTR_FIELD
        &$M.iir_resamplev2.Up_1_Down_2.filter,     // CONVERSION_OBJECT_PTR_FIELD
        -8,                                 // INPUT_SCALE_FIELD
        8,                                  // OUTPUT_SCALE_FIELD
        0 ...;


    .VAR/DM1 ref_downsample_dm1[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
        &stream_map_refin,                  // INPUT_PTR_FIELD
        &stream_map_refin,                  // OUTPUT_PTR_FIELD
        &$M.iir_resamplev2.Up_1_Down_2.filter,     // CONVERSION_OBJECT_PTR_FIELD
        -8,                                 // INPUT_SCALE_FIELD
        8,                                  // OUTPUT_SCALE_FIELD
        0 ...;



#if uses_DCBLOCK
   .VAR/DM2 adc_dc_block_dm1[PEQ_OBJECT_SIZE(1)] =     // 1 stage 
      &stream_map_sndin,               // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndin,               // PTR_OUTPUT_DATA_BUFF_FIELD
      1,                               // MAX_STAGES_FIELD
      CVC_DCBLOC_PEQ_PARAM_PTR,        // PARAM_PTR_FIELD
      0 ...;
#endif

   .VAR/DM1 mute_cntrl_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,               // OFFSET_INPUT_PTR
      &$M.CVC_SYS.CurCallState,         // OFFSET_PTR_STATE
      $M.CVC_HEADSET.CALLST.MUTE;       // OFFSET_MUTE_VAL

#if uses_SND_PEQ
   // Parameteric EQ
   .VAR/DM2 snd_peq_dm2[PEQ_OBJECT_SIZE(MAX_NUM_PEQ_STAGES)] =
      &stream_map_sndout,             // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndout,             // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,             // MAX_STAGES_FIELD
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SND_PEQ_CONFIG,  // PARAM_PTR_FIELD
      0 ...;
#endif

   // SND AGC Pre-Gain stage
   .VAR/DM1 out_gain_dm1[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndout,              // OFFSET_INPUT_PTR
      &stream_map_sndout,              // OFFSET_OUTPUT_PTR
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SNDGAIN_MANTISSA,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SNDGAIN_EXPONENT;

#if uses_SND_AGC || uses_SND_NS
   // SND VAD
   .VAR/DM1 snd_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,     // INPUT_PTR_FIELD
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SND_VAD_ATTACK_TC, // Parameter Ptr 
      0 ...;

   .VAR vad_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &snd_vad400 + $M.vad400.FLAG_FIELD, // PTR_VAD_FLAG_FIELD
      &rcv_vad400 + $M.vad400.FLAG_FIELD, // PTR_ECHO_FLAG_FIELD
      0,                                  // FLAG_FIELD
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME,    // HOLD_TIME_FRAMES_FIELD
      0 ...;

#endif

#if uses_SND_AGC
   .VAR/DM2 snd_vad_peq[PEQ_OBJECT_SIZE(3)] =   // 3 stages
      &stream_map_sndout,                       // PTR_INPUT_DATA_BUFF_FIELD
      &vad_peq_output,                          // PTR_OUTPUT_DATA_BUFF_FIELD
      3,                                        // MAX_STAGES_FIELD
      CVC_VAD_PEQ_PARAM_PTR,                    // PARAM_PTR_FIELD
      0 ...;

   // SND AGC
   .VAR/DM snd_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,                   //OFFSET_SYS_CON_WORD_FIELD
      $M.CVC_HEADSET.CONFIG.SND_AGCBYP, //OFFSET_BYPASS_BIT_MASK_FIELD
      0,                                // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SND_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
      &stream_map_sndout,  //OFFSET_PTR_INPUT_FIELD
      &stream_map_sndout,  //OFFSET_PTR_OUTPUT_FIELD
      &vad_hold + $M.CVC.vad_hold.FLAG_FIELD,
                           //OFFSET_PTR_VAD_VALUE_FIELD
      0x7FFFFF,            //OFFSET_HARD_LIMIT_FIELD
      0,                   //OFFSET_PTR_TONE_FLAG_FIELD
      0 ...;
#endif      

#if uses_NSVOLUME
   // NDVC - Noise Controled Volume
   .VAR/DM1 ndvc_dm1[$M.NDVC_Alg1_0_0.BLOCK_SIZE + $M.NDVC_Alg1_0_0.MAX_STEPS] =
      0,                               // OFFSET_CONTROL_WORD
      $M.CVC_HEADSET.CONFIG.NDVCBYP,   // OFFSET_BITMASK_BYPASS
      $M.NDVC_Alg1_0_0.MAX_STEPS,      // OFFSET_MAXSTEPS
      &sndoms_LpXnz,                   // FROM OMS_270 LPXNZ
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_NDVC_HYSTERESIS,  // OFFSET_PTR_PARAMS
      0 ...;
#endif

   .VAR mic_in_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_sndin,               // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL_PTR

   .VAR sco_out_pk_dtct[$M.audio_proc.peak_monitor.STRUCT_SIZE] =
      &stream_map_sndout,              // PTR_INPUT_BUFFER_FIELD
      0;                               // PEAK_LEVEL_PTR

   // -----------------------------------------------------------------------------

   // Parameter to Module Map
   .VAR/ADDR_TABLE_DM   ParameterMap[] =

#if uses_AEC
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_CNG_Q,              &aec_dm1 + $M.AEC_500.OFFSET_CNG_Q_ADJUST,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_CNG_SHAPE,          &aec_dm1 + $M.AEC_500.OFFSET_CNG_NOISE_COLOR,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_DTC_AGGR,           &aec_dm1 + $M.AEC_500.OFFSET_DTC_AGRESSIVENESS,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_ENABLE_AEC_REUSE,   &aec_dm1 + $M.AEC_500.OFFSET_ENABLE_AEC_REUSE,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,         &aec_dm1 + $M.AEC_500.OFFSET_CONFIG,
#endif

#if uses_SND_NS
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,         &oms270snd_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_OMS_HARMONICITY,    &oms270snd_obj + $M.oms270.HARM_ON_FIELD,
   #ifdef uses_SSR
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,         &oms270ssr_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_OMS_HARMONICITY,    &oms270ssr_obj + $M.oms270.HARM_ON_FIELD,
   #endif
#endif

#if uses_RCV_NS
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,         &oms270rcv_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_RCV_OMS_HFK_AGGR,   &oms270rcv_obj + $M.oms270.AGRESSIVENESS_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_OMS_HI_RES_MODE,    &oms270rcv_obj + $M.oms270.HARM_ON_FIELD,
#endif


#if uses_RCV_AGC
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,         &rcv_agc400_dm + $M.agc400.OFFSET_SYS_CON_WORD_FIELD,
#endif

#if uses_NSVOLUME
    &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,           &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_CONTROL_WORD,
#endif

#if uses_SND_AGC
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,         &snd_agc400_dm + $M.agc400.OFFSET_SYS_CON_WORD_FIELD,
#endif

#if uses_AEQ
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,             &AEQ_DataObject + $M.AdapEq.CONTROL_WORD_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_ATK_TC,             &AEQ_DataObject + $M.AdapEq.ALFA_A_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_ATK_1MTC,           &AEQ_DataObject + $M.AdapEq.ONE_MINUS_ALFA_A_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_DEC_TC,             &AEQ_DataObject + $M.AdapEq.ALFA_D_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_DEC_1MTC,           &AEQ_DataObject + $M.AdapEq.ONE_MINUS_ALFA_D_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BEX_NOISE_LVL_FLAGS,    &AEQ_DataObject + $M.AdapEq.BEX_NOISE_LVL_FLAGS,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BEX_LOW_STEP,           &AEQ_DataObject + $M.AdapEq.BEX_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BEX_HIGH_STEP,          &AEQ_DataObject + $M.AdapEq.BEX_PASS_HIGH_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_POWER_TH,           &AEQ_DataObject + $M.AdapEq.AEQ_POWER_TH_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_MIN_GAIN,           &AEQ_DataObject + $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_MAX_GAIN,           &AEQ_DataObject + $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH1,    &AEQ_DataObject + $M.AdapEq.VOL_STEP_UP_TH1_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH2,    &AEQ_DataObject + $M.AdapEq.VOL_STEP_UP_TH2_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOW_STEP,           &AEQ_DataObject + $M.AdapEq.AEQ_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOW_STEP_INV,       &AEQ_DataObject + $M.AdapEq.INV_AEQ_PASS_LOW_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_HIGH_STEP,          &AEQ_DataObject + $M.AdapEq.AEQ_PASS_HIGH_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_HIGH_STEP_INV,      &AEQ_DataObject + $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD,

      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOW_BAND_INDEX,     &AEQ_DataObject + $M.AdapEq.LOW_INDEX_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOW_BANDWIDTH,      &AEQ_DataObject + $M.AdapEq.LOW_BW_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOG2_LOW_BANDWIDTH, &AEQ_DataObject + $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_MID_BANDWIDTH,      &AEQ_DataObject + $M.AdapEq.MID_BW_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOG2_MID_BANDWIDTH, &AEQ_DataObject + $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_HIGH_BANDWIDTH,     &AEQ_DataObject + $M.AdapEq.HIGH_BW_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_LOG2_HIGH_BANDWIDTH,&AEQ_DataObject + $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_MID1_BAND_INDEX,    &AEQ_DataObject + $M.AdapEq.MID1_INDEX_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_MID2_BAND_INDEX,    &AEQ_DataObject + $M.AdapEq.MID2_INDEX_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AEQ_HIGH_BAND_INDEX,    &AEQ_DataObject + $M.AdapEq.HIGH_INDEX_FIELD,
#endif

#if uses_PLC
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_PLC_STAT_INTERVAL,      &$sco_data.object + $sco_pkt_handler.STAT_LIMIT_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG,             &$sco_data.object + $sco_pkt_handler.CONFIG_FIELD,
#endif

      // Auxillary Audio Settings
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_CLIP_POINT,             &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.CLIP_POINT_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BOOST_CLIP_POINT,       &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.BOOST_CLIP_POINT_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_BOOST,                  &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.BOOST_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_SCO_STREAM_MIX,         &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PRIM_GAIN_FIELD,
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_AUX_STREAM_MIX,         &$dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.AUX_GAIN_FIELD,
   
#if uses_AEC
      // HD threshold
      &CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HD_THRESH_GAIN,         &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,
#endif

      // End of Parameter Map
      0;

   // Statistics from Modules sent via SPI
   // ------------------------------------------------------------------------
   .VAR/ADDR_TABLE_DM StatisticsPtrs[] = //$M.CVC_HEADSET.STATUS.BLOCK_SIZE+2] =
      $M.CVC_HEADSET.STATUS.BLOCK_SIZE,
      &StatisticsClrPtrs,
      // Statistics
      &$M.CVC_SYS.cur_mode,
      &$M.CVC_SYS.CurCallState,
      &$M.CVC_SYS.SysControl,
      &$M.CVC_SYS.CurDAC,
      &$M.CVC_SYS.Last_PsKey,
      &$M.CVC_SYS.SecStatus,
      &$dac_out.spkr_out_pk_dtct,
      &mic_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.CVC.app.scheduler.tasks+$FRM_SCHEDULER.TOTAL_MIPS_FIELD,

#if uses_NSVOLUME
      &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_FILTSUMLPDNZ,
      &ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL,
#else
      &ZeroValue,&ZeroValue,
#endif
      $dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PEAK_AUXVAL_FIELD,
      &$M.CVC_MODULES_STAMP.CompConfig,
      &$adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN,
      &$M.CVC_SYS.Volume,
      &$M.CVC_SYS.ConnectStatus,                           // $M.CVC_HEADSET.STATUS.CONNSTAT
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

#if uses_SND_NS
    &wnr_obj + $M.oms270.wnr.POWER_LEVEL_FIELD,         // WNR Power Level (Q8.16 log2 power)
#else
    &OneValue,
#endif
#if uses_AEC
   &aec_dm1 + $M.AEC_500.OFFSET_AEC_COUPLING,
#else
    &$M.CVC.data.ZeroValue,
#endif
    // Resampler related stats - SPTBD - add to XML
    $M.audio_config.audio_if_mode,
    $M.audio_config.adc_sampling_rate,
    $M.audio_config.dac_sampling_rate,
    $M.FrontEnd.frame_adc_sampling_rate;

// Clear These statistics
.VAR/ADDR_TABLE_DM StatisticsClrPtrs[] =
      &$dac_out.spkr_out_pk_dtct,
      &mic_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      $dac_out.auxillary_mix_op.param + $cbops.aux_audio_mix_op.PEAK_AUXVAL_FIELD,
      &$adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,
      0;

   // Processing Tables
   // ----------------------------------------------------------------------------
   .VAR/DM ReInitializeTable[] =

      // Function                                           r7                 r8
      // only for FE/BEX
      $frame.iir_resamplev2.Initialize,                  &adc_downsample_dm1, 0 ,
      $frame.iir_resamplev2.Initialize,                  &ref_downsample_dm1,   0 ,
      $frame.iir_resamplev2.Initialize,                  &dac_upsample_dm1,   0 ,

      $filter_bank.two_channel.analysis.initialize,  &fft_obj,         &AecAnalysisBank,
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


#if uses_SND_NS
      $M.oms270.initialize.func,           &oms270snd_obj,           &wnr_obj,
#endif

#if uses_AEC
      $M.AEC_500.Initialize.func,          &vsm_fdnlp_dm1,           &aec_dm1,
#endif

#if uses_SSR
   $M.oms270.initialize.func,           &oms270ssr_obj,           0,
   $M.wrapper.ssr.initialize,             &asr_obj,                     0,
   $purge_cbuffer,                        &$dac_out.cbuffer_struc,      0,
#endif

#if uses_DCBLOCK
      $audio_proc.peq.initialize,          &adc_dc_block_dm1,        0,
      $audio_proc.peq.initialize,          &sco_dc_block_dm1,        0,
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

#if uses_NSVOLUME
      $M.NDVC_alg1_0_0.Initialize.func,   &ndvc_dm1,                    0,
#endif

#if uses_SND_AGC
      $audio_proc.peq.initialize,         &snd_vad_peq,                 0,
      $M.vad400.initialize.func,          &snd_vad400,                  0,
      $M.agc400.initialize.func,                0,                 &snd_agc400_dm,
#endif


      $cbops.sidestone_filter_op.InitializeFilter,     &$adc_in.sidetone_copy_op.param,  0,

      0;                                    // END OF TABLE

   // -------------------------------------------------------------------------------
   // Table of functions for current mode
   .VAR ModeProcTableSnd[$M.CVC_HEADSET.SYSMODE.MAX_MODES] =
      &copy_proc_funcsSnd,              // undefined state
      &hfk_proc_funcsSnd,               // hfk mode
#if uses_SSR
      &ssr_proc_funcsSnd,               // ssr mode
#else
      &copy_proc_funcsSnd,              // undefined mode
#endif
      &copy_proc_funcsSnd,              // pass-thru mode
      &copy_proc_funcsSnd,              // undefined state
      &copy_proc_funcsLpbk,             // loop-back mode
      &copy_proc_funcsSnd,              // standby-mode
      &hfk_proc_funcsSnd;               // low volume mode
      
   .VAR ModeProcTableRcv[$M.CVC_HEADSET.SYSMODE.MAX_MODES] =
      &copy_proc_funcsRcv,              // undefined state
      &hfk_proc_funcsRcv,               // hfk mode
      &hfk_proc_funcsRcv,               // ssr mode
      &copy_proc_funcsRcv,              // pass-thru mode
      &copy_proc_funcsRcv,              // undefined state
      0,                                // loop-back mode       // SP. Loopback does all processing in Send
      &copy_proc_funcsRcv,              // standby-mode
      &hfk_proc_funcsRcv;               // low volume mode
      

   // -----------------------------------------------------------------------------
   .VAR/DM hfk_proc_funcsRcv[] =
      // Function                               r7                   r8

      $frame_sync.distribute_streams_ind,      &rcv_process_streams,  0,

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &sco_dc_block_dm1,      0,
#endif

      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,        0,

#if uses_RCV_VAD
      $audio_proc.peq.process,                  &rcv_vad_peq,           0,
      $M.vad400.process.func,                   &rcv_vad400,           0,
#endif

#if uses_RCV_FREQPROC
      $filter_bank.one_channel.analysis.process, &fft_obj,   &RcvAnalysisBank,

   #if uses_AEQ
      $M.AdapEq.process.tone_detect,            0,                   &AEQ_DataObject,
   #endif

   #if uses_RCV_NS
      $M.oms270.process.func,                   &oms270rcv_obj,         0,
      $M.oms270.apply_gain.func,                &oms270rcv_obj,         0,
   #endif

   #if uses_AEQ
      $M.AdapEq.process.func,                   0,                   &AEQ_DataObject,
   #endif

      // wmsn: for NB/WB only, not for FE/BEX
      $cvc.non_fe.Zero_DC_Nyquist,              &E_real,              &E_imag,

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
      $M.agc400.process.func,                       0,              &rcv_agc400_dm,
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
      $frame_sync.distribute_streams_ind,      &snd_process_streams,  0,

      // only for FE/BEX
      $cvc.fe.frame_resample_process,         &adc_downsample_dm1, 0 ,
      $cvc.fe.frame_resample_process,         &ref_downsample_dm1, 0 ,

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &adc_dc_block_dm1,      0,
#endif

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_pk_dtct,        0,

      $filter_bank.two_channel.analysis.process, &fft_obj,   &AecAnalysisBank,

#if uses_SND_NS
      $M.oms270.process.func,       			&oms270snd_obj,        	0,  
      $one_mic.send.process,                     0,                     0,
      $M.CVC.Zero_DC_Nyquist.func,              &E_real,             &E_imag,
#else
      $M.CVC.Zero_DC_Nyquist.func,              &D_real,             &D_imag,
#endif

      $filter_bank.one_channel.synthesis.process, &fft_obj,   &SndSynthesisBank,

#if uses_NSVOLUME
      $M.NDVC_alg1_0_0.Process.func,            &ndvc_dm1,                  0,
#endif

#if uses_SND_PEQ
      $audio_proc.peq.process,                  &snd_peq_dm2,               0,
#endif

      $M.audio_proc.stream_gain.Process.func,   &out_gain_dm1,              0,

#if uses_SND_AGC
      $audio_proc.peq.process,                  &snd_vad_peq,               0,
      $M.vad400.process.func,                   &snd_vad400,                0, 
      $M.vad_hold.process.func,                 &vad_hold,               	0,                      
      $M.agc400.process.func,                   0,                   &snd_agc400_dm,
#endif

      $M.MUTE_CONTROL.Process.func,             &mute_cntrl_dm1,            0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,        0,

      $frame_sync.update_streams_ind,            &snd_process_streams, 0,

      0;                                     // END OF TABLE
   

   // -------------------------------------------------------------------------------

#if uses_SSR // Simple Speech Recognition
   .VAR/DM ssr_proc_funcsSnd[] =
      // Function                               r7                      r8
      $frame_sync.distribute_streams_ind,       &snd_process_streams,   0,

      // only for FE/BEX
      $cvc.fe.frame_resample_process,         &adc_downsample_dm1, 0 ,
      $cvc.fe.frame_resample_process,         &ref_downsample_dm1, 0 ,

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &adc_dc_block_dm1,      0,
#endif

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_pk_dtct,        0,

      $filter_bank.two_channel.analysis.process, &fft_obj, &AecAnalysisBank,

#if uses_SND_NS
      $M.oms270.process.func,                   &oms270ssr_obj,         0,
#endif

      // SP.  ASR uses oms data object
      $M.wrapper.ssr.process,                   &asr_obj,                 0,
      
      $M.MUTE_CONTROL.Process.func,             &mute_ssr_dm1,              0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,        0,

      $frame_sync.update_streams_ind,            &snd_process_streams,    0,
      0;                                     // END OF TABLE

#endif

   // -----------------------------------------------------------------------------
   .VAR/DM copy_proc_funcsSnd[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,        &snd_process_streams,  0,
      
      $cvc_Set_PassThroughGains,                &ModeControl,         0, 
      
      // only for FE/BEX
      $cvc.fe.frame_resample_process,         &adc_downsample_dm1, 0 ,

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_pk_dtct,      0,
      $M.audio_proc.stream_gain.Process.func,   &passthru_snd_gain,   0,
      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,     0,
      
      $frame_sync.update_streams_ind,           &snd_process_streams,  0,
      0;                                     // END OF TABLE

   .VAR/DM copy_proc_funcsRcv[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,       &rcv_process_streams,  0,
      
      $cvc_Set_PassThroughGains,                &ModeControl,         0,     
      
      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,      0,
      $M.audio_proc.stream_gain.Process.func,   &passthru_rcv_gain,   0,
      
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

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_pk_dtct,      0,
      $M.audio_proc.peak_monitor.Process.func,  &sco_in_pk_dtct,      0,
	  $M.audio_proc.stream_gain.Process.func,   &passthru_snd_gain,   0,    // si --> ro
      $M.audio_proc.stream_gain.Process.func,   &passthru_rcv_gain,   0,    // ri --> so

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,     0,
      
      $frame_sync.update_streams_ind,           &lpbk_process_streams,  0,
      0;                                     // END OF TABLE
      
 
// ***************  Stream Definitions  ************************/
 
   // reference stream map
   .VAR	stream_map_refin[$framesync_ind.ENTRY_SIZE_FIELD] =
      $dac_out.reference_cbuffer_struc,         // $framesync_ind.CBUFFER_PTR_FIELD     
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.ADC_DAC_Num_Samples_Per_Frame,     // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD     [--CONFIG--]
      $frame_sync.distribute_sync_stream_ind,   // Distribute Function
      $frame_sync.update_sync_streams_ind,      // Update Function
      &stream_map_sndin,                        // $framesync_ind.SYNC_POINTER_FIELD
      1,                                        // $framssync_ind.SYNC_MULTIPLIER_FIELD
      0 ...;
    // SP.  Constant links.  Set in data objects
    //  &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_PTR_FRAME
    //  &ref_downsample_dm1 +  $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //  &ref_downsample_dm1 +  $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,
       
 
   // sndin stream map
   .VAR	stream_map_sndin[$framesync_ind.ENTRY_SIZE_FIELD] =
      $adc_in.cbuffer_struc,                    // $framesync_ind.CBUFFER_PTR_FIELD     
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.ADC_DAC_Num_Samples_Per_Frame,     // $framesync_ind.FRAME_SIZE_FIELD
      3,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function  
      0 ...;        
    // SP.  Constant links.  Set in data objects
    //  &passthru_snd_gain + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //  &adc_dc_block_dm1 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &adc_dc_block_dm1 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &mic_in_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD
    //  &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_FRAME
    //  &adc_downsample_dm1 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //  &adc_downsample_dm1 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,



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
    //  &out_gain_dm1 + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //  &out_gain_dm1 + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR,
    //  &snd_peq_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &snd_peq_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &sco_out_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,
    //  &SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME
    //  &snd_agc400_dm + $M.agc400.OFFSET_PTR_INPUT_FIELD,
    //  &snd_agc400_dm + $M.agc400.OFFSET_PTR_OUTPUT_FIELD,
    //  &mute_cntrl_dm1 + $M.MUTE_CONTROL.OFFSET_INPUT_PTR,
    //  &passthru_snd_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR
    

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
    //    &sco_dc_block_dm1 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //    &sco_dc_block_dm1 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //    &rcv_vad_peq + $audio_proc.peq.INPUT_ADDR_FIELD,
    //    &sco_in_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,
    //    &passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //    &RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME
    //    &dac_upsample_dm1 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD
    //    &passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR
  

    // rcvout stream map
   .VAR  stream_map_rcvout[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$dac_out.cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD     
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.ADC_DAC_Num_Samples_Per_Frame,     // $framesync_ind.FRAME_SIZE_FIELD
      3,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_output_stream_ind, // Distribute Function
      $frame_sync.update_output_streams_ind,    // Update Function
      0 ...;    
    // SP.  Constant links.  Set in data objects
    //      &rcvout_gain_dm2 + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //      &rcvout_gain_dm2 + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR,
    //      &rcv_peq_dm2 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //      &rcv_peq_dm2 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //      &RcvSynthesisBank + $M.filter_bank.Parameters.OFFSET_PTR_FRAME
    //      &rcv_agc400_dm + $M.agc400.OFFSET_PTR_INPUT_FIELD,
    //      &rcv_agc400_dm + $M.agc400.OFFSET_PTR_OUTPUT_FIELD,
    //      &dac_upsample_dm1 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,
    //      &passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR
      
      
   // -----------------------------------------------------------------------------

// Stream List for Receive Processing
.VAR/ADDR_TABLE_DM    rcv_process_streams[] = 
   &stream_map_rcvin, 
   &stream_map_rcvout,
   0;
      
// Stream List for Send Processing
.VAR/ADDR_TABLE_DM    snd_process_streams[] = 
   &stream_map_sndin, 
   &stream_map_refin,
   &stream_map_sndout,
   0;

// Stream List for Loopback Processing
.VAR/ADDR_TABLE_DM    lpbk_process_streams[] = 
   &stream_map_sndin, 
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
   .CODESEGMENT CVC_SSR_UTILITY_PM;
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

#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif
   L0 = 0;

   call $unblock_interrupts;
   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif

#if uses_SND_NS
.MODULE  $one_mic_aec_control;
   .CODESEGMENT PM;

$one_mic.send.process: 
   $push_rLink_macro;
    
#if uses_AEC   
   // AEC Bypassed for LV mode
   r0 = M[$M.CVC_SYS.cur_mode];
   NULL = r0 - $M.CVC_HEADSET.SYSMODE.LOWVOLUME;
   if Z jump byPassAEC;
    
   // Check if AEC has been enabled globally
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.CVC_HEADSET.CONFIG.AECENA;
   if Z jump aec_disabled;    
   
   // AEC function
   r7 = &$M.CVC.data.aec_dm1;
   call $M.AEC_500.fnmls_process.func;

   // half-duplex function
   r7 = &$M.CVC.data.vsm_fdnlp_dm1;
   r8 = &$M.CVC.data.aec_dm1;
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.CVC_HEADSET.CONFIG.HDBYP;
   if Z call $AEC_500.NonLinearProcess;
   
go_cng:
   // Apply CNG (Not for SSR mode)  SPTBD
   r7 = &$M.CVC.data.aec_dm1;
   r0 = M[$M.CVC_SYS.cur_mode];
   NULL = r0 - $M.CVC_HEADSET.SYSMODE.SSR;
   if NZ call $M.AEC_500.comfort_noise_generator.func;   
   jump $pop_rLink_and_rts;

aec_disabled:
   // copy input to output and exit
   r10 = M[$cvc_fftbins];
   I0 = &$M.CVC.data.D_real;
   I4 = &$M.CVC.data.D_imag;
   I1 = &$M.CVC.data.E_real;
   I5 = &$M.CVC.data.E_imag;
   I2 = $M.CVC.data.Attenuation;
   r2 = 0x7FFFFF;
   do copy_buffer;
      r0 = M[I0,1], r1 = M[I4,1];
      M[I1,1] = r0, M[I5,1] = r1;
      M[I2,1] = r2;
   copy_buffer:
   jump go_cng;
#endif

byPassAEC:
    // Apply OMS attenuation    D --> E
    r7 = &$M.CVC.data.oms270snd_obj;
    call $M.oms270.apply_gain.func;  
    jump $pop_rLink_and_rts;
    
.ENDMODULE;
#endif

// Always called for a MODE change
.MODULE $M.CVC_HEADSET.SystemReInitialize;


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
    r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_OMS_AGGR]; 
#if uses_SND_NS
    r1 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_ASR_OMS_AGGR];
    r2 = M[$M.CVC_SYS.cur_mode];
    NULL = r2 - $M.CVC_HEADSET.SYSMODE.SSR;
    if NZ r1=r0;
    M[&$M.CVC.data.oms270snd_obj + $M.oms270.AGRESSIVENESS_FIELD] = r1;
#endif

#if uses_AEC
   // Configure CNG
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS] = r0;
   r1 = $M.AEC_500.CNG_G_ADJUST;
   r0 = M[&$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_HFK_CONFIG];
   r2 = r0 AND ($M.CVC_HEADSET.CONFIG.CNGENA + $M.CVC_HEADSET.CONFIG.AECENA);
   Null = r2 - ($M.CVC_HEADSET.CONFIG.CNGENA + $M.CVC_HEADSET.CONFIG.AECENA);

   if NZ r1 = Null;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_CNG_G_ADJUST] = r1;

   // Configure RER
   r2 = r0 AND $M.CVC_HEADSET.CONFIG.RERENA;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_RER_func] = r2;
  
   // ASR mode needs different initial timer
   r0 = -268;
   r1 = M[$M.CVC_SYS.ssr_aec_initial_adapt];
   r2 = M[$M.CVC_SYS.cur_mode];
   NULL = r2 - $M.CVC_HEADSET.SYSMODE.SSR;
   if Z r0 = r1;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_L_DTC] = r0;
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
     
#if uses_RCV_AGC  
   // refresh from persistence
   r1 = M[$M.1mic.LoadPersistResp.persistent_agc_init];
   M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_PERSISTED_GAIN_FIELD] = r1;
#endif     

   // USB rate match persistence
   // --------------------------

   call $block_interrupts;

   // Load the USB rate match info previously acquired from the persistence store
   r1 = M[$M.1mic.LoadPersistResp.persistent_current_alpha_index];

   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD] = r1;

   r1 = M[$M.1mic.LoadPersistResp.persistent_average_io_ratio];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD] = r1;

   r1 = M[$M.1mic.LoadPersistResp.persistent_warp_value];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD] = r1;

   r1 = M[$M.1mic.LoadPersistResp.persistent_inverse_warp_value];
   M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD] = r1;

   r1 = M[$M.1mic.LoadPersistResp.persistent_sra_current_rate];
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

   .codesegment CVC_ZERO_DC_NYQUIST_PM;

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
//    pass-through      user specified  user specified
//    standby           zero            zero
//    loopback          unity           unity
//
//
// INPUTS:
//    r7 - Pointer to the data structure
//
// *****************************************************************************

.MODULE $M.set_mode_gains;
    .CODESEGMENT SET_MODE_GAIN_PM;
          
$cvc_Set_LoopBackGains: 

   // SP.  Gain si-->ro
   r0 = &$M.CVC.data.stream_map_rcvout;
   M[&$M.CVC.data.passthru_snd_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR] = r0;
   // SP.  Gain ri-->so
   r0 = &$M.CVC.data.stream_map_sndout;
   M[&$M.CVC.data.passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR] = r0;

   // Unity (0 db)
   r0 = 0.5;
   r1 = 1;
   r2 = r0;
   r3 = r1;
   jump setgains; 
   
$cvc_Set_PassThroughGains:   

   // SP.   Gain si-->so
   r0 = &$M.CVC.data.stream_map_sndout;
   M[&$M.CVC.data.passthru_snd_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR] = r0;

   // SP.  Gain in-place.  Resampler is ri-->ri, for FE/BEX
   // SP.  Gain ri-->ro,                         for NB/WB
   r1 = &$M.CVC.data.stream_map_rcvin;
   r2 = &$M.CVC.data.stream_map_rcvout;
   r0 = M[$M.ConfigureSystem.Variant];
   Null = r0 - $M.CVC.BANDWIDTH.FE;
   if NZ r1 = r2;   
   M[&$M.CVC.data.passthru_rcv_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR] = r1;

   r4 = M[$M.CVC_SYS.cur_mode];
   NULL = r4 - $M.CVC_HEADSET.SYSMODE.PSTHRGH;
   if Z jump passthroughgains; 
       // Standby - Zero Signal
       r0 = NULL;
       r1 = 1;
       r2 = r0;
       r3 = r1;
       jump setgains;   
passthroughgains:
   // PassThrough Gains set from Parameters
   r0 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA];
   r1 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT];
   r2 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_PT_RCVGAIN_MANTISSA];
   r3 = M[$M.CVC.data.CurParams + $M.CVC_HEADSET.PARAMETERS.OFFSET_PT_RCVGAIN_EXPONENT];
setgains:
   M[r7 + $M.SET_MODE_GAIN.ADC_MANT]    = r0;
   M[r7 + $M.SET_MODE_GAIN.ADC_EXP]     = r1;
   M[r7 + $M.SET_MODE_GAIN.SCO_IN_MANT] = r2;
   M[r7 + $M.SET_MODE_GAIN.SCO_IN_EXP]  = r3;
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


.CONST $CVC_1MIC_PERSIST_MGDC_OFFSET                              0; // Not used in 1 mic headset (but want a common/compatible pblock)
.CONST $CVC_1MIC_PERSIST_AGC_OFFSET                               1;
.CONST $CVC_1MIC_PERSIST_CURRENT_ALPHA_INDEX_OFFSET               2;
.CONST $CVC_1MIC_PERSIST_AVERAGE_IO_RATIO_HI_OFFSET               3;
.CONST $CVC_1MIC_PERSIST_AVERAGE_IO_RATIO_LO_OFFSET               4;

.CONST $CVC_1MIC_PERSIST_WARP_VALUE_HI_OFFSET                     5;
.CONST $CVC_1MIC_PERSIST_WARP_VALUE_LO_OFFSET                     6;
.CONST $CVC_1MIC_PERSIST_INVERSE_WARP_VALUE_HI_OFFSET             7;
.CONST $CVC_1MIC_PERSIST_INVERSE_WARP_VALUE_LO_OFFSET             8;

.CONST $CVC_1MIC_PERSIST_SRA_CURRENT_RATE_HI_OFFSET               9;
.CONST $CVC_1MIC_PERSIST_SRA_CURRENT_RATE_LO_OFFSET               10;

.CONST $CVC_1MIC_PERSIST_NUM_ELEMENTS                             11; // Number of persistance elements

// *****************************************************************************
// DESCRIPTION: Response to persistence load request
// r2 = length of persistence block / zero for error[?]
// r3 = address of persistence block  
// *****************************************************************************
.MODULE $M.1mic.LoadPersistResp;

   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   // AGC persistence
   .VAR persistent_agc = 0x20000;
   .VAR persistent_agc_init = 0x20000;

   // USB rate match  persistence
   .VAR persistent_current_alpha_index = 0;
   .VAR persistent_average_io_ratio = 0.0;
   .VAR persistent_warp_value = 0.0;
   .VAR persistent_inverse_warp_value = 0.0;
   .VAR persistent_sra_current_rate = 0.0;

func:

   Null = r2 - $CVC_1MIC_PERSIST_NUM_ELEMENTS;
   if NZ rts; // length must be correct

#if uses_RCV_AGC
   r0 = M[r3 + $CVC_1MIC_PERSIST_AGC_OFFSET];
   r0 = r0 ASHIFT 8; // 16 msb, 8lsbs trucated
   M[persistent_agc] = r0;
   M[persistent_agc_init] = r0;
#endif

   // USB rate match persistence
   // --------------------------

   // CURRENT_ALPHA_INDEX
   r0 = M[r3 + $CVC_1MIC_PERSIST_CURRENT_ALPHA_INDEX_OFFSET];
   M[persistent_current_alpha_index] = r0;

   // AVERAGE_IO_RATIO
   r0 = M[r3 + $CVC_1MIC_PERSIST_AVERAGE_IO_RATIO_HI_OFFSET];
   r1 = M[r3 + $CVC_1MIC_PERSIST_AVERAGE_IO_RATIO_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_average_io_ratio] = r0;

   // WARP_VALUE
   r0 = M[r3 + $CVC_1MIC_PERSIST_WARP_VALUE_HI_OFFSET];
   r1 = M[r3 + $CVC_1MIC_PERSIST_WARP_VALUE_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_warp_value] = r0;

   // INVERSE_WARP_VALUE
   r0 = M[r3 + $CVC_1MIC_PERSIST_INVERSE_WARP_VALUE_HI_OFFSET];
   r1 = M[r3 + $CVC_1MIC_PERSIST_INVERSE_WARP_VALUE_LO_OFFSET];
   r0 = r0 LSHIFT 8;
   r1 = r1 AND 0xff;
   r0 = r0 OR r1;
   M[persistent_inverse_warp_value] = r0;

   // SRA_CURRENT_RATE
   r0 = M[r3 + $CVC_1MIC_PERSIST_SRA_CURRENT_RATE_HI_OFFSET];
   r1 = M[r3 + $CVC_1MIC_PERSIST_SRA_CURRENT_RATE_LO_OFFSET];
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
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .CONST $CVC_1MIC_PERSIST_STORE_MSG_SIZE         ($CVC_1MIC_PERSIST_NUM_ELEMENTS + 1); // Need 1 extra for the SysID
   // SysID(1), MGDC(1), AGC(1), Alpha index(1), IO ratio(2), USB warp value(2), USB inverse warp value(2), sra current rate(2)

   // Pblock re-send timer data structure
   .VAR $pblock_send_timer_struc[$timer.STRUC_SIZE];

   // Persistence message data
   .VAR persist_data_1mic[$CVC_1MIC_PERSIST_STORE_MSG_SIZE];            // Need 1 extra for the SysID

$pblock_send_handler:
   
   $push_rLink_macro;
   
   r0 = M[$pblock_key];                                                 // Unique data access key
   M[&persist_data_1mic] = r0;                                          // Store the SysID

#if uses_RCV_AGC
   r0 = M[$M.CVC.data.rcv_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD];
   M[$M.1mic.LoadPersistResp.persistent_agc]=r0;                    
   r0 = r0 ASHIFT -8;                                                   // to 16-bit, truncate 8 lsbs
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_AGC_OFFSET] = r0;
#endif

   // USB rate match persistence
   // --------------------------

   // CURRENT_ALPHA_INDEX
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD];
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_CURRENT_ALPHA_INDEX_OFFSET] = r0;

   // AVERAGE_IO_RATIO
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_AVERAGE_IO_RATIO_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_1mic  + 1 + $CVC_1MIC_PERSIST_AVERAGE_IO_RATIO_LO_OFFSET] = r1;

   // WARP_VALUE_FIELD
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_WARP_VALUE_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_WARP_VALUE_LO_OFFSET] = r1;

   // INVERSE_WARP_VALUE_FIELD
   r0 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_INVERSE_WARP_VALUE_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_INVERSE_WARP_VALUE_LO_OFFSET] = r1;

   // SRA_CURRENT_RATE
   r0 = M[$far_end.in.sw_copy_op.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD];
   r1 = r0 LSHIFT -8;                                                   // Bits 23-8
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_SRA_CURRENT_RATE_HI_OFFSET] = r1;
   r1 = r0 AND 0xff;                                                    // Bits 7-0
   M[&persist_data_1mic + 1 + $CVC_1MIC_PERSIST_SRA_CURRENT_RATE_LO_OFFSET] = r1;

   r3 = $M.CVC.VMMSG.STOREPERSIST;
   r4 = $CVC_1MIC_PERSIST_STORE_MSG_SIZE;
   r5 = &persist_data_1mic;
   call $message.send_long;

   // post another timer event
   r1 = &$pblock_send_timer_struc;
   r2 = $TIMER_PERIOD_PBLOCK_SEND_MICROS;
   r3 = &$pblock_send_handler;
   call $timer.schedule_event_in_period;

   jump $pop_rLink_and_rts;   

.ENDMODULE; 


// *****************************************************************************
// MODULE:
//    $M.vad_hold.process
//
// DESCRIPTION:
//    Delay VAD transition to zero after echo event. Logic:
//    if echo_flag
//        echo_hold_counter = echo_hold_time_frames
//    else
//        echo_hold_counter = MAX(--echo_hold_counter, 0)
//    end 
//    VAD = VAD && (echo_hold_counter > 0)
//
// INPUTS:
//    r7 - Pointer to the data structure
//
// *****************************************************************************
.MODULE $M.vad_hold.process;
   .CODESEGMENT PM;

func:
   r0 = M[r7 + $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD];
   r0 = M[r0]; // VAD status
   r1 = M[r7 + $M.CVC.vad_hold.PTR_ECHO_FLAG_FIELD];
   r1 = M[r1]; // echo status
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
