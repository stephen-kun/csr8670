// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2012        http://www.csr.com
// Part of ADK 2.0
//
// $Change: 762921 $  $DateTime: 2011/04/07 16:29:18 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Hardware ADC/DAC Warp operator
//
// DESCRIPTION:
//    It is desireable to adjust the ADC/DAC rate to match the processing rate.
//    This operator monitors the ADC or DAC and tracks the samples over time,
//    where the time is derived from the period of the timer task calling this 
//    operator
//
//    In system where the SCO is driving the timing, the SCO logic adjusts the
//    period of the timer task to maintain synchronization with the SCO transmissions.
//
// *****************************************************************************

#include "frame_sync_hw_warp_operator.h"
#include "stack.h"
#include "cbops_vector_table.h"


.MODULE $M.frame_sync.hw_warp_op;
   .CODESEGMENT FRAME_SYNC_HW_WARP_PM;
   .DATASEGMENT DM;
   
    // ** function vector **
   .VAR $frame_sync.hw_warp_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,      // reset function
      &$frame_sync.hw_warp_op.amount_to_use,   // amount to use function
      &$frame_sync.hw_warp_op.main;            // main function
          
// *****************************************************************************
// MODULE:
//   $frame_sync.hw_warp_op.amount_to_use
//
// DESCRIPTION:
//   ADC/DAC rate matching amount to use functions
//
// INPUTS:
//    - r5 = the minimum of the number of input samples available and the
//      amount of output space available
//    - r6 = the number of input samples available
//    - r7 = the amount of output space available
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    none (r5-r8) preserved
//
// TRASHED REGISTERS:
//    r0,r1,r2,r4
//
// *****************************************************************************
$frame_sync.hw_warp_op.amount_to_use:
    // Wait for Port to connect
    r0 = M[r8 + $frame_sync.hw_warp_op.PORT_OFFSET];
    r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
    Null = M[$cbuffer.port_offset_addr + r0];
    if Z jump jp_restart;      

    // Increment Period Counter.  Wait for Settle Time to complete
    r0 = M[r8 + $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET];
    r0 = r0 + 1;
    M[r8 + $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET]=r0;
    if NEG rts;
    // Wait for completion of sample collection 
    r1 = M[r8+$frame_sync.hw_warp_op.PERIODS_PER_SECOND_OFFSET];
    r2 = M[r8+$frame_sync.hw_warp_op.COLLECT_SECONDS_OFFSET];    
    r1 = r1 * r2 (int);
    NULL = r0 - r1;
    if NEG rts;
    // Complete rate mismatch
    r0 = M[r8 + $frame_sync.hw_warp_op.TARGET_RATE_OFFSET];
    r0 = r0 * r2 (int);    
    // Load number of samples provided by source
    rMAC = M[r8 + $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET];
    r1 = SIGNDET rMAC;
    r2 = r1 - 2;
    rMAC = rMAC ASHIFT r2; 
    // Warp = actual_number_of_samples / expected_number_of_samples
    // Frac divide + 1 more shift to make sure it's bigger than numerator
    r0 = r0 ASHIFT r1; 
    Div = rMAC / r0;
    // Division result is Q.22
    r0 = DivResult;
    // Check that data stream is reasonable
    NULL = r0 - 0.499;       // 0.25
    if NEG jump jp_restart;

    // Hardware needs percentage to increase or decrease warp by.
    r0 = r0 - 0.5;       // subtract one in q.22 domain
    r4 = r0 ASHIFT 1;    // q.23  
    
    r3 = r4;    // debug
    
    // calculate moving step (logarithmic then linear)
    r0 = r4;
    if NEG r0 = -r0;
    r1 = 64;    
    r2 = r0 * 0.064 (frac);
    Null = r0 - 0.0015;
    if NEG r2 = r1;
    r1 = r2 - 1280;
    if POS r2 = r2 - r1;
    
    // Limit warp step size
    r0 = r4 - r2;
    if POS r4 = r4 - r0;
    r0 = r4 + r2;
    if NEG r4 = r4 - r0;
    
    // Update Warp
    r2 = M[r8 + $frame_sync.hw_warp_op.LAST_WARP_OFFSET];
    r4 = r2 - r4;
    r4 = r4 * 0.015625 (frac);
    r1 = r4 ASHIFT 6;
           
    // Send Warp Messages if warp has changed
    NULL = r1-r2;
    if Z jump jp_rate_ok;
    
    M[r8 + $frame_sync.hw_warp_op.LAST_WARP_OFFSET]=r1;
      
    // SP.  r7,r8 are not affected by $message.send_short
    pushm <r5,r6,rLink>;   
    // Check if data from ADC or DAC and get ADC ports
    r9 = r4;
    r2 = &$MESSAGE_WARP_ADC;
    r3 = M[r8 + $frame_sync.hw_warp_op.WHICH_PORTS_OFFSET];
    r3 = r3 AND 0x3;
    if NZ call $message.send_short;    
    // Check if data from ADC or DAC and get DAC ports
    r2 = &$MESSAGE_WARP_DAC;
    r4 = r9; 
    r3 = M[r8 + $frame_sync.hw_warp_op.WHICH_PORTS_OFFSET];
    r3 = r3 LSHIFT -4;
    r3 = r3 AND 0x3;
    if NZ call $message.send_short;
    popm <r5,r6,rLink>;
jump jp_rate_ok;

jp_restart:
    // Reset Timer and data collection
    r0 = M[r8 + $frame_sync.hw_warp_op.PERIODS_PER_SECOND_OFFSET];
    r0 = r0 * -0.1 (frac);
    M[r8 + $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET]=r0;
    M[r8 + $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET]=NULL;
    rts;
jp_rate_ok:
    // Keep Tracking Rate without settle time
    r2 = M[r8 + $frame_sync.hw_warp_op.COLLECT_SECONDS_OFFSET];
    r0 = M[r8 + $frame_sync.hw_warp_op.TARGET_RATE_OFFSET];
    r0 = r0 * r2 (int); 
    r1 = M[r8 + $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET];
    r1 = r1 - r0;
    
    NULL = M[r8+$frame_sync.hw_warp_op.ENABLE_DITHER_OFFSET];
    if Z r1=NULL;
    M[r8 + $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET]=r1;
    
    M[r8 + $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET]=NULL;
    rts;

// *****************************************************************************
// MODULE:
//    $frame_sync.hw_warp_op.main
//
// DESCRIPTION:
//    Accumulate data transfered to/from port
//
// INPUTS:
//    - r5 = pointer to the list of input and output buffer start addresses
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0
//
// *****************************************************************************
$frame_sync.hw_warp_op.main:
    NULL = M[r8 + $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET];
    if NEG rts;
    r0 = M[r8 + $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET];
    r0 = r0 + r10;
    M[r8 + $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET]=r0;
    rts;
.ENDMODULE;
