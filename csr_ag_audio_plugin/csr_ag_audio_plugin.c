/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_ag_audio_plugin.c
DESCRIPTION
    Interface file for an audio_plugin
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <print.h>
#include <stream.h> /*for the ringtone_note*/

#include "audio_plugin_if.h" /*the messaging interface*/
#include "csr_ag_audio_plugin.h"
#include "csr_ag_audio.h"
#include "csr_ag_audio_if.h"
	/*the task message handler*/
static void message_handler (Task task, MessageId id, Message message) ;

	/*the local message handling functions*/
static void handleAudioMessage ( Task task , MessageId id, Message message ) 	;
static void handleInternalMessage ( Task task , MessageId id, Message message ) 	;
	
	/*the plugin task*/

const CsrAgAudioPluginTaskData csr_ag_audio_cvsd_8k_1mic_plugin = {{message_handler}, CSR_AG_AUDIO_CVSD_8K_1_MIC, 0, 0};

const CsrAgAudioPluginTaskData csr_ag_audio_cvsd_48k_1mic_plugin = {{message_handler}, CSR_AG_AUDIO_CVSD_48K_1_MIC, 0, 0};

const CsrAgAudioPluginTaskData csr_ag_audio_cvsd_8k_2mic_plugin = {{message_handler}, CSR_AG_AUDIO_CVSD_8K_2_MIC, 1, 0};

const CsrAgAudioPluginTaskData csr_ag_audio_sbc_16k_1mic_plugin = {{message_handler}, CSR_AG_AUDIO_SBC_16K_1_MIC, 0, 0};

const CsrAgAudioPluginTaskData csr_ag_audio_sbc_48k_1mic_plugin = {{message_handler}, CSR_AG_AUDIO_SBC_48K_1_MIC, 0, 0};

const CsrAgAudioPluginTaskData csr_ag_audio_sbc_2mic_plugin = {{message_handler}, CSR_AG_AUDIO_SBC_2_MIC, 1, 0};


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
		case (AUDIO_PLUGIN_CONNECT_MSG ):
		{
			AUDIO_PLUGIN_CONNECT_MSG_T * connect_message = (AUDIO_PLUGIN_CONNECT_MSG_T *)message ;
	
			if (IsAudioBusy())
			{ 		/*Queue the connect message until the audio task is available*/
				MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_CONNECT_MSG ) ; 
				
				message->audio_sink = connect_message->audio_sink ;
				message->sink_type  = connect_message->sink_type ;
				message->codec_task = connect_message->codec_task ;
				message->volume     = connect_message->volume ;
				message->rate       = connect_message->rate ;
				message->mode       = connect_message->mode ;
				message->features   = connect_message->features ;
				message->params     = connect_message->params ;
                message->app_task	= connect_message->app_task ;
				
			    MessageSendConditionally ( task, AUDIO_PLUGIN_CONNECT_MSG , message , (const uint16 *)AudioBusyPtr() ) ;
			} 
			else
			{		/*connect the audio*/
				CsrAgAudioPluginConnect(  (CsrAgAudioPluginTaskData*)task,
                                  connect_message->audio_sink,
                                  connect_message->sink_type,
                                  connect_message->codec_task,
                                  connect_message->volume,
                                  connect_message->rate,
                                  connect_message->features.stereo,
                                  connect_message->mode,
                                  connect_message->params,
                                  connect_message->app_task);
			}			
		}	
		break ;
		
		case (AUDIO_PLUGIN_DISCONNECT_MSG ):
		{
			if (IsAudioBusy())
			{
				MessageSendConditionally ( task, AUDIO_PLUGIN_DISCONNECT_MSG , 0 ,(const uint16 *)AudioBusyPtr() ) ;
    		}
			else
			{
				CsrAgAudioPluginDisconnect((CsrAgAudioPluginTaskData*)task) ;
			}
		}	
		break ;
		
		case (AUDIO_PLUGIN_SET_MODE_MSG ):
		{
            AUDIO_PLUGIN_SET_MODE_MSG_T * mode_message = (AUDIO_PLUGIN_SET_MODE_MSG_T *)message ;			
			
            if (IsAudioBusy())
            {
                MAKE_AUDIO_MESSAGE ( AUDIO_PLUGIN_SET_MODE_MSG) ;
                message->mode   = mode_message->mode ;
                message->params = mode_message->params ;
        
        		MessageSendConditionally ( task, AUDIO_PLUGIN_SET_MODE_MSG , message ,(const uint16 *)AudioBusyPtr() ) ;
    	    }
            else
            {
                CsrAgAudioPluginSetMode((CsrAgAudioPluginTaskData*)task,mode_message->mode , mode_message->params) ;
            }
		}
		break ;
		
		case (AUDIO_PLUGIN_SET_VOLUME_MSG ): 
		{
			AUDIO_PLUGIN_SET_VOLUME_MSG_T * volume_message = (AUDIO_PLUGIN_SET_VOLUME_MSG_T *)message ;			
			
			if (IsAudioBusy())
			{
			     MAKE_AUDIO_MESSAGE (AUDIO_PLUGIN_SET_VOLUME_MSG ) ;
			     message->volume = volume_message->volume ;
			     
		         MessageSendConditionally ( task, AUDIO_PLUGIN_SET_VOLUME_MSG , message ,(const uint16 *)AudioBusyPtr()) ;    	
            }
            else
            {
                CsrAgAudioPluginSetVolume ((CsrAgAudioPluginTaskData*)task, volume_message->volume ) ;
            }			
		}		
		break ;
		
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
	
					PRINT(("TONE:Q\n"));
					
					MessageSendConditionally ( task , AUDIO_PLUGIN_PLAY_TONE_MSG, message ,(const uint16 *)AudioBusyPtr() ) ;			
				}
			}
			else
			{
				PRINT(("TONE:start\n"));				
                SetAudioBusy((TaskData*) task);    
        		CsrAgAudioPluginPlayTone ((CsrAgAudioPluginTaskData*)task, tone_message->tone, tone_message->codec_task  , 					  
								        tone_message->tone_volume, tone_message->features.stereo      ) ;		     				
			}
							     
		}
		break ;
		
		case (AUDIO_PLUGIN_STOP_TONE_MSG ):
		{
			if (IsAudioBusy())
			{
				CsrAgAudioPluginStopTone() ;
			}
		}
		break ;		
		
		default:
		{
		}
		break ;
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
        case MESSAGE_STREAM_DISCONNECT: /*a tone has completed*/
        {
            PRINT(("CSR_AG_AUDIO: Tone End\n"));
            SetAudioBusy(NULL);
            
            CsrAgAudioPluginToneComplete((CsrAgAudioPluginTaskData*)task) ;            
        }    
		break ;
		
		default:
		{
				/*route the cvc messages to the relavent handler*/
			CsrAgAudioPluginInternalMessage((CsrAgAudioPluginTaskData*)task , id , message ) ;
		}
		break ;
	}	
}
