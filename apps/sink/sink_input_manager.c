/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2013-2014
Part of ADK 3.5

FILE NAME
    sink_input_manager.c

DESCRIPTION
    The Input Manager that is responsible for monitoring messages sent from
    the various "input monitoring" tasks
*/

#if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))

/* Firmware includes */
#include <message.h>
#include <stdio.h>

/* Application includes */
#include "sink_input_manager.h"
#include "sink_private.h"
#include "sink_states.h"
#include "sink_statemanager.h"
#include "sink_events.h"
#if (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
#include "sink_ble_remote_control.h"
#include "sink_gatt_client.h"
#endif
#ifdef ENABLE_IR_REMOTE
#include "sink_ir_remote_control.h"
#endif


/* Macro for Input Manager Debug */
#ifdef DEBUG_INPUT_MANAGER
#define INPUT_MANAGER_DEBUG(x) DEBUG(x)
#else
#define INPUT_MANAGER_DEBUG(x) 
#endif



/*******************************************************************************
    Helper function to process an input event, requires the input event that
    has occured and the current input mask when the event was generated.
    
    Searches through the "input manager" lookup table to see if the event that
    has been generated should be converted to a user event and sent to the
    application handler to be processed.
*/
static void processInputEvent(inputEvent_t event, uint16 mask)
{
    /* Find the "input event" in the lookup table */
    uint16 i;
    for (i=0; i<theSink.rundata->inputManager.size_lookup_table; i++)
    {
        /* "Input event ID", "Input mask" and state must match for the user event to be generated */
        if  ( (theSink.rundata->inputManager.config->lookup_table[i].input_event == event) &&
              (theSink.rundata->inputManager.config->lookup_table[i].mask == mask) &&
              ( (1<<stateManagerGetState()) & (theSink.rundata->inputManager.config->lookup_table[i].state_mask) ) )
              
        {
            /* Use the offset in the lookup table to create the user event that needs to be sent to the app_handler task */
            sinkEvents_t x = EVENTS_USR_MESSAGE_BASE + theSink.rundata->inputManager.config->lookup_table[i].user_event;
            
            INPUT_MANAGER_DEBUG(("Generate Event [%x]\n", x));
            MessageSend( &theSink.task , x , 0 );
            
            /* Don't need to waste any more time in the loop, found the event so just return */
            return;
        }
    }
    /* No lookup entry exists for the input event */
    INPUT_MANAGER_DEBUG(("Ignore\n"));
}


/****************************************************************************/
void notifyInputManager( inputMonitorType_t monitor, inputEvent_t event, uint16 mask, uint16 id )
{
#ifdef ENABLE_IR_REMOTE
    /* Check for IR leanring mode */
    if (theSink.rundata->irInputMonitor.learning_mode && (theSink.rundata->irInputMonitor.learn_this_input_id == 0) )
    {
        /* Do no process the input event, just learn it */
        if (event == inputEventDown)
        {
            /* We have recived a code from the remote controller, send a message to blink the led*/            
            MessageSend(&theSink.task, EventSysRemoteControlCodeReceived, 0);
            
            /* Store the input mask to learn */
            theSink.rundata->irInputMonitor.learn_this_input_id = mask;
            
            /* Restart the learning mode timeout as it's being used */
            MessageCancelAll(&theSink.task, EventSysIRLearningModeTimeout);
            MessageSendLater(&theSink.task, EventSysIRLearningModeTimeout, 0, theSink.rundata->irInputMonitor.config->learning_mode_timeout );
            
            /* Nothing more to do here, wait for an "unknown" button on the IR remote to be pressed so it can be learnt */
            return;
        }
    }
#endif
    /* Which event has occured? */
    switch(event)
    {
        /* Has an input been pressed? */
        case inputEventDown:
        {
            /* Ignore the press if there is an ongoing input process */
            if (!theSink.rundata->inputManager.down_mask)
            {
                INPUT_MANAGER_DEBUG(("IN: Event[%x] mask[%x] : ", event, mask));
                processInputEvent(event, mask);
                theSink.rundata->inputManager.down_mask = mask;
                
                /* We have recived a code from the remote controller, send a message to blink the led*/            
                MessageSend(&theSink.task, EventSysRemoteControlCodeReceived, 0);
            }
        }
        break;
        
        /* Has a button been released? */
        case inputEventVShortRelease:
        case inputEventShortRelease:
        case inputEventLongRelease:
        case inputEventVVLongRelease:
        case inputEventVLongRelease:
        {
            INPUT_MANAGER_DEBUG(("IN: Event[%x] mask[%x] : ", event, theSink.rundata->inputManager.down_mask));
            processInputEvent(event, theSink.rundata->inputManager.down_mask);
            theSink.rundata->inputManager.down_mask = 0;
        }
        break;
        
        /* Has a timer fired? */
        case inputEventShortTimer:
        case inputEventLongTimer:
        case inputEventVLongTimer:
        case inputEventVVLongTimer:
        case inputEventRepeatTimer:
        {
            INPUT_MANAGER_DEBUG(("IN: Event[%x] mask[%x] : ", event, mask));
            processInputEvent(event, mask);
        }
        break;
    }
}


/****************************************************************************/
bool inputManagerBusy(void)
{
    /* Is the input manager task is busy processing an input event? */
    if (theSink.rundata->inputManager.down_mask)
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}


#else /* #if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED)) */

static const int dummy_input_manager;  /* ISO C forbids an empty source file */

#endif
