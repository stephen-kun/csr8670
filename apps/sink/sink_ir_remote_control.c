/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2013-2014

FILE NAME
    sink_ir_remote_control.c

DESCRIPTION
    Interface with Infrared Remote controller(s)
*/

#ifdef ENABLE_IR_REMOTE

/* Application includes */
#include "sink_ir_remote_control.h"
#include "sink_private.h"
#include "sink_debug.h"
#include "sink_configmanager.h"
#include "sink_config.h"
#include "sink_input_manager.h"

/* Firmware includes */
#include <panic.h>
#include <stdlib.h>
#include <infrared.h>

/* Macro for BLE HID RC Debug */
#ifdef DEBUG_IR_RC
#define IR_RC_DEBUG(x) DEBUG(x)
#else
#define IR_RC_DEBUG(x) 
#endif

/*******************************************************************************
NAME
    tableIndexToBitmask

DESCRIPTION
    Helper function to convert a given uint16 table index value into a uint16 bitmask that is 
    to be utilised by input manager module

RETURNS
    uint16 bitmask corresponding to the given table index value. 
    
*********************************************************************************/
static uint16 tableIndexToBitmask(const uint16 index){
        
    uint16 bitmask = 0;
    bitmask = 0x1 << index;    
    
    return bitmask;
            
    }

/*******************************************************************************
NAME
    bitmaskToTableIndex

DESCRIPTION
    Helper function to convert a given uint16 bitmask value into a uint16 table index value that is 
    to be utilised by remote oontrol module while creating a new record for recently learnt RC codes  

RETURNS
    uint16 table index corresponding to the given bitmask value.
    
*********************************************************************************/
static uint16 bitmaskToTableIndex(const uint16 bitmask){
    
    uint16 index = 0;
    uint16 tempBitmask = bitmask;
    
    /* initial case (bitmask == 0) could result in an infinite loop, take care! */
    if(tempBitmask == 0)
    	return 0;

    while(tempBitmask != 0x1)
    {
        tempBitmask = tempBitmask >> 0x1;
        index++;
    }

    return index;
    
}

/*******************************************************************************
NAME
    irCodeLookup

DESCRIPTION
    Helper function to search through the IR lookup tables to see if the
    recieved code matched. 

RETURNS
    uint16 input mask indicating which input (button) was pressed, if no match
    in the lookup tables was found, will return zero.
    
*********************************************************************************/
static uint16 irCodeLookup( uint16 address, uint16 code )
{
    uint16 i;
    
    /* Does the recieved IR code match an entry in the IR lookup table? */
    for (i=0; i<theSink.rundata->irInputMonitor.size_lookup_table; i++)
    {
        if ( (theSink.rundata->irInputMonitor.config->lookup_table[i].ir_code == code) &&
             (theSink.rundata->irInputMonitor.config->lookup_table[i].remote_address == address) )
        {
            /* Found a match; translate the IR code to an input mask */
            return tableIndexToBitmask(theSink.rundata->irInputMonitor.config->lookup_table[i].input_id);
        }
    }
    
    /* No match was found in the default lookup table; Does the recieved IR code match an entry in the learnt codes lookup table? */
    if (theSink.rundata->irInputMonitor.num_learnt_codes)
    {
        for (i=0; i<theSink.rundata->irInputMonitor.num_learnt_codes; i++)
        {
            if ( (theSink.rundata->irInputMonitor.learnt_codes[i].ir_code == code) &&
             (theSink.rundata->irInputMonitor.learnt_codes[i].remote_address == address) )
            {
                /* Found a match; translate the IR code to an input mask and return */
                return tableIndexToBitmask(theSink.rundata->irInputMonitor.learnt_codes[i].input_id);
            }
        }
    }
    
    /* No match was found in either lookup table */
    return 0;
}


/*******************************************************************************
    Helper function to create and send a message to the irInputMonitorTask
    
    PARAMETERS:
    mid         - Message ID
    timer       - Timer ID to identify which timer this message is going to be
    mask        - input mask
    addr        - Address of the IR RC whose button this message is associated
    delay_time  - delay sending the message by *timer* ms
*/
static void createIrRcButtonEventMessage(irRcMessageID_t mid, irRcTimerID_t timer, uint16 mask, uint16 addr, uint32 delay_time)
{
    MAKE_IR_RC_MESSAGE(IR_RC_BUTTON_EVENT_MSG);
    message->timer  = timer;
    message->mask   = mask;
    message->addr   = addr;
    
    /* Dispatch the message */
    MessageSendLater(&theSink.rundata->irInputMonitor.task, mid, message, delay_time);
}



/*******************************************************************************
NAME
    handleIrEventMsg

DESCRIPTION
    Helper function to handle when firmware sends an Infra Red Event message
*/
static void handleIrEventMsg( MessageInfraRedEvent * msg )
{
    /* If not in learning mode, process the IR event and notify the Input Manager (if IR event is valid) */
    if (!theSink.rundata->irInputMonitor.learning_mode )
    {
        /* Is this a button press or a button release? */
        if (msg->event == EVENT_PRESSED)
        {
            /* Find out if the recieved IR code is one that is understood */
            uint16 input_mask = irCodeLookup(msg->address, msg->data[0]);
            
            /* Was the IR code valid (understood)? */
            if (input_mask)
            {
                /* Inform the input manager which button has been pressed */
                notifyInputManager( inputMonitorIRRemote, inputEventDown, input_mask, msg->address );
                
                /* Store the input mask of the button that is now held down */
                theSink.rundata->irInputMonitor.button_mask = input_mask;
                
                /* Update the button state */
                theSink.rundata->irInputMonitor.button_state = inputDownVShort;
                
                /* Start the duration and repeat timers */
                createIrRcButtonEventMessage(IR_RC_BUTTON_TIMER_MSG, IR_RC_TIMER_SHORT, input_mask, msg->address, theSink.rundata->irInputMonitor.timers->shortTimer);
                createIrRcButtonEventMessage(IR_RC_BUTTON_REPEAT_MSG, 0, input_mask, msg->address, theSink.rundata->irInputMonitor.timers->repeatTimer);
            }
            else
            {
                IR_RC_DEBUG(("IR: Unrecognised IR MSG [%x] [%x]\n", msg->address, msg->data[0]));
            }
        }
        else
        {
            /* Cancel the (MULTIPLE,SHORT,LONG,VLONG or VVLONG) TIMER & REPEAT timers*/
            MessageCancelAll(&theSink.rundata->irInputMonitor.task, IR_RC_BUTTON_TIMER_MSG);
            MessageCancelAll(&theSink.rundata->irInputMonitor.task, IR_RC_BUTTON_REPEAT_MSG);
            
            /* Inform the input manager that the button has been released */
            switch (theSink.rundata->irInputMonitor.button_state)
            {
                case inputNotDown:
                    /* State not valid for a release event */
                case inputMultipleDetect:
                    /* State not supported by the IR remote (mutliple IR buttons are not supported) */
                break;
                
                case inputDownVShort:
                {
                    notifyInputManager( inputMonitorIRRemote, inputEventVShortRelease, theSink.rundata->irInputMonitor.button_mask, msg->address );
                }
                break;
                case inputDownShort:
                {
                    notifyInputManager( inputMonitorIRRemote, inputEventShortRelease, theSink.rundata->irInputMonitor.button_mask, msg->address );
                }
                break;
                case inputDownLong:
                {
                    notifyInputManager( inputMonitorIRRemote, inputEventLongRelease, theSink.rundata->irInputMonitor.button_mask, msg->address );
                }
                break;
                case inputDownVLong:
                {
                    notifyInputManager( inputMonitorIRRemote, inputEventVLongRelease, theSink.rundata->irInputMonitor.button_mask, msg->address );
                }
                break;
                case inputDownVVLong:
                {
                    notifyInputManager( inputMonitorIRRemote, inputEventVVLongRelease, theSink.rundata->irInputMonitor.button_mask, msg->address );
                }
                break;
            }
            
            /* Update the button state and clear the mask as a button has just been released */
            theSink.rundata->irInputMonitor.button_state = inputNotDown;
            theSink.rundata->irInputMonitor.button_mask = 0;
        }
    }
    
    
    /* Learning mode is active */
    else
    {
        if ( (msg->event == EVENT_PRESSED)&& irCanLearnNewCode() )
        {
            /* Is there an input ID (or mask) to learn? */
            if (theSink.rundata->irInputMonitor.learn_this_input_id)
            {
                /* Check that the code to learn is not already one that is known; there would be no point learning a known code */
                if ( irCodeLookup(msg->address, msg->data[0]) != theSink.rundata->irInputMonitor.learn_this_input_id )
                {
                    /* Add the learnt code */
                    irLookupTableConfig_t new_code;
                    new_code.input_id       = bitmaskToTableIndex(theSink.rundata->irInputMonitor.learn_this_input_id);
                    new_code.remote_address = msg->address;
                    new_code.ir_code        = msg->data[0];
                    
                    /* Allocate memory to store the new input code (and also the other learnt codes) */
                   	theSink.rundata->irInputMonitor.learnt_codes = realloc( theSink.rundata->irInputMonitor.learnt_codes, (theSink.rundata->irInputMonitor.num_learnt_codes * sizeof(irLookupTableConfig_t)) + sizeof(irLookupTableConfig_t) );
                        
                    /* Add the new code to the learnt codes */
                    theSink.rundata->irInputMonitor.learnt_codes[theSink.rundata->irInputMonitor.num_learnt_codes] = new_code;
                    
                    /* Increment the number of learnt codes as a new code has now been added */
                    theSink.rundata->irInputMonitor.num_learnt_codes++;
                    
                    /* Store the new learnt code to PSKEY so it will be remembered "forever" (at least until the learnt codes are cleared) */
                    ConfigStore( CONFIG_IR_REMOTE_CONTROL_LEARNED_CODES, theSink.rundata->irInputMonitor.learnt_codes, (theSink.rundata->irInputMonitor.num_learnt_codes * sizeof(irLookupTableConfig_t)) );
                    
                    /* Clear the "input to learn" as may want to learn other codes */
                    theSink.rundata->irInputMonitor.learn_this_input_id = 0;
                    
                    /* Let the application decide what to do now IR code has been learnt (could play tone or exit learning mode) */
                    MessageSend(&theSink.task, EventSysIRCodeLearnSuccess, 0);
                }
                else
                {
                    IR_RC_DEBUG(("IR: Cannot learn a known IR code addr[%x] data[%x] id[%x]\n", msg->address, msg->data[0], theSink.rundata->irInputMonitor.learn_this_input_id));
                    
                    /* Let app decide how to handle a failed code learn */
                    MessageSend(&theSink.task, EventSysIRCodeLearnFail, 0);
                }
            }
            else
            {
                /* Notify the input manager of the button press to learn */
                notifyInputManager( inputMonitorIRRemote, inputEventDown, irCodeLookup(msg->address, msg->data[0]), msg->address );
            }
        }
    }
}

                    
/*******************************************************************************
NAME
    ir_rc_message_handler

DESCRIPTION
    message handler for the IR recieve messages provided by the firmware
*/
static void ir_rc_message_handler( Task task, MessageId id, Message message )
{
    if (id == MESSAGE_INFRARED_EVENT)
    {
        handleIrEventMsg( (MessageInfraRedEvent*)message );
    }
    
    /* Has a duration timer fired? */
    else if (id == IR_RC_BUTTON_TIMER_MSG)
    {
        IR_RC_BUTTON_EVENT_MSG_T *msg = (IR_RC_BUTTON_EVENT_MSG_T *)message;
        
        /* Which timer has just fired? */
        switch(msg->timer)
        {
            case IR_RC_TIMER_SHORT:
            {
                /* Update the button state */
                theSink.rundata->irInputMonitor.button_state = inputDownShort;
                
                /* Notify the input manager of the timer event */
                notifyInputManager( inputMonitorIRRemote, inputEventShortTimer, msg->mask, msg->addr );
                
                /* Start the LONG timer */
                createIrRcButtonEventMessage( IR_RC_BUTTON_TIMER_MSG, IR_RC_TIMER_LONG, msg->mask, msg->addr, (theSink.rundata->irInputMonitor.timers->longTimer - theSink.rundata->irInputMonitor.timers->shortTimer) );
            }
            break;
            case IR_RC_TIMER_LONG:
            {
                /* Update the button state */
                theSink.rundata->irInputMonitor.button_state = inputDownLong;
                
                /* Notify the input manager of the timer event */
                notifyInputManager( inputMonitorIRRemote, inputEventLongTimer, msg->mask, msg->addr );
                
                /* Start the VLONG timer */
                createIrRcButtonEventMessage( IR_RC_BUTTON_TIMER_MSG, IR_RC_TIMER_VLONG, msg->mask, msg->addr, (theSink.rundata->irInputMonitor.timers->vLongTimer - theSink.rundata->irInputMonitor.timers->longTimer) );
            }
            break;
            case IR_RC_TIMER_VLONG:
            {
                /* Update the button state */
                theSink.rundata->irInputMonitor.button_state = inputDownVLong;
                
                /* Notify the input manager of the timer event */
                notifyInputManager( inputMonitorIRRemote, inputEventVLongTimer, msg->mask, msg->addr );
                
                /* Start the VVLONG timer */
                createIrRcButtonEventMessage( IR_RC_BUTTON_TIMER_MSG, IR_RC_TIMER_VVLONG, msg->mask, msg->addr, (theSink.rundata->irInputMonitor.timers->vvLongTimer - theSink.rundata->irInputMonitor.timers->vLongTimer) );
            }
            break;
            case IR_RC_TIMER_VVLONG:
            {
                /* Update the button state */
                theSink.rundata->irInputMonitor.button_state = inputDownVVLong;
                
                /* Notify the input manager of the timer event */
                notifyInputManager( inputMonitorIRRemote, inputEventVVLongTimer, msg->mask, msg->addr );
            }
            break;
        }
    }
    
    /* Has the repeat timer fired? */
    else if (id == IR_RC_BUTTON_REPEAT_MSG)
    {
        IR_RC_BUTTON_EVENT_MSG_T *msg = (IR_RC_BUTTON_EVENT_MSG_T *)message;
        
        /* Notify the input manager of the timer event */
        notifyInputManager( inputMonitorIRRemote, inputEventRepeatTimer, msg->mask, msg->addr );
        
        /* Keep sending REPEAT messages until the button(s) is/are released */
        createIrRcButtonEventMessage(  IR_RC_BUTTON_REPEAT_MSG, 0, msg->mask, msg->addr, theSink.rundata->irInputMonitor.timers->repeatTimer );
    }
}


/****************************************************************************/
bool irCanLearnNewCode(void)
{
    if (theSink.rundata->irInputMonitor.num_learnt_codes >= theSink.rundata->irInputMonitor.config->max_learning_codes)
    {
        return FALSE;
    }
    else
    {
        return TRUE;
    }
}


/****************************************************************************/
bool irStartLearningMode(void)
{
    /* Is it a good state for the IR monitor to start learning a new code? */
    if ( ( irCanLearnNewCode() ) && ( !inputManagerBusy() ) )
    {
        /* Start the failsafe timer to automatically stop IR learning mode after timeout */
        MessageSendLater(&theSink.task, EventSysIRLearningModeTimeout, 0, theSink.rundata->irInputMonitor.config->learning_mode_timeout );
        
        /* Start the learning mode reminder message (can be used to trigger reminder tone indicating learning mode is active) */
        MessageSendLater(&theSink.task, EventSysIRLearningModeReminder, 0, theSink.rundata->irInputMonitor.config->learning_mode_reminder );
        
        /* Start learning mode */
        theSink.rundata->irInputMonitor.learning_mode = 1;
        
        return TRUE;
    }
    else
    {
        /* Can't start learning mode */
        IR_RC_DEBUG(("IR: Cannot start IR Learning mode (bad state)\n"));
        
        return FALSE;
    }
}


/****************************************************************************/
void handleIrLearningModeReminder(void)
{
    /* A new reminder needs to be generated */
    MessageSendLater(&theSink.task, EventSysIRLearningModeReminder, 0, theSink.rundata->irInputMonitor.config->learning_mode_reminder );
    
    /* TODO : Play a tone or something */
}


/****************************************************************************/
void irStopLearningMode(void)
{
    if (theSink.rundata->irInputMonitor.learning_mode)
    {
        /* Terminate learning mode by clearing the learning mode data and cancelling the timeout and reminder */
        theSink.rundata->irInputMonitor.learning_mode = 0;
        theSink.rundata->irInputMonitor.learn_this_input_id = 0;
        MessageCancelAll(&theSink.task, EventSysIRLearningModeTimeout);
        MessageCancelAll(&theSink.task, EventSysIRLearningModeReminder);
    }
}


/****************************************************************************/
void irClearLearntCodes(void)
{
    if (theSink.rundata->irInputMonitor.num_learnt_codes)
    {
        /* Free the allocated memory used to store the learnt codes and reset the counter */
        free(theSink.rundata->irInputMonitor.learnt_codes);
        
        /*  theSink.rundata->irInputMonitor.learnt_codes pointer should be set to NULL as 
        it is critical for realloc() that is used while adding new codes in the learnt codes table*/ 
        theSink.rundata->irInputMonitor.learnt_codes = NULL;
        theSink.rundata->irInputMonitor.num_learnt_codes = 0;
        
        /* Also clear the PSKEY data */
        ConfigStore( CONFIG_IR_REMOTE_CONTROL_LEARNED_CODES, 0, 0 );
    }
}


/****************************************************************************/
void initIrInputMonitor( timerConfig_t * timers )
{
    IR_RC_DEBUG(("IR: Init\n"));
    
    /* The input monitor is only required if there's a lookup table to convert incoming Infrared events */
    if (theSink.rundata->irInputMonitor.size_lookup_table)
    {
        uint16 size;    /* Variable used to store number of words in PSKEY CONFIG_IR_REMOTE_CONTROL_LEARNED_CODES */
        
        /* Need to know about the configured timers */
        theSink.rundata->irInputMonitor.timers = timers;
        
        /* Setup the message handler for the Infrared RC Monitor */
        theSink.rundata->irInputMonitor.task.handler = ir_rc_message_handler;
            
        /* register for IR messages from the firmware */
        MessageInfraredTask(&theSink.rundata->irInputMonitor.task);
    
        /* set the required protocol, NEC or RC5 */
        InfraredConfigure(INFRARED_PROTOCOL, theSink.rundata->irInputMonitor.config->protocol );

        /* set the pio to use for the IR receiver */
        InfraredConfigure(INFRARED_PIO, theSink.rundata->irInputMonitor.config->ir_pio );
        
        /* set FW IR interface parameters */
        InfraredConfigure(INFRARED_JITTER_ALLOWANCE, 300);
        InfraredConfigure(INFRARED_START_PULSE_STABLE_PERIOD, 200);
        InfraredConfigure(INFRARED_KEY_RELEASE_PERIOD, 120);
        InfraredConfigure(INFRARED_KEEP_AWAKE_PERIOD, 110);
        
        /* enable FW IR receive scanning */
        InfraredConfigure(INFRARED_ENABLE, 1);   
        
        /* Has the application learnt any IR codes? */
        size = ConfigRetrieve(CONFIG_IR_REMOTE_CONTROL_LEARNED_CODES, 0, 0);
        if (size)
        {
            /* Find out how many learnt IR codes exist */
            theSink.rundata->irInputMonitor.num_learnt_codes = size / sizeof(irLookupTableConfig_t);
            
            /* Allocate memory to load the learnt codes */
            theSink.rundata->irInputMonitor.learnt_codes = mallocPanic(size);
            
            /* Copy the learnt codes from PS to runtime data */
            if ( ConfigRetrieve(CONFIG_IR_REMOTE_CONTROL_LEARNED_CODES, theSink.rundata->irInputMonitor.learnt_codes, size) == 0)
            {
                IR_RC_DEBUG(("IR: Failed to read learnt IR Codes\n"));
                /* Can't use the learnt codes so just ignore them (rather than panic application) */
                theSink.rundata->irInputMonitor.num_learnt_codes = 0;
            }
#ifdef DEBUG_IR_RC
            else
            {
                uint16 i;
                IR_RC_DEBUG(("IR: Num learnt codes = [%d]:\n", theSink.rundata->irInputMonitor.num_learnt_codes));
                for (i=0; i<theSink.rundata->irInputMonitor.num_learnt_codes; i++)
                {
                    IR_RC_DEBUG(("IR: ADDR[%x] : [0x%x]->[0x%02x]\n", theSink.rundata->irInputMonitor.learnt_codes[i].remote_address, theSink.rundata->irInputMonitor.learnt_codes[i].input_id, theSink.rundata->irInputMonitor.learnt_codes[i].ir_code));
                }
            }
#endif /*DEBUG_IR_RC*/
        }
        else
        {
            /* No IR codes have been learnt */
            theSink.rundata->irInputMonitor.num_learnt_codes = 0;
        }
    }
    else 
    {
        IR_RC_DEBUG(("IR: NO IR Config\n"));
    }
}


#else /* ENABLE_IR_REMOTE */

static const int dummy_ir_rc;  /* ISO C forbids an empty source file */

#endif /* ENABLE_IR_REMOTE */
