
#include "core_library.h"
#include "cbops_library.h"
#include "plc100_library.h"
#include "mips_profile.h"
#include "subwoofer.h"
#include "frame_sync_buffer.h"

.MODULE $M.plc100.subwoofer;
   .DATASEGMENT DM;

   .VAR/PLC100_CONST_DM $plc100.sw_consts[$plc100.consts.STRUC_SIZE] =     $plc100.SP_BUF_LEN_SW,		
                                                                           $plc100.OLA_LEN_SW,			
                                                                           $plc100.RANGE_SW,			
                                                                           $plc100.MIN_DELAY_SW,		
                                                                           $plc100.MAX_DELAY_SW,		
                                                                           $plc100.PER_TC_INV_SW,
                                                                           &$plc100.sw_ola_win;			

   .VAR/PLC100_OLAWIN_DM   $plc100.sw_ola_win[$plc100.OLA_LEN_SW] =  0x155555,
                                                                     0x400000,
                                                                     0x6AAAAA;

   

.ENDMODULE;

// ************************************************************************ //   

// ****************** TODO: move to library ******************************* //
.MODULE $M.cbops.iir_resample.1_2_to_48;
   .DATASEGMENT DM;

.BLOCK/DM1  filter;
       .VAR  fir_offset = 160;
       .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs; 
       .VAR  Input_Scale    = 2; // -6;
       .VAR  Output_Scale   = -1; // 5;
       .VAR  R_out          = 40;
       .VAR  frac_ratio     = 0.025000;
       //.VAR  int_ratio      = 0;   (down sample only)
       .VAR  iir_scale      = 2;
       .VAR  coeffs[10]= 0.6594444513320923,
                                   -0.0002225637435913,
                                   -0.0000116825103760,
                                   -0.0002832412719727,
                                    0.0002855062484741,
                                    0.0002199411392212,
                                    0.0179519653320313,
                                    0.1312066316604614,
                                    0.3992873430252075,
                                    0.5200430154800415;
.ENDBLOCK;
// Upsample
// L = 40
// fir_scale  = 2;
// IIR Gain = 88.931335 *(Rout/160)<<fir_scale = 44.465667
// FIR Gain = 1.000000
// fp : Nyquyst*(1-0.160000) = 0.010500
// rp : (0.025000)^2 = 0.000625
// -3dB cutoff = 1103.040000 Hz
// intermediate (history)         Q6.17;

// input              Q8.15<<input_scale  = Q6.17
// IIR coefficients   Q2.21  :  Q6.17 * Q2.21 = Q8.19 >> iir_scale = Q6.17  
// FIR coefficients   Q3.20  :  Q6.17 * Q3.20 = Q9.20 << out_scale = Q8.15  
.ENDMODULE;

// ****************************************************************************

.MODULE $M.main;
    .CODESEGMENT PM;
    .DATASEGMENT DM;
   
$main:
   
   .CONST  $SCO_IN_PORT_HEADER   (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_LITTLE_ENDIAN | $cbuffer.FORCE_16BIT_WORD) + 0);
   .CONST  $SCO_IN_PORT_AUDIO    (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO) + 0);
   .CONST  $L2CAP_IN_PORT_HEADER (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_LITTLE_ENDIAN | $cbuffer.FORCE_16BIT_WORD | $cbuffer.FORCE_NO_SIGN_EXTEND) + 1);
   .CONST  $L2CAP_IN_PORT        (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO) + 1);
   .CONST  $ADC_PORT             (($cbuffer.READ_PORT_MASK  + 2) | $cbuffer.FORCE_PCM_AUDIO);
   .CONST  $DAC_OUT_PORT         (($cbuffer.WRITE_PORT_MASK + 0) | $cbuffer.FORCE_PCM_AUDIO);
   .CONST  $I2S_OUT_PORT         (($cbuffer.WRITE_PORT_MASK + 1) | $cbuffer.FORCE_PCM_AUDIO);
      
   .VAR $audio_out_timer_struc[$timer.STRUC_SIZE];
   .VAR $l2cap_timer_struc[$timer.STRUC_SIZE];
   .VAR/DMCIRC $input[$INPUT_CBUFFER_SIZE];
   .VAR/DMCIRC $l2cap_codec_cbuffer[$INPUT_CBUFFER_SIZE];
   .VAR/DMCIRC $frame_process_in[$OUTPUT_CBUFFER_SIZE];
   .VAR/DMCIRC $frame_process_out[$OUTPUT_CBUFFER_SIZE];
   .VAR/DMCIRC $dac_out[$OUTPUT_CBUFFER_SIZE_L2CAP_RATE_MATCHING];

   .VAR $input_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($input),             // size
      &$input,                    // read pointer
      &$input;                    // write pointer
      
   .VAR $l2cap_codec_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($l2cap_codec_cbuffer),             // size
      &$l2cap_codec_cbuffer,                    // read pointer
      &$l2cap_codec_cbuffer;                    // write pointer

   .VAR $frame_process_in_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($frame_process_in),             // size
      &$frame_process_in,                    // read pointer
      &$frame_process_in + 39;               // write pointer  // TODO: find out why resampler only generates 321 samples the first go.

  .VAR $frame_process_out_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($frame_process_out),             // size
      &$frame_process_out,                    // read pointer
      &$frame_process_out;                    // write pointer

  .VAR $dac_out_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($dac_out),             // size
      &$dac_out,                    // read pointer
      &$dac_out;                    // write pointer

 // ADC Input operator chain
   .VAR $adc_in_copy_struc[] =
#ifdef KAL_ARCH2   
      $upsample_32000_to_48000_op,        // upsample from 32K to 48K on BC5MM
#else      
      &$adc_copy_op,                      // First operator block
#endif     
      1,                                  // Number of inputs
      &$ADC_PORT,                         // Input
      1,                                  // Number of outputs
      &$frame_process_in_cbuffer_struc;   // Output


#ifdef KAL_ARCH2
.VAR/DM1CIRC  $adc_fir_buf_L[$cbops.IIR_UPSAMPLE_FIR_BUFFER_SIZE];
.VAR/DM2CIRC  $adc_iir_buf_L[$cbops.IIR_RESAMPLE_IIR_BUFFER_SIZE];
.BLOCK $upsample_32000_to_48000_op;
      .VAR $upsample_32000_to_48000_op.next = $audio_in_dc_remove_op;
      .VAR $upsample_32000_to_48000_op.func = $cbops.mono_iir_upsample;
      .VAR $upsample_32000_to_48000_op.param[$cbops.mono.iir_resample.STRUC_SIZE] =
         0,                                           // INPUT_1_START_INDEX_FIELD
         1,                                           // OUTPUT_1_START_INDEX_FIELD
         &$M.cbops.iir_resample.32_to_48.filter,      // FILTER_DEFINITION_PTR_FIELD
         0,                                           // INPUT_SCALE_FIELD
         8,                                           // OUTPUT_SCALE_FIELD,
         0,                                           // SAMPLE_COUNT_FIELD,
         &$adc_iir_buf_L,                             // IIR_HISTORY_BUF_PTR_FIELD,
         &$adc_fir_buf_L,                             // FIR_HISTORY_BUF_PTR_FIELD
         1;                                           // RESET_FLAG_FIELD
   .ENDBLOCK;
#else
   .BLOCK $adc_copy_op;                                                                     
      .VAR adc_copy_op.next = &$audio_in_dc_remove_op;                                       
      .VAR adc_copy_op.func = &$cbops.shift;                                            
      .VAR adc_copy_op.param[$cbops.shift.STRUC_SIZE] =                                 
         0,    /* Input index field (ADC cbuffer) */                                               
         1,    /* Output index field (SIDE TONE cbuffer) */                                        
         8;    /* Shift parameter field */                                                         
   .ENDBLOCK;  
#endif

   .BLOCK $audio_in_dc_remove_op;
      .VAR audio_in_dc_remove_op.next = &$audio_in_noise_gate_op;
      .VAR audio_in_dc_remove_op.func = &$cbops.dc_remove;
      .VAR audio_in_dc_remove_op.param[$cbops.dc_remove.STRUC_SIZE] =
         1,                      // Input index (right cbuffer)
         1,                      // Output index (right cbuffer)
         0 ...;
   .ENDBLOCK;

   .BLOCK $audio_in_noise_gate_op;
      .VAR audio_in_noise_gate_op.next = &$signal_detect_adc_op;
      .VAR audio_in_noise_gate_op.func = &$cbops.noise_gate;
      .VAR audio_in_noise_gate_op.param[$cbops.noise_gate.STRUC_SIZE] =
         1,                      // Input index (left cbuffer)
         1,                      // Output index (left cbuffer)
         0 ...;
   .ENDBLOCK;

   .BLOCK $signal_detect_adc_op;
#ifdef KAL_ARCH2
      .VAR $signal_detect_adc_op.next = $comlete_32k_48k_upsample_op;
#else
      .VAR $signal_detect_adc_op.next = $cbops.NO_MORE_OPERATORS;
#endif      
      .VAR $signal_detect_adc_op.func = &$cbops.signal_detect_op;
      .VAR $signal_detect_adc_op.param[$cbops.signal_detect_op.STRUC_SIZE_MONO] =
         &$signal_detect_adc_op_coefs,    // pointer to coefficients
         1,                               // number of channels to process
         1;                               // channel index
   .ENDBLOCK;

    .var $signal_detect_adc_op_coefs[$cbops.signal_detect_op_coef.STRUC_SIZE] = 
         0,                               // detection threshold
         0,                               // trigger time
         0,                               // current max value
         0,                               // signal detected timeout timer
         1,                               // signal status (1 = playing audio)
         $music_example.VMMSG.SIGNAL_DETECT_STATUS; // ID for status message sent to VM


#ifdef KAL_ARCH2
   .BLOCK $comlete_32k_48k_upsample_op;
      .VAR $comlete_32k_48k_upsample_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $comlete_32k_48k_upsample_op.func = &$cbops.iir_resample_complete;
   .ENDBLOCK;     
#endif      

    


   // INPUT Operator chain with ESCO and L2CAP:
   .VAR $upsample_copy_struc[] =
      &$signal_detect_op,                 // First operator block
      1,                                  // Number of inputs
      &$input_cbuffer_struc,              // Input
      1,                                  // Number of outputs
      &$frame_process_in_cbuffer_struc;   // Output

   // TODO: may want to move signal detect.  Right now it's after PLC so during a bad link
   // condition we'll be basing signal detection on an artificial signal.

   .BLOCK $signal_detect_op;
      .VAR $signal_detect_op.next = $upsample_1200_to_48000_op;
      .VAR $signal_detect_op.func = &$cbops.signal_detect_op;
      .VAR $signal_detect_op.param[$cbops.signal_detect_op.STRUC_SIZE_MONO] =
         &$signal_detect_op_coefs,        // pointer to coefficients
         1,                               // number of channels to process
         0;                               // channel index
   .ENDBLOCK;

    .var $signal_detect_op_coefs[$cbops.signal_detect_op_coef.STRUC_SIZE] = 
         0,                               // detection threshold
         0,                               // trigger time
         0,                               // current max value
         0,                               // signal detected timeout timer
         1,                               // signal status (1 = playing audio)
         $music_example.VMMSG.SIGNAL_DETECT_STATUS; // ID for status message sent to VM

   .VAR/DM1CIRC  $fir_buf_L[$cbops.IIR_UPSAMPLE_FIR_BUFFER_SIZE];
   .VAR/DM2CIRC  $iir_buf_L[$cbops.IIR_RESAMPLE_IIR_BUFFER_SIZE];

   .BLOCK $upsample_1200_to_48000_op;
      .VAR $upsample_1200_to_48000_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $upsample_1200_to_48000_op.func = $cbops.mono_iir_upsample;
      .VAR $upsample_1200_to_48000_op.param[$cbops.mono.iir_resample.STRUC_SIZE] =
         0,                                         // INPUT_1_START_INDEX_FIELD
         1,                                         // OUTPUT_1_START_INDEX_FIELD
         &$M.cbops.iir_resample.1_2_to_48.filter,   // FILTER_DEFINITION_PTR_FIELD
         -8,                                        // INPUT_SCALE_FIELD
         7,                                         // OUTPUT_SCALE_FIELD,
         0,                                         // SAMPLE_COUNT_FIELD,
         &$iir_buf_L,                               // IIR_HISTORY_BUF_PTR_FIELD,
         &$fir_buf_L,                               // FIR_HISTORY_BUF_PTR_FIELD
         1;                                         // RESET_FLAG_FIELD
   .ENDBLOCK;

// OUPUT Operator chain:   
   .VAR $warp_out_copy_struc[] =
      &$audio_out_rate_adjustment_and_shift_op_mono,  // First operator block
      1,                                              // Number of inputs
      &$frame_process_out_cbuffer_struc,              // Input
      1,                                              // Number of outputs
      &$dac_out_cbuffer_struc;                        // Output

   .VAR $soundbar_subwoofer_rate_adjustment = 0;
   .VAR/DM1CIRC $sr_hist_left[12];
   .BLOCK $audio_out_rate_adjustment_and_shift_op_mono;
      .VAR $audio_in_rate_adjustment_and_shift_op_mono.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_in_rate_adjustment_and_shift_op_mono.func = &$cbops.rate_adjustment_and_shift;
      .VAR $audio_in_rate_adjustment_and_shift_op_mono.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
         0,  //   INPUT1_START_INDEX_FIELD
         1,  //   OUTPUT1_START_INDEX_FIELD
         -1, //   INPUT2_START_INDEX_FIELD
         -1, //   OUTPUT2_START_INDEX_FIELD
         0, //   SHIFT_AMOUNT_FIELD
         &$sra_coeffs,
         &$sr_hist_left,
         0,
         &$soundbar_subwoofer_rate_adjustment,
         $cbops.dither_and_shift.DITHER_TYPE_NONE,  // DITHER_TYPE_FIELD - Must be none so we can copy many samples.
         0 ...;                                     // Pad out remaining items with zeros
   .ENDBLOCK;


  .VAR $dac_out_copy_struc[] =
      &$audio_out_volume,            // First operator block
      1,                             // Number of inputs
      &$dac_out_cbuffer_struc,       // Input
      1,                             // Number of outputs
      $DAC_OUT_PORT;                 // Output
 
   .BLOCK $audio_out_volume;

  .VAR audio_out_volume.next = &$audio_out_dither_and_shift_op;
  .VAR audio_out_volume.func = &$cbops.volume;
      .VAR audio_out_volume.param[$cbops.volume.STRUC_SIZE] =
         0,                               // Input index
         0,                               // Output index
         0,                               // Final Gain Value
         1,                               // Current Gain Value
         50,                              // samples per step,
         -4,                              // step shift field 
         0.02,                            // delta field        
         0;                               // current step field
   .ENDBLOCK;

      .VAR/DM1CIRC $sr_hist_left2[12];
      .BLOCK $audio_out_rate_adjustment_and_shift_op_mono2;
      .VAR $audio_in_rate_adjustment_and_shift_op_mono2.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_in_rate_adjustment_and_shift_op_mono2.func = &$cbops.rate_adjustment_and_shift;
      .VAR $audio_in_rate_adjustment_and_shift_op_mono2.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
         0,  //   INPUT1_START_INDEX_FIELD
         1,  //   OUTPUT1_START_INDEX_FIELD
         -1, //   INPUT2_START_INDEX_FIELD
         -1, //   OUTPUT2_START_INDEX_FIELD
         -8, //   SHIFT_AMOUNT_FIELD
         &$sra_coeffs,
         &$sr_hist_left2,
         0,
         &$current_rate,
         $cbops.dither_and_shift.DITHER_TYPE_NONE,  //   DITHER_TYPE_FIELD
         0 ...;                                     // Pad out remaining items with zeros
    .ENDBLOCK;

   .VAR/DM1CIRC $dither_hist[$cbops.dither_and_shift.FILTER_COEFF_SIZE];
   .BLOCK $audio_out_dither_and_shift_op;
      .VAR $audio_out_dither_and_shift_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $audio_out_dither_and_shift_op.func = &$cbops.dither_and_shift;
      .VAR $audio_out_dither_and_shift_op.param[$cbops.dither_and_shift.STRUC_SIZE] =
         0,                                        // Input index
         1,                                        // Output index
        -8,                                        // amount of shift after dithering
         $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
         $dither_hist,                             // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
         0;                                        // Enable compressor
   .ENDBLOCK;

   // PLC data structure
#ifdef KAL_ARCH2
   .VAR/DM1CIRC buffer_speech[$plc100.SP_BUF_LEN_SW];
#else
   .VAR/DM1 buffer_speech[$plc100.SP_BUF_LEN_SW];
#endif

   .VAR/DM buffer_ola[$plc100.OLA_LEN_SW];
   .VAR/DM plc_obj[$plc100.STRUC_SIZE] = 
      &buffer_speech,                    // SPEECH_BUF_PTR_FIELD: 0
      &buffer_speech,                    // SPEECH_BUF_PTR_FIELD: 1
      &buffer_ola,                       // OLA_BUF_PTR_FIELD:    2
      &$input_cbuffer_struc,             // OUTPUT_PTR_FIELD:     3
      &$plc100.sw_consts,                // CONSTS_FIELD:         4
      1.0,                               // ATTENUATION_FIELD:    5
      0.3,                               // PER_THRESHOLD_FIELD:  6
      0 ...;

   // MIPS data structure
   .VAR $FunctionMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
     0,                                 // STAT
     0,                                 // TMAIN
     0,                                 // SMAIN
     0,                                 // TINT
     0,                                 // SINT
     0,                                 // SMAIN_INT
     0,                                 // MAIN_CYCLES
     0,                                 // INT_CYCLES
     0,                                 // TOT_CYCLES
     0;                                 // TEVAL

      
   // PORT Connected Functions:
   .VAR read_port_function_table[] =
        &esco_port_connected, &l2cap_port_connected, &adc_port_connected; 

   .VAR write_port_function_table[] =
        &dac_port_connected, &i2s_port_connected;

   // WALL CLOCK structures:
   .VAR $bdaddr_message_struc[$message.STRUC_SIZE];
   .VAR $sco_params_message_struc[$message.STRUC_SIZE];
   .VAR $wall_clock_message_struc[$message.STRUC_SIZE];    

   .VAR $sco_timer_struc[$timer.STRUC_SIZE];
   .VAR $wall_clock_timer_struc[$timer.STRUC_SIZE];

   .VAR $bdaddr_struc[4];
   .VAR $wall_clock_msw;
   .VAR $wall_clock_lsw;
   .VAR $wall_clock_time;
   .VAR $sco_param_tesco = 0;
   .VAR $sco_param_wesco = 0;
   .VAR $sco_param_clock_msw;
   .VAR $sco_param_clock_lsw;
   .VAR $sco_param_to_air_size;
   .VAR $sco_param_from_air_size;
   .VAR $sco_param_to_air_time;
   .VAR $sco_param_from_air_time;
   .VAR $sco_timer_id = 0;
   .VAR $sub_dac_sampling_rate = 48000;
   .VAR $dac_copies;


   .VAR/DM1 $samples_per_us_sbc[4] = 0, 0, 0.041, 0.048;
   // us per sample is in q5.19
   .VAR/DM1 $us_per_sample_sbc[4] = 0, 0, 0.708616780045352, 0.651041666666667;
   .VAR $warp_amount = 0;

      // buffers that are after Frame Processing
      .VAR $output_buffers[] = 
         &$dac_out_cbuffer_struc,
         &$us_per_sample_sbc + 2,            // inverse sample_rate Q5.19
         0;
      
      .VAR $active_port = $DAC_OUT_PORT;
      .VAR $output_port_and_delay_size[] = 
         &$active_port,               // TODO: consider using $audio_if_mode
         &$us_per_sample_sbc + 2,     // port sample rate
         0,
         &$us_per_sample_sbc + 2,     // delay sample rate         
         &$warp_amount,               // TODO: see if this exists somewhere
         0;                           // TIME_TO_PLAY
         
   .CONST $subwoofer_rate_detect.COUNTER                               0;
   .CONST $subwoofer_rate_detect.COUNTER_THRESHOLD                     1;
   .CONST $subwoofer_rate_detect.ACCUMULATOR                           2;
   .CONST $subwoofer_rate_detect.COUNTER_THRESHOLD_RECIP               3;
   .CONST $subwoofer_rate_detect.AMOUNT_LAST_TIME                      4;
   .CONST $subwoofer_rate_detect.EXPECTED_NUM_SAMPLES_RECIP_Q20        5;
   .CONST $subwoofer_rate_detect.STRUC_SIZE                            6;
 
   .VAR $rate_detection_obj[$subwoofer_rate_detect.STRUC_SIZE] = 
       0,                                         // COUNTER
       $THIRTY_SECONDS_ESCO,                      // COUNTER_THRESHOLD
       0,                                         // ACCUMULATOR
       2048,                                      // COUNTER_THRESHOLD_RECIP
       0,                                         // AMOUNT_LAST_TIME
       5965232;                                   // EXPECTED_NUMBER_OF_SAMPLES_RECIP_Q20

   .VAR $l2cap_rate_detection_obj[$subwoofer_rate_detect.STRUC_SIZE] = 
       0,                                         // COUNTER
       $THIRTY_SECONDS_ESCO/2,                    // COUNTER_THRESHOLD (The L2CAP counter size is half of the ESCO counter size because because L2CAP frames are twice the size of ESCO frames.)
       0,                                         // ACCUMULATOR
       2048*2,                                    // COUNTER_THRESHOLD_RECIP
       0,                                         // AMOUNT_LAST_TIME
       5965232;                                   // EXPECTED_NUMBER_OF_SAMPLES_RECIP_Q20

   // initialise the stack library
   call $stack.initialise;
   // initialise the interrupt library
   call $interrupt.initialise;
   // initialise the message library
   call $message.initialise;
   // initialise the cbuffer library
   call $cbuffer.initialise;
   // initialise the pskey library
   call $pskey.initialise;
   // init DM_flash
   call $flash.init_dmconst;

#ifdef USES_PATCH
   // initialize Patch Libary   
   R1 = 0x0293;  // PSKEY_ID.  PsKey Holding first patch – may not exist.  0x0293 = PSKEY_USR9. 
   r2 = &$input;  // just need a temporary buffer, which is at least 128 words in size.
   call $KapLoader.LoadPatch;
#endif

   // initialise the wallclock library
   call $wall_clock.initialise;
   // initialise PLC library
   r7 = plc_obj;
   call $plc100.initialize;

   // register message handler for bt address
   r1 = &$bdaddr_message_struc;
   r2 = $MESSAGE_PORT_BT_ADDRESS;
   r3 = &$bdaddr_message_handler;
   call $message.register_handler;

   // register message handler for sco parameters 
   r1 = &$sco_params_message_struc;
   r2 = $LONG_MESSAGE_SCO_PARAMS_RESULT;
   r3 = &$sco_params_message_handler;
   call $message.register_handler;

   // set up message hander for $LONG_MESSAGE_WALL_CLOCK_RESPONSE message
   r1 = &$wall_clock_message_struc;
   r2 = $LONG_MESSAGE_WALL_CLOCK_RESPONSE_TBTA;
   r3 = &$wall_clock_message_handler;
   call $message.register_handler;
   
   // Register port connection call back functions
   // Be careful - these are used in $sco_timing.initialize
   r0 = &read_port_connected_handler;
   M[$cbuffer.read_port_connect_address] = r0;
   r0 = &write_port_connected_handler;
   M[$cbuffer.write_port_connect_address] = r0;
   
   // intialize SPI communications library
   call $spi_comm.initialize;
   
   // Power Up Reset needs to be called once during program execution
   call $music_example.power_up_reset;


   // Send READY message to plugin so it can connect streams and send other
   // DSP messages
   r2 = $music_example.VMMSG.READY;
   r3 = $SUBWOOFER_SYSID;
   r4 = M[$music_example.Version];
   r4 = r4 LSHIFT -8;
   call $message.send_short;
   
   // tell vm we're ready and wait for the go message
   call $message.send_ready_wait_for_go;

   frame_loop:
      // Check Communication
      call $spi_comm.polled_service_routine;

      r0 = M[$music_example.link_type];
      Null = r0 - $M.SUBWOOFER.INPUT_TYPE.ADC;
      if Z jump adc_mode;
      Null = r0 - $M.SUBWOOFER.INPUT_TYPE.L2CAP;
      if Z jump l2cap_mode;
      Null = r0 - $M.SUBWOOFER.INPUT_TYPE.ESCO;
      if Z jump esco_mode;
      // else
      jump frame_loop;

      adc_mode:
         // Sleep until interrupt fires.
         call $frame_sync.1ms_delay;
         r0 = $frame_process_in_cbuffer_struc;
         call $cbuffer.calc_amount_data;
         Null = r0 - $music_example.NUM_SAMPLES_PER_FRAME;
         if NEG jump frame_loop;
         call $music_example_process;
         jump frame_loop;

      l2cap_mode:
         // Sleep until interrupt fires.
         call $frame_sync.1ms_delay;
         call $l2cap_process;
         jump frame_loop;
         
      esco_mode:
         // ESCO MODE
         call $timer.1ms_delay;
         jump frame_loop;
   
   // Port handler functions
read_port_connected_handler:
   // r1 = port ID
   // 0 = ESCO
   // 1 = L2CAP
   // 2 = ADC
   r0 = M[read_port_function_table + r1];
   jump r0;

write_port_connected_handler:
   // r1 = port ID
   // 0 = DAC
   // 1 = I2S
   r1 = r1 - $cbuffer.WRITE_PORT_OFFSET;  // TODO: validate for ports other than 0, and Elvis.
   r0 = M[write_port_function_table + r1];
   jump r0;

adc_port_connected:
   $push_rLink_macro;
   r2 = M[$l2cap_copy_handler_id];
   call $timer.cancel_event;
   r2 = M[$l2cap_input_check_handler_id];
   call $timer.cancel_event;
   r1 = &$adc_dac_timer_struc;
   r2 = $TMR_PERIOD_ADC_DAC;
   r3 = &$adc_dac_handler;
   call $timer.schedule_event_in;
   r0 = $M.SUBWOOFER.INPUT_TYPE.ADC;
   M[$music_example.link_type] = r0;
   r0 = 1.0;
   M[$M.main.audio_out_volume.param + $cbops.volume.FINAL_VALUE_FIELD]= r0;
   jump $pop_rLink_and_rts;

esco_port_connected:
   // TODO - note we may have to request SCO parameters again
   $push_rLink_macro;   
   r2 = $MESSAGE_GET_BT_ADDRESS;
   r3 = $cbuffer.READ_PORT_MASK + r1;
   r4 = 0; 
   r5 = 0;
   r6 = 0;
   call $message.send;
   r0 = $M.SUBWOOFER.INPUT_TYPE.ESCO;
   M[$music_example.link_type] = r0;
   r2 = M[$adc_dac_id];
   call $timer.cancel_event;
   r0 = 1.0;
   M[$M.main.audio_out_volume.param + $cbops.volume.FINAL_VALUE_FIELD]= r0;
   
   // output of frame process goes into temporary buffer prior to going through warp.
   r0 = &$frame_process_out_cbuffer_struc;
   M[$M.system_config.data.stream_map_left_out + $framesync_ind.CBUFFER_PTR_FIELD] = r0;

   jump $pop_rLink_and_rts;

l2cap_port_connected:
   // start timer that copies codec input data
   $push_rLink_macro;
   r2 = $MESSAGE_GET_BT_ADDRESS;
   r3 = $cbuffer.READ_PORT_MASK + r1;
   r4 = 0; 
   r5 = 0;
   r6 = 0;
   call $message.send;
   r0 = $M.SUBWOOFER.INPUT_TYPE.L2CAP;
   M[$music_example.link_type] = r0;
   r2 = M[$adc_dac_id];
   call $timer.cancel_event;
   r0 = 1.0;
   M[$M.main.audio_out_volume.param + $cbops.volume.FINAL_VALUE_FIELD]= r0;

   // output of frame process goes into temporary buffer prior to going through warp.
   r0 = &$frame_process_out_cbuffer_struc;
   M[$M.system_config.data.stream_map_left_out + $framesync_ind.CBUFFER_PTR_FIELD] = r0;


   jump $pop_rLink_and_rts;

dac_port_connected:
   r1 = $DAC_OUT_PORT;
   M[$dac_out_copy_struc + 4] = r1;
   r1 = $M.SUBWOOFER.OUTPUT_TYPE.DAC;
   M[$music_example.output_type] = r1;
   rts;

i2s_port_connected:
   r1 = $I2S_OUT_PORT;
   M[$dac_out_copy_struc + 4] = r1;
   r1 = $M.SUBWOOFER.OUTPUT_TYPE.I2S;
   M[$music_example.output_type] = r1;
   rts;


.ENDMODULE;


// TODO: clean up code below.  Can probably use wall clock library and
// remove a bunch of this code.

// r0 = message ID
// r1 = message Data 0
// r2 = message Data 1
// r3 = message Data 2
// r4 = message Data 3
// word 0 - bits 0:6  - either type of port number
//          bit 7     - set on failure
//          bits 8:15 - type field of typed BDADDR
// word 1 - bits 47:32 of BDADDR
// word 2 - bits 31:16 of BDADDR
// word 3 - bits 15:0 of BDADDR

.MODULE $M.bdaddr_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $bdaddr_message_handler:

   $push_rLink_macro;   

   // store device address
   r1 = r1 LSHIFT -8;
   M[$bdaddr_struc + 0] = r1;  // type
   M[$bdaddr_struc + 1] = r2; // bits 47:32 of BDADDR
   M[$bdaddr_struc + 2] = r3; // bits 31:16 of BDADDR
   M[$bdaddr_struc + 3] = r4; // bits 15:0 of BDADDR

   // request wall clock
   r2 = Null OR $MESSAGE_GET_WALL_CLOCK_TBTA;
   r3 = M[$bdaddr_struc + 0];
   r4 = M[$bdaddr_struc + 1];
   r5 = M[$bdaddr_struc + 2];
   r6 = M[$bdaddr_struc + 3];
   call $message.send;

   // start wall clock update timer
   r1 = &$wall_clock_timer_struc;
   r2 = $WALL_CLOCK_UPDATE_PERIOD;
   r3 = &$wall_clock_timer_handler;
   call $timer.schedule_event_in;
    
   // pop rLink from stack
   jump $pop_rLink_and_rts;
    
.ENDMODULE;

// r0 = $message.LONG_MESSAGE_MODE_ID (a special flag to imply long message mode)
// r1 = long message ID (the actual ID of the message to send)
// r2 = long message size (in words)
// r3 = long message address of payload
//
// word 0 - type of BDADDR
// word 1 - bits 47:32 of BDADDR
// word 2 - bits 31:16 of BDADDR
// word 3 - bits 15:0 of BDADDR
// word 4 - MS 16bits of clock
// word 5 - LS 16bits of clock
// word 6 - MS 16bits of TIMER_TIME when the clock value was valid
// word 7 - LS 16bits of TIMER_TIME when the clock value was valid

.MODULE $M.wall_clock_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $wall_clock_adjustment;
   .VAR $l2cap_input_handler;

   $wall_clock_message_handler:

   $push_rLink_macro;   

   // store wall clock 
   r0 = M[r3 + 4];
   M[$wall_clock_msw] = r0;
   r0 = M[r3 + 5];
   M[$wall_clock_lsw] = r0;
   
   // store local time (convert to 24bit)
   r0 = M[r3 + 6];
   r1 = M[r3 + 7];
   r0 = r0 LSHIFT 16;
   r1 = r1 AND 0xFFFF;
   r1 = r1 + r0;
   M[$wall_clock_time] = r1;

// TODO: switch over to using wall clock library functions
   // calc: 'firmware wall clock' x FIRMWARE_WALL_CLOCK_PERIOD
   r1 = M[r3 + 4];
   r2 = M[r3 + 5];
   rMAC = r1 LSHIFT -8;
   rMAC = rMAC AND 0xFF;
   rMAC = rMAC * ($wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_VALUE * 2) (int);
   r1 = r1 LSHIFT 16;
   r2 = r2 AND 0xFFFF;
   r2 = r2 + r1;
   rMAC = rMAC + r2 * ($wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_VALUE) (UU);
   r2 = rMAC LSHIFT (23 + $wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_SHIFT);

   // calc:  - 'firmware timer time'
   r4 = M[r3 + 7];
   r3 = M[r3 + 6];
   r3 = r3 LSHIFT 16;
   r4 = r4 AND 0xFFFF;
   r4 = r4 + r3;
   r2 = r2 - r4;

   // store ADJUSTMENT_VALUE
   M[$wall_clock_adjustment] = r2;

   r0 = $M.SUBWOOFER.INPUT_TYPE.ESCO;
   Null =  r0 - M[$music_example.link_type];
   if Z jump request_sco_params;
   // We have an L2CAP audio connection
   // Start looking for data on L2CAP port
   Null = M[$l2cap_input_handler];
   if NZ jump done;
   r0 = 1;
   M[$l2cap_input_handler] = r0;
   r1 = &$input_check_data_timer_struc;
   r2 = $TMR_PERIOD_CHECK_DATA;
   r3 = &$input_check_data_handler;
   call $timer.schedule_event_in;
   jump done;

request_sco_params:
   // request sco parameters if we haven't fetched them already
   Null = M[$sco_param_tesco];
   if NZ jump done;
   r2 = $MESSAGE_GET_SCO_PARAMS;
   r3 = $cbuffer.READ_PORT_MASK + 0; // port
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send;    

done:
   // pop rLink from stack
   jump $pop_rLink_and_rts;
    
.ENDMODULE;

// r0 = $message.LONG_MESSAGE_MODE_ID (a special flag to imply long message mode)
// r1 = long message ID (the actual ID of the message to send)
// r2 = long message size (in words)
// r3 = long message address of payload
//
// word 0 - either type of port number
// word 1 - Tesco, in slots
// word 2 - Wesco, in slots
// word 3 - to-air packet length, in bytes
// word 4 - from-air packet length, in bytes
// word 5/6 - wall clock value for the start of the first
//            reserved slot (MSW in 5, LSW in 6)
// word 7 - to-air processing time required by firmware, in us
// word 8 - from-air processing time required by firmware, in us

.MODULE $M.sco_params_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $sco_params_message_handler:

   $push_rLink_macro;   

   // store Tesco
   r0 = M[r3 + 1];
   M[$sco_param_tesco] = r0;
   Null = r0 - 6;
   if Z jump dont_clear_first_success;
      // Tesco is 12 or 24
      M[$M.sco_timer_handler.first_success] = Null;
   dont_clear_first_success:
    
   // store Wesco
   r0 = M[r3 + 2];
   M[$sco_param_wesco] = r0;
    
   // store packet sizes
   r0 = M[r3 + 3];
   M[$sco_param_to_air_size] = r0;
   r0 = M[r3 + 4];
   M[$sco_param_from_air_size] = r0;
    
   // join MSW & LSW to get 32 bit SCO clock value
   r0 = M[r3 + 5];
   r1 = M[r3 + 6];
   r0 = r0 LSHIFT 16;
   r1 = r1 AND 0xFFFF;
   r1 = r1 + r0;
   r0 = M[r3 + 5];
   r0 = r0 LSHIFT - 8;
   M[$sco_param_clock_msw] = r0;
   M[$sco_param_clock_lsw] = r1;

   // store F/W deadlines (sign extend to 24 bits)
   r0 = M[r3 + 7];
   r0 = r0 LSHIFT 8;
   r0 = r0 ASHIFT -8;
   M[$sco_param_to_air_time] = r0;
   r0 = M[r3 + 8];
   r0 = r0 LSHIFT 8;
   r0 = r0 ASHIFT -8;
   M[$sco_param_from_air_time] = r0;
        
   // cancel any running timer
   r1 = &$sco_timer_id;
   call $timer.cancel_event;
    
   // schedule timer
   call $sco_schedule_from_air;
    
   // pop rLink from stack
   jump $pop_rLink_and_rts;
    
.ENDMODULE;


.MODULE $M.sco_schedule_from_air;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $sco_schedule_from_air:

   $push_rLink_macro;   

   // join MSW & LSW to get 32 bit wall-clock value
   r1 = M[$wall_clock_msw];
   r2 = M[$wall_clock_lsw];
   r1 = r1 LSHIFT 16;
   r2 = r2 AND 0xFFFF;
   r2 = r2 + r1;
   r1 = M[$wall_clock_msw];
   r1 = r1 LSHIFT - 8;

   // get sco clock
   r3 = M[$sco_param_clock_msw];
   r4 = M[$sco_param_clock_lsw];

sco_schedule_next_instant:

   // calculate difference between sco clock and wall-clock
   r6 = r4 - r2;           // lsw
   r5 = r3 - r1 - borrow;  // msw
   
   // convert into uS (1 clk is 312.5uS)
   r5 = r6 * 625 (int);
   r5 = r5 ASHIFT -1;
    
   // advance SCO clock (add Tesco)
   r0 = M[$sco_param_tesco];
   r0 = r0 * 2 (int);
   r4 = r4 + r0;           // lsw
   r3 = r3 + carry;        // msw
  
   // BT clock is 28 bits. 4 bits are in $sco_param_clock_msw, while 24 bits
   // are in $sco_param_clock_msw.  Here we wrap the msw back to zero.
   Null = r3 - 16;
   if NEG jump load_sco_param_clock;
   r3 = Null;    
 
load_sco_param_clock:    
   M[$sco_param_clock_msw] = r3;
   M[$sco_param_clock_lsw] = r4;

   // add to wall-clock time to get absolute time
   r0 = M[$wall_clock_time];
   r2 = r0 + r5;
    
   // add F/W deadline
   r2 = r2 + M[$sco_param_from_air_time];
           
   // schedule timer
   r1 = &$sco_timer_struc;
   r3 = &$sco_timer_handler;
   call $timer.schedule_event_at;
   M[$sco_timer_id] = r3;
    
   // pop rLink from stack
   jump $pop_rLink_and_rts;
    
.ENDMODULE;

.MODULE $M.sco_timer_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
    
   .VAR error_type;
   .VAR error_last_time = 1;
   .VAR consecutive_error_count = 0;
   .VAR packet_counter = 0;
   .VAR write_to_dac_port = 0;
   .VAR first_success = 1;
   .VAR plc_bypass = 0;
   
   $sco_timer_handler:
   
   $push_rLink_macro;   

   // schedule next timer
   call $sco_schedule_from_air;

   // get input write address
   r0 = $input_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;
   
   // determine if DAC operators will get called
   r0 = M[first_success];
   if NZ jump no_successful_sco_packets_receieved_yet;
   
   // if we didn't write to the DAC port last time, we need to this time.
   r1 = 1;
   M[write_to_dac_port] = r1;
   
no_successful_sco_packets_receieved_yet:   
   // check amount of data in port
   r0 = $SCO_IN_PORT_HEADER;
   call $cbuffer.calc_amount_data;
 
   r1 = $SCO_ERROR_NO_DATA;
   r10 = r0 - Null;
   if Z jump process_packet_error;
       
   // get read address
   r0 = $SCO_IN_PORT_HEADER;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   // read sync word 
   r10 = r10 - 1;
   r1 = $SCO_ERROR_NO_META_DATA_SYNC_WORD;
   r5 = M[I0,1];
   Null = r5 - 0x5c5c;
   if NZ jump process_packet_error;
 
   // read header size
   r5 = M[I0,1];
    
   // read payload size
   r1 = M[I0,1];
    
   // assume no error
   M[error_type] = Null;
    
   // read status
   r10 = r10 - 3;
   r1 = M[I0, 1];
   r1 = r1 AND 0xFF;
   if Z jump sco_no_error;
   jump process_packet_error;

sco_no_error:
   // skip over extra header word - could be more intelligent with this.
   // right now I'm just assuming some firmwares provide 4, and others provide
   // 5 words.
   Null = r5 - 5;
   if NZ jump done_with_sco_meta_data_header; // header is 4 words
   r0 = M[I0,1];
done_with_sco_meta_data_header:

   r0 = $SCO_IN_PORT_HEADER;
   r1 = I0;
   call $cbuffer.set_read_address;
    
   r0 = $SCO_IN_PORT_AUDIO;
   call $cbuffer.calc_amount_data;
   r10 = r0;
 
   // get read address
   r0 = $SCO_IN_PORT_AUDIO;
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;

   // read header sync word
   r1 = $SCO_ERROR_NO_SWAT_SYNC_WORD;
   r10 = r10 - 1;
   r0 = M[I0,1];
   Null = r0 - 0xfff5f5;
   if NZ jump process_packet_error;  // something's gone wrong, this should be a sync word

   // read packet counter
   r1 = $SCO_ERROR_PACKET_COUNTER;     
   r10 = r10 - 1;
   r0 = M[I0,1];

   // if packet counter == 1, read the audio; if packet counter == 2, read audio if we had an error last time
   // Note packet counter will always be 1 for TESCO = 12 and TESCO = 24
   Null = r0 - 1;
   if Z jump extract_audio;
   Null = r0 - 2;
   if NZ jump process_packet_error; // something's gone wrong, this should have been a 1 or 2 
   Null = M[error_last_time];
   if NZ jump extract_audio;
   // need to bin data because we extracted it from the last BT packet.
   M[packet_counter] = r0;
   jump bin_data;
   
extract_audio:
   M[packet_counter] = r0;
   
   M[error_last_time] = Null;
   M[consecutive_error_count] = Null;

   .VAR $max_ota_latency;

   // read wall clock from payload
   r10 = r10 - 2;
   r1 = M[I0,1];
   r1 = r1 LSHIFT 16;
   r2 = M[I0,1];
   r2 = r2 AND 0xFFFF;
   r1 = r1 + r2;                       // r1 = time source wrote to port
   r2 = M[$wall_clock_adjustment];
   r2 = r2 + M[$TIMER_TIME];           // r2 = local time wall clock time
   
   r1 = r2 - r1;

   Null = r1 - M[$max_ota_latency];
   if NEG jump dont_log_max_ota_latency;   
   M[$max_ota_latency] = r1;
dont_log_max_ota_latency:
   Null = r1 - 6000;
   if POS jump process_packet_error;   // packet is too old

   // capture first success
   Null = M[first_success];
   if Z jump not_first_success;
   // if packet counter is 1 we need to copy to the DAC port next time.
   // if packet counter is 2 we need to copy to the DAC port this time.
    r3 = 1;
    M[first_success] = Null;
    r2 = Null;
    Null = r0 - 1;
    if NZ r2 = r3;
    M[write_to_dac_port] = r2;

not_first_success:

// read audio samples into buffer for PLC, then read the zero padding and bin it
   r1 = $music_example.NUM_SAMPLES_PER_PLC;
   r2 = 18;    // Soundbar sends packets that are 15 ms of audio, which is 18 samples at FS = 1200 Hz
   r0 = M[$sco_param_tesco];
   Null = r0 - 24;
   if Z r1 = r2; 
   r0 = r10 - r1;
   r10 = r1;

read_data:
   do sco_loop;
      r1 = M[I0,1];
      r1 = r1 ASHIFT 8; // shift up for PLC
      M[I4,1] = r1;
   sco_loop:

   r10 = r0;

   do consume_data;
      r1 = M[I0,1];
   consume_data:

   L4 = Null;
   L0 = Null;

   // set new read address for SCO Input port
   r0 = $SCO_IN_PORT_AUDIO;
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
   
   r0 = M[$sco_param_tesco];
   Null = r0 - 24;
   if NZ jump upsample;

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


upsample:   
   // upsample audio
   call $block_interrupts;
   r8 = &$upsample_copy_struc;
   call $cbops.copy;
   call $unblock_interrupts;

   // do frame based processing
   call $music_example_process;

   r0 = M[$sco_param_tesco];
   Null = r0 - 24;
   if NZ jump warp;
   
   // do frame based processing
   call $music_example_process;   

warp:
   r8 = &$warp_out_copy_struc;
   call $cbops.copy;

   jump done;

bin_data:
   do bin_redundant_packet;
      r1 = M[I0,1];
   bin_redundant_packet:

   // Clear L4 since we won't be writing to the input cbuffer
   L4 = Null;
   
set_new_read_address:
   // set new read address for SCO Input port
   L0 = 0;
   r0 = $SCO_IN_PORT_AUDIO;
   r1 = I0;
   call $cbuffer.set_read_address;
   
done:
   Null = M[write_to_dac_port];
   if Z jump exit;

   // The DAC handler needs to get kicked off every 7.5 ms unless TESCO = 24, then it needs to every 15 ms.
   // Couple DAC interrupt to this interrupt so we can measure the mismatch between the SCO and DAC.
   // This handler runs every 3.75 ms.  We kick start the DAC handler every 7.5 ms.
   r0 = M[$sco_param_tesco];
   Null = r0 - 6;
   if NZ jump not_tesco_6;
   .var $toggle_dac_interrupt;
   r1 = 1;
   r0 = M[$toggle_dac_interrupt];
   if NZ r1 = Null;
   M[$toggle_dac_interrupt] = r1;
   Null = r1 - Null;
   if Z jump exit;
   
   not_tesco_6:
   // Calculate rate mismatch between Soundbar and Subwoofer and warp to compensate.
   r8 = $rate_detection_obj;
   call $subwoofer_rate_detect;

   r1 = 5;
   r0 = M[$sco_param_tesco];
   r2 = 10;
   Null = r0 - 24;
   if Z r1 = r2;
   M[$dac_copies] = r1;

   r2 = M[$M.esco_audio_out_copy_handler.audio_out_id]; 
   call $timer.cancel_event;
   r2 = 0;
   r1 = &$audio_out_timer_struc;
   r3 = &$esco_audio_out_copy_handler;
   call $timer.schedule_event_in;   

exit:
   // pop rLink from stack
   jump $pop_rLink_and_rts;


   // routine for dealing with SCO errors
process_packet_error:

   // store error type
   M[error_type] = r1;
#if 1
   .VAR $bad_packet_counter_counter = 0;
   .VAR $bad_link_error_counter = 0;
   .VAR $lost_packet_error_counter = 0;
   .VAR $crc_error_counter = 0;
   .VAR $no_data_counter = 0;
   .VAR $no_meta_data_sync_word_counter = 0;
   .VAR $no_swat_sync_word_counter = 0;
   .VAR $old_packet_counter = 0;

   // check if crc error
   Null = r1 - 1;
   if NZ jump not_crc_error;
   r0 = M[$crc_error_counter];
   r0 = r0 + 1;
   M[$crc_error_counter] = r0;
        
not_crc_error:

   // check if lost packet
   Null = r1 - 2;
   if NZ jump not_lost_packet_error;
   r0 = M[$lost_packet_error_counter];
   r0 = r0 + 1;
   M[$lost_packet_error_counter] = r0;

not_lost_packet_error:

   // check if link is about to drop
   Null = r1 - 3;
   if NZ jump not_about_to_drop;
   r0 = M[$bad_link_error_counter];
   r0 = r0 + 1;
   M[$bad_link_error_counter] = r0;

not_about_to_drop:
  
   // check if no data
   Null = r1 - $SCO_ERROR_NO_DATA;
   if NZ jump not_no_data;
   r0 = M[$no_data_counter];
   r0 = r0 + 1;
   M[$no_data_counter] = r0;
    
not_no_data:

   // check no meta data sync word
   Null = r1 - $SCO_ERROR_NO_META_DATA_SYNC_WORD;
   if NZ jump have_sync_word;
   r0 = M[$no_meta_data_sync_word_counter];
   r0 = r0 + 1;
   M[$no_meta_data_sync_word_counter] = r0;
   
have_sync_word:

   // check no swat sync word
   Null = r1 - $SCO_ERROR_NO_SWAT_SYNC_WORD;
   if NZ jump have_swat_sync_word;
   r0 = M[$no_swat_sync_word_counter];
   r0 = r0 + 1;
   M[$no_swat_sync_word_counter] = r0;

have_swat_sync_word:

   // check packet counter error
   Null = r1 - $SCO_ERROR_PACKET_COUNTER;
   if NZ jump no_bad_packet_counter_error;
   r0 = M[$bad_packet_counter_counter];
   r0 = r0 + 1;
   M[$bad_packet_counter_counter] = r0;

no_bad_packet_counter_error:

   // check if old data
   Null = r1 - 6000;
   if NEG jump not_old_packet;
   r0 = M[$old_packet_counter];
   r0 = r0 + 1;
   M[$old_packet_counter] = r0;

not_old_packet:


#endif
   
   r0 = M[consecutive_error_count];
   r0 = r0 + 1;
   M[consecutive_error_count] = r0;
   
   r0 = 1;
   M[error_last_time] = r0;
   
   // bin the data
   do bin_data_loop;
       r0 = M[I0,1];
   bin_data_loop:
   
   r0 = $SCO_IN_PORT_AUDIO;
   r2 = $SCO_IN_PORT_HEADER;
   
   // set new read address for SCO Input port
   Null = r1 - $SCO_ERROR_NO_SWAT_SYNC_WORD;
   if NEG r0 = r2;
   L0 = 0;
   r1 = I0;
   call $cbuffer.set_read_address;
   
   // Clear L4 register since we won't be writing to the input cbuffer.
   L4 = Null;
   r0 = M[$sco_param_tesco];
   Null = r0 - 6;
   if NZ jump failure;
   
   // Use PLC to generate packets if necessary.
   // Frame_a1 Frame_a2 Frame_b1 Frame_b2 Frame_c1 Frame_c2
   // If we successfully got Frame_a1, we can cope with two errors in a row; the third error requires PLC to generate audio.
   // If we successfully got Frame_a2, we can only cope with one error before calling the PLC to generate data.

   // if we've not received a successful packet yet, don't do anything
   Null = M[first_success];
   if NZ jump done;

   r1 = M[packet_counter];
   r0 = M[consecutive_error_count]; // 1 means 1 error, 2 means 2 in a row, 3 means 3 in a row
   
   Null = r1 - 1;
   if NZ jump last_counter_two;
   Null = r0 - 3;
   if NEG jump done;
   // 3 or more consecutive errors, need to generate audio with PLC.
   // Set 'consecutive_error_count', which will make PLC run again if we get two consecutive errors.
   r1 = 1;
   M[consecutive_error_count] = r1;
   jump failure;
   
last_counter_two:
   // if we get two consecutive errors we need the PLC to generate audio.
   Null = r0 - 2;
   if NEG jump done;
   M[consecutive_error_count] = Null;
   
failure:  
   r0 = M[$subwoofer.packet_fail_counter];
   r0 = r0 + 1;
   M[$subwoofer.packet_fail_counter] = r0;

   Null = M[plc_bypass];
   if NZ jump bypass_plc;
      // Use PLC to generate a packet
      r1 = M[error_type];
      jump do_plc;
 
bypass_plc:
      // write zeros to the input cbuffer.  Just used for testing.
      r0 = $input_cbuffer_struc;
      call $cbuffer.get_write_address_and_size;
      I4 = r0;
      L4 = r1;
      r1 = 0;
      r10 = $music_example.NUM_SAMPLES_PER_PLC;
      r2 = 18;
      r0 = M[$sco_param_tesco];
      Null = r0 - 24;
      if Z r10 = r2;
      
      do copy_zeros_loop;
         M[I4,1] = r1;
      copy_zeros_loop:      
      L4 = Null;
      jump do_plc;
      
.ENDMODULE;



.MODULE $M.wall_clock_timer_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   $wall_clock_timer_handler:
   
   $push_rLink_macro;   

   // request wall clock
   r2 = Null OR $MESSAGE_GET_WALL_CLOCK_TBTA;
   r3 = M[$bdaddr_struc + 0];
   r4 = M[$bdaddr_struc + 1];
   r5 = M[$bdaddr_struc + 2];
   r6 = M[$bdaddr_struc + 3];
   call $message.send;

   // schedule next wall clock update
   r1 = &$wall_clock_timer_struc;
   r2 = $WALL_CLOCK_UPDATE_PERIOD;
   r3 = &$wall_clock_timer_handler;
   call $timer.schedule_event_in_period;
    
   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $audio_out_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform copying of samples to the
//    output.
//
// *****************************************************************************
.MODULE $M.l2cap_audio_out_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   .VAR audio_out_id;
  
   $l2cap_audio_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;
   
   r0 = $audio_out_rate_adjustment_and_shift_op_mono2;
   M[$M.main.audio_out_volume.next] = r0;
    
   r8 = &$dac_out_copy_struc;
   call $cbops.dac_av_copy;   

   .var $dac_isr_running=0;
   r1 = 1;
   M[$dac_isr_running] = r1;

   r2 = 1500;
   r1 = &$audio_out_timer_struc;
   r3 = &$l2cap_audio_out_copy_handler;
   call $timer.schedule_event_in_period;
   M[audio_out_id] = r3;

done:
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $audio_out_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform copying of samples to the
//    output.
//
// *****************************************************************************
.MODULE $M.esco_audio_out_copy_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $first_audio_out_copy_handler = 1;
   .VAR audio_out_id;
  
   $esco_audio_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;
   
   Null = M[$first_audio_out_copy_handler];
   if Z jump done_setting_port_level;
   
   r0 = &$dac_out_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   Null = r0 - Null;
   if Z jump done_setting_port_level;
   
   // Prime DAC to a good working level.  We'll put 180 samples in there
   // to protect against over and underflowing.

   r0 = M[$dac_out_copy_struc + 4];
   call $cbuffer.calc_amount_space;
   r10 = r0 + 180;   
  
   call $audio_insert_silence;
   M[$first_audio_out_copy_handler] = Null;

done_setting_port_level:

   r8 = &$dac_out_copy_struc;
   call $cbops.dac_av_copy;   

   r1 = M[$dac_copies];
   r1 = r1 - 1;
   if Z jump done;
   M[$dac_copies] = r1;

   r2 = 1500;
   r1 = &$audio_out_timer_struc;
   r3 = &$esco_audio_out_copy_handler;
   call $timer.schedule_event_in_period;
   M[audio_out_id] = r3;

done:
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

.MODULE $M.audio_insert_silence;
    .CODESEGMENT PM;
    .DATASEGMENT DM;

$audio_insert_silence:

    $push_rLink_macro;   

    // get audio port write address
    r0 = M[$dac_out_copy_struc + 4];
    call $cbuffer.get_write_address_and_size; 
    I4 = r0;
    L4 = r1;
    
    r0 = 0;
    // generate silence
    do audio_fill_loop;
        M[I4,1] = r0;
    audio_fill_loop:

    // set new write address
    r0 = M[$dac_out_copy_struc + 4];
    r1 = I4;
    call $cbuffer.set_write_address; 
    L4 = 0;

    // pop rLink from stack
    jump $pop_rLink_and_rts;
    
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $input_check_data_handler
//
// DESCRIPTION:
//    Checks for L2CAP data.
//
// *****************************************************************************
.MODULE $M.input_check_data_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   // ** allocate memory for timer structures **
   .VAR $input_check_data_timer_struc[$timer.STRUC_SIZE];

   $input_check_data_handler:
   
   // push rLink onto stack
   $push_rLink_macro;
   
   M[$frame_sync.sync_flag] = Null;
   
   // Prevent audio from being played.
   r1 = 1;
   M[$buffering_flag] = r1;
   
   // check for data
   r0 = $L2CAP_IN_PORT;
   call $cbuffer.calc_amount_data;
   Null = r0 - $L2CAP_FRAME_SIZE;
   if NEG jump post_timer;
   // First frame of L2CAP data has arrrived.
   // Schedule first L2CAP handler
   call $l2cap_schedule_first_handler;
   jump done;

post_timer:
   // post another timer event
   r1 = &$input_check_data_timer_struc;
   r2 = $TMR_PERIOD_CHECK_DATA;
   r3 = &$input_check_data_handler;
   call $timer.schedule_event_in_period;
   M[$l2cap_input_check_handler_id] = r3;
done:
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// input: r0 = error_type
// TODO: Fix timers for L2CAP and replace magic numbers with .CONSTS.
.MODULE $calc_error_rate;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   .VAR frame_counter = 0;
   .VAR frame_errors = 0;
   .VAR window = 266; // 2 seconds
   .VAR thresh = 133; // 50% error rate to trigger volume fade
   .VAR attenuator_counter = 0;

$calc_error_rate:
   $push_rLink_macro;

   r1 = M[frame_errors];
   r0 = r0 + r1;
   M[frame_errors] = r0;
   
   // if error rate exceeds 50% over 2 seconds fade volume to zero
   r1 = M[frame_counter];
   r1 = r1 + 1;
   Null = r1 - M[window]; // 2 seconds
   if Z jump set_volume;
   M[frame_counter] = r1;
   jump done;
   
set_volume:
   M[frame_counter] = Null;
   M[frame_errors] = Null;
   Null = r0 - M[thresh];  // 50% error rate
   if NEG jump good_error_rate;
   // high error rate, attenuate volume
   M[$M.main.audio_out_volume.param + $cbops.volume.FINAL_VALUE_FIELD]= Null;
   //M[$audio_mute_op_mono.param + $cbops.mono_soft_mute_op.MUTE_DIRECTION] = Null;
   // bring audio back if it's good for .25 seconds second
   r0 = 33;
   M[window] = r0;
   r0 = 16;
   M[thresh] = r0;
   r0 = M[attenuator_counter];
   r0 = r0 + 1;
   M[attenuator_counter] = r0;
   jump done;

good_error_rate:
   r0 = 1.0;
   M[$M.main.audio_out_volume.param + $cbops.volume.FINAL_VALUE_FIELD]= r0;
   //r0 = 1;
   //M[$audio_mute_op_mono.param + $cbops.mono_soft_mute_op.MUTE_DIRECTION] = r0; // unmute
   r0 = 266;
   M[window] = r0;
   r0 = 133;
   M[thresh] = r0;
   
done:
    // pop rLink from stack
    jump $pop_rLink_and_rts;
    
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $adc_dac_handler
//
// DESCRIPTION:
//    Gets input from ADC.  Copies output to DAC.
//
// *****************************************************************************
.MODULE $M.adc_dac_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   // ** allocate memory for timer structures **
   .VAR $adc_dac_timer_struc[$timer.STRUC_SIZE];
   .VAR $adc_dac_id;

   $adc_dac_handler:
   
   // push rLink onto stack
   $push_rLink_macro;
   
   r0 = &$audio_out_dither_and_shift_op;
   M[$M.main.audio_out_volume.next] = r0;
   
   M[$frame_sync.sync_flag] = Null;
   
   r8 = &$adc_in_copy_struc;
   call $cbops.copy;

   r8 = &$dac_out_copy_struc;
   call $cbops.copy;

post_timer:
   // post another timer event
   r1 = &$adc_dac_timer_struc;
   r2 = $TMR_PERIOD_ADC_DAC;
   r3 = &$adc_dac_handler;
   call $timer.schedule_event_in_period;
   M[$adc_dac_id] = r3;

done:
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.subwoofer_rate_detect
//
// DESCRIPTION:
//    This function computes the clock mismatch between the Soundbar and 
//    Subwoofer.
//
//    A clock mismatch between the Soundbar and Subwoofer can be up to 40 PPM.
//    This routine detects the error and sets a warp value that will compensate
//    for the mismatch.  A warp is calculated every 4096 iterations because this
//    is long enough to detect a mismatch of 1 PPM.
//
//    1 PPM = 1/1000000 = 0.000001
//    This would produce .048 extra samples per second.
//    It would take 20.833 seconds for the error to manifest itself into one
//    sample.
//
//    40 PPM would generate 58.98 extra samples in 4096 iterations.  The buffers
//    are large enough to handle this surge, which would happen for the first
//    two iterations before subwoofer_rate_detect would fix the issue.
//    A quicker intial reaction could be acheieved by storing the clock mismatch
//    value in a PSKEY.
//
// INPUTS:
//    r8 - data object
//    
// *****************************************************************************
.MODULE $M.subwoofer_rate_detect;
   .CODESEGMENT   PM;
   .DATASEGMENT   DM;

$subwoofer_rate_detect:
   .VAR $amount_last_time;
   .VAR temp;
   .VAR $fp_accum;

   $push_rLink_macro;

   // Count samples in DAC cbuffer and DAC/I2S port
   r0 = &$dac_out_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   push r0;
   
   r0 = M[$dac_out_copy_struc + 4];
   call $cbuffer.calc_amount_space;
   r0 = r0 + 1;
   r1 = $DAC_PORT_SIZE - r0;

   pop r0;
   r3 = r0 + r1;    
   
   r0 = &$frame_process_out_cbuffer_struc;
   call $cbuffer.calc_amount_data;

   r0 = r0 + r3;
   
   r9 = M[r8 + $subwoofer_rate_detect.ACCUMULATOR];
   r9 = r9 + r0;
   M[r8 + $subwoofer_rate_detect.ACCUMULATOR] = r9;

   // Determine if it's time to compute the clock mismatch value.
   r0 = M[r8 + $subwoofer_rate_detect.COUNTER];
   r0 = r0 + 1;
   M[r8 + $subwoofer_rate_detect.COUNTER] = r0;

   r1 = M[r8 + $subwoofer_rate_detect.COUNTER_THRESHOLD];
   Null = r0 - r1;
   if NZ jump done_with_warp;

   // Calculate average number of samples obtained per instance by dividing the
   // number of samples by the COUNTER_THRESHOLD value.
   r4 = M[r8 + $subwoofer_rate_detect.COUNTER_THRESHOLD_RECIP];
   r4 = r9 * r4 (frac);

   // Compare this to the average number of samples collected last time.
   r3 = M[r8 + $subwoofer_rate_detect.AMOUNT_LAST_TIME]; //$amount_last_time]
   if Z r3 = r4;   // if first time, seed the value.

   r5 = r4 - r3;   // r5 = amount this time - amount last time.  If rates are matched this is zero.

   M[r8 + $subwoofer_rate_detect.AMOUNT_LAST_TIME] = r4;

   r0 = M[r8 + $subwoofer_rate_detect.EXPECTED_NUM_SAMPLES_RECIP_Q20];
   r0 = r0 * r5 (frac);  // (amount this time - amount last time)/expected number of samples = error rate

   r0 = r0 ASHIFT 3; // convert to q.23  

   r4 = Null - r0; // required warp value.

   // limit final warp value to be within 40 PPM.
   // Actually we'll limit it to 50 PPM to allow it to overshoot a little, if necessary.
   r3 = 0.00005;
   Null = Null + r4;
   if POS jump positive_limit;
   Null = r4 + r3;
   if NEG r4 = Null - r3;
   jump load_warp;

positive_limit:
   Null = r4 - r3;
   if POS r4 = r3;

load_warp: 
   r0 = M[$soundbar_subwoofer_rate_adjustment];
   r0 = r0 + r4;
   M[$soundbar_subwoofer_rate_adjustment] = r0;

freeze_warp:
   M[r8 + $subwoofer_rate_detect.COUNTER] = Null;
   M[r8 + $subwoofer_rate_detect.ACCUMULATOR] = Null;
  
done_with_warp:
   jump $pop_rLink_and_rts;

.ENDMODULE;
