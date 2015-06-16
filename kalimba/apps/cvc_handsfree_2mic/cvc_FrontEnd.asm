// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1555509 $  $DateTime: 2013/03/14 18:29:20 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    This file defines the front end prcoessing for the CVC 2-MIC Handsfree
//
// *****************************************************************************
#include "core_library.h"
#include "cbops_multirate_library.h"
#include "frame_sync_stream_macros.h"
#include "frame_sync_library.h"     
#include "cvc_modules.h"            // Reference to NDVC Noise Estimate
#include "cvc_handsfree_2mic.h"

.CONST  $ADC_PORT_L           (($cbuffer.READ_PORT_MASK  + 0) | $cbuffer.FORCE_PCM_AUDIO);
.CONST  $ADC_PORT_R           (($cbuffer.READ_PORT_MASK  + 2) | $cbuffer.FORCE_PCM_AUDIO);
.CONST  $DAC_PORT_L           (($cbuffer.WRITE_PORT_MASK + 0) | $cbuffer.FORCE_PCM_AUDIO);
.CONST  $DAC_PORT_R           (($cbuffer.WRITE_PORT_MASK + 2) | $cbuffer.FORCE_PCM_AUDIO);   
.CONST  $TONE_PORT            (($cbuffer.READ_PORT_MASK  + 3) | $cbuffer.FORCE_PCM_AUDIO);

#define $TONE_EXTRA_BOOST_BITS   2
#define $PROMPT_EXTRA_BOOST_BITS (-1)   
   
// --------------------------------------------------------------------------
// INPUT/OUTPUT streams
// --------------------------------------------------------------------------
.MODULE $cbops.scratch;
   .DATASEGMENT DM;
   
    // if NUM_INPUTS_FIELD + NUM_OUTPUTS_FIELD + NUM_INTERNAL_FIELD > 9,increase
    // size of this table
   
    .VAR BufferTable[9*$cbops_multirate.BufferTable.ENTRY_SIZE];
   
    // scratch sufficient for 96kHz sample rate @ 625 usec
    // scratch 1 for resampler temp stage
    DeclareCBuffer(cbuffer_struc1,mem1,120);
    // scratch 2,3,4,5 for changing consumed/produced
    DeclareCBuffer(cbuffer_struc2,mem2,120);
    DeclareCBuffer(cbuffer_struc3,mem3,120);
    DeclareCBuffer(cbuffer_struc4,mem4,120);
    DeclareCBuffer(cbuffer_struc5,mem5,120);

.ENDMODULE;

#define ADCINDEX_PORT_LEFT      0
#define ADCINDEX_PORT_RIGHT     1
#define ADCINDEX_CBUFFER_LEFT   2
#define ADCINDEX_CBUFFER_RIGHT  3
#define ADCINDEX_INTERNAL_LEFT  4
#define ADCINDEX_INTERNAL_RIGHT 5
#define ADCINDEX_INTERNAL_LEFT_TEMP   6
#define ADCINDEX_INTERNAL_RIGHT_TEMP  7
#define ADCINDEX_NONE          -1

.MODULE $adc_in;
   .DATASEGMENT DM;

//                   (internal)                (cBuffer)
//   PORT ---- RESAMPLE ----- RATEMATCH -------->   Right
//
//                   (internal)                (cBuffer)
//   PORT ---- RESAMPLE --+-- RATEMATCH -------->   Left
//                                         |
//                     RATE_MONITOR    
//
//                                  
    DeclareCBuffer(left.cbuffer_struc,left.mem,$BLOCK_SIZE_ADC_DAC * 2);
    DeclareCBuffer(right.cbuffer_struc,right_mem,$BLOCK_SIZE_ADC_DAC * 2);

    
    .VAR/DM1CIRC    sr_hist_left[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];
    .VAR/DM1CIRC    sr_hist_right[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];
    
   .VAR copy_struc[] =
      $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
      &sync_op,                       // MAIN_FIRST_OPERATOR_FIELD
      &ratematch_switch_op,           // MTU_FIRST_OPERATOR_FIELD
      2,                              // NUM_INPUTS_FIELD
      $ADC_PORT_L,                    // portL->scratch2 (resampleL)
      $ADC_PORT_R,                    // portR->scratch3 (resampleR)
      2,                              // NUM_OUTPUTS_FIELD
      &left.cbuffer_struc,            // scratch4->cbufferL(rate matchL)
      &right.cbuffer_struc,           // scratch5->cbufferR(rate matchR)
      4,                              // NUM_INTERNAL_FIELD
      $cbops.scratch.cbuffer_struc2,  // for Left operation (from portL)
      $cbops.scratch.cbuffer_struc3,  // for Right operation (from portR)
      $cbops.scratch.cbuffer_struc4,  // for Left operation(scratch2->scratch4)
      $cbops.scratch.cbuffer_struc5;  // for Right operation(scratch3->scratch5)
      
     // Last operator in amount to use negotiation
     //      Ensures same number of samples are processes from left & right ports
     .BLOCK sync_op;
        .VAR sync_op.mtu_next  = $cbops.NO_MORE_OPERATORS;
        .VAR sync_op.main_next = copy_op_left;      
        .VAR sync_op.func = $cbops.stereo_sync_op;
        .VAR sync_op.param[$cbops.stereo_sync_op.STRUC_SIZE] =
            ADCINDEX_PORT_LEFT,     // START1_INDEX_FIELD
            ADCINDEX_PORT_RIGHT;    // START2_INDEX_FIELD
    .ENDBLOCK; 

    // Port Copy/Resampler Operator
    .BLOCK copy_op_left;
        .VAR copy_op_left.mtu_next  = &sync_op;
        .VAR copy_op_left.main_next = &copy_op_right;
        .VAR copy_op_left.func = $cbops_iir_resamplev2;
        .VAR copy_op_left.param[$iir_resamplev2.OBJECT_SIZE] =
            ADCINDEX_PORT_LEFT,                 // Input index
            ADCINDEX_INTERNAL_LEFT,                  // Output index
            0,                                  // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
            0,                                  // INPUT_SCALE_FIELD   (input Q15)
            8,                                  // OUTPUT_SCALE_FIELD  (output Q23)
            &$cbops.scratch.mem1,               // INTERMEDIATE_CBUF_PTR_FIELD
            LENGTH($cbops.scratch.mem1),        // INTERMEDIATE_CBUF_LEN_FIELD
            0 ...;
    .ENDBLOCK;
    
    .BLOCK copy_op_right;
        .VAR copy_op_right.mtu_next  = &copy_op_left;
        .VAR copy_op_right.main_next = &second_copy_op_left;
        .VAR copy_op_right.func = $cbops_iir_resamplev2;
        .VAR copy_op_right.param[$iir_resamplev2.OBJECT_SIZE] =
            ADCINDEX_PORT_RIGHT,                // Input index
            ADCINDEX_INTERNAL_RIGHT,            // Output index
            0,                                  // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
            0,                                  // INPUT_SCALE_FIELD   (input Q15)
            8,                                  // OUTPUT_SCALE_FIELD  (output Q23)
            &$cbops.scratch.mem1,               // INTERMEDIATE_CBUF_PTR_FIELD
            LENGTH($cbops.scratch.mem1),        // INTERMEDIATE_CBUF_LEN_FIELD
            0 ...;
    .ENDBLOCK;
    
    // Port Copy/Resampler Operator
    .BLOCK second_copy_op_left;
        .VAR second_copy_op_left.mtu_next  = &copy_op_right;
        .VAR second_copy_op_left.main_next = &second_copy_op_right;
        .VAR second_copy_op_left.func = $cbops_iir_resamplev2;
        .VAR second_copy_op_left.param[$iir_resamplev2.OBJECT_SIZE] =
            ADCINDEX_INTERNAL_LEFT,             // Input index
            ADCINDEX_INTERNAL_LEFT_TEMP,        // Output index
            0,                                  // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
            -8,                                 // INPUT_SCALE_FIELD   (input Q15)
            8,                                  // OUTPUT_SCALE_FIELD  (output Q23)
            &$cbops.scratch.mem1,               // INTERMEDIATE_CBUF_PTR_FIELD
            LENGTH($cbops.scratch.mem1),        // INTERMEDIATE_CBUF_LEN_FIELD
#ifdef KAL_ARCH2
            0,                                  // PARTIAL1_FIELD
            0,                                  // SAMPLE_COUNT1_FIELD
            &fir_buf1,                          // FIR_HISTORY_BUF_PTR_FIELD
            &iir_buf1,                          // IIR_HISTORY_BUF_PTR_FIELD,
            0,                                  // PARTIAL1_FIELD
            0,                                  // SAMPLE_COUNT1_FIELD
            &fir_buf2,                          // FIR_HISTORY_BUF_PTR_FIELD
            &iir_buf2,                          // IIR_HISTORY_BUF_PTR_FIELD,
#endif 
            0 ...;
    .ENDBLOCK;
   
    .BLOCK second_copy_op_right;
        .VAR second_copy_op_right.mtu_next  = &second_copy_op_left;
        .VAR second_copy_op_right.main_next = &ratematch_switch_op;
        .VAR second_copy_op_right.func = $cbops_iir_resamplev2;
        .VAR second_copy_op_right.param[$iir_resamplev2.OBJECT_SIZE] =
            ADCINDEX_INTERNAL_RIGHT,            // Input index
            ADCINDEX_INTERNAL_RIGHT_TEMP,       // Output index
            0,                                  // FILTER_DEFINITION_PTR_FIELD  [---CONFIG---]
            -8,                                 // INPUT_SCALE_FIELD   (input Q15)
            8,                                  // OUTPUT_SCALE_FIELD  (output Q23)
            &$cbops.scratch.mem1,               // INTERMEDIATE_CBUF_PTR_FIELD
            LENGTH($cbops.scratch.mem1),        // INTERMEDIATE_CBUF_LEN_FIELD
#ifdef KAL_ARCH2
            0,                                  // PARTIAL1_FIELD
            0,                                  // SAMPLE_COUNT1_FIELD
            &fir_buf3,                          // FIR_HISTORY_BUF_PTR_FIELD
            &iir_buf3,                          // IIR_HISTORY_BUF_PTR_FIELD,
            0,                                  // PARTIAL1_FIELD
            0,                                  // SAMPLE_COUNT1_FIELD
            &fir_buf4,                          // FIR_HISTORY_BUF_PTR_FIELD
            &iir_buf4,                          // IIR_HISTORY_BUF_PTR_FIELD,
#endif 
            0 ...;
    .ENDBLOCK;

    // Conditionally insert HW or software rate match
    .BLOCK ratematch_switch_op;
        .VAR ratematch_switch_op.mtu_next  = 0; // Set by switch
        .VAR ratematch_switch_op.main_next = 0; // Set by switch
        .VAR ratematch_switch_op.func = &$cbops.switch_op;
        .VAR ratematch_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
            &$sw_ratematching_adc,      // PTR_STATE_FIELD
            &sw_copy_left_op,           // MTU_NEXT_TRUE_FIELD 
            &hw_rate_op,                // MTU_NEXT_FALSE_FIELD
            &sw_rate_op,                // MAIN_NEXT_TRUE_FIELD
            &hw_copy_left_op;           // MAIN_NEXT_FALSE_FIELD
    .ENDBLOCK;

    // Software rate matching uses internal buffers  
    .BLOCK sw_rate_op;
        .VAR sw_rate_op.mtu_next  = &second_copy_op_right;
        .VAR sw_rate_op.main_next = &sw_copy_left_op; 
        .VAR sw_rate_op.func = &$cbops.rate_monitor_op;
        .VAR sw_rate_op.param[$cbops.rate_monitor_op.STRUC_SIZE] =
            ADCINDEX_INTERNAL_LEFT_TEMP, // MONITOR_INDEX_FIELD
            1600,                       // PERIODS_PER_SECOND_FEILD
            10,                         // SECONDS_TRACKED_FIELD
            0,                          // TARGET_RATE_FIELD    [---CONFIG---]
            10,                         // ALPHA_LIMIT_FIELD (controls the size of the averaging window)
            0.5,                        // AVERAGE_IO_RATIO_FIELD - initialize to 1.0 in q.22
            0,                          // WARP_MSG_LIMIT_FIELD 
            0 ...;     
    .ENDBLOCK;
    
    .BLOCK sw_copy_left_op;
        .VAR sw_copy_left_op.mtu_next  = &sw_copy_right_op; 
        .VAR sw_copy_left_op.main_next = &sw_copy_right_op;  
        .VAR sw_copy_left_op.func = &$cbops.rate_adjustment_and_shift;
        .VAR sw_copy_left_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
            ADCINDEX_INTERNAL_LEFT_TEMP,// INPUT1_START_INDEX_FIELD
            ADCINDEX_CBUFFER_LEFT,      // OUTPUT1_START_INDEX_FIELD
            0,                          // SHIFT_AMOUNT_FIELD
            0,                          // MASTER_OP_FIELD
            &$sra_coeffs,               // FILTER_COEFFS_FIELD
            &sr_hist_left,              // HIST1_BUF_FIELD
            &sr_hist_left,              // HIST1_BUF_START_FIELD
            &sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD, // SRA_TARGET_RATE_ADDR_FIELD
            0,                          // ENABLE_COMPRESSOR_FIELD
            0 ...;     
    .ENDBLOCK;
    
    .BLOCK sw_copy_right_op;
        .VAR sw_copy_right_op.mtu_next  = &second_copy_op_right; 
        .VAR sw_copy_right_op.main_next = $cbops.NO_MORE_OPERATORS;  
        .VAR sw_copy_right_op.func = &$cbops.rate_adjustment_and_shift;
        .VAR sw_copy_right_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
            ADCINDEX_INTERNAL_RIGHT_TEMP,// INPUT1_START_INDEX_FIELD
            ADCINDEX_CBUFFER_RIGHT,     // OUTPUT1_START_INDEX_FIELD
            0,                          // SHIFT_AMOUNT_FIELD
            &sw_copy_left_op.param,     // MASTER_OP_FIELD
            &$sra_coeffs,               // FILTER_COEFFS_FIELD
            &sr_hist_right,             // HIST1_BUF_FIELD
            &sr_hist_right,             // HIST1_BUF_START_FIELD
            &sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD, // SRA_TARGET_RATE_ADDR_FIELD
            0,                          // ENABLE_COMPRESSOR_FIELD
            0 ...;     
    .ENDBLOCK;
    
    // Hardware Rate matching uses copy_op to simplify routing
    //  Otherwise output of copy_op and input to sidetone would need to change 
    .BLOCK hw_copy_left_op;
        .VAR hw_copy_left_op.mtu_next  = &hw_copy_right_op; 
        .VAR hw_copy_left_op.main_next = &hw_copy_right_op; 
        .VAR hw_copy_left_op.func = &$cbops.copy_op;
        .VAR hw_copy_left_op.param[$cbops.copy_op.STRUC_SIZE] =
            ADCINDEX_INTERNAL_LEFT_TEMP, // INPUT_START_INDEX_FIELD
            ADCINDEX_CBUFFER_LEFT;       // OUTPUT_START_INDEX_FIELD 
    .ENDBLOCK; 

    .BLOCK hw_copy_right_op;
        .VAR hw_copy_right_op.mtu_next  = &second_copy_op_right; 
        .VAR hw_copy_right_op.main_next = &hw_rate_op; 
        .VAR hw_copy_right_op.func = &$cbops.copy_op;
        .VAR hw_copy_right_op.param[$cbops.copy_op.STRUC_SIZE] =
            ADCINDEX_INTERNAL_RIGHT_TEMP,// INPUT_START_INDEX_FIELD
            ADCINDEX_CBUFFER_RIGHT;      // OUTPUT_START_INDEX_FIELD 
    .ENDBLOCK; 
    
    // Hardware Rate matching monitors cBuffer
    .BLOCK hw_rate_op;
        .VAR hw_rate_op.mtu_next  = &hw_copy_left_op;
        .VAR hw_rate_op.main_next = $cbops.NO_MORE_OPERATORS;
        .VAR hw_rate_op.func = &$cbops.hw_warp_op;
        .VAR hw_rate_op.param[$cbops.hw_warp_op.STRUC_SIZE] =
            $ADC_PORT_L,       // PORT_OFFSET - Tracks Connectivity
            ADCINDEX_INTERNAL_LEFT_TEMP,// MONITOR_INDEX_OFFSET - Monitors throughput
            0x33,              // WHICH_PORTS_OFFSET
            0,                 // TARGET_RATE_OFFSET    [---CONFIG---]
            1600,              // PERIODS_PER_SECOND_OFFSET 
            3,                 // COLLECT_SECONDS_OFFSET
            1,                 // ENABLE_DITHER_OFFSET  [---CONFIG---]
            0 ...;
    .ENDBLOCK;  
    
.ENDMODULE;

/************************** Data Structure***************************************/

#define DACINDEX_CBUFFER        0
#define DACINDEX_PORT_LEFT      1
#define DACINDEX_PORT_RIGHT     2
#define DACINDEX_REFERENCE      3
#define DACINDEX_INTERNAL       4
#define DACINDEX_NONE          -1

.MODULE $dac_out;
   .DATASEGMENT DM;
   
//
//          (ST cBuffer)                                   (Ref cBuffer)
//          ----------> SIDETONE MIX  ---+   +-- REFERENCE --->
//                                       |   |           
//                 (internal)            |   |                      (DAC cBuffer)
// PORT <--- RESAMPLE ----- RATEMATCH ---+---+----+------ INSERTION -----<   
//                                                |
//                                              TONE MIX
//                                                |
//                                             (Aux cBuffer)
//

    .VAR RightPortEnabled = 0;        
    .VAR spkr_out_pk_dtct = 0;
    .VAR/DM1CIRC    sr_hist[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];
    
    DeclareCBuffer (cbuffer_struc,mem,$BLOCK_SIZE_ADC_DAC * 2);
    DeclareCBuffer (reference_cbuffer_struc,reference_mem,$BLOCK_SIZE_ADC_DAC * 2);

    .VAR copy_struc[] =
        $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
        &insert_op,                     // MAIN_FIRST_OPERATOR_FIELD
        &insert_op,                     // MTU_FIRST_OPERATOR_FIELD
        1,                              // NUM_INPUTS_FIELD
        &cbuffer_struc,                   
        3,                              // NUM_OUTPUTS_FIELD
        $DAC_PORT_L,                    
        $DAC_PORT_R,
        reference_cbuffer_struc,        
        1,                              // NUM_INTERNAL_FIELD
        $cbops.scratch.cbuffer_struc2;   

    // cBuffer Insertion Operator (Keep DAC chain Fed)
    .BLOCK insert_op;
    .VAR insert_op.mtu_next  = &dac_wrap_op;
    .VAR insert_op.main_next = &auxillary_mix_op;
    .VAR insert_op.func = &$cbops.insert_op;
    .VAR insert_op.param[$cbops.insert_op.STRUC_SIZE] =
        DACINDEX_CBUFFER,   // BUFFER_INDEX_FIELD
        0,                  // MAX_ADVANCE_FIELD       
        0 ...;
    .ENDBLOCK;

    // Mix in Auxillary Audio
    .BLOCK auxillary_mix_op;
        .VAR auxillary_mix_op.mtu_next = $cbops.NO_MORE_OPERATORS;
        .VAR auxillary_mix_op.main_next = &reference_copy_op;
        .VAR auxillary_mix_op.func = &$cbops.aux_audio_mix_op;
        .VAR auxillary_mix_op.param[$cbops.aux_audio_mix_op.STRUC_SIZE] =
            DACINDEX_CBUFFER,                /* Input index (Output cbuffer) */
            DACINDEX_CBUFFER,                /* Output index (Output cbuffer) */
            $TONE_PORT,                      /* Auxillary Audio Port */
            $tone_in.cbuffer_struc,          /* Auxillary Audio CBuffer */
            0,                               /* Hold Timer */
            -154,                            /* Hold count.  0.625 msec (ISR rate) * 154 = ~ 96 msec */
            0x80000,   /*(0db) */            /* Auxillary Gain   */
            0x80000,   /*(0db) */            /* Main Gain            (Q5.18) */
            0x008000,  /*(0db) */            /* OFFSET_INV_DAC_GAIN  (Q8.15) */
            1.0,                             /* Volume Independent Clip Point (Q23)*/
            0,                               /* Absolute Clip Point  (Q23)*/
            0x40000,                         /* Boost (Q4.19)*/
            0,                               /* Auxillary Audio Peak Statistic */
            1.0,                             /* Inverse gain difference between Main & Tone Volume (Q23) */
            0;                               /* Internal Data */
    .ENDBLOCK;

    // Tap for AEC reference  (Use $cbops.shift to share code)
    .BLOCK reference_copy_op;
        .VAR reference_copy_op.mtu_next = &auxillary_mix_op;      
        .VAR reference_copy_op.main_next = &pk_out_dac;
        .VAR reference_copy_op.func = &$cbops.shift;
        .VAR reference_copy_op.param[$cbops.shift.STRUC_SIZE] =
             DACINDEX_CBUFFER,     // Input index
             DACINDEX_REFERENCE,   // Output index
             0;                    // SHIFT_AMOUNT_FIELD
    .ENDBLOCK;

    .BLOCK pk_out_dac;
      .VAR pk_out_dac.mtu_next = &reference_copy_op; 
      .VAR pk_out_dac.main_next= &ratematch_switch_op;
      .VAR pk_out_dac.func    = &$cbops.peak_monitor_op;
      .VAR pk_out_dac.param[$cbops.peak_monitor_op.STRUC_SIZE] =
           DACINDEX_CBUFFER,     // PTR_INPUT_BUFFER_FIELD
           &spkr_out_pk_dtct;    // PEAK_LEVEL_PTR - UFE stat
    .ENDBLOCK;

    // Conditionally insert HW or software rate match
    .BLOCK ratematch_switch_op;
        .VAR ratematch_switch_op.mtu_next  = 0; // Set by switch
        .VAR ratematch_switch_op.main_next = 0; // Set by switch
        .VAR ratematch_switch_op.func = &$cbops.switch_op;
        .VAR ratematch_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
            &$sw_ratematching_dac,      // PTR_STATE_FIELD
            &sw_copy_op,                // MTU_NEXT_TRUE_FIELD 
            &hw_copy_op,                // MTU_NEXT_FALSE_FIELD
            &sw_copy_op,                // MAIN_NEXT_TRUE_FIELD
            &hw_copy_op;                // MAIN_NEXT_FALSE_FIELD
    .ENDBLOCK;
    
    // Software rate matching uses internal buffers   
    .BLOCK sw_copy_op;
        .VAR sw_copy_op.mtu_next  = &pk_out_dac; 
        .VAR sw_copy_op.main_next = &copy_op_left; 
        .VAR sw_copy_op.func = &$cbops.rate_adjustment_and_shift;
        .VAR sw_copy_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
            DACINDEX_CBUFFER,           // INPUT1_START_INDEX_FIELD
            DACINDEX_INTERNAL,          // OUTPUT1_START_INDEX_FIELD
            0,                          // SHIFT_AMOUNT_FIELD
            0,                          // MASTER_OP_FIELD
            &$sra_coeffs,               // FILTER_COEFFS_FIELD
            &sr_hist,                   // HIST1_BUF_FIELD
            &sr_hist,                   // HIST1_BUF_START_FIELD
            &$adc_in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD, // SRA_TARGET_RATE_ADDR_FIELD
            0,                          // ENABLE_COMPRESSOR_FIELD
            0 ...;     
    .ENDBLOCK;
    
    // If not Software ratematch, copy coperation simplifies routing
    //   Otherwise input for copy_op would need to change based on mode
    .BLOCK hw_copy_op;
        .VAR hw_copy_op.mtu_next  = &pk_out_dac; 
        .VAR hw_copy_op.main_next = &copy_op_left; 
        .VAR hw_copy_op.func = &$cbops.copy_op;
        .VAR hw_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
            DACINDEX_CBUFFER,             // INPUT_START_INDEX_FIELD
            DACINDEX_INTERNAL;            // OUTPUT_START_INDEX_FIELD 
    .ENDBLOCK;

    .BLOCK copy_op_left;
        .VAR copy_op_left.mtu_next  = &ratematch_switch_op;
        .VAR copy_op_left.main_next = &dac_right_switch_op;
        .VAR copy_op_left.func = $cbops_iir_resamplev2;
        .VAR copy_op_left.param[$iir_resamplev2.OBJECT_SIZE] =
             DACINDEX_INTERNAL,                         // Input index  (input  Q23)
             DACINDEX_PORT_LEFT,                        // Output index (output Q15)
             0,                                         // FILTER_DEFINITION_PTR_FIELD      [---CONFIG---]
             -8,                                        // INPUT_SCALE_FIELD
             0,                                         // OUTPUT_SCALE_FIELD,
             &$cbops.scratch.mem1,                      // INTERMEDIATE_CBUF_PTR_FIELD
             LENGTH($cbops.scratch.mem1),               // INTERMEDIATE_CBUF_LEN_FIELD
             0 ...;
   .ENDBLOCK;
   
    // Conditionally insert HW or software rate match
    .BLOCK dac_right_switch_op;
        .VAR dac_right_switch_op.mtu_next  = 0; // Set by switch
        .VAR dac_right_switch_op.main_next = 0; // Set by switch
        .VAR dac_right_switch_op.func = &$cbops.switch_op;
        .VAR dac_right_switch_op.param[$cbops.switch_op.STRUC_SIZE] =
            &RightPortEnabled,          // PTR_STATE_FIELD
            &copy_op_right,             // MTU_NEXT_TRUE_FIELD 
            &copy_op_left,              // MTU_NEXT_FALSE_FIELD
            &copy_op_right,             // MAIN_NEXT_TRUE_FIELD
            &dac_wrap_op;               // MAIN_NEXT_FALSE_FIELD
    .ENDBLOCK;
   
   .BLOCK copy_op_right;
        .VAR copy_op_right.mtu_next  = &copy_op_left;
        .VAR copy_op_right.main_next = &dac_wrap_op;
        .VAR copy_op_right.func = $cbops_iir_resamplev2;
        .VAR copy_op_right.param[$iir_resamplev2.OBJECT_SIZE] =
             DACINDEX_INTERNAL,                         // Input index  (input  Q23)
             DACINDEX_PORT_RIGHT,                       // Output index (output Q15)
             0,                                         // FILTER_DEFINITION_PTR_FIELD      [---CONFIG---]
             -8,                                        // INPUT_SCALE_FIELD
             0,                                         // OUTPUT_SCALE_FIELD,
             &$cbops.scratch.mem1,                      // INTERMEDIATE_CBUF_PTR_FIELD
             LENGTH($cbops.scratch.mem1),               // INTERMEDIATE_CBUF_LEN_FIELD
             0 ...;
   .ENDBLOCK;

    // Check DAC for wrap.  Always last operator
    .BLOCK dac_wrap_op;
        .VAR dac_wrap_op.mtu_next  = &dac_right_switch_op;
        .VAR dac_wrap_op.main_next = $cbops.NO_MORE_OPERATORS;
        .VAR dac_wrap_op.func = &$cbops.port_wrap_op;
        .VAR dac_wrap_op.param[$cbops.port_wrap_op.STRUC_SIZE] =
            DACINDEX_PORT_LEFT, // LEFT_PORT_FIELD
            DACINDEX_PORT_RIGHT,// RIGHT_PORT_FIELD
            3,                  // BUFFER_ADJUST_FIELD
            0,                  // MAX_ADVANCE_FIELD         [---CONFIG---]
            1,                  // SYNC_INDEX_FIELD (change to 0 if SinkSynchronize is used by VM)
            0;                  // internal : WRAP_COUNT_FIELD
    .ENDBLOCK;
.ENDMODULE;

.MODULE $tone_in;
    .DATASEGMENT DM;
    // SP.  Need to add a little headroom above a frame to
    //      handle conversion ratio plus maximum fill is size-1
    DeclareCBuffer(cbuffer_struc,mem, $BLOCK_SIZE_ADC_DAC+3 );
    
   .VAR copy_struc[] =
      $cbops.scratch.BufferTable,      // BUFFER_TABLE_FIELD
      deinterleave_mix_op,             // MAIN_FIRST_OPERATOR_FIELD
      copy_op,                         // MTU_FIRST_OPERATOR_FIELD
      1,                               // NUM_INPUTS_FIELD
      $TONE_PORT,
      1,                               // NUM_OUTPUTS_FIELD
      &cbuffer_struc,   
      1,                               // NUM_INTERNAL_FIELD
      $cbops.scratch.cbuffer_struc2;

    // for mono tone/voice prompt this is just a copy operator
    // for stereo voice prompts this operator extracts L and R voice
    // prompt samples from interleaved input stream and then mixes
    // them into one mono stream
   .BLOCK deinterleave_mix_op;
      .VAR deinterleave_mix_op.mtu_next  = $cbops.NO_MORE_OPERATORS;
      .VAR deinterleave_mix_op.main_next = copy_op;
      .VAR deinterleave_mix_op.func = $cbops.deinterleave_mix;
      .VAR deinterleave_mix_op.param[$cbops.deinterleave_mix.STRUC_SIZE] =
         0,                                  // Input index
         2,                                  // Output1 index
        -1,                                  // Output2 index
         0 ;                                 // de-interleave enabled flag
   .ENDBLOCK;

   .BLOCK copy_op;
      .VAR copy_op.mtu_next  = deinterleave_mix_op;
      .VAR copy_op.main_next = $cbops.NO_MORE_OPERATORS;
      .VAR copy_op.func = $cbops_iir_resamplev2;
      .VAR copy_op.param[$iir_resamplev2.OBJECT_SIZE_SNGL_STAGE] =
         2,                                  // Input index
         1,                                  // Output index
         &$M.iir_resamplev2.Up_2_Down_1.filter,    // FILTER_DEFINITION_PTR_FIELD
         0,                                  // INPUT_SCALE_FIELD
         8,                                  // OUTPUT_SCALE_FIELD,
         0 ...;
   .ENDBLOCK;
.ENDMODULE;
   

// Rate match enable masks
.CONST $RATE_MATCH_DISABLE_MASK              0x0000;
.CONST $HW_RATE_MATCH_ENABLE_MASK            0x0001;
.CONST $SW_RATE_MATCH_ENABLE_MASK            0x0002;
.CONST $SW_RATE_MATCH_MASK                   0x0003;

// Mask for interface mode
.CONST $AUDIO_IF_MASK                        (0x00ff);       // Mask to select the audio i/f info

.CONST $ADCDAC_PERIOD_USEC                  0.000625;

.MODULE $M.FrontEnd;
   .CODESEGMENT PM_FLASH;
   .DATASEGMENT DM;
   
   .VAR $sw_ratematching_adc = 0;
   .VAR $sw_ratematching_dac = 0;
     
   .VAR frame_adc_sampling_rate=8000;
   .VAR frame_dac_sampling_rate=8000;
   .VAR current_tone_sampling_rate=8000;
      
// *****************************************************************************
// MODULE:
//    IdentifyFilter:
//
// DESCRIPTION:
//    Search resampler list for filter descriptor.
//    List is NULL terminated with the descriptors for targets of 8kHz and 16kHz
//
// INPUTS:
//    r8 = Search Table (cvc_rcvout_resampler_lookup or cvc_sndin_resampler_lookup)
//    r7 = Sample Rate  
//    r6 = Target Sample Rate 
//
// OUTPUTS:
//    r0 = Descriptor, or NULL
// *****************************************************************************
    .VAR cvc_rcvout_resampler_lookup[] =
        // Rate     ,     8kHz-->Rate,                          16kHz-->Rate
        32000,        $M.iir_resamplev2.Up_4_Down_1.filter,     $M.iir_resamplev2.Up_2_Down_1.filter,            
        44100,        $M.iir_resamplev2.Up_441_Down_80.filter,  $M.iir_resamplev2.Up_441_Down_160_low_mips.filter,
        48000,        $M.iir_resamplev2.Up_6_Down_1.filter,     $M.iir_resamplev2.Up_3_Down_1.filter,
        96000,        $M.iir_resamplev2.Up_12_Down_1.filter,    $M.iir_resamplev2.Up_6_Down_1.filter,
        0;
    
    .VAR cvc_sndin_resampler_lookup[] =
        // Rate     ,     Rate-->8Kz,                            Rate-->16kHz
        32000,        $M.iir_resamplev2.Up_1_Down_4.filter,     $M.iir_resamplev2.Up_1_Down_2.filter,         
        44100,        $M.iir_resamplev2.Up_160_Down_441.filter, $M.iir_resamplev2.Up_160_Down_441_low_mips.filter,
        48000,        $M.iir_resamplev2.Up_1_Down_6.filter,     $M.iir_resamplev2.Up_1_Down_3.filter,
        96000,        $M.iir_resamplev2.Up_1_Down_6.filter,     $M.iir_resamplev2.Up_1_Down_3.filter,
        8000,         0,                                        $M.iir_resamplev2.Up_2_Down_1.filter,
        16000,        $M.iir_resamplev2.Up_1_Down_2.filter,     0,
        0;
        
IdentifyFilter:
    r6 = r6 - 15999;
    if NEG r6=NULL;
    // Target Sample Rate (r5)  : (0) 8kHz or (1) 16kHz
jp_identify:
    r0 = M[r8];
    if Z rts;
    r8 = r8 + 3;
    Null = r0 - 16000;
    if LE jump jp_identify;
    NULL = r0 - r7;
    if NZ jump jp_identify;    
    r8 = r8 - 2;
    r0 = M[r8 + r6];
    rts;
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
$ConfigureFrontEnd:
    $push_rLink_macro;
   
    // Get CVC variant
    r9 = M[$M.CVC_SYS.cvc_bandwidth];
    
    // Setup sample rates based on variant 
    r1 = 8000;      // 8  kHz
    Null = r9 - $M.CVC.BANDWIDTH.WB;
    if Z r1 = r1 + r1;
    M[frame_adc_sampling_rate]=r1;

    r1 = 8000;      // 8  kHz
    Null = r9 - $M.CVC.BANDWIDTH.NB;  
    if NZ r1=r1+r1;
    M[frame_dac_sampling_rate]=r1;
    
    // Setup Aux Tone sample rate 8kHz or 16kHz
    r0 = &$M.iir_resamplev2.Up_2_Down_1.filter;
    Null = r9 - $M.CVC.BANDWIDTH.NB;
    if Z r0=NULL;
    r8 = &$tone_in.copy_op.param;
    call $iir_resamplev2.SetFilter;
    
    // FE/BEX functions
    r1 = &$frame.iir_resamplev2.Process;
    Null = r9 - $M.CVC.BANDWIDTH.FE;
    if NZ r1=NULL;
    M[$fe_frame_resample_process] = r1;
    
    // Set Front end Frame Size 
    r0 = 60;
    NULL = r9 - $M.CVC.BANDWIDTH.NB;
    if NZ r0 = r0 + r0;
    M[&$M.CVC.data.stream_map_refin  + $framesync_ind.FRAME_SIZE_FIELD] = r0;
    M[&$M.CVC.data.stream_map_rcvout + $framesync_ind.FRAME_SIZE_FIELD] = r0;
    
    r0 = 60;
    NULL = r9 - $M.CVC.BANDWIDTH.WB;
    if Z r0 = r0 + r0;
    M[&$M.CVC.data.stream_map_left_adc  + $framesync_ind.FRAME_SIZE_FIELD] = r0;
    M[&$M.CVC.data.stream_map_right_adc + $framesync_ind.FRAME_SIZE_FIELD] = r0;
        
    // Setup Rate Matching
    r0 = M[$M.audio_config.audio_rate_matching];
    r0 = r0 AND $SW_RATE_MATCH_ENABLE_MASK;
    M[$sw_ratematching_dac] = r0;
    M[$sw_ratematching_adc] = r0;

    // ---- Setup ADC -----
    // Setup ADC sampling Rate
    r6 = M[frame_adc_sampling_rate]; // target rate (only 8kHz or 16kHz)
    r7 = M[$M.audio_config.adc_sampling_rate]; // I2S or DAC rate
    r8 = &cvc_sndin_resampler_lookup;
    call IdentifyFilter;
    // r0 = filter descrptor or NULL (passthrough)
    push r0;
    r8 = &$adc_in.copy_op_left.param; 
    call $iir_resamplev2.SetFilter;
    pop r0;
    r8 = &$adc_in.copy_op_right.param; 
    call $iir_resamplev2.SetFilter;
    
    // For 44.1kHz -> 8kHz, we do 44.1 -> 16kHz in the cvc_sndin_resampler_lookup 
    // above. Second copy is filter descriptor (Up_1_Down_2) or NULL.
    // Note : IdentifyFilter sets r6 to zero when the sample rate is less than 16 kHz.
    
    Null = r6;
    if NZ jump its_not_441_to_8;
    
    Null = r7 - 44100;
    if NZ jump its_not_441_to_8;

    r0 = &$M.iir_resamplev2.Up_1_Down_2.filter;
    r8 = &$adc_in.second_copy_op_left.param;
    call $iir_resamplev2.SetFilter;   
    
    r0 = &$M.iir_resamplev2.Up_1_Down_2.filter;
    r8 = &$adc_in.second_copy_op_right.param;
    call $iir_resamplev2.SetFilter;   

its_not_441_to_8:
    
    r3 = 10;  // Start with Dithering
    // r3 = dither
    r1 = M[frame_adc_sampling_rate];    // target rate
    r8 = &$adc_in.sw_rate_op.param;
    call $cbops.rate_monitor_op.Initialize;
    r8 = &$adc_in.hw_rate_op.param;
    call $cbops.hw_warp_op.Initialize;
    
    r6 = M[frame_adc_sampling_rate];
    r2 = r6 * $ADCDAC_PERIOD_USEC (frac);
    r2 = r2 + 1;
    // Jitter for send in.   The smaller the jitter the more glitches but
    //  of smaller size, or fewer glitches of a larger magnitude.  Two interupt
    //  periods seem to work well.
    r2 = r2 + r2;      
    M[&$M.CVC.data.stream_map_left_adc  + $framesync_ind.JITTER_FIELD] = r2;
    M[&$M.CVC.data.stream_map_right_adc + $framesync_ind.JITTER_FIELD] = r2;
    
    // ---- Setup DAC -----
    //  MAX_ADVANCE_FIELD for DAC cBuffer and sidetone (8kHz or 16kHz time 625usec)
    //      NB:  DAC cBuffer & Sidetone = 8kHz
    //      FE:  DAC cBuffer & Sidetone = 16kHz
    //      WB:  DAC cBuffer & Sidetone = 16kHz
    r6 = M[frame_dac_sampling_rate];
    r2 = r6 * $ADCDAC_PERIOD_USEC (frac);
    r2 = r2 + 1;
    M[$dac_out.insert_op.param + $cbops.insert_op.MAX_ADVANCE_FIELD]  = r2;
    M[&$M.CVC.data.stream_map_rcvout + $framesync_ind.JITTER_FIELD]   = r2;    
    // The reference is sync'd to the MIC inputs.   Drop/Inserts on the MIC
    //       input are detected at the reference but not visa-versa.  Give the
    //       reference a little more jitter to ensure that the drops/inserts occur 
    //       at the MIC first
    r3 = r2 * 3 (int); 
    M[&$M.CVC.data.stream_map_refin  + $framesync_ind.JITTER_FIELD]   = r3;
    
    r7 = M[$M.audio_config.dac_sampling_rate];
    r8 = &cvc_rcvout_resampler_lookup;
    call IdentifyFilter;
    // r0 is resampler Descriptor or NULL (passthrough)
    // Set DAC port MAX_ADVANCE_FIELD (r2)
    r3 = r7 * $ADCDAC_PERIOD_USEC (frac);
    r3 = r3 + 1;
    NULL = r0;
    if NZ r2=r3;
    M[$dac_out.dac_wrap_op.param + $cbops.port_wrap_op.MAX_ADVANCE_FIELD] = r2;
    // Setup DAC resamplers
    r8 = &$dac_out.copy_op_left.param;
    push r0;
    call $iir_resamplev2.SetFilter;
    pop r0;
    r8 = &$dac_out.copy_op_right.param;     
    call $iir_resamplev2.SetFilter;
    jump $pop_rLink_and_rts;
    
$DAC_CheckConnectivity:   
    $push_rLink_macro;
    r8 = 1;
    r0 = $DAC_PORT_R;
    call $cbuffer.is_it_enabled;
    if Z r8=NULL;
    M[$dac_out.RightPortEnabled] = r8;
    
    jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $set_tone_rate_from_vm
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
   $set_tone_rate_from_vm:

   $push_rLink_macro;

   // extract  mono/stereo flag, this application
   // coverts streo voice prompts to mono
   r0 = r2 AND 1;
   M[$tone_in.deinterleave_mix_op.param + $cbops.deinterleave_mix.INPUT_INTERLEAVED_FIELD] = r0;

   // firmware tones are boosted by 3 bits, voice promts expected to be normalised
   r0 = 8 + $PROMPT_EXTRA_BOOST_BITS;
   r3 = 8 + $TONE_EXTRA_BOOST_BITS;
   Null = r2 AND 0x2;
   if Z r0 = r3;
   M[$tone_in.copy_op.param + $iir_resamplev2.OUTPUT_SCALE_FIELD] = r0;

   // extract tone rate
   r1 = r1 AND 0xFFFF;
   M[current_tone_sampling_rate] = r1;

   // look up table to search
   // for matching entry
   r2 = cvc_sndin_resampler_lookup;
   r3 = r2;
   r4 = 0x7FFFFF;
   search_tone_rate_loop:
      // r3 = best match so far
      // r4 = best distance so far
      // r1 = tone sample rate

      // read next entry sample rate
      r0 = M[r2 + 0];
      // if no more entry, exit the loop
      if Z jump seach_done;

      // if exact match found exit
      r0 = r0 - r1;
      if Z jump exact_tone_found;

      // else look for nearest one
      if NEG r0 = -r0;
      Null = r4 - r0;
      if NEG jump  continue_search;

      // update nearest one
      r4 = r0;
      r3 = r2;
      continue_search:
      // go to next entry
      r2 = r2 + 3;
   jump  search_tone_rate_loop;

   exact_tone_found:
   r3 = r2;
   seach_done:
   // r3 = exact or nearest entry
   r0 = M[r3 + 1];
   r1 = M[r3 + 2];
   // r0 = rate -> 8khz coeffs
   // r1 = rate -> 16khz coeffs
   r2 = M[frame_dac_sampling_rate];
   Null = r2 - 8000;
   if NZ r0 = r1;
   // set operator filter coeffs
   r8 = &$tone_in.copy_op.param;
   call $iir_resamplev2.SetFilter;

   // clear tone buffer
   r0 = $tone_in.cbuffer_struc;
   call $cbuffer.empty_buffer;
   
   jump $pop_rLink_and_rts;

.ENDMODULE;
