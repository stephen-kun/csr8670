// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef SBC_WBS_ONLY
#ifndef SBC_CHANGE_STATE_INCLUDED
#define SBC_CHANGE_STATE_INCLUDED

#include "sbc.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.save_state
//
// DESCRIPTION:
//    Saves the current decoder state into the provided memory.
//
// INPUTS:
//    - I0 = Address of memory region to write state to
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, I4, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.sbcdec.save_state;
   .CODESEGMENT SBCDEC_SAVE_STATE_PM;
   .DATASEGMENT DM;

   $sbcdec.save_state:

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.CHANGE_STATE_ASM.SAVE_STATE.PATCH_ID_0, r1)
   pop r1;
#endif

   // synthesis filter 1

   // get all of the single variables, then do the two buffes
   r0 = M[r9 + $sbc.mem.GET_BITPOS_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.SYNTHESIS_VCH1PTR_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.SYNTHESIS_VCH2PTR_FIELD];

   r10 = M[r9 + $sbc.mem.SYNTHESIS_VCH1_FIELD];
   I4 = r10;
   r10 = $sbcdec.SYNTHESIS_BUFFER_LENGTH;


   do copy_synthesis_vch1_loop;
      r0 = M[I4, 1],    M[I0, 1] = r0;
   copy_synthesis_vch1_loop:

   // synthesis filter 2

   r10 = M[r9 + $sbc.mem.SYNTHESIS_VCH2_FIELD];
   I4 = r10;
   r10 = $sbcdec.SYNTHESIS_BUFFER_LENGTH;


   do copy_synthesis_vch2_loop;
      r0 = M[I4, 1],    M[I0, 1] = r0;
   copy_synthesis_vch2_loop:

   M[I0, 1] = r0;

   // lastly if a debug build store the debug variables
   #ifdef DEBUG_SBCDEC
      r0 = M[$sbcdec.framecount];
      M[I0, 1] = r0;
      r0 = M[$sbcdec.framecrc_errors];
      M[I0, 1] = r0;
      r0 = M[$sbcdec.lostsync_errors];
      M[I0, 1] = r0;
   #endif

   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $sbcdec.restore_state
//
// DESCRIPTION:
//    Restores the current decoder state from the provided memory.
//
// INPUTS:
//    - I0 = Address of memory region to read state from
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, I4, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.sbcdec.restore_state;
   .CODESEGMENT SBCDEC_RESTORE_STATE_PM;
   .DATASEGMENT DM;

   $sbcdec.restore_state:

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcdec.CHANGE_STATE_ASM.RESTORE_STATE.PATCH_ID_0, r1)
   pop r1;
#endif

   // synthesis filter 1
   r10 = $sbcdec.SYNTHESIS_BUFFER_LENGTH - 1;

   // get all of the single variables, then do the two buffes
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.GET_BITPOS_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.SYNTHESIS_VCH1PTR_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.SYNTHESIS_VCH2PTR_FIELD] = r0;

   r0 = M[r9 + $sbc.mem.SYNTHESIS_VCH1_FIELD];
   I4 = r0;


   r0 = M[I0, 1];

   do copy_synthesis_vch1_loop;
      r0 = M[I0, 1],    M[I4, 1] = r0;
   copy_synthesis_vch1_loop:

   M[I4, 1] = r0;

   // synthesis filter 2
   r10 = $sbcdec.SYNTHESIS_BUFFER_LENGTH - 1;

   r0 = M[r9 + $sbc.mem.SYNTHESIS_VCH2_FIELD];
   I4 = r0;


   r0 = M[I0, 1];

   do copy_synthesis_vch2_loop;
      r0 = M[I0, 1],    M[I4, 1] = r0;
   copy_synthesis_vch2_loop:

   M[I4, 1] = r0;

   // lastly if a debug build store the debug variables
   #ifdef DEBUG_SBCDEC
      r0 = M[I0, 1];
      M[$sbcdec.framecount] = r0;
      r0 = M[I0, 1];
      M[$sbcdec.framecrc_errors] = r0;
      r0 = M[I0, 1];
      M[$sbcdec.lostsync_errors] = r0;
   #endif

   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $sbcenc.save_state
//
// DESCRIPTION:
//    Saves the current decoder state into the provided memory.
//
// INPUTS:
//    - I0 = Address of memory region to write state to
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, I4, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.sbcenc.save_state;
   .CODESEGMENT SBCENC_SAVE_STATE_PM;
   .DATASEGMENT DM;

   $sbcenc.save_state:

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.CHANGE_STATE_ASM.SAVE_STATE.PATCH_ID_0, r1)
   pop r1;
#endif

   // get all of the single variables, then do the two buffes
   r0 = M[r9 + $sbc.mem.PUT_NEXTWORD_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.PUT_BITPOS_FIELD];
   M[I0, 1] = r0;
   // various encoder settings
   r0 = M[r9 + $sbc.mem.ENC_SETTING_NROF_SUBBANDS_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_NROF_BLOCKS_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_SAMPLING_FREQ_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_CHANNEL_MODE_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_ALLOCATION_METHOD_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_BITPOOL_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ENC_SETTING_FORCE_WORD_ALIGN_FIELD];
   M[I0, 1] = r0;
   // the analysis buffer pointers
   r0 = M[r9 + $sbc.mem.ANALYSIS_XCH1PTR_FIELD];
   M[I0, 1] = r0;
   r0 = M[r9 + $sbc.mem.ANALYSIS_XCH2PTR_FIELD];


   // analysis filter 1
   r10 = M[r9 + $sbc.mem.ANALYSIS_XCH1_FIELD];
   I4 = r10;
   r10 = $sbcenc.ANALYSIS_BUFFER_LENGTH;

   do copy_analysis_xch1_loop;
      r0 = M[I4, 1],    M[I0, 1] = r0;
   copy_analysis_xch1_loop:

   // analysis filter 2
   r10 = M[r9 + $sbc.mem.ANALYSIS_XCH2_FIELD];
   I4 = r10;
   r10 = $sbcenc.ANALYSIS_BUFFER_LENGTH;

   do copy_analysis_xch2_loop;
      r0 = M[I4, 1],    M[I0, 1] = r0;
   copy_analysis_xch2_loop:

   M[I0, 1] = r0;

   // lastly if we are in debug mode
   #ifdef DEBUG_SBCENC
      r0 = M[$sbcenc.framecount];
      M[I0, 1] = r0;
   #endif

   rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $sbcenc.restore_state
//
// DESCRIPTION:
//    Restores the current decoder state from the provided memory.
//
// INPUTS:
//    - I0 = Address of memory region to read state from
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, I4, r10, DoLoop
//
// *****************************************************************************
.MODULE $M.sbcenc.restore_state;
   .CODESEGMENT SBCENC_RESTORE_STATE_PM;
   .DATASEGMENT DM;

   $sbcenc.restore_state:

#if defined(PATCH_LIBS)
   push r1;
   LIBS_SLOW_SW_ROM_PATCH_POINT($sbcenc.CHANGE_STATE_ASM.RESTORE_STATE.PATCH_ID_0, r1)
   pop r1;
#endif

   // get all of the single variables, then do the two buffes
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.PUT_NEXTWORD_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.PUT_BITPOS_FIELD] = r0;
   // various encoder settings
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_NROF_SUBBANDS_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_NROF_BLOCKS_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_SAMPLING_FREQ_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_CHANNEL_MODE_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_ALLOCATION_METHOD_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_BITPOOL_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ENC_SETTING_FORCE_WORD_ALIGN_FIELD] = r0;
   // the analysis buffer pointers
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ANALYSIS_XCH1PTR_FIELD] = r0;
   r0 = M[I0, 1];
   M[r9 + $sbc.mem.ANALYSIS_XCH2PTR_FIELD] = r0;


   // analysis filter 1
   r10 = ($sbcenc.ANALYSIS_BUFFER_LENGTH - 1);
   r0 = M[r9 + $sbc.mem.ANALYSIS_XCH1_FIELD];
   I4 = r0;



   r0 = M[I0, 1];

   do copy_analysis_xch1_loop;
      r0 = M[I0, 1],    M[I4, 1] = r0;
   copy_analysis_xch1_loop:

   M[I4, 1] = r0;

   // analysis filter 2
   r10 = ($sbcenc.ANALYSIS_BUFFER_LENGTH - 1);

   r0 = M[r9 + $sbc.mem.ANALYSIS_XCH2_FIELD];
   I4 = r0;


   r0 = M[I0, 1];

   do copy_analysis_xch2_loop;
      r0 = M[I0, 1],    M[I4, 1] = r0;
   copy_analysis_xch2_loop:

   M[I4, 1] = r0;

   // lastly if we are in debug mode
   #ifdef DEBUG_SBCENC
      r0 = M[I0, 1];
      M[$sbcenc.framecount] = r0;
   #endif

   rts;

.ENDMODULE;


#endif
#endif
