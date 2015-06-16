/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_button_handler.c

DESCRIPTION
    Handles button events.
    The functionality is only included if INCLUDE_BUTTONS is defined.
    
*/


#ifdef INCLUDE_BUTTONS

/* header for this file */
#include "source_button_handler.h"
/* application header files */
#include "source_app_msg_handler.h"
#include "source_debug.h"
#include "source_private.h"
#include "source_states.h"
/* profile/library headers */

/* VM headers */
#include <psu.h>


#ifdef DEBUG_BUTTONS
    #define BUTTONS_DEBUG(x) DEBUG(x)
#else
    #define BUTTONS_DEBUG(x)
#endif


/****************************************************************************
NAME    
    button_enter_inquiry - Enters Inquiry mode from button event
*/ 
static void button_enter_inquiry(void)
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


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    button_msg_handler - Message handler for button events
*/  
void button_msg_handler(Task task, MessageId id, Message message)
{
    switch (id)
    {
        case BUTTON_MSG_ENTER_PAIRING_MODE:
        {
            BUTTONS_DEBUG(("BUTTON_MSG_ENTER_PAIRING_MODE\n"));
                        
            /* flag to indicate long press, so short press events aren't sent */
            theSource->button_data.button_long_press = TRUE;
            /* start inquiry */
            button_enter_inquiry();
        }
        break;
        
        case BUTTON_MSG_RESET_PAIRED_DEVICE_LIST:
        {
            BUTTONS_DEBUG(("BUTTON_MSG_RESET_PAIRED_DEVICE_LIST\n"));
            
            /* flag to indicate long press, so short press events aren't sent */
            theSource->button_data.button_long_press = TRUE;
            /* Delete paired devices and associated attributes */
            ConnectionSmDeleteAllAuthDevices(PS_KEY_USER_PAIRED_ATTR_BASE);
            ConnectionSmDeleteAllAuthDevices(PS_KEY_USER_PAIRED_NAME_BASE);
            /* start inquiry */
            button_enter_inquiry();
        }
        break;
        
        case BUTTON_MSG_CONNECT:
        {
            if (!theSource->button_data.button_long_press)
            {
                BUTTONS_DEBUG(("BUTTON_MSG_CONNECT\n"));
                
                /* a long press of the button hasn't been activated, okay to send short release event */
                switch (states_get_state())
                {
                    case SOURCE_STATE_IDLE:
                    case SOURCE_STATE_CONNECTABLE:
                    case SOURCE_STATE_DISCOVERABLE:
                    case SOURCE_STATE_INQUIRING:
                    {
                        /* no longer in forced inquiry mode */    
                        theSource->inquiry_mode.force_inquiry_mode = FALSE;
                        /* reset connection attempts */
                        theSource->connection_data.connection_retries = 0;
                        /* initialise the connection with the connection manager */
                        connection_mgr_start_connection_attempt(NULL, AGHFP_PROFILE_IS_ENABLED ? PROFILE_AGHFP : PROFILE_A2DP, 0);
                    }
                    break;
                
                    case SOURCE_STATE_CONNECTED:
                    {
                        /* see if a further device can be connected */
                        if (connection_mgr_connect_further_device(TRUE))
                        {
                            /* connection will be attempted */
                        }
                    }
                    break;
                
                    default:
                    {
                    }
                    break;
                }
            }
            theSource->button_data.button_long_press = FALSE;
        }
        break;
        
        case BUTTON_MSG_ON_OFF_HELD:
        {
#ifdef ANALOGUE_INPUT_DEVICE            
            BUTTONS_DEBUG(("BUTTON_MSG_ON_OFF_HELD\n"));
            switch (states_get_state())
            {
                case SOURCE_STATE_IDLE:
                case SOURCE_STATE_CONNECTABLE:
                case SOURCE_STATE_DISCOVERABLE:
                case SOURCE_STATE_INQUIRING:
                case SOURCE_STATE_CONNECTING:
                case SOURCE_STATE_CONNECTED:
                {
                    if (theSource->button_data.power_button_released)
                    {
                        states_set_state(SOURCE_STATE_POWERED_OFF);
                    }
                    else
                    {
                        BUTTONS_DEBUG(("  Power off ignored\n"));
                    }
                }
                break;
                
                case SOURCE_STATE_POWERED_OFF:
                {
                    if (connection_mgr_any_connected_profiles())
                    {                        
                        /* if still devices connected wait for them to disconnect - power on anyway after a delay incase a connection gets stuck */
                        MessageSendConditionally(&theSource->app_data.appTask, APP_POWER_ON_DEVICE, 0, &theSource->connection_data.profile_connected); 
                        MessageSendLater(&theSource->app_data.appTask, APP_POWER_ON_DEVICE, 0, 1000); 
                    }
                    else
                    {
                        /* power on immediately if no devices connected */
                        MessageSend(&theSource->app_data.appTask, APP_POWER_ON_DEVICE, 0);
                    }
                }
                break;
                
                default:
                {
                }
                break;
            }
#endif /* ANALOGUE_INPUT_DEVICE */            
        }
        break;
        
        case BUTTON_MSG_ON_OFF_RELEASE:
        {
#ifdef ANALOGUE_INPUT_DEVICE            
            BUTTONS_DEBUG(("BUTTON_MSG_ON_OFF_RELEASE\n"));
            /* stop device powering off straight after a power on */
            theSource->button_data.power_button_released = TRUE;
#endif /* ANALOGUE_INPUT_DEVICE */            
        }
        break;
        
        case CHARGER_CONNECTED:
        {
            BUTTONS_DEBUG(("CHARGER_CONNECTED\n"));
            
#ifdef INCLUDE_POWER_READINGS            
            PowerChargerMonitor();
#endif            
        }
        break;
        
        case CHARGER_DISCONNECTED:
        {
            BUTTONS_DEBUG(("CHARGER_DISCONNECTED\n"));
            
#ifdef INCLUDE_POWER_READINGS            
            PowerChargerMonitor();
#endif
            
            switch (states_get_state())
            {
                case SOURCE_STATE_POWERED_OFF:
                {
                    MessageSend(&theSource->app_data.appTask, APP_POWER_OFF_DEVICE, 0);
                }
                break;
                
                default:
                {
                }
                break;
            }
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
    buttons_init - Initialises the button handling
*/ 
void buttons_init(void)
{
    theSource->button_data.buttonTask.handler = button_msg_handler;
    
    pioInit(&theSource->button_data.pio_state, &theSource->button_data.buttonTask);
    
    if (!PsuGetVregEn())
    {
        /* if VREG (used as power button) is not high initially then note that the power button is not held down */
        theSource->button_data.power_button_released = TRUE;
    }
}


#else
    static const int buttons_disabled;
#endif /* #INCLUDE_BUTTONS */

