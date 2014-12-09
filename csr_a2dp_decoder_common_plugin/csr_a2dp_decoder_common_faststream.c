/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_decoder_common_faststream.c
DESCRIPTION
    plugin implentation which routes the sco audio though the dsp
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
#include <pblock.h>

#include "csr_i2s_audio_plugin.h"
#include "audio_plugin_if.h" /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_a2dp_decoder_common_plugin.h"
#include "csr_a2dp_decoder_common.h"
#include "csr_a2dp_decoder_common_if.h"
#include "csr_a2dp_decoder_common_faststream.h"
#include "csr_a2dp_decoder_common_cvc_back_channel.h"

/****************************************************************************
DESCRIPTION
    This function connects FASTSTREAM
    
    FastStream does not use RTP. L2CAP frames enter/leave via port 2
****************************************************************************/
void MusicConnectFaststream(A2dpPluginConnectParams *codecData )
{
    uint32 voice_rate = 16000;
    Sink speaker_snk_a = NULL;
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();

    /*  Initialise PCM. Output stereo at 44k1Hz or 48kHz, input from left ADC at 16kHz.  */
    
    /* If no voice rate is set just make the ADC rate equal to 16kHz */
    if (codecData->voice_rate)
        voice_rate = codecData->voice_rate;

    PRINT(("DECODER: FastStream rate=0x%lx voice_rate=0x%lx\n format=0x%x bitpool=0x%x",DECODER->rate,codecData->voice_rate,codecData->format,codecData->bitpool));

    if (DECODER->rate)
    {
        /* ensure media sink is available, may have been disposed */
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
        /* connect dsp input port */
        PanicFalse(StreamConnect(StreamSourceFromSink(DECODER->media_sink),StreamKalimbaSink(LOW_LATENCY_CODEC_TO_DSP_PORT)));
    }
    
    /* update the current audio state */
    SetAudioInUse(TRUE);
}

