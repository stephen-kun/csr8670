/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

FILE NAME
    sink_peer.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_a2dp.h"
#include "sink_configmanager.h"
#include "sink_devicemanager.h"
#include "sink_config.h"
#include "sink_wired.h"
#include "sink_usb.h"
#include "sink_slc.h"
#include "sink_auth.h"
#include "sink_peer.h"
#include "sink_avrcp.h"


#include <bdaddr.h>
#include <ps.h>
#include <panic.h>
#include <sdp_parse.h>
#include <stdlib.h>
#include <string.h>


#ifdef ENABLE_PEER

#ifdef DEBUG_PEER
    #define PEER_DEBUG(x) DEBUG(x)
#else
    #define PEER_DEBUG(x)
#endif

#ifdef DEBUG_PEER_SM
    #define PEER_SM_DEBUG(x) DEBUG(x)
    
static const char * av_source_str[] = 
{
    "SOURCE_NULL",
    "SOURCE_ANALOGUE",
    "SOURCE_USB",
    "SOURCE_A2DP"
};

static const char * relay_state_str[] = 
{
    "STATE_IDLE",
    "STATE_CLOSING",
    "STATE_OPENING",
    "STATE_OPEN",
    "STATE_SUSPENDING",
    "STATE_STARTING",
    "STATE_STREAMING"
};

static const char * relay_event_str[] = 
{
    "EVENT_DISCONNECTED",
    "EVENT_CONNECTED",
    "EVENT_CLOSED",
    "EVENT_OPEN",
    "EVENT_OPENING",
    "EVENT_NOT_OPENED",
    "EVENT_OPENED",
    "EVENT_CLOSE",
    "EVENT_SUSPENDED",
    "EVENT_START",
    "EVENT_STARTING",
    "EVENT_NOT_STARTED",
    "EVENT_STARTED",
    "EVENT_SUSPEND"
};

#else
    #define PEER_SM_DEBUG(x)
#endif


#define DATA_EL_UINT_16(value)  (((value)>>8)&0xFF),((value)&0xFF)

#define PEER_DEVICE_OFFSET_UUID128_ATTR_VAL     6
#define PEER_DEVICE_SERVICE_RECORD_SIZE        34


/* Supported features are those Peer features offered by the local device */
/* Compatible feature are those Peer features that need to be supported by the remote device in order to be available for use */
#ifdef PEER_AS
#define SUPPORTED_SHAREME_A2DP_FEATURES  (remote_features_shareme_a2dp_source | remote_features_shareme_a2dp_sink  )
#define COMPATIBLE_SHAREME_A2DP_FEATURES (remote_features_shareme_a2dp_sink   | remote_features_shareme_a2dp_source)
#else
#define SUPPORTED_SHAREME_A2DP_FEATURES  (0)
#define COMPATIBLE_SHAREME_A2DP_FEATURES (0)
#endif

#ifdef PEER_TWS
#define SUPPORTED_TWS_A2DP_FEATURES  (remote_features_tws_a2dp_source | remote_features_tws_a2dp_sink  )
#define COMPATIBLE_TWS_A2DP_FEATURES (remote_features_tws_a2dp_sink   | remote_features_tws_a2dp_source)
#else
#define SUPPORTED_TWS_A2DP_FEATURES  (0)
#define COMPATIBLE_TWS_A2DP_FEATURES (0)
#endif

#ifdef PEER_AVRCP
#define SUPPORTED_PEER_AVRCP_FEATURES  (remote_features_peer_avrcp_target     | remote_features_peer_avrcp_controller)
#define COMPATIBLE_PEER_AVRCP_FEATURES (remote_features_peer_avrcp_controller | remote_features_peer_avrcp_target    )
#else
#define SUPPORTED_PEER_AVRCP_FEATURES  (0)
#define COMPATIBLE_PEER_AVRCP_FEATURES (0)
#endif

#define PEER_DEVICE_UUID128 0x00, 0x00, 0x10, 0x02, 0xD1, 0x02, 0x11, 0xE1, 0x9B, 0x23, 0x00, 0x02, 0x5B, 0x00, 0xA5, 0xA5     /* CSR Peer Device service UUID */
#define PEER_DEVICE_SUPPORTED_FEATURES  (SUPPORTED_SHAREME_A2DP_FEATURES | SUPPORTED_TWS_A2DP_FEATURES | SUPPORTED_PEER_AVRCP_FEATURES)
#define PEER_DEVICE_COMPATIBLE_FEATURES (COMPATIBLE_SHAREME_A2DP_FEATURES | COMPATIBLE_TWS_A2DP_FEATURES | COMPATIBLE_PEER_AVRCP_FEATURES)
#define PEER_DEVICE_VERSION 0x0300  /* Version 3.00 */


static const uint8 peer_device_service_record_template[ PEER_DEVICE_SERVICE_RECORD_SIZE ] =
{
    /* DataElUint16, ServiceClassIDList(0x0001) */
    0x09, 0x00, 0x01,
        /* DataElSeq 17 bytes */
        0x35, 0x11,
            /* DataElUuid128, 128-bit (16 byte) UUID */
            0x1C, PEER_DEVICE_UUID128,
            
    /* DataElUint16, SupportedFeatures(0x0311) */
    0x09, 0x03, 0x11,
        /* DataElUint16, Supported Features Bitmask */
        0x09, DATA_EL_UINT_16(PEER_DEVICE_SUPPORTED_FEATURES),
        
    /* DataElUint16, Version(0x0200) */
    0x09, 0x02, 0x00,
        /* DataElUint16, Peer Device support version number */
        0x09, DATA_EL_UINT_16(PEER_DEVICE_VERSION)
};


/* DataElSeq(0x35), Length(0x11), 128-bit UUID(0x1C) */
static const uint8 peer_device_search_pattern[] = {0x35, 0x11, 0x1C, PEER_DEVICE_UUID128};
/* DataElSeq(0x35), Length(0x06), DataElUint16(0x09), SupportedFeatures(0x0311), DataElUint16(0x09), Version(0x0200) */
static const uint8 peer_device_attr_list[] = {0x35, 0x06, 0x09, 0x03, 0x11, 0x09, 0x02, 0x00};


/*************************************************************************
NAME    
    expandUuid128
    
DESCRIPTION
    Expands a 128-bit UUID stored as eight 16-bit words to sixteen 8-bit words

RETURNS
    TRUE if non zero UUID read from PS, FALSE otherwise
    
**************************************************************************/
static bool expandUuid128 (uint16 *uuid_base)
{
    bool non_zero = FALSE;
    uint16 *read_ptr = uuid_base + 8;
    uint16 *write_ptr = (uint16 *)(uuid_base + 16);
    
    while (--read_ptr >= uuid_base)
    {
        uint16 read_data = *read_ptr;
        
        PEER_DEBUG((" %X",read_data));
        
        *(--write_ptr) = (read_data & 0xFF);
        *(--write_ptr) = ((read_data >> 8) & 0xFF);
        
        if (read_data)
        {
            non_zero = TRUE;
        }
        
    }
    
    PEER_DEBUG(("   non_zero=%u\n",non_zero));
    return non_zero;
}


/*************************************************************************
NAME    
    RequestRemotePeerServiceRecord
    
DESCRIPTION
    Issues a request to obtain the attributes of a Peer Device SDP record from
    the specified device

RETURNS
    TRUE if a search requested, FALSE otherwise
    
**************************************************************************/
bool RequestRemotePeerServiceRecord (const bdaddr *bd_addr)
{
    if (theSink.features.PeerUseCsrUuid)
    {
        PEER_DEBUG(("Requesting PEER SDP record using CSR UUID\n"));
        ConnectionSdpServiceSearchAttributeRequest(&theSink.task, bd_addr, 32, sizeof(peer_device_search_pattern), peer_device_search_pattern, sizeof(peer_device_attr_list), peer_device_attr_list);
        return TRUE;
    }
    else
    {
        uint16 *search_pattern = (uint16 *)mallocPanic( sizeof(uint16) * sizeof(peer_device_search_pattern) );
    
        PsRetrieve(CONFIG_PEER_DEVICE_CUSTOM_UUID, &search_pattern[3], 8);    /* Get 128 bit UUID from PS */
        if ( expandUuid128((uint16 *)&search_pattern[3]) )
        {
            PEER_DEBUG(("Requesting PEER SDP record using custom UUID\n"));
            memcpy(search_pattern, peer_device_search_pattern, 3);          /* Get Data El Seq info from peer_device_search_pattern */
    
            ConnectionSdpServiceSearchAttributeRequest(&theSink.task, bd_addr, 32, sizeof(peer_device_search_pattern), (uint8 *)search_pattern, sizeof(peer_device_attr_list), peer_device_attr_list);
            return TRUE;
        }
        else
        {
            PEER_DEBUG(("Not requesting PEER SDP record\n"));
            free(search_pattern);
        }
    }
    
    return FALSE;
}


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
remote_features GetCompatibleRemotePeerFeatures (const uint8 *attr_data, uint16 attr_data_size)
{
    uint32 supported_features, version;
    uint16 compatible_features = remote_features_shareme_a2dp_sink & PEER_DEVICE_COMPATIBLE_FEATURES;   /* Minimally, we can expect a device to be a standard A2DP sink */
    
    PEER_DEBUG(("GetCompatibleRemotePeerFeatures\n"));
    
    if ( SdpParseGetArbitrary(attr_data_size, attr_data, 0x0311, &supported_features) &&
         SdpParseGetArbitrary(attr_data_size, attr_data, 0x0200, &version) )
    {
        PEER_DEBUG(("   features = %lX   version = %lX\n",supported_features,version));
        
        if (version == PEER_DEVICE_VERSION)
        {   /* Same peer version, so we can expect to support all A2DP and AVRCP features advertised */
            PEER_DEBUG(("   version matched\n"));
            compatible_features = supported_features & PEER_DEVICE_COMPATIBLE_FEATURES;
        }
        else
        {   /* ShareMe uses standard A2DP operation, thus ShareMe can be supported in one or more roles */
            compatible_features = supported_features & (remote_features_shareme_a2dp_source | remote_features_shareme_a2dp_sink) & PEER_DEVICE_COMPATIBLE_FEATURES;
        }
    }
    
    
    PEER_DEBUG(("   compatible features = %X\n",compatible_features));
    return compatible_features;
}


/*************************************************************************
NAME    
    RegisterPeerDeviceServiceRecord
    
DESCRIPTION
    Registers a Peer Device SDP record

RETURNS
    None
    
**************************************************************************/
void RegisterPeerDeviceServiceRecord ( void )
{
    if (!theSink.features.PeerUseCsrUuid)
    {   /* Construct service record from template */
        uint16 *peer_device_service_record = (uint16 *)mallocPanic( sizeof(uint16) * PEER_DEVICE_SERVICE_RECORD_SIZE );
        memmove(peer_device_service_record, peer_device_service_record_template, PEER_DEVICE_SERVICE_RECORD_SIZE);
        
        /* Update 128-bit UUID from PS */
        if (PsRetrieve(CONFIG_PEER_DEVICE_CUSTOM_UUID, peer_device_service_record + PEER_DEVICE_OFFSET_UUID128_ATTR_VAL, 8))
        {
            expandUuid128((uint16 *)&peer_device_service_record[PEER_DEVICE_OFFSET_UUID128_ATTR_VAL]);

            /* Malloc'd block is passed to f/w and unmapped from VM space */
            ConnectionRegisterServiceRecord(&theSink.task, PEER_DEVICE_SERVICE_RECORD_SIZE, (uint8 *)peer_device_service_record);
        }
    }
    else
    {   /* Register the Device Id SDP record from constant space */
        ConnectionRegisterServiceRecord(&theSink.task, PEER_DEVICE_SERVICE_RECORD_SIZE, peer_device_service_record_template);
    }
}


/*************************************************************************
NAME    
    updateAudioGating
    
DESCRIPTION
    Updates gating used for "multimedia" (non-sco) types of audio based on
    call status of any connected Peer and audio source being relayed

RETURNS
    None
    
**************************************************************************/
static void updateAudioGating (void)
{
    uint16 peer_id;
    
    /* Initially assume that no audio needs gating */
    audioUngateAudio(audio_gate_all);
    
    if (theSink.peer.current_state != RELAY_STATE_STREAMING)
    {   /* Ensure we only relay audio data when in the Streaming state */
        audioGateAudio(audio_gate_relay);
    }
    
    if ( a2dpGetPeerIndex(&peer_id) )
    {   /* Have a connected Peer */
        if (theSink.features.TwsSingleDeviceOperation && 
            (theSink.a2dp_link_data->peer_features[peer_id] & remote_features_tws_a2dp_sink) &&
            (theSink.a2dp_link_data->remote_peer_status[peer_id] & PEER_STATUS_IN_CALL))
        {   /* Peer has an active call and we are in single device mode */
            audioGateAudio(audio_gate_multimedia);
            return;
        }
    }
    
    /* Not in a state to required multimedia audio to be gated due to a call on the other Peer, update for currently selected source */
    switch (theSink.features.PeerSource)
    {
    case RELAY_SOURCE_NULL:
        /* Auto source selection mode - don't gate any audio */
        break;
    case RELAY_SOURCE_ANALOGUE:
        /* Gate all non-sco audio excluding wired */
        audioGateAudio(audio_gate_multimedia & ~audio_gate_wired);
        break;
    case RELAY_SOURCE_USB:
        /* Gate all non-sco audio excluding USB */
        audioGateAudio(audio_gate_multimedia & ~audio_gate_usb);
        break;
    case RELAY_SOURCE_A2DP:
        /* Gate all non-sco audio excluding A2DP */
        audioGateAudio(audio_gate_multimedia & ~audio_gate_a2dp);
        break;
    }
}

/*************************************************************************
NAME    
    issuePeerStatusChange
    
DESCRIPTION
    Issues a relay availability status update to the specified Peer

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
static void issuePeerStatusChange (uint16 peer_id, PeerStatusChange peer_status_change)
{
#ifdef ENABLE_AVRCP            
    uint16 avrcp_id;
    
    /* does the device support AVRCP and is AVRCP currently connected to this device? */
    for_all_avrcp(avrcp_id)
    {    
        /* ensure media is streaming and the avrcp channel is that requested to be paused */
        if (theSink.avrcp_link_data && theSink.a2dp_link_data && theSink.avrcp_link_data->connected[avrcp_id] && 
            (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[peer_id], &theSink.avrcp_link_data->bd_addr[avrcp_id])))
        {
            /* Inform remote peer of change to local devices status */
            sinkAvrcpVendorUniquePassthroughRequest( avrcp_id, AVRCP_PEER_CMD_PEER_STATUS_CHANGE, sizeof(peer_status_change), (const uint8 *)&peer_status_change );
        }
    }
#endif
}

/*************************************************************************
NAME    
    checkPeerFeatures
    
DESCRIPTION
    Checks the remote features bitmask of the current Peer device for support 
    of one or more of the supplied features.

RETURNS
    TRUE if one or more features supported, FALSE otherwise
    
**************************************************************************/
static bool checkPeerFeatures (remote_features features)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        if (theSink.a2dp_link_data->peer_features[peer_id] & features)
        {
            return TRUE;
        }
    }
    
    return FALSE;
}

/*************************************************************************
NAME    
    setRelayAvailability
    
DESCRIPTION
    Updates the relay availability for the specified peer status

RETURNS
    None
    
**************************************************************************/
static void setRelayAvailability (PeerStatus *peer_status, PeerStatusChange peer_status_change)
{
    PEER_DEBUG(("setRelayAvailability\n"));
    
    if ((peer_status_change & PEER_CALL_STATUS_CHANGE) == PEER_STATUS_CHANGE_CALL_INACTIVE)
    {
        PEER_DEBUG(("   call inactive\n"));
        *peer_status &= ~PEER_STATUS_IN_CALL;
    }
    
    if ((peer_status_change & PEER_CALL_STATUS_CHANGE) == PEER_STATUS_CHANGE_CALL_ACTIVE)
    {
        PEER_DEBUG(("   call active\n"));
        *peer_status |= PEER_STATUS_IN_CALL;
    }
    
    if ((peer_status_change & PEER_RELAY_STATUS_CHANGE) == PEER_STATUS_CHANGE_RELAY_AVAILABLE)
    {
        PEER_DEBUG(("   relay available\n"));
        *peer_status &= ~PEER_STATUS_DONT_RELAY;
    }
    
    if ((peer_status_change & PEER_RELAY_STATUS_CHANGE) == PEER_STATUS_CHANGE_RELAY_UNAVAILABLE)
    {
        PEER_DEBUG(("   relay unavailable\n"));
        *peer_status |= PEER_STATUS_DONT_RELAY;
    }
    
    if ((peer_status_change & PEER_RELAY_OWNERSHIP_CHANGE) == PEER_STATUS_CHANGE_RELAY_FREED)
    {
        PEER_DEBUG(("   relay free'd\n"));
        *peer_status &= ~PEER_STATUS_OWNS_RELAY;
    }
    
    if ((peer_status_change & PEER_RELAY_OWNERSHIP_CHANGE) == PEER_STATUS_CHANGE_RELAY_CLAIMED)
    {
        PEER_DEBUG(("   relay claimed\n"));
        *peer_status |= PEER_STATUS_OWNS_RELAY;
    }
}

/*************************************************************************
NAME    
    setRemoteRelayAvailability
    
DESCRIPTION
    Helper function used to update remote relay availability

RETURNS
    None
    
**************************************************************************/
static void setRemoteRelayAvailability (uint16 peer_id, PeerStatusChange peer_status_change)
{
    PEER_DEBUG(("setRemoteRelayAvailability\n"));
    setRelayAvailability( &theSink.a2dp_link_data->remote_peer_status[peer_id], peer_status_change );

    updateAudioGating();
    audioHandleRouting(audio_source_none);
}

/*************************************************************************
NAME    
    setLocalRelayAvailability
    
DESCRIPTION
    Helper function to update local relay availability and issue status change to Peer

RETURNS
    None
    
**************************************************************************/
static void setLocalRelayAvailability (uint16 peer_id, PeerStatusChange peer_status_change)
{
    PEER_DEBUG(("setLocalRelayAvailability\n"));
    setRelayAvailability( &theSink.a2dp_link_data->local_peer_status[peer_id], peer_status_change );
    
    issuePeerStatusChange( peer_id, peer_status_change );
}


/*************************************************************************
NAME    
    issueSourceStartResponse
    
DESCRIPTION
    Peer state machine helper function
    
    Issues a start response to the current source

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
static bool issueSourceStartResponse (RelaySource current_source)
{
    uint16 av_id;
    
    PEER_DEBUG(("issueSourceStartResponse av=%u\n",current_source));
    
    switch (current_source)
    {
    case RELAY_SOURCE_NULL:
        break;
    case RELAY_SOURCE_ANALOGUE:
        /* Don't actually need to send a start response to an analogue source */
        return TRUE;
        break;
    case RELAY_SOURCE_USB:
        /* Don't actually need to send a start response to a USB source */
        return TRUE;
        break;
    case RELAY_SOURCE_A2DP:
        if (a2dpGetSourceIndex(&av_id))
        {
            a2dp_stream_state a2dp_state = A2dpMediaGetState(theSink.a2dp_link_data->device_id[av_id], theSink.a2dp_link_data->stream_id[av_id]);
            
            if (a2dp_state == a2dp_stream_streaming)
            {   /* Already streaming */
                return TRUE;
            }
            else if (a2dp_state == a2dp_stream_starting)
            {   /* Starting, so attempt to send a response */
                return A2dpMediaStartResponse(theSink.a2dp_link_data->device_id[av_id], theSink.a2dp_link_data->stream_id[av_id], TRUE);
            }
            /* else in wrong state, so fall through and return FALSE */
        }
        break;
    }
    
    return FALSE;
}

/*************************************************************************
NAME    
    determineRequiredState
    
DESCRIPTION
    Peer state machine helper function.
    
    Examines any currently connected sources to determine which source needs to be relayed.

RETURNS
    TRUE if a change to the required state occurs, FALSE otherwise
    
**************************************************************************/
static bool determineRequiredState (void)
{
    uint16 source_id;
    RelayState last_state = theSink.peer.required_state;
    RelaySource last_source = theSink.peer.required_source;
    
    /* Initially assume no source is connected */
    theSink.peer.required_state = RELAY_STATE_IDLE;
    theSink.peer.required_source = RELAY_SOURCE_NULL;
    
#ifdef ENABLE_WIRED
    if (((theSink.features.PeerSource == RELAY_SOURCE_ANALOGUE) || (theSink.features.PeerSource == RELAY_SOURCE_NULL)) && analogAudioConnected())
    {   /* If an analogue source is connected, it is considered to be streaming */
        theSink.peer.required_state = RELAY_STATE_STREAMING;
        theSink.peer.required_source = RELAY_SOURCE_ANALOGUE;
    }
#endif

#ifdef ENABLE_USB
    if (((theSink.features.PeerSource == RELAY_SOURCE_USB) || (theSink.features.PeerSource == RELAY_SOURCE_NULL)) && (usbAudioIsAttached() && theSink.usb.spkr_active))
    {   /* Streaming USB source has higher priority than streaming analogue source */
        theSink.peer.required_state = RELAY_STATE_STREAMING;
        theSink.peer.required_source = RELAY_SOURCE_USB;
    }
#endif
    
    /* Check for A2DP Source */
    if (((theSink.features.PeerSource == RELAY_SOURCE_A2DP) || (theSink.features.PeerSource == RELAY_SOURCE_NULL)) && a2dpGetSourceIndex(&source_id))
    {
        a2dp_stream_state a2dp_state = A2dpMediaGetState(theSink.a2dp_link_data->device_id[source_id], theSink.a2dp_link_data->stream_id[source_id]);
        a2dp_suspend_state suspend_state = theSink.a2dp_link_data->SuspendState[source_id]; /* AVRCP play status can lead AVDTP stream state changes */
        
        if ((suspend_state == a2dp_not_suspended) && ((a2dp_state == a2dp_stream_starting) || (a2dp_state == a2dp_stream_streaming)))
        {   /* A streaming (or heading towards it) A2DP source has the highest priority */
            theSink.peer.required_state = RELAY_STATE_STREAMING;
            theSink.peer.required_source = RELAY_SOURCE_A2DP;
        }
        else if ((a2dp_state == a2dp_stream_open) || (a2dp_state == a2dp_stream_suspending) || (a2dp_state == a2dp_stream_streaming))
        {   /* A2DP media stream is open (or heading back to it).  Check for streaming state as well as AVRCP play status can lead AVDTP stream state changes */
            uint16 peer_id;
            
            if (a2dpGetPeerIndex(&peer_id) && !(theSink.a2dp_link_data->peer_features[peer_id] & remote_features_peer_source))
            {   /* We have a Peer that can't be a source itself, thus it is ok to leave a media channel open when suspended as */
                /* it will never want to use the relay channel. (Only when idle will the relay channel be marked as available) */
                if (theSink.peer.required_state != RELAY_STATE_STREAMING)
                {   /* Don't allow an open A2DP stream to have higher precedence that an streaming Analogue/USB stream */ 
                    theSink.peer.required_state = RELAY_STATE_OPEN;
                    theSink.peer.required_source = RELAY_SOURCE_A2DP;
                }
            }
        }
    }
    
    PEER_SM_DEBUG(("PEER: Required[%s:%s]\n",av_source_str[theSink.peer.required_source],relay_state_str[theSink.peer.required_state]));
    
    if ((last_state != theSink.peer.required_state) || (last_source != theSink.peer.required_source))
    {   /* Required state has changed */
        return TRUE;
    }
    else
    {   /* No change to required state */
        return FALSE;
    }
}

/*************************************************************************
NAME    
    updateTargetRelayState
    
DESCRIPTION
    Peer state machine helper function to manage updating of the target state.
    
    The Peer state machine is designed to manage the media (relay) channel to another Peer device.  Generally, the Peer driving the
    state machine is the one attempting to relay audio.
    However, for adherence to the GAVDP specification, an A2DP source must allow a sink to open and start a media channel.  We cope
    with this by allowing a Peer to change the current_state but keep the current_source and target_source as RELAY_SOURCE_NULL.  The 
    target_state is allowed to track the current_state in this scenario, so the state machine does not attempt to drive the relay 
    channel from this side.

    The required_state/source indicates what is currently streaming and what the relay channel ultimately needs to be forwarding.
    
    The required_state/source can change rapidly as a user pauses/resumes a single source or swaps between different sources.
    This is tempered by the target_state/source which attempts to track the required_state/source as closely as possible but is
    only updated when the current state reaches that last set target state.  
    
    However, changing the required_source will cause the state machine to return the relay state to idle before progressing again.
    This ensures the relay media channel is closed and then re-opened with a SEP suitable for forwarding audio data from the 
    required_source.
    
    The final stage of the state machine is to only action changes to the current state once one of the non-transitional (stable) 
    states has been reached (idle, open, streaming and routed).  This, again, prevents rapid changes to the required_state from 
    unduly upsetting operation.
    
RETURNS
    None
    
**************************************************************************/
static void updateTargetRelayState (void)
{
    if ( peerIsRelayAvailable() )
    {
        if (theSink.peer.current_state == theSink.peer.target_state)
        {   /* Reached the target state, so update as appropriate */
            if ((theSink.peer.target_source != theSink.peer.required_source) && (theSink.peer.target_state != RELAY_STATE_IDLE))
            {   /* Source has changed, go through idle state to get to it */
                theSink.peer.target_state = RELAY_STATE_IDLE;
            }
            else
            {   /* Update to the required state */
                theSink.peer.target_source = theSink.peer.required_source;
                theSink.peer.target_state = theSink.peer.required_state;
            }
        }
        else
        {   /* Current state differs to target state */
            if ((theSink.peer.current_source == RELAY_SOURCE_NULL) && (theSink.peer.target_source == RELAY_SOURCE_NULL))
            {   /* No source being managed.  Thus the other Peer is driving the state machine */
                /* Update target state to keep track of what other Peer is doing and also prevent this device from driving the state machine too */
                if (checkPeerFeatures(remote_features_peer_source) || (theSink.peer.required_source == RELAY_SOURCE_NULL))
                {   /* Only prevent local Peer state machine from driving state if other Peer can act as a source or we don't require use of relay channel */
                    /* Prevents sink only Peers (such as PTS) from holding a media channel open if we need to use it */
                    theSink.peer.target_state = theSink.peer.current_state;
                }
                
                if (theSink.peer.current_state == RELAY_STATE_IDLE)
                {   /* Other peer has now finished using the relay channel.  Update to the required state */
                    theSink.peer.target_source = theSink.peer.required_source;
                    theSink.peer.target_state = theSink.peer.required_state;
                }
            }
            /* else allow relay state to reach target state before updating target state again */
        }
    }
    else
    {
        if ((theSink.peer.current_source == RELAY_SOURCE_NULL) && (theSink.peer.target_source == RELAY_SOURCE_NULL))
        {   /* No source being managed.  Thus the other Peer is driving the state machine */
            /* Update target state to keep track of what other Peer is doing and also prevent this device from driving the state machine too */
            theSink.peer.target_state = theSink.peer.current_state;
        }
        else
        {   /* Either no Peer connected or not in a state to accept a media stream.  Revert target state to idle */
            theSink.peer.target_source = RELAY_SOURCE_NULL;
            theSink.peer.target_state = RELAY_STATE_IDLE;
        }
    }

    PEER_SM_DEBUG(("PEER: Target[%s:%s]\n",av_source_str[theSink.peer.target_source],relay_state_str[theSink.peer.target_state]));
}


/*************************************************************************
NAME    
    updateCurrentState
    
DESCRIPTION
    Peer state machine helper function to help manage changes to the current state

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
static void updateCurrentState (RelayState relay_state)
{
    theSink.peer.current_state = relay_state;
    
    if (theSink.peer.current_state == RELAY_STATE_IDLE)
    {   /* Reset current source once idle state reached */
        theSink.peer.current_source = RELAY_SOURCE_NULL;
    }
    
    /* Update target state, if necessary */
    updateTargetRelayState();
    
    if (theSink.peer.current_source == RELAY_SOURCE_NULL)
    {   /* Update current source if we have reached idle and target has changed */
        theSink.peer.current_source = theSink.peer.target_source;
    }
    
    PEER_SM_DEBUG(("PEER: Current[%s:%s]\n",av_source_str[theSink.peer.current_source],relay_state_str[theSink.peer.current_state]));
}


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
void peerAdvanceRelayState (RelayEvent relay_event)
{
    PEER_SM_DEBUG(("----\nPEER: Relay[%s]\n",relay_event_str[relay_event]));
    
    switch (relay_event)
    {
    case RELAY_EVENT_DISCONNECTED:
        updateCurrentState( RELAY_STATE_IDLE );
        break;
        
    case RELAY_EVENT_CONNECTED:
        updateCurrentState( RELAY_STATE_IDLE );
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Open relay stream */
            if (a2dpIssuePeerOpenRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER OPEN REQ"));
                updateCurrentState( RELAY_STATE_OPENING );
            }
        }
        break;
        
    case RELAY_EVENT_CLOSED:
        updateCurrentState( RELAY_STATE_IDLE );
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Open relay stream */
            if (a2dpIssuePeerOpenRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER OPEN REQ"));
                updateCurrentState( RELAY_STATE_OPENING );
            }
        }
        break;
        
    case RELAY_EVENT_OPEN:
        updateCurrentState( RELAY_STATE_IDLE );
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Open relay stream */
            if (a2dpIssuePeerOpenRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER OPEN REQ"));
                updateCurrentState( RELAY_STATE_OPENING );
            }
        }
        break;
        
    case RELAY_EVENT_OPENING:
        updateCurrentState( RELAY_STATE_OPENING );
        /* Peer will wait for open to complete, so do nothing further */
        break;
        
    case RELAY_EVENT_NOT_OPENED:
        updateCurrentState( RELAY_STATE_IDLE );
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Open relay stream */
            if (a2dpIssuePeerOpenRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER OPEN REQ"));
                updateCurrentState( RELAY_STATE_OPENING );
            }
        }
        break;
        
    case RELAY_EVENT_OPENED:
        updateCurrentState( RELAY_STATE_OPEN );
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Close relay stream */
            if (a2dpIssuePeerCloseRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER CLOSE REQ"));
                updateCurrentState( RELAY_STATE_CLOSING );
            }
        }
        else if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Start relay stream */
            if (a2dpIssuePeerStartRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER START REQ"));
                updateCurrentState( RELAY_STATE_STARTING );
            }
        }
        break;

    case RELAY_EVENT_CLOSE:
        updateCurrentState( RELAY_STATE_OPEN );
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Close relay stream */
            if (a2dpIssuePeerCloseRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER CLOSE REQ"));
                updateCurrentState( RELAY_STATE_CLOSING );
            }
        }
        break;
    
    case RELAY_EVENT_SUSPENDED:
        updateCurrentState( RELAY_STATE_OPEN );
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Close relay stream */
            if (a2dpIssuePeerCloseRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER CLOSE REQ"));
                updateCurrentState( RELAY_STATE_CLOSING );
            }
        }
        else if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Start relay stream */
            if (a2dpIssuePeerStartRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER START REQ"));
                updateCurrentState( RELAY_STATE_STARTING );
            }
        }
        break;
        
    case RELAY_EVENT_START:
        updateCurrentState( RELAY_STATE_OPEN );
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Start relay stream */
            if (a2dpIssuePeerStartRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER START REQ"));
                updateCurrentState( RELAY_STATE_STARTING );
            }
        }
        break;

    case RELAY_EVENT_STARTING:
        updateCurrentState( RELAY_STATE_STARTING );
        /* Peer will wait for start to complete, so do nothing further */
        break;
        
    case RELAY_EVENT_NOT_STARTED:
        updateCurrentState( RELAY_STATE_OPEN );
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Close relay stream */
            if (a2dpIssuePeerCloseRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER CLOSE REQ"));
                updateCurrentState( RELAY_STATE_CLOSING );
            }
        }
        else if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Start relay stream */
            if (a2dpIssuePeerStartRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER START REQ"));
                updateCurrentState( RELAY_STATE_STARTING );
            }
        }
        break;
        
    case RELAY_EVENT_STARTED:
        updateCurrentState( RELAY_STATE_STREAMING );
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Suspend relay stream */
            if (a2dpIssuePeerSuspendRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER SUSPEND REQ"));
                updateCurrentState( RELAY_STATE_SUSPENDING );
            }
        }
        else
        {   /* Route relay stream */
            issueSourceStartResponse(theSink.peer.current_source);
            VolumeCheckA2dp(same_volume);
            PEER_SM_DEBUG(("PEER: Issue[%s]\n","SOURCE START RESP"));
        }
        break;
        
    case RELAY_EVENT_SUSPEND:
        updateCurrentState( RELAY_STATE_STREAMING );
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Suspend relay stream */
            if (a2dpIssuePeerSuspendRequest())
            {
                PEER_SM_DEBUG(("PEER: Issue[%s]\n","PEER SUSPEND REQ"));
                updateCurrentState( RELAY_STATE_SUSPENDING );
            }
        }
        break;
    }
    
    updateAudioGating();
    audioHandleRouting(audio_source_none);
}
        

/*************************************************************************
NAME    
    kickPeerStateMachine
    
DESCRIPTION
    Will automatically attempt to advance the Relay channel if it is in a 'steady' state (i.e. not expecting an external event)

RETURNS
    None
    
**************************************************************************/
static void kickPeerStateMachine (void)
{
    switch (theSink.peer.current_state)
    {
    case RELAY_STATE_IDLE:
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Open relay stream */
            peerAdvanceRelayState(RELAY_EVENT_OPEN);
        }
        break;
    case RELAY_STATE_OPEN:
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Close relay stream */
            peerAdvanceRelayState(RELAY_EVENT_CLOSE);
        }
        if (theSink.peer.target_state > theSink.peer.current_state)
        {   /* Start relay stream */
            peerAdvanceRelayState(RELAY_EVENT_START);
        }
        break;
    case RELAY_STATE_STREAMING:
        if (theSink.peer.target_state < theSink.peer.current_state)
        {   /* Suspend relay stream */
            peerAdvanceRelayState(RELAY_EVENT_SUSPEND);
        }
        break;
    default:
        /* Do nothing as we are waiting for an action to complete */
        break;
    }
}


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
void peerUpdateRequiredRelayState (void)
{
    determineRequiredState();
    updateTargetRelayState();
    kickPeerStateMachine();
}


/*************************************************************************
NAME    
    peerGetSource
    
DESCRIPTION
    Obtains the currently configured source

RETURNS
    Current source
    
**************************************************************************/
RelaySource peerGetSource (void)
{
    if (theSink.features.PeerSource == RELAY_SOURCE_NULL)
    {   /* Automatic source selection configured, so return the current relayed source */
        return theSink.peer.required_source;
    }
    else
    {   /* Return the current configured source */
        return theSink.features.PeerSource;
    }
}

/*************************************************************************
NAME    
    peerSetSource
    
DESCRIPTION
    Sets the current source to use for relaying audio

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool peerSetSource (RelaySource new_source)
{
    if (theSink.features.PeerSource != new_source)
    {
        theSink.features.PeerSource = new_source;
        
        updateAudioGating();
        audioHandleRouting(audio_source_none);

        PEER_UPDATE_REQUIRED_RELAY_STATE("SELECT NEW SOURCE");        
    }
    
    return TRUE;
}

/*************************************************************************
NAME    
    peerGetPeerSink
    
DESCRIPTION
    Obtains sink to relay channel

RETURNS
    Handle to relay channel, NULL otherwise
    
**************************************************************************/
Sink peerGetPeerSink (void)
{
    if (theSink.peer.current_state >= RELAY_STATE_OPEN)
    {
        uint16 peer_id;
        
        if (a2dpGetPeerIndex(&peer_id))
        {
            return A2dpMediaGetSink(theSink.a2dp_link_data->device_id[peer_id], theSink.a2dp_link_data->stream_id[peer_id]);
        }
    }
    
    return NULL;
}


/*************************************************************************
NAME    
    peerGetSourceSink
    
DESCRIPTION
    Obtains sink of the current source

RETURNS
    Handle to sink if there is a current streaming source, NULL otherwise
    
**************************************************************************/
Sink peerGetSourceSink (void)
{
    Sink sink = NULL;
    
    switch (theSink.peer.current_source)
    {
    case RELAY_SOURCE_NULL:
        break;
        
    case RELAY_SOURCE_ANALOGUE:
#ifdef ENABLE_WIRED
        sink = analogGetAudioSink();
#endif
        break;
        
    case RELAY_SOURCE_USB:
#ifdef ENABLE_USB
        sink = usbGetAudioSink();
#endif
        break;
        
    case RELAY_SOURCE_A2DP:
        sink = a2dpGetSourceSink();
        break;
    }
    
    return sink;
}


/*************************************************************************
NAME    
    peerIsRelayAvailable
    
DESCRIPTION
    Determines if relay channel is available for use

RETURNS
    TRUE if relay available, FALSE otherwise
    
**************************************************************************/
bool peerIsRelayAvailable (void)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        if ( !(theSink.a2dp_link_data->remote_peer_status[peer_id] & (PEER_STATUS_IN_CALL | PEER_STATUS_DONT_RELAY | PEER_STATUS_OWNS_RELAY)) &&   /* Has remote peer requested that relay not be used? */
             !(theSink.a2dp_link_data->local_peer_status[peer_id] & (PEER_STATUS_IN_CALL | PEER_STATUS_DONT_RELAY)) &&    /* Does local device not want relay to be used? */
              ((theSink.a2dp_link_data->seid[peer_id] == 0) || (theSink.a2dp_link_data->seid[peer_id] & SOURCE_SEID_MASK)) &&   /* Either no SEP or a source SEP has been configured */
              (theSink.a2dp_link_data->peer_features[peer_id] & remote_features_peer_sink) )                              /* Peer supports a sink role */
        {
            PEER_SM_DEBUG(("PEER: RelayAvailable[TRUE]\n"));
            return TRUE;
        }
    }
    
    PEER_SM_DEBUG(("PEER: RelayAvailable[FALSE]\n"));
    return FALSE;
}

/*************************************************************************
NAME    
    peerCheckSource
    
DESCRIPTION
    Determines if the current peer source is the same as the new_source.

RETURNS
    TRUE if the current peer source is the same as new_source or if it is RELAY_SOURCE_NULL, FALSE otherwise
    
**************************************************************************/
bool peerCheckSource(RelaySource new_source)
{
    if((theSink.features.PeerSource != RELAY_SOURCE_NULL) && (theSink.features.PeerSource != new_source))
    {
        return FALSE;
    }
    else
    {
        return TRUE;
    }
}

/*************************************************************************
NAME    
    peerUpdateLocalStatusChange
    
DESCRIPTION
    Updates the local relay availability and issues a status change to a connected Peer

RETURNS
    None
    
**************************************************************************/
void peerUpdateLocalStatusChange (PeerStatusChange peer_status_change)
{
    uint16 peer_id;
        
    PEER_DEBUG(("peerUpdateLocalStatusChange status=0x%X\n",peer_status_change));
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        setLocalRelayAvailability( peer_id, peer_status_change);
        PEER_UPDATE_REQUIRED_RELAY_STATE("LOCAL STATUS CHANGED");
    }
}


/*************************************************************************
NAME    
    peerHandleStatusChangeCmd
    
DESCRIPTION
    Handles a relay availability status change from a Peer

RETURNS
    None
    
**************************************************************************/
void peerHandleStatusChangeCmd (PeerStatusChange peer_status_change)
{
    uint16 peer_id;
        
    PEER_DEBUG(("peerHandleStatusChangeCmd status=0x%X\n",peer_status_change));
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        setRemoteRelayAvailability( peer_id, peer_status_change);
        PEER_UPDATE_REQUIRED_RELAY_STATE("REMOTE STATUS CHANGED");
    }
}


/*************************************************************************
NAME    
    peerHandleAudioRoutingCmd
    
DESCRIPTION
    Hamdles a audio routing notification from a Peer

RETURNS
    None
    
**************************************************************************/
void peerHandleAudioRoutingCmd (PeerTwsAudioRouting master_routing_mode, PeerTwsAudioRouting slave_routing_mode)
{
    uint16 peer_id;
        
    PEER_DEBUG(("peerHandleAudioRoutingCmd  master=%u  slave=%u\n",master_routing_mode,slave_routing_mode));

    if (a2dpGetPeerIndex(&peer_id))
    {
        if ((master_routing_mode <= PEER_TWS_ROUTING_DMIX) && (slave_routing_mode <= PEER_TWS_ROUTING_DMIX))
        {
            theSink.a2dp_link_data->a2dp_audio_mode_params.master_routing_mode = master_routing_mode;
            theSink.a2dp_link_data->a2dp_audio_mode_params.slave_routing_mode = slave_routing_mode;
        }
        
        if (theSink.routed_audio)            
        {
            AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
        }
    }
}


/*************************************************************************
NAME    
    peerHandleVolumeCmd
    
DESCRIPTION
    Handle a volume change notification from a Peer

RETURNS
    None
    
**************************************************************************/
void peerHandleVolumeCmd (uint8 volume)
{
    uint16 peer_id;
        
    PEER_DEBUG(("peerHandleVolumeCmd  volume=%u\n",volume));
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        volume = volume;
    }
}

/*************************************************************************
NAME    
    peerUpdateMasterTrimVolume
    
DESCRIPTION
    Handle a trim volume change notification from a Peer

RETURNS
    None
    
**************************************************************************/

void peerUpdateTrimVolume(PeerTrimVolChangeCmd cmd)
{

    switch(cmd)
    {
        case PEER_TRIM_VOL_MASTER_UP:
            MessageSend(&theSink.task , EventUsrMasterDeviceTrimVolumeUp , 0);
            break;

        case PEER_TRIM_VOL_MASTER_DOWN:
            MessageSend(&theSink.task , EventUsrMasterDeviceTrimVolumeDown , 0);
            break;

        case PEER_TRIM_VOL_SLAVE_UP:
            MessageSend(&theSink.task , EventUsrSlaveDeviceTrimVolumeUp , 0);
            break;

        case PEER_TRIM_VOL_SLAVE_DOWN:
            MessageSend(&theSink.task , EventUsrSlaveDeviceTrimVolumeDown , 0);
            break;
            
        default:
            break;
        }
}


/*************************************************************************
NAME    
    peerUpdateMasterTrimVolume
    
DESCRIPTION
   Sends the appropriate trim volume change command to the master peer device.

RETURNS
    None
    
**************************************************************************/
void peerSendDeviceTrimVolume(uint16 index , volume_direction dir, tws_device_type tws_device)
{
    /* Audio routed from a Peer device which supports TWS as a Source.  This takes priority over ShareMe and thus means we are in a TWS session */
    PeerTrimVolChangeCmd cmd = PEER_TRIM_VOL_NO_CHANGE;
    if (tws_device == tws_master)
    {
        switch (dir)
        {
        case increase_volume:
            cmd = PEER_TRIM_VOL_MASTER_UP;
            break;

        case decrease_volume:
            cmd = PEER_TRIM_VOL_MASTER_DOWN;
            break;

        case same_volume:
        default:
            cmd = PEER_TRIM_VOL_NO_CHANGE;
            break;
        }                            
    }
    else if (tws_device == tws_slave)
    {
        switch (dir)
        {
        case increase_volume:
            cmd = PEER_TRIM_VOL_SLAVE_UP;
            break;
        
        case decrease_volume:
            cmd = PEER_TRIM_VOL_SLAVE_DOWN;
            break;
        
        case same_volume:
        default:
            cmd = PEER_TRIM_VOL_NO_CHANGE;
            break;
        }                            
    }
    if(cmd != PEER_TRIM_VOL_NO_CHANGE) 
    {
        sinkAvrcpVendorUniquePassthroughRequest(index , AVRCP_PEER_CMD_UPDATE_TRIM_VOLUME, 
                sizeof(uint16), (const uint8 *)&cmd);
    }
}


/*************************************************************************
NAME    
    peerHandleRemoteAGConnected
    
DESCRIPTION
    Checks if the sink device is already connected to an AG with the same bd address as the one connected to the peer,
    if yes, then disconnect the local AG connected if the bd addr of the sink device is lower than that of peer.

RETURNS
    None
    
**************************************************************************/
void peerHandleRemoteAgConnected(void)
{    
    if(theSink.remote_peer_audio_conn_status & A2DP_AUDIO)
    {
        uint16 avA2dpId;
        uint16 peerA2dpId;
        /* check if the bd address of the local AG is the same as the AG connected to the peer */
        if(a2dpGetPeerIndex (&peerA2dpId) && a2dpGetSourceIndex(&avA2dpId) && 
            BdaddrIsSame(&(theSink.remote_peer_ag_bd_addr) , &(theSink.a2dp_link_data->bd_addr[avA2dpId])))
        {
            if(peerCompareBdAddr(&theSink.a2dp_link_data->bd_addr[peerA2dpId] , &theSink.local_bd_addr))
            {
                sinkAvrcpDisconnect(&(theSink.a2dp_link_data->bd_addr[avA2dpId]));
                A2dpSignallingDisconnectRequest(theSink.a2dp_link_data->device_id[avA2dpId]);
                sinkDisconnectAllSlc();
            }
        }
    }
}

/*************************************************************************
NAME    
    compareBdAddr
    
DESCRIPTION
    Compares the first and the second bdaddr.
RETURNS
    TRUE if the first is greater than second, otherwise return FALSE.
    
**************************************************************************/
bool peerCompareBdAddr(const bdaddr* first , const bdaddr* second)
{
    if( first->nap == second->nap)
    {
        if(first->uap == second->uap)
        {
            if(first->lap == second->lap)
            {
                return FALSE;
            }
            else
            {
                if(first->lap > second->lap)
                {
                    return TRUE;
                }
            }
        }
        else
        {
            if(first->uap > second->uap)
            {
                return TRUE;
            }
        }
    }
    else
    {
        if(first->nap > second->nap)
        {
            return TRUE;
        }
    }
    return FALSE;
}


/*************************************************************************
NAME    
    peerSendAudioEnhancements
    
DESCRIPTION
    Sends audio enhancement setting to currently connected Peer

RETURNS
    None
    
**************************************************************************/
void peerSendAudioEnhancements()
{
    uint16 peerA2dpId;
    
    if(a2dpGetPeerIndex(&peerA2dpId))
    {    
        /* Send the audio enhancement settings to the peer if this device is a TWS master*/
        if((theSink.a2dp_link_data->seid[peerA2dpId] & (SOURCE_SEID_MASK | TWS_SEID_MASK)) == (SOURCE_SEID_MASK | TWS_SEID_MASK))
        {
            uint16 peerAvrcpIndex;
            for_all_avrcp(peerAvrcpIndex)
            {
                if(theSink.avrcp_link_data && BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[peerA2dpId], &theSink.avrcp_link_data->bd_addr[peerAvrcpIndex]))
                {
                    uint8 audio_enhancements_array[2];
                    uint16 audio_enhancements = ((theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing -
                            A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0) & A2DP_MUSIC_CONFIG_USER_EQ_SELECT)|
                            (theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements & ~A2DP_MUSIC_CONFIG_USER_EQ_SELECT);

                    audio_enhancements_array[0] = (uint8)audio_enhancements;
                    audio_enhancements_array[1] = (uint8)(audio_enhancements >> 8);                    
                                        
                    sinkAvrcpVendorUniquePassthroughRequest(peerAvrcpIndex , AVRCP_PEER_CMD_UPDATE_AUDIO_ENHANCEMENT_SETTINGS, 
                       sizeof(audio_enhancements_array), (const uint8 *)audio_enhancements_array);
                    
                    break;
                } 
            }
        }
    }
}

/*************************************************************************
NAME    
    peerSendEqSettings
    
DESCRIPTION
    Sends DSP EQ setting to currently connected Peer

RETURNS
    None
    
**************************************************************************/
void peerSendUserEqSettings(void)
{
    uint16 peerA2dpId;
    uint16 i;
    
    if(a2dpGetPeerIndex(&peerA2dpId))
    {    
        /* Send the audio enhancement settings to the peer if this device is a TWS master*/
        if((theSink.a2dp_link_data->seid[peerA2dpId] & (SOURCE_SEID_MASK | TWS_SEID_MASK)) == (SOURCE_SEID_MASK | TWS_SEID_MASK))
        {
            uint16 peerAvrcpIndex;
            for_all_avrcp(peerAvrcpIndex)
            {
                if(theSink.avrcp_link_data && BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[peerA2dpId], &theSink.avrcp_link_data->bd_addr[peerAvrcpIndex]))
                {
                    uint16 size_data = (NUM_USER_EQ_BANDS * USER_EQ_BAND_PARAMS_SIZE) + USER_EQ_PARAM_PRE_GAIN_SIZE;
                    uint8 *user_eq_params_array = (uint8 *)mallocPanic( sizeof(uint8) * size_data) ;
                    uint8 *local_data_array = user_eq_params_array;

                    if((local_data_array != NULL) && (theSink.PEQ != NULL))
                    {
                        /*Store the data into the uint8 array */
                        local_data_array[PRE_GAIN_LO_OFFSET] = LOBYTE(theSink.PEQ->preGain);
                        local_data_array[PRE_GAIN_HI_OFFSET] = HIBYTE(theSink.PEQ->preGain); 

                        /*Increment the data pointer with the no. of bytes required to store the Pre-gain value */
                        local_data_array += USER_EQ_PARAM_PRE_GAIN_SIZE ;

                        for(i=0; i<NUM_USER_EQ_BANDS ; i++)
                        {
                            local_data_array[BAND_FILTER_OFFSET]= (uint8)theSink.PEQ->bands[i].filter;
                            local_data_array[BAND_FREQ_LO_OFFSET]=  LOBYTE(theSink.PEQ->bands[i].freq);
                            local_data_array[BAND_FREQ_HI_OFFSET]=  HIBYTE(theSink.PEQ->bands[i].freq);
                            local_data_array[BAND_GAIN_LO_OFFSET]=  LOBYTE(theSink.PEQ->bands[i].gain);
                            local_data_array[BAND_GAIN_HI_OFFSET]=  HIBYTE(theSink.PEQ->bands[i].gain);
                            local_data_array[BAND_Q_LO_OFFSET]=  LOBYTE(theSink.PEQ->bands[i].Q);            
                            local_data_array[BAND_Q_HI_OFFSET]=  HIBYTE(theSink.PEQ->bands[i].Q);

                            /*Increment the data pointer with the no. of bytes required to store all the band parameters */
                            local_data_array += USER_EQ_BAND_PARAMS_SIZE ;                        
                        }
                        
                        local_data_array = NULL;
                                            
                        sinkAvrcpVendorUniquePassthroughRequest(peerAvrcpIndex , AVRCP_PEER_CMD_UPDATE_USER_EQ_SETTINGS, 
                                                                                                  size_data, (const uint8 *)user_eq_params_array);                        
                        free(user_eq_params_array);

                        break;
                    }
                } 
            }
        }
    }
}


/*************************************************************************
NAME    
    peerRequestUserEqSetings
    
DESCRIPTION
    Request current DSP EQ setting from the connected Peer (Master)

RETURNS
    None
    
**************************************************************************/
void peerRequestUserEqSetings(void)
{
    uint16 peerA2dpId;
    a2dp_link_priority priority;
    
    if(a2dpGetPeerIndex(&peerA2dpId))
    {    
        /* Request the current user eq settings from the peer if this device is a TWS Slave*/
        if(findCurrentA2dpSource(&priority) && (theSink.a2dp_link_data->peer_device[priority] == remote_device_peer))
        {
            uint16 peerAvrcpIndex;
            for_all_avrcp(peerAvrcpIndex)
            {
                if(theSink.avrcp_link_data && BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[peerA2dpId], &theSink.avrcp_link_data->bd_addr[peerAvrcpIndex]))
                {
                    sinkAvrcpVendorUniquePassthroughRequest(peerAvrcpIndex , AVRCP_PEER_CMD_REQUEST_USER_EQ_SETTINGS, 0 , NULL);
                }
            }
        }
    }
}

/*************************************************************************
NAME    
    peerConnectPeer
    
DESCRIPTION
    Attempts to connect a TWS Peer, if not already in a Peer session

RETURNS
    TRUE if a connection is attempted, FALSE otherwise
    
**************************************************************************/
bool peerConnectPeer (void)
{
    if (!a2dpGetPeerIndex(NULL))
    {
        typed_bdaddr  peer_addr;
        sink_attributes peer_attributes;    
        uint16 list_idx;
        uint16 list_size = ConnectionTrustedDeviceListSize();

        for (list_idx = 0; list_idx < list_size; list_idx++)
        {
            /* attempt to obtain the device attributes for the current ListID required */
            if (deviceManagerGetIndexedAttributes(list_idx, &peer_attributes, &peer_addr))
            {
                if ((peer_attributes.peer_device == remote_device_peer) && 
                    (peer_attributes.peer_features & (remote_features_tws_a2dp_sink | remote_features_tws_a2dp_source)))
                {   /* Only attempt to connect a TWS Peer */
                    slcConnectDevice(&peer_addr.addr, peer_attributes.profiles);
                    return TRUE;
                }
            }
        }
    }
    
    return FALSE;
}

/*************************************************************************
NAME    
    peerObtainPairingMode
    
DESCRIPTION
    Obtains the pairing mode used for the currently connected Peer device

RETURNS
    None
    
**************************************************************************/
PeerPairingMode peerObtainPairingMode (uint16 peer_id)
{
    PeerPairingMode pairing_mode = PEER_PAIRING_MODE_TEMPORARY;   /* By default, devices use temporary pairing */
    
    if (theSink.a2dp_link_data->peer_features[peer_id] & (remote_features_tws_a2dp_sink | remote_features_tws_a2dp_source))
    {   /* If remote Peer supports TWS then use the configured TWS pairing mode */
        pairing_mode = theSink.features.TwsPairingMode;
        PEER_DEBUG(("PEER: TWS Pairing Mode = %u\n",pairing_mode));
    }
    else 
    {
        if (theSink.a2dp_link_data->peer_features[peer_id] & (remote_features_shareme_a2dp_sink | remote_features_shareme_a2dp_source))
        {   /* If remote Peer supports ShareMe and not TWS then use the configured ShareMe pairing mode */
            pairing_mode = theSink.features.ShareMePairingMode;
            PEER_DEBUG(("PEER: ShareMe Pairing Mode = %u\n",pairing_mode));
        }
    }
    
    return pairing_mode;
}

/*************************************************************************
NAME    
    peerUpdatePairing
    
DESCRIPTION
    Ensures permanent pairing data is updated

RETURNS
    None
    
**************************************************************************/
void peerUpdatePairing (uint16 peer_id, void *peer_attributes)
{
    switch (peerObtainPairingMode(peer_id))
    {
    case PEER_PAIRING_MODE_TEMPORARY:
    case PEER_PAIRING_MODE_NORMAL:
        break;
    case PEER_PAIRING_MODE_PERMANENT:
        /* Permanent pairing is enabled for Peer devices */
        PEER_DEBUG(("PEER: Add/update permanent pairing for Peer %u\n", peer_id));
        AuthUpdatePermanentPairing(&theSink.a2dp_link_data->bd_addr[peer_id], peer_attributes);
        break;
    }
}

/*************************************************************************
NAME    
    peerInitPeerStatus
    
DESCRIPTION
    Inits peer data structure and sets the initial required state

RETURNS
    None
    
**************************************************************************/
void peerInitPeerStatus (void)
{
    PEER_DEBUG(("peerInitPeerStatus\n"));
    
    memset(&theSink.peer, 0, sizeof(theSink.peer));
    determineRequiredState();
}

#endif  /* ENABLE_PEER */
