/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_profile_handler.h
    
DESCRIPTION    
	
*/

#ifndef A2DP_PROFILE_HANDLER_H_
#define A2DP_PROFILE_HANDLER_H_


/****************************************************************************
NAME
	a2dpProfileHandler

DESCRIPTION
    This function handles all messages sent to the a2dp profile library
    task. 
*/
void a2dpProfileHandler(Task task, MessageId id, Message message);


#endif /* A2DP_PROFILE_HANDLER_H_ */
