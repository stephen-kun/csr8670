// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef ADAPEQ_LIB_H
#define ADAPEQ_LIB_H

.CONST $ADAPEQ_VERSION                       0x01000A;


// Bands_Buffer contains two buffers: 1st half AEQ_BAND_PX + 2nd half band_pwr
.CONST   $M.AdapEq.Num_AEQ_Bands             3;
.CONST   $M.AdapEq.Bands_Buffer_Length       ($M.AdapEq.Num_AEQ_Bands * 2);
.CONST   $M.AdapEq.Scratch_Length            65;

// -----------------------------------------------------------------------------
// Constant offsets into the AdapEq data objects
// -----------------------------------------------------------------------------
// @DATA_OBJECT ADAPEQDATAOBJECT

// @DOC_FIELD_TEXT    Configuration Word for AdapEq
// @DOC_FIELD_FORMAT  Bit Mask
.CONST   $M.AdapEq.CONTROL_WORD_FIELD        0;
// @DOC_FIELD_TEXT    Bitmask to bypass AdapEq
// @DOC_FIELD_FORMAT  Bit Mask
.CONST   $M.AdapEq.BYPASS_BIT_MASK_FIELD     $M.AdapEq.CONTROL_WORD_FIELD + 1;
// @DOC_FIELD_TEXT    Bitmask to enable or disable AdapEq BEX
// @DOC_FIELD_FORMAT  Bit Mask
.CONST   $M.AdapEq.BEX_BIT_MASK_FIELD        $M.AdapEq.BYPASS_BIT_MASK_FIELD + 1;
// @DOC_FIELD_TEXT    Number of FFT bins 
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.NUM_FREQ_BINS             $M.AdapEq.BEX_BIT_MASK_FIELD + 1;
// @DOC_FIELD_TEXT    BEX Noise dependent enable flags
// @DOC_FIELD_FORMAT  Flag
.CONST   $M.AdapEq.BEX_NOISE_LVL_FLAGS       $M.AdapEq.NUM_FREQ_BINS + 1;
// @DOC_FIELD_TEXT    Pointer to real part of X (FFT of input signal x)
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_X_REAL_FIELD          $M.AdapEq.BEX_NOISE_LVL_FLAGS + 1;
// @DOC_FIELD_TEXT    Pointer to imaginary part of X (FFT of input signal x)
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_X_IMAG_FIELD          $M.AdapEq.PTR_X_REAL_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to block exponent of X (FFT of input signal x)
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_BEXP_X_FIELD          $M.AdapEq.PTR_X_IMAG_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to real part of Z
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_Z_REAL_FIELD          $M.AdapEq.PTR_BEXP_X_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to imaginary part of Z
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_Z_IMAG_FIELD          $M.AdapEq.PTR_Z_REAL_FIELD + 1;
// @DOC_FIELD_TEXT    Low band starting frequency.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.LOW_INDEX_FIELD           $M.AdapEq.PTR_Z_IMAG_FIELD + 1;
// @DOC_FIELD_TEXT    Low Band Width
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.LOW_BW_FIELD              $M.AdapEq.LOW_INDEX_FIELD + 1;
// @DOC_FIELD_TEXT    Inverse Low Band Width
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD  $M.AdapEq.LOW_BW_FIELD + 1;
// @DOC_FIELD_TEXT    Mid Band Width
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.MID_BW_FIELD              $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD + 1;
// @DOC_FIELD_TEXT    Inverse Mid Band Width
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD  $M.AdapEq.MID_BW_FIELD + 1;
// @DOC_FIELD_TEXT    High Band Width
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.HIGH_BW_FIELD             $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD + 1;
// @DOC_FIELD_TEXT    Inverse High Band Width
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD $M.AdapEq.HIGH_BW_FIELD + 1;
// @DOC_FIELD_TEXT    Frame counter
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.AEQ_EQ_COUNTER_FIELD      $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD + 1;
// @DOC_FIELD_TEXT    Number of frames to wait before adaptation starts
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.AEQ_EQ_INIT_FRAME_FIELD   $M.AdapEq.AEQ_EQ_COUNTER_FIELD + 1;

.CONST   $M.AdapEq.AEQ_GAIN_LOW_FIELD        $M.AdapEq.AEQ_EQ_INIT_FRAME_FIELD + 1;

.CONST   $M.AdapEq.AEQ_GAIN_HIGH_FIELD       $M.AdapEq.AEQ_GAIN_LOW_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to the value of Voice Activity Detector (VAD)  .
// @DOC_FIELD_TEXT    Value = 1 for 'voice activity detected'  Value = 0 for 'no voice activity detected'
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_VAD_AGC_FIELD         $M.AdapEq.AEQ_GAIN_HIGH_FIELD + 1;
// @DOC_FIELD_TEXT    Attack time of power average for each band.
// @DOC_FIELD_FORMAT  Q1.23 format
.CONST   $M.AdapEq.ALFA_A_FIELD              $M.AdapEq.PTR_VAD_AGC_FIELD + 1;
// @DOC_FIELD_TEXT    1 - Attack time of power average for each band.
// @DOC_FIELD_FORMAT  Q1.23 format
.CONST   $M.AdapEq.ONE_MINUS_ALFA_A_FIELD    $M.AdapEq.ALFA_A_FIELD + 1;
// @DOC_FIELD_TEXT    Decay time of power average for each band
// @DOC_FIELD_FORMAT  Q1.23 format
.CONST   $M.AdapEq.ALFA_D_FIELD              $M.AdapEq.ONE_MINUS_ALFA_A_FIELD + 1;
// @DOC_FIELD_TEXT    1 - Decay time of power average for each band
// @DOC_FIELD_FORMAT  Q1.23 format
.CONST   $M.AdapEq.ONE_MINUS_ALFA_D_FIELD    $M.AdapEq.ALFA_D_FIELD + 1;
// @DOC_FIELD_TEXT    Average time constant for initial calculation of the powers
// @DOC_FIELD_FORMAT  Q1.23 format
.CONST   $M.AdapEq.ALFA_ENV_FIELD            $M.AdapEq.ONE_MINUS_ALFA_D_FIELD + 1;
// @DOC_FIELD_TEXT    1 - Average time constant for initial calculation of the powers
// @DOC_FIELD_FORMAT  Q1.23 format
.CONST   $M.AdapEq.ONE_MINUS_ALFA_ENV_FIELD  $M.AdapEq.ALFA_ENV_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to AEQ bands buffer
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_AEQ_BAND_PX_FIELD     $M.AdapEq.ONE_MINUS_ALFA_ENV_FIELD + 1;
// @DOC_FIELD_TEXT    Current state of the AEQ (low noise / mid noise / high noise)
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.STATE_FIELD               $M.AdapEq.PTR_AEQ_BAND_PX_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to step size
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_VOL_STEP_UP_FIELD     $M.AdapEq.STATE_FIELD + 1;
// @DOC_FIELD_TEXT    Transition threshold from low noise state to middle noise state based on NDVC volume.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.VOL_STEP_UP_TH1_FIELD     $M.AdapEq.PTR_VOL_STEP_UP_FIELD + 1;
// @DOC_FIELD_TEXT    Transition threshold from middle noise state to high noise state based on NDVC volume.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.VOL_STEP_UP_TH2_FIELD     $M.AdapEq.VOL_STEP_UP_TH1_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to Low Noise Target Power Ratio
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_GOAL_LOW_FIELD        $M.AdapEq.VOL_STEP_UP_TH2_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to Low Noise Target Power Ratio
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_GOAL_HIGH_FIELD       $M.AdapEq.PTR_GOAL_LOW_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to attenuation for BEX AEQ
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_BEX_ATT_TOTAL_FIELD   $M.AdapEq.PTR_GOAL_HIGH_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to BEX Low Noise Target Power Ratio
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_BEX_GOAL_HIGH2_FIELD  $M.AdapEq.PTR_BEX_ATT_TOTAL_FIELD  + 1;
// @DOC_FIELD_TEXT    BEX Low Inter-Band Step Size
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.BEX_PASS_LOW_FIELD        $M.AdapEq.PTR_BEX_GOAL_HIGH2_FIELD + 1;
// @DOC_FIELD_TEXT    Step size of gain transition between extended band-1 and band-2.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.BEX_PASS_HIGH_FIELD       $M.AdapEq.BEX_PASS_LOW_FIELD + 1;
// @DOC_FIELD_TEXT    Boundary frequency between low band and middle (reference) band.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.MID1_INDEX_FIELD          $M.AdapEq.BEX_PASS_HIGH_FIELD  + 1;
// @DOC_FIELD_TEXT    Boundary frequency between middle (reference) band and high band.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.MID2_INDEX_FIELD          $M.AdapEq.MID1_INDEX_FIELD + 1;
// @DOC_FIELD_TEXT    Stop frequency of high band.
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.HIGH_INDEX_FIELD          $M.AdapEq.MID2_INDEX_FIELD + 1;
// @DOC_FIELD_TEXT    Inverse Low Band Step
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.INV_AEQ_PASS_LOW_FIELD    $M.AdapEq.HIGH_INDEX_FIELD + 1;
// @DOC_FIELD_TEXT    Inverse High Band Step
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD   $M.AdapEq.INV_AEQ_PASS_LOW_FIELD + 1;
// @DOC_FIELD_TEXT    Step size of gain transition between low band and reference band.
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.AEQ_PASS_LOW_FIELD        $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD + 1;
// @DOC_FIELD_TEXT    Step size of gain transition between reference band and high band.
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.AEQ_PASS_HIGH_FIELD       $M.AdapEq.AEQ_PASS_LOW_FIELD + 1;
// @DOC_FIELD_TEXT    For low/ref/high band if the power of a lower band is greater than its neighbor higher band  
// @DOC_FIELD_TEXT    and if the power difference is above this threshold the signal will be detected as tone signal.
// @DOC_FIELD_TEXT    During tone signal the AEQ will be disabled.
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.AEQ_POWER_TH_FIELD        $M.AdapEq.AEQ_PASS_HIGH_FIELD + 1;
// @DOC_FIELD_TEXT    Tone power if any is detected .
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.AEQ_TONE_POWER_FIELD      $M.AdapEq.AEQ_POWER_TH_FIELD + 1;
// @DOC_FIELD_TEXT    The lower bound of AEQ gain allowed for low band and high band.
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD     $M.AdapEq.AEQ_TONE_POWER_FIELD + 1;
// @DOC_FIELD_TEXT    The higher bound of AEQ gain allowed for low band and high band.
// @DOC_FIELD_FORMAT  Q8.16 format
.CONST   $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD     $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD + 1;
// @DOC_FIELD_TEXT    Output flag for AEQ Tone Detection
// @DOC_FIELD_FORMAT  Flag
.CONST   $M.AdapEq.AEQ_POWER_TEST_FIELD      $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD + 1;
// @DOC_FIELD_TEXT    Pointer to the AEQ scratch buffer
// @DOC_FIELD_FORMAT  Pointer
.CONST   $M.AdapEq.PTR_SCRATCH_G_FIELD       $M.AdapEq.AEQ_POWER_TEST_FIELD + 1;
// @DOC_FIELD_TEXT    Structure Size
// @DOC_FIELD_FORMAT  Integer
.CONST   $M.AdapEq.STRUC_SIZE                $M.AdapEq.PTR_SCRATCH_G_FIELD + 1;


// @END  DATA_OBJECT ADAPEQDATAOBJECT
// -----------------------------------------------------------------------------
// AEQ scratch variables
// -----------------------------------------------------------------------------
#define AEQ_S_BEQ_ENABLED                    $scratch.s0
#define AEQ_S_log2_sum_pXt                   $scratch.s1
#define AEQ_S_lin_gain                       $scratch.s2
#define AEQ_S_diff_high                      $scratch.s3

#endif
