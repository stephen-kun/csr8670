// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef _DMSS_LIB_H
#define  _DMSS_LIB_H

// -----------------------------------------------------------------------------
// DMSS DATA OBJECT
// -----------------------------------------------------------------------------
// @DATA_OBJECT         DMSS_DATAOBJECT

// @DOC_FIELD_TEXT Pointer to left channel (X0)(real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $dmss.X0_FIELD                     0;

// @DOC_FIELD_TEXT Pointer to right channel (X1) (real/imag/BExp)
// @DOC_FIELD_FORMAT Pointer
.CONST $dmss.X1_FIELD                     1;

// @DOC_FIELD_TEXT Pointer to variable holding the number of fft bins.
// @DOC_FIELD_FORMAT Pointer
.CONST $dmss.PTR_NUMBIN_FIELD             2;

.CONST $dmss.INTERNAL_START_FIELD         3;

// Internal fields
.CONST $dmss.LPIN0_FIELD                  0 + $dmss.INTERNAL_START_FIELD;
.CONST $dmss.LPIN1_FIELD                  1 + $dmss.LPIN0_FIELD;
.CONST $dmss.LPOUT0_FIELD                 1 + $dmss.LPIN1_FIELD;
.CONST $dmss.LPOUT1_FIELD                 1 + $dmss.LPOUT0_FIELD;
.CONST $dmss.DIFF_LP_FIELD                1 + $dmss.LPOUT1_FIELD;

.CONST $dmss.STRUC_SIZE                   1 + $dmss.DIFF_LP_FIELD;;

// @END DATA_OBJECT     DMSS_DATAOBJECT


// -----------------------------------------------------------------------------
// DMSS CONSTANTS
// -----------------------------------------------------------------------------
.CONST $dmss100.BIN_SKIPPED               1;
.CONST $dmss100.NUM_PROC                  63;
.CONST $dmss.LP_INIT                     (-48<<16);                    // Q8.16
.CONST $dmss.LALFALPZ                     -5.64371240507421220/(1<<7); // Q8.16

#endif // _DMSS_LIB_H
