// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2009-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CMPD100_LIB_H
#define CMPD100_LIB_H


.CONST  $CMPD100_VERSION                         0x010004;

// cmpd100 data object definitions
.CONST  $cmpd100.OFFSET_CONTROL_WORD            0;
.CONST  $cmpd100.OFFSET_ENABLE_BIT_MASK         1;
.CONST  $cmpd100.OFFSET_INPUT_CH1_PTR           2;
.CONST  $cmpd100.OFFSET_INPUT_CH2_PTR           3;
.CONST  $cmpd100.OFFSET_OUTPUT_CH1_PTR          4;
.CONST  $cmpd100.OFFSET_OUTPUT_CH2_PTR          5;
.CONST  $cmpd100.OFFSET_MAKEUP_GAIN             6;
.CONST  $cmpd100.OFFSET_GAIN_PTR                7;
.CONST  $cmpd100.OFFSET_NEG_ONE                 8;
.CONST  $cmpd100.OFFSET_POW2_NEG4               9;
.CONST  $cmpd100.OFFSET_EXPAND_THRESHOLD        10;
.CONST  $cmpd100.OFFSET_LINEAR_THRESHOLD        11;
.CONST  $cmpd100.OFFSET_COMPRESS_THRESHOLD      12;
.CONST  $cmpd100.OFFSET_LIMIT_THRESHOLD         13;
.CONST  $cmpd100.OFFSET_INV_EXPAND_RATIO        14;
.CONST  $cmpd100.OFFSET_INV_LINEAR_RATIO        15;
.CONST  $cmpd100.OFFSET_INV_COMPRESS_RATIO      16;
.CONST  $cmpd100.OFFSET_INV_LIMIT_RATIO         17;
.CONST  $cmpd100.OFFSET_EXPAND_CONSTANT         18;
.CONST  $cmpd100.OFFSET_LINEAR_CONSTANT         19;
.CONST  $cmpd100.OFFSET_COMPRESS_CONSTANT       20;
.CONST  $cmpd100.OFFSET_EXPAND_ATTACK_TC        21;
.CONST  $cmpd100.OFFSET_EXPAND_DECAY_TC         22;
.CONST  $cmpd100.OFFSET_LINEAR_ATTACK_TC        23;
.CONST  $cmpd100.OFFSET_LINEAR_DECAY_TC         24;
.CONST  $cmpd100.OFFSET_COMPRESS_ATTACK_TC      25;
.CONST  $cmpd100.OFFSET_COMPRESS_DECAY_TC       26;
.CONST  $cmpd100.OFFSET_LIMIT_ATTACK_TC         27;
.CONST  $cmpd100.OFFSET_LIMIT_DECAY_TC          28;
.CONST  $cmpd100.OFFSET_HEADROOM_COMPENSATION   29;
.CONST  $cmpd100.STRUC_SIZE                     30;

#define $cmpd100.HEADROOM_OFFSET(nBits)         (log(2.0**nBits)/128.0/log(2))

#endif
