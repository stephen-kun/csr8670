// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCDEC_SAMPLE_RECONSTRUCTION_INCLUDED
#define SBCDEC_SAMPLE_RECONSTRUCTION_INCLUDED

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.sample_reconstruction
//
// DESCRIPTION:
//    Reconstruction of subband samples
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    rMAC, r0-r8, I0-I2, M0, M1
//
// NOTES:
//  Reconsturction of subband samples:
//
//    @verbatim
//    for ch = 1:nrof_channels,
//       for sb = 1:nrof_subbands,
//          levels(ch,sb) = 2^ bits(ch,sb) - 1;
//       end
//    end
//
//    for blk = 1:nrof_blocks,
//       for ch = 1:nrof_channels,
//          for sb = 1:nrof_subbands,
//             if levels(ch,sb) > 0
//                sb_sample(blk,ch,sb) = 2^(scale_factor(ch,sb)+1) * ...
//                     ((audio_sample(blk,ch,sb)*2+1)/levels(ch,sb) - 1);
//             else
//                sb_sample(blk,ch,sb) = 0;
//             end
//          end
//       end
//    end
//    @endverbatim
//
// *****************************************************************************
.MODULE $M.sbcdec.sample_reconstruction;
   .CODESEGMENT SBCDEC_SAMPLE_RECONSTRUCTION_PM;
   .DATASEGMENT DM;

   $sbcdec.sample_reconstruction:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.SAMPLE_RECONSTRUCTION_ASM.SAMPLE_RECONSTRUCTION.PATCH_ID_0, r1)
#endif

   r5 = 128;
   r8 = M[r9 + $sbc.mem.LEVELRECIP_COEFS_FIELD];
   r8 = r8 - 2;
   r1 = M[r9 + $sbc.mem.AUDIO_SAMPLE_FIELD];
   I0 = r1; // I0 = audio_sample(blk,ch,sb)
   r1 = M[r9 + $sbc.mem.BITS_FIELD];
   I1 = r1; // I1 = bits(ch,sb)
   r1 = M[r9 + $sbc.mem.SCALE_FACTOR_FIELD];
   I2 = r1; // I2 = scale_factor(ch,sb)





   r7 = M[r9 + $sbc.mem.NROF_CHANNELS_FIELD];
   r1 = M[r9 + $sbc.mem.NROF_SUBBANDS_FIELD];

   r1 = r1 * r7 (int);
   // M0 = nrof_channels * nrof_subbands
   M0 = r1;
   // M2 = -M0
   M2 = -r1;
   // M3 = 2*M0
   M3 = r1 + r1;


   r2 = M[r9 + $sbc.mem.NROF_BLOCKS_FIELD];

   r2 = r1 * r2 (int);
   M1 = -r2;
   // M1 = -nrof_channels * nrof_subbands * nrof_blocks + 1;
   M1 = M1 + 1;

   // for (ch=0, ch<nrof_channels; ch++)
   chan_loop:

      r6 = M[r9 + $sbc.mem.NROF_SUBBANDS_FIELD];

      // for (sb=0, sb<nrof_subbands; sb++)
      subband_loop:

         r10 = M[r9 + $sbc.mem.NROF_BLOCKS_FIELD];

         // r1 = bits(ch,sb)
         r1 = M[I1, 1];
         Null = Null + r1,     r2 = M[I2, 1];

         // if bits=0 then fill with zeros
         if Z jump zero_sample;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.SAMPLE_RECONSTRUCTION_ASM.SAMPLE_RECONSTRUCTION.PATCH_ID_1, r3)
#endif

            // r2 = scale_factor(ch,sb) + 1
            r2 = r2 + 1;
            // r3 = 2^(23+bits) / levels

            r3 = M[r8 + r1];

            // r1 = scale_factor - bits + 1
            r1 = r2 - r1;
            // r4 = 2^(8+scale_factor)
            r4 = r5 ASHIFT r2;
            // r0 = audio_sample(blk,ch,sb)
            r0 = M[I0, M0];

            // for (blk=0, blk<nrof_blocks; blk++)
            do block_loop;

               // r0 = (audio_sample*2 + 1) * 2^7
               r0 = r0 LSHIFT 8;
               r0 = r0 + 128;

               // multiply by (2^(23+bits) / levels)
               rMAC = r0 * r3 (UU);
               // result shifted by (scale_factor - bits + 1)
               r0 = rMAC LSHIFT r1;
               // subtract 2^(8+scale_factor)
               // and r0 = audio_sample(blk,ch,sb)
               rMAC = r0 - r4,      r0 = M[I0, M2];

               // store sb_sample back
               M[I0, M3] = rMAC;
            block_loop:

            // dummy read to reposition I0
            r0 = M[I0, M2];
            jump done_block_loop;

         zero_sample:

            // for (blk=0, blk<nrof_blocks; blk++)
            do zero_loop;
               // write 0 for this block
               M[I0, M0] = r1;
            zero_loop:

         done_block_loop:
         // dummy read to reposition I0
         r1 = M[I0, M1];
         r6 = r6 - 1;
      if NZ jump subband_loop;

      r7 = r7 - 1;
   if NZ jump chan_loop;
   rts;

.ENDMODULE;

#endif