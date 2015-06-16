/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014

FILE NAME
    sink_gatt_client.c

DESCRIPTION
    Framework for GATT Services when device is configured as a GATT Client
*/
#ifdef GATT_CLIENT_ENABLED

/* Application includes */
#include "sink_gatt_client.h"
#include "sink_ble_remote_control.h"
#include "sink_ble_scanning.h"
#include "sink_private.h"
#include "sink_debug.h"
#ifdef BLE_ENABLED
#include "sink_ble_remote_control.h"
#endif

/* Library includes */
#include <connection.h>
#include <gatt.h>

/* Macro for GATT SERVER Debug */
#ifdef DEBUG_GATT
#include <stdio.h>
#define GATT_CLIENT_DEBUG(x) DEBUG(x)
#else
#define GATT_CLIENT_DEBUG(x) 
#endif


/******************************************************************************/
void setup_gatt_client_tasks(uint32 gatt_services)
{
    bool init_gatt = FALSE;
    
    GATT_CLIENT_DEBUG(("GATT : Setup GATT Client tasks\n"));
    
    /* Which GATT services have been configured? */
    if (gatt_services & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            GATT_CLIENT_DEBUG(("GATT : Init BLE HOGP\n"));
            initBleHidInputMonitor( &theSink.rundata->inputManager.config->input_timers );
            init_gatt = TRUE;
        }
        #else
        {
            GATT_CLIENT_DEBUG(("GATT : Cannot init HOGP, [BLE is disabled]\n"));
        }
        #endif
    }
    
    if (gatt_services & GATT_FLAG_CLIENT_BATTERY)
    {
        GATT_CLIENT_DEBUG(("GATT : Init GATT Battery\n"));
        init_gatt = TRUE;
        /* TODO : Implement Battery Service Parser */
    }
    
    if (init_gatt)
    {
        GattInit(&theSink.rundata->gatt.task, 0, NULL);
    }
}


/******************************************************************************/
void disconnect_all_gatt_servers(void)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            GATT_CLIENT_DEBUG(("GATT: Disconnect all connected HOGP devices\n"));
            bleDisconnectAllConnectedRemotes(FALSE);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_init_cfm(GATT_INIT_CFM_T * cfm)
{
    if (cfm->status == gatt_status_success)
    {
        theSink.rundata->gatt.initialised = TRUE;
    }
    
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            GATT_CLIENT_DEBUG(("GATT: Enable scanning for HID Devices\n"));
            ble_scan_allow_hid_devices();
            start_ble_scanning();
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_connect_cfm(GATT_CONNECT_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattConnectCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_discover_all_primary_services_cfm(GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattDiscoverAllPrimaryServicesCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_discover_all_characteristics_cfm(GATT_DISCOVER_ALL_CHARACTERISTICS_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattDiscoverAllCharacteristicsCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_discover_all_characteristic_descriptors_cfm(GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattDiscoverAllCharacteristicDescriptorsCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_find_included_services_cfm(GATT_FIND_INCLUDED_SERVICES_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattFindIncludedServicesCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_read_characteristic_value_cfm(GATT_READ_CHARACTERISTIC_VALUE_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattReadCharacteristicValueCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_read_long_characteristic_value_cfm(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattReadLongCharacteristicValueCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_write_without_response_cfm(GATT_WRITE_WITHOUT_RESPONSE_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattWriteWithoutResponseCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_write_characteristic_value_cfm(GATT_WRITE_CHARACTERISTIC_VALUE_CFM_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattWriteCharacteristicCfm(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_notification_ind(GATT_NOTIFICATION_IND_T * cfm)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattNotificationInd(cfm);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_indication_ind(GATT_INDICATION_IND_T * ind)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattIndicationInd(ind);
        }
        #endif
    }
}


/******************************************************************************/
void client_handle_gatt_disconnect_ind(GATT_DISCONNECT_IND_T * ind)
{
    /* Depending on which client profile is enabled, depends on which client task to handle the message */
    if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
    {
        #ifdef BLE_ENABLED
        {
            hogpHandleGattDisconnectInd(ind);
        }
        #endif
    }
}


#else /* GATT_CLIENT_ENABLED */

#include <csrtypes.h>
static const uint16 gatt_client_dummy = 0;

#endif /* GATT_CLIENT_ENABLED */
