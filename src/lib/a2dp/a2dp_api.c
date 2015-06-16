/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_api.c

DESCRIPTION


NOTES

*/


/****************************************************************************
    Header files
*/
#include "a2dp.h"
#include "a2dp_private.h"
#include "a2dp_api.h"
#include "a2dp_codec_handler.h"
#include "a2dp_process_command.h"
#include "a2dp_data_block.h"

#include <bdaddr.h>
#include <stdlib.h>
#include <string.h>
#include <print.h>

/****************************************************************************/
static const a2dp_signalling_state A2dpSignallingState[ 6 ] =
{
    a2dp_signalling_idle,
    a2dp_signalling_connecting,
    a2dp_signalling_connecting,
    a2dp_signalling_connecting,
    a2dp_signalling_connected,
    a2dp_signalling_disconnecting
};

static const a2dp_stream_state A2dpStreamState[ 19 ] =
{
    a2dp_stream_idle,
    a2dp_stream_discovering,
    a2dp_stream_configuring,
    a2dp_stream_configuring,
    a2dp_stream_configuring,
    a2dp_stream_configured,
    a2dp_stream_opening,
    a2dp_stream_opening,
    a2dp_stream_open,
    a2dp_stream_streaming,
    a2dp_stream_starting,
    a2dp_stream_starting,
    a2dp_stream_streaming,
    a2dp_stream_closing,
    a2dp_stream_closing,
    a2dp_stream_reconfiguring,
    a2dp_stream_reconfiguring,
    a2dp_stream_aborting,
    a2dp_stream_aborting
};

#if 0
static a2dp_stream_state getStreamState (uint16 state_mask)
{
    uint8 state = 0;

    if (state_mask & 0xFF00)
    {
        state_mask >>= 8;
        state = 8;
    }
    if (state_mask & 0xF0)
    {
        state_mask >>= 4;
        state += 4;
    }
    if (state_mask & 0xC)
    {
        state_mask >>= 2;
        state += 2;
    }
    if (state_mask & 0x2)
    {
        state++;
    }

    return A2dpStreamState[ state ];
}
#endif


static uint8 findDeviceId (remote_device *device)
{
    PRINT((" device_id="));

    if ((device != NULL) && device->instantiated)
    {
        PRINT(("%u",device->device_id));
        return device->device_id;
    }

    PRINT(("INVALID_DEVICE_ID"));
    return INVALID_DEVICE_ID;
}


static uint8 findStreamId (media_channel *media)
{
    PRINT((" stream_id="));

    if ((media != NULL) && media->status.instantiated)
    {
        PRINT(("%u",media->status.media_id));
        return media->status.media_id;
    }

    PRINT(("INVALID_STREAM_ID"));
    return INVALID_STREAM_ID;
}


void a2dpSignallingConnectInd (remote_device *device)
{
    MAKE_A2DP_MESSAGE(A2DP_SIGNALLING_CONNECT_IND);

    PRINT(("a2dpSignallingConnectInd"));

    message->device_id = findDeviceId(device);

    if (device != NULL)
    {
        message->addr = device->bd_addr;
    }
    else
    {
        BdaddrSetZero(&message->addr);
    }

    MessageSend(a2dp->clientTask, A2DP_SIGNALLING_CONNECT_IND, message);
}


void a2dpSignallingConnectCfm (remote_device *device, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_SIGNALLING_CONNECT_CFM);

    PRINT(("a2dpSignallingConnectCfm status=%u", status));

    message->device_id = findDeviceId(device);
    message->status = status;
    
    if (device != NULL)
    {
        message->addr = device->bd_addr;
        message->locally_initiated = device->signal_conn.status.locally_initiated;
    }
    else
    {
        BdaddrSetZero(&message->addr);
        message->locally_initiated = TRUE;  /* A NULL device can only occur on outgoing connection attempts */
    }

    MessageSend(a2dp->clientTask, A2DP_SIGNALLING_CONNECT_CFM, message);
}


void a2dpSignallingDisconnectInd (remote_device *device, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_SIGNALLING_DISCONNECT_IND);

    PRINT(("a2dpSignallingDisconnectInd status=%u", status));

    message->device_id = findDeviceId(device);
    message->status = status;

    if (device != NULL)
    {
        message->addr = device->bd_addr;
    }
    else
    {
        BdaddrSetZero(&message->addr);
    }

    MessageSend(a2dp->clientTask, A2DP_SIGNALLING_DISCONNECT_IND, message);
}

void a2dpSignallingLinklossInd (remote_device *device)
{
    MAKE_A2DP_MESSAGE(A2DP_SIGNALLING_LINKLOSS_IND);

    PRINT(("a2dpSignallingLinklossInd"));

    message->device_id = findDeviceId(device);

    MessageSend(a2dp->clientTask, A2DP_SIGNALLING_LINKLOSS_IND, message);
}


void a2dpMediaOpenInd (remote_device *device, uint8 seid)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_OPEN_IND);

    PRINT(("a2dpMediaOpenInd"));

    message->device_id = findDeviceId(device);
    message->seid = seid;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_OPEN_IND, message);
}

void a2dpMediaOpenCfm (remote_device *device, media_channel *media, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_OPEN_CFM);

    PRINT(("a2dpMediaOpenCfm status=%u", status));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);
    message->status = status;
    if (status == a2dp_success)
    {
        sep_config_type *sep_config = (sep_config_type *)((sep_data_type *)PanicNull( blockGetCurrent( device->device_id, data_block_sep_list )))->sep_config;  
        message->seid = sep_config->seid;
    }
    else
    {
        message->seid = 0xFF;
    }
    
    if ((media != NULL) && media->status.instantiated)
    {
        message->locally_initiated = media->status.locally_initiated;
    }
    else
    {
        message->locally_initiated = TRUE;  /* A NULL media can only occur on locally initiated connections */
    }

    MessageSend(a2dp->clientTask, A2DP_MEDIA_OPEN_CFM, message);
}


void a2dpMediaCloseInd (remote_device *device, media_channel *media, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_CLOSE_IND);

    PRINT(("a2dpMediaCloseInd status=%u", status));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);
    message->status = status;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_CLOSE_IND, message);
}


void a2dpMediaStartInd (remote_device *device, media_channel *media)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_START_IND);

    PRINT(("a2dpMediaStartInd"));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);

    MessageSend(a2dp->clientTask, A2DP_MEDIA_START_IND, message);
}


void a2dpMediaStartCfm (remote_device *device, media_channel *media, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_START_CFM);

    PRINT(("a2dpMediaStartCfm status=%u", status));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);
    message->status = status;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_START_CFM, message);
}


void a2dpMediaSuspendInd (remote_device *device, media_channel *media)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_SUSPEND_IND);

    PRINT(("a2dpMediaSuspendInd"));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);

    MessageSend(a2dp->clientTask, A2DP_MEDIA_SUSPEND_IND, message);
}


void a2dpMediaSuspendCfm (remote_device *device, media_channel *media, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_SUSPEND_CFM);

    PRINT(("a2dpMediaSuspendCfm status=%u", status));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);
    message->status = status;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_SUSPEND_CFM, message);
}


void a2dpCodecConfigureInd (remote_device *device, uint8 local_seid, uint16 size_remote_service_caps, uint8* remote_service_caps)
{
    MAKE_A2DP_MESSAGE_WITH_LEN(A2DP_CODEC_CONFIGURE_IND, size_remote_service_caps);

    PRINT(("a2dpCodecConfigureInd local_seid=%u", local_seid));

    message->device_id = findDeviceId(device);
    message->local_seid = local_seid;
    message->size_codec_service_caps = size_remote_service_caps;
    memmove(message->codec_service_caps, remote_service_caps, size_remote_service_caps);

    MessageSend(a2dp->clientTask, A2DP_CODEC_CONFIGURE_IND, message);
}


void a2dpMediaReconfigureInd (remote_device *device, media_channel *media)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_RECONFIGURE_IND);

    PRINT(("a2dpMediaReconfigureInd"));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);

    MessageSend(a2dp->clientTask, A2DP_MEDIA_RECONFIGURE_IND, message);
}


void a2dpMediaReconfigureCfm (remote_device *device, media_channel *media, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_RECONFIGURE_CFM);

    PRINT(("a2dpMediaReconfigureCfm"));

    message->device_id = findDeviceId(device);
    message->stream_id = findStreamId(media);
    message->status = status;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_RECONFIGURE_CFM, message);
}


void a2dpMediaAvSyncDelayInd (remote_device *device, uint8 seid)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_AV_SYNC_DELAY_IND);

    PRINT(("a2dpMediaAvSyncDelayInd"));

    message->device_id = findDeviceId(device);
    message->seid = seid;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_AV_SYNC_DELAY_IND, message);
}


void a2dpMediaAvSyncDelayCfm (remote_device *device, uint8 seid, a2dp_status_code status)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_AV_SYNC_DELAY_CFM);

    PRINT(("a2dpMediaAvSyncDelayCfm"));

    message->device_id = findDeviceId(device);
    message->seid = seid;
    message->status = status;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_AV_SYNC_DELAY_CFM, message);
}

void a2dpMediaAvSyncDelayUpdatedInd (remote_device *device, uint8 seid, uint16 delay)
{
    MAKE_A2DP_MESSAGE(A2DP_MEDIA_AV_SYNC_DELAY_UPDATED_IND);

    PRINT(("a2dpMediaAvSyncDelayUpdatedInd"));

    message->device_id = findDeviceId(device);
    message->seid = seid;
    message->delay = delay;

    MessageSend(a2dp->clientTask, A2DP_MEDIA_AV_SYNC_DELAY_UPDATED_IND, message);
}

#if 0
/****************************************************************************/
void sendGetCurrentSepCapabilitiesCfm(a2dp_status_code status, const uint8 *caps, uint16 size_caps)
{
    MAKE_A2DP_MESSAGE_WITH_LEN(A2DP_GET_CURRENT_SEP_CAPABILITIES_CFM, size_caps);

    message->a2dp = a2dp;
    message->status = status;

    if (status == a2dp_success)
    {
        memmove(message->caps, caps, size_caps);
        message->size_caps = size_caps;
    }
    else
    {
        message->caps[0] = 0;
        message->size_caps = 0;
    }

    MessageSend(a2dp->clientTask, A2DP_GET_CURRENT_SEP_CAPABILITIES_CFM, message);
}
#endif



bool A2dpConfigureMaxRemoteDevices(uint8 max_remote_devs)
{
    /* Check we can handle this request */
    if((a2dp != NULL) && (max_remote_devs <= A2DP_MAX_REMOTE_DEVICES_DEFAULT) && (max_remote_devs > 0))
    {
        if(A2DP_MAX_REMOTE_DEVICES == max_remote_devs)
        {
            /* Request for current setting */
            return TRUE;
        }
        else if(A2DP_MAX_REMOTE_DEVICES > max_remote_devs)
        {
            /* If second device is not in use we can disable */
            if(BdaddrIsZero(&a2dp->remote_conn[1].bd_addr))
            {
                a2dp->max_remote_devs = 1;
                return TRUE;
            }
        }
        else
        {
            /* Nothing to stop us adding support for two devs */
            a2dp->max_remote_devs = 2;
            return TRUE;
        }
    }
    
    return FALSE;
}


/****************************************************************************/
bool A2dpSignallingConnectRequest (bdaddr *addr)
{
    if ((a2dp == NULL) || (addr == NULL) || BdaddrIsZero(addr))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_SIGNALLING_CONNECT_REQ);
        message->addr = *addr;

        MessageSend(&a2dp->task, A2DP_INTERNAL_SIGNALLING_CONNECT_REQ, message);
        return TRUE;
    }
}

bool A2dpSignallingConnectResponse (uint16 device_id, bool accept)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_SIGNALLING_CONNECT_RES);
        message->device = &a2dp->remote_conn[device_id];
        message->accept = accept;

        MessageSend(&a2dp->task, A2DP_INTERNAL_SIGNALLING_CONNECT_RES, message);
        return TRUE;
    }
}


bool A2dpSignallingDisconnectRequest (uint16 device_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ);
        message->device = &a2dp->remote_conn[device_id];

        MessageSend(&a2dp->task, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, message);
        return TRUE;
    }
}


Sink A2dpSignallingGetSink (uint16 device_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return (Sink)NULL;
    }

    if (a2dp->remote_conn[device_id].signal_conn.status.connection_state == avdtp_connection_connected)
    {
        return a2dp->remote_conn[device_id].signal_conn.connection.active.sink;
    }
    else
    {
        return (Sink)NULL;
    }
}

a2dp_signalling_state A2dpSignallingGetState (uint16 device_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return a2dp_signalling_idle;
    }

    return A2dpSignallingState[ a2dp->remote_conn[device_id].signal_conn.status.connection_state ];
}


bool A2dpDeviceGetBdaddr (uint16 device_id, bdaddr *addr)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        BdaddrSetZero(addr);
        return FALSE;
    }

    if (a2dp->remote_conn[device_id].signal_conn.status.connection_state == avdtp_connection_idle)
    {
        BdaddrSetZero(addr);
        return FALSE;
    }
    else
    {
        *addr = a2dp->remote_conn[device_id].bd_addr;
        return TRUE;
    }
}


bool A2dpDeviceManageLinkloss (uint16 device_id, bool enable)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }

    if (a2dp->remote_conn[device_id].signal_conn.status.connection_state != avdtp_connection_connected)
    {
        return FALSE;
    }
    else
    {
        a2dp->remote_conn[device_id].manage_linkloss = enable;
        return TRUE;
    }
}


bool A2dpMediaOpenRequest (uint16 device_id, uint16 size_seid_list, uint8 *seid_list)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE_WITH_LEN(A2DP_INTERNAL_MEDIA_OPEN_REQ, size_seid_list);
        message->device = &a2dp->remote_conn[device_id];
        if (size_seid_list && seid_list)
        {
            message->size_seid_list = size_seid_list;
            memmove( message->seid_list, seid_list, size_seid_list);
        }
        else
        {
            message->size_seid_list = 0;
        }
        

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_OPEN_REQ, message);
        return TRUE;
    }
}


bool A2dpMediaOpenResponse(uint16 device_id, bool accept)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_OPEN_RES);
        message->device = &a2dp->remote_conn[device_id];
        message->accept = accept;

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_OPEN_RES, message);
        return TRUE;
    }
}


bool A2dpMediaCloseRequest (uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_CLOSE_REQ);
        message->device = &a2dp->remote_conn[device_id];
        message->media = &message->device->media_conn[stream_id];

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_CLOSE_REQ, message);
        return TRUE;
    }
}


bool A2dpMediaStartRequest (uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_START_REQ);
        message->device = &a2dp->remote_conn[device_id];
        message->media = &message->device->media_conn[stream_id];

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_START_REQ, message);
        return TRUE;
    }
}


bool A2dpMediaStartResponse (uint16 device_id, uint16 stream_id, bool accept)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_START_RES);
        message->device = &a2dp->remote_conn[device_id];
        message->media = &message->device->media_conn[stream_id];
        message->accept = accept;

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_START_RES, message);
        return TRUE;
    }
}


bool A2dpMediaSuspendRequest (uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_SUSPEND_REQ);
        message->device = &a2dp->remote_conn[device_id];
        message->media = &message->device->media_conn[stream_id];

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_SUSPEND_REQ, message);
        return TRUE;
    }
}


bool A2dpMediaReconfigureRequest (uint16 device_id, uint16 stream_id, uint16 service_caps_size, const uint8 *service_caps)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_RECONFIGURE_REQ);
        message->device = &a2dp->remote_conn[device_id];
        message->media = &message->device->media_conn[stream_id];
        message->service_caps_size = service_caps_size;
        message->service_caps = service_caps;

        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_RECONFIGURE_REQ, message);
        return TRUE;
    }
}


bool A2dpMediaAvSyncDelayRequest(uint16 device_id, uint8 seid, uint16 delay)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_REQ);
        message->device = &a2dp->remote_conn[device_id];
        message->seid = seid;
        message->delay = delay;
        
        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_REQ, message);
        return TRUE;
    }
}


uint16 A2dpMediaAvSyncDelayResponse (uint16 device_id, uint8 seid, uint16 delay)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_RES);
        message->device = &a2dp->remote_conn[device_id];
        message->seid = seid;
        message->delay = delay;
        
        MessageSend(&a2dp->task, A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_RES, message);
        return TRUE;
    }
}


Sink A2dpMediaGetSink (uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return (Sink)NULL;
    }

    if (a2dp->remote_conn[device_id].media_conn[stream_id].status.connection_state == avdtp_connection_connected)
    {
        return a2dp->remote_conn[device_id].media_conn[stream_id].connection.active.sink;
    }
    else
    {
        return (Sink)NULL;
    }
}


a2dp_role_type A2dpMediaGetRole(uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return a2dp_role_undefined;
    }

    if (a2dp->remote_conn[device_id].media_conn[stream_id].status.connection_state == avdtp_connection_connected)
    {
        return a2dp->remote_conn[device_id].local_sep.role;
    }
    else
    {
        return a2dp_role_undefined;
    }
}


a2dp_stream_state A2dpMediaGetState (uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return a2dp_stream_idle;
    }

    /* TODO: Make multiple stream aware */
    return A2dpStreamState[ a2dp->remote_conn[device_id].signal_conn.status.stream_state ];
}

a2dp_codec_settings * A2dpCodecGetSettings (uint16 device_id, uint16 stream_id)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES) || (stream_id >= A2DP_MAX_MEDIA_CHANNELS))
    {
        return NULL;
    }

    /* TODO: Make multiple stream aware */
    return a2dpGetCodecAudioParams( &a2dp->remote_conn[device_id] );
}

bool A2dpCodecSetAvailable(uint16 device_id, uint8 seid, bool available)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    
    return a2dpSetSepAvailable(&a2dp->remote_conn[device_id], seid, available);
}


bool A2dpCodecGetAvailable(uint16 device_id, uint8 seid)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }

    return !a2dpGetSepAvailability(&a2dp->remote_conn[device_id], seid);
}

/*****************************************************************************/
bool A2dpCodecConfigureResponse(uint16 device_id, bool accept, uint8 local_seid, uint16 size_codec_service_caps, uint8 *codec_service_caps)
{
    if ((a2dp == NULL) || (device_id >= A2DP_MAX_REMOTE_DEVICES))
    {
        return FALSE;
    }
    else
    {
        if (accept)
        {
            if ((codec_service_caps == NULL) || (size_codec_service_caps == 0))
            {   /* Accepting so must be supplied some caps */
                return FALSE;
            }
        }
        else
        {   /* Rejecting so don't need to pass any supplied caps */
            size_codec_service_caps = 0;
        }
        
        {
            MAKE_A2DP_MESSAGE_WITH_LEN(A2DP_INTERNAL_CODEC_CONFIGURE_RSP, size_codec_service_caps);
            
            if ((message->size_codec_service_caps = size_codec_service_caps) > 0)
            {
                memmove(message->codec_service_caps, codec_service_caps, size_codec_service_caps);
            }
            
            message->device = &a2dp->remote_conn[device_id];
            message->local_seid = local_seid;
            message->accept = accept;
                    
            MessageSend(&a2dp->task, A2DP_INTERNAL_CODEC_CONFIGURE_RSP, message);
            return TRUE;
        }
    }
}


#if 0
/*****************************************************************************/
void A2dpGetCurrentSepCapabilities(A2DP *dep_a2dp)
{
    dep_a2dp = dep_a2dp;

#ifdef A2DP_DEBUG_LIB
    if (!a2dp)
        A2DP_DEBUG(("A2dpGetCurrentSepCapabilities NULL instance\n"));
#endif

    if ((a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_open) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_streaming) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_local_starting) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_local_suspending) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_reconfig_reading_caps) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_reconfiguring)
        )
    {
        if (a2dpSendGetCapabilities(a2dp->sep.remote_seid))
        {
            /* Start watchdog */
            PRINT(("A2dpGetCurrentSepCapabilities seid=%d\n",a2dp->sep.remote_seid));
            MessageSendLater(&a2dp->task, A2DP_INTERNAL_GET_CAPS_TIMEOUT_IND, 0, WATCHDOG_TGAVDP100);
            return;
        }
    }

    sendGetCurrentSepCapabilitiesCfm(a2dp_wrong_state, 0, 0);
}
#endif

#if 0
/*****************************************************************************/
uint8 *A2dpGetCurrentSepConfiguration(A2DP *a2dp, uint16 *size_caps)
{
    if ((a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_open) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_streaming) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_local_starting) ||
        (a2dp->remote_conn[0].signal_conn.stream_state == avdtp_stream_local_suspending)
        )
    {
        uint8 *service_caps = blockGetBase( data_block_configured_service_caps );
        if (service_caps)
        {
            uint8 *caps;
            uint16 size_service_caps = blockGetSize( data_block_configured_service_caps );

            /* Create copy of service caps for app, since the library one could move */
            /* Expectation is that app will free this memory when it has finished with it */
            caps = (uint8 *)malloc( size_service_caps );
            if (caps != NULL)
            {
                memmove( caps, service_caps, size_service_caps);
                *size_caps = size_service_caps;
                return caps;
            }
        }
    }

    /* Control only reaches here if we haven't got valid caps to return */
    *size_caps = 0;
    return 0;
}
#endif

