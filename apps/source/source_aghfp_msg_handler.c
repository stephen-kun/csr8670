/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_aghfp_msg_handler.c

DESCRIPTION
    AGHFP profile message handling.
    
*/

/* header for this file */
#include "source_aghfp_msg_handler.h"
/* application header files */
#include "source_aghfp.h"
#include "source_app_msg_handler.h"
#include "source_connection_mgr.h"
#include "source_debug.h"
#include "source_init.h"
#include "source_private.h"
/* profile/library headers */
#include <aghfp.h>
/* VM headers */
#include <panic.h>
#include <stdlib.h>


#ifdef DEBUG_AGHFP_MSG
    #define AGHFP_MSG_DEBUG(x) DEBUG(x)
#else
    #define AGHFP_MSG_DEBUG(x)
#endif     


/* Display unhandled states in Debug Mode */
#define aghfp_msg_unhandled_state(inst) AGHFP_MSG_DEBUG(("AGHFP MSG Ignored; state [%d] inst[0x%x]\n", aghfp_get_state(inst), (uint16)inst));


/* AGHFP library message handling functions */
static void aghfp_msg_init_cfm(const AGHFP_INIT_CFM_T *message);
static void aghfp_msg_slc_connect_cfm(const AGHFP_SLC_CONNECT_CFM_T *message);
static void aghfp_msg_slc_connect_ind(const AGHFP_SLC_CONNECT_IND_T *message);
static void aghfp_msg_slc_disconnect_ind(const AGHFP_SLC_DISCONNECT_IND_T *message);
static void aghfp_msg_audio_connect_ind(const AGHFP_AUDIO_CONNECT_IND_T *message);
static void aghfp_msg_audio_connect_cfm(const AGHFP_AUDIO_CONNECT_CFM_T *message);
static void aghfp_msg_audio_disconnect_ind(const AGHFP_AUDIO_DISCONNECT_IND_T *message);
static void aghfp_msg_caller_id_setup(const AGHFP_CALLER_ID_SETUP_IND_T *message);
/* AGHFP application message handling functions */
static void aghfp_msg_internal_connect_req(Task task);
static void aghfp_msg_internal_connect_audio_req(Task task);
static void aghfp_msg_internal_disconnect_audio_req(Task task);
static void aghfp_msg_internal_disconnect_req(Task task);
static void aghfp_msg_internal_create_call_req(Task task, const AGHFP_INTERNAL_CALL_CREATE_REQ_T *message);
static void aghfp_msg_internal_send_ring(Task task);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    aghfp_msg_handler - Handles AGHFP messages.
*/
void aghfp_msg_handler(Task task, MessageId id, Message message)
{  
    /* AGHFP profile library messages */
    switch (id)
    {
/******************/
/* INITIALISATION */
/******************/
        
        /* confirmation of the initialisation of the AGHFP library */
        case AGHFP_INIT_CFM:
        {          
            AGHFP_MSG_DEBUG(("AGHFP_INIT_CFM [%d]:\n", ((AGHFP_INIT_CFM_T *)message)->status));            
            
            aghfp_msg_init_cfm((AGHFP_INIT_CFM_T *)message);
        }
        return;

/******************/
/* CONNECTION     */
/******************/
        
        /* confirmation of a connection attempt */
        case AGHFP_SLC_CONNECT_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SLC_CONNECT_CFM [%d]:\n", ((AGHFP_SLC_CONNECT_CFM_T *)message)->status));   
            
            aghfp_msg_slc_connect_cfm((AGHFP_SLC_CONNECT_CFM_T *)message);
        }
        return;
        
        /* indication that a remote device is trying to connect */
        case AGHFP_SLC_CONNECT_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SLC_CONNECT_IND:\n"));
            
            aghfp_msg_slc_connect_ind((AGHFP_SLC_CONNECT_IND_T *)message);            
        }
        return;
        
        /* indication that the connection has been lost */
        case AGHFP_SLC_DISCONNECT_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SLC_DISCONNECT_IND:\n")); 
            
            aghfp_msg_slc_disconnect_ind((AGHFP_SLC_DISCONNECT_IND_T *)message);  
        }
        return;

/******************/
/* AUDIO          */
/******************/
        
        /* confirmation of an audio connection request */
        case AGHFP_AUDIO_CONNECT_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_AUDIO_CONNECT_CFM [%d]:\n", ((AGHFP_AUDIO_CONNECT_CFM_T *)message)->status));   
            aghfp_msg_audio_connect_cfm((AGHFP_AUDIO_CONNECT_CFM_T *)message);
        }
        return;
        
        /* indication that a remote device is trying to connect audio */
        case AGHFP_AUDIO_CONNECT_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_AUDIO_CONNECT_IND:\n"));
            aghfp_msg_audio_connect_ind((AGHFP_AUDIO_CONNECT_IND_T *)message);
        }
        return;

        /* indication that the audio has disconnected */
        case AGHFP_AUDIO_DISCONNECT_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_AUDIO_DISCONNECT_IND:\n")); 
            aghfp_msg_audio_disconnect_ind((AGHFP_AUDIO_DISCONNECT_IND_T *)message);
        }
        return;
 
        /* indication that the audio parameters need to be supplied */
        case AGHFP_APP_AUDIO_PARAMS_REQUIRED_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_APP_AUDIO_PARAMS_REQUIRED_IND:\n"));
            aghfp_send_audio_params();
        }
        return;
        
        /* indication of microphone gain sent from remote device */
        case AGHFP_SYNC_MICROPHONE_GAIN_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SYNC_MICROPHONE_GAIN_IND:\n"));
            aghfp_mic_gain_ind(((AGHFP_SYNC_MICROPHONE_GAIN_IND_T *)message)->gain);
        }
        return;
        
        /* indication of speaker volume sent from remote device */
        case AGHFP_SYNC_SPEAKER_VOLUME_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SYNC_SPEAKER_VOLUME_IND:\n"));  
            aghfp_speaker_volume_ind(((AGHFP_SYNC_SPEAKER_VOLUME_IND_T *)message)->volume);
        }
        return;

        /* confirmation of setting microphone gain */
        case AGHFP_SET_REMOTE_MICROPHONE_GAIN_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SET_REMOTE_MICROPHONE_GAIN_CFM:\n"));
        }
        return;
        
        /* confirmation of setting speaker volume */
        case AGHFP_SET_REMOTE_SPEAKER_VOLUME_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SET_REMOTE_SPEAKER_VOLUME_CFM:\n"));
        }
        return;
        
        case AGHFP_VOICE_RECOGNITION_SETUP_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_VOICE_RECOGNITION_SETUP_IND:\n"));                        
            
            /* send state to USB host */
            usb_send_device_command_voice_recognition(((AGHFP_VOICE_RECOGNITION_SETUP_IND_T *)message)->enable);
                    
            /* voip mode */
            aghfp_voip_mode_answer_call();
        }    
        return;
        
        /* HF wants voice recognition  */
        case AGHFP_VOICE_RECOGNITION_ENABLE_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_VOICE_RECOGNITION_ENABLE_CFM:\n"));            
        }
        return;        
        
        case AGHFP_NREC_SETUP_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_NREC_SETUP_IND:\n"));
            /* noise reduction not supported so send error */
            AGHFP_MSG_DEBUG(("  - unsupported, send ERROR\n"));
            AghfpSendError(((AGHFP_NREC_SETUP_IND_T *)message)->aghfp);
        }    
        return;
        
        case AGHFP_TRANSMIT_DTMF_CODE_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_TRANSMIT_DTMF_CODE_IND:\n"));
            /* Ignore this message */
            AGHFP_MSG_DEBUG(("  - ignored\n"));            
        }
        return;

/******************/
/* CALL           */
/******************/
        
        /* confirmation of sending call indicator */
        case AGHFP_SEND_CALL_INDICATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_CALL_INDICATOR_CFM:\n")); 
        }
        return;

        /* confirmation of sending call setup indicator */
        case AGHFP_SEND_CALL_SETUP_INDICATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_CALL_SETUP_INDICATOR_CFM:\n")); 
        }
        return;

        /* confirmation of sending ring alert */
        case AGHFP_SEND_RING_ALERT_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_RING_ALERT_CFM:\n"));   
        }
        return;

        /* confirmation of sending inband ring enable */
        case AGHFP_INBAND_RING_ENABLE_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INBAND_RING_ENABLE_CFM:\n"));  
        }
        return;

        /* confirmation of sending battery charge */
        case AGHFP_SEND_BATT_CHG_INDICATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_BATT_CHG_INDICATOR_CFM:\n"));   
        }
        return;

        /* confirmation of sending service indicator */
        case AGHFP_SEND_SERVICE_INDICATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_SERVICE_INDICATOR_CFM:\n"));  
        }
        return;

        /* confirmation of sending network operator */
        case AGHFP_NETWORK_OPERATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_NETWORK_OPERATOR_CFM:\n")); 
        }
        return;

        /* indication of unrecognised AT command */
        case AGHFP_UNRECOGNISED_AT_CMD_IND:
		{
            AGHFP_MSG_DEBUG(("AGHFP_UNRECOGNISED_AT_CMD_IND:\n")); 
            AghfpSendError(((AGHFP_UNRECOGNISED_AT_CMD_IND_T *)message)->aghfp);                        
		}
        return;

        /* indication of response hold status request */
	    case AGHFP_RESPONSE_HOLD_STATUS_REQUEST_IND:
		{
            AGHFP_MSG_DEBUG(("AGHFP_RESPONSE_HOLD_STATUS_REQUEST_IND:\n"));
            /* Just send OK back since we do not support Response and Hold */
            AghfpSendOk(((AGHFP_RESPONSE_HOLD_STATUS_REQUEST_IND_T *)message)->aghfp);
		}
		return;
        
        /* confirmation of sending response hold state request */
        case AGHFP_SEND_RESPONSE_HOLD_STATE_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_RESPONSE_HOLD_STATE_CFM:\n"));                         
        }
        return;
        
        /* indication of setting response hold status request */
        case AGHFP_SET_RESPONSE_HOLD_STATUS_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SET_RESPONSE_HOLD_STATUS_IND:\n"));  
            /* Not in a hold state so don't need AghfpConfirmResponseHoldState so just send OK*/
            AghfpSendOk(((AGHFP_SET_RESPONSE_HOLD_STATUS_IND_T *)message)->aghfp);
        }
        return;
        
        /* confirmation of response hold state request */
        case AGHFP_CONFIRM_RESPONSE_HOLD_STATE_CFM:
        {            
            AGHFP_CONFIRM_RESPONSE_HOLD_STATE_CFM_T *msg = (AGHFP_CONFIRM_RESPONSE_HOLD_STATE_CFM_T *)message;
            
            AGHFP_MSG_DEBUG(("AGHFP_CONFIRM_RESPONSE_HOLD_STATE_CFM:\n"));
            
            if (msg->status == aghfp_success)
            {
           
            }
            else
            {
           
            }                       
        }
        return;   
        
        /* indication of indicator activation */
        case AGHFP_INDICATORS_ACTIVATION_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INDICATORS_ACTIVATION_IND:\n"));
        }
        return;
        
        /* indication of indicator event reporting */
        case AGHFP_INDICATOR_EVENTS_REPORTING_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INDICATOR_EVENTS_REPORTING_IND: mode[%d] ind[%d]\n",
                             ((AGHFP_INDICATOR_EVENTS_REPORTING_IND_T *)message)->mode,
                             ((AGHFP_INDICATOR_EVENTS_REPORTING_IND_T *)message)->ind));
        }
        return;
        
        /* HF wants to answer call */
        case AGHFP_ANSWER_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_ANSWER_IND:\n"));
            /* Respond with OK */
            AghfpSendOk(((AGHFP_ANSWER_IND_T *)message)->aghfp);
            /* send USB Vendor command which answers call to host */ 
            usb_send_device_command_accept_call();
            /* VOIP mode */
            aghfp_voip_mode_answer_call();
        }
        return;
        
        /* HF wants to hang up call */
        case AGHFP_CALL_HANG_UP_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_CALL_HANG_UP_IND:\n"));
            /* Respond with OK */
            AghfpSendOk(((AGHFP_CALL_HANG_UP_IND_T *)message)->aghfp);       
            /* send USB Vendor command which hangs up call to host */ 
            usb_send_device_command_reject_call();
            /* send USB HID command for HangUp */
            usb_send_hid_hangup();
        }
        return;
        
        /* HF wants to dial number */
        case AGHFP_DIAL_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_DIAL_IND:\n"));
            /* send USB Vendor command which dials number to host */             
            usb_send_device_command_dial_number(((AGHFP_DIAL_IND_T *)message)->size_number, ((AGHFP_DIAL_IND_T *)message)->number);
            /* VOIP mode */
            aghfp_voip_mode_answer_call();
        }
        return;
        
        /* HF wants to dial number from memory  */
        case AGHFP_MEMORY_DIAL_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_MEMORY_DIAL_IND:\n"));
            /* send USB Vendor command which dials memory location to host */             
            usb_send_device_command_dial_memory(((AGHFP_MEMORY_DIAL_IND_T *)message)->size_number, ((AGHFP_MEMORY_DIAL_IND_T *)message)->number);
        }
        return;
        
        /* HF wants a last number redial  */
        case AGHFP_LAST_NUMBER_REDIAL_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_LAST_NUMBER_REDIAL_IND:\n"));
            /* send USB Vendor command which dials last number to host */             
            usb_send_device_command_dial_last();
            /* send USB HID command for HangUp */
            usb_send_hid_hangup();
        }
        return;
                
        case AGHFP_NETWORK_OPERATOR_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_NETWORK_OPERATOR_IND:\n"));
            /* send network operator */
            AGHFP_MSG_DEBUG(("  - respond with operator name VoIP\n"));
            AghfpSendNetworkOperator(((AGHFP_NETWORK_OPERATOR_IND_T *)message)->aghfp, 
                                     0, 
                                     theSource->aghfp_data.aghost_state.size_network_operator, 
                                     theSource->aghfp_data.aghost_state.network_operator);
        }
        return;
        
        case AGHFP_CURRENT_CALLS_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_CURRENT_CALLS_IND:\n"));
            if (((AGHFP_CURRENT_CALLS_IND_T *)message)->last_idx == 0)
            {
                /* Current calls list required, send over USB to host */
                usb_send_device_command_current_calls();            
            }
        }    
        return;
        
        case AGHFP_SUBSCRIBER_NUMBER_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SUBSCRIBER_NUMBER_IND:\n"));
            /* Ignore this message for now */
            AGHFP_MSG_DEBUG(("  - ignored\n"));
            AghfpSendSubscriberNumbersComplete(((AGHFP_SUBSCRIBER_NUMBER_IND_T *)message)->aghfp);
        }  
        return; 
        
        case AGHFP_SUBSCRIBER_NUMBER_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SUBSCRIBER_NUMBER_CFM:\n"));
        }
        return;
        
        case AGHFP_PHONE_NUMBER_REQUEST_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_PHONE_NUMBER_REQUEST_IND:\n"));
            /* Ignore this requiest, send ERROR */
            AGHFP_MSG_DEBUG(("  - ignored, send ERROR\n"));
            AghfpSendError(((AGHFP_PHONE_NUMBER_REQUEST_IND_T *)message)->aghfp);
        }    
        return;
        
        case AGHFP_SET_CALLER_ID_DETAILS_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SET_CALLER_ID_DETAILS_CFM:\n"));
        }
        return;
        
        case AGHFP_CALLER_ID_SETUP_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_CALLER_ID_SETUP_IND:\n"));
            aghfp_msg_caller_id_setup((AGHFP_CALLER_ID_SETUP_IND_T *)message);
        }
        return;
        
        case AGHFP_CALL_WAITING_SETUP_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_CALL_WAITING_SETUP_IND:\n"));
        }
        return;
        
        case AGHFP_CALL_INDICATIONS_STATUS_REQUEST_IND:
        {
            AGHFP_MSG_DEBUG(("AGHFP_CALL_INDICATIONS_STATUS_REQUEST_IND:\n"));
            AGHFP_MSG_DEBUG(("    avail[%d] call[%d] call_setup[%d] call_held[%d] signal[%d] roam[%d] batt[%d]\n",
                                                theSource->aghfp_data.aghost_state.availability,
                                                theSource->aghfp_data.aghost_state.call_status,
                                                theSource->aghfp_data.aghost_state.call_setup_status,
                                                theSource->aghfp_data.aghost_state.call_held_status,
                                                theSource->aghfp_data.aghost_state.signal,
                                                theSource->aghfp_data.aghost_state.roam_status,
                                                theSource->aghfp_data.aghost_state.batt));
            
            AghfpCallIndicatorsStatusResponse(((AGHFP_CALL_INDICATIONS_STATUS_REQUEST_IND_T *)message)->aghfp,
                                                theSource->aghfp_data.aghost_state.availability,
                                                theSource->aghfp_data.aghost_state.call_status,
                                                theSource->aghfp_data.aghost_state.call_setup_status,
                                                theSource->aghfp_data.aghost_state.call_held_status,
                                                theSource->aghfp_data.aghost_state.signal,
                                                theSource->aghfp_data.aghost_state.roam_status,
                                                theSource->aghfp_data.aghost_state.batt);
        }
        return;
        
        case AGHFP_SEND_SIGNAL_INDICATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_SIGNAL_INDICATOR_CFM:\n"));
        }
        return;
        
        case AGHFP_SEND_ROAM_INDICATOR_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_ROAM_INDICATOR_CFM:\n"));
        }
        return;
        
        case AGHFP_SEND_CALLER_ID_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_CALLER_ID_CFM %d:\n", ((AGHFP_SEND_CALLER_ID_CFM_T *)message)->status));
        }
        return;
        
        case AGHFP_SEND_CALL_WAITING_NOTIFICATION_CFM:
        {
            AGHFP_MSG_DEBUG(("AGHFP_SEND_CALL_WAITING_NOTIFICATION_CFM:\n"));
        }
        return;
                
        
/******************/
/* CSR FEATURES   */
/******************/
        
        /* indication of remote CSR supported features */
        case AGHFP_CSR_SUPPORTED_FEATURES_IND:
		{
			AGHFP_MSG_DEBUG(("AGHFP_CSR_SUPPORTED_FEATURES_IND:\n"));
		}
		return;
	
        /* indication of CSR feature negotiation */
	    case AGHFP_CSR_FEATURE_NEGOTIATION_IND:
		{
			AGHFP_MSG_DEBUG(("AGHFP_CSR_FEATURE_NEGOTIATION_IND:\n"));
		}
		return;

        /* indication of CSR feature negotiation request */
	    case AGHFP_CSR_FEATURE_NEGOTIATION_REQ_IND:
		{
			AGHFP_MSG_DEBUG(("AGHFP_CSR_FEATURE_NEGOTIATION_REQ_IND:\n"));
		}
		return;

        default:       
        {
	    	/* fall through to next switch statement */
        }
        break;
    }
    
    /* AGHFP Internal Application Messages */
    switch (id)
    {
        /* internal message to connect AGHFP */
        case AGHFP_INTERNAL_CONNECT_REQ:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_CONNECT_REQ:\n"));
            aghfp_msg_internal_connect_req(task);
        }
        return;
        
        /* internal message to connect AGHFP audio */
        case AGHFP_INTERNAL_CONNECT_AUDIO_REQ:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_CONNECT_AUDIO_REQ:\n"));
            aghfp_msg_internal_connect_audio_req(task);
        }
        return;
        
        /* internal message to disconnect AGHFP audio */
        case AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ:\n"));
            aghfp_msg_internal_disconnect_audio_req(task);
        }
        return;
        
        /* internal message to disconnect AGHFP */
        case AGHFP_INTERNAL_DISCONNECT_REQ:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_DISCONNECT_REQ:\n"));
            aghfp_msg_internal_disconnect_req(task);
        }
        return;
        
        /* internal message to create a call */
        case AGHFP_INTERNAL_CALL_CREATE_REQ:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_CALL_CREATE_REQ:\n"));
            aghfp_msg_internal_create_call_req(task, (AGHFP_INTERNAL_CALL_CREATE_REQ_T *)message);
        }
        return;
        
        /* internal message to send RING */
        case AGHFP_INTERNAL_RING_ALERT:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_RING_ALERT:\n"));
            aghfp_msg_internal_send_ring(task);
        }
        return;
        
        /* internal message to send Voice Recognition enable\disable */
        case AGHFP_INTERNAL_VOICE_RECOGNITION:
        {
            AGHFP_MSG_DEBUG(("AGHFP_INTERNAL_VOICE_RECOGNITION:\n"));
            aghfp_voice_recognition_ind(((AGHFP_INTERNAL_VOICE_RECOGNITION_T *)message)->enable);
        }
        break;
        
        default:
        {
            AGHFP_MSG_DEBUG(("AGHFP MSG Unhandled[0x%x]\n",id));
        }
        return;
    }       
}


/****************************************************************************
NAME    
    aghfp_msg_init_cfm - Handles AGHFP library message AGHFP_INIT_CFM.
*/
static void aghfp_msg_init_cfm(const AGHFP_INIT_CFM_T *message)
{
    /* AGHFP registered */
    if (message->status == aghfp_success)
    {
        /* store AGHFP pointer */
        theSource->aghfp_data.aghfp = message->aghfp;
        
        /* get CIND requests sent to the application */
        AghfpCindStatusPollClientEnable(theSource->aghfp_data.aghfp, TRUE);
                
        /* Update init procedure - AGHFP profile is initialised */
        init_register_profiles(REGISTERED_PROFILE_AGHFP);
    }
    else
    {
        Panic();
    }
}


/****************************************************************************
NAME    
    aghfp_msg_slc_connect_cfm - Handles AGHFP library message AGHFP_SLC_CONNECT_CFM.
*/
static void aghfp_msg_slc_connect_cfm(const AGHFP_SLC_CONNECT_CFM_T *message)
{
    aghfpInstance *inst = aghfp_get_instance_from_pointer(message->aghfp);
    
    if (inst == NULL)
    {
        AGHFP_MSG_DEBUG(("  inst not found\n"));        
        return;
    }
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTING_LOCAL:
        case AGHFP_STATE_CONNECTING_REMOTE:
        case AGHFP_STATE_DISCONNECTED: /* incase a connection crossover failed */
        {
            if (message->status == aghfp_success)
            {               
                /* store that this profile is supported */
                inst->aghfp_support = AGHFP_SUPPORT_YES;
                /* store Sink for the connection */
                inst->slc_sink = message->rfcomm_sink;
                /* update the state to reflect it is connected */
                aghfp_set_state(inst, AGHFP_STATE_CONNECTED);                
                /* send USB command for audio connection state (disconnected) */
                usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_DISCONNECTED);
            }
            else
            {            
                bool security_reconnect = FALSE;
                
                if (message->status != aghfp_connect_sdp_fail_no_data)
                {
                    if (message->status == aghfp_connect_sdp_fail_no_connection)
                    {
                        /* clear current connection requests */
                        MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);
                        /* don't attempt to connect any further profiles as connection failed */
                        connection_mgr_clear_attempted_profiles();
                    }
                    else if (message->status != aghfp_connect_sdp_fail)
                    {
                        /* if connection didn't fail at SDP stage then assume HFP is supported on the remote device */
                        inst->aghfp_support = AGHFP_SUPPORT_YES;
                    }
                }
                
                if (message->status == aghfp_connect_security_reject)
                {
                    /* choose next PIN code if security rejected */
                    security_reconnect = connection_mgr_get_next_pin_code(&inst->addr);
                }
                
                if ((inst->aghfp_support == AGHFP_SUPPORT_YES) && 
                    ((states_get_state() == SOURCE_STATE_CONNECTING) || (states_get_state() == SOURCE_STATE_CONNECTED)) &&
                    ((inst->aghfp_connection_retries < theSource->ps_config->features.aghfp_max_connection_retries) ||
                     security_reconnect))
                {
                    aghfp_set_state(inst, AGHFP_STATE_DISCONNECTED);
                    /* HFP is supported but connection failed, possibly due to connection crossover - retry HFP connection */
                    MessageSendLater(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_REQ, 0, theSource->ps_config->ps_timers.aghfp_connection_failed_timer);                    
                    /* increase connection retries */
                    inst->aghfp_connection_retries++;
                }
                else
                {
                    /* reset AGHFP instance to indicate it is disconnected */
                    aghfp_init_instance(inst);
                    /* send message that has connection has failed */    
                    MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);
                }
            }
        }
        break;
        
        default:
        {           
            aghfp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    aghfp_msg_slc_connect_ind - Handles AGHFP library message AGHFP_SLC_CONNECT_IND.
*/
static void aghfp_msg_slc_connect_ind(const AGHFP_SLC_CONNECT_IND_T *message)
{
    bool accept = FALSE;
    aghfpInstance *inst = aghfp_get_instance_from_bdaddr(message->bd_addr);
    
    if (inst == NULL)
    {
        inst = aghfp_get_free_instance();
    }
        
    if (inst != NULL)
    {
        /* store that AGHFP is supported by remote device */
        inst->aghfp_support = AGHFP_SUPPORT_YES;
                    
        switch (aghfp_get_state(inst))
        {
            case AGHFP_STATE_DISCONNECTED:
            {
                if (connection_mgr_can_connect(&message->bd_addr, PROFILE_AGHFP))
                {
                    /* accept incoming connection */
                    accept = TRUE;
                    /* store address of connecting device */
                    inst->addr = message->bd_addr;
                    /* store library pointer of connecting device */
                    inst->aghfp = message->aghfp;
                    /* register incoming connection with connection manager */
                    connection_mgr_set_incoming_connection(PROFILE_AGHFP, &inst->addr);
                    
                    /* update state */
                    aghfp_set_state(inst, AGHFP_STATE_CONNECTING_REMOTE);
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
    
    AGHFP_MSG_DEBUG(("  accept = %d\n", accept));
    AghfpSlcConnectResponse(theSource->aghfp_data.aghfp, accept);
}


/****************************************************************************
NAME    
    aghfp_msg_slc_disconnect_ind - Handles AGHFP library message AGHFP_SLC_DISCONNECT_IND.
*/
static void aghfp_msg_slc_disconnect_ind(const AGHFP_SLC_DISCONNECT_IND_T *message)
{
    aghfpInstance *inst = aghfp_get_instance_from_pointer(message->aghfp);
    
    if (inst == NULL)
    {
        AGHFP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTING_LOCAL:
        case AGHFP_STATE_CONNECTING_REMOTE:
        case AGHFP_STATE_CONNECTED:
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        case AGHFP_STATE_CONNECTED_AUDIO:
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        case AGHFP_STATE_DISCONNECTING:
        {            
            if ((message->status == aghfp_disconnect_link_loss) && (theSource->ps_config->ps_timers.link_loss_reconnect_delay_timer != TIMER_NO_TIMEOUT))
            {
                AGHFP_MSG_DEBUG(("  Link-Loss\n"));
                MessageSendLater(&theSource->app_data.appTask, APP_LINKLOSS_IND, 0, D_SEC(theSource->ps_config->ps_timers.link_loss_reconnect_delay_timer));
            }            
            /* register disconnection with connection manager */
            connection_mgr_set_profile_disconnected(PROFILE_AGHFP, &inst->addr);
            /* reset AGHFP instance */
            aghfp_init_instance(inst);            
        }
        break;
        
        default:
        {
            aghfp_msg_unhandled_state(inst);
        }
        break;
    }        
}


/****************************************************************************
NAME    
    aghfp_msg_audio_connect_ind - Handles AGHFP library message AGHFP_AUDIO_CONNECT_IND.
*/
static void aghfp_msg_audio_connect_ind(const AGHFP_AUDIO_CONNECT_IND_T *message)
{
    aghfpInstance *inst = aghfp_get_instance_from_pointer(message->aghfp);
    
    if (inst == NULL)
    {
        AGHFP_MSG_DEBUG(("  inst not found\n"));
    }
    else
    {    
        switch (aghfp_get_state(inst))
        {
            case AGHFP_STATE_CONNECTED:
            case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
            {
                /* cancel queued outgoing audio connection */
                MessageCancelAll(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_AUDIO_REQ);
                /* set state */
                aghfp_set_state(inst, AGHFP_STATE_CONNECTING_AUDIO_REMOTE);
                /* respond with required audio parameters */
                AghfpAudioConnectResponse(inst->aghfp, TRUE, theSource->ps_config->hfp_audio.sync_pkt_types, &theSource->ps_config->hfp_audio.audio_params);                 
            }
            return;
            
            default:
            {
                aghfp_msg_unhandled_state(inst);
            }
            break;
        }
    }    
    
    AghfpAudioConnectResponse(theSource->aghfp_data.aghfp, FALSE, 0, NULL);
}


/****************************************************************************
NAME    
    aghfp_msg_audio_connect_cfm - Handles AGHFP library message AGHFP_AUDIO_CONNECT_CFM.
*/
static void aghfp_msg_audio_connect_cfm(const AGHFP_AUDIO_CONNECT_CFM_T *message)
{
    aghfpInstance *inst = aghfp_get_instance_from_pointer(message->aghfp);
    
    if (inst == NULL)
    {
        AGHFP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
     
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        {              
            AGHFP_MSG_DEBUG(("  AGHFP Audio : cl_status:[%d] link_type[%d] audio_sink[0x%x] rx_bandwidth[0x%lx] tx_bandwidth[0x%lx] using_wbs[%d] wbs_codec[%d]\n",
                             message->cl_status,
                             message->link_type,
                             (uint16)message->audio_sink,
                             message->rx_bandwidth,
                             message->tx_bandwidth,
                             message->using_wbs,
                             message->wbs_codec
                             ));
            
            if (message->status == aghfp_audio_connect_success)
            {
                inst->link_type = message->link_type;
	            inst->audio_sink = message->audio_sink;
                inst->using_wbs = message->using_wbs;
    
                aghfp_set_state(inst, AGHFP_STATE_CONNECTED_AUDIO);
                
                /* send USB command for audio connection state (connected) */
                usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_CONNECTED);
                
                /* send USB command to stop music */
                usb_send_media_hid_command(opid_stop, 0);
            }
            else
            {
                aghfp_set_state(inst, AGHFP_STATE_CONNECTED);
            }
        }
        return;
            
        default:
        {
            aghfp_msg_unhandled_state(inst);
        }
        break;
    }    
}


/****************************************************************************
NAME    
    aghfp_msg_audio_disconnect_ind - Handles AGHFP library message AGHFP_AUDIO_DISCONNECT_IND.
*/
static void aghfp_msg_audio_disconnect_ind(const AGHFP_AUDIO_DISCONNECT_IND_T *message)
{
    aghfpInstance *inst = aghfp_get_instance_from_pointer(message->aghfp);
    
    if (inst == NULL)
    {
        AGHFP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
     
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTED_AUDIO:  
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        {                          
            aghfp_set_state(inst, AGHFP_STATE_CONNECTED);
            
            /* send USB command for audio connection state (disconnected) */
            usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_DISCONNECTED);
        }
        return;
            
        default:
        {
            aghfp_msg_unhandled_state(inst);
        }
        break;
    }    
}


/****************************************************************************
NAME    
    aghfp_msg_caller_id_setup - Handles AGHFP library message AGHFP_CALLER_ID_SETUP_IND.
*/
static void aghfp_msg_caller_id_setup(const AGHFP_CALLER_ID_SETUP_IND_T *message)
{
    aghfpInstance *inst = aghfp_get_instance_from_pointer(message->aghfp);
    
    if (inst == NULL)
    {
        AGHFP_MSG_DEBUG(("  inst not found\n"));
        return;
    }
     
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTING_LOCAL:
        case AGHFP_STATE_CONNECTING_REMOTE:
        case AGHFP_STATE_CONNECTED:
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        case AGHFP_STATE_CONNECTED_AUDIO:
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        case AGHFP_STATE_DISCONNECTING:
        {                          
            inst->cli_enable = message->enable;
        }
        return;
            
        default:
        {
            aghfp_msg_unhandled_state(inst);
        }
        break;
    }        
}


/****************************************************************************
NAME    
    aghfp_msg_internal_connect_req - Handles AGHFP application message to connect a device.
*/
static void aghfp_msg_internal_connect_req(Task task)
{
    aghfpInstance *inst = (aghfpInstance *) task;
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_DISCONNECTED:
        {                    
            /* update state */
            aghfp_set_state(inst, AGHFP_STATE_CONNECTING_LOCAL);
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
    aghfp_msg_internal_connect_audio_req - Handles AGHFP application message to connect audio.
*/
static void aghfp_msg_internal_connect_audio_req(Task task)
{
    aghfpInstance *inst = (aghfpInstance *) task;
    
    if (theSource->audio_data.audio_voip_music_mode != AUDIO_VOIP_MODE)
    {
        AGHFP_MSG_DEBUG(("  NOT VOIP mode - returning\n"));
        return;
    }
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTED:
        {                    
            /* update state */
            AGHFP_MSG_DEBUG(("connected\n"));
            aghfp_set_state(inst, AGHFP_STATE_CONNECTING_AUDIO_LOCAL);
        }
        break;
        
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        {
            /* connect audio again after disconnection */
            AGHFP_MSG_DEBUG(("disconnecting audio\n"));
            MessageSendConditionally(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_AUDIO_REQ, 0, &inst->disconnecting_audio);
        }
        break;
        
        case AGHFP_STATE_CONNECTED_AUDIO:
        {
            /* make sure audio is routed if audio is available */
            AGHFP_MSG_DEBUG(("connected audio\n"));
            if ((theSource->audio_data.audio_routed != AUDIO_ROUTED_AGHFP) &&
                (theSource->audio_data.audio_voip_music_mode == AUDIO_VOIP_MODE))
            {  
                aghfp_enter_state_connected_audio(inst, AGHFP_STATE_CONNECTED_AUDIO);
            }
        }
        break;
        
        default:
        {     
             aghfp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    aghfp_msg_internal_disconnect_audio_req - Handles AGHFP application message to disconnect audio.
*/
static void aghfp_msg_internal_disconnect_audio_req(Task task)
{
    aghfpInstance *inst = (aghfpInstance *) task;
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTED_AUDIO:
        {                    
            /* update state */
            aghfp_set_state(inst, AGHFP_STATE_DISCONNECTING_AUDIO);
        }
        break;
        
        default:
        {     
             aghfp_msg_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    aghfp_msg_internal_disconnect_req - Handles AGHFP application message to disconnect connection.
*/
static void aghfp_msg_internal_disconnect_req(Task task)
{
    aghfpInstance *inst = (aghfpInstance *) task;
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTED:
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        case AGHFP_STATE_CONNECTED_AUDIO:        
        {                    
            /* update state */
            aghfp_set_state(inst, AGHFP_STATE_DISCONNECTING);
        }
        break;
        
        default:
        {     
             aghfp_msg_unhandled_state(inst);
        }
        break;
    }
}


static void aghfp_msg_internal_create_call_req(Task task, const AGHFP_INTERNAL_CALL_CREATE_REQ_T *req)
{
    aghfpInstance *inst = (aghfpInstance *) task;
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTED:
        case AGHFP_STATE_CONNECTED_AUDIO:
        
        {            
            /* send message to create call */
            AghfpCallCreate(theSource->aghfp_data.aghfp, req->call_type, FALSE);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        {
            MAKE_MESSAGE(AGHFP_INTERNAL_CALL_CREATE_REQ);  
            message->call_type = req->call_type;
            MessageSendConditionally(&inst->aghfpTask, AGHFP_INTERNAL_CALL_CREATE_REQ, message, &inst->connecting_audio);
        }
        break;
        
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        {
            MAKE_MESSAGE(AGHFP_INTERNAL_CALL_CREATE_REQ);  
            message->call_type = req->call_type;
            MessageSendConditionally(&inst->aghfpTask, AGHFP_INTERNAL_CALL_CREATE_REQ, message, &inst->disconnecting_audio);
        }
        break;
        
        default:
        {     
             aghfp_msg_unhandled_state(inst);
        }
        break;
    }
}


static void aghfp_msg_internal_send_ring(Task task)
{
    aghfpInstance *inst = (aghfpInstance *) task;
    
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_CONNECTED:
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        case AGHFP_STATE_CONNECTED_AUDIO:     
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        {                    
            /* send RING for incoming call */
            if (theSource->aghfp_data.aghost_state.call_setup_status == aghfp_call_setup_incoming)
            {
                AghfpSendRingAlert(theSource->aghfp_data.aghfp);
                /* Send CLI if supplied */
                if (theSource->aghfp_data.aghost_state.ring && inst->cli_enable)
                {
                    AghfpSendCallerId(theSource->aghfp_data.aghfp, 
                                      theSource->aghfp_data.aghost_state.ring->clip_type, 
                                      theSource->aghfp_data.aghost_state.ring->size_clip_number, 
                                      theSource->aghfp_data.aghost_state.ring->clip_number, 
                                      0, 
                                      NULL);
                }
            }
            
            /* queue next RING */
            MessageSendLater(&inst->aghfpTask, AGHFP_INTERNAL_RING_ALERT, 0, AGHFP_RING_ALERT_DELAY);
        }
        break;
        
        default:
        {     
             aghfp_msg_unhandled_state(inst);
        }
        break;
    }
}


