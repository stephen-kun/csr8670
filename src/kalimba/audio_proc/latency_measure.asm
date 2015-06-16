// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: $  $DateTime: $
// *****************************************************************************
// *****************************************************************************
// NAME:
//    Latency Measure Library
//
// DESCRIPTION:
//    This library provides an API for calculating latency due to buffering
//    PCM, as well as encoded audio frames.
//
// *****************************************************************************
#ifndef LATENCY_MEASURE_INCLUDED
#define LATENCY_MEASURE_INCLUDED

#include "stack.h"
#include "cbuffer.h"
#include "latency_measure.h"


// *****************************************************************************
// MODULE:
//    $M.latency_measure.calc_pcm_latency
//
// DESCRIPTION:
//    Calculates PCM latency using Sum(amount_data[i]/fs[i]).
//
// INPUTS:
//    - r7 = pointer to a pcm_latency data structure:
//         $pcm_latency.BUFFERS_LIST_FIELD
//            pointer to a null terminated list of cbuffer structure (for
//            cbuffers)or a port identifier (for ports) and inverse sample rate
//            pairs. For example:
//              cbuffer_struc_1, addr_inverse_fs1, warp_1,
//              cbuffer_struc_2, addr_inverse_fs2, warp_2
//              port_id_1, inverse_fs_port1, warp_3,
//              0;
//
//              addr_inverse_fs are pointers to microsecond values in q.17 format.
//              They are computed as:  1/fs*10^6 / 2 ^7
//
//              warps are pointers to software or hardware warp values.
//              0.01 means the source is 1% faster than the sink.
//
//         $pcm_latency.SAMPLES_LIST_FIELD
//            pointer to a null terminated list of pairs of number of samples
//            and associated inverse_sample rate.  For example,
//              addr_num_samples_in_buffer1, addr_inverse_fs1, warp_1, 0;
//            This input is especially useful for accounting for the delay
//            induced by the delay function in the audio_proc library, which
//            does not use a cbuffer struc.
//
//
// OUTPUTS:
//    - r6 the result of the latency calcuation in microseconds.
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r6, r8
//
// *****************************************************************************

.MODULE $M.latency_measure.calc_pcm_latency;
   .CODESEGMENT LATENCY_MEASURE_CALC_PCM_LATENCY_PM;

    $latency.calc_pcm_latency:

    // push rLink onto stack
    $push_rLink_macro;

    call $block_interrupts;

    // Count the number of cbuffer samples, which will be played before this frame.
    // Each buffer can have its own sample rate associated with it.  The data structure
    // is populated with inverse sample rates so we can use a multiplication.

    // point to null terminiated list of buffers
    r8 = M[r7 + $pcm_latency.BUFFERS_LIST_FIELD];
    r6 = 0;
    proc_loop_buffers:
       r0 = M[r8];
       // NULL value terminates List
       if Z jump done_with_proc_loop;
       // is it a buffer?
       Null = SIGNDET r0;
       if NZ jump is_buf;
       // it is a port, force an MMU buffer set
       Null = M[$PORT_BUFFER_SET];
       // is it a read port?
       r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
       Null = r1 - $cbuffer.NUM_PORTS;
       if NEG jump is_read_port;
          // its a write port
          call $cbuffer.calc_amount_space;
          r0 = r0 + 1;        // compensate for routine reporting 1 less that true amount of space
          r2 = r2 ASHIFT -1;  // size of port in 16-bit words
          r0 = r2 - r0;       // number of samples in port = size of buffer - amount of space
          jump calculate_latency;
       is_read_port:
       is_buf:

       // calculate amount in buffer
       call $cbuffer.calc_amount_data;

       calculate_latency:
       call calc_and_accum_latency;
       // point to next cbuffer
       r8 = r8 + 3;
    jump proc_loop_buffers;
done_with_proc_loop:

    // calculate latency due to delay line
    r8 = M[r7 + $pcm_latency.SAMPLES_LIST_FIELD];
    if Z jump done;
    proc_loop_samples:
       // Beware: Currently this loop will exit as soon as it sees an entry having zero latency.
       // This means if your application has more than one entry, and if any of the entries near
       // the top of the list have zero delay, the other entries will be ignored.
       // get delay amount in samples
       r0 = M[r8];
       // NULL value terminates List
       if Z jump done;
       // calculate latency
       call calc_and_accum_latency;
       // point to next cbuffer
       r8 = r8 + 3;
    jump proc_loop_samples;

done:

    // output is in r6
    call $unblock_interrupts;

    jump $pop_rLink_and_rts;


calc_and_accum_latency:
       // get inverse sample rate
       r1 = M[r8 + 1];
       r1 = M[r1];
       // get warp rate
       r2 = M[r8 + 2];
       if Z jump no_warp;
         // get ptr to a ptr
         r2 = M[r2];
         if Z jump no_warp;
         r2 = M[r2];
       no_warp:
       // r0 = number of samples
       // r1 = ptr to inverse sample rate
       // r2 = ptr to warp rate

       // the inverse sample rate needs to be modified by the current warp
       // value as: 1/fs * 1/(1-warp)
       // to avoid the division we use an approximation:
       // 1/fs * 1/(1-warp) ~= 1/fs * (1 + warp + warp^2)
       // which is equivalent to: 1/fs + 1/fs * warp + 1/fs * warp^2
       r3 = r1 * r2 (frac);    // r3 = 1/fs * warp
       r2 = r3 * r2 (frac);    // r2 = 1/fs * warp^2
       r3 = r1 + r3;
       r1 = r3 + r2;

       // compute q31.17 result 
       rMAC = r0 * r1;
       // convert to 24.24
       rMAC = rMAC ASHIFT $latency.PCM_LATENCY_SHIFT;
       // upper 24 bits is the amount of time it will take the data to play out of this cbuffer
       r1 = rMAC1;
       // accumulate time
       r6 = r6 + r1;
       rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $latency_measure.reset_encoded_latency
//
// DESCRIPTION:
//    resets latency measurements procedure
//
// INPUTS:
//    r7 = $encoded_latency structure
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-r1
// *****************************************************************************
.MODULE $M.latency_measure.reset;
   .CODESEGMENT LATENCY_MEASURE_RESET_ENCODED_LATENCY_PM;
   .DATASEGMENT DM;

   $latency.reset_encoded_latency:

   // push rLink onto stack
   $push_rLink_macro;

   // see if the packet boundary buffer has been defined,
   // if not it means that it's only pcm measurements
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   if Z jump encoded_reset_done;

      // clear packets info buffer
      call $cbuffer.empty_buffer;

      // initialise last read address of coded buffer
      r0 = M[r7 + $encoded_latency.CODEC_CBUFFER_FIELD];
      r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];
      M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_CODED_RD_ADDR_FIELD] = r0;

      // initialise last write address of decoder output buffer
      r0 = M[r7 + $encoded_latency.DECODED_CBUFFER_FIELD];
      r0 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_DECODED_WR_ADDR_FIELD] = r0;

      // reset history for min calc
      r0 = 0x7FFFFF;
      M[r7 + $encoded_latency.HIST_LATENCY_US_FIELD + 0] = r0;
      M[r7 + $encoded_latency.HIST_LATENCY_US_FIELD + 1] = r0;
      M[r7 + $encoded_latency.HIST_LATENCY_US_FIELD + 2] = r0;
      M[r7 + $encoded_latency.HIST_LATENCY_US_FIELD + 3] = r0;

   encoded_reset_done:

   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $latency_measure.calc_encoded_latency
//
// DESCRIPTION:
//    calculates latency in DSP for encoded streams
//
//    Latency for encoded stream is (re)calculated once per packet, packets are
//    the segments of received encoded data for which we know (or can estimate)
//    the arrival time. This function receives the arrival time info for packets
//    and calculate the latency by working out what the expected exit time for
//    the first sample of packet will be.
//
// INPUTS:
//   r7 = $encoded_latency structure
//      $encoded_latency.PCM_LATENCY_STRUCT_FIELD
//          structure for calculating PCM latency, this will have all inputs to
//          calculate pcm latency. This functions calculates the pcm latency to
//          work out when the first sample of the packet will leaves to output
//          audio interface. The structure has been defined in $pcm_latency data structure
//
//      $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD
//         cbuffer holding packet boundary info for coded data, cbuffer
//         it shall contain structured information about packets that has reached DSP
//         codec buffer as described below:
//            - structure size is two words
//            - first word shows the the boundary of the packet, i.e. where the packet
//              encoded data starts in the DSP coded buffer
//            - second word is the time (local timer time) at which the packet arrived in
//              the chip
//
//      $encoded_latency.CODEC_CBUFFER_FIELD
//         codec cbuffer, the cbuffer that holds coded data and used as input to the decoder
//
//      $encoded_latency.DECODED_CBUFFER_FIELD
//         decoder output pcm cbuffer, pass one of the pcm output cbuffer. This field is used
//         to see whether decoder has generated any new output compared to the last run of
//         this function.
//
//      $encoded_latency.DECODER_INV_SAMPLE_RATE_FIELD
//         Variable containing inverse sample rate for decoder output data.
//
//      $encoded_latency.CURRENT_WARP_RATE_FIELD
//         current warp rate used in the system that will apply to the output of decoder
//
//      $encoded_latency.LATENCY_MEASUREMENT_LAST_CODED_RD_ADDR_FIELD (state)
//         last read pointer of the codec buffer that processed, is used to find out the first time decoder
//         decodes fully or partly a packet
//
//      $encoded_latency.LATENCY_MEASUREMENT_LAST_DECODED_WR_ADDR_FIELD (state)
//         last write pointer of the decoder output buffer that processed, is used to find out how many sample
//         decoder has generated in last run.
//
//      $encoded_latency.TOTAL_LATENCY_US_FIELD (output)
//         computed latency
// OUTPUTS:
//    None
//
// NOTES:
//    - this function shall be called after running the decoder, in non-ISR level.
//
// TRASHED REGISTERS:
//    r0 - r6, r10, do_loop, rMAC, I5, M0
// *****************************************************************************
.MODULE $M.latency_measure.calc_encoded_latency;
   .CODESEGMENT LATENCY_MEASURE_CALC_ENCODED_LATENCY_PM;
   .DATASEGMENT DM;

   $latency.calc_encoded_latency:

   // push rLink onto stack
   $push_rLink_macro;

   // return if no packet info cbuffer is provided
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   if Z  jump $pop_rLink_and_rts;

   // the size packet buffer info might not be enough,
   // this wont cause a problem, we delete one entry when
   // it's become full
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   call $cbuffer.calc_amount_space;
   Null = r0 - 2;
   if POS jump buffer_full_check_done;
      call $block_interrupts;
      
      // remove the two most recent entries from the buffer
      r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
      call $cbuffer.get_write_address_and_size;
      L5 = r1;
      I5 = r0;
      M0 = -4;        // remove 2 most recent enteries 
      r0 = M[I5, M0];
      r1 = I5;
      r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
      call $cbuffer.set_write_address;
      L5 = 0;
      call $unblock_interrupts;
   buffer_full_check_done:

   // make sure the decoder has generate some data
   r0 = M[r7 + $encoded_latency.DECODED_CBUFFER_FIELD];
   r2 = M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_DECODED_WR_ADDR_FIELD];
   r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   r2 = r1 - r2;
   if Z jump $pop_rLink_and_rts;

   // if read address has not changed then return
   r0 = M[r7 + $encoded_latency.CODEC_CBUFFER_FIELD];
   r3 = M[r0 + $cbuffer.READ_ADDR_FIELD];
   r0 = M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_CODED_RD_ADDR_FIELD];
   Null = r0 - r3;
   if Z jump $pop_rLink_and_rts;;

   // get the amount of data in the info buffer
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   call $cbuffer.calc_amount_data;

   // number of packets not processed (two words of info per packet)
   r10 = r0 ASHIFT -1;

   // no process if no packet left
   if Z jump end;

   // we only process the oldest three packets, in fact in normal
   // situation we pass only the oldest packet
   r0 = r10 - 3;
   if POS r10 = r10 - r0;

   // open the info buffer for reading
   r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
   call $cbuffer.get_read_address_and_size;
   I5 = r0;
   L5 = r1;

   // get read pointer of the codec buffer
   r0 = M[r7 + $encoded_latency.CODEC_CBUFFER_FIELD];
   r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];

   // get the last read pointer that was processed
   r1 = M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_CODED_RD_ADDR_FIELD];

   // At this point
   //   r0 = new read address of the coded buffer
   //   r1 = previous read address of the coded buffer
   //   I5/L5: info buffer
   do search_loop;
      // read the boundary position
      r2 = M[I5, 1];

      // read the arrival time
      r4 = M[I5, 1];

      // when moving from previous address to new address,
      // see whether we have passed the boundary address of this packet
      call is_address_within_range;

      // if we have passed then packet decoding time started
      Null = r3;
      if NZ jump entry_found;

      // else keep searching
   search_loop:
   L5 = 0;
   // not found, so don't do anything
   jump end;

   entry_found:
      // ok, we have found an entry for the packet

      // first update the read pointer of the info buffer
      r1 = I5;
      r0 = M[r7 + $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD];
      call $cbuffer.set_read_address;
      L5 = 0;

      // now calculates the latency
      call $block_interrupts;

      // r4 = arrival time for the packet
      // r7 = input structure
      push r4;
      push r7;
      // calculate latency in pcm domain
      r7 = M[r7 + $encoded_latency.PCM_LATENCY_STRUCT_FIELD];
      call $latency.calc_pcm_latency;
      // r6 = latency in pcm domain
      pop r7;
      pop r4;

      // get current time
      r3 = M[$TIMER_TIME];

      // r4 = arrival time for the packet
      // r3 = current time
      // r6 = pcm latency ahead
      r4 = r3 - r4;
      if NEG r4 = -r4;
      r4 = r4 + r6;
      if NEG jump end_calc;

      // less the amount of samples created this time
      r0 = M[r7 + $encoded_latency.DECODED_CBUFFER_FIELD];
      call $cbuffer.get_write_address_and_size;
      r2 = M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_DECODED_WR_ADDR_FIELD];
      r0 = r0 - r2;
      if NEG r0 = r0 + r1;

      // get inverse sample rate
      r1 = M[r7 + $encoded_latency.DECODER_INV_SAMPLE_RATE_FIELD];
      r1 = M[r1];
      // fix for warp rate
      r2 = M[r7 + $encoded_latency.CURRENT_WARP_RATE_FIELD];
      if Z jump no_warp;
         // get ptr to a ptr
         r2 = M[r2];
         if Z jump no_warp;
         r2 = M[r2];
      no_warp:            
      r3 = r1 * r2 (frac);    // r3 = 1/fs * warp
      r2 = r3 * r2 (frac);    // r2 = 1/fs * warp^2
      r3 = r1 + r3;
      r1 = r3 + r2;

      // compute q31.17 result 
      rMAC = r0 * r1;

      // convert to 24.24
      rMAC = rMAC ASHIFT $latency.PCM_LATENCY_SHIFT;

      // upper 24 bits is the amount of time it will take the data to play out of this cbuffer
      r1 = rMAC1;

      r4 = r4 - r1;
      if NEG jump end_calc;

      // see if min search enabled
      r10 = M[r7 + $encoded_latency.SEARCH_MIN_LEN_FIELD];
      if Z jump min_done;

      // max 4 hist value
      r0 = r10 - 4;
      if POS r10 = r10 - r0;
      r10 = r10 - 1;

      // search history to find minimum
      I5 = r7 + ($encoded_latency.HIST_LATENCY_US_FIELD);
      r1 = M[I5, 1];
      do loop_min;
          // read next val
          r0 = M[I5, -1];

          // min calc
          Null = r0 - r1;
          if NEG r1 = r0;

          // store in previous location
          M[I5, 2] = r0;
      loop_min:

      // store new calc and do min
      r0 = M[I5, -1];
      M[I5, 0] = r4;
      Null = r4 - r1;
      if POS r4 = r1;
      min_done:

      // save calculated latency
      M[r7 + $encoded_latency.TOTAL_LATENCY_US_FIELD] = r4;
      end_calc:

      call $unblock_interrupts;

   end:
   // update last read address for coded buffer
   r0 = M[r7 + $encoded_latency.CODEC_CBUFFER_FIELD];
   r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];
   M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_CODED_RD_ADDR_FIELD] = r0;

   // update last write address for decoded buffer
   r0 = M[r7 + $encoded_latency.DECODED_CBUFFER_FIELD];
   r0 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   M[r7 + $encoded_latency.LATENCY_MEASUREMENT_LAST_DECODED_WR_ADDR_FIELD] = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

   // ------------------------------------------------------------
   // Function: is_address_within_range
   //
   // Inputs:
   //    r0 = addr1, r1= addr2, r2=addr
   // Description:
   //     see whether addr2  <= addr < addr1 in a circular context
   //
   // Output: r3
   // ---------------------------------------------------------
   is_address_within_range:
   // default: yes, it's within range
   r3 = 1;
   Null = r0 - r1;
   if NEG jump neg_part;
   pos_part:
      // Start--------r1========>r0--------End(=Start)
      // to lie in [r1 r0] range, r1<=r2<r0
      Null = r2 - r0;
      if POS r3 = 0;
      Null = r2 - r1;
      if NEG r3 = 0;
      rts;

   neg_part:
      // Start========>r0--------r1=======>End(=Start)
      // to lie in [r1 r0] range, r1<=r2 or r2<r0
      Null = r2 - r1;
      if POS rts;
      Null = r2 - r0;
      if POS r3 = 0;
      rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $M.latency_measure.calc_inv_fs
//
// DESCRIPTION:
//    utility function that calculates inverse of fs suitable for latency measurement
//
// INPUTS:
//    r0 = input sample rate in Hz, minimum 8khz
//
// OUTPUTS:
//    r0 = (1/fs) or more precisely number of microseconds in 1 sample in Q6.17 format
//
// TRASHED REGISTERS:
//    rMAC
//
// *****************************************************************************
.MODULE $M.latency_measure.calc_inv_fs;
   .CODESEGMENT LATENCY_MEASURE_CALC_INV_FS_PM;
   $latency.calc_inv_fs:
    r0 = r0 LSHIFT 2;
    rMAC = 15625;
    Div = rMAC / r0;
    r0 = DivResult;
    rts;
.ENDMODULE;
#endif

