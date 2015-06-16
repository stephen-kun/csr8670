/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_init.c

DESCRIPTION
    Initialisation of application.
    
*/


/* header for this file */
#include "source_init.h"
/* application header files */
#include "source_a2dp.h"
#include "source_app_msg_handler.h"
#include "source_avrcp.h"
#include "source_debug.h"
#include "source_inquiry.h"
#include "source_memory.h"
#include "source_private.h"
#include "source_states.h"
/* profile/library headers */
#include <a2dp.h>
#include <codec.h>
#include <connection.h>
/* VM headers */
#include <panic.h>


#ifdef DEBUG_INIT
    #define INIT_DEBUG(x) DEBUG(x)
#else
    #define INIT_DEBUG(x)
#endif


/* connection library messages to receive */
const msg_filter connection_msg_filter = {msg_group_acl};


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    init_register_profiles - Called when a profile has been initialised  
*/
void init_register_profiles(REGISTERED_PROFILE_T registered_profile)
{
    switch (registered_profile)
    {
        case REGISTERED_PROFILE_NONE:
        {
            /* initialise profile memory */
            init_profile_memory();
            
            /* store locally supported profiles */
            if (theSource->ps_config->bt_profiles.hfp_profile != PS_HFP_PROFILE_DISABLED)
            {
                theSource->connection_data.supported_profiles |= PROFILE_AGHFP;
            }
            if (theSource->ps_config->bt_profiles.a2dp_profile != PS_A2DP_PROFILE_DISABLED)
            {
                theSource->connection_data.supported_profiles |= PROFILE_A2DP;
            }
            if (theSource->ps_config->bt_profiles.avrcp_profile != PS_AVRCP_PROFILE_DISABLED)
            {
                theSource->connection_data.supported_profiles |= PROFILE_AVRCP;
            }
            
            /* set initial audio mode based on registered Profiles */
            if (A2DP_PROFILE_IS_ENABLED)
            {    
                audio_set_voip_music_mode(AUDIO_MUSIC_MODE);
            }
            else
            {
                audio_set_voip_music_mode(AUDIO_VOIP_MODE);
            }
            
            /* initialise Connection library */
            INIT_DEBUG(("INIT: Initialising Connection Library...\n"));
            ConnectionInitEx2(&theSource->connectionTask, &connection_msg_filter, theSource->ps_config->number_paired_devices);
        }
        break;
        
        case REGISTERED_PROFILE_CL:
        {
            CsrInternalCodecTaskData *codec = PanicUnlessMalloc(sizeof(CsrInternalCodecTaskData));
            /* initialise Codec library */
            INIT_DEBUG(("INIT: Initialising Codec Library...\n"));           
            CodecInitCsrInternal(codec, &theSource->codecTask);
        }
        break;
        
        case REGISTERED_PROFILE_CODEC:
        {            
            if (A2DP_PROFILE_IS_ENABLED)
            {
                /* initialise A2DP library */
                INIT_DEBUG(("INIT: Initialising A2DP Library...\n"));
                a2dp_init();
                break;
            }
        }
        /* fall through to REGISTERED_PROFILE_A2DP if A2DP disabled */        
        
        case REGISTERED_PROFILE_A2DP:
        {        
            if (AVRCP_PROFILE_IS_ENABLED)
            {
                /* initialise AVRCP library */
                INIT_DEBUG(("INIT: Initialising AVRCP Library...\n"));
                avrcp_init();
                break;
            }
        }
        /* fall through to REGISTERED_PROFILE_AVRCP if AVRCP disabled */ 
        
        case REGISTERED_PROFILE_AVRCP:
        {           
            if (AGHFP_PROFILE_IS_ENABLED)
            {
                /* initialise AGHFP library */
                INIT_DEBUG(("INIT: Initialising AGHFP Library...\n"));
                aghfp_init();  
                break;
            }
        }
        /* fall through to REGISTERED_PROFILE_AGHFP if AGHFP disabled */
        
        case REGISTERED_PROFILE_AGHFP:
        {
            /* libraries initialised - send message to indicate the app is initialised */            
            MessageSend(&theSource->app_data.appTask, APP_INIT_CFM, 0);
        }
        break;
        
        default:
        {
            INIT_DEBUG(("INIT: Unrecognised Profile Registered\n"));
            Panic();
        }
        break;
    }
}


/****************************************************************************
NAME    
    init_profile_memory - Initialise memory to hold profile data
*/
bool init_profile_memory(void)
{
    return memory_create_block(MEMORY_CREATE_BLOCK_PROFILES);
}

