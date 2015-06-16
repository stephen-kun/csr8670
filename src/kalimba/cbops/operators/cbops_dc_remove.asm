// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    DC remove operator
//
// DESCRIPTION:
//    It is useful to remove any dc component from the signal going to the DAC
// (as this is bad for speakers) and also from the ADC (as this might affect
// the operation of the compression codec used).
//
// The dc component is estimated as follows:
// @verbatim
//    dc_est = old_dc_est * (1 - 1/n) + current_sample * (1/n)
//
// where: old_dc_est is initialised to 0
//        1/n = $cbuffer.dc_remove.FILTER_COEF;
// @endverbatim
//
// The dc is removed from the sample as follows:
// @verbatim
//    sample = sample - dc_est
// @endverbatim
//
// When using the operator the following data structure is used:
//    - $cbops.dc_remove.INPUT_START_INDEX_FIELD = index of the input buffer
//    - $cbops.dc_remove.OUTPUT_START_INDEX_FIELD = index of the output
//       buffer
//    - $cbops.dc_remove.DC_ESTIMATE_FIELD = leave initialised to zero
//
// *****************************************************************************

#include "stack.h"
#include "cbops.h"

.MODULE $M.cbops.dc_remove;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.dc_remove[$cbops.function_vector.STRUC_SIZE] =
      &$cbops.dc_remove.reset,              // reset function
      $cbops.function_vector.NO_FUNCTION,   // amount to use function
      &$cbops.dc_remove.main;               // main function

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.dc_remove.reset
//
// DESCRIPTION:
//    Reset routine for the DC remove operator, see $cbops.dc_remove.main
//
// INPUTS:
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    none
//
// *****************************************************************************
.MODULE $M.cbops.dc_remove.reset;
   .CODESEGMENT CBOPS_DC_REMOVE_RESET_PM;
   .DATASEGMENT DM;

   // ** reset routine **
   $cbops.dc_remove.reset:
   // zero the current dc estimate
   M[r8 + $cbops.dc_remove.DC_ESTIMATE_FIELD] = Null;
   rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.dc_remove.main
//
// DESCRIPTION:
//    Operator that removes any DC component from the input data
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
//    rMAC, r0-4, r10, I0, L0, I4, L4, DoLoop
//
// *****************************************************************************
.MODULE $M.cbops.dc_remove.main;
   .CODESEGMENT CBOPS_DC_REMOVE_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.dc_remove.main:

   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $cbops.profile_dc_remove[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      $push_rLink_macro;
      r0 = &$cbops.profile_dc_remove;
      call $profiler.start;
   #endif

   // get the offset to the read buffer to use
   r0 = M[r8 + $cbops.dc_remove.INPUT_START_INDEX_FIELD];

   // get the input buffer read address
   r1 = M[r6 + r0];
   // store the value in I0
   I0 = r1;
   // get the input buffer length
   r1 = M[r7 + r0];
   // store the value in L0
   L0 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B0;
   #endif

   // get the offset to the write buffer to use
   r0 = M[r8 + $cbops.dc_remove.OUTPUT_START_INDEX_FIELD];

   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I4
   I4 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L4
   L4 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B4;
   #endif

   // get the current dc estimate
   rMAC = M[r8 + $cbops.dc_remove.DC_ESTIMATE_FIELD];

   r1 = $cbops.dc_remove.FILTER_COEF;

   // needed for saturation and used as -1.0 below
   r3 = 0x800000;

   // r2 = 1.0 - (1/n)
   // Note 0x800000 represents +1.0 so long as you subtract something from it
   // i.e. this works as long as $cbops.dc_remove.FILTER_COEF is not 0
   r2 = r3 - r1;

   // for speed pipeline the: read -> update -> write
   r10 = r10 - 1;

   // new_dc_est = old_dc_est * (1 - 1/n) + current_sample * (1/n)
   // and read the first sample
   rMAC = rMAC * r2, r0 = M[I0,1];

   rMAC = rMAC + r0 * r1;
   r0 = r0 - rMAC;
   // saturate if overflow has occured
   if V r0 = r0 * r3 (int) (sat);
   do loop;
      rMAC = rMAC * r2, r0 = M[I0,1], M[I4,1] = r0;
      rMAC = rMAC + r0 * r1;
      r0 = r0 - rMAC;
      if V r0 = r0 * r3 (int) (sat);
   loop:

   // zero the length registers and write the last sample
   L0 = 0, M[I4,1] = r0;
   L4 = 0;
   #ifdef BASE_REGISTER_MODE
      // Zero the base registers
      push Null;
      B4 = M[SP-1];
      pop B0;
   #endif

   // store updated dc estimate for next time
   M[r8 + $cbops.dc_remove.DC_ESTIMATE_FIELD] = rMAC;

   // stop profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      r0 = &$cbops.profile_dc_remove;
      call $profiler.stop;
      jump $pop_rLink_and_rts;
   #else
      rts;
   #endif

.ENDMODULE;

