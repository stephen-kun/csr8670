// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef FRAME_SYNC_DAC_SYNC_OP_HEADER_INCLUDED
#define FRAME_SYNC_DAC_SYNC_OP_HEADER_INCLUDED

.CONST $frame_sync.dac_wrap_op.INPUT_INDEX_FIELD       0;
.CONST $frame_sync.dac_wrap_op.LEFT_PORT_FIELD         1;
.CONST $frame_sync.dac_wrap_op.RIGHT_PORT_FIELD        2;
.CONST $frame_sync.dac_wrap_op.RATE_SCALE_FIELD        3;
.CONST $frame_sync.dac_wrap_op.BUFFER_ADJUST_FIELD     4;
.CONST $frame_sync.dac_wrap_op.MAX_ADVANCE_FIELD       5; 
.CONST $frame_sync.dac_wrap_op.PTR_ADC_STATUS_FIELD    6;
.CONST $frame_sync.dac_wrap_op.PACKET_SIZE_PTR_FIELD   7;
.CONST $frame_sync.dac_wrap_op.COPY_LIMIT_PTR_FIELD    8;

// Internal working data.  Initialize to zero
.CONST $frame_sync.dac_wrap_op.DROP_INSERT_FIELD       9;
.CONST $frame_sync.dac_wrap_op.XFER_AMOUNT_FIELD       10;
.CONST $frame_sync.dac_wrap_op.CBUFFER_PTR_FIELD       11;
.CONST $frame_sync.dac_wrap_op.WRAP_COUNT_FIELD        12;
.CONST $frame_sync.dac_wrap_op.STRUC_SIZE              13;

.CONST $frame_sync.dac_sync_op.STRUC_PTR_FIELD         0;
.CONST $frame_sync.dac_sync_op.STRUC_SIZE              1;

#endif // FRAME_SYNC_DAC_SYNC_OP_HEADER_INCLUDED
