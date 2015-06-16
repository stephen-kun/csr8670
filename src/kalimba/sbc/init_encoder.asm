// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBCENC_INIT_ENCODER_INCLUDED
#define SBCENC_INIT_ENCODER_INCLUDED

#include "stack.h"
#include "profiler.h"
#include "kalimba_standard_messages.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcenc.init_encoder
//
// DESCRIPTION:
//    Initialise variables for sbc encoding. This is the initialisation function
//    to call when using dynamic external tables.
//
// INPUTS:
//    - r5 = pointer to encoder structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r3, r10, DoLoop, I0
//
// *****************************************************************************
.MODULE $M.sbcenc.init_encoder;
   .CODESEGMENT SBCENC_INIT_ENCODER_PM;
   .DATASEGMENT DM;

   $sbcenc.init_encoder:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.INIT_ENCODER_ASM.INIT_ENCODER.PATCH_ID_0, r1)
#endif

   // -- initialise encoder variables --
   call $sbcenc.reset_encoder;

   call $sbcenc.init_tables;

   // pop rLink from stack
   jump $pop_rLink_and_rts;



.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $sbcenc.deinit_encoder
//
// DESCRIPTION:
//    It is kept for consistency in terms of lifecycle functions. Functionality
//    needed in deinit stage can be added here. 
//    This function's static variant (deinit_static_encoder) is the one where
//    message handlers are removed.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0-r3
//
// *****************************************************************************
.MODULE $M.sbcenc.deinit_encoder;
   .CODESEGMENT SBCENC_DEINIT_ENCODER_PM;
   .DATASEGMENT DM;

   $sbcenc.deinit_encoder:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.INIT_ENCODER_ASM.DEINIT_ENCODER.PATCH_ID_0, r3)
#endif

   rts;

.ENDMODULE;
#endif
#endif
