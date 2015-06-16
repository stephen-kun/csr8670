/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014
Part of ADK 3.5

FILE NAME
    sink_gatt.h

DESCRIPTION
    Header file for interface with GATT library
*/
#ifndef GATT_DISABLED

#ifndef _SINK_GATT_H_
#define _SINK_GATT_H_

/* Application includes */
#include "sink_gatt_server.h"
#include "sink_gatt_client.h"

/* Firmware includes */
#include <csrtypes.h>
#include <message.h>


/*
    Defines GAP appearance (https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.gap.appearance.xml)
*/
typedef enum
{
    gap_appearance_unknown                  = 0,
    gap_appearance_generic_phone            = 64,
    gap_appearance_generic_computer         = 128,
    gap_appearance_generic_watch            = 192,
    gap_appearance_sports_watch             = 193,
    gap_appearance_generic_clock            = 256,
    gap_appearance_generic_display          = 320,
    gap_appearance_generic_remote_control   = 384,
    gap_appearance_generic_eye_glasses      = 448,
    gap_appearance_generic_tag              = 512,
    gap_appearance_generic_keyring          = 576,
    gap_appearance_generic_media_player     = 640,
    gap_appearance_generic_barcode_scanner  = 704,
    gap_appearance_generic_thermometer      = 768,
    gap_appearance_ear_thermometer          = 769,
    gap_appearance_generic_heart_rate       = 832,
    gap_appearance_generic_heart_rate_belt  = 833,
    gap_appearance_generic_blood_pressure   = 896,
    gap_appearance_blood_pressure_arm       = 897,
    gap_appearance_blood_pressure_wrist     = 898,
    gap_appearance_hid_device               = 960,
    gap_appearance_keyboard                 = 961,
    gap_appearance_mouse                    = 962,
    gap_appearance_joystick                 = 963,
    gap_appearance_gamepad                  = 964,
    gap_appearance_digitizer_tablet         = 965,
    gap_appearance_card_reader              = 966,
    gap_appearance_digital_pen              = 967,
    gap_appearance_barcode_scanner          = 968,
    gap_appearance_generic_glucose_meter    = 1024,
    gap_appearance_generic_run_walk_sensor  = 1088,
    gap_appearance_run_walk_sensor_in_shoe  = 1089,
    gap_appearance_run_walk_sensor_on_shoe  = 1090,
    gap_appearance_run_walk_sensor_on_hip   = 1091,
    gap_appearance_generic_cycling          = 1152,
    gap_appearance_cycling_computer         = 1153,
    gap_appearance_cycling_speed_sensor     = 1154,
    gap_appearance_cycling_cadence_sensor   = 1155,
    gap_appearance_cycling_power_sensor     = 1156,
    gap_appearance_cycling_speed_cadence    = 1157,
    gap_appearance_generic_oximeter         = 3136,
    gap_appearance_fingertip                = 3137,
    gap_appearance_wrist_worn               = 3138,
    gap_appearance_generic_sports           = 5184,
    gap_appearance_location_device          = 5185,
    gap_appearance_location_nav_device      = 5186,
    gap_appearance_location_pod             = 5187,
    gap_appearance_location_nav_pod         = 5188
} gapAppearance_t;


#define GATT_CLIENT_CONFIG_OCTET_SIZE   2       /* Client Config must be 16bits (2 octects) */
#define GATT_CLIENT_CONFIG_NOTIFY_BIT   0x1     /* Bit 1 of the Client Configuration is used to enable/disable notifications */
#define GATT_CLIENT_CONFIG_INICATE_BIT  0x2     /* Bit 2 of the Client Configuration is used to enable/disable indications   */



/*
    Defines GATT mode of operation configured via config tool.
*/
typedef enum
{
    gatt_mode_disabled=0,   /* GATT is disabled for the device */
    gatt_mode_client,       /* GATT is running in client mode */
    gatt_mode_server        /* GATT is running in server mode */

} gattMode_t;


/*
    GATT Configuration data
*/
typedef struct
{
    gattMode_t  mode;      /* Defines GATT mode of operation (disabled, client or server) */
    uint16      client;    /* List of supported services when running in GATT Client mode */
} gattConfigData_t;


/*
    GATT Runtime data
*/
typedef struct
{
    TaskData                    task;           /* The GATT message handler */
    gattConfigData_t            config;         /* GATT configuration data */
    bool                        initialised;    /* Flag set when GATT has been initialised for the device */
    
#ifdef GATT_SERVER_ENABLED
    gattServerRuntimeData_t     server;     /* If configured as GATT_SERVER, this is GATT_SERVER runtime data */
#endif
} gattRuntimeData_t;



/*******************************************************************************
NAME    
    initialise_gatt_for_device
    
DESCRIPTION
    Function to initialise the GATT library for the device based on the
    configuration settings defined for the application
*/
void initialise_gatt_for_device(uint8 *name, uint16 size_name);


/*******************************************************************************
NAME
    gatt_message_handler

DESCRIPTION
    Function to handle messages generated by the GATT library and pass them
    on to the appropriate GATT sub task.
*/
void gatt_message_handler( Task task, MessageId id, Message message );


/*******************************************************************************
NAME    
    disconnect_all_gatt_devices
    
DESCRIPTION
    Function to disconnect all connected GATT devices
*/
void disconnect_all_gatt_devices( void );


#endif /* _SINK_GATT_H_ */

#endif /* GATT_DISABLED */
