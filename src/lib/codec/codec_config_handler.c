/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    codec_config_handler.c
    
DESCRIPTION
	
*/

#include "codec.h"
#include "codec_private.h"
#include "codec_config_handler.h"


/****************************************************************************
NAME	
	sendCodecConfigureCfm

DESCRIPTION
	Send a CODEC_CONFIG_CFM message back to the client application with
	a status code.
*/
void sendCodecConfigureCfm(Task clientTask, codec_status_code status)
{
	MAKE_CODEC_MESSAGE(CODEC_CONFIGURE_CFM);
	message->status = status;
	MessageSend(clientTask, CODEC_CONFIGURE_CFM, message);	
}

