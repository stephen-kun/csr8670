/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_dut_audio.c
    
DESCRIPTION
    Audio plugin for DUT mode

*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <stream.h>
#include <print.h>
#include <stream.h> 
#include <message.h>
#include <micbias.h>
                                                                                                                    
#include "audio_plugin_if.h"
#include "audio_plugin_common.h"
#include "csr_dut_audio.h"
#include "csr_dut_audio_plugin.h"


typedef struct
{
    /*! The Audio sink in use */
    Sink audio_sink;    
    /*! The current mode */
    unsigned mode:8;
    /*! Unused */
    unsigned unused:8;
    /*! Codec Task */
    Task codec_task;
    /*! The current audio volume level*/
    uint16 volume;    
    /*! Indicates if stereo or mono */
    bool stereo;
    /*! Indicates rate of audio */
    uint32 rate;
    /*! The Tone sink in use */
    Sink tone_sink;
    /*! The current tone volume level*/
    uint16 tone_volume;
    /*! The current tone stereo flag*/
    uint16 tone_stereo;
    /*! The current tone */
    ringtone_note *tone;
    /*! The plugin parameters */
    uint16 params;
} DUT_AUDIO_T;

static DUT_AUDIO_T *DUT_AUDIO = NULL;


static void dut_audio_connect_mic_speaker(void)
{
    Sink speaker_snk;
    Source mic_source;
    common_mic_params *mic_params = NULL;
    
    CodecSetOutputGainNow(DUT_AUDIO->codec_task, 0, left_and_right_ch);
    
    if (DUT_AUDIO->params)
    {
        speaker_snk = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, (DUT_AUDIO->stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
        DUT_AUDIO->audio_sink = speaker_snk;
        PanicFalse(SinkConfigure(speaker_snk, STREAM_CODEC_OUTPUT_RATE, DUT_AUDIO->rate));
    
        mic_params = (common_mic_params *)DUT_AUDIO->params;
        mic_source = AudioPluginGetMic(AUDIO_CHANNEL_A, mic_params->mic_a.digital);
        AudioPluginSetMicRate(mic_source, mic_params->mic_a.digital, DUT_AUDIO->rate);           
        AudioPluginSetMicPio(mic_params->mic_a, TRUE);
   
        PanicFalse(StreamConnect(mic_source, speaker_snk));
    
        CodecSetOutputGainNow(DUT_AUDIO->codec_task, DUT_AUDIO->volume, left_and_right_ch);  
        
        PRINT(("DUT AUDIO: Connect Mic/Speaker vol[%d]\n", DUT_AUDIO->volume));    
    }    
}


static void dut_audio_disconnect_mic_speaker(void)
{
    if (DUT_AUDIO->audio_sink)
    {
        PRINT(("DUT AUDIO: Disconnect Mic/Speaker\n"));  
        StreamDisconnect(0, DUT_AUDIO->audio_sink);
        DUT_AUDIO->audio_sink = 0;
        
        if (DUT_AUDIO->params)
        {
            common_mic_params *mic_params = (common_mic_params *)DUT_AUDIO->params;
            AudioPluginSetMicPio(mic_params->mic_a, FALSE);
        }
    }
}


void CsrDutAudioPluginConnect(Task codec_task, uint16 volume, AUDIO_MODE_T mode, bool stereo, uint32 rate, const void * params)
{
    if (DUT_AUDIO)
    {
        /* check incase AudioDisconnect wasn't called */
        CsrDutAudioPluginDisconnect();
    }
    
    DUT_AUDIO = (DUT_AUDIO_T *)PanicUnlessMalloc(sizeof(DUT_AUDIO_T));
    
    DUT_AUDIO->volume = volume;
    DUT_AUDIO->mode = mode;
    DUT_AUDIO->codec_task = codec_task ;
    DUT_AUDIO->stereo = stereo;
    DUT_AUDIO->audio_sink = 0;
    DUT_AUDIO->tone_volume = 0;
    DUT_AUDIO->tone_stereo = 0;
    DUT_AUDIO->tone = NULL;
    DUT_AUDIO->rate = rate;
    DUT_AUDIO->params = (uint16) params;
    
    PRINT(("DUT AUDIO: CsrDutAudioPluginConnect\n")); 
    
    CsrDutAudioPluginSetMode(mode);
}


void CsrDutAudioPluginDisconnect(void)
{
    if (!DUT_AUDIO)
        Panic();
    
    PRINT(("DUT AUDIO: CsrDutAudioPluginDisconnect\n")); 
    
    dut_audio_disconnect_mic_speaker();
    CsrDutAudioPluginStopTone();
    
    free(DUT_AUDIO);
    DUT_AUDIO = NULL;
}


void CsrDutAudioPluginSetMode(AUDIO_MODE_T mode)
{
    if (!DUT_AUDIO)
        Panic();

    DUT_AUDIO->mode = mode;
    
    PRINT(("DUT AUDIO: CsrDutAudioPluginSetMode [%d]\n", mode)); 

    switch (mode)
    {
        case AUDIO_MODE_CONNECTED:
        {
            dut_audio_connect_mic_speaker();
        }
        break;
            
        default:
        {
            dut_audio_disconnect_mic_speaker();
        }
        break;
    }
}


void CsrDutAudioPluginSetVolume(uint16 volume)
{    
    if (DUT_AUDIO)
    {
        if (DUT_AUDIO->tone_sink)
        {
            PRINT(("DUT AUDIO: Set Tone Volume [%d]\n", DUT_AUDIO->tone_volume)); 
            CodecSetOutputGainNow(DUT_AUDIO->codec_task, DUT_AUDIO->tone_volume, left_and_right_ch);            
        }
        else
        {
            PRINT(("DUT AUDIO: Set Audio Volume [%d]\n", DUT_AUDIO->volume)); 
            CodecSetOutputGainNow(DUT_AUDIO->codec_task, DUT_AUDIO->volume, left_and_right_ch);
        }
    }
}

        
        
/****************************************************************************
DESCRIPTION
    plays a tone using the audio plugin    
*/
void CsrDutAudioPluginPlayTone(ringtone_note *tone, Task codec_task, uint16 tone_volume, bool stereo) 
{    
    Source lSource;
    Sink speaker_snk = NULL;
    
    if (!DUT_AUDIO || DUT_AUDIO->audio_sink)
    {
        /* tone audio should not be connected */
        SetAudioBusy(NULL);
        return;
    }
    
    CodecSetOutputGainNow(codec_task, 0, left_and_right_ch);  
    
    dut_audio_disconnect_mic_speaker();
    
    speaker_snk = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, (stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
    
    DUT_AUDIO->tone_sink = speaker_snk;
    DUT_AUDIO->tone_volume = tone_volume;
    DUT_AUDIO->tone_stereo = stereo;
    DUT_AUDIO->tone = tone;
    
    PRINT(("DUT AUDIO: Play tone, stereo[%d] sink[0x%x] vol[%d]\n", stereo, (uint16)speaker_snk, tone_volume));    
    
    PanicFalse(SinkConfigure(speaker_snk, STREAM_CODEC_OUTPUT_RATE, DUT_AUDIO->rate));
   
        /*request an indication that the tone has completed / been disconnected*/
    MessageSinkTask(speaker_snk, (TaskData*)&csr_dut_audio_plugin);
        
        /*connect the tone*/        
    lSource = StreamRingtoneSource((const ringtone_note *)tone);    
            
    PanicFalse( StreamConnectAndDispose(lSource, speaker_snk));
    
    CodecSetOutputGainNow(codec_task, tone_volume, left_and_right_ch);                
}

/****************************************************************************
DESCRIPTION
    Stop a tone from currently playing
*/
void CsrDutAudioPluginStopTone ( void ) 
{  
    PRINT(("DUT_AUDIO: Stop Tone\n"));
   
    if (DUT_AUDIO && DUT_AUDIO->tone_sink)
    {
        StreamDisconnect(0, DUT_AUDIO->tone_sink);   
        MessageSinkTask(DUT_AUDIO->tone_sink, NULL);                                 
        SinkClose(DUT_AUDIO->tone_sink);
        DUT_AUDIO->tone_sink = 0;
        PRINT(("DUT_AUDIO: Disconnect Tone\n"));
    }
}

/****************************************************************************
DESCRIPTION
    a tone has completed
    
*/
bool CsrDutAudioPluginToneComplete(void)
{
    PRINT(("DUT_AUDIO: Tone Complete\n"));
  
    CsrDutAudioPluginStopTone();
    
    /* if plugin is still connected and no other audio routed then restart tone */
    if (DUT_AUDIO && !DUT_AUDIO->audio_sink)
    {        
        return FALSE;        
    }
    return TRUE;
}


/****************************************************************************
DESCRIPTION
    repeat the tone
    
*/
void CsrDutAudioPluginRepeatTone(Task task)
{
    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_PLAY_TONE_MSG ) ; 
    
    PRINT(("DUT_AUDIO: Queue Repeat\n"));

    message->tone = DUT_AUDIO->tone;
    message->can_queue = FALSE;
    message->codec_task = DUT_AUDIO->codec_task;
    message->tone_volume = DUT_AUDIO->tone_volume;
    message->features.stereo = DUT_AUDIO->tone_stereo;
    
    MessageSendConditionally(task, AUDIO_PLUGIN_PLAY_TONE_MSG, message, (const uint16 *)AudioBusyPtr());
}
