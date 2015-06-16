// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 759481 $  $DateTime: 2011/04/04 14:10:53 $
// *****************************************************************************

#ifndef MALLOC_PM_INCLUDED
#define MALLOC_PM_INCLUDED

#include "malloc_library.h"
#include "core_library.h"
#include "architecture.h"

.CONST $malloc_pm.NEXT_PTR_FIELD  $PMWIN_LO_START + 0;
.CONST $malloc_pm.SIZE_FIELD      $PMWIN_HI_START + 0;


.MODULE $malloc_pm;
   .DATASEGMENT DM;

   .VAR start_pointer;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $malloc_pm.initialise
//
// DESCRIPTION:
//    -
//
// INPUTS:
//    - r0 = patch RAM start address
//    - r1 = patch RAM size
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r2, r3
//
//
// *****************************************************************************
.MODULE $M.malloc_pm.initialise;
   .CODESEGMENT MALLOC_PM_INITIALISE_PM;

   $malloc_pm.initialise:

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_PM_ASM.INITIALISE.PATCH_ID_0, r3)
#endif

   // enable writing to PM
   r3 = M[$PM_WIN_ENABLE];
   r2 = 1;
   M[$PM_WIN_ENABLE] = r2;

   M[r0 + $malloc_pm.NEXT_PTR_FIELD] = Null;
   M[r0 + $malloc_pm.SIZE_FIELD] = r1;
   M[$malloc_pm.start_pointer] = r0;

   // restore setting
   M[$PM_WIN_ENABLE] = r3;

   rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $malloc_pm.alloc;
//
// DESCRIPTION:
//    - Allocates a contiguous of patch RAM
//
// INPUTS:
//    - r0 = requested size
//
// OUTPUTS:
//    - r0 = address or zero if error
//    - r1 = actual size of block (0 in fail case, same as requested size otherwise)
//
// TRASHED REGISTERS:
//    - r1 - r5
//
// NOTES
//    Interrupts are not blocked in this function. If PM was ever to be allocated
//    in an interrupt then this should be added. However there isn't currently
//    any plan to ever do this.
//
// *****************************************************************************
.MODULE $M.malloc_pm.alloc;
   .CODESEGMENT MALLOC_PM_ALLOC_PM;

   $malloc_pm.alloc:

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_PM_ASM.ALLOC.PATCH_ID_0, r3)
#endif

   // add extra word to store size
   r0 = r0 + 1;

   // enable writing to PM
   r3 = M[$PM_WIN_ENABLE];
   push r3;
   r3 = 1;
   M[$PM_WIN_ENABLE] = r3;

   r5 = $malloc_pm.start_pointer - $malloc_pm.NEXT_PTR_FIELD;
   r4 = M[r5 + $malloc_pm.NEXT_PTR_FIELD];
   if Z jump failed;
   r1 = 0;
   r2 = 1.0; // large number
   search_loop:
      // get size
      r3 = M[r4 + $malloc_pm.SIZE_FIELD];
      // check it is large enough for our requirements
      Null = r3 - r0;
      if LT jump too_small;
         // is it the smallest block that is large enough?
         Null = r3 - r2;
         if GE jump too_big;
            // yes, store the previous address and new size
            r2 = r3;
            r1 = r5;
         too_big:
      too_small:
      r5 = r4;
      r4 = M[r4 + $malloc_pm.NEXT_PTR_FIELD];
      if NZ jump search_loop;

   // search completed
   Null = r1;
   if Z jump failed;

   // got the block to allocate
   // now sort out linking the remaining space
   // r0 = requested size
   // r1 = address of previous
   // r2 = size of block
   r3 = M[r1 + $malloc_pm.NEXT_PTR_FIELD]; // address to return
   r4 = M[r3 + $malloc_pm.NEXT_PTR_FIELD]; // next free section
   r2 = r2 - r0;
   if Z jump nothing_remaining;
      // split free block into alloced block and
      // the remains as another free block
      r4 = r3 + r0;                          // start address of new free block
      M[r4 + $malloc_pm.SIZE_FIELD] = r2;
      r2 = M[r3 + $malloc_pm.NEXT_PTR_FIELD];
      M[r4 + $malloc_pm.NEXT_PTR_FIELD] = r2;
   nothing_remaining:
   M[r1 + $malloc_pm.NEXT_PTR_FIELD] = r4;
   // store the size (including extra word) in the first word of the block and
   // return the address of the next word
   M[r3 + $malloc_pm.SIZE_FIELD] = r0;
   r1 = r0 - 1;
   r0 = r3 + 1;

   exit:
   // restore setting
   pop r4;
   M[$PM_WIN_ENABLE] = r4;

   rts;

   failed:
   // couldn't find block big enough
   r0 = 0;
   r1 = 0;
   jump exit;


.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $malloc_pm.free;
//
// DESCRIPTION:
//    - Allocates a contiguous of patch RAM
//
// INPUTS:
//    - r0 = pointer
//
// OUTPUTS:
//    - r0 = 0 (success)
//
// TRASHED REGISTERS:
//    - r1 - r5
//
// NOTES
//    Interrupts are not blocked in this function. If PM was ever to be allocated
//    in an interrupt then this should be added. However there isn't currently
//    any plan to ever do this.
//
// *****************************************************************************
.MODULE $M.malloc_pm.free;
   .CODESEGMENT MALLOC_PM_FREE_PM;

   $malloc_pm.free:

#if defined(PATCH_LIBS)
   LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT($malloc.MALLOC_PM_ASM.FREE.PATCH_ID_0, r4)
#endif

   // enable writing to PM
   r3 = M[$PM_WIN_ENABLE];
   push r3;
   r3 = 1;
   M[$PM_WIN_ENABLE] = r3;

   // size is stored in the negative space of the block
   // read out the size and adjust the pointer
   r1 = M[r0 + $malloc_pm.SIZE_FIELD - 1];
   r0 = r0 - 1;

   // find position for freeing block
   r3 = $malloc_pm.start_pointer - $malloc_pm.NEXT_PTR_FIELD;
   search_loop:
      r4 = r3;
      r3 = M[r3 + $malloc_pm.NEXT_PTR_FIELD];
      if Z jump found_end;
      Null = r3 - r0;
      if LT jump search_loop;
      // fall through

   found_end:
   // r0 = address of block to free
   // r1 = size of block to free
   // r3 = address of next free block or zero if we're at the end
   // r4 = address of previous free block

   // check whether we'll be the first block
   Null = r4 - ($malloc_pm.start_pointer-$malloc_pm.NEXT_PTR_FIELD);
   if Z jump dont_merge_previous;
      // not the first block, check whether the freeing
      // block can be merged with the previous
      r2 = M[r4 + $malloc_pm.SIZE_FIELD];
      r5 = r4 + r2;
      Null = r5 - r0;
      if LT jump dont_merge_previous;
         // merge blocks
         r1 = r1 + r2;
         r0 = r4;
         jump done_previous;
   dont_merge_previous:
      // sort out linked list of blocks
      M[r0 + $malloc_pm.NEXT_PTR_FIELD] = r3;
      M[r4 + $malloc_pm.NEXT_PTR_FIELD] = r0;
      // fall through
   done_previous:
   M[r0 + $malloc_pm.SIZE_FIELD] = r1;

   // check whether we'll be the last block
   Null = r3;
   if Z jump dont_merge_next;
      // not the last block, check whether the freeing
      // block can be merged with the next
      r2 = r0 + r1;
      Null = r2 - r3;
      if LT jump dont_merge_next;
         // merge blocks
         r2 = M[r3 + $malloc_pm.NEXT_PTR_FIELD];
         M[r0 + $malloc_pm.NEXT_PTR_FIELD] = r2;
         r2 = M[r3 + $malloc_pm.SIZE_FIELD];
         r1 = r1 + r2;
         M[r0 + $malloc_pm.SIZE_FIELD] = r1;
         // fall through
   dont_merge_next:

   // restore setting
   pop r3;
   M[$PM_WIN_ENABLE] = r3;

   r0 = 0;

   rts;

.ENDMODULE;


#endif   //MALLOC_PM_INCLUDED
