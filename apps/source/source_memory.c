/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_memory.c
    
DESCRIPTION
    Handles application memory applications.
    
*/


/* header for this file */
#include "source_memory.h"
/* application header files */
#include "source_a2dp.h"
#include "source_aghfp.h"
#include "source_avrcp.h"
#include "source_debug.h"
#include "source_private.h"
/* profile/library headers */
#include <audio.h>
/* VM headers */
#include <stdlib.h>


#ifdef DEBUG_MEMORY
    #define MEMORY_DEBUG(x) DEBUG(x)
#else
    #define MEMORY_DEBUG(x)
#endif


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    memory_create - Allocates memory of the specified size
*/
void *memory_create(size_t size)
{
    void *memory = malloc(size);
    MEMORY_DEBUG(("MEMORY: Create; size[0x%x] address[0x%x]\n", size, (uint16)memory));
    return memory;
}


/****************************************************************************
NAME    
    memory_free - Frees the memory that is passed in
*/
void memory_free(void *memory)
{
    MEMORY_DEBUG(("MEMORY: Free; address[0x%x]\n", (uint16)memory));
    free(memory);
}


/****************************************************************************
NAME    
    memory_create_block - Creates a memory block that can be split up and used for different elements
*/
bool memory_create_block(MEMORY_CREATE_BLOCK_T block)
{
    MEMORY_DEBUG(("MEMORY: Create block [%d]\n", block));
                  
    switch (block)
    {
        case MEMORY_CREATE_BLOCK_PROFILES:
        {
            theSource->profile_memory = memory_create(sizeof(a2dpInstance) * A2DP_MAX_INSTANCES +
                                                      sizeof(aghfpInstance) * AGHFP_MAX_INSTANCES +
                                                      sizeof(avrcpInstance) * AVRCP_MAX_INSTANCES);
            if (theSource->profile_memory)
            {
                return TRUE;
            }
        }
        break;
        
        case MEMORY_CREATE_BLOCK_CODECS:
        {
            theSource->a2dp_data.codec_config = memory_create(a2dp_get_sbc_caps_size() + a2dp_get_faststream_caps_size() + a2dp_get_aptx_caps_size()  + a2dp_get_aptxLowLatency_caps_size());
            if (theSource->a2dp_data.codec_config)
            {
                return TRUE;
            }
        }
        break;
        
        default:
        {
            MEMORY_DEBUG(("MEMORY: Unknown create block\n"));
        }
        break;
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    memory_get_block - Gets an element of a memory block
*/
void *memory_get_block(MEMORY_GET_BLOCK_T block)
{
    switch (block)
    {
        case MEMORY_GET_BLOCK_PROFILE_A2DP:
        {
            if (theSource->profile_memory)
            {
                return theSource->profile_memory->a2dp;
            }
        }
        break;
        
        case MEMORY_GET_BLOCK_PROFILE_AGHFP:
        {
            if (theSource->profile_memory)
            {
                return theSource->profile_memory->aghfp;
            }
        }
        break;
        
        case MEMORY_GET_BLOCK_PROFILE_AVRCP:
        {
            if (theSource->profile_memory)
            {
                return theSource->profile_memory->avrcp;
            }
        }
        break;
        
        case MEMORY_GET_BLOCK_CODEC_SBC:
        {
            if (theSource->a2dp_data.codec_config)
            {
                return theSource->a2dp_data.codec_config;
            }
        }
        break;
        
        case MEMORY_GET_BLOCK_CODEC_FASTSTREAM:
        {
            if (theSource->a2dp_data.codec_config)
            {
                return theSource->a2dp_data.codec_config + a2dp_get_sbc_caps_size();
            }
        }
        break;
        
        case MEMORY_GET_BLOCK_CODEC_APTX:
        {
            if (theSource->a2dp_data.codec_config)
            {
                return theSource->a2dp_data.codec_config + a2dp_get_sbc_caps_size() + a2dp_get_faststream_caps_size();
            }
        }
        break;
        
        case MEMORY_GET_BLOCK_CODEC_APTX_LOW_LATENCY:
        {
            if (theSource->a2dp_data.codec_config)
            {
                return theSource->a2dp_data.codec_config + a2dp_get_sbc_caps_size() + a2dp_get_faststream_caps_size()  + a2dp_get_aptx_caps_size();
            }
        }
        break;
        
        default:
        {
            MEMORY_DEBUG(("MEMORY: Unknown get block [%d]\n", block));
        }
        break;
    }
    
    return NULL;
}
