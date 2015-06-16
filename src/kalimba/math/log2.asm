// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef MATH_LOG2_INCLUDED
#define MATH_LOG2_INCLUDED

#include "math_library.h"

//******************************************************************************
// MODULE:
//    $math.log2_taylor
//
// DESCRIPTION:
//    Calculate y = log2(x) in taylor series method
//
// INPUTS:
//    - rMAC = x (double presicion, Q9.47 positive number)
//
// OUTPUTS:
//    - r0 = log2(x), Q format is Q8.16
//
// TRASHED REGISTERS:
//    rMAC, r0, r1, r6, I7
//
// CPU USAGE:
//    23 cycles
//
// NOTES:
//    For log2(0) this routine returns = log2(1/2^48).
//
//******************************************************************************
.MODULE $M.math.log2_taylor;
   .CODESEGMENT MATH_LOG2_TAYLOR_PM;
   .DATASEGMENT DM;



   .VAR/DM1 log2_coefs[7] = -0.0124136209,   0.0589549541,  -0.1361793280,
                         0.2269296646,  -0.3584938049,   0.7211978436,
                         0.0000063181;


$math.log2_taylor:
   // 20 cycles.  if can use I0:I3 and M1=1 could save 4 more
   push I0;
   push M1;          
   // load table address
   I0 = &log2_coefs;
   M1 = 1;

   // -P
   r6 = SIGNDET rMAC;
   // M, C6
   rMAC = rMAC ASHIFT r6, r0 = M[I0,1];
   // 4*(M - 1/2), unsigned
   r1 = rMAC LSHIFT 2;
   // x = 2*M - 1
   rMAC = r1 LSHIFT -1;

   // 1 - P
   r6 = r6 + M1,         r1=M[I0,M1];
   // integer part: negative
   r6 = r6 ASHIFT 16;

   // C5 + C6*x
   r1 = r1 + r0*rMAC ,   r0=M[I0,M1];
   // C4 + (C6*x + C5)*x
   r0 = r0 + r1*rMAC ,   r1=M[I0,M1];
   // C3 + (C6*x^2 + C5*x + C4)*x
   r1 = r1 + r0*rMAC ,   r0=M[I0,M1];
   // C2 + (C6*x^3 + C5*x^2 + C4*x + C3)*x
   r0 = r0 + r1*rMAC ,   r1=M[I0,M1];
   // C1 + (C6*x^4 + C5*x^5 + C4*x^2 + C3*x + C2)*x
   r1 = r1 + r0*rMAC ,   r0=M[I0,M1];
   // C0 + (C6*x^5 + C5*x^4 + C4*x^3 + C3*x^2 + C2*x + C1)*x
   r0 = r0 + r1*rMAC ;
   // fractional part
   r1 = r0 ASHIFT -6;
   // 8.16 format
   r0 = r1 - r6;
   pop M1;
   pop I0;

   rts;

.ENDMODULE;





//******************************************************************************
// MODULE:
//    $math.log2_table
//
// DESCRIPTION:
//    Calculate y = log2(x) in table look up method
//
// INPUTS:
//    - rMAC = x (double presicion, Q9.47 positive number)
//
// OUTPUTS:
//    - r0 = log2(x), Q format is Q8.16
//
// TRASHED REGISTERS:
//    rMAC, r1, r6
//
// CPU USAGE:
//    14 cycles
//
// NOTES:
//    For log2(0) this routine returns = log2(1/2^48).
//
//******************************************************************************
.MODULE $M.math.log2_table;
   .CODESEGMENT MATH_LOG2_TABLE_PM;
   .DATASEGMENT DM;

   .CONST   $LOG2_TBL_INDX   5;

   .VAR/DM1 tab32_log2[33] = 0.0000000000,   0.0003468395,   0.0006833076,
                         0.0010100008,   0.0013275146,   0.0016363264,
                         0.0019369125,   0.0022296906,   0.0025150776,
                         0.0027933716,   0.0030649900,   0.0033301712,
                         0.0035893322,   0.0038425922,   0.0040903091,
                         0.0043327213,   0.0045700073,   0.0048024059,
                         0.0050301552,   0.0052533150,   0.0054721832,
                         0.0056868792,   0.0058975816,   0.0061043501,
                         0.0063074827,   0.0065069794,   0.0067029595,
                         0.0068956614,   0.0070850849,   0.0072714090,
                         0.0074546337,   0.0076349974,   0.0078125000;

$math.log2_abs_table:
   // number of leading zeros
   r6 = SIGNDET rMAC;
   // normalised
   rMAC = rMAC ASHIFT r6;
   // ensure positive (absolute value)
   if NEG rMAC = NULL - rMAC;
   jump continue_jp;

$math.log2_table:
   // number of leading zeros
   r6 = SIGNDET rMAC;
   // normalised
   rMAC = rMAC ASHIFT r6;
continue_jp:

   r6 = r6 + 1;
   // integer part: negative
   r6 = r6 ASHIFT 16;

   r1 = rMAC LSHIFT 2;
   // table index
   r1 = r1 LSHIFT -(24 - $LOG2_TBL_INDX);

   r0 = rMAC LSHIFT ($LOG2_TBL_INDX + 2);
   // interpolation factor
   r0 = r0 LSHIFT -1;

   // base value
   rMAC = M[r1 + (&tab32_log2 + 0)];            // base value
   r1 = M[r1 + (&tab32_log2 + 1)];
   // interpolation range
   r1 = r1 - rMAC;
   // interpolation bits and fractional part
   rMAC = rMAC + r0 * r1;
   // Q8.16 format
   r0 = rMAC - r6;
   rts;

.ENDMODULE;

#endif // MATH_LOG2_INCLUDED
