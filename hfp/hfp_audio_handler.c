/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_audio_handler.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_audio_handler.h"
#include "hfp_common.h"
#include "hfp_link_manager.h"
#include "hfp_call_handler.h"
#include "hfp_hs_handler.h"

#include "hfp_wbs_handler.h"

#include <bdaddr.h>
#include <panic.h>
#include <print.h>

/* Mask out SCO bits from the original packet type */
#define EDR_ESCO_ONLY(pkt)  ((pkt) & (sync_all_esco | sync_all_edr_esco));

/* Mask out SCO and EDR bits (inverted) from the original packet type */
#define ESCO_ONLY(pkt)      (((pkt) & sync_all_esco) | sync_all_edr_esco)

/* EV3 only */
#define EV3_SAFE            (sync_ev3 | sync_all_edr_esco)

/* Mask out eSCO and EDR bits (inverted) from the original packet type */
#define SCO_ONLY(pkt)       (((pkt) & sync_all_sco) | sync_all_edr_esco)

/* HV1 only */
#define HV1_SAFE            (sync_hv1 | sync_all_edr_esco)

/* Including each EDR eSCO bit disables the options. This bitmap therefore enables EV3 and 2EV3 */
#define WBS_PACKET_TYPE     (sync_ev3 | sync_3ev5 | sync_2ev5 | sync_3ev3 /* | sync_2ev3 */)

/* Default parameters for an eSCO connection.  These are the "S3" safe settings 
   for a 2-EV3 packet type as defined in the HFP spec. */
const hfp_audio_params default_esco_audio_params =
{
    8000,                    /* Bandwidth for both Tx and Rx */
    0x000a,                  /* Max Latency                  */
    sync_air_coding_cvsd,    /* Voice Settings               */
    sync_retx_power_usage,   /* Retransmission Effort        */
};

/* Default parameters for a SCO connection.  The max latency is sufficient to 
   support all SCO packet types - HV1, HV2 and HV3. */
const hfp_audio_params default_sco_audio_params =
{
    8000,                    /* Bandwidth for both Tx and Rx */
    0x0005,                  /* Max Latency                  */
    sync_air_coding_cvsd,    /* Voice Settings               */
    sync_retx_disabled,      /* Retransmission Effort        */
};

/* mSBC parameters for an eSCO connection. Configured to allow AG to request either 
"T1" safe settings or "T2" settings */
static const hfp_audio_params msbc_audio_params =
{
    8000,                           /* Bandwidth for both Tx and Rx */
    0x000e,                         /* Max Latency                  */
    sync_air_coding_transparent,    /* Voice Settings               */
    sync_retx_link_quality,         /* Retransmission Effort        */
};

/* "S1" safe settings for EV3 connection.  Configured to obtain best ESCO link possible. */
static const sync_config_params default_s1_sync_config_params =
{
    8000,                           /* tx_bandwidth   */
    8000,                           /* rx_bandwidth   */
    0x7,                            /* max_latency    */
    sync_air_coding_cvsd,           /* voice_settings */
    sync_retx_power_usage,          /* retx_effort    */
    (sync_ev3 | sync_all_edr_esco)  /* packet_type    */
};


/* Work out the audio parameters to use */
const hfp_audio_params* hfpAudioGetParams(hfp_link_data* link, sync_pkt_type* packet_type, const hfp_audio_params* audio_params, bool disable_override)
{
    /* If we're using mSBC */
    if(link->wbs_codec_mask == hfp_wbs_codec_mask_msbc && !disable_override)
    {
        *packet_type = WBS_PACKET_TYPE;
        return &msbc_audio_params;
    }
    
    /* If app provided audio params */
    if(audio_params)
        return audio_params;
    /* If we're using eSCO */
    if(*packet_type & sync_all_esco)
        return &default_esco_audio_params;
    /* Must be using SCO */
    return &default_sco_audio_params;
}


/* Set hfp's audio parameters to imply no connection */
static void resetAudioParams (hfp_link_data* link)
{
    link->audio_state = hfp_audio_disconnected;
    link->audio_sink  = 0;
}


/* Inform the app of the status of the audio (Synchronous) connection */
void sendAudioConnectCfmFailToApp(hfp_link_data* link, hfp_audio_connect_status status)
{
    if(status != hfp_audio_connect_success)
    {
        /* Send a cfm message to the application. */
        MAKE_HFP_MESSAGE(HFP_AUDIO_CONNECT_CFM);
        message->priority     = hfpGetLinkPriority(link);
        message->status       = status;
        message->audio_sink   = link ? link->audio_sink : 0;
        message->rx_bandwidth = 0;
        message->tx_bandwidth = 0;
        message->link_type    = sync_link_unknown;
        message->codec        = hfp_wbs_codec_mask_none;
        MessageSend(theHfp->clientTask, HFP_AUDIO_CONNECT_CFM, message);
    }
}


/* Inform the app of the status of the audio (Synchronous) disconnection */
void sendAudioDisconnectIndToApp(hfp_link_data* link, hfp_audio_disconnect_status status)
{
    /* Send a cfm message to the application. */
    hfpSendCommonCfmMessageToApp(HFP_AUDIO_DISCONNECT_IND, link, status);
}


/* Attempt to create an audio (Synchronous) connection.  Due to firmware operation, eSCO and SCO must be requested
   separately. */
static void startAudioConnectRequest(hfp_link_data* link, sync_pkt_type packet_type, const hfp_audio_params *audio_params)
{
    sync_config_params config_params;

    /* If both sides support WBS kick off codec negotiation */
    if (hfpWbsStartCodecNegotiation(link))
    {
        link->audio_state = hfp_audio_wbs_connect;
        return;
    }
    
    /* Store connection parameters for later use */
    link->audio_state              = hfp_audio_connecting;
    link->audio_packet_type        = packet_type;
    link->audio_packet_type_to_try = packet_type;
    link->audio_params             = *audio_params;
    
    /* determine if esco or edr (inverted logic) packet types requested */
    if ( packet_type & sync_all_esco )
    {
        /* set packet type as the passed in esco and edr bits */
        config_params.packet_type = EDR_ESCO_ONLY(packet_type);
        config_params.retx_effort = audio_params->retx_effort;
    }
    else
    {
        /* mask out esco and add edr bits */
        config_params.packet_type = SCO_ONLY(packet_type);
        /* No re-transmissions for SCO */            
        config_params.retx_effort = sync_retx_disabled;
    }
    
    config_params.tx_bandwidth   = audio_params->bandwidth;
    config_params.rx_bandwidth   = audio_params->bandwidth;
    config_params.max_latency    = audio_params->max_latency;
    config_params.voice_settings = audio_params->voice_settings;
        
    /* Issue a Synchronous connect request to the connection lib */
    ConnectionSyncConnectRequest(&theHfp->task, hfpGetLinkSink(link), &config_params);
}


/* Continue with attempt to create an audio (Synchronous) connection.  Due to firmware operation, eSCO and SCO must be requested
   separately. */
static void continueAudioConnectRequest(hfp_link_data* link)
{
    /* On entry, link->audio_packet_type will contain the packet types last attempted.
       Continue with connection attempt if we tried a packet type > hv1 last time around. */
    if ( link->audio_packet_type_to_try != HV1_SAFE )
    {
        sync_config_params  config_params;
        const sync_config_params* config = (const sync_config_params*) &config_params;
        
        if((link->audio_packet_type_to_try & sync_all_edr_esco) != sync_all_edr_esco)
        {
            /* If EDR bits attempted, try esco only by removing SCO and EDR bits */
            link->audio_packet_type_to_try = ESCO_ONLY(link->audio_packet_type);
        }
        else if((link->audio_packet_type_to_try & sync_all_esco) && (link->audio_packet_type_to_try != EV3_SAFE))
        {
            /* If ESCO bits attempted that weren't EV3 only try EV3 with S1 settings */
            link->audio_packet_type_to_try = EV3_SAFE;
            /* Substitute the S1 settings instead of user supplied settings */
            config = &default_s1_sync_config_params;
        }
        else if(link->audio_packet_type_to_try == EV3_SAFE)
        {
            /* Now try all enabled sco packet bits */
            link->audio_packet_type_to_try = SCO_ONLY(link->audio_packet_type);
            /* Disable retransmits for SCO */
            link->audio_params.retx_effort = sync_retx_disabled;
        }
        else 
        {
            /* Now down to SCO packet types, try HV1 only before giving up */
            link->audio_packet_type_to_try = HV1_SAFE;
        }
        
        config_params.packet_type    = link->audio_packet_type_to_try;
        config_params.tx_bandwidth   = link->audio_params.bandwidth;
        config_params.rx_bandwidth   = link->audio_params.bandwidth;
        config_params.retx_effort    = link->audio_params.retx_effort;
        config_params.max_latency    = link->audio_params.max_latency;
        config_params.voice_settings = link->audio_params.voice_settings;
        
        ConnectionSyncConnectRequest(&theHfp->task, hfpGetLinkSink(link), config);
    }
    else
    {   /* All connection attempts have failed - give up */
        resetAudioParams(link);
    
        /* Inform app that connect failed */
        sendAudioConnectCfmFailToApp(link, hfp_audio_connect_failure);
    }
}


/****************************************************************************
NAME    
    hfpHandleAudioConnectReq

DESCRIPTION
    Transfer the audio from the AG to the HF or vice versa depending on which
    device currently has it.

RETURNS
    void
*/
void hfpHandleAudioConnectReq(const HFP_INTERNAL_AUDIO_CONNECT_REQ_T *req)
{
    hfp_link_data*           link   = req->link;
    hfp_audio_connect_status status = hfp_audio_connect_success;
    
    switch ( link->audio_state )
    {
        case hfp_audio_disconnected:
            startAudioConnectRequest(link, req->packet_type, &req->audio_params);
        break;
        
        case hfp_audio_connecting:
        case hfp_audio_accepting:
        case hfp_audio_accept_pending:
        case hfp_audio_wbs_connect:
            status = hfp_audio_connect_in_progress;
        break;
        
        case hfp_audio_disconnecting:
        case hfp_audio_connected:
            status = hfp_audio_connect_have_audio;
        break;
        
        default:
            HFP_DEBUG(("hfpHandleAudioConnectReq invalid state %d\n",link->audio_state));
        break;
    }
    /* Send fail message if status is not success */
    sendAudioConnectCfmFailToApp(link, status);
}


/****************************************************************************
NAME    
    hfpHandleSyncConnectInd

DESCRIPTION
    Incoming audio notification, accept if we recognise the sink reject
    otherwise.

RETURNS
    void
*/
void hfpHandleSyncConnectInd(const CL_DM_SYNC_CONNECT_IND_T *ind)
{
    /* Get the link (if any) for this device */
    hfp_link_data* link = hfpGetLinkFromBdaddr(&ind->bd_addr);
    
    /* Make sure its our device and audio is disconnected or WBS connecting */
    if(link && (link->audio_state == hfp_audio_disconnected || link->audio_state == hfp_audio_wbs_connect))
    {
        /* Tell the application */
        MAKE_HFP_MESSAGE(HFP_AUDIO_CONNECT_IND);
        message->priority = hfpGetLinkPriority(link);
        message->codec    = link->wbs_codec_mask ? link->wbs_codec_mask : hfp_wbs_codec_mask_cvsd;
        MessageSend(theHfp->clientTask, HFP_AUDIO_CONNECT_IND, message);
        
        link->audio_state = hfp_audio_accepting;
    }
    else if(link && link->audio_state == hfp_audio_connecting)
    {
        link->audio_state = hfp_audio_accept_pending;
    }
    else
    {
        /* Not interested in this device, reject */
        ConnectionSyncConnectResponse(&theHfp->task, &ind->bd_addr, FALSE, 0);
    }
}


/* Accept/reject an incoming audio connect request */
static void audioConnectResponse(hfp_link_data* link, bool response, sync_pkt_type packet_type, const hfp_audio_params *audio_params)
{
    bdaddr bd_addr;
    bool   have_addr = hfpGetLinkBdaddr(link, &bd_addr);
    
    if(response && have_addr)
    {
        /* Set up audio config */
        sync_config_params           config_params;
        config_params.tx_bandwidth   = audio_params->bandwidth;
        config_params.rx_bandwidth   = audio_params->bandwidth;
        config_params.max_latency    = audio_params->max_latency;
        config_params.voice_settings = audio_params->voice_settings;
        config_params.packet_type    = packet_type;
        config_params.retx_effort    = audio_params->retx_effort;
        
        /* Accept the request */
        ConnectionSyncConnectResponse(&theHfp->task, &bd_addr, TRUE, &config_params);
    }
    else
    {
        /* Reject the request */
        if(have_addr)
            ConnectionSyncConnectResponse(&theHfp->task, &bd_addr, FALSE, 0);
        
        /* App rejected or we have no bdaddr, fail and tidy up the link */
        sendAudioConnectCfmFailToApp(link, hfp_audio_connect_failure);
        resetAudioParams(link);
    }
}


/****************************************************************************
NAME    
    hfpHandleAudioConnectRes

DESCRIPTION
    Accept or reject to an incoming audio connection request from remote device.

RETURNS
    void
*/
void hfpHandleAudioConnectRes(const HFP_INTERNAL_AUDIO_CONNECT_RES_T *res)
{
    hfp_link_data*           link   = res->link;
    hfp_audio_connect_status status = hfp_audio_connect_success;
    
    /* Fail if not in hfp_audio_accepting state */
    switch ( link->audio_state )
    {
        case hfp_audio_accept_pending:
            link->audio_state = hfp_audio_connecting;
            /* Fall through */
        case hfp_audio_accepting:
            audioConnectResponse(link, res->response, res->packet_type, &res->audio_params);
        break;
        
        case hfp_audio_connecting:
            status = hfp_audio_connect_in_progress;
        break;
        
        case hfp_audio_disconnecting:   
        case hfp_audio_connected:
            status = hfp_audio_connect_have_audio;
        break;
        
        case hfp_audio_disconnected:
            status = hfp_audio_connect_failure;
        break;
        
        default:
            HFP_DEBUG(("hfpHandleAudioConnectRes invalid state %d\n",link->audio_state));
        break;
    }
    /* Send fail message if status is not success */
    sendAudioConnectCfmFailToApp(link, status);
}


/****************************************************************************
NAME    
    hfpHandleSyncConnectCfm

DESCRIPTION
    Confirmation in response to an audio (SCO/eSCO) open request indicating 
    the outcome of the Synchronous connect attempt.

RETURNS
    void
*/
void hfpHandleSyncConnectCfm(const CL_DM_SYNC_CONNECT_CFM_T *cfm)
{
    /* Get the link */
    hfp_link_data* link = hfpGetLinkFromBdaddr(&cfm->bd_addr);
    
    /* If this isn't for us ignore it silently */
    if(link)
    {
        if ( link->audio_state==hfp_audio_connecting || link->audio_state==hfp_audio_accepting || link->audio_state==hfp_audio_accept_pending )
        {
            /* Informs us of the outcome of the Synchronous connect attempt */
            if (cfm->status == hci_success)
            {
                /* Construct cfm message for the application. */
                MAKE_HFP_MESSAGE(HFP_AUDIO_CONNECT_CFM);
                message->priority     = hfpGetLinkPriority(link);
                message->status       = hfp_audio_connect_success;
                message->audio_sink   = cfm->audio_sink;
                message->rx_bandwidth = cfm->rx_bandwidth;
                message->tx_bandwidth = cfm->tx_bandwidth;
                message->link_type    = cfm->link_type;
                message->codec        = link->wbs_codec_mask ? link->wbs_codec_mask : hfp_wbs_codec_mask_cvsd;
                MessageSend(theHfp->clientTask, HFP_AUDIO_CONNECT_CFM, message);
            
                /* store the audio sink */
                link->audio_sink  = cfm->audio_sink;
                link->audio_state = hfp_audio_connected;
                
                /* Update the link call state if required*/
                hfpHandleCallAudio(link, TRUE);
                
                return;
            }
            else if( link->audio_state == hfp_audio_connecting )
            {
                /* This step failed, move onto next stage of connection attempt */
                continueAudioConnectRequest(link);
                return;
            }
            else if( link->audio_state == hfp_audio_accept_pending )
            {
                /* Notify the app of pending SYNC connect ind */
                MAKE_HFP_MESSAGE(HFP_AUDIO_CONNECT_IND);
                message->priority = hfpGetLinkPriority(link);
                MessageSend(theHfp->clientTask, HFP_AUDIO_CONNECT_IND, message);
                return;
            }
        }
        
        /* Either got here in odd state or incoming sync failed, tidy up the link */
        resetAudioParams(link);
        
        /* Inform app that connect failed */
        sendAudioConnectCfmFailToApp(link, hfp_audio_connect_failure);
    }
    /* sco connection made with HFP link not connected */
    else
    {
        /* Inform app that connection was made with no link */
        if (cfm->status == hci_success)
        {
            /* Construct cfm message for the application. */
            MAKE_HFP_MESSAGE(HFP_AUDIO_CONNECT_CFM);
            message->priority     = hfp_invalid_link;
            message->status       = hfp_audio_connect_no_hfp_link;
            message->audio_sink   = cfm->audio_sink;
            message->rx_bandwidth = cfm->rx_bandwidth;
            message->tx_bandwidth = cfm->tx_bandwidth;
            message->link_type    = cfm->link_type;
            message->codec        = link->wbs_codec_mask ? link->wbs_codec_mask : hfp_wbs_codec_mask_cvsd;
            MessageSend(theHfp->clientTask, HFP_AUDIO_CONNECT_CFM, message);
        }       
    }
}


/* Disconnect an existing audio (Synchronous) connection */
static void audioDisconnectRequest(hfp_link_data* link)
{
    /* Send a disconnect request to the connection lib */
    link->audio_state = hfp_audio_disconnecting;
    ConnectionSyncDisconnect(link->audio_sink, hci_error_oetc_user);
}


/****************************************************************************
NAME
    hfpHandleAudioDisconnectReq

DESCRIPTION
    Attempt to disconnect the audio (Synchronous) connection.

RETURNS
    void
*/
void hfpHandleAudioDisconnectReq(hfp_link_data* link)
{
    switch ( link->audio_state )
    {
        case hfp_audio_disconnected:
        case hfp_audio_connecting:
        case hfp_audio_accepting:
        case hfp_audio_accept_pending:
            /* Audio already with AG - indicate a fail for this attempt */
            sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_no_audio);
        break;
        case hfp_audio_disconnecting:   
            /* Already attempting to close an audio connection - indicate a fail for this attempt */
            sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_in_progress);
        break;
        case hfp_audio_connected:
            audioDisconnectRequest(link);
        break;
        default:
            HFP_DEBUG(("hfpHandleAudioDisconnectReq invalid state %d\n",link->audio_state));
        break;
    }
}


/****************************************************************************
NAME    
    hfpManageSyncDisconnect

DESCRIPTION
    Used to inform hfp of a synchronous (audio) disconnection.
    
RETURNS
    void
*/
void hfpManageSyncDisconnect(hfp_link_data* link)
{
    if ( link->audio_state!=hfp_audio_disconnected )
    {
        /* Reset the audio handle */
        resetAudioParams(link);
        sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_success);
    }
}


/****************************************************************************
NAME    
    hfpHandleSyncDisconnectInd

DESCRIPTION
    Audio (Synchronous) connection has been disconnected 

RETURNS
    void
*/
void hfpHandleSyncDisconnectInd(const CL_DM_SYNC_DISCONNECT_IND_T *ind)
{
    hfp_link_data* link = hfpGetLinkFromAudioSink(ind->audio_sink);
    
    /* If it's not our sink, silently ignore this indication */
    if ( link )
    {
        if ( link->audio_state==hfp_audio_connected || link->audio_state==hfp_audio_disconnecting )
        { 
            /* Inform the app */ 
            if (ind->status == hci_success)
            {
                hfpManageSyncDisconnect(link);
                
                /* Update the link call state if required*/
                hfpHandleCallAudio(link, FALSE);
            }
            else
            {
                /* Disconnect has failed, we are still connected - inform the app */
                sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_failure);
            }
        }
        else
        {
            /* Should never get here */
            HFP_DEBUG(("hfpHandleSyncDisconnectInd invalid state %d\n",link->audio_state));
            
            resetAudioParams(link);
    
            /* Inform app that connect failed */
            sendAudioConnectCfmFailToApp(link, hfp_audio_connect_failure);
        }
    }
}


/****************************************************************************
NAME    
    hfpHandleAudioTransferReq

DESCRIPTION
    Transfer the audio from the AG to the HF or vice versa depending on which
    device currently has it.

RETURNS
    void
*/
void hfpHandleAudioTransferReq(const HFP_INTERNAL_AUDIO_TRANSFER_REQ_T *req)
{
    hfp_link_data* link = req->link;
    hfp_audio_transfer_direction direction = req->direction;
    
    /* Work out direction if the application wasn't specific */
    if(direction == hfp_audio_transfer)
    {
        switch ( link->audio_state )
        {
            case hfp_audio_disconnected:
                direction = hfp_audio_to_hfp;
            break;
            case hfp_audio_connecting:
            case hfp_audio_accepting:
            case hfp_audio_accept_pending:
            case hfp_audio_wbs_connect:
                /* Already attempting to create an audio connection - indicate a fail for this attempt */
                sendAudioConnectCfmFailToApp(link, hfp_audio_connect_in_progress);
            break;
            case hfp_audio_disconnecting:   
                /* Already attempting to close an audio connection - indicate a fail for this attempt */
                sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_in_progress);
            break;
            case hfp_audio_connected:
                direction = hfp_audio_to_ag;
            break;
            default:
                HFP_DEBUG(("hfpHandleAudioTransferReq invalid state %d\n",link->audio_state));
            break;
        }
    }
    
    if(direction == hfp_audio_to_hfp)
    {
        /* Connect Audio */
        MAKE_HFP_MESSAGE(HFP_INTERNAL_AUDIO_CONNECT_REQ);
        message->link         = link;
        message->packet_type  = req->packet_type;
        message->audio_params = req->audio_params;
        MessageSend(&theHfp->task, HFP_INTERNAL_AUDIO_CONNECT_REQ, message);
    }
    else if(direction == hfp_audio_to_ag)
    {
        /* Disconnect Audio */
        hfpSendCommonInternalMessage(HFP_INTERNAL_AUDIO_DISCONNECT_REQ, link);
    }
}
