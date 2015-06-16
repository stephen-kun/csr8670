// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1177960 $  $DateTime: 2011/12/16 15:39:27 $
// *****************************************************************************


#include "core_library.h"
#include "math_library.h"

.MODULE $math.fft_twiddle;
   .DATASEGMENT DM;

   .VAR twiddle_size_dm1 = 0;
   .VAR twiddle_size_dm2 = 0;
   .VAR interested_list = 0;

   .CONST NEXT_FIELD    0;
   .CONST OPID_FIELD    1;
   .CONST STRUC_SIZE    2;

   .CONST SUCCESS       0;
   .CONST FAIL          1;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $math.fft_twiddle.alloc
//
// DESCRIPTION:
//    Allocates and populates memory for fft twiddle factors. If the factors are
//    already allocated just register interest. The 'interested list' ID is
//    stored in a list of 'interested' parties. This ID can be anything but
//    is most useful when it is unique to each party using the fft.
//
// INPUTS:
//    - r1 = num fft points required
//    - r2 = 'interested list' ID
//
// OUTPUTS:
//    - r0 = result
//
// TRASHED REGISTERS:
//    r1-r6, doLoop, I0, I1, I4, M0, M1
//
// *****************************************************************************
.MODULE $M.math.fft_twiddle.alloc;
   .CODESEGMENT PM_FLASH;

   $math.fft_twiddle.alloc:

   $push_rLink_macro;

#if defined(PATCH_LIBS)
   // patch point trashes r0 and r3
   LIBS_SLOW_SW_ROM_PATCH_POINT($math.FFT_TWIDDLE.ALLOC.PATCH_ID_0, r3)
#endif

   // save opid
   push r2;
   // r3 = amount to alloc in each DM
   r3 = r1 LSHIFT -1;

   // check for the size of the currently allocated block for
   // imaginary twiddle factors
   r4 = 0;
   r0 = M[$fft.twiddle_imag_address];
   if NZ call $malloc.get_block_size;
   r5 = r0;
   Null = r0 - r3;
   if GE jump dm2_memory_ok;
      // set 'new imag' flag
      r4 = 1;
      // allocate new memory for imaginary twiddle factors
      r0 = r3;
      r1 = $malloc.dm_preference.DM2;
      call $malloc.alloc;
      r2 = r0;
      if Z jump out_of_ram1;
      r5 = r1;
   dm2_memory_ok:

   // check for the size of the currently allocated block for
   // real twiddle factors
   r0 = M[$fft.twiddle_real_address];
   if NZ call $malloc.get_block_size;
   r6 = r0;
   Null = r0 - r3;
   if GE jump dm1_memory_ok;
      // set 'new real' flag
      r4 = r4 OR 2;
      // allocate new memory for real twiddle factors
      r0 = r3;
      r1 = $malloc.dm_preference.DM1;
      call $malloc.alloc;
      r3 = r0;
      if Z jump out_of_ram2;
      r6 = r1;

      // definitely got memory for both real and imag twiddle
      // factors so can start freeing old memory
      r0 = M[$fft.twiddle_real_address];
      if NZ call $malloc.free;
      M[$fft.twiddle_real_address] = r3;
   dm1_memory_ok:

   Null = r4 AND 1;
   if Z jump dont_free_imag;
      // got new memory for imag factors, free old memory
      r0 = M[$fft.twiddle_imag_address];
      if NZ call $malloc.free;
      M[$fft.twiddle_imag_address] = r2;
   dont_free_imag:

   Null = r4;
   if Z jump dont_load_factors;
      // some new memory was allcated, use it
      r2 = M[$fft.twiddle_imag_address];
      r1 = M[$fft.twiddle_real_address];
      // calculate min(real_block_size,imag_block_size)
      Null = r5 - r6;
      if GT r5 = r6;
      // calculate max twiddle factors that will fit (*2)
      r0 = SIGNDET r5;
      r0 = (24-1) - r0;
      r0 = 1 LSHIFT r0;
      call $math.load_fft_twiddle_factors;
   dont_load_factors:

   // register interest
   r0 = $math.fft_twiddle.STRUC_SIZE;
   r1 = $malloc.dm_preference.NO_PREFERNCE;
   call $malloc.alloc;
   Null = r0;
   if Z jump out_of_ram3;
   r1 = M[$math.fft_twiddle.interested_list];
   M[r0 + $math.fft_twiddle.NEXT_FIELD] = r1;
   M[$math.fft_twiddle.interested_list] = r0;
   pop r2;
   M[r0 + $math.fft_twiddle.OPID_FIELD] = r2;

   r0 = $math.fft_twiddle.SUCCESS;
   jump $pop_rLink_and_rts;


   out_of_ram2:
      // free the DM2 memory we just allcated
      Null = r4 AND 1;
      if Z jump out_of_ram1;
         r0 = r2;
         call $malloc.free;
   out_of_ram1:
   out_of_ram3:
      pop r2;
#ifdef DEBUG_ON
      call $error;
#endif
      r0 = $math.fft_twiddle.FAIL;
      jump $pop_rLink_and_rts;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $math.fft_twiddle.free
//
// DESCRIPTION:
//    Unregisters interest in fft twiddle factors then frees them if no-one else
//    is interested
//
// INPUTS:
//    - r1 = 'interested list' ID
//
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0, r2, r3
//
// *****************************************************************************
.MODULE $M.math.fft_twiddle.free;
   .CODESEGMENT PM_FLASH;

   $math.fft_twiddle.free:

   $push_rLink_macro;

#if defined(PATCH_LIBS)
   // patch point trashes r0 and r2
   LIBS_SLOW_SW_ROM_PATCH_POINT($math.FFT_TWIDDLE.FREE.PATCH_ID_0, r2)
#endif

   // find entry in interested list
   r3 = $math.fft_twiddle.interested_list;
   r0 = M[r3];
   if Z jump check_interested_list;
   search_interested_loop:
      r2 = M[r0 + $math.fft_twiddle.OPID_FIELD];
      Null = r2 - r1;
      if Z jump found;
      r3 = r0;
      r0 = M[r0 + $math.fft_twiddle.NEXT_FIELD];
      if NZ jump search_interested_loop;
      //fall through

   // opid isn't in interested list
   // still free the factors if the list is empty
   jump check_interested_list;


   found:
   // remove entry from list
   r1 = M[r0 + $math.fft_twiddle.NEXT_FIELD];
   M[r3 + $math.fft_twiddle.NEXT_FIELD] = r1;

   // free the entry
   call $malloc.free;

   check_interested_list:
   // check whether anyone is still interested
   Null = M[$math.fft_twiddle.interested_list];
   if NZ jump exit_ok;
      // no-one is, free the factors
      r0 = M[$fft.twiddle_real_address];
      if NZ call $malloc.free;
      M[$fft.twiddle_real_address] = 0;
      r0 = M[$fft.twiddle_imag_address];
      if NZ call $malloc.free;
      M[$fft.twiddle_imag_address] = 0;
   exit_ok:
   jump $pop_rLink_and_rts;

.ENDMODULE;