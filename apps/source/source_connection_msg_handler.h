/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_connection_msg_handler.h

DESCRIPTION
    Connection library message handling.
    
*/


#ifndef _SOURCE_CONNECTION_MSG_HANDLER_H_
#define _SOURCE_CONNECTION_MSG_HANDLER_H_


/* VM headers */
#include <message.h>


/***************************************************************************
Function definitions
****************************************************************************
*/

/****************************************************************************
NAME    
    connection_msg_handler

DESCRIPTION
    Handles Connection library messages.

*/
void connection_msg_handler(Task task, MessageId id, Message message);


#endif /* _SOURCE_CONNECTION_MSG_HANDLER_H_ */
