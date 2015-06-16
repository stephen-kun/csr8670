// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    plc100 library
//
// DESCRIPTION:
//    This library is meant to detect lost packets in the input PCM data and
//    compensate for the lost packets by intelligent replacement of lost packets
//    to mitigate perceptual impact of lost packets in processed speech output
// *****************************************************************************

#ifndef PLC100_LIB_H
#define PLC100_LIB_H

   // library build version
   .CONST $PLC100_VERSION 0x010000;



   // @DATA_OBJECT PLC_DATAOBJECT
   // field definitions for plc100 internal data object

   // @DOC_FIELD_TEXT  Pointer to start address of input speech circular buffer.  Length of the buffer is specified by constant: $plc100.SP_BUF_LEN_NB or $plc100.SP_BUF_LEN_WB
   // @DOC_FIELD_FORMAT  Pointer
   .CONST $plc100.SPEECH_BUF_START_ADDR_FIELD     0;
   // @DOC_FIELD_TEXT  Internal
   .CONST $plc100.SPEECH_BUF_PTR_FIELD            1;
   // @DOC_FIELD_TEXT  Pointer to OLA buffer.   Length of the buffer is specified by constant: $plc100.OLA_LEN_NB or $plc100.OLA_LEN_WB
   // @DOC_FIELD_FORMAT  Pointer
   .CONST $plc100.OLA_BUF_PTR_FIELD               2;
   // @DOC_FIELD_TEXT  Pointer to output CBUFFER structure
   // @DOC_FIELD_FORMAT  Pointer
   .CONST $plc100.OUTPUT_PTR_FIELD                3;
   // @DOC_FIELD_TEXT  Pointer to internal constant table.   NB:&$plc100.nb_consts.    WB:&$plc100.wb_consts
   // @DOC_FIELD_FORMAT  Pointer
   .CONST $plc100.CONSTS_FIELD                    4;
   // @DOC_FIELD_TEXT  OLA attenuation factor, default using $plc100.INITIAL_ATTENUATION.
   // @DOC_FIELD_FORMAT  Q1.23
   .CONST $plc100.ATTENUATION_FIELD               5;
   // @DOC_FIELD_TEXT  Packet error rate threhold field: If the packet error rate exceeds this threshold, the PLC algorithm is bypassed and damaged packets are passed through to the output unchanged.
   // @DOC_FIELD_FORMAT  Q1.23
   .CONST $plc100.PER_THRESHOLD_FIELD             6;
   .CONST $plc100.PACKET_LEN_FIELD                7;
   .CONST $plc100.BFI_FIELD                       8;
   .CONST $plc100.BFI1_FIELD                      9;
   .CONST $plc100.BFI_CUR_FIELD                  10;
   .CONST $plc100.PER_FIELD                      11;
   .CONST $plc100.PITCH_FIELD                    12;
   .CONST $plc100.BFI_PREV_FIELD                 13;
   .CONST $plc100.HARM_FIELD                     14;
   .CONST $plc100.TONALITY_FIELD                 15;
   .CONST $plc100.LOOP_LIMIT_FIELD               16;
   .CONST $plc100.SUB_PACKET_LEN_FIELD           17;
   .CONST $plc100.LOOP_COUNTER_FIELD             18;
   // @DOC_FIELD_TEXT  PLC data object structure size
   .CONST $plc100.STRUC_SIZE                     19;
   // @END  DATA_OBJECT PLC_DATAOBJECT

   .CONST $plc100.consts.SPEECH_BUF_LEN_FIELD     0;
   .CONST $plc100.consts.OLA_LEN_FIELD            1;
   .CONST $plc100.consts.RANGE_FIELD              2;
   .CONST $plc100.consts.MIN_DELAY_FIELD          3;
   .CONST $plc100.consts.MAX_DELAY_FIELD          4;
   .CONST $plc100.consts.PER_TC_INV_FIELD         5;
   .CONST $plc100.consts.OLA_WIN_PTR_FIELD        6;
   .CONST $plc100.consts.STRUC_SIZE               7;





   // 1.0 in Q16 format
   .CONST $plc100.ONEQ16               0x010000;
   // 0.07 in Q16 format
   .CONST $plc100.M_THRESH             0x11EC;
   // 1.75 in Q16 format
   .CONST $plc100.HARM_TONETHRESH      0x1C000;
   .CONST $plc100.MAX_PACKET_LEN       60;
   .CONST $plc100.ATT_THRESH           0.95;
   // constants independent of NB/WB configuration
   .CONST $plc100.HARM_THRESHOLD       0xB333;  // harmonicity threshold
   .CONST $plc100.XCORR_THRESH         0x733333;// 0.9 in Q23 format

   // initial value for attenuation
   .CONST $plc100.INITIAL_ATTENUATION  0.8;


   // bfi for bit errored packet = 1
   .CONST $plc100.BITERROR_PACKET 1;
   // bfi for missed packet = 3
   .CONST $plc100.MISSED_PACKET 3;



   // constants needed by application to configure plc data object (NB and WB)
   // NB = narrowband;
   .CONST $plc100.MIN_DELAY_NB         54;
   .CONST $plc100.MAX_DELAY_NB         108;     // 2 * min delay
   .CONST $plc100.OLA_LEN_NB           10;
   .CONST $plc100.SP_BUF_LEN_NB        226;     // (2 * max delay) + ola len
   .CONST $plc100.RANGE_NB             4;
   .CONST $plc100.PER_TC_INV_NB        0x6666;  // 1/(fs*alpha_in_sec) in Q23 format
   // WB = wideband
   .CONST $plc100.MIN_DELAY_WB         107;
   .CONST $plc100.MAX_DELAY_WB         214;     // 2 * min delay
   .CONST $plc100.OLA_LEN_WB           24;
   .CONST $plc100.SP_BUF_LEN_WB        452;     // (2 * max delay) + ola len
   .CONST $plc100.RANGE_WB             8;
   .CONST $plc100.PER_TC_INV_WB        0x3333;  // 1/(fs*alpha_in_sec) in Q23 format
#endif   // PLC100_LIB_
