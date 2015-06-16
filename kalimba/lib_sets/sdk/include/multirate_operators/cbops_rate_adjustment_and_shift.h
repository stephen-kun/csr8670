// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef CBOPS_RATE_ADJUSTMENT_AND_SHIFT_HEADER_INCLUDED
#define CBOPS_RATE_ADJUSTMENT_AND_SHIFT_HEADER_INCLUDED

   .CONST   $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD             0;  // input
   .CONST   $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD            1;  // output
   .CONST   $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD                   2;  // shift amount
   .CONST   $cbops.rate_adjustment_and_shift.MASTER_OP_FIELD                      3;  // Pointer to Master
   .CONST   $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD                  4;  // filter coeffs address
   .CONST   $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD                      5;  // history cirular buffer for left channel
   .CONST   $cbops.rate_adjustment_and_shift.HIST1_BUF_START_FIELD                6;  // history cirular buffer for left channel start address
   .CONST   $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD           7;  // target rate (address)
   .CONST   $cbops.rate_adjustment_and_shift.ENABLE_COMPRESSOR_FIELD              8;  // 0: no compressor 1: compressor in
   .CONST   $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD               9; // current rate
   .CONST   $cbops.rate_adjustment_and_shift.RF                                   10; // internal state
   .CONST   $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD             11; // internal state
   .CONST   $cbops.rate_adjustment_and_shift.WORKING_STATE_FIELD                  12; // delay or SRA mode
   .CONST   $cbops.rate_adjustment_and_shift.TEMP_VAR_FIELD                       13; // delay or SRA mode

   .CONST   $cbops.rate_adjustment_and_shift.STRUC_SIZE                           14;


   .CONST $cbops.rate_adjustment_and_shift.SRA_UPRATE      21;

   // define one of options (better quality, bigger computation)
   //#define $sra.NORMAL_QUALITY_COEFFS
   #define $sra_HIGH_QUALITY_COEFFS
   //#define $sra.VERY_HIGH_QUALITY_COEFFS

   #ifdef $sra_VERY_HIGH_QUALITY_COEFFS
      .CONST $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE 18;
   #endif

   #ifdef $sra_HIGH_QUALITY_COEFFS
      .CONST $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE 12;
   #endif

   #ifdef $sra_NORMAL_QUALITY_COEFFS
      .CONST $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE 8;
   #endif

  .CONST $sra.MOVING_STEP (0.0015*(1.0/1000.0)/10.0); // 0.0015: interrupt period, this means it would take 8 seconds for 1hz change for a 1khz tone

   //#define $sra_DISABLE_FOR_LOW_RATES // this option has not been tested
   #ifdef $sra_DISABLE_FOR_LOW_RATES
      .CONST $cbops.rate_adjustment_and_shift.MIN_RATE_UP      0.0004;
      .CONST $cbops.rate_adjustment_and_shift.MIN_RATE_LOW     0.0002;
   #endif

#endif // CBOPS_RATE_ADJUSTMENT_AND_SHIFT_HEADER_INCLUDED
