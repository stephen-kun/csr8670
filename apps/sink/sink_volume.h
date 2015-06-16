/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_volume.h
    
DESCRIPTION

    
*/

#ifndef SINK_VOLUME_H
#define SINK_VOLUME_H


#include "sink_volume.h"

#include <hfp.h>

#define VOL_NUM_VOL_SETTINGS     (16)


typedef enum  
{
    increase_volume,
    decrease_volume,
    same_volume
}volume_direction;

typedef enum
{
    tws_none,
    tws_master,
    tws_slave
} tws_device_type;

/* Data structure type volume_info encapsulates run-time accessable/modifiable 
masterVolume and tonesVolume in levels matching relevant AVRCP volume levels*/ 
typedef struct
{
	int16 masterVolume;
	int16 tonesVolume;
}volume_info;

#define MAX_A2DP_CONNECTIONS        2        


typedef struct
{
    volume_info a2dp_volume[MAX_A2DP_CONNECTIONS];    /* An instance of data structure type volume_info for run-time access/modify puposes on A2DP & tones volume levels */
    volume_info analog_volume; 
    volume_info spdif_volume; 
    volume_info usb_volume; 
    volume_info fm_volume; 
}volume_levels_t;   
    
/* Send 0 for mute on, non-zero for mute off */
#define VOLUME_MUTE_ON        0
#define VOLUME_MUTE_OFF       10

#define VOLUME_A2DP_MIN_LEVEL 0
#define VOLUME_A2DP_MUTE_GAIN 0

#define VOLUME_HFP_MAX_LEVEL 15
#define VOLUME_HFP_MIN_LEVEL 0

#define VOLUME_FM_MAX_LEVEL 15
#define VOLUME_FM_MIN_LEVEL 0

#define DSP_DB_SCALE 60
#define DEVICE_TRIM_DB_SCALE 10

#define VOLUME_NUM_VOICE_STEPS 16

#define VOLUME_MUTE_DB -7200 /* mute level for master volume of -120dB */

/****************************************************************************
NAME
 volumeInit

DESCRIPTION
 malloc memory for storing of current volume levels for a2dp, usb, wired and fm
 interfaces

RETURNS
 none

*/
void volumeInit(void);

/****************************************************************************
NAME 
 VolumeSetA2dp
DESCRIPTION
    sets the current A2dp volume
    
RETURNS
 void
    
*/
void VolumeSetA2dp(uint16 index, uint16 oldVolume, bool pPlayTone);


/****************************************************************************
NAME 
 VolumeCheckA2dp

DESCRIPTION
 check whether any a2dp connections are present and if these are currently active
 and routing audio to the device, if that is the case adjust the volume up or down
 as appropriate

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
bool VolumeCheckA2dp(volume_direction dir);

/****************************************************************************
NAME 
 VolumeCheckA2dpMute

DESCRIPTION
 check whether any a2dp connections are at minimum volume and mutes them properly if they are

RETURNS
 bool   Returns true if stream muted
    
*/
bool VolumeCheckA2dpMute(void);


/****************************************************************************
NAME 
 VolumeSetHeadsetVolume

DESCRIPTION
 sets the internal speaker gain to the level corresponding to the phone volume level
    
RETURNS
 void
    
*/
void VolumeSetHeadsetVolume( uint16 pNewVolume , bool pPlayTone, hfp_link_priority priority );


/****************************************************************************
NAME 
 VolumeSendAndSetHeadsetVolume

DESCRIPTION
    sets the vol to the level corresponding to the phone volume level
    In addition - send a response to the AG indicating new volume level

RETURNS
 void
    
*/
void VolumeSendAndSetHeadsetVolume( uint16 pNewVolume , bool pPlayTone , hfp_link_priority priority );


/****************************************************************************
NAME 
    VolumeGet

DESCRIPTION
    Returns the absolute HFP volume level

RETURNS
    void
    
*/
uint16 VolumeGet(void);


/****************************************************************************
NAME 
    VolumeSet

DESCRIPTION
    Sets HFP volume to absolute level

RETURNS
    void
    
*/
void VolumeSet(uint16 level);


/****************************************************************************
NAME 
    VolumeCheck

DESCRIPTION
    Increase/Decrease volume

RETURNS
 void
    
*/
void VolumeCheck(volume_direction dir);


/****************************************************************************
NAME 
 VolumeCheckDeviceTrim

DESCRIPTION
 check for an active A2DP, Wired or USB streaming currently routing audio to the device and adjust the trim volume up or down
 as appropriate

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
bool VolumeCheckDeviceTrim(volume_direction dir, tws_device_type tws_device);

/****************************************************************************
NAME 
 VolumeUpdateDeviceTrim

DESCRIPTION
 Updates the trim volume changes locally in the device.

RETURNS
void
    
*/
void VolumeUpdateDeviceTrim(volume_direction dir, tws_device_type tws_device);

/****************************************************************************
NAME 
 VolumeHandleSpeakerGainInd

DESCRIPTION
 Handle speaker gain change indication from the AG

RETURNS
 void
    
*/
void VolumeHandleSpeakerGainInd(HFP_VOLUME_SYNC_SPEAKER_GAIN_IND_T* ind);

/****************************************************************************
NAME 
 VolumeUpdateMuteStatus

DESCRIPTION
 Set the mute state for the appropriate audio source currently being routed

RETURNS
 void
    
*/
void VolumeUpdateMuteStatus(bool OnOrOff);

/****************************************************************************
NAME 
 VolumeToggleMute

DESCRIPTION
 Toggles the mute state

RETURNS
 void
    
*/
void VolumeToggleMute( void );


/****************************************************************************
DESCRIPTION
    sends the current microphone volume to the AG on connection.
*/
void VolumeSendMicrophoneGain(hfp_link_priority priority, uint8 mic_gain);


/****************************************************************************
DESCRIPTION
    Set mute or unmute (mic gain of VOLUME_MUTE_ON - 0 is mute, all other 
    gain settings unmute).
*/
void VolumeSetMicrophoneGain(hfp_link_priority priority, uint8 mic_gain);


/****************************************************************************
DESCRIPTION
    Set mute or unmute remotely from AG if SyncMic feature bit is enabled
    (mic gain of VOLUME_MUTE_ON - 0 is mute, all other gain settings unmute).
*/
void VolumeSetMicrophoneGainCheckMute(hfp_link_priority priority, uint8 mic_gain);
        
/****************************************************************************
DESCRIPTION
    Determine whether the mute reminder tone should be played in the device, e.g. #
    if AG1 is in mute state but AG2 is not muted and is the active AG then the mute reminder
    tone will not be played, when AG1 becomes the active AG it will be heard.
*/
bool VolumePlayMuteToneQuery(void);

#endif

