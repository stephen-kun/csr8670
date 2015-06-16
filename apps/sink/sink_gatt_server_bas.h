/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_gatt_server_bas.h

DESCRIPTION
    Implementation of the GATT Battery Service
*/
#ifdef GATT_SERVER_ENABLED

#ifndef _SINK_GATT_SERVER_BAS_H_
#define _SINK_GATT_SERVER_BAS_H_

/* Library includes */
#include <gatt.h>

/* Firmware includes */
#include <csrtypes.h>


/*
    Defines runtime data for the battery service
*/
typedef struct
{
    uint16                  battery_notify;     /* Stores current state for battery level notifications */
    uint8                   battery_level;      /* Stores battery level - updated when requested */
    
} gattBatteryService_t;


/*******************************************************************************
NAME    
    handle_battery_service_access
    
DESCRIPTION
    Function to handle when the remote device wants to access the service
    declaration in the BAS GATT DB
*/
void handle_battery_service_access(GATT_ACCESS_IND_T * ind);


/*******************************************************************************
NAME    
    handle_battery_level_request
    
DESCRIPTION
    Function to handle when the remote device wants to access the battery
    level characteristic in the BAS GATT DB
*/
void handle_battery_level_access(GATT_ACCESS_IND_T * ind);


/*******************************************************************************
NAME    
    handle_battery_level_request
    
DESCRIPTION
    Function to handle when the remote device wants to access the battery
    level client configuration descriptor in the BAS GATT DB
*/
void handle_battery_level_c_cfg_access(GATT_ACCESS_IND_T * ind);


/*******************************************************************************
NAME    
    send_battery_level_notification_to_device
    
DESCRIPTION
    Function to send the current battery level notification to a remote device
*/
void send_battery_level_notification_to_device(uint16 cid);


/*******************************************************************************
NAME    
    send_battery_level_notification_to_device
    
DESCRIPTION
    Function to send the current battery level indication to a remote device
*/
void send_battery_level_indication_to_device(uint16 cid);


/*******************************************************************************
NAME    
    handle_battery_level_indication_cfm
    
DESCRIPTION
    Function to handle the Indication response when the battery level indication
    is being sent to the remote device.
*/
void handle_battery_level_indication_cfm(GATT_INDICATION_CFM_T * ind);


#endif /* _SINK_GATT_SERVER_BAS_H_ */

#endif /* GATT_SERVER_ENABLED */
