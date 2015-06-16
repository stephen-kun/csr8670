// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#ifndef _MGDC100_LIB_H
#define  _MGDC100_LIB_H

// -----------------------------------------------------------------------------
// MGDC DATA OBJECT
// -----------------------------------------------------------------------------
// @DATA_OBJECT         MGDC_DATAOBJECT

// @DOC_FIELD_TEXT Pointer to left channel (X0)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.X0_FIELD                     0;

// @DOC_FIELD_TEXT Pointer to right channel (X1) (real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.X1_FIELD                     1;

// @DOC_FIELD_TEXT Pointer to Parameters     @DOC_LINK @DATA_OBJECT  MGDC_PARAM
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.PARAM_FIELD                  2;

// @DOC_FIELD_TEXT Pointer to the varialble holding 'number of fft bins'
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.PTR_NUMFREQ_BINS_FIELD       3;

// @DOC_FIELD_TEXT Pointer to G (OMS/DMS)
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.PTR_G_OMS_FIELD              4;

// @DOC_FIELD_TEXT MGDC Maximum compensation (in dB), Q8.16
// @DOC_FIELD_FORMAT Q8.16
.CONST $mgdc100.FRONTMICBIAS_FIELD           5;

// @DOC_FIELD_TEXT Pointer to an external application mode flag
// @DOC_FIELD_TEXT Output: 2-mic mode: 0, 1-mic mode: non-zero
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.PTR_MICMODE_FIELD            6;

// @DOC_FIELD_TEXT Pointer to an external OMS_VAD_FIELD variable
// @DOC_FIELD_FORMAT Pointer
.CONST $mgdc100.PTR_OMS_VAD_FIELD            7;

// @DOC_FIELD_TEXT Internal, default 0, Q8.16, set by headset system via PS-key
// @DOC_FIELD_FORMAT Q8.16
.CONST $mgdc100.L2FBPXD_FIELD                8;

// Internal fields
.CONST $mgdc100.MAXCOMP_FIELD                9;
.CONST $mgdc100.TH0_FIELD                    10;
.CONST $mgdc100.TH1_FIELD                    11;
.CONST $mgdc100.L2FBPX0T_FIELD               12;
.CONST $mgdc100.L2FBPX1T_FIELD               13;
.CONST $mgdc100.L2FBPXDST_FIELD              14;
.CONST $mgdc100.EXP_GAIN_FIELD               15;
.CONST $mgdc100.MTS_GAIN_FIELD               16;
.CONST $mgdc100.MEAN_OMS_G_FIELD             17;
.CONST $mgdc100.HOLD_ADAPT_FIELD             18;
.CONST $mgdc100.SWITCH_OUTPUT_FIELD          19;
.CONST $mgdc100.MGDC_UPDATE_FIELD            20;

.CONST $mgdc100.STRUC_SIZE                   21;

// @END DATA_OBJECT     MGDC_DATAOBJECT

// -----------------------------------------------------------------------------
// MGDC USER PARAMETER STRUCTURE
// -----------------------------------------------------------------------------
// @DATA_OBJECT         MGDC_PARAM

// @DOC_FIELD_TEXT MGDC Maximum compensation, default 1.99315685693241720 in Q8.16
// @DOC_FIELD_FORMAT Q8.16
.CONST $mgdc100.param.MAXCOMP_FIELD          0;

// @DOC_FIELD_TEXT Threshold for detection of channel lost
// @DOC_FIELD_FORMAT Q8.16
.CONST $mgdc100.param.TH_FIELD               1;

// @END DATA_OBJECT     MGDC_PARAM

#endif // _MGDC100_LIB_H
