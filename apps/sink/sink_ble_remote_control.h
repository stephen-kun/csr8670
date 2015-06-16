/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2013-2014
Part of ADK 3.5

FILE NAME
    sink_ble_remote_control.h

DESCRIPTION
    Header file for interface with BLE HID Remote Controllers that support
    the HOGP profile. 
    This device adopts the "Report Host" role defined within the HOGP spec

NOTES
    The default (example) lookup table that exists in bleremotecontrol.snk is configured as:
       INPUT_ID:  INPUT_MASK:     HID:    BUTTON:   DESCRIPTION:
       (input0)   000000000001    0x30    PWR       Power
       (input1)   000000000010    0xEA    VOL-      Volume Down
       (input2)   000000000100    0xE9    VOL+      Volume Up
       (input3)   000000001000    0xB0    >||       Play
       (input4)   000000010000    0xB5    >>|       Fast Forward
       (input5)   000000100000    0xB6    |<<       Rewind
       (input6)   000001000000    0x89    1         Media Select TV (wired input)
       (input7)   000010000000    0x8c    2         Media Select Telephone (A2DP [AG1] input)
       (input8)   000100000000    0x93    3         Media Select Tuner (FM input)
       (input9)   001000000000    0xE3    4         Sub channel (enable/disable subwoofer audio forwarding)
*/

#ifndef _SINK_BLE_REMOTE_CONTROL_H_
#define _SINK_BLE_REMOTE_CONTROL_H_

#if defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED)

/* Application includes */
#include "sink_input_manager.h"

/* Firmware includes */
#include <message.h>
#include <bdaddr.h>

/* Library includes */
#include <gatt.h>
#include <connection.h>


/* USB HID Main Item Tags (http://www.usb.org/developers/devclass_docs/HID1_11.pdf - page28) */
#define USB_HID_TAG_INPUT           0x0020  /* 1000 00nn */
#define USB_HID_TAG_OUTPUT          0x0024  /* 1001 00nn */
#define USB_HID_TAG_FEATURE         0x002C  /* 1011 00nn */
#define USB_HID_TAG_COLLECTION      0x0028  /* 1010 00nn */
#define USB_HID_TAG_END_COLLECTION  0x0030  /* 1100 00nn */
/* USB HID Global Item Tags (http://www.usb.org/developers/devclass_docs/HID1_11.pdf - page35) */
#define USB_HID_TAG_USEAGE_PAGE     0x0001  /* 0000 01nn */
#define USB_HID_TAG_LOGICAL_MIN     0x0005  /* 0001 01nn */
#define USB_HID_TAG_LOGICAL_MAX     0x0009  /* 0010 01nn */
#define USB_HID_TAG_PHYSICAL_MIN    0x000D  /* 0011 01nn */
#define USB_HID_TAG_PHYSICAL_MAX    0x0011  /* 0100 01nn */
#define USB_HID_TAG_UNIT_EXPONENT   0x0015  /* 0101 01nn */
#define USB_HID_TAG_UNIT            0x0019  /* 0110 01nn */
#define USB_HID_TAG_REPORT_TAG      0x001D  /* 0111 01nn */
#define USB_HID_TAG_REPORT_ID       0x0021  /* 1000 01nn */
#define USB_HID_TAG_REPORT_COUNT    0x0025  /* 1001 01nn */
#define USB_HID_TAG_PUSH            0x0029  /* 1010 01nn */
#define USB_HID_TAG_POP             0x002D  /* 1011 01nn */
/* USB HID Local Item Tags (http://www.usb.org/developers/devclass_docs/HID1_11.pdf - page40) */
#define USB_HID_TAG_USAGE           0x0002  /* 0000 10nn */
#define USB_HID_TAG_USAGE_MIN       0x0006  /* 0001 10nn */
#define USB_HID_TAG_USAGE_MAX       0x000A  /* 0010 10nn */
#define USB_HID_TAG_DESIGNATOR_IDX  0x000E  /* 0011 10nn */
#define USB_HID_TAG_DESIGNATOR_MIN  0x0012  /* 0100 10nn */
#define USB_HID_TAG_DESIGNATOR_MAX  0x0016  /* 0101 10nn */
#define USB_HID_TAG_STRING_IDX      0x001E  /* 0111 10nn */
#define USB_HID_TAG_STRING_MIN      0x0022  /* 1000 10nn */
#define USB_HID_TAG_STRING_MAX      0x0026  /* 1001 10nn */
#define USB_HID_TAG_DELIMITER       0x002A  /* 1010 10nn */

/* USB HID Collection, End Collection Items (http://www.usb.org/developers/devclass_docs/HID1_11.pdf - page33) */
#define USB_HID_COLLECTION_PHYSICAL         0x00
#define USB_HID_COLLECTION_APPLICATION      0x01
#define USB_HID_COLLECTION_LOGICAL          0x02
#define USB_HID_COLLECTION_REPORT           0x03
#define USB_HID_COLLECTION_ARRAY            0x04
#define USB_HID_COLLECTION_USE_SWITCH       0x05
#define USB_HID_COLLECTION_USE_MODIFIER     0x06
#define USB_HID_COLLECTION_RESERVED_BASE    0x07
#define USB_HID_COLLECTION_RESERVED_TOP     0x7F
#define USB_HID_COLLECTION_VENDOR_BASE      0x80
#define USB_HID_COLLECTION_VENDOR_TOP       0xFF


/* USB Usage Page ID's (http://www.usb.org/developers/devclass_docs/Hut1_12v2.pdf - page14) */
#define USB_USAGE_PAGE_CONSUMER         0x0C
#define USB_USAGE_PAGE_GAME_CONTROL     0x05
#define USB_VENDOR_SPECIFIC_BASE        0xFF00
#define USB_VENDOR_SPECIFIC_TOP         0xFFFF

/* USB Consumer Page Usage Page ID's ((http://www.usb.org/developers/devclass_docs/Hut1_12v2.pdf  - page75) */
#define USB_CONSUMER_USAGE_UNASSIGNED          0x00
#define USB_CONSUMER_USAGE_CONSUMER_CONTROL    0x01
#define USB_CONSUMER_USAGE_NUMERIC_KEYPAD      0x02

/* Used for service searching; do not modify */
static const gatt_uuid_t GATT_HID_SERVICE_UUID_T                = GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE;
static const gatt_uuid_t GATT_BATTERY_SERVICE_UUID_T            = GATT_SERVICE_UUID_BATTERY_SERVICE;
static const gatt_uuid_t GATT_DEVICE_INFORMATION_SERVICE_UUID_T = GATT_SERVICE_UUID_DEVICE_INFORMATION;

/*
    Defines the Protocol modes that can be written to Protocol Mode characteristics (as defined by Bluetooth.org)
*/
typedef enum
{
    hogp_boot_mode_protocol = 0x0,  /* Use the boot mode protocol */
    hogp_report_mode_protocol       /* Use the report mode protocol */
    
    /* Keys 2-255 are reserved */
} hogpProtocolMode_t;


/*
    Defines the HID Control Point commands
*/
typedef enum
{
    hogp_enter_suspend_mode = 0x0,  /* Used to put the HID device into suspend mode */
    hogp_exit_suspend_mode          /* Used to take the HID device out of suspend mode */
    
    /* Keys 2-255 are reserved */
} hogpSuspendMode_t;


/* Data the PTS system needs written (this is the default PIXT values for HOGP PTS) */
static const uint8 pts_tspx_input_report_data[5]    = {0xAA, 0xB3, 0xF8, 0xA6, 0xCD};
static const uint8 pts_tspx_output_report_data[7]   = {0xEF, 0x90, 0x78, 0x56, 0x34, 0x12, 0x00};
static const uint8 pts_tspx_feature_report_data[5]  = {0xEA, 0x45, 0x3F, 0x2D, 0x87};
static const uint8 pts_set_protocol_mode_data[1]    = {hogp_report_mode_protocol};

/* Pre-Defined data to write to characteristics  */
static const uint8 enable_notifications_data[2]     = {0x1, 0x0};                   /* Data to write to client configuration characteristics to enable notifications for the associated characteristic */
static const uint8 disable_notifications_data[2]    = {0x0, 0x0};                   /* Data to write to client configuration characteristics to disable notifications for the associated characteristic */
static const uint8 enter_suspend_mode[1]            = {hogp_enter_suspend_mode};    /* Data to write to HID Control Point characterisitc to enter suspend mode */
static const uint8 exit_suspend_mode[1]             = {hogp_exit_suspend_mode};     /* Data to write to HID Control Point characterisitc to exit suspend mode */

/*
    Defines the Timer IDs to differentiate which timer has fired
*/
typedef enum
{
    BLE_HID_RC_TIMER_MULTIPLE = 0,  /* The MULTIPLE timer has fired whilst the button is still pressed (the button down will be considered a single button press) */
    BLE_HID_RC_TIMER_SHORT,         /* The SHORT timer has fired whilst the button is still pressed */
    BLE_HID_RC_TIMER_LONG,          /* The LONG timer has fired whilst the button is still pressed */
    BLE_HID_RC_TIMER_VLONG,         /* The VLONG timer has fired whilst the button is still pressed */
    BLE_HID_RC_TIMER_VVLONG         /* The VVLONG timer has fired whilst the button is still pressed */
    
} bleHidRcTimerID_t;


/*
    Defines the BLE HID RC button events
    These IDs are the actual message ID's as identified by the MessageLoop() scheduler
*/
#define BLE_HID_RC_MSG_BASE 0
typedef enum
{
    BLE_HID_RC_BUTTON_DOWN_MSG = BLE_HID_RC_MSG_BASE,   /* Sent when a button is pressed */
    BLE_HID_RC_BUTTON_TIMER_MSG,                        /* Sent when a button duration (SHORT, LONG, VLONG, VVLONG) timer fires */
    BLE_HID_RC_BUTTON_REPEAT_MSG,                       /* Sent when a button REPEAT timer fires */
    BLE_HID_RC_BUTTON_UP_MSG,                           /* Sent when a button is released */
    BLE_HID_RC_CONNECTION_TIMEOUT_MSG,                  /* Sent to ensure a connection request doesn't timeout and cause issues */
    BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ,           /* Internal message used to trigger discovery of ALL primary services */
    BLE_HID_RC_EVENT_PRIM_SERVICES_DISCOVERED,          /* Used to indicate when primary service discovery has completed */
    BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ,          /* Internal message used to trigger discovery of ALL included services */
    BLE_HID_RC_EVENT_INCLUDED_SERVICES_DISCOVERED,      /* Used to indicate when included service discovery has completed */
    BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ,        /* Internal message used to trigger discovery of ALL characteristics for a service */
    BLE_HID_RC_EVENT_ALL_CHARACTERISTICS_DISCOVERED,    /* Used to indicate when a characteristic discovery has completed */
    BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ,            /* Internal message used to trigger discovery of ALL descriptors for a service */
    BLE_HID_RC_EVENT_ALL_DESCRIPTORS_DISCOVERED,        /* Used to indicate when a descriptor discovery has completed */
    BLE_HID_RC_PROCESS_ALL_SERVICES_REQ,                /* Internal message used to trigger processing of all the discovered characterisitcs & descriptors for each discovered service */
    BLE_HID_RC_EVENT_SERVICE_PROCESSED,                 /* Used to indicate when all characteristics & descriptors for a discovered service have been read & processed */
    BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED,            /* Used to indicate when all characteristics & descriptors for all services have been read & processed */
    BLE_HID_RC_SETUP_SUSPEND_MODE_REQ,                  /* Internal message used to trigger setting up suspend mode for the device (if supported) */
    BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP,                /* Used to indicate when suspend mode has been setup */
    BLE_HID_RC_SETUP_NOTIFICATIONS_REQ,                 /* Internal message used to start setup notifications for the remote controller device */
    BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP,       /* Used to indicate when notifications for a service have been setup */
    BLE_HID_RC_EVENT_ALL_NOTIFICATIONS_SETUP,           /* Used to indicate when all notifications for the remote controller have been setup */
    BLE_HID_RC_ENTER_SUSPEND_MODE_REQ,                  /* Internal message used to request to enter suspend mode */
    BLE_HID_RC_EXIT_SUSPEND_MODE_REQ,                   /* Internal message used to request to exit suspend mode */
    BLE_HID_RC_MSG_TOP                                  /* DO NOT MODIFY: ALWAYS LEAVE AT LAST POSITION IN THIS ENUM */
    
} bleHidRcMessageID_t;


/*
    Defines services supported by the BLE HOGP report host
*/
typedef enum
{
    service_invalid,
    service_hid,
    service_battery,
    service_dev_info
    
} bleHidRcSupportedServices_t;


/*
    Defines the types of Report that a report characteristic can be defined as
*/
typedef enum
{
    type_report_none = 0,   /* Indicates the characteristic is not a report (or the associated report reference is setup wrong) */
    type_input_report,      /* Indicates REPORT is an input report */
    type_output_report,     /* Indicates REPORT is an output report */
    type_feature_report     /* Indicates REPORT is a feature report */
    
} reportType_t;


/* 
    Defines the HID lookup table for converting HID code to input mask based on "input_id" that is bitshifted to create an "input_mask"
    Compacted to one word per lookup entry.
*/
typedef struct
{
    unsigned  input_id:4;   /* The input ID the HID code translates to (allows up to 16 RC buttons to be supported) */
    unsigned  hid_code:12;  /* The HID Code sent by the remote control, Consumer HID has some values that are 12-bit length (0x0 <> 0xFFF) */    
    
} bleLookupTable_t;


/*
    Defines the config data structure for the scan parameters used when BLE scanning for HID Remote Controllers.
*/
typedef struct
{
    uint16 scan_interval; /* Scan interval in steps of 0.625ms, range 0x0004 (2.5 ms) to 0x4000 (10.24 s) */
    uint16 scan_window;   /* Scan window in steps of 0.625ms, range 0x0004 (2.5ms) to 0x4000 (10.24 s). Must be less than or equal to the scan_interval parameter value */
} bleConfigScanParams_t;


/* 
    Defines the data structure of the BLE HID RC configuration data
*/
typedef struct
{
    uint16                max_remotes;          /* Stores the maximum number of remote controllers supported */
    uint16                pairing_timeout;      /* The pairing timeout (in seconds) so the BLE pairing mode is disabled after n seconds */
    bleConfigScanParams_t scan_params;          /* The scan parameters to use when scanning for BLE remote controllers */
    bdaddr                stored_addr;          /* Bluetooth address of a BLE remote controller (given priority on connections) */
    bleLookupTable_t      lookup_table[1];      /* Stores the lookup table configured for the BLE remote */
    
} bleHidRcConfig_t;


/*
    Remote controller states
*/
typedef enum
{
    rc_disconnected=0,          /* Controller is not connected (NOTE: do not modify rc_disconnected position; must always equal zero) */
    rc_connecting,              /* Controller is connecting */
    rc_ready_for_discovery,     /* Controller is connected, but no services / characteristics have yet been discovered */
    rc_service_discovery,       /* Discovering all primary services on the remote device */
    rc_ready_for_include,       /* All services have been discovered, now ready to find any included services */
    rc_included_discovery,      /* Discovering all included services on the remote device */
    rc_ready_for_chars,         /* All services & includes have been discovered, now ready to find any characteristics */
    rc_char_discovery,          /* Discovering all characteristics on the remote device */
    rc_ready_for_descriptors,   /* All services, includes & characteristics have been discovered, now ready to find any descriptors */
    rc_descriptor_discovery,    /* Discovering all descriptors on the remote device */
    rc_ready_for_processing,    /* All services, includes, characteristics & descriptors have been discovered : now ready to process the discovered HID service(s) */
    rc_processing_hid,          /* Processing and setting up the HID service(s) for the remote controller */
    rc_ready_to_process_bat,    /* HID service(s) have been processed and now ready to process the battery service(s) */
    rc_processing_battery,      /* Processing and setting up the Battery service(s) for the remote controller */
    rc_ready_to_process_dinfo,  /* HID and battery service(s) have been processed and now ready to process the device information service(s) */
    rc_processing_dinfo,        /* Processing and setting up the Device information service(s) for the remote controller */
    rc_setup_suspend_mode,      /* Setting up the suspend mode (if supported) */
    rc_setup_notifications,     /* Setting up notifications for the remote controller */
    rc_connected                /* Controller is connected */
    
} rcState_t;


/*
    Defines the type of data being read when calling GattRead functions
*/
typedef enum
{
    reading_none,                   /* Not in the process of reading any data */
    reading_all_characteristics,    /* In the process of reading all characteristic values */
    reading_report_map,             /* In the process of reading a report map characteristic */
    reading_all_descriptors,        /* In the process of reading all descriptors */
    reading_char_declaration,       /* In the process of reading a single characteristic declaration */
    reading_report_reference        /* In the process of reading a single report reference descriptor */
    
} bleReadType_t;


/*
    Used to store the UUID, start handle and end handle for each HOGP service supported by the remote controller
*/
typedef struct
{
    uint16  uuid;   /* UUID for the service */
    uint16  start;  /* Start handle for the service */
    uint16  end;    /* End handle for the service */
    
} gattService_t;


/* 
    Used to store the UUID, start handle, end handle and properties for each characteristic supported by the remote controller
*/
typedef struct
{
    uint16          handle;         /* The assigned handle for the characteristic */
    uint16          uuid;           /* The UUID for the characteristic */
    unsigned        props:8;        /* The characteristic properties */
    unsigned        report_id:8;    /* For report Characteristics, indicates the report ID of the characteristic */
    reportType_t    report_type:2;  /* For report Characteristics, indicates the "report type" of the characteristic */
    unsigned        suspend:1;      /* For HID Control Point characteristics, indicates whether or not suspend mode is supported */
    unsigned        notify:1;       /* Flag used to state whether or not this characteristic is a REPORT that we want notifications to be enabled for */
    unsigned        reserved:12;
    
} gattChar_t;


/* 
    Defines the data structure for BUTTON EVENT messages
*/
typedef struct
{
    uint16              cid;    /* Connection ID to identify the RC the button press was generated on */
    uint16              mask;   /* Identifies which of the buttons are currently pressed down */
    bleHidRcTimerID_t   timer;  /* Identifies the button timer that has fired (Only used for BLE_HID_RC_BUTTON_TIMER_MSG) */
    
} BLE_HID_RC_BUTTON_EVENT_MSG_T;


/*
    Defines the data structure for the Conection timeout message
*/
#define BLE_HID_RC_CONNECTION_TIMEOUT   D_SEC(5) /* 5 second timeout on the connection */
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_CONNECTION_TIMEOUT_MSG_T;


/*
    Defines the data structure for the Primary services discovery request
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ_T;


/*
    Defines the data structure for the Primary services discovered message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_PRIM_SERVICES_DISCOVERED_T;


/*
    Defines the data structure for the included services discovery request
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ_T;


/*
    Defines the data structure for the Included services discovered message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_INCLUDED_SERVICES_DISCOVERED_T;


/*
    Defines the data structure for the characteristic discovery request
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ_T;


/*
    Defines the data structure for the Characteristics discovered message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_ALL_CHARACTERISTICS_DISCOVERED_T;


/*
    Defines the data structure for the descriptor discovery request
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ_T;


/*
    Defines the data structure for the Descriptors discovered message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_ALL_DESCRIPTORS_DISCOVERED_T;


/*
    Defines the data structure for the process all services request
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_PROCESS_ALL_SERVICES_REQ_T;


/* 
    Defines the data structure for the message used to indicate when all 
    descriptors for a discovered service have been processed
*/
typedef struct
{
    uint16                          cid;            /* Connection ID for the device */
    bleHidRcSupportedServices_t     service_type;   /* The type of service that has been processed */
    
} BLE_HID_RC_EVENT_SERVICE_PROCESSED_T;


/*
    Defines the data structure for the HID service processed message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED_T;


/*
    Defines the data structure for the setup suspend mode request
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_SETUP_SUSPEND_MODE_REQ_T;


/*
    Defines the data structure for the suspend mode setup message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP_T;


/*
    Defines the data structure for the setup notifications request message
*/
typedef struct
{
    uint16      cid;
    bool        notify;
    
} BLE_HID_RC_SETUP_NOTIFICATIONS_REQ_T;


/*
    Defines the data structure for the notifications setup complete message
*/
typedef struct
{
    uint16      cid;
    bool        notify;
    
} BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP_T;


/*
    Defines the data structure for the notifications setup complete message
*/
typedef struct
{
    uint16      cid;
    
} BLE_HID_RC_EVENT_ALL_NOTIFICATIONS_SETUP_T;


/*
     Data required for each active BLE remote controller
*/
typedef struct
{
    /* State info for the remote controller */
    uint16          cid;                /* Store the GATT assigned Connection ID for the remote controller */
    typed_bdaddr    taddr;              /* Store the BDADDR of the remote controller */
    uint16          button_mask;        /* Keep track of the state (up/down) for each of the 16 configurable RC HID buttons */
    unsigned        buttons_down:4;     /* Keep track of the number of multiple buttons that are held down (supports 0 <> MAX_MULTIPLE_BUTTONS) */
    unsigned        writing_pts_data:1; /* Flag that is set when writing test data to a characteristic for PTS mode */
    unsigned        suspend_active:1;   /* TODO : Flag that is set when suspend mode is active */
    unsigned        write_hid_notify:1; /* Flag set when writing data to enable/disable HID notifications */
    unsigned        write_bat_notify:1; /* Flag set when writing data to enable/disable Battery notifications */
    unsigned        notify_status:1;    /* Flag set when writing to enable notifications, unset when writing to disable notifications */
    bleReadType_t   reading_type:4;     /* Keep track of what data is being read from the remote device */
    unsigned        reserved1:3;
    
    unsigned        reserved2:3;
    inputState_t    d_state:4;          /* Keep track of the state for the pressed button(s) on the remote controller */
    rcState_t       state:5;            /* Keep track of the connection state with the remote controller */    
    
    /* Control flags */
    unsigned        d_sent_in_m_state:1;  /* Flag used when the DOWN notification has already sent in inputMultipleDetect state */
    
    /* HID Over GATT Services that must be supported by the RC (as per the spec) */
    unsigned        supports_battery:1;   /* Device supports the battery service */
    unsigned        supports_hid:1;       /* Device supports the HID service */
    unsigned        supports_dev_info:1;  /* Device supports the Device Information service */
    
    /* GATT Handles for the remote controller */
    uint16          disco_counter;          /* Counter used for discovering stuff about the remote device */
    
    uint16          num_services;           /* Stores the number of services supported by the device */
    gattService_t   *services;              /* Stores all HOGP services supported by the device */
    
    uint16          num_characteristics;    /* Stores the number of (useful) characteristics supported by the device */
    gattChar_t      *characteristics;       /* Stores all (useful) characteristics supported by the device */
    
    uint16          num_descriptors;        /* Stores the number of (useful) characterisitcs supported by the device */
    gattChar_t      *descriptors;           /* Store all descriptors for (useful) characterisitcs supported by the device */
    
    /* For service, characteristic & descriptor discovery/processing, the following data is used to keep track of things */
    uint16          service_search_index;   /* When service searching, this is an index to keep track of the service being processed */ 
    uint16          processing_start;       /* When service searching, this is the start handle for the service being processed */
    uint16          processing_end;         /* When service searching, this is the end handle for the service being processed*/
    uint16          processing_index;       /* Index used when processing the discovered descriptors */
    uint16          reading_handle;         /* Used when reading a characteristic to ensure the right one is returned */
    
    /* TODO : processing_index & disco_counter can be the same variable to save one word */
    
} remoteController_t;


/*
    Task data required by the input monitor for the BLE HID Remote Controller
*/
typedef struct
{
    TaskData            task;                       /* The task that is responsible for communicating with the BLE HID RC */
    timerConfig_t       *timers;                    /* The timers configured (for SHORT/LONG/VLONG etc.), these are part of the InputManager config so just obtain a pointer to that memory area rather than creating a duplicate local copy (makes references to those timers easier to read) */
    uint16              size_lookup_table;          /* The number of entries in the lookup table */
    uint16              active_remotes;             /* Keep track of how many remote controllers are connected at any one time */
    
    unsigned            pairing_mode:1;             /* Flag indicating whether or not BLE pairing mode is enabled */
    unsigned            ad_scan_disabled:1;         /* Set this flag to disable AD scanning to ensure RC's cannot be reconnected */
    
    /* PTS Control data */
    unsigned            pts_test_mode:1;            /* Flag indicating whether or not BLE PTS Test Mode is enabled */
    unsigned            pts_write_with_response:1;  /* Flag to set the write mode, if set, gives priority to "Write With Response (W)" mode, if unset, gives priority to "Write Without Response (WWR)" mode (for writing data to characteristics) */
    unsigned            reserved:12;
    
    bleHidRcConfig_t    *config;                    /* Stores the configuration data required by the BLE remote controller task */
    remoteController_t  *remotes;                   /* Store data for each connected remote controller */

} bleHidRCTaskData_t; 


/****************************************************************************
NAME    
    initBleInputMonitor
    
DESCRIPTION
    Function to initialise the BLE HID Remote Controller Task
*/
void initBleHidInputMonitor( timerConfig_t * timers );


/****************************************************************************
NAME    
    bleEnablePtsTestMode
    
DESCRIPTION
    Function to enable PTS Test Mode to run the BLE HOGP PTS tests
*/
void bleEnablePtsTestMode(void);


/****************************************************************************
NAME    
    bleDisablePtsTestMode
    
DESCRIPTION
    Function to disable PTS Test Mode
*/
void bleDisablePtsTestMode(void);


/****************************************************************************
NAME    
    blePtsModeNext
    
DESCRIPTION
    Function to progress to the next stage of remote device service/characteristic
    discovery when running in PTS test mode
*/
void blePtsModeNext(void);


/****************************************************************************
NAME    
    bleChangeWriteModePriority
    
DESCRIPTION
    Function to change the write mode priority for writing data to 
    characteristics on the remote device
*/
void bleChangeWriteModePriority(void);


/****************************************************************************
NAME    
    bleEnablePairingMode
    
DESCRIPTION
    Function to enable BLE pairing mode (whilst this mode is active, new
    BLE remote controllers can pair & connect), when this mode is disabled,
    only paired BLE remote controllers can connect (if BLE scans are enabled)
*/
void bleEnablePairingMode(void);


/****************************************************************************
NAME    
    bleDisablePairingMode
    
DESCRIPTION
    Function to disable BLE pairing mode
*/
void bleDisablePairingMode(void);


/****************************************************************************
NAME    
    bleRemotePairingComplete
    
DESCRIPTION
    Function to handle when pairing with a BLE remote controller has been
    completed
*/
void bleRemotePairingComplete(bool pairing_successful);


/****************************************************************************
NAME    
    handleBleRemotePairingComplete
    
DESCRIPTION
    Function to handle when the pairing has completed with the BLE remote,
    will generate either EventSysBleRemotePairingSuccess or 
    EventSysBleRemotePairingFailed to be handled; doing it this way can
    have a tone / LED filter associated to inform the user of the outcome
*/
void handleBleRemotePairingComplete( CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND_T * m );


/****************************************************************************
NAME    
    hogpHandleRemoteAdvertisingReportInd
    
DESCRIPTION
    Function to handle when the device recieves an advertisment from a BLE
    device (that matches the BLE filter we setup)
*/
void hogpHandleRemoteAdvertisingReportInd(CL_DM_BLE_ADVERTISING_REPORT_IND_T * m);


/****************************************************************************
NAME    
    bleConnectStoredRemote
    
DESCRIPTION
    Function to connect the stored (pre-configured) BLE remote controller
*/
void bleConnectStoredRemote(void);


/****************************************************************************
NAME    
    bleEnterSuspendMode
    
DESCRIPTION
    Function to enter suspend mode; used to inform any connected remote 
    controllers that the report host is entering low power mode
*/
void bleEnterSuspendMode(void);


/****************************************************************************
NAME    
    bleExitSuspendMode
    
DESCRIPTION
    Function to exit suspend mode; used to inform any connected remote 
    controllers that the report host is exiting low power mode
*/
void bleExitSuspendMode(void);


/****************************************************************************
NAME    
    bleEnableNotifications
    
DESCRIPTION
    Function to enable notifications for all connected devices
*/
void bleEnableNotifications(void);


/****************************************************************************
NAME    
    bleDisableNotifications
    
DESCRIPTION
    Function to disable notifications for all connected devices
*/
void bleDisableNotifications(void);


/****************************************************************************
NAME    
    bleDisconnectStoredRemote
    
DESCRIPTION
    Function to disconnect the stored (pre-configured) BLE remote controller
*/
void bleDisconnectStoredRemote(void);


/*******************************************************************************
NAME    
    hogpHandleGattConnectCfm
    
DESCRIPTION
    Function to handle GATT_CONNECT_CFM messages
*/
void hogpHandleGattConnectCfm( GATT_CONNECT_CFM_T * m );


/****************************************************************************
NAME
    hogpHandleGattDiscoverAllPrimaryServicesCfm
    
DESCRIPTION
    Function to handle GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM
*/
void hogpHandleGattDiscoverAllPrimaryServicesCfm( GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM_T * m );


/*******************************************************************************
NAME
    hogpHandleGattDiscoverAllCharacteristicsCfm

DESCRIPTION
    Function to handle GATT_DISCOVER_ALL_CHARACTERISTICS_CFM_T
*/
void hogpHandleGattDiscoverAllCharacteristicsCfm( GATT_DISCOVER_ALL_CHARACTERISTICS_CFM_T * m);



/*******************************************************************************
NAME
    hogpHandleGattDiscoverAllCharacteristicDescriptorsCfm

DESCRIPTION
    Function to handle GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM
*/
void hogpHandleGattDiscoverAllCharacteristicDescriptorsCfm( GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM_T * m );



/*******************************************************************************
NAME
    hogpHandleGattFindIncludedServicesCfm

DESCRIPTION
    Function to handle GATT_FIND_INCLUDED_SERVICES_CFM
*/
void hogpHandleGattFindIncludedServicesCfm( GATT_FIND_INCLUDED_SERVICES_CFM_T * m );


/*******************************************************************************
NAME
    hogpHandleGattReadCharacteristicValueCfm

DESCRIPTION
    Function to handle GATT_READ_CHARACTERISTIC_VALUE_CFM
*/
void hogpHandleGattReadCharacteristicValueCfm( GATT_READ_CHARACTERISTIC_VALUE_CFM_T * m );


/*******************************************************************************
NAME
    hogpHandleGattReadCharacteristicValueCfm

DESCRIPTION
    Function to handle GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM
*/
void hogpHandleGattReadLongCharacteristicValueCfm(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T * m);


/*******************************************************************************
NAME
    hogpHandleGattWriteWithoutResponseCfm

DESCRIPTION
    Function to handle GATT write requests, handles GATT message:
    GATT_WRITE_WITHOUT_RESPONSE_CFM
*/
void hogpHandleGattWriteWithoutResponseCfm( GATT_WRITE_WITHOUT_RESPONSE_CFM_T * m );


/*******************************************************************************
NAME
    hogpHandleGattWriteCharacteristicCfm

DESCRIPTION
    Function to handle GATT write requests, handles GATT message:
    GATT_WRITE_CHARACTERISTIC_VALUE_CFM
*/
void hogpHandleGattWriteCharacteristicCfm( GATT_WRITE_CHARACTERISTIC_VALUE_CFM_T * m );


/*******************************************************************************
NAME
    hogpHandleGattNotificationInd

DESCRIPTION
    Function to handle GATT_NOTIFICATION_IND
*/
void hogpHandleGattNotificationInd( GATT_NOTIFICATION_IND_T * m );


/*******************************************************************************
NAME
    hogpHandleGattIndicationInd

DESCRIPTION
    Handle when the remote device sends an indication
*/
void hogpHandleGattIndicationInd( GATT_INDICATION_IND_T * m );


/*******************************************************************************
NAME
    hogpHandleGattDisconnectInd

DESCRIPTION
    Function to handle GATT_DISCONNECT_IND 
*/
void hogpHandleGattDisconnectInd( GATT_DISCONNECT_IND_T * m );


/*******************************************************************************
NAME
    bleDisconnectAllConnectedRemotes

DESCRIPTION
    Function to disconnect all connected remote controllers

RETURNS
    Number of connected remote controllers that have been sent disconnection
    requests
*/
uint16 bleDisconnectAllConnectedRemotes( bool hard_reset );


/* Macro used by the BLE "Input Monitor" to generate messages to send itself */
#define MAKE_BLE_RC_HID_MESSAGE(TYPE) TYPE##_T *message = PanicUnlessNew(TYPE##_T);


#endif /* defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED) */

#endif /* _SINK_BLE_REMOTE_CONTROL_H_ */
