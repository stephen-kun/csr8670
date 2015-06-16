// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef PATCH_INCLUDED
#define PATCH_INCLUDED

#include "core_library.h"
#include "patch.h"

// **************************** Library Description ****************************
// --------------------------------* PATCH FUNCTIONS *--------------------------------
//   $patch.
//    TODO write extensive help
//
//
//
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    $patch
//
// DESCRIPTION:
//
// INPUTS:
//    -
//
// OUTPUTS:
//    -
//
// TRASHED REGISTERS:
//    - r0, r10, I0, DoLoop
//
//
// *****************************************************************************
.MODULE $patch;
   .DATASEGMENT DM;

   .VAR struct_pointer;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $patch.initialise
//
// DESCRIPTION:
//
// INPUTS:
//    - r0 = patch structure pointer
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0, r10, I0, DoLoop
//
//
// *****************************************************************************
.MODULE $M.patch.initialise;
   .CODESEGMENT PATCH_INITIALISE_PM;

   $patch.initialise:

   $push_rLink_macro;

   M[$patch.struct_pointer] = r0;
   M[r0 + $patch.EXP_REMAINING_FIELD] = Null;
   M[r0 + $patch.PATCH_LIST_FIELD] = Null;

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $patch.add_patch
//
// DESCRIPTION:
//
//    patchMessage () {
//       patchID        // 12 bits = A unique ID as an enum (for Encore: 8-bit process 4-bit patch ID)
//       patchType      // 3 bits
//       extendedPatch  // 1 bits 1 if extendedPatch, zero otherwise (only valid when using patch RAM, ignored otherwise)
//       reserved       // 8 bits - set to zero for this version of patch system
//       patchAddressMS // 8 bits (DM or PM MS 8bits of address that is patched - ignored on BC5, but still present as padding)
//       patchAddressLS // 16 bits (DM or PM LS 16 bits of address that is patched)
//       patchSize      // 16 bits
//
//       if (extendedPatch && (patchID != REPLACEMENT_RAM_CODEPATCH) &&
//           (patchID != REPLACEMENT_RAM_DATAPATCH &&)) {
//          currentPatchSize      // 16 bits
//       }
//
//       // Read the actual patch payload
//       for ( count = 0; count < patchSize; count++ ) {
//          if ( patchType || codePatch )
//             patchPayload[count]           // 32 bits
//          else if ( patchType || dataPatch )
//             patchPayload[count]           // 24 bits packed with padding on last byte if required
//       }
//
//     }
//
// INPUTS:
//    - r0: pointer to the patch message
//
// OUTPUTS:
//    - r3 = -1 if failed, otherwise either 0 or the address of the patch
//
// TRASHED REGISTERS:
//    - assume everything
//
// *****************************************************************************
.MODULE $M.patch.add_patch;
   .CODESEGMENT PATCH_ADD_PM;

   $patch.add_patch:

   // push rLink onto stack
   $push_rLink_macro;

   I0 = r0;
   r6 = M[$patch.struct_pointer];

   // enable writing to PM
   r0 = M[$PM_WIN_ENABLE];
   push r0;
   r0 = 1;
   M[$PM_WIN_ENABLE] = r0;

   // parse patch message header
   r0 = M[I0, 1];
   r0 = r0 AND 0xFFFF;
   r5 = r0 LSHIFT -4;      // r5 = patchID
   r2 = r0 LSHIFT -1;
   r2 = r2 AND 0x7;        // r2 = patchType
   r8 = r0 AND 0x1;        // r8 = extendedPatch

   r0 = M[I0, 1];
   r3 = M[I0, 1];
   r3 = r3 AND 0xFFFF;     // r3 = patchAddressLS
   r0 = r0 LSHIFT 16;      // r0 = patchAddressMS
   r3 = r3 OR r0;          // r3 = patchAddress
   r4 = M[I0, 1];
   // check that the length is non-zero
   Null = r4;
   if Z jump exit_with_error;

   // switch (patchType)
   Null= r2 - $patch.REPLACEMENT_RAM_CODEPATCH;
   if NE jump not_code_replacement;

      // write patch to program RAM
      r10 = r4;
      call $patch.private.write_pm_ram;

      jump exit_with_success;
   not_code_replacement:


   Null= r2 - $patch.REPLACEMENT_RAM_DATAPATCH;
   if NE jump not_data_replacement;

      // write patch to data RAM
      call $patch.private.write_dm_ram;
      // pop rLink from stack
      jump exit_with_success;
   not_data_replacement:


   Null = r2 - $patch.SW_ROM_CODEPATCH;
   if NZ jump not_sw_rom_code;
      call $patch.private.populate_patch_ram;
      Null = r3;
      if NEG jump exit_with_error;
      Null = r2;
      if NZ jump exit_with_success;

      // populate fast/slow patch tables, if needed
      call $patch.private.populate_fast_slow_patch_tables; // in: r3, r5. out: none, trashed: r0-2, r5
      jump exit_with_success;
   not_sw_rom_code:

    #ifdef ROM
        Null = r2 - $patch.HW_ROM_CODEPATCH;
        if NZ jump not_hw_rom_code;
        push r3;
        call $patch.private.populate_patch_ram;
        pop r4;
        Null = r3;
        if NEG jump exit_with_error;
        Null = r2;
        if NZ jump exit_with_success;
        
        // calc HW patch number 0-15
        r0 = r5 - $patch.HW_PATCH_ID_BASE;
        #ifdef DEBUG_PATCH
            // HW patch IDs should be greater or equal to $patch.HW_PATCH_ID_BASE
            if LT call $error;
        #endif
        
        // patch_address = pm_addr - 0x2800 + flashwin_start_addr
        // writing to PM_FLASHWIN_START_ADDR clears the cache so that the patch will take effect immediately.
        r1 = M[$PM_FLASHWIN_START_ADDR];
        r4 = r4 + r1;
        r4 = r4 - $PMWIN_SIZE;
        
        // clear the cache
        M[$PM_FLASHWIN_START_ADDR] = r1;
        M[$DSP_ROM_PATCH0_ADDR + r0] = r4;
        M[$DSP_ROM_PATCH0_BRANCH + r0] = r3;
        
        jump exit_with_success;
        not_hw_rom_code:
    #endif

   Null = r2 - $patch.RAM_CODEPATCH;
   if NZ jump not_ram_code;
      push r3;
      call $patch.private.populate_patch_ram;
      pop r4;
      Null = r3;
      if NEG jump exit_with_error;
      Null = r2;
      if NZ jump exit_with_success;

      // change RAM code to jump to patch
      r0 = $patch.JUMP_INSTRUCTION_MS;
      M[r4 + $PMWIN_HI_START] = r0;
      // this jump will be a relative jump
      // so make the address relative
      r0 = r3 - r4;
      M[r4 + $PMWIN_LO_START] = r0;
      jump exit_with_success;
   not_ram_code:

   Null = r2 - $patch.EXCUTEPATCH;
   if NZ jump not_execute_code;
      // execute patch
      push r5;
      call $patch.private.populate_patch_ram;
      pop r5;
      Null = r3;
      if NEG jump exit_with_error;
      push r5;
      Null = r2;
      if Z call r3;
      pop r5;
      call $patch.private.free_block;
      jump exit_with_success;
   not_execute_code:
   exit_with_error:
   // TODO handle errors informatively back to host
#ifdef DEBUG_PATCH
   call $error;
#else
   r3 = -1; // i.e. error
   jump exit;
#endif

   exit_with_success:
   Null = r3;
   if NEG r3 = 0;

   exit:
   // restore original state of PM_WIN_ENABLE
   pop r0;
   M[$PM_WIN_ENABLE] = r0;
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $patch.remove_patch
//
// DESCRIPTION:
//    - removes a patch - does not "undo" any previous changes to PM RAM
//
// INPUTS:
//    - r5 = patch ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// *****************************************************************************
.MODULE $M.patch.remove_patch;
   .CODESEGMENT PM_FLASH;
   .DATASEGMENT DM;

   $patch.remove_patch:

   // push rLink onto stack
   $push_rLink_macro;

   r7 = r5;
   call $patch.private.free_block;

   r3 = M[$patch.struct_pointer];
   r1 = M[r3 + $patch.NUM_OF_FAST_PATCHES_FIELD];
   // if the patch ID is in the fast patch range, write the patch
   // address to the corresponding entry in the fast patch table.
   Null = r7 - r1;
   if GE jump not_a_fast_patch;
      r3 = M[r3 + $patch.TABLE_FAST_POINTER_FIELD];
      M[r3 + r7] = Null;
      jump patch_removed;
   not_a_fast_patch:

   r0 = M[r3 + $patch.NUM_OF_SLOW_PATCHES_FIELD];
   r0 = r0 + r1;
   // if the patch ID is in the slow patch range, set the relevent
   // bit of the corresponding entry in the slow patch table.
   Null = r7 - r0;
   if GE jump patch_removed;
   r7 = r7 - r1;
   r1 = r7 AND 0xF;
   r0 = 1;
   r1 = r0 ASHIFT r1;
   r1 = r1 XOR 0xFFFF;
   r0 = r7 LSHIFT -4;
   r3 = M[r3 + $patch.TABLE_SLOW_POINTER_FIELD];
   r2 = M[r3 + r0];
   r2 = r2 AND r1;
   M[r3 + r0] = r2;


   patch_removed:

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $patch.id_search
//
// DESCRIPTION:
//    - This function is called from the patch points with the relevent patch ID.
//      It searches through id_to_block_map for the patch ID and if it finds one
//      it executes it.
//
// INPUTS:
//    - r0 = patch ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0, DoLoop
//    It is assumed that this function is called like this:
//
//    push r0;
//    r0 = patchID;
//    call $patch.id_search;
//    pop r0;     // NOTE that changes to r0 in the patch are not retained
//
//    if there are no patches, no registers are trashed. If there is a patch
//    it can be assumed that the call is made to the actual patch. So any
//    changes in the patch will be retained. (r0 is trashed in the function)
//
// *****************************************************************************
.MODULE $M.patch.id_search;
   .CODESEGMENT PATCH_ID_SEARCH_PM;

   $patch.id_search:

   push r1;
   push r2;

   // enable writing to PM
   r1 = M[$PM_WIN_ENABLE];
   push r1;
   r1 = 1;
   M[$PM_WIN_ENABLE] = r1;

   r1 = M[$patch.struct_pointer];

   // search linked list for patch
   r2 = r1 + ($patch.PATCH_LIST_FIELD - $patch.block.NEXT_FIELD);

   loop:
      r2 = M[r2 + $patch.block.NEXT_FIELD];
      if Z jump exit_no_patch;
      r1 = M[r2 + $patch.block.ID_FIELD];
      Null = r1 - r0;
      if NZ jump loop;
      // fall through

   // found patch
   r0 = r2 + $patch.block.STRUC_SIZE;

   // restore PM window
   pop r1;
   M[$PM_WIN_ENABLE] = r1;

   pop r2;
   pop r1;
   jump r0;


   exit_no_patch:
   // haven't found patch, this should only occur with VERY_SLOW patches

   // restore PM window
   pop r1;
   M[$PM_WIN_ENABLE] = r1;

   pop r2;
   pop r1;
   rts;

.ENDMODULE;

// *****************************************************************************
// *                                                                           *
// *------------------------> HELPER FUNCTIONS <-------------------------------*
// *                                                                           *
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    $patch.private.populate_patch_ram;
//
// DESCRIPTION:
//    - writes to patch RAM from a buffer
//
// INPUTS:
//    - r4 = patch size
//    - r5 = patch_id
//    - r6 = patch structure pointer
//    - r8 = extendedPatch
//
// OUTPUTS:
//    - r2 = size of patch remaining
//    - r3 = patch ram address (if -1, write unsuccessful)
//    - r6 = unchanged
//
// TRASHED REGISTERS:
//    -
//
// *****************************************************************************
.MODULE $M.patch.private.populate_patch_ram;
   .CODESEGMENT PATCH_PRIV_POPULATE_PM;

   $patch.private.populate_patch_ram:
   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($patch.PATCH_ASM.PRIVATE.POPULATE_PATCH_RAM.PATCH_ID_0, r3)
#endif

   r0 = M[r6 + $patch.EXP_REMAINING_FIELD];
   if Z jump nothing_pending;
      // we are in the middle of an extended patch
      Null = r8;
      if Z jump exit_with_error;
      jump load_extended_patch_constants;
   not_extended:

   nothing_pending:
   // obtain patch start segment index
   call $patch.private.get_block;

   Null = r3;  // r3 = patch block address
   if Z jump $pop_rLink_and_rts;

   // check if it is an extended patch
   Null = r8;
   if Z jump write_patch;
      // store EXP constants for the first time
      M[r6 + $patch.EXP_ADDRESS_FIELD] = r3;
      M[r6 + $patch.EXP_REMAINING_FIELD] = r4;

      load_extended_patch_constants:
         // calculate the current start address
         r0 = M[r6 + $patch.EXP_REMAINING_FIELD];
         r3 = M[r6 + $patch.EXP_ADDRESS_FIELD];
         r3 = r3 + r4;
         r3 = r3 - r0;

         // calculate and store next remaining
         r4 = M[I0, 1]; // read currentPatchSize
         r0 = r0 - r4;
         if NEG jump exit_with_error;
         M[r6 + $patch.EXP_REMAINING_FIELD] = r0;
   write_patch:

   // copy the patch code to patch RAM
   r10 = r4;
   call $patch.private.write_pm_ram; // returns r0

   // load the first patch ram address if extended patch
   // note that the modification should use the first patch ram
   // address not the current one.
   Null = r8;
   if Z jump r3_correct;
      r3 = M[r6 + $patch.EXP_ADDRESS_FIELD];
   r3_correct:

   exit:
      r2 = M[r6 + $patch.EXP_REMAINING_FIELD];
      // pop rLink from stack
      jump $pop_rLink_and_rts;

   exit_with_error:
      r3 = -1;
      jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $patch.private.write_pm_ram;
//
// DESCRIPTION:
//    - writes instructions read from a 16-bit buffer to PM
//
// INPUTS:
//    - r3 = the start of the PM address to write to (unchanged)
//    - r6 = patch structure pointer
//    - r10 = Number of instructions (code lines)
//    - I0 = buffer to read from (16-bit words big-endian)
//
// OUTPUTS:
//    - r0 = M[I0 + r10]
//    - r6 = unchanged
//    - I0 (updated) = I0 + r10 + 1
//    - I4 = last PMWIN_HI_START writen to + 1
//    - I5 = last PMWIN_LO_START writen to + 1
//
// TRASHED REGISTERS:
//    - r0, r1, I4, I5, r10, DoLoop
//
//
// *****************************************************************************
.MODULE $M.patch.private.write_pm_ram;
   .CODESEGMENT PATCH_PRIV_WRITE_PM_RAM_PM;

   $patch.private.write_pm_ram:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($patch.PATCH_ASM.PRIVATE.WRITE_PM_RAM.PATCH_ID_0, r1)
#endif

   I4 = r3 + $PMWIN_HI_START;
   I5 = r3 + $PMWIN_LO_START;
   r0 = M[I0, 1];
   do write_replacement_code_loop;
      // TODO it is assumed that no masking (24 -> 16 bit) is needed, verify if this is correct.
      M[I4, 1] = r0,
       r1 = M[I0, 1];
      M[I5, 1] = r1,
       r0 = M[I0, 1];
   write_replacement_code_loop:

   rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $patch.private.populate_fast_slow_patch_tables
//
// DESCRIPTION:
//    - This function is called when a slow or fast patch is receieved. here the
//      relevent flags/addresses in patch tables are set/populated, so that the
//      patch point is activated.
//
// INPUTS:
//    - r5 = patch ID
//    - r3 = patch address
//    - r6 = patch structure pointer
//
// OUTPUTS:
//    - r6 = unchanged
//
// TRASHED REGISTERS:
//    - r0, r1, r2, r5
//
// *****************************************************************************
.MODULE $M.patch.private.populate_fast_slow_patch_tables;
   .CODESEGMENT PM_FLASH;
   .DATASEGMENT DM;

   $patch.private.populate_fast_slow_patch_tables:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($patch.PATCH_ASM.PRIVATE.POPULATE_FAST_SLOW_PATCH_TABLES.PATCH_ID_0, r1)
#endif

      // if the patch ID is in the fast patch range, write the patch
      // address to the corresponding entry in the fast patch table.
      r1 = M[r6 + $patch.NUM_OF_FAST_PATCHES_FIELD];
      Null = r5 - r1;
      if GE jump not_a_fast_patch;
         r1 = M[r6 + $patch.TABLE_FAST_POINTER_FIELD];
         M[r1 + r5] = r3;
         rts;
      not_a_fast_patch:


      // if the patch ID is in the slow patch range, set the relevent
      // bit of the corresponding entry in the slow patch table.
      r2 = M[r6 + $patch.NUM_OF_SLOW_PATCHES_FIELD];
      r2 = r2 + r1;
      Null = r5 - r2;
      if GE rts;

      r5 = r5 - r1;
      r1 = r5 AND 0xF;
      r2 = 1;
      r1 = r2 ASHIFT r1;
      r5 = r5 LSHIFT -4;
      r0 = M[r6 + $patch.TABLE_SLOW_POINTER_FIELD];
      r2 = M[r0 + r5];
      r2 = r2 OR r1;
      M[r0 + r5] = r2;

   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $patch.private.write_dm_ram;
//
// DESCRIPTION:
//    - writes instructions read from a 16-bit buffer to PM
//
// INPUTS:
//    - r3 = the start of the DM address to write to (unchanged)
//    - r4 = patch size (number of data to be written
//    - r6 = patch structure pointer
//    - I0 = buffer to read from (16-bit words big-endian)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0-r3, r10, doLoop, I0, I4
//
//
// *****************************************************************************
.MODULE $M.patch.private.write_dm_ram;
   .CODESEGMENT PATCH_PRIV_WRITE_DM_RAM_PM;


   $patch.private.write_dm_ram:

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($patch.PATCH_ASM.PRIVATE.WRITE_DM_RAM.PATCH_ID_0, r1)
#endif

   // pre-init the loop
   I4 = r3;
   r3 = r4 AND 0x1;
   r10 = r4 ASHIFT -1;
   r0 = M[I0, 1];
   do write_replacement_data_loop;
      // read 3 16-bit words and write 2 24-bit words each itteration
      r0 = r0 AND 0xFFFF;
      r1 = r0 LSHIFT 8;
      r0 = M[I0, 1];
      r0 = r0 AND 0xFFFF;
      r2 = r0 LSHIFT -8;
      r1 = r1 OR r2;
      r2 = r0 LSHIFT 16;
      M[I4, 1] = r1,
       r0 = M[I0, 1];
      r0 = r0 AND 0xFFFF;
      r2 = r2 OR r0,
       r0 = M[I0, 1];
      M[I4, 1] = r2;
   write_replacement_data_loop:
   Null = r3;
   if Z jump no_odd_data_left;
      // copy last odd 24-bit word
      r0 = r0 AND 0xFFFF;
      r1 = r0 LSHIFT 8;
      r0 = M[I0, 1];
      r0 = r0 AND 0xFFFF;
      r2 = r0 LSHIFT -8;
      r1 = r1 OR r2;
      M[I4, 1] = r1;
   no_odd_data_left:

   rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $patch.get_block
//
// DESCRIPTION:
//    -
//
// INPUTS:
//    - r4 = patch size
//    - r5 = patch_id
//    - r6 = patch structure pointer
//
// OUTPUTS:
//    - r3 = patch ram address (if -1, write unsuccessful)
//    - r6 = unchanged
//
// TRASHED REGISTERS:
//    - r0 - r2, r7
//
// *****************************************************************************
.MODULE $M.patch.private.get_block;
   .CODESEGMENT PATCH_PRIV_GET_BLOCK_PM;

   $patch.private.get_block:

   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($patch.PATCH_ASM.GET_BLOCK.PATCH_ID_0, r1)
#endif

   r7 = r5;

   // enable writing to PM
   r0 = M[$PM_WIN_ENABLE];
   push r0;
   r0 = 1;
   M[$PM_WIN_ENABLE] = r0;

   // allocate the memory
   // need size of patch plus the header
   r0 = r4 + $patch.block.STRUC_SIZE;      // could r4 ever be zero? !!!!!!!!!!!!!!!!!!!
   call $malloc_pm.alloc;
   Null = r0;
   if Z jump exit;

   // add to linked list
   r3 = M[r6 + $patch.PATCH_LIST_FIELD];
   M[r0 + $patch.block.NEXT_FIELD] = r3;
   M[r6 + $patch.PATCH_LIST_FIELD] = r0;

   // write size and ID into header
   M[r0 + $patch.block.ID_FIELD] = r7;

   // return address of the payload
   r3 = r0 + $patch.block.STRUC_SIZE;

   exit:

   r5 = r7;

   // restore setting
   pop r0;
   M[$PM_WIN_ENABLE] = r0;

   // return size of the payload
   r4 = r1 - $patch.block.STRUC_SIZE;
   if NEG r4 = 0;

   jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $patch.free_block
//
// DESCRIPTION:
//    -
//
// INPUTS:
//    - r5 = patch_id
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//    - r0 - r5;
//
// *****************************************************************************
.MODULE $M.patch.private.free_block;
   .CODESEGMENT PATCH_PRIV_FREE_BLOCK_PM;

   $patch.private.free_block:

   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($patch.PATCH_ASM.FREE_BLOCK.PATCH_ID_0, r1)
#endif

   // enable writing to PM
   r0 = M[$PM_WIN_ENABLE];
   push r0;
   r0 = 1;
   M[$PM_WIN_ENABLE] = r0;

   // search for block with ID matching patch id
   r0 = M[$patch.struct_pointer];
   r0 = r0 + ($patch.PATCH_LIST_FIELD - $patch.block.NEXT_FIELD);
   loop:
      r2 = r0;
      r0 = M[r0 + $patch.block.NEXT_FIELD];
      if Z jump exit;
      r1 = M[r0 + $patch.block.ID_FIELD];
      Null = r1 - r5;
      if NZ jump loop;
      // fall through

   // remove block from list
   r3 = M[r0 + $patch.block.NEXT_FIELD];
   M[r2 + $patch.block.NEXT_FIELD] = r3;

   // free the memory
   call $malloc_pm.free;

   exit:
   // restore setting
   pop r0;
   M[$PM_WIN_ENABLE] = r0;

   jump $pop_rLink_and_rts;

.ENDMODULE;




#endif   //PATCH_INCLUDED






