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
// *****************************************************************************
#include "core_library.h"
#include "stream_copy.h"
.MODULE $M.stream_copy;
 .codesegment PM;
$stream_copy:

   push rLink;  
   // Get Input Buffer
   r0  = M[r7 + $stream_copy.INPUT_PTR_BUFFER_FIELD];
#ifdef BASE_REGISTER_MODE  
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B0;
#else
   call $frmbuffer.get_buffer;
#endif
   // r0 = buf ptr
   // r1 = circ buf length
   // r2 = buffer base address <base variant only>
   // r3 = frame size
   I0  = r0;
   L0  = r1;
      
   // Use input frame size
   r10 = r3;
   // Update output frame size from input
   r0 = M[r7 + $stream_copy.OUTPUT_PTR_BUFFER_FIELD];
   call $frmbuffer.set_frame_size;
   
   // Get output buffer
#ifdef BASE_REGISTER_MODE  
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B4;
#else
   call $frmbuffer.get_buffer;
#endif
   I4 = r0;
   L4 = r1;
   pop rLink;
   

// INPUT->OUTPUT
   r0=M[I0,1]; // first input
   do loop_passthru;
      M[I4,1] = r0, r0=M[I0,1]; // copy
   loop_passthru:

// Clear L registers
   L0 = 0;
   L4 = 0;
#ifdef BASE_REGISTER_MODE  
   push Null;
   B4 = M[SP-1];
   pop  B0;
#endif   
   rts;
.ENDMODULE;
