/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_audio_prompts.c
    
DESCRIPTION
    module responsible for audio (voice) prompts
    
*/

#include "sink_private.h"
#include "sink_debug.h"
#include "sink_audio_prompts.h"
#include "sink_events.h"
#include "sink_tones.h"
#include "sink_statemanager.h"
#include "sink_pio.h"
#include "vm.h"


#include <stddef.h>
#include <csrtypes.h>
#include <audio.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <partition.h>
#include <csr_tone_plugin.h> 
#include <csr_voice_prompts_plugin.h>

#ifdef DEBUG_AUDIO_PROMPTS
    #define PROMPTS_DEBUG(x) DEBUG(x)
#else
    #define PROMPTS_DEBUG(x) 
#endif


/****************************************************************************
NAME
    AudioPromptPlay
    
DESCRIPTION
    Conditionally call text-to-speech plugin
*/
void AudioPromptPlay(Task plugin, uint16 id, bool can_queue, bool override)
{
    if (theSink.audio_prompts_enabled)
    {
        /* turn on audio amp */
        PioSetPio ( theSink.conf1->PIOIO.pio_outputs.DeviceAudioActivePIO , pio_drive, TRUE) ;
        /* start check to turn amp off again if required */ 
        MessageSendLater(&theSink.task , EventSysCheckAudioAmpDrive, 0, 1000);    
        
#ifdef ENABLE_SQIFVP        
        /* If using multiple partitions for the voice prompt langages, mount the relevant partiton if required */

        /* find if the partition for this language is mounted */
        if (!((1<<theSink.audio_prompt_language) & theSink.rundata->partitions_mounted))
        {
            /* Mount the partition for this prompt */
            PROMPTS_DEBUG(("AudioPromptPlay mount SQIF partition %u (0x%x)\n", theSink.audio_prompt_language, theSink.rundata->partitions_mounted));
            if(!PartitionMountFilesystem(PARTITION_SERIAL_FLASH, theSink.audio_prompt_language , PARTITION_LOWER_PRIORITY))
                Panic();
            
            theSink.rundata->partitions_mounted |= (1<<theSink.audio_prompt_language);
            PROMPTS_DEBUG(("AudioPromptPlay SQIF partitions now mounted 0x%x\n", theSink.rundata->partitions_mounted ));
        }
#endif
        
        PROMPTS_DEBUG(("AudioPromptPlay %d  [lang:%u][q:%u][o.r.:%u]\n", id, theSink.audio_prompt_language,can_queue,override));
        AudioPlayAudioPrompt(plugin, id, theSink.audio_prompt_language, can_queue,
                     theSink.codec_task, TonesGetToneVolume(FALSE), theSink.conf2->audio_routing_data.PluginFeatures, override, &theSink.task);
    }
}


/****************************************************************************
NAME 
DESCRIPTION
RETURNS    
*/

void AudioPromptConfigure( uint8 size_index )
{
    PROMPTS_DEBUG(("Setup AP Indexing: %d prompts\n",size_index));
    AudioVoicePromptsInit((TaskData *)&csr_voice_prompts_plugin, size_index, theSink.num_audio_prompt_languages);
}

/****************************************************************************
NAME 
DESCRIPTION
RETURNS    
*/
bool AudioPromptPlayEvent ( sinkEvents_t event )
{  
    uint16 lEventIndex = event;
	uint16 state_mask  = 1 << stateManagerGetState();
    audio_prompts_config_type* ptr  = NULL;
	TaskData * task    = NULL;
    bool event_match   = FALSE;
    
    if(theSink.conf4)
    {
        ptr = theSink.conf4->audioPromptEvents;
    }
    else
    {
        /* no config */
        return FALSE;
    }
 
#ifdef ENABLE_SOUNDBAR
	/* In Limbo for sound bar build, playing audio prompts may cause panic if I2S amplifier is powered down by PIO */
    if(stateManagerGetState() == deviceLimbo)
    {
        /* If sound bar I2S amplifier shut down is managed by PIO, first check the logic state of amplifier power pin */
        if((theSink.conf2->audio_routing_data.PluginFeatures.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
            &&(theSink.features.AmplifierShutDownByPIO))
     	{
            /* Check configuration for AMP pio drive */
            if(theSink.conf1->PIOIO.pio_outputs.PowerOnPIO != NO_PIO)
            {
				/* Do not attempt to play audio prompts through I2S if amplifier is shut down already,
				otherwise, I2C comms will fail and cause panic */
                if(theSink.audioAmpPowerPin != TRUE)
                
                    return FALSE;
            }
        }
    }
#endif
    
    task = (TaskData *) &csr_voice_prompts_plugin;

    /* While we have a valid Audio Prompt event */
    while(ptr->prompt_id != AUDIO_PROMPT_NOT_DEFINED)
    {           
        /* Play Audio Prompt if the event matches and we're not in a blocked state or in streaming A2DP state */
        if((ptr->event == lEventIndex) && 
           ((ptr->state_mask & state_mask) && 
           (!(ptr->sco_block && theSink.routed_audio)||(state_mask & (1<<deviceA2DPStreaming)))))
        {
            PROMPTS_DEBUG(("AP: EvPl[%x][%x][%x][%x][%x]\n", event, lEventIndex, ptr->event, ptr->prompt_id,  ptr->cancel_queue_play_immediate )) ;
            event_match = TRUE;
            switch(event)
            {
                case EventSysMuteReminder:
                case EventSysRingtone1:
                case EventSysRingtone2:
                
                    /* never queue mute reminders to protect against the case that the prompt is longer 
                    than the mute reminder timer */
       	            AudioPromptPlay(task, (uint16) ptr->prompt_id, FALSE, ptr->cancel_queue_play_immediate);
                break;
                default:
                   AudioPromptPlay(task, (uint16) ptr->prompt_id, TRUE, ptr->cancel_queue_play_immediate);
                   
                   /* If the event is a power off, then there is no need to connect an audio plugin again after the prompt */
                   if((GetAudioPlugin()!= task)&&(event == EventUsrPowerOff))
                   {
                       MessageCancelAll(GetAudioPlugin(),AUDIO_PLUGIN_CONNECT_MSG);
                   }                   
                 break;
            }   
        }
        ptr++;
    }
    return event_match;
} 

/****************************************************************************
NAME 
    AudioPromptPlayNumString
DESCRIPTION
    Play a numeric string using the Audio Prompts plugin
RETURNS    
*/

void AudioPromptPlayNumString(uint16 size_num_string, uint8* num_string)
{
    if(size_num_string)
    {
        uint8 * pData = num_string;
        uint8 i;        

        /* check each character in the string is a numeric character */
        for(i=0;i<size_num_string;i++)
        {                    
            /* Check for non-numeric characters */
            if(*pData >= 0x30 || *pData <= 0x39)
            {
                PROMPTS_DEBUG(("AP: PlayDigit[%x]\n", pData[i]- 0x30 )) ;
                
                switch (pData[i] - 0x30)
                {
                    /* Send event corresponding to the digit, assign audio prompts to these
                       events in the normal manner */
                    case 0:
                        MessageSend(&theSink.task, EventSysToneDigit0, 0);
                        break;
                    case 1:
                        MessageSend(&theSink.task, EventSysToneDigit1, 0);
                        break;                    
                    case 2:
                        MessageSend(&theSink.task, EventSysToneDigit2, 0);
                        break;
                    case 3:
                        MessageSend(&theSink.task, EventSysToneDigit3, 0);
                        break;
                    case 4:
                        MessageSend(&theSink.task, EventSysToneDigit4, 0);
                        break;
                    case 5:
                        MessageSend(&theSink.task, EventSysToneDigit5, 0);
                        break;
                    case 6:
                        MessageSend(&theSink.task, EventSysToneDigit6, 0);
                        break;
                    case 7:
                        MessageSend(&theSink.task, EventSysToneDigit7, 0);
                        break;
                    case 8:
                        MessageSend(&theSink.task, EventSysToneDigit8, 0);
                        break;
                    case 9:
                        MessageSend(&theSink.task, EventSysToneDigit9, 0);
                        break;   
                    default:
                        ;
                }
            }                    
        }
    }
}

/****************************************************************************
NAME 
    AudioPromptPlayNumber
DESCRIPTION
    Play a uint32 using the Audio prompt plugin
RETURNS    
*/

void AudioPromptPlayNumber(uint32 number)
{
    char num_string[7];
    sprintf(num_string, "%06ld",number);
    AudioPromptPlayNumString(strlen(num_string), (uint8*)num_string);
}

/****************************************************************************
NAME 
DESCRIPTION
RETURNS    
*/

bool AudioPromptPlayCallerNumber( const uint16 size_number, const uint8* number ) 
{
	if(theSink.features.VoicePromptNumbers)
    {
        if(theSink.RepeatCallerIDFlag && size_number > 0) 
        { 
            theSink.RepeatCallerIDFlag = FALSE;
            AudioPromptPlayNumString(size_number, (uint8*)number);
            return TRUE;
        }
    }

    return FALSE;
}

/****************************************************************************
NAME 
DESCRIPTION
RETURNS    
*/
bool AudioPromptPlayCallerName( const uint16 size_name, const uint8* name ) 
{
#ifdef TEXT_TO_SPEECH_NAMES
	TaskData * task = (TaskData *) &INSERT_TEXT_TO_SPEECH_PLUGIN_HERE;
    
	if(size_name > 0) 
	{
        /* Hook point for Text to speech synthesizer */
        Panic();
	}
#endif
    return FALSE;
}

/****************************************************************************
NAME    
    AudioPromptTerminate
    
DESCRIPTION
  	function to terminate a Audio Prompt prematurely.
    
RETURNS
    
*/
void AudioPromptTerminate( void )
{
    TaskData * task = (TaskData *) &csr_voice_prompts_plugin;

    /* Do nothing if Audio Prompt Terminate Disabled */
    if(!theSink.features.DisableAudioPromptTerminate)
    {
        PROMPTS_DEBUG(("PROMPTS: Terminate prompts\n")) ;
        
        /* Make sure we cancel any pending Audio Prompts */
        MessageCancelAll(task, AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG);
        /* Cancel any digits that maybe pending */
        MessageCancelAll(task,EventSysToneDigit0);
        MessageCancelAll(task,EventSysToneDigit1);
        MessageCancelAll(task,EventSysToneDigit2);
        MessageCancelAll(task,EventSysToneDigit3);
        MessageCancelAll(task,EventSysToneDigit4);
        MessageCancelAll(task,EventSysToneDigit5);
        MessageCancelAll(task,EventSysToneDigit6); 
        MessageCancelAll(task,EventSysToneDigit7);        
        MessageCancelAll(task,EventSysToneDigit8);        
        MessageCancelAll(task,EventSysToneDigit9);        
        /* Stop the current Audio Prompt */
	    AudioStopAudioPrompt( task ) ;
    }
}  
      
/****************************************************************************
NAME    
    AudioPromptSelectLanguage
    
DESCRIPTION
  	function to select a audio prompt language.
    
RETURNS
    
*/
void AudioPromptSelectLanguage( void )
{
#ifdef ENABLE_SQIFVP     
    uint16 current_lang = theSink.audio_prompt_language;
#endif    
    uint16 delay = theSink.conf1->timeouts.LanguageConfirmTime_s;

#ifdef ENABLE_SQIFVP  
    /* if using Multiple partitions in SQIF for voice prompts make sure we choose one with prompts in it */
    do
    {
        theSink.audio_prompt_language++;
	    if(theSink.audio_prompt_language >= theSink.num_audio_prompt_languages)
            theSink.audio_prompt_language = 0;   
        
        PROMPTS_DEBUG(("AP: Select language [%u][%u][%u][0x%x]\n", theSink.audio_prompt_language,current_lang, theSink.num_audio_prompt_languages,theSink.rundata->partitions_free )) ;
    }
    while (((1<<theSink.audio_prompt_language) & theSink.rundata->partitions_free) && (theSink.audio_prompt_language != current_lang));

#else    
    theSink.audio_prompt_language++;
	if(theSink.audio_prompt_language >= theSink.num_audio_prompt_languages)
        theSink.audio_prompt_language = 0;
    
    PROMPTS_DEBUG(("AP: Select language [%u]\n", theSink.audio_prompt_language )) ;
#endif

    if(delay)
    {
        MessageCancelAll(&theSink.task, EventSysStoreAudioPromptLanguage);
        MessageSendLater(&theSink.task, EventSysStoreAudioPromptLanguage, 0, D_SEC(delay));
    }
}

