// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.comes/ Part of ADK 3.5
//
// $Change$  $DateTime$
// $Revision$
// *****************************************************************************
// *****************************************************************************
// DESCRIPTION
//
//   Measuring the latency of the spdif for both coded and pcm input data type
//
//   For PCM data type, the measured latency will be the total buffering data
//   including those in ports for input and output interfaces .
//
//   For coded data, the latency is updated once per IEC61937 frame, the measured
//   latency will be difference between the arrival time of a packet(when first
//   word of packet is seen in the input port) and the time the the (first sample
//   of the) packet leaves for the output interface.
//
// *****************************************************************************
#ifndef SPDIF_LATENCY_MEASUREMENT_ASM_INCLUDED
#define SPDIF_LATENCY_MEASUREMENT_ASM_INCLUDED
#include "core_library.h"
#include "spdif_library.h"
#ifdef SPDIF_LATENCY_MEASUREMENT
#include "latency_measure.h"
// *****************************************************************************
// MODULE:
//    $spdif.latency_measure
//
// DESCRIPTION:
//   wrapper function to for calling latency measurement functions
//
// INPUTS:
//   r8 = spdif stream decode structure
//   r4 = function index
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything except r7 and r8
// *****************************************************************************
.MODULE $M.spdif.latency_measurement;
   .CODESEGMENT SPDIF_LATENCY_MEASUREMENT_PM;
   .DATASEGMENT DM;

   $spdif.latency_measurement:

   // push rLink onto stack
   $push_rLink_macro;

   // function table for measuring latency
   .VAR latency_measurment_func_table[] =
       $spdif.latency_measurement.reset,
       $spdif.latency_measurement.identify_packet_boundary,
       $spdif.latency_measurement.update_latency;

   // save r8 and r7
   push r8;
   push r7;

   // get the input structure
   r8 = M[$spdif.stream_decode.stream_decode_struct];

   // get the latency buffers structure, if 0 means no latency measurement
   // has been requested
   r7 = M[r8 + $spdif.stream_decode.LATENCY_MEASUREMENT_STRUCT_FIELD];
   if Z jump end;

   // r8 = pointer to stream decode
   // r4 = function to call
   r5 = M[r8 + $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD];
   r4 = M[r4 + latency_measurment_func_table];
   call r4;

   end:
   pop r7;
   pop r8;

   // pop lank from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $$spdif.latency_measurement.update_latency
//
// DESCRIPTION:
//    updates latency, for both pcm and coded data
//
// INPUTS:
//    r8 = stream decode structure
//    r7 = latency structure
//    I0 = current position of spdif input buffer
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything except r7 and r8
// *****************************************************************************
.MODULE $M.spdif.latency_measurement.update_latency;
   .CODESEGMENT SPDIF_LATENCY_MEASUREMENT_UPDATE_LATENCY_PM;
   .DATASEGMENT DM;

   $spdif.latency_measurement.update_latency:

   // push rLink onto stack
   $push_rLink_macro;
   r0 = M[r8 + $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD];
   Null = r0 - $spdif.DECODER_TYPE_PCM;
   if GT jump is_coded;

   // its pcm data type,
   call $block_interrupts;
   // SPDIF input ports(fs) --> spdif input buffer(2*fs) --> spdif output buffers and app buffers(input structure)
   // first calculate pcm latency for output buffers
   push r7;
   push r5;
   push r8;
   r7 = M[r7 + $encoded_latency.PCM_LATENCY_STRUCT_FIELD];
   call $latency.calc_pcm_latency;
   pop r8;
   pop r5;
   pop r7;

   // now calculate pcm latency for input buffer and port
   call $spdif.latency_measurement.calc_spdif_input_latency;

   // fix for warping factor
   r0 = M[r7 + $encoded_latency.CURRENT_WARP_RATE_FIELD];
   if NZ r0 = M[r0];
   r1 = rMAC * r0 (frac);
   r0 = r1 * r0 (frac);
   rMAC = rMAC + r1;
   rMAC = rMAC + r0;

   // total pcm latency
   rMAC = rMAC + r6;
   call $unblock_interrupts;
   M[r7 + $encoded_latency.TOTAL_LATENCY_US_FIELD] = rMAC;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

   is_coded:
   // calculate encoded latency
   call $latency.calc_encoded_latency;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.latency_measurement.identify_packet_boundary
//
// DESCRIPTION:
//    writes a new entry to the packet boundary info buffer
//
// INPUTS:
//    I4 = boundary
//    r7 = encoded latency input structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-r3, I5, rMAC
// *****************************************************************************
.MODULE $M.spdif.latency_measurement.identify_packet_boundary;
   .CODESEGMENT SPDIF_LATENCY_MEASUREMENT_IDENTIFY_PACKET_BOUNDARY_PM;
   .DATASEGMENT DM;

   $spdif.latency_measurement.identify_packet_boundary:

   // push rLink onto stack
   $push_rLink_macro;

   // open the packet info buffer for writing
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   call $cbuffer.get_write_address_and_size;
   L5 = r1;
   I5 = r0;

   // the size packet buffer info might not be enough,
   // this wont cause a problem, we delete one entry when
   // it's become full
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   Null = r0 - 2;
   if POS jump buffer_full_check_done;
      r0 = M[I5, -1];
      r0 = M[I5, -1];
   buffer_full_check_done:

   // interrupts shall be blocked
   call $block_interrupts;

   // see how many samples in SPDIF input port
   r0 = M[r5 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r4 = r0;

   // amount of data in input buffer not processed yet
   r0 = M[r5 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
   r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   r0 = r1 - I0;
   if NEG r0 = r0 + L0;

   // total samples before the boundary
   r0 = r0 LSHIFT -1;
   r0 = r4 + r0;

   // get inverse of sample rate
   r1 = M[r5 + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD];
   // compute q29.19 result
   rMAC = r0 * r1;
   // convert to 24.24
   rMAC = rMAC ASHIFT $latency.PCM_LATENCY_SHIFT;

   // fix for warping factor
   r0 = M[r7 + $encoded_latency.CURRENT_WARP_RATE_FIELD];
   if NZ r0 = M[r0];
   r1 = rMAC * r0(frac);
   r0 = r1 * r0(frac);
   rMAC = rMAC + r1;
   rMAC = rMAC + r0;

   // calculate the arrival time
   r0 = M[$TIMER_TIME];
   r4 = r0 - rMAC;

   // save boundary
   r0 = I4;
   M[I5, 1] = r0;

   // save arrival time
   M[I5, 1] = r4;

   call $unblock_interrupts;

   // close the packet info buffer
   r1 = I5;
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   call $cbuffer.set_write_address;
   L5 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spdif.latency_measurement.reset
//
// DESCRIPTION:
//    resets spdif latency measurement procedure
//
// INPUTS:
//    r7 = encoded latency input structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    assume everything
// *****************************************************************************
.MODULE $M.spdif.latency_measurement.reset;
   .CODESEGMENT SPDIF_LATENCY_MEASUREMENT_RESET_PM;
   .DATASEGMENT DM;

   $spdif.latency_measurement.reset:

   // push rLink onto stack
   $push_rLink_macro;

   // reset encoded latency
   call $latency.reset_encoded_latency;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $spdif.latency_measurement.calc_spdif_input_latency
//
// DESCRIPTION:
//    measures latency in the spdif input port and buffer
//
// INPUTS:
//
//
// OUTPUTS:
//    rMAC = measured latency in micro seconds
//
// TRASHED REGISTERS
//    r0-r2, rMAC
// *****************************************************************************
.MODULE $M.spdif.latency_measurement.calc_spdif_input_latency;
   .CODESEGMENT SPDIF_LATENCY_MEASUREMENT_CALC_SPDIF_INPUT_LATENCY_PM;
   .DATASEGMENT DM;

   $spdif.latency_measurement.calc_spdif_input_latency:
   // push rLink onto stack
   $push_rLink_macro;

   call $block_interrupts;

      r0 = M[r5 + $spdif.frame_copy.LEFT_INPUT_PORT_FIELD];
      call $cbuffer.calc_amount_data;
      rMAC = r0;

      // amount of data in input buffer
      r0 = M[r5 + $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD];
      call $cbuffer.calc_amount_data;
      r0 = r0 LSHIFT -1;
      r0 = rMAC + r0;

      // get inverse of sample rate
      r1 = M[r5 + $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD];
      // compute q29.19 result
      rMAC = r0 * r1;
      // convert to 24.24
      rMAC = rMAC ASHIFT $latency.PCM_LATENCY_SHIFT;

   call $unblock_interrupts;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif // #ifdef SPDIF_LATENCY_MEASUREMENT
#endif  // #ifndef SPDIF_LATENCY_MEASUREMENT_ASM_INCLUDED
