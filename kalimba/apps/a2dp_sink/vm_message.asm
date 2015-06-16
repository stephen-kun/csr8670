// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: 1905219 $  $DateTime: 2014/05/27 11:22:10 $
// *****************************************************************************


#include "music_example.h"
#include "stack.h"
#include "pskey.h"
#include "message.h"
#include "cbops_library.h"

// VM Message Handlers
.MODULE $M.music_example_message;
   .DATASEGMENT DM;
   .VAR set_plugin_message_struc[$message.STRUC_SIZE];
   .VAR set_mode_message_struc[$message.STRUC_SIZE];
   .VAR volume_message_struc[$message.STRUC_SIZE];
   .VAR set_param_message_struc[$message.STRUC_SIZE];
   .VAR set_config_message_struc[$message.STRUC_SIZE];
   .VAR ping_message_struc[$message.STRUC_SIZE];
   .VAR get_param_message_struc[$message.STRUC_SIZE];
   .VAR load_params_message_struc[$message.STRUC_SIZE];
#if defined(APTX_ENABLE) || defined(APTX_ACL_SPRINT_ENABLE)
   .VAR security_message_struc[$message.STRUC_SIZE];
#endif
   .VAR ps_key_struc[$pskey.STRUC_SIZE];
    .var signal_detect_message_struct[$message.STRUC_SIZE];
    .var soft_mute_message_struct[$message.STRUC_SIZE];
    .var set_user_eq_param_message_struct[$message.STRUC_SIZE];
    .var get_user_eq_param_message_struct[$message.STRUC_SIZE];
    .var set_user_eq_group_param_message_struct[$message.STRUC_SIZE];
    .var get_user_eq_group_param_message_struct[$message.STRUC_SIZE];
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.music_example_message.SetPlugin
//
// FUNCTION
//    $M.music_example_message.SetPlugin.func
//
// DESCRIPTION:
//    Handle the set plugin VM message
//    (this sets the connection type)
//
// INPUTS:
//    r1 = connection type:
//       SBC_DECODER        = 1
//       MP3_DECODER        = 2
//       AAC_DECODER        = 3
//       FASTSTREAM_SINK    = 4
//       USB_DECODER        = 5
//       APTX_DECODER       = 6
//       ANALOGUE_DECODER   = 7
//       APTX_SPRINT_DECODER = 8
//       SPDIF_DECODER      = 9
// OUTPUTS:
//    none
//
// TRASHES: r0
//
// *****************************************************************************
.MODULE $M.music_example_message.SetPlugin;

   .CODESEGMENT   PM;

func:

   // Allow only the first message ($app_config.io is initialised to -1)
   null = M[$app_config.io];
   if POS rts;

   // Set the plugin type
   M[$app_config.io] = r1;
 
     // Set up the codec_type and codec_config for the music manager
#ifdef USB_ENABLE
   null = r1 - $USB_IO;
   if NZ jump skip_usb;

      // Set the codec type to USB
      r0 = $music_example.USB_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.USB_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_usb:
#endif

#ifdef ANALOGUE_ENABLE
   null = r1 - $ANALOGUE_IO;
   if NZ jump skip_analogue;

      // Set the codec type to analogue
      r0 = $music_example.ANALOGUE_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.ANALOGUE_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_analogue:
#endif


#ifdef SBC_ENABLE
   null = r1 - $SBC_IO;
   if NZ jump skip_sbc;

      // Set the codec type to SBC
      r0 = $music_example.SBC_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.SBC_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_sbc:
#endif

#ifdef MP3_ENABLE
   null = r1 - $MP3_IO;
   if NZ jump skip_mp3;

      // Set the codec type to MP3
      r0 = $music_example.MP3_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.MP3_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_mp3:
#endif

#ifdef FASTSTREAM_ENABLE
   null = r1 - $FASTSTREAM_IO;
   if NZ jump skip_faststream;

      // Set the codec type to FASTSTREAM
      r0 = $music_example.FASTSTREAM_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.FASTSTREAM_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_faststream:
#endif

#ifdef APTX_ENABLE
   null = r1 - $APTX_IO;
   if NZ jump skip_aptx;

      // Set the codec type to APTX
      r0 = $music_example.APTX_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.APTX_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_aptx:
#endif

#ifdef APTX_ACL_SPRINT_ENABLE
   null = r1 - $APTX_ACL_SPRINT_IO;
   if NZ jump skip_aptx_acl_sprint;

      // Set the codec type to APTX ACL SPRINT
      r0 = $music_example.APTX_ACL_SPRINT_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.APTX_ACL_SPRINT_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_aptx_acl_sprint:
#endif

#ifdef AAC_ENABLE
   null = r1 - $AAC_IO;
   if NZ jump skip_aac;

      // Set the codec type to AAC
      r0 = $music_example.AAC_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.AAC_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_aac:
#endif

#ifdef SPDIF_ENABLE
   null = r1 - $SPDIF_IO;
   if NZ jump skip_spdif;

      // Set the codec type to SPDIF
      r0 = $music_example.SPDIF_CODEC_TYPE;
      M[$codec_type] = r0;

      // Set the codec config
      r0 = $music_example.SPDIF_CODEC_CONFIG;
      M[$codec_config] = r0;

      jump exit;

   skip_spdif:
#endif

   // Unknown codec
   jump $error;

   exit:

   rts;
.ENDMODULE;

// *****************************************************************************
// DESCRIPTION: $MsgMusicSetMode
//       handle mode change
//  r1 = processing mode
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
      r4 = $M.MUSIC_MANAGER.CONFIG.USER_EQ_SELECT;
      
      // get number of EQ banks in use
      r5 = M[&$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS];
      r5 = r5 and r4;
      
      // get the current EQ bank and advance to next
      r0 = M[&$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG];
      r6 = r0 AND r4;
      r6 = r6 + 1;
      
      // use specified index if r2==2
      Null = r2 - 2;
      if Z r6 = r3;

      // If EQFLAT bit is one it means a flat curve has been added to the system.
      // The flat curve is used when bank==0;
      // If EQFLAT bit is zero AND bank==0, bank must be forced to one.
      r8 = $M.MUSIC_MANAGER.CONFIG.EQFLAT;
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
      M[&$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG] = r6;
      
      // User has requested a new EQ bank, but shouldn't need to call
      // coefficient calculation routine here as "reinit" is requested.
      
   do_not_advance_to_next_eq_bank:

   // ensure mode is valid
   r3 = $M.MUSIC_MANAGER.SYSMODE.MAX_MODES;
   Null = r3 - r1;
   if NEG r1 = r3;
   r3 = $M.MUSIC_MANAGER.SYSMODE.STANDBY;
   Null = r3 - r1;
   if POS r1 = r3;
   // save mode
   M[$music_example.sys_mode] = r1;
   // Re-init because mode or EQ setting has changed
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
   Null = r1 - $M.MUSIC_MANAGER.PARAMETERS.STRUCT_SIZE;
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
      r8 = $M.MUSIC_MANAGER.SYSMODE.STANDBY;
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
   Null = r1 - $M.MUSIC_MANAGER.PARAMETERS.STRUCT_SIZE;
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
//  r3 = message pay load
//     word0 = sytem volume index
//     word1 = master_volume_dB * 60
//     word2 = tone_volume_dB * 60
//     word3 = left_trim_volume_dB * 60
//     word4 = right_trim_volume_dB * 60
//     
// *****************************************************************************
.MODULE $M.music_example_message.Volume;

  .DATASEGMENT DM;

.CODESEGMENT   MUSIC_EXAMPLE_VM_VOLUME_PM;

// ---------------------------------------
// vmdB2vol:
//    helper function to convert 
//    vm volumes(dB/60.) to suitable
//    linear format for DSP (Q5.19)
//    
//    input r0 = vm vol dB
//    
//    output r0 = kal vol linear
// ---------------------------------------
vmdB2vol:
   // convert vmdB to log2 format
   r1 = 0.4215663554485;
   rMAC = r0 * 181 (int);
   rMAC = rMAC + r0 * r1;
   // less 24dB for Q5.19 format
   r0 = rMAC - (1<<18);
   if POS r0 = 0;
   // r0 = log2(volume/16.0)
   jump $math.pow2_taylor;
// ------------------------------------------
// update_volumes:
//    update the system when receiving
//    new volumes, it also sends the
//    system volume to vm
//   inputs:
//      r1 = system volume index
//      r2 = master volume (db/60)
//      r3 = tone volume (dB/60)
//      r4 = left trim volume (db/60)
//      r5 = right trim volume (db/60)
//    output: None  
// ------------------------------------------
update_volumes:

   // push rLink onto stack
   $push_rLink_macro;

   // update system volume
   r1 = r1 AND 0xF;
   M[$music_example.SystemVolume] = r1;

   // update master volume
   Null = r2;
   if POS r2 = 0;
   M[$music_example.MasterVolume] = r2;

   // update tone volume
   Null = r3;
   if POS r3 = 0;
   M[$music_example.ToneVolume] = r3;

   // update left trim volume
   r0 = r4 - $music_example.MAX_VM_TRIM_VOLUME_dB;
   if POS r4 = r4 - r0;
   r0 = r4 - $music_example.MIN_VM_TRIM_VOLUME_dB;
   if NEG r4 = r4 - r0;
   M[$music_example.LeftTrimVolume] = r4;

   // right trim volume
   r0 = r5 - $music_example.MAX_VM_TRIM_VOLUME_dB;
   if POS r5 = r5 - r0;
   r0 = r4 - $music_example.MIN_VM_TRIM_VOLUME_dB;
   if NEG r5 = r5 - r0;
   M[$music_example.RightTrimVolume] = r5;

   // convert master volume to linear
   r0 = r2;
   call vmdB2vol;
   r0 = r0 ASHIFT 2; // compensation for headroom
   M[$M.system_config.data.stereo_volume_and_limit_obj + $volume_and_limit.MASTER_VOLUME_FIELD] = r0;
   M[$M.system_config.data.mono_volume_and_limit_obj + $volume_and_limit.MASTER_VOLUME_FIELD] = r0;

   // convert tone volume to linear
   r0 = M[$music_example.ToneVolume];
   call vmdB2vol;
   r3 = r0 ASHIFT 3;  // 4-bit up for converting Q5.19 to Q1.23, 1 down for mixing
   M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD] = r3;
   M[$audio_out_tone_upsample_mono_mix.param + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD] = r3;

   // convert left trim to linear
   r0 = M[$music_example.LeftTrimVolume];
   call vmdB2vol;
   M[$M.system_config.data.left_channel_vol_struc + $volume_and_limit.channel.TRIM_VOLUME_FIELD] = r0;

   // convert right trim to linear
   r0 = M[$music_example.RightTrimVolume];
   call vmdB2vol;
   M[$M.system_config.data.right_channel_vol_struc + $volume_and_limit.channel.TRIM_VOLUME_FIELD] = r0;

   // VM expects L & R music gains to be sent back
   r4 = M[$music_example.SystemVolume];
   r3 = r4;
   r2 = $music_example.VMMSG.CODEC;
   call $message.send_short;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

func:

   // push rLink onto stack
   $push_rLink_macro;
#ifdef TWS_ENABLE
   r0 = M[$tws.local_mute];
   if Z jump skip_volume_save;

   r2 = length($tws.local_saved_volume_struc);
   r1 = &$tws.local_saved_volume_struc; 
   call $tws.copy_array;  
   jump volume_msg_done;
   skip_volume_save: 
#endif
   // get system volume
   r1 = M[r3 + 0];
   // get master volume
   r2 = M[r3 + 1];
   // get left trim volume
   r4 = M[r3 + 3];
   // right trim volume
   r5 = M[r3 + 4];
   // get tone volume
   r3 = M[r3 + 2];
   // update internal volumes
   call update_volumes; 

volume_msg_done:
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
   .VAR Pskey_fetch_flg = 1;
   .VAR Last_PsKey;

func:
   $push_rLink_macro;
   // Set Mode to standby
   r8 = $M.MUSIC_MANAGER.SYSMODE.STANDBY;
   M[$music_example.sys_mode] = r8;
   push r1; // save key
   // Copy default parameters into current parameters
   call $M.music_example.load_default_params.func;
   // Save for SPI Status
   M[paramoffset] = 0; // needed if loadparams is called more than once
   pop r2;
   M[Last_PsKey] = r2;
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

   // copy codec config word to current config word
   r0 = M[$codec_config];
   r0 = M[&$M.system_config.data.CurParams + r0];

   // Set the current codec config word
   M[&$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG] = r0;

   call $M.music_example.ReInit.func;

   // Tell VM is can send other messages
   r2 = $music_example.VMMSG.PARAMS_LOADED;
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
   if NZ jump No_Retry;				
   //Retry requesting for the PSKEY once.
   r0 = M[$M.music_example.LoadParams.Pskey_fetch_flg];  //If Z we have retried once already
   if Z jump No_2nd_Retry;
   M[$M.music_example.LoadParams.Pskey_fetch_flg] = 0;
   r2 = M[$M.music_example.LoadParams.Last_PsKey];
   jump $M.music_example.LoadParams.TestPsKey;
No_2nd_Retry:
   //Reset flag for next time and keep the default parameters
   r0 = 1;
   M[$M.music_example.LoadParams.Pskey_fetch_flg] = r0;
   jump $M.music_example.LoadParams.done;
No_Retry:
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

#ifdef APTX_ENABLE
// *****************************************************************************
// DESCRIPTION: $AptxSecurityStatus
// r1 = PsKey Address containing apt-X Security Status
// *****************************************************************************
.MODULE $M.music_example.AptxSecurityStatus;

   .CODESEGMENT PM;

func:
   $push_rLink_macro;

   // Security status is in r1;
   M[$aptx_security_status] = r1;

   call $aptx.decoder_version;

   M[$aptx_decoder_version] = r1;

   jump $pop_rLink_and_rts;
.ENDMODULE;


#elif defined APTX_ACL_SPRINT_ENABLE
// *****************************************************************************
// DESCRIPTION: $AptxSecurityStatus
// r1 = PsKey Address containing apt-X Security Status
// *****************************************************************************
.MODULE $M.music_example.AptxSecurityStatus;

   .CODESEGMENT PM;

func:
   $push_rLink_macro;

   // Security status is in r1;
   M[$aptx_security_status] = r1;

  call $aptx_sprint.decoder_version;


   M[$aptx_decoder_version] = r1;

   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif



// *****************************************************************************
// DESCRIPTION: $SetConfig
// *****************************************************************************
// Set and return configuration word of music manager
// - Config word enables or bypasses the various audio processing modules
// - 24 bit config word is split into two parts.
// - Most significant 8 bits and Least significant 16 bits
// *****************************************************************************
// on entry r1 = Mask MSW (8 bits)
//          r2 = Mask LSW (16 bits)
//          r3 = Data MSW (8 bits)
//          r4 = Data LSW (8 bits)
// *****************************************************************************
// Return Param 0 = Data MSW (8 bits)
//              1 = Data LSW (16 bits)
// *****************************************************************************

.MODULE $M.music_example_message.SetConfig ;

   .CODESEGMENT PM ;

func:

    $push_rLink_macro ;

    // reconstruct config mask
    r2 = r2 and 0xffff ;
    r1 = r1 lshift 16 ;
    r1 = r1 or r2 ;
    // reconstruct data word
    r4 = r4 and 0xffff ;
    r3 = r3 lshift 16;
    r3 = r3 or r4 ;
    
    r0 = M[&$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG] ;
    
    // modify code word ( (data & mask) ^ (configWord & !mask) )
    r3 = r3 and r1 ;
    r1 = r1 xor 0xfffff ;
    r0 = r0 and r1 ;
    r0 = r0 or r3 ;     
    
    M[&$M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG] = r0 ;

    // new config word into MSW and LSW and send back to VM    
    r2 = $music_example.VMMSG.SETCONFIG_RESP ;
    r3 = r0 lshift -16 ;
    r4 = r0 and 0xffff ;
    call $message.send_short ;
    
    // Re-init because has changed
    r1 = 1;
    M[$music_example.reinit] = r1;
    
    jump $pop_rLink_and_rts ;

.ENDMODULE ;

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
    
    r1 = r1 lshift 8 ;
    r8 = &$signal_detect_op_coefs;
    call $M.cbops.signal_detect_op.message_handler.func;

    jump $pop_rLink_and_rts ;

.endmodule ;


//------------------------------------------------------------------------------
.module $M.music_example_message.SoftMute;
//------------------------------------------------------------------------------
// Receives paramters for soft mute
//------------------------------------------------------------------------------
// on entry r1 = mute control (0=unmute, 1=mute)
//               bit 0 = left/right mute control
//               bit 1 = subwoofer mute control
// *** NO CHECKING IS PERFORMED ON MESSAGE PARAMETERS ***
//------------------------------------------------------------------------------

    .datasegment dm ;
    .codesegment pm ;

func:

    $push_rLink_macro ;

    // take copy of r1 as it's destroyed
    r2 = r1;
    
    // left/right mute control
    r1 = r1 and 0x01;
    r8 = $audio_mute_op_stereo.param;
    call $M.cbops.soft_mute.message_handler.func;

    // subwoofer mute control
    r1 = r2 lshift -1;
    r1 = r1 and 0x01;
    r0 = 1;
    r1 = -r1;
    null = r1;
    if Z r1 = r0;
    m[$M.downsample_sub_to_1k2.mute_direction] = r1;

    jump $pop_rLink_and_rts ;

.endmodule ;


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
    r0 = r0 + ($M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        
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
    r0 = r0 + ($M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        
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
        r0 = r0 + ($M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
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
        r0 = r0 + ($M.system_config.data.CurParams + $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS);
        r0 = m[r0];         // r0 = paramter value
        m[i0,1] = r0;       // store parameter back into message to return to VM
    GetParamsLoop:
    
    r5 = r3;
    r4 = r2;
    r3 = $music_example.GAIAMSG.GET_USER_GROUP_PARAM_RESP;
    call $message.send_long;    

    jump $pop_rLink_and_rts ;

.endmodule ;


