// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#include "subwoofer.h"
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
   r4 = $M.SUBWOOFER.PARAMETERS.STRUCT_SIZE;
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
   r3 = $SUBWOOFER_SYSID;
   r5 = M[$music_example.Version];
   r6 = 48000;
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
   // push rLink onto stack
   $push_rLink_macro;

   r2 = $music_example.VMMSG.CODEC;
   r3 = M[$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_ADC_GAIN];
   r4 = M[$M.system_config.data.CurParams + $M.SUBWOOFER.PARAMETERS.OFFSET_DAC_GAIN];
   call $message.send_short;

   r8 = 1;
   M[$music_example.reinit] = r8;
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

.MODULE $M.music_example.GetControl;

   .CODESEGMENT MUSIC_EXAMPLE_SPI_GETCONTROL_PM;

func:
   // push rLink onto stack
   $push_rLink_macro;

#if 0
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


   r0 = M[$music_example.SysControl];
   NULL = r0 AND $M.SUBWOOFER.CONTROL.DAC_OVERRIDE;
   if Z jump dontupdateDAC;
   r2 = M[$music_example.OvrDACgain];
   if NEG jump dontupdateDAC;
   r3 = r2 AND 0xf;
   M[$music_example.CurDacL] = r3;
   r2 = r2 LSHIFT -8;
   r4 = r2 AND 0xf;
   M[$music_example.CurDacR] = r4;

   r2 = $music_example.VMMSG.CODEC;
   call $message.send_short;
dontupdateDAC:
   r8 = 0;
#endif

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
   r10 = $M.SUBWOOFER.STATUS.BLOCK_SIZE;
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
    M[$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
    M[$M.system_config.data.dac_l_pk_dtct   + $M.audio_proc.peak_monitor.PEAK_LEVEL]=Null;
   rts;
.ENDMODULE;

