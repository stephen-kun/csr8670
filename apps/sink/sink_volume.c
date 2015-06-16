/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_volume.c
    
DESCRIPTION
    module responsible for Vol control 
    
*/
#include "sink_statemanager.h"
#include "sink_volume.h"
#include "sink_tones.h"
#include "sink_pio.h"
#include "sink_slc.h"
#include "sink_audio.h"
#include "sink_wired.h"
#include "sink_display.h"

#ifdef ENABLE_AVRCP
#include "sink_avrcp.h"    
#endif 

#ifdef ENABLE_PEER
#include "sink_peer.h"    
#endif 


#ifdef ENABLE_FM
#include "sink_fm.h"
#endif

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#include <audio.h>
#include <stddef.h>
#include <string.h>

#ifdef DEBUG_VOLUME
#define VOL_DEBUG(x) DEBUG(x)
#else
#define VOL_DEBUG(x) 
#endif


/****************************************************************************
NAME
 volumeInit

DESCRIPTION
 malloc memory for storing of current volume levels for a2dp, usb, wired and fm
 interfaces

RETURNS
 none

*/
void volumeInit(void)
{
    /* malloc slot for current volume levels */
    theSink.volume_levels = PanicUnlessMalloc(sizeof(volume_levels_t));
    /* initialise to mute for all interfaces */
    memset(theSink.volume_levels, 0 , sizeof(volume_levels_t));
}



/* Helper to decide if sync request from AG affects our gain settings */
static bool volumeSyncAffectsGain(hfp_link_priority priority)
{
    Sink sink;
    /* Match active sink against HFP sink */
    if(HfpLinkGetAudioSink(priority, &sink))
        if( theSink.routed_audio && theSink.routed_audio == sink )
            return TRUE;

    return FALSE;
}


/****************************************************************************
DESCRIPTION
    sets the current A2dp volume
    
*/
void VolumeSetA2dp(uint16 index, uint16 oldVolume, bool pPlayTone)
{               
    AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
    uint16 dbValueMaster;
                         
    /* convert the tone into a dB (* 60) scaled value to send to the dsp */
    theSink.volume_levels->a2dp_volume[index].tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
 
    /* check for mute state */
    if(theSink.volume_levels->a2dp_volume[index].masterVolume == VOLUME_A2DP_MUTE_GAIN)
    {
        /* muted state, set master gain to -120dB */
        dbValueMaster = VOLUME_MUTE_DB;
    }
    else
    {        
        /* convert to dB */
        dbValueMaster =  VolumeConvertStepsToDB(theSink.volume_levels->a2dp_volume[index].masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
    }       
         
    VOL_DEBUG(("VOL: A2dp set vol [%d][%x]\n", theSink.volume_levels->a2dp_volume[index].masterVolume, dbValueMaster));

    volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
    volumeDsp.codec_task = theSink.codec_task;
    volumeDsp.master_gain = dbValueMaster;
    volumeDsp.tones_gain =  theSink.volume_levels->a2dp_volume[index].tonesVolume;
    volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
    volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
    volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
    volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
    volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
    volumeDsp.mute_active = theSink.sink_mute_status;

    /* set volume level via a2dp library plugin */
    AudioSetVolumeA2DP ( &volumeDsp);
    /* update the display to show A2DP volume */
    displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * theSink.volume_levels->a2dp_volume[index].masterVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
#ifdef ENABLE_SUBWOOFER
    /* update subwoofer volume */
    updateSwatVolume(theSink.volume_levels->a2dp_volume[index].masterVolume);
#endif    

    /* check whether A2DP volume has gone from 0 (mute) to a valid level, if so
       send set mode message to plugin to unmute output */
    if((oldVolume == VOLUME_A2DP_MIN_LEVEL)&&(theSink.volume_levels->a2dp_volume[index].masterVolume != VOLUME_A2DP_MIN_LEVEL))
    {
        /* set the operating mode to FULL_PROCESSING */
        AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
        /* send set mode message to DSP to unmute output ports of DSP */
        AudioSetMode(AUDIO_MODE_UNMUTE_SPEAKER, &theSink.a2dp_link_data->a2dp_audio_mode_params);  
    }

    
}

#if defined ENABLE_PEER && defined PEER_TWS
/****************************************************************************
NAME 
 VolumeCheckDeviceTrim

DESCRIPTION
 check for an active A2DP, Wired or USB streaming currently routing audio to the device and adjust the trim volume up or down
 as appropriate

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
bool VolumeCheckDeviceTrim (volume_direction dir, tws_device_type tws_device)
{    
    if(a2dpCheckDeviceTrimVol(dir, tws_device) || usbCheckDeviceTrimVol(dir, tws_device) ||wiredAudioCheckDeviceTrimVol(dir, tws_device))
    {
        return TRUE;
    } 
    
    return FALSE;
}


/****************************************************************************
NAME 
 VolumeUpdateDeviceTrim

DESCRIPTION
 Updates the trim volume changes locally in ther device.

RETURNS
void
    
*/
void VolumeUpdateDeviceTrim(volume_direction dir, tws_device_type tws_device)
{             
    int16 *device_trim;

    VOL_DEBUG(("VOL: VolumeCheckDeviceTrim [%i][%i][%i][%i][%i]\n", theSink.conf1->volume_config.volume_control_config.device_trim_master, 
                                                            theSink.conf1->volume_config.volume_control_config.device_trim_slave, 
                                                            theSink.conf1->volume_config.volume_control_config.device_trim_change, 
                                                            theSink.conf1->volume_config.volume_control_config.device_trim_min,
                                                            theSink.conf1->volume_config.volume_control_config.device_trim_max));

    if (tws_device == tws_master)
    {
        device_trim = &theSink.conf1->volume_config.volume_control_config.device_trim_master;
    }
    else
    {
        device_trim = &theSink.conf1->volume_config.volume_control_config.device_trim_slave;
    }

    if (dir == increase_volume)
    {   /* Increase and clamp to upper limit */
        *device_trim += theSink.conf1->volume_config.volume_control_config.device_trim_change;
        
        if (*device_trim >= theSink.conf1->volume_config.volume_control_config.device_trim_max)
        {
            *device_trim = theSink.conf1->volume_config.volume_control_config.device_trim_max;
            MessageSend ( &theSink.task , EventSysTrimVolumeMax , 0 );
        }
        
        VOL_DEBUG(("VOL: inc device trim [%i]\n", *device_trim)); 
    }
    else
    {   /* Decrease and clamp to lower limit */
        *device_trim -= theSink.conf1->volume_config.volume_control_config.device_trim_change;
        
        if (*device_trim <= theSink.conf1->volume_config.volume_control_config.device_trim_min)
        {
            *device_trim = theSink.conf1->volume_config.volume_control_config.device_trim_min;
            MessageSend ( &theSink.task , EventSysTrimVolumeMin , 0 );                                      
        }
        
        VOL_DEBUG(("VOL: dec device trim [%i]\n", *device_trim)); 
    }    
    
}

#endif

/****************************************************************************
NAME 
 VolumeCheckA2dp

DESCRIPTION
 check whether any a2dp connections are present and if these are currently active
 and routing audio to the device, if that is the case adjust the volume up or down
 as appropriate

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
bool VolumeCheckA2dp(volume_direction dir)
{
    uint8 index;
 
    /* check both possible instances of a2dp connection */
    for(index = a2dp_primary; index < (a2dp_secondary+1); index++)
    {
        /* is a2dp connected? */
        if(theSink.a2dp_link_data->connected[index])
        {
            /* check whether the a2dp connection is present and streaming data and that the audio is routed */
            if(theSink.routed_audio && (theSink.routed_audio == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index])))
            {
#if defined ENABLE_PEER && defined ENABLE_AVRCP
                if ((theSink.a2dp_link_data->peer_device[index] == remote_device_peer) && (theSink.a2dp_link_data->peer_features[index] & remote_features_tws_a2dp_source))
                {   /* Audio routed from a Peer device which supports TWS as a Source.  This takes priority over ShareMe and thus means we are in a TWS session */
                    switch (dir)
                    {
                    case increase_volume:
                        sinkAvrcpVolumeUp();
                        break;
                    
                    case decrease_volume:
                        sinkAvrcpVolumeDown();
                        break;
                    
                    case same_volume:
                    default:    
                        break;
                    }
                }
                else
#endif
                {
                    /* get current volume for this profile */
                    int16 lOldVol = theSink.volume_levels->a2dp_volume[index].masterVolume;                
                      
                    switch (dir)
                    {
                        case increase_volume:
                        {
                            /* Volume level should be lifted upwards by predefined coefficient 
                               which is used to map allowed a2dp volume level range into avrcp volume index values */ 
                            theSink.volume_levels->a2dp_volume[index].masterVolume++; 
                            /* limit check */
                            if(theSink.volume_levels->a2dp_volume[index].masterVolume >= (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1))
                            {
                                /* Master volume is the A2DP volume level to check against MAX level for event handling*/ 
                                theSink.volume_levels->a2dp_volume[index].masterVolume = (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1);
                                MessageSend ( &theSink.task , EventSysVolumeMax , 0 );
                            }
                        }
                        break;
                        case decrease_volume:
                        {
                            /* decrease volume by one level down to minimum */
                            theSink.volume_levels->a2dp_volume[index].masterVolume--;
                            /* limit to minimum and send notification event when at min level */
                            if(theSink.volume_levels->a2dp_volume[index].masterVolume <= VOLUME_A2DP_MIN_LEVEL)
                            {                        
                                theSink.volume_levels->a2dp_volume[index].masterVolume = VOLUME_A2DP_MIN_LEVEL;
                                MessageSend ( &theSink.task , EventSysVolumeMin , 0 );                                      
                            }
                        }     
                        break;
                        
                        case same_volume:
                        default:    
                            ; /* no volume change */
                        break;
                    }
                                        
#ifdef ENABLE_AVRCP    
                    if(theSink.features.avrcp_enabled)  
                    {
                        int16 vol_step_change = 0;

                        if (lOldVol > (theSink.volume_levels->a2dp_volume[index].masterVolume - 1))
                            vol_step_change = (((lOldVol - theSink.volume_levels->a2dp_volume[index].masterVolume) * (AVRCP_MAX_ABS_VOL))/theSink.conf1->volume_config.volume_control_config.no_of_steps);
                        else
                            vol_step_change = (((theSink.volume_levels->a2dp_volume[index].masterVolume - lOldVol) * (AVRCP_MAX_ABS_VOL))/theSink.conf1->volume_config.volume_control_config.no_of_steps);
                    
                        VOL_DEBUG(("VOL: avrcp abs vol old[%d] new[%d] step_change[%d]\n",lOldVol, theSink.volume_levels->a2dp_volume[index].masterVolume,vol_step_change)); 

                        /* update absolute volume control change */
                        sinkAvrcpVolumeStepChange(dir, vol_step_change);                
                    }
#endif                
                    VolumeSetA2dp(index, lOldVol, TRUE);
                }
                
                /* if feature to unmute on volume change is set then issue unmute */
                if ((theSink.features.VolumeChangeCausesUnMute)&&(theSink.sink_mute_status))
        		{
                    MessageSend(&theSink.task, EventUsrMuteOff, 0);
                }

                /* volume adjusted for a A2DP media stream */
                return TRUE;
            }
        }
    }
    /* no routed a2dp media streams found */
    return FALSE;
}

/****************************************************************************
NAME 
 VolumeCheckA2dpMute

DESCRIPTION
 check whether any a2dp connections are at minimum volume and mutes them properly if they are

RETURNS
 bool   Returns true if stream muted
    
*/
bool VolumeCheckA2dpMute()
{
    uint8 index;
 
    /* check both possible instances of a2dp connection */
    for(index = a2dp_primary; index < (a2dp_secondary+1); index++)
    {
        /* is a2dp connected? */
        if(theSink.a2dp_link_data->connected[index])
        {
            /* check whether the a2dp connection is present and streaming data and that the audio is routed */
            if(theSink.routed_audio && 
               (theSink.routed_audio == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index])))
            {
                /* get current volume for this profile */
				uint16 currentVol = theSink.volume_levels->a2dp_volume[index].masterVolume;
                                       
                if( currentVol == VOLUME_A2DP_MUTE_GAIN)
                {
                    /* mute adjusted for a A2DP media stream */
                    VOL_DEBUG(("VOL: A2dp re-mute\n"));
                    return TRUE;
                }
            }
        }
    }
    /* no routed a2dp media streams found */
    return FALSE;
}

/****************************************************************************
DESCRIPTION
 sets the internal speaker gain to the level corresponding to the phone volume level
 
*/
void VolumeSetHeadsetVolume( uint16 pNewVolume , bool pPlayTone, hfp_link_priority priority) 
{      
    bool lPlayTone = FALSE ;
    bool lVolumeChangeCausesUnMute = theSink.features.VolumeChangeCausesUnMute ;
    bool lAdjustVolumeWhilstMuted = theSink.features.AdjustVolumeWhilstMuted ;
    bool set_gain = volumeSyncAffectsGain(priority);

    VOL_DEBUG(("SetVol [%x] [%d][%d][%d]\n " ,pNewVolume, theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted , lVolumeChangeCausesUnMute , lAdjustVolumeWhilstMuted)) ;
    
	/* only adjust the volume if this AG is not muted or the device has the feature to allow volume change
       whilst muted or the feature to unmute on volume changes */
    if ( (!theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted ) || ( lVolumeChangeCausesUnMute ) || 
         (lAdjustVolumeWhilstMuted))
    {
        /* set the local volume only, check whether unMute on volume change feature is enabled*/
        if ((theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted)&&(lVolumeChangeCausesUnMute))
		{
            VolumeSetMicrophoneGainCheckMute(priority, VOLUME_MUTE_OFF);
        }
        
        /* the tone needs to be played so set flag */
        lPlayTone = TRUE ;     
        
        /* set new volume */
        theSink.profile_data[PROFILE_INDEX(priority)].audio.gSMVolumeLevel = pNewVolume ; 
        
        /* update the display */
        displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * pNewVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
        
        /* determine whether this volume change affects the audio currently being routed to the speaker #
           and update volume level via audio plugin if this is the case */
        if(set_gain)
            AudioSetVolume ( theSink.conf1->volume_config.gVolMaps[ pNewVolume ].VolGain , TonesGetToneVolume(FALSE), theSink.codec_task ) ;
    }
    
    /* ensure there is a valid tone (non zero) to be played */
    if( pPlayTone && lPlayTone && theSink.conf1->volume_config.gVolMaps[pNewVolume].Tone )
    {   /*only attempt to play the tone if it has not yet been played*/
        VOL_DEBUG(("VOL: VolTone[%x]\n" , (int)theSink.conf1->volume_config.gVolMaps[pNewVolume].Tone)) ;
        TonesPlayTone(theSink.conf1->volume_config.gVolMaps[pNewVolume].Tone ,theSink.features.QueueVolumeTones, FALSE);
    }    
}


/****************************************************************************
DESCRIPTION
    sets the vol to the level corresponding to the phone volume level
    In addition - send a response to the AG indicating new volume level
    
*/
void VolumeSendAndSetHeadsetVolume( uint16 pNewVolume , bool pPlayTone, hfp_link_priority priority ) 
{
    /* ensure profile is connected before changing volume */
    if(priority)
    {
        /*if hfp is attached - then send the vol change, but only if the device is not
          muted or the feature to allow volume changes whilst muted is enabled or the feature to unmute on
          volume changes is enabled */
        if ( (stateManagerIsConnected() && (!theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted))||
             (theSink.features.VolumeChangeCausesUnMute)||(theSink.features.AdjustVolumeWhilstMuted))
        {     
            HfpVolumeSyncSpeakerGainRequest ( priority , (uint8*)&pNewVolume ) ;
        }
        VOL_DEBUG(("VOL: SEND and %x",(unsigned int) priority)) ;
        
        /* make the corresponding local volume changes */
        VolumeSetHeadsetVolume( pNewVolume , pPlayTone, priority );
    }
}


/****************************************************************************
NAME 
    VolumeGet

DESCRIPTION
    Returns the absolute HFP volume level

RETURNS
    void
    
*/
uint16 VolumeGet(void)
{
    uint16 level = 0;
    
    if(deviceManagerNumConnectedDevs())
    {
        hfp_link_priority priority = audioGetLinkPriority(TRUE);
        level = theSink.profile_data[PROFILE_INDEX(priority)].audio.gSMVolumeLevel;
       	VOL_DEBUG(("VOL: VolumeGet AG%d = %d\n", priority, level));
    }
    
    return level;
}


/****************************************************************************
NAME 
    VolumeSet

DESCRIPTION
    Sets HFP volume to absolute level

RETURNS
    void
    
*/
void VolumeSet(uint16 level)
{
    if(deviceManagerNumConnectedDevs())
    {
        /* Get the link to change volume on */
        hfp_link_priority priority = audioGetLinkPriority(TRUE);
        VolumeSendAndSetHeadsetVolume(level, TRUE, priority) ;
       	VOL_DEBUG(("VOL: VolumeSet AG%d = %d\n", priority, level));
    }
}


/****************************************************************************
NAME 
    VolumeCheckHfp

DESCRIPTION
    Increase/Decrease HFP volume

RETURNS
    TRUE if volume was changed, FALSE otherwise
    
*/
static bool VolumeCheckHfp(volume_direction dir)
{
    if(deviceManagerNumConnectedDevs())
    {
        /* Get the link to change volume on */
        hfp_link_priority priority = audioGetLinkPriority(TRUE);
        /* Get current volume for this profile */
        uint16 lOldVol = theSink.profile_data[PROFILE_INDEX(priority)].audio.gSMVolumeLevel;
        /* Obtain new volume level */
        VolMapping_t* mapping = &theSink.conf1->volume_config.gVolMaps[lOldVol];
        uint16 lNewVol = (dir == increase_volume ? mapping->IncVol : mapping->DecVol);

        /* limit to maximum and send notification event when at max level */
        if(lNewVol >= VOLUME_HFP_MAX_LEVEL)
        {
            lNewVol = VOLUME_HFP_MAX_LEVEL;
            MessageSend ( &theSink.task , EventSysVolumeMax , 0 );
        }
        /* limit to minimum and send notification event when at min level */
        else if (lNewVol == VOLUME_HFP_MIN_LEVEL)
        {
            MessageSend ( &theSink.task , EventSysVolumeMin , 0 );
        }
        /* send, set and store new volume level */
        VolumeSendAndSetHeadsetVolume ( lNewVol ,TRUE , priority) ;
        
        VOL_DEBUG(("VOL: VolUp[%d][%d] to AG%d\n",lOldVol, lNewVol, priority))  ;
        return TRUE;
    }
    return FALSE;
}


/****************************************************************************
NAME 
    VolumeCheckUsb

DESCRIPTION
    Increase/Decrease USB volume

RETURNS
 void
    
*/
static void VolumeCheckUsb(volume_direction dir)
{
    if(dir == increase_volume)
        usbVolUp();
    else
        usbVolDn();
}

/****************************************************************************
NAME 
    VolumeCheckFmRx

DESCRIPTION
    Increase/Decrease FM RX volume

RETURNS
 void
    
*/
static bool VolumeCheckFmRx(volume_direction dir)
{
#ifdef ENABLE_FM   
    AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
    uint16 dbValueMaster;

    if (theSink.conf2->sink_fm_data.fmRxOn==TRUE)
    {       
        /* change up or down */
        if(dir == increase_volume)
        {
            /* increase volume by one level up to maximum */
            theSink.volume_levels->fm_volume.masterVolume++; 
            /* limit check */
            if(theSink.volume_levels->fm_volume.masterVolume >= (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1))
            {
    			/* Master volume is the A2DP volume level to check against MAX level for event handling*/ 
				theSink.volume_levels->fm_volume.masterVolume = (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1);
                MessageSend ( &theSink.task , EventSysVolumeMax , 0 );
            }
        }
        /* decrease volume */
        else
        {
            /* decrease volume by one level up to minimum */
            theSink.volume_levels->fm_volume.masterVolume--; 
            /* limit to minimum and send notification event when at min level */
            if(theSink.volume_levels->fm_volume.masterVolume <= VOLUME_A2DP_MIN_LEVEL)
            {                        
                theSink.volume_levels->fm_volume.masterVolume = VOLUME_A2DP_MIN_LEVEL;
                MessageSend ( &theSink.task , EventSysVolumeMin , 0 );                                      
            }
        }      

        /* convert the tone into a dB (* 60) scaled value to send to the dsp */
        theSink.volume_levels->fm_volume.tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
    	
        dbValueMaster =  VolumeConvertStepsToDB(theSink.volume_levels->fm_volume.masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
    	        
    	volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
    	volumeDsp.codec_task = theSink.codec_task;
        volumeDsp.master_gain = dbValueMaster;
        volumeDsp.tones_gain =  theSink.volume_levels->fm_volume.tonesVolume;
        volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
        volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
        volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
        volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
        volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
        volumeDsp.mute_active = theSink.sink_mute_status;

        /* set the volume through the FM audio plugin */
        AudioSetVolumeA2DP ( &volumeDsp);

        /* update the display */
        displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * theSink.volume_levels->fm_volume.masterVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);

        VOL_DEBUG(("VOL: Fm Vol [%d] \n",theSink.volume_levels->fm_volume.masterVolume))  ;

        return TRUE;
    }
#endif
    return FALSE;
}



/****************************************************************************
NAME 
    VolumeCheck

DESCRIPTION
    Increase/Decrease volume

RETURNS
 void
    
*/
void VolumeCheck(volume_direction dir)
{
    /* Try A2DP first */
    if(VolumeCheckA2dp(dir))
        return;
    
    /* Try HFP if has audio */
    if(HfpLinkPriorityFromAudioSink(theSink.routed_audio))
        if(VolumeCheckHfp(dir))
            return;
    /* Try USB if has audio */
    if(usbAudioSinkMatch(theSink.routed_audio))
    {
        VolumeCheckUsb(dir);
        return;
    }

    /* Try wired if has audio */
    if(wiredAudioUpdateVolume(dir))
        return;
    
    /*Try FM RX*/
    if (VolumeCheckFmRx(dir))
        return;

    /* Try USB */
    if(usbGetAudioSink())    
    {    
        VolumeCheckUsb(dir);
        return;
    }

    /* Try HFP without any audio connections */    
    VolumeCheckHfp(dir);
}


/****************************************************************************
NAME 
 VolumeHandleSpeakerGainInd

DESCRIPTION
 Handle speaker gain change indication from the AG

RETURNS
 void
    
*/
void VolumeHandleSpeakerGainInd(HFP_VOLUME_SYNC_SPEAKER_GAIN_IND_T* ind)
{
    VolumeSetHeadsetVolume ( ind->volume_gain , theSink.features.PlayLocalVolumeTone , ind->priority ) ;
}

/****************************************************************************
NAME 
 VolumeUpdateMuteStatus

DESCRIPTION
 Set the mute state for the appropriate audio source currently being routed

RETURNS
 void
    
*/
void VolumeUpdateMuteStatus(bool OnOrOff)
{
    /* audio currently being routed, determine if this is HFP or MUSIC audio */
    audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);

    /* set mute is enabled runtime flag */
    theSink.sink_mute_status = OnOrOff;
    
    /* determine if any audio is currently being routed */                   
    if(theSink.routed_audio)            
    {
        /* is the currently routed audio hfp? */
        if((theSink.routed_audio == lAudioStatus->sinkAG1)||(theSink.routed_audio == lAudioStatus->sinkAG2))
        {
            /* determine which AG is to be muted or unmuted, start with the AG that is currently routing audio */
            hfp_link_priority priority = HfpLinkPriorityFromAudioSink(theSink.routed_audio);
     
            /* send unmute message if suitable AG found */
            if(priority)
            {
                VOL_DEBUG(("VOL: Mute T [%c]\n" , (theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted ? 'F':'T') )) ;

                /* hfp audio currently being routed, update mute state of appropriate AG */
                VolumeSetMicrophoneGain(priority,( OnOrOff ? VOLUME_MUTE_ON:VOLUME_MUTE_OFF)); 
            }
        }
        /* as hfp audio is not currently being routed it must be a music, tone or voice prompt source */
        else
        {
            /* send mute or unmute request to audio plugin */
            if(OnOrOff)
                AudioSetMode(AUDIO_MODE_MUTE_SPEAKER, &theSink.a2dp_link_data->a2dp_audio_mode_params);
            else
                AudioSetMode(AUDIO_MODE_UNMUTE_SPEAKER, &theSink.a2dp_link_data->a2dp_audio_mode_params);                
        }
    }    
    /* free malloc'd status memory slot used for audio status checking */
    freePanic(lAudioStatus);   
}
        


/****************************************************************************
NAME 
 VolumeToggleMute

DESCRIPTION
 Toggles the mute state

RETURNS
 void
    
*/
void VolumeToggleMute ( void )
{
    /* If MUTE enabled, generate EventUsrMuteOff, otherwise generate EventUsrMuteOn */
    if(theSink.sink_mute_status == TRUE)
        MessageSend(&theSink.task, EventUsrMuteOff, 0);
    else
        MessageSend(&theSink.task, EventUsrMuteOn, 0);
}

/****************************************************************************
DESCRIPTION
    sends the current microphone volume to the AG on connection.
*/
void VolumeSendMicrophoneGain(hfp_link_priority priority, uint8 mic_gain) 
{
    /* ensure link is valid before applying mute */
    if(priority != hfp_invalid_link)
    {
        VOL_DEBUG(("VOL: Sending Mic Gain [%d] %d\n", priority, mic_gain));
        /* Set profile's mute bit */
        theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted = (mic_gain ? FALSE : TRUE);
        /* Send mic volume to AG */
        HfpVolumeSyncMicrophoneGainRequest(priority , &mic_gain);
    }
}


/****************************************************************************
DESCRIPTION
    Set mute or unmute (mic gain of VOLUME_MUTE_ON - 0 is mute, all other 
    gain settings unmute).
*/
void VolumeSetMicrophoneGain(hfp_link_priority priority, uint8 mic_gain)
{
     AUDIO_MODE_T mode = AUDIO_MODE_CONNECTED;
           
    VOL_DEBUG(("VOL: Set Mic Gain [%d] %d\n", priority, mic_gain));


    /* update the mute state for the music streaming with back channel support dsp apps */
    theSink.a2dp_link_data->a2dp_audio_mode_params.mic_mute = (~mic_gain & 0x1);
     
    /* determine the priority to control if not passed in */
    if(!priority)    
    {
        /* try to get the currently routed audio */
        priority = HfpLinkPriorityFromAudioSink(theSink.routed_audio);

        /* is there a routed audio that can be muted or unmuted ? */ 
        if(!priority)
        {
            /* no routed audio on device, check for active call on either AG */
            hfp_call_state CallState = hfp_call_state_idle;             
            HfpLinkGetCallState(PROFILE_INDEX(hfp_primary_link), &CallState);
            /* any calls on AG1? */
            if(CallState != hfp_call_state_idle)
                priority = hfp_primary_link;
            /* no calls on AG1, check AG2 */        
            else
            {
                /* call state of AG2 */
                HfpLinkGetCallState(PROFILE_INDEX(hfp_secondary_link), &CallState);
                /* any calls on AG2? */
                if(CallState != hfp_call_state_idle)
                    priority = hfp_secondary_link;                    
            }
        }
    }
    
    VOL_DEBUG(("VOL: Set Mic Gain [%d] priority is: %d\n",  mic_gain, priority));

    /* ensure there is a valid AG to mute */
    if(priority)
    {
        /* If vol has been set to 0 then mute */
        if(mic_gain == VOLUME_MUTE_ON)
        {
            VOL_DEBUG(("VOL: Mute On\n"));
            /* Update settings */
            theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted = TRUE;
            /* check whether feature to mute oth micorphone and speaker is set */
            if (theSink.features.MuteSpeakerAndMic)
                mode = AUDIO_MODE_MUTE_BOTH;
            /* mute microphone only by default */
            else
                mode = AUDIO_MODE_MUTE_MIC;
            /* Cancel any existing reminder tones to prevent numerous scheduled reminder tones */
            MessageCancelAll( &theSink.task , EventSysMuteReminder ) ;
            /* Start reminder tones */
            if(theSink.conf1->timeouts.MuteRemindTime_s !=0)
               MessageSendLater( &theSink.task , EventSysMuteReminder , 0 ,D_SEC(theSink.conf1->timeouts.MuteRemindTime_s ) ) ;                
        }
        /* mute off */        
        else
        {
            VOL_DEBUG(("VOL: Mute Off on priority %d\n",priority));           
            /* Update settings */
            theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted = FALSE;
            /* update mode to non mute */
            mode = AUDIO_MODE_CONNECTED;
            /* Cancel reminder tones if no other muted AG */          
            if((!theSink.profile_data[PROFILE_INDEX(hfp_primary_link)].audio.gMuted)&&
               (!theSink.profile_data[PROFILE_INDEX(hfp_secondary_link)].audio.gMuted))
            {
                MessageCancelAll( &theSink.task , EventSysMuteReminder ) ;
                VOL_DEBUG(("VOL: Mute Off - no mute - stop reminder tones\n"));           
            }
        }

        /* mute/unmute the audio via the audio plguin */
        AudioSetMode(mode,&theSink.a2dp_link_data->a2dp_audio_mode_params);      
    }
    /*This part need to executed only if bidirectional codec is enabled */
#if defined (APTX_LL_BACK_CHANNEL) || defined(INCLUDE_FASTSTREAM)
    else
    {
        /* A2DP mute ?*/
        if( mic_gain == VOLUME_MUTE_ON)
        {
            mode = theSink.features.MuteSpeakerAndMic ? AUDIO_MODE_MUTE_BOTH: AUDIO_MODE_MUTE_MIC;
        }
        /* Update the mute state for the music streaming with back channel support dsp apps */
        theSink.a2dp_link_data->a2dp_audio_mode_params.mic_mute = (~(mic_gain>>1) & 0x1);
        VOL_DEBUG(("VOL: A2DP Mute mode = %d , Mic _mute = %d\n",mode,theSink.a2dp_link_data->a2dp_audio_mode_params.mic_mute));

        /* mute/unmute the audio via the audio plguin */
        AudioSetMode(mode,&theSink.a2dp_link_data->a2dp_audio_mode_params);      
    }
#endif /* defined (APTX_LL_BACK_CHANNEL) || defined(INCLUDE_FASTSTREAM)*/
}

/****************************************************************************
DESCRIPTION
    Set mute or unmute remotely from AG if SyncMic feature bit is enabled
    (mic gain of VOLUME_MUTE_ON - 0 is mute, all other gain settings unmute).
*/
void VolumeSetMicrophoneGainCheckMute(hfp_link_priority priority, uint8 mic_gain)
{          
    
    VOL_DEBUG(("VOL: Set Remote Mic Gain [%d] priority is: %d\n",  mic_gain, priority));

    /* ensure profile passed in is valid */
    if(priority)
    {
        /* if currently muted and volume is non zero then send unmute event */
        if((mic_gain != VOLUME_MUTE_ON)&&(theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted))
        {
            /* does this mute state change affect the currently routed audio? */    
            if(volumeSyncAffectsGain(priority))
            {
                /* it does so indicate unmute has taken place */
                MessageSend(&theSink.task, EventUsrMuteOff, 0);
            }
            /* unmute state change occurred on AG that isn't currently having its audio
               routed, if other AG is not muted then cancel the mute reminder timer */
            else if(!theSink.profile_data[PROFILE_INDEX(OTHER_PROFILE(priority))].audio.gMuted)
            {
                /* prevent mute reminder timer from continuing as no valid mute cases any more */
                MessageCancelAll( &theSink.task , EventSysMuteReminder ) ;
                VOL_DEBUG(("VOL: Check Mute Off - no mute - stop reminder tones\n"));           
            }
            /* update the profile's mute bit */
            theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted = FALSE;
        }
        /* if not muted and request to go into mute state */
        else if((mic_gain == VOLUME_MUTE_ON)&&(!theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted))
        {
            /* is this AG currently having its audio routed?*/
            if(volumeSyncAffectsGain(priority))
            {
                /* audio from this AG routed so process full mute indication */
                MessageSend(&theSink.task, EventUsrMuteOn, 0);
            }
            /* update the profile's mute bit */
            theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted = TRUE;
        }
    }
}


/****************************************************************************
DESCRIPTION
    Determine whether the mute reminder tone should be played in the device, e.g. #
    if AG1 is in mute state but AG2 is not muted and is the active AG then the mute reminder
    tone will not be played, when AG1 becomes the active AG it will be heard.
*/
bool VolumePlayMuteToneQuery(void)
{
    hfp_link_priority priority;
    
    /* determine which AG is currently the active AG */
    priority = audioGetLinkPriority(TRUE);
    

    /* check whether AG that is currently routing its audio to the device speaker is in mute state,
       if it is not then prevent the mute reminder tone from being heard. */
    if((priority) && (theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted == FALSE))
    {
        VOL_DEBUG(("VOL: PlayMuteTone FALSE on %d mute is %d \n",priority,theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted));           
        return FALSE;
    }
    /* all other use cases the mute reminder tone will be heard */    
    else
    {
        VOL_DEBUG(("VOL: PlayMuteTone TRUE on %d mute is %d\n",priority,theSink.profile_data[PROFILE_INDEX(priority)].audio.gMuted));           
        return TRUE;
    }
}
   
    
    

