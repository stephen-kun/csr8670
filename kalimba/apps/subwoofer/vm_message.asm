// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: 1905219 $  $DateTime: 2014/05/27 11:22:10 $
// *****************************************************************************


#include "subwoofer.h"
#include "stack.h"
#include "pskey.h"
#include "message.h"
#include "cbops_library.h"

// VM Message Handlers
.MODULE $M.music_example_message;
   .DATASEGMENT DM;
   .VAR set_mode_message_struc[$message.STRUC_SIZE];
   .VAR volume_message_struc[$message.STRUC_SIZE];
   .VAR set_param_message_struc[$message.STRUC_SIZE];
   .VAR ping_message_struc[$message.STRUC_SIZE];
   .VAR get_param_message_struc[$message.STRUC_SIZE];
   .VAR load_params_message_struc[$message.STRUC_SIZE];
   .VAR ps_key_struc[$pskey.STRUC_SIZE];
   .VAR signal_detect_message_struct[$message.STRUC_SIZE];
   .VAR soft_mute_message_struct[$message.STRUC_SIZE];
   .VAR set_dac_rate_from_vm[$message.STRUC_SIZE];
    .var set_user_eq_param_message_struct[$message.STRUC_SIZE];
    .var get_user_eq_param_message_struct[$message.STRUC_SIZE];
    .var set_user_eq_group_param_message_struct[$message.STRUC_SIZE];
    .var get_user_eq_group_param_message_struct[$message.STRUC_SIZE];
.ENDMODULE;

// *****************************************************************************
// DESCRIPTION: $MsgMusicSetMode
//       handle mode change
//  r1 = processing mode - Not used in Subwoofer application.  Mode is
//       auto set using input port.
//  r2 = eq bank state (TODO: to which modes does this apply?)
//       0 = do not advance to next EQ bank
//       1 = advance to next EQ bank
//       2 = use eq Bank that is specified in r3
//  r3 = eq bank (only used if r2 = 2)
// *****************************************************************************
.MODULE $M.music_example_message.SetMode;

   .CODESEGMENT   MUSIC_EXAMPLE_VM_SETMODE_PM;
func:
   Null = r2; /* TODO see if the plugin is doing this initially */
   if Z jump do_not_advance_to_next_eq_bank;
      r4 = $M.SUBWOOFER.CONFIG.USER_EQ_SELECT;
      
      // get number of EQ banks in use
      r5 = M[&$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS];
      r5 = r5 and r4;
      
      // get the current EQ bank and advance to next
      r0 = M[&$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_CONFIG];
      r6 = r0 AND r4;
      r6 = r6 + 1;

      // use specified index if r2==2
      Null = r2 - 2;
      if Z r6 = r3;

      // If EQFLAT bit is one it means a flat curve has been added to the system.
      // The flat curve is used when bank==0;
      // If EQFLAT bit is zero AND bank==0, bank must be forced to one.
      r8 = $M.SUBWOOFER.CONFIG.EQFLAT;
      r3 = 0;
      r7 = 1;
      Null = r0 AND r8;     // is zero if flat curve not allowed (i.e. Bank0 not allowed)
      if Z r3 = r7;
      NULL = r5 - r6;
      if LT r6 = r3;        // reset index to 0 or 1 depending on EQFLAT

      // If the VM sent r2=2 and r3=0, use Bank1 if a flat curve isn't included
      Null = r6 - 0;
      if Z r6 = r3;

      // update EQ bank bits of Music Manager Config Parameter
      r7 = 0xffffff XOR r4;
      r7 = r0 AND r7;
      r6 = r7 OR r6;
      M[&$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_CONFIG] = r6;
      
      // User has requested a new EQ bank, but shouldn't need to call
      // coefficient calculation routine here as "reinit" is requested.
      
   do_not_advance_to_next_eq_bank:

   // reinit since PEQ has changed.
   r1 = 1;
   M[$music_example.reinit] = r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// DESCRIPTION: $MsgMusicSetParameter
//       handle set parameter
//  r1 = Parameter ID
//  r2 = Parameter MSW
//  r3 = Parameter LSW
//  r4 = Status (NZ=done)
// *****************************************************************************
.MODULE $M.music_example_message.SetParam;

   .CODESEGMENT MUSIC_EXAMPLE_VM_SETPARAM_PM;

func:
   Null = r1;
   if NEG rts;
   Null = r1 - $M.SUBWOOFER.PARAMETERS.STRUCT_SIZE;
   if POS rts;
      // Save Parameter
      r3 = r3 AND 0xFFFF;
      r2 = r2 LSHIFT 16;
      r2 = r2 OR r3;
      M[$M.system_config.data.CurParams + r1] = r2;
      // Check status
      Null = Null + r4;
      if NZ jump $music_example_reinitialize;
      // Set Mode to standby
      r8 = $M.SUBWOOFER.SYSMODE.STANDBY;
      M[$music_example.sys_mode] = r8;
      rts;
.ENDMODULE;

// *****************************************************************************
// DESCRIPTION: Read Parameter
//       handle get parameter
// INPUTS:
//    r1 = Parameter ID
// Response
//    P0 = requested ID
//    P1 = returned ID, 0 if request was invalid
//    P2 = MSW
//    P3 = LSW
// *****************************************************************************
.MODULE $M.music_example_message.GetParam;

   .CODESEGMENT MUSIC_EXAMPLE_VM_GETPARAM_PM;

func:
   // Validate Request
   // P0
   r3 = r1;
   // P1
   r4 = r1;
   if NEG r4 = Null;
   Null = r1 - $M.SUBWOOFER.PARAMETERS.STRUCT_SIZE;
   if POS r4 = Null;
   r6 = M[$M.system_config.data.CurParams + r4];
   // MSW   : P2
   r5 = r6 LSHIFT -16;
   // LSW   : P3
   r6 = r6 AND 0xFFFF;
   // push rLink onto stack
   $push_rLink_macro;
   // Send GET RESPONSE Message
   r2 = $music_example.VMMSG.GETPARAM_RESP;
   call $message.send_short;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
   rts;
.ENDMODULE;

#if 0
// *****************************************************************************
// DESCRIPTION: $MsgCvcPing
//       Ping from VM - Verify Operation
// *****************************************************************************
.MODULE $M.music_example_message.Ping;

   .CODESEGMENT   MUSIC_EXAMPLE_VM_PING_PM;

func:
   // push rLink onto stack
   $push_rLink_macro;
   // Send PING Message
   r2 = $M.CVC.VMMSG.PINGRESP;
   r3 = M[$M.CVC_HEADSET.FrameCounter];
   call $message.send_short;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif
// *****************************************************************************
// DESCRIPTION: $MsgMusicExampleSetVolume
//       handle call state mode
//  r1 = swat_system_volume_db   Q7.1 range: 0 to 255 (255 means 127.5 dB)
//  r2 = swat_sub_trim_volume_db Q7.1 range: 0 to 255
//  r3 = local_volume_index      range: 0 to 50 (gets mapped to user defined dB gains)
//
//  Note: negative gains are applied.  i.e. 255 gets applied as -127.5 dB.
//  dB to linear conversion: 2^(dB_value *log2(10)/20) = linear_value
//  where log2(10)/20 ~= 0.166096
// *****************************************************************************
.MODULE $M.music_example_message.Volume;
   .DATASEGMENT   DM;
   .CODESEGMENT   MUSIC_EXAMPLE_VM_VOLUME_PM;

func:
   $push_rLink_macro;
   
// TODO: determine if this function is too heavy for a message interruption.

   // Limit Gains
   r5 = 255;
   NULL = r1 - r5;
   if POS r1 = r5;

   NULL = r2 - r5;
   if POS r2 = r5;

   // Limit ADC gain to be within table boundary
   r5 = M[$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_VOLUME_TABLE_SIZE];
   r5 = r5 - 1;
   NULL = r3 - r5;
   if POS r3 = r5;
   // Table is stored in reverse order
   r3 = r5 - r3;
   // Add 1 to help with indexing table values which are packed 3 in each 24-bit work
   r3 = r3 + 1;
   
   // Update UFE statistics.
   M[$M.system_config.data.swat_system_gain_db] = -r1; 
   M[$M.system_config.data.swat_trim_gain_db] = -r2;
   
   // Convert gains from dB to linear and apply negative gain for attenuation
   // Note $math.pow2_taylor doesn't trash r2 and r3.
   r1 = r1 ASHIFT 15; // Q7.16 to represent 0 through 96
   r0 = r1 * -0.1660964 (frac);
   call $math.pow2_taylor;
   r4 = NULL;
   NULL = r0 - 0x7fffff;
   if NZ jump set_swat_system_gain;
   // set true unity gain
   r4 = 1;
   r0 = 0.5;
set_swat_system_gain:
   M[$M.system_config.data.swat_system_gain_mantissa] = r0;
   M[$M.system_config.data.swat_system_gain_exponent] = r4;    

   r1 = r2 ASHIFT 15; // Q7.16 to represent 0 through 96
   r0 = r1 * -0.1660964 (frac);
   call $math.pow2_taylor;
   r4 = NULL;
   NULL = r0 - 0x7fffff;
   if NZ jump set_swat_trim_gain;
   // set true unity gain
   r4 = 1;
   r0 = 0.5;
set_swat_trim_gain:
   M[$M.system_config.data.swat_trim_gain_mantissa] = r0;
   M[$M.system_config.data.swat_trim_gain_exponent] = r4;    

   // Look up adc gain value  We're essentially making a byte pointer here.
   r1 = 3;
   rMAC = r3;
   rMAC = rMAC ASHIFT 0 (LO);      // integer divide requires this shift
   Div = rMAC/r1;
   r1 = DivRemainder;
   r6 = DivResult;                 // table index
   
   r0 = &$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_VOLUME_TABLE0;
   Null = r1 - Null;
   if NZ jump remainder_1;
   r6 = r6 - 1;   
   jump fetch_table_value;

remainder_1:
   Null = r1 - 1;
   if NZ jump remainder_2;
   r1 = -16;
   jump fetch_table_value;
   
remainder_2:
   r1 = -8;

fetch_table_value:
   r0 = M[r0 + r6];
   r0 = r0 LSHIFT r1;

   r3 = r0 AND 0xFF;
   M[$M.system_config.data.adc_gain_db] = -r3;

   r1 = r3 ASHIFT 15; // Q7.16 to represent 0 through 96
   r0 = r1 * -0.1660964 (frac);
   call $math.pow2_taylor;
   r4 = NULL;
   NULL = r0 - 0x7fffff;
   if NZ jump set_adc_gain;
   // set true unity gain
   r4 = 1;
   r0 = 0.5;
set_adc_gain:
   M[$M.system_config.data.adc_gain_mantissa] = r0;
   M[$M.system_config.data.adc_gain_exponent] = r4;
   
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// DESCRIPTION: $LoadParams
// r1 = PsKey Address containing Music Example parameters
// *****************************************************************************
.MODULE $M.music_example.LoadParams;

   .CODESEGMENT MUSIC_EXAMPLE_VM_LOADPARAMS_PM;
   .DATASEGMENT DM;
   .VAR paramoffset = 0;

func:
   $push_rLink_macro;
   // Set Mode to standby
   r8 = $M.SUBWOOFER.SYSMODE.STANDBY;
   M[$music_example.sys_mode] = r8;
   push r1; // save key
   // Copy default parameters into current parameters
   call $M.music_example.load_default_params.func;
   // Save for SPI Status
   M[paramoffset] = 0; // needed if loadparams is called more than once
   pop r2;

TestPsKey:
   if Z jump done;
      // r2 = key;
      //  &$friendly_name_pskey_struc;
      r1 = &$M.music_example_message.ps_key_struc;
      // &$DEVICE_NAME_pskey_handler;
      r3 = &$M.music_example.PsKeyReadHandler.func;
      call $pskey.read_key;
      jump $pop_rLink_and_rts;
done:



   r8 = 1;
   M[$music_example.reinit] = r8;

   // Tell VM it can send other messages
   r2 = $music_example.VMMSG.PARAMS_LOADED;
   r3 = M[$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_VOLUME_TABLE_SIZE];
   call $message.send_short;

   r2 = $music_example.VMMSG.CODEC;
   r3 = M[$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_ADC_GAIN];
   r4 = M[$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_DAC_GAIN];
   call $message.send_short;
   
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// DESCRIPTION: $PsKeyReadHandler
//  INPUTS:
//    Standard (short) message mode:
//    r1 = Key ID
//    r2 = Buffer Length; $pskey.FAILED_READ_LENGTH on failure
//    r3 = Payload.  Key ID Plus data
// *****************************************************************************
.MODULE $M.music_example.PsKeyReadHandler;

   .CODESEGMENT MUSIC_EXAMPLE_PSKEYREADHANDLER_PM;

func:
   $push_rLink_macro;

   // error checking - check if read failed
   // if so, DSP default values will be used instead of PsKey values.
   Null = r2 - $pskey.FAILED_READ_LENGTH;
   if Z jump $M.music_example.LoadParams.done;
   // Adjust for Key Value in payload?
   I0 = r3 + 1;
   r10 = r2 - 1;
   // Clear sign bits
   // I2=copy of address
   I2 = I0;
   // r3=mask to clear sign extension
   r3 = 0x00ffff;
   do loop1;
      r0 = M[I2,0];
      r0 = r0 AND r3;
      M[I2,1] = r0;
loop1:
   r10 = 256;

   // End of buffer pointer (last valid location)
   I2 = I2 - 1;

   // error checking - make sure first value is the Pskey address.
   // if not, DSP default values will be used instead of PsKey values.
   r0 = M[I0,1];
   Null = r1 - r0;
   if NZ jump $M.music_example.LoadParams.done;

   // get next Pskey address
   // r5 = address of next PsKey
   r5 = M[I0,1];
   r0 = M[I0,1];
   // r4 = NumParams (last parameter + 1)
   r4 = r0 AND 0xff;
   if Z r4 = r10;
   // r0 = firstParam (zero-based index into
   //      paramBlock)
   r0 = r0 LSHIFT -8;

   // initial mask value
   r8 = Null;

start_loop:
      r8 = r8 LSHIFT -1;
      if NZ jump withinGroup;

      // Check for past end of buffer
      null = I2 - I0;
      if NEG jump endOfBuffer;

      // group
      r3 = M[I0,1];

      // mask value
      r8 = 0x8000;
      // used for odd variable
      r7 = Null;
withinGroup:
      Null = r3 AND r8;
      if Z jump dontOverwriteCurrentValue;
         // overwrite current parameter
         r7 = r7 XOR 0xffffff;
         if Z jump SomeWhere;
         // MSB for next two parameters
         r2 = M[I0,1];
         // MSB for param1
         r6 = r2 LSHIFT -8;
         jump SomeWhereElse;
SomeWhere:
         // MSB for param2
         r6 = r2 AND 0xff;
SomeWhereElse:
         // LSW
         r1 = M[I0,1];
         r6 = r6 LSHIFT 16;
         // Combine MSW and LSW
         r1 = r1 OR r6;
         r6 = r0 + M[$M.music_example.LoadParams.paramoffset];
         M[$M.system_config.data.CurParams + r6] = r1;
dontOverwriteCurrentValue:
      r0 = r0 + 1;
      Null = r0 - r4;
   if NEG jump start_loop;

endOfBuffer:
   // inc offset if lastkey=0
   r2 = M[$M.music_example.LoadParams.paramoffset];
   Null = r4 - r10;
   if Z r2 = r2 + r10;
   M[$M.music_example.LoadParams.paramoffset] = r2;
   // PS Key Being requested
   r2 = r5;
   jump $M.music_example.LoadParams.TestPsKey;

.ENDMODULE;


//------------------------------------------------------------------------------
.module $M.music_example_message.SignalDetect;
//------------------------------------------------------------------------------
// Receives paramters for standby detection
//------------------------------------------------------------------------------
// on entry r1 = threshold (16 bit fractional value - aligned to MSB in DSP)
//          r2 = trigger time in seconds (16 bit int)
// *** NO CHECKING IS PERFORMED ON MESSAGE PARAMETERS ***
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

// TODO: bring this back */
#if 0
    r1 = r1 lshift 8 ;
    r8 = &$signal_detect_op_coefs;
    call $M.cbops.signal_detect_op.message_handler.func;
#endif
    jump $pop_rLink_and_rts ;

.endmodule ;


//------------------------------------------------------------------------------
.module $M.music_example_message.SoftMute;
//------------------------------------------------------------------------------
// Receives paramters for soft mute
//------------------------------------------------------------------------------
// on entry r1 = mute direction
// *** NO CHECKING IS PERFORMED ON MESSAGE PARAMETERS ***
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

// TODO: bring this back
#if 0
    r1 = r1 lshift 8 ;
    r8 = $audio_mute_op_stereo.param;
    call $M.cbops.signal_detect_op.message_handler.func;
#endif
    jump $pop_rLink_and_rts ;

.endmodule ;


// *****************************************************************************
// MODULE:
//    set_dac_rate_from_vm
//
// DESCRIPTION: message handler for receiving DAC rate from VM
//
// INPUTS:
//  r1 = dac sampling rate/10 (e.g. 44100Hz is given by r1=4410)
// *****************************************************************************
.module $M.music_example_message.set_dac_rate;
   .CODESEGMENT PM;

func:

   // Mask sign extension
   r1 = r1 AND 0xffff;

   // Scale to get sampling rate in Hz
   r1 = r1 * 10 (int);
   
   // Store the parameters
   M[$sub_dac_sampling_rate] = r1;     // DAC sampling rate (e.g. 44100Hz is given by r1=44100)

   r0 = $M.SUBWOOFER.INPUT_TYPE.L2CAP;
   Null = r0 - M[$music_example.link_type];
   if NZ jump done;

   r3 = 3; // 48000 Hz pointer
   Null = r1 - 48000;
   if Z jump set_frame_period;
   r3 = 2; // 44100 Hz pointer  

set_frame_period:
   r0 = &$us_per_sample_sbc + r3;
   M[$output_buffers + 1] = r0;
   M[$output_port_and_delay_size + 1] = r0;
   M[$output_port_and_delay_size + 3] = r0;      

done:
   rts;
.ENDMODULE;



//------------------------------------------------------------------------------
.module $M.music_example_message.SetUserEqParamMsg;
//------------------------------------------------------------------------------
// receives user eq parameter update message.
//   If "update" field is non-zero, the coefficient calculation routine is run
//------------------------------------------------------------------------------
// Parameter is sent as a short message
//   <msgID> <Param ID> <value> <update> <>
//------------------------------------------------------------------------------
// On entry
//   r0 = message ID (ignored)
//   r1 = parameter ID
//   r2 = value
//   r3 = update
//   r4 = unused
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

    r0 = r1;                // r0 = paramID
    call $user_eq.calcParamAddrOffset;          // on exit, r0 = ParamAddrOffset
    r0 = r0 + ($M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        
    r2 = r2 and 0x00ffff;
    m[r0] = r2;
    
    // if update flag is zero then exit now and don't recalculate coefficients
    null = r3 - 0;
    if eq jump $pop_rLink_and_rts ;
    
    r0 = r1;
    r7 = &$M.system_config.data.UserEqInitTable;
    call $user_eq.calcBandCoefs;

    jump $pop_rLink_and_rts ;

.endmodule ;


//------------------------------------------------------------------------------
.module $M.music_example_message.GetUserEqParamMsg;
//------------------------------------------------------------------------------
// request user eq parameter message.
//   return message contains requested parameter
//------------------------------------------------------------------------------
// Parameter is sent as a short message
//   <msgID> <Param ID> <> <> <>
// Reply is sent as a short message
//   <msgID> <Param ID> <value> <> <>
//------------------------------------------------------------------------------
// On entry
//   r0 = message ID (ignored)
//   r1 = parameter ID
//   r2 = unused
//   r3 = unused
//   r4 = unused
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

    r3 = r1;          // word 1 of return message (parameter ID)

    r0 = r1;                // r0 = paramID
    call $user_eq.calcParamAddrOffset;          // on exit, r0 = ParamAddrOffset
    r0 = r0 + ($M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        
    r4 = m[r0];       // word 2 (value)
    r5 = 0;           // word 3
    r6 = 0;           // word 4
    r2 = $music_example.GAIAMSG.GET_USER_PARAM_RESP;
    call $message.send_short;

    jump $pop_rLink_and_rts ;

.endmodule ;


//------------------------------------------------------------------------------
.module $M.music_example_message.SetUserEqGroupParamMsg;
//------------------------------------------------------------------------------
// receives user eq group parameter update message.
//   If "update" field is non-zero, the coefficient calculation routine is run
//------------------------------------------------------------------------------
// Parameter is sent as a long message
//   <numParams> <Param-1> <value-1>...<Param-n> <value-n> <update>
//------------------------------------------------------------------------------
// On entry
//   r1 = message ID (ignored)
//   r2 = message length in words
//   r3 = message
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

    i0 = r3;                // i0 ptr to message
    r1 = m[i0,1];           // number of parameters to retrieve
    r10 = r1;
    do SetParamsLoop;
        r0 = m[i0,1];       // r0 = paramID
        call $user_eq.calcParamAddrOffset;          // on exit, r0 = ParamAddrOffset
        r0 = r0 + ($M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        r1 = m[i0,1];       // get value to store
        r1 = r1 and 0x00ffff;
        m[r0] = r1;         // store value
    SetParamsLoop:
    
    //// currently ignore update flag for group parameter message
    
    jump $pop_rLink_and_rts ;

.endmodule ;


//------------------------------------------------------------------------------
.module $M.music_example_message.GetUserEqGroupParamMsg;
//------------------------------------------------------------------------------
// request user eq group parameter message.
//   return LONG message contains requested parameters
//------------------------------------------------------------------------------
// Parameter is sent as a long message
//   <numParams> <Param-1> < 00000 >...<Param-n> < 00000 >
// Reply is sent as a long message
//   <numParams> <Param-1> <value-1>...<Param-n> <value-n>
//------------------------------------------------------------------------------
// On entry
//   r1 = message ID (ignored)
//   r2 = message length in words
//   r3 = message
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;
    
    i0 = r3;                // i0 ptr to message
    r1 = m[i0,1];           // number of parameters to retrieve
    r10 = r1;
    do GetParamsLoop;
        r0 = m[i0,1];               // r0 = paramID
        call $user_eq.calcParamAddrOffset;          // on exit, r0 = ParamAddrOffset
        r0 = r0 + ($M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        r0 = m[r0];         // r0 = paramter value
        m[i0,1] = r0;       // store parameter back into message to return to VM
    GetParamsLoop:
    
    r5 = r3;
    r4 = r2;
    r3 = $music_example.GAIAMSG.GET_USER_GROUP_PARAM_RESP;
    call $message.send_long;    

    jump $pop_rLink_and_rts ;

.endmodule ;


