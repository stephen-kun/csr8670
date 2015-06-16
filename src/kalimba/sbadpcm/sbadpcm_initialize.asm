// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

// *****************************************************************************
// FILE: sbadpcm_initialize.asm - SBADPCM initialization routine
// *****************************************************************************

#ifndef _SBADPCM_INITIALIZE
#define _SBADPCM_INITIALIZE

#include "sbadpcm.h"

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Object_initialize
//
// FUNCTION:
//    $sbadpcm.reset
//
// DESCRIPTION:
//    Initialize SBADPCM data object
//
// MODIFICATIONS:
//    6/15/09    scg - original implementation
//
// INPUTS:
//    r8 - pointer to ADPCM data object (encoder/decoder)
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-r1,r10,I0-I2, LOOP, L0,L1,M1
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    L4  - length of circular buffer (I4)
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY: 31
//    CYCLES:   meaningless
//
// NOTES:
// *****************************************************************************


.MODULE $M.SBAdpcm.Object_initialize;


   .CODESEGMENT SBADPCM_OBJECT_INITIALIZE_PM;

$sbadpcm.reset:

   M1 = 1;

   // clear the internal state
   r1 = $sbadpcm.START_INTERNAL_FIELD;
   I0 = r8 + r1;
   r10 = $sbadpcm.decode.STRUC_SIZE - r1;

   r0 = 0;
   do clear_internal_loop;
      M[I0, 1] = r0;
   clear_internal_loop:

   // detL=32, detH=8
   r0 = 32;
   M[r8 + $sbadpcm.DETL_FIELD] = r0;
   r0 = 8;
   M[r8 + $sbadpcm.DETH_FIELD] = r0;

   // clear filterbank history buffer
   I2 = r8;
   r0 = M[I2, 1];
   r0 = M[r0 + $sbadpcm.MODE_TABLE.FLAGS_FIELD];
   Null = r0 AND $sbadpcm.flags.MODE_ENCODE;
   if NZ jump encoder;
      // decoder: clear reca and recb filter histories
      r10 = $sbadpcm.REC_HIST_BUF_SIZE;
      r0 = r0 - r0, r1 = M[I2, M1];
      I0 = r1, r1 = M[I2, M1];
      I1 = r1;
      L0 = r10;
      L1 = r10;
      do clear_recarecb;
         M[I0, 1] = r0;
         M[I1, 1] = r0;
      clear_recarecb:
      L0 = 0;
      L1 = 0;
      rts;
encoder:
      // decoder: clear reca and recb filter histories
      r10 = $sbadpcm.HIST_BUF_SIZE;
      r0 = r0 - r0, r1 = M[I2, M1];
      I0 = r1;
      L0 = r10;
      do clear_xhist;
         M[I0, 1] = r0;
      clear_xhist:
      L0 = 0;
      rts;

.ENDMODULE;




#endif //_ADPCM_INITIALIZE
