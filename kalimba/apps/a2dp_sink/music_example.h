// *****************************************************************************
// %%fullcopyright(2009)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************


#ifndef music_example_LIB_H
#define music_example_LIB_H

#include "music_manager_library_gen.h"
#include "audio_proc_library.h"

//  MUSIC_EXAMPLE version number
#define MUSIC_EXAMPLE_VERSION                               0x0001

.CONST $music_example.JITTER    3000; 

// SPI Message IDs
.CONST $M.music_example.SPIMSG.STATUS                       0x1007;
.CONST $M.music_example.SPIMSG.PARAMS                       0x1008;
.CONST $M.music_example.SPIMSG.REINIT                       0x1009;
.CONST $M.music_example.SPIMSG.VERSION                      0x100A;
.CONST $M.music_example.SPIMSG.CONTROL                      0x100B;
.CONST $M.music_example.SPIMSG.SPDIF_CONFIG                 0x2000;  
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


.CONST $music_example.VMMSG.SETPLUGIN                       0x1020;

#ifdef LATENCY_REPORTING
.CONST $music_example.VMMSG.LATENCY_REPORTING               0x1023;
#endif

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
#ifdef SUB_ENABLE
    // 360 samples is used with subwoofer so sub packets and frames line up
    .CONST $music_example.NUM_SAMPLES_PER_FRAME                 360;
#else // SUB_ENABLE
    .CONST $music_example.NUM_SAMPLES_PER_FRAME                 160;
#endif // SUB_ENABLE

// Overloaded PEQ data object definition
.CONST $music_example.peq.INPUT_ADDR_FIELD                  0;
.CONST $music_example.peq.OUTPUT_ADDR_FIELD                 1;
.CONST $music_example.peq.MAX_STAGES_FIELD                  2;
.CONST $music_example.peq.PARAM_PTR_FIELD                   3;  
.CONST $music_example.peq.DELAYLINE_ADDR_FIELD              4;
.CONST $music_example.peq.COEFS_ADDR_FIELD                  5;
.CONST $music_example.peq.NUM_STAGES_FIELD                  6;
.CONST $music_example.peq.DELAYLINE_SIZE_FIELD              7;
.CONST $music_example.peq.COEFS_SIZE_FIELD                  8;
.CONST $music_example.peq.BLOCK_SIZE_FIELD                  9;
.CONST $music_example.peq.SCALING_ADDR_FIELD               10;
.CONST $music_example.peq.GAIN_EXPONENT_ADDR_FIELD         11;
.CONST $music_example.peq.GAIN_MANTISA_ADDR_FIELD          12;
.CONST $music_example.peq.BYPASS_BIT_MASK_FIELD            13;

.CONST $music_example.peq.STRUC_SIZE                       14;

// PEQ Bank Select Definitions
.CONST $music_example.peq.BS_COEFFS_PTR_FIELD               0;
.CONST $music_example.peq.BS_SCALE_PTR_FIELD                1;
.CONST $music_example.peq.BS_NUMSTAGES_FIELD                2;
.CONST $music_example.peq.BS_GAIN_EXP_PTR_FIELD             3;
.CONST $music_example.peq.BS_GAIN_MANT_PTR_FIELD            4;
.CONST $music_example.peq.BS_STRUC_SIZE                     5;

// Codec configuration offsets
.CONST $music_example.SBC_CODEC_CONFIG                      $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC1_CONFIG;
.CONST $music_example.MP3_CODEC_CONFIG                      $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC2_CONFIG;
.CONST $music_example.FASTSTREAM_CODEC_CONFIG               $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC3_CONFIG;
.CONST $music_example.USB_CODEC_CONFIG                      $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC4_CONFIG;
.CONST $music_example.APTX_CODEC_CONFIG                     $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC5_CONFIG;
.CONST $music_example.AAC_CODEC_CONFIG                      $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC6_CONFIG;
.CONST $music_example.ANALOGUE_CODEC_CONFIG                 $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC7_CONFIG;
.CONST $music_example.APTX_ACL_SPRINT_CODEC_CONFIG          $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC8_CONFIG;
.CONST $music_example.SPDIF_CODEC_CONFIG                    $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC9_CONFIG;

// Codec types
.CONST  $music_example.SBC_CODEC_TYPE                       0;
.CONST  $music_example.MP3_CODEC_TYPE                       1;
.CONST  $music_example.FASTSTREAM_CODEC_TYPE                2;
.CONST  $music_example.USB_CODEC_TYPE                       3;
.CONST  $music_example.APTX_CODEC_TYPE                      4;
.CONST  $music_example.AAC_CODEC_TYPE                       5;
.CONST  $music_example.ANALOGUE_CODEC_TYPE                  6;
.CONST  $music_example.APTX_ACL_SPRINT_CODEC_TYPE           7;
.CONST  $music_example.SPDIF_CODEC_TYPE                     8;

// Codec stats structure size
.CONST  $music_example.CODEC_STATS_SIZE                     ($M.MUSIC_MANAGER.STATUS.BLOCK_SIZE - $M.MUSIC_MANAGER.STATUS.CODEC_FS_OFFSET);

.CONST $music_example.12dB                                  12.041199826559248;
.CONST $music_example.DEFAULT_MASTER_VOLUME                 $volume_and_limit.dB2VOL(0 + $music_example.12dB);  // 0dB + 12dB headroom
.CONST $music_example.DEFAULT_TRIM_VOLUME                   $volume_and_limit.dB2VOL(0);                        // 0dB
.CONST $music_example.LIMIT_THRESHOLD                       $volume_and_limit.LIMIT_THRESHOLD(-1.0);            // Threshold = -1dB
.CONST $music_example.LIMIT_RATIO                           $volume_and_limit.LIMIT_RATIO(20);                  // Ratio = 20
.CONST $music_example.LIMIT_THRESHOLD_LINEAR                ((10.0**(-1.0/20.0))/16.0);                         // Threshold = -1dB
.CONST $music_example.MAX_VM_TRIM_VOLUME_dB                 round($music_example.12dB*60.0);                    // Max Trim Volume = +12dB
.CONST $music_example.MIN_VM_TRIM_VOLUME_dB                 round(-$music_example.12dB*60.0);                   // Min Trim Volume = -12dB
.CONST $music_example.MUTE_MASTER_VOLUME                    0;                                                  // Mute

#endif

