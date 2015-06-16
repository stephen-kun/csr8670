// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 762921 $  $DateTime: 2011/04/07 16:29:18 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Frame Sync Auxilary Audio mix operator
//
// DESCRIPTION:
//    It is desireable to mix in auxillary audio for voice prompts or tones.
//    This operator mixes data from a supplied buffer in with the "main" data stream.
//    Clipping and volume adjustment is supported
//
//    The number of samples in the sidetone buffer is monitored at this point.
// If there are too few, extra samples are created by repeating the last sample
// from the buffer. If too many samples are present, one sample will be
// discarded during each call.
//
// When using the operator the following data structure is used:
//    - $frame_sync.sidetone_mix_op.INPUT_START_INDEX_FIELD = the input buffer
//       index
//    - $frame_sync.sidetone_mix_op.OUTPUT_START_INDEX_FIELD = the output
//       buffer index
//    - $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD = the address of the
//       sidetone cbuffer struc
//    - $frame_sync.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD = the number of
//       samples allowed to build up in the sidetone buffer
//    - $frame_sync.sidetone_mix_op.GAIN_FIELD = the address of the gain to
//       apply to the sidetone samples
//
// *****************************************************************************

#include "stack.h"
#include "cbops_vector_table.h"
#include "frame_sync_aux_mix_operator.h"
#ifdef PATCH_LIBS
   #include "patch_library.h"
#endif
#include "cbuffer.h"

.MODULE $M.frame_sync.aux_audio_mix_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $frame_sync.aux_audio_mix_op[$cbops.function_vector.STRUC_SIZE] =
      // reset function
      $cbops.function_vector.NO_FUNCTION,
      // amount to use function
      $cbops.function_vector.NO_FUNCTION,
      // main function
      &$frame_sync.aux_audio_mix_op.main;

.ENDMODULE;




// *****************************************************************************
// MODULE:
//    $frame_sync.sidetone_mix_op.main
//
// DESCRIPTION:
//    Operator that mixes the auxillary audio with the main input
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
//    r0, r1, r2, r3, r5, r6, r10, rMAC, M1, I0, I1, I4, L0, L1, L4, DoLoop
//
// *****************************************************************************


.MODULE $M.frame_sync.aux_audio_mix_op.main;
   .CODESEGMENT FRAME_SYNC_AUXAUDIO_MIX_OP_MAIN_PM;
   .DATASEGMENT DM;

   $frame_sync.aux_audio_mix_op.main:

   // push rLink onto stack
   $push_rLink_macro;
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($frame_sync.FRAME_SYNC_AUX_MIX_OPERATOR_ASM.AUX_AUDIO_MIX_OP.PATCH_ID_0,r1) // af05_CVC_patches1
#endif

   // Check State of Auxilary Audio

   // Get Auxillary Audio buffer and amount of data

   // With the new previnised cvc the tone buffer may not be connected
   r0 = M[r8 + $frame_sync.aux_audio_mix_op.TONE_BUFFER_FIELD];
   if Z jump no_tone;
   #ifdef BASE_REGISTER_MODE
      call $cbuffer.get_read_address_and_size_and_start_address;
      push r2;
      pop  B4;
   #else
      call $cbuffer.get_read_address_and_size;
   #endif
      I4 = r0;
      L4 = r1;
      r0 = M[r8 + $frame_sync.aux_audio_mix_op.TONE_BUFFER_FIELD];
      M[r8 + $frame_sync.aux_audio_mix_op.INTERNAL_BUF_PTR_FIELD] = r0;
      call $cbuffer.calc_amount_data;

   no_tone:
   // Save transfer amount
   push r10;

   // Compare data in Auxillary buffer to amount_to_use (r10)
   r10 = r10 - r0;
   if LE jump lp_in_tone;
      // Is the Buffer Empty?
      M0 = r0;
      if Z jump lp_no_tone_or_start_tone_proc;

         // There's is insufficient auxillary audio to transfer.  If the port is enabled, it must have
         // just been connected and we're just starting to aquire data.  If the port is
         // disabled, we must have just disconnected the port and we need to mix the
         // remaining data.
         r0 = M[r8 + $frame_sync.aux_audio_mix_op.TONE_PORT_FIELD];
         call $cbuffer.is_it_enabled;
         if Z jump lp_no_tone_or_start_tone_proc;

         // Last chunk of data so zero padd and advance write pointer
         // Save Ptr and Advance past good data, r1=0
         r3  = I4;

         r1 = r1 XOR r1, r0 = M[I4,M0];
         // Zero Pad remainder of transfer
         do lp_zero;
            M[I4,1] = r1;
lp_zero:
         // Update Write address past frame
         r0 = M[r8 + $frame_sync.aux_audio_mix_op.TONE_BUFFER_FIELD];
         r1 = I4;
         call $cbuffer.set_write_address;
         // Restore Pointer
         I4 = r3;
         jump AuxDone;

lp_no_tone_or_start_tone_proc:
      // Tone Buffer is empty (May be start of tone or no tone)
      // No tone to mix.  Update hold timer
      r0 = M[r8 + $frame_sync.aux_audio_mix_op.TIMER_FIELD];
      r0 = r0 + 1;
      if POS  r0 = Null;
      M[r8 + $frame_sync.aux_audio_mix_op.TIMER_FIELD] = r0;
      M[r8 + $frame_sync.aux_audio_mix_op.INTERNAL_BUF_PTR_FIELD] = NULL;
      jump AuxDone;

lp_in_tone:
   // We have sufficient tone data to process.  Reset hold timer
   r0 = M[r8 + $frame_sync.aux_audio_mix_op.TIMER_HOLD_FIELD];
   M[r8 + $frame_sync.aux_audio_mix_op.TIMER_FIELD] = r0;
AuxDone:

   // Restore Transfer amount
   pop r10;

   // I4,L4 is Aux Audio Buffer

   // get the offset to the read buffer to use
   r0 = M[r8 + $frame_sync.aux_audio_mix_op.INPUT_START_INDEX_FIELD];
   r1 = M[r6 + r0];
   I0 = r1;
   r1 = M[r7 + r0];
   L0 = r1;
#ifdef BASE_REGISTER_MODE
   r1 = M[r5 + r0];
   push r1;
   pop  B0;
#endif

   // get the offset to the write buffer to use
   r0 = M[r8 + $frame_sync.aux_audio_mix_op.OUTPUT_START_INDEX_FIELD];
   r1 = M[r6 + r0];
   I5 = r1;
   r1 = M[r7 + r0];
   L5 = r1;
#ifdef BASE_REGISTER_MODE
   r1 = M[r5 + r0];
   push r1;
   pop  B5;
#endif

   // Recompute clipper threshold based on current volume.
   // As volume decreases the degree of clipping also decreases.
   // This is done outside the loop below so at most there could be
   // a one ms delay between a volume change and recomputing the
   // threshold value.

   r9 = 0x800000;       // -1.0 factional
   // r7 = gain mantisa: (Q8.15)
   r7 = M[r8 + $frame_sync.aux_audio_mix_op.OFFSET_INV_DAC_GAIN];
   M1 = 1;
   M0 = 0;
   r1 = M[r8 + $frame_sync.aux_audio_mix_op.CLIP_POINT_FIELD];
   // Multiply the Clip Point (r1) with the inverse DAC gain (r7)
   rMAC = r1 * r7;
   // r7 = clip point.
   // The inverse DAC gain is Q8.15, so we need to shift r7 to get Q23
   r7 = rMAC ASHIFT 8;
   // limit the clipper threshold so DAC wrap bug doesn't occur
   r1 = M[r8 + $frame_sync.aux_audio_mix_op.BOOST_CLIP_POINT_FIELD];
   Null = r7 - r1;
   if POS r7 = r1;

   // Adjust SCO gain to Auxillary DAC level
   r6 = M[r8 + $frame_sync.aux_audio_mix_op.PRIM_GAIN_FIELD];           // Q5.18
   r3 = M[r8 + $frame_sync.aux_audio_mix_op.AUX_GAIN_ADJUST_FIELD];     // Q23
   r6 = r6 * r3 (frac);
   r3 = 0x80000;        // 0dB gain (Q5.18)
   // If not in or just after tone primary gain is (0 dB)
   NULL = M[r8 + $frame_sync.aux_audio_mix_op.TIMER_FIELD];
   if POS r6 = r3;

   // Only mix tone if we have a buffer
   r5 = M[r8 + $frame_sync.aux_audio_mix_op.AUX_GAIN_FIELD];            // Q5.18
   NULL = M[r8 + $frame_sync.aux_audio_mix_op.INTERNAL_BUF_PTR_FIELD];
   if Z r5 = NULL;

   // Apply Boost       Q5.18 * Q4.19 = Q9.14
   r3 = M[r8 + $frame_sync.aux_audio_mix_op.BOOST_FIELD];
   r6 = r6 * r3 (frac);
   r4 = r5 * r3 (frac);

   // I1 = &Aux peakval
   I1 = r8 + $frame_sync.aux_audio_mix_op.PEAK_AUXVAL_FIELD;

   // r4 - Aux Gain (Mixing)    (Q9.14)
   // r5 - Aux Gain (Peak)      (Q5.18)
   // r6 - Primary Gain         (Q9.14)
   // r7 - clip point           (Q23)

   // LOOP START
   do lp_clipper;
     //r2 = SCO, r1 = Tone (Aux)
     r2 = M[I0,1], r1 = M[I4,1];

     // Mix signal and Aux Tone
     rMAC = r1 * r4;
     rMAC = RMAC + r2 * r6;

     // Calculate Peak magnitude of Aux signal
     // r2=Aux peakval
     r1 = r1 * r5 (frac), r2 = M[I1, 0];
     // r1=ABS(Aux)
     if NEG r1 = r1 * r9 (frac);
     // max<test?
     Null = r2 - r1;
     if LT r2 = r1;

     // Get Sign
     r1 = rMAC ASHIFT 56;
     // Signal (Q23)
     r3 = rMAC ASHIFT 9;
     // ABS Magnitude
     r3 = r3 * r1 (frac),  M[I1,M0] = r2;
     // Check for Clip
     Null = r3 - r7;
     if POS r3 = r7;
     // Reset sign
     r3 = r3 * r1 (frac);
     M[I5,1] = r3;
lp_clipper:

   L0 = 0;
   L4 = 0;
   L5 = 0;
#ifdef BASE_REGISTER_MODE
   push Null;
   B0 = M[SP-1];
   B4 = M[SP-1];
   pop B5;
#endif
   // Update Auxilar Audio stream pointer
   r1 = I4;
   r0 = M[r8 + $frame_sync.aux_audio_mix_op.INTERNAL_BUF_PTR_FIELD];
   if NZ call $cbuffer.set_read_address;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
