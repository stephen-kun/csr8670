// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifdef DEBUG_ON
   #define ENABLE_PROFILER_MACROS
#endif

#include "profiler.h"
#include "segments.asm"
#include "stream_encode.asm"
#include "stream_decode.asm"
#include "stream_decode_sync.asm"
#include "stream_relay.asm"

#ifdef BUILD_WITH_C_SUPPORT
  #include "codec_library_c_stubs.asm"
#endif
