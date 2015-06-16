// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1555509 $  $DateTime: 2013/03/14 18:29:20 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    This file defines the back end prcoessing for the CVC 1-MIC Headset
//    This include SCO/USB and WBS operations
//
// External References:
//
// *****************************************************************************
#include "core_library.h"
#include "cbops_multirate_library.h"
#include "frame_sync_stream_macros.h"
#include "frame_sync_library.h"
#include "plc100_library.h"
#include "sbc_library.h"
#include "usbio.h"
#include "frame_codec.h"
#include "cvc_modules.h"            
#include "cvc_headset.h"

// SCO or USB share the same port
.CONST  $SCO_IN_PORT          ($cbuffer.READ_PORT_MASK  + 1);
.CONST  $SCO_OUT_PORT         ($cbuffer.WRITE_PORT_MASK + 1);
.CONST  $USB_IN_PORT          ($cbuffer.READ_PORT_MASK  + 1);
.CONST  $USB_OUT_PORT         ($cbuffer.WRITE_PORT_MASK + 1);


// far end send output structures
.MODULE $far_end.out;
   .DATASEGMENT DM;
   // Big enough for 2 SCO packets, wmsn: for WB only
   DeclareCBuffer(frame_to_encoder.cbuffer_struc, frame_to_encoder.mem, 3*90);
   // The scaling has been reduced to 3 from 4 to reduce the usage of data memory
   DeclareCBuffer(cbuffer_struc,mem,$BLOCK_SIZE_SCO * 3);

  .VAR/DM1CIRC    sr_hist[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];

   // ** allocate memory for USB input (non-cbops) copy routine **
    .VAR/DM usb_copy_struc[$frame_sync.USB_OUT_MONO_STRUC_SIZE] =
        &cbuffer_struc,                          // USB source cbuffer
        $USB_OUT_PORT,                           // USB sink port
        -8,                                      // Shift amount
        $SAMPLE_RATE / 1000,                     // Transfer per period (number of samples transferred on each timer interrupt)
        0;                                       // Stall counter

    .VAR copy_struc[] =
        $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
        &sw_copy_op,                    // MAIN_FIRST_OPERATOR_FIELD
        &sw_copy_op,                    // MTU_FIRST_OPERATOR_FIELD
        1,                              // NUM_INPUTS_FIELD
        &frame_to_encoder.cbuffer_struc,
        1,                              // NUM_OUTPUTS_FIELD
        &cbuffer_struc,
        0;                              // NUM_INTERNAL_FIELD

    .BLOCK sw_copy_op;
        .VAR sw_copy_op.mtu_next  = $cbops.NO_MORE_OPERATORS; 
        .VAR sw_copy_op.main_next = $cbops.NO_MORE_OPERATORS;  
        .VAR sw_copy_op.func = &$cbops.rate_adjustment_and_shift;
        .VAR sw_copy_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
            0,                          // INPUT1_START_INDEX_FIELD
            1,                          // OUTPUT1_START_INDEX_FIELD
            0,                          // SHIFT_AMOUNT_FIELD
            0,                          // MASTER_OP_FIELD
            &$sra_coeffs,               // FILTER_COEFFS_FIELD
            &sr_hist,                   // HIST1_BUF_FIELD
            &sr_hist,                   // HIST1_BUF_START_FIELD
            &$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD, // SRA_TARGET_RATE_ADDR_FIELD
            0,                          // ENABLE_COMPRESSOR_FIELD
            0 ...;     
    .ENDBLOCK;

.ENDMODULE;

// far end receive input structures
.MODULE $far_end.in;
    .DATASEGMENT DM;

    DeclareCBuffer(output.cbuffer_struc,mem_output,3*90);          // Big enough for 2 SCO packets
    DeclareCBuffer(input.cbuffer_struc,mem_input,3*93);            // Big enough for 2 SCO packets with headers

    .VAR/DM1CIRC    sr_hist[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];

    // ** allocate memory for USB input (non-cbops) copy routine **
    .VAR/DM usb_copy_struc[$frame_sync.USB_IN_MONO_COPY_STRUC_SIZE] =
        $USB_IN_PORT,               // USB source port
        &input.cbuffer_struc,       // Sink buffer
        0,                          // Packet length (Number of audio data bytes in a USB packet for all channels) [--CONFIG--]
        8,                          // Shift amount
        0 ...;

    .VAR copy_struc[] =
        $cbops.scratch.BufferTable,     // BUFFER_TABLE_FIELD
        &sw_rate_op,                    // MAIN_FIRST_OPERATOR_FIELD
        &sw_copy_op,                    // MTU_FIRST_OPERATOR_FIELD
        1,                              // NUM_INPUTS_FIELD
        &input.cbuffer_struc,
        1,                              // NUM_OUTPUTS_FIELD
        &output.cbuffer_struc,
        0;                              // NUM_INTERNAL_FIELD

    .BLOCK sw_rate_op;
        .VAR sw_rate_op.mtu_next  = $cbops.NO_MORE_OPERATORS;
        .VAR sw_rate_op.main_next = &sw_copy_op; 
        .VAR sw_rate_op.func = &$cbops.rate_monitor_op;
        .VAR sw_rate_op.param[$cbops.rate_monitor_op.STRUC_SIZE] =
            0,                          // MONITOR_INDEX_FIELD
            1600,                       // PERIODS_PER_SECOND_FIELD
            10,                         // SECONDS_TRACKED_FIELD
            0,                          // TARGET_RATE_FIELD    [---CONFIG---]
            10,                         // ALPHA_LIMIT_FIELD (controls the size of the averaging window)
            0.5,                        // AVERAGE_IO_RATIO_FIELD - initialize to 1.0 in q.22
            11,                         // WARP_MSG_LIMIT_FIELD 
            2400,                       // IDLE_PERIODS_AFTER_STALL_FIELD
            0 ...;     
    .ENDBLOCK;
    
    .BLOCK sw_copy_op;
        .VAR sw_copy_op.mtu_next  = &sw_rate_op; 
        .VAR sw_copy_op.main_next = $cbops.NO_MORE_OPERATORS;  
        .VAR sw_copy_op.func = &$cbops.rate_adjustment_and_shift;
        .VAR sw_copy_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
            0,                          // INPUT1_START_INDEX_FIELD
            1,                          // OUTPUT1_START_INDEX_FIELD
            0,                          // SHIFT_AMOUNT_FIELD
            0,                          // MASTER_OP_FIELD
            &$sra_coeffs,               // FILTER_COEFFS_FIELD
            &sr_hist,                   // HIST1_BUF_FIELD
            &sr_hist,                   // HIST1_BUF_START_FIELD
            &sw_rate_op.param + $cbops.rate_monitor_op.WARP_VALUE_FIELD, // SRA_TARGET_RATE_ADDR_FIELD
            0,                          // ENABLE_COMPRESSOR_FIELD
            0 ...;     
    .ENDBLOCK;

.ENDMODULE;

.MODULE $sco_data;
    .DATASEGMENT DM;

   // sco decoder object
   .VAR/DM sco_decoder_nb[$sco_decoder.STRUC_SIZE] =
            $frame_sync.sco_decoder.pcm.validate,        // VALIDATE_FUNC
            $frame_sync.sco_decoder.pcm.process,         // DECODE_FUNC
            $frame_sync.sco_decoder.pcm.initialize,      // RESET_FUNC
            0,                                // DATA_PTR
            0.3;                              // THRESHOLD (between 0 and 1) //wmsn: this field is for PLC only

   .VAR/DM sco_decoder_wb[$sco_decoder.STRUC_SIZE] =
            $sco_decoder.wbs.validate,     // VALIDATE_FUNC
            $sco_decoder.wbs.process,      // DECODE_FUNC
            $sco_decoder.wbs.initialize,   // RESET_FUNC
            0,                             // DATA_PTR
            1.0;                           // THRESHOLD (between 0 and 1) //wmsn: this field is for PLC only

    // declare all plc memory for testing plc module
   .VAR/DM1 buffer_speech[$plc100.SP_BUF_LEN];
   .VAR/DM buffer_ola[$plc100.OLA_LEN];


    .VAR/DM plc_obj[$plc100.STRUC_SIZE] =
                   &buffer_speech,                    // SPEECH_BUF_START_ADDR_FIELD: 0
                   &buffer_speech,                    // SPEECH_BUF_PTR_FIELD: 1
                   &buffer_ola,                       // OLA_BUF_PTR_FIELD:     2
                   &$far_end.in.output.cbuffer_struc, // OUTPUT_PTR_FIELD:   3
                   0,                                 // CONSTS_FIELD:  4         [--CONFIG--]
                   $plc100.INITIAL_ATTENUATION,       // ATTENUATION_FIELD:  5
                   0,                                 // PER_THRESHOLD_FIELD:  6  [--CONFIG--]
                   0 ...;


    .VAR/DM object[$sco_pkt_handler.STRUC_SIZE ] =
                   $SCO_IN_PORT | $cbuffer.FORCE_LITTLE_ENDIAN,    // SCO PORT (header)   
                   0,                                  // SCO port (payload)      [--CONFIG--]
                   &$far_end.in.input.cbuffer_struc,   // INPUT_PTR_FIELD
                   &$far_end.in.output.cbuffer_struc,  // OUTPUT_PTR_FIELD:   2
                   0x2000,                             // ENABLE_FIELD
                   0x0000,                             // CONFIG_FIELD
                   0,                                  // STAT_LIMIT_FIELD
                   0,                                  // PACKET_IN_LEN_FIELD
                   0,                                  // PACKET_OUT_LEN_FIELD: 6
                   0                  ,                // DECODER_PTR              [--CONFIG--]
                   $plc100.process,                    // PLC_PROCESS_PTR
                   $plc100.initialize,                 // PLC_RESET_PTR
                   0,                                  // BFI_FIELD:          7
                   0,                                  // PACKET_LOSS_FIELD
                   0,                                  // INV_STAT_LIMIT_FIELD
                   0,                                  // PACKET_COUNT_FIELD
                   0,                                  // BAD_PACKET_COUNT_FIELD
                   &plc_obj,                           // PLC_DATA_PTR_FIELD

                   0,                                       // SCO_OUT_PORT_FIELD (payload)  [--CONFIG--]
                   0,                                       // SCO_OUT_SHIFT_FIELD           [--CONFIG--]
                   &$far_end.out.cbuffer_struc,             // SCO_OUT_BUFFER_FIELD
                   30,                                      // SCO_OUT_PKTSIZE_FIELD
                   0,                                       // SCO_PARAM_TESCO_FIELD
                   0,                                       // SCO_PARAM_SLOT_LS_FIELD
                   0,                                       // SCO_NEW_PARAMS_FLAG
                   0,                                       // JITTER_PTR_FIELD (not used)
                   &$far_end.out.frame_to_encoder.cbuffer_struc, // ENCODER_BUFFER_FIELD
                   120,                                     // ENCODER_INPUT_SIZE_FIELD
                   30,                                      // ENCODER_OUTPUT_SIZE_FIELD
                   &$wbsenc.set_up_frame_encode,            // ENCODER_SETUP_FUNC_FIELD
                   &$wbsenc.process_frame;                  // ENCODER_PROC_FUNC_FIELD
.ENDMODULE;

.CONST $FAR_END.AUDIO.SCO_CVSD               0;
.CONST $FAR_END.AUDIO.SCO_SBC                2;
.CONST $FAR_END.AUDIO.USB_PCM                3;
   
.MODULE $M.BackEnd;
    .CODESEGMENT PM_FLASH;
    .DATASEGMENT DM;
   
    .VAR  sco_streaming   = $FAR_END.AUDIO.DEFAULT_CODING-$FAR_END.AUDIO.USB_PCM;
    .VAR  wbs_sco_encode_func = 0;
    .VAR  wbs_init_func = 0;

// *****************************************************************************
// MODULE:
//    $ConfigureBackEnd
//
// DESCRIPTION:
//    Set up the system Back End (USB/PCM SCO/WBS SCO)
//
// INPUTS:
//      r1 - Encoding mode
// OUTPUTS:
//    none
// *****************************************************************************

$ConfigureBackEnd:
    $push_rLink_macro;
    // set sco_streaming flag
    r0 = r1 - $FAR_END.AUDIO.USB_PCM;
    M[sco_streaming] = r0;
   
    // Get CVC variant
    r9 = M[$M.CVC_SYS.cvc_bandwidth];
    
    // Set SCO/USB Frame Size
    r0 = 60;
    NULL = r9 - $M.CVC.BANDWIDTH.WB;
    if Z r0 = r0 + r0;
    M[&$M.CVC.data.stream_map_rcvin  + $framesync_ind.FRAME_SIZE_FIELD]  = r0;
    M[&$M.CVC.data.stream_map_sndout + $framesync_ind.FRAME_SIZE_FIELD]  = r0;
    
    // for USB mode, set jitter to 2ms (@16ms), otherwise zero
    r2 = $NUM_SAMPLES_2MS_16K;
    NULL = M[sco_streaming];
    if NZ r2 = Null;
    M[$M.CVC.data.stream_map_rcvin + $framesync_ind.JITTER_FIELD] = r2;
    
    r2 = &$far_end.out.cbuffer_struc;
    r3 = &$far_end.out.frame_to_encoder.cbuffer_struc;
    // Check for WBS mode
    NULL = M[sco_streaming];
    if Z  jump jp_not_wbs;
    NULL = r9 - $M.CVC.BANDWIDTH.WB;
    if NZ jump jp_not_wbs;
jp_wbs: 
    //  for WB use "frame_to_encoder" for frame process "send out"
    M[&$M.CVC.data.stream_map_sndout + $framesync_ind.CBUFFER_PTR_FIELD] = r3;

    // Set up WBS encoder
    r0 = &$cvc.wb.wbs_sco_encode;
    M[wbs_sco_encode_func] = r0;
    r0 = &$cvc.wb.wbs_initialize;
    M[wbs_init_func] = r0;
    // SCO encoded data
    r0 = $SCO_IN_PORT  + $cbuffer.FORCE_16BIT_DATA_STREAM;
    r1 = $SCO_OUT_PORT + $cbuffer.FORCE_16BIT_DATA_STREAM;
    M[$sco_data.object + $sco_pkt_handler.SCO_PAYLOAD_FIELD]=r0;
    M[$sco_data.object + $sco_pkt_handler.SCO_OUT_PORT_FIELD]=r1;
    r0 = &$sco_data.sco_decoder_wb;
    M[$sco_data.object + $sco_pkt_handler.DECODER_PTR]=r0;
    r0 = &$plc100.wb_consts;
    M[$sco_data.plc_obj + $plc100.CONSTS_FIELD]=r0;
    M[$sco_data.object + $sco_pkt_handler.SCO_OUT_SHIFT_FIELD]=NULL;
    r0 = 0.3;
    M[$sco_data.plc_obj + $plc100.PER_THRESHOLD_FIELD]=r0;
  
    jump $pop_rLink_and_rts;  
jp_not_wbs:
    // Set up routing for frame process "send out"
    //  for USB use "frame_to_encoder", For SCO use "cbuffer_struc"
    NULL = M[sco_streaming];
    if Z r2 = r3;        
    M[&$M.CVC.data.stream_map_sndout + $framesync_ind.CBUFFER_PTR_FIELD] = r2;
    
    // No Encoder
    M[wbs_sco_encode_func] = NULL;
    M[wbs_init_func]       = NULL;  
    // SCO PCM data
    r0 = $SCO_IN_PORT  + $cbuffer.FORCE_PCM_AUDIO;
    r1 = $SCO_OUT_PORT + $cbuffer.FORCE_PCM_AUDIO;
    M[$sco_data.object + $sco_pkt_handler.SCO_PAYLOAD_FIELD] = r0;
    M[$sco_data.object + $sco_pkt_handler.SCO_OUT_PORT_FIELD]= r1;
    // SCO IN PCM
    r0 = &$sco_data.sco_decoder_nb;
    M[$sco_data.object + $sco_pkt_handler.DECODER_PTR]=r0;
    r0 = &$plc100.nb_consts;
    M[$sco_data.plc_obj + $plc100.CONSTS_FIELD]=r0;
    r0 = -8;
    M[$sco_data.object + $sco_pkt_handler.SCO_OUT_SHIFT_FIELD]=r0;
    r0 = 1.0;
    M[$sco_data.plc_obj + $plc100.PER_THRESHOLD_FIELD]=r0;

    // Set USB Packet Size
    r0 = 8;
    NULL = r9 - $M.CVC.BANDWIDTH.WB;
    if Z r0 = r0 + r0;

    // Number of words transferred out per timer period
    M[$far_end.out.usb_copy_struc + $frame_sync.USB_OUT_MONO_TRANSFER_PER_PERIOD_FIELD] = r0; 
    // USB Packet Length is in Bytes
    r1 = r0 + r0;

    // Number of bytes transferred in per timer period
    M[$far_end.in.usb_copy_struc  + $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD]   = r1;

    // Set USB Rate (number of words per 1msec period * 1000)
    r1 = r0 * 1000 (int);    
    r8 = &$far_end.in.sw_rate_op.param;
    call $cbops.rate_monitor_op.Initialize;
      
    jump $pop_rLink_and_rts;
    
.ENDMODULE;

