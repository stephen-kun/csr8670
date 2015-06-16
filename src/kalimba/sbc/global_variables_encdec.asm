// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef SBC_GLOBAL_VARIABLES_INCLUDED
#define SBC_GLOBAL_VARIABLES_INCLUDED

// *****************************************************************************
// MODULE:
//    $sbc.variables
//
// DESCRIPTION:
//    Global variables shared between encoder and decoder. The variables and
//    tables that were used in static builds have moved to init_static_common.
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
.MODULE $sbc;
   .DATASEGMENT DM;

   // header constants
   .CONST        SYNC_WORD         0x9C;
   .CONST        CRC_GENPOLY       0b00011101;

   .CONST        FS_16000HZ        0;
   .CONST        FS_32000HZ        1;
   .CONST        FS_44100HZ        2;
   .CONST        FS_48000HZ        3;

   .CONST        MONO              0;
   .CONST        DUAL_CHANNEL      1;
   .CONST        STEREO            2;
   .CONST        JOINT_STEREO      3;

   .CONST        LOUDNESS          0;
   .CONST        SNR               1;


   // header variables
#ifndef SBC_USE_EXTERNAL_MEMORY
   .VAR/DM1      framecrc;
   .VAR/DM1      crc_checksum;
   .VAR/DM1      sampling_freq;
   .VAR/DM1      nrof_blocks;
   .VAR/DM1      channel_mode;
   .VAR/DM1      nrof_channels;
   .VAR/DM1      allocation_method;
   .VAR/DM1      nrof_subbands;
   .VAR/DM1      bitpool;
   .VAR/DM1      force_word_align;
#ifndef SBC_WBS_ONLY
   .VAR/DM1      join[8];
#endif
#endif


#ifndef SBC_WBS_ONLY
   // subband prototype window for M = 4

   .VAR/DMCONST_WINDOWED16      win_coefs_m4[60] =
                  0x0000,  0x0000,  0x232A,  0x0061,  0xC600,  0xB328,  0x00FB,  0x7A00,
                  0xFF12,  0x007A,  0x47FF,  0x3774,  0x02CB,  0x3F05,  0x3B75,  0x0764,
                  0x6708,  0x3DDD,  0x069F,  0xDC01,  0x91E5,  0xF89F,  0x24EC,  0x1F5E,
                  0x22B6,  0x3E31,  0xEAB9,  0x3F23,  0x9548,  0x25E5,  0x4B58,  0x4048,
                  0x25E5,  0x3F23,  0x9531,  0xEAB9,  0xDD49,  0xC2EC,  0x1F5E,  0xF89F,
                  0x2401,  0x91E5,  0x069F,  0xDC08,  0x3DDD,  0x0764,  0x6705,  0x3B75,
                  0xFD34,  0xC1FF,  0x3774,  0x007A,  0x4700,  0xFF12,  0x00FB,  0x7A00,
                  0xB328,  0x0061,  0xC600,  0x232A;

#endif
   // subband prototype window for M = 8

   .VAR/DMCONST_WINDOWED16      win_coefs_m8[120] =
                  0x0000,  0x0000,  0x1486,  0x002C,  0xFE00,  0x48B2,  0x006B,  0xFE00,
                  0x956A,  0x00C1,  0x8400,  0xE9CC,  0x0107,  0xB201,  0x13BD,  0x0105,
                  0x6E00,  0xD3E3,  0x0076,  0x3FFF,  0xE890,  0xFF27,  0xC4FE,  0x359E,
                  0x02E5,  0xCD04,  0x1C6E,  0x055A,  0xCF06,  0x86CE,  0x0780,  0x8908,
                  0x24A4,  0x084E,  0x1907,  0xD7D1,  0x069F,  0xB404,  0x88FB,  0x017F,
                  0x44FD,  0x7BAE,  0xF881,  0x0DF2,  0xA1BA,  0xEBFE,  0x58E4,  0xC4A2,
                  0x22D0,  0xC22A,  0x7CFA,  0x31F5,  0x6738,  0xEEC6,  0x3F1C,  0x8844,
                  0x3B3C,  0x4810,  0xD84A,  0x708A,  0x4B3D,  0xB24A,  0x708A,  0x4810,
                  0xD844,  0x3B3C,  0x3F1C,  0x8838,  0xEEC6,  0x31F5,  0x672A,  0x7CFA,
                  0xDD2F,  0x3EE4,  0xC4A2,  0xEBFE,  0x58F2,  0xA1BA,  0xF881,  0x0DFD,
                  0x7BAE,  0x017F,  0x4404,  0x88FB,  0x069F,  0xB407,  0xD7D1,  0x084E,
                  0x1908,  0x24A4,  0x0780,  0x8906,  0x86CE,  0x055A,  0xCF04,  0x1C6E,
                  0xFD1A,  0x33FE,  0x359E,  0xFF27,  0xC4FF,  0xE890,  0x0076,  0x3F00,
                  0xD3E3,  0x0105,  0x6E01,  0x13BD,  0x0107,  0xB200,  0xE9CC,  0x00C1,
                  0x8400,  0x956A,  0x006B,  0xFE00,  0x48B2,  0x002C,  0xFE00,  0x1486;


   // Loudness bit allocation offset table for M = 4
   //
   //   offset4   sb=0   sb=1   sb=2   sb=3
   //  fs=16000    -1      0      0      0
   //  fs=32000    -2      0      0      1
   //  fs=44100    -2      0      0      1
   //  fs=48000    -2      0      0      1

   .BLOCK/DMCONST_WINDOWED16 loudness_offset;

#ifndef SBC_WBS_ONLY

      .VAR       loudness_offset_m4[16] =

                 -1,    0,    0,    0,
                 -2,    0,    0,    1,
                 -2,    0,    0,    1,
                 -2,    0,    0,    1;
#endif
   // Loudness bit allocation offset table for M = 8
   //
   //  offset8     sb=0  sb=1  sb=2  sb=3  sb=4  sb=5  sb=6  sb=7
   //  fs=16000     -2,    0,    0,    0,    0,    0,    0,    1,
   //  fs=32000     -3,    0,    0,    0,    0,    0,    1,    2,
   //  fs=44100     -4,    0,    0,    0,    0,    0,    1,    2,
   //  fs=48000     -4,    0,    0,    0,    0,    0,    1,    2);

   .VAR          loudness_offset_m8[32] =

                 -2,    0,    0,    0,    0,    0,    0,    1,
                 -3,    0,    0,    0,    0,    0,    1,    2,
                 -4,    0,    0,    0,    0,    0,    1,    2,
                 -4,    0,    0,    0,    0,    0,    1,    2;

   .ENDBLOCK;


.ENDMODULE;

#endif
