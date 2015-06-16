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
#include "sink_link_policy.h"
#include "sink_tones.h"
#include "sink_volume.h"
#include "sink_speech_recognition.h"
#include "sink_wired.h"
#include "sink_dut.h"
#include "sink_display.h"
#include "sink_audio_routing.h"
#include "sink_peer.h"

#include <connection.h>
#include <hfp.h>
#include <stdlib.h>
#include <audio.h>
#include <audio_plugin_if.h>
#include <sink.h>
#include <bdaddr.h>
#include <codec.h>

#include <csr_cvc_common_plugin.h>
#ifdef ENABLE_SOUNDBAR
#include <inquiry.h>
#include "sink_swat.h"
#endif /* ENABLE_SOUNDBAR */
    
    #define NODSPCVSD       (TaskData *)&csr_cvsd_no_dsp_plugin

#ifdef INCLUDE_DSP

#ifdef INCLUDE_DSP_EXAMPLES

    /* SDK configuration */

    #include <csr_common_example_plugin.h>

    #define CVC1MIC              (TaskData *)&csr_cvsd_cvc_1mic_headset_plugin  
    #define CVSD1MIC_EXAMPLE    (TaskData *)&csr_cvsd_8k_1mic_plugin    
    #define CVC2MIC             (TaskData *)&csr_cvsd_cvc_2mic_headset_plugin
    #define SBC1MIC_EXAMPLE     (TaskData *)&csr_sbc_1mic_plugin
    #define CVSD2MIC_EXAMPLE    (TaskData *)&csr_cvsd_8k_2mic_plugin
    #define SBC2MIC_EXAMPLE     (TaskData *)&csr_sbc_2mic_plugin

    #define MAX_NUM_AUDIO_PLUGINS_PER_CODEC (6)
    /* pass digital mic settings to example plugin */
    #define AUDIO_CONNECT_PARAMS &theSink.cvc_params

    /* the column to use is selected by user PSKEY
       the row depends upon the audio link (codec) negotiated */
    TaskData * const gCsrPlugins [] [ MAX_NUM_AUDIO_PLUGINS_PER_CODEC ] = 
        {   /*   0          1                 2           3         4                    5*/
    /*CVSD*/    {NODSPCVSD, CVSD1MIC_EXAMPLE, CVC1MIC, CVC2MIC,  CVSD2MIC_EXAMPLE ,   NULL  } ,
    /*MSBC*/    {NULL     , SBC1MIC_EXAMPLE , NULL   , NULL   ,  SBC2MIC_EXAMPLE  ,   NULL  } ,
        };  
   
    
#else
    
            
    /* ROM/Production configuration */
    
    /* Headset plugins */
    #define CVCHS1MIC       (TaskData *)&csr_cvsd_cvc_1mic_headset_plugin       
    #define CVCHS1MICBEX    (TaskData *)&csr_cvsd_cvc_1mic_headset_bex_plugin
    #define CVCHS1MICWBS    (TaskData *)&csr_wbs_cvc_1mic_headset_plugin    
    #define CVCHS2MIC       (TaskData *)&csr_cvsd_cvc_2mic_headset_plugin
    #define CVCHS2MICBEX    (TaskData *)&csr_cvsd_cvc_2mic_headset_bex_plugin
    #define CVCHS2MICWBS    (TaskData *)&csr_wbs_cvc_2mic_headset_plugin
    /* Handsfree plugins */
    #define CVCHF1MIC       (TaskData *)&csr_cvsd_cvc_1mic_handsfree_plugin     
    #define CVCHF1MICBEX    (TaskData *)&csr_cvsd_cvc_1mic_handsfree_bex_plugin
    #define CVCHF1MICWBS    (TaskData *)&csr_wbs_cvc_1mic_handsfree_plugin
    #define CVCHF2MIC       (TaskData *)&csr_cvsd_cvc_2mic_handsfree_plugin     
    #define CVCHF2MICBEX    (TaskData *)&csr_cvsd_cvc_2mic_handsfree_bex_plugin
    #define CVCHF2MICWBS    (TaskData *)&csr_wbs_cvc_2mic_handsfree_plugin
    
    #define MAX_NUM_AUDIO_PLUGINS_PER_CODEC (9)
    /* Pass digital mic settings and USB settings */
    #define AUDIO_CONNECT_PARAMS &theSink.cvc_params

    /* the column to use is selected by user PSKEY
       the row depends upon the audio link (codec) negotiated */
    TaskData * const gCsrPlugins [] [ MAX_NUM_AUDIO_PLUGINS_PER_CODEC ] = 
        {   /*   0             1                 2                3                    4              5            6                7                8      */
    /*CVSD*/    {NODSPCVSD,  CVCHS1MIC      , CVCHS1MICBEX    ,  CVCHS2MIC     ,   CVCHS2MICBEX,  CVCHF1MIC,    CVCHF1MICBEX,   CVCHF2MIC,      CVCHF2MICBEX} ,
    /*MSBC*/    {NULL     ,  CVCHS1MICWBS   , CVCHS1MICWBS    ,  CVCHS2MICWBS  ,   CVCHS2MICWBS,  CVCHF1MICWBS, CVCHF1MICWBS,   CVCHF2MICWBS,   CVCHF2MICWBS } ,
        };

#endif /*INCLUDE_DSP_EXAMPLES*/
    
#else

    #define MAX_NUM_AUDIO_PLUGINS_PER_CODEC (1)
    /* Pass digital mic settings and USB settings */
    #define AUDIO_CONNECT_PARAMS &theSink.cvc_params
    
    /* the column to use is selected by user PSKEY
       the row depends upon the audio link (codec) negotiated */
    TaskData * const gCsrPlugins [] [ MAX_NUM_AUDIO_PLUGINS_PER_CODEC ] = 
    {   /*  0   */
    /*CVSD*/    {NODSPCVSD},
    /*SBC*/     {NULL},
    };  

#endif  

#define NUM_CSR_CODECS (sizeof(gCsrPlugins)/(sizeof(TaskData*)*MAX_NUM_AUDIO_PLUGINS_PER_CODEC))
    
/* Audio params used for second SCO */
const hfp_audio_params multipoint_params = {8000, 7, sync_air_coding_cvsd, sync_retx_power_usage};    

#ifdef DEBUG_AUDIO

#ifdef DEBUG_PRINT_ENABLED
    static const char * const gScoPacketStrings [ 10 ]= {
                        "hv1",
                        "hv2",
                        "hv3",
                        "ev3",
                        "ev4",
                        "ev5",
                        "2ev3",
                        "3ev3",
                        "2ev5",
                        "3ev5"
                        };    
#endif

#define AUD_DEBUG(x) DEBUG(x)
#else
#define AUD_DEBUG(x) 
#endif      

/****************************************************************************
NAME    
    getScoPriorityFromHfpPriority
    
DESCRIPTION
    obtain the current sco priority level of the AG priority passed in

RETURNS
    current sco priority level, if any, may not have a sco
*/   
audio_priority getScoPriorityFromHfpPriority(hfp_link_priority priority)
{
    AUD_DEBUG(("AUD: GetScoPriority - %d=%d\n",priority,theSink.profile_data[PROFILE_INDEX(OTHER_PROFILE(priority))].audio.sco_priority)) ;
    return theSink.profile_data[PROFILE_INDEX(OTHER_PROFILE(priority))].audio.sco_priority;
}

/****************************************************************************
NAME    
    setScoPriorityFromHfpPriority
    
DESCRIPTION
    sets the current sco priority level of the AG priority passed in

RETURNS
    nothing
*/   
void setScoPriorityFromHfpPriority(hfp_link_priority priority, audio_priority level)
{
    AUD_DEBUG(("AUD: SetScoPriority - %d=%d\n",priority,level)) ;
    if(priority != hfp_invalid_link)    
        theSink.profile_data[PROFILE_INDEX(OTHER_PROFILE(priority))].audio.sco_priority = level;
}


/****************************************************************************
NAME    
    audioGetLinkPriority
    
DESCRIPTION
    Common method of getting the link we want to manipulate audio settings on

RETURNS
    
*/
hfp_link_priority audioGetLinkPriority ( bool audio )
{
    hfp_link_priority priority;
    
    /* See if we can get a link from the device audio sink... */
    priority = HfpLinkPriorityFromAudioSink(theSink.routed_audio);

    /* If that fails see if we have an active call... */
    if(!priority)
        priority = HfpLinkPriorityWithActiveCall(audio);
    
    /* If we got something return it, otherwise return primary link */
    return (priority ? priority : hfp_primary_link);
}

/****************************************************************************
NAME    
    audioSwapMediaChannel
    
DESCRIPTION
    attempt to swap between media channels if two channels exist and one of them
    is currentyl being routed to the speaker.
RETURNS
    successful or not status
*/
bool audioSwapMediaChannel(void)
{
    Sink a2dpSinkPri, a2dpSinkSec; 
    a2dp_stream_state a2dpStatePri, a2dpStateSec;

    /* get the status of the a2dp links */
    getA2dpStreamData(a2dp_primary,   &a2dpSinkPri, &a2dpStatePri);
    getA2dpStreamData(a2dp_secondary, &a2dpSinkSec, &a2dpStateSec);
    
    /* check whether a2dp pri is currently being routed and a2dp sec is available */
    if((theSink.routed_audio == a2dpSinkPri)&&(a2dpSinkSec)&&(a2dpStateSec == a2dp_stream_streaming))
    {
        /* swap to a2dp secondary */
        AudioDisconnect();   
        A2dpRouteAudio(a2dp_secondary, a2dpSinkSec);
        return TRUE;
    }
    /* check whether a2dp sec is currently being routed and swap to a2dp pri */
    else if((theSink.routed_audio == a2dpSinkSec)&&(a2dpSinkPri)&&(a2dpStatePri == a2dp_stream_streaming))
    {
        AudioDisconnect();   
        A2dpRouteAudio(a2dp_primary, a2dpSinkPri);       
        return TRUE;    
    }
    /* not possible to swap media channels */
    return FALSE;
}

/****************************************************************************
NAME    
    audioGetSettings
    
DESCRIPTION
    Get the settings to use for a given incoming/outgoing SCO connection on
    a given AG.

RETURNS
    pointer to hfp_audio_params to use, packets is set to packet types to use.
*/
static hfp_audio_params* audioGetSettings(hfp_link_priority priority, sync_pkt_type* packets)
{
    Sink sink;
    
    /* Get the priority of the other link */
    hfp_link_priority other = (priority == hfp_primary_link) ? hfp_secondary_link : hfp_primary_link;
    
    /* If this is the second sco request limit its choice of packet type to EV3 S1 or HV3 settings only
       this is to prevent to the reserved slot violation problems seen on some phones when trying to use
       2 x 2EV3 links */
    if( (theSink.MultipointEnable) && (theSink.features.ForceEV3S1ForSco2) && (HfpLinkGetAudioSink(other, &sink)) && (sink != NULL) )
    {
        /* request EV3 S1 packet type instead */
        *packets = (sync_hv3 | sync_ev3 | sync_all_edr_esco );
        /* set up for safe EV3 S1 parameters or hv3 should esco not be available */    
        return (hfp_audio_params*)&multipoint_params;
    }
    
    /* Use configured packet types */
    *packets = theSink.HFP_supp_features.packet_types; 
    
    /* If additional params specified use them */
    if(theSink.HFP_supp_features.additional_audio_params)
        return &theSink.HFP_supp_features.audio_params;
    
    /* Use HFP library defaults */
    return NULL;
}
 

/****************************************************************************
NAME    
    audioHandleSyncConnectInd
    
DESCRIPTION
    Handle HFP_AUDIO_CONNECT_IND.  This indicates that an incoming sychronous 
    connection is being requested

RETURNS
    
*/
void audioHandleSyncConnectInd ( const HFP_AUDIO_CONNECT_IND_T *pInd )
{
    sync_pkt_type     packet_types;
    hfp_audio_params* audio_params;
    bool              disable_wbs_override = FALSE;
    
    AUD_DEBUG(("AUD: Synchronous Connect Ind [%d] from [%x]:\n" , pInd->codec, PROFILE_INDEX(pInd->priority))) ;
    
    audio_params = audioGetSettings(pInd->priority, &packet_types);
    
    AUD_DEBUG(("AUD : [%lx][%x][%x][%x]\n" , audio_params->bandwidth ,audio_params->max_latency   ,
                                            audio_params->voice_settings ,audio_params->retx_effort)) ;
    
    /* WBS test case - use bad WBS params */
    if(theSink.FailAudioNegotiation)
    {
        packet_types = sync_all_sco;
        disable_wbs_override = TRUE;
    }
    
    HfpAudioConnectResponse(pInd->priority, TRUE, packet_types, audio_params, disable_wbs_override);
}


/****************************************************************************
NAME    
    audioHandleSyncConnectCfm
    
DESCRIPTION
    Handle HFP_AUDIO_CONNECT_CFM.  This indicates that an incoming sychronous 
    connection has been established

RETURNS
    
*/
void audioHandleSyncConnectCfm ( const HFP_AUDIO_CONNECT_CFM_T * pCfm )
{       
    uint8 index = PROFILE_INDEX(pCfm->priority);
    hfp_call_state CallState;
    
    /* Get the priority of the other link */
    hfp_link_priority other = (pCfm->priority == hfp_primary_link) ? hfp_secondary_link : hfp_primary_link;
    
    
    AUD_DEBUG(("Synchronous Connect Cfm from [%x]:\n", (uint16)pCfm->priority)) ;
 
    /* if successful */
    if ( pCfm->status == hfp_success)
    {      
        Sink sink;
        
        /* obtain sink for this audio connection */
        if(HfpLinkGetSlcSink(pCfm->priority, &sink))
        {
            /* Send our link policy settings for active SCO role */
            linkPolicyUseHfpSettings(pCfm->priority, sink);
        }

        /* store in individual hfp struct as it may be necessary to disconnect and reconnect
           audio on a per hfp basis for multipoint multiparty calling */
        theSink.profile_data[index].audio.tx_bandwidth= pCfm->tx_bandwidth;
        theSink.profile_data[index].audio.link_type= pCfm->link_type;           
        theSink.profile_data[index].audio.codec_selected = pCfm->codec;           
                
        /* Send an event to indicate that a SCO has been opened */           
        /* this indicates that an audio connection has been successfully created to the AG*/
        MessageSend ( &theSink.task , EventSysSCOLinkOpen , 0 ) ;

        /* update the audio priority state 
           is this sco a streaming audio sco?, check call state for this ag */
        if(HfpLinkGetCallState(pCfm->priority, &CallState))
        {          
            /* determine sco priority based on call status */
            switch(CallState)
            {
                /* no call so this is a steaming audio connection */
                case hfp_call_state_idle:
                    setScoPriorityFromHfpPriority(pCfm->priority, sco_streaming_audio);
                break;
                
                /* incoming call so this is an inband ring sco */
                case hfp_call_state_incoming:
                case hfp_call_state_incoming_held:
                case hfp_call_state_twc_incoming:
                    setScoPriorityFromHfpPriority(pCfm->priority, sco_inband_ring);                    
                break;
   
                /* active call states so this sco has highest priority */
                case hfp_call_state_active:
                case hfp_call_state_twc_outgoing:
                    /* this audio connection may have been the result of the an audio transfer
                       from the AG and there is already an active call on the other AG, check for this
                       and make this new audio connection held leaving the other routed audio connection 
                       intact */
                    if(getScoPriorityFromHfpPriority(other)==sco_active_call)                    
                        setScoPriorityFromHfpPriority(pCfm->priority, sco_held_call);                    
                    else
                        setScoPriorityFromHfpPriority(pCfm->priority, sco_active_call);                    
                break;
                
                /* an outgoing call sco has highest priority, if there is a call on other AG
                   it needs to be put on hold whilst this outgoing call is made */
                case hfp_call_state_outgoing:
                    /* does other AG have active call on it?, if so hold the audio */
                    if(getScoPriorityFromHfpPriority(other)==sco_active_call)
                        setScoPriorityFromHfpPriority(other, sco_held_call);
                    /* make the outgoing call audio the one that gets routed */
                    setScoPriorityFromHfpPriority(pCfm->priority, sco_active_call);
                break;

                /* this call is held so the sco is put to on hold priority which is lower than
                   active call but higher than streaming */
                case hfp_call_state_held_active:
                case hfp_call_state_held_remaining:
                    if(theSink.routed_audio)                    
                        setScoPriorityFromHfpPriority(pCfm->priority, sco_held_call);                    
                break;
   
                /* non covered states treat as highest priority sco connection */
                default:
                    setScoPriorityFromHfpPriority(pCfm->priority, sco_active_call);                    
                break;
            }
        }
        
        /* route the appropriate audio connection */
        audioHandleRouting(audio_source_none);

        /*change the active call state if necessary*/
        if ((stateManagerGetState() == deviceActiveCallNoSCO) )
        {
            stateManagerEnterActiveCallState();
        }
                       
#ifdef DEBUG_AUDIO
        switch (pCfm->link_type)
        {
            case (sync_link_unknown):
                AUD_DEBUG(("AUD: Link = ?\n")) ;
            break ;
            case (sync_link_sco) :
                AUD_DEBUG(("AUD: Link = SCO\n")) ;
            break;
            case sync_link_esco:
                AUD_DEBUG(("AUD: Link = eSCO\n")) ;
            break ;    
        }
#endif        

    }
    else
    {
        AUD_DEBUG(("Synchronous Connect Cfm: FAILED\n")) ;       
    }
    AUD_DEBUG(("AUD : Sco->\n")) ;
}


/****************************************************************************
NAME    
    audioHandleSyncDisconnectInd
    
DESCRIPTION
    Handle HFP_AUDIO_DISCONNECT_IND.  This indicates that an incoming sychronous 
    connection has been disconnected

RETURNS
    
*/
void audioHandleSyncDisconnectInd ( const HFP_AUDIO_DISCONNECT_IND_T * pInd )
{
    Sink sink;   
    
    /* Get the priority of the other link */
    hfp_link_priority other = (pInd->priority == hfp_primary_link) ? hfp_secondary_link : hfp_primary_link;
    AUD_DEBUG(("AUD: Synchronous Disconnect Ind [%x]:\n",pInd->priority)) ;

    /* ensure disconnection was succesfull */
    if(pInd->status == hfp_audio_disconnect_success)
    {
        MessageSend ( &theSink.task , EventSysSCOLinkClose , 0 ) ;      
         
        /* update sco priority */
        setScoPriorityFromHfpPriority(pInd->priority, sco_none);                    

        /* SCO has been disconnected, check for the prescence of another sco in hold state, this occurs
           when the AG has performed an audio transfer, promote the held call to active */
        if(getScoPriorityFromHfpPriority(other) == sco_held_call)
            setScoPriorityFromHfpPriority(other, sco_active_call);
        
        AUD_DEBUG(("AUD: Synchronous Disconnect Ind [%x]: sco_pri = %d\n",pInd->priority, HfpLinkPriorityFromAudioSink(theSink.routed_audio) )) ;
    
        /* deroute the audio */
        audioHandleRouting(audio_source_none);    

        /*change the active call state if necessary*/
        if ((stateManagerGetState() == deviceActiveCallSCO))
            stateManagerEnterActiveCallState();
    
        /* Send our link policy settings for normal role  now SCO is dropped */
        if(HfpLinkGetSlcSink(pInd->priority, &sink))
            linkPolicyUseHfpSettings(pInd->priority, sink);
    }
    
}


/****************************************************************************
NAME    
    audioHfpGetPlugin
    
DESCRIPTION
    Get HFP plugin based on codec and index

RETURNS
    
*/
Task audioHfpGetPlugin(hfp_wbs_codec_mask codec, uint8 plugin)
{
    TaskData * const (*gPlugins)[MAX_NUM_AUDIO_PLUGINS_PER_CODEC];
    gPlugins = NULL;

    /* select row in plugin table, cvsd is row 0, msbc is row 1 currently */
    gPlugins = &gCsrPlugins[codec - hfp_wbs_codec_mask_cvsd];

    AUD_DEBUG(("AUD: gplugins [%x] \n" , (uint16)gPlugins));

    /* Now reference the plugin based on the plugin selected (column). */
    if((gPlugins != NULL) && (plugin <= MAX_NUM_AUDIO_PLUGINS_PER_CODEC))
    {
        AUD_DEBUG(("AUD: plugin [%x] \n" , (uint16)plugin));
        return (*gPlugins)[plugin]; 
    }

    return NULL;
}


/****************************************************************************
NAME    
    audioHfpConnectAudio
    
DESCRIPTION
    attempt to reconnect an audio connection from the sink value associcated 
    with the passed hfp instance

RETURNS
    
*/
void audioHfpConnectAudio (hfp_link_priority priority, Sink sink)
{    
    uint8 index = PROFILE_INDEX(priority);
    
    /* ensure sink is valid before trying to route audio */
    TaskData *plugin = NULL;
    
    /* ensure a valid codec is negotiated, should be at least cvsd */
    if(theSink.profile_data[index].audio.codec_selected)       
    {                

        /* determine additional features applicable for this audio plugin */
                
        theSink.routed_audio = sink;    
        
        plugin = audioHfpGetPlugin(theSink.profile_data[index].audio.codec_selected, theSink.features.audio_plugin);

        AUD_DEBUG(("AUD: plugin [%d] [%d], sink [%x]\n" , theSink.features.audio_plugin 
                                                        , theSink.profile_data[index].audio.codec_selected
                                                        , (uint16)theSink.routed_audio)) ;
        /* connect audio using the audio plugin selected above */            
        AudioConnect ( plugin,
                       theSink.routed_audio  ,
                       theSink.profile_data[index].audio.link_type ,
                       theSink.codec_task ,
                       theSink.conf1->volume_config.gVolMaps[ theSink.profile_data[index].audio.gSMVolumeLevel ].VolGain ,
                       theSink.profile_data[index].audio.tx_bandwidth ,
                       theSink.conf2->audio_routing_data.PluginFeatures  ,
                       AUDIO_MODE_CONNECTED,
                       AUDIO_ROUTE_INTERNAL,
                       powerManagerGetLBIPM(),
                       AUDIO_CONNECT_PARAMS,
                       NULL ) ;       

        audioControlLowPowerCodecs (TRUE) ;

        AUD_DEBUG(("AUD: Route SCO\n"));
    
        AUD_DEBUG(("Audio Connect[%d][%x]\n", theSink.features.audio_plugin , theSink.profile_data[index].audio.gSMVolumeLevel )) ;
       
        AudioSetVolume ( theSink.conf1->volume_config.gVolMaps[ theSink.profile_data[index].audio.gSMVolumeLevel ].VolGain , TonesGetToneVolume(FALSE), theSink.codec_task ) ;
            
        /* mute control */
        VolumeSetMicrophoneGain(priority, (theSink.profile_data[index].audio.gMuted ? VOLUME_MUTE_ON : VOLUME_MUTE_OFF));            
    }
}

/****************************************************************************
NAME    
    audioIndicateCodec
    
DESCRIPTION
    Sends an event to indicate which A2DP codec is in use

RETURNS
    void
*/
void audioIndicateCodec(uint8 seid)
{
    switch(seid)
    {
        case SBC_SEID:
            MessageSend ( &theSink.task , EventSysCodecSbc , 0 ) ;
            break;
        case MP3_SEID:
            MessageSend ( &theSink.task , EventSysCodecMp3 , 0 ) ;
            break;        
        case AAC_SEID:
            MessageSend ( &theSink.task , EventSysCodecAac , 0 ) ;
            break;  
        case APTX_SEID:
            MessageSend ( &theSink.task , EventSysCodecAptx , 0 ) ;
            break;  
#ifdef INCLUDE_FASTSTREAM            
        case FASTSTREAM_SEID:
            MessageSend ( &theSink.task , EventSysCodecFaststream , 0 ) ;
            break;  
#endif
#ifdef INCLUDE_APTX_ACL_SPRINT            
        case APTX_SPRINT_SEID:
            MessageSend ( &theSink.task , EventSysCodecAptxLL , 0 ) ;
            break;              
#endif            
        default:
           AUD_DEBUG(("AUD: Unknown codec\n"));                 
    }
}


/****************************************************************************
NAME    
    A2dpRouteAudio
    
DESCRIPTION
    attempt to connect an audio connection from a2dp device via the passed in 
    deviceID

RETURNS
    
*/
void A2dpRouteAudio(uint8 Index, Sink sink)
{      
    AUD_DEBUG(("AudioA2dpRoute Index[%x] Sink[%x]\n", Index , (uint16) sink )) ;

    /* ensure sink is valid before attempting the connection */
    if(sink)
    {       
        /* Use an instance of A2DP message structure for initial volume setting */
        AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeInitAudio;

        a2dp_codec_settings * codec_settings;
            
        AUD_DEBUG(("AudioA2dpRoute Index[%d] DevId[%x]\n", Index , theSink.a2dp_link_data->device_id[Index] )) ;

        /* get the rate information for connection */
        codec_settings = A2dpCodecGetSettings(theSink.a2dp_link_data->device_id[Index], theSink.a2dp_link_data->stream_id[Index]);

            /* ensure stream is valid */
            if(codec_settings)
            {     
                AUDIO_MODE_T mode = AUDIO_MODE_CONNECTED;
                int16 a2dp_gain_dB;
                /* determine additional features applicable for this audio plugin */
                /* Volume info is sent to DSP in dB units */
                a2dp_gain_dB = VolumeConvertStepsToDB(theSink.volume_levels->a2dp_volume[Index].masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);

                /* check for MUTE volume level and mute as appropriate */
				if (theSink.volume_levels->a2dp_volume[Index].masterVolume == VOLUME_A2DP_MUTE_GAIN)
                {
                    mode = AUDIO_MODE_MUTE_SPEAKER;
                }			
                             
                /* initialise the AudioConnect extra parameters required to pass in additional codec information */
				if (codec_settings->codecData.latency_reporting) /* latency reporting retrieved from a2dp library */
				{
					/* TODO: obtain settings from PS, probably based on codec type */
					theSink.a2dp_link_data->a2dp_audio_connect_params.latency.last = 150;
					theSink.a2dp_link_data->a2dp_audio_connect_params.latency.target = 150/5;
					theSink.a2dp_link_data->a2dp_audio_connect_params.latency.change = 10/5;
					theSink.a2dp_link_data->a2dp_audio_connect_params.latency.period = 500/100;			
				}

                theSink.a2dp_link_data->a2dp_audio_connect_params.packet_size = codec_settings->codecData.packet_size; /* Packet size retrieved from a2dp library */            
                theSink.a2dp_link_data->a2dp_audio_connect_params.content_protection = codec_settings->codecData.content_protection; /* content protection retrieved from a2dp library */            
                theSink.a2dp_link_data->a2dp_audio_connect_params.clock_mismatch = theSink.a2dp_link_data->clockMismatchRate[Index]; /* clock mismatch rate for this device */      
                theSink.a2dp_link_data->a2dp_audio_connect_params.mode_params = &theSink.a2dp_link_data->a2dp_audio_mode_params; /* EQ mode and Audio enhancements */
#ifdef INCLUDE_A2DP_EXTRA_CODECS                
#ifdef INCLUDE_FASTSTREAM                
                theSink.a2dp_link_data->a2dp_audio_connect_params.voice_rate = codec_settings->codecData.voice_rate; /* voice rate retrieved from a2dp library */
                theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = codec_settings->codecData.bitpool; /* bitpool retrieved from a2dp library */
                theSink.a2dp_link_data->a2dp_audio_connect_params.format = codec_settings->codecData.format; /* format retrieved from a2dp library */
#endif                   
#ifdef INCLUDE_APTX
                theSink.a2dp_link_data->a2dp_audio_connect_params.channel_mode  = codec_settings->channel_mode; /* aptX channel mode */ 
#endif
#ifdef INCLUDE_APTX_ACL_SPRINT
                theSink.a2dp_link_data->a2dp_audio_connect_params.aptx_sprint_params  = codec_settings->codecData.aptx_sprint_params; /* aptX LL params */ 
#endif
#endif  
#ifdef ENABLE_SOUNDBAR
                theSink.a2dp_link_data->seid[Index] = codec_settings->seid;
#endif /* ENABLE_SOUNDBAR */
#ifdef ENABLE_SUBWOOFER
                /* set the sub woofer link type prior to passing to audio connect */
                theSink.a2dp_link_data->a2dp_audio_connect_params.sub_woofer_type  = AUDIO_SUB_WOOFER_NONE;  
                theSink.a2dp_link_data->a2dp_audio_connect_params.sub_sink  = NULL;  
                
                /* bits inverted in dsp plugin */                
                sinkAudioSetEnhancement(MUSIC_CONFIG_SUB_WOOFER_BYPASS,TRUE);
#else
                /* no subwoofer support, set the sub woofer bypass bit in music config message sent o dsp */
                sinkAudioSetEnhancement(MUSIC_CONFIG_SUB_WOOFER_BYPASS,FALSE);
#endif          

                AUD_DEBUG(("AudioA2dpRoute Index[%d] DevId[%x] Gain[%x] Codec[%x] ClkMismatch[%x] EQ[%x] packet_size[%u]\n", 
                           Index , 
                           theSink.a2dp_link_data->device_id[Index],
                           a2dp_gain_dB,
                           codec_settings->seid,
                           theSink.a2dp_link_data->a2dp_audio_connect_params.clock_mismatch,
                           (uint16)theSink.a2dp_link_data->a2dp_audio_connect_params.mode_params,
                           theSink.a2dp_link_data->a2dp_audio_connect_params.packet_size)) ;
                
                audioIndicateCodec( codec_settings->seid );

#ifdef ENABLE_SOUNDBAR
                /* Set the LE SCAN priority to Low since we are Streaming  It is possible 
                that we might be receiving less or no LE adverts when streaming is in progress*/
                InquirySetPriority(inquiry_low_priority);
#endif /*  ENABLE_SOUNDBAR */

                /* We need to set A2DP volume info as the audio is in mute state after connection */ 
				volumeInitAudio.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
                volumeInitAudio.codec_task = theSink.codec_task;
        		volumeInitAudio.master_gain = a2dp_gain_dB;
                volumeInitAudio.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
        		volumeInitAudio.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
        		volumeInitAudio.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;	
                volumeInitAudio.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
                volumeInitAudio.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
          		volumeInitAudio.tones_gain = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
                volumeInitAudio.mute_active = theSink.sink_mute_status;
                
                /* connect the audio via the audio plugin */    
  			    AudioConnect(getA2dpPlugin(codec_settings->seid),
                             sink , 
                             AUDIO_SINK_AV ,
                             theSink.codec_task,
                             volumeInitAudio.tones_gain, 
                             codec_settings->rate,
                             theSink.conf2->audio_routing_data.PluginFeatures ,
                             mode,
                             AUDIO_ROUTE_INTERNAL,
                             powerManagerGetLBIPM(), 
                             &theSink.a2dp_link_data->a2dp_audio_connect_params,
                             &theSink.task);
               
				AudioSetVolumeA2DP(&volumeInitAudio);

#ifdef ENABLE_SUBWOOFER
                /* set subwoofer volume level */
                updateSwatVolume(theSink.volume_levels->a2dp_volume[Index].masterVolume);

                SWAT_DEBUG(("SW : Send sample rate to Sub, rate is %ld\n",codec_settings->rate));
                
                /* send sample rate to sub */
                sendSampleRateToSub(codec_settings->rate);                        
#endif
                
                audioControlLowPowerCodecs (FALSE) ;

                /* caller responsible for freeing memory */
                freePanic(codec_settings);
                
#ifdef ENABLE_AVRCP
                if(theSink.features.avrcp_enabled)
                {    
                    UpdateAvrpcMessage_t * lUpdateMessage = mallocPanic ( sizeof(UpdateAvrpcMessage_t) ) ;        
                    lUpdateMessage->bd_addr = theSink.a2dp_link_data->bd_addr[Index];                            
                    /* any AVRCP commands should be targeted to the device which has A2DP audio routed */ 
                    MessageSend( &theSink.task, EventSysSetActiveAvrcpConnection, lUpdateMessage);
                }
#endif            
        }
            
        /* update the current sink being routed */            
        theSink.routed_audio = sink;
    }
}


/****************************************************************************
NAME    
    audioControlLowPowerCodecs
    
DESCRIPTION
    Enables / disables the low power codecs. 
    will only use low power codecs is the flag UseLowPowerCodecs is set and 
    enable == TRUE
    
    This fn is called whenever an audioConnect occurs in order to select the 
    right codec ouptut stage power .
    
RETURNS
    none
*/
void audioControlLowPowerCodecs(  bool enable  )
{
    audio_channel channel  =  AUDIO_CHANNEL_A ;
    Sink sink   = NULL ;
    
    if ( theSink.conf2->audio_routing_data.PluginFeatures.stereo )
    {
        channel = AUDIO_CHANNEL_A_AND_B;
    }

    /* obtain sink to audio hardware */
    sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, channel);

    /* ensure sink is valid */
    if(sink)
    {
        /* if low power codec use is disabled in features ps or enable is false */
        if ((!theSink.features.UseLowPowerAudioCodecs)||(!enable))
        {
            /*disable low power codecs as feature disabled or enable override is set */
            AUD_DEBUG(("AUD:LowPowerCodecDisable CODEC NORMAL, feature [%c] enable [%c]\n", theSink.features.UseLowPowerAudioCodecs? 'T':'F', enable? 'L':'N')) ;
        
#ifdef BC5_MULTIMEDIA
            /* set to normal mode */
            PanicFalse(SinkConfigure(sink, STREAM_CODEC_LOW_POWER_OUTPUT_STAGE_ENABLE, FALSE ));
#else        
            /* set codec to high quality mode */
            PanicFalse(SinkConfigure(sink, STREAM_CODEC_QUALITY_MODE, CODEC_HIGH_MODE )) ;  
#endif        
        }
        /* if the low power audio codec feature is enabled and the enable is true */
        else
        {
#ifdef BC5_MULTIMEDIA
            /* enable the low power mode */        
            PanicFalse(SinkConfigure(sink, STREAM_CODEC_LOW_POWER_OUTPUT_STAGE_ENABLE, TRUE)) ;
#else        
            /* set the codec type to low power telephony mode */
            PanicFalse(SinkConfigure(sink, STREAM_CODEC_QUALITY_MODE, CODEC_TELEPHONY_MODE )) ;
#endif
            AUD_DEBUG(("AUD:LowPowerCodecEnable CODEC LOW POWER, feature [%c] enable [%c]\n", theSink.features.UseLowPowerAudioCodecs? 'T':'F', enable? 'L':'N')) ;
        }

        /* Close the Source/Sink */
        SinkClose(sink);
    }
}


/****************************************************************************
NAME    
    audioHandleMicSwitch
    
DESCRIPTION
    Handle AT+MICTEST AT command from TestAg. 
    This command swaps between the two microphones to test 2nd mic in production.

RETURNS
    returns true if mic switch command issued to plugin
*/
bool audioHandleMicSwitch( void )
{
    AUD_DEBUG(("audioHandleMicSwitch\n"));
    
    /*only attempt to swap between the microphones if we have a sco connection present*/
    if (theSink.routed_audio)
    {
        AudioMicSwitch() ; 
        return TRUE;
    }
    else
    {
        AUD_DEBUG(("audioHandleMicSwitch - no sco present\n"));
        return FALSE;
    }
}


/****************************************************************************
NAME    
    sinkTransferToggle
    
DESCRIPTION
    If the audio is at the device end transfer it back to the AG and
    vice versa.

RETURNS
    void
*/
void sinkTransferToggle( uint16 eventId )
{
    /* Get the link to toggle audio on */
    hfp_link_priority priority = audioGetLinkPriority(FALSE);
    sync_pkt_type packet_type;
    hfp_audio_params* audio_params;
    
    audio_params = audioGetSettings(priority, &packet_type);    
       
    AUD_DEBUG(("AUD: Audio Transfer\n")) ;
    
    /* Perform audio transfer */
    HfpAudioTransferRequest(priority, hfp_audio_transfer, packet_type, audio_params );
}


/****************************************************************************
NAME    
    sinkCheckForAudioTransfer
    
DESCRIPTION
    checks on connection for an audio connction and performs a transfer if not present

RETURNS
    void
*/
void sinkCheckForAudioTransfer ( void )
{
    sinkState lState = stateManagerGetState() ;
    
    AUD_DEBUG(("AUD: Tx[%d] [%x]\n", lState , (int)theSink.routed_audio)) ;
    
    switch (lState)
    {
        case deviceIncomingCallEstablish :
        case deviceThreeWayCallWaiting :
        case deviceThreeWayCallOnHold :
        case deviceThreeWayMulticall :
        case deviceIncomingCallOnHold : 
        case deviceActiveCallNoSCO :
        {              
            Sink sink;            
            hfp_call_state state;  
            hfp_link_priority priority = hfp_invalid_link;
              
            /* check call state and sink of AG1 */
            if((HfpLinkGetCallState(hfp_primary_link, &state))&&(state == hfp_call_state_active)&&
               (HfpLinkGetAudioSink(hfp_primary_link, &sink))&&(!sink))
            {
                priority = hfp_primary_link;
            }
            /* or check call state and sink of AG2 */
            else if((HfpLinkGetCallState(hfp_secondary_link, &state))&&(state == hfp_call_state_active)&&
                    (HfpLinkGetAudioSink(hfp_secondary_link, &sink))&&(!sink))    
            {
                priority = hfp_secondary_link;
            }
            /* if call found with no audio */
            if (priority)
            {
                hfp_audio_params * audio_params = NULL;
                HfpAudioTransferRequest(priority, 
                                        hfp_audio_to_hfp , 
                                        theSink.HFP_supp_features.packet_types,
                                        audio_params );
            }    
        }
        break ;
        default:
        break;
    }
}
        
void CreateAudioConnection(void)
{
    hfp_audio_params * audio_params = NULL;
    HfpAudioTransferRequest(hfp_primary_link, 
                               hfp_audio_to_hfp , 
                               theSink.HFP_supp_features.packet_types,
                               audio_params );
}

/****************************************************************************
NAME    
    sinkAudioSetEnhancement
DESCRIPTION
    updates the current audio enhancement settings and updates the dsp if it
    is currently running and streaming a2dp music.

RETURNS
    void
*/
void sinkAudioSetEnhancement(uint16 enhancement, bool enable)
{
    a2dp_stream_state a2dpStatePri = a2dp_stream_idle;
    a2dp_stream_state a2dpStateSec = a2dp_stream_idle;   
    Sink a2dpSinkPri = 0;
    Sink a2dpSinkSec = 0;
    uint16 lEnhancements;
    
    /* user has changed an enhancement default, set flag to indicate user values should be used and not 
       dsp default values */
    if(enhancement != MUSIC_CONFIG_SUB_WOOFER_BYPASS)    
    {
        /* don't update for sub woofer only changes */        
        theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements |= MUSIC_CONFIG_DATA_VALID;
    }
    
    /* take local copy as enhancement bits are inverted in the dsp */
    lEnhancements = theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements;
                
    /* if an enhancement is being enabled add to enables bitmask */
    if(enable)        
        lEnhancements |= enhancement;
    /* otherwise remove it */    
    else
        lEnhancements &= ~enhancement;
   
    /* determine if value has changed and needs to be committed to PS */
    if(theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements != lEnhancements)
    {
        theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements = lEnhancements;
        configManagerWriteSessionData () ;
    }

    /* now decide whether the music manager is currently running and an update of 
       configuration is required */
         
    /* if a2dp connected obtain the current streaming state for primary a2dp connection */
    getA2dpStreamData(a2dp_primary,   &a2dpSinkPri, &a2dpStatePri);

    /* if a2dp connected obtain the current streaming state for secondary a2dp connection */
    getA2dpStreamData(a2dp_secondary, &a2dpSinkSec, &a2dpStateSec);
 
    /* Determine which a2dp source this is for */
    if(((a2dpStatePri == a2dp_stream_streaming) && (a2dpSinkPri == theSink.routed_audio))||
       ((a2dpStateSec == a2dp_stream_streaming) && (a2dpSinkSec == theSink.routed_audio))
#ifdef ENABLE_USB
       ||((usbAudioSinkMatch(theSink.routed_audio) && (theSink.usb.config.plugin_type == usb_plugin_stereo)))
#endif
#ifdef ENABLE_WIRED        
       ||(analogAudioSinkMatch(theSink.routed_audio))||(spdifAudioSinkMatch(theSink.routed_audio))
#endif        
      )
    {                
        AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
    }
}
