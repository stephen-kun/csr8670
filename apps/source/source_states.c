/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_states.c

DESCRIPTION
    Main application state machine.
    
*/


/* application header files */
#include "source_app_msg_handler.h"
#include "source_audio.h"
#include "source_connection_mgr.h"
#include "source_debug.h"
#include "source_init.h"
#include "source_inquiry.h"
#include "source_led_handler.h"
#include "source_memory.h"
#include "source_power.h"
#include "source_private.h"
#include "source_ps.h"
#include "source_scan.h"
#include "source_states.h"
#include "source_usb.h"

/* VM headers */
#include <charger.h>
#include <pio.h>


#ifdef DEBUG_STATES
    #define STATES_DEBUG(x) DEBUG(x)

    const char *const state_strings[SOURCE_STATES_MAX] = {  "Initialising",
                                                            "Powered Off",
                                                            "Test Mode",
                                                            "Idle",
                                                            "Connectable",
                                                            "Discoverable",
                                                            "Connecting",
                                                            "Inquiring",
                                                            "Connected"};
#else
    #define STATES_DEBUG(x)
#endif

/* check the device is powered on */    
#define states_is_powered_on(state) (state > SOURCE_STATE_TEST_MODE);
    
/* Debug output for unhandled state */
#define states_unhandled_state(inst) STATES_DEBUG(("STATES unhandled state[%d]", states_get_state()));
    
    
/* exit state functions */    
static void states_exit_state(SOURCE_STATE_T new_state);
static void states_exit_state_initialising(void);
static void states_exit_state_powered_off(void);
static void states_exit_state_test_mode(void);
static void states_exit_state_idle(void);
static void states_exit_state_connectable(void);
static void states_exit_state_discoverable(void);
static void states_exit_state_connecting(void);
static void states_exit_state_inquiring(void);
static void states_exit_state_connected(SOURCE_STATE_T new_state);
/* enter state functions */    
static void states_enter_state(SOURCE_STATE_T old_state);
static void states_enter_state_initialising(void);
static void states_enter_state_powered_off(void);
static void states_enter_state_test_mode(void);
static void states_enter_state_idle(SOURCE_STATE_T old_state);
static void states_enter_state_connectable(void);
static void states_enter_state_discoverable(void);
static void states_enter_state_connecting(void);
static void states_enter_state_inquiring(void);
static void states_enter_state_connected(SOURCE_STATE_T old_state);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    states_set_state - Sets the new application state
*/
void states_set_state(SOURCE_STATE_T new_state)
{
    if (new_state < SOURCE_STATES_MAX)
    {
        SOURCE_STATE_T old_state = theSource->app_data.app_state;
        
        /* leaving current state */
        states_exit_state(new_state);
        
        /* store new state */
        theSource->app_data.app_state = new_state;
        STATES_DEBUG(("STATE: new state [%s]\n", state_strings[new_state]));
        
        /* entered new state */
        states_enter_state(old_state);               
        
        /* fudge states reported to Host, so that IDLE state is converted to a known state */
        if (new_state == SOURCE_STATE_IDLE)
        {
            theSource->app_data.pre_idle_state = old_state;
            new_state = theSource->app_data.pre_idle_state;
        }    
        if (old_state == SOURCE_STATE_IDLE)
        {
            old_state = theSource->app_data.pre_idle_state;
        }
        if (old_state != new_state)
        {
            /* send new state via Vendor USB command */
            usb_send_vendor_state();

#ifdef INCLUDE_LEDS            
            /* update LED state indication */
            leds_show_state(new_state);
#endif /* INCLUDE_LEDS */              
        }
    }
}


/****************************************************************************
NAME    
    states_get_state - Gets the application state
*/
SOURCE_STATE_T states_get_state(void)
{
    return theSource->app_data.app_state;
}


/****************************************************************************
NAME    
    states_force_inquiry - Start Inquiry regardless of current activity
*/
void states_force_inquiry(void)
{
    switch (states_get_state())
    {
        case SOURCE_STATE_IDLE:      
        case SOURCE_STATE_CONNECTABLE:
        case SOURCE_STATE_DISCOVERABLE:
        case SOURCE_STATE_CONNECTING:
        case SOURCE_STATE_CONNECTED:
        {      
            /* cancel connecting timer */
            MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);  
            /* move to inquiry state */    
            states_set_state(SOURCE_STATE_INQUIRING);
            /* set appropriate timers as it is being forced to stay in inquiry state */
            states_no_timers();
            /* indicate this is a forced inquiry, and must remain in this state until a successful connection */
            theSource->inquiry_mode.force_inquiry_mode = TRUE;
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
    states_no_timers - Turns off timers that were set by the PS configuration 
*/
void states_no_timers(void)
{
    /* stop timers */
    theSource->ps_config->ps_timers.inquiry_state_timer = TIMER_NO_TIMEOUT;
    theSource->ps_config->ps_timers.inquiry_idle_timer = 0;
    theSource->ps_config->ps_timers.connection_idle_timer = 0;
    theSource->ps_config->ps_timers.disconnect_idle_timer = 0;
    
    /* note that timers have been stopped */
    theSource->timer_data.timers_stopped = TRUE;
}


/****************************************************************************
NAME    
    states_exit_state - Called when exiting an application state
*/
static void states_exit_state(SOURCE_STATE_T new_state)
{
    switch (states_get_state())
    {
        case SOURCE_STATE_INITIALISING:
        {
            states_exit_state_initialising();
        }
        break;
        
        case SOURCE_STATE_POWERED_OFF:
        {
            states_exit_state_powered_off();
        }
        break;
        
        case SOURCE_STATE_TEST_MODE:
        {
            states_exit_state_test_mode();
        }
        break;
        
        case SOURCE_STATE_IDLE:
        {
            states_exit_state_idle();
        }
        break;
        
        case SOURCE_STATE_CONNECTABLE:
        {
            states_exit_state_connectable();
        }
        break;
        
        case SOURCE_STATE_DISCOVERABLE:
        {
            states_exit_state_discoverable();
        }
        break;
        
        case SOURCE_STATE_CONNECTING:
        {
            states_exit_state_connecting();
        }
        break;
        
        case SOURCE_STATE_INQUIRING:
        {
            states_exit_state_inquiring();
        }
        break;
        
        case SOURCE_STATE_CONNECTED:
        {
            states_exit_state_connected(new_state);
        }
        break;
              
        default:
        {
            states_unhandled_state();
        }
        break;
    }
}


/****************************************************************************
NAME    
    states_exit_state_initialising - Called when exiting the SOURCE_STATE_INITIALISING state
*/
static void states_exit_state_initialising(void)
{
    
}


/****************************************************************************
NAME    
    states_exit_state_powered_off - Called when exiting the SOURCE_STATE_POWERED_OFF state
*/
static void states_exit_state_powered_off(void)
{
    
}


/****************************************************************************
NAME    
    states_exit_state_test_mode - Called when exiting the SOURCE_STATE_TEST_MODE state
*/
static void states_exit_state_test_mode(void)
{
    
}


/****************************************************************************
NAME    
    states_exit_state_idle - Called when exiting the SOURCE_STATE_IDLE state
*/
static void states_exit_state_idle(void)
{
    
}


/****************************************************************************
NAME    
    states_exit_state_connectable - Called when exiting the SOURCE_STATE_CONNECTABLE state
*/
static void states_exit_state_connectable(void)
{
    scan_set_unconnectable();
}


/****************************************************************************
NAME    
    states_exit_state_discoverable - Called when exiting the SOURCE_STATE_DISCOVERABLE state
*/
static void states_exit_state_discoverable(void)
{
    scan_set_unconnectable();
    MessageCancelAll(&theSource->app_data.appTask, APP_INQUIRY_IDLE_TIMEOUT);
}


/****************************************************************************
NAME    
    states_exit_state_connecting - Called when exiting the SOURCE_STATE_CONNECTING state
*/
static void states_exit_state_connecting(void)
{
}


/****************************************************************************
NAME    
    states_exit_state_inquiring - Called when exiting the SOURCE_STATE_INQUIRING state
*/
static void states_exit_state_inquiring(void)
{
    /* cancel any active inquries */
    ConnectionInquireCancel(&theSource->connectionTask);
}


/****************************************************************************
NAME    
    states_exit_state_connected - Called when exiting the SOURCE_STATE_CONNECTED state
*/
static void states_exit_state_connected(SOURCE_STATE_T new_state)
{
    if (new_state != SOURCE_STATE_CONNECTING) /* if going from connected to connecting, might be connecting further devices so don't disconnect */
    {
        /* Remove all connections as it has left the connected state */
        MessageSend(&theSource->app_data.appTask, APP_DISCONNECT_REQ, 0);
    }
    /* Clear the manufacturer ID */
    theSource->connection_data.remote_manufacturer = 0;
}


/****************************************************************************
NAME    
    states_enter_state - Called when entering an application state
*/
static void states_enter_state(SOURCE_STATE_T old_state)
{
    switch (states_get_state())
    {
        case SOURCE_STATE_INITIALISING:
        {
            states_enter_state_initialising();
        }
        break;
        
        case SOURCE_STATE_POWERED_OFF:
        {
            states_enter_state_powered_off();
        }
        break;
        
        case SOURCE_STATE_TEST_MODE:
        {
            states_enter_state_test_mode();
        }
        break;
        
        case SOURCE_STATE_IDLE:
        {
            states_enter_state_idle(old_state);
        }
        break;
        
        case SOURCE_STATE_CONNECTABLE:
        {
            states_enter_state_connectable();
        }
        break;
        
        case SOURCE_STATE_DISCOVERABLE:
        {
            states_enter_state_discoverable();
        }
        break;
        
        case SOURCE_STATE_CONNECTING:
        {
            states_enter_state_connecting();
        }
        break;
        
        case SOURCE_STATE_INQUIRING:
        {
            states_enter_state_inquiring();
        }
        break;
        
        case SOURCE_STATE_CONNECTED:
        {
            states_enter_state_connected(old_state);
        }
        break;
              
        default:
        {
            states_unhandled_state();
        }
        break;
    }
}


/****************************************************************************
NAME    
    states_enter_state_initialising - Called when entering the SOURCE_STATE_INITIALISING application state
*/
static void states_enter_state_initialising(void)
{
    /* apply power to device */
    app_power_device(TRUE);
    /* get configuration from PSKEYs */
    ps_get_configuration();    
    /* initialise audio block */
    audio_init();
    /* initialise inquiry */
    inquiry_init();
    
#ifdef INCLUDE_BUTTONS    
    /* initialise buttons */
    buttons_init();
#endif /* INCLUDE_BUTTONS */
    
#ifdef INCLUDE_POWER_READINGS
    /* initialise power readings */
    power_init();
#endif /* INCLUDE_POWER_READINGS */
    
    /* start registration of libraries */
    init_register_profiles(REGISTERED_PROFILE_NONE);  
}


/****************************************************************************
NAME    
    states_enter_state_powered_off - Called when entering the SOURCE_STATE_POWERED_OFF application state
*/
static void states_enter_state_powered_off(void)
{    
    /* restore any stopped timers on power off */
    ps_restore_timers();
    
    /* cancel any queued messages */
    MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);
    MessageCancelAll(&theSource->app_data.appTask, APP_LINKLOSS_IND);
    MessageCancelAll(&theSource->app_data.appTask, APP_AUDIO_START);
    MessageCancelAll(&theSource->app_data.appTask, APP_USB_AUDIO_ACTIVE);
    
    /* Physically power off the device after a delay */
    MessageSendLater(&theSource->app_data.appTask, APP_POWER_OFF_DEVICE, 0, POWER_OFF_DELAY);
}


/****************************************************************************
NAME    
    states_enter_state_test_mode - Called when entering the SOURCE_STATE_TEST_MODE application state
*/
static void states_enter_state_test_mode(void)
{
    /* enter DUT mode */
    ConnectionEnterDutMode();
}


/****************************************************************************
NAME    
    states_enter_state_idle - Called when entering the SOURCE_STATE_IDLE application state
*/
static void states_enter_state_idle(SOURCE_STATE_T old_state)
{
    uint16 delay = 0; /* default is to have no delay before next connection attempt */

    switch (old_state)
    {
        case SOURCE_STATE_CONNECTING:
        {
            if (theSource->ps_config->features.connection_max_retries != INVALID_VALUE)
            {
                /* feature enabled to only try to a remote device a set number of times before giving up */
                if ((theSource->connection_data.connection_retries < theSource->ps_config->features.connection_max_retries) ||
                    theSource->timer_data.timers_stopped)
                {
                    /* if it was connnecting use the connection_idle_timer delay before next connection attempt */
                    delay = theSource->ps_config->ps_timers.connection_idle_timer;
                    STATES_DEBUG(("STATE: was connecting, connection attempts:[%d], can continue after delay:[%d secs]\n", theSource->connection_data.connection_retries, delay));
                    
                    if (!theSource->timer_data.timers_stopped)
                    {
                        /* increase number of connections attempted if timers haven't been bypassed */
                        theSource->connection_data.connection_retries++;
                    }
                }
                else
                {
                    /* configured number of connection attempts have been tried - give up connecting! */
                    delay = TIMER_NO_TIMEOUT;
                    theSource->connection_data.connection_retries = 0;
                    STATES_DEBUG(("STATE: was connecting, given up trying to connect\n"));
                }
            }
            else
            {
                /* if it was connnecting use the connection_idle_timer delay before next connection attempt */
                delay = theSource->ps_config->ps_timers.connection_idle_timer;
                STATES_DEBUG(("STATE: was connecting, next connect delay:[%d secs]\n", delay));
            }
        }
        break;
        
        case SOURCE_STATE_CONNECTED:
        {
            /* if it was connnected use the disconnect_idle_timer delay before next connection attempt */
            delay = theSource->ps_config->ps_timers.disconnect_idle_timer;
            STATES_DEBUG(("STATE: was connected, delay:[%d secs]\n", delay));
        }
        break;
        
        case SOURCE_STATE_INITIALISING:
        case SOURCE_STATE_POWERED_OFF:
        {
            if (BdaddrIsZero(&theSource->ps_config->bdaddr_remote_device))
            {
                /* if the device was powered off and no previous connection exists:
                    use the power_on_discover_idle_timer before first discovery attempt */
                delay = theSource->ps_config->ps_timers.power_on_discover_idle_timer;
            }
            else
            {
                /* if the device was powered off and a previous connection exists:
                    use the power_on_connect_idle_timer before first connection attempt */
                delay = theSource->ps_config->ps_timers.power_on_connect_idle_timer;
            }
        }
        break;
        
        default:
        {
            
        }
        break;            
    }
    
    if (old_state != SOURCE_STATE_CONNECTING)
    {
        /* reset connection attempts if not currently connecting */
        theSource->connection_data.connection_retries = 0;
    }
    
    if (delay != 0)
    {
        /* enter connectable or discoverable state if a delay has been configured */
        if (BdaddrIsZero(&theSource->ps_config->bdaddr_remote_device) || theSource->inquiry_mode.force_inquiry_mode)
        {
            /* no device to connect to, go discoverable */
            MessageSend(&theSource->app_data.appTask, APP_ENTER_PAIRING_STATE_FROM_IDLE, 0);
        }
        else
        {
            /* there is a device to connect to, go connectable */
            MessageSend(&theSource->app_data.appTask, APP_ENTER_CONNECTABLE_STATE_FROM_IDLE, 0);
        }
    }

    if (delay != TIMER_NO_TIMEOUT)
    {
        STATES_DEBUG(("STATE: IDLE delay before next connection:[%d secs]\n", delay));      
        /* initialise the connection with the connection manager */
        connection_mgr_start_connection_attempt(NULL, AGHFP_PROFILE_IS_ENABLED ? PROFILE_AGHFP : PROFILE_A2DP, delay);        
    }
    else
    {
        STATES_DEBUG(("STATE: No auto reconnection\n"));
    }
}


/****************************************************************************
NAME    
    states_enter_state_connectable - Called when entering the SOURCE_STATE_CONNECTABLE application state
*/
static void states_enter_state_connectable(void)
{
    scan_set_connectable_only();
}


/****************************************************************************
NAME    
    states_enter_state_discoverable - Called when entering the SOURCE_STATE_DISCOVERABLE application state
*/
static void states_enter_state_discoverable(void)
{
    scan_set_connectable_discoverable();
}


/****************************************************************************
NAME    
    states_enter_state_connecting - Called when entering the SOURCE_STATE_CONNECTING application state
*/
static void states_enter_state_connecting(void)
{
    if (connection_mgr_get_current_profile() == PROFILE_AGHFP)
    {
        aghfp_start_connection();
    }
    else if (connection_mgr_get_current_profile() == PROFILE_A2DP)
    {
        a2dp_start_connection();
    }
    else
    {
        Panic(); /* Panic if A2DP and HFP profiles disabled */
    }
}


/****************************************************************************
NAME    
    states_enter_state_inquiring - Called when entering the SOURCE_STATE_INQUIRING application state
*/
static void states_enter_state_inquiring(void)
{
    if (inquiry_has_results())
    {
        /* continue inquiry from previously found results */
        MessageSend(&theSource->app_data.appTask, APP_INQUIRY_CONTINUE, 0);
    }
    else
    {
        /* restart inquiry process */
        inquiry_start_discovery();
    }
}


/****************************************************************************
NAME    
    states_enter_state_connected - Called when entering the SOURCE_STATE_CONNECTED application state
*/
static void states_enter_state_connected(SOURCE_STATE_T old_state)
{
    /* finish any ongoing inquiry */
    inquiry_complete();
    
    /* restore timers if they have been altered */
    if (usb_get_hid_mode() == USB_HID_MODE_HOST)
    {
        ps_restore_timers();
    }
    
    if ((old_state == SOURCE_STATE_CONNECTING) && 
        !theSource->audio_data.audio_aghfp_connection_delay &&
        !theSource->audio_data.audio_a2dp_connection_delay)
    {
        /* start any audio immediately as this side initiated connection */
        MessageSend(&theSource->app_data.appTask, APP_AUDIO_START, 0);
    }
    else
    {
        /* start any audio after the configured delay as this side didn't initiate connection */
        MessageSendLater(&theSource->app_data.appTask, APP_AUDIO_START, 0, theSource->ps_config->ps_timers.audio_delay_timer);
    }
}

