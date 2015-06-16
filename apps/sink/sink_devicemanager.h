/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_devicemanager.h
    
DESCRIPTION
    
*/

#ifndef _SINK_DEVICEMANAGER_H_
#define _SINK_DEVICEMANAGER_H_

#include <connection.h>

#include "sink_configmanager.h"


/* Link types the sink device supports */
typedef enum
{
    sink_none  = 0x00,
    sink_hfp   = 0x01,
    sink_a2dp  = 0x02,
    sink_avrcp = 0x04,
    sink_swat  = 0x08
}sink_link_type;

/* HFP attributes */
typedef struct
{
    uint8 volume;
} hfp_attributes;

/* A2DP attributes */
typedef struct
{
    uint8  volume;
    uint16 clock_mismatch;
    uint16 audio_enhancements;
} a2dp_attributes;

/* sub woofer attributes */
typedef struct
{
    uint8 sub_trim_idx;    
} sub_attributes;

/* All device attributes stored in PS */
typedef struct
{
#ifdef ENABLE_PEER
    unsigned            :4;
    remote_features     peer_features:6;
    remote_device       peer_device:2;
#else
    unsigned            :12;
#endif
    sink_link_type      profiles:4;
    hfp_attributes      hfp;
    a2dp_attributes     a2dp;
    sub_attributes      sub;
} sink_attributes;


typedef struct
{
    bdaddr           bd_addr;
    sink_attributes  attributes;
} EVENT_UPDATE_ATTRIBUTES_T;


/* Connection mask */
typedef enum
{
    conn_hfp_pri  = 1 << 0,
    conn_hfp_sec  = 1 << 1,
    conn_a2dp_pri = 1 << 2,
    conn_a2dp_sec = 1 << 3
} conn_mask;

#define conn_hfp  (conn_hfp_pri | conn_hfp_sec)
#define conn_a2dp (conn_a2dp_pri | conn_a2dp_sec)


/****************************************************************************
NAME    
    deviceManagerGetDefaultAttributes
    
DESCRIPTION
    Initialise sink_attributes struct to default values

RETURNS
    void
*/
void deviceManagerGetDefaultAttributes(sink_attributes* attributes, bool is_subwoofer);


/****************************************************************************
NAME    
    deviceManagerGetAttributes
    
DESCRIPTION
    Get the attributes for a given device, or check device is in PDL if 
    attributes is NULL.

RETURNS
    TRUE if device in PDL, otherwise FALSE
*/
bool deviceManagerGetAttributes(sink_attributes* attributes, const bdaddr* dev_addr);


/****************************************************************************
NAME    
    deviceManagerGetIndexedAttributes
    
DESCRIPTION
    Get the attributes for a given index of device

RETURNS
    TRUE if successful, otherwise FALSE
*/
bool deviceManagerGetIndexedAttributes(uint8 index, sink_attributes* attributes, typed_bdaddr* dev_addr);

/****************************************************************************
NAME
    deviceManagerStoreAttributes
    
DESCRIPTION
    Stores given attribute values against a given device in PS.

RETURNS
    void
*/
void deviceManagerStoreAttributes(sink_attributes* attributes, const bdaddr* dev_addr);


/****************************************************************************
NAME
    deviceManagerStoreDefaultAttributes
    
DESCRIPTION
    Stores the default attributes against a given device in PS.

RETURNS
    void
*/
void deviceManagerStoreDefaultAttributes(const bdaddr* dev_addr, bool is_subwoofer);


/****************************************************************************
NAME
    deviceManagerUpdateAttributes
    
DESCRIPTION
    Stores the current attribute values for a given HFP/A2DP connection in
    PS.

RETURNS
    void
*/
void deviceManagerUpdateAttributes(const bdaddr* bd_addr, sink_link_type link_type, hfp_link_priority hfp_priority, a2dp_link_priority a2dp_priority);

/****************************************************************************
NAME
    deviceManagerMarkTrusted
    
DESCRIPTION
     Sets a device as trusted

RETURNS
    void
*/
void deviceManagerMarkTrusted(const bdaddr* dev_addr);

/****************************************************************************
NAME
    deviceManagerDelayedUpdateAttributes
    
DESCRIPTION
    Store attributes contained in EVENT_UPDATE_ATTRIBUTES_T in PS

RETURNS
    void
*/
void deviceManagerDelayedUpdateAttributes(EVENT_UPDATE_ATTRIBUTES_T* update);


/****************************************************************************
NAME
    deviceManagerSetPriority
    
DESCRIPTION
    Set a device's priority in the PDL

RETURNS
    void
*/
uint8 deviceManagerSetPriority(const bdaddr* dev_addr);


/****************************************************************************
NAME    
    deviceManagerRemoveDevice
    
DESCRIPTION
    Remove given device from the PDL

RETURNS
    void
*/
#define deviceManagerRemoveDevice(dev_addr) ConnectionSmDeleteAuthDevice(dev_addr)


/****************************************************************************
NAME    
    deviceManagerRemoveAllDevices
    
DESCRIPTION
    Remove all devices from the PDL

RETURNS
    void
*/
#define deviceManagerRemoveAllDevices() ConnectionSmDeleteAllAuthDevices(0)


/****************************************************************************
NAME    
    deviceManagerProfilesConnected
    
DESCRIPTION
    compare passed in bdaddr against those of the current connected devices,
    if a match is found returns true

RETURNS
    TRUE or FALSE
*/
conn_mask deviceManagerProfilesConnected(const bdaddr * bd_addr);


/****************************************************************************
NAME    
    deviceManagerNumConnectedDevs
    
DESCRIPTION
   determines the number of different connected devices, a device may connected
   both hfp and a2dp or only one of each
RETURNS
    number of connected devices
*/
uint8 deviceManagerNumConnectedDevs(void);


/****************************************************************************
NAME    
    deviceManagerNumConnectedPeerDevs
    
DESCRIPTION
   determines the number of different connected peer devices, a device will only
   have connected a2dp
RETURNS
    number of connected peer devices
*/
uint8 deviceManagerNumConnectedPeerDevs(void);


/****************************************************************************
NAME    
    deviceManagerCanConnect
    
DESCRIPTION
   Determines if max number of possible connections have been made
RETURNS
   TRUE if connection can be made, FALSE otherwise
*/
bool deviceManagerCanConnect(void);

/****************************************************************************
NAME    
    deviceManagerIsSameDevice
    
DESCRIPTION
    Determines if the supplied HF and AV devices are actually one and the same

RETURNS
    TRUE if the devices are the same, FALSE otherwise
*/
bool deviceManagerIsSameDevice(a2dp_link_priority a2dp_link, hfp_link_priority hfp_link);


/****************************************************************************
NAME    
    deviceManagerDeviceDisconnectedInd
    
DESCRIPTION
    Finds which device has been disconnected(primary or secondary) and sends the appropriate event to notify the same

RETURNS
    void
*/
void deviceManagerDeviceDisconnectedInd(const bdaddr* dev_addr);


#endif /* _SINK_DEVICEMANAGER_H_ */

