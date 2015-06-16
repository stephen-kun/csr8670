//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio plc 2008             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
//------------------------------------------------------------------------------
// NAME:
//    Delay Operator
//
// DESCRIPTION:
//    Operator to delay an audio stream by a specified length in samples.
//
// MODULES:
//    - $tws.delay.initialize
//    - $tws.delay.process
//------------------------------------------------------------------------------

#ifndef CBOPS_DELAY_INCLUDED
#define CBOPS_DELAY_INCLUDED

#include "cbops_delay.h"
#include "cbops.h"


.MODULE $M.cbops.delay;

    .CODESEGMENT PM;
    .DATASEGMENT DM;

    // ** function vector **
    .VAR $cbops.delay[$cbops.function_vector.STRUC_SIZE] =
        $cbops.function_vector.NO_FUNCTION,        // reset function
        $cbops.function_vector.NO_FUNCTION,        // amount to use function
        &$cbops.delay.main;                        // main function

.ENDMODULE;



//------------------------------------------------------------------------------
// MODULE:
//    $cbops.delay.initialize
//
// DESCRIPTION:
//    Clear the delay buffer
//
// HISTORY:
//
// INPUTS:
//    - r8 = pointer to delay data object, with the following fields being set
//       - $cbops.delay.DBUFF_ADDR_FIELD
//       - $cbops.delay.DBUFF_SIZE_FIELD
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r10, I0, L0, LOOP
//
// NOTES:
//------------------------------------------------------------------------------

.MODULE $M.cbops.delay.initialize;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$cbops.delay.initialize:
   
   // Clear delay buffer   
   r10 = M[r8 + $cbops.delay.DBUFF_SIZE_FIELD];
   r0  = M[r8 + $cbops.delay.DBUFF_ADDR_FIELD];
   L0 = r10;
   I0 = r0;
   r0 = 0;
   do loop_delay_init;
      M[I0,1] = r0;
loop_delay_init:
   L0 = 0;
   rts;

.ENDMODULE;



//------------------------------------------------------------------------------
// MODULE:
//    $cbops.delay.main
//
// DESCRIPTION:
//    Delaying input audio stream into output audio stream via delay buffer
//
// HISTORY:
//
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to delay data object, with evey field being set
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r10, I0-I2, I4-I5, L0-L1, L4-L5, M1-M2, LOOP
//
// NOTES:
//    - Delay buffer must be circular. Due to a known Kalimba chip bug, the
//      size of the buffer (DBUFF_SIZE_FIELD) must be at least 2.
//
//    - A '0' set in the 'DELAY_FIELD' means 'no delay'.
//
//    - Maximum legal delay is the size of the delay buffer (DBUFF_SIZE_FIELD).
//------------------------------------------------------------------------------

.MODULE $M.cbops.delay.main;

   .CODESEGMENT PM;
   .DATASEGMENT DM;

$cbops.delay.main:
        
   // Set up Input Pointer
   r0 = M[r8+$cbops.delay.INPUT_INDEX];
   r1 = M[r6+r0];
   I4 = r1;
   r1 = M[r7+r0];
   L4 = r1;
   
   // Set up Output Pointer
   r0 = M[r8+$cbops.delay.OUTPUT_INDEX];
   r1 = M[r6+r0];
   I5 = r1;
   r1 = M[r7+r0];
   L5 = r1;

   // Get write pointer to delay buffer (DBUFF_ADDR_FIELD / DBUFF_SIZE_FIELD)
   r0 = M[r8+$cbops.delay.DBUFF_ADDR_FIELD];
   I1 = r0;
   r0 = M[r8+$cbops.delay.DBUFF_SIZE_FIELD];
   L1 = r0;
   
   // Get read pointer of delayed stream, point to input stream if no delay
   // Depending on DELAY_FIELD
   I0 = I1;
   L0 = L1;
   r1 = M[r8+$cbops.delay.DELAY_FIELD];
   r0 = r1;
   M2 = NULL - r0;
   if Z L0 = L4;
   r1 = M[I0,M2];
   NULL = M2;
   if Z I0 = I4;
   
   // Delaying input stream into output stream via delay buffer
   do loop_delay;
      r0 = M[I4,1], r1 = M[I0,1];
      M[I1,1] = r0, M[I5,1] = r1;
loop_delay:

   // Update delay address field pointer for next frame, and clear L-registers
   r1 = I1;
   M[r8 + $cbops.delay.DBUFF_ADDR_FIELD] = r1;
   L0 = 0;
   L1 = 0;
   L4 = 0;
   L5 = 0;

   rts;

.ENDMODULE;

#endif // CBOPS_DELAY_INCLUDED