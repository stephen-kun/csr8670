/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_avrcp.c

DESCRIPTION
    AVRCP profile message handling.
    
*/


/* header for this file */
#include "source_avrcp_msg_handler.h"
/* application header files */
#include "source_connection_mgr.h"
#include "source_debug.h"
#include "source_init.h"
#include "source_private.h"
#include "source_usb.h"
/* profile/library headers */
#include <avrcp.h>
#include <codec.h>
/* VM headers */
#include <panic.h>
#include <sink.h>


#ifdef DEBUG_AVRCP_MSG
    #define AVRCP_MSG_DEBUG(x) DEBUG(x)
#else
    #define AVRCP_MSG_DEBUG(x)
#endif     


/* Display unhandled states in Debug Mode */
#define avrcp_msg_unhandled_state(inst) AVRCP_MSG_DEBUG(("AVRCP MSG Ignored; state [%d] inst[0x%x]\n", avrcp_get_state(inst), (uint16)inst));

#define AVRCP_MSG_DEBUG_INST(inst) AVRCP_MSG_DEBUG(("        inst[0x%x]\n", (uint16)inst))


/* AVRCP library message handling functions */
static void avrcp_msg_connect_cfm(const AVRCP_CONNECT_CFM_T *message);	
static void avrcp_msg_connect_ind(const AVRCP_CONNECT_IND_T *message);
static void avrcp_msg_disconnect_ind(const AVRCP_DISCONNECT_IND_T *message);
static void avrcp_msg_passthrough_ind(const AVRCP_PASSTHROUGH_IND_T *message);
static void avrcp_msg_unitinfo_ind(const AVRCP_UNITINFO_IND_T *message);
static void avrcp_msg_subunitinfo_ind(const AVRCP_SUBUNITINFO_IND_T *message);
static void avrcp_msg_vendordependent_ind(const AVRCP_VENDORDEPENDENT_IND_T *message);
static void avrcp_msg_vendordependent_cfm(const AVRCP_VENDORDEPENDENT_CFM_T *message);
static void avrcp_msg_volume_changed_event_ind(const AVRCP_EVENT_VOLUME_CHANGED_IND_T *message);
/* AVRCP application message handling functions */
static void avrcp_msg_internal_connect_req(Task task);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    avrcp_msg_handler - Handles AVRCP messages.
*/
void avrcp_msg_handler(Task task, MessageId id, Message message)
{  
    /* AVRCP profile library messages */
    switch (id)
    {
/******************/
/* INITIALISATION */
/******************/
        
        /* confirmation of the initialisation of the AVRCP library */
        case AVRCP_INIT_CFM:
        {
            AVRCP_MSG_DEBUG(("AVRCP_INIT_CFM [%d]:\n", ((AVRCP_INIT_CFM_T*)message)->status));            
            /* AVRCP registered */
            if (((AVRCP_INIT_CFM_T*)message)->status == avrcp_success)
            {
                init_register_profiles(REGISTERED_PROFILE_AVRCP);
            }
            else
            {
                Panic();
            }
        }
        return;
			
/******************/
/* CONNECTION     */
/******************/
        
        /* confirmation of an AVRCP connection attempt */
	    case AVRCP_CONNECT_CFM:
        {
            AVRCP_MSG_DEBUG(("AVRCP_CONNECT_CFM %d:\n", ((AVRCP_CONNECT_CFM_T *)message)->status));
            avrcp_msg_connect_cfm((AVRCP_CONNECT_CFM_T *)message);	
        }
        return;
        
        /* indication of an incoming AVRCP connection attempt */
	    case AVRCP_CONNECT_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_CONNECT_IND:\n"));
            avrcp_msg_connect_ind((AVRCP_CONNECT_IND_T *)message);	
        }
        return;
        
        /* indication of an AVRCP disconnection */
	    case AVRCP_DISCONNECT_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_DISCONNECT_IND:\n"));
            avrcp_msg_disconnect_ind((AVRCP_DISCONNECT_IND_T *)message);	
        }
        return;
	
/******************/
/* AV/C Specific  */
/******************/    

        /* confirmation of an AVRCP PassThrough request */
	    case AVRCP_PASSTHROUGH_CFM:
        {
            AVRCP_MSG_DEBUG(("AVRCP_PASSTHROUGH_CFM %d:\n", ((AVRCP_PASSTHROUGH_CFM_T *)message)->status));
        }
        return;
        
        /* indication of a remotely sent AVRCP PassThrough command */
	    case AVRCP_PASSTHROUGH_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_PASSTHROUGH_IND:\n"));
            avrcp_msg_passthrough_ind((AVRCP_PASSTHROUGH_IND_T *)message);
        }
        return;
        
        /* confirmation of an AVRCP UnitInfo request */
	    case AVRCP_UNITINFO_CFM:
        {
            AVRCP_MSG_DEBUG(("AVRCP_UNITINFO_CFM %d:\n", ((AVRCP_UNITINFO_CFM_T *)message)->status));
        }
        return;
        
        /* indication of a remotely sent AVRCP UnitInfo command */
	    case AVRCP_UNITINFO_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_UNITINFO_IND:\n"));
            avrcp_msg_unitinfo_ind((AVRCP_UNITINFO_IND_T *)message);
        }
        return;
        
        /* indication of a remotely sent AVRCP SubunitInfo command */
	    case AVRCP_SUBUNITINFO_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_SUBUNITINFO_IND:\n"));
            avrcp_msg_subunitinfo_ind((AVRCP_SUBUNITINFO_IND_T *)message);
        }
        return;
        
        /* confirmation of an AVRCP SubunitInfo request */
	    case AVRCP_SUBUNITINFO_CFM:
        {
            AVRCP_MSG_DEBUG(("AVRCP_SUBUNITINFO_CFM %d:\n", ((AVRCP_SUBUNITINFO_CFM_T *)message)->status));
        }
        return;
        	  
        /* indication of a remotely sent AVRCP VendorDependent command */
	    case AVRCP_VENDORDEPENDENT_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_VENDORDEPENDENT_IND:\n"));
            avrcp_msg_vendordependent_ind((AVRCP_VENDORDEPENDENT_IND_T *)message);
        }
        return;
        
        /* confirmation of an AVRCP VendorDependent request */
        case AVRCP_VENDORDEPENDENT_CFM:
        {
            AVRCP_MSG_DEBUG(("AVRCP_VENDORDEPENDENT_CFM %d:\n", ((AVRCP_VENDORDEPENDENT_CFM_T *)message)->status));
            avrcp_msg_vendordependent_cfm((AVRCP_VENDORDEPENDENT_CFM_T *)message);
        }
        return;
        
        /* notification of an AVRCP Volume Changed Event */
        case AVRCP_EVENT_VOLUME_CHANGED_IND:
        {
            AVRCP_MSG_DEBUG(("AVRCP_EVENT_VOLUME_CHANGED_IND:\n"));
            avrcp_msg_volume_changed_event_ind((AVRCP_EVENT_VOLUME_CHANGED_IND_T *)message);
        }
        return;
			
        default:       
        {
            
        }
        break;
    }    
    
    /* application internal AVRCP messages */
    switch (id)
    {
        /* internal message to connect AVRCP */
        case AVRCP_INTERNAL_CONNECT_REQ:
        {
            AVRCP_MSG_DEBUG(("AVRCP_INTERNAL_CONNECT_REQ:\n"));
            avrcp_msg_internal_connect_req(task);
        }
        return;
        
        /* internal message to send VendorDependent command */
        case AVRCP_INTERNAL_VENDOR_COMMAND_REQ:
        {
            AVRCP_MSG_DEBUG(("AVRCP_INTERNAL_VENDOR_COMMAND_REQ:\n"));
            avrcp_send_vendor_command(task, (AVRCP_INTERNAL_VENDOR_COMMAND_REQ_T *)message);
        }
        return;
        
        
        /* internal message to send VendorDependent command */
        case AVRCP_SOURCE_VENDOR_COMMAND_REQ:
        {
            AVRCP_MSG_DEBUG(("AVRCP_SOURCE_VENDOR_COMMAND_REQ\n"));
            avrcp_source_vendor_command((avrcpInstance *)task, 
                                      ((AVRCP_SOURCE_VENDOR_COMMAND_REQ_T *)message)->company_id,
                                      ((AVRCP_SOURCE_VENDOR_COMMAND_REQ_T *)message)->cmd_id,
                                      ((AVRCP_SOURCE_VENDOR_COMMAND_REQ_T *)message)->size_data,
                                      ((AVRCP_SOURCE_VENDOR_COMMAND_REQ_T *)message)->data);
        }
        return;
        
        default:       
        {
	    	
        }
        break;
    }
    
    /* firmware messages */
    switch (id)
    {
        /* message to indicate the Vendor data Source is now empty */ 
        case MESSAGE_SOURCE_EMPTY:
        {
            avrcpInstance *inst = (avrcpInstance *) task;
            AVRCP_MSG_DEBUG(("AVRCP MESSAGE_SOURCE_EMPTY:\n"));
            if (inst != NULL)
            {
                avrcp_free_vendor_data(inst);
            }
        }
        return;
        
        default:       
        {
	    	
        }
        break;
    }
    
    /* handle Connection library messages destined for AVRCP instance */
    switch (id)
    {
        /* confirmation of AVRCP service search */
        case CL_SDP_SERVICE_SEARCH_CFM:
        {
            avrcpInstance *inst = (avrcpInstance *) task;
            AVRCP_MSG_DEBUG(("AVRCP CL_SDP_SERVICE_SEARCH_CFM status = %u\n", ((CL_SDP_SERVICE_SEARCH_CFM_T *)message)->status));
            avrcp_sdp_search_cfm(inst, (CL_SDP_SERVICE_SEARCH_CFM_T *)message);                      
        } 
        return;
        
        default:       
        {
	    	AVRCP_MSG_DEBUG(("AVRCP MSG Unhandled[0x%x]\n", id));
        }
        return;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_connect_cfm - Handles AVRCP library message AVRCP_CONNECT_CFM.
*/
static void avrcp_msg_connect_cfm(const AVRCP_CONNECT_CFM_T *message)
{    
    avrcpInstance *inst = avrcp_get_instance_from_bdaddr(message->bd_addr);
    
    AVRCP_MSG_DEBUG(("  sink[0x%x]\n", (uint16)message->sink));
 
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        
        /* retry AVRCP connection as a crossover connection case has caused the connection attempt to stall */
        avrcp_start_connection(message->bd_addr); 
        
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTING_LOCAL:
        case AVRCP_STATE_CONNECTING_REMOTE:
        case AVRCP_STATE_DISCONNECTED: /* incase a connection crossover failed */
        {            
            if (message->status == avrcp_success)
            {
                /* store library instance */
                inst->avrcp = message->avrcp;
                avrcp_set_state(inst, AVRCP_STATE_CONNECTED);
            }
            else
            {
                if ((states_get_state() == SOURCE_STATE_CONNECTED) &&
                    (inst->avrcp_support == AVRCP_SUPPORT_YES) && 
                    (inst->avrcp_connection_retries < theSource->ps_config->features.avrcp_max_connection_retries))
                {
                    avrcp_set_state(inst, AVRCP_STATE_DISCONNECTED);
                    /* AVRCP is supported but connection failed, possibly due to connection crossover - retry AVRCP connection */
                    MessageSendLater(&inst->avrcpTask, AVRCP_INTERNAL_CONNECT_REQ, 0, theSource->ps_config->ps_timers.avrcp_connection_failed_timer);                    
                    /* increase connection retries */
                    inst->avrcp_connection_retries++;
                }
                else
                {
                    /* give up on AVRCP connection attempts */
                    avrcp_init_instance(inst);                
                }
            }
        }
        break;
        
        default:
        {      
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_connect_ind - Handles AVRCP library message AVRCP_CONNECT_IND.
*/
static void avrcp_msg_connect_ind(const AVRCP_CONNECT_IND_T *message)
{
    bool accept = FALSE;
    avrcpInstance *inst = avrcp_get_instance_from_bdaddr(message->bd_addr);
    
    if (inst == NULL)
    {
        inst = avrcp_get_free_instance();
    }
    
    if (inst == NULL)
    {
        /* Couldn't find free instance so reject so that the confirm message will be sent to the application task */           
        AvrcpConnectResponse(&theSource->app_data.appTask, message->connection_id, message->signal_id, accept);
    }
    else
    {
        AVRCP_MSG_DEBUG_INST(inst);
        
        /* store that AVRCP is supported by remote device */
        inst->avrcp_support = AVRCP_SUPPORT_YES;
        
        switch (avrcp_get_state(inst))
        {
            case AVRCP_STATE_DISCONNECTED:
            {
                if (connection_mgr_can_connect(&message->bd_addr, PROFILE_AVRCP))
                {
                    /* accept incoming connection */
                    accept = TRUE;
                    /* store remote address */
                    inst->addr = message->bd_addr;                    
                    /* update state */
                    avrcp_set_state(inst, AVRCP_STATE_CONNECTING_REMOTE);
                    DEBUG_BDADDR(inst->addr);
                }
            }
            break;
        
            default:
            {          
                avrcp_msg_unhandled_state(inst);
            }   
            break;
        }
        AvrcpConnectResponse(&inst->avrcpTask, message->connection_id, message->signal_id, accept);
    }
  
    /* Reply to connect request */
    AVRCP_MSG_DEBUG(("  accept = %d\n", accept));
}


/****************************************************************************
NAME    
    avrcp_msg_disconnect_ind - Handles AVRCP library message AVRCP_DISCONNECT_IND.
*/
static void avrcp_msg_disconnect_ind(const AVRCP_DISCONNECT_IND_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
    
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTING_LOCAL:
        case AVRCP_STATE_CONNECTING_REMOTE:
        case AVRCP_STATE_CONNECTED:
        case AVRCP_STATE_DISCONNECTING:
        {            
            avrcp_init_instance(inst);
        }
        break;
        
        default:
        {      
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_passthrough_ind - Handles AVRCP library message AVRCP_PASSTHROUGH_IND.
*/
static void avrcp_msg_passthrough_ind(const AVRCP_PASSTHROUGH_IND_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
    
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        AvrcpPassthroughResponse(message->avrcp, avctp_response_rejected);
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {            
            /* Acknowledge the request */    
            switch (message->opid)
            {
                case opid_play:
                case opid_stop:
                case opid_pause:
                case opid_rewind:
                case opid_fast_forward:
                case opid_forward:
                case opid_backward:
                case opid_volume_up:   
                case opid_volume_down:
                {
                    AVRCP_MSG_DEBUG(("  opid %d\n", message->opid));
                    {
                        if ((theSource->audio_data.audio_voip_music_mode == AUDIO_VOIP_MODE) &&
                            ((message->opid == opid_play) || (message->opid == opid_pause)))
                        {
                            if (message->opid == opid_play)
                            {
                                /* switch from VOIP mode to MUSIC mode on receiving play media command */
                                aghfp_music_mode_end_call();
                            }
                            /* ignore pause media command as already in VOIP mode and sent USB stop */
                        }
                        else
                        {
                            /* convert these AVRCP commands to USB command */
                            usb_send_media_hid_command(message->opid, message->state);
                        }
                    
                        /* The headset should accept these commands. */
                        AvrcpPassthroughResponse(message->avrcp, avctp_response_accepted);
                    }
                }
                break;
        
                default:
                {
                    /* The headset won't accept any other commands. */
                    AvrcpPassthroughResponse(message->avrcp, avctp_response_not_implemented);
                }
                break;
            }
        }
        break;
        
        default:
        {     
            avrcp_msg_unhandled_state(inst);
            AvrcpPassthroughResponse(message->avrcp, avctp_response_rejected);
        }
        break;
    }    
}


/****************************************************************************
NAME    
    avrcp_msg_unitinfo_ind - Handles AVRCP library message AVRCP_UNITINFO_IND.
*/
static void avrcp_msg_unitinfo_ind(const AVRCP_UNITINFO_IND_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
    
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {        
            /* Send the correct response to UnitInfo requests. */            
            AvrcpUnitInfoResponse(message->avrcp, TRUE, subunit_panel, 0, theSource->ps_config->company_id);
        }
        break;
        
        default:
        {       
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_subunitinfo_ind - Handles AVRCP library message AVRCP_SUBUNITINFO_IND.
*/
static void avrcp_msg_subunitinfo_ind(const AVRCP_SUBUNITINFO_IND_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
    
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {
            /* Send the correct response to SubUnitInfo requests. */
            uint8 page_data[4];
            page_data[0] = 0x48; /* subunit_type: panel; max_subunit_ID: 0 */
            page_data[1] = 0xff;
            page_data[2] = 0xff;
            page_data[3] = 0xff;
            AvrcpSubUnitInfoResponse(message->avrcp, TRUE, page_data); 
        }
        break;
        
        default:
        {        
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_vendordependent_ind - Handles AVRCP library message AVRCP_VENDORDEPENDENT_IND.
*/
static void avrcp_msg_vendordependent_ind(const AVRCP_VENDORDEPENDENT_IND_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
   
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        AvrcpVendorDependentResponse(message->avrcp, avctp_response_rejected);
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {         
           /* check the Vendor AVRCP command is one the dongle recognises */
            if ((message->company_id == theSource->ps_config->company_id) && theSource->ps_config->features.avrcp_vendor_enable)
            {
                if ((message->command_type == AVRCP_CTYPE_NOTIFICATION) && (message->size_op_data >= AVRCP_VENDOR_NOTIFICATION_DATA_LENGTH))
                {
                    if ((message->op_data[0] == AVRCP_VENDOR_PRODUCT_ID_UPPER_BYTE) && (message->op_data[1] == AVRCP_VENDOR_PRODUCT_ID_LOWER_BYTE))
                    {
                        avrcp_handle_vendor_ind(message->op_data[2]);        
                        AvrcpVendorDependentResponse(message->avrcp, avctp_response_changed);
                        return;
                    }
                }
            } 
            AvrcpVendorDependentResponse(message->avrcp, avctp_response_not_implemented);
        }
        break;
        
        default:
        {      
            avrcp_msg_unhandled_state(inst);
            AvrcpVendorDependentResponse(inst->avrcp, avctp_response_rejected);
        }
        break;
    }    
}


/****************************************************************************
NAME    
    avrcp_msg_vendordependent_cfm - Handles AVRCP library message AVRCP_VENDORDEPENDENT_CFM.
*/
static void avrcp_msg_vendordependent_cfm(const AVRCP_VENDORDEPENDENT_CFM_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
    
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {
            if ((message->status == avrcp_unsupported) || (message->status == avrcp_rejected))
            {
                /* store that the Vendor commands are not accepted by the remote device, so as not to send them again */
                inst->remote_vendor_support = AVRCP_SUPPORT_NO;
            }
            inst->pending_vendor_command = FALSE;
        }
        break;
        
        default:
        {        
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_volume_changed_event_ind - Handles AVRCP library message AVRCP_EVENT_VOLUME_CHANGED_IND.
*/
static void avrcp_msg_volume_changed_event_ind(const AVRCP_EVENT_VOLUME_CHANGED_IND_T *message)
{
    avrcpInstance *inst = avrcp_get_instance_from_pointer(message->avrcp);
    
    if (inst == NULL)
    {
        AVRCP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {
            if ((message->response == avctp_response_interim) || (message->response == avctp_response_changed))
            {
                uint8 volume = message->volume / AVRCP_ABS_VOL_STEP_CHANGE;
                
                AVRCP_MSG_DEBUG(("  volume ind[%d] current volume[%d]\n", message->volume, theSource->volume_data.speaker_vol));
                
                if (a2dp_get_number_connections() == 1)
                {
                    /* send a volume changed message to the USB host if 1 A2DP connection only,
                        otherwise remote device A could change the volume of remote device B */
                    if (theSource->volume_data.speaker_vol < volume)
                    {
                        /* volume has increased so send VOL_UP to USB host */
                        usb_send_media_hid_command(opid_volume_up, 0);
                    }
                    else if (theSource->volume_data.speaker_vol > volume)
                    {
                        /* volume has decreased so send VOL_DOWN to USB host */
                        usb_send_media_hid_command(opid_volume_down, 0);
                    }
                }
                
                if (message->response == avctp_response_changed)
                {
                    /* re-register to receive volume changes */
                    avrcp_register_volume_changes(inst);
                }
            }
        }
        break;
        
        default:
        {        
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_msg_internal_connect_req - Handles AVRCP application message to initiate AVRCP connection.
*/
static void avrcp_msg_internal_connect_req(Task task)
{
    avrcpInstance *inst = (avrcpInstance *) task;
    
    AVRCP_MSG_DEBUG_INST(inst);
    
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_DISCONNECTED:
        {
            avrcp_set_state(inst, AVRCP_STATE_CONNECTING_LOCAL);
        }
        break;
        
        default:
        {
            avrcp_msg_unhandled_state(inst);
        }
        break;
    }
}
