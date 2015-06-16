// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef MALLOC_HEADER_INCLUDED
#define MALLOC_HEADER_INCLUDED


#ifdef DEBUG_MALLOC_ON
    #define MALLOC_FREE_TESTS
    #define MALLOC_PANIC_ON_BAD_FREE
#endif

#ifdef DEBUG_MALLOC_ON
   #ifdef INCLUDE_DEBUG_SPACE
      .CONST $malloc.DEBUG_SPACE          1;
   #else
      .CONST $malloc.DEBUG_SPACE          0;
   #endif
#else
   .CONST $malloc.DEBUG_SPACE             0;
#endif

#define INCLUDE_GUARD_BAND
#ifdef INCLUDE_GUARD_BAND
  .CONST $malloc.GUARD_BAND_SPACE         1;
#else
  .CONST $malloc.GUARD_BAND_SPACE         0;
#endif

   .CONST $malloc.SIZE_FIELD              0;               .CONST $malloc.input.SIZE_FIELD          0;
   .CONST $malloc.START_ADDR_DM1_FIELD    1;               .CONST $malloc.input.NUMBER_DM1_FIELD    1;
   .CONST $malloc.START_ADDR_DM2_FIELD    2;               .CONST $malloc.input.NUMBER_DM2_FIELD    2;
   .CONST $malloc.POINTER_DM1_FIELD       3;               .CONST $malloc.input.STRUC_SIZE          3;
   .CONST $malloc.POINTER_DM2_FIELD       4;
#ifdef DEBUG_MALLOC_ON
   .CONST $malloc.LOW_WATERMARK_DM1_FIELD 5;
   .CONST $malloc.LOW_WATERMARK_DM2_FIELD 6;
   .CONST $malloc.FAIL_COUNT_FIELD        7;

   .CONST $malloc.EXTRA_DEBUG_FIELDS      3;
   .CONST $malloc.WATERMARK_ON            1;
   .CONST $malloc.FAIL_COUNT_ON           1;
#else
   .CONST $malloc.EXTRA_DEBUG_FIELDS      0;
   .CONST $malloc.WATERMARK_ON            0;
   .CONST $malloc.FAIL_COUNT_ON           0;
#endif
   .CONST $malloc.STRUC_SIZE              5 + $malloc.EXTRA_DEBUG_FIELDS;


   .CONST $malloc.MAX_NUM_SIZES          60;

   .CONST $malloc.free_block.POINTER_FIELD     0;
   .CONST $malloc.free_block.NUM_FREE_FIELD    1;

   .CONST $malloc.dm_preference.DM1            1;
   .CONST $malloc.dm_preference.DM2            2;
   .CONST $malloc.dm_preference.NO_PREFERNCE   3;


#endif
