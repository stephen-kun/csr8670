// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef MATH_SQRT_INCLUDED
#define MATH_SQRT_INCLUDED

// *****************************************************************************
// MODULE:
//    $math.sqrt
//
// DESCRIPTION:
//    Library subroutine to evaluate the square root of a number
//
// INPUTS:
//    - r0 = input value between 0 and 2^23-1 (ie. 0 and 1.0 fractional)
//
// OUTPUTS:
//    - r1 = result (accurate to 16bits, RMS error is 5bits))
//
// TRASHED REGISTERS:
//    rMAC, r2-r4, I0, M0
//
// CPU USAGE:
//    15 cycles
//
// *****************************************************************************

.MODULE $M.math.sqrt;
   .CODESEGMENT MATH_SQRT_PM;
   .DATASEGMENT DM;

   .BLOCK/DM1 sqrtcoefs;
      .VAR coefs[5] = -0.0582446212,   0.2427302840,  -0.4456864692,
                   0.6458306544,  0.1153651422;
      .VAR sqrtofhalf = 0.7071067812;
   .ENDBLOCK;

   $math.sqrt:

   M0 = 1;
   I0 = &coefs;
   // r4 = shiftamount
   r4 = SIGNDET r0,         rMAC = M[I0,M0];
   // normalise so between 0.5 and 1.0
   r1 = r0 ASHIFT r4,       r2 = M[I0,M0];

   // if input = 0 make sure output is 0
   // and load x^0 * coefs(1)
   if Z rts;

   // x^1*coefs(5) + x^0*coefs(4) 
   r2 = r2 + r1*rMAC,         rMAC=M[I0,M0];
   // x^2*coefs(5) + x^1*coefs(4) + x^0*coefs(3) 
   rMAC = rMAC + r1*r2,       r2=M[I0,M0];
   // x^3*coefs(5) + x^2*coefs(4) + x^1*coefs(3) + x^0*coefs(2) 
   r2 = r2 + r1*rMAC,         rMAC=M[I0,M0];
   // x^4*coefs(5) + x^3*coefs(4) + x^2*coefs(3) + x^1*coefs(2) + x^0*coefs(1)
   rMAC = rMAC + r1*r2,       r3=M[I0,M0];

   // r2 = loose LSB of shiftamount
   r2 = r4 ASHIFT -1;
   // r2 = 1 - floor(shiftamount/2)
   r2 = M0 - r2;
   // rescale and shift
   r1 = rMAC ASHIFT r2;
   Null = r4 AND 1;
   // if shiftamount was odd * sqrt(1/2)
   if NZ r1 = r1 * r3 (frac);
   rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $math.sqrt48         - single calling function (double precision input)
//       or
//    $math.fsqrt          - single calling function (float format input)
//       or
//    $math.sqrt.init
//    $math.sqrt.core      - loop calling (double precision input)
//    $math.fsqrt.core     - loop calling (float format input)
//
// DESCRIPTION:
//    y = sqrt(x)
//
// INPUTS:
//    - rMAC = x (double presicion, Q1.47 positive number) (ie. 0 and 1.0 fractional)
//
//                                                          or for $math.fsqrt
//    - r0   = x (mantisa)
//    - r1   = x (exp: number of sign bits)
//
// OUTPUTS:
//    - r0   = y (Q1.23) (accurate to 16bits, RMS error is 5bits))
//
//                                                          or additionally
//    - rMAC = y (mantisa)
//    - r1   = y (exp: negative number of sign bits)
//
// TRASHED REGISTERS:
//    rMAC, r1-r2, I3, M1
//    M2 - trashed by '$math.sqrt.init'
//
// CPU USAGE:
//    16 cycles
//
// *****************************************************************************
.MODULE $M.math.sqrt48;
   .CODESEGMENT MATH_SQRT_48_TAYLOR_M;
   .DATASEGMENT DM;

   .BLOCK/DM1 sqrtcoefs;
      .VAR coefs[5] = -0.0582446212,   0.2427302840,  -0.4456864692,
                   0.6458306544,  0.1153651422;
      .VAR sqrtofhalf = 0.7071067812;
   .ENDBLOCK;


// -----------------------------------------------------------------------------
// $math.sqrt.init: set up for loop usage
// -----------------------------------------------------------------------------
$math.sqrt.init:
   I3 = &coefs;
   M1 = 1;
   M2 = -LENGTH(&coefs);
   rts;

// -----------------------------------------------------------------------------
// $math.fsqrt: entry of single calling for float input in r0/r1 (mantisa/exp)
// -----------------------------------------------------------------------------
$math.fsqrt:
   I3 = &coefs;
   M1 = 1;
   jump $math.fsqrt.core;

// -----------------------------------------------------------------------------
// $math.sqrt48: entry of single calling for double precision input in rMAC
// -----------------------------------------------------------------------------
$math.sqrt48:
   I3 = &coefs;
   M1 = 1;

// -----------------------------------------------------------------------------
// $math.sqrt.core: entry of loop calling for double precision input in rMAC
// -----------------------------------------------------------------------------
$math.sqrt.core:
   // r1 = shiftamount
   r1 = SIGNDET rMAC;
   // normalise so between 0.5 and 1.0
   r0 = rMAC ASHIFT r1;

// -----------------------------------------------------------------------------
// $math.fsqrt.core: entry of loop calling for float input in r0(mantisa)/r1(exp)
// -----------------------------------------------------------------------------
$math.fsqrt.core:

   // if input = 0 make sure output is 0
   Null = r0,                 rMAC = M[I3,M1];
   if Z r1 = r1 + r1,         r2 = M[I3,M1];
   // x^1*coefs(5) + x^0*coefs(4) 
   r2 = r2 + r0 * rMAC,       rMAC=M[I3,M1];
   // x^2*coefs(5) + x^1*coefs(4) + x^0*coefs(3) 
   rMAC = rMAC + r0* r2,      r2=M[I3,1];
   // x^3*coefs(5) + x^2*coefs(4) + x^1*coefs(3) + x^0*coefs(2) 
   r2 = r2 + r0* rMAC,        rMAC=M[I3,M1];
   // x^4*coefs(5) + x^3*coefs(4) + x^2*coefs(3) + x^1*coefs(2) + x^0*coefs(1)
   rMAC = rMAC + r0* r2,      r2=M[I3,M2];

   Null = r1 AND 1;
   // if shiftamount was odd * sqrt(1/2)
   if NZ rMAC = rMAC * r2 (frac);
   // loose LSB of shiftamount
   r2 = r1 ASHIFT -1;
   // 1 - floor(shiftamount/2)
   r1 = 1 - r2;
   // rescale and shift
   r0 = rMAC ASHIFT r1;
   rts;

.ENDMODULE;

#endif // MATH_SQRT_INCLUDED
