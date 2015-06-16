// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    one_mic_example_system.asm
//
// DESCRIPTION:
//    This file defines the functions that are used by the one_mic_example
//    system.
//
// *****************************************************************************

#include "stack.h"
#include "one_mic_example.h"
#include "core_library.h"

// *****************************************************************************
// MODULE:
//    $M.one_mic_example_reinitialize
//
// DESCRIPTION:
// This routine is called by one_mic_example_process when the algorithm needs to
// be reinitialized.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// CPU USAGE:
//    CODE memory:    6  words
//    DATA memory:    0  words
// *****************************************************************************
.MODULE $M.one_mic_example_reinitialize;
 .CODESEGMENT PM;

$one_mic_example_reinitialize:
// Transfer Parameters to Modules.

// Call Module Initialize Functions
   $push_rLink_macro;
   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;

// Clear Reinitialization Flag
   M[$one_mic_example.reinit]    = NULL;
   
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.one_mic_example_process.vm 
//
// DESCRIPTION:
//    Data module containing vm message structures.
//
// *****************************************************************************
.MODULE $M.one_mic_example.vm;
 .DATASEGMENT DM;
 
 .VAR set_mode_msg_struc[$message.STRUC_SIZE];
 .VAR $persistant_warp_message_struc[$message.STRUC_SIZE]; 
 
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.one_mic_example.vm_msg.set_mode 
//
// DESCRIPTION:
//    This function handles the set_mode message from the VM.
//    If the mode sent by the VM is out of range, the first mode is forced.
//
// INPUTS:
//    r1 = mode
//
// OUTPUTS:
//    none
//
// CPU USAGE:
//    CODE memory:    9  words
//    DATA memory:    0  words
// *****************************************************************************
.MODULE $M.one_mic_example_.vm_msg.set_mode;
   .CODESEGMENT PM;

$one_mic_example.vm_msg.setmode:
   $push_rLink_macro;
   r3 = M[$one_mic_example.num_modes];
   NULL = r3 - r1;
   if NEG r1 = 0;
   M[$one_mic_example.sys_mode]   = r1;
   r2 = $one_mic_example.REINITIALIZE;
   M[$one_mic_example.reinit] =  r2;
   jump $pop_rLink_and_rts;
.ENDMODULE;

#ifdef USB_DONGLE
// *********************************************************************************
// MODULE:
//    $persistant_warp_message_handler
//
// DESCRIPTION:
//   handler function for receiving persistant warp mesage from vm and
//   configuring the warp/ rate matching data structure to use the last good warp value
//   stored in the PSKEYs
//
// INPUTS:
//    - r1 has WARP_MSG_COUNTER (upper 8 bits)  and CURRENT_ALPHA_INDEX (lower 8 bits) 
//    - r2 has upper 16 bits AVERAGE_IO_RATIO,
//    - r3 has lower 8 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT and lower 8 bits of AVERAGE_IO_RATIO
//    - r4 has upper 16  bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r4   
// **********************************************************************************
.MODULE $M.persistant_warp_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$persistant_warp_message_handler:

      $push_rLink_macro;
      r8 = &$usb_in_rm.sw_rate_op.param;
      r1 = r1 AND 0xFF; // CURRENT_ALPHA_INDEX
      M[r8 + $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD] = r1; // Store CURRENT_ALPHA_INDEX
      
      r2 = r2 LSHIFT 8; // shift up 8 bits
      r1 = r3 AND 0xFF; // lower 8 bits of AVERAGE_IO_RATIO
      r2 = r2 OR r1; // Form full 24 bit value for AVERGE_IO_RATIO
      M[r8 + $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD] = r2;  // Store AVERAGE_IO_RATIO
      
      r4 = r4 LSHIFT 8; // shift up 8 bits
      r1 = r3 LSHIFT -8; // lower 8 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT
      r1 = r1 AND 0xFF; // lower 8 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT
      r4 = r4 OR r1; // Form full 24 bit value for TARGET_WARP_VALUE_OUTPUT_ENDPOINT
      M[r8 + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD] = r4; // Store TARGET_WARP_VALUE_OUTPUT_ENDPOINT
      r4 = -r4;
      M[r8 + $cbops.rate_monitor_op.WARP_VALUE_FIELD] = r4;
      
      // Reset Rate Detect
      r1 = M[r8 + $cbops.rate_monitor_op.TARGET_RATE_FIELD];
      call $cbops.rate_monitor_op.Initialize;
 
      jump $pop_rLink_and_rts;
      
.ENDMODULE;
#endif
// *****************************************************************************
// MODULE:
//    $M.one_mic_example.send_ready_msg 
//
// DESCRIPTION:
//    This function sends a ready message to the VM application signifying that
//    it is okay for the VM application to connect streams to the kalimba.  The
//    application needs to call this function just prior to scheduling the audio
//    interrupt handler.  
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//          
// CPU USAGE:
//    cycles = 
//    CODE memory:    5  words
//    DATA memory:    4  words
// *****************************************************************************
.MODULE $M.one_mic_example.power_up_reset;
 .DATASEGMENT    DM;
 .CODESEGMENT    PM;

// Entries can be added to this table to suit the system being developed.
   .VAR  message_handlers[] =
// Message Struc Ptr  Message ID  Message Handler  Registration Function
   &$M.one_mic_example.vm.set_mode_msg_struc,  $one_mic_example.VMMSG.SETMODE,
   &$one_mic_example.vm_msg.setmode, $message.register_handler,
      0;

$one_mic_example.power_up_reset:
   $push_rLink_macro; 
   r4 = &message_handlers;
   call $frame_sync.register_handlers;
   jump $pop_rLink_and_rts;
   
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.one_mic_example 
//
// DESCRIPTION:
//    one_mic_example data object.
//
// *****************************************************************************
.MODULE $one_mic_example;
 .DATASEGMENT DM;
   .VAR  sys_mode       = $one_mic_example.SYSMODE.PASSTHRU;
   .VAR  reinit         = $one_mic_example.REINITIALIZE;
   .VAR  num_modes      = 1;
.ENDMODULE;
