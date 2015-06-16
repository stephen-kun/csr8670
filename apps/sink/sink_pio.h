/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_pio.h
    
DESCRIPTION
    Part of the ledmanager Module responsible for managing the PIO outputs excluding LEDs
    
*/

#ifndef SINK_PIO_H
#define SINK_PIO_H

#include "sink_private.h"
#include <pio.h>
#include <pio_common.h>

/****************************************************************************
NAME	
	LEDManagerSetPowerOff

DESCRIPTION
    Set / Clear a power pin for the device
    
RETURNS
	void
*/
void PioSetPowerPin ( bool enable ) ;


/****************************************************************************
NAME	
	PioSetPio

DESCRIPTION
    Fn to change a PIO
    Set drive TRUE to drive PIO, FALSE to pull PIO
    Set dir TRUE to set high, FALSE to set low
    
RETURNS
	void
*/
void PioSetPio(uint16 pio , pio_common_dir drive, bool dir);


/****************************************************************************
NAME	
	PioGetPio

DESCRIPTION
    Fn to read a PIO
    
RETURNS
	TRUE if set, FALSE if not
*/
bool PioGetPio(uint16 pio);


#endif
