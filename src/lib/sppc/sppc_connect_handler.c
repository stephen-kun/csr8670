/* Copyright (C) Cambridge Silicon Radio Limited 2010-2014 */
/* Part of ADK 3.5 

FILE NAME
	sppc_connect_handler.c        

DESCRIPTION
	Functions for making an SPP client connection (device A, initiator).

*/

#include <sdp_parse.h>
#include "sppc.h"
#include "../spp_common/spp_common_private.h"

struct __SPP 
{
    SPP_COMMON      c;
    uint16          security_channel;
};


/* Spp service search request */
static const uint8 SppServiceRequest [] =
{
    0x35, 0x05,                     /* type = DataElSeq, 5 bytes in DataElSeq */
    0x1a, 0x00, 0x00, 0x11, 0x01    /* 4 byte UUID */
};


/* Spp protocol search request */
static const uint8 protocolAttributeRequest [] =
{
    0x35, 0x03,         /* type = DataElSeq, 3 bytes in DataElSeq */
    0x09, 0x00, 0x04    /* 2 byte UINT attrID ProtocolDescriptorList */    
};

#define SPP_SDP_SEARCH(task,bd_addr) ConnectionSdpServiceSearchAttributeRequest(\
                    task,\
                    bd_addr,\
                    0x40,\
                    sizeof(SppServiceRequest),\
                    (uint8 *)SppServiceRequest,\
                    sizeof(protocolAttributeRequest),\
                    (uint8 *)protocolAttributeRequest\
                    )

#define SEND_CONNECT_CFM(spp,status) sppSendConnectCfm(spp,SPP_CLIENT_CONNECT_CFM,status)

/*****************************************************************************/
static void sppcHandleRegisterOutgoingServiceCfm(SPP *spp, CL_SM_REGISTER_OUTGOING_SERVICE_CFM_T *cfm)
{
    /* Store the security channel id and start a search for the SPP
     * service on the remote device. 
     */
    SPP_STATE(sppSearching);
    
    spp->security_channel = cfm->security_channel;

    SPP_SDP_SEARCH(&spp->c.task, &spp->c.bd_addr);
}

/*****************************************************************************/

static void sppcHandleSdpServiceSearchAttributeCfm(SPP *spp, CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm)
{
    if (cfm->status == sdp_response_success)
    {
        uint8 rfcomm_channel;
        uint8 channels_found;
        uint8 *p_rfcomm_channel = &rfcomm_channel;
        
        if (
            SdpParseGetMultipleRfcommServerChannels(
                cfm->size_attributes,
                (uint8 *)cfm->attributes,
                1,
                &p_rfcomm_channel,
                &channels_found
                )
            )
        {
            /* Proceed with the RFCOMM connection */
            rfcomm_config_params rfcomm_config = 
                {
                RFCOMM_DEFAULT_PAYLOAD_SIZE,
                RFCOMM_DEFAULT_MODEM_SIGNAL,
                RFCOMM_DEFAULT_BREAK_SIGNAL,
                RFCOMM_DEFAULT_MSC_TIMEOUT
                };

            if (spp->c.max_payload_size)
                rfcomm_config.max_payload_size = spp->c.max_payload_size;
                        
            ConnectionRfcommConnectRequest(
                &spp->c.task,
                &spp->c.bd_addr,
                spp->security_channel,
                rfcomm_channel,
                &rfcomm_config
                );

            SPP_STATE(sppConnecting);
        }
        else
        {
            /* This should not happen, but if it does... */
            Panic();
        }
    }
    else
    {
        SEND_CONNECT_CFM(spp, spp_connect_sdp_fail);
    }    
}

/*****************************************************************************/

static void sppcHandleRfcommClientConnectCfm(SPP *spp, CL_RFCOMM_CLIENT_CONNECT_CFM_T *cfm)
{
    if (cfm->status == rfcomm_connect_pending)
    {
        spp->c.sink = cfm->sink;
    }
    else if (cfm->status == rfcomm_connect_success)
    {
        spp->c.sink = cfm->sink;
        spp->c.max_payload_size = cfm->payload_size;
        SPP_STATE(sppConnected);
    }
    SEND_CONNECT_CFM(spp, sppConvertRfcommConnectStatus(cfm->status));
}

/*****************************************************************************/

static void sppcConnectionHandler(Task task, MessageId id, Message message)
{
   	SPP* spp = (SPP*) task;

    switch(spp->c.state)
    {
    case sppInitialising:
        if (id == CL_SM_REGISTER_OUTGOING_SERVICE_CFM)
            sppcHandleRegisterOutgoingServiceCfm(
                spp,
                (CL_SM_REGISTER_OUTGOING_SERVICE_CFM_T *)message
                );
        else
            sppHandleUnexpectedMsg(spp->c.state, id);
        break;
        
    case sppSearching:
        switch(id)
        {
        case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM:
            sppcHandleSdpServiceSearchAttributeCfm(
                spp,
                (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *)message
                );
            break;
                
        default:
            sppHandleUnexpectedMsg(spp->c.state, id);
            break;
        }
        break;

    case sppConnecting:
        switch(id)
        {
        case CL_RFCOMM_CLIENT_CONNECT_CFM:
            sppcHandleRfcommClientConnectCfm(
                spp,
                (CL_RFCOMM_CLIENT_CONNECT_CFM_T *)message 
                );
            break;

        case CL_RFCOMM_DISCONNECT_IND:
            sppHandleRfcommDisconnectInd(
                spp,
                (CL_RFCOMM_DISCONNECT_IND_T *)message
                );
            break;

        case CL_SM_ENCRYPTION_CHANGE_IND:
            sppForwardSmEncryptionChangeInd(
                spp,
                (CL_SM_ENCRYPTION_CHANGE_IND_T *)message
                );
            break;

        case CL_RFCOMM_CONTROL_IND:
            sppForwardRfcommControlInd(spp, (CL_RFCOMM_CONTROL_IND_T*)message);
            break;


        default:
            sppHandleUnexpectedMsg(spp->c.state, id);
            break;
        }
        break;

    case sppConnected:
        switch(id)
        {
        case CL_RFCOMM_DISCONNECT_IND:
            sppHandleRfcommDisconnectInd(
                spp,
                (CL_RFCOMM_DISCONNECT_IND_T *)message
                );
            break;

        case CL_RFCOMM_CONTROL_IND:
            sppForwardRfcommControlInd(spp, (CL_RFCOMM_CONTROL_IND_T*)message);
            break;

        case CL_SM_ENCRYPTION_CHANGE_IND:
            sppForwardSmEncryptionChangeInd(
                spp,
                (CL_SM_ENCRYPTION_CHANGE_IND_T *)message
                );
            break;
            
        case MESSAGE_MORE_DATA:
            sppForwardMessageMoreData(spp, (MessageMoreData *)message);
            break;
            
        case MESSAGE_MORE_SPACE:
            sppForwardMessageMoreSpace(spp, (MessageMoreSpace *)message);
            break;

        /* Ignored messages */
        case MESSAGE_STREAM_DISCONNECT:
        case MESSAGE_SOURCE_EMPTY:
            break;

        default:
            sppHandleUnexpectedMsg(spp->c.state, id);
            break;
        }
        break;
    
    case sppDisconnecting:
        switch(id)
        {
        case CL_RFCOMM_DISCONNECT_CFM:
            sppHandleRfcommDisconnectCfm(
                spp, 
                (CL_RFCOMM_DISCONNECT_CFM_T *)message
                );
            break;
            
        case SPP_INTERNAL_DISCONNECT_REQ:
            /* No tidy up needed for the client. */
            MessageSend(&spp->c.task, SPP_INTERNAL_TASK_DELETE_REQ, 0);
            break;
            
        case SPP_INTERNAL_TASK_DELETE_REQ:
            sppDeleteTask(spp);
            break;    

        /* Ignored messages */
        case MESSAGE_STREAM_DISCONNECT:
        case MESSAGE_SOURCE_EMPTY:
            break;

        default:
            sppHandleUnexpectedMsg(spp->c.state, id);
            break;
        }
        break;

    default:
        SPP_DEBUG(("Unexpected SPP Client state %d\n", spp->c.state));
        break;
    }
}

/*****************************************************************************/

void SppConnectRequest(Task theAppTask, const bdaddr *bd_addr, const uint16 security_channel, const uint16 max_payload_size)
{
    /* Create the Sppc task */
    SPP *spp = PanicUnlessNew(SPP);

    SPP_PRINT(("SPP Client Task Created.\n"));
    
    spp->c.task.handler= sppcConnectionHandler;
    spp->c.client_task = theAppTask;
    spp->c.sink = 0;
    spp->c.bd_addr = *bd_addr;
    spp->c.max_payload_size = max_payload_size;
    spp->c.state = sppIdle;
    spp->security_channel = security_channel;

    /* If the security_channel is 0, then before searching for an SPP service
     * to connect to, first create the security channel with default security
     * level 2 (SSP, Authentication, Encryption).
     */
    if (security_channel == 0)
    {
        SPP_STATE(sppInitialising);
        ConnectionSmRegisterOutgoingRfcomm(
            &spp->c.task, 
            bd_addr, 
            sec4_out_level_2
            );
    }
    /* Otherwise, proceed with searching for the SPP service on the remote 
     * device.
     */
    else
    {
        SPP_STATE(sppSearching);
        SPP_SDP_SEARCH(&spp->c.task, &spp->c.bd_addr);
    }
}

