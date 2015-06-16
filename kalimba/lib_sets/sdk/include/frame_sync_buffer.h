// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef FRAMESYNC_BUFFER_H
#define FRAMESYNC_BUFFER_H
   
// Stream Table Entry Description

// SP.  Matches $frmbuffer data struct
.CONST	 $framesync_ind.CBUFFER_PTR_FIELD	      0;
.CONST	 $framesync_ind.FRAME_PTR_FIELD		      1;
.CONST	 $framesync_ind.CUR_FRAME_SIZE_FIELD      2;
// Extended Data Structure
.CONST	 $framesync_ind.FRAME_SIZE_FIELD          3;
.CONST   $framesync_ind.JITTER_FIELD              4;
.CONST   $framesync_ind.DISTRIBUTE_FUNCPTR_FIELD  5;
.CONST   $framesync_ind.UPDATE_FUNCPTR_FIELD      6;
.CONST   $framesync_ind.COUNTER_FIELD             7;      // MIN/MAX COUNTER (~ 1 second)
.CONST   $framesync_ind.AMOUNT_DATA_FIELD         8;      
.CONST   $framesync_ind.THRESHOLD_FIELD           9;
.CONST   $framesync_ind.MIN_FIELD                  10;
.CONST   $framesync_ind.MAX_FIELD                  11;
.CONST   $framesync_ind.DROP_INSERT_FIELD          12;

// Fields for Sync stream functions
.CONST   $framesync_ind.SYNC_POINTER_FIELD         7;
.CONST   $framesync_ind.SYNC_MULTIPLIER_FIELD      8;
.CONST   $framesync_ind.SYNC_AMOUNT_DATA_FIELD     9;


// Size of stream object
.CONST   $framesync_ind.ENTRY_SIZE_FIELD           13;


#endif
