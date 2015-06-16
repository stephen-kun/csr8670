// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.tone_mix 
//
// DESCRIPTION:
//    This function checks to see if data is available in the tone cbuffer.
//    If a frame of data is available it is mixed with the primary input stream.
//    This function assumes that the port 3 is being used for the tone stream.
//    Here is an example of how the VM could generate a tone.
//
//    Example:
//    stream_source = StreamAudioSource(gFixedTones[5])
//    StreamDisconnect(0, StreamKalimbaSink(3));
//    StreamConnectAndDispose(stream_source, StreamKalimbaSink(3));
//
//    Note that "gFixedtones" came from the mono headset example application.
//
// INPUTS:
//    r8 - aux mix data object
//
// OUTPUTS:
//    none

// *****************************************************************************
#include "core_library.h"
#include "tone_mix.h"

.MODULE $M.tone_mix;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR  one_24 = 1.0;
   .VAR  neg_1 = 0x800000;
   .VAR  ToneCbuf = 0;

$tone_mix:
   $push_rLink_macro;
   
   r10 = M[r8 + $tone_mix.OFFSET_FRAME_SIZE];   
   r6 = M[r8 + $tone_mix.OFFSET_SCO_GAIN_Q5_19];
   r4 = M[r8 + $tone_mix.OFFSET_TONE_GAIN_Q5_19];
   r5 = M[r8 + $tone_mix.OFFSET_TONE_CBUFFER_STRUC];

   // Get stream data	
   r0 = r5;
   call $cbuffer.get_read_address_and_size;
   I4 = r0;
   L4 = r1;
 
   // Check amount of data.
   r0 = r5;
   call $cbuffer.calc_amount_data;
   r2 = r5;
   r10 = r10 - r0;
   // there's at least a frame of tone data
   if LE jump done;  
   M0 = r0;
   // not enough tone data
   if Z jump not_enough_tone_data;      

   // There's less than frame of tone data.  If the port is enabled, it must have
   // just been connected and we're just starting to acquire data.  If the port is
   // disabled, we must have just disconnected the port and we need to mix the 
   // remaining data.
   r0 = M[r8 + $tone_mix.OFFSET_TONE_PORT];
   call $cbuffer.is_it_enabled;
   // port is enabled, but we'll mix later when
   // we have a frame of data.
   if NZ jump not_enough_tone_data; 
                                    

   // Last chunk of data so zero padd and advance write pointer
   // Save Pointer
   r3 = I4;                                    
   // Advance past good data, r1=0
   r1 = r1 XOR r1, r0 = M[I4,M0]; 
   do lp_zero;
      // Zero Pad
      M[I4,1] = r1;                         
lp_zero:

   r0 = r2;
   r1 = I4;
   // Update Write address past frame
   call $cbuffer.set_write_address;       
   // Restore Pointer
   I4 = r3;                               
   jump done;
   
not_enough_tone_data:
   r2 = Null;

done:
   M[ToneCbuf] = r2;
   // Set gain to zero if invalid
   if Z r4 = Null;

   // r8 is pointing to data object
   I3 = r8;
   M1 = 1;
   r2 = M[I3,M1];
   // I0 = ptr_ip_buffer, read in next value from
   //object
   I0 = r2, r2 = M[I3,M1];   
   // L0 = setup length of buffer, read in next value                           
   L0 = r2, r2 = M[I3,M1];   
   // I5 = Output buffer 
   I5 = r2, r2 = M[I3,M1];   
   // r2 = Frame Size
   L5 = r2, r2 = M[I3,M1];   
   r10 = r2;
 
   // LOOP START
   do lp_mix;
      // r2 = SCO, r1 = Tone (Aux)
      r2 = M[I0,1], r1 = M[I4,1];   
      // Blend AUX   ( Q10.38 )
      rMAC = r1 * r4;              
      // Blend Signal ( Q10.38 )
      rMAC = RMAC + r2 * r6;       
      // Signal (Q1.23)
      r3 = rMAC ASHIFT 4;         
      // Save
      M[I5,1] = r3;               
lp_mix:

   L0 = 0;
   L4 = 0;
   L5 = 0;

   // Update the I/O buffer pointers back into data object before leaving.
   r0 = I0;
   M[r8 + $tone_mix.OFFSET_PTR_IN_FRAME] = r0;
   r0 = I5;
   M[r8 + $tone_mix.OFFSET_PTR_OUT_FRAME] = r0;	

   r1 = I4;
   L4 = 0;
   r0 = M[ToneCbuf];
   if NZ call $cbuffer.set_read_address;
   jump $pop_rLink_and_rts;

.ENDMODULE;
