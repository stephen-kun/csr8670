/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_power.h

DESCRIPTION
    Handles power readings when running as a self powered device.    

*/


#ifndef _SOURCE_POWER_H_
#define _SOURCE_POWER_H_


/* VM headers */
#include <csrtypes.h>


/***************************************************************************
Function definitions
****************************************************************************
*/

#ifdef INCLUDE_POWER_READINGS

/****************************************************************************
NAME    
    power_init

DESCRIPTION
    Initialises the power manager.
 
*/
void power_init(void);


#endif /* INCLUDE_POWER_READINGS */


/****************************************************************************
NAME    
    power_is_charger_connected
    
DESCRIPTION
    Called to see if the charger is connected
    
*/
bool power_is_charger_connected(void);


#endif /* _SOURCE_POWER_H_ */


