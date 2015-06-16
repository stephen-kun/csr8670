/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_tones.h
    
DESCRIPTION
    header file which defines all of the tones which can be used in the 
	sink device application
    
*/  

#ifndef SINK_TONES_H
#define SINK_TONES_H


/****************************************************************************
NAME 
 TonesPlayEvent

DESCRIPTION
 function to indaicate an event by playing its associated tone uses underlying
    tones playback

RETURNS
 void
    
*/
void TonesPlayEvent ( sinkEvents_t pEvent ) ;

/****************************************************************************
NAME    
    TonesPlayTone
    
DESCRIPTION
  	Works out the correct volume to play tones or Audio Prompts at
    
RETURNS
    void
*/
uint16 TonesGetToneVolume(bool PlayToneAtDefaultLevel);

/****************************************************************************
NAME    
    TonesPlayTone
    
DESCRIPTION
  	Playsback the tone given by the heasdsetTone_t index
    
RETURNS
    void
*/
void TonesPlayTone ( uint16 pTone , bool pCanQueue , bool PlayToneAtDefaultLevel) ;

/****************************************************************************
NAME    
    ToneTerminate
    
DESCRIPTION
  	function to terminate a ring tone prematurely.
    
RETURNS
    
*/
void ToneTerminate ( void ) ;

#endif

