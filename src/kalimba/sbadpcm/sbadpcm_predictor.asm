// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************


#ifndef _SBADPCM_PREDICTOR
#define _SBADPCM_PREDICTOR

#include "sbadpcm.h"

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Predictor
//
// DESCRIPTION:
//
// MODIFICATIONS:
//    6/17/09    scg - original implementation
//
// INPUTS:
//   r7 ptr to l/h internal state
//   r8 ptr to data object
//   I7 table of constants
//   M1 = 1
//   M0 = 0
//
// OUTPUTS:
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    I4/L4  - circular x-buffer
//    M3  - sample loop counter
//
// TRASHED REGISTERS:
//    r0-r6,r10,I0,I1,I5,I6,LOOP,M2
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY: 104
//    CYCLES:
//         bit exact: = 178
//         optimized: = 118
//
// NOTES:
// *****************************************************************************


.MODULE $M.SBAdpcm.Predictor;

   .CODESEGMENT SBADPCM_PREDICTOR_PM;
   .DATASEGMENT DM;

   .VAR/DM2 tempwd1;
   .VAR/DM2 tempdm2;
   .VAR r7temp;

   .VAR rx;
   .VAR px;
#if G722_BITEXACT
   .VAR r8save;
   .VAR mask0to7 = 0xffff00;
#endif
   .VAR pred_k1 = 32640*256;


Proc:
   M2 = -1;

// BLOCK4x
// ************************************************************************************

// PARREC
// ************************************************************************************

#if G722_BITEXACT
   M[r8save] = r8;
   r8 = M[mask0to7];
   r0 = M[r7 + $sbadpcm.Dxt_FIELD_OFFSET];
   r1 = M[r7 + $sbadpcm.SZx_FIELD_OFFSET];
   r1 = r1 + r0;
   r1 = r1 AND r8, r4 = M[I7, 1]; // r4=-23;
   M[px] = r1;
#else
   r0 = M[r7 + $sbadpcm.Dxt_FIELD_OFFSET];
   r1 = M[r7 + $sbadpcm.SZx_FIELD_OFFSET];
   r4 = M[I7, 1]; // r4=-23;
   M[px] = r0+r1;
#endif

// RECONS
// ************************************************************************************
#if G722_BITEXACT
   r1 = M[r7 + $sbadpcm.Sx_FIELD_OFFSET];
   r2 = r0 + r1;
   r2 = r2 AND r8, r1 = M[I7, 1]; // r1=128
   M[rx] = r2;
#else
   r1 = M[r7 + $sbadpcm.Sx_FIELD_OFFSET];
   M[rx] = r0 + r1;
   r1 = M[I7, 1]; // r1=128
#endif

// UPZERO
// ************************************************************************************
   // r0=Dxt0
   // r1=Sx1
   r10 = 6;
   r6 = M[pred_k1];
   I0 = r7 + $sbadpcm.Dxt_HIST_FIELD_OFFSET;
   I1 = r7 + $sbadpcm.Bx_FIELD_OFFSET;
   I5 = &tempwd1;
   I6 = &tempdm2;
   r3 = r0; // r3=Dxt0
   if Z r1 = r1 - r1;
   M[tempwd1] = r1;
   r2 = r0 ASHIFT r4, r0 = M[I0, M0];  // r2=SG0, r0=Dxt1
   r0 = r0 ASHIFT r4, M[I0, 1] = r3, M[I6, 0] = r0;  // SG1=DLT1>>15, Dxt1=Dxt0, tempdm2=r0(Dxt1)
   // for i=1:6. NOTE: overwrites x-hist by 1 sample
#if G722_BITEXACT
   do upzero_loop;
      r0 = r0 - r2, r1 = M[I1, 0], r3 = M[I5, 0];    // SGi==SG0?, r1=Bxi, r3=wd1(0 or 128)
      if NZ r3 = Null-r3;       // r3=wd2=+/-wd1
      rMac = r1 * r6, r0 = M[I0, 0], r1 = M[I6, 0];      // wd3=Bxi*32640, r0=Dxti, r1=Dxti-1
      r5 = rMac1; // no rounding
      r5 = r5 AND r8;
      r5 = r5 + r3, M[I0, 1] = r1;   // Bxi=wd2+wd3, Dxti=Dxti-1 (cannot saturate)
      r0 = r0 ASHIFT r4, M[I1, 1] = r5, M[I6, 0] = r0;  // SGi=DLTi>>15, tempdm2=r0(Dxti)
   upzero_loop:
#else
   rMac = M[I5, 0]; //rMac=wd1(0 or 128);
   r5 = -1.0;
   do upzero_loop;
      r0 = r0 - r2, r1 = M[I1, 0],r3 = M[I6, 0] ;         // SGi==SG0?, r1=Bxi, r3=Dxti-1
      if NZ rMac = rMac*r5, r0 = M[I0, M0];                // rMac=wd2=+/-wd1 r0=Dxti,
      rMac = rMac + r1 * r6, M[I0, 1] = r3, M[I6, 0] = r0; // rMac=BLi=wd2+Bxi*32640(wd3),Dxti=Dxti-1,tempdm2=r0(Dxti)
      r0 = r0 ASHIFT r4, M[I1, 1] = rMac, rMac = M[I5, 0];// SGi=DLTi>>15, store Bxi, rMac=wd1(0 or 128)
   upzero_loop:
#endif

// UPPOL2
// ************************************************************************************
   r5 = M[px];
   I0 = r7 + $sbadpcm.Px_FIELD_OFFSET;
   I1 = r7 + $sbadpcm.Ax_FIELD_OFFSET;

#if G722_BITEXACT
   r5 = r5 ASHIFT r4, r0 = M[I0, 1], r1 = M[I7, 1]; // r1 = -7
   r0 = r0 ASHIFT r4, r3 = M[I1, 1];         // r0 = sg1 = Px1>>15, r3=Ax1
   r3 = r3 + r3;
   r3 = r3 AND r8;
   r3 = r3 + r3;                           // r3 = wd1 = 4*AL1
   r3 = r3 AND r8;
   r6 = r0 - r5;
   if Z r3 = Null - r3;                    // +/-r3
   r3 = r3 AND r8;
   r3 = r3 ASHIFT r1, r0 = M[I0, 1], r2 = M[I7, 1];    // r3=wd2, r2=128
   r3 = r3 AND r8;

   r0 = r0 ASHIFT r4, r1 = M[I7, 1];     // r0 = sg2 = Px2>>15,  r1 = -1
   Null = r0 - r5;
   if NZ r2 = r2 * r1(int);      // r2 = wd3

   r2 = r2 + r3, rMac = M[I1, 0], r1 = M[I7, 1];         // r2=wd4=wd2+wd3(notsat), rMac=Ax2, r1=32512*256
   rMac = rMac * r1, r3 = M[I7, 1]; // r3 = -12288;
   r1 = rMac1;           // r1 = wd5 = 32512*Ax2, no rounding
   r1 = r1 AND r8;
   r1 = r1 + r2, r2 = M[I7, 1];         // r1 = Ax2 = wd5 + wd4, r2 = 12288;
   Null = r2 - r1;
   if LT r1 = r2;
   Null = r1 - r3;
   if LT r1 = r3;          // ax2 = min(max(ax2,-12288),-12288)
   // saved in UPPOL1
#else
   r5 = r5 ASHIFT r4, r0 = M[I0, 1], r1 = M[I7, 1]; // r1 = -7
   r0 = r0 ASHIFT r4, r3 = M[I1, 1];         // r0 = sg1 = Px1>>15, r3=Ax1
   r3 = r3 + r3;
   r3 = r3 + r3;                           // r3 = wd1 = 4*AL1
   r6 = r0 - r5;
   if Z r3 = Null - r3;                    // +/-r3
   r3 = r3 ASHIFT r1, r0 = M[I0, 1], r2 = M[I7, 1];    // r3=wd2, r2=128

   r0 = r0 ASHIFT r4, r1 = M[I7, 1];     // r0 = sg2 = Px2>>15,  r1 = -1
   Null = r0 - r5;
   if NZ r2 = r2 * r1(int);      // r2 = wd3

   r2 = r2 + r3, rMac = M[I1, 0], r1 = M[I7, 1];         // r2=wd4=wd2+wd3(notsat), rMac=Ax2, r1=32512*256
   rMac = rMac * r1, r3 = M[I7, 1]; // r3 = -12288;
   r1 = rMac;           // r1 = wd5 = 32512*Ax2, no rounding
   r1 = r1 + r2, r2 = M[I7, 1];         // r1 = Ax2 = wd5 + wd4, r2 = 12288;
   Null = r2 - r1;
   if LT r1 = r2;
   Null = r1 - r3;
   if LT r1 = r3;          // ax2 = min(max(ax2,-12288),-12288)
   // saved in UPPOL1
#endif


// UPPOL1
// ************************************************************************************
   // r6 = sg0-sg1
   r0 = r0 - r0, M[I1, -1] = r1, r3 = M[I7, 1]; // r0=0, // save Ax2, r3=-1
   r0 = r0 + r6, r1 = M[I1, 1], r2 = M[I7, 1]; // test, r1 = AL1, r2 = 192
   if NZ r2 = r2 * r3(int);  // r2=wd1
   r0 = M[I7, 1]; //r0 = 32640*256
   rMac = r0 * r1; // 32640*AL1
#if G722_BITEXACT
   r0 = rMac1;  // r0=wd2
   r0 = r0 AND r8;
#else
   r0 = rMac;  // r0=wd2
#endif
   r0 = r0 + r2, r1 = M[I1, -1], r2 = M[I7, 1];         // r0=Ax1, r1=Ax2, r2=15360
   r2 = r2 - r1;      // r2=wd3
   r3 = Null - r2;    // r3=-wd3
   Null = r2 - r0;
   if NEG r0 = r2;
   Null = r0 - r3;
   if NEG r0 = r3;
   M[I1, 1] = r0;


   // shift Rx,Px
   I0 = r7 + $sbadpcm.Rx_FIELD_OFFSET;
   r0 = M[rx];
   r2 = M[I0, 1];
   M[I0, M2] = r2;
   M[I0, 0] = r0;

   I0 = r7 + $sbadpcm.Px_FIELD_OFFSET;
   r0 = M[px];
   r2 = M[I0, 1];
   M[I0, M2] = r2;
   M[I0, 0] = r0;



// FILTEZ a=a+(Xn+Xn)*Hn
// ************************************************************************************
   I0 = r7 + $sbadpcm.Dxt_HIST_FIELD_OFFSET; // q.23
   I1 = r7 + $sbadpcm.Bx_FIELD_OFFSET;      // q.23
   r10 = 6;
#if G722_BITEXACT
   r2 = r2 - r2, r0 = M[I0, 1]; // r2=0,r0=first dxt
   do filtez_loop;
      r0 = r0 + r0, r1 = M[I1, 1];
      r0 = r0 AND r8;
      rMac = r0*r1, r0 = M[I0, 1];
      r1 = rMac1;
      r2 = r2 + r1;
      r2 = r2 AND r8;
   filtez_loop:
   M[r7 + $sbadpcm.SZx_FIELD_OFFSET] = r2;
#else
   rMac = rMac - rMac, r0 = M[I0, 1]; // rMac=0,r0=first dxt
   do filtez_loop;
      r0 = r0 + r0, r1 = M[I1, 1];
      rMac = rMac + r0*r1, r0 = M[I0, 1];
   filtez_loop:
   M[r7 + $sbadpcm.SZx_FIELD_OFFSET] = rMac;
#endif

// FILTEP/PREDIC
// ************************************************************************************
   I0 = r7 + $sbadpcm.Rx_FIELD_OFFSET;
   I1 = r7 + $sbadpcm.Ax_FIELD_OFFSET;
#if G722_BITEXACT
   r4 = r4 - r4, r0 = M[I0, 1]; // r4=0,r0=first Rx
   r0 = r0 + r0, r1 = M[I1, 1];
   r0 = r0 AND r8;

   rMac = r0*r1, r0 = M[I0, 1];
   r4 = rMac1;
   r4 = r4 AND r8;

   r0 = r0 + r0, r1 = M[I1, 1];
   r0 = r0 AND r8;

   rMac = r0*r1, r0 = M[I0, 1];
   r1 = rMac1;
   r4 = r4 + r1;
   r4 = r4 AND r8;

   r4 = r4 + r2;
   r4 = r4 AND r8;
   M[r7 + $sbadpcm.Sx_FIELD_OFFSET] = r4;
   r8 = M[r8save];
#else
                        r0 = M[I0, 1]; // r4=0,r0=first Rx
   r0 = r0 + r0, r1 = M[I1, 1];
   rMac = rMac + r0*r1, r0 = M[I0, 1];
   r0 = r0 + r0, r1 = M[I1, 1];
   rMac = rMac + r0*r1;
   M[r7 + $sbadpcm.Sx_FIELD_OFFSET] = rMac;
#endif

   rts;

.ENDMODULE;

#endif //_SBADPCM_PREDICTOR

