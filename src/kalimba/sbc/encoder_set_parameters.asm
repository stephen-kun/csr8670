// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBCENC_ENCODE_SET_PARAMETERS_INCLUDED
#define SBCENC_ENCODE_SET_PARAMETERS_INCLUDED

#include "core_library.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcenc.encoder_set_parameters
//
// DESCRIPTION:
//    Set parameters for Encoder
//
// INPUTS:
//    - R9 = data object pointer
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1
//
// *****************************************************************************
.MODULE $M.sbcenc.encoder_set_parameters;
   .CODESEGMENT SBCENC_ENCODER_SET_PARAMETERS_PM;
   .DATASEGMENT DM;

   $sbcenc.encoder_set_parameters:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.ENCODER_SET_PARAMETERS_ASM.ENCODER_SET_PARAMETERS.PATCH_ID_0, r1)
#endif

   // block interrupts
   call $block_interrupts;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_NROF_SUBBANDS_FIELD];
   M[r9 + $sbc.mem.NROF_SUBBANDS_FIELD] = r0;

   r0 = M[r9 + $sbc.mem.ENC_SETTING_FORCE_WORD_ALIGN_FIELD];
   M[r9 + $sbc.mem.FORCE_WORD_ALIGN_FIELD] = r0;

   r0 = M[r9 + $sbc.mem.ENC_SETTING_NROF_BLOCKS_FIELD];
   M[r9 + $sbc.mem.NROF_BLOCKS_FIELD] = r0;

   r0 = M[r9 + $sbc.mem.ENC_SETTING_SAMPLING_FREQ_FIELD];
   M[r9 + $sbc.mem.SAMPLING_FREQ_FIELD] = r0;

   r0 = M[r9 + $sbc.mem.ENC_SETTING_CHANNEL_MODE_FIELD];
   M[r9 + $sbc.mem.CHANNEL_MODE_FIELD] = r0;




   r1 = 1;
   Null = r0 - $sbc.MONO;
   if NZ r1 = r1 + r1;

   M[r9 + $sbc.mem.NROF_CHANNELS_FIELD] = r1;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_ALLOCATION_METHOD_FIELD];
   M[r9 + $sbc.mem.ALLOCATION_METHOD_FIELD] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_BITPOOL_FIELD];
   M[r9 + $sbc.mem.BITPOOL_FIELD] = r0;



   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
#endif
