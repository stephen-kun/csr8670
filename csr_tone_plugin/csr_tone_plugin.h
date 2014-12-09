/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_tone_plugin.h

DESCRIPTION
    
    
NOTES
   
*/


/*!
@file   csr_tone_plugin.h
@brief  Header file for the default tone playback plugin


	The plugin provides tone playback whilst no other audio is routed
	This cna generate tones using the internal codecs on either DAC channel A only 
    or DAC channel A & B
    
    On calling AudioPlayTone() in the audio library, if no other audio plugin 
    is connected then, the play tone request will be routed to the csr_tone_plugin
    
    If the audio library is not busy (AUDIO_BUSY=0) then the tone will be played 
    according to the parameters passed into the audio library
    
    If the can_queue paramter is set, then tones are queued based upon the 
    state of the AUDIO_BUSY flag
    
    Tone playback opccurs in the order that tone play requests are made.
    
    AudioStopTone() is supported in this plugin - i.e. tones can be stopped prematurely 
    (e.g ring tones)
     

*/

#ifndef _CSR_TONE_PLUGIN_H_
#define _CSR_TONE_PLUGIN_H_

#include <message.h>

/*! 
    The task used to receive the audio_plugin_if messages for the audio library    
*/
extern const TaskData csr_tone_plugin ;

#endif

