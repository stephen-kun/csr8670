/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    power_monitor.h

DESCRIPTION
    This file contains the ADC monitoring functionality

NOTES

*/

#define POWER_INIT_COMPLETE   (power_init_vref | power_init_vbat | power_init_vthm | power_init_vchg)

#define POWER_INIT_GET(x)        (power && (power->init_mask & (x)))
#define POWER_INIT_SET(x)        (power->init_mask |= (x))
#define POWER_INIT_IS_COMPLETE() (power && (power->init_mask == POWER_INIT_COMPLETE))


/****************************************************************************
NAME
    PowerInitComplete
    
DESCRIPTION
    Power library initialisation completed
*/
void PowerInitComplete(Task clientTask, bool success);
