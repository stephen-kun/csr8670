// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    rate_adjustment_and_shift operator
//
// DESCRIPTION:
//    This operator replaces the warp_and_shift operator, it resamples the
//    incoming data to a proper rate to compensate the rate mismatch between source
//    and sink clocks.
//
//
// *****************************************************************************

#include "stack.h"
#include "cbops.h"

// Operator function table
.MODULE $M.cbops.rate_adjustment_and_shift;
   .DATASEGMENT DM;

   .VAR amount_used;

   // ** function vector **
   .VAR $cbops.rate_adjustment_and_shift[$cbops.function_vector.STRUC_SIZE] =
      &$cbops.function_vector.NO_FUNCTION,               // reset vector
      &$cbops.rate_adjustment_and_shift.amount_to_use,   // amount to use function
      &$cbops.rate_adjustment_and_shift.main;            // main function

.ENDMODULE;

// Completion handling used where the operator is NOT the last in the cbops chain
.MODULE $M.cbops.rate_adjustment_and_shift_complete;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.rate_adjustment_and_shift_complete[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,                // reset function
      $cbops.function_vector.NO_FUNCTION,                // amount to use function
      $cbops.rate_adjustment_and_shift.complete;         // main function

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbops.rate_adjustment_and_shift.complete
//
// DESCRIPTION:
//    operator main function to complete rate adjustment
//    This operator is the last in the chain.  Reseting $cbops.amount_to_use
//    to correctly advance the input buffer
//
// INPUTS:
//    - r6  = pointer to the list of input and output buffer pointers
//    - r7  = pointer to the list of buffer lengths
//    - r8  = pointer to operator structure
//    - r10 = the number of samples to generate
//
// OUTPUTS:
//    - r8  = pointer to operator structure
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************
.MODULE $M.cbops.rate_adjustment_and_shift.complete;
   .CODESEGMENT CBOPS_RATE_ADJUSTMENT_AND_SHIFT_COMPLETE_PM;

$cbops.rate_adjustment_and_shift.complete:
    // This should be the last operator in chain.
    // Set M[$cbops.amount_to_use] to correctly advance the input buffer pointers
    r0 = M[$M.cbops.rate_adjustment_and_shift.amount_used];
    M[$cbops.amount_to_use] = r0;
    rts;

.ENDMODULE;

// *******************************************************************************
// MODULE:
//    $cbops.rate_adjustment_and_shift.amount_to_use
//
// DESCRIPTION:
//    Amount to use function for the rate_adjustment_and_shift operator.  The number of
//    input samples to process is calculated based on the amount of space in
//    the output buffer and the current warp factor that is being applied.
//
// INPUTS:
//    - r5 = the minimum of the number of input samples available and the
//      amount of output space available
//    - r6 = the number of input samples available
//    - r7 = the amount of output space available
//    - r8 = pointer to operator structure:
//    $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD
//          -left input audio channel index
//    $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD
//          -left output audio channel index
//    $cbops.rate_adjustment_and_shift.INPUT2_START_INDEX_FIELD
//          -right input audio channel index (-1 if mono required)
//    $cbops.rate_adjustment_and_shift.OUTPUT2_START_INDEX_FIELD
//          -right output audio channel index (-1 if mono required)
//    $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD
//          -amount of shift required after resampling
//    $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD
//          - coefficient used to resample
//    $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD
//          - history buffer for resampling left input
//    $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD
//          - history buffer for resampling right input
//    $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD
//          - address which stores the target rate value,
//            output_rate = (1 + target_rate) * input_rate, target rate is expceted to be
//            between -0.005 and 0.005
//    $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD
//          - determines which type of ditherring is applied befor shifting
//            one of the follwing values
//                - $cbops.dither_and_shift.DITHER_TYPE_NONE (0)       -> no dithering
//                - $cbops.dither_and_shift.DITHER_TYPE_TRIANGULAR (1) -> triangular dithering
//                - $cbops.dither_and_shift.DITHER_TYPE_SHAPED (2)     -> noise shaped dithering
//           NOTE: $sra.ENABLE_DITHER_FUNCTIONS must be defined to enable dithering funtions
//    $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.RF
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.DITHER_HIST_RIGHT_INDEX_FIELD
//           - internal state , init to zero
//
// OUTPUTS:
//    - r5 = number of input samples to use
//
// TRASHED REGISTERS:
//    r0, r4, r5
//
// *******************************************************************************
.MODULE $M.cbops.rate_adjustment_and_shift.amount_to_use;
   .CODESEGMENT CBOPS_RATE_ADJUSTMENT_AND_SHIFT_AMOUNT_TO_USE_PM;
   .DATASEGMENT DM;

   // ** amount to use function **
$cbops.rate_adjustment_and_shift.amount_to_use:
   //   r6 = amount_input_data
   //   r7 = amount_output_space
   // calculate the required amount of input data we need given the amount of output space we have
   r0 = M[r8 + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD];
   r4 = r0 * r7 (frac);
   r4 = r7 - r4;
  #ifdef $sra_ENABLE_DITHER_FUNCTIONS
      Null = M[r8 + $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD];
      if Z jump no_limit;
      // limit amount to use to 95, this is just a safe gaurd and normally doesnt happen
      // dithering uses scratch memory defined in av_copy module
      r0 = r4 - 95;
      if POS r4 = r4 - r0;
      no_limit:
   #endif
   // because of rounding errors to be safe we knock off 2
   r4 = r4 - 2;
   if NEG r4 = 0;

   // if the amount of data avaiable > calculate amount -> set amount available to calculate amount
   Null = r4 - r5;
   if NEG r5 = r4;
   rts;

.ENDMODULE;
// *******************************************************************************
// MODULE:
//    $cbops.rate_adjustment_and_shift.main
//
// DESCRIPTION:
//   Main processing function for the rate_adjustment_and_shift operator.
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure:
//    $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD
//          -left input audio channel index
//    $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD
//          -left output audio channel index
//    $cbops.rate_adjustment_and_shift.INPUT2_START_INDEX_FIELD
//          -right input audio channel index (-1 if mono required)
//    $cbops.rate_adjustment_and_shift.OUTPUT2_START_INDEX_FIELD
//          -right output audio channel index (-1 if mono required)
//    $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD
//          -amount of shift required after resampling
//    $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD
//          - coefficient used to resample
//    $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD
//          - history buffer for resampling left input
//    $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD
//          - history buffer for resampling right input
//    $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD
//          - address which stores the target rate value,
//            output_rate = (1 + target_rate) * input_rate, target rate is expeted to be
//            between 0.005 and 0.005
//    $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD
//          - determines which type of ditherring is applied befor shifting
//            one of the follwing values
//                - $cbops.dither_and_shift.DITHER_TYPE_NONE (0)       -> no dithering
//                - $cbops.dither_and_shift.DITHER_TYPE_TRIANGULAR (1) -> triangular dithering
//                - $cbops.dither_and_shift.DITHER_TYPE_SHAPED (2)     -> noise shaped dithering
//           NOTE: $sra.ENABLE_DITHER_FUNCTIONS must be defined to enable dithering funtions
//    $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.RF
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD
//           - internal state , init to zero
//    $cbops.rate_adjustment_and_shift.DITHER_HIST_RIGHT_INDEX_FIELD
//           - internal state , init to zero
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    everything
//
// *******************************************************************************
.MODULE $M.cbops.rate_adjustment_and_shift.main;
   .CODESEGMENT CBOPS_RATE_ADJUSTMENT_AND_SHIFT_MAIN_PM;
   .DATASEGMENT DM;

   // ** main routine **
   $cbops.rate_adjustment_and_shift.main:
   // push rLink onto stack
   $push_rLink_macro;
  #ifdef ENABLE_PROFILER_MACROS
     .VAR/DM1 $cbops.profile_rate_adjustment_and_shift[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      r0 = &$cbops.profile_rate_adjustment_and_shift;
      call $profiler.start;
  #endif

     // define a variable to stor right channel info
    .VAR right_channel_info[7] ;
    .CONST $sra.RIGHT_CHANNEL_ENABLE_FIELD                 0;
    .CONST $sra.RIGHT_CHANNEL_INPUT_BUFFER_ADDR_FIELD      1;
    .CONST $sra.RIGHT_CHANNEL_INPUT_BUFFER_LENGTH_FIELD    2;
    .CONST $sra.RIGHT_CHANNEL_INPUT_BUFFER_START_FIELD     3;
    .CONST $sra.RIGHT_CHANNEL_OUTPUT_BUFFER_ADDR_FIELD     4;
    .CONST $sra.RIGHT_CHANNEL_OUTPUT_BUFFER_LENGTH_FIELD   5;
    .CONST $sra.RIGHT_CHANNEL_OUTPUT_BUFFER_START_FIELD    6;

    // define some other scratch variable
   .VAR temp_vars[4];
   .CONST  $sra.TEMPVAR_SHIFT_VALUE_FIELD 0;

   // -- get the left channel input/output info
   // get the offset to the read buffer to use
   r2 = M[r8 + $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD];
   // get the input buffer read address
   r3 = M[r6 + r2];
   // store the value in I4
   I4 = r3;
   // get the input buffer length
   r4 = M[r7 + r2];
   // Store the value in L4
   L4 = r4;
#ifdef BASE_REGISTER_MODE
   // get the start address
   r1 = M[r5 + r2];
   push r1;
   pop B4;
#endif


   // get the offset to the write buffer to use
   r2 = M[r8 + $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD];
   // get the output buffer write address
   r3 = M[r6 + r2];
   // store the value in I5
   I5 = r3;
   // get the output buffer length
   r4 = M[r7 + r2];
   // store the value in L5
   L5 = r4;
#ifdef BASE_REGISTER_MODE
   // get the start address
   r1 = M[r5 + r2];
   push r1;
   pop B5;
#endif


   // -- get the right channel input/output info
   // get the offset to the read buffer to use
   r2 = M[r8 + $cbops.rate_adjustment_and_shift.INPUT2_START_INDEX_FIELD];
   // if mono skip reading more info
   M[right_channel_info+$sra.RIGHT_CHANNEL_ENABLE_FIELD] = r2;
   if NEG jump no_right_channel;
   // get the input buffer read address
   r3 = M[r6 + r2];
   // store the value in a temp addr
   M[right_channel_info + $sra.RIGHT_CHANNEL_INPUT_BUFFER_ADDR_FIELD] = r3;
   // get the input buffer length
   r4 = M[r7 + r2];
   //  store the value in a temp addr
   M[right_channel_info + $sra.RIGHT_CHANNEL_INPUT_BUFFER_LENGTH_FIELD] = r4;
#ifdef BASE_REGISTER_MODE
   // get the start address
   r1 = M[r5 + r2];
   //  store the value in a temp addr
   M[right_channel_info + $sra.RIGHT_CHANNEL_INPUT_BUFFER_START_FIELD] = r1;
#endif


   // get the offset to the write buffer to use
   r2 = M[r8 + $cbops.rate_adjustment_and_shift.OUTPUT2_START_INDEX_FIELD];
   // get the output buffer write address
   r3 = M[r6 + r2];
   //  store the value in a temp addr
   M[right_channel_info + $sra.RIGHT_CHANNEL_OUTPUT_BUFFER_ADDR_FIELD] = r3;
   // get the output buffer length
   r4 = M[r7 + r2];
   //  store the value in a temp addr
   M[right_channel_info + $sra.RIGHT_CHANNEL_OUTPUT_BUFFER_LENGTH_FIELD] = r4;
#ifdef BASE_REGISTER_MODE
   // get the start address
   r1 = M[r5 + r2];
   //  store the value in a temp addr
   M[right_channel_info + $sra.RIGHT_CHANNEL_OUTPUT_BUFFER_START_FIELD] = r1;
#endif

   no_right_channel:

   // read the shift amount
   r7 = M[r8 + $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD];
   // save it in a temp variable
   M[temp_vars + $sra.TEMPVAR_SHIFT_VALUE_FIELD] = r7;

   // obtain pointer to history buffer
   r0 = M[r8 + $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD];
   I0 = r0;
#ifdef BASE_REGISTER_MODE
   r0 = M[r8 + $cbops.rate_adjustment_and_shift.HIST1_BUF_START_FIELD];
   push r0;
   B0 = M[SP-1];
   pop B1;
#endif
   r0 = $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE;
   r1 = M[r8 + $cbops.rate_adjustment_and_shift.FILTER_COEFFS_SIZE_FIELD];
   if Z r1 = r0;
   L0 = r1;
   L1 = r1;

   // get the coeffs addr
   r0 = M[r8 + $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD];

   // I3 is now pointer to the end of coefficient table
   r1 = r1 * ($cbops.rate_adjustment_and_shift.SRA_UPRATE)(int);
   r1 = r1 LSHIFT -1;
   I3 = r0 + r1;


   // calculate current rate, slowly move towards the target rate
   r0 = M[r8 + $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD];
   r4 = M[r0];

   // slowly move towards the target rate
   r5 = M[r8 + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD];
   // logarithmic then linear movement
   r1 = $sra.MOVING_STEP;
   r0 = r5 - r4;
   if NEG r0 = -r0;
   r2 = r0 * 0.001(frac);
   Null = r0 - 0.0015;
   if NEG r2 = r1;
   r1 = r2 - (30*$sra.MOVING_STEP);
   if POS r2 = r2 - r1;
   r1 = r5 - r4;
   r0 = r1 - r2;
   if POS r1 = r1 - r0;
   r0 = r1 + r2;
   if NEG r1 = r1 - r0;
   // update the current rate
   r5 = r5 - r1;
   M[r8 + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD] = r5;

  #ifdef $sra_ENABLE_DITHER_FUNCTIONS
      // decide which function to call for dithering
      r1 = &$sra.tpdf_dither_func;
      r2 = &$sra.noiseshaped_dither_func;
      r3 = 0;
      r0 = M[r8 + $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD];
      Null = r0 - $cbops.dither_and_shift.DITHER_TYPE_TRIANGULAR;
      if Z r3 = r1;
      Null = r0 - $cbops.dither_and_shift.DITHER_TYPE_SHAPED;
      if Z r3 = r2;
      // if scratch buffer is the input buffer, dont dither
      r0 = I4;
      r0 = r0 AND 0xFFFF80;
    //  Null = r0 - &$sra.scratch_buffer;
      Null = r0 - &$M.cbops.av_copy.left_silence_buffer;
      if Z r3 = 0;
      M[dither_function] = r3;
  #endif

   // save r10 for next channel
   .VAR n_samples;
    M[&n_samples] = r10;

    // Save the number of input samples consumed for possible completion later
    M[$M.cbops.rate_adjustment_and_shift.amount_used] = r10;

   .VAR chn_no;
    M[chn_no] =0;

    M3 = 1;
   sra_gen_main_loop:

     #ifdef $sra_ENABLE_DITHER_FUNCTIONS
         // when dithering is enabled, it doesnt write to final buffer, instead it writes to the scratch buffer
         r0 = M[dither_function];
         if NZ call dither_preset;
     #endif

      // run resample
      call sra_resample;

      // adjust hist buffer index
      M1 = r10;
      r0 = M[I0, M1];

      // store history index for next time
      r3 = r8 + M[chn_no];
      r1 = I0;
      M[r3 + $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD] = r1;

     // run dither function
     #ifdef $sra_ENABLE_DITHER_FUNCTIONS
         r0 = M[dither_function];
         if NZ call run_dither_function;
     #endif

      // finish if this was second channel
      r1 = M[chn_no];
      if NZ jump finished;

      // finish if no left channel available
      r1 = M[right_channel_info + $sra.RIGHT_CHANNEL_ENABLE_FIELD];
      if NEG jump finished;

      //hist buff2
      r1 = M[r8 + $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD];
      I0 = r1;
#ifdef BASE_REGISTER_MODE
      r0 = M[r8 + $cbops.rate_adjustment_and_shift.HIST2_BUF_START_FIELD];
      push r0;
      B0 = M[SP-1];
      pop B1;
#endif

      //get second channel input info
      r1 = M[right_channel_info+$sra.RIGHT_CHANNEL_INPUT_BUFFER_ADDR_FIELD];
      I4 = r1;
      r1 = M[right_channel_info +$sra.RIGHT_CHANNEL_INPUT_BUFFER_LENGTH_FIELD];
      L4 = r1;
#ifdef BASE_REGISTER_MODE
      r1 = M[right_channel_info +$sra.RIGHT_CHANNEL_INPUT_BUFFER_START_FIELD];
      push r1;
      pop B4;
#endif

      //get second channel output info
      r1 = M[right_channel_info+$sra.RIGHT_CHANNEL_OUTPUT_BUFFER_ADDR_FIELD];
      I5 = r1;
      r1 = M[right_channel_info +$sra.RIGHT_CHANNEL_OUTPUT_BUFFER_LENGTH_FIELD];
      L5 = r1;
#ifdef BASE_REGISTER_MODE
      r1 = M[right_channel_info +$sra.RIGHT_CHANNEL_OUTPUT_BUFFER_START_FIELD];
      push r1;
      pop B5;
#endif

      // again, set counter to zero
      r1 = 1;
      M[chn_no] = r1;
   jump sra_gen_main_loop;

   finished:
   M[r8 + $cbops.rate_adjustment_and_shift.RF] = r4;
   r0 = -M1;
   M[r8 + $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD] = r0;
   L5 = 0;
   L4 = 0;
   L0 = 0;
   L1 = 0;

   // set number of output samples produced
   r0 = I7;
   M[$cbops.amount_written] = r0;

   // If not last operator in chain then set M[$cbops.amount_to_use] to the amount of output generated
   // ready for the next operator. In this situation, the cbops chain will need to be terminated
   // with the completion operator to reset M[$cbops.amount_to_use] to enable correct input buffer
   // updating (this is not actually needed if the chain input is a port).
   r2 = M[$cbops.amount_to_use];
   r1 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];
   Null = r1 - $cbops.NO_MORE_OPERATORS;
   if NZ r2=r0;
   M[$cbops.amount_to_use] = r2;

   #ifdef ENABLE_PROFILER_MACROS
       // stop profiling if enabled
       r0 = &$cbops.profile_rate_adjustment_and_shift;
       call $profiler.stop;
   #endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

// *****************************************************************************
// NAME:
//    sra_gen_loop
//
// DESCRIPTION:
//
//  function to resample the input
//
// INPUTS:
//  r4: current value of $cbops.rate_adjustment_and_shift.RF
//  r10: number of input samples
//  I4, L4: input buffer address and size
//  I5, L5: output buffer and size
//  I0, L0, L1: hist buffer and size (L0 = L1)
//  I3: pointer to the coeffs
//  M3: 1
//
// OUTPUTS:
//  r0: total number of sample required for last iteration of the loop
//  r10:  (available number of sample for last iteration of the loop - r0)
//  r4 : current value of $cbops.rate_adjustment_and_shift.RF
//  I7: total number of output samples generated
//  I0: updated hist buffer address
//
// TRASHED REGISTERS:
//    r0-r4, r6, I7, rMAC, I0-I2, I6, M0-M2
// NOTE:
// this function has not been optimized yet
// *****************************************************************************
   sra_resample:

   // set up registers
   r5 = M[r8 + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD];
   I2 = &temp_vars + 1;
   r4 = M[r8 + $cbops.rate_adjustment_and_shift.RF];
   r6 = $cbops.rate_adjustment_and_shift.SRA_UPRATE;
   M2 = -r6;
   M0 = r6;
   r10 = M[&n_samples];
   rMAC = r4*r6;
   r10 = M[&n_samples];
   I7 = 0;
   r0 = M[r8 + $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD];
   if Z jump start_gen;
   r1 = M[I4, 1];
   r10 = r10 - M3, M[I0, 1] = r1;

   start_gen:

   Null = L0 - $cbops.rate_adjustment_and_shift.SRA_HD_QUALITY_COEFFS_SIZE;
   if Z jump run_high_quality_gen_loop;

   do sra_gen_loop;
      // input is upsampled by rate=r6, find the best points to iterpolate
      r3 = rMAC0;
      r3 = r3 LSHIFT -1; // r3 = interpolation ratio
      r2 = rMAC1;        // r2 = index of first point

      // FIR filtering starts from right side of coeffs
      I6 = I3 + r2;
      r0 = (-$cbops.rate_adjustment_and_shift.SRA_UPRATE-1) - r2;
      M1 = r0 - r2;
      I1 = I0;
      rMAC = 0, r0 = M[I1,M3], r1 = M[I6,M2];              //1st coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //2nd coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //3rd coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //4th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //5th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M1]; //9th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //7th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //8th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //9th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //10th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //11th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //12th coeff & sample
      rMAC = rMAC - r0 * r1, r1 = M[I4,0];

      //calculate second point
      M1 = M1 - 2;
      r2 = r2 + M3, M[I2,  0] = rMAC;
      //if first point index is (r6-1) then to calculate next point and extra load is required
      if NEG jump no_extra_load;
         // load an extra point
         M1 = r6 - 1;
         r2 = -r6, M[I1, M3] = r1;
      no_extra_load:
      // calculate second point
      I6 = I3 + r2;
      I7 = I7 + M3,          r0 = M[I1,M3], r1 = M[I6,M2]; //1st coeff & sample
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
      rMAC = rMAC + r0 * r1, r1 = M[I2,-1];

   continue_resample_proc:

      // linear interpolation between two adjacent points
      rMAC = rMAC * r3, r3 = M[I4,1];
      rMAC = rMAC - r1 * 1.0;
      r2 = 0;
      r1 = rMAC - r2, r0 = M[I2,M3];

      //shift
      r1 = r1 ASHIFT r0;

      // load new sample to hist buf
      r4 = r4 - r5, M[I5, M3] = r1;
      if NEG jump no_extra_copy;
         r4 = r4 + (-1.0);
         Null = r5;
         if NEG jump is_neg_rate;
         is_pos_rate:
            r3 = M[I4, -1], r3 = M[I0,-1];
            r10 = r10 + M3, r3 = M[I0,0];
            jump no_extra_copy;
         is_neg_rate:
            r10 = r10 - M3, M[I0,M3] = r3, r3 = M[I4,M3];
            if LE jump end_rts;
      no_extra_copy:
      rMAC = r4 * r6, M[I0,M3] = r3;
   sra_gen_loop:
   rts;

   end_rts:
   r10 = r10 - M3, M[I0, M3] = r3;
   rts;


   run_high_quality_gen_loop:
   do sra_gen_loop;
      // input is upsampled by rate=r6, find the best points to iterpolate
      r3 = rMAC0;
      r3 = r3 LSHIFT -1; // r3 = interpolation ratio
      r2 = rMAC1;        // r2 = index of first point

      // FIR filtering starts from right side of coeffs
      I6 = I3 + r2;
      r0 = (-$cbops.rate_adjustment_and_shift.SRA_UPRATE-1) - r2;
      M1 = r0 - r2;
      I1 = I0;
      rMAC = 0, r0 = M[I1,M3], r1 = M[I6,M2];              //1st coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //2nd coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //3rd coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //4th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //5th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //6th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //7th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //8th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //9th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //10th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //11th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //12th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //13th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //14th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //15th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //16th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //17th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M1]; //18th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //19th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //20th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //21th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //22th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //23th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //24th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //25th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //26th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //27th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //28th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //29th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //30th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //31th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //32th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //33th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //34th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //35th coeff & sample
      rMAC = rMAC - r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //36th coeff & sample
      rMAC = rMAC - r0 * r1, r1 = M[I4,0];

      //calculate second point
      M1 = M1 - 2;
      r2 = r2 + M3, M[I2,  0] = rMAC;
      //if first point index is (r6-1) then to calculate next point and extra load is required
      if NEG jump no_extra_load_hd;
         // load an extra point
         M1 = r6 - 1;
         r2 = -r6, M[I1, M3] = r1;
      no_extra_load_hd:
      // calculate second point
      I6 = I3 + r2;
      I7 = I7 + M3,          r0 = M[I1,M3], r1 = M[I6,M2]; //1st coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //2nd coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //3rd coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //4th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //5th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //6th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //7th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //8th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //9th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //10th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //11th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //12th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //13th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //14th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //15th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //16th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2]; //17th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M1]; //18th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //19th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //20th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //21th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //22th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //23th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //24th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //25th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //26th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //27th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //28th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //29th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //30th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //31th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //32th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //33th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //34th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //35th coeff & sample
      rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M0]; //36th coeff & sample
      rMAC = rMAC + r0 * r1, r1 = M[I2,-1];
      jump continue_resample_proc;

#ifdef $sra_ENABLE_DITHER_FUNCTIONS
// *****************************************************************************
// NAME:
//  dither_preset
//
// DESCRIPTION:
//  redirects sra output to scratch buffer
// INPUTS:
//  none
// OUTPUTS:
//  I5 = start of scratch buffer
// TRASHED REGISTERS
// r0
// *****************************************************************************
   dither_preset:
   // temporarily save output buffer address/size
   r0 = I5;
   M[temp_vars + 2] = r0;
   r0 = L5;
   M[temp_vars + 3] = r0;
   // use scratch buffer as output of sra
   L5 = 0;
  // I5 = &$sra.scratch_buffer;
   I5 = &$M.cbops.av_copy.left_silence_buffer;
   // shift is perfomed after dithering
   M[temp_vars + $sra.TEMPVAR_SHIFT_VALUE_FIELD] = 0;
   rts;
// *****************************************************************************
// NAME:
//  dither_preset
//
// DESCRIPTION:
//    applies dither function on scratch buffer and outputs to the output buffer
// INPUTS:
//  none
// OUTPUTS:
//  none
// *****************************************************************************
   run_dither_function:
   .VAR dither_function;
   .VAR rand_num = $math.RAND_SEED;
   r2 = M[rand_num];
   //I2 = &$sra.scratch_buffer; // input buffer
   I2 = &$M.cbops.av_copy.left_silence_buffer; // input buffer
   r10 = I7;                  // data size
   // restore output buffer
   r1 = M[temp_vars + 2];
   I5 = r1;
   r1 = M[temp_vars + 3];
   L5 = r1;
   // obtain the amount of shift
   r7 = M[r8 + $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD];
   r5 = 1.0;
   // calc dither amplitude
   r6 = -24 - r7;
   r6 = r5 ASHIFT r6;
   M2 = $math.RAND_INC;
   jump r0;  // jump to the dither function
// *****************************************************************************
// NAME:
//    tpdf_dither_func
//
// DESCRIPTION:
//
//  adds tpdf (triangular probability density function) dither type to the input
//
// INPUTS:
//  I2/L2: pointer to the input buffer
//  I5/L5: pointer to output buffer
//  r7: amount of shift
//  r6: dither amplitude (1.0>>(24+r7))
//  r10: number of input samples to dither
//  r5: 1.0
//  r2: random number
//
// OUTPUTS:
//  I2 and I5 updated
// TRASHED REGISTERS:
//    r1-r2, rMAC, r10
//
//-----------------------------------------------------------------------------
//              tpdf dither
//                  |
//               +--V--+    +---------+
// input ------->| sum |----| Q(shift)|----->  output
//               +-----+    +---------+
//
// *****************************************************************************
   $sra.tpdf_dither_func:
   r3 = $math.RAND_MULT;
   I6 = &$cbops.dither_and_shift.coeffs+ $cbops.dither_and_shift.FILTER_COEFF_SIZE+1;
   rMAC = M[I2, 1];
   rMAC =rMAC + r2 * r6;
   do tpdf_dither_loop;
      r2 = r2 * r3(int);                        // save output, generate uniform random value
      r2 = r2 + M2;                             // get input
      rMAC =rMAC + r2 * r6;                     // add TPDF dither
      rMAC = rMAC + r5 * r6;                    // dc remove
      r2 = r2 * r3(int), M[I6, 0] = rMAC;       // generate another uniform random value
      r2 = r2 + M2, r1 = M[I6, 0];
      r1 = r1 ASHIFT r7, rMAC = M[I2, 1];       // shift operation, get next input
      rMAC =rMAC + r2 * r6, M[I5, 1] = r1;      // save output
   tpdf_dither_loop:
   rMAC = M[I0, -1];
   M[rand_num] = r2;
   rts;
// *****************************************************************************
// NAME:
//    noiseshaped_dither_func
//
// INPUTS:
//  I2/L2: pointer to the input buffer
//  I5/L5: pointer to output buffer
//  r7: amount of noise
//  r6: dither amplitude (1.0>>(24+r7))
//  r10: number of input samples to dither
//  r2: random number
//  r5: 1.0
// OUTPUTS:
//  I2 and I5 updated
//
// TRASHED REGISTERS:
//    rMAC, r0-r2, r3-r5, r10, I2, I2, I6
//-----------------------------------------------------------------------
//   Noise-Shaped dithering structure
//
//                           tpdf dither
//                               |
//           +-----+          +--V--+     +----------+
// input --->| sub |-----+----| sum |-----| Q(shift) |--------+---->output
//           +--+--+     |    +-----+     +----------+        |
//              |        |                                    |
//              |        +------------------+                 |
//              |                           |                 |
//              |      +--------+        +--V--+   +----+     |
//              +------| Filter |<-------| sub |<--| DQ |<----+
//                     +--------+        +-----+   +----+
//
// *****************************************************************************
   .VAR/DM1CIRC dith_hist_left[5];
   .VAR/DM1CIRC dith_hist_right[5];
   .VAR/DM2 dither_coeffs[5+2] =  0.54602619736894,
                                 -0.63777198265141,
                                  0.54174933914712,
                                 -0.34770370646217,
                                  0.11651094321320, 0, 0;
   $sra.noiseshaped_dither_func:
   .VAR temp_r4;
   M[temp_r4] = r4;
   // set up registers
   r0 = r8 + M[$M.cbops.rate_adjustment_and_shift.main.chn_no];
   M[&dither_coeffs + 6] = r6;
   r0 = M[r0 + $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD];
   I1 = &dith_hist_left + r0;
   r1 = r0 + &dith_hist_right;
   NULL = M[$M.cbops.rate_adjustment_and_shift.main.chn_no];
   if NZ I1 = r1;
   L1 = 5;
   I6 = &dither_coeffs;
   M0 = -6;
   r4 = $math.RAND_MULT;
   M[$cbops.dither_and_shift.coeffs+ $cbops.dither_and_shift.FILTER_COEFF_SIZE+1] = r6;
   r6 = r6 * 0.75 (frac);
   r3 = -1;
   r0 = -r7;
   r3 = r3 ASHIFT r0, r1 = M[I1, 0];
   do shaped_dither_loop;
      // generate first uniform random value
      r2 = r2 * r4 (int), rMAC = M[I2,1], r0 = M[I6,1];
      r2 = r2 + M2, M[I1,-1] = r1;
      // run filter
      rMAC = rMAC - r1 * r0, r1 = M[I1,-1], r0 = M[I6,1];
      rMAC = rMAC - r1 * r0, r1 = M[I1,-1], r0 = M[I6,1];
      rMAC = rMAC - r1 * r0, r1 = M[I1,-1], r0 = M[I6,1];
      rMAC = rMAC - r1 * r0, r1 = M[I1,0], r0 = M[I6,1];
      rMAC = rMAC - r1 * r0;
      rMAC =rMAC + r2 * r6, M[I6,0] = rMAC;
      // generate second uniform random value
      r2 = r2 * r4 (int), r0 = M[I6,1];
      r2 = r2 + M2;
      // dither
      rMAC = rMAC + r2 * r6, r1 = M[I6,M0];
      // dc removal
      rMAC = rMAC + r5 * r1;
      // dequantize
      r1   = rMAC AND r3;
      // quantize
      rMAC = r1 ASHIFT r7;
      // feed back
      r1 =  r1 - r0, M[I5,1] = rMAC;
      r1 = r1 * 4 (int)(sat);
   shaped_dither_loop:
   M[rand_num] = r2;
   M[I1,0] = r1;
   r0 = r8 + M[$M.cbops.rate_adjustment_and_shift.main.chn_no];
   r1 = I1;
   r1 = r1 AND 0x7;
   M[r0 + $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD] = r1;
   L1 = L0;
   r4 = M[temp_r4] ;
   rts;
#endif    //#ifdef $sra_ENABLE_DITHER_FUNCTIONS
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $$sra_coeffs
// DESCRIPTION:
//    sra filter coefficients which is suitable for almost all applications.
//
//    for fs=48000Hz:
//       0-16khz -> flat with maximum +-0.1dB variation
//       18Khz   -> -0.5dB
//       20kHz   -> -2dB loss
//       MIPS ~= 5.5 for stereo rate matching
//    Coeff size = 126 Words
// *****************************************************************************
.MODULE $M.cbops.sra_coeffs;
   .DATASEGMENT DM;

   .VAR/DM2 $sra_coeffs[] =
      0.942166317765547,  0.935633819906705,  0.922654965904998,  0.903400621267356,  0.878123565877304,  0.847154345427453,  0.810895860876315,
      0.769816796388242,  0.724444007468774,  0.675354009809407,  0.623163725333956,  0.568520654781874,  0.512092655627483,  0.454557510045183,
      0.396592469891649,  0.338863964265883,  0.282017650183075,  0.226668978389792,  0.173394434559584,  0.122723601310068,  0.075132169006358,
      0.031036003545734, -0.009213642316381, -0.045333710574907, -0.077111672942665, -0.104406603961470, -0.127149001307571, -0.145339386019030,
     -0.159045737982207, -0.168399843109067, -0.173592647806485, -0.174868733220325, -0.172520036022173, -0.166878953946474, -0.158310982696836,
     -0.147207036106171, -0.133975603509646, -0.119034897194501, -0.102805138616959, -0.085701124978401, -0.068125207945633, -0.050460804052308,
     -0.033066541947022, -0.016271135513937, -0.000369054370812,  0.014382955244752,  0.027768465236798,  0.039613061272834,  0.049785143369359,
      0.058195853749911,  0.064798171429956,  0.069585228726745,  0.072587918932434,  0.073871876469001,  0.073533920758307,  0.071698062638131,
      0.068511177339990,  0.064138450778481,  0.058758706202904,  0.052559716202998,  0.045733600766068,  0.038472405724605,  0.030963947725808,
      0.023388002047364,  0.015912898457034,  0.008692578168356,  0.001864152096970, -0.004454012606365, -0.010163664058159, -0.015187494528429,
     -0.019469438548030, -0.022974463742877, -0.025687888504910, -0.027614269938875, -0.028775913405490, -0.029211061283776, -0.028971823208936,
     -0.028121912962143, -0.026734258392912, -0.024888550283822, -0.022668794001475, -0.020160924233517, -0.017450538238929, -0.014620797014635,
     -0.011750536805832, -0.008912625676518, -0.006172591637850, -0.003587540336799, -0.001205371766499,  0.000935702904544,  0.002807351264468,
      0.004391030629515,  0.005677640982371,  0.006666946561290,  0.007366797532646,  0.007792186836958,  0.007964179812712,  0.007908755554665,
      0.007655599166726,  0.007236883167919,  0.006686074375449,  0.006036799719686,  0.005321800762037,  0.004572002326604,  0.003815715772567,
      0.003077992187790,  0.002380135341398,  0.001739378759533,  0.001168725945368,  0.000676947703005,  0.000268725883967, -0.000055071224182,
     -0.000297000102653, -0.000462560766757, -0.000559646010434, -0.000597945189188, -0.000588326923623, -0.000542224629382, -0.000471047545066,
     -0.000385638000685, -0.000295793127754, -0.000209866156820, -0.000134458990879, -0.000074214004826, -0.000031709128873, -0.000007456356322;
.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $$sra_coeffs_hd_quality
// DESCRIPTION:
//    sra filter coefficients which for very high quality applications, for
//    example for Dolby Digital (R) SPDIF output. It hass flatter passband
//    and lower aliasing distortion.
//
//    for fs=48000Hz:
//       0-20khz -> flat with maximum +-0.05dB variation
//       MIPS ~= 9.8 for stereo rate matching
//    Coeff size = 378 Words
//
// *****************************************************************************
.MODULE $M.cbops.sra_coeffs_hd_quality;
   .DATASEGMENT DM;
 .VAR/DM2 $sra_coeffs_hd_quality[] =
      0.924132030586272,  0.918210925537120,  0.906437490693035,  0.888948318903719,  0.865945919916025,  0.837695905638113,  0.804523304282305,
      0.766808059524010,  0.724979783129323,  0.679511840715572,  0.630914860238343,  0.579729761287570,  0.526520410190895,  0.471866011157445,
      0.416353347170470,  0.360568986003127,  0.305091566568492,  0.250484278833165,  0.197287646764394,  0.146012718313251,  0.097134759358974,
      0.051087539976102,  0.008258291484498, -0.031016598327937, -0.066455096471272, -0.097832199999055, -0.124981746117002, -0.147797341772570,
     -0.166232411191694, -0.180299373565168, -0.190067976487725, -0.195662823601742, -0.197260146989694, -0.195083886004140, -0.189401144247872,
     -0.180517105166893, -0.168769494064575, -0.154522680181202, -0.138161516729657, -0.120085019383353, -0.100699984652821, -0.080414648866947,
     -0.059632486126026, -0.038746239675714, -0.018132275748900,  0.001854657854529,  0.020886194200940,  0.038664565534153,  0.054926222369634,
      0.069444809061760,  0.082033462873077,  0.092546415268877,  0.100879886008441,  0.106972272404601,  0.110803647677330,  0.112394593443903,
      0.111804401886453,  0.109128692849612,  0.104496499894092,  0.098066887032910,  0.090025164391842,  0.080578776273510,  0.069952938997142,
      0.058386108389968,  0.046125357902362,  0.033421748012894,  0.020525765911441,  0.007682911451493, -0.004870498877621, -0.016911243596103,
     -0.028232763555757, -0.038648332322618, -0.047993785087605, -0.056129770260391, -0.062943497030468, -0.068349961581436, -0.072292644149959,
     -0.074743678560944, -0.075703505080761, -0.075200026252913, -0.073287293667681, -0.070043761232904, -0.065570147335675, -0.059986954209212,
     -0.053431697758033, -0.046055904979758, -0.038021938905187, -0.029499712632326, -0.020663354547921, -0.011687886225486, -0.002745972795568,
      0.005995197145649,  0.014376848718721,  0.022251326238933,  0.029484523548710,  0.035958001783976,  0.041570763718314,  0.046240660806703,
      0.049905416306959,  0.052523255254223,  0.054073139464377,  0.054554613011358,  0.053987270631092,  0.052409868128674,  0.049879099992473,
      0.046468074947154,  0.042264525018600,  0.037368787762784,  0.031891604569143,  0.025951780344008,  0.019673751385540,  0.013185108869336,
      0.006614125081133,  0.000087328384158, -0.006272829066861, -0.012350169600991, -0.018036816484584, -0.023235014820770, -0.027858717778298,
     -0.031834914088117, -0.035104678136908, -0.037623929605829, -0.039363895340148, -0.040311271881637, -0.040468092742754, -0.039851309946401,
     -0.038492104499520, -0.036434945223190, -0.033736419645188, -0.030463864402924, -0.026693825746638, -0.022510383228379, -0.018003371478774,
     -0.013266536091051, -0.008395660044624, -0.003486696815857,  0.001366054637845,  0.006071699439938,  0.010544389527131,  0.014704830926679,
      0.018481630183833,  0.021812458184583,  0.024645013589796,  0.026937772316191,  0.028660513881680,  0.029794619890475,  0.030333144380458,
      0.030280660107226,  0.029652889014887,  0.028476129067478,  0.026786493217289,  0.024628979505715,  0.022056394075434,  0.019128151176005,
      0.015908976035125,  0.012467537721584,  0.008875039831536,  0.005203796985556,  0.001525824739363, -0.002088530394417, -0.005571895513587,
     -0.008861087034467, -0.011898216352124, -0.014631666879422, -0.017016926803964, -0.019017265048704, -0.020604241236904, -0.021758043877520,
     -0.022467654434630, -0.022730838356886, -0.022553967454857, -0.021951681163857, -0.020946397159917, -0.019567684455410, -0.017851514442964,
     -0.015839407343572, -0.013577493116884, -0.011115507086137, -0.008505741303427, -0.005801973027629, -0.003058391610449, -0.000328544597148,
      0.002335677033358,  0.004884995812829,  0.007273629818329,  0.009460084580056,  0.011407841773550,  0.013085933939599,  0.014469396960535,
      0.015539594608142,  0.016284412112864,  0.016698318333760,  0.016782298682153,  0.016543663420123,  0.015995738271823,  0.015157446409398,
      0.014052792768726,  0.012710263281799,  0.011162152956495,  0.009443837771264,  0.007593006068977,  0.005648865524512,  0.003651341824981,
      0.001640284946417, -0.000345301650644, -0.002267994433387, -0.004092632456353, -0.005786937256157, -0.007322059519620, -0.008673043781127,
     -0.009819204250959, -0.010744406810997, -0.011437254196832, -0.011891173375233, -0.012104406083542, -0.012079905384545, -0.011825142871117,
     -0.011351832796509, -0.010675580879574, -0.009815466814297, -0.008793570579204, -0.007634453478885, -0.006364605446143, -0.005011870483564,
     -0.003604862227121, -0.002172381476058, -0.000742847162043,  0.000656248359926,  0.001998849608536,  0.003260804743075,  0.004420280810445,
      0.005458120739550,  0.006358136707532,  0.007107335929459,  0.007696076389518,  0.008118151506697,  0.008370804181384,  0.008454672072389,
      0.008373667279562,  0.008134794830734,  0.007747915471108,  0.007225459209663,  0.006582096875108,  0.005834377561699,  0.005000340294844,
      0.004099108513689,  0.003150476052617,  0.002174493209300,  0.001191061220576,  0.000219543039586, -0.000721602268462, -0.001615154902508,
     -0.002445433686099, -0.003198554539369, -0.003862644176618, -0.004428006179735, -0.004887237660423, -0.005235295790614, -0.005469514528532,
     -0.005589572876473, -0.005597416955635, -0.005497139055577, -0.005294817595161, -0.004998322604886, -0.004617091896496, -0.004161883516782,
     -0.003644510383308, -0.003077563168304, -0.002474127533613, -0.001847501727873, -0.001210920342890, -0.000577289697915,  0.000041060111357,
      0.000632601985163,  0.001186813499791,  0.001694350243959,  0.002147188268242,  0.002538733842046,  0.002863899463217,  0.003119145812483,
      0.003302490072687,  0.003413481726342,  0.003453147590739,  0.003423908435371,  0.003329470041341,  0.003174691997937,  0.002965437881043,
      0.002708410716815,  0.002410977799703,  0.002080989005861,  0.001726592723124,  0.001356053410439,  0.000977574608467,  0.000599130956010,
      0.000228312432467, -0.000127816345613, -0.000462839385091, -0.000771093220032, -0.001047750043862, -0.001288879166143, -0.001491486401672,
     -0.001653531500131, -0.001773924203287, -0.001852499963901, -0.001889976767174, -0.001887894854206, -0.001848541451073, -0.001774862852124,
     -0.001670366388458, -0.001539014930426, -0.001385116626349, -0.001213212569353, -0.001027965013121, -0.000834048629322, -0.000636047119490,
     -0.000438357268447, -0.000245102261843, -0.000060055794622,  0.000113421821570,  0.000272434677773,  0.000414588879626,  0.000538016555932,
      0.000641386396496,  0.000723901163361,  0.000785282907204,  0.000825746878495,  0.000845965346145,  0.000847022720648,  0.000830363521406,
      0.000797734826950,  0.000751124901711,  0.000692699704020,  0.000624738948678,  0.000549573326163,  0.000469524372644,  0.000386848344543,
      0.000303685283253,  0.000222014265006,  0.000143615623535,  0.000070040714906,  0.000002589570731, -0.000057703436200, -0.000110076005496,
     -0.000154036697150, -0.000189356576140, -0.000216054361836, -0.000234375871852, -0.000244768664261, -0.000247852866966, -0.000244389237559,
     -0.000235245520689, -0.000221362163479, -0.000203718413905, -0.000183299764634, -0.000161067617855, -0.000137931938821, -0.000114727540436,
     -0.000092194502662, -0.000070963082917, -0.000051543321495, -0.000034319393810, -0.000019548613214, -0.000007364848460,  0.000002214007772,
      0.000009274995068,  0.000013996036016,  0.000016629524757,  0.000017484248136,  0.000016906362557,  0.000015260154735,  0.000012909296657,
      0.000010199265217,  0.000007441536974,  0.000004900090316,  0.000002780653802,  0.000001223033629,  0.000000296738481,  0.000000000000000;
.ENDMODULE;


