//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio Ltd 2010             http://www.csr.com
// Part of ADK 3.5
//
// $Revision: #2 $  $Date: 2014/05/27 $
//------------------------------------------------------------------------------



#ifndef CBOPS_SIGNAL_DETECT_HEADER_INCLUDED
#define CBOPS_SIGNAL_DETECT_HEADER_INCLUDED

    #define SIGNAL_DETECT_TIMER_PERIOD 1000000   // timer should run every second

    // Operator structure definition
   
    .const   $cbops.signal_detect_op.COEFS_PTR                    0;
    .const   $cbops.signal_detect_op.NUM_CHANNELS                 1;
    .const   $cbops.signal_detect_op.FIRST_CHANNEL_INDEX          2;
    
    .const   $cbops.signal_detect_op.STRUC_SIZE_MONO              3;
    .const   $cbops.signal_detect_op.STRUC_SIZE_STEREO            4;
    .const   $cbops.signal_detect_op.STRUC_SIZE_3_CHANNEL         5;
    

    // coefficients/data memory structure definition
    
    .const   $cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE  0;
    .const   $cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME  1;
    .const   $cbops.signal_detect_op_coef.CURRENT_MAX_VALUE       2;
    .const   $cbops.signal_detect_op_coef.SECOND_TIMER            3;
    .const   $cbops.signal_detect_op_coef.SIGNAL_STATUS           4;
    .const   $cbops.signal_detect_op_coef.SIGNAL_STATUS_MSG_ID    5;
    
    .const   $cbops.signal_detect_op_coef.STRUC_SIZE              6;
    
#endif // CBOPS_SIGNAL_DETECT_HEADER_INCLUDED
