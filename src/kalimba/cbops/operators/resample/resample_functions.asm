// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#include "core_library.h"



.MODULE $M.cbops.resample.stereo_frac_1st_channel;
   .CODESEGMENT CBOPS_RESAMPLE_STEREO_FRAC_1ST_CHANNEL_PM;

   $cbops.resample.stereo_frac_1st_channel:
   $push_rLink_macro;

   // Coefficients 1-9 do not apply linear interpolation
   // Coef 1
   //            next coef      sample data
   r3 = r3 + M0, r0 = M[I2,M1], r2 = M[I4,M0];

   M[I3,M0] = r0;
   //                   next coef      sample data
   rMAC = r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 2
   M[I3,M0] = r0;
   //                         next coef      sample data
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 3
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 4
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 5
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 6
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 7
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // Coef 8
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // I6 point to one data ahead of I2
   I6 = I2 + 1;

   // Coef 9                 r0=next coef,  r2=current coef
   M[I3,M0] = r0;
   rMAC =rMAC + r0 * r2, r0 = M[I6,M1], r2 = M[I2,M1];


   // Coefficients 10-24 requires linear interpolation
   // Coef 10
   r0 = r0 - r2;
   r0 = r0 * r1 (frac);
   //            sample data    current coef
   r0 = r0 + r2, r2 = M[I4,M0], r5 = M[I2,M1];
   //                         next coef      store coef
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;

   // Coef 11
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M1];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;

   // Coef 12
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M1];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;

   // Coef 13
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M1];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;

   // Coef 14
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M1];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;

   // Coef 15
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M1];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;

   // Coef 16
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M1];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M1], M[I3,M0] = r0;


   // ** invert the address and M reg to perform coef mirroring **
   I2 = r8 - I2;
   I6 = I2 - 1;


   // Coef 17
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 18
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 19
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 20
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 21
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 22
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 23
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0], r5 = M[I2,M2];
   rMAC = rMAC + r0 * r2, r0 = M[I6,M2], M[I3,M0] = r0;

   // Coef 24
   r0 = r0 - r5;
   r0 = r0 * r1 (frac);
   r0 = r0 + r5, r2 = M[I4,M0];

   M[I3,M0] = r0;
   //                         next coef      sample data
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 25
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 26
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 27
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 28
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 29
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 30
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 31
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 32
   M[I3,M0] = r0;
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // Coef 33
   M[I3,M0] = r0;


   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;




.MODULE $M.cbops.resample.stereo_frac_2nd_channel;
   .CODESEGMENT CBOPS_RESAMPLE_STEREO_FRAC_2ND_CHANNEL_PM;

   $cbops.resample.stereo_frac_2nd_channel:
   $push_rLink_macro;

   // *** process the second channel

   // Coef 1
   //                   coef from      input
   //                   temp_buf       sample data
   rMAC = r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 2
   //                         coef from      input
   //                         temp_buf       sample data
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 3
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 4
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 5
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 6
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 7
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 8
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 9
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 10
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 11
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 12
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 13
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 14
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 15
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 16
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 17
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 18
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 19
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 20
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 21
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 22
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 23
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 24
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 25
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 26
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 27
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 28
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 29
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 30
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 31
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 32
   rMAC = rMAC + r0 * r2, r0 = M[I7,M0], r2 = M[I1,M0];
   // Coef 33
   rMAC = rMAC + r0 * r2;


   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;




.MODULE $M.cbops.resample.mono_int_upsample;
   .CODESEGMENT CBOPS_RESAMPLE_MONO_INT_UPSAMPLE_PM;

   $cbops.resample.mono_int_upsample:
   $push_rLink_macro;

   // Coefficients 1-9 do not apply linear interpolation
   // Coef 1
   //            next coef      sample data
   r3 = r3 + M0, r0 = M[I2,M1], r2 = M[I4, M0];
   //                   next coef      sample data
   rMAC = r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 2
   //                         next coef      sample data
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 3
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 4
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 5
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 6
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 7
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 8
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 9
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 10
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 11
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 12
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 13
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 14
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 15
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];
   // Coef 16
   rMAC = rMAC + r0 * r2, r0 = M[I2,M1], r2 = M[I4,M0];

   // invert the M reg to perform coef mirroring
   I2 = I6 - I2;


   // Coef 17
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 18
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 19
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 20
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 21
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 22
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 23
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 24
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 25
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 26
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 27
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 28
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 29
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 30
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 31
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];
   // Coef 32
   rMAC = rMAC + r0 * r2, r0 = M[I2,M2], r2 = M[I4,M0];

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

