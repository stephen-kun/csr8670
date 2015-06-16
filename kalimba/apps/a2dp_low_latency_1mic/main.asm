// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2003)        http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************
// *****************************************************************************
// A2DP Low Latency 1mic Application
//
// Subsystem definitions 
// Backend  : Decode(APTX-LL, Faststream)@44.1 or 48kHz, Encode(mSBC/WBS)@16kHz
// Frontend : ADC @16kHz, DAC/I2S out @44.1 or 48kHz
// Send     : CVC 1mic Echo and Noise Reduction processing tuned through UFE
// Receive  : Music manager post processing tuned through UFE
// Main     : Start up sequence and system operation
// *****************************************************************************
// *****************************************************************************
#include "core_library.h"
#include "codec_library.h"
#include "spi_comm_library.h"
#include "a2dp_low_latency_1mic_library_gen.h"

#define SETPLUGIN_MESSAGE_ID            0x1024
#define SET_DAC_RATE_MESSAGE_ID         0x1070
#define SET_CODEC_RATE_MESSAGE_ID       0x1071
#define SET_TONE_RATE_MESSAGE_ID        0x1072
#define APTX_LL_PARAMS1_MESSAGE_ID      0x1036
#define APTX_LL_PARAMS2_MESSAGE_ID      0x1037
#define SET_EQ_BANK_MESSAGE_ID          0x1039
#define CUR_EQ_BANK_MESSAGE_ID          0x1028
#define CONFIGURE_LATENCY_REPORTING     0x1027

.MODULE $M.main;
   .CODESEGMENT MAIN_PM;
   .DATASEGMENT DM;
   
   .VAR set_plugin_message_struc[$message.STRUC_SIZE];
   .VAR set_dac_rate_message_struc[$message.STRUC_SIZE];
   .VAR set_codec_rate_message_struc[$message.STRUC_SIZE];
   .VAR set_tone_rate_message_struc[$message.STRUC_SIZE];
   .VAR aptx_ll_params1_message_struc[$message.STRUC_SIZE];
   .VAR aptx_ll_params2_message_struc[$message.STRUC_SIZE];
   .VAR set_eq_bank_message_struc[$message.STRUC_SIZE];
   .VAR latency_reporting_message_struc[$message.STRUC_SIZE];

$main:
   // initialise the stack library
   call $stack.initialise;
   // initialise the interrupt library
   call $interrupt.initialise;
   // initialise the message library
   call $message.initialise;
   // initialise the cbuffer library
   call $cbuffer.initialise;
   // initialise the pskey library
   call $pskey.initialise;
   // initialize Licensing subsystem
   call $Security.Initialize;
#ifdef DEBUG_ON
   // initialise the profiler library
   call $profiler.initialise;
#endif
   // init DM_flash
   call $flash.init_dmconst;
   
   // handler for SET_EQ_BANK_MESSAGE_ID message
   r1 = &set_eq_bank_message_struc;
   r2 = SET_EQ_BANK_MESSAGE_ID;
   r3 = &$M.set_eq_bank.func;
   call $message.register_handler;

   // handler for SET_DAC_RATE_MESSAGE_ID message
   r1 = &set_dac_rate_message_struc;
   r2 = SET_DAC_RATE_MESSAGE_ID;
   r3 = &$M.set_dac_rate.func;
   call $message.register_handler;
   
   // handler for SET_CODEC_RATE_MESSAGE_ID message
   r1 = &set_codec_rate_message_struc;
   r2 = SET_CODEC_RATE_MESSAGE_ID;
   r3 = &$M.set_codec_rate.func;
   call $message.register_handler;

   // handler for SET_TONE_RATE_MESSAGE_ID message
   r1 = &set_tone_rate_message_struc;
   r2 = SET_TONE_RATE_MESSAGE_ID;
   r3 = &$M.set_tone_rate.func;
   call $message.register_handler;

   // handler for SETPLUGIN_MESSAGE_ID 
   r1 = &set_plugin_message_struc;
   r2 = SETPLUGIN_MESSAGE_ID;
   r3 = &$M.set_plugin.func;
   call $message.register_handler;

#ifdef LATENCY_REPORTING
   // handler for CONFIGURE_LATENCY_REPORTING 
   r1 = &latency_reporting_message_struc;
   r2 = CONFIGURE_LATENCY_REPORTING;
   r3 = &$M.configure_latency_reporting.func;
   call $message.register_handler;
#endif    

#ifdef APTX_ACL_SPRINT_ENABLE   
   // handlers for VM_APTX_LL_PARAMS_MESSAGE_ID messages
   r1 = &aptx_ll_params1_message_struc;
   r2 = APTX_LL_PARAMS1_MESSAGE_ID;
   r3 = &$M.aptx_ll_params1.func;
   call $message.register_handler;
   
   r1 = &aptx_ll_params2_message_struc;
   r2 = APTX_LL_PARAMS2_MESSAGE_ID;
   r3 = &$M.aptx_ll_params2.func;
   call $message.register_handler;
#endif   

   // intialize SPI communications library
   call $spi_comm.initialize;
    
#ifdef LATENCY_REPORTING
   // reset encoded latency module
   r7 = &$encoded_latency_struct;
   call $latency.reset_encoded_latency;
#endif 

   // set up message handler for GO message
   r1 = &$M.message.send_ready_wait_for_go.go_from_vm_message_struc;
   r2 = $MESSAGE_GO;
   r3 = &$M.message.send_ready_wait_for_go.go_from_vm_handler;
   call $message.register_handler;

   // send message saying we're up and running!
   r2 = Null OR $MESSAGE_KALIMBA_READY;
   call $message.send_short;

   // power up reset and cvc start   
   call $SendProcStart; 
   // start frontend timer
   call $FrontEndStart;
   
   // wait until GO message from the VM has been received
vm_go_wait:
      Null = M[$M.message.send_ready_wait_for_go.go_from_vm];
   if Z jump vm_go_wait;

   // initialize encode/decode and setup rate matching
   call $ConfigureBackEnd;
   // start backend timer
   call $BackEndStart;

   // continually decode and encode codec frames
frame_loop:

    // Check Communication
    call $spi_comm.polled_service_routine;
   // call decoder for music channel
    call $DecodeInput;

    M[$ARITHMETIC_MODE] = NULL;

   // run music manager function table
    call $ReceiveProcRun;
   // run cvc function table
    call $SendProcRun;
   // call encoder for voice channel
    call $EncodeOutput;
    
    // If either encoder or decoder report SUCCESS continue immediately.
    // Otherwise sleep one msec. This ensures all available data is
    // processed without delay
    r0 = M[&$M.A2DP_OUT.encoder_codec_stream_struc + $codec.av_encode.MODE_FIELD];
    Null = r0 - $codec.SUCCESS;
    if Z jump frame_loop;
    
    r0 = M[&$M.A2DP_IN.decoder_codec_stream_struc + $codec.av_decode.MODE_FIELD];
    Null = r0 - $codec.SUCCESS;
    if NZ call $SystemSleep;
    jump frame_loop;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $SystemSleep
//
// DESCRIPTION:
//    Place Processor in IDLE and compute system MIPS
//
// *****************************************************************************
.MODULE $M.Sleep;
   .CODESEGMENT SYSTEM_SLEEP_PM;
   .DATASEGMENT DM;
   
    .VAR TotalTime=0;
    .VAR LastUpdateTm=0;
    .VAR Mips=0;
   
$SystemSleep:

     // set sync_flag at start of frame process
     r1 = 1;
     M[$frame_sync.sync_flag] = r1;
     // Timer status for MIPs estimate
     r1 = M[$TIMER_TIME]; 
     r4 = M[$interrupt.total_time];
     // save current clock rate
     r6 = M[$CLOCK_DIVIDE_RATE];
     // go to slower clock and wait for task event
     r0 = $frame_sync.MAX_CLK_DIV_RATE;
     M[$CLOCK_DIVIDE_RATE] = r0;
   
   // wait in loop (delay) till sync flag is reset
jp_wait:
     Null = M[$frame_sync.sync_flag];
   if NZ jump jp_wait;   
     
     // restore clock rate
     M[$CLOCK_DIVIDE_RATE] = r6; 
     
     // r1 is total idle time
     r3 = M[$TIMER_TIME];         
     r1 = r3 - r1; 
     r4 = r4 - M[$interrupt.total_time];
     r1 = r1 + r4;
     r0 = M[&TotalTime]; 
     r1 = r1 + r0;
     M[&TotalTime]=r1; 
     
     // Check for MIPs update  <reserve r2,r8>
     r0 = M[LastUpdateTm];
     r5 = r3 - r0;
     rMAC = 1000000;
     NULL = r5 - rMAC;
     if NEG rts;
     
     // Time Period
	 rMAC = rMAC ASHIFT -1;
	 Div = rMAC/r5;       
     // Total Processing (Time Period - Idle Time)
     rMAC = r5 - r1;
     // Last Trigger Time 
     M[LastUpdateTm]=r3;
     // Reset total time count 
     M[&TotalTime]=NULL; 
     // MIPS
     r3  = DivResult;
     rMAC  = r3 * rMAC (frac);	
     // Convert for UFE format
	 // UFE uses STAT_FORMAT_MIPS - Displays (m_ulCurrent/8000.0*m_pSL->GetChipMIPS()) 
	 // Multiply by 0.008 = 1,000,000 --> 8000 = 100% of MIPs  
	 r3 = 0.008;
     rMAC = rMAC * r3 (frac);  // Total MIPs Est
     M[Mips]=rMAC;  
     rts;
     
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $SystemReInitialize
//
// DESCRIPTION:
//    Always called for a MODE change
//
// *****************************************************************************
.MODULE $M.A2DP_LOW_LATENCY_1MIC.SystemReInitialize;
   .CODESEGMENT CVC_SYSTEM_REINITIALIZE_PM;
   .DATASEGMENT DM;
   
 func:
   // Clear Re-Initialize Flag
   M[$M.CVC_SYS.AlgReInit]    = Null;
   M[$M.CVC_SYS.FrameCounter] = Null;
   
   // Transfer Parameters to Modules.
   // Assumes at least one value is copied
   M1 = 1;
   I0 = &$M.CVC.data.ParameterMap;
   // Get Source (Pre Load)
   r0 = M[I0,M1];
lp_param_copy:
      // Get Destination
      r1 = M[I0,M1];
      // Read Source,
      r0 = M[r0];
      // Write Destination,  Get Source (Next)
      M[r1] = r0, r0 = M[I0,M1];
      // Check for NULL termination
      Null = r0;
   if NZ jump lp_param_copy;

#if uses_AEC
   // Configure CNG
   r1 = $M.AEC_500.CNG_G_ADJUST;
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r2 = r0 AND ($M.A2DP_LOW_LATENCY_1MIC.CONFIG.CNGENA + $M.A2DP_LOW_LATENCY_1MIC.CONFIG.AECENA);
   Null = r2 - ($M.A2DP_LOW_LATENCY_1MIC.CONFIG.CNGENA + $M.A2DP_LOW_LATENCY_1MIC.CONFIG.AECENA);
   if NZ r1 = Null;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_CNG_G_ADJUST] = r1;
   
   // Configure RER
   r2 = r0 AND $M.A2DP_LOW_LATENCY_1MIC.CONFIG.RERENA;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_RER_func] = r2;
   // Configure Send OMS aggresiveness
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_OMS_AGGR];
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS] = r0;
   
#endif

   // push rLink onto stack
   $push_rLink_macro;
   
   // Call Module Initialize Functions   
   r4 = &$M.CVC.data.ReInitializeTable;
   call $frame_sync.run_function_table;
   
   // Clear Re-Initialize Flag
#if uses_AEC   
   r0 = Null;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS] = r0;   
#endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
.ENDMODULE;
