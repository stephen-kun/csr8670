// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCDEC_GLOBAL_VARIABLES_INCLUDED
#define SBCDEC_GLOBAL_VARIABLES_INCLUDED

#include "message.h"
#include "profiler.h"
#include "sbc_profiler_macros.h"

// *****************************************************************************
// MODULE:
//    $sbcdec.variables
//
// DESCRIPTION:
//    Global variables that are decoder specific. All variables and tables that
//    were used in static build have been moved to init_static_decoder.
//
// INPUTS:
//    N/A
//
// OUTPUTS:
//    N/A
//
// TRASHED REGISTERS:
//    N/A
//
// *****************************************************************************
.MODULE $sbcdec;
   .DATASEGMENT DM;

#ifndef SBC_WBS_ONLY
   .VAR/DM1      codec_struc;
#endif
   // decoder control variables


   #ifndef SBC_WBS_ONLY

   // initialise profiling and macros if enabled
   #ifdef PROFILE_SBCDEC

      .VAR $sbcdec.profile_frame_decode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_read_frame_header[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_frame_decode_wbs[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_read_frame_header_wbs[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_read_scale_factors[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_calc_bit_allocation[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_read_audio_samples[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_sample_reconstruction[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_joint_stereo_decode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR $sbcdec.profile_synthesis_subband_filter[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;

   #endif


   #ifdef DEBUG_SBCDEC
      .VAR/DM1      framecount = 0;
      .VAR/DM1      framecrc_errors = 0;
      .VAR/DM1      lostsync_errors = 0;
   #endif
   #endif

   // filterbank synthesis variables
   .CONST       SYNTHESIS_BUFFER_LENGTH   160;

#ifndef SBC_WBS_ONLY
   // synthesis subband filterbank matrix for (4x8) M = 4
   //DM1

   .VAR/DMCONST_WINDOWED16      synthesis_coefs_m4[48] =
                  0x5A82,  0x7AA5,  0x7D86,  0xA57D,  0x865A,  0x827A,  0x30FB,  0xC589,
                  0xBE51,  0x7641,  0xAFCF,  0x043B,  0x0000,  0x0000,  0x0000,  0x0000,
                  0x0000,  0x0000,  0xCF04,  0x3B76,  0x41AF,  0x89BE,  0x5130,  0xFBC5,
                  0xA57D,  0x865A,  0x827A,  0x5A82,  0x7AA5,  0x7D86,  0x89BE,  0x51CF,
                  0x043B,  0x30FB,  0xC576,  0x41AF,  0x8000,  0x0080,  0x0000,  0x8000,
                  0x0080,  0x0000,  0x89BE,  0x51CF,  0x043B,  0x30FB,  0xC576,  0x41AF;

#endif
   //DM1
   // synthesis subband filterbank matrix for (8x16) M = 8

   .VAR/DMCONST_WINDOWED16      synthesis_coefs_m8[192] =
                  0x5A82,  0x7AA5,  0x7D86,  0xA57D,  0x865A,  0x827A,  0x5A82,  0x7AA5,
                  0x7D86,  0xA57D,  0x865A,  0x827A,  0x471C,  0xED82,  0x75A1,  0x18F8,
                  0xB86A,  0x6D99,  0x9592,  0x67E7,  0x0748,  0x7D8A,  0x5FB8,  0xE313,
                  0x30FB,  0xC589,  0xBE51,  0x7641,  0xAFCF,  0x043B,  0xCF04,  0x3B76,
                  0x41AF,  0x89BE,  0x5130,  0xFBC5,  0x18F8,  0xB8B8,  0xE313,  0x6A6D,
                  0x9982,  0x75A1,  0x7D8A,  0x5F95,  0x9267,  0x471C,  0xEDE7,  0x0748,
                  0x0000,  0x0000,  0x0000,  0x0000,  0x0000,  0x0000,  0x0000,  0x0000,
                  0x0000,  0x0000,  0x0000,  0x0000,  0xE707,  0x4847,  0x1CED,  0x9592,
                  0x677D,  0x8A5F,  0x8275,  0xA16A,  0x6D99,  0xB8E3,  0x1318,  0xF8B8,
                  0xCF04,  0x3B76,  0x41AF,  0x89BE,  0x5130,  0xFBC5,  0x30FB,  0xC589,
                  0xBE51,  0x7641,  0xAFCF,  0x043B,  0xB8E3,  0x137D,  0x8A5F,  0xE707,
                  0x4895,  0x9267,  0x6A6D,  0x9918,  0xF8B8,  0x8275,  0xA147,  0x1CED,
                  0xA57D,  0x865A,  0x827A,  0x5A82,  0x7AA5,  0x7D86,  0xA57D,  0x865A,
                  0x827A,  0x5A82,  0x7AA5,  0x7D86,  0x9592,  0x6718,  0xF8B8,  0x7D8A,
                  0x5F47,  0x1CED,  0xB8E3,  0x1382,  0x75A1,  0xE707,  0x486A,  0x6D99,
                  0x89BE,  0x51CF,  0x043B,  0x30FB,  0xC576,  0x41AF,  0x7641,  0xAF30,
                  0xFBC5,  0xCF04,  0x3B89,  0xBE51,  0x8275,  0xA195,  0x9267,  0xB8E3,
                  0x13E7,  0x0748,  0x18F8,  0xB847,  0x1CED,  0x6A6D,  0x997D,  0x8A5F,
                  0x8000,  0x0080,  0x0000,  0x8000,  0x0080,  0x0000,  0x8000,  0x0080,
                  0x0000,  0x8000,  0x0080,  0x0000,  0x8275,  0xA195,  0x9267,  0xB8E3,
                  0x13E7,  0x0748,  0x18F8,  0xB847,  0x1CED,  0x6A6D,  0x997D,  0x8A5F,
                  0x89BE,  0x51CF,  0x043B,  0x30FB,  0xC576,  0x41AF,  0x7641,  0xAF30,
                  0xFBC5,  0xCF04,  0x3B89,  0xBE51,  0x9592,  0x6718,  0xF8B8,  0x7D8A,
                  0x5F47,  0x1CED,  0xB8E3,  0x1382,  0x75A1,  0xE707,  0x486A,  0x6D99;


   // Unsigned lookup of: (2^bits) / (2^bits - 1) * 2^23
   // The table is for bits values of 2-16.

   .VAR/DMCONST_WINDOWED16      levelrecip_coefs[23] =
                 0xAAAA,  0xAB92,  0x4925,  0x8888,  0x8984,  0x2108,  0x8208,  0x2181,
                 0x0204,  0x8080,  0x8180,  0x4020,  0x8020,  0x0880,  0x1002,  0x8008,
                 0x0180,  0x0400,  0x8002,  0x0080,  0x0100,  0x8000,  0x8000;


   // Lookup table to slightly speedup generating a bit mask

   .VAR/DMCONST_WINDOWED16      bitmask_lookup[26] =
                 0x0000,  0x0000,  0x0001,  0x0000,  0x0300,  0x0007,  0x0000,  0x0F00,
                 0x001F,  0x0000,  0x3F00,  0x007F,  0x0000,  0xFF00,  0x01FF,  0x0003,
                 0xFF00,  0x07FF,  0x000F,  0xFF00,  0x1FFF,  0x003F,  0xFF00,  0x7FFF,
                 0x00FF,  0xFF00;


.ENDMODULE;

#endif
