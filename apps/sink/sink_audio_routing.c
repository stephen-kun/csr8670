/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_audio.c

DESCRIPTION
    This file handles all Synchronous connection messages

NOTES

*/


/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_audio.h"
#include "sink_statemanager.h"
#include "sink_pio.h"
#include "sink_tones.h"
#include "sink_volume.h"
#include "sink_speech_recognition.h"
#include "sink_wired.h"
#include "sink_dut.h"
#include "sink_display.h"
#include "sink_audio_routing.h"
#include "sink_devicemanager.h"
#include "sink_debug.h"
#include "sink_partymode.h"

#ifdef ENABLE_FM
#include "sink_fm.h"
#endif

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#include <connection.h>
#include <a2dp.h>
#include <hfp.h>
#include <stdlib.h>
#include <audio.h>
#include <audio_plugin_if.h>
#include <sink.h>
#include <bdaddr.h>
#include <vm.h>
#include <swat.h>
#ifdef DEBUG_AUDIO
#define AUD_DEBUG(x) DEBUG(x)
#else
#define AUD_DEBUG(x) 
#endif     


static bool isAudioGated (audio_gating audio_gated_mask)
{
    AUD_DEBUG(("isAudioGated(0x%X)  0x%X\n",audio_gated_mask,theSink.gated_audio));
    return !!(theSink.gated_audio & audio_gated_mask);
}

audio_gating audioGateAudio (uint16 audio_gated_mask)
{
    theSink.gated_audio |= audio_gated_mask;
    
    AUD_DEBUG(("audioGateAudio(0x%X)  0x%X\n",audio_gated_mask,theSink.gated_audio));
    return theSink.gated_audio;
}

audio_gating audioUngateAudio (uint16 audio_ungated_mask)
{
    theSink.gated_audio &= ~audio_ungated_mask;
    
    AUD_DEBUG(("audioUngateAudio(0x%X)  0x%X\n",audio_ungated_mask,theSink.gated_audio));
    return theSink.gated_audio;
}

#ifdef ENABLE_SOUNDBAR
/****************************************************************************
NAME    
    audioSwitchToAudioSource
    
DESCRIPTION
	Switch audio routing to the source passed in, it may not be possible
    to actually route the audio at that point if audio sink for that source
    is not available at that time.
    
    If the audio is not routed, it will be queued for routing unless cancelled,
    un-comment line to cancel the queuing feature of the audio switching

RETURNS
    TRUE if audio routed, FALSE id not possible to route audio
*/
bool audioSwitchToAudioSource(audio_sources source)
{   
    /* attempt to route audio from passed in source if specified */
    if(source)
    {
        /* attempt to switch to passed source */
        if(audioHandleRouting (source))
        {
            /* able to route source, exit */
           AUD_DEBUG(("AUD: Switch to source %d - success\n",source)); 
           
#ifdef ENABLE_SUBWOOFER
            /* Check if a SWAT media channel needs to be opened for the "new" source */
            switch(source)
            {
                case audio_source_FM:
                case audio_source_ANALOG:
                case audio_source_USB:
                case audio_source_SPDIF:
                {
                    AUD_DEBUG(("AUD [SW] : (switch source) Connect eSCO media\n"));
                    MessageCancelAll(&theSink.task, EventSysSubwooferOpenLLMedia);
                    MessageCancelAll(&theSink.task, EventSysSubwooferOpenStdMedia);
                    MessageSend(&theSink.task, EventSysSubwooferOpenLLMedia, 0);
                }
                break;
                case audio_source_AG1:
                case audio_source_AG2:
                {
                    AUD_DEBUG(("AUD [SW] : (switch source) Connect L2CAP media\n"));
                    MessageCancelAll(&theSink.task, EventSysSubwooferOpenLLMedia);
                    MessageCancelAll(&theSink.task, EventSysSubwooferOpenStdMedia);
                    MessageSend(&theSink.task, EventSysSubwooferOpenStdMedia, 0);
                }
                break;
                case audio_source_none:
                case audio_source_end_of_list:
                {
                    AUD_DEBUG(("AUD [SW] : (switch source) Disconnect media\n"));
                }
                break;
            }
#endif
           return TRUE;
        }
        /* failed to route audio from passed in source, an already connected source is left connected */
        else
        {
           AUD_DEBUG(("AUD: Switch to source %d - success\n",source)); 
    
           /* To prevent automatic routing of the source when it becomes available
              include the following line */
/*           theSink.rundata->requested_audio_source = audio_source_none; */
            
           return FALSE;
        } 
    }
    /* no source passed in, treat this as a disconnect request */
    else
    {
        /* update the current requested source */
        theSink.rundata->requested_audio_source = audio_source_none;
        
        /* if audio is currently routed, disconnect it */
        if(theSink.routed_audio)
        {
            /* get current audio status */
            audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);        

            AUD_DEBUG(("AUD: disconnect or suspend current source\n"));
            
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);

            /* free malloc'd audio status memory slot */
            freePanic(lAudioStatus);
            
            /* report audio successfully disconnected */
            return TRUE;
        }
        /* no audio currently routed, reported failed status */
        else
        {
            return FALSE;
        }
    }
}
 
/****************************************************************************
NAME    
    audioSwitchToNextAudioSource
    
DESCRIPTION
	attempt to cycle to the next available audio source, if a source
    isn't available then cycle round until one is found, if no audio sources
    are available then stop

RETURNS
    none
*/
void audioSwitchToNextAudioSource(void)
{
    /* temporarily store current audio source as routed_audio_source may be changed by connectedion attempts */
    audio_sources old_source = theSink.rundata->routed_audio_source;
    /* get current audio source */
    audio_sources new_source = theSink.rundata->routed_audio_source;
    
    AUD_DEBUG(("AUD: Switch to next source\n"));

    /* scroll around audio_source list and see if it is possible to
       connect and route a source */
    do
    {
        /* move to next source */
        new_source++;
        /* ensure a new source can be found, if not give up searching */
        if((new_source == old_source)||((new_source == audio_source_end_of_list)&&(old_source == audio_source_none)))
        {
            /* restore any previous routed audio since no new source is available */
            audioHandleRouting (old_source);
            AUD_DEBUG(("AUD: Switch to next source - fail, no sources available - %d\n",old_source)); 
            break;
        }
        /* loop around list of sources when reaching the end of the list */
        if(new_source == audio_source_end_of_list) 
            new_source = (audio_source_none + 1);
        /* attempt to route the requested source */
        if(audioHandleRouting (new_source))
        {
            
            /* update the currently routed source */    
            theSink.rundata->routed_audio_source = new_source;
            /* able to route source, exit */
            AUD_DEBUG(("AUD: Switch to next source - success %d\n",new_source)); 
            /* make sure the subwoofer type is correct for the routed input source */
#ifdef ENABLE_SUBWOOFER
            audioCheckSubwooferConnection(TRUE);
#endif

            break;
        }
        /* attempt to route audio failed, reset queued request before attempting
           next source */
        else
        {
           theSink.rundata->requested_audio_source = audio_source_none; 
        }
    /* continue around list of sources until back where started from */
    }while(new_source != theSink.rundata->routed_audio_source);       
}

#endif
        
/****************************************************************************
NAME    
    audioHandleRouting
    
DESCRIPTION
	Handle the routing of the audio connections or connection based on
    sco priority level, can specify a required source for soundbar type apps

RETURNS
    TRUE if audio routed correctly, FALSE if no audio available to route 
*/
bool audioHandleRouting (audio_sources requested_source)
{       
    bool status = TRUE;
#ifdef ENABLE_SUBWOOFER
    /* Indicate which audio source has been routed so the sub audio routing can also be routed appropriately */
    audio_sources sub_source_to_route = audio_source_none;
#endif
    
    /* get current audio status */
    audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);        
       
    /* ensure initialisation is complete before attempting to route audio */
    if(theSink.SinkInitialising)
    {
        /* free malloc'd status memory slot */
        freePanic(lAudioStatus);
        return FALSE;
    }

    AUD_DEBUG(("AUD: audioHandleRouting %x, Allocations remaining %d\n",(uint16)theSink.routed_audio,VmGetAvailableAllocations()));
   
    /* is the headset in device under test mode with active audio, if so
       disconnect the audio */
    if ((stateManagerGetState() == deviceTestMode)&&(isDutAudioActive()))
    {
        /* if audio is active in DUT mode then must disconnect this first to avoid any Panics,
           as device is still allowed to operate in DUT mode */
        AUD_DEBUG(("AUD: disconnect DUT audio\n"));
        AudioDisconnect();
    }

/* non soundbar (headset) operation results in an automatic switching of audio sources based upon the 
   priority of audio sources available, the priorities of the audio sources are as follows:
   
    lowest priority  - fm
                     - wireless
                     - usb
                     - a2dp
                     - sco
                     - speech recognition
                     
    the app will automatically connect and disconnect the audio sources as it sees fit.  */
#ifndef ENABLE_SOUNDBAR

    /* determine which audio sources are available and what should be routed, if
       already routed then no changes are made, otherwise disconnect and reconnect
       the next highest priority available audio source */

#ifdef ENABLE_SPEECH_RECOGNITION
    /* speech recognition takes priority over all other audio sources */    
    if (!speechRecognitionIsActive() )
#endif
    {
        AUD_DEBUG(("AUD: ASR not active\n"));
        /* SCO with active call has the highest routing priority, if present then route sco */
        if(!audioActiveCallScoAvailable(lAudioStatus, hfp_invalid_link))
        {
            AUD_DEBUG(("AUD: no sco\n"));

#ifdef ENABLE_PARTYMODE
            /* check whether party mode is enabled and configured, whether it needs
               to change from default audio routing  functionality */
            if(!sinkCheckPartyModeAudio(requested_source, lAudioStatus))                
#endif
            {        
        
                /* there are no sco's available with active call so check for a2dp sources */
                if(!audioA2dpStreamAvailable(lAudioStatus, a2dp_pri_sec))
                {
                    AUD_DEBUG(("AUD: no a2dp\n"));
#ifdef ENABLE_USB
                    /* there are no a2dp streams available, check for usb audio sources */        
                    if(!audioUsbAvailable(lAudioStatus))    
#endif
                    {
                        AUD_DEBUG(("AUD: no usb\n"));
#ifdef ENABLE_WIRED  
                        /* no usb sources, is wired available? */
                        if((!audioSpdifAvailable(lAudioStatus))&&(!audioAnalogAvailable(lAudioStatus)))
#endif
                        {
                            AUD_DEBUG(("AUD: no wired\n"));
#ifdef ENABLE_FM
                            /* no wired available, is fm available? */
                            if(!audioFMAvailable(lAudioStatus))
#endif
                            {
                                AUD_DEBUG(("AUD: no fm\n"));
                            
                                /* check for any SCO without call sources */
                                if(!audioScoAvailable(lAudioStatus))
                                {                           
                                    /* if no audio sources and audio still routed, disconnect it */                            
                                    if(lAudioStatus->audio_routed)
                                    {
                                        AUD_DEBUG(("AUD: sink with no source, disconnect\n"));
                                        /* disconnect the active audio */
                                        audioDisconnectActiveSink();   
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
#ifdef ENABLE_SPEECH_RECOGNITION
    /* speech recognition is active */
    else
    {
        /* if another audio source is already connected, disconnect or suspend it
           to use the audio hardware for speech recognition */
        if(lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: routing, ASR active, suspend/disconnect current source\n"));

            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
    }
#endif
           
/* for soundbar operation the audio sources are switched manually, sources can be specified
   directly or a switch to next source function is available. If the audio source that is requested
   is not currently available, its sink will be routed as and when it becomes available unless the
   the request to switch to that source is cancelled */
#else

    /* soundbar selectable/manual audio source switching */
    status = FALSE;
    
    /* if a source is specified/requested, attempt to route it, it may not be possible to route
       it at this time so it is necessary to store the requested source for such a time that
       the audio is available to route for this source*/
    if((requested_source)&&(requested_source != theSink.rundata->routed_audio_source))
    {
        AUD_DEBUG(("AUD: routing, try to route source %d \n",requested_source));
        /* store the requested source, it may not be available at this time but could be 
           connected later */
        theSink.rundata->requested_audio_source = requested_source;
        
        /* attempt to route source */
        if(audioRouteSource(requested_source, lAudioStatus))
        {
            /* source routed ok, routed_audio_source is updated to match requested source */
            AUD_DEBUG(("AUD: routing, source %d routed successfully\n",requested_source));
            status = TRUE;
#ifdef ENABLE_SUBWOOFER
            /* Subwoofer needs to know the audio source that has been routed */
            sub_source_to_route = requested_source;
            
            /* if attempting to use USB or WIRED sub with esco sub link, ensure that no a2dp media is
               currently streaming as the link cannot support both */
            if((theSink.rundata->requested_audio_source == audio_source_ANALOG)||
               (theSink.rundata->requested_audio_source == audio_source_SPDIF)||
               (theSink.rundata->requested_audio_source == audio_source_USB))
            {
                audioSuspendDisconnectAllA2dpMedia(lAudioStatus);
            }
            
            /* If a subwoofer media channel is connected, ensure audio is being routed */
            if(SwatGetMediaState(theSink.rundata->subwoofer.dev_id) == swat_media_streaming)
            {
                AudioConfigureSubWoofer(AUDIO_SUB_WOOFER_L2CAP, SwatGetMediaSink(theSink.rundata->subwoofer.dev_id));               
            }
            else if(SwatGetMediaLLState(theSink.rundata->subwoofer.dev_id) == swat_media_streaming)                    
            {
                AudioConfigureSubWoofer(AUDIO_SUB_WOOFER_ESCO, SwatGetMediaSink(theSink.rundata->subwoofer.dev_id));
            }
            /* if not streaming the check if it needs to be connected */
            else
                audioCheckSubwooferConnection(TRUE);
#endif
        }
        /* not possible to route source at this time */
        else
        {
            AUD_DEBUG(("AUD: routing, source %d NOT routed\n",requested_source));            
            /* if a different audio source is currently routed, disconnect it */ 
            if(lAudioStatus->audio_routed)
            {
                AUD_DEBUG(("AUD: routing, request to suspend/disconnect current source\n"));
                /* suspend or disconnect the current audio source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
        }
#ifdef ENABLE_AVRCP           
        /* if AG1 or AG2, deteremine if AVRCP is available for that source and
           update the currently active AVRCP connection appropriately */
        SetSoundbarAVRCPActiveSource(requested_source);                   
#endif
    }
    /* no requested source passed in, check to see if a previous source was requested
       and not available at that time but has since become available and needs to be routed */
    else
    {
        /* is requested source routed if avaiable? */
        if((theSink.rundata->requested_audio_source)&&
           (theSink.rundata->routed_audio_source != theSink.rundata->requested_audio_source))
        {
            /* requested source not yet routed, see if it can now be routed */
            AUD_DEBUG(("AUD: routing, retry to route source %d \n",requested_source));
    
            /* try to route source again to see if source is now valid */
            if(audioRouteSource(theSink.rundata->requested_audio_source, lAudioStatus))
            {
                /* source routed ok, routed_audio_source is updated to match requested source */
                AUD_DEBUG(("AUD: routing, source %d routed successfully\n",requested_source));
                status = TRUE;
#ifdef ENABLE_SUBWOOFER
                /* Subwoofer needs to know the audio source that has been routed */
                sub_source_to_route = theSink.rundata->requested_audio_source;
                
                /* if attempting to use USB or WIRED sub with esco sub link, ensure that no a2dp media is
                   currently streaming as the link cannot support both */
                if((theSink.rundata->requested_audio_source == audio_source_ANALOG)||
                   (theSink.rundata->requested_audio_source == audio_source_SPDIF)||
                   (theSink.rundata->requested_audio_source == audio_source_USB))
                {
                    audioSuspendDisconnectAllA2dpMedia(lAudioStatus);
                }
                
                /* If a subwoofer media channel is connected, ensure audio is being routed */
                if (SwatGetMediaState(theSink.rundata->subwoofer.dev_id) == swat_media_streaming)
                {
                    /* ensure sub woofer link type is correct for routed source, sub media type can lag behind */
                    if((theSink.rundata->requested_audio_source == audio_source_AG1)||(theSink.rundata->requested_audio_source == audio_source_AG2))
                        AudioConfigureSubWoofer(AUDIO_SUB_WOOFER_L2CAP, SwatGetMediaSink(theSink.rundata->subwoofer.dev_id));
                }
                else if(SwatGetMediaLLState(theSink.rundata->subwoofer.dev_id) == swat_media_streaming)
                {
                    /* ensure sub woofer link type is correct for routed source, sub media type can lag behind */
                    if((theSink.rundata->requested_audio_source == audio_source_ANALOG)||
                       (theSink.rundata->requested_audio_source == audio_source_SPDIF)||
                       (theSink.rundata->requested_audio_source == audio_source_USB))
                        AudioConfigureSubWoofer(AUDIO_SUB_WOOFER_ESCO, SwatGetMediaSink(theSink.rundata->subwoofer.dev_id));
                }
                /* if not streaming then check if it needs to be connected */
                else
                    audioCheckSubwooferConnection(TRUE);
#endif
            }
        }
        /* no need to make any changes to routing but if the subwoofer is enabled check to see if 
           it requires a media channel to be opened for LFE audio */
        else
        {
#ifdef ENABLE_SUBWOOFER
            bool okToConnectSub = TRUE;
#endif            
            AUD_DEBUG(("AUD: routing, no changes to be made, check sub, source is %d\n",theSink.rundata->routed_audio_source));
            
            /* if currently routed source is AG1 or AG2, check whether it is still A2DP streaming or paused in which case
               need to stop the sub woofer stream */
            if((theSink.rundata->routed_audio_source == audio_source_AG1)||(theSink.rundata->routed_audio_source == audio_source_AG2))
            {
                /* if no longer streaming,unload the dsp to allow switching to sco or a2dp */
                if (((theSink.routed_audio == lAudioStatus->a2dpSinkPri)&&(lAudioStatus->a2dpStatePri != a2dp_stream_streaming)) ||
                    ((theSink.routed_audio == lAudioStatus->a2dpSinkSec)&&(lAudioStatus->a2dpStateSec != a2dp_stream_streaming)) ||
                    ((theSink.routed_audio)&&(theSink.routed_audio != lAudioStatus->sinkAG1)&&
                                                (theSink.routed_audio != lAudioStatus->sinkAG2)&&
                                                (theSink.routed_audio != lAudioStatus->a2dpSinkPri)&&
                                                (theSink.routed_audio != lAudioStatus->a2dpSinkSec)))
                {
                    AUD_DEBUG(("AUD: routing, a2dp stopped, stop sub\n"));
#ifdef ENABLE_SUBWOOFER
                    /* indicate sub has been disconnected, don't reconnect it */
                    okToConnectSub = FALSE;
#endif /* ENABLE_SUBWOOFER */
                    /* disconnect currently routed source */
                    audioDisconnectActiveSink();                    
                    /* indicate source is no longer routed, will be rerouted when next available */
                    theSink.rundata->routed_audio_source = audio_source_none;
                }
#if (defined ENABLE_SUBWOOFER) && (defined ENABLE_AVRCP) && (MAX_AVRCP_CONNECTIONS >=2) && (MAX_A2DP_CONNECTIONS >=2)        
                /* is stream avrcp paused but still streaming? */
                else if((theSink.routed_audio == lAudioStatus->a2dpSinkPri)&&(lAudioStatus->a2dpStatePri == a2dp_stream_streaming)&&(theSink.features.avrcp_enabled))
                {
                    /* if avrcp is connected to the routed a2dp stream */
                    if ((theSink.avrcp_link_data->connected[0])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary],&theSink.avrcp_link_data->bd_addr[0])))        
                    {
                        /* check the current play state */
                        if(theSink.avrcp_link_data->play_status[0] == avrcp_play_status_paused)
                        {
                            AUD_DEBUG(("AUD: routing, a2dp paused, stop sub\n"));
                            /* mute subwoofer and disconnect media channel */                            
                            sendMuteToSubwoofer();
                            /* indicate sub has been disconnected, don't reconnect it */
                            okToConnectSub = FALSE;
                        }
                    }
                    /* if avrcp is connected to the routed a2dp stream */
                    else if ((theSink.avrcp_link_data->connected[1])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary],&theSink.avrcp_link_data->bd_addr[1])))        
                    {
                        /* check the current play state */
                        if(theSink.avrcp_link_data->play_status[1] == avrcp_play_status_paused)
                        {
                            /* mute subwoofer and disconnect media channel */                            
                            sendMuteToSubwoofer();
                            AUD_DEBUG(("AUD: routing, a2dp paused, stop sub\n"));
                            /* indicate sub has been disconnected, don't reconnect it */
                            okToConnectSub = FALSE;
                        }
                    }                            
                }
                /* also check a second instance of A2DP/AVRCP */
                else if((theSink.routed_audio == lAudioStatus->a2dpSinkSec)&&(lAudioStatus->a2dpStateSec == a2dp_stream_streaming)&&(theSink.features.avrcp_enabled))
                {
                    /* if avrcp is connected to the routed a2dp stream */
                    if ((theSink.avrcp_link_data->connected[0])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_secondary],&theSink.avrcp_link_data->bd_addr[0])))        
                    {
                        /* check the current play state */
                        if(theSink.avrcp_link_data->play_status[0] == avrcp_play_status_paused)
                        {
                            AUD_DEBUG(("AUD: routing, a2dp paused, stop sub\n"));
                            /* mute subwoofer and disconnect media channel */                            
                            sendMuteToSubwoofer();
                            /* indicate sub has been disconnected, don't reconnect it */
                            okToConnectSub = FALSE;
                        }
                    }
                    /* if avrcp is connected to the routed a2dp stream */
                    else if ((theSink.avrcp_link_data->connected[1])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_secondary],&theSink.avrcp_link_data->bd_addr[1])))        
                    {
                        if(theSink.avrcp_link_data->play_status[1] == avrcp_play_status_paused)
                        {
                            AUD_DEBUG(("AUD: routing, a2dp paused, stop sub\n"));
                            /* mute subwoofer and disconnect media channel */                            
                            sendMuteToSubwoofer();
                            /* indicate sub has been disconnected, don't reconnect it */
                            okToConnectSub = FALSE;
                        }
                    }                            
                }
#endif /* (defined ENABLE_AVRCP) && (MAX_AVRCP_CONNECTIONS >=2) && (MAX_A2DP_CONNECTIONS >=2)*/
                else if((theSink.routed_audio)&&(!lAudioStatus->a2dpSinkPri)&&(!lAudioStatus->a2dpSinkSec)&&(!lAudioStatus->sinkAG1)&&(!lAudioStatus->sinkAG2))
                {
                    AUD_DEBUG(("AUD: routing, source no longer available, disconnect it %d\n",(uint16)theSink.routed_audio));

                    /* disconnect currently routed source */
                    audioDisconnectActiveSink();     
                    /* indicate source is no longer routed, will be rerouted when next available */
                    theSink.rundata->routed_audio_source = audio_source_none;
                }
            }
            /* when routing a wired input source and the source is now no logner available then disconnect the source */            
            else if(((theSink.rundata->routed_audio_source == audio_source_ANALOG)&&(!analogAudioConnected()))||
                    ((theSink.rundata->routed_audio_source == audio_source_SPDIF)&&(!spdifAudioConnected())))
            {
#ifdef ENABLE_SUBWOOFER
                /* close the sub media channel */
                /* indicate sub has been disconnected, don't reconnect it */
                okToConnectSub = FALSE;
#endif /* ENABLE_SUBWOOFER */
                /* disconnect currently routed source */
                audioDisconnectActiveSink();                    
                /* indicate source is no longer routed, will be rerouted when next available */
                theSink.rundata->routed_audio_source = audio_source_none;                           
            }
#ifdef ENABLE_SUBWOOFER           
            /* If subwoofer is connected but media is closed and not opening, open a media channel (based on the audio source) */
            audioCheckSubwooferConnection(okToConnectSub);            
#endif /* ENABLE_SUBWOOFER */
        }
    }
#endif    

#ifdef ENABLE_PEER
    /* Relay any AV Source stream to a connected Peer */
    audioRelaySourceStream();
#endif

    /* update the display and set audio amp enable pio as appropriate using the newly
       routed audio as the current audio source */
    audioUpdateDisplayAmp(theSink.routed_audio, lAudioStatus);
    
    /* free malloc'd status memory slot */
    freePanic(lAudioStatus);
    
    return status;   
}



#ifdef ENABLE_SUBWOOFER        
/****************************************************************************
NAME    
    audioCheckSubwooferConnection
    
DESCRIPTION
	check the sub woofer connection and streaming status and reconnect/start streaming
    if necessary

RETURNS
    TRUE if sub woofer reconnected, FALSE if no action has been taken
*/
bool audioCheckSubwooferConnection(bool okToConnectSub)
{

    /* If subwoofer is connected but media is closed and not opening, open a media channel (based on the audio source) */
    if ((okToConnectSub)&&(SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id)) && 
        (SwatGetMediaState((theSink.rundata->subwoofer.dev_id)) != swat_media_opening)&&
        (SwatGetMediaLLState((theSink.rundata->subwoofer.dev_id)) != swat_media_opening))
    {
       /* Open the SWAT media channel */
       switch(theSink.rundata->routed_audio_source)
       {
          case audio_source_FM:
          case audio_source_ANALOG:
          case audio_source_SPDIF:
          case audio_source_USB:
          {
              SWAT_DEBUG(("AUD [SW] : Connect eSCO media\n"));
              MessageCancelAll(&theSink.task, EventSysSubwooferOpenLLMedia);
              MessageCancelAll(&theSink.task, EventSysSubwooferOpenStdMedia);
              MessageSend(&theSink.task, EventSysSubwooferOpenLLMedia, 0);
              return TRUE;
          }
          break;
          case audio_source_AG1:
          case audio_source_AG2:
          {
              SWAT_DEBUG(("AUD [SW] : Connect L2CAP media\n"));
              MessageCancelAll(&theSink.task, EventSysSubwooferOpenLLMedia);
              MessageCancelAll(&theSink.task, EventSysSubwooferOpenStdMedia);
              MessageSend(&theSink.task, EventSysSubwooferOpenStdMedia, 0);
              return TRUE;
          }
          break;
          case audio_source_none:
          case audio_source_end_of_list:
              SWAT_DEBUG(("AUD [SW] : CheckSub No Source Defined\n"));
          break;
      } 
   }

    SWAT_DEBUG(("AUD [SW] : CheckSub Sink [%x] MediaType [%x] State [%x]\n",(uint16)SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id),SwatGetMediaType(theSink.rundata->subwoofer.dev_id), SwatGetMediaState(theSink.rundata->subwoofer.dev_id) ));
   
   /* no action required */   
   return FALSE;
}
#endif /* ENABLE_SUBWOOFER */

/****************************************************************************
NAME    
    audioRouteSource
    
DESCRIPTION
	attempt to route the audio for the passed in source

RETURNS
    TRUE if audio routed correctly, FALSE if no audio available yet to route 
*/
bool audioRouteSource(audio_sources source, audio_source_status * lAudioStatus)
{
    bool status = FALSE;
    
    /* if the required source is not currently routed then attempt to route it */
    if(source != audio_source_none)
    {
        /* determine required source and check its availability */
        switch(source)
        {
            /* is FM source available to route? */
            case audio_source_FM:
#ifdef ENABLE_FM
                if(audioFMAvailable(lAudioStatus))
                    status = TRUE;
#endif
            break;
            
            /* is ANALOG source available to route? */
            case audio_source_ANALOG:
#ifdef ENABLE_WIRED  
                if(audioAnalogAvailable(lAudioStatus))
                    status = TRUE;
#endif                
            break;

            /* is SPDIF source available to route? */
            case audio_source_SPDIF:
#ifdef ENABLE_WIRED  
                if(audioSpdifAvailable(lAudioStatus))
                    status = TRUE;
#endif                
            break;

            /* is USB source available to route? */
            case audio_source_USB:
#ifdef ENABLE_USB            
                if(audioUsbAvailable(lAudioStatus))    
                    status = TRUE;
#endif                
            break;

            /* is AG1 source available to route? */
            case audio_source_AG1:
                /* is AG1 sco available? */    
                if(!audioActiveCallScoAvailable(lAudioStatus, hfp_primary_link))
                {
                    /* no AG1 SCO, check for AG1 A2DP */
                    if(audioA2dpStreamAvailable(lAudioStatus, a2dp_primary))
                        status = TRUE;
                }
                else
                    status = TRUE;

            break;

            /* is AG2 source available to route? */
            case audio_source_AG2:    
                /* is AG2 SCO available? */
                if(!audioActiveCallScoAvailable(lAudioStatus, hfp_secondary_link))
                {
                    /* no AG2 SCO, check for AG2 A2DP */
                    if(audioA2dpStreamAvailable(lAudioStatus, a2dp_secondary))
                        status = TRUE;
                }
                else
                    status = TRUE;
            break;

            /* no valid audio requested to be routed */
            default:
            break;
        }       
    }
    /* no audio source requested, disconnect any current auduio that is routed */
    else
    {
        /* is there any audio routed? */
        if(lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: routing, request to suspend/disconnect current source\n"));
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
            /* sucessfully disconnecte audio */    
            status = TRUE;
        }
    }
    
#ifdef ENABLE_DISPLAY    
    switch(theSink.rundata->routed_audio_source)
    {
        case audio_source_FM:     
            displayShowSimpleText("FM",1);
            break;
        case audio_source_ANALOG:
            displayShowSimpleText("Analogue",1);
            break;
        case audio_source_SPDIF:
            displayShowSimpleText("SPDIF",1);
            break;
        case audio_source_USB:
            displayShowSimpleText("USB",1);
            break;
        case audio_source_AG1:
            displayShowSimpleText("AG 1",1);
            break;            
        case audio_source_AG2:
            displayShowSimpleText("AG 2",1);
            break;            
        default:
            displayShowSimpleText(DISPLAYSTR_CLEAR,1);
            break;
    }         
#endif            
    
    /* indicate whether audio was successfully routed or not */
    return status;
}
        
        
/****************************************************************************
NAME    
    audioActiveCallScoAvailable
    
DESCRIPTION
    checks for any sco being present, check whether there is a corresponding
    active call and route it based on its priority. check whether sco is already
    routed or whether a different audio source needs to be suspended/disconnected
    
RETURNS
    true if sco routed, false if no sco routable
*/
bool audioActiveCallScoAvailable(audio_source_status * lAudioStatus, hfp_link_priority priority)
{
    Sink sinkToRoute = 0;

    AUD_DEBUG(("AUD: Sco Status state p[%d] s[%d] sink p[%d] s[%d]\n" , lAudioStatus->stateAG1, lAudioStatus->stateAG2,(uint16)lAudioStatus->sinkAG1, (uint16)lAudioStatus->sinkAG2)) ;   

    if (isAudioGated(audio_gate_call))
    {
        AUD_DEBUG(("AUD: Call SCO gated\n"));
        if (lAudioStatus->audio_routed && 
            ((lAudioStatus->audio_routed == lAudioStatus->sinkAG1) || 
             (lAudioStatus->audio_routed == lAudioStatus->sinkAG2)) )
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }
    
    /* determine number of scos and calls if any */
    if((lAudioStatus->sinkAG1 && (lAudioStatus->stateAG1 > hfp_call_state_idle))&&(lAudioStatus->sinkAG2 && (lAudioStatus->stateAG2 > hfp_call_state_idle)))
    {
        AUD_DEBUG(("AUD: two scos\n"));
        /* two calls and two sco's exist, determine which sco has the highest priority */
        if(getScoPriorityFromHfpPriority(hfp_secondary_link) > getScoPriorityFromHfpPriority(hfp_primary_link))
        {
            AUD_DEBUG(("AUD: route - sec > pri = [%d] [%d] :\n" , (uint16)getScoPriorityFromHfpPriority(hfp_primary_link), (uint16)getScoPriorityFromHfpPriority(hfp_secondary_link))) ;   
            sinkToRoute = lAudioStatus->sinkAG2;            
            theSink.rundata->routed_audio_source = audio_source_AG2;
        }
        /* primary is higher priority so route that instead */
        else
        {
            AUD_DEBUG(("AUD: route - pri > sec = [%d] [%d] :\n" , (uint16)getScoPriorityFromHfpPriority(hfp_primary_link), (uint16)getScoPriorityFromHfpPriority(hfp_secondary_link))) ;   
            sinkToRoute = lAudioStatus->sinkAG1;            
            theSink.rundata->routed_audio_source = audio_source_AG1;
        }
    }
    /* primary AG call + sco only? or pri sco and voice dial is active? */    
    else if( lAudioStatus->sinkAG1 && 
            ((lAudioStatus->stateAG1 > hfp_call_state_idle)||(theSink.VoiceRecognitionIsActive))
           )
    {
        AUD_DEBUG(("AUD: AG1 sco\n"));
        /* AG1 (primary) call with sco only */
        sinkToRoute = lAudioStatus->sinkAG1;
        theSink.rundata->routed_audio_source = audio_source_AG1;
    }
    /* secondary AG call + sco only? or sec sco and voice dial is active? */    
    else if( lAudioStatus->sinkAG2 && 
            ((lAudioStatus->stateAG2 > hfp_call_state_idle)||(theSink.VoiceRecognitionIsActive))
           )
    {
        AUD_DEBUG(("AUD: AG2 sco\n"));
        /* AG2 (secondary) call with sco only */
        sinkToRoute = lAudioStatus->sinkAG2;
        theSink.rundata->routed_audio_source = audio_source_AG2;
    }
    /* if there is an incoming call with no sco, i.e. out of band rintone, disconnect any other audio source
       and allow out of band ringtone to play */
    else if((lAudioStatus->stateAG1 == hfp_call_state_incoming)||(lAudioStatus->stateAG2 == hfp_call_state_incoming))
    {
        /* if any non sco audio source is currently routed then disconnect it to play
           the out of band ringtone */
        if(lAudioStatus->audio_routed)
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        /* indicate a successful operation to prevent other audio sources being connected */
        return TRUE;        
    }
    
    /* is there a sco sink that needs to be routed? */
    if(sinkToRoute)
    {
        AUD_DEBUG(("AUD: sco sink to route\n"));

        /* determine if any other audio source is currently being route and suspend/disconnect it 
           before connecting up new sco audio source, if this source is already being
           routed then do nothing */
        if(sinkToRoute != lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: sco sink not yet routed\n"));

            /* is there already audio routed? */
            if(lAudioStatus->audio_routed)
            {
                AUD_DEBUG(("AUD: other audio source routed, disconnect it first\n"));

                /* suspend or disconnect the current audio source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            AUD_DEBUG(("AUD: connect sco sink %x\n",(uint16)sinkToRoute));
            /* connect up the requested sco sink */
            audioConnectScoSink(HfpLinkPriorityFromAudioSink(sinkToRoute), sinkToRoute);
        }
        /* sco audio routed */
        return TRUE;
    }
    /* no sco audio found to route */
    return FALSE;
}


/****************************************************************************
NAME    
    audioRelaySourceStream
    
DESCRIPTION
    Checks for a Peer relay (source) stream and asks DSP to relay audio from any active AV Source
    
RETURNS
    true if audio relayed, false otherwise
*/
bool audioRelaySourceStream (void)
{
#ifdef ENABLE_PEER
    if (!isAudioGated(audio_gate_relay) && (theSink.peer.current_source != RELAY_SOURCE_NULL) && (theSink.peer.current_state >= RELAY_STATE_STARTING))
    {   /* We have an active relay stream, thus we must be wanting to forward audio data to a Peer */
        Sink av_sink;
        Sink peer_sink;
        
        /* Obtain Source and Peer sinks while doing some sanity checking */
        if (((peer_sink = peerGetPeerSink())!=NULL) && ((av_sink = peerGetSourceSink())!=NULL) && (theSink.routed_audio == av_sink))
        {   /* Outbound forwarding stream will only be connected if main inbound stream is routed */
            uint16 peer_idx;
            
            if (a2dpGetPeerIndex(&peer_idx))
            {
                if(!IsAudioRelaying())
                {
                    a2dp_codec_settings *codec_settings = A2dpCodecGetSettings(theSink.a2dp_link_data->device_id[peer_idx], theSink.a2dp_link_data->stream_id[peer_idx]);
                    
                    if (codec_settings)
                    {
                        AUD_DEBUG(("AUD: Start forwarding sink 0x%X seid=0x%X\n", (uint16)peer_sink, codec_settings->seid )) ;
                        AudioStartForwarding( getA2dpPlugin(codec_settings->seid), peer_sink, codec_settings->codecData.content_protection!=avdtp_no_protection );
                        free(codec_settings);
                        
                        AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
                    }
                }
                
                return TRUE;
            }
        }
    }
    
    if (theSink.routed_audio)
    {   /* Only attempt to stop forwarding if there is a routed stream (and hence codec loaded) */
        AUD_DEBUG(("AUD: Stop forwarding\n")) ;
        AudioStopForwarding();
    }
#endif
    
    return FALSE;
}    


/****************************************************************************
NAME    
    audioA2dpStreamAvailable
    
DESCRIPTION
    checks for any a2dp streams being present and routes them if present, if no
    streaming connections check for suspended streams and resume them
    
RETURNS
    true if a2dp routed, false if no a2dp routable
*/
bool audioA2dpStreamAvailable(audio_source_status * lAudioStatus, a2dp_link_priority priority)
{
    bool routed = FALSE;
    a2dp_link_priority linkPri = priority;    
    
    if (isAudioGated(audio_gate_a2dp))
    {
        AUD_DEBUG(("AUD: A2DP gated\n"));
        if (lAudioStatus->audio_routed && 
            ((lAudioStatus->audio_routed == lAudioStatus->a2dpSinkPri) || 
             (lAudioStatus->audio_routed == lAudioStatus->a2dpSinkSec)) )
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }
    
    /* are both primary and secondary a2dp sources streaming streaming audio and one of them
        currently routed?, if so use AVRCP play status to decide if it needs to be swapped
        or left alone, if neither is routed then drop through to connecting the primary sink */
    if(((priority == a2dp_pri_sec)&&(lAudioStatus->a2dpStatePri == a2dp_stream_streaming)&&(lAudioStatus->a2dpStateSec == a2dp_stream_streaming))&&
       ((lAudioStatus->a2dpRolePri == a2dp_sink)&&(lAudioStatus->a2dpRoleSec == a2dp_sink))&&
       ((lAudioStatus->a2dpSinkPri == lAudioStatus->audio_routed)||(lAudioStatus->a2dpSinkSec == lAudioStatus->audio_routed)))     
    {
#if (defined ENABLE_AVRCP) && (MAX_AVRCP_CONNECTIONS >=2) && (MAX_A2DP_CONNECTIONS >=2)        
        uint16 avrcpIndex;
        /* default play status to Playing as in a streaming state */
        uint16 priPlayStatus = avrcp_play_status_playing;
        uint16 secPlayStatus = avrcp_play_status_playing;
        
        if(!theSink.features.avrcp_enabled ||
           !theSink.features.EnableAvrcpAudioSwitching)
        {
            AUD_DEBUG(("AUD: ignore AVRCP in audio switching\n"));
            return TRUE;
        }
        
        AUD_DEBUG(("AUD: play status avrcp 0 (%u,%u), avrcp 1 (%u,%u) \n",
                   theSink.avrcp_link_data->connected[0],theSink.avrcp_link_data->play_status[0],
                   theSink.avrcp_link_data->connected[1],theSink.avrcp_link_data->play_status[1]));
                       
        /* if AVRCP is connected get the play status, if it's not then assume Playing as at this point there is
            an A2DP stream active */ 
        if (theSink.avrcp_link_data->connected[0])
        {
            priPlayStatus = theSink.avrcp_link_data->play_status[0];
        }
            
        if (theSink.avrcp_link_data->connected[1])
        {
            secPlayStatus = theSink.avrcp_link_data->play_status[1];
        }
            
        /* Compare play status to see if one is in a play state (or fwd or rwd seek) while the other is not.
           If there is no AVRCP connections this will fall through to making no changes as there is nothing to make a better 
           decision with (both will be set to 'Playing') */
        if((priPlayStatus == avrcp_play_status_playing || priPlayStatus == (1 << avrcp_play_status_fwd_seek) || priPlayStatus == (1 << avrcp_play_status_rev_seek)) &&
           (secPlayStatus != avrcp_play_status_playing && secPlayStatus != (1 << avrcp_play_status_fwd_seek) && secPlayStatus != (1 << avrcp_play_status_rev_seek)))
        { 
            avrcpIndex = 0;
        }
        else if((secPlayStatus == avrcp_play_status_playing || secPlayStatus == (1 << avrcp_play_status_fwd_seek) || secPlayStatus == (1 << avrcp_play_status_rev_seek)) && 
                (priPlayStatus != avrcp_play_status_playing && priPlayStatus != (1 << avrcp_play_status_fwd_seek) && priPlayStatus != (1 << avrcp_play_status_rev_seek)))
        {                
            avrcpIndex = 1;
        }
        else
        {
            /* leave routing as it is, both are probably in Playing state or neither have AVRCP
               and we don't know any better */
            AUD_DEBUG(("AUD: ignore AVRCP in audio switching leave alone\n"));
            return TRUE;
        }
        
        /* Check if the selected AVRCP channel is connected */
        if (theSink.avrcp_link_data->connected[avrcpIndex])
        {
            linkPri = BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary], 
                                   &theSink.avrcp_link_data->bd_addr[avrcpIndex])  ?  a2dp_primary : a2dp_secondary;        
        }
        else
        {
            /* AVRCP is not connected to the selected stream, find the A2DP for the other AVRCP instance and select the opposite */
            linkPri = BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary], 
                                   &theSink.avrcp_link_data->bd_addr[avrcpIndex=0?1:0])  ?  a2dp_secondary : a2dp_primary;        
        }        

        AUD_DEBUG(("AUD: select avrcp %u, a2dp %u\n", avrcpIndex, linkPri));
      
#else       
        /* with no AVRCP leave audio routing as is*/
        return TRUE;   
#endif           
    }        
    
    /* no active streams, are there any suspended streams? */    
    if((linkPri != a2dp_secondary)&&(a2dpSuspended(a2dp_primary)==a2dp_local_suspended)&&(lAudioStatus->a2dpRolePri == a2dp_sink))
    {
        AUD_DEBUG(("AUD: route - a2dp suspended, resume primary\n" )) ;   
        /* is there already audio routed? */
        if(lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: pri a2dp other source connected, disconnect\n"));
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        /* send avrcp play or a2dp start to resume audio and connect it */        
        ResumeA2dpStream(a2dp_primary, lAudioStatus->a2dpStatePri, lAudioStatus->a2dpSinkPri);       
        /* successfull issued restart of audio */
        routed = TRUE;
    }
    else if((linkPri != a2dp_primary)&&(a2dpSuspended(a2dp_secondary)==a2dp_local_suspended)&&(lAudioStatus->a2dpRoleSec == a2dp_sink))
    {
        AUD_DEBUG(("AUD: route - a2dp suspended, resume secondary\n" )) ;   
        /* is there already audio routed? */
        if(lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: pri a2dp other source connected, disconnect\n"));
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        ResumeA2dpStream(a2dp_secondary, lAudioStatus->a2dpStateSec, lAudioStatus->a2dpSinkSec);                     
        /* successfull issued restart of audio */
        routed = TRUE;
    }
    /* is primary a2dp streaming audio? */
    else if((linkPri != a2dp_secondary)&&((lAudioStatus->a2dpStatePri == a2dp_stream_starting)||(lAudioStatus->a2dpStatePri == a2dp_stream_streaming))&&(a2dpSuspended(a2dp_primary)==a2dp_not_suspended)&&(lAudioStatus->a2dpRolePri == a2dp_sink))
    {
        AUD_DEBUG(("AUD: pri a2dp streaming\n"));
        /* is it currently already routed? */
        if(lAudioStatus->audio_routed != lAudioStatus->a2dpSinkPri)
        {
            AUD_DEBUG(("AUD: pri a2dp not yet routed\n"));
            /* is there already audio routed? */
            if(lAudioStatus->audio_routed)
            {
                AUD_DEBUG(("AUD: pri a2dp other source connected, disconnect\n"));
                /* suspend or disconnect the current audio source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            /* route a2dp primary audio */
            AUD_DEBUG(("AUD: route - no sink and a2dp streaming connect Pri A2dp:\n" )) ;           
            A2dpRouteAudio(a2dp_primary, lAudioStatus->a2dpSinkPri);        
            theSink.rundata->routed_audio_source = audio_source_AG1;
        } 
        
        /* successfully routed audio */
        routed = TRUE;
    }
    /* or a2dp secondary streaming audio */    
    else if((linkPri != a2dp_primary)&&((lAudioStatus->a2dpStateSec == a2dp_stream_starting)||(lAudioStatus->a2dpStateSec == a2dp_stream_streaming))&&(a2dpSuspended(a2dp_secondary)==a2dp_not_suspended)&&(lAudioStatus->a2dpRoleSec == a2dp_sink))
    {
        AUD_DEBUG(("AUD: sec a2dp streaming\n"));
        /* is it currently already routed? */
        if(lAudioStatus->audio_routed != lAudioStatus->a2dpSinkSec)
        {
            AUD_DEBUG(("AUD: sec a2dp not yet routed\n"));
            /* is there already audio routed? */
            if(lAudioStatus->audio_routed)
            {
                /* suspend or disconnect the current audio source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            /* route a2dp secondary audio */
            AUD_DEBUG(("AUD: route - no sink and a2dp streaming connect Sec A2dp:\n" )) ;           
            A2dpRouteAudio(a2dp_secondary, lAudioStatus->a2dpSinkSec);
            theSink.rundata->routed_audio_source = audio_source_AG2;                      
        } 
        
        /* successfully routed audio */
        routed = TRUE;
    }
    else
    {
        AUD_DEBUG(("AUD: failed to route any a2dp audio\n"));        
    }
    
    return routed;
}


#ifdef ENABLE_USB
/****************************************************************************
NAME    
    audioUsbAvailable
    
DESCRIPTION
    checks for a usb stream being present and routes it if present
    
RETURNS
    true if usb routed, false if no usb routable
*/
bool audioUsbAvailable(audio_source_status * lAudioStatus)
{
    Sink usb_sink = usbGetAudioSink();
    
    if (isAudioGated(audio_gate_usb))
    {
        AUD_DEBUG(("AUD: USB gated\n"));
        if (lAudioStatus->audio_routed && (lAudioStatus->audio_routed == usb_sink))
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }
    
    /* is there USB audio available? */    
    if(usb_sink)
    {
        /* USB audio available, is USB audio already routed? */
        if(lAudioStatus->audio_routed)
        {
            /* is routed audio already USB? */
            if(!(lAudioStatus->audio_routed == usb_sink))
            {
                AUD_DEBUG(("AUD: USB audio but not USB, suspend/disconnect\n"));
                /* usb audio not routed, disconnect current source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            /* USB audio already routed, do nothing */
            else
                return TRUE;
        }
    
        /* route USB audio */
        usbAudioRoute();     
        
        theSink.rundata->routed_audio_source = audio_source_USB;

        AUD_DEBUG(("AUD: USB audio routed\n"));

        /* USB audio correctly routed */
        return TRUE;   
    }
    else if (usbAudioSuspended() == usb_audio_suspend_local)
    {
        if(lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: USB audio suspended, disconnect other source\n"));
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        
        usbAudioResume();
        return TRUE;
    }
    /* not able to route usb audio */    
    else 
    {
        AUD_DEBUG(("AUD: USB audio NOT routed\n"));
        return FALSE;
    }
}
#endif


#ifdef ENABLE_WIRED
/****************************************************************************
NAME    
    audioAnalogAvailable
    
DESCRIPTION
    checks for an analog audio stream being present and routes it if present
    
RETURNS
    true if analog audio routed, false if no analog audio routable
*/
bool audioAnalogAvailable(audio_source_status * lAudioStatus)
{
    if (isAudioGated(audio_gate_wired))
    {
        AUD_DEBUG(("AUD: Analogue gated\n"));
        if (lAudioStatus->audio_routed && analogAudioSinkMatch(lAudioStatus->audio_routed))
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }
    
    /* is the wired audio connection available? */
    if(analogAudioConnected())
    {
        /* is some audio already routed? */
        if(lAudioStatus->audio_routed)
        {
            /* is routed audio already wired audio? */
            if(!analogAudioSinkMatch(lAudioStatus->audio_routed))
            {
                /* wired audio not routed, disconnect current source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            /* ANALOG audio already routed, do nothing */
            else
            {
                AUD_DEBUG(("AUD: Analog audio already routed\n"));
                return TRUE;
            }
        }
        
        /* route analog audio */
        analogAudioRoute();
        
        theSink.rundata->routed_audio_source = audio_source_ANALOG;

        AUD_DEBUG(("AUD: Analog audio routed\n"));
        
        return TRUE;
    }
    /* not able to route wired audio */    
    else 
    {
        return FALSE;
    }
}

/****************************************************************************
NAME    
    audioSpdifAvailable
    
DESCRIPTION
    checks for an spdif audio stream being present and routes it if present
    
RETURNS
    true if spdif audio routed, false if no spdif audio routable
*/
bool audioSpdifAvailable(audio_source_status * lAudioStatus)
{
    if (isAudioGated(audio_gate_wired))
    {
        AUD_DEBUG(("AUD: SPDIF gated\n"));
        if (lAudioStatus->audio_routed && spdifAudioSinkMatch(lAudioStatus->audio_routed))
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }

    /* is the wired audio connection available? */
    if(spdifAudioConnected())
    {
        /* is some audio already routed? */
        if(lAudioStatus->audio_routed)
        {
            /* is routed audio already wired audio? */
            if(!spdifAudioSinkMatch(lAudioStatus->audio_routed))
            {
                /* wired audio not routed, disconnect current source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            /* SPDIF audio already routed, do nothing */
            else
            {
                AUD_DEBUG(("AUD: Spdif audio already routed\n"));
                return TRUE;
            }
        }
        
        /* route analog audio */
        spdifAudioRoute();
        
        theSink.rundata->routed_audio_source = audio_source_SPDIF;

        AUD_DEBUG(("AUD: spdif audio routed\n"));
        
        return TRUE;
    }
    /* not able to route spdif audio */    
    else 
    {
        return FALSE;
    }
}
#endif

#ifdef ENABLE_FM

/****************************************************************************
NAME    
    audioFMAvailable
    
DESCRIPTION
    checks for an fm audio stream being present and routes it if present  
    
RETURNS
    true if fm routed, false if no fm routed
*/
bool audioFMAvailable(audio_source_status * lAudioStatus)
{
    /* insert fm audio check/connection here */
    Sink fm_sink = FM_SINK;

    if (isAudioGated(audio_gate_fm))
    {
        AUD_DEBUG(("AUD: FM gated\n"));
        if (lAudioStatus->audio_routed && (lAudioStatus->audio_routed == fm_sink))
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }

    /* is there FM audio available? */    
    if (theSink.conf2->sink_fm_data.fmRxOn) 
    {
        /* FM audio available, is FM audio already routed? */
        if(lAudioStatus->audio_routed)
        {
            /* is routed audio already FM? */
            if(!(lAudioStatus->audio_routed == fm_sink))
            {
                AUD_DEBUG(("AUD: audio but not FM, suspend/disconnect\n"));
                /* FM audio not routed, disconnect current source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            /* FM audio already routed, do nothing */
            else
                return TRUE;
        }

        /* route FM audio */
        theSink.routed_audio=FM_SINK;
        sinkFmRxAudioConnect();
        AUD_DEBUG(("AUD: FM audio routed\n"));

        /* FM audio correctly routed */
        return TRUE;   
    }
    /* not able to route FM audio */
    else 
    {
        return FALSE;
    }
}
#endif


/****************************************************************************
NAME    
    audioScoAvailable
    
DESCRIPTION
    checks for any sco being present without any call indications
    
RETURNS
    true if sco routed, false if no sco routable
*/
bool audioScoAvailable(audio_source_status * lAudioStatus)
{
    Sink sinkToRoute = 0;

    AUD_DEBUG(("AUD: Sco Status state p[%d] s[%d] sink p[%d] s[%d]\n" , lAudioStatus->stateAG1, lAudioStatus->stateAG2,(uint16)lAudioStatus->sinkAG1, (uint16)lAudioStatus->sinkAG2)) ;   

    if (isAudioGated(audio_gate_sco))
    {
        AUD_DEBUG(("AUD: SCO (non-call) gated\n"));
        if (lAudioStatus->audio_routed && 
            ((lAudioStatus->audio_routed == lAudioStatus->sinkAG1) || 
             (lAudioStatus->audio_routed == lAudioStatus->sinkAG2)) )
        {
            /* suspend or disconnect the current audio source */
            audioSuspendDisconnectSource(lAudioStatus);
        }
        return FALSE;
    }
        
    /* check whether any sco sinks are available to route */
    if(lAudioStatus->sinkAG1)
        sinkToRoute = lAudioStatus->sinkAG1;
    else if(lAudioStatus->sinkAG2)
        sinkToRoute = lAudioStatus->sinkAG2;
        
    /* is there a sco sink that needs to be routed? */
    if(sinkToRoute)
    {
        AUD_DEBUG(("AUD: sco sink to route\n"));

        /* determine if any other audio source is currently being route and suspend/disconnect it 
           before connecting up new sco audio source, if this source is already being
           routed then do nothing */
        if(sinkToRoute != lAudioStatus->audio_routed)
        {
            AUD_DEBUG(("AUD: sco sink not yet routed\n"));

            /* is there already audio routed? */
            if(lAudioStatus->audio_routed)
            {
                AUD_DEBUG(("AUD: other audio source routed, disconnect it first\n"));

                /* suspend or disconnect the current audio source */
                audioSuspendDisconnectSource(lAudioStatus);
            }
            AUD_DEBUG(("AUD: connect sco sink %x\n",(uint16)sinkToRoute));
            /* connect up the requested sco sink */
            audioConnectScoSink(HfpLinkPriorityFromAudioSink(sinkToRoute), sinkToRoute);
        }
        /* sco audio routed */
        return TRUE;
    }
    /* no sco audio found to route */
    return FALSE;
}

/****************************************************************************
NAME    
    audioSuspendDisconnectSource
    
DESCRIPTION
    determines source of sink passed in and decides whether to issue a suspend or
    not based on source type, an audio disconnect is performed thereafter regardless
    of wether or not the source requires a suspend
    
RETURNS
    true if audio disconnected, false if no action taken
*/
bool audioSuspendDisconnectSource(audio_source_status * lAudioStatus)
{
    bool status = FALSE;
    bool peer_has_call = FALSE;

#ifdef ENABLE_PEER    
    uint16 peer_id;
    if (a2dpGetPeerIndex(&peer_id) && (theSink.a2dp_link_data->remote_peer_status[peer_id] & PEER_STATUS_IN_CALL))
    {
        peer_has_call = TRUE;
    }
#endif

    /* is source a2dp? */    
    if(lAudioStatus->audio_routed == lAudioStatus->a2dpSinkPri)
    {
        /* determine if there is a sco/call on same AG, if feature is set to not
           suspend then do nothing otherwise suspend AG */
        if( (!theSink.features.AssumeAutoSuspendOnCall) || (theSink.VoiceRecognitionIsActive) ||
            ((lAudioStatus->stateAG1 > hfp_call_state_idle) && (lAudioStatus->stateAG2 == hfp_call_state_idle) && !deviceManagerIsSameDevice(a2dp_primary, hfp_primary_link)) || 
            ((lAudioStatus->stateAG2 > hfp_call_state_idle) && (lAudioStatus->stateAG1 == hfp_call_state_idle) && !deviceManagerIsSameDevice(a2dp_primary, hfp_secondary_link)) ||
            (theSink.features.TwsSingleDeviceOperation && peer_has_call) )
        {
            AUD_DEBUG(("AUD: suspend a2dp primary audio \n"));
            SuspendA2dpStream(a2dp_primary);
        }
        /* and disconnect the routed sink */
        AUD_DEBUG(("AUD: disconnect a2dp primary audio \n"));
        audioDisconnectActiveSink();
        /* successfully disconnected audio */        
        status = TRUE;
    }
    else if(lAudioStatus->audio_routed == lAudioStatus->a2dpSinkSec)
    {
        /* determine if there is a sco/call on same AG, if feature is set to not
           suspend then do nothing otherwise suspend AG */
        if( (!theSink.features.AssumeAutoSuspendOnCall) || (theSink.VoiceRecognitionIsActive) ||
            ((lAudioStatus->stateAG1 != hfp_call_state_idle) && (lAudioStatus->stateAG2 == hfp_call_state_idle) && !deviceManagerIsSameDevice(a2dp_secondary, hfp_primary_link)) || 
            ((lAudioStatus->stateAG2 != hfp_call_state_idle) && (lAudioStatus->stateAG1 == hfp_call_state_idle) && !deviceManagerIsSameDevice(a2dp_secondary, hfp_secondary_link)) ||
            (theSink.features.TwsSingleDeviceOperation && peer_has_call) )
        {
            AUD_DEBUG(("AUD: suspend a2dp secondary audio \n"));
            SuspendA2dpStream(a2dp_secondary);
        }
        /* and disconnect the routed sink */
        AUD_DEBUG(("AUD: disconnect a2dp secondary audio \n"));
        audioDisconnectActiveSink();
        /* successfully disconnected audio */        
        status = TRUE;
    }
#ifdef ENABLE_USB
    else if(usbAudioSinkMatch(lAudioStatus->audio_routed)) 
    {
        /* Disconnect any USB audio */
        AUD_DEBUG(("AUD: disconnect USB audio \n"));
#ifdef ENABLE_SUBWOOFER
        /* mute the subwoofer */
        sendMuteToSubwoofer();        
#endif
        usbAudioDisconnect();
        /* successfully disconnected audio */        
        status = TRUE;
    }
#endif
#ifdef ENABLE_WIRED    
    else if((analogAudioSinkMatch(lAudioStatus->audio_routed))||(spdifAudioSinkMatch(lAudioStatus->audio_routed)))
    {
        /* Disconnect any wired audio */
        AUD_DEBUG(("AUD: disconnect wired audio \n"));
#ifdef ENABLE_SUBWOOFER
        /* mute the subwoofer */
        sendMuteToSubwoofer();        
#endif
        wiredAudioDisconnect();
        /* successfully disconnected audio */        
        status = TRUE;
    }
#endif
#ifdef ENABLE_FM
    else if (sinkFmAudioSinkMatch(lAudioStatus->audio_routed))
    {
        /* suspend FM */
        AUD_DEBUG(("AUD: disconnect FM audio \n"));
#ifdef ENABLE_SUBWOOFER
        /* mute the subwoofer */
        sendMuteToSubwoofer();        
#endif
        sinkFmRxAudioDisconnect();
        /* successfully disconnected audio */        
        status = TRUE;
    }
#endif    
    /* SCO audio sources */
    else
    {
        /* disconnect SCO audio sources */
        AUD_DEBUG(("AUD: disconnect SCO audio %x\n",(uint16)theSink.routed_audio));
        audioDisconnectActiveSink(); 
        /* successfully disconnected audio */        
        status = TRUE;
    }

    /* update the currently routed source */
    if(status == TRUE)
        theSink.rundata->routed_audio_source = audio_source_none;
    
    /* provide feedback on whether audio got disconnected or not */
    return status;
}



/****************************************************************************
NAME    
    audioUpdateDisplayAmp
    
DESCRIPTION
    update the display if applicable and control the audio amp pio
    
RETURNS
    none
*/
void audioUpdateDisplayAmp(Sink audio_routed, audio_source_status * lAudioStatus)
{
    /* if any audio present display volume level and turn on audio amp - Update SWAT volume */
    if(audio_routed)
    {           
#if defined ENABLE_DISPLAY || defined ENABLE_SUBWOOFER
        int16 volume = theSink.features.DefaultVolume;  

        /* synchronise displayed volume */        
        if (audio_routed == lAudioStatus->a2dpSinkPri)
        {
            AUD_DEBUG(("AUD: disp vol a2dp1\n")) ;   
            volume = theSink.volume_levels->a2dp_volume[a2dp_primary].masterVolume;
        }       
        else if (audio_routed == lAudioStatus->a2dpSinkSec)
        {
            AUD_DEBUG(("AUD: disp vol a2dp2\n")) ;   
            volume = theSink.volume_levels->a2dp_volume[a2dp_secondary].masterVolume;
        }      
        else if (audio_routed == lAudioStatus->sinkAG1)
        {
            AUD_DEBUG(("AUD: disp vol hfp1\n")) ;   
            volume = theSink.profile_data[PROFILE_INDEX(hfp_primary_link)].audio.gSMVolumeLevel;
        }       
        else if (audio_routed == lAudioStatus->sinkAG2)
        {
            AUD_DEBUG(("AUD: disp vol hfp2\n")) ;   
            volume = theSink.profile_data[PROFILE_INDEX(hfp_secondary_link)].audio.gSMVolumeLevel;
        }
#ifdef ENABLE_USB
        else if (usbAudioSinkMatch(audio_routed))
        {
            usb_device_class_audio_levels *levels = mallocPanic(sizeof (usb_device_class_audio_levels));
            
            AUD_DEBUG(("AUD: disp vol usb\n")) ;   
            if (levels)
            {
                UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_LEVELS, (uint16 *) levels);
            
                /* convert to signed 16 */
                levels->out_l_vol = (int16)(int8)(levels->out_l_vol>>8);
                levels->out_r_vol = (int16)(int8)(levels->out_r_vol>>8);

                /* convert to volume steps */
                volume = (theSink.conf1->volume_config.volume_control_config.no_of_steps - ((levels->out_l_vol * theSink.conf1->volume_config.volume_control_config.no_of_steps)/-60));
    
                /* limit check */
                if(volume >= theSink.conf1->volume_config.volume_control_config.no_of_steps)
                    volume = (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1);
                if(volume < 0)
                    volume = 0;        
               
                if (theSink.usb.config.plugin_type != usb_plugin_stereo)
                    volume = levels->out_l_vol;
                
                freePanic(levels);
            }
        }
#endif /* def ENABLE_USB */
#ifdef ENABLE_WIRED
        else if (analogAudioSinkMatch(audio_routed))
        {
            AUD_DEBUG(("AUD: disp vol wired\n")) ;   
            volume = theSink.volume_levels->analog_volume.masterVolume;
        }
        else if (spdifAudioSinkMatch(audio_routed))
        {
            AUD_DEBUG(("AUD: disp vol wired\n")) ;   
            volume = theSink.volume_levels->spdif_volume.masterVolume;
        }
#endif /* def ENABLE_WIRED */       
        
#endif /* def ENABLE_DISPLAY || ENABLE_SUBWOOFER */
        
#ifdef ENABLE_DISPLAY
        displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * volume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
#endif
        
#ifdef ENABLE_SUBWOOFER
        updateSwatVolume(volume);
#endif
        
        /* turn on/off AMP pio drive */    
        if(audio_routed)
            PioSetPio ( theSink.conf1->PIOIO.pio_outputs.DeviceAudioActivePIO , pio_drive, TRUE) ;            
    }
    /* no audio routed, turn off amp */
    else
        PioSetPio ( theSink.conf1->PIOIO.pio_outputs.DeviceAudioActivePIO , pio_drive, FALSE) ;
    
}

/****************************************************************************
NAME    
    audioConnectScoSink
    
DESCRIPTION
    Route audio from a given SCO sink

RETURNS
    
*/
void audioConnectScoSink(hfp_link_priority priority, Sink sink)
{
    /* If there is another sink connected, disconnect it */
    if((theSink.routed_audio) && (theSink.routed_audio != sink))
        audioDisconnectActiveSink();
    /* if no audio routed then connect it up, it could already be routed to intended sco */
    if(!theSink.routed_audio)
        audioHfpConnectAudio(priority, sink);
}

/****************************************************************************
NAME    
    audioDisconnectActiveSink
    
DESCRIPTION
    Disconnect the active audio sink

RETURNS
    
*/
void audioDisconnectActiveSink(void)
{
    if(theSink.routed_audio)
    {
        AUD_DEBUG(("AUD: route - audio disconnect = [%X] :\n" , (uint16)theSink.routed_audio)) ;   
#ifdef ENABLE_SUBWOOFER
        /* mute the subwoofer */
        sendMuteToSubwoofer();        
#endif
        /* sco no longer valid so disconnect sco */
        AudioDisconnect();
        /* clear routed_audio value to indicate no routed audio */
        theSink.routed_audio = 0;  
    }
}

/****************************************************************************
NAME    
    audioGetStatus
    
DESCRIPTION
    malloc slot and get status of sco/calls and a2do links, significantly
    reduces stack usage at the expense of a temporary slot use

RETURNS
    ptr to structure containing audio statuses
*/
audio_source_status * audioGetStatus(Sink routed_audio)
{
    /* use temporary memory slot for storing current audio sources */
    audio_source_status * lAudioStatus = mallocPanic(sizeof(audio_source_status));        

    /* store currently routed audio */
    lAudioStatus->audio_routed = routed_audio;
    
    /* get AG1 and AG2 call current states if connected */
    HfpLinkGetCallState(hfp_primary_link, &lAudioStatus->stateAG1);
    HfpLinkGetCallState(hfp_secondary_link, &lAudioStatus->stateAG2);
    
    /* get audio sink for AGs if available */
    HfpLinkGetAudioSink(hfp_primary_link, &lAudioStatus->sinkAG1);
    HfpLinkGetAudioSink(hfp_secondary_link, &lAudioStatus->sinkAG2);  
    
    /* get status of current a2dp links */
    getA2dpStreamData(a2dp_primary,   &lAudioStatus->a2dpSinkPri, &lAudioStatus->a2dpStatePri);
    getA2dpStreamData(a2dp_secondary, &lAudioStatus->a2dpSinkSec, &lAudioStatus->a2dpStateSec);
    
    getA2dpStreamRole(a2dp_primary, &lAudioStatus->a2dpRolePri);
    getA2dpStreamRole(a2dp_secondary, &lAudioStatus->a2dpRoleSec);
    
    return lAudioStatus;
}

#ifdef ENABLE_SOUNDBAR
#ifdef ENABLE_SUBWOOFER

/****************************************************************************
NAME    
    audioSuspendDisconnectAllA2dpMedia
    
DESCRIPTION
    called when the SUB link wants to use an ESCO link, there is not enough
    link bandwidth to support a2dp media and esco links so suspend or disconnect
    all a2dp media streams
    
RETURNS
    true if audio disconnected, false if no action taken
*/
bool audioSuspendDisconnectAllA2dpMedia(audio_source_status * lAudioStatus)
{
    bool status = FALSE;          

    AUD_DEBUG(("AUD: suspend any a2dp due to esco sub use \n"));
            
    /* primary a2dp currently routed? */    
    if((theSink.rundata->routed_audio_source)&&(theSink.routed_audio == lAudioStatus->a2dpSinkPri))
    {
        AUD_DEBUG(("AUD: suspend a2dp primary audio \n"));
        SuspendA2dpStream(a2dp_primary);
        /* and disconnect the routed sink */
        AUD_DEBUG(("AUD: disconnect a2dp primary audio \n"));
        /* disconnect audio */
        audioDisconnectActiveSink();
        /* update currently routed source */
        theSink.rundata->routed_audio_source = audio_source_none;
        /* successfully disconnected audio */        
        status = TRUE;
    }
    /* secondary a2dp currently routed? */
    else if((theSink.rundata->routed_audio_source)&&(theSink.routed_audio == lAudioStatus->a2dpSinkSec))
    {
        AUD_DEBUG(("AUD: suspend a2dp secondary audio \n"));
        SuspendA2dpStream(a2dp_secondary);
        /* and disconnect the routed sink */
        AUD_DEBUG(("AUD: disconnect a2dp secondary audio \n"));
        /* disconnect audio */
        audioDisconnectActiveSink();
        /* update currently routed source */
        theSink.rundata->routed_audio_source = audio_source_none;
        /* successfully disconnected audio */        
        status = TRUE;
    }
    /* are there any a2dp media streams not currently routed that need to be suspended? */
    else
    {
        if(lAudioStatus->a2dpStatePri == a2dp_stream_streaming)
        {
            AUD_DEBUG(("AUD: suspend pri a2dp\n"));
            /* suspend or disconnect the a2dp media stream */
            SuspendA2dpStream(a2dp_primary);       
        }
        if(lAudioStatus->a2dpStateSec == a2dp_stream_streaming)
        {
            AUD_DEBUG(("AUD: suspend sec a2dp\n"));
            /* suspend or disconnect the a2dp media stream */
            SuspendA2dpStream(a2dp_secondary);       
        }
    }                
    /* provide feedback on whether audio got disconnected or not */
    return status;
}

#endif
#endif

#ifdef ENABLE_SOUNDBAR
#ifdef ENABLE_AVRCP
/****************************************************************************
NAME    
    SetSoundbarAVRCPActiveSource
    
DESCRIPTION
    called when manually selecting AG1 or AG2 input, this function determines
    if it is possible to ascertain which AVRCP connections are tied to which
    AG and sets the active AVRCP instance if it is able to do so based on the 
    selected audio source
    
RETURNS
    none
*/
void SetSoundbarAVRCPActiveSource(audio_sources source)
{
    a2dp_link_priority index = a2dp_invalid;
    
    /* only process if AVRCP enabled */
    if(theSink.features.avrcp_enabled)
    {
        /* only check for AG1 or AG2 sources */
        switch(source)
        {
            /* attempt to match an AVRCP istance for AG1 */
            case audio_source_AG1:
                /* which avrcp instance is part of the a2dp media connection, primary? */
                if ((theSink.avrcp_link_data->connected[a2dp_primary])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary],&theSink.avrcp_link_data->bd_addr[a2dp_primary])))        
                {
                    index = a2dp_primary;
                }
                /* or secondary? */
                else if ((theSink.avrcp_link_data->connected[a2dp_secondary])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_primary],&theSink.avrcp_link_data->bd_addr[a2dp_secondary])))        
                {
                    index = a2dp_secondary;                
                }
            break;
            
            /* attempt to match an AVRCP istance for AG2 */
            case audio_source_AG2:
                /* which avrcp instance is part of the a2dp media connection, primary? */
                if ((theSink.avrcp_link_data->connected[a2dp_primary])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_secondary],&theSink.avrcp_link_data->bd_addr[a2dp_primary])))        
                {
                    index = a2dp_primary;
                }
                /* or secondary? */
                else if ((theSink.avrcp_link_data->connected[a2dp_secondary])&&(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[a2dp_secondary],&theSink.avrcp_link_data->bd_addr[a2dp_secondary])))        
                {
                    index = a2dp_secondary;                
                }            
            break;
            
            /* all other input source types */
            default:
            break;
        }

        /* if a valid AVRCP instance has been found for this source, set it as active */
        if(index != a2dp_invalid)
        {
            UpdateAvrpcMessage_t * lUpdateMessage = mallocPanic ( sizeof(UpdateAvrpcMessage_t) ) ;        
            lUpdateMessage->bd_addr = theSink.a2dp_link_data->bd_addr[index];                            
            /* any AVRCP commands should be targeted to the device which has A2DP audio routed */ 
            MessageSend( &theSink.task, EventSysSetActiveAvrcpConnection, lUpdateMessage);
        }
    }
        
    
}
#endif
#endif

