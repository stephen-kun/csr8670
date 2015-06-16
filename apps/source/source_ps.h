/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_ps.h

DESCRIPTION
    Handles the PS Keys used by the application. Includes reading from and writing to PS.
    
*/


#ifndef _SOURCE_PS_H_
#define _SOURCE_PS_H_


/* application header files */
#include "source_app_msg_handler.h"
#include "source_inquiry.h"
/* VM headers */
#include <bdaddr.h>
#include <csrtypes.h>
/* profile/library headers */
#include <aghfp.h>
#include <connection.h>
#include <power.h>

/* The Configuration Set type: 1 = Source */
#define CONFIG_SET_PRODUCT_TYPE   1

/*******************************************************************************************************/
/* REMEMBER TO UPDATE THESE VALUES WHEN MAKING CONFIGURATION CHANGES THAT WILL REQUIRE AN UPDATE TO THE
   CONFIGURATION TOOL XML FILE TO MAINTAIN FORWARDS AND BACKWARDS COMPATIBILITY                        */
/*******************************************************************************************************/
#define CONFIG_SET_VERSION        2
/*******************************************************************************************************/
/* REMEMBER TO UPDATE THESE VALUES WHEN MAKING CONFIGURATION CHANGES THAT WILL REQUIRE AN UPDATE TO THE
   CONFIGURATION TOOL XML FILE TO MAINTAIN FORWARDS AND BACKWARDS COMPATIBILITY                        */
/*******************************************************************************************************/

/* PS Key value for local Bluetooth address */
#define PS_KEY_LOCAL_BDADDR         0x0001
/* The maximum length of a name that can be read from the paired device attributes */
#define PS_REMOTE_NAME_MAX_LENGTH   56
/* The maximum PIN codes stored. These are used when trying to connect to a Bluetooth v2.0 or earlier device */
#define PS_MAX_PIN_CODES 4


/* User PSKeys used by the application */
typedef enum
{
    PS_KEY_USER_COMPANY_ID = 0,         /* 0 */
    PS_KEY_USER_BLUETOOTH_PROFILES,     /* 1 */
    PS_KEY_USER_DUALSTREAM,             /* 2 */
    PS_KEY_USER_FEATURES,               /* 3 */
    PS_KEY_USER_SBC_CONFIG,             /* 4 */
    PS_KEY_USER_FASTSTREAM_CONFIG,      /* 5 */
    PS_KEY_USER_A2DP_CODECS,            /* 6 */
    PS_KEY_USER_BDADDR_REMOTE_DEVICE,   /* 7 */
    PS_KEY_USER_TIMERS,                 /* 8 */
    PS_KEY_USER_USB_CONFIG,             /* 9 */
    PS_KEY_USER_APTX_CONFIG,            /* 10 */
    PS_KEY_USER_SNIFF,                  /* 11 */
    PS_KEY_USER_HFP_AUDIO,              /* 12 */
    PS_KEY_USER_BDADDR_STREAM2_DEVICE,  /* 13 */
    PS_KEY_USER_APTX_LOW_LATENCY_CONFIG,/* 14 */
    PS_KEY_USER_PIN_CODES,              /* 15 */
    PS_KEY_USER_POWER_READINGS,         /* 16 */
    PS_KEY_USER_PIO,                    /* 17 */
    
    PS_KEY_USER_PAIRED_ATTR_BASE = 24,  /* 24 */
    /* Paired device attributes could be stored 24 - 31, so don't reuse any of these keys */
    PS_KEY_USER_PAIRED_ATTR_MAX = 31,   /* 31 */
    
    PS_KEY_USER_PAIRED_NAME_BASE = 32,  /* 32 */
    /* Paired device local name could be stored 32 - 39, so don't reuse any of these keys */
    PS_KEY_USER_PAIRED_NAME_MAX = 39,   /* 39 */
    
    PS_KEY_PAIRED_DEVICE_LIST_SIZE = 40,/* 40 */
    
    PS_KEY_CONFIG_SET_VERSION_ID = 49   /* 49 */
} PS_KEY_USER_T;

/* A2DP profiles supported */
typedef enum
{
    PS_A2DP_PROFILE_DISABLED,
    PS_A2DP_PROFILE_1_2
} PS_A2DP_PROFILE_T;

/* AVRCP profiles supported */
typedef enum
{
    PS_AVRCP_PROFILE_DISABLED,
    PS_AVRCP_PROFILE_1_0
} PS_AVRCP_PROFILE_T;

/* HFP profiles supported */
typedef enum
{
    PS_HFP_PROFILE_DISABLED,
    PS_HFP_PROFILE_1_6
} PS_HFP_PROFILE_T;

/* PSKey configurable connection policy */
typedef enum
{
    PS_CONNECT_LAST_DEVICE,
    PS_CONNECT_PAIRED_LIST
} PS_CONNECT_POLICY_T;


/* PSKey configurable timers */
typedef struct
{
    uint16 inquiry_state_timer; /* in secs */
    uint16 inquiry_idle_timer; /* in secs */
    uint16 connection_idle_timer; /* in secs */
    uint16 disconnect_idle_timer; /* in secs */
    uint16 aghfp_connection_failed_timer; /* in millisecs */
    uint16 a2dp_connection_failed_timer; /* in millisecs */    
    uint16 avrcp_connection_failed_timer; /* in millisecs */
    uint16 avrcp_connection_delay_timer; /* in millisecs */
    uint16 profile_connection_delay_timer; /* in millisecs */    
    uint16 link_loss_reconnect_delay_timer; /* in secs */
    uint16 media_repeat_timer; /* in millisecs */
    uint16 audio_delay_timer; /* in millisecs */
    uint16 usb_audio_active_timer; /* in secs */
    uint16 power_on_connect_idle_timer; /* in secs */
    uint16 power_on_discover_idle_timer; /* in secs */
} PS_TIMERS_T;

/* PSKey configurable features */
typedef struct
{
    unsigned input_source:4;    /* USB = 0, analogue = 1, SPDIF = 2 */
    unsigned connect_policy:2;
    unsigned avrcp_vendor_enable:1;
    unsigned sbc_force_max_bitpool:1;
    unsigned aghfp_max_connection_retries:8;
    unsigned a2dp_max_connection_retries:8;
    unsigned avrcp_max_connection_retries:8;
    uint16 connection_max_retries;
} PS_FEATURES_T;

/* PSKey configurable SBC configuration */
typedef struct
{
    unsigned unused:8;
    unsigned sampling_freq_ch_mode:8;    
    uint16 max_bitpool;
    uint16 min_bitpool;
} PS_SBC_CONFIG_T;

/* PSKey configurable Faststream configuration */
typedef struct
{
    unsigned music_voice:8;    
    unsigned sampling_freqs:8;    
} PS_FASTSTREAM_CONFIG_T;

/* PSKey configurable A2DP codecs */
typedef struct
{
    unsigned aptxLowLatency_preference:3;
    unsigned aptxLowLatency:1;
    unsigned aptx_preference:3;
    unsigned aptx:1;
    unsigned faststream_preference:3;
    unsigned faststream:1;
    unsigned sbc_preference:3;
    unsigned sbc:1;
} PS_A2DP_CODECS_T;

/* PSKey configurable USB configuration */
typedef struct
{
    unsigned unused:12;
    unsigned usb_hid_keyboard_interface:1;
    unsigned usb_hid_consumer_interface:1;
    unsigned usb_mic_interface:1;
    unsigned usb_speaker_interface:1;
} PS_USB_CONFIG_T;

/* PSKey configurable APT-X configuration */
typedef struct
{
    unsigned unused:8;
    unsigned sampling_freqs:8;     
} PS_APTX_CONFIG_T;

/* PSKey configurable APT-X Low Latency configuration */
typedef struct
{
    unsigned unused:7;
    unsigned bidirectional:1;
    unsigned sampling_freqs:8;     
} PS_APTX_LOW_LATENCY_CONFIG_T;

/* PSKey configurable sniff parameters */
typedef struct
{
    unsigned unused:8;
    unsigned number_a2dp_entries:4;
    unsigned number_aghfp_entries:4;
    lp_power_table *a2dp_powertable;
    lp_power_table *aghfp_powertable;
} PS_SNIFF_T;

/* PSKey configurable HFP audio parameters */
typedef struct
{
    uint16 sync_pkt_types;
    aghfp_audio_params audio_params;     
} PS_HFP_AUDIO_T;

/* PSKey configurable Bluetooth profiles */
typedef struct
{
     PS_A2DP_PROFILE_T a2dp_profile;
     PS_AVRCP_PROFILE_T avrcp_profile;
     PS_HFP_PROFILE_T hfp_profile;
} PS_BT_PROFILES_CONFIG_T;

/* PSKey configurable DualStream mode */
typedef struct
{
    unsigned unused:14;
    unsigned dual_stream_enable:1;
    unsigned dual_stream_connect_both_devices:1;     
} PS_DUALSTREAM_CONFIG_T;


/* PSKey configurable PIN Codes */
typedef struct
{
    uint8 code[4];     
} PS_PIN_CODE_T;

typedef struct
{
    uint16 number_pin_codes;
    PS_PIN_CODE_T pin_codes[PS_MAX_PIN_CODES];
} PS_PIN_CONFIG_T;

typedef struct
{
    power_config power;
} PS_POWER_CONFIG_T;

/* PSKey configurable APT-X configuration */
typedef struct
{
    unsigned spdif_input:8;
    unsigned unused:8;     
} PS_PIO_CONFIG_T;

/* PSKey configurable items */
typedef struct
{
    bdaddr bdaddr_remote_device;
    bdaddr bdaddr_stream2_device;    
    uint32 company_id;
    uint16 number_paired_devices;
    PS_TIMERS_T ps_timers;
    PS_FEATURES_T features;
    PS_SBC_CONFIG_T sbc_config;
    PS_FASTSTREAM_CONFIG_T faststream_config;
    PS_A2DP_CODECS_T a2dp_codecs;
    PS_USB_CONFIG_T usb_config;
    PS_APTX_CONFIG_T aptx_config;
    PS_APTX_LOW_LATENCY_CONFIG_T aptxLowLatency_config;
    PS_SNIFF_T sniff;
    PS_HFP_AUDIO_T hfp_audio;
    PS_BT_PROFILES_CONFIG_T bt_profiles;
    PS_DUALSTREAM_CONFIG_T dualstream;
    PS_POWER_CONFIG_T pwr_config;
    PS_PIO_CONFIG_T pio_config;
} PS_CONFIG_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    ps_read_user

DESCRIPTION
    Read a User PSKey.
    Similar to calling PsRetrieve but will return a default value if the PSKey has not been written to.
    
RETURNS
    The size of data returned.
    
*/
uint16 ps_read_user(uint16 ps_key, void *ps_data, uint16 ps_size);


/****************************************************************************
NAME    
    ps_read_full

DESCRIPTION
    Read a device PSKey.
    Similar to calling PsFullRetrieve but contains additional debug information.
    
RETURNS
    The size of data returned.
    
*/
uint16 ps_read_full(uint16 ps_key, void *ps_data, uint16 ps_size);


/****************************************************************************
NAME    
    ps_write

DESCRIPTION
    Write a device PSKey.
    Similar to calling PsStore but contains additional debug information.
    
RETURNS
    The size of data written.
    
*/
uint16 ps_write(uint16 ps_key, const void *ps_data, uint16 ps_size);


/****************************************************************************
NAME    
    ps_get_configuration

DESCRIPTION
    Reads the PSKeys used to configure the device.
     
*/
void ps_get_configuration(void);


/****************************************************************************
NAME    
    ps_get_time_critical_data

DESCRIPTION
    Reads the PSKeys used to configure the device that need to be read before the main application starts up.
     
*/
void ps_get_time_critical_data(void);


/****************************************************************************
NAME    
    ps_restore_timers

DESCRIPTION
    Sets the timers to the PS defaults.
     
*/
void ps_restore_timers(void);


/****************************************************************************
NAME    
    ps_write_new_remote_device

DESCRIPTION
    Write the device to PS and store it as last used device.
    The function accepts the address of the remote device connected and the profile that has just connected.
     
*/
void ps_write_new_remote_device(const bdaddr *addr, PROFILES_T profile);


/****************************************************************************
NAME    
    ps_write_device_name

DESCRIPTION
    Write the device name to PS.
     
*/
void ps_write_device_name(const bdaddr *addr, uint16 size_name, const uint8 *name);


/****************************************************************************
NAME    
    ps_write_device_attributes

DESCRIPTION
    Write the device attributes to PS.
     
*/
void ps_write_device_attributes(const bdaddr *addr, ATTRIBUTES_T attributes);

/****************************************************************************
NAME 
    ps_set_version

DESCRIPTION
    Reads the PSKEY containing the version type and number and checks if it 
    needs to be set or reset, will not be written if already the correct value.
 
RETURNS
    void
*/ 
void ps_set_version(void);

#endif /* _SOURCE_PS_H_ */
