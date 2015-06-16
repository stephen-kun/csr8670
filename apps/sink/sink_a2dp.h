/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
*/

/*!
@file    sink_a2dp.h
@brief   Interface to the a2dp profile initialisation functions. 
*/

#ifndef _SINK_A2DP_INIT_H_
#define _SINK_A2DP_INIT_H_


#include <csr_a2dp_decoder_common_plugin.h>
#include "sink_private.h"
#include "sink_peer.h"
#include <a2dp.h>

/* Local stream end point codec IDs */
#define SOURCE_SEID_MASK        0x20        /*!< @brief Combined with a SEP codec id to produce an id for source codecs */
#define TWS_SEID_MASK			0x10		/*!< @brief Combined with a SEP codec id to produce an id for TWS codecs */
#define BASE_SEID_MASK			0x0F		/*!< @brief Mask used to determine base codec SEID, masking away any SOURCE or TWS bits */
#define INVALID_SEID            0x00        /*!< @brief A seid is a 6 bit non-zero value */
#define SBC_SEID                0x01        /*!< @brief Local Stream End Point ID for SBC codec */
#define MP3_SEID                0x02        /*!< @brief Local Stream End Point ID for MP3 codec */
#define AAC_SEID                0x03        /*!< @brief Local Stream End Point ID for AAC codec */
#define APTX_SEID               0x05        /*!< @brief Local Stream End Point ID for aptX codec */
#ifdef INCLUDE_FASTSTREAM
#define FASTSTREAM_SEID         0x04        /*!< @brief Local Stream End Point ID for FastStream codec */
#endif
#ifdef INCLUDE_APTX_ACL_SPRINT
#define APTX_SPRINT_SEID        0x06        /*!< @brief Local Stream End Point ID for aptX Sprint codec */
#endif


/* The bits used to enable codec support for A2DP, as read from CONFIG_CODEC_ENABLED */
#define SBC_CODEC_BIT           0xFF        /*!< @brief SBC is mandatory and always enabled */
#define MP3_CODEC_BIT           0           /*!< @brief Bit used to enable MP3 codec in PSKEY */
#define AAC_CODEC_BIT           1           /*!< @brief Bit used to enable AAC codec in PSKEY */
#define FASTSTREAM_CODEC_BIT    2           /*!< @brief Bit used to enable FastStream codec in PSKEY */
#define APTX_CODEC_BIT          3           /*!< @brief Bit used to enable aptX codec in PSKEY */
#define APTX_SPRINT_CODEC_BIT   4           /*!< @brief Bit used to enable aptX LL codec in PSKEY */

#define KALIMBA_RESOURCE_ID     1           /*!< @brief Resource ID for Kalimba */

/* Bits used to select which DAC channel is used to render audio, as read from CONFIG_FEATURE_BLOCK */


typedef enum
{
    a2dp_primary = 0x00,
    a2dp_secondary = 0x01,
    a2dp_pri_sec = 0x02,
    a2dp_invalid = 0xff
} a2dp_link_priority;

#define A2DP_DEVICE_ID(x) (theSink.a2dp_link_data ? theSink.a2dp_link_data->device_id[x] : 0)
#define for_all_a2dp(idx)      for((idx) = 0; (idx) < MAX_A2DP_CONNECTIONS; (idx)++)

typedef enum
{
    a2dp_not_suspended,
    a2dp_local_suspended,
    a2dp_remote_suspended
} a2dp_suspend_state;


#ifdef ENABLE_AVRCP
typedef enum
{
    avrcp_support_unknown,
    avrcp_support_second_attempt,
    avrcp_support_unsupported,
    avrcp_support_supported
} avrcpSupport;
#endif

typedef struct
{
    a2dp_link_priority priority;
} EVENT_STREAM_ESTABLISH_T;

typedef enum
{
    LR_UNKNOWN_ROLE,
    LR_CURRENT_ROLE_SLAVE,
    LR_CURRENT_ROLE_MASTER,
    LR_CHECK_ROLE_PENDING_START_REQ
} a2dp_link_role;

typedef struct
{
#ifdef ENABLE_AVRCP
    avrcpSupport       avrcp_support:2;
#else
    unsigned           unused:2;
#endif    
    unsigned           connected:1;
    unsigned           media_reconnect:1;
    remote_device      peer_device:2;
    a2dp_suspend_state SuspendState:2;
    unsigned seid:8;
    unsigned device_id:8;
    unsigned stream_id:8;
    unsigned list_id:8;
    unsigned gAvVolumeLevel:8;
    unsigned av_source:8;
    uint16 clockMismatchRate;
    bdaddr bd_addr;
} a2dp_instance_data;

/* TODO: Optimise memory usage */
typedef struct
{
    bool remote_connection;                                             
    bool connected[MAX_A2DP_CONNECTIONS];                           /* :1 */
    bool media_reconnect[MAX_A2DP_CONNECTIONS];                     /* :1 */
    bool micMuted[MAX_A2DP_CONNECTIONS];                            /* :1 */
#ifdef PEER_SCATTERNET_DEBUG   /* Scatternet debugging only */
    bool invert_ag_role[MAX_A2DP_CONNECTIONS];                      /* :1 */
#endif
    remote_features peer_features[MAX_A2DP_CONNECTIONS];            /* :4 */
    remote_device peer_device[MAX_A2DP_CONNECTIONS];                /* :2 */
    PeerStatus local_peer_status[MAX_A2DP_CONNECTIONS];             /* :2 */
    PeerStatus remote_peer_status[MAX_A2DP_CONNECTIONS];            /* :2 */
    bool playing[MAX_A2DP_CONNECTIONS];                             /* :1 */
    a2dp_link_role link_role[MAX_A2DP_CONNECTIONS];                 /* :2 */
    a2dp_suspend_state SuspendState[MAX_A2DP_CONNECTIONS];          /* :2 */
    uint16 av_source[MAX_A2DP_CONNECTIONS];                         /* :2 */
    uint16 device_id[MAX_A2DP_CONNECTIONS];                         /* :3 */
    uint16 stream_id[MAX_A2DP_CONNECTIONS];                         /* :1 */
    uint16 seid[MAX_A2DP_CONNECTIONS];                              /* :6 */
	uint16 latency[MAX_A2DP_CONNECTIONS];                           /* :16 */
    uint8 list_id[MAX_A2DP_CONNECTIONS];                            /* :8 */
    bdaddr bd_addr[MAX_A2DP_CONNECTIONS];
    uint16 clockMismatchRate[MAX_A2DP_CONNECTIONS];                 /* :16 */
#ifdef ENABLE_AVRCP
    avrcpSupport avrcp_support[MAX_A2DP_CONNECTIONS];               /* :2 */
#endif
    A2dpPluginConnectParams  a2dp_audio_connect_params;
    A2dpPluginModeParams     a2dp_audio_mode_params;

}a2dp_data;

/****************************************************************************
  FUNCTIONS
*/

/*************************************************************************
NAME    
    a2dpGetPeerIndex
    
DESCRIPTION
    Attempts to obtain the index into a2dp_link_data structure for a currently 
    connected Peer device.
    
RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool a2dpGetPeerIndex (uint16* Index);

/*************************************************************************
NAME    
    a2dpGetSourceIndex
    
    Attempts to obtain the index into a2dp_link_data structure for a currently 
    connected A2dp Source device.
    
RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool a2dpGetSourceIndex (uint16* Index);

/*************************************************************************
NAME    
    a2dpGetSourceSink
    
DESCRIPTION
    Attempts to obtain the media sink for a currently connected A2dp Source.

RETURNS
    Handle to media sink if present, NULL otherwise
    
**************************************************************************/
Sink a2dpGetSourceSink (void);

/*************************************************************************
NAME    
    sinkA2dpHandlePeerAvrcpConnectCfm
    
DESCRIPTION
    Configure initial relay availability when a Peer connects

RETURNS
    None
    
**************************************************************************/
void sinkA2dpHandlePeerAvrcpConnectCfm (uint16 peer_id, bool successful);

/****************************************************************************
NAME    
    sinkA2dpSetLinkRole
    
DESCRIPTION
    Updates stored BT role for specified device

RETURNS
    None
    
**************************************************************************/
void sinkA2dpSetLinkRole (Sink sink, hci_role role);

/*************************************************************************
NAME    
    sinkA2dpSetPeerAudioRouting
    
DESCRIPTION
    Informs current Peer of the required routing modes and updates DSP

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool sinkA2dpSetPeerAudioRouting (PeerTwsAudioRouting master_routing_mode, PeerTwsAudioRouting slave_routing_mode);

/*************************************************************************
NAME    
    a2dpSetSuspendState
    
DESCRIPTION
    Sets the suspend state for the specified device

RETURNS
    None
    
**************************************************************************/
void a2dpSetSuspendState (uint16 id, uint16 state);

/*************************************************************************
NAME    
    a2dpPauseNonRoutedSource
    
DESCRIPTION
    Check whether the a2dp connection is present and streaming data and that the audio is routed, 
    if thats true then pause/stop the incoming stream corresponding to the input deviceId.

RETURNS
    None
    
**************************************************************************/
#ifdef ENABLE_AVRCP
    void a2dpPauseNonRoutedSource(uint16 id);
#endif

/*************************************************************************
NAME    
    a2dpIssuePeerOpenRequest
    
DESCRIPTION
    Issues a request to opens a media stream to a currently connected Peer
    
RETURNS
    TRUE if request issued, FALSE otherwise
    
**************************************************************************/
bool a2dpIssuePeerOpenRequest (void);

/*************************************************************************
NAME    
    a2dpIssuePeerCloseRequest
    
DESCRIPTION
    Issues a request to close the relay channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise

**************************************************************************/
bool a2dpIssuePeerCloseRequest (void);

/*************************************************************************
NAME    
    a2dpIssuePeerStartRequest
    
DESCRIPTION
    Issues a request to start the relay channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise

**************************************************************************/
bool a2dpIssuePeerStartRequest (void);

/*************************************************************************
NAME    
    a2dpIssuePeerSuspendRequest
    
DESCRIPTIONDESCRIPTION
    Issues a request to suspend the relay channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise

**************************************************************************/
bool a2dpIssuePeerSuspendRequest (void);

/*************************************************************************
NAME    
    a2dpIssuePeerStartResponse
    
DESCRIPTION
    Issues a start response to a Peer based on availability of the relay channel

RETURNS
    TRUE if response sent, FALSE otherwise
    
**************************************************************************/
bool a2dpIssuePeerStartResponse (void);

/****************************************************************************
NAME 
 a2dpCheckDeviceTrimVol

DESCRIPTION
 check whether any a2dp connections are present and if these are currently active
 and routing audio to the device, if that is the case adjust the trim volume up or down
 as appropriate

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
***************************************************************************/
bool a2dpCheckDeviceTrimVol (volume_direction dir, tws_device_type tws_device);

/*************************************************************************
NAME    
    a2dpSetPlayingState
    
DESCRIPTION
    Logs the current AVRCP play status for the specified A2DP connection and
    updates the Suspend State for the Media channel so that it reflects the true
    media playing status.

RETURNS
    None
    
**************************************************************************/
void a2dpSetPlayingState (uint16 id, bool playing);

/*************************************************************************
NAME    
    InitA2dp
    
DESCRIPTION
    This function initialises the A2DP library.
*/
void InitA2dp(void);

/*************************************************************************
NAME    
    getA2dpIndex
    
DESCRIPTION
    This function tries to find a device id match in the array of a2dp links 
    to that device id passed in

RETURNS
    match status of true or false
**************************************************************************/
bool getA2dpIndex(uint16 DeviceId, uint16 * Index);

/*************************************************************************
NAME    
    getA2dpIndexFromSink
    
DESCRIPTION
    This function tries to find the a2dp device associated with the supplied 
    sink.  The supplied sink can be either a signalling or media channel.

RETURNS
    match status of true or false
**************************************************************************/
bool getA2dpIndexFromSink(Sink sink, uint16 * Index);

/*************************************************************************
NAME    
    getA2dpIndexFromPlugin
    
DESCRIPTION
    This function tries to find the a2dp device associated with the supplied 
    audio plugin.

RETURNS
    match status of true or false
**************************************************************************/
bool getA2dpIndexFromPlugin(Task audio_plugin, uint16 * Index);

/*************************************************************************
NAME    
    InitSeidConnectPriority
    
DESCRIPTION
    Retrieves a list of the preferred Stream End Points to connect with.
*/
uint16 InitSeidConnectPriority(uint8 seid, uint8 *seid_list);


/*************************************************************************
NAME    
    getA2dpStreamData
    
DESCRIPTION
    Function to retreive media sink and state for a given A2DP source

RETURNS
    void
**************************************************************************/
void getA2dpStreamData(a2dp_link_priority priority, Sink* sink, a2dp_stream_state* state);


/*************************************************************************
NAME    
    getA2dpStreamRole
    
DESCRIPTION
    Function to retreive the role (source/sink) for a given A2DP source

RETURNS
    void
**************************************************************************/
void getA2dpStreamRole(a2dp_link_priority priority, a2dp_role_type* role);


/*************************************************************************
NAME    
    getA2dpPlugin
    
DESCRIPTION
    Retrieves the audio plugin for the requested SEP.
*/
Task getA2dpPlugin(uint8 seid);

/****************************************************************************
NAME    
    sinkA2dpInitComplete
    
DESCRIPTION
    Headset A2DP initialisation has completed, check for success. 

RETURNS
    void
**************************************************************************/
void sinkA2dpInitComplete(const A2DP_INIT_CFM_T *msg);

/****************************************************************************
NAME    
    issueA2dpSignallingConnectResponse
    
DESCRIPTION
    Issue response to a signalling channel connect request, following discovery of the 
    remote device type. 

RETURNS
    void
**************************************************************************/
void issueA2dpSignallingConnectResponse(const bdaddr *bd_addr);

/*************************************************************************
NAME    
    handleA2DPSignallingConnectInd
    
DESCRIPTION
    handle a signalling channel connect indication

RETURNS
    
**************************************************************************/
void handleA2DPSignallingConnectInd(uint16 DeviceId, bdaddr SrcAddr);

/*************************************************************************
NAME    
    handleA2DPSignallingConnected
    
DESCRIPTION
    handle a successfull confirm of a signalling channel connected

RETURNS
    
**************************************************************************/
void handleA2DPSignallingConnected(a2dp_status_code status, uint16 DeviceId, bdaddr SrcAddr, bool locally_initiated);

/*************************************************************************
NAME    
    connectA2dpStream
    
DESCRIPTION
    Issues a request to the A2DP library to establish a media stream to a
    remote device.  The request can be delayed by a certain amount of time 
    if required.

RETURNS
    
**************************************************************************/
void connectA2dpStream (a2dp_link_priority priority, uint16 delay);

/*************************************************************************
NAME    
    handleA2DPOpenInd
    
DESCRIPTION
    handle an indication of an media channel open request, decide whether 
    to accept or reject it

RETURNS
    
**************************************************************************/
void handleA2DPOpenInd(uint16 DeviceId, uint8 seid);

/*************************************************************************
NAME    
    handleA2DPOpenCfm
    
DESCRIPTION
    handle a successfull confirm of a media channel open

RETURNS
    
**************************************************************************/
void handleA2DPOpenCfm(uint16 DeviceId, uint16 StreamId, uint8 seid, a2dp_status_code status);

/*************************************************************************
NAME    
    handleA2DPSignallingDisconnected
    
DESCRIPTION
    handle the disconnection of the signalling channel
RETURNS
    
**************************************************************************/
void handleA2DPSignallingDisconnected(uint16 DeviceId, a2dp_status_code status,  bdaddr SrcAddr);

/*************************************************************************
NAME    
    handleA2DPSignallingLinkloss
    
DESCRIPTION
    handle the indication of a link loss
RETURNS
    
**************************************************************************/
void handleA2DPSignallingLinkloss(uint16 DeviceId);

/*************************************************************************
NAME    
    handleA2DPStartInd
    
DESCRIPTION
    handle the indication of media start ind
RETURNS
    
**************************************************************************/
void handleA2DPStartInd(uint16 DeviceId, uint16 StreamId);

/*************************************************************************
NAME    
    handleA2DPStartStreaming
    
DESCRIPTION
    handle the indication of media start cfm
RETURNS
    
**************************************************************************/
void handleA2DPStartStreaming(uint16 DeviceId, uint16 StreamId, a2dp_status_code status);

/*************************************************************************
NAME    
    handleA2DPSuspendStreaming
    
DESCRIPTION
    handle the indication of media suspend from either the ind or the cfm
RETURNS
    
**************************************************************************/
void handleA2DPSuspendStreaming(uint16 DeviceId, uint16 StreamId, a2dp_status_code status);


/*************************************************************************
NAME    
    handleA2DPStoreClockMismatchRate
    
DESCRIPTION
    handle storing the clock mismatch rate for the active stream
RETURNS
    
**************************************************************************/
void handleA2DPStoreClockMismatchRate(uint16 clockMismatchRate);


/*************************************************************************
NAME    
    handleA2DPStoreCurrentEqBank
    
DESCRIPTION
    handle storing the current EQ bank
RETURNS
    
**************************************************************************/
void handleA2DPStoreCurrentEqBank(uint16 clockMismatchRate);


/* TODO - index below should be a2dp_link_priority not uint8.  */

/*************************************************************************
NAME    
    SuspendA2dpStream
    
DESCRIPTION
    called when it is necessary to suspend an a2dp media stream due to 
    having to process a call from a different AG 
RETURNS
    
**************************************************************************/
void SuspendA2dpStream(a2dp_link_priority priority);
        

/*************************************************************************
NAME    
    ad2pSuspended
    
DESCRIPTION
    Helper to indicate whether A2DP is suspended on given source
RETURNS
    TRUE if A2DP suspended, otherwise FALSE
**************************************************************************/
a2dp_suspend_state a2dpSuspended(a2dp_link_priority priority);


/*************************************************************************
NAME    
    ResumeA2dpStream
    
DESCRIPTION
    Called to resume a suspended A2DP stream
RETURNS
    
**************************************************************************/
void ResumeA2dpStream(a2dp_link_priority priority, a2dp_stream_state state, Sink sink);



#ifdef ENABLE_AVRCP
bool getA2dpVolume(const bdaddr *bd_addr, uint16 *a2dp_volume);


bool setA2dpVolume(const bdaddr *bd_addr, uint16 a2dp_volume);
#endif


/*************************************************************************
NAME    
    handleA2DPSyncDelayInd
    
DESCRIPTION
	Handle request from A2DP library for a Sink device to supply an initial
	Synchronisation Delay (audio latency) report.

RETURNS
    
**************************************************************************/
void handleA2DPSyncDelayInd (uint16 device_id, uint8 seid);

/*************************************************************************
NAME    
    handleA2DPLatencyReport
    
DESCRIPTION
	Handle notification from an audio plugin raised due to the DSP providing
	a measured audio latency value.

RETURNS
    
**************************************************************************/
void handleA2DPLatencyReport (Task audio_plugin, bool estimated, uint16 latency);

/*************************************************************************
NAME    
    handleA2DPMessage
    
DESCRIPTION
    A2DP message Handler, this function handles all messages returned
    from the A2DP library and calls the relevant functions if required

RETURNS
    
**************************************************************************/
void handleA2DPMessage( Task task, MessageId id, Message message );

/*************************************************************************
NAME    
    getA2dpIndexFromBdaddr
    
DESCRIPTION
    Attempts to find a A2DP link data index based on the supplied bdaddr.
    
RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool getA2dpIndexFromBdaddr (const bdaddr *bd_addr, uint16 *index);

/*************************************************************************
NAME    
    disconnectAllA2dpAVRCP
    
DESCRIPTION
    disconnect any a2dp and avrcp connections
    
RETURNS
    
**************************************************************************/
void disconnectAllA2dpAvrcp (bool disconnect_peer);

/*************************************************************************
NAME    
    disconnectAllA2dpPeerDevices
    
DESCRIPTION
    disconnect any a2dp connections to any peer devices
    
RETURNS
    TRUE is any peer devices disconnected, FALSE otherwise
    
**************************************************************************/
bool disconnectAllA2dpPeerDevices (void);

/*************************************************************************
NAME    
    handleA2DPStoreEnhancments
    
DESCRIPTION
    handle storing the current enhancements settings
RETURNS
    
**************************************************************************/
void handleA2DPStoreEnhancements(uint16 enhancements);

/*************************************************************************
 NAME    
    handleA2DPUserEqBankUpdate
    
DESCRIPTION
	Handle notification from an audio plugin for DSP ready for data message in order to update user defined EQ bank 
    when GAIA set EQ parameter commands are processed

RETURNS 
**************************************************************************/
void handleA2DPUserEqBankUpdate(void);

/*************************************************************************
NAME    
    findCurrentA2dpSource
    
DESCRIPTION
    Attempts to obtain index of a connected A2dp Source that has established
    a media channel

RETURNS
    TRUE if found, FALSE otherwise

**************************************************************************/
bool findCurrentA2dpSource (a2dp_link_priority* priority);

/*************************************************************************
NAME    
    controlA2DPPeer
    
DESCRIPTION
    Issues AVDTP Start/Suspend command to current Peer device
    
RETURNS
    FALSE if no appropriate Peer device found
    TRUE if a command was issued
**************************************************************************/

bool controlA2DPPeer (uint16 event);

#if defined(ENABLE_SOUNDBAR) && defined(ENABLE_SUBWOOFER)
/*************************************************************************
NAME    
    suspendWhenSubwooferStreamingLowLatency
    
DESCRIPTION
    funnction to determine if a2dp stream should be suspended due to the use
    of the low latency subwoofer link. Streaming a2dp media will adversely affect
    the quality of the sub low latency link due to bluetooth link bandwidth 
    limitations

RETURNS
    none
    
**************************************************************************/
void suspendWhenSubwooferStreamingLowLatency(uint16 Id);
#endif

#endif /* _SINK_A2DP_INIT_H_ */


