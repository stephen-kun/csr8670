/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_buttons.h
    
DESCRIPTION
    
*/
#ifndef SINK_BUTTONS_H
#define SINK_BUTTONS_H

#include "sink_buttonmanager.h"

#define VREG_PIN    (24)
#define CHG_PIN     (25)

    /*the mask values for the charger pins*/
#define VREG_PIN_MASK ((uint32)1 << VREG_PIN)
#define CHG_PIN_MASK ((uint32)1 << CHG_PIN)

    /*the mask values for the charger pin events*/
#define CHARGER_VREG_VALUE ( (uint32)((PsuGetVregEn()) ? VREG_PIN_MASK:0 ) )
#define CHARGER_CONNECT_VALUE ( (uint32)( (powerManagerIsChargerConnected())  ? CHG_PIN_MASK:0 ) )

#define DOUBLE_PRESS 2
#define TRIPLE_PRESS 3

/****************************************************************************
NAME 
 buttonManagerInit

DESCRIPTION
 Initialises the button event 

RETURNS
 void
    
*/
void ButtonsInit (  ButtonsTaskData *pButtonsTask ) ;


/****************************************************************************
DESCRIPTION
 	Called after the configuration has been read and will trigger buttons events
    if a pio has been pressed or held whilst the configuration was still being loaded
    , i.e. the power on button press    
*/
void ButtonsCheckForChangeAfterInit( void );

/****************************************************************************

DESCRIPTION
 	this function remaps the cap sense and pio bitmask into an input assignment
    pattern specified by pskey user 10, this allows buttons to be triggered from 
    pios of anywhere from 0 to 31 and cap sense 0 to 5

*/ 
uint32 ButtonsTranslate(uint16 CapSenseState, uint32 PioState);


/*
DESCRIPTION
 	this function remaps an input assignment into a cap sense or pio bitmask
    pattern specified by pskey user 10

*/ 
uint32 ButtonsTranslateInput(uint16 block, uint16 index, bool include_cap_sense);



#endif
