/******************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************/

#ifndef FRAME_SYNC_SIDETONE_FILTER_OP_HEADER_INCLUDED
#define FRAME_SYNC_SIDETONE_FILTER_OP_HEADER_INCLUDED
#include "peq.h"
  
 
/**************************** Parameters ***************************************/   
/* Parameter, -6dB Clip point for sidetone in Q1.23 */
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_ST_CLIP_POINT          0;
/* Limits the DAC dependent gain applied to the ST (for constant level) */
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_ST_ADJUST_LIMIT        1;
/* sidetone filter switch:
//   0: manual turn off
//   1: manual turn on
//   ~: filter automatic on/off based on noise level    */
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_SWITCH             2;
/* If noise is below this level, automatic switch turns off filter  */
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_NOISE_LOW_THRES    3;
/* If noise is above this level, automatic switch turns on filter */
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_NOISE_HIGH_THRES   4;
/* Sidetone Gain mantisa/exponent */
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_GAIN_EXP           5;
.CONST   $frame_sync.sidetone_filter_op.Parameter.OFFSET_STF_GAIN_MANTISSA      6;

.CONST   $frame_sync.sidetone_filter_op.Parameter.BLOCKSIZE                     7;    
    


/************************** Data Structure***************************************/
.CONST   $frame_sync.sidetone_filter_op.INPUT_START_INDEX_FIELD                 0;
.CONST   $frame_sync.sidetone_filter_op.OUTPUT_START_INDEX_FIELD                1;  
.CONST   $frame_sync.sidetone_filter_op.ENABLE_MASK_FIELD                       2;
.CONST   $frame_sync.sidetone_filter_op.PARAM_PTR_FIELD                         3;
   
.CONST   $frame_sync.sidetone_filter_op.APPLY_FILTER                            4;  
.CONST   $frame_sync.sidetone_filter_op.APPLY_GAIN_FIELD                        5;  

/* Pointer to the variable of an external noise level estimation */
.CONST   $frame_sync.sidetone_filter_op.NOISE_LEVEL_PTR_FIELD                   6;
/* Bitwise flag for enabling the sidetone */
.CONST   $frame_sync.sidetone_filter_op.OFFSET_ST_CONFIG_FIELD                  7; 
/* Inverse of Current DAC Gain */
.CONST   $frame_sync.sidetone_filter_op.OFFSET_PTR_INV_DAC_GAIN                 8; 
/* output for side tone */
.CONST   $frame_sync.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN            9; 
/* Peak sidetone {q5.19} */
.CONST   $frame_sync.sidetone_filter_op.OFFSET_PEAK_ST                          10;
/* sidetone filter uses PEQ, starts from this field */
.CONST   $frame_sync.sidetone_filter_op.PEQ_START_FIELD                         11;


#define SIDETONE_FILTER_OBJECT_SIZE(x)  ($frame_sync.sidetone_filter_op.PEQ_START_FIELD + PEQ_OBJECT_SIZE(x))


   
#endif // FRAME_SYNC_SIDETONE_FILTER_OP_HEADER_INCLUDED
   
   

   
