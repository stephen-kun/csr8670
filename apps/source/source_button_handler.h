/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_button_handler.h

DESCRIPTION
    Handles button events.
    The functionality is only included if INCLUDE_BUTTONS is defined.
    
*/


#ifdef INCLUDE_BUTTONS


#ifndef _SOURCE_BUTTON_HANDLER_H_
#define _SOURCE_BUTTON_HANDLER_H_


#include "source_buttons.h"


/* Base message number for button messages which is created by ButtonParsePro */
#define BUTTON_MSG_BASE 1000


/* structure holding the button data */
typedef struct
{
    TaskData buttonTask;
    PioState pio_state;
    unsigned power_button_released:1;
    unsigned button_long_press:1;
} BUTTON_DATA_T;


/***************************************************************************
Function definitions
****************************************************************************
*/

/****************************************************************************
NAME    
    button_msg_handler

DESCRIPTION
    Message handler for button events.

*/
void button_msg_handler(Task task, MessageId id, Message message);


/****************************************************************************
NAME    
    buttons_init

DESCRIPTION
    Initialises the button handling.

*/
void buttons_init(void);


#endif /* _SOURCE_BUTTON_HANDLER_H_ */


#endif /* INCLUDE_BUTTONS */
