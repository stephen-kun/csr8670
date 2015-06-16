// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef _ASF_LIB_H
#define _ASF_LIB_H

// -----------------------------------------------------------------------------
// ASF external constants
// -----------------------------------------------------------------------------
.CONST $asf100.BIN_SKIPPED                      1;
.CONST $asf100.NUM_PROC                         63;
.CONST $asf100.SCRATCH_SIZE_DM1                 (6+5) * $asf100.NUM_PROC;
.CONST $asf100.SCRATCH_SIZE_DM2                 (6+5) * $asf100.NUM_PROC;


// -----------------------------------------------------------------------------
// ASF data object structure
// -----------------------------------------------------------------------------

// @DATA_OBJECT ASF_DATAOBJECT

// @DOC_FIELD_TEXT Pointer to left channel (X0)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.Z0_FIELD                         0;

// @DOC_FIELD_TEXT Pointer to right channel (X1) (real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.Z1_FIELD                         1;

// @DOC_FIELD_TEXT Pointer to X length (FFT size)
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.MODE_FIELD                       2;

// @DOC_FIELD_TEXT Pointer to Parameters     @DOC_LINK @DATA_OBJECT  ASF_PARAM_OBJECT
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.PARAM_FIELD                      3;

// @DOC_FIELD_TEXT Pointer to Parameters
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.POWER_ADJUST_FIELD               4;

// @DOC_FIELD_TEXT Pointer to DM1 scratch block, with size of '$asf100.SCRATCH_SIZE_DM1'
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.SCRATCH_DM1_FIELD                5;

// @DOC_FIELD_TEXT Pointer to DM2 scratch block, with size of '$asf100.SCRATCH_SIZE_DM2'
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.SCRATCH_DM2_FIELD                6;

// @DOC_FIELD_TEXT Pointer to function of application preprocessing
// @DOC_FIELD_TEXT This function is executed after channel alingment.
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.FUNC_APP_PREP_FIELD              7;

// @DOC_FIELD_TEXT Pointer to function of application post processing
// @DOC_FIELD_TEXT This function is executed at the end of all ASF process.
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.FUNC_APP_PP_FIELD                8;

// @DOC_FIELD_TEXT Pointer to beamformer function eg. near-end, far-end, etc
// @DOC_FIELD_FORMAT Pointer
.CONST $asf100.BEAM_FUNC_FIELD                  9;

// @DOC_FIELD_TEXT Beam_mode = 0 -> Fixed Delay and Sum Beamforming
// @DOC_FIELD_TEXT           = 1 -> Adaptive MVDR Beamforming
// @DOC_FIELD_FORMAT Integer
.CONST $asf100.BEAM_MODE_FIELD                  10;


.CONST $asf100.INTERNAL_START_FIELD             11;

// .............................................................................
// Internal fields
// .............................................................................

// DATA pointers
.CONST $asf100.PX0N_FIELD                 0 + $asf100.INTERNAL_START_FIELD;
.CONST $asf100.PX1N_FIELD                 1 + $asf100.PX0N_FIELD;
.CONST $asf100.PXCRN_FIELD                1 + $asf100.PX1N_FIELD;
.CONST $asf100.PXCIN_FIELD                1 + $asf100.PXCRN_FIELD;
.CONST $asf100.COH_FIELD                  1 + $asf100.PXCIN_FIELD;
.CONST $asf100.WNR_G_FIELD                1 + $asf100.COH_FIELD;
.CONST $asf100.BEAM_CC0_REAL_FIELD        1 + $asf100.WNR_G_FIELD;            // q1.23
.CONST $asf100.BEAM_CC0_IMAG_FIELD        1 + $asf100.BEAM_CC0_REAL_FIELD;    // q1.23
.CONST $asf100.BEAM_PHI0_REAL_FIELD       1 + $asf100.BEAM_CC0_IMAG_FIELD;    // q1.23
.CONST $asf100.BEAM_PHI0_IMAG_FIELD       1 + $asf100.BEAM_PHI0_REAL_FIELD;   // q1.23
.CONST $asf100.BEAM_FD_W0_REAL_FIELD      1 + $asf100.BEAM_PHI0_IMAG_FIELD;   // q4.20
.CONST $asf100.BEAM_FD_W0_IMAG_FIELD      1 + $asf100.BEAM_FD_W0_REAL_FIELD;  // q4.20
.CONST $asf100.BEAM_FD_W1_REAL_FIELD      1 + $asf100.BEAM_FD_W0_IMAG_FIELD;  // q4.20
.CONST $asf100.BEAM_FD_W1_IMAG_FIELD      1 + $asf100.BEAM_FD_W1_REAL_FIELD;  // q4.20
.CONST $asf100.BEAM_FW_W1_REAL_FIELD      1 + $asf100.BEAM_FD_W1_IMAG_FIELD;  // q1.23
.CONST $asf100.BEAM_FW_W1_IMAG_FIELD      1 + $asf100.BEAM_FW_W1_REAL_FIELD;  // q1.23
.CONST $asf100.BEAM_COMP_T_REAL_FIELD     1 + $asf100.BEAM_FW_W1_IMAG_FIELD;  // q4.20
.CONST $asf100.BEAM_COMP_T_IMAG_FIELD     1 + $asf100.BEAM_COMP_T_REAL_FIELD; // q4.20
.CONST $asf100.BEAM_TR0_FIELD             1 + $asf100.BEAM_COMP_T_IMAG_FIELD; // q1.23
.CONST $asf100.BEAM_TR1_FIELD             1 + $asf100.BEAM_TR0_FIELD;         // q1.23
.CONST $asf100.COH_COS_FIELD              1 + $asf100.BEAM_TR1_FIELD;
.CONST $asf100.COH_SIN_FIELD              1 + $asf100.COH_COS_FIELD;
.CONST $asf100.COH_G_FIELD                1 + $asf100.COH_SIN_FIELD;
// Start consecutive (X0/X1)
.CONST $asf100.X0_REAL_FIELD              1 + $asf100.COH_G_FIELD;
.CONST $asf100.X0_IMAG_FIELD              1 + $asf100.X0_REAL_FIELD;
.CONST $asf100.X0_BEXP_FIELD              1 + $asf100.X0_IMAG_FIELD;
.CONST $asf100.X1_REAL_FIELD              1 + $asf100.X0_BEXP_FIELD;
.CONST $asf100.X1_IMAG_FIELD              1 + $asf100.X1_REAL_FIELD;
.CONST $asf100.X1_BEXP_FIELD              1 + $asf100.X1_IMAG_FIELD;
.CONST $asf100.X0_SAVED_REAL_FIELD        1 + $asf100.X1_BEXP_FIELD;
.CONST $asf100.X0_SAVED_IMAG_FIELD        1 + $asf100.X0_SAVED_REAL_FIELD;
.CONST $asf100.X0_SAVED_BEXP_FIELD        1 + $asf100.X0_SAVED_IMAG_FIELD;
// End consecutive (X0/X1)

.CONST $asf100.COH_IMAG_FIELD             1 + $asf100.X0_SAVED_BEXP_FIELD;

// Scratch pointers
// Start consecutive (PXCRNT:PXCINT)
.CONST $asf100.SCRATCH_PXCRNT_FIELD       1 + $asf100.COH_IMAG_FIELD;
.CONST $asf100.SCRATCH_PXCINT_FIELD       1 + $asf100.SCRATCH_PXCRNT_FIELD;
.CONST $asf100.SCRATCH_PX0NT_FIELD        1 + $asf100.SCRATCH_PXCINT_FIELD;
.CONST $asf100.SCRATCH_PX1NT_FIELD        1 + $asf100.SCRATCH_PX0NT_FIELD;
// End consecutive (PXCRNT:PXCINT)
.CONST $asf100.SCRATCH_LPX0T_FIELD        1 + $asf100.SCRATCH_PX1NT_FIELD;   // q8.16
.CONST $asf100.SCRATCH_LPX1T_FIELD        1 + $asf100.SCRATCH_LPX0T_FIELD;   // q8.16

// Module Bypass Flag
.CONST $asf100.BYPASS_FLAG_WNR_FIELD      1 + $asf100.SCRATCH_LPX1T_FIELD;
.CONST $asf100.BYPASS_FLAG_COH_FIELD      1 + $asf100.BYPASS_FLAG_WNR_FIELD;
.CONST $asf100.BYPASS_FLAG_BF_FIELD       1 + $asf100.BYPASS_FLAG_COH_FIELD;

// .............................................................................
// WNR Object fields
// .............................................................................
.CONST $asf100.wnr.G1_FIELD               1 + $asf100.BYPASS_FLAG_BF_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_EXP_FIELD   1 + $asf100.wnr.G1_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_LB_FIELD    1 + $asf100.wnr.PHS_FACTOR_EXP_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_TR_FIELD    1 + $asf100.wnr.PHS_FACTOR_LB_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_HB_FIELD    1 + $asf100.wnr.PHS_FACTOR_TR_FIELD;
.CONST $asf100.wnr.MEAN_PWR_FIELD         1 + $asf100.wnr.PHS_FACTOR_HB_FIELD;
.CONST $asf100.wnr.MEAN_G_FIELD           1 + $asf100.wnr.MEAN_PWR_FIELD;
.CONST $asf100.wnr.MEAN_CC0_FIELD         1 + $asf100.wnr.MEAN_G_FIELD;
.CONST $asf100.wnr.COH_ATK_FIELD          1 + $asf100.wnr.MEAN_CC0_FIELD;
.CONST $asf100.wnr.COH_DEC_FIELD          1 + $asf100.wnr.COH_ATK_FIELD;
.CONST $asf100.wnr.DETECT_FLAG_FIELD      1 + $asf100.wnr.COH_DEC_FIELD;
.CONST $asf100.wnr.COHERENCE_FIELD        1 + $asf100.wnr.DETECT_FLAG_FIELD;
.CONST $asf100.wnr.WIND_FIELD             1 + $asf100.wnr.COHERENCE_FIELD;
.CONST $asf100.WNROBJ_END_FIELD           0 + $asf100.wnr.WIND_FIELD;
// WNR Object fields end


// .............................................................................
// BF Object fields
// .............................................................................
// following are used by BF

// SCRATCH
// Start consecutive (W0/W1/Z0_FDSB)
.CONST $asf100.bf.SCRATCH_W0_REAL_FIELD      1 + $asf100.WNROBJ_END_FIELD;   // q4.20
.CONST $asf100.bf.SCRATCH_W0_IMAG_FIELD      1 + $asf100.bf.SCRATCH_W0_REAL_FIELD; // q4.20 
.CONST $asf100.bf.SCRATCH_W1_REAL_FIELD      1 + $asf100.bf.SCRATCH_W0_IMAG_FIELD; // q4.20
.CONST $asf100.bf.SCRATCH_W1_IMAG_FIELD      1 + $asf100.bf.SCRATCH_W1_REAL_FIELD; // q4.20
.CONST $asf100.bf.SCRATCH_Z0_FDSB_REAL_FIELD 1 + $asf100.bf.SCRATCH_W1_IMAG_FIELD;
.CONST $asf100.bf.SCRATCH_Z0_FDSB_IMAG_FIELD 1 + $asf100.bf.SCRATCH_Z0_FDSB_REAL_FIELD;
.CONST $asf100.bf.SCRATCH_BEXP_Z0_FDSB_FIELD 1 + $asf100.bf.SCRATCH_Z0_FDSB_IMAG_FIELD;
// End consecutive (W0/W1/Z0_FDISB)
.CONST $asf100.bf.SCRATCH_PS0T_FIELD         1 + $asf100.bf.SCRATCH_BEXP_Z0_FDSB_FIELD;  // q1.23
.CONST $asf100.bf.SCRATCH_NPX0_FIELD         1 + $asf100.bf.SCRATCH_PS0T_FIELD;     // q4.20
.CONST $asf100.bf.SCRATCH_PS1T_FIELD         1 + $asf100.bf.SCRATCH_NPX0_FIELD;     // q1.23   
.CONST $asf100.bf.SCRATCH_NEG_D_FIELD        1 + $asf100.bf.SCRATCH_PS1T_FIELD;     // q2.22
.CONST $asf100.bf.BEAM_FW_W0_REAL_FIELD      1 + $asf100.bf.SCRATCH_NEG_D_FIELD;   // q1.23
.CONST $asf100.bf.BEAM_TEMP_FIELD            1 + $asf100.bf.BEAM_FW_W0_REAL_FIELD;
.CONST $asf100.BF_END_FIELD                  0 + $asf100.bf.BEAM_TEMP_FIELD;
// BF Object fields end

.CONST $asf100.STRUC_SIZE                    1 + $asf100.BF_END_FIELD;

// @END  DATA_OBJECT ASF_DATAOBJECT



// -----------------------------------------------------------------------------
// ASF parameter structure
// -----------------------------------------------------------------------------
// @DATA_OBJECT  DATA_OBJECT ASF_PARAM_OBJECT

// @DOC_FIELD_TEXT      Microphone distance Parameters (in meter), range is .005 to .070 (request to bring upper range to .15)
// @DOC_FIELD_FORMAT    Q1.23 format, in meter
.CONST $asf100.param.MIC_DIST_FIELD             0;

// @DOC_FIELD_TEXT      Wind Gain Aggressiveness .
// @DOC_FIELD_TEXT      The larger the value the more noise is reduced. 0: no wind reduction.
// @DOC_FIELD_FORMAT    Q1.23 format
.CONST $asf100.wnr.param.GAIN_AGGR_FIELD        1;

// @DOC_FIELD_TEXT      Silence Threshold, in log2 dB.
// @DOC_FIELD_TEXT      Signal will be treated as non-wind silence if power is below this threshold.
// @DOC_FIELD_FORMAT    Q8.16 format
.CONST $asf100.wnr.param.THRESH_SILENCE_FIELD   2;

// @DOC_FIELD_TEXT      Speech Degration Factor for Target Capture Beam. Range is 0.1 to 1.0
// @DOC_FIELD_FORMAT    Q1.23 format
.CONST $asf100.bf.param.BETA0_FIELD             3;

// @DOC_FIELD_TEXT      Speech Degration Factor for Target Rejection Beam. Range is 0.1 to 1.0
// @DOC_FIELD_FORMAT    Q1.23 format
.CONST $asf100.bf.param.BETA1_FIELD             4;

// @DOC_FIELD_TEXT      Wind Noise Reduction Phase Threshold. Range is 0 to 1.0
// @DOC_FIELD_FORMAT    Q1.23 format
.CONST $asf100.wnr.param.THRESH_PHASE_FIELD     5;

// @DOC_FIELD_TEXT      Wind Noise Reduction Coherence Threshold. Range is 0 to 1.0
// @DOC_FIELD_FORMAT    Q1.23 format
.CONST $asf100.wnr.param.THRESH_COHERENCE_FIELD 6;

// @END  DATA_OBJECT ASF_PARAM_OBJECT

#endif   // _ASF_LIB_H
