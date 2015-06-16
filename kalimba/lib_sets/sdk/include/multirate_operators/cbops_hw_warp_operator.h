// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2012        http://www.csr.com
// Part of ADK 2.0
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CBOPS_HW_WARP_OP_HEADER_INCLUDED
#define CBOPS_HW_WARP_OP_HEADER_INCLUDED
//  which     1 for A, 2 for B, 3 for A&B   0: none
//  bits 3:0 = ADC which ports
//  bits 7:4 = DAC which ports
.CONST $cbops.hw_warp_op.PORT_OFFSET                0;
.CONST $cbops.hw_warp_op.MONITOR_INDEX_OFFSET       1;
.CONST $cbops.hw_warp_op.WHICH_PORTS_OFFSET         2;
.CONST $cbops.hw_warp_op.TARGET_RATE_OFFSET         3;
.CONST $cbops.hw_warp_op.PERIODS_PER_SECOND_OFFSET  4;
.CONST $cbops.hw_warp_op.COLLECT_SECONDS_OFFSET     5;
.CONST $cbops.hw_warp_op.ENABLE_DITHER_OFFSET       6;

.CONST $cbops.hw_warp_op.ACCUMULATOR_OFFSET         7;
.CONST $cbops.hw_warp_op.PERIOD_COUNTER_OFFSET      8;
.CONST $cbops.hw_warp_op.LAST_WARP_OFFSET           9;

.CONST $cbops.hw_warp_op.STRUC_SIZE                 10;

#endif // CBOPS_HW_WARP_OP_HEADER_INCLUDED

