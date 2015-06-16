// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

#ifndef _SBADPCM_SCO_DECODE
#define _SBADPCM_SCO_DECODE


.MODULE $M.sbadpcm.Decoder.Sco_decode;

#ifdef BLD_PRIVATE
   .PRIVATE;
#endif

   .DATASEGMENT DM;
   .CODESEGMENT SBADPCM_DECODER_SCO_DECODE_PM;

// *****************************************************************************
// FUNCTION:
//    $sco_decoder.sbadpcm.validate:
//
// DESCRIPTION:
//    Verify sufficient output space for decode
//
// INPUTS:
//    r0 - Output space in samples
//    r5 - Input length in Bytes
//    r6 - Input length in words (rounded up)
//    r7 - Decoder Data Object
//    r8 - sbadpcm Data Object
//    I0,L0 - Payload packet as words (litte endian)
//
// OUTPUTS:
//    r1 - Output in samples, 0 to abort
//
// RESERVED REGISTERS
//    r5,r7,r9,I0,L0
//
// TRASHED REGISTERS:
//
// CPU USAGE:
//    D-MEMORY: xxx
//    P-MEMORY: xxx
//    CYCLES:   xxx
//
// NOTES:
// *****************************************************************************

$sco_decoder.sbadpcm.validate:
   // -- Number of samples to be processed --

   // Account for extra space in unpacking packets of odd length packets
   r0 = r0 - 2; // 2 samples per byte
   // Calculate output size (samples)
   r1 = 2 * r5 (int);
   // Check for space in output
   NULL = r0 - r1;
   if NEG r1=NULL;
   rts;


// *****************************************************************************
// FUNCTION:
//    $sco_decoder.sbadpcm.process:`
//
// DESCRIPTION:
//    Decoding SCO sbadpcm packets into DAC audio samples.
//
//    The SCO c-buffer contains auristream packet words to be decoded into DAC
//    audio samples. Refer to the function description of Frame_encode for
//    auristream packet word definition.  DAC audio could be mono-channel(left
//    only) or stereo-channels(both left and right).
//
// INPUTS:
//    r2    - Packet status
//    r5    - payload size in bytes
//    r6    - payload size in words (rounded up)
//    r7    - PLC Data Object
//    r8    - sbadpcm Data Object
//    I0,L0 - Input CBuffer
// OUTPUTS:
//    r5    - Output packet status
//    r7    - PLC Data Object
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

$sco_decoder.sbadpcm.process:

   .VAR temp1;
   .VAR temp2;

   // check if bit errors should be ignored
   //r1 = 0x0002;
   //r3 = M[r7 + $sco_pkt_handler.DECODER_PTR];
   //r3 = M[r3 + $sco_decoder.THRESHOLD];
   //NULL = r0 - r3;
   //if NEG r2 = r2 AND r1;

   // If packet error then no decode
   r5 = r2;
   NULL = r2 AND 0x0002;
   if NZ rts;

   // -- Save codec decoder structure --
   // -- Push rLink onto stack --
   $push_rLink_macro;
   M[temp1] = r7;
   M[temp2] = r5;


   //------------------------------------------------------------
   // Unpacking bitstream into code stream
   //------------------------------------------------------------
   M1 = 4;
   M0 = 1;

   // Get Output buffer
   r0 = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;
   I5 = I4;
   L5 = r1, r0 = M[I0, M0]; // r0=x[0]
   r2 = M[I5, 2]; // I5=I4+2;
   r10 = r6; // number of encoded words in payload
   r1 = r0 AND 0xff;


            // unpacking
            r2 = -8;
            do unpack_loop; // for i=0:N-1
               r0 = r0 LSHIFT r2, M[I5, M1] = r1;  // r0=msb[i], y[i*4+2]=r1=lsb[i],
               M[I4, M1] = r0, r0 = M[I0, M0];     //            y[i*4]  =r0=msb[i], r0=x[i+1]
               r1 = r0 AND 0xff;                   //            r1 = lsb[i]
            unpack_loop:

            // I0 is overread by 1
            r0 = M[I0, -1];

            L5 = 0; // reset L5


            ////////////////////////////////////////////
            // -- Stereo decoding merge back to here --
            ////////////////////////////////////////////

            //------------------------------------------------------------
            // Decoding code stream in left channel into sample stream
            //------------------------------------------------------------

            // get unpacking output
            r0 = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];
            call $cbuffer.get_write_address_and_size;
            I4 = r0;
            L4 = r1;
            L0 = 0;


            // decoding
            r0 = M[r7 + $sco_pkt_handler.PACKET_OUT_LEN_FIELD];
            r10 = r0 LSHIFT -1; // r10 = number of codes = num_samples/2

            call $sbadpcm.decoder.block_decode;

   L4 = Null;

   // -- Pop rLink from stack , restore data object pointer --
   r5 = M[temp2];
   r7 = M[temp1];
   jump $pop_rLink_and_rts;


.ENDMODULE;



#endif //_SBADPCM_SCO_DECODE
