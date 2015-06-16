/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_pio.c
    
DESCRIPTION


*/

#include "sink_pio.h"

#include "sink_private.h"
#include "sink_configmanager.h"

#include <pio.h>
#include <psu.h>

#ifdef DEBUG_PIO
#define PIO_DEBUG(x)  DEBUG (x)
#else
#define PIO_DEBUG(x) 
#endif


/****************************************************************************
NAME	
	PioSetPio

DESCRIPTION
    Fn to change a PIO
    Set drive pio_drive to drive PIO, pio_pull to pull PIO
    Set dir TRUE to set high, FALSE to set low
    
RETURNS
	void
*/
void PioSetPio(uint16 pio , pio_common_dir drive, bool dir) 
{
    PIO_DEBUG(("PIO: %s pin %d %s\n", (drive ? "Drive" : "Pull"), pio, (dir ? "high" : "low")));
    PioCommonSetPin(pio, drive, dir);
}


/****************************************************************************
NAME	
	PioGetPio

DESCRIPTION
    Fn to read a PIO
    
RETURNS
	TRUE if set, FALSE if not
*/
bool PioGetPio(uint16 pio)
{
    PIO_DEBUG(("PIO: Read pin %d\n", pio));
    return PioCommonGetPin(pio);
}


/****************************************************************************
NAME	
	PioSetPowerPin

DESCRIPTION
    controls the internal regulators to latch / remove the power on state
    
RETURNS
	void
*/
void PioSetPowerPin ( bool enable ) 
{
    /* power on or off the smps */
#ifdef BC5_MULTIMEDIA
    PsuConfigure(PSU_SMPS0, PSU_ENABLE, enable);
#else
    /* when shutting down ensure all psus are off for BC7 chips */
    if(!enable)
        PsuConfigure(PSU_ALL, PSU_ENABLE, enable);
#endif
    PIO_DEBUG(("PIO : PowerOnSMPS %X\n", enable)) ;      
}
