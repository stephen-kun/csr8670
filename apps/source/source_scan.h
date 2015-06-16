/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_scan.h

DESCRIPTION
    Sets scan modes - connectability / discoverability    

*/


#ifndef _SOURCE_SCAN_H_
#define _SOURCE_SCAN_H_


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    scan_set_unconnectable

DESCRIPTION
    Turns off scanning so the device is not connectable or discoverable.
 
*/
void scan_set_unconnectable(void);


/****************************************************************************
NAME    
    scan_set_connectable_only

DESCRIPTION
    Sets scanning so the device is connectable only.
 
*/
void scan_set_connectable_only(void);


/****************************************************************************
NAME    
    scan_set_discoverable_only

DESCRIPTION
    Sets scanning so the device is discoverable only.
 
*/
void scan_set_discoverable_only(void);


/****************************************************************************
NAME    
    scan_set_connectable_discoverable

DESCRIPTION
    Sets scanning so the device is connectable and discoverable.
 
*/
void scan_set_connectable_discoverable(void);


/****************************************************************************
NAME    
    scan_check_connection_state

DESCRIPTION
    If the connection state has been updated this function will be called
    to check if the scan state has to be updated. This will only be relevant
    if DualStream is enabled as the device will still need to be connectable
    if only connected to one A2DP device.
 
*/
void scan_check_connection_state(void);


#endif /* _SOURCE_SCAN_H_ */
