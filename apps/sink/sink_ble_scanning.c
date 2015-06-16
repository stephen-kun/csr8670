/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014

FILE NAME
    sink_ble_scanning.c

DESCRIPTION
    BLE Scanning functionality
*/

#ifdef BLE_ENABLED

/* Application includes */
#include "sink_ble_scanning.h"
#include "sink_gap_ad_types.h"
#include "sink_debug.h"

/* Library includes */
#include <connection.h>
#include <gatt.h>

/* Firmware includes */
#include <csrtypes.h>


/* Macro for BLE AD Data Debug */
#ifdef DEBUG_BLE
#include <stdio.h>
#define BLE_SCAN_DEBUG(x) DEBUG(x)
#else
#define BLE_SCAN_DEBUG(x) 
#endif


/****************************************************************************/
void ble_scan_allow_hid_devices(void)
{
    uint8 ble_filter[] = {GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE & 0xFF, GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE >> 8};
    BLE_SCAN_DEBUG(("BLE: Add HID scan filter\n"));
    ConnectionBleAddAdvertisingReportFilter(AD_TYPE_SERVICE_UUID_16BIT_LIST, sizeof ble_filter, sizeof ble_filter, ble_filter);
}


/****************************************************************************/
void ble_clear_scan_data(void)
{
    BLE_SCAN_DEBUG(("BLE: Clear scan filters\n"));
    ConnectionBleClearAdvertisingReportFilter();
}


/****************************************************************************/
void start_ble_scanning(void)
{
    /* Begin scanning, this will allow advertisements from HID BLE devices to be recieved by the application */
    BLE_SCAN_DEBUG(("BLE: Start scanning\n"));
    ConnectionDmBleSetScanEnable(TRUE);
}


/****************************************************************************/
void stop_ble_scanning(void)
{
    /* Stop scanning, this will stop advertisements from HID BLE devices to be recieved by the application */
    BLE_SCAN_DEBUG(("BLE: Stop scanning\n"));
    ConnectionDmBleSetScanEnable(FALSE);
}


#else /* #ifdef BLE_ENABLED */

#include <csrtypes.h>
static const uint16 sink_ble_scanning = 0;

#endif /* #ifdef BLE_ENABLED */
