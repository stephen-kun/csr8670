// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change$  $DateTime$
// *****************************************************************************


// *****************************************************************************
// NAME:
//    adf_alg_1_0_0 Library
//
// DESCRIPTION:
//    This library provides the ADF-alg1_1_0 function for two mic headset
//    processing
//
//    This library provides the following API functions:
//          TBD
//   The library version is available at the data location:
//      $M.ADF_alg1p0p0.Version
// *****************************************************************************

#ifndef _adf_alg_1_0_0_LIB_H
#define  _adf_alg_1_0_0_LIB_H

// Library Build Version
.CONST  $M.adf_alg_1_0_0_VERSION         0x010000; //1.0.0

// System Proportions

.CONST   $M.adf_alg_1_0_0.ADF_num_proc          55;
.CONST   $M.adf_alg_1_0_0.Num_Taps              4;


.CONST $M.adf_alg_1_0_0.DATA_SIZE_DM1		(23 + 2*$M.adf_alg_1_0_0.Num_Taps)*$M.adf_alg_1_0_0.ADF_num_proc;

.CONST $M.adf_alg_1_0_0.DATA_SIZE_DM2		(19 + 2*$M.adf_alg_1_0_0.Num_Taps)*$M.adf_alg_1_0_0.ADF_num_proc + $M.adf_alg_1_0_0.Num_Taps+1;

.CONST $M.adf_alg_1_0_0.SCRATCH_SIZE_DM1  (5 * $M.adf_alg_1_0_0.ADF_num_proc);
.CONST $M.adf_alg_1_0_0.SCRATCH_SIZE_DM2  (1 * $M.adf_alg_1_0_0.ADF_num_proc);

.CONST $M.adf_alg_1_0_0.MGDC_param.Th0             3.98631371386483/128;   // 12 dB, for hold_adapt flag
.CONST $M.adf_alg_1_0_0.MGDC_param.Th1             3.98631371386483/128;   // 12 dB, for switch_output flab

//********************************************************************
// adf_alg_1_0_0 Data Structure Element Offset Definitions
//
// The following parameter block is used for all adf_alg_1_0_0
// process functions.
//
// The application using this library must include a data block of
// size STRUCT_SIZE.  The associated parameters should be initialized
// as defined below.
//
//********************************************************************

// Input/Output Block Offsets


// @DATA_OBJECT ADFDATAOBJECT

// SP.  Below must match AEC
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_E_REAL_PTR             0;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_E_IMAG_PTR             $M.adf_alg_1_0_0.OFFSET_FNLMS_E_REAL_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_D_EXP_PTR              $M.adf_alg_1_0_0.OFFSET_FNLMS_E_IMAG_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_D_REAL_PTR             $M.adf_alg_1_0_0.OFFSET_FNLMS_D_EXP_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_D_IMAG_PTR             $M.adf_alg_1_0_0.OFFSET_FNLMS_D_REAL_PTR+1;
// @DOC_FIELD_FORMAT Pointer
// @DOC_FIELD_TEXT Pointer to a scratch memory in DM2 with size of '2*$M.adf_alg_1_0_0.ADF_num_proc + 1'
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt   $M.adf_alg_1_0_0.OFFSET_FNLMS_D_IMAG_PTR+1;
// @DOC_FIELD_TEXT ADFRNR exit function, to be initialized with '$AEC_500.rer_adfrnr'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_RER_EXT_FUNC_PTR             $M.adf_alg_1_0_0.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_D_REAL_PTR               $M.adf_alg_1_0_0.OFFSET_RER_EXT_FUNC_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_D_IMAG_PTR               $M.adf_alg_1_0_0.OFFSET_RER_D_REAL_PTR +1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_imag              $M.adf_alg_1_0_0.OFFSET_RER_D_IMAG_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_real              $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_imag+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_SqGr                 $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_real+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_L2absGr              $M.adf_alg_1_0_0.OFFSET_RER_PTR_SqGr+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_LPwrD                $M.adf_alg_1_0_0.OFFSET_RER_PTR_L2absGr +1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_W_ri              $M.adf_alg_1_0_0.OFFSET_RER_PTR_LPwrD +1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_L_adaptR          $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_W_ri +1;
// @DOC_FIELD_TEXT Internal, to be initialized by '4'
.CONST $M.adf_alg_1_0_0.OFFSET_RER_SQGRDEV                  $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_L_adaptR +1;
// SP.  End Match
// SP.  Keep X0_Real, X0_Imag, X0_Exp, LPx0, X1_Real, X1_Imag, X0_Exp, and LPx1
//     consequtive and in order.  Functions rely on this arangement
// @DOC_FIELD_TEXT Pointer to real part of X0 (first channel FFT)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_X0_REAL_PTR         $M.adf_alg_1_0_0.OFFSET_RER_SQGRDEV+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of X0 (first channel FFT)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_X0_IMAG_PTR         $M.adf_alg_1_0_0.OFFSET_X0_REAL_PTR+1;
// @DOC_FIELD_TEXT Pointer to block exponent of X0 (first channel FFT)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_X0_EXP_PTR          $M.adf_alg_1_0_0.OFFSET_X0_IMAG_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPx0		       $M.adf_alg_1_0_0.OFFSET_X0_EXP_PTR+1;
// @DOC_FIELD_TEXT Pointer to real part of X1 (second channel FFT)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_X1_REAL_PTR         $M.adf_alg_1_0_0.OFFSET_ADF_LPx0+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of X1 (second channel FFT)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_X1_IMAG_PTR         $M.adf_alg_1_0_0.OFFSET_X1_REAL_PTR+1;
// @DOC_FIELD_TEXT Pointer to block exponent part of X1 (second channel FFT)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_X1_EXP_PTR          $M.adf_alg_1_0_0.OFFSET_X1_IMAG_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPx1		       $M.adf_alg_1_0_0.OFFSET_X1_EXP_PTR+1;

// Buffer Pointers
// @DOC_FIELD_TEXT Pointer to DM1 data block, with size of '$M.adf_alg_1_0_0.DATA_SIZE_DM1'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM1data         $M.adf_alg_1_0_0.OFFSET_ADF_LPx1+1;
// @DOC_FIELD_FORMAT Pointer
// @DOC_FIELD_TEXT Pointer to DM2 data block, with size of '$M.adf_alg_1_0_0.DATA_SIZE_DM2'
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM2data         $M.adf_alg_1_0_0.OFFSET_PTR_DM1data+1;
// @DOC_FIELD_TEXT Pointer to DM1 constant block, with size of '2*Num_FFT_Freq_Bins'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM1const        $M.adf_alg_1_0_0.OFFSET_PTR_DM2data+1;
// @DOC_FIELD_TEXT Pointer to DM1 table, to be initialized with '$adf.dm1_table'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM1tables       $M.adf_alg_1_0_0.OFFSET_PTR_DM1const+1;

// Scratch Memory
// LPwrX0 = &$M.AEC_500.dm1.scratch1
// LPwrX1 = &$M.AEC_500.dm1.scratch1 + ADF_num_proc
// LpX1t  = &$M.AEC_500.dm1.scratch1 + 2*ADF_num_proc
// adaptFactor01 = &$M.AEC_500.dm1.scratch1 + 3*ADF_num_proc
// adaptFactor10 = &$M.AEC_500.dm1.scratch1 + 4*ADF_num_proc
// @DOC_FIELD_TEXT Pointer to DM1 scratch block, with size of '$M.adf_alg_1_0_0.SCRATCH_SIZE_DM1'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM1  	   $M.adf_alg_1_0_0.OFFSET_PTR_DM1tables+1;

// sgn_xdGa01 = &$M.AEC_500.dm2.scratch1
// @DOC_FIELD_TEXT Pointer to DM2 scratch block, with size of '$M.adf_alg_1_0_0.SCRATCH_SIZE_DM2'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM2  	   $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM1+1;


// @DOC_FIELD_TEXT Pointer to OMS G array
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_OMS_G_PTR           $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM2+1;
// @DOC_FIELD_TEXT Pointer to real part of E (ADF output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_E_OUT_REAL_PTR      $M.adf_alg_1_0_0.OFFSET_OMS_G_PTR+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of E (ADF output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_E_OUT_IMAG_PTR      $M.adf_alg_1_0_0.OFFSET_E_OUT_REAL_PTR+1;

// $M.adf_alg_1_0_0.PostProcess.func or 0
// @DOC_FIELD_TEXT Post-processing function, to be initialized with '0' (no PP), or with '$M.adf_alg_1_0_0.PostProcess.func'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_POSTPROC_FUNCPTR    $M.adf_alg_1_0_0.OFFSET_E_OUT_IMAG_PTR+1;
// L_PostP_ctrl buffer or 0
// @DOC_FIELD_TEXT Pointer to L_PostP_ctrl[] buffer to store such variables or 0 to skip calculation. Only needed by 2MicHF
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_L_POSTP_CTRL_PTR        $M.adf_alg_1_0_0.OFFSET_POSTPROC_FUNCPTR+1;
// @DOC_FIELD_TEXT Number of FFT bins (NB:65/WB:129)
// @DOC_FIELD_FORMAT Integer
.CONST $M.adf_alg_1_0_0.OFFSET_NUMFREQ_BINS        $M.adf_alg_1_0_0.OFFSET_L_POSTP_CTRL_PTR+1;

// Bit-wise control word for ADF config
// @DOC_FIELD_TEXT CVC configuration contorl word (CVC parameter)
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_CONTROL                      $M.adf_alg_1_0_0.OFFSET_NUMFREQ_BINS+1;
// @DOC_FIELD_TEXT Bit mask for bypass pre-processing
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_PREP          $M.adf_alg_1_0_0.OFFSET_CONTROL+1;
// @DOC_FIELD_TEXT Bit mask for bypass MGDC
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_MGDC          $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_PREP+1;
// @DOC_FIELD_TEXT Bit mask for selecting wider micphone mode
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_WIDE_MIC_ENA         $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_MGDC+1;
// @DOC_FIELD_TEXT Bit mask for bypass post-processing
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_RPT_POSTP     $M.adf_alg_1_0_0.OFFSET_BITMASK_WIDE_MIC_ENA+1;
// @DOC_FIELD_TEXT Bit mask for bypass ADFPS (ADF power saving mode)
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFPS         $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_RPT_POSTP+1;
// @DOC_FIELD_TEXT Bit mask for bypass ADFRNR (ADF residual noise reduction)
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFRNR        $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFPS+1;

// @DOC_FIELD_TEXT Post-processing adaptation rate, default 0xFD95C1, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_PP_GAMMAP           $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFRNR+1;
// @DOC_FIELD_TEXT threshold for high freq adapt decision in post-processing, default 0.5, Q1.23 (CVC parameter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.adf_alg_1_0_0.OFFSET_PP_THRES            $M.adf_alg_1_0_0.OFFSET_PP_GAMMAP+1;
// @DOC_FIELD_TEXT VAD output flag detected by ADF Post-Processing
// @DOC_FIELD_FORMAT Flag
.CONST $M.adf_alg_1_0_0.OFFSET_PP_VAD_DETECT       $M.adf_alg_1_0_0.OFFSET_PP_THRES+1;
// Matlab:Th_AGC_PostPctrl
// @DOC_FIELD_TEXT threshold for VAD detection, default 0.35, Q1.23
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.adf_alg_1_0_0.OFFSET_PP_VAD_THRES        $M.adf_alg_1_0_0.OFFSET_PP_VAD_DETECT+1;
// @DOC_FIELD_TEXT Post-processing bias control, default 0, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_PP_CTRL_BIAS        $M.adf_alg_1_0_0.OFFSET_PP_VAD_THRES+1;
// @DOC_FIELD_TEXT Post-processing transition control, default 2.0 (in Q5.19) (CVC parameter)
// @DOC_FIELD_FORMAT Q5.19
.CONST $M.adf_alg_1_0_0.OFFSET_PP_CTRL_TRANS       $M.adf_alg_1_0_0.OFFSET_PP_CTRL_BIAS+1;
// @DOC_FIELD_TEXT MGDC alpha value, default 0.000374929696288273, Q1.23 (CVC parameter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_ALFAD          $M.adf_alg_1_0_0.OFFSET_PP_CTRL_TRANS+1;
// @DOC_FIELD_TEXT MGDC front micphone bias, default 0.00259525632413075, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_FRONTMICBIAS   $M.adf_alg_1_0_0.OFFSET_MGDC_ALFAD+1;
// @DOC_FIELD_TEXT MGDC Maximum compensation, default 0.0155715379447845, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_MAXCOMP        $M.adf_alg_1_0_0.OFFSET_MGDC_FRONTMICBIAS+1;
// @DOC_FIELD_TEXT MGDC adaptation threshold, default 0xA05417, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_ADAPT_THRESH   $M.adf_alg_1_0_0.OFFSET_MGDC_MAXCOMP+1;
// @DOC_FIELD_TEXT MGDC internal, default 10, Q24.0
// @DOC_FIELD_FORMAT Q24.0
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_K_LB           $M.adf_alg_1_0_0.OFFSET_MGDC_ADAPT_THRESH+1;
// @DOC_FIELD_TEXT MGDC internal, default 32, Q24.0
// @DOC_FIELD_FORMAT Q24.0
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_K_HB           $M.adf_alg_1_0_0.OFFSET_MGDC_K_LB+1;
// @DOC_FIELD_TEXT MGDC internal, default -4, Q24.0
// @DOC_FIELD_FORMAT Q24.0
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_EXP   $M.adf_alg_1_0_0.OFFSET_MGDC_K_HB+1;
// @DOC_FIELD_TEXT MGDC internal
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_MTS   $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_EXP+1;
// @DOC_FIELD_TEXT Threshold for detection of right channel lost
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_TH0        $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_MTS+1;
// @DOC_FIELD_TEXT Threshold for detection of left channel lost
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_TH1        $M.adf_alg_1_0_0.OFFSET_MGDC_TH0+1;
// @DOC_FIELD_TEXT Pointer to wind detection flag
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_WIND_DETECT        $M.adf_alg_1_0_0.OFFSET_MGDC_TH1+1;
// @DOC_FIELD_TEXT Pointer to receive VAD flag
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_ADF_HOLD        $M.adf_alg_1_0_0.OFFSET_PTR_WIND_DETECT+1;
// @DOC_FIELD_TEXT DMSS aggressiveness, default 1.0 (CVC parameter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.adf_alg_1_0_0.OFFSET_DMSS_WEIGHT         $M.adf_alg_1_0_0.OFFSET_PTR_ADF_HOLD+1;
// @DOC_FIELD_TEXT Pointer to OMS LpXnz array
// @DOC_FIELD_FORMAT Pointer
.CONST $M.adf_alg_1_0_0.OFFSET_OMS_LPXNZ_PTR       $M.adf_alg_1_0_0.OFFSET_DMSS_WEIGHT+1;
// @DOC_FIELD_TEXT ADFPS threshold for turning on ADF process, default -0.22656, Q8.16 (CVC paramter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_ON       $M.adf_alg_1_0_0.OFFSET_OMS_LPXNZ_PTR+1;
// @DOC_FIELD_TEXT ADFPS threshold for turning off ADF process, default -0.19531, Q8.16 (CVC paramter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_OFF      $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_ON+1;
// @DOC_FIELD_TEXT ADFPS upper threshold for turning off part of the ADF process, deafult 0.023438, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_CLEAN   $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_OFF+1;
// @DOC_FIELD_TEXT ADFPS lower threshold for turning off part of the ADF process, deafult -0.023438, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_NOISY   $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_CLEAN+1;
// @DOC_FIELD_TEXT ADFPS threshold for turning off post-processing, default 0.03125, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_POSTP   $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_NOISY+1;
// @DOC_FIELD_TEXT MGDC threshold for detecting speech, default 0.023357, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_TH_ADF_DLPZ         $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_POSTP+1;
// @DOC_FIELD_TEXT Microphone Separation Distance, default 0.0625, Q6.18 (CVC paramter)
// @DOC_FIELD_FORMAT Q6.18
.CONST $M.adf_alg_1_0_0.OFFSET_PREP_DT_MIC         $M.adf_alg_1_0_0.OFFSET_TH_ADF_DLPZ+1;
// @DOC_FIELD_TEXT Square root of subtraction factor, default 0.836660026534076, Q1.23 (CVC paramter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.adf_alg_1_0_0.OFFSET_SQRT_PREP_SUBFACTOR $M.adf_alg_1_0_0.OFFSET_PREP_DT_MIC+1;
// @DOC_FIELD_TEXT ADF Gain Replication Adjustment, default 0, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_REPL_ADJUST         $M.adf_alg_1_0_0.OFFSET_SQRT_PREP_SUBFACTOR+1;
// @DOC_FIELD_TEXT ADF Replication Power Factor, default 0.25, Q4.20 (CVC parameter)
// @DOC_FIELD_FORMAT Q4.20
.CONST $M.adf_alg_1_0_0.OFFSET_REPL_POWER          $M.adf_alg_1_0_0.OFFSET_REPL_ADJUST+1;

// -----------------------------------------------------------------------------
// ADFRNR control
// - RNR_ALFA:    time constant in Q23
// - RNR_ADJUST:  Q20; default = 1.0
//                increasing this value reduces RNR aggressiveness
// - RNR_BIAS:    SNR estimation bias, L2dB Q16,
//                positive dB reduces aggressiveness,
//                negative dB increases aggressiveness
// - RNR_TRANS:   SNR estimation bias transition - controls ADFRNR switching, Q20
//                0.0 => smooth transitioning; 8.0 => hard-switching; default = 1.0
// -----------------------------------------------------------------------------
// @DOC_FIELD_TEXT ADFRNR SNR estimation alpha factor, default 0.208934889149704, Q1.23 (CVC parameter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_ALFA            $M.adf_alg_1_0_0.OFFSET_REPL_POWER+1;
// @DOC_FIELD_TEXT ADFRNR gain adjustment, default 0.125, Q4.20 (CVC parameter)
// @DOC_FIELD_FORMAT Q4.20
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST          $M.adf_alg_1_0_0.OFFSET_RNR_ALFA+1;
// @DOC_FIELD_TEXT ADFRNR bias control, default 0, Q8.16 (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_BIAS            $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST+1;
// @DOC_FIELD_TEXT ADFRNR transition control, default 0.125, Q4.20 (CVC parameter)
// @DOC_FIELD_FORMAT Q4.20
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_TRANS           $M.adf_alg_1_0_0.OFFSET_RNR_BIAS+1;

// For Mic Gain Differential Compensation
// @DOC_FIELD_TEXT Internal, default 0, Q8.16, set by headset system via PS-key
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.adf_alg_1_0_0.OFFSET_L2FBpXD  		       $M.adf_alg_1_0_0.OFFSET_RNR_TRANS+1;

// -----------------------------------------------------------------------------
// Internal Variables Start from here
// -----------------------------------------------------------------------------
.CONST $M.adf_alg_1_0_0.OFFSET_INTERNAL_START      $M.adf_alg_1_0_0.OFFSET_L2FBpXD+1;

//SP.  Keep V0_Real, V0_Imag, V0_Exp, LPz0, V1_Real, V1_Imag, V0_Exp, and LPz1
//     consequtive and in order.  Functions rely on this arangement
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V0_real            $M.adf_alg_1_0_0.OFFSET_INTERNAL_START+0;
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V0_imag		      $M.adf_alg_1_0_0.OFFSET_PTR_V0_real+1;
.CONST $M.adf_alg_1_0_0.OFFSET_V0_EXP_PTR             $M.adf_alg_1_0_0.OFFSET_PTR_V0_imag+1;    // SP. Same value as OFFSET_X0_EXP_PTR
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPz0		         $M.adf_alg_1_0_0.OFFSET_V0_EXP_PTR+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V1_real            $M.adf_alg_1_0_0.OFFSET_ADF_LPz0+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V1_imag		      $M.adf_alg_1_0_0.OFFSET_PTR_V1_real+1;
.CONST $M.adf_alg_1_0_0.OFFSET_V1_EXP_PTR             $M.adf_alg_1_0_0.OFFSET_PTR_V1_imag+1;    // SP. Same value as OFFSET_X1_EXP_PTR
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPz1		         $M.adf_alg_1_0_0.OFFSET_V1_EXP_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_muAt    		       $M.adf_alg_1_0_0.OFFSET_ADF_LPz1+1;      // SPTBD .  use scratch register?

// SP. Keep ct_Px0, dL2Px0FB, &L2Px0t0 Consequtive and in order
.CONST $M.adf_alg_1_0_0.OFFSET_ct_Px0    		       $M.adf_alg_1_0_0.OFFSET_muAt+1;
.CONST $M.adf_alg_1_0_0.OFFSET_dL2Px0FB  		       $M.adf_alg_1_0_0.OFFSET_ct_Px0+1;
.CONST $M.adf_alg_1_0_0.OFFSET_L2Px0t0  		       $M.adf_alg_1_0_0.OFFSET_dL2Px0FB+1;
// SP. Keep ct_Px1, dL2Px1FB, &L2Px1t0 Consequtive and in order
.CONST $M.adf_alg_1_0_0.OFFSET_ct_Px1    		       $M.adf_alg_1_0_0.OFFSET_L2Px0t0+1;
.CONST $M.adf_alg_1_0_0.OFFSET_dL2Px1FB  		       $M.adf_alg_1_0_0.OFFSET_ct_Px1+1;
.CONST $M.adf_alg_1_0_0.OFFSET_L2Px1t0  		       $M.adf_alg_1_0_0.OFFSET_dL2Px1FB+1;

.CONST $M.adf_alg_1_0_0.OFFSET_ct_init  		       $M.adf_alg_1_0_0.OFFSET_L2Px1t0+1;
// For Mic Gain Differential Compensation
.CONST $M.adf_alg_1_0_0.OFFSET_MGDCexp  		       $M.adf_alg_1_0_0.OFFSET_ct_init+1;
.CONST $M.adf_alg_1_0_0.OFFSET_MGDCmts  		       $M.adf_alg_1_0_0.OFFSET_MGDCexp+1;

.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_L2FBpXDst 	       $M.adf_alg_1_0_0.OFFSET_MGDCmts+1;
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_hold_adapt 	       $M.adf_alg_1_0_0.OFFSET_MGDC_L2FBpXDst+1;
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_switch_output      $M.adf_alg_1_0_0.OFFSET_MGDC_hold_adapt+1;
.CONST $M.adf_alg_1_0_0.OFFSET_adfps_option_func       $M.adf_alg_1_0_0.OFFSET_MGDC_switch_output+1;
.CONST $M.adf_alg_1_0_0.OFFSET_adfps_mode              $M.adf_alg_1_0_0.OFFSET_adfps_option_func+1;
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_Diff_LPz            $M.adf_alg_1_0_0.OFFSET_adfps_mode+1;

.CONST $M.adf_alg_1_0_0.OFFSET_PreP_func_ptr              $M.adf_alg_1_0_0.OFFSET_ADF_Diff_LPz+1;

.CONST $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor              $M.adf_alg_1_0_0.OFFSET_PreP_func_ptr+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor_T              $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PreP_G_mgdc_fmb              $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor_T+1;

.CONST $M.adf_alg_1_0_0.OFFSET_G_RatioX1X0              $M.adf_alg_1_0_0.OFFSET_PreP_G_mgdc_fmb+1;
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LALFALPZ              $M.adf_alg_1_0_0.OFFSET_G_RatioX1X0+1;

.CONST $M.adf_alg_1_0_0.OFFSET_num_taps              $M.adf_alg_1_0_0.OFFSET_ADF_LALFALPZ+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PP_kL                 $M.adf_alg_1_0_0.OFFSET_num_taps+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PP_kH                 $M.adf_alg_1_0_0.OFFSET_PP_kL+1;
.CONST $M.adf_alg_1_0_0.OFFSET_compara_mn_factor      $M.adf_alg_1_0_0.OFFSET_PP_kH+1;

// SPTBD - Can simplify using function pointers?
.CONST $M.adf_alg_1_0_0.OFFSET_bypass_mgdc      $M.adf_alg_1_0_0.OFFSET_compara_mn_factor+1;
.CONST $M.adf_alg_1_0_0.OFFSET_bypass_postp_rpt  $M.adf_alg_1_0_0.OFFSET_bypass_mgdc+1;
.CONST $M.adf_alg_1_0_0.OFFSET_wide_mic_enabled  $M.adf_alg_1_0_0.OFFSET_bypass_postp_rpt+1;

// $CVCLIB.MA.STRUC: L2Th_adfps
.CONST $M.adf_alg_1_0_0.OFFSET_L2Th_adfps          $M.adf_alg_1_0_0.OFFSET_wide_mic_enabled+1;
.CONST $M.adf_alg_1_0_0.OFFSET_L2Th_adfps_alpha    $M.adf_alg_1_0_0.OFFSET_L2Th_adfps+1;

// $CVCLIB.MA.STRUC: LpXfb_adfps
.CONST $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps         $M.adf_alg_1_0_0.OFFSET_L2Th_adfps_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps_alpha   $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps+1;

// $CVCLIB.MA.STRUC: LpVa
.CONST $M.adf_alg_1_0_0.OFFSET_LpVa                $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_LpVa_alpha          $M.adf_alg_1_0_0.OFFSET_LpVa+1;

// $CVCLIB.MA.STRUC: LpVp
.CONST $M.adf_alg_1_0_0.OFFSET_LpVp                $M.adf_alg_1_0_0.OFFSET_LpVa_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_LpVp_alpha          $M.adf_alg_1_0_0.OFFSET_LpVp+1;

// ADFRNR states
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_BYPASS_FLAG     $M.adf_alg_1_0_0.OFFSET_LpVp_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_DIFF_DLPZ       $M.adf_alg_1_0_0.OFFSET_RNR_BYPASS_FLAG+1;
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST_USED     $M.adf_alg_1_0_0.OFFSET_RNR_DIFF_DLPZ+1;

// Gain replication High Band
.CONST $M.adf_alg_1_0_0.OFFSET_G_HB                $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST_USED+1;

// Size of the block
.CONST   $M.adf_alg_1_0_0.STRUCT_SIZE              $M.adf_alg_1_0_0.OFFSET_G_HB+1;

// @END  DATA_OBJECT ADFDATAOBJECT


.CONST   $MAX_24                 0x7fffff;
.CONST   $MIN_24                 0x800000;
.CONST   $MIN_48_MSB             0x800000;
.CONST   $MIN_48_LSB             0;
.CONST   $MAX_48_MSB             0x7fffff;
.CONST   $MAX_48_LSB             0xffffff;

#endif // end of _adf_alg_1_0_0_LIB_H


