/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_profile_handler.c

DESCRIPTION
    File containing the profile handler function for the a2dp library.

NOTES

*/


/****************************************************************************
    Header files
*/
#include "a2dp.h"
#include "a2dp_codec_handler.h"
#include "a2dp_init.h"
#include "a2dp_l2cap_handler.h"
#include "a2dp_private.h"
#include "a2dp_profile_handler.h"
#include "a2dp_packet_handler.h"
#include "a2dp_sdp.h"
#include "a2dp_command_handler.h"

#include <print.h>

#ifndef BUILD_FOR_23F
#include <sink.h>
#include <stream.h>
#endif

/*****************************************************************************/
static void handleUnexpected(uint16 type)
{
    A2DP_DEBUG(("A2DP handleUnexpected - MsgId 0x%x\n", type));
}


/****************************************************************************/
static void sendEncryptionChangeInd(const CL_SM_ENCRYPTION_CHANGE_IND_T *ind)
{
    MAKE_A2DP_MESSAGE(A2DP_ENCRYPTION_CHANGE_IND);
    message->encrypted = ind->encrypted;
    message->a2dp = a2dp;
    MessageSend(a2dp->clientTask, A2DP_ENCRYPTION_CHANGE_IND, message);
}


/*****************************************************************************/
void a2dpProfileHandler(Task task, MessageId id, Message message)
{
    switch (id)
    {
    case A2DP_INTERNAL_L2CAP_CONNECT_REQ:
        PRINT(("A2DP_INTERNAL_L2CAP_CONNECT_REQ\n"));
        a2dpHandleL2capConnectReq((A2DP_INTERNAL_L2CAP_CONNECT_REQ_T *) message);
        break;
    
    case A2DP_INTERNAL_SIGNALLING_CONNECT_REQ:
        PRINT(("A2DP_INTERNAL_SIGNALLING_CONNECT_REQ\n"));
        a2dpHandleSignallingConnectReq((A2DP_INTERNAL_SIGNALLING_CONNECT_REQ_T *) message);
        break;

    case A2DP_INTERNAL_SIGNALLING_CONNECT_RES:
        PRINT(("A2DP_INTERNAL_SIGNALLING_CONNECT_RES\n"));
        a2dpHandleSignallingConnectRes((A2DP_INTERNAL_SIGNALLING_CONNECT_RES_T *) message);
        break;

    case A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ:
        PRINT(("A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ\n"));
        a2dpHandleSignallingDisconnectReq((A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ_T *) message);
        break;

    case A2DP_INTERNAL_CODEC_CONFIGURE_RSP:
        PRINT(("A2DP_INTERNAL_CODEC_CONFIGURE_RSP\n"));
        a2dpHandleCodecConfigureResponse((A2DP_INTERNAL_CODEC_CONFIGURE_RSP_T *) message);
        break;

    case A2DP_INTERNAL_MEDIA_OPEN_REQ:
        PRINT(("A2DP_INTERNAL_OPEN_REQ\n"));
        a2dpStreamEstablish((A2DP_INTERNAL_MEDIA_OPEN_REQ_T *) message);
        break;

    case A2DP_INTERNAL_MEDIA_OPEN_RES:
        PRINT(("A2DP_INTERNAL_OPEN_RES\n"));
        a2dpStreamOpenResponse((A2DP_INTERNAL_MEDIA_OPEN_RES_T *) message);
        break;

    case A2DP_INTERNAL_MEDIA_START_REQ:
        PRINT(("A2DP_INTERNAL_START_REQ\n"));
        a2dpStreamStart((A2DP_INTERNAL_MEDIA_START_REQ_T *) message);
        break;
        
    case A2DP_INTERNAL_MEDIA_START_RES:
        PRINT(("A2DP_INTERNAL_START_RES\n"));
        a2dpStreamStartResponse((A2DP_INTERNAL_MEDIA_START_RES_T *) message);
        break;
        
    case A2DP_INTERNAL_MEDIA_SUSPEND_REQ:
        PRINT(("A2DP_INTERNAL_MEDIA_SUSPEND_REQ\n"));
        a2dpStreamSuspend((A2DP_INTERNAL_MEDIA_SUSPEND_REQ_T *) message);
        break;

    case A2DP_INTERNAL_MEDIA_CLOSE_REQ:
        PRINT(("A2DP_INTERNAL_MEDIA_CLOSE_REQ\n"));
        a2dpStreamRelease((A2DP_INTERNAL_MEDIA_CLOSE_REQ_T *) message);
        break;
        
    case A2DP_INTERNAL_MEDIA_RECONFIGURE_REQ:
        PRINT(("A2DP_INTERNAL_MEDIA_RECONFIGURE_REQ\n"));
        a2dpStreamReconfigure((A2DP_INTERNAL_MEDIA_RECONFIGURE_REQ_T *) message);
        break;
        
    case A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_REQ:
        PRINT(("A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_REQ\n"));
        a2dpStreamDelayReport(((A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_REQ_T *)message)->device, ((A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_REQ_T *)message)->delay);
        break;
        
    case A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_RES:
        PRINT(("A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_RES\n"));
        a2dpStreamDelayReport(((A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_RES_T *)message)->device, ((A2DP_INTERNAL_MEDIA_AV_SYNC_DELAY_RES_T *)message)->delay);
        break;
        
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 0:
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 1:
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 2:
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 3:
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 4:
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 5:
    case A2DP_INTERNAL_LINKLOSS_TIMEOUT_BASE + 6:
        PRINT(("A2DP_INTERNAL_LINKLOSS_TIMEOUT\n"));
        a2dpHandleL2capLinklossTimeout(id);
        break;
    
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 0:
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 1:
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 2:
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 3:
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 4:
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 5:
    case A2DP_INTERNAL_CLIENT_RSP_TIMEOUT_BASE + 6:
        PRINT(("A2DP_INTERNAL_CLIENT_RSP_TIMEOUT\n"));
        a2dpHandleInternalClientRspTimeout(id);
        break;
    
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 0:
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 1:
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 2:
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 3:
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 4:
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 5:
    case A2DP_INTERNAL_REMOTE_CMD_TIMEOUT_BASE + 6:
        PRINT(("A2DP_INTERNAL_REMOTE_CMD_TIMEOUT\n"));
        a2dpHandleInternalRemoteCmdTimeout(id);
        break;
    
    case A2DP_INTERNAL_WATCHDOG_BASE + 0:
    case A2DP_INTERNAL_WATCHDOG_BASE + 1:
    case A2DP_INTERNAL_WATCHDOG_BASE + 2:
    case A2DP_INTERNAL_WATCHDOG_BASE + 3:
    case A2DP_INTERNAL_WATCHDOG_BASE + 4:
    case A2DP_INTERNAL_WATCHDOG_BASE + 5:
    case A2DP_INTERNAL_WATCHDOG_BASE + 6:
        PRINT(("A2DP_INTERNAL_WATCHDOG_IND\n"));
        a2dpHandleInternalWatchdogTimeout(id);
        break;

#if 0
    case A2DP_INTERNAL_RECONFIGURE_REQ:
        PRINT(("A2DP_INTERNAL_RECONFIGURE_REQ\n"));
        a2dpHandleReconfigureReq((A2DP_INTERNAL_RECONFIGURE_REQ_T *) message);
        break;
#endif

#if 0
    case A2DP_INTERNAL_SEND_CODEC_PARAMS_REQ:
        PRINT(("A2DP_INTERNAL_SEND_CODEC_PARAMS_REQ\n"));
        a2dpSendCodecAudioParams();
        if (((A2DP_INTERNAL_SEND_CODEC_PARAMS_REQ_T *) message)->send_reconfigure_message)
            a2dpSendReconfigureCfm(a2dp_success);
        break;
#endif

#if 0
    case A2DP_INTERNAL_GET_CAPS_TIMEOUT_IND:
        PRINT(("A2DP_INTERNAL_GET_CAPS_TIMEOUT_IND\n"));
        a2dpGetCapsTimeout();
        break;
#endif

    default:
        switch(id)
        {
        case CL_SDP_REGISTER_CFM:
            PRINT(("CL_SDP_REGISTER_CFM\n"));
            a2dpHandleSdpRegisterCfm((CL_SDP_REGISTER_CFM_T *) message);
            break;

        case CL_L2CAP_REGISTER_CFM:
            PRINT(("CL_L2CAP_REGISTER_CFM\n"));
            a2dpHandleL2capRegisterCfm((CL_L2CAP_REGISTER_CFM_T *) message);
            break;

        case CL_L2CAP_CONNECT_IND:
            PRINT(("CL_L2CAP_CONNECT_IND\n"));
            a2dpHandleL2capConnectInd((CL_L2CAP_CONNECT_IND_T *) message);
            break;

        case CL_L2CAP_CONNECT_CFM:
            PRINT(("CL_L2CAP_CONNECT_CFM\n"));
            a2dpHandleL2capConnectCfm((CL_L2CAP_CONNECT_CFM_T *) message);
            break;

        case CL_L2CAP_DISCONNECT_IND:
            PRINT(("CL_L2CAP_DISCONNECT_IND\n"));
            a2dpHandleL2capDisconnect(((CL_L2CAP_DISCONNECT_IND_T *)message)->identifier, ((CL_L2CAP_DISCONNECT_IND_T *)message)->sink, ((CL_L2CAP_DISCONNECT_IND_T *)message)->status);
            ConnectionL2capDisconnectResponse(((CL_L2CAP_DISCONNECT_IND_T *)message)->identifier, ((CL_L2CAP_DISCONNECT_IND_T *)message)->sink);
            break;

        case CL_L2CAP_DISCONNECT_CFM:
            PRINT(("CL_L2CAP_DISCONNECT_CFM\n"));
            a2dpHandleL2capDisconnect(0, ((CL_L2CAP_DISCONNECT_CFM_T *)message)->sink, ((CL_L2CAP_DISCONNECT_CFM_T *)message)->status);
            break;

        case CL_SM_ENCRYPTION_CHANGE_IND:
            PRINT(("CL_SM_ENCRYPTION_CHANGE_IND\n"));
            /* We have received an indication that the encryption status of the sink has changed */
            sendEncryptionChangeInd((CL_SM_ENCRYPTION_CHANGE_IND_T *) message);
            break;

        case CL_DM_ROLE_CFM:
        case CL_SM_ENCRYPTION_KEY_REFRESH_IND:
        case CL_L2CAP_TIMEOUT_IND:
            break;

        case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM:
            a2dpHandleSdpServiceSearchAttributeCfm ((CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *)message);
            break;

        default:
            switch(id)
            {
            case MESSAGE_MORE_DATA:
                PRINT(("MESSAGE_MORE_DATA\n"));
                /* Data has arrived on the signalling channel */
                a2dpHandleSignalPacket( a2dpFindDeviceFromSink( StreamSinkFromSource(((MessageMoreData *)message)->source) ));
                break;

            case MESSAGE_MORE_SPACE:
            case MESSAGE_STREAM_DISCONNECT:
            case MESSAGE_SOURCE_EMPTY:
                break;

            default:
                handleUnexpected(id);
                break;
            }
        }
    }
}
