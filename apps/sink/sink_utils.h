/*******************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_uitils.h

DESCRIPTION
    Contains utility functions used by the sink application
*/

#ifndef _SINK_UTILS_H_
#define _SINK_UTILS_H_

#include <csrtypes.h>


/*******************************************************************************
NAME
    bitCounter16

DESCRIPTION
    Function to count the number of set bits in a uint16 bitmask
*/
uint16 bitCounter16(uint16 to_count);


/*******************************************************************************
NAME    
    bitCounter32
    
DESCRIPTION
    Function to count the number of set bits in a 32bit mask
*/
uint16 bitCounter32(uint32 to_count);


#endif /* _SINK_UTILS_H_ */
