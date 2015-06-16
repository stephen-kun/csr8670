// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************
#ifndef _SBADPCM_DECODER
#define _SBADPCM_DECODER

#include "stack.h"
#include "sbadpcm.h"


// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Decoder
//
// FUNCTION:
//    $sbadpcm.decoder.block_decode
//
// DESCRIPTION:
//    Decoding SBADPCM code stream (I4,L4) into PCM sample stream, in-place
//
//    Multiplexed SBADPCM input codes are stored in even words starting at I4/L4
//    Output Linear PCM samples are left-justified
//
// MODIFICATIONS:
//    7/06/09    scg - original implementation
//
// INPUTS:
//    r10 - number of codes (non-zero)
//    r8  - pointer to data object (decoder)
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
//    P-MEMORY: 46
//    CYCLES:
//      bitexact: 6 + r10 * (40 + Quant_LSBdec + Quant_HSBdec + 2*Pred + QMF_synth)
//       = 6 + r10 * (40 + 30 + 23 + 364 + 73) = 6+r10*530 : MIPS=4.2
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.Decoder;


   .DATASEGMENT DM;
   .CODESEGMENT SBADPCM_DECODER_PM;

   .VAR mode_ptr;

$sbadpcm.decoder.block_decode:

   // -- Push rLink onto stack --
   $push_rLink_macro;

   // init
   M3 = r10;
   M1 = 1;
   M0 = 0;
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

decoder_loop:

      r0 = M[r8 + $sbadpcm.decode.PTR_MODE_FIELD];
      I0 = r0 + $sbadpcm.MODE_TABLE.PTRCONST_LSB_FIELD; // I0 = &MUX_SHIFT_FIELD

      // DEMUX
      r0 = M[I4, 0]; // r0=code
      r2 = -6;
      r1 = r0 LSHIFT r2, r2 = M[I0, M1]; // r2=PTRCONST_LSB_FIELD
      M[r8 + $sbadpcm.IH_FIELD] = r1;
      r0 = r0 AND 0x3f;
      M[r8 + $sbadpcm.IL_FIELD] = r0;

      // BLOCK 5L,2L,3L
      I5 = r2, r2 = M[I0, M1];         // r2=PTRTABLES_LSB_FIELD
      I2 = r2;
      I3 = r8 + $sbadpcm.DLt_FIELD;
      r1 = M[r8 + $sbadpcm.DETL_FIELD];
      call $M.SBAdpcm.Quantize.decoderLSB_proc;

      // RECONS
#if G722_BITEXACT
      r3 = 0xffff00;
      r0 = M[r8 + $sbadpcm.EL_FIELD];
      r1 = M[r8 + $sbadpcm.SL_FIELD];
      r2 = r0 + r1;
      r2 = r2 AND r3;
      M[r8 + $sbadpcm.XL_FIELD] = r2;
#else
      r0 = M[r8 + $sbadpcm.EL_FIELD];
      r1 = M[r8 + $sbadpcm.SL_FIELD];
      r0 = r0 + r1;
      M[r8 + $sbadpcm.XL_FIELD] = r0;
#endif

      // BLOCK4L
      r7 = r8 + $sbadpcm.XL_FIELD;
      I7 = &$M.SBAdpcm.memory.PredConst;
      call $M.SBAdpcm.Predictor.Proc;

      r0 = M[r8 + $sbadpcm.decode.PTR_MODE_FIELD];
      I0 = r0 + $sbadpcm.MODE_TABLE.PTRCONST_HSB_FIELD;
      r2 = M[I0, M1];

      // BLOCK 2H,3H
      I5 = r2, r2 = M[I0, M1]; // r2=PTRTABLES_HSB_FIELD
      I2 = r2;
      I3 = r8 + $sbadpcm.DHt_FIELD;
      r0 = M[r8 + $sbadpcm.IH_FIELD];
      r1 = M[r8 + $sbadpcm.DETH_FIELD];
      call $M.SBAdpcm.Quantize.decoderHSB_proc;

      // BLOCK4H
      r7 = r8 + $sbadpcm.XH_FIELD;
      I7 = &$M.SBAdpcm.memory.PredConst;
      call $M.SBAdpcm.Predictor.Proc;
      r1 = M[r8 + $sbadpcm.RH_FIELD + 0];
      M[r8 + $sbadpcm.XH_FIELD] = r1;
      r0 = M[r8 + $sbadpcm.XL_FIELD];

      // saturate to halfscale
      r0 = r0 + r0;
      r0 = r0 ASHIFT -1;
      r1 = r1 + r1;
      r1 = r1 ASHIFT -1;
#if G722_BITEXACT
      r0 = r0 AND 0xffff00;
      r1 = r1 AND 0xffff00;
#endif

#if ENABLE_QMF_BYPASS
      Null = M[bypass_qmf];
      if Z jump do_qmf_synthesis;

      // write the lsb/hsb samples directly
      M[I4, 1] = r0;
      M[I4, 1] = r1;

      jump qmf_synthesis_done;

do_qmf_synthesis:
#endif

      // QMF filterbank
      call $M.Adpcm.QMF.synthesis;

qmf_synthesis_done:

      // next code
      M3 = M3 - M1;
   if NZ jump decoder_loop;

   M[$ARITHMETIC_MODE] = Null;

   // pop rLink from stack and return
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif //_SBADPCM_DECODER

