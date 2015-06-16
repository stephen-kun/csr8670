/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    dm_ble_random_address.c      

DESCRIPTION
    This file contains functions for setting the Bluetooth low energy random
    address.
NOTES

*/

#ifndef DISABLE_BLE

#include "dm_ble_random_address.h"
#include "common.h"
#include "bdaddr.h"

#include <vm.h>

/****************************************************************************
NAME    
    ConnectionDmBleConfigureLocalAddressReq

DESCRIPTION
    Configure the local device address used for BLE connections

RETURNS
   void
*/
void ConnectionDmBleConfigureLocalAddressReq(
        ble_local_addr_type     addr_type,
        const typed_bdaddr*     static_taddr
        )
{
    if (connectionGetBtVersion() < bluetooth4_0)
    {
        CL_DEBUG(("Bluestack does not support low energy (BT 4.0)\n"));
    }
    else if (addr_type >= ble_local_addr_last)
    {
        CL_DEBUG(("addr_type parameter out of range: %d\n", addr_type));
    }
    else
    {
        MAKE_PRIM_T(DM_SM_CONFIGURE_LOCAL_ADDRESS_REQ);

        switch (addr_type)
        {
            case ble_local_addr_write_static:
                prim->set_permanent_address_type = 
                    DM_SM_ADDRESS_WRITE_STATIC;
                break;
            case ble_local_addr_generate_static:
                prim->set_permanent_address_type = 
                    DM_SM_ADDRESS_GENERATE_STATIC;
                break;
            case ble_local_addr_generate_non_resolvable: 
                prim->set_permanent_address_type = 
                    DM_SM_ADDRESS_GENERATE_NON_RESOLVABLE;
                break;
            case ble_local_addr_generate_resolvable:
                prim->set_permanent_address_type = 
                    DM_SM_ADDRESS_GENERATE_RESOLVABLE;
                break;
            default:
               /* ble_local_addr_last handled above. */
               break;
        }

        if (static_taddr)
        {
            BdaddrConvertTypedVmToBluestack(&prim->static_addrt, static_taddr);
        }
        else
        {
            prim->static_addrt.type = TBDADDR_INVALID;
            memset(&prim->static_addrt.addr, 0, sizeof(BD_ADDR_T));
        }

        /* This field is not used by Bluestack. */
        prim->privacy = 1;

        VmSendDmPrim(prim);
    }
}


/****************************************************************************
NAME    
    ConnectionDmBleConfigureLocalAddressReq

DESCRIPTION
    Configure the local device address used for BLE connections

RETURNS
   void
*/
void connectionHandleDmSmConfigureLocalAddressCfm(
        DM_SM_CONFIGURE_LOCAL_ADDRESS_CFM_T* cfm
        )
{
    MAKE_CL_MESSAGE(CL_DM_BLE_CONFIGURE_LOCAL_ADDRESS_CFM);
    message->status = (cfm->status) ? fail : success;

    switch (cfm->permanent_address_type)
    {
        case DM_SM_ADDRESS_WRITE_STATIC:
            message->addr_type = ble_local_addr_write_static;
            break;
        case DM_SM_ADDRESS_GENERATE_STATIC:
            message->addr_type = ble_local_addr_generate_static;
            break;
        case DM_SM_ADDRESS_GENERATE_NON_RESOLVABLE:
            message->addr_type = ble_local_addr_generate_non_resolvable;
            break;
        case DM_SM_ADDRESS_GENERATE_RESOLVABLE:
            message->addr_type = ble_local_addr_generate_resolvable;
            break;
        default:
            CL_DEBUG((
                        "DM_SM_PERMANENT_ADDRESS_T %d not handled\n", 
                        cfm->permanent_address_type 
                     ));
            break;
    }

    BdaddrConvertTypedBluestackToVm(&message->random_taddr, &cfm->random_addrt);

    MessageSend(
            connectionGetAppTask(), 
            CL_DM_BLE_CONFIGURE_LOCAL_ADDRESS_CFM,
            message
            );
}

#else

#include <bdaddr_.h>

#endif /* DISABLE_BLE */

