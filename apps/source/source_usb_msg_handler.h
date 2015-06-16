/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_usb_msg_handler.h

DESCRIPTION
    USB message handling.
    
*/


#ifndef _SOURCE_USB_MSG_HANDLER_H_
#define _SOURCE_USB_MSG_HANDLER_H_


/* VM headers */
#include <message.h>


/***************************************************************************
Function definitions
****************************************************************************
*/

/****************************************************************************
NAME    
    usb_msg_handler

DESCRIPTION
    Handles USB messages.

*/
void usb_msg_handler(Task task, MessageId id, Message message);


#endif /* _SOURCE_USB_MSG_HANDLER_H_ */
