/*************************************************************************
 Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
 Part of ADK 3.5

FILE : 
    power.h

CONTAINS:
    API for the Battery power monitoring and charger management

**************************************************************************/


#ifndef POWER_H_
#define POWER_H_

#include <adc.h>
#include <charger.h>
#include <library.h>

#define POWER_MAX_VTHM_LIMITS   0x07
#define POWER_MAX_VBAT_LIMITS   0x05
#define POWER_MAX_VTHM_REGIONS  (POWER_MAX_VTHM_LIMITS + 1)
#define POWER_MAX_VBAT_REGIONS  (POWER_MAX_VBAT_LIMITS + 1)
#define POWER_VBAT_LIMIT_END    0xFF
#define POWER_VTHM_LIMIT_END    0xFFFF
#define POWER_VSCALE            0x14

/*!
    @brief Define the types for the upstream messages sent from the Power
    library to the application.
*/
typedef enum
{
/* 0x7800 */    POWER_INIT_CFM = POWER_MESSAGE_BASE,
/* 0x7801 */    POWER_BATTERY_VOLTAGE_IND, 
/* 0x7802 */    POWER_BATTERY_TEMPERATURE_IND,
/* 0x7803 */    POWER_CHARGER_VOLTAGE_IND,
/* 0x7804 */    POWER_CHARGER_STATE_IND, 
/* 0x7805 */    POWER_MESSAGE_TOP
}PowerMessageId ;

/*! 
    @brief Charger state
*/
typedef enum
{
    power_charger_disconnected,
    power_charger_disabled,
    power_charger_trickle,
    power_charger_just_connected,
    power_charger_fast,
    power_charger_boost_internal,
    power_charger_boost_external,
    power_charger_complete
} power_charger_state;

/*! 
    @brief Boost setting
*/
typedef enum
{
    power_boost_disabled,
    power_boost_internal_enabled,
    power_boost_external_enabled
} power_boost_enable;

/*! 
    @brief ADC monitoring info
*/
typedef struct
{
    vm_adc_source_type source:8;      /* The ADC source */
    unsigned           period_chg:8;  /* Interval (in seconds) between measurements when charging */
    uint16             period_no_chg; /* Interval (in seconds) between measurements when not charging */
} power_adc;

/*! 
    @brief VREF Configuration
*/
typedef struct
{
    power_adc           adc;                /* VREF ADC */
} power_vref_config;

/*! 
    @brief Battery Limit Setting
*/
typedef struct
{
    unsigned notify_period:8;       /* Interval (in minutes) between notifcations (0 to disable) */
    unsigned limit:8;               /* Battery Voltage Threshold (mV/POWER_VSCALE)*/
} power_vbat_limit;

/*! 
    @brief Battery Configuration
*/
typedef struct
{
    power_adc           adc;                            /* Battery Voltage ADC */
    power_vbat_limit    limits[POWER_MAX_VBAT_REGIONS]; /* Battery Voltage Thresholds Settings */
} power_vbat_config;

/*!
    @brief Thermistor Configuration. VTHM is read from an external 
    AIO. Limits can be calculated from your thermistor's data sheet, 
    where T is the resistance of the thermistor for given temperature 
    and R is a fixed resistor:
    
    VSRC -------
                |
                R                VSRC(mV) x T
                |---- VTHM(mV) = ------------
                T                   T + R
                |
                _
                -
    
    Where VSRC is the same source as the ADC we can configure limits 
    in terms of raw ADC counts in place of the calculated voltage 
    for improved accuracy:
    
                       VSRC(ADC Counts) x T
    VTHM(ADC Counts) = --------------------
                              T + R
    
    VSRC(ADC Counts) = VADC(ADC Counts) = Max ADC Counts.
    
    NOTES:
    - Thermistor may be driven from a constant source or via a PIO
    - ADC readings are 10 bits: Max ADC Counts = 1023.
    - ADC readings will saturate above ADC source voltage, on BC5/BC6 
    this is 1.5v, on BC7 1.35v. No limit should be set above this level.
*/
typedef struct
{
    power_adc           adc;                           /* Thermistor ADC */
    unsigned            delay:4;                       /* Delay(ms) between setting PIO and reading ADC */
    unsigned            unused:5;                      /* Unused */
    unsigned            raw_limits:1;                  /* Set limits in ADC counts rather than voltage */
    unsigned            drive_pio:1;                   /* Drive thermistor from a PIO */
    unsigned            pio:5;                         /* PIO to use (0-31)*/
    uint16              limits[POWER_MAX_VTHM_LIMITS]; /* Voltage Thresholds (mV/ADC Counts) */
} power_vthm_config;

/*! 
    @brief Charger Configuration
*/
typedef struct
{
    power_adc           adc;                /* VCHG ADC */
    uint16              limit;              /* VCHG Threshold (mV/POWER_VSCALE) */
} power_vchg_config;


/*!
    @brief  PMU temperature based charging control configuration
*/
typedef struct
{
    unsigned            min_charge_i:8;         /*!< Minimum charger current */
    unsigned            max_charge_i:8;         /*!< Maximum charger current */
    unsigned            charger_i_step:8;       /*!< Charger current step-size */
    unsigned            unused:8;               /*!< Not used (set to 0) */
    unsigned            no_incr_i_temp:8;       /*!< Temeprature (degC) where current will not be increased */
    unsigned            decr_i_temp:8;          /*!< Temeprature (degC) where current will be decreased */
    uint16              monitor_period_active;  /*!< Period (ms) to monitor PMU temperature when charger is active */
    uint16              monitor_period_idle;    /*!< Period (ms) to monitor PMU temperature when charger is idle */
    uint16              monitor_period_nopwr;   /*!< Period (ms) to monitor PMU temperature when there is no charger power */
} power_pmu_temp_mon_config;

/*! 
    @brief Battery Level 
*/
typedef enum
{
    POWER_BATT_CRITICAL,           /* when voltage (mV) < level0 * POWER_VSCALE */
    POWER_BATT_LOW,                /* when voltage (mV) < level1 * POWER_VSCALE */
    POWER_BATT_LEVEL0,             /* when voltage (mV) < level2 * POWER_VSCALE */
    POWER_BATT_LEVEL1,             /* when voltage (mV) < level3 * POWER_VSCALE */
    POWER_BATT_LEVEL2,             /* when voltage (mV) < level4 * POWER_VSCALE */
    POWER_BATT_LEVEL3              /* when voltage (mV) < level5 * POWER_VSCALE */
}power_battery_level;

/*!
    @brief Power Library Configuration
*/
typedef struct
{
    power_vref_config    vref;    /* VREF Config */
    power_vbat_config    vbat;    /* Battery config */
    power_vthm_config    vthm;    /* Thermistor config */
    power_vchg_config    vchg;    /* Charger config */
} power_config;

/*!
    @brief Contains voltage and level
*/
typedef struct
{
    uint16 voltage;
    uint8  level;
} voltage_reading;

/*!
    @brief This message is returned when the battery and charger monitoring 
    subsystem has been initialised.
*/
typedef struct
{
    bool            success;
    voltage_reading vthm;
    voltage_reading vbat;
    voltage_reading vchg;
    power_charger_state state;
} POWER_INIT_CFM_T;

/*!
    @brief This message is sent to App to indicate the battery voltage level and its value.
*/
typedef struct
{
    voltage_reading vbat;
} POWER_BATTERY_VOLTAGE_IND_T;

/*!
    @brief This message is sent to App to indicate the temperature level and its value.
*/
typedef struct
{
    voltage_reading vthm;
} POWER_BATTERY_TEMPERATURE_IND_T;

/*!
    @brief This message is sent to App to indicate the charger voltage level and its value.
*/
typedef struct
{
    voltage_reading vchg;
} POWER_CHARGER_VOLTAGE_IND_T;

/*!
    @brief This message is sent to App to indicate the charging state.
*/
typedef struct
{
    power_charger_state   state;
} POWER_CHARGER_STATE_IND_T;


/****************************************************************************
NAME    
    PowerInit
    
DESCRIPTION
    This function will initialise the battery and battery charging sub-system
    The sub-system manages the reading and calulation of the battery voltage 
    and temperature
    
    The application will receive a POWER_INIT_CFM message from the 
    library indicating the initialisation status.
    
RETURNS
    void
*/
void PowerInit(Task clientTask, const power_config *power_data, const power_pmu_temp_mon_config *pmu_mon_config);


/****************************************************************************
NAME
    PowerBatteryGetVoltage
    
DESCRIPTION
    Call this function to get the current battery voltage (in mV) and the 
    level
 
RETURNS
    bool
*/
bool PowerBatteryGetVoltage(voltage_reading* vbat);


/****************************************************************************
NAME
    PowerBatteryGetTemperature
    
DESCRIPTION
    Call this function to get the current thermistor voltage (in mV) and the
    level
    
RETURNS
    bool
*/
bool PowerBatteryGetTemperature(voltage_reading *vthm);


/****************************************************************************
NAME
    PowerChargerGetVoltage
    
DESCRIPTION
    Call this function to get the current charger voltage (in mV)
    
RETURNS
    bool
*/
bool PowerChargerGetVoltage(voltage_reading* vchg);


/****************************************************************************
NAME
    PowerChargerGetState
    
DESCRIPTION
    The value pointed to by state will be set to the updated charger state 
    unless state is NULL.
    
RETURNS
    void
*/
void PowerChargerGetState(power_charger_state* state);


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
void PowerChargerMonitor(void);


/****************************************************************************
NAME
    PowerChargerEnable
    
DESCRIPTION
    Enable/disable the charger.
    
RETURNS
    void
*/
void PowerChargerEnable(bool enable);


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
void PowerChargerSetCurrent(uint8 current);


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
void PowerChargerSetBoost(power_boost_enable boost);


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
bool PowerChargerReduceTrim(uint8 trim);


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
bool PowerChargerSetVterm(uint8 vterm);


#endif     /* POWER_H_ */
