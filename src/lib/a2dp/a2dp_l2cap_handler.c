/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_l2cap_handler.c

DESCRIPTION


NOTES

*/


/****************************************************************************
    Header files
*/
#include "a2dp.h"
#include "a2dp_init.h"
#include "a2dp_l2cap_handler.h"
#include "a2dp_profile_handler.h"
#include "a2dp_packet_handler.h"
#include "a2dp_command_handler.h"
#include "a2dp_api.h"

#include <print.h>
#include <stdlib.h>
#include <bdaddr.h>
#include <source.h>
#include <string.h>
#include <util.h>

#include <sink.h>
#include <stream.h>
#include <sdp_parse.h>

/*****************************************************************************/

#define CONNECT_DELAY_IMMEDIATE ((uint32)0)
#define CONNECT_DELAY_RANDOM    ((uint32)-1)

#define MIN(a,b)    (((a)<(b))?(a):(b))


static const uint16 a2dp_conftab[] =
{
    L2CAP_AUTOPT_SEPARATOR,                             /* START */
    L2CAP_AUTOPT_MTU_IN,            0x037F,             /* Maximum inbound MTU - 895 bytes */
    L2CAP_AUTOPT_MTU_OUT,           0x0030,             /* Minimum acceptable outbound MTU - 48 bytes */
    L2CAP_AUTOPT_FLUSH_IN,          0x0000, 0x0000,     /* Min acceptable remote flush timeout - zero*/
                                    0xFFFF, 0xFFFF,     /* Max acceptable remote flush timeout - infinite*/
    L2CAP_AUTOPT_FLUSH_OUT,         0xFFFF, 0xFFFF,     /* Min local flush timeout - infinite */
                                    0xFFFF, 0xFFFF,     /* Max local flush timeout - infinite */
    L2CAP_AUTOPT_TERMINATOR                             /* END */
};


/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), AdvancedAudioDistribution(0x110D) */
static const uint8 avdtp_general_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0D};

/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), AudioSource(0x110A) */
static const uint8 avdtp_source_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0A};

/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), AudioSink(0x110B) */
static const uint8 avdtp_sink_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0B};

/* DataElSeq(0x35), Length(0x03), DataElUint16(0x09), BluetoothProfileDescriptorList(0x0009) */
static const uint8 avdtp_attr_list[] = {0x35, 0x03, 0x09, 0x00, 0x09};


/*****************************************************************************/
static a2dp_status_code convertDisconnectStatusCode(l2cap_disconnect_status l2cap_status)
{
    switch (l2cap_status)
    {
    case l2cap_disconnect_successful:
        return a2dp_success;
    case l2cap_disconnect_no_connection:
        return a2dp_no_signalling_connection;
    case l2cap_disconnect_link_loss:
        return a2dp_disconnect_link_loss;
    case l2cap_disconnect_timed_out:
    case l2cap_disconnect_error:
    default:
        return a2dp_operation_fail;
    }
}


/*****************************************************************************/
static void startLinklossTimer (remote_device *device)
{
    PRINT(("startLinklossTimer %X",(uint16)device));
    
    MessageCancelAll(&a2dp->task, A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + device->device_id);
    MessageSendLater(&a2dp->task, A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + device->device_id, NULL, D_SEC(a2dp->linkloss_timeout));
    device->linkloss = TRUE;
    device->linkloss_timer_expired = FALSE;
}


/*****************************************************************************/
static void stopLinklossTimer (remote_device *device)
{
    PRINT(("stopLinklossTimer %X",(uint16)device));
    
    MessageCancelAll(&a2dp->task, A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + device->device_id);
    device->linkloss = FALSE;
    device->linkloss_timer_expired = FALSE;
}


/*****************************************************************************/
static remote_device* findDeviceFromSink (Sink sink)
{
    uint8 i;
    typed_bdaddr taddr;
    
    if (sink != NULL)
    {
        /* Any signalling/media sinks from the same device will resolve to the same bdaddr */
        if ( SinkIsValid(sink) && SinkGetBdAddr(sink, &taddr) )
        {
            for (i=0; i<A2DP_MAX_REMOTE_DEVICES; i++)
            {
                if ( BdaddrIsSame( &a2dp->remote_conn[i].bd_addr, &taddr.addr ) )
                {
                    PRINT(("[%04X %02X %06lX] sink=%X id=%u ",
                            taddr.addr.nap,
                            taddr.addr.uap,
                            taddr.addr.lap,
                            (uint16)sink,i));
                    return &a2dp->remote_conn[i];
                }
            }
        }
        else
        {   /* The sink has been disconnected and is no longer valid.  We'll have to find it the slow way */
            for (i=0; i<A2DP_MAX_REMOTE_DEVICES; i++)
            {
                remote_device *device = &a2dp->remote_conn[i];
                if ( ((device->signal_conn.status.connection_state == avdtp_connection_connected) || 
                      (device->signal_conn.status.connection_state == avdtp_connection_disconnecting) ||
                      (device->signal_conn.status.connection_state == avdtp_connection_disconnect_pending)) && 
                     (device->signal_conn.connection.active.sink == sink) )
                {
                    PRINT(("sink=%X id=%u ",(uint16)sink,i));
                    return device;
                }
                else
                {
                    uint8 j;
                    
                    for (j=0; j<A2DP_MAX_MEDIA_CHANNELS; j++)
                    {
                        media_channel *media = &device->media_conn[j];
                        if ( ((media->status.connection_state == avdtp_connection_connected) ||
                              (media->status.connection_state == avdtp_connection_disconnecting) ||
                              (media->status.connection_state == avdtp_connection_disconnect_pending)) && 
                             (media->connection.active.sink == sink) )
                        {
                            PRINT(("sink=%X id=%u ",(uint16)sink,i));
                            return device;
                        }
                    }
                }
            }
        }
    }

    PRINT(("Sink=%X id=UNKNOWN ",(uint16)sink));
    return NULL;
}


/*****************************************************************************/
static remote_device* findDeviceFromBdaddr (const bdaddr *addr)
{
    uint8 i;
    
    if ( !BdaddrIsZero( addr ) )
    {
        for (i=0; i<A2DP_MAX_REMOTE_DEVICES; i++)
        {
            if ( BdaddrIsSame( &a2dp->remote_conn[i].bd_addr, addr ) )
            {
                PRINT(("[%04X %02X %06lX] id=%u ",addr->nap,addr->uap,addr->lap,i));
                return &a2dp->remote_conn[i];
            }
        }
    }

    PRINT(("[%04X %02X %06lX] id=UNKNOWN ",addr->nap,addr->uap,addr->lap));
    return NULL;
}


/*****************************************************************************/
static remote_device* addDevice (const bdaddr *addr)
{
    uint8 i;

    PRINT((" addDevice"));    
    if ( !BdaddrIsZero( addr ) )
    {
        for (i=0; i<A2DP_MAX_REMOTE_DEVICES; i++)
        {
            if ( BdaddrIsZero( &a2dp->remote_conn[i].bd_addr ) )
            {   /* Ok to add a new device - init the data structure */
                remote_device *device = &a2dp->remote_conn[i];
                memset( device, 0, sizeof(remote_device) );  /* Assumes enumerated type defaults are zero in value */
                device->bd_addr = *addr;
                device->device_id = i;
                device->instantiated = TRUE;
                PRINT(("device_id=%u [device=%X]\n",i, (uint16)device));
                return device;
            }
        }
    }

    PRINT(("-fail\n"));
    return NULL;
}


/*****************************************************************************/
static bool removeDevice (remote_device *device)
{
    PRINT(("removeDevice[%X]\n",(uint16)device));    
    if (device != NULL)
    {
        memset( device, 0, sizeof(remote_device) );  /* Assumes enumerated type defaults are zero in value */
        return TRUE;
    }

    return FALSE;
}


/*****************************************************************************/
static signalling_channel *initiateSignalling (remote_device *device, uint16 connection_id, uint8 identifier)
{
    PRINT((" initiateSignalling device=%X connection_id=%u identifier=%u",(uint16)device, connection_id, identifier));
        
    if (device != NULL)
    {
        signalling_channel *signalling = &device->signal_conn;
        
        if ( signalling->status.connection_state == avdtp_connection_idle )
        {   /* Ok to add a new device - init the data structure */
            memset( signalling, 0, sizeof(signalling_channel) );  /* Assumes enumerated type defaults are zero in value */

            if (connection_id == AVDTP_OUTGOING_CONNECTION_ID)
            {
                signalling->connection.setup.outbound_cid = connection_id;
                signalling->status.connection_state = avdtp_connection_paging;
            }
            else
            {
                signalling->connection.setup.inbound_cid = connection_id;
                signalling->connection.setup.inbound_id = identifier;
                signalling->status.connection_state = avdtp_connection_paged;
            }
            PRINT(("(signalling=%X)\n",(uint16)signalling));
            
            return signalling;
        }
        else if ( (signalling->status.connection_state == avdtp_connection_paging) && (connection_id != AVDTP_OUTGOING_CONNECTION_ID) )
        {   /* Incoming connection request has rippled up from lower stack layers - manage this crossover condition */
            signalling->status.connection_state = avdtp_connection_crossover;
            signalling->connection.setup.inbound_cid = connection_id;
            signalling->connection.setup.inbound_id = identifier;
            PRINT(("(signalling=%X)\n",(uint16)signalling));
            
            return signalling;
        }
    }
    
    return NULL;
}


/*****************************************************************************/
static bool completeSignalling (signalling_channel *signalling, uint16 connection_id, Sink sink, uint16 mtu)
{
    PRINT((" completeSignalling signalling=%X sink=%X mtu=%u\n",(uint16)signalling, (uint16)sink, mtu));
    
    if (signalling != NULL)
    {
        if ( (signalling->status.connection_state == avdtp_connection_paging) || 
             (signalling->status.connection_state == avdtp_connection_paged) ||
             (signalling->status.connection_state == avdtp_connection_crossover) )
        {   /* Finalise the channel information */
            if (connection_id == signalling->connection.setup.outbound_cid)
            {
                signalling->status.locally_initiated = TRUE;
            }
            
            signalling->connection.active.sink = sink;
            signalling->connection.active.mtu = MIN(DEFAULT_L2CAP_LOCAL_MTU_MAXIMUM, mtu);
            signalling->status.connection_state = avdtp_connection_connected;
            return TRUE;
        }
        
        if (signalling->status.connection_state == avdtp_connection_connected)
        {   /* Update the stored MTU due to an L2CAP parameter renegotiation */
            signalling->connection.active.mtu = mtu;
            return TRUE;
        }
        
    }
    
    return FALSE;
}


/*****************************************************************************/
static void requestRemoteA2dpVersion (remote_device *device)
{
    PRINT(("requestRemoteA2dpVersion from [%X]\n",(uint16)device));
    
    if (device && device->instantiated && (device->profile_version==avdtp_version_not_requested) && !BdaddrIsZero(&device->bd_addr))
    {
        switch (a2dp->profile_role)
        {
        case A2DP_INIT_ROLE_SOURCE:
            /* This A2DP instance configured to support Source role only */
            ConnectionSdpServiceSearchAttributeRequest(&a2dp->task, &device->bd_addr, 32, sizeof(avdtp_sink_search_pattern), avdtp_sink_search_pattern, sizeof(avdtp_attr_list), avdtp_attr_list);
            break;
            
        case A2DP_INIT_ROLE_SINK:
            /* This A2DP instance configured to support Sink role only */
            ConnectionSdpServiceSearchAttributeRequest(&a2dp->task, &device->bd_addr, 32, sizeof(avdtp_source_search_pattern), avdtp_source_search_pattern, sizeof(avdtp_attr_list), avdtp_attr_list);
            break;
            
        default:
            /* This A2DP instance configured to support both Source and Sink roles */
            ConnectionSdpServiceSearchAttributeRequest(&a2dp->task, &device->bd_addr, 32, sizeof(avdtp_general_search_pattern), avdtp_general_search_pattern, sizeof(avdtp_attr_list), avdtp_attr_list);
            break;
        }
    }
}


/*****************************************************************************/
void a2dpHandleSdpServiceSearchAttributeCfm (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm)
{
    remote_device *device = findDeviceFromBdaddr(&cfm->bd_addr);
    
    PRINT(("a2dpHandleSdpServiceSearchAttributeCfm "));
    
	/* Only use version from first A2DP SDP record. Assume same AVDTP version is supported by a device advertising both Source and Sink roles */
    if (device && (device->profile_version==avdtp_version_not_requested))	
    {
        PRINT(("device=%X connection_state=%u\n",(uint16)device,device->signal_conn.status.connection_state));
        
        /* Initially assume no valid AVDTP version information has been returned */
        device->profile_version = avdtp_version_unknown;
        
        if ( (cfm->status==sdp_response_success) && !cfm->error_code )
        {   /* Response obtained, examine it */
            uint16 version;
            
            /* Obtain AdvancedAudioDistribution Profile version */
            if ( SdpParseGetProfileVersion(cfm->size_attributes, cfm->attributes, 0x110D, &version) )
            {
                PRINT(("  A2DP Version=0x%X\n",version));
                
                switch (version)
                {
                case 0x0100:
                    device->profile_version = avdtp_version_10;
                    break;
                    
                case 0x0102:
                    device->profile_version = avdtp_version_12;
                    break;
                   
                case 0x0103:
#ifndef A2DP_1_2                     
                    device->profile_version = avdtp_version_13;
#else
                    /* If in v1.2 mode set version correctly */
                    device->profile_version = avdtp_version_12;
#endif              
                    break;
                default:
                    device->profile_version = avdtp_version_pre_10;
                    break;
                }
            }
        }
        
        if (device->signal_conn.status.connection_state == avdtp_connection_connected)
        {   /* Issue cfm message and start processing AVDTP commands, as SDP search has now completed */
            a2dpSignallingConnectCfm(device, a2dp_success);
        
            /* Check for data in the buffer */
            a2dpHandleSignalPacket( device );
        }
    }
}


/*****************************************************************************/
static media_channel* initiateMedia (remote_device *device, uint16 connection_id, uint8 identifier)
{
    uint8 i;
    
    PRINT((" initiateMedia device=%X connection_id=%u identifier=%u",(uint16)device, connection_id, identifier));
    
    if (device != NULL)
    {
        for (i=0; i<A2DP_MAX_MEDIA_CHANNELS; i++)
        {
            if ( device->media_conn[i].status.connection_state == avdtp_connection_idle )
            {   /* Ok to add a new device - init the data structure */
                media_channel *media = &device->media_conn[i];
                memset( media, 0, sizeof(media_channel) );  /* Assumes enumerated type defaults are zero in value */

                media->status.media_id = i;
                media->status.instantiated = TRUE;
                
                if (connection_id == AVDTP_OUTGOING_CONNECTION_ID)
                {
                    media->connection.setup.outbound_cid = connection_id;
                    media->status.connection_state = avdtp_connection_paging;
                }
                else
                {
                    media->connection.setup.inbound_cid = connection_id;
                    media->connection.setup.inbound_id = identifier;
                    media->status.connection_state = avdtp_connection_paged;
                }

                PRINT(("media_id=%u [media=%X]\n",i, (uint16)media));
            
                return media;
            }
        }
    }
    
    return NULL;
}


/*****************************************************************************/
static bool completeMedia (media_channel *media, uint16 connection_id, Sink sink, uint16 mtu)
{
    PRINT((" completeMedia cid=%u media=%X sink=%X mtu=%u\n",(uint16)media, connection_id, (uint16)sink, mtu));
    
    if (media != NULL)
    {
        if ( (media->status.connection_state == avdtp_connection_paging) || (media->status.connection_state == avdtp_connection_paged) )
        {   /* Finalise channel information */
            if (connection_id == media->connection.setup.outbound_cid)
            {
                media->status.locally_initiated = TRUE;
            }
            media->connection.active.sink = sink;
            media->connection.active.mtu = MIN(DEFAULT_L2CAP_LOCAL_MTU_MAXIMUM, mtu);
            media->status.connection_state = avdtp_connection_connected;
            return TRUE;
        }
        
        if (media->status.connection_state == avdtp_connection_connected)
        {   /* Update the stored MTU due to an L2CAP parameter renegotiation */
            media->connection.active.mtu = mtu;
            return TRUE;
        }
    }
    
    return FALSE;
}


/*****************************************************************************/
static bool removeMedia (media_channel *media)
{
    PRINT(("removeMedia[%X]\n",(uint16)media));    
    if (media != NULL)
    {
        memset( media, 0, sizeof(media_channel) );  /* Assumes enumerated type defaults are zero in value */
        return TRUE;
    }
    
    return FALSE;
}


/*****************************************************************************/
static media_channel* findMediaFromSink (remote_device *device, Sink sink)
{
    uint8 i;
    
    if ( (device != NULL) && (sink != NULL) )
    {
        for (i=0; i<A2DP_MAX_MEDIA_CHANNELS; i++)
        {
            media_channel *media = &device->media_conn[i];
            
            if ( ((media->status.connection_state == avdtp_connection_connected) || 
                  (media->status.connection_state == avdtp_connection_disconnecting) ||
                  (media->status.connection_state == avdtp_connection_disconnect_pending)) && 
                 (media->connection.active.sink == sink) )
            {
                return media;
            }
        }
    }
    
    return NULL;
}


/*****************************************************************************/
static media_channel* findMediaFromConnectionId (remote_device *device, uint16 connection_id)
{
    uint8 i;
    
    if (device != NULL)
    {
        for (i=0; i<A2DP_MAX_MEDIA_CHANNELS; i++)
        {
            media_channel *media = &device->media_conn[i];
            
            switch (media->status.connection_state)
            {
            case avdtp_connection_idle:
                break;
                
            case avdtp_connection_paging:
            case avdtp_connection_paged:
            case avdtp_connection_crossover:
                 /* Only one media channel is established, per device, at any one time so these checks are valid to perform */
                 if ( (connection_id == media->connection.setup.inbound_cid) ||
                      (connection_id == media->connection.setup.outbound_cid) ||
                      (AVDTP_OUTGOING_CONNECTION_ID == media->connection.setup.outbound_cid) )
                 {
                     return media;
                 }
                 break;
                 
            case avdtp_connection_connected:
            case avdtp_connection_disconnecting:
            case avdtp_connection_disconnect_pending:
                /* We no longer store a connection id, so obtain it via the stored sink */
                if (connection_id == SinkGetL2capCid(media->connection.active.sink))
                {
                    return media;
                }
                break;                
            }
        }
    }
    
    return NULL;
}


/*****************************************************************************/
static bool isSignallingConnected (remote_device *device)
{
    if (device != NULL)
    {
        if ( (device->signal_conn.status.connection_state == avdtp_connection_connected) ||
             (device->signal_conn.status.connection_state == avdtp_connection_disconnecting) ||
             (device->signal_conn.status.connection_state == avdtp_connection_disconnect_pending))  /* Still consider as connected while disconnecting */
        {
            return TRUE;
        }
    }
    
    return FALSE;
}


/*****************************************************************************/
static bool isMediaConnected (remote_device *device)
{
    if (device != NULL)
    {
        uint8 i;
    
        for (i=0; i<A2DP_MAX_MEDIA_CHANNELS; i++)
        {
            media_channel *media = &device->media_conn[i];
            
            if ( (media->status.connection_state == avdtp_connection_connected) ||
                 (media->status.connection_state == avdtp_connection_disconnecting) ||
                 (media->status.connection_state == avdtp_connection_disconnect_pending))  /* Still consider as connected while disconnecting */
            {
                return TRUE;
            }
        }
    }
    
    return FALSE;
}


/*****************************************************************************/
static void l2capConnectRequest(uint32 delay, remote_device *device, uint16 conftab_size, uint16 *conftab)
{
    PRINT(("l2capConnectRequest delay=%ld\n",delay));
    
    if (delay==CONNECT_DELAY_IMMEDIATE)
    {
        ConnectionL2capConnectRequest(&a2dp->task, &device->bd_addr, AVDTP_PSM, AVDTP_PSM, conftab_size, conftab);
        return;
    }
    
    if (delay==CONNECT_DELAY_RANDOM)
    {
        delay = UtilRandom()/20;    /* 0 to 3.2secs */
        PRINT(("l2capConnectRequest random delay=%lu\n",delay));
    }
    
    {
        MAKE_A2DP_MESSAGE(A2DP_INTERNAL_L2CAP_CONNECT_REQ);
        message->device = device;
        message->conftab_size = conftab_size;
        message->conftab = conftab;
        
        MessageSendLater(&a2dp->task, A2DP_INTERNAL_L2CAP_CONNECT_REQ, message, delay);
    }
}


/*****************************************************************************/
bool a2dpSignallingDisconnectPending (remote_device *device)
{
    if ((device != NULL) && (device->signal_conn.status.connection_state == avdtp_connection_disconnect_pending))
    {   /* Signalling channel disconnect is pending - do it now */
        device->signal_conn.status.connection_state = avdtp_connection_disconnecting;
        ConnectionL2capDisconnectRequest(&a2dp->task, device->signal_conn.connection.active.sink);
        
        return TRUE;
    }
    
    return FALSE;
}


/*****************************************************************************/
bool a2dpDisconnectAllMedia (remote_device *device)
{
    bool result = FALSE;
    
    if (device != NULL)
    {
        uint8 i;
    
        for (i=0; i<A2DP_MAX_MEDIA_CHANNELS; i++)
        {
            media_channel *media = &device->media_conn[i];
            
            if ( (media->status.connection_state == avdtp_connection_paging) ||
                 (media->status.connection_state == avdtp_connection_paged) )
            {   
                media->status.connection_state = avdtp_connection_disconnect_pending;
                result = TRUE;
            }
            else if ( media->status.connection_state == avdtp_connection_connected )
            {   
                media->status.connection_state = avdtp_connection_disconnecting;
                ConnectionL2capDisconnectRequest(&a2dp->task, media->connection.active.sink);
                
                result = TRUE;
            }
            else if ( media->status.connection_state == avdtp_connection_disconnecting )
            {   /* Media channel is already being disconnected */
                result = TRUE;
            }
        }
    }
    
    return result;
}


/*****************************************************************************/
remote_device * a2dpFindDeviceFromSink (Sink sink)
{
    if (sink && SinkIsValid(sink))
    {
        return findDeviceFromSink( sink );
    }
    
    return NULL;
}


/*****************************************************************************/
void a2dpRegisterL2cap(void)
{
    ConnectionL2capRegisterRequest(&a2dp->task, AVDTP_PSM, 0);
}


/*****************************************************************************/
void a2dpHandleL2capRegisterCfm(const CL_L2CAP_REGISTER_CFM_T *cfm)
{
    /* Send a confirmation message to the client regardless of the outcome */
    a2dpSendInitCfmToClient((cfm->status == success) ? a2dp_success : a2dp_l2cap_fail);
}


/*****************************************************************************/
void a2dpHandleL2capLinklossTimeout(MessageId msg_id)
{
    PanicFalse((uint16)(msg_id-A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE) < A2DP_MAX_REMOTE_DEVICES);

    {    
        remote_device *device = &a2dp->remote_conn[(uint16)(msg_id-A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE)];

        if (device->linkloss && !device->linkloss_timer_expired)
        {
            device->linkloss_timer_expired = TRUE;
        }
    }
}


/*****************************************************************************/
void a2dpHandleSignallingConnectReq(const A2DP_INTERNAL_SIGNALLING_CONNECT_REQ_T *req)
{
    remote_device *device = findDeviceFromBdaddr(&req->addr);
    
    PRINT(("a2dpHandleL2capSignallingConnectReq"));    
    
    if (device != NULL)
    {   /* We are connecting/have connected to this device */
        signalling_channel *signalling = &device->signal_conn;

        PRINT((" signalling state=%u\n",signalling->status.connection_state));
        switch (signalling->status.connection_state)
        {
        case avdtp_connection_idle:     /* Can be in idle state after a link loss */
        case avdtp_connection_paging:
        case avdtp_connection_paged:
        case avdtp_connection_crossover:
            /* Already processing a connection request to/from the device, reject this one */
            a2dpSignallingConnectCfm(device, a2dp_wrong_state);
            break;

        case avdtp_connection_connected:
            /* Can only support one signalling connection to a remote device */
            a2dpSignallingConnectCfm(device, a2dp_max_connections);
            break;
            
        case avdtp_connection_disconnecting:
        case avdtp_connection_disconnect_pending:
            /* Currently disconnecting.  Re-issue request when disconnection completes */
            {
                MAKE_A2DP_MESSAGE(A2DP_INTERNAL_SIGNALLING_CONNECT_REQ);
                message->addr = req->addr;
                /* On disconnection removeDevice() will be called which will zero the remote_device structure contents. */
                /* bd_addr is the closest thing to a uint16.                                                            */
                MessageSendConditionally(&a2dp->task, A2DP_INTERNAL_SIGNALLING_CONNECT_REQ, message, (uint16 *)&device->bd_addr);
            }
            break;
        }
    }
    else
    {   /* Outgoing request to a new device */
        if ( (device=addDevice(&req->addr))!=NULL )
        {   /* Able to support a new connection */
            PanicNull( initiateSignalling( device, AVDTP_OUTGOING_CONNECTION_ID, 0 ) );    /* This should never panic */
            l2capConnectRequest(CONNECT_DELAY_IMMEDIATE, device, sizeof(a2dp_conftab), (uint16 *)a2dp_conftab);
            requestRemoteA2dpVersion(device);
        }
        else
        {   /* Unable to support this connection - already connected to the maximum number of supported devices */
            a2dpSignallingConnectCfm(NULL, a2dp_max_connections);
        }
    }
}


/*****************************************************************************/
void a2dpMediaConnectReq(remote_device *device)
{
    /* We are connecting/have connected to this device */
    signalling_channel *signalling = &device->signal_conn;
    
    PRINT(("a2dpMediaConnectReq signalling state=%u",signalling->status.connection_state));
    switch (signalling->status.connection_state)
    {
    case avdtp_connection_idle:
    case avdtp_connection_paging:
    case avdtp_connection_paged:
    case avdtp_connection_crossover:
        /* Already processing a connection request to/from the device, reject this one */
        a2dpMediaOpenCfm(device, NULL, a2dp_wrong_state);
        break;

    case avdtp_connection_connected:
        /* Ok to request a media channel */
        {   /* No media channel currently being setup, ok to request one */
            media_channel *media = initiateMedia(device, AVDTP_OUTGOING_CONNECTION_ID, 0);
            if (media != NULL)
            {   /* Able to initiate a media connection */
                l2capConnectRequest(CONNECT_DELAY_IMMEDIATE, device, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
            }
            else
            {   /* Unable to initiate any more media connections */
                a2dpMediaOpenCfm(device, NULL, a2dp_max_connections);
            }
        }
        break;
        
    case avdtp_connection_disconnecting:
    case avdtp_connection_disconnect_pending:
        /* Currently disconnecting, reject this one */
        a2dpMediaOpenCfm(device, NULL, a2dp_wrong_state);
        break;
    }
}


/*****************************************************************************/
void a2dpHandleSignallingConnectRes(const A2DP_INTERNAL_SIGNALLING_CONNECT_RES_T *res)
{
    signalling_channel *signalling = &((remote_device *)PanicNull(res->device))->signal_conn;
    
    PRINT(("a2dpHandleSignallingConnectRes device=%X",(uint16)res->device));    
    
    if (signalling != NULL)
    {
        PRINT((" signalling state=%u",signalling->status.connection_state));
        
        switch (signalling->status.connection_state)
        {
        case avdtp_connection_idle:
        case avdtp_connection_paging:
        case avdtp_connection_disconnecting:
        case avdtp_connection_disconnect_pending:
            /* Should not be able to get here */
            PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpHandleL2capConnectRes %u\n",signalling->status.connection_state));
            break;
            
        case avdtp_connection_crossover:
            /* An incoming and outgoing connection have been requested simultaneously */
            if (!res->accept)
            {   /* Incoming connection has been rejected - update state to reflect this */
                signalling->status.connection_state = avdtp_connection_paging;
            }
            /* Drop through */
        case avdtp_connection_paged:
            /* Send reponse to remote device */
            ConnectionL2capConnectResponse(&a2dp->task, res->accept, AVDTP_PSM, signalling->connection.setup.inbound_cid, signalling->connection.setup.inbound_id, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
            signalling->connection.setup.inbound_id = 0;    /* Zero the identifier to indicate we have responded */
            requestRemoteA2dpVersion(res->device);
            break;
    
        case avdtp_connection_connected:    /* Will occur if remote side accepts outgoing connection before application issues a response to an incoming */
            /* Already connected.  Inbound connection will have already been rejected automatically so silently drop this response */
            break;
        }
    }
}


/****************************************************************************/
void a2dpHandleSignallingDisconnectReq(const A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ_T *req)
{
    /* We should already know about the device sending us a message */
    remote_device *device = (remote_device *)PanicNull(req->device);
    
    PRINT(("a2dpHandleL2capSignallingDisconnectReq device=%X",(uint16)req->device));    
    
    if ( device )
    {
        signalling_channel *signalling = &device->signal_conn;
        
        PRINT((" signalling state=%u",signalling->status.connection_state));
        PRINT((" stream state %u\n", signalling->status.stream_state));
        
        /* Request to disconnect, so prevent any linkloss management */
        device->manage_linkloss = FALSE;
        
        switch (signalling->status.connection_state)
        {
        case avdtp_connection_idle:
            /* Already disconnected */
            break;
        case avdtp_connection_paging:
        case avdtp_connection_paged:
        case avdtp_connection_crossover:
            /* Should not be able to get here - we wont have a sink until a connection has been established */
            A2DP_DEBUG(("Invalid state for A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ\n"));
            break;
        case avdtp_connection_connected:
            if ( a2dpStreamClose(device) )
            {   /* Client is pulling the signalling channel while we have a Media channel established - close gracefully */
                signalling->status.connection_state = avdtp_connection_disconnect_pending;
            }
            else if (signalling->status.stream_state != avdtp_stream_idle)
            {   /* Client is pulling the signalling channel while setting up a Media channel - we have no option but to abort */
                a2dpStreamAbort(device);
                signalling->status.connection_state = avdtp_connection_disconnect_pending;
            }
            else
            {   /* No media streams to close, so continue with signalling channel close */
                signalling->status.connection_state = avdtp_connection_disconnecting;
                ConnectionL2capDisconnectRequest(&a2dp->task, signalling->connection.active.sink);
            }
            break;
        case avdtp_connection_disconnecting:
        case avdtp_connection_disconnect_pending:
            /* Already in the process of disconnecting */
            break;
        }
    }
}


/****************************************************************************/
void a2dpMediaDisconnectReq(Sink sink)
{
    /* We should already know about the device sending us a message */
    remote_device *device = findDeviceFromSink(sink);
    
    PRINT(("a2dpMediaDisconnectReq device=%X sink=%X", (uint16)device, (uint16)sink));  
      
    if ( device )
    {
        media_channel *media = NULL;
        
        if ( (media=findMediaFromSink(device, sink))!=NULL )
        {   /* Request to disconnect a media channel */
            PRINT((" media state=%u\n",media->status.connection_state));
            
            switch (media->status.connection_state)
            {
            case avdtp_connection_idle:
                /* Already disconnected */
                break;
            case avdtp_connection_paging:
            case avdtp_connection_paged:
            case avdtp_connection_crossover:
                /* Should not be able to get here - we wont have a sink until a connection has been established */
                PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpL2capMediaDisconnectReq %u\n",media->status.connection_state));
                break;
            case avdtp_connection_connected:
                media->status.connection_state = avdtp_connection_disconnecting;
                ConnectionL2capDisconnectRequest(&a2dp->task, sink);
                break;
            case avdtp_connection_disconnecting:
            case avdtp_connection_disconnect_pending:
                /* Already in the process of disconnecting */
                break;
            }
        }
    }
}


/*****************************************************************************/
void a2dpHandleL2capConnectReq(const A2DP_INTERNAL_L2CAP_CONNECT_REQ_T *req)
{
    l2capConnectRequest(CONNECT_DELAY_IMMEDIATE, req->device, req->conftab_size, (uint16 *)req->conftab);
}


/*****************************************************************************/
void a2dpHandleL2capConnectInd(const CL_L2CAP_CONNECT_IND_T *ind)
{
    PRINT(("a2dpHandleL2capConnectInd"));    
    
    if(ind->psm == AVDTP_PSM)
    {
        remote_device *device = findDeviceFromBdaddr(&ind->bd_addr);
        
        if (device != NULL)
        {   /* We are connecting/have connected to this device */
            signalling_channel *signalling = &device->signal_conn;
            media_channel *media = NULL;
            
            PRINT((" signalling state=%u\n",signalling->status.connection_state));    
            
            switch ( signalling->status.connection_state )
            {
            case avdtp_connection_idle:
                /* Will be in this state if a link loss has occurred and remote device is paging us to re-establish connection */
                initiateSignalling(device, ind->connection_id, ind->identifier);
                
                /* No need to ask app for permission, since we are trying to re-establish a lost link */
                ConnectionL2capConnectResponse(&a2dp->task, TRUE, AVDTP_PSM, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                break;
                
            case avdtp_connection_paging:
                /* Already connecting, so this looks like a cross-over case */
                initiateSignalling(device, ind->connection_id, ind->identifier);
                
                if ( device->linkloss )
                {   /* No need to ask app for permission, since we are trying to re-establish a lost link */
                    ConnectionL2capConnectResponse(&a2dp->task, TRUE, AVDTP_PSM, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                }
                else
                {   /* This must be a signalling channel, so the app must decide if to accept this connection */
                    a2dpSignallingConnectInd(device);
                }
                break;
                
            case avdtp_connection_paged:
            case avdtp_connection_crossover:
                /* Already processing an incoming connection request, reject this one */
                ConnectionL2capConnectResponse(&a2dp->task, FALSE, ind->psm, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                break;

            case avdtp_connection_connected:
                /* Must be a media channel.  Always accept these immediately unless the maximum supported media channels has been reached */
                if ( (signalling->status.stream_state==avdtp_stream_remote_opening) && (media=initiateMedia(device, ind->connection_id, ind->identifier))!=NULL )
                {   /* Able to accept a media connection */
                    ConnectionL2capConnectResponse(&a2dp->task, TRUE, ind->psm, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                }
                else
                {   /* In wrong state or unable to accept any more media connections */
                    ConnectionL2capConnectResponse(&a2dp->task, FALSE, ind->psm, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                }
                break;
                
            case avdtp_connection_disconnecting:
            case avdtp_connection_disconnect_pending:
                /* Currently disconnecting, reject this one */
                ConnectionL2capConnectResponse(&a2dp->task, FALSE, ind->psm, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                break;
            }
        }
        else
        {   /* Incoming request from a new device */
            if ( (device=addDevice(&ind->bd_addr))!=NULL )
            {   /* Able to support this new connection */
                initiateSignalling(device, ind->connection_id, ind->identifier);
                
                /* This must be the signalling channel, so let the app decide whether to accept this connection */
                a2dpSignallingConnectInd(device);
            }
            else
            {   /* Unable to support this connection - already connected to the maximum number of supported devices */
                ConnectionL2capConnectResponse(&a2dp->task, FALSE, ind->psm, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
            }
        }
    }
    else
    {   /* Incorrect PSM */
        ConnectionL2capConnectResponse(&a2dp->task, FALSE, ind->psm, ind->connection_id, ind->identifier, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
    }
}


/*****************************************************************************/
/* CL_L2CAP_CONNECT_CFM messages received when an L2CAP connection completes or when link parameters are re-negotiated */
void a2dpHandleL2capConnectCfm(const CL_L2CAP_CONNECT_CFM_T *cfm)
{
    /* We should already know about the device sending us a message */
    remote_device *device = findDeviceFromBdaddr(&cfm->addr);
    
    PRINT(("a2dpHandleL2capConnectCfm for device=%X cid=%u status=%u",(uint16)device, cfm->connection_id, cfm->status));
    
    if (device != NULL)
    {
        signalling_channel *signalling = &device->signal_conn;
        media_channel *media = NULL;
    
        PRINT((" signalling state=%u\n",signalling->status.connection_state));
        
        switch (signalling->status.connection_state)
        {
        case avdtp_connection_idle:
            /* Should not be able to get here */ 
            PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpHandleL2capConnectCfm %u\n",signalling->status.connection_state));
            if (cfm->sink)
            {   /* Closing the L2CAP channel when idle is likely to be the best course of action */
                ConnectionL2capDisconnectRequest(&a2dp->task, cfm->sink);
            }
            break;
            
        case avdtp_connection_crossover:
            if ((cfm->status == l2cap_connect_success) && (cfm->connection_id == signalling->connection.setup.outbound_cid))
            {   /* Successful connection of outbound request */
                if (signalling->connection.setup.inbound_cid && signalling->connection.setup.inbound_id)
                {   /* Non-zero cid and id indicate that a response is outstanding, reject the inbound connection */
                    ConnectionL2capConnectResponse(&a2dp->task, FALSE, AVDTP_PSM, signalling->connection.setup.inbound_cid, signalling->connection.setup.inbound_id, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                }
            }
            /* Fall through to avdtp_connection_paging case */
            
        case avdtp_connection_paging:
        case avdtp_connection_paged:
            if (cfm->status == l2cap_connect_success)
            {
                completeSignalling(signalling, cfm->connection_id, cfm->sink, cfm->mtu_remote);
                stopLinklossTimer(device);
                MessageCancelAll(&a2dp->task, A2DP_INTERNAL_L2CAP_CONNECT_REQ);

                if (device->profile_version != avdtp_version_not_requested)
                {   /* Issue cfm message and start processing AVDTP commands, as SDP search has already completed */
                    a2dpSignallingConnectCfm(device, a2dp_success);
                
                    /* Check for data in the buffer */
                    a2dpHandleSignalPacket( device );
                }
            }
            else if (cfm->status == l2cap_connect_pending)
            {
                if (signalling->connection.setup.inbound_cid != cfm->connection_id)
                {
                    signalling->connection.setup.outbound_cid = cfm->connection_id;
                }
            }
            else
            {
                if (signalling->status.connection_state == avdtp_connection_crossover)
                {   /* Crossover conection setup being managed, revert to the appropriate singular connection setup state */
                    if (signalling->connection.setup.inbound_cid == cfm->connection_id)
                    {   /* The incoming connection setup failed */
                        signalling->connection.setup.inbound_cid = 0;
                        signalling->connection.setup.inbound_id = 0;
                        signalling->status.connection_state = avdtp_connection_paging;
                    }
                    else
                    {   /* The outgoing connection setup failed */
                        signalling->connection.setup.outbound_cid = 0;
                        signalling->status.connection_state = avdtp_connection_paged;
                    }
                    
                    if (cfm->status == l2cap_connect_failed_security)
                    {
                        a2dpSignallingConnectCfm(device, a2dp_security_reject);
                    }
                    else
                    {
                        a2dpSignallingConnectCfm(device, a2dp_operation_fail);
                    }
                }
                else
                {   /* A singular connection setup being managed */
                    if ( device->linkloss )
                    {   /* Trying to re-establish a signalling channel after a link loss */
                        if ( device->manage_linkloss && !device->linkloss_timer_expired )
                        {   /* Make another connection attempt */
                            signalling->status.connection_state = avdtp_connection_idle;
                            initiateSignalling( device, AVDTP_OUTGOING_CONNECTION_ID, 0 );
                            l2capConnectRequest(CONNECT_DELAY_RANDOM, device, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                        }
                        else
                        {   /* Timer has expired, inform app of disconnect due to linkloss */
                            a2dpSignallingDisconnectInd(device, a2dp_disconnect_link_loss);
                            removeDevice( device );     /* Will remove signalling data too */
                        }
                    }
                    else
                    {   /* Tidy up and inform app of failure */
                        if (cfm->status == l2cap_connect_failed_security)
                        {
                            a2dpSignallingConnectCfm(device, a2dp_security_reject);
                        }
                        else
                        {
                            a2dpSignallingConnectCfm(device, a2dp_operation_fail);
                        }
                        removeDevice( device );     /* Will remove signalling data too */
                    }
                }
            }
            break;
            
        case avdtp_connection_connected:
        case avdtp_connection_disconnect_pending:   /* Will occur if an Abort has been raised as the media L2CAP channel is established */
        case avdtp_connection_disconnecting:        /* Could get here if an L2CAP renegoitation occurred just before disconnect req */
            if (cfm->connection_id == SinkGetL2capCid(signalling->connection.active.sink))
            {   /* Signalling channel L2CAP parameter negotiation has occurred, update stored values */
                completeSignalling(signalling, cfm->connection_id, cfm->sink, cfm->mtu_remote);
            }
            else if ( (media = findMediaFromConnectionId(device, cfm->connection_id)) != NULL)
            {
                PRINT((" media state=%u",media->status.connection_state));
                
                switch (media->status.connection_state)
                {
                case avdtp_connection_idle:
                case avdtp_connection_crossover:        /* A media channel can never be in this state */
                    /* Should not be able to get here */
                    PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpHandleL2capConnectCfm %u\n",media->status.connection_state));
                    if (cfm->sink)
                    {   /* Closing the L2CAP channel when idle is likely to be the best course of action */
                        ConnectionL2capDisconnectRequest(&a2dp->task, cfm->sink);
                    }
                    break;
                    
                case avdtp_connection_paging:
                case avdtp_connection_paged:
                    if (cfm->status == l2cap_connect_success)
                    {
                        completeMedia(media, cfm->connection_id, cfm->sink, cfm->mtu_remote);
                        StreamConnectDispose(StreamSourceFromSink(cfm->sink));
        
                        if (signalling->status.stream_state != avdtp_stream_local_aborting)
                        {   /* Only update Stream state and inform app if we are not in the process of aborting */
                            a2dpSetStreamState(device, avdtp_stream_open);
                            a2dpMediaOpenCfm(device, media, a2dp_success);
                        }
                        else
                        {   /* Let app know we are aborting */
                            a2dpMediaOpenCfm(device, media, a2dp_aborted);
                        }
                        
                        /* Check for data in the buffer - more than likely a deferred command */
                        a2dpHandleSignalPacket( device );
                    }
                    else if (cfm->status == l2cap_connect_pending)
                    {
                        if (media->connection.setup.inbound_cid != cfm->connection_id)
                        {
                            media->connection.setup.outbound_cid = cfm->connection_id;
                        }
                    }
                    else
                    {
                        a2dpMediaOpenCfm(device, media, a2dp_operation_fail);
                        removeMedia( media );
                        
                        /* Request for a media channel failed, so abort to return to idle state */
                        a2dpStreamAbort(device);
                    }
                    break;
                    
                case avdtp_connection_connected:        /* would get here if an L2CAP renegoitation occurred */
                case avdtp_connection_disconnecting:    /* Possibly could get here if an L2CAP renegoitation occurred just before disconnect req */
                    completeMedia(media, cfm->connection_id, cfm->sink, cfm->mtu_remote);
                    break;
                    
                case avdtp_connection_disconnect_pending:
                    if (cfm->status == l2cap_connect_success)
                    {
                        completeMedia(media, cfm->connection_id, cfm->sink, cfm->mtu_remote);
                        StreamConnectDispose(StreamSourceFromSink(cfm->sink));
                        media->status.connection_state = avdtp_connection_disconnecting;
                        ConnectionL2capDisconnectRequest(&a2dp->task, media->connection.active.sink);
                    }
                    else if (cfm->status == l2cap_connect_pending)
                    {   /* Wait for connection to actually complete before tearing it down */
                        if (media->connection.setup.inbound_cid != cfm->connection_id)
                        {
                            media->connection.setup.outbound_cid = cfm->connection_id;
                        }
                    }
                    else
                    {   /* Connection failed */
                        a2dpMediaOpenCfm(device, media, a2dp_operation_fail);
                        removeMedia( media );
                        a2dpSignallingDisconnectPending(device);
                    }
                    break;
                }
            }
            else
            {   /* Received a confirmation message with an unrecognised connection id - should be due to a signalling crossover condition */
                PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpHandleL2capConnectCfm unrecognised cid 0x%X\n",cfm->connection_id));
                if (cfm->sink)
                {   /* Closing the unrecognised L2CAP channel is likely to be the best course of action */
                    ConnectionL2capDisconnectRequest(&a2dp->task, cfm->sink);
                }
            }
            break;
        }
    }
}


/****************************************************************************/
void a2dpHandleL2capDisconnect(uint16 cid, Sink sink, l2cap_disconnect_status status)
{
    remote_device *device = findDeviceFromSink(sink);
    
    PRINT(("a2dpHandleL2capDisconnect device=%X cid=%x sink=%X status=%u", (uint16)device, (uint16)cid, (uint16)sink, status));    
        
    if (device != NULL)
    {   /* Device is recognised by A2DP lib */
        signalling_channel *signalling = NULL;
        media_channel *media = NULL;
        
        if (((signalling = &device->signal_conn) != NULL) && (signalling->connection.active.sink == sink))
        {   /* A signalling channel disconnected */
            PRINT((" signalling state=%u\n",signalling->status.connection_state));    
            
            switch (signalling->status.connection_state)
            {
            case avdtp_connection_idle:
                /* Already disconnected, ignore message */
                break;
            case avdtp_connection_paging:
            case avdtp_connection_paged:
            case avdtp_connection_crossover:
                /* Should not be able to get here - we wont have a sink until a connection has been established */
                PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpHandleL2capDisconnect signalling %u\n",signalling->status.connection_state));
                break;
            case avdtp_connection_connected:
            case avdtp_connection_disconnect_pending:
            case avdtp_connection_disconnecting:
                if ((status == l2cap_disconnect_link_loss) && device->manage_linkloss && a2dp->linkloss_timeout)
                {   /* Start managing linkloss situation */
                    signalling->status.connection_state = avdtp_connection_idle;
                    startLinklossTimer(device);
                    
                    /* Postpone signalling channel re-establishment if there are any media channels marked as connected */
                    if ( !isMediaConnected( device ) )
                    {   /* No media channels, ok to attempt to re-establish signalling connection */
                        /* Inform app of link loss */
                        a2dpSignallingLinklossInd(device);
                        
                        initiateSignalling( device, AVDTP_OUTGOING_CONNECTION_ID, 0 );
                        l2capConnectRequest(CONNECT_DELAY_RANDOM, device, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                    }
                }
                else
                {   /* Signalling channel has gone, remove any remaining media channels */
                    if ( a2dpDisconnectAllMedia( device ) )
                    {   /* Media channels being disconnected.  Mark signalling as disconnected but postpone removal of data structure and app indication */
                        signalling->status.connection_state = avdtp_connection_idle;
                    }
                    else
                    {   /* No media channels are connected, so remove device from list */
                        a2dpSignallingDisconnectInd(device, convertDisconnectStatusCode(status));
                        a2dpStreamReset(device);
                        removeDevice( device ); /* Will remove signalling and media channel data too */
                    }
                }
                break;
            }
        }
        else if ( (media=findMediaFromSink(device, sink))!=NULL )
        {   /* A media channel disconnected */
            PRINT((" media state=%u\n",media->status.connection_state));    
            
            switch (media->status.connection_state)
            {
            case avdtp_connection_idle:
                /* Already disconnected, ignore message */
                break;
            case avdtp_connection_paging:
            case avdtp_connection_paged:
            case avdtp_connection_crossover:
                /* Should not be able to get here - we wont have a sink until a connection has been established */
                PRINT(("UNEXPECTED A2DP LIBRARY STATE: a2dpHandleL2capDisconnect media %u\n",media->status.connection_state));
                break;
            case avdtp_connection_connected:
            case avdtp_connection_disconnect_pending:
            case avdtp_connection_disconnecting:
                a2dpMediaCloseInd(device, media, convertDisconnectStatusCode(status));
                removeMedia( media );
                if ( !isMediaConnected( device ) )
                {
                    a2dpStreamReset(device);
                    
                    if ( !a2dpSignallingDisconnectPending(device) )
                    {   /* There is no signalling channel disconnect pending */
                        if ( !isSignallingConnected( device ) )
                        {   /* No signalling channel, so send indication to client now */
                            a2dpSignallingDisconnectInd(device, convertDisconnectStatusCode(status));
                            removeDevice( device );     /* Removes signalling channel data too */
                        }
                        else if ( device->linkloss )
                        {   /* Signalling channel linkloss notification received before media channel(s) */
                            /* Inform app of link loss */
                            a2dpSignallingLinklossInd(device);
                            
                            if (signalling->status.connection_state == avdtp_connection_idle)
                            {   /* Remote deive has not started reconnection, so initiate signalling channel connection now */
                                initiateSignalling( device, AVDTP_OUTGOING_CONNECTION_ID, 0 );
                                l2capConnectRequest(CONNECT_DELAY_RANDOM, device, sizeof(a2dp_conftab), (uint16*)a2dp_conftab);
                            }
                        }
                    }
                }
                break;
            }
        }
    }
}

