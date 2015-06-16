/*************************************************************************
 Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
 Part of ADK 3.5

    FILE : 
                power_private.h

    CONTAINS:
                Internal information for the Battery Power Monitoring and 
                and charging management 

**************************************************************************/


#ifndef POWER_PRIVATE_H_
#define POWER_PRIVATE_H_

#include "power.h"

#include <message.h> 
#include <panic.h>
#include <print.h>

#ifndef MESSAGE_MAKE
/* 
   Normally picked up from message.h, but might not be present pre
   4.1.1h, so fall back to the old behaviour.
*/
#define MESSAGE_MAKE(N,T) T *N = PanicUnlessNew(T)
#endif

#define MAKE_POWER_MESSAGE(TYPE) MESSAGE_MAKE(message,TYPE##_T);

/* Internal messages */
enum
{
    POWER_INTERNAL_VREF_REQ,
    POWER_INTERNAL_VBAT_REQ,
    POWER_INTERNAL_VCHG_REQ,
    POWER_INTERNAL_VTHM_REQ,
    POWER_INTERNAL_CHG_MONITOR_REQ,
    POWER_INTERNAL_VBAT_NOTIFY_REQ,
    POWER_INTERNAL_VTHM_SETUP,
    POWER_INTERNAL_TOP              /* Must come last */
};

/* Init mask */
typedef enum
{
    power_init_start    = 0,
    power_init_vref     = 1 << 0,
    power_init_vbat     = 1 << 1,
    power_init_vchg     = 1 << 2,
    power_init_vthm     = 1 << 3,
    power_init_cfm_sent = 1 << 4
} power_init_mask;

/* Definition of the power type, a global structure used in library */
typedef struct
{
    TaskData            task;                   /* Power library task */
    Task                clientTask;             /* Client */
    power_config        config;                 /* Configuration */
    power_pmu_temp_mon_config   pmu_mon_config; /* Configuration for PMU based charger control */
    power_init_mask     init_mask:5;            /* Library initialisation mask */
    power_charger_state chg_state:3;            /* Charger state */
    power_boost_enable  chg_boost:2;            /* Boost internal/external/disable */
    unsigned            chg_cycle_complete:1;   /* Boost cycle complete */
    unsigned            pmu_mon_enabled:1;      /* Enable PMU temperature monitoring */
    uint16              vref;                   /* Most recent VREF measurement */
    uint16              vbat;                   /* Most recent VBAT measurement */
    uint16              vchg;                   /* Most recent VCHG measurement */
    uint16              vthm;                   /* Most recent VTHM measurement */
    uint8               ps_chg_trim;            /* Charger trim from PS */
    uint16              charger_i_target;       /* Requested charger current */
    uint16              charger_i_setting;      /* Current value that has been set */
} power_type;

extern power_type*      power;

#endif /* POWER_PRIVATE_H_ */


