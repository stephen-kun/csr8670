/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_connection_mgr.c

DESCRIPTION
    Connection manager for handling connection to remote devices.

*/


/* header for this file */
#include "source_connection_mgr.h"
/* application header files */
#include "source_app_msg_handler.h"
#include "source_debug.h"
#include "source_led_handler.h"
#include "source_private.h"
#include "source_states.h"


#ifdef DEBUG_CONNECTION_MGR
    #define CONNECTION_MGR_DEBUG(x) DEBUG(x)
#else
    #define CONNECTION_MGR_DEBUG(x)
#endif    


/* local conection functions */
static void connection_mgr_set_remote_device(const bdaddr *addr);
static void connection_mgr_clear_remote_device(void);
static void connection_mgr_set_profile_attempt(PROFILES_T profile);
static void connection_mgr_restart_paired_device(void);
static bool connection_mgr_next_paired_device(typed_bdaddr *addr);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    connection_mgr_can_pair - Determines if a pairing attempt should be accepted or rejected
*/    
bool connection_mgr_can_pair(const bdaddr *bd_addr)
{
    switch (states_get_state())
    {        
        case SOURCE_STATE_INQUIRING:
        case SOURCE_STATE_CONNECTING:        
        {
            /* the remote connection address should be set in these states */
            if (!BdaddrIsZero(&theSource->connection_data.remote_connection_addr))
            {
                /* only accept pairing if this is the device currently in negotiation with */
                if (BdaddrIsSame(&theSource->connection_data.remote_connection_addr, bd_addr))
                    return TRUE;
                else
                    return FALSE;
            }
        }
        break;
        
        case SOURCE_STATE_DISCOVERABLE:        
        {
            return TRUE;
        }
        break;
        
        default:
        {
            /* fall through to end of function */
        }
        break;
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_can_connect - Determines if an incoming connection should be accepted or rejected
*/ 
bool connection_mgr_can_connect(const bdaddr *bd_addr, PROFILES_T profile_connecting)
{
    switch (states_get_state())
    {
        case SOURCE_STATE_CONNECTABLE:
        case SOURCE_STATE_DISCOVERABLE:
        case SOURCE_STATE_CONNECTED:
        {
            /* only allow incoming connection in these states */
            return TRUE;
        }
        break;
        
        case SOURCE_STATE_CONNECTING:
        {
            /* only allow incoming connection when connecting if the profiles are not connecting */
            if (!aghfp_is_connecting() && !a2dp_is_connecting())
                return TRUE;
        }
        break;
        
        default:
        {
            /* fall through to end of function */
        }
        break;
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_start_connection_attempt - Begins connecting to a remote device by sending the APP_CONNECT_REQ message
*/
void connection_mgr_start_connection_attempt(const bdaddr *addr, PROFILES_T profile, uint16 delay)
{
    MAKE_MESSAGE(APP_CONNECT_REQ); 
    message->force_inquiry_mode = FALSE;
    
    CONNECTION_MGR_DEBUG(("CM: Start remote connection attempt\n"));
    
    /* clear previous connection attempts and set profile to connect with */
    connection_mgr_clear_remote_device();
    connection_mgr_clear_attempted_profiles();
    connection_mgr_set_profile_attempt(profile);    
    
    if (addr != NULL)
    {
        CONNECTION_MGR_DEBUG(("    address supplied\n"));
        /* use address if supplied */
        connection_mgr_set_remote_device(addr);
    }
    else
    {
        /* not connecting to a specific address so force inquiry if the flag has been set */
        message->force_inquiry_mode = theSource->inquiry_mode.force_inquiry_mode;
        /* find address to use */
        if (theSource->ps_config->features.connect_policy == PS_CONNECT_LAST_DEVICE)
        {
            CONNECTION_MGR_DEBUG(("    connect to last\n"));
            /* address of last used remote device stored in PS */
            connection_mgr_set_remote_device(&theSource->ps_config->bdaddr_remote_device);
        }
        else
        {
            /* get address from the paired device list */
            typed_bdaddr paired_addr;
            bool paired_found = FALSE;
            
            connection_mgr_restart_paired_device();
            paired_found = connection_mgr_next_paired_device(&paired_addr);
            
            if (paired_found)
            {                
                CONNECTION_MGR_DEBUG(("    connect to paired\n"));
                DEBUG_BDADDR(paired_addr.addr);
                
                connection_mgr_set_remote_device(&paired_addr.addr);
            }
            else
            {
                CONNECTION_MGR_DEBUG(("    no device found\n"));
                /* don't wait for delay as there are no paired devices */
                delay = 0;
            }
        }
    }
    
    MessageSendLater(&theSource->app_data.appTask, APP_CONNECT_REQ, message, D_SEC(delay));
}


/****************************************************************************
NAME    
    connection_mgr_connect_next_profile - Continues the connection attempt using the next profile that is enabled
*/
bool connection_mgr_connect_next_profile(void)
{       
    uint16 supported_profiles = theSource->connection_data.supported_profiles;
    uint16 current_profile = connection_mgr_get_current_profile();   
    
    CONNECTION_MGR_DEBUG(("CM: Connect Next Profile - supported_profiles [%d] current_profile [%d]\n", supported_profiles, current_profile));
    
    while (current_profile != PROFILE_NONE)
    {
        /* move to next profile to try */
        current_profile = current_profile >> 1;  
        CONNECTION_MGR_DEBUG(("    current_profile [%d]\n", current_profile));
        
        /* break if this next profile is supported */
        if (current_profile & supported_profiles)
        {
            CONNECTION_MGR_DEBUG(("    profile found\n"));
            break; 
        }                
    }
            
    CONNECTION_MGR_DEBUG(("        next profile [%d]\n", current_profile));
    
    if (current_profile != PROFILE_NONE)
    {
        uint16 delay;
        MAKE_MESSAGE(APP_CONNECT_REQ);
        /* wait for the delay specified in the PS Key, to give chance for the remote device to connect the next profile */
        delay = theSource->ps_config->ps_timers.profile_connection_delay_timer;
        /* set profile to connect with */
        connection_mgr_set_profile_attempt(current_profile);
        /* send connect message */
        message->force_inquiry_mode = FALSE;
        MessageSendLater(&theSource->app_data.appTask, APP_CONNECT_REQ, message, delay);
        
        return TRUE;
    }

    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_connect_next_paired_device - Continues the connection attempt to the next device in the paired device list
*/
bool connection_mgr_connect_next_paired_device(void)
{
    typed_bdaddr paired_device;
    
    if (connection_mgr_next_paired_device(&paired_device))
    {
        MAKE_MESSAGE(APP_CONNECT_REQ); 
        /* connect to next device from the paired device list, setting the profile to try first */
        connection_mgr_clear_attempted_profiles();
        connection_mgr_set_profile_attempt(AGHFP_PROFILE_IS_ENABLED ? PROFILE_AGHFP : PROFILE_A2DP);
        connection_mgr_set_remote_device(&paired_device.addr);
        message->force_inquiry_mode = FALSE;
        MessageSend(&theSource->app_data.appTask, APP_CONNECT_REQ, message);
        
        return TRUE;
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_set_incoming_connection - Stores the remote device as the device to connect with
*/
void connection_mgr_set_incoming_connection(PROFILES_T profile, const bdaddr *addr)
{
    /* store the incoming connection as the device to connect with */
    connection_mgr_clear_attempted_profiles();
    connection_mgr_set_profile_attempt(profile);
    connection_mgr_set_remote_device(addr);    
    
    /* Cancel any outgoing connecting requests as the remote device is trying to connect.
        Further profiles will be connected by the dongle on confirmation of connection. */
    MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);
}


/****************************************************************************
NAME    
    connection_mgr_clear_attempted_profiles - Resets which profiles have been attempted
*/
void connection_mgr_clear_attempted_profiles(void)
{
    theSource->connection_data.remote_profiles_attempted = 0;
    
    CONNECTION_MGR_DEBUG(("CM: Clear attempted profiles\n"));
}


/****************************************************************************
NAME    
    connection_mgr_get_current_profile - Returns which profile is currently being used in a connection attempt
*/
PROFILES_T connection_mgr_get_current_profile(void)
{
    CONNECTION_MGR_DEBUG(("CM: Get current profile [%d]\n", theSource->connection_data.remote_profiles_attempted));
    
    /* get current active profile based on what has been attempted - AGHFP always tried before A2DP */
    if (theSource->connection_data.remote_profiles_attempted & PROFILE_A2DP)
        return PROFILE_A2DP;
    if (theSource->connection_data.remote_profiles_attempted & PROFILE_AGHFP)
        return PROFILE_AGHFP; 
    
    return PROFILE_NONE;
}


/****************************************************************************
NAME    
    connection_mgr_any_connected_profiles - Returns if any profiles are currently connected
*/
bool connection_mgr_any_connected_profiles(void)
{
    if (a2dp_get_number_connections() || aghfp_get_number_connections())
    {
        /* profiles connected */
        return TRUE;
    }
    
    /* no connections */
    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_connect_further_device - Attempts to connect to a further remote device
*/
bool connection_mgr_connect_further_device(bool manual_connect)
{
    bool initial_manual_connect = theSource->connection_data.manual_2nd_connection;
    
    /* store the manual connect flag passed in */
    theSource->connection_data.manual_2nd_connection = manual_connect;
    
    if (A2DP_DUALSTREAM_ENABLED)
    {        
        if (manual_connect || (!manual_connect && A2DP_DUALSTREAM_CONNECT_NEXT))
        {
            CONNECTION_MGR_DEBUG(("CM: connection_mgr_connect_further_device\n"));
        
            if (theSource->ps_config->features.connect_policy == PS_CONNECT_LAST_DEVICE)
            {
                /* get address from the last used PS Key */
                
                bdaddr connect_addr, addr_a, addr_b;
                
                BdaddrSetZero(&connect_addr);
                BdaddrSetZero(&addr_a);
                BdaddrSetZero(&addr_b);
                
                a2dp_get_connected_addr(&addr_a, &addr_b);
                
                if (BdaddrIsSame(&addr_a, &theSource->ps_config->bdaddr_stream2_device) &&
                    !BdaddrIsZero(&addr_a))
                {
                    /* the device stored in the second PS Key is connected, so connect the first PS Key device */
                    connect_addr = theSource->ps_config->bdaddr_remote_device;
                    CONNECTION_MGR_DEBUG(("    connect first PS Key device\n"));
                }
                else if (!BdaddrIsZero(&theSource->ps_config->bdaddr_stream2_device))
                {
                    /* the device stored in the first PS Key is connected, so connect the second PS Key device */
                    connect_addr = theSource->ps_config->bdaddr_stream2_device;
                    CONNECTION_MGR_DEBUG(("    connect second PS Key device\n"));
                }
                    
                /* Connect to second device if it has been found. Don't connect to it if connection has already been attempted. */
                if (A2DP_PROFILE_IS_ENABLED && 
                    !BdaddrIsZero(&connect_addr) && 
                    BdaddrIsZero(&addr_b) &&
                    (theSource->connection_data.device_number != CONNECTION_DEVICE_SECONDARY))
                {               
                    connection_mgr_start_connection_attempt(&connect_addr, PROFILE_A2DP, 0);
                    
                    theSource->connection_data.device_number = CONNECTION_DEVICE_SECONDARY;
                
                    return TRUE;
                }
            }
            else
            {
                /* get address from the paired device list */
                
                typed_bdaddr paired_addr;
                bool paired_found = FALSE;
                
                if (manual_connect && !initial_manual_connect)
                {
                    /* for user initiated connection attempts start at the beginning of the paired device list */
                    connection_mgr_restart_paired_device();
                }
            
                paired_found = connection_mgr_next_paired_device(&paired_addr);
            
                if (paired_found && a2dp_allow_more_connections())
                {                
                    CONNECTION_MGR_DEBUG(("    connect to paired\n"));
                    DEBUG_BDADDR(paired_addr.addr);
                
                    /* connect to secondary device from the paired device list */
                    connection_mgr_start_connection_attempt(&paired_addr.addr, PROFILE_A2DP, 0);
                
                    theSource->connection_data.device_number = CONNECTION_DEVICE_SECONDARY;
            
                    return TRUE;
                }
            }        
        }
    }

    /* reset manual connect flag as no longer connecting to a second device */
    theSource->connection_data.manual_2nd_connection = FALSE;
    
    /* reset to connect with primary device */
    theSource->connection_data.device_number = CONNECTION_DEVICE_PRIMARY;
    
    return FALSE;
}
        

/****************************************************************************
NAME    
    connection_mgr_set_remote_device - Store the device to connect with
*/
static void connection_mgr_set_remote_device(const bdaddr *addr)
{
    /* store the address of the device the source is connecting to */
    theSource->connection_data.remote_connection_addr = *addr;
    
    CONNECTION_MGR_DEBUG(("CM: Set remote connection addr: \n"));
    DEBUG_BDADDR(theSource->connection_data.remote_connection_addr);
}


/****************************************************************************
NAME    
    connection_mgr_clear_remote_device - Clears the device to connect with
*/
static void connection_mgr_clear_remote_device(void)
{
    /* clear the address of the device the source is connecting to */
    BdaddrSetZero(&theSource->connection_data.remote_connection_addr);    
    
    CONNECTION_MGR_DEBUG(("CM: Clear remote connection addr\n"));
}


/****************************************************************************
NAME    
    connection_mgr_set_profile_attempt - Keeps a record that the profile passed in has been attempted
*/
static void connection_mgr_set_profile_attempt(PROFILES_T profile)
{
    /* store that this active profile is being attempted */
    theSource->connection_data.remote_profiles_attempted |= profile;
    
    CONNECTION_MGR_DEBUG(("CM: Attempting profile [%d], profiles attempted [%d] \n", profile, theSource->connection_data.remote_profiles_attempted));
}


/****************************************************************************
NAME    
    connection_mgr_restart_paired_device - Resets the indexes back to the beginning of the paired device list
*/
static void connection_mgr_restart_paired_device(void)
{
    CONNECTION_MGR_DEBUG(("CM: Restart Paired Device List\n"));
    
    /* start at the most recently used device from the paired device list */
    theSource->connection_data.paired_device_start = 0;
    theSource->connection_data.paired_device_index = 0;
}


/****************************************************************************
NAME    
    connection_mgr_next_paired_device - Returns the address of the next device from the paired device list.
                                        Will return TRUE if an address is returned in addr.
                                        Will return FALSE if no address is returned.
*/
static bool connection_mgr_next_paired_device(typed_bdaddr *addr)
{
    typed_bdaddr paired_addr;
    uint8 psdata[1];
    const uint16 size_psdata = 0;
    
    CONNECTION_MGR_DEBUG(("CM: Next Paired Device\n"));
    
    if (theSource->ps_config->features.connect_policy == PS_CONNECT_LAST_DEVICE)
    {
        /* if the Source is only connect to the last device then not concerned about the paired list */
        
        CONNECTION_MGR_DEBUG(("   no next paired - connect to last device only\n"));
        
        return FALSE;
    }
    
    if (theSource->connection_data.paired_device_index >= theSource->ps_config->number_paired_devices)
    {
        /* reached the end of the paired device list, loop back to the beginning */
        theSource->connection_data.paired_device_index = 0;
        if (theSource->connection_data.paired_device_index == theSource->connection_data.paired_device_start)
        {
            /* reached the start again so return that no more paired devices to try */
            
            CONNECTION_MGR_DEBUG(("   no next paired - reached end of list\n"));
            
            return FALSE;
        }
    }
    
    if (ConnectionSmGetIndexedAttributeNowReq(PS_KEY_USER_PAIRED_NAME_BASE, theSource->connection_data.paired_device_index, size_psdata, psdata, &paired_addr))
    {
        CONNECTION_MGR_DEBUG(("   next paired - index %d\n", theSource->connection_data.paired_device_index));
        DEBUG_BDADDR(paired_addr.addr);
        
        /* return the address of the device found */
        *addr = paired_addr;
        
        /* increment the index to the paired devices */
        theSource->connection_data.paired_device_index++;
        
        return TRUE;
    }
    
    CONNECTION_MGR_DEBUG(("   no next paired - attribute not found\n"));
    
    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_set_profile_connected - Registers a profile connection with the connection manager
*/
void connection_mgr_set_profile_connected(PROFILES_T profile, const bdaddr *addr)
{
    switch (profile)
    {
        case PROFILE_A2DP:
        {
            /* see if the AGHFP profile is connected */
            aghfpInstance *aghfp_inst = aghfp_get_instance_from_bdaddr(*addr);
            
            if (aghfp_inst != NULL)
            {
                if (aghfp_is_connected(aghfp_inst->aghfp_state))
                {
                    break;
                }
            }
            
#ifdef INCLUDE_LEDS            
            /* this is the first profile connected for this device, show connected LED indication */
            leds_show_event(LED_EVENT_DEVICE_CONNECTED);
#endif            
        }
        break;
        
        case PROFILE_AGHFP:
        {
            /* see if the A2DP profile is connected */
            a2dpInstance *a2dp_inst = a2dp_get_instance_from_bdaddr(*addr);
            
            if (a2dp_inst != NULL)
            {
                if (a2dp_is_connected(a2dp_inst->a2dp_state))
                {
                    break;
                }
            }
#ifdef INCLUDE_LEDS            
            /* this is the first profile connected for this device, show connected LED indication */
            leds_show_event(LED_EVENT_DEVICE_CONNECTED);
#endif            
        }
        break;
        
        default:
        {
            
        }
        break;
    }
}


/****************************************************************************
NAME    
    connection_mgr_set_profile_disconnected - Registers a profile disconnection with the connection manager
*/
void connection_mgr_set_profile_disconnected(PROFILES_T profile, const bdaddr *addr)
{
    switch (profile)
    {
        case PROFILE_A2DP:
        {
            /* see if the AGHFP profile is connected */
            aghfpInstance *aghfp_inst = aghfp_get_instance_from_bdaddr(*addr);
            
            if (aghfp_inst != NULL)
            {
                if (aghfp_is_connected(aghfp_inst->aghfp_state))
                {
                    break;
                }
            }
#ifdef INCLUDE_LEDS            
            /* this is the final profile disconnected for this device, show disconnected LED indication */
            leds_show_event(LED_EVENT_DEVICE_DISCONNECTED);
#endif            
        }
        break;
        
        case PROFILE_AGHFP:
        {
            /* see if the A2DP profile is connected */
            a2dpInstance *a2dp_inst = a2dp_get_instance_from_bdaddr(*addr);
            
            if (a2dp_inst != NULL)
            {
                if (a2dp_is_connected(a2dp_inst->a2dp_state))
                {
                    break;
                }
            }
#ifdef INCLUDE_LEDS            
            /* this is the final profile disconnected for this device, show disconnected LED indication */
            leds_show_event(LED_EVENT_DEVICE_DISCONNECTED);
#endif            
        }
        break;
        
        default:
        {
            
        }
        break;
    }
}


/****************************************************************************
NAME    
    connection_mgr_reset_pin_codes - Resets the stored PIN codes to their default states.
*/
void connection_mgr_reset_pin_codes(void)
{
    uint16 index = 0;
    
    if (theSource->connection_data.connection_pin)
    {
        theSource->connection_data.connection_pin->device.number_device_pins = 0;
        for (index = 0; index < CONNECTION_MAX_DEVICE_PIN_CODES; index ++)
        {
            BdaddrSetZero(&theSource->connection_data.connection_pin->device.addr[index]);
            theSource->connection_data.connection_pin->device.index[index] = 0;
        }
    }
}



/****************************************************************************
NAME    
    connection_mgr_find_pin_index_by_addr - Find PIN index by the Bluetooth address supplied
*/
uint16 connection_mgr_find_pin_index_by_addr(const bdaddr *addr)
{
    uint16 index = 0;
    uint16 pins_stored = theSource->connection_data.connection_pin->device.number_device_pins;
    
    for (index = 0; index < pins_stored; index++)
    {
        if (BdaddrIsSame(&theSource->connection_data.connection_pin->device.addr[index], addr))
        {
            CONNECTION_MGR_DEBUG(("  found PIN index %d\n", index));
            return index;
        }
    }
    
    CONNECTION_MGR_DEBUG(("  no PIN index\n"));
    
    return INVALID_VALUE;
}


/****************************************************************************
NAME    
    connection_mgr_get_next_pin_code - Return if next PIN code was found for the device with the Bluetooth address supplied     
*/
bool connection_mgr_get_next_pin_code(const bdaddr *addr)
{
    /* may need to try next PIN code */
    uint16 index = connection_mgr_find_pin_index_by_addr(addr);
        
    if (index != INVALID_VALUE)
    {
        theSource->connection_data.connection_pin->device.index[index]++;
        if (theSource->connection_data.connection_pin->device.index[index] >= CONNECTION_MAX_DEVICE_PIN_CODES)
        {
            theSource->connection_data.connection_pin->device.index[index] = 0;                        
        }
        else
        {
            CONNECTION_MGR_DEBUG(("   next PIN code index %d\n", theSource->connection_data.connection_pin->device.index[index]));
            return TRUE;
        }
    }
    
    CONNECTION_MGR_DEBUG(("   no next PIN code\n"));
    
    return FALSE;
}


/****************************************************************************
NAME    
    connection_mgr_set_link_supervision_timeout - Sets the link supervision timeout for the link associated with the supplied Sink
*/
void connection_mgr_set_link_supervision_timeout(Sink sink)
{
    ConnectionSetLinkSupervisionTimeout(sink, CONNECTION_LINK_SUPERVISION_TIMEOUT);
}
