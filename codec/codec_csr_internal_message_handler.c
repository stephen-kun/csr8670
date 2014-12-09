/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    codec_csr_internal_message_handler.c
    
DESCRIPTION

*/
#include "codec.h"
#include "codec_private.h"
#include "codec_csr_internal_init_handler.h"
#include "codec_csr_internal_config_handler.h"
#include "codec_csr_internal_volume_handler.h"
#include "codec_csr_internal_message_handler.h"


/****************************************************************************
NAME	
	csrInternalMessageHandler

DESCRIPTION
	All messages for the CSR internal codec are handled by this function

RETURNS
	void
*/
void csrInternalMessageHandler(Task task, MessageId id, Message message)
{
	CsrInternalCodecTaskData *codec = (CsrInternalCodecTaskData *) task;

	/* Check the message id */
	switch (id)
	{
	case CODEC_INTERNAL_INIT_REQ:
		handleCsrInternalCodecInitReq(codec);
		break;
	case CODEC_INTERNAL_CONFIG_REQ:
		handleCsrInternalCodecConfigureReq(codec, (CODEC_INTERNAL_CONFIG_REQ_T *) message);		
		break;
	case CODEC_INTERNAL_INPUT_GAIN_REQ:
		handleCsrInternalInputGainReq((CODEC_INTERNAL_INPUT_GAIN_REQ_T *) message);
		break;
	case CODEC_INTERNAL_OUTPUT_GAIN_REQ:
		handleCsrInternalOutputGainReq((CODEC_INTERNAL_OUTPUT_GAIN_REQ_T *) message);
		break;
		
	/* Not used */
	case CODEC_INTERNAL_CODEC_ENABLE_REQ:
		break;
	case CODEC_INTERNAL_CODEC_DISABLE_REQ:
		break;
	case CODEC_INTERNAL_POWER_DOWN_REQ:
		break;
	default:
		break;
	}
}


