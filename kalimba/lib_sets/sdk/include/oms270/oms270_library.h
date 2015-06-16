// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef DMS100_LIB_H
#define DMS100_LIB_H

// -----------------------------------------------------------------------------
// OMS270 version number
//    v.0.0.1: initial version
//    v.1.0.0: wideband
//    v.1.1.0: wnr
//    v.1.2.0: wideband resource reduction
//    v.2.0.0: PBP
//    v.2.1.0: PBP/LINEAR
//
// DMS100 version number
//    ver 1.0.0 - from OMS270 v.2.1.0
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// OMS270 PBP mode external constants
// -----------------------------------------------------------------------------
.CONST $oms270.MAX_MIN_SEARCH_LENGTH            68;
.CONST $oms270.PBP.DIM_NB                       25;
.CONST $oms270.PBP.DIM_WB                       30;
.CONST $oms270.PBP.NUM_LINEAR_BAND              15;
.CONST $oms270.PBP.MS_BAND                      2;
.CONST $oms270.PBP.NOISE_THRESHOLD              0.8;

.CONST $M.oms270.QUE_LENGTH                     ($oms270.MAX_MIN_SEARCH_LENGTH * $oms270.PBP.MS_BAND);
.CONST $M.oms270.narrow_band.STATE_LENGTH       ($oms270.PBP.DIM_NB * 4 + 2 * $oms270.PBP.MS_BAND);
.CONST $M.oms270.wide_band.STATE_LENGTH         ($oms270.PBP.DIM_WB * 4 + 2 * $oms270.PBP.MS_BAND);
.CONST $M.oms270.narrow_band.SCRATCH_LENGTH     ($oms270.PBP.DIM_NB + 2 * ( 65-2-$oms270.PBP.NUM_LINEAR_BAND)); // max(121, $oms270.PBP.DIM_NB * 4 + $oms270.PBP.MS_BAND)
.CONST $M.oms270.wide_band.SCRATCH_LENGTH       ($oms270.PBP.DIM_WB + 2 * (129-2-$oms270.PBP.NUM_LINEAR_BAND)); // max(254, $oms270.PBP.DIM_WB * 4 + $oms270.PBP.MS_BAND)
.CONST $M.oms270.NOISE_THRESHOLD                ($oms270.PBP.NOISE_THRESHOLD);

// -----------------------------------------------------------------------------
// OMS270 Linear mode external constants
// -----------------------------------------------------------------------------
.CONST $oms270.linear.DIM                       65;
.CONST $oms270.linear.narrow_band.MS_BAND       2;
.CONST $oms270.linear.wide_band.MS_BAND         3;
.CONST $oms270.linear.NOISE_THRESHOLD           0.9;

.CONST $oms270.linear.narrow_band.QUE_LENGTH    ($M.oms270.QUE_LENGTH);
.CONST $oms270.linear.wide_band.QUE_LENGTH      ($oms270.MAX_MIN_SEARCH_LENGTH * $oms270.linear.wide_band.MS_BAND);
.CONST $oms270.linear.narrow_band.STATE_LENGTH  ($oms270.linear.DIM * 2 + 2 * $oms270.linear.narrow_band.MS_BAND);
.CONST $oms270.linear.wide_band.STATE_LENGTH    ($oms270.linear.DIM * 2 + 2 * $oms270.linear.wide_band.MS_BAND);
.CONST $oms270.linear.SCRATCH_LENGTH            ($oms270.linear.DIM * 4 + $oms270.linear.wide_band.MS_BAND);   // 263

// -----------------------------------------------------------------------------
// DMS100 external constants
// -----------------------------------------------------------------------------
.CONST $dms100.DIM                              65;
.CONST $dms100.MIN_SEARCH_LENGTH                34;
.CONST $dms100.MS_BAND                          8;
.CONST $dms100.NOISE_THRESHOLD                  0.8;

.CONST $dms100.QUE_LENGTH                       ($dms100.MIN_SEARCH_LENGTH * $dms100.MS_BAND);
.CONST $dms100.STATE_LENGTH                     ($dms100.DIM * 6 + $dms100.MS_BAND * 2);
.CONST $dms100.SCRATCH_LENGTH                   ($dms100.DIM * 4 + $dms100.MS_BAND);   // 268


// -----------------------------------------------------------------------------
// OMS270/DMS100 DATA STRUCTURE
// -----------------------------------------------------------------------------

// @DATA_OBJECT OMS_DATAOBJECT

// @DOC_FIELD_TEXT OMS mode object (wideband/narrowband)
// @DOC_FIELD_TEXT Available objects:
// @DOC_FIELD_TEXT    - $oms270.narrow_band.mode
// @DOC_FIELD_TEXT    - $oms270.wide_band.mode
// @DOC_FIELD_TEXT    - $oms270.linear.narrow_band.mode
// @DOC_FIELD_TEXT    - $oms270.linear.wide_band.mode
// @DOC_FIELD_TEXT    - $dms100.narrow_band.mode
// @DOC_FIELD_TEXT    - $dms100.wide_band.mode
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_MODE_FIELD              0;
// @DOC_FIELD_TEXT Configuration word, CVC parameter
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.oms270.CONTROL_WORD_FIELD          $M.oms270.PTR_MODE_FIELD + 1;
// @DOC_FIELD_TEXT Bitmask to bypass OMS
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.oms270.BYPASS_BIT_MASK_FIELD       $M.oms270.CONTROL_WORD_FIELD + 1;
// @DOC_FIELD_TEXT Flag to enable Minimun search (OMS internal process)
// @DOC_FIELD_FORMAT Flag
.CONST $M.oms270.MIN_SEARCH_ON_FIELD         $M.oms270.BYPASS_BIT_MASK_FIELD + 1;
// @DOC_FIELD_TEXT Flag to enable OMS time domain process.
// @DOC_FIELD_FORMAT Flag
.CONST $M.oms270.HARM_ON_FIELD               $M.oms270.MIN_SEARCH_ON_FIELD + 1;
// @DOC_FIELD_TEXT Flag to enable LSA (OMS internal process)
// @DOC_FIELD_FORMAT Flag
.CONST $M.oms270.MMSE_LSA_ON_FIELD           $M.oms270.HARM_ON_FIELD + 1;
// @DOC_FIELD_TEXT FFT window size
// @DOC_FIELD_FORMAT Integer
.CONST $M.oms270.FFT_WINDOW_SIZE_FIELD       $M.oms270.MMSE_LSA_ON_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to input frame of time signal 'x'.
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_INP_X_FIELD             $M.oms270.FFT_WINDOW_SIZE_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to real part of X (FFT of input signal x)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_X_REAL_FIELD            $M.oms270.PTR_INP_X_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to imaginary part of X (FFT of input signal x)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_X_IMAG_FIELD            $M.oms270.PTR_X_REAL_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to block exponent of X (FFT of input signal x)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_BEXP_X_FIELD            $M.oms270.PTR_X_IMAG_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to real part of Y (OMS output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_Y_REAL_FIELD            $M.oms270.PTR_BEXP_X_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to imaginary part of Y (OMS output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_Y_IMAG_FIELD            $M.oms270.PTR_Y_REAL_FIELD + 1;
// @DOC_FIELD_TEXT Initial power in dB.
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.oms270.INITIAL_POWER_FIELD         $M.oms270.PTR_Y_IMAG_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to internal circular buffer, of size '$M.oms270.QUE_LENGTH'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.LPX_QUEUE_START_FIELD       $M.oms270.INITIAL_POWER_FIELD + 1;
// external interpolated G/LPXNZ
// @DOC_FIELD_TEXT Pointer to G
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_G_FIELD                 $M.oms270.LPX_QUEUE_START_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to LpX_nz
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_LPXNZ_FIELD             $M.oms270.PTR_G_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to internal state memory
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_STATE_FIELD             $M.oms270.PTR_LPXNZ_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to scratch memory
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_SCRATCH_FIELD           $M.oms270.PTR_STATE_FIELD + 1;
// @DOC_FIELD_TEXT Nz claculation Alpha, default 0.036805582279178
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.ALFANZ_FIELD                $M.oms270.PTR_SCRATCH_FIELD + 1;
// @DOC_FIELD_TEXT S claculation Alpha, default 0xFF13DE
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.LALFAS_FIELD                $M.oms270.ALFANZ_FIELD + 1;
// @DOC_FIELD_TEXT S claculation Alpha1, default 0xFEEB01
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.LALFAS1_FIELD               $M.oms270.LALFAS_FIELD + 1;
// @DOC_FIELD_TEXT Harmonicity Threshould, CVC parameter
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.HARM_THRESH_FIELD           $M.oms270.LALFAS1_FIELD + 1;
// @DOC_FIELD_TEXT VAD Threshould
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.VAD_THRESH_FIELD            $M.oms270.HARM_THRESH_FIELD + 1;
// @DOC_FIELD_TEXT OMS aggresiveness, CVC parameter
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.AGRESSIVENESS_FIELD         $M.oms270.VAD_THRESH_FIELD + 1;
// @DOC_FIELD_TEXT Pointer to Tone flag, where 0 indicates a tone
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.PTR_TONE_FLAG_FIELD         $M.oms270.AGRESSIVENESS_FIELD + 1;

// -----------------------------------------------------------------------------
// DMS100 Data Object
// -----------------------------------------------------------------------------
// @DOC_FIELD_TEXT Pointer to output channel (Y)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $dms100.Y_FIELD                       1 + $M.oms270.PTR_TONE_FLAG_FIELD;

// @DOC_FIELD_TEXT Pointer to mono (left) channel (X)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $dms100.X_FIELD                       1 + $dms100.Y_FIELD;

// @DOC_FIELD_TEXT Pointer to second (right) channel (D)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $dms100.D_FIELD                       1 + $dms100.X_FIELD;

// @DOC_FIELD_TEXT Pointer to DMS Parameter  @DOC_LINK @DATA_OBJECT DMS_PARAM_OBJECT
// @DOC_FIELD_FORMAT Pointer
.CONST $dms100.PARAM_FIELD                   1 + $dms100.D_FIELD;

// @DOC_FIELD_TEXT Pointer to parameter of Power Adjustment
// @DOC_FIELD_TEXT In log2 dB in Q8.16 format
// @DOC_FIELD_FORMAT Pointer
.CONST $dms100.PTR_POWR_ADJUST_FIELD         1 + $dms100.PARAM_FIELD;

// @DOC_FIELD_TEXT Pointer to external DMS mode
// @DOC_FIELD_FORMAT Pointer
.CONST $dms100.PTR_DMS_MODE_FIELD            1 + $dms100.PTR_POWR_ADJUST_FIELD;

// @DOC_FIELD_TEXT DMS moudule internal fileds start from here
// @DOC_FIELD_FORMAT Field Offset
.CONST $dms100.INTERNAL_FIELD                1 + $dms100.PTR_DMS_MODE_FIELD;

// User Data Pointers
.CONST $dms100.SPP_FIELD                     0 + $dms100.INTERNAL_FIELD;
.CONST $dms100.LPDS_FIELD                    1 + $dms100.SPP_FIELD;
.CONST $dms100.LPN_FIELD                     1 + $dms100.LPDS_FIELD;
.CONST $dms100.VAD_T_LIKE_FIELD              1 + $dms100.LPN_FIELD;
.CONST $dms100.SNR_FIELD                     1 + $dms100.VAD_T_LIKE_FIELD;

// Feature Bypass Flags
.CONST $dms100.MASTER_DMS_MODE_FIELD         1 + $dms100.SNR_FIELD;
.CONST $dms100.GSCHEME_FIELD                 1 + $dms100.MASTER_DMS_MODE_FIELD;
.CONST $dms100.BYPASS_SPP_FIELD              1 + $dms100.GSCHEME_FIELD;
.CONST $dms100.BYPASS_GSMOOTH_FIELD          1 + $dms100.BYPASS_SPP_FIELD;
.CONST $dms100.BYPASS_NFLOOR_FIELD           1 + $dms100.BYPASS_GSMOOTH_FIELD;
.CONST $dms100.BYPASS_NLIFT_FIELD            1 + $dms100.BYPASS_NFLOOR_FIELD;

// Internal States
.CONST $dms100.VAD_VOICED_FIELD              1 + $dms100.BYPASS_NLIFT_FIELD;
.CONST $dms100.VAD_COUNT_FIELD               1 + $dms100.VAD_VOICED_FIELD;
.CONST $dms100.VAD_LIKE_MEAN_FIELD           1 + $dms100.VAD_COUNT_FIELD;
.CONST $dms100.DMS_MODE_FIELD                1 + $dms100.VAD_LIKE_MEAN_FIELD;

// OMS/DMS common fileds
.CONST $M.oms270.DMS_COMMON_FIELD            1 + $dms100.DMS_MODE_FIELD;

.CONST $M.oms270.FUNC_MMS_LPXS_FIELD         0 + $M.oms270.DMS_COMMON_FIELD;
.CONST $M.oms270.FUNC_MMS_PROC_FIELD         1 + $M.oms270.DMS_COMMON_FIELD;
.CONST $M.oms270.PTR_HARM_VALUE_FIELD        2 + $M.oms270.DMS_COMMON_FIELD;
.CONST $M.oms270.LTILT_FIELD                 $M.oms270.PTR_HARM_VALUE_FIELD + 1;
.CONST $M.oms270.VOICED_FIELD                $M.oms270.LTILT_FIELD + 1;
.CONST $M.oms270.MIN_SEARCH_COUNT_FIELD      $M.oms270.VOICED_FIELD + 1;
.CONST $M.oms270.MIN_SEARCH_LENGTH_FIELD     $M.oms270.MIN_SEARCH_COUNT_FIELD + 1;
.CONST $M.oms270.PTR_LPXS_FIELD              $M.oms270.MIN_SEARCH_LENGTH_FIELD + 1;
.CONST $M.oms270.PTR_LPY_FIELD               $M.oms270.PTR_LPXS_FIELD + 1;
.CONST $M.oms270.VOICED_COUNTER_FIELD        $M.oms270.PTR_LPY_FIELD + 1;
.CONST $M.oms270.PTR_LPX_MIN_FIELD           $M.oms270.VOICED_COUNTER_FIELD + 1;

.CONST $M.oms270.WIND_FIELD                  $M.oms270.PTR_LPX_MIN_FIELD + 1;
.CONST $M.oms270.WNR_OBJ_FIELD               $M.oms270.WIND_FIELD + 1;
.CONST $M.oms270.FUNC_WIND_DETECT_FIELD      $M.oms270.WNR_OBJ_FIELD + 1;
.CONST $M.oms270.FUNC_WIND_REDUCTION_FIELD   $M.oms270.FUNC_WIND_DETECT_FIELD + 1;
.CONST $M.oms270.INITIALISED_FIELD           $M.oms270.FUNC_WIND_REDUCTION_FIELD + 1;
.CONST $M.oms270.LIKE_MEAN_FIELD             $M.oms270.INITIALISED_FIELD + 1;
.CONST $M.oms270.TEMP_FIELD                  $M.oms270.LIKE_MEAN_FIELD + 1;
// internal G/LPXNZ
// G/LpX_nz (OMS) -> G_G/MS_LpN (DMS)
.CONST $M.oms270.G_G_FIELD                   $M.oms270.TEMP_FIELD + 1;
.CONST $M.oms270.MS_LPN_FIELD                $M.oms270.G_G_FIELD + 1;
.CONST $M.oms270.PTR_LPX_QUEUE_FIELD         $M.oms270.MS_LPN_FIELD + 1;
.CONST $M.oms270.PTR_LPN_FIELD               $M.oms270.PTR_LPX_QUEUE_FIELD + 1;

// Scratch pointer fields
.CONST $M.oms270.SCRATCH_LPXT_FIELD          $M.oms270.PTR_LPN_FIELD + 1;
.CONST $M.oms270.SCRATCH_LIKE_FIELD          $M.oms270.SCRATCH_LPXT_FIELD + 1;
.CONST $M.oms270.SCRATCH_NZLIFT_FIELD        $M.oms270.SCRATCH_LIKE_FIELD + 1;
.CONST $M.oms270.SCRATCH_LPNZLIFT_FIELD      $M.oms270.SCRATCH_NZLIFT_FIELD + 1;
.CONST $M.oms270.SCRATCH_LTILT_FIELD         $M.oms270.SCRATCH_LPNZLIFT_FIELD + 1;

// Internal field to differentiate between the OMS/DMS mode
.CONST $M.oms270.OMS_MODE_FLAG_FIELD         $M.oms270.SCRATCH_LTILT_FIELD + 1;

// Start: Harmonicity Fields
.CONST $M.oms270.HARM_START_FIELD            $M.oms270.OMS_MODE_FLAG_FIELD + 1;
.CONST $M.oms270.HAM_MODE_FIELD              $M.oms270.HARM_START_FIELD + $harmonicity.MODE_FIELD;
.CONST $M.oms270.HAM_INP_X_FIELD             $M.oms270.HARM_START_FIELD + $harmonicity.INP_X_FIELD;
.CONST $M.oms270.HAM_FFT_WINDOW_SIZE_FIELD   $M.oms270.HARM_START_FIELD + $harmonicity.FFT_WINDOW_SIZE_FIELD;
.CONST $M.oms270.HAM_FLAG_ON_FIELD           $M.oms270.HARM_START_FIELD + $harmonicity.FLAG_ON_FIELD;
.CONST $M.oms270.HARM_VALUE_FIELD            $M.oms270.HARM_START_FIELD + $harmonicity.HARM_VALUE_FIELD;
// End: Harmonicity Fields

.CONST $M.oms270.STRUC_SIZE                  $M.oms270.HARM_START_FIELD + $harmonicity.STRUC_SIZE;
.CONST $dms100.STRUC_SIZE                    $M.oms270.STRUC_SIZE;

// @END  DATA_OBJECT OMS_DATAOBJECT

// -----------------------------------------------------------------------------
// WNR data object
// -----------------------------------------------------------------------------

// @DATA_OBJECT OMSWNR_DATAOBJECT

// @DOC_FIELD_TEXT WNR initialization function pointer
// @DOC_FIELD_TEXT to be set: &$M.oms270.wnr.initialize.func
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.wnr.FUNC_WNR_INIT_FIELD           0;
// @DOC_FIELD_TEXT Pointer to WNR user parameter object  @DOC_LINK @DATA_OBJECT WNR_PRAMOBJECT
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.wnr.PTR_WNR_PARAM_FIELD           1;
// @DOC_FIELD_TEXT Pointer to receive path VAD flag
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.wnr.PTR_RCVVAD_FLAG_FIELD         2;
// @DOC_FIELD_TEXT Pointer to send path VAD flag
// @DOC_FIELD_FORMAT Pointer
.CONST $M.oms270.wnr.PTR_SNDVAD_FLAG_FIELD         3;

// Internal fields
.CONST $M.oms270.wnr.SND_VAD_COUNT_FIELD           4;
.CONST $M.oms270.wnr.HOLD_FIELD                    5;
.CONST $M.oms270.wnr.YWEI_FIELD                    6;
.CONST $M.oms270.wnr.POWER_THRES_FIELD             7;
.CONST $M.oms270.wnr.POWER_LEVEL_FIELD             8;
.CONST $M.oms270.wnr.COUNT_FIELD                   9;
// The following 3 fields need to be consecutive and in order
.CONST $M.oms270.wnr.HIGH_BIN_FIELD                10;
.CONST $M.oms270.wnr.LOW_BIN_FIELD                 11;
.CONST $M.oms270.wnr.ROLLOFF_IDX_FIELD             12;
.CONST $M.oms270.wnr.STRUC_SIZE                    13;

// @END  DATA_OBJECT OMSWNR_DATAOBJECT


// -----------------------------------------------------------------------------
// WNR control parameter block offset
// -----------------------------------------------------------------------------
// @DATA_OBJECT WNR_PRAMOBJECT

// @DOC_FIELD_TEXT WNR aggressiveness, default 1.0, CVC parameter
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.oms270.param.WNR_AGRESSIVENESS_FIELD     0;
// @DOC_FIELD_TEXT WNR power threshold (dB in log2), below which signal is seen as non-wind, CVC parameter
// @DOC_FIELD_FORMAT Integer
.CONST $M.oms270.param.WNR_POWER_THRESHOLD_FIELD   1;
// @DOC_FIELD_TEXT WNR detection hold (number of frames), CVC parameter
// @DOC_FIELD_FORMAT Integer
.CONST $M.oms270.param.WNR_HOLD_FIELD              2;

// @END  DATA_OBJECT WNR_PRAMOBJECT


// -----------------------------------------------------------------------------
// DMS100 Parameter Structure
// -----------------------------------------------------------------------------
// @DATA_OBJECT DMS_PARAM_OBJECT

// @DOC_FIELD_TEXT DMS aggressiveness, default 1.0
// @DOC_FIELD_FORMAT Q1.23
.CONST $dms100.param.AGRESSIVENESS_FIELD           0;

// @DOC_FIELD_TEXT      Residual Noise floor (in log2 dB)
// @DOC_FIELD_FORMAT    Q8.16 format
.CONST $dms100.param.RESIDUAL_NFLOOR_FIELD         1;

// @END  DATA_OBJECT DMS_PARAM_OBJECT

#endif // DMS100_LIB_H
