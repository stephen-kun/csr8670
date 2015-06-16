/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014

FILE NAME
    sink_gatt_server_bas.c

DESCRIPTION
    Implementation of the GATT Generic Access service
*/
#ifdef GATT_SERVER_ENABLED

/* Application includes */
#include "sink_gatt_server_gap.h"
#include "sink_private.h"
#include "sink_gatt.h"
#include "sink_gatt_db.h"

/* Library includes */
#include <gatt.h>
#include <power.h>

/* Firmware includes */
#include <csrtypes.h>

/* Macro for GATT SERVER Debug */
#ifdef DEBUG_GATT
#include <stdio.h>
#define GATT_SERVER_GAP_DEBUG(x) DEBUG(x)
#else
#define GATT_SERVER_GAP_DEBUG(x) 
#endif


/******************************************************************************/
void handle_gatt_service_access(GATT_ACCESS_IND_T * ind)
{
    GATT_SERVER_GAP_DEBUG(("GATT SERVICE REQ [%x]\n", ind->flags));
    GattAccessResponse(ind->cid, ind->handle, gatt_status_success, 0, 0);
}


/******************************************************************************/
void handle_gap_service_access(GATT_ACCESS_IND_T * ind)
{
    GATT_SERVER_GAP_DEBUG(("GAP SERVICE REQ [%x]\n", ind->flags));
    GattAccessResponse(ind->cid, ind->handle, gatt_status_success, 0, 0);
}


/******************************************************************************/
void handle_device_name_access(GATT_ACCESS_IND_T * ind)
{
    /* Can only read this characteristic */
    if (ind->flags & ATT_ACCESS_READ)
    {
        if (theSink.rundata->gatt.server.dev_name_req.busy)
        {
            /* Is there an offset? If so, device wants to read long name */
            
            
            /* Busy processing a GATT access request for the local name - Supply empty response */
            GattAccessResponse(ind->cid, HANDLE_DEVICE_NAME, gatt_status_success, 0, 0);
        }
        else
        {
            /* Inquire CL for the local name, wait for a response from CL then respond to the GATT request */
            theSink.rundata->gatt.server.dev_name_req.busy   = TRUE;
            theSink.rundata->gatt.server.dev_name_req.cid    = ind->cid;
            theSink.rundata->gatt.server.dev_name_req.offset = ind->offset;
            ConnectionReadLocalName(&theSink.rundata->gatt.task);
        }
    }
    else
    {
        GATT_SERVER_GAP_DEBUG(("GATT REQ: Device Name FLAGS[%x]\n", ind->flags));
        GattAccessResponse(ind->cid, HANDLE_DEVICE_NAME, gatt_status_success, 0, 0);
    }
}


/******************************************************************************/
void respond_gap_local_name_req(CL_DM_LOCAL_NAME_COMPLETE_T * cfm)
{
    /* Should only get this as part of a request to get the device name */
    if (theSink.rundata->gatt.server.dev_name_req.busy)
    {
        /* Respond to the request with the device name */
        GattAccessResponse(theSink.rundata->gatt.server.dev_name_req.cid, HANDLE_DEVICE_NAME, gatt_status_success, (cfm->size_local_name - theSink.rundata->gatt.server.dev_name_req.offset), (cfm->local_name + theSink.rundata->gatt.server.dev_name_req.offset));
    }        
    /* Tidy everything up ready for a new request to be actioned */
    theSink.rundata->gatt.server.dev_name_req.cid  = 0;
    theSink.rundata->gatt.server.dev_name_req.busy = FALSE;
}


/******************************************************************************/
void handle_device_appearance_access(GATT_ACCESS_IND_T * ind)
{
    /* Can only read this characteristic */
    if (ind->flags & ATT_ACCESS_READ)
    {
        /* Respond to the request with the appearance (need to pack it into a uint8 array) */
        uint16 appearance = gap_appearance_unknown;
        uint8  packed_appearance[2];
        packed_appearance[0] = (appearance << 8) & 0xF;
        packed_appearance[2] = appearance & 0xFF;
        GattAccessResponse(ind->cid, HANDLE_DEVICE_APPEARANCE, gatt_status_success, 2, packed_appearance);
    }
    else
    {
        GATT_SERVER_GAP_DEBUG(("GATT REQ: Device Name FLAGS[%x]\n", ind->flags));
        GattAccessResponse(ind->cid, HANDLE_DEVICE_APPEARANCE, gatt_status_success, 0, 0);
    }
}

#else
unsigned const sink_gatt_server_gap=0;
#endif /* #ifdef GATT_SERVER_ENABLED */
