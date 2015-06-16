// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

// *****************************************************************************
// FILE: sbadpcm_quantize.asm - SBADPCM quantization process
// *****************************************************************************

#ifndef _SBADPCM_QUANTIZE
#define _SBADPCM_QUANTIZE

#include "sbadpcm.h"

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Quantize
//
// DESCRIPTION:
//    BLOCK 1x, BLOCK 2x, BLOCK3x, BLOCK5L
//
// MODIFICATIONS:
//    6/16/09    scg - original implementation
//
// INPUTS:
//        x=L or H (for lowband/highband)
//    (enc)r0 = Ex (1.23, LJ), (dec)r0=Ix(dec)
//    r1 = detx        ( .18) ie q1.15/8
//    I2 = ptr tables
//    I3 = ptr to l/h internal state + 2
//    I5 = ptr constants
//    M1 = 1
//    M0 = 0
//    r8 ptr to data object
// OUTPUTS:
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    I4/L4  - circular x-buffer
//    M3  - sample loop counter
//
//
// TRASHED REGISTERS:
//    r0-r5,r10, I0-I3,I5, loop
//
// CPU USAGE:
//    D-MEMORY:
//    P-MEMORY:
//    CYCLES:
//
//       ENCODE:
//
//         LOWSB:
//            bitexact: up to  37+4*30 = 157
//            optimized: up to 37+3*30 = 127
//
//         HIGHSB:
//            bitexact: up to  37+4*2 = 45
//            optimized: up to 37+3*2 = 43
//
//       DECODE:
//
//         LOWSB:
//            bitexact: 30
//            optimized: 28
//
//         HIGHSB:
//            bitexact: 23
//            optimized: 21
//
// NOTES:
//    optimize: some sort of binary search tree instead of a linear search?
// *****************************************************************************


.MODULE $M.SBAdpcm.Quantize;
   .CODESEGMENT SBADPCM_QUANTIZE_PM;

decoderLSB_proc:

// BLOCK 5L, INVQBL
// ************************************************************************************
   r3 = M[I5, 1], r5 = M[I2, 1]; // r3 = rix shift, r5=qqxilx vs rix table

   r2 = r0 LSHIFT r3; // r2=rix, load wxtab
   rMac = M[r5 + r2];    // wd2 (signed qq4)
   rMac = rMac * r1;  // Dl=sgn_qq4*detx (q23*q15), save Ix
#if G722_BITEXACT
   r3 = rMac1;  // Dl
   r3 = r3 ASHIFT 8; // Dl to q23
#else
   r3 = rMac ASHIFT 8;
#endif
   M[r8+$sbadpcm.EL_FIELD] = r3; //Dl,x

decoderHSB_proc:
   r3 = M[I5, 1], r5 = M[I2, 1]; // r3 = rix shift, r5=qqxilx vs rix table

   jump block2x;

encoder_proc:

// BLOCK 1x QUANTx
// ************************************************************************************
   r3 = M[I2, 1], r2 = M[I5, 1]; // r2 = loop count
   r4 = M[I2, 1], r5 = M[I5, 1]; // r5 = size of negative Ix table
   r10 = r2;
   I1 = r3;
   r2=M[I1, M1];
   r0 = r0 ASHIFT -8;
   if POS jump eXpos;
   r4 = r4+r5; // negative Ix
   r0 = r0 + M1;
   r0 = r0 * -1 (int);
eXpos:

   do quantize_loop;
#if G722_BITEXACT
      rMac = r2*r1;  // detl*Qi q18*q20+1=q39-24=q15 in rMac1
      r2 = rMac1;    // {bitexact} no rounding
      Null = r0-r2, r2=M[I1, M1]; // wd - detl*Qi
      if LT jump quantize_done;
#else
      rMac = r0;
      rMac = rMac - r2*r1, r2=M[I1, 1];
      IF LT jump quantize_done;

#endif
   quantize_loop:
   r2=M[I1, M1]; // extra increment on I1 for fallthrough case

quantize_done:
   // I1-r3=mix+1 -> range is 2-31(low), 2-3(high)
   I0 = I1 - r3, r5 = M[I2, M1]; // r5=qqxilx vs rix table
   // r0=Ix code [0-63 (low), 0-3(high)]
   I0 = I0 + r4;
   r0 = M[I0, 0], r3 = M[I5, 1]; // load Ix, rix shift
   M[I3, M1] = r0;


block2x:

// BLOCK 2x, INVQAx
// ************************************************************************************
   // r0 = Ix
   // r1 = detx
   r2 = r0 LSHIFT r3, r4 = M[I2, M1]; // r2=rix, load wxtab
   rMac = M[r5 + r2];    // wd2 (signed qq4)
   rMac = rMac * r1;  // Dxt=sgn_qq4*detx (q23*q15), save Ix
#if G722_BITEXACT
   r0 = rMac1;  // Dxt
   r0 = r0 ASHIFT 8; // Dxt to q23
#else
   r0 = rMac ASHIFT 8; // Dxt to q23
#endif
// BLOCK 3x, LOGSCx
// ************************************************************************************
   // r2 = rix
   I0 = r4 + r2, M[I3, M1] = r0;    // get wx index, save Dxt;
   r3 = M[I3, 0], r0 = M[I5, 1];     // load nbxl, load 127
   r0 = r0 * r3(int), r1 = M[I5, M1];   // nbxl*127, load -7
   r0 = r0 LSHIFT r1, r1 = M[I0, 0], r3 = M[I5, 1];  // wd = (nbxl*127)>>7, load wx, load 18432
   r0 = r0 + r1, r2 = M[I5, 1];     // nbx1 = min(max(wd + wx, 0), 18432), load 6
   if NEG r0 = 0;
   Null = r3 - r0;
   if NEG r0 = r3, r4 = M[I2, M1];

// BLOCK 3x, SCALEx
// ************************************************************************************
   // r0 = nbx1
   r0 = r0 LSHIFT r2, M[I3, 0] = r0, r2 = M[I5, 1];  // nbx1>>6, save nbx1,  load 31
   r0 = r0 and r2, r1 = M[I3, 1], r2 = M[I5, 1]; // wd1=(nbx1>>6)&31, load nbx1 ,load 11
   I0 = r4 + r0;
   r1 = r1 LSHIFT r2, r3 = M[I5, 1];             // wd2=nbx1>>11, load 8
   r3 = r1 - r3, r0=M[I0, M0];                  // wd2-8, load ixb
   r0 = r0 LSHIFT r3, r2 = M[I5, 1];            // wd3 = ixb[] << wd2-8, load 2
   r0 = r0 LSHIFT r2;                           // detx = wd3 << 2
   M[I3, M1] = r0;                              // save detx

   rts;

.ENDMODULE;

#endif //_SBADPCM_QUANTIZE
