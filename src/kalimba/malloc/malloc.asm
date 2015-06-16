// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef MALLOC_INCLUDED
#define MALLOC_INCLUDED

#include "malloc_library.h"
#include "core_library.h"

.MODULE $malloc;
   .DATASEGMENT DM;

   .VAR info[$malloc.MAX_NUM_SIZES * $malloc.STRUC_SIZE];

   .VAR end_addr[2];

   // Scratch Registers
   .VAR $scratch.s0;
   .VAR $scratch.s1;
   .VAR $scratch.s2;
   .VAR $scratch.s3;
   .VAR $scratch.s4;
   .VAR $scratch.s5;
   .VAR $scratch.s6;
   .VAR $scratch.s7;
   .VAR $scratch.s8;
   .VAR $scratch.s9;
   .VAR $scratch.s10;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $malloc.initialise
//
// DESCRIPTION:
//    Initialise malloc library.
//
// INPUTS:
//    r0 = DM1 area pointer      (NOTE: THIS SHOULD NOT BE ZERO)
//    r1 = DM1 area size
//    r2 = DM2 area pointer
//    r3 = DM2 area size
//
//
// OUTPUTS:
//
//
// TRASHED REGISTERS:
//
//
// NOTE:
//    DM1 area should not start at 0 as the is the failure return code for
//    the alloc routine
//
// *****************************************************************************
.MODULE $M.malloc.initialise;
   .CODESEGMENT MALLOC_INIT_PM;

   $malloc.initialise:

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.INITIALISE.PATCH_ID_0, r4)
#endif

   I1 = r0;
   I2 = r0 + r1;
   I5 = r2;
   I6 = r2 + r3;

   // find end of list
   I0 = $malloc.info;
   // we rely on zero being an invalid address, this includes for the info
   // structure, so check now and fail hard if it is
   if Z call $error;
   I4 = $malloc.info;
   M0 = $malloc.input.STRUC_SIZE;
   M1 = $malloc.STRUC_SIZE;
   r0 = M[I0,M0];
   Null = r0,        r1 = M[I4, M1];
   if Z rts;      // if nothing in info then exit
   find_end_of_list:
      r0 = M[I0,M0];
      Null = r0,        r1 = M[I4, M1];
      if NZ jump find_end_of_list;

   // check haven't run off the end of the structure
   Null = I4 - ($malloc.info + ($malloc.MAX_NUM_SIZES * $malloc.STRUC_SIZE) + $malloc.STRUC_SIZE);
   if GT call $error;

   // if the structure isn't completely full fill it with zeros
   I3 = I4 - $malloc.STRUC_SIZE;
   r10 = ($malloc.info + ($malloc.MAX_NUM_SIZES * $malloc.STRUC_SIZE)) - I3;
   r0 = 0;
   do zero_loop;
      M[I3, 1] = r0;
   zero_loop:

   // shift information in place from array of $malloc.input.STRUCs to array of $malloc.STRUCs
   I0 = I0 + ((-2 * $malloc.input.STRUC_SIZE) + $malloc.input.NUMBER_DM2_FIELD);
   I4 = I4 + ((-2 * $malloc.STRUC_SIZE)       + $malloc.input.NUMBER_DM2_FIELD);
   M0 = - ($malloc.STRUC_SIZE - $malloc.input.NUMBER_DM2_FIELD);
   M1 = -1;
   copy_loop:
      r0 = M[I0,M1];
      M[I4,M1] = r0,       r0 = M[I0,M1];
      M[I4,M1] = r0,       r0 = M[I0,M1];
      M[I4,M0] = r0;
      Null = I0 - I4;
      if LT jump copy_loop;

   // return I0 and I4 to start of $malloc.info
   I0 = $malloc.info;
   I4 = I0;

   // run through each structure and populate it fully
   r0 = I1 + $malloc.GUARD_BAND_SPACE;
   r1 = I5 + $malloc.GUARD_BAND_SPACE;
#ifdef INCLUDE_GUARD_BAND
   r2 = 0xABCDEF;
   more_guard_band:
      M[I1,1] = r2;
      M[I5,1] = r2;
      Null = r0 - I1;
      if GT jump more_guard_band;
#endif
   r7 = 1;
   next_size:
      r2 = M[I4, 1];    // size
      Null = r2;
      if Z rts;
      M0 = r2 +  $malloc.DEBUG_SPACE + $malloc.GUARD_BAND_SPACE;
      M1 = r2 + ($malloc.DEBUG_SPACE - 1);
      r3 = M[I4, 1];    // num dm1
      r4 = M[I4,-1];    // num dm2
      M[I4, 1] = r0;    // start addr dm1
      M[I4, 1] = r1;    // start addr dm2
      dm1_dm2_loop:
         r2 = r0;
         Null = r3;
         if Z jump no_blocks;
            r10 = r3 - 1;
            I0 = r0;                      // start
            r2 = r2 + M0;                 // next block
            r5 = r10 + 1;
#ifdef INCLUDE_GUARD_BAND
            r3 = 0xABCDEF;
#endif
            do set_up_blocks;
               r2 = r2 + M0,  M[I0, 1] = r2;    // write next address
               r5 = r5 - r7,  M[I0,M1] = r5;    // write remaining free (can I use r10?)
#ifdef INCLUDE_GUARD_BAND
               r8 = r2 - M0;
               more_guard_band2:
                  M[I0, 1] = r3;
                  Null = r8 - I0;
                  if GT jump more_guard_band2;
#endif
            set_up_blocks:
            r3 = 0;
            M[I0, 1] = r3;                // end of the list
            M[I0,M1] = r5;
#ifdef INCLUDE_GUARD_BAND
            r3 = 0xABCDEF;
            more_guard_band3:
               M[I0, 1] = r3;
               Null = r2 - I0;
               if GT jump more_guard_band3;
#endif
            r3 = r0;                      // pointer to start
         no_blocks:
         M[I4, 1] = r3;                   // write pointer to start
         Null = r0 - r1;
         if Z jump done_dm2;              // if just done dm1, do dm2
         r6 = r2;             // store start addr for next size
         // set up for dm2 loop
         r3 = r4;             // num
         r0 = r1;             // start addr
         jump dm1_dm2_loop;

      done_dm2:
      // set up start addresses properly
      r0 = r6;
      r1 = r2;
      // check for overflowing regions !! NOTE BY THIS POINT ALREADY WRITTEN INTO SOMEONE ELSE'S AREA !!
      Null = r0 - I2;
      if GT call $error;
      Null = r1 - I6;
      if GT call $error;

      M[$malloc.end_addr + 0] = r0;
      M[$malloc.end_addr + 1] = r1;

#ifdef DEBUG_MALLOC_ON
      M2 = -2;
      r2 = M[I4,M2];   // dummy read to get back to dm1 pointer

      // get dm1 num blocks and write to low watermark
      r2 = M[I4, 2];
      r3 = M[r2 + $malloc.free_block.NUM_FREE_FIELD];  // garbage if r2 = 0
      Null = r2;
      if Z r3 = 0;
      M[I4,-1] = r3;

      // get dm2 num blocks and write to low watermark
      r2 = M[I4, 2];
      r3 = M[r2 + $malloc.free_block.NUM_FREE_FIELD];  // garbage if r2 = 0
      Null = r2;
      if Z r3 = 0;
      M[I4, 1] = r3;

      // write zero to fail count field
      r2 = 0;
      M[I4, 1] = r2;
#endif

      jump next_size;


.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $malloc.alloc
//
// DESCRIPTION:
//
//
// INPUTS:
//    r0 = size
//    r1 = dm preference (0x1: dm1, 0x2: dm2, 0x3: either)
//
// OUTPUTS:
//    r0 = returned address (0 is failure)
//    r1 = actual size of block
//
//
// TRASHED REGISTERS:
//    I3, M0
//
// *****************************************************************************
.MODULE $M.malloc.alloc;
   .CODESEGMENT MALLOC_ALLOC_PM;

   $malloc.alloc:

   $push_rLink_macro;

   push r2;
   push r3;

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.ALLOC.PATCH_ID_0, r2)
#endif

   r2 = r0;
   call $block_interrupts;

   // check for zero size requested
   Null = r2;
   if Z jump exit;

   // search for first size >= r0
   I3 = $malloc.info;
   M0 = $malloc.STRUC_SIZE;
   sizes_loop:
      r0 = M[I3, M0];
      Null = r2 - r0;
      if LE jump found_size;  // size >= requested
      Null = I3 - ($malloc.info + ($malloc.STRUC_SIZE * $malloc.MAX_NUM_SIZES));
      if LT jump sizes_loop;
   // size won't fit in any block
   r2 = 0;                    // error code, fail
   jump exit;

   // try the next size (if there is one)
   try_again:
   r2 = M[I3, 1];          // dummy read
#ifdef DEBUG_MALLOC_ON
   r2 = M[I3, 2];          // dummy read move on to fail count
   // increment fail count
   r2 = M[I3, 0];
   r2 = r2 + 1;
   M[I3, 1] = r2;
#endif
   r2 = 0;                 // error code, fail
   pop r0;                 // remove old block size from stack
   Null = I3 - ($malloc.info + ($malloc.STRUC_SIZE * $malloc.MAX_NUM_SIZES));
   if GE jump exit;        // test for running off the end of the list
   r0 = M[I3, M0];         // next size
   Null = r0;
   if Z jump exit;         // test for next size existing

   found_size:

   push r0;                // push block size onto stack

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.ALLOC.PATCH_ID_1, r2)
#endif

   // move back to the size to use then on to dm1 pointer field
   I3 = I3 - ($malloc.STRUC_SIZE - $malloc.POINTER_DM1_FIELD);

   // get count of available DM1 blocks
   r0 = M[I3, 1];
   r2 = M[r0 + $malloc.free_block.NUM_FREE_FIELD];  // garbage if r0 = 0
   // zero count if pointer is Null
   Null = r0;
   if Z r2 = 0;
   // zero count if dm2 only requested
   Null = r1 AND $malloc.dm_preference.DM1;
   if Z r2 = 0;

   // get count of available DM2 blocks
   r0 = M[I3, 0];
   r3 = M[r0 + $malloc.free_block.NUM_FREE_FIELD];  // garbage if r0 = 0
   // zero count if pointer is Null
   Null = r0;
   if Z r3 = 0;
   // zero count if dm1 only requested
   Null = r1 AND $malloc.dm_preference.DM2;
   if Z r3 = 0;

   // select DM to use
   Null = r2 OR r3;
   if Z jump try_again;  // check for none available in either DM
   // if selecting DM1 move I3 to point at DM1 pointer
   r0 = $malloc.POINTER_DM1_FIELD - $malloc.POINTER_DM2_FIELD;
   Null = r2 - r3;
   if GT I3 = I3 + r0;
   r0 = M[I3, 0];

   found:
   // remove from head of list
   r1 = M[r0];
   M[I3, 0] = r1;
#ifdef DEBUG_MALLOC_ON
   // write low watermark to number field
   I3 = I3 - ($malloc.POINTER_DM1_FIELD - $malloc.LOW_WATERMARK_DM1_FIELD);
   r2 = M[r1 + $malloc.free_block.NUM_FREE_FIELD];
   Null = r1;
   if Z r2 = r1;
   r1 = M[I3, 0];
   Null = r2 - r1;
   if LT r1 = r2;
   M[I3, 0] = r1;
   #ifdef INCLUDE_DEBUG_SPACE
      r1 = M[SP-4];
      M[r0] = r1;
   #endif
#endif
   r2 = r0 + $malloc.DEBUG_SPACE;

   pop r1;     // block size

   exit:
   call $unblock_interrupts;
   r0 = r2;    // address
   pop r3;
   pop r2;
   jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $malloc.free
//
// DESCRIPTION:
//
//
// INPUTS:
//    r0 = address
//
// OUTPUTS:
//    r0 = return code (0 success, -1 fail)
//
// TRASHED REGISTERS:
//    I3, M0
//    rMAC, Div (if MALLOC_FREE_TESTS defined)
//
// *****************************************************************************
.MODULE $M.malloc.free;
   .CODESEGMENT MALLOC_FREE_PM;

   $malloc.free:

   $push_rLink_macro;

   push r1;
   push r0;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.FREE.PATCH_ID_0, r1)
#endif

   call $block_interrupts;
   pop r0;
   // check for Null pointer (should return success)
   if Z jump exit_success;

   // get the block pointer
   call $malloc.get_block_info;

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.FREE.PATCH_ID_1, r1)
#endif
   Null = I3;
   if Z jump exit_error;

   // put block back on list
   r1 = M[I3, 0];
   M[r0] = r1,    M[I3, M0] = r0;
   // write num of free blocks
   Null = r1;
   if Z jump first_element;
      r1 = M[r1 + $malloc.free_block.NUM_FREE_FIELD];
   first_element:
   r1 = r1 + 1;
   M[r0 + $malloc.free_block.NUM_FREE_FIELD] = r1;


   exit_success:
   // return success
   call $unblock_interrupts;
   r0 = 0;
   exit:
   pop r1;
   jump $pop_rLink_and_rts;

   exit_error:
   // return fail
#ifdef MALLOC_PANIC_ON_BAD_FREE
   call $error;
#endif
   call $unblock_interrupts;
   r0 = -1;
   jump exit;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $malloc.zero_alloc
//
// DESCRIPTION:
//    Allocate a block and zero all the elements of it.
//
// INPUTS:
//    r0 = size
//    r1 = dm preference (0x1: dm1, 0x2: dm2, 0x3: either)
//
// OUTPUTS:
//    r0 = returned address (0 is failure)
//    r1 = actual size of block
//
//
// TRASHED REGISTERS:
//    r10, I3, M0
//
// *****************************************************************************
.MODULE $M.malloc.zero_alloc;
   .CODESEGMENT MALLOC_ZERO_ALLOC_PM;

   $malloc.zero_alloc:

   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_PUSH_REGS_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.ZERO_ALLOC.PATCH_ID_0)
#endif

   call $malloc.alloc;
   Null = r0;
   if Z jump $pop_rLink_and_rts;

   push r0;
   r10 = r1;
   I3 = r0;
   r0 = 0;
   do zero_loop;
      M[I3, 1] = r0;
   zero_loop:
   pop r0;

   jump $pop_rLink_and_rts;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $malloc.get_block_size
//
// DESCRIPTION:
//    Returns the size of a block of RAM, does not check if the address is the
// start of a block.
//
// INPUTS:
//    r0 = address
//
// OUTPUTS:
//    r0 = size (0 on failure)
//
// TRASHED REGISTERS:
//    r1, I3, M0
//    rMAC, Div (if MALLOC_FREE_TESTS defined)
//
// *****************************************************************************
.MODULE $M.malloc.get_block_size;
   .CODESEGMENT MALLOC_GET_BLOCK_SIZE_PM;

   $malloc.get_block_size:

   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.GET_BLOCK_SIZE.PATCH_ID_0, r1)
#endif

   call $malloc.get_block_info;

   // work out adjustment value based on input address being in DM1 or DM2
   r1 = $malloc.POINTER_DM2_FIELD - $malloc.POINTER_DM1_FIELD;
   Null = r0;
   if POS r1 = 0;

   // check for zero being returned
   r0 = I3;
   if Z jump exit;
      r0 = r0 - r1;
      r0 = M[r0 + ($malloc.SIZE_FIELD-$malloc.POINTER_DM1_FIELD)];
   exit:

   jump $pop_rLink_and_rts;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $malloc.get_block_info
//
// DESCRIPTION:
//    Returns the address of the structure in the info block for a block of RAM.
// It does not check if the address is the start of a block.
//
// INPUTS:
//    r0 = address
//
// OUTPUTS:
//    I3 = address of $malloc.POINTER_DM1_FIELD or $malloc.POINTER_DM2_FIELD
//         element of info structure (whichever is appropriate for the address
//         input)
//    r0 = 'actual' start address of block
//
// TRASHED REGISTERS:
//    r1
//    rMAC, Div (if MALLOC_FREE_TESTS defined)
//
// *****************************************************************************
.MODULE $M.malloc.get_block_info;
   .CODESEGMENT MALLOC_GET_BLOCK_INFO_PM;

   $malloc.get_block_info:

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.GET_BLOCK_INFO.PATCH_ID_0, r1)
#endif

   // check that subtracting debug size won't switch between DMs
   Null = r0 - $malloc.DEBUG_SPACE;
   if V jump exit_error;      // catches DM2 -> DM1
   if B jump exit_error;      // catched DM1 -> DM2

   // find size
   I3 = $malloc.info + $malloc.START_ADDR_DM1_FIELD;
   r1 = $malloc.START_ADDR_DM2_FIELD - $malloc.START_ADDR_DM1_FIELD;
   r0 = r0 - $malloc.DEBUG_SPACE;
   if NEG I3 = I3 + r1;
   M0 = $malloc.STRUC_SIZE;
   r1 = M[I3, M0];
   Null = r0 - r1;
   if LT jump exit_error;  // addr < start addr of first size
   sizes_loop:
      r1 = M[I3, M0];
      Null = r1;
      if Z jump end_of_sizes; // block is of largest size or not valid block
      Null = r0 - r1;
      if LT jump found_size;  // addr < start addr
      Null = I3 - ($malloc.info + ($malloc.STRUC_SIZE * $malloc.MAX_NUM_SIZES));
      if LT jump sizes_loop;
   // in final size
   I3 = I3 + $malloc.STRUC_SIZE;
   //fall through
   end_of_sizes:
   // check that the block address isn't larger than the end address
   // calculate modifier for moving between DM1 and DM2
   r1 = $malloc.START_ADDR_DM2_FIELD - $malloc.START_ADDR_DM1_FIELD;
   Null = r0;
   if POS r1 = 0;
   r1 = M[$malloc.end_addr + r1];
   Null = r0 - r1;
   if GE jump exit_error;
   //fall through

   found_size:
#ifdef MALLOC_FREE_TESTS
   // calculate modifier for moving between DM1 and DM2
   r1 = $malloc.START_ADDR_DM2_FIELD - $malloc.START_ADDR_DM1_FIELD;
   Null = r0;
   if POS r1 = 0;

   // check that address isn't too high
   rMAC = M[$malloc.end_addr + r1];  // this working relies on start address fields not changing
   Null = r0 - rMAC;
   if GE jump exit_error;

   // read size
   rMAC = I3 + ((-2*$malloc.STRUC_SIZE) - $malloc.START_ADDR_DM1_FIELD + $malloc.SIZE_FIELD);
   r1 = rMAC - r1;
   r1 = M[r1];
   // calculate actual size
   r1 = r1 + $malloc.DEBUG_SPACE + $malloc.GUARD_BAND_SPACE;
   // read start address
   I3 = I3 + (-2*$malloc.STRUC_SIZE);
   rMAC = M[I3, ($malloc.POINTER_DM1_FIELD - $malloc.START_ADDR_DM1_FIELD)];
   // calculate offset from start address
   rMAC = r0 - rMAC;
   // ensure address is a valid block address
   rMAC = rMAC ASHIFT 0 (LO);      // integer divide requires this shift
   Div = rMAC/r1;
   r1 = DivRemainder;
   nop;
   nop;
   if NZ jump exit_error;

   r1 = M[I3, 0];
   Null = r1;
   if Z jump skip_inf_check_loop;
   inf_check_loop:
       Null = r1 - r0;
       if Z jump exit_error;
       r1 = M[r1];
   if NZ jump inf_check_loop;
   skip_inf_check_loop:

#else
   // move to pointer field
   I3 = I3 + ((-2*$malloc.STRUC_SIZE) - $malloc.START_ADDR_DM1_FIELD + $malloc.POINTER_DM1_FIELD);
#endif

   rts;

   exit_error:
   I3 = 0;
   rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $malloc.realloc_pools
//
// DESCRIPTION:
//    Reallocates the memory pools.
//    Pass in a block with the new set of memory pools (a list of $malloc.input
//    structures). This must be the only block that is currently allocated.
//
// INPUTS:
//    r0 = DM1 area pointer      (NOTE: THIS SHOULD NOT BE ZERO)
//    r1 = DM1 area size
//    r2 = DM2 area pointer
//    r3 = DM2 area size
//    r4 = block with new pool information
//
// OUTPUTS:
//    r0 = result, 0=success, 1=fail
//
// TRASHED REGISTERS:
//    Assume everything
//
// *****************************************************************************
.MODULE $M.malloc.realloc_pools;
   .CODESEGMENT MALLOC_REALLOC_POOLS_PM;

   $malloc.realloc_pools:

   $push_rLink_macro;

   pushm<r0,r1,r2,r3,r4>;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_ASM.REALLOC_POOLS.PATCH_ID_0, r1)
#endif

   call $block_interrupts;

   // get block size for later
   r0 = r4;
   call $malloc.get_block_size;
   r8 = r0 + $malloc.DEBUG_SPACE;

   // check that the only allocated block is the one passed in
   r7 = $malloc.info;
   block_size_loop:
      // get start addresses
      r2 = M[r7 + $malloc.START_ADDR_DM1_FIELD];
      r4 = M[r7 + $malloc.START_ADDR_DM2_FIELD];
      Null = r7 - $malloc.info;
      if Z jump first_loop;
         // check that the gap between the start address of this and
         // the previous block is entirely filled with free blocks
         Null = r6 - r2;
         if NZ call not_all_free;
         Null = r5 - r4;
         if NZ call not_all_free;
      first_loop:
      // get first free block for this size
      r5 = M[r7 + $malloc.POINTER_DM1_FIELD];
      r1 = M[r7 + $malloc.POINTER_DM2_FIELD];
      r3 = M[r7 + $malloc.SIZE_FIELD];
      r3 = r3 + $malloc.DEBUG_SPACE;
      start_count_free:
         // for each free block increment start address by block size
         Null = r5;
         if Z jump found_end;
         count_free_loop:
            r2 = r2 + r3;
            r5 = M[r5 + $malloc.free_block.POINTER_FIELD];
            if NZ jump count_free_loop;
            // fall through

      found_end:
      // got last free block, check whether we just did dm1 or dm2
      r5 = r2;
      if NEG jump done_dm2;
         // we just did dm1, save results and do the same for dm2
         r6 = r2;
         r2 = r4;
         r5 = r1;
         jump start_count_free;
      done_dm2:
      // both dms parsed. If this isn't the final size then loop
      r7 = r7 + $malloc.STRUC_SIZE;
      Null = r7 - ($malloc.info + ($malloc.STRUC_SIZE * $malloc.MAX_NUM_SIZES));
      if GE jump last_size;
      Null = M[r7 + $malloc.SIZE_FIELD];
      if NZ jump block_size_loop;
      // fall through

   last_size:
   // this is the final size, there is no next start address,
   // check against the stored end addresses
   r2 = M[$malloc.end_addr + 0];
   r4 = M[$malloc.end_addr + 1];
   Null = r6 - r2;
   if NZ call not_all_free;
   Null = r5 - r4;
   if NZ call not_all_free;

   // now fill in $malloc.info
   pop I0;
   r10 = r8;
   I4 = $malloc.info;
   do copy_malloc_info_loop;
      r0 = M[I0, 1];
      M[I4, 1] = r0;
   copy_malloc_info_loop:

   // and run malloc initialise with the new pools
   popm<r0,r1,r2,r3>;
   call $malloc.initialise;
   call $unblock_interrupts;
   r0 = 0;
   jump $pop_rLink_and_rts;


// ******************************************************************
// Note that we *call* this label from realloc pools above. So rts
// will take us back to the call
// ******************************************************************
   not_all_free:
      // there is at least one block allocated, check that
      // it is only the block passed in

      // if the size we're currently on is different to the
      // block passed in then fail
      Null = r8 - r3;
      if NZ jump exit_fail;
      // add the block size to the appropriate register
      // r5 for DM2 r6 for DM1
      Null = M[SP-1];
      if NEG r5 = r5 + r3;
      if POS r6 = r6 + r3;
      // run the test again
      Null = r6 - r2;
      if NZ jump exit_fail;
      Null = r5 - r4;
      if Z rts;      // return to where the test failed, all is well
// ******************************************************************
// we fall through or jump here on the failure case. Now we can
// pop_rLink_and_rts to return not to where not_all_free was called
// but to where realloc_pools was called since we never pushed rLink
// after the call to not_all_free
// ******************************************************************


   exit_fail:
      // at least one block other than the one passed in has been
      // allocated, this means we can't proceed.
      popm<r0,r1,r2,r3,r4>;
      // we have failed, free the input block
      r0 = r4;
      call $malloc.free;
      call $unblock_interrupts;
      r0 = 1;
      // this exits the realloc_pools function immediately
      jump $pop_rLink_and_rts;


.ENDMODULE;

#endif



