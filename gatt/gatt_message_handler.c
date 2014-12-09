/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    gatt_message_handler.c        

DESCRIPTION
    Handles messages received from the ATT protocol and internal GATT library
    messages and routes them to the appropriate handler functions.

NOTES

*/

#include "gatt.h"
#include "gatt_private.h"

#if (GATT_FEATURES & (GATT_FIND_INCLUDED_SERVICES | GATT_READ))
/*************************************************************************
NAME    
    handleAttReadCfm
    
DESCRIPTION
    Routes ATT_READ_CFM to correct sub-procedure handler.
    
RETURNS
    
*/
static void handleAttReadCfm(ATT_READ_CFM_T *m)
{
    switch (gattGetCidData(m->cid)->scenario)
    {
#if (GATT_FEATURES & GATT_READ)
        case gatt_ms_read:
            gattHandleAttReadCfmRead(m);
            break;
#endif

#if (GATT_FEATURES & GATT_FIND_INCLUDED_SERVICES)
        case gatt_ms_find_includes:
            gattHandleAttReadCfmInclude(m);
            break;
#endif
                                    
        default:
            GATT_DEBUG_INFO(("Unrouted ATT_READ_CFM\n"));
    }
}
#endif

#if (GATT_FEATURES & (GATT_RELATIONSHIP_DISCOVERY | \
                      GATT_CHARACTERISTIC_DISCOVERY))
/*************************************************************************
NAME    
    handleAttReadByTypeCfm
    
DESCRIPTION
    Routes ATT_READ_BY_TYPE_CFM to correct sub-procedure handler.
    
RETURNS
    
*/
static void handleAttReadByTypeCfm(ATT_READ_BY_TYPE_CFM_T *m)
{
    switch (gattGetCidData(m->cid)->scenario)
    {
#if (GATT_FEATURES & GATT_FIND_INCLUDED_SERVICES)
        case gatt_ms_find_includes:
            gattHandleAttReadByTypeCfmInclude(m);
            break;
#endif

#if (GATT_FEATURES & GATT_DISC_ALL_CHARACTERISTICS)
        case gatt_ms_discover_all_characteristics:
            gattHandleAttReadByTypeCfmCharacteristic(m);
            break;
#endif

#if (GATT_FEATURES & GATT_READ_BY_UUID)
        case gatt_ms_read_by_uuid:
            gattHandleAttReadByTypeCfmRead(m);
            break;
#endif            
    }
}
#endif

/****************************************************************************
NAME
    gattMessageHandler

DESCRIPTION
    Recieves and routes messages from ATT protocol and internal GATT messages.
*/

void gattMessageHandler(Task task, MessageId id, Message message) 
{
    gattState   *theGatt = (gattState *)task;
    uint16      type = ((ATT_UPRIM_T *)message)->type;

    /* 
     * Large switch structures used to reduce call stack.
     * 'return' after successful message handling.
     * 'break' will drop through to debug info for unexpected messages.
     */
    switch (theGatt->state)
    {
        case gatt_state_uninitialised:
            /* Shouldn't get any messages in this state so ignore. */
            break;

        case gatt_state_initialising:
            if (MESSAGE_BLUESTACK_ATT_PRIM  == id)
            {
                switch(type)
                {
                    case ATT_REGISTER_CFM:
                        gattHandleAttRegisterCfm(
                            theGatt, 
                            (ATT_REGISTER_CFM_T *)message
                            );
                        return;

                    case ATT_ADD_DB_CFM:
                        gattHandleAttAddDbCfm(
                            theGatt,
                            (ATT_ADD_DB_CFM_T *)message
                            );
                        return; 
                        
                    default:
                        break;
                } /* end type switch */
            }
            break;

        case gatt_state_initialised:
            switch(id)
            {
                case MESSAGE_BLUESTACK_ATT_PRIM:
                    switch(type)
                    {
                        case ATT_CONNECT_CFM:
                            gattHandleAttConnectCfm(
                                theGatt,
                                (ATT_CONNECT_CFM_T *)message
                                );
                            return;

                        case ATT_DISCONNECT_IND:
                            gattHandleAttDisconnectInd(
                                 theGatt,
                                (ATT_DISCONNECT_IND_T *)message
                                );
                            return;

                        case ATT_CONNECT_IND:
                            gattHandleAttConnectInd(
                                (ATT_CONNECT_IND_T *)message
                                );
                            return;

#if (GATT_FEATURES & GATT_EXCHANGE_MTU)
                        case ATT_EXCHANGE_MTU_CFM:
                            gattHandleAttExchangeMtuCfm(
                                (ATT_EXCHANGE_MTU_CFM_T *)message
                                );
                            return;
#endif

                        case ATT_EXCHANGE_MTU_IND:
                            gattHandleAttExchangeMtuInd(
                                theGatt,
                                (ATT_EXCHANGE_MTU_IND_T *)message
                                );
                            return;

#if (GATT_FEATURES & GATT_DISC_ALL_PRIMARY_SERVICES)
                        case ATT_READ_BY_GROUP_TYPE_CFM:
                            gattHandleAttReadByGroupTypeCfm(
                                (ATT_READ_BY_GROUP_TYPE_CFM_T*)message);
                            return;
#endif

#if (GATT_FEATURES & GATT_DISC_PRIMARY_SERVICE)
                        case ATT_FIND_BY_TYPE_VALUE_CFM:
                            gattHandleAttFindByTypeValueCfm(
                                (ATT_FIND_BY_TYPE_VALUE_CFM_T*)message);
                            return;
#endif

#if (GATT_FEATURES & (GATT_FIND_INCLUDED_SERVICES | \
                      GATT_DISC_ALL_CHARACTERISTICS | \
                      GATT_READ_BY_UUID))
                        case ATT_READ_BY_TYPE_CFM:
                            handleAttReadByTypeCfm(
                                (ATT_READ_BY_TYPE_CFM_T*)message);
                            return;
#endif
                            
#if (GATT_FEATURES & GATT_DESCRIPTOR_DISCOVERY)
                        case ATT_FIND_INFO_CFM:
                            gattHandleAttFindInfoCfm(
                                (ATT_FIND_INFO_CFM_T*)message);
                            return;
#endif
                            
#if (GATT_FEATURES & (GATT_FIND_INCLUDED_SERVICES | GATT_READ))
                        case ATT_READ_CFM:
                            handleAttReadCfm((ATT_READ_CFM_T*)message);
                            return;                            
#endif

#if (GATT_FEATURES & GATT_READ_LONG)
                        case ATT_READ_BLOB_CFM:
                            gattHandleAttReadBlobCfm(
                                (ATT_READ_BLOB_CFM_T*)message);
                            return;                            
#endif
                            
#if (GATT_FEATURES & GATT_READ_MULTIPLE)
                        case ATT_READ_MULTI_CFM:
                            gattHandleAttReadMultiCfm(
                                (ATT_READ_MULTI_CFM_T*)message);
                            return;
#endif

#if (GATT_FEATURES & (GATT_WRITE_COMMAND | \
                      GATT_WRITE_SIGNED | \
                      GATT_WRITE))
                        case ATT_WRITE_CFM:
                            gattHandleAttWriteCfm((ATT_WRITE_CFM_T*)message);
                            return;
#endif
                            
#if (GATT_FEATURES & (GATT_WRITE_LONG | \
                      GATT_WRITE_RELIABLE))
                        case ATT_PREPARE_WRITE_CFM:
                            gattHandleAttPrepareWriteCfm(
                                (ATT_PREPARE_WRITE_CFM_T*)message);
                            return;

                        case ATT_EXECUTE_WRITE_CFM:
                            gattHandleAttExecuteWriteCfm(
                                (ATT_EXECUTE_WRITE_CFM_T*)message);
                            return;
#endif
                            
                        case ATT_ACCESS_IND:
                            gattHandleAttAccessInd(
                                (ATT_ACCESS_IND_T *)message
                                );
                            return;

                        case ATT_HANDLE_VALUE_CFM:
                            gattHandleAttHandleValueCfm(
                                (ATT_HANDLE_VALUE_CFM_T *)message
                                );
                            return;

                        case ATT_HANDLE_VALUE_IND:
                            gattHandleAttHandleValueInd(
                                (ATT_HANDLE_VALUE_IND_T *)message
                                );
                            return;
                            
                        default:
                            break;
                    } /* ATT Message type switch */
                    break;

                /*
                 * Connection library messages
                 */
#if (GATT_FEATURES & GATT_PRIMARY_DISCOVERY)
                case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM:
                    gattHandleClSdpServiceSearchAttributeCfm(
                        (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T*)message);
                    return;
#endif
                    
                /*
                 *Internal GATT library messages 
                 */
                case GATT_INTERNAL_CONNECT_REQ:
                    gattHandleInternalConnectReq(
                        theGatt,
                        (GATT_INTERNAL_CONNECT_REQ_T *)message
                        );
                    return;

                case GATT_INTERNAL_DISCONNECT_REQ:
                    gattHandleInternalDisconnectReq(
                        (GATT_INTERNAL_DISCONNECT_REQ_T *)message
                        );
                    return;

                case GATT_INTERNAL_DELETE_CONN:
                    gattHandleInternalDeleteConn(
                        (GATT_INTERNAL_DELETE_CONN_T *)message
                        );
                    return;

#if (GATT_FEATURES & GATT_EXCHANGE_MTU)
                case GATT_INTERNAL_EXCHANGE_MTU_REQ:
                    gattHandleInternalExchangeMtuReq(
                        (GATT_INTERNAL_EXCHANGE_MTU_REQ_T *)message
                        );
                    return;
#endif

#if (GATT_FEATURES & GATT_DISC_ALL_PRIMARY_SERVICES)
                case GATT_INTERNAL_DISCOVER_ALL_PRIMARY_SERVICES_REQ:
                    gattHandleInternalDiscoverAllPrimaryServicesReq(
                        (GATT_INTERNAL_DISCOVER_ALL_PRIMARY_SERVICES_REQ_T*)
                        message);
                    return;
#endif

#if (GATT_FEATURES & GATT_DISC_PRIMARY_SERVICE)
                case GATT_INTERNAL_DISCOVER_PRIMARY_SERVICE_REQ:
                    gattHandleInternalDiscoverPrimaryServiceReq(
                        (GATT_INTERNAL_DISCOVER_PRIMARY_SERVICE_REQ_T*)
                        message);
                    return;
#endif

#if (GATT_FEATURES & GATT_DESCRIPTOR_DISCOVERY)
                case GATT_INTERNAL_DISCOVER_ALL_DESCRIPTORS_REQ:
                    gattHandleInternalDiscoverAllDescriptorsReq(
                        (GATT_INTERNAL_DISCOVER_ALL_DESCRIPTORS_REQ_T*)
                        message);
                    return;
#endif                    
                    
#if (GATT_FEATURES & GATT_RELATIONSHIP_DISCOVERY)
                        case GATT_INTERNAL_FIND_INCLUDES_REQ:
                            gattHandleInternalFindIncludesReq(
                                (GATT_INTERNAL_FIND_INCLUDES_REQ_T*)message);
                            return;
#endif

#if (GATT_FEATURES & (GATT_CHARACTERISTIC_DISCOVERY))
                case GATT_INTERNAL_DISCOVER_ALL_CHARACTERISTICS_REQ:
                    gattHandleGattDiscoverAllCharacteristicsReq(
                        (GATT_INTERNAL_DISCOVER_ALL_CHARACTERISTICS_REQ_T*)
                        message);
                    return;
#endif

#if (GATT_FEATURES & GATT_READ)
                case GATT_INTERNAL_READ_REQ:
                    gattHandleInternalReadReq(
                        (GATT_INTERNAL_READ_REQ_T *)message);
                    return;
#endif

#if (GATT_FEATURES & GATT_READ_BY_UUID)
                case GATT_INTERNAL_READ_BY_UUID_REQ:
                    gattHandleInternalReadByUuidReq(
                        (GATT_INTERNAL_READ_BY_UUID_REQ_T*)message);
                    return;
#endif

#if (GATT_FEATURES & GATT_READ_LONG)
                case GATT_INTERNAL_READ_LONG_REQ:
                    gattHandleInternalReadLongReq(
                        (GATT_INTERNAL_READ_LONG_REQ_T *)message);
                    return;
#endif
                    
#if (GATT_FEATURES & GATT_READ_MULTIPLE)
                case GATT_INTERNAL_READ_MULTIPLE_REQ:
                    gattHandleInternalReadMultipleReq(
                        (GATT_INTERNAL_READ_MULTIPLE_REQ_T*)message);
                    return;
#endif

#if (GATT_FEATURES & GATT_CHARACTERISTIC_WRITE)
                case GATT_INTERNAL_WRITE_REQ:
                    gattHandleInternalWriteReq(
                        (GATT_INTERNAL_WRITE_REQ_T*)message);
                    return;
#endif

#if (GATT_FEATURES & GATT_WRITE_RELIABLE)
                case GATT_INTERNAL_EXECUTE_WRITE_REQ:
                    gattHandleInternalExecuteWriteReq(
                        (GATT_INTERNAL_EXECUTE_WRITE_REQ_T*)message);
                    return;
#endif
                    
                case GATT_INTERNAL_ACCESS_RES:
                    gattHandleInternalAccessRes(
                        (GATT_INTERNAL_ACCESS_RES_T *)message
                        );
                    return;

                case GATT_INTERNAL_HANDLE_VALUE_REQ:
                    gattHandleInternalHandleValueReq(
                        (GATT_INTERNAL_HANDLE_VALUE_REQ_T *)message
                        );
                    return;

                default:
                    break;
            } /* id switch */
                
        default:
            break;
    } /* theGatt->state switch*/    

    GATT_DEBUG_INFO((
        "GATT Msg Hndler - Unknown Msg - State %d : id 0x%02X : type 0x%02X\n",
        theGatt->state,
        id,
        type));
}
