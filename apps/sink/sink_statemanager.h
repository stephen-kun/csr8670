/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_statemanager.h
    
DESCRIPTION
    main device state information
    
*/


/*!
@file	sink_statemanager.h
@brief	Header file for the state handling of the sink application.

		Provides single point of entry and exit for all of the device states
*/

#ifndef _SINK_STATE_MANAGER_H
#define _SINK_STATE_MANAGER_H

#include "sink_private.h"
#include "sink_states.h"



/*!
	@brief Instruct the device to enter the connectable state

	@param pApp The main application task
	
	@param req_disc If the device is currently connected then request a HfpDisconnect
	
	After this funciton is called, the device will be in page scanning mode
*/
void stateManagerEnterConnectableState( bool req_disc ) ;

/*!
	@brief Instruct the device to enter the connected state

	@param pApp The main application task
	
	If the device was previously discoverable or connectable, then disables these modes
	
	If the device was previously in an active call the EventSysEndOfCall is sent
*/
void stateManagerEnterConnectedState( void ) ;

/*!
	@brief Instruct the device to enter the connectable/Discoveranble state

	@param pApp The main application task
	
	After this function is callerd, then the device will be both page scanning and 
    inquiry scanning
*/
void stateManagerEnterConnDiscoverableState( bool req_disc ) ;

/*!
	@brief Instruct the device to enter the Incoming call state

	@param pApp The main application task
	
	This occurs after the HFP call setup indicator has changed
	or in HSP mode, the RING has been detected
	
	If the device was previously in a non-conencted state and the feature bit to 
    auto answer is enabled, then the device will attempt to answer the call
    
    Any Incoming RING PIO is set high
*/
void stateManagerEnterIncomingCallEstablishState( void ) ;

/*!
	@brief Instruct the device to enter the outgoing call state

	@param pApp The main application task
	
	This occurs after the HFP call setup indicator has changed
	Any outgoing RING is set high	
*/
void stateManagerEnterOutgoingCallEstablishState( void ) ;

/*!
	@brief Instruct the device to enter the active call state

	@param pApp The main application task
	
	This occurs after the HFP call indicator has changed
	
	Incoming / outgoing PIOs are cleared 
	Any active call PIO is set 
	
*/
void stateManagerEnterActiveCallState( void ) ;

/*!
	@brief Instruct the device to begin powering off

	@param pApp The main application task
	
	Disconnects any active SLC (connection)
	
	and waits for the Limbo timeout until an actual power off 
*/
void stateManagerEnterPoweringOffState( void ) ;

/*!
	@brief Instruct the device to enter the Limbo state

	@param pApp The main application task
	
	The device is now logically off but physically still on.
	
	This occurs on power on before a power on event has been received 
    OR after a power off event has ben received and before the device is 
    physically shut down.
    
    The device remains in this state for the Limbo Timout which can 
    be configured in  (CONFIG_TIMEOUTS)) 
*/
void stateManagerEnterLimboState( void ) ;

/*!
	@brief Instruct the device to check the Limbo state

	@param pApp The main application task
	
	This occurs periodically to check if the device can physically power
	down (after the limbo timeout)
	
	If the charger is not connected then the device will physically power down 
	
	If the charger is connected, then the device remains in the limbo state in order to 
	service any charger LED indications
*/
void stateManagerUpdateLimboState( void ) ;

/*!
	@brief Instruct the device to physically power on

	@param pApp The main application task
	
	This occurs only after receiveing a power on event
	After this call, the device will be in the conenctable state
*/
void stateManagerPowerOn( void ) ;

/*!
	@brief Instruct the device to enter the three way call waiting state

	@param pApp The main application task	
*/
void stateManagerEnterThreeWayCallWaitingState( void ) ;

/*!
	@brief Instruct the device to enter the three way call on hold state

	@param pApp The main application task	
*/
void stateManagerEnterThreeWayCallOnHoldState( void ) ;

/*!
	@brief Instruct the device to enter the three way multi party call state

	@param pApp The main application task	
*/
void stateManagerEnterThreeWayMulticallState( void ) ;

/*!
	@brief Instruct the device to enter the single incoming on hold state

	@param pApp The main application task	
*/
void stateManagerEnterIncomingCallOnHoldState( void ) ;

/*!
	@brief request the current state of the device 

    @return The current state of the device	
*/
sinkState stateManagerGetState ( void ) ;

/*!
	@brief request whether or not the device is connected 

    @return TRUE if connected
*/
bool stateManagerIsConnected ( void ) ;

/*!
	@brief Instruct the device to enter the test mode state

	@param pApp The main application task	
*/
void stateManagerEnterTestModeState ( void ) ;

/****************************************************************************
NAME	
	stateManagerEnterA2dpStreamingState

DESCRIPTION
    enter A2DP streaming state if not showing any active call states
RETURNS
	void
    
*/
void stateManagerEnterA2dpStreamingState(void);

/****************************************************************************
NAME	
	stateManagerAmpPowerControl

DESCRIPTION
    method to control logic state of mute and power PIOs for audio amplifier stage
RETURNS	
    
*/
void stateManagerAmpPowerControl(power_control_dir);
        
#endif

