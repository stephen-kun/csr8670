/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_voice_prompts.h
DESCRIPTION
    plugin implementation which plays audio prompts
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
#include <string.h>
#include <source.h>
#include <transform.h>
#include <i2c.h>

#include <file.h>
#include <stdio.h>
#include "audio_plugin_if.h" 
#include <kalimba.h>
#include <kalimba_standard_messages.h>

#include "audio.h"
#include "audio_plugin_if.h"
#include "csr_tone_plugin.h"
#include "csr_voice_prompts_plugin.h"
#include "csr_voice_prompts.h"
#include "csr_i2s_audio_plugin.h"

#define PROMPT_MAX_SIZE (0xffff)


typedef struct
{
    uint16                     no_prompts;
    uint16                     no_prompts_per_lang;
} voice_prompts_header;

typedef struct
{
    uint32              size;
    voice_prompts_codec decompression;
    uint16              playback_rate;
    bool                stereo;
} voice_prompt;

typedef struct 
{
    /*! The codec task to use to connect the audio*/
    Task                codec_task;
    /* */
    AudioPluginFeatures features;
    /*! VP source */
    Source              source;
    /*! Decompression to use */
    voice_prompts_codec decompression;
    /*! Playback rate */
    uint16              playback_rate;
    /*! The language */
    uint16              language;
    /*! The volume at which to play the tone */
    int16               prompt_volume;
    /*! stereo or mono */
    bool                stereo;
    /*! flag that indicates if the prompt is mixing with existing audio */
    bool                mixing;
    /*! prompt index Id. */
    uint16              prompt_id;   
    /*! If this is a tone, pointer to the ringtone_note */
    ringtone_note       *tone;   
} PHRASE_DATA_T ;

/* Decoder type to send to DSP app */
typedef enum
{
    PHRASE_NO_DECODER = 0,
    PHRASE_SBC_DECODER = 1,
    PHRASE_MP3_DECODER = 2,
    PHRASE_AAC_DECODER = 3
} PHRASE_DECODER_T;


static voice_prompts_header     header;
static PHRASE_DATA_T            *phrase_data = NULL;

#define SIZE_PROMPT_DATA   (12)

static Source csrVoicePromptsGetPrompt(voice_prompt* prompt, PHRASE_DATA_T * pData);

void CsrVoicePromptsPluginStopPhraseMixable ( void ) ;
void CsrVoicePromptsPluginStopPhraseDsp ( void ) ;

/****************************************************************************
DESCRIPTION
    helper function to determine whether voice prompt to be played is adpcm or pcm which
    can then be mixed by the other dsp applications.
*/
bool CsrVoicePromptsIsMixable(uint16 id, uint16 language, Task codec_task)
{
    Source lSource = NULL ;
    voice_prompt prompt;
    
    /* Allocate the memory */
    PHRASE_DATA_T * p_data = (PHRASE_DATA_T *) PanicUnlessMalloc(sizeof(PHRASE_DATA_T));
    
    /* Set up params */
    p_data->language      = language;
    p_data->codec_task    = codec_task;
    p_data->prompt_id     = id;
    p_data->tone          = NULL;
    
    /* initialise compression type */    
    prompt.decompression = voice_prompts_codec_none;  
    
    /* call function to get type of compression used  for this prompt */
    lSource = csrVoicePromptsGetPrompt(&prompt, p_data);
    
    /* Finished with header source now compression type has been found, close it */
    if(!SourceClose(lSource))
        Panic();
    
    free(p_data);
    p_data = NULL;

    switch (prompt.decompression)
    {
        case voice_prompts_codec_ima_adpcm:
        case voice_prompts_codec_pcm:
        case voice_prompts_codec_tone:
            return TRUE;
        default:
            return FALSE;
    }
}

static Source csrVoicePromptsGetPrompt(voice_prompt* prompt, PHRASE_DATA_T * pData)
{
    const uint8* rx_array;
    Source lSource = NULL;
    uint16 index;

    char file_name[17];

    if(!pData)
        return NULL;
        
    /* determine if this is a tone */
    if(pData->tone)
    {
        PRINT(("VP: Prompt is a tone 0x%x\n", (uint16)pData->tone));    
    
        /* update current tone playing status */
        SetTonePlaying(TRUE);
        
        prompt->size = 0;
        prompt->decompression = voice_prompts_codec_tone;
        prompt->playback_rate = 8000;
        prompt->stereo = pData->features.stereo;

        /*return the tone source*/
        return StreamRingtoneSource ( (const ringtone_note *) (pData->tone) ) ;        
    }
    
    /* Must be a prompt, work out the index of the prompt */
    index = pData->prompt_id;
    
    /* Adjust for language */
    index += (pData->language * header.no_prompts_per_lang);
    
    /* Sanity checking */
    if(index >= header.no_prompts || !prompt )
        return NULL;
    
    PRINT(("VP: Play prompt %d of %d\n", index+1, header.no_prompts));
    
    /* Get the header file name */
    sprintf(file_name, "headers/%d.idx", index);
    lSource = StreamFileSource(FileFind(FILE_ROOT, file_name, strlen(file_name)));

    /* Check source created successfully */
    if(SourceSize(lSource) < SIZE_PROMPT_DATA)
    {
        /* Finished with header source, close it */
        SourceClose(lSource);
        return NULL;
    }
    
    /* Map in header */
    rx_array = SourceMap(lSource);
    
    /* Pack data into result */
    /*    rx_array[0] not used*/
    /*    rx_array[1] index, not used */
    prompt->stereo        = rx_array[4];
    prompt->size          = ((uint32)rx_array[5] << 24) | ((uint32)rx_array[6] << 16) | ((uint16)rx_array[7] << 8) | (rx_array[8]);
    prompt->decompression = rx_array[9];
    prompt->playback_rate = ((uint16)rx_array[10] << 8) | (rx_array[11]);   
    
    /* The size of the prompt must be limited to 16 bits for I2C and SPI as the firmware traps only support a 16 bit size */
    if (prompt->size > PROMPT_MAX_SIZE)
    {
        prompt->size = PROMPT_MAX_SIZE;
        PRINT(("Prompt size adjusted to 16 bit maximum\n"));
    }
    
    /* Get the prompt file name */
    sprintf(file_name, "prompts/%d.prm", index);
    
    PRINT(("File Prompt: %s dec %X rate 0x%x stereo %u size 0x%lx \n", file_name, prompt->decompression,prompt->playback_rate,prompt->stereo,prompt->size));
    
    /* Finished with header source, close it */
    if(!SourceClose(lSource))
        Panic();
    
    return StreamFileSource(FileFind(FILE_ROOT, file_name, strlen(file_name)));
}


static const char* csrVoicePromptsGetKapFile(void)
{
    switch (phrase_data->decompression)
    {
    /* if no DSP loaded, use SBC decoder to playback variable rate PCM and tones */
    case voice_prompts_codec_tone:
    case voice_prompts_codec_sbc:
    case voice_prompts_codec_pcm: 
    case voice_prompts_codec_ima_adpcm: /* use when resampling */
        return "sbc_decoder/sbc_decoder.kap";
    case voice_prompts_codec_mp3:
        return "mp3_decoder/mp3_decoder.kap";
    case voice_prompts_codec_aac:
        return "aac_decoder/aac_decoder.kap";
    default:
        Panic();
        return NULL;
    }
}

static PHRASE_DECODER_T csrVoicePromptsDecompressionToDecoder(void)
{
    switch (phrase_data->decompression)
    {
        case voice_prompts_codec_sbc:
        case voice_prompts_codec_pcm:
        case voice_prompts_codec_ima_adpcm:
        case voice_prompts_codec_tone:
            return PHRASE_SBC_DECODER;
        case voice_prompts_codec_mp3: 
            return PHRASE_MP3_DECODER;
        case voice_prompts_codec_aac:
            return PHRASE_AAC_DECODER;
        default:
            return PHRASE_NO_DECODER;
    }
}
       


/****************************************************************************
DESCRIPTION
    Initialise indexing.
*/

void CsrVoicePromptsPluginInit ( uint16 no_prompts, uint16 no_languages )
{
    PRINT(("VP: Init %d prompts %d languages ", no_prompts, no_languages));
    header.no_prompts = no_prompts;
    header.no_prompts_per_lang = no_prompts / no_languages;
}

/****************************************************************************
DESCRIPTION
    Plays back a voice prompt once DSP has loaded
*/

void CsrVoicePromptPluginPlayDsp(kalimba_state state)
{    
    uint16 resampleRate = OUTPUT_RATE_48K/10; /* default, unless overridden below */

    /* if the dsp has not yet been loaded, load it and wait for a call back to this function */
    if(state == kalimba_idle)
    {        
        /* Find the DSP file to use */
        const char *kap_file = csrVoicePromptsGetKapFile();
        FILE_INDEX file_index = FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file));
        
        /* Load DSP */
        if (!KalimbaLoad(file_index))
            Panic();
        
        return;
    }
    
    /* Connect prompt source to kalimba */
    if ((phrase_data->decompression == voice_prompts_codec_pcm) || 
        (phrase_data->decompression == voice_prompts_codec_ima_adpcm) ||
        (phrase_data->decompression == voice_prompts_codec_tone))
    {
        /* Connect ADPCM, PCM prompts and tones to the tone mixing port */
        Sink lSink = NULL;
        Task taskdata = NULL;
        lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
        
        if(phrase_data->decompression == voice_prompts_codec_ima_adpcm)
        {   
            PanicFalse(TransformStart(TransformAdpcmDecode(phrase_data->source, lSink)));
        }
        else
        {                      
            StreamConnect(phrase_data->source, lSink);
        }                
        
        taskdata = MessageSinkTask( lSink , (TaskData*) &csr_voice_prompts_plugin);
        PRINT(("VP: sink task now %x was %x.\n",(uint16)&csr_voice_prompts_plugin,(uint16)taskdata));

        /* set the digital volume before playing the prompt, since pcm is played via the tone port there is
           no need to attenuate volume by -6dB */
        CsrVoicePromptsPluginSetVolume(phrase_data->prompt_volume, FALSE);  
    }
    else
    {   /* all other prompt codec types */
        StreamConnect(phrase_data->source, StreamKalimbaSink(0));
        /* set the digital volume before playing the prompt adjusting volume level by -6dB as not being
           passed through dsp tone port */
        CsrVoicePromptsPluginSetVolume(phrase_data->prompt_volume, TRUE);  
    }

    
    /* was the dsp loaded by the voice_prompts_plugin? */
    if(state == kalimba_loaded)
    {
        Sink lSink,rSink;    
   
        /* determine output type */
        switch(phrase_data->features.audio_output_type)
        {
            /* is the I2S required? */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {     
                /* is resampling being used? */
                if(CsrI2SMusicResamplingFrequency())
                {
                    resampleRate = CsrI2SMusicResamplingFrequency()/10;
                    /* connect the source to the I2S output  */
                    lSink = CsrI2SAudioOutputConnect(CsrI2SMusicResamplingFrequency(), phrase_data->features.stereo, StreamKalimbaSource(0), StreamKalimbaSource(1));
                }
                /* no resampling in use */
                else
                {
                    /* connect the source to the I2S output  */
                    lSink = CsrI2SAudioOutputConnect(OUTPUT_RATE_48K, phrase_data->features.stereo, StreamKalimbaSource(0), StreamKalimbaSource(1));                   
                }
                /* and set its volume level */
                CsrI2SAudioOutputSetVolume(phrase_data->features.stereo, (phrase_data->prompt_volume * 2/3), (phrase_data->prompt_volume * 2/3), FALSE);
            }
            break;
            
            /* is the output type spdif? */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                /* must be stereo for spdif output */
                lSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
                rSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
                /* configure channel to required rate */
                PanicFalse(SinkConfigure(lSink,  STREAM_SPDIF_OUTPUT_RATE, OUTPUT_RATE_48K));
                PanicFalse(SinkConfigure(rSink,  STREAM_SPDIF_OUTPUT_RATE, OUTPUT_RATE_48K));
                /* synchronise both sinks for channels A & B */
                PanicFalse(SinkSynchronise(lSink, rSink));
                /* connect dsp ports */
                PanicFalse(StreamConnect(StreamKalimbaSource(0),lSink));
                PanicFalse(StreamConnect(StreamKalimbaSource(1),rSink));                  
            }
            break;
            
            /* use the built in codec */
            default:
            {
                /* Connect PCM channel A */
                lSink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
                SinkConfigure(lSink, STREAM_CODEC_OUTPUT_RATE, OUTPUT_RATE_48K);
    
                /* Connect PCM channel B */
                if(phrase_data->features.stereo)
                {
                    rSink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                    SinkConfigure(rSink, STREAM_CODEC_OUTPUT_RATE, OUTPUT_RATE_48K);
                    PanicFalse(SinkSynchronise(lSink, rSink));
                    PanicFalse(StreamConnectAndDispose(StreamKalimbaSource(1), rSink));
                }
    
                PanicFalse(StreamConnectAndDispose(StreamKalimbaSource(0), lSink));      
            }
            break;
        }           
    }

    /* Set the playback rate */
    KalimbaSendMessage(MESSAGE_SET_SAMPLE_RATE, phrase_data->playback_rate, 0, 0, 1);
                      
    /* Set the codec in use */
    KalimbaSendMessage(MUSIC_SET_PLUGIN_MSG, csrVoicePromptsDecompressionToDecoder(), 0, 0, 0);

    if (phrase_data->decompression == voice_prompts_codec_pcm)
    {
		/* PCM specific messages */   
        /* Set that we are sending a PCM prompt in tone port */
        KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, resampleRate , 0, 0, (phrase_data->features.audio_output_type|LOCAL_FILE_PLAYBACK|PCM_PLAYBACK));
        
        /* Configure prompt playback */    
        KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, phrase_data->playback_rate , (phrase_data->stereo?PROMPT_STEREO:0)|PROMPT_ISPROMPT, 0, 0);        
        
        KalimbaSendMessage(MESSAGE_SET_CODEC_SAMPLE_RATE, OUTPUT_RATE_48K/10, 0, 0, 0);   
    }
    else if ( phrase_data->decompression == voice_prompts_codec_tone )
    {
        /* tone specific messages */   
        /* Set that we are sending a tone in tone port */
        KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, resampleRate , 0, 0, (phrase_data->features.audio_output_type|PCM_PLAYBACK));
        
        /* Configure prompt playback */    
        KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, phrase_data->playback_rate , 0, 0, 0);     

        KalimbaSendMessage(MESSAGE_SET_CODEC_SAMPLE_RATE, OUTPUT_RATE_48K/10, 0, 0, 0);           
    }
    else if ( phrase_data->decompression == voice_prompts_codec_ima_adpcm )  
    {    
        PRINT(("VP: play ADPCM with DSP\n"));
        /* Set that we are sending a ADPCM prompt in tone port */
        KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, resampleRate , 0, 0, (phrase_data->features.audio_output_type|LOCAL_FILE_PLAYBACK|PCM_PLAYBACK));
               
        KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, phrase_data->playback_rate , /*PROMPT_MONO*/PROMPT_ISPROMPT, 0, 0);   

        KalimbaSendMessage(MESSAGE_SET_CODEC_SAMPLE_RATE, OUTPUT_RATE_48K/10, 0, 0, 0);        
    }
    else
    {
        /* Set the codec sampling rate (DSP needs to know this for resampling) */
        KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, resampleRate , 0, 0, (phrase_data->features.audio_output_type|LOCAL_FILE_PLAYBACK));
        
        KalimbaSendMessage(MESSAGE_SET_CODEC_SAMPLE_RATE, phrase_data->playback_rate/10, 0, 0, 0);
    }
    
    /* Ready to go... */
    if (!KalimbaSendMessage(KALIMBA_MSG_GO, 0, 0, 0, 0))
    {
        PRINT(("VP: DSP failed to send go to kalimba\n"));
        Panic();
    }
}


/****************************************************************************
DESCRIPTION
    plays One digital number using the audio plugin    
*/

static void CsrVoicePromptsPluginPlayDigit(void) 
{
    Source lSource ;
    voice_prompt prompt;
    
    /* Get the prompt data*/
    lSource = csrVoicePromptsGetPrompt(&prompt, phrase_data);
    if(!lSource) Panic();
    
    SetAudioBusy((TaskData*) &(csr_voice_prompts_plugin));

    /* Stash the source */
    phrase_data->source = lSource;
    phrase_data->decompression = prompt.decompression;
    phrase_data->stereo = prompt.stereo;
    phrase_data->playback_rate =  (prompt.playback_rate ? prompt.playback_rate : 8000);
    phrase_data->mixing = FALSE;    /* overridden later if this prompt is mixed */
    
    SetVpPlaying(TRUE);

    /* Connect the stream to the DAC */
    switch(prompt.decompression)
    {
        case voice_prompts_codec_ima_adpcm:
        case voice_prompts_codec_none:     
        case voice_prompts_codec_tone:  
        {
#ifndef ALWAYS_RESAMPLE             
            Sink rSink = NULL;
#endif
            Sink lSink = NULL;
            Task taskdata = NULL;

            
            /* if DSP is already running, the voice prompt can be mixed with the dsp
               audio via the kalimba mixing port (3), either the CVC plugin or
               the music plugin will have already determined the output source and connected the 
               appropriate ports to the hardware, the volume will already have been set, it is not
               necessary to do it again */
            if(GetCurrentDspStatus())
            {            
                /* Configure tone or prompt playback */    
                if(prompt.decompression == voice_prompts_codec_tone)
                {
                    PRINT(("VP: play tone\n"));
                    KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, phrase_data->playback_rate , 0/*Mono Bit 0 =0, TONE BIT 1 = 0*/, 0, 0); 
                }                    
                else
                {
                    PRINT(("VP: play adpcm\n"));
                    KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, phrase_data->playback_rate , /*PROMPT_MONO*/PROMPT_ISPROMPT, 0, 0);                                  
                }
                /* stream voice prompt data to the DSP tone mixing port */                
                phrase_data->mixing = TRUE;
                lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
                PRINT(("VP: play dsp mix lSink = %x lSource = %x\n",(uint16)lSink,(uint16)lSource));
                SinkConfigure(lSink, STREAM_CODEC_OUTPUT_RATE, phrase_data->playback_rate);
                
                /* Get messages when source has finished */
                taskdata = MessageSinkTask( lSink , (TaskData*) &csr_voice_prompts_plugin);

                /* connect the kalimba port to the audio_prompt */
                if(prompt.decompression == voice_prompts_codec_ima_adpcm)
                {   
                    PanicFalse(TransformStart(TransformAdpcmDecode(lSource, lSink)));
                }
                else
                {                      
                    PanicFalse(StreamConnect(lSource, lSink)); 
                }   
                
                /* no need to set volume as host plugin has already done so */
            }
            /* not using the dsp for voice prompt mixing */
            else            
#ifdef ALWAYS_RESAMPLE
            /* Load the DSP to playback this prompt as it's needed to re-sample it, it is necessary to set the
               digital volume control using this method as DSP application will initialise to mute */
            {                   
                Task kal_task = MessageKalimbaTask( (TaskData*) &csr_voice_prompts_plugin );
                PRINT(("VP: Use DSP for ADPCM prompt\n"));
                CsrVoicePromptPluginPlayDsp((kal_task != &csr_voice_prompts_plugin) ? kalimba_idle : kalimba_ready);  
                return;                
            }
#else              
            /* Play the prompt directly without the DSP */
            {      
                /* determine output type */
                switch(phrase_data->features.audio_output_type)
                {
                    /* is the I2S required? */
                    case OUTPUT_INTERFACE_TYPE_I2S:
                    {               
                        /* connect the source to the I2S output via the adpcm decode */
                        lSink = CsrI2SAudioOutputConnectAdpcm(phrase_data->playback_rate, phrase_data->features.stereo, lSource);
                        /* Get messages when source has finished */
                        taskdata = MessageSinkTask( lSink , (TaskData*) &csr_voice_prompts_plugin);
                        /* and set its volume level */
                        CsrI2SAudioOutputSetVolume(phrase_data->features.stereo, (phrase_data->prompt_volume * 2/3), (phrase_data->prompt_volume * 2/3), FALSE);
                    }
                    break;
                    
                    /* is the output type spdif? */
                    case OUTPUT_INTERFACE_TYPE_SPDIF:
                    {
                        Source rSource;
                        /* must be stereo for spdif output */    
                        rSource = csrVoicePromptsGetPrompt(&prompt, phrase_data);
                        if(!rSource) Panic();
                        /* must be stereo for spdif output */
                        lSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
                        rSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
                        /* Get messages when source has finished */
                        taskdata = MessageSinkTask( lSink , (TaskData*) &csr_voice_prompts_plugin);
                        /* configure channel to required rate */
                        PanicFalse(SinkConfigure(lSink,  STREAM_SPDIF_OUTPUT_RATE, OUTPUT_RATE_48K));
                        PanicFalse(SinkConfigure(rSink,  STREAM_SPDIF_OUTPUT_RATE, OUTPUT_RATE_48K));
                        /* synchronise both sinks and sources for channels A & B */
                        PanicFalse(SinkSynchronise(lSink, rSink));
                        PanicFalse(SourceSynchronise(lSource, rSource));
                        /* connect the kalimba port to the audio_prompt */
                        if(prompt.decompression == voice_prompts_codec_ima_adpcm)
                        {
                            PanicFalse(TransformStart(TransformAdpcmDecode(lSource, lSink)));
                            PanicFalse(TransformStart(TransformAdpcmDecode(rSource, rSink)));
                        }
                        else
                        {
                            PanicFalse(StreamConnect(lSource, lSink)); 
                            PanicFalse(StreamConnect(rSource, rSink)); 
                        }
                    }
                    break;
                
                    /* DAC output */
                    default:
                    {
                        /* Configure port 0 to be routed to internal codec A (and B), with a sample rate of 8k or configured rate. */
                        lSink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, (phrase_data->features.stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));

                        PRINT(("VP: play lSink = %x, stereo = %x\n",(uint16)lSink,phrase_data->features.stereo));
                        
                        SinkConfigure(lSink, STREAM_CODEC_OUTPUT_RATE, phrase_data->playback_rate);
                        
                        /* Get messages when source has finished */
                        taskdata = MessageSinkTask( lSink , (TaskData*) &csr_voice_prompts_plugin);
                        
                        /* connect the kalimba port to the audio_prompt */
                        if(prompt.decompression == voice_prompts_codec_ima_adpcm)
                        {   
                            PanicFalse(TransformStart(TransformAdpcmDecode(lSource, lSink)));
                        }
                        else
                        {                      
                            PanicFalse(StreamConnect(lSource, lSink)); 
                        }

                        /*Set the output Gain immediately - scaled down to (roughly) match tone volume */
                        CodecSetOutputGainNow(phrase_data->codec_task, phrase_data->prompt_volume * 2/3, (phrase_data->features.stereo ? left_and_right_ch : left_ch) );
                    }
                    break;
                }    
            }                
 #endif               
        }
        break;
        
        case voice_prompts_codec_pcm:        
        {    
            Sink lSink = NULL;
            Task taskdata = NULL;
            
            /* determine whether the prompt is being played as a mixed with audio via the dsp, if the dsp is being
               used for audio mixing there is no need to set the volume as this will already have been performed 
               plugin used to load the dsp for audio processing */            
            if(GetCurrentDspStatus())
            {
                /* store that this PCM prompt is mixing */
                phrase_data->mixing = TRUE;
                
                /* stream voice prompt data to the DSP tone mixing port */                
                lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
                PRINT(("VP: play dsp mix lSink = %x lSource = %x\n",(uint16)lSink,(uint16)lSource));
                SinkConfigure(lSink, STREAM_CODEC_OUTPUT_RATE, phrase_data->playback_rate);                               
                
                /* Get messages when source has finished */
                taskdata = MessageSinkTask( lSink , (TaskData*) &csr_voice_prompts_plugin);

                PRINT(("VP: sink task now %x was %x\n",(uint16)&csr_voice_prompts_plugin,(uint16)taskdata));
                
                /* Configure PCM prompt playback */    
                KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, phrase_data->playback_rate , (phrase_data->stereo?PROMPT_STEREO:0)|PROMPT_ISPROMPT, 0, 0);        
                
                /* Connect source to PCM */
                PanicFalse(StreamConnect(lSource, lSink));
            }
            /* Load the DSP to play PCM audio prompt  */
            else
            {
                Task kal_task = MessageKalimbaTask( (TaskData*) &csr_voice_prompts_plugin );
                PRINT(("VP: Use DSP for PCM prompt\n"));
                CsrVoicePromptPluginPlayDsp((kal_task != &csr_voice_prompts_plugin) ? kalimba_idle : kalimba_ready);            
            }
        }
        break;

        case voice_prompts_codec_sbc:
        case voice_prompts_codec_mp3:
        case voice_prompts_codec_aac:     
        {
            /* for sbc, aac or mp3 voice prompts it is necessary to load the dsp with the appropriate application
               to perform the decoding */
            Task kal_task = MessageKalimbaTask( (TaskData*) &csr_voice_prompts_plugin );
            PRINT(("VP: Play DSP prompt\n"));
            CsrVoicePromptPluginPlayDsp((kal_task != &csr_voice_prompts_plugin) ? kalimba_idle : kalimba_ready);
        }
        break;

        default:
            PRINT(("VP: Codec Invalid\n"));
            Panic();
        break;
    }

}

/****************************************************************************
DESCRIPTION
    plays a number phrase using the audio plugin    
*/

void CsrVoicePromptsPluginPlayPhrase (uint16 id , uint16 language, Task codec_task , uint16 prompt_volume , AudioPluginFeatures features)
{
    if(phrase_data != NULL)
        Panic();
    
    PRINT(("VP: Play Phrase:\n"));
    
    /* Allocate the memory */
    phrase_data = (PHRASE_DATA_T *) PanicUnlessMalloc(sizeof(PHRASE_DATA_T));
    memset(phrase_data,0,sizeof(PHRASE_DATA_T));
    
    /* Set up params */
    phrase_data->language      = language;
    phrase_data->codec_task    = codec_task;
    phrase_data->prompt_volume = prompt_volume;
    phrase_data->features      = features;
    phrase_data->prompt_id     = id;
    phrase_data->mixing        = FALSE; /* currently unknown so set to false */
    phrase_data->tone          = NULL;  /* not a tone */
    
    MessageCancelAll((TaskData*) &csr_voice_prompts_plugin, MESSAGE_STREAM_DISCONNECT );
    MessageCancelAll((TaskData*) &csr_voice_prompts_plugin, MESSAGE_FROM_KALIMBA);
    
    CsrVoicePromptsPluginPlayDigit(); 
    
    SetVpPlaying(TRUE);
}

/****************************************************************************
DESCRIPTION
    plays a tone using the audio plugin    
*/
void CsrVoicePromptsPluginPlayTone ( TaskData *task, ringtone_note * tone, Task codec_task, uint16 tone_volume, AudioPluginFeatures features)
{
    if(tone == NULL)
        Panic();
    
    PRINT(("VP: Play tone:\n"));
    
    /* Allocate the memory */
    phrase_data = (PHRASE_DATA_T *) PanicUnlessMalloc(sizeof(PHRASE_DATA_T));
    memset(phrase_data,0,sizeof(PHRASE_DATA_T));
    
    /* Set up params */
    phrase_data->language      = 0;
    phrase_data->codec_task    = codec_task;
    phrase_data->prompt_volume = tone_volume;
    phrase_data->features      = features;
    phrase_data->prompt_id     = 0; /* not a prompt */
    phrase_data->mixing        = FALSE; /* currently unknown so set to false */
    phrase_data->tone          = tone;
    
    MessageCancelAll((TaskData*) &csr_voice_prompts_plugin, MESSAGE_STREAM_DISCONNECT );
    MessageCancelAll((TaskData*) &csr_voice_prompts_plugin, MESSAGE_FROM_KALIMBA);
    
    CsrVoicePromptsPluginPlayDigit(); 
    
    SetVpPlaying(TRUE);  
}

/****************************************************************************
DESCRIPTION
    Stop prompt where DSP has not been loaded by the plugin, e.g. (adpcm or pcm) 
    Prompt is either mixing in an existing DSP app or not using the DSP.
*/
void CsrVoicePromptsPluginStopPhraseMixable ( void ) 
{
    Sink lSink=NULL;
    Task taskdata = NULL;
    
    /* Check for DSP mixing */
    if(GetCurrentDspStatus())
    {
        lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
        /* reset the volume levels of the dsp plugin */
        if(GetAudioPlugin())           	    
            MessageSend( GetAudioPlugin(), AUDIO_PLUGIN_RESET_VOLUME_MSG, 0 ) ;
    }
    else    /* Must be ADPCM not mixing */
    {
        switch(phrase_data->features.audio_output_type)
        {
            /* is the I2S required? */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {               
                CsrI2SAudioOutputDisconnect( phrase_data->features.stereo);  
            }
            break;
            
            /* spdif output? */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                Sink rSink = NULL;
                                
                /* obtain source to SPDIF hardware and disconnect it */
                lSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
                rSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
                StreamDisconnect(0, lSink);
                StreamDisconnect(0, rSink);
                SinkClose(lSink);
                SinkClose(rSink);
            }
            break;
            
            /* use built in codec */
            default:
            {
                lSink = StreamAudioSink(AUDIO_HARDWARE_CODEC,AUDIO_INSTANCE_0, (phrase_data->features.stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
                /* Disconnect PCM source/sink */
                StreamDisconnect(StreamSourceFromSink(lSink), lSink); 
            }
        }
    }    
    /* close sink and cancel any messages if valid */
    if(lSink)
    {
        /* Cancel all the messages relating to VP that have been sent */
        taskdata = MessageSinkTask(lSink, NULL);
        SinkClose(lSink);
    }
    PRINT(("VP: SinkTask now NULL was %x\n",(uint16)taskdata));
    MessageCancelAll((TaskData*) &csr_voice_prompts_plugin, MESSAGE_STREAM_DISCONNECT);
}

/****************************************************************************
DESCRIPTION
    Stop dsp phrase playing where VP plugin has loaded the DSP
*/
void CsrVoicePromptsPluginStopPhraseDsp ( void ) 
{
    Sink lSink=NULL;

    /* Cancel all the messages relating to VP that have been sent */
    (void)MessageKalimbaTask(NULL);
    MessageCancelAll((TaskData*) &csr_voice_prompts_plugin, MESSAGE_FROM_KALIMBA);
    
    /* Disconnect PCM sources/sinks */
    switch(phrase_data->features.audio_output_type)
    {
       /* is the I2S required? */
        case OUTPUT_INTERFACE_TYPE_I2S:
        {
            CsrI2SAudioOutputDisconnect( phrase_data->features.stereo);              
        }
        break;
        
        /* spdif output */
        case OUTPUT_INTERFACE_TYPE_SPDIF:
        {
            Sink rSink = NULL;
                            
            /* obtain source to SPDIF hardware and disconnect it */
            lSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
            rSink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
            StreamDisconnect(0, lSink);
            StreamDisconnect(0, rSink);
            SinkClose(lSink);
            SinkClose(rSink);
        }
        break;
        
        /* DAC output */        
        default:
        {
            lSink = StreamAudioSink(AUDIO_HARDWARE_CODEC,AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
            StreamDisconnect(StreamSourceFromSink(lSink), lSink); 
            SinkClose(lSink);
            if(phrase_data->features.stereo)
            {
                lSink = StreamAudioSink(AUDIO_HARDWARE_CODEC,AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                StreamDisconnect(StreamSourceFromSink(lSink), lSink); 
                SinkClose(lSink);
            }           
        }
        break;
    }
    /* PCM connected to kalimba, make sure prompt source is disconnected */
    StreamDisconnect(phrase_data->source, NULL);
    KalimbaPowerOff();
}

/****************************************************************************
DESCRIPTION
    Stop a prompt from currently playing
*/
void CsrVoicePromptsPluginStopPhrase ( void ) 
{
    bool isTone;
    
    if(!phrase_data)
        Panic();
    
    /* store if this is a tone */
    isTone = (phrase_data->decompression == voice_prompts_codec_tone);        
        
    PRINT(("VP: Terminated\n"));
                
    if(phrase_data->mixing)
    {
        /* If DSP already loaded and the prompt was mixed */         
        CsrVoicePromptsPluginStopPhraseMixable();
    }
    else
    {
        /* DSP not previously loaded or the prompt was not mixable type*/          
        CsrVoicePromptsPluginStopPhraseDsp();        
    }           
    
    /* Make sure prompt source is disposed */
    if(SourceIsValid(phrase_data->source))
        StreamDisconnect(phrase_data->source, NULL);
    
    /* Tidy up */
    free(phrase_data);
    phrase_data = NULL;
    SetAudioBusy(NULL) ;
    SetVpPlaying(FALSE);
    
    if(isTone)
        SetTonePlaying(FALSE);
}


/****************************************************************************
DESCRIPTION
    Set the digital volume control is applicable
*/
void CsrVoicePromptsPluginSetVolume (int16 volume, bool minus_6_db) 
{
    AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T VolumeMsg;
    
    /* set a default for DAC gain to allow tones to be heard before volume is set */
    VolumeMsg.system_gain = CODEC_STEPS; 
    
    /* limit tones volume to 0dB */    
    if(volume > CODEC_STEPS) volume = CODEC_STEPS;    
    VolumeMsg.tones_gain = (MINIMUM_DIGITAL_VOLUME_80dB + (((0 - MINIMUM_DIGITAL_VOLUME_80dB) * volume)/CODEC_STEPS)); /* set the initial tones volume level */    
    /* if required subtract 6dB from the volume */
    if(minus_6_db)
        VolumeMsg.tones_gain += DSP_VOICE_PROMPTS_LEVEL_ADJUSTMENT;
    VolumeMsg.master_gain = VolumeMsg.tones_gain; 
    VolumeMsg.trim_gain_left = 0; /* 0dB */
    VolumeMsg.trim_gain_right = 0; /* 0dB */
    VolumeMsg.device_trim_master = 0;
    VolumeMsg.device_trim_slave = 0;
    VolumeMsg.volume_type = DSP_VOLUME_CONTROL; 
    /* i2s output to use external volume control via the i2s device itself */
    if(phrase_data->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
        VolumeMsg.volume_type = EXTERNAL_VOLUME_CONTROL; 
        
    /* if user has requested DAC volume control */
    if((VolumeMsg.volume_type == DAC_VOLUME_CONTROL)||VolumeMsg.volume_type == MIXED_VOLUME_CONTROL)
    {
        /* convert dB master volume to DAC based system volume */
        volume = (CODEC_STEPS + (VolumeMsg.master_gain/DB_TO_DAC));
        /* DAC gain only goes down to -45dB, dsp volume control goes to -60dB */
        if(volume <0) volume =0;
        /* set system gain which will in turn be used to set the DAC gain via dsp message */
        VolumeMsg.system_gain = volume;
        /* set the master volume to full scale */
        VolumeMsg.master_gain = MAXIMUM_DIGITAL_VOLUME_0DB;
        /* set dsp volume levels */
        KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16 *)&VolumeMsg);
        /* set DAC gain */
        CodecSetOutputGainNow(phrase_data->codec_task, volume, left_and_right_ch);

        PRINT(("DSP DAC Gains: System Gain = %d Master Gain = %d\n", VolumeMsg.system_gain, VolumeMsg.master_gain));
    }
    /* volume scheme that allows external devices such as an I2S amplifier which allow volume control
       by I2C commands to make use of the increased volume resolution settings of the digital volume control
       configuration */
    else if (VolumeMsg.volume_type == EXTERNAL_VOLUME_CONTROL)
    {   
        /* Full external volume control */
        PRINT(("DSP Ext Vol:  System = %d  Master = %d  Left = %d  Right = %d  TrimM = %d  TrimS = %d\n", VolumeMsg.system_gain, VolumeMsg.master_gain,  VolumeMsg.trim_gain_left, VolumeMsg.trim_gain_right, VolumeMsg.device_trim_master, VolumeMsg.device_trim_slave));
           
        /* for I2S output that supports volume control by I2C interface, send the dB value
           of the master gain +_ device trims to I2S plugin */
        if(phrase_data->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
        {
            PRINT(("CsrI2SAudioOutputSetVolume\n"));
            CsrI2SAudioOutputSetVolume(phrase_data->features.stereo, (VolumeMsg.master_gain + VolumeMsg.trim_gain_left), (VolumeMsg.master_gain + VolumeMsg.trim_gain_right), TRUE);
        }
        /* built in audio output hardware */
        else if(phrase_data->features.audio_output_type == OUTPUT_INTERFACE_TYPE_SPDIF)
        {     
            /* add some form of extra codec volume control here for SPDIF output if required */
        }
        
        /* DSP needs to be set to pass audio un-attenuated. 
           Tones are mixed and might want to be attenuated.
           System volume can be used to drive on-board DACs, if required */
        VolumeMsg.master_gain = MAXIMUM_DIGITAL_VOLUME_0DB;
        VolumeMsg.trim_gain_left = 0;
        VolumeMsg.trim_gain_right = 0;
        KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16 *)&VolumeMsg);
        /* MUSIC_CODEC_MSG will arrive from DSP and be a suitable point to apply any on-board DAC gains as well as drive external amp */
    }
    /* dsp only volume control */
    else
    {
        PRINT(("DSP Dig Vol:  System = %d  Master = %d  Tone = %d Left = %d  Right = %d  TrimM = %d  TrimS = %d\n", VolumeMsg.system_gain, VolumeMsg.master_gain, VolumeMsg.tones_gain, VolumeMsg.trim_gain_left, VolumeMsg.trim_gain_right, VolumeMsg.device_trim_master, VolumeMsg.device_trim_slave));

        /* for I2S output that supports volume control by I2C interface, send the dB value
           of the master gain +_ device trims to I2S plugin */
        if(phrase_data->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
        {
            PRINT(("CsrI2SAudioOutputSetVolume\n"));
            CsrI2SAudioOutputSetVolume(phrase_data->features.stereo, VolumeConvertDACGainToDB(VolumeMsg.system_gain), VolumeConvertDACGainToDB(VolumeMsg.system_gain), TRUE);
        }         
        
        /* set dsp volume levels */
        KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16 *)&VolumeMsg);

        /* set the DAC gain */
        CodecSetOutputGainNow(phrase_data->codec_task, VolumeMsg.system_gain, left_and_right_ch);
    }
}
