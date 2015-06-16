/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_codec_msg_handler.c

DESCRIPTION
    Codec library message handling.
    
*/


/* header for this file */
#include "source_codec_msg_handler.h"
/* application header files */
#include "source_debug.h"
#include "source_init.h"
#include "source_private.h"
/* profile/library headers */
#include <codec.h>
/* VM headers */
#include <panic.h>


#ifdef DEBUG_CODEC_MSG
    #define CODEC_MSG_DEBUG(x) DEBUG(x)
#else
    #define CODEC_MSG_DEBUG(x)
#endif     


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    codec_msg_handler - Handle Codec library messages
*/    
void codec_msg_handler(Task task, MessageId id, Message message)
{  
    /* codec library initialisation confirmation */
    if (id == CODEC_INIT_CFM) 
    {
        CODEC_MSG_DEBUG(("CODEC_INIT_CFM [%d]\n", ((CODEC_INIT_CFM_T*)message)->status));
        if (((CODEC_INIT_CFM_T*)message)->status == codec_success) 
        {            
            theSource->codec = ((CODEC_INIT_CFM_T*)message)->codecTask;
            
            init_register_profiles(REGISTERED_PROFILE_CODEC);
        }
        else
        {
            Panic();
        }
    }
}
