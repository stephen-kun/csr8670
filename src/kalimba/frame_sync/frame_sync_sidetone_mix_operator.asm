// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Frame Sync Sidetone mix operator
//
// DESCRIPTION:
//    In a headset type application it is often desirable to feed some of the
// received microphone signal back out on the speaker. This gives the user some
// indication the headset is on. This operator mixes data from a supplied buffer
// in with the "main" data stream.
//
// @verbatim
//      Received SCO data       +         Data to DAC
//      ---------------------->O---------------------->
//                             ^
//                             |
//                             O x g
//                             |
//                             |
//                    Received ADC data
// @endverbatim
//
//
//    The number of samples in the sidetone buffer is monitored at this point.
// If there are too few, extra samples are created by repeating the last sample
// from the buffer. If too many samples are present, one sample will be
// discarded during each call.
//
// When using the operator the following data structure is used:
//    - $frame_sync.sidetone_mix_op.INPUT_START_INDEX_FIELD = the input buffer
//       index
//    - $frame_sync.sidetone_mix_op.OUTPUT_START_INDEX_FIELD = the output
//       buffer index
//    - $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD = the address of the
//       sidetone cbuffer struc
//    - $frame_sync.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD = the number of
//       samples allowed to build up in the sidetone buffer
//    - $frame_sync.sidetone_mix_op.GAIN_FIELD = the address of the gain to
//       apply to the sidetone samples
//
// *****************************************************************************

#include "stack.h"
#include "cbops_vector_table.h"
#ifdef FRAME_SYNC_DEBUG // SP.  cbuffer debug
#include "frame_sync_stream_macros.h"
#endif
#ifdef PATCH_LIBS
   #include "patch_library.h"
#endif
#include "cbuffer.h"

.MODULE $M.frame_sync.sidetone_mix_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $frame_sync.sidetone_mix_op[$cbops.function_vector.STRUC_SIZE] =
      // reset function
      &$frame_sync.sidetone_mix_op.reset,
      // amount to use function
      &$frame_sync.sidetone_mix_op.amount_to_use,
      // main function
      &$frame_sync.sidetone_mix_op.main;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frame_sync.sidetone_mix_op.reset
//
// DESCRIPTION:
//    Reset routine for the side tone mix operator,
//    see $frame_sync.sidetone_mix_op.main
//
// INPUTS:
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, I0, L0
//
// *****************************************************************************
.MODULE $M.frame_sync.sidetone_mix_op.reset;
   .CODESEGMENT FRAME_SYNC_SIDETONE_MIX_OP_RESET_PM;
   .DATASEGMENT DM;

   $frame_sync.sidetone_mix_op.reset:

   // push rLink onto stack
   $push_rLink_macro;
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($frame_sync.FRAME_SYNC_SIDETONE_MIX_OPERATOR_ASM.RESET.PATCH_ID_0,r1) // af05_CVC_patches1
#endif

   // empty the sidetone buffer
   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   I0  = r2;
   r10 = r1;
   r0 = 0;
   do lp_clr_sidetone;
        M[I0,1]=r0;
lp_clr_sidetone:   
#else
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   // write a zero in the previous location
   r0 = M[I0,-1];
   r0 = 0;
   M[I0,1] = r0;

   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];
   r1 = I0;
   call $cbuffer.set_write_address;
   L0 = 0;
#endif
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frame_sync.sidetone_mix_op.main
//
// DESCRIPTION:
//    Operator that copies the output/input word and reads/writes the samples
//    to/from the sidetone buffer
//
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r5, r6, r10, rMAC, M1, I0, I1, I4, L0, L1, L4, DoLoop
//
// *****************************************************************************
#ifdef FRAME_SYNC_DEBUG

#define SetMinVal(x, val)              \
      r1 = M[r2 + val];                \
      NULL = r1 - x;                   \
      if POS r1 = x;                   \
      M[r2 + val] = r1

#define SetMaxVal(x, val)              \
      r1 = M[r2 + val];                \
      NULL = x - r1;                   \
      if POS r1 = x;                   \
      M[r2 + val] = r1

#endif

.MODULE $M.frame_sync.sidetone_mix_op.main;
   .CODESEGMENT FRAME_SYNC_SIDETONE_MIX_OP_MAIN_PM;
   .DATASEGMENT DM;

   $frame_sync.sidetone_mix_op.main:

   // push rLink onto stack
   $push_rLink_macro;
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($frame_sync.FRAME_SYNC_SIDETONE_MIX_OPERATOR_ASM.MAIN.PATCH_ID_0,r1) // af05_CVC_patches1
#endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $frame_sync.sidetone_mix_op.INPUT_START_INDEX_FIELD];

   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I0
   I0 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L0
   L0 = r1;
#ifdef BASE_REGISTER_MODE 
   // Get Base Address of buffer
   r1 = M[r5 + r0];
   push r1;
   pop  B0;
#endif

   // get the offset to the write buffer to use
   r0 = M[r8 + $frame_sync.sidetone_mix_op.OUTPUT_START_INDEX_FIELD];

   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I4
   I4 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L4
   L4 = r1;
#ifdef BASE_REGISTER_MODE 
   // Get Base Address of buffer
   r1 = M[r5 + r0];
   push r1;
   pop  B4;
#endif   

   // get the sidetone buffer read address and size
   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE   
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B1;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   // set the length & get the first DAC sample
   M1 = 1;
   I1 = r0;
   L1 = r1, rMAC = M[I0,M1];

   r0 = M[r8 + $frame_sync.sidetone_mix_op.AMOUNT_DATA_FIELD];
   // Check if we need to insert samples (later)
   // Limit transfer to available data
   r3 = r10 - r0;
   if NEG r3 = Null;

#ifdef FRAME_SYNC_DEBUG
   r2 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];

   // Sample Insertions
   r1 = M[r2 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD];
   r1 = r1 + r3;
   M[r2 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD] = r1;

   // Data In CBuffer
   SetMaxVal(r0,$frame_sync.DBG_MAX_IN_LEV);
   SetMinVal(r0, $frame_sync.DBG_MIN_IN_LEV);

   // Transfer
   SetMaxVal(r10,$frame_sync.DBG_MAX_OUT_LEV);
   SetMinVal(r10,$frame_sync.DBG_MIN_OUT_LEV);


   // Check for Reset
   r1 = M[r2 + $frame_sync.DBG_COUNT];
   r1 = r1 + 1;
   if NEG r1 = Null;
   Null = r1 - 5000;
   if NEG jump jp_no_reset;
      r1 = 0x7FFFFF;
      M[r2 + $frame_sync.DBG_MIN_IN_LEV] = r1;
      M[r2 + $frame_sync.DBG_MAX_IN_LEV] = Null;
      M[r2 + $frame_sync.DBG_MIN_OUT_LEV] = r1;
      M[r2 + $frame_sync.DBG_MAX_OUT_LEV] = Null;
jp_no_reset:
   M[r2 + $frame_sync.DBG_COUNT] = r1;
#endif

   // Amount to blend
   r10 = r10 - r3;
   // read the address of the gain to use and dereference it
   r1 = M[r8 + $frame_sync.sidetone_mix_op.GAIN_FIELD];
   r1 = M[r1];

   do write_loop;
      // calculate the current output sample and read a side tone sample
      r0 = M[I1,1];
      rMAC = rMAC + r0 * r1;
      // get the next DAC value and write the result
      rMAC = M[I0,1], M[I4,1] = rMAC;
write_loop:

   // Repeat Last sample of sidetone buffer
   r0 = M[I1,-1];
   r10 = r3, r0 = M[I1,M1];
   L1 = 0;
#ifdef BASE_REGISTER_MODE 
    push Null;
    pop B1;
#endif
   do write_loop2;
      // calculate the current output sample
      rMAC = rMAC + r0 * r1;
      // get the next DAC value and write the result
      rMAC = M[I0,1], M[I4,1] = rMAC;
   write_loop2:

   // set the read pointer in the side tone buffer
   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];
   r1 = I1;
   call $cbuffer.set_read_address;

   // zero the remaining length registers we have used
   L0 = 0;
   L4 = 0;
#ifdef BASE_REGISTER_MODE 
    push Null;
    B0 = M[SP-1];
    pop B4;
#endif
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.sidetone_mix_op.amount_to_use
//
// DESCRIPTION:
//    Operator that checks for sidetone buffer levels and removes samples if
//    necessary
//
// INPUTS:
//    - r5 = the minimum of the number of input samples available and the
//           amount of output space available
//    - r6 = the number of input samples available
//    - r7 = the amount of output space available
//    - r8 = pointer to operator parameter structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r10, DoLoop, M0, I0, L0
//
// *****************************************************************************
.MODULE $M.frame_sync.sidetone_mix_op.amount_to_use;
   .CODESEGMENT FRAME_SYNC_SIDETONE_MIX_OP_AMOUNT_TO_USE_PM;
   .DATASEGMENT DM;

   $frame_sync.sidetone_mix_op.amount_to_use:

#ifdef FRAME_SYNC_DEBUG
   r2 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];
   r0 = M[r8 + $frame_sync.sidetone_mix_op.TIMER_PERIOD_SAMPLES_FIELD];
   M[r2 + $frame_sync.DBG_PACKET_SIZE_FIELD] = r0;
   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD];
   M[r2 + $frame_sync.DBG_CBUFFER_COPY_THRESHOLD_FIELD] = r0;
#endif

   // push rLink onto stack
   $push_rLink_macro;
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($frame_sync.FRAME_SYNC_SIDETONE_MIX_OPERATOR_ASM.AMOUNT_TO_USE.PATCH_ID_0,r1) // af05_CVC_patches1
#endif

   M0 = 1;
   // calculate the number of samples in the sidetone buffer
   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   M[r8 + $frame_sync.sidetone_mix_op.AMOUNT_DATA_FIELD] = r0;

   // if amount of data in ST buffer > threshold, dump excess
   r3 = M[r8 + $frame_sync.sidetone_mix_op.TIMER_PERIOD_SAMPLES_FIELD];
   r1 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD];
   r1 = r1 + r3;
   // Limit to size minus period
   r2 = r2 - r3;
   r2 = r2 - 1;
   if NEG r2 = Null;
   Null = r2 - r1;
   if NEG r1 = r2;

   r10 = r0 - r1;
   if LE jump $pop_rLink_and_rts;

   // Adjust Data in Port
   M[r8 + $frame_sync.sidetone_mix_op.AMOUNT_DATA_FIELD] = r1;

   r0 = M[r8 + $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD];

#ifdef FRAME_SYNC_DEBUG
   r1 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
   r1 = r1 + r10;
   M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD] = r1;
#endif

   call $cbuffer.advance_read_ptr;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
