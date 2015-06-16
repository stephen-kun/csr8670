// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCDEC_RESET_DECODER_INCLUDED
#define SBCDEC_RESET_DECODER_INCLUDED

#include "core_library.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.reset_decoder
//
// DESCRIPTION:
//    Reset variables for sbc decoding
//
// INPUTS:
//    - r5 = pointer to decoder data structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r10, DoLoop, I1
//
// *****************************************************************************
.MODULE $M.sbcdec.reset_decoder;
   .CODESEGMENT SBCDEC_RESET_DECODER_PM;
   .DATASEGMENT DM;

   $sbcdec.reset_decoder:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.RESET_DECODER_ASM.RESET_DECODER.PATCH_ID_0, r1)
   pop r1;
#endif

   r0 = 16;

   // -- Load memory structure pointer
   // This pointer should have been initialised externally
   r9 = M[r5 + $codec.DECODER_DATA_OBJECT_FIELD];

   M[r9 + $sbc.mem.GET_BITPOS_FIELD] = r0;


   // clear the filter buffers
   call $sbcdec.silence_decoder;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif

