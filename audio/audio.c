/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
	audio.c        
	
DESCRIPTION
     The main audio manager file
     
*/ 
#include "audio.h"

#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <stream.h>
#include <csr_tone_plugin.h> /*allows tones to be played while no other plugin is in use*/
#include <csr_voice_prompts_plugin.h>
#include <print.h>
#include <string.h>
#include <csr_a2dp_decoder_common_plugin.h>

#ifdef RESAMPLE_TONES
/* If tone resampling is needed the csr_voice_prompts_plugin_resample plugin variant should be used */
#define TONE_PLUGIN csr_voice_prompts_plugin
#else
#define TONE_PLUGIN csr_tone_plugin
#endif

static AUDIO_t * AUDIO;

/****************************************************************************
NAME	
	AudioLibraryInit

DESCRIPTION
	This function mallocs the memory to be used by the audio library 

RETURNS
	void
*/
void AudioLibraryInit (  void )
{
    if (AUDIO == NULL)
    {
        /* malloc one allocation for audio and plugin use */
        AUDIO = PanicUnlessMalloc(sizeof(AUDIO_t));  
    
        /* initialise to 0 */
        memset(AUDIO,0,sizeof(AUDIO_t));
    }
}



/****************************************************************************
NAME	
	AudioSyncConnect

DESCRIPTION
	This function connects cvc to the stream subsystem

RETURNS
	void
*/
bool AudioConnect (  Task audio_plugin,  
                     Sink audio_sink , 
					 AUDIO_SINK_T sink_type , 
					 Task codec_task , 
					 uint16 volume , 
					 uint32 rate ,  
					 AudioPluginFeatures features , 
					 AUDIO_MODE_T mode, 
					 AUDIO_ROUTE_T route , 
					 AUDIO_POWER_T power, 
					 const void * params , 
					 Task app_task ) 
{   
	/*send a message to the audio plugin*/
	MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_CONNECT_MSG ) ;
	
	message->audio_sink = audio_sink ;
	message->sink_type  = sink_type ; 
	message->codec_task = codec_task ;
	message->volume     = volume ;
	message->rate		= rate;
	message->mode 		= mode ;
    message->route      = route;
	message->features   = features ; 
	message->params     = params ;
	message->app_task	= app_task ;
	message->power	    = power ;
    
    AUDIO->plugin = audio_plugin ;
    AUDIO->message = *message;

    PRINT(("AUD: AudioConnect pl[%x] sk[%x] bsy[%x]\n", (uint16)audio_plugin, (int)audio_sink, (uint16)AUDIO->AUDIO_BUSY )) ;
    MessageSendConditionally ( audio_plugin, AUDIO_PLUGIN_CONNECT_MSG , message , (const uint16 *)AudioBusyPtr() ) ;
    return TRUE ;
}

/****************************************************************************
NAME	
	AudioDisconnect

DESCRIPTION
	Disconnect any currently connected audio, including any relay channel
    
RETURNS
	void
*/
void AudioDisconnect( void )
{
	
    if ( AUDIO->plugin )
	{
    	MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_DISCONNECT_MSG , 0 , (const uint16 *)AudioBusyPtr() ) ;
	}
    else
	{
        PRINT(("AUD: AudioDisconnect ignored, not connected\n"));
	}
    
    AUDIO->plugin = NULL;
	AUDIO->relay_plugin = NULL;
}

/****************************************************************************
NAME	
	AudioSetVolume

DESCRIPTION
	update the volume of any currently connected audio

RETURNS
	void
*/
void AudioSetVolume( uint16 volume , uint16 tone_volume, Task codec_task )
{
	if ( AUDIO->plugin )   
    {
	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_VOLUME_MSG ) ; 
	
		message->codec_task = codec_task ;
		message->volume     = volume ;
        message->tone_volume = tone_volume;
		
	    MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_SET_VOLUME_MSG, message , (const uint16 *)AudioBusyPtr() ) ;
        
        AUDIO->message.volume = volume;
    }
}

/****************************************************************************
NAME	
	AudioSetMode

DESCRIPTION
	Set the audio connection mode

RETURNS
	void
*/
bool AudioSetMode ( AUDIO_MODE_T mode , const void * params )
{
    bool lResult = FALSE ;
    
    if ( AUDIO->plugin )
    {
	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_MODE_MSG ) ; 
	
		message->mode = mode ;
		message->params = params ;
		
	    MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_SET_MODE_MSG, message , (const uint16 *)AudioBusyPtr() ) ;
	    
	    lResult = TRUE ;
        AUDIO->message.mode   = mode;
    }
    
    return lResult ;   
}

/****************************************************************************
NAME	
	AudioConfigureSubWoofer

DESCRIPTION
	Set the operating mode of the sub woofer

RETURNS
	void
*/
bool AudioConfigureSubWoofer(AUDIO_SUB_TYPE_T  sub_woofer_type, Sink sub_sink )
{
    bool lResult = FALSE ;
    
    if ( AUDIO->plugin )
    {
	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_SUB_WOOFER_MSG ) ; 
	
		message->sub_woofer_type = sub_woofer_type ;
		message->sub_sink = sub_sink ;
		
	    MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_SET_SUB_WOOFER_MSG, message , (const uint16 *)AudioBusyPtr() ) ;
	    
	    lResult = TRUE ;
    }
    
    return lResult ;       
}

/****************************************************************************
NAME	
	AudioSetSoftMute

DESCRIPTION
	Apply soft mute / unmute to either (or both) sink and subwoofer

RETURNS
	void
*/
bool AudioSetSoftMute( AUDIO_SOFT_MUTE_TYPE_T mute_type )
{
    bool lResult = FALSE ;
    
    if ( AUDIO->plugin )
    {
	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_SOFT_MUTE_MSG ) ; 
	
		message->mute_mode_type = mute_type ;
		
	    MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_SET_SOFT_MUTE_MSG, message , (const uint16 *)AudioBusyPtr() ) ;
	    
	    lResult = TRUE ;
    }
    
    return lResult ;     
}

/****************************************************************************
NAME	
	AudioSetRoute

DESCRIPTION
	Set the audio connection route

RETURNS
	void
*/
bool AudioSetRoute(AUDIO_ROUTE_T route, const void * params)
{
    bool lResult = FALSE ;
    
    if ( AUDIO->plugin )
    {
	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_ROUTE_MSG ) ; 
	
		message->route = route ;
		message->params = params ;
		
	    MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_SET_ROUTE_MSG, message , (const uint16 *)AudioBusyPtr()) ;
	    
	    lResult = TRUE ;
        AUDIO->message.route  = route;
    }
    
    return lResult ;   
}

/****************************************************************************
NAME	
	AudioStartForwarding

DESCRIPTION
	Start forwarding undecoded audio frames to specified sink

RETURNS
	void
*/
bool AudioStartForwarding(Task relay_plugin, Sink forwarding_sink, bool content_protection)
{
    bool lResult = FALSE ;
    
    if ( AUDIO->plugin && ((AUDIO->relay_plugin == NULL) || (AUDIO->relay_plugin == relay_plugin)))
    {
	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_START_FORWARDING_MSG ) ; 
	
		message->forwarding_sink = forwarding_sink ;
		message->content_protection = content_protection ;

		AUDIO->relay_plugin = relay_plugin;
		
		MessageSendConditionally ( AUDIO->relay_plugin, AUDIO_PLUGIN_START_FORWARDING_MSG, message , (const uint16 *)AudioBusyPtr()) ;
	    
	    lResult = TRUE ;
    }
    
    return lResult ;   
}


/****************************************************************************
NAME	
	IsAudioRelaying

DESCRIPTION
	Query whether the  plugin used for the stream relay operation is available

RETURNS
	void
*/
bool IsAudioRelaying(void)
{
    if(AUDIO->relay_plugin != NULL)
        return TRUE;
    else
        return FALSE;
}

/****************************************************************************
NAME	
	AudioStopForwarding

DESCRIPTION
	Stop forwarding of undecoded audio frames

RETURNS
	void
*/
void AudioStopForwarding(void)
{
    if ( AUDIO->plugin && AUDIO->relay_plugin)
    {
	    MessageSendConditionally ( AUDIO->relay_plugin, AUDIO_PLUGIN_STOP_FORWARDING_MSG, NULL , (const uint16 *)AudioBusyPtr()) ;
		
		AUDIO->relay_plugin = NULL ;
    }
}

/****************************************************************************
NAME	
	AudioPlayTone

DESCRIPTION

    queues the tone if can_queue is TRUE and there is already a tone playing

RETURNS 
    
*/
void AudioPlayTone ( const ringtone_note * tone , bool can_queue , Task codec_task, uint16 tone_volume , AudioPluginFeatures features ) 
{   	
	if ((uint16*)AUDIO->AUDIO_BUSY == NULL || can_queue) 
	{
		MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_PLAY_TONE_MSG ) ; 
	
    	message->tone        = (ringtone_note *) (tone) ;
    	message->can_queue   = can_queue ;
    	message->codec_task  = codec_task ;
    	message->tone_volume = tone_volume  ;
    	message->features    = features ;
	
        if(AUDIO->plugin)
        {
    		PRINT(("AUDIO: play tone, plugin = %x \n",(uint16)AUDIO->plugin));
		    MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_PLAY_TONE_MSG, message , (const uint16 *)AudioBusyPtr() ) ;
	    }
        else
	    {    
    		PRINT(("AUDIO: play tone, no plugin \n"));
			MessageSendConditionally( (TaskData*)&TONE_PLUGIN, AUDIO_PLUGIN_PLAY_TONE_MSG, message , (const uint16 *)AudioBusyPtr() ) ;
	    }
	}
	else
	{
		PRINT(("AUDIO: discard tone \n"));
	} 
}

/****************************************************************************
NAME	
	AudioStopTone

DESCRIPTION
	Stop a tone from playing

RETURNS
	
*/
void AudioStopTone ( void ) 
{
    PRINT(("AUDIO: STOP tone, busy = %x\n",(uint16)AUDIO->AUDIO_BUSY));
	if(AUDIO->AUDIO_BUSY)
	{	
		MessageSend ( (TaskData*)AUDIO->AUDIO_BUSY , AUDIO_PLUGIN_STOP_TONE_MSG, 0 ) ;
		MessageCancelAll((TaskData*)&(TONE_PLUGIN),AUDIO_PLUGIN_PLAY_TONE_MSG);
		MessageCancelAll((TaskData*) AUDIO->AUDIO_BUSY ,AUDIO_PLUGIN_PLAY_TONE_MSG);
	}
}

/****************************************************************************
NAME	
	AudioPlayAudioPrompt
    
DESCRIPTION

    plays / queues the Audio Prompt if already Playing or busy. 

RETURNS
    
*/
void AudioPlayAudioPrompt ( Task plugin , uint16 id , uint16 language , bool can_queue , Task codec_task, uint16 ap_volume , AudioPluginFeatures features, bool override, Task app_task )
{   
	MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG) ; 
	
	message->id          = id ;
	message->language    = language ;
	message->can_queue   = can_queue ;
	message->codec_task  = codec_task ;
	message->ap_volume   = ap_volume  ;
	message->features    = features ;
	message->app_task    = app_task;
	
    if (AUDIO->plugin) 
	{
        /* if this voice prompt is set to play immediately, cancel any queued prompts */
        if(override)
        {
            MessageCancelAll( plugin, AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG);
            MessageCancelAll( plugin, AUDIO_PLUGIN_CONNECT_MSG);
        }


        /* determine whether voice prompts can be mixed with dsp audio, to do this 
           voice prompts must be in adpcm or pcm format and the audio plugin must be capable
           of supporting tone mixing via kalimba port 3 (tone port) */
#ifdef EXCLUDE_AP
        if(GetCurrentDspStatus()) 
#else		
        if((GetCurrentDspStatus()) && 
           (CsrVoicePromptsIsMixable(id, language, codec_task)))      
#endif                
        {
            PRINT(("AUD play Audio Prompt via DSP mixing\n"));				
            MessageSendConditionally ( plugin , AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG ,message , (const uint16 *)AudioBusyPtr() ) ;        
        }
        /* if the audio plugin connect message is in the queue but not yet actioned, queue
           the Audio Prompt message until the audio plugin is loaded, then decide what to do with it */     
#ifdef EXCLUDE_AP
        else if(!IsAudioInUse())
#else           
        else if((!IsAudioInUse()) && 
           (CsrVoicePromptsIsMixable(id, language, codec_task)))           
#endif           
        {          
            PRINT(("AUD play Audio Prompt - plugin loading\n"));	
            MessageSendConditionally ( plugin , AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG , message , (const uint16 *)AudioBusyPtr() ) ;           
        }
        /* audio is connected via audio plugin and not using the DSP or not ADPCM voice prompts
           so need to disconnect current plugin prior to playing voice prompts */
        else
        {
        
            PRINT(("AUD play -Audio Prompt disconnect audio\n"));				
            /*if we have a plugin connected, then perform the disconnect*/
            MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_DISCONNECT_MSG , 0 , (const uint16 *)AudioBusyPtr() ) ;
            MessageSendConditionally ( plugin , AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG , message , (const uint16 *)AudioBusyPtr() ) ;           
    
			/* queue message to reconnect plugin and restore volume*/
            {
                MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_CONNECT_MSG ) ;
                *message = AUDIO->message;
                MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_CONNECT_MSG , message , (const uint16 *)AudioBusyPtr() ) ;
            }    

            /* request app refresh volume after reconnect */
            {
                MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_REFRESH_VOLUME);
                PRINT(("AUD:Vol refresh\n"));
                message->audio_plugin = codec_task;
                MessageSendConditionally(app_task, AUDIO_PLUGIN_REFRESH_VOLUME, message, (const uint16 *)AudioBusyPtr());
            }			
        }
    }
    else
    {
        PRINT(("AUD play Audio Prompt no plugin\n"));				
        /* if this voice prompt is set to play immediately, cancel any queued prompts */
        if(override)
            MessageCancelAll( plugin, AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG);
        
        MessageSendConditionally ( plugin , AUDIO_PLUGIN_PLAY_AUDIO_PROMPT_MSG ,message , (const uint16 *)AudioBusyPtr() ) ;        
    }	
}

/****************************************************************************
NAME	
	AudioStopAudioPrompt

DESCRIPTION
	Stop Audio Prompt from playing

RETURNS
*/
void AudioStopAudioPrompt ( TaskData * plugin )
{
	if ( AUDIO->AUDIO_BUSY && ((TaskData *)AUDIO->AUDIO_BUSY == plugin) )  /* only send message if plugin is currently Playing */
	{
        PRINT(("AUD stop Audio Prompt plugin=%x, busy=%x\n",(uint16)plugin,(uint16)AUDIO->AUDIO_BUSY));				
	    MessageSend ((TaskData*)plugin, AUDIO_PLUGIN_STOP_AUDIO_PROMPT_MSG, 0 ) ;
    }
}


#ifndef EXCLUDE_AP
/****************************************************************************
NAME	
	AudioVoicePromptsInit

DESCRIPTION
    Initialises the voice prompts indexing. The data block pointed to by index should *NOT* be freed
    after calling this function, the plugin will refer to this block once it has been 
    initialised.

RETURNS
*/
void AudioVoicePromptsInit( TaskData * plugin, uint16 no_prompts, uint16 no_languages)
{
    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_VOICE_PROMPTS_INIT_MSG ); 
    message->no_prompts   = no_prompts;
    message->no_languages = no_languages;
    MessageSend (plugin, AUDIO_PLUGIN_VOICE_PROMPTS_INIT_MSG, message) ;
}
#endif  /* EXCLUDE_AP */



/****************************************************************************
NAME	
	AudioSetPower

DESCRIPTION
	    This can be used to change the power level of an underlying plugin and this 
		behaviour is not supported by all plugin vendors.

RETURNS
	
*/
void AudioSetPower(AUDIO_POWER_T power)
{
    if ( AUDIO->plugin )
    {
		MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_POWER_MSG ) ; 
	
		message->power = power ;
        /* NB. Don't update AUDIO.message or we may end up with no DSP and metadata enabled */
	    MessageSend (AUDIO->plugin, AUDIO_PLUGIN_SET_POWER_MSG, message ) ;
    }

}

/****************************************************************************
NAME	
	AudioMicSwitch

DESCRIPTION
	Swap between the two microphone inputs in Production Test

RETURNS
	
*/
void AudioMicSwitch ( void ) 
{
    PRINT(("AUD: MicSwitch\n")) ;
	
    if ( AUDIO->plugin )
    {
    	MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_MIC_SWITCH_MSG, 0 , (const uint16 *)AudioBusyPtr() ) ;
    }
    
}



/****************************************************************************
NAME	
	AudioStartASR

DESCRIPTION
	Start or restart the ASR algorithm

RETURNS
	
*/
bool AudioStartASR ( AUDIO_MODE_T mode ) 
{
    bool lResult = FALSE ;

    PRINT(("AUD: AudioStartASR")) ;
	
    if ( AUDIO->plugin )
    {
   	    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_START_ASR ) ; 
	
		message->mode = mode ;

    	MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_START_ASR, message , (const uint16 *)AudioBusyPtr() ) ;

        lResult = TRUE ;
    }
    return lResult;
}


/****************************************************************************
NAME	
	IsAudioBusy

DESCRIPTION
	query the current status of the audio library

RETURNS
	pointer to current audio_busy task value
*/
TaskData * IsAudioBusy(void)
{   
    PRINT(("AUD: IsAudioBusy = %s \n",AUDIO->AUDIO_BUSY?"TRUE":"FALSE")) ;
    return (TaskData *)AUDIO->AUDIO_BUSY;
}
        
/****************************************************************************
NAME	
	AudioBusyPtr

DESCRIPTION
	get pointer to AUDIO_BUSY for use with messageSendConditionally
RETURNS
	pointer to current audio_busy task value
*/
uint16 * AudioBusyPtr(void)
{   
    PRINT(("AUD: AudioBusyPtr = %s \n",AUDIO->AUDIO_BUSY?"TRUE":"FALSE")) ;
    return &AUDIO->AUDIO_BUSY;
}

/****************************************************************************
NAME	
	SetAudioBusy

DESCRIPTION
	update the current status of the audio library

RETURNS

*/
void SetAudioBusy(TaskData* task)
{
    AUDIO->AUDIO_BUSY = (uint16)task;        
    PRINT(("AUD: SetAudioBusy = %x Plugin = %x\n",(uint16)AUDIO->AUDIO_BUSY,(uint16)AUDIO->plugin)) ;
}

/****************************************************************************
NAME	
	GetCurrentDspStatus

DESCRIPTION
	query the current dsp status of the audio library

RETURNS
	pointer to current dsp status value
*/
DSP_STATUS_INFO_T GetCurrentDspStatus(void)
{
    return AUDIO->dsp_status;
}

/****************************************************************************
NAME	
	SetCurrentDspStatus

DESCRIPTION
	update the current dsp status of the audio library

RETURNS
	
*/
void SetCurrentDspStatus(DSP_STATUS_INFO_T status)
{
    AUDIO->dsp_status = status;
}

/****************************************************************************
NAME	
	IsAudioInUse

DESCRIPTION
	query whether the audio sub system is currently in use

RETURNS
    true or false status
*/
bool IsAudioInUse(void)
{
    PRINT(("AUD: IsAudioInUse = %s \n",AUDIO->audio_in_use?"TRUE":"FALSE")) ;
    return AUDIO->audio_in_use;
}

/****************************************************************************
NAME	
	SetAudioInUse

DESCRIPTION
	update the current audio in use state

RETURNS
	
*/
void SetAudioInUse(bool status)
{
    AUDIO->audio_in_use = status;
    PRINT(("AUD: SetAudioInUse = %s \n",AUDIO->audio_in_use?"TRUE":"FALSE")) ;
}

/****************************************************************************
NAME	
	IsTonePlaying

DESCRIPTION
	query whether the tone playing is currently in use

RETURNS
    true or false status
*/
bool IsTonePlaying(void)
{
    return AUDIO->tone_playing;
}

/****************************************************************************
NAME	
	SetTonePlaying

DESCRIPTION
	update the current tone playing in use state

RETURNS
	
*/
void SetTonePlaying(bool status)
{
    AUDIO->tone_playing = status;
}

/****************************************************************************
NAME	
	IsVpPlaying

DESCRIPTION
	query whether the voice prompt system is currently in use

RETURNS
    true or false status
*/
bool IsVpPlaying(void)
{
    return AUDIO->vp_playing;
}

/****************************************************************************
NAME	
	SetVpPlaying

DESCRIPTION
	update the current voice playing state 

RETURNS
	
*/
void SetVpPlaying(bool status)
{
    AUDIO->vp_playing = status;
}

/****************************************************************************
NAME	
	IsAsrPlaying

DESCRIPTION
	query whether the asr system is currently in use

RETURNS
    true or false status
*/
bool IsAsrPlaying(void)
{
    return AUDIO->asr_running;
}

/****************************************************************************
NAME	
	SetAsrPlaying

DESCRIPTION
	update the current asr state 

RETURNS
	
*/
void SetAsrPlaying(bool status)
{
    AUDIO->asr_running = status;
}

/****************************************************************************
NAME	
	GetAudioPlugin

DESCRIPTION
	method to get current audio plugin 

RETURNS
	
*/
Task GetAudioPlugin(void)
{
    return AUDIO->plugin;    
}

/****************************************************************************
NAME
	AudioSetVolumeA2DP

DESCRIPTION
	method to send A2DP volume info to DSP

RETURNS

*/
void AudioSetVolumeA2DP(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T *volumeDspA2DP )
{
	if(AUDIO->plugin){

		MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG ) ;
        
        /* create message containing passed in volume information stucture */
        memcpy(message, volumeDspA2DP, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T));       

		MessageSendConditionally ( AUDIO->plugin, AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG, message , (const uint16 *)AudioBusyPtr() ) ;

		AUDIO->message.volume = volumeDspA2DP->master_gain;
	}
}


