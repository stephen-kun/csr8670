// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCDEC_READ_SCALE_FACTORS_INCLUDED
#define SBCDEC_READ_SCALE_FACTORS_INCLUDED

#include "stack.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.read_scale_factors
//
// DESCRIPTION:
//    Read Scalefactors
//
// INPUTS:
//    - I0 = buffer to read words from
//
// OUTPUTS:
//    - I0 = buffer to read words from (updated)
//
// TRASHED REGISTERS:
//    r0-r7, r10, DoLoop, I1, M1
//
// NOTES:
//  Read in scalefactors (doing CRC of the bits):
//
//     @verbatim
//     scale_factors()
//     (
//        for (ch=0;ch<nrof_channels;ch++)
//        (
//           for (sb=0;sb<nrof_subbands;sb++)
//           (
//           $scale_factor[ch][sb]                             4 UiMsbf
//           )
//        )
//     )
//     @endverbatim
//
// *****************************************************************************
.MODULE $M.sbcdec.read_scale_factors;
   .CODESEGMENT SBCDEC_READ_SCALE_FACTORS_PM;
   .DATASEGMENT DM;

   $sbcdec.read_scale_factors:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.READ_SCALE_FACTORS_ASM.READ_SCALE_FACTORS.PATCH_ID_0, r6)
#endif


   r6 = M[r9 + $sbc.mem.NROF_CHANNELS_FIELD];
   r7 = M[r9 + $sbc.mem.NROF_SUBBANDS_FIELD];
   r6 = r6 * r7 (int);
   r0 = M[r9 + $sbc.mem.SCALE_FACTOR_FIELD];
   I1 = r0;


   M1 = 1;
   r0 = 4;
   loop:
      call $sbcdec.getbits;
      call $sbc.crc_calc;
      // subband sample reconstruction later
      r6 = r6 - M1,        M[I1, M1] = r1;
   if NZ jump loop;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif