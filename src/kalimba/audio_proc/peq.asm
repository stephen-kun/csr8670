// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

// $****************************************************************************
// NAME:
//    Audio Processing Library PEQ Module (version 2.0.0)
//
// DESCRIPTION:
//    Parametric Equalizer based on multi-stage biquad filter
//
// MODULES:
//    $audio_proc.peq.initialize
//    $audio_proc.peq.process
// *****************************************************************************

#ifndef AUDIO_PEQ_INCLUDED
#define AUDIO_PEQ_INCLUDED

#include "peq.h"
#ifdef PATCH_LIBS
   #include "patch_library.h"
#endif


// *****************************************************************************
// MODULE:
//    $audio_proc.peq.initialize
//
// DESCRIPTION:
//    Based on the number of stages specified, set the size of PEQ delay buffer
//    and filter coefficient buffer, and clear the PEQ delay buffer.
//
// INPUTS:
//    - r7 = pointer to peq data object, with the below field being set
//       - $audio_proc.peq.NUM_STAGES_FIELD
//       - $audio_proc.peq.DELAYLINE_ADDR_FIELD
//
// OUTPUTS:
//    - none
//
//    - the following fields of data object pointed by r7 being altered:
//       - $audio_proc.peq.DELAYLINE_SIZE_FIELD
//       - $audio_proc.peq.COEFS_SIZE_FIELD
//
//    - delay buffer pointed by $audio_proc.peq.DELAYLINE_ADDR_FIELD is zeroed
//
// TRASHED REGISTERS:
//    r0, r1, r10, I0
//
// NOTES:
// *****************************************************************************


.MODULE $M.audio_proc.peq.initialize;
   .CODESEGMENT   AUDIO_PROC_PEQ_INITIALIZE_PM;
   .DATASEGMENT   DM;

$audio_proc.peq.initialize:
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($audio_proc.PEQ_ASM.INITIALIZE.PATCH_ID_0,r10) // af05_CVC_patches1
#endif

   // Pointer to PEQ parameters
   r8 = M[r7 + $audio_proc.peq.PARAM_PTR_FIELD];
   // number of stages (lower LSBs)
   r0 = M[r8 + $audio_proc.peq.parameter.NUM_STAGES_FIELD];
   r0 = r0 AND $audio_proc.peq.const.NUM_STAGES_MASK;
   M[r7 + $audio_proc.peq.NUM_STAGES_FIELD] = r0;

   // size of delay buffer = (num_stage+1)*2
   r1 = r0 + 1;
   r10 = r1 ASHIFT 1;
   M[r7 + $audio_proc.peq.DELAYLINE_SIZE_FIELD] = r10;

   // Delay buffer appended to end of peq data structure
   r1 = r7 + $audio_proc.peq.STRUC_SIZE;
   M[r7 + $audio_proc.peq.DELAYLINE_ADDR_FIELD]=r1;

   // size of coef buffer = (num_stage) * 5
   r10 = r0 * 5 (int);
   M[r7 + $audio_proc.peq.COEFS_SIZE_FIELD] = r10;

   // Set Pointer to coefficients in parameters
   r0 = r8 + $audio_proc.peq.parameter.STAGES_SCALES;
   M[r7 + $audio_proc.peq.COEFS_ADDR_FIELD] = r0;

   rts;

.ENDMODULE;



.MODULE $M.audio_proc.peq.zero_delay_data;
   .CODESEGMENT   AUDIO_PROC_PEQ_INITIALIZE_PM;
   .DATASEGMENT   DM;

$audio_proc.peq.zero_delay_data:

    push r10;

    // size of delay buffer = (max_num_stages+1)*2
    r10 = M[r7 + $audio_proc.peq.MAX_STAGES_FIELD];
    r10 = r10 + 1;
    r10 = r10 ASHIFT 1;
#ifndef KAL_ARCH2
   // Delay buffer appended to end of peq data structure
    r1 = r7 + $audio_proc.peq.STRUC_SIZE;
#else
    r1 = M[r7 + $audio_proc.peq.DELAYLINE_ADDR_FIELD];
#endif
    // Initialize delay buffer to zero
    I0 = r1;
    r1 = Null;
    do init_dly_ln_loop;
        M[I0, 1] = r1;
    init_dly_ln_loop:

    pop r10;
    rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $audio_proc.peq.process
//
// DESCRIPTION:
//    Implementation of multi-stage cascaded biquad filters:
//
//       y(n) = (  b0/a0 * x(n) + b1/a0 * x(n-1) + b2/a0 * x(n-2)
//               - a1/a0 * y(n-1) - a2/a0 * y(n-2) ) << scalefactor
//
//    Overall output level is adjusted by specified gain factor.
//
// INPUTS:
//    - r7 = pointer to delay data object, all fields should be initialized
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    rMAC, r0-r6, r10, M0-M2, I0-I5, L0, L1, L4, L5, LOOP
//
// NOTES:
//    The coefs buffers and delay line buffer MUST be circular.
//
//    Upon completion of the process, the pointers of input and output buffer
//    are updated. In case the PEQ function needs to be called multiple times
//    within a loop (Ex. 8 samples at a time within a 64 sample block), this
//    saves the framework re-assigning the pointers before calling the PEQ
//    function again. Even if it does, it wouldnt harm anything.
// *****************************************************************************

.MODULE $M.audio_proc.peq.process;
   .CODESEGMENT   AUDIO_PROC_PEQ_PROCESS_PM;
   .DATASEGMENT   DM;

$audio_proc.peq.process:
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($audio_proc.PEQ_ASM.PROCESS.PATCH_ID_0,r1) // af05_CVC_patches1
#endif
   push rLink;
   // Get input buffer
   r0 = M[r7 +  $audio_proc.peq.INPUT_ADDR_FIELD];
#ifdef BASE_REGISTER_MODE
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B4;
#else
   call $frmbuffer.get_buffer;
#endif
   I4 = r0;
   L4 = r1;

   // Set frame size from input
   r4 = r3;
   // Update frame size of output from input
   r0 = M[r7 +  $audio_proc.peq.OUTPUT_ADDR_FIELD];
   call $frmbuffer.set_frame_size;

   // Get output buffer
#ifdef BASE_REGISTER_MODE
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B0;
#else
   call $frmbuffer.get_buffer;
#endif
   I0 = r0;
   L0 = r1;

   pop rLink;

$audio_proc.peq.process_op:
#if defined(PATCH_LIBS)
   LIBS_SLOW_SW_ROM_PATCH_POINT($audio_proc.PEQ_ASM.PROCESS.PATCH_ID_1,r10) // af05_CVC_patches1
#endif
// INPUTS:
//      I4,L4,B4  - Input Buffer
//      I0,L0,B0  - Output Buffer
//      r4        - Number of samples
//      r7        - PEQ data structure

   M1 = 1;
   I3 = r7+$audio_proc.peq.PARAM_PTR_FIELD;
   M0 = -1;

   r10 = Null,      r0 = M[I3,M1];      // I2 = &PARAM_PTR_FIELD[1]
   I2 = r0 + M1,    r0 = M[I3,M1];      // I5,B5 = DELAYLINE_ADDR_FIELD
   // I5 = ptr to delay line,

   push r0;
   pop  B5;

   I5 = r0, r0 = M[I3,M1];              // I1,B1 = COEFS_ADDR_FIELD
   // I1 = ptr to coefs buffer,

   push r0;
   pop  B1;

   I1 = r0, r1 = M[I3,M1];              // M2 = NUM_STAGES_FIELD
   M2 = r1, r1 = M[I3,M1];              // L5 = DELAYLINE_SIZE_FIELD
   L5 = r1, r1 = M[I3,M1];              // L1 = COEFS_SIZE_FIELD
   L1 = r1, r1 = M[I2,M1];              // r1 = GAIN_EXPONENT_FIELD
   r5 = M[I2,M1];                       // r5 = GAIN_MANTISA_FIELD
   // Set Gain. Add 2-bit head room
   r6 = r1 - 2;
   // Set Ptr to scale factors
   r2 = M[r7 + $audio_proc.peq.MAX_STAGES_FIELD];
   r2 = r2 * 5 (int);
   I2 = I2 + r2;                        // Jump over coefficients
   I2 = I2 + M2;                        // end of scale factors (reset to beginnng below)
   // needed for bug in index feed forward, M2 = -num stages
   M2 = Null - M2;

      // this loop excutes for each sample in the block
peq_block_loop:
      // get new input sample
      // number of Biquad stages used, get new input sample
      r10 = r10 - M2, r0 = M[I4,M1];
      // Apply mantisa,Exp to front end gain, get x(n-2), update I2
      rMAC = r0 * r5,      r3 = M[I5,M1], r0 = M[I2,M2];
      // get coef b2
      r0 = rMAC ASHIFT r6, r2 = M[I1,M1];
      do biquad_loop;
         // b2*x(n-2), get x(n-1), get coef b1
         rMAC = r3 * r2, r1 = M[I5,M0], r2 = M[I1,M1];
         // +b1*x(n-1), store new x(n-2), get coef b0
         rMAC = rMAC + r1 * r2, M[I5,M1] = r1, r2 = M[I1,M1];
         // +b0*x(n),store new x(n-1)
         rMAC = rMAC + r0 * r2, M[I5,M1] = r0;
         // get y(n-2), get coef a2
         r1 = M[I5,M1], r2 = M[I1,M1];
         // -a2*y(n-2), get y(n-1), get coef a1
         rMAC = rMAC - r1 * r2, r1 = M[I5,M0], r2 = M[I1,M1];
         // -a1*y(n-1), get x(n-2), get the scalefactor
         rMAC = rMAC - r1 * r2, r3 = M[I5,M1], r2 = M[I2,M1];
         // get y(n)
         r0 = rMAC;         // get coef b2
         r0 = r0 ASHIFT r2, r2 = M[I1,M1];
biquad_loop:
      // update I5
      r3 = M[I5,M0];
      // store new y(n-2), update I1
      M[I5,M1] = r1, r2 = M[I1,M0];
      // Restore Head room
      r3 = r0 ASHIFT 2;
      // Decrement the block counter, store new y(n-1), write back o/p sample
      r4 = r4 - M1, M[I5,M1] = r0,  M[I0,M1] = r3;
   if NZ jump peq_block_loop;

   // clear L-regs
   L0 = Null;
   L4 = Null;
   L1 = Null;
   L5 = Null;

   // clear base registers
   push Null;
   #ifdef BASE_REGISTER_MODE
   B4 = M[SP-1];
   B0 = M[SP-1];
   #endif
   B1 = M[SP-1];
   pop B5;

   rts;

.ENDMODULE;

#endif // AUDIO_PEQ_INCLUDED
