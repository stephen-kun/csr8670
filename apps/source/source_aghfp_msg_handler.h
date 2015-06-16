/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_aghfp_msg_handler.h

DESCRIPTION
    AGHFP profile message handling.
    
*/


#ifndef _SOURCE_AGHFP_MSG_HANDLER_H_
#define _SOURCE_AGHFP_MSG_HANDLER_H_


/* profile/library headers */
#include <aghfp.h>
/* VM headers */
#include <message.h>


/* Application defined AGHFP messages */
#define AGHFP_INTERNAL_MESSAGE_BASE 0

typedef enum
{
    AGHFP_INTERNAL_CONNECT_REQ = AGHFP_INTERNAL_MESSAGE_BASE,
    AGHFP_INTERNAL_CONNECT_AUDIO_REQ,
    AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ,
    AGHFP_INTERNAL_DISCONNECT_REQ,
    AGHFP_INTERNAL_CALL_CREATE_REQ,
    AGHFP_INTERNAL_RING_ALERT,
    AGHFP_INTERNAL_VOICE_RECOGNITION,
    AGHFP_INTERNAL_MESSAGE_TOP
} AghfpInternalMessageId;


typedef struct
{
    aghfp_call_type call_type;
} AGHFP_INTERNAL_CALL_CREATE_REQ_T;

typedef struct
{
    bool enable;
} AGHFP_INTERNAL_VOICE_RECOGNITION_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    aghfp_msg_handler

DESCRIPTION
    Handles AGHFP messages.

*/
void aghfp_msg_handler(Task task, MessageId id, Message message);


#endif /* _SOURCE_AGHFP_MSG_HANDLER_H_ */
