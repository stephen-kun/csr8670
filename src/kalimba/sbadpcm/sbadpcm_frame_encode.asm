// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

#ifndef _SBADPCM_FRAME_ENCODE
#define _SBADPCM_FRAME_ENCODE

#include "sbadpcm.h"

.MODULE $M.sbadpcm.encoder.Frame_encode;

   .DATASEGMENT DM;
   .CODESEGMENT SBADPCM_ENCODER_FRAME_ENCODE_PM;

// *****************************************************************************
// FUNCTION:
//    $sbadpcm.encoder.frame_encode
//
// DESCRIPTION:
//    Encoding ADC audio samples into sbadpcm packets.
//    Currently only supports 8-bit mode
//
// INPUTS:
//    r5 - pointer to codec encoder object structure
//          - $codec.ENCODER_OUT_BUFFER_FIELD
//          - $codec.ENCODER_IN_LEFT_BUFFER_FIELD
//          - $codec.ENCODER_IN_RIGHT_BUFFER_FIELD
//          - $codec.ENCODER_MODE_FIELD
//    r8 - pointer to sbadpcm encoder data object structure
//          - $sbadpcm.encode.PTR_MODE_FIELD
//          - $sbadpcm.encode.PTR_ENC_HISTX_FIELD
//          - $sbadpcm.encode.BLKSIZE_FIELD
//          - etc zeroed
//
// OUTPUTS:
//    r0 - codec status, writen into codec structure $codec.ENCODER_MODE_FIELD
//          - $codec.SUCCESS
//          - $codec.NOT_ENOUGH_INPUT_DATA
//          - $codec.NOT_ENOUGH_OUTPUT_SPACE
//
// TRASHED REGISTERS:
//    Assumes everything
//
// CPU USAGE:
//    D-MEMORY: xxx
//    P-MEMORY: xxx
//    CYCLES:   xxx
//
// NOTES:
// *****************************************************************************

   .VAR codec_struc;
   .VAR packet_length;

$sbadpcm.encoder.frame_encode:

   // -- Push rLink onto stack --
   $push_rLink_macro;

   // -- Save codec encoder structure --
   M[codec_struc] = r5;

   //------------------------------------------------------------
   // Calculating packet/sample lengths
   //------------------------------------------------------------

   // -- Check that we have enough input PCM audio data --
   r6 = $codec.NOT_ENOUGH_INPUT_DATA;
   r0 = M[r5 + $codec.ENCODER_IN_LEFT_BUFFER_FIELD];           // Get input cbuffer pointer
   call $cbuffer.calc_amount_data;
   r3 = r0 ASHIFT -2;                                          // r3 = #words needed to encode available samples = pcm_samples/4
   if Z jump Exit;                                             // if <4 pcm samples (1 encoded word/2 8-bit codes) are available, exit

      // check that we have enough output space for ADPCM packet
      r6 = $codec.NOT_ENOUGH_OUTPUT_SPACE;
      r0 = M[r5 + $codec.ENCODER_OUT_BUFFER_FIELD];
      call $cbuffer.calc_amount_space;
      Null = r0 - 1;                                           // if <1 ouput word available, then exit
      if NEG jump Exit;

         // calculate common available data and space
         Null = r0 - r3;
         if POS r0 = r3;                                       // r0 = min(sco_out_space, pcm_samples/4)

         // limit output space for avoiding over processing
         r1 = M[r8 + $sbadpcm.encode.BLKSIZE_FIELD];
         r1 = r1 LSHIFT -2;                                    // pcm_samples to packed words
         Null = r0 - r1;
         if POS r0 = r1;

         // r0 = min(sco_out_space, pcm_samples/4, pcm_blksize/4)
         M[packet_length] = r0;                                // Save the number of packed encoded words

         //------------------------------------------------------------
         // Coding sample stream into code stream
         //------------------------------------------------------------

         // get encoder input/output, in-place
         r0 = M[r5 + $codec.ENCODER_IN_LEFT_BUFFER_FIELD];
         call $cbuffer.get_read_address_and_size;
         I4 = r0;
         L4 = r1;

         // -- encoding --
         r0 = M[packet_length];
         r10 = r0 LSHIFT 1;                                    // #codes = 2*packet_len
         call $sbadpcm.encoder.block_encode;

         // restore codec structure, data object and table pointer
         r5 = M[codec_struc];

         //------------------------------------------------------------
         // Packing code stream into bit stream
         //------------------------------------------------------------

         M1 = 2;
         // get encoder i/o pointers
         r0 = M[r5 + $codec.ENCODER_IN_LEFT_BUFFER_FIELD];
         call $cbuffer.get_read_address_and_size;
         I0 = r0;
         L0 = r1;

         r0 = M[r5 + $codec.ENCODER_OUT_BUFFER_FIELD];
         call $cbuffer.get_write_address_and_size;
         I4 = r0, r0 = M[I0, M1];                              // r0=msb[0]
         L4 = r1;

         r2 = 8;
         r10 = M[packet_length];                               // Restore the number of packed encoded words

         r0 = r0 LSHIFT r2, r1 = M[I0, 2];                     // r0= msb[0]<<8,             r1=lsb[0]
         r1 = r1 OR r0, r0 = M[I0, 2];                         // r1=(msb[0]<<8)|lsb[0],     r0=msb[1]
         do loop_pack;                                         // for i=0:N-1
            r0 = r0 LSHIFT r2, r1 = M[I0, 2], M[I4, 1] = r1;   // r1=msb[i+1]<<8,            r1=lsb[i+1], y[i]=r1
            r1 = r1 OR r0, r0 = M[I0, 2];                      // r1=(msb[i+1]<<8)|lsb[i+1], r0=msb[i+2]
         loop_pack:

         // I0 was over-read by 6 samples
         M1 = -6;
         r1 = M[I0, M1];

         // update encoder i/o pointers --
         r0 = M[r5 + $codec.ENCODER_OUT_BUFFER_FIELD];
         r1 = I4;
         call $cbuffer.set_write_address;
         L4 = 0;

         r0 = M[r5 + $codec.ENCODER_IN_LEFT_BUFFER_FIELD];
         r1 = I0;
         call $cbuffer.set_read_address;
         L0 = 0;

         // encoder succeeds
         r6 = $codec.SUCCESS;

Exit:

   //------------------------------------------------------------
   // Returning status
   //------------------------------------------------------------

   // -- Prior to exit, r6 holds STATUS --
   r0 = r6;

   // -- Update $codec.ENCODER_STRUC with STATUS --
   M[r5 + $codec.ENCODER_MODE_FIELD] = r6;

   // -- Pop rLink from stack --
   jump $pop_rLink_and_rts;


// *****************************************************************************
// FUNCTION:
//    $sbadpcm.encoder.reset_encoder
//
// DESCRIPTION:
//    Initialize/reset encoder data object
//
// INPUTS:
//    r8 - pointer to sbadpcm encoder data object structure
//          - $sbadpcm.encode.PTR_MODE_FIELD
//          - $sbadpcm.encode.PTR_ENC_HISTX_FIELD
//          - $sbadpcm.encode.BLKSIZE_FIELD
//          - etc zeroed
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//
//
// CPU USAGE:
//    D-MEMORY: xxx
//    P-MEMORY: xxx
//    CYCLES:   xxx
//
// NOTES:
// *****************************************************************************

$sbadpcm.encoder.reset_encoder:

   // r8 = pointer to sbadpcm encoder data object structure
   // initialize
   jump $sbadpcm.reset;

.ENDMODULE;

#endif //_SBADPCM_FRAME_ENCODE
