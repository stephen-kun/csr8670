/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_gatt_client.h

DESCRIPTION
    Framework for GATT Services when device is configured as a GATT Client
*/
#ifdef GATT_CLIENT_ENABLED

#ifndef _SINK_GATT_CLIENT_H_
#define _SINK_GATT_CLIENT_H_

/* Library includes */
#include <gatt.h>

/* Firmware includes */
#include <csrtypes.h>


/* GATT Client Flags used to indicate which GATT client services are supported on the device */
#define GATT_FLAG_CLIENT_HOGP           0x1
#define GATT_FLAG_CLIENT_BATTERY        0x2


/*******************************************************************************
NAME    
    setup_gatt_client_tasks
    
DESCRIPTION
    Function to setup the GATT client tasks that are configured for the device.

PARAMETERS
    gatt_services - configured list of GATT services that are supported by the
                    device.
*/
void setup_gatt_client_tasks(uint32 gatt_services);


/*******************************************************************************
NAME    
    disconnect_all_gatt_servers
    
DESCRIPTION
    Function to disconnect all connected GATT servers
*/
void disconnect_all_gatt_servers(void);


/*******************************************************************************
NAME    
    client_handle_gatt_init_cfm
    
DESCRIPTION
    Function to handle the GATT_INIT_CFM message
*/
void client_handle_gatt_init_cfm(GATT_INIT_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_connect_cfm
    
DESCRIPTION
    Function to handle the GATT_CONNECT_CFM message
*/
void client_handle_gatt_connect_cfm(GATT_CONNECT_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_discover_all_primary_services_cfm
    
DESCRIPTION
    Function to handle the GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM message
*/
void client_handle_gatt_discover_all_primary_services_cfm(GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_discover_all_characteristics_cfm
    
DESCRIPTION
    Function to handle the GATT_DISCOVER_ALL_CHARACTERISTICS_CFM message
*/
void client_handle_gatt_discover_all_characteristics_cfm(GATT_DISCOVER_ALL_CHARACTERISTICS_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_discover_all_characteristic_descriptors_cfm
    
DESCRIPTION
    Function to handle the GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM message
*/
void client_handle_gatt_discover_all_characteristic_descriptors_cfm(GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_find_included_services_cfm
    
DESCRIPTION
    Function to handle the GATT_FIND_INCLUDED_SERVICES_CFM message
*/
void client_handle_gatt_find_included_services_cfm(GATT_FIND_INCLUDED_SERVICES_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_read_characteristic_value_cfm
    
DESCRIPTION
    Function to handle the GATT_READ_CHARACTERISTIC_VALUE_CFM message
*/
void client_handle_gatt_read_characteristic_value_cfm(GATT_READ_CHARACTERISTIC_VALUE_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_read_long_characteristic_value_cfm
    
DESCRIPTION
    Function to handle the GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM message
*/
void client_handle_gatt_read_long_characteristic_value_cfm(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_write_without_response_cfm
    
DESCRIPTION
    Function to handle the GATT_WRITE_WITHOUT_RESPONSE_CFM message
*/
void client_handle_gatt_write_without_response_cfm(GATT_WRITE_WITHOUT_RESPONSE_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_write_characteristic_value_cfm
    
DESCRIPTION
    Function to handle the GATT_WRITE_CHARACTERISTIC_VALUE_CFM message
*/
void client_handle_gatt_write_characteristic_value_cfm(GATT_WRITE_CHARACTERISTIC_VALUE_CFM_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_notification_ind
    
DESCRIPTION
    Function to handle the GATT_NOTIFICATION_IND message
*/
void client_handle_gatt_notification_ind(GATT_NOTIFICATION_IND_T * cfm);


/*******************************************************************************
NAME    
    client_handle_gatt_indication_ind
    
DESCRIPTION
    Function to handle the GATT_INDICATION_IND message
*/
void client_handle_gatt_indication_ind(GATT_INDICATION_IND_T * ind);

                        
/*******************************************************************************
NAME    
    client_handle_gatt_disconnect_ind
    
DESCRIPTION
    Function to handle the GATT_DISCONNECT_IND message
*/
void client_handle_gatt_disconnect_ind(GATT_DISCONNECT_IND_T * ind);


#endif /* _SINK_GATT_CLIENT_H_ */

#endif /* GATT_CLIENT_ENABLED */
