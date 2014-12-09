/******************************************************************************
   Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com                              
   Part of ADK 3.5
   $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $         
   */           
/******************************************************************************/

/******************************************************************************
    MODULE:
        pblock.c

    DESCRIPTION
        This module implements a persistence system called pblock.
        Pblock allows keyed blocks of data to be persisted to/from a PSKey
        Intended usage is for multiple DSP applications running on a chip, each 
        needing an independent block of persistent memory.
  
    Functions:
        void PblockInit(void)
            Initialize the PBlock system. Called once per powercycle
  
        void PblockStore(void)
            Store the data to persistance. Can be called at will.
  
        uint16* PblockGet(uint16 entry_id, uint16* entry_len)
            Retrieve data from a keyed block
  
        void PblockSet(uint16 entry_id, uint16 entry_len, uint16 *data)
            Store data to a keyed block. Entry will be created if not present

    Notes
        Storage format:
            {entry header}
            entryid_entrysize:8:8
            {entry data}
            data0:16
            data1:16
            dataN:16
            {entry header}
            entryid_entrysize:8:8
            {entry data}
            data0:16
            data1:16
            dataN:16
            {max_size}

   */  
/******************************************************************************/

#ifndef PBLOCK_H_
#define PBLOCK_H_

typedef struct
{
    unsigned id:8;
    unsigned size:8;
    uint16   data[1];
} pblock_entry;

typedef struct
{
    uint16      key;
    unsigned    len:8;
    unsigned    cur_len:8;
    uint16*     cache;
} pblock_key;

void PblockInit(pblock_key* key);
void PblockStore(void);
const pblock_entry* PblockGet(uint16 id);
void PblockSet(uint16 id, uint16 len, uint16 *data);

#endif /*PBLOCK_H_*/
