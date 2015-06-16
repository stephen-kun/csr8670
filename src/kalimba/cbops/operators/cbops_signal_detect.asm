//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio Ltd 2010             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$  $Date$
//------------------------------------------------------------------------------
// NAME:
//   signal detector operator
//------------------------------------------------------------------------------
// DESCRIPTION:
//   Monitors audio level and sends message when under threshold for prescribed
//   time, or goes over threshold - useful for auto standby feature
//   Processing doesn't change audio.
//------------------------------------------------------------------------------
// When using the operator the following data structure is used:
//   - $signal_detect_op.LINEAR_THRESHOLD_VALUE = level below which audio
//       considered silent
//   - $signal_detect_op.NO_SIGNAL_TRIGGER_TIME = trigger time for sending
//       "no signal" message to VM
//   - $signal_detect_op.CURRENT_MAX_VALUE = current maximum audio level
//   - $signal_detect_op.SECOND_TIMER = second timer counting
//       length of time audio has been quiet
//   - $signal_detect_op.SIGNAL_STATUS = 1 if playing audio,
//                                       0 if no audio
//   - $signal_detect_op.SIGNAL_STATUS_MSG_ID = ID for status message sent to VM
//   - $signal_detect_op.NUM_CHANNELS = number of channels to process
//   - $signal_detect_op.FIRST_CHANNEL_INDEX = the index of the first
//       channel in the operator copy framework parameter area
//------------------------------------------------------------------------------


#include "cbops_library.h"
#include "stack.h"
#include "timer.h"

#include "cbops_signal_detect.h"


.module $M.cbops.signal_detect_op;

    .codesegment pm;
    .datasegment dm;

   // function vector table
   .var $cbops.signal_detect_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,   // reset function (unused)
      $cbops.function_vector.NO_FUNCTION,   // amount to use function (unused)
      &$cbops.signal_detect_op.main;               // main function

.endmodule;



//------------------------------------------------------------------------------
.module $M.cbops.signal_detect_op.main;
//------------------------------------------------------------------------------
// stores maximum signal level for stereo channel pair.
//------------------------------------------------------------------------------
// INPUTS:
//   - r6 = pointer to the list of input and output buffer pointers
//   - r7 = pointer to the list of buffer lengths
//   - r8 = pointer to operator structure
//   - r10 = the number of samples to process
//------------------------------------------------------------------------------
// OUTPUTS:
//   none
//------------------------------------------------------------------------------
// TRASHED REGISTERS:
//   r0, r1, r2, i0, i1, i4
//------------------------------------------------------------------------------

    .codesegment pm;
    .datasegment dm;

    $cbops.signal_detect_op.main:

    // push rLink onto stack
    $push_rLink_macro;

    r9 = r10;               // take copy of number of samples
    
    r5 = m[r8 + $cbops.signal_detect_op.COEFS_PTR];                // get ptr to coefficients
    r3 = m[r8 + $cbops.signal_detect_op.NUM_CHANNELS];
    i4 = r8 + $cbops.signal_detect_op.FIRST_CHANNEL_INDEX;
    l4 = 0;
    
    r2 = m[r5 + $cbops.signal_detect_op_coef.CURRENT_MAX_VALUE];        // get previous maximum value
    
    channelLoop:
    
        r10 = r9;
    
        r0 = m[i4,1];       // channel index
        r1 = m[r6 + r0];    // get the buffer read address
        i0 = r1;            // store the value in I0
        r1 = m[r7 + r0];    // get the buffer length
        l0 = r1;            // store the value in L0
    
        // find max of current audio channel
        do sampleLoop;
            r0 = m[i0,1];
            // maxVal = MAX(maxVal,ABS(audio))
            null = r0;
            if neg r0 = -r0;
            null = r2 - r0;
            if neg r2 = r0;
        sampleLoop:
    
        r3 = r3 - 1;
    if nz jump channelLoop;

    // store new maximum value
    m[r5 + $cbops.signal_detect_op_coef.CURRENT_MAX_VALUE] = r2;
    
    // zero length registers
    l0 = 0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.endmodule;


//------------------------------------------------------------------------------
.module $M.signal_detect_op.timer_handler;
//------------------------------------------------------------------------------
// should be called once a second by main application
// on entry : r8 = pointer to coefficients structure
//------------------------------------------------------------------------------
//   if (MaxLevel < Threshold)
//   {
//       secondTimer++
//       if (secondTimer > noSignalTriggerTime)
//       {
//           if (signalStatus == true)
//           {
//               signalStatus = false
//               sendMessage(signalStatus)
//           }
//       }
//   }
//   else
//   {
//	     // level is over threshold
//       if (signalStatus == false)
//       {
//           signalStatus = true
//           sendMessage(signalStatus)
//       }
//       secondTimer = 0
//   }
//------------------------------------------------------------------------------
// Message sent to VM
//   1 = receiving audio
//   0 = no audio
//------------------------------------------------------------------------------

    .codesegment pm;
    .datasegment dm;
    
    $cbops.signal_detect_op.timer_handler:
    
    // push rLink onto stack
    $push_rLink_macro;
    
    r1 = m[r8+$cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE];
    if z jump detectionDisabled;
    r0 = m[r8+$cbops.signal_detect_op_coef.CURRENT_MAX_VALUE];
    null = r0 - r1;
    if pos jump levelOverThreshold;
    
        // level under threshold
        r2 = m[r8+$cbops.signal_detect_op_coef.SECOND_TIMER];
        r2 = r2 + 1;
        m[r8+$cbops.signal_detect_op_coef.SECOND_TIMER] = r2;
        
        r1 = m[r8+$cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME];
        null = r2 - r1;
        if neg jump exit;
            // timer greater than "no signal" trigger time
            // check whether already in no signal state
            null = m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS];
            if z jump resetTimer;
                r3 = 0;
                m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS]=r3;
                // send signal status (r3) to VM    
                r2 = m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS_MSG_ID];
                call $message.send_short ;
                jump exit;

    levelOverThreshold:
    
        null = m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS];
        if nz jump resetTimer;
            // in "no signal" state, but have audio, so send signal status message
            r3 = 1;
            m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS]=r3;
            // send signal status (r3) to VM    
            r2 = m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS_MSG_ID];
            call $message.send_short ;
            
    resetTimer:
    
    r2 = 0;
    m[r8+$cbops.signal_detect_op_coef.SECOND_TIMER] = r2;

    exit:
    
    // clear current maximum audio level
    r0 = 0;
    m[r8+$cbops.signal_detect_op_coef.CURRENT_MAX_VALUE] = r0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;
    

    detectionDisabled:
    
    // clear current leve and timer.  Set status to passing audio

    r0 = 0;
    m[r8+$cbops.signal_detect_op_coef.SECOND_TIMER] = r0;
    m[r8+$cbops.signal_detect_op_coef.CURRENT_MAX_VALUE] = r0;
    r0 = 1;
    m[r8+$cbops.signal_detect_op_coef.SIGNAL_STATUS]=r0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.endmodule;


//------------------------------------------------------------------------------
.module $M.cbops.signal_detect_op.message_handler ;
//------------------------------------------------------------------------------
// Receives paramters for signal detection
//------------------------------------------------------------------------------
// on entry r1 = threshold
//          r2 = trigger time in seconds (16 bit int)
//          r8 = pointer to coefficients structure
// *** NO CHECKING IS PERFORMED ON MESSAGE PARAMETERS ***
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

    m[r8+$cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE] = r1;
    m[r8+$cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME] = r2;
    
    jump $pop_rLink_and_rts ;

.endmodule ;

