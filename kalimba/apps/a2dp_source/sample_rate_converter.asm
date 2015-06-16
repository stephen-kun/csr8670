// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2005)        http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************

#include "stack.h"
#include "src.h"
#include "core_library.h"

// **********************************************************************************************
// NAME:
//    Sample Rate Converter
//
// DESCRIPTION:
//  used for integer and fractional rate conversion,
//  fractional has been tested only for down conversion
//
// ***********************************************************************************************
.MODULE $src;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

// defining flash segment, flash data is used to store filter coefficients for different rates
#ifdef SRC_DEBUG_ON
 .VAR amount_used;
 .VAR amount_generated;
#endif

// include coefficients for the sample rate converter
// the computational complexity is (plus some overhead):
//									nch*FO*FILTER_LEN for integer ratios (16, 24 and 32 khz output)
//									2*nch*FO*FILTER_LEN for fractional ratios (44.1 and 22.05 khz output)
// FILTER_LEN is 64, and therefore for 44.1khz the computation for two channels is about 13.5MIPS
// you can include src_coefficients_lowcomplexity.asm here to use  FILTER_LEN=42 and reduce the complexity
// the price is reducing your cut-off frequency
#ifndef LOW_COMPLEXITY_SRC_FILTER
#include "src_coefficients.asm"
#else
#include "src_coefficients_lowcomplexity.asm"
#endif

.ENDMODULE;

// ************************************************************************************************************************************
// MODULE:
//    $src.upsample_downsample
//
// DESCRIPTION:
//    upsampling and downsamling by integer ratio
//
//
// INPUTS:
//    - r8 = pointer to $src.upsample_downsample structure
//           or a port identifier (for ports)
//
//  INPUT_1_CBUFFER_FIELD            cbuffer containing left input
//  INPUT_2_CBUFFER_FIELD            cbuffer containing Right input (if mono set to zero)
//  OUTPUT_1_CBUFFER_FIELD           cbuffer containing left output
//  OUTPUT_2_CBUFFER_FIELD           buffer containing right output (if mono set to zero)
//  FILTER_COEFFS_FIELD	             buffer address containing anti aliasing filter coeffs (length = L*COEFFSIZE_FIELD)
//  HIST1_BUF_FIELD                  history circular buffer for left channel, history buffer size size must be at least COEFFSIZE_FIELD
//  HIST2_BUF_FIELD                  history circular buffer for right channel (set zero if mono)
//  COEFFSIZE_FIELD                  length of anti-aliasing filter
//  DECIMATION_RATE_FIELD            decimation factor (M)
//  UPSAMPLE_RATE_FIELD              upsampling rate (L)
//  INV_RATIO_INT_FIELD              int(M/L)
//  INV_RATIO_FRAC_FIELD             frac(M/L)
//  INV_DOWN_RATIO_FIELD             1.0/M.0
//
//
//
// OUTPUTS:
//    - None
//
// TRASHED REGISTERS:
//    everything
//
// NOTES:
//
// ***********************************************************************************************************************************

.MODULE $M.src.upsample_downsample;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
 $src.upsample_downsample:

 $push_rLink_macro;

#ifdef DEBUG_ON
    // start profiling if enabled
   .VAR/DM1 $src.profile_upsample_downsample[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED;

    r0 = &$src.profile_upsample_downsample;
    call $profiler.start;

#endif

#ifdef SRC_DEBUG_ON
   M[$src.amount_used] = 0;
   M[$src.amount_generated] = 0;
#endif

  // check if enough data in input cbuffers to start
  r0 = M[r8 + $src.upsample_downsample.INPUT_1_CBUFFER_FIELD];
  call $cbuffer.calc_amount_data;
  r5 = r0;

  // check the right channel
  r0 = M[r8 + $src.upsample_downsample.INPUT_2_CBUFFER_FIELD];
  if Z jump no_input_right_channel;
  call $cbuffer.calc_amount_data;
  Null = r0 - r5;
  if NEG r5 = r0;

no_input_right_channel:
  Null = r5 - $src.MINIMUM_INPUT_SAMPLES;
  if NEG jump end;

  // check if enough space at the left output cbufer
  r0 = M[r8 + $src.upsample_downsample.OUTPUT_1_CBUFFER_FIELD];
  call $cbuffer.calc_amount_space;
  r6 = r0;

  // check if enough space at the right output cbufer
  r0 = M[r8 + $src.upsample_downsample.OUTPUT_2_CBUFFER_FIELD];
  if Z jump no_output_right_channel;
  call $cbuffer.calc_amount_space;
  Null = r0 - r6;
  if NEG r6 = r0;
no_output_right_channel:

  r4 = M[r8 + $src.upsample_downsample.INV_RATIO_INT_FIELD];
  r1 = r4*r6(int);
  r4 = M[r8 + $src.upsample_downsample.INV_RATIO_FRAC_FIELD];
  r0 = r4*r6(frac);
  r0 = r0 + r1;
  Null = r0 - $src.MINIMUM_INPUT_SAMPLES;
  if NEG jump end;

  r1 = r0 - r5;
  if POS r0 = r0 - r1;


  r1 = M[r8 + $src.upsample_downsample.INV_DOWN_RATIO_FIELD];
  r0 = r1 * r0 (frac);
  r0 = r0 - 1;

  // get conversion ratios
  r6 = M[r8 + $src.upsample_downsample.UPSAMPLE_RATE_FIELD];
  M2 = -r6;
  r5 = M[r8 + $src.upsample_downsample.DECIMATION_RATE_FIELD];
  // now M2 = -UP Ratio, R5 = Down Ratio

  // calculate Loop count
  r10 = r0 * r5 (int);
  r10 = r10 * r6 (int);
#ifdef SRC_DEBUG_ON
   r1 = r0 * r6 (int);
   M[$src.amount_generated] = r1;
   r1 = r0 * r5 (int);
   M[$src.amount_used] = r1;
#endif

  // coefficient size
  r4 = M[r8 + $src.upsample_downsample.COEFFSIZE_FIELD];
  L0 = r4;

  // get the history
  r0 = M[r8 + $src.upsample_downsample.HIST1_BUF_FIELD];
  I0 = r0;

  // get the coeffs addr
  r0 = M[r8 + $src.upsample_downsample.FILTER_COEFFS_FIELD];
  r1 = r4*r6(int);
  // I3 is now pointer to the end of coefficient table
  I3 = r0 + r1;

  // save amount to use
  M1 = r10;

  //first channel
  r3 = 0;


  // get the offset to the read buffer to use
  r0 = M[r8 + $src.upsample_downsample.INPUT_1_CBUFFER_FIELD];
  I2 = r0;

  // get the offset to the first write buffer to use
  r0 = M[r8 + $src.upsample_downsample.OUTPUT_1_CBUFFER_FIELD];
  I6 = r0;


run:
   // get the input buffer read address
   r0 = I2;
   call $cbuffer.get_read_address_and_size;
   I5 = r0;
   L5 = r1;



   // get the output buffer write address
   r0 = I6;
   call $cbuffer.get_write_address_and_size;
   I1 = r0;
   L1 = r1;

   // r6: up counter
   // r7: down counter
   r6 = 1;
   r7 = 1;

   M0 = M1;
   M3 = 1;
   loop_upsample_downsample:

       // see if it is the time to feed another sample into history buffer
       r6 = r6 - 1;
	   if GT jump no_feeding;
	   // feed the sample
	   r6 = r6 - M2, r0 = M[I5, 1];
	   M[I0, 1] = r0;

   no_feeding:
       // see if it is the time to compute an output sample
       r7 = r7 -1;
	   if GT jump no_computing;


       // I3 points to the end of coeffs
	   // starts from the right coeff
	   I4 = I3 - r6 ;

       // compute the sample, please note this is not
	   // poly-phase implementation of downsampler,
	   // when up ratio is not 1, a 1/UP_RATIO loss will occur
	   // it must be compensated either after this process or in coeffs
       r10 = L0 - 1;
	   rMAC = 0, r1 = M[I0,M3], r2 = M[I4,M2];
	   do fir_loop;
		 rMAC = rMAC + r1 * r2, r1 = M[I0,M3], r2 = M[I4,M2];
	   fir_loop:
	   rMAC = rMAC + r1 * r2;
	    r7 = r7 + r5, M[I1, 1] = rMAC;
   no_computing:

	   M0 = M0 - 1;
	   if GT jump loop_upsample_downsample;

       // store history index for next time
	   r1 = r8 + r3;
       r0 = I0;
	   M[r1 + $src.upsample_downsample.HIST1_BUF_FIELD] = r0;

       // update read pointer of input cbuffer
       r0 = I2;
	   r1 = I5;
	   call $cbuffer.set_read_address;

       // update write pointer of output cbuffer
       r0 = I6;
	   r1 = I1;
	   call $cbuffer.set_write_address;


	 // if right channel the exit
     Null = r3;
	 if GT jump finished;


	 // get the offset to the read buffer to use
	 r0 = M[r8 + $src.upsample_downsample.INPUT_2_CBUFFER_FIELD];
	 // if no right channel exit
	 if Z jump finished;
	 // set up the process for right channel
	 I2 = r0;

     // get the offset to the first write buffer to use
     r0 = M[r8 + $src.upsample_downsample.OUTPUT_2_CBUFFER_FIELD];
     I6 = r0;
     // get the history
	 r1 = M[r8 + $src.upsample_downsample.HIST2_BUF_FIELD];
     I0 = r1;

     // second channel
     r3 = 1;
     jump run;


finished:
   L5 = 0;
   L1 = 0;
   L0 = 0;


end:
#ifdef DEBUG_ON
   // stop profiling if enabled
    r0 = &$src.profile_upsample_downsample;
    call $profiler.stop;
#endif

// pop rLink from stack
jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $src.fractional_resample
//
// DESCRIPTION:
//    fractional downsamling by integer ratio
//
//
// INPUTS:
//    - r8 = pointer to $src.upsample_downsample structure
//           or a port identifier (for ports)
//
//  INPUT_1_CBUFFER_FIELD            cbuffer containing left input
//  INPUT_2_CBUFFER_FIELD            cbuffer containing right input (if mono set to zero)
//  OUTPUT_1_CBUFFER_FIELD           cbuffer containing left output
//  OUTPUT_2_CBUFFER_FIELD           buffer containing right output (if mono set to zero)
//  FILTER_COEFFS_FIELD	             buffer address containing anti aliasing filter coeffs (length = L*COEFFSIZE_FIELD)
//  HIST1_BUF_FIELD                  history circular buffer for left channel, history buffer size size must be at least COEFFSIZE_FIELD
//  HIST2_BUF_FIELD                  history circular buffer for right channel (set zero if mono)
//  COEFFSIZE_FIELD                  lenght of anti aliasing filter
//  ROUT_FIELD            			 FO/gcd(FI, FO)
//  UPSAMPLE_RATE_FIELD              upsampling rate (L)
//  INV_RATIO_INT_FIELD              int(FI/FO)
//  INV_RATIO_FRAC_FIELD             frac(FI/FO)
//  INV_DOWN_RATIO_FIELD             FO/FI.0
//
//
//
// OUTPUTS:
//    - None
//
// TRASHED REGISTERS:
//    everything
//
// NOTES:
//
// *****************************************************************************

.MODULE $M.src.fractional_resample;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
 $src.fractional_resample:

 $push_rLink_macro;

#ifdef DEBUG_ON
    // start profiling if enabled
   .VAR/DM1 $src.profile_fractional_resample[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED;
    r0 = &$src.profile_fractional_resample;
    call $profiler.start;
#endif

#ifdef SRC_DEBUG_ON
   M[$src.amount_used] = 0;
   M[$src.amount_generated] = 0;
#endif

  // check if enough data in input cbuffer to start
  // left channel
  r0 = M[r8 + $src.upsample_downsample.INPUT_1_CBUFFER_FIELD];
  call $cbuffer.calc_amount_data;
  r4 = r0;

  //right channel
  r0 = M[r8 + $src.upsample_downsample.INPUT_2_CBUFFER_FIELD];
  if Z jump no_input_right_channel;
  call $cbuffer.calc_amount_data;
  Null = r0 - r4;
  if NEG r4 = r0;

no_input_right_channel:
  //calc amount output
  r5 = M[r8 + $src.upsample_downsample.INV_DOWN_RATIO_FIELD];
  r5 = r4*r5(frac);
  r0 = M[r8 + $src.upsample_downsample.INV_DOWN_RATIO_INT_FIELD];
  r0 = r0 * r4 (int);
  r5 = r5 + r0;
  Null = r5 - $src.MINIMUM_OUTPUT_SAMPLES;
  if NEG jump end;

  // check if enough space at the left output cbufer
  r0 = M[r8 + $src.upsample_downsample.OUTPUT_1_CBUFFER_FIELD];
  call $cbuffer.calc_amount_space;
  r4 = r0;

  // check if enough space at the right output cbufer
  r0 = M[r8 + $src.upsample_downsample.OUTPUT_2_CBUFFER_FIELD];
  if Z jump no_output_right_channel;
  call $cbuffer.calc_amount_space;
  Null = r0 - r4;
  if NEG r4 = r0;

no_output_right_channel:
  Null = r4 - $src.MINIMUM_OUTPUT_SAMPLES;
  if NEG jump end;

  r1 = r4 - r5;
  if POS r4 = r4 - r1;
  //M1 number of output samples to generate
  M1 = r4 - 1;
#ifdef SRC_DEBUG_ON
   r0 = M1;
   M[$src.amount_generated] = r0;
#endif

  //get the interpolation rate
  r6 = M[r8 + $src.upsample_downsample.UPSAMPLE_RATE_FIELD];
  M2 = -r6;


  //coefficient size
  r4 = M[r8 + $src.upsample_downsample.COEFFSIZE_FIELD];


 // get the coeffs addr
  r0 = M[r8 + $src.upsample_downsample.FILTER_COEFFS_FIELD];
  r1 = r4*r6(int);
  // I3 is now pointer to the end of coefficient table
  I3 = r0 + r1;



  //hist buff1
  r0 = M[r8 + $src.upsample_downsample.HIST1_BUF_FIELD];
  I0 = r0;
  L0 = r4;
  L1 = r4;

  //get first channel input info
  r0 = M[r8 + $src.upsample_downsample.INPUT_1_CBUFFER_FIELD];
  call $cbuffer.get_read_address_and_size;
  I4 = r0;
  L4 = r1;


  //get first channel output info
  r0 = M[r8 + $src.upsample_downsample.OUTPUT_1_CBUFFER_FIELD];
  call $cbuffer.get_write_address_and_size;
  I5 = r0;
  L5 = r1;


  r4 = M[r8 + $src.upsample_downsample.RF];
  r7 = M[r8 + $src.upsample_downsample.OUT_COUNTER];
  r5 = M[r8 + $src.upsample_downsample.INV_RATIO_FRAC_FIELD];




  M3 = 1;
  M0 = M1;

   //in this loop
   //r6: upsample rate
   //M2= -r6
   //I0, L0: hist buff
   //I4, L4: input
   //I5, L5: output
   //r4: rf
   //r7: ry
   //r5: aF
   .VAR chn_no;
   M[chn_no] =0;
#ifdef SRC_DEBUG_ON
    M[$src.amount_used] = 0;
#endif
 fractional_gen_loop:

     // get number of samples to feed into history
     r10 = M[r8 + $src.upsample_downsample.INV_RATIO_INT_FIELD];

     // check if an extra sample needs to feed
     r4 = r4 + r5;
	 if NEG jump no_extra_copy;
        r10 = r10 + 1;
        r4 = r4 - (-1.0);
   no_extra_copy:

#ifdef SRC_DEBUG_ON
   r0 = M[$src.amount_used];
   M[$src.amount_used] = r0 + r10;
#endif
     // feed samples into history buffer
     do cploop;
        r0 = M[I4, 1];
	    M[I0, 1] = r0;
    cploop:

    // input is upsampled by rate=r6, find the best points to interpolate
    rMAC = r4*r6;       // r6=uprate r4=fraction
    r3 = rMAC0;
	r3 = r3 LSHIFT -1; // r3 = interpolation ratio
    r2 = rMAC1;        // r0 = index of first point


    // FIR filtering starts from right side of coeffs
    I6 = I3 + r2 ;

    // compute first point to interpolate later on
    // when up ratio is not 1, a 1/UP_RATIO loss will occur
    // it must be compensated either in data or in coeffs(preferable)
    r10 = L0 - 1;
	rMAC = 0, r0 = M[I0,M3], r1 = M[I6,M2];
	do fir_loop1;
		  rMAC = rMAC + r0 * r1, r0 = M[I0,M3], r1 = M[I6,M2];
	fir_loop1:
	rMAC = rMAC + r0 * r1;

    //calculate second point
	I1 = I0;
	r1 = r2 + 1;
	//if first point index is (r6-1) then to calculate next point and extra load is required
	if NEG jump no_extra_load;
	 // load an extra point
	 r2 = M[I4, 0];
	 r1 = -r6, M[I1, M3] = r2;
    no_extra_load:


	// save result from first point
	r2 = rMAC*r3(frac);
	r2 = rMAC -r2;

	// calculate second point
	I6 = I3 + r1 ;
    r10 = L0 - 1;
	rMAC = 0, r0 = M[I1,M3], r1 = M[I6,M2];
	do fir_loop2;
	   rMAC = rMAC + r0 * r1, r0 = M[I1,M3], r1 = M[I6,M2];
	fir_loop2:
	rMAC = rMAC + r0 * r1;

	// linear interpolation between two adjacent points
	rMAC = rMAC * r3;
   rMAC = rMAC + r2*1.0;

	// save final computed sample
    r7 = r7 - M3, M[I5, M3] = rMAC;
	if GT jump no_reset;
       r7 = M[r8 + $src.upsample_downsample.ROUT_FIELD];
       r4 = -1.0;
	no_reset:

    M0 = M0 - 1;
	if GT  jump  fractional_gen_loop;

    // store history index for next time
	r3 = r8 + M[chn_no];
	r0 = I0;
	M[r3 + $src.upsample_downsample.HIST1_BUF_FIELD] = r0;

    //update read pointer of input cbuffer
    r0 = M[r3 + $src.upsample_downsample.INPUT_1_CBUFFER_FIELD];
	r1 = I4;
	call $cbuffer.set_read_address;

    // update write pointer of output cbuffer
    r0 = M[r3 + $src.upsample_downsample.OUTPUT_1_CBUFFER_FIELD];
	r1 = I5;
	call $cbuffer.set_write_address;

    // finish if this was second channel
    r0 = M[chn_no];
	if NZ jump finished;

	// finish if no left channel available
    r0 = M[r8 + $src.upsample_downsample.INPUT_2_CBUFFER_FIELD];
	if Z jump finished;

    //hist buff2
    r0 = M[r8 + $src.upsample_downsample.HIST2_BUF_FIELD];
    I0 = r0;


    //get first channel input info
    r0 = M[r8 + $src.upsample_downsample.INPUT_2_CBUFFER_FIELD];
    call $cbuffer.get_read_address_and_size;
    I4 = r0;
    L4 = r1;


    //get first channel output info
    r0 = M[r8 + $src.upsample_downsample.OUTPUT_2_CBUFFER_FIELD];
    call $cbuffer.get_write_address_and_size;
    I5 = r0;
    L5 = r1;
    M0 = M1;
	r0 = 1;
	M[chn_no] = r0;
	r4 = M[r8 + $src.upsample_downsample.RF];
    r7 = M[r8 + $src.upsample_downsample.OUT_COUNTER];
	jump fractional_gen_loop;

finished:
   M[r8 + $src.upsample_downsample.RF] = r4;
   M[r8 + $src.upsample_downsample.OUT_COUNTER] = r7;
   L5 = 0;
   L4 = 0;
   L0 = 0;
   L1 = 0;

end:
#ifdef DEBUG_ON
   // stop profiling if enabled
    r0 = &$src.profile_fractional_downsample;
    call $profiler.stop;
#endif

// pop rLink from stack
jump $pop_rLink_and_rts;
.ENDMODULE;
