// *****************************************************************************
// %%fullcopyright(2009)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef music_example_LIB_H
#define music_example_LIB_H

#include "subwoofer_library_gen.h"

//  MUSIC_EXAMPLE version number
#define MUSIC_EXAMPLE_VERSION                               0x0001

.CONST $music_example.JITTER                                  3000;

// SPI Message IDs
.CONST $M.music_example.SPIMSG.STATUS                       0x1007;
.CONST $M.music_example.SPIMSG.PARAMS                       0x1008;
.CONST $M.music_example.SPIMSG.REINIT                       0x1009;
.CONST $M.music_example.SPIMSG.VERSION                      0x100A;
.CONST $M.music_example.SPIMSG.CONTROL                      0x100B;

// VM Message IDs
.CONST $music_example.VMMSG.READY                           0x1000;
.CONST $music_example.VMMSG.SETMODE                         0x1001;
.CONST $music_example.VMMSG.VOLUME                          0x1002;
.CONST $music_example.VMMSG.SETPARAM                        0x1004;
.CONST $music_example.VMMSG.CODEC                           0x1006;
.CONST $music_example.VMMSG.PING                            0x1008;
.CONST $music_example.VMMSG.PINGRESP                        0x1009;
.CONST $music_example.VMMSG.SECPASSED                       0x100c;
.CONST $music_example.VMMSG.SETSCOTYPE                      0x100d;
.CONST $music_example.VMMSG.SETCONFIG                       0x100e;
.CONST $music_example.VMMSG.SETCONFIG_RESP                  0x100f;
.CONST $music_example.VMMSG.GETPARAM                        0x1010;
.CONST $music_example.VMMSG.GETPARAM_RESP                   0x1011;
.CONST $music_example.VMMSG.LOADPARAMS                      0x1012;
.CONST $music_example.VMMSG.CUR_EQ_BANK                     0x1014;
.CONST $music_example.VMMSG.PARAMS_LOADED                   0x1015;
.CONST $music_example.VMMSG.APTX_PARAMS                     0x1016;
.CONST $music_example.VMMSG.APTX_SECURITY                   0x1017;

.const $music_example.VMMSG.SIGNAL_DETECT_SET_PARMS         0x1018;
.const $music_example.VMMSG.SIGNAL_DETECT_STATUS            0x1019;
.const $music_example.VMMSG.SOFT_MUTE                       0x101a;

.const $music_example.VMMSG.DAC_RATE                        0x1070;   // Set the DAC sampling rate (plus other rate match params)



.CONST $music_example.VMMSG.SETPLUGIN                       0x1020;

// VM Messages associated with GAIA commands

.const $music_example.GAIAMSG.SET_USER_PARAM                0x121a;
.const $music_example.GAIAMSG.GET_USER_PARAM                0x129a;
.const $music_example.GAIAMSG.SET_USER_GROUP_PARAM          0x121b;
.const $music_example.GAIAMSG.GET_USER_GROUP_PARAM          0x129b;

.const $music_example.GAIAMSG.SET_USER_PARAM_RESP           0x321a;
.const $music_example.GAIAMSG.GET_USER_PARAM_RESP           0x329a;
.const $music_example.GAIAMSG.SET_USER_GROUP_PARAM_RESP     0x321b;
.const $music_example.GAIAMSG.GET_USER_GROUP_PARAM_RESP     0x329b;


.CONST $music_example.REINITIALIZE                          1;

// Codec mute control
.CONST $music_example.MUTE_CONTROL.OFFSET_INPUT_PTR         0;
.CONST $music_example.MUTE_CONTROL.OFFSET_INPUT_LEN         1;
.CONST $music_example.MUTE_CONTROL.OFFSET_NUM_SAMPLES       2;
.CONST $music_example.MUTE_CONTROL.OFFSET_MUTE_VAL          3;
.CONST $music_example.MUTE_CONTROL.STRUC_SIZE               4;

// Data block size
// TMR_PERIOD_AUDIO_COPY and NUM_SAMPLES_PER_FRAME will affect the audio quality. Need to ensure
// that both TMR_PERIOD_AUDIO_COPY and NUM_SAMPLE_PER_FRAME are set appropriately to provide the
// DAC port with enough data for each timer interrupt.
//
// Therefore, the minimum value for NUM_SAMPLES_PER_FRAME is ceiling((TMR_PERIOD_AUDIO_COPY/1000000) * SAMPLE_RATE)
// where TMR_PERIOD_AUDIO_COPY is given in microseconds and SAMPLE_RATE is given in hertz.
.CONST $music_example.NUM_SAMPLES_PER_FRAME                 360;
.CONST $music_example.NUM_SAMPLES_PER_TWO_FRAMES            720;
.CONST $music_example.NUM_SAMPLES_PER_PLC                     9;

// Overloaded PEQ data object definition
.CONST $music_example.peq.INPUT_ADDR_FIELD                  0;
.CONST $music_example.peq.INPUT_SIZE_FIELD                  1;
.CONST $music_example.peq.OUTPUT_ADDR_FIELD                 2;
.CONST $music_example.peq.OUTPUT_SIZE_FIELD                 3;
.CONST $music_example.peq.DELAYLINE_ADDR_FIELD              4;
.CONST $music_example.peq.COEFS_ADDR_FIELD                  5;
.CONST $music_example.peq.NUM_STAGES_FIELD                  6;
.CONST $music_example.peq.DELAYLINE_SIZE_FIELD              7;
.CONST $music_example.peq.COEFS_SIZE_FIELD                  8;
.CONST $music_example.peq.BLOCK_SIZE_FIELD                  9;
.CONST $music_example.peq.SCALING_ADDR_FIELD                10;
.CONST $music_example.peq.GAIN_EXPONENT_ADDR_FIELD          11;
.CONST $music_example.peq.GAIN_MANTISA_ADDR_FIELD           12;
.CONST $music_example.peq.BYPASS_BIT_MASK_FIELD             13;

.CONST $music_example.peq.STRUC_SIZE                        14;

// PEQ Bank Select Definitions
.CONST $music_example.peq.BS_COEFFS_PTR_FIELD               0;
.CONST $music_example.peq.BS_SCALE_PTR_FIELD                1;
.CONST $music_example.peq.BS_NUMSTAGES_FIELD                2;
.CONST $music_example.peq.BS_GAIN_EXP_PTR_FIELD             3;
.CONST $music_example.peq.BS_GAIN_MANT_PTR_FIELD            4;
.CONST $music_example.peq.BS_STRUC_SIZE                     5;

.CONST $WALL_CLOCK_UPDATE_PERIOD         100000;
.CONST $INPUT_CBUFFER_SIZE                  150;  //  TODO: 60 or 150? 60 samples can hold two 60 byte 2ev3 packets - MIGHT BE SUFFICIENT.  150 holds 6 L2CAP packets.
.CONST $OUTPUT_CBUFFER_SIZE                   (($music_example.NUM_SAMPLES_PER_FRAME * 4) + $music_example.NUM_SAMPLES_PER_FRAME /2) * 1; // allows PLC to generate two 15ms frames. 
.CONST $SCO_ERROR_NO_DATA                     4;
.CONST $SCO_ERROR_NO_META_DATA_SYNC_WORD      5;
.CONST $SCO_ERROR_NO_SWAT_SYNC_WORD           6;
.CONST $SCO_ERROR_SOURCE_FLUSHED_PACEKT       7;
.CONST $SCO_ERROR_PACKET_COUNTER              7;
.CONST $TMR_PERIOD_CHECK_DATA               250;
.CONST $500_US_AT_48000_HZ                   24; 
.CONST $L2CAP_HEADER_SIZE                     7; // 7 words
.CONST $L2CAP_AUDIO_SIZE                     18; // 18 audio samples
.CONST $L2CAP_FRAME_SIZE                     $L2CAP_HEADER_SIZE + $L2CAP_AUDIO_SIZE;
.CONST $FLUSH_TIMEOUT                     30000; // 30 ms jitter on L2CAP audio
.CONST $SUBSTREAM_LATENCY                 30000; // TODO: empircally determine if this can be decreased.
.CONST $L2CAP_JITTER_TIME                 $FLUSH_TIMEOUT + $SUBSTREAM_LATENCY; 
.CONST $L2CAP_AUDIO_HANDLER_INTERVAL       3750; // Handler will copy data to DAC port every 3.75 ms.
.CONST $TMR_PERIOD_ADC_DAC                 3750;

.CONST $plc100.OLA_LEN_SW           3;
.CONST $plc100.MIN_DELAY_SW         30;     // Based off min pitch of 20 Hz.
.CONST $plc100.MAX_DELAY_SW         60;     // 2 * min delay
.CONST $plc100.RANGE_SW             4;
.CONST $plc100.SP_BUF_LEN_SW        123;     // (2 * max delay) + ola len
.CONST $plc100.PER_TC_INV_SW        0x2AAAA;  // 1/(fs*T) in Q23 format

.CONST $THIRTY_SECONDS_ESCO                      4096;
.CONST $DAC_PORT_SIZE                            256;
.CONST $OUTPUT_CBUFFER_SIZE_L2CAP_RATE_MATCHING  5040;  // 720 * 7. A lot of data is buffered in L2CAP mode to help ensure robustness.  We need to have a big DAC buffer so that we have enough headroom to analyze the rate mismatch between Soundbar and Subwoofer.

#endif

