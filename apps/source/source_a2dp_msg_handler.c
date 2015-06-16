/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_a2dp_msh_handler.c

DESCRIPTION
    A2DP profile message handling
    
*/


/* header for this file */
#include "source_a2dp_msg_handler.h"
/* application header files */
#include "source_a2dp.h"
#include "source_app_msg_handler.h"
#include "source_connection_mgr.h"
#include "source_debug.h"
#include "source_init.h"
#include "source_memory.h"
#include "source_private.h"
/* profile/library headers */
#include <a2dp.h>
#include <codec.h>
/* VM headers */
#include <panic.h>


#ifdef DEBUG_A2DP_MSG
    #define A2DP_MSG_DEBUG(x) DEBUG(x)
#else
    #define A2DP_MSG_DEBUG(x)
#endif     


#define A2DP_MSG_DEBUG_INST(inst) A2DP_MSG_DEBUG(("        inst[0x%x]\n", (uint16)inst))

/* Display unhandled states in Debug Mode */
#define a2dp_msg_unhandled_state(inst) A2DP_MSG_DEBUG(("A2DP MSG Ignored; state[%d] inst[0x%x]\n", a2dp_get_state(inst), (uint16)inst));


/* A2DP library message handling functions */
static void a2dp_msg_connect_ind(const A2DP_SIGNALLING_CONNECT_IND_T *message);		
static void a2dp_msg_connect_cfm(const A2DP_SIGNALLING_CONNECT_CFM_T *message);	    
static void a2dp_msg_disconnect_ind(const A2DP_SIGNALLING_DISCONNECT_IND_T *message);
static void a2dp_msg_media_open_ind(const A2DP_MEDIA_OPEN_IND_T *message);
static void a2dp_msg_media_open_cfm(const A2DP_MEDIA_OPEN_CFM_T *message);
static void a2dp_msg_media_close_ind(const A2DP_MEDIA_CLOSE_IND_T *message);
static void a2dp_msg_media_configure_ind(A2DP_CODEC_CONFIGURE_IND_T *message);
static void a2dp_msg_media_start_ind(const A2DP_MEDIA_START_IND_T *message);
static void a2dp_msg_media_start_cfm(const A2DP_MEDIA_START_CFM_T *message);
static void a2dp_msg_media_suspend_ind(const A2DP_MEDIA_SUSPEND_IND_T *message);
static void a2dp_msg_media_suspend_cfm(const A2DP_MEDIA_SUSPEND_CFM_T *message);
static void a2dp_msg_link_loss_ind(const A2DP_SIGNALLING_LINKLOSS_IND_T *message);
/* A2DP application message handling functions */
static void a2dp_msg_internal_signalling_connect_req(Task task);
static void a2dp_msg_internal_media_open_req(Task task);
static void a2dp_msg_internal_media_start_req(Task task);
static void a2dp_msg_internal_force_disconnect_req(Task task);
static void a2dp_msg_internal_signalling_disconnect_req(Task task);
static void a2dp_msg_internal_media_suspend_req(Task task);
static void a2dp_msg_internal_connect_audio_req(Task task);
static void a2dp_msg_internal_media_close_req(Task task);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    a2dp_msg_handler - Handles A2DP messages.
*/
void a2dp_msg_handler(Task task, MessageId id, Message message)
{  
    /* A2DP Library Messages */
    switch (id)
    {
/******************/
/* INITIALISATION */
/******************/
        
        /* confirmation of the initialisation of the A2DP library */
        case A2DP_INIT_CFM:
        {
            A2DP_MSG_DEBUG(("A2DP_INIT_CFM [%d]:\n", ((A2DP_INIT_CFM_T*)message)->status));
            if (((A2DP_INIT_CFM_T*)message)->status == a2dp_success)
            {
                /* set number of devices the A2DP library should handle */
                A2dpConfigureMaxRemoteDevices(A2DP_ENABLED_INSTANCES);
                
                /* init of A2DP complete */
                init_register_profiles(REGISTERED_PROFILE_A2DP);
            }
            else
            {
                Panic();
            }
        }
        return;

/*****************************/        
/* SIGNALING CHANNEL CONTROL */
/*****************************/

        /* indication of a remote source trying to make a signalling connection */		
	    case A2DP_SIGNALLING_CONNECT_IND:
		{
	        A2DP_MSG_DEBUG(("A2DP_SIGNALLING_CONNECT_IND:\n"));
            a2dp_msg_connect_ind((A2DP_SIGNALLING_CONNECT_IND_T *)message);		
        
		}
		return;

        /* confirmation of a signalling connection attempt, successful or not */
	    case A2DP_SIGNALLING_CONNECT_CFM:
        {
            A2DP_MSG_DEBUG(("A2DP_SIGNALLING_CONNECT_CFM %d:\n", ((A2DP_SIGNALLING_CONNECT_CFM_T *)message)->status));
            a2dp_msg_connect_cfm((A2DP_SIGNALLING_CONNECT_CFM_T *)message);	    
        }
        return;
        
        /* indication of a signalling channel disconnection having occured */
    	case A2DP_SIGNALLING_DISCONNECT_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_SIGNALLING_DISCONNECT_IND:\n"));
        	a2dp_msg_disconnect_ind((A2DP_SIGNALLING_DISCONNECT_IND_T *)message);
        }
		return;
        
/*************************/        
/* MEDIA CHANNEL CONTROL */        
/*************************/
        
        /* indication of a remote device attempting to open a media channel */      
        case A2DP_MEDIA_OPEN_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_OPEN_IND:\n"));
        	a2dp_msg_media_open_ind((A2DP_MEDIA_OPEN_IND_T *)message);
        }
        return;
		
        /* confirmation of request to open a media channel */
        case A2DP_MEDIA_OPEN_CFM:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_OPEN_CFM %d:\n", ((A2DP_MEDIA_OPEN_CFM_T *)message)->status));
        	a2dp_msg_media_open_cfm((A2DP_MEDIA_OPEN_CFM_T *)message);
        }
        return;
        	
        /* indication of a closed media channel */
        case A2DP_MEDIA_CLOSE_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_CLOSE_IND:\n"));
            a2dp_msg_media_close_ind((A2DP_MEDIA_CLOSE_IND_T *)message);
        }
        return;   
        
        case A2DP_CODEC_CONFIGURE_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_CODEC_CONFIGURE_IND:\n"));
            a2dp_msg_media_configure_ind((A2DP_CODEC_CONFIGURE_IND_T *)message);
        }
        return;

/**********************/          
/*  STREAMING CONTROL */
/**********************/          
        
        /* indication of start of media streaming from the remote device */
        case A2DP_MEDIA_START_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_START_IND:\n"));
         	a2dp_msg_media_start_ind((A2DP_MEDIA_START_IND_T *)message);
        }
        return;
		
        /* confirmation of a local request to start media streaming */
        case A2DP_MEDIA_START_CFM:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_START_CFM %d:\n", ((A2DP_MEDIA_START_CFM_T *)message)->status));
    	    a2dp_msg_media_start_cfm((A2DP_MEDIA_START_CFM_T *)message);
        }
        return;
        
        /* indication of media suspended from the remote device */
        case A2DP_MEDIA_SUSPEND_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_SUSPEND_IND:\n"));
        	a2dp_msg_media_suspend_ind((A2DP_MEDIA_SUSPEND_IND_T *)message);
        }
        return;
		
        /* confirmation of a local request to suspend media streaming */
        case A2DP_MEDIA_SUSPEND_CFM:
        {
            A2DP_MSG_DEBUG(("A2DP_MEDIA_SUSPEND_CFM %d:\n", ((A2DP_MEDIA_SUSPEND_CFM_T *)message)->status));
        	a2dp_msg_media_suspend_cfm((A2DP_MEDIA_SUSPEND_CFM_T *)message);
        }
        return;

/*************************/
/* MISC CONTROL MESSAGES */
/*************************/
                
        /* indication of A2DP link loss */
        case A2DP_SIGNALLING_LINKLOSS_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_SIGNALLING_LINKLOSS_IND:\n"));	
            a2dp_msg_link_loss_ind((A2DP_SIGNALLING_LINKLOSS_IND_T *)message);
        }
        return;           
		        
        /* indication that the encryption status has changed */
	    case A2DP_ENCRYPTION_CHANGE_IND:
        {
            A2DP_MSG_DEBUG(("A2DP_ENCRYPTION_CHANGE_IND:\n"));
        }
		return;
			
        default:       
        {	    	
        }
        break;
    }    
    
    /* A2DP Internal Application Messages */
    switch (id)
    {
        /* internal request to connect A2DP signalling */
        case A2DP_INTERNAL_SIGNALLING_CONNECT_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_SIGNALLING_CONNECT_REQ:\n"));
            a2dp_msg_internal_signalling_connect_req(task);
        }
        return;
        
        /* internal request to open media */
        case A2DP_INTERNAL_MEDIA_OPEN_REQ:        
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_MEDIA_OPEN_REQ:\n"));
            a2dp_msg_internal_media_open_req(task);
            
        }
        return;
        
        /* internal request to start streaming */
        case A2DP_INTERNAL_MEDIA_START_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_MEDIA_START_REQ:\n"));
            a2dp_msg_internal_media_start_req(task);
        }
        return;
        
        /* internal request to force disconnect */
        case A2DP_INTERNAL_FORCE_DISCONNECT_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_FORCE_DISCONNECT_REQ:\n"));
            a2dp_msg_internal_force_disconnect_req(task);
        }
        return;
        
        /* internal request to disconnect A2DP signalling */
        case A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ:\n"));
            a2dp_msg_internal_signalling_disconnect_req(task);
        }
        return;
        
        /* internal request to suspend A2DP stream */
        case A2DP_INTERNAL_MEDIA_SUSPEND_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_MEDIA_SUSPEND_REQ:\n"));
            a2dp_msg_internal_media_suspend_req(task);
        }
        return;
        
        case A2DP_INTERNAL_CONNECT_AUDIO_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_CONNECT_AUDIO_REQ:\n"));
            a2dp_msg_internal_connect_audio_req(task);
        }
        return;
        
        case A2DP_INTERNAL_MEDIA_CLOSE_REQ:
        {
            A2DP_MSG_DEBUG(("A2DP_INTERNAL_MEDIA_CLOSE_REQ:\n"));
            a2dp_msg_internal_media_close_req(task);
        }
        return;
        
        default:
        {

        }
        break;
    }      
    
    /* handle Connection library messages destined for A2DP instance */
    switch (id)
    {
        /* result of A2DP service search */
        case CL_SDP_SERVICE_SEARCH_CFM:
        {
            a2dpInstance *inst = (a2dpInstance *) task;
            A2DP_MSG_DEBUG(("A2DP CL_SDP_SERVICE_SEARCH_CFM status = %u\n", ((CL_SDP_SERVICE_SEARCH_CFM_T *)message)->status));
            a2dp_sdp_search_cfm(inst, (CL_SDP_SERVICE_SEARCH_CFM_T *)message);                      
        } 
        break;
        /* result of read remote device features */
        case CL_DM_REMOTE_FEATURES_CFM:
        {
            a2dpInstance *inst = (a2dpInstance *) task;
            A2DP_MSG_DEBUG(("A2DP CL_DM_REMOTE_FEATURES_CFM\n"));
            a2dp_remote_features_cfm(inst, (CL_DM_REMOTE_FEATURES_CFM_T *)message);
            return;
        }
        
        default:       
        {
	    	A2DP_MSG_DEBUG(("A2DP MSG Unhandled[0x%x]\n", id));
        }
        return;
    }
}


/****************************************************************************
NAME    
    a2dp_msg_connect_ind - Handles A2DP library message A2DP_SIGNALLING_CONNECT_IND.
*/
static void a2dp_msg_connect_ind(const A2DP_SIGNALLING_CONNECT_IND_T *message)
{
    bool accept = FALSE;
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        inst = a2dp_get_instance_from_bdaddr(message->addr);
        if (inst == NULL)
        {
            inst = a2dp_get_free_instance();
        }
    }
        
    if (inst != NULL)
    {
        A2DP_MSG_DEBUG_INST(inst);
        
        /* store that A2DP is supported by remote device */
        inst->a2dp_support = A2DP_SUPPORT_YES;                    
        
        switch (a2dp_get_state(inst))
        {
            case A2DP_STATE_DISCONNECTED:
            {
                if (connection_mgr_can_connect(&message->addr, PROFILE_A2DP))
                {
                    /* accept incoming connection */
                    accept = TRUE;
                    /* store address of connecting device */
                    inst->addr = message->addr;
                    /* register incoming connection with connection manager */
                    connection_mgr_set_incoming_connection(PROFILE_A2DP, &inst->addr);
                            
                    /* update state */
                    a2dp_set_state(inst, A2DP_STATE_CONNECTING_REMOTE);
                    DEBUG_BDADDR(inst->addr);
                }
            }
            break;
        
            default:
            {            
            }
            break;
        }
    }
    
    A2DP_MSG_DEBUG(("  accept = %d\n", accept));
    if (!A2dpSignallingConnectResponse(((A2DP_SIGNALLING_CONNECT_IND_T *)message)->device_id, accept))
    {
        a2dp_set_state(inst, A2DP_STATE_DISCONNECTED);
    }
}


/****************************************************************************
NAME    
    a2dp_msg_connect_cfm - Handles A2DP library message A2DP_SIGNALLING_CONNECT_CFM.
*/
static void a2dp_msg_connect_cfm(const A2DP_SIGNALLING_CONNECT_CFM_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_bdaddr(message->addr);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));        
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTING_LOCAL:
        case A2DP_STATE_CONNECTING_REMOTE:
        case A2DP_STATE_DISCONNECTED: /* incase a connection crossover failed */
        {
            if (message->status == a2dp_success)
            {
                /* store the device_id for this signalling connection */
                inst->a2dp_device_id = message->device_id;  
                A2DP_MSG_DEBUG(("  device ID:[0x%x]\n", inst->a2dp_device_id));   
                /* update the state to reflect the signalling channel is connected */
                a2dp_set_state(inst, A2DP_STATE_CONNECTED_SIGNALLING);
            }
            else
            {            
                bool security_reconnect = FALSE;

                if (message->status == a2dp_security_reject)
                {
                    /* choose next PIN code if security rejected */
                    security_reconnect = connection_mgr_get_next_pin_code(&inst->addr);
                }

                if ((inst->a2dp_support == A2DP_SUPPORT_YES) && 
                    ((states_get_state() == SOURCE_STATE_CONNECTING) || (states_get_state() == SOURCE_STATE_CONNECTED)) &&
                    ((inst->a2dp_connection_retries < theSource->ps_config->features.a2dp_max_connection_retries) ||
                    security_reconnect))
                {
                    a2dp_set_state(inst, A2DP_STATE_DISCONNECTED);                    
                    /* A2DP is supported but connection failed, possibly due to connection crossover - retry A2DP connection */
                    MessageSendLater(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_CONNECT_REQ, 0, theSource->ps_config->ps_timers.a2dp_connection_failed_timer);                    
                    /* increase connection retries */
                    inst->a2dp_connection_retries++;
                }
                else
                {
                    /* reset A2DP instance to indicate it is disconnected */
                    a2dp_init_instance(inst);
                    /* send message that has connection has failed */    
                    MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);
                }
            }
        }
        break;
        
        default:
        {           
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    a2dp_msg_disconnect_ind - Handles A2DP library message A2DP_SIGNALLING_DISCONNECT_IND.
*/
static void a2dp_msg_disconnect_ind(const A2DP_SIGNALLING_DISCONNECT_IND_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTING_LOCAL:
        case A2DP_STATE_CONNECTING_REMOTE:
        case A2DP_STATE_CONNECTED_SIGNALLING:
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        case A2DP_STATE_CONNECTING_MEDIA_REMOTE:
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        case A2DP_STATE_DISCONNECTING_MEDIA:
        case A2DP_STATE_DISCONNECTING:
        {            
            if ((message->status == a2dp_disconnect_link_loss) && (theSource->ps_config->ps_timers.link_loss_reconnect_delay_timer != TIMER_NO_TIMEOUT))
            {
                A2DP_MSG_DEBUG(("  Link-Loss\n"));
                MessageSendLater(&theSource->app_data.appTask, APP_LINKLOSS_IND, 0, D_SEC(theSource->ps_config->ps_timers.link_loss_reconnect_delay_timer));
            }
            /* register disconnection with connection manager */
            connection_mgr_set_profile_disconnected(PROFILE_A2DP, &inst->addr);
            /* Disconnect A2DP audio if it is routed */
            audio_a2dp_disconnect(inst->a2dp_device_id, inst->media_sink);
            /* reset A2DP instance */
            a2dp_init_instance(inst);         
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }        
}


/****************************************************************************
NAME    
    a2dp_msg_media_open_ind - Handles A2DP library message A2DP_MEDIA_OPEN_IND.
*/
static void a2dp_msg_media_open_ind(const A2DP_MEDIA_OPEN_IND_T *message)
{
    bool accept = FALSE;
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }    
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_SIGNALLING: 
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        {
            /* accept this media connection */
            accept = TRUE;            
            a2dp_set_state(inst, A2DP_STATE_CONNECTING_MEDIA_REMOTE);
        }
        break;
        
        default:
        {            
        }
        break;
    }      
    
    A2DP_MSG_DEBUG(("  accept = %d\n", accept));
    if (!A2dpMediaOpenResponse(message->device_id, accept))
    {
        a2dp_set_state(inst, A2DP_STATE_CONNECTED_SIGNALLING);
    }
}


/****************************************************************************
NAME    
    a2dp_msg_media_open_cfm - Handles A2DP library message A2DP_MEDIA_OPEN_CFM.
*/
static void a2dp_msg_media_open_cfm(const A2DP_MEDIA_OPEN_CFM_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        case A2DP_STATE_CONNECTING_MEDIA_REMOTE:        
        {           
            if (message->status == a2dp_success)
            {
                a2dp_codec_settings *settings = NULL;
                /* store the device_id for this signalling connection */
                inst->a2dp_stream_id = message->stream_id;
                A2DP_MSG_DEBUG(("  device ID:[0x%x]\n", message->device_id)); 
                A2DP_MSG_DEBUG(("  stream ID [0x%x]\n", message->stream_id));

                settings = A2dpCodecGetSettings(message->device_id, message->stream_id);
                           
                if (settings)
                {
                    A2DP_MSG_DEBUG(("  stream end point ID [0x%x]\n", settings->seid));
                    /* update the audio plugin in use */
                    audio_a2dp_set_plugin(settings->seid);                    
                    /* free the settings memory that the A2DP library allocated */
                    memory_free(settings);
                }
                
                /* update the state to reflect the media channel is connected */
                a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA);
            }
            else
            {
                /* if media can't be connected then disconnect signalling channel */
                a2dp_set_state(inst, A2DP_STATE_DISCONNECTING);
            }
        }
        break;
        
        default:
        {         
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }      
}


/****************************************************************************
NAME    
    a2dp_msg_media_close_ind - Handles A2DP library message A2DP_MEDIA_CLOSE_IND.
*/
static void a2dp_msg_media_close_ind(const A2DP_MEDIA_CLOSE_IND_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        case A2DP_STATE_DISCONNECTING_MEDIA:        
        {           
            /* reset stream_id for this media connection */
            inst->a2dp_stream_id = A2DP_INVALID_ID;
            /* update state */
            a2dp_set_state(inst, A2DP_STATE_CONNECTED_SIGNALLING);
        }
        break;
        
        case A2DP_STATE_DISCONNECTING: 
        case A2DP_STATE_DISCONNECTED:
        {
        }
        break;
        
        default:
        {         
            a2dp_msg_unhandled_state(inst);
        }
        break;
    } 
}


/****************************************************************************
NAME    
    a2dp_msg_media_configure_ind - Handles A2DP library message A2DP_CODEC_CONFIGURE_IND.
*/
static void a2dp_msg_media_configure_ind(A2DP_CODEC_CONFIGURE_IND_T *message)
{
    bool accept = FALSE;
    
#ifdef INCLUDE_APPLICATION_A2DP_CODEC_CONFIGURATION    
    
    switch (message->local_seid)
    {
        case A2DP_SEID_SBC:
        {
            /* SBC needs to be configured */
            accept = a2dp_configure_sbc(message);
        } 
        break;
        
        case A2DP_SEID_FASTSTREAM:
        {
            /* Faststream needs to be configured */
            accept = a2dp_configure_faststream(message);
        } 
        break;
        
        case A2DP_SEID_APTX:
        {
            /* APT-X needs to be configured */
            accept = a2dp_configure_aptx(message);
        } 
        break;
        
        case A2DP_SEID_APTX_LOW_LATENCY:
        {
            /* APT-X Low Latency needs to be configured */
            accept = a2dp_configure_aptxLowLatency(message);
        } 
        break;
    }
    
#endif /* INCLUDE_APPLICATION_A2DP_CODEC_CONFIGURATION */

    /* send response */
    A2dpCodecConfigureResponse(message->device_id, accept, message->local_seid, message->size_codec_service_caps, message->codec_service_caps);
}


/****************************************************************************
NAME    
    a2dp_msg_media_start_ind - Handles A2DP library message A2DP_MEDIA_START_IND.
*/
static void a2dp_msg_media_start_ind(const A2DP_MEDIA_START_IND_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));

        /* can't find our A2DP task instance, very bad, reject the start request */
        A2dpMediaStartResponse(message->device_id, message->stream_id, FALSE);
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {        
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:        
        {           
            /* check audio mode */
            if (theSource->audio_data.audio_voip_music_mode == AUDIO_VOIP_MODE)
            {
                /* attempt to switch audio mode from VOIP to MUSIC if remote device starts streaming */
                audio_set_voip_music_mode(AUDIO_MUSIC_MODE);
            }
            
            /* accept the stream start request and then go on to setup the audio */
            A2dpMediaStartResponse(message->device_id, message->stream_id, TRUE);
            a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_STREAMING);
        }
        break;
               
        default:
        {         
            /* not in a valid state to start a stream, reject the start request */
            A2dpMediaStartResponse(message->device_id, message->stream_id, FALSE);
            a2dp_msg_unhandled_state(inst);
        }
        break;
    } 
}


/****************************************************************************
NAME    
    a2dp_msg_media_start_cfm - Handles A2DP library message A2DP_MEDIA_START_CFM.
*/
static void a2dp_msg_media_start_cfm(const A2DP_MEDIA_START_CFM_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {                
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:        
        {           
            if (message->status == a2dp_success)
            {
                a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_STREAMING);
            }
            else
            {
                a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA);
            }
        }
        break;
               
        default:
        {         
            a2dp_msg_unhandled_state(inst);
        }
        break;
    } 
}


/****************************************************************************
NAME    
    a2dp_msg_media_suspend_ind - Handles A2DP library message A2DP_MEDIA_SUSPEND_IND.
*/
static void a2dp_msg_media_suspend_ind(const A2DP_MEDIA_SUSPEND_IND_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {                
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING: 
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        {           
            a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_SUSPENDED);
        }
        break;
               
        default:
        {         
            a2dp_msg_unhandled_state(inst);
        }
        break;
    } 
}


/****************************************************************************
NAME    
    a2dp_msg_media_suspend_cfm - Handles A2DP library message A2DP_MEDIA_SUSPEND_CFM.
*/
static void a2dp_msg_media_suspend_cfm(const A2DP_MEDIA_SUSPEND_CFM_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {                        
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        {          
            if (message->status == a2dp_success)
            {
                a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_SUSPENDED);
            }
            else
            {
                a2dp_set_state(inst, A2DP_STATE_DISCONNECTING_MEDIA);
            }
        }
        break;
               
        default:
        {         
            a2dp_msg_unhandled_state(inst);
        }
        break;
    } 
}


/****************************************************************************
NAME    
    a2dp_msg_link_loss_ind - Handles A2DP library message A2DP_SIGNALLING_LINKLOSS_IND.
*/
static void a2dp_msg_link_loss_ind(const A2DP_SIGNALLING_LINKLOSS_IND_T *message)
{
    a2dpInstance *inst = a2dp_get_instance_from_device_id(message->device_id);
    
    if (inst == NULL)
    {
        A2DP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTING_LOCAL:
        case A2DP_STATE_CONNECTING_REMOTE:
        case A2DP_STATE_CONNECTED_SIGNALLING:
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        case A2DP_STATE_CONNECTING_MEDIA_REMOTE:
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        case A2DP_STATE_DISCONNECTING_MEDIA:
        case A2DP_STATE_DISCONNECTING:
        {
            /* Disconnect A2DP audio if it is routed */
            audio_a2dp_disconnect(inst->a2dp_device_id, inst->media_sink);
            /* reset A2DP instance */
            a2dp_init_instance(inst);
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }        
}


/****************************************************************************
NAME    
    a2dp_msg_internal_signalling_connect_req - Handles A2DP application message to connect signalling.
*/
static void a2dp_msg_internal_signalling_connect_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_DISCONNECTED:
        {                    
            /* update state */
            a2dp_set_state(inst, A2DP_STATE_CONNECTING_LOCAL);
        }
        break;
        
        default:
        {     
             /* must send confirmation that connection attempt failed */
             MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);
        }
        break;
    }
}


/****************************************************************************
NAME    
    a2dp_msg_internal_media_open_req - Handles A2DP application message to open media.
*/
static void a2dp_msg_internal_media_open_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
            
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_SIGNALLING:
        {
            a2dp_set_state(inst, A2DP_STATE_CONNECTING_MEDIA_LOCAL);
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }        
}


/****************************************************************************
NAME    
    a2dp_msg_internal_media_start_req - Handles A2DP application message to start media.
*/
static void a2dp_msg_internal_media_start_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
            
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        {         
            a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL);
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }        
}


/****************************************************************************
NAME    
    a2dp_msg_internal_force_disconnect_req - Handles A2DP application message to force a disconnection.
*/
static void a2dp_msg_internal_force_disconnect_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
            
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_DISCONNECTING:
        {
            /* Disconnect A2DP audio if it is routed */
            audio_a2dp_disconnect(inst->a2dp_device_id, inst->media_sink);
            /* just reset state as can't issue a disconnect */
            a2dp_init_instance(inst);
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }      
}


/****************************************************************************
NAME    
    a2dp_msg_internal_signalling_disconnect_req - Handles A2DP application message to disconnect the signalling.
*/
static void a2dp_msg_internal_signalling_disconnect_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
            
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_SIGNALLING:
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        case A2DP_STATE_CONNECTING_MEDIA_REMOTE:
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        case A2DP_STATE_DISCONNECTING_MEDIA:
        {
            a2dp_set_state(inst, A2DP_STATE_DISCONNECTING);
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }      
}


/****************************************************************************
NAME    
    a2dp_msg_internal_media_suspend_req - Handles A2DP application message to suspend the media.
*/
static void a2dp_msg_internal_media_suspend_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
            
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        {
            a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL);
        }
        break;
        
        default:
        {
            a2dp_msg_unhandled_state(inst);
        }
        break;
    }      
}


/****************************************************************************
NAME    
    a2dp_msg_internal_connect_audio_req - Handles A2DP application message to connect audio.
*/
static void a2dp_msg_internal_connect_audio_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
    
    if (theSource->audio_data.audio_voip_music_mode != AUDIO_MUSIC_MODE)
    {
        A2DP_MSG_DEBUG(("  NOT MUSIC mode - returning\n"));
        return;
    }
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_SIGNALLING:
        {                    
            /* open media */
            A2DP_MSG_DEBUG(("SetState conn_media_local\n"));
            a2dp_set_state(inst, A2DP_STATE_CONNECTING_MEDIA_LOCAL);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        {
            A2DP_MSG_DEBUG(("suspend: send media start\n"));
            MessageSendConditionally(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_START_REQ, 0, &inst->a2dp_suspending);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        {
            A2DP_MSG_DEBUG(("connected: send media start\n"));
            MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_START_REQ, 0);            
        }
        break;
        
        case A2DP_STATE_DISCONNECTING_MEDIA:
        {
            A2DP_MSG_DEBUG(("disconnecting media\n"));
            if (inst->a2dp_suspending)
            {
                A2DP_MSG_DEBUG(("disconnecting: send connec_audio\n"));
                MessageSendConditionally(&inst->a2dpTask, A2DP_INTERNAL_CONNECT_AUDIO_REQ, 0, &inst->a2dp_suspending);
            }
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        {
            /* make sure audio is routed if audio is available */
            A2DP_MSG_DEBUG(("media streaming\n"));
            if ((theSource->audio_data.audio_routed != AUDIO_ROUTED_A2DP) &&
                (theSource->audio_data.audio_voip_music_mode == AUDIO_MUSIC_MODE))
            {                
                a2dp_enter_state_connected_media_streaming(inst, A2DP_STATE_CONNECTED_MEDIA_STREAMING);
            }
        }
        break;
        
        default:
        {     
             A2DP_MSG_DEBUG(("a2dp_msg_internal_connect_audio_req unhandled %d\n",a2dp_get_state(inst)));
             a2dp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    a2dp_msg_internal_media_close_req - Handles A2DP application message to close media channel.
*/
static void a2dp_msg_internal_media_close_req(Task task)
{
    a2dpInstance *inst = (a2dpInstance *) task;
    
    A2DP_MSG_DEBUG_INST(inst);
    
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTED_MEDIA:
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        {                    
            /* close media */
            a2dp_set_state(inst, A2DP_STATE_DISCONNECTING_MEDIA);
        }
        break;
        
        default:
        {     
             a2dp_msg_unhandled_state(inst);
        }
        break;
    }
}
