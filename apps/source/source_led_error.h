/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2014

PROJECT
    source

FILE NAME
    source_led_error.h

DESCRIPTION
    Indicates Configuration Set and PS store Errors using the system LEDs

*/


#ifndef _SOURCE_LED_ERROR_H_
#define _SOURCE_LED_ERROR_H_


#include <stdlib.h>
#include <stdio.h>


#define CfgErrFalse(e,ErrId) do { if (!(e)) LedsIndicateError(ErrId); } while(0)

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

#endif /* _SOURCE_LED_ERROR_H_ */
