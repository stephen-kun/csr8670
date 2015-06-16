// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1956147 $  $DateTime: 2014/08/05 16:39:07 $
// *****************************************************************************


#include "music_example.h"
#include "spi_comm_library.h"
#include "stack.h"
#include "cbops.h"
#include "audio_proc_library.h"


// SPI Message Handlers
.MODULE $M.music_example_spi;
   .DATASEGMENT DM;
   .VAR status_message_struc[$spi_comm.STRUC_SIZE];
   .VAR version_message_struc[$spi_comm.STRUC_SIZE];
   .VAR reinit_message_struc[$spi_comm.STRUC_SIZE];
   .VAR parameter_message_struc[$spi_comm.STRUC_SIZE];
   .VAR control_message_struc[$spi_comm.STRUC_SIZE];
#ifdef SPDIF_ENABLE
   .VAR spdif_config_message_struc[$spi_comm.STRUC_SIZE];
#endif   
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    message handler
//
// DESCRIPTION:
//    User registered message handler
//
// INPUTS:
//    r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************
.MODULE $M.music_example.GetParams;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_GETPARAMS_PM;

func:
   r3 = &$M.system_config.data.CurParams;
   r4 = $M.MUSIC_MANAGER.PARAMETERS.STRUCT_SIZE;
   r5 = &$M.system_config.data.DefaultParameters;
   M[r1] = r3;
   M[r1 + 1] = r4;
   M[r1 + 2] = r5;
   r8 = 3;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    message handler
//
// DESCRIPTION:
//    User registered message handler
//
// INPUTS:
//    r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************
.MODULE $M.music_example.GetVersion;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_GETVERSION_PM;

func:
   r3 = $MUSIC_MANAGER_SYSID;
   r5 = M[$music_example.Version];
   r6 = M[$current_codec_sampling_rate];
   // Make sure the order of arguments match the
   // SPI messaging document.
   M[r1] = r3;
   M[r1 + 1] = r5;
   M[r1 + 2] = r6;

   r8 = 3;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    message handler
//
// DESCRIPTION:
//    User registered message handler
//
// INPUTS:
//    r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************

.MODULE $M.music_example.ReInit;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_REINIT_PM;

func:
   r8 = 1;
   M[$music_example.reinit] = r8;
   r8 = 0;
   rts;
.ENDMODULE;
#ifdef SPDIF_ENABLE
// *****************************************************************************
// MODULE:
//    $M.music_example.GetSpdifConfig
//
// DESCRIPTION:
//    User registered message handler for SPDIF app configuration
//
// INPUTS:
//   r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************

.MODULE $M.music_example.GetSpdifConfig;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_GETCONTROL_PM;

func:
   // push rLink onto stack
   $push_rLink_macro;
   r2 = M[r1 + 1]; // spdif config word
   r3 = M[r1 + 2]; // AC-3 config word 1
   r1 = M[r1 + 0]; // AC-3 config word 2
   call $spdif_apply_realtime_config;
   
   r8 = 0;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
#endif
// *****************************************************************************
// MODULE:
//    message handler
//
// DESCRIPTION:
//    User registered message handler
//
// INPUTS:
//    r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************

.MODULE $M.music_example.GetControl;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_GETCONTROL_PM;

func:
   // push rLink onto stack
   $push_rLink_macro;

   // SysControl
   // OvrDACgain
   // OvrMode
   I4 = &$music_example.SpiSysControl;
   I0 = r1;
   r10 = LENGTH($music_example.SpiSysControl);
   do lp_copy_control;
      r0 = M[I0,1];
      M[I4,1] = r0;
lp_copy_control:

// Zero out right output cbuffer only if MONO mode is selected in Music Manager
   r4 = 1;
   M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD] = r4;
   r0 = M[$music_example.OvrMode];
   r0 = r0 + r0;
   // see if the new mode is Mono
   Null = M[r0 + $M.music_example_process.mono_mode_conversion_table+1];
   if NZ jump done_zero_right_cbuffer_output;
      // no tone mixing to the right channel
      M[$audio_out_tone_upsample_stereo_mix.param + $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD] = -r4;
      r3 = Null;

      // Zero out DC estimate on right channel dc_remove operator when switching into mono mode
      // in order to prevent the transient DC estimate from being written into the $dac_out_right
      // cbuffer. The transient DC estimate causes a buzz since the $dac_out_right cbuffer is
      // no longer updated but the data in this cbuffer is still fed to the DAC port.
      M[&$M.main.audio_out_dc_remove_op_right.param + $cbops.dc_remove.DC_ESTIMATE_FIELD] = r3;

      r10 = LENGTH($dac_out_right);
      I0 = &$dac_out_right;
      do clear_right_cbuffer_output;
        M[I0,1] = r3;
      clear_right_cbuffer_output:
   done_zero_right_cbuffer_output:

   r0 = M[$music_example.SysControl];
   NULL = r0 AND $M.MUSIC_MANAGER.CONTROL.DAC_OVERRIDE;
   if Z jump dontupdateDAC;
   r1 = M[$music_example.OvrMasterSystemVolume];
   // extract master volume
   r2 = r1 ASHIFT -4;
   // extract system volume
   r1 = r1 AND 0xF;
   // get tone volume
   r3 = M[$music_example.ToneVolume];
   r4 = M[$music_example.OvrTrimVolumes];
   // extract left trim volume
   r5 = r4 ASHIFT -12;
   // extract right trim volume
   r4 = r4 LSHIFT 12;
   r4 = r4 ASHIFT -12;
#ifdef TWS_ENABLE
   r0 = M[$relay.mode];
   null = r0 - $TWS_MASTER_MODE;
   if NZ jump no_sync;
   I0 = &$tws.message_volume_struc;
   M[I0,1] = r1;
   M[I0,1] = r2;
   M[I0,1] = r3;
   M[I0,1] = r4;
   M[I0,1] = r5;
   I0 = null;
   
   jump dontupdateDAC;
   no_sync:
   call $M.music_example_message.Volume.update_volumes;
#else
   call $M.music_example_message.Volume.update_volumes;
#endif
dontupdateDAC:
   r8 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    message handler
//
// DESCRIPTION:
//    User registered message handler
//
// INPUTS:
//    r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************
.MODULE $M.music_example.GetStatus;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_GETSTATUS_PM;

func:
   // Pointer to Payload
   I1 = r1;
   // Copy Status
   r10 = $M.MUSIC_MANAGER.STATUS.BLOCK_SIZE;
   // Payload Size
   r8 = r10;
   I4 = &$M.system_config.data.StatisticsPtrs;
   r1 = M[I4,1];
   do lp_copy_status;
      // Dereference Pointer
      r1 = M[r1];
      // Copy, Next POinter
      M[I1,1] = r1, r1 = M[I4,1];
      // Bug in BC3MM in index register feed forward
      nop;
lp_copy_status:
   // Clear Peak Statistics
   r10 = LENGTH($music_example.Statistics);
   I4 = &$music_example.Statistics;
   r2 = r2 XOR r2;
   do loop_clr_statistics;
      M[I4,1] = r2;
loop_clr_statistics:

    // Clear Peak Detection
    M[$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
    M[$M.system_config.data.pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
#ifdef SPDIF_ENABLE
    M[$M.system_config.data.pcmin_lfe_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
#endif
    M[$M.system_config.data.dac_l_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
    M[$M.system_config.data.dac_r_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
#ifdef SUB_ENABLE
    M[$M.system_config.data.sub_pk_dtct     + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
#endif

   rts;
.ENDMODULE;

