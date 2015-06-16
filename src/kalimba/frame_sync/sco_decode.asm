// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    SCO MetaData Library
//
// DESCRIPTION:
//    This library provides routines to copy SCO data from the port to buffers.
//    It reads the meta data packet with in-band headers from from the port and
//    writes the packet with a limitted in-band header to a buffer.
//
//    Each packet in the input buffer is processed by the appropriate decoder
//    and optionally the Packet Loss Conealment (PLC) algorothm.  The resulting
//    PCM data is written to the output buffer.
//
//    port-->[$frame_sync.sco_port_handler]-->buffer-->[$frame_sync.sco_decode]-->buffer
//
//
// *****************************************************************************

#include "frame_codec.h"
#include "stack.h"
#include "frame_sync_library.h"
#include "wall_clock.h"
#include "message.h"
#include "cbuffer.h"

#define USES_RCV_TIMING

// *****************************************************************************
// MODULE:
//    $frame_sync.sco_initialize
//
// DESCRIPTION:
//    Initialize the SCO medta data logic plus the decoder and PLC algorithm
//
// INPUTS:
//    - r7 = pointer to sco.decoder data structure:
//
// OUTPUTS:
//    - none
//
// RESERVED REGISTERS:
//    - none
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//    If input is not connected, purge the input and exit
//    Buffering state - If amount of data in input cbuffer < buffering
//                      threshold, exit
//    Decoding state - Do normal decoding and exit
//    Still need to implement adaptive buffering threshold logic
//    Still need to call reset decoder - disconnected to connected state
//    Return code is put into M[r5 + $frame_sync.stream_decode.MODE_FIELD]
//       $codec.SUCCESS is returned on success
//       $codec.NOT_ENOUGH_INPUT_DATA is returned if unconnected or buffering
//       other errors may be returned by the low-level encoder
// *****************************************************************************

.MODULE $M.frame_sync.sco_initialize;
   .CODESEGMENT FRAME_SYNC_SCO_INITIALIZE_PM;
   .DATASEGMENT DM;

$frame_sync.sco_initialize:
   $push_rLink_macro;
    // reset packet count
   M[r7 + $sco_pkt_handler.PACKET_COUNT_FIELD] = Null;
   // reset bad packet count
   M[r7 + $sco_pkt_handler.BAD_PACKET_COUNT_FIELD] = Null;
   // reset loss rate
   M[r7 + $sco_pkt_handler.PACKET_LOSS_FIELD] = Null;
   // set inverse limit = 1/limit for loss stats
   r1 = M[r7 + $sco_pkt_handler.STAT_LIMIT_FIELD];
   rMAC = 1;
   Div = rMAC/r1;
   r1 = DivResult;
   r1 = r1 ASHIFT -1;
   M[r7 + $sco_pkt_handler.INV_STAT_LIMIT_FIELD] = r1;

   // Initialize Decoder
   r8 = M[r7 + $sco_pkt_handler.DECODER_PTR];
   r1 = M[r8 + $sco_decoder.RESET_FUNC];
   r8 = M[r8 + $sco_decoder.DATA_PTR];
   r9 = r8; // to pass data object pointer in a way that is matching unified i/f
   call r1;

   // Initialize PLC
   r1 = M[r7 + $sco_pkt_handler.PLC_RESET_PTR];
   if Z jump $pop_rLink_and_rts;
   r7 = M[r7 + $sco_pkt_handler.PLC_DATA_PTR_FIELD];
   call r1;
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.sco_port_handler
//
// DESCRIPTION:
//    Poll the SCO port checking for packets.  Provided there is sufficient space
//    for a complete packet in the buffer and there is any data in the port, this function
//    will read the port.  If the data represents a valid packet it is written to
//    the buffer.  If it does not, the connents of the port are read and thrown away.
//    This effectively purges the port.  Header words are read as 16-bit little-endian,
//    With no saturation.  The Payload is also read as 16-bit words.  However, the endian
//    and saturation modes are configuable through the sco.decoder data structure.  Port
//    packets are aligned on 16-bit word boundries.  If the payload is an odd number of bytes
//    it is padded to maintain word alignment.  The payload size field does not include the
//    padding.
//
//   The packet format in the port is:
//      [sync word        ]   (0x5C5C)
//      [header size      ]   (size in words, 16-bit)
//      [payload size     ]   (size in bytes, 8-bit)
//      [0x00  ¦ status   ]
//      [ (extra header)  ]   (not used)
//      -------------------
//      [  (payload)      ]
//
//   DSP buffers are 24-bits wide.  The packet format in the buffer is:
//      [ 0x00 ¦ payload size   ]   (size in bytes, 8-bit)
//      [ 0x00 ¦ 0x00  ¦ status ]
//      ------------------------
//      [       (payload)       ]
//
// INPUTS:
//    - r8 = pointer to sco.decoder data structure:
//
// OUTPUTS:
//    - none
//
// RESERVED REGISTERS:
//    - none
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//      Conditions for a valid packet are:
//        1) Amount of Data in port is >= 4 words
//        2) First word read is 0x5C5C (sync word)
//        3) Amount of Data in port is >= header size provided in header
//        4) Amount of Data in port is >= header plus payload size provided in header
//
// *****************************************************************************
.MODULE $M.frame_sync.sco_port_handler;
   .CODESEGMENT FRAME_SYNC_SCO_PORT_HANDLER_PM;
   .DATASEGMENT DM;

   // Size of last packet written to CBuffer
   .VAR $sco_last_packet_size=0;
   // Amount of data in Port
   .VAR $sco_port_data=0;

   // The amount of metadata that we read from the header
   .CONST METADATA_TO_READ    5;
   // The amount of metadata we write into the buffer 
   // for sco_decode to read
   .CONST METADATA_TO_WRITE   3;

$frame_sync.sco_port_handler:

   $push_rLink_macro;
jp_do_again:
   // Check SCO Port for Data
   r0 = M[r8 + $sco_pkt_handler.SCO_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   M[$sco_port_data]=r0;
   if Z jump $pop_rLink_and_rts;
   // Check CBuffer for space
   r0 = M[r8 + $sco_pkt_handler.INPUT_PTR_FIELD];
   call $cbuffer.calc_amount_space;
   Null = r0 - M[$sco_last_packet_size];
   if NEG jump $pop_rLink_and_rts;
   // Get Port
   r0 = M[r8 + $sco_pkt_handler.SCO_PORT_FIELD];
   call $cbuffer.get_read_address_and_size.its_a_port;
   r6 = r0;
   // Get CBuffer
   r0 = M[r8 + $sco_pkt_handler.INPUT_PTR_FIELD];
#ifdef BASE_REGISTER_MODE
    call $cbuffer.get_write_address_and_size_and_start_address;
    push r2;
    pop  B4;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I4 = r0;
   L4 = r1;
   // Check Header
   r5 = M[$sco_port_data];
   Null = r5 - METADATA_TO_READ;
   if NEG jump jp_purge;
   r0 = M[r6];           // Sync
   r3 = M[r6];           // Header size
   r5 = r5 - METADATA_TO_READ;
   // Payload size (bytes)
   r1 = M[r6];
   M[I4,1]=r1;
   r9 = r1 + 1;
   // Status
   r4 = M[r6];
   M[I4,1]=r4;
   // Timestamp
   r1 = M[r6];
   M[I4,1]=r1;

#ifdef DEBUG_ON // Debug
   M[$plc_status]=r4;
   r4 = r4 LSHIFT -8;
   r4 = r4 AND 0xFF;
   M[$plc_fsco] = r4;
#endif

   // Check Sync word
   Null = r0 - 0x5c5c;
   if NZ jump jp_purge;
   // Dump remainder of header
   r10 = r3 - METADATA_TO_READ;        // Remainder of header in words
   Null = r5 - r10;
   if NEG jump jp_purge;
   r5 = r5 - r10;
   // Get Port
   do lp_skip_hdr;
       r0 = M[r6];
       nop;
   lp_skip_hdr:
   // Payload in words
   r10 = r9 ASHIFT -1;
   Null  = r5 - r10;
   if NEG jump jp_purge;
   r5  = r5 - r10;
   // Set Payload Configuration Payload
   r0 = M[r8 + $sco_pkt_handler.SCO_PAYLOAD_FIELD];
   call $cbuffer.get_read_address_and_size.its_a_port;
   // Set Packet size
   r0 = r10 + METADATA_TO_WRITE;
   M[$sco_last_packet_size]=r0;
   // Copy Port to Buffer
   do lp_copy;
      r1 = M[r6];
      M[I4,1] = r1;
lp_copy:
   // Update CBuffer
   L4 = Null;
   r0 = M[r8 + $sco_pkt_handler.INPUT_PTR_FIELD];
   r1 = I4;
   call $cbuffer.set_write_address;

#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B4;
#endif

   // Update Port
   // force an MMU buffer set
   Null = M[$PORT_BUFFER_SET];

#ifdef USES_RCV_TIMING
   jump jp_do_again;
#else
   jump $pop_rLink_and_rts;
#endif

jp_purge:
  // Payload minus amount read
  r2 = M[$sco_port_data];
  r10 = r5;
  // Update Purge Count
#ifdef DEBUG_ON
   r0 = M[$sco_purge];
   r0 = r0 + r2;
   M[$sco_purge]=r0;
#endif

   // Purge port
   do lp_purge;
      r1 = M[r6];
      nop;
lp_purge:
   L4 = Null;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B4;
#endif
   // force an MMU buffer set
   Null = M[$PORT_BUFFER_SET];
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.sco_decode
//
// DESCRIPTION:
//    Perform appropriate decoder and optional PLC operation in SCO packets.
//    operates on the buffer written to by $frame_sync.sco_port_handler.
//
//   DSP buffers are 24-bits wide.  The packet format in the buffer is:
//      [ 0x00 ¦ payload size   ]   (size in bytes, 8-bit)
//      [ 0x00 ¦ 0x00  ¦ status ]
//      ------------------------
//      [       (payload)       ]
//
//    The operation is:
//      1) Check the port.  If it is not connected then purge the input buffer
//         and exit.
//      2) Check the input Buffer.  If it is empty then exit.  Otherwise, calculate
//         and save where the buffer's read pointer should be after the packet is
//         processed.  Save the current packet's payload size in bytes and status.
//      3) Get the amount of space in the output buffer and call the decoder
//         validate function.  The validate function returns the decoded packet
//         size in samples.  The validate function returns zero to indicate
//         insufficient space.  If zero then exit
//      4) Collect debug statistics on packet status
//      5) Call decoder's decode function to generate samples in the output buffer.
//         The decode function returns the output packet status.
//      6) Update the input buffer's read pointer.  If the output packet status
//         is negative then exit without updating the output buffer.
//      7) Update statistics for output packet error rates.
//      8) If PLC is enabled, then call the PLC processing function.  It will update
//         the output buffer's write pointer as appropriate.  If PLC is not enabled,
//         update the output buffer's write pointer as appropriate.  If PLC is not enabled
//         and the output packet status indicates a missed packet (0x02 or 0x03) replace
//         the output packets with the last PCM value from the previous output packet.
//      9) Repeat this sequence to process then next packet in the input buffer.
//
// INPUTS:
//    - r7 = pointer to sco.decoder data structure:
//
// OUTPUTS:
//    - none
//
// RESERVED REGISTERS:
//    - none
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//     If PLC is not enabled, Bit errors are ignored to emulate previous firmware
//     operation.
//
// *****************************************************************************
.MODULE $M.frame_sync.sco_decode;
   .CODESEGMENT FRAME_SYNC_SCO_DECODE_PM;
   .DATASEGMENT DM;

   // Use to track position in CBuffer
   .VAR $next_packet_value=0;

#ifdef DEBUG_ON  // Debug
   .VAR $plc_lost_packet = 0;
   .VAR $plc_missed_packet = 0;
   .VAR $plc_biterror_packet = 0;
   .VAR $sco_purge= 0;
   .VAR $plc_fsco = 0;
   .VAR $plc_status=0;
#endif

$frame_sync.sco_decode:
   $push_rLink_macro;

jp_check_packet:
   // Process Header.  Only complete packets are in Cbuffer
   r0 = M[r7 + $sco_pkt_handler.INPUT_PTR_FIELD];
   call $cbuffer.calc_amount_data;
   Null = r0;
   if Z jump $pop_rLink_and_rts;
   r0 = M[r7 + $sco_pkt_handler.INPUT_PTR_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0;
   L0 = r1;

   M1 = 1;
   // Process Header
   r5 = M[I0,1];                     // Payload length (bytes)
   r6 = r5 + M1,    r2 = M[I0,M1];   // Status Words
   r6 = r6 LSHIFT -1;                // Payload length (words)
   M3 = r6,         r0 = M[I0,M1];   // Throw away timestamp

   // Calculate and save position after payload
   I4 = I0;
   r0 = M[I0,M3];
   r0 = I0;
   I0 = I4;
   M[$next_packet_value] = r0;

   // Save Payload size in bytes and status
   M[r7 + $sco_pkt_handler.PACKET_IN_LEN_FIELD] = r5;
   r2 = r2 AND 0x0003;
   M[r7 + $sco_pkt_handler.BFI_FIELD] = r2;

   // Check Output Space
   r0 = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];
   call $cbuffer.calc_amount_space;

   // If insufficient room in output, then exit without updating input buffer.
   // The packet will be reprocessed next call
   r8 = M[r7 + $sco_pkt_handler.DECODER_PTR];
   r1 = M[r8 + $sco_decoder.VALIDATE_FUNC];
   r8 = M[r8 + $sco_decoder.DATA_PTR];
   r9 = r8; // to pass data object pointer in a way that is matching unified i/f
   // r7 is PLC data object
   // r8 is decoder data object
   // r0 is output space
   // r5 is payload size in bytes
   // r6 is payload size in words (rounded up)
   // I0,L0,B0 is pointer to payload
   call r1;
   // r7 is PLC data object
   // r1 is output packet size in samples
   // I0,L0 is pointer to payload
   M[r7 + $sco_pkt_handler.PACKET_OUT_LEN_FIELD] =  r1;
   if Z jump jp_sco_no_decode;

   r2 = M[r7 + $sco_pkt_handler.BFI_FIELD];
#ifdef DEBUG_ON
   M1 = 1;
   // Count Invalid Packet Events (debug ???)
   r3 = M[$plc_lost_packet];
   Null = r2 - 2;                     // Lost packet
   if Z r3 = r3 + M1;
   M[$plc_lost_packet] = r3;

   r3 = M[$plc_missed_packet];
   Null = r2 - 3;                     // Major Timing Error
   if Z r3 = r3 + M1;
   M[$plc_missed_packet] = r3;

   r3 = M[$plc_biterror_packet];      // Bit Error
   Null = r2 - 1;
   if Z r3 = r3 + M1;
   M[$plc_biterror_packet] = r3;
#endif

   // For CVSD and Auristream, Decode is always successful or Packet needs concealment
   // For SBC we have three possible results
   //    1) Output created. Decode Successful
   //    2) Decode Failed.  Decode Failed needs packet concealment
   //    3) Partial Packet.  No Decode -> abort
   // **********************************************************************
   //         For SBC check packet state relative to position in SBC Packet
   //         SBC packets may be composed of multiple SCO packets and are not
   //         aligned.  A SCO packet can contain the end of one SBC packet and the
   //         start of another)
   r8 = M[r7 + $sco_pkt_handler.DECODER_PTR];
   r1 = M[r8 + $sco_decoder.DECODE_FUNC];
   r8 = M[r8 + $sco_decoder.DATA_PTR];
   r9 = r8; // to pass data object pointer in a way that is matching unified i/f
   // r7 is PLC data object
   // r8 is decoder data object
   // r2 is packet status
   // r5 is payload size (bytes)
   // r6 is payload size (words)
   // I0,L0 is pointer to payload
   call r1;
   // r7 is PLC data object
   // r5 is output packet status
   //    <0 no output
   //    0  output good no compensation
   //    >0 output bad, needs compensation

   // Update Input buffer
   L0 = Null;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif
   r0 = M[r7 + $sco_pkt_handler.INPUT_PTR_FIELD];
   r1 = M[$next_packet_value];
   M[r0 + $cbuffer.READ_ADDR_FIELD] = r1;

   // Check Output generated
   M[r7 + $sco_pkt_handler.BFI_FIELD] = r5;
   if NEG jump jp_check_packet;

   // update packet loss statistics
   // Packet and Bad Packet Count
   M1 = 1;
   r0 = M[r7 + $sco_pkt_handler.PACKET_COUNT_FIELD];
   r0 = r0 + M1;
   r1 = M[r7 + $sco_pkt_handler.BAD_PACKET_COUNT_FIELD];
   Null = M[r7 + $sco_pkt_handler.BFI_FIELD];
   if NZ r1 = r1 + M1;
   // Convert counts to bytes
   r2 = M[r7 + $sco_pkt_handler.PACKET_OUT_LEN_FIELD];
   r6 = r1 * r2 (int);    // Bad Bytes (samples?)
   r3 = r0 * r2 (int);    // Total Bytes (samples?)
   // When Total Byte count > STAT_LIMIT calculate Bad Bytes/STAT_LIMIT and reset counters
   r4 = M[r7 + $sco_pkt_handler.PACKET_LOSS_FIELD];
   r2 = M[r7 + $sco_pkt_handler.INV_STAT_LIMIT_FIELD];
   r5 = M[r7 + $sco_pkt_handler.STAT_LIMIT_FIELD];
   Null = r3 - r5;
   if POS r4 = r6 * r2 (int) (sat);
   if POS r0 = Null;
   if POS r1 = Null;
   M[r7 + $sco_pkt_handler.PACKET_COUNT_FIELD] = r0;
   M[r7 + $sco_pkt_handler.BAD_PACKET_COUNT_FIELD] = r1;
   M[r7 + $sco_pkt_handler.PACKET_LOSS_FIELD] = r4;

   // Check for PLC
   r0 = M[r7 + $sco_pkt_handler.CONFIG_FIELD];
   r1 = M[r7 + $sco_pkt_handler.ENABLE_FIELD];
   Null = r0 AND r1;
   if Z jump jp_no_plc;
      // if bfi is set, function below performs packet loss concealment
      // if bfi is not set, function updates overlap-add buffers
      // input port not accessed in function below
      r1 = M[r7 + $sco_pkt_handler.PLC_PROCESS_PTR];
      if Z jump jp_check_packet;
         r0 = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];
         r2 = M[r7 + $sco_pkt_handler.PACKET_OUT_LEN_FIELD];
         r3 = M[r7 + $sco_pkt_handler.BFI_FIELD];
         push r7;
         r7 = M[r7 + $sco_pkt_handler.PLC_DATA_PTR_FIELD];
         M[r7 + $plc100.OUTPUT_PTR_FIELD] = r0;
         M[r7 + $plc100.PACKET_LEN_FIELD] = r2;
         M[r7 + $plc100.BFI_FIELD] = r3;
         call r1;
         pop r7;
         jump jp_check_packet;
   // PLC Bypassed.  Manage output
jp_no_plc:
   r10 = M[r7 + $sco_pkt_handler.PACKET_OUT_LEN_FIELD];
   r0  = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B1;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I1 = r0;
   L1 = r1;
   // Ignore Bit Errors
   r1 = M[r7 + $sco_pkt_handler.BFI_FIELD];
   Null = r1 AND 0x0002;
   if NZ jump jp_replace;
      // Advance output without modifying data
      M1 = r10;
      r0 = M[I1,M1];
      jump jp_set_output;
jp_replace:
      // Copy last sample in place of packet
      r0 = M[I1,-1];
      r2 = M[I1,1];
      do lp_copy_last_sample;
         M[I1,1] = r2;
      lp_copy_last_sample:
jp_set_output:
   L1 = Null;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B1;
#endif
   r1 = I1;
   r0 = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];
   call $cbuffer.set_write_address;
   // Repeat until all packets have been processed
   jump jp_check_packet;

jp_sco_no_decode:
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif
   L0 = Null;
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frame_sync.sco_decoder.pcm.initialize
//
// DESCRIPTION:
//    Initialization function for PCM formated SCO data.
//
// INPUTS:
//    - r7 = pointer to sco.decoder data structure:
// OUTPUTS:
//    - none
//
// RESERVED REGISTERS:
//    - r7
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.frame_sync.sco_decoder.pcm.initialize;
   .CODESEGMENT FRAME_SYNC_SCO_DECODER_PCM_INITIALIZE_PM;
   .DATASEGMENT DM;

   $frame_sync.sco_decoder.pcm.initialize:
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.sco_decoder.pcm.validate
//
// DESCRIPTION:
//    Validation function for for PCM formated SCO data.
//
// INPUTS:
//    - r7 = pointer to sco.decoder data structure:
//    - r8 = pointer to decoder's data structure
//    - r0 = space in output buffer
//    - r2 = input packet status
//    - r5 = input packet size in bytes
//    - r6 = input packet size in words  (r5+1)>>1
//    - I0 = pointer to start of payload in input buffer
//    - L0 = size if input buffer
//
// OUTPUTS:
//    - r1 = size in samples of output packet.  Zero if there is insufficient
//           space in the buffer
//
// RESERVED REGISTERS:
//    - r2,r5,r6,r7,I0,L0
//
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//   PCM has no decoder data struct (r8=Null)
//
// *****************************************************************************

.MODULE $M.frame_sync.sco_decoder.pcm.validate;
   .CODESEGMENT FRAME_SYNC_SCO_DECODER_PCM_VALIDATE_PM;
   .DATASEGMENT DM;
 $frame_sync.sco_decoder.pcm.validate:
    // Check for space in output
    r1 = r6;
    Null = r0 - r6;
    if NEG r1 = Null;
    rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.sco_decoder.pcm.process
//
// DESCRIPTION:
//    process function for for PCM formated SCO data.  The function copies the
//    input packet status to the output packet status.  If the packet is invalid
//    (0x02 or 0x03) it returns without doing any processing.  Otherwise, it copies
//    the packet in the input buffer to the output shifting it up by 8 to convert
//    16-bit data to 24-bit data.
//
// INPUTS:
//    - r7 = pointer to sco.decoder data structure:
//    - r8 = pointer to decoder's data structure
//    - r2 = input packet status
//    - r5 = input packet size in bytes
//    - r6 = input packet size in words  (r5+1)>>1
//    - I0 = pointer to start of payload in input buffer
//    - L0 = size if input buffer
//
// OUTPUTS:
//    - r5 = Output packet's status.  Negative if decoder processes the input but
//           is not ready to generate an output.  Otherwise, status is:
//            0x00   - packet is valid
//            0x01   - packet has bit errors
//            0x02   - packet is invalid
//            0x03   - packet is invalid, and BlueCore has experienced a major timing
//                     issue.
//
// RESERVED REGISTERS:
//    - r7
//
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//   PCM has no decoder data struct (r8=Null)
//   The function does not update the output buffer's write pointer.  That is accomplished
//   in the calling layer or the PLC if enabled.
//
// *****************************************************************************
.MODULE $M.frame_sync.sco_decoder.pcm.process;
   .CODESEGMENT FRAME_SYNC_SCO_DECODER_PCM_PROCESS_PM;
   .DATASEGMENT DM;

 $frame_sync.sco_decoder.pcm.process:
   // Pass input status to output
   r5 = r2;
   // If packet error then no copy.  All bit errors are processed
   Null = r2 AND 0x0002;
   if NZ rts;

   $push_rLink_macro;
   // Get Output buffer
   r0 = M[r7 + $sco_pkt_handler.OUTPUT_PTR_FIELD];

#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B4;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I4  = r0;
   r10 = r6;
   L4  = r1;
   // Copy payload to output and shift to 24-bits
   do lp_copy;
      r0 = M[I0,1];
      r0 = r0 ASHIFT 8;
      M[I4,1]=r0;
lp_copy:
   L4 = Null;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B4;
#endif
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frame_sync.sco_encode
//
// DESCRIPTION:
//    Perform encoding of SCO synchronized data
//
// INPUTS:
//    R9 = encoder data object pointer
// OUTPUTS:
//
// RESERVED REGISTERS:
//    R9
// TRASHED REGISTERS:
//    - all, except R9
//
// NOTES:
//
// *****************************************************************************

.MODULE $M.sco_encode;
   .CODESEGMENT FRAME_SYNC_SCO_ENCODE_PM;

$frame_sync.sco_encode:
    $push_rLink_macro;

    // Call frame setup
    r1 = M[$M.sco_timing.sco_data_ptr];
    r7 = M[r1 + $sco_pkt_handler.ENCODER_BUFFER_FIELD];         // input
    r8 = M[r1 + $sco_pkt_handler.SCO_OUT_BUFFER_FIELD];         // output
    r0 = M[r1 + $sco_pkt_handler.ENCODER_SETUP_FUNC_FIELD];
    if NZ call r0;

jp_repeat:
    // Check for sufficient input data to encode
    r7 = M[$M.sco_timing.sco_data_ptr];
    r0 = M[r7 + $sco_pkt_handler.ENCODER_BUFFER_FIELD];         // input
    call $cbuffer.calc_amount_data;
    r1 = M[r7 + $sco_pkt_handler.ENCODER_INPUT_SIZE_FIELD];
    NULL = r0 - r1;
    if NEG jump $pop_rLink_and_rts;
    // Minimize pending sco output data
    r0 = M[r7 + $sco_pkt_handler.SCO_OUT_BUFFER_FIELD];         // output
    call $cbuffer.calc_amount_data;
    // if sco packet >= encoded packet
    //    encode if output buffer is empty
    // else
    //    encode if output buffer is less than or equal to one sco packet
    r1 = M[r7 + $sco_pkt_handler.ENCODER_OUTPUT_SIZE_FIELD];    // encoded packet size
    r2 = M[r7 + $sco_pkt_handler.SCO_OUT_PKTSIZE_FIELD];        // sco packet size

    // If not CVSD then bytes/2
    r3 = r2 LSHIFT -1;
    r4 = M[r7 + $sco_pkt_handler.SCO_OUT_PORT_FIELD];
    r4 = r4 AND $cbuffer.FORCE_16BIT_DATA_STREAM;
    NULL = r4 - $cbuffer.FORCE_16BIT_DATA_STREAM;
    if Z r2 = r3;

    NULL = r1 - r2;
    if NEG r0 = r0 - r2;
    NULL = r0;
    if GT jump $pop_rLink_and_rts;

    // Encode packet and retest
    r0 = M[r7 + $sco_pkt_handler.ENCODER_PROC_FUNC_FIELD];
    call r0;
    jump jp_repeat;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $sco_timing.initialize
//
// DESCRIPTION:
//    Initialize SCO synchronization mechanism
//
// INPUTS:
//
// OUTPUTS:
//
// RESERVED REGISTERS:
//
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//
// *****************************************************************************

.MODULE $M.sco_timing;
   .CODESEGMENT SCO_TIMING_INITIALIZE_PM;
   .DATASEGMENT DM;

//   /* Some reasonable defaults based on experiment (see B-100393). */
//#define SCO_PARAM_MASTER_DEADLINE_US 1500
//#define SCO_PARAM_SLAVE_DEADLINE_US   500
//#define SCO_PARAM_DELIVERY_DELAY      400; /* Experiment shows 143 (768-625) */
//#define MICROSECONDS_PER_SLOT           (625)
//
//    clk = sco->next_master_tx;
//    psk [1] = SCO_PARAM_DELIVERY_DELAY;
//    if (sco->rl->masterside)
//    {
//        psk [0] = SCO_PARAM_MASTER_DEADLINE_US;
//        fsco    = sco->fsco
//    }
//    else
//    {
//        psk [0] = SCO_PARAM_SLAVE_DEADLINE_US;
//        /* On the slave, we get to transmit one slot later */
//        clk += 2;  /* one slot = 2 ticks */
//        /* We also receive our data one slot earlier */
//        fsco    = sco->fsco-1;
//    }
//
//    /* To allow easy adjustment during testing, provide PSKEY access */
//#ifdef SCO_PARAMETERS_OVERRIDE_VIA_PSKEY_USR37
//    psget (PSKEY_USR37, psk, sizeof psk);
//#endif

// const uint16 packet_ticks[16] = {2, 2 ,2 ,2 ,2 ,2,2,2,2,2,6,6,6,6,10,10};
//  SP.  6 for 2EV5,3EV5 otherwise 2
//.BLOCK sco_params;
//  .VAR portnum;
//  .VAR Tesco;               // sco->tsco
//  .VAR Wesco;               // (Not-Used) sco->fsco - (packet_ticks[sco->toair_packet] + packet_ticks[sco->fromair_packet]) / 2;
//                            //  sco->fsco-6 (2EV5,3EV5)  else   sco->fsco-2
//  .VAR snd_packlen;         // sco->toair_bytes
//  .VAR rcv_packlen;         // sco->fromair_bytes
//  .VAR start_slots_ms;      // (uint16) (clk >> 16)
//  .VAR start_slots_ls;      // (uint16) (clk & 0xFFFF)
//  .VAR snd_deadline;        // psk [0]
//  .VAR rcv_deadline;        // (Not-Used) fsco * MICROSECONDS_PER_SLOT + psk [1]
//.ENDBLOCK;

.VAR    sco_data_ptr=0;
.VAR    bt_addr.message_struc[$message.STRUC_SIZE];
.VAR    sco_param.message_struc[$message.STRUC_SIZE];
.VAR    sco_param_failed.message_struc[$message.STRUC_SIZE];
.VAR    wallclock_obj[$wall_clock.STRUC_SIZE] = 0 ...;
#ifdef USES_RCV_TIMING
.VAR sco_rcv_trigger;
.VAR    rcv_proc_trigger;
#endif
   // r8 = sco object
$sco_timing.initialize:
   $push_rLink_macro;

   // Save SCO Data Object
   M[sco_data_ptr]   = r8;
   // Clear Tsco until SCO connection
   M[r8+$sco_pkt_handler.SCO_PARAM_TESCO_FIELD]=NULL;

   // set up message handler for bluetooth address
   r1 = &bt_addr.message_struc;
   r2 = $MESSAGE_PORT_BT_ADDRESS;
   r3 = &$rm_bluetooth_address_handler;
   call $message.register_handler;

   // set up message handler for SCO params message
   r1 = &sco_param.message_struc;
   r2 = $LONG_MESSAGE_SCO_PARAMS_RESULT;
   r3 = &$sco_params_handler;
   call $message.register_handler;

   // set up error handler for SCO params message
   r1 = &sco_param_failed.message_struc;
   r2 = $MESSAGE_GET_SCO_PARAMS_FAILED;
   r3 = &$sco_params_failed_handler;
   call $message.register_handler;

   r0 = $sco_timing.PortConnected;
   M[$cbuffer.write_port_connect_address] = r0;
   r0 = $sco_timing.PortDisConnected;
   M[$cbuffer.write_port_disconnect_address] = r0;

   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $sco_timing.PortConnected
//
// DESCRIPTION:
//    Detect SCO Port Connection
//
// INPUTS:
//      r1 = Connected Write Port
//
// OUTPUTS:
//
// RESERVED REGISTERS:
//
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.sco_timing.PortConnected;
   .CODESEGMENT SCO_TIMING_PORT_CONNECTED_PM;

$sco_timing.PortConnected:

   // Check for Connected SCO Output Port
   r8 = M[$M.sco_timing.sco_data_ptr];
   if Z rts;
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_PORT_FIELD];
   r0 = r0 AND ($cbuffer.WRITE_PORT_OFFSET | $cbuffer.PORT_NUMBER_MASK);
   NULL = r1 - r0;
   if NZ rts;

   $push_rLink_macro;

   // Clear Tsco to indicate new connection
   M[r8+$sco_pkt_handler.SCO_PARAM_TESCO_FIELD]=NULL;

   // Request BT Address for Wall Clock
   r2 = $MESSAGE_GET_BT_ADDRESS;
   r3 = r1 AND $cbuffer.PORT_NUMBER_MASK;
   push r3;
   call $message.send_short;

   // Request SCO Parmaters
   r2 = $MESSAGE_GET_SCO_PARAMS;
   pop r3;
   call $message.send_short;

   jump $pop_rLink_and_rts;

$sco_timing.PortDisConnected:
   // Check for DisConnected SCO Output Port
   r8 = M[$M.sco_timing.sco_data_ptr];
   if Z rts;
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_PORT_FIELD];
   r0 = r0 AND ($cbuffer.WRITE_PORT_OFFSET | $cbuffer.PORT_NUMBER_MASK);
   NULL = r1 - r0;
   if NZ rts;

$sco_timing.ScoDisconnect:
   $push_rLink_macro;
   //SP.  Only disconnect once
   r1 = &$M.sco_timing.wallclock_obj;
   NULL = M[r1 + $wall_clock.NEXT_ADDR_FIELD];
   if NZ call $wall_clock.disable;
   // Clear wall clock parameters
   r1 = &$M.sco_timing.wallclock_obj;
   M[r1 + $wall_clock.NEXT_ADDR_FIELD]=NULL;
   M[r1 + $wall_clock.ADJUSTMENT_VALUE_FIELD]=NULL;
   // Clear TSco to indicate no SCO
   r8 = M[$M.sco_timing.sco_data_ptr];
   M[r8+$sco_pkt_handler.SCO_PARAM_TESCO_FIELD]=NULL;
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $rm_bluetooth_address_handler
//
// DESCRIPTION:
//    Get BT address for SCO connection
//
// INPUTS:
//      r1 = BT Address Type | (port)
//      r2 = BT ADdress Word 0
//      r3 = BT ADdress Word 1
//      r4 = BT ADdress Word 2
//
// OUTPUTS:
//
// RESERVED REGISTERS:
//
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.sco_timing.rm_bluetooth_address_handler;
   .CODESEGMENT SCO_TIMING_RCV_BT_ADDRESS_PM;
$rm_bluetooth_address_handler:
   $push_rLink_macro;

   // Save encoding mode and other parameters
   // note these can end up getting sign-extended... is this OK?
   r1 = r1 LSHIFT -8;
   M[$M.sco_timing.wallclock_obj + $wall_clock.BT_ADDR_TYPE_FIELD]  = r1;
   M[$M.sco_timing.wallclock_obj + $wall_clock.BT_ADDR_WORD0_FIELD] = r2;
   M[$M.sco_timing.wallclock_obj + $wall_clock.BT_ADDR_WORD1_FIELD] = r3;
   M[$M.sco_timing.wallclock_obj + $wall_clock.BT_ADDR_WORD2_FIELD] = r4;

   // start wallclock.  SP.  only start it once
   r1 = &$M.sco_timing.wallclock_obj;
   NULL = M[r1 + $wall_clock.NEXT_ADDR_FIELD];
   if Z call $wall_clock.enable;
   jump $pop_rLink_and_rts;

$sco_params_failed_handler:
   // No Sync Required.  Should Not Happen!!!
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.sco_params
//
// DESCRIPTION:
//    Message detailing sco-connection parameters
//
// INPUTS:
//    r3-points to long message structure of format:
//       offset 0 - SCO connection handle (portnum)
//       offset 1 - Tesco (slots)
//       offset 2 - Wesco (slots)
//       offset 3 - to-air packet length (bytes)
//       offset 4 - from-air packet length (bytes)
//       offset 5 - MS 16bits of btclock giving start of reserved slots
//       offset 6 - LS 16bits of btclock giving start of reserved slots
//       offset 7 - to-air deadline relative to start of reserved slots (microseconds)
//       offset 8 - from-air deadline relative to start of reserved slots (microseconds)
//
//       See http://wiki/KalimbaSCOparameters for detailed description
//
// *****************************************************************************
.MODULE $M.sco_timing.sco_params_handler;
   .CODESEGMENT SCO_TIMING_RCV_SCO_PARAMS_PM;
   .DATASEGMENT DM;


$sco_params_handler:
//#define DEBUG_SCO_PARMS
#ifdef DEBUG_SCO_PARMS
   .VAR $sco_params[9];
   
   I0 = r3;
   I3 = &$sco_params;
   r10 = 9;
   r0 = M[I0, 1];
   do get_params;
      M[I3, 1] = r0; r0 = M[I0, 1];
   get_params:
#endif

   M1 = 1;
   r8 = M[$M.sco_timing.sco_data_ptr];

   // Update Next Xmit Time in BT clks (24-bit)
   r1 = M[r3 + 5]; // msw
   r2 = M[r3 + 6]; // lsw
   rMAC = r1 LSHIFT -8;
   rMAC = rMAC AND 0xFF;
   rMAC = rMAC * (625 * 2) (int);
   r1 = r1 LSHIFT 16;
   r2 = r2 AND 0xFFFF;
   r2 = r2 + r1;
   rMAC = rMAC + r2 * (625) (UU);
   r6 = rMAC LSHIFT 22;

#ifdef USES_RCV_TIMING
   // Set SCO write Time
   r1 = M[r3 + 7];
   r6 = r6 - r1;
   // Set Sco Read Time
   r2 = M[r3 + 8];
   r7 = M[r3 + 1];
   r2 = r2 + r1;                     // r2 = from_air_deadline + to_air_deadline  
   rMAC = r2 * 0.0016;               // 1/625 usec
   r2   = rMAC1;                     // from_air_deadline + to_air_deadline (slots)
   NULL = r2 - r7;                   // Tesco-(fad+tad)
   if POS r2 = r2 - r7;              // if (fad+tad) > Tesco, (fad+tad) -= Tesco
   M[$M.sco_timing.rcv_proc_trigger]=r2;
   if NZ r2 = r7 - r2;
   r2 = r2 - 2;                     // back up two slots to account for possible rounding error in usec->slot 
   if LE r2 = M1;                    // conversion or firmware being a slot late. Ensure not zero or negative
   M[$M.sco_timing.sco_rcv_trigger]=r2;

#else
   // Shift back by 1/2 slot
   r6 = r6 - 312;      // ***** SPTBD - remove shift???? ****

   // Master or Slave
   r4 = 1250;
   r1 = M[r3 + 7];
   NULL = r1 - 1000;
   if POS r6 = r6 - r4;
#endif
   // Set SCO Xfer Size.
   r0 = M[r3 + 3];
   M[r8 + $sco_pkt_handler.SCO_OUT_PKTSIZE_FIELD] = r0;

   // Set Recieve Jitter
   r2 = M[r8 + $sco_pkt_handler.JITTER_PTR_FIELD];
   if NZ M[r2]=r0;
   


   // Update TESCO
   r5 = M[r8 + $sco_pkt_handler.SCO_PARAM_TESCO_FIELD];
   r7 = M[r3 + 1];
   r7 = r7 * 625 (int);
   M[r8 + $sco_pkt_handler.SCO_PARAM_TESCO_FIELD]=r7;

   // Signal new SCO config Received.  If ount of sync
   r1 =  M[r8 + $sco_pkt_handler.SCO_PARAM_SLOT_LS_FIELD];
   M[r8 + $sco_pkt_handler.SCO_PARAM_SLOT_LS_FIELD]=r6;

   // If tsco was zero, then its the first event.  Force a reset
   NULL = r5;
   if Z jump jp_force_reset;

   // Check if SCO has lost alignment
   r1 = r1 - r6;
   if Z rts;
   rMAC = r1 ASHIFT 0 (LO);    // LS word of rMAC now equals r1, with
                                // sign extension in higher bits;
   Div = rMAC/r7;
   r4 = DivRemainder;
   if NEG r4 = NULL - r4;
   NULL = r4 - 312;
   if NEG rts;

jp_force_reset:
   M[r8 + $sco_pkt_handler.SCO_NEW_PARAMS_FLAG]=r7;

   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $sco_timing.SyncClock
//
// DESCRIPTION:
//    Synchronize BT Clock and SCO Transmit with ISR
//
// INPUTS:
//      r7 = Ptr to task Frame Counter
//      r1 = Ptr to timer task struct
//      r3 = Ptr to Timer Task Handler
//
// OUTPUTS:
//
// RESERVED REGISTERS:
//
// TRASHED REGISTERS:
//    - all
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.sco_timing.SyncClock;
   .CODESEGMENT SCO_TIMING_SYNC_PM;
   .DATASEGMENT DM;

$sco_timing.SyncClock:
   $push_rLink_macro;


   r8 = M[$M.sco_timing.sco_data_ptr];

   // Set Timer Task to Middle of next BT slot

#if 1
   r5 = M[r1 + $timer.TIME_FIELD];
#else
   r5 = M[$TIMER_TIME];
#endif
   // BT clk in usec
   r0 = M[&$M.sco_timing.wallclock_obj + $wall_clock.ADJUSTMENT_VALUE_FIELD];
   r6 = r0 + r5;

   // BT Clks till SCO Xmit slot (negative if already passed)
   r0 = M[r8+$sco_pkt_handler.SCO_PARAM_SLOT_LS_FIELD];
   r0 = r0 - r6;

   // Calculate offset between BT clock and SCO Xmit
   r4 = 625;
   rMAC = r0 * 0.0016;
   r2   = rMAC1;
   r2   = r2 * r4    (int);
   r2   = r0 - r2;

   // Modulous clks by Tesco in usec
   rMAC = r0 ASHIFT 0 (LO);    // LS word of rMAC now equals r0, with
                                // sign extension in higher bits;
   r0 = M[r8+$sco_pkt_handler.SCO_PARAM_TESCO_FIELD];
   if Z r2 = NULL;
   Div = rMAC/r0;

   // Advance Timer
   NULL = r2 - 312;
   if GT r2 = r2 - r4;
   r2 = r2 + r4;
   r2 = r2 + r5;

   // r1 and r3 set in function call
   call $timer.schedule_event_at;   //SP.  r6-r9 & Div not used in call

   // Wait for Valid SCO parameters and BT clock sync
   r0 = M[r8+$sco_pkt_handler.SCO_PARAM_TESCO_FIELD];
   if Z jump $pop_rLink_and_rts;
   NULL = M[&$M.sco_timing.wallclock_obj + $wall_clock.ADJUSTMENT_VALUE_FIELD];
   if Z jump $pop_rLink_and_rts;

   // Advance sco next_xmit_clks.
   // r6 - BT clks in usec
   // DivRemainder - modulous of sco xmit
   r4 = DivRemainder;
   NULL = r4 + NULL;
   if LE r4 = r4 + r0; // SP.  If neg then time was passed.  If zero then advance by tsco
   // r4 is clks till next SCO xmit.  Update SCO xmit time (current clk + remainder)
   r1 = r6 + r4;
   M[r8+$sco_pkt_handler.SCO_PARAM_SLOT_LS_FIELD] = r1;

   // Check for SCO XMIT (tsco - remainder)
   r4 = r4 + 312;
   rMAC = r4 * 0.0016;               // 1/625 usec
   r2  = rMAC1;                     // BT clk we are currently in

#ifdef USES_RCV_TIMING
   // Perform re-trans safe SCO read
   push r2;
NULL = r2 - M[$M.sco_timing.sco_rcv_trigger];
   if Z call $frame_sync.sco_port_handler;
   pop r2;
#endif
   NULL = r2 - 1;
   if NZ jump $pop_rLink_and_rts;

   // Get Buffer and Port
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_PORT_FIELD];
   call $cbuffer.get_write_address_and_size.its_a_port;
   I4 = r0;
   L4 = r1;
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_BUFFER_FIELD];

#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0;
   L0 = r1;
   // Transfer SCO Packet
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   r10 = M[r8 + $sco_pkt_handler.SCO_OUT_PKTSIZE_FIELD];

   // If not CVSD then bytes/2
   r2 = r10 LSHIFT -1;
   r1 = M[r8 + $sco_pkt_handler.SCO_OUT_PORT_FIELD];
   r1 = r1 AND $cbuffer.FORCE_16BIT_DATA_STREAM;
   NULL = r1 - $cbuffer.FORCE_16BIT_DATA_STREAM;
   if Z r10 = r2;

   NULL = r0 - r10;
   if NEG r10 = r0;
   r1 = M[r8 + $sco_pkt_handler.SCO_OUT_SHIFT_FIELD];
   do lp_sco_xmit;
      r0 = M[I0,1];
      r0 = r0 ASHIFT r1;
      M[I4,1]=r0;
lp_sco_xmit:
   // Update Buffer and Port
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_BUFFER_FIELD];
   r1 = I0;
   call $cbuffer.set_read_address;
   r0 = M[r8 + $sco_pkt_handler.SCO_OUT_PORT_FIELD];
   r1 = I4;
   call $cbuffer.set_write_address;
   L0 = NULL;
   L4 = NULL;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif
   // Check for sync with first SCO xmit
   NULL = M[r8 + $sco_pkt_handler.SCO_NEW_PARAMS_FLAG];
   if NZ M[r7]=NULL;
   M[r8 + $sco_pkt_handler.SCO_NEW_PARAMS_FLAG]=NULL;

   jump $pop_rLink_and_rts;

.ENDMODULE;
