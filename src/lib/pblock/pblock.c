/******************************************************************************
   Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com                              
   Part of ADK 3.5
   $Change: 641757 $  $DateTime: 2010/10/20 20:54:35 $         
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
  
      void pblock_shutdown(void)
         Shutdown the PBlock system. Called once per powercycle
  
      void PblockStore(void)
         Store the data to persistance. Can be called at will.
  
      uint16* PblockGet(uint16 entry_id, uint16* entry_len)
         Retrieve data from a keyed block
  
      void PblockSet(uint16 entry_id, uint16 entry_len, uint16 *data)
         Store data to a keyed block. Entry will be created if not present

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

   Notes
   */  
/******************************************************************************/

#include <ps.h>
#include <stdlib.h>
#include <string.h>
#include <panic.h>
#include <print.h>

#include "pblock.h"

#define PBLOCK_START    ((pblock_entry*)pblock->cache)
#define PBLOCK_END      ((pblock_entry*)(pblock->cache + pblock->cur_len))
#define for_all_entries(entry)      for(entry = PBLOCK_START; entry < PBLOCK_END; entry = (pblock_entry*)(((uint16*) entry) + entry->size + 1))
#define for_all_data(entry, data)   for(data = entry->data; data < (entry->data + entry->size); data++)

static pblock_key* pblock;

static const pblock_entry empty_pblock = {0, 0, {0}};

#ifdef DEBUG_PRINT_ENABLED
static void pblockDebug(void)
{
    pblock_entry* entry;
    uint16*       data;
    
    for_all_entries(entry)
    {
        PRINT(("PBLOCK: Entry 0x%02X:", entry->id));
        for_all_data(entry, data)
            PRINT((" 0x%04X", *data));
        PRINT(("\n"));
    }
}
#else
#define pblockDebug() ((void)(0))
#endif

static pblock_entry* pblockAddEntry(uint16 id, uint16 len)
{
    pblock_entry* entry = PBLOCK_END;
   
    if (!pblock || (pblock->cur_len + len + 1) > pblock->len)
        return NULL;
    
    PRINT(("PBLOCK: New Entry 0x%02x (size=%d)\n", id, len));   
    
    entry->id = id;
    entry->size = len;
    pblock->cur_len += len + 1;
   
    return entry;
}

void PblockInit(pblock_key* key)
{
    pblock = key;
    PRINT(("PBLOCK: Load\n"));
    pblock->cur_len = PsRetrieve(pblock->key, pblock->cache, pblock->len);
    pblockDebug();
}

void PblockStore(void)
{
    PRINT(("PBLOCK: Store\n"));
    PanicFalse(pblock->cur_len == PsStore(pblock->key, pblock->cache, pblock->cur_len));
    pblockDebug();
}

const pblock_entry* PblockGet(uint16 id)
{
    pblock_entry* entry;
    
    if(pblock)
        for_all_entries(entry)
            if(entry->id == id)
                return entry;
    
    return &empty_pblock;
}

void PblockSet(uint16 id, uint16 len, uint16 *data)
{
    pblock_entry* entry = (pblock_entry*)PblockGet(id);
    
    if(!entry->size) 
        entry = pblockAddEntry(id, len);
    
    if(entry->size == len)
    {
        memmove(entry->data, data, entry->size);
        PRINT(("PBLOCK: Stored %d words to entry 0x%02x \n", len, id ));
    }
}
