// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#include "reset.asm"
#include "error.asm"
#include "stack.asm"
#include "timer.asm"
#include "message.asm"
#include "cbuffer.asm"
#include "interrupt.asm"
#include "flash.asm"
#include "pskey.asm"
#include "wall_clock.asm"
#include "pio.asm"
#include "profiler.asm"
//#include "fwrandom.asm"
#ifdef BUILD_WITH_C_SUPPORT
   #include "core_library_c_stubs.asm"
   #include "crt0_withputchar.asm"
#endif

/*! \mainpage Kalimba Library Documentation

\section intro_sec Introduction

This set of documents covers the software libraries for the Kalimba DSP.
The libraries include core functionality including interrupt handling, message passing and
circular buffer management, higher level functionality in the form of the math library up to
larger libraries including MP3 and SBC libraries.

These documents are aimed at all users wishing to write code for the Kalimba DSP. They can be
read either stand-alone or along side the example applications available in your SDK.

\section background Background

Kalimba is an on-chip DSP co-processor available on selected BlueCore chips.

The Kalimba DSP particularly targets audio processing applications for BlueCore. The likely audio
processing applications include:
- Sub-Band Coding (SBC) encoding and decoding, as defined in the Bluetooth Advanced Audio
Distribution Profile
- MP3 encoding and decoding, as defined in ISO/IEC 11172-3, and the sample rate extensions defined
in ISO/IES 13818-3
- Advanved Audio Coding (AAC) encoding and decoding, as defined in ISO/IEC 13818-7
- Alternative voice/Hi-Fi CODECs
- Echo and noise cancellation
- Speech and music enhancement

\section usage_sec Usage

There are three links at the top of each page - "Main Page", "File List" and "File Members".

\subsection main_page Main Page

Clicking on "Main Page" will always return you to this page.

\subsection file_list File List

This links to a contents page which lists each file grouped by library. For the core
libraries each file typically describes multiple functions, for the other libraries each file
generally describes only one function.

\subsection file_members File Members

This links to a contents page which lists each function alphabetically. Note where applicable
the library name is removed, so $cbuffer.get_read_address_and_size is listed as
get_read_address_and_size.

*/







