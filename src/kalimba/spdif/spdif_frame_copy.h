// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2012-2014        http://www.csr.com
// Part of ADK 3.5
//
// *****************************************************************************
#ifndef SPDIF_FRAME_COPY_HEADER_INCLUDED
#define SPDIF_FRAME_COPY_HEADER_INCLUDED

   // -- Define spdif "frame copy" structure fields
   .CONST $spdif.frame_copy.LEFT_INPUT_PORT_FIELD                        0;  // left input port
   .CONST $spdif.frame_copy.RIGHT_INPUT_PORT_FIELD                       1;  // right input port
   .CONST $spdif.frame_copy.SPDIF_INPUT_BUFFER_FIELD                     2;  // input buffer (interleaved from from spdif ports)
   .CONST $spdif.frame_copy.LEFT_PCM_BUFFER_FIELD                        3;  // spdif output left pcm cbuffer
   .CONST $spdif.frame_copy.RIGHT_PCM_BUFFER_FIELD                       4;  // spdif output right pcm cbuffer
   .CONST $spdif.frame_copy.CODED_BUFFER_FIELD                           5;  // spdif output coded data buffer
   .CONST $spdif.frame_copy.SUPPORTED_CODEC_TYPES_BITS_FIELD             6;  // bitmap of supported codecs
   .CONST $spdif.frame_copy.MODE_FIELD                                   7;  // input/output mode (return value)
   .CONST $spdif.frame_copy.RESET_NEEDED_FIELD                           8;  // flag showing whether reset is needed
   .CONST $spdif.frame_copy.READING_STATE_FIELD                          9;  // buffer reading state
   .CONST $spdif.frame_copy.PCM_COUNTER_FIELD                            10; // init phase pcm sample counter
   .CONST $spdif.frame_copy.CODEC_TYPE_FIELD                             11; // codec type detected from stream
   .CONST $spdif.frame_copy.STREAM_ALIGNMENT_FIELD                       12; // whether right stream is aligned or shifted (for coded data)
   .CONST $spdif.frame_copy.INVALID_BURST_COUNT_FIELD                    13; // counts number of invalid burst received
   .CONST $spdif.frame_copy.NULL_BURST_COUNT_FIELD                       14; // counts number of null burst received
   .CONST $spdif.frame_copy.PAUSE_BURST_COUNT_FIELD                      15; // counts number of pause burst received
   .CONST $spdif.frame_copy.PAY_LOAD_LENGTH_FIELD                        16; // payload length for the coded frame
   .CONST $spdif.frame_copy.STREAM_SWAPPED_FIELD                         17; // whether the stream L/R swapped  (for coded data only)
   .CONST $spdif.frame_copy.PAY_LOAD_LEFT_FIELD                          18; // coded payload length left to load
   .CONST $spdif.frame_copy.UNSYNC_COUNTER_FIELD                         19; // counting number of consecyutive words looking for sync
   .CONST $spdif.frame_copy.STUFFING_DATA_LENGTH_FIELD                   20; // length of stuffing data (for coded data only)
   .CONST $spdif.frame_copy.UNSUPPORTED_BURST_COUNT_FIELD                21; // counts number of pause burst received
   .CONST $spdif.frame_copy.CODEC_AUDIO_FRAME_SIZE_FIELD                 22; // spdif audio frame size
   .CONST $spdif.frame_copy.PCM_FADE_IN_INDEX_FIELD                      23; // fading index used when starting PCM playback
   .CONST $spdif.frame_copy.PREV_UNALIGNED_WORD_FIELD                    24; // previous left sample, valid for un-aligned stream
   .CONST $spdif.frame_copy.STREAM_INVALID_FIELD                         25; // whether the current stream is invalid
   .CONST $spdif.frame_copy.SAMPLING_FREQ_FIELD                          26; // sampling frequency of the input stream
   .CONST $spdif.frame_copy.INV_SAMPLING_FREQ_FIELD                      27; // inverse of sampling frequency received from fw
   .CONST $spdif.frame_copy.CHSTS_DATA_MODE_FIELD                        28; // channels status data or audio flag
   .CONST $spdif.frame_copy.CHSTS_SAMPLE_RATE_FIELD                      29; // channel status sampling frequency
   .CONST $spdif.frame_copy.INVALID_MESSAGE_PENDING_FIELD                30; // input buffer level (not used, for monitoring purpose)
   .CONST $spdif.frame_copy.NEW_CODEC_TYPE_FIELD                         31; // codec type detected from stream
   .CONST $spdif.frame_copy.NEW_CODEC_AUDIO_FRAME_SIZE_FIELD             32; // audio frame size detected from stream
   .CONST $spdif.frame_copy.INVALID_DELAY_COUNT_DOWN_FIELD               33; // audio frame size detected from stream
   .CONST $spdif.frame_copy.INVALID_MESSAGE_POSTPONE_TIME_FIELD          34; // amount of time to postpone invalid message from FW
   .CONST $spdif.frame_copy.ENABLE_EVENT_REPORT_FIELD                    35; // if NZ, event message will be sent to VM
   .CONST $spdif.frame_copy.CHSTS_FIRST_WORD_FIELD                       36; // channel status first 16-bit
   .CONST $spdif.frame_copy.LAST_REPORTED_WORDS_FIELD                    37; // last repoted data to VM (4 words)
   .CONST $spdif.frame_copy.FW_SAMPLING_FREQ_FIELD                       41; // sampling frequency received from fw
   #ifdef $spdif.DSP_SPDIF_RATE_MEASUREMENT
   .CONST $spdif.frame_copy.DSP_SAMPLING_FREQ_FIELD                      42; // sampling frequency decided by DSP
   .CONST $spdif.frame_copy.MEASURED_SAMPLING_FREQ_FIELD                 43; // exact sampling frequency measured by DSP (for external use)
   .CONST $spdif.frame_copy.RATE_DETECT_HIST_INDEX_FIELD                 44; // index to store last entry
   .CONST $spdif.frame_copy.RATE_DETECT_HIST_LAST_TIME_FIELD             45; // last read time
   .CONST $spdif.frame_copy.RATE_DETECT_HIST_FW_RATE_CHNAGED_FIELD       46; // fw rate changed

   .CONST $spdif.frame_copy.RATE_DETECT_HIST_FIELD                       47; // history of received amount of data and its arival time
   .CONST $spdif.frame_copy.STRUC_SIZE             (47+$spdif.RATE_DETECT_AMOUNT_HIST_LENGTH+$spdif.RATE_DETECT_RATE_HIST_LENGTH);
   #else
   .CONST $spdif.frame_copy.STRUC_SIZE                                   42;
   #endif
#endif //#ifdef SPDIF_FRAME_COPY_HEADER_INCLUDED
