/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_init.h
    
DESCRIPTION
    
*/

#ifndef _SINK_INIT_H_
#define _SINK_INIT_H_

/*************************************************************************
NAME    
    InitUserFeatures
    
DESCRIPTION
    This function initialises all of the user features - this will result in a
    poweron message if a user event is configured correctly and the device will 
    complete the power on

RETURNS

*/
void InitUserFeatures ( void );

/*************************************************************************
NAME    
    InitEarlyUserFeatures
    
DESCRIPTION
    This function initialises the configureation that is required early 
    on in the start-up sequence. 

RETURNS

*/
void InitEarlyUserFeatures ( void );

/****************************************************************************
NAME	
	SetupPowerTable

DESCRIPTION
	Attempts to obtain a low power table from the Ps Key store.  If no table 
	(or an incomplete one) is found	in Ps Keys then the default is used.
	
RETURNS
	void
*/
void SetupPowerTable( void );


/****************************************************************************
NAME    
    sinkHfpInit
    
DESCRIPTION
    Initialise the HFP library
	
RETURNS
    void
*/
void sinkHfpInit( void );


/****************************************************************************
NAME    
    sinkInitComplete
    
DESCRIPTION
    Sink device initialisation has completed. 

RETURNS
    void
*/
void sinkInitComplete( const HFP_INIT_CFM_T *cfm );

#endif /* _SINK_INIT_H_ */
