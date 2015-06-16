// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2003)        http://www.csr.com
// %%version
//
// $Revision: #2 $  $Date: 2014/05/09 $
// *****************************************************************************

#ifndef CODEC_DECODER_FASTSTREAM_HEADER_INCLUDED
#define CODEC_DECODER_FASTSTREAM_HEADER_INCLUDED

#include "music_example.h"

#if !defined(FASTSTREAM_ENABLE)
    #error "The define FASTSTREAM_ENABLE must currently be set"
    #error "SBC is the only CODEC currently supported by faststream"
#endif

#define SIGNAL_DETECT_THRESHOLD                         (0.000316)  // detection level threshold (0.000316 = -70 dBFS)
#define SIGNAL_DETECT_TIMEOUT                           (600)       // length of silence before message sent to VM (600 = 10 minutes)


// 1ms is chosen as the interrupt rate for the codec input/output as this is a
// good compromise between not overloading the xap with messages and making
// sure that the xap side buffer is emptied relatively often.
#define TMR_PERIOD_CODEC_COPY                           1000

// 0.5ms is chosen as the interrupt rate for the audio input/output because:
// adc/dac mmu buffer is 256byte = 128samples
//                               - upto 8 sample fifo in voice interface
//                               = 120samples = 2.5ms @ 48KHz
// assume absolute worst case jitter on interrupts = 1.0ms
// hence we need it <=1.5ms between audio input/output interrupts
// We want absolute minimum latency so choose 0.5ms
#define TMR_PERIOD_AUDIO_COPY                           500

// The timer period for copying tones.  We don't want to force the VM to fill
// up the tone buffer too regularly.
#define TMR_PERIOD_TONE_COPY                            6000
.CONST  $PCM_END_DETECTION_TIME_OUT                     (30000);        // minimum tone inactivity time before sending TONE END message

#define TONE_BUFFER_SIZE                                192 // for 8khz input and 16ms interrupt period

// Force a limit on the number of words in decoder input buffer by throwing out one frame
#define MONITOR_CODEC_BUFFER_LEVEL                      324             // in WORDS (has been set for maximum delay of 40ms)
#define TARGET_CODEC_BUFFER_LEVEL                       288             // in WORDS (has been set for 37ms delay)


// Faststream frame length is 36 words
#define FAST_STREAM_FRAME_LENGTH                        36
#define MAX_SAMPLE_RATE                                 48000
#define ABSOLUTE_MAXIMUM_CLOCK_MISMATCH_COMPENSATION    0.03     // this is absolute maximum value(3%), it is also capped to value received from vm
.CONST $OUTPUT_AUDIO_CBUFFER_SIZE                       ($music_example.NUM_SAMPLES_PER_FRAME + 2*(TMR_PERIOD_AUDIO_COPY * MAX_SAMPLE_RATE/1000000));
#define SRA_AVERAGING_TIME                              1               // in seconds (this is optimal value, smaller values migh handle jitter better but might cause warping effect)
#define SRA_MAXIMUM_RATE                                0.005           // max absolute value of SRA rate, this is to compensate for clock drift between SRC and SNK(~ +-250Hz)
                                                                        // and to some extent handle the jitter,

// A debug define to force the decoder to use a mono output
//#define FORCE_MONO_OUTPUT

// I/O configuration enum matches the PLUGIN type from the VM
.CONST  $INVALID_IO                                     -1;
.CONST  $SBC_IO                                         1;
.CONST  $MP3_IO                                         2;
.CONST  $AAC_IO                                         3;
.CONST  $FASTSTREAM_IO                                  4;
.CONST  $USB_IO                                         5;
.CONST  $APTX_IO                                        6;
.CONST  $APTX_ACL_SPRINT_IO                             7;
.CONST  $ANALOGUE_IO                                    8;

#define VM_DAC_RATE_MESSAGE_ID                          0x7050          // Obsoleted message use VM_SET_DAC_RATE_MESSAGE_ID

#define VM_SET_DAC_RATE_MESSAGE_ID                      0x1070          // Set the DAC sampling rate (plus other rate match params)
#define VM_SET_CODEC_RATE_MESSAGE_ID                    0x1071          // Set the codec sampling rate
#define VM_SET_TONE_RATE_MESSAGE_ID                     0x1072          // Set the tone sampling rate

#define PLAY_BACK_FINISHED_MSG                          0x1080
#define UNSUPPORTED_SAMPLING_RATES_MSG                  0x1090

.CONST  $AUDIO_IF_MASK                                  (0x00ff);       // Mask to select the audio i/f info
.CONST  $LOCAL_PLAYBACK_MASK                            (0x0100);       // Mask to select the local playback control bit

.CONST  $AUDIO_LEFT_OUT_PORT                            ($cbuffer.WRITE_PORT_MASK + 0);
.CONST  $AUDIO_RIGHT_OUT_PORT                           ($cbuffer.WRITE_PORT_MASK + 1);

// Port used for CODEC inputs
.CONST  $CODEC_IN_PORT                                  ($cbuffer.READ_PORT_MASK + 2);

.CONST  $AUDIO_LEFT_IN_PORT                             ($cbuffer.READ_PORT_MASK + 0);
.CONST  $CODEC_OUT_PORT                                 ($cbuffer.WRITE_PORT_MASK + 2);

// Port used for tone inputs
.CONST  $TONE_IN_PORT                                   (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO)  + 3);

#endif

