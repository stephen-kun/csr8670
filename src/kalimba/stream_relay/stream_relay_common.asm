
// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2003-2007        http://www.csr.com
// Part of Stereo-Headset-SDK Q3-2007
//
// $Revision$  $Date$
// *****************************************************************************

#include "stream_relay_library.h"
#include "core_library.h"


// *****************************************************************************
// MODULE:
//    $stream_relay.getbits
//
// DESCRIPTION:
//    Get bits from encoded Stream to relay to TWS buffer. 
//
// INPUTS:
//    - r0 = number of bits to get from buffer
//    - I0 = buffer pointer to read words from
//    - $get_bitpos = previous val (should be initialised to 16)
//
// OUTPUTS:
//    - r0 = unaffected
//    - r1 = the data read from the buffer
//    - I0 = buffer pointer to read words from (updated)
//    - $get_bitpos   = updated
//
// TRASHED REGISTERS:
//    r2, r3
//
// *****************************************************************************
.MODULE $M.stream_relay.getbits;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
  .VAR $stream_relay.get_bitpos = 16;
  .VAR/DM1 $stream_relay.bitmask_lookup[17] =
                 0b0000000000000000,
                 0b0000000000000001,
                 0b0000000000000011,
                 0b0000000000000111,
                 0b0000000000001111,
                 0b0000000000011111,
                 0b0000000000111111,
                 0b0000000001111111,
                 0b0000000011111111,
                 0b0000000111111111,
                 0b0000001111111111,
                 0b0000011111111111,
                 0b0000111111111111,
                 0b0001111111111111,
                 0b0011111111111111,
                 0b0111111111111111,
                 0b1111111111111111			 
				 ;  

   $stream_relay.getbits:
  
   r3 = M[$stream_relay.bitmask_lookup + r0];    // form a bit mask (r3)
   r2 = r0 - M[$stream_relay.get_bitpos];        // r2 = shift amount
   r1 = M[I0, 0];                       // r1 = the current word 
   r1 = r1 LSHIFT r2;                   // shift current word
   r1 = r1 AND r3;                      // extract only the desired bits
   Null = r2 + 0;
// ??? Tests C and/or V flag, but previous instruction will not modify those flags

   if   LE jump one_word_only;          //check if we need to read the next word

   r3 = M[I0,1];                        // increment I0 to point to the next word
   r3 = M[I0,0];                        // get another word from buffer (r3)
   r2 = r2 - 16;                        // calc new shift amount
   r3 = r3 LSHIFT r2;                   // and shift
   r1 = r1 + r3;                        // combine the 2 parts
one_word_only:
   M[$stream_relay.get_bitpos] = Null - r2;      // update get_bitpos
   rts;   

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $stream_relay.putbits
//
// DESCRIPTION:
//    Put bits into buffer
//
// INPUTS:
//    - r0 = number of bits to put in buffer
//    - r1 = the data to put in the buffer
//    - I4 = buffer pointer to write words to
//
// OUTPUTS:
//    - I4 = buffer pointer to write words to (updated)
//
// TRASHED REGISTERS:
//    r2, r3
//
// *****************************************************************************
.MODULE $M.stream_relay.putbits;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $stream_relay.put_bitpos = 16;
   .VAR $stream_relay.put_nextword = 0;
   
   $stream_relay.putbits:
   
   r2 = M[$stream_relay.put_bitpos];
   // r2 = shift amount
   r2 = r2 - r0;
   // see if another word needs to be written
   if LE jump anotherword;

      // shift new data to the left
      r3 = r1 LSHIFT r2;
      // get any previous data to write
      r3 = r3 + M[$stream_relay.put_nextword];
      // add in the new data
      M[$stream_relay.put_nextword] = r3;
      // update bitpos
      M[$stream_relay.put_bitpos] = r2;
      rts;

   anotherword:

      // shift current word right if needed
      r3 = r1 LSHIFT r2;
      // add in any previous data to write
      r3 = r3 + M[$stream_relay.put_nextword];
      r3 = r3 AND 0xffff;
      // write the data
      M[I4, 1] = r3;
      r2 = r2 + 16;
      // any remaining data put in MSBs of sbc_nextword
      r3 = r1 LSHIFT r2;
      M[$stream_relay.put_nextword] = r3;
      // update bitpos
      M[$stream_relay.put_bitpos] = r2;
      rts;

.ENDMODULE;
