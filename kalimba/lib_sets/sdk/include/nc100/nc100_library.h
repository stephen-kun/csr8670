// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef _NC100_LIB_H
#define  _NC100_LIB_H

// -----------------------------------------------------------------------------
// HISTORY:
//    12-11-08 Wed wms 1.0.0: Initial Version, from ADF100
// -----------------------------------------------------------------------------
.CONST  $NC_VERSION                       0x010000;


// -----------------------------------------------------------------------------
// EXTERNAL CONSTANTS
// -----------------------------------------------------------------------------
.CONST $nc100.BIN_SKIPPED           9;
.CONST $nc100.NUM_PROC              55;
.CONST $nc100.NUM_TAPS              2;
.CONST $nc100.DM1_DATA_SIZE		   ((2 + 2*$nc100.NUM_TAPS) * $nc100.NUM_PROC);
.CONST $nc100.DM2_DATA_SIZE		   ((0 + 2*$nc100.NUM_TAPS) * $nc100.NUM_PROC + $nc100.NUM_TAPS+1);
.CONST $nc100.DM1_SCRATCH_SIZE      ((1 + 3*$nc100.NUM_PROC));

// -----------------------------------------------------------------------------
// DATA OBJECT
// -----------------------------------------------------------------------------
// @DATA_OBJECT         NC_DATAOBJECT

// @DOC_FIELD_TEXT Pointer to left channel (X0)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.X0_FIELD                             0;

// @DOC_FIELD_TEXT Pointer to right channel (X1) (real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.X1_FIELD                             1;

// @DOC_FIELD_TEXT Pointer to DM1 data block, with size of '$nc100.DM1_DATA_SIZE'
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.DM1_DATA_FIELD                       2;

// @DOC_FIELD_TEXT Pointer to DM2 data block, with size of '$nc100.DM2_DATA_SIZE'
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.DM2_DATA_FIELD                       3;

// @DOC_FIELD_TEXT Pointer to DM1 scratch block, with size of '$nc100.DM1_SCRATCH_SIZE'
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.DM1_SCRATCH_FIELD                    4;

// @DOC_FIELD_TEXT Pointer to NC_ctrl[] buffer, with size of $nc100.NUM_PROC
// @DOC_FIELD_TEXT DM2 allocation is recommended.
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.NC_CTRL_FIELD                        5;

// @DOC_FIELD_TEXT Pointer to function of application preprocessing
// Do not trash M0/M1, do not trash FP(ARCH2) or r9(ARCH2).
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.FUNC_APP_PREP_FIELD                  6;

// @DOC_FIELD_TEXT Pointer to function of application post-processing
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.FUNC_APP_PP_FIELD                    7;

// @DOC_FIELD_TEXT NC adaptation repeat flag.
// @DOC_FIELD_Flag
.CONST $nc100.RPTP_FLAG_FIELD                      8;

// @DOC_FIELD_TEXT Pointer to OMS G array
// @DOC_FIELD_FORMAT Pointer
.CONST $nc100.G_OMS_FIELD                          9;

// Internal fields

// SP.  Below must match AEC
.CONST $nc100.FNLMS_FIELD                          10;
.CONST $nc100.OFFSET_FNLMS_E_REAL_PTR              0 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_E_IMAG_PTR              1 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_D_EXP_PTR               2 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_D_REAL_PTR              3 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_D_IMAG_PTR              4 + $nc100.FNLMS_FIELD;
// Pointer to a scratch memory in DM2 with size of '2*$nc100.NUM_PROC + 1'
.CONST $nc100.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt    5 + $nc100.FNLMS_FIELD;
.CONST $nc100.FNLMS_END_FIELD                      $nc100.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt;
// SP.  End Match

.CONST $nc100.STRUCT_SIZE                          1 + $nc100.FNLMS_END_FIELD;

// @END DATA_OBJECT     NC_DATAOBJECT

#endif // _NC100_LIB_H


