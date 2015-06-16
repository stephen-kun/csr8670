/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    audio.h
    
DESCRIPTION
    header file for the audio library	
*/

/*!
@file   audio.h
@brief  Header file for the audio library.
    This defines the Application Programming interface to the audio library.
    
    i.e. the interface between the VM application and the audio library.
        
    see the audio_plugin_if documentation for details of the API between the 
    audio library and an underlying audio plugin.
*/

#ifndef _AUDIO_H_
#define _AUDIO_H_

#include <message.h>
#include <stream.h> /*for the ringtone_note*/
#include "audio_plugin_if.h"


typedef struct audio_lib_Tag
{
    Task plugin;                            /* main plugin in use */
    Task relay_plugin;                      /* plugin used for managing stream relay operation */
    uint16 AUDIO_BUSY;                      /* audio routing currently in progress */
    AUDIO_PLUGIN_CONNECT_MSG_T message;     /* store of current connection params */
    DSP_STATUS_INFO_T dsp_status;           /* current dsp status */
    unsigned audio_in_use:1;                /* audio currently being routed */
    unsigned tone_playing:1;                /* tone currently being played */
    unsigned vp_playing:1;                  /* voice prompt currently being played */
    unsigned asr_running:1;                 /* asr is currently running/listening */
    unsigned unused:12;     
}AUDIO_t ;

/****************************************************************************
NAME	
	AudioLibraryInit

DESCRIPTION
	This function mallocs the memory to be used by the audio library 

RETURNS
	void
*/
void AudioLibraryInit (  void );


/*!
    @brief Connects an audio stream to the underlying audio plugin 
    
    @param audio_plugin The audio plugin to use for the audio connection
    @param audio_sink The Sink to connect (may be synchronous AV or other) 
    @param sink_type The type of audio connection required - see AUDIO_SINK_T
    @param codec_task The codec task to connect the audio stream to
    @param volume The volume at which to connect the audio plugin. 
                  The plugin vendor is responsible for the use of this value    
    @param stereo Whether or not a stereo connection is to be used (channel A or channel A & B)
    @param mode The mode to set the audio connection to
                This behaviour is plugin dependent
    @param route The route the audio will take (internal, i2s, spif)
                This behaviour is plugin dependent
    @param power The power level the plugin will use
                This behaviour is plugin dependent
    @param params Used to specify plugin specific parameters - See plugin vendor for details 
    @param app_task The main application task that should receive messages sent from the plugin.
    
    A call to AudioConnect must be followed by a call to AudioDisconnect
    i.e. only a single audio plugin can be supported at any one time
    
    The underlying audio plugin is responsible for connecting up the audio sink
    as requested
    
    Calls to AudioConnect will be queued if the AUDIO_BUSY flag is set. 
    i.e. if a tone is currently being played, then the audio connection will occur
    once the tone has completed.
      
*/
bool AudioConnect(Task audio_plugin,
                  Sink audio_sink , 
				  AUDIO_SINK_T sink_type , 
				  Task codec_task , 
				  uint16 volume, 
				  uint32 rate  , 
				  AudioPluginFeatures features , 
				  AUDIO_MODE_T mode , 
				  AUDIO_ROUTE_T route , 
				  AUDIO_POWER_T power ,
				  const void * params , 
				  Task app_task);

/*!
    @brief Disconnects an audio stream previously connected using AudioConnect
    
    The underlying audio_plugin previously connected using AudioConnect() 
    will be asked to perform the disconnect.
    
    Calls to AudioDisconnect when no plugin is connected will be ignored
    
*/
void AudioDisconnect(void);

/*!
    @brief Updates the volume of any currently connected audio connection
    
    @param volume The new volume to pass to the currently connected audio plugin
    @param volume The new tone/prompt volume to pass to the currently connected audio plugin    
    @param codec_task The codec task used for the underlying audio connection
    
    The volume is set by the underlying audio plugin and the behaviour is specific
    to the implementation of the plugin.
    
    Some plugins may interpret this as a codec gain
    Others may choose to ignore this value etc 
    
    Note : the initial volume setting is passed in as part of AudioConnect 
*/    
void AudioSetVolume(uint16 volume , uint16 tone_volume, Task codec_task);

/*!
    @brief Updates the mode of any currently connected audio connection
    
    @param mode The mode to set the audio connection to
                This behaviour is plugin dependent
    @param params Used to specify plugin specific parameters - See plugin vendor for details
    
    The mode can be used to change the connection behaviour of an underlying plugin and this 
    behaviour is not supported by all plugin vendors.
    
    This call is ignored if no plugin is currently connected
    
    Note : The mode & params are passed in as part of AudioConnect   
*/
bool AudioSetMode(AUDIO_MODE_T mode , const void * params);

/****************************************************************************
NAME	
	AudioConfigureSubWoofer

DESCRIPTION
	Set the operating mode of the sub woofer

RETURNS
	void
*/
bool AudioConfigureSubWoofer(AUDIO_SUB_TYPE_T sub_woofer_type, Sink sub_sink );

/*!
    @brief Updates the mute state of the audio using soft mute
    
    @param mute_type Defines which mute type to apply
        
    This call is ignored if no plugin is currently connected
*/
bool AudioSetSoftMute( AUDIO_SOFT_MUTE_TYPE_T mute_type );

/*!
    @brief Updates the route of any currently connected audio connection
    
    @param route The route the audio will take (internal, i2s, spif)
                This behaviour is plugin dependent
    @param params Used to specify plugin specific parameters - See plugin vendor for details
        
    This call is ignored if no plugin is currently connected
    
    Note : The mode & params are passed in as part of AudioConnect   
*/
bool AudioSetRoute(AUDIO_ROUTE_T route, const void * params);

/*!
    @brief Starts forwarding undecoded audio frames to the specified sink
    
	@param relay_plugin Plugin that manages the relay mechanism
    @param forwarding_sink The media sink to a remote device
                           This behaviour is plugin dependent
    @param content_protection Flag indicating if content protection is enabled
    
    This call is ignored if a main plugin is not currently connected
*/
bool AudioStartForwarding(Task relay_plugin, Sink forwarding_sink, bool content_protection);

/*!
    @brief Stops forwarding of undecoded audio frames
           This behaviour is plugin dependent
        
    This call is ignored if no plugin is currently connected
*/
void AudioStopForwarding(void);

/*!
    @brief Plays a tone 
    
    @param tone The tone to be played 
    @param can_queue Whether or not to queue the requested tone
    @param codec_task The codec task to connect the tone to
    @param tone_volume The volume at which to play the tone (0 = play tone at current volume)
    @param features including Whether or not a stereo connection is to be used (channel A or channel A & B)                    
		
    Tone playback can be used when an audio connection is present or not. (plugin connected or not)
    
    When a plugin is not connected, the standard tone playback plugin is used - csr_tone_plugin
    This allows tones to be played direct to the codec task (pcm) without the use of a DSP
    
    When a plugin is connected, the tone playback request will be passed to the currently connected plugin
    The underlying plugin is then responsible for connecting up the audio tone.
    Some plugins may choose to ignore tone requests in certain modes 
    
    Tone queuing can be achieved using the can_queue parameter. If this is selected, then
    tones will be queued using the audio flag AUDIO_BUSY.
    Tones will be played back in the order they are requested.       
*/

void AudioPlayTone ( const ringtone_note * tone , bool can_queue , Task codec_task, uint16 tone_volume , AudioPluginFeatures features ) ;

/*!
    @brief Stops a currently playing tone
    
    If a tone is currently connected to either the default tone plugin (csr_tone_plugin)
    or to any other connected plugin then, the tone can be stopped part way through.
    
    In general, this is used to end ring tones prematurely to allow fast call setup times.
    
    Note : The implementation of AudioStopTone is plugin specific.
    Some plugins may choose to ignore the request to stop playback of a tone
*/
void AudioStopTone ( void ) ;

/*!
    @brief Plays text-to-speech

    @param plugin Audio Prompt plugin to use

    @param id Identifier used by the Audio Prompt plug-in to determine which Audio Prompt to
            play, eg name caller ID

    @param language This gives us an offest from the id determined by
                language * (size_index / no_languages), where size_index and
                no_languages are taken from AudioVoicePromptsInit. 
                
    @param can_queue If this is TRUE, and Audio Prompt cannot currently be played 
                (eg tone is playing), then it will be played on 
                completion of the currently playing tone

    @param ap_volume The volume at which to play the Audio Prompt. A non-zero value will 
                      cause the Audio Prompt to played at this volume level.

    @param features including Whether or not a stereo connection is to be used (channel A or channel A & B)     						

    @param app_task The main application task that should receive messages sent from audio lib.		

    @param override  prompt is set to play immediately, cancel any queued prompts
*/
void AudioPlayAudioPrompt ( Task plugin , uint16 id ,  uint16 language , bool can_queue , Task codec_task, uint16 ap_volume , AudioPluginFeatures features, bool override, Task app_task );
/*!
    @brief Stop Audio Prompt from playing
*/
void AudioStopAudioPrompt ( Task plugin );

/*!
    @brief Initialises the voice prompts indexing, telling the plugin where in EEPROM voice 
                prompts are located.

    @param plugin The voice prompts plugin

    @param size_index The number of voice prompts to index
                  
    @param no_languages The number of languages supported. For example if there are
                  four prompts and two languages size_index = 4, no_languages = 2. When a
                  prompt is played the index is found using :
                  id + (language *(size_index/no_languages))
                  
                  Prompts should be stored as shown below:
                  | idx 0 | idx 1 | idx 2 | idx 3 |
                  |lang00|lang01|lang10|lang11|
*/
void AudioVoicePromptsInit( TaskData * plugin, uint16 no_prompts, uint16 no_languages);

/*!
    @brief Updates the Power level of any currently connected audio connection
    
    @param power The power to set the audio connection to
                This behaviour is plugin dependent
    
    This can be used to change the power level of an underlying plugin and this 
    behaviour is not supported by all plugin vendors.
    
    This call is ignored if no plugin is currently connected
*/
void AudioSetPower(AUDIO_POWER_T power);

/*!
    @brief Swap between microphone inputs in Production Test
*/
void AudioMicSwitch ( void );

/****************************************************************************
NAME	
	AudioStartASR

DESCRIPTION
	Start or restart the ASR algorithm

RETURNS
	
*/
bool AudioStartASR ( AUDIO_MODE_T mode ) ;
        
/****************************************************************************
NAME	
	IsAudioBusy

DESCRIPTION
	query the current status of the audio library

RETURNS
	pointer to current audio_busy task value
*/
TaskData * IsAudioBusy(void);

/****************************************************************************
NAME	
	SetAudioBusy

DESCRIPTION
	update the current status of the audio library

RETURNS

*/
void SetAudioBusy(TaskData* task);

/****************************************************************************
NAME	
	GetCurrentDspStatus

DESCRIPTION
	query the current dsp status of the audio library

RETURNS
	pointer to current dsp status value
*/
DSP_STATUS_INFO_T GetCurrentDspStatus(void);

/****************************************************************************
NAME	
	SetCurrentDspStatus

DESCRIPTION
	update the current dsp status of the audio library

RETURNS
	
*/
void SetCurrentDspStatus(DSP_STATUS_INFO_T status);

/****************************************************************************
NAME	
	IsAudioInUse

DESCRIPTION
	query whether the audio sub system is currently in use

RETURNS
    true or false status
*/
bool IsAudioInUse(void);

/****************************************************************************
NAME	
	SetAudioInUse

DESCRIPTION
	update the current audio in use state

RETURNS
	
*/
void SetAudioInUse(bool status);

/****************************************************************************
NAME	
	IsTonePlaying

DESCRIPTION
	query whether the tone playing is currently in use

RETURNS
    true or false status
*/
bool IsTonePlaying(void);

/****************************************************************************
NAME	
	SetTonePlaying

DESCRIPTION
	update the current tone playing in use state

RETURNS
	
*/
void SetTonePlaying(bool status);

/****************************************************************************
NAME	
	IsVpPlaying

DESCRIPTION
	query whether the voice prompt system is currently in use

RETURNS
    true or false status
*/
bool IsVpPlaying(void);

/****************************************************************************
NAME	
	IsAudioRelaying

DESCRIPTION
	Query whether the  plugin used for the stream relay operation is available

RETURNS
	void
*/
bool IsAudioRelaying(void);

/****************************************************************************
NAME	
	SetVpPlaying

DESCRIPTION
	update the current voice playing state 

RETURNS
	
*/
void SetVpPlaying(bool status);

/****************************************************************************
NAME	
	IsAsrPlaying

DESCRIPTION
	query whether the asr system is currently in use

RETURNS
    true or false status
*/
bool IsAsrPlaying(void);

/****************************************************************************
NAME	
	SetAsrPlaying

DESCRIPTION
	update the current asr state 

RETURNS
	
*/
void SetAsrPlaying(bool status);

/****************************************************************************
NAME	
	AudioBusyPtr

DESCRIPTION
	get pointer to AUDIO_BUSY for use with messageSendConditionally
RETURNS
	pointer to current audio_busy task value
*/
uint16 * AudioBusyPtr(void);

/****************************************************************************
NAME	
	GetAudioPlugin

DESCRIPTION
	method to get current audio plugin 

RETURNS
	
*/
Task GetAudioPlugin(void);

/****************************************************************************
NAME
	AudioSetVolumeA2DP

DESCRIPTION
	method to send A2DP volume info to DSP

RETURNS

*/
void AudioSetVolumeA2DP(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T *volume);


#endif /* _AUDIO_H_ */
