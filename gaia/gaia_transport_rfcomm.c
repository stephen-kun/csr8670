/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#include "gaia.h"
#include "gaia_private.h"

#ifdef GAIA_TRANSPORT_RFCOMM
#include <string.h>
#include <stream.h>
#include <source.h>
#include <sink.h>
#include <sppc.h>

#include "gaia_transport.h"
#include "gaia_transport_rfcomm.h"
#include "gaia_transport_common.h"


static const uint8 gaia_rfcomm_service_record[] =
{
    0x09, 0x00, 0x01,       /*  0  1  2  ServiceClassIDList(0x0001) */
    0x35,   17,             /*  3  4     DataElSeq 17 bytes */
    0x1C, 0x00, 0x00, 0x11, 0x07, 0xD1, 0x02, 0x11, 0xE1, 0x9B, 0x23, 0x00, 0x02, 0x5B, 0x00, 0xA5, 0xA5,       
                            /*  5 .. 21  UUID GAIA (0x00001107-D102-11E1-9B23-00025B00A5A5) */
    0x09, 0x00, 0x04,       /* 22 23 24  ProtocolDescriptorList(0x0004) */
    0x35,   12,             /* 25 26     DataElSeq 12 bytes */
    0x35,    3,             /* 27 28     DataElSeq 3 bytes */
    0x19, 0x01, 0x00,       /* 29 30 31  UUID L2CAP(0x0100) */
    0x35,    5,             /* 32 33     DataElSeq 5 bytes */
    0x19, 0x00, 0x03,       /* 34 35 36  UUID RFCOMM(0x0003) */
    0x08,    0,             /* 37 38     uint8 RFCOMM channel */
#define GAIA_RFCOMM_SR_CH_IDX (38)
    0x09, 0x00, 0x06,       /* 39 40 41  LanguageBaseAttributeIDList(0x0006) */
    0x35,    9,             /* 42 43     DataElSeq 9 bytes */
    0x09,  'e',  'n',       /* 44 45 46  Language: English */
    0x09, 0x00, 0x6A,       /* 47 48 49  Encoding: UTF-8 */
    0x09, 0x01, 0x00,       /* 50 51 52  ID base: 0x0100 */
    0x09, 0x01, 0x00,       /* 53 54 55  ServiceName 0x0100, base + 0 */
    0x25,   11,             /* 56 57     String length 11 */
    'C', 'S', 'R', ' ', 'G', 'A', 'I', 'A', 
                            /* 58 .. 65  "CSR GAIA"  */
    0xE2, 0x84, 0xA2        /* 66 67 68  U+2122, Trade Mark sign */
};


static const rfcomm_config_params rfcomm_config = 
{
    RFCOMM_DEFAULT_PAYLOAD_SIZE,
    RFCOMM_DEFAULT_MODEM_SIGNAL,
    RFCOMM_DEFAULT_BREAK_SIGNAL,
    RFCOMM_DEFAULT_MSC_TIMEOUT
};
        

static void sdp_register_rfcomm(uint8 channel)
{
    uint8 *sr = malloc(sizeof gaia_rfcomm_service_record);
    
    if (sr == NULL)
    {
        GAIA_DEBUG(("Out of memory (sr)\n"));
        GAIA_PANIC();
    }
        
    else
    {
        memcpy(sr, gaia_rfcomm_service_record, sizeof gaia_rfcomm_service_record);
        sr[GAIA_RFCOMM_SR_CH_IDX] = channel;
        gaia->spp_listen_channel = channel;
        GAIA_TRANS_DEBUG(("gaia: ch %u\n", channel));
        ConnectionRegisterServiceRecord(&gaia->task_data, sizeof gaia_rfcomm_service_record, sr);
    /*  NOTE: firmware will free the slot  */
    }
}


static void process_transport_data(gaia_transport *transport)
{
    Source source = gaiaTransportGetSource(transport);
    uint16 idx = 0;
    uint16 expected = GAIA_OFFS_PAYLOAD;
    uint16 packet_length = 0;
    uint16 data_length = SourceSize(source);
    uint8 *data = (uint8 *) SourceMap(source);
    uint8 *packet = NULL;
    uint8 flags = 0;
    uint8 check = 0;

    GAIA_TRANS_DEBUG(("gaia: process_source_data: %d\n", data_length));

#ifdef DEBUG_GAIA_TRANSPORT
    if (data_length == 0)
        GAIA_DEBUG(("gaia: done\n"));

    else
    {
        uint16 i;
        GAIA_DEBUG(("gaia: got"));
        for (i = 0; i < data_length; ++i)
            GAIA_DEBUG((" %02x", data[i]));
        GAIA_DEBUG(("\n"));
    }
#endif

    if (data_length >= GAIA_OFFS_PAYLOAD)    
    {
        while ((idx < data_length) && (packet_length < expected))
        {
            if (packet_length > 0)
            {
                if (packet_length == GAIA_OFFS_FLAGS)
                    flags = data[idx];

                else if (packet_length == GAIA_OFFS_PAYLOAD_LENGTH)
                {
                    expected = GAIA_OFFS_PAYLOAD + data[idx] + ((flags & GAIA_PROTOCOL_FLAG_CHECK) ? 1 : 0);
                    GAIA_TRANS_DEBUG(("gaia: expect %d + %d + %d = %d\n", 
                                GAIA_OFFS_PAYLOAD, data[idx], (flags & GAIA_PROTOCOL_FLAG_CHECK) ? 1 : 0, expected));
                }

                check ^= data[idx];
                ++packet_length;
            }

            else if (data[idx] == GAIA_SOF)
            {
                packet = data + idx;
                packet_length = 1;
                check = GAIA_SOF;
            }

            ++idx;
        }


        if (packet_length == expected)
        {
            if (((flags & GAIA_PROTOCOL_FLAG_CHECK) == 0) || (check == 0))
                process_packet(transport, packet);

            else
                GAIA_TRANS_DEBUG(("gaia: bad chk\n"));

            SourceDrop(source, idx);
        }
        
        else if (packet_length == 0)
        {
        /*  No start-of-frame; drop the lot  */
            GAIA_TRANS_DEBUG(("gaia: no sof\n"));
            SourceDrop(source, data_length);
        }
        
        
        if (idx < data_length)
        {
            MESSAGE_PMAKE(more, GAIA_INTERNAL_MORE_DATA_T);
            GAIA_TRANS_DEBUG(("gaia: more: %d < %d\n", idx, data_length));
            more->transport = transport;
            MessageSendLater(&gaia->task_data, GAIA_INTERNAL_MORE_DATA, more, APP_BUSY_WAIT_MILLIS);
        }
    }
}


/*************************************************************************
NAME
    gaiaTransportRfcommDropState
    
DESCRIPTION
    Clear down transport state
*/
void gaiaTransportRfcommDropState(gaia_transport *transport)
{
    transport->state.spp.sink = NULL;
    transport->connected = FALSE;
    transport->enabled = FALSE;
    transport->type = gaia_transport_none;
    
    /* No longer have a Gaia connection over this transport, ensure we reset any threshold state */
    gaiaTransportCommonCleanupThresholdState(transport);
}


/*************************************************************************
NAME
    gaiaTransportRfcommSendPacket
    
DESCRIPTION
    Copy the passed packet to the transport sink and flush it
    If <task> is not NULL, send a confirmation message
*/
void gaiaTransportRfcommSendPacket(Task task, gaia_transport *transport, uint16 length, uint8 *data)
{
    bool status = FALSE;
    
    if (gaia)
    {
        Sink sink = gaiaTransportGetSink(transport);
        
        if (SinkClaim(sink, length) == BAD_SINK_CLAIM)
        {
            GAIA_TRANS_DEBUG(("gaia: no sink\n"));
        }

        else
        {
            uint8 *sink_data = SinkMap(sink);
            memcpy (sink_data, data, length);

#ifdef DEBUG_GAIA_TRANSPORT
            {
                uint16 idx;
                GAIA_DEBUG(("gaia: put"));
                for (idx = 0; idx < length; ++idx)
                    GAIA_DEBUG((" %02x", data[idx]));
                GAIA_DEBUG(("\n"));
            }
#endif
            status = SinkFlush(sink, length);
        }   
    }
    
    if (task)
        gaiaTransportCommonSendGaiaSendPacketCfm(transport, data, status);
    
    else
        free(data);
}


/*! @brief
 */
void gaiaTransportRfcommInit(gaia_transport *transport)
{
    memset(transport, 0, sizeof (gaia_transport));
    transport->type = gaia_transport_rfcomm;
}


/*! @brief
 */
void gaiaTransportRfcommConnectRes(gaia_transport *transport)
{

}

/*! @brief
 */
void gaiaTransportRfcommDisconnectReq(gaia_transport *transport)
{
    ConnectionRfcommDisconnectRequest(&gaia->task_data, gaiaTransportRfcommGetSink(transport));
}

/*! @brief
 */
void gaiaTransportRfcommDisconnectRes(gaia_transport *transport)
{

}

/*! @brief
 */
void gaiaTransportRfcommStartService(void)
{
    ConnectionRfcommAllocateChannel(&gaia->task_data, SPP_DEFAULT_CHANNEL);
}

/*! @brief
 */
Sink gaiaTransportRfcommGetSink(gaia_transport *transport)
{
    return transport->state.spp.sink;
}


/*! @brief
 */
bool gaiaTransportRfcommHandleMessage(Task task, MessageId id, Message message)
{
    bool msg_handled = TRUE;    /* default position is we've handled the message */

    switch (id)
    {
        case GAIA_INTERNAL_MORE_DATA:
            {
                GAIA_INTERNAL_MORE_DATA_T *m = (GAIA_INTERNAL_MORE_DATA_T *) message;
                GAIA_TRANS_DEBUG(("gaia: GAIA_INTERNAL_MORE_DATA: t=%04x\n", (uint16) m->transport));
                process_transport_data(m->transport);
            }
            break;
            
            
        case MESSAGE_MORE_DATA:
            {
                MessageMoreData *m = (MessageMoreData *) message;
                gaia_transport *t = gaiaTransportFromSink(StreamSinkFromSource(m->source));
                GAIA_TRANS_DEBUG(("gaia: MESSAGE_MORE_DATA: t=%04x\n", (uint16) t));
                
                if (t && (t->type == gaia_transport_rfcomm))
                    process_transport_data(t);
                
                else
                    msg_handled = FALSE;
            }
            break;
            

        case CL_RFCOMM_REGISTER_CFM:
            {
                CL_RFCOMM_REGISTER_CFM_T *m = (CL_RFCOMM_REGISTER_CFM_T *) message;
                GAIA_TRANS_DEBUG(("gaia: CL_RFCOMM_REGISTER_CFM: %d = %d\n", m->server_channel, m->status));
                
                if (m->status == success)
                    sdp_register_rfcomm(m->server_channel);
                
                else
                    gaiaTransportCommonSendGaiaStartServiceCfm(gaia_transport_rfcomm, NULL, FALSE);
            }
            break;
        
            
        case CL_SDP_REGISTER_CFM:
            {
                CL_SDP_REGISTER_CFM_T *m = (CL_SDP_REGISTER_CFM_T *) message;
                GAIA_TRANS_DEBUG(("gaia: CL_SDP_REGISTER_CFM: %d\n", m->status));
                
                if (m->status == sds_status_success)
                {
                    if (gaia->spp_sdp_handle == 0)
                        gaiaTransportCommonSendGaiaStartServiceCfm(gaia_transport_rfcomm, NULL, TRUE);
                    
                    gaia->spp_sdp_handle = m->service_handle;
                }
                
                else
                    gaiaTransportCommonSendGaiaStartServiceCfm(gaia_transport_rfcomm, NULL, FALSE);
            }
            break;

            
        case CL_RFCOMM_CONNECT_IND:
            {
                CL_RFCOMM_CONNECT_IND_T *m = (CL_RFCOMM_CONNECT_IND_T *) message;
                gaia_transport *transport = gaiaTransportFindFree();

                GAIA_TRANS_DEBUG(("gaia: CL_RFCOMM_CONNECT_IND\n"));
                
                if (transport == NULL)
                    ConnectionRfcommConnectResponse(task, FALSE, m->sink, m->server_channel, &rfcomm_config);
                
                else
                {
                    transport->type = gaia_transport_rfcomm;
                    transport->state.spp.sink = m->sink;
                    transport->state.spp.rfcomm_channel = m->server_channel;
                    ConnectionRfcommConnectResponse(task, TRUE, m->sink, m->server_channel, &rfcomm_config);
                }
            }
            break;
            
            
        case CL_RFCOMM_SERVER_CONNECT_CFM:
            {
                CL_RFCOMM_SERVER_CONNECT_CFM_T *m = (CL_RFCOMM_SERVER_CONNECT_CFM_T *) message;
                gaia_transport *transport = gaiaTransportFromRfcommChannel(m->server_channel);
                
                GAIA_TRANS_DEBUG(("gaia: CL_RFCOMM_SERVER_CONNECT_CFM: ch=%d sts=%d\n", 
                                  m->server_channel, m->status));
                
                if (m->status == rfcomm_connect_success)
                {
                    transport->state.spp.sink = m->sink;
                    transport->state.spp.rfcomm_channel = m->server_channel;
                    ConnectionUnregisterServiceRecord(task, gaia->spp_sdp_handle);
                    gaiaTransportCommonSendGaiaConnectInd(transport, TRUE);
                    transport->connected = TRUE;
                    transport->enabled = TRUE;
                }
                
                else
                    gaiaTransportCommonSendGaiaConnectInd(transport, FALSE);
                    
            }
            break;
            
            
        case CL_SDP_UNREGISTER_CFM:
            {
                CL_SDP_UNREGISTER_CFM_T *m = (CL_SDP_UNREGISTER_CFM_T *) message;
                GAIA_TRANS_DEBUG(("gaia: CL_SDP_UNREGISTER_CFM: %d\n", m->status));
                if (m->status == success)
                {
                /*  Get another channel from the pool  */
                    ConnectionRfcommAllocateChannel(task, SPP_DEFAULT_CHANNEL);
                }
            }
            break;
 
            
        case CL_RFCOMM_DISCONNECT_IND:
            {
                CL_RFCOMM_DISCONNECT_IND_T *m = (CL_RFCOMM_DISCONNECT_IND_T *) message;
                gaia_transport *transport = gaiaTransportFromSink(m->sink);
                
                GAIA_TRANS_DEBUG(("gaia: CL_RFCOMM_DISCONNECT_IND\n"));
                
                ConnectionRfcommDisconnectResponse(m->sink);

            /*  release channel for re-use  */
                ConnectionRfcommDeallocateChannel(task, transport->state.spp.rfcomm_channel);
            }
            break;
        

        case CL_RFCOMM_DISCONNECT_CFM:
            {
                CL_RFCOMM_DISCONNECT_CFM_T *m = (CL_RFCOMM_DISCONNECT_CFM_T *) message;
                gaia_transport *transport = gaiaTransportFromSink(m->sink);
                
                GAIA_TRANS_DEBUG(("gaia: CL_RFCOMM_DISCONNECT_CFM\n"));
                gaiaTransportDropState(transport);
                gaiaTransportCommonSendGaiaDisconnectCfm(transport);
            }
            break;
            
            
        case CL_RFCOMM_UNREGISTER_CFM:
            {
                CL_RFCOMM_UNREGISTER_CFM_T *m = (CL_RFCOMM_UNREGISTER_CFM_T *) message;
                GAIA_TRANS_DEBUG(("gaia: CL_RFCOMM_UNREGISTER_CFM\n"));
                
                if (m->status == success)
                {
                    gaia_transport *transport = gaiaTransportFromRfcommChannel(m->server_channel);
                    gaiaTransportCommonSendGaiaDisconnectInd(transport);                            
                }
            }
            break;
            
        
             /*  Things to ignore  */
        case MESSAGE_MORE_SPACE:
        case MESSAGE_SOURCE_EMPTY:
        case CL_RFCOMM_PORTNEG_IND:
        case CL_RFCOMM_CONTROL_IND:
        case CL_RFCOMM_LINE_STATUS_IND:
            break;

        default:
            {
                /* indicate we couldn't handle the message */
            /*  GAIA_DEBUG(("gaia: rfcomm: unh 0x%04X\n", id));  */
                msg_handled = FALSE;
            }
            break;
    }

    return msg_handled;
}

#endif /* GAIA_TRANSPORT_RFCOMM */
