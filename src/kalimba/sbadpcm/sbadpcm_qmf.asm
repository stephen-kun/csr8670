// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

// *****************************************************************************
// FILE: adpcm_state.asm - ADPCM signal reconstruct and states update
// *****************************************************************************

#ifndef _SBADPCM_QMF
#define _SBADPCM_QMF

#include "sbadpcm.h"


// *****************************************************************************
// MODULE:
//    $M.Adpcm.QMF
//
// DESCRIPTION:
//    QMF filterbank
//
// MODIFICATIONS:
//    6/15/09    scg - original implementation
//
// INPUTS:
//    r0/r1 = YL/YH (synthesis only)
//    r8 - pointer to ADPCM data object (encoder/decoder)
//    I4/L4 - ptrX (Q1.23)
//    M1 = 1
//
// OUTPUTS:
//    I4 - updated by two samples
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    L4  - length of circular buffer (I4)
//    M3  - sample loop counter
//
// TRASHED REGISTERS:
//   Analysis:   r0-r3,r10,I0,I5,L0,M0,M2,LOOP
//   Synthesis:  r0-r4,r10,I0,I5,L0,LOOP
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY:
//      Analysis: 43
//      Synthesis: 53
//    CYCLES (bit-accurate with ITU c-code):
//      Analysis: 33+2*12 = 57
//      Synthesis: 38+2*12 = 62
//
// NOTES:
// *****************************************************************************

.MODULE $M.Adpcm.QMF;

   .VAR/DM2     qmf_coef[] =
768,-2816,-2816,13568,3072,-39936,8192,92672,
-53760,-206080,243456,992256,992256,243456,
-206080,-53760,92672,8192,-39936,3072,13568,
-2816,-2816,768;

   .DATASEGMENT DM;
   .CODESEGMENT ADPCM_QMF_PM;

analysis:
   M0 = -25;
   M2 = -1;
   I5 = &qmf_coef;
   L0 = $sbadpcm.HIST_BUF_SIZE;
   r3 = 12;


   // update the history buffer
   r0 = M[r8 + $sbadpcm.encode.PTR_ENC_HISTX_FIELD];
   I0 = r0;
   r1 = M[I4, M1];
   M[I0, M1] = r1, r1 = M[I4, M2];
   r10 = r3, M[I0, M1] = r1;
   r0 = I0;
   M[r8 + $sbadpcm.encode.PTR_ENC_HISTX_FIELD] = r0;


   // odd delay(Xn-1,...Xn-23) * odd coef(h1,h3,h5,...)
   // I0=Xn-23=Xn+1
   // I5=coef[0]=coef[23]
   rMac = 0, r0 = M[I0, 2], r1 = M[I5, 2];
   do qmf_oddx;
      rMac = rMac + r0*r1, r0 = M[I0, 2], r1 = M[I5, 2];
   qmf_oddx:
#if G722_BITEXACT
   r2 = rMac1;
#else
   r2 = rMac;
#endif

   // even delay(Xn,....Xn-22) * even coef(h0,h2,h4,...)
   // I0=X[n-22]=X[n+2]
   // I5=coef[1]=coef[22]
   r10 = r10 + r3, r0 = M[I0, M2], r1 = M[I5, M0];
   rMac = 0, r0 = M[I0, 2], r1 = M[I5, 2];
   do qmf_evenx;
      rMac = rMac + r0*r1, r0 = M[I0, 2], r1 = M[I5, 2];
   qmf_evenx:
#if G722_BITEXACT
   r0 = rMac1; // no rounding
   r1 = r2 + r0; // low subband
   r0 = r0 - r2; // high subband
#else
   r1 = r2 + rMac; // low subband
   r0 = rMac - r2; // high subband
#endif

   // x*2, saturate to halfscale
   r0 = r0 + r0;
   r0 = r0 + r0;
   r0 = r0 ASHIFT -1;
   r1 = r1 + r1;
   r1 = r1 + r1;
   r1 = r1 ASHIFT -1;

#if G722_BITEXACT
   r0 = r0 AND 0xffff00;
   r1 = r1 AND 0xffff00;
#endif

   // store
   M[r8 + $sbadpcm.XL_FIELD] = r1; // xL
   M[r8 + $sbadpcm.XH_FIELD] = r0; // xH
   L0 = 0;

   rts;


synthesis:

   L0 = $sbadpcm.HIST_BUF_SIZE/2;
   r3 = 12;
   r2 = r0 - r1; // recA
   r4 = r0 + r1; // recB

   // recA (rl-rh)
   I5 = &qmf_coef+1;
   r0 = M[r8 + $sbadpcm.decode.PTR_HIST_RECA_FIELD];
   I0 = r0;
   r10 = r3, M[I0, M1] = r2;
   r0 = I0;
   M[r8 + $sbadpcm.decode.PTR_HIST_RECA_FIELD] = r0;
   // even coef, recA history
   rMac = 0, r0 = M[I0, 1], r1 = M[I5, 2];
   do qmf_synth_even;
      rMac = rMac + r0*r1, r0 = M[I0, 1], r1 = M[I5, 2];
qmf_synth_even:
#if G722_BITEXACT
   r2 = rMac1;
#else
   r2 = rMac;
#endif

   // recb (rl+rh)
   I5 = &qmf_coef;
   r0 = M[r8 + $sbadpcm.decode.PTR_HIST_RECB_FIELD];
   I0 = r0;
   r10 = r3, M[I0, M1] = r4;
   r0 = I0;
   M[r8 + $sbadpcm.decode.PTR_HIST_RECB_FIELD] = r0;
   // odd coef, recB history
   rMac = 0, r0 = M[I0, 1], r1 = M[I5, 2];
   do qmf_synth_odd;
      rMac = rMac + r0*r1, r0 = M[I0, 1], r1 = M[I5, 2];
qmf_synth_odd:

   r0 = r2;
#if G722_BITEXACT
   r1 = rMac1;
#else
   r1 = rMac;
#endif


   r0 = r0 + r0;
   r0 = r0 + r0;
   r0 = r0 + r0;
   r0 = r0 + r0;

   r1 = r1 + r1;
   r1 = r1 + r1;
   r1 = r1 + r1;
   r1 = r1 + r1;


   M[I4, 1] = r0;
   M[I4, 1] = r1;

   L0 = 0;


   rts;



.ENDMODULE;

#endif //_SBADPCM_QMF
