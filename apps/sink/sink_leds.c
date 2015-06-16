/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2007

FILE NAME
    sink_leds.c
    
DESCRIPTION
    Module responsible for managing the LED outputs and the pios 
    configured as led outputs
    
*/

#include "sink_leds.h"
#include "sink_private.h"
#include "sink_led_manager.h"
#include "sink_statemanager.h"
#include "sink_pio.h"

#include <panic.h>
#include <stddef.h>
#include <led.h>
#include <string.h>

#ifdef DEBUG_LEDS
#define LED_DEBUG(x) {printf x;}
#else
#define LED_DEBUG(x) 
#endif


#define LED_ON  TRUE    
#define LED_OFF FALSE

#define LEDS_STATE_START_DELAY_MS 300

 /*internal message handler for the LED callback messages*/
static void LedsMessageHandler( Task task, MessageId id, Message message ) ;

 /*helper functions for the message handler*/
static uint16 LedsApplyFilterToTime     ( uint16 pTime )  ;
static LEDColour_t LedsGetPatternColour ( const LEDPattern_t * pPattern ) ;

 /*helper functions to change the state of LED pairs depending on the pattern being played*/
static void LedsTurnOffLEDPair ( LEDPattern_t * pPattern, bool pUseOveride  ) ;
static void LedsTurnOnLEDPair  ( LEDPattern_t * pPattern , LEDActivity_t * pLED );

    /*method to complete an event*/
static void LedsEventComplete ( LEDActivity_t * pPrimaryLed , LEDActivity_t * pSecondaryLed ) ;
    /*method to indicate that an event has been completed*/
static void LedsSendEventComplete ( sinkEvents_t pEvent , bool pPatternCompleted ) ;

    /*filter enable - check methods*/
static bool LedsIsFilterEnabled ( uint16 pFilter ) ;
static void LedsEnableFilter ( uint16 pFilter , bool pEnable) ;

static void LedsHandleOverideLED ( bool pOnOrOff ) ;

	/*Follower LED helper functions*/
static bool LedsCheckFiltersForLEDFollower( void ) ;

static uint16 LedsGetLedFollowerRepeatTimeLeft( LEDPattern_t* pPattern) ;


static uint16 LedsGetLedFollowerStartDelay( void ) ;

static void LedsSetEnablePin ( bool pOnOrOff ) ;

static void ledsTurnOnAltLeds(uint8 On_LedA, uint8 Off_LedB);

#ifdef DEBUG_DIM
#define DIM_DEBUG(x) DEBUG(x)
#else
#define DIM_DEBUG(x) 
#endif

#define DIM_NUM_STEPS (0xf)
#define DIM_STEP_SIZE ((4096) / (DIM_NUM_STEPS + 1) ) 
#define DIM_PERIOD    (0x0)

    


static void PioSetLed ( uint16 pPIO , bool pOnOrOff ) ;

/****************************************************************************
NAME	
	PioSetLedPin

DESCRIPTION
    Fn to change set an LED attached to a PIO, a special LED pin , or a tricolour LED
    
RETURNS
	void
*/
void PioSetLedPin ( uint16 pPIO , bool pOnOrOff ) 
{
    LED_DEBUG(("LM : SetLed [%x][%x] \n", pPIO , pOnOrOff )) ;

    /*handle tricolour LEDS first */
	switch (pPIO)
	{		
		case (11):
		{		/*use the configured LED pair*/
			PioSetLed (theSink.theLEDTask->gTriColLeds.TriCol_a, pOnOrOff) ;
			PioSetLed (theSink.theLEDTask->gTriColLeds.TriCol_b, pOnOrOff) ;		
		}
		break ;
		case (12):
		{		/*use the configured LED pair*/
			PioSetLed (theSink.theLEDTask->gTriColLeds.TriCol_b, pOnOrOff) ;
			PioSetLed (theSink.theLEDTask->gTriColLeds.TriCol_c, pOnOrOff) ;		
		}
		break ;
		case (13) :
		{		/*use the configured LED pair*/
			PioSetLed (theSink.theLEDTask->gTriColLeds.TriCol_c, pOnOrOff) ;
			PioSetLed (theSink.theLEDTask->gTriColLeds.TriCol_a, pOnOrOff) ;	
		}
		break ;		
        
		default:
		{	
            /*a single LED pin to update*/
			PioSetLed (pPIO , pOnOrOff) ;
		}	
		break ;
	}
}	

/****************************************************************************
NAME	
	PioSetLed

DESCRIPTION
   Internal fn to change set an LED attached to a PIO or a special LED pin 
    
RETURNS
	void
*/
static void PioSetLed ( uint16 pPIO , bool pOnOrOff ) 
{	
    LEDActivity_t * gActiveLED = &theSink.theLEDTask->gActiveLEDS[pPIO];
    
   /* LED pins are special cases*/
    if ( pPIO == 14)        
    {
        if ( gActiveLED->DimTime > 0 ) /*if this is a dimming led / pattern*/ 
        {
            if (theSink.theLEDTask->gLED_0_STATE != pOnOrOff) /*if the request is to do the same as what we are doing then ignore*/
            {
                    /*set led to max or min depending on whether we think the led is on or off*/
                gActiveLED->DimState = (DIM_NUM_STEPS * !pOnOrOff) ; 
                gActiveLED->DimDir   = pOnOrOff ; /*1=go up , 0 = go down**/ 
                        
                LedConfigure(LED_0, LED_DUTY_CYCLE, (gActiveLED->DimState * (DIM_STEP_SIZE)));
                LedConfigure(LED_0, LED_PERIOD, DIM_PERIOD );
                
                DIM_DEBUG(("DIM: Set LED [%d][%x][%d]\n" ,pPIO ,gActiveLED->DimState ,gActiveLED->DimDir  )) ;
                LedConfigure(LED_0, LED_ENABLE, TRUE);
                /*send the first message*/
                MessageCancelAll ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ) ;                
                MessageSendLater ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ,0 ,gActiveLED->DimTime ) ;       
              
                theSink.theLEDTask->gLED_0_STATE = pOnOrOff ;
            }
        }
        else
        {              
            DIM_DEBUG(("DIM 0 N:[%d]\n" , pOnOrOff)) ;
		    LedConfigure(LED_0, LED_ENABLE, pOnOrOff ) ;
            LedConfigure(LED_0, LED_DUTY_CYCLE, (0xfff));
            LedConfigure(LED_0, LED_PERIOD, DIM_PERIOD );
            theSink.theLEDTask->gLED_0_STATE = pOnOrOff ;
        }
    }
    else if (pPIO == 15 )
    {
        if ( gActiveLED->DimTime > 0 ) /*if this is a dimming led / pattern*/ 
        {
            if (theSink.theLEDTask->gLED_1_STATE != pOnOrOff) /*if the request is to do the same as what we are doing then ignore*/
            {
                   /*set led to max or min depending on whether we think the led is on or off*/
                gActiveLED->DimState = (DIM_NUM_STEPS * !pOnOrOff) ; 
                gActiveLED->DimDir   = pOnOrOff ; /*1=go up , 0 = go down**/ 
                                    
                LedConfigure(LED_1, LED_DUTY_CYCLE, (gActiveLED->DimState * (DIM_STEP_SIZE)));
                LedConfigure(LED_1, LED_PERIOD, DIM_PERIOD );
                
                DIM_DEBUG(("DIM: Set LED [%d][%x][%d]\n" ,pPIO ,gActiveLED->DimState , gActiveLED->DimDir  )) ;
                LedConfigure(LED_1, LED_ENABLE, TRUE);
                   /*send the first message*/
                MessageCancelAll ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ) ;                
                MessageSendLater ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ,0 ,gActiveLED->DimTime ) ;

                theSink.theLEDTask->gLED_1_STATE = pOnOrOff ;                                  
            }
        }
        else
        {
            DIM_DEBUG(("DIM 1 N:[%d]\n" , pOnOrOff)) ;
            LedConfigure(LED_1, LED_ENABLE, pOnOrOff ) ;
            LedConfigure(LED_1, LED_DUTY_CYCLE, (0xfff));
            LedConfigure(LED_1, LED_PERIOD, DIM_PERIOD );
            theSink.theLEDTask->gLED_1_STATE = pOnOrOff ;
        }
    }
    else if (pPIO == 10 )
    {
        if ( gActiveLED->DimTime > 0 ) /*if this is a dimming led / pattern*/ 
        {
            if (theSink.theLEDTask->gLED_2_STATE != pOnOrOff) /*if the request is to do the same as what we are doing then ignore*/
            {
                   /*set led to max or min depending on whether we think the led is on or off*/
                gActiveLED->DimState = (DIM_NUM_STEPS * !pOnOrOff) ; 
                gActiveLED->DimDir   = pOnOrOff ; /*1=go up , 0 = go down**/ 
                                    
                LedConfigure(LED_2, LED_DUTY_CYCLE, (gActiveLED->DimState * (DIM_STEP_SIZE)));
                LedConfigure(LED_2, LED_PERIOD, DIM_PERIOD );
                
                DIM_DEBUG(("DIM: Set LED [%d][%x][%d]\n" ,pPIO ,gActiveLED->DimState , gActiveLED->DimDir  )) ;
                LedConfigure(LED_2, LED_ENABLE, TRUE);
                   /*send the first message*/
                MessageCancelAll ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ) ;                
                MessageSendLater ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ,0 ,gActiveLED->DimTime ) ;

                theSink.theLEDTask->gLED_2_STATE = pOnOrOff ;
            }
        }
        else
        {
            DIM_DEBUG(("DIM 2 N:[%d]\n" , pOnOrOff)) ;
            LedConfigure(LED_2, LED_ENABLE, pOnOrOff ) ;
            LedConfigure(LED_2, LED_DUTY_CYCLE, (0xfff));
            LedConfigure(LED_2, LED_PERIOD, DIM_PERIOD );
            theSink.theLEDTask->gLED_2_STATE = pOnOrOff ;
        }
    }
    else
    {
        PioSetPio (pPIO , pio_drive, pOnOrOff) ;
    }
}


/****************************************************************************
NAME	
	PioSetDimState  
	
DESCRIPTION
    Update funtion for a led that is currently dimming
    
RETURNS
	void
*/
void PioSetDimState ( uint16 pPIO )
{
    uint16 lDim = 0x0000 ;
    LEDActivity_t *gActiveLED = &theSink.theLEDTask->gActiveLEDS[pPIO];

    if (gActiveLED->DimDir && gActiveLED->DimState >= DIM_NUM_STEPS )
    {      
        lDim = 0xFFF;
        DIM_DEBUG(("DIM:+[F] [ON]\n" ));
    }
    else if ( !gActiveLED->DimDir && gActiveLED->DimState == 0x0 )
    {
        lDim = 0 ;
        DIM_DEBUG(("DIM:-[0] [OFF]\n" ));
    }
    else
    {
        if(gActiveLED->DimDir)
            gActiveLED->DimState++ ;
        else
            gActiveLED->DimState-- ;
        
        DIM_DEBUG(("DIM:Direction [%x], DimState:[%x], DimTime:[%x]\n", gActiveLED->DimDir, gActiveLED->DimState, gActiveLED->DimTime));
        
        lDim = (gActiveLED->DimState * (DIM_STEP_SIZE) ) ;
        
        MessageCancelAll ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) ) ;                
        MessageSendLater ( &theSink.theLEDTask->task, (DIM_MSG_BASE + pPIO) , 0 , gActiveLED->DimTime ) ;    
    }    
    
    if (pPIO == 14)
    {
        LedConfigure(LED_0, LED_DUTY_CYCLE, lDim);
        LedConfigure(LED_0, LED_PERIOD, DIM_PERIOD );  
        LedConfigure(LED_0, LED_ENABLE, TRUE ) ;
    }
    else if (pPIO ==15)
    {        
        LedConfigure(LED_1, LED_DUTY_CYCLE, lDim);
        LedConfigure(LED_1, LED_PERIOD, DIM_PERIOD );  
        LedConfigure(LED_1, LED_ENABLE, TRUE ) ;
    }
    else if (pPIO ==10)
    {        
        LedConfigure(LED_2, LED_DUTY_CYCLE, lDim);
        LedConfigure(LED_2, LED_PERIOD, DIM_PERIOD );  
        LedConfigure(LED_2, LED_ENABLE, TRUE ) ;
    }
    
}

/****************************************************************************
NAME 
 LedsInit

DESCRIPTION
 	Initialise the Leds data
RETURNS
 void
    
*/
void LedsInit ( void ) 
{
        /*Set the callback handler for the task*/
    theSink.theLEDTask->task.handler = LedsMessageHandler ;
    
    theSink.theLEDTask->gCurrentlyIndicatingEvent = FALSE ;
    	/*set the tricolour leds to known values*/
    theSink.theLEDTask->gTriColLeds.TriCol_a = 0 ;
    theSink.theLEDTask->gTriColLeds.TriCol_b = 0 ;
    theSink.theLEDTask->gTriColLeds.TriCol_c = 0 ;
    
    theSink.theLEDTask->gFollowing = FALSE ; 
}

     
/****************************************************************************
NAME 
 LedsCheckForFilter

DESCRIPTION
 This function checksif a filter has been configured for the given event, 
    if it has then activates / deactivates the filter 
    
    Regardless of whether a filter has been activated or not, the event is signalled as 
    completed as we have now deaklt with it (only checked for a filter if a pattern was not
    associated.

RETURNS
 void
    
*/       
void LedsCheckForFilter ( sinkEvents_t pEvent ) 
{
    uint16 lFilterIndex = 0 ;
    
    for (lFilterIndex = 0 ; lFilterIndex < theSink.theLEDTask->gLMNumFiltersUsed ; lFilterIndex ++ )
    { 
        LEDFilter_t *lEventFilter = &(theSink.theLEDTask->gEventFilters [ lFilterIndex ]);
        
        if((uint16)(lEventFilter->Event) == pEvent && lEventFilter->FilterType != DISABLED)
        {
            if (lEventFilter->FilterType != CANCEL)
            {
                /* Check filter isn't already enabled */
                if (!LedsIsFilterEnabled(lFilterIndex))
                {
                    /* Enable filter */
                    LedsEnableFilter (lFilterIndex , TRUE) ;
            
                    /* If it is an overide fLED filter and the currently playing pattern is OFF then turn on the overide led immediately*/
                    if ( lEventFilter->FilterType == OVERRIDE)
                    {                        
                        uint16 lOverideLEDIndex = lEventFilter->OverideLED ;                    
                        
                        /* this should only happen if the led in question is currently off*/
                        if ( theSink.theLEDTask->gActiveLEDS[lOverideLEDIndex].OnOrOff == LED_OFF)
                        {
                             LED_DEBUG(("LED: FilEnable Turn on[%d][%d] \n",lFilterIndex + 1 , lOverideLEDIndex  )) ;
                             PioSetLedPin ( lOverideLEDIndex , LED_ON) ;
                        }
                    }
                }
            }
            else
            {
                 uint16 lFilterToCancel = lEventFilter->FilterToCancel ;
                /*disable the according filter*/
                 if ( lFilterToCancel != 0 )
                 {
                     uint16 lFilterToCancelIndex = lFilterToCancel - 1 ;
                     LEDFilter_t *lEventFilter1  = &(theSink.theLEDTask->gEventFilters [ lFilterToCancelIndex ]);
                     uint16 lOverideLEDIndex     = lEventFilter1->OverideLED ;
                    
                     LED_DEBUG(("LED: FilCancel[%d][%d] [%d]\n",lFilterIndex + 1 , lFilterToCancel , lFilterToCancelIndex )) ;
                     
                        /*lFilter To cancel = 1-n, LedsEbnable filter requires 0-n */
                     LedsEnableFilter (lFilterToCancelIndex , FALSE ) ;
                     
                     if ( theSink.theLEDTask->gActiveLEDS[lOverideLEDIndex].OnOrOff == LED_OFF)
                     {   /*  LedsHandleOverideLED ( theSink.theLEDTask , LED_OFF) ;*/
                         if ( lEventFilter1->FilterType == OVERRIDE)
                         {
                             LED_DEBUG(("LED: FilCancel Turn off[%d][%d] [%d]\n",lFilterIndex + 1 , lFilterToCancel , lFilterToCancelIndex )) ;
	          	             PioSetLedPin ( lOverideLEDIndex, LED_OFF) ;                
                             
                             /* it is possible for the cancel filter to turn off leds used in a solid led
                                state indication such as a solid blue pairing indication, should the charger be
                                removed and then reinserted the solid blue state is turned off, this call will reset
                                the state indication and turn it back on again */
                             LEDManagerIndicateState ( stateManagerGetState () ) ;                       

                         }    
                     }                           
                 }
                 else
                 {
                    LED_DEBUG(("LED: Fil !\n")) ;
                 }
            }
            LED_DEBUG(("LM : Filter Found[%d]A[%x] [%d]\n", lFilterIndex + 1,  pEvent , theSink.theLEDTask->gEventFilters[ lFilterIndex ].IsFilterActive )) ;
       }      
    }
}


/****************************************************************************
NAME 
    LedsEnableFilterOverrides

DESCRIPTION
    Enable or disable filters overriding LEDs. This will not change which 
    filters are active, it will just turn off any LEDs the filters are 
    forcing on.
    
RETURNS
    void    
*/
void LedsEnableFilterOverrides(bool enable)
{
    uint16 lFilterIndex;
    /* Run through all filters */
    for (lFilterIndex = 0 ; lFilterIndex < theSink.theLEDTask->gLMNumFiltersUsed ; lFilterIndex ++ )
    {
        LEDFilter_t *lEventFilter = &(theSink.theLEDTask->gEventFilters [ lFilterIndex ]);
        /* If filter is overriding an LED turn it off */
        if (LedsIsFilterEnabled(lFilterIndex) && (lEventFilter->FilterType == OVERRIDE))
            PioSetLedPin(lEventFilter->OverideLED, (enable ? LED_ON : LED_OFF));
    }
    /* Restore state (ensures we haven't disabled any LEDs we shouldn't) */
    LEDManagerIndicateState ( stateManagerGetState () ) ;  
}


/****************************************************************************
NAME 
    ledsIndicateLedsPattern

DESCRIPTION
 	Given the indication type and leds pattern, Play the LED Pattern
RETURNS
    void
*/
void ledsIndicateLedsPattern(LEDPattern_t *lPattern, uint8 lIndex, IndicationType_t Ind_type)
{
    uint8 lPrimaryLED     = lPattern->LED_A;
    uint8 lSecondaryLED   = lPattern->LED_B;

    #ifdef DEBUG_LM
    	LMPrintPattern( lPattern ) ;
    #endif
        
    if(Ind_type == IT_EventIndication)
    {
        /*if the PIO we want to use is currently indicating an event then do interrupt the event*/
        MessageCancelAll (&theSink.theLEDTask->task, lPrimaryLED ) ;
        MessageCancelAll (&theSink.theLEDTask->task, lSecondaryLED ) ;
    }
        
    /*cancel all led state indications*/
    /*Find the LEDS that are set to indicate states and Cancel the messages,
      -do not want to indicate more than one state at a time */
    LedsIndicateNoState ( ) ;
    
    /*now set up and start the event indication*/
    LedsSetLedActivity ( &theSink.theLEDTask->gActiveLEDS[lPrimaryLED] , Ind_type , lIndex  , lPattern->DimTime ) ;
    /*Set the Alternative LED up with the same info*/
    LedsSetLedActivity ( &theSink.theLEDTask->gActiveLEDS[lSecondaryLED] , Ind_type , lIndex , lPattern->DimTime ) ;

    /* - need to set the LEDS to a known state before starting the pattern*/
    LedsTurnOffLEDPair (lPattern , TRUE ) ;
   
    /*Handle permanent output leds*/
    if ( lPattern->NumFlashes == 0 )
    {
        /*set the pins on or off as required*/
        if ( LED_SCALE_ON_OFF_TIME(lPattern->OnTime) > 0 )
        {
            LED_DEBUG(("LM :ST PIO_ON\n")) ;
            LedsTurnOnLEDPair ( lPattern , &theSink.theLEDTask->gActiveLEDS[lPrimaryLED]) ;
        }
        else if ( LED_SCALE_ON_OFF_TIME(lPattern->OffTime) > 0 )
        {
            LED_DEBUG(("LM :ST PIO_OFF\n")) ;
            LedsTurnOffLEDPair ( lPattern , TRUE) ;
            
            LedsSendEventComplete ( lPattern->StateOrEvent, TRUE ) ;
            /*If we are turning a pin off the revert to state indication*/
            LedsEventComplete ( &theSink.theLEDTask->gActiveLEDS[lPrimaryLED] , &theSink.theLEDTask->gActiveLEDS[lSecondaryLED] ) ;
        }   
    }
    else
    {
        if(Ind_type == IT_EventIndication)
        {
            MessageSend (&theSink.theLEDTask->task, lPrimaryLED, 0) ;
            theSink.theLEDTask->gCurrentlyIndicatingEvent = TRUE ;
        }
        else
        {
            /*send the first message for this state LED indication*/ 
            MessageSendLater (&theSink.theLEDTask->task , lPrimaryLED, 0 , LEDS_STATE_START_DELAY_MS ) ;
        }
    }
}

/****************************************************************************
NAME 
 LedsIndicateNoState

DESCRIPTION
	remove any state indications as there are currently none to be displayed
RETURNS
 void
    
*/
void LedsIndicateNoState ( void  )  
{
     /*Find the LEDS that are set to indicate states and Cancel the messages,
    -do not want to indicate more than one state at a time*/
    uint16 lLoop = 0;

    for ( lLoop = 0 ; lLoop < SINK_NUM_LEDS ; lLoop ++ )
    {
        LEDActivity_t *lActiveLeds = &theSink.theLEDTask->gActiveLEDS[lLoop];
        
        if (lActiveLeds->Type == IT_StateIndication)
        {
            MessageCancelAll ( &theSink.theLEDTask->task, lLoop ) ; 
            lActiveLeds->Type =  IT_Undefined ;
            
            LED_DEBUG(("LED: CancelStateInd[%x]\n" , lLoop)) ;
            
            LedsTurnOffLEDPair ( &theSink.theLEDTask->gStatePatterns[lActiveLeds->Index] ,TRUE) ;                    
        }
    }
}

/****************************************************************************
NAME 
 LedActiveFiltersCanOverideDisable

DESCRIPTION
    Check if active filters disable the global LED disable flag.
RETURNS 
 	bool
*/
bool LedActiveFiltersCanOverideDisable( void )
{
    uint16 lFilterIndex ;
    
    for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
    {
        if ( LedsIsFilterEnabled(lFilterIndex) )
        {
            /* check if this filter overides LED disable flag */
            if ( theSink.theLEDTask->gEventFilters[lFilterIndex].OverideDisable)
                return TRUE;
        }
    }
    return FALSE;
}

/****************************************************************************
NAME 
 LEDManagerMessageHandler

DESCRIPTION
 The main message handler for the LED task. Controls the PIO in question, then 
    queues a message back to itself for the next LED update.

RETURNS
 void
    
*/
static void LedsMessageHandler( Task task, MessageId id, Message message )
{  
    bool lOldState = LED_OFF ;
    uint16 lTime   = 0 ;
    LEDColour_t lColour ;    
    
    LEDActivity_t * lLED   = &theSink.theLEDTask->gActiveLEDS[id] ;
    LEDPattern_t *  lPattern = NULL ;
    bool lPatternComplete = FALSE ;
        
    if (id < DIM_MSG_BASE )
    {
        
        /*which pattern are we currently indicating for this LED pair*/
        if ( lLED->Type == IT_StateIndication)
        {
            /* this is a STATE indication */        
            lPattern = &theSink.theLEDTask->gStatePatterns[ lLED->Index] ;
        }
        else
        {   /*is an event indication*/
            lPattern = &theSink.theLEDTask->pEventPatterns [ lLED->Index ] ;
        }
        
        /* get which of the LEDs we are interested in for the pattern we are dealing with */
        lColour = LedsGetPatternColour ( lPattern ) ;
         
        /*get the state of the LED we are dealing with*/
        lOldState = theSink.theLEDTask->gActiveLEDS [ lPattern->LED_A ].OnOrOff ;
     
        LED_DEBUG(("LM : LED[%d] [%d] f[%d]of[%d]\n", id ,lOldState , lLED->NumFlashesComplete , lPattern->NumFlashes )) ;
             
        /*  is LED currently off? */
        if (lOldState == LED_OFF)
        {
            /* led is off so start the new pattern by turning LED on */
            lTime = LED_SCALE_ON_OFF_TIME(lPattern->OnTime) ;
            LED_DEBUG(("LED: set ON time [%x]\n",lTime)) ;   
                
            /*Increment the number of flashes*/
            lLED->NumFlashesComplete++ ;
                  
            LED_DEBUG(("LED: Pair On\n")) ;
            LedsTurnOnLEDPair ( lPattern , lLED ) ;
            
        }
        else
        {   
            /*restart the pattern if we have palayed all of the required flashes*/
            if ( lLED->NumFlashesComplete >= lPattern->NumFlashes )
            {
                lTime = LED_SCALE_REPEAT_TIME(lPattern->RepeatTime) ;
                lLED->NumFlashesComplete = 0 ;       
                    /*inc the Num times the pattern has been played*/
                lLED->NumRepeatsComplete ++ ;
                LED_DEBUG(("LED: Pat Rpt[%d] [%d][%d]\n",lTime, lLED->NumRepeatsComplete , lPattern->TimeOut)) ;
          
                /*if a single pattern has completed*/
                if ( LED_SCALE_REPEAT_TIME(lPattern->RepeatTime) == 0 ) 
                {
                    LED_DEBUG(("LED: PC: Rpt\n")) ;
                    lPatternComplete = TRUE ;
                }
                   /*a pattern timeout has occured*/
                if ( ( lPattern->TimeOut !=0 )  && ( lLED->NumRepeatsComplete >= lPattern->TimeOut) )
                {
                    lPatternComplete = TRUE ;
                    LED_DEBUG(("LED: PC: Rpt b\n")) ;
                }              
                
                /*if we have reached the end of the pattern and are using a follower then revert to the orig pattern*/
                if (theSink.theLEDTask->gFollowing)
                {
                    theSink.theLEDTask->gFollowing = FALSE ;
                    lTime = LedsGetLedFollowerRepeatTimeLeft( lPattern ) ;    
                }
                else
                {
                    /*do we have a led follower filter and are we indicating a state, if so use these parameters*/
                    if (lLED->Type == IT_StateIndication)
                    {
                        if( LedsCheckFiltersForLEDFollower( ) )
                        {
                            lTime = LedsGetLedFollowerStartDelay( ) ;       
                            theSink.theLEDTask->gFollowing = TRUE ;
                        }
                    }    
                 }            
            } 
            else /*otherwise set up for the next flash*/
            {
                lTime = LED_SCALE_ON_OFF_TIME(lPattern->OffTime) ;
                LED_DEBUG(("LED: set OFF time [%x]\n",lTime)) ;   
        	} 
            
        						
    		lColour = LedsGetPatternColour ( lPattern ) ;
				
			if ( lColour != LED_COL_LED_ALT )
			{
                /*turn off both LEDS*/
                LED_DEBUG(("LED: Pair OFF\n")) ;   

                if ( (lTime == 0 ) && ( lPatternComplete == FALSE ) )
   		        {
    	            /*ie we are switching off for 0 time - do not use the overide led as this results in a tiny blip*/
            	    LedsTurnOffLEDPair ( lPattern , FALSE) ;
        	    }
   		        else
   	    	    {
            	    LedsTurnOffLEDPair ( lPattern , TRUE) ;
            	}
			}
			else
			{
				/*signal that we are off even though we are not*/
			    theSink.theLEDTask->gActiveLEDS [ lPattern->LED_A ].OnOrOff  = FALSE ;                     
			}
		}
      
       
        /*handle the completion of the pattern or send the next update message*/
        if (lPatternComplete)
        {
            LED_DEBUG(("LM : PatternComplete [%x][%x]  [%x][%x]\n" , theSink.theLEDTask->gActiveLEDS[lPattern->LED_B].Index, lLED->Index , theSink.theLEDTask->gActiveLEDS[lPattern->LED_B].Type , lLED->Type    )) ;
            /*set the type of indication for both LEDs as undefined as we are now indicating nothing*/
            if ( theSink.theLEDTask->gActiveLEDS[id].Type == IT_EventIndication )
            {
                      /*signal the completion of an event*/
                LedsSendEventComplete ( lPattern->StateOrEvent, TRUE ) ;
                    /*now complete the event, and indicate a new state if required*/        
                LedsEventComplete ( lLED , &theSink.theLEDTask->gActiveLEDS[lPattern->LED_B] ) ;
            }  
            else if (theSink.theLEDTask->gActiveLEDS[id].Type == IT_StateIndication )
            {
                /*then we have completed a state indication and the led pattern is now off*/    
                /*Indicate that we are now with LEDS disabled*/
               theSink.theLEDTask->gLEDSStateTimeout = TRUE ;
            }
            
            /* ensure leds are turned off when pattern completes as when using an alternating pattern
               leds are now left on to provide a better smoother transistion between colours */
            if ( lColour == LED_COL_LED_ALT )
            {
                LedsTurnOffLEDPair ( lPattern , TRUE) ;
            }
        }
        else
        {   
            /*apply the filter in there is one  and schedule the next message to handle for this led pair*/
            lTime = LedsApplyFilterToTime ( lTime ) ;
            MessageSendLater (&theSink.theLEDTask->task , id , 0 , lTime ) ;
            LED_DEBUG(("LM : PatternNotComplete  Time=[%x] [%x][%x]  [%x][%x]\n" ,lTime, theSink.theLEDTask->gActiveLEDS[lPattern->LED_B].Index, lLED->Index , theSink.theLEDTask->gActiveLEDS[lPattern->LED_B].Type , lLED->Type    )) ;
        } 
        
    }
    else
    {
        /*DIMMING LED Update message */       
        PioSetDimState ( (id - DIM_MSG_BASE) );
    }
}


/****************************************************************************
NAME 
 LedsTurnOnAltLeds

DESCRIPTION
    Fn to turn on the LEDs with Alt LED colour pattern
    
RETURNS
 void
*/
static void ledsTurnOnAltLeds(uint8 On_LedA, uint8 Off_LedB)
{
    uint8 TriA = theSink.theLEDTask->gTriColLeds.TriCol_a;
    uint8 TriB = theSink.theLEDTask->gTriColLeds.TriCol_b;
    uint8 TriC = theSink.theLEDTask->gTriColLeds.TriCol_c;
    
    switch (Off_LedB)  /*if a is a tri colour, then do not turn off the led == b*/
    {
		case (11):
			if (On_LedA != TriA)
				PioSetLedPin ( TriA, LED_OFF) ;

			if (On_LedA != TriB)
				PioSetLedPin ( TriB, LED_OFF) ;						
		break ;					
		case(12):
			if (On_LedA != TriB)
				PioSetLedPin ( TriB, LED_OFF) ;
						
			if (On_LedA != TriC)
				PioSetLedPin ( TriC, LED_OFF) ;
		break ;
		case(13):
			if (On_LedA != TriC)
				PioSetLedPin ( TriC, LED_OFF) ;
						
			if (On_LedA != TriA)								
				PioSetLedPin ( TriA, LED_OFF) ;
		break ;
		default:
			/*if b is a tricolor and one of b == a then dont turn off a */	
			switch ( On_LedA )
			{
				case(11):
					if  ( (TriA != Off_LedB) && (TriB != Off_LedB) )								
                        PioSetLedPin (  Off_LedB , LED_OFF )  ;
				break ;
				case(12):
					if  ( (TriB != Off_LedB) && (TriC != Off_LedB) )								
						PioSetLedPin (  Off_LedB , LED_OFF )  ;
				break ;
				case(13):
					if  ( (TriC != Off_LedB) && (TriA != Off_LedB) )								
						PioSetLedPin (  Off_LedB , LED_OFF )  ;
				break ;
				default:
						PioSetLedPin (  Off_LedB , LED_OFF )  ;                               
                break ;
			}					
         break ;						
	}
				
	/*now turn the other LED on*/
	PioSetLedPin (  On_LedA , LED_ON )  ;                
}


/****************************************************************************
NAME 
 LMTurnOnLEDPair

DESCRIPTION
    Fn to turn on the LED associated with the pattern / LEDs depending upon the 
    colour 
    
RETURNS
 void
*/
static void LedsTurnOnLEDPair ( LEDPattern_t * pPattern , LEDActivity_t * pLED )
{
    LEDColour_t lColour = LedsGetPatternColour ( pPattern ) ;   
    
    /* to prevent excessive stack usage when compiled in native mode only perform one read and convert of these
       4 bit parameters */
    uint8 LedA = pPattern->LED_A; 
    uint8 LedB = pPattern->LED_B; 
    
    LED_DEBUG(("LM : TurnOnPair  " )) ;
    
    if (theSink.theLEDTask->gFollowing )
    {	 /*turn of the pair of leds (and dont use an overide LED */
        
        /* obtain the PIO to drive */
        uint16 lLED = theSink.theLEDTask->gFollowPin; 
                
        LedsTurnOffLEDPair ( pPattern , FALSE) ;
        
        /* check to ensure it was possible to retrieve PIO, the filter may have been cancelled */
        if(lLED <= SINK_NUM_LEDS)
        {
            /* set the LED specified in the follower filter */
            PioSetLedPin ( lLED , LED_ON );
        }
    }
    else
    {/*we are not following*/
            /*Turn on the LED enable pin*/    
        LedsSetEnablePin ( LED_ON )  ;

        switch (lColour )
        {
        case LED_COL_LED_A:
    
            LED_DEBUG(("LED: A ON[%x][%x]\n", LedA , LedB)) ;            
            if (LedA != LedB)
            {
                if(!isOverideFilterActive(LedB))
                {
                    PioSetLedPin ( LedB , LED_OFF )  ;
                }
            }
            PioSetLedPin ( LedA , LED_ON )  ;
        
        break;
        case LED_COL_LED_B:
    
            LED_DEBUG(("LED: B ON[%x][%x]\n", LedA , LedB)) ;
            if (LedA != LedB)
            {
                if(!isOverideFilterActive( LedA))
                {
                    PioSetLedPin ( LedA , LED_OFF )  ;
                }
            }
            PioSetLedPin ( LedB , LED_ON )  ;
            
        break;
        case LED_COL_LED_ALT:
                   
            if (pLED->NumFlashesComplete % 2 )
            {
                LED_DEBUG(("LED: A ALT On[%x],Off[%x]\n", LedB , LedA)) ;
                ledsTurnOnAltLeds(LedB, LedA);
            }
            else
            {
                LED_DEBUG(("LED: B ALT On[%x],Off[%x]\n", LedA , LedB)) ;
                ledsTurnOnAltLeds(LedA, LedB);
            }        
        break;
        case LED_COL_LED_BOTH:
    
            LED_DEBUG(("LED: AB Both[%x][%x]\n", LedA , LedB)) ;
            PioSetLedPin (  LedA , LED_ON )  ;
            PioSetLedPin (  LedB , LED_ON )  ;
        break;
        default:
            LED_DEBUG(("LM : ?Col\n")) ;
        break;
        }
    }
 
    /* only process the overide filter if not an alternating pattern or a permanently on pattern otherwise
       led will be turned off */
    if((lColour != LED_COL_LED_BOTH)&&(lColour != LED_COL_LED_ALT)&&(pPattern->NumFlashes))
    {
        /*handle an overide LED if there is one will also dealit is different to one of the pattern LEDS)*/
        if((!isOverideFilterActive(LedA)) || (!isOverideFilterActive(LedB)) )
        {
            LED_DEBUG(("LM : TurnOnPair - Handle Overide\n" )) ;
            LedsHandleOverideLED (   LED_OFF ) ;
        }
    }
    
    pLED->OnOrOff = TRUE ;
        
}


/****************************************************************************
NAME 
 LMTurnOffLEDPair

DESCRIPTION
    Fn to turn OFF the LEDs associated with the pattern
    
RETURNS
 void
*/
static void LedsTurnOffLEDPair ( LEDPattern_t * pPattern  , bool pUseOveride ) 
{
    LED_DEBUG(("LM : TurnOffPair \n" )) ;

    /*turn off both LEDS*/
    if(!isOverideFilterActive( pPattern->LED_A))
    {
        LED_DEBUG(("LM : TurnOffPair - OVR A%x \n", pPattern->LED_A )) ;
        PioSetLedPin ( pPattern->LED_A , LED_OFF )  ;
    }
    
    if(!isOverideFilterActive( pPattern->LED_B))
    {
        LED_DEBUG(("LM : TurnOffPair - OVR B %x \n", pPattern->LED_B )) ;
        PioSetLedPin ( pPattern->LED_B , LED_OFF )  ;
    }
        /*handle an overide LED if we want to use one*/
    if ( pUseOveride )
    {
        LedsHandleOverideLED ( LED_ON ) ;
    }
    theSink.theLEDTask->gActiveLEDS [ pPattern->LED_A ].OnOrOff  = FALSE ;        
    
        /*Turn off the LED enable pin*/  

    LedsSetEnablePin ( LED_OFF )  ;
}


/****************************************************************************
NAME 
 LedsHandleOverideLED

DESCRIPTION
    Enables / diables any overide LEDS if there are some    
RETURNS
*/
static void LedsHandleOverideLED ( bool pOnOrOff ) 
{   
    uint16 lFilterIndex = 0 ;
    
    for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
    {
        if ( LedsIsFilterEnabled(lFilterIndex) )
        {
             if ( theSink.theLEDTask->gEventFilters[lFilterIndex].FilterType == OVERRIDE)
             {
                    /*Overide the Off LED with the Overide LED*/
                    LED_DEBUG(("LM: LEDOveride [%d] [%d]\n" , theSink.theLEDTask->gEventFilters[lFilterIndex].OverideLED , pOnOrOff)) ;    
                    PioSetLedPin ( theSink.theLEDTask->gEventFilters[lFilterIndex].OverideLED , pOnOrOff) ;   
             }    
        }
    }  
}


/****************************************************************************
NAME 
 LMGetPatternColour

DESCRIPTION
    Fn to determine the LEDColour_t of the LED pair we are currently playing
    takes into account whether or not a filter is currently active
    
RETURNS
 LEDColour_t
*/
static LEDColour_t LedsGetPatternColour ( const  LEDPattern_t * pPattern )
{
    uint16 lFilterIndex = 0 ;
        /*sort out the colour of the LED we are interested in*/
    LEDColour_t lColour = pPattern->Colour ;
   
    for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
    {
        if ( LedsIsFilterEnabled(lFilterIndex) )
        {
            if ( theSink.theLEDTask->gEventFilters[lFilterIndex].Colour != LED_COL_EITHER )
            {
                    /*Overide the Off LED with the Overide LED*/
                lColour = theSink.theLEDTask->gEventFilters[lFilterIndex].Colour;   
            } 
        }
    }
    return lColour ;
}


/****************************************************************************
NAME 
 LMApplyFilterToTime

DESCRIPTION
    Fn to change the callback time if a filter has been applied - if no filter is applied
    just returns the original time
    
RETURNS
 uint16 the callback time
*/
static uint16 LedsApplyFilterToTime ( uint16 pTime ) 
{
    uint16 lFilterIndex = 0 ;
    uint16 lTime = pTime ; 
    
    for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
    {
        if ( LedsIsFilterEnabled(lFilterIndex) )
        {
            LEDFilter_t *lEventFilter = &(theSink.theLEDTask->gEventFilters[lFilterIndex]);
            
            if ( lEventFilter->Speed )
            {
                if (lEventFilter->SpeedAction == SPEED_MULTIPLY)
                {
                    LED_DEBUG(("LED: FIL_MULT[%d]\n" , lEventFilter->Speed )) ;
                    lTime *= lEventFilter->Speed ;
                }
                else /*we want to divide*/
                {
                    if (lTime)
                    {
                       LED_DEBUG(("LED: FIL_DIV[%d]\n" , lEventFilter->Speed )) ;
                      lTime /= lEventFilter->Speed ;
                    }
                }
            }
        }
    }

    return lTime ;
}




/****************************************************************************
NAME 
 LEDManagerSendEventComplete

DESCRIPTION
    Sends a message to the main task thread to say that an event indication has been completed
    
    
RETURNS
 void
*/
void LedsSendEventComplete ( sinkEvents_t pEvent , bool pPatternCompleted )
{
    if ( (pEvent > EVENTS_MESSAGE_BASE) && (pEvent <= EVENTS_LAST_EVENT ) )
    {   
        LMEndMessage_t * lEventMessage = mallocPanic ( sizeof(LMEndMessage_t) ) ;
         
        /*need to add the message containing the EventType here*/
        lEventMessage->Event = pEvent  ;
        lEventMessage->PatternCompleted =  pPatternCompleted ;
                        
        LED_DEBUG(("LM : lEvCmp[%x] [%x]\n",lEventMessage->Event , lEventMessage->PatternCompleted )) ;
            
        MessageSend ( &theSink.task , EventSysLEDEventComplete , lEventMessage ) ;
    }
}

/****************************************************************************
NAME 
 LedsEventComplete

DESCRIPTION
    signal that a given event indicatio has completed
RETURNS
 	void
*/
static void LedsEventComplete ( LEDActivity_t * pPrimaryLed , LEDActivity_t * pSecondaryLed ) 
{       
    pPrimaryLed->Type = IT_Undefined ;
    
    pSecondaryLed->Type = IT_Undefined ;
    
    theSink.theLEDTask->gCurrentlyIndicatingEvent = FALSE ;
}        
/****************************************************************************
NAME 
 LedsEnableFilter

DESCRIPTION
    enable / disable a given filter ID
RETURNS
 	void
*/
static void LedsEnableFilter ( uint16 pFilter , bool pEnable)
{
    uint32 lOldMask = LED_GETACTIVEFILTERS() ;
    
    if (pEnable)
    {
        /*to set*/
        LED_SETACTIVEFILTERS((lOldMask | ( (uint32)0x1 << pFilter )));
        LED_DEBUG(("LED: EnF [%lx] [%lx] [%x]\n", lOldMask , LED_GETACTIVEFILTERS() , pFilter));
    }
    else
    {
        /*to unset*/
        LED_SETACTIVEFILTERS(lOldMask & ~(  (uint32)0x1 << pFilter ));
        LED_DEBUG(("LED: DisF [%lx] [%lx] [%x]\n", lOldMask , LED_GETACTIVEFILTERS() , pFilter));
    }
    
    /* Check if we should indicate state */
    if ((theSink.theLEDTask->gEventFilters[pFilter].OverideDisable) && (lOldMask != LED_GETACTIVEFILTERS()))
        LEDManagerIndicateState ( stateManagerGetState () ) ;                          
}

/****************************************************************************
NAME 
 LedsIsFilterEnabled

DESCRIPTION
    determine if a filter is enabled
RETURNS
 	bool - enabled or not
*/
static bool LedsIsFilterEnabled ( uint16 pFilter )
{
    bool lResult = FALSE ;
    
    if ( LED_GETACTIVEFILTERS() & ( 0x1UL << pFilter ) )
    {
        lResult = TRUE ;
    }
    
    return lResult ;
}

/****************************************************************************
NAME 
 LedsSetLedActivity

DESCRIPTION
    Sets a Led Activity to a known state
RETURNS
 void
*/
void LedsSetLedActivity ( LEDActivity_t * pLed , IndicationType_t pType , uint16 pIndex , uint16 pDimTime)
{
    
    
    pLed->Type               = pType ;
    pLed->Index              = pIndex ;
    pLed->DimTime            = pDimTime ;   
    LED_DEBUG(("LED[%d]\n" , pDimTime)) ; 
  
}
/****************************************************************************
NAME 
	LedsCheckFiltersForLEDFollower
DESCRIPTION
    determine if a follower is currently active
RETURNS
 	bool - active or not
*/
static bool LedsCheckFiltersForLEDFollower( void )
{
    uint16 lResult = FALSE ;    
    uint16 lFilterIndex = 0 ;
    
    for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
    {
        if ( LedsIsFilterEnabled(lFilterIndex) )
        {
            LEDFilter_t *lEventFilter = &(theSink.theLEDTask->gEventFilters[lFilterIndex]);
                
            /*if this filter defines a lefd follower*/
            if ( lEventFilter->FilterType == FOLLOW)
            {
                theSink.theLEDTask->gFollowPin = lEventFilter->OverideLED;
                lResult = TRUE ;
            }    
        }
    }
    return lResult ;
}
/****************************************************************************
NAME 
	LedsGetLedFollowerRepeatTimeLeft
DESCRIPTION
    calculate the new repeat time based upon the follower led delay and the normal repeat time
RETURNS
 	uint16 - updated repeat time to use
*/
static uint16 LedsGetLedFollowerRepeatTimeLeft( LEDPattern_t * pPattern) 
{
    uint16 lTime = LED_SCALE_REPEAT_TIME(pPattern->RepeatTime) ;
    uint16 lPatternTime = ( ( LED_SCALE_ON_OFF_TIME(pPattern->OnTime)  *  pPattern->NumFlashes) + 
                            ( LED_SCALE_ON_OFF_TIME( pPattern->OffTime) * (pPattern->NumFlashes - 1 ) )   +
                            ( LedsGetLedFollowerStartDelay() ) ) ;
                            
    if(lPatternTime < lTime )
    {
        lTime = lTime - lPatternTime ;
        LED_DEBUG(("LED: FOllower Rpt [%d] = [%d] - [%d]\n " , lTime , LED_SCALE_REPEAT_TIME(pPattern->RepeatTime) , lPatternTime)) ;
    }
    
    return lTime ;        
}
/****************************************************************************
NAME 
	LedsGetLedFollowerStartDelay
DESCRIPTION
    get the delay associated with a follower led pin
RETURNS
 	uint16 - delay to use for the follower
*/             
static uint16 LedsGetLedFollowerStartDelay( void )
{
    uint16 lDelay = 0 ;
    uint16 lFilterIndex =0 ;    
    
    for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
    {
        if ( LedsIsFilterEnabled(lFilterIndex) )
        {
                /*if this filter defines a lefd follower*/
            if ( theSink.theLEDTask->gEventFilters[lFilterIndex].FilterType == FOLLOW)
            {		 /*the led to use to follow with*/
                LED_DEBUG(("LM: LEDFollower Led[%d] Delay[%d]\n" , theSink.theLEDTask->gEventFilters[lFilterIndex].OverideLED ,
                                                                   FILTER_SCALE_DELAY_TIME(theSink.theLEDTask->gEventFilters[lFilterIndex].FollowerLEDDelay))) ;    
                lDelay = FILTER_SCALE_DELAY_TIME(theSink.theLEDTask->gEventFilters[lFilterIndex].FollowerLEDDelay) * 50 ;
            }    
        }
    }

    return lDelay ;
}

/****************************************************************************
NAME 
 LedsResetAllLeds

DESCRIPTION
    resets all led pins to off and cancels all led and state indications
RETURNS
 void
*/
void LedsResetAllLeds ( void ) 
{   
		/*Cancel all event indications*/ 
    uint16 lLoop = 0;
    
    for ( lLoop = 0 ; lLoop < SINK_NUM_LEDS ; lLoop ++ )
    {
        if (theSink.theLEDTask->gActiveLEDS[lLoop].Type == IT_EventIndication)
        {
            MessageCancelAll ( &theSink.theLEDTask->task, lLoop ) ; 
            theSink.theLEDTask->gActiveLEDS[lLoop].Type =  IT_Undefined ;
            
            LED_DEBUG(("LED: CancelEventInd[%x]\n" , lLoop)) ;
            LedsTurnOffLEDPair( &theSink.theLEDTask->pEventPatterns[theSink.theLEDTask->gActiveLEDS[lLoop].Index] ,TRUE) ;
        }
    }
    	/*cancel all state indications*/
    LedsIndicateNoState ()  ;   
}


/****************************************************************************
NAME 
 LedsSetEnablePin

DESCRIPTION
    if configured sets a pio as a led enable pin
RETURNS
 void
*/
static void LedsSetEnablePin ( bool pOnOrOff ) 
{
    if ( theSink.conf1->PIOIO.pio_outputs.LedEnablePIO < 0xFF ) 
    {
        PioSetLedPin ( theSink.conf1->PIOIO.pio_outputs.LedEnablePIO , pOnOrOff ) ;
    }
}


/****************************************************************************
NAME 
 isOverideFilterActive

DESCRIPTION
    determine if an overide filter is currently active and driving one of the
    leds in which case return TRUE to prevent it being turned off to display 
    another pattern, allows solid red with flashing blue with no interuption in
    red for example.
RETURNS
    true or false
*/
bool isOverideFilterActive ( uint8 Led ) 
{  
    uint16 lFilterIndex = 0 ;
 
    /* determine whether feature to make an overide filter drive the led permanently regardless of 
       any intended flash pattern for that led is enabled */
    if(theSink.features.OverideFilterPermanentlyOn)
    {
        /* permanent overide filter led indication is enabled, this means that an active override
           filter will drive its configured led regardless of any other patterns configured for that
           led */
        for (lFilterIndex = 0 ; lFilterIndex< LM_NUM_FILTER_EVENTS ; lFilterIndex++ )
        {
            /* look for any active filters */
            if ( LedsIsFilterEnabled(lFilterIndex) )
            {
                /* if this is an overide filter driving an led check to see if the passed in LED
                   requires that this led be turned off, if it does then stop the led being turned off
                   otherwise allow it to be turned off as usual */
                 if ( theSink.theLEDTask->gEventFilters[lFilterIndex].FilterType == OVERRIDE)
                 {
                    /* if overide led is active and is driving the passed in led stop this led being turned off */
                    if ((theSink.theLEDTask->gEventFilters[lFilterIndex].OverideLED)&&
                        (theSink.theLEDTask->gEventFilters[lFilterIndex].OverideLED == Led))
                    {
                        return TRUE;                    
                    }
                }    
            }
        }  
    }
    /* permanent overide filter led drive is diabled so allow led pattern to be indicated */
    else
    {
        return FALSE;
    }
    
    /* default case whereby led can be driven normally */
    return FALSE;    
}


/****************************************************************************
NAME 
    LedsIndicateError

DESCRIPTION
    Indicates a fatal application error by flashing each LED in turn the 
    number of times of the specified error id.
    This function never returns.
RETURNS
    void
*/
void LedsIndicateError ( const uint16 errId ) 
{
    uint8 ledId = LED_0;

    /* init leds */
    for (ledId = LED_0; ledId <= LED_2; ledId++)
    {          
        LedConfigure(ledId, LED_DUTY_CYCLE, 0x0);
        LedConfigure(ledId, LED_FLASH_ENABLE, 0);
        LedConfigure(ledId, LED_ENABLE, 1);
    }
    
    /* Never leave this function */
    while (TRUE)
    {            
        /* flash each led in turn */
        for (ledId = LED_0; ledId <= LED_2; ledId++)
        {
            uint16 flashCount = 0;
            uint16 waitCounter = 0;
            /* Flash the number of times corresponding to the config id error */
            for(flashCount = 0; flashCount < errId; flashCount++)
            {
                uint16 intensity = 0x0;
                
                /* Fade in */
                for (intensity=0x0; intensity <= 0x0FFF; intensity++)
                {          
                    
                    LedConfigure(ledId, LED_DUTY_CYCLE, intensity);    
                    
                    /* wait */
                    waitCounter = 0;
                    while (waitCounter < 0x09FF)
                    {
                        waitCounter++;              
                    }
                }
                
                LedConfigure(ledId, LED_DUTY_CYCLE, 0);   
            }
            
            waitCounter = 0;
            while (waitCounter < 0x0FFF)
            {
                waitCounter++;              
            }
        }
    }  
}        
        

