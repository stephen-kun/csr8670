// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2012        http://www.csr.com
// Part of ADK 2.0
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef FRAME_SYNC_HW_WARP_OP_HEADER_INCLUDED
#define FRAME_SYNC_HW_WARP_OP_HEADER_INCLUDED
//  which     1 for A, 2 for B, 3 for A&B   0: none
//  bits 3:0 = ADC which ports
//  bits 7:4 = DAC which ports
.CONST $frame_sync.hw_warp_op.PORT_OFFSET                0;
.CONST $frame_sync.hw_warp_op.WHICH_PORTS_OFFSET         1;
.CONST $frame_sync.hw_warp_op.TARGET_RATE_OFFSET         2;
.CONST $frame_sync.hw_warp_op.PERIODS_PER_SECOND_OFFSET  3;
.CONST $frame_sync.hw_warp_op.COLLECT_SECONDS_OFFSET     4;
.CONST $frame_sync.hw_warp_op.ENABLE_DITHER_OFFSET       5;

.CONST $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET         6;
.CONST $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET      7;
.CONST $frame_sync.hw_warp_op.LAST_WARP_OFFSET           8;

.CONST $frame_sync.hw_warp_op.STRUC_SIZE                 9;

#endif // FRAME_SYNC_HW_WARP_OP_HEADER_INCLUDED

