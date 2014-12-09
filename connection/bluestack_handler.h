/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    connection_private.h
    
DESCRIPTION

*/

#ifndef    CONNECTION_BLUESTACK_HANDLER_H_
#define    CONNECTION_BLUESTACK_HANDLER_H_


/****************************************************************************
NAME    
    connectionBluestackHandler    

DESCRIPTION
    Connection task handler for incoming Bluestack primitives

RETURNS
    void    
*/
void connectionBluestackHandler(Task task, MessageId id, Message message);


#endif    /* CONNECTION_BLUESTACK_HANDLER_H_ */
