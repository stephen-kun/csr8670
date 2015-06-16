/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_voice_prompts.h

DESCRIPTION
    
    
NOTES
   
*/

#ifndef _CSR_SIMPLE_TESXT_TO_SPEECH_H_
#define _CSR_SIMPLE_TESXT_TO_SPEECH_H_

#define OUTPUT_RATE_48K   48000

void CsrVoicePromptsPluginInit(uint16 no_prompts, uint16 no_languages);

typedef enum
{
    kalimba_idle,
    kalimba_loaded,
    kalimba_ready
} kalimba_state;

void CsrVoicePromptPluginPlayDsp(kalimba_state state);

void CsrVoicePromptsPluginPlayPhrase(uint16 id , uint16 language, Task codec_task , uint16 prompt_volume , AudioPluginFeatures features);
void CsrVoicePromptsPluginStopPhrase ( void ) ;
void CsrVoicePromptsPluginPlayTone ( TaskData *task, ringtone_note * tone, Task codec_task, uint16 tone_volume, AudioPluginFeatures features);
void CsrVoicePromptsPluginSetVolume (int16 volume, bool minus_6_db) ;

#endif


