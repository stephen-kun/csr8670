/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    dm_ble_security.c      

DESCRIPTION
    This file contains the implementation of Low Energy security msg scenarios.

NOTES

*/

#ifndef DISABLE_BLE

#include "connection.h"
#include "connection_private.h"

#include "dm_ble_security.h"

#include <bdaddr.h>
#include <vm.h>

/****************************************************************************
NAME    
    ConnectionBleDmSecurityReq

DESCRIPTION
    Starts the BLE Sm Security message scenario.

RETURNS
   void
*/
void ConnectionDmBleSecurityReq(
        Task                    theAppTask, 
        const typed_bdaddr      *taddr, 
        ble_security_type       security,
        ble_connection_type     conn_type
        )
{
#ifdef CONNECTION_DEBUG_LIB
    /* Check parameters. */
    if (security >= ble_security_last )
        CL_DEBUG(("ble_security_type out of range\n"));

    if (conn_type >= ble_connection_last)
        CL_DEBUG(("ble_connection_type out of range\n"));
    
#endif
    if (connectionGetBtVersion() < bluetooth4_0)
    {
        CL_DEBUG(("Bluestack does not support low energy (BT 4.0)\n"));
    }
    else
    {
        MAKE_CL_MESSAGE(CL_INTERNAL_SM_DM_SECURITY_REQ);

        message->theAppTask = theAppTask;
        message->taddr      = *taddr;
        message->security   = security;
        message->conn_type = conn_type;

        MessageSend(connectionGetCmTask(), CL_INTERNAL_SM_DM_SECURITY_REQ, message);
    }
}


/****************************************************************************
NAME    
    connectionHandleInternalBleDmSecurityReq

DESCRIPTION
    Deals with the internal message (see above). State lock for the task is 
    not required as it can be passed as the context for the Security message
    scenario.

RETURNS
   void
*/
void connectionHandleInternalBleDmSecurityReq(
        CL_INTERNAL_SM_DM_SECURITY_REQ_T *req
        )
{
    MAKE_PRIM_T(DM_SM_SECURITY_REQ);
 
    switch(req->conn_type)
    {
        case ble_connection_master_directed:
            prim->connection_flags = 
                L2CA_CONFLAG_ENUM(L2CA_CONNECTION_LE_MASTER_DIRECTED);
            break;
        case ble_connection_master_whitelist:
            prim->connection_flags = 
                L2CA_CONFLAG_ENUM(L2CA_CONNECTION_LE_MASTER_WHITELIST);
            break;
        case ble_connection_slave_directed:
            prim->connection_flags = 
                L2CA_CONFLAG_ENUM(L2CA_CONNECTION_LE_SLAVE_DIRECTED);
            break;
        case ble_connection_slave_undirected:
            prim->connection_flags =
                L2CA_CONFLAG_ENUM(L2CA_CONNECTION_LE_SLAVE_UNDIRECTED);
            break;
        case ble_connection_slave_whitelist:
            prim->connection_flags = 
                L2CA_CONFLAG_ENUM(L2CA_CONNECTION_LE_SLAVE_WHITELIST);
            break;
        default:
            CL_DEBUG(("ble_connection_type %d not handled\n", req->conn_type));
            break;
    }

    /* Add flags to lock the ACL and to Time out the security scenario if it 
     * takes too long. 
     */
    prim->connection_flags |= L2CA_CONFLAG_LOCK_ACL;
    prim->connection_flags |= L2CA_CONFLAG_PAGE_TIMEOUT;

    BdaddrConvertTypedVmToBluestack(&prim->addrt, &req->taddr);

    prim->context = (uint16)req->theAppTask;

    switch(req->security)
    {
        case ble_security_encrypted:
            prim->security_requirements = 
                DM_SM_SECURITY_UNAUTHENTICATED_NO_BONDING;
            break;
        case ble_security_encrypted_bonded:
            prim->security_requirements = 
                DM_SM_SECURITY_UNAUTHENTICATED_BONDING;
            break;
        case ble_security_authenticated:
            prim->security_requirements =
                DM_SM_SECURITY_AUTHENTICATED_NO_BONDING;
            break;
        case ble_security_authenticated_bonded:
            prim->security_requirements =
                DM_SM_SECURITY_AUTHENTICATED_BONDING;
        default:
            CL_DEBUG(("ble_security_type %d not handled\n", req->security));
            break;
    }

    /* Not used for the REQ */
    prim->status = 0;
    
    VmSendDmPrim(prim);
}


/****************************************************************************
NAME    
    connectionHandleDmSmSecurityCfm

DESCRIPTION
    Handle the DM_SM_SECURITY_CFM message from Bluestack.

RETURNS
   void
*/
void connectionHandleDmSmSecurityCfm(DM_SM_SECURITY_CFM_T *cfm)
{
    MAKE_CL_MESSAGE(CL_DM_BLE_SECURITY_CFM);

    message->status = (cfm->status) ? fail : success;
    BdaddrConvertTypedBluestackToVm(&message->taddr, &cfm->addrt);

    MessageSend((Task)cfm->context, CL_DM_BLE_SECURITY_CFM, message);
}

/****************************************************************************
NAME    
    ConnectionSmBleIoCapabilityResponse

DESCRIPTION
    Populate and send the CL_INTERNAL_SM_IO_CAPABILITY_RESPONSE_RES message,
    specifically for BLE data.

RETURNS
   void
*/
void ConnectionSmBleIoCapabilityResponse(
        const typed_bdaddr*     taddr, 
        cl_sm_io_capability     io_capability, 
        uint16                  key_distribution,    
        bool                    force_mitm,
        uint8*                  oob_hash_c
        ) 
{
#ifdef CONNECTION_DEBUG_LIB
    if(taddr == NULL)
    {
       CL_DEBUG(("Out of range Bluetooth Address 0x%p\n", (void*)taddr)); 
    }
#endif
    {
        MAKE_CL_MESSAGE(CL_INTERNAL_SM_IO_CAPABILITY_REQUEST_RES);
        
        message->taddr = *taddr;
        message->io_capability = io_capability;

        if (
            message->io_capability == cl_sm_io_cap_no_input_no_output ||
            message->io_capability == cl_sm_reject_request
           )
            message->mitm = FALSE;
        else
            message->mitm = force_mitm;

        /* For BLE, there is only OOB hash c data, if it is there then MITM
         * is on. 
         */
        if(oob_hash_c)
        {
            message->mitm = TRUE;
            message->oob_data_present = DM_SM_OOB_DATA_HASHC_ONLY;
            message->oob_hash_c = PanicUnlessMalloc(CL_SIZE_OOB_DATA);
            memmove(message->oob_hash_c, oob_hash_c, CL_SIZE_OOB_DATA);
            message->oob_rand_r = NULL;
        }
        else
        {
            message->oob_data_present = DM_SM_OOB_DATA_NONE;
            message->oob_hash_c = NULL;
            message->oob_rand_r = NULL;
        }

        /* No keys - no bonding. Yes - deliberate assignment. */
        if ( (message->key_distribution = key_distribution) )
            message->bonding = TRUE;
        else
            message->bonding = FALSE;
        
        MessageSend(connectionGetCmTask(), CL_INTERNAL_SM_IO_CAPABILITY_REQUEST_RES, message);
    }
}

#else

static const int dummy;

#endif /* DISABLE_BLE */


