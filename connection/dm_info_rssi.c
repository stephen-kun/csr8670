/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_info_rssi.c        

DESCRIPTION
    This file contains the management entity responsible for arbitrating 
    access to functionality in BlueStack that provides information on
    the setup of the local device or about the link to the remote device.

NOTES

*/


/****************************************************************************
    Header files
*/
#include "connection.h"
#include "connection_private.h"


/*****************************************************************************/
void ConnectionGetRssi(Task theAppTask, Sink sink)
{
    /* All requests are sent through the internal state handler */    
    MAKE_CL_MESSAGE(CL_INTERNAL_DM_READ_RSSI_REQ);
    message->theAppTask = theAppTask;
    message->sink = sink;
    MessageSend(connectionGetCmTask(), CL_INTERNAL_DM_READ_RSSI_REQ, message);
}

/*****************************************************************************/
void ConnectionGetRssiBdaddr(Task theAppTask, const typed_bdaddr *taddr)
{
    /* All requests are sent through the internal state handler */    
    MAKE_CL_MESSAGE(CL_INTERNAL_DM_READ_RSSI_REQ);
    message->theAppTask = theAppTask;
    message->sink = NULL; /* make sink to null to use taddr instead */
    message->taddr = *taddr;
    MessageSend(connectionGetCmTask(), CL_INTERNAL_DM_READ_RSSI_REQ, message);
}


