// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    FastStream Library
//
// DESCRIPTION:
//    This library provides an API for configuring codecs to make them suitable
//    for FastStream applications. Functions are passed to the codec as a parameter
//    in codec structure
//
//
// *****************************************************************************

#include "stack.h"
#include "faststream.h"

// **********************************************************************************
// NAME:
//    $faststream.sbcenc_post_func
//
// DESCRIPTION:
//    This function which is called by sbc encoder right after encoding a frame
//    and before setting the final write address, makes sure that the
//    encoded frame has an even number of bytes
//INPUTS:
//    - I0 = buffer pointer to write words to
//    - L0 length of the buffer
//    - R9 = encoder data object pointer
// OUTPUTS:
//    - I0 = buffer pointer to write words to (updated)
//
//  TRASHED REGISTERS:
//    - r0-r4
//************************************************************************************
.MODULE $M.faststream.sbcenc_post_func;
.CODESEGMENT FASTSTREAM_SBCENC_POST_FUNC_PM;

$faststream.sbcenc_post_func:
   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($faststream.FASTSTREAM_ASM.SBCENC_POST_FUNC.PATCH_ID_0, r1)
#endif

   // it used to load again r9 from SBC lib memory_pointer
   r0 = M[r9 + $sbc.mem.PUT_BITPOS_FIELD];

   // calculate number of bits should be padded to
   // make the frame length even
   r0 = r0 AND 15;
   r1 = 0;
   call $sbcenc.putbits;

 jump $pop_rLink_and_rts;

.ENDMODULE;
