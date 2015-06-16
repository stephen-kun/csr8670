// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************
#ifndef _SBADPCM_ENCODER
#define _SBADPCM_ENCODER

#include "stack.h"
#include "sbadpcm.h"


// *****************************************************************************
// MODULE:
//    $M.Adpcm.Encoder
//
// FUNCTION:
//    $adpcm.encoder.block_encode
//
// DESCRIPTION:
//    Coding PCM sample stream (I4,L4) into ADPCM code stream, in-place
//
//    Input Linear PCM samples are assumed to be left-justified (ie Q1.23)
//    Multiplexed SBADPCM output codes are stored in even words starting at I4/L4
//
// MODIFICATIONS:
//    6/15/09    scg - original implementation
//
// INPUTS:
//    r10 - number of codes (non-zero)
//    r8  - pointer to data object (encoder)
//    I4  - i/o data pointer
//    L4  - length of circular buffer (I4)
//
// OUTPUTS:
//    I4  - Updated i/o buffer pointer for next block
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    L4  - length of circular buffer (I4)
//
// TRASHED REGISTERS:
//    r0-r7,r10,rMAC,I0-I7,L0-L3,M0-M3,LOOP
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY: 49
//    CYCLES:
//        bitexact: 7 + r10 * (42 + QMF_analysis + Quant_LSBenc + Quant_HSBenc + 2*Pred)
//         = 7 + r10 * (42 + 63 + 157 + 45 + 364) = 7+r10*671 : MIPS=5.4
//
// NOTES:
// *****************************************************************************

.MODULE $M.SBAdpcm.Encoder;



   .DATASEGMENT DM;
   .CODESEGMENT SBADPCM_ENCODER_PM;

$sbadpcm.encoder.block_encode:

   // push rLink onto stack
   $push_rLink_macro;

   // init
   M3 = r10;
   M1 = 1;
   r0 = $ADDSUB_SATURATE_ON_OVERFLOW_MASK;
   M[$ARITHMETIC_MODE] = r0;

#if ENABLE_QMF_BYPASS
   // bypass qmf
   .VAR bypass_qmf = 0;
   r0 = M[r8 + $sbadpcm.decode.PTR_MODE_FIELD];
   r0 = M[r0 + $sbadpcm.MODE_TABLE.FLAGS_FIELD];
   r0 = r0 AND $sbadpcm.flags.BYPASS_QMF;
   M[bypass_qmf] = r0;
#endif

encoder_loop:

#if ENABLE_QMF_BYPASS
      r0 = M[bypass_qmf];
      if Z jump do_qmf_analysis;

      r0 = M[I4, 1];
      r1 = M[I4, -1];

      M[r8 + $sbadpcm.XL_FIELD] = r0; // xL
      M[r8 + $sbadpcm.XH_FIELD] = r1; // xH
      jump qmf_analysis_done;

do_qmf_analysis:
#endif

      call $M.Adpcm.QMF.analysis;

qmf_analysis_done:
      M0 = 0;
      // BLOCK 1L, SUBTRA
      r0 = M[r8 + $sbadpcm.XL_FIELD]; // {opt} use index for these 3 reads[?]
      r1 = M[r8 + $sbadpcm.DETL_FIELD];
      r2 = M[r8 + $sbadpcm.SL_FIELD];
      r0 = r0 - r2;
#if G722_BITEXACT
      r0 = r0 AND 0xffff00;
#endif
      M[r8 + $sbadpcm.EL_FIELD] = r0; // debug


      // BLOCK 1L,2L,3L
      r2 = M[r8 + $sbadpcm.decode.PTR_MODE_FIELD];
      I0 = r2 + $sbadpcm.MODE_TABLE.PTRCONST_LSB_FIELD;
      r2 = M[I0, M1];
      I5 = r2, r2 = M[I0, M1];
      I2 = r2;
      I3 = r8 + $sbadpcm.IL_FIELD;
      call $M.SBAdpcm.Quantize.encoder_proc;

      // BLOCK 1H, SUBTRA
      r0 = M[r8 + $sbadpcm.XH_FIELD]; // {opt} use index for these 3 reads[?]
      r1 = M[r8 + $sbadpcm.DETH_FIELD];
      r2 = M[r8 + $sbadpcm.SH_FIELD];
      r0 = r0 - r2;
#if G722_BITEXACT
      r0 = r0 AND 0xffff00;
#endif
      M[r8 + $sbadpcm.EH_FIELD] = r0; // debug


      // BLOCK 1H,2H,3H
      r2 = M[r8 + $sbadpcm.decode.PTR_MODE_FIELD];
      I0 = r2 + $sbadpcm.MODE_TABLE.PTRCONST_HSB_FIELD;
      r2 = M[I0, M1];
      I5 = r2, r2 = M[I0, M1];
      I2 = r2;
      I3 = r8 + $sbadpcm.IH_FIELD;
      call $M.SBAdpcm.Quantize.encoder_proc;


      // BLOCK4L
      r7 = r8 + $sbadpcm.XL_FIELD;
      I7 = &$M.SBAdpcm.memory.PredConst;
      call $M.SBAdpcm.Predictor.Proc;

      // BLOCK4H
      r7 = r8 + $sbadpcm.XH_FIELD;
      I7 = &$M.SBAdpcm.memory.PredConst;
      call $M.SBAdpcm.Predictor.Proc;

      // mux Il and Ih and store
      r0 = M[r8 + $sbadpcm.IH_FIELD];
      r1 = M[r8 + $sbadpcm.IL_FIELD];
      r0 = r0 LSHIFT 6;
      r1 = r1 OR r0;
      M[I4, 2] = r1;

      // next sample
      M3 = M3 - M1;
   if NZ jump encoder_loop;

   M[$ARITHMETIC_MODE] = Null;

   // pop rLink from stack and return
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif //_ADPCM_ENCODER
