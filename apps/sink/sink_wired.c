/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_wired.c        

DESCRIPTION
    Application level implementation of Wired Sink features

NOTES
    - Conditional on ENABLE_WIRED define
    - Output PIO is theSink.conf1->PIOIO.pio_outputs.wired_output
    - Input PIO is theSink.conf1->PIOIO.pio_inputs.wired_input
*/

#include "sink_private.h"
#include "sink_debug.h"
#include "sink_wired.h"
#include "sink_audio.h"
#include "sink_pio.h"
#include "sink_powermanager.h"
#include "sink_statemanager.h"
#include "sink_tones.h"
#include "sink_display.h"
#include "sink_audio_routing.h"
#include "sink_volume.h"

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#include <panic.h>
#include <stream.h>
#include <source.h>
#include <sink.h>
#include <string.h>

#ifdef ENABLE_WIRED

#ifdef DEBUG_WIRED
    #define WIRED_DEBUG(x) DEBUG(x)
#else
    #define WIRED_DEBUG(x) 
#endif

/* Wired PIOs */
#define PIO_ANALOG_DETECT (theSink.conf1->PIOIO.pio_inputs.analog_input)
#define PIO_SPDIF_DETECT (theSink.conf1->PIOIO.pio_inputs.spdif_detect)
#define PIO_WIRED_SELECT (theSink.conf1->PIOIO.pio_outputs.PowerOnPIO)
#define PIO_SPDIF_INPUT (theSink.conf1->PIOIO.pio_inputs.spdif_input)
#define PIO_SPDIF_OUTPUT (theSink.conf1->PIOIO.pio_outputs.spdif_output)

#define PIN_WIRED_ALWAYSON  PIN_INVALID     /* Input PIO is disabled, always assumed on */
#define PIN_WIRED_DISABLED  0xFE            /* Entire input type is disabled */

/* Wired audio params */
#ifdef FORCE_WIRED
    #define ANALOG_CONNECTED  (TRUE)
    #define ANALOG_READY      (TRUE)
    #define SPDIF_CONNECTED   (FALSE)
    #define SPDIF_READY       (FALSE)
#else
    /* If the Detect PIO for S/PDIF or analog wired input is set to N/A (0xff), assume always connected */
    #define ANALOG_CONNECTED  (PIO_ANALOG_DETECT == PIN_WIRED_ALWAYSON?TRUE:!PioGetPio(PIO_ANALOG_DETECT))
    #define ANALOG_READY      ((theSink.conf2 != NULL) && (PIO_ANALOG_DETECT !=PIN_WIRED_DISABLED))
    #define SPDIF_CONNECTED   (PIO_SPDIF_DETECT == PIN_WIRED_ALWAYSON?TRUE:!PioGetPio(PIO_SPDIF_DETECT))
    #define SPDIF_READY       ((theSink.conf2 != NULL) && (PIO_SPDIF_DETECT !=PIN_WIRED_DISABLED))
#endif

#define ANALOG_SINK      ((Sink)0xFFFF)
#define SPDIF_SINK       ((Sink)0xFFFE)

#define WIRED_RATE       (48000)
#define WIRED_PLUGIN     (getA2dpPlugin(SBC_SEID))


#include <csr_a2dp_decoder_common_plugin.h>


/****************************************************************************
NAME 
    wiredAudioInit
    
DESCRIPTION
    Set up wired audio PIOs and configuration
    
RETURNS
    void
*/ 
void wiredAudioInit(void)
{
    if(ANALOG_READY)
    {
        WIRED_DEBUG(("WIRE: analog Select %d Detect %d\n", PIO_WIRED_SELECT, PIO_ANALOG_DETECT));
        /* Pull detect high, audio jack will pull it low */
        if(PIO_ANALOG_DETECT != PIN_WIRED_ALWAYSON)
            PioSetPio(PIO_ANALOG_DETECT, pio_pull, TRUE);
        PioSetPio(PIO_WIRED_SELECT, pio_drive, TRUE);
        /* Check audio routing */
        audioHandleRouting(audio_source_none);
    }

    if(SPDIF_READY)
    {
        WIRED_DEBUG(("WIRE: spdif Select %d Detect %d\n", PIO_WIRED_SELECT, PIO_SPDIF_DETECT));
        if(PIO_SPDIF_DETECT != PIN_WIRED_ALWAYSON)
        {
            /* Pull detect high, audio jack will pull it low */
            PioSetPio(PIO_SPDIF_DETECT, pio_pull, TRUE);
        }
        PioSetPio(PIO_WIRED_SELECT, pio_drive, TRUE);
        
        if((PIO_SPDIF_INPUT != PIN_WIRED_ALWAYSON) && (PIO_SPDIF_INPUT != PIN_WIRED_DISABLED))
        {
            /* configure SPDIF ports, required for CSR8675 */
            PioSetFunction(PIO_SPDIF_INPUT, SPDIF_RX);            
        }
        if(PIO_SPDIF_OUTPUT != PIN_INVALID) 
        {
            /* configure SPDIF output port, required for CSR8675 */
            PioSetFunction(PIO_SPDIF_OUTPUT, SPDIF_TX);
        }
        /* Check audio routing */
        audioHandleRouting(audio_source_none);
    }
}

/****************************************************************************
NAME 
    wiredAudioRoute
    
DESCRIPTION
    Route wired audio stream through DSP
    
RETURNS
    void
*/ 
void wiredAudioRoute(Sink audio_sink, int16 master_volume, AUDIO_SINK_T variant_type)
{
    AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
    uint16 volume_dB = VolumeConvertStepsToDB(master_volume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
    uint16 mode   = (master_volume == VOLUME_A2DP_MUTE_GAIN) ? AUDIO_MODE_MUTE_SPEAKER : AUDIO_MODE_CONNECTED;
    
    /* calculate tones volume */
    theSink.volume_levels->analog_volume.tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);

    /* update currently routed audio sink */
    theSink.routed_audio = audio_sink;
    /* Make sure we're using correct parameters for Wired audio */
    theSink.a2dp_link_data->a2dp_audio_connect_params.mode_params = &theSink.a2dp_link_data->a2dp_audio_mode_params;
    /* pass in the AC3 configuration */            
    theSink.a2dp_link_data->a2dp_audio_connect_params.spdif_ac3_config = &theSink.conf2->audio_routing_data.SpdifAC3Settings;
    /* pass in target latency */
    theSink.a2dp_link_data->a2dp_audio_connect_params.target_latency_config = &theSink.conf2->audio_routing_data.TargetLatency;            

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

    WIRED_DEBUG(("WIRE: Routing (Vol %ddB)\n", volume_dB));

#if defined ENABLE_PEER && defined PEER_TWS
    {
        AudioPluginFeatures PluginFeatures = theSink.conf2->audio_routing_data.PluginFeatures;
        PluginFeatures.audio_input_routing = AUDIO_ROUTE_INTERNAL_AND_RELAY;
        
        switch (WIRED_RATE)
        {
        case 16000:
            theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 53;
            theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0x3F;    /* 16Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
            break;
        case 32000:
            theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 53;
            theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0x7F;    /* 32Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
            break;
        case 44100:
            theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 53;
            theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0xBF;    /* 44.1Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
            break;
        case 48000:
            theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 51;
            theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0xFF;    /* 48Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
            break;
        default:
            /* Unsupported rate */
            break;
        }
        
        WIRED_DEBUG(("WIRE: AUDIO_ROUTE_INTERNAL_AND_RELAY\n"));
        AudioConnect(WIRED_PLUGIN, 
                     audio_sink, 
                     variant_type, 
                     theSink.codec_task, 
                     theSink.volume_levels->analog_volume.tonesVolume, 
                     WIRED_RATE, 
                     PluginFeatures, 
                     mode, 
                     AUDIO_ROUTE_INTERNAL, 
                     powerManagerGetLBIPM(), 
                     &theSink.a2dp_link_data->a2dp_audio_connect_params, 
                     &theSink.task);
    }
#else
    WIRED_DEBUG(("WIRE: AUDIO_ROUTE_INTERNAL\n"));
    
    /* connect wired audio using the a2dp_decoder_common_plugin */
    AudioConnect(WIRED_PLUGIN, 
                 audio_sink, 
                 variant_type, 
                 theSink.codec_task, 
                 theSink.volume_levels->analog_volume.tonesVolume, 
                 WIRED_RATE, 
                 theSink.conf2->audio_routing_data.PluginFeatures, 
                 mode, 
                 AUDIO_ROUTE_INTERNAL, 
                 powerManagerGetLBIPM(), 
                 &theSink.a2dp_link_data->a2dp_audio_connect_params, 
                 &theSink.task);
#endif
                
    audioControlLowPowerCodecs (FALSE) ;
    

    /* update volume via a2dp common plugin */
    volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
    volumeDsp.codec_task = theSink.codec_task;
    volumeDsp.master_gain = volume_dB;
    volumeDsp.tones_gain =  theSink.volume_levels->analog_volume.tonesVolume;
    volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
    volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
    volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
    volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
    volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
    volumeDsp.mute_active = theSink.sink_mute_status;
    
    AudioSetVolumeA2DP ( &volumeDsp);
    
    /* set the operating mode */
    AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);

#ifdef ENABLE_SUBWOOFER
    /* set subwoofer volume level */
    updateSwatVolume(master_volume);
#endif
    
} 

/****************************************************************************
NAME 
    wiredAudioDisconnect
    
DESCRIPTION
    Force disconnect of wired audio
    
RETURNS
    void
*/ 
void wiredAudioDisconnect(void)
{
    if((ANALOG_READY && analogAudioSinkMatch(theSink.routed_audio))||
       (SPDIF_READY && spdifAudioSinkMatch(theSink.routed_audio)))
    {
        WIRED_DEBUG(("WIRE: Disconnect Audio\n"));
        AudioDisconnect();
        theSink.routed_audio = 0;

        /* Update limbo state */
        if (stateManagerGetState() == deviceLimbo )
            stateManagerUpdateLimboState();
    }
}

/****************************************************************************
NAME 
    analogAudioRoute
    
DESCRIPTION
    Route analog audio stream through DSP
    
RETURNS
    void
*/ 
void analogAudioRoute(void)
{
    WIRED_DEBUG(("ANALOG: Audio "));

    /* If config ready check PIO - Connected if low */
    if(ANALOG_READY && ANALOG_CONNECTED)
    {
        WIRED_DEBUG(("Connected [0x%04X]\n", (uint16)ANALOG_SINK));
        /* If wired audio not already connected, connect it */
        if(theSink.routed_audio != ANALOG_SINK)
        {
            /* route the analog audio */
            wiredAudioRoute(ANALOG_SINK, theSink.volume_levels->analog_volume.masterVolume, AUDIO_SINK_ANALOG);
        }
    }
    else
    {
        WIRED_DEBUG(("Disconnected\n"));
        wiredAudioDisconnect();
    }
}

/****************************************************************************
NAME 
    spdifAudioRoute
    
DESCRIPTION
    Route spdif audio stream through DSP
    
RETURNS
    void
*/ 
void spdifAudioRoute(void)
{
    WIRED_DEBUG(("SPDIF: Audio "));

    /* If config ready check PIO - Connected if low */
    if(SPDIF_READY && SPDIF_CONNECTED)
    {
        WIRED_DEBUG(("Connected [0x%04X]\n", (uint16)SPDIF_SINK));
        /* If wired audio not already connected, connect it */
        if(theSink.routed_audio != SPDIF_SINK)
        {
            /* route the spdif audio */
            wiredAudioRoute(SPDIF_SINK,theSink.volume_levels->spdif_volume.masterVolume, AUDIO_SINK_SPDIF);
        }
    }
    else
    {
        WIRED_DEBUG(("Disconnected\n"));
        wiredAudioDisconnect();
    }
}

/****************************************************************************
NAME 
    analogAudioSinkMatch
    
DESCRIPTION
    Compare sink to analog audio sink.
    
RETURNS
    TRUE if Sink matches, FALSE otherwise
*/ 
bool analogAudioSinkMatch(Sink sink)
{
    if(ANALOG_READY)
        return sink == ANALOG_SINK;
    return FALSE;
}

/****************************************************************************
NAME 
    spdifAudioSinkMatch
    
DESCRIPTION
    Compare sink to spdif audio sink.
    
RETURNS
    TRUE if Sink matches, FALSE otherwise
*/ 
bool spdifAudioSinkMatch(Sink sink)
{
    if(SPDIF_READY)
        return sink == SPDIF_SINK;
    return FALSE;
}


/****************************************************************************
NAME 
    wiredAudioUpdateVolume
    
DESCRIPTION
    Adjust wired audio volume if currently being routed
    
RETURNS
    TRUE if wired audio being routed, FALSE otherwise
*/ 
bool wiredAudioUpdateVolume(volume_direction dir)
{   
    int16 oldVolume;
    
    /* if either the analog or spdif inputs are routed, adjust the appropriate volume */
    if((analogAudioSinkMatch(theSink.routed_audio))||(spdifAudioSinkMatch(theSink.routed_audio)))
    {
        AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
    	uint16 dbValueMaster;
        int16 * masterVolume;
                
        /* determeine the volume source to adjust */
        if(analogAudioSinkMatch(theSink.routed_audio))
        {
            masterVolume = &theSink.volume_levels->analog_volume.masterVolume;
            WIRED_DEBUG(("analog: master %d ana vol %d\n", *masterVolume, theSink.volume_levels->analog_volume.masterVolume));
        }
        else
        {
            masterVolume = &theSink.volume_levels->spdif_volume.masterVolume;
            WIRED_DEBUG(("spdif: master %d spdif vol %d\n", *masterVolume, theSink.volume_levels->spdif_volume.masterVolume));
        }            
 
        /* take copy of old volume level to check for exit from mute state */
        oldVolume = *masterVolume;
        
        /* change up or down */
        if(dir == increase_volume)
        {
            /* Volume level should be lifted upwards by predefined coefficient 
    		which is used to map allowed a2dp volume level range into avrcp volume index values */ 
            (*masterVolume)++; 
            /* limit check */
            if(*masterVolume >= (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1))
            {
    			/* Master volume is the A2DP volume level to check against MAX level for event handling*/ 
				*masterVolume = (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1);
                MessageSend ( &theSink.task , EventSysVolumeMax , 0 );
            }
        }
        /* decrease volume */
        else
        {
            /* decrease volume by one level down to minimum */
            (*masterVolume)--;
            /* limit to minimum and send notification event when at min level */
            if(*masterVolume <= VOLUME_A2DP_MIN_LEVEL)
            {                        
                *masterVolume = VOLUME_A2DP_MIN_LEVEL;
                MessageSend ( &theSink.task , EventSysVolumeMin , 0 );                                      
            }
        }                

        WIRED_DEBUG(("wired vol: new master %d\n", *masterVolume));
        
        /* check for mute state */
        if(*masterVolume == VOLUME_A2DP_MIN_LEVEL)
        {
            /* muted state, set master gain to -120dB */
            dbValueMaster = VOLUME_MUTE_DB;
        }
        else
        {        
            /* convert to dB */
            dbValueMaster =  VolumeConvertStepsToDB(*masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
        }       

        /* convert the tone into a dB (* 60) scaled value to send to the dsp */
        theSink.volume_levels->analog_volume.tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
    	    	        
        WIRED_DEBUG(("VOL: A2dp set vol [%d][%x]\n", theSink.volume_levels->analog_volume.masterVolume, dbValueMaster));

    	volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
    	volumeDsp.codec_task = theSink.codec_task;
        volumeDsp.master_gain = dbValueMaster;
        volumeDsp.tones_gain =  theSink.volume_levels->analog_volume.tonesVolume;
        volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
        volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
        volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
        volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
        volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
        volumeDsp.mute_active = theSink.sink_mute_status;

        /* indicate volume change on display */
        displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * *masterVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
        
#ifdef ENABLE_SUBWOOFER
        updateSwatVolume(*masterVolume);
#endif
        
        WIRED_DEBUG(("WIRE: Volume %s\n", (dir == increase_volume) ? "Up" : "Down"));
        /* update volume via a2dp common plugin */
        AudioSetVolumeA2DP ( &volumeDsp);

        /* check whether wired volume has gone from 0 (mute) to a valid level, if so
           send set mode message to plugin to unmute output */
        if((oldVolume == VOLUME_A2DP_MIN_LEVEL)&&(*masterVolume != VOLUME_A2DP_MIN_LEVEL))
        {
            /* set the operating mode to FULL_PROCESSING */
            AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
            /* send set mode message to DSP to unmute output ports of DSP */
            AudioSetMode(AUDIO_MODE_UNMUTE_SPEAKER, &theSink.a2dp_link_data->a2dp_audio_mode_params);  
        }
        /* volume successfully updated */
        return TRUE;
    }
    return FALSE;
}


#if defined ENABLE_PEER && defined PEER_TWS 

/****************************************************************************
NAME 
    wiredAudioCheckDeviceTrimVol
    
DESCRIPTION
    Adjust wired audio volume if currently being routed
    
RETURNS
    TRUE if wired audio being routed, FALSE otherwise
*/ 

bool wiredAudioCheckDeviceTrimVol(volume_direction dir, tws_device_type tws_device)
{ 
    /* if either the analog or spdif inputs are routed, adjust the appropriate volume */
    if(!analogAudioSinkMatch(theSink.routed_audio))
    {
        return FALSE;
    }

    VolumeUpdateDeviceTrim(dir, tws_device);

    /*Update trim volume to the dsp */
    wiredAudioSetVolume();       

    /* volume successfully updated */
    return TRUE;
}
#endif

/****************************************************************************
NAME
    wiredAudioSetVolume

DESCRIPTION
    Set Wired audio volume

RETURNS
    void
*/

void wiredAudioSetVolume(void)
{
    AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
    uint16 dbValueMaster;
    int16 * masterVolume;
            
    masterVolume = &theSink.volume_levels->analog_volume.masterVolume;
    
    /* check for mute state */
    if(*masterVolume == VOLUME_A2DP_MIN_LEVEL)
    {
        /* muted state, set master gain to -120dB */
        dbValueMaster = VOLUME_MUTE_DB;
    }
    else
    {        
        /* convert to dB */
        dbValueMaster =  VolumeConvertStepsToDB(*masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
    }       
    
    /* convert the tone into a dB (* 60) scaled value to send to the dsp */
    theSink.volume_levels->analog_volume.tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
                    
    WIRED_DEBUG(("ANALOG: set vol [%d][%x]\n", theSink.volume_levels->analog_volume.masterVolume, dbValueMaster));
    
    volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
    volumeDsp.codec_task = theSink.codec_task;
    volumeDsp.master_gain = dbValueMaster;
    volumeDsp.tones_gain =  theSink.volume_levels->analog_volume.tonesVolume;
    volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
    volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
    volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
    volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
    volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
    volumeDsp.mute_active = theSink.sink_mute_status;
    
    /* indicate volume change on display */
    displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * *masterVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);      
    
     /* update trim volume via a2dp common plugin */
    AudioSetVolumeA2DP ( &volumeDsp);
    
}

/****************************************************************************
NAME 
    analogAudioConnected
    
DESCRIPTION
    Determine if analog audio input is connected
    
RETURNS
    TRUE if connected, otherwise FALSE
*/ 
bool analogAudioConnected(void)
{
    /* If Wired mode configured and ready check PIO */
    if (ANALOG_READY)
    {
        return ANALOG_CONNECTED;
    }

    /* Wired audio cannot be connected yet */
    return FALSE;
}

/****************************************************************************
NAME 
    analogGetAudioSink
    
DESCRIPTION
    Check analog state and return sink if available
    
RETURNS
    Sink if available, otherwise NULL
*/ 
Sink analogGetAudioSink(void)
{
    if (ANALOG_READY)
    {
        return ANALOG_SINK;
    }
    
    return NULL;
}


/****************************************************************************
NAME 
    analogGetAudioRate
    
DESCRIPTION
    Obtains the current defined sample rate for wired audio
    
RETURNS
    None
*/ 
void analogGetAudioRate (uint16 *rate)
{
    if (ANALOG_READY)
    {
        *rate = WIRED_RATE;
    }
    else
    {
        *rate = 0;
    }
}


/****************************************************************************
NAME 
    spdifAudioConnected
    
DESCRIPTION
    Determine if spdif audio input is connected
    
RETURNS
    TRUE if connected, otherwise FALSE
*/ 
bool spdifAudioConnected(void)
{
    /* If Wired mode configured and ready check PIO */
    if (SPDIF_READY)
    {
        return SPDIF_CONNECTED;
    }

    /* spdif audio cannot be connected yet */
    return FALSE;
}

/****************************************************************************
NAME 
    spdifGetAudioSink
    
DESCRIPTION
    Check spdif state and return sink if available
    
RETURNS
    Sink if available, otherwise NULL
*/ 
Sink spdifGetAudioSink(void)
{
    if (SPDIF_READY)
    {
        return SPDIF_SINK;
    }
    
    return NULL;
}

#endif /* ENABLE_WIRED */
