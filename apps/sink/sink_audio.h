/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_audio.h
    
DESCRIPTION
    
*/

#ifndef _SINK_AUDIO_H_
#define _SINK_AUDIO_H_


#include "sink_private.h"

/* Linked-list structure for registering user implemented WBS codecs. */
typedef struct _audio_codec_plugin_info
{
    uint32      					bandwidth;			/* Codec audio paramters - bandwidth */
    uint16      					max_latency;		/* Codec audio paramters - max latency */
    uint16     	 					voice_settings;		/* Codec audio paramters - vioce settings */
    uint16      					retx_effort;		/* Codec audio paramters - re-transmission effort */
    uint16							packet_types;		/* Codec's supported packet types */
} audio_codec_plugin_info;

/* interval at which to check whether the audio amplifier can be turned off after playing a
   tone or a voice prompt, amplifier is turned off instantly when using the dsp to route
   call or a2dp audio */
#define CHECK_AUDIO_AMP_PIO_DRIVE_DELAY 2000

#ifdef DAC_ADC_LINK
/* ADC and DAC linked - force stereo if plugin is 2 mic */
#define AUDIO_PLUGIN_FORCE_STEREO (theSink.features.audio_plugin == 3 || theSink.features.audio_plugin == 4)
#else
/* ADC and DAC independant - no need to force stereo */
#define AUDIO_PLUGIN_FORCE_STEREO (FALSE)
#endif

typedef struct
{
    bdaddr bd_addr;
}UpdateAvrpcMessage_t;

/****************************************************************************
NAME    
    getScoPriorityFromHfpPriority
    
DESCRIPTION
    obtain the current sco priority level of the AG priority passed in

RETURNS
    current sco priority level, if any, may not have a sco
*/   
audio_priority getScoPriorityFromHfpPriority(hfp_link_priority priority);

/****************************************************************************
NAME    
    setScoPriorityFromHfpPriority
    
DESCRIPTION
    sets the current sco priority level of the AG priority passed in

RETURNS
    nothing
*/   
void setScoPriorityFromHfpPriority(hfp_link_priority priority, audio_priority level);

/****************************************************************************
NAME    
    audioGetLinkPriority
    
DESCRIPTION
	Common method of getting the link we want to manipulate audio settings on

RETURNS
    
*/
hfp_link_priority audioGetLinkPriority ( bool audio );



/****************************************************************************
NAME    
    audioSwapMediaChannel
    
DESCRIPTION
	attempt to swap between media channels if two channels exist and one of them
    is currentyl being routed to the speaker.
RETURNS
    successful or not status
*/
bool audioSwapMediaChannel(void);

/****************************************************************************
NAME    
    audioHandleSyncConnectInd
    
DESCRIPTION

RETURNS
    
*/
void audioHandleSyncConnectInd ( const HFP_AUDIO_CONNECT_IND_T *pInd );

/****************************************************************************
NAME    
    audioHandleSyncConnectInd
    
DESCRIPTION

RETURNS
    
*/
void audioHandleSyncConnectCfm ( const HFP_AUDIO_CONNECT_CFM_T * pCfm );

/****************************************************************************
NAME    
    audioHandleSyncConnectInd
    
DESCRIPTION

RETURNS
    
*/
void audioHandleSyncDisconnectInd ( const HFP_AUDIO_DISCONNECT_IND_T * pInd ) ;

/****************************************************************************
DESCRIPTION
    toggles a custom audio processing feature
*/
void audioToggleFeature1 ( void ) ;

/****************************************************************************
DESCRIPTION
    toggles a custom audio processing feature
*/
void audioToggleFeature2 ( void ) ;

/****************************************************************************
NAME    
    audioHfpGetPlugin
    
DESCRIPTION
	Get HFP plugin based on codec and index

RETURNS
    
*/
Task audioHfpGetPlugin(hfp_wbs_codec_mask codec, uint8 plugin);

/****************************************************************************
NAME    
    audioHfpConnectAudio
    
DESCRIPTION
	attempt to reconnect an audio connection from the sink value associcated 
    with the passed hfp instance

RETURNS
    
*/
void audioHfpConnectAudio ( hfp_link_priority priority, Sink sink);

/****************************************************************************
NAME    
    audioIndicateCodec
    
DESCRIPTION
    Sends an event to indicate which A2DP codec is in use

RETURNS
    void
*/
void audioIndicateCodec(uint8 seid);

/****************************************************************************
NAME    
    A2dpRouteAudio
    
DESCRIPTION
	attempt to connect an audio connection from a2dp device via the passed in 
    deviceID

RETURNS
    
*/
void A2dpRouteAudio(uint8 Index, Sink sink);

/****************************************************************************
NAME    
    audioHandleMicSwitch
    
DESCRIPTION
	Handle AT+MICTEST AT command from TestAg. 
    This command swaps between the two microphones to test 2nd mic in production.

RETURNS
    returns true if mic switch command issued to plugin
*/
bool audioHandleMicSwitch( void );

/****************************************************************************
NAME    
    sinkTransferToggle
    
DESCRIPTION
    If the audio is at the sink end transfer it back to the AG and
    vice versa.

RETURNS
    FALSE if an audio transfer to the AG has been initiated.
    TRUE otherwise.
*/
void sinkTransferToggle( uint16 eventId ) ;

/****************************************************************************
NAME    
    sinkCheckForAudioTransfer
    
DESCRIPTION
    checks on connection for an audio connction and performs a transfer if not present

RETURNS
    void
*/
void sinkCheckForAudioTransfer ( void ) ;

/****************************************************************************
NAME    
    audioControlLowPowerCodecs
    
DESCRIPTION
	Enables / disables the low power codecs. 
    will only use low power codecs is the flag UseLowPowerCodecs is set and 
    enable == TRUE
    
    This fn is called whenever an audioConnect occurs in order to select the 
    right codec ouptut stage power 

RETURNS
    none
*/
void audioControlLowPowerCodecs( bool enable  ) ;

/****************************************************************************
NAME    
    sinkAudioSetEnhancement
DESCRIPTION
    updates the current audio enhancement settings and updates the dsp if it
    is currently running and streaming a2dp music.

RETURNS
    void
*/
void sinkAudioSetEnhancement(uint16 enhancement, bool enable);

void CreateAudioConnection(void);

#endif 


