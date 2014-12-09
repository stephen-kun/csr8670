/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    connection_tdl.h
    
DESCRIPTION
    Trusted device list handling header file.
*/

#ifndef    CONNECTION_TDL_H_
#define    CONNECTION_TDL_H_


/* The number of devices to manage. */
#define DEFAULT_NO_DEVICES_TO_MANAGE    (8)
#define MAX_NO_DEVICES_TO_MANAGE        (DEFAULT_NO_DEVICES_TO_MANAGE)
#define MIN_NO_DEVICES_TO_MANAGE        (1)


/****************************************************************************
NAME
	connectionInitTrustedDeviceList

FUNCTION
    This function is called initailise the managed list of trusted devices

RETURNS
    The number of devices registered with the Bluestack Security Manager
*/
uint16 connectionInitTrustedDeviceList(void);


/****************************************************************************
NAME
    connectionAuthAddDevice

FUNCTION
    This function is called to add a trusted device to the persistent trusted 
    device list

RETURNS
    TRUE or FALSE to indicate if the device was successfully added to the 
    Trusted device List
*/
bool connectionAuthAddDevice(const CL_INTERNAL_SM_ADD_AUTH_DEVICE_REQ_T *req);


/****************************************************************************
NAME
    connectionAuthGetDevice

FUNCTION
    This function is called to add a trusted device to the persistent trusted 
    device list.  A flag indicating if the device was found is returned.
*/
bool connectionAuthGetDevice(
            const bdaddr        *peer_bd_addr,
            cl_sm_link_key_type *link_key_type,
            uint16              *link_key,
            uint16              *trusted
            );


/****************************************************************************
NAME
    connectionAuthDeleteDevice

FUNCTION
    This function is called to remove a trusted device from the persistent 
    trusted device list.  A flag indicating if the device was successfully removed 
    is returned.
*/
bool connectionAuthDeleteDevice(
        uint8 type, 
        const bdaddr* peer_bd_addr
        );


/****************************************************************************
NAME
    connectionAuthDeleteAllDevices

FUNCTION
    This function is called to remove all trusted devices from the persistent 
    trusted device list.  A flag indicating if all the devices were successfully 
    removed is returned.
*/
bool connectionAuthDeleteAllDevice(uint16 ps_base);


/****************************************************************************
NAME
    connectionAuthSetTrustLevel

FUNCTION
    This function is called to set the trust level of a device stored in the
    trusted device list.  The Blustack Security Manager is updated with the
    change.

RETURNS
    TRUE is record updated, otherwise FALSE
*/
bool connectionAuthSetTrustLevel(const bdaddr* peer_bd_addr, uint16 trusted);

/****************************************************************************
NAME
    connectionAuthUpdateMru

FUNCTION
    This function is called to keep a track of the most recently used device.
    The TDI index is updated provided that the device specified is currently
    stored in the TDL.

RETURNS
    TRUE if device specified is in the TDL, otherwise FALSE
*/
uint16 connectionAuthUpdateMru(const bdaddr* peer_bd_addr);


/****************************************************************************
NAME
    connectionAuthGetMruBdAddr

FUNCTION
    This function is called get the Bluetooth Device Address of the Most
    Recently Used device

RETURNS
    Pointer to Bluetooth device address
*/
/*bdaddr connectionAuthGetMruBdAddr(void);*/


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
            uint8           bd_addr_type,
            const bdaddr*   bd_addr,
            uint16          size_psdata,
            const uint8*    psdata
            );


/****************************************************************************
NAME
    connectionAuthGetAttribute

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calulated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
void connectionAuthGetAttribute(
            Task            appTask, 
            uint16          ps_base, 
            uint8           bd_addr_type,
            const bdaddr*   bd_addr, 
            uint16          size_psdata
            );


/****************************************************************************
NAME
    connectionAuthGetAttributeNow

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calulated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
bool connectionAuthGetAttributeNow(
            uint16          ps_base,
            uint8           bd_addr_type,
            const bdaddr*   bd_addr,
            uint16          size_psdata,
            uint8*          psdata
            );
    

/****************************************************************************
NAME
    connectionAuthGetIndexedAttribute

FUNCTION
    This function is called to read the specified data from the specified 
    persistent store key.  The persistent store key is calulated from
    the specified base + the index of the specified device in TDL.

RETURNS
*/
void connectionAuthGetIndexedAttribute(
            Task    appTask,
            uint16  ps_base,
            uint16  mru_index,
            uint16  size_psdata
            );


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
            );

/****************************************************************************
NAME
    connectionAuthUpdateTdl

FUNCTION
    Update the TDL for the the device with keys indicated. Keys are packed
    for storage in PS, as much as possible. 

RETURNS

*/
void connectionAuthUpdateTdl(
            const TYPED_BD_ADDR_T   *addrt,
            const DM_SM_KEYS_T      *keys
            );

/****************************************************************************
NAME
    connectionAuthDeleteDeviceFromTdl

FUNCTION
    Seach the TDL for the device indicated and remove it from the index 
    (effectively deleteing it from the TDL). 

RETURNS

*/
void connectionAuthDeleteDeviceFromTdl(const TYPED_BD_ADDR_T *addrt);

#endif    /* CONNECTION_DM_SECURITY_AUTH_H_ */
