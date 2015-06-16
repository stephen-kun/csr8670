/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_power.c

DESCRIPTION
    Handles power readings when running as a self powered device.    

*/


/* header for this file */
#include "source_power.h"
/* application header files */
#include "source_debug.h"
#include "source_led_handler.h"
#include "source_private.h"
#include "source_states.h"
/* VM headers */
#include <charger.h>
#include <panic.h>
#include <psu.h>
/* profile/library headers */
#include <power.h>


#ifdef DEBUG_POWER
    #define POWER_DEBUG(x) DEBUG(x)
#else
    #define POWER_DEBUG(x)
#endif


#ifdef INCLUDE_POWER_READINGS


/****************************************************************************
NAME    
    power_handle_battery_voltage
    
DESCRIPTION
    Called when the battery voltage is returned.
    
*/
static void power_handle_battery_voltage(voltage_reading vbat)
{
    power_battery_level level = vbat.level;
    
    POWER_DEBUG(("PM: Battery voltage[0x%x] level[%d]\n", vbat.voltage, vbat.level));
        
    if (!power_is_charger_connected())
    {   
        switch (states_get_state())
        {
            case SOURCE_STATE_IDLE:
            case SOURCE_STATE_CONNECTABLE:
            case SOURCE_STATE_DISCOVERABLE:
            case SOURCE_STATE_INQUIRING:
            case SOURCE_STATE_CONNECTING:
            case SOURCE_STATE_CONNECTED:
            {
                switch (level)
                {
                    case POWER_BATT_CRITICAL:
                    {
                        POWER_DEBUG(("    Critical battery\n"));

                        /* power off device */
                        states_set_state(SOURCE_STATE_POWERED_OFF);
                    }
                    break;
                    
                    case POWER_BATT_LOW:
                    {
                        POWER_DEBUG(("    Low battery\n"));
                        
#ifdef INCLUDE_LEDS            
                        /* show low battery LED */
                        leds_show_event(LED_EVENT_LOW_BATTERY);
#endif                                 
                    }
                    break;
                    
                    default:
                    {
                    }
                    break;
                }
            }
            break;
            
            default:
            {
            }
            break;
        }
    }
}


/****************************************************************************
NAME    
    power_handle_battery_temp
    
DESCRIPTION
    Called when the battery temperature is returned.
    
*/
static void power_handle_battery_temp(voltage_reading vthm)
{
    POWER_DEBUG(("PM: Battery temp voltage[0x%x] level[%d]\n", vthm.voltage, vthm.level));
    
    if (power_is_charger_connected())
    {
        /* Enable charger */
        PowerChargerEnable(TRUE);
    }
}


/****************************************************************************
NAME    
    power_handle_charge_state
    
DESCRIPTION
    Called when the charge state is returned.
    
*/
static void power_handle_charge_state(power_charger_state state)
{
    POWER_DEBUG(("PM: Charger State [%d]\n", state));
    
    switch(state)
    {
        case power_charger_trickle:
        case power_charger_fast:
        case power_charger_boost_internal:
        case power_charger_boost_external:
        {
            POWER_DEBUG(("PM: Charge In Progress\n"));
        }   
        break;
        
        case power_charger_complete:
        {
            POWER_DEBUG(("PM: Charge Complete\n"));
        }
        break;
        
        case power_charger_disconnected:
        {
            POWER_DEBUG(("PM: Charger Disconnected\n"));
        }
        break;
        
        case power_charger_disabled:
        {
            POWER_DEBUG(("PM: Charger Disabled\n"));
        }
        break;
        
        default:
        {
            POWER_DEBUG(("PM: Charger Unhandled!\n"));
        }
        break;
    }
}


/****************************************************************************
NAME    
    power_handle_charge_voltage
    
DESCRIPTION
    Called when the charge voltage is returned.
    
*/
static void power_handle_charge_voltage(voltage_reading vchg)
{
    POWER_DEBUG(("PM: Charge voltage[0x%x] level[%d]\n", vchg.voltage, vchg.level));
}
    

static void power_msg_handler(Task task, MessageId id, Message message)
{
    switch(id)
    {
        case POWER_INIT_CFM:
        {
            POWER_INIT_CFM_T *cfm = (POWER_INIT_CFM_T *)message;
            
            POWER_DEBUG(("POWER_INIT_CFM\n"));
            
            if (!cfm->success) 
                Panic();
            
            /* handle returned charge state */
            power_handle_charge_state(cfm->state);
            /* handle returned battery voltage */
            power_handle_battery_voltage(cfm->vbat);
            /* handle returned battery temperature */
            power_handle_battery_temp(cfm->vthm);
        }
        break;
        
        case POWER_BATTERY_VOLTAGE_IND:
        {
            POWER_BATTERY_VOLTAGE_IND_T *ind = (POWER_BATTERY_VOLTAGE_IND_T *)message;
            
            POWER_DEBUG(("POWER_BATTERY_VOLTAGE_IND\n"));
            
            /* handle returned battery voltage */
            power_handle_battery_voltage(ind->vbat);
        }
        break;
        
        case POWER_CHARGER_VOLTAGE_IND:
        {
            POWER_CHARGER_VOLTAGE_IND_T *ind = (POWER_CHARGER_VOLTAGE_IND_T *)message;
            
            POWER_DEBUG(("POWER_CHARGER_VOLTAGE_IND\n"));
            
            /* handle returned charge voltage */
            power_handle_charge_voltage(ind->vchg);
        }
        break;
        
        case POWER_BATTERY_TEMPERATURE_IND:
        {
            POWER_BATTERY_TEMPERATURE_IND_T *ind = (POWER_BATTERY_TEMPERATURE_IND_T *)message;
            
            POWER_DEBUG(("POWER_BATTERY_TEMPERATURE_IND\n"));
            
            /* handle returned battery temperature */
            power_handle_battery_temp(ind->vthm);
        }
        break;
        
        case POWER_CHARGER_STATE_IND:
        {
            POWER_CHARGER_STATE_IND_T *ind = (POWER_CHARGER_STATE_IND_T *)message;
            
            POWER_DEBUG(("POWER_CHARGER_STATE_IND\n"));
            
            /* handle returned charge state */
            power_handle_charge_state(ind->state);
        }
        break;
        
        default:
        {
            POWER_DEBUG(("Unhandled Power message 0x%x\n", id));
        }
        break;
    }
}


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    power_init - Initialises the power manager.
 
*/
void power_init(void)
{
    theSource->powerTask.handler = power_msg_handler;
    PowerInit(&theSource->powerTask, &theSource->ps_config->pwr_config.power);
}


#endif /* INCLUDE_POWER_READINGS */
    

/****************************************************************************
NAME    
    power_is_charger_connected - Called to see if the charger is connected
    
*/
bool power_is_charger_connected(void)
{
    return (ChargerStatus() != NO_POWER);
}

