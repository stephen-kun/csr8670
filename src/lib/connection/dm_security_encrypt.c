/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_security_encrypt.c        

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
#include    <string.h>
#include    <vm.h>
#include    <sink.h>


/*****************************************************************************/
void ConnectionSmEncrypt(Task theAppTask, Sink sink, uint16 encrypt)
{
#ifdef CONNECTION_DEBUG_LIB
    if ((encrypt != TRUE) && (encrypt != FALSE))
    {
        CL_DEBUG(("Invalid value passin for the encrypt flag 0x%x\n", encrypt));
    }

    if(!sink)
    {
        CL_DEBUG(("Null sink passed in\n")); 
    }
#endif

    {
        MAKE_CL_MESSAGE(CL_INTERNAL_SM_ENCRYPT_REQ);
        message->theAppTask = theAppTask;
        message->sink = sink;
        message->encrypt = encrypt;
        MessageSend(connectionGetCmTask(), CL_INTERNAL_SM_ENCRYPT_REQ, message);  
    }
}


/*****************************************************************************/
void ConnectionSmEncryptionKeyRefreshSink(Sink sink)
{
#ifdef CONNECTION_DEBUG_LIB
    if(!sink)
    {
        CL_DEBUG(("Null sink passed in\n")); 
    }
#endif
    
    {
        typed_bdaddr taddr;
        if(SinkGetBdAddr(sink, &taddr))
        {
        	if (taddr.type == TYPED_BDADDR_PUBLIC)
        	{
                MAKE_CL_MESSAGE(CL_INTERNAL_SM_ENCRYPTION_KEY_REFRESH_REQ);
                message->taddr = taddr;
                MessageSend(connectionGetCmTask(), CL_INTERNAL_SM_ENCRYPTION_KEY_REFRESH_REQ, message);
        	}
        	else
        	{
                CL_DEBUG(("SinkGetBdAddr returned non-public type\n"));
        	}
        }
    }
}

