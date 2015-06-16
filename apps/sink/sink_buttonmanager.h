/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_buttonmanager.h
    
DESCRIPTION
    
*/
#ifndef SINK_BUTTON_MANAGER_H
#define SINK_BUTTON_MANAGER_H

#include "sink_events.h"

/* Persistent store event configuration definition */
typedef struct
{
 	unsigned    event:8;
 	unsigned 	type:8;
 	uint16  	pio_mask;
 	uint16  	state_mask;
}event_config_type;

typedef enum ButtonsTimeTag
{
    B_INVALID ,
    B_SHORT ,
    B_LONG  ,
    B_VERY_LONG , 
    B_DOUBLE ,
    B_REPEAT , 
    B_LOW_TO_HIGH ,
    B_HIGH_TO_LOW , 
    B_SHORT_SINGLE,
    B_LONG_RELEASE,
    B_VERY_LONG_RELEASE ,
    B_VERY_VERY_LONG ,
    B_VERY_VERY_LONG_RELEASE,
    B_TRIPLE
}ButtonsTime_t ;

typedef enum ButtonInputSourceTag
{
    B_PIO ,
    B_CAP ,
    B_RESERVED_1,
    B_RESERVED_2
}ButtonsInputSource_t;

    /*used by the button manager*/
typedef struct ButtonEventsTag
{  
    unsigned     ButtonMaskLS :16; /* least significant word of the button mask*/
    unsigned     ButtonMaskVC :2;  /* VREG and CHG bits of the mask */
    unsigned     StateMask :14;      
    
    unsigned     Duration:4 ; /*ButtonsTime_t*/
    unsigned     Event:12 ;
}ButtonEvents_t ;

#define BM_NUM_BUTTON_MATCH_PATTERNS 4

#define BM_NUM_BUTTONS_PER_MATCH_PATTERN 6 

#define BM_EVENTS_PER_CONF_BLOCK (33)   /* Number of events stored per block in memory */
#define BM_EVENTS_PER_PS_BLOCK (22)     /* Number of events stored per block in PS */

#define BM_NUM_BUTTON_TRANSLATIONS 18

#define BM_CAP_SENSORS 6
#define BM_CAP_SENSOR_LOW_SENSITIVITY 500
#define BM_CAP_SENSOR_HIGH_SENSITIVITY 100

typedef struct ButtonPatternTag
{
	sinkEvents_t 		EventToSend ;
    uint16          NumberOfMatches ;
    uint32          ButtonToMatch[BM_NUM_BUTTONS_PER_MATCH_PATTERN] ;   
}ButtonMatchPattern_t ;

typedef struct ButtonTranslationTag
{
    unsigned             button_no:8;       /* button number to assign, 0 to 15 */
    unsigned             input_source:2;    /* input source, pio or cap sense */
    unsigned             input_number:6;    /* input number, 0 to 31 */
}button_translation_type;

/* Definition of the button configuration */
typedef struct
{
    uint16 double_press_time;
    uint16 long_press_time;
    uint16 very_long_press_time; 
	uint16 repeat_time;
	uint16 very_very_long_press_time ;
  
	unsigned debounce_number:8 ;
  	unsigned debounce_period_ms:8;

}button_config_type;

	/*the buttons structure - part of the main app task*/
typedef struct
{
    TaskData    task;
	Task        client;   
   
    uint32 		gButtonPIOLevelMask ;           /* mask used set PIO debounce state, not required for capsense input assignments */
    uint32      gOldPIOState;                   /* last PIO state used to merge in with the capsense data */
    uint32      gPerformInputEdgeCheck;         /* bit mask of translated inputs that are configured for edge detect */
    uint32      gPerformInputLevelCheck;        /* bit mask of translated inputs that are configured for level detect */
    uint32      gBOldInputState;                 /* bit mask of translated pio and capsense inputs last seen as pressed */
    uint32      gBMultipleState  ;    
    
    button_config_type * button_config ;        /*the button durations etc*/
    
    unsigned    gBTapCount:8;                   /* multiple press counter */
	unsigned 	gBTime:8 ;                      /* *ButtonsTime_t   */
   
    ButtonEvents_t * gButtonEvents [2] ;        /*pointer to the array of button event maps*/
             
    ButtonMatchPattern_t gButtonPatterns [BM_NUM_BUTTON_MATCH_PATTERNS]; /*the button match patterns*/
			
    uint16      gButtonMatchProgress[BM_NUM_BUTTON_MATCH_PATTERNS] ;  /*the progress achieved*/
    
#ifdef ENABLE_CAPSENSE    
    uint16      gOldCapState;                   /* last stored state of the capsense switches */
#endif
    
    /* array of input vs button translations */
    button_translation_type gTranslations[BM_NUM_BUTTON_TRANSLATIONS];
    
} ButtonsTaskData;


/****************************************************************************
NAME 
 buttonManagerInit

DESCRIPTION
 Initialises the button event 

RETURNS
    
*/
void buttonManagerInit ( void ) ;

/****************************************************************************
NAME 
 buttonManagerAddMapping

DESCRIPTION
 Maps a button event to a system event
        
    pButtonMask - 
    mask of the buttons that when pressed will generate an event
    e.g.  0x0001 = button PIO 0
    
          0x0003 = combination of PIO 0  and PIO 1
    pSystemEvent
        The Event to be signalled as define in sink_events.h
    pStateMask
        the states as defined in sink_states that the event will be generated in
    pDuration
        the Duration of the button press as defined in sink_buttons.h
        B_SHORT , B_LONG , B_VLONG, B_DOUBLE
          
RETURNS
    
*/
void buttonManagerAddMapping ( event_config_type * event_config , uint8 index) ;

/****************************************************************************
DESCRIPTION
 Adds a button pattern to match against
          
RETURNS
 void
*/    
void buttonManagerAddPatternMapping ( ButtonsTaskData *pButtonsTask, uint16 pSystemEvent , uint16 * pButtonsToMatch, uint16 lPatternIndex ) ;


/****************************************************************************
NAME 
 ButtonManagerConfigDurations
    
DESCRIPTION
 Wrapper method for the button Duration Setup
    
RETURNS

    void
*/   
void buttonManagerConfigDurations ( ButtonsTaskData *pButtonsTask, button_config_type * pButtons ) ; 

/****************************************************************************
NAME 
 BMButtonDetected

DESCRIPTION
 function call for when a button has been detected 
          
RETURNS
 void
*/    
void BMButtonDetected ( uint32 pButtonMask  , ButtonsTime_t pTime ) ;

/****************************************************************************
DESCRIPTION
 	perform an initial read of pios after configuration has been read as it is possible
    that pio states may have changed whilst the config was being read and now needs
    checking to see if any relevant events need to be generated 
*/

void BMCheckButtonsAfterReadingConfig( void );

#endif
