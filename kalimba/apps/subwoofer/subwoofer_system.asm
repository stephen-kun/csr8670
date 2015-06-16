// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    subwoofer_system.asm
//
// DESCRIPTION:
//    This file defines the functions that are used by the subwoofer
//    system.
//
// *****************************************************************************

#include "stack.h"
#include "subwoofer.h"
#include "core_library.h"
#include "spi_comm_library.h"
#include "mips_profile.h"
#include "subwoofer_config.h"

// *****************************************************************************
// MODULE:
//    $M.music_example_process
//
// DESCRIPTION:
// This routine is called from the main loop when a frame of data is ready
// to be processed.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// *****************************************************************************
.MODULE $M.music_example_process;
 .CODESEGMENT  MUSIC_EXAMPLE_PROCESS_PM;
 .DATASEGMENT  DM;
   .VAR  TimeStamp;
   .VAR  PeakMips;

$music_example_process:
   $push_rLink_macro;

   M[$ARITHMETIC_MODE] = NULL;

   r8 = &$FunctionMips_data_block;
   call $M.mips_profile.mainstart;   // start profiler

// Check for Initialization
   NULL = M[$music_example.reinit];
   if NZ call $music_example_reinitialize;

// Determine processing mode
   r1 = $M.SUBWOOFER.SYSMODE.STANDBY;
   r4 = 0;
   
    r3 = 1;
// If no ports are connected go into standby mode
   r0 = $SCO_IN_PORT_HEADER;
   call $cbuffer.is_it_enabled;
   if NZ r4 = r4 + r3;

   r0 = $L2CAP_IN_PORT;
   call $cbuffer.is_it_enabled;
   if NZ r4 = r4 + r3;

   r0 = $ADC_PORT;
   call $cbuffer.is_it_enabled;
   if NZ r4 = r4 + r3;
   
   NULL = r4 - NULL;
   if Z jump mode_processing;

   // A port is connected, determine which processing to do.
   r1 = $M.SUBWOOFER.SYSMODE.BLUETOOTH;
   r2 = $M.SUBWOOFER.SYSMODE.ADC;

// If ADC is connected change the mode
   r0 = $ADC_PORT;
   call $cbuffer.is_it_enabled;
   if NZ r1 = r2;

// Call processing table that corresponds to the current mode
mode_processing:
   // Provide Mode to UFE
   M[$music_example.CurMode] = r1;

   r4 = M[$M.system_config.data.mode_table + r1];
   call $frame_sync.run_function_table;

   r8 = &$FunctionMips_data_block;
   call $M.mips_profile.mainend;

   // Store Function MIPS
   r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
   M[&$music_example.PeakMipsFunc] = r0;
   
   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.music_example_reinitialize
//
// DESCRIPTION:
// This routine is called by music_example_process when the algorithm needs to
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
.MODULE $M.music_example_reinitialize;
 .CODESEGMENT MUSIC_EXAMPLE_REINIT_PM;

$music_example_reinitialize:
   $push_rLink_macro;

// Transfer Parameters to Modules.
// Assumes at least one value is copied
   M1 = 1;
   I0 = &$M.system_config.data.ParameterMap;
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


// Tell VM the current EQ Bank
   r2 = $music_example.VMMSG.CUR_EQ_BANK;
   r3 = r0 AND $M.SUBWOOFER.CONFIG.USER_EQ_SELECT;
   call $message.send_short;
   


// Call Module Initialize Functions
   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;

// Clear Reinitialization Flag
   M[$music_example.reinit]    = NULL;
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.music_example.peq.process
//
// DESCRIPTION:
//    front end for peq's. Exits if 0-stage.
//
// INPUTS:
//    - r7 = pointer to peq object
//    - r8 = pointer to bank select object
//
// OUTPUTS:
//    - none
//
//
// *****************************************************************************

.MODULE $music_example.peq;
   .CODESEGMENT MUSIC_EXAMPLE_PEQ_PM;

.DATASEGMENT DM;

//------------------------------------------------------------------------------
initialize:
//------------------------------------------------------------------------------
// initialise parametric filter
// - if user_eq, then need to select filter bank, and adjust it depending on
//   sample rate.  If filter bank is zero, then don't update coefficients as
//   filtering is put into bypass by peq processing wrapper (below).
//   Bank 0 means flat curve, but is only valid if EQFLAT is enabled.
//   Bank 1 means use the peq 1 for 44.1 kHz or peq 7 for 48 kHz etc...
// - if not user_eq, then force filter bank to zero.  sample rate bank switch is
//   still performed.
//------------------------------------------------------------------------------
// on entry r7 = pointer to filter object
//          r8 = pointer to bank selection object
//------------------------------------------------------------------------------

    r0 = M[&$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_CONFIG];
    r5 = M[r8];     // Number of banks per sample rate
   
    // running user_eq so get selected bank number
    // speaker and base boost only have one bank
    r3 = r0 and $M.SUBWOOFER.CONFIG.USER_EQ_SELECT;
    NULL = r5 - 1;
    if Z r3=Null;

    // Use sample rate to update bank
#if 0 // NOT NEEDED IN SUBWOOFER BECAUSE WE ONLY USE 48 kHz
    r1 = M[$current_codec_sampling_rate];
    Null = r1 - 48000;
    if Z r3 = r3 + r5;
#endif

    // Access the requested Bank
    // PARAM_PTR_FIELD=Null for no Peq
    r8 = r8 + 1;
    r0 = M[r8 + r3];
    M[r7 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
    if Z rts;
    jump $audio_proc.peq.initialize;


//------------------------------------------------------------------------------
process:
//------------------------------------------------------------------------------
// peq processing wrapper
// - return without processing if bypassed
// - if running user_eq (BYPASS_BIT_MASK_FIELD == USER_EQ_BYPASS)
//     then check whether user eq bank is 0
//------------------------------------------------------------------------------
// on entry r7 = pointer to filter object (used by audio_proc.peq.process)
//------------------------------------------------------------------------------

    r0 = M[&$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_CONFIG];
    
    // check if EQ is bypassed
    null = r0 and r8;
    if NZ rts;
    
    // if Parameters is Null then no Peq
    Null = M[r7 + $audio_proc.peq.PARAM_PTR_FIELD];
    if Z rts;

    jump $audio_proc.peq.process;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.music_example.send_ready_msg
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
.MODULE $M.music_example.power_up_reset;
 .DATASEGMENT    DM;
 .CODESEGMENT    MUSIC_EXAMPLE_POWER_UP_RESET_PM;

// Entries can be added to this table to suit the system being developed.
   .VAR  message_handlers[] =
// Message Struc Ptr  Message ID  Message Handler  Registration Function
   &$M.music_example_message.set_mode_message_struc,       $music_example.VMMSG.SETMODE,                 &$M.music_example_message.SetMode.func,      $message.register_handler,
   &$M.music_example_message.volume_message_struc,         $music_example.VMMSG.VOLUME,                  &$M.music_example_message.Volume.func,       $message.register_handler,
   &$M.music_example_message.load_params_message_struc,    $music_example.VMMSG.LOADPARAMS,              &$M.music_example.LoadParams.func,           $message.register_handler,
   &$M.music_example_message.signal_detect_message_struct, $music_example.VMMSG.SIGNAL_DETECT_SET_PARMS, &$M.music_example_message.SignalDetect.func, $message.register_handler,
   &$M.music_example_message.soft_mute_message_struct,     $music_example.VMMSG.SOFT_MUTE,               &$M.music_example_message.SoftMute.func,     $message.register_handler,
   &$M.music_example_message.set_dac_rate_from_vm,         $music_example.VMMSG.DAC_RATE,                &$M.music_example_message.set_dac_rate.func, $message.register_handler,
   &$M.music_example_spi.status_message_struc,             $M.music_example.SPIMSG.STATUS,               &$M.music_example.GetStatus.func,            $spi_comm.register_handler,
   &$M.music_example_spi.version_message_struc,            $M.music_example.SPIMSG.VERSION,              &$M.music_example.GetVersion.func,           $spi_comm.register_handler,
   &$M.music_example_spi.control_message_struc,            $M.music_example.SPIMSG.CONTROL,              &$M.music_example.GetControl.func,           $spi_comm.register_handler,
   &$M.music_example_spi.reinit_message_struc,             $M.music_example.SPIMSG.REINIT,               &$M.music_example.ReInit.func,               $spi_comm.register_handler,
   &$M.music_example_spi.parameter_message_struc,          $M.music_example.SPIMSG.PARAMS,               &$M.music_example.GetParams.func,            $spi_comm.register_handler,
      0;

$music_example.power_up_reset:
   $push_rLink_macro;

   // Copy default parameters into current parameters
   call $M.music_example.load_default_params.func;

   r4 = &message_handlers;
   call $frame_sync.register_handlers;
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.music_example.load_default_params
//
// DESCRIPTION:
//    This function copies the (packed) default parameter values into the current
//    parameters block...
//
//    Packing format should be three 16-bit words to two 24-bit words
//    eg: 1234 5678 9abc def0 to 123456,789abc
//
//    Throughput is 2 outputs/8 cycles
//
// INPUTS:
//    NONE
//
// OUTPUTS:
//    loads Default parameter values into CurParams block.
//
// TRASHED REGISTERS:
//    r0,r2,r3,r4,L0,I0,I1,I4,r10,Loop
//
// CPU USAGE:
//    cycles =
//    CODE memory:     18 words
//    DATA memory:     5 words
//
// Note:
//    LENGTH($M.system_config.data.CurParams) must be even
//
// *****************************************************************************
.MODULE $M.music_example.load_default_params;


   .CODESEGMENT MUSIC_EXAMPLE_LOAD_DEFAULT_PARAMS_PM;
   .DATASEGMENT DM;
   .VAR/DM1CIRC operatorvals[] = 8,0x00ff00,-8,0x00ffff,16;

func:
   L0 = LENGTH(operatorvals);
   I0 = &operatorvals;
   I4 = &$M.system_config.data.DefaultParameters;
   I1 = &$M.system_config.data.CurParams;
   r10 = LENGTH($M.system_config.data.CurParams);
#if 1 // compiler bug: should divide above by two @ compile time
   r10 = r10 ASHIFT -1;
#endif
   r4 = M[I0, 1], r0 = M[I4, 1];  // load 8, load 0x1234
   do three16_to_two24_loop;
      r0 = r0 LSHIFT r4, r4 = M[I0, 1], r2 = M[I4, 0]; // load 0x5678,load mask
      r2 = r2 AND r4, r4 = M[I0, 1];    // mask sign bits, load -8
      r2 = r2 LSHIFT r4, r4 = M[I0, 1], r3 = M[I4, 1]; // load mask, load 0x5678
      r0 = r0 OR r2,               r2 = M[I4, 1]; // load 0x9abc, word1 done
      r2 = r2 AND r4, r4 = M[I0, 1];      // clear upper bits of word2, load 16
      r3 = r3 LSHIFT r4, M[I1, 1] = r0;   // store word1
      r3 = r3 OR r2,     r4 = M[I0, 1], r0 = M[I4, 1]; // load 8, load 0xdef0
      M[I1, 1] = r3;  // word2 done, store word2
   three16_to_two24_loop:
   L0 = 0;
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.music_example
//
// DESCRIPTION:
//    music_example data object.
//
// *****************************************************************************
.MODULE $M.MUSIC_EXAMPLE_VERSION_STAMP;
   .DATASEGMENT DM;
   .BLOCK VersionStamp;
   .VAR  h1 = 0xbeef;
   .VAR  h2 = 0xbeef;
   .VAR  h3 = 0xbeef;
   .VAR  SysID = $SUBWOOFER_SYSID;
   .VAR  BuildVersion = SUBWOOFER_VERSION;
   .VAR  h4 = 0xbeef;
   .VAR  h5 = 0xbeef;
   .VAR  h6 = 0xbeef;
   .ENDBLOCK;
.ENDMODULE;

// System Configuration is saved in kap file.
.MODULE $M.MUSIC_EXAMPLE_MODULES_STAMP;
   .DATASEGMENT DM;
   .BLOCK ModulesStamp;
      .VAR  s1 = 0xfeeb;
      .VAR  s2 = 0xfeeb;
      .VAR  s3 = 0xfeeb;
      .VAR  CompConfig = SUBWOOFER_CONFIG_FLAG;
      .VAR  s4 = 0xfeeb;
      .VAR  s5 = 0xfeeb;
      .VAR  s6 = 0xfeeb;
   .ENDBLOCK;
.ENDMODULE;

.MODULE $music_example; // TODO: rename subwoofer
 .DATASEGMENT DM;
   .VAR  Version    = MUSIC_EXAMPLE_VERSION;
   .VAR  sys_mode   = $M.SUBWOOFER.SYSMODE.BLUETOOTH;
   .VAR  reinit     = $music_example.REINITIALIZE;
   .VAR  num_modes  = 4; // TODO: verify this
   .VAR  link_type;
   .VAR $subwoofer.packet_fail_counter = 0;
   .VAR output_type = 0;  // TODO: set this at run-time.

// SPI System Control
.BLOCK SpiSysControl;
   // Bit-wise flag for tuning control
   .VAR  SysControl = 0;
   // Override for DAC gain
   .VAR  OvrDACgain = 9;
   .VAR  OvrCallState = 0;
   .VAR  OvrMode    = 0;
.ENDBLOCK;

   .VAR  CurDacL            = 11;
   .VAR  CurDacR            = 11;

.BLOCK Statistics;
   .VAR  CurMode            = 0;
   .VAR  PeakMipsFunc       = 0;
   .VAR  PeakMipsDecoder    = 0;
.ENDBLOCK;

.ENDMODULE;
