/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2010

FILE NAME
    display_example.h

DESCRIPTION
    
    
NOTES
   
*/

#include <stdlib.h>
#include <panic.h>
#include <print.h>
#include <stream.h>
#include <app/vm/vm_if.h>
#include <message.h> 
#include <string.h>




#include "display_plugin_if.h"  
#include "display_example_if.h"  
#include "display_example_plugin.h"
#include "display_example.h"



typedef struct display_Tag
{

   uint16 volume_range;
   
   Task app_task;

}DISPLAY_EXAMPLE_t ;

/* The task instance pointer*/
static DISPLAY_EXAMPLE_t * DISPLAY_EXAMPLE = NULL;

/* display plugin functions*/
void DisplayExamplePluginInit(  DisplayExamplePluginTaskdata *task, 
                                Task app_task)
{
    if (DISPLAY_EXAMPLE)
          Panic();
   
    DISPLAY_EXAMPLE = PanicUnlessNew ( DISPLAY_EXAMPLE_t ); 
   
   /* initalise the display */
   DISPLAY_EXAMPLE->app_task = app_task;
   
   /* indicate success */
   {
        MAKE_DISPLAY_MESSAGE(DISPLAY_PLUGIN_INIT_IND);
        PRINT(("DISPLAYEX: Send DISPLAY_PLUGIN_INIT_IND\n"));
        message->result = TRUE;
        MessageSend(DISPLAY_EXAMPLE->app_task, DISPLAY_PLUGIN_INIT_IND, message);
    }
   
}

void DisplayExamplePluginSetState( DisplayExamplePluginTaskdata *task, bool state ) 
{
    PRINT(("DISP: State %u:\n", state));


}

void DisplayExamplePluginSetText( DisplayExamplePluginTaskdata *task, char* text, uint8 text_length, uint8 line, uint8 scroll, bool flash, uint16 scroll_update, uint16 scroll_pause, uint16 display_time ) 
{
    /* configure scroll and update messages so they're sctive on the correct line number, this example is 2 lines */
    uint8   active_line_clear_msg = (line==0)?DISP_EX_TEXTLN0_CLEAR_INT:DISP_EX_TEXTLN1_CLEAR_INT;
    uint8   active_line_scroll_msg = (line==0)?DISP_EX_SCROLLLN0_TEXT_INT:DISP_EX_SCROLLLN1_TEXT_INT;

    PRINT(("DISP: (L%u)(L%u)(F%u)(S%u,%u)(D:%u): ", line,text_length, flash,scroll_update,scroll_pause, display_time));
    PRINT(("%-.*s", text_length, text));
    PRINT(("\n"));
    
    /* cancel any scrolling or clear messages */
    MessageCancelAll( (TaskData*)task , active_line_clear_msg);
    MessageCancelAll( (TaskData*)task , active_line_scroll_msg);
    
    switch(scroll)
    {
        case DISPLAY_TEXT_SCROLL_SCROLL:
        case DISPLAY_TEXT_SCROLL_BOUNCE:
        {
            /* send message to update display for scroll */
            MAKE_DISPLAY_MESSAGE_WITH_LEN(DispExScrollMessage, text_length);

            message->text_length = text_length;
            message->line = line;
            message->bounce = (scroll == DISPLAY_TEXT_SCROLL_BOUNCE);
            message->scroll_update = scroll_update; 
            memmove(message->text,text,text_length) ;
        
            /* if scrolling, check if a longer pause is required to start scrolling */
            MessageSendLater((TaskData*)task, active_line_scroll_msg, message, scroll_pause?scroll_pause:scroll_update);
        }       
        break; 
        case DISPLAY_TEXT_SCROLL_STATIC:
        default:
            ; /* do nothing */
    }
    
    /* check if this display is for a limited time only */
    if(display_time)
    {
        MAKE_DISPLAY_MESSAGE(DispExClearLineMessage);
        message->line = line;
        MessageSendLater((TaskData*)task, active_line_clear_msg, message, display_time);
    }
}


void DisplayExamplePluginSetVolume( DisplayExamplePluginTaskdata *task, uint16 volume ) 
{
    PRINT(("DISP: Volume %u:\n", volume));
}

void DisplayExamplePluginSetIcon( DisplayExamplePluginTaskdata *task, uint8 icon, bool state ) 
{
    PRINT(("DISP: Icon %u(%u):\n", icon, state));
}


void DisplayExamplePluginSetBattery( DisplayExamplePluginTaskdata *task, uint8 battery_level ) 
{
    PRINT(("DISP: Batt %u:\n", battery_level));
}

void DisplayExamplePluginScrollText( DisplayExamplePluginTaskdata *task, DispExScrollMessage_T * dispscrmsg)
{
    /* configure scroll and update messages so they're sctive on the correct line number, this example is 2 lines */
    uint8   active_line_scroll_msg = (dispscrmsg->line==0)?DISP_EX_SCROLLLN0_TEXT_INT:DISP_EX_SCROLLLN1_TEXT_INT;

    PRINT(("DISP: Scroll line  %u, %u: ", dispscrmsg->line , dispscrmsg->scroll_update));
    PRINT((dispscrmsg->text));
    PRINT(("\n"));

    {
            /* send message to update display for scroll */
        MAKE_DISPLAY_MESSAGE_WITH_LEN(DispExScrollMessage, dispscrmsg->text_length);

        message->text_length = dispscrmsg->text_length;
        message->line = dispscrmsg->line;
        message->bounce = dispscrmsg->bounce;
        message->scroll_update = dispscrmsg->scroll_update; 
        memmove(message->text,dispscrmsg->text,dispscrmsg->text_length) ;

        /* if scrolling, check if a longer pause is required to start scrolling */
        MessageSendLater((TaskData*)task, active_line_scroll_msg, message, message->scroll_update);
    }

}

void DisplayExamplePluginClearText( DisplayExamplePluginTaskdata *task, uint8 line ) 
{
    /* configure scroll and update messages so they're sctive on the correct line number, this example is 2 lines */
    uint8   active_line_scroll_msg = (line==0)?DISP_EX_SCROLLLN0_TEXT_INT:DISP_EX_SCROLLLN1_TEXT_INT;

    /* Cancel any scrolling on this line */
    MessageCancelAll( (TaskData*)task , active_line_scroll_msg);
    PRINT(("DISP: Clear line (%u)\n", line ));
}

