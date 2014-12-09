/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_security_authorise.c        

DESCRIPTION
    This file contains the management entity responsible for device security

NOTES

*/


/****************************************************************************
    Header files
*/
#include "connection.h"
#include "connection_private.h"

#include    <message.h>
#include    <vm.h>


/*****************************************************************************/
void ConnectionDmAclDetach(const bdaddr* bd_addr, uint8 reason, bool detach_all)
{   

    MAKE_CL_MESSAGE(CL_INTERNAL_DM_ACL_FORCE_DETACH_REQ);
    message->bd_addr = *bd_addr;
    message->reason = reason;
    if (detach_all)
        message->flags = DM_ACL_FLAG_FORCE | DM_ACL_FLAG_ALL;
    else
        message->flags = DM_ACL_FLAG_FORCE;

    MessageSend(connectionGetCmTask(), CL_INTERNAL_DM_ACL_FORCE_DETACH_REQ, message);
}



