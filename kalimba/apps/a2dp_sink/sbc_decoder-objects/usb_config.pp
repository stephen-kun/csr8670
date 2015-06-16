.linefile 1 "usb_config.asm"
.linefile 1 "<command-line>"
.linefile 1 "usb_config.asm"


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stack.h" 1
.linefile 4 "usb_config.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/usbio.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/usbio.h"
.CONST $USB_STALL_CNT_THRESH 7;


.CONST $frame_sync.SYNC_MASK 0x7f;


.CONST $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD 0;
.CONST $frame_sync.USB_IN_STEREO_COPY_LEFT_SINK_FIELD 1;
.CONST $frame_sync.USB_IN_STEREO_COPY_RIGHT_SINK_FIELD 2;
.CONST $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD 3;
.CONST $frame_sync.USB_IN_STEREO_COPY_SHIFT_AMOUNT_FIELD 4;
.CONST $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD 5;
.CONST $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD 6;
.CONST $frame_sync.USB_IN_STEREO_STATE_FIELD 7;
.CONST $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD 8;
.CONST $frame_sync.USB_IN_STEREO_COPY_RETRY_FIELD 9;
.CONST $frame_sync.USB_IN_STEREO_COPY_STRUC_SIZE 10;



.CONST $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD 0;
.CONST $frame_sync.USB_IN_MONO_COPY_SINK_FIELD 1;
.CONST $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD 2;
.CONST $frame_sync.USB_IN_MONO_COPY_SHIFT_AMOUNT_FIELD 3;
.CONST $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD 4;
.CONST $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD 5;
.CONST $frame_sync.USB_IN_MONO_STATE_FIELD 6;
.CONST $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD 7;
.CONST $frame_sync.USB_IN_MONO_COPY_RETRY_FIELD 8;
.CONST $frame_sync.USB_IN_MONO_COPY_STRUC_SIZE 9;



.CONST $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD 0;
.CONST $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD 1;
.CONST $frame_sync.USB_OUT_STEREO_SINK_FIELD 2;
.CONST $frame_sync.USB_OUT_STEREO_SHIFT_AMOUNT_FIELD 3;
.CONST $frame_sync.USB_OUT_STEREO_TRANSFER_PER_PERIOD_FIELD 4;
.CONST $frame_sync.USB_OUT_STEREO_STALL_CNT_FIELD 5;
.CONST $frame_sync.USB_OUT_STEREO_STRUC_SIZE 6;



.CONST $frame_sync.USB_OUT_MONO_SOURCE_FIELD 0;
.CONST $frame_sync.USB_OUT_MONO_SINK_FIELD 1;
.CONST $frame_sync.USB_OUT_MONO_SHIFT_AMOUNT_FIELD 2;
.CONST $frame_sync.USB_OUT_MONO_TRANSFER_PER_PERIOD_FIELD 3;
.CONST $frame_sync.USB_OUT_MONO_STALL_CNT_FIELD 4;
.CONST $frame_sync.USB_OUT_MONO_STRUC_SIZE 5;

.CONST $frame_sync.IDLE_STATE 0;
.CONST $frame_sync.SYNCING_A_STATE 1;
.CONST $frame_sync.SYNCING_B_STATE 2;
.CONST $frame_sync.SYNCED_STATE 3;
.linefile 5 "usb_config.asm" 2


.MODULE $M.usb;
   .DATASEGMENT DM;


   .VAR $usb_rate_candidates[] =
      48000, 192, 0,
      8000, 32, 0,
      16000, 64, 0,
      22050, 92, 20,
      32000, 128, 0,
      44100, 180, 10,
      0;

.ENDMODULE;
.linefile 39 "usb_config.asm"
.MODULE $M.config_usb;
   .CODESEGMENT PM;

   $config_usb:

   r0 = $usb_rate_candidates;
   I0 = r0;

   M0 = 2;

   r0 = M[$current_codec_sampling_rate];
   rate_loop:

      r1 = M[I0,1];
      null = r1;
      if Z jump error;
      null = r1 - r0;
      if Z jump done;

      r1 = M[I0,M0];

   jump rate_loop;

   error:
   I0 = $usb_rate_candidates + 1;

   done:


   r0 = M[I0,1];
   M[r8 + $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD] = r0;


   r0 = M[I0,1];
   M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD] = r0;

   rts;

.ENDMODULE;
.linefile 101 "usb_config.asm"
.MODULE $M.usb_state_mc;
   .CODESEGMENT PM;
   .DATASEGMENT DM;


   .CONST PAUSED 0;
   .CONST WAITING_TO_START 1;
   .CONST RUNNING 2;

   .CONST SILENCE_INSERTION_TIME 0.006;
   .CONST PAUSE_THRESH 3;


   .VAR $usb_fn_table[] = paused_fn, waiting_to_start_fn, running_fn;

   .VAR $usb_state = PAUSED;

   .VAR $usb_pause_period_count;
   .VAR $usb_pause_period_thresh = PAUSE_THRESH;
   .VAR $usb_pause_silence_insertion_time = SILENCE_INSERTION_TIME;


   $run_usb_state_mc:


      push rLink;


      r0 = $CON_IN_PORT;
      call $cbuffer.calc_amount_data;


      r3 = M[$usb_state];
      r1 = M[$usb_fn_table + r3];



      call r1;


      M[$usb_state] = r3;


      jump $pop_rLink_and_rts;





   paused_fn:


      push rLink;


      r0 = $CON_IN_PORT;
      call $cbuffer.empty_buffer;


      call $master_app_reset;


      r3 = WAITING_TO_START;



      r0 = 1;
      M[$M.jitter_buffering.is_buffering] = r0;


      jump $pop_rLink_and_rts;


   waiting_to_start_fn:


      push rLink;

      null = r0;
      if Z jump still_waiting_to_start;


         M[$usb_pause_period_count] = 0;


         r0 = M[$current_codec_sampling_rate];
         r1 = M[$usb_pause_silence_insertion_time];
         r5 = r0 * r1 (frac);


         r4 = $audio_out_left_cbuffer_struc;
         call $audio_prime_silence;
         r4 = $audio_out_right_cbuffer_struc;
         call $audio_prime_silence;



         call r7;

         r3 = RUNNING;

      still_waiting_to_start:


      jump $pop_rLink_and_rts;


   running_fn:


      push rLink;

      r5 = PAUSED;

      r4 = M[$usb_pause_period_count];
      r4 = r4 + 1;

      null = r0;
      if NZ r4 = 0;
      M[$usb_pause_period_count] = r4;

      null = r4 - M[$usb_pause_period_thresh];
      if POS r3 = r5;

      push r3;


      call r7;
      pop r3;


      jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 252 "usb_config.asm"
.MODULE $M.audio_prime_silence;
    .CODESEGMENT PM;

$audio_prime_silence:


   push rLink;


   r0 = r4;
   call $cbuffer.empty_buffer;


   r0 = r4;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;


   r10 = r5;


   r0 = 0;


   do audio_fill_loop;
     M[I0,1] = r0;
   audio_fill_loop:


   r0 = r4;
   r1 = I0;
   call $cbuffer.set_write_address;
   L0 = 0;


   jump $pop_rLink_and_rts;

.ENDMODULE;
