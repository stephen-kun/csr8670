/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_a2dp_msh_handler.h

DESCRIPTION
    A2DP profile message handling.
    
*/


#ifndef _SOURCE_A2DP_MSG_HANDLER_H_
#define _SOURCE_A2DP_MSG_HANDLER_H_


/* VM headers */
#include <message.h>


/* Application defined A2DP messages */
#define A2DP_INTERNAL_MESSAGE_BASE 0

typedef enum
{
    A2DP_INTERNAL_SIGNALLING_CONNECT_REQ = A2DP_INTERNAL_MESSAGE_BASE,
    A2DP_INTERNAL_MEDIA_OPEN_REQ,
    A2DP_INTERNAL_MEDIA_START_REQ,
    A2DP_INTERNAL_FORCE_DISCONNECT_REQ,
    A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ,
    A2DP_INTERNAL_MEDIA_SUSPEND_REQ,
    A2DP_INTERNAL_CONNECT_AUDIO_REQ,
    A2DP_INTERNAL_MEDIA_CLOSE_REQ,
    A2DP_INTERNAL_MESSAGE_TOP
} A2dpInternalMessageId;   


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    a2dp_msg_handler

DESCRIPTION
    Handles A2DP messages.

*/
void a2dp_msg_handler(Task task, MessageId id, Message message);


#endif /* _SOURCE_A2DP_MSG_HANDLER_H_ */
