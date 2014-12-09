/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    tone.h
DESCRIPTION
    plugin implentation which plays tones
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <stream.h>
#include <print.h>
#include <stream.h> 
#include <message.h>
                                                                                                                    
#include "audio_plugin_if.h" /*for the audio_mode*/
#include "csr_tone.h"
#include "csr_tone_plugin.h"
#include "csr_i2s_audio_plugin.h"


typedef struct
{
    Sink audio_sink;
    AudioPluginFeatures features;
} TONE_T;

static TONE_T TONE;


/****************************************************************************
DESCRIPTION
    plays a tone using the audio plugin    
*/
void CsrTonePluginPlayTone ( ringtone_note * tone, Task codec_task, uint16 tone_volume , AudioPluginFeatures features) 
{    
    Source lSource ;
	Sink spkr_sink_a = NULL;
	Sink spkr_sink_b = NULL;
    
   
  	/*obtain source to the tone*/		
	lSource = StreamRingtoneSource ( (const ringtone_note *) tone ) ;    
    
    /* deteremine output type */
    switch(features.audio_output_type)
    {
        /* when using the i2s output in conjunction with external hardware */
        case OUTPUT_INTERFACE_TYPE_I2S:
        { 
            /* update output type */
            TONE.features.audio_output_type = features.audio_output_type;
            TONE.features.stereo = features.stereo;
            /* connect tone to i2s output */
            if(TONE.features.stereo)
            {
                Source lSource2 = StreamRingtoneSource ( (const ringtone_note *) tone ) ;    
                SourceSynchronise(lSource,lSource2);
                PRINT(("TONE: Play Stereo\n"));
                TONE.audio_sink = CsrI2SAudioOutputConnect(8000, TRUE, lSource, lSource2);  
            }
            else
            {
                PRINT(("TONE: Play Mono\n"));
                TONE.audio_sink = CsrI2SAudioOutputConnect(8000, FALSE, lSource, NULL);             
            }
            /*request an indication that the tone has completed / been disconnected*/
            MessageSinkTask ( TONE.audio_sink , (TaskData*)&csr_tone_plugin ) ;
            /* and set its volume level */
            CsrI2SAudioOutputSetVolume(TONE.features.stereo, tone_volume, tone_volume, FALSE);
        }
        break;
        
        /* when using the spdif output in conjunction with external hardware */
        case OUTPUT_INTERFACE_TYPE_SPDIF:
        { 
            /* must be stereo */
            Source lSource2 = StreamRingtoneSource ( (const ringtone_note *) tone ) ;    
            SourceSynchronise(lSource,lSource2);
            /* update output type */
            TONE.features.audio_output_type = features.audio_output_type;
            TONE.features.stereo = features.stereo;
            /* must be stereo for spdif output */
            spkr_sink_a = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
            spkr_sink_b = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
			TONE.audio_sink = spkr_sink_a;
            /* configure channel to required rate */
            PanicFalse(SinkConfigure(spkr_sink_a,  STREAM_SPDIF_OUTPUT_RATE, 8000));
            PanicFalse(SinkConfigure(spkr_sink_b,  STREAM_SPDIF_OUTPUT_RATE, 8000));
            /* synchronise both sinks for channels A & B */
            PanicFalse(SinkSynchronise(spkr_sink_a, spkr_sink_b));
            /* connect ports */
            PanicFalse(StreamConnectAndDispose(lSource, spkr_sink_a));
            PanicFalse(StreamConnectAndDispose(lSource2, spkr_sink_b));
            /*request an indication that the tone has completed / been disconnected*/
            MessageSinkTask ( TONE.audio_sink , (TaskData*)&csr_tone_plugin ) ;
        }
        break;
        
        /* use internal codec for DAC speaker drive */
        default:
        {
            CodecSetOutputGainNow(codec_task, 0, left_and_right_ch);   
     
            spkr_sink_a = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, (features.stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
        
            TONE.audio_sink = spkr_sink_a;
        
            PRINT(("TONE: Play tone, stereo[%d] sink[0x%x] vol[%d]\n", features.stereo, (uint16)spkr_sink_a, tone_volume));    
        
            PanicFalse(SinkConfigure(spkr_sink_a, STREAM_CODEC_OUTPUT_RATE, 8000));
           
            /*request an indication that the tone has completed / been disconnected*/
            MessageSinkTask ( spkr_sink_a , (TaskData*)&csr_tone_plugin ) ;
            
            /* connect tone source to speaker port */            
            PanicFalse( StreamConnectAndDispose( lSource , spkr_sink_a ) );
        
            CodecSetOutputGainNow(codec_task, tone_volume, left_and_right_ch); 
        }
    }
    
    /* update current tone playing status */
    SetTonePlaying(TRUE);

}

/****************************************************************************
DESCRIPTION
	Stop a tone from currently playing
*/
void CsrTonePluginStopTone ( void ) 
{  
    PRINT(("TONE: Terminated\n"));
   
    if (TONE.audio_sink)
    {
        /* unregister notifications */
        MessageSinkTask(TONE.audio_sink, NULL);	

        /* deteremine output type */
        switch(TONE.features.audio_output_type)
        {
            /* when using the i2s output in conjunction with external hardware */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {
                /* i2s */
                CsrI2SAudioOutputDisconnect(TONE.features.stereo); 
            }
            break;
            
            /* using spdif audio output */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                /* obtain source to SPDIF hardware and disconnect it */
                Sink l_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
                Sink r_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
                StreamDisconnect(0, l_sink);
                StreamDisconnect(0, r_sink);
                SinkClose(l_sink);
                SinkClose(r_sink);
            }
            break;
        
            /* DAC output */
            default:
            {                   
                StreamDisconnect(0, TONE.audio_sink); 
                SinkClose(TONE.audio_sink);
            }
            break;
        }
        /* reset sinik */
        TONE.audio_sink = 0;
        /* update current tone playing status */
        SetTonePlaying(FALSE);
    }
}

/****************************************************************************
DESCRIPTION
	a tone has completed
*/
void CsrTonePluginToneComplete (void )
{
    PRINT(("TONE: Complete\n"));
  
    CsrTonePluginStopTone();
}

