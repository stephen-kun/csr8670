//------------------------------------------------------------------------------
// Copyright (C) Cambridge Silicon Radio Ltd 2012             http://www.csr.com
// Part of ADK 3.5
//
// $Revision:$
// $Date:$
//------------------------------------------------------------------------------
// NAME:
//   bass_management
//------------------------------------------------------------------------------
// DESCRIPTION:
//   Apply bass management to audio.
//   Potential input scenarios
//   -  Left and right audio
//   -  Left and right audio with LFE
//   Potential output scenarios
//   -  Left and right speakers
//   -  Left and right speakers with subwoofer
//------------------------------------------------------------------------------
// The following data structure is used:
//   - $bass_management.LEFT_INPUT_PTR = pointer to left input channel buffer
//   - $bass_management.RIGHT_INPUT_PTR = pointer to right input channel buffer
//   - $bass_management.LEFT_OUTPUT_PTR = pointer to left output channel buffer
//   - $bass_management.RIGHT_OUTPUT_PTR = pointer to rightt output channel buffer
//   - $bass_management.LFE_INPUT_PTR = pointer to LFE input channel buffer (0 if not present)
//   - $bass_management.SUB_OUTPUT_PTR = pointer to sub output channel buffer (0 if not present)
//   - $bass_management.BASS_BUFFER_PTR = pointer to internal bass channel buffer
//   - $bass_management.BASS_BUFFER_SIZE = internal bass channel buffer size
//   - $bass_management.COEFS_PTR = pointer to coefficients
//   - $bass_management.DATA_MEM_PTR = pointer to filter data memory
//   - $bass_management.BYPASS_WORD_PTR = pointer to bypass control word
//   - $bass_management.BYPASS_BIT_MASK_FIELD = mask for processing bypass control
//------------------------------------------------------------------------------
// coefficients
//   - $bass_management.COEF.CONFIG = enable flags for filters etc.
//   - $bass_management.COEF.A1 = left/right mix to bass channel gain value
//   - $bass_management.COEF.A2 = left/right headroom gain value
//   - $bass_management.COEF.A3 = lfe mix to bass channel gain value
//   - $bass_management.COEF.A4 = bass channel mix to left/right output gain value
//   - $bass_management.COEF.A5 = sub output headroom gain value
//   - $bass_management.COEF.FREQ = crossover frequency control
//------------------------------------------------------------------------------



#include "cbuffer.h"
#include "stack.h"

#include "bass_management.h"

//------------------------------------------------------------------------------
.module $M.bass_management;
//------------------------------------------------------------------------------
// apply bass management to audio
//------------------------------------------------------------------------------
// INPUTS:
//   - r7 = pointer to procesing structure
//   - r8 = pointer to sub cbuffer to zero sub output buffer
//------------------------------------------------------------------------------
// OUTPUTS:
//   none
//------------------------------------------------------------------------------
// TRASHED REGISTERS:
//   Lots
//------------------------------------------------------------------------------

    .codesegment AUDIO_PROC_BASS_MANAGEMENT_PM;
    .datasegment DM;

$bass_management.initialize:
   
   #define FREQ_SCALE_32000     0.2010619298;
   #define FREQ_SCALE_44100     0.1458952779;
   #define FREQ_SCALE_48000     0.1340412866;
    
   // r8 points to cbuffer structure of sub output
   r8 = r8 - null;
   if z jump no_output_buffer_to_zero;
      r0 = m[r8+$cbuffer.READ_ADDR_FIELD];
      i0 = r0;
      r10 = m[r8+$cbuffer.SIZE_FIELD];
      l0  = r10;
      r0 = 0;
      do clear_buffer;
         m[i0,1] = r0;
      clear_buffer:
   no_output_buffer_to_zero:

   r8 = m[r7 + $bass_management.COEFS_PTR];
    
   r2 = FREQ_SCALE_48000;              // default to 48 kHz sampling rate
    
   r0 = m[r7 + $bass_management.CODEC_RATE_PTR];
   r0 = m[r0];
    
   r1 = FREQ_SCALE_32000;
   null = r0 - 32000;
   if z r2 = r1;
   r1 = FREQ_SCALE_44100;
   null = r0 - 44100;
   if z r2 = r1;

   r4 = m[r8 + $bass_management.COEF_FREQ_PARAM];
   r4 = r4 ashift 13;
   rmac = r4 * r2;
    
   m[r8 + $bass_management.COEF_FREQ] = rmac;

   // Revert to linear buffering
   l0 = 0;

   rts;


$bass_management.zero_data:

    // r7 = pointer to procesing structure
    r8 = m[r7 + $bass_management.COEFS_PTR];
    r0 = m[r8 + $bass_management.COEF_NUM_LF_STAGES];
    r1 = m[r8 + $bass_management.COEF_NUM_HF_STAGES];
    r1 = r1 + r1;       // two channels of HF filtering
    r0 = r0 + r1;
    r10 = r0 + r0;      // two delay elements per filter
    
    r0 = m[r7 + $bass_management.DATA_MEM_PTR];
    i0 = r0;
    l0 = 0;
    r0 = 0;
    do clear_data_memory;
        m[i0,1] = r0;
    clear_data_memory:

    rts;
    

$bass_management:

    .var frequency_coef;

    // push rLink onto stack
    $push_rLink_macro;
    
    // check if processing is bypassed
    r0 = m[r7 + $bass_management.BYPASS_WORD_PTR];
    r0 = m[r0];
    r1 = M[r7 + $bass_management.BYPASS_BIT_MASK_FIELD];
    null = r0 and r1;
    if nz jump bypass;

    // if we have an LFE channel
    //   Bass = a1*L + a1*R + a3*LFE
    // otherwise
    //   Bass = a1*L + a1*R
    //--------------------------------------------------------------------------
    
    // if we have an LFE, copy it to bass buffer otherwise clear bass buffer
    
    r8  = m[r7 + $bass_management.COEFS_PTR];
    
    // get frame size from input
    r0 = m[r7 + $bass_management.LEFT_INPUT_PTR];    
    call get_ptrs;
    r10 = r3;
    // get pointer to bass buffer
    r0 = m[r7 + $bass_management.BASS_BUFFER_PTR];
    i2 = r0;
    // check for LFE buffer
    r0 = m[r7 + $bass_management.LFE_INPUT_PTR];
    if Z jump clearBassBuffer;
        call get_ptrs;
        i0 = r0;
        l0 = r1;
        do inputLFEcopyLoop;
            r0 = m[i0,1];
            m[i2,1] = r0;
        inputLFEcopyLoop:
        jump bassChannelReadyForMixingLR;

    clearBassBuffer:
        r0 = 0;
        do clearBassBufferLoop;
            m[i2,1] = r0;
        clearBassBufferLoop:
    
    bassChannelReadyForMixingLR:
    
    // mix left and right channels into bass buffer

    r0 = m[r7 + $bass_management.LEFT_INPUT_PTR];    
    call get_ptrs;
    i0 = r0;
    l0 = r1;
    r10 = r3;
    r0 = m[r7 + $bass_management.RIGHT_INPUT_PTR];
    call get_ptrs;
    i4 = r0;
    l4 = r1;
    r0 = m[r7 + $bass_management.BASS_BUFFER_PTR];
    i2 = r0;

    r4 = m[r8 + $bass_management.COEF_A1];
    r5 = m[r8 + $bass_management.COEF_A3];

    do mixToBassBufferLoop;
        r1 = m[i0,1],           r2 = m[i4,1];               // r1 = left, r2 = right
        rmac = rmac - rmac,     r0 = m[i2,0];               // r0 = bass buffer
        rmac = rmac + r0 * r5;
        rmac = rmac + r1 * r4;
        rmac = rmac + r2 * r4;
        r0 = rmac ashift 2;
        m[i2,1] = r0;
    mixToBassBufferLoop:
    
    // copy left and right inputs to outputs
    //--------------------------------------------------------------------------

    call copyLRinToLRout;
    

    // apply filters as needed
    //--------------------------------------------------------------------------
    
    // left and right channel
    
    r0 = m[r8 + $bass_management.COEF_CONFIG];
    null = r0 and $bass_management.COEF_CONFIG.ENABLE_HPF;
    if z jump dontFilterLeftRight;
    
        // filter left channel
        r0 = m[r7 + $bass_management.LEFT_OUTPUT_PTR];
        call get_ptrs;
        
        r4 = m[r7 + $bass_management.DATA_MEM_PTR];
        i4 = r4;
        l4 = 0;
        
        r4 = m[r8 + $bass_management.COEF_FREQ];
        
        r6 = r8 + $bass_management.COEF_STRUCT_BASE_SIZE;
        i2 = r6;
        r6 = m[r8 + $bass_management.COEF_NUM_HF_STAGES];
        leftHPFloop:
            r5 = m[i2,1];
            call HighPassFilter;
            r6 = r6 - 1;
        if nz jump leftHPFloop;
        
        // filter right channel
        r0 = m[r7 + $bass_management.RIGHT_OUTPUT_PTR];
        call get_ptrs;
        
        // don't need to set r4 as right channel data follows left channel
        
        r6 = r8 + $bass_management.COEF_STRUCT_BASE_SIZE;
        i2 = r6;
        r6 = m[r8 + $bass_management.COEF_NUM_HF_STAGES];
        rightHPFloop:
            r5 = m[i2,1];
            call HighPassFilter;
            r6 = r6 - 1;
        if nz jump rightHPFloop;
        
    dontFilterLeftRight:
    
    // sub channel
    
    r0 = m[r8 + $bass_management.COEF_CONFIG];
    null = r0 and $bass_management.COEF_CONFIG.ENABLE_LPF;
    if z jump dontFilterBassChannel;
    
        // get frame size from input
        r0 = m[r7 + $bass_management.LEFT_INPUT_PTR];
        call get_ptrs;

        // filter bass channel
        r0 = m[r7 + $bass_management.BASS_BUFFER_PTR];
        r1 = 0;

        r4 = m[r7 + $bass_management.DATA_MEM_PTR];
        r5 = m[r8 + $bass_management.COEF_NUM_HF_STAGES];
        r5 = r5 * 4 (int);
        r4 = r4 + r5;
        i4 = r4;
        l4 = 0;
        
        r4 = m[r8 + $bass_management.COEF_FREQ];
        
        r6 = r8 + $bass_management.COEF_STRUCT_BASE_SIZE;
        r5 = m[r8 + $bass_management.COEF_NUM_HF_STAGES];
        r6 = r5 + r6;
        i2 = r6;
        r6 = m[r8 + $bass_management.COEF_NUM_LF_STAGES];
        
        subLPFloop:
            r5 = m[i2,1];
            call LowPassFilter;
            r6 = r6 - 1;
        if nz jump subLPFloop;
        
    dontFilterBassChannel:
    
    // mix bass in to left and right outputs
    //--------------------------------------------------------------------------

    r0 = m[r7 + $bass_management.LEFT_OUTPUT_PTR];    
    call get_ptrs;
    i0 = r0;
    l0 = r1;
    r10 = r3;
    r0 = m[r7 + $bass_management.RIGHT_OUTPUT_PTR];
    call get_ptrs;
    i4 = r0;
    l4 = r1;
    r0 = m[r7 + $bass_management.BASS_BUFFER_PTR];
    i2 = r0;


    r4 = m[r8 + $bass_management.COEF_A2];
    r5 = m[r8 + $bass_management.COEF_A4];

    do mixBassBufferToLeftRightLoop;
        r2 = m[i2,1];       // bass
        
        rmac = rmac - rmac,     r0 = m[i0,0];       // left
        rmac = rmac + r0 * r4;
        rmac = rmac + r2 * r5;
        r0 = rmac ashift 2;
        
        rmac = rmac - rmac,     r1 = m[i4,0];
        rmac = rmac + r1 * r4;
        rmac = rmac + r2 * r5;
        r1 = rmac ashift 2;
        m[i0,1] = r0,       m[i4,1] = r1;
    mixBassBufferToLeftRightLoop:
    

    // if we have a sub channel, copy the bass to it while applying gain A5
    //--------------------------------------------------------------------------
    
    r0 = m[r7 + $bass_management.BASS_BUFFER_PTR];
    i2 = r0;
    r0 = m[r7 + $bass_management.SUB_OUTPUT_PTR];
    call get_ptrs;
    i1 = r0;
    l1 = r1;

    null = i1;
    if z jump dontCopyBassToSub;
        // get frame size from input
        r0 = m[r7 + $bass_management.LEFT_INPUT_PTR];
        call get_ptrs;
        r10 = r3;    
        r5 = m[r8 + $bass_management.COEF_A5];
        do outputSUBcopyLoop;
            rmac = rmac - rmac,         r0 = m[i2,1];
            rmac = rmac + r0 * r5;
            r0 = rmac ashift 2;
            m[i1,1] = r0;
        outputSUBcopyLoop:

    dontCopyBassToSub:
    
    exit:

    // zero length registers
    l0 = 0;
    l1 = 0;
    l4 = 0;
    l5 = 0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;


//------------------------------------------------------------------------------
HighPassFilter:
//------------------------------------------------------------------------------
// on entry
//   r0 = address of audio buffer
//   r1 = length of audio buffer
//   r3 = samples to process
//   r4 = fc
//   r5 = q
//   i4 = address of delay data memory
//------------------------------------------------------------------------------

        pushm <r0,r1,r3,r10>;

    i0 = r0;
    l0 = r1;
    r10 = r3;
    
    // calculate scaling factor required to achieve unity gain in passband
    // - this is necessary because digital state variable filter HPF output has
    //   gain.  Gain correction [1-(wd^2)/4-(wd*qd)/2] is applied to audio input
    
    rmac = r4 * r4;
    r1 = rmac;                  // wd^2
    r3 = 0.25;
    rmac = 0x7fffff;
    rmac = rmac - r1 * r3;      // 1 - (wd^2)/4
    rmac = rmac - r4 * r5;      // 1 - (wd^2)/4 - (wd*qd)/2
    r3 = rmac;                  // r3 = gain to apply to input
    
    // state variable filter
    
    r1 = m[i4,1];       // r1 = D1 (BP)
    r2 = m[i4,-1];      // r2 = D2 (LP)
    do highPassFilterLoop;
        rmac = r2;                                  // rmac = D2
        rmac = rmac + r1 * r4,      r0 = m[i0,0];   // rmac = D2 + f * D1,      r0 = input
        r2 = rmac ;                                 // r2 = LP

        rmac = r0*r3;                               // rmac = scaled input
        rmac = rmac + r2 * 0x800000;                // rmac = I - L
        rmac = rmac - r1 * r5;                      // rmac = I - L - Q * D1 / 2                  
        rmac = rmac - r1 * r5;                      // rmac = I - L - Q * D1
        r0 = rmac;                                  // r0 = HP
        
        rmac = r1 ;                                 // rmac = D1
        rmac = rmac + r0 * r4,      m[i0,1] = r0;   // rmac = D1 + f * HP,      output = HP
        r1 = rmac;                                  // r1 = BP
    highPassFilterLoop:
    m[i4,1] = r1;       // D1 = r1 (BP)
    m[i4,1] = r2;       // D2 = r2 (LP)

        popm <r0,r1,r3,r10>;

    rts;


//------------------------------------------------------------------------------
LowPassFilter:
//------------------------------------------------------------------------------
// on entry
//   r0 = address of audio buffer
//   r1 = length of audio buffer
//   r3 = samples to process
//   r4 = fc
//   r5 = q
//   i4 = address of delay data memory
//------------------------------------------------------------------------------

        pushm <r0,r1,r3,r10>;
    
    i0 = r0;
    l0 = r1;
    r10 = r3;

    r1 = m[i4,1];       // r1 = D1 (BP)
    r2 = m[i4,-1];      // r2 = D2 (LP)
    do lowPassFilterLoop;
        rmac = r2;                                  // rmac = D2
        rmac = rmac + r1 * r4;                      // rmac = D2 + f * D1 
        r2 = rmac ;                                 // r2 = LP

        rmac = m[i0,0];                             // rmac = input
        rmac = rmac + r2 * 0x800000;                // rmac = I - L
        rmac = rmac - r1 * r5;                      // rmac = I - L - Q * D1 / 2                  
        rmac = rmac - r1 * r5;                      // rmac = I - L - Q * D1
        r0 = rmac;                                  // r0 = HP
        
        rmac = r1 ;                                 // rmac = D1
        rmac = rmac + r0 * r4,      m[i0,1] = r2;   // rmac = D1 + f * HP,      output = LP
        r1 = rmac;                                  // r1 = BP
    lowPassFilterLoop:
    m[i4,1] = r1;       // D1 = r1 (BP)
    m[i4,1] = r2;       // D2 = r2 (LP)

        popm <r0,r1,r3,r10>;

    rts;
    

copyLRinToLRout:
    // push rLink onto stack
    $push_rLink_macro;
    
    r0 = m[r7 + $bass_management.LEFT_INPUT_PTR];    
    call get_ptrs;
    i0 = r0;
    l0 = r1;
    r10 = r3;
    r0 = m[r7 + $bass_management.RIGHT_INPUT_PTR];
    call get_ptrs;
    i4 = r0;
    l4 = r1;
    r0 = m[r7 + $bass_management.LEFT_OUTPUT_PTR];    
    r3 = r10;
    call $frmbuffer.set_frame_size;
    call get_ptrs;
    i1 = r0;
    l1 = r1;
    r0 = m[r7 + $bass_management.RIGHT_OUTPUT_PTR];
    r3 = r10;
    call $frmbuffer.set_frame_size;
    call get_ptrs;
    i5 = r0;
    l5 = r1;
    
    // set sub output frame size
    r0 = m[r7 + $bass_management.SUB_OUTPUT_PTR];
    r3 = r10;
    call $frmbuffer.set_frame_size;

    do copyLRinToLRoutLoop;
        r0 = m[i0,1],       r1 = m[i4,1];
        m[i1,1] = r0,       m[i5,1] = r1;
    copyLRinToLRoutLoop:
    
   jump $pop_rLink_and_rts;    


bypass:

    // copy left and right inputs to outputs
    call copyLRinToLRout;
    
    // if we have a sub output, fill it with zeros or copy LFE to it
    //--------------------------------------------------------------------------
    
    // check whether we have a sub output to fill
    r0 = m[r7 + $bass_management.SUB_OUTPUT_PTR];
    if z jump bypassNoSubOutput;
    call get_ptrs;
    r10 = r3;
    i1 = r0;
    l1 = r1;
    
    // if we have an LFE input, copy it to the sub, otherwise fill sub with zero
    r0 = m[r7 + $bass_management.LFE_INPUT_PTR];
    if Z jump bypassClearSubOutput;
        call get_ptrs;
        i0 = r0;
        l0 = r1;
        do bypassLFEcopyLoop;
            r0 = m[i0,1];
            m[i1,1] = r0;
        bypassLFEcopyLoop:
        jump bypassNoSubOutput;
        
    bypassClearSubOutput:
        r0 = 0;
        do bypassClearSubOutputLoop;
            m[i1,1] = r0;
        bypassClearSubOutputLoop:

    bypassNoSubOutput:
    
    // zero length registers
    l0 = 0;
    l1 = 0;
    l4 = 0;
    l5 = 0;
    
    // pop rLink from stack
    jump $pop_rLink_and_rts;


get_ptrs:
// INPUTS:
//    - r0 = pointer to frame buffer structure
//
// OUTPUTS:
//    - r0 = buffer address
//    - r1 = buffer size
//    - r2 = buffer start address   <base address variant>
//    - r3 = frame size
    $push_rLink_macro;
#ifdef BASE_REGISTER_MODE  
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B0;
#else
   call $frmbuffer.get_buffer;
#endif

   jump $pop_rLink_and_rts;

.endmodule;
