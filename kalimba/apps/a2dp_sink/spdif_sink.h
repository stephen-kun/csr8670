// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#ifndef SPDIF_SINK_HEADER_INCLUDED
#define SPDIF_SINK_HEADER_INCLUDED

   #define TMR_PERIOD_SPDIF_COPY           1000   // spdif data copy runs per 1ms
   #define MAX_SPDIF_SRA_RATE              0.015  // maximum mismatch rate between input and output clocks
   #define SPDIF_PACKET_BOUNDARY_INFO_SIZE 40     // size of cbuffer for packets' boundary info
   #define SPDIF_DEFAULT_LATENCY_MS        40     // default latency
   #define MIN_SPDIF_LATENCY_MS            25     // minimum target latency
   #define MIN_SPDIF_LATENCY_WITH_SUB_MS   40     // minimum target latency when sub is connected
   #define MAX_SPDIF_LATENCY_CODED_MS      150    // maximum target latency for coded input
   #define MAX_SPDIF_LATENCY_PCM_MS        70     // maximum target latency for pcm input

   #define SPDIF_LATENCY_CONVERGE_US       150    // in us, assumed converged when latency diff reaches to this value
   #define OUTPUT_INTERFACE_INIT_ACTIVE           // output is connected acive not inactive
   #define SPDIF_PAUSE_THRESHOLD_US        5000   // pause detection threshold in micro seconds
   #define SPDIF_PAUSE_SILENCE_TO_ADD_MS   50     // maximum amount of silence to insert during pause

   // Port used for SPDIF inputs
   .CONST $SPDIF_IN_LEFT_PORT        ($cbuffer.READ_PORT_MASK  + 0 + $cbuffer.FORCE_NO_SIGN_EXTEND);
   .CONST $SPDIF_IN_RIGHT_PORT       ($cbuffer.READ_PORT_MASK  + 1 + $cbuffer.FORCE_NO_SIGN_EXTEND);

   .CONST $spdif_sra.RATE_CALC_HIST_SIZE 32;

   .CONST $spdif_sra.MAX_RATE_FIELD                  0;  // maximum mismatch rate to compensate
   .CONST $spdif_sra.TARGET_LATENCY_MS_FIELD         1;  // target latency in ms
   .CONST $spdif_sra.CURRENT_LATENCY_PTR_FIELD       2;  // current latency in the system
   .CONST $spdif_sra.OFFSET_LATENCY_US_FIELD         3;  // target latency in ms
   .CONST $spdif_sra.SRA_RATE_FIELD                  4;  // calculated mismatch rate
   .CONST $spdif_sra.FIX_RATE_FIELD                  5;  // a small fix for rate when the buffer gets full or empty
   .CONST $spdif_sra.SAMPLES_DELAY_AVERAGE_FIELD     6;  // Average delay in samples
   .CONST $spdif_sra.AVERAGE_LATENCY_FIELD           7;  // current average latency
   .CONST $spdif_sra.AVERAGE_LATENCY_LEFT_FIELD      8;  // latency can be added by this value
   .CONST $spdif_sra.LATENCY_CONVERGED_FIELD         9; // flag showing latemcy converged
   .CONST $spdif_sra.RATE_BEFORE_FIX_FIELD           10; // actual clock mismatch rate (x16)
   .CONST $spdif_sra.STRUC_SIZE                      11;

   // define SPDIF related message IDs
   #define VM_CONFIG_SPDIF_APP_MESSAGE_ID             0x1073  // VM to DSP, to configure the spdif sink app
   #define VM_AC3_DECODER_CONFIG_MESSAGE_ID           0x1074  // VM to DSP, to configure ac-3 decoder
   .CONST $SPDIF_EVENT_MSG                            0x1075; // DSP to VM. to notify events in the input stream
   #define VM_AC3_USER_INFO_REQUEST_MESSGE_ID         0x1076  // VM to DSP, to request for latest AC-3 stream status
   #define AC3_USER_INFO_MSG                          0x1077  // DSP to VM, to send the latest status of AC-3 stream

   .CONST $ENABLE_RATE_MATCH                   0x0;
   .CONST $DISABLE_ALL_RATE_MATCH_CONFIGURED   0x1;
   .CONST $DISABLE_HW_RATE_MATCH_SUB_NEEDS     0x2;
   .CONST $DISABLE_HW_RATE_MATCH_NOT_DOABLE    0x4;
   .CONST $DISABLE_SW_RATE_MATCH_HW_PREFERED   0x8;

   .CONST $hw_warp.TIMER_PERIOD_FIELD       0;   // TIMER period
   .CONST $hw_warp.TARGET_RATE_PTR_FIELD    1;   // address containg target rate
   .CONST $hw_warp.MOVING_STEP_FIELD        2;   // moving step
   .CONST $hw_warp.LAST_TIME_FIELD          3;   // last time it warp updated
   .CONST $hw_warp.CURRENT_RATE_FIELD       4;   // current hw warp value
   .CONST $hw_warp.STRUC_SIZE               5;

#endif // #ifndef   SPDIF_SINK_HEADER_INCLUDED
