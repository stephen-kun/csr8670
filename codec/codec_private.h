/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    codec_private.h
    
DESCRIPTION

*/

#ifndef CODEC_PRIVATE_H_
#define CODEC_PRIVATE_H_

#include <message.h>
#include <panic.h>

/* Macros for creating messages */
#define MAKE_CODEC_MESSAGE(TYPE) TYPE##_T *message = PanicUnlessNew(TYPE##_T);

/*#define CODEC_DEBUG_LIB*/

/* Macro used to generate debug lib printfs */
#ifdef CODEC_DEBUG_LIB
#include <stdio.h>
#define CODEC_DEBUG(x) {printf x;}
#else
#define CODEC_DEBUG(x)
#endif


enum
{
	CODEC_INTERNAL_INIT_REQ,
	CODEC_INTERNAL_CONFIG_REQ,
	CODEC_INTERNAL_INPUT_GAIN_REQ,
	CODEC_INTERNAL_OUTPUT_GAIN_REQ,
	CODEC_INTERNAL_CODEC_ENABLE_REQ,
	CODEC_INTERNAL_CODEC_DISABLE_REQ,
	CODEC_INTERNAL_POWER_DOWN_REQ
};

typedef struct
{
	codec_config_params *config;
} CODEC_INTERNAL_CONFIG_REQ_T;

typedef struct
{
	uint16 volume;
    codec_channel channel;
} CODEC_INTERNAL_INPUT_GAIN_REQ_T;

typedef struct
{
	uint16 volume;
    codec_channel channel;
} CODEC_INTERNAL_OUTPUT_GAIN_REQ_T;


#endif /* CODEC_PRIVATE_H */
