// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.stream_mix 
//
// DESCRIPTION:
//    This function mixes two streams together using a weighted sum.
//
// INPUTS:
//    r7 - Pointer to the stream mixer data structure
//
// OUTPUTS:
//    none

// *****************************************************************************

#include "stream_mix.h"

.MODULE $M.stream_mix;
    .CODESEGMENT PM;
    
$stream_mix:
   // Pointer to the stream copy data struc
   I2 = r7;    
   M1 = 1;
   
   push rLink;  
   // Get Input Buffers
   r0 = M[I2,M1];                   // OFFSET_INPUT_CH1_PTR
#ifdef BASE_REGISTER_MODE  
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B0;
#else
   call $frmbuffer.get_buffer;
#endif
   // r0 = buf ptr
   // r1 = circ buf length
   // r2 = bbuffer base address <base variant only>
   // r3 = frame size
   I0  = r0;
   L0  = r1,    r0 = M[I2,M1];       // OFFSET_INPUT_CH2_PTR
#ifdef BASE_REGISTER_MODE  
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B1;
#else
   call $frmbuffer.get_buffer;
#endif
   I1  = r0;
   L1  = r1;
   
   // Use input frame size
   r10 = r3,    r0 = M[I2,M1];       // OFFSET_OUTPUT_PTR
   // Update output frame size from input
   call $frmbuffer.set_frame_size;
   
   // Get output buffer
#ifdef BASE_REGISTER_MODE  
   call $frmbuffer.get_buffer_with_start_address;
   push r2;
   pop  B4;
#else
   call $frmbuffer.get_buffer;
#endif
   I4 = r0,    r4 = M[I2,M1];       // OFFSET_PTR_CH1_MANTISSA
   L4 = r1,    r5 = M[I2,M1];       // OFFSET_PTR_CH2_MANTISSA
   pop rLink;
                                   
   r4 = M[r4], r2 = M[I2,M1];       // OFFSET_PTR_EXPONENT                   
   // r0 = first input ch1                      
   r5 = M[r5], r0 = M[I0,M1];       // first sample CH1               
   // r1 = first input ch2
   r6 = M[r2], r1 = M[I1,M1];       // first sample CH2       
   
   // Sum & Copy
   do lp_stream_copy;
      // CH1 * CH1_Mantisa    
      rMAC = r0 * r4, r0 = M[I0,M1];   
      // CH2 * CH2_Mantisa 
      rMAC = rMAC + r1 * r5, r1 = M[I1,M1];   
      // Shift for exponent
      r2 = rMAC ASHIFT r6;             
      // Save Output (r2)
      M[I4,1] = r2;                     
lp_stream_copy:
              
   L0 = 0;
   L1 = 0;
   L4 = 0;  
#ifdef BASE_REGISTER_MODE  
   push Null;
   B4 = M[SP-1];
   B1 = M[SP-1];
   pop  B0;
#endif 
   rts;
.ENDMODULE;

