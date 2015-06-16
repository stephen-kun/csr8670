/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

/*!
@file    sink_peer.h
@brief   Interface to the Peer device functionality. 
*/

#ifndef _SINK_PEER_H_
#define _SINK_PEER_H_

#include <bdaddr.h>

typedef enum
{
    PEER_PAIRING_MODE_TEMPORARY,
    PEER_PAIRING_MODE_NORMAL,
    PEER_PAIRING_MODE_PERMANENT
} PeerPairingMode;

typedef enum
{
    RELAY_SOURCE_NULL,      /* There is no source active that is providing audio to be relayed */
    RELAY_SOURCE_ANALOGUE,  /* Wired analogue is acting as the source for relayed audio data */
    RELAY_SOURCE_USB,       /* USB is acting as the source for relayed audio data */
    RELAY_SOURCE_A2DP       /* Bluetooth AV Source, i.e. an AG, is acting as the source for relayed audio data */
} RelaySource;

typedef enum
{
    RELAY_STATE_IDLE,
    RELAY_STATE_CLOSING,
    RELAY_STATE_OPENING,
    RELAY_STATE_OPEN,
    RELAY_STATE_SUSPENDING,
    RELAY_STATE_STARTING,
    RELAY_STATE_STREAMING
} RelayState;

typedef enum
{
    RELAY_EVENT_DISCONNECTED,
    RELAY_EVENT_CONNECTED,
    RELAY_EVENT_CLOSED,
    RELAY_EVENT_OPEN,
    RELAY_EVENT_OPENING,
    RELAY_EVENT_NOT_OPENED,
    RELAY_EVENT_OPENED,
    RELAY_EVENT_CLOSE,
    RELAY_EVENT_SUSPENDED,
    RELAY_EVENT_START,
    RELAY_EVENT_STARTING,
    RELAY_EVENT_NOT_STARTED,
    RELAY_EVENT_STARTED,
    RELAY_EVENT_SUSPEND
} RelayEvent;

typedef enum
{
    PEER_STATUS_CHANGE_CALL_INACTIVE     = 0x01,
    PEER_STATUS_CHANGE_CALL_ACTIVE       = 0x02,
    PEER_CALL_STATUS_CHANGE              = 0x03,
    PEER_STATUS_CHANGE_RELAY_UNAVAILABLE = 0x04,
    PEER_STATUS_CHANGE_RELAY_AVAILABLE   = 0x08,
    PEER_RELAY_STATUS_CHANGE             = 0x0C,
    PEER_STATUS_CHANGE_RELAY_CLAIMED     = 0x10,
    PEER_STATUS_CHANGE_RELAY_FREED       = 0x20,
    PEER_RELAY_OWNERSHIP_CHANGE          = 0x30
} PeerStatusChange;

typedef enum
{
    PEER_STATUS_IN_CALL    = 0x01,
    PEER_STATUS_DONT_RELAY = 0x02,
    PEER_STATUS_OWNS_RELAY = 0x04,
    PEER_STATUS_POWER_OFF = 0x08
} PeerStatus;

typedef enum
{
    PEER_TWS_ROUTING_STEREO,
    PEER_TWS_ROUTING_LEFT,
    PEER_TWS_ROUTING_RIGHT,
    PEER_TWS_ROUTING_DMIX
} PeerTwsAudioRouting;

typedef enum
{
    PEER_TRIM_VOL_NO_CHANGE,
    PEER_TRIM_VOL_MASTER_UP ,
    PEER_TRIM_VOL_MASTER_DOWN,
    PEER_TRIM_VOL_SLAVE_UP,
    PEER_TRIM_VOL_SLAVE_DOWN
}PeerTrimVolChangeCmd;


#ifdef DEBUG_PEER_SM
#define PEER_UPDATE_REQUIRED_RELAY_STATE(str)  {DEBUG(("----\nPEER: Update[%s]\n",str)); peerUpdateRequiredRelayState();}
#else
#define PEER_UPDATE_REQUIRED_RELAY_STATE(str)  {peerUpdateRequiredRelayState();}
#endif

/*************************************************************************
NAME    
    RequestRemotePeerServiceRecord
    
DESCRIPTION
    Issues a request to obtain the attributes of a Peer Device SDP record from
    the specified device

RETURNS
    TRUE if a search requested, FALSE otherwise
    
**************************************************************************/
bool RequestRemotePeerServiceRecord (const bdaddr *bd_addr);

/*************************************************************************
NAME    
    GetCompatibleRemotePeerFeatures
    
DESCRIPTION
    Identifies the set of compatible features based on locally supported peer features 
    and the remote features obtained from a Peer during a Peer Device SDP record search 
    request.
    The compatible features are a set of mutually matching features i.e. if the local device
    supports a tws source role then the compatible feature would be the Peer supporting a tws
    sink role.

RETURNS
    The compatible set of features of the connected Peer
    
**************************************************************************/
remote_features GetCompatibleRemotePeerFeatures (const uint8 *attr_data, uint16 attr_data_size);

/*************************************************************************
NAME    
    RegisterPeerDeviceServiceRecord
    
DESCRIPTION
    Registers a Peer Device SDP record

RETURNS
    None
    
**************************************************************************/
void RegisterPeerDeviceServiceRecord ( void );

/*************************************************************************
NAME    
    peerGetSource
    
DESCRIPTION
    Obtains the currently configured source

RETURNS
    Current source
    
**************************************************************************/
RelaySource peerGetSource (void);

/*************************************************************************
NAME    
    peerSetSource
    
DESCRIPTION
    Sets the current source to use for relaying audio

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool peerSetSource (RelaySource src);

/*************************************************************************
NAME    
    peerGetPeerSink
    
DESCRIPTION
    Obtains sink to relay channel

RETURNS
    Handle to relay channel, NULL otherwise
    
**************************************************************************/
Sink peerGetPeerSink (void);

/*************************************************************************
NAME    
    peerGetSourceSink
    
DESCRIPTION
    Obtains sink of the current source

RETURNS
    Handle to sink if there is a current streaming source, NULL otherwise
    
**************************************************************************/
Sink peerGetSourceSink (void);

/*************************************************************************
NAME    
    peerAdvanceRelayState
    
DESCRIPTION
    Updates the Peer state machine current state based on the supplied event.
    This function should be called when an event occurs that would cause a change to
    the actual Peer state machine status.
    
    This forms one of the two functions that should be used to drive the Peer state machine.

RETURNS
    None
    
**************************************************************************/
void peerAdvanceRelayState (RelayEvent relay_event);

/*************************************************************************
NAME    
    peerUpdateRequiredRelayState
    
DESCRIPTION
    Used to update the Peer state machine required state.  This should be called when any event occurs
    that would cause a change to the required streaming state or source.
    
    This forms one of the two functions that should be used to drive the Peer state machine.

RETURNS
    None
    
**************************************************************************/
void peerUpdateRequiredRelayState (void);

/*************************************************************************
NAME    
    peerIsRelayAvailable
    
DESCRIPTION
    Determines if relay channel is available for use

RETURNS
    TRUE if relay available, FALSE otherwise
    
**************************************************************************/
bool peerIsRelayAvailable (void);

/*************************************************************************
NAME    
    peerCheckSource
    
DESCRIPTION
    Determines if the provided source can be relayed

RETURNS
    TRUE if relay available, FALSE otherwise
    
**************************************************************************/

bool peerCheckSource(RelaySource new_source);

/*************************************************************************
NAME    
    peerUpdateLocalStatusChange
    
DESCRIPTION
    Updates the local relay availability and issues a status change to a connected Peer

RETURNS
    None
    
**************************************************************************/
void peerUpdateLocalStatusChange (PeerStatusChange peer_status_change);

/*************************************************************************
NAME    
    peerHandleStatusChangeCmd
    
DESCRIPTION
    Handles a relay availability status change from a Peer

RETURNS
    None
    
**************************************************************************/
void peerHandleStatusChangeCmd (PeerStatusChange peer_status_change);

/*************************************************************************
NAME    
    peerHandleAudioRoutingCmd
    
DESCRIPTION
    Hamdles a audio routing notification from a Peer

RETURNS
    None
    
**************************************************************************/
void peerHandleAudioRoutingCmd (PeerTwsAudioRouting master_routing_mode, PeerTwsAudioRouting slave_routing_mode);

/*************************************************************************
NAME    
    peerHandleVolumeCmd
    
DESCRIPTION
    Handle a volume change notification from a Peer

RETURNS
    None
    
**************************************************************************/
void peerHandleVolumeCmd (uint8 volume);

/*************************************************************************
NAME    
    peerUpdateMasterTrimVolume
    
DESCRIPTION
    Handle a trim volume change notification from a Peer : TWS slave

RETURNS
    None
    
**************************************************************************/
void peerUpdateTrimVolume(PeerTrimVolChangeCmd cmd);

/*************************************************************************
NAME    
    peerUpdateMasterTrimVolume
    
DESCRIPTION
   Sends the appropriate trim volume change command to the master peer device.

RETURNS
    None
    
**************************************************************************/
void peerSendDeviceTrimVolume(uint16 index , volume_direction dir, tws_device_type tws_device);

/*************************************************************************
NAME    
    peerSendAudioEnhancements
    
DESCRIPTION
    Sends audio enhancement setting to currently connected Peer

RETURNS
    None
    
**************************************************************************/
void peerSendAudioEnhancements(void);

/*************************************************************************
NAME    
    peerSendEqSettings
    
DESCRIPTION
    Sends DSP EQ setting to currently connected Peer

RETURNS
    None
    
**************************************************************************/
void peerSendUserEqSettings(void);

/*************************************************************************
NAME    
    peerRequestUserEqSetings
    
DESCRIPTION
    Request current DSP EQ setting from the connected Peer (Master)

RETURNS
    None
    
**************************************************************************/
void peerRequestUserEqSetings(void);

/*************************************************************************
NAME    
    peerConnectPeer
    
DESCRIPTION
    Attempts to connect a TWS Peer, if not already in a Peer session

RETURNS
    TRUE if a connection is attempted, FALSE otherwise
    
**************************************************************************/
bool peerConnectPeer (void);

/*************************************************************************
NAME    
    peerObtainPairingMode
    
DESCRIPTION
    Obtains the pairing mode used for the currently connected Peer device

RETURNS
    None
    
**************************************************************************/
PeerPairingMode peerObtainPairingMode (uint16 peer_id);

/*************************************************************************
NAME    
    peerUpdatePairing
    
DESCRIPTION
    Ensures permanent pairing data is updated

RETURNS
    None
    
**************************************************************************/
void peerUpdatePairing (uint16 peer_id, void *peer_attributes);

/*************************************************************************
NAME    
    peerInitPeerStatus
    
DESCRIPTION
    Inits peer data structure and sets the initial required state

RETURNS
    None
    
**************************************************************************/
void peerInitPeerStatus (void);

/*************************************************************************
NAME    
    peerHandleRemoteAGConnected
    
DESCRIPTION
    Checks if the sink device is already connected to an AG with the same bd address as the one connected to the peer,
    if yes, then disconnect the local AG connected if the bd addr of the sink device is lower than that of peer.

RETURNS
    None
    
**************************************************************************/
void peerHandleRemoteAgConnected (void);

/*************************************************************************
NAME    
    compareBdAddr
    
DESCRIPTION
    Compares the first and the second bdaddr.
RETURNS
    TRUE if the first bd addr is greater than second, otherwise returns FALSE.
    
**************************************************************************/
bool peerCompareBdAddr(const bdaddr* first , const bdaddr* second);



#endif
