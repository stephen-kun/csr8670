/*************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    gatt_message.c

DESCRIPTION
    Functions for handling message queueing.

NOTES
*/

#include "gatt_private.h"
#include <string.h>

/*************************************************************************
NAME    
    gatt_message_internal
    
DESCRIPTION
    This function is used to send internal messages.

RETURNS
    
*/
void gatt_message_internal(Task task, cid_map_t *conn, void *prim, uint16 id)
{
    gatt_internal_t *msg = (gatt_internal_t*)prim;

    /* Store the application task */
    msg->task = task;

    /* Send the message to GATT task */
    MessageSendConditionallyOnTask(gattGetTask(), id, msg, &conn->data.app);
}

/*************************************************************************
NAME    
    gatt_message_prepare
    
DESCRIPTION
    This function is used to prepare for creating a new message, possibly
    sending pending messages to the application.

NOTES
    This function sets the following boolean flags:
    - more_to_come - a flag in the pending message indicating if more
                     responses _will_ follow.
    - more - more responses can follow
    - send - a new message can be sent without waiting for more information

RETURNS
    True if another message can be sent, false otherwise
*/
bool gatt_message_prepare(cid_map_t *conn,
                          bool *more, bool *send,
                          att_result_t result,
                          bool final,
                          bool *more_to_come,
                          uint16 id)
{
    bool last = FALSE;

    *more = FALSE;
    *send = TRUE;
    
    switch (result)
    {
        case ATT_RESULT_SUCCESS:
            if (final) break; /* procedure handle range already done */
            
            /* Last result for current request. We'll have to start a new
             * request to find out if there are still more results to come.
             * Store current results for later delivery. */
            *send = FALSE;
            *more = TRUE;
            break;

        case ATT_RESULT_SUCCESS_MORE:
            *more = TRUE;
            break;

        default:
            last = TRUE;
    }

    /* deliver pending message */
    if (more_to_come)
    {
        /* update fields */
        *more_to_come = (*more | *send) & !last;

        gatt_message_send(conn, id);
        
        if (last)
        {
            gattSetConnState(conn, NULL, gatt_ms_none);
            return FALSE;
        }
    }

    return TRUE;
}

/*************************************************************************
NAME    
    gatt_message_send
    
DESCRIPTION
    This function is used to send messages to the application.

RETURNS
    
*/
void gatt_message_send(cid_map_t *conn, uint16 id)
{
    if (conn->data.stash)
    {
        MessageSend(conn->data.app, id, conn->data.stash);
        conn->data.stash = NULL;
    }
}

/*************************************************************************
NAME    
    gatt_message_status
    
DESCRIPTION
    This function is used to convert Bluestack ATT result codes to GATT
    status codes.

    FIXME: This function needs a proper implementation. Remember to convert
    ATT_RESULT_SUCCESS_MORE to success.

RETURNS
    Corresponding GATT result code
*/
gatt_status_t gatt_message_status(att_result_t result)
{
    switch (result)
    {
        case ATT_RESULT_SUCCESS:
        case ATT_RESULT_SUCCESS_MORE:
            return ATT_RESULT_SUCCESS;

        default:
            return result & ~0x8000; /* mask out sign bit of integer */
    }
}

/*************************************************************************
NAME    
    gattSetConnState
    
DESCRIPTION
    This function is used to set the state machine and related locks.

RETURNS
    
*/
void gattSetConnState(cid_map_t *conn, Task task, gatt_msg_scen_t sm)
{
    conn->data.app = task;
    conn->data.scenario = sm;
}
