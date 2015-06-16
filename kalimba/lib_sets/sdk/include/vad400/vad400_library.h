// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change$  $DateTime$
// *****************************************************************************

// *****************************************************************************
// NAME:
//    vad400 Library
//
// DESCRIPTION:
//
// *****************************************************************************

#ifndef VAD400_LIB_H
#define VAD400_LIB_H

// library build version
.CONST $VAD400_VERSION 0x010000;

//******************************************************************************
// VAD400 data structure element offset definitions
//
// The following data object is used for all vad400 modules
//
//******************************************************************************

// @DATA_OBJECT VAD_PRAMS_DATAOBJECT

// @DOC_FIELD_TEXT Attack Time to speech estimation of the VAD.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.ATTACK_TC_FIELD              0;
// @DOC_FIELD_TEXT Decay Time to speech estimation of the VAD.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.DECAY_TC_FIELD               1;
// @DOC_FIELD_TEXT Attack Time to noise estimation of the VAD.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.ENVELOPE_TC_FIELD            2;
// @DOC_FIELD_TEXT Initialization time (in sec.) for VAD when the vad detection in 0.
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.Parameter.INIT_FRAME_THRESH_FIELD      3;
// @DOC_FIELD_TEXT Ratio betwen speech and input dymanic range for VAD detection.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.RATIO_FIELD                  4;
// @DOC_FIELD_TEXT Minimum amplitude for VAD detection.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.MIN_SIGNAL_FIELD             5;
// @DOC_FIELD_TEXT Minimum power envelope for VAD detection.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.MIN_MAX_ENVELOPE_FIELD       6;
// @DOC_FIELD_TEXT Dynamic threshold between maximum power and power to avoid ramping in stationary noise.
// @DOC_FIELD_FORMAT Q.23
.CONST   $M.vad400.Parameter.DELTA_THRESHOLD_FIELD        7;
// @DOC_FIELD_TEXT Threshold in seconds to have detection of stationary noise.
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.Parameter.COUNT_THRESHOLD_FIELD        8;
// @DOC_FIELD_TEXT Size of parameter structure
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.Parameter.OBJECT_SIZE_FIELD			  9;

// @END  DATA_OBJECT VAD_PRAMS_DATAOBJECT

// field definitions for vad400 data object

// // @DATA_OBJECT VAD_DATAOBJECT

// @DOC_FIELD_TEXT Pointer to frame fuffer for Processing Modules ($frmbuffer in cbuffer.h)
// @DOC_FIELD_FORMAT Pointer
.CONST   $M.vad400.INPUT_PTR_FIELD              0;
// @DOC_FIELD_TEXT Pointer to parameters structure   @DOC_LINK         @DATA_OBJECT  VAD_PRAMS_DATAOBJECT
// @DOC_FIELD_FORMAT Pointer
.CONST   $M.vad400.PARAM_PTR_FIELD              1;
// @DOC_FIELD_TEXT Estimate of the amplitude of the signal
// @DOC_FIELD_FORMAT Q.12
.CONST   $M.vad400.E_FILTER_FIELD               2;
// @DOC_FIELD_TEXT Maximum of estimate of the amplitude of the signal
// @DOC_FIELD_FORMAT Q.12
.CONST   $M.vad400.E_FILTER_MAX_FIELD           3;
// @DOC_FIELD_TEXT Minimum of estimate of the amplitude of the signal
// @DOC_FIELD_FORMAT Q.12
.CONST   $M.vad400.E_FILTER_MIN_FIELD           4;
// @DOC_FIELD_TEXT Internal counter
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.COUNTER_DELTA_FIELD          5;
// @DOC_FIELD_TEXT Counter used by "initialization time".
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.COUNTER_FIELD                6;
// @DOC_FIELD_TEXT Flag identifying that voice has been detected
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.FLAG_FIELD                   7;
// @DOC_FIELD_TEXT Size of the VAD object
// @DOC_FIELD_FORMAT Integer
.CONST   $M.vad400.OBJECT_SIZE_FIELD            8;

// @END  DATA_OBJECT VAD_DATAOBJECT


#endif   //_VAD400_LIB_H
