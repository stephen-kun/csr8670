/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    power_monitor.c

DESCRIPTION
    This file contains the ADC monitoring functionality

NOTES

*/


/****************************************************************************
    Header files
*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "power.h"
#include "power_private.h"
#include "power_init.h"
#include "power_monitor.h"
#include "power_charger.h"

#define POWER_DEFAULT_VOLTAGE  0xFFFF


/****************************************************************************
NAME
    PowerInitComplete
    
DESCRIPTION
    Power library initialisation completed
*/
void PowerInitComplete(Task clientTask, bool success)
{
    MAKE_POWER_MESSAGE(POWER_INIT_CFM);
    message->success = success;
    
    if(success)
    {
        /* Set initial readings */
        PowerChargerGetVoltage(&message->vchg);
        PowerBatteryGetVoltage(&message->vbat);
        PowerBatteryGetTemperature(&message->vthm);
        PowerChargerGetState(&message->state);
        /* Record CFM sent so we don't send > 1 success */
        POWER_INIT_SET(power_init_cfm_sent);
        /* Charger connected during init, restart monitoring */
        if(power->chg_state != power_charger_disconnected)
            powerMonitorRestart();
    }
    
    MessageSend(clientTask, POWER_INIT_CFM, message);
}


/****************************************************************************
NAME
    PowerInit
    
DESCRIPTION
    This function will initialise the battery and its charging sub-system.
    The sub-systems manages the reading and calulation of the battery voltage
    and temperature, and the monitoring the charger status. 
*/
void PowerInit(Task clientTask, const power_config *config, const power_pmu_temp_mon_config *pmu_mon_config)
{
    if(config && !power)
    {
        /* Set up power task */
        power = PanicUnlessNew(power_type);
        
        /* ensure memory is initialised */
        memset(power,0,sizeof(power_type));
        
        power->clientTask   = clientTask;
        power->config       = *config;
        power->vref         = POWER_DEFAULT_VOLTAGE;
        power->vbat         = POWER_DEFAULT_VOLTAGE;
        power->vthm         = POWER_DEFAULT_VOLTAGE;
        power->vchg         = POWER_DEFAULT_VOLTAGE;
        power->chg_cycle_complete = FALSE;
        
        if (pmu_mon_config != NULL)
        {
            power->pmu_mon_config = *pmu_mon_config;
            power->charger_i_target = 0;
            power->charger_i_setting = 0;
            /* if the monitoring periods have been set then enable the pmu charger control */
            if(power->pmu_mon_config.monitor_period_active || power->pmu_mon_config.monitor_period_idle || power->pmu_mon_config.monitor_period_nopwr)
                power->pmu_mon_enabled = 1;
            /* otherwise disable it */
            else
                power->pmu_mon_enabled = 0;
        }
        else
        {
            power->pmu_mon_enabled = 0;
        }
        
        POWER_INIT_SET(power_init_start);
        powerChargerGetTrim();
        
        /* Start monitoring */
        powerMonitorInit();
        PowerChargerMonitor();
    }
    else
    {
        PowerInitComplete(clientTask, FALSE);
    }
}
