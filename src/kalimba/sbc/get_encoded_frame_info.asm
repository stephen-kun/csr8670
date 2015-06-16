// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBCENC_GET_ENCODED_FRAME_INFO_INCLUDED
#define SBCENC_GET_ENCODED_FRAME_INFO_INCLUDED

#include "stack.h"
#include "codec_library.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcenc.get_encoded_frame_info
//
// DESCRIPTION:
//    Read information about an sbc frame by parsing the cbuffer
//
// INPUTS:
//    - r9 = data object pointer
//
// OUTPUTS:
//    - r0 - frame size in octets
//    - r1 - Number of samples per frame
//
// TRASHED REGISTERS:
//    assume everything
//
// NOTES:
//
//
//
// *****************************************************************************
.MODULE $M.sbcenc.get_encoded_frame_info;
   .CODESEGMENT SBCENC_GET_ENCODED_FRAME_INFO_PM;
   .DATASEGMENT DM;

   $sbcenc.get_encoded_frame_info:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.GET_ENCODED_FRAME_INFO_ASM.GET_ENCODED_FRAME_INFO.PATCH_ID_0, r1)
#endif

   // -- Setup encoder parameters --
   call $sbcenc.encoder_set_parameters;

   // Calculate the frame length
   call $sbc.calc_frame_length;

   r1 = M[r9 + $sbc.mem.NROF_BLOCKS_FIELD];
   r2 = M[r9 + $sbc.mem.NROF_SUBBANDS_FIELD];




   // Calculate number of samples per frame
   r1 = r1 * r2 (int);

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
#endif
