/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_dut.h
    
DESCRIPTION
	Place the device into Device Under Test (DUT) mode
    
*/

#ifndef _SINK_DUT_H_
#define _SINK_DUT_H_


/****************************************************************************
DESCRIPTION
  	This function is called to place the device into DUT mode
*/
void enterDutMode(void);

/****************************************************************************
DESCRIPTION
  	This function is called to place the device into TX continuous test mode
*/

void enterTxContinuousTestMode ( void ) ;

/****************************************************************************
DESCRIPTION
  	This function is called to determine if the device should enter DUT mode.
*/
bool checkForDUTModeEntry( void );

/****************************************************************************
DESCRIPTION
  	Enter service mode - device changers local name and enters discoverable 
	mode
*/
void enterServiceMode( void ) ;
 
/****************************************************************************
DESCRIPTION
  	handle a local bdaddr request and continue to enter service mode
*/
void DutHandleLocalAddr(CL_DM_LOCAL_BD_ADDR_CFM_T *cfm) ;



/************************************************************************* 
DESCRIPTION
    Perform the CVC production test routing and nothing else in the given
    boot mode
*/
void cvcProductionTestEnter ( void ) ;

/*************************************************************************
DESCRIPTION
    Handle the response from Kalimba to figure out if the CVC licence key exists    
*/
void cvcProductionTestKalimbaMessage ( Task task, MessageId id, Message message ) ;


/*************************************************************************
DESCRIPTION
    Enter an audio test mode to route mic to speaker
*/
void enterAudioTestMode(void);


/*************************************************************************
DESCRIPTION
    Enter a tone test mode to continuously repeat the tone specified
*/
void enterToneTestMode(void);


/*************************************************************************
DESCRIPTION
    Enter a key test mode to cycle through LED patterns based on pressing the configured keys (PIOs)
*/
void enterKeyTestMode(void);


/*************************************************************************
DESCRIPTION
    A configured key has been pressed, check if this is in key test mode
*/
void checkDUTKeyPress(uint32 lNewState);


/*************************************************************************
DESCRIPTION
    A configured key has been released, check if this is in key test mode
*/
void checkDUTKeyRelease(uint32 lNewState, ButtonsTime_t pTime);


/*************************************************************************
DESCRIPTION
    Initialise DUT mode
*/
void dutInit(void);


/*************************************************************************
DESCRIPTION
    Return if DUT audio mode is running
*/
bool isDutAudioActive(void);


#endif /* _SINK_DUT_H_ */
