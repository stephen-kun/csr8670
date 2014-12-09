/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#include "gaia.h"
#include "gaia_private.h"
#include "gaia_transport.h"
#include "gaia_transport_common.h"
#include <stream.h>
#include <audio.h>
#include <sink.h>


#ifdef GAIA_TRANSPORT_RFCOMM
#include "gaia_transport_rfcomm.h"
#endif

#ifdef GAIA_TRANSPORT_SPP
#include "gaia_transport_spp.h"
#endif

#ifdef GAIA_TRANSPORT_MFI
#include "gaia_transport_mfi.h"
#endif

/*! @brief Initialise a Gaia transport.
 */
void gaiaTransportInit(gaia_transport *transport)
{
    switch (transport->type)
    {
#ifdef GAIA_TRANSPORT_RFCOMM
        case gaia_transport_rfcomm:
            gaiaTransportRfcommInit(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_SPP
        case gaia_transport_spp:
            gaiaTransportSppInit(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_MFI
        case gaia_transport_mfi:
            gaiaTransportMfiInit(transport);
            break;
#endif
        default:
            GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
            GAIA_PANIC();
            break;
    }
}


/*! @brief Attempt to find a free transport slot
 */
gaia_transport *gaiaTransportFindFree(void)
{
    uint16 idx;
    
    for (idx = 0; idx < gaia->transport_count; ++idx)
    {
        if (gaia->transport[idx].type == gaia_transport_none)
            return &gaia->transport[idx];
    }
    
    return NULL;
}

#if defined GAIA_TRANSPORT_RFCOMM || defined GAIA_TRANSPORT_SPP
/*! @brief Attempt to find the tranport associated with an RFCOMM channel
 */
gaia_transport *gaiaTransportFromRfcommChannel(uint16 channel)
{
    uint16 idx;
    
    for (idx = 0; idx < gaia->transport_count; ++idx)
    {
        if (((gaia->transport[idx].type == gaia_transport_rfcomm) || (gaia->transport[idx].type == gaia_transport_spp))
            && (gaia->transport[idx].state.spp.rfcomm_channel == channel))
            return &gaia->transport[idx];
    }
    return NULL;
}
#endif /* def GAIA_TRANSPORT_SPP */

/*! @brief Attempt to find the tranport associated with a sink
 */
gaia_transport *gaiaTransportFromSink(Sink sink)
{
    uint16 idx;
    
    for (idx = 0; idx < gaia->transport_count; ++idx)
        if (gaiaTransportGetSink(&gaia->transport[idx]) == sink)
            return &gaia->transport[idx];
    
    return NULL;
}


/*! @brief Attempt to connect Gaia to a device over a given transport.
 */
void gaiaTransportConnectReq(gaia_transport *transport, bdaddr *address)
{
#if defined GAIA_TRANSPORT_SPP || defined GAIA_TRANSPORT_RFCOMM
    if (transport == NULL)
    {
        transport = gaiaTransportFindFree();
        if (transport == NULL)
        {
        /*  No spare transports; return failure to application  */
            gaiaTransportCommonSendGaiaConnectCfm(NULL, FALSE);
            return;
        }

        else
        {
            transport->type = gaia_transport_spp;
        }
    }
#endif

    switch (transport->type)
    {
#ifdef GAIA_TRANSPORT_SPP
        case gaia_transport_spp:
            gaiaTransportSppConnectReq(transport, address);
            break;
#endif
#ifdef GAIA_TRANSPORT_MFI
        case gaia_transport_mfi:
            gaiaTransportMfiConnectReq(transport, address);
            break;
#endif
        default:
            GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
            GAIA_PANIC();
            break;
    }
}

/*! @brief Respond to an incoming Gaia connection indication over a given transport.
 */
void gaiaTransportConnectRes(gaia_transport *transport)
{
    switch (transport->type)
    {
#ifdef GAIA_TRANSPORT_RFCOMM
        case gaia_transport_rfcomm:
            gaiaTransportRfcommConnectRes(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_SPP
        case gaia_transport_spp:
            gaiaTransportSppConnectRes(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_MFI
        case gaia_transport_mfi:
            gaiaTransportMfiConnectRes(transport);
            break;
#endif
        default:
            GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
            GAIA_PANIC();
            break;
    }

}

/*! @brief Attempt to disconnect Gaia over a given transport.
 */
void gaiaTransportDisconnectReq(gaia_transport *transport)
{
    switch (transport->type)
    {
#ifdef GAIA_TRANSPORT_RFCOMM
        case gaia_transport_rfcomm:
            gaiaTransportRfcommDisconnectReq(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_SPP
        case gaia_transport_spp:
            gaiaTransportSppDisconnectReq(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_MFI
        case gaia_transport_mfi:
            gaiaTransportMfiDisconnectReq(transport);
            break;
#endif
        default:
            GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
            GAIA_PANIC();
            break;
    }
}

/*! @brief Respond to a Gaia disconnection indication over a given transport.
 */
void gaiaTransportDisconnectRes(gaia_transport *transport)
{
    switch (transport->type)
    {
#ifdef GAIA_TRANSPORT_RFCOMM
        case gaia_transport_rfcomm:
            gaiaTransportRfcommDisconnectRes(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_SPP
        case gaia_transport_spp:
            gaiaTransportSppDisconnectRes(transport);
            break;
#endif
#ifdef GAIA_TRANSPORT_MFI
        case gaia_transport_mfi:
            gaiaTransportMfiDisconnectRes(transport);
            break;
#endif
        default:
            GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
            GAIA_PANIC();
            break;
    }
}

/*! @brief Clear down state of given transport.
 */
void gaiaTransportDropState(gaia_transport *transport)
{
    GAIA_TRANS_DEBUG(("gaia: drop state t=%04X %d o=%04X\n",
        (uint16) transport, transport->type, (uint16) gaia->outstanding_request));

    if (gaia->outstanding_request == transport)
        gaia->outstanding_request = NULL;

    if (gaia->pfs_state != PFS_NONE)
    {
        GAIA_TRANS_DEBUG(("gaia: drop pfs %d s=%lu r=%lu\n", 
            gaia->pfs_state, gaia->pfs_sequence, gaia->pfs_raw_size));

        gaia->pfs_sequence = 0;
        gaia->pfs_raw_size = 0;
        SinkClose(gaia->pfs.sink);
        gaia->pfs_state = PFS_NONE;
    }

    if (IsAudioBusy() == &gaia->task_data)
        SetAudioBusy(NULL);
 
    switch (transport->type)
    {
#ifdef GAIA_TRANSPORT_RFCOMM
    case gaia_transport_rfcomm:
        gaiaTransportRfcommDropState(transport);
        break;
#endif
#ifdef GAIA_TRANSPORT_SPP
    case gaia_transport_spp:
        gaiaTransportSppDropState(transport);
        break;
#endif
#ifdef GAIA_TRANSPORT_MFI
    case gaia_transport_mfi:
        break;
#endif
    default:
        GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
        GAIA_PANIC();
        break;
    }    
}

/*! @brief Start Gaia as a server on a given transport.
 */
void gaiaTransportStartService(gaia_transport_type transport_type)
{
    switch (transport_type)
    {
#ifdef GAIA_TRANSPORT_RFCOMM
    case gaia_transport_rfcomm:
        gaiaTransportRfcommStartService();
        break;
#endif
#ifdef GAIA_TRANSPORT_SPP
    case gaia_transport_spp:
        gaiaTransportSppStartService();
        break;
#endif
#ifdef GAIA_TRANSPORT_MFI
    case gaia_transport_mfi:
        gaiaTransportMfiStartService();
        break;
#endif
    default:
        GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport_type));
        GAIA_PANIC();
        break;
    }

}

/*! @brief Transmit a Gaia packet over a given transport.
 */
void gaiaTransportSendPacket(Task task, gaia_transport *transport, uint16 length, uint8 *data)
{
    switch (transport->type)
    {
    case gaia_transport_none:
    /*  Transport has been cleared down  */
        GAIA_TRANS_DEBUG(("gaia: transport %04x gone\n", (uint16) transport));
        gaiaTransportCommonSendGaiaSendPacketCfm(transport, data, FALSE);
        break;
        
#ifdef GAIA_TRANSPORT_RFCOMM
    case gaia_transport_rfcomm:
        gaiaTransportRfcommSendPacket(task, transport, length, data);
        break;
#endif
#ifdef GAIA_TRANSPORT_SPP
    case gaia_transport_spp:
        gaiaTransportSppSendPacket(task, transport, length, data);
        break;
#endif
#ifdef GAIA_TRANSPORT_MFI
    case gaia_transport_mfi:
        gaiaTransportMfiSendPacket(task, transport, length, data);
        break;
#endif
    default:
        GAIA_TRANS_DEBUG(("gaia: unknown transport %d\n", transport->type));
        GAIA_PANIC();
        break;
    }
}


/*! @brief Get the stream source for a given transport.
 */
Source gaiaTransportGetSource(gaia_transport *transport)
{
    switch (transport->type)
    {
    case gaia_transport_none:
        return NULL;
        break;
        
#ifdef GAIA_TRANSPORT_RFCOMM
    case gaia_transport_rfcomm:
        return StreamSourceFromSink(gaiaTransportRfcommGetSink(transport));
        break;
#endif
        
#ifdef GAIA_TRANSPORT_SPP
    case gaia_transport_spp:
        return StreamSourceFromSink(gaiaTransportSppGetSink(transport));
        break;
#endif
        
    default:
        GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
        GAIA_PANIC();
        break;
    }

    return NULL;
}


/*! @brief Get the stream sink for a given transport.
 */
Sink gaiaTransportGetSink(gaia_transport *transport)
{
    switch (transport->type)
    {
    case gaia_transport_none:
        break;
            
#ifdef GAIA_TRANSPORT_RFCOMM
    case gaia_transport_rfcomm:
        return gaiaTransportRfcommGetSink(transport);
        break;
#endif
#ifdef GAIA_TRANSPORT_SPP
    case gaia_transport_spp:
        return gaiaTransportSppGetSink(transport);
        break;
#endif
#ifdef GAIA_TRANSPORT_MFI
    case gaia_transport_mfi:
        return gaiaTransportMfiGetSink(transport);
        break;
#endif
    default:
        GAIA_TRANS_DEBUG(("Unknown Gaia transport %d\n", transport->type));
        GAIA_PANIC();
        break;
    }

    return NULL;
}

/*! @brief Pass incoming message for handling by a given transport.
 */
bool gaiaTransportHandleMessage(Task task, MessageId id, Message message)
{
#ifdef GAIA_TRANSPORT_RFCOMM
    if (gaiaTransportRfcommHandleMessage(task, id, message))
        return TRUE;
#endif
#ifdef GAIA_TRANSPORT_SPP
    if (gaiaTransportSppHandleMessage(task, id, message))
        return TRUE;
#endif
#ifdef GAIA_TRANSPORT_MFI
    if (gaiaTransportMfiHandleMessage(task, id, message))
        return TRUE;
#endif
    return FALSE;
}
