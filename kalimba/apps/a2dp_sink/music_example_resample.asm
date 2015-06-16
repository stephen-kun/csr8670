// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change: 1322655 $  $DateTime: 2012/06/07 14:16:10 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    Resampler used to reconcile the codec output sampling rate to the
//    DAC sampling rate
//
// *****************************************************************************

#include "core_library.h"
#include "cbops_library.h"
#include "codec_decoder.h"
#include "operators\iir_resamplev2\iir_resamplev2_header.h"

// DAC resampler module
.MODULE $dac_resampler;
   .DATASEGMENT DM;

   // Maximum expected resampled audio samples delivered to the DAC per timer period
   .CONST MAX_DAC_OUTPUT_SAMPLES_PER_TIMER_PERIOD        (MAX_SAMPLE_RATE * TMR_PERIOD_AUDIO_COPY / 1000000);

   // Buffer scaling factor to allow for jitter
   .CONST BUFFER_SCALING_FACTOR                          2;
   
   // Additional space for temp buffer used in resampler
   .CONST BUFF_PAD   10;
   
#ifdef ANC_96K
   //Buffer size needed for temp buff in resampler with 96kHz Fs @ timer of 0.5ms
   //Max size is for 16k->96(6up1down)==6*0.5*96==288
   .CONST TEMP_BUFF_SIZE                          288+BUFF_PAD;   
#else   
   //Buffer size needed for temp buff in resampler with 48kHz Fs @ timer of 1.5ms
   //Max size is for 16k->48(3up1down)==3*1.5*96==216
   .CONST TEMP_BUFF_SIZE                          216+BUFF_PAD;
#endif   

   // Lookup table used to determine cbops/resampler structure values given codec rate and ADC rate
   // Codec rate, DAC rate, filter spec, mono resampler operator, stereo resampler operator, mono operator struc, stereo operator struc
   // Optimized table to have only the minimum required parameters (3 elements) compared to the original table structure (5 elements)
   .CONST record_size 3;
   .VAR filter_spec_lookup_table[] =
      48000, 48000, 0,
      44100, 44100, 0,
      32000, 32000, 0,
      22050, 22050, 0,
      16000, 16000, 0,
      8000, 8000, 0,

      16000, 48000, $M.iir_resamplev2.Up_3_Down_1.filter,
      32000, 48000, $M.iir_resamplev2.Up_3_Down_2.filter,
      44100, 48000, $M.iir_resamplev2.Up_160_Down_147.filter,
      16000, 44100, $M.iir_resamplev2.Up_441_Down_160.filter,
      32000, 44100, $M.iir_resamplev2.Up_441_Down_320.filter,
      48000, 44100, $M.iir_resamplev2.Up_147_Down_160.filter,
#ifdef ANC_96K
      16000, 96000, $M.iir_resamplev2.Up_6_Down_1.filter,
     32000, 96000, $M.iir_resamplev2.Up_3_Down_1.filter,
      44100, 96000, $M.iir_resamplev2.Up_320_Down_147.filter,
      48000, 96000, $M.iir_resamplev2.Up_2_Down_1.filter,
#endif
      
      0;

   // Resampler input data buffers
   .VAR/DMCIRC dac_out_temp_left[BUFFER_SCALING_FACTOR * MAX_DAC_OUTPUT_SAMPLES_PER_TIMER_PERIOD + 1];
   .VAR/DMCIRC dac_out_temp_right[BUFFER_SCALING_FACTOR * MAX_DAC_OUTPUT_SAMPLES_PER_TIMER_PERIOD + 1];

   .VAR $dac_out_temp_left_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH(dac_out_temp_left),                   // Size
      dac_out_temp_left,                           // Read pointer
      dac_out_temp_left;                           // Write pointer
   .VAR $dac_out_temp_right_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH(dac_out_temp_right),                  // Size
      dac_out_temp_right,                          // Read pointer
      dac_out_temp_right;                          // Write pointer

 
   .VAR/DM iir_temp[TEMP_BUFF_SIZE];

   // ------------------------------------------------------------------------------------
   // Stereo copy/resampler handling
   .VAR $dac_out_resampler_stereo_copy_struc[] =
      stereo_copy_switch_op,
      2,
      $dac_out_left_cbuffer_struc,                    // Left input cbuffer
      $dac_out_right_cbuffer_struc,                   // Right input cbuffer
      2,
      $dac_out_temp_left_cbuffer_struc,               // Left output port/cbuffer
      $dac_out_temp_right_cbuffer_struc;              // Right output port/cbuffer

   // Switch operator chains according to whether resampling is being performed
   .BLOCK stereo_copy_switch_op;
      .VAR stereo_copy_switch_op.next = stereo_left_copy_op;
      .VAR stereo_copy_switch_op.func = $cbops.switch_op;
      .VAR stereo_copy_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
         $dac_resampler.resampler_active,             // Pointer to switch (non-zero selects resampler)
         stereo_left_resampler_op,                         // ALT_NEXT_FIELD, pointer to alternate cbops chain
         0,                                           // SWITCH_MASK_FIELD
         $cbops.switch_op.INVERT_CONTROL;             // INVERT_CONTROL_FIELD
   .ENDBLOCK;

   .BLOCK stereo_left_copy_op;
      .VAR stereo_left_copy_op.next = stereo_right_copy_op;
      .VAR stereo_left_copy_op.func = $cbops.copy_op;
      .VAR stereo_left_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         0,                                           // Input buffer index
         2;                                           // Output buffer index
   .ENDBLOCK;

   .BLOCK stereo_right_copy_op;
      .VAR stereo_right_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR stereo_right_copy_op.func = $cbops.copy_op;
      .VAR stereo_right_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         1,                                           // Input buffer index
         3;                                           // Output buffer index
   .ENDBLOCK;

   .BLOCK stereo_left_resampler_op;
      .VAR stereo_left_resampler_op.next = stereo_right_resampler_op;
      .VAR stereo_left_resampler_op.func = $cbops_iir_resamplev2;
      .VAR stereo_left_resampler_op.param[$iir_resamplev2.OBJECT_SIZE] =
         0,                                           // Input 1 start index field
         2,                                           // Output 1 start index field
         0,                                           // Filter definition ptr field
         -8,                                          // Input scale field
         8,                                           // Output scale field,
         &iir_temp,                       // INTERMEDIATE_CBUF_PTR_FIELD,
         length(iir_temp),                // INTERMEDIATE_CBUF_LEN_FIELD,
         0 ...;            
   .ENDBLOCK;

  .BLOCK stereo_right_resampler_op;
      .VAR stereo_right_resampler_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR stereo_right_resampler_op.func = $cbops_iir_resamplev2;
      .VAR stereo_right_resampler_op.param[$iir_resamplev2.OBJECT_SIZE] =
         1,                                           // Input 2 start index field
         3,                                           // Output 2 start index field
        0,                                           // Filter definition ptr field
         -8,                                          // Input scale field
         8,                                           // Output scale field,
         &iir_temp,                       // INTERMEDIATE_CBUF_PTR_FIELD,
         length(iir_temp),                // INTERMEDIATE_CBUF_LEN_FIELD,
         0 ...;            
   .ENDBLOCK;


    // ------------------------------------------------------------------------------------
    // Mono copy/resampler handling
   .VAR $dac_out_resampler_mono_copy_struc[] =
      mono_copy_switch_op,
      1,                                              // Number of inputs
      $dac_out_left_cbuffer_struc,                    // Input cbuffer
      1,                                              // Number of outputs
      $dac_out_temp_left_cbuffer_struc;               // Output port/cbuffer

   // Switch operator chains according to whether resampling is being performed
   .BLOCK mono_copy_switch_op;
      .VAR mono_copy_switch_op.next = mono_copy_op;
      .VAR mono_copy_switch_op.func = $cbops.switch_op;
      .VAR mono_copy_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
         $dac_resampler.resampler_active,             // Pointer to switch (non-zero selects resampler)
         mono_resampler_op,                           // ALT_NEXT_FIELD, pointer to alternate cbops chain
         0,                                           // SWITCH_MASK_FIELD
         $cbops.switch_op.INVERT_CONTROL;             // INVERT_CONTROL_FIELD
   .ENDBLOCK;

   .BLOCK mono_copy_op;
      .VAR mono_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR mono_copy_op.func = $cbops.copy_op;
      .VAR mono_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         0,                                           // Input buffer index
         1;                                           // Output buffer index
   .ENDBLOCK;

   .BLOCK mono_resampler_op;
      .VAR mono_resampler_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR mono_resampler_op.func = $cbops_iir_resamplev2;
      .VAR mono_resampler_op.param[$iir_resamplev2.OBJECT_SIZE] =
         0,                                           // Input 1 start index field
         1,                                           // Output 1 start index field
         0,                                           // Filter definition ptr field
         -8,                                          // Input scale field
         8,                                           // Output scale field,
         &iir_temp,                                // Iir history buf ptr field,
         length(iir_temp),                                // Fir history buf ptr field
         0 ...;                                           // Reset flag field
   .ENDBLOCK;

   // Flag showing whether the resampling is active
   .VAR resampler_active = 0;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.config_resampler
//
// DESCRIPTION:
//    Configure the resampler to perform the required output sampling rate
//    change. This modifies the cbops/resampler operator structures
//    with values appropriate for the sampling rate change.
//
//    Uses $current_codec_sampling_rate and $current_dac_sampling_rate
//    to determine the configuration required.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    - r0, r1, r2, r3, r4, r5, r6, r10, DoLoop;
//
// *****************************************************************************
.MODULE $M.config_resampler;
   .CODESEGMENT CONFIG_RESAMPLER_PM;
   
  
   $config_resampler:

   // Push rLink onto stack
   $push_rLink_macro;

   // Point to first record in table
   r1 = $dac_resampler.filter_spec_lookup_table;

   // Lookup the required resampler changes for the given rates
   lookup_loop:

      // End of table?
      r0 = M[r1];
      if Z jump rates_not_supported;

      // Codec rate matches?
      null = r0 - M[$current_codec_sampling_rate];
      if NZ jump skip;

      // DAC rate matches?
      r0 = M[r1+1];
      null = r0 - M[$current_dac_sampling_rate];
      if Z jump done;

      skip:

      // Next record
      r1 = r1 + $dac_resampler.record_size;
   jump lookup_loop;

   rates_not_supported:

   // Get the requested rates
   r3 = M[$current_codec_sampling_rate];
   r4 = M[$current_dac_sampling_rate];

   // Scale down rates by 10 to fit into 16bit words
   r0 = 10;
   rMAC = r3;
   Div = rMAC/r0;
   r3 = DivResult;
   rMAC = r4;
   Div = rMAC/r0;
   r4 = DivResult;

   // Report the error to the VM
   r2 = UNSUPPORTED_SAMPLING_RATES_MSG;
   call $message.send_short;

#if 1
   // Abort
   call $error;
#endif

   // Default to a valid rate configuration (given by the first table record)
   r1 = $dac_resampler.filter_spec_lookup_table;

   // Override the DAC and codec rates with default values
   r0 = M[r1];
   M[$current_codec_sampling_rate] = r0;
   r0 = M[r1+1];
   M[$current_dac_sampling_rate] = r0;

   done:

   call $block_interrupts;

   r2 = $cbops.switch_op.ON;

   //Force Set the Reset field in the filter parameter to 0   
   M[$dac_resampler.mono_resampler_op.param + $iir_resamplev2.RESET_FLAG_FIELD] = 0;
   M[$dac_resampler.stereo_left_resampler_op.param + $iir_resamplev2.RESET_FLAG_FIELD] = 0;
   M[$dac_resampler.stereo_right_resampler_op.param + $iir_resamplev2.RESET_FLAG_FIELD] = 0;
   

  
   // Filter specifications in the resampler structure
   r0 = M[r1+2];
   M[$dac_resampler.mono_resampler_op.param + $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD] = r0;
   M[$dac_resampler.stereo_left_resampler_op.param + $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD] = r0;
   M[$dac_resampler.stereo_right_resampler_op.param + $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD] = r0;
   // Store a flag indicating whether resampling is being used
   if Z r2 = 0;
 
   M[$dac_resampler.resampler_active] = r2;

  //Filter Function is now statically assigned in the structure   


   call $unblock_interrupts;

   // Pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
