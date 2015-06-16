/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_states.h

DESCRIPTION
    Main application state machine.
    
*/


#ifndef _SOURCE_STATES_H_
#define _SOURCE_STATES_H_


/* Application state machine */
typedef enum
{    
    SOURCE_STATE_INITIALISING,      /* The source is initailising */    	
    SOURCE_STATE_POWERED_OFF,       /* The source is powered off */    	
    SOURCE_STATE_TEST_MODE,         /* The source is in test mode */    
    SOURCE_STATE_IDLE,              /* The source is powered on in an idle state */    
    SOURCE_STATE_CONNECTABLE,       /* The source is connectable - page scan */    
    SOURCE_STATE_DISCOVERABLE,      /* The source is discoverable - inquiry scan */    
    SOURCE_STATE_CONNECTING,        /* The source is connecting - paging */    
    SOURCE_STATE_INQUIRING,         /* The source is looking for a new device - inquiry */    
    SOURCE_STATE_CONNECTED          /* The source is connected to a device */
} SOURCE_STATE_T;

#define SOURCE_STATES_MAX  (SOURCE_STATE_CONNECTED + 1)


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    states_set_state

DESCRIPTION
    Sets the new application state.
 
*/
void states_set_state(SOURCE_STATE_T new_state);


/****************************************************************************
NAME    
    states_get_state

DESCRIPTION
    Gets the application state.
    
RETURNS
    The application state.
 
*/
SOURCE_STATE_T states_get_state(void);


/****************************************************************************
NAME    
    states_force_inquiry

DESCRIPTION
    Move to Inquiry state regardless of current activity.
 
*/
void states_force_inquiry(void);


/****************************************************************************
NAME    
    states_no_timers

DESCRIPTION
    Turns off timers that were set by the PS configuration.
 
*/
void states_no_timers(void);
        

#endif /* _SOURCE_STATES_H_ */
