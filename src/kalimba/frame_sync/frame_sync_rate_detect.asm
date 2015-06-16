
#include "stack.h"
#include "frame_sync_rate_detect.h"

// *****************************************************************************
// MODULE:
//    $M.frame_sync.rate_detect
//
// DESCRIPTION:
//    This function calcualates the rate mismatch between two devices.
//    The calculated rate is stored into two fields in the data object:
//      $rate_detect.TARGET_WARP_VALUE_OUTPUT_ENDPOINT and
//      $rate_detect.TARGET_WARP_VALUE_OUTPUT_ENDPOINT.  These are in a format
//    suitable for the $cbops.rate_adjustment_and_shift operator.
//
//    These assumptions are made:
//    1) $M.frame_sync.rate_detect is called from the application's audio_copy
//    handler, which runs every 625 microseconds.
//    2) The cbuffer being analyzed holds at least 2 packets of data (i.e. if
//    running USB at 16 kHz, each USB packet is 16 words.  The buffer therefore
//    needs to hold at least 32 words.
//
//    This rate detect function will work best with USB if
//    $rate_detect.COUNTER_THRESHOLD is set to a value that will contain an
//    even number of USB deliveries (they're delivered at a 1ms interval) and an
//    even number of audio_handler interrupts (they fire every 625
//    microseconds).  This means it must be a multiple of 8.  160,000 is a good
//    value because it is a multiple of 8 and it provides a good amount of data
//    (10 seconds if running @ 16kHz) to calculate a warp value.  Note, that
//    since USB is delivered in packets (the packet interval is 1 ms) and since
//    the DSP is polling for new data, each measurement will likely be under
//    or over by a USB packet size (16 samples if running at 16 kHz).  This is
//    why we calculate over a long period of time (~10 seconds) and why we
//    use an averaging filter. 
//
// INPUTS:
//    r2 - data object
//    
// *****************************************************************************
.MODULE $M.frame_sync.rate_detect;
   .CODESEGMENT   PM;
   .DATASEGMENT   DM;

$frame_sync.rate_detect:
   .VAR temp;

   $push_rLink_macro;

   // Count new input samples
   r3 = M[r2 + $rate_detect.INPUT_CBUFFER_STRUCTURE];
   r0 = M[r3 + $cbuffer.WRITE_ADDR_FIELD];
   r1 = M[r3 + $cbuffer.SIZE_FIELD];
   r4 = M[r2 + $rate_detect.LAST_WRITE_PTR_POS];

   r3 = r0 - r4;
   if Z jump check_stall;
   if NEG r3 = r3 + r1;

   // Store updated write position and number of new samples.
   M[r2 + $rate_detect.LAST_WRITE_PTR_POS] = r0;
   r9 = M[r2 + $rate_detect.ACCUMULATOR];
   r9 = r9 + r3;
   M[r2 + $rate_detect.ACCUMULATOR] = r9;

   M[r2 + $rate_detect.STALL_FIELD] = r1;
   jump have_data;

   // If no new data twice in a row, we've stalled so reset rate detect.
   // This assumes USB packets are delivered every 1ms and DSP audio copy
   // handler runs every .625 ms.
check_stall:
   Null = M[r2 + $rate_detect.STALL_FIELD];
   if Z jump freeze_warp;
   M[r2 + $rate_detect.STALL_FIELD] = Null;
   r9 = M[r2 + $rate_detect.ACCUMULATOR];

have_data:
   // Compare accumulated data to expected amount of samples
   // (10 second intervals is good)
   r0 = M[r2 + $rate_detect.COUNTER];
   r0 = r0 + 1;
   M[r2 + $rate_detect.COUNTER] = r0;

   r1 = M[r2 + $rate_detect.COUNTER_THRESHOLD];
   Null = r0 - r1;
   if NZ jump done_with_warp;

   // Load number of expected samples
   r4 = M[r2 + $rate_detect.EXPECTED_NUM_SAMPLES];
 
   // Load number of samples provided by source
   M[r2 + $rate_detect.NUM_SAMPLES] = r9;
   rMAC = r9;
   r3 = SIGNDET rMAC;
   r9 = r3 - 2;
   rMAC = rMAC ASHIFT r9; 

   // Warp = actual_number_of_samples / expected_number_of_samples
   // Frac divide + 1 more shift to make sure it's bigger than numerator
   r4 = r4 ASHIFT r3; 
   Div = rMAC / r4;

// *****************************************************************************     
// Compute the average warp value using:
//    average_IO_ratio = alpha * instantanious_IO_ratio + (1 - alpha) * average_IO_ratio
//
// Where:
//    The first alpha is 1 because they will have only been one warp.
//    The second alpha is 1/2 because there will have been 2 warps.
//    The third alpha is 1/3.
//     .......
//    After 10 IO ratios have been collected alpha will be held at 1/10,
//    which will make it such that we'll continue averaging the last
//    10 warp values.  This should be a sufficient amount of data to average
//    to get a good warp value.  We need to average

   .VAR $alpha_warp_table[11] = 1.0, 4194304, 2796203, 2097152, 1677722,
                             1398101, 1198373, 1048576, 932068, 838861, 762601;
      
   // Load the appropriate alpha value
   r3 = M[r2 + $rate_detect.CURRENT_ALPHA_INDEX];
   r9 = M[r3 + $alpha_warp_table];
   
   r3 = r3 + 1;
   r4 = M[r2 + $rate_detect.ALPHA_LIMIT];
   Null = r3 - r4;
   if POS r3 = r4;
   M[r2 + $rate_detect.CURRENT_ALPHA_INDEX] = r3;

   r4 = 1.0;
   r1 = r4 - r9; // 1 - alpha    
   r3 = M[r2 + $rate_detect.AVERAGE_IO_RATIO];   
      
   // Division result is Q.22
   r0 = DivResult;

   // rMAC = alpha * instantanious IO Ratio
   rMAC = r9 * r0;
   // rMAC = rMAC + (1 - alpha) * average_warp
   rMAC = rMAC + r1 * r3;
   r4 = rMAC;
   M[r2 + $rate_detect.AVERAGE_IO_RATIO] = r4;

   // $cbops.rate_adjustment_and_shift operator needs % to increase or decrease warp by.
   r4 = r4 - 0.5;  // subtract one in q.22 domain
   r4 = r4 ASHIFT 1; // q.23



   // limit final warp value to be within -0.05 to 0.05 because that is the range specified by $cbops.rate_adjustment_and_shift.
   r3 = 0.05;
   Null = Null + r4;
   if POS jump positive_limit;
   Null = r4 + r3;
   if NEG r4 = Null - r3;
   jump load_warp;

positive_limit:
   Null = r4 - r3;
   if POS r4 = r3;

load_warp: 
   M[r2 + $rate_detect.TARGET_WARP_VALUE_OUTPUT_ENDPOINT] = r4;
   r1 = -r4;
   M[r2 + $rate_detect.TARGET_WARP_VALUE_INPUT_ENDPOINT] = r1;

send_warp_message:
   r3 = M[r2 + $rate_detect.WARP_MSG_COUNTER];
   r4 = M[r2 + $rate_detect.WARP_MSG_LIMIT];
   r3 = r3 + 1;
   Null = r4 - r3;
   if NEG jump freeze_warp;
   M[r2 + $rate_detect.WARP_MSG_COUNTER] = r3;
   Null = r3 AND 0x1;
   if Z jump freeze_warp; 
   // code below here only runs when alpha_index is 0, 2, 4, 6, 8, and 10
   


   r3 = 1 ;  // r3 holds CURRENT_ALPHA_INDEX to be stored - value is always 1
   r4 = M[r2 + $rate_detect.AVERAGE_IO_RATIO];
   r5 = r4 AND 0xFF;   // lower 8 bits AVERAGE_IO_RATIO
   r4 = r4 LSHIFT -8;  // get upper 16 bits AVERAGE_IO_RATIO
   r6 = M[r2 + $rate_detect.TARGET_WARP_VALUE_OUTPUT_ENDPOINT];
   r0 = r6 AND 0xFF;   // lower 8 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT
   r0 = r0 LSHIFT 8;   // shift up 8 bits
   r5 = r5 OR r0;      // lower 8 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT and lower 8 bits of AVERAGE_IO_RATIO
   r6 = r6 LSHIFT -8;  // get upper 16 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT
   
   // r3 has WARP_MSG_COUNTER|CURRENT_ALPHA_INDEX, 
   // r4 has upper 16 bits AVERAGE_IO_RATIO,
   // r5 has lower 8 bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT and lower 8 bits of AVERAGE_IO_RATIO
   // r6 has upper 16  bits of TARGET_WARP_VALUE_OUTPUT_ENDPOINT
   M[temp] = r2;
   r2 = $WARP_PARAMS_MESSAGE_ID;  
   call $message.send_short;
   r2 = M[temp]; 

freeze_warp:
   M[r2 + $rate_detect.COUNTER] = Null;
   M[r2 + $rate_detect.ACCUMULATOR] = Null;
  
done_with_warp:
   jump $pop_rLink_and_rts;

.ENDMODULE;

