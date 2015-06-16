// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1141152 $  $DateTime: 2011/11/02 20:31:09 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    DAC Synchronization operator
//
// DESCRIPTION:
//    The CBOPS library copies the minimum of the amount of data in the input
// buffers and the amount of space in the output buffers. However, for the DAC
// we want to maintain the Minimum amount of data in the Port to minimize
// latency.  On the other hand we need to maintain sufficient data in the Port to
// prevent a wrap condition where the read pointer (limit) passes the write
// pointer (offset).  Also, to maintain syncronization with the ADC/DAC and the
// rest of the system we need to drop samples at the DAC when they are inserted
// in the ADC and visa versa
//
//  The $frame_sync.dac_sync_op and $frame_sync.dac_wrap_op operators work in
//  conjunction to provide this functionality.
//
//  The $frame_sync.dac_wrap_op operator must be the last operator in the chain and
//  the $frame_sync.dac_sync_op operator should be inserted just before the
//  operator that actually write to the DAC.  If a sidetone mix operation is included
//  in the chain the $frame_sync.dac_sync_op operator should precede it as well
//
// *****************************************************************************

#include "stack.h"
#include "frame_sync_dac_sync_operator.h"
#include "cbops_vector_table.h"
#include "architecture.h"
#include "cbuffer.h"
#ifdef FRAME_SYNC_DEBUG // SP.  cbuffer debug
#include "frame_sync_stream_macros.h"
#endif


.MODULE $M.frame_sync.dac_sync_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $frame_sync.dac_sync_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,      // reset function
      $cbops.function_vector.NO_FUNCTION,      // amount to use function
      &$frame_sync.dac_sync_op.main;           // main function

.ENDMODULE;

.MODULE $M.frame_sync.dac_wrap_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $frame_sync.dac_wrap_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,      // reset function
      &$frame_sync.dac_wrap.amount_to_use,     // amount to use function
      &$frame_sync.dac_wrap.main;              // main function

.ENDMODULE;


.MODULE $M.frame_sync.dac_wrap_op;
   .CODESEGMENT FRAME_SYNC_DAC_SYNC_PM;
   .DATASEGMENT DM;

// *****************************************************************************
// MODULE:
//   $frame_sync.dac_wrap.amount_to_use
//
// DESCRIPTION:
//   DAC rate matching amount to use functions
//
// INPUTS:
//    - r5 = the minimum of the number of input samples available and the
//      amount of output space available
//    - r6 = the number of input samples available
//    - r7 = the amount of output space available
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    - r5 = the number of samples to process
//    - r6 = the number of input samples available (adjusted)
//
// TRASHED REGISTERS:
//    r0 - r10
//
// *****************************************************************************
$frame_sync.dac_wrap.amount_to_use:
    // r7 (Minimum space) is not valid in stereo configuration
    // r6 (Minimum data)  is amount of data in Rcv Out CBuffer

    // Check for Connectivity
    NULL = r7;
    if Z r6=NULL;
    r0 = M[r8 + $frame_sync.dac_wrap_op.LEFT_PORT_FIELD];
    r0 = r0 AND  ($cbuffer.PORT_NUMBER_MASK | $cbuffer.WRITE_PORT_OFFSET);
    r1 = M[r0 + $cbuffer.port_limit_addr];
    if Z rts;

	M1 = 1;

    /****************** Calculate Data in Port ************************/
    $push_rLink_macro;
    r0 = M[r8 + $frame_sync.dac_wrap_op.LEFT_PORT_FIELD];
    call calc_dac_amount_of_data;
    r10 = M[r8 + $frame_sync.dac_wrap_op.MAX_ADVANCE_FIELD];
    // r2 is data in port, r10 is max advance,

    // Limit amount of data after transfer to two times maximum advance
    r3  = r10 ASHIFT 1;
    r0  = r3 - r2;
    if NEG r0 = Null;

    // r10 is maximum transfer per period
    // r0 is maximum transfer for this period
    // Scale r10 and r0 if input/output are at different rates
    r4 = M[r8 + $frame_sync.dac_wrap_op.RATE_SCALE_FIELD];
    r0  = r0  * r4 (frac);
    r10 = r10 * r4 (frac);

    // Limit transfer to scaled maximum advance plus one.
    r10 = r10 + M1;
    Null = r0 - r10;
    if POS r0 = r10;

    // Update SideTone Parameters
    r1 = M[r8 + $frame_sync.dac_wrap_op.PACKET_SIZE_PTR_FIELD];
    if NZ M[r1] = r10;
    r4 = r10 ASHIFT 1;
    r1 = M[r8 + $frame_sync.dac_wrap_op.COPY_LIMIT_PTR_FIELD];
    if NZ M[r1] = r4;

    // limit transfer (r5) of input (r6) to desired transfer (r0)
    r5   = r6;
    Null = r5 - r0;
    if POS r5 = r0;

    // Update Drop/Insert count from ADC
    r0 = r5;
    r4 = r8 + $frame_sync.dac_wrap_op.DROP_INSERT_FIELD;
    r3 = M[r8 + $frame_sync.dac_wrap_op.PTR_ADC_STATUS_FIELD];
    if Z r3=r4;
    r1 = M[r3];
    M[r3]=NULL;
    // Number of Drop/Inserts to apply (r3)
    r3 = r1 + M[r4];
    if Z    jump jp_adc_drop_insert_done;
    if NEG  jump jp_adc_dropped;
jp_adc_inserted:
        // Ignore excessive insertion
        NULL = r3 - r10;
        if POS r3=NULL;
        // ADC inserted samples.    Increase samples For Reference (DAC drops samples)
        r5 = r5 + r3;
        // Limit By input
        Null = r5 - r6;
        if POS r5 = r6;
        // Subtract change in transfer.
        r3 = r3 - r5;
        r3 = r3 + r0;
        jump jp_adc_drop_insert_done;
jp_adc_dropped:
        // Ignore excessive drops (r3 < 0)
        NULL = r3 + r10;
        if NEG r3=NULL;
        // ADC dropped samples.     Increase samples for DAC
        r0 = r0 - r3;
        // Verify input not stalled.   
        NULL = r5;
        if NZ r3 = NULL;
jp_adc_drop_insert_done:
    // Account for samples droppped/inserted
    M[r8 + $frame_sync.dac_wrap_op.DROP_INSERT_FIELD]=r3;
    // Save DAC Transfer
    M[r8 + $frame_sync.dac_wrap_op.XFER_AMOUNT_FIELD] = r0;

    // If no transfer do wrap prevention
    NULL = r5;
    if Z jump check_for_wrapping;
    jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $frame_sync.dac_wrap.main
//
// DESCRIPTION:
//    Operator set $cbops.amount_to_use AND $cbops.amount_written to advance
//    CBuffers and handles DAC wrap protection
//
// INPUTS:
//    - r5 = pointer to the list of input and output buffer start addresses
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
$frame_sync.dac_wrap.main:
    // Restore CBuffer Pointer
    r3 = M[r8+$frame_sync.dac_wrap_op.CBUFFER_PTR_FIELD];
    r4 = M[r8+$frame_sync.dac_wrap_op.INPUT_INDEX_FIELD];
    M[r6 + r4]=r3;
    // Restore Reference Xfer to advance Buffer
    r0 = M[r8 + $frame_sync.dac_wrap_op.XFER_AMOUNT_FIELD];
    M[$cbops.amount_to_use]  = r0;
    M[$cbops.amount_written] = r0;

    // Check for Buffer Wrapping
    $push_rLink_macro;

check_for_wrapping:
    r4 = M[r8 + $frame_sync.dac_wrap_op.MAX_ADVANCE_FIELD];

    // Mono DAC
    r3 = M[r8 + $frame_sync.dac_wrap_op.LEFT_PORT_FIELD];
    call CheckDacWrap;
    // Need to handle hardware sync of DAC ports
    r3 = M[r8 + $frame_sync.dac_wrap_op.RIGHT_PORT_FIELD];
    if NZ call SyncChannel;    
    jump $pop_rLink_and_rts;
// *****************************************************************************
// MODULE:
//   CheckDacWrap
//
// DESCRIPTION:
//    If amount of data in port is less than Maximum Transfer per period
//    Zero insert to prevent or recover from buffer wrap
//
// INPUTS:
//    - r3  = DAC Port ID
//    - r4  = Padded Maximum Transfer per period
//    - r8  = Data Structure
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//    r0,r1,r2
//
// *****************************************************************************
CheckDacWrap:
    // Make sure port is connected
    r0 = r3 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
    Null = M[$cbuffer.port_offset_addr + r0];
    if Z rts;
    $push_rLink_macro;
    // force an MMU buffer set
    Null = M[$PORT_BUFFER_SET];
    r0 = r3;
    call calc_dac_amount_of_data;
    // r2 is number of samples in port, negative if overflow
    r10 = r4 - r2;
    if LE jump $pop_rLink_and_rts;
    // Save number of insertions
    r0 = M[r8 + $frame_sync.dac_wrap_op.WRAP_COUNT_FIELD];
    r0 = r0 + r10;
    M[r8 + $frame_sync.dac_wrap_op.WRAP_COUNT_FIELD]=r0;
    // Zero insert to align MMU Buffer
    r0 = r3;
    call $cbuffer.get_write_address_and_size;
    do lp_insert_loop;
        M[r0] = Null;
        nop;
    lp_insert_loop:
    r0 = r3;
    call $cbuffer.set_write_address;
    jump $pop_rLink_and_rts;
    // r8 = data object
SyncChannel:   
    // Make sure both ports are actually connected
    r0 = M[r8 + $frame_sync.dac_wrap_op.RIGHT_PORT_FIELD];
    r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
    r1 = M[$cbuffer.port_offset_addr + r0];
    if Z rts;
    r0 = M[r8 + $frame_sync.dac_wrap_op.LEFT_PORT_FIELD];
    r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
    r2 = M[$cbuffer.port_offset_addr + r0];
    if Z rts;
    // force an MMU buffer set
    Null = M[$PORT_BUFFER_SET];
    // Compare Left and Right offsets
    r3 = M[$cbuffer.port_buffer_size + r0];
    r3 = r3 - 1;
    r2 = M[r2]; // Left offset
    r1 = M[r1]; // Right Offset
    r2 = r2 - r1;
    r2 = r2 AND r3;
    r10 = r2 ASHIFT -1;
    if LE rts;
    // Save number of insertions
    r0 = M[r8 + $frame_sync.dac_wrap_op.WRAP_COUNT_FIELD];
    r0 = r0 + r10;
    M[r8 + $frame_sync.dac_wrap_op.WRAP_COUNT_FIELD]=r0;
    $push_rLink_macro;
    // Zero insert to align MMU Buffer (Right)
    r0 = M[r8 + $frame_sync.dac_wrap_op.RIGHT_PORT_FIELD];;
    call $cbuffer.get_write_address_and_size;
    do lp_insert_loop_R;
        M[r0] = Null;
        nop;
    lp_insert_loop_R:
    r0 = M[r8 + $frame_sync.dac_wrap_op.RIGHT_PORT_FIELD];;
    call $cbuffer.set_write_address;
    jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $frame_sync.dac_sync_op.main
//
// DESCRIPTION:
//    Operator sets $cbops.amount_to_use and handles sample insertion for DAC
//
// INPUTS:
//    - r5 = pointer to the list of input and output buffer start addresses
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
$frame_sync.dac_sync_op.main:

    r9 = M[r8 + $frame_sync.dac_sync_op.STRUC_PTR_FIELD];

    // Save Rcv CBuffer Pointer
    r4 = M[r9+$frame_sync.dac_wrap_op.INPUT_INDEX_FIELD];
    r3 = M[r6 + r4];
    M[r9+$frame_sync.dac_wrap_op.CBUFFER_PTR_FIELD]=r3;

    // Set $cbops.amount_to_use for DAC outout
    r0 = M[r9 + $frame_sync.dac_wrap_op.XFER_AMOUNT_FIELD];     // DAC Xfer
    M[r9 + $frame_sync.dac_wrap_op.XFER_AMOUNT_FIELD]=r10;      // Reference Xfer
    M[$cbops.amount_to_use]=r0;
    r10 = r0 - r10;
#ifdef FRAME_SYNC_DEBUG
    if NEG jump jp_dac_drop;
#endif
    if LE rts;

    // DAC is inserting samples
#ifdef FRAME_SYNC_DEBUG
    r0 = M[&$cbops.buffer_pointers + r4];
    r1 = M[r0 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD];
    r1 = r1 + r10;
    M[r0 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD]  = r1;
#endif

    r0 = M[r7 + r4];
    I0 = r3;
    L0 = r0;
#ifdef BASE_REGISTER_MODE
   // Get Base Address of buffer
   r1 = M[r5 + r4];
   push r1;
   pop  B0;
#endif

    // Duplicate sample and backtrack buffer
    r0 = M[I0,-1];
    do lp_ins_dac;
        M[I0,-1]=r0;
lp_ins_dac:
    r0 = M[I0,1];
    L0 = NULL;

#ifdef BASE_REGISTER_MODE
    push Null;
    pop B0;
#endif

    // Save buffer with inserted samples to be used by DAC
    r3 = I0;
    M[r6 + r4]=r3;
    rts;

#ifdef FRAME_SYNC_DEBUG
jp_dac_drop:
    r0 = M[&$cbops.buffer_pointers + r4];
    r1 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
    r1 = r1 - r10;
    M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD]  = r1;
    rts;
#endif

// *****************************************************************************
// MODULE:
//   calc_dac_amount_of_data
//
// DESCRIPTION:
//   Calculate amount of data in port
//
//
// INPUTS:
//    - r0 = DAC Port ID
//
// OUTPUTS:
//    - r2 = data words in port (size-space)
//      negative if a wrap occured.  Assumes that advance is
//      always less than half the buffer
//
// TRASHED REGISTERS:
//    r0,r1,r2
//
// *****************************************************************************
calc_dac_amount_of_data:
    $push_rLink_macro;
    call $cbuffer.calc_amount_space.its_a_port;
    // r0 is space in port minus one, r2 is buffer size in bytes
    r2  = r2 LSHIFT -1;
    r2  = r2 - r0;
    Null = r0 - r2;
    if NEG r2 = Null - r0;

    r0 = M[r8 + $frame_sync.dac_wrap_op.BUFFER_ADJUST_FIELD];
    r2 = r2 - r0;
    // r2 is number of samples in port, negative if overflow
    jump $pop_rLink_and_rts;















.ENDMODULE;
