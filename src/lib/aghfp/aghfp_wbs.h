/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
Part of ADK 3.5

FILE NAME
    aghfp_wbs.h
    
DESCRIPTION
    Interface for the Wide Band Speech Service for the AGHFP library.

*/

/*!
@file aghfp_wbs.h
@brief Interface for the Wide Band Speech Service for the AGHFP library..

*/

/*****************************************************************************

IMPORTANT INFORMATION REGARDING THE MAINTENANCE OF THIS FILE

The contents of this file shadows that of wbs.h in the WBS speech module. If 
that file is changed, this file must also be changed accordingly.

The .h and .c versions of this file exist to provide an interface for WB-Speech 
for this library. It was desired to be able to build a WB-Speech and 
non-WB-Speech variant of the library with the non-WB-Speech not being dependant 
upon the existence on a WBS library. One option to achieve this would be to 
place compile switches throughout the library code for the WBS handling. This 
options did not appear to fit in with how the library was currently written. A 
second option would be to use a compile switch which would implement a stub for 
the WBS library within the this library for the non-WB-Speech version. This is 
what the .h and .c versions of this file aim to achieve. If WBS is defined, 
wbs.h is included and the WBS library is linked in to complete the interface. 
If WBS is not defined, the .h file implements the defines, enums, structures and 
prototypes which form the WBS-Speech interface and the .c provides the stubs 
for the actual function calls.

This is bad from a code maintenance point of view since this file needs to be 
maintained in line with wbs.h and wbs.c, but the desire to have a non-WB-Speech 
variant not dependant upon the WBS library and to have no WBS compile switches 
scattered around the code necessitated such an approach.

The way foward would be to implement a 'common' module, included by all 
libraries, which can house things which are common to the libraries and can be
used to implement stubs when features are not required.

******************************************************************************/

#ifndef AGHFP_WBS_H
#define AGHFP_WBS_H

#ifdef WBS

#include <wbs.h>

#else

#include <bdaddr_.h>
#include <message.h>

/* Codec ID's for WB-Speech. */
typedef enum
{
    wbs_codec_cvsd = 0x01,
    wbs_codec_msbc = 0x02
} wbs_codec;


/*!
    @brief Structure defining user definable information regarding the HF's codecs.

*/
typedef struct
{
    uint8     num_codecs;
    uint16    codecs;
    wbs_codec codec_ids[1];
} codecs_info;

/*
    Return the Codec ID given a codec mask.
*/
wbs_codec WbsCodecMaskToCodecId(codecs_info *codecs_info_in, uint16 codec_mask);

/*
    Return the codec mask given a Codec ID.
*/
uint16 WbsCodecIdToCodecMask(codecs_info *codecs_info_in, wbs_codec codec_id);

#endif /* WBS */

#endif /* AGHFP_WBS_H */

