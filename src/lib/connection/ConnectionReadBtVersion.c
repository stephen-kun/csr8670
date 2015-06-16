/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    ConnectionReadBtVersion.c        

DESCRIPTION
    This file contains the management entity responsible for arbitrating 
    access to functionality in BlueStack that provides information on
    the setup of the local device version

NOTES

*/


/****************************************************************************
    Header files
*/
#include "connection.h"
#include "connection_private.h"

/*****************************************************************************/
void ConnectionReadBtVersion(Task theAppTask)
{
     /* All requests are sent through the internal state handler */    
    MAKE_CL_MESSAGE(CL_INTERNAL_DM_SET_BT_VERSION_REQ);
    message->theAppTask = theAppTask;
    message->version = BT_VERSION_CURRENT;
    MessageSend(connectionGetCmTask(), CL_INTERNAL_DM_SET_BT_VERSION_REQ, message);
}
