// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2003)        http://www.csr.com
// %%version
//
// $Revision$  $Date$
// *****************************************************************************
// *****************************************************************************
// Frontend for a2dp_low_latency_1mic
//
// Configuration : 
//      ADC @ 16kHz
//      DAC/I2S out @ 44.1 or 48kHz
//      Timer Task @ 750 uSec
//
// Interface points :
//      audio_in_left_cbuffer_struc
//      sidetone_cbuffer_struc
//      Reference.cbuffer_struc
//      left_cbuffer_struc
//      right_cbuffer_struc
//
// Ports : 
//      AUDIO_IN_PORT
//      AUDIO_LEFT_OUT_PORT
//      AUDIO_RIGHT_OUT_PORT
//      TONE_IN_PORT
// *****************************************************************************
// *****************************************************************************
#include "core_library.h"
#include "cbops_multirate_library.h"
#include "frame_sync_stream_macros.h"
#include "sr_adjustment_gaming.h"
#include "a2dp_low_latency_1mic_library_gen.h"

#define $TONE_BUFFER_SIZE             192
#define $TONE_EXTRA_BOOST_BITS        2
#define $PROMPT_EXTRA_BOOST_BITS      (-1)
#define PLAY_BACK_FINISHED_MSG        0x1080
#define TMR_PERIOD_AUDIO_COPY         750
#define TMR_PERIOD_CODEC_COPY         1000
#define $PCM_END_DETECTION_TIME_OUT   40
#define SIDETONE_PEQ_STAGES           3

.CONST  $ADCDAC_PERIOD_USEC           0.00075;
.CONST  $AUDIO_IN_PORT     ($cbuffer.READ_PORT_MASK + 0);
.CONST  $AUDIO_LEFT_OUT_PORT    ($cbuffer.WRITE_PORT_MASK + 0);
.CONST  $AUDIO_RIGHT_OUT_PORT   ($cbuffer.WRITE_PORT_MASK + 1);
.CONST  $TONE_IN_PORT           (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO)  + 3);
.CONST  $OUTPUT_AUDIO_CBUFFER_SIZE   (160 + 8*(TMR_PERIOD_AUDIO_COPY * 48000/1000000));

// Scratch table declaration 
.MODULE $cbops.scratch;
    .DATASEGMENT DM;
    
   .VAR BufferTable[9*$cbops_multirate.BufferTable.ENTRY_SIZE];
   
// Scratch sufficient for 96kHz sample rate @ 625 usec
    DeclareCBuffer(cbuffer_struc1,mem1,120);
    DeclareCBuffer(cbuffer_struc2,mem2,120);
    DeclareCBuffer(cbuffer_struc3,mem3,300);
    
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $set_dac_rate
//
// DESCRIPTION: message handler for receiving DAC rate from VM
//
// INPUTS:
//  r1 = dac sampling rate/10 (e.g. 44100Hz is given by r1=4410)
//  r2 = maximum clock mismatch to compensate (r2/10)%
//       (Bit7==1 disables the rate control, e.g 0x80)
//  r3 = bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
//  r4 = bits(1:0): audio output interface type:
//                  0 -> None (not expected)
//                  1 -> Analogue output (DAC)
//                  2 -> I2S output
//                  3 -> SPDIF output
//       bit8: playback mode (0: remote playback, 1: local file play back)
//             local play back isn't relevant in this app and shall not be used
//
// OUTPUTS:
//  - none
//
// NOTES:
// *****************************************************************************
.MODULE $M.set_dac_rate;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   
   .VAR local_play_back;
   .VAR audio_if_mode; // output interface type
   .VAR max_clock_mismatch;
   .VAR long_term_mismatch;

func:

   // Mask sign extension
   r1 = r1 AND 0xffff;
   // Scale to get sampling rate in Hz
   r1 = r1 * 10 (int);
   // Store the parameters                 
   M[$M.dac_out.current_dac_sampling_rate] = r1;   // DAC sampling rate (e.g. 44100Hz is given by r1=44100)
   M[max_clock_mismatch] = r2;          // Maximum clock mismatch to compensate (r2/10)% (Bit7==1 disables the rate control, e.g 0x80)
   M[long_term_mismatch] = r3;          // bit0: if long term mismatch rate saved bits(15:1): saved_rate>>5
   
   r0 = r4 AND $LOCAL_PLAYBACK_MASK;     // Mask for local file play back info
   M[local_play_back] = r0;             // NZ means local file play back (local file play back not used here)
   r0 = r4 AND $AUDIO_IF_MASK;           // Mask for audio i/f info
   M[audio_if_mode] = r0;               // Set the audio output interface type

#ifdef LATENCY_REPORTING
   // update inverse of dac sample rate
   push rLink;
   r0 = M[$M.dac_out.current_dac_sampling_rate];
   call $latency.calc_inv_fs;
   M[$inv_dac_fs] = r0;
   pop rLink;
#endif 

   // Signal Change in sample rate
   r0=1; 
   M[$M.dac_out.dac_sr_flag] = r0;
   rts;
   
.ENDMODULE;

// *****************************************************************************
#define ADCINDEX_PORT_LEFT      0 
#define ADCINDEX_CBUFFER_LEFT   1
#define ADCINDEX_SIDETONE       2
#define ADCINDEX_INTERNAL_ST    3
#define ADCINDEX_NONE          -1

.MODULE $M.adc_in;
   .DATASEGMENT DM;
   
       DeclareCBuffer(audio_in_left_cbuffer_struc,audio_in_left,AUDIO_CBUFFER_SIZE);
       DeclareCBuffer(sidetone_cbuffer_struc,sidetone_mem,(4*48));

    .VAR copy_struc[] =
         $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
         &left_shift_op,                 // MAIN_FIRST_OPERATOR_FIELD
         &sidetone_resample_op,          // MTU_FIRST_OPERATOR_FIELD 
         1,                              // NUM_INPUTS_FIELD
         $AUDIO_IN_PORT,
         2,                              // NUM_OUTPUTS_FIELD
         &audio_in_left_cbuffer_struc,
         sidetone_cbuffer_struc,
         1,                              // NUM_INTERNAL_FIELD
         &$cbops.scratch.cbuffer_struc1;
     
     .BLOCK left_shift_op; 
         .VAR left_shift_op.prev_op = $cbops.NO_MORE_OPERATORS; 
         .VAR left_shift_op.next_op = &sidetone_copy_op; 
         .VAR left_shift_op.func = &$cbops.shift;
         .VAR left_shift_op.param[$cbops.shift.STRUC_SIZE] =
                  ADCINDEX_PORT_LEFT,     // Input index (left input port)
                  ADCINDEX_CBUFFER_LEFT,  // Output index (left cbuffer)
                  8;                      // Shift amount
     .ENDBLOCK;
      
     .BLOCK sidetone_copy_op; 
       .VAR sidetone_copy_op.prev_op = &left_shift_op; 
       .VAR sidetone_copy_op.next_op = &sidetone_resample_op;                                 
       .VAR sidetone_copy_op.func = &$cbops.sidetone_filter_op;                                          
       .VAR sidetone_copy_op.param[CBOPS_SIDETONE_FILTER_OBJECT_SIZE(SIDETONE_PEQ_STAGES)] =                                 
          ADCINDEX_CBUFFER_LEFT,    /* Input index field (ADC cbuffer) */                                               
          ADCINDEX_INTERNAL_ST,     /* Output index field (SIDE TONE cbuffer) */                                        
            $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SIDETONEENA,  // SideTone Enable Mask
            &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_CLIP_POINT, // Pointer to Sidetone Parameters
            0,                                  // Apply Filter-Filter
            0.0,                                // APPLY_GAIN            
	       &$M.CVC.data.ZeroValue,
            0,                                  // Config
            &$M.dac_out.auxillary_mix_left_op.param+$cbops.aux_audio_mix_op.OFFSET_INV_DAC_GAIN,// OFFSET_PTR_INV_DAC_GAIN
            0,                                  // OFFSET_CURRENT_SIDETONE_GAIN
            0,                                  // OFFSET_PTR_PEAK_ST
            0,                                  // PTR_INPUT_DATA_BUFF_FIELD  - Not Used
            0,                                  // PTR_OUTPUT_DATA_BUFF_FIELD - Not Used
            SIDETONE_PEQ_STAGES,                // MAX_STAGES_FIELD
            &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_CONFIG,
            0 ...;	    	                                                          
     .ENDBLOCK; 
   
     .BLOCK sidetone_resample_op;
        .VAR sidetone_resample_op.prev_op = &sidetone_copy_op;
        .VAR sidetone_resample_op.next_op = $cbops.NO_MORE_OPERATORS;
        .VAR sidetone_resample_op.func = $cbops_iir_resamplev2;
        .VAR sidetone_resample_op.param[$iir_resamplev2.OBJECT_SIZE] =
            ADCINDEX_INTERNAL_ST,         // Input index
            ADCINDEX_SIDETONE,            // Output index
            0,                            // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
            -8,                           // INPUT_SCALE_FIELD   (input Q15)
            8,                            // OUTPUT_SCALE_FIELD  (output Q23)
            &$cbops.scratch.mem2,         // INTERMEDIATE_CBUF_PTR_FIELD
            LENGTH($cbops.scratch.mem2),  // INTERMEDIATE_CBUF_LEN_FIELD
            0 ...;
     .ENDBLOCK;
   
.ENDMODULE;

// *****************************************************************************
.MODULE $M.tone_in;
    .DATASEGMENT DM;

    DeclareCBuffer(left_cbuffer_struc, left_mem, $TONE_BUFFER_SIZE);
    DeclareCBuffer(right_cbuffer_struc, right_mem, $TONE_BUFFER_SIZE);
    .VAR aux_input_stream_available;       // local pcm file is being mixed
   .VAR/DM1CIRC tone_hist_left[$cbops.fir_resample.HIST_LENGTH];
   .VAR/DM1CIRC tone_hist_right[$cbops.fir_resample.HIST_LENGTH];
   .VAR current_tone_sampling_rate = 8000;
   
   .VAR copy_struc[] =     
      $cbops.scratch.BufferTable,      // BUFFER_TABLE_FIELD
      deinterleave_mix_op,             // MAIN_FIRST_OPERATOR_FIELD
      copy_op_right,                   // MTU_FIRST_OPERATOR_FIELD
      1,                               // NUM_INPUTS_FIELD
      $TONE_IN_PORT,
      2,                               // NUM_OUTPUTS_FIELD
      &left_cbuffer_struc,   
      &right_cbuffer_struc,         
      2,
      &$cbops.scratch.cbuffer_struc1,
      &$cbops.scratch.cbuffer_struc2;

   .BLOCK deinterleave_mix_op;
      .VAR deinterleave_mix_op.mtu_next  = $cbops.NO_MORE_OPERATORS;
      .VAR deinterleave_mix_op.main_next = shift_op_left;
      .VAR deinterleave_mix_op.func = $cbops.deinterleave_mix;
      .VAR deinterleave_mix_op.param[$cbops.deinterleave_mix.STRUC_SIZE] =
         0,                                  // Input index
         3,                                  // Output1 index
         4,                                  // Output2 index
         0 ;                                 // input interleaved flag
   .ENDBLOCK;

   .BLOCK shift_op_left;
      .VAR shift_op_left.prev_op = deinterleave_mix_op;
      .VAR shift_op_left.next_op = &copy_op_left;
      .VAR shift_op_left.func = $cbops.shift;
      .VAR shift_op_left.param[$cbops.shift.STRUC_SIZE] =
         3,                            // Input index
         3,                            // Output index
         8;                            // Shift amount
   .ENDBLOCK;

   .BLOCK copy_op_left;
      .VAR copy_op_left.prev_op = &shift_op_left;
      .VAR copy_op_left.next_op = copy_left_to_right;
      .VAR copy_op_left.func = $cbops.fir_resample;
      .VAR copy_op_left.param[$cbops.fir_resample.STRUC_SIZE] =
         3,                                   // Input index
         1,                                   // Output index
         $sra_coeffs,                         // COEF_BUF_INDEX_FIELD        
         current_tone_sampling_rate,          // INPUT_RATE_ADDR_FIELD      
         $M.dac_out.current_dac_sampling_rate,// OUTPUT_RATE_ADDR_FIELD       
         tone_hist_left,                      // HIST_BUF_FIELD 
         0 ...;
   .ENDBLOCK;

   .BLOCK copy_left_to_right;
      .VAR copy_left_to_right.prev_op = &copy_op_left;
      .VAR copy_left_to_right.next_op = &$cbops.NO_MORE_OPERATORS;
      .VAR copy_left_to_right.func = $cbops.copy_op;
      .VAR copy_left_to_right.param[$cbops.copy_op.STRUC_SIZE] =
         1,                            // Input index
         2;                            // Output index
   .ENDBLOCK;
  
   .BLOCK shift_op_right;
      .VAR shift_op_right.prev_op = &copy_op_left;
      .VAR shift_op_right.next_op = &copy_op_right;
      .VAR shift_op_right.func = $cbops.shift;
      .VAR shift_op_right.param[$cbops.shift.STRUC_SIZE] =
         4,                            // Input index
         4,                            // Output index
         8;                            // Shift amount
   .ENDBLOCK;

  .BLOCK copy_op_right;
      .VAR copy_op_right.prev_op = &shift_op_right;
      .VAR copy_op_right.next_op = $cbops.NO_MORE_OPERATORS;
      .VAR copy_op_right.func = $cbops.fir_resample;
      .VAR copy_op_right.param[$cbops.fir_resample.STRUC_SIZE] =
         4,                                   // Input index
         2,                                   // Output index
         $sra_coeffs,                         // COEF_BUF_INDEX_FIELD        
         current_tone_sampling_rate,          // INPUT_RATE_ADDR_FIELD      
         $M.dac_out.current_dac_sampling_rate,// OUTPUT_RATE_ADDR_FIELD       
         tone_hist_right,                     // HIST_BUF_FIELD 
         0 ...;
   .ENDBLOCK;
   
.ENDMODULE;

// *****************************************************************************
#define DAC_RESAMPLE_CBUFFER_LEFT_IN       0
#define DAC_RESAMPLE_CBUFFER_RIGHT_IN      1
#define DAC_RESAMPLE_CBUFFER_LEFT_OUT      2
#define DAC_RESAMPLE_CBUFFER_RIGHT_OUT     3
#define DAC_RESAMPLE_INTERNAL_LEFT_OUT     4
#define DAC_RESAMPLE_INTERNAL_RIGHT_OUT    5

.MODULE $M.dac_out_resample;
    .DATASEGMENT DM;
    
    DeclareCBuffer(left_cbuffer_struc,dac_out_left, $OUTPUT_AUDIO_CBUFFER_SIZE);
    DeclareCBuffer(right_cbuffer_struc,dac_out_right, $OUTPUT_AUDIO_CBUFFER_SIZE);
    
   .VAR/DM1CIRC sr_hist_left[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];
   .VAR/DM1CIRC sr_hist_right[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];

       .VAR copy_struc[] =                                                                              
        $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
        &sync_op,                       // MAIN_FIRST_OPERATOR_FIELD
        &sw_rate_right_op,              // MTU_FIRST_OPERATOR_FIELD
        2,                              // NUM_INPUTS_FIELD
        &left_cbuffer_struc,
        &right_cbuffer_struc,
        2,                              // NUM_OUTPUTS_FIELD
        &$M.dac_out.left_cbuffer_struc, 
        &$M.dac_out.right_cbuffer_struc,      
        2,                              // NUM_INTERNAL_FIELD
        &$cbops.scratch.cbuffer_struc1,
        &$cbops.scratch.cbuffer_struc2;
        
    .BLOCK sync_op;
      .VAR sync_op.prev_op = $cbops.NO_MORE_OPERATORS;
      .VAR sync_op.next_op = &left_op;      
      .VAR sync_op.func = $cbops.stereo_sync_op;
      .VAR sync_op.param[$cbops.stereo_sync_op.STRUC_SIZE] =
           DAC_RESAMPLE_CBUFFER_LEFT_IN,     // START1_INDEX_FIELD
           DAC_RESAMPLE_CBUFFER_RIGHT_IN;    // START2_INDEX_FIELD
    .ENDBLOCK;   
        
    .BLOCK left_op;
      .VAR left_op.prev_op = &sync_op;
      .VAR left_op.next_op = &sw_rate_left_op;
      .VAR left_op.func = $cbops_iir_resamplev2;
      .VAR left_op.param[$iir_resamplev2.OBJECT_SIZE] =
           DAC_RESAMPLE_CBUFFER_LEFT_IN,    // Input index
           DAC_RESAMPLE_INTERNAL_LEFT_OUT,  // Output index
           0,                               // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
           -8,                              // INPUT_SCALE_FIELD   (input Q15)
           8,                               // OUTPUT_SCALE_FIELD  (output Q23)
           &$cbops.scratch.mem3,            // INTERMEDIATE_CBUF_PTR_FIELD
           LENGTH($cbops.scratch.mem3),     // INTERMEDIATE_CBUF_LEN_FIELD
           0 ...;
    .ENDBLOCK;
    
    .BLOCK sw_rate_left_op;
      .VAR sw_rate_left_op.mtu_next  = &left_op; 
      .VAR sw_rate_left_op.main_next = &right_op; 
      .VAR sw_rate_left_op.func = &$cbops.rate_adjustment_and_shift;
      .VAR sw_rate_left_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
           DAC_RESAMPLE_INTERNAL_LEFT_OUT,  // INPUT1_START_INDEX_FIELD
           DAC_RESAMPLE_CBUFFER_LEFT_OUT,   // OUTPUT1_START_INDEX_FIELD
           0,                               // SHIFT_AMOUNT_FIELD
           0,                               // MASTER_OP_FIELD
           &$sra_coeffs,                    // FILTER_COEFFS_FIELD
           &sr_hist_left,                   // HIST1_BUF_FIELD
           &sr_hist_left,                   // HIST1_BUF_START_FIELD
           &$sra_struct + $sra.SRA_RATE_FIELD,// SRA_TARGET_RATE_ADDR_FIELD
           0,                               // ENABLE_COMPRESSOR_FIELD
           0 ...;     
    .ENDBLOCK;
    
    .BLOCK right_op;
      .VAR right_op.prev_op = &sw_rate_left_op;
      .VAR right_op.next_op = &sw_rate_right_op;
      .VAR right_op.func = $cbops_iir_resamplev2;
      .VAR right_op.param[$iir_resamplev2.OBJECT_SIZE] =
           DAC_RESAMPLE_CBUFFER_RIGHT_IN,   // Input index
           DAC_RESAMPLE_INTERNAL_RIGHT_OUT, // Output index
           0,                               // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
           -8,                              // INPUT_SCALE_FIELD   (input Q15)
           8,                               // OUTPUT_SCALE_FIELD  (output Q23)
           &$cbops.scratch.mem3,            // INTERMEDIATE_CBUF_PTR_FIELD
           LENGTH($cbops.scratch.mem3),     // INTERMEDIATE_CBUF_LEN_FIELD
           0 ...;
    .ENDBLOCK;
    
    .BLOCK sw_rate_right_op;
      .VAR sw_rate_right_op.mtu_next  = &right_op; 
      .VAR sw_rate_right_op.main_next = $cbops.NO_MORE_OPERATORS; 
      .VAR sw_rate_right_op.func = &$cbops.rate_adjustment_and_shift;
      .VAR sw_rate_right_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
           DAC_RESAMPLE_INTERNAL_RIGHT_OUT,  // INPUT1_START_INDEX_FIELD
           DAC_RESAMPLE_CBUFFER_RIGHT_OUT,   // OUTPUT1_START_INDEX_FIELD
           0,                                // SHIFT_AMOUNT_FIELD
           0,                                // MASTER_OP_FIELD
           &$sra_coeffs,                     // FILTER_COEFFS_FIELD
           &sr_hist_right,                   // HIST1_BUF_FIELD
           &sr_hist_right,                   // HIST1_BUF_START_FIELD
           &$sra_struct + $sra.SRA_RATE_FIELD,// SRA_TARGET_RATE_ADDR_FIELD
           0,                                // ENABLE_COMPRESSOR_FIELD
           0 ...;     
    .ENDBLOCK;
    
.ENDMODULE;

// *****************************************************************************
#define DACINDEX_CBUFFER_LEFT_IN     0
#define DACINDEX_CBUFFER_RIGHT_IN    1
#define DACINDEX_SIDETONE            2
#define DACINDEX_PORT_LEFT           3
#define DACINDEX_PORT_RIGHT          4
#define DACINDEX_REFERENCE           5

.MODULE $M.dac_out;
   .DATASEGMENT DM;
     
   .VAR audio_out_timer_struc[$timer.STRUC_SIZE];
   .VAR current_dac_sampling_rate = 48000;
   .VAR dac_sr_flag = 0;
   
    DeclareCBuffer(left_cbuffer_struc,dac_out_left, $OUTPUT_AUDIO_CBUFFER_SIZE);
    DeclareCBuffer(right_cbuffer_struc,dac_out_right, $OUTPUT_AUDIO_CBUFFER_SIZE);
    DeclareCBuffer(Reference.cbuffer_struc,Reference.mem, AUDIO_CBUFFER_SIZE);
   
   .VAR/DM1CIRC $dither_hist_left[$cbops.dither_and_shift.FILTER_COEFF_SIZE];
   .VAR/DM1CIRC $dither_hist_right[$cbops.dither_and_shift.FILTER_COEFF_SIZE];
   
   .VAR copy_struc[] =                                                                              
        $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
        &insert_op_left,                // MAIN_FIRST_OPERATOR_FIELD
        &insert_op_left,                // MTU_FIRST_OPERATOR_FIELD
        3,                              // NUM_INPUTS_FIELD
        &left_cbuffer_struc,
        &right_cbuffer_struc,
        &$M.adc_in.sidetone_cbuffer_struc,
        3,                              // NUM_OUTPUTS_FIELD
        $AUDIO_LEFT_OUT_PORT, 
        $AUDIO_RIGHT_OUT_PORT,     
        &Reference.cbuffer_struc,
        0;                              // NUM_INTERNAL_FIELD
        
    .BLOCK insert_op_left;
        .VAR insert_op_left.prev_op = &insert_op_right;
        .VAR insert_op_left.next_op = &insert_op_right;
        .VAR insert_op_left.func = &$cbops.insert_op;
        .VAR insert_op_left.param[$cbops.insert_op.STRUC_SIZE] =
            DACINDEX_CBUFFER_LEFT_IN, // BUFFER_INDEX_FIELD
            0,                        // MAX_ADVANCE_FIELD    [-- CONFIG--]   
            0 ...;
    .ENDBLOCK;
   
   .BLOCK insert_op_right;
        .VAR insert_op_right.prev_op = &dac_wrap_op;
        .VAR insert_op_right.next_op = auxillary_mix_right_op;
        .VAR insert_op_right.func = &$cbops.insert_op;
        .VAR insert_op_right.param[$cbops.insert_op.STRUC_SIZE] =
            DACINDEX_CBUFFER_RIGHT_IN, // BUFFER_INDEX_FIELD
            0,                         // MAX_ADVANCE_FIELD    [-- CONFIG--]   
            0 ...;
    .ENDBLOCK;

    .BLOCK auxillary_mix_right_op;      
        .VAR auxillary_mix_right_op.prev_op = $cbops.NO_MORE_OPERATORS;
        .VAR auxillary_mix_right_op.next_op = &auxillary_mix_left_op;                                                     
        .VAR auxillary_mix_right_op.func = &$cbops.aux_audio_mix_op;                                 
        .VAR auxillary_mix_right_op.param[$cbops.aux_audio_mix_op.STRUC_SIZE] =                         
           DACINDEX_CBUFFER_RIGHT_IN,       // Input index (Output cbuffer)                        
           DACINDEX_CBUFFER_RIGHT_IN,       // Output index (Output cbuffer)                       
           $TONE_IN_PORT,                   // Auxillary Audio Port                                    
           $M.tone_in.right_cbuffer_struc,  // Auxillary Audio CBuffer                                                    
           0,                               // Hold Timer    
           -128,                            // Hold count. (96/0.750ms) = 128 
           0x80000,                         // Auxillary Gain  (During Tone Mix)  (Q5.18)  
           0x80000,                         // Main Gain       (During Tone Mix)  (Q5.18) 
           0x008000,                        // OFFSET_INV_DAC_GAIN  (Q8.15) 
           1.0,                             // Volume Independent Clip Point (Q23)
           1.0,                             // Absolute Clip Point  (Q23)
           0x40000,                         // Global Gain i.e. Boost (Q4.19)
           0,                               // Auxillary Audio Peak Statistic 
           1.0,                             // Inverse gain difference between Main & Tone Volume (Q23) 
           0;                               // Internal Data                                                                 
   .ENDBLOCK;  
   
    .BLOCK auxillary_mix_left_op;      
        .VAR auxillary_mix_left_op.prev_op = auxillary_mix_right_op;
        .VAR auxillary_mix_left_op.next_op = &reference_op;                                                     
        .VAR auxillary_mix_left_op.func = &$cbops.aux_audio_mix_op;                                 
        .VAR auxillary_mix_left_op.param[$cbops.aux_audio_mix_op.STRUC_SIZE] =                         
           DACINDEX_CBUFFER_LEFT_IN,        // Input index (Output cbuffer)                        
           DACINDEX_CBUFFER_LEFT_IN,        // Output index (Output cbuffer)                       
           $TONE_IN_PORT,                   // Auxillary Audio Port                                    
           $M.tone_in.left_cbuffer_struc,   // Auxillary Audio CBuffer                                                    
           0,                               // Hold Timer    
           -128,                            // Hold count.  (96/0.750ms) = 128 
           0x80000,                         // Auxillary Gain  (During Tone Mix)  (Q5.18)  
           0x80000,                         // Main Gain       (During Tone Mix)  (Q5.18) 
           0x008000,                        // OFFSET_INV_DAC_GAIN  (Q8.15) 
           1.0,                             // Volume Independent Clip Point (Q23)
           1.0,                             // Absolute Clip Point  (Q23)
           0x40000,                         // Global Gain i.e. Boost (Q4.19)
           0,                               // Auxillary Audio Peak Statistic 
           1.0,                             // Inverse gain difference between Main & Tone Volume (Q23) 
           0;                               // Internal Data                                                                
   .ENDBLOCK;  
   
    .BLOCK reference_op;
        .VAR reference_op.prev_op = &auxillary_mix_left_op;
        .VAR reference_op.next_op = &sidetone_mix_op;
        .VAR reference_op.func = $cbops_iir_resamplev2;
        .VAR reference_op.param[$iir_resamplev2.OBJECT_SIZE] =
            DACINDEX_CBUFFER_LEFT_IN,        // Input index
            DACINDEX_REFERENCE,              // Output index
            0,                               // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
            -8,                              // INPUT_SCALE_FIELD   (input Q15)
            8,                               // OUTPUT_SCALE_FIELD  (output Q23)
            &$cbops.scratch.mem3,            // INTERMEDIATE_CBUF_PTR_FIELD
            LENGTH($cbops.scratch.mem3),     // INTERMEDIATE_CBUF_LEN_FIELD
            0 ...;
    .ENDBLOCK;

   .BLOCK sidetone_mix_op;
        .VAR sidetone_mix_op.prev_op = &reference_op;
        .VAR sidetone_mix_op.next_op = &dither_left_op;
        .VAR sidetone_mix_op.func = &$cbops.sidetone_mix_op;
        .VAR sidetone_mix_op.param[$cbops.sidetone_mix_op.STRUC_SIZE] =
            DACINDEX_CBUFFER_LEFT_IN,     // INPUT_START_INDEX_FIELD
            DACINDEX_CBUFFER_LEFT_IN,     // OUTPUT_START_INDEX_FIELD
            DACINDEX_SIDETONE,            // SIDETONE_START_INDEX_FIELD
            0,                            // SIDETONE_MAX_SAMPLES_FIELD    [--- CONFIG ---]  
            0;                            // ATTENUATION_PTR_FIELD
   .ENDBLOCK;

   .BLOCK dither_left_op;
      .VAR dither_left_op.prev_op = &sidetone_mix_op;
      .VAR dither_left_op.next_op = &dither_right_op;
      .VAR dither_left_op.func = &$cbops.dither_and_shift;
      .VAR dither_left_op.param[$cbops.dither_and_shift.STRUC_SIZE] =
            DACINDEX_CBUFFER_LEFT_IN,                 // Input index
            DACINDEX_PORT_LEFT,                       // Output index
            -8,                                       // amount of shift after dithering
            $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
            $dither_hist_left,                        // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
            0;                                        // Enable compressor
   .ENDBLOCK;

   .BLOCK dither_right_op;
      .VAR dither_right_op.prev_op = &dither_left_op;
      .VAR dither_right_op.next_op = &dac_wrap_op;
      .VAR dither_right_op.func = &$cbops.dither_and_shift;
      .VAR dither_right_op.param[$cbops.dither_and_shift.STRUC_SIZE] =
            DACINDEX_CBUFFER_RIGHT_IN,                // Input index
            DACINDEX_PORT_RIGHT,                      // Output index
            -8,                                       // amount of shift after dithering
            $cbops.dither_and_shift.DITHER_TYPE_NONE, // type of dither
            $dither_hist_right,                       // history buffer for dithering (size = $cbops.dither_and_shift.FILTER_COEFF_SIZE)
            0;                                        // Enable compressor
   .ENDBLOCK;
   
    .BLOCK dac_wrap_op;
        .VAR dac_wrap_op.prev_op = &dither_right_op;
        .VAR dac_wrap_op.next_op = $cbops.NO_MORE_OPERATORS;
        .VAR dac_wrap_op.func = &$cbops.port_wrap_op;
        .VAR dac_wrap_op.param[$cbops.port_wrap_op.STRUC_SIZE] =
            DACINDEX_PORT_LEFT, // LEFT_PORT_FIELD
            DACINDEX_PORT_RIGHT,// RIGHT_PORT_FIELD
            3,                  // BUFFER_ADJUST_FIELD
            0,                  // MAX_ADVANCE_FIELD [-- CONFIG --]
            1,                  // SYNC_INDEX_FIELD
            0;                  // internal : WRAP_COUNT_FIELD
    .ENDBLOCK;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $audio_out_copy_handler
//
// DESCRIPTION:
//    Function called on a timer interrupt to perform the mono or stereo copying
//    of decoded samples to the output and from the input.
//
// *****************************************************************************
.MODULE $M.audio_out_copy_handler;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

$audio_out_copy_handler:

   // push rLink onto stack
   $push_rLink_macro;
   
   // reset the sync flag
   M[$frame_sync.sync_flag] = Null;

   // Check for change in front end
   Null = M[$M.dac_out.dac_sr_flag];
   if NZ call $ConfigureFrontEnd;
   
   // Check for change in front end
   Null = M[$M.A2DP_IN.codec_sr_flag];
   if NZ call $ConfigureFrontEnd;
   
   r0 = M[&$M.tone_in.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD]; 
   M[&$M.detect_end_of_aux_stream.last_write_address] = r0;
    
   // copy audio data from the port to the cbuffer
   r8 = &$M.adc_in.copy_struc;
   call $cbops_multirate.copy;

   // copy tone data from the port
   r8 = &$M.tone_in.copy_struc;
   call $cbops_multirate.copy;
      
   // detect end of tone/prompt stream
   call $detect_end_of_aux_stream;

   // Call the resample copy routine
   r8 = &$M.dac_out_resample.copy_struc;
   call $cbops_multirate.copy;

#ifdef LATENCY_REPORTING
   r8 = &$M.dac_out_resample.sw_rate_left_op.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD;
   M[$latency_calc_current_warp] = r8;
#endif  

   // Call the dac copy routine
   r8 = &$M.dac_out.copy_struc;
   call $cbops_multirate.copy;
   
   // post another timer event
   r1 = &$M.dac_out.audio_out_timer_struc;
   r2 = TMR_PERIOD_AUDIO_COPY;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in_period;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $ConfigureFrontEnd
//
// DESCRIPTION:
//    Set up the system Front End
//
// INPUTS:
//    none
// OUTPUTS:
//    none
// *****************************************************************************
.MODULE $M.FrontEndConfigure;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

$FrontEndStart:
   // push rLink onto stack
$push_rLink_macro;
    
   // start timer that copies audio samples
    r1 = &$M.dac_out.audio_out_timer_struc;
    r2 = TMR_PERIOD_AUDIO_COPY;
    r3 = &$audio_out_copy_handler;
    call $timer.schedule_event_in;
    
   // pop rLink from stack
jump $pop_rLink_and_rts;

$ConfigureFrontEnd:

   // push rLink onto stack
   $push_rLink_macro;
   
    M[$M.dac_out.dac_sr_flag] = NULL;
    M[$M.A2DP_IN.codec_sr_flag] = Null;

    r1 = 48000;
    Null = r1 - M[$M.dac_out.current_dac_sampling_rate];
    if NZ jump check_dac_chain_44k;
    
    r3 = 44100;
    Null = r3 - M[$M.set_codec_rate.current_codec_sampling_rate];
    if NZ jump set_dac_chain_48k;
    
    // DAC resample left : 44.1 kHz --> 48 kHz
    r0 = &$M.iir_resamplev2.Up_160_Down_147_low_mips.filter;
    r8 = &$M.dac_out_resample.left_op.param; 
    call $iir_resamplev2.SetFilter;
    
    // DAC resample right : 44.1 kHz --> 48 kHz
    r0 = &$M.iir_resamplev2.Up_160_Down_147_low_mips.filter;
    r8 = &$M.dac_out_resample.right_op.param; 
    call $iir_resamplev2.SetFilter;
    
set_dac_chain_48k:

    // Side Tone : 16 kHz --> 48 kHz
    r0 = &$M.iir_resamplev2.Up_3_Down_1.filter;
    r8 = &$M.adc_in.sidetone_resample_op.param; 
    call $iir_resamplev2.SetFilter;
    
    // AEC Reference : 48 kHz --> 16 kHz
    r0 = &$M.iir_resamplev2.Up_1_Down_3.filter;
    r8 = &$M.dac_out.reference_op.param; 
    call $iir_resamplev2.SetFilter;
    
    jump set_max_advance_fields;
    
check_dac_chain_44k:

    r4 = 48000;
    Null = r4 - M[$M.set_codec_rate.current_codec_sampling_rate];
    if NZ jump set_dac_chain_44k;
    
    // DAC resample left : 48 kHz --> 44.1 kHz
    r0 = &$M.iir_resamplev2.Up_147_Down_160_low_mips.filter;
    r8 = &$M.dac_out_resample.left_op.param; 
    call $iir_resamplev2.SetFilter;
    
    // DAC resample right : 48 kHz --> 44.1 kHz
    r0 = &$M.iir_resamplev2.Up_147_Down_160_low_mips.filter;
    r8 = &$M.dac_out_resample.right_op.param; 
    call $iir_resamplev2.SetFilter;
    
set_dac_chain_44k:

    // Side Tone : 16 kHz --> 44.1 kHz
    r0 = &$M.iir_resamplev2.Up_441_Down_160.filter;
    r8 = &$M.adc_in.sidetone_resample_op.param; 
    call $iir_resamplev2.SetFilter;
    
    // AEC Reference : 44.1 kHz --> 16 kHz
    r0 = &$M.iir_resamplev2.Up_160_Down_441.filter;
    r8 = &$M.dac_out.reference_op.param; 
    call $iir_resamplev2.SetFilter;
    
set_max_advance_fields:
    // Set Samples per period Parameters
    r1 = M[$M.dac_out.current_dac_sampling_rate];
    r2 = r1 * $ADCDAC_PERIOD_USEC (frac);
    r2 = r2 + 1;
 
    M[$M.dac_out.sidetone_mix_op.param + $cbops.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD]=r2; 
    M[$M.dac_out.dac_wrap_op.param + $cbops.port_wrap_op.MAX_ADVANCE_FIELD]  = r2;
    M[$M.dac_out.insert_op_left.param + $cbops.insert_op.MAX_ADVANCE_FIELD]  = r2;
    M[$M.dac_out.insert_op_right.param + $cbops.insert_op.MAX_ADVANCE_FIELD] = r2;
  
   // pop rLink from stack
   jump $pop_rLink_and_rts;
    
.ENDMODULE;

// *****************************************************************************
//
// Master reset routine, called to clear garbage samples during a pause
//
// *****************************************************************************
.MODULE $M.master_app_reset;
   .CODESEGMENT MASTER_APP_RESET_PM;
   .DATASEGMENT DM;
   $master_app_reset:
   
// push rLink onto stack
$push_rLink_macro;

   // local play back?
   Null = M[&$M.set_dac_rate.local_play_back];
   if Z jump pause_happened;
   
   // notify VM about end of play_back
   r2 = PLAY_BACK_FINISHED_MSG;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send_short;
   pause_happened:
   
   call $block_interrupts;
   
   // Purge dac out left buffer
   r0 = M[&$M.dac_out.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out.left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   // Purge dac out right buffer
   r0 = M[&$M.dac_out.right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out.right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0; 
   
   // Purge dac out resample left buffer
   r0 = M[&$M.dac_out_resample.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out_resample.left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;
   // Purge dac out resample right buffer
   r0 = M[&$M.dac_out_resample.right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out_resample.right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0; 
 
#ifdef LATENCY_REPORTING
   r7 = &$encoded_latency_struct;
   call $latency.reset_encoded_latency;
   M[$first_packet_received] = 0;
#endif 
    
   call $unblock_interrupts;
   
// pop rLink from stack
jump $pop_rLink_and_rts;

.ENDMODULE;
// *****************************************************************************
// MODULE:
//    $detect_end_of_aux_stream
//
// DESCRIPTION:
//    detects end of pcm tone/prompts and notifies vm
// *****************************************************************************

.MODULE $M.detect_end_of_aux_stream;
   .CODESEGMENT DETECT_END_OF_AUX_STREAM_PM;
   .DATASEGMENT DM;
   
   .VAR last_write_address = &$M.tone_in.left_mem;   
   .VAR write_move_counter = 0;

   $detect_end_of_aux_stream:

   $push_rLink_macro;

   // detect end of tone/prompt auxiliary pcm input stream
   r3 = M[$M.tone_in.aux_input_stream_available];
   if Z jump $pop_rLink_and_rts;

   // see if the input is active
   r0 = $M.tone_in.left_cbuffer_struc;
   call $cbuffer.calc_amount_data;

   // check if input activity has been seen before
   Null = r3 AND 0x2;
   if NZ jump input_has_received;

   // input hasn't started yet, so no end check
   Null = r0;
   if Z jump $pop_rLink_and_rts;

   // input just received
   r3 = r3 OR 0x2;
   M[$M.tone_in.aux_input_stream_available] = r3;
   jump $pop_rLink_and_rts;

   input_has_received:

   // Get the write address for the output buffer
   r0 = &$M.tone_in.left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   r4 = M[last_write_address];
   r3 = M[write_move_counter];
   r5 = 0;
   
   Null = r0 - r4;
   if Z r5 = r3 + 1;
   M[write_move_counter] = r5;
   
   Null = r5 - $PCM_END_DETECTION_TIME_OUT;
   if NEG jump $pop_rLink_and_rts;
   
   // inactive more than a threshold
   // notify VM about end of play back of aux input
   r2 = PLAY_BACK_FINISHED_MSG;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;      
   call $message.send_short;
   M[$M.tone_in.aux_input_stream_available] = 0;
   M[write_move_counter] = 0;
   
   // Purge tone buffers
   r0 = M[&$M.tone_in.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.tone_in.left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0; 
   
   r0 = M[&$M.tone_in.right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.tone_in.right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0; 
   
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.set_tone_rate
//
// DESCRIPTION: message handler for receiving tone rate from VM
//
// INPUTS:
//  r1 = (tone rate)
//  r2 = bit 0: mono / stereo
//       bit 1: tone / prompt
//  r3 = Not used
//  r4 = Not used
// OUTPUTS:
//    none
// *****************************************************************************
.MODULE $M.set_tone_rate;
   .CODESEGMENT SET_TONE_RATE_PM;
   .DATASEGMENT DM;
   
   func:
   // push rLink onto stack
   $push_rLink_macro;
   
   // extract  mono/stereo flag
   r3 = $M.tone_in.copy_left_to_right;
   r4 = $M.tone_in.shift_op_right;
   r0 = r2 AND 1;
   M[$M.tone_in.deinterleave_mix_op.param + $cbops.deinterleave_mix.INPUT_INTERLEAVED_FIELD] = r0;
   
   // also config the copy operator, this is for efficiency
   // so the resampler is not run twice for mono propmpts
   if NZ r3 = r4;
   M[$M.tone_in.copy_op_left.next_op] = r3;
   
   // firmware tones are boosted by 3 bits, voice promts expected to be normalised
   r0 = 8 + $PROMPT_EXTRA_BOOST_BITS;
   r3 = 8 + $TONE_EXTRA_BOOST_BITS;
   Null = r2 AND 0x2;
   if Z r0 = r3;
   M[$M.tone_in.shift_op_left.param + $cbops.shift.SHIFT_AMOUNT_FIELD] = r0;
   M[$M.tone_in.shift_op_right.param + $cbops.shift.SHIFT_AMOUNT_FIELD] = r0;
   
   // extract tone rate
   r1 = r1 AND 0xFFFF;
   M[$M.tone_in.current_tone_sampling_rate] = r1;
   
   // clear tone buffers
   r0 = $M.tone_in.left_cbuffer_struc;
   call $cbuffer.empty_buffer;
   r0 = $M.tone_in.right_cbuffer_struc;
   call $cbuffer.empty_buffer;
   
   // clear tone history buffers
   r10 = length($M.tone_in.tone_hist_left);
   r0 = 0;
   I2 = $M.tone_in.tone_hist_left;
   I6 = $M.tone_in.tone_hist_right;
   do clear_loop;
      M[I2, 1] = r0, M[I6,1] = r0;
   clear_loop:

   // auxiliary input expected now
   r0 = 1;
   M[$M.tone_in.aux_input_stream_available] = r0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;
   
.ENDMODULE;
