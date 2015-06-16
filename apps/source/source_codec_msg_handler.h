/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_codec_msg_handler.h

DESCRIPTION
    Codec library message handling.
    
*/


#ifndef _SOURCE_CODEC_MSG_HANDLER_H_
#define _SOURCE_CODEC_MSG_HANDLER_H_


/* VM headers */
#include <message.h>


/***************************************************************************
Function definitions
****************************************************************************
*/

/****************************************************************************
NAME    
    codec_msg_handler

DESCRIPTION
    Message handler for Codec library messages.

*/
void codec_msg_handler(Task task, MessageId id, Message message);


#endif /* _SOURCE_CODEC_MSG_HANDLER_H_ */
