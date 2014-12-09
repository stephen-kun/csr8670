/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#include "gaia.h"
#include "gaia_private.h"

#ifdef GAIA_TRANSPORT_MFI
#include "gaia_transport.h"
#include "gaia_transport_mfi.h"
#include "gaia_transport_common.h"

#include <connection.h>
#include <iap.h>
#include <message.h>
#include <panic.h>
#include <memory.h>

#define DATA_SESSION_RECEIVE_MTU    128
static const uint8 accessory_caps[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, IAP_GL_ACC_CAPS_BYTE2_COMMS_WITH_APPS, 0x00};

/****************************************************************
 * Internal utility functions
 ****************************************************************/

/*! @brief Utility function to search the gaia transports looking for a transport matching an iap_link.
 *
 *  @param link iap_link to use for matching a gaia transport.
 *
 *  @return gaia_transport* Pointer to a gaia_transport, or NULL on failure.
 */
static gaia_transport* gaiaTransportMfiFindIapTransport(iap_link *link)
{
    uint16 i = 0;

    for (i=0; i<gaia->transport_count; i++)
    {
        if ((gaia->transport[i].type == gaia_transport_mfi) && (gaia->transport[i].state.mfi.link == link))
            return &gaia->transport[i];
    }

    /* no matching MFi transports, return NULL to indicate failure */
    return NULL;
}

/*! @brief Clean up state associated with being connected for future connections.
 */
static void gaiaTransportMfiCleanupConnectionState(gaia_transport* transport)
{
    /* reset state of data session */
    transport->state.mfi.data_session_was_open = 0;

    /* reset connection direction, so we're happy for local or remote re-connection */
    transport->state.mfi.remote_connection = 0;

    /* obviously clear the flag that says we're connected */
    transport->connected = 0;
}

/****************************************************************
 * Functions that handle messages from the iap library
 ****************************************************************/

/*! @brief Handle initialisation confirmation from iap library.
 */
static void gaiaTransportMfiHandleIapInitConfirmation(IAP_INIT_CFM_T *cfm)
{
    if (cfm->status == iap_success)
    {
        /* library initialised, IapInit() was called in response to a GaiaStartService() so automatically try and create
         * an iap link */
        IapLinkInitRequest(iap_transport_bt);
    }
    else
    {
        gaiaTransportCommonSendGaiaStartServiceCfm(gaia_transport_mfi, NULL, FALSE);
    }
}

/*! @brief Handle confirmation of attempt to initialise a iap link.
 */
static void gaiaTransportMfiHandleIapLinkInitConfirmation(IAP_LINK_INIT_CFM_T *cfm)
{
    bool status = FALSE;
    gaia_transport *transport = NULL;

    if (cfm->status == iap_success)
    {
        /* successfully initialised an iap link, look for a free gaia transport and store the iap_link reference */
        transport = gaiaTransportFindFree();

        if (transport)
        {
            transport->type = gaia_transport_mfi;
            transport->state.mfi.link = cfm->link;
            status = TRUE;
        }
    }
    
    /* send VM application a GAIA_START_SERVICE_CFM message with outcome of the requested GaiaStartService operation */
    gaiaTransportCommonSendGaiaStartServiceCfm(gaia_transport_mfi, transport, status);
}

/*! @brief Handle indication of incoming MFi connection.
 */
static void gaiaTransportMfiHandleIapConnectIndication(IAP_CONNECT_IND_T *ind)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(ind->link);
    if (transport != NULL)
    {
        /* accept the connection, should get a IAP_CONNECT_CFM to complete the transaction */
        IapConnectResponse(ind->link, TRUE, ind->server_channel);

        /* flag this is a remote connection so we know how we need to inform the client task of events */
        transport->state.mfi.remote_connection = 1;
    }
}

/*! @brief Handle confirmation of MFi connection.
 */
static void gaiaTransportMfiHandleIapConnectConfirmation(IAP_CONNECT_CFM_T *cfm)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(cfm->link);
    if (transport != NULL)
    {
        if (cfm->status == iap_success)
        {
            /* update local state for this MFi transport */
            transport->state.mfi.link = cfm->link;
        }
        else
        {
            /* if the connect failed, and this was a locally originated connection
             * we need to send a GAIA_CONNECT_CFM failure message to the app */
            if (!transport->state.mfi.remote_connection)
            {
                gaiaTransportCommonSendGaiaConnectCfm(transport, FALSE);
            }
        }
    }
    else
    {
        GAIA_TRANS_DEBUG(("Failed to find matching MFi transport for IAP_CONNECT_CFM\n"));
        Panic();
    }
}

/*! @brief Handle indication of MFi disconnection.
 */
static void gaiaTransportMfiHandleIapDisconnectIndication(IAP_DISCONNECT_IND_T *ind)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(ind->link);
    if (transport != NULL)
    {
        /* if Gaia connected was fully open, tell the client task that we got disconnected */
        if (transport->connected)
        {
            gaiaTransportCommonSendGaiaDisconnectInd(transport);
        }
        
        /* clean up after ourselves, so that we work correctly next time */
        gaiaTransportMfiCleanupConnectionState(transport);
    }
    else
    {
        GAIA_TRANS_DEBUG(("Failed to find matching MFi transport for IAP_DISCONNECT_IND\n"));
        Panic();
    }
}

/*! @brief Handle confirmation that a requested disconnection has completed.
 */
static void gaiaTransportMfiHandleIapDisconnectConfirmation(IAP_DISCONNECT_CFM_T *cfm)
{
    gaia_transport *transport = NULL;
   
    transport = gaiaTransportMfiFindIapTransport(cfm->link);
    if (transport != NULL)
    {
        /* clean up after ourselves, so that we work correctly next time */
        gaiaTransportMfiCleanupConnectionState(transport);

        if (transport->state.mfi.client_discon_req)
        {
            gaiaTransportCommonSendGaiaDisconnectCfm(transport);

            /* reset the client_discon_req flag for future use */
            transport->state.mfi.client_discon_req = 0;
        }
        else
        {
            /* this was a disconnect request by this library due to failure during connection
             * IapGetiPodOptionsForLingo(), send a GAIA_CONNECT_CFM if this was a locally originated
             * connected, silently ignore if this is a failed remote connection */
            if (!transport->state.mfi.remote_connection)
            {
                gaiaTransportCommonSendGaiaConnectCfm(transport, FALSE);
            }
        }
    }
    else
    {
        GAIA_TRANS_DEBUG(("Failed to find matching MFi transport for IAP_DISCONNECT_CFM\n"));
        Panic();
    }
}

/*! @brief Handle indication of MFi transport authentication status.
 */
static void gaiaTransportMfiHandleIapAuthenticationIndication(IAP_AUTHENTICATION_IND_T *ind)
{
    gaia_transport *transport = NULL;

    transport = gaiaTransportMfiFindIapTransport(ind->link);
    if (transport != NULL)
    {
        switch (ind->status)
        {
            case iap_success:
                /* nothing to do, we're not 'gaia open' until the link is usable, i.e we get an
                 * IAP_DATA_SESSION_STATUS_IND with a status of iap_data_session_open */
                break;
            case iap_auth_fail:
                /* inform app GAIA connection attempt has failed */
                /* fall-thru */
            case iap_idps_fail_device_not_supported:
            {
                /* if this was a locally originated connection, inform the client task */
                if (!transport->state.mfi.remote_connection)
                {
                    gaiaTransportCommonSendGaiaConnectCfm(transport, FALSE);
                }
                break;
            }
            case iap_auth_revoked:
                /* ignore - only needed if using iap over a UART */
                break;
            case iap_auth_in_progress:
                /* ignore - no corresponding need to inform client task of pending Gaia connection */
                break;
            default:
                GAIA_TRANS_DEBUG(("Unknown status in IAP_AUTHENTICATION_IND %x\n", ind->status));
                break;
        }
    }
    else
    {
        GAIA_TRANS_DEBUG(("Failed to matching transport for IAP_AUTHENTICATION_IND\n"));
        Panic();
    }
}

/*! @brief Handle indication that the iap library requires our accessory info.
 */
static void gaiaTransportMfiHandleIapAccessoryInfoIndication(IAP_ACCESSORY_INFO_IND_T *ind)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(ind->link);
    if (transport != NULL)
    {
        /* send a request for the iap general lingo options */
        IapGetiPodOptionsForLingo(ind->link, IAP_LINGO_GENERAL);
    }
    else
    {
        GAIA_TRANS_DEBUG(("Failed to matching transport for IAP_ACCESSORY_INFO_IND\n"));
        Panic();
    }
}

/*! @brief Handle indication of results from an IapGetiPodOptionsForLingo call to the iap library.
 */
static void gaiaTransportMfiHandleIapIpodOptionsForLingoCfm(IAP_IPOD_OPTIONS_FOR_LINGO_CFM_T *cfm)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(cfm->link);
    if (transport != NULL)
    {
        if ((cfm->status == iap_success) && (cfm->options_lsb & IAP_GL_OPTION_COMMS_WITH_APPS))
        {
            IapAccessoryInfoResponse(cfm->link, &transport->state.mfi.config);
        }
        else
        {
            /* failed to get options for general lingo, disconnect this transport */
            IapDisconnectRequest(cfm->link);
        }
    }
}

/*! @brief Handle indication of change in iOS device sleep/hibernate state.
 */
static void gaiaTransportMfiHandleIapIpodStateChangeInd(IAP_IPOD_STATE_CHANGE_IND_T *ind)
{
    /* Nothing to do, we don't receive these messages when using iAP over a Bluetooth transport. */
}

/*! @brief Handle indication of change in state of data session with iOS device.
 */
static void gaiaTransportMfiHandleIapDataSessionStatusInd(IAP_DATA_SESSION_STATUS_IND_T *ind)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(ind->link);
    if (transport != NULL)
    {
        switch (ind->status)
        {
            case iap_data_session_open:
            {
                transport->state.mfi.data_session_id = ind->session_id;
                transport->connected = 1;
                    
                /* data session opened by iOS app, finally able to send a GAIA_CONNECT_XXX to the client app */
                if (transport->state.mfi.data_session_was_open)
                {
                    transport->state.mfi.data_session_was_open = 0;

                    /* we had an open data session - since closed by iOS - but without losing our bluetooth connection
                     * or authenticated status with the iOS device.
                     *
                     * iOS has then re-opened the data session, from the Gaia perspective this is a new
                     * remotely initiated connection, so send a GAIA_CONNECT_IND */
                    gaiaTransportCommonSendGaiaConnectInd(transport, TRUE);
                }
                else
                {
                    /* if this is a remotely initiated connection, send a GAIA_CONNECT_IND,
                     * else this was locally initiated so send a GAIA_CONNECT_CFM */
                    if (transport->state.mfi.remote_connection)
                    {
                        gaiaTransportCommonSendGaiaConnectInd(transport, TRUE);
                    }
                    else
                    {
                        gaiaTransportCommonSendGaiaConnectCfm(transport, TRUE);
                    }
                }
                break;
            }
            case iap_data_session_closed:
            {
                /* data session closed, need to tell the client app that its connection is 'closed'
                 * we are still connected and authenticated with the iOS device, but from the Gaia
                 * perspective the connection is unusable, therefore disconnected */
                transport->state.mfi.data_session_id = 0;
                transport->state.mfi.data_session_was_open = 1;
                transport->connected = 0;
                gaiaTransportCommonCleanupThresholdState(transport);
                gaiaTransportCommonSendGaiaDisconnectInd(transport);
                break;
            }
        }
    }
}

/*! @brief Handle indication of received data from iOS device.
 */
static void gaiaTransportMfiHandleIapDataSessionReceiveDataInd(IAP_DATA_SESSION_RECEIVE_DATA_IND_T *ind)
{
    uint16 idx = 0;
    uint8 *gaia_packet_start = NULL;
    uint16 packet_length = 0;
    uint16 expected = GAIA_OFFS_PAYLOAD;
    uint8 flags = 0;
    uint8 check = 0;
    gaia_transport *transport = NULL;

    GAIA_TRANS_DEBUG(("SID:%x PID:%x SIZE:%d\n", ind->session_id, ind->pkt_id, ind->size_data));

    /* ensure we have a valid Gaia packet to pass up for processing
     *  - find the start of frame if (although should be first byte)
     *  - at least a valid header size
     *  - checksum (if required) 
     *  - validate that there are at least 'length' bytes in the packet
     */

    /* if we have at least enough data for a valid Gaia packet header */
    if (ind->size_data >= GAIA_OFFS_PAYLOAD)
    {
        while (idx < ind->size_data)
        {
            if (packet_length > 0)
            {
                /* get the flags if we're at that position in the header */
                if (packet_length == GAIA_OFFS_FLAGS)
                    flags = ind->data[idx];
                else if (packet_length == GAIA_OFFS_PAYLOAD_LENGTH)
                {
                    /* work out total expected packet length if we're at that position in the header */
                    expected = GAIA_OFFS_PAYLOAD + ind->data[idx] + ((flags & GAIA_PROTOCOL_FLAG_CHECK) ? 1 : 0);
                }
                /* update checksum with value at current position in the packat and increase packet length */
                check ^= ind->data[idx];
                packet_length++;

            }
            else if (ind->data[idx] == GAIA_SOF)
            {
                /* we've found the start of a frame, initialise packet length to 1
                 * and start the checksum with the GAIA_SOF value */
                gaia_packet_start = &ind->data[idx];
                packet_length = 1;
                check = GAIA_SOF;
            }
            /* move to next byte in the available data */
            idx++;
        }

        if (packet_length == expected)
        {
            if (((flags & GAIA_PROTOCOL_FLAG_CHECK) == 0) || (check == 0))
            {
                transport = gaiaTransportMfiFindIapTransport(ind->link);
                if (transport != NULL)
                {
                    process_packet(transport, gaia_packet_start);
                }
            }
            else
                GAIA_TRANS_DEBUG(("bad checksum\n"));
        }
    }

    /* let MFi know we've received and handled the packet, it can send more */
    IapDataSessionReceiveDataResponse(ind->link, ind->pkt_id);
}

/*! @brief Handle confirmation of data transmission request to iOS device.
 */
static void gaiaTransportMfiHandleIapDataSessionTransmitDataCfm(IAP_DATA_SESSION_TRANSMIT_DATA_CFM_T *cfm)
{
    gaia_transport *transport = NULL;
    
    transport = gaiaTransportMfiFindIapTransport(cfm->link);
    if (transport != NULL)
    {
        if (transport->state.mfi.transmit_cfm_to_client)
        {
            /* this was a packet from the client task, inform it of the result of the 
             * attempted transmission */
            gaiaTransportCommonSendGaiaSendPacketCfm(transport, transport->state.mfi.client_data_ptr,
                                                     cfm->status == iap_data_session_ack_success ? TRUE : FALSE);

            /* clean up for next time */
            transport->state.mfi.client_data_ptr = NULL;
            transport->state.mfi.transmit_cfm_to_client = 0;
        }
        else
        {
            /* this was a packet we sent, free the data ourselves and clean up for next time */
            free(transport->state.mfi.client_data_ptr);
            transport->state.mfi.client_data_ptr = NULL;
        }
    }
}

/****************************************************************
 * Functions that implement the gaia_transport.h interface
 ****************************************************************/

/*! @brief Initialise MFi transport.
 */
void gaiaTransportMfiInit(gaia_transport *transport)
{
#ifdef DEBUG_GAIA
    if (transport == NULL)
        Panic();
#endif

    /* initialise our transport state */
    memset(transport, 0, sizeof (gaia_transport));
    transport->type = gaia_transport_mfi;
}


/*! @brief Initialise IAP library.
 */
void gaiaTransportMfiStartService(void)
{
    if (!gaia->iap_lib_init)
    {
        /* initialise the IAP library, and request a new bluetooth iap_link on success */
        IapInit(&gaia->task_data);
    }
    else
    {
        /* IAP library already initialised, just request a new bluetooth iap_link */
        IapLinkInitRequest(iap_transport_bt);
    }
}


/*! @brief Handle a request from client task to create a Gaia connection.
 */
void gaiaTransportMfiConnectReq(gaia_transport *transport, bdaddr *address)
{
#ifdef DEBUG_GAIA
    if (transport == NULL)
        Panic();
#endif

    /* if the transport has been configured permit the connection request */
    if (transport->state.mfi.transport_configured)
    {
        /* record this is a locally originated connection request */
        transport->state.mfi.remote_connection = 0;

        /* ask iap library to connect us */
        IapConnectBtRequest(transport->state.mfi.link, address);
    }
    else
    {
        /* not configured, return fail to the client task */
        gaiaTransportCommonSendGaiaConnectCfm(transport, FALSE);
    }
}

/*! @brief Handle client task response to an incoming connection indication.
 */
void gaiaTransportMfiConnectRes(gaia_transport *transport)
{
    /* TODO really nothing to do here? */
}

/*! @brief Handle client task request to disconnect an MFi transport.
 */
void gaiaTransportMfiDisconnectReq(gaia_transport *transport)
{
#ifdef DEBUG_GAIA
    if (transport == NULL)
        Panic();
#endif

    transport->state.mfi.client_discon_req = 1;
    IapDisconnectRequest(transport->state.mfi.link);
}

/*! @brief Handle client task response to an incoming disconnection indication.
 */
void gaiaTransportMfiDisconnectRes(gaia_transport *transport)
{
    /* TODO really nothing to do here? */
}

/*! @brief Handle client task data transmission request.
 */
void gaiaTransportMfiSendPacket(Task task, gaia_transport *transport, uint16 length, uint8 *data)
{
#ifdef DEBUG_GAIA
    if (transport == NULL)
        Panic();
#endif

    /* pass data on to iap for transmission */
    IapDataSessionTransmitDataRequest(transport->state.mfi.link,
                                      (const uint8*)data, length,
                                      transport->state.mfi.data_session_id);

    /* set flag if we'll need to send a GAIA_SEND_PACKET_CFM message to the client task
     * once iap sends us a IAP_DATA_SESSION_TRANSMIT_DATA_CFM */
    if (task)
    {
        transport->state.mfi.transmit_cfm_to_client = 1;
    }

    /* save the pointer to the data, either for sending back to the client task once we get
     * a IAP_DATA_SESSION_TRANSMIT_DATA_CFM or for freeing ourselves */
    transport->state.mfi.client_data_ptr = data;
}

/*! @brief Return the sink being used by our underlying MFi transport.
 */
Sink gaiaTransportMfiGetSink(gaia_transport *transport)
{
#ifdef DEBUG_GAIA
    if (transport == NULL)
        Panic();
#endif

    return IapGetLinkSink(transport->state.mfi.link);
}

/*! @brief MFi transport message handler.
 */
bool gaiaTransportMfiHandleMessage(Task task, MessageId id, Message message)
{
    bool msg_handled = TRUE;

    switch (id)
    {
        case IAP_INIT_CFM:
            gaiaTransportMfiHandleIapInitConfirmation((IAP_INIT_CFM_T *)message);
            break;

        case IAP_LINK_INIT_CFM:
            gaiaTransportMfiHandleIapLinkInitConfirmation((IAP_LINK_INIT_CFM_T *)message);
            break;

        case IAP_CONNECT_IND:
            gaiaTransportMfiHandleIapConnectIndication((IAP_CONNECT_IND_T *)message);
            break;

        case IAP_CONNECT_CFM:
            gaiaTransportMfiHandleIapConnectConfirmation((IAP_CONNECT_CFM_T *)message);
            break;

        case IAP_DISCONNECT_IND:
            gaiaTransportMfiHandleIapDisconnectIndication((IAP_DISCONNECT_IND_T *)message);
            break;

        case IAP_DISCONNECT_CFM:
            gaiaTransportMfiHandleIapDisconnectConfirmation((IAP_DISCONNECT_CFM_T *)message);
            break;

        case IAP_AUTHENTICATION_IND:
            gaiaTransportMfiHandleIapAuthenticationIndication((IAP_AUTHENTICATION_IND_T *)message);
            break;

        case IAP_ACCESSORY_INFO_IND:
            gaiaTransportMfiHandleIapAccessoryInfoIndication((IAP_ACCESSORY_INFO_IND_T *)message);
            break;

        case IAP_IPOD_OPTIONS_FOR_LINGO_CFM:
            gaiaTransportMfiHandleIapIpodOptionsForLingoCfm((IAP_IPOD_OPTIONS_FOR_LINGO_CFM_T *)message);
            break;

        case IAP_IPOD_STATE_CHANGE_IND:
            gaiaTransportMfiHandleIapIpodStateChangeInd((IAP_IPOD_STATE_CHANGE_IND_T *)message);
            break;

        case IAP_DATA_SESSION_STATUS_IND:
            gaiaTransportMfiHandleIapDataSessionStatusInd((IAP_DATA_SESSION_STATUS_IND_T *)message);
            break;

        case IAP_DATA_SESSION_RECEIVE_DATA_IND:
            gaiaTransportMfiHandleIapDataSessionReceiveDataInd((IAP_DATA_SESSION_RECEIVE_DATA_IND_T *)message);
            break;

        case IAP_DATA_SESSION_TRANSMIT_DATA_CFM:
            gaiaTransportMfiHandleIapDataSessionTransmitDataCfm((IAP_DATA_SESSION_TRANSMIT_DATA_CFM_T *)message);
            break;

        default:
            msg_handled = FALSE;
            break;
    }

    return msg_handled;
}

/****************************************************************
 * End of functions that implement the gaia_transport.h interface
 ****************************************************************/
/*!
    @brief Provide the configuration required to use an MFi transport.
    
    TODO this is nasty and breaks our nice clean generic core<->transport interface...fix it sunshine...

    Applications wishing to use Gaia over an MFi transport must call this function
    prior to calling GaiaBtConnectRequest(), such that the configuration can be used
    during connection establishment with iOS devices.  GaiaBtConnectRequest() will
    fail if this function has not been called first.

    @param config Pointer to a gaia_mfi_transport_config structure.
*/
void GaiaMfiTransportConfig(GAIA_TRANSPORT *transport, gaia_mfi_transport_config* config)
{
    gaia_transport *internal_transport = (gaia_transport*)transport;

    iap_accessory_config *iac = &internal_transport->state.mfi.config;
    
    iac->lingoes = IAP_GL_DEVICE_LINGOES_SPOKEN_GENERAL;
    iac->accessory_name = config->accessory_name;
    iac->manufacturer_name = config->manufacturer_name;
    iac->model_name = config->model_name;
    iac->firmware_version = config->firmware_version;
    iac->hardware_version = config->hardware_version;
    iac->protocol_string = config->protocol_string;
    iac->bundle_seed_id = config->bundle_seed_id;
    iac->receive_mtu = DATA_SESSION_RECEIVE_MTU;
    iac->accessory_caps = accessory_caps;
    iac->rf_certs = IAP_GL_ACC_RF_CERT_CLASS_2;
    iac->metadata = iap_metadata_type_default_match;
    iac->preferences = NULL;
    iac->num_preferences = 0;
    iac->serial_number = NULL;
    
    /* flag that the client task has now been configured and calls to
     * GaiaBtConnectRequest() are now permitted */
    internal_transport->state.mfi.transport_configured = 1;
}

#endif /* GAIA_TRANSPORT_MFI */
