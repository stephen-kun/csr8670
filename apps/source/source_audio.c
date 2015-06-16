/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_audio.c

DESCRIPTION
    Handles audio routing.    
    
*/


/* header for this file */
#include "source_audio.h"
/* application header files */
#include "source_app_msg_handler.h"
#include "source_debug.h"
#include "source_memory.h"
#include "source_private.h"
#include "source_usb.h"
/* profile/library headers */
#include <audio.h>
#include <kalimba_standard_messages.h>
#include <print.h>
#include <stdlib.h>


#ifdef DEBUG_AUDIO
    #define AUDIO_DEBUG(x) DEBUG(x)
#else
    #define AUDIO_DEBUG(x)
#endif

#define PIO_SPDIF_INPUT (theSource->ps_config->pio_config.spdif_input)

#define PIN_WIRED_ALWAYSON  PIN_INVALID     /* Input PIO is disabled, always assumed on */
#define PIN_WIRED_DISABLED  0xFE            /* Entire input type is disabled */


/* Get audio plugin functions */
static Task audio_a2dp_get_plugin(void);
static Task audio_aghfp_get_plugin(bool wbs);
static bool audio_is_bidir_supported(a2dp_codec_settings* settings);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    audio_plugin_msg_handler - Handles messages received from an audio plugin library
*/
void audio_plugin_msg_handler(Task task, MessageId id, Message message)
{
    switch (id)
    {        
        case AUDIO_PLUGIN_DSP_IND:
        {
            /* Warp value sent from the DSP via the audio plugin */
            if (((AUDIO_PLUGIN_DSP_IND_T *)message)->id == KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE)
            {
                if (theSource->audio_data.audio_routed == AUDIO_ROUTED_AGHFP)
                {
                    /* only store the value for AGHFP audio */
                    aghfp_store_warp_values(((AUDIO_PLUGIN_DSP_IND_T *)message)->size_value,
                                            ((AUDIO_PLUGIN_DSP_IND_T *)message)->value);
                }
            }
        }
        break;

        default:
        {
        }
        break;           
	}	
}


/****************************************************************************
NAME    
    audio_init - Initialise audio part of code
*/
void audio_init(void)
{
    /* initialise audio library */
    AudioLibraryInit();
    
    /* set the input source to either analogue, USB or SPDIF */
    theSource->audio_data.audio_a2dp_connect_params.input_device_type = theSource->ps_config->features.input_source;
    
    if(theSource->ps_config->features.input_source == A2dpEncoderInputDeviceSPDIF)
    {
        if((PIO_SPDIF_INPUT != PIN_WIRED_ALWAYSON) && (PIO_SPDIF_INPUT != PIN_WIRED_DISABLED))
        {
            PioSetFunction(PIO_SPDIF_INPUT, SPDIF_RX);
        }
    }
    
    theSource->audio_data.audio_plugin = NULL;
    theSource->audio_data.audio_routed = AUDIO_ROUTED_NONE;
}


/****************************************************************************
NAME    
    audio_a2dp_connect - Route A2DP audio
*/
void audio_a2dp_connect(Sink sink, uint16 device_id, uint16 stream_id)
{
    uint8 bitpool;
    uint8 bad_link_bitpool;
    bool multiple_streams;
    
    /* start audio active timer */
    audio_start_active_timer();
    
    /* remove any AGHFP audio */
    audio_aghfp_disconnect();
               
    AUDIO_DEBUG(("AUDIO: audio_a2dp_connect\n"));
    
    if (theSource->audio_data.audio_routed == AUDIO_ROUTED_NONE)
    {
    
        theSource->audio_data.audio_a2dp_connect_params.input_source = usb_get_speaker_source(); /* Set the USB Source, not used for Analogue */
        theSource->audio_data.audio_a2dp_connect_params.input_sink = usb_get_mic_sink(); /* Set the USB Sink, not used for Analogue */
        theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[device_id] = sink; /* Set the A2DP media Sink */    
    
        AUDIO_DEBUG(("  audio_routed [%d] input_source [0x%x] input_sink [0x%x] a2dp_sink_0 [0x%x] a2dp_sink_1 [0x%x]\n", 
                     theSource->audio_data.audio_routed, 
                     (uint16)theSource->audio_data.audio_a2dp_connect_params.input_source,
                     (uint16)theSource->audio_data.audio_a2dp_connect_params.input_sink,
                     (uint16)theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[0],
                     (uint16)theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[1]));

        if (theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[0] || theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[1])
        {        
            AudioPluginFeatures features = {0,0,0}; /* no stereo or i2s output */
            a2dp_codec_settings *codec_settings = A2dpCodecGetSettings(device_id, stream_id);
                    
            if (codec_settings)
            {                            
                AUDIO_DEBUG(("  codec ; voice_rate[0x%lx] packet_size[0x%x] bitpool[0x%x] format[0x%x] CP[0x%x]\n",
                             codec_settings->codecData.voice_rate,
                             codec_settings->codecData.packet_size,
                             codec_settings->codecData.bitpool,
                             codec_settings->codecData.format,
                             codec_settings->codecData.content_protection
                             ));
                
                theSource->audio_data.audio_a2dp_connect_params.rate = codec_settings->codecData.voice_rate;
                theSource->audio_data.audio_a2dp_connect_params.packet_size = codec_settings->codecData.packet_size; 
                if (a2dp_get_sbc_bitpool(&bitpool, &bad_link_bitpool, &multiple_streams))
                {
                    theSource->audio_data.audio_a2dp_connect_params.bitpool = bitpool;    
                    theSource->audio_data.audio_a2dp_connect_params.bad_link_bitpool = bad_link_bitpool;
                }
                else
                {
                    theSource->audio_data.audio_a2dp_connect_params.bitpool = codec_settings->codecData.bitpool;
                }                
                theSource->audio_data.audio_a2dp_connect_params.format = codec_settings->codecData.format;                        
                theSource->audio_data.audio_a2dp_mode_params.eq_mode = theSource->volume_data.eq_index;
                theSource->audio_data.audio_a2dp_connect_params.mode = &theSource->audio_data.audio_a2dp_mode_params;
                /* turn on content protection if negotiated */
                theSource->audio_data.audio_a2dp_connect_params.content_protection = codec_settings->codecData.content_protection;

                /* remember if the remote device supports bidirectional audio, i.e. has a MIC back channel */
                theSource->audio_data.audio_remote_bidir_support = audio_is_bidir_supported(codec_settings) ? 1 : 0;
                                       
                theSource->audio_data.audio_routed = AUDIO_ROUTED_A2DP;
                                
                audio_a2dp_get_plugin();
                
                AudioConnect(audio_a2dp_get_plugin(),
                         0, 
        		     	 AUDIO_SINK_AV,
        		    	 theSource->codec,
        		    	 /*a2dp_gain*/10, 
                         codec_settings->rate,
        		    	 features, /* stereo supported, no i2s output */
        		     	 volume_get_mute_mode(),
                         AUDIO_ROUTE_INTERNAL,
        		    	 /*power*/0, 
                         &theSource->audio_data.audio_a2dp_connect_params,
                         &theSource->audioTask);   
                  
                /* free the codec_settings memory that the A2DP library allocated */
                memory_free(codec_settings);
            }
        }   
    }
    else if (theSource->audio_data.audio_routed == AUDIO_ROUTED_A2DP)
    {
        /* connecting additional A2DP device */
        theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[device_id] = sink;
        theSource->audio_data.audio_a2dp_mode_params.connect_sink = sink;
        if (a2dp_get_sbc_bitpool(&bitpool, &bad_link_bitpool, &multiple_streams))
        {
            theSource->audio_data.audio_a2dp_mode_params.bitpool = bitpool;  
            theSource->audio_data.audio_a2dp_mode_params.bad_link_bitpool = bad_link_bitpool;
        }
        
        AUDIO_DEBUG(("  audio_routed [%d] connect_sink [0x%x] bitpool [%d] bad_link_bitpool [%d]\n",
                      theSource->audio_data.audio_routed,
                      (uint16)sink,
                      bitpool,
                      bad_link_bitpool));
         
        audio_update_mode_parameters();  
    }
}


/****************************************************************************
NAME    
    audio_a2dp_disconnect - Disconnect A2DP audio
*/
void audio_a2dp_disconnect(uint16 device_id, Sink media_sink)
{
    uint16 index = 0;
    bool active_audio = FALSE;
    
    if (media_sink)
    {
        if (theSource->audio_data.audio_routed == AUDIO_ROUTED_A2DP)
        {
            /* store that this media is now disconnected */
            theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[device_id] = 0;        
            
            /* see if any other A2DP media is active */
            for (index = 0; index < CSR_A2DP_ENCODER_PLUGIN_MAX_A2DP_SINKS; index++)
            {
                if (theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[index])
                {
                    active_audio = TRUE;
                }
            }
            
            if (active_audio)
            {
                /* A2DP media still active so just disconnect one of the A2DP audio streams */
                theSource->audio_data.audio_a2dp_mode_params.disconnect_sink = media_sink;
                
                AUDIO_DEBUG(("  Disconnect A2DP Audio: sink [0x%x]\n",
                          (uint16)media_sink));
                
                audio_update_mode_parameters();             
            }
            else
            {
                /* no A2DP media still active so disconnect all A2DP audio streams */
                audio_a2dp_disconnect_all();
            }
        }
    }
}


/****************************************************************************
NAME    
    audio_a2dp_disconnect_all - Disconnect all A2DP audio
*/
void audio_a2dp_disconnect_all(void)
{
    uint16 index = 0;
    
    if (theSource->audio_data.audio_routed == AUDIO_ROUTED_A2DP)
    {
        theSource->audio_data.audio_routed = AUDIO_ROUTED_NONE;
        
        for (index = 0; index < CSR_A2DP_ENCODER_PLUGIN_MAX_A2DP_SINKS; index++)
        {
            theSource->audio_data.audio_a2dp_connect_params.a2dp_sink[index] = 0;            
        }
        
        AudioDisconnect();
        
    }
}


/****************************************************************************
NAME    
    audio_a2dp_set_plugin - Set A2DP audio plugin
*/
void audio_a2dp_set_plugin(uint8 seid)
{
    AUDIO_DEBUG(("AUDIO: audio_a2dp_set_plugin [%d]\n", seid));
    
    switch (seid)
    {
        case A2DP_SEID_SBC:
        {
            theSource->audio_data.audio_plugin = (TaskData *)&csr_a2dp_sbc_encoder_plugin;
        }
        break;
        
        case A2DP_SEID_FASTSTREAM:
        {
            theSource->audio_data.audio_plugin = (TaskData *)&csr_a2dp_faststream_encoder_plugin;
        }
        break;
        
        case A2DP_SEID_APTX:        
        {
            theSource->audio_data.audio_plugin = (TaskData *)&csr_a2dp_aptx_encoder_plugin;
        }
        break;        
        
        case A2DP_SEID_APTX_LOW_LATENCY:
        {
            theSource->audio_data.audio_plugin = (TaskData *)&csr_a2dp_aptx_lowlatency_encoder_plugin;
        }
        break;        
        
        default:
        {
        }
        break;
    }
}


/****************************************************************************
NAME    
    audio_set_voip_music_mode

DESCRIPTION
    Set the audio mode in use (VOIP \ MUSIC). 

*/
void audio_set_voip_music_mode(AUDIO_VOIP_MUSIC_MODE_T mode)
{
    AUDIO_DEBUG(("AUDIO: Audio Mode [%d]\n", mode));
    theSource->audio_data.audio_voip_music_mode = mode;
}


/****************************************************************************
NAME    
    audio_switch_voip_music_mode - Switch the audio mode in use (VOIP \ MUSIC)
*/
void audio_switch_voip_music_mode(AUDIO_VOIP_MUSIC_MODE_T new_mode)
{
    if (states_get_state() == SOURCE_STATE_CONNECTED)
    {
        AUDIO_DEBUG(("AUDIO: Switch Audio Mode\n"));
        if ((new_mode == AUDIO_VOIP_MODE) &&
            (theSource->audio_data.audio_voip_music_mode == AUDIO_MUSIC_MODE))
        {
            if (AGHFP_PROFILE_IS_ENABLED && aghfp_get_number_connections())            
            {
                /* only switch if bidirectional support is not enabled, otherwise we're
                 * running with a codec and a remote device which is already feeding us
                 * a MIC back channel */
                if (!theSource->audio_data.audio_remote_bidir_support)
                {
                    /* switch to VOIP mode from MUSIC mode */
                    audio_set_voip_music_mode(AUDIO_VOIP_MODE);
                    MessageSend(&theSource->app_data.appTask, APP_AUDIO_START, 0);
                }
            }
        }
        else if ((new_mode == AUDIO_MUSIC_MODE) &&
                 (theSource->audio_data.audio_voip_music_mode == AUDIO_VOIP_MODE))
        {
            if (A2DP_PROFILE_IS_ENABLED && a2dp_get_number_connections())            
            {
                /* switch to MUSIC mode from VOIP mode */
                audio_set_voip_music_mode(AUDIO_MUSIC_MODE);
                MessageSend(&theSource->app_data.appTask, APP_AUDIO_START, 0);
                /* make sure Voice Recognition is disabled as this can cause audio routing issues on the remote device */
                aghfp_send_voice_recognition(FALSE);
            }
        }
    }
}


/****************************************************************************
NAME    
    audio_aghfp_connect - Route AGHFP audio
*/
void audio_aghfp_connect(Sink sink, bool esco, bool wbs, uint16 size_warp, uint16 *warp)
{
    uint16 i = 0;
    AudioPluginFeatures features = {0,0,0}; /* no stereo or i2s output */

    AUDIO_DEBUG(("AUDIO: audio_aghfp_connect\n"));
    
    /* start audio active timer */
    audio_start_active_timer();
    
    /* remove any A2DP audio */
    audio_a2dp_disconnect_all();
    
    theSource->audio_data.audio_aghfp_connect_params.mic = NULL;
    theSource->audio_data.ag_usb_params.usb_source = usb_get_speaker_source(); /* Set the USB Source */
    theSource->audio_data.ag_usb_params.usb_sink = usb_get_mic_sink(); /* Set the USB Sink */
    theSource->audio_data.audio_aghfp_connect_params.usb = &theSource->audio_data.ag_usb_params;
    
    for (i = 0; i < size_warp; i++)
    {
        theSource->audio_data.audio_aghfp_connect_params.warp[i] = warp[i];
    }

    if (theSource->audio_data.audio_routed == AUDIO_ROUTED_NONE)
    {               
        theSource->audio_data.audio_routed = AUDIO_ROUTED_AGHFP;
              
        AudioConnect(audio_aghfp_get_plugin(wbs),
                        sink, 
                        esco ? AUDIO_SINK_ESCO : AUDIO_SINK_SCO,
                        theSource->codec,
                        /*aghfp_gain*/10, 
                        8000,
                        features ,                        /* no stereo or I2S output required */
                        volume_get_mute_mode(),
                        AUDIO_ROUTE_INTERNAL,
                        /*power*/0, 
                        &theSource->audio_data.audio_aghfp_connect_params,
                        &theSource->audioTask);        
    }
}


/****************************************************************************
NAME    
    audio_aghfp_disconnect - Disconnect AGHFP audio
*/
void audio_aghfp_disconnect(void)
{
    if (theSource->audio_data.audio_routed == AUDIO_ROUTED_AGHFP)
    {
        theSource->audio_data.audio_routed = AUDIO_ROUTED_NONE;
        
        /* unroute audio */    
        AudioDisconnect();       
    }
}
    

/****************************************************************************
NAME    
    audio_route_all - Route audio for all active connections. 
*/
void audio_route_all(void)
{
    /* AGHFP audio */
    aghfp_route_all_audio();    
    
    /* A2DP audio */
    a2dp_route_all_audio();
}


/****************************************************************************
NAME    
    audio_suspend_all - Suspend audio for all active connections
*/
void audio_suspend_all(void)    
{
    /* AGHFP audio */
    aghfp_suspend_all_audio();    
    
    /* A2DP audio */
    a2dp_suspend_all_audio();
}


/****************************************************************************
NAME    
    audio_start_active_timer - Starts the audio active timer in USB mode if the USB audio interfaces are inactive

*/
void audio_start_active_timer(void)
{
    MessageCancelFirst(&theSource->app_data.appTask, APP_USB_AUDIO_ACTIVE);
    MessageCancelFirst(&theSource->app_data.appTask, APP_USB_AUDIO_INACTIVE);
    
#ifndef ANALOGUE_INPUT_DEVICE    
    /* Audio active timer only applies to a USB device as an Analogue input device cannot be notified when audio is present */
    if ((theSource->ps_config->ps_timers.usb_audio_active_timer != TIMER_NO_TIMEOUT) &&
        (!theSource->audio_data.audio_usb_active))
    {
        /* send the audio inactive message after the PS configured delay */
        MessageSendLater(&theSource->app_data.appTask, APP_USB_AUDIO_INACTIVE, 0, D_SEC(theSource->ps_config->ps_timers.usb_audio_active_timer));        
    }
#endif    
}


/****************************************************************************
NAME    
    audio_a2dp_update_bitpool - Change the bitpool for the A2DP audio
*/
void audio_a2dp_update_bitpool(uint8 bitpool, uint8 bad_link_bitpool)
{
    if (theSource->audio_data.audio_routed == AUDIO_ROUTED_A2DP)
    {
        /* change A2DP SBC bitpools */
        theSource->audio_data.audio_a2dp_mode_params.bitpool = bitpool;
        theSource->audio_data.audio_a2dp_mode_params.bad_link_bitpool = bad_link_bitpool;
     
        AUDIO_DEBUG(("AUDIO: audio_a2dp_update_bitpool - bitpool[%d] bad_link_bitpool[%d]\n", bitpool, bad_link_bitpool));
           
        audio_update_mode_parameters();        
    }
}


/****************************************************************************
NAME    
    audio_update_mode_parameters - The audio parameters have changed so update the audio mode 
*/
void audio_update_mode_parameters(void)
{
    AudioSetMode(volume_get_mute_mode(), &theSource->audio_data.audio_a2dp_mode_params);
}
     

/****************************************************************************
NAME    
    audio_a2dp_get_plugin - Get the active A2DP audio plugin
*/
static Task audio_a2dp_get_plugin(void)
{    
    return theSource->audio_data.audio_plugin;
}


/****************************************************************************
NAME    
    audio_aghfp_get_plugin - Get the active AGHFP audio plugin
*/
static Task audio_aghfp_get_plugin(bool wbs)
{
    uint32 usb_sample_rate = usb_get_speaker_sample_rate();
    
    if (wbs)
    {
        switch (usb_sample_rate)
        {
            case 48000:
            {
                return (TaskData *)&csr_ag_audio_sbc_48k_1mic_plugin;
            }
            case 16000:
            {
                return (TaskData *)&csr_ag_audio_sbc_16k_1mic_plugin;
            }
            default:
            {
                Panic(); /* no wide-band audio plugin for this USB sample rate */
            }
        }
        
        return 0;
    }    
    
    switch (usb_sample_rate)
    {
        case 48000:
        {
            return (TaskData *)&csr_ag_audio_cvsd_48k_1mic_plugin;
        }
        case 8000:
        {
            return (TaskData *)&csr_ag_audio_cvsd_8k_1mic_plugin;
        }
        default:
        {
            Panic(); /* no narrow-band audio plugin for this USB sample rate */
        }
    }
    
    return 0;
}

/****************************************************************************
NAME    
    audio_is_bidir_supported - Returns true if remote device supports
                               bidirectional audio.
*/
static bool audio_is_bidir_supported(a2dp_codec_settings* settings)
{
    bool supported = FALSE;

    switch (settings->seid)
    {
        case A2DP_SEID_FASTSTREAM:
        {
            if ((settings->size_configured_codec_caps >= A2DP_FASTSTREAM_DIRECTION_INDEX) &&
                 (settings->configured_codec_caps[A2DP_FASTSTREAM_DIRECTION_INDEX] & A2DP_FASTSTREAM_VOICE))
            {
                supported = TRUE;
            }
        }
        break;

        case A2DP_SEID_APTX_LOW_LATENCY:
        {
            if ((settings->size_configured_codec_caps >= A2DP_APTX_DIRECTION_INDEX) &&
                (settings->configured_codec_caps[A2DP_APTX_DIRECTION_INDEX] & A2DP_APTX_LOWLATENCY_VOICE_16000))
            {
                supported = TRUE;
            }
        }
        break;

        default:
        break;
    }

    return supported;
}
