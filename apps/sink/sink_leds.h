/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    device_leds.h
    
DESCRIPTION
    Module responsible for managing the PIO outputs including LEDs
    
*/

#ifndef SINK_LEDS_H
#define SINK_LEDS_H

#include "sink_leddata.h"
#include "sink_states.h"

#define DIM_MSG_BASE (0x1000)

/****************************************************************************
NAME	
	PioSetLedPin

DESCRIPTION
    Fn to change an LED attached to a PIO, a special LED pin , or a tricolour LED
    
RETURNS
	void
*/
void PioSetLedPin ( uint16 pPIO , bool pOnOrOff ) ;

/****************************************************************************
NAME	
	PioSetDimState  
	
DESCRIPTION
    Update funtion for a led that is currently dimming
    
RETURNS
	void
*/
void PioSetDimState ( uint16 pPIO );



/****************************************************************************
NAME 
    LedsInit

DESCRIPTION
 	Initialise the Leds data
RETURNS
    void
    
*/
void LedsInit ( void ) ;


/****************************************************************************
NAME 
    ledsIndicateLedsPattern

DESCRIPTION
 	Given the indication type and leds pattern, Play the LED Pattern
RETURNS
    void
*/
void ledsIndicateLedsPattern(LEDPattern_t *lPattern, uint8 lIndex, IndicationType_t Ind_type);
        

/****************************************************************************
NAME 
    LedsIndicateNoState

DESCRIPTION
    used to cancel any outstanding state indications

RETURNS
    void
    
*/
void LedsIndicateNoState ( void ) ;

/****************************************************************************
NAME 
 LedActiveFiltersCanOverideDisable

DESCRIPTION
    Check if active filters disable the global LED disable flag.
RETURNS
 	bool
*/
bool LedActiveFiltersCanOverideDisable( void ) ;

/****************************************************************************
NAME 
    LedsCheckForFilter

DESCRIPTION
    checks and sets a filter if one is defined for the given event
    
RETURNS
    void    
*/
void LedsCheckForFilter ( sinkEvents_t pEvent ) ;

/****************************************************************************
NAME 
    LedsEnableFilterOverrides

DESCRIPTION
    Enable or disable filters overriding LEDs. This will not change which 
    filters are active, it will just turn off any LEDs the filters are 
    forcing on.
    
RETURNS
    void    
*/
void LedsEnableFilterOverrides(bool enable);

/****************************************************************************
NAME 
    LedsSetLedActivity

DESCRIPTION
    Sets a Led Activity to a known state
RETURNS
    void
*/
void LedsSetLedActivity ( LEDActivity_t * pLed , IndicationType_t pType , uint16 pIndex , uint16 pDimTime) ;

/****************************************************************************
NAME 
    LedsResetAllLeds

DESCRIPTION
    resets all led pins to off and cancels all led and state indications
RETURNS
    void
*/
void LedsResetAllLeds ( void ) ;

/****************************************************************************
NAME 
 isOverideFilterActive

DESCRIPTION
    determine if an overide filter is currently active and driving one of the
    leds in which case return TRUE to prevent it being turned off to display 
    another pattern, allows solid red with flashing blue with no interuption in
    red for example.
RETURNS
    true or false
*/
bool isOverideFilterActive ( uint8 Led );

/****************************************************************************
NAME 
    LedsIndicateError

DESCRIPTION
    Indicates a fatal application error by flashing each LED in turn the 
    number of times of the specified error id.
    This function never returns.
RETURNS
    void
*/
void LedsIndicateError ( const uint16 errId ) ;

#endif

