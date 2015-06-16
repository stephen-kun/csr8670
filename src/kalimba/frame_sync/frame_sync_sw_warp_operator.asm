// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2012        http://www.csr.com
// Part of ADK 2.0
//
// $Change: 762921 $  $DateTime: 2011/04/07 16:29:18 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Software Warp operator
//
// DESCRIPTION:
//    It is desirable to adjust the ADC/DAC rate to match the processing rate.
//    This operator monitors the ADC or DAC and tracks the samples over time,
//    where the time is derived from the period of the timer task calling this
//    operator. The Software Warp operator generates outputs that can be used
//    to drive the $cbops.rate_adjustment_and_shift operator.
//
//    For successful rate matching operation the Software Warp operator
//    (which calculates the adjustment) should be placed in a cbops chain
//    after the cbops_rate_adjustment_and_shift operator. This is because
//    the calculation must be based on the adjusted sampling rate.
//
//    Also, if it is required to use the Software Warp Operator in the same
//    cbops chain as the cbops_rate_adjustment_and_shift operator (after it!)
//    then the cbops_rate_adjustment_and_shift_complete operator must be
//    used to terminate the chain.
//
//    In a system where the SCO is driving the timing, the SCO logic adjusts the
//    period of the timer task to maintain synchronization with the SCO transmissions.
//    This allows a common timing reference at both ends of the BT link.
//
// *****************************************************************************

#include "frame_sync_sw_warp_operator.h"
#include "stack.h"
#include "cbops_vector_table.h"


.MODULE $M.frame_sync.sw_warp_op;
   .CODESEGMENT FRAME_SYNC_SW_WARP_PM;
   .DATASEGMENT DM;

    // ** function vector **
   .VAR $frame_sync.sw_warp_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,      // reset function
      $frame_sync.sw_warp_op.amount_to_use,    // amount to use function
      $frame_sync.sw_warp_op.main;             // main function

// *****************************************************************************
// MODULE:
//   $frame_sync.sw_warp_op.amount_to_use
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
$frame_sync.sw_warp_op.amount_to_use:
    // Wait for Port to connect
    r0 = M[r8 + $frame_sync.sw_warp_op.PORT_OFFSET];
    r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
    Null = M[$cbuffer.port_offset_addr + r0];
    if Z jump jp_restart;

    // Increment Period Counter.  Wait for Settle Time to complete
    r0 = M[r8 + $frame_sync.sw_warp_op.PERIOD_COUNTER_OFFSET];
    r0 = r0 + 1;
    M[r8 + $frame_sync.sw_warp_op.PERIOD_COUNTER_OFFSET]=r0;
    if NEG rts;
    // Wait for completion of sample collection
    r1 = M[r8 + $frame_sync.sw_warp_op.PERIODS_PER_SECOND_OFFSET];
    r2 = M[r8 + $frame_sync.sw_warp_op.COLLECT_SECONDS_OFFSET];
    r1 = r1 * r2 (int);
    NULL = r0 - r1;
    if NEG rts;
    // Complete rate mismatch
    r0 = M[r8 + $frame_sync.sw_warp_op.TARGET_RATE_OFFSET];
    r0 = r0 * r2 (int);
    // Load number of samples provided by source
    rMAC = M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_OFFSET];

    // Save the total accumulated in period (for debug purposes)
    M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_TOTAL_OFFSET] = rMAC;
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

    // Software needs percentage to increase or decrease warp by.
    r0 = r0 - 0.5;       // subtract one in q.22 domain
    r4 = r0 ASHIFT 1;    // q.23

    // Update Warp
    r2 = M[r8 + $frame_sync.sw_warp_op.FWD_WARP_OFFSET];
    r4 = r2 - r4;
    r4 = r4 * 0.015625 (frac);
    r1 = r4 ASHIFT 6;

    // Store values pointed at by the $cbops.rate_adjustment_and_shift operator
    M[r8 + $frame_sync.sw_warp_op.FWD_WARP_OFFSET] = r1;

    r2 = r1 * r1 (frac);
    r2 = r2 - r1;
    M[r8 + $frame_sync.sw_warp_op.REV_WARP_OFFSET] = r2;

jump jp_rate_ok;

jp_restart:
    // Reset Timer and data collection
    r0 = M[r8 + $frame_sync.sw_warp_op.PERIODS_PER_SECOND_OFFSET];
    r0 = r0 * -0.1 (frac);
    M[r8 + $frame_sync.sw_warp_op.PERIOD_COUNTER_OFFSET] = r0;
    M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_OFFSET] = NULL;
    M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_TOTAL_OFFSET] = 0;

    // Zero the WARP values
    M[r8 + $frame_sync.sw_warp_op.FWD_WARP_OFFSET] = 0;
    M[r8 + $frame_sync.sw_warp_op.REV_WARP_OFFSET] = 0;
    rts;

jp_rate_ok:
    // Keep Tracking Rate without settle time
    r2 = M[r8 + $frame_sync.sw_warp_op.COLLECT_SECONDS_OFFSET];
    r0 = M[r8 + $frame_sync.sw_warp_op.TARGET_RATE_OFFSET];
    r0 = r0 * r2 (int);
    r1 = M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_OFFSET];
    r1 = r1 - r0;
    NULL = M[r8 + $frame_sync.sw_warp_op.ENABLE_DITHER_OFFSET];
    if Z r1 = NULL;
    M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_OFFSET] = r1;

    M[r8 + $frame_sync.sw_warp_op.PERIOD_COUNTER_OFFSET] = NULL;
    rts;

// *****************************************************************************
// MODULE:
//    $frame_sync.sw_warp_op.main
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
$frame_sync.sw_warp_op.main:
    NULL = M[r8 + $frame_sync.sw_warp_op.PERIOD_COUNTER_OFFSET];
    if NEG rts;

    r0 = M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_OFFSET];
    r0 = r0 + r10;
    M[r8 + $frame_sync.sw_warp_op.ACCUMULATOR_OFFSET]=r0;
    rts;

.ENDMODULE;
