/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    codec_power.c
    
DESCRIPTION
	
*/

#include "codec.h"
#include "codec_private.h"


void CodecEnable(Task codecTask)
{
	MessageSend(codecTask, CODEC_INTERNAL_CODEC_ENABLE_REQ, 0);
}

void CodecDisable(Task codecTask)
{
	MessageSend(codecTask, CODEC_INTERNAL_CODEC_DISABLE_REQ, 0);
}

void CodecPowerDown(Task codecTask)
{
	MessageSend(codecTask, CODEC_INTERNAL_POWER_DOWN_REQ, 0);
}



