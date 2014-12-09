/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
Part of ADK 3.5

FILE NAME
    wbs_supported.c
    
DESCRIPTION
    Interface for the Wide Band Speech Service where the service is supported

*/

/*****************************************************************************

IMPORTANT INFORMATION REGARDING THE MAINTENANCE OF THIS FILE

If this file is changed please consider the following files:

aghfp_wbs.h
aghfp_wbs.c
hfp_wbs.h
hfp_wbs.c

wbs.h and wbs.c implement the interface into the WBS speech library. However, 
it may be desirable to build variants of a library with and without WB-Speech. 
In the latter case it is desirable to not have to rely on the existence of the 
WBS library in order for code to compile and link correctly. For the 
non-WB-Speech variant the interface is implemented within the (non-WBS) 
library and stubs are created for the WBS function calls which default to 
WB-Speech not supported type behaviour. However, since the same interface is 
being implemented in multiple places each version must be maintained and kept 
in line with the others.

The following text should appear in the .c and .h files within each module 
which implement the WBS interface stub:

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

#include "wbs.h"

#include <print.h>
#include <file.h>
#include <kalimba.h>
#include <panic.h>
#include <message.h>
#include <ctype.h>
#include <vm.h>

/*
    Return the Codec ID given a codec mask.
*/
wbs_codec WbsCodecMaskToCodecId(codecs_info *codecs_info_in, uint16 codec_mask)
{
    uint16 counter_1;
    uint16 test_mask = 1;
    uint16 codec_index = 0;
    bool   codec_found = FALSE;

    for(counter_1 = 0; counter_1 < 16; counter_1++)
    {
        /* Is it this codec? */
        if(codec_mask & test_mask)
        {
            codec_found = TRUE;
            break;
        }

        test_mask <<= 1;

        /* Move codec index along if it is time to do so */
        if(codecs_info_in->codecs & test_mask) codec_index++;
    }

    if(codec_found)
    {
        return(codecs_info_in->codec_ids[codec_index]);
    }
    else
    {
        return(0);
    }
 }
 
/*
    Return the codec mask given a Codec ID.
*/
uint16 WbsCodecIdToCodecMask(codecs_info *codecs_info_in, wbs_codec codec_id)
 {
    uint16 counter_1;
    uint16 test_mask = 1;
    uint16 codec_index = 0;
    bool   codec_found = FALSE;
    bool   first_bit_found = FALSE;

    for(counter_1 = 0; counter_1 < 16; counter_1++)
    {
        /* Find the first bit set in the codec mask. */
        if(!first_bit_found && !(codecs_info_in->codecs & test_mask))
        {
            test_mask <<= 1;
            continue;
        }

        first_bit_found = TRUE;
    
        if((codecs_info_in->codec_ids[codec_index] == codec_id) && (codecs_info_in->codecs & test_mask))
        {
            codec_found = TRUE;
            break;
        }

        test_mask <<= 1;
        
        /* Move codec index along if it is time to do so */
        if(codecs_info_in->codecs & test_mask) codec_index++;
    }

    if(codec_found)
    {
        return(test_mask);
    }
    else
    {
        return(0);
    }
}

