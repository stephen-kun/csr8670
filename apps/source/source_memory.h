/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_memory.h
    
DESCRIPTION
    Handles application memory applications.
    
*/


#ifndef _SOURCE_MEMORY_H_
#define _SOURCE_MEMORY_H_


/* VM headers */
#include <csrtypes.h>
#include <panic.h>


/* Memory blocks that can be created. A memory block will handle, eg. multiple profiles, or multiple codecs. */
typedef enum
{
    MEMORY_CREATE_BLOCK_PROFILES,
    MEMORY_CREATE_BLOCK_CODECS
} MEMORY_CREATE_BLOCK_T;

/* Elements of a memory block that can be accessed. */
typedef enum
{
    MEMORY_GET_BLOCK_PROFILE_A2DP,
    MEMORY_GET_BLOCK_PROFILE_AGHFP,
    MEMORY_GET_BLOCK_PROFILE_AVRCP,
    MEMORY_GET_BLOCK_CODEC_SBC,
    MEMORY_GET_BLOCK_CODEC_FASTSTREAM,
    MEMORY_GET_BLOCK_CODEC_APTX,
    MEMORY_GET_BLOCK_CODEC_APTX_LOW_LATENCY
} MEMORY_GET_BLOCK_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    memory_create

DESCRIPTION
    Allocates memory of the specified size.
    Use when allocating memory to keep track of application memory.
    
RETURNS
    The memory allocated.
    
*/
void *memory_create(size_t size);


/****************************************************************************
NAME    
    memory_free

DESCRIPTION
    Frees the memory that is passed in.
    Use when freeing memory to keep track of application memory.
    
*/
void memory_free(void *memory);


/****************************************************************************
NAME    
    memory_create_block

DESCRIPTION
    Creates a memory block that can be split up and used for different elements
    
RETURNS
    TRUE - memory block created successfully
    FALSE - memory block creation failed
    
*/
bool memory_create_block(MEMORY_CREATE_BLOCK_T block);


/****************************************************************************
NAME    
    memory_get_block

DESCRIPTION
    Gets an element of a memory block
    
RETURNS
    Returns a pointer to the memory allocated or NULL if unsuccessful
    
*/
void *memory_get_block(MEMORY_GET_BLOCK_T block);


#endif /* _SOURCE_MEMORY_H_ */
