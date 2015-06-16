/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_security_oob.c        

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
#include <vm.h>


/*****************************************************************************/
void ConnectionSmReadLocalOobData(Task theAppTask)
{
    MAKE_CL_MESSAGE(CL_INTERNAL_SM_READ_LOCAL_OOB_DATA_REQ);
    message->task = theAppTask;
    MessageSend(connectionGetCmTask(), CL_INTERNAL_SM_READ_LOCAL_OOB_DATA_REQ, message);
}

