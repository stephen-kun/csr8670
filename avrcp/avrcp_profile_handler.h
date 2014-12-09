/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    profile_handler.h
    
DESCRIPTION
    Header file for the AVRCP profile library.
*/

#ifndef AVRCP_PROFILE_HANDLER_H_
#define AVRCP_PROFILE_HANDLER_H_

#include <message.h>


/******************************************************************
NAME    
    avrcpInitHandler

DESCRIPTION
    All Initialization messages are handled here
*/
void avrcpInitHandler(Task task, MessageId id, Message message);

/****************************************************************************
NAME    
    avrcpProfileHandler

DESCRIPTION
    All messages for the profile lib instance are handled by this function.
*/
void avrcpProfileHandler(Task task, MessageId id, Message message);


/****************************************************************************
NAME    
    avrcpDataCleanUp

DESCRIPTION
    This function is called when a source becomes empty and all it does is 
    free the memory allocated and turned into a source using 
    StreamRegionSource.
*/
void avrcpDataCleanUp(Task task, MessageId id, Message message);

/****************************************************************************
NAME    
    avbpProfileHandler

DESCRIPTION
    profileHandler function for Browsing channel 
*/
void avbpProfileHandler(Task task, MessageId id, Message message);

#endif /* AVRCP_PROFILE_HANDLER_H */
