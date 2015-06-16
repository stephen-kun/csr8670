/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_info_remote_version.c        

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
#include "sink.h"

/*****************************************************************************/
void ConnectionReadRemoteVersion(Task theAppTask, Sink sink)
{
    /* All requests are sent through the internal state handler */    
    typed_bdaddr taddr;
    MAKE_CL_MESSAGE(CL_INTERNAL_DM_READ_REMOTE_VERSION_REQ);
    message->theAppTask = theAppTask;
     
    /* Get bdaddr from sink */
    if (!SinkGetBdAddr(sink, &taddr))
    {
        message->taddr.type = TYPED_BDADDR_PUBLIC;
        message->taddr.addr.lap = 0;
        message->taddr.addr.nap = 0;
        message->taddr.addr.uap = 0;
    }
    else if (taddr.type != TYPED_BDADDR_PUBLIC)
    {
        CL_DEBUG(("SinkGetBdAddr returned non-public type\n"));

        message->taddr.type = TYPED_BDADDR_PUBLIC;
        message->taddr.addr.lap = 0;
        message->taddr.addr.nap = 0;
        message->taddr.addr.uap = 0;
    }
	else
	{
		message->taddr = taddr;
    }
    
     MessageSend(connectionGetCmTask(), CL_INTERNAL_DM_READ_REMOTE_VERSION_REQ, message);
}

void ConnectionReadRemoteVersionBdaddr(Task theAppTask, const typed_bdaddr *addr)
{
    /* All requests are sent through the internal state handler */    
    MAKE_CL_MESSAGE(CL_INTERNAL_DM_READ_REMOTE_VERSION_REQ);
    message->theAppTask = theAppTask;
    message->taddr = *addr;
    MessageSend(connectionGetCmTask(), CL_INTERNAL_DM_READ_REMOTE_VERSION_REQ, message);
}

