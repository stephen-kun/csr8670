/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_aptx.c
DESCRIPTION
    aptx specific functions
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
#include "csr_a2dp_decoder_common_aptx.h"

/****************************************************************************
DESCRIPTION
    This function connects APTX standard delay audio 
****************************************************************************/
void MusicConnectAptx(A2dpPluginConnectParams *codecData, uint8 content_protection)
{
    Sink speaker_snk_a = NULL;
    Transform rtp_transform = 0;
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();
    
    /* Initialise PCM. Output stereo at 44k1Hz or 48kHz. */
    PRINT(("DECODER: aptX rate=%u Hz\n",(uint16)DECODER->rate));

    /* ensure sample rate is set to a valid value */
    if (DECODER->rate)
    {
        /* disconnect media sink, it may be been disposed of */
        StreamDisconnect(StreamSourceFromSink(DECODER->media_sink), 0);    
        
        /* determine the output hardware type */
        switch(DECODER->features.audio_output_type)
        {
            /* using the inbuilt dacs */
            case OUTPUT_INTERFACE_TYPE_NONE:
            case OUTPUT_INTERFACE_TYPE_DAC:
            {
                /* configure built-in audio hardware channel A */
                speaker_snk_a = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
                PanicFalse(SinkConfigure(speaker_snk_a, STREAM_CODEC_OUTPUT_RATE, DECODER->rate));
    
                /* if STEREO mode configured then connect the output channel B */
                if(DECODER->features.stereo)
                {
                    Sink speaker_snk_b = NULL;
        
                    PRINT(("DECODER: Stereo\n"));
        
                    /* connect channels B */
                    speaker_snk_b = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                    /* configure channel to required rate */
                    PanicFalse(SinkConfigure(speaker_snk_b, STREAM_CODEC_OUTPUT_RATE, DECODER->rate));
                    /* synchronise both sinks for channels A & B */
                    PanicFalse(SinkSynchronise(speaker_snk_a, speaker_snk_b));
                    /* plug port 1 into Right DAC */
                    PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT),speaker_snk_a));
                    PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT),speaker_snk_b));
                }
                /* mono operation, only connect left port */
                else
                {
                    /* plug port 0 into Left DAC */
                    PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT),speaker_snk_a));
                }
            }
            break;

            /* using the spdif digital output hardware */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                Sink speaker_snk_b = NULL;
                /* configure spdif audio hardware channel 0 */
                speaker_snk_a = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
                speaker_snk_b = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
                /* configure channel to required rate */
                PanicFalse(SinkConfigure(speaker_snk_a,  STREAM_SPDIF_OUTPUT_RATE, DECODER->rate));
                PanicFalse(SinkConfigure(speaker_snk_b,  STREAM_SPDIF_OUTPUT_RATE, DECODER->rate));
                /* connect channels B */
                /* synchronise both sinks for channels A & B */
                PanicFalse(SinkSynchronise(speaker_snk_a, speaker_snk_b));
                /* plug port 1 into Right DAC */
                PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT),speaker_snk_a));
                PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT),speaker_snk_b));   
      
                PRINT(("DECODER: Stereo\n"));
            }
            break;
            
            /* using the i2s digital output hardware */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {
                /* is a specified output frequency required? use resampling*/
                if(CsrI2SMusicResamplingFrequency())
                    CsrI2SAudioOutputConnect(CsrI2SMusicResamplingFrequency(), DECODER->features.stereo, StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT), StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT));                                 
                /* use the negotiated sample rate of the input, no resampling required */                
                else
                    CsrI2SAudioOutputConnect(DECODER->rate, DECODER->features.stereo, StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT), StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT));                                                                
            }            
            break;
        }
    
        /* if content protection required connect the media sink to the decoder transform */
        if (content_protection)
        {
#ifdef SHAREME_SLAVE
            rtp_transform = rtp_transform;
            StreamConnect(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#else
            rtp_transform = TransformRtpDecode(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
            TransformConfigure(rtp_transform, VM_TRANSFORM_RTP_SCMS_ENABLE, content_protection);
            /*start the transform decode*/
            PRINT(("aptX: RTP Transform \n"));
            (void)TransformStart( rtp_transform ) ;
#endif
        }
        /* otherwise connect the media sink to the dsp input port */
        else
        {
            PanicFalse(StreamConnect(StreamSourceFromSink(DECODER->media_sink),StreamKalimbaSink(CODEC_TO_DSP_PORT)));
        }

        /* Send parameters that are to be displayed in Music Manager application */
        PRINT(("aptX: sampling rate=0x%lx channel mode=0x%x \n",DECODER->rate,codecData->channel_mode));
        KalimbaSendMessage(APTX_PARAMS_MSG,DECODER->rate, codecData->channel_mode, 0,0);
    }
    
    /* update the current audio state */
    SetAudioInUse(TRUE);
}
