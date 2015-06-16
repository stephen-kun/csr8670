/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_gatt_server_bas.h

DESCRIPTION
    Implementation of the GATT Generic Access service
*/
#ifdef GATT_SERVER_ENABLED

#ifndef _SINK_GATT_SERVER_GAP_H_
#define _SINK_GATT_SERVER_GAP_H_

#include <gatt.h>
#include <connection.h>

#include <csrtypes.h>


/*
    Defines data structure required when a remote device wishes to read the GAP
    local name
*/
typedef struct
{
    bool    busy;
    uint16  cid;
    uint16  offset;
} gattGapReadName_t;


/*******************************************************************************
NAME    
    handle_gatt_service_access
    
DESCRIPTION
    Function to handle when the remote device wants to access the GATT service
    characteristic in the GAP GATT DB
*/
void handle_gatt_service_access(GATT_ACCESS_IND_T * ind);


/*******************************************************************************
NAME    
    handle_gap_service_access
    
DESCRIPTION
    Function to handle when the remote device wants to access the GAP service
    characteristic in the GAP GATT DB
*/
void handle_gap_service_access(GATT_ACCESS_IND_T * ind);


/*******************************************************************************
NAME    
    handle_device_name_access
    
DESCRIPTION
    Function to handle when the remote device wants to access the device name
    characteristic in the GAP GATT DB
*/
void handle_device_name_access(GATT_ACCESS_IND_T * ind);


/*******************************************************************************
NAME    
    respond_gap_local_name_req
    
DESCRIPTION
    Function that will be called after the CL returns with the local device name
    so it can be returned as a response to the GATT GAP read local name request.
*/
void respond_gap_local_name_req(CL_DM_LOCAL_NAME_COMPLETE_T * cfm);


/*******************************************************************************
NAME    
    handle_device_appearance_access
    
DESCRIPTION
    Function to handle when the remote device wants to access the device
    appearance characteristic in the GAP GATT DB
*/
void handle_device_appearance_access(GATT_ACCESS_IND_T * ind);


#endif /* _SINK_GATT_SERVER_GAP_H_ */

#endif /* GATT_SERVER_ENABLED */
