/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    codec_init_handler.c
    
DESCRIPTION
	
*/

#include "codec.h"
#include "codec_private.h"
#include "codec_init_handler.h"


/****************************************************************************
NAME	
	sendInitCfmToApp

DESCRIPTION
	Send an initialisation confirmation message back to the client application.
*/
void sendInitCfmToApp(Task codecTask, 
					  Task clientTask, 
					  codec_status_code status, 
					  uint16 inputGainRange, 
					  uint16 outputGainRange)
{
	MAKE_CODEC_MESSAGE(CODEC_INIT_CFM);
	message->status = status;
	message->inputGainRange = inputGainRange;
	message->outputGainRange = outputGainRange;
    message->codecTask = codecTask;
	MessageSend(clientTask, CODEC_INIT_CFM, message);
}
