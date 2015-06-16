/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_connection_mgr.h

DESCRIPTION
    Connection manager for handling connection to remote devices.

*/


#ifndef _SOURCE_CONNECTION_MGR_H_
#define _SOURCE_CONNECTION_MGR_H_


/* application header files */
#include "source_inquiry.h"
#include "source_ps.h"
/* VM headers */
#include <bdaddr.h>
#include <stdlib.h>


/* number of different devices for which PIN codes are stored */
#define CONNECTION_MAX_DEVICE_PIN_CODES 4

/* the link supervision timeout to use for a connection
    the timeout is in 0.625ms units so here 8064 (0x1f80) * 0.625ms = 5 secs approx */
#define CONNECTION_LINK_SUPERVISION_TIMEOUT 0x1f80


typedef enum
{
    CONNECTION_DEVICE_PRIMARY = 0,
    CONNECTION_DEVICE_SECONDARY
} CONNECTION_DEVICE_T;

typedef struct
{
    uint16 number_device_pins;
    bdaddr addr[CONNECTION_MAX_DEVICE_PIN_CODES];
    uint16 index[CONNECTION_MAX_DEVICE_PIN_CODES];
} CONNECTION_DEVICE_PIN_CODES_T;

typedef struct
{
    PS_PIN_CONFIG_T pin;
    CONNECTION_DEVICE_PIN_CODES_T device;
} CONNECTION_PIN_CODE_STORE_T;


/* structure holding the connection variables */
typedef struct
{
    bdaddr remote_connection_addr;      
    unsigned remote_profiles_attempted:8;
    unsigned paired_device_index:8;
    unsigned paired_device_start:8;
    unsigned supported_profiles:8;      
    uint16 remote_manufacturer;
    uint16 profile_connected;
    CONNECTION_DEVICE_T device_number:2;  
    unsigned connected_device_ps_slot:2;
    unsigned manual_2nd_connection:1;
    unsigned disconnecting_a2dp_media_before_signalling:1;
    CONNECTION_PIN_CODE_STORE_T *connection_pin;
    uint16 connection_retries;
} CONNECTION_DATA_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    connection_mgr_can_pair

DESCRIPTION
    Determines if a pairing attempt should be accepted or rejected.
    
RETURNS
    TRUE - Allow pairing attempt
    FALSE - Reject pairing attempt

*/
bool connection_mgr_can_pair(const bdaddr *bd_addr);


/****************************************************************************
NAME    
    connection_mgr_can_connect

DESCRIPTION
    Determines if a incoming connection should be accepted or rejected.
    
RETURNS
    TRUE - Allow incoming connection
    FALSE - Reject incoming connection

*/
bool connection_mgr_can_connect(const bdaddr *bd_addr, PROFILES_T profile_connecting);


/****************************************************************************
NAME    
    connection_mgr_start_connection_attempt

DESCRIPTION
    Begins connecting to a remote device by sending the APP_CONNECT_REQ message. 
    The parameters passed in will determine the connection attempt:
        addr - A Bluetooth address can be supplied to connect to this device. 
                If this is NULL then the address will be filled in by the function based on the reconnection policy.
        profile - Can specify which profile to attempt first.
        delay - Can specify a delay before the APP_CONNECT_REQ message is sent.
    
*/
void connection_mgr_start_connection_attempt(const bdaddr *addr, PROFILES_T profile, uint16 delay);


/****************************************************************************
NAME    
    connection_mgr_connect_next_profile

DESCRIPTION
    Continues the connection attempt using the next profile that is enabled.
    
RETURNS
    TRUE - Connection attempt to the remote device was initiated using the next profile available
    FALSE - Connection was not attempted (for example, if there were no more profiles to try)

*/
bool connection_mgr_connect_next_profile(void);


/****************************************************************************
NAME    
    connection_mgr_connect_next_paired_device

DESCRIPTION
    Continues the connection attempt to the next device in the paired device list.
    
RETURNS
    TRUE - Connection attempt to the next remote device from the paired device list was initiated
    FALSE - Connection was not attempted (for example, if there were no more paired devices to try)

*/
bool connection_mgr_connect_next_paired_device(void);


/****************************************************************************
NAME    
    connection_mgr_set_incoming_connection

DESCRIPTION
    Stores the remote device as the device to connect with, as it has sent a connection request.

*/
void connection_mgr_set_incoming_connection(PROFILES_T profile, const bdaddr *addr);


/****************************************************************************
NAME    
    connection_mgr_clear_attempted_profiles

DESCRIPTION
    Resets which profiles have been attempted.

*/
void connection_mgr_clear_attempted_profiles(void);


/****************************************************************************
NAME    
    connection_mgr_get_current_profile

DESCRIPTION
    Returns which profile is currently being used in a connection attempt.

RETURNS
    The profile currently being used in a connection attempt.  

*/
PROFILES_T connection_mgr_get_current_profile(void);


/****************************************************************************
NAME    
    connection_mgr_any_connected_profiles

DESCRIPTION
    Returns if any profiles are currently connected.
    
RETURNS
    TRUE - There are profiles connected.
    FALSE - There are no profiles connected.

*/
bool connection_mgr_any_connected_profiles(void);


/****************************************************************************
NAME    
    connection_mgr_connect_further_device

DESCRIPTION
    Attempts to connect to a further remote device. 
    manual_connect - TRUE if the connection is user initiated, FALSE otherwise
    
RETURNS
    TRUE - Connection attempt to the next remote device was initiated
    FALSE - Connection to a remote device was not attempted

*/
bool connection_mgr_connect_further_device(bool manual_connect);


/****************************************************************************
NAME    
    connection_mgr_set_profile_connected

DESCRIPTION
    Registers a profile connection with the connection manager.

*/
void connection_mgr_set_profile_connected(PROFILES_T profile, const bdaddr *addr);


/****************************************************************************
NAME    
    connection_mgr_set_profile_disconnected

DESCRIPTION
    Registers a profile disconnection with the connection manager.

*/
void connection_mgr_set_profile_disconnected(PROFILES_T profile, const bdaddr *addr);


/****************************************************************************
NAME    
    connection_mgr_reset_pin_codes

DESCRIPTION
    Resets the stored PIN codes to their default states.

*/
void connection_mgr_reset_pin_codes(void);


/****************************************************************************
NAME    
    connection_mgr_find_pin_index_by_addr

DESCRIPTION
    Find PIN index by the Bluetooth address supplied
    
*/
uint16 connection_mgr_find_pin_index_by_addr(const bdaddr *addr);


/****************************************************************************
NAME    
    connection_mgr_get_next_pin_code

DESCRIPTION
    Return if next PIN code was found for the device with the Bluetooth address supplied 
    
*/
bool connection_mgr_get_next_pin_code(const bdaddr *addr);


/****************************************************************************
NAME    
    connection_mgr_set_link_supervision_timeout

DESCRIPTION
    Sets the link supervision timeout for the link associated with the supplied Sink
    
*/
void connection_mgr_set_link_supervision_timeout(Sink sink);


#endif /* _SOURCE_CONNECTION_MGR_H_ */
