// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1172207 $  $DateTime: 2011/12/09 20:46:31 $
// *****************************************************************************

#include "stack.h"
#include "cbops.h"
#include "iir_resamplev2_header.h"

// *****************************************************************************
// NAME:
//    IIR resampler
//
// DESCRIPTION:
//    These are the core modules for the IIR resampler
//      $reset_iir_resampler     - reset resampler stage
//      $iir_1stStage_upsample   - process 6th order FIR only upsample stage
//      $iir_2ndStage_upsample   - process 10th order FIR plus IIR upsample stage
//      $iir_2ndStage_downsample - process 10th order FIR plus IIR downsample stage
//
//    For each IIR filter there is a processing and a count function.  The count function
//    must be 'IIR_COUNT_FUNCTION_OFFSET' instructions before the processing function.
//    Supported IIR filters are as follows:
//      $iir_resamplerv2.iir_19_s2 - 19th order (2 stages)
//      $iir_resamplerv2.iir_19_s3 - 19th order (3 stages)
//      $iir_resamplerv2.iir_19_s4 - 19th order (4 stages)
//      $iir_resamplerv2.iir_19_s5 - 19th order (5 stages)
//      $iir_resamplerv2.iir_15_s2 - 15th order (2 stages)
//      $iir_resamplerv2.iir_15_s3 - 15th order (3 stages)
//      $iir_resamplerv2.iir_9_s2  - 9th order (2 stages)
//
// *****************************************************************************

// SP.  Number of instructions of count function before process function
#if defined (KAL_ARCH4) || defined(KAL_ARCH5)
#define IIR_COUNT_FUNCTION_OFFSET   8
#elif defined (KAL_ARCH3) || defined (KAL_ARCH2)
#define IIR_COUNT_FUNCTION_OFFSET   2
#else
// force error if chip not known
#error Unsupported architecture
#endif



// *****************************************************************************
// MODULE:
//    $reset_iir_resampler
//
// DESCRIPTION:
//    Initializes the filter state and clears the IIR history buffer.
//    Fir Gordon and beyond the IIR and FIR history buffers are allocated
//    from the end of the data structure
//
// INPUTS:
//    I2  - State Variable Pointers
//    I3  - Pointer to Filter Stage configuration
//    r4  - Base Address (>= gordon)
//    r2  = 0 (reserved)
//    M0  = 1 (reserved)
//
// OUTPUTS:
//    I2  - State Variable Pointers for next stage
//    I3  - Pointer to Filter Stage configuration for next stage
//    r4  - Base Address (>= gordon) for next stage history buffer
//
// TRASHED REGISTERS:
//    r3,r0,r1,r10,I0,L0,
//
// *****************************************************************************
.MODULE $M.reset_iir_resampler;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$reset_iir_resampler:

   M[I2,M0] = r2;              // Clear Partial input
   r3 = M[I3,M0];              // Get FIR Size
   r0 = M[I3,M0];              // Get IIR Size
   M[I2,M0] = r2;               // Clear Partial input
   M[I2,M0] = r4;               // Set Fir History Ptr
   r4 = r4 + r3;
   r1 = r4, M[I2,M0] = r4;      // Set IIR History Ptr
   r4 = r4 + r0;

   // Advanced I2,I3 to Next Stage
   I3 = I3 + 4;
   // Check if stage has IIR component
   r10 = r0;                    // IIR Length
   if Z rts;
   I0  = r1;                    // IIR History Ptr
   I3 = I3 + 2;
   push rLink,  r1=M[I3,M0];    // IIR Process Function Ptr
   r1 = r1 - IIR_COUNT_FUNCTION_OFFSET;
   call r1;
   I3 = I3 + r1;         
   
   // Clear IIR History
   do clr_loop;
      M[I0,1]=r2;
clr_loop:

   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $iir_1stStage_upsample
//
// DESCRIPTION:
//    Processing 6th order FIR only upsample stage
//
// INPUTS:
//    I1,L1,B1  - Input Buffer
//    I5,L5,B5  - Output Buffer
//    I2  - State Variable Pointers
//           Partial Samples
//           Polyphase Counter
//           FIR History Buffer
//           IIR History Buffer
//    I3  - Pointer to Filter Stage Config
//           FIR Size = 6
//           IIR Size = 0
//           Rout
//           Input Scale
//           FIR Coefficient Base
//           Fractional Ratio
//    r2  - Input Scaling Factor
//    r5  - Output Scaling Factor
//    r10 - amout of input (consumed)
//    FP  - Base Address (>= BC7)
//    M0  = 1   (reserved)
//    r9  = 1.0 (reserved)
//
// OUTPUTS:
//    I2  - State Variable Pointers for next stage
//    I3  - Pointer to Filter Stage configuration for next stage
//    FP  - Base Address (>= BC7) for next stage history buffer
//
// TRASHED REGISTERS:
//    all
//
// MIPS:
//      2*input + 19*output
//
// *****************************************************************************
.MODULE $M.iir_1stStage_upsample;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;

$iir_1stStage_upsample:
   I3 = I3 + 2;                        // Skip FIR & IIR sizes
   r7 = r7 - r7,     r4=M[I3,M0];      // Rout
   M1 = r4,          r1=M[I3,M0];      // input_scale
   r8 = r1 + r2,     r1=M[I3,M0];      // FIR Coefficient Base
   I6 = r1,          r5=M[I3,M0];      // Fractional Ratio
   M2 = NULL - r4;
   // M3 = Coefficient Mirror = (2*base + Rout*6-1)
   r2 = r4 * 6 (int);
   M3 = r2 - M0,     r0=M[I2,M0];      // Partial Input N/A
   M3 = M3 + I6,     r3=M[I2,M0];      // Polyphase Counter
   M3 = M3 + I6,     r0=M[I2,-1];      // FIR History (I2 Points to Polyphase Counter)
   I0 = r0;
   L0 = 6;

   // Set Base Registsers for History Buffers
   push FP;
   pop  B0;
   FP = FP + 6;

   // r3  - Polyphase Counter - [0 ... (Rout-1)]     V
   // r4  - Rout                       C
   // r5  - Fractional Ratio           C
   // r8  - Output Scaling Factor
   // I0  - Fir History  (Circ)        V
   // I3  - Pointer to Config
   // I6  - Fir Coeffs Base Address    C
   // r7  - amount produced
   // M1 = Rout
   // M2 = -Rout
   // M3 = Fir Coefficient Reflection

   // First poly phase Index
   // r1 = mod[ input_sample_counter * convert_ratio, 1]*Rout
   r2 = r3 * r5 (int);
   if NEG  r2 = r2 + r9;
   r1 = r2 * r4 (frac);

   do loop;
      // Loop Through Input
      rMAC = M[I1,M0];                 // Input, Coefficient Ptr
     M[I0,M0] = rMAC;                      // FIR History x(n)
loop_rpt:
      // Coefficient Ptr : Base + phase (r1)
      I7 = I6 + r1;
      // Apply FIR Polyphase Kernal (6th order)
      r3 = r3 + M0,           r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 1
      rMAC = r1 * r2,         r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 2
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];
     // invert the M reg to perform coef mirroring
      I7 = M3 - I7;
     // Coef 3
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 4
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 5
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 6
      rMAC = rMAC + r1 * r2;

      // Apply Output Scaling
      r1 = rMAC ASHIFT r8;

      // Amount Produced
      r7 = r7 + M0,     M[I5,M0] = r1;

      // r3 = mod(input_sample_counter,Rout)
      Null = r3 - r4;
      if GE r3 = r3 - r3;
      // r2 = mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int);
      if NEG r2 = r2 + r9;
      // Polyphase index (r1)
      r1 = r2 * r4 (frac);

      // reprocess last sample (i.e. upsample)
      Null = r5 - r2;
      if LE jump loop_rpt;
      // Can't Have Jump at end of loop
      nop;
   loop:

      // Update State
      r0 = I0,    M[I2,M0]=r3;    // Save Polyphase Counter
      L0 =NULL,   M[I2,M0]=r0;    // Save FIR History
      I2 = I2 + M0;               // Advance over IIR History Ptr

      // Outputs
      //    r7 = output produced
      //    I2 = State Pointer (next filter)
      //    I3 = Config Pointer (next filter)
      //    M0  = 1
      //    r9  = 1.0
      rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $iir_2ndStage_upsample
//
// DESCRIPTION:
//    Processing 10th order FIR plus IIR upsample stage
//
// INPUTS:
//    I1,L1,B1  - Input Buffer
//    I5,L5,B5  - Output Buffer
//    I2  - State Variable Pointers
//           Partial Samples
//           Polyphase Counter
//           FIR History Buffer
//           IIR History Buffer
//    I3  - Pointer to Filter Stage Config
//           FIR Size = 10
//           IIR Size
//           Rout
//           input scale
//           output scale
//           FIR Coefficient Base
//           Fractional Ratio
//           Integer ratio (not used = 0)
//           IIR Function Pointer
//           IIR coefficients and scaling factors
//    r2  - Input Scaling Factor
//    r5  - Output Scaling Factor
//    r10 - amout of input (consumed)
//    FP  - Base Address (>= BC7)
//    M0  = 1   (reserved)
//    r9  = 1.0 (reserved)
//
// OUTPUTS:
//    I2  - State Variable Pointers for next stage
//    I3  - Pointer to Filter Stage configuration for next stage
//    FP  - Base Address (>= BC7) for next stage history buffer
//
// TRASHED REGISTERS:
//    all
//
// MIPS:
//      2*input + (31+IIR order)*output    : IIR order = 9,15,or 19
//
// *****************************************************************************
.MODULE $M.iir_2ndStage_upsample;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;

$iir_2ndStage_upsample:
   $push_rLink_macro;

   I3 = I3 + M0;                       // Skip FIR size
   r7 = r7 - r7,     r1=M[I3,M0];      // IIR Size
   // Set Base Registsers for History Buffers
   push FP;
   pop  B0;
   FP = FP + 10;
   push FP;
   pop  B4;
   FP = FP + r1;

   L4 = r1,          r4=M[I3,M0];      // Rout
   M1 = r4,          r1=M[I3,M0];      // input_scale
   r6 = r1 + r2,     r1=M[I3,M0];      // output_scale
   r8 = r1 + r5,     r1=M[I3,M0];      // FIR Coefficient Base
   I6 = r1,          r5=M[I3,M0];      // Fractional Ratio
   M2 = NULL - r4,   r0=M[I2,M0];      // Partial Samples  (NA)
   // M3 = Coefficient Mirror = (2*base + Rout*10-1)
   r2 = r4 * 10 (int);
   push I2;
   M3 = r2 - M0,     r3=M[I2,M0];      // Polyphase Counter
   M3 = M3 + I6,     r1=M[I2,M0];      // Fir History
   M3 = M3 + I6,     r2=M[I2,M0];      // IIR History
   I0 = r1,          r0=M[I3,M0];      // Integer ratio
   I4 = r2,          r0=M[I3,M0];      // IIR Function Pointer
   L0 = 10;

   // r7  - amount produced
   // r0  - IIR Function Pointer
   // r5  - Fractional Ratio           C
   // r4  - Rout                       C
   // r6  - Input Scaling Factor
   // r8  - Output Scaling Factor
   // I6  - Fir Coeffs Base Address    C
   // M1 = Rout
   // M2 = -Rout
   // M3 = Fir Coefficient Reflection
   // I0  - Fir History  (Circ)        V
   // I4  - IIR History (Circ)         V
   // r3  - Polyphase Counter - [0 ... (Rout-1)]     V

   // First phase (poly phase)
   // r1 = mod[ input_sample_counter * convert_ratio, 1]*Rout
   r2 = r3 * r5 (int);
   if NEG  r2 = r2 + r9;
   r1 = r2 * r4 (frac);

   // Note: Put loop in function
   do loop;
      // Loop Through Input
      rMAC = M[I1,M0];          // Input, Coefficient Ptr
      M[I0,M0] = rMAC;          // FIR History x(n)
loop_rpt:
      // Coefficient Ptr : base + phase (r1)
      I7 = I6 + r1;
      // Apply FIR Polyphase Kernal (10th order)
      r3 = r3 + M0,           r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 1
      rMAC = r1 * r2,         r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 2
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 3
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];
      // Coef 4
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];
       // invert the M reg to perform coef mirroring
      I7 = M3 - I7;
      // Coef 5
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 6
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 7
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 8
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 9
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];
      // Coef 10
      rMAC = rMAC + r1 * r2;

      // Apply IIR
      I2 = I3;
      call r0;             // Handle IIR,

      // Apply Output Scaling Factor
      rMAC = rMAC ASHIFT r8,  M[I4,M0] = rMAC;   // History y(n)
      //increment counter write the result
      r7 = r7 + M0,           M[I5,M0] = rMAC;

      // r3 = mod(input_sample_counter,Rout)
      Null = r3 - r4;
      if GE r3 = r3 - r3;
      // rb = mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int);
      if NEG  r2 = r2 + r9;
      // Polohase Index
      r1 = r2 * r4 (frac);

      // reprocess last sample (i.e. upsample)
      Null = r5 - r2;
      if LE jump loop_rpt;
      // Can't have jump at end of loop
      nop;
   loop:

   // Update State
   I3 = I2;
   pop I2;
   r0 = I0,    M[I2,M0]=r3;      // Polyphase Counter
   r0 = I4,    M[I2,M0]=r0;      // FIR History
   L0 = NULL,  M[I2,M0]=r0;      // IIR History
   L4 = NULL;

   // Outputs
   //    r7 = output produced
   //    I2 = State Pointer (next filter)
   //    I3 = Config Pointer (next filter)
   //    M0  = 1
   //    r9  = 1.0

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_2ndStage_downsample
//
// DESCRIPTION:
//    Processing 10th order FIR plus IIR downsample stage
//
// INPUTS:
//    I1,L1,B1  - Input Buffer
//    I5,L5,B5  - Output Buffer
//    I2  - State Variable Pointers
//           Partial Samples
//           Polyphase Counter
//           FIR History Buffer
//           IIR History Buffer
//    I3  - Pointer to Filter Stage Config
//           FIR Size = 10
//           IIR Size
//           Rout
//           input scale
//           output scale
//           FIR Coefficient Base
//           Fractional Ratio
//           Integer ratio (not used = 0)
//           IIR Function Pointer
//           IIR coefficients and scaling factors
//    r2  - Input Scaling Factor
//    r5  - Output Scaling Factor
//    r10 - amout of input (consumed)
//    FP  - Base Address (>= BC7)
//    M0  = 1   (reserved)
//    r9  = 1.0 (reserved)
//
// OUTPUTS:
//    I2  - State Variable Pointers for next stage
//    I3  - Pointer to Filter Stage configuration for next stage
//    FP  - Base Address (>= BC7) for next stage history buffer
//
// TRASHED REGISTERS:
//    all
//
// MIPS:
//     (10 + IIR Order)*input + 27*output     : IIR order = 9,15,or 19
//
// *****************************************************************************
.MODULE $M.iir_2ndStage_downsample;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;

$iir_2ndStage_downsample:

   $push_rLink_macro;

   I3 = I3 + M0;                       // Skip FIR size
   r7 = r7 - r7,     r1=M[I3,M0];      // IIR Size
   // Set Base Registsers for History Buffers
   push FP;
   pop  B0;
   FP = FP + 10;
   push FP;
   pop  B4;
   FP = FP + r1;

   L4 = r1,          r4=M[I3,M0];      // Rout
   M1 = r4,          r1=M[I3,M0];      // input_scale
   r6 = r1 + r2,     r1=M[I3,M0];      // output_scale
   r8 = r1 + r5,     r1=M[I3,M0];      // FIR Coefficient Base
   I6 = r1;
   push I2;
   M2 = NULL - r4,   r1=M[I2,M0];      // Partial Count
   // M3 = Coefficient Mirror = (2*base + Rout*10-1)
   r2 = r4 * 10 (int);
   M3 = r2 - M0,     r3=M[I2,M0];      // polyphase counter
   M3 = M3 + I6;
   M3 = M3 + I6,     r0=M[I2,M0];      // FIR History
   I0=r0,            r0=M[I2,M0];      // IIR History
   I4=r0;
   L0=10;

   // r1  - partial input
   // r0  - Integer Ratio              C
   // r3  - Polyphase Counter - [0 ... (Rout-1)]
   // r5  - Fractional Ratio           C
   //     - IIR Function Pointer       C
   // r4  - Rout                       C
   // r6  - Input Scaling Factor
   // r8  - Output Scaling Factor
   // I6  - Fir Coeffs Base Address    C
   // r7  - amount consumed
   // I0  - Fir History  (Circ)
   // I3  - Pointer to Config
   // I4  - IIR History (Circ)
   // M1 = Rout
   // M2 = -Rout
   // M3 = Fir Coefficient Reflection

   // modulous sample counter
   Null = r3 - r4,         r5 = M[I3,M0];    // Frac_ratio
   if GE r3 = r3 - r3;
   // mod[ input_sample_counter * convert_ratio, 1]
   r2 = r3 * r5 (int),     r0 = M[I3,M0];    // Int_ratio
   if NEG r2 = r2 + r9;
   // Adjust Number of input samples per output sample
   Null = r5 - r2,         r5 = M[I3,M0];    // IIR Function Pointer
   if GT r0 = r0 + M0;
   // Reduce required input samples by amount already processed (i.e. partial)
   NULL = r1;
   if NZ r0=r1;

   // Check fo sufficient input
   r10 = r10 - r0;
   if NEG jump insufficient_data;

   // loop to generate output
loop:
      // Polyphase index (r1)
      r1 = r2 * r4 (frac);
      // Coefficient Ptr : base + phase (r1)
      I7 = I6 + r1;

      read_input:
          I2 = I3,      rMAC = M[I1,M0];                    // Get Input
          call   r5;                                        // Handle IIR
          r0 = r0 - M0, M[I0,M0] = rMAC, M[I4,M0] = rMAC;   // IIR history y(n),  FIR history x(n)
      if NZ jump read_input;

      // Apply FIR Polyphase Kernal (10th order)
      r3 = r3 + M0,           r1 = M[I7,M1], r2 = M[I0,M0];     // y(n-9)
      // Coef 1
      rMAC = r1 * r2,         r1 = M[I7,M1], r2 = M[I0,M0];     // y(n-8)
      // Coef 2
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];     // y(n-7)
      // Coef 3
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];     // y(n-6)
      // Coef 4
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M1], r2 = M[I0,M0];     // y(n-5)
      // invert the M reg to perform coef mirroring
      I7 = M3 - I7;
      // Coef 5
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];     // y(n-4)
      // Coef 6
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];     // y(n-3)
      // Coef 7
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];     // y(n-2)
      // Coef 8
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];     // y(n-1)
      // Coef 9
      rMAC = rMAC + r1 * r2,  r1 = M[I7,M2], r2 = M[I0,M0];     // y(n-0)
      // Coef 10
      rMAC = rMAC + r1 * r2;

      // Apply Output Scaling Factor
      r1 = rMAC ASHIFT r8;
      //write the result, Reset I2 to point to int_ratio
      R7 = R7 + M0,     M[I5,M0] = r1;
      I3 = I3 - 3;

      // modulous sample counter
      Null = r3 - r4,         r5 = M[I3,M0];    // Frac_ratio
      if GE r3 = r3 - r3;
      // mod[ input_sample_counter * convert_ratio, 1]
      r2 = r3 * r5 (int),     r0 = M[I3,M0];    // Int_ratio
      if NEG r2 = r2 + r9;
      // Adjust Number of input samples per output sample
      Null = r5 - r2,         r5 = M[I3,M0];    // IIR Function Pointer
      if GT r0 = r0 + M0;

      // Check fo sufficient input
      r10 = r10 - r0;
      if POS jump loop;

insufficient_data:
      // r10 < 0 amount of insufficient input
      // r0 is amount of input required per output
      r4 = r0 + r10;
      if Z jump done;
      r0 = r4;
      r4 = NULL-r10;
      read_input_end:
          I2 = I3,      rMAC = M[I1,M0];                    // Get Input
          call   r5;                                    // Handle IIR
          r0 = r0 - M0, M[I0,M0] = rMAC, M[I4,M0] = rMAC;   // IIR history y(n),  FIR history x(n)
      if NZ jump read_input_end;

done:

   // Update State
   I3=I2;
   pop I2;
   L0=NULL,    M[I2,M0]=r4;      // Partial input
   r0=I0,      M[I2,M0]=r3;      // polyphase count
   r0=I4,      M[I2,M0]=r0;      // FIR History
   L4=NULL,    M[I2,M0]=r0;      // IIR History

   // Outputs
   //    r7 = output produced
   //    I2 = State Pointer (next filter)
   //    I3 = Config Pointer (next filter)
   //    M0  = 1
   //    r9  = 1.0
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_19_s2.count
//    $iir_resamplerv2.iir_19_s2
//
// DESCRIPTION:
//    Process 19th order IIR in 2 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*25
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_19_s2;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;

// SP.  Count function must be 2 instructions before process function
$iir_resamplerv2.iir_19_s2.count:
    r1 = 23;    // 19 + 2*2
    rts;
$iir_resamplerv2.iir_19_s2:
   r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-10)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-9)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-8)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-7)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History g(n-9)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-8)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-7)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_19_s3.count
//    $iir_resamplerv2.iir_19_s3
//
// DESCRIPTION:
//    Process 19th order IIR in 3 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*27
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_19_s3;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$iir_resamplerv2.iir_19_s3.count:
    r1 = 25;    // 19 + 3*2
    rts;
$iir_resamplerv2.iir_19_s3:
    r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-7)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History g(n-6)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];     // Scale Factor and History h(n-6)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History g(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_19_s4.count
//    $iir_resamplerv2.iir_19_s4
//
// DESCRIPTION:
//    Process 19th order IIR in 4 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*29
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_19_s4;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$iir_resamplerv2.iir_19_s4.count:
    r1 = 27;    // 19 + 4*2
    rts;
$iir_resamplerv2.iir_19_s4:
    r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History g(n-5)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];     // Scale Factor and History h(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History g(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History u(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History h(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History u(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History u(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History u(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_19_s5.count
//    $iir_resamplerv2.iir_19_s5
//
// DESCRIPTION:
//    Process 19th order IIR in 5 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*31
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_19_s5;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$iir_resamplerv2.iir_19_s5.count:
    r1 = 29;    // 19 + 5*2
    rts;
$iir_resamplerv2.iir_19_s5:
    r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History g(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];     // Scale Factor and History h(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History g(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History u(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History h(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History u(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History u(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History u(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History v(n-3)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History u(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History v(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History v(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_15_s2.count
//    $iir_resamplerv2.iir_15_s2
//
// DESCRIPTION:
//    Process 15th order IIR in 2 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*21
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_15_s2;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$iir_resamplerv2.iir_15_s2.count:
    r1 = 19;    // 15 + 2*2
    rts;
$iir_resamplerv2.iir_15_s2:
    r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-8)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-7)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History g(n-7)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
    rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_15_s3.count
//    $iir_resamplerv2.iir_15_s3
//
// DESCRIPTION:
//    Process 15th order IIR in 3 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*23
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_15_s3;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$iir_resamplerv2.iir_15_s3.count:
    r1 = 21;    // 15 + 3*2
    rts;
$iir_resamplerv2.iir_15_s3:
    r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-6)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History g(n-5)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];      // Scale Factor and History h(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History g(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History h(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
    rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $iir_resamplerv2.iir_9_s2.count
//    $iir_resamplerv2.iir_9_s2
//
// DESCRIPTION:
//    Process 9th order IIR in 2 stages
//
// INPUTS:
//    I4,L4,B4 - iir history  (circ)
//    I2       - descriptor - Scale Factors, Coefficients
//    r6       - input scale
//    rMAC     - input value/output value
///
// OUTPUTS:
//    I2   - State Variable Pointers for next stage
//    rMAC - Filter result
//
// TRASHED REGISTERS:
//    r1,r2
//
// MIPS:
//     rate*15
//
// *****************************************************************************
.MODULE $M.iir_resamplerv2.iir_9_s2;
   .CODESEGMENT IIR_RESAMPLEV2_COMMON_PM;
$iir_resamplerv2.iir_9_s2.count:
    r1 = 13;    // 9 + 2*2
    rts;
$iir_resamplerv2.iir_9_s2:
   r2 = rMAC ASHIFT r6,    r1 = M[I2,M0];                 // Shift Input. Coefficient
   rMAC = r2 * r1,         r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-5)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-4)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-2)
    rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History y(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,0];    // Scale Factor and History g(n-4)
   rMAC = rMAC ASHIFT r1,  r1 = M[I2,M0];
   rMAC = rMAC * r1,       r1 = M[I2,1], M[I4,1]=rMAC;    // Coefficient  and History y(n)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-3)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-2)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1], r2 = M[I4,1];    // Coefficient  and History g(n-1)
   rMAC = rMAC - r2 * r1,  r1 = M[I2,1];              // Scale Factor
   rMAC = rMAC ASHIFT r1;
   rts;

.ENDMODULE;


