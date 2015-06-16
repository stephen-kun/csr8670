/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_powermanager.c
    
DESCRIPTION
    Module responsible for managing the battery monitoring and battery 
    charging functionaility
************************************************************************/

#include "sink_powermanager.h"
#include "sink_private.h"
#include "sink_statemanager.h"
#include "sink_led_manager.h"
#include "sink_audio.h"
#include "sink_pio.h"
#include "sink_csr_features.h"
#include "sink_led_manager.h"
#include "sink_leds.h"
#include "sink_debug.h"
#include "sink_display.h"

#include <pio.h>
#include <psu.h>
#include <vm.h>
#include <boot.h>
#include <ps.h>


#ifdef DEBUG_POWER
    #define PM_DEBUG(x) {printf x;}             
#else
    #define PM_DEBUG(x) 
#endif

static const sink_charge_setting default_charge_setting = 
{{FALSE, power_boost_disabled, vsel_chg, FALSE, FALSE, 0, 0},
{vterm_default, 0, 0}};

#ifdef ENABLE_BATTERY_OPERATION

static void powerManagerHandleVbat(voltage_reading vbat, battery_level_source source);

/****************************************************************************
NAME    
    powerManagerPowerOff
    
DESCRIPTION
    Power off due to critical battery or temperature outside operational
    limits
    
RETURNS
    void
*/
static void powerManagerPowerOff(void)
{
    if(stateManagerGetState() == deviceLimbo)
        stateManagerUpdateLimboState();
    else
        MessageSend(&theSink.task, EventUsrPowerOff, 0);
}


/****************************************************************************
NAME    
    powerManagerConfig
    
DESCRIPTION
    Configure power management
    
RETURNS
    void
*/
void powerManagerConfig(const power_config* config, const power_pmu_temp_mon_config* pmu_mon_config)
{
    uint16 level = 0;
    
    PM_DEBUG(("PM: Power Library Init\n"));
    PowerInit(&theSink.task, config, pmu_mon_config);
    theSink.battery_state = POWER_BATT_LEVEL3;   
    
    if ((theSink.conf1 != NULL) && (config != NULL))
    {
        /* store the charger termination voltage as the max battery voltage */
        theSink.rundata->battery_limits.max_battery_v = 0;
        PsFullRetrieve(PSKEY_CHARGER_CALC_VTERM, &theSink.rundata->battery_limits.max_battery_v, sizeof(uint16));    
        /* store the critical voltage as the min battery voltage */
        theSink.rundata->battery_limits.min_battery_v = 0;
    
        for (level = 0; level < POWER_MAX_VBAT_LIMITS; level++)
        {
            if ((theSink.conf1->power.bat_events[level].event) == EventSysBatteryCritical)
            {
                theSink.rundata->battery_limits.min_battery_v = config->vbat.limits[level].limit * POWER_VSCALE;
                break;
            }
        }
    }
}


/****************************************************************************
NAME    
    powerManagerChargerConnected
    
DESCRIPTION
    This function is called when the charger is plugged into the device
    
RETURNS
    void
*/
void powerManagerChargerConnected( void )
{
    PM_DEBUG(("PM: Charger has been connected\n"));
    /* Monitor charger state */
    PowerChargerMonitor();
    /* notify the audio plugin of the new power state */
    AudioSetPower(POWER_BATT_LEVEL3);
}


/****************************************************************************
NAME    
    powerManagerChargerDisconnected
    
DESCRIPTION
    This function is called when the charger is unplugged from the device
    
RETURNS
    void
*/
void powerManagerChargerDisconnected( void )
{
    PM_DEBUG(("PM: Charger has been disconnected\n"));  
    /* Immediately update charger */
    PowerChargerMonitor();
    powerManagerUpdateChargeCurrent();
    /* Cancel current LED indication */
    MessageSend(&theSink.task, EventSysCancelLedIndication, 0);
    /* Restore default bootmode */
    usbSetBootMode(BOOTMODE_DEFAULT);
}


/****************************************************************************
NAME    
    powerManagerIsChargerConnected
    
DESCRIPTION
    This function is called by applications to check whether the charger has 
    been plugged into the device
    
RETURNS
    bool
*/
bool powerManagerIsChargerConnected(void)
{
    /* Have to use trap, called before Power lib initialised */
    return (ChargerStatus() != NO_POWER);
}


/****************************************************************************
NAME    
    powerManagerIsChargerDisabled
    
DESCRIPTION
    This function is called by applications to check whether the charger has 
    been disabled
    
RETURNS
    bool
*/
bool powerManagerIsChargerDisabled(void)
{
    /* Have to use trap, called before Power lib initialised */
    return (ChargerStatus() == DISABLED_ERROR);
}


/****************************************************************************
NAME
    powerManagerIsChargerFullCurrent
    
DESCRIPTION
    This function is called by applications to check whether the charger is
    in (potentially) drawing full configured current.
    
RETURNS
    bool
*/
bool powerManagerIsChargerFullCurrent(void)
{
    /* Full current is only drawn in fast charge state */
    return (ChargerStatus() == FAST_CHARGE);
}


/****************************************************************************
NAME
    powerManagerIsVthmCritical
    
DESCRIPTION
    This function is called by applications to check whether the battery 
    temperature has reached critical level where the device must be powered
    off
    
RETURNS
    bool
*/
bool powerManagerIsVthmCritical(void)
{
    voltage_reading vthm;

    if(PowerBatteryGetTemperature(&vthm))
    {
        /* Check the power_off setting for this temperature */
        sink_charge_setting setting = theSink.conf1->power.chg_settings[vthm.level];
        PM_DEBUG(("PM: VTHM %s\n", setting.current.power_off ? "Critical" : "Okay"));
        return setting.current.power_off;
    }
    /* No temperature reading, wait until one available */
    PM_DEBUG(("PM: VTHM Okay\n"));
    return FALSE;
}


/****************************************************************************
NAME    
    powerManagerReadVbat
    
DESCRIPTION
    Call this function to take an immediate battery reading and sent to AG.
    
RETURNS
    void
*/
void powerManagerReadVbat(battery_level_source source)
{
    voltage_reading reading;
    if(PowerBatteryGetVoltage(&reading))
        powerManagerHandleVbat(reading, source);
}


/****************************************************************************
NAME    
    powerManagerHandleVbatCritical
    
DESCRIPTION
    Called when the battery voltage is detected to be in critical state
*/
static void powerManagerHandleVbatCritical( void )
{
    PM_DEBUG(("PM: Battery Critical\n"));
    /* Reset low batt warning */
    theSink.battery_state = POWER_BATT_CRITICAL;
    /* Power Off */
    if(!powerManagerIsChargerConnected())
    {
        powerManagerPowerOff();
    }
}


/****************************************************************************
NAME    
    powerManagerHandleVbatLow
    
DESCRIPTION
    Called when the battery voltage is detected to be in Battery Low state
*/
static void powerManagerHandleVbatLow( void )
{
    sinkState lSinkState = stateManagerGetState ();
    bool batt_was_low = powerManagerIsVbatLow();

    PM_DEBUG(("PM: Battery Low\n"));
    if(powerManagerIsChargerConnected() || lSinkState == deviceLimbo)
    {
        theSink.battery_state = POWER_BATT_LEVEL0;
    }
    else
    {
        theSink.battery_state = POWER_BATT_LOW;  
    }

    if(!batt_was_low || !powerManagerIsVbatLow())
    {
        /* update state indication to indicate low batt state change */
        LEDManagerIndicateState( lSinkState );
    }
    
    AudioSetPower(powerManagerGetLBIPM());
}


/****************************************************************************
NAME    
    batteryNormal
    
DESCRIPTION
    Called when the battery voltage is detected to be in a Normal state
*/
static void powerManagerHandleVbatNormal(uint8 level)
{
    bool low_batt = powerManagerIsVbatLow();
    PM_DEBUG(("PM: Battery Normal %d\n", level));
    MessageSend(&theSink.task, EventSysBatteryOk, 0);
    
    /* If charger connected send a charger gas gauge message (these don't have any functional use but can be associated with LEDs/tones) */
    if (powerManagerIsChargerConnected())
        MessageSend(&theSink.task, (EventSysChargerGasGauge0+level), 0);
    
    /* reset any low battery warning that may be in place */
    theSink.battery_state = POWER_BATT_LEVEL0 + level;
    csr2csrHandleAgBatteryRequestRes(level);

    /* when changing from low battery state to a normal state, refresh the led state pattern
       to replace the low battery pattern should it have been shown */
    if(low_batt) LEDManagerIndicateState(stateManagerGetState());
    
    AudioSetPower(powerManagerGetLBIPM());
}


/****************************************************************************
NAME    
    powerManagerHandleVbat
    
DESCRIPTION
    Called when the battery voltage is detected to be in a Normal state
*/
static void powerManagerHandleVbat(voltage_reading vbat, battery_level_source source)
{
    /* Get the event associated with this battery level */
    sink_battery_setting setting = theSink.conf1->power.bat_events[vbat.level];
    sinkEvents_t event = setting.event;

    PM_DEBUG(("PM: Battery Voltage 0x%02X (%dmV)\n", vbat.level, vbat.voltage));

    displayUpdateBatteryLevel(powerManagerIsChargerConnected());
    
    /* Send indication if not charging, not in limbo state and indication enabled for this source */
    if(!powerManagerIsChargerConnected() && (stateManagerGetState() != deviceLimbo) && (setting.sources & source))
    {
        PM_DEBUG(("PM: Sending Event 0x%X\n", event));
        MessageSend(&theSink.task, event, NULL);
    }
    
    switch(event)
    {
        case EventSysBatteryCritical:
            /* Always indicate critical battery */
            powerManagerHandleVbatCritical();
            usbSetVbatDead(TRUE);
            break;

        case EventSysBatteryLow:
            powerManagerHandleVbatLow();
            usbSetVbatDead(FALSE);
            break;

        case EventSysGasGauge0 :
        case EventSysGasGauge1 :
        case EventSysGasGauge2 :
        case EventSysGasGauge3 :
            powerManagerHandleVbatNormal(event - EventSysGasGauge0);
            usbSetVbatDead(FALSE);
            break;

        default:
            break;
    }
}


/****************************************************************************
NAME
    powerManagerHandleChargeState
    
DESCRIPTION
    Called when the charger state changes
*/
static void powerManagerHandleChargeState(power_charger_state state)
{
    PM_DEBUG(("PM: Charger State 0x%02X\n", state));
    if(!theSink.features.ChargerTerminationLEDOveride) 
    {
        /* Generate new message based on the reported charger state */
        switch(state)
        {
            case power_charger_trickle:
            case power_charger_fast:
            case power_charger_boost_internal:
            case power_charger_boost_external:
                PM_DEBUG(("PM: Charge In Progress\n"));
                MessageSend(&theSink.task, EventSysChargeInProgress, 0);
            break;
            case power_charger_complete:
                PM_DEBUG(("PM: Charge Complete\n"));
                MessageSend(&theSink.task, EventSysChargeComplete, 0);
            break;
            case power_charger_disconnected:
                PM_DEBUG(("PM: Charger Disconnected\n"));
            break;
            case power_charger_disabled:
                PM_DEBUG(("PM: Charger Disabled\n"));
                MessageSend(&theSink.task, EventSysChargeDisabled, 0);
            break;            
            case power_charger_just_connected:
                PM_DEBUG(("PM: Charger just connected\n"));
                /* do nothing, wait until the next monitoring period to update LEDs etc. */
            break;
            default:
                PM_DEBUG(("PM: Charger Unhandled!\n"));
            break;
        }
    }
}


/*************************************************************************
NAME    
    handlePowerMessage
    
DESCRIPTION
    handles the Battery/Charger Monitoring Messages

RETURNS
    
*/
void handlePowerMessage( Task task, MessageId id, Message message )
{
    switch(id)
    {
        case POWER_INIT_CFM:
        {
            POWER_INIT_CFM_T* cfm = (POWER_INIT_CFM_T*)message;
            PM_DEBUG(("PM: POWER_INIT_CFM\n"));
            if(!cfm->success) Panic();
            /* Update VBUS level */
            usbSetVbusLevel(cfm->vchg);
            /* Only indicate if low/critical (or intial reading feature enabled) */
            powerManagerHandleVbat(cfm->vbat, battery_level_initial_reading);
            /* Update charge current based on battery temperature */
            if (!powerManagerChargerSetup(&cfm->vthm))
            {
                /* and if the charger was left disabled then handle initial charge state 
                 * to notify the app that charger is disabled
                 */
                powerManagerHandleChargeState(cfm->state);
            }
        }
        break;

        case POWER_BATTERY_VOLTAGE_IND:
        {
            POWER_BATTERY_VOLTAGE_IND_T* ind = (POWER_BATTERY_VOLTAGE_IND_T*)message;
            PM_DEBUG(("PM: POWER_BATTERY_VOLTAGE_IND\n"));
            powerManagerHandleVbat(ind->vbat, battery_level_automatic);
            usbUpdateChargeCurrent();
        }
        break ;

        case POWER_CHARGER_VOLTAGE_IND:
        {
            PM_DEBUG(("PM: POWER_CHARGER_VOLTAGE_IND\n"));
            usbSetVbusLevel(((POWER_CHARGER_VOLTAGE_IND_T*)message)->vchg);
            usbUpdateChargeCurrent();
        }
        break;

        case POWER_BATTERY_TEMPERATURE_IND:
        {
            POWER_BATTERY_TEMPERATURE_IND_T* ind = (POWER_BATTERY_TEMPERATURE_IND_T*)message;
            PM_DEBUG(("PM: POWER_BATTERY_TEMPERATURE_IND\n"));
            powerManagerChargerSetup(&ind->vthm);
        }
        break;

        case POWER_CHARGER_STATE_IND:
        {
            POWER_CHARGER_STATE_IND_T* ind = (POWER_CHARGER_STATE_IND_T*)message;
            /* Send event if not using LED overide feature or state is currently not trickle charge */
            PM_DEBUG(("PM: POWER_CHARGER_STATE_IND\n"));
            powerManagerHandleChargeState(ind->state);
            /* NB. Charger state will not indicate a change from complete to fast. We assume this
            doesn't matter as we should run from VBUS when complete so battery should not run down */
            powerManagerUpdateChargeCurrent();
        }
        break ;
        
        default :
            PM_DEBUG(("PM: Unhandled Battery msg[%x]\n", id));
        break ;
    }
}


/****************************************************************************
NAME    
    powerManagerGetLBIPM
    
DESCRIPTION
    Returns the Power level to use for Low Battery Intelligent Power 
    Management (LBIPM).
    Note will always return high level if this feature is disabled.
    
RETURNS
    void
*/
power_battery_level powerManagerGetLBIPM( void )                             
{
    PM_DEBUG(("PM: Battery Management %s\n", theSink.lbipmEnable ? "Enabled" : "Disabled"));
    PM_DEBUG(("PM: Using %s Level ", powerManagerIsChargerConnected() ? "Chg" : "Batt"));
    PM_DEBUG(("%d\n", powerManagerIsChargerConnected() ? POWER_BATT_LEVEL3 : theSink.battery_state));

    /* Get current battery level */
    if(theSink.lbipmEnable && !powerManagerIsChargerConnected())
        return theSink.battery_state;
    
    /* LBIPM disabled or charger is connected so use full power level */
    return POWER_BATT_LEVEL3;
}


/****************************************************************************
NAME    
    powerManagerChargerSetup
    
DESCRIPTION
    Update the charger settings based on USB limits and provided temperature
    reading. Updates current, trim, boost charge settings and enables or 
    disables the charger. On BC7 this can also be used to select whether the
    chip draws power from VBAT or VBYP.
    
RETURNS
    bool
*/
bool powerManagerChargerSetup(voltage_reading* vthm)
{
    /* Get temperature limits */
    sink_charge_current* usb_limits = usbGetChargeCurrent();
    sink_charge_setting setting;

    PM_DEBUG(("PM: Set Current\n"));

    if(vthm)
    {
        PM_DEBUG(("PM: Temp 0x%02X %dmV\n", vthm->level, vthm->voltage));
        setting = theSink.conf1->power.chg_settings[vthm->level];
    }
    else
    {
        PM_DEBUG(("PM: No Temp Reading\n"));
        setting = default_charge_setting;
    }
    
    if(usb_limits)
    {
        /* Apply minimum settings from combined limits */
        setting.current.charge = usb_limits->charge & setting.current.charge;
        if(usb_limits->boost < setting.current.boost)
            setting.current.boost = usb_limits->boost;
        setting.current.vsel = usb_limits->vsel | setting.current.vsel;
        setting.current.disable_leds = usb_limits->disable_leds | setting.current.disable_leds;
        if(usb_limits->current < setting.current.current)
            setting.current.current = usb_limits->current;
    }
    
    if(!powerManagerIsChargerConnected())
    {
        /* Must apply these settings when charger removed */
        setting.current.boost  = power_boost_disabled;
        setting.current.charge = FALSE;
#ifdef HAVE_VBAT_SEL
        setting.current.vsel   = vsel_bat;
    }
    else if(setting.current.power_off)
    {
        /* If outside operating temp cannot run from battery */
        setting.current.vsel = vsel_chg;
#endif
    }

    switch(setting.termination.type)
    {
        case vterm_voltage:
            /* BC7 allows us to set absolute termination voltage */
            PM_DEBUG(("PM: Termination Voltage %d\n", setting.termination.voltage * POWER_VSCALE));
            if(!PowerChargerSetVterm(setting.termination.voltage))
            {
                PM_DEBUG(("PM: Failed, disabling charger\n"));
                setting.current.charge = FALSE;
            }
        break;
        case vterm_trim:
            /* BC5 needs to modify trim setting */
            PM_DEBUG(("PM: Trim Termination Voltage -%d\n", setting.termination.trim));
            /* Disable charger if unable to trim */
            if(!PowerChargerReduceTrim(setting.termination.trim))
            {
                PM_DEBUG(("PM: Failed, disabling charger\n"));
                setting.current.charge = FALSE;
            }
        break;
        default:
            /* Use default termination voltage */
            PM_DEBUG(("PM: Termination Voltage Unchanged\n"));
        break;
    }

    /* Disable LEDs if required */
    PM_DEBUG(("PM: %s LEDs\n", setting.current.disable_leds ? "Disable" : "Enable"));
    LedManagerForceDisable(setting.current.disable_leds);
    
    /* With VBAT_SEL we can wait for temp reading before enabling charger. 
       Without we enable charger by default and may need to turn it off. */
    if(vthm)
    {
        PM_DEBUG(("PM: Current %d, Boost 0x%X\n", setting.current.current, setting.current.boost));
        PM_DEBUG(("PM: Charger %s\n", (setting.current.charge ? "Enabled" : "Disabled")));
        
        /* Set charge current */
        PowerChargerSetCurrent(setting.current.current);
        PowerChargerSetBoost(setting.current.boost);

#ifdef HAVE_VBAT_SEL
    }
    /* Flip the switch to draw current from VBAT or VBYP */
    PM_DEBUG(("PM: SEL %s\n", ((setting.current.vsel == vsel_bat) ? "VBAT" : "VBYP") ));
    PsuConfigure(PSU_VBAT_SWITCH, PSU_SMPS_INPUT_SEL_VBAT, ((setting.current.vsel == vsel_bat) ? TRUE : FALSE));

    if(vthm)
    {
#endif
        /* Enable/disable charger */
        PowerChargerEnable(setting.current.charge);

        /* Power off */
        if(setting.current.power_off)
        {
            PM_DEBUG(("PM: Power Off\n"));
            powerManagerPowerOff();
        }
    }
    return((vthm) && (setting.current.charge));
}


/****************************************************************************
NAME    
    powerManagerChargerSetup
    
DESCRIPTION
    Update the charger settings based on latest reading of VTHM
    
RETURNS
    void
*/
void powerManagerUpdateChargeCurrent(void)
{
    voltage_reading vthm;
    /* If power library intialised setup charger */
    if(PowerBatteryGetTemperature(&vthm))
        powerManagerChargerSetup(&vthm);
    else
        powerManagerChargerSetup(NULL);
}

#endif /* battery operation disabled */

/****************************************************************************
NAME    
    powerManagerCheckPanic
    
DESCRIPTION
    Check if the last reset was caused by Panic/ESD
    
RETURNS
    void
*/
#ifdef INSTALL_PANIC_CHECK
void powerManagerCheckPanic(void)
{
    vm_reset_source rst_src = VmGetResetSource();
    vm_power_enabler en_src = VmGetPowerSource();

    theSink.panic_reconnect = FALSE;
    /* Is panic check enabled */
    if(theSink.features.ReconnectOnPanic)
        if(rst_src == RESET_SOURCE_FIRMWARE || rst_src == UNEXPECTED_RESET || en_src == POWER_ENABLER_RESET_PROTECTION)
            theSink.panic_reconnect = TRUE;

    PM_DEBUG(("PM: Power %d, Reset %d, Old State %d %sReconnect\n", en_src, rst_src, theSink.rundata->old_state, theSink.panic_reconnect ? "":"Don't "));
}
#endif


