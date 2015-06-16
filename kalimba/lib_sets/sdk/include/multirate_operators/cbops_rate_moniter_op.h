// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#ifndef CBOPS_RATE_MONITOR_OP_HEADER_INCLUDED
#define CBOPS_RATE_MONITOR_OP_HEADER_INCLUDED

// cbops.rate_monitor_op data object definitions
.CONST $cbops.rate_monitor_op.MONITOR_INDEX_FIELD                   0;  // Index (into cbuffer table) of the cbuffer used to monitor the rate
.CONST $cbops.rate_monitor_op.PERIODS_PER_SECOND_FIELD              1;  // Number of calls per second (from timer interrupt handler)
.CONST $cbops.rate_monitor_op.SECONDS_TRACKED_FIELD                 2;  // Compute warp after a measurement period of this many seconds (this is not exact!)
.CONST $cbops.rate_monitor_op.TARGET_RATE_FIELD                     3;  // Target sampling rate in Hz
.CONST $cbops.rate_monitor_op.ALPHA_LIMIT_FIELD                     4;  // Controls how much history is used in calculation
.CONST $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD                5;  // Q.22, initialize to one (i.e. 2^22)
.CONST $cbops.rate_monitor_op.WARP_MSG_LIMIT_FIELD                  6;  // Number of warp messages to send
.CONST $cbops.rate_monitor_op.IDLE_PERIODS_AFTER_STALL_FIELD        7;  // Number of timer handler calls before rate matching restarts after a stall

// Initialize to zero
.CONST $cbops.rate_monitor_op.ACCUMULATOR_FIELD                     8;  // Accumulator used to accumulate samples during the measurement period
.CONST $cbops.rate_monitor_op.COUNTER_FIELD                         9;  // Counter of timer interrupt periods (nominally at a 625usec period)
.CONST $cbops.rate_monitor_op.STALL_FIELD                           10; // Counter used to determine the stall status (stalled if >= 3) - initialize to >= 3 for stall
.CONST $cbops.rate_monitor_op.LAST_ACCUMULATION_FIELD               11; // Number of input samples transferred over the measurement period (used in warp calculation)
.CONST $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD             12; // Filter coeff index used to control adaptation convergence
.CONST $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD              13; // Warp value used to control S/W warp operator (used to match local rate to output rate)
.CONST $cbops.rate_monitor_op.WARP_VALUE_FIELD                      14; // Warp value used to control S/W warp operator (used to match input rate to local rate)
.CONST $cbops.rate_monitor_op.WARP_MSG_COUNTER_FIELD                15; // Count of warp messages

.CONST $cbops.rate_monitor_op.DEBUG_STALL_COUNT_FIELD               16; // Count of the number of stalls
.CONST $cbops.rate_monitor_op.DEBUG_LAST_PERIOD_COUNT_FIELD         17; // Final handler timer call count for the measurement period
.CONST $cbops.rate_monitor_op.DEBUG_TIMER_PERIOD_FIELD              18; // Calculated timer period
.CONST $cbops.rate_monitor_op.DEBUG_ALG_RESTART_COUNT_FIELD         19; // Count of algorithm restarts
.CONST $cbops.rate_monitor_op.DEBUG_INSTANTANEOUS_IO_RATIO_FIELD    20; // Instantaneous IO rate (in Q.22 format)

.CONST $cbops.rate_monitor_op.STRUC_SIZE                            21;


.CONST $cbops.rate_monitor_op.NO_DATA_PERIODS_FOR_STALL             3;          // Number of timer handler calls with no data before declaring a stall
.CONST $cbops.rate_monitor_op.ALG_RESTART_THRESHOLD                 0.0005;      // The rate match algorithm is restarted when the instantaneous and average IO ratios differ by this threshold

#endif // CBOPS_RATE_MONITOR_OP_HEADER_INCLUDED




