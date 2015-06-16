// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBCENC_GLOBAL_VARIABLES_INCLUDED
#define SBCENC_GLOBAL_VARIABLES_INCLUDED

#include "message.h"
#include "codec_library.h"
#include "profiler.h"
#include "sbc_profiler_macros.h"

// *****************************************************************************
// MODULE:
//    $sbcenc.variables
//
// DESCRIPTION:
//    Global variables that are encoder specific. All variables and tables that
//    were used in static build have been moved to init_static_encoder.
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
.MODULE $sbcenc;
   .DATASEGMENT DM;

#ifndef SBC_WBS_ONLY
   .VAR/DM1      codec_struc;

   // initialise profiling and macros if enabled
   #ifdef PROFILE_SBCENC

      .VAR/DM1 $sbcenc.profile_frame_encode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_analysis_subband_filter[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_calc_scale_factors[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_joint_stereo_encode[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_write_frame_header[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_write_scale_factors[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_calc_bit_allocation[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_quantize_samples[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      .VAR/DM1 $sbcenc.profile_write_audio_samples[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;

   #endif
#endif

   #ifdef DEBUG_SBCENC
      .VAR/DM1      framecount = 0;
   #endif

   .CONST        ANALYSIS_BUFFER_LENGTH   80;

#ifndef SBC_WBS_ONLY
   // analysis subband filterbank matrix (4x8) for M = 4

   .VAR/DMCONST_WINDOWED16      analysis_coefs_m4[48] =
                  0x5A82,  0x7A76,  0x41AF,  0x7FFF,  0xFF76,  0x41AF,  0x5A82,  0x7A30,
                  0xFBC5,  0x0000,  0x00CF,  0x043B,  0xA57D,  0x8630,  0xFBC5,  0x7FFF,
                  0xFF30,  0xFBC5,  0xA57D,  0x8689,  0xBE51,  0x0000,  0x0076,  0x41AF,
                  0xA57D,  0x86CF,  0x043B,  0x7FFF,  0xFFCF,  0x043B,  0xA57D,  0x8676,
                  0x41AF,  0x0000,  0x0089,  0xBE51,  0x5A82,  0x7A89,  0xBE51,  0x7FFF,
                  0xFF89,  0xBE51,  0x5A82,  0x7ACF,  0x043B,  0x0000,  0x0030,  0xFBC5;

#endif
   // analysis subband filterbank matrix for (8x16) M = 8

   .VAR/DMCONST_WINDOWED16      analysis_coefs_m8[192] =
                  0x5A82,  0x7A6A,  0x6D99,  0x7641,  0xAF7D,  0x8A5F,  0x7FFF,  0xFF7D,
                  0x8A5F,  0x7641,  0xAF6A,  0x6D99,  0x5A82,  0x7A47,  0x1CED,  0x30FB,
                  0xC518,  0xF8B8,  0x0000,  0x00E7,  0x0748,  0xCF04,  0x3BB8,  0xE313,
                  0xA57D,  0x86E7,  0x0748,  0x30FB,  0xC56A,  0x6D99,  0x7FFF,  0xFF6A,
                  0x6D99,  0x30FB,  0xC5E7,  0x0748,  0xA57D,  0x8682,  0x75A1,  0x89BE,
                  0x51B8,  0xE313,  0x0000,  0x0047,  0x1CED,  0x7641,  0xAF7D,  0x8A5F,
                  0xA57D,  0x8682,  0x75A1,  0xCF04,  0x3B47,  0x1CED,  0x7FFF,  0xFF47,
                  0x1CED,  0xCF04,  0x3B82,  0x75A1,  0xA57D,  0x8618,  0xF8B8,  0x7641,
                  0xAF6A,  0x6D99,  0x0000,  0x0095,  0x9267,  0x89BE,  0x51E7,  0x0748,
                  0x5A82,  0x7AB8,  0xE313,  0x89BE,  0x5118,  0xF8B8,  0x7FFF,  0xFF18,
                  0xF8B8,  0x89BE,  0x51B8,  0xE313,  0x5A82,  0x7A6A,  0x6D99,  0xCF04,
                  0x3B82,  0x75A1,  0x0000,  0x007D,  0x8A5F,  0x30FB,  0xC595,  0x9267,
                  0x5A82,  0x7A47,  0x1CED,  0x89BE,  0x51E7,  0x0748,  0x7FFF,  0xFFE7,
                  0x0748,  0x89BE,  0x5147,  0x1CED,  0x5A82,  0x7A95,  0x9267,  0xCF04,
                  0x3B7D,  0x8A5F,  0x0000,  0x0082,  0x75A1,  0x30FB,  0xC56A,  0x6D99,
                  0xA57D,  0x867D,  0x8A5F,  0xCF04,  0x3BB8,  0xE313,  0x7FFF,  0xFFB8,
                  0xE313,  0xCF04,  0x3B7D,  0x8A5F,  0xA57D,  0x86E7,  0x0748,  0x7641,
                  0xAF95,  0x9267,  0x0000,  0x006A,  0x6D99,  0x89BE,  0x5118,  0xF8B8,
                  0xA57D,  0x8618,  0xF8B8,  0x30FB,  0xC595,  0x9267,  0x7FFF,  0xFF95,
                  0x9267,  0x30FB,  0xC518,  0xF8B8,  0xA57D,  0x867D,  0x8A5F,  0x89BE,
                  0x5147,  0x1CED,  0x0000,  0x00B8,  0xE313,  0x7641,  0xAF82,  0x75A1,
                  0x5A82,  0x7A95,  0x9267,  0x7641,  0xAF82,  0x75A1,  0x7FFF,  0xFF82,
                  0x75A1,  0x7641,  0xAF95,  0x9267,  0x5A82,  0x7AB8,  0xE313,  0x30FB,
                  0xC5E7,  0x0748,  0x0000,  0x0018,  0xF8B8,  0xCF04,  0x3B47,  0x1CED;


   // Lookup of: (2^bits - 1) * 2^7
   // The table is for bits values of 2-16.

   .VAR/DMCONST_WINDOWED16      level_coefs[23] =
                 0x0001,  0x8000,  0x0380,  0x0007,  0x8000,  0x0F80,  0x001F,  0x8000,
                 0x3F80,  0x007F,  0x8000,  0xFF80,  0x01FF,  0x8003,  0xFF80,  0x07FF,
                 0x800F,  0xFF80,  0x1FFF,  0x803F,  0xFF80,  0x7FFF,  0x8000;


.ENDMODULE;

#endif
