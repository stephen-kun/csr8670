/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    codec_csr_internal_init_handler.c
    
DESCRIPTION
	
*/

#include "codec.h"
#include "codec_private.h"
#include "codec_init_handler.h"
#include "codec_csr_internal_init_handler.h"


/****************************************************************************
NAME	
	handleCsrInternalCodecInitReq

DESCRIPTION
	Function to handle internal init request message, for the CSR internal
	codec.
*/
void handleCsrInternalCodecInitReq(CsrInternalCodecTaskData *codec)
{
	sendInitCfmToApp(&codec->task, codec->clientTask, codec_success, CODEC_INPUT_GAIN_RANGE, CODEC_OUTPUT_GAIN_RANGE);	
}
