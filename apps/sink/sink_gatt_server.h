/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_gatt_server.h

DESCRIPTION
    Framework for GATT Services when device is configured as a GATT Server
*/
#ifdef GATT_SERVER_ENABLED

#ifndef _SINK_GATT_SERVER_H_
#define _SINK_GATT_SERVER_H_

/* Application includes */
#include "sink_gatt_server_gap.h"
#include "sink_gatt_server_bas.h"

/* Library includes */
#include <gatt.h>

/* Firmware includes */
#include <csrtypes.h>


#define GATT_CHARACTERISTIC_APPEARANCE_UNKNOWN 0x0000

#define MAX_GATT_CLIENT_DEVICES 0x1     /* Maximum number of connected GATT clients supported at any time */

/*
    Defines all characteristics that can be configured for Indications, used
    to store which indication is currently in progress.
*/
typedef enum
{
    indication_none=0,          /* No indication in progress */
    indication_battery_level    /* Battery Level indication in progress */
    
} gattIndicationChars_t;


/*
    Defines state of connected GATT client
*/
typedef enum
{
    gatt_client_state_disconnected,
    gatt_client_state_connected
    
} gattClientState_t;


/*
    Defines the data structure for connected GATT client devices
*/
typedef struct
{
    uint16              cid;
    gattClientState_t   state;
    
} gattClientDevice_t;


/*
    Defines the structure used to store runtime data required to implement
    GATT services.
*/
typedef struct
{
    uint16                  size_ad_data;       /* Size of the advertising data */
    uint8                   *ad_data;           /* Advertising data */
    bool                    ad_data_valid;      /* Flag set to ensure AD Data has been registered successfully & can be advertised */
    
    gattIndicationChars_t   indication;         /* When an indication is being sent, this is set to the characteristic being indicated */
    
    gattGapReadName_t       dev_name_req;       /* When a remote device is reading the local name, this data is required */
    
    gattClientDevice_t      devs[MAX_GATT_CLIENT_DEVICES];  /* Store runtime data for each connected GATT client device */
    gattBatteryService_t    bas_service;                    /* Store runtime data for BAS service */

} gattServerRuntimeData_t;


/*******************************************************************************
NAME    
    server_handle_gatt_init_cfm
    
DESCRIPTION
    Function to handle the GATT_INIT_CFM message
*/
void server_handle_gatt_init_cfm(GATT_INIT_CFM_T * cfm);


/*******************************************************************************
NAME    
    server_handle_gatt_connect_cfm
    
DESCRIPTION
    Function to handle the GATT_CONNECT_CFM message
*/
void server_handle_gatt_connect_cfm(GATT_CONNECT_CFM_T * cfm);


/*******************************************************************************
NAME    
    server_handle_gatt_disconnect_ind
    
DESCRIPTION
    Function to handle the GATT_DISCONNECT_IND message
*/
void server_handle_gatt_disconnect_ind(GATT_DISCONNECT_IND_T * ind);


/*******************************************************************************
NAME    
    server_handle_gatt_access_ind
    
DESCRIPTION
    Function to handle when a remote device wants to access an element of the 
    GATT Database
*/
void server_handle_gatt_access_ind(GATT_ACCESS_IND_T * req);


/*******************************************************************************
NAME    
    server_handle_gatt_indication_cfm
    
DESCRIPTION
    Function to handle when an indication message is recieved from the GATT lib
*/
void server_handle_gatt_indication_cfm(GATT_INDICATION_CFM_T * ind);


/*******************************************************************************
NAME    
    disconnect_all_gatt_clients
    
DESCRIPTION
    Function to disconnect all connected GATT clients
*/
void disconnect_all_gatt_clients( void );




#endif /* GATT_SERVER_ENABLED */

#endif /* _SINK_GATT_SERVER_H_ */
