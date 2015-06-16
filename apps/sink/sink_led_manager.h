/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_led_manager.h
    
DESCRIPTION
    
*/
#ifndef SINK_LED_MANAGER_H
#define SINK_LED_MANAGER_H


#include "sink_private.h"
#include "sink_states.h"
#include "sink_events.h"

#define LedManagerQueuedEvent() (theSink.theLEDTask->Queue[0])

    void LedManagerMemoryInit(void);
    void LEDManagerInit ( void ) ;

	void LEDManagerIndicateEvent ( MessageId pEvent ) ;

    void LedManagerIndicateQueuedEvent(void);
    
	void LEDManagerIndicateState ( sinkState pState )  ;


	void LedManagerDisableLEDS ( void ) ;
	void LedManagerEnableLEDS  ( void ) ;

	void LedManagerToggleLEDS  ( void )  ;

	void LedManagerResetLEDIndications ( void ) ;

	void LEDManagerResetStateIndNumRepeatsComplete  ( void ) ;


	void LEDManagerCheckTimeoutState( void );

	void LedManagerForceDisable( bool disable );
        
	#ifdef DEBUG_LM
		void LMPrintPattern ( LEDPattern_t * pLED ) ;
	#endif
		
#endif

