// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CBOPS_RATE_ADJUSTMENT_AND_SHIFT_HEADER_INCLUDED
#define CBOPS_RATE_ADJUSTMENT_AND_SHIFT_HEADER_INCLUDED

   .CONST   $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD             0; // left input
   .CONST   $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD            1; // left output
   .CONST   $cbops.rate_adjustment_and_shift.INPUT2_START_INDEX_FIELD             2; // right input
   .CONST   $cbops.rate_adjustment_and_shift.OUTPUT2_START_INDEX_FIELD            3; // right output
   .CONST   $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD                   4; // shift amount
   .CONST   $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD                  5; // filter coeffs address
   .CONST   $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD                      6; // history cirular buffer for left channel
   .CONST   $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD                      7; // history cirular buffer for right channel
#ifdef BASE_REGISTER_MODE
   .CONST   $cbops.rate_adjustment_and_shift.HIST1_BUF_START_FIELD                $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD+1;               // history cirular buffer for left channel start address
   .CONST   $cbops.rate_adjustment_and_shift.HIST2_BUF_START_FIELD                $cbops.rate_adjustment_and_shift.HIST1_BUF_START_FIELD+1;         // history cirular buffer for right channel start address
   .CONST   $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD           $cbops.rate_adjustment_and_shift.HIST2_BUF_START_FIELD+1;         // target rate (address)
#else
   .CONST   $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD           $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD+1;               // target rate (address)
#endif
   .CONST   $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD                    $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD+1;    // type of dithering
   .CONST   $cbops.rate_adjustment_and_shift.ENABLE_COMPRESSOR_FIELD              $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD+1;             // 0: no compressor 1: compressor in
   .CONST   $cbops.rate_adjustment_and_shift.FILTER_COEFFS_SIZE_FIELD             $cbops.rate_adjustment_and_shift.ENABLE_COMPRESSOR_FIELD+1;
   .CONST   $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD               $cbops.rate_adjustment_and_shift.FILTER_COEFFS_SIZE_FIELD+1;      // current rate
   .CONST   $cbops.rate_adjustment_and_shift.RF                                   $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD+1;        // internal state
   .CONST   $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD             $cbops.rate_adjustment_and_shift.RF+1;                            // internal state
   .CONST   $cbops.rate_adjustment_and_shift.WORKING_STATE_FIELD                  $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD+1;      // delay or SRA mode
   .CONST   $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD         $cbops.rate_adjustment_and_shift.WORKING_STATE_FIELD+1;           // internal state
   .CONST   $cbops.rate_adjustment_and_shift.DITHER_HIST_RIGHT_INDEX_FIELD        $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD+1;  // internal state

   .CONST   $cbops.rate_adjustment_and_shift.STRUC_SIZE                           $cbops.rate_adjustment_and_shift.DITHER_HIST_RIGHT_INDEX_FIELD+1;

   // Completion operator parameter structure size
   .CONST   $cbops.rate_adjustment_and_shift_complete.STRUC_SIZE                  1;

   .CONST $cbops.rate_adjustment_and_shift.SRA_UPRATE      21;

   .CONST $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE 12;
   .CONST $cbops.rate_adjustment_and_shift.SRA_HD_QUALITY_COEFFS_SIZE 36;

  .CONST $sra.MOVING_STEP (0.0015*(1.0/1000.0)/10.0); // 0.0015: interrupt period, this means it would take 8 seconds for 1hz change for a 1khz tone

   #define $sra_ENABLE_DITHER_FUNCTIONS
   #ifdef $sra_ENABLE_DITHER_FUNCTIONS
   // TODO: cannot declare constant as below.  For now replace $sra.scratch_buffer with $M.cbops.av_copy.left_silence_buffer
   // COME BACK AND ADDRESS THIS LATER!
   #endif

#endif // CBOPS_RATE_ADJUSTMENT_AND_SHIFT_HEADER_INCLUDED
