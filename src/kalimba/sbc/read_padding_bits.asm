// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBCDEC_READ_PADDING_BITS_INCLUDED
#define SBCDEC_READ_PADDING_BITS_INCLUDED

#include "stack.h"
#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.read_padding_bits
//
// DESCRIPTION:
//    Read padding bits
//
// INPUTS:
//    - I0 = buffer to read words from
//
// OUTPUTS:
//    - I0 = buffer to read words from (updated)
//
// TRASHED REGISTERS:
//    r0-r3
//
// NOTES:
//  Remove padding bits from frame:
//
//     @verbatim
//     padding()
//     (
//        while ((bit_count mod 8)!=0)
//        (
//        $padding_bit                                         1 UiMsbf
//        bit_count++
//        )
//     )
//     @endverbatim
//
// *****************************************************************************
.MODULE $M.sbcdec.read_padding_bits;
   .CODESEGMENT SBCDEC_READ_PADDING_BITS_PM;
   .DATASEGMENT DM;

   $sbcdec.read_padding_bits:
   $sbcdec.byte_align:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.READ_PADDING_BITS_ASM.READ_PADDING_BITS.PATCH_ID_0, r3)
#endif

   // get byte aligned

   r0 = M[r9 + $sbc.mem.GET_BITPOS_FIELD];

   r0 = r0 AND 7;
   call $sbcdec.getbits;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif
#endif
