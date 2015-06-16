/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_config.h
    
DESCRIPTION
    
*/

#ifndef _SINK_CONFIG_H_
#define _SINK_CONFIG_H_


#include "sink_configmanager.h"
#include "sink_powermanager.h"
#include "sink_states.h"
#include "sink_volume.h"
#include "sink_buttonmanager.h"
#include "sink_private.h"
#include <fm_rx_plugin.h>



/****************************************************************************
NAME 
 	ConfigRetrieve

DESCRIPTION
 	This function is called to read a configuration key.  If the key exists
 	in persistent store it is read from there.  If it does not exist then
 	the default is read from constant space
 
RETURNS
 	0 if no data was read otherwise the length of data
*/
uint16 ConfigRetrieve(uint16 config_id, void* data, uint16 len);

/****************************************************************************
NAME 
 	ConfigStore

DESCRIPTION
 	This function is called to store a configuration key.  This will always
    be in PS Store
 
RETURNS
 	0 if no data was stored otherwise the length of data
*/
uint16 ConfigStore(uint16 config_id, const void* data, uint16 len);


/****************************************************************************
NAME 
 	get_service_record

DESCRIPTION
 	This function is called to get a special service record associated with a 
 	given configuration
 
RETURNS
 	a pointer to the service record
*/
uint8 * get_service_record ( void ) ;

/****************************************************************************
NAME 
 	get_service_record_length

DESCRIPTION
 	This function is called to get the length of a special service record 
 	associated with a given configuration
 
RETURNS
 	the length of the service record
*/
uint16 get_service_record_length ( void ) ;


#endif /* _SINK_CONFIG_H_ */
