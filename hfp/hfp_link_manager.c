/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_link_manager.c

DESCRIPTION
    The link manager provides commonly used functionality for accessing links
    in hfp_task_data.

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_link_manager.h"
#include "hfp_common.h"
#include "hfp_sdp.h"
#include "bdaddr.h"

#include <sink.h>
#include <string.h>
#include <print.h>


/****************************************************************************
NAME
    hfpLinkSetup

DESCRIPTION
    Setup a link 

RETURNS
    void
*/
void hfpLinkSetup(hfp_link_data* link, hfp_service_data* service, const bdaddr* bd_addr, Sink sink, hfp_slc_state state)
{
    /* Don't change link priority if it already has one */
    if(hfpGetLinkPriority(link) == hfp_invalid_link)
    {
        /* Set the priority of this link */
        if(hfpGetLinkFromPriority(hfp_primary_link))
            hfpSetLinkPriority(link, hfp_secondary_link);
        else
            hfpSetLinkPriority(link, hfp_primary_link);
    }
    
    PRINT(("Link priority %X\n", link->priority));
    
    /* Reserve the service for incoming connections */
    if(state == hfp_slc_incoming)
    {
        link->owns_service = TRUE;
        service->busy = TRUE;
    }
    
    /* Set up link params */
    link->service = service;
    hfpSetLinkBdaddr(link, bd_addr);
    hfpSetLinkSink(link, sink);
    hfpSetLinkSlcState(link, state);
}


/****************************************************************************
NAME
    hfpLinkReset

DESCRIPTION
    Reset all the connection related state in this function.

RETURNS
    void
*/
void hfpLinkReset(hfp_link_data* link, bool promote_secondary)
{
    /* Free extra indicator indexes stored for this link */
    if(link->ag_supported_indicators.extra_indicator_idxs)
        free(link->ag_supported_indicators.extra_indicator_idxs);
    
    /* If link was using a service */
    if(link->service && link->owns_service)
    {
        /* Release the service */
        link->service->busy = FALSE;
        /* Register service with SDP if it was hidden and no other
           service is visible for the same profile */
        hfpRegisterServiceRecord(link->service);
    }
    
    /* Send call state indication if call state not idle */
    if(link->ag_call_state != hfp_call_state_idle)
        hfpSetLinkCallState(link, hfp_call_state_idle);
    
    /* Zero the hfp_link_data struct */
    memset(link, 0, sizeof(hfp_link_data));
    
    /* Reset the AG's supported features to default vals as specified in the HFP spec */
    link->ag_supported_features = (AG_THREE_WAY_CALLING | AG_IN_BAND_RING);
    
    /* Check if we need to promote a secondary link */
    if(promote_secondary)
        hfpSetLinkPriority(hfpGetLinkFromPriority(hfp_secondary_link), hfp_primary_link);
}


/****************************************************************************
NAME    
    hfpSetLinkSink

DESCRIPTION
    Set the Sink for a given link

RETURNS
    void
*/
void hfpSetLinkSink(hfp_link_data* link, Sink sink)
{
    link->identifier.sink = sink;
}

/****************************************************************************
NAME    
    hfpGetLinkSink

DESCRIPTION
    Get the Sink for a given link

RETURNS
    The link's Sink if successful, otherwise NULL.
*/
Sink hfpGetLinkSink(hfp_link_data* link)
{
    /* If sink is not set it will be NULL, just need to check for NULL ptr */
    if(link)
        return link->identifier.sink;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpSetLinkBdaddr

DESCRIPTION
    Set the bdaddr for a given link

RETURNS
    void
*/
void hfpSetLinkBdaddr(hfp_link_data* link, const bdaddr* bd_addr)
{
    link->identifier.bd_addr = *bd_addr;
}


/****************************************************************************
NAME
    hfpSetLinkSlcState

DESCRIPTION
    Set the SLC state for a given link

RETURNS
    TRUE if state transition was allowed, FALSE otherwise
*/
void hfpSetLinkSlcState(hfp_link_data* link, hfp_slc_state slc_state)
{
    link->ag_slc_state = slc_state;
}


/****************************************************************************
NAME
    hfpSetLinkCallState

DESCRIPTION
    Set the call state for a given link

RETURNS
    TRUE if state transition was allowed, FALSE otherwise
*/
void hfpSetLinkCallState(hfp_link_data* link, hfp_call_state call_state)
{
    if(link->ag_call_state != call_state)
    {

        /* Call state of a link has changed, tell the app */
        MAKE_HFP_MESSAGE(HFP_CALL_STATE_IND);
        message->priority   = hfpGetLinkPriority(link);
        message->call_state = call_state;

        /*record the first incoming call link*/
        if(call_state == hfp_call_state_incoming)
        {
            if(theHfp->first_incoming_call == hfp_invalid_link)
            {
                theHfp->first_incoming_call = message->priority;
            }
        }
        else
        {
            if(theHfp->first_incoming_call == message->priority)
            {
                theHfp->first_incoming_call = hfp_invalid_link;
            }
        }

        MessageSend(theHfp->clientTask, HFP_CALL_STATE_IND, message);

        /* Update the link's call state */
        link->ag_call_state = call_state;
    }
}


/****************************************************************************
NAME    
    hfpGetLinkBdaddr

DESCRIPTION
    Get the bdaddr for a given link

RETURNS
    If successful the bdaddr pointed to by bd_addr will be set to the link's
    bdaddr. If not successful this will be zero'ed.
*/
bool hfpGetLinkBdaddr(hfp_link_data* link, bdaddr* bd_addr)
{
    if(link && link->ag_slc_state > hfp_slc_disabled)
    {
        /* Before hfp_slc_connected link is identified by bdaddr */
        *bd_addr = link->identifier.bd_addr;
        return TRUE;
    }
    BdaddrSetZero(bd_addr);
    return FALSE;
}


/****************************************************************************
NAME    
    hfpGetLinkFromSink

DESCRIPTION
    Get the link data corresponding to a given Sink

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetLinkFromSink(Sink sink)
{
    hfp_link_data*  link;
    
    /* Don't match a NULL sink */
    if(sink != NULL)
    {
        for_all_links(link)
        {
            if(link->ag_slc_state <= hfp_slc_disabled)
            {
                /* Ignore - can't possibly be a match */
            }
            else if(link->ag_slc_state < hfp_slc_outgoing)
            {
                /* Before hfp_slc_outgoing link is identified by bdaddr */
                typed_bdaddr check_addr;
                /* If we can get a bdaddr from the sink and it matches then return the link */
                if(SinkGetBdAddr(sink, &check_addr) && BdaddrIsSame(&check_addr.addr, &link->identifier.bd_addr))
                    return link;
            }
            else
            {
                /* Once RFCOMM is established link is identified by sink */
                if(link->identifier.sink == sink)
                    return link;
            }
        }
    }
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetLinkFromBdaddr

DESCRIPTION
    Get the link data corresponding to a given bdaddr

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetLinkFromBdaddr(const bdaddr* bd_addr)
{
    hfp_link_data*  link;
    
    for_all_links(link)
    {
        bdaddr link_addr;
        
        if(hfpGetLinkBdaddr(link, &link_addr) && BdaddrIsSame(&link_addr, bd_addr))
            return link;
    }
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetLinkFromAudioSink

DESCRIPTION
    Get the link data corresponding to a given audio Sink

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetLinkFromAudioSink(Sink sink)
{
    hfp_link_data* link;
    
    for_all_links(link)
    {
        if(link->audio_state < hfp_audio_connected)
        {
            typed_bdaddr bd_addr;
            typed_bdaddr link_addr;
            /* Get bdaddr from the audio sink and match with that */
            if(SinkGetBdAddr(sink, &bd_addr) && hfpGetLinkBdaddr(link, &link_addr.addr) && BdaddrIsSame(&link_addr.addr, &bd_addr.addr))
                return link;
        }
        else
        {
            /* We have an audio sink stored, match that instead */
            if(link->audio_sink == sink)
                return link;
        }
    }
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetLinkFromSlcState

DESCRIPTION
    Get link data for the first link in the given SLC state

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
static hfp_link_data* hfpGetLinkFromSlcState(hfp_slc_state state)
{
    hfp_link_data*  link;
    
    for_all_links(link)
        if(link->ag_slc_state == state)
            return link;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetIdleLink

DESCRIPTION
    Get link data for the first link in the idle SLC state

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetIdleLink(void)
{
    hfp_link_data*  link;
    
    for_all_links(link)
        if(link->ag_slc_state == hfp_slc_idle && link->ag_link_loss_state != hfp_link_loss_recovery)
            return link;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetLinkFromAudioState

DESCRIPTION
    Get link data for the first link in the given audio state

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetLinkFromAudioState(hfp_audio_connect_state audio_state)
{
    hfp_link_data*  link;
    
    for_all_links(link)
        if(link->audio_state == audio_state)
            return link;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetLinkFromService

DESCRIPTION
    Get link data for the link using the given service

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetLinkFromService(hfp_service_data* service)
{
    hfp_link_data*  link;
    
    for_all_links(link)
        if(link->service == service && link->owns_service)
            return link;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpSetLinkPriority

DESCRIPTION
    Set the priority of a link

RETURNS
    void
*/
void hfpSetLinkPriority(hfp_link_data* link, hfp_link_priority priority)
{
    if(link) link->priority = priority;
}


/****************************************************************************
NAME    
    hfpGetLinkPriority

DESCRIPTION
    Get the priority of a link

RETURNS
    void
*/
hfp_link_priority hfpGetLinkPriority(hfp_link_data* link)
{
    if(link)
        return link->priority;
    else
        return hfp_invalid_link;
}


/****************************************************************************
NAME    
    hfpGetLinkFromPriority

DESCRIPTION
    Get a link from it's priority

RETURNS
    Pointer to the corresponding hfp_link_data if successful. Otherwise NULL.
*/
hfp_link_data* hfpGetLinkFromPriority(hfp_link_priority priority)
{
    hfp_link_data*  link;
    
    if(theHfp && theHfp->initialised && priority != hfp_invalid_link)
        for_all_links(link)
            if(link->priority == priority)
                return link;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetLinkTimeoutMessage

DESCRIPTION
    Because we have two links that could have pending commands we need 
    separate timeout messages for each link. This function is used to get
    the timeout message corresponding to a given link.

RETURNS
    The MessageId for the timeout message corresponding to the link.
*/
MessageId hfpGetLinkTimeoutMessage(hfp_link_data* link, MessageId timeout_base)
{
    bool link_is_zero_idx = (link == &theHfp->links[0]);
    
    switch(timeout_base)
    {
        case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND:
            return link_is_zero_idx ? HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND : HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_1_IND;
            
        case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_0_IND:
            return link_is_zero_idx ? HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_0_IND : HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_1_IND;
        
        case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_0_IND:
            return link_is_zero_idx ? HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_0_IND : HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_1_IND;
        
        case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_0_IND:
            return link_is_zero_idx ? HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_0_IND : HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_1_IND;
            
        default:
            HFP_ASSERT_FAIL(("Timeout requested for invalid base\n"));
            return 0;
    }
}


/****************************************************************************
NAME    
    hfpGetLinkFromTimeoutMessage

DESCRIPTION
    This function is used in handling the above timeouts, we need to know
    which link a command has timed out from.

RETURNS
    The link corresponding to the timeout MessageId
*/
hfp_link_data* hfpGetLinkFromTimeoutMessage(MessageId id)
{
    switch(id)
    {
        case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND:
        case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_0_IND:
        case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_0_IND:
        case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_0_IND:
            return &theHfp->links[0];
            
        case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_1_IND:
        case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_1_IND:
        case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_1_IND:
        case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_1_IND:
            return &theHfp->links[1];
            
        default:
            return NULL;
    }
}


/****************************************************************************
NAME    
    hfpLinkGetProfile

DESCRIPTION
    Get the profile being used by a link (if any)

RETURNS
    The profile if one is in use, otherwise hfp_profile_none
*/
hfp_profile hfpLinkGetProfile(hfp_link_data* link)
{
    if(link && link->service)
        return link->service->profile;
    else
        return hfp_no_profile;
}


/****************************************************************************
NAME    
    hfpLinkIsHsp

DESCRIPTION
    Check if a link is using HSP

RETURNS
    TRUE if it is, FALSE if not
*/
bool hfpLinkIsHsp(hfp_link_data* link)
{
    return supportedProfileIsHsp(hfpLinkGetProfile(link));
}


/****************************************************************************
NAME    
    hfpLinkIsHfp

DESCRIPTION
    Check if a link is using HFP

RETURNS
    TRUE if it is, FALSE if not
*/
bool hfpLinkIsHfp(hfp_link_data* link)
{
    return supportedProfileIsHfp(hfpLinkGetProfile(link));
}


/****************************************************************************
NAME
    hfpLinkIsHfp106

DESCRIPTION
    Check if a link is using HFP 1.6

RETURNS
    TRUE if it is, FALSE if not
*/
bool hfpLinkIsHfp106(hfp_link_data* link)
{
    return supportedProfileIsHfp106(hfpLinkGetProfile(link));
}


/****************************************************************************
NAME    
    hfpLinkDisable

DESCRIPTION
    Disable or enable a link. This will fail if the link is invalid. It will
    also fail if attempting to disable a link that is not idle, or attempting
    to enable a link that is not disabled.

RETURNS
    TRUE if successful, FALSE otherwise
*/
static bool hfpLinkDisable(hfp_link_data* link, bool disable)
{
    if(!link) return FALSE;
    
    if(disable)
    {
        if(link->ag_slc_state != hfp_slc_idle)
            return FALSE;
        PRINT(("0x%X disabled\n", (uint16)link));
        link->ag_slc_state = hfp_slc_disabled;
    }
    else
    {
        if(link->ag_slc_state != hfp_slc_disabled)
            return FALSE;
        PRINT(("0x%X enabled\n", (uint16)link));
        link->ag_slc_state = hfp_slc_idle;
    }
    return TRUE;
}

/****************************************************************************
NAME    
    HfpLinkGetBdaddr

DESCRIPTION
    External function to get the bdaddr of a given link

RETURNS
    TRUE if successful, FALSE otherwise
*/
bool HfpLinkGetBdaddr(hfp_link_priority priority, bdaddr* bd_addr)
{
    hfp_link_data* link = hfpGetLinkFromPriority(priority);
    return hfpGetLinkBdaddr(link, bd_addr);
}


/****************************************************************************
NAME    
    HfpLinkGetSlcSink

DESCRIPTION
    External function to get the slc Sink of a given link

RETURNS
    TRUE if successful, FALSE otherwise
*/
bool HfpLinkGetSlcSink(hfp_link_priority priority, Sink* sink)
{
    hfp_link_data* link = hfpGetLinkFromPriority(priority);
    *sink = hfpGetLinkSink(link);
    return (*sink) ? TRUE : FALSE;
}


/****************************************************************************
NAME    
    HfpLinkGetAudioSink

DESCRIPTION
    External function to get the audio Sink of a given link

RETURNS
    TRUE if successful, FALSE otherwise
*/
bool HfpLinkGetAudioSink(hfp_link_priority priority, Sink* sink)
{
    hfp_link_data* link = hfpGetLinkFromPriority(priority);
    if(link)
    {
        *sink = link->audio_sink;
        return TRUE;
    }
    *sink = NULL;
    return FALSE;
}


/****************************************************************************
NAME    
    HfpLinkGetCallState

DESCRIPTION
    External function to get the call state of a given link

RETURNS
    TRUE if successful, FALSE otherwise
*/
bool HfpLinkGetCallState(hfp_link_priority priority, hfp_call_state* state)
{
    hfp_link_data* link = hfpGetLinkFromPriority(priority);
    
    if(link)
    {
        *state = link->ag_call_state;
        return TRUE;
    }
    *state = hfp_call_state_idle;
    return FALSE;
}


/****************************************************************************
NAME    
    HfpLinkSetMaxConnections

DESCRIPTION
    Set the maximum number of allowed connections. It is not possible
    to set max connections greater than the configured number, so if 
    multipoint support is not configured any setting other than one will fail.
    If reducing the number of connections this function will fail if an idle
    link is not available to be disabled.

RETURNS
    TRUE if successful, FALSE otherwise
*/
bool HfpLinkSetMaxConnections(uint8 max_connections)
{
    hfp_link_data* link;
    uint8 link_count = 0;
    
    /* Count number of active links */
    for_all_links(link)
        if(link->ag_slc_state != hfp_slc_disabled)
            link_count++;
    
    PRINT(("Set max connections %d, currently %d\n", max_connections, link_count));
    
    if(max_connections == link_count)
    {
        PRINT(("Already done\n"));
        return TRUE;
    }
    else if(max_connections > link_count)
    {
        link = hfpGetLinkFromSlcState(hfp_slc_disabled);
        PRINT(("Enabling link 0x%X\n", (uint16)link));
        return hfpLinkDisable(link, FALSE);
    }
    else
    {
        link = hfpGetIdleLink();
        PRINT(("Disabling link 0x%X\n", (uint16)link));
        return hfpLinkDisable(link, TRUE);
    }
}


/****************************************************************************
NAME    
    HfpLinkPriorityFromCallState
    
DESCRIPTION
    determine if any of the connected AG's are in the passed in state, if
    a state match is found return the link priority

RETURNS
    link priority if match is found, invalid link if none found
*/   
hfp_link_priority HfpLinkPriorityFromCallState(hfp_call_state call_state)
{
    hfp_call_state state;
    hfp_link_priority priority;
    
    for_all_priorities(priority)
        if((HfpLinkGetCallState(priority, &state)) && (call_state == state))
            return priority;
    
    return hfp_invalid_link;
}


/****************************************************************************
NAME    
    HfpLinkPriorityWithAudio
    
DESCRIPTION
    Get the highest priority link with audio.

RETURNS
    link priority if match is found, invalid link if none found
*/
hfp_link_priority HfpLinkPriorityWithActiveCall(bool audio)
{
    hfp_link_priority priority;
    Sink sink;
    
    /* Find a link with audio and a call */
    for_all_priorities(priority)
    {
        /* If link has audio or we don't care about audio*/
        if(!audio || HfpLinkGetAudioSink(priority, &sink))
        {
            /* Return if it has a call ongoing */
            hfp_call_state call_state;
            HfpLinkGetCallState(priority, &call_state);
            switch(call_state)
            {
                case hfp_call_state_active:
                case hfp_call_state_twc_incoming:
                case hfp_call_state_twc_outgoing:
                case hfp_call_state_held_active:
                case hfp_call_state_multiparty:
                    return priority;
                break;
                
                default:
                break;
            }
        }
    }
    
    /* Failed so just return the highest priority link with audio */
    if(audio)
        for_all_priorities(priority)
            if(HfpLinkGetAudioSink(priority, &sink))
                return priority;
    
    /* No links with audio, we failed completely */
    return hfp_invalid_link;
}


/****************************************************************************
NAME    
    HfpLinkPriorityFromAudioSink
    
DESCRIPTION
    try to find a match for current headset audio sink value

RETURNS
    link priority if match is found, invalid link if none found
*/
hfp_link_priority HfpLinkPriorityFromAudioSink(Sink sco_sink)
{
    /* Return if sco_sink matches one of the links */
    hfp_link_data* link = hfpGetLinkFromAudioSink(sco_sink);
    return hfpGetLinkPriority(link);
}


/****************************************************************************
NAME    
    HfpLinkPriorityFromBdaddr
    
DESCRIPTION
    Try to find a match for a Bluetooth address

RETURNS
    link priority if match is found, invalid link if none 
    found
*/
hfp_link_priority HfpLinkPriorityFromBdaddr(const bdaddr* bd_addr)
{
    hfp_link_data* link = hfpGetLinkFromBdaddr(bd_addr);
    if(link) return link->priority;
    return hfp_invalid_link;
}


/****************************************************************************
NAME    
    HfpLinkLoss
    
DESCRIPTION
    Query if HFP is currently attempting to reconnect any lost links

RETURNS
    TRUE if HFP is recovering from link loss, FALSE 
    otherwise
*/
bool HfpLinkLoss(void)
{
    hfp_link_data*  link;
    
    for_all_links(link)
        if(link->ag_link_loss_state == hfp_link_loss_recovery)
            return TRUE;
    
    return FALSE;
}

/****************************************************************************
NAME    
    HfpPriorityIsHsp
    
DESCRIPTION
    Query if the connection for the profile passed in is HSP profile

RETURNS
    TRUE if HSP profile otherwise FALSE
*/
bool HfpPriorityIsHsp(hfp_link_priority priority)
{
    hfp_link_data* link = hfpGetLinkFromPriority(priority);
    
    return(hfpLinkIsHsp(link));    
}
/*****************************************************************************
NAME    
    HfpGetFirstIncomingCallPriority
    
DESCRIPTION
    Function that provides information on priority that received the
    first incoming call	    

RETURNS
    The priority on which the first call came.
*/

hfp_link_priority HfpGetFirstIncomingCallPriority(void)
{
   return theHfp->first_incoming_call;
}
