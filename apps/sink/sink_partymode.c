/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2013-2014

FILE NAME
    sink_partymode.c      

DESCRIPTION
    These are the functions for controlling the Party Mode feature of the soundbar, 
    bluetooth connections and audio routing is handled differently in this mode
    of operation
    

NOTES

*/
#include "sink_partymode.h"
#include "sink_statemanager.h"
#include "sink_audio.h"
#include "sink_audio_routing.h"
#include "sink_private.h"
#include "sink_configmanager.h"
#include "sink_slc.h"

#include <stdlib.h>
#include <audio.h>
#include <bdaddr.h>

#ifdef DEBUG_PARTY_MODE
    #define PTY_DEBUG(x) DEBUG(x)
#else
    #define PTY_DEBUG(x) 
#endif

#ifdef ENABLE_PARTYMODE

#define OTHER_DEVICE(x) (x ^ 0x1)

static bool sinkCheckAvrcpStateMatch(a2dp_link_priority priority, avrcp_play_status play_status);

/****************************************************************************
NAME    
    sinkCheckAvrcpStateMatch
    
DESCRIPTION
    helper function to check an avrcp play status for a given a2dp link priority
    
RETURNS
    true is the avrcp play state matches that passed in
    false if state does not match or no matching avrcp link is found for a2dp profile index
*/
bool sinkCheckAvrcpStateMatch(a2dp_link_priority priority, avrcp_play_status play_status)
{
    if((BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[priority], &theSink.avrcp_link_data->bd_addr[a2dp_primary])&&(theSink.avrcp_link_data->play_status[a2dp_primary] == play_status))||
       (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[priority], &theSink.avrcp_link_data->bd_addr[a2dp_secondary])&&(theSink.avrcp_link_data->play_status[a2dp_secondary] == play_status)))
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}
         
/****************************************************************************
NAME    
    sinkCheckPartyModeAudio
    
DESCRIPTION
    Called when checking for PartyMode being enabled, if not enabled no action is
    taken, when enabled decisions are made as to what audio should be playing or
    paused/resumed etc
    
RETURNS
    bool false if party mode not enabled, true is party mode enabled and action has
    been taken with regards to the routing of the audio source
*/
bool sinkCheckPartyModeAudio(audio_sources requested_source, audio_source_status * lAudioStatus)
{
    uint8 index;
    
    /* check whether party mode is enabled and configured and if the currently routed audio is one of the a2dp streams */
    if((theSink.PartyModeEnabled)&&(theSink.features.PartyMode)&&(lAudioStatus->audio_routed)&&
       ((lAudioStatus->a2dpSinkPri == lAudioStatus->audio_routed)||(lAudioStatus->a2dpSinkSec == lAudioStatus->audio_routed))
      )
    {
        /* determine the PartyMode operating mode required */     
        switch(theSink.features.PartyMode)
        {
            /* simple barge-in mode of operation, a new audio source streaming music
               disconnects any currently streaming device */
            case partymode_barge_in:
                PTY_DEBUG(("PTY: bargein\n"));

                /* if the current streaming audio A2DP pri and a stream for A2DP sec is available, switch to that */            
                if((lAudioStatus->a2dpSinkPri == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStateSec == a2dp_stream_streaming))
                {
                    PTY_DEBUG(("PTY: drop current pri route new sec\n"));

                    /* drop bluetooth connection to device currently streaming */
                    for(index = a2dp_primary; index < (a2dp_secondary+1); index++)
                    {
                        /* is a2dp connected? */
                        if(theSink.a2dp_link_data->connected[index])
                        {
                            /* check whether the a2dp connection is present and streaming data and that the audio is routed */
                            if(lAudioStatus->audio_routed == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index]))
                            {                                   
                                /* disconnect a2dp audio device */
                                sinkPartyModeDisconnectDevice(index);
                            }
                        }
                    }
                    /* route the audio from the new device */
                    A2dpRouteAudio(a2dp_secondary, lAudioStatus->a2dpSinkSec);
                }
                /* if the current streaming audio A2DP sec and a stream for A2DP pri is available, switch to that */            
                else if((lAudioStatus->a2dpSinkSec == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStatePri == a2dp_stream_streaming))
                {
                    PTY_DEBUG(("PTY: drop current sec route new pri\n"));
                    /* drop bluetooth connection to device currently streaming */
                    for(index = a2dp_primary; index < (a2dp_secondary+1); index++)
                    {
                        /* is a2dp connected? */
                        if(theSink.a2dp_link_data->connected[index])
                        {
                            /* check whether the a2dp connection is present and streaming data and that the audio is routed */
                            if(lAudioStatus->audio_routed == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index]))
                            {                                   
                                /* disconnect a2dp audio device */
                                sinkPartyModeDisconnectDevice(index);
                            }
                        }
                    }
                    /* route the audio from the new device */
                    A2dpRouteAudio(a2dp_primary, lAudioStatus->a2dpSinkPri);
                }
                /* no action has been taken */
                else
                    return TRUE;
            break;
        
            /* more complex use case, a new streaming audio source is paused using avrcp
               until the current playing track completes */
            case partymode_avrcp_control:
                PTY_DEBUG(("PTY: avrcp ctrl AG1[%x] AG2[%x] AVRCP1[%x] AVRCP[%x] \n",lAudioStatus->a2dpStatePri,lAudioStatus->a2dpStateSec,theSink.avrcp_link_data->play_status[a2dp_primary],theSink.avrcp_link_data->play_status[a2dp_secondary]));

                /* if the current streaming audio is A2DP pri and a stream for A2DP sec is available, pause that and wait for the 
                   current track to finish playing */            
                if((lAudioStatus->a2dpSinkPri == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStatePri == a2dp_stream_streaming)&&
                   ((lAudioStatus->a2dpStateSec == a2dp_stream_streaming)&&
                    (sinkCheckAvrcpStateMatch(a2dp_secondary, avrcp_play_status_playing)))
                   )
                {
                    PTY_DEBUG(("PTY: suspend a2dp sec audio until pri track finished \n"));
                    SuspendA2dpStream(a2dp_secondary);
                    /* set paused flag */
                    theSink.rundata->partymode_pause.audio_source_secondary_paused = TRUE;
                }
                /* if the current streaming audio A2DP sec and a stream for A2DP pri is available, switch to that */            
                else if((lAudioStatus->a2dpSinkSec == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStateSec == a2dp_stream_streaming)&&
                        ((lAudioStatus->a2dpStatePri == a2dp_stream_streaming)&&
                         (sinkCheckAvrcpStateMatch(a2dp_primary, avrcp_play_status_playing)))
                       )
                {
                    PTY_DEBUG(("PTY: suspend a2dp pri audio until sec track finished \n"));
                    SuspendA2dpStream(a2dp_primary);
                    /* set paused flag */
                    theSink.rundata->partymode_pause.audio_source_primary_paused = TRUE;
                }
                /* check if currently routed primary source is still valid, disconnect if not */
                else if((lAudioStatus->a2dpSinkPri == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStatePri != a2dp_stream_streaming))
                {
                    /* check if other source is present and paused */
                    a2dp_link_priority link = sinkPartyModeCheckForOtherPausedSource(a2dp_primary);
                    PTY_DEBUG(("PTY: pri source not valid, disconnect\n"));
                    /* disconnect a2dp primary audio */
                    audioDisconnectActiveSink();
                    /* disconnect primary audio device */
                    if(deviceManagerNumConnectedDevs() > 1)
                        sinkPartyModeDisconnectDevice(a2dp_primary);
                    /* check for other paused audio source to route */                    
                    if((link != a2dp_invalid)&&(theSink.rundata->partymode_pause.audio_source_secondary_paused))
                    {
                        PTY_DEBUG(("PTY: resume paused sec\n"));
                        /* resume paused device */
                        ResumeA2dpStream(a2dp_secondary, lAudioStatus->a2dpStateSec, lAudioStatus->a2dpSinkSec);
                    }
                    return TRUE;                
                }
                /* check if currently routed secondary source is still valid, disconnect if not */
                else if((lAudioStatus->a2dpSinkSec == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStateSec != a2dp_stream_streaming))
                {
                    /* check if other source is present and paused */
                    a2dp_link_priority link = sinkPartyModeCheckForOtherPausedSource(a2dp_secondary);
                    PTY_DEBUG(("PTY: sec source not valid, disconnect\n"));
                    /* disconnect a2dp secondary audio */
                    audioDisconnectActiveSink();
                    /* disconnect secondary audio device */
                    if(deviceManagerNumConnectedDevs() > 1)
                        sinkPartyModeDisconnectDevice(a2dp_secondary);
                    /* check for other paused audio source to route */                    
                    if((link != a2dp_invalid)&&(theSink.rundata->partymode_pause.audio_source_primary_paused))
                    {
                        PTY_DEBUG(("PTY: resume paused pri\n"));
                        /* resume paused device */
                        ResumeA2dpStream(a2dp_primary, lAudioStatus->a2dpStatePri, lAudioStatus->a2dpSinkPri);
                    }
                    return TRUE;                
                }
                /* take no action at this time */
                else
                {
                    PTY_DEBUG(("PTY: avrcp - no action - AR[%x] Pri[%x] Sec[%x]\n",(uint16)lAudioStatus->audio_routed,lAudioStatus->a2dpStatePri,lAudioStatus->a2dpStateSec));
                    return TRUE;
                }
            break;
            
            /* not a valid configuration of operating mode */
            default:
                PTY_DEBUG(("PTY: invalid mode - no action\n"));
                /* default to standard audio routing mode of operation */
                return FALSE;
            break;
                       
        }
        return TRUE;   
    }        
    /* no audio routed or party mode not enabled */
    else
    {
        /* party mode not active or no audio currently routed, take no action and let standard audio routing
           functions take control */
        PTY_DEBUG(("PTY: NOT ACTIVE [%d] or NO AUDIO ROUTED AR[%x] Pri[%x] Sec[%x]\n",(theSink.PartyModeEnabled && theSink.features.PartyMode)
                                                                                     ,(uint16)lAudioStatus->audio_routed
                                                                                     ,(uint16)lAudioStatus->a2dpSinkPri
                                                                                     ,(uint16)lAudioStatus->a2dpSinkSec));
        return FALSE;
    }
}    
   

/****************************************************************************
NAME    
    sinkPartyModeTrackChangeIndication
    
DESCRIPTION
    Called when AVRCP has detected a track change indication
    
RETURNS
    none
*/
void sinkPartyModeTrackChangeIndication(uint16 index)
{        
    /* check to see if this is an indication from the currently active device */
    if ((theSink.PartyModeEnabled)&&(theSink.features.PartyMode)&&(index == sinkAvrcpGetActiveConnection()))
    {
        PTY_DEBUG(("PTY: track change active dev\n"));
        
        if(!theSink.features.avrcp_enabled ||
           !theSink.features.EnableAvrcpAudioSwitching)
        {
            PTY_DEBUG(("PTY: ignore AVRCP in party mode\n"));
            return;
        }
        /*  check whether to changing the audio routing */
        else
        {
            /* get current audio status */
            audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);        
       
            /* ensure device is still streaming/playing */ 
            
            /* determine which device track change came from */
            if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary], &theSink.avrcp_link_data->bd_addr[index]))
            {
                /* track change on primary a2dp device, check it is still streaming and audio is routed */
                if(((theSink.avrcp_link_data->play_status[index] == avrcp_play_status_playing)||(theSink.avrcp_link_data->play_status[index] == avrcp_play_status_stopped)||(theSink.avrcp_link_data->play_status[index] == avrcp_play_status_paused))&&
                    (lAudioStatus->a2dpSinkPri == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStatePri == a2dp_stream_streaming))
                {
                    /* track change on a2dp primary is valid, check if a2dp secondary is paused */
                    if((lAudioStatus->a2dpStateSec == a2dp_stream_streaming)||(lAudioStatus->a2dpStateSec == a2dp_stream_open))
                    {
                        /* check avrcp play status is paused */        
                        if((theSink.rundata->partymode_pause.audio_source_secondary_paused)&&(theSink.avrcp_link_data->play_status[(index^1)] == avrcp_play_status_paused))
                        {
                            PTY_DEBUG(("PTY: track change route sec dis pri\n"));

                            /* disconnect primary device */                            
                            sinkPartyModeDisconnectAndResume(a2dp_primary, lAudioStatus);
                            /* reset paused flag */
                            theSink.rundata->partymode_pause.audio_source_secondary_paused = FALSE;
                        }
                    }
                }                     
            }
            else if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_secondary], &theSink.avrcp_link_data->bd_addr[index]))
            {
                /* track change on primary a2dp device, check it is still streaming and audio is routed */
                if(((theSink.avrcp_link_data->play_status[index] == avrcp_play_status_playing)||(theSink.avrcp_link_data->play_status[index] == avrcp_play_status_stopped)||(theSink.avrcp_link_data->play_status[index] == avrcp_play_status_paused))&&
                    (lAudioStatus->a2dpSinkSec == lAudioStatus->audio_routed)&&(lAudioStatus->a2dpStateSec == a2dp_stream_streaming))
                {
                    /* track change on a2dp primary is valid, check if a2dp secondary is paused */
                    if((lAudioStatus->a2dpStatePri == a2dp_stream_streaming)||(lAudioStatus->a2dpStatePri == a2dp_stream_open))
                    {
                        /* check avrcp play status is paused */        
                        if((theSink.rundata->partymode_pause.audio_source_primary_paused)&&(theSink.avrcp_link_data->play_status[(index^1)] == avrcp_play_status_paused))
                        {
                            PTY_DEBUG(("PTY: track change route pri dis sec\n"));
                            /* disconnect secondary device */                            
                            sinkPartyModeDisconnectAndResume(a2dp_secondary, lAudioStatus);
                            /* reset paused flag */
                            theSink.rundata->partymode_pause.audio_source_primary_paused = FALSE;
                        }
                    }
                }                     
                
            }
            /* free malloc'd status memory slot */
            freePanic(lAudioStatus);
        }
    }
    /* indication from device that isn't currently streaming audio, ignore */
    else
    {
        PTY_DEBUG(("PTY: track change ignored PTY[%d] index[%d] ActiveIdx[%d]\n",(theSink.PartyModeEnabled && theSink.features.PartyMode),index,sinkAvrcpGetActiveConnection()));
    }
}



/****************************************************************************
NAME    
    sinkPartyModeDisconnectDevice
    
DESCRIPTION
    Disconnects the AG specified by the passed in a2dp link priority 
    
RETURNS
    successful or unable to disconnect state as true or false
*/
bool sinkPartyModeDisconnectDevice(a2dp_link_priority link)
{
    PTY_DEBUG(("PTY: Disc Dev[%d] Connected[%d]\n",link ,theSink.a2dp_link_data->connected[link]));
    /* is a2dp connected? */
    if(theSink.a2dp_link_data->connected[link])
    {
        /* disconnect a2dp primary audio */
        audioDisconnectActiveSink();
        /* disconnect device bluetooth link */
        A2dpSignallingDisconnectRequest(theSink.a2dp_link_data->device_id[link]);
        /* if hfp connected to this device then disconnect it */
        if(deviceManagerIsSameDevice(link, hfp_primary_link))
            HfpSlcDisconnectRequest(hfp_primary_link);
        else if(deviceManagerIsSameDevice(link, hfp_secondary_link))
            HfpSlcDisconnectRequest(hfp_secondary_link);

#ifdef ENABLE_MAPC
        /* Disconnect all MAPC links */
        mapcDisconnectMns();
#endif
#ifdef ENABLE_PBAP        
        /* Disconnect all PBAP links */
        pbapDisconnect();
#endif	  
        return TRUE;                                
    }
    /* didn't disconnect anything */
    else
        return FALSE;
}

/****************************************************************************
NAME    
    sinkPartyModeDisconnectAndResume
    
DESCRIPTION
    Disconnects the AG specified by the passed in a2dp link priority and
    resumes the a2dp playing
    
RETURNS
    none
*/
void sinkPartyModeDisconnectAndResume(a2dp_link_priority link, audio_source_status * lAudioStatus)
{
    /* attempt to disconnect passed in device */
    if(sinkPartyModeDisconnectDevice(link))
    {                           
        /* send avrcp play or a2dp start to resume audio and connect it */        
        if(link == a2dp_secondary)    
            ResumeA2dpStream(a2dp_primary, lAudioStatus->a2dpStatePri, lAudioStatus->a2dpSinkPri);         
        else
            ResumeA2dpStream(a2dp_secondary, lAudioStatus->a2dpStateSec, lAudioStatus->a2dpSinkSec);         
    }
}

/****************************************************************************
NAME    
    sinkPartyModeCheckForOtherPausedSource
    
DESCRIPTION
    function to look for a device other than the one passed in that is in an paused
    state
    
RETURNS
    link priority if an avrcp paused device is found
*/
a2dp_link_priority sinkPartyModeCheckForOtherPausedSource(a2dp_link_priority link)
{
    
    /* determine if the other device is connected and has avrcp connected*/
    if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[OTHER_DEVICE(link)], &theSink.avrcp_link_data->bd_addr[a2dp_primary]))
    {
        /* device is connected, check its current avrcp state, if paused then return index of device */
        if(theSink.avrcp_link_data->play_status[a2dp_primary] == avrcp_play_status_paused)
            return OTHER_DEVICE(link);
    }
    /* determine if the other device is connected and has avrcp connected*/
    else if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[OTHER_DEVICE(link)], &theSink.avrcp_link_data->bd_addr[a2dp_secondary]))
    {
        /* device is connected, check its current avrcp state, if paused then return index of device */        
        if(theSink.avrcp_link_data->play_status[a2dp_secondary] == avrcp_play_status_paused)
            return OTHER_DEVICE(link);
    }
    /* no paused other devices found */
    return a2dp_invalid;
}    
        
#endif
