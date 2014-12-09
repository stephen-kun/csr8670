/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    dm_ble_random_address.h      

DESCRIPTION
    This file contains the prototypes for BLE DM Random Address functions.

NOTES

*/

#include "connection.h"
#include "connection_private.h"

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
        );
