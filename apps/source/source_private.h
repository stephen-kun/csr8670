/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_private.h

DESCRIPTION
    Application specific data.
    
*/


#ifndef _SOURCE_PRIVATE_H_
#define _SOURCE_PRIVATE_H_


/* application header files */
#include "source_a2dp.h"
#include "source_aghfp.h"
#include "source_audio.h"
#include "source_avrcp.h"
#include "source_button_handler.h"
#include "source_connection_mgr.h"
#include "source_inquiry.h"
#include "source_ps.h"
#include "source_states.h"
#include "source_usb.h"
#include "source_volume.h"
/* VM headers */
#include <bdaddr.h>
#include <message.h>


/* CSR Manufacturer ID */
#define CSR_MANUFACTURER_ID                             0xA
/* Class of Device definitions */
#define COD_MAJOR_CAPTURING                             0x080000
#define COD_MAJOR_AV                                    0x000400  
#define COD_MINOR_AV_HIFI_AUDIO                         0x000028
/* Power table entries for Sniff mode */
#define POWER_TABLE_ENTRIES                             10
/* no timeout for timer events */
#define TIMER_NO_TIMEOUT                                0xffff
/* invalid value */
#define INVALID_VALUE                                   0xffff
/* core spec supported features defines */
#define SUPPORTED_FEATURES_WORD1_5SLOT                  0x0002
#define SUPPORTED_FEATURES_WORD2_EDR_ACL_2MBPS_3MBPS    0x0600
#define SUPPORTED_FEATURES_WORD3_EDR_ACL_3SLOT_5SLOT    0x0180
/* time to wait after a power off event to physically power off the hardware */
#define POWER_OFF_DELAY                                 3000



/* Macro for creating messages with payload */
#define MAKE_MESSAGE(TYPE) TYPE##_T *message = PanicUnlessNew(TYPE##_T);
#define MAKE_MESSAGE_WITH_LEN(TYPE, LEN) TYPE##_T *message = (TYPE##_T *) PanicUnlessMalloc(sizeof(TYPE##_T) + LEN);


/* structure holding all the data for all profile instances */
typedef struct
{
    a2dpInstance a2dp[A2DP_MAX_INSTANCES];
    aghfpInstance aghfp[AGHFP_MAX_INSTANCES];    
    avrcpInstance avrcp[AVRCP_MAX_INSTANCES]; 
} PROFILE_INST_T;


/* structure holding the timer data */
typedef struct
{
    unsigned timers_stopped:1;
} TIMER_DATA_T;


/* structure holding the general application variables and state */
typedef struct
{
    TaskData appTask;
    SOURCE_STATE_T app_state; 
    SOURCE_STATE_T pre_idle_state; /* used to return meaningful status to Host */ 
} APP_DATA_T;


/* structure used to hold the power table entries */
typedef struct
{
    unsigned unused:8;
    unsigned aghfp_entries:4;
	unsigned a2dp_entries:4;
	lp_power_table powertable[1];
} POWER_TABLE_T;


/* structure holding all application variables */
typedef struct
{    
    TaskData codecTask;
    TaskData connectionTask;
    TaskData usbTask;
    TaskData audioTask;
    Task codec; 
    
#ifdef INCLUDE_POWER_READINGS
    TaskData powerTask;
#endif    

    APP_DATA_T app_data;
    A2DP_DATA_T a2dp_data;
    AVRCP_DATA_T avrcp_data;
    AGHFP_DATA_T aghfp_data;
    
    CONNECTION_DATA_T connection_data;
    INQUIRY_SCAN_DATA_T *inquiry_data;
    INQUIRY_MODE_DATA_T inquiry_mode;
    PS_CONFIG_T *ps_config;
    USB_DATA_T usb_data;
    VOLUME_DATA_T volume_data;
    AUDIO_DATA_T audio_data;
    PROFILE_INST_T *profile_memory;
    TIMER_DATA_T timer_data;
    
#ifdef INCLUDE_BUTTONS    
    BUTTON_DATA_T button_data;
#endif    
    
} SOURCE_TASK_DATA_T;

/* application variables declared in another file */
extern SOURCE_TASK_DATA_T *theSource;


#endif /* _SOURCE_PRIVATE_H_ */

