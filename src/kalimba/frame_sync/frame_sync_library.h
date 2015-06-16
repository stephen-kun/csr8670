// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef FRAMESYNCLIB_H_INCLUDED
#define FRAMESYNCLIB_H_INCLUDED


.CONST   $FRAMESYNCLIB_VERSION 0x000002;

#include "frame_sync_stream_macros.h"
#include "frame_sync_sidetone_mix_operator.h"
#include "frame_sync_dac_sync_operator.h"
#include "frame_sync_sco_copy_operator.h"
#include "frame_sync_buffer.h"
#include "frame_sync_tsksched.h"
#include "frame_sync_hw_warp_operator.h"

// frame process object definition
.CONST   $frame_sync.frame_process.AMT_RDY_BUFFER_PTR_FIELD         0;
.CONST   $frame_sync.frame_process.MIN_AMOUNT_READY_FIELD           1;
.CONST   $frame_sync.frame_process.NUM_OUTPUT_RATE_OBJECTS_FIELD    2;
.CONST   $frame_sync.frame_process.NUM_RATE_OBJECTS_FIELD           3;
.CONST   $frame_sync.frame_process.STRUC_SIZE                       4;

// Position of first cbuffer structure relative to the frame process structure above
.CONST   $frame_sync.frame_process.FIRST_CBUFFER_STRUC_FIELD        4;

#endif
