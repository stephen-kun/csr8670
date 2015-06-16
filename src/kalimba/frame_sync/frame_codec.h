// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef CODEC_HAL_H
#define CODEC_HAL_H
   
// Common Structure for SCO packet handling code
.CONST    $sco_pkt_handler.SCO_PORT_FIELD                             0;
.CONST    $sco_pkt_handler.SCO_PAYLOAD_FIELD                          1;
.CONST    $sco_pkt_handler.INPUT_PTR_FIELD                            2;
.CONST    $sco_pkt_handler.OUTPUT_PTR_FIELD                           3;
.CONST    $sco_pkt_handler.ENABLE_FIELD                               4;
.CONST    $sco_pkt_handler.CONFIG_FIELD                               5;    // Config
.CONST    $sco_pkt_handler.STAT_LIMIT_FIELD                           6;    // Config
.CONST    $sco_pkt_handler.PACKET_IN_LEN_FIELD                        7;   
.CONST    $sco_pkt_handler.PACKET_OUT_LEN_FIELD                       8;
.CONST    $sco_pkt_handler.DECODER_PTR                                9;
.CONST    $sco_pkt_handler.PLC_PROCESS_PTR                            10;
.CONST    $sco_pkt_handler.PLC_RESET_PTR                              11;
.CONST    $sco_pkt_handler.BFI_FIELD                                  12;
.CONST    $sco_pkt_handler.PACKET_LOSS_FIELD                          13;    // Status
.CONST    $sco_pkt_handler.INV_STAT_LIMIT_FIELD                       14;
.CONST    $sco_pkt_handler.PACKET_COUNT_FIELD                         15;
.CONST    $sco_pkt_handler.BAD_PACKET_COUNT_FIELD                     16;
.CONST    $sco_pkt_handler.PLC_DATA_PTR_FIELD                         17;
// Extension for SCO Output
.CONST    $sco_pkt_handler.SCO_OUT_PORT_FIELD                         18;
.CONST    $sco_pkt_handler.SCO_OUT_SHIFT_FIELD                        19;
.CONST    $sco_pkt_handler.SCO_OUT_BUFFER_FIELD                       20;
.CONST    $sco_pkt_handler.SCO_OUT_PKTSIZE_FIELD                      21;
.CONST    $sco_pkt_handler.SCO_PARAM_TESCO_FIELD                      22;
.CONST    $sco_pkt_handler.SCO_PARAM_SLOT_LS_FIELD                    23;
.CONST    $sco_pkt_handler.SCO_NEW_PARAMS_FLAG                        24;
.CONST    $sco_pkt_handler.JITTER_PTR_FIELD                           25;

// Extension for Encoded SCO
.CONST    $sco_pkt_handler.ENCODER_BUFFER_FIELD                       26;
.CONST    $sco_pkt_handler.ENCODER_INPUT_SIZE_FIELD                   27;
.CONST    $sco_pkt_handler.ENCODER_OUTPUT_SIZE_FIELD                  28;
.CONST    $sco_pkt_handler.ENCODER_SETUP_FUNC_FIELD                   29;
.CONST    $sco_pkt_handler.ENCODER_PROC_FUNC_FIELD                    30;

.CONST    $sco_pkt_handler.STRUC_SIZE                                 31;

// Common structure for all decoders in SCO packet handling code
.CONST    $sco_decoder.VALIDATE_FUNC                                  0;
.CONST    $sco_decoder.DECODE_FUNC                                    1;
.CONST    $sco_decoder.RESET_FUNC                                     2;
.CONST    $sco_decoder.DATA_PTR                                       3;
.CONST    $sco_decoder.THRESHOLD                                      4;
.CONST    $sco_decoder.STRUC_SIZE                                     5;

#endif
