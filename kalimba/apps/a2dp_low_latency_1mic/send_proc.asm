// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change:  $  $DateTime:  $
// *****************************************************************************
// *****************************************************************************
// CVC 1mic send processing
//
// Configuration :
//      Echo and Noise reduction processing @ 16kHz
//      Parameter tuning through UFE
//
// Interface points :
//      stream_map_sndin
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
//    define statements in a2dp_low_latency_1mic_config.h
// *****************************************************************************
// *****************************************************************************
#include "stack.h"
#include "timer.h"
#include "frame_codec.h"
#include "cbops_multirate_library.h"
#include "cvc_modules.h"
#include "a2dp_low_latency_1mic.h"
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

.CONST $SND_IN_JITTER           500; 
.CONST $REF_IN_JITTER           100; 
.CONST $SND_OUT_JITTER          1000;                
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
      .VAR  CompConfig = A2DP_LOW_LATENCY_1MIC_CONFIG_FLAG;
      .VAR  s4 = 0xfeeb;
      .VAR  s5 = 0xfeeb;
      .VAR  s6 = 0xfeeb;
   .ENDBLOCK;
   
.ENDMODULE;

.MODULE $M.CVC_VERSION_STAMP;
   .DATASEGMENT DM;
   
   .BLOCK VersionStamp;
   .VAR  h1 = 0xbeef;
   .VAR  h2 = 0xbeef;
   .VAR  h3 = 0xbeef;
   .VAR  SysID = $A2DP_LOW_LATENCY_1MIC_SYSID;
   .VAR  BuildVersion = $CVC_VERSION;
   .VAR  h4 = 0xbeef;
   .VAR  h5 = 0xbeef;
   .VAR  h6 = 0xbeef;
   .ENDBLOCK;
   
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
   
.CONST  $CVC_ONEMIC_HEADSET_SECID     0x258C;

   // ** Memory Allocation for CVC config structure
   .VAR CVC_config_struct[$M.CVC.CONFIG.STRUC_SIZE] =
      &$App.Codec.Apply,                        // CODEC_CNTL_FUNC
      &$CVC_AppHandleConfig,                    // CONFIG_FUNC
      0,                                        // PERSIS_FUNC
      $CVC_ONEMIC_HEADSET_SECID,                // SECURITY_ID
      $CVC_VERSION,                             // VERSION
      $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.STANDBY,    // STANDBY_MODE
      $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.FULLPROC,   // HFK_MODE
      $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.MAX_MODES,// NUMBER of MODES
      $M.A2DP_LOW_LATENCY_1MIC.CALLST.MUTE,        // CALLST_MUTE
      $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.STRUCT_SIZE,// NUM_PARAMS
      &$M.CVC.data.CurParams,                   // PARAMS_PTR
      &$M.CVC.data.DefaultParameters_wb,           // DEF_PARAMS_PTR
      $A2DP_LOW_LATENCY_1MIC_SYSID,                // SYS_ID
      $M.CVC.BANDWIDTH.WB_FS,                      // SYS_FS
      0,                                           // CVC_BANDWIDTH_INIT_FUNC (n/a)
      &$M.CVC.data.StatisticsPtrs,              // STATUS_PTR
      &$M.dac_out.auxillary_mix_left_op.param,         // TONE_MIX_PTR
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE; // $M.CVC.CONFIG.PTR_INV_DAC_TABLE
      
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
   .VAR $pblock_key = ($A2DP_LOW_LATENCY_1MIC_SYSID >> 8) | (CVC_SYS_FS / 2000); // unique key

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
#if uses_SND_AGC || uses_RCV_VAD
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
            $M.CVC.BANDWIDTH.WB_FS/2000,                 // BANDWIDTH_ID
            0;

$SendProcStart:

   $push_rLink_macro;
   // request persistence
   r0 = $M.CVC.BANDWIDTH.WB_FS/2000;
   r3 = r0 OR ($A2DP_LOW_LATENCY_1MIC_SYSID >> 8);
   M[$pblock_key] = r3;
   r2 = $M.CVC.VMMSG.LOADPERSIST;
   call $message.send_short;

   call $ConfigureSystem;
   r8 = &$M.CVC.app.config.CVC_config_struct;
   call $CVC.PowerUpReset;
   call $CVC.Start;

   jump $pop_rLink_and_rts;

$ConfigureSystem:
   $push_rLink_macro;

   // select parameter set based on cvc bandwidth
   r6 = &cvc_bandwidth_param_wb;

   // Save the Variant for the UFE (SPI) GetVersion
   r0 = M[r6 + $CVC.BW.PARAM.SYS_FS];
   M[&$M.CVC.app.config.CVC_config_struct + $M.CVC.CONFIG.SYS_FS] = r0;

   // Set SCO/USB Frame Size
   r1 = M[r6 + $CVC.BW.PARAM.Num_Samples_Per_Frame];
#if uses_SND_NS
   r2 = M[$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_HISTORY];
   r2 = r2 - r1;
   M[$M.CVC.data.oms270snd_obj + $M.oms270.PTR_INP_X_FIELD] = r2;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Freq_Bins];
   M[$cvc_fftbins] = r0;

#if uses_AEC
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_NUM_FREQ_BINS] = r0;
   M[&$M.CVC.data.vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS] = r0;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Window];
#if uses_SND_NS
   M[&$M.CVC.data.oms270snd_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.OMS_MODE_OBJECT];
#if uses_SND_NS
   M[&$M.CVC.data.oms270snd_obj + $M.oms270.PTR_MODE_FIELD] = r0;
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
#if uses_SND_AGC
   M[&$M.CVC.data.snd_vad_peq + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
#endif

   r0 = M[r6 + $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR];
   M[&$M.CVC.data.adc_dc_block_dm1 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;

   r0 = M[r6 + $CVC.BW.PARAM.FB_CONFIG_AEC];
   M[&$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
   M[&$M.CVC.data.SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;

    jump $pop_rLink_and_rts;

$SendProcRun:

    $push_rLink_macro;

    r0 = &$M.adc_in.audio_in_left_cbuffer_struc;
    call $cbuffer.calc_amount_data;
    NULL = r0 - $M.CVC.Num_Samples_Per_Frame;
    if NEG jump $pop_rLink_and_rts;

    NULL = M[$M.CVC_SYS.AlgReInit];
    if NZ call $M.A2DP_LOW_LATENCY_1MIC.SystemReInitialize.func;

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
    Null = r1 - $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.FULLPROC;
    if Z r1 = r2;
    
    r1 = $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.FULLPROC;
    M[$M.CVC_SYS.cur_mode] =  r1;
    M[$M.CVC_SYS.SysMode] = r1;

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
    r7 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG];
    r8 = &$M.adc_in.sidetone_copy_op.param;
    r1 = M[$M.CVC_SYS.cur_mode];
    NULL = r1 - $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.FULLPROC;
    if Z jump jp_sidetone_enabled;
        NULL = r1 - $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.LOWVOLUME;
        if NZ r7 = Null;
        
jp_sidetone_enabled:
    M[r8 + $cbops.sidetone_filter_op.OFFSET_ST_CONFIG_FIELD]=r7;
    call $cbops.sidetone_filter_op.SetMode;
    
    jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $set_variant_from_vm
//
// DESCRIPTION:
//    Message handler for receiving the variant from the VM
//    This is the LOAD_PARAMS message
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
// *****************************************************************************
$set_variant_from_vm:
   // Set the default Parameters
   r4 = &$M.CVC.data.DefaultParameters_wb;
   r9 = M[$M.CVC_SYS.cvc_bandwidth];
   Null = r9 - $M.CVC.BANDWIDTH.WB;
   if Z r6 = r4;
   M[&$M.CVC.app.config.CVC_config_struct + $M.CVC.CONFIG.DEF_PARAMS_PTR] = r6;

.ENDMODULE;

// *****************************************************************************

// MODULE:
//    $M.App.Codec.Apply
//
// DESCRIPTION:
//    A pointer to this function is passed in via the CVC_data_obj data object.
//    CVC uses the pointer to call this function to set the ADC and DAC gains.
//    Most users will probably keep the function as is, sending the
//    $M.CVC.VMMSG.CODEC message to the VM application. However, this function
//    can be modified to set the gains directly using the DSP.
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
   r0 = $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.FULLPROC;
#if uses_VCAEC
   r7 = $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.LOWVOLUME;
   r2 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LVMODE_THRES];
   Null = r2 - r3;
   if POS r0 = r7;
#endif
   M[&$M.CVC_SYS.VolState] = r0;

   // Get the ADC gain parameter
   r4 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ADCGAIN];

//    r3 - DAC Gain
//    r4 - ADC Gain
//
//    The DAC Gain is in a form suitable for the VM function CodecSetOutputGainNow.
//    The ADC Gain is the form described by T_mic_gain in csr_cvc_common_if.h

   // r3=DAC gain r4=ADC gain left
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
   // set mic-config bits
   r1 = M[$M.CVC_MODULES_STAMP.CompConfig];
   r1 = r1 AND (~(flag_uses_DIGITAL_MIC));
   r0 = r4 LSHIFT ( round(log2(flag_uses_DIGITAL_MIC)) - 1);
   r0 = r0 AND flag_uses_DIGITAL_MIC;
   r1 = r1 OR r0;
   M[$M.CVC_MODULES_STAMP.CompConfig] = r1;
   rts;
   
.ENDMODULE;

// *****************************************************************************
.MODULE $M.CVC.data;
   .DATASEGMENT DM;

   // Temp Variable to handle disabled modules.
   .VAR  ZeroValue = 0;
   .VAR  OneValue = 1.0;
   .VAR  MinusOne  = -1;

   // These lines write module and version information to the kap file.
   .VAR kap_version_stamp = &$M.CVC_VERSION_STAMP.VersionStamp;
   .VAR kap_modules_stamp = &$M.CVC_MODULES_STAMP.ModulesStamp;

   // Default Block
   .VAR/DMCONST16  DefaultParameters_wb[] =
       #include "a2dp_low_latency_1mic_defaults_FA1M.dat"
   ;
   // guarantee even length
   .VAR  CurParams[2*ROUND(0.5*$M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.STRUCT_SIZE)];

//  ******************  Define circular Buffers ********************************

 .VAR/DM1     ref_delay_buffer[Max_RefDelay_Sample];
 .VAR/DM2     fft_circ[FFT_BUFFER_SIZE];

#if uses_SND_NS
   .VAR/DM1 sndLpX_queue[$M.oms270.QUE_LENGTH];
#endif

//  ******************  Define Scratch/Shared Memory ***************************

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
         // real,imag interlaced
         .VAR  W_ri[2 * $M.CVC.Num_FFT_Freq_Bins +1];
         .VAR  Attenuation[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  L_adaptA[$M.CVC.Num_FFT_Freq_Bins];
         .VAR  L_adaptR[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;


   .BLOCK/DM2  $M.dm2_scratch;
         // real,imag interlaced
         .VAR  Exp_Mts_adapt[2*$M.CVC.Num_FFT_Freq_Bins + 1];
         .VAR  scratch_extra_dm2[$asf100.SCRATCH_SIZE_DM2 - ( 2*$M.CVC.Num_FFT_Freq_Bins + 1 )];
   .ENDBLOCK;


    // The oms_scratch buffer reuses the AEC buffer to reduce the data memory usage.
#define oms_scratch              $M.dm1_scratch
    // The following two scratch buffers for the fft_object
    // reuses the scratch buffer from the AEC module.  This allows
    // reduction in the requirement of data memory for the overall system.
    // To be noted: The same AEC scratch memory is also reused for the
    // OMS270 scratch.

#define fft_real_scratch         $M.dm1_scratch
#define fft_imag_scratch $M.dm1_scratch + FFT_BUFFER_SIZE
#define fft_circ_scratch         fft_circ

    // The aeq_scratch buffer reuses the AEC buffer to reduce the data memory usage.

#define vad_scratch $M.dm1_scratch

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

// ***************  Common Test Mode Control Structure **************************
   .CONST   $M.SET_MODE_GAIN.ADC_MANT                  0;
   .CONST   $M.SET_MODE_GAIN.ADC_EXP                   1;
   .CONST   $M.SET_MODE_GAIN.SCO_IN_MANT               2;
   .CONST   $M.SET_MODE_GAIN.SCO_IN_EXP                3;
   .CONST   $M.SET_MODE_GAIN.STRUC_SIZE                4;

   .VAR     ModeControl[$M.SET_MODE_GAIN.STRUC_SIZE];

   .VAR/DM1 passthru_snd_gain[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndin,                        // OFFSET_INPUT_PTR
      0,                                        // OFFSET_OUTPUT_PTR     <set in passthrough & loopback>
      &ModeControl + $M.SET_MODE_GAIN.ADC_MANT, // OFFSET_PTR_MANTISSA
      &ModeControl + $M.SET_MODE_GAIN.ADC_EXP;  // OFFSET_PTR_EXPONENT

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
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC, // Parameter Ptr
        0 ...;

#endif

// ************************  Send Side Processing   **************************

// OMS requires 3 frames for harmonicity (window is only 2 frame)
#if uses_SND_NS
.CONST $SND_HARMONICITY_HISTORY_EXTENSION  $M.CVC.Num_Samples_Per_Frame;
#else
.CONST $SND_HARMONICITY_HISTORY_EXTENSION  0;
#endif

   .VAR/DM1  bufd_inp[$M.CVC.Num_FFT_Window + $SND_HARMONICITY_HISTORY_EXTENSION];
   .VAR/DM2  bufx_inp[$M.CVC.Num_FFT_Window];

   // Analysis Filter Bank Config Block
   .VAR/DM1 AecAnalysisBank[$M.filter_bank.Parameters.TWO_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,                             // OFFSET_CONFIG_OBJECT
      &stream_map_sndin,               // CH1_PTR_FRAME
      &stream_map_refin,               // CH2_PTR_FRAME
      &bufd_inp+$SND_HARMONICITY_HISTORY_EXTENSION,// OFFSET_CH1_PTR_HISTORY
      &bufx_inp,                       // OFFSET_CH2_PTR_HISTORY
      0,                               // CH1_BEXP
      0,                               // CH2_BEXP
      &D_real,                         // CH1_PTR_FFTREAL
      &D_imag,                         // CH1_PTR_FFTIMAG
      &X_real,                         // CH2_PTR_FFTREAL
      &X_imag,                         // CH2_PTR_FFTIMAG


      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_REF_DELAY,  //OFFSET_CH2_DELAY_PTR
      &ref_delay_buffer,            // OFFSET_CH2_DELAY_BASE
     &ref_delay_buffer,               // OFFSET_CH2_DELAY_BUF_PTR
      LENGTH(ref_delay_buffer);        // OFFSET_CH2_DELAY_BUF_LEN

   // Syntheseis Filter Bank Config Block
     .VAR/DM1  bufd_outp[($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame)];

   .VAR/DM2 SndSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      CVC_BANK_CONFIG_AEC,                      // OFFSET_CONFIG_OBJECT
      &stream_map_sndout,                       // OFFSET_PTR_FRAME
      &bufd_outp,                               // OFFSET_PTR_HISTORY
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
#if uses_SND_NS
      &E_real,                                  // OFFSET_PTR_FFTREAL
      &E_imag,                                  // OFFSET_PTR_FFTIMAG
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
        M_oms270_mode_object,   // $M.oms270.PTR_MODE_FIELD
        0,                      // $M.oms270.CONTROL_WORD_FIELD
        $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SNDOMSENA,
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
        &sndoms_G,                 // $M.oms270.G_FIELD;
        &sndoms_LpXnz,             // $M.oms270.LPXNZ_FIELD,
        &sndoms_state,             // $M.oms270.PTR_STATE_FIELD
        &oms_scratch,           // $M.oms270.PTR_SCRATCH_FIELD
        0.036805582279178,      // $M.oms270.ALFANZ_FIELD      
        0xFF13DE,               // $M.oms270.LALFAS_FIELD       
        0xFEEB01,               // $M.oms270.LALFAS1_FIELD      
        0.45,                   // $M.oms270.HARMONICITY_THRESHOLD_FIELD
        $M.oms270.NOISE_THRESHOLD,  // $M.oms270.VAD_THRESH_FIELD
        1.0,                    // $M.oms270.AGRESSIVENESS_FIELD
        0,                      // $M.oms270.PTR_TONE_FLAG_FIELD
        0 ...;

   .VAR wnr_obj[$M.oms270.wnr.STRUC_SIZE] =
         &$M.oms270.wnr.initialize.func,  // FUNC_WNR_INIT_FIELD
         &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_WNR_AGGR, // PTR_WNR_PARAM_FIELD
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

#if uses_DCBLOCK
   .VAR/DM2 adc_dc_block_dm1[PEQ_OBJECT_SIZE(1)] =     // 1 stage
      &stream_map_sndin,               // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndin,               // PTR_OUTPUT_DATA_BUFF_FIELD
      1,                               // MAX_STAGES_FIELD
      CVC_DCBLOC_PEQ_PARAM_PTR,        // PARAM_PTR_FIELD
      0 ...;
#endif

   .VAR/DM1 mute_cntrl_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,                       // OFFSET_INPUT_PTR
      &$M.CVC_SYS.CurCallState,                 // OFFSET_PTR_STATE
      $M.A2DP_LOW_LATENCY_1MIC.CALLST.MUTE;       // OFFSET_MUTE_VAL


#if uses_SND_PEQ
   // Parameteric EQ
   .VAR/DM2 snd_peq_dm2[PEQ_OBJECT_SIZE(MAX_NUM_PEQ_STAGES)] =
      &stream_map_sndout,             // PTR_INPUT_DATA_BUFF_FIELD
      &stream_map_sndout,             // PTR_OUTPUT_DATA_BUFF_FIELD
      MAX_NUM_PEQ_STAGES,             // MAX_STAGES_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG,  // PARAM_PTR_FIELD
       0 ...;
#endif

   // SND AGC Pre-Gain stage
   .VAR/DM1 out_gain_dm1[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndout,              // OFFSET_INPUT_PTR
      &stream_map_sndout,              // OFFSET_OUTPUT_PTR
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT;

#if uses_SND_AGC || uses_SND_NS
   // SND VAD
   .VAR/DM1 snd_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,     // INPUT_PTR_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_ATTACK_TC, // Parameter Ptr
      0 ...;
   .VAR vad_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &snd_vad400 + $M.vad400.FLAG_FIELD, // PTR_VAD_FLAG_FIELD
      &rcv_vad400 + $M.vad400.FLAG_FIELD, // PTR_ECHO_FLAG_FIELD
      0,                                  // FLAG_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME,    // HOLD_TIME_FRAMES_FIELD
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
      $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SND_AGCBYP, //OFFSET_BYPASS_BIT_MASK_FIELD
      0,                                // OFFSET_BYPASS_PERSIST_FIELD
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL, // OFFSET_PARAM_PTR_FIELD
      &stream_map_sndout,  //OFFSET_PTR_INPUT_FIELD
      &stream_map_sndout,  //OFFSET_PTR_OUTPUT_FIELD
      &vad_hold + $M.CVC.vad_hold.FLAG_FIELD,
                           //OFFSET_PTR_VAD_VALUE_FIELD
      0x7FFFFF,            //OFFSET_HARD_LIMIT_FIELD
      0,                   //OFFSET_PTR_TONE_FLAG_FIELD
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
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CNG_Q,              &aec_dm1 + $M.AEC_500.OFFSET_CNG_Q_ADJUST,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CNG_SHAPE,          &aec_dm1 + $M.AEC_500.OFFSET_CNG_NOISE_COLOR,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DTC_AGGR,           &aec_dm1 + $M.AEC_500.OFFSET_DTC_AGRESSIVENESS,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE,   &aec_dm1 + $M.AEC_500.OFFSET_ENABLE_AEC_REUSE,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG,         &aec_dm1 + $M.AEC_500.OFFSET_CONFIG,
#endif

#if uses_SND_NS
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG,         &oms270snd_obj + $M.oms270.CONTROL_WORD_FIELD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_OMS_HARMONICITY,    &oms270snd_obj + $M.oms270.HARM_ON_FIELD,

#endif

#if uses_SND_AGC
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG,         &snd_agc400_dm + $M.agc400.OFFSET_SYS_CON_WORD_FIELD,
#endif

#if uses_AEC
      // HD threshold
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN,         &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,
#endif

#if uses_DITHER
      // Update both the stereo and mono operators with the noise shape field
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE,&$M.system_config.data.dithertype,
#endif

#if uses_STEREO_ENHANCEMENT
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CONFIG,           &$M.system_config.data.stereo_3d_obj + 9,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_REFLECTION_DELAY, &$M.system_config.data.stereo_3d_obj + 10,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SE_MIX,           &$M.system_config.data.stereo_3d_obj + 11,
#endif

#if uses_COMPANDER
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CONFIG,                  &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CONFIG,                  &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1,     &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1,     &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1,       &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1,     &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1,      &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1,        &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC1,         &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_MAKEUP_GAIN1,            &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2,     &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2,     &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2,       &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2,     &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2,      &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2,        &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC2,         &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_MAKEUP_GAIN2,            &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
#endif

     // End of Parameter Map
      0;

   // Statistics from Modules sent via SPI
   // ------------------------------------------------------------------------
   .VAR/ADDR_TABLE_DM StatisticsPtrs[] = //$M.A2DP_LOW_LATENCY_1MIC.STATUS.BLOCK_SIZE+2] =
      $M.A2DP_LOW_LATENCY_1MIC.STATUS.BLOCK_SIZE,
      &StatisticsClrPtrs,
      // Statistics
      &$M.CVC_SYS.cur_mode,                             // $M.A2DP_LOW_LATENCY_1MIC.STATUS.CUR_MODE_OFFSET
      &$M.CVC_SYS.SysControl,                           // $M.A2DP_LOW_LATENCY_1MIC.STATUS.SYS_CONTROL_OFFSET
      &$M.ConfigureSystem.PeakMipsTxFunc,               // $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_MIPS_OFFSET
      &$M.back_end.PeakMipsDecoder,                     // $M.A2DP_LOW_LATENCY_1MIC.STATUS.DECODER_MIPS_OFFSET
      &$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, // FOR PEAK_PCMINL_OFFSET
     &$M.system_config.data.pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, // FOR PEAK_PCMINR_OFFSET
      &$M.system_config.data.dac_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,   // FOR PEAK_DACL_OFFSET
     &$M.system_config.data.dac_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,   // FOR PEAK_DACR_OFFSET
      &ZeroValue,                                       // FOR PEAK_SUB_OFFSET 
      &$M.CVC_SYS.CurDAC,                               // $M.A2DP_LOW_LATENCY_1MIC.STATUS.CUR_DACL_OFFSET
#ifdef uses_USER_EQ
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CONFIG,// USER_EQ_BANK_OFFSET 
#else
      &ZeroValue,
#endif                              
      &$M.CVC_MODULES_STAMP.CompConfig,                 // $M.A2DP_LOW_LATENCY_1MIC.STATUS.COMPILED_CONFIG
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
      &$M.CVC_SYS.SecStatus,                            // $M.A2DP_LOW_LATENCY_1MIC.STATUS.SEC_STAT_OFFSET
      &mic_in_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL, //PEAK_ADC_LEFT_OFFSET
      &sco_out_pk_dtct  + $M.audio_proc.peak_monitor.PEAK_LEVEL, //PEAK_SCO_OUT_OFFSET
      &$M.Sleep.Mips,                                   // $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_MIPS_OFFSET
      &ZeroValue,                                       // PEAK_AUX_OFFSET
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN, // SIDETONE_GAIN
      &ZeroValue,                                       // VOLUME
      &$M.CVC_SYS.ConnectStatus,                        // $M.A2DP_LOW_LATENCY_1MIC.STATUS.CONNSTAT    
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST, //  SIDETONE_PEAK
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
      &asf_object + $asf100.wnr.MEAN_PWR_FIELD;
#else
      &ZeroValue;
#endif

// Clear These statistics
.VAR/ADDR_TABLE_DM StatisticsClrPtrs[] =
      &mic_in_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL,
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

      $filter_bank.two_channel.analysis.initialize,  &fft_obj,         &AecAnalysisBank,
      $filter_bank.one_channel.synthesis.initialize, &fft_obj,         &SndSynthesisBank,

#if uses_SND_NS
      $M.oms270.initialize.func,           &oms270snd_obj,           &wnr_obj,
#endif

#if uses_AEC
      $M.AEC_500.Initialize.func,          &vsm_fdnlp_dm1,           &aec_dm1,
#endif


#if uses_DCBLOCK
      $audio_proc.peq.initialize,          &adc_dc_block_dm1,        0,
#endif

#if uses_SND_PEQ
      $audio_proc.peq.initialize,     &snd_peq_dm2,             0,
#endif

#if uses_RCV_VAD
      $audio_proc.peq.initialize,          &rcv_vad_peq,             0,
      $M.vad400.initialize.func,           &rcv_vad400,              0,
#endif


#if uses_SND_AGC
      $audio_proc.peq.initialize,         &snd_vad_peq,                 0,
      $M.vad400.initialize.func,          &snd_vad400,                  0,
      $M.agc400.initialize.func,                0,                 &snd_agc400_dm,
#endif

#if uses_STEREO_ENHANCEMENT
    $stereo_3d_enhancement.initialize,   0,                  &$M.system_config.data.stereo_3d_obj,
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

    $cbops.sidestone_filter_op.InitializeFilter,     &$M.adc_in.sidetone_copy_op.param,  0,

      0;                                    // END OF TABLE
// -----------------------------------------------------------------------------
   // Table of functions for current mode
   .VAR ModeProcTableSnd[$M.A2DP_LOW_LATENCY_1MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsSnd,              // Standby
      &copy_proc_funcsSnd,              // pass-thru mode
      &hfk_proc_funcsSnd,               // full proc mode
      &copy_proc_funcsSnd;              // low volume state
 // -----------------------------------------------------------------------------

 .VAR/DM hfk_proc_funcsSnd[] =
      // Function                               r7                   r8

      $frame_sync.distribute_streams_ind,       &snd_process_streams,0,

#if uses_RCV_VAD
      $audio_proc.peq.process,                  &rcv_vad_peq,           0,
      $M.vad400.process.func,                   &rcv_vad400,            0,
#endif

#if uses_DCBLOCK
      $audio_proc.peq.process,                  &adc_dc_block_dm1,      0,
#endif

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_pk_dtct,        0,

      $filter_bank.two_channel.analysis.process, &fft_obj,   &AecAnalysisBank,

#if uses_SND_NS
      $M.oms270.process.func,                &oms270snd_obj,         0,
      $one_mic.send.process,                     0,                     0,
      $M.CVC.Zero_DC_Nyquist.func,              &E_real,             &E_imag,
#else
      $M.CVC.Zero_DC_Nyquist.func,              &D_real,             &D_imag,
#endif

      $filter_bank.one_channel.synthesis.process, &fft_obj,   &SndSynthesisBank,

#if uses_SND_PEQ
      $audio_proc.peq.process,                  &snd_peq_dm2,        0,
#endif
      $M.audio_proc.stream_gain.Process.func,   &out_gain_dm1,       0,

#if uses_SND_AGC
      $audio_proc.peq.process,                  &snd_vad_peq,               0,
      $M.vad400.process.func,                   &snd_vad400,         0,
      $M.vad_hold.process.func,                 &vad_hold,                 0,
      $M.agc400.process.func,                   0,                   &snd_agc400_dm,
#endif

      $M.MUTE_CONTROL.Process.func,             &mute_cntrl_dm1,     0,

      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,    0,

      $frame_sync.update_streams_ind,           &snd_process_streams,0,

      0;                                     // END OF TABLE

   // -------------------------------------------------------------------------------
   // -------------------------------------------------------------------------------

   .VAR/DM copy_proc_funcsSnd[] =
      // Function                               r7                   r8
      $frame_sync.distribute_streams_ind,        &snd_process_streams,  0,

      $cvc_Set_PassThroughGains,                &ModeControl,         0,

      $M.audio_proc.peak_monitor.Process.func,  &mic_in_pk_dtct,      0,
      $M.audio_proc.stream_gain.Process.func,   &passthru_snd_gain,   0,
      $M.audio_proc.peak_monitor.Process.func,  &sco_out_pk_dtct,     0,

      $frame_sync.update_streams_ind,           &snd_process_streams,  0,
      0;                                     // END OF TABLE


// ***************  Stream Definitions  ************************/

// reference stream map
   .VAR  stream_map_refin[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.dac_out.Reference.cbuffer_struc,      // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.ADC_DAC_Num_Samples_Per_Frame,     // $framesync_ind.FRAME_SIZE_FIELD
      $REF_IN_JITTER,                           // $framesync_ind.JITTER_FIELD     [--CONFIG--]
      $frame_sync.distribute_sync_stream_ind,   // Distribute Function
      $frame_sync.update_sync_streams_ind,      // Update Function
      &stream_map_sndin,                        // $framesync_ind.SYNC_POINTER_FIELD
      1,                                        // $framssync_ind.SYNC_MULTIPLIER_FIELD
      0 ...;
    //  Constant links.  Set in data objects
    //  &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH2_PTR_FRAME
    //   &ref_downsample_dm1 +  $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //   &ref_downsample_dm1 +  $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,

   // sndin stream map
   .VAR  stream_map_sndin[$framesync_ind.ENTRY_SIZE_FIELD] =
      $M.adc_in.audio_in_left_cbuffer_struc,                    // $framesync_ind.CBUFFER_PTR_FIELD
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.ADC_DAC_Num_Samples_Per_Frame,     // $framesync_ind.FRAME_SIZE_FIELD
      $SND_IN_JITTER,                           // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
    //  Constant links.  Set in data objects
    //  &passthru_snd_gain + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR,
    //  &adc_dc_block_dm1 + $audio_proc.peq.INPUT_ADDR_FIELD,
    //  &adc_dc_block_dm1 + $audio_proc.peq.OUTPUT_ADDR_FIELD,
    //  &mic_in_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD
    //  &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_FRAME
    //  &adc_downsample_dm1 + $iir_resamplev2.INPUT_1_START_INDEX_FIELD,
    //  &adc_downsample_dm1 + $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD,

   // sndout stream map .
   .VAR  stream_map_sndout[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.A2DP_OUT.encoder_in_cbuffer_struc,      // $framesync_ind.CBUFFER_PTR_FIELD     [---CONFIG---]
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $M.CVC.Num_Samples_Per_Frame,             // $framesync_ind.FRAME_SIZE_FIELD
      $SND_OUT_JITTER ,                         // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_output_stream_ind, // Distribute Function
      $frame_sync.update_output_streams_ind,    // Update Function
      0 ...;
    //  Constant links.  Set in data objects
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
    //  &sco_out_pk_dtct + $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD,

   // -----------------------------------------------------------------------------

// Stream List for Send Processing
.VAR/ADDR_TABLE_DM    snd_process_streams[] =
   &stream_map_sndin,
   &stream_map_refin,
   &stream_map_sndout,
   0;
.ENDMODULE; // End of $M.CVC.data

#if uses_SND_NS

.MODULE  $one_mic_aec_control;
   .CODESEGMENT PM;
   
$one_mic.send.process:
   $push_rLink_macro;
   
#if uses_AEC
   // AEC Bypassed for LV mode
   r0 = M[$M.CVC_SYS.cur_mode];
//REVISIT   NULL = r0 - $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.LOWVOLUME;
   if Z jump byPassAEC;
   // Check if AEC has been enabled globally
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.A2DP_LOW_LATENCY_1MIC.CONFIG.AECENA;
   if Z jump aec_disabled;
   // AEC function
   r7 = &$M.CVC.data.aec_dm1;
   call $M.AEC_500.fnmls_process.func;
   // half-duplex function
   r7 = &$M.CVC.data.vsm_fdnlp_dm1;
   r8 = &$M.CVC.data.aec_dm1;
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r0 AND $M.A2DP_LOW_LATENCY_1MIC.CONFIG.HDBYP;
   if Z call $AEC_500.NonLinearProcess;
go_cng:
   // Apply CNG (Not for SSR mode)  SPTBD
   r7 = &$M.CVC.data.aec_dm1;
   r0 = M[$M.CVC_SYS.cur_mode];
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
// *****************************************************************************

.MODULE $M.set_mode_gains;
    .CODESEGMENT SET_MODE_GAIN_PM;

$cvc_Set_PassThroughGains:

   // Gain si-->so
   r0 = &$M.CVC.data.stream_map_sndout;
   M[&$M.CVC.data.passthru_snd_gain + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR] = r0;

   r4 = M[$M.CVC_SYS.cur_mode];
   NULL = r4 - $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.PASSTHRU;
   if Z jump passthroughgains;
       // Standby - Zero Signal
       r0 = NULL;
       r1 = 1;
       jump setgains;
passthroughgains:
   // PassThrough Gains set from Parameters
   r0 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA];
   r1 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT];
setgains:
   M[r7 + $M.SET_MODE_GAIN.ADC_MANT]    = r0;
   M[r7 + $M.SET_MODE_GAIN.ADC_EXP]     = r1;
   rts;

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
