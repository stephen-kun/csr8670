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
#include "power.h"
#include "power_private.h"
#include "power_init.h"
#include "power_monitor.h"
#include "power_battery.h"
#include "power_charger.h"

#include <pio_common.h>
#include <adc.h>
#include <pio.h>
#include <stdlib.h>
#include <vm.h>

#define PIO_MASK(pio) (((uint32)1) << pio)


power_type* power;


/****************************************************************************
NAME
    powerMonitorSetThermistorPio
    
DESCRIPTION
    Drive the thermistor
*/
static void powerMonitorSetThermistorPio(bool drive)
{
    if(power->config.vthm.drive_pio)
    {
        PRINT(("POWER: Set Thermistor PIO %d\n", drive));
        PioCommonSetPin(power->config.vthm.pio, pio_drive, drive);
    }
}


/****************************************************************************
NAME
    powerMonitorConfigureThermistorPio
    
DESCRIPTION
    Configure the thermistor PIO
*/
static bool powerMonitorConfigureThermistorPio(void)
{
    PRINT(("POWER: Thermistor Config "));
    if(power->config.vthm.drive_pio)
    {
        PRINT(("Thermistor PIO %d\n", power->config.vthm.pio));
        return PioCommonSetPin(power->config.vthm.pio, pio_drive, FALSE);
    }
    PRINT(("\n"));
    return TRUE;
}


/****************************************************************************
NAME
    powerMonitorReadAdc
    
DESCRIPTION
    Queue an ADC reading
*/
static void powerMonitorReadAdc(Task task, MessageId id, uint32 period)
{
    MessageSendLater(task, id, NULL, period);
}


/****************************************************************************
NAME
    powerMonitorReadAdcNow
    
DESCRIPTION
    Attempt to take an ADC reading, if this fails queue a retry
*/
static bool powerMonitorReadAdcNow(Task task, MessageId id, power_adc* adc, power_init_mask mask)
{
    uint32 period = D_SEC(powerChargerDisconnected() ? adc->period_no_chg : adc->period_chg);
    
    /* Make sure init doesn't stall */
    if(!period)
    {
        POWER_INIT_SET(mask);
        return TRUE;
    }
    
    /* Don't allow any additional readings until VREF has been measured */
    if(mask == power_init_vref || POWER_INIT_GET(power_init_vref))
    {
        /* Request ADC Reading */
        if(AdcRequest(task, adc->source))
        {
            /* Successful request, queue next monitor */
            powerMonitorReadAdc(task, id, period);
            return TRUE;
        }
    }
    
    /* Failed */
    return FALSE;
}


/****************************************************************************
NAME
    powerMonitorHandler
    
DESCRIPTION
    Power library message handler.
*/
static void powerMonitorHandler(Task task, MessageId id, Message message)
{
    switch(id)
    {
        case POWER_INTERNAL_VREF_REQ:
            /* Queue retry if ADC read fails */
            if(!powerMonitorReadAdcNow(task, id, &power->config.vref.adc, power_init_vref))
                powerMonitorReadAdc(task, id, 0);
        break;
        
        case POWER_INTERNAL_VBAT_REQ:
            /* Queue retry if ADC read fails */
            if(!powerMonitorReadAdcNow(task, id, &power->config.vbat.adc, power_init_vbat))
                powerMonitorReadAdc(task, id, 0);
        break;
        
        case POWER_INTERNAL_VCHG_REQ:
            /* Queue retry if ADC read fails */
            if(!powerMonitorReadAdcNow(task, id, &power->config.vchg.adc, power_init_vchg))
                powerMonitorReadAdc(task, id, 0);
        break;
        
        case POWER_INTERNAL_VTHM_SETUP:
            /* Set PIO and queue ADC read */
            powerMonitorSetThermistorPio(TRUE);
            powerMonitorReadAdc(task, POWER_INTERNAL_VTHM_REQ, power->config.vthm.delay);
        break;
        
        case POWER_INTERNAL_VTHM_REQ:
            /* Queue next setup if successful, otherwise queue immediate retry of ADC read */
            if(!powerMonitorReadAdcNow(task, POWER_INTERNAL_VTHM_SETUP, &power->config.vthm.adc, power_init_vthm))
                powerMonitorReadAdc(task, POWER_INTERNAL_VTHM_REQ, 0);
        break;
        
        case POWER_INTERNAL_CHG_MONITOR_REQ:
            powerChargerHandleMonitorReq();
        break;
        
        case POWER_INTERNAL_VBAT_NOTIFY_REQ:
            powerBatterySendVoltageInd();
        break;
        
        case MESSAGE_ADC_RESULT:
        {
            MessageAdcResult* result  = (MessageAdcResult*)message;
            uint16            reading = result->reading;
            
            if(result->adc_source == power->config.vref.adc.source)
            {
                /* Store reading */
                power->vref = reading;
                PRINT(("POWER: VREF %u(ADC counts), VREF Constant %u\n", power->vref, VmReadVrefConstant()));
                POWER_INIT_SET(power_init_vref);
            }
            else
            {
#ifdef BC5MM
                /* voltage(mV) = reading(ADC counts) * (mv_per_count = VREF(mV)/VREF(ADC counts)) */
                uint16 res = ((uint32)((uint32)(VmReadVrefConstant()) * (uint32)reading)) / power->vref;
                PRINT(("POWER: BC5MM res %u\n", res));
#else            
                /* On BC7 platforms, there is an issue whereby the VREF voltage is unstable and inaccurate and
                   is not read by the same ADC as vbat/vchg, therefore when calculating values for VBAT etc, 
                   substitue a fixed reference value instead to improve accuracy of these readings */
                uint16 res;
                
                /* for inputs of vbat,vchg, use a fixed reference voltage to improve accuracy, VREF is on
                   a different ADC to that of the vbat/vchg inputs and hence not accurate to use in calculations */
                if (result->adc_source>adcsel_vref) 
                {
                    /* for inputs other than AIOs voltage(mV) = reading(ADC counts) * (1350mV/1024) */
                    res = (uint32)reading * 1350 / 1024;
                } 
                /* for aio inputs continue to use the VREF reading which comes from the same ADC as the aio inputs */
                else 
                {
                    /* for AIOs voltage(mV) = reading(ADC counts) * (mv_per_count = VREF(mV)/VREF(ADC counts)) */
                    res = ((uint32)((uint32)VmReadVrefConstant() * (uint32)reading)) / power->vref;
                }
                PRINT(("POWER: BC7 res %u\n", res));
#endif
                /* Processing the reading results */
                if(result->adc_source == power->config.vthm.adc.source)
                {
                    powerMonitorSetThermistorPio(FALSE);
                    PRINT(("POWER: Thermistor %s\n", power->config.vthm.raw_limits ? "Raw" : "Voltage"));
                    powerBatteryHandleTemperatureReading(power->config.vthm.raw_limits ? reading : res);
                }
                else if(result->adc_source == power->config.vbat.adc.source)
                {
                    PRINT(("POWER: BatVoltage counts %d mV %d vref = %d\n", reading, res, power->vref));
                    powerBatteryHandleVoltageReading(res);
                }
                else if(result->adc_source == power->config.vchg.adc.source)
                {
                    PRINT(("POWER: ChgVoltage counts %d mV %d vref = %d\n", reading, res, power->vref));
                    powerChargerHandleVoltageReading(res);
                }
                else
                {
                    Panic();
                }
            }
            
            if(POWER_INIT_IS_COMPLETE())
            {
                /* We have all our initial readings */
                PRINT(("POWER: INIT COMPLETE\n"));
                PowerInitComplete(power->clientTask, TRUE);
            }
        }
        break;
        
        default:
            Panic();
        break;
    }
}


/****************************************************************************
NAME
    powerMonitorStart
    
DESCRIPTION
    Start monitoring all values.
*/
static void powerMonitorStart(void)
{
    /* Start monitoring by taking VREF measurement*/
    powerMonitorReadAdc(&power->task, POWER_INTERNAL_VREF_REQ, 0);
    powerMonitorReadAdc(&power->task, POWER_INTERNAL_VTHM_SETUP, 0);
    powerMonitorReadAdc(&power->task, POWER_INTERNAL_VCHG_REQ, 0);
    powerMonitorReadAdc(&power->task, POWER_INTERNAL_VBAT_REQ, 0);
}


/****************************************************************************
NAME
    powerMonitorRestart
    
DESCRIPTION
    Restart monitoring all values.
*/
void powerMonitorRestart(void)
{
    /* Cancel all pending monitor requests */
    MessageCancelAll(&power->task, POWER_INTERNAL_VREF_REQ);
    MessageCancelAll(&power->task, POWER_INTERNAL_VTHM_SETUP);
    MessageCancelAll(&power->task, POWER_INTERNAL_VTHM_REQ);
    MessageCancelAll(&power->task, POWER_INTERNAL_VCHG_REQ);
    MessageCancelAll(&power->task, POWER_INTERNAL_VBAT_REQ);
    /* Restart monitoring */
    powerMonitorStart();
}

/****************************************************************************
NAME
    powerMonitorInit
    
DESCRIPTION
    Initialise power monitoring
*/
void powerMonitorInit(void)
{
    power->task.handler = powerMonitorHandler;
    PanicFalse(powerMonitorConfigureThermistorPio());
    powerMonitorStart();
}
