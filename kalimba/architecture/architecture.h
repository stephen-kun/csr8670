// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef ARCHITECTURE_H_INCLUDED
#define ARCHITECTURE_H_INCLUDED

#if defined AMBER
#   include "amber.h"
#   include "amber_io_defs.h"
#   include "amber_io_map.h"
#elif defined GEMINI
#   include "gemini.h"
#   include "gemini_io_defs.h"
#   include "gemini_io_map.h"
#elif defined GORDON
#   include "gordon.h"
#   include "gordon_io_defs.h"
#   include "gordon_io_map.h"
#elif defined PURDEY
#   include "purdey.h"
#   include "purdey_io_defs.h"
#   include "purdey_io_map.h"
#elif defined SIRFSTARV
#   include "sirfstarv.h"
#   include "sirfstarv_io_defs.h"
#   include "sirfstarv_io_map.h"
#elif defined DALE
#   include "dale.h"
#   include "dale_io_defs.h"
#   include "dale_io_map.h"
#elif defined RICK
#   include "rick.h"
#   include "rick_io_defs.h"
#   include "rick_io_map.h"
#else
#   error "no known target defined, set AMBER, GORDON or SIRFSTARV etc"
#endif

#endif
