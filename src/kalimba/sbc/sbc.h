// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBC_HEADER_INCLUDED
#define SBC_HEADER_INCLUDED

#if defined(PATCH_LIBS)
   #include "patch_library.h"
#endif

#ifdef SBC_WBS_ONLY
   // WBS Configuration
   .CONST        $sbc.WBS_NROF_SUBBANDS           8;
   .CONST        $sbc.WBS_NROF_BLOCKS             15;
   .CONST        $sbc.WBS_NROF_CHANNELS           1;
   .CONST        $sbc.WBS_NROF_BITPOOL            26;
   .CONST        $sbc.WBS_SAMPLING_FREQ           0;
   .CONST        $sbc.WBS_CHANNEL_MODE            0;
   .CONST        $sbc.WBS_ALLOCATION_METHOD       0;
#endif

   // general sbc constants
   .CONST        $sbc.MAX_AUDIO_FRAME_SIZE_IN_WORDS   128;
   .CONST        $sbc.MAX_SBC_FRAME_SIZE_IN_BYTES     512;
   .CONST        $sbc.MIN_SBC_FRAME_SIZE_IN_BYTES     20;
   .CONST        $sbc.CAN_IDLE                        0;
   .CONST        $sbc.DONT_IDLE                       1;
   .CONST        $sbc.WBS_SBC_FRAME_LENGTH_IN_BYTES   62;
   .CONST        $sbc.WBS_SBC_FRAME_LENGTH_IN_WORDS   31;
   .CONST        $sbc.SBC_NOT_SYNC                    99; // value must >16


   // structure sizes for saving and restoring state
   .CONST        $sbcdec.STATE_STRUC_SIZE             326;
   .CONST        $sbcend.STATE_STRUC_SIZE             172;


// encoder                                                         offset       Init Reqd?      Info
    .CONST       $sbc.mem.AUDIO_SAMPLE_JS_FIELD                    0;           // Y            ptr to 256 words
    .CONST       $sbc.mem.ANALYSIS_COEFS_M8_FIELD                  1;           // Y            ptr to 128 words
    .CONST       $sbc.mem.ANALYSIS_COEFS_M4_FIELD                  2;           // Y            ptr to 32 words
    .CONST       $sbc.mem.ANALYSIS_XCH1_FIELD                      3;           // Y            ptr to ANALYSIS_BUFFER_LENGTH words
    .CONST       $sbc.mem.ANALYSIS_XCH2_FIELD                      4;           // Y            ptr to ANALYSIS_BUFFER_LENGTH words
    .CONST       $sbc.mem.ANALYSIS_Y_FIELD                         5;           // Y            ptr to 16 words
    .CONST       $sbc.mem.LEVEL_COEFS_FIELD                        6;           // Y            ptr to 15 words
    .CONST       $sbc.mem.PRE_POST_PROC_STRUC_FIELD                7;           // Opt          ptr to func to handle any post processing
    .CONST       $sbc.mem.ENC_SETTING_NROF_SUBBANDS_FIELD          8;           // Y            No of sub bands
    .CONST       $sbc.mem.ENC_SETTING_NROF_BLOCKS_FIELD            9;           // Y            No of blocks
    .CONST       $sbc.mem.ENC_SETTING_SAMPLING_FREQ_FIELD          10;          // Y            Sampling frequency (0 - 3)
    .CONST       $sbc.mem.ENC_SETTING_CHANNEL_MODE_FIELD           11;          // Y            Channel mode (0- 3)
    .CONST       $sbc.mem.ENC_SETTING_ALLOCATION_METHOD_FIELD      12;          // Y            Allocation method (0, 1)
    .CONST       $sbc.mem.ENC_SETTING_BITPOOL_FIELD                13;          // Y            Bitpool size (sugg 50)
    .CONST       $sbc.mem.ENC_SETTING_FORCE_WORD_ALIGN_FIELD       14;          // Opt          Force to word aligned data len
    .CONST       $sbc.mem.PUT_NEXTWORD_FIELD                       15;          // N            Used Internally
    .CONST       $sbc.mem.PUT_BITPOS_FIELD                         16;          // Y            Ptr to func to output SBC bits
    .CONST       $sbc.mem.ANALYSIS_XCH1PTR_FIELD                   17;          // N            Used internally
    .CONST       $sbc.mem.ANALYSIS_XCH2PTR_FIELD                   18;          // N            Used internally
    .CONST       $sbc.mem.WBS_SEND_FRAME_COUNTER_FIELD             19;          // N            Used internally
// common
    .CONST       $sbc.mem.AUDIO_SAMPLE_FIELD                       20;          // Y            ptr to 256 words
    .CONST       $sbc.mem.WIN_COEFS_M8_FIELD                       21;          // Y            ptr to 80 words
    .CONST       $sbc.mem.WIN_COEFS_M4_FIELD                       22;          // Y            ptr to 40 words
    .CONST       $sbc.mem.LOUDNESS_OFFSET_FIELD                    23;          // Y            ptr to 48 words
    .CONST       $sbc.mem.SCALE_FACTOR_FIELD                       24;          // Y            ptr to 16 words
    .CONST       $sbc.mem.SCALE_FACTOR_JS_FIELD                    25;          // Y            ptr to 16 words
    .CONST       $sbc.mem.BITNEED_FIELD                            26;          // Y            ptr to 16 words
    .CONST       $sbc.mem.BITS_FIELD                               27;          // Y            ptr to 16 words
    .CONST       $sbc.mem.SAMPLING_FREQ_FIELD                      28;          // N            Internal
    .CONST       $sbc.mem.NROF_BLOCKS_FIELD                        29;          // N            Internal
    .CONST       $sbc.mem.CHANNEL_MODE_FIELD                       30;          // N            Internal
    .CONST       $sbc.mem.NROF_CHANNELS_FIELD                      31;          // N            Internal
    .CONST       $sbc.mem.ALLOCATION_METHOD_FIELD                  32;          // N            Internal
    .CONST       $sbc.mem.NROF_SUBBANDS_FIELD                      33;          // N            Internal
    .CONST       $sbc.mem.BITPOOL_FIELD                            34;          // N            Internal
    .CONST       $sbc.mem.FRAMECRC_FIELD                           35;          // N            Internal
    .CONST       $sbc.mem.CRC_CHECKSUM_FIELD                       36;          // N            Internal
    .CONST       $sbc.mem.FORCE_WORD_ALIGN_FIELD                   37;          // N            Internal
    .CONST       $sbc.mem.JOIN_FIELD                               38;          // N            Internal
    .CONST       $sbc.mem.JOIN_1_FIELD                             39;          // N            Internal
    .CONST       $sbc.mem.JOIN_2_FIELD                             40;          // N            Internal
    .CONST       $sbc.mem.JOIN_3_FIELD                             41;          // N            Internal
    .CONST       $sbc.mem.JOIN_4_FIELD                             42;          // N            Internal
    .CONST       $sbc.mem.JOIN_5_FIELD                             43;          // N            Internal
    .CONST       $sbc.mem.JOIN_6_FIELD                             44;          // N            Internal
    .CONST       $sbc.mem.JOIN_7_FIELD                             45;          // N            Internal
    .CONST       $sbcenc.mem.STRUC_SIZE                            46;
// decoder
    .CONST       $sbc.mem.SYNTHESIS_COEFS_M8_FIELD                 46;          // Y            ptr to 128 words
    .CONST       $sbc.mem.SYNTHESIS_COEFS_M4_FIELD                 47;          // Y            ptr to 32 words
    .CONST       $sbc.mem.LEVELRECIP_COEFS_FIELD                   48;          // Y            ptr to 15 words
    .CONST       $sbc.mem.BITMASK_LOOKUP_FIELD                     49;          // Y            ptr to 17 words
    .CONST       $sbc.mem.SYNTHESIS_VCH1_FIELD                     50;          // Y            ptr to SYNTHESIS_BUFFER_LENGTH words
    .CONST       $sbc.mem.SYNTHESIS_VCH2_FIELD                     51;          // Y            ptr to SYNTHESIS_BUFFER_LENGTH words
    .CONST       $sbc.mem.CONVERT_TO_MONO_FIELD                    52;          // N            Unused
    .CONST       $sbc.mem.FRAME_UNDERFLOW_FIELD                    53;          // Opt          Forces a buffer underflow
    .CONST       $sbc.mem.FRAME_CORRUPT_FIELD                      54;          // N            Internal
    .CONST       $sbc.mem.NUM_BYTES_AVAILABLE_FIELD                55;          // N            Internal
    .CONST       $sbc.mem.WBS_SBC_FRAME_OK_FIELD                   56;          // N            Unused
    .CONST       $sbc.mem.CUR_FRAME_LENGTH_FIELD                   57;          // N            Internal
    .CONST       $sbc.mem.RETURN_ON_CORRUPT_FRAME_FIELD            58;          // Y            True/False
    .CONST       $sbc.mem.GET_BITPOS_FIELD                         59;          // Y            Ptr to func to retrieve next bit
    .CONST       $sbc.mem.SYNTHESIS_VCH1PTR_FIELD                  60;          // N            Internal
    .CONST       $sbc.mem.SYNTHESIS_VCH2PTR_FIELD                  61;          // N            Internal
    .CONST       $sbc.mem.WBS_FRAME_BUFFER_PTR_FIELD               62;          // Y            For WBS only, ptr to WBS_ENCODED_FRAME_SIZE_B words
    .CONST       $sbc.mem.WBS_SYNC_FIELD                           63;          // N            For WBS only, internal
    .CONST       $sbc.mem.WBS_BYTES_IN_FRAME_BUFFER_FIELD          64;          // N            For WBS only, internal
    .CONST       $sbc.mem.WBS_STICKY_BFI_FIELD                     65;          // N            For WBS only, internal
    .CONST       $sbc.mem.WBS_PAYLOAD_ALIGN_FIELD                  66;          // N            For WBS only, internal
    .CONST       $sbc.mem.TIMESTAMP_T1_FIELD                       67;          // N            For WBS only, internal
    .CONST       $sbc.mem.TIMESTAMP_T2_FIELD                       68;          // N            For WBS only, internal


    .CONST       $sbc.mem.STRUC_SIZE                               69;

#endif
