// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.com
// Part of ADK 3.5
//
// *****************************************************************************
#ifndef SPDIF_STREAM_DECODE_HEADER_INCLUDED
#define SPDIF_STREAM_DECODE_HEADER_INCLUDED

   // -- Define spdif "stream decode" structure fields

   // fields for general setting
   .CONST $spdif.stream_decode.SPDIF_FRAME_COPY_STRUCT_FIELD                            0;  // spdif "frame copy" structure
   .CONST $spdif.stream_decode.GET_DECODER_FUNCTION_PTR_FIELD                           1;  // call back function to get decoder info
   .CONST $spdif.stream_decode.MASTER_RESET_FUNCTION_FIELD                              2;  // master reset function

   // fields for output interface setting, only used with SPDIF_OUTPUT_INTERFACE_CONTROL defined
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_TYPE_FIELD                              3;  // output interface type
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_LEFT_PORT_FIELD                         4;  // output interface left port
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_RIGHT_PORT_FIELD                        5;  // output interface right port
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_FADING_DIRECTION_PTR_FIELD              6;  // variable's address to control fading in/out the output interface
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_SETTING_RATE_FIELD                      7;  // if not 0, will be used for output rate config, else output rate = input rate

   // latency measurement input
   .CONST $spdif.stream_decode.LATENCY_MEASUREMENT_STRUCT_FIELD                         8;  // latency measurement input structure

   // general state variables
   .CONST $spdif.stream_decode.MODE_FIELD                                               9;  // output result
   .CONST $spdif.stream_decode.CURRENT_CODEC_TYPE_FIELD                                 10;  // current codec type of spdif stream
   .CONST $spdif.stream_decode.DECODER_DECODE_STRUCT_FIELD                              11;  // decoder input structure
   .CONST $spdif.stream_decode.DECODER_FRAME_DECODE_FUNCTION_FIELD                      12;  // decoder frame decode function
   .CONST $spdif.stream_decode.DECODER_RESET_FUNCTION_FIELD                             13;  // decoder reset function
   .CONST $spdif.stream_decode.CODEC_IS_DECODING_FIELD                                  14;  // flag showing whether decoder is currently decoding
   .CONST $spdif.stream_decode.STALL_COPYING_FIELD                                      15;  // flag showing copying shall be stalled now

   // state variables for SPDIF_OUTPUT_INTERFACE_CONTROL
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_STATE_FIELD                             16; // current state of output interface
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_PROCESSING_STATE_FIELD                  17; // processing state for output interface
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_CONFIG_RATE_FIELD                       18; // rate sent to fw for output interface
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_CURRENT_RATE_FIELD                      19; // current rate of output
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_FW_CONFIRM_PENDIG_FIELD                 20; // number of pending confirms from fw
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_NEW_TYPE_FIELD                          21; // new output interface type
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_NEW_LEFT_PORT_FIELD                     22; // new output interface left port
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_NEW_RIGHT_PORT_FIELD                    23; // new output interface right
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_UPDATE_INTERFACE_FIELD                  24; // flag showing request for change of output interface
   .CONST $spdif.stream_decode.OUTPUT_INTERFACE_INIT_ACTIVE_FIELD                       25; // flag shows whether output ports already active
   .CONST $spdif.stream_decode.STRUC_SIZE                                               26;

#endif // #ifndef SPDIF_STREAM_DECODE_HEADER_INCLUDED
