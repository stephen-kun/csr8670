/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_voice_prompts_plugin.h

DESCRIPTION
    
    
NOTES
   
*/
/*!
@file   csr_voice_prompts_plugin.h

@brief  Header file for the csr plugin which allows simple 8 bit pcm Text to speech
    phrases to be connected directly to the PCM ports.  Higher quality audio prompts
    maybe used and decoded by the DSP if a suitable decoder is present.
        
    This can connect the simple Audio Prompts using the internal codecs on 
    either DAC channel A only or DAC channel A & B
    
    Tone playback is not supported in this plugin as the AudioPlayTone() functionality is 
    used for the Audio Prompts playback
     
     How to use:
     
     AudioConnect() the csr_simple_text_to_speech_plugin using the audio library
     
     call AudioPlayTone() with the digit you wish to be played.
     
     If the prompts are not located in the filesystem at the correct place, then the 
     application will panic.
      
*/



#ifndef _CSR_VOICE_PROMPTS_PLUGIN_H_
#define _CSR_VOICE_PROMPTS_PLUGIN_H_

#include <message.h>

extern const TaskData csr_voice_prompts_plugin ;
extern bool CsrVoicePromptsIsMixable(uint16 id , uint16 language, Task codec_task);

 
#endif

