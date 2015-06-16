// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2008-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Audio Process Library
//
// DESCRIPTION:
//    This library contains the following modules:
//       - delay
//       - peq: Parametric Equalizer
//       - peak signal monitor
//       - stream gain
//       - stream mixer
//
// *****************************************************************************

#ifndef AUDIO_PROC_LIBRARY_INCLUDED
#define AUDIO_PROC_LIBRARY_INCLUDED

#include "flash.h"
#include "delay.asm"
#include "peq.asm"
#include "peak_monitor.asm"
#include "stream_gain.asm"
#include "stream_mixer.asm"
#include "cmpd100.asm"
#include "stereo_3d_enhancement.asm"
#include "mute_control.asm"
#include "stereo_copy.h"
#include "bass_management.asm"
#include "latency_measure.asm"

#endif // AUDIO_PROC_LIBRARY_INCLUDED
