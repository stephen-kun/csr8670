// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef _HARMONICITY_H
#define _HARMONICITY_H

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------
.CONST $harmonicity.WINDOW_LENGTH               30;
.CONST $harmonicity.DELAY_LENGTH                27;

.CONST $harmonicity.nb.FRAME_SIZE               60;
.CONST $harmonicity.nb.DELAY_START              53;
.CONST $harmonicity.nb.DECIMATION               2;

.CONST $harmonicity.wb.FRAME_SIZE               120;
.CONST $harmonicity.wb.DELAY_START              107;
.CONST $harmonicity.wb.DECIMATION               4;


// -----------------------------------------------------------------------------
// Data Object
// -----------------------------------------------------------------------------
.CONST $harmonicity.MODE_FIELD                  0;
.CONST $harmonicity.INP_X_FIELD                 1;
.CONST $harmonicity.FFT_WINDOW_SIZE_FIELD       2;
.CONST $harmonicity.FLAG_ON_FIELD               3;
.CONST $harmonicity.HARM_VALUE_FIELD            4;
.CONST $harmonicity.AMDF_MEM_START_FIELD        5;
.CONST $harmonicity.STRUC_SIZE                 ($harmonicity.AMDF_MEM_START_FIELD + $harmonicity.DELAY_LENGTH);


// -----------------------------------------------------------------------------
// Mode Structure
// -----------------------------------------------------------------------------
.CONST $harmonicity.mode.FRAME_SIZE             0;
.CONST $harmonicity.mode.DELAY_START            1;
.CONST $harmonicity.mode.DECIMATION             2;

#endif // _HARMONICITY_H


