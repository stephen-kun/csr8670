/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_decoder_cvc_back_channel.c
DESCRIPTION
    cvc back channel specific functions
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <print.h>
#include <file.h>
#include <stream.h> /*for the ringtone_note*/
#include <kalimba.h>
#include <kalimba_standard_messages.h>
#include <message.h>
#include <ps.h>
#include <Transform.h>
#include <string.h>
#include <pio_common.h>

#include "csr_i2s_audio_plugin.h"
#include "audio_plugin_if.h" /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_a2dp_decoder_common_plugin.h"
#include "csr_a2dp_decoder_common.h"
#include "csr_a2dp_decoder_common_if.h"
#include "csr_a2dp_decoder_common_cvc_back_channel.h"
#include "csr_a2dp_decoder_common_low_latency.h"


/****************************************************************************
DESCRIPTION
    This function disconnects any CVC microphone back channels
****************************************************************************/    
void CsrA2dpDecoderPluginDisconnectMic(A2dpPluginConnectParams *codecData)
{
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();
    Source l_src = AudioPluginGetMic(AUDIO_CHANNEL_A, codecData->mic_params->mic_a.digital);
            
    /* if microphone back channel is connected then disconnect it */
    if (l_src)
    {
        /* disconnect and close the source */
        StreamDisconnect(l_src, 0);
        SourceClose(l_src);

        /* reset the mic bias pio drive */
        AudioPluginSetMicPio(codecData->mic_params->mic_a, FALSE);
    }

    /* one or two mic back channel ? */
    if(DECODER->features.use_two_mic_back_channel)
    {
        Source r_src = AudioPluginGetMic(AUDIO_CHANNEL_B, codecData->mic_params->mic_b.digital);

    	/* if right mic channel is connected then disconnect it */
        if(r_src)
        {
            /* disconnect and close the source */
            StreamDisconnect(r_src, 0);
            SourceClose(r_src);
    
            /* reset the mic bias pio for mic B */
            AudioPluginSetMicPio(codecData->mic_params->mic_b, FALSE);
        }
    }
}


/****************************************************************************
DESCRIPTION
    This function controls the mute of the microphone back channels
****************************************************************************/    
void CsrA2dpDecoderPluginMuteMic(A2dpPluginConnectParams * codecData, A2DP_DECODER_PLUGIN_TYPE_T a2dp_plugin_variant, A2dpPluginModeParams * mode_params)
{
     /*Mute mic only of back channel plugin is used */
     if((codecData)&&(mode_params)&&
        ((a2dp_plugin_variant == APTX_DECODER)||
         (a2dp_plugin_variant == FASTSTREAM_SINK))
       )
     {
            /* Mute Mic, as this functionality is not supported by DSP,
            Directly controlling the mic*/
            PRINT(("DECODER: Set Mic Mute to [%x]\n" , mode_params->mic_mute ));
            MicMuteUnmute(codecData,mode_params->mic_mute);
     }
}


/****************************************************************************
DESCRIPTION
    Sets the audio mode
*/
void CsrA2dpDecoderPluginSetLowLatencyMode ( AUDIO_MODE_T mode , A2dpPluginTaskdata *task , A2dpPluginModeParams *mode_params, A2DP_MUSIC_PROCESSING_T music_processing )
{
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();
    /* pre-initialise with the most common parameters and adjust below as necessary */
    A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
    uint16 sysmode;
    uint16 call_state = CALLST_CONNECTED;
    uint16 volume;

    if (!DECODER)
        Panic() ;

    /* update the current operating mode stored value */
    DECODER->mode = mode;

    /* set current volume level */
    volume  = DECODER->volume.master_gain;
    
    /* default operating mode of full processing */
    sysmode = SYSMODE_HFK;

    /* determine current operating mode */
    switch (mode)
    {
        /* mute operation */
        case AUDIO_MODE_MUTE_SPEAKER:        
        case AUDIO_MODE_MUTE_BOTH:
        {
            /* Always standby */
            sysmode = SYSMODE_STANDBY;
            volume = DAC_MUTE;
            KalimbaSendMessage(LOW_LATENCY_SETMODE_MSG, MUSIC_SYSMODE_STANDBY, 1, 0, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
        
            /* if using the microphone or spdif/i2s back channel */   
            if(isCodecLowLatencyBackChannel())
            {
                /*If Mic has been muted, then unmute , as this functionality is 
                  not supported by DSP,Directly controlling the mic*/
                mode_params->mic_mute = TRUE;
                CsrA2dpDecoderPluginMuteMic(codecData, (A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant, mode_params); 
            }
        }
        break;
        /* left/1st mic pass through mode */
        case AUDIO_MODE_LEFT_PASSTHRU:
            sysmode = SYSMODE_LEFT_PASSTHRU;        
        break;

        /* right/2nd mic pass through mode */        
        case AUDIO_MODE_RIGHT_PASSTHRU:
            sysmode = SYSMODE_RIGHT_PASSTHRU;        
        break;
        
        /* low volume operating mode */
        case AUDIO_MODE_LOW_VOLUME:
            sysmode = SYSMODE_LOW_VOLUME;
        break;
        
        /* no mute required, full processing as default mode */        
        case AUDIO_MODE_CONNECTED:                   
        case AUDIO_MODE_UNMUTE_SPEAKER:
        
            /* if using the microphone or spdif/i2s back channel */   
            if(isCodecLowLatencyBackChannel())
            {
                /*If Mic has been muted, then unmute , as this functionality is 
                  not supported by DSP,Directly controlling the mic*/
                mode_params->mic_mute = FALSE;
                CsrA2dpDecoderPluginMuteMic(codecData, (A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant, mode_params); 
            }

            /* when sub woofer is enabled and a sub link is connected, put dsp into bassmanagement mode */
            if(codecData->sub_woofer_type != AUDIO_SUB_WOOFER_NONE)
            {
               /* set the current EQ mode of operation */                    
               CsrA2dpDecoderLowLatencyPluginSetEqMode(music_processing);
            }
            else
            {
               /* set the current EQ mode of operation */                    
               CsrA2dpDecoderLowLatencyPluginSetEqMode(music_processing);
            }

            /* update the audio enhancements settings */
            CsrA2dpDecoderPluginUpdateEnhancements(mode_params);

        break;
            
        default:
        {
            PRINT(("DECODER: Set Audio Mode Invalid [%x]\n" , mode ));
        }
        break;
    }
	/*send update to kalimba */
    PRINT(("CVC: SYSMODE 0x%x, CALLSTATE 0x%x, VOL 0x%x\n", sysmode, call_state, volume));
    KalimbaSendMessage(LOW_LATENCY_VOLUME_MSG, 0, 0, volume, DECODER->volume.tones_gain);
    KalimbaSendMessage(LOW_LATENCY_SETMODE_MSG, sysmode, 0, call_state, ( codecData->mic_params->mic_a.digital << 1 ) | codecData->mic_params->mic_b.digital );
}

/****************************************************************************
DESCRIPTION
    utility function to set microphone gains for the CVC back channel variants

    @return void
*/
void CvcMicSetGain(audio_channel channel, bool digital, T_mic_gain gain)
{
    Source mic_source = AudioPluginGetMic(channel, digital);
    uint8 mic_gain = (digital ? gain.digital_gain : gain.analogue_gain);
    AudioPluginSetMicGain(mic_source, digital, mic_gain, gain.preamp_enable);
}

/****************************************************************************
DESCRIPTION
    utility function to connect the 1 or two mics to the cvc back channel app

    @return void
*/
void CsrA2dpDecoderConnectBackChannel(A2dpPluginConnectParams * codecData, bool use_two_mic_back_channel)
{
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();

    /****************************************/
    /* connect the back channel microphones */
    /****************************************/

    /* obtain source for mic a */
    Source mic_source_a = AudioPluginGetMic(AUDIO_CHANNEL_A, codecData->mic_params->mic_a.digital);
    /* set microphone sample rate */
    AudioPluginSetMicRate(mic_source_a, codecData->mic_params->mic_a.digital, BACK_CHANNEL_SAMPLE_RATE); 
    /* Set mic bias pin */
    AudioPluginSetMicPio(codecData->mic_params->mic_a, TRUE);

    /* set mic bias pin for second microphone if 2 mic variant is chosen */    
    if(use_two_mic_back_channel)
    {
        /* obtain source for microphone b */
        Source mic_source_b = AudioPluginGetMic(AUDIO_CHANNEL_B, codecData->mic_params->mic_b.digital);
        /* set mic b input sample rate */
        AudioPluginSetMicRate(mic_source_b, codecData->mic_params->mic_b.digital, BACK_CHANNEL_SAMPLE_RATE); 
        /* set mic b bias pin */
        AudioPluginSetMicPio(codecData->mic_params->mic_b, TRUE);
        /* synchronise the two microphone inputs */
        SourceSynchronise(mic_source_a, mic_source_b);
        /* connect 1st mic to dsp */
        PanicFalse(StreamConnect(mic_source_a, StreamKalimbaSink(CVC_1MIC_PORT)));
        PRINT(("A2DP: connect 1-mic back channel\n"));
        /* connect 2nd mic to dsp */
        PanicFalse(StreamConnect(mic_source_b, StreamKalimbaSink(CVC_2MIC_PORT)));
        PRINT(("A2DP: connect 2-mic back channel\n"));
    }
    else
    {
        /* connect 1st mic to dsp */
        PanicFalse(StreamConnect(mic_source_a, StreamKalimbaSink(CVC_1MIC_PORT)));
        PRINT(("A2DP: connect 1-mic back channel\n"));
    }

    /* stream currently disposed, disconnect and */
    StreamDisconnect(0, DECODER->media_sink);
    /* connect the back channel to the l2cap link */
    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_BACK_CHANNEL_PORT),DECODER->media_sink));

}

/****************************************************************************
DESCRIPTION
    utility function to determine which low latency application is running and 
    whether it supports back channel operation or not

    @return back channel support as true or false
*/
bool isCodecLowLatencyBackChannel(void)
{
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();

    /* determine if the app running supports back channel */
    if(DECODER && ((DECODER->task->a2dp_plugin_variant == FASTSTREAM_SINK)||(DECODER->task->a2dp_plugin_variant == APTX_ACL_SPRINT_DECODER))&&
        (DECODER->features.use_one_mic_back_channel || DECODER->features.use_two_mic_back_channel))
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

