// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.com
// Part of ADK 3.5
//
// *****************************************************************************
#ifndef SPDIF_HEADER_INCLUDED
#define SPDIF_HEADER_INCLUDED

   // defining spdif processing states
   .CONST $spdif.state.LOOKING_FOR_SYNC_INFO                       0; // looking for sync info in the stream
   .CONST $spdif.state.PCM_MUTE                                    1; // pcm mute
   .CONST $spdif.state.PCM_UNMUTE                                  2; // pcm play
   .CONST $spdif.state.PCM_FADE_IN                                 3; // pcm play
   .CONST $spdif.state.LOADING_CODED_DATA                          4; // coded data is being loaded
   .CONST $spdif.state.IEC_61937_Pa_Pz                             5; // unaligned stream read payload length
   .CONST $spdif.state.READING_STUFFING_DATA                       6; // reading and discarding stuffing data


   // define alignment constants
   .CONST $spdif.STREAM_ALIGNMENT_NORMAL                           0; // left and right are aligned
   .CONST $spdif.STREAM_ALIGNMENT_SHIFTED                          1; // right is lagging by one word

   // define decoder types, not necessarily all can be supported
   .CONST $spdif.DECODER_TYPE_PCM_MUTE                             0; // either unknown or unsupported
   .CONST $spdif.DECODER_TYPE_PCM                                  1; // raw pcm is being received
   .CONST $spdif.DECODER_TYPE_AC3                                  2; // Dolby digital AC-3
   .CONST $spdif.DECODER_TYPE_MPEG1_LAYER1                         3; // MPEG1
   .CONST $spdif.DECODER_TYPE_MPEG1_LAYER23                        4; // MP3
   .CONST $spdif.DECODER_TYPE_DTS1                                 5; // DTS1
   .CONST $spdif.DECODER_TYPE_DTS2                                 6; // DTS2
   .CONST $spdif.DECODER_TYPE_DTS3                                 7; // DTS3
   .CONST $spdif.DECODER_TYPE_EAC3                                 8; // Dolby digital E-AC3
   .CONST $spdif.DECODER_TYPE_MPEG2_AAC                            9; // MPEG-2 AAC

   // IEC-61937 data types, not all supported
   .CONST $spdif.IEC_61937_DATA_TYPE_NULL                         0x00;
   .CONST $spdif.IEC_61937_DATA_TYPE_AC3                          0x01;
   .CONST $spdif.IEC_61937_DATA_TYPE_PAUSE                        0x03;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG1_LAYER1                 0x04;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG1_LAYER23                0x05;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG2_EXTENTION              0x06;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG2_AAC                    0x07;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG2_LAYER1_LSF             0x08;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG2_LAYER2_LSF             0x09;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG2_LAYER3_LSF             0x0A;
   .CONST $spdif.IEC_61937_DATA_TYPE_DTS1                         0x0B;
   .CONST $spdif.IEC_61937_DATA_TYPE_DTS2                         0x0C;
   .CONST $spdif.IEC_61937_DATA_TYPE_DTS3                         0x0D;
   .CONST $spdif.IEC_61937_DATA_TYPE_ATRAC                        0x0E;
   .CONST $spdif.IEC_61937_DATA_TYPE_ATRAC3                       0x0F;
   .CONST $spdif.IEC_61937_DATA_TYPE_ATRACX                       0x10;
   .CONST $spdif.IEC_61937_DATA_TYPE_DTSHD                        0x11;
   .CONST $spdif.IEC_61937_DATA_TYPE_WMAPRO                       0x12;
   .CONST $spdif.IEC_61937_DATA_TYPE_MPEG2_AAC_LSF                0x13;
   .CONST $spdif.IEC_61937_DATA_TYPE_EAC3                         0x15;
   .CONST $spdif.IEC_61937_DATA_TYPE_TRUEHD                       0x16;

   // macro to enable data type
   #define $spdif.DATA_TYPE_SUPPORT(x)    (1<<(x))

   // audio frame length for some IEC-61937 data types
   .CONST $spdif.AC3_AUDIO_FRAME_LENGTH                           1536;
   .CONST $spdif.MPEG1_LAYER23_AUDIO_FRAME_LENGTH                 1152;
   .CONST $spdif.DTS1_AUDIO_FRAME_LENGTH                          512;
   .CONST $spdif.DTS2_AUDIO_FRAME_LENGTH                          1024;
   .CONST $spdif.DTS3_AUDIO_FRAME_LENGTH                          2048;
   .CONST $spdif.MPEG2_AAC_FRAME_LENGTH                           1024;

   // IEC_61937 preambles
   .CONST $spdif.IEC_61937_Pz                                      0x0000;
   .CONST $spdif.IEC_61937_Pa                                      0xf872;
   .CONST $spdif.IEC_61937_Pb                                      0x4e1f;

   // some empirical constants
   .CONST $spdif.MAX_COPY_PROCESS_SAMPLES                          2048;   // maximum number of samples to precess by copy sub-lib each run
   .CONST $spdif.MAX_UNSYNC_SAMPLES                                10;     // maximum number of sample to stay un-synced before muting output
   .CONST $spdif.PCM_SWITCH_FADE_IN_SAMPLES                        256;    // number of samples to (linearly) fade in over when starting pcm mode
   .CONST $spdif.INVALID_MESSAGE_POSTPONE_TIME_MS                  2000;   // time to postpone handling of received invalid message
   .CONST $spdif.INPUT_BUFFER_MIN_SPACE                            144;    // minimum space that shall be available in the buffer
   .CONST $spdif.MIN_PCM_ACTIVITY_SAMPLES                          2048;   // minimum number of samples before unmuting pcm stream
   .CONST $spdif.MIN_INPUT_DATA_SUCCESS                            128;    // minimum amount of data for returning success
   .CONST $spdif.MIN_OUTPUT_SPACE_SUCCESS                          128;    // minimum amount of space for returning success
   .CONST $spdif.OUTPUT_INTERFACE_FADE_OUT_TIME_MS                 5;      // time to wait for fade in/out take effect

   // define bit fields on reasons for invalid streams
   .CONST $spdif.STREAM_INVALID_FROM_FW                            1;  // invalid due to message from fw
   .CONST $spdif.STREAM_INVALID_NO_START                           2;  // no start message yet have received
   .CONST $spdif.STREAM_INVALID_SWITCHING                          4;  // invalid due to output port switching

   // same meaning as $codec output modes
   .CONST $spdif.SUCCESS                                          0;
   .CONST $spdif.NOT_ENOUGH_INPUT_DATA                            1;
   .CONST $spdif.NOT_ENOUGH_OUTPUT_SPACE                          2;

   #ifdef DEBUG_ON
      #include "profiler.h"
      #define PROFILER_START_SPDIF(addr)  \
         r0 = addr;                        \
         call $profiler.start;
      #define PROFILER_STOP_SPDIF(addr)   \
         r0 = addr;                        \
         call $profiler.stop;
   #else
      #define PROFILER_START_SPDIF(addr)
      #define PROFILER_STOP_SPDIF(addr)
   #endif

   // define output interface processing state(only used with SPDIF_OUTPUT_INTERFACE_CONTROL defined)
   .CONST $spdif.STATE_IDLE                                       0;  // Idle, no flow of data
   .CONST $spdif.STATE_WAIT_OUTPUT_INTERFACE_RATE                 1;  // waiting for rate configuration to finish
   .CONST $spdif.STATE_WAIT_OUTPUT_INTERFACE_ACTIVATE             2;  // waiting for activation to finish
   .CONST $spdif.STATE_FULL_ACTIVE                                3;  // fully active
   .CONST $spdif.STATE_OUTPUT_INTERFACE_FADING_OUT                4;  // in fading out period
   .CONST $spdif.STATE_WAIT_OUTPUT_INTERFACE_DEACTIVATE           5;  // waiting for deactivation to finish
   .CONST $spdif.STATE_WAIT_OUTPUT_INTERFACE_MUTE                 6;  // waiting for mute to finish
   .CONST $spdif.STATE_WAIT_OUTPUT_INTERFACE_UNMUTE               7;  // waiting unmute to finish

   // define output port types(only used with SPDIF_OUTPUT_INTERFACE_CONTROL defined)
   .CONST $spdif.OUTPUT_INTERFACE_TYPE_NONE                            0;   // no audio output port control
   .CONST $spdif.OUTPUT_INTERFACE_TYPE_DAC                             1;   // output to internal DACs
   .CONST $spdif.OUTPUT_INTERFACE_TYPE_I2S                             2;   // output to I2S interface
   .CONST $spdif.OUTPUT_INTERFACE_TYPE_SPDIF                           3;   // output to spdif interface

   // define bit filed constant for output interface state (only used with SPDIF_OUTPUT_INTERFACE_CONTROL defined)
   .CONST $spdif.OUTPUT_INTERFACE_STATE_ACTIVE                    1;  // Interface are active
   .CONST $spdif.OUTPUT_INTERFACE_STATE_UNMUTE                    2;  // Interface aren't mute
   .CONST $spdif.OUTPUT_INTERFACE_STATE_FADING                    4;  // Interface are in fading out phase
   .CONST $spdif.OUTPUT_INTERFACE_STATE_FADING_DONE               8;  // Fading out has been done for the interface

   // command args for latency measurement                            
   .CONST $spdif.latency_measurment.RESET                         0;   // reset the latency measurement process
   .CONST $spdif.latency_measurment.TAG_NEW_PACKET_ARRIVAL        1;   // update history for coded input
   .CONST $spdif.latency_measurment.UPDATE_LATENCY                2;   // update latecny

   // $spdif.DSP_SPDIF_RATE_CHECK -> to check validity of input rate
   // $spdif.DSP_SPDIF_RATE_MEASUREMENT -> just to measure the rate
   // For CSR8760 chip this is mandatory
   #define $spdif.DSP_SPDIF_RATE_CHECK

   // enable measurment if rate check is enabled
   #ifdef $spdif.DSP_SPDIF_RATE_CHECK
   #ifndef $spdif.DSP_SPDIF_RATE_MEASUREMENT
   #define $spdif.DSP_SPDIF_RATE_MEASUREMENT
   #endif
   #endif

   #ifdef $spdif.DSP_SPDIF_RATE_MEASUREMENT
       // DSP Rate measurement

       // history of amount of new data seen in input port
       // the equivalent time length will be the reading
       // period (normally 1ms) times history length. Increasing
       // this value would achieve more accurate measurement
       // but would need more memory and computations, it also
       // increases the detection lag when switching from one
       // rate to another rate
      .CONST $spdif.RATE_DETECT_AMOUNT_HIST_LENGTH 40;

      // history of detected rates, each time the rate
      // detect is called it would measure the input
      // rate, and keeps a short history of last detected
      // rates. It uses a hysteresis mechanism to switch
      // to/from a rate.
      .CONST $spdif.RATE_DETECT_RATE_HIST_LENGTH   15;
      .CONST $spdif.RATE_DETECT_VALID_THRESHOLD    11;   // to switch to new valid rate
      .CONST $spdif.RATE_DETECT_INVALID_THRESHOLD   6;   // to switch from valid rate to invalid
                                                         // sum of two thresholds must be greater than hist length

       // the accuracy that is needed when measuring the rate
       // the using application shall be able to cope with
       // twice of this amount of mismatch
      .CONST $spdif.RATE_DETECT_ACCURACY        0.005;   // 0.5% tolerance + 0.5% jitter

   #endif
#endif // #ifndef SPDIF_HEADER_INCLUDED
