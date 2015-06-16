// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifdef DEBUG_ON
   #define DEBUG_MATH
   #define ENABLE_PROFILER_MACROS
#endif

#include "profiler.h"
#include "sin.asm"
#include "cos.asm"
#include "sqrt.asm"
#include "inv_qdrt.asm"
#include "pow2.asm"
#include "log2.asm"
#include "rand.asm"
#include "fft.asm"
#include "vector_complex_multiply.asm"
#include "iir.asm"
#include "atan.asm"
#include "div48.asm"
#include "address_bitreverse.asm"
#include "misc.asm"
