/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_scan.h
    
DESCRIPTION
    
*/

#ifndef _SINK_SCAN_H_
#define _SINK_SCAN_H_


/****************************************************************************
NAME    
    sinkWriteEirData
    
DESCRIPTION
    Writes the local name and device UUIDs into device EIR data, local name 
	is shortened to fit into a DH1 packet if necessary

RETURNS
    void
*/
void sinkWriteEirData( CL_DM_LOCAL_NAME_COMPLETE_T *message );


/****************************************************************************
NAME    
    sinkEnableConnectable
    
DESCRIPTION
    Make the device connectable 

RETURNS
    void
*/
void sinkEnableConnectable( void );


/****************************************************************************
NAME    
    sinkDisableConnectable
    
DESCRIPTION
    Take device out of connectable mode.

RETURNS
    void
*/
void sinkDisableConnectable( void );


/****************************************************************************
NAME    
    sinkEnableDiscoverable
    
DESCRIPTION
    Make the device discoverable. 

RETURNS
    void
*/
void sinkEnableDiscoverable( void );


/****************************************************************************
NAME    
    sinkDisableDiscoverable
    
DESCRIPTION
    Make the device non-discoverable. 

RETURNS
    void
*/
void sinkDisableDiscoverable( void );


/****************************************************************************
NAME    
    sinkEnableMultipointConnectable
    
DESCRIPTION
    when in multi point mode check to see if device can be made connectable,
    this will be when only one AG is currently connected. this function will
    be called upon certain button presses which will reset the 60 second timer
    and allow a second AG to connect should the device have become non discoverable
    
RETURNS
    none
*/
void sinkEnableMultipointConnectable( void );


#endif /* _SINK_SCAN_H_ */
