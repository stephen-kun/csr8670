// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef MATH_ATAN_INCLUDED
#define MATH_ATAN_INCLUDED

// *****************************************************************************
// MODULE:
//    $math.atan
//
// DESCRIPTION:
//    Library subroutine to evaluate the arctan (4 quadrants) of a complex number.
//    The approximation uses a second order polynomial, optimized with a minimax
//    criterion (see IEEE Signal Processing Magazine, Volume 23 Number 3 May 2006.
//    The maximum absolute error is 0.0038 rad.
//
// INPUTS:
//    - r5: Real part
//    - r6: Imaginary part
//
//
// OUTPUTS:
//    - r5 = angle -2^23 == -180°,  +2^23 == 180°
//
// TRASHED REGISTERS:
//    rMAC, r0, r1, r2, r3, r4, r5, r6, r7, r8
//
// PROGRAM MEMORY:
//    51 words
//
// CPU USAGE:
//    44 cycles for worst case scenario.
//
// *****************************************************************************

.MODULE $M.math.atan;
#ifdef BLD_PRIVATE
   .PRIVATE;
#endif
   .CODESEGMENT MATH_ATAN_PM;
	.DATASEGMENT DM;

   .CONST   $math.MAX_24                 0x7fffff;
   .CONST   $math.MIN_24                 0x800000;

$math.atan:
$atan:
   // signI
   r2 = &$math.MIN_24;
   // signQ
   r3 = &$math.MIN_24;
   //coeff1Q21;
   r7 = 0.26460003852844;
   //coeff2Q21;
   r8 = 0.06824994087219;
   r4 = &$math.MAX_24;

   r0 = r5;
   if POS jump endAbsReal0;
      r2 = 0x7fffff;
      r0 = r0 * 0x800000 (frac);
   endAbsReal0:

   r1 = r6;
   if POS jump endAbsImag0;
      r3 = 0x7fffff;
      r1 = r1 * 0x800000 (frac);
   endAbsImag0:

   Null = r1 - r0;
   if LT jump IdivQ;
   QdivI:
      rMAC = r5 ASHIFT -1;
      Div = rMAC / r6;
      r7 = -r7;
      // signI
      r4 = r2;
      jump endDivIQ;

IdivQ:
   rMAC = r6 ASHIFT -1;
   Div = rMAC/r5;
   // signQ
   r4 = r3;
endDivIQ:
   // PI_Q21;
   r3 = -0.78539812564850;
   // x - y
   Null = r5 - r6;
   // r8 = -coeff2
   if LT r8 = - r8;
   // abs(y) - (+x)
   Null = r1 - r5;
   if LT jump Q18;
Q45:
      // abs(y) - (-x)
      Null = r1 + r5;
      if GT jump Q23;
         // pi*sign(Q)
         r3 = r3 * r4 (frac);
         jump endQuadrants;
Q23:
      r3 = r3 ASHIFT -1;
      // abs(x) - (+y)
      Null = r0 - r6;
      // Q67
      if LT r3 = -r3;
      jump endQuadrants;
Q18:
      r3 = 0;
endQuadrants:
   rMAC = r3;
   // coeff2*sign_
   r8 = r8 * r4 (frac);
   r0 = DivResult;
   // QdivI^2
   r1 = r0 * r0 (frac);
   rMAC = rMAC + r1 * r8;
   // r7 = coeff1, r0 = QdivI
   rMAC = rMAC + r7 * r0;

   // convert to [-1,1) range: multiply by 4/pi = (2/pi)*2^2
   r1 = rMAC1;
   r0 = rMAC0;
   // 2/pi
   r2 = 0.63661968708038;
   r0 = r0 * r2 (frac);
   rMAC = r1 * r2;
   rMAC = rMAC + r0 * 1.192092895507813e-7;
   r5 = rMAC ASHIFT 1;
   rts;

.ENDMODULE;

#endif // MATH_ATAN_INCLUDED
