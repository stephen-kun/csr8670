/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2010

FILE NAME
    display_example_plugin.c
DESCRIPTION
    Interface file for example display plugin
    
NOTES
*/

#include <stdlib.h>
#include <print.h>

#include "display_plugin_if.h" /* messaging interface*/
#include "display_example_plugin.h"
#include "display_example.h"
#include "display_example_if.h"

    /* task message handler*/
static void message_handler (Task task, MessageId id, Message message);

static void handleDisplayMessage ( Task task , MessageId id, Message message );
static void handleInternalDisplayMessage ( Task task , MessageId id, Message message );

/* initialise display plugin with device specific parameters */
const DisplayExamplePluginTaskdata display_example_plugin = {{message_handler}, 
                                                                15,     /* vol range */
                                                                2,      /* lines on the display */
                                                                16};    /* length of lines on the display */

/****************************************************************************
DESCRIPTION
    The main display task message handler
*/
static void message_handler ( Task task, MessageId id, Message message ) 
{
    if ( (id >= DISPLAY_DOWNSTREAM_MESSAGE_BASE ) && (id <= DISPLAY_DOWNSTREAM_MESSAGE_TOP) )
    {
        handleDisplayMessage (task , id, message ) ;
    }
    else
    {   
        handleInternalDisplayMessage (task , id , message ) ;
    }
}   

/****************************************************************************
DESCRIPTION

    messages from the display library are received here. 
    and converted into function calls to be implemented in the 
    plugin module
*/ 
static void handleDisplayMessage ( Task task , MessageId id, Message message )  
{
    switch (id)
    {
        case DISPLAY_PLUGIN_INIT_MSG:
        {
            DISPLAY_PLUGIN_INIT_MSG_T * init_message = (DISPLAY_PLUGIN_INIT_MSG_T *)message ;
            PRINT(("DISPLAY: DISPLAY_PLUGIN_INIT_MSG\n"));
            *init_message->max_length = display_example_plugin.length;
            DisplayExamplePluginInit( (DisplayExamplePluginTaskdata*)task,
                                      init_message->app_task) ;
        }                       
        break;
        case DISPLAY_PLUGIN_SET_STATE_MSG:
        {
            DISPLAY_PLUGIN_SET_STATE_MSG_T * state_message = (DISPLAY_PLUGIN_SET_STATE_MSG_T *)message ;
            PRINT(("DISPLAY: DISPLAY_PLUGIN_SET_STATE\n"));     
            DisplayExamplePluginSetState((DisplayExamplePluginTaskdata*)task,
                                            state_message->state);
        }           
        break;
        
        case DISPLAY_PLUGIN_SET_BATTERY_MSG:
        {
            DISPLAY_PLUGIN_SET_BATTERY_MSG_T * battery_message = (DISPLAY_PLUGIN_SET_BATTERY_MSG_T *)message ;
            PRINT(("DISPLAY: DISPLAY_PLUGIN_SET_BATTERY_MSG\n"));       
            DisplayExamplePluginSetBattery((DisplayExamplePluginTaskdata*)task,
                                            battery_message->battery_level);
        }
        break;
        case DISPLAY_PLUGIN_SET_TEXT_MSG:
        {
            DISPLAY_PLUGIN_SET_TEXT_MSG_T * text_message = (DISPLAY_PLUGIN_SET_TEXT_MSG_T *)message ;
            PRINT(("DISPLAY: DISPLAY_PLUGIN_SET_TEXT_MSG\n"));      
            DisplayExamplePluginSetText((DisplayExamplePluginTaskdata*)task,
                                        text_message->text,
                                        text_message->text_length,
                                        text_message->line,
                                        text_message->scroll,
                                        text_message->flash_enable,                                     
                                        text_message->scroll_update,
                                        text_message->scroll_pause,
                                        text_message->display_time);    
                                        
        }
        break;
        case DISPLAY_PLUGIN_SET_VOLUME_MSG:
        {
            DISPLAY_PLUGIN_SET_VOLUME_MSG_T * vol_message = (DISPLAY_PLUGIN_SET_VOLUME_MSG_T *)message ;
            PRINT(("DISPLAY: DISPLAY_PLUGIN_SET_VOLUME_MSG\n"));    
            DisplayExamplePluginSetVolume((DisplayExamplePluginTaskdata*)task,
                                           vol_message->volume);
                                          
        }
        break;
        case DISPLAY_PLUGIN_SET_ICON_MSG:
        {
            DISPLAY_PLUGIN_SET_ICON_MSG_T * icon_message = (DISPLAY_PLUGIN_SET_ICON_MSG_T *)message ;
            PRINT(("DISPLAY: DISPLAY_PLUGIN_SET_ICON_MSG\n"));      
            DisplayExamplePluginSetIcon((DisplayExamplePluginTaskdata*)task,
                                               icon_message->icon, icon_message->state);
        }                                           
        break;  
        default:
        {
            PRINT(("DISPLAY: unhandled message %x\n", id));
            Panic();
        }
        break ;
    }
    

}


/****************************************************************************
DESCRIPTION
    Internal  messages to the task are handled here
*/ 
static void handleInternalDisplayMessage ( Task task , MessageId id, Message message )  
{
    switch(id)
    {
      case DISP_EX_TEXTLN0_CLEAR_INT:
      case DISP_EX_TEXTLN1_CLEAR_INT:
        {
            DisplayExamplePluginClearText((DisplayExamplePluginTaskdata*)task, ((DispExClearLineMessage_T *) message)->line);
        }
      break;
      case DISP_EX_SCROLLLN0_TEXT_INT:
      case DISP_EX_SCROLLLN1_TEXT_INT:
        {
            DispExScrollMessage_T *scrlmsg = (DispExScrollMessage_T *) message;     
            DisplayExamplePluginScrollText((DisplayExamplePluginTaskdata*)task, scrlmsg);
        }
      break;
      default:
        break;
    }   


}  
