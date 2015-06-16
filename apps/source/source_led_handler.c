/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_led_handler.c

DESCRIPTION
    Updates LED indications.
    The functionality is only included if INCLUDE_LEDS is defined.
*/


#ifdef INCLUDE_LEDS

/* header for this file */
#include "source_led_handler.h"
/* application header files */
#include "source_debug.h"
#include "source_private.h"
#include "source_states.h"
/* profile/library headers */

/* VM headers */



#ifdef DEBUG_LEDS
    #define LEDS_DEBUG(x) DEBUG(x)
#else
    #define LEDS_DEBUG(x)
#endif


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    leds_show_state - Updates the LED pattern based on the current device state  
*/
void leds_show_state(SOURCE_STATE_T state)
{
    switch(state)
    {      
        case SOURCE_STATE_INITIALISING:
        case SOURCE_STATE_POWERED_OFF:
        {
            ledsPlay(LED_OFF_STATE);
        }
        break;
        
        case SOURCE_STATE_TEST_MODE:
        {
            ledsPlay(LED_TEST_MODE_STATE);
        }
        break;
        
        case SOURCE_STATE_CONNECTABLE:
        {
            ledsPlay(LED_CONNECTABLE_STATE);
        }
        break;
        
        case SOURCE_STATE_DISCOVERABLE:
        {
            ledsPlay(LED_DISCOVERABLE_STATE);
        }
        break;
        
        case SOURCE_STATE_INQUIRING:
        {
            ledsPlay(LED_INQUIRING_STATE);
        }
        break;
        
        case SOURCE_STATE_CONNECTING:
        {
            ledsPlay(LED_CONNECTING_STATE);
        }
        break;
        
        case SOURCE_STATE_CONNECTED:
        {            
            ledsPlay(LED_CONNECTED_STATE);
        }
        break;
        
        case SOURCE_STATE_IDLE:
        default:
        {
            /* do nothing */
        }
        break;
    }
        
}


/****************************************************************************
NAME    
    leds_show_event - Updates the LED pattern based on the current device event  
*/
void leds_show_event(LED_EVENT_T event)
{
    switch(event)
    {      
        case LED_EVENT_DEVICE_CONNECTED:
        {
            ledsPlay(LED_CONNECTION);
        }
        break;
        
        case LED_EVENT_DEVICE_DISCONNECTED:
        {
            ledsPlay(LED_DISCONNECTION);
        }
        break;
        
        case LED_EVENT_LOW_BATTERY:
        {
            ledsPlay(LED_LOW_BATTERY);
        }
        break;
        
        default:
        {
            /* do nothing */
        }
        break;
    }
}


#else
    static const int leds_disabled;
#endif /* INCLUDE_LEDS */

