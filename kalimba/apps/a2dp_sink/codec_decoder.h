// *****************************************************************************
// %%fullcopyright(2003)        http://www.csr.com
// %%version
//
// $Change: 1939690 $  $DateTime: 2014/07/14 20:50:45 $
// *****************************************************************************

#ifndef CODEC_DECODER_HEADER_INCLUDED
#define CODEC_DECODER_HEADER_INCLUDED

#include "music_example.h"



#define SIGNAL_DETECT_THRESHOLD                         (0.000316)  // detection level threshold (0.000316 = -70 dBFS)
#define SIGNAL_DETECT_TIMEOUT                           (600)       // length of silence before message sent to VM (600 = 10 minutes)

#ifdef USB_ENABLE
   // USB related defines

   #define $SAMPLE_RATE                                 48000    // Sampling rate in Hertz
   #define $SAMPLE_SIZE                                 2        // 2 bytes per sample
   #define $PACKET_RATE                                 1000     // Number of packets in 1 second
   #define $NUM_CHANNELS                                2        // Number of channels (Mono: 1, Stereo: 2)

   #define $USB_PACKET_LEN                              (($SAMPLE_RATE * $SAMPLE_SIZE * $NUM_CHANNELS) / $PACKET_RATE)   // Number of audio data bytes in a USB packet (for all channels)

   // Port is only 128 samples (256 bytes) so must empty it before it fills (receives 48l+48r samples every msec)
   #define TMR_PERIOD_USB_IN_COPY                       800
#endif // #ifdef USB_ENABLE

#ifdef ANALOGUE_ENABLE
   #define TMR_PERIOD_ANALOGUE_IN_COPY                  1500
#endif // #ifdef ANALOGUE_ENABLE

// A2DP related defines

// 8ms is chosen as the interrupt rate for the codec input/output as this is a
// good compromise between not overloading the xap with messages and making
// sure that the xap side buffer is emptied relatively often.
#ifdef LATENCY_REPORTING
    #define TMR_PERIOD_CODEC_COPY                       1000
#else
#ifdef ANC_96K
    #define TMR_PERIOD_CODEC_COPY                       4000
#else
    #define TMR_PERIOD_CODEC_COPY                       8000
#endif
#endif

// 1.5ms is chosen as the interrupt rate for the audio input/output because:
// adc/dac mmu buffer is 256byte = 128samples
//                               - upto 8 sample fifo in voice interface
//                               = 120samples = 2.5ms @ 48KHz
// assume absolute worst case jitter on interrupts = 1.0ms
// Hence choose 1.5ms between audio input/output interrupts

#ifdef ANC_96K
// For 96 kHz: 120samples = 1.25ms @ 96KHz
// jitter on interrupts = 1.0ms
// Hence choose .25ms between audio input/output interrupts
    #define TMR_PERIOD_AUDIO_COPY                       500
#else
    #define TMR_PERIOD_AUDIO_COPY                       1500
#endif


#define LOCAL_TMR_PERIOD_CODEC_COPY                     500      // to read file thoroughly before port is closed

// The timer period for copying tones.  We don't want to force the VM to fill
// up the tone buffer too regularly.
#define TMR_PERIOD_TONE_COPY                            16000

#define TONE_BUFFER_SIZE                                256 // for 8khz input and 16ms interrupt period

// The frame_sync output cbuffer (dac_out) size does not have to equal the frame_sync input cbuffer (audio_out) size
// The minimum size = NUM_SAMPLES_PER_FRAME + 2*(number of samples per timer interrupt)

#ifdef ANC_96K
    #define MAX_SAMPLE_RATE                             96000
#else
    #define MAX_SAMPLE_RATE                             48000
#endif

#define ABSOLUTE_MAXIMUM_CLOCK_MISMATCH_COMPENSATION    0.03     // this is absolute maximum value(3%), it is also capped to value received from vm
#define DEFAULT_MAXIMUM_CLOCK_MISMATCH_COMPENSATION    0.005    // maximum half a percent compensation, 0.5% default value
.CONST $OUTPUT_AUDIO_CBUFFER_SIZE                       (($music_example.NUM_SAMPLES_PER_FRAME*2) + 2*(TMR_PERIOD_AUDIO_COPY * MAX_SAMPLE_RATE/1000000));  
#define SRA_AVERAGING_TIME                              2        //in seconds


// A debug define to force the decoder to use a mono output
//.CONST FORCE_MONO                                   1;

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
.CONST  $SPDIF_IO                                       9;

#define VM_DAC_RATE_MESSAGE_ID                          0x7050          // Obsoleted message use VM_SET_DAC_RATE_MESSAGE_ID

#define VM_SET_DAC_RATE_MESSAGE_ID                      0x1070          // Set the DAC sampling rate (plus other rate match params)
#define VM_SET_CODEC_RATE_MESSAGE_ID                    0x1071          // Set the codec sampling rate
#define VM_SET_TONE_RATE_MESSAGE_ID                     0x1072          // Set the tone sampling rate

#define PLAY_BACK_FINISHED_MSG                          0x1080
#define UNSUPPORTED_SAMPLING_RATES_MSG                  0x1090

.CONST  $AUDIO_IF_MASK                                  (0x00ff);       // Mask to select the audio i/f info
.CONST  $LOCAL_PLAYBACK_MASK                            (0x0100);       // Mask to select the local playback control bit
.CONST  $PCM_PLAYBACK_MASK                              (0x0200);       // Mask to select the pcm or coded local playback control bit
.CONST  $PCM_END_DETECTION_TIME_OUT                     (30000);        // minimum tone inactivity time before sending TONE END message

.CONST $AUDIO_LEFT_OUT_PORT                             ($cbuffer.WRITE_PORT_MASK + 0);
.CONST $AUDIO_RIGHT_OUT_PORT                            ($cbuffer.WRITE_PORT_MASK + 1);
    
#ifdef SUB_ENABLE
    // ** setup ports that are to be used **
    .CONST $AUDIO_ESCO_SUB_OUT_PORT                         ($cbuffer.WRITE_PORT_MASK | $cbuffer.FORCE_LITTLE_ENDIAN | $cbuffer.FORCE_NO_SATURATE | $cbuffer.FORCE_16BIT_WORD) + 2;
    // ( 80000C | 100000 | 002000 | 018000 ) + 2 = 91A00E
    .const $AUDIO_L2CAP_SUB_OUT_PORT                        ($cbuffer.WRITE_PORT_MASK + $cbuffer.FORCE_PCM_AUDIO + 3);
    .CONST $HEADER_L2CAP_SUB_OUT_PORT                       (($cbuffer.WRITE_PORT_MASK | $cbuffer.FORCE_LITTLE_ENDIAN | $cbuffer.FORCE_16BIT_WORD | $cbuffer.FORCE_NO_SIGN_EXTEND) + 3);

    .const $ESCO_SUB_AUDIO_PACKET_SIZE                         9;
    .const $L2CAP_SUB_AUDIO_PACKET_SIZE                       18;

    .CONST $L2CAP_SUB_ALIGNMENT_DELAY                       3020;       // 68.5 ms at 44.1 kHz; 62.9 ms at 48 kHz
    .CONST $ESCO_SUB_ALIGNMENT_DELAY                         650;       // 14.74 ms at 44.1 kHz; 13.54 ms at 48 kHz
    .CONST $L2CAP_FRAME_PROCESSING_RATE                     7500;       // frame process runs every 7.5 ms 
    .CONST $SUBWOOFER_ESCO_PORT_RATE                        3750;       // rate at which audio is written to subwoofer port in ESCO mode
    .CONST $L2CAP_PACKET_SIZE_BYTES                           50;
    .CONST $L2CAP_HEADER_SIZE_WORDS                            7;
#endif // SUB_ENABLE


// Port used for USB and CODEC inputs
.CONST $CON_IN_PORT                                     ($cbuffer.READ_PORT_MASK  + 0);

#ifdef ANALOGUE_ENABLE
// Ports used for analogue input from ADCs
.CONST $CON_IN_LEFT_PORT                                ($cbuffer.READ_PORT_MASK  + 0);
.CONST $CON_IN_RIGHT_PORT                               ($cbuffer.READ_PORT_MASK  + 1);
#endif

// Port used for tone inputs
.CONST $TONE_IN_PORT                                    (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO) + 3);

#if defined(SRA_TARGET_LATENCY) && (!defined(LATENCY_REPORTING))
   #error "TARGET LATENCY ONLY WORKS WHEN LATENCY REPORTING IS ENABLED"
#endif

#endif
