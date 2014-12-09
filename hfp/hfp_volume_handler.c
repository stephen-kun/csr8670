/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    hfp_sound_handler.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_common.h"
#include "hfp_parse.h"
#include "hfp_send_data.h"
#include "hfp_volume_handler.h"
#include "hfp_link_manager.h"

#include <panic.h>
#include <stdio.h>
#include <string.h>

/* Max gain is 15 */
#define HFP_MAX_GAIN 15


/****************************************************************************
NAME    
    hfpHandleVgsRequest

DESCRIPTION
    Send a volume gain update to the AG.

RETURNS
    void
*/
void hfpHandleVgsRequest(hfp_link_data* link, uint8 gain)
{
    /* Don't send anything to AG if gain already set */
    if(link->at_vol_setting != gain)
    {
        /* Store the latest volume setting requested by the client */
        link->at_vol_setting = (gain > HFP_MAX_GAIN) ? HFP_MAX_GAIN : gain;
        
        /*
            Don't send another AT command if one is pending, the volume is read
            from the link data when the VGS is sent so just updating the volume
            stored in the link is enough. This prevents us from sending AT+VGS 
            to the AG repeatedly for rapid volume changes. 
        */
        if (!link->at_vol_pending)
        {
            char *vgs = "AT+VGS=00\r";
            
            /* Set the pending mask */
            link->at_vol_pending = TRUE;
            
            /* Send the AT cmd over the air */
            hfpSendAtCmd(link, strlen(vgs), vgs, hfpVgsCmdPending);
        }
    }
}


/****************************************************************************
NAME    
    sendSpeakerVolumeIndToApp

DESCRIPTION
    We're in the right state to inform the app that the volume gain has
    been changed from the AG.

RETURNS
    void
*/
static void sendSpeakerVolumeIndToApp(hfp_link_data* link, uint16 gain)
{
    /* This is generated in response to receiving a volume indication from the AG */
    MAKE_HFP_MESSAGE(HFP_VOLUME_SYNC_SPEAKER_GAIN_IND);
    message->priority = hfpGetLinkPriority(link);
    message->volume_gain = gain;
    MessageSend(theHfp->clientTask, HFP_VOLUME_SYNC_SPEAKER_GAIN_IND, message);
}


/****************************************************************************
NAME    
    hfpHandleSpeakerGain

DESCRIPTION
    Called from the auto generated parser when a +VGS indication is
    received from the AG.

AT INDICATION
    +VGS

RETURNS
    void
*/
void hfpHandleSpeakerGain(Task link_ptr, const struct hfpHandleSpeakerGain *ind)
{
    if(ind->gain <= HFP_MAX_GAIN)
    {
        hfp_link_data* link = (hfp_link_data*)link_ptr;
        
        if((hfpLinkIsHfp(link) && hfFeatureEnabled(HFP_REMOTE_VOL_CONTROL)) || hfpLinkIsHsp(link))
        {
            /* If link is in a valid state for this message... */
            if(link && link->ag_slc_state == hfp_slc_complete)
            {
                /* 
                   If we have a pending volume setting we want that to win, so
                   don't update local volume with the AG's change in that case. 
                   No point telling the application about it either.
                */
                if(!link->at_vol_pending)
                {
                    sendSpeakerVolumeIndToApp(link, ind->gain);
                    link->at_vol_setting = ind->gain;
                }
            }
        }
    }
}


/****************************************************************************
NAME    
    hfpHandleVgsInd

DESCRIPTION
    Send the VGM request to the AG.

RETURNS
    void
*/
void hfpHandleVgmRequest(hfp_link_data* link, uint8 gain)
{
    char vgm[11];

    strcpy(vgm, "AT+VGM=00\r");
    gain = (gain > HFP_MAX_GAIN) ? HFP_MAX_GAIN : gain;
 
    /* Create the AT cmd we're sending */
    vgm[7] = '0' + gain / 10;
    vgm[8] = '0' + gain % 10;
     
    /* Send the AT cmd over the air */
    hfpSendAtCmd(link, strlen(vgm), vgm, hfpCmdPending);
}


/****************************************************************************
NAME    
    sendMicVolumeIndToApp

DESCRIPTION
    Pass on the received microphone gain indication to the app.

RETURNS
    void
*/
static void sendMicVolumeIndToApp(hfp_link_data* link, uint16 mic_gain)
{
    /* This is generated in response to receiving a mic indication from the AG */
    MAKE_HFP_MESSAGE(HFP_VOLUME_SYNC_MICROPHONE_GAIN_IND);
    message->priority = hfpGetLinkPriority(link);
    message->mic_gain = mic_gain;
    MessageSend(theHfp->clientTask, HFP_VOLUME_SYNC_MICROPHONE_GAIN_IND, message);
}


/****************************************************************************
NAME    
    hfpHandleMicrophoneGain

DESCRIPTION
    Received a +VGM indication from the AG.

AT INDICATION
    +VGM

RETURNS
    void
*/
void hfpHandleMicrophoneGain(Task link_ptr, const struct hfpHandleMicrophoneGain *ind)
{
    /* Don't pass the message to the app if the AG has sent us an out of range value */
    if (ind->gain <= HFP_MAX_GAIN)
    {
        hfp_link_data* link = (hfp_link_data*)link_ptr;
        
        if(link && link->ag_slc_state == hfp_slc_complete)
            sendMicVolumeIndToApp(link, ind->gain);
    }
}

