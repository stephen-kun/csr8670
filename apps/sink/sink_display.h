/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2010-2014

FILE NAME
    sink_display.h
    
DESCRIPTION
    
*/
#ifndef _SINK_DISPLAY_H_
#define _SINK_DISPLAY_H_

#ifndef ENABLE_DISPLAY
/* dummy display functions if display is disabled */
#define handleDisplayMessage(task, id, message) ((void)(0))
#define displayInit() ((void)(0))
#define displaySetState(state) ((void)(0))
#define displayShowText(text, txtlen, line, scroll, scroll_update, scroll_pause, flash, display_time ) ((void)(0))
#define displayShowSimpleText(text, line) ((void)(0))
#define displayUpdateIcon(icon, state) ((void)(0))
#define displayUpdateVolume(vol) ((void)(0))
#define displayUpdateBatteryLevel(charging) ((void)(0))

#else

/* Pre-define some text strings */
#define DISPLAYSTR_HELLO        "Power On"    
#define DISPLAYSTR_GOODBYE      "Goodbye"    
#define DISPLAYSTR_CHARGING     "Charging" 

#define DISPLAYSTR_CLEAR      ""    
#define DISPLAYSTR_PAIRING      "Pairing mode"
#define DISPLAYSTR_CONNECTED    "Connected"
#define DISPLAYSTR_OUTGOINGCALL "Outgoing Call"
#define DISPLAYSTR_INCOMINGCALL "Incoming Call"
#define DISPLAYSTR_ACTIVECALL   "Call in progress"
#define DISPLAYSTR_TWCWAITING   "Call Waiting"
#define DISPLAYSTR_TWCONHOLD    "Call On Hold"
#define DISPLAYSTR_TWCMULTI     "Multicall"
#define DISPLAYSTR_INCOMINGONHOLD "Incoming Call On Hold"
#define DISPLAYSTR_ACTIVECALLNOSCO "Call (No audio)"
#define DISPLAYSTR_A2DPSTREAMING   "Play"
#define DISPLAYSTR_LOWBATTERY      "Low Battery"
#define DISPLAYSTR_TESTMODE      "Test Mode"
#define DISPLAYSTR_FM_STORAGE_FULL      "FM storage full"


/****************************************************************************
NAME 
    displayInit
    
DESCRIPTION
    Initialise the display
    
RETURNS
    void
*/ 

void displayInit(void);



/****************************************************************************
NAME 
    displayShowText
    
DESCRIPTION
    Display text on display
    
RETURNS
    void
*/ 

void displayShowText(char* text, 
                     uint8 txtlen, 
                     uint8 line,
                     bool scroll,
                     uint16 scroll_update,                     
                     uint16 scroll_pause,
                     bool  flash,
                     uint16  display_time );



/****************************************************************************
NAME 
    displaySetState
    
DESCRIPTION
    Turn display off (state FALSE) or on (state TRUE)
    
RETURNS
    void
*/ 
void displaySetState(bool state);

        
/****************************************************************************
NAME 
    displayShowSimpleText
    
DESCRIPTION
    Simplified interface to display text
    
RETURNS
    void
*/ 
void displayShowSimpleText(char* text, uint8 line);

        
/****************************************************************************
NAME 
    displayUpdateIcon
    
DESCRIPTION
    Updates the state of an icon on the display
    
RETURNS
    void
*/ 

void displayUpdateIcon( uint8 icon, bool state );


/****************************************************************************
NAME 
    displayUpdateVolume
    
DESCRIPTION
    Updates the state of the volume on the display
    
RETURNS
    void
*/ 
void displayUpdateVolume( int16 vol );


/****************************************************************************
NAME 
    displayUpdateBatteryLevel
    
DESCRIPTION
    Updates the state of the battery level on the display
    
RETURNS
    void
*/ 
void displayUpdateBatteryLevel( bool charging );


/****************************************************************************
NAME 
    displayUpdateAppState
    
DESCRIPTION
    Updates the the display with the application state
    
RETURNS
    void
*/ 
void displayUpdateAppState (sinkState newState);

#endif /* ifndef ENABLE_DISPLAY */
       
#endif /* _SINK_DISPLAY_H_ */
