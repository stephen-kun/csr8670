/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014

FILE NAME
    sink_gatt_server.c

DESCRIPTION
    Framework for GATT Services when device is configured as a GATT Server
*/
#ifdef GATT_SERVER_ENABLED

/* Application includes */
#include "sink_gatt_server.h"
#include "sink_private.h"
#include "sink_debug.h"
#include "sink_gatt_server_bas.h"
#include "sink_gatt.h"
#include "sink_gatt_db.h"
#ifdef BLE_ENABLED
#include "sink_ble_advertising.h"
#endif

/* Library includes */
#include <connection.h>
#include <gatt.h>

/* Firmware includes */
#include <stdlib.h>
#include <string.h>


/* Macro for GATT SERVER Debug */
#ifdef DEBUG_GATT
#include <stdio.h>
#define GATT_SERVER_DEBUG(x) DEBUG(x)
#else
#define GATT_SERVER_DEBUG(x) 
#endif


typedef enum
{
    GATT_CLIENT_DEVICE_ADDED,
    GATT_CLIENT_DEVICE_KNOWN,
    GATT_CLIENT_MAX_DEVICES

} gattAddDeviceCode_t;


/*******************************************************************************
FUNCTION
    add_client_device
    
DESCRIPTION
    Helper function to add a client device to the known devices list
*/  
static gattAddDeviceCode_t add_client_device(uint16 cid)
{
    /* Ensure device is not already known */
    uint16 i;
    for (i=0; i<MAX_GATT_CLIENT_DEVICES; i++)
    {
        if (theSink.rundata->gatt.server.devs[i].cid == cid)
        {
            GATT_SERVER_DEBUG(("GATT: Client[%x] already known\n", cid));
            return GATT_CLIENT_DEVICE_KNOWN;
        }
    }
    
    /* Add device (if possible) */
    for (i=0; i<MAX_GATT_CLIENT_DEVICES; i++)
    {
        if (theSink.rundata->gatt.server.devs[i].state == gatt_client_state_disconnected)
        {
            /* Add new device */
            theSink.rundata->gatt.server.devs[i].cid   = cid;
            theSink.rundata->gatt.server.devs[i].state = gatt_client_state_connected;
            return GATT_CLIENT_DEVICE_ADDED;
        }
    }
    
    return GATT_CLIENT_MAX_DEVICES;
}


/*******************************************************************************
FUNCTION
    remove_client_device
    
DESCRIPTION
    Helper function to remove a client device from the known devices list
*/  
static void remove_client_device(uint16 cid)
{
    /* Find the device in the known devices list and remove it */
    uint16 i;
    for (i=0; i<MAX_GATT_CLIENT_DEVICES; i++)
    {
        if (theSink.rundata->gatt.server.devs[i].cid == cid)
        {
            theSink.rundata->gatt.server.devs[i].cid   = 0;
            theSink.rundata->gatt.server.devs[i].state = gatt_client_state_disconnected;
        }
    }
}


/******************************************************************************/
void server_handle_gatt_init_cfm(GATT_INIT_CFM_T * cfm)
{
    if (cfm->status == gatt_status_success)
    {
        theSink.rundata->gatt.initialised = TRUE;
    }
    
    if (cfm->status == gatt_status_success)
    {
        /* Set the BLE role to SLAVE and wait for a connection from a remote device */
        GattConnectRequest(&theSink.rundata->gatt.task, NULL, gatt_connection_ble_slave_undirected, FALSE);        
    }
}


/******************************************************************************/
void server_handle_gatt_connect_cfm(GATT_CONNECT_CFM_T * cfm)
{
    switch(cfm->status)
    {
        case gatt_status_initialising:
        {
            GATT_SERVER_DEBUG(("GATT: Connection initialising\n"));
            #if defined(BLE_ENABLED)
            {
                /* Start Advertising so a remote device can find and connect */
                start_ble_advertising();
            }
            #endif
        }
        break;
        case gatt_status_success:
        {
            /* Ensure device was able to be added */
            if (add_client_device(cfm->cid) == GATT_CLIENT_DEVICE_ADDED)
            {
                GATT_SERVER_DEBUG(("GATT: Connect success - stop advertising\n"));
                
                #if defined(BLE_ENABLED)
                {
                    stop_ble_advertising();
                }
                #endif
            }
        }
        break;
        default:
        {
            GATT_SERVER_DEBUG(("GATT: Connect failed %x\n", cfm->status));
        }
    }
}


/******************************************************************************/
void server_handle_gatt_disconnect_ind(GATT_DISCONNECT_IND_T * ind)
{
    GATT_SERVER_DEBUG(("GATT: Disconnected\n"));
    
    /* Remove device from known devices list */
    remove_client_device(ind->cid);
    
    #if defined(BLE_ENABLED)
    {
        start_ble_advertising();
    }
    #endif
    
    GATT_SERVER_DEBUG(("GATT: Wait for a connection from a remote device\n"));
    GattConnectRequest(&theSink.rundata->gatt.task, NULL, gatt_connection_ble_slave_undirected, FALSE);
}


/******************************************************************************/
void server_handle_gatt_access_ind(GATT_ACCESS_IND_T * ind)
{
    /* Which GATT declaration/characteristic/descriptor has been requested? */
    bool is_valid = FALSE;
    
    /* Was the GATT characteristic requested? */
    if (ind->handle == HANDLE_GATT_SERVICE)
    {
        handle_gatt_service_access(ind);
        is_valid = TRUE;
    }
    
    /* Was a GAP characteristic requested? */
    if (ind->handle == HANDLE_GAP_SERVICE)
    {
        handle_gap_service_access(ind);
        is_valid = TRUE;
    }
    else if (ind->handle == HANDLE_DEVICE_NAME)
    {
        handle_device_name_access(ind);
        is_valid = TRUE;
    }
    else if (ind->handle == HANDLE_DEVICE_APPEARANCE)
    {
         handle_device_appearance_access(ind);
         is_valid = TRUE;
    }
    
#ifdef GATT_SERVER_BAS_ENABLED
    /* Was a BAS characteristic requested? */
    if (ind->handle == HANDLE_BATTERY_SERVICE)
    {
        handle_battery_service_access(ind);
        is_valid = TRUE;
    }
    else if (ind->handle == HANDLE_BATTERY_LEVEL)
    {
        handle_battery_level_access(ind);
        is_valid = TRUE;
    }
    else if (ind->handle == HANDLE_BATTERY_LEVEL_CLIENT_CONFIG)
    {
        handle_battery_level_c_cfg_access(ind);
        is_valid = TRUE;
    }
#endif
    
    if (!is_valid)
    {
        GATT_SERVER_DEBUG(("ERROR : GATT_ACCESS_IND cid[%x] handle[%x] flags[%x] offset[%x] size[%x] value[%x]\n", ind->cid, ind->handle, ind->flags, ind->offset, ind->size_value, ind->value[0]));
    }
}


/******************************************************************************/
void server_handle_gatt_indication_cfm(GATT_INDICATION_CFM_T * ind)
{
    /* Which service is currently sending an indication? */
    switch(theSink.rundata->gatt.server.indication)
    {
        case indication_none:
        {
            GATT_SERVER_DEBUG(("GATT_INDICATION_CFM : ERROR, no service is doing indication\n"));
        }
        break;
        case indication_battery_level:
        {
            #ifdef GATT_SERVER_BAS_ENABLED
            {
                handle_battery_level_indication_cfm(ind);
            }
            #endif
        }
        break;
    }
}


/******************************************************************************/
void disconnect_all_gatt_clients(void)
{
    /* Disconnect all connected devices */
    uint16 i;
    for (i=0; i<MAX_GATT_CLIENT_DEVICES; i++)
    {
        if (theSink.rundata->gatt.server.devs[i].state != gatt_client_state_disconnected)
        {
            GattDisconnectRequest(theSink.rundata->gatt.server.devs[i].cid);
            /* Handle Disconnect IND will remove the device from known devices list */
        }
    }
}


#else /* GATT_SERVER_ENABLED */

#include <csrtypes.h>
static const uint16 gatt_server_dummy = 0;

#endif /* GATT_SERVER_ENABLED */
