/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_simple_text_to_speech_plugin.c
DESCRIPTION
    an audio plugin
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <print.h>
#include <stream.h> /*for the ringtone_note*/
#include <string.h>
#include "audio_plugin_if.h" /*the messaging interface*/
#include "csr_voice_prompts_plugin.h"
#include "csr_voice_prompts.h"

/* Messages from DSP */
#define MUSIC_READY_MSG           (0x1000)
#define MUSIC_SETMODE_MSG         (0x1001)
#define MUSIC_VOLUME_MSG          (0x1002)
#define MUSIC_CODEC_MSG           (0x1006)
#define MUSIC_TONE_END            (0x1080)
#define MUSIC_LOADPARAMS_MSG      (0x1012)

/* DSP message structure */
typedef struct
{
    uint16 id;
    uint16 a;
    uint16 b;
    uint16 c;
    uint16 d;
} DSP_REGISTER_T;

/*the local kalimba message handling function*/
static void handleKalimbaMessage (Task task , Message message);

/*the task message handler*/
static void message_handler (Task task, MessageId id, Message message);

/*the local message handling functions*/
static void handleAudioMessage (Task task , MessageId id, Message message);
static void handleInternalMessage (Task task , MessageId id, Message message);
    
/*the plugin task*/
const TaskData csr_voice_prompts_plugin = { message_handler };

/****************************************************************************
DESCRIPTION
    The main task message handler
*/
static void message_handler ( Task task, MessageId id, Message message ) 
{
    if ( (id >= AUDIO_DOWNSTREAM_MESSAGE_BASE ) && (id <= AUDIO_DOWNSTREAM_MESSAGE_TOP) )
    {
        handleAudioMessage (task , id, message ) ;
    }
    else if (id == MESSAGE_FROM_KALIMBA)
    {
        handleKalimbaMessage (task , message ) ;
    }
    else
    {
        handleInternalMessage (task , id , message ) ;
    }
}    

/****************************************************************************
DESCRIPTION

    messages from the audio library are received here. 
    and converted into function calls to be implemented in the 
    plugin module
*/ 
static void handleAudioMessage ( Task task , MessageId id, Message message )     
{
    switch (id)
    {
        case (AUDIO_PLUGIN_VOICE_PROMPTS_INIT_MSG ):
        {
            AUDIO_PLUGIN_VOICE_PROMPTS_INIT_MSG_T * init_message = (AUDIO_PLUGIN_VOICE_PROMPTS_INIT_MSG_T *)message;
            CsrVoicePromptsPluginInit(init_message->no_prompts, init_message->no_languages);
        }
        break;
        
        case (AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG ):
        {
            AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG_T * prompt_message = (AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG_T *)message ;
                           
            /* if the audio is currently busy then queue this audio prompt request, or if the audio plugin is in an 'about to be loaded state', queue until it is
                                     loaded and running */
            if ((IsAudioBusy())||(GetCurrentDspStatus() && (GetCurrentDspStatus() != DSP_RUNNING)))
            {    
                if ( prompt_message->can_queue) 
                {                
                    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG) ; 
                    memmove(message, prompt_message, sizeof(AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG_T));
                    MessageSendConditionally ( task , AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG, message ,(const uint16 *)AudioBusyPtr() ) ;
                    PRINT(("VP:Queue\n")); 
                }
            }
            else
            {
                CsrVoicePromptsPluginPlayPhrase ( prompt_message->id, prompt_message->language, 
                                                  prompt_message->codec_task, prompt_message->ap_volume, prompt_message->features);
                PRINT(("VP:start\n"));
            } 
        }
        break ;
        
        case (AUDIO_PLUGIN_STOP_AUDIO_PROMPT_MSG ):
        {
            if(IsAudioBusy()) 
            {
                CsrVoicePromptsPluginStopPhrase() ;
            }
        }
        break;
        
#ifdef ALWAYS_RESAMPLE        
        /* this plugin only handles tones when it's needed to re-sample them */
		case (AUDIO_PLUGIN_PLAY_TONE_MSG ):
		{
			AUDIO_PLUGIN_PLAY_TONE_MSG_T * tone_message = (AUDIO_PLUGIN_PLAY_TONE_MSG_T *)message ;
			
			if (IsAudioBusy()) 
			{	
				if ( tone_message->can_queue) /*then re-queue the tone*/
				{				
					MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_PLAY_TONE_MSG ) ; 
					
					message->tone        = tone_message->tone       ;
					message->can_queue   = tone_message->can_queue  ;
					message->codec_task  = tone_message->codec_task ;
					message->tone_volume = tone_message->tone_volume;
					message->features    = tone_message->features   ;
	
					PRINT(("VP: tone Q\n"));
					
					MessageSendConditionally ( task , AUDIO_PLUGIN_PLAY_TONE_MSG, message ,(const uint16 *)AudioBusyPtr() ) ;			
				}
			}
			else
			{			
				PRINT(("VP:tone start\n"));				
                SetAudioBusy((TaskData*) task);    
        		CsrVoicePromptsPluginPlayTone (task, tone_message->tone, tone_message->codec_task, tone_message->tone_volume, tone_message->features) ;		     				
			}
							     
		}
		break ;        
        
		case (AUDIO_PLUGIN_STOP_TONE_MSG ):
		{
			if (IsAudioBusy())
			{                
                CsrVoicePromptsPluginStopPhrase() ;
                SetAudioBusy( NULL );   
			}
		}
		break ;		        
#endif        
        default:
            /*other messages do not need to be handled by the voice prompts plugin*/
        break ;
    }
}

/****************************************************************************
DESCRIPTION
    kalimba messages to the task are handled here
*/ 
static void handleKalimbaMessage ( Task task , Message message )
{
    const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
    PRINT(("handleKalimbaMessage: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));
    
    switch ( m->id ) 
    {
        case MUSIC_READY_MSG:
        {
            PRINT(("VP: KalMsg MUSIC_READY_MSG\n"));
            CsrVoicePromptPluginPlayDsp(kalimba_loaded);
        }
        break;
        
        case MUSIC_CODEC_MSG:
        break;
        
        case MUSIC_TONE_END:
        {
            PRINT(("VP: KalMsg MUSIC_TONE_END\n"));
            if(IsAudioBusy() && (IsAudioBusy() == (TaskData*) &csr_voice_prompts_plugin))
            {
                MessageCancelAll ((TaskData*)IsAudioBusy(), AUDIO_PLUGIN_STOP_AUDIO_PROMPT_MSG ) ;
                MessageSend( (TaskData*) &csr_voice_prompts_plugin, AUDIO_PLUGIN_STOP_AUDIO_PROMPT_MSG, NULL );                                 
            }            
        }
        break;
        
        default:
        {
            PRINT(("handleKalimbaMessage: unhandled %X\n", m->id));
        }
        break;
    }
}

/****************************************************************************
DESCRIPTION
    Internal messages to the task are handled here
*/ 
static void handleInternalMessage ( Task task , MessageId id, Message message )     
{
    switch (id)
    {
        case MESSAGE_STREAM_DISCONNECT:
        {        
            PRINT(("VP: MESSAGE_STREAM_DISCONNECT\n"));
   
            if(IsAudioBusy() && (IsAudioBusy() == (TaskData*) &csr_voice_prompts_plugin))
            {
                MessageCancelAll ((TaskData*)IsAudioBusy(), AUDIO_PLUGIN_STOP_AUDIO_PROMPT_MSG ) ;
                MessageSend( (TaskData*) &csr_voice_prompts_plugin, AUDIO_PLUGIN_STOP_AUDIO_PROMPT_MSG, NULL );
            }    
        }
        break ;
        
        case MESSAGE_MORE_SPACE:
            PRINT(("VP: MESSAGE_MORE_SPACE\n"));
        break;
        
        default:
            Panic() ;
        break ;
    }
}
