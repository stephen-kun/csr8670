// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#include "frame_sync_library.h"

.MODULE $M.framesynclib;
   .DATASEGMENT DM;
   .VAR Version = $FRAMESYNCLIB_VERSION;
.ENDMODULE;

#ifndef USES_FRAMESYNCTEST

#include "frame_process.asm"
#include "frame_sync_utils.asm"
#include "usbio.asm"
#include "sco_decode.asm"
#include "frame_sync_sidetone_mix_operator.asm"
#include "frame_sync_dac_sync.asm"
#include "frame_sync_sco_copy_operator.asm"
#include "frame_sync_sidetone_mix_operator.asm"
#include "frame_sync_aux_mix_operator.asm"
#include "frame_sync_sidetone_filter_operator.asm"
#include "frame_sync_buffer.asm"
#include "frame_sync_rate_detect.asm"
#include "frame_sync_hw_warp_operator.asm"

#endif

