
#include "core_library.h"
#include "cbops_library.h"
#include "plc100_library.h"
#include "mips_profile.h"
#include "subwoofer.h"
#include "audio_proc_library.h"

.MODULE $M.l2cap_process;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
    
   .VAR error_type;
   .VAR audio_out_id;
   .VAR $l2cap_input_check_handler_id;
   .VAR $soundbar_packet_counter;
   .VAR $just_started_streaming_flag;
   .VAR $local_packet_counter;
   .VAR $l2cap_copy_handler_id;
   .VAR $first_l2cap_copy_handler;
   .VAR $l2cap_process_counter;
   .VAR $bin_counter;
   .VAR $sync_error_counter;
   .VAR $underflow_counter;
   .VAR $buffering_flag=1;
   .VAR l2cap_temp1;
   .VAR l2cap_temp2;

   
   $l2cap_process:
   
   $push_rLink_macro;
   
   r1 = M[$l2cap_process_counter];
   r1 = r1 + 1;
   M[$l2cap_process_counter] = r1;
   
   Null = M[$buffering_flag];
   if NZ jump done;
   
   // Any data to decode?
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   Null = r0 - $L2CAP_FRAME_SIZE;
   if NEG jump check_underflow;

   // We have input data, do we have enough space for PLC's input buffer?
   r0 = $input_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $L2CAP_AUDIO_SIZE;
   if NEG jump done;

   // Do we have enough space for upsampled frame?
   r0 = $frame_process_in_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $music_example.NUM_SAMPLES_PER_TWO_FRAMES;
   if NEG jump done;

   // Do do we have enough space for output of frame process?
   r0 = $dac_out_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $music_example.NUM_SAMPLES_PER_TWO_FRAMES;
   if NEG jump done;
 
   // Extract Header
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;
   
   // read header sync word
   r0 = M[I0,1];
   Null = r0 - 0xf5f5;
   if NZ jump sync_error;  // TODO: flush port? find_sync?

   // read packet counter and time Soundbar wrote to MMU port
   r0 = M[I0,1];        // LSW of packet counter
   r1 = M[I0,1];        // packet counter, SoundbarTxTime
   r2 = r1 AND 0xFF00;  // MSB of packet counter
   r2 = r2 LSHIFT 8;
   r0 = r2 + r0;
   M[$soundbar_packet_counter] = r0;  // 24-bit counter TODO: only set this when streaming starts

   // read time Soundbar wrote this frame to output MMU port
   r0 = r1 LSHIFT 16;   // MSB of SoundbarTxTime 
   r1 = M[I0,1];        // LSW of SoundbarTxTime
   r1 = r1 AND 0xFFFF;  // TODO: shouldn't need this since sign extension is off
   r0 = r0 + r1;
   M[$first_wall_clock_from_payload] = r0;
   
   // Read time that Soundbar will play this frame
   r0 = M[I0,1];        // MSB of current warp, MSB of TIME_SB_WILL_PLAY    
   r2 = r0 AND 0xFF00;  // MSB of current warp
   r2 = r2 LSHIFT 8;
   r0 = r0 LSHIFT 16;
   r1 = M[I0,1];        // LSW of TIME_SB_WILL_PLAY
   r1 = r1 AND 0xFFFF;
   r0 = r0 + r1;
   r1 = M[I0,1];        // LSB of current warp
   r1 = r2 + r1;
   M[$current_rate] = r1;
   M[$first_time_to_play_from_payload] = r0;
      
   // Did streaming just start?
   Null = M[$just_started_streaming_flag];
   if Z jump did_not_just_start_streaming;
     
   // Set Subwoofer's delay to synchronize audio playback
   M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD] = Null;
   
   // set new read address for input data
   r0 = $l2cap_codec_cbuffer_struc;
   r1 = I0;
   call $cbuffer.set_read_address;
   L0 = Null;

   // Compute when Subwoofer will play
   r7 = &$output_buffers;
   r8 = &$output_port_and_delay_size;
   call $calc_time_to_play;
   
   r8 = &$output_port_and_delay_size;
   r1 = M[r8 + 5];                            // r1 = Time Subwoofer will play
   r0 = M[$first_time_to_play_from_payload];
   r1 = r0 - r1;                              // r1 = required delay (us) = time Soundbar will play - time Subwoofer will play.
   if POS jump subwoofer_delay_is_required;
   jump bin_data;  // subwoofer is going to play after Soundbar, so we prevent this.
 
subwoofer_delay_is_required:
     r0 = M[$sub_dac_sampling_rate];
     r2 = 2; // 41000 pointer
     Null = r0 - 48000;
     if NZ jump convert_from_microseconds_to_samples;
     r2 = 3;  // 48000 pointer 

convert_from_microseconds_to_samples:
     r0 = M[$samples_per_us_sbc + r2];
     r1 = r0 * r1 (frac);   
     r0 = LENGTH($M.system_config.data.delay_buf_left);   
     Null = r0 - r1;
     // if NEG, the delay buffer isn't big enough to account for the delay
     // between the Soundbar and Subwoofer.
     if POS jump set_delay;
     jump bin_data;
set_delay:
     M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD] = r1;
     r8 = &$M.system_config.data.delay_left;
     call $audio_proc.delay.initialize;

     r0 = $l2cap_codec_cbuffer_struc;
     call $cbuffer.get_read_address_and_size;
     I0 = r0;
     L0 = r1;

     // Delay is set, so set flag.
     M[$just_started_streaming_flag] = Null;

did_not_just_start_streaming:
     r0 = M[$soundbar_packet_counter];
     r1 = r0 - M[$local_packet_counter];
     if Z jump no_missing_packet;
     Null = r1 - 1;
     if NZ jump bin_data;
     // We're missing one packet.  Generate it with the PLC.
     M[error_type] = r1;
     jump do_plc;

no_missing_packet:
     // Validate playback synchronization
     r0 = I0;
     M[l2cap_temp1] = r0;
     r0 = L0;
     M[l2cap_temp2] = r0;    
          
     r1 = M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD];
     M[$output_port_and_delay_size + 2] = r1;
     r7 = &$output_buffers;
     r8 = &$output_port_and_delay_size;
     call $calc_time_to_play;
     r1 = M[$output_port_and_delay_size + 5];       // r1 = Time Subwoofer will play
     M[$output_port_and_delay_size + 2] = Null;
     r1 = r1 - M[$first_time_to_play_from_payload]; // r1 = Time Subwoofer will play - Time Soundbar will play

     // TODO: modify warp to account for Soundbar/Subwoofer mismatch.
.VAR $trace[4000];
.VAR $trace_counter;
r0 = M[$trace_counter];
Null = r0 - 4000;
if Z jump skip;
   M[$trace + r0] = r1;
   r0 = r0 + 1;
   M[$trace_counter] = r0;
skip:

     // Ensure difference between when Subwoofer will play and Soundbar will play is reasonable.
     // If, for example, the Soundbar stalled, this difference would be large and would need fixing.
     
     // Will Subwoofer play 6 ms after the Soundbar?
     Null = r1 - 10000;
     if NEG jump subwoofer_is_not_too_late;
     jump bin_data;
     
subwoofer_is_not_too_late:
     // Will Subwoofer play 6 ms before the Soundbar?
     Null = r1 + 10000;
     if POS jump restore_pointers;
     jump bin_data;

restore_pointers:
     r0 = M[l2cap_temp1];
     I0 = r0;
     r0 = M[l2cap_temp2];
     L0 = r0;

read_data:
   M[error_type] = Null;
   
   r0 = $input_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;
   
// read audio samples into buffer for PLC
   r10 = $L2CAP_AUDIO_SIZE;
   do sco_loop;
      r1 = M[I0,1];
      r1 = r1 ASHIFT 8; // shift up for PLC
      M[I4,1] = r1;  
   sco_loop:
   
   L4 = Null;
   L0 = Null;

   // set new read address for input data
   r0 = $l2cap_codec_cbuffer_struc;
   r1 = I0;
   call $cbuffer.set_read_address;
   
   // Set BFI to zero, which tells the PLC the audio is goood
   r1 = 0;

do_plc:
   // call PLC
   r7 = &$M.main.plc_obj;
   M[r7 + $plc100.BFI_FIELD] = r1;
   r0 = M[r7 + $plc100.BFI_FIELD];
   call $calc_error_rate;

   r7 = &$M.main.plc_obj;
   r0 = &$input_cbuffer_struc;
   M[r7 + $plc100.OUTPUT_PTR_FIELD] = r0;
   r0 = $music_example.NUM_SAMPLES_PER_PLC;
   M[r7 + $plc100.PACKET_LEN_FIELD] = r0;
   call $plc100.process;
   
   // call PLC
   r7 = &$M.main.plc_obj;
   r1 = M[error_type];
   M[r7 + $plc100.BFI_FIELD] = r1;
   r0 = M[r7 + $plc100.BFI_FIELD];
   call $calc_error_rate;

   r7 = &$M.main.plc_obj;
   r0 = &$input_cbuffer_struc;
   M[r7 + $plc100.OUTPUT_PTR_FIELD] = r0;
   r0 = $music_example.NUM_SAMPLES_PER_PLC;
   M[r7 + $plc100.PACKET_LEN_FIELD] = r0;
   call $plc100.process;

   // upsample audio
   call $block_interrupts;   
   r8 = &$upsample_copy_struc;
   call $cbops.copy;
   call $unblock_interrupts;

   // do frame based processing
   call $music_example_process;
   call $music_example_process;

   // Call warp operator, which fixes clock mismatch between Soundbar and Subwoofer.
   call $block_interrupts;   
  
   r8 = &$warp_out_copy_struc;
   call $cbops.copy;
   
   // Call it again because cbops.copy is limited to copying 512 samples.
   r8 = &$warp_out_copy_struc;
   call $cbops.copy;
   
   call $unblock_interrupts;
   
   // Calculate rate mismatch between Soundbar and Subwoofer and warp to compensate.
   r8 = $l2cap_rate_detection_obj;
   call $subwoofer_rate_detect;
   
   // If PLC generated packets, update local packet counter.
   Null = M[error_type];
   if Z jump plc_did_not_generate_frame;
      
   r0 = M[$subwoofer.packet_fail_counter];
   r0 = r0 + 1;
   M[$subwoofer.packet_fail_counter] = r0;
      
plc_did_not_generate_frame:

   r0 = M[$local_packet_counter];
   r0 = r0 + 1;
   M[$local_packet_counter] = r0;

   // Clear L registers
   L4 = NULL;
   L0 = NULL;
   
   // kick off DAC operator.
   Null = M[$dac_isr_running];
   if NZ jump done;

   // call DAC operator chain
   r2 = M[$M.l2cap_audio_out_copy_handler.audio_out_id]; 
   call $timer.cancel_event;

   r2 = 0;
   r1 = &$audio_out_timer_struc;
   r3 = &$l2cap_audio_out_copy_handler;
   call $timer.schedule_event_in;   
   M[audio_out_id] = r3;

done:

   // Clear L registers
   L4 = NULL;
   L0 = NULL;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
bin_data:
   // We are recovering from a serious packet loss, so flush all data.
   r1 = M[$bin_counter];
   r1 = r1 + 1;
   M[$bin_counter] = r1;

   call $block_interrupts;
   
   // Flush data
   r0 = M[$l2cap_codec_cbuffer_struc + 2]; // write address
   M[$l2cap_codec_cbuffer_struc + 1 ] = r0;

   r0 = M[$input_cbuffer_struc + 2]; // write address
   M[$input_cbuffer_struc + 1 ] = r0;

   r0 = M[$dac_out_cbuffer_struc + 2]; // write address
   M[$dac_out_cbuffer_struc + 1 ] = r0;
   
   r0 = M[$frame_process_out_cbuffer_struc + 2]; // write address
   M[$frame_process_out_cbuffer_struc + 1 ] = r0;

   r0 = $L2CAP_IN_PORT;
   call $cbuffer.empty_buffer;    
    
   call $unblock_interrupts;
    
   jump rebuffer;
   
sync_error:
   // This should never happen because the Soundbar only sends complete frames.
   r0 = M[$sync_error_counter];
   r0 = r0 + 1;
   M[$sync_error_counter] = r0;
   
   jump bin_data;

check_underflow:
   // We don't have input data.  If we're running out of DAC data we need to
   // fade out volume, and re-buffer data by cancelling $l2cap_copy_handler and
   // scheduling $input_check_data_handler.
   
   r3 = Null;
   r0 = $input_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r3 = r3 + r0;
   r0 = $frame_process_in_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   r3 = r3 + r0;
   r0 = $dac_out_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   r3 = r3 + r0;

   Null = r3 - 100;
   if POS jump done;    
   
   r1 = M[$underflow_counter];
   r1 = r1 + 1;
   M[$underflow_counter] = r1;

rebuffer:
   // Running short on data.
   // Cancel copying from port so we can buffer up data.
   r2 = M[$l2cap_copy_handler_id]; 
   call $timer.cancel_event;
   
   r1 = &$input_check_data_timer_struc;
   r2 = $TMR_PERIOD_CHECK_DATA;
   r3 = &$input_check_data_handler;
   call $timer.schedule_event_in;

   // reset rate detect algorithm
   M[r8 + $subwoofer_rate_detect.COUNTER] = Null;
   M[r8 + $subwoofer_rate_detect.ACCUMULATOR] = Null;

   jump done;

.ENDMODULE;


.MODULE $M.l2cap_schedule_first_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
    
   .VAR $first_wall_clock_from_payload;
   .VAR $gobble_counter;
   .VAR $current_rate;
   .VAR $first_time_to_play_from_payload;
   
   $l2cap_schedule_first_handler:
   
   $push_rLink_macro;
   
   // check for enough input data
   r0 = $L2CAP_IN_PORT_HEADER;
   call $cbuffer.calc_amount_data;
   Null = r0 - $L2CAP_FRAME_SIZE;
   if NEG jump not_enough_data;
   
   // check for enough output space
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $L2CAP_FRAME_SIZE;
   if NEG jump not_enough_space;
   
   // get write address
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   // get read address
   r0 = $L2CAP_IN_PORT_HEADER;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;
         
   // read header sync word
   r0 = M[I0,1];
   M[I4,1] = r0;
   Null = r0 - 0xf5f5;
   if NZ jump sync_error;

   // read packet counter and time Soundbar wrote to MMU port
   r0 = M[I0,1];        // LSW of packet counter
   M[I4,1] = r0;
   r1 = M[I0,1];        // packet counter, SoundbarTxTime
   M[I4,1] = r1;
   r2 = r1 AND 0xFF00;  // MSB of packet counter
   r2 = r2 LSHIFT 8;
   r0 = r2 + r0;
   M[$local_packet_counter] = r0;  // 24-bit counter

   // read time Soundbar will play the framefrom payload
   r0 = r1 LSHIFT 16;   // MSB of SoundbarTxTime 
   r1 = M[I0,1];        // LSW of SoundbarTxTime
   M[I4,1] = r1;
   r1 = r1 AND 0xFFFF;  // TODO: shouldn't need this since sign extension is off
   r0 = r0 + r1;
   M[$first_wall_clock_from_payload] = r0;
   
   // Read time that Soundbar will play
   r0 = M[I0,1];        // MSB of current warp, MSB of TIME_SB_WILL_PLAY    
   M[I4,1] = r0;
   r2 = r0 AND 0xFF00;  // MSB of current warp
   r2 = r2 LSHIFT 8;
   r0 = r0 LSHIFT 16;
   r1 = M[I0,1];        // LSW of TIME_SB_WILL_PLAY
   M[I4,1] = r1;
   r1 = r1 AND 0xFFFF;
   r0 = r0 + r1;
   r1 = M[I0,1];        // LSB of current warp
   M[I4,1] = r1;
   r1 = r2 + r1;
   M[$current_rate] = r1;
   M[$first_time_to_play_from_payload] = r0;

   // set read address
   r0 = $L2CAP_IN_PORT_HEADER;
   r1 = I0;
   call $cbuffer.set_read_address;
   
   // get read address
   r0 = $L2CAP_IN_PORT;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   // read audio samples into buffer
   r10 = $L2CAP_AUDIO_SIZE;
   do copy_audio;
      r1 = M[I0,1];
      M[I4,1] = r1;
   copy_audio:
   
   r0 = $L2CAP_IN_PORT;
   r1 = I0;
   call $cbuffer.set_read_address;
   
   r1 = I4;   
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.set_write_address;
   
   L4 = Null;
   L0 = Null;

   // get current time
   r1 = M[$wall_clock_adjustment];
   r1 = r1 + M[$TIMER_TIME];

   // schedule first timer
   r0 = M[$first_wall_clock_from_payload];
   r1 = r1 - r0;                    // r1 = SoundbarTxTime - CurrentTime ;
   r2 = $L2CAP_JITTER_TIME - r1;    // Ensure elapsed time does not exceed jitter time.
   r2 = r2 - 5000;                  // Note that if we remove this line, we might not need the delay buffer.
     
   if NEG jump data_is_too_old; 
   r1 = &$l2cap_timer_struc;
   r3 = &$l2cap_copy_handler;
   call $timer.schedule_event_in;
   M[$l2cap_copy_handler_id] = r3;
   
success:
   r1 = 1;
   M[$first_l2cap_copy_handler] = r1;

done:
   L4 = Null;
   L0 = Null;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
not_enough_data:
not_enough_space:
data_is_too_old:
sync_error:

   r0 = $L2CAP_IN_PORT_HEADER;
   r1 = I0;
   call $cbuffer.set_read_address;
   
   // flush the port
   r0 = $L2CAP_IN_PORT;
   call $cbuffer.empty_buffer;
    
   r1 = &$input_check_data_timer_struc;
   r2 = $TMR_PERIOD_CHECK_DATA;
   r3 = &$input_check_data_handler;
   call $timer.schedule_event_in;

   r1 = M[$gobble_counter];
   r1 = r1 + 1;
   M[$gobble_counter] = r1;

   jump done;

.ENDMODULE;


.MODULE $M.l2cap_copy_handler;
   .CODESEGMENT PM;

   $l2cap_copy_handler:
   
   $push_rLink_macro;

   M[$frame_sync.sync_flag] = Null;

   // check for enough input data
   r0 = $L2CAP_IN_PORT_HEADER;
   call $cbuffer.calc_amount_data;
   Null = r0 - $L2CAP_FRAME_SIZE;
   if NEG jump not_enough_data;
   
   // check for enough output space
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.calc_amount_space;
   Null = r0 - $L2CAP_FRAME_SIZE;
   if NEG jump not_enough_space;
   
   // copy header into $l2cap_codec_cbuffer
   r0 = $L2CAP_IN_PORT_HEADER;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;
   
   r10 = $L2CAP_HEADER_SIZE; 
   do copy_header_loop;
      r0 = M[I0,1];
      M[I4,1]=r0;
   copy_header_loop:

   r1 = I0;   
   r0 = $L2CAP_IN_PORT_HEADER;
   call $cbuffer.set_read_address;

   // copy audio frame into $l2cap_codec_cbuffer
   r0 = $L2CAP_IN_PORT;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;
   
   r10 = $L2CAP_AUDIO_SIZE;
   do copy_audio_loop;
      r0 = M[I0,1];
      M[I4,1]=r0;
   copy_audio_loop:

   r1 = I0;   
   r0 = $L2CAP_IN_PORT;
   call $cbuffer.set_read_address;

   r1 = I4;   
   r0 = $l2cap_codec_cbuffer_struc;
   call $cbuffer.set_write_address;

   L0 = Null;
   L4 = Null;
   
   Null = M[$first_l2cap_copy_handler];
   if Z jump not_first_handler;
      M[$first_l2cap_copy_handler] = Null;
      r1 = 1;   
      M[$just_started_streaming_flag] = r1;
      M[$buffering_flag] = Null;

not_first_handler:
not_enough_data:
not_enough_space:

   r2 = 1500;   // TODO: determine rate
   r1 = &$l2cap_timer_struc;
   r3 = &$l2cap_copy_handler;
   call $timer.schedule_event_in_period;
   M[$l2cap_copy_handler_id] = r3;
  
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
