// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.audio_proc.stream_gain
//
//DESCRIPTION:
//    Used for copying data across stream buffers. This module performs sample
//    copying with gain control (mantissa & exponent) employing ramped
//    gain changes.
//
// INPUTS:
//    - r7 = Pointer to the stream copy data structure
//    - r8 = Pointer to the ramp control data structure
//
// OUTPUT:
//    None
//
// TRASHED REGISTERS:
//      r0-r7, r10, I0, I2, I4, M1, L0, L4, DoLoop
// *****************************************************************************

#include "stream_gain.h"
#ifdef PATCH_LIBS
   #include "patch_library.h"
#endif
#include "cbuffer.h"

.MODULE $M.audio_proc.stream_gain.Process;

   .CODESEGMENT   AUDIO_PROC_STREAM_GAIN_PROCESS_PM;

func:
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($audio_proc.STREAM_GAIN_ASM.PROCESS.PATCH_ID_0,r1) // af05_CVC_patches1
#endif

   push rLink;
   // Get Input Buffer
   r0  = M[r7 + $M.audio_proc.stream_gain.OFFSET_INPUT_PTR];

#ifdef BASE_REGISTER_MODE
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B0;
#else
   call $frmbuffer.get_buffer;
#endif
   I0  = r0;
   L0  = r1;

   // Use input frame size
   r10 = r3;
   // Update output frame size from input
   r0 = M[r7 + $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR];
   call $frmbuffer.set_frame_size;

   // Get output buffer
#ifdef BASE_REGISTER_MODE
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B4;
#else
   call $frmbuffer.get_buffer;
#endif
   I4 = r0;
   L4 = r1;
   pop rLink;

   r1 = M[r7 + $M.audio_proc.stream_gain.OFFSET_PTR_MANTISSA];
   r2 = M[r7 + $M.audio_proc.stream_gain.OFFSET_PTR_EXPONENT];
   // dereference pointer (mantissa)
   r1 = M[r1];
   // dereference pointer (exponent),
   r2 = M[r2];
   // r0 = first value of i/p buffer
   r0 = M[I0,1];

   // Check if ramping is supported (i.e. r8 points at stream_gain_ramp structure)
   null = r8 - 0;
   if Z jump adjust_gain;

   r3 = M[r8 + $audio_proc.stream_gain_ramp.PREV_MANTISSA_FIELD];    //
   r4 = M[r8 + $audio_proc.stream_gain_ramp.PREV_EXPONENT_FIELD];    //

   null = r1 - r3;                        // Check if mantissa has changed
   if NZ jump apply_ramp;                 // Yes - need to ramp

   null = r2 - r4;                        // Check if exponent has changed
   if Z jump adjust_gain;                 // No - do specified gain adjustment

   //...drop through and apply a ramped gain change
   apply_ramp:

   r5 = M[r8 + $audio_proc.stream_gain_ramp.RAMP_GAIN_FIELD];        // Get the new value blending gain

   // r10 = number of samples to process
   do lp_ramp_copy;

      r6 = M[r8 + $audio_proc.stream_gain_ramp.RAMP_STEP_FIELD];     // Get the blending gain step value
      r5 = r5 + r6;                                                  // Ramp the blend of old and new levels

      null = r5 - 1.0;                    // Ramp done?
      if POS jump complete;               // If ramp is complete finish copy without ramp

      // Calculate the sample value with desired gain
      rMAC = r0 * r1;                     // = i/p * mantissa
      r6 = rMAC ASHIFT r2;                // = o/p = rMAC * 2^Exponent

      r6 = r6 * r5 (frac);                // Blend the new gain sample level

      r7 = 1.0 - r5;                      // Calculate the blend gain for the old level

      // Calculate the sample value with previous gain
      rMAC = r0 * r3;                     // = i/p * mantissa
      r0 = rMAC ASHIFT r4;                // = o/p = rMAC * 2^Exponent

      r0 = r0 * r7 (frac);                // Blend the old gain sample level

      r0 = r0 + r6;                       // Mix old and new contributions

      // Save o/p value, load next i/p value
      M[I4,1] = r0, r0 = M[I0,1];

   lp_ramp_copy:

   M[r8 + $audio_proc.stream_gain_ramp.RAMP_GAIN_FIELD] = r5;    // Save the blending gain for the next call

   jump exit;

   // Ramping is complete
   complete:

   // Save the current gain values as previous values
   M[r8 + $audio_proc.stream_gain_ramp.PREV_MANTISSA_FIELD] = r1;
   M[r8 + $audio_proc.stream_gain_ramp.PREV_EXPONENT_FIELD] = r2;

   // Reset the ramp gain ready for the next volume change
   M[r8 + $audio_proc.stream_gain_ramp.RAMP_GAIN_FIELD] = 0;

   // ... drop through to complete processing after ramp completes

   // Gain control following ramp
   adjust_gain:

   do lp_stream_copy;
      // rMAC = i/p * mantissa
      rMAC = r0 * r1;
      // rMAC = o/p = rMAC * 2^Exponent
      rMAC = rMAC ASHIFT r2 (56bit);
      // Save o/p value, load next i/p value
      M[I4,1] = rMAC, r0 = M[I0,1];
lp_stream_copy:

exit:

   // clear L0/L4
   L0 = Null;
   L4 = Null;
#ifdef BASE_REGISTER_MODE
   push Null;
   B4 = M[SP-1];
   pop  B0;
#endif

   rts;
.ENDMODULE;
