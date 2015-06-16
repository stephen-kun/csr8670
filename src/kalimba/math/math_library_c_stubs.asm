// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// C stubs for "math" library
// These obey the C compiler calling convention (see documentation)
// Comments show the syntax to call the routine also see matching header file


.MODULE $M.math_c_stubs;
   .CODESEGMENT PM;

// int sin( int x);
$_sin:
   push rLink;
   push I0;
   call $math.sin;
   r0 = r1;          // TODO optimise: sin to return r0 instead of r1
   pop I0;
   pop rLink;
   rts;

// int sqrt( int x);
$_sqrt:
   pushm <r4, rLink>;
   pushm <I0, M0>;
   call $math.sqrt;
   r0 = r1;          // TODO optimise: sqrt to return r0 instead of r1
   popm <I0, M0>;
   popm <r4, rLink>;
   rts;

// void fft( fft_struc *x);
// note: result is bit reversed
$_fft:
   pushm <r4, r5, r6, r7, r8, r9, rLink>;
   pushm <I0, I1, I2, I4, I5, M0, M1, M2, M3>;
   I7 = r0;
   call $math.fft;
//   r8 = 0.60950;     // !!! 6-bit room for overflow before fft (norm/64)
//   r8 = 1.0;
//   call $math.scaleable_fft;      // !!! add another arg to prototype?
   popm <I0, I1, I2, I4, I5, M0, M1, M2, M3>;
   popm <r4, r5, r6, r7, r8, r9, rLink>;
   rts;

// void bitreverse_array( int *in, int *out, int size);
// note: out must be a circular buffer, size must be power of 2
$_bitreverse_array:
   push rLink;
   pushm <I0, I4, M1, M2>;
   I4 = r0;
   r0 = r1;
   call $math.address_bitreverse;
   I0 = r1;
   r10 = r2;
   call $math.bitreverse_array;
   popm <I0, I4, M1, M2>;
   pop rLink;
   rts;

// int log2( long x);
// input: positive Q1.47 ( 0 <= x < 2 )
// output: Q8.16
// note. possibility for range extention (up to 256?), the asm function takes 56-bit rMAC as input
$_log2:
   push rLink;
   push r6;
   rMAC0 = r1;          // LS
   rMAC12 = r0 (SE);    // MS
   call $math.log2_taylor;
   // note. faster log2_table available (precision?)
   pop r6;
   pop rLink;
   rts;


.ENDMODULE;
