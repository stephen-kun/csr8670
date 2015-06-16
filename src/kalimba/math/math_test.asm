// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// for internal test use only

#define FFT_TWIDDLE_MAX_POINTS 512

#include "math_library.h"
#include "fft_twiddle.h"


.CONST $N_FFT_PTS 512;
.CONST $N_CMULT_PTS 128;
.CONST $N_RAND_PTS 100;

#if 3 * $N_CMULT_PTS > $N_FFT_PTS
   .error 3 * NUM_CMULT_PTS must be <= NUM_FFT_PTS
#endif


.CONST $NUM_FFT_PTS        $N_FFT_PTS;
.CONST $NUM_CMULT_PTS      $N_CMULT_PTS;
.CONST $NUM_RAND_PTS       $N_RAND_PTS;


#ifdef DEBUG_ON
   #define DEBUG_MATH
   #define PROFILE_MATH
#endif

.CONST  $MATHLIB_VERSION         0x010200; //1.0.0
.MODULE $M.mathlib;
   .DATASEGMENT DM;
   .VAR Version = MATHLIB_VERSION;
.ENDMODULE;


.MODULE $M.main;
   .CODESEGMENT MATH_PM;
   .DATASEGMENT DM;

   .CONST SPI_CLR   0x005555;
   .CONST SPI_SET 0x00AAAA;
   .VAR   $flag_ready;
   .VAR   $flag_complete;
   .VAR   $branch_address;

   .VAR/DM1 $fftr[$NUM_FFT_PTS];
   .VAR/DM2 $ffti[$NUM_FFT_PTS];
   .VAR/DM2 $ffttemp[$NUM_FFT_PTS];
   .VAR/DM1 $randarray[$NUM_RAND_PTS];

   .VAR $ffttemp_br_addr = BITREVERSE($ffttemp);

   .VAR $cmult_input1_real_addr = &$fftr;
   .VAR $cmult_input1_imag_addr = &$ffti;
   .VAR $cmult_input2_real_addr = &$fftr + $NUM_CMULT_PTS;
   .VAR $cmult_input2_imag_addr = &$ffti + $NUM_CMULT_PTS;
   .VAR $cmult_output_real_addr = &$fftr + 2*$NUM_CMULT_PTS;
   .VAR $cmult_output_imag_addr = &$ffti + 2*$NUM_CMULT_PTS;

   // test parameters
   .VAR $fft_scale = 0.5;

   .VAR $processor = 2;

   .BLOCK fft_struct;
      .VAR fft_num_pts = $NUM_FFT_PTS;
      .VAR fft_ptr_real = &$fftr;
      .VAR fft_ptr_imag = &$ffti;
   .ENDBLOCK;

   .VAR num_rand_pts = $NUM_RAND_PTS;
   .VAR num_cmult_pts = $NUM_CMULT_PTS;



$main:

   // initialise the stack library
   call $stack.initialise;

   // Set FLAG_READY = SPI_CLR
   // Set FLAG_COMPLETE = SPI_CLR

   rMAC = &SPI_CLR;
   M[&$flag_ready] = rMAC;
   M[&$flag_complete] = rMAC;

   start_iteration:

      // Wait for PC to write input arguments
      // Wait for FLAG_READY == SPI_SET

   wait_input:
      // rMAC = M[&$flag_ready];
      rLink = M[&$flag_ready];
      Null = rLink - &SPI_SET;
   if NZ jump wait_input;

   // PC should be done.
   // Get address of function to execute stored in $branch_address

   rLink = M[&$branch_address];
//   break;
      // Execute at BRANCH_ADDRESS (temporarily a fixed function)
   call rLink;
      // Set FLAG_READY = SPI_CLR
      // Set FLAG_COMPLETE = SPI_SET

   rLink = &SPI_CLR;
   M[&$flag_ready] = rLink;
   rLink = &SPI_SET;
   M[&$flag_complete] = rLink;

      //Jump and wait for next iteration
   jump start_iteration;


.ENDMODULE;


.MODULE $M.reset_rng;
   // reset random number generator
   // params : none
   // trashed: r0
   // cycles:  3

   .CODESEGMENT MATH_PM;
   .DATASEGMENT DM;

$reset_rng:
   r0 = &$math.RAND_SEED;
   M[$math.rand_num] =  r0; // re seed RNG

   r0 = $RAND_SEED;
   M[$M.math.rand_memory_cvc.rand_num] = r0; // re seed the CVC RNG
   rts;

.ENDMODULE;


.MODULE $M.memcpy;
   // copy memory
   // params : I4 = src, I0 = dst, r10 = len
   // trashed: r0
   // cycles:  3+N


   .CODESEGMENT MATH_PM;
   .DATASEGMENT DM;

$memcpy:
   M1 = 1;

   // prime
   r0 = M[I4,M1];

   // copy (extra read at end)
   do memcpy_loop;
      r0 = M[I4,M1], M[I0,M1] = r0;
   memcpy_loop:

   rts;

.ENDMODULE;
