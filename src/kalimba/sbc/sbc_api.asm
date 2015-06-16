// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBC_API_INCLUDED
#define SBC_API_INCLUDED

#include "sbc.h"

.MODULE $M.sbcdec.get_sampling_frequency;
   .CODESEGMENT SBCDEC_GET_SAMPLING_FREQUENCY_PM;
   .DATASEGMENT DM;
    $sbcdec.get_sampling_frequency:
     .VAR sampling_freq_hz[4] = 16000, 32000, 44100, 48000;

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.SBC_API_ASM.GET_SAMPLING_FREQUENCY.PATCH_ID_0, r1)
   pop r1;
#endif


      r0 = M[r9 + $sbc.mem.BITPOOL_FIELD];
      if Z rts;
      r0 = M[r9 + $sbc.mem.SAMPLING_FREQ_FIELD];

      r0 = M[r0 + sampling_freq_hz];

	  // OUTPUTs:
//      r0 - sample rate [0=16000, 1=32000, 2=44100, 3=48000]
//      r1 - Number of Channels (1 or 2)
    $sbcdec.GetInfo:
#ifdef SBC_USE_EXTERNAL_MEMORY
      r9 = M[$sbc.memory_pointer];
      r0 = M[r9 + $sbc.mem.BITPOOL_FIELD];
      if Z rts;
      r0 = M[r9 + $sbc.mem.SAMPLING_FREQ_FIELD];
      r1 = M[r9 + $sbc.mem.NROF_CHANNELS_FIELD];
#else
      r0 = M[$sbc.bitpool];
      if Z rts;
      r0 = M[$sbc.sampling_freq];
      r1 = M[$sbc.nrof_channels];
#endif
      rts;
    
      rts;
.ENDMODULE;

#endif
#endif
