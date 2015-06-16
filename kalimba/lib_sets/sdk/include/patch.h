// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef PATCH_HEADER_INCLUDED
#define PATCH_HEADER_INCLUDED

#include "patch_library.h"
#include "architecture.h"

   // patch types                              // Adds ID into patch table             Uses Patch RAM      Description
   .CONST $patch.REPLACEMENT_RAM_CODEPATCH   0;//    No                                    No              Overwrites PM RAM with new contents
   .CONST $patch.REPLACEMENT_RAM_DATAPATCH   1;//    No                                    No              Overwrites DM RAM with new contents
   .CONST $patch.SW_ROM_CODEPATCH            2;//    Yes                                   Yes             Enables ROM patch point, and downloads to patch RAM the code for this patch
   .CONST $patch.HW_ROM_CODEPATCH            3;//    No (but to hw patch register)         Yes             Enables ROM HW patch logic, and downloads to patch RAM the code for this patch
   .CONST $patch.RAM_CODEPATCH               4;//    Yes                                   Yes             Overwrites a PM RAM location with a jump instruction to patch RAM, and downloads to patch RAM the code for this patch
   .CONST $patch.EXCUTEPATCH                 5;//    No                                 Temporarily        Downloads to patch RAM, executes that code and completes

   // Other constants
   .CONST $patch.JUMP_INSTRUCTION_MS         0xDDF0;
   // HW patches must use IDs 0xFE0-0xFEF. These IDs should not be used by other patches
   .CONST $patch.HW_PATCH_ID_BASE            0xFE0;

   // patch structure
   .CONST $patch.TABLE_FAST_POINTER_FIELD                      0;
   .CONST $patch.NUM_OF_FAST_PATCHES_FIELD                     1;
   .CONST $patch.TABLE_SLOW_POINTER_FIELD                      2;
   .CONST $patch.NUM_OF_SLOW_PATCHES_FIELD                     3;
   .CONST $patch.PATCH_LIST_FIELD                              4;
   // extended-patch fields
   .CONST $patch.EXP_ADDRESS_FIELD                             5;
   .CONST $patch.EXP_REMAINING_FIELD                           6;
   .CONST $patch.STRUCT_SIZE                                   7;


   .CONST $patch.block.NEXT_FIELD      $PMWIN_LO_START + 0;
   .CONST $patch.block.ID_FIELD        $PMWIN_HI_START + 0;
   .CONST $patch.block.STRUC_SIZE      1;


#endif // PATCH_HEADER_INCLUDED

