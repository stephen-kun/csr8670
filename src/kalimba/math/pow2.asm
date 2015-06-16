// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef MATH_TABLE_INCLUDED
#define MATH_TABLE_INCLUDED

//******************************************************************************
// MODULE:
//    $math.pow2_taylor
//
// DESCRIPTION:
//    Calculate y = pow2(x) in taylor series method
//
// INPUTS:
//    - r0 = x (negative number, Q format is 8.16)
//
// OUTPUTS:
//    - r0 = pow2(x), in Q1.23
//
// TRASHED REGISTERS:
//    r1, r6, r7, I7
//
// CPU USAGE:
//    18 cycles
//
//******************************************************************************
.MODULE $M.math.pow2_taylor;
   .CODESEGMENT MATH_POW2_TAYLOR_PM;
   .DATASEGMENT DM;

   .VAR/DM1 pow2_coefs[7] = 0.0000782609,   0.0006790758,   0.0048083663,
                        0.0277463794,   0.1201133728,   0.3465742469,
                        0.5000000000;

$math.pow2_taylor:
   // 18 cycles (saves 3 cycles).  If can use I0:I3 and M1=1 we could save an additionall 4 cycles
   push I0;
   // table
   I0 = &pow2_coefs;
   // (8-24);
   r7 = r0 ASHIFT -16;
   r6 = r0 LSHIFT 8;
   // fractional portion
   r6 = r6 LSHIFT -1;

   push M1,           r1 = M[I0,1];
   M1 = 1;
   // integer portion
   r7 = r7 + M1,      r0 = M[I0,M1];
   // C5 + C6*x
   r0 = r0 + r1*r6 ,  r1 = M[I0,M1]; 
   // C4 + (C6*x + C5)*x
   r1 = r1 + r0*r6 ,  r0 = M[I0,M1];
   // C3 + (C6*x^2 + C5*x + C4)*x
   r0 = r0 + r1*r6 ,  r1 = M[I0,M1];
   // C2 + (C6*x^3 + C5*x^2 + C4*x + C3)*x
   r1 = r1 + r0*r6 ,  r0 = M[I0,M1];
   // C1 + (C6*x^4 + C5*x^5 + C4*x^2 + C3*x + C2)*x
   r0 = r0 + r1*r6 ,  r1 = M[I0,M1];
   // C0 + (C6*x^5 + C5*x^4 + C4*x^3 + C3*x^2 + C2*x + C1)*x
   r1 = r1 + r0*r6 ;
   // Q1.23
   r0 = r1 ASHIFT r7;
   pop M1;
   pop I0;

   rts;

.ENDMODULE;





//******************************************************************************
// MODULE:
//    $math.pow2_table
//
// DESCRIPTION:
//    Calculate y = pow2(x) in table look up method
//
// INPUTS:
//    - r0 = x (negative number, Q format is 8.16
//
// OUTPUTS:
//    - r0 = pow2(x), in Q1.23
//
// TRASHED REGISTERS:
//    r1, r6, r7
//
// CPU USAGE:
//    12 cycles
//
//******************************************************************************
.MODULE $M.math.pow2_table;
   .CODESEGMENT MATH_POW2_TABLE_PM;
   .DATASEGMENT DM;

   .CONST   $POW2_TBL_INDX   5;


   .VAR/DM1 tab32_pow2[33] = 0.4999998808,   0.5109484196,   0.5221368074,
                         0.5335700512,   0.5452537537,   0.5571932793,
                         0.5693942308,   0.5818623304,   0.5946034193,
                         0.6076235771,   0.6209287643,   0.6345254183,
                         0.6484196186,   0.6626181602,   0.6771275997,
                         0.6919548512,   0.7071067095,   0.7225903273,
                         0.7384129763,   0.7545820475,   0.7711052895,
                         0.7879903316,   0.8052450418,   0.8228776455,
                         0.8408962488,   0.8593095541,   0.8781259060,
                         0.8973543644,   0.9170038700,   0.9370837212,
                         0.9576032162,   0.9785718918,   0.9999998808;

$math.pow2_sat_table:
   //(8-24);
   r6 = r0 ASHIFT (-16);
   if NEG jump continue_jp;
   r0 = 2 * 0.4999998808;
   rts;

$math.pow2_table:
   //(8-24);
   r6 = r0 ASHIFT (-16);
   
continue_jp:
   //Q8.16;
   r7 = r0 LSHIFT 8;
   //table index
   r7 = r7 LSHIFT -(24 - $POW2_TBL_INDX);
   //integer part
   r6 = r6 + 1;

   //base value
   r1 = M[r7 + (&tab32_pow2 + 0)];  
   // interpolation range
   r7 = M[r7 + (&tab32_pow2 + 1)];
   r7 = r7 - r1;
   // (POW2_TBL_INDX+8);
   r0 = r0 LSHIFT ($POW2_TBL_INDX + 8);
   r0 = r0 LSHIFT -1;
   r1 = r1 + r7*r0;
   //pow2 value: Q1.23
   r0 = r1 ASHIFT r6;
   
   rts;

.ENDMODULE;

#endif // MATH_TABLE_INCLUDED
