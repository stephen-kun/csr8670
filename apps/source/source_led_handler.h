/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_led_handler.h

DESCRIPTION
    Updates LED indications.
    The functionality is only included if INCLUDE_LEDS is defined.
*/


#ifdef INCLUDE_LEDS


#ifndef _SOURCE_LED_HANDLER_H_
#define _SOURCE_LED_HANDLER_H_


/* application header files */
#include "source_leds.h"
#include "source_states.h"


typedef enum
{
    LED_EVENT_DEVICE_CONNECTED,
    LED_EVENT_DEVICE_DISCONNECTED,
    LED_EVENT_LOW_BATTERY
} LED_EVENT_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    leds_show_state

DESCRIPTION
    Updates the LED pattern based on the current device state.
    
*/
void leds_show_state(SOURCE_STATE_T state);


/****************************************************************************
NAME    
    leds_show_event

DESCRIPTION
    Updates the LED pattern based on the current device event.
    
*/
void leds_show_event(LED_EVENT_T event);


#endif /* _SOURCE_LED_HANDLER_H_ */


#endif /* INCLUDE_LEDS */
