/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    power_charger.h

DESCRIPTION
    This file contains the monitoring of battery charging functionality.
    
    Once the battery charger is connected, charger is monitored and the
    charging state is repeatly reported to App.
NOTES
    
**************************************************************************/


#ifndef POWER_CHARGER_H_
#define POWER_CHARGER_H_


/****************************************************************************
NAME
    powerChargerDisconnected
    
DESCRIPTION
    Check if charger is disconnected or connected
    
RETURNS
    TRUE if disconnected, FALSE if connected
*/
#define powerChargerDisconnected() (power->chg_state == power_charger_disconnected)


/****************************************************************************
NAME
    powerChargerHandleMonitorReq
    
DESCRIPTION
    Monitor charger status (and handle boost enable/disable).
    
RETURNS
    void
*/
void powerChargerHandleMonitorReq(void);


/****************************************************************************
NAME
    powerChargerHandleVoltageReading
    
DESCRIPTION
    Calculate the current charger voltage and manage boost enable/disable.
    
RETURNS
    void
*/
void powerChargerHandleVoltageReading(uint16 reading);


/****************************************************************************
NAME
    powerChargerGetTrim
    
DESCRIPTION
    Read PSKEY_CHARGER_TRIM or set to invalid if not present.
    
RETURNS
    void
*/
void powerChargerGetTrim(void);


#endif /* POWER_CHARGER_H_ */


