/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2013-2014

FILE NAME
    sink_partymode.h      

DESCRIPTION
    These are the functions for controlling the Party Mode feature of the soundbar, 
    bluetooth connections and audio routing is handled differently in this mode
    of operation
    

NOTES

*/
#ifndef _HS_PARTYMODE_H_
#define _HS_PARTYMODE_H_

/* flag to indicate that audio source has been paused and is queued for playing
   when current flag is finished */
typedef struct    
{
    unsigned audio_source_primary_paused:1;
    unsigned audio_source_secondary_paused:1;                                
}pty_pause_state_t;

#include "sink_private.h"

#ifdef ENABLE_PARTYMODE

enum PartyModeOperatingMode
{
    partymode_none,
    partymode_barge_in,
    partymode_avrcp_control    
};


/* time a newly connected device is given to start playing a track before
   disconnecting it */
#define PARTYMODE_MUSIC_TIMEOUT D_MIN(2)


/****************************************************************************
NAME    
    sinkCheckPartyModeAudio
    
DESCRIPTION
    Called when checking for PartyMode being enabled, if not enabled no action is
    taken, when enabled decisions are made as to what audio should be playing or
    paused/resumed etc
    
RETURNS
    bool false if party mode not enabled, true is party mode enabled and action has
    been taken with regards to the routing of the audio source
*/
bool sinkCheckPartyModeAudio(audio_sources requested_source, audio_source_status * lAudioStatus);

/****************************************************************************
NAME    
    sinkPartyModeTrackChangeIndication
    
DESCRIPTION
    Called when AVRCP has detected a track change indication
    
RETURNS
    none
*/
void sinkPartyModeTrackChangeIndication(uint16 index);

/****************************************************************************
NAME    
    sinkPartyModeDisconnectDevice
    
DESCRIPTION
    Disconnects the AG specified by the passed in a2dp link priority 
    
RETURNS
    successful or unable to disconnect state as true or false
*/
bool sinkPartyModeDisconnectDevice(a2dp_link_priority link);

/****************************************************************************
NAME    
    sinkPartyModeDisconnectAndResume
    
DESCRIPTION
    Disconnects the AG specified by the passed in a2dp link priority and
    resumes the a2dp playing
    
RETURNS
    none
*/
void sinkPartyModeDisconnectAndResume(a2dp_link_priority link, audio_source_status * lAudioStatus);

/****************************************************************************
NAME    
    sinkPartyModeCheckForOtherPausedSource
    
DESCRIPTION
    function to look for a device other than the one passed in that is in an paused
    state
    
RETURNS
    link priority if an avrcp paused device is found
*/
a2dp_link_priority sinkPartyModeCheckForOtherPausedSource(a2dp_link_priority link);


/* ENABLE_PARTYMODE */
#endif
/* _HS_PARTYMODE_H_ */
#endif

