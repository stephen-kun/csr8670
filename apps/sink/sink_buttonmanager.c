/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    main.c        

DESCRIPTION
    This is the button manager for Sink device
    This file provides a configurable wrapper for the button messages and
    converts them into the standard system messages which are passed to the
    main message handler - main.c

NOTES
 
*/
#include "sink_private.h"
#include "sink_buttonmanager.h"
#include "sink_statemanager.h"
#include "sink_buttons.h"
#include "sink_volume.h"
#include "sink_scan.h"
#include "sink_led_manager.h"

#include <stddef.h>
#include <csrtypes.h>
#include <panic.h>
#include <stdlib.h>
#include <string.h>

#include "sink_events.h"

#ifdef DEBUG_BUT_MAN
    #define BM_DEBUG(x) DEBUG(x)
    
    const char * const gDebugTimeStrings[14] = {"Inv" , 
    											"Short", 
                                                "Long" ,
                                                "VLong" , 
                                                "Double" ,
                                                "Rpt" , 
                                                "LToH" , 
                                                "HToL" , 
                                                "ShSingle",
                                                "Long Release",
                                                "VLong Release",
                                                "V V Long" ,
                                                "VV Long Release" ,
                                                "Triple" } ;
                 
#else
    #define BM_DEBUG(x) 
#endif

/*
 LOCAL FUNCTION PROTOTYPES
 */
static void BMCheckForButtonMatch ( uint32 pButtonMask , ButtonsTime_t  pDuration  )  ;

static void BMCheckForButtonPatternMatch ( uint32 pButtonMask ) ;

/****************************************************************************
VARIABLES  
*/

#define BM_NUM_BLOCKS (2)
#define BM_NUM_CONFIGURABLE_EVENTS (BM_EVENTS_PER_BLOCK * BM_NUM_BLOCKS)

#define BUTTON_PIO_DEBOUNCE_NUM_CHECKS  (4)
#define BUTTON_PIO_DEBOUNCE_TIME_MS     (15)

/****************************************************************************
  FUNCTIONS
*/

/****************************************************************************
NAME 
 	buttonManagerInit
*/  
void buttonManagerInit ( void ) 
{   	
			/*put the buttons task and the button patterens in a single memory block*/
	int lSize = sizeof(ButtonsTaskData) ; 
		
	/*allocate the memory*/
	theSink.theButtonsTask = mallocPanic( lSize );

    /* initialise structure */    
    memset(theSink.theButtonsTask, 0, lSize);  
	
    theSink.theButtonsTask->client = &theSink.task;
 
	/*create the array of Button Events that we are going to populate*/   
    BM_DEBUG(("BM: ButtonEvents block size [%u]\n" ,  sizeof( ButtonEvents_t ) * BM_EVENTS_PER_CONF_BLOCK ));
    theSink.theButtonsTask->gButtonEvents[0] = (ButtonEvents_t * ) ( mallocPanic( sizeof( ButtonEvents_t ) * BM_EVENTS_PER_CONF_BLOCK ) ) ;
    theSink.theButtonsTask->gButtonEvents[1]= (ButtonEvents_t * ) ( mallocPanic( sizeof( ButtonEvents_t ) * BM_EVENTS_PER_CONF_BLOCK ) ) ;
    
      /*init the PIO button routines with the Button manager Task data */ 
    ButtonsInit( theSink.theButtonsTask ) ; 
}

/****************************************************************************

DESCRIPTION
	Wrapper method for the button Duration Setup
	configures the button durations to the user values

*/   
void buttonManagerConfigDurations ( ButtonsTaskData *pButtonsTask, button_config_type * pButtons )
{
    pButtonsTask->button_config = (button_config_type *)pButtons ;
	
	if ((pButtons->debounce_number == 0 ) || ( pButtons->debounce_period_ms == 0 ) )
	{
		/*use defaults*/
		DEBUG(("BM: DEFAULT button debounce\n")) ;
		pButtonsTask->button_config->debounce_number =  BUTTON_PIO_DEBOUNCE_NUM_CHECKS;
		pButtonsTask->button_config->debounce_period_ms = BUTTON_PIO_DEBOUNCE_TIME_MS ;		
	}
	else
	{
		DEBUG(("BM: Debounce[%x][%x]\n" , pButtonsTask->button_config->debounce_number ,pButtonsTask->button_config->debounce_period_ms)) ;
	}
}

/****************************************************************************
NAME	
	buttonManagerAddMapping     
*/     
void buttonManagerAddMapping ( event_config_type * event_config, uint8 index ) 
{
    ButtonsTaskData * lButtonsTask = theSink.theButtonsTask ;                   
    ButtonEvents_t * lInputEvent;
    uint16 lBlockIndex = 0 ; 
    uint16 lEvIndex = 0 ;   
    
    /* Select the correct input event block */
    if(index < BM_EVENTS_PER_CONF_BLOCK)
    {
        lBlockIndex = 0;
        lEvIndex = index;
    }
    /* use second set of button events as first set of events is now full*/
    else
    {
        lBlockIndex = 1;
        lEvIndex = index - BM_EVENTS_PER_CONF_BLOCK;
    }
    
    /* get input configuration for index passed in */
    lInputEvent = &lButtonsTask->gButtonEvents[lBlockIndex][lEvIndex];
  
    /* if input has been assigned, process and add to input checking masks */
    if ( lInputEvent )
    {
        /* store button mask */
        lInputEvent->ButtonMaskLS = event_config->pio_mask;   
        lInputEvent->ButtonMaskVC = (uint32)((uint32)((uint32)event_config->state_mask & 0xC000 ) >>14);     
                
        /* set duration, configured event and states mask from config */
        lInputEvent->Duration   = (ButtonsTime_t)event_config->type ;
        lInputEvent->Event      = event_config->event  ;
        lInputEvent->StateMask  = event_config->state_mask & 0x3fff ;              
    
        /* look for edge detect configuration of input and add the input used to the check for edge detect */
        if((lInputEvent->Duration == B_LOW_TO_HIGH)||(lInputEvent->Duration == B_HIGH_TO_LOW))
        {
            /* add input mask bit */
            lButtonsTask->gPerformInputEdgeCheck |= (uint32)((lInputEvent->ButtonMaskLS | (uint32)(lInputEvent->ButtonMaskVC) << VREG_PIN));
        }
        /* otherwise must be a level check */
        else if(lInputEvent->Duration > B_INVALID)
        {
            lButtonsTask->gPerformInputLevelCheck |= (uint32)((lInputEvent->ButtonMaskLS | (uint32)(lInputEvent->ButtonMaskVC) << VREG_PIN));
        }               
        
        BM_DEBUG(("BM: Add Mapping: Event[%x] Duration[%x] Input Mask[0x%lx] Level Check[0x%lx]\n", lInputEvent->Event
                                                                                                  , lInputEvent->Duration
                                                                                                  , (uint32)((lInputEvent->ButtonMaskLS | (uint32)(lInputEvent->ButtonMaskVC) << VREG_PIN))
                                                                                                  , lButtonsTask->gPerformInputLevelCheck ));

        /* translate input into PIO only mask for registering PIO debounce assignments, excluding capacitive touch bits */
        /* create mask of pios being used to set debounce state */               
        lButtonsTask->gButtonPIOLevelMask |= ButtonsTranslateInput(lBlockIndex, lEvIndex, FALSE) ; 
    }
    else
    {
        BM_DEBUG(("_!BM1\n")) ;
    }
        
}


/****************************************************************************
DESCRIPTION
 	add a new button pattern mapping
*/
void buttonManagerAddPatternMapping ( ButtonsTaskData *pButtonsTask, uint16 pSystemEvent , uint16 * pButtonsToMatch, uint16 lPatternIndex ) 
{   
    
    uint16 lButtonIndex = 0 ;

    /*adds a button pattern map*/
    if (pButtonsTask->gButtonPatterns[lPatternIndex].EventToSend == B_INVALID )
    {
        pButtonsTask->gButtonPatterns[lPatternIndex].EventToSend = pSystemEvent ;
    
        for (lButtonIndex = 0 ; lButtonIndex < BM_NUM_BUTTONS_PER_MATCH_PATTERN ; lButtonIndex++)
        {
            uint32 pattern = 0;
            
            /* if a pio is defined convert it to a 32 bit bitmask */
            if(pButtonsToMatch[lButtonIndex])
                pattern = (1<<(pButtonsToMatch[lButtonIndex]-1));
            
            pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[lButtonIndex] = pattern ;
        
            if (pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[lButtonIndex] != 0)
            {
                pButtonsTask->gButtonPatterns[lPatternIndex].NumberOfMatches = lButtonIndex + 1;
            }
        }
        
        BM_DEBUG(("BM: But Pat  [%x] ,[%lx][%lx][%lx][%lx][%lx][%lx] [%d]\n" ,  pButtonsTask->gButtonPatterns[lPatternIndex].EventToSend
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[0]
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[1]
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[2]
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[3]
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[4]
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].ButtonToMatch[5]
                                                                        
                                                                        , pButtonsTask->gButtonPatterns[lPatternIndex].NumberOfMatches )) ;
    }    
    
}


/****************************************************************************
NAME	
	BMButtonDetected

DESCRIPTION
	function call for when a button has been detected 
RETURNS
	void
    
*/
void BMButtonDetected ( uint32 pButtonMask , ButtonsTime_t pTime  )
{
 
    BM_DEBUG(("BM : But [%lx] [%s]\n" ,pButtonMask ,  gDebugTimeStrings[pTime]  )) ;
 
    /*perform the search over both blocks*/
    BMCheckForButtonMatch ( pButtonMask  , pTime ) ;
    
    /*only use regular button presses for the pattern matching to make life simpler*/
    if ( ( pTime == B_SHORT ) || (pTime == B_LONG ) )
    {
        BMCheckForButtonPatternMatch (  pButtonMask ) ;
    }   
}


/****************************************************************************
NAME 
 BMCheckButtonLock
    
DESCRIPTION
 function to chyeck if a button press should be ignored because of
 the button lock feature.  Returns TRUE if the button event should be blocked.
    
RETURNS

    void
*/   
static bool BMCheckButtonLock ( MessageId id ) 
{
    /* ignore button lock in a call state */
    uint16 statemask = ( (1 << deviceOutgoingCallEstablish) | 
                         (1 << deviceIncomingCallEstablish) | 
                         (1 << deviceActiveCallSCO) | 
                         (1 << deviceThreeWayCallWaiting) |
                         (1 << deviceThreeWayCallOnHold) |
                         (1 << deviceThreeWayMulticall) |
                         (1 << deviceIncomingCallOnHold) );
    
    sinkState state = stateManagerGetState ();
    
    /* check if button lock is enabled or in a call state where the lock should be ignored */
    if((!theSink.buttons_locked) || ( statemask & (1 << state) ))
    {
        BM_DEBUG(("BM : Button Lock status[%x][%x][%x]\n" , theSink.buttons_locked, statemask, state)) ;
        return FALSE;
    }    

    /* Buttons are locked and not in a call state, check this isn't a charger event or an attempt to 
       unlock the buttons */
    switch(id)
    {
        case EventUsrButtonLockingToggle:
        case EventUsrButtonLockingOff:
        case EventUsrChargerConnected:
        case EventUsrChargerDisconnected:
            BM_DEBUG(("BM : Event bypasses button lock [%x]\n" , id)) ;
            return FALSE;
        default:
            BM_DEBUG(("BM : Button Locked [%x]\n" , id)) ;
            return TRUE;
    }

}

/****************************************************************************
NAME 
 BMCheckForButtonMatch
    
DESCRIPTION
 function to check a button for a match in the button events map - sends a message
    to a connected task with the corresponding event
    
RETURNS

    void
*/   
static void BMCheckForButtonMatch ( uint32 pButtonMask , ButtonsTime_t  pDuration ) 
{
    uint16 lBlockIndex = 0 ; 
    uint16 lEvIndex = 0 ;        
    uint32 lMask = 0;
    
        /*each block*/
    for (lBlockIndex = 0 ; lBlockIndex < BM_NUM_BLOCKS ; lBlockIndex++)
    {       /*Each Entry*/        
        for (lEvIndex = 0 ; lEvIndex < BM_EVENTS_PER_CONF_BLOCK ; lEvIndex ++)
        { 
            ButtonEvents_t * lButtonEvent = &theSink.theButtonsTask->gButtonEvents [lBlockIndex] [ lEvIndex ] ;
            /*if the event is valid*/
            if ( lButtonEvent != NULL)
            {     
                /* work out input mask for this event configuration */
               lMask = (uint32)(lButtonEvent->ButtonMaskLS | (uint32)(lButtonEvent->ButtonMaskVC) << VREG_PIN);  

               /* if the input mask of the configuration item being checked matches the current inputs being set
                  progress to checking the current state and stte configuration of that input to see if an event should
                  be generated */
               if (lMask == pButtonMask )
               {                          
                    /*we have a button match*/
                    if ( lButtonEvent->Duration == pDuration )
                    {           
                        if ( (lButtonEvent->StateMask) & ( ( 1 << stateManagerGetState () )) )
                        {                                
                            BM_DEBUG(("BM : State Match [%lx][%x][%x]\n" , pButtonMask ,  lButtonEvent->Event, lButtonEvent->StateMask)) ;
                            
                            /* if the led's are disabled and the feature bit to ignore a button press when the
                               led's are enabled is true then ignore this button press and just re-enable the leds */
							if(theSink.theLEDTask->gLEDSStateTimeout && theSink.features.IgnoreButtonPressAfterLedEnable)
                            {
								LEDManagerCheckTimeoutState();
                            }
                            /* all other cases the button generated event is processed as normal */
                            else
							{
                                /* Only indicate the event if the buttons are unlocked or this is actually the user 
                                   trying to unlock them */                                
                                if(!BMCheckButtonLock(lButtonEvent->Event + EVENTS_MESSAGE_BASE))
                                {
                                    /*we have fully matched an event....so tell the main task about it*/
                                    MessageSend( theSink.theButtonsTask->client, (lButtonEvent->Event + EVENTS_MESSAGE_BASE) , 0 ) ;								
                                }
                                else
                                {
                                    /* Button has been blocked because the buttons are locked, event is sent so the block event can be indicated */
                                    MessageSend( theSink.theButtonsTask->client, EventSysButtonBlockedByLock , 0 ) ;		
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
  
/****************************************************************************
DESCRIPTION
 	check to see if a button pattern has been matched
*/
static void BMCheckForButtonPatternMatch ( uint32 pButtonMask  ) 
{
    uint16 lIndex = 0 ;
    
    ButtonsTaskData * lButtonsTask = theSink.theButtonsTask ;
    
    BM_DEBUG(("BM: Pat[%lx]\n", pButtonMask )) ;
    
    for (lIndex = 0; lIndex < BM_NUM_BUTTON_MATCH_PATTERNS ; lIndex++ )
    { 

        BM_DEBUG(("BM: Check Match - progress= [%d]\n", lButtonsTask->gButtonMatchProgress[lIndex] )) ;

        if ( lButtonsTask->gButtonPatterns[lIndex].ButtonToMatch[lButtonsTask->gButtonMatchProgress[lIndex]] == pButtonMask )
        {
                    /*we have matched a button*/
            lButtonsTask->gButtonMatchProgress[lIndex]++ ;
            
            BM_DEBUG(("BM: Pat Prog[%d][%x]\n", lIndex , lButtonsTask->gButtonMatchProgress[lIndex]  )) ;
                    
                
            if (lButtonsTask->gButtonMatchProgress[lIndex] >= lButtonsTask->gButtonPatterns[lIndex].NumberOfMatches)
            {
                        /*we have matched a pattern*/
                BM_DEBUG(("BM: Pat Match[%d] Ev[%x]\n", lIndex ,lButtonsTask->gButtonPatterns[lIndex].EventToSend)) ;
                
                lButtonsTask->gButtonMatchProgress[lIndex] = 0 ;
                
                MessageSend( lButtonsTask->client, lButtonsTask->gButtonPatterns[lIndex].EventToSend , 0 ) ;
            }
            
        }       
        else
        {
            lButtonsTask->gButtonMatchProgress[lIndex] = 0 ;
                /*special case = if the last button pressed was the same as the first button*/
            if ( lButtonsTask->gButtonPatterns [ lIndex ].ButtonToMatch[0]== pButtonMask)            
            {
                lButtonsTask->gButtonMatchProgress[lIndex] = 1 ;
            
            }
        }
    }
}


/****************************************************************************
DESCRIPTION
 	perform an initial read of pios following configuration reading as it is possible
    that pio states may have changed whilst the config was being read and now needs
    checking to see if any relevant events need to be generated 
*/

void BMCheckButtonsAfterReadingConfig( void )
{
    ButtonsCheckForChangeAfterInit();
}
