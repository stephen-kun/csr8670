//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio Ltd 2010             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$  $Date$
//------------------------------------------------------------------------------
// NAME:
//   stereo soft mute operator
//
// DESCRIPTION:
//   perform quick/clickless mute of audio by using sin^2 gain curve
//   Processing can work inplace (output buffer can be same as input buffer)
//
// When using the operator the following data structure is used:
//   - $cbops.stereo_soft_mute_op.INPUT_LEFT_START_INDEX_FIELD = the index of the left
//       channel inputs in the operator copy framework parameter area
//   - $cbops.stereo_soft_mute_op.INPUT_RIGHT_START_INDEX_FIELD = the index of the right
//       channel inputs in the operator copy framework parameter area
//   - $cbops.stereo_soft_mute_op.OUTPUT_LEFT_START_INDEX_FIELD = the index of the left
//       channel outputs in the operator copy framework parameter area
//   - $cbops.stereo_soft_mute_op.OUTPUT_RIGHT_START_INDEX_FIELD = the index of the right
//       channel outputs in the operator copy framework parameter area
//   - $cbops.stereo_soft_mute_op.MUTE_DIRECTION = (int) 1 -> unmute audio
//                                                 (int) -1 -> mute audio
//   - $cbops.stereo_soft_mute_op.MUTE_INDEX = used internally
//------------------------------------------------------------------------------


#include "cbops_library.h"
#include "stack.h"

#include "cbops_stereo_soft_mute.h"


.module $M.cbops.stereo_soft_mute.mute_coefs;

    .datasegment dm;
    
    // mute ramp.
    //   sin^2 over 32 samples gives smooth but rapid transition to and from mute
    //   ramp is negated so will end with gain of -1.0.  Ramp will be either
    //   infinite mute. or lossless passthru when not in transition.
    
    .var $mute_coefs[] = 
        0x000000, 0xFFABF1, 0xFEB09F, 0xFD109F, 0xFAD035, 0xF7F54C, 0xF48764, 0xF08F7F, 
        0xEC1809, 0xE72CBF, 0xE1DA8C, 0xDC2F6B, 0xD63A40, 0xD00AB1, 0xC9B0FF, 0xC33DD7, 
        0xBCC22A, 0xB64F02, 0xAFF550, 0xA9C5C1, 0xA3D096, 0x9E2575, 0x98D342, 0x93E7F8, 
        0x8F7082, 0x8B789D, 0x880AB5, 0x852FCC, 0x82EF62, 0x814F62, 0x805410, 0x800000 ;

.endmodule;


.module $M.cbops.stereo_soft_mute ;

    .datasegment dm ;
    .codesegment pm ;

    // function vector table
    .var $cbops.stereo_soft_mute[$cbops.function_vector.STRUC_SIZE] =
        $cbops.function_vector.NO_FUNCTION,         // reset function (unused)
        $cbops.function_vector.NO_FUNCTION,         // amount to use function (unused)
        &$cbops.stereo_soft_mute.main;              // main function

//------------------------------------------------------------------------------
$cbops.stereo_soft_mute.main:
//------------------------------------------------------------------------------
// applies a soft mute to stereo audio
//   mute curve is defined by an array ($mute_coefs) which is multiplied with
//   the audio.  The mute curve is negated.  When the curve is multiplied with
//   the mute curve, it is inverted again.  This results in a gain of exactly 1
//   so the audio is normally passed losslessly.
//------------------------------------------------------------------------------
// on entry
//   - r6 = pointer to the list of input and output buffer pointers
//   - r7 = pointer to the list of buffer lengths
//   - r8 = pointer to operator structure
//   - r10 = the number of samples to process
//------------------------------------------------------------------------------

    // push rLink onto stack
    $push_rLink_macro;

    // get the offsets to the read buffers
    r0 = M[r8 + $cbops.stereo_soft_mute_op.INPUT_LEFT_START_INDEX_FIELD];    // left input index
    r1 = M[r6 + r0];    // get the buffer read address
    I0 = r1;            // store the value in I0
    r1 = M[r7 + r0];    // get the buffer length
    L0 = r1;            // store the value in L0
    r0 = M[r8 + $cbops.stereo_soft_mute_op.INPUT_RIGHT_START_INDEX_FIELD];   // right input index
    r1 = M[r6 + r0];
    I4 = r1;
    r1 = M[r7 + r0];
    L4 = r1;

    // get the offsets to the write buffers
    r0 = M[r8 + $cbops.stereo_soft_mute_op.OUTPUT_LEFT_START_INDEX_FIELD];   // left output index
    r1 = M[r6 + r0];
    I1 = r1;
    r1 = M[r7 + r0];
    L1 = r1;
    r0 = M[r8 + $cbops.stereo_soft_mute_op.OUTPUT_RIGHT_START_INDEX_FIELD];  // right output index
    r1 = M[r6 + r0];
    I5 = r1;
    r1 = M[r7 + r0];
    L5 = r1;
    
    M1 = 1;
    
    r0 = M[r8 + $cbops.stereo_soft_mute_op.MUTE_INDEX];
    r1 = M[r8 + $cbops.stereo_soft_mute_op.MUTE_DIRECTION];
    do loop;
        // work out gain value from ramp table
        r0 = r0 + r1,       r2 = M[I0,M1];       // get left audio
        if neg r0 = 0;
        r4 = length($mute_coefs)-1;
        null = r4 - r0;
        if neg r0 = r4;
        r4 = $mute_coefs;
        r4 = r0 + r4,       r3 = M[I4,M1];      // get right audio
        r4 = M[r4];                             // get gain
        
        // apply gain to audio
        r2 = r2 * r4 (frac);                    // apply gain to left
        r3 = r3 * r4 (frac);                    // apply gain to right
        r2 = -r2;                               // invert left
        r3 = -r3,           M[I1,M1] = r2;      // store left and invert right
        M[I5,M1] = r3;                          // store right
    loop:
    M[r8 + $cbops.stereo_soft_mute_op.MUTE_INDEX] = r0;

    // zero length registers
    L0 = 0;
    L1 = 0;
    L4 = 0;
    L5 = 0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;

.endmodule;


//------------------------------------------------------------------------------
.module $M.cbops.stereo_soft_mute.message_handler ;
//------------------------------------------------------------------------------
// Receives paramter for soft mute
//------------------------------------------------------------------------------
// on entry r1 = mute control (0=unmute, 1=mute)
//          r8 = pointer to operator structure
// *** NO CHECKING IS PERFORMED ON MESSAGE PARAMETERS ***
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;
    
    // change input parameter (0=unmute, 1=mute) into coefficient (+1=unmute, -1=mute)
    r0 = 1;
    r1 = -r1;
    null = r1;
    if Z r1 = r0;

    m[r8+$cbops.stereo_soft_mute_op.MUTE_DIRECTION] = r1;
    
    jump $pop_rLink_and_rts ;

.endmodule ;
