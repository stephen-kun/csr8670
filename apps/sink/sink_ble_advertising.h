/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_ble_advertising.h

DESCRIPTION
    BLE Advertising functionality
*/

#ifndef _SINK_BLE_ADVERTISING_H_
#define _SINK_BLE_ADVERTISING_H_

/* Library includes */
#include <connection.h>

/* Firmware includes */
#include <csrtypes.h>


#if defined(GATT_SERVER_ENABLED) && defined(BLE_ENABLED)


#define MAX_AD_DATA_SIZE_IN_OCTECTS (0x1F)   /* AD Data max size = 31 octets (defined by BT spec) */
#define AD_DATA_HEADER_SIZE         (0x02)   /* AD header{Octet[0]=length, Octet[1]=Tag} AD data{Octets[2]..[n]} */
#define OCTETS_PER_SERVICE          (0x02)   /* 2 octets per uint16 service UUID */


/*
  Defines structure used for setting up the advertisement data for the device 
*/
typedef struct
{
    uint8*  ptr;    /* Pointer to AD Data */
    uint16  size;   /* Size of AD Data */
} builtAdData_t;


/*
  Defines the BLE advertising modes that can be used
*/
typedef enum
{
    le_limited_discoverable_mode = 0x1,
    le_general_discoverable_mode = 0x2,
    br_edr_not_supported = 0x4,
    le_and_br_to_same_device_controller = 0x8,
    le_and_br_to_same_device_host = 0x10
} advertisingFlags_t;


/*******************************************************************************
NAME    
    setup_ble_ad_data
    
DESCRIPTION
    Function to setup the BLE Advertising dat for the device
*/
void setup_ble_ad_data(uint16 size_local_name, uint8 *local_name);


/*******************************************************************************
NAME    
    handle_set_ble_ad_data_cfm
    
DESCRIPTION
    Function to handle when BLE advertising data has been registered with CL
*/
void handle_set_ble_ad_data_cfm(CL_DM_BLE_SET_ADVERTISING_DATA_CFM_T * cfm);


/*******************************************************************************
NAME    
    start_ble_advertising

DESCRIPTION
    Function to start advertising the registered BLE AD Data
    Returns FALSE if advertising data has not yet been registered
    Returns TRUE if advertising was started
*/
bool start_ble_advertising(void);


/*******************************************************************************
NAME    
    stop_ble_advertising

DESCRIPTION
    Function to stop advertising the registered BLE AD Data
*/
void stop_ble_advertising(void);

#endif /* defined(GATT_SERVER_ENABLED) && defined(BLE_ENABLED) */


#if defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED)

/*
    Defines the advertising data (from a remote device) that the Sink
    application is interested in
*/
typedef struct
{
    uint8   flags;          /* Indicates which BLE modes the device supports */
    uint16  appearance;     /* The appearance of the device (if supplied) */
    uint16  service;        /* The primary service of the device (if supplied) */
} bleAdvertisingData_t;


/*******************************************************************************
NAME
    handle_ble_advertising_report

DESCRIPTION
    Function to handle when an ADVERTISING report is recieved from a remote
    device
*/
void handle_ble_advertising_report(CL_DM_BLE_ADVERTISING_REPORT_IND_T * ind);


#endif /* defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED) */

#endif /* _SINK_BLE_ADVERTISING_H_ */
