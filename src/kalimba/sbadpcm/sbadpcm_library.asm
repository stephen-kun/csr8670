// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

// *****************************************************************************
// FILE: sbadpcm_library.asm - 'sbadpcm' Library Master Assemly Code
// *****************************************************************************

#ifndef _SBADPCM_LIBRARY
#define _SBADPCM_LIBRARY

#include "stack.h"
#include "sbadpcm.h"
#include "frame_codec.h"

// *****************************************************************************
// LIBRARY:
//    $M.Adpcm
//
// DESCRIPTION:
//    Kalimba DSP implementation of ITU G722 SBADPCM in library format
//
// MODIFICATIONS:
//
// CPU USAGE:
//    D-MEMORY: xxx
//    P-MEMORY: xxx
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.SBAdpcm
//
// DESCRIPTION:
//    Contain the library version
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm;
#ifdef BLD_PRIVATE
   .PRIVATE;
#endif
   .DATASEGMENT DM;
   .CODESEGMENT SBADPCM_PM;

   // -- adpcm library version  --
   .VAR Version = SBADPCM_LIBRARY_VERSION;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.memory
//
// DESCRIPTION:
//    Data module to contiain constant symbols used by the entire codec
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.memory;

   .DATASEGMENT DM;


   .VAR/DM1 QQ4IL4[16] =
      0,-5236736,-3301376,-2295808,-1609728,-1085440,-661504,
      -307200,5236736,3301376,2295808,1609728,1085440,661504,
      307200,0; // q.23 - ril to signed qq4 table (via il4/sil)

   .VAR/DM1 WLIL4[16] =
      -60,3042,1198,538,334,172,58,-30,
      3042,1198,538,334,172,58,-30,-60;

   .VAR/DM1 ILB[32] =
      2048,2093,2139,2186,2233,2282,2332,2383,
      2435,2489,2543,2599,2656,2714,2774,2834,
      2896,2960,3025,3091,3158,3228,3298,3371,
      3444,3520,3597,3676,3756,3838,3922,4008;


   .VAR/DM1 QQ2IH2[4] =
      -1896448,-413696,1896448,413696;

   .VAR/DM1 WHIH2[4] =
      798, -214, 798, -214;


   // list of constants for the predictor
   .VAR/DM2 PredConst[] =
      -23, 128*256, -7, 128*256, -1, 32512*256, -12288*256, 12288*256, -1, 192*256, 32640*256, 15360*256;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.encode.memory
//
// DESCRIPTION:
//    Data module to contiain constant symbols used only by the encoder
//
// NOTES:
// *****************************************************************************

.MODULE $M.SBAdpcm.encode.memory;
   .VAR/DM1 Q6[29] =
      71680,147456,225280,307200,389120,477184,565248,
      661504,757760,864256,968704,1085440,1202176,1331200,
      1462272,1609728,1757184,1925120,2095104,2295808,2496512,
      2742272,2985984,3301376,3614720,4055040,4495360,5236736,5978112; // q.20

   .VAR/DM1 ILpILn[60] =
      61,60,59,58,57,56,55,54,
      53,52,51,50,49,48,47,46,
      45,44,43,42,41,40,39,38,
      37,36,35,34,33,32,
      63,62,31,30,29,28,27,26,
      25,24,23,22,21,20,19,18,
      17,16,15,14,13,12,11,10,
      9, 8, 7, 6, 5, 4; // integer

   .VAR/DM1 Q2[1] =
      1155072; // q.20

   .VAR/DM1 IHpIHn[4] =
      3,2,
      1,0; // integer

   // constants used by the quanize function for lowband encoder
   .VAR/DM2 QuantConstLSBEnc[] = 29, 30, -2, 127, -7, 18432, -6, 31, -11, 8, 2;

   .VAR/DM2 QuantConstHSBEnc[] = 1, 2, 0, 127, -7, 22528, -6, 31, -11, 10, 2;

   // lists of tables
   .VAR/DM1 QuantTablesLSBEnc[] =
      &Q6, &ILpILn-2, &$M.SBAdpcm.memory.QQ4IL4, &$M.SBAdpcm.memory.WLIL4, &$M.SBAdpcm.memory.ILB;

   .VAR/DM1 QuantTablesHSBEnc[] =
      &Q2, &IHpIHn-2, &$M.SBAdpcm.memory.QQ2IH2, &$M.SBAdpcm.memory.WHIH2, &$M.SBAdpcm.memory.ILB;


.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.decode.memory
//
// DESCRIPTION:
//    Data module to contiain constant symbols used only by the decoder
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.decode.memory;
   // constants used by the quanize function for highband
   .VAR/DM2 QuantConstHSBDec[] =       0, 127, -7, 22528, -6, 31, -11, 10, 2;

   .VAR/DM1 QuantTablesHSBDec[] =
      &$M.SBAdpcm.memory.QQ2IH2, &$M.SBAdpcm.memory.WHIH2, &$M.SBAdpcm.memory.ILB;

.ENDMODULE;



// Mode tables

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Mode.Encode
//
// DESCRIPTION:
//    mode table for encoder
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.Mode.Encode;
   .DATASEGMENT DM;
   .VAR $sbadpcm.mode.encode[$sbadpcm.MODE_TABLE.STRUCT_SIZE] =
      $sbadpcm.flags.MODE_ENCODE,                      // FLAGS_FIELD
      &$M.SBAdpcm.encode.memory.QuantConstLSBEnc,      // MODE_TABLE_PTRCONST_LSB
      &$M.SBAdpcm.encode.memory.QuantTablesLSBEnc,     // MODE_TABLE_PTRTABLES_LSB
      &$M.SBAdpcm.encode.memory.QuantConstHSBEnc,      // MODE_TABLE_PTRCONST_LSB
      &$M.SBAdpcm.encode.memory.QuantTablesHSBEnc;     // MODE_TABLE_PTRTABLES_LSB
.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Mode.Decode6Bit
//
// DESCRIPTION:
//    mode table for 6-bit decoder
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.Mode.Decode6Bit;
   .DATASEGMENT DM;

   // constants used by the quanize function for lowband decoder
   .VAR/DM2 QuantConstLSBDec6Bit[] = -2, -2, 127, -7, 18432, -6, 31, -11, 8, 2;

   .VAR/DM1 QuantTablesLSBDec6Bit[] =
      &$M.SBAdpcm.memory.QQ4IL4, &$M.SBAdpcm.memory.QQ4IL4, &$M.SBAdpcm.memory.WLIL4, &$M.SBAdpcm.memory.ILB;

   .VAR $sbadpcm.mode.decode6bit[$sbadpcm.MODE_TABLE.STRUCT_SIZE] =
      0,                              // FLAGS_FIELD
      &QuantConstLSBDec6Bit,          // PTRCONST_LSB_FIELD
      &QuantTablesLSBDec6Bit,         // PTRTABLES_LSB_FIELD
      &$M.SBAdpcm.decode.memory.QuantConstHSBDec,   // PTRCONST_HSB_FIELD
      &$M.SBAdpcm.decode.memory.QuantTablesHSBDec;   // PTRTABLES_HSB_FIELD

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Mode.Decode7Bit
//
// DESCRIPTION:
//    mode table for 7-bit decoder
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.Mode.Decode7Bit;
   .DATASEGMENT DM;

   .VAR/DM1 QQ5IL5[32] =
      -71680,-71680,-5978112,-4495360,-3614720,-2985984,-2496512,
      -2095104,-1757184,-1462272,-1202176,-968704,-757760,-565248,
      -389120,-225280,5978112,4495360,3614720,2985984,2496512,2095104,
      1757184,1462272,1202176,968704,757760,565248,389120,225280,71680,-71680;

   .VAR/DM2 QuantConstLSBDec7Bit[] = -1, -2, 127, -7, 18432, -6, 31, -11, 8, 2;

   .VAR/DM1 QuantTablesLSBDec7Bit[] =
      &QQ5IL5, &$M.SBAdpcm.memory.QQ4IL4, &$M.SBAdpcm.memory.WLIL4, &$M.SBAdpcm.memory.ILB;

   .VAR $sbadpcm.mode.decode7bit[$sbadpcm.MODE_TABLE.STRUCT_SIZE] =
      0,                              // FLAGS_FIELD
      &QuantConstLSBDec7Bit,          // PTRCONST_LSB_FIELD
      &QuantTablesLSBDec7Bit,         // PTRTABLES_LSB_FIELD
      &$M.SBAdpcm.decode.memory.QuantConstHSBDec,   // PTRCONST_HSB_FIELD
      &$M.SBAdpcm.decode.memory.QuantTablesHSBDec;   // PTRTABLES_HSB_FIELD


.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Mode.Decode8Bit
//
// DESCRIPTION:
//    mode table for 8-bit decoder
//
// NOTES:
// *****************************************************************************
.MODULE $M.SBAdpcm.Mode.Decode8Bit;
   .DATASEGMENT DM;

   .VAR/DM1 QQ6IL6[64] =
      -34816,-34816,-34816,-34816,-6350848,-5607424,-4866048,-4276224,
      -3835904,-3459072,-3143680,-2865152,-2619392,-2396160,-2195456,
      -2011136,-1841152,-1683456,-1536000,-1396736,-1265664,-1142784,
      -1026048,-915456,-811008,-710656,-614400,-520192,-432128,-348160,
      -266240,-186368,6350848,5607424,4866048,4276224,3835904,3459072,
      3143680,2865152,2619392,2396160,2195456,2011136,1841152,1683456,
      1536000,1396736,1265664,1142784,1026048,915456,811008,710656,614400,
      520192,432128,348160,266240,186368,110592,34816,-110592,-34816;

   .VAR/DM2 QuantConstLSBDec8Bit[] =  0, -2, 127, -7, 18432, -6, 31, -11, 8, 2;

   .VAR/DM1 QuantTablesLSBDec8Bit[] =
      &QQ6IL6, &$M.SBAdpcm.memory.QQ4IL4, &$M.SBAdpcm.memory.WLIL4, &$M.SBAdpcm.memory.ILB;

   .VAR $sbadpcm.mode.decode8bit[$sbadpcm.MODE_TABLE.STRUCT_SIZE] =
      0,                               // FLAGS_FIELD
      &QuantConstLSBDec8Bit,           // PTRCONST_LSB_FIELD
      &QuantTablesLSBDec8Bit,          // PTRTABLES_LSB_FIELD
      &$M.SBAdpcm.decode.memory.QuantConstHSBDec,   // PTRCONST_HSB_FIELD
      &$M.SBAdpcm.decode.memory.QuantTablesHSBDec;   // PTRTABLES_HSB_FIELD

.ENDMODULE;





// *****************************************************************************
//    adpcm library code set
// *****************************************************************************
#ifndef NOLIB
   // include the core encoder/decoder
#include "sbadpcm_initialize.asm"
#include "sbadpcm_encoder.asm"
#include "sbadpcm_decoder.asm"
#include "sbadpcm_predictor.asm"
#include "sbadpcm_quantize.asm"
#include "sbadpcm_qmf.asm"
   // include the encoded data framework front-end
#include "sbadpcm_frame_encode.asm"

   // include the sco-decoder framework front-end
#include "sbadpcm_sco_decode.asm"

#endif





#endif // _SBADPCM_LIBRARY

