/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    power_charger.c

DESCRIPTION
    This file contains the monitoring of battery charging functionality.

    Once the battery charger is connected, charger is monitored and the
    charging state is repeatly reported to App.

NOTES

**************************************************************************/


/****************************************************************************
    Header files
*/
#include "power.h"
#include "power_private.h"
#include "power_charger.h"
#include "power_init.h"
#include "power_monitor.h"

#include <stdlib.h>
#include <charger.h>
#include <ps.h>
#include <vm.h>

/* Make sure these are defined so lib builds on old SDK */
#ifndef CHARGER_USE_EXT_TRAN
#define CHARGER_USE_EXT_TRAN    0x05
#endif
#ifndef CHARGER_TERM_VOLTAGE
#define CHARGER_TERM_VOLTAGE    0x07
#endif

/* Voltage level: 0 - under limit or 1 - equal to or over limit */
#define powerChargerGetVoltageLevel() (power->vchg >= power->config.vchg.limit)
#define PSKEY_CHARGER_TRIM          (0x03B7)
#define PSKEY_CHARGER_TRIM_INVALID  (0xFF)


/****************************************************************************
NAME
    powerChargerReset

DESCRIPTION
    Turn the charger off and on again

RETURNS
    void
*/
static void powerChargerReset(void)
{
    ChargerConfigure(CHARGER_ENABLE, FALSE);
    /* If charger has not been disabled turn it back on */
    if(power->chg_state != power_charger_disabled)
        ChargerConfigure(CHARGER_ENABLE, TRUE);
}


/****************************************************************************
NAME
    powerChargerDisableBoost

DESCRIPTION
    Permanently disable internal/external boost until charger is detached

RETURNS
    void
*/
static void powerChargerDisableBoost(void)
{
    if(power->chg_state == power_charger_boost_internal)
    {
        PRINT(("POWER: Disable Internal Boost\n"));
        ChargerConfigure(CHARGER_ENABLE_BOOST, FALSE);
        powerChargerReset();
    }
    else if(power->chg_state == power_charger_boost_external)
    {
        PRINT(("POWER: Disable External Boost\n"));
        ChargerConfigure(CHARGER_USE_EXT_TRAN, FALSE);
    }
}



/****************************************************************************
NAME
    powerChargerGetState

DESCRIPTION
    Get current power library state for the charger (derived from f/w state)

RETURNS
    power_charger_state
*/
static power_charger_state powerChargerGetState(void)
{
    PRINT(("POWER: State "));

    switch(ChargerStatus())
    {
        case TRICKLE_CHARGE:
            PRINT(("TRICKLE_CHARGE "));
            PRINT(("power_charger_trickle\n"));
            return power_charger_trickle;
            break;
        case FAST_CHARGE:
            PRINT(("FAST_CHARGE "));
            if(power->chg_state < power_charger_complete)
            {
                if(power->chg_cycle_complete)
                    return power_charger_fast;

                switch(power->chg_boost)
                {
                    case power_boost_internal_enabled:
                        PRINT(("power_charger_boost_internal\n"));
                        return power_charger_boost_internal;
                    case power_boost_external_enabled:
                        PRINT(("power_charger_boost_external\n"));
                        return power_charger_boost_external;
                    default:
                        PRINT(("power_charger_fast\n"));
                        return power_charger_fast;
                }
            }
            break;
        case DISABLED_ERROR:
            PRINT(("DISABLED_ERROR power_charger_disabled\n"));
            return power_charger_disabled;
        case STANDBY:
            PRINT(("STANDBY power_charger_complete\n"));
            return power_charger_complete;
        case NO_POWER:
            PRINT(("NO_POWER power_charger_disconnected\n"));
            return power_charger_disconnected;
        default:
            break;
    }

    PRINT(("\n"));
    return power->chg_state;
}


/****************************************************************************
NAME
    powerChargerHandleMonitorReq

DESCRIPTION
    Monitor charger status (and handle boost enable/disable).

RETURNS
    void
*/
void powerChargerHandleMonitorReq(void)
{
    uint16  monitor_period = D_SEC(1);
    power_charger_state new_state = powerChargerGetState();
    int16   temperature;
    uint8   new_charger_current;

    PRINT(("PWR: ChgMonitor\n"));
    
    if(power->chg_state != new_state)
    {
        
        PRINT(("PWR: ChgMonitor: state change\n"));
        
        /* if the charger was previously disconnected */
        if (power->chg_state==power_charger_disconnected)
        {
            /* then update the state to say it has just been connected */
            new_state = power_charger_just_connected;
        }
    
        /* Don't send any messages unless init complete */
        if(POWER_INIT_GET(power_init_cfm_sent))
        {
            /* If the charge has been completed, mask out fast/trickle/etc... */
            switch (new_state)
            {
                case power_charger_trickle:
                case power_charger_fast:
                case power_charger_boost_internal:
                case power_charger_boost_external:
                    if (power->chg_cycle_complete)
                        break;
                    /* Fall-through to default case */
                default:
                {
                    MAKE_POWER_MESSAGE(POWER_CHARGER_STATE_IND);
                    message->state = new_state;
                    MessageSend(power->clientTask, POWER_CHARGER_STATE_IND, message);
                    break;
                }
            }
        }
        /* Charger connected/disconnected, restart monitoring and re-enable boost */
        if(power->chg_state == power_charger_disconnected || new_state == power_charger_disconnected)
        {
            power->chg_cycle_complete = FALSE;
            /* Wait until init complete to restart monitoring */
            if(POWER_INIT_GET(power_init_cfm_sent))
                powerMonitorRestart();
        }

        switch(new_state)
        {
            case power_charger_boost_internal:
                PRINT(("POWER: Enable Internal Boost\n"));
                ChargerConfigure(CHARGER_ENABLE_BOOST, TRUE);
            break;
            case power_charger_boost_external:
                PRINT(("POWER: Enable External Boost\n"));
                ChargerConfigure(CHARGER_USE_EXT_TRAN, TRUE);
            break;
            case power_charger_complete:
                power->chg_cycle_complete = TRUE;
                /* Fall-through to default case */
            default:
                /* Make sure we disable boost */
                powerChargerDisableBoost();
            break;
        }

        power->chg_state = new_state;
    }

    if (power->pmu_mon_enabled)
    {
        /* Load the present value of the charger current setting */
        new_charger_current = power->charger_i_setting;

        /* If the requested current is lower than the setting, reduce immediatley */
        if (new_charger_current > power->charger_i_target)
            new_charger_current = power->charger_i_target;

        /* Check the status of the charger */
        switch (ChargerStatus())
        {
            case DISABLED_ERROR:
            case STANDBY:
            {
                monitor_period = power->pmu_mon_config.monitor_period_idle;

                /* If the device is not charging, reduce the current to minimum */
                new_charger_current = power->pmu_mon_config.min_charge_i;
                PRINT(("PWR: ChgMonitor: Standby\n"));
                break;
            }
            case NO_POWER:
            {
                monitor_period = power->pmu_mon_config.monitor_period_nopwr;

                /* If the device is not charging, reduce the current to minimum */
                new_charger_current = power->pmu_mon_config.min_charge_i;
                PRINT(("PWR: ChgMonitor: no power\n"));
                break;
            }
            default:
            {
                PRINT(("PWR: ChgMonitor: default\n"));

                monitor_period = power->pmu_mon_config.monitor_period_active;

                /* Measure the PMU temperature */
                temperature = VmGetTemperatureBySensor(TSENSOR_PMU);

                if (temperature == INVALID_SENSOR)
                {
                    /* No PMU temperature sensor - set current now */
                    new_charger_current = power->charger_i_target;
                }
                else if (temperature == INVALID_TEMPERATURE)
                {
                    /* If the temperature could not be read, set the charger current to minimum */
                    new_charger_current = power->pmu_mon_config.min_charge_i;
                }
                else
                {
                    /* Check for the charger current setting being too high
                       or the PMU temperature being too high */
                    if (new_charger_current > power->charger_i_target
                        || temperature >= power->pmu_mon_config.decr_i_temp)
                    {
                        /* Reduce the current:
                           If the setting is larger than the step size, reduce by the step size
                           Else, set the current to minimum
                        */
                        if (new_charger_current >= power->pmu_mon_config.charger_i_step)
                            new_charger_current -= power->pmu_mon_config.charger_i_step;
                        else
                            new_charger_current = power->pmu_mon_config.min_charge_i;

                        /* Range-check the new setting */
                        if (new_charger_current < power->pmu_mon_config.min_charge_i)
                            new_charger_current = power->pmu_mon_config.min_charge_i;
                    }
                    /* Check for the charger current setting being below the target
                       AND that the temperature is below the no-increment temperature */
                    else if (new_charger_current < power->charger_i_target
                        && temperature < power->pmu_mon_config.no_incr_i_temp)
                    {
                        /* Increase current by the step-size */
                        new_charger_current += power->pmu_mon_config.charger_i_step;

                        /* Check that the current did not increase above the target */
                        if (new_charger_current > power->charger_i_target)
                            new_charger_current = power->charger_i_target;

                        /* Range-check the new setting */
                        if (new_charger_current > power->pmu_mon_config.max_charge_i)
                            new_charger_current = power->pmu_mon_config.max_charge_i;
                    }
                }
                break;
            }
        }

        /* Set the new charger current */
        if (new_charger_current != power->charger_i_setting){
            power->charger_i_setting = new_charger_current;
            ChargerConfigure(CHARGER_CURRENT, power->charger_i_setting);
        }
    }
    else
    {
        /* Original code before charger current control was added */
        if (power->chg_state == power_charger_disconnected)
            monitor_period = 0;
    }

    if (monitor_period)
    {
        PRINT(("PWR: ChgMonitor: reschedule\n"));
        MessageSendLater(&power->task, POWER_INTERNAL_CHG_MONITOR_REQ, NULL, monitor_period);
    }
    else
    {
        PRINT(("PWR: ChgMonitor: STOP MONTORING\n"));
    }
}


/****************************************************************************
NAME
    powerChargerHandleVoltageReading

DESCRIPTION
    Calculate the current charger voltage and manage boost enable/disable.

RETURNS
    void
*/
void powerChargerHandleVoltageReading(uint16 reading)
{
    bool old_level = powerChargerGetVoltageLevel();
    PRINT(("POWER: VCHG old - %u(mV) new - %u(mV)\n", power->vchg, reading));
    power->vchg = reading;

    if(POWER_INIT_GET(power_init_vchg))
    {
        bool new_level = powerChargerGetVoltageLevel();
        if(old_level != new_level)
        {
            MAKE_POWER_MESSAGE(POWER_CHARGER_VOLTAGE_IND);
            message->vchg.voltage = power->vchg;
            message->vchg.level   = new_level;
            MessageSend(power->clientTask, POWER_CHARGER_VOLTAGE_IND, message);
        }
    }
    else
    {
        POWER_INIT_SET(power_init_vchg);
    }
}


/****************************************************************************
NAME
    powerChargerGetTrim

DESCRIPTION
    Read PSKEY_CHARGER_TRIM or set to invalid if not present.

RETURNS
    void
*/
void powerChargerGetTrim(void)
{
    if(!PsFullRetrieve(PSKEY_CHARGER_TRIM, &power->ps_chg_trim, sizeof(uint8)))
        power->ps_chg_trim = PSKEY_CHARGER_TRIM_INVALID;
}


/****************************************************************************
NAME
    PowerChargerGetVoltage

DESCRIPTION
    Call this function to get the current charger voltage (in mV)

RETURNS
    bool
*/
bool PowerChargerGetVoltage(voltage_reading* vchg)
{
    if(POWER_INIT_GET(power_init_vchg))
    {
        vchg->voltage = power->vchg;
        vchg->level   = powerChargerGetVoltageLevel();
        return TRUE;
    }
    return FALSE;
}


/****************************************************************************
NAME
    PowerChargerGetState

DESCRIPTION
    The value pointed to by state will be set to the updated charger state
    unless state is NULL.

RETURNS
    void
*/
void PowerChargerGetState(power_charger_state* state)
{
    /* Set latest state */
    if(state) *state = power->chg_state;
}


/****************************************************************************
NAME
    PowerChargerMonitor

DESCRIPTION
    Enable/disable the charger monitoring. Monitoring is enabled by default
    but is disabled when charger detach is detected. It is up to the
    application to re-enable charger monitoring when the charger is attached

RETURNS
    void
*/
void PowerChargerMonitor(void)
{
    /* Restart charger monitoring */
    MessageCancelFirst(&power->task, POWER_INTERNAL_CHG_MONITOR_REQ);
    powerChargerHandleMonitorReq();
}


/****************************************************************************
NAME
    PowerChargerEnable

DESCRIPTION
    Enable/disable the charger.

RETURNS
    void
*/
void PowerChargerEnable(bool enable)
{
    PRINT(("POWER: Charger %s\n", (enable ? "Enable" : "Disable")));
    ChargerConfigure(CHARGER_ENABLE, enable);
}


/****************************************************************************
NAME
    PowerChargerSetCurrent

DESCRIPTION
    Set charger current level (actual current for each level (0-15) can be
    found in the data sheet for your chip). For newer chips such as Dale or
    Gordon the value in mA should be given (this value will be rounded to
    the nearest possible current setting).

RETURNS
    void
*/
void PowerChargerSetCurrent(uint8 current)
{
    if (power->pmu_mon_enabled){
        power->charger_i_target = current;

        if (current < power->charger_i_setting){
            power->charger_i_setting = current;
            ChargerConfigure(CHARGER_CURRENT, current);
        }
    } else {
        ChargerConfigure(CHARGER_CURRENT, current);
    }
}


/****************************************************************************
NAME
    PowerChargerSetBoost

DESCRIPTION
    Configure boost settings. By default this is disabled, but can be
    configured to draw boost current from internal/external transistor.
    Boost charge will be enabled on entering fast charge unless the boost
    cycle has already completed. The boost cycle is reset on charger attach.

RETURNS
    void
*/
void PowerChargerSetBoost(power_boost_enable boost)
{
    PRINT(("POWER: Charger Boost %d\n", boost));
    power->chg_boost = boost;
}


/****************************************************************************
NAME
    PowerChargerReduceTrim

DESCRIPTION
    Reduce the charger trim in order to reduce the termination voltage. This
    will fail if the value to reduce by is larger than the value stored in
    PS or charger trim configuration is not supported. On BC7 and later
    PowerChargerSetVterm should be used.

RETURNS
    bool
*/
bool PowerChargerReduceTrim(uint8 trim)
{
    /* If we have a valid PS charger trim and requested trim can be subtracted */
    if(power->ps_chg_trim != PSKEY_CHARGER_TRIM_INVALID && trim < power->ps_chg_trim)
    {
        /* Set reduced value if possible */
        return ChargerConfigure(CHARGER_TRIM, (power->ps_chg_trim - trim));
    }
    /* Unable to reduce trim */
    return FALSE;
}


/****************************************************************************
NAME
    PowerChargerSetVterm

DESCRIPTION
    Reduce the termination voltage to (vterm * POWER_VSCALE)(mV). This will
    fail if requested termination voltage is higher than the configured
    termination voltage. Prior to BC7 PowerChargerReduceTrim should be used.

RETURNS
    bool
*/
bool PowerChargerSetVterm(uint8 vterm)
{
    /* Attempt to reduce termination voltage */
    return ChargerConfigure(CHARGER_TERM_VOLTAGE, (vterm * POWER_VSCALE));
}
