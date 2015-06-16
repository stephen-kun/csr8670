/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_audio.h

DESCRIPTION
    Handles audio routing.
    
*/


#ifndef _SOURCE_AUDIO_H_
#define _SOURCE_AUDIO_H_


/* profile/library headers */
#include <stream.h>
#include <audio_plugin_if.h>
#include <csr_a2dp_encoder_common_plugin.h>
#include <csr_ag_audio_plugin.h>
#include <pio.h>
#include <pio_common.h>


/* Indicates which audio is routed */
typedef enum
{
    AUDIO_ROUTED_NONE,
    AUDIO_ROUTED_A2DP,
    AUDIO_ROUTED_AGHFP
} AUDIO_ROUTED_T;

/* Indicates which audio mode is active (VOIP \ Music) */
typedef enum
{
    AUDIO_MUSIC_MODE,
    AUDIO_VOIP_MODE
} AUDIO_VOIP_MUSIC_MODE_T;


/* structure holding the Audio data */
typedef struct
{
    A2dpEncoderPluginConnectParams audio_a2dp_connect_params;    
    A2dpEncoderPluginModeParams audio_a2dp_mode_params;
    CsrAgAudioPluginConnectParams audio_aghfp_connect_params;
    CsrAgAudioPluginUsbParams ag_usb_params;
    Task audio_plugin;
    
    unsigned audio_routed:2;
    unsigned audio_usb_active:1;
    unsigned audio_a2dp_connection_delay:1;
    unsigned audio_aghfp_connection_delay:1;
    unsigned audio_voip_music_mode:2;
    unsigned audio_remote_bidir_support:1;
    unsigned unused:8;
} AUDIO_DATA_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    audio_plugin_msg_handler

DESCRIPTION
    Handles messages received from an audio plugin library. 

*/
void audio_plugin_msg_handler(Task task, MessageId id, Message message);


/****************************************************************************
NAME    
    audio_init

DESCRIPTION
    Initialises the audio section of code. 

*/
void audio_init(void);


/****************************************************************************
NAME    
    audio_a2dp_connect

DESCRIPTION
    Attempt to route the A2DP audio. 

*/
void audio_a2dp_connect(Sink sink, uint16 device_id, uint16 stream_id);


/****************************************************************************
NAME    
    audio_a2dp_disconnect

DESCRIPTION
    Attempt to disconnect the A2DP audio. 

*/
void audio_a2dp_disconnect(uint16 device_id, Sink media_sink);


/****************************************************************************
NAME    
    audio_a2dp_disconnect_all

DESCRIPTION
    Attempt to disconnect all active A2DP audio. 

*/
void audio_a2dp_disconnect_all(void);


/****************************************************************************
NAME    
    audio_a2dp_set_plugin

DESCRIPTION
    Set the A2DP audio plugin in use. 

*/
void audio_a2dp_set_plugin(uint8 seid);


/****************************************************************************
NAME    
    audio_set_voip_music_mode

DESCRIPTION
    Set the audio mode in use (VOIP \ MUSIC). 

*/
void audio_set_voip_music_mode(AUDIO_VOIP_MUSIC_MODE_T mode);


/****************************************************************************
NAME    
    audio_switch_voip_music_mode

DESCRIPTION
    Switch the audio mode in use (VOIP \ MUSIC). 

*/
void audio_switch_voip_music_mode(AUDIO_VOIP_MUSIC_MODE_T new_mode);


/****************************************************************************
NAME    
    audio_aghfp_connect

DESCRIPTION
    Attempt to route the AGHFP audio. 

*/
void audio_aghfp_connect(Sink sink, bool esco, bool wbs, uint16 size_warp, uint16 *warp);


/****************************************************************************
NAME    
    audio_aghfp_disconnect

DESCRIPTION
    Attempt to disconnect the AGHFP audio. 

*/
void audio_aghfp_disconnect(void);


/****************************************************************************
NAME    
    audio_route_all

DESCRIPTION
    Route audio for all active connections. 

*/
void audio_route_all(void);


/****************************************************************************
NAME    
    audio_suspend_all

DESCRIPTION
    Suspend audio for all active connections. 

*/
void audio_suspend_all(void);


/****************************************************************************
NAME    
    audio_start_active_timer

DESCRIPTION
    Starts the audio active timer in USB mode if the USB audio interfaces are inactive. 
    When the timer expires the Bluetooth audio links can be suspended as no USB audio will be active.

*/
void audio_start_active_timer(void);


/****************************************************************************
NAME    
    audio_a2dp_update_bitpool

DESCRIPTION
    Change the bitpool for the A2DP audio. 

*/
void audio_a2dp_update_bitpool(uint8 bitpool, uint8 bad_link_bitpool);


/****************************************************************************
NAME    
    audio_update_mode_parameters

DESCRIPTION
    The audio parameters have changed so update the audio mode. 

*/
void audio_update_mode_parameters(void);


#endif /* _SOURCE_AUDIO_H_ */
