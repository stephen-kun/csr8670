/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    avrcp_init.c        

DESCRIPTION
    This file contains the initialisation code for the AVRCP profile library.

NOTES

*/
/****************************************************************************
    Header files
*/
#include <stdlib.h>
#include <Panic.h>
#include <connection.h>
#include "avrcp_init.h"
#include "avrcp_profile_handler.h"

static AvrcpDeviceTask gAvrcpDeviceSettings;
static const TaskData avrcpInitTask = {avrcpInitHandler};

/****************************************************************************
 *NAME    
 *  avrcpInitProfile 
 *
 *DESCRIPTION
 *  Initialize the profile settings 
 **************************************************************************/
static void avrcpInitProfile( avrcp_device_role role,
                             uint8 tg_features, 
                             uint8 ct_features, 
                             uint8 extensions )
{
    /* Feature bits and extensions need to be aligned only for 
       Target Category 1 or 3 */
    if(tg_features & (AVRCP_CATEGORY_1 | AVRCP_CATEGORY_3))
    {
        /* AVRCP_VERSION_1_3 support must be turned ON to support 
           Player application settings. Group Navigation support is 
           mandatory for v1.3 */
        if(extensions & AVRCP_VERSION_1_3)
        {
            tg_features |= AVRCP_GROUP_NAVIGATION;

            if((extensions & AVRCP_VERSION_1_4) == AVRCP_VERSION_1_3)
            {
                /* Version 1.4 features are not supported */
                tg_features &= AVRCP_1_4_EXTENSION_MASK;
            }
        }
        else
        {
            /* None of the extensions are valid */
            extensions = 0;

            /* version 1.3 features are not supported */
            tg_features &= AVRCP_1_3_EXTENSION_MASK;
        }
    }

    /* Set the SDP Bit for Browsing if the controller supports 
       Browsing channel */
    if((extensions & AVRCP_BROWSING_SUPPORTED) == AVRCP_BROWSING_SUPPORTED)
    {
        ct_features |= AVRCP_VIRTUAL_FILE_SYSTEM_BROWSING;
         
    }

     /* Set the Supported features values */
    gAvrcpDeviceSettings.device_type = role;
    gAvrcpDeviceSettings.local_target_features = tg_features;
    gAvrcpDeviceSettings.local_controller_features = ct_features; 
    gAvrcpDeviceSettings.local_extensions = extensions;
    gAvrcpDeviceSettings.unused = 0;


}

/****************************************************************************
 *NAME    
 *   avrcpHandleInternalInitReq
 *
 *DESCRIPTION
 *   Handle the internal initialization. Register with L2CAP and initialize
 *   browsing. 
 **************************************************************************/
void avrcpHandleInternalInitReq( const AVRCP_INTERNAL_INIT_REQ_T *req)
{
    gAvrcpDeviceSettings.app_task = req->connectionTask;
    avrcpInitProfile(req->init_params.device_type,
                    req->init_params.supported_target_features,
                    req->init_params.supported_controller_features,
                    req->init_params.profile_extensions);

    ConnectionL2capRegisterRequest( (Task)&avrcpInitTask, 
                    (isAvrcpBrowsingEnabled(avrcpGetDeviceTask()))?
                    AVCTP_BROWSING_PSM:AVCTP_PSM,
					0);
}

/****************************************************************************
 *NAME    
 *   avrcpGetInitTask
 *
 *DESCRIPTION
 *  Get the Initailization Task; 
 **************************************************************************/
Task avrcpGetInitTask( void )
{
    return (Task)&avrcpInitTask;
}

/****************************************************************************
 *NAME    
 *   avrcpGetDeviceTask
 *
 *DESCRIPTION
 *  Get the device Task
 **************************************************************************/
AvrcpDeviceTask* avrcpGetDeviceTask(void)
{
    return &gAvrcpDeviceSettings;
}

/****************************************************************************
*NAME    
*  avrcpInitDefaults
*
*DESCRIPTION
*  Initialize the Default AVRCP task values.
*****************************************************************************/
void avrcpInitDefaults( AVRCP       *avrcp,
                        avrcpState   state)
{
    avrcpSetState(avrcp, state);
    avrcp->pending = avrcp_none;
    avrcp->block_received_data = 0;
    avrcp->sink = 0;
    avrcp->cmd_transaction_label = 1;
    avrcp->registered_events = 0;
    avrcp->continuation_pdu = 0;
    avrcp->fragment = avrcp_packet_type_single;
    avrcp->continuation_data = 0;
    avrcp->sdp_search_mode = avrcp_sdp_search_none;
    avrcp->sdp_search_repeat = 0;
    avrcp->av_msg = NULL;    
    avrcp->av_msg_len = 0;
    avrcp->data_app_ind = 0;
    avrcp->remote_features = 0;
    avrcp->remote_extensions = 0;
}


/****************************************************************************
*NAME    
*  avrcpCreateTask
*
*DESCRIPTION
*  Create the AVRCP Task and initiaze the default values.
******************************************************************************/
AVRCP *avrcpCreateTask( Task         client, 
                        avrcpState   state)
{
    AVRCP *avrcp;

    /* Create a new Task */
    if(isAvrcpBrowsingEnabled(avrcpGetDeviceTask()))
    {
        avrcp = PanicUnlessMalloc(sizeof(AVRCP)+sizeof(AVBP));

        /* Initalize browsing */
        avrcpInitBrowsing(avrcp);
    }
    else
    {
        avrcp = PanicUnlessNew(AVRCP);

        /* No browsing supported */
        avrcp->avbp_task = NULL;
    }

    /* Set the handler function */
    avrcp->task.handler = avrcpProfileHandler;

    /* Set the static Task data */
    avrcp->clientTask = client;   
 
    /* Set the Intial configuration Data */
    avrcp->l2cap_mtu = AVRCP_MTU_DEFAULT; 

    /* Initialize the default values */
    avrcpInitDefaults(avrcp, state);

    /* Initialize datacleanup handler */
    (avrcp->dataFreeTask.cleanUpTask).handler = avrcpDataCleanUp;
    avrcp->dataFreeTask.sent_data = 0;

    return avrcp;
}

/****************************************************************************
*NAME    
*   avrcpResetValues
*
*DESCRIPTION
*  Reset the local state values to their initial states. 
*    
******************************************************************************/
void avrcpResetValues(AVRCP* avrcp)
{

    /* Reset the Browsing channel entries if it is present */
    if(avrcp->avbp_task)
    {
       avrcpResetAvbpValues((AVBP*)avrcp->avbp_task);      
    }

    /* Free any memory that may be allocated */
    avrcpSourceProcessed(avrcp, TRUE);

   /* Reset the local state values to their initial states */
    avrcpInitDefaults(avrcp, avrcpReady);

    /* Cancel all pending messages */
    MessageCancelAll(&avrcp->task, AVRCP_INTERNAL_WATCHDOG_TIMEOUT);
    MessageCancelAll(&avrcp->task, AVRCP_INTERNAL_SEND_RESPONSE_TIMEOUT);
    MessageCancelAll(&avrcp->task, AVRCP_INTERNAL_CONNECT_REQ);

}


/****************************************************************************
*NAME    
*    avrcpResetAvbpValues
*
*DESCRIPTION
*   Reset the browsing channel Task 
****************************************************************************/
void avrcpResetAvbpValues(AVBP* avbp)
{
    if(!avbp) return;

    /* Reset the local Values to their initial states */
    avrcpSetAvbpState(avbp, avbpReady);
    avbp->avbp_sink = 0;
    avbp->avbp_sink_data = 0;
    avbp->avbp_mtu = AVRCP_MTU_DEFAULT;    /* 672 */ 
    avbp->blocking_cmd = AVRCP_INVALID_PDU_ID;
    avbp->trans_id = 0;
    
    /* Cancel all AVBP Timers if running */
    MessageCancelAll(&avbp->task, AVRCP_INTERNAL_WATCHDOG_TIMEOUT);
    MessageCancelAll(&avbp->task, AVRCP_INTERNAL_SEND_RESPONSE_TIMEOUT);
}


/****************************************************************************
*NAME    
*   avrcpInitBrowsing
*
*DESCRIPTION
*    Initialise all members of the AVBP task data structure and register 
*    AVCTP_Browsing PSM with L2CAP. 
****************************************************************************/
void avrcpInitBrowsing(AVRCP *avrcp)
{
    AVBP *avbp= (AVBP*) (((uint16*)avrcp) + sizeof(AVRCP));

    /* Set Browsing Channel Profile Handler */
    avbp->task.handler = avbpProfileHandler;

    /* Associated AVRCP Task. */
    avbp->avrcp_task = &avrcp->task;
    avrcpResetAvbpValues(avbp);

    /* Associate the AVBP task with AVRCP */
    avrcp->avbp_task = &avbp->task;
}

/****************************************************************************
*NAME    
*   avrcpSendInitCfmToClient
*
*DESCRIPTION
*  Post processing of init procedure. Set the states and send AVRCP_INIT_CFM 
*  to the application.
****************************************************************************/
void avrcpSendInitCfmToClient( avrcp_unreg_status   state,
                               uint32             sdp_handle, 
                               avrcp_status_code  status)
{
    MAKE_AVRCP_MESSAGE(AVRCP_INIT_CFM);
    message->status = status;
    message->sdp_handle = sdp_handle;

    if(status == avrcp_fail)
    {
        switch( state )
        {
        case avrcp_unreg_all:
            ConnectionL2capUnregisterRequest((Task)&avrcpInitTask,AVCTP_PSM);

        case avrcp_unreg_browse: /* fall through */
            if(isAvrcpBrowsingEnabled(avrcpGetDeviceTask()))
            {
                ConnectionL2capUnregisterRequest((Task)&avrcpInitTask,
                                                 AVCTP_BROWSING_PSM);
            }

        default:
            break;
        }
    }
                                         
    MessageSend((Task)gAvrcpDeviceSettings.app_task, AVRCP_INIT_CFM, message);
}


                
/***************************************************************************
*NAME    
*   AvrcpInit
*
*DESCRIPTION
*   Initialize AVRCP 
****************************************************************************/
void AvrcpInit(Task theAppTask, const avrcp_init_params *config)
{
    /* Must pass in valid configuration parameters. */
    if (!config || !theAppTask)
    {
        MAKE_AVRCP_MESSAGE(AVRCP_INIT_CFM);
        message->status = avrcp_fail;
        MessageSend(theAppTask, AVRCP_INIT_CFM, message);
        return;
    }
    else
    {
        MAKE_AVRCP_MESSAGE(AVRCP_INTERNAL_INIT_REQ);
        message->connectionTask = theAppTask;
        message->init_params = *config;

        /* Configure the device type */
#ifdef AVRCP_CT_ONLY_LIB 
        message->init_params.device_type = avrcp_ct;
        message->init_params.supported_target_features = 0;
#else 
#ifdef AVRCP_TG_ONLY_LIB
        message->init_params.device_type = avrcp_tg;
        message->init_params.supported_controller_features = 0;
#endif /* AVRCP_TG_ONLY_LIB */
#endif /* AVRCP_CT_ONLY_LIB */  

        MessageSend((Task) &avrcpInitTask, AVRCP_INTERNAL_INIT_REQ, message);
    }
}


/****************************************************************************
*NAME    
*   avrcpHandleDeleteTask
*
*DESCRIPTION
*   Delete a dynamically allocated AVRCP and AVBP task instance. 
*   Before deleting make  sure all messages for that task are flushed 
*   from the message queue.
*****************************************************************************/
void avrcpHandleDeleteTask(AVRCP *avrcp)
{
    /* Delete Browsing Channel Task */
    if(avrcp->avbp_task)
    {
        MessageFlushTask(avrcp->avbp_task);
    }
 
    /* Delete Control Channel Task */
    MessageFlushTask(&avrcp->task);
    free(avrcp);
}

