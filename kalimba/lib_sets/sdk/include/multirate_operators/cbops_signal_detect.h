//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio Ltd 2010             http://www.csr.com
// %%version
//
// $Revision: #1 $  $Date: 2014/04/23 $
//------------------------------------------------------------------------------



#ifndef CBOPS_SIGNAL_DETECT_HEADER_INCLUDED
#define CBOPS_SIGNAL_DETECT_HEADER_INCLUDED

    #define SIGNAL_DETECT_TIMER_PERIOD 1000000   // timer should run every second

    // Operator structure definition
    .const   $cbops.signal_detect_op.LINEAR_THRESHOLD_VALUE       0;
    .const   $cbops.signal_detect_op.NO_SIGNAL_TRIGGER_TIME       1;
    .const   $cbops.signal_detect_op.CURRENT_MAX_VALUE            2;
    .const   $cbops.signal_detect_op.SECOND_TIMER                 3;
    .const   $cbops.signal_detect_op.SIGNAL_STATUS                4;
    .const   $cbops.signal_detect_op.SIGNAL_STATUS_MSG_ID         5;
    .const   $cbops.signal_detect_op.NUM_CHANNELS                 6;
    .const   $cbops.signal_detect_op.FIRST_CHANNEL_INDEX          7;       
    .const   $cbops.signal_detect_op.STRUC_SIZE_MONO              8;
    .const   $cbops.signal_detect_op.STRUC_SIZE_STEREO            9;
    .const   $cbops.signal_detect_op.STRUC_SIZE_3_CHANNEL        10;
    
#endif // CBOPS_SIGNAL_DETECT_HEADER_INCLUDED
