// *****************************************************************************
// %%fullcopyright(2009)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CMPD100_LIB_H
#define CMPD100_LIB_H

.CONST  $cbops.cmpd_op.Parameter.OFFSET_EXPAND_THRESHOLD        0;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_LINEAR_THRESHOLD        1;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_COMPRESS_THRESHOLD      2;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_LIMIT_THRESHOLD         3;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_INV_EXPAND_RATIO        4;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_INV_LINEAR_RATIO        5;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_INV_COMPRESS_RATIO      6;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_INV_LIMIT_RATIO         7;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_EXPAND_ATTACK_TC        8;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_EXPAND_DECAY_TC         9;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_LINEAR_ATTACK_TC        10;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_LINEAR_DECAY_TC         11;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_COMPRESS_ATTACK_TC      12;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_COMPRESS_DECAY_TC       13;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_LIMIT_ATTACK_TC         14;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_LIMIT_DECAY_TC          15;
.CONST  $cbops.cmpd_op.Parameter.OFFSET_MAKEUP_GAIN             16;
.CONST  $cbops.cmpd_op.Parameter.STRUC_SIZE                     17;

// cmpd_op data object definitions
.CONST  $cbops.cmpd_op.INPUT_1_START_INDEX_FIELD      0;
.CONST  $cbops.cmpd_op.INPUT_2_START_INDEX_FIELD      1;
.CONST  $cbops.cmpd_op.OUTPUT_1_START_INDEX_FIELD     2;
.CONST  $cbops.cmpd_op.OUTPUT_2_START_INDEX_FIELD     3;
.CONST  $cbops.cmpd_op.OFFSET_PARAM_PTR               4;
.CONST  $cbops.cmpd_op.OFFSET_SAMPLES_FOR_PROCESS     5;
.CONST  $cbops.cmpd_op.OFFSET_GAIN_PTR                6;
.CONST  $cbops.cmpd_op.OFFSET_NEG_ONE                 7;
.CONST  $cbops.cmpd_op.OFFSET_POW2_NEG4               8;
// UNINITIALIZED STATE INFO
.CONST  $cbops.cmpd_op.OFFSET_EXPAND_CONSTANT         9;
.CONST  $cbops.cmpd_op.OFFSET_LINEAR_CONSTANT         10;
.CONST  $cbops.cmpd_op.OFFSET_COMPRESS_CONSTANT       11;
.CONST  $cbops.cmpd_op.OFFSET_PEAK					  12;
.CONST  $cbops.cmpd_op.OFFSET_LOG_PEAK			      13;
.CONST  $cbops.cmpd_op.OFFSET_REGION				  14;
.CONST  $cbops.cmpd_op.OFFSET_INST_GAIN				  15;
.CONST  $cbops.cmpd_op.OFFSET_SAMPLE_COUNT			  16;
.CONST  $cbops.cmpd_op.STRUC_SIZE                     17;

#endif

//r9 = M[r8 + $cbops.cmpd_op.OFFSET_PARAM_PTR ];
//r0 = M[r9 + $cbops.cmpd_op.Parameter.OFFSET_EXPAND_THRESHOLD];
	
// OFFSET_PARAM_PTR = 
//&CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_THRESHOLD1
//&CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_THRESHOLD2
