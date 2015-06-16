// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Utilities file for frame sync library
//
// DESCRIPTION:
//    This file contains utility modules used throughout frame sync library.
//    Specifically, it contains, a purge function, an advance read ptr function,
//    which can be used to remove samples (provided a check has been made that
//    there is enough data to remove) and an insert zeros function.
//
// *****************************************************************************

#include "stack.h"
#ifdef FRAME_SYNC_DEBUG // SP.  cbuffer debug
#include "frame_sync_stream_macros.h"
#endif

// *****************************************************************************
// MODULE:
//    $M.frame_sync.cbuffer.purge
//
// DESCRIPTION:
//    Purge cbuffers by setting write pointer to read pointer
//
// INPUTS:
//    - r2 = Pointer to cbuffer struc
//    - r8 = Pointer to frame process struc
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// NOTES:
//    Interrupts should be blocked around call to this function to prevent
//    pre-emption during execution.
//    Currently used only on cbuffers, not on ports.
//
// *****************************************************************************
.MODULE $M.frame_sync.cbuffer.purge;
   .CODESEGMENT FRAME_SYNC_CBUFFER_PURGE_PM;
   .DATASEGMENT DM;

$frame_sync.cbuffer.purge:
   $push_rLink_macro;
   r0 = r2;
#ifdef BASE_REGISTER_MODE
   // Save r2 in stack, as it will be modified.
   push r2;
   call $cbuffer.get_read_address_and_size_and_start_address;
   // Restore r2; the value returned by the function in r2 is not used.
   pop r2;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   r1 = r0;
   r0 = r2;
   call $cbuffer.set_write_address;
   M[r8 + $frame_sync.frame_process.MIN_AMOUNT_READY_FIELD] = Null;
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.run_function_table
//
// DESCRIPTION:
//    This function calls a series of functions defined in the NULL termininated
//    processing table passed in through register (r4).  Each entry in the table
//   has the following three fields:
//    1) Ptr to function to be called.
//    2) Value to insert into register (r7) before calling function
//    3) Value to insert into register (r8) before calling function
//
// INPUTS:
//    - r4 holds the address of the processing table to run
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r4,r5,r7,r8 (plus processing function usage)
//
// NOTE:
//   There are no limitations on register usage by a processing function
//
// *****************************************************************************
.MODULE $M.frame_sync.run_function_table;
   .CODESEGMENT   FRAME_SYNC_RUN_FUNCTION_TABLE_PM;
   .DATASEGMENT   DM;

$frame_sync.run_function_table:
   $push_rLink_macro;
lp_proc_loop:
   // Func
   r5 = M[r4];
   // NULL Function terminates List
   if Z jump $pop_rLink_and_rts;
   // Data
   r7 = M[r4 + 1];
   // Data
   r8 = M[r4 + 2];
   r4 = r4 + 3;
   push r4;
   // Process Module
   call r5;
   pop r4;
   jump lp_proc_loop;


.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.handlers
//
// DESCRIPTION:
//    This function calls a series of functions defined in the NULL termininated
//    registration table passed in through register (r4).  Each entry in the
//    table has the following four fields:
//    1) Value to insert into register (r1) before calling function
//    2) Value to insert into register (r2) before calling function
//    3) Value to insert into register (r3) before calling function
//    4) Pointer to function to call to register handler
//
// INPUTS:
//    - r4 holds the address of the registration table to run
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-r4 (plus processing function usage)
//
// NOTE:
//   There are no limitations on register usage by a registration function
//
// *****************************************************************************
.MODULE $M.frame_sync.handlers;
   .CODESEGMENT   FRAME_SYNC_HANDLERS_PM;
   .DATASEGMENT   DM;
   .VAR LOOP_COUNT;

$frame_sync.register_handlers:

   $push_rLink_macro;
lp_proc_loop:
      // Data (r1)
      r1 = M[r4];
      // NULL Function terminates List
      if Z jump $pop_rLink_and_rts;
         // Data (r2)
         r2 = M[r4 + 1];
         // Data (r3)
         r3 = M[r4 + 2];
         // Function
         r0 = M[r4 + 3];
         r4 = r4 + 4;
         M[LOOP_COUNT] = r4;
         // Registration function
         call r0;
         r4 = M[LOOP_COUNT];
   jump lp_proc_loop;

.ENDMODULE;


