// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// DESCRIPTION
//    Frame Sync streams declaration macros and debug info constants
//
// *****************************************************************************

#ifndef FRAME_SYNC_STREAM_MACROS_H
#define FRAME_SYNC_STREAM_MACROS_H

#include "core_library.h"

#ifndef BASE_REGISTER_MODE
#define DMCBUF      DMCIRC
#else
#define DMCBUF      DM
#endif

#ifdef BASE_REGISTER_MODE
#define DeclareCBufferNoMem(cbuffer_struc, cbuffer)     \
.VAR cbuffer_struc[$cbuffer.STRUC_SIZE] =               \
          LENGTH(cbuffer),                              \
          &cbuffer,                                     \
          &cbuffer,                                     \
          &cbuffer
#else
#define DeclareCBufferNoMem(cbuffer_struc, cbuffer)     \
.VAR cbuffer_struc[$cbuffer.STRUC_SIZE] =               \
          LENGTH(cbuffer),                              \
          &cbuffer,                                     \
          &cbuffer          
#endif

#ifdef FRAME_SYNC_DEBUG

   .CONST $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD     $cbuffer.STRUC_SIZE + 0;
   .CONST $frame_sync.DBG_AVERAGE_TRANSFER_TIME_FIELD    $cbuffer.STRUC_SIZE + 1;
   .CONST $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD   $cbuffer.STRUC_SIZE + 2;
   .CONST $frame_sync.DBG_TIME_STAMP_FIELD               $cbuffer.STRUC_SIZE + 3;
   .CONST $frame_sync.DBG_MIN_TIME                       $cbuffer.STRUC_SIZE + 4;
   .CONST $frame_sync.DBG_MAX_TIME                       $cbuffer.STRUC_SIZE + 5;
   .CONST $frame_sync.DBG_MIN_IN_LEV                     $cbuffer.STRUC_SIZE + 6;
   .CONST $frame_sync.DBG_MAX_IN_LEV                     $cbuffer.STRUC_SIZE + 7;
   .CONST $frame_sync.DBG_MIN_OUT_LEV                    $cbuffer.STRUC_SIZE + 8;
   .CONST $frame_sync.DBG_MAX_OUT_LEV                    $cbuffer.STRUC_SIZE + 9;
   .CONST $frame_sync.DBG_COUNT                          $cbuffer.STRUC_SIZE + 10;
   .CONST $frame_sync.DBG_PACKET_SIZE_FIELD              $cbuffer.STRUC_SIZE + 11;
   .CONST $frame_sync.DBG_PORT_COPY_THRESHOLD_FIELD      $cbuffer.STRUC_SIZE + 12;
   .CONST $frame_sync.DBG_CBUFFER_COPY_THRESHOLD_FIELD   $cbuffer.STRUC_SIZE + 13;
   .CONST $frame_sync.DBG_STRUC_SIZE                     14;

#define DeclareCBuffer(cbuffer_struc, cbuffer, cbuffer_size)           \
  .VAR/DMCBUF cbuffer[cbuffer_size];                                   \
  .BLOCK/DM cbuffer_struc ## _block;                                   \
     DeclareCBufferNoMem(cbuffer_struc,cbuffer);                       \
     .VAR cbuffer_struc ## _debug[$frame_sync.DBG_STRUC_SIZE] = 0 ...; \
  .ENDBLOCK

#else
#define DeclareCBuffer(cbuffer_struc, cbuffer, cbuffer_size)           \
      .VAR/DMCBUF cbuffer[cbuffer_size];                               \
      DeclareCBufferNoMem(cbuffer_struc,cbuffer)                        
#endif
   

#endif
