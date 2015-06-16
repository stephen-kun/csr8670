// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************
// *****************************************************************************
// NAME:
//    copy operator
//
// DESCRIPTION:
//    This operator does resampling and mixing when tone data are
//    available in the input cbuffer.
//
// When using the operator the following data structure is used:
//
//       $cbops.auto_resample_mix.IO_LEFT_INDEX_FIELD
//          -left audio channel index
//       $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD
//          -right audio channel index
//       $cbops.auto_resample_mix.TONE_CBUFFER_FIELD
//          -pointer to cbuffer structure containing the tone data
//       $cbops.auto_resample_mix.COEF_BUF_INDEX_FIELD
//          -coefficients to be used for resampling, for efficiency it shall
//          be defined in DM2
//       $cbops.auto_resample_mix.OUTPUT_RATE_ADDR_FIELD
//          -address containing output(main audio) rate
//       $cbops.auto_resample_mix.HIST_BUF_FIELD
//          -address holding filter history data,
//          - must be circular, (even for base register build)
//          size $cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH
//          and for efficiency defined in DM1 memory
//       $cbops.auto_resample_mix.INPUT_RATE_ADDR_FIELD
//          -address containing input(signal) rate
//       $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD
//          -tone ratio when mixing
//       $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD
//          - audio ratio when mixing
//       $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD
//          - (internal state) fractional part of fin/fo
//       $cbops.auto_resample_mix.CURRENT_OUTPUT_RATE_FIELD
//          - (internal state) last used output rate
//       $cbops.auto_resample_mix.CURRENT_INPUT_RATE_FIELD
//          - (internal state) last used input rate
//       $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD
//          - (internal state) int part of fin/fo
//       $cbops.auto_resample_mix.IR_RATIO_FIELD
//          - (internal state) used to hold last interpolation ratio
//       $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD
//          - (internal state)
//       $cbops.auto_resample_mix.INPUT_STATE_FIELD
//          - (internal state) whether tone is seen in input or not
//       $cbops.auto_resample_mix.INPUT_COUNTER_FIELD
//          - (internal state) counts consecutive times that tone is seen in
//            input buffer.
//       $cbops.auto_resample_mix.OPERATION_MODE_FIELD
//          - (internal state) action that is performed, normally resampling and
//            mix, but if fs == fin it would be just resampling
// *****************************************************************************
#include "stack.h"
#include "cbops.h"

.MODULE $M.cbops.auto_upsample_and_mix;
    .DATASEGMENT DM;

    // ** function vector **
    .VAR $cbops.auto_upsample_and_mix[$cbops.function_vector.STRUC_SIZE] =
        $cbops.function_vector.NO_FUNCTION,         // reset function
        $cbops.function_vector.NO_FUNCTION,         // amount to use function
        &$cbops.auto_upsample_and_mix.main;            // main function

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $$cbops.auto_upsample_and_mix.main
//
// DESCRIPTION:
//    Operator that upsamples the tone and mixes it to both left and right channel
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
//    everything
//
// *****************************************************************************
.MODULE $M.cbops.auto_upsample_and_mix.main;
   .CODESEGMENT CBOPS_AUTO_UPSAMPLE_AND_MIX_MAIN_PM;
   .DATASEGMENT DM;

   $cbops.auto_upsample_and_mix.main:

   // push rLink onto stack
   $push_rLink_macro;

   // default output rate
   r3 = 48000;

   // default input rate
   r4 = 8000;

   // get input sample rate
   r1 = M[r8 + $cbops.auto_resample_mix.INPUT_RATE_ADDR_FIELD];
   if NZ r1 = M[r1];
   if Z r1 = r4;

   // get output sample rate
   r2 = M[r8 + $cbops.auto_resample_mix.OUTPUT_RATE_ADDR_FIELD];
   if NZ r2 = M[r2];
   if Z r2 = r3;

   // new setup if input rate has changed
   r0 = M[r8 + $cbops.auto_resample_mix.CURRENT_INPUT_RATE_FIELD];
   Null = r0 - r1;
   if NZ jump do_set_up;

   // new setup if output rate has changed
   r0 = M[r8 + $cbops.auto_resample_mix.CURRENT_OUTPUT_RATE_FIELD];
   Null = r0 - r2;
   if Z jump set_up_done;
   // setting up the ratios
   do_set_up:
      // store last setup input/output rates
      M[r8 + $cbops.auto_resample_mix.CURRENT_INPUT_RATE_FIELD] = r1;
      M[r8 + $cbops.auto_resample_mix.CURRENT_OUTPUT_RATE_FIELD] = r2;
      M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD] = 0;
      r0 = 1.0;
      M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD] = r0;

      // ignore tone if fout < 0.9fout
      r4 = $cbops.auto_resample_mix.TONE_MIXING_IGNORE_ACTION;
      r0 = r1 * 0.9(frac);
      Null = r2 - r0;
      if NEG jump set_opmode;

      // no resampling if fin == fout
      r4 = $cbops.auto_resample_mix.TONE_MIXING_JUSTMIX_ACTION;
      r3 = 1;
      Null = r1 - r2;
      if Z jump set_opmode;
      // set in rati, if fin > fout --> downsamling
      if NEG r3 = 0;
      if GT  r1 = r1 - r2;
      M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD] = r3;

      // calculate frac ratio
      rMAC = r1;
      r1 = r2 ASHIFT 1;
      Div = rMAC / r1;
      r0 = DivResult;
      // rounding
      r1 = DivRemainder;
      r3 = 1;
      Null = r1 - r2;
      if POS r0 = r0 + r3;
      M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD] = r0;

      // resample operation
      r4 = $cbops.auto_resample_mix.TONE_MIXING_RESAMPLE_ACTION;

      // set the operation mode
      set_opmode:
      M[r8 + $cbops.auto_resample_mix.OPERATION_MODE_FIELD] = r4;

   set_up_done:

   //calc available value
   r0 = M[r8 + $cbops.auto_resample_mix.TONE_CBUFFER_FIELD];
   call $cbuffer.calc_amount_data;

   //calc expected value
   r1 = M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD];
   r3 = M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD];
   r3 = r3 * r10 (int);
   r1 = r1 * r10 (frac);
   // r1 amount_tone_available
   r1 = r1 + 1;
   r1 = r1 + r3;

   r2 = M[r8 + $cbops.auto_resample_mix.INPUT_COUNTER_FIELD];
   r2 = r2 + 1;
   r4 = M[r8 + $cbops.auto_resample_mix.INPUT_STATE_FIELD];
   // r0 = amount of tone available
   // r1 = amount of tone needed
   // r4 = current input state
   // r2 = current input counter
   if Z jump no_tone;
      Null = r0;
      if NZ r2 = 0;
      jump set_new_state;
   no_tone:
      Null = r0 - r1;
      if NEG r2 = 0;
   set_new_state:
   r0 = r4;
   r3 = 1;
   Null = r2 - 3;
   if POS r4 = r4 XOR r3;

   r1 = 1.0;
   r3 = M[r8 + $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD];
   Null = r4 - r0;
   if NZ r3 = r1;

   M[r8 + $cbops.auto_resample_mix.INPUT_COUNTER_FIELD] = r2;
   M[r8 + $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD] = r3;
   M[r8 + $cbops.auto_resample_mix.INPUT_STATE_FIELD] = r4;

   // see if we need to do any operation
   Null = r4 OR r3;
   if Z jump $pop_rLink_and_rts;

   // get the Cbuffer holding tone data
   r0 = M[r8 + $cbops.auto_resample_mix.TONE_CBUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif

   // store address to read tone data
   // an increment will be added later then assign the sum to I4
   I0 = r0;
   // store the length value in L1
   L0 = r1;

   // get the hist buf info
   L1 = $cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH;
   r0 = M[r8 + $cbops.auto_resample_mix.HIST_BUF_FIELD];
   I1 = r0;

   // get the offset to the left buffer to use
   r0 = M[r8 + $cbops.auto_resample_mix.IO_LEFT_INDEX_FIELD];
   // get the output buffer write address
   r1 = M[r6 + r0];
   // store the value in I0
   I4 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L0
   L4 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B4;
   #endif

   // mix to dummy address if no second channel is defined
   .VAR right_temp;
   I5 = &right_temp;
   L5 = 1;
   // get the offset to the right buffer to use
   r0 = M[r8 + $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD];
   if NEG jump no_right_cahnnel;

   // get the output buffer write address for right channel
   r1 = M[r6 + r0];
   // store the value in I5
   I5 = r1;
   // get the output buffer length
   r1 = M[r7 + r0];
   // store the value in L5
   L5 = r1;
   #ifdef BASE_REGISTER_MODE
      // get the start address
      r1 = M[r5 + r0];
      push r1;
      pop B5;
   #endif
   no_right_cahnnel:

   r4 = M[r8 + $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD];
   r3 = 1.0;
   r2 = M[r8 + $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD];
   if Z jump do_resample_mix;
   Null = M[r8 + $cbops.auto_resample_mix.INPUT_STATE_FIELD];
   if NZ jump do_soft_move;
   r4 = 1.0;
   r3 = M[r8 + $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD];
   do_soft_move:
   // r3 = start gain
   // r4 = end gain
   // r2 = current soft move gain
   // r10 = number of samples
   r3 = r3 - r4;
   r6 = 1.0;
   // min 1ms ramping time for 48khz output
   r5 = 1.0/48.0;
   do  soft_move_loop;
      rMAC = r2 * r3, r0 = M[I4, 0];
      rMAC = rMAC + r4*r6;
      r0 = r0 * rMAC (frac), r1 = M[I5, 0];
      r1 = r1 * rMAC (frac), M[I4, 1] = r0;
      r2 = r2 - r5, M[I5, 1] = r1;
      if NEG r2 = 0;
   soft_move_loop:
   M[r8 + $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD] = r2;
   jump $pop_rLink_and_rts;
   end_soft_move:
   r2 = 0;
   M[r8 + $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD] = r2;
   jump $pop_rLink_and_rts;

   do_resample_mix:
   // check if the operation mode requires resampling
   r0 = M[r8 + $cbops.auto_resample_mix.OPERATION_MODE_FIELD];
   Null = r0 - $cbops.auto_resample_mix.TONE_MIXING_RESAMPLE_ACTION;
   if Z jump resampling_op;

   // or just mixing for when fi = fout
   Null = r0 - $cbops.auto_resample_mix.TONE_MIXING_JUSTMIX_ACTION;
   if Z jump justmix_op;

   // else ignore the tone
   ignore_op:
   r7 = r10;
   jump op_done;

   justmix_op:
   r4 = M[r8 + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD];
   r5 = M[r8 + $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD];
   r7 = r10;
   r2 = 0, r0 = M[I0, 0];
   r6 = 1.0;
   do  just_mix_loop;
       //compute tone proportion, (saturate and round)
       r0 = r0*r4(frac), r3 = M[I4, 0], M[I1, 1] = r0; //r0: tone proportion
       //mix
       rMAC = r5*r3, r1 = M[I5,0];    // rMAC = left proportion
       rMAC = rMAC + r0*r6, M[I0, 1] = r2;                           // rMAC = left+tone
       rMAC = r5*r1, M[I4, 1] = rMAC;                  //save left, rMAC = right proportion
       rMAC = rMAC + r0*r6, r0 = M[I0, 0];            // rMAC = right+tone
       // save final computed sample
        M[I5, 1] = rMAC;
   just_mix_loop:

   jump op_done;

   resampling_op:
   // get the index to coefficient buffer
   r5 = M[r8 + $cbops.auto_resample_mix.COEF_BUF_INDEX_FIELD];

   // store in I3, an increment will be added later, then
   // assign the sum to I2;
   I3 = r5 + (($cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH*$cbops.auto_resample_mix.TONE_FILTER_UPRATE)/2);

   // get the sampling conversion ratio, Ratio_in/Ratio_out
   // it is the integral fraction of Freq_in/Freq_out
   // for upsampling, it is a fraction.
   r5 = M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD];

   // load the sample counter
   r4 = M[r8 + $cbops.auto_resample_mix.IR_RATIO_FIELD];
   M3 = 1;
   r6 = $cbops.auto_resample_mix.TONE_FILTER_UPRATE;
   M2 = -r6;
   M0 = r6;
   r7 = 0;

   // downsampling or upsampling
   Null = M[r8 + $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD];
   if Z jump upsampling;

   downsampling:
   do  fractinal_gen_loop;
      // for downsampling (int_ratio = 1) read extra
      // sample from input buffer to hist
      rMAC = 0, r0 = M[I0, 0];
      r7 = r7 + M3, M[I1, M3] = r0;
      M[I0, M3] = rMAC;
      jump start_norm;

   upsampling:
   do  fractinal_gen_loop;
      start_norm:
      r4 = r4 + r5 ;
      if NEG jump no_extra_copy;
         // clear the oldest sample and jump to next one
         rMAC = 0, r0 = M[I0, 0];
         r4 = r4 - (-1.0);
         r7 = r7 + M3, M[I1, M3] = r0;
         M[I0, M3] = rMAC;
      no_extra_copy:

      // input is upsapled by rate=r6, find the best points to interpolate
      rMAC = r4*r6;       // r6=uprate r4=fraction
      r3 = rMAC0;
      r3 = r3 LSHIFT -1; // r3 = interpolation ratio
      r2 = rMAC1;        // r0 = index of first point

      // FIR filtering starts from right side of coeffs
      I6 = I3 + r2 ;
      r0 = (-$cbops.auto_resample_mix.TONE_FILTER_UPRATE-1) - r2;
      M1 = r0 - r2;
      // save I1
      I7 = I1;

      rMAC = 0,              r0 = M[I1,M3], r1 = M[I6,M2]; //1st coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //2nd coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //3rd coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //4th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //5th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M1]; //6th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //7th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //8th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //9th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //10th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //11th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //12th coeff & sample
      rMAC = rMAC - r0 * r1, r1 = M[I0,0];

      //calculate second point
      M1 = M1 - 2;
      r2 = r2 + M3;
      //if first point index is (r6-1) then to calculate next point and extra load is required
      if NEG jump no_extra_load;
        // load an extra point
        M1 = r6 - 1;
        r2 = -r6, M[I1, M3] = r1;
      no_extra_load:

       // calculate second point
       I6 = I3 + r2;
       r2 = rMAC;

                              r0 = M[I1,M3], r1 = M[I6,M2]; //1st coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //2nd coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //3rd coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //4th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //5th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M1]; //6th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //7th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //8th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //9th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //10th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //11th coeff & sample
       rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //12th coeff & sample
       rMAC = rMAC + r0 * r1;

       // restore I1
       I1 = I7;
       //linear interpolation between two adjacent points
       rMAC = rMAC*r3, r0 = M[I2, -1];
       rMAC = rMAC - r2*1.0;

       //compute tone proportion, (saturate and round)
       r2 = M[r8 + $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD];
       r2 = rMAC*r2(frac), r3 = M[I4, 0]; //r2: tone proportion

       //mix
       r0 = M[r8 + $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD];
       rMAC = r0*r3, r1 = M[I5,0];    // rMAC = left proportion
       rMAC = rMAC + r2*1.0;          // rMAC = left+tone
       rMAC = r1*r0, M[I4, 1] = rMAC; //save left, rMAC = right proportion
       rMAC = rMAC + r2*1.0;          // rMAC = right+tone
       // save final computed sample
       M[I5, 1] = rMAC;
   fractinal_gen_loop:

   // save hist pointer
   r0 = I1;
   M[r8 + $cbops.auto_resample_mix.HIST_BUF_FIELD] = r0;

   // store the sample counter
   M[r8 + $cbops.auto_resample_mix.IR_RATIO_FIELD] = r4;

   op_done:
   // update tone cbuffer read address
   r0 = M[r8 + $cbops.auto_resample_mix.TONE_CBUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   r1 = r7 - r0;
   if POS r7= r7 - r1;
   // update tone cbuffer read address
   r0 = M[r8 + $cbops.auto_resample_mix.TONE_CBUFFER_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif

   I0 = r0;
   L0 = r1;
   M0 = r7;
   r0 = M[I0, M0];
   r1 = I0;
   r0 = M[r8 + $cbops.auto_resample_mix.TONE_CBUFFER_FIELD];
   call $cbuffer.set_read_address;

   end:
   L4 = 0;
   L1 = 0;
   L0 = 0;
   L5 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
