/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    profile_handler.c        

DESCRIPTION
   This file implements the profile state machine and the task handler function.

NOTES

*/


/****************************************************************************
    Header files
*/
#include <stdlib.h>
#include <connection.h>
#include "avrcp_caps_handler.h"
#include "avrcp_connect_handler.h"
#include "avrcp_continuation_handler.h"
#include "avrcp_element_attributes_handler.h"
#include "avrcp_player_app_settings_handler.h"
#include "avrcp_l2cap_handler.h"
#include "avrcp_metadata_transfer.h"
#include "avrcp_notification_handler.h"
#include "avrcp_signal_passthrough.h"
#include "avrcp_signal_unit_info.h"
#include "avrcp_signal_vendor.h"
#include "avrcp_absolute_volume.h"
#include "avrcp_profile_handler.h"
#include "avrcp_browsing_handler.h"


/****************************************************************************
 *NAME    
 *    avrcpHandleReadyMessages    
 *
 *DESCRIPTION
 *  Profile state machine to handle Messages in the Ready state. 
 *
 *PARAMETERS
 *  avrcp       - AVRCP Instance
 *  MessageId   - Message ID.
 *  message     - Message.
 ****************************************************************************/
static bool avrcpHandleReadyMessages(AVRCP *avrcp, 
                                     MessageId id, 
                                     Message   message)
{
    switch(id)
    {
        case AVRCP_INTERNAL_SDP_SEARCH_REQ:
            avrcpSdpSearchRequest(avrcp,
                    &((AVRCP_INTERNAL_SDP_SEARCH_REQ_T*)message)->bd_addr,
                    avrcp_sdp_search_and_connect_pending);

            break;
        case AVRCP_INTERNAL_CONNECT_REQ:
            avrcpHandleInternalConnectReq(avrcp, 
                                   (AVRCP_INTERNAL_CONNECT_REQ_T *) message);
            break;

        default:
            return FALSE;  
    }

    return TRUE;
}

/****************************************************************************
 *NAME    
 *    avrcpHandleConnectingMessages    
 *
 *DESCRIPTION
 *  Profile state machine to handle Messages in the Connecting state. 
 *
 *PARAMETERS
 *  avrcp       - AVRCP Instance
 *  MessageId   - Message ID.
 *  message     - Message.
 ****************************************************************************/
static bool avrcpHandleConnectingMessages(AVRCP *avrcp, 
                                         MessageId id, 
                                         Message   message)
{
    switch(id)
    {
       case AVRCP_INTERNAL_CONNECT_RES:
             avrcpHandleInternalL2capConnectRes(avrcp, 
                             (AVRCP_INTERNAL_CONNECT_RES_T *) message);
             break;

       case  CL_L2CAP_CONNECT_CFM:
            avrcpHandleL2capConnectCfm(avrcp, 
                       (CL_L2CAP_CONNECT_CFM_T *) message);
            break;

       case CL_L2CAP_DISCONNECT_CFM:
            avrcpHandleL2capDisconnectCfm(avrcp,
                    (CL_L2CAP_DISCONNECT_CFM_T *) message);
            break;
            
        case CL_L2CAP_DISCONNECT_IND:
            avrcpHandleL2capDisconnectInd(avrcp, 
                          (CL_L2CAP_DISCONNECT_IND_T *) message);
              break;

        default:
            return FALSE;  
    }

    return TRUE;
}

/****************************************************************************
 *NAME    
 *    avrcpHandleConnectedMessages    
 *
 *DESCRIPTION
 *  Profile state machine to handle Messages in the Connected state. 
 *
 *PARAMETERS
 *  avrcp       - AVRCP Instance
 *  MessageId   - Message ID.
 *  message     - Message.
 ****************************************************************************/
static bool avrcpHandleConnectedMessages(AVRCP *avrcp, 
                                         MessageId id, 
                                         Message   message)
{
    switch(id)
    {

        case AVRCP_INTERNAL_DISCONNECT_REQ:
            avrcpHandleInternalDisconnectReq(avrcp);
            break;

        case AVRCP_INTERNAL_GET_FEATURES:
            avrcpGetSupportedFeatures(avrcp);
            break;

        case AVRCP_INTERNAL_GET_EXTENSIONS:
            avrcpGetProfileVersion(avrcp);
            break;

    #ifndef AVRCP_TG_ONLY_LIB /* Disable CT for TG only lib */
        case AVRCP_INTERNAL_PASSTHROUGH_REQ:
            avrcpHandleInternalPassThroughReq(avrcp, 
                           (AVRCP_INTERNAL_PASSTHROUGH_REQ_T *) message);
            break;

        case AVRCP_INTERNAL_UNITINFO_REQ:
            avrcpHandleInternalUnitInfoReq(avrcp);
            break;

        case AVRCP_INTERNAL_SUBUNITINFO_REQ:
            avrcpHandleInternalSubUnitInfoReq(avrcp, 
                                (AVRCP_INTERNAL_SUBUNITINFO_REQ_T *) message);
            break;

        case AVRCP_INTERNAL_VENDORDEPENDENT_REQ:
            avrcpHandleInternalVendorDependentReq(avrcp, 
                              (AVRCP_INTERNAL_VENDORDEPENDENT_REQ_T *) message);
            break;

    #endif /* !AVRCP_TG_ONLY_LIB */

    #ifndef AVRCP_CT_ONLY_LIB /* Disable TG for CT only lib */

        case AVRCP_INTERNAL_PASSTHROUGH_RES:
            avrcpHandleInternalPassThroughRes(avrcp, 
                           (AVRCP_INTERNAL_PASSTHROUGH_RES_T *) message);
            break;


        case AVRCP_INTERNAL_UNITINFO_RES:
            avrcpHandleInternalUnitInfoRes( avrcp, 
                               (AVRCP_INTERNAL_UNITINFO_RES_T *) message);
            break;


        case AVRCP_INTERNAL_SUBUNITINFO_RES:
            avrcpHandleInternalSubUnitInfoRes(avrcp, 
                               (AVRCP_INTERNAL_SUBUNITINFO_RES_T *) message);
            break;


        case AVRCP_INTERNAL_VENDORDEPENDENT_RES:
            avrcpHandleInternalVendorDependentRes(avrcp, 
                              (AVRCP_INTERNAL_VENDORDEPENDENT_RES_T *) message);
            break;

       case AVRCP_INTERNAL_SEND_RESPONSE_TIMEOUT:
            avrcpHandleInternalSendResponseTimeout(avrcp,
                          (AVRCP_INTERNAL_SEND_RESPONSE_TIMEOUT_T *) message);
            break;

        case AVRCP_INTERNAL_GET_CAPS_RES:
            avrcpHandleInternalGetCapsResponse(avrcp, 
                               (AVRCP_INTERNAL_GET_CAPS_RES_T *) message);
            break;

        case AVRCP_INTERNAL_LIST_APP_ATTRIBUTE_RES:
            avrcpHandleInternalListAppAttributesResponse(avrcp, 
                           (AVRCP_INTERNAL_LIST_APP_ATTRIBUTE_RES_T *) message);
            break;

        case AVRCP_INTERNAL_LIST_APP_VALUE_RES:
            avrcpHandleInternalListAppValuesResponse(avrcp, 
                            (AVRCP_INTERNAL_LIST_APP_VALUE_RES_T *) message);
            break;

        case AVRCP_INTERNAL_GET_APP_VALUE_RES:
            avrcpHandleInternalGetAppValueResponse(avrcp, 
                            (AVRCP_INTERNAL_GET_APP_VALUE_RES_T *) message);
            break;

        case AVRCP_INTERNAL_SET_APP_VALUE_RES:
            avrcpHandleInternalSetAppValueResponse(avrcp, 
                             (AVRCP_INTERNAL_SET_APP_VALUE_RES_T *) message);
            break;

        case AVRCP_INTERNAL_GET_APP_ATTRIBUTES_TEXT_RES:
            avrcpHandleInternalGetAppAttributeTextResponse(avrcp, 
                     (AVRCP_INTERNAL_GET_APP_ATTRIBUTES_TEXT_RES_T *) message);
            break;

        case AVRCP_INTERNAL_GET_APP_VALUE_TEXT_RES:
            avrcpHandleInternalGetAppValueTextResponse(avrcp, 
                     (AVRCP_INTERNAL_GET_APP_VALUE_TEXT_RES_T *) message);
            break;

        case AVRCP_INTERNAL_GET_ELEMENT_ATTRIBUTES_RES:
            avrcpHandleInternalGetElementAttributesResponse(avrcp, 
                       (AVRCP_INTERNAL_GET_ELEMENT_ATTRIBUTES_RES_T *) message);
            break;

        case AVRCP_INTERNAL_GET_PLAY_STATUS_RES:
            avrcpHandleInternalGetPlayStatusResponse(avrcp, 
                      (AVRCP_INTERNAL_GET_PLAY_STATUS_RES_T *) message);
            break;

        case AVRCP_INTERNAL_EVENT_PLAYBACK_STATUS_CHANGED_RES:
            avrcpHandleInternalEventPlaybackStatusChangedResponse(avrcp, 
                 (AVRCP_INTERNAL_EVENT_PLAYBACK_STATUS_CHANGED_RES_T*)message);
            break;

        case AVRCP_INTERNAL_EVENT_TRACK_CHANGED_RES:
            avrcpHandleInternalEventTrackChangedResponse(avrcp, 
                       (AVRCP_INTERNAL_EVENT_TRACK_CHANGED_RES_T *) message);
            break;

        case AVRCP_INTERNAL_EVENT_PLAYBACK_POS_CHANGED_RES:
            avrcpHandleInternalEventPlaybackPosChangedResponse(avrcp, 
                     (AVRCP_INTERNAL_EVENT_PLAYBACK_POS_CHANGED_RES_T*)message);
            break;

        case AVRCP_INTERNAL_EVENT_BATT_STATUS_CHANGED_RES:
            avrcpHandleInternalEventBattStatusChangedResponse(avrcp, 
                     (AVRCP_INTERNAL_EVENT_BATT_STATUS_CHANGED_RES_T*) message);
            break;

        case AVRCP_INTERNAL_EVENT_SYSTEM_STATUS_CHANGED_RES:
            avrcpHandleInternalEventSystemStatusChangedResponse(avrcp, 
                  (AVRCP_INTERNAL_EVENT_SYSTEM_STATUS_CHANGED_RES_T*) message);
            break;

       case AVRCP_INTERNAL_EVENT_PLAYER_APP_SETTING_CHANGED_RES:
           avrcpHandleInternalEventPlayerAppSettingChangedResponse(avrcp, 
              (AVRCP_INTERNAL_EVENT_PLAYER_APP_SETTING_CHANGED_RES_T*) message);
            break;

       case AVRCP_INTERNAL_REJECT_METADATA_RES:
           avrcpHandleInternalRejectMetadataResponse(avrcp, 
                    ((AVRCP_INTERNAL_REJECT_METADATA_RES_T*)message)->response,
                    ((AVRCP_INTERNAL_REJECT_METADATA_RES_T*)message)->pdu_id);
           break;   

       case AVRCP_INTERNAL_ABORT_CONTINUING_RES:
           avrcpHandleInternalAbortContinuingResponse(avrcp, 
                        (AVRCP_INTERNAL_ABORT_CONTINUING_RES_T *) message);
           break;

       case AVRCP_INTERNAL_NEXT_CONTINUATION_PACKET:
           avrcpHandleNextContinuationPacket(avrcp, 
                      (AVRCP_INTERNAL_NEXT_CONTINUATION_PACKET_T *) message);
           break;

        case AVRCP_INTERNAL_GROUP_RES:
           avrcpHandleInternalGroupResponse(avrcp, 
                        (AVRCP_INTERNAL_GROUP_RES_T *) message);
           break;   

        case AVRCP_INTERNAL_COMMON_METADATA_CONTROL_RES:
            avrcpHandleCommonMetadataControlResponse(avrcp, 
                    (AVRCP_INTERNAL_COMMON_METADATA_CONTROL_RES_T*) message);
            break;

        case AVRCP_INTERNAL_SET_ABSOLUTE_VOL_RES:
            avrcpHandleInternalAbsoluteVolumeRsp(avrcp,
                              (AVRCP_INTERNAL_SET_ABSOLUTE_VOL_RES_T*) message);
            break; 
   
        case AVRCP_INTERNAL_EVENT_VOLUME_CHANGED_RES:
            avrcpHandleInternalAbsoluteVolumeEvent(avrcp,
                     (AVRCP_INTERNAL_EVENT_VOLUME_CHANGED_RES_T*) message);
            break; 

        case AVRCP_INTERNAL_EVENT_ADDRESSED_PLAYER_CHANGED_RES:
            avrcpHandleInternalAddressPlayerChangedEvent(avrcp,
                (AVRCP_INTERNAL_EVENT_ADDRESSED_PLAYER_CHANGED_RES_T*)message);
            break;

        case AVRCP_INTERNAL_EVENT_UIDS_CHANGED_RES:
            avrcpHandleInternalEventUidsChangedEvent(avrcp,
                (AVRCP_INTERNAL_EVENT_UIDS_CHANGED_RES_T*)message);
            break;

        case AVRCP_INTERNAL_EVENT_COMMON_RES:
            avrcpHandleInternalCommonEventResponse(avrcp,
                (AVRCP_INTERNAL_EVENT_COMMON_RES_T*) message);
            break;
    #endif /* !AVRCP_CT_ONLY_LIB*/

       case AVRCP_INTERNAL_MESSAGE_MORE_DATA:
       case MESSAGE_MORE_DATA: /* Fall Through */
            avrcpHandleReceivedData(avrcp);        
            break;
   
        case CL_L2CAP_DISCONNECT_IND:
            avrcpHandleL2capDisconnectInd(avrcp, 
                          (CL_L2CAP_DISCONNECT_IND_T *) message);
              break;

        default:
            return FALSE;  
    }

    return TRUE;
}

/****************************************************************************
 *NAME    
 *    avrcpHandleUnhandledMessages    
 *
 *DESCRIPTION
 *  Profile state machine to handle Messages Unhandled messages.
 *
 *PARAMETERS
 *  avrcp       - AVRCP Instance
 *  MessageId   - Message ID.
 *  message     - Message.
 ****************************************************************************/
static void avrcpHandleUnhandledMessages(AVRCP *avrcp, 
                                         MessageId id, 
                                         Message   message)
{
    switch(id)
    {
        case AVRCP_INTERNAL_TASK_DELETE_REQ:
            avrcpHandleDeleteTask(avrcp);
            break;

        case AVRCP_INTERNAL_CONNECT_REQ:
            avrcpSendConnectCfmToApp( avrcp,avrcp_bad_state, 
                  &((AVRCP_INTERNAL_CONNECT_REQ_T *)message)->bd_addr,
                  0 );
            break;

        case AVRCP_INTERNAL_DISCONNECT_REQ:
            avrcpSendCommonCfmMessageToApp( AVRCP_DISCONNECT_IND, 
                                    avrcp_device_not_connected, 0, avrcp);
            break;


    #ifndef AVRCP_TG_ONLY_LIB /* Disable CT for TG only lib */
        case AVRCP_INTERNAL_PASSTHROUGH_REQ:
            avrcpSendCommonCfmMessageToApp(AVRCP_PASSTHROUGH_CFM, 
                                    avrcp_device_not_connected, 0, avrcp);
            break;

        case AVRCP_INTERNAL_UNITINFO_REQ:
            avrcpSendUnitInfoCfmToClient(avrcp, 
                                 avrcp_device_not_connected, 0, 0, (uint32) 0);
            break;

        case AVRCP_INTERNAL_SUBUNITINFO_REQ:
           avrcpSendSubunitInfoCfmToClient(avrcp,
                                          avrcp_device_not_connected, 0, 0); 
           
            break;      

        case AVRCP_INTERNAL_VENDORDEPENDENT_REQ:
           avrcpSendCommonCfmMessageToApp(AVRCP_VENDORDEPENDENT_CFM, 
                                 avrcp_device_not_connected, 0, avrcp);
            break;


        case AVRCP_INTERNAL_WATCHDOG_TIMEOUT:
            avrcpHandleInternalWatchdogTimeout(avrcp);
            break;

    #endif /* !AVRCP_TG_ONLY_LIB */

       case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM:
             avrcpHandleServiceSearchAttributeCfm(avrcp, 
                        (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *) message);
             break;

        case CL_L2CAP_CONNECT_IND:
            avrcpHandleL2capConnectIndReject( &avrcp->task,
                                       (CL_L2CAP_CONNECT_IND_T *) message);
            break;

       case CL_L2CAP_CONNECT_CFM:               /* Fall Through */
       case CL_L2CAP_TIMEOUT_IND:               /* Fall Through */
       case AVRCP_INTERNAL_MESSAGE_MORE_DATA:   /* Fall Through */
       case MESSAGE_MORE_DATA:                  /* Fall Through */
       case MESSAGE_MORE_SPACE:                 /* Fall Through */
       case MESSAGE_SOURCE_EMPTY:               /* Fall Through */
       case MESSAGE_STREAM_DISCONNECT:          /* Fall Through */
                /* ignore */
                break;

        default:
            if(id > AVRCP_MSG_BASE  && id < AVRCP_MSG_BOTTOM)
            {
                /* Ignore these messages. 
                   It may happen due to cross over of messages */
                AVRCP_INFO(("Ignoring the Message(%d) in wrong state (%d)",
                         id, avrcp->state));
            }
            else
            {
                AVRCP_DEBUG((" AVRCP handleUnexpected- State 0x%x MsgId 0x%x\n",
                      avrcp->state, id ));

            }
            break;
    }

    return;
}


/**************************************************************************
 *NAME    
 *    avrcpInitHandler
 *
 *DESCRIPTION
 *  Profile Task handler function to handle initialization messages
 *
 *PARAMETERS
 *  Task        - Task.
 *  MessageId   - Message ID.
 *  message     - Message.
 **************************************************************************/
void avrcpInitHandler(Task task, MessageId id, Message message)
{
    switch(id)
    {
       case AVRCP_INTERNAL_INIT_REQ:
            avrcpHandleInternalInitReq((AVRCP_INTERNAL_INIT_REQ_T*) message);
            break;

       case CL_L2CAP_REGISTER_CFM:
            avrcpHandleL2capRegisterCfm((CL_L2CAP_REGISTER_CFM_T *) message); 
            break;

       case CL_SDP_REGISTER_CFM:
            avrcpHandleSdpRegisterCfm((CL_SDP_REGISTER_CFM_T *) message);
            break;    

       case CL_L2CAP_CONNECT_IND:
            avrcpHandleL2capConnectInd((CL_L2CAP_CONNECT_IND_T *) message);
            break;

        case CL_L2CAP_UNREGISTER_CFM:
        default:
            /* ignore */
            break;
    }

}


/****************************************************************************
 *NAME    
 *    avrcpProfileHandler    
 *
 *DESCRIPTION
 *  Profile Task handler function ti handle all messages to AVRCP Task.
 *
 *PARAMETERS
 *  Task        - Task.
 *  MessageId   - Message ID.
 *  message     - Message.
 ****************************************************************************/
void avrcpProfileHandler(Task task, MessageId id, Message message)
{
    AVRCP *avrcp = (AVRCP *) task;
    avrcpState profileState = avrcp->state;
    bool consumed=TRUE;

    if (profileState == avrcpReady)
    {
        consumed = avrcpHandleReadyMessages(avrcp, id, message);
    }
    else if (profileState == avrcpConnecting)
    {
        consumed = avrcpHandleConnectingMessages(avrcp, id, message);
    }
    else
    {
        consumed = avrcpHandleConnectedMessages(avrcp, id, message);
    }

    if(!consumed)
    {
        avrcpHandleUnhandledMessages(avrcp, id, message);
    }

}
/****************************************************************************
*NAME    
*    avrcpDataCleanUp
*
*DESCRIPTION
*    Source handler function to free the allocated data. 
******************************************************************************/
void avrcpDataCleanUp(Task task, MessageId id, Message message)
{
    AvrcpCleanUpTask *cleanTask = (AvrcpCleanUpTask *) task;

    switch (id)
    {
    case MESSAGE_SOURCE_EMPTY:
        {
            /* Free the previously stored data ptr. */
            if (cleanTask->sent_data)
            {
                free(cleanTask->sent_data);
                AVRCP_INFO(("avrcpDataCleanUp: Cleanup Stored Data"));
            }
            cleanTask->sent_data = 0;
        }
        break;

    default:
        AVRCP_DEBUG((" AVRCP handleUnexpected in "
                   " avrcpDataCleanUp- MsgId 0x%x\n",id));
        break;
    }
}

/****************************************************************************
*NAME    
*    avbpProfileHandler
*
*DESCRIPTION
*    profileHandler function for Browsing channel 
******************************************************************************/
void avbpProfileHandler(Task task, MessageId id, Message message)
{
    AVBP *avbp = (AVBP *) task;

    /* Handle irrespective of state. Trust the connection library will not 
       send these messages  at wrong time.  Check the state only for the
       messages triggered by the peer device. */
    switch(id)
    {
        case AVRCP_INTERNAL_CONNECT_REQ:
            avrcpHandleInternalBrowseConnectReq(avbp, 
                                   (AVRCP_INTERNAL_CONNECT_REQ_T *) message);
            break;

        case AVRCP_INTERNAL_CONNECT_RES:
             avrcpHandleInternalBrowseConnectRes(avbp, 
                             (AVRCP_INTERNAL_CONNECT_RES_T *) message);
             break;     

        case AVRCP_INTERNAL_DISCONNECT_REQ:
            avrcpHandleInternalBrowseDisconnectReq(avbp, 1);
            break;

        case CL_L2CAP_CONNECT_IND:
            avrcpHandleL2capConnectIndReject(task,
                                       (CL_L2CAP_CONNECT_IND_T *) message);
            break;

        case CL_L2CAP_CONNECT_CFM:
            avrcpHandleAvbpConnectCfm(avbp, (CL_L2CAP_CONNECT_CFM_T*)message);
            break;

       case CL_L2CAP_DISCONNECT_IND:
            avrcpHandleBrowseDisconnectInd(avbp, 
                          (CL_L2CAP_DISCONNECT_IND_T *) message);
              break;

        case CL_L2CAP_DISCONNECT_CFM:
            avrcpHandleBrowseDisconnectCfm(avbp, 
                          (CL_L2CAP_DISCONNECT_CFM_T *) message);
              break;

    #ifndef AVRCP_TG_ONLY_LIB /* Disable CT for TG only lib */
       case AVRCP_INTERNAL_WATCHDOG_TIMEOUT:
            avbpHandleInternalWatchdogTimeout(avbp);
            break;

       case AVRCP_INTERNAL_BROWSE_SET_PLAYER_REQ:
            avrcpHandleInternalBrowseSetPlayerReq(avbp, 
                        (AVRCP_INTERNAL_BROWSE_SET_PLAYER_REQ_T*)message);
            break;

       case AVRCP_INTERNAL_CHANGE_PATH_REQ:
            avrcpHandleInternalChangePathReq(avbp, 
                            (AVRCP_INTERNAL_CHANGE_PATH_REQ_T*)message);
            break;

       case AVRCP_INTERNAL_GET_ITEM_ATTRIBUTES_REQ:
            avrcpHandleInternalGetItemAttributesReq(avbp,
                    (AVRCP_INTERNAL_GET_ITEM_ATTRIBUTES_REQ_T*) message);
            break;

       case AVRCP_INTERNAL_GET_FOLDER_ITEMS_REQ:
            avrcpHandleInternalGetFolderItemsReq(avbp,
                   (AVRCP_INTERNAL_GET_FOLDER_ITEMS_REQ_T*)message);
            break;

       case AVRCP_INTERNAL_SEARCH_REQ:
            avrcpHandleInternalSearchReq(avbp,          
                    (AVRCP_INTERNAL_SEARCH_REQ_T*) message);
            break;

#endif /* !AVRCP_TG_ONLY_LIB */

#ifndef AVRCP_CT_ONLY_LIB /* Disable TG for CT only lib */
       case AVRCP_INTERNAL_SEND_RESPONSE_TIMEOUT:
            avbpHandleInternalSendResponseTimeout(avbp);
            break;

       case AVRCP_INTERNAL_BROWSE_SET_PLAYER_RES:
            avrcpHandleInternalBrowseSetPlayerRes(avbp,
                       (AVRCP_INTERNAL_BROWSE_SET_PLAYER_RES_T*)message);
            break;

       case AVRCP_INTERNAL_CHANGE_PATH_RES:
            avrcpHandleInternalChangePathRes(avbp,
                            (AVRCP_INTERNAL_CHANGE_PATH_RES_T*)message);
            break;

       case AVRCP_INTERNAL_GET_ITEM_ATTRIBUTES_RES:
            avrcpHandleInternalGetItemAttributesRes(avbp,
                   (AVRCP_INTERNAL_GET_ITEM_ATTRIBUTES_RES_T*)message);
            break; 

       case AVRCP_INTERNAL_GET_FOLDER_ITEMS_RES:
            avrcpHandleInternalGetFolderItemsRes(avbp,
                   (AVRCP_INTERNAL_GET_FOLDER_ITEMS_RES_T*) message);
            break;

       case AVRCP_INTERNAL_SEARCH_RES:
            avrcpHandleInternalSearchRes(avbp,
                    (AVRCP_INTERNAL_SEARCH_RES_T*) message);
            break;

#endif /* !AVRCP_CT_ONLY_LIB*/

       case AVRCP_INTERNAL_MESSAGE_MORE_DATA:
       case MESSAGE_MORE_DATA: /* Fall Through */  
            if(isAvbpConnected(avbp)) avbpHandleReceivedData (avbp);
            break;

       case MESSAGE_MORE_SPACE:
       case MESSAGE_SOURCE_EMPTY:
       case MESSAGE_STREAM_DISCONNECT:
       case CL_L2CAP_TIMEOUT_IND:
                /* ignore */
                break;

        default:
            if(id > AVRCP_MSG_BASE  && id < AVRCP_MSG_BOTTOM)
            {
                /* Ignore these messages. 
                   It may happen due to cross over of messages */
                AVRCP_INFO(("Ignoring the Message(%d) \n", id));
            }
            else
            {
                AVRCP_DEBUG(("Unhandled Message = %x\n", id));

            }
            break;
    }
}

