/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_data_block.c

DESCRIPTION

NOTES

*/



/****************************************************************************
    Header files
*/

#include "a2dp_data_block.h"
#include "a2dp_private.h"
#include <string.h>    /* for memset */
#include <print.h>
#include <stdlib.h>

#ifdef SINGLE_MEM_SLOT
/* Single memory slot operation.  Data blocks positioned at end of A2DP structure */
#define DBLK_TYPE      A2DP
#define DBLK_HDR_SIZE  sizeof(DBLK_TYPE)
#define DBLK_BASE      a2dp
#define DBLK           a2dp->data_blocks.block
#define DBLK_DATA_SIZE a2dp->data_blocks.size_blocks
#else
/* Multiple memory slot operation.  Data blocks reside in their own memory slots */
#define DBLK_TYPE         data_block_header
#define DBLK_HDR_SIZE     sizeof(DBLK_TYPE)
#define DBLK_BASE(n)      a2dp->data_blocks[(n)]
#define DBLK(n)           a2dp->data_blocks[(n)]->block
#define DBLK_DATA_SIZE(n) a2dp->data_blocks[(n)]->size_blocks
#endif

void blockInit (void)
{
#ifndef SINGLE_MEM_SLOT
    uint16 i;
    for (i=0; i<A2DP_MAX_REMOTE_DEVICES_DEFAULT; i++)
    {
        DBLK_BASE(i) = (DBLK_TYPE *)PanicNull(malloc(DBLK_HDR_SIZE));
        memset((uint8 *)DBLK_BASE(i), 0, DBLK_HDR_SIZE);
    }
#endif
}

uint8 *blockAdd (uint8 device_id, data_block_id block_id, uint8 element_count, uint8 element_size)
{
#ifdef SINGLE_MEM_SLOT
    data_block_info *data_block = &DBLK[device_id][block_id];
#else
    data_block_info *data_block = &DBLK(device_id)[block_id];
#endif
    
    PRINT(("blockAdd(devId=%u, blkId=%u, cnt=%u, sz=%u)",device_id, block_id, element_count, element_size));
    
    if (!data_block->offset)
    {
        uint16 block_size = element_size * element_count;
#ifdef SINGLE_MEM_SLOT
        uint16 offset = DBLK_HDR_SIZE + DBLK_DATA_SIZE;  /* New block added at end of any existing ones */
        DBLK_TYPE *new_data_pool = (DBLK_TYPE *)realloc(DBLK_BASE, offset+block_size);
#else
        uint16 offset = DBLK_HDR_SIZE + DBLK_DATA_SIZE(device_id);  /* New block added at end of any existing ones */
        DBLK_TYPE *new_data_pool = (DBLK_TYPE *)realloc(DBLK_BASE(device_id), offset+block_size);
#endif
        if (new_data_pool)
        {
#ifdef SINGLE_MEM_SLOT
            DBLK_BASE = new_data_pool;
            memset((uint8*)((uint16)DBLK_BASE+offset), 0, block_size);  /* For debug purposes */
#else
            DBLK_BASE(device_id) = new_data_pool;
            memset((uint8*)((uint16)DBLK_BASE(device_id)+offset), 0, block_size);  /* For debug purposes */
#endif

#ifdef SINGLE_MEM_SLOT
            data_block = &DBLK[device_id][block_id];
            DBLK_DATA_SIZE += block_size;
#else
            data_block = &DBLK(device_id)[block_id];
            DBLK_DATA_SIZE(device_id) += block_size;
#endif
            data_block->offset = offset;
            data_block->block_size = block_size;
            data_block->element_size = element_size;
            data_block->current_element = 0;

#ifdef SINGLE_MEM_SLOT
            PRINT((" [@%X]  size_blocks=%u\n",(uint16)DBLK_BASE+offset, DBLK_DATA_SIZE));
            return (uint8 *)((uint16)DBLK_BASE+offset);
#else
            PRINT((" [@%X]  size_blocks(%u)=%u\n",(uint16)DBLK_BASE(device_id)+offset, device_id, DBLK_DATA_SIZE(device_id)));
            return (uint8 *)((uint16)DBLK_BASE(device_id)+offset);
#endif
        }
    }

    /* Failed - block already exists  or  unable to allocate memory */
    PRINT(("[NULL]\n"));
    return 0;
}


void blockRemove (uint8 device_id, data_block_id block_id)
{
#ifdef SINGLE_MEM_SLOT
    data_block_info *data_block = &DBLK[device_id][block_id];
#else
    data_block_info *data_block = &DBLK(device_id)[block_id];
#endif
    uint16 offset = data_block->offset;
    
    PRINT(("blockRemove(devId=%u, blkId=%u)",device_id, block_id));
    
    if ( offset )
    {
        DBLK_TYPE *new_data_pool;
        uint16 block_size = data_block->block_size;
#ifdef SINGLE_MEM_SLOT
        data_block_info *block = &DBLK[0][0];
#else
        data_block_info *block = &DBLK(device_id)[0];
#endif
        
        /* Reduce offsets of all blocks positioned above the block being removed */        
        do
        {
            PRINT((" [%X]",(uint16)block));
            
            if ( offset < block->offset )
            {
                block->offset -= block_size;
            }
        }
#ifdef SINGLE_MEM_SLOT
        while (++block <= &DBLK[A2DP_MAX_REMOTE_DEVICES-1][max_data_blocks-1]);
#else
        while (++block <= &DBLK(device_id)[max_data_blocks-1]);
#endif
        
        /* Zero info parameters of block being removed */
        memset( data_block, 0, sizeof( data_block_info ) );
        
#ifdef SINGLE_MEM_SLOT
        /* Reduce overall size of all blocks */
        DBLK_DATA_SIZE -= block_size;
        PRINT(("  size_blocks=%u\n",DBLK_DATA_SIZE));
#else
        /* Reduce overall size of all blocks */
        DBLK_DATA_SIZE(device_id) -= block_size;
        PRINT(("  size_blocks(%u)=%u\n",device_id,DBLK_DATA_SIZE(device_id)));
#endif
            
#ifdef SINGLE_MEM_SLOT
        /* Shift blocks above removed block down by the appropriate amount.  For debug purposes, fill the now unused area at top of memory area */
        memmove((uint8*)DBLK_BASE+offset, (uint8*)DBLK_BASE+offset+block_size, DBLK_DATA_SIZE-offset+DBLK_HDR_SIZE);
        memset((uint8*)DBLK_BASE+DBLK_DATA_SIZE+DBLK_HDR_SIZE, 0xFF, block_size);  /* For debug purposes */
        
        if ( (new_data_pool = (DBLK_TYPE *)realloc(DBLK_BASE, DBLK_HDR_SIZE+DBLK_DATA_SIZE)) != NULL )
        {
            DBLK_BASE = new_data_pool;
        }
        /* No need to worry about a failed realloc, old one will still exist and be valid */
#else
        /* Shift blocks above removed block down by the appropriate amount.  For debug purposes, fill the now unused area at top of memory area */
        memmove((uint8*)DBLK_BASE(device_id)+offset, (uint8*)DBLK_BASE(device_id)+offset+block_size, DBLK_DATA_SIZE(device_id)-offset+DBLK_HDR_SIZE);
        memset((uint8*)DBLK_BASE(device_id)+DBLK_DATA_SIZE(device_id)+DBLK_HDR_SIZE, 0xFF, block_size);  /* For debug purposes */
        
        if ( (new_data_pool = (DBLK_TYPE *)realloc(DBLK_BASE(device_id), DBLK_HDR_SIZE+DBLK_DATA_SIZE(device_id))) != NULL )
        {
            DBLK_BASE(device_id) = new_data_pool;
        }
        /* No need to worry about a failed realloc, old one will still exist and be valid */
#endif
    }
}


uint8 *blockGetBase (uint8 device_id, data_block_id block_id)
{
#ifdef SINGLE_MEM_SLOT
    uint16 offset = DBLK[device_id][block_id].offset;
#else
    uint16 offset = DBLK(device_id)[block_id].offset;
#endif

    PRINT(("blockGetBase(devId=%u, blkId=%u)\n",device_id, block_id));
    
#ifdef SINGLE_MEM_SLOT
    return (offset)?(uint8*)((uint16)DBLK_BASE+offset):(uint8*)0;
#else
    return (offset)?(uint8*)((uint16)DBLK_BASE(device_id)+offset):(uint8*)0;
#endif
}


uint8 *blockGetIndexed (uint8 device_id, data_block_id block_id, uint8 element)
{
#ifdef SINGLE_MEM_SLOT
    data_block_info *data_block = &DBLK[device_id][block_id];
#else
    data_block_info *data_block = &DBLK(device_id)[block_id];
#endif
    uint16 offset = data_block->element_size * element;
    
    PRINT(("blockGetIndexed(devId=%u, blkId=%u, ele=%u)\n",device_id, block_id, element));
    
    offset += data_block->offset;
    
#ifdef SINGLE_MEM_SLOT
    return (offset)?(uint8*)((uint16)DBLK_BASE+offset):(uint8*)0;
#else
    return (offset)?(uint8*)((uint16)DBLK_BASE(device_id)+offset):(uint8*)0;
#endif
}


uint8 *blockGetCurrent (uint8 device_id, data_block_id block_id)
{
#ifdef SINGLE_MEM_SLOT
    data_block_info *data_block = &DBLK[device_id][block_id];
#else
    data_block_info *data_block = &DBLK(device_id)[block_id];
#endif
    uint16 offset = data_block->element_size * data_block->current_element;
    
    PRINT(("blockGetCurrent(devId=%u, blkId=%u)=%u\n",device_id, block_id, data_block->current_element));
    
    offset += data_block->offset;
    
#ifdef SINGLE_MEM_SLOT
    return (offset)?(uint8*)((uint16)DBLK_BASE+offset):(uint8*)0;
#else
    return (offset)?(uint8*)((uint16)DBLK_BASE(device_id)+offset):(uint8*)0;
#endif
}


uint8 *blockSetCurrent (uint8 device_id, data_block_id block_id, uint8 element)
{
#ifdef SINGLE_MEM_SLOT
    data_block_info *data_block = &DBLK[device_id][block_id];
#else
    data_block_info *data_block = &DBLK(device_id)[block_id];
#endif
    
    PRINT(("blockSetCurrent(devId=%u, blkId=%u, ele=%u)\n",device_id, block_id, element));
    
    if ( element == DATA_BLOCK_INDEX_NEXT )
    {
        element = data_block->current_element + 1;
    }
    else if ( element == DATA_BLOCK_INDEX_PREVIOUS )
    {
        element = data_block->current_element - 1;
    }
    
    if ( (data_block->element_size * element) < data_block->block_size )
    {
        data_block->current_element = element;
        return blockGetCurrent(device_id, block_id);
    }

    return NULL;
}


uint16 blockGetSize (uint8 device_id, data_block_id block_id)
{
#ifdef SINGLE_MEM_SLOT
    PRINT(("blockGetSize(devId=%u, blkId=%u)=%u   size_blocks=%u\n",device_id, block_id, DBLK[device_id][block_id].block_size, DBLK_DATA_SIZE));
    return DBLK[device_id][block_id].block_size;
#else
    PRINT(("blockGetSize(devId=%u, blkId=%u)=%u   size_blocks(%u)=%u\n",device_id, block_id, DBLK(device_id)[block_id].block_size, device_id, DBLK_DATA_SIZE(device_id)));
    return DBLK(device_id)[block_id].block_size;
#endif
}


