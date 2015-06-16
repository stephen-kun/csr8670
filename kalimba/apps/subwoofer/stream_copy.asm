// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.stream_copy
//
// DESCRIPTION:
//   Function to copy data from one buffer into another.
//
// INPUTS:
//   r7 -  data object containing pointers to input and output data.  Also
//         contains the number of samples to process.
//
// OUTPUTS:
//   - none
//
// CPU USAGE:
//   CODE memory:   27  words
//   DATA memory:    0  words (externally defined in data object)
// *****************************************************************************
#include "core_library.h"
#include "stream_copy.h"
.MODULE $M.stream_copy;
 .codesegment MUSIC_EXAMPLE_STREAMCOPY_PM;
$stream_copy:

// get data from data object
   I3 = r7;
   M1 = 1;
   r0 = M[I3, M1];
   I0 = r0,   r0 = M[I3,M1];  // INPUT_CH1_PTR_BUFFER_FIELD
   L0 = r0,   r0 = M[I3,M1];  // INPUT_CH1_CIRCBUFF_SIZE_FIELD
   I4 = r0,   r0 = M[I3,M1];  // INPUT_CH2_PTR_BUFFER_FIELD
   L4 = r0,   r0 = M[I3,M1];  // INPUT_CH2_CIRCBUFF_SIZE_FIELD
   I1 = r0,   r0 = M[I3,M1];  // OUTPUT_CH1_PTR_BUFFER_FIELD
   L1 = r0,   r0 = M[I3,M1];  // OUTPUT_CH1_CIRCBUFF_SIZE_FIELD
   I5 = r0,   r0 = M[I3,M1];  // OUTPUT_CH2_PTR_BUFFER_FIELD
   L5 = r0,   r0 = M[I3,M1];  // OUTPUT_CH2_CIRCBUFF_SIZE_FIELD
   r10 = r0;                  // NUM_SAMPLES

// ADC-> SCO OUT  : SCO IN -> DAC
   do loop_copy_data;
      r0 = M[I0,1], r2 = M[I4,1];
      M[I1,1] = r0, M[I5,1] = r2;
   loop_copy_data:

// Update data object
   I3 = r7;
   M2 = 2;
   r0 = I0;
   r0 = I4,  M[I3,M2] = r0;   // INPUT_CH1_PTR_BUFFER_FIELD
   r0 = I1,  M[I3,M2] = r0;   // INPUT_CH2_PTR_BUFFER_FIELD
   r0 = I5,  M[I3,M2] = r0;   // OUTPUT_CH1_PTR_BUFFER_FIELD
             M[I3,M2] = r0;   // OUTPUT_CH2_PTR_BUFFER_FIELD

// Clear L registers
   L0 = 0;
   L1 = 0;
   L4 = 0;
   L5 = 0;
   rts;
.ENDMODULE;
