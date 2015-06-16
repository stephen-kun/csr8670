/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    connection_tdl.c        

DESCRIPTION
    This file contains the functionality to manage a list of trusted devices.
    A list of devices is maintained in the persistent store.

    DM_SM_KEY_ID, used for BLE Privacy, is not supported yet.
    DM_SM_KEY_SIGN, used for BLE Data Signing, is not supported yet.

NOTES

*/

/****************************************************************************
    Header files
*/
#include "connection.h"
#include "connection_private.h"
#include "common.h"
#include "connection_tdl.h"

#include <bdaddr.h>
#include <message.h>
#include <panic.h>
#include <ps.h>
#include <stdlib.h>
#include <string.h>
#include <vm.h>


/*lint -e525 -e725 -e830 */

/* 
   The trusted device list is stored in the user area of Persistent store.  

   TRUSTED_DEVICE_INDEX         base for the TDL, contains the index
   TRUSTED_DEVICE_LIST + 0      first device in the list
   TRUSTED_DEVICE_LIST + 1      second device in the list
   
*/
#define TRUSTED_DEVICE_INDEX    PSKEY_TRUSTED_DEVICE_LIST

#define TRUSTED_DEVICE_LIST     (TRUSTED_DEVICE_INDEX + 1)

/* The number of devices to be manage */
#define MAX_TRUSTED_DEVICES  \
    (((connectionState *)connectionGetCmTask())->smState.TdlNumberOfDevices)

/* Size of the Trusted Device Index in words */
#define TDI_SIZE                ((MAX_NO_DEVICES_TO_MANAGE - 1) / 4 + 1)

/* Unused index */
#define TDI_UNUSED              (0xf)

/*
    The Trusted Device index is used to maintain a list of the Most Recently 
    Used trusted device.  This index is reordered each time the bonding 
    procedure is successful with a remote device.  Each item in this list 
    refers to an entry in the Trusted Device List.  Adopting this approach 
    results in Persistent Store write operations being kept to a minimum.
*/
typedef struct
{
    uint16                      order[MAX_NO_DEVICES_TO_MANAGE];
}td_index_t;


/* Used to convert from DM_SM_KEY_* type, in case the ordering in dm_prim.h
 * should change or be added to. Also, the function calc_td_data_offset()
 * relies on the specific ordering of this enum.
 */
typedef enum
{
    TDL_KEY_ENC_BREDR,
    TDL_KEY_ENC_CENTRAL,
    TDL_KEY_DIV,
    TDL_KEY_SIGN, 
    TDL_KEY_ID,
    TDL_KEY_UNKNOWN
} TDL_DATA_TYPE_T;

#define MASK_ENC_BREDR      (1<<TDL_KEY_ENC_BREDR)
#define MASK_ENC_CENTRAL    (1<<TDL_KEY_ENC_CENTRAL)
#define MASK_DIV            (1<<TDL_KEY_DIV)
#define MASK_SIGN           (1<<TDL_KEY_SIGN)
#define MASK_ID             (1<<TDL_KEY_ID)

#define BLE_ONLY_LINK_KEYS  (MASK_ENC_CENTRAL | MASK_DIV | MASK_SIGN | MASK_ID)

#define SIZE_ENC_BREDR      (sizeof(DM_SM_KEY_ENC_BREDR_T))
#define SIZE_ENC_CENTRAL    (sizeof(DM_SM_KEY_ENC_CENTRAL_T))
#define SIZE_DIV            (sizeof(uint16))
#define SIZE_ID             (sizeof(DM_SM_KEY_ID_T))

/* Indicates the contents of the packed link key store. */
/* 
    A device can be set as "priority device",
    therefore we need an indicator for this.
    Structure below had a 'spare' bit we can
    now use as 'priority_device' flag.
*/
typedef struct _content_t
{
    unsigned    addr_type:2;
    unsigned    trusted:1;
    unsigned    key_size:4;
    unsigned    security_req:3;
    unsigned    priority_device:1;
    unsigned    data_flags:5; /* TDL_DATA_TYPE_T */
} content_t;

/* Encryption key size is in range 7 to 16 octets. Pack it into 4 bits by 
 * subtracting 6. 
 */
#define PACK_TD_ENC_KEY_SIZE(TDP, EKS) \
     ((TDP)->content.key_size = ((EKS) - 6) & 0xF)
     
#define UNPACK_TD_ENC_KEY_SIZE(EKS, TDP) \
     ((EKS) = (uint16)(TDP)->content.key_size + 6)

/* Trusted Device data - in packed format. The 'content' field dictates the 
 * size and content of the data field.
 */
typedef struct _td_data_t
{
    uint16              bdaddr[3];
    content_t           content;
    uint16              data[1];
} td_data_t;

/* Size of the td_data_t type without the data e.g. just the packed bdaddr 
 * and content fields. 
 */
#define SIZE_TD         (sizeof(td_data_t)-sizeof(uint16))

#define SIZE_TD_DATA_T (SIZE_ENC_BREDR + \
                        SIZE_ENC_CENTRAL + \
                        SIZE_DIV + \
                        SIZE_ID + \
                        SIZE_TD)

/* Reduce slot usage in tdl_find_device by putting the index and typed_bdaddr 
 * into a single struct to allocate memory for.
 */
typedef struct
{
    td_index_t      tdi;
    typed_bdaddr    dev_taddr;
} one_slot;

/****************************************************************************

DESCRIPTION
    Reads the Trusted Device List Index from PS and unpacks it into the 
    td_index_t structure. 
*/
static void read_trusted_device_index(td_index_t *tdi)
{
    uint16  ps_tdi[TDI_SIZE];

    if (PsRetrieve(TRUSTED_DEVICE_INDEX, ps_tdi, TDI_SIZE) != TDI_SIZE)
    {
        memset(tdi, TDI_UNUSED, sizeof(td_index_t));
    }
    else
    {    
        uint16 i;
        uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;

        for (i = 0; i < max_trusted_devices; i++)
            tdi->order[i] = (ps_tdi[i / 4] >> (4 * (i % 4))) & 0x0F;
    }
}


/****************************************************************************
NAME
    ConnectionTrustedDeviceListSize()

FUNCTION
    Returns how many devices are in the trusted device list

RETURNS
    uint8 
*/
uint16 ConnectionTrustedDeviceListSize()
{
    td_index_t  tdi;
    uint16      count;
    uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;

    read_trusted_device_index( &tdi );

    for (
            count = 0; 
            count < max_trusted_devices && tdi.order[count] != TDI_UNUSED;
            count++
         ) ;
    return count;
}

/****************************************************************************

DESCRIPTION
    Store the Trusted Device List Index in to PS and pack it, using 4-bits 
    per index value.
*/
static void store_trusted_device_index(const td_index_t *tdi)
{
    uint16  ps_tdi[TDI_SIZE];
    uint16 i;
    uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;

    memset(ps_tdi, 0, TDI_SIZE);

    for (i = 0; i < max_trusted_devices; i++)
        ps_tdi[i / 4] |= (tdi->order[i] & 0x0F) << (4 * (i % 4));

    PsStore(TRUSTED_DEVICE_INDEX, ps_tdi, TDI_SIZE);
}


/****************************************************************************
NAME
    convert_dm_sm_to_tdl_key_type

FUNCTION
    Converts DM_SM_KEY_* type to the associated CL TDL_KEY_* type, in case the
    DM_SM_KEY_TYPE_T ever changes in content or order. Also, dictates the bit 
    order in the content_t 'data_flags' field.

RETURNS
    TDL_DATA_TYPE_T

*/
static TDL_DATA_TYPE_T convert_dm_sm_to_tdl_key_type(DM_SM_KEY_TYPE_T key_type)
{
    switch (key_type)
    {
        case DM_SM_KEY_ENC_BREDR:   return TDL_KEY_ENC_BREDR;
        case DM_SM_KEY_ENC_CENTRAL: return TDL_KEY_ENC_CENTRAL;
        case DM_SM_KEY_DIV:         return TDL_KEY_DIV;
        case DM_SM_KEY_ID:          return TDL_KEY_ID;
        default:
            break;
    }
    return TDL_KEY_UNKNOWN;
}

/****************************************************************************
NAME
    get_data_type_size

FUNCTION
    Returns the size of the associated key data.

RETURNS
    uint16

*/
static uint16 get_data_type_size(TDL_DATA_TYPE_T key_type)
{
    switch (key_type)
    {
        case TDL_KEY_ENC_BREDR:     return SIZE_ENC_BREDR;
        case TDL_KEY_ENC_CENTRAL:   return SIZE_ENC_CENTRAL;
        case TDL_KEY_DIV:           return SIZE_DIV;
        case TDL_KEY_ID:            return SIZE_ID;
        default:
            break;
    }
    return 0;
}

/****************************************************************************
NAME
    pack_td_bdaddr

FUNCTION
    Pack a type and bdaddr address into the td_data_t type. 

RETURNS

*/
static void pack_td_bdaddr(td_data_t *td, uint8 type, const bdaddr *addr)
{
    td->content.addr_type = type;
    td->bdaddr[0] = addr->nap;
    td->bdaddr[1] = (uint16)addr->uap << 8 | 
                    (uint16)((addr->lap & 0x00FF0000) >> 16);
    td->bdaddr[2] = (uint16)addr->lap;
}

/****************************************************************************
NAME
    unpack_td_typed_bdaddr

FUNCTION
    Unpack a typed_bdaddr address from the td_data_t type. 

RETURNS
    bdaddr type (TYPED_BDADDR_*).
*/
static uint8 unpack_td_bdaddr(bdaddr *addr, const td_data_t *td)
{
    addr->nap = (uint16)td->bdaddr[0];
    addr->uap = (uint8)(td->bdaddr[1] >> 8);
    addr->lap = (uint32)(td->bdaddr[1] & 0xFF) << 16 | td->bdaddr[2];
    return (uint8)td->content.addr_type;
}


/****************************************************************************
NAME
    unpack_td_TYPED_BDADDR_T

FUNCTION
    Unpack a TYPED_BD_ADDR_T address from the td_data_t type. 

RETURNS

*/
static void unpack_td_TYPED_BDADDR_T(
                TYPED_BD_ADDR_T *addrt, 
                const td_data_t *td
                )
{
    addrt->type     = (uint8_t)td->content.addr_type;
    addrt->addr.nap = (uint16_t)td->bdaddr[0];
    addrt->addr.uap = (uint8_t)(td->bdaddr[1] >> 8);
    addrt->addr.lap = (uint24_t)(td->bdaddr[1] & 0xFF) << 16 | td->bdaddr[2];
}


/****************************************************************************
NAME
    pack_td_security_requirements

FUNCTION
    Pack a key security requirements into the td_data_t type. The 
    dm_prim.h defines DM_SM_SECURITY_ only use 3-bits (that VM is interested 
    in), only the top bit needs to be relocated.

RETURNS

*/
static void pack_td_security_requirements(
                    td_data_t   *td,
                    uint16      security_requirements
                    )
{
    /* copy bits 3 and 1. */
    td->content.security_req = security_requirements & 0x5;
    /* relocate bit 15 to bit 2 */
    td->content.security_req |= security_requirements >> 13 & 0x2;
}

/****************************************************************************
NAME
    unpack_td_security_requirements

FUNCTION
    Unpack the key security requirements from the td_data_t type.

RETURNS

*/
static uint16 unpack_td_security_requirements(const td_data_t *td)
{
    /* copy bits 3 and 1 */
    uint16 sec_req = td->content.security_req & 0x05;
    /* Relocate bit 2 back to bit 15 */
    sec_req |= (td->content.security_req & 0x2) << 13;

    return sec_req;
}

/****************************************************************************
NAME
    calc_td_data_size

FUNCTION
    Calculates the size of a td_data_t data field, based on the data flags set 
    in the content field.

RETURNS

*/
static uint16 calc_td_data_size(content_t content)
{
    uint16 size = 0;
    uint16 dt;

    for (dt = TDL_KEY_ENC_BREDR; dt < TDL_KEY_UNKNOWN; dt++)
        if (content.data_flags & (1<<dt))
            size += get_data_type_size((TDL_DATA_TYPE_T)dt);
    
    return size;
}    

/* Calculate the size of td_data_t var passed as a PTR to the macro */
#define CALC_TD_SIZE(TDP)  (SIZE_TD + calc_td_data_size((TDP)->content))

/****************************************************************************
NAME
    calc_td_data_offset

FUNCTION
    Calculates the index offset to the data related to a specific link key,
    as indicated by the flag settings int the content_t type. 

    The order of keys is specific to the TDL_DATA_TYPE_T, if they are changed
    in that type the changes must also be reflected here.
    
RETURNS
    uint16
*/
  
static uint16 calc_td_data_offset(
                    content_t       content, 
                    TDL_DATA_TYPE_T data_type
                    )
{
    uint16_t offset = 0;

    if (data_type == TDL_KEY_ENC_BREDR) return offset;
    if (content.data_flags & MASK_ENC_BREDR) offset += SIZE_ENC_BREDR;

    if (data_type == TDL_KEY_ENC_CENTRAL) return offset;
    if (content.data_flags & MASK_ENC_CENTRAL) offset += SIZE_ENC_CENTRAL;

    if (data_type == TDL_KEY_DIV) return offset;
    if (content.data_flags & MASK_DIV) offset += SIZE_DIV;

    /* Assume that the data type is TDL_KEY_ID, offset will be to that key. */
    return offset;
}

/****************************************************************************
NAME
    pack_td_key

FUNCTION
    Pack a DM_SM_UKEY_T key, indicated by the DM_SM_KEY_TYPE_T.  

RETURNS

*/
static void pack_td_key(
            td_data_t               **tdp, 
            const uint16            *key, 
            DM_SM_KEY_TYPE_T        dm_sm_key_type)
{
    td_data_t *td = *tdp;
    TDL_DATA_TYPE_T key_type = convert_dm_sm_to_tdl_key_type(dm_sm_key_type);
    uint16_t offset = calc_td_data_offset(td->content, key_type);
    uint16_t key_size = get_data_type_size(key_type);
    uint16_t key_mask = (1 << key_type);

    /* If not already set, then realloc the td->data to make space.*/
    if (!(td->content.data_flags & key_mask))
    {
        uint16_t size_prev_data = calc_td_data_size(td->content);

        /* Set the content data flag bit to 1 for this key type so that
         * the new size of td_data can be calculated.
         */
        td->content.data_flags |= key_mask;

        *tdp = 
            (td_data_t *) PanicNull(
                    realloc(td,  SIZE_TD + calc_td_data_size(td->content) )
                    );

        td = *tdp;

        /* Copy data to make space for new data, if it is below it. */
        memmove(
                &td->data[ offset + key_size ], 
                &td->data[offset], 
                size_prev_data - offset
               );
    }

    memmove(&td->data[offset], key, key_size);
}


/****************************************************************************
NAME
    unpack_td_key

FUNCTION
    Unpack a DM_SM_UKEY_T key, indicated by the DM_SM_KEY_TYPE_T.  

RETURNS

*/ 
static void unpack_td_key(
                uint16                  *key, 
                const td_data_t         *td,    
                const TDL_DATA_TYPE_T   key_type
                )
{
    uint16_t key_size = get_data_type_size(key_type);
    uint16_t offset = calc_td_data_offset(td->content, key_type);

    memmove(key, &td->data[offset], key_size);
}




/****************************************************************************
NAME
    dm_sm_add_device_req

FUNCTION
    This function creates and populates a DM_SM_ADD_DEVICE_REQ primitive 
    and sends it to Bluestack to register a device with the Bluestack 
    Security Manager

RETURNS

*/
static void dm_sm_add_device_req( const td_data_t *td )
{   
    uint16 key_present[DM_SM_MAX_NUM_KEYS] = {
        DM_SM_KEY_NONE,
        DM_SM_KEY_NONE,
        DM_SM_KEY_NONE,
        DM_SM_KEY_NONE,
        DM_SM_KEY_NONE
    };
    uint16  key_idx = 0;
    uint16  dt;

    MAKE_PRIM_T(DM_SM_ADD_DEVICE_REQ);

    unpack_td_TYPED_BDADDR_T(&prim->addrt, td);

    /* The Privacy and Data Signing are not currently supported and 
     * so the following fields are default.
     */
    prim->privacy =  DM_SM_PRIVACY_DISABLED;
    prim->reconnection_bd_addr.lap = 0;
    prim->reconnection_bd_addr.uap = 0;
    prim->reconnection_bd_addr.nap = 0;

    prim->trust = 
        td->content.trusted ? DM_SM_TRUST_ENABLED : DM_SM_TRUST_DISABLED;

    prim->keys.security_requirements = unpack_td_security_requirements(td);

    for (dt = TDL_KEY_ENC_BREDR; dt < TDL_KEY_UNKNOWN; dt++)
    {
        uint16 *key;
        if (td->content.data_flags & (1<<dt))
        {
            switch(dt)
            {
                case TDL_KEY_ENC_BREDR:
                    key_present[key_idx] = DM_SM_KEY_ENC_BREDR;
                    key = (uint16 *) PanicUnlessMalloc(
                            sizeof(DM_SM_KEY_ENC_BREDR_T)
                            );
                    break;
                case TDL_KEY_ENC_CENTRAL:
                    key_present[key_idx] = DM_SM_KEY_ENC_CENTRAL;
                    key = (uint16 *) PanicUnlessMalloc(
                            sizeof(DM_SM_KEY_ENC_CENTRAL_T)
                            );
                    break;
                case TDL_KEY_DIV:
                    key_present[key_idx] = DM_SM_KEY_DIV;
                    key = 0;
                    break;
                case TDL_KEY_ID:
                    key_present[key_idx] = DM_SM_KEY_ID;
                    key = (uint16 *) PanicUnlessMalloc(
                            sizeof(DM_SM_KEY_ID_T)
                            );
                    break;

                default:
                    /* To please the compiler. */
                    break;
            }

            if (dt == TDL_KEY_DIV)
            {
                unpack_td_key((uint16 *)&key, td, dt);
            }
            else
            {
                unpack_td_key(key, td, dt);
                key = VmGetHandleFromPointer(key);
            }

            prim->keys.u[key_idx++].none = (void *)key;
        }
    }

    UNPACK_TD_ENC_KEY_SIZE(prim->keys.encryption_key_size,td);

    prim->keys.present = DM_SM_KEYS_PRESENT(
            key_present[0],
            key_present[1],
            key_present[2],
            key_present[3],
            key_present[4],
            DM_SM_KEYS_UPDATE_EXISTING
            );
    VmSendDmPrim(prim);
}

/*************************************************************************
NAME    
    tdl_find_device
    
DESCRIPTION
    Find a device from the trusted device list.
    
RETURNS
    pointer to the device data (must be freed by the caller), or NULL
    position of the record, or empty slot pos in case of device not found
    index of the current position
*/
static td_data_t *tdl_find_device(
                        uint8                   addr_type,
                        const bdaddr            *addr, 
                        uint16                  *pp, 
                        uint16                  *pi
                        )
{
    td_data_t *td = (td_data_t *) PanicUnlessMalloc(SIZE_TD_DATA_T);
    one_slot *os = PanicUnlessNew(one_slot);
    uint16 used = 0;
    uint16 pos;
    uint16 idx;
    uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;
    
    read_trusted_device_index(&os->tdi);

    for (idx = 0;
         idx < max_trusted_devices && (pos = os->tdi.order[idx]) != TDI_UNUSED;
         idx++)
    {
        if (PsRetrieve(TRUSTED_DEVICE_LIST + pos, td, SIZE_TD_DATA_T))
        {
            os->dev_taddr.type = unpack_td_bdaddr(&os->dev_taddr.addr, td);

            if (
                os->dev_taddr.type == addr_type && 
                BdaddrIsSame(&os->dev_taddr.addr, addr)
                )
            {
                /* found our device */
                goto out;
            }

            /* mark slot as used */
            used |= 1 << pos;
        }
    }

    /* device data not needed anymore */
    free(td);
    td = NULL;

    if (idx < max_trusted_devices)
    {
        /* find first free slot */
        /* we do know that there is a free slot so no need for checking
         * idx < max_trusted_devices */
        for (pos = 0; used & (1 << pos); pos++);
    }
    else
    {
        /* tdl is full, return the last position */
        idx = max_trusted_devices - 1;
        pos = os->tdi.order[idx];
    }

out:
    free(os);

    if (pp)
    {
        *pp = pos;
    }

    if (pi)
    {
        *pi = idx;
    }
    
    return td;
}

/****************************************************************************
NAME
    connectionInitTrustedDeviceList

FUNCTION
    This function is called to initialise the Trusted Device List.  All
    devices in the list are registered with the Bluestack Security Manager.

RETURNS
    The number of devices registered with Bluestack
*/
/****************************************************************************

DESCRIPTION
    This function updates the Trusted Device Index
*/
static void update_trusted_device_index(    
    const uint16 pos, 
    const uint16 idx
    )
{
    td_index_t      tdi;
    uint16                      index;
    
    /* Read the TDI from persistent store */
    read_trusted_device_index(&tdi);
    
    /* Re-order TDI */
    for(index = 0; index < idx; index++)
    {
        tdi.order[idx - index] = tdi.order[idx - index - 1];
    }
        
    /* Update with the position of the new record in the TDL as MRU 
     * device. 
     */
    tdi.order[0] = pos;
        
    /* Store persistently */
    store_trusted_device_index(&tdi);
}

/****************************************************************************

DESCRIPTION
    This function will delete an entry from the trusted device index and
    then delete the list entry itself.
*/
static uint16 delete_from_trusted_device_list(uint16 pos, uint16 idx)
{
    td_index_t tdi;
    uint16 i;
    uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;
    
    /* Read the TDI from persistent store */
    read_trusted_device_index(&tdi);
        
    /* Delete index from TDI and reorder TDI */
    for(i = idx; i < max_trusted_devices - 1; i++)
        tdi.order[i] = tdi.order[i + 1];

    /* LRU index is now invalid */
    tdi.order[max_trusted_devices - 1] = TDI_UNUSED;
        
    /* Store persistently */
    store_trusted_device_index(&tdi);

    /* Delete the list entry */
    PsStore(TRUSTED_DEVICE_LIST + pos, NULL, 0);


    return TRUE;
}

/****************************************************************************
NAME
    connectionInitTrustedDeviceList

FUNCTION
    This function is called to initialise the Trusted Device List.  All
    devices in the list are registered with the Bluestack Security Manager.

RETURNS
    The number of devices registered with Bluestack
*/
uint16 connectionInitTrustedDeviceList(void)
{
    uint16 i;
    uint16 pos; /* TRUSTED_DEVICE_LIST + pos */
    td_index_t tdi;
    td_data_t *td;
    uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;
    
    /* read the device index */
    read_trusted_device_index(&tdi);

    td = PanicUnlessMalloc(SIZE_TD_DATA_T);

    for (i = 0;
         i < max_trusted_devices && (pos = tdi.order[i]) != TDI_UNUSED;
         i++)
    {
        if (PsRetrieve(TRUSTED_DEVICE_LIST + pos, td, SIZE_TD_DATA_T))
        {
            dm_sm_add_device_req(td);
        }
        /* If we fail to read a Link Key then the link keys and index are out
         * of step - this can lead to an infinite reset cycle. To avoid this,
         * delete the TDL and Index, then Panic to cause a reset.
         */
        else
        {
            uint16 j;


            /* Delete the index */
            PsStore(TRUSTED_DEVICE_INDEX, NULL, 0);

            /* Delete all the List Entry PS Keys */
            for (j = 0; j < max_trusted_devices; j++);
            {
                PsStore(TRUSTED_DEVICE_LIST + j, NULL, 0);
            }

            CL_DEBUG_INFO((
                "ERROR: Could not read TDL Entry at index %d, position %d\n",
                i, 
                pos
                ));
            Panic();
        }
    }
        
    free(td);

    return i;
}

/****************************************************************************
NAME
    connectionAuthAddDevice

FUNCTION
    This function is called to add a trusted device to the persistent trusted 
    device list.  A flag indicating if the device was successfully added is
    returned.
*/
bool connectionAuthAddDevice(const CL_INTERNAL_SM_ADD_AUTH_DEVICE_REQ_T *req)
{
    uint16          pos; /* TRUSTED_DEVICE_LIST + pos */
    uint16          idx; /* tdi.order[idx] */
    td_data_t       *td     = NULL;
    uint16          ok      = TRUE;
                    /* If there is a link key, there is encryption. */
    uint16          sec_req = DM_SM_SECURITY_ENCRYPTION;

    td = tdl_find_device(TBDADDR_PUBLIC, &req->bd_addr, &pos, &idx);

    /* If not bonded BUT there is an existing entry in the TDL, then this 
     * device did have a bonded connection but now it does not. Therefore,
     * delete the previously bonded link key.
     */
    if(!req->bonded && td)
        delete_from_trusted_device_list(pos, idx);

    /* If the device is not already in the TDI then we may have to add it. */
    if (!td)
    {
        td = (td_data_t *)PanicNull( calloc(1,  SIZE_TD ) );
        pack_td_bdaddr(td, TYPED_BDADDR_PUBLIC, &req->bd_addr);
    }

    /* Update the stored link key */
    pack_td_key(&td, (uint16 *)&req->enc_bredr ,DM_SM_KEY_ENC_BREDR);
    td->content.trusted = req->trusted ? TRUE : FALSE;
    
    /* 
        When adding, the device is always a non-priority device.
        This is catered for already by 'td' struct being calloc'd.
    */

    if(req->bonded && req->enc_bredr.link_key_type != DM_SM_LINK_KEY_DEBUG)
    {       
        sec_req |= DM_SM_SECURITY_BONDING;
        
        if (
            req->enc_bredr.link_key_type == DM_SM_LINK_KEY_AUTHENTICATED_P192 ||
            req->enc_bredr.link_key_type == DM_SM_LINK_KEY_AUTHENTICATED_P256
           )
        {
            sec_req |= DM_SM_SECURITY_MITM_PROTECTION;
        }

        pack_td_security_requirements(td, sec_req);
        
        /* Store trusted device persistently in the list */
        if  ( !PsStore(TRUSTED_DEVICE_LIST + pos, td, CALC_TD_SIZE(td)) )
        {
            ok = FALSE;
        }
        else
        {
            /* Keep a track of the most recently used device by updating the 
             * TDI. Update the index AFTER the list entry, to help avoid 
             * mismatch * errors.
             */
            update_trusted_device_index(pos, idx);
            
            /*
                To keep TDL properly sorted we need to explicitly
                call the SetPriority function setting it as a non-priority
                device. Otherwise the sorting wouldn't happen.
            */
            ok = ConnectionAuthSetPriorityDevice(&req->bd_addr, FALSE);
        }
    }
    else
    {
        pack_td_security_requirements(td, sec_req);        
    }
    
    /* Update the device in the Bluestack Security Manager database */
    dm_sm_add_device_req(td);
    free(td);
    
    return ok;     
}

/****************************************************************************
NAME
    connectionAuthGetDevice

FUNCTION
    This function is called to get a trusted device from the persistent trusted 
    device list.  A flag indicating if the device was found is returned.
*/
bool connectionAuthGetDevice(
            const bdaddr *peer_bd_addr,
            cl_sm_link_key_type *link_key_type,
            uint16 *link_key,
            uint16 *trusted
            )
{
    td_data_t *td;

    if ((td = tdl_find_device(TYPED_BDADDR_PUBLIC, peer_bd_addr, NULL, NULL)))
    {
        DM_SM_KEY_ENC_BREDR_T enc_bredr;

        unpack_td_key((uint16 *)&enc_bredr, td, TDL_KEY_ENC_BREDR);
        
        *link_key_type = connectionConvertLinkKeyType(enc_bredr.link_key_type);
        memmove(link_key, &enc_bredr.link_key, BREDR_KEY_SIZE);

        *trusted = td->content.trusted;

        free(td);
        
        return TRUE;
    }

    return FALSE;
}



/****************************************************************************
NAME
    connectionAuthDeleteDevice

FUNCTION
    This function is called to remove a trusted device from the persistent 
    trusted device list.  A flag indicating if the device was successfully 
    removed is returned.
*/
bool connectionAuthDeleteDevice(
        uint8           type,
        const bdaddr*   peer_bd_addr
        )
{
    uint16 pos; /* TRUSTED_DEVICE_LIST + pos */
    uint16 idx; /* tdi.order[idx] */
    td_data_t *td;

    /* Remove from the BlueStack security datatbase */
    MAKE_PRIM_T(DM_SM_REMOVE_DEVICE_REQ);

    prim->addrt.type = type;
    BdaddrConvertVmToBluestack(&prim->addrt.addr, peer_bd_addr);

    VmSendDmPrim(prim);

    /* Search the trusted device list for the specified device */
    if ((td = tdl_find_device(type, peer_bd_addr, &pos, &idx)))
    {
        /* Delete it and re-order TDI */
        delete_from_trusted_device_list(pos, idx);

        free(td);
        
        return TRUE;
    }

    return FALSE;
}


/****************************************************************************
NAME
    connectionAuthDeleteAllDevices

FUNCTION
    This function is called to remove all trusted devices from the persistent 
    trusted device list.  A flag indicating if all the devices were 
    successfully removed is returned.

RETURNS
    TRUE if even one link key is deleted, returns FALSE if the TDL is empty.
*/
bool connectionAuthDeleteAllDevice(uint16 ps_base)
{
    /* Flag to indicate if the devices were deleted */
    bool            deleted = FALSE;
    
    /* Trusted device list record index */
    uint16          rec = 0;
    
    /* Trusted device record */
    td_data_t       *td =  (td_data_t *) PanicUnlessMalloc(SIZE_TD_DATA_T);
    
    /* trusted device index */
    td_index_t      tdi;
    uint16 max_trusted_devices = MAX_TRUSTED_DEVICES;
    
    /* Delete Trusted Device Index (TDI) - actually, set all index entries to
     * 0xF, which indicates the index entry is unused. This is done first 
     * in case the PS journal becomes full on this PsStore operation. 
     */
    memset(&tdi, TDI_UNUSED, sizeof(td_index_t));
    store_trusted_device_index(&tdi);
    
    /* Loop through list of trusted devices */
    for(rec = 0; rec < max_trusted_devices; rec++)
    {
        if  (
            PsRetrieve(
                TRUSTED_DEVICE_LIST + rec,
                td,
                SIZE_TD_DATA_T
                )
            )
        {
            /* Unregister with Bluestack security manager */
            MAKE_PRIM_T(DM_SM_REMOVE_DEVICE_REQ);
            unpack_td_TYPED_BDADDR_T(&prim->addrt, td);

            /* Delete entry from TDL */
            (void)PsStore(TRUSTED_DEVICE_LIST + rec, NULL, 0);
            deleted = TRUE;

            VmSendDmPrim(prim);
        }

        /* Delete any associated attribute data */
        (void)PsStore(PSKEY_TDL_ATTRIBUTE_BASE + rec, NULL, 0);
    }
    free(td);
    
    return deleted;
}


/****************************************************************************
NAME
    connectionAuthSetTrustLevel

FUNCTION
    This function is called to set the trust level of a device stored in the
    trusted device list.  The Bluestack Security Manager is updated with the
    change.

RETURNS
    TRUE is record updated, otherwise FALSE
*/
bool connectionAuthSetTrustLevel(const bdaddr* peer_bd_addr, uint16 trusted)
{
    uint16 pos; /* TRUSTED_DEVICE_LIST + pos */
    td_data_t *td;

    if ((td = tdl_find_device(TYPED_BDADDR_PUBLIC, peer_bd_addr, &pos, NULL)))
    {
        /* Update the trust level */
        td->content.trusted = trusted ? TRUE : FALSE;

        /* Store the record */
        PsStore(TRUSTED_DEVICE_LIST + pos, td, CALC_TD_SIZE(td));

        /* Update Bluestack Security Manager Database */
        dm_sm_add_device_req(td);

        free(td);
        
        /* Record updated */
        return TRUE;
    }
    
    /* Record for this device does not exist */
    return FALSE;
}

/****************************************************************************
NAME
    ConnectionAuthSetPriorityDevice

FUNCTION
    This function is called to set the priority flag of a device
    stored in the trusted device list.  The Blustack Security Manager
    is updated with the change.

RETURNS
    TRUE if record updated, otherwise FALSE
*/
bool ConnectionAuthSetPriorityDevice(
        const bdaddr* bd_addr, 
        uint16 is_priority_device
        )
{
    uint16      pos;
    uint16      idx; 
    td_data_t   *td;

    if ((td = tdl_find_device(TYPED_BDADDR_PUBLIC, bd_addr, &pos, &idx)))
    {
        /* Update the priority flag */
        td->content.priority_device = is_priority_device ? TRUE : FALSE;

        /* Store the record */
        PsStore(TRUSTED_DEVICE_LIST + pos, td, CALC_TD_SIZE(td));

        /* Update Bluestack Security Manager Database */
        /* dm_sm_add_device_req(td); */

        /* update the MRU status of the device */
        update_trusted_device_index(pos, idx);
        
        /*
           If we are removing the priority status we need to
           move the device down the TDL to be below any still
           existing priority devices.
        */
        if (!is_priority_device)
        {
            uint16      temp;
            uint16      index;
            td_index_t  tdi;

            /* Read the TDI from persistent store */
            read_trusted_device_index(&tdi);

            /* check all devices to the right to see if they're priority */
            for (index = 1; index<MAX_NO_DEVICES_TO_MANAGE; index++)
            {
                /* if we're at the end of (a non-full) list we're done*/
                if (tdi.order[index] == TDI_UNUSED)
                {
                    break;
                }
                
                /* otherwise get device's priority */
                PsRetrieve(
                        TRUSTED_DEVICE_LIST + tdi.order[index],
                        td,
                        SIZE_TD_DATA_T
                        );
                
                /* if it is a priority device, swap places */
                if (td->content.priority_device)
                {
                    temp = tdi.order[index];
                    tdi.order[index] = tdi.order[index-1];
                    tdi.order[index-1] = temp;
                }
                else
                {
                    /* if it's non-priority device, we're done */
                    break;
                }
            }
            
            /* we have to store modified TDL Index */
            store_trusted_device_index(&tdi);
        }
        
        free(td);
        
        /* Record updated */
        return TRUE;
    }
    
    /* Record for this device does not exist */
    return FALSE;
}


/****************************************************************************
NAME
    connectionAuthUpdateMru

FUNCTION
    This function is called to keep a track of the most recently used device.
    The TDI index is updated provided that the device specified is currently
    stored in the TDL.
*/
uint16 connectionAuthUpdateMru(const bdaddr* peer_bd_addr)
{
    uint16 pos; /* TRUSTED_DEVICE_LIST + pos */
    uint16 idx; /* tdi.order[idx] */
    td_data_t *td;

    if ((td = tdl_find_device(TYPED_BDADDR_PUBLIC, peer_bd_addr, &pos, &idx)))
    {
        /* Keep a track of the most recently used device by updating the TDI. */
        update_trusted_device_index(pos, idx);

        free(td);

        return TRUE;
    }

    return FALSE;
}

/****************************************************************************
NAME
    connectionAuthPutAttribute

FUNCTION
    This function is called to store the specified data in the specified 
    persistent  store key.  The persistent store key is calculated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
void connectionAuthPutAttribute(
        uint16          ps_base,
        uint8           addr_type,
        const bdaddr*   bd_addr,
        uint16          size_psdata,
        const uint8*    psdata
        )
{
    uint16 pos; /* TRUSTED_DEVICE_LIST + pos */
    td_data_t *td;

    if ((td = tdl_find_device(addr_type, bd_addr, &pos, NULL)))
    {
        PsStore(PSKEY_TDL_ATTRIBUTE_BASE + pos, psdata, size_psdata);
        free(td);
    }
}


/****************************************************************************
NAME
    connectionAuthGetAttribute

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calculated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
void connectionAuthGetAttribute(
        Task appTask,
        uint16 ps_base,
        uint8 addr_type,
        const bdaddr* bd_addr,
        uint16 size_psdata
        )
{
    if (appTask)
    {
        /* Send a message back to the application task */
        MAKE_CL_MESSAGE_WITH_LEN(CL_SM_GET_ATTRIBUTE_CFM, size_psdata);
        message->size_psdata = size_psdata;
        message->psdata[0] = 0;
        
        message->bd_addr = *bd_addr;
        
        if (
                connectionAuthGetAttributeNow(
                    ps_base, 
                    addr_type,
                    bd_addr,
                    size_psdata, 
                    message->psdata)
           )
        {
            message->status = success;
        }
        else
        {
            message->status = fail;
        }
        
        MessageSend(appTask, CL_SM_GET_ATTRIBUTE_CFM, message);
    }
}


/****************************************************************************
NAME
    connectionAuthGetAttributeNow

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calculated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
bool connectionAuthGetAttributeNow(
        uint16 ps_base,
        uint8 addr_type,
        const bdaddr* bd_addr,
        uint16 size_psdata,
        uint8* psdata
        )
{
    uint16 pos; /* TRUSTED_DEVICE_LIST + pos */
    td_data_t *td;

    if ((td = tdl_find_device(addr_type, bd_addr, &pos, NULL)))
    {
        free(td);
        
        if(size_psdata)
        {
            /* Read attribute data */
            if(PsRetrieve(PSKEY_TDL_ATTRIBUTE_BASE + pos, psdata, size_psdata))
            {
                return TRUE;
            }
        }
        else
        {
            /* No attribute data required, so just indicate success */
            return TRUE;
        }
    }   

    return FALSE;
}

/****************************************************************************
NAME
    connectionAuthGetIndexedAttribute

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calculated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
void connectionAuthGetIndexedAttribute(
    Task appTask,
    uint16 ps_base,
    uint16 mru_index, 
    uint16 size_psdata
    )
{
    /* Send a message back to the application task */
    MAKE_CL_MESSAGE_WITH_LEN(CL_SM_GET_INDEXED_ATTRIBUTE_CFM, size_psdata);
    message->size_psdata = size_psdata;
    message->psdata[0] = 0;

    if (
            connectionAuthGetIndexedAttributeNow(
                ps_base, 
                mru_index,
                size_psdata,
                message->psdata,
                &message->taddr)
       )
    {
        message->status = success;
    }
    else
    {
        message->status = fail;
    }

    /* Send confirmation back to application */
    MessageSend(appTask, CL_SM_GET_INDEXED_ATTRIBUTE_CFM, message);
}


/****************************************************************************
NAME
    connectionAuthGetIndexedAttributeNow

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calulated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
bool connectionAuthGetIndexedAttributeNow(
        uint16          ps_base,
        uint16          mru_index,
        uint16          size_psdata,
        uint8           *psdata,
        typed_bdaddr    *taddr
        )
{
    td_index_t      tdi;    
    bool            success = FALSE;
    uint16          max_trusted_devices = MAX_TRUSTED_DEVICES;
    
    /* Read Trusted Device Index from Persistent store */
    read_trusted_device_index(&tdi);
    
    if (mru_index < max_trusted_devices)
    {
        /* Only want the address but need to read the maximum key size to
         * ensure PsRetrieve returns a positive (>0) response.
         */
        td_data_t  *td =  (td_data_t *) PanicUnlessMalloc(SIZE_TD_DATA_T);

        /* Read the device record from the Trusted Device List */
        if  (
            tdi.order[mru_index] != TDI_UNUSED &&
            PsRetrieve(
                (TRUSTED_DEVICE_LIST + tdi.order[mru_index]),
                td,
                SIZE_TD_DATA_T
                )
            )
        {
            /* Get Bluetooth address of device. */
            taddr->type = unpack_td_bdaddr(&taddr->addr, td);
                
            /* Check if application wants attribute data */
            if (size_psdata != 0)
            {
                /* Read attribute data */
                if  (
                    PsRetrieve(
                        PSKEY_TDL_ATTRIBUTE_BASE + tdi.order[mru_index],
                        psdata,
                        size_psdata)
                    )
                    success = TRUE;
            }
            else
            {
                /* No attribute data required, so just indicate success */
                success = TRUE;
            }
        }

        free(td);
        
    }
    return success;
}

/****************************************************************************
NAME
    connectionAuthUpdateTdl

FUNCTION
    Update the TDL for the device with keys indicated. Keys are packed
    for storage in PS, as much as possible. 

RETURNS

*/
void connectionAuthUpdateTdl(
    const TYPED_BD_ADDR_T   *addrt,
    const DM_SM_KEYS_T      *keys
    )
{
    uint16          pos; /* TRUSTED_DEVICE_LIST + pos */
    uint16          idx; /* tdi.order[idx] */
    td_data_t       *td;
    uint16          key_idx;
    uint16          key_type;

    typed_bdaddr *taddr = PanicUnlessNew(typed_bdaddr);
    BdaddrConvertTypedBluestackToVm(taddr, addrt);
    td = tdl_find_device(taddr->type, &taddr->addr, &pos, &idx);

    /* Device not found - create new entry */
    if (!td)
    {
        td = (td_data_t *)PanicNull( calloc(1,  SIZE_TD ) );
        pack_td_bdaddr(td, taddr->type, &taddr->addr);
    }

    free(taddr);

    pack_td_security_requirements(td, keys->security_requirements);

    PACK_TD_ENC_KEY_SIZE(td, keys->encryption_key_size);

    for (key_idx=0; key_idx<DM_SM_MAX_NUM_KEYS; key_idx++)
    {
        key_type = 
            keys->present >> (DM_SM_NUM_KEY_BITS * key_idx) & DM_SM_KEY_MASK;

        if (key_type == DM_SM_KEY_NONE)
        {
            continue;
        }
        else if (key_type == DM_SM_KEY_DIV)
        {
            pack_td_key(&td, &keys->u[key_idx].div, DM_SM_KEY_DIV);
        }
        else
        {
            pack_td_key(&td, (uint16 *)keys->u[key_idx].none, key_type);
        }
    }

    /* Update the trusted device list to indicate this was the most recent. */
    if ( PsStore(TRUSTED_DEVICE_LIST + pos, td, CALC_TD_SIZE(td)) )
        update_trusted_device_index(pos, idx);

    free(td);
    
}


/****************************************************************************
NAME
    connectionAuthDeleteDeviceFromTdl

FUNCTION
    Seach the TDL for the device indicated and remove it from the index 
    (effectively deleteing it from the TDL). 

RETURNS

*/

void connectionAuthDeleteDeviceFromTdl(const TYPED_BD_ADDR_T *addrt)
{
    uint16          idx;
    uint16          pos;
    td_data_t       *td;
    typed_bdaddr    taddr;

    BdaddrConvertTypedBluestackToVm(&taddr, addrt);

    td = tdl_find_device(taddr.type, &taddr.addr, &pos, &idx);

    if (td)
    {
        delete_from_trusted_device_list(pos, idx);
        free(td);
    }  
}

#ifndef DISABLE_BLE
/****************************************************************************
NAME
    ConnectionDmBleAddTdlDevicesToWhiteList

FUNCTION
    Add devices in the TDL to the BLE White List 

RETURNS

*/
void ConnectionDmBleAddTdlDevicesToWhiteListReq(bool ble_only_devices)
{
    uint16      i;
    uint16      pos; /* TRUSTED_DEVICE_LIST + pos */
    td_index_t  tdi;
    td_data_t   *td;
    bdaddr      addr;
    uint8       addr_type;
    uint16      max_trusted_devices = MAX_TRUSTED_DEVICES;
    
    /* read the device index */
    read_trusted_device_index(&tdi);

    td = PanicUnlessMalloc(SIZE_TD_DATA_T);

    for (i = 0;
         i < max_trusted_devices && (pos = tdi.order[i]) != TDI_UNUSED;
         i++)
    {
        if (PsRetrieve(TRUSTED_DEVICE_LIST + pos, td, SIZE_TD_DATA_T))
        {
            /* If only adding BLE devices and there are no BLE link keys
             * for this device, then continue to the next in the list.
             */
            if (
                ble_only_devices &&  
                !(td->content.data_flags & BLE_ONLY_LINK_KEYS) 
               )
            {
                continue;
            }

            addr_type = unpack_td_bdaddr(&addr, td);
            ConnectionDmBleAddDeviceToWhiteListReq(addr_type, &addr);
        }
    }
        
    free(td);
}

/****************************************************************************
NAME
    ConnectionBondedToPrivacyEnabledDevice

FUNCTION
    Determine if this BlueCore is bonded with a privacy enabled device. 

RETURNS
    TRUE if it is bonded to a privacy enabled device, otherwise FALSE.

*/
bool ConnectionBondedToPrivacyEnabledDevice(void)
{
    uint16      i;
    uint16      pos; /* TRUSTED_DEVICE_LIST + pos */
    td_index_t  tdi;
    td_data_t*  td;
    bool        result = FALSE;
    uint16      max_trusted_devices = MAX_TRUSTED_DEVICES;

    /* Read the device index */
    read_trusted_device_index(&tdi);

    td = PanicUnlessMalloc(SIZE_TD_DATA_T);

    for (i = 0;
         i < max_trusted_devices && (pos = tdi.order[i]) != TDI_UNUSED;
         i++)
    {
        if (PsRetrieve(TRUSTED_DEVICE_LIST + pos, td, SIZE_TD_DATA_T))
        {
            /* Check for the IRK (ID link key). 
             * This indicates that we have bonded with a device using privacy.
             */
            if (td->content.data_flags & MASK_ID)
            {
                result = TRUE;
                break;
            }
        }
    }

    free(td);

    return result;
}

#endif /* DISABLE_BLE */
/*lint +e525 +e725 +e830 */
