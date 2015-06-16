/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_LED_manager.c
    
DESCRIPTION
    Module responsible for managing the PIO outputs including LEDs
    
*/

/****************************************************************************
INCLUDES
*/
#include "sink_led_manager.h"
#include "sink_private.h"


#include "sink_configmanager.h"
#include "sink_statemanager.h"
#include "sink_leds.h"
#include "sink_leddata.h"
#include "sink_pio.h"
#include "sink_powermanager.h"

#include <stddef.h>
#include <pio.h>
#include <stdlib.h>
#include <string.h>

/****************************************************************************
DEFINITIONS
*/


#ifdef DEBUG_LM
#define LM_DEBUG(x) {printf x;}
#else
#define LM_DEBUG(x) 
#endif


/****************************************************************************
LOCAL FUNCTION PROTOTYPES
*/


 /*methods to allocate/ initialise the space for the patterns and mappings*/
static void LEDManagerInitStatePatterns   ( void ) ;
static void LEDManagerInitEventPatterns   ( void ) ;
static void LEDManagerInitActiveLEDS      ( void ) ;
static void LEDManagerCreateFilterPatterns( void ) ;

/****************************************************************************
NAME	
	ledManagerMemoryInit

DESCRIPTION
	Initialise memory for led manager, this has moved from theSink as ran 
    out of globals space.

RETURNS
	void
    
*/
void LedManagerMemoryInit(void) 
{
	/* Allocate memory to hold the led manager states */
    LM_DEBUG(("LM Mem Init Task 0x%x, active leds 0x%x:\n",sizeof(LedTaskData),(sizeof(LEDActivity_t) * SINK_NUM_LEDS) )) ;    
	theSink.theLEDTask = mallocPanic(sizeof(LedTaskData));
    memset(theSink.theLEDTask, 0, sizeof(LedTaskData));
    
    /* allocate memory for LED events */
    theSink.theLEDTask->pEventPatterns = mallocPanic(LM_MAX_NUM_PATTERNS * sizeof(LEDPattern_t));
    memset(theSink.theLEDTask->pEventPatterns, 0, LM_MAX_NUM_PATTERNS * sizeof(LEDPattern_t));
}

/****************************************************************************
NAME 
 PIOManagerInit

DESCRIPTION
 Initialises LED manager

RETURNS
 void
    
*/
void LEDManagerInit ( void ) 
{
        
    LM_DEBUG(("LM Init :\n")) ;
   
    theSink.theLEDTask->gLEDSSuspend = FALSE;
                
    LM_DEBUG(("LM : p[%x][%x][%x]\n" ,  (int)theSink.theLEDTask->gStatePatterns ,
                                        (int)*theSink.theLEDTask->pEventPatterns ,
                                        (int)theSink.theLEDTask->gActiveLEDS    
            )) ;
    
    /*create the patterns we want to use*/
    LEDManagerInitStatePatterns ( ) ;
    LEDManagerInitActiveLEDS( ) ;
    LEDManagerInitEventPatterns( ) ;
    
    memset(theSink.theLEDTask->Queue, 0, sizeof(LEDEventQueue_t));
    
    /*the filter information*/
    LEDManagerCreateFilterPatterns( ) ;
    
    LedsInit ( ) ;

}
/****************************************************************************
NAME 
 LEDManagerInitActiveLEDS

DESCRIPTION
 Creates the active LED space for the number of leds the system supports

RETURNS
 void
    
*/
static void LEDManagerInitActiveLEDS ( void ) 
{
    uint16 lIndex = 0; 
 
    for ( lIndex= 0 ; lIndex < SINK_NUM_LEDS ; lIndex ++ )
    {
        LedsSetLedActivity ( &theSink.theLEDTask->gActiveLEDS [ lIndex ] , IT_Undefined , 0 , 0 ) ;    
    }
}
/****************************************************************************
NAME 
 LEDManagerInitStatePatterns

DESCRIPTION
 Creates the state patterns space for the system states

RETURNS
 void
    
*/
static void LEDManagerInitStatePatterns ( void ) 
{
    uint16 lIndex = 0; 
 
    for ( lIndex= 0 ; lIndex < SINK_NUM_STATES ; lIndex ++ )
    {
        LEDPattern_t *lStatePattern = &(theSink.theLEDTask->gStatePatterns[lIndex]);
        
        memset(lStatePattern, 0, sizeof(LEDPattern_t));
        lStatePattern->Colour     = LED_COL_LED_A ;  
    }
     
}
/****************************************************************************
NAME 
 LEDManagerInitEventPatterns

DESCRIPTION
 inits the Event pattern pointers

RETURNS
 void
    
*/
static void LEDManagerInitEventPatterns ( void )
{
    uint16 lIndex = 0; 
 
    for ( lIndex= 0 ; lIndex < LM_MAX_NUM_PATTERNS ; lIndex ++ )
    {
        LEDPattern_t *lEventPattern = &(theSink.theLEDTask->pEventPatterns[lIndex]);
        
        memset(lEventPattern, 0, sizeof(LEDPattern_t));
        lEventPattern->Colour     = LED_COL_LED_A ;  
    } 
}
/****************************************************************************
NAME 
 LEDManagerCreateFilterPatterns

DESCRIPTION
 Creates the Filter patterns space 

RETURNS
 void
    
*/
static void LEDManagerCreateFilterPatterns ( void )
{
    uint16 lIndex = 0 ;
    

    for (lIndex = 0 ; lIndex < LM_NUM_FILTER_EVENTS ; lIndex++ )
    {
        LEDFilter_t *lEventFilter = &(theSink.theLEDTask->gEventFilters [ lIndex ]);
        
        memset(lEventFilter, 0, sizeof(LEDFilter_t));
    }
    
    theSink.theLEDTask->gLMNumFiltersUsed = 0 ;

    LED_SETACTIVEFILTERS(0x0);
}
 

#ifdef DEBUG_LM
/****************************************************************************
NAME 
 LMPrintPattern

DESCRIPTION
    debug fn to output a LED pattern
    
RETURNS
 void
*/

void LMPrintPattern ( LEDPattern_t * pLED ) 
{
#ifdef DEBUG_PRINT_ENABLED
    const char * const lColStrings [ 5 ] =   {"LED_E ","LED_A","LED_B","ALT","Both"} ;
    if(pLED)
    {
        LM_DEBUG(("[%d][%d] [%d][%d][%d] ", pLED->LED_A , pLED->LED_B, pLED->OnTime ,pLED->OffTime ,pLED->RepeatTime)) ;  
        LM_DEBUG(("[%d] [%d] [%s]\n",       pLED->NumFlashes, pLED->TimeOut, lColStrings[pLED->Colour])) ;    
        LM_DEBUG(("[%d]\n",       pLED->OverideDisable)) ;    
    }
    else
    {
        LM_DEBUG(("LMPrintPattern = NULL \n")) ;  
    }
#endif

}
#endif


static bool ledManagerCanPlayPattern(LEDPattern_t* pattern)
{
    if(theSink.theLEDTask->gLEDSSuspend)
        return FALSE;

    return (theSink.theLEDTask->gLEDSEnabled || pattern->OverideDisable || LedActiveFiltersCanOverideDisable());
}


/****************************************************************************
NAME 
 LEDManagerIndicateEvent

DESCRIPTION
 displays event notification
    This function also enables / disables the event filter actions - if a normal event indication is not
    associated with the event, it checks to see if a filer is set up for the event 

RETURNS
 void
    
*/

void LEDManagerIndicateEvent ( MessageId pEvent ) 
{
	uint8 i,lPatternIndex;
    uint16 lEventIndex = pEvent ;
    LEDPattern_t * lPattern = NULL;
    
    lPatternIndex = NO_STATE_OR_EVENT;
    LM_DEBUG(("LM IndicateEvent [%x]\n", lEventIndex)) ;   
    
    /* search for a matching event */
    for(i=0;i<theSink.theLEDTask->gEventPatternsAllocated;i++)
    {
        if((theSink.theLEDTask->pEventPatterns[i]).StateOrEvent == lEventIndex)
        {
            lPatternIndex = i;
            lPattern      = &(theSink.theLEDTask->pEventPatterns[i]);            
            break;
        }
    }
        
    /*if there is an event configured*/
    if ( lPatternIndex != NO_STATE_OR_EVENT )
    {    
        /*only indicate if LEDs are enabled*/
        if (ledManagerCanPlayPattern(lPattern))
        {
    
            LM_DEBUG(("LM : IE[%x]\n",pEvent )) ;
 
            /*only update if wer are not currently indicating an event*/
            if ( ! theSink.theLEDTask->gCurrentlyIndicatingEvent )
            {
                ledsIndicateLedsPattern(lPattern, lPatternIndex, IT_EventIndication);
            }    
            else
            {
                if (theSink.features.QueueLEDEvents )
                {
                    uint8 i;
                    /*try and add it to the queue*/
                    LM_DEBUG(("LM: Queue LED Event [%x]\n" , pEvent )) ;
					
                    for(i = 0; i < sizeof(LEDEventQueue_t); i++)
                    {
                        if(theSink.theLEDTask->Queue[i] == 0)
                        {
                            theSink.theLEDTask->Queue[i] = pEvent;
                            break;
                        }
                    }
                    
#ifdef DEBUG_LM
					if(i == sizeof(LEDEventQueue_t))
                    {
                        LM_DEBUG(("LM: Err Queue Full!!\n")) ;
                    }
#endif
                }    
            }
        }
        else
        {
            LM_DEBUG(("LM : No IE disabled\n")) ;
        }  
    }
    else
    {
        LM_DEBUG(("LM: NoEvPatCfg %x\n",pEvent )) ;
    }
    
    /*indicate a filter if there is one present*/
    LedsCheckForFilter ( pEvent ) ;
	
}

/****************************************************************************
NAME	
	LEDManagerIndicateQueuedEvent

DESCRIPTION
	Display the event at the top of the event queue

RETURNS
	void
    
*/
void LedManagerIndicateQueuedEvent(void)
{
    uint8 i;
    LM_DEBUG(("LM : Queue [%x]", theSink.theLEDTask->Queue[0]));
    
    LEDManagerIndicateEvent(theSink.theLEDTask->Queue[0]) ;
    
    /* Shuffle the queue */
    for(i = 1; i < sizeof(LEDEventQueue_t); i++)
    {
        LM_DEBUG(("[%x]", theSink.theLEDTask->Queue[i]));
        theSink.theLEDTask->Queue[i - 1] = theSink.theLEDTask->Queue[i];
    }
    
    LM_DEBUG(("\n"));
    theSink.theLEDTask->Queue[sizeof(LEDEventQueue_t) - 1] = 0;
}

/****************************************************************************
NAME	
	LEDManagerIndicateState

DESCRIPTION
	displays state indication information

RETURNS
	void
    
*/

void LEDManagerIndicateState ( sinkState pState )  
{   
    /* Flags controlling which led indications are to be displayed are set to false by default */
    bool displayLedIndication = FALSE; 
    bool displayLedIndicationCurrState = FALSE;
    bool displayLedIndicationLowBatt = FALSE;
    
    /* Local variables and led pattern pointers are required for ledsIndicateLedsPattern(...) function 
    to display the Led pattern */      
    uint8 i,lPatternIndex, lowBattPatternIndex; 
    
    LEDPattern_t * lPattern = NULL;
    LEDPattern_t * lowBattPattern = NULL;
    
    lPatternIndex = NO_STATE_OR_EVENT;
    lowBattPatternIndex = NO_STATE_OR_EVENT;
     
#ifdef MONO_A2DP_STREAMING
	pState = stateManagerGetCombinedLEDState(pState);
#endif
	
    /* search for a matching state and low battery warning pattern */
	for(i=0;i<theSink.theLEDTask->gStatePatternsAllocated;i++)
    {
        if(theSink.theLEDTask->gStatePatterns[i].StateOrEvent == pState)
        {
            /* update indicated state index and associated led pattern */
            lPatternIndex = i;
            lPattern = &theSink.theLEDTask->gStatePatterns[i];
        }
        else if(theSink.theLEDTask->gStatePatterns[i].StateOrEvent == deviceLowBattery)
        {
            /* update indicated low battery warning and associated led pattern */
             lowBattPatternIndex = i;
             lowBattPattern = &theSink.theLEDTask->gStatePatterns[i];            
        }        
    }       
        
    /* Determine what the LED indication status should be and set the associated flags to be 
    processed in the next step for a proper LED indication handling mechanism */

    if( powerManagerIsVbatLow() ) /* In low battery warning state */
    {
       if(lowBattPattern == NULL) /* There is no low battery warning LED pattern defined */
       {
             if(lPattern == NULL)
                 displayLedIndication = FALSE;
             else
             {
                 displayLedIndication = TRUE;    
                 displayLedIndicationCurrState = TRUE;  
                 displayLedIndicationLowBatt = FALSE;
             }
        }
        else   /* There is a low battery warning LED pattern defined */
        {
             
            displayLedIndication = TRUE;    
            displayLedIndicationLowBatt = TRUE;
            displayLedIndicationCurrState = FALSE;            
        }
    }

    else /* Not in low battery warning state */
    {
        if(lPattern == NULL)
            displayLedIndication = FALSE;
        else
        {
            displayLedIndication = TRUE; 
            displayLedIndicationCurrState = TRUE;
            displayLedIndicationLowBatt = FALSE;
        }
    }
    
    /* Now process the flags previously set and display the associated LED pattern */
    if(displayLedIndication)
    {
        if(displayLedIndicationLowBatt) /* Associated Low Power Led Indication to be Displayed */
        {
            /*if there is a pattern associated with the Low Battery Warning Mode and not disabled, indicate it*/
            theSink.theLEDTask->gStateCanOverideDisable = lowBattPattern->OverideDisable;
                
            /* only indicate if LEDs are enabled*/
            if (ledManagerCanPlayPattern(lowBattPattern))
            {
                LM_DEBUG(("LM : Low Battery LED Indication Being Processed\n IS[%x]\n", pState)) ;
    
                if (    ( theSink.theLEDTask->gActiveLEDS[lowBattPattern->LED_A].Type != IT_EventIndication  )
                     && ( theSink.theLEDTask->gActiveLEDS[lowBattPattern->LED_B].Type != IT_EventIndication  ) )
                {   
                    /*Indicate the LED Pattern of Low Battery Warning Mode*/
                    ledsIndicateLedsPattern(lowBattPattern, lowBattPatternIndex, IT_StateIndication);        
                }
            }
            
            else /* No Led Indication to be processed due to ledManagerCanPlayPattern(lowBattPattern) returning false */
            {           
                LM_DEBUG(("LM: NoStCfg[%x]\n",pState)) ;
                LedsIndicateNoState ( ) ; 
            }
        }
        
        else if(displayLedIndicationCurrState) /* Not in Low Power Warning Mode, Associated State Led Indication to be Displayed */
        {
            /*if there is a pattern associated with the state and not disabled, indicate it*/
            theSink.theLEDTask->gStateCanOverideDisable = lPattern->OverideDisable;
                
            /* only indicate if LEDs are enabled*/
            if (ledManagerCanPlayPattern(lPattern))
            {
                LM_DEBUG(("LM : State LED Indication Being Processed\n IS[%x]\n", pState)) ;
    
                if (    ( theSink.theLEDTask->gActiveLEDS[lPattern->LED_A].Type != IT_EventIndication  )
                     && ( theSink.theLEDTask->gActiveLEDS[lPattern->LED_B].Type != IT_EventIndication  ) )
                {   
                   /*Indicate the LED Pattern of Event/State*/
                   ledsIndicateLedsPattern(lPattern, lPatternIndex, IT_StateIndication);        
                }
            }
            
            else /* No Led Indication to be processed due to ledManagerCanPlayPattern(lPattern) returning false */
            {           
                LM_DEBUG(("LM: NoStCfg[%x]\n",pState)) ;
                LedsIndicateNoState ( ) ; 
            }
        }
    }
    else /* No Led Indication to be processed due to no associated pattern having been found to display */
    {
        LM_DEBUG(("LM : DIS NoStCfg[%x]\n", pState)) ;
        LedsIndicateNoState ( ) ; 
    }
}

/****************************************************************************
NAME	
	LedManagerDisableLEDS

DESCRIPTION
    Disable LED indications
RETURNS
	void
    
*/
void LedManagerDisableLEDS ( void )
{
    LM_DEBUG(("LM Disable LEDS\n")) ;

    /*turn off all current LED Indications if not overidden by state or filter */
    if (!theSink.theLEDTask->gStateCanOverideDisable && !LedActiveFiltersCanOverideDisable())
    {
        LedsIndicateNoState ( ) ;
    }    
    
    theSink.theLEDTask->gLEDSEnabled = FALSE ;
}

/****************************************************************************
NAME	
	LedManagerEnableLEDS

DESCRIPTION
    Enable LED indications
RETURNS
	void
    
*/
void LedManagerEnableLEDS ( void )
{
    LM_DEBUG(("LM Enable LEDS\n")) ;
    
    theSink.theLEDTask->gLEDSEnabled = TRUE ;
         
    LEDManagerIndicateState ( stateManagerGetState() ) ;    
}


/****************************************************************************
NAME	
	LedManagerToggleLEDS

DESCRIPTION
    Toggle Enable / Disable LED indications
RETURNS
	void
    
*/
void LedManagerToggleLEDS ( void ) 
{
    if ( theSink.theLEDTask->gLEDSEnabled )
    {
   		MessageSend (&theSink.task , EventUsrLedsOff , 0) ;
    }
    else
    {
   		MessageSend (&theSink.task , EventUsrLedsOn , 0) ;
    }
}

/****************************************************************************
NAME	
	LedManagerResetLEDIndications

DESCRIPTION
    Resets the LED Indications and reverts to state indications
	Sets the Flag to allow the Next Event to interrupt the current LED Indication
    Used if you have a permanent LED event indication that you now want to interrupt
RETURNS
	void
    
*/
void LedManagerResetLEDIndications ( void )
{    
    LedsResetAllLeds ( ) ;
    
    theSink.theLEDTask->gCurrentlyIndicatingEvent = FALSE ;
    
    LEDManagerIndicateState (stateManagerGetState() ) ;
}

/****************************************************************************
NAME	
	LEDManagerResetStateIndNumRepeatsComplete

DESCRIPTION
    Resets the LED Number of Repeats complete for the current state indication
       This allows the time of the led indication to be reset every time an event 
       occurs.
RETURNS
	void
    
*/
void LEDManagerResetStateIndNumRepeatsComplete  ( void ) 
{
    uint8 i,lPatternIndex;   
    LEDPattern_t * lPattern = NULL;
    
    /*get state*/
    sinkState lState = stateManagerGetState() ;
    
    /*get pattern*/   
    lPatternIndex = NO_STATE_OR_EVENT;
        
    /* search for a matching state */
    for(i=0;i<theSink.theLEDTask->gStatePatternsAllocated;i++)
    {
        if(theSink.theLEDTask->gStatePatterns[i].StateOrEvent == lState)
        {
            /* force indicated state to that of Low Battery configured pattern */
            lPattern = &theSink.theLEDTask->gStatePatterns[i] ;
            lPatternIndex = i;
            break;
        }
    }       
       
    /* does pattern exist for this state */
    if (lPattern)
    {
        LEDActivity_t * lLED   = &theSink.theLEDTask->gActiveLEDS[lPattern->LED_A] ;
        if (lLED)
        {
            /*reset num repeats complete to 0*/
            lLED->NumRepeatsComplete = 0 ;
        }    
    }
}

/****************************************************************************
NAME	
	LEDManagerCheckTimeoutState

DESCRIPTION
    checks the led timeout state and resets it if required, this function is called from
    an event or volume button press to re-enable led indications as and when required
    to do so 
RETURNS
	void
    
*/
void LEDManagerCheckTimeoutState( void )
{
    /*handles the LED event timeouts - restarts state indications if we have had a user generated event only*/
    if (theSink.theLEDTask->gLEDSStateTimeout)
    {   
        /* send message that can be used to show an led pattern when led's are re-enabled following a timeout */
        MessageSend( &theSink.task, EventSysResetLEDTimeout, 0);
    }
    else
    {
        /*reset the current number of repeats complete - i.e restart the timer so that the leds will disable after
          the correct time*/
        LEDManagerResetStateIndNumRepeatsComplete  ( ) ;
    }
}


/****************************************************************************
NAME	
	LedManagerForceDisable

DESCRIPTION
    Set disable TRUE to force all LEDs off, call again with disable FALSE
    to restore LEDs to the correct state (including filters).

RETURNS
	void
*/
void LedManagerForceDisable( bool disable )
{
    if(disable != (bool)theSink.theLEDTask->gLEDSSuspend)
    {
        if(disable)
        {
            /* Suspend LED indications */
            LedsResetAllLeds() ;
            theSink.theLEDTask->gCurrentlyIndicatingEvent = FALSE ;
            theSink.theLEDTask->gLEDSSuspend = TRUE;
            LedsEnableFilterOverrides(FALSE);
        }
        else
        {
            /* Resume LED indications */
            theSink.theLEDTask->gLEDSSuspend = FALSE;
            LEDManagerIndicateState(stateManagerGetState());  
            LedsEnableFilterOverrides(TRUE);
        }
    }
}


