// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCENC_RESET_ENCODER_INCLUDED
#define SBCENC_RESET_ENCODER_INCLUDED

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcenc.reset_encoder
//
// DESCRIPTION:
//    Reset variables for sbc encoding
//
// INPUTS:
//    - r5 = pointer to encoder data structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r10, DoLoop, I0
//
// *****************************************************************************
.MODULE $M.sbcenc.reset_encoder;
   .CODESEGMENT SBCENC_RESET_ENCODER_PM;
   .DATASEGMENT DM;

   $sbcenc.reset_encoder:

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.RESET_ENCODER_ASM.RESET_ENCODER.PATCH_ID_0, r1)
   pop r1;
#endif


   // -- Load memory structure pointer
   // This pointer should have been initialised externally
   r9 = M[r5 + $codec.ENCODER_DATA_OBJECT_FIELD];


   // init X ptrs to the start of X
   r0 = M[r9 + $sbc.mem.ANALYSIS_XCH1_FIELD];
   M[r9 + $sbc.mem.ANALYSIS_XCH1PTR_FIELD] = r0;

   // init vector X ch 1 to zero
   I0 = r0;

   r10 = $sbcenc.ANALYSIS_BUFFER_LENGTH;
   r0 = 0;
   do asf_init_loop1;
      M[I0, 1] = r0;
   asf_init_loop1:

#ifndef SBC_WBS_ONLY
   // init vector X ch 2 to zero
   r0 = M[r9 + $sbc.mem.ANALYSIS_XCH2_FIELD];
   M[r9 + $sbc.mem.ANALYSIS_XCH2PTR_FIELD] = r0;

   I0 = r0;
   r10 = $sbcenc.ANALYSIS_BUFFER_LENGTH;
   r0 = 0;
   do asf_init_loop2;
      M[I0, 1] = r0;
   asf_init_loop2:
#endif
   rts;

.ENDMODULE;

#endif