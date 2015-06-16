// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Revision: #3 $  $Date: 2010/03/05 $
// *****************************************************************************

#ifndef CODEC_STREAM_ENCODE_MUX_INCLUDED
#define CODEC_STREAM_ENCODE_MUX_INCLUDED

#include "codec_library.h"

// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.register_sink
//
// DESCRIPTION:
//    Adds a handler to the list of output ports to deliver audio to.
//
// INPUTS:
//    - r1 = pointer to stream_encode.mux.sink_handler_struc
//    - r2 = codec cbuffer to get data from
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0, r2, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.register_sink;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.register_sink:

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.REGISTER_SINK.PATCH_ID_0, r1)
   pop r1;
#endif

   // also set its state to streaming
   r0 = $codec.stream_encode.STATE_STREAMING;
   M[r1 + $codec.stream_encode.mux.STATE_FIELD] = r0;

   // populate the cbuffer structure
   r0 = M[r2 + $cbuffer.SIZE_FIELD];
   M[r1 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD + $cbuffer.SIZE_FIELD] = r0;
   r0 = M[r2 + $cbuffer.READ_ADDR_FIELD];
   M[r1 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD + $cbuffer.READ_ADDR_FIELD] = r0;
   r0 = M[r2 + $cbuffer.WRITE_ADDR_FIELD];
   M[r1 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD + $cbuffer.WRITE_ADDR_FIELD] = r0;
#ifdef BASE_REGISTER_MODE
   r0 = M[r2 + $cbuffer.START_ADDR_FIELD];
   M[r1 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD + $cbuffer.START_ADDR_FIELD] = r0;
#endif

  // mark this one as the last
   M[r1 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD] = 0;
   r2 = &$codec.stream_encode.mux.output_sinks;
   find_connection_tail:
      r0 = r2;
      r2 = M[r0 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
   if NZ jump find_connection_tail;

   found:
   M[r0 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD] = r1;


   // done
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.unregister_sink
//
// DESCRIPTION:
//    Removes the supplied handler from the list of output sinks to deliver
// audio to.
//
// INPUTS:
//    - r1 = BCID - connection ID stored in the strcuture
//
// OUTPUTS:
//    r0 = the top of list = zero if empty
//
// TRASHED REGISTERS:
//    r1, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.unregister_sink;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.unregister_sink:
   $push_rLink_macro;

  // find this handler in the list
   push r2;
   push r3;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.UNREGISTER_SINK.PATCH_ID_0, r2)
#endif

   r0 = &$codec.stream_encode.mux.output_sinks;
   find_handler_field:
      r2 = r0;
      r0 = M[r2 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
      if Z jump not_found;
      r3 = M[r0 + $codec.stream_encode.mux.TERMINAL_FIELD];
      Null = r3 - r1;
   if NZ jump find_handler_field;

   r3 = M[r0 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
   M[r2 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD] = r3;
   call $malloc.free;

   not_found:
   pop r3;
   pop r2;
   r0 = M[$codec.stream_encode.mux.output_sinks];
   jump $pop_rLink_and_rts;

.ENDMODULE;


//*****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.find_sink
//
// DESCRIPTION:
//    Finds the supplied handler from the list of output sinks to deliver
// audio to.
//
// INPUTS:
//    - r1 = Terminal ID stored in the strcuture
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r1, r2, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.find_sink;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.find_sink:

  // find this handler in the list
   push r2;
   push r3;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.FIND_SINK.PATCH_ID_0, r2)
#endif

   r0 = &$codec.stream_encode.mux.output_sinks;
   find_handler_field:
      r2 = r0;
      r0 = M[r2 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
      if Z jump not_found;
      r3 = M[r0 + $codec.stream_encode.mux.TERMINAL_FIELD];
      Null = r3 - r1;
   if NZ jump find_handler_field;
   jump found;

   not_found:
   r0 = Null;

   found:
   pop r3;
   pop r2;
   rts;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.configure_sink_cid
//
// DESCRIPTION:
//    Updates the specified handler with the new L2CAP CID
//
// INPUTS:
//    - r1 = BCID - connection ID stored in the strcuture
//    - r2 = L2CAP CID to be stored in the structure
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r1, r2, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.configure_sink_cid;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.configure_sink_cid:

  push r3;
  push r2;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.CONFIGURE_SINK_CID.PATCH_ID_0, r2)
#endif

  // find this handler in the list
   r0 = &$codec.stream_encode.mux.output_sinks;
   find_handler_field:
      r2 = r0;
      r0 = M[r2 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
      if Z jump not_found;
      r3 = M[r0 + $codec.stream_encode.mux.TERMINAL_FIELD];
      Null = r3 - r1;
   if NZ jump find_handler_field;

   pop r2;
   M[r0 + $codec.stream_encode.mux.L2CAP_CID_FIELD] = r2;
   jump done;

   not_found:
   pop r2;

   done:
   pop r3;
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.update_cbuffer_read_pointer
//
// DESCRIPTION:
//    Updates the read pointer of the supplied cbuffer structure to the last
// read pointer of the Sink handler list
//
// INPUTS:
//    r5 = M[$codec.stream_encode.struc_ptr]
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-4, r6, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.update_cbuffer_read_pointer;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.update_cbuffer_read_pointer:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.UPDATE_CBUFFER_READ_POINTER.PATCH_ID_0, r3)
#endif

   // get the handler of the structure with the tail pointer
   call $codec.stream_encode.mux.find_tail_pointer;

   // should we update anything?
   Null = r3;
   if Z jump $pop_rLink_and_rts;

   // r3 should now point to the handler with the tail pointer - get the pointer
   r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   r1 = r0;
   r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
   call $cbuffer.set_read_address;

   // pop rLink from stack and exit
   jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.find_tail_pointer
//
// DESCRIPTION:
//    Returns address of handler structure with the tail pointer
//
// INPUTS:
//    None
//
// OUTPUTS:
//    - Sinks streaming:
//     - r3 = handler structure with tail pointer
//    - No sinks connected:
//     - r3 = $codec.stream_encode.mux.LAST_SINK_HANDLER
//
// TRASHED REGISTERS:
//    r0-4, r6, r10, DoLoop (NOT r5)
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.find_tail_pointer;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.find_tail_pointer:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.FIND_TAIL_POINTER.PATCH_ID_0, r3)
#endif

   // set r3 to nothing found
   r3 = Null;

   // get the head of the list
   r4 = M[$codec.stream_encode.mux.output_sinks];
   if Z rts;

   // push rLink onto stack
   $push_rLink_macro;
   // block inputs we're messing with read and write pointers
   call $block_interrupts;

   // set to something small
   r6 = 0;
   find_tail_pointer:
      // how much data is there in this structure
      r0 = r4 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
      call $cbuffer.calc_amount_data;
      r1 = r0 - r6;
      if NEG jump not_possible_tail_pointer;
         r3 = r4;
         r6 = r6 + r1;
      not_possible_tail_pointer:

      // get the next cbuffer structure
      r4 = M[r4 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
   if NZ jump find_tail_pointer;

   // unblock interrupts
   call $unblock_interrupts;
   // pop rLink from stack and exit
   jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.update_write_pointers
//
// DESCRIPTION:
//    Updates the write pointers of each of the sink handler cbuffer structures
//    with the write pointer of the supplied codec cbuffer structure. The state
//    of the STOPPED sinks is also monitored for revival.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure to update
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-4, r10, DoLoop (NOT r5)
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.update_cbuffer_write_pointer;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.update_cbuffer_write_pointer:

#if defined(PATCH_LIBS)
   push r0;
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.UPDATE_CBUFFER_WRITE_POINTER.PATCH_ID_0, r3)
   pop r0;
#endif

   // get the head of the list
   r3 = M[$codec.stream_encode.mux.output_sinks];
   if Z rts;

   // push rLink onto stack
   $push_rLink_macro;

   // get the write address
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   r4 = r0;

   // block interrupts around this - we're messing with read and write pointers
   call $block_interrupts;

   find_tail_pointer:
      // is this one streaming?
      Null = M[r3 + $codec.stream_encode.mux.STATE_FIELD];
      if NZ jump set_write_pointer;
         #if defined(L2CAP_FRAME)
            Null = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];
            if Z jump non_l2cap_operation;
               // set this write pointer
               r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
               r1 = r4;
               call $cbuffer.set_write_address;

               // purge more data
               call $codec.stream_encode.mux.discard_codec_data;
               Null = r6;
               if NZ jump get_next_sink;

               // switch to streaming state if no more data to purge
               r1 = $codec.stream_encode.STATE_STREAMING;
               M[r3 + $codec.stream_encode.mux.STATE_FIELD] = r1;
               jump get_next_sink;
            non_l2cap_operation:
         #endif

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.UPDATE_CBUFFER_WRITE_POINTER.PATCH_ID_1, r1)
#endif

         // has anybody read anything from this one?
         r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_read_address_and_size_and_start_address;
#else
         call $cbuffer.get_read_address_and_size;
#endif

         r1 = M[r3 + $codec.stream_encode.mux.PREV_READ_PNTR_FIELD];
         Null = r1 - r0;
         if Z jump still_not_streaming;

         resume_streaming:
            r1 = $codec.stream_encode.STATE_STREAMING;
            M[r3 + $codec.stream_encode.mux.STATE_FIELD] = r1;
            jump set_write_pointer;

         still_not_streaming:
         // this still isn't streaming, leave one packet in the buffer
         r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
#ifdef BASE_REGISTER_MODE
         call $cbuffer.get_write_address_and_size_and_start_address;
#else
         call $cbuffer.get_write_address_and_size;
#endif
         Null = r0 - r4;
         if Z jump get_next_sink;

         // move the read address on and save then new read address
         r1 = r0;
         M[r3 + $codec.stream_encode.mux.PREV_READ_PNTR_FIELD] = r1;
         r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
         call $cbuffer.set_read_address;

      set_write_pointer:
         // set this write pointer
         r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
         r1 = r4;
         call $cbuffer.set_write_address;

      get_next_sink:
      // get the next sink structure
      r3 = M[r3 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
   if NZ jump find_tail_pointer;

   // unblock interrupts
   call $unblock_interrupts;

   // pop rLink from stack and exit
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.find_tail_pointer_and_reset
//
// DESCRIPTION:
//    Finds the last structure with the tail pointer and resets that sink. if in
//    L2CAP mode, integer number of L2CAP packets are discarded. If the amount
//    of data available is less than the amount of data to be discarded, the
//    remaining amount is saved and discarded lated when updating the write
//    pointer next time.
//    If not in L2CAP mode, purges the sink with the tail pointer and puts it in
//    STOPPED mode, where its read pointer is monitored for revival.
//
// INPUTS:
//    - r5 = M[$codec.stream_encode.struc_ptr]
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0-4, r10, DoLoop, M0, L0, I0
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.find_tail_pointer_and_reset;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.find_tail_pointer_and_reset:


   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.FIND_TAIL_POINTER_AND_RESET.PATCH_ID_0, r3)
#endif

   // block interrupts
   call $block_interrupts;

   call $codec.stream_encode.mux.find_tail_pointer;
   Null = r3;
   if Z jump exit_and_dont_idle;

   // reset that handler
   #if defined(L2CAP_FRAME)
      r4 = M[r5 + $codec.stream_encode.MEDIA_HDR_ADDR_FIELD];
      if Z jump non_l2cap_operation;
         // Discard 1 or 2 whole ATUs + L2CAP headers from this stream before
         // resuming streaming mode. It is assumed that whole L2CAP packets are
         // copied out in the copy handler, i.e. the remaining data in cbuffers
         // are whole L2CAP packets. As L2CAP packets can have an odd number of
         // bytes in them, two whole L2CAP packets are skipped to make sure the
         // byte-alignment is remains intact, if ATU size is odd.

         // calculate amount to discard (i.e. 1 or 2 L2CAP packets)
         r6 = M[r4 + $codec.media_header.L2CAP_ATU_SIZE_FIELD];
         // Add the L2CAP header size (4 bytes)
         r6 = r6 + 4;
         r1 = r6 ASHIFT 1;
         Null = r6 AND 1;
         if NZ r6 = r1;
         // convert bytes to words
         r6 = r6 ASHIFT -1;
         M[r3 + $codec.stream_encode.mux.AMOUNT_LEFT_TO_DISCARD_FIELD] = r6;

         // discard some/all of the data
         call $codec.stream_encode.mux.discard_codec_data;

         jump set_state_to_stopped;

      non_l2cap_operation:
   #endif

   // purge the clogged sink and store its read pointer
   r0 = M[r5 + $codec.stream_encode.OUT_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   r1 = r0;
   M[r3 + $codec.stream_encode.mux.PREV_READ_PNTR_FIELD] = r0;
   r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
   call $cbuffer.set_read_address;

   set_state_to_stopped:
   // now mark it as not streaming
   r1 = $codec.stream_encode.STATE_STOPPED;
   M[r3 + $codec.stream_encode.mux.STATE_FIELD] = r1;

   // if all streams are stopped, reset the encoder
   r3 = M[$codec.stream_encode.mux.output_sinks];
   if Z jump exit;

   find_not_stopped_loop:
      // if not stopped
      r0 = M[r3 + $codec.stream_encode.mux.STATE_FIELD];
      Null = r0 - $codec.stream_encode.STATE_STOPPED;
      if NE jump exit_and_dont_idle;

      // get the next sink structure
      r3 = M[r3 + $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD];
   if NZ jump find_not_stopped_loop;
   r3 = 0;//1;  // idle
   jump exit;

   exit_and_dont_idle:
   r3 = 0;  // dont idle

   // unblock interrupts
   exit:
   call $unblock_interrupts;

   // pop rLink from stack and exit
   jump $pop_rLink_and_rts;

.ENDMODULE;


#if defined(L2CAP_FRAME)
// *****************************************************************************
// MODULE:
//    $codec.stream_encode.mux.discard_codec_data
//
// DESCRIPTION:
//    Discards codec data from a given sink
//
// INPUTS:
//    - r3 = sink handler structure to purge
//
// OUTPUTS:
//    - r6 = remaining amount of data to be discarded (words)
//
// TRASHED REGISTERS:
//    r0-2, r6, r10, DoLoop, M0, L0, I0
//
// *****************************************************************************
.MODULE $M.codec.stream_encode.mux.discard_codec_data;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $codec.stream_encode.mux.discard_codec_data:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($codec.STREAM_ENCODE_MUX_ASM.DISCARD_CODEC_DATA.PATCH_ID_0, r6)
#endif

   // calculate amount to discard right now
   r6 = M[r3 + $codec.stream_encode.mux.AMOUNT_LEFT_TO_DISCARD_FIELD];
   if Z jump $pop_rLink_and_rts;
   r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
   call $cbuffer.calc_amount_data;
   Null = r0 - r6;
   if GT r0 = r6;
   // remaining amount to discard
   r6 = r6 - r0;
   M[r3 + $codec.stream_encode.mux.AMOUNT_LEFT_TO_DISCARD_FIELD] = r6;
   M0 = r0;
   r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0; L0 = r1;
   r0 = M[I0, M0];
   r0 = r3 + $codec.stream_encode.mux.CBUFFER_STRUC_FIELD;
   r1 = I0;
   call $cbuffer.set_read_address;
   L0 = 0;

   // pop rLink from stack and exit
   jump $pop_rLink_and_rts;

.ENDMODULE;
#endif // #if defined(L2CAP_FRAME)

#endif