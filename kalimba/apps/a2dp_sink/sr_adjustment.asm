// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#include "core_library.h"
#include "cbops_library.h"
#include "codec_library.h"
#include "sr_adjustment.h"
#include "kalimba_standard_messages.h"

// *****************************************************************************
// MODULE:
//    $sra_calcrate
//
// DESCRIPTION:
//    calculates the mistmatch rate between sink and source
//
//
// *****************************************************************************
.MODULE $M.sra_calcrate;
   .CODESEGMENT MUSIC_EXAMPLE_SRA_CALCRATE_PM;
   .DATASEGMENT DM;

  .VAR mode_funtion_table[] = &idle, &start, &addup;

   $sra_calcrate:

   // push rLink onto stack
   $push_rLink_macro;

   // Get the connection type
   r0 = M[$app_config.io];

#if defined(USB_ENABLE) && (!defined(TWS_WIRED_MODE_ENABLE))

   null = r0 - $USB_IO;
   if Z jump skip_a2dp_sra_reset;
   
#endif

#if defined(ANALOGUE_ENABLE) && (!defined(TWS_WIRED_MODE_ENABLE))
   null = r0 - $ANALOGUE_IO;
   if Z jump skip_a2dp_sra_reset;
#endif

      r0 = M[$decoder_codec_stream_struc + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
      if Z jump $reset_sra;

   skip_a2dp_sra_reset:

   // jump to proper function
   r0 = M[$sra_struct + $sra.RATECALC_MODE_FIELD];
   r0 = M[r0 + mode_funtion_table];
   jump r0;


// -- idle mode function
idle:
   // check if start address has been tagged
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD];
   // if not stay in idle  mode
   if Z jump end;

   // set mode to start mode and go to start funtion
   r0 = $sra.RATECALC_START_MODE;
   M[$sra_struct + $sra.RATECALC_MODE_FIELD] = r0;

// -- start mode function
start:
   // get the read pointer of codec cbuffer
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.get_read_address_and_size;

   // check if start tag address has just passed
   r1 = M[$sra_struct + $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD];
   r2 = M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD];
   call is_it_within_range;

   // stay in start mode if not yet passed
   Null = r3;
   if Z jump end;

 // start tag address just passed
 //clear start tag
 M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD] = NULL;

 // clear accumulator
 M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD] = Null;

 // set next mode to rate_calc mode (addup)
 r0 = $sra.RATECALC_ADD_MODE;
 M[$sra_struct + $sra.RATECALC_MODE_FIELD] = r0;
 jump end;

// -- addup mode function,
//    in this mode the number of PCM samples produced by the decoder is continously counted
//    until an end tag is seen
addup:
  // work out number of  PCM samples has been generated since last time by seeing the amount of movement
  // in write pointer of audio cbuffer
  r0 = M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD];
  call $cbuffer.get_write_address_and_size;
  r2 = r0 - M[$sra_struct + $sra.AUDIO_CBUFFER_PREV_WRITE_ADDR_FIELD];
  if NEG r2 = r2 + r1;
  // update accumulator
  r1 = r2 + M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD];
  M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD] = r1;

  // search for end tag
  r2 = M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD];
  if Z jump end;
  // end tag seen, from now see if it jas just passed
  r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
  call $cbuffer.get_read_address_and_size;
  r1 = M[$sra_struct + $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD];
  r2 = M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD];
  call is_it_within_range;
  Null = r3;
  // if not passed, stay in add-up mode
  if Z jump end;

  // end tag address has just been passed by the decoder, end accumulation and update the rate
  //clear the end tag address
  M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD] = Null;
  // set new mode to idle mode, it should automatically go to start mode if everything is right
  r0 = $sra.RATECALC_IDLE_MODE;
  M[$sra_struct + $sra.RATECALC_MODE_FIELD] = r0;

  // make sure accumulated value is right
  r2 = M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD];
  r3 = 1;
  r1 = r2 - M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD];
  if NEG r3 = -r3;
  r1 = r1*r3(int);
  r7 = M[$sra_struct + $sra.MAX_RATE_FIELD];
  r7 = r7 * 6 (int);
  r2 = r2 * r7(frac); // twice maximum value
  r2 = r1 - r2;
  // if too big value then ignore it
  if POS jump idle; //r1 = r1 - r2;

  r1 = r1*r3(int);
  // save the diff value into history
  r0 = M[$sra_struct + $sra.HIST_INDEX_FIELD];
  M[r0 + ($sra_struct+$sra.HIST_BUFF_FIELD)] = r1;

  // r0 = update index
  r0 = r0 + 1;
  r0 = r0 AND ($sra.BUFF_SIZE-1);
  M[$sra_struct + $sra.HIST_INDEX_FIELD] = r0;

  // if for the first time buffer is full?
  if NZ jump init_phase_passed;
  r2 = $sra.STEADY_SAVING_MODE;
  M[$sra_struct + $sra.SAVIN_STATE_FIELD] = r2;
  init_phase_passed:

  // if init phase not yet passed, partially average
  r1 = $sra.BUFF_SIZE;
  Null = M[$sra_struct + $sra.SAVIN_STATE_FIELD];
  if NZ r0 = r1;

  // once long term rate detected, slow down clac new rate to 8 seconds
  Null = M[$sra_struct + $sra.LONG_TERM_RATE_DETECTED_FIELD];
  if  Z jump calc_final_rate;
  NULL = r0 AND 1;
  if NZ jump idle;
  calc_final_rate:
  // calculate sum of hist values
  r10 = r0 - 1;
  r3 = 1.0;
  I0 = (&$sra_struct+$sra.HIST_BUFF_FIELD);
  r1 = 0, r2 = M[I0, 1];
  do acc_loop;
     r1 = r1 + r2, r2 = M[I0, 1];
  acc_loop:
  r1 = r1 + r2;

  // r1 = abs(sum), r3 = sign
  if NEG r3 = -r3;
  r1 = r1 * r3 (frac);

  // averaging
  rMAC = 0;
  rMAC0 = r1;
  Div = rMAC / r0;
  r1 = DivResult;

  // rate calculation
  rMAC = r1 ASHIFT -1;
  r2 = M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD];
  Div = rMAC / r2;
  r1 = DivResult;
  // limit rate
  r2 = r1 - M[$sra_struct + $sra.MAX_RATE_FIELD];
  if POS r1 = r1 - r2;
  // add sign
  r1 = r1 * r3 (frac);
  // set rate
  M[$sra_struct + $sra.RATE_BEFORE_FIX_FIELD] = r1;
  // -- see if rate is almost stable
  r6 = r0 LSHIFT -1;
  r7 = r0 AND 1;
  Null = r6 - 6;
  if NEG jump idle;
  r4 = M[$sra_struct + $sra.HIST_INDEX_FIELD];
  NULL = r0 - M[$sra_struct + $sra.HIST_INDEX_FIELD];
  if Z r4 = 0;
  r4 = r4 + r7;
  // calc sum(hist(1:end/2))
  r10 = r6;
  r1 = 0;
  do read_first_half_ents;
     r3 = M[r4 + ($sra_struct + $sra.HIST_BUFF_FIELD)];
     r1 = r1 + r3;
     r4 = r4 + 1;
     r4 = r4 AND ($sra.BUFF_SIZE-1);
  read_first_half_ents:
  // calc sum(hist(end/2+1:end))
  r10 = r6;
  r2 = 0;
  do read_second_half_ents;
     r3 = M[r4 + ($sra_struct + $sra.HIST_BUFF_FIELD)];
     r2 = r2 + r3;
     r4 = r4 + 1;
     r4 = r4 AND ($sra.BUFF_SIZE-1);
  read_second_half_ents:
  r3 = r1 - r2;
  if NEG r3 = -r3;
  // first half ~= second half?
  rMAC = r3 ASHIFT -1;
  r0 = M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD];
  Div = rMAC / r0;
  r1 = DivResult;
  r2 = r6*0.0008(int);
  Null = r1 - r2;
  if POS jump idle;
  // long term rate detected, is it different from saved one?
  r0 = 1;
  M[$sra_struct + $sra.LONG_TERM_RATE_DETECTED_FIELD] = r0;
  r0 = M[$sra_struct + $sra.RATE_BEFORE_FIX_FIELD];
  r1 = r0 - M[$sra_struct + $sra.LONG_TERM_RATE_FIELD];
  if NEG r1 = -r1;
  Null = r1 - 0.0002;
  if NEG jump idle;
  // send long term rate to vm
  M[$sra_struct + $sra.LONG_TERM_RATE_FIELD] = r0;
  r0 = r0 ASHIFT -6;
  r0 = r0 ASHIFT 1;
  r3 = r0 OR 1;
  r4 = 0;
  r5 = 0;
  r6 = 0;
  r2 = $MESSAGE_SOURCE_CLOCK_MISMATCH_RATE;
  call $message.send_short;
  // exit this mode
  jump idle;

end:
 // update previous read pointer for codec cbuffer
 r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
 call $cbuffer.get_read_address_and_size;
 M[$sra_struct + $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD] = r0;

 // update previous write pointer for audio cbuffer
 r0 = M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD];
 call $cbuffer.get_write_address_and_size;
 M[$sra_struct + $sra.AUDIO_CBUFFER_PREV_WRITE_ADDR_FIELD] = r0;

 exit:

  // pop rLink from stack
   jump $pop_rLink_and_rts;

 //r0 = addr1, r1= addr2, r2=addr
 // result: r3
 is_it_within_range:
  r3 = 1;
  Null = r0 - r1;
  if NEG jump neg_part;
  pos_part:

   Null = r2 - r0;
   if POS r3 = 0;
   Null = r2 - r1;
   if NEG r3 = 0;
  rts;

 neg_part:
   Null = r2 - r1;
   if POS rts;
   Null = r2 - r0;
   if POS r3 = 0;

rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $sra_tagtimes
//
// DESCRIPTION:
//    tags the cbuffer contatining codec data, so that rate calculator can measure
//    the amount of PCM samples received in a defined period
//
// *****************************************************************************
.MODULE $M.sra_tagtimes;
   .CODESEGMENT MUSIC_EXAMPLE_SRA_TAGTIMES_PM;
   .DATASEGMENT DM;

  .VAR mode_funtion_table[] = &idle, &counting;

   $sra_tagtimes:

   // push rLink onto stack
   $push_rLink_macro;


#if defined(USB_ENABLE) || defined(ANALOGUE_ENABLE) && (!defined(TWS_WIRED_MODE_ENABLE))

   // Get the connection type
   r0 = M[$app_config.io];
   null = r0 - $USB_IO;
   if Z jump usb_fix;

   null = r0 - $ANALOGUE_IO;
   if NZ jump calc_a2dp_fix_rate;

usb_fix:

      // Amount of data in input pcm buffer
      r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
      call $cbuffer.calc_amount_data;
      r4 = r0;
      r5 = r2;
      
      // r4 is total data fill level of input  pcm buffer (in samples)
      // r5 is max size of input pcm buffer (in samples)
      // Use a LPF for smooth changes (also shift up by 8 to improve accuracy)
      r1 = M[$sra_struct + $sra.AVERAGE_LEVEL_FIELD];
      r4 = r4 LSHIFT 8;
      rMAC = r4 * 0.01;
      rMAC = rMAC + r1*0.99;
      M[$sra_struct + $sra.AVERAGE_LEVEL_FIELD] = rMAC;

      // Calculate the fractional average fill level (e.g. 1.0 is both buffers full)
      // (effectively, shift result down by 8 to reverse previous shift up by 8.
      //  An additional shift of 1 is needed to give correct integer divide)
      r5 = r5 LSHIFT 9;
      Div = rMAC / r5;
      r4 = DivResult;

      // Target a fill level of 70%
      r4 = 0.7 - r4;

      // Limit the maximum adjustment
      r0 = r4 - 0.2;
      if POS r4 = r4 - r0;
      r0 = r4 + 0.2;
      if NEG r4 = r4 - r0;

      // Scale the adjustment
      r0 = r4 * 0.005(frac);
      r1 = M[$sra_struct + $sra.FIX_VALUE_FIELD];

      // r0 = new fixing value
      // r1 = old fixing value
      // move slightly towards new value
      r4 = r0 - r1;
      r4 = r4 *(1.0/32)(frac);
      r1 = r1 + r4;
      M[$sra_struct + $sra.FIX_VALUE_FIELD] = r1;

      // Set the max. rate change
#if 1
      // For USB just use a fixed value since the expected jitter is low)
      r7 = 0.001;
#else
      r7 = 0.0025;
      r0 = 0.001;
      NULL = M[$sra_struct + $sra.LONG_TERM_RATE_DETECTED_FIELD];
      if Z r7 = r0;
#endif
      jump set_final_rate;

   calc_a2dp_fix_rate:
#endif

   // Data in PORT
   r0 = M[$sra_struct + $sra.CODEC_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r5 = r0;

   skip_port_data:

#ifdef SRA_TARGET_LATENCY
   // get current latency value
   r0 = M[$sra_struct + $sra.CURRENT_LATENCY_PTR_FIELD];
   r0 = M[r0];
   // us -> 0.1ms
   r0 = r0 * 0.01 (frac);
   // accumulate latency values
   r0 = r0 + M[$sra_struct + $sra.LATENCY_ACC_FIELD];
   M[$sra_struct + $sra.LATENCY_ACC_FIELD] = r0;
#endif

   // Data in CBUFFER
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.calc_amount_data;

   // Total data in PORT+CBUFFER
   r5 = r5 + r0;

   // acumulate the codec level for averaging
   r5 = r5 + M[$sra_struct + $sra.BUFFER_LEVEL_ACC_FIELD];
   M[$sra_struct + $sra.BUFFER_LEVEL_ACC_FIELD] = r5;

   // increament counter
   r4 = M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD];
   r4 = r4 + 1;
   M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD] = r4;

   // averaging is done for 25% of TAG_DURATION (0.5 seconds)
   r1 = M[$sra_struct + $sra.TAG_DURATION_FIELD];
   r1 = r1 * 0.25(frac);
   Null = r4 - r1;
   // time to average?
   if NEG jump no_update_on_buf_level;

#ifdef SRA_TARGET_LATENCY
   // get latency accumulator
   r0 = M[$sra_struct + $sra.LATENCY_ACC_FIELD];
   // reset latency accumulator
   M[$sra_struct + $sra.LATENCY_ACC_FIELD] = 0;
   // calculate average latency
   rMAC = 0;
   rMAC0 = r0;
   r0 = M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD];
   Div = rMAC / r0;
   r0 = DivResult;
   M[$sra_struct + $sra.AVERAGE_LATENCY_FIELD] = r0;
#endif

   r7 = 0.0025;
   NULL = M[$sra_struct + $sra.LONG_TERM_RATE_DETECTED_FIELD];
   if Z jump no_long_term;
      r7 = 0.001;
   no_long_term:
   // averaging the codec buffer level
   M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD] = Null;
   M[$sra_struct + $sra.BUFFER_LEVEL_ACC_FIELD] = Null;
   r6 = M[$sra_struct + $sra.FIX_VALUE_FIELD];
   r0 = r6 ASHIFT -2;
   M[$sra_struct + $sra.FIX_VALUE_FIELD] = r6 - r0;
   // calc avg
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   r0 = M[r0]; // get the size of buffer
   r0 = r0 * r4 (int); // size*N
   rMAC = r5 ASHIFT -1;
   Div = rMAC / r0;   // sum/(N*size)
   r1 = DivResult;
   r4 = M[$sra_struct + $sra.AVERAGE_LEVEL_FIELD];
   M[$sra_struct +$sra.AVERAGE_LEVEL_FIELD] = r1;
   r4 = r1 - r4;
   // if virtually full then decrease the rate slowly
   Null = r1 - 0.98;
   if NEG jump not_full;
      r0 = r6 - 0.0005;
      r1 = r0 + M[$sra_struct + $sra.MAX_RATE_FIELD];
      if NEG r0 = r0 - r1;
      r1 = r0 + 0.015;
      if NEG r0 = r0 - r1;
      M[$sra_struct + $sra.FIX_VALUE_FIELD] = r0;
      jump set_final_rate;
   not_full:
   
#ifdef SRA_TARGET_LATENCY

   // se if target latency requested
   Null = M[$sra_struct + $sra.TARGET_LATENCY_MS_FIELD];
   if Z jump no_target_latency;

   // also see if latency is being calculated
   r2 = M[$sra_struct + $sra.AVERAGE_LATENCY_FIELD];
   if Z jump no_target_latency;

   // robustness still is prioprity
   r0 = r1 - 0.3;
   if NEG jump handle_empty;
   
   // work out difference (in 100us)
   r0 = M[$sra_struct + $sra.TARGET_LATENCY_MS_FIELD];
   r0 = r0 * 10(int)(sat);
   r0 = r0 - r2;
   
   // scale, how fast we want to fix it
   r0 = r0 * 7000 (int)(sat);
   r2 = r0 ASHIFT -1;
   if NEG r2 = -r2;
   r0 = r0 * r2 (frac);
   
   // limit fixing range
   r2 = r0 - 0.005;
   if POS r0 = r0 - r2;
   r2 = r0 + 0.005;
   if NEG r0 = r0 - r2;

   // if about to get full then add a negative fix  to rate
   r2 = r1 - 0.9;
   if NEG jump fix_rate;
   r2 = r2 * (-0.015)(frac);
   Null = r4 + 0.01;
   if NEG r2 = r6;
   // whichever smaller
   Null = r0 - r2;
   if POS r0 = r2;
   jump fix_rate;
no_target_latency:
#endif
   // if about to get full then add a negative fix  to rate
   r0 = r1 - 0.85;
   if NEG jump check_for_empty;
   r0 = r0 * (-0.015)(frac);
   Null = r4 + 0.01;
   if NEG r0 = r6;
   jump fix_rate;

check_for_empty:
   // if about to get empty add a positive fix to the rate
   r0 = r1 - 0.6;
   if POS jump set_final_rate;
handle_empty:
   r2 = r0 + 0.2;
   if NEG r0 = r0 - r2;
   r0 = r0 * (-0.035)(frac);
   // moving upward? dont update
   Null = r4 - 0.05;
   if POS r0 = r6;
   // add extra if falling sharp
   r2 = r4 + 0.02;
   if POS jump no_extra;
   r3 = r2 + 0.05;
   if POS r2 = r2 - r3;
   r2 = r2 * (-0.002)(frac);
   r2 = r2 + r6;
   Null = r2 - r0;
   if POS r0 = r2;
   r0 = r0 + r2;
no_extra:
   NULL = r1 - 0.2;
   if NEG r0 = r6;
fix_rate:
   // limit the change in fix value
   r1 = r6 + r7;
   NULL = r0 - r1;
   if POS r0 = r1;
   r1 = r6 - r7;
   NULL = r0 - r1;
   if NEG r0 = r1;
   // set the fix value
   M[$sra_struct + $sra.FIX_VALUE_FIELD] = r0;


set_final_rate:
   //set final gain
   r0 = M[$sra_struct + $sra.RATE_BEFORE_FIX_FIELD];
   r0 = r0 + M[$sra_struct + $sra.FIX_VALUE_FIELD];
   // another limit check might be useful again???
   r1 = r0 - M[$sra_struct + $sra.MAX_RATE_FIELD];
   if POS r0 = r0 - r1;
   r1 = r0 + M[$sra_struct + $sra.MAX_RATE_FIELD];
   if NEG r0 = r0 - r1;
   r1 = r0 + 0.015;
   if NEG r0 = r0 - r1;
   r6 = M[$sra_struct + $sra.SRA_RATE_FIELD];
   r1 = r6 + r7;
   NULL = r0 - r1;
   if POS r0 = r1;
   r1 = r6 - r7;
   NULL = r0 - r1;
   if NEG r0 = r1;
   M[$sra_struct + $sra.SRA_RATE_FIELD] = r0;

no_update_on_buf_level:

   r0 = M[$sra_struct + $sra.CODEC_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r3 = r0;

   // update no data counter
   r0 = M[$sra_struct+ $sra.NO_CODEC_DATA_COUNTER_FIELD];
   r0 = r0 + 1;
   Null = r3;
   if NZ r0 = 0;
   M[$sra_struct+ $sra.NO_CODEC_DATA_COUNTER_FIELD] = r0;

   // rest sra if no activity during past NO_ACTIVITY_PERIOD perio
   Null = r0 - $sra.NO_ACTIVITY_PERIOD;
   if NEG jump no_reset_sra;
   M[$sra_struct + $sra.FIX_VALUE_FIELD] = Null;
   jump $reset_sra;

no_reset_sra:
   // increment active period counter
   r0 = M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD];
   r1 = $sra.ACTIVITY_PERIOD_BEFORE_START + 10;
   r0 = r0 + 1;
   Null = r0 - r1;
   if POS r0 = r1;
   M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD] = r0;

   // jump to the proper mode
   r0 = M[$sra_struct + $sra.MODE_FIELD];
   r0 = M[r0 + mode_funtion_table];
   jump r0;

// -- idle mode function
 idle:
   // switch to start mode only if it has been active during past ACTIVITY_PERIOD_BEFORE_START
   r0 = M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD];
   Null = r0 - $sra.ACTIVITY_PERIOD_BEFORE_START;
   if POS jump start;
   jump end;

// -- start mode function
start:


   // tag start point so it can be used for rate calc thread
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.get_write_address_and_size;
   M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD]= r0;

   // and go to counting mode
   r0 = $sra.COUNTING_MODE;
   M[$sra_struct + $sra.MODE_FIELD] = r0;
   M[$sra_struct + $sra.TAG_TIME_COUNTER_FIELD] = Null;

// -- counting mode function
 counting:
   // increament the counter
   r0 = M[$sra_struct + $sra.TAG_TIME_COUNTER_FIELD];
   r0 = r0 + 1;
   M[$sra_struct + $sra.TAG_TIME_COUNTER_FIELD] = r0;
   // time to end counting?
   r0 = r0 - 1;
   Null = r0 - M[$sra_struct + $sra.TAG_DURATION_FIELD];
   if NEG jump end;

   //now pcm thread shouldnt be in idle mode, if so reset
   r0 = M[$sra_struct + $sra.RATECALC_MODE_FIELD];
   Null = r0 - $sra.RATECALC_ADD_MODE;
   if NZ jump  $reset_sra;

   // tag  end point address
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.get_write_address_and_size;
   M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD]= r0;

   // jump idle to restart
   jump idle;

end:
   // pop rLink from stack
   jump $pop_rLink_and_rts;

  $reset_sra:
  M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD] = Null;
  M[$sra_struct + $sra.RATECALC_MODE_FIELD] = Null;
  M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD] = Null;
  M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD] = Null;
  M[$sra_struct + $sra.MODE_FIELD] = Null;
  jump $pop_rLink_and_rts;

.ENDMODULE;
