#ifndef AUDIO_PROC_VOLUME_AND_LIMIT_ASM_INCLUDED
#define AUDIO_PROC_VOLUME_AND_LIMIT_ASM_INCLUDED
// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2009-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1552683 $  $DateTime: 2013/03/12 11:12:55 $
// *****************************************************************************
#include "stack.h"
#include "volume_and_limit.h"
#include "math_library.h"
#include "cbuffer.h"

// *****************************************************************************
// MODULE:
//    $volume_and_limit.apply_volume
//
// DESCRIPTION:
//    main function for multi channel volume and limit operation
//
// INPUTS:
//    - r7 = pointer to $volume_and_limit parameters structure,  the format of the
//       structure is as follows:
//
//       - $volume_and_limit.OFFSET_CONTROL_WORD_FIELD and
//       - $volume_and_limit.OFFSET_BYPASS_BIT_FIELD
//           To enable disable the hard limitero nly, There is no means to disable the volume, however
//           0dB can be used for pass-through mode.
//
//      - $volume_and_limit.NROF_CHANNELS_FIELD (setting)
//           Number of channels. Each channel has its own specific setting and state data.
//           The volume and limit structure is a contiguous block of memory consists of one
//           common $volume_and_limit structure followed by N $volume_and_limit.channel
//           structures where N is the number of channels set by this field. common structure
//           includes all setting and state variables that are share for all channels, while
//           channel structures only include channel-specific data.
//
//      - $volume_and_limit.SAMPLE_RATE_FIELD (setting)
//        pointer holding the sample rate of inputs, this is used to calculate attack and release coeffs
//
//      - $volume_and_limit.MASTER_VOLUME_FIELD (setting)
//           Master volume that is applied to all channels, there is a trim volume for each channel too
//           which is set in the channel specific data structure. This field has Q4.19 linear format. For
//           each channel final volume is:
//              volume(ch) = master_volume + trim_volume(ch)
//           this still has the Q4.19 format, so it will be capped at +24.08dB.
//
//      - $volume_and_limit.LIMIT_THRESHOLD_FIELD
//           threshold field for limiter in logarithmic scale, use $volume_and_limit.LIMIT_THRESHOLD(dB)
//           macro to set this field in dB. This filed should always be negative, for a normal operation
//           -1dB is optimum, it will attenuate anything above this threshold based on the limiter ratio
//
//      - $volume_and_limit.LIMIT_THRESHOLD_LINEAR_FIELD
//           threshold field for limiter in linear scale, is needed to avoid computing that in real time
//
//      - $volume_and_limit.LIMIT_RATIO_FIELD_FIELD
//           Ratio field for limiter, when limiter is triggered, it will attenuate the input based on the
//           limiter ratio value:
//              attenuation = (input_level - limit_threshold)(1-1/R),
//           i.e. for R dB increase in the input level it will increase the output by 1dB
//
//      - $volume_and_limit.LIMITER_GAIN_FIELD (internal state)
//           current limiter gain, same limiter gain is applied to all channels simultaneously.
//           The limiter gain never becomes positive. Limiter wont get triggered if all channel
//           volumes (master + channel-specific) are negative
//
//      - $volume_and_limit.LIMITER_GAIN_LINEAR_FIELD (internal state)
//           same as LIMITER_GAIN_FIELD but in linear scale
//
//      - $volume_and_limit.channel
//        N channel structure must follow the main structure (in a single contiguous block),
//        see the header file for meaning of $volume_and_limit.channel structure fields
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//     assume everything
//
// *****************************************************************************
.MODULE $M.audio_proc.volume_and_limit.apply_volume;
   .CODESEGMENT AUDIO_PROC_VOLUME_AND_LIMIT_APPLY_VOLUME_PM;
   .DATASEGMENT DM;

   $volume_and_limit.apply_volume:

   $push_rLink_macro;

   // this function uses r8
   r8 = r7;

   // compute 1024.0/fs, results will be used later
   r0 = M[r8 + $volume_and_limit.SAMPLE_RATE_PTR_FIELD];
   r0 = M[r0];
   rMAC = 512;
   Div = rMAC / r0;

   // -- Get amount of data on input (consumed) and update output (produced)
   // Amount of data may be zero. Assumes all channels available data
   // are equal

   // get number of channels
   r10 = M[r8 + $volume_and_limit.NROF_CHANNELS_FIELD];
   if LE jump $pop_rLink_and_rts;

   // get first channel structure
   r6 = r8 +  $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD;
   r2 = 0x7FFFFF;
   do find_transfer_mnt_loop;

      // input channel
      r0 = M[r6 + $volume_and_limit.channel.INPUT_PTR_FIELD];
      r3  = M[r0 + $frmbuffer.FRAME_SIZE_FIELD];
      Null = r2 - r3;
      if POS r2 = r3;

      // input channel
      r0 = M[r6 + $volume_and_limit.channel.OUTPUT_PTR_FIELD];
      r3  = M[r0 + $frmbuffer.FRAME_SIZE_FIELD];
      Null = r2 - r3;
      if POS r2 = r3;

      // go to next channel
      r6 = r6 + $volume_and_limit.channel.STRUC_SIZE;
   find_transfer_mnt_loop:

   // r4 is the amount to process
   r10 = r2;
   if LE jump $pop_rLink_and_rts;

   // ------------------------------------------------------------------
   // calculate coefficients, we have received n=r2 sample to process
   // There are two coefficients to compute, volume ramp up/down coeff,
   // which only is used if master volume or a trim volume has changed, and
   // limiter attack/release coeff which only is used if limiter is triggered
   //
   // both of these coefficient calculated once per run, this is because
   // we don't want to update limiter/volume gains per sample. Since the
   // amount to process is changeable the coefficients are so too.
   //
   // for volume update maximum volume change is limited like the following:
   //     max_volume_change =  vol_max_change_coeff * current_volume + offset_volume_change
   //     where vol_max_change_coeff = (10^(5*n/fs) - 1 ~= 11.5*(n/fs) where n is
   //     the amount of input sample to process this time, this gives around up to
   //     1dB increase of volume per 10ms.
   //
   // For limiter, normally it has to have a look ahead buffer so it can attack
   // above threshold inputs smoothly, here we don't have look ahead buffers for
   // input channels (we cant afford it) and we want to support variable amount
   // of samples to process each run. The attack and release coeffs for limiter
   // is used when the the peak of all inputs go above or below threshold.
   //    current_gain += (target_gain - current_gain)*attack_coeff/release_coeff
   //    the attack and release coeffs are also dependent on n/fs, we want to have
   //    10ms attack time and 50ms release time.
   //    release_coeff ~= 1 - exp((log(0.01)/0.05/)*n/fs) = 1 - 2^(-132n/fs)
   //    attack_coeff = 1 - exp((log(0.01)/0.01/)*n/fs) = 1 - 2^(-664n/fs)
   // --------------------------------------------------------------------
   
   // save arithmetic mode
   r0 = M[$ARITHMETIC_MODE];
   push r0;

   r0 = DivResult;                   // r0 = 1024.0/fs
   rMAC = r0 * r2;                   // rMAC = n*1024/fs/2.0**23
   rMAC = rMAC ASHIFT (13+3);        // rMAC = (n/fs)*8
   push r10;                         // save r10 in stack, amount to process
   push rMAC;                        // save n/fs in stack, coeff

   // compute volume update coeff: 11.5*n/fs
   rMAC = rMAC ASHIFT -4;
   r5 = rMAC * 23 (int) (sat);

    // set add/sub saturation flag
    r0 = 1;
    M[$ARITHMETIC_MODE] = r0;

    // -- Update Volumes, all volumes are in Q4.19 format --
    r10 = M[r8 + $volume_and_limit.NROF_CHANNELS_FIELD];           // get number of channels
    r6 = r8 +  $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD; // go to first channel structure
    M2 = $volume_and_limit.VOLUME_RAMP_OFFSET_CONST;               // offset for updating
    r3 = M[r8 + $volume_and_limit.MASTER_VOLUME_FIELD];            // get master volume
    r4 = 0;
    do volume_update_loop;
        // r6: channel volume structure
        // r5: volume ramp coeff
        // M2: volume ramp offset
        // r3: master volume

        // channel volume = master volume + trim_volume
        // volumes are in linear Q4.19 format
        r0 = M[r6 + $volume_and_limit.channel.TRIM_VOLUME_FIELD];
        rMAC = r3 * r0;
        rMAC = rMAC ASHIFT 4 (56bit);

        // rMAC = channel volume, smoothly change the volume toward rMAC
        // calculate maximum volume change
        // max_vol_change = vol_change_ratio * current_volume(ch) + offset_volume_change
        r1 = M[r6 + $volume_and_limit.channel.CURRENT_VOLUME_FIELD];
        r0 = rMAC - r1;
        if Z jump next_ch_vol;
        if NEG r0 = -r0;
        r2 = r1 * r5 (frac);
        r2 = r2 + M2;

        // limit the change to target volume
        r2 = MIN r0;
        Null = rMAC - r1;
        if NEG r2 = -r2;

        // new volume = current volume + change
        r1 = r1 + r2;
        // update volume
        M[r6 + $volume_and_limit.channel.CURRENT_VOLUME_FIELD] = r1;
        next_ch_vol:

        // r4 later is used to see whether all volumes are negative
        // note: limiter will not be triggered for negative volumes
        r4 = MAX r1;

        // get next channel structure
        r6 = r6 + $volume_and_limit.channel.STRUC_SIZE;
   volume_update_loop:

   // clear add/sub saturation flag
   M[$ARITHMETIC_MODE] = Null;

   // -- Calculate limiter gain --
   r3 = 0;   // no limiter attn. by default

   // -- see if limiter is enabled by user
   r0 = M[r8 + $volume_and_limit.OFFSET_CONTROL_WORD_FIELD];
   r1 = M[r8 + $volume_and_limit.OFFSET_BYPASS_BIT_FIELD];
   Null = r0 AND r1;
   if NZ jump limiter_analysis_done;

   // -- limiter is relevant only when at least one channel
   // has positive volume
   Null = r4 - $volume_and_limit.MIN_POSITIVE_VOLUME;
   if NEG jump limiter_analysis_done;

   // Analysis loop, it calculates what would be
   //    the biggest output sample if volumes are
   //    applied without limiter (could exceed 0dBFS)
   //
   // for ch in channels:
   //    mx_ch = max(abs(samples[ch])) * volume[ch]
   //    mx = max(mx, mx_ch)
   //
   //
   r6 = r8 +  $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD;
   r0 = M[r8 + $volume_and_limit.NROF_CHANNELS_FIELD];
   M1 = r0;
   r4 = 0;
   M0 = 1;
   limiter_analysis_loop:

      // get the volumes for this channel
      r1 = M[r6 + $volume_and_limit.channel.CURRENT_VOLUME_FIELD];

      // ignore the channel if its volume is negative
      Null = r1 - $volume_and_limit.MIN_POSITIVE_VOLUME;
      if NEG jump get_next_channel;

      // get the amount to analyse
      r10 = M[SP - 2];

      // get input buffer
      r0 = M[r6 + $volume_and_limit.channel.INPUT_PTR_FIELD];
      #ifdef BASE_REGISTER_MODE
         call $frmbuffer.get_buffer_with_start_address;
         push r2;
         pop  B0;
      #else
         call $frmbuffer.get_buffer;
      #endif
      I0  = r0;
      L0  = r1;
      r10 = r10 - 1;

      // find sample with maximum magnitude
      r5 = 0, r2 = M[I0,M0];
      do channel_search_loop;
         r2 = ABS r2;
         r5 = MAX r2, r2 = M[I0,M0];
      channel_search_loop:
      r2 = ABS r2;
      r5 = MAX r2;

      // calculate volume[ch]*max_sample[ch]
      r1 = M[r6 + $volume_and_limit.channel.CURRENT_VOLUME_FIELD];
      r5 = r5 * r1(frac);

      // max output sample among all channels
      r4 = MAX r5;

      get_next_channel:
      // get next channel structure
      r6 = r6 + $volume_and_limit.channel.STRUC_SIZE;
      M1 = M1 - 1;
    if NZ jump limiter_analysis_loop;
    L0 = 0;

   r3 = 0;   // no limiter attn. by default

   // see if peak is above the limiter threshold
   r2 = M[r8 + $volume_and_limit.LIMIT_THRESHOLD_LINEAR_FIELD];
   Null = r4 - r2;
   if NEG jump limiter_analysis_done;

   // compute logarithm of peak
   rMAC = r4;
   call $math.log2_table;

   // compute how much attenuation is needed
   // attn =  (input_level - limit_threshold)(1-1/R)
   r3 = M[r8 + $volume_and_limit.LIMIT_THRESHOLD_FIELD];
   r1 = M[r8 + $volume_and_limit.LIMIT_RATIO_FIELD_FIELD];
   // r0 = input level (log)
   // r3 = limiter threshold (log)
   // r1 = (1-1/R)
   r0 = r3 - r0;
   r3 = r0 * r1 (frac);
   limiter_analysis_done:
   // get n/fs
   r0 = M[SP - 1];
   // calculate release coeff(reaches 99% in 50ms)
   r0 = r0 * (log(0.01)/0.05/log(2.0)/128.0/8.0)(frac);
   call $math.pow2_table;
   r4 = 1.0 - r0;

   // attack coeff, 5 times faster
   r1 = r0 * r0 (frac);
   r1 = r1 * r1 (frac);
   r1 = r0 * r1 (frac);
   r2 = 1.0 - r1;

   // apply release or attack coeff
   r0 = M[r8 + $volume_and_limit.LIMITER_GAIN_FIELD];
   r5 = r3 - r0;
   if POS r2 = r4;
   r5 = r5 * r2 (frac);

   // update limiter gain
   r0 = r0 + r5;
   if POS r0 = 0;
   r2 = r0 - r3;
   if NEG r2 = -r2;
   Null = r2 - 0.00001;
   if NEG r0 = r3;
   M[r8 + $volume_and_limit.LIMITER_GAIN_FIELD] = r0;

   // calculate limiter gain - linear
   call $math.pow2_table;
   r4 = M[r8 + $volume_and_limit.LIMITER_GAIN_LINEAR_FIELD];
   M[r8 + $volume_and_limit.LIMITER_GAIN_LINEAR_FIELD] = r0;
   // r4 holds the limiter previous
  

   // -- Apply volumes

   // get first channel structure and number of channels
   r6 = r8 +  $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD;
   r0 = M[r8 + $volume_and_limit.NROF_CHANNELS_FIELD];
   M1 = r0;

   // set arithmetic mode
   r0 = 1;
   M[$ARITHMETIC_MODE] = r0;

   apply_volume_loop:
      // r6 = channel structure
      // get input buffer for this channel
      r0 = M[r6 + $volume_and_limit.channel.INPUT_PTR_FIELD];
      #ifdef BASE_REGISTER_MODE
         call $frmbuffer.get_buffer_with_start_address;
         push r2;
         pop  B0;
      #else
         call $frmbuffer.get_buffer;
      #endif
      I0  = r0;
      L0  = r1;

      // get output buffer for this channel
      r0 = M[r6 + $volume_and_limit.channel.OUTPUT_PTR_FIELD];
      #ifdef BASE_REGISTER_MODE
         call $frmbuffer.get_buffer_with_start_address;
         push r2;
         pop  B0;
      #else
         call $frmbuffer.get_buffer;
      #endif
      I4  = r0;
      L4  = r1;

      // get the volume for this channel
      r1 = M[r6 + $volume_and_limit.channel.CURRENT_VOLUME_FIELD];

      // get limiter attenuation gain
      r0 = M[r8 + $volume_and_limit.LIMITER_GAIN_LINEAR_FIELD];

      // calculate init and final volume for this frame
      r2 = r1 * r0 (frac);
      r1 = M[r6 + $volume_and_limit.channel.LAST_VOLUME_APPLIED_FIELD];
      r2 = r2 - r1;      

      // r1 = initial gain to apply on this frame/channel
      // r2 = (final gain - initial gain) for this frame/channel

      // linear ramp within one frame
      rMAC = r2 ASHIFT 0 (LO);
      // get amount to process
      r10 = M[SP - 2];
      Div = rMAC / r10;
      r10 = r10 - 1;

      // shift amount to compensate volume Q4.19 format
      r3 = 4;
      // calculate sample ramp
      r5 = DivResult;
      // next volume
      r1 = r1 + r5, r2 = M[I0,1];
      // apply volume
      rMAC = r2 * r1;
      do volume_loop;
         // shift for Q4.19 volume format
         rMAC = rMAC ASHIFT r3 (56bit), r2 =   M[I0,1];

         // apply volume
         r1 = r1 + r5;
         rMAC = r2 * r1, M[I4,1] = rMAC;
      volume_loop:
      // shift for Q4.19 volume format
      rMAC = rMAC ASHIFT r3 (56bit);
      M[I4,1] = rMAC;
      M[r6 + $volume_and_limit.channel.LAST_VOLUME_APPLIED_FIELD] = r1;

      // get next channel structure
      r6 = r6 + $volume_and_limit.channel.STRUC_SIZE;
      M1 = M1 - 1;
   if NZ jump apply_volume_loop;
   L0 = 0;
   L4 = 0;

   // restore stack pointer
   pop r0;
   pop r0;

   // restore add/sub saturation flag
   pop r0;
   M[$ARITHMETIC_MODE] = r0;

#ifdef BASE_REGISTER_MODE
   push NULL;
   B0 = M[SP-1];
   pop B4;
#endif

   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $volume_and_limit.reset
//
// DESCRIPTION:
//
//
// INPUTS:
//    - r7 = volume and limit data object
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//
//
// *****************************************************************************

.MODULE $M.audio_proc.volume_and_limit.reset;

   .CODESEGMENT AUDIO_PROC_VOLUME_AND_LIMIT_RESET_PM;

   $volume_and_limit.reset:
   $volume_and_limit.initialize:

    // -- Update Volumes, all volumes are in Q4.19 format --
    // get first channel, it is expected to be valid
    r10 = M[r7 + $volume_and_limit.NROF_CHANNELS_FIELD];
    r6 = r7 +  $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD;
    r3 = M[r7 + $volume_and_limit.MASTER_VOLUME_FIELD];

    do volume_reset_loop;

        // channel volume = master volume + trim_volume
        // there will be no ramp up/down at the beginning
        r0 = M[r6 + $volume_and_limit.channel.TRIM_VOLUME_FIELD];
        rMAC = r3 * r0;
        rMAC = rMAC ASHIFT 4 (56bit);

        M[r6 + $volume_and_limit.channel.CURRENT_VOLUME_FIELD] = rMAC;
        M[r6 + $volume_and_limit.channel.LAST_VOLUME_APPLIED_FIELD] = rMAC;

        // get next channel structure
        r6 = r6 + $volume_and_limit.channel.STRUC_SIZE;
   volume_reset_loop:

   // also reset the limiter gain
   M[r7 + $volume_and_limit.LIMITER_GAIN_FIELD] = 0;

   rts;
.ENDMODULE;
#endif // #ifndef AUDIO_PROC_VOLUME_AND_LIMIT_ASM_INCLUDED
