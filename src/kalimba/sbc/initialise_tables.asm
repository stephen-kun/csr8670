// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef INITIALISE_TABLES_ASM_INCLUDED
#define INITIALISE_TABLES_ASM_INCLUDED


#include "core_library.h"

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbc.init_tables
//
// DESCRIPTION:
//    This function will populate all the tables in RAM with data in tables in
//    Flash/ROM. Initialises encoder, decoder and common tables, hence it needs
//    a joint data object pointer. For separate encoder and decoder table init,
//    use sbcenc.init_tables and sbcdec.init_tables functions, respectively.
//
// INPUTS:
//    - R9 pointer to data object with valid data object with buffers
//      allocated
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// NOTES:
//    -
//
// *****************************************************************************
.MODULE $M.sbc.init_tables;
   .CODESEGMENT SBC_INIT_TABLES_PM;
   .DATASEGMENT DM;

   $sbc.init_tables:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbc.INIT_TABLES_ASM.INIT_TABLES.PATCH_ID_0, r2)
#endif

   call $sbcdec.private.init_tables;
   call $sbcenc.private.init_tables;
   call $sbc.private.init_tables_common;

   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $sbcdec.init_tables
//
// DESCRIPTION:
//    This function will populate all the tables in RAM with data in tables in
//    Flash/ROM needed by the SBC decoder.
//
// INPUTS:
//    - R5 pointer to decoder structure, which has valid data object with buffers
//      allocated
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// NOTES:
//    -
//
// *****************************************************************************
.MODULE $M.sbcdec.init_tables;
   .CODESEGMENT SBCDEC_INIT_TABLES_PM;
   .DATASEGMENT DM;

   $sbcdec.init_tables:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.INIT_TABLES_ASM.INIT_TABLES.PATCH_ID_0, r2)
#endif

   r9 = M[r5 + $codec.DECODER_DATA_OBJECT_FIELD];
   call $sbcdec.private.init_tables;
   call $sbc.private.init_tables_common;

   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $sbcenc.init_tables
//
// DESCRIPTION:
//    This function will populate the tables in RAM with data in tables in
//    Flash/ROM needed by the SBC encoder.
//
// INPUTS:
//    - R5 pointer to encoder structure, which has valid data object with buffers
//      allocated
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// NOTES:
//    -
//
// *****************************************************************************
.MODULE $M.sbcenc.init_tables;
   .CODESEGMENT SBCENC_INIT_TABLES_PM;
   .DATASEGMENT DM;

   $sbcenc.init_tables:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.INIT_TABLES_ASM.INIT_TABLES.PATCH_ID_0, r2)
#endif

   r9 = M[r5 + $codec.ENCODER_DATA_OBJECT_FIELD];
   call $sbcenc.private.init_tables;
   call $sbc.private.init_tables_common;

   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// *******************  PRIVATE FUNCTIONS FROM THIS POINT ON *******************
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    $sbcdec.private.init_tables
//
// DESCRIPTION:
//    This function will populate decoder tables in RAM with data in tables in
//    Flash/ROM
//
// INPUTS:
//    - R9 pointer to data object with buffers allocated
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// NOTES:
//    -
//
// *****************************************************************************
.MODULE $M.sbcdec.private.init_tables;
   .CODESEGMENT SBCDEC_PRIVATE_INIT_TABLES_PM;
   .DATASEGMENT DM;

   $sbcdec.private.init_tables:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.INIT_TABLES_ASM.PRIVATE.INIT_TABLES.PATCH_ID_0, r2)
#endif

   r2 = M[$flash.windowed_data16.address];

   // synthesis_coefs_m8
   r0 = M[r9 + $sbc.mem.SYNTHESIS_COEFS_M8_FIELD];
   I0 = r0;
   r0 = &$sbcdec.synthesis_coefs_m8;
   r1 = 128;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky

#ifndef SBC_WBS_ONLY
   // synthesis_coefs_m4
   // TODO can't we just use one of the tables depending on the setting?
   r0 = M[r9 + $sbc.mem.SYNTHESIS_COEFS_M4_FIELD];
   I0 = r0;
   r0 = &$sbcdec.synthesis_coefs_m4;
   r1 = 32;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky
#endif

   // levelrecip_coefs
   r0 = M[r9 + $sbc.mem.LEVELRECIP_COEFS_FIELD];
   I0 = r0;
   r0 = &$sbcdec.levelrecip_coefs;
   r1 = 15;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky

   // bitmask_lookup
   r0 = M[r9 + $sbc.mem.BITMASK_LOOKUP_FIELD];
   I0 = r0;
   r0 = &$sbcdec.bitmask_lookup;
   r1 = 17;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $sbcenc.private.init_tables
//
// DESCRIPTION:
//    This function will populate encoder tables in RAM with data in tables in
//    Flash/ROM
//
// INPUTS:
//    - R9 pointer to data object with buffers allocated
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// NOTES:
//    -
//
// *****************************************************************************
.MODULE $M.sbcenc.private.init_tables;
   .CODESEGMENT SBCENC_PRIVATE_INIT_TABLES_PM;
   .DATASEGMENT DM;

   $sbcenc.private.init_tables:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.INIT_TABLES_ASM.PRIVATE.INIT_TABLES.PATCH_ID_0, r2)
#endif

   r2 = M[$flash.windowed_data16.address];

   // analysis_coefs_m8
   r0 = M[r9 + $sbc.mem.ANALYSIS_COEFS_M8_FIELD];
   I0 = r0;
   r0 = &$sbcenc.analysis_coefs_m8;
   r1 = 128;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky

#ifndef SBC_WBS_ONLY
   // analysis_coefs_m4
   // TODO can't we just use one of the tables depending on the setting?
   r0 = M[r9 + $sbc.mem.ANALYSIS_COEFS_M4_FIELD];
   I0 = r0;
   r0 = &$sbcenc.analysis_coefs_m4;
   r1 = 32;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky
#endif

   // level_coefs
   r0 = M[r9 + $sbc.mem.LEVEL_COEFS_FIELD];
   I0 = r0;
   r0 = &$sbcenc.level_coefs;
   r1 = 15;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky

   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $sbc.private.init_tables_common
//
// DESCRIPTION:
//    This function will populate common tables in RAM with data in tables in
//    Flash/ROM
//
// INPUTS:
//    - r9 = pointer to data object, which has valid pointers
//           to allocated buffers.
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - TODO
//
// NOTES:
//    -
//
// *****************************************************************************
.MODULE $M.sbc.private.init_tables_common;
   .CODESEGMENT SBC_PRIVATE_INIT_TABLES_COMMON_PM;
   .DATASEGMENT DM;

   $sbc.private.init_tables_common:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbc.INIT_TABLES_ASM.PRIVATE.INIT_TABLES_COMMON.PATCH_ID_0, r2)
#endif

   // -- common tables
   r2 = M[$flash.windowed_data16.address];
   // this is common table init,
   // and may have only encoder or only decoder side used, use R9 from previous encoder or decoder-specific
   // table initialisation.

   // win_coefs_m8
   r0 = M[r9 + $sbc.mem.WIN_COEFS_M8_FIELD];
   I0 = r0;
   r0 = &$sbc.win_coefs_m8;
   r1 = 80;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky

#ifndef SBC_WBS_ONLY
   // win_coefs_m4
   r0 = M[r9 + $sbc.mem.WIN_COEFS_M4_FIELD];
   I0 = r0;
   r0 = &$sbc.win_coefs_m4;
   r1 = 40;
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm_24;// TODO does not trash r2 but risky
#endif

   // loudness_offset
   r0 = M[r9 + $sbc.mem.LOUDNESS_OFFSET_FIELD];
   I0 = r0;
   r0 = &$sbc.loudness_offset;
#ifndef SBC_WBS_ONLY
   r1 = 48;
#else
   r1 = 32;
#endif
   // r2 = M[$flash.windowed_data16.address];
   call $flash.copy_to_dm;// does not trash r2

   jump $pop_rLink_and_rts;

.ENDMODULE;



#endif // INITIALISE_TABLES_ASM_INCLUDED
