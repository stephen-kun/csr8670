/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_audio_prompts.h
    
DESCRIPTION
    header file which defines the interface between the audio (voice) prompts and the application
    
*/  

#ifndef SINK_AUDIO_PROMPTS_H
#define SINK_AUDIO_PROMPTS_H
#include "sink_debug.h"


#define AUDIO_PROMPT_NOT_DEFINED (0xFF)



/****************************************************************************

*/
void AudioPromptConfigure( uint8 size_index );

/****************************************************************************

*/
void AudioPromptPlay(Task plugin, uint16 id, bool can_queue, bool override);

/****************************************************************************

*/
bool AudioPromptPlayEvent( sinkEvents_t event );

/****************************************************************************
NAME 
    AudioPromptPlayNumString
DESCRIPTION
    Play a numeric string using the Audio Prompt plugin
RETURNS    
*/
void AudioPromptPlayNumString(uint16 size_num_string, uint8* num_string);

/****************************************************************************
NAME 
    AudioPromptPlayNumber
DESCRIPTION
    Play a uint32 using the audio prompt plugin
RETURNS    
*/
void AudioPromptPlayNumber(uint32 number);

/* **************************************************************************
   */


bool AudioPromptPlayCallerNumber( const uint16 size_number, const uint8* number );

/****************************************************************************
NAME    
    AudioPromptPlayCallerName
    
DESCRIPTION
  	function to play caller name
    
RETURNS
    
*/
bool AudioPromptPlayCallerName( const uint16 size_name, const uint8* name );
   
/****************************************************************************
NAME    
    AudioPromptTerminate
    
DESCRIPTION
  	function to terminate an audio prompt prematurely.
    
RETURNS
    
*/
void AudioPromptTerminate( void );

/****************************************************************************
NAME    
    AudioPromptSelectLanguage
    
DESCRIPTION
  	Move to next language
    
RETURNS
    
*/
void AudioPromptSelectLanguage( void );

#endif

