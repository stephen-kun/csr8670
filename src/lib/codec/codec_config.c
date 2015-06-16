/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    codec_config.c
    
DESCRIPTION
	
*/

#include "codec.h"
#include "codec_private.h"

#include <string.h>

static void SetDefaultConfigParams(codec_config_params *config)
{
	config->adc_sample_rate = sample48kHz;
	config->dac_sample_rate = sample48kHz;
	config->inputs = no_input;
	config->outputs = OUTPUT_DAC;
}

void CodecConfigure(Task codecTask, const codec_config_params *config)
{
	uint16 length = sizeof(codec_config_params);
	MAKE_CODEC_MESSAGE(CODEC_INTERNAL_CONFIG_REQ);
	message->config = (codec_config_params *) PanicUnlessMalloc(length);
	if (!config)
		SetDefaultConfigParams(message->config);
	else
		memmove(message->config, config, length);
	MessageSend(codecTask, CODEC_INTERNAL_CONFIG_REQ, message);
}



