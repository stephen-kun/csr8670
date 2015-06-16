// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    two_mic_example_system.asm
//
// DESCRIPTION:
//    This file defines the functions that are used by the two_mic_example
//    system.
//
// *****************************************************************************

#include "stack.h"
#include "two_mic_example.h"
#include "core_library.h"


// *****************************************************************************
// MODULE:
//    $M.two_mic_example_reinitialize
//
// DESCRIPTION:
// This routine is called by two_mic_example_process when the algorithm needs to
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
.MODULE $M.two_mic_example_reinitialize;
 .CODESEGMENT PM;

$two_mic_example_reinitialize:
// Transfer Parameters to Modules.

// Call Module Initialize Functions
   $push_rLink_macro;
   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;

// Clear Reinitialization Flag
   M[$two_mic_example.reinit]    = NULL;
   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.two_mic_example_process.vm 
//
// DESCRIPTION:
//    Data module containing vm message structures.
//
// *****************************************************************************
.MODULE $M.two_mic_example.vm;
 .DATASEGMENT DM;
 .VAR set_mode_msg_struc[$message.STRUC_SIZE];
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.two_mic_example.vm_msg.set_mode 
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
.MODULE $M.two_mic_example_.vm_msg.set_mode;
   .CODESEGMENT PM;

$two_mic_example.vm_msg.setmode:
   $push_rLink_macro;
   r3 = M[$two_mic_example.num_modes];
   NULL = r3 - r1;
   if NEG r1 = 0;
   M[$two_mic_example.sys_mode]   = r1;
   r2 = $two_mic_example.REINITIALIZE;
   M[$two_mic_example.reinit] =  r2;
   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.two_mic_example.send_ready_msg 
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
.MODULE $M.two_mic_example.power_up_reset;
 .DATASEGMENT    DM;
 .CODESEGMENT    PM;

// Entries can be added to this table to suit the system being developed.
   .VAR  message_handlers[] =
// Message Struc Ptr  Message ID  Message Handler  Registration Function
   &$M.two_mic_example.vm.set_mode_msg_struc,  $two_mic_example.VMMSG.SETMODE,
   &$two_mic_example.vm_msg.setmode, $message.register_handler,
      0;

$two_mic_example.power_up_reset:
   $push_rLink_macro; 
   r4 = &message_handlers;
   call $frame_sync.register_handlers;
   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.two_mic_example 
//
// DESCRIPTION:
//    two_mic_example data object.
//
// *****************************************************************************
.MODULE $two_mic_example;
 .DATASEGMENT DM;
   .VAR  sys_mode       = $two_mic_example.SYSMODE.PASSTHRU;
   .VAR  reinit         = $two_mic_example.REINITIALIZE;
   .VAR  num_modes      = 1;
.ENDMODULE;
