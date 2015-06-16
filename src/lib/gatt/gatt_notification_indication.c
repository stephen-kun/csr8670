/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    gatt_notification_indication.c        

DESCRIPTION
    Handle the Notification and Indication GATT message scenarios, both 
    server and client side.

NOTES

*/

/***************************************************************************
    Header Files
*/

#include "gatt.h"
#include "gatt_private.h"

#include <string.h>
#include <stdlib.h>
#include <vm.h>

/****************************************************************************
NAME
    GattNotification

DESCRIPTION
    Send a Notification Req to the client. Does not update the ATT database.

RETURNS

*/
void GattNotificationRequest(
        Task theAppTask, 
        uint16 cid, 
        uint16 handle, 
        uint16 size_value,
        const uint8 *value
        )
{
    MAKE_GATT_MESSAGE_WITH_VALUE(
        GATT_INTERNAL_HANDLE_VALUE_REQ, 
        size_value,
        value
        );

    message->theAppTask = theAppTask;
    message->cid        = cid;
    message->handle     = handle;
    message->flags      = ATT_HANDLE_VALUE_NOTIFICATION;

    MessageSendConditionally(
            gattGetTask(),
            GATT_INTERNAL_HANDLE_VALUE_REQ,
            message,
            &gattGetCidData(cid)->scenario
            );
}

/****************************************************************************
NAME
    GattIndicationRequest

DESCRIPTION
    Send an Indication (no response) to the client. Does not update the ATT
    database.

RETURNS

*/
void GattIndicationRequest(
        Task theAppTask, 
        uint16 cid, 
        uint16 handle, 
        uint16 size_value,
        const uint8 *value
        )
{
    MAKE_GATT_MESSAGE_WITH_VALUE(
        GATT_INTERNAL_HANDLE_VALUE_REQ, 
        size_value,
        value
        );

    message->theAppTask = theAppTask;
    message->cid        = cid;
    message->handle     = handle;
    message->flags      = ATT_HANDLE_VALUE_INDICATION;

    MessageSendConditionally(
            gattGetTask(),
            GATT_INTERNAL_HANDLE_VALUE_REQ,
            message,
            &gattGetCidData(cid)->scenario
            );
}

/****************************************************************************
NAME
    gattSendCfm

DESCRIPTION
    Send an Indication or Notification Cfm message, depending on the the 
    flags set (Indication or Notification
RETURNS

*/

static void gattSendCfm(
    Task task, 
    gatt_status_t status, 
    uint16 cid,
    uint16 flags
    )
{
    /* NOTIFICATION and INDICATION message are identical in structure. */
    MessageId id = GATT_INDICATION_CFM;
    MAKE_GATT_MESSAGE(GATT_INDICATION_CFM);

    message->status = status;
    message->cid = cid;

    if (flags == ATT_HANDLE_VALUE_NOTIFICATION)
        id = GATT_NOTIFICATION_CFM;

    MessageSend(task, id, message);
}

/****************************************************************************
NAME
    gattHandleInternalHandleValueReq

DESCRIPTION
    Handle the Internal Handle Value Request message. 

RETURNS

*/
void gattHandleInternalHandleValueReq(GATT_INTERNAL_HANDLE_VALUE_REQ_T *req)
{
    if ( gattCidIsValid(req->cid) )
    {
        gatt_msg_scen_t msg_scen = gatt_ms_notification_req;

        if (req->flags == ATT_HANDLE_VALUE_INDICATION)
            msg_scen = gatt_ms_indication_req;
        
        /* Message is sent conditionally, so the lock should always be free
         * at this point.
         */
        if ( gattLockCid(req->cid, msg_scen) )
        {
            MAKE_ATT_PRIM(ATT_HANDLE_VALUE_REQ);
            
            prim->cid           = req->cid;
            prim->handle        = req->handle;
            prim->flags         = req->flags;
            prim->size_value    = req->size_value;
            
            if (req->size_value)
            {
                uint8 *value = (uint8 *)PanicUnlessMalloc(req->size_value);
                memmove(value, req->value, req->size_value);
                prim->value = VmGetHandleFromPointer(value);
            }
            else
            {
                prim->value = 0;    /* Unlikely */
            }

            /* Stash the flags to determine the CFM message later. */
            gattGetCidData(req->cid)->req.notif_ind_flags = req->flags;
            
            VmSendAttPrim(prim);
        }
        else 
            GATT_DEBUG(("GATT_INTERNAL_HANDLE_VALUE_REQ cid locked!\n"));
    }
    else 
    {
        gattSendCfm(
            req->theAppTask,
            gatt_status_invalid_cid,
            req->cid,
            req->flags
            );
    }
}

/****************************************************************************
NAME
    gattAttHandleValueCfm

DESCRIPTION
    Handle the Internal Handle Value Request message. 

RETURNS

*/
void gattHandleAttHandleValueCfm(ATT_HANDLE_VALUE_CFM_T *cfm)
{
    if ( gattCidIsValid(cfm->cid) )
    {
        gatt_status_t status = gatt_status_success;
        conn_data_t *cd = gattGetCidData(cfm->cid);

        if (cfm->result)
        {
            
            if (cfm->result == ATT_RESULT_SUCCESS_SENT)
                status = gatt_status_success_sent;
            else
            {
                status = gatt_status_failure;
                GATT_DEBUG_INFO((
                    "gattAttHandleValueCfm: ATT result 0x%04x\n", 
                    cfm->result
                    ));
            }
        }
        
        gattSendCfm(
            gattGetCidMappedTask(cfm->cid),
            status,
            cfm->cid,
            cd->req.notif_ind_flags
            );

        /* Don't unlock until failure or success */
        if (status != gatt_status_success_sent)
        {
            cd->stash = 0;
            gattUnlockCid(cfm->cid);
        }
    }
    else
        GATT_DEBUG_INFO((
            "gattAttHandleValueCfm: invalid cid 0x%04x\n", 
            cfm->cid
            ));
}

/****************************************************************************
NAME
    gattAttHandleValueind

DESCRIPTION
    Handle the ATT Handle Value Indication message. Could be a GATT
    Notification or Indication, depending on the flags. 

RETURNS

*/
void gattHandleAttHandleValueInd(ATT_HANDLE_VALUE_IND_T *ind)
{
    uint8 *value = 0;
    if (ind->size_value)
        value = (uint8 *) VmGetPointerFromHandle(ind->value);   

    if ( gattCidIsValid(ind->cid) )
    {
        /* Notification and Indication message structures are identical,
         * so use NOTFICATION and adjust the message id accordingly.
         */
        MessageId id = GATT_NOTIFICATION_IND;
        
        MAKE_GATT_MESSAGE_WITH_VALUE(
            GATT_NOTIFICATION_IND, 
            ind->size_value,
            value
            );

        message->cid = ind->cid;
        message->handle = ind->handle;

        if (ind->flags == ATT_HANDLE_VALUE_INDICATION)
            id = GATT_INDICATION_IND;

        MessageSend( gattGetCidMappedTask(ind->cid), id, message );
    }
    else    
        GATT_DEBUG_INFO((
            "gattAttHandleValueInd: invalid cid 0x%04x\n", 
            ind->cid
            ));

    free(value);
}

/****************************************************************************
NAME
    GattIndicationResponse

DESCRIPTION
    API function in response to GATT_INDICATION_IND. Non-locking, sends 
    response immediately.

RETURNS

*/
void GattIndicationResponse(uint16 cid)
{
    if( gattCidIsValid(cid) )
    {
        MAKE_ATT_PRIM(ATT_HANDLE_VALUE_RSP);

        prim->cid = cid;

        VmSendAttPrim(prim);
    }
    else
        GATT_DEBUG_INFO((
            "GattIndicationResponse: invalid cid 0x%04x\n", 
            cid
            ));
}


