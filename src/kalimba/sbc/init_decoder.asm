// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBCDEC_INIT_DECODER_INCLUDED
#define SBCDEC_INIT_DECODER_INCLUDED

#include "stack.h"
#include "profiler.h"
#include "kalimba_standard_messages.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.init_decoder
//
// DESCRIPTION:
//    Initialise variables for sbc decoding. This is the initialisation function
//    to call when using dynamic external tables.
//
// INPUTS:
//    - r5 = pointer to decoder structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-r3, r10, DoLoop, I0
//
// *****************************************************************************
.MODULE $M.sbcdec.init_decoder;
   .CODESEGMENT SBCDEC_INIT_DECODER_PM;
   .DATASEGMENT DM;

   $sbcdec.init_decoder:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.INIT_DECODER_ASM.INIT_DECODER.PATCH_ID_0, r1)
#endif

   // -- reset decoder variables --
   call $sbcdec.reset_decoder;

   call $sbcdec.init_tables;

   // pop rLink from stack
   jump $pop_rLink_and_rts;


.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $sbcdec.deinit_decoder
//
// DESCRIPTION:
//    It is kept for consistency in terms of lifecycle functions. Functionality
//    needed in deinit stage can be added here. 
//    This function's static variant (deinit_static_decoder) is the one where
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
.MODULE $M.sbcdec.deinit_decoder;
   .CODESEGMENT SBCDEC_DEINIT_DECODER_PM;
   .DATASEGMENT DM;

   $sbcdec.deinit_decoder:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.INIT_DECODER_ASM.DEINIT_DECODER.PATCH_ID_0, r3)
#endif

   rts;

.ENDMODULE;
#endif
#endif
