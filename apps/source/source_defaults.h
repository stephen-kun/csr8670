/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_defaults.h

DESCRIPTION
    Handles User PSKey default values.
    
*/


#ifndef _SOURCE_DEFAULTS_H_
#define _SOURCE_DEFAULTS_H_


/* VM headers */
#include <csrtypes.h>


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    defaults_get_value

DESCRIPTION
    Returns the default value for a User PSKey. 
        ps_key - specifies the User PSKey to read
        ps_data - the buffer to hold the returned default data
        ps_size - the size of the ps_data buffer passed in
    
RETURNS
    The size of data contained in ps_data

*/
uint16 defaults_get_value(uint16 ps_key, void *ps_data, uint16 ps_size);


#endif /* _SOURCE_DEFAULTS_H_ */
