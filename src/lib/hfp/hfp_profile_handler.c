/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    profile_handler.c        

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_link_manager.h"
#include "hfp_common.h"
#include "hfp_indicators_handler.h"
#include "hfp_ok.h"
#include "hfp_receive_data.h"
#include "hfp_rfc.h"
#include "hfp_sdp.h"
#include "hfp_send_data.h"
#include "hfp_slc_handler.h"
#include "hfp_audio_handler.h"
#include "hfp_init.h"
#include "hfp_profile_handler.h"
#include "hfp_call_handler.h"
#include "hfp_caller_id_handler.h"
#include "hfp_response_hold_handler.h"
#include "hfp_current_calls_handler.h"
#include "hfp_hs_handler.h"
#include "hfp_multiple_calls_handler.h"
#include "hfp_dial_handler.h"
#include "hfp_voice_handler.h"
#include "hfp_nrec_handler.h"
#include "hfp_extended_error_handler.h"
#include "hfp_voice_tag_handler.h"
#include "hfp_subscriber_num_handler.h"
#include "hfp_dtmf_handler.h"
#include "hfp_network_operator_handler.h"
#include "hfp_csr_features.h"

#define DEBUG_PRINT_ENABLEDx
#include <print.h>

/*lint -e525 -e725 -e830 */

typedef enum
{
    hfpUnexpectedClPrim,
    hfpUnexpectedHfpPrim,
    hfpUnexpectedMessage,
    hfpUnexpectedWbsPrim
} hfpUnexpectedReasonCode;


/****************************************************************************
NAME    
    handleUnexpected    

DESCRIPTION
    This function is called as a result of a message arriving when this
    library was not expecting it.

RETURNS
    void    
*/
static void handleUnexpected(hfpUnexpectedReasonCode code, uint16 type)
{
    type = type;
    code = code;

    HFP_DEBUG(("theHfp handleUnexpected - Code 0x%x MsgId 0x%x\n", code, type));
}


/****************************************************************************
NAME    
    hfpProfileHandler

DESCRIPTION
    All messages for this profile lib are handled by this function

RETURNS
    void
*/
void hfpProfileHandler(Task task, MessageId id, Message message)
{
    if(!theHfp->initialised)
    {
        /* Initialisation messages */
        if(id >= HFP_MSG_BASE && id < HFP_INTERNAL_TOP)
        {
            switch(id)
            {
                case HFP_INTERNAL_SDP_REGISTER_REQ:
                    PRINT(("HFP_INTERNAL_SDP_REGISTER_REQ\n"));
                    hfpRegisterServiceRecord( ((HFP_INTERNAL_SDP_REGISTER_REQ_T *)message)->service );
                break;
                
                default:
                     /* Panic in debug and ignore in release lib variants */  
                    goto hfp_prim_error;
            }
        }
        else if(id >= CL_MESSAGE_BASE && id < CL_MESSAGE_TOP)
        {
            switch (id)
            {
                case CL_DM_SYNC_REGISTER_CFM:
                    PRINT(("CL_DM_SYNC_REGISTER_CFM\n"));
                    /* Ignore this silently */
                break;
                
                case CL_RFCOMM_REGISTER_CFM:
                    PRINT(("CL_RFCOMM_REGISTER_CFM\n"));
                    hfpInitRfcommRegisterCfm((CL_RFCOMM_REGISTER_CFM_T *) message);
                break;
                
                case CL_SDP_REGISTER_CFM:
                    PRINT(("CL_SDP_REGISTER_CFM\n"));
                    hfpInitSdpRegisterCfm((CL_SDP_REGISTER_CFM_T *) message);
                break;
                
                default:
                     /* Panic in debug and ignore in release lib variants */  
                    goto cl_prim_error;
                break;
            }
        }
        else
        {
            /* Panic in debug and ignore in release lib variants */  
            goto sys_prim_error;
        }
    }
    else
    {
        /* Run time messages */
        if(id == HFP_INTERNAL_SDP_REGISTER_REQ)
        {
            /* 
               This message does not conform to the common structure,
               also its sent from inside the lib only so we know service
               is valid. 
            */
            PRINT(("HFP_INTERNAL_SDP_REGISTER_REQ\n"));
            hfpRegisterServiceRecord( ((HFP_INTERNAL_SDP_REGISTER_REQ_T *)message)->service );
        }
        else if(id >= HFP_MSG_BASE && id < HFP_INTERNAL_TOP)
        {
            hfp_link_data* link = NULL;
            bool success = FALSE;
            
            /* Try and obtain the link for this message */
            if(message)
                link = ((HFP_COMMON_INTERNAL_MESSAGE_T*)message)->link;
            else
                link = hfpGetLinkFromTimeoutMessage(id);
            
            if(link)
            {
                switch(link->ag_slc_state)
                {
                    /* 
                       In theory audio connect should only happen once SLC is complete, 
                       however in practice some AG's will open SCO before completing the
                       SLC so we should be able to handle it. 
                    */
                    case hfp_slc_searching:
                    case hfp_slc_incoming:
                    case hfp_slc_outgoing:
                    case hfp_slc_connected:
                        switch(id)
                        {
                            case HFP_INTERNAL_AUDIO_CONNECT_RES:
                                PRINT(("HFP_INTERNAL_AUDIO_CONNECT_RES\n"));
                                hfpHandleAudioConnectRes((HFP_INTERNAL_AUDIO_CONNECT_RES_T*)message);
                                success = TRUE;
                            break;
                            
                            case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_0_IND:
                            case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_1_IND:
                                PRINT(("HFP_RFCOMM_LINK_LOSS_RECONNECT\n"));
                                hfpHandleRfcommLinkLossReconnect(link);
                                success = TRUE;
                            break;
                            
                            case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_0_IND:
                            case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_1_IND:
                                PRINT(("HFP_RFCOMM_LINK_LOSS_TIMEOUT\n"));
                                hfpHandleRfcommLinkLossTimeout(link);
                                success = TRUE;
                            break;
                                
                            case HFP_INTERNAL_SLC_DISCONNECT_REQ:
                                PRINT(("HFP_INTERNAL_SLC_DISCONNECT_REQ\n"));
                                hfpHandleDisconnectRequest(link);
                                success = TRUE;
                            break;
                            
                            default:
                            break;
                        }
                    break;
                    
                    /*
                       AT commands/requests that are valid once SLC is completed
                    */
                    case hfp_slc_complete:
                        if(hfpLinkIsHfp(link))
                        {
                            /* Messages valid for HFP in this state */
                            switch(id)
                            {
                                case HFP_INTERNAL_AT_BTRH_STATUS_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BTRH_STATUS_REQ\n"));
                                    hfpHandleBtrhStatusReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_BAC_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BAC_REQ\n"));
                                    /* Only allowed if we are an HFP device */
                                    hfpHandleBacRequest(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_CLIP_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CLIP_REQ\n"));
                                    success = hfpHandleCallerIdEnableReq((HFP_INTERNAL_AT_CLIP_REQ_T*)message);
                                break;
                        
                                case HFP_INTERNAL_AT_ANSWER_REQ:
                                    PRINT(("HFP_INTERNAL_AT_ANSWER_REQ\n"));
                                    success = hfpHandleAnswerCall((HFP_INTERNAL_AT_ANSWER_REQ_T*)message);
                                break;
                                
                                case HFP_INTERNAL_AT_TERMINATE_REQ:
                                    PRINT(("HFP_INTERNAL_AT_TERMINATE_REQ\n"));
                                    success = hfpHandleTerminateCall(link, hfpChupCmdPending);
                                break;
                                
                                case HFP_INTERNAL_AT_CLCC_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CLCC_REQ\n"));
                                    success = hfpHandleCurrentCallsGetReq(link);
                                break;
                                
                                case HFP_INTERNAL_AT_CHLD_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CHLD_REQ\n"));
                                    success = hfpSendChldCmd((HFP_INTERNAL_AT_CHLD_REQ_T*)message);
                                break;
                                
                                case HFP_INTERNAL_AT_BTRH_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BTRH_REQ\n"));
                                    success = hfpHandleBtrhReq((HFP_INTERNAL_AT_BTRH_REQ_T*)message);
                                break;
                        
                                case HFP_INTERNAL_AT_BLDN_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BLDN_REQ\n"));
                                    hfpHandleLastNumberRedial(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_ATD_NUMBER_REQ:
                                    PRINT(("HFP_INTERNAL_AT_ATD_NUMBER_REQ\n"));
                                    hfpHandleDialNumberRequest((HFP_INTERNAL_AT_ATD_NUMBER_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_ATD_MEMORY_REQ:
                                    PRINT(("HFP_INTERNAL_AT_ATD_MEMORY_REQ\n"));
                                    hfpHandleDialMemoryRequest((HFP_INTERNAL_AT_ATD_MEMORY_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_BVRA_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BVRA_REQ\n"));
                                    success = hfpHandleVoiceRecognitionEnable((HFP_INTERNAL_AT_BVRA_REQ_T*)message);
                                break;
                                
                                case HFP_INTERNAL_AT_NREC_REQ:
                                    PRINT(("HFP_INTERNAL_AT_NREC_REQ\n"));
                                    hfpHandleNrEcDisable(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_BIA_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BIA_REQ\n"));
                                    hfpHandleSetActiveIndicatorsReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_CMEE_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CMEE_REQ\n"));
                                    hfpHandleExtendedErrorReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_CNUM_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CNUM_REQ\n"));
                                    hfpHandleSubscriberNumberGetReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_BINP_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BINP_REQ\n"));
                                    success = hfpHandleGetVoiceTagReq(link);
                                break;
                                
                                case HFP_INTERNAL_AT_VTS_REQ:
                                    PRINT(("HFP_INTERNAL_AT_VTS_REQ\n"));
                                    hfpHandleDtmfRequest((HFP_INTERNAL_AT_VTS_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_COPS_REQ:
                                    PRINT(("HFP_INTERNAL_AT_COPS_REQ\n"));
                                    hfpHandleNetworkOperatorReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_CCWA_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CCWA_REQ\n"));
                                    success = hfpHandleCallWaitingNotificationEnable((HFP_INTERNAL_AT_CCWA_REQ_T*)message);
                                break;
                                
                                case HFP_INTERNAL_AT_CMD_REQ:
                                {
                                    HFP_INTERNAL_AT_CMD_REQ_T* req = (HFP_INTERNAL_AT_CMD_REQ_T*)message;
                                    PRINT(("HFP_INTERNAL_AT_CMD_REQ\n"));
                                    if(!req->size_cmd) break;
                                    hfpSendAtCmd(req->link, req->size_cmd, req->cmd, hfpAtCmdPending);
                                    success = TRUE;
                                }
                                break;
                                
                                case HFP_INTERNAL_CSR_SUPPORTED_FEATURES_REQ:
                                    PRINT(("HFP_INTERNAL_CSR_SUPPORTED_FEATURES_REQ\n"));
                                    hfpCsrFeaturesReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_CSR_BATTERY_LEVEL_REQ:
                                    PRINT(("HFP_INTERNAL_CSR_BATTERY_LEVEL_REQ\n"));
                                    hfpCsrFeaturesHandleBatteryLevelReq((HFP_INTERNAL_CSR_BATTERY_LEVEL_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_CSR_POWER_SOURCE_REQ:
                                    PRINT(("HFP_INTERNAL_CSR_POWER_SOURCE_REQ\n"));
                                    hfpCsrFeaturesHandlePowerSourceReq((HFP_INTERNAL_CSR_POWER_SOURCE_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_CSR_GET_SMS_REQ:
                                    PRINT(("HFP_INTERNAL_CSR_GET_SMS_REQ\n"));
                                    success = hfpHandleCsrGetSmsReq((HFP_INTERNAL_CSR_GET_SMS_REQ_T*)message);
                                break;
                                
                                case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND:
                                case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_1_IND:
                                    PRINT(("HFP_INTERNAL_WAIT_AT_TIMEOUT_IND\n"));
                                    hfpHandleWaitAtTimeout(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_SLC_DISCONNECT_REQ:
                                    PRINT(("HFP_INTERNAL_SLC_DISCONNECT_REQ\n"));
                                    hfpHandleDisconnectRequest(link);
                                    success = TRUE;
                                break;
                        
                                case HFP_INTERNAL_AUDIO_CONNECT_REQ:
                                    PRINT(("HFP_INTERNAL_AUDIO_CONNECT_REQ\n"));
                                    hfpHandleAudioConnectReq((HFP_INTERNAL_AUDIO_CONNECT_REQ_T*)message);
                                    success = TRUE;
                                break;
                        
                                case HFP_INTERNAL_AUDIO_CONNECT_RES:
                                    PRINT(("HFP_INTERNAL_AUDIO_CONNECT_RES\n"));
                                    hfpHandleAudioConnectRes((HFP_INTERNAL_AUDIO_CONNECT_RES_T*)message);
                                    success = TRUE;
                                break;
                        
                                case HFP_INTERNAL_AUDIO_TRANSFER_REQ:
                                    PRINT(("HFP_INTERNAL_AUDIO_TRANSFER_REQ\n"));
                                    hfpHandleAudioTransferReq((HFP_INTERNAL_AUDIO_TRANSFER_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AUDIO_DISCONNECT_REQ:
                                    PRINT(("HFP_INTERNAL_AUDIO_DISCONNECT_REQ\n"));
                                    hfpHandleAudioDisconnectReq(link);
                                    success = TRUE;
                                break;
                                
                                default:
                                break;
                            }
                        }
                        else if(hfpLinkIsHsp(link))
                        {
                            /* Messages valid for HSP in this state */
                            switch(id)
                            {
                                case HFP_INTERNAL_AT_ANSWER_REQ:
                                    PRINT(("HFP_INTERNAL_AT_ANSWER_REQ\n"));
                                    success = hfpHandleAnswerHspCall((HFP_INTERNAL_AT_ANSWER_REQ_T*)message);
                                break;
                                
                                case HFP_INTERNAL_AT_TERMINATE_REQ:
                                    PRINT(("HFP_INTERNAL_AT_TERMINATE_REQ\n"));
                                    success = hfpHandleTerminateHspCall(link);
                                break;
                                
                                case HFP_INTERNAL_AT_BVRA_REQ:
                                    PRINT(("HFP_INTERNAL_AT_BVRA_REQ\n"));
                                    success = hfpHandleHspVoiceRecognitionEnable((HFP_INTERNAL_AT_BVRA_REQ_T*) message);
                                break;
                                
                                case HFP_INTERNAL_AT_CMD_REQ:
                                {
                                    HFP_INTERNAL_AT_CMD_REQ_T* req = (HFP_INTERNAL_AT_CMD_REQ_T*)message;
                                    PRINT(("HFP_INTERNAL_AT_CMD_REQ\n"));
                                    hfpSendAtCmd(req->link, req->size_cmd, req->cmd, hfpAtCmdPending);
                                }
                                break;
                                
                                case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND:
                                case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_1_IND:
                                    PRINT(("HFP_INTERNAL_WAIT_AT_TIMEOUT_IND\n"));
                                    hfpHandleWaitAtTimeout(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_SLC_DISCONNECT_REQ:
                                    PRINT(("HFP_INTERNAL_SLC_DISCONNECT_REQ\n"));
                                    hfpHandleDisconnectRequest(link);
                                    success = TRUE;
                                break;
                        
                                case HFP_INTERNAL_AUDIO_CONNECT_REQ:
                                    PRINT(("HFP_INTERNAL_AUDIO_CONNECT_REQ\n"));
                                    hfpSendHsButtonPress(link, hfpCmdPending);
                                    success = TRUE;
                                break;
                        
                                case HFP_INTERNAL_AUDIO_CONNECT_RES:
                                    PRINT(("HFP_INTERNAL_AUDIO_CONNECT_RES\n"));
                                    hfpHandleAudioConnectRes((HFP_INTERNAL_AUDIO_CONNECT_RES_T*)message);
                                    success = TRUE;
                                break;
                        
                                case HFP_INTERNAL_AUDIO_TRANSFER_REQ:
                                    PRINT(("HFP_INTERNAL_AUDIO_TRANSFER_REQ\n"));
                                    hfpHandleAudioTransferReq((HFP_INTERNAL_AUDIO_TRANSFER_REQ_T*)message);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AUDIO_DISCONNECT_REQ:
                                    PRINT(("HFP_INTERNAL_AUDIO_DISCONNECT_REQ\n"));
                                    hfpHandleAudioDisconnectReq(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_0_IND:
                                case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_1_IND:
                                    PRINT(("HFP_INTERNAL_HS_INCOMING_TIMEOUT_IND\n"));
                                    hfpHandleCallIncomingTimeout(link);
                                    success = TRUE;
                                break;
                                
                                case HFP_INTERNAL_AT_CKPD_REQ:
                                    PRINT(("HFP_INTERNAL_AT_CKPD_REQ\n"));
                                    hfpSendHsButtonPress(link, hfpCkpdCmdPending);
                                    success = TRUE;
                                break;
                                
                                default:
                                break;
                            }
                        }
                    break;
                    
                    /* 
                       No internal messages valid in these states 
                    */
                    case hfp_slc_idle:
                    case hfp_slc_disabled:
                    default:
                    break;
                }
            }
            
            if(!success)
            {
                MessageId cfm_id = HFP_NO_CFM;
                
                PRINT(("Link %X, SLC state %X\n", (uint16)link, link ? link->ag_slc_state : 0));
                
                /* Either the link is NULL or link state was invalid. */
                switch (id)
                {
                    case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_0_IND:
                    case HFP_RFCOMM_LINK_LOSS_RECONNECT_LINK_1_IND:
                        PRINT(("HFP_RFCOMM_LINK_LOSS_RECONNECT\n"));
                        goto hfp_prim_error;
                    break;
                    
                    case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_0_IND:
                    case HFP_RFCOMM_LINK_LOSS_TIMEOUT_LINK_1_IND:
                        PRINT(("HFP_RFCOMM_LINK_LOSS_TIMEOUT\n"));
                        goto hfp_prim_error;
                    break;

                    case HFP_INTERNAL_AT_BAC_REQ:
                        PRINT(("HFP_INTERNAL_AT_BAC_REQ\n"));
                        /* Ignore this silently */
                    break;
                    
                    case HFP_INTERNAL_AT_BTRH_STATUS_REQ:
                        PRINT(("HFP_INTERNAL_AT_BTRH_STATUS_REQ\n"));
                        /* Internal request failed, ignore */
                    break;
                    
                    case HFP_INTERNAL_AT_CLIP_REQ:
                        PRINT(("HFP_INTERNAL_AT_CLIP_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_CALLER_ID_ENABLE_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_ANSWER_REQ:
                        PRINT(("HFP_INTERNAL_AT_ANSWER_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_CALL_ANSWER_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_TERMINATE_REQ:
                        PRINT(("HFP_INTERNAL_AT_TERMINATE_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = hfpHandleChupAtAck(link);
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_BLDN_REQ:
                        PRINT(("HFP_INTERNAL_AT_BLDN_REQ"));
                        cfm_id = HFP_DIAL_LAST_NUMBER_CFM;
                    break;
                    
                    case HFP_INTERNAL_AT_ATD_NUMBER_REQ:
                        PRINT(("HFP_INTERNAL_AT_ATD_NUMBER_REQ"));
                        cfm_id = HFP_DIAL_NUMBER_CFM;
                    break;
                    
                    case HFP_INTERNAL_AT_ATD_MEMORY_REQ:
                        PRINT(("HFP_INTERNAL_AT_ATD_MEMORY_REQ"));
                        cfm_id = HFP_DIAL_MEMORY_CFM;
                    break;
                    
                    case HFP_INTERNAL_AT_BVRA_REQ:
                        PRINT(("HFP_INTERNAL_AT_BVRA_REQ\n"));
                        cfm_id = HFP_VOICE_RECOGNITION_ENABLE_CFM;
                    break;
                    
                    case HFP_INTERNAL_AT_NREC_REQ:
                        PRINT(("HFP_INTERNAL_AT_NREC_REQ\n"));
                        /* Internal request failed, ignore */
                    break;
                    
                    case HFP_INTERNAL_AT_CLCC_REQ:
                        PRINT(("HFP_INTERNAL_AT_CLCC_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_CURRENT_CALLS_CFM;
#endif
                    break;
                            
                    case HFP_INTERNAL_AT_CHLD_REQ:
                        PRINT(("HFP_INTERNAL_AT_CHLD_REQ\n"));
                        hfpHandleChldAtAck(link, ((HFP_INTERNAL_AT_CHLD_REQ_T*)message)->action, hfp_fail);
                    break;
                    
                    case HFP_INTERNAL_AT_BTRH_REQ:
                        PRINT(("HFP_INTERNAL_AT_BTRH_REQ\n"));
#ifndef HFP_MIN_CFM
                        hfpHandleBtrhAtAck(link, ((HFP_INTERNAL_AT_BTRH_REQ_T*)message)->action, hfp_fail);
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_BIA_REQ:
                        PRINT(("HFP_INTERNAL_AT_BIA_REQ\n"));
                        /* Internal request failed, ignore */
                    break;
                    
                    case HFP_INTERNAL_AT_CMEE_REQ:
                        PRINT(("HFP_INTERNAL_AT_CMEE_REQ\n"));
                        /* Internal request failed, ignore */
                    break;
                    
                    case HFP_INTERNAL_AT_CNUM_REQ:
                        PRINT(("HFP_INTERNAL_AT_CNUM_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_SUBSCRIBER_NUMBERS_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_BINP_REQ:
                        PRINT(("HFP_INTERNAL_AT_BINP_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_VOICE_TAG_NUMBER_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_VTS_REQ:
                        PRINT(("HFP_INTERNAL_AT_VTS_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_DTMF_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_COPS_REQ:
                        PRINT(("HFP_INTERNAL_AT_COPS_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_NETWORK_OPERATOR_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_CCWA_REQ:
                        PRINT(("HFP_INTERNAL_AT_CCWA_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_CALL_WAITING_ENABLE_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_AT_CMD_REQ:
                        PRINT(("HFP_INTERNAL_AT_CMD_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_AT_CMD_CFM;
#endif
                    break;
                    
                    case HFP_INTERNAL_CSR_SUPPORTED_FEATURES_REQ:
                        PRINT(("HFP_INTERNAL_CSR_SUPPORTED_FEATURES_REQ\n"));
                        hfpCsrFeaturesHandleCsrSfAtAck(link, hfp_fail);
                    break;
                    
                    case HFP_INTERNAL_CSR_BATTERY_LEVEL_REQ:
                        PRINT(("HFP_INTERNAL_CSR_BATTERY_LEVEL_REQ\n"));
                        /* No notification for app so ignore this */
                    break;
                    
                    case HFP_INTERNAL_CSR_POWER_SOURCE_REQ:
                        PRINT(("HFP_INTERNAL_CSR_POWER_SOURCE_REQ\n"));
                        /* No notification for app so ignore this */
                    break;
                    
                    case HFP_INTERNAL_CSR_GET_SMS_REQ:
                        PRINT(("HFP_INTERNAL_CSR_GET_SMS_REQ\n"));
                        hfpCsrFeaturesHandleGetSmsAtAck(link, hfp_fail);
                    break;
                    
                    case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND:
                    case HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_1_IND:
                        PRINT(("HFP_INTERNAL_WAIT_AT_TIMEOUT_IND\n"));
                        /* Timeout on a link we don't recognise */
                        goto hfp_prim_error;
                    break;
                    
                    case HFP_INTERNAL_SLC_DISCONNECT_REQ:
                        PRINT(("HFP_INTERNAL_SLC_DISCONNECT_REQ\n"));
                        /* Disconnect request on invalid link/link with no SLC */
                        hfpSendSlcDisconnectIndToApp(link, hfp_disconnect_no_slc);
                    break;
                    
                    case HFP_INTERNAL_AUDIO_CONNECT_REQ:
                        PRINT(("HFP_INTERNAL_AUDIO_CONNECT_REQ\n"));
                        sendAudioConnectCfmFailToApp(link, hfp_audio_connect_error);
                    break;
                    
                    case HFP_INTERNAL_AUDIO_CONNECT_RES:
                        PRINT(("HFP_INTERNAL_AUDIO_CONNECT_RES\n"));
                        sendAudioConnectCfmFailToApp(link, hfp_audio_connect_error);
                    break;
                    
                    case HFP_INTERNAL_AUDIO_DISCONNECT_REQ:
                        PRINT(("HFP_INTERNAL_AUDIO_DISCONNECT_REQ\n"));
                        sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_error);
                    break;
                    
                    case HFP_INTERNAL_AUDIO_TRANSFER_REQ:
                        PRINT(("HFP_INTERNAL_AUDIO_TRANSFER_REQ\n"));
                        /* What fail message we send depends on the direction requested */
                        switch(((HFP_INTERNAL_AUDIO_TRANSFER_REQ_T*)message)->direction)
                        {
                            case hfp_audio_to_hfp:
                                sendAudioConnectCfmFailToApp(link, hfp_audio_connect_error);
                                break;

                            case hfp_audio_to_ag:
                                sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_error);
                            break;

                            case hfp_audio_transfer:
                                if (link && link->audio_sink)
                                    sendAudioDisconnectIndToApp(link, hfp_audio_disconnect_error);
                                else
                                    sendAudioConnectCfmFailToApp(link, hfp_audio_connect_error);
                            break;
                        }
                    break;
                    
                    case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_0_IND:
                    case HFP_INTERNAL_HS_INCOMING_TIMEOUT_LINK_1_IND:
                        PRINT(("HFP_INTERNAL_HS_INCOMING_TIMEOUT_IND\n"));
                        /* SLC has closed before the incoming timeout fired */
                        goto hfp_prim_error;
                    break;
                    
                    case HFP_INTERNAL_AT_CKPD_REQ:
                        PRINT(("HFP_INTERNAL_AT_CKPD_REQ\n"));
#ifndef HFP_MIN_CFM
                        cfm_id = HFP_HS_BUTTON_PRESS_CFM;
#endif
                    break;
                    
                    default:
                        /* Panic in debug and ignore in release lib variants */  
                        goto hfp_prim_error;
                    break;
                }
                
                /* Send _CFM message to app if necessary */
                if(cfm_id) hfpSendCommonCfmMessageToApp(cfm_id, link, hfp_fail);
            }
        }
        else if(id >= CL_MESSAGE_BASE && id < CL_MESSAGE_TOP)
        {
            switch(id)
            {
                case CL_RFCOMM_REGISTER_CFM:
                    PRINT(("CL_RFCOMM_REGISTER_CFM\n"));
                    goto cl_prim_error;
                break;

                case CL_RFCOMM_CONNECT_IND:
                    PRINT(("CL_RFCOMM_CONNECT_IND\n"));
                    /* Handle the connect cfm */
                    hfpHandleRfcommConnectInd((CL_RFCOMM_CONNECT_IND_T *) message);
                break;
                
                case CL_RFCOMM_CLIENT_CONNECT_CFM:
                    PRINT(("CL_RFCOMM_CLIENT_CONNECT_CFM\n"));
                    hfpHandleRfcommClientConnectCfm((CL_RFCOMM_CLIENT_CONNECT_CFM_T *) message);
                break;
                
                case CL_RFCOMM_SERVER_CONNECT_CFM:
                    PRINT(("CL_RFCOMM_SERVER_CONNECT_CFM\n"));
                    hfpHandleRfcommServerConnectCfm((CL_RFCOMM_SERVER_CONNECT_CFM_T *) message);
                break;
                
                case CL_RFCOMM_DISCONNECT_IND:
                    PRINT(("CL_RFCOMM_DISCONNECT_IND\n"));
                    hfpHandleRfcommDisconnectInd((CL_RFCOMM_DISCONNECT_IND_T *) message);
                break;
                
                case CL_RFCOMM_DISCONNECT_CFM:
                    PRINT(("CL_RFCOMM_DISCONNECT_CFM\n"));
                    hfpHandleRfcommDisconnectCfm((CL_RFCOMM_DISCONNECT_CFM_T *) message);
                break;

                case CL_SDP_REGISTER_CFM:
                    PRINT(("CL_SDP_REGISTER_CFM\n"));
                    hfpHandleSdpRegisterCfm((CL_SDP_REGISTER_CFM_T *) message);
                break;

                case CL_SDP_UNREGISTER_CFM:
                    PRINT(("CL_SDP_UNREGISTER_CFM\n"));
                    handleSdpUnregisterCfm((CL_SDP_UNREGISTER_CFM_T *) message);
                break;

                case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM:
                    PRINT(("CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM\n"));
                    /* Currently we only look for attributes during SLC establishment and connection */
                    hfpHandleServiceSearchAttributeCfm((CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *) message);
                break;

                case CL_DM_SYNC_CONNECT_IND:
                    PRINT(("CL_DM_SYNC_CONNECT_IND\n"));
                    hfpHandleSyncConnectInd((CL_DM_SYNC_CONNECT_IND_T*)message);
                break;

                case CL_DM_SYNC_CONNECT_CFM:
                    PRINT(("CL_DM_SYNC_CONNECT_CFM\n"));
                    hfpHandleSyncConnectCfm((CL_DM_SYNC_CONNECT_CFM_T*)message);
                break;
                
                case CL_DM_SYNC_DISCONNECT_IND:
                    PRINT(("CL_DM_SYNC_DISCONNECT_IND\n"));
                    hfpHandleSyncDisconnectInd((CL_DM_SYNC_DISCONNECT_IND_T*)message);
                break;

                case CL_RFCOMM_PORTNEG_IND:
                {
                    PRINT(("CL_RFCOMM_PORTNEG_IND\n"));
                    hfpHandleRfcommPortnegInd((CL_RFCOMM_PORTNEG_IND_T*)message);
                }
                break;
                
                case CL_RFCOMM_PORTNEG_CFM:
                case CL_RFCOMM_CONTROL_IND:
                case CL_RFCOMM_CONTROL_CFM:
                case CL_RFCOMM_LINE_STATUS_IND:
                case CL_DM_ROLE_CFM:
                case CL_DM_SYNC_REGISTER_CFM:
                case CL_SM_ENCRYPTION_CHANGE_IND:
                case CL_SM_ENCRYPTION_KEY_REFRESH_IND:
                    /* Silently ignore these */
                break;
                
                default:
                    /* Panic in debug and ignore in release lib variants */  
                    goto cl_prim_error;
                break;
            }
        }
        else
        {
            switch(id)
            {
                case MESSAGE_MORE_DATA:
                {
                    PRINT(("MESSAGE_MORE_DATA"));
                    /* We have received more data into the RFCOMM buffer */
                    hfpHandleReceivedData(((MessageMoreData *) message)->source);
                    PRINT(("\n"));
                }
                break;
                
                case MESSAGE_MORE_SPACE:
                case MESSAGE_SOURCE_EMPTY:
                case MESSAGE_STREAM_DISCONNECT:
                    /* Silently ignore these */
                    break;
                
                default:
                    /* Panic in debug and ignore in release lib variants */    
                    goto sys_prim_error;
                break;
            }
        }
    }
    return;
    
    sys_prim_error:
    handleUnexpected(hfpUnexpectedMessage, id);
    return;
    
    cl_prim_error:
    handleUnexpected(hfpUnexpectedClPrim, id);
    return;

    hfp_prim_error:
    handleUnexpected(hfpUnexpectedHfpPrim, id);
    return;

}

/*lint +e525 +e725 +e830 */
