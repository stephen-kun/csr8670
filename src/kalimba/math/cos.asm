// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef MATH_COS_INCLUDED
#define MATH_COS_INCLUDED

#include "stack.h"

// *****************************************************************************
// MODULE:
//    $math.cos
//
// DESCRIPTION:
//    Library subroutine to evaluate the Cosine of a number
//
// INPUTS:
//    - r0 = input angle -2^23 == -180°,  +2^23 == 180°
//
// OUTPUTS:
//    - r1 = result
//
// TRASHED REGISTERS:
//    rMAC, r2, r3, I0
//
// CPU USAGE:
//    4 + 22(from sin) cycles = 26 cycles
//
// *****************************************************************************
.MODULE $M.math.cos;
   .CODESEGMENT MATH_COS_PM;
   .DATASEGMENT DM;

$math.cos:
$cos:
   $push_rLink_macro;
   r3 = -1.0;
   r1 = r0 + 0.5;
   r2 = r0 - 0.5;
   if GE r1 = r2 + r3;
   r0 = r1;
   call $math.sin;
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cos_taylor6
//
// DESCRIPTION:
//    Library subroutine to evaluate the Cosine of a number
//
// INPUTS:
//    r0 = input angle -2^23 == -180°,  +2^23 == 180°
//
// OUTPUTS:
//    r0 = result (accurate to approximately 15 bits for 6th order)
//
// TRASHED REGISTERS:
//    I0, r1, r2, r3, rMAC
//
// CPU USAGE:
//    TBD
//
// NOTES:
//    More efficient implementation needs to be done after it is determined
//    how many bits of precision are needed in cosine function
//    Then an efficient trade off needs to be made between table size
//    and order of taylor interpolation done between table entries.
//    This implementation is a straight taylor series implementation of order 6
//    with no table used and its centered around pi/4. It makes use of symmetry
//    cos x = cos (- x) and cos(pi - x) = - cos(x)
//
// *****************************************************************************
.MODULE $M.math.cos_taylor6;

   .CODESEGMENT MATH_COS_TAYLOR6_PM;
   .DATASEGMENT DM;

$math.cos_taylor6:

   .VAR coefs[7] =  0.08838834764832, -0.27768018363490,
                   -0.43617901247743,  0.45676559374971,
                    0.35874285843417, -0.22540478571692,
                   -0.11802166981538;
   .VAR vFracMin = 0x800000;

   I0 = &coefs;
   r8 = M[&vFracMin];
   r1 = r8;
   Null = r0;
   if NEG r0 = r0 * r8 (frac);
   // rMAC = coefs(0)
   rMAC = M[I0,1];
   // if 2nd quad. then invert input
   Null = r0 LSHIFT 1;
   if POS r1 = Null;
   if NEG r0 = -r0;
   // remove sign bit
   r0 = r0 LSHIFT 1;
   r0 = r0 LSHIFT -1;
   // r0 = x - a, to calc cos centered around a = pi/4
   r0 = r0 - 0.25;

   r3 = M[I0,1];
   r2 = r0 * r0 (frac);
   // x^1 * coefs(1)
   rMAC = rMAC + r0 * r3, r3 = M[I0,1];
   // x^2 * coefs(2)
   rMAC = rMAC + r2 * r3, r3 = M[I0,1];
   r2 = r2 * r0 (frac);
   // x^3 * coefs(3)
   rMAC = rMAC + r2 * r3, r3 = M[I0,1];
   r2 = r2 * r0 (frac);
   // x^4 * coefs(4)
   rMAC = rMAC + r2 * r3, r3 = M[I0,1];
   r2 = r2 * r0 (frac);
   // x^5 * coefs(5)
   rMAC = rMAC + r2 * r3, r3 = M[I0,1];
   r2 = r2 * r0 (frac);
   // x^6 * coefs(6)
   rMAC = rMAC + r2 * r3;
   // rescale
   r0 = rMAC ASHIFT 3;
   Null = r1;
   // negate output if needed
   if NZ r0 = r0 * r8 (frac);
   rts;

.ENDMODULE;

#endif // MATH_COS_INCLUDED
