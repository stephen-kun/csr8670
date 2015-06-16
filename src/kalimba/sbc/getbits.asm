// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCDEC_GETBITS_INCLUDED
#define SBCDEC_GETBITS_INCLUDED

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.getbits
//
// DESCRIPTION:
//    Get bits from SBC stream
//
// INPUTS:
//    - r0 = number of bits to get from buffer
//    - I0 = buffer to read words from
//
// OUTPUTS:
//    - r0 = unaffected
//    - r1 = the data read from the buffer
//    - I0 = buffer to read words from (updated)
//
// TRASHED REGISTERS:
//    r2, r3
//
// *****************************************************************************
.MODULE $M.sbcdec.getbits;
   .CODESEGMENT SBCDEC_GETBITS_PM;
   .DATASEGMENT DM;

   $sbcdec.get8bits:
   $sbcdec.get1byte:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.GET_BITS_ASM.GET8BITS.PATCH_ID_0, r3)
#endif

   r0 = 8;
   jump $sbcdec.getbits;


   $sbcdec.get4bits:
   r0 = 4;
   jump $sbcdec.getbits;


   $sbcdec.get2bits:
   r0 = 2;
   jump $sbcdec.getbits;


   $sbcdec.get1bit:
   r0 = 1;

   $sbcdec.getbits:
   // M[sbcdec.get_bitpos] should be initialised to 16

   // form a bit mask (r3)

      r3 = M[r9 + $sbc.mem.BITMASK_LOOKUP_FIELD];
      r3 = M[r3 + r0];
      // r2 = shift amount
      r2 = M[r9 + $sbc.mem.GET_BITPOS_FIELD];
      r2 = r0 - r2;

   // see if another word from buffer is needed
   if GT jump anotherword;

      // get current word from buffer (r1)
      r1 = M[I0, 0];
      // shift data to right
      r1 = r1 LSHIFT r2;
      // do the bit masking
      r1 = r1 AND r3;
      // update get_bitpos

      r2 = Null - r2;
      M[r9 + $sbc.mem.GET_BITPOS_FIELD] = r2;

      rts;

   anotherword:

      // get current word from buffer (r1)
      r1 = M[I0, 1];
      // shift current word
      r1 = r1 LSHIFT r2;
      // mask out unwanted bits
      // and get another word from buffer (r3)
      r1 = r1 AND r3,      r3 = M[I0, 0];
      // calc new shift amount
      r2 = r2 - 16;
      // and shift
      r3 = r3 LSHIFT r2;
      // combine the 2 parts
      r1 = r1 + r3;

      // update get_bitpos

      r2 = Null - r2;
      M[r9 + $sbc.mem.GET_BITPOS_FIELD] = r2;

      rts;

.ENDMODULE;

#endif