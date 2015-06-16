/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_usb.h
    
DESCRIPTION
    
*/
#ifndef _SINK_USB_H_
#define _SINK_USB_H_

#include <stdlib.h>

#define USB_DEVICE_CLASS_AUDIO      (USB_DEVICE_CLASS_TYPE_AUDIO_SPEAKER | USB_DEVICE_CLASS_TYPE_AUDIO_MICROPHONE)

typedef enum
{
    usb_audio_suspend_none,
    usb_audio_suspend_local,
    usb_audio_suspend_remote
} usb_audio_suspend_state;

typedef enum
{
    usb_plugin_stereo,
    usb_plugin_mono_nb,
    usb_plugin_mono_wb
} usb_plugin_type;

typedef struct
{
    sink_charge_current     i_disc;                 /* Current when USB disconnected but charger connected */
    sink_charge_current     i_susp;                 /* Current when suspended */
    sink_charge_current     i_susp_db;              /* Current when suspended prior to enumeration with dead battery*/
    sink_charge_current     i_att;                  /* Current when attached but not enumerated */
    sink_charge_current     i_att_trickle;          /* Current when attached but not enumerated and trickle charging */
    sink_charge_current     i_conn;                 /* Current when connected to host/hub */
    sink_charge_current     i_conn_trickle;         /* Current when connected to host/hub and trickle charging */
    sink_charge_current     i_chg;                  /* Current when connected to a charging host/hub */
    sink_charge_current     i_dchg;                 /* Current when connected to a dedicated charger */
    sink_charge_current     i_lim;                  /* Current when vbus drop is detected */
    unsigned                audio_always_on:1;      /* Route USB audio even if not in use */
    unsigned                unused:1;
    usb_plugin_type         plugin_type:2;          /* Mono/Stereo */
    unsigned                plugin_index:4;         /* USB plugin to use */
    unsigned                attach_timeout:4;       /* Time (seconds) after attach at which we set low power bootmode if not enumerated */
    unsigned                deconfigured_timeout:4; /* Time (seconds) after deconfigure at which we set low power bootmode if not enumerated */
    usb_device_class_type   device_class;           /* Class of device */
} usb_config; 

typedef struct
{
    usb_config          config;                 /* USB config */
    unsigned            ready:1;                /* Ready */
    unsigned            enumerated:1;           /* USB enumerated */
    unsigned            suspended:1;            /* Suspended */
    unsigned            mic_active:1;           /* USB Mic in use */
    unsigned            spkr_active:1;          /* USB Speaker in use */
    unsigned            vbus_okay:1;            /* VBUS above threshold */
    unsigned            dead_battery:1;         /* Battery is below dead battery threshold */
    unsigned            deconfigured:1;         /* USB has been deconfigured */
    unsigned            audio_suspend_state:2;  /* Current USB audio suspend state */
    unsigned            unused:6;
} usb_info;

typedef struct
{
    FILE_INDEX  index;
    uint32      size;
} usb_file_info;

#define USB_NAME_SIZE 8
#define USB_EXT_SIZE  3

typedef struct
{
    char name[USB_NAME_SIZE];
    char ext[USB_EXT_SIZE];
} usb_file_name;

typedef struct
{
    char  name[USB_NAME_SIZE + USB_EXT_SIZE + 1];
    uint8 size;
} usb_file_name_info;

#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)


typedef struct
{
    uint32                               sample_rate;
    const usb_device_class_audio_config* usb_descriptors;
    usb_plugin_type                      plugin_type;
} usb_plugin_info;

/* Define some easier to read values... */
#define USB_PLAY_PAUSE  USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PLAY_PAUSE
#define USB_STOP        USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_STOP
#define USB_FWD         USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_NEXT_TRACK
#define USB_BCK         USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PREVIOUS_TRACK
#define USB_VOL_UP      USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_UP
#define USB_VOL_DN      USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_DOWN
#define USB_MUTE        USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_MUTE

#endif

/*************************************************************************
NAME    
    usbAudioSuspended
    
DESCRIPTION
    Obtains the audio suspend state for USB

RETURNS
    Current audio suspend state
    
**************************************************************************/
usb_audio_suspend_state usbAudioSuspended (void);

/*************************************************************************
NAME    
    usbSetAudioSuspendState
    
DESCRIPTION
    Sets the audio suspend state for USB

RETURNS
    None
    
**************************************************************************/
void usbSetAudioSuspendState (usb_audio_suspend_state state);

/****************************************************************************
NAME 
    usbUpdateChargeCurrent
    
DESCRIPTION
    Set the charge current based on USB state
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void usbUpdateChargeCurrent(void);
#else
#define usbUpdateChargeCurrent() ((void)(0))
#endif


/****************************************************************************
NAME 
    usbSetBootMode
    
DESCRIPTION
    Set the boot mode to default or low power
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void usbSetBootMode(uint8 bootmode);
#else
#define usbSetBootMode(x) ((void)(0))
#endif



/****************************************************************************
NAME 
    handleUsbMessage
    
DESCRIPTION
    Handle firmware USB messages
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void handleUsbMessage(Task task, MessageId id, Message message);
#else
#define handleUsbMessage(task, id, message) ((void)(0))
#endif


/****************************************************************************
NAME 
    usbTimeCriticalInit
    
DESCRIPTION
    Initialise USB. This function is time critical and must be called from
    _init. This will fail if either Host Interface is not set to USB or
    VM control of USB is FALSE in PS. It may also fail if Transport in the
    project properties is not set to USB VM.
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void usbTimeCriticalInit(void);
#else
#define usbTimeCriticalInit() ((void)(0))
#endif


/****************************************************************************
NAME 
    usbInit
    
DESCRIPTION
    Initialisation done once the main loop is up and running. Determines USB
    attach status etc.
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void usbInit(void);
#else
#define usbInit() ((void)(0))
#endif


/****************************************************************************
NAME 
    usbSetVbusLevel
    
DESCRIPTION
    Set whether VBUS is above or below threshold
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void usbSetVbusLevel(voltage_reading vbus);
#else
#define usbSetVbusLevel(x) ((void)(0))
#endif


/****************************************************************************
NAME 
    usbSetDeadBattery
    
DESCRIPTION
    Set whether VBAT is below the dead battery threshold
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
void usbSetVbatDead(bool dead);
#else
#define usbSetVbatDead(x) ((void)(0))
#endif


/****************************************************************************
NAME 
    usbGetChargeCurrent
    
DESCRIPTION
    Get USB charger limits
    
RETURNS
    void
*/ 
#ifdef ENABLE_USB
sink_charge_current* usbGetChargeCurrent(void);
#else
#define usbGetChargeCurrent() (NULL)
#endif


/****************************************************************************
NAME 
    usbSendHidEvent
    
DESCRIPTION
    Send HID event over USB
    
RETURNS
    void
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbSendHidEvent(usb_device_class_event event);
#else
#define usbSendHidEvent(x) ((void)(0))
#endif

#define usbPlayPause()  usbSendHidEvent(USB_PLAY_PAUSE)
#define usbStop()       usbSendHidEvent(USB_STOP)
#define usbFwd()        usbSendHidEvent(USB_FWD)
#define usbBck()        usbSendHidEvent(USB_BCK)
#define usbVolUp()      usbSendHidEvent(USB_VOL_UP)
#define usbVolDn()      usbSendHidEvent(USB_VOL_DN)
#define usbMute()       usbSendHidEvent(USB_MUTE)


/****************************************************************************
NAME 
    usbIsAttached
    
DESCRIPTION
    Determine if USB is attached
    
RETURNS
    TRUE if USB is attached, FALSE otherwise
*/ 
#ifdef ENABLE_USB
bool usbIsAttached(void);
#else
#define usbIsAttached() (FALSE)
#endif


/****************************************************************************
NAME 
    usbAudioIsAttached
    
DESCRIPTION
    Determine if USB Audio is attached
    
RETURNS
    TRUE if USB Audio is attached, FALSE otherwise
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
bool usbAudioIsAttached(void);
#else
#define usbAudioIsAttached() (FALSE)
#endif

/****************************************************************************
NAME 
 usbCheckDeviceTrimVol

DESCRIPTION
 check whether USB streaming is ongoing and if currently active and routing audio to the device, adjust the volume up or down
 as appropriate.

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
bool usbCheckDeviceTrimVol(volume_direction dir, tws_device_type tws_device);
#else
#define usbCheckDeviceTrimVol(dir,tws_device) (FALSE)
#endif


/****************************************************************************
NAME 
    usbAudioSinkMatch
    
DESCRIPTION
    Compare sink to the USB audio sink
    
RETURNS
    TRUE if sink matches USB audio sink, otherwise FALSE
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
bool usbAudioSinkMatch(Sink sink);
#else
#define usbAudioSinkMatch(sink) (FALSE)
#endif


/****************************************************************************
NAME 
    usbAudioRoute
    
DESCRIPTION
    Connect USB audio stream
    
RETURNS
    void
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbAudioRoute(void);
#else
#define usbAudioRoute() ((void)(0))
#endif


/*************************************************************************
NAME    
    usbAudioSuspend
    
DESCRIPTION
    Issue HID consumer control command to attempt to pause current USB stream

RETURNS
    None
    
**************************************************************************/
void usbAudioSuspend (void);

/*************************************************************************
NAME    
    usbAudioResume
    
DESCRIPTION
    Issue HID consumer control command to attempt to resume current USB stream

RETURNS
    None
    
**************************************************************************/
void usbAudioResume (void);

/****************************************************************************
NAME 
    usbAudioDisconnect
    
DESCRIPTION
    Disconnect USB audio stream
    
RETURNS
    void
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbAudioDisconnect(void);
#else
#define usbAudioDisconnect() ((void)(0))
#endif
        

/****************************************************************************
NAME 
    usbAudioSetVolume
    
DESCRIPTION
    Set USB audio volume
    
RETURNS
    void
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbAudioSetVolume(void);
#else
#define usbAudioSetVolume() ((void)(0))
#endif


/****************************************************************************
NAME 
    usbAudioGetMode
    
DESCRIPTION
    Get the current USB audio mode if USB in use
    
RETURNS
    void
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbAudioGetMode(AUDIO_MODE_T* mode);
#else
#define usbAudioGetMode(x) ((void)(0))
#endif

/****************************************************************************
NAME 
    usbGetAudioSink
    
DESCRIPTION
    check USB state and return sink if available
    
RETURNS
   sink if available, otherwise 0
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
Sink usbGetAudioSink(void);
#else
#define usbGetAudioSink() (NULL)
#endif

/****************************************************************************
NAME 
    usbAudioSetSpeakerSampleRate
    
DESCRIPTION
    check if the sample rate has change, whether usb audio is currently streaming
    , if so a restart of the sbc_decoder is necessary to run at the new indicated rate
    
RETURNS
    none
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbAudioSetSpeakerSampleRate(uint16 sample_rate);
#else
#define usbAudioSetSpeakerSampleRate(x) (NULL)
#endif


/****************************************************************************
NAME 
    usbAudioSetMicSampleRate
    
DESCRIPTION
    check if the sample rate has change, whether usb audio is currently streaming
    , if so a restart of the sbc_decoder may be necessary to run at the new indicated rate
    
RETURNS
    none
*/ 
#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
void usbAudioSetMicSampleRate(uint16 sample_rate);
#else
#define usbAudioSetMicSampleRate(x) (NULL)
#endif

#endif /* _SINK_USB_H_ */
