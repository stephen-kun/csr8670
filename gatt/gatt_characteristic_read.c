/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    gatt_exchange_mtu.c        

DESCRIPTION
    Functions to handle GATT Characteristic Value Read sub-procedures.

    This module implements support for the following GATT sub-procedures:
    - Read Characteristic Value
    - Read Using Characteristic UUID
    - Read Long Characteristic Values
    - Read Multiple Characteristic Values

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

#if (GATT_FEATURES & GATT_READ)
/****************************************************************************
NAME
    gattSendReadCharacteristicValueCfm

DESCRIPTION
    Send the GATT_READ_CHARACTERISTIC_VALUE_CFM message.

NOTES
    'value' array data is copied so if it is a ptr, it must be freed
    afterwards by the caller.

RETURNS

*/
static void gattSendReadCharacteristicValueCfm(Task task,
                                               uint16 cid,
                                               uint16 handle, 
                                               gatt_status_t status, 
                                               uint16 size_value, 
                                               const uint8 *value)
{
    MAKE_GATT_MESSAGE_WITH_VALUE(GATT_READ_CHARACTERISTIC_VALUE_CFM, 
                                 size_value,
                                 value);

    message->cid = cid;
    message->handle = handle;
    message->status = gatt_message_status(status);

    MessageSend(task, GATT_READ_CHARACTERISTIC_VALUE_CFM, message);
}

void GattReadCharacteristicValueRequest(Task theAppTask,
                                        uint16 cid,
                                        uint16 handle)
{
    cid_map_t *conn;

    if ((conn = gattFindConn(cid)) && !conn->closing)
    {
        MAKE_GATT_MESSAGE(GATT_INTERNAL_READ_REQ);

        message->common.task = theAppTask;
        message->common.cid = cid;
        message->handle = handle;

        MessageSendConditionallyOnTask(
            gattGetTask(),
            GATT_INTERNAL_READ_REQ,
            message,
            &conn->data.app);
    }
    else
    {
        gattSendReadCharacteristicValueCfm(
            theAppTask, cid, handle, gatt_status_invalid_cid, 0, NULL);
    }
}

/****************************************************************************
NAME
    gattHandleInternalReadReq
           
DESCRIPTION
    Handle the internal Read request.

RETURN

*/
void gattHandleInternalReadReq(GATT_INTERNAL_READ_REQ_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->common.cid)); /* never NULL */

    gattSetConnState(conn, m->common.task, gatt_ms_read);

    /* store the handle for the response */
    conn->data.req.read.handle = m->handle;

    gatt_read_req(m->common.cid, m->handle);
}



/****************************************************************************
NAME
    gattHandleAttReadCfmRead

DESCRIPTION
    This function handles Bluestack response for ATT_READ_REQ during
    Read Characteristic Value.

RETURNS

*/
void gattHandleAttReadCfmRead(ATT_READ_CFM_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->cid)); /* never NULL */
    uint8 *value = VmGetPointerFromHandle(m->value);

    gattSendReadCharacteristicValueCfm(conn->data.app, m->cid,
                                        conn->data.req.read.handle,
                                        m->result,
                                        m->size_value, value);
        
    gattSetConnState(conn, NULL, gatt_ms_none);
    free(value);
}
#endif /* GATT_READ */

#if (GATT_FEATURES & GATT_READ_BY_UUID)
/****************************************************************************
NAME
    gattSendReadCharacteristicValueCfm

DESCRIPTION
    Send the GATT_READ_CHARACTERISTIC_VALUE_CFM message.

NOTES
    'value' array data is copied so if it is a ptr, it must be freed
    afterwards by the caller.

RETURNS

*/
static void gattSendReadUsingCharacteristicUuidCfm(Task task,
                                                   uint16 cid,
                                                   uint16 handle,
                                                   bool more,
                                                   gatt_status_t status, 
                                                   uint16 size_value, 
                                                   const uint8 *value)
{
    MAKE_GATT_MESSAGE_WITH_VALUE(GATT_READ_USING_CHARACTERISTIC_UUID_CFM, 
                                 size_value,
                                 value);

    message->cid = cid;
    message->handle = handle;
    message->more_to_come = more;
    message->status = gatt_message_status(status);

    MessageSend(task, GATT_READ_USING_CHARACTERISTIC_UUID_CFM, message);
}

void GattReadUsingCharacteristicUuidRequest(Task theAppTask,
                                            uint16 cid,
                                            uint16 start,
                                            uint16 end,
                                            gatt_uuid_type_t uuid_type,
                                            const gatt_uuid_t *uuid)
{
    cid_map_t *conn;
    gatt_status_t err;

    /* check that cid exists */
    if (!(conn = gattFindConn(cid)) || conn->closing)
        err = gatt_status_invalid_cid;

    /* check that uuid is valid */
    else if ((uuid_type < gatt_uuid16) || (uuid_type > gatt_uuid128))
        err = gatt_status_invalid_uuid;

    /* send internal request */
    else 
    {
        MAKE_GATT_MESSAGE(GATT_INTERNAL_READ_BY_UUID_REQ);

        message->common.task = theAppTask;
        message->common.cid = cid;
        message->start = start;
        message->end = end;
        message->uuid_type = uuid_type;
        memmove(message->uuid, uuid, GATT_UUID_SIZE);        

        MessageSendConditionallyOnTask(
            gattGetTask(),
            GATT_INTERNAL_READ_BY_UUID_REQ,
            message,
            &conn->data.app);

        return;
    }

    /* send error */
    gattSendReadUsingCharacteristicUuidCfm(
        theAppTask, cid, start, FALSE, err, 0, NULL);
}

/****************************************************************************
NAME
    gattHandleInternalReadByUuidReq
           
DESCRIPTION
    Handle the internal Read By Uuid request.

RETURN

*/

void gattHandleInternalReadByUuidReq(GATT_INTERNAL_READ_BY_UUID_REQ_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->common.cid)); /* never NULL */

    gattSetConnState(conn, m->common.task, gatt_ms_read_by_uuid);

    conn->data.req.read_by_uuid.end = m->end;
    conn->data.req.read_by_uuid.uuid_type = m->uuid_type;
    memmove(conn->data.req.read_by_uuid.uuid, m->uuid, GATT_UUID_SIZE);

    gatt_read_by_type_req(m->common.cid, m->start, m->end,
                          m->uuid_type, m->uuid);
}



/****************************************************************************
NAME
    gattHandleAttReadByTypeCfmRead

DESCRIPTION
    This function handles Bluestack response for ATT_READ_BY_TYPE_REQ during
    Read Using Characteristic UUID.

RETURNS

*/
void gattHandleAttReadByTypeCfmRead(ATT_READ_BY_TYPE_CFM_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->cid)); /* never NULL */
    STASH(conn, stash, READ_USING_CHARACTERISTIC_UUID);
    uint8 *data;
    bool more;
    bool send;

    data = VmGetPointerFromHandle(m->value);

    if (!gatt_message_prepare(conn,
                              &more, &send, m->result,
                              m->handle >= conn->data.req.read_by_uuid.end,
                              stash ? &stash->more_to_come : NULL,
                              GATT_READ_USING_CHARACTERISTIC_UUID_CFM))
    {
        free(data);
        return;
    }

    /* Create the message */
    MAKE_STASH_WITH_LEN(conn, stash, READ_USING_CHARACTERISTIC_UUID,
                        m->size_value);

    stash->cid = m->cid;
    stash->more_to_come = more;
    stash->status = gatt_message_status(m->result);
    stash->handle = m->handle;
    stash->size_value = m->size_value;
    memmove(stash->value, data, m->size_value);
    
    /* schedule new round for getting more information */
    if (!send)
    {
        gatt_read_by_type_req(m->cid,
                              m->handle + 1,
                              conn->data.req.read_by_uuid.end,
                              conn->data.req.read_by_uuid.uuid_type,
                              conn->data.req.read_by_uuid.uuid);
    }
    
    /* only sent the message if we are not waiting for more information */
    else
    {
        gatt_message_send(conn, GATT_READ_USING_CHARACTERISTIC_UUID_CFM);

        if (!more)
        {
            gattSetConnState(conn, NULL, gatt_ms_none);
        }
    }
    
    free(data);
}
#endif /* GATT_READ_BY_UUID */

#if (GATT_FEATURES & GATT_READ_LONG)
void GattReadLongCharacteristicValueRequest(Task theAppTask,
                                            uint16 cid,
                                            uint16 handle)
{
    cid_map_t *conn;
    
    if ((conn = gattFindConn(cid)) && !conn->closing)
    {
        MAKE_GATT_MESSAGE(GATT_INTERNAL_READ_LONG_REQ);

        message->common.task = theAppTask;
        message->common.cid = cid;
        message->handle = handle;
        
        MessageSendConditionallyOnTask(
            gattGetTask(),
            GATT_INTERNAL_READ_LONG_REQ,
            message,
            &conn->data.app);
    }
    else
    {
        MAKE_GATT_MESSAGE(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM);

        memset(message, 0, sizeof(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T));
        message->cid = cid;
        message->status = gatt_status_invalid_cid;
        message->handle = handle;
        
        MessageSend(theAppTask,
                    GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM,
                    message);
    }
}

/*************************************************************************
NAME    
    gattHandleInternalReadLongReq
    
DESCRIPTION
    This function is handler for ATT_FIND_INCLUDES_REQ internal message.
    
RETURNS
    
*/
void gattHandleInternalReadLongReq(GATT_INTERNAL_READ_LONG_REQ_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->common.cid)); /* never NULL */
    
    gattSetConnState(conn, m->common.task, gatt_ms_read_long);

    conn->data.req.read_long.handle = m->handle;
    conn->data.req.read_long.offs = 0;
    
    gatt_read_blob_req(m->common.cid,
                       conn->data.req.read_long.offs,
                       conn->data.req.read_long.handle);
}

/*************************************************************************
NAME    
    gattHandleAttReadBlobCfm
    
DESCRIPTION
    This function handles Bluestack response for ATT_READ_BLOB_REQ.
    
RETURNS
    
*/
void gattHandleAttReadBlobCfm(ATT_READ_BLOB_CFM_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->cid)); /* never NULL */
    STASH(conn, stash, READ_LONG_CHARACTERISTIC_VALUE);
    uint8 *data;

    data = VmGetPointerFromHandle(m->value);

    do
    {
        /* Create the message */
        if (!stash)
        {
            MAKE_STASH(conn, stash, READ_LONG_CHARACTERISTIC_VALUE);
            stash->cid = m->cid;
            stash->handle = conn->data.req.read_long.handle;
            stash->offset = conn->data.req.read_long.offs;
            stash->status = gatt_message_status(m->result);
        }

        /* add data to packet */
        if (m->size_value)
        {
            if (!(stash =
                  realloc(stash,
                          sizeof(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T) +
                          stash->size_value + m->size_value - 1)))
            {
                /* can't get the block larger, send message */
                stash = conn->data.stash;
                stash->more_to_come = TRUE;
                stash = NULL;
                gatt_message_send(conn,
                                  GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM);
                continue;
            }

            conn->data.stash = stash;
        
            memmove(stash->value + stash->size_value, data, m->size_value);
            stash->size_value += m->size_value;
            conn->data.req.read_long.offs += m->size_value;
        }

        break; /* whole value has been copied */
    } while (1);
    
    /* schedule new round for getting more information */
    if (m->result == ATT_RESULT_SUCCESS &&
        stash->size_value % MAX_BLOB_SIZE(conn->mtu) == 0)
    {
        gatt_read_blob_req(m->cid,
                           conn->data.req.read_long.offs,
                           conn->data.req.read_long.handle);
    }
    
    /* only sent the message if we are not waiting for more information */
    else
    {
        gatt_message_send(conn, GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM);
        gattSetConnState(conn, NULL, gatt_ms_none);
    }
    
    free(data);
}
#endif /* GATT_READ_LONG */

#if (GATT_FEATURES & GATT_READ_MULTIPLE)
/****************************************************************************
NAME
    gattSendReadMultipleCharacteristicValuesCfm

DESCRIPTION
    Send the GATT_READ_MULTIPLE_CHARACTERISTIC_VALUES_CFM message.

NOTES
    'value' array data is copied so if it is a ptr, it must be freed
    afterwards by the caller.

RETURNS

*/
static void gattSendReadMultipleCharacteristicValuesCfm(Task task,
                                                        uint16 cid,
                                                        gatt_status_t status,
                                                        uint16 size_value,
                                                        uint8 *value)
{
    MAKE_GATT_MESSAGE_WITH_VALUE(GATT_READ_MULTIPLE_CHARACTERISTIC_VALUES_CFM, 
                                 size_value,
                                 value);

    message->cid = cid;
    message->status = gatt_message_status(status);

    MessageSend(task, GATT_READ_MULTIPLE_CHARACTERISTIC_VALUES_CFM, message);
}

void GattReadMultipleCharacteristicValuesRequest(Task theAppTask,
                                                 uint16 cid,
                                                 uint16 num_handles,
                                                 uint16 *handles)
{
    cid_map_t *conn;

    if ((conn = gattFindConn(cid)) && !conn->closing)
    {
        MAKE_GATT_MESSAGE_WITH_LEN(GATT_INTERNAL_READ_MULTIPLE_REQ,
                                   num_handles);

        message->common.task = theAppTask;
        message->common.cid = cid;
        message->num_handles = num_handles;
        memmove(message->handles, handles, num_handles);
        
        MessageSendConditionallyOnTask(
            gattGetTask(),
            GATT_INTERNAL_READ_MULTIPLE_REQ,
            message,
            &conn->data.app);
    }
    else
    {
        gattSendReadMultipleCharacteristicValuesCfm(
            theAppTask, cid, gatt_status_invalid_cid, 0, NULL);
    }
}

/****************************************************************************
NAME
    gattHandleInternalReadMultipleReq
           
DESCRIPTION
    Handle the internal Read Multiple Characteristic Values request.

RETURN

*/

void gattHandleInternalReadMultipleReq(
    GATT_INTERNAL_READ_MULTIPLE_REQ_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->common.cid)); /* never NULL */

    gattSetConnState(conn, m->common.task, gatt_ms_read_multiple);

    gatt_read_multi_req(m->common.cid, m->num_handles, m->handles);
}



/****************************************************************************
NAME
    gattHandleAttReadMultiCfm

DESCRIPTION
    This function handles Bluestack response for ATT_READ_MULTI_REQ.

RETURNS

*/
void gattHandleAttReadMultiCfm(ATT_READ_MULTI_CFM_T *m)
{
    cid_map_t *conn = PanicNull(gattFindConn(m->cid)); /* never NULL */
    uint8 *value = VmGetPointerFromHandle(m->value);

    gattSendReadMultipleCharacteristicValuesCfm(
        conn->data.app, m->cid, m->result,m->size_value, value);
        
    gattSetConnState(conn, NULL, gatt_ms_none);
    free(value);
}
#endif /* GATT_READ_BY_UUID */

