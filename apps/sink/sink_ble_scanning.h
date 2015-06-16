/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_ble_advertising.h

DESCRIPTION
    BLE Advertising functionality
*/

#ifdef BLE_ENABLED

#ifndef _SINK_BLE_SCANNING_H_
#define _SINK_BLE_SCANNING_H_


/****************************************************************************
NAME    
    ble_scan_allow_hid_devices
    
DESCRIPTION
    Function to allow devices advertising the HID Service to be scanned
*/
void ble_scan_allow_hid_devices(void);


/****************************************************************************
NAME    
    ble_clear_scan_data
    
DESCRIPTION
    Function to clear all scan filters
*/
void ble_clear_scan_data(void);


/****************************************************************************
NAME    
    start_ble_scanning
    
DESCRIPTION
    Function to enable BLE scanning
*/
void start_ble_scanning(void);


/****************************************************************************
NAME    
    stop_ble_scanning
    
DESCRIPTION
    Function to disable BLE scanning
*/
void stop_ble_scanning(void);


#endif /* _SINK_BLE_SCANNING_H_ */

#endif /* #ifdef BLE_ENABLED */
