/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    ConnectionSmChangeLinkKey.c        

DESCRIPTION
    This file contains the management entity responsible for device security

NOTES

*/


/****************************************************************************
    Header files
*/
#include "connection.h"
#include "connection_private.h"

#include <message.h>
#include <string.h>
#include <vm.h>


/*****************************************************************************/
void ConnectionSmChangeLinkKey(Sink sink)
{   
    MAKE_CL_MESSAGE(CL_INTERNAL_SM_CHANGE_LINK_KEY_REQ);
    message->sink = sink;
    MessageSend(connectionGetCmTask(), CL_INTERNAL_SM_CHANGE_LINK_KEY_REQ, message);
}

