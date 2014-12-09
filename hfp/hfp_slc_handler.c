/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_slc_handler.c        

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_common.h"
#include "hfp_link_manager.h"
#include "hfp_service_manager.h"
#include "hfp_parse.h"
#include "hfp_rfc.h"
#include "hfp_sdp.h"
#include "hfp_send_data.h"
#include "hfp_slc_handler.h"
#include "hfp_audio_handler.h"
#include "hfp_init.h"
#include "hfp_wbs.h"

#include <bdaddr.h>
#include <panic.h>
#include <stdio.h>
#include <string.h>
#include <sink.h>
#include <print.h>

#define stringLen(string) (sizeof((string))-1)

/* Tidy up SLC on connection */
static void hfpSlcConnectTidy(hfp_link_data* link)
{
    /* Issue a request to unregister the service record */
    if(link->owns_service)
        hfpUnregisterServiceRecord(link->service);
            
    /* Set the link state to slc complete */
    hfpSetLinkSlcState(link, hfp_slc_complete);
            
    /* Disable noise reduction/echo cancelation on the AG */
    hfpSendCommonInternalMessage(HFP_INTERNAL_AT_NREC_REQ, link);
}


/****************************************************************************
NAME    
    hfpSendSlcConnectCfmToApp

DESCRIPTION
    Send a HFP_SLC_CONNECT_CFM message to the app telling it the outcome
    of the connect attempt.

RETURNS
    void
*/
void hfpSendSlcConnectCfmToApp(hfp_link_data* link, const bdaddr* bd_addr, hfp_connect_status status)
{
    if(link && (link->ag_link_loss_state != hfp_link_loss_none))
    {
        if (status == hfp_connect_success)
            hfpSlcConnectTidy(link);
        
        /* We're trying to recover from link loss... keep going */
        hfpHandleRfcommLinkLossComplete(link, status);
    }
    else
    {
        MAKE_HFP_MESSAGE(HFP_SLC_CONNECT_CFM);
        message->status   = status;
        message->sink     = hfpGetLinkSink(link);
        message->priority = hfpGetLinkPriority(link);
        message->profile  = hfpLinkGetProfile(link);
        /* Try and get bdaddr from the link data */
        if(!hfpGetLinkBdaddr(link, &message->bd_addr) && bd_addr)
            message->bd_addr = *bd_addr;
        
        /* If the connect succeeded need to tidy up a few things */
        if(link)
        {
            if (status == hfp_connect_success)
                hfpSlcConnectTidy(link);
            else if (status != hfp_connect_failed_busy)
                hfpLinkReset(link, TRUE);
        }
        MessageSend(theHfp->clientTask, HFP_SLC_CONNECT_CFM, message);
    }
}

/****************************************************************************
NAME    
    hfpSendSlcDisconnectIndToApp

DESCRIPTION
    Send a HFP_SLC_DISCONNECT_IND message to the app notifying it that
    the SLC has been disconnected.

RETURNS
    void
*/
void hfpSendSlcDisconnectIndToApp(hfp_link_data* link, hfp_disconnect_status status)
{
    MAKE_HFP_MESSAGE(HFP_SLC_DISCONNECT_IND);
    message->status   = status;
    message->priority = hfpGetLinkPriority(link);
    (void)hfpGetLinkBdaddr(link, &message->bd_addr);
    
    /* Tidy up if valid link was disconnected */
    if(status != hfp_disconnect_no_slc)
    {
        /* Reset the connection related state */
        hfpLinkReset(link, TRUE);

        /* Cancel the AT response timeout message because we'll have no more AT cmds being sent */
        (void) MessageCancelAll(&theHfp->task, hfpGetLinkTimeoutMessage(link, HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND));
    }
    MessageSend(theHfp->clientTask, HFP_SLC_DISCONNECT_IND, message);
}


/****************************************************************************
NAME    
    hfpHandleBrsfRequest

DESCRIPTION
    Send AT+BRSF to the AG.

RETURNS
    void
*/
void hfpHandleBrsfRequest(hfp_link_data* link)
{
    char brsf[15];

    /* Create the AT cmd we're sending */
    sprintf(brsf, "AT+BRSF=%d\r", theHfp->hf_supported_features);

    /* Send the AT cmd over the air */
    hfpSendAtCmd(link, strlen(brsf), brsf, hfpBrsfCmdPending);
}


/****************************************************************************
NAME    
    hfpHandleBacRequest

DESCRIPTION
    Send AT+BAC= to the AG.

RETURNS
    void
*/
void hfpHandleBacRequest(hfp_link_data* link)
{
    /* Safety check against misbehaving AGs; only proceed if the AG supports Codec Negotiation. */
    if(agFeatureEnabled(link, AG_CODEC_NEGOTIATION) && hfFeatureEnabled(HFP_CODEC_NEGOTIATION))
    {
        char   bac_req[20];
        uint16 check_bit;
        
        /* Create a local copy of HF supported codecs */
        hfp_wbs_codec_mask supported_codecs = theHfp->wbs_codec_mask;
        
        /* Start the AT+BAC command */
        uint8  char_idx = sprintf(bac_req, "AT+BAC=");
        
        /* Run through all bits of supported codec mask until no more set */
        for(check_bit=1; supported_codecs > 0; check_bit <<= 1)
        {
            /* Check if bit is set in the codec mask */
            if(supported_codecs & check_bit)
            {
                /* Convert this bit to codec ID and put into AT+BAC */
                char_idx += sprintf(&bac_req[char_idx], "%d,", hfpWbsCodecMaskToCodecId(supported_codecs & check_bit));
           }
            /* Clear this bit in supported codecs */
            supported_codecs &= ~(supported_codecs & check_bit);
        }
        
        /* Replace last ',' with '\r' */
        sprintf(&bac_req[char_idx-1], "\r");
        
        /* Send the AT cmd over the air */
        hfpSendAtCmd(link, char_idx, bac_req, hfpBacCmdPending);
    }
}


/****************************************************************************
NAME    
    hfpHandleCindTestRequest

DESCRIPTION
    Send AT+CIND=? to the AG.

RETURNS
    void
*/
static void hfpHandleCindTestRequest(hfp_link_data* link)
{
    /* Send the AT cmd over the air */
    char cind_test[] = "AT+CIND=?\r";
    hfpSendAtCmd(link, stringLen(cind_test), cind_test, hfpCindTestCmdPending);
}


/****************************************************************************
NAME    
    hfpHandleCindReadRequest

DESCRIPTION
    Send AT+CIND? to the AG.

RETURNS
    void
*/
static void hfpHandleCindReadRequest(hfp_link_data* link)
{
    char cind_read[] = "AT+CIND?\r";

    /* Send the AT cmd over the air */
    hfpSendAtCmd(link, stringLen(cind_read), cind_read, hfpCindReadCmdPending);
}


/****************************************************************************
NAME    
    hfpHandleCmerRequest

DESCRIPTION
    Send AT+CMER to the AG.

RETURNS
    void
*/
static void hfpHandleCmerRequest(hfp_link_data* link)
{
    const char* cmer = "AT+CMER=3, 0, 0, 1\r";

    /* Send the AT cmd over the air */
    hfpSendAtCmd(link, strlen(cmer), cmer, hfpCmerCmdPending);
}


/****************************************************************************
NAME    
    hfpHandleChldStatusRequest

DESCRIPTION
    Send AT+CHLD=? to the AG.

RETURNS
    void
*/
static void hfpHandleChldStatusRequest(hfp_link_data* link)
{
    const char* chld = "AT+CHLD=?\r";
    
    /* Only send this if both sides support TWC, otherwise SLC is complete */
    if (hfFeatureEnabled(HFP_THREE_WAY_CALLING) && agFeatureEnabled(link, AG_THREE_WAY_CALLING))
        hfpSendAtCmd(link, strlen(chld), chld, hfpChldStatusCmdPending);
}


/****************************************************************************
NAME    
    hfpSlcCheckAtAck

DESCRIPTION
    Generic handler for AT Acks during SLC establishment

RETURNS
    TRUE if Ack was successful, FALSE otherwise
*/
bool hfpSlcCheckAtAck(hfp_link_data* link, hfp_lib_status status)
{
    /* An AT command in the SLC establishment has failed */
    if(status != hfp_success)
    {
        /* If we have an RFCOMM connection we want to get rid of it */
        if(link->ag_slc_state == hfp_slc_connected  && SinkIsValid(hfpGetLinkSink(link)))
        {
            /* We have a valid RFCOMM connection still, tear it down */
            hfpSendCommonInternalMessage(HFP_INTERNAL_SLC_DISCONNECT_REQ, link);
            /* NB. When disconnecting in hfp_slc_connected this can result in two
            disconnect requests being sent to the CL. This either results in
            the CL rejecting the request with status rfcomm_disconnect_unknown_sink
            which we ignore, or BlueStack rejecting the request with RFC_INVALID_CHANNEL
            which the CL does not forward on to us. In both cases only one 
            HFP_SLC_CONNECT_CFM will be sent to the app when disconnected */
        }
        return FALSE;
    }
    return TRUE;
}


/****************************************************************************
NAME    
    hfpHandleSupportedFeaturesNotification

DESCRIPTION
    Store the AG's supported features.

RETURNS
    void
*/
void hfpHandleSupportedFeaturesNotification(hfp_link_data* link, uint16 features)
{
    /* Store the AG's supported features */
    link->ag_supported_features = features;
}


/****************************************************************************
NAME    
    hfpHandleSupportedFeaturesInd

DESCRIPTION
    Handle the supported features sent by the AG.

AT INDICATION
    +BRSF

RETURNS
    void
*/
void hfpHandleSupportedFeaturesInd(Task link_ptr, const struct hfpHandleSupportedFeaturesInd *ind)
{
    hfp_link_data* link = (hfp_link_data*)link_ptr;

    /* Deal with supported Features */
    hfpHandleSupportedFeaturesNotification(link, ind->supportedfeat);
    
    /* Send AT+BAC if supported */
    hfpHandleBacRequest(link);
}


/****************************************************************************
NAME    
    hfpHandleBrsfAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+BRSF cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleBrsfAtAck(hfp_link_data* link, hfp_lib_status status)
{
    /* Perform SDP search if BRSF failed */
    if (status != hfp_success)
        hfpGetAgSupportedFeatures(link);
    
    /* Send AT+CIND=? (or queue if AT+BAC was sent) */
    hfpHandleCindTestRequest(link);
    /* Queue up AT+CIND? */
    hfpHandleCindReadRequest(link);
}


/****************************************************************************
NAME    
    hfpHandleBacAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+BAC cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleBacAtAck(hfp_link_data* link, hfp_lib_status status)
{
    /* AG didn't understand AT+BAC so clear its codec negotiation bit */
    if(link->ag_slc_state == hfp_slc_connected && status != hfp_success)
        link->ag_supported_features &= ~AG_CODEC_NEGOTIATION;
}


/****************************************************************************
NAME    
    hfpHandleCindTestAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+CIND=? cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleCindTestAtAck(hfp_link_data* link, hfp_lib_status status)
{
    /* Queue AT+CMER if successful */
    if(hfpSlcCheckAtAck(link, status))
        hfpHandleCmerRequest(link);
}


/****************************************************************************
NAME    
    hfpHandleCindReadAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+CIND? cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleCindReadAtAck(hfp_link_data* link, hfp_lib_status status)
{
    /* Queue AT+CHLD=? if successful */
    if(hfpSlcCheckAtAck(link, status))
        hfpHandleChldStatusRequest(link);
}


/****************************************************************************
NAME    
    hfpHandleCmerAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+CMER cmd. If we're
    not getting call hold params from the AG then the SLC is complete.

RETURNS
    void
*/
void hfpHandleCmerAtAck(hfp_link_data* link, hfp_lib_status status)
{
    if (hfpSlcCheckAtAck(link, status))
    {
        /* If TWC not enabled this is the last AT command in the SLC establishment */
        if (!hfFeatureEnabled(HFP_THREE_WAY_CALLING) || !agFeatureEnabled(link, AG_THREE_WAY_CALLING))
            hfpSendSlcConnectCfmToApp(link, NULL, hfp_connect_success);
    }
}


/****************************************************************************
NAME    
hfpHandleCallHoldSupportInd

DESCRIPTION
    Call hold parameters received and parsed. 

RETURNS
    void
*/
static void hfpHandleCallHoldSupportInd(Task link_ptr)
{
    hfp_link_data* link = (hfp_link_data*)link_ptr;
    /* Inform the app the SLC has been established */
    hfpSendSlcConnectCfmToApp(link, NULL, hfp_connect_success);
}


/****************************************************************************
NAME    
    hfpHandleCallHoldInfo

DESCRIPTION
    Generic call hold parameter handler. Called when we don't have a 
    dictionary match for the call hold string.

AT INDICATION
    +CHLD

RETURNS
    void
*/
void hfpHandleCallHoldInfo(Task link_ptr, const struct hfpHandleCallHoldInfo *ind)
{
    hfpHandleCallHoldSupportInd(link_ptr);
}


/****************************************************************************
NAME    
    hfpHandleCallHoldInfoCommon

DESCRIPTION
    Call hold parameter handler for one very common set of call hold parameters -
    namely when the string looks like "\r\n+CHLD: (0,1,1x,2,2x,3,4)\r\n". 

AT INDICATION
    +CHLD

RETURNS
    void
*/
void hfpHandleCallHoldInfoCommon(Task link_ptr)
{
    hfpHandleCallHoldSupportInd(link_ptr);
}


/****************************************************************************
NAME    
    hfpHandleCallHoldInfoRange

DESCRIPTION
    Generic call hold parameter handler used when the params are specified as 
    a range of values. Called when we don't have a dictionary match for the 
    call hold string.

AT INDICATION
    +CHLD

RETURNS
    void
*/
void hfpHandleCallHoldInfoRange(Task link_ptr, const struct hfpHandleCallHoldInfoRange *ind)
{
    hfpHandleCallHoldSupportInd(link_ptr);
}


/****************************************************************************
NAME
    hfpHandleDisconnectRequest

DESCRIPTION
    We're in the right state and have received a disconnect request, 
    handle it here.

RETURNS
    void
*/
void hfpHandleDisconnectRequest(hfp_link_data* link)
{
    if (link->audio_sink)
    {
        MAKE_HFP_MESSAGE(HFP_INTERNAL_SLC_DISCONNECT_REQ);
        message->link = link;
        /* If we have a SCO/eSCO active need to tear that down first */
        hfpHandleAudioDisconnectReq(link);
        /* Queue up the SLC disconnect message */
        MessageSendConditionally(&theHfp->task, HFP_INTERNAL_SLC_DISCONNECT_REQ, message, (uint16 *) &link->audio_sink);    /*lint !e740 */
    }
    else 
    {
        /* If recovering from link loss or timed out we need to be sure to force disconnect */
        if (link->ag_link_loss_state == hfp_link_loss_recovery || link->ag_link_loss_state == hfp_link_loss_timeout)
        {
            /* Link was recovering from link loss, stop the procedure */
            MessageId message_id = hfpGetLinkTimeoutMessage(link, HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_0_IND);
            MessageCancelFirst(&theHfp->task, message_id);
            hfpHandleRfcommLinkLossAbort(link, TRUE);
        }
        /* Either no link loss or we aborted link loss recovery. Now bring down the link. */
        else
        {
            /* Can only get here from searching/outgoing/incoming/connected/complete */
            if(link->ag_slc_state == hfp_slc_searching)
            {
                /* Notify application of connection failure (link will be reset so SDP results ignored) */
                hfpSendSlcConnectCfmToApp(link, NULL, hfp_connect_sdp_fail);
            }
            else
            {
                /* Request the connection lib aborts/disconnects the RFCOMM connection */
                ConnectionRfcommDisconnectRequest(&theHfp->task, hfpGetLinkSink(link));
            }
        }
    }
}
