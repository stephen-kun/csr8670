/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_decoder_common_fm.c
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
#include "csr_a2dp_decoder_common_fm.h"

/****************************************************************************
DESCRIPTION
    This function connects FM
    

****************************************************************************/
void MusicConnectFM(A2dpPluginConnectParams *codecData )
{
    Sink speaker_snk_a = NULL;
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();
    Source input_a, input_b;
       
    if (DECODER->rate)
    {
        /* connect the FM receiver I2S to the DSP */
        input_a = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
        PanicFalse(SourceConfigure(input_a, STREAM_I2S_MASTER_MODE, TRUE));
        PanicFalse(SourceConfigure(input_a, STREAM_I2S_SYNC_RATE, DECODER->rate));
        /* connect I2S left channel to dsp */
        PanicFalse(StreamConnect(input_a ,StreamKalimbaSink(WIRED_LINE_A_TO_DSP_PORT)));
    
        input_b = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
        PanicFalse(SourceConfigure(input_b, STREAM_I2S_MASTER_MODE, TRUE));                    
        PanicFalse(SourceConfigure(input_b, STREAM_I2S_SYNC_RATE, DECODER->rate));
        /* connect I2S right channel to dsp */
        PanicFalse(StreamConnect(input_b ,StreamKalimbaSink(WIRED_LINE_B_TO_DSP_PORT)));
               
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
    }
    
    /* update the current audio state */
    SetAudioInUse(TRUE);
}

/****************************************************************************
DESCRIPTION
    This function disconnects the FM I2S ports
    

****************************************************************************/
void MusicDisconnectFM(A2dpPluginConnectParams *codecData )
{
    Source input_a, input_b;
       
    /* disconnect the FM receiver I2S to the DSP */
    input_a = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
    input_b = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
    
    /* disconnect I2S left and right channels from dsp */
    StreamDisconnect(input_a ,StreamKalimbaSink(WIRED_LINE_A_TO_DSP_PORT));
    StreamDisconnect(input_b ,StreamKalimbaSink(WIRED_LINE_B_TO_DSP_PORT));
}


