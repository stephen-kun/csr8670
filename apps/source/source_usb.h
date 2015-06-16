/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_usb.h

DESCRIPTION
    USB functionality.
    
*/


#ifndef _SOURCE_USB_H_
#define _SOURCE_USB_H_


/* profile/library headers */
#include <avrcp.h>
#include <usb_device_class.h>
/* VM headers */
#include <sink.h>


/* HID Descriptor */
#define USB_HID_DESCRIPTOR_LENGTH 9
#define USB_B_DESCRIPTOR_TYPE_HID 0x21
#define USB_B_DESCRIPTOR_TYPE_HID_REPORT 0x22
#define USB_HID_CONSUMER_TRANSPORT_REPORT_DESCRIPTOR_LENGTH 98

/* Audio Descriptor Unit/Terminal IDs */
#define USB_AUDIO_SPEAKER_IT            0x01
#define USB_AUDIO_SPEAKER_FU            0x02
#define USB_AUDIO_SPEAKER_OT            0x03
#define USB_AUDIO_MIC_IT                0x04
#define USB_AUDIO_MIC_FU                0x05
#define USB_AUDIO_MIC_OT                0x06

/* USB Audio Sample Rates and Packet Sizes */
/* The Mic configuration is the audio sent to USB. The Speaker configuration is the audio received from USB. */
#define USB_AUDIO_PACKET_RATE_MS        1000
#define USB_AUDIO_SAMPLE_SIZE           2
#define USB_AUDIO_CHANNELS_MIC          1
#define USB_AUDIO_CHANNEL_CONFIG_MIC    1

#define MS_LYNC_ONLY_BUILDx /* define for mono USB @16kHz for a MS Lync audio build, otherwise use USB @48kHz */

#ifndef MS_LYNC_ONLY_BUILD
/* non-Lync build set to 48kHz USB audio (stereo audio received from USB and sent to remote device, 
    mono audio received from the remote device and sent to USB) */
#define USB_AUDIO_STEREO_SPEAKER
#ifdef USB_MIC_16K      /* Back channel is output at 16 kHz over USB */
  #define USB_AUDIO_SAMPLE_RATE_MIC           (uint32)16000
#else
  #define USB_AUDIO_SAMPLE_RATE_MIC           (uint32)48000
#endif
#define USB_AUDIO_SAMPLE_RATE_SPEAKER       (uint32)48000
#define USB_AUDIO_CHANNELS_SPEAKER          2
#define USB_AUDIO_CHANNEL_CONFIG_SPEAKER    3
#else
/* Lync build set to 16kHz USB audio (mono audio received from USB and sent to remote device, 
    mono audio received from the remote device and sent to USB) */
#define USB_AUDIO_SAMPLE_RATE_MIC           (uint32)16000
#define USB_AUDIO_SAMPLE_RATE_SPEAKER       (uint32)16000
#define USB_AUDIO_CHANNELS_SPEAKER          1
#define USB_AUDIO_CHANNEL_CONFIG_SPEAKER    1
#endif

#define USB_AUDIO_MAX_PACKET_SIZE_MIC       (USB_AUDIO_SAMPLE_RATE_MIC / (USB_AUDIO_PACKET_RATE_MS / USB_AUDIO_SAMPLE_SIZE) * USB_AUDIO_CHANNELS_MIC)
#define USB_AUDIO_MAX_PACKET_SIZE_SPEAKER   (USB_AUDIO_SAMPLE_RATE_SPEAKER / (USB_AUDIO_PACKET_RATE_MS / USB_AUDIO_SAMPLE_SIZE) * USB_AUDIO_CHANNELS_SPEAKER)


/* HID Report Types */
#define USB_CONSUMER_REPORT_ID          0x02
#define USB_CONSUMER_REPORT_SIZE        18 

/* Delay (in ms) before starting audio when active interface message received */
#define USB_AUDIO_ACTIVE_DELAY          500
/* Delay (in ms) before acting on active Mic */
#define MIC_AUDIO_ACTIVE_DELAY          500
/* Delay (in ms) before acting on inactive Mic */
#define MIC_AUDIO_INACTIVE_DELAY        500


/* HID modes */
typedef enum
{
    USB_HID_MODE_CONSUMER
    ,USB_HID_MODE_HOST
} USB_HID_MODE_T;

/* USB data structure */
typedef struct
{
    USB_HID_MODE_T hid_mode;
    unsigned ffwd_press:1;
    unsigned rew_press:1;
    unsigned unused:14;
} USB_DATA_T;


/* Possible Host Commands sent to Device */
typedef enum
{
    USB_HOST_COMMAND_HOST_CONNECTION,
    USB_HOST_COMMAND_STATE,
    USB_HOST_COMMAND_AG_CALL_STATE,
    USB_HOST_COMMAND_AG_SIGNAL_STRENGTH,
    USB_HOST_COMMAND_AG_BATTERY_LEVEL,
    USB_HOST_COMMAND_AG_AUDIO,
    USB_HOST_COMMAND_AG_NETWORK,
    USB_HOST_COMMAND_AG_ERROR,
    USB_HOST_COMMAND_AG_OK,
    USB_HOST_COMMAND_AG_CURRENT_CALL,
	USB_HOST_COMMAND_AG_VOICE_RECOGNITION
} USB_HOST_COMMAND_T;

/* Data sent with USB_HOST_COMMAND_HOST_CONNECTION command Host->Device */
typedef enum
{
    USB_HOST_DATA_HOST_CONNECTION_DISCONNECTED,
    USB_HOST_DATA_HOST_CONNECTION_CONNECTED
} USB_HOST_DATA_HOST_CONNECTION_T;

/* Data sent with USB_HOST_COMMAND_STATE command Host->Device */
typedef enum
{
    USB_HOST_DATA_STATE_GET_STATE,
    USB_HOST_DATA_STATE_ENTER_DFU_MODE,
    USB_HOST_DATA_STATE_ENTER_DUT_MODE,
    USB_HOST_DATA_STATE_INQUIRY,
    USB_HOST_DATA_STATE_INQUIRY_SCAN,
    USB_HOST_DATA_STATE_PAGE,
    USB_HOST_DATA_STATE_PAGE_SCAN  
} USB_HOST_DATA_STATE_T;

/* Data sent with USB_HOST_COMMAND_AG_CALL_STATE command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_CALL_STATE_NONE,
    USB_HOST_DATA_AG_CALL_STATE_INCOMING,
    USB_HOST_DATA_AG_CALL_STATE_OUTGOING,
    USB_HOST_DATA_AG_CALL_STATE_ACTIVE, 
    USB_HOST_DATA_AG_CALL_STATE_CALL_WAITING_ACTIVE_CALL,
    USB_HOST_DATA_AG_CALL_STATE_CALL_HELD_ACTIVE_CALL,
    USB_HOST_DATA_AG_CALL_STATE_CALL_HELD
} USB_HOST_DATA_AG_CALL_STATE_T;

/* Data sent with USB_HOST_COMMAND_SIGNAL_STRENGTH command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_SIGNAL_STRENGTH_VALUE
} USB_HOST_DATA_AG_SIGNAL_STRENGTH_T;

/* Data sent with USB_HOST_COMMAND_BATTERY_LEVEL command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_BATTERY_LEVEL_VALUE
} USB_HOST_DATA_AG_BATTERY_LEVEL_T;

/* Data sent with USB_HOST_COMMAND_AG_AUDIO command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_AUDIO_GET_STATE,
    USB_HOST_DATA_AG_AUDIO_TRANSFER
} USB_HOST_DATA_AG_AUDIO_T;

/* Data sent with USB_HOST_COMMAND_AG_NETWORK command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_NETWORK_OPERATOR,
    USB_HOST_DATA_AG_NETWORK_AVAILABILITY,
	USB_HOST_DATA_AG_NETWORK_ROAM
} USB_HOST_DATA_AG_NETWORK_T;

/* Data sent with USB_HOST_COMMAND_AG_ERROR command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_ERROR_INVALID_MEMORY_LOCATION,
	USB_HOST_DATA_AG_ERROR_INVALID_LAST_NUMBER_DIAL
} USB_HOST_DATA_AG_ERROR_T;

/* Data sent with USB_HOST_COMMAND_AG_OK command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_OK_VALID_MEMORY_LOCATION,
	USB_HOST_DATA_AG_OK_VALID_LAST_NUMBER_DIAL,
    USB_HOST_DATA_AG_OK_SENT_ALL_CURRENT_CALLS
} USB_HOST_DATA_AG_OK_T;

/* Data sent with USB_HOST_COMMAND_AG_CURRENT_CALL command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_CURRENT_CALL_DETAILS
} USB_HOST_DATA_AG_CURRENT_CALL_T;

/* Data sent with USB_HOST_COMMAND_AG_VOICE_RECOGNITION command Host->Device */
typedef enum
{
    USB_HOST_DATA_AG_VOICE_RECOGNITION_DISABLE,
	USB_HOST_DATA_AG_VOICE_RECOGNITION_ENABLE
} USB_HOST_DATA_AG_VOICE_RECOGNITION_T;

/* Possible Device Commands sent to Host */
typedef enum
{
    USB_DEVICE_COMMAND_STATE,
    USB_DEVICE_COMMAND_AG_CALL,
    USB_DEVICE_COMMAND_AG_AUDIO_STATE,
	USB_DEVICE_COMMAND_AG_VOICE_RECOGNITION  
} USB_DEVICE_COMMAND_T;

/* Data sent with USB_DEVICE_COMMAND_STATE command Device->Host */
typedef enum
{
    USB_DEVICE_DATA_STATE_INQUIRY,
    USB_DEVICE_DATA_STATE_INQUIRY_SCAN,
    USB_DEVICE_DATA_STATE_PAGE,
    USB_DEVICE_DATA_STATE_PAGE_SCAN, 
    USB_DEVICE_DATA_STATE_CONNECTED,
    USB_DEVICE_DATA_STATE_UNKNOWN
} USB_DEVICE_DATA_STATE_T;

/* Data sent with USB_DEVICE_COMMAND_AG_CALL command Device->Host */
typedef enum
{
    USB_DEVICE_COMMAND_AG_CALL_ACCEPT,
    USB_DEVICE_COMMAND_AG_CALL_REJECT,
    USB_DEVICE_COMMAND_AG_CALL_NUMBER_SUPPLIED,
    USB_DEVICE_COMMAND_AG_CALL_MEMORY,
    USB_DEVICE_COMMAND_AG_CALL_LAST_NUMBER,
    USB_DEVICE_COMMAND_AG_CALL_GET_CURRENT_CALLS
} USB_DEVICE_DATA_AG_CALL_T;

/* Data sent with USB_DEVICE_COMMAND_AG_AUDIO_STATE command Device->Host */
typedef enum
{
    USB_DEVICE_DATA_AG_AUDIO_STATE_NO_SLC_CONNECTION,
    USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_DISCONNECTED,
    USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_CONNECTED
} USB_DEVICE_DATA_AG_AUDIO_STATE_T;

/* Data sent with USB_DEVICE_COMMAND_AG_VOICE_RECOGNITION command Device->Host */
typedef enum
{
    USB_DEVICE_DATA_AG_VOICE_RECOGNITION_DISABLE,
    USB_DEVICE_DATA_AG_VOICE_RECOGNITION_ENABLE
} USB_DEVICE_DATA_AG_VOICE_RECOGNITION_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    usb_time_critical_init

DESCRIPTION
    Enumerate as a USB device before the main application starts up. 
 
*/
void usb_time_critical_init(void);


/****************************************************************************
NAME    
    usb_get_speaker_source

DESCRIPTION
    Finds the speaker Source. 
 
RETURNS
    The speaker Source.
    
*/
Source usb_get_speaker_source(void);


/****************************************************************************
NAME    
    usb_get_mic_sink

DESCRIPTION
    Finds the mic Sink. 
 
RETURNS
    The mic Sink.
    
*/
Sink usb_get_mic_sink(void);


/****************************************************************************
NAME    
    usb_get_audio_levels_update_headset

DESCRIPTION
    Retrieves the USB audio levels and optionally sends the local volumes to the remote device. 
    
*/
void usb_get_audio_levels_update_headset(bool only_if_volumes_changed);


/****************************************************************************
NAME    
    usb_send_media_hid_command

DESCRIPTION
    Sends a USB HID media command to the host.
    
*/
void usb_send_media_hid_command(avc_operation_id op_id, bool state);


/****************************************************************************
NAME    
    usb_get_hid_mode

DESCRIPTION
    Finds the current HID mode.
    
RETURNS
    The current HID mode.    
    
*/
USB_HID_MODE_T usb_get_hid_mode(void);


/****************************************************************************
NAME    
    usb_set_hid_mode

DESCRIPTION
    Sets the current HID mode.
    
*/
void usb_set_hid_mode(USB_HID_MODE_T mode);


/****************************************************************************
NAME    
    usb_send_vendor_state

DESCRIPTION
    Sends the new application state to the host.
    
*/
void usb_send_vendor_state(void);


/****************************************************************************
NAME    
    usb_handle_report

DESCRIPTION
    Handle a the USB_DEVICE_CLASS_MSG_REPORT_IND message indicating a USB report sent from the host.
    
*/
void usb_handle_report(const USB_DEVICE_CLASS_MSG_REPORT_IND_T *msg);


/****************************************************************************
NAME    
    usb_rewind_release

DESCRIPTION
    Sends a USB HID Rewind release event to the host.
    
*/
void usb_rewind_release(void);


/****************************************************************************
NAME    
    usb_fast_forward_release

DESCRIPTION
    Sends a USB HID Fast Forward release event to the host.
    
*/
void usb_fast_forward_release(void);


/****************************************************************************
NAME    
    usb_send_hid_answer

DESCRIPTION
    Sends a HID command to answer a call.
    
*/
void usb_send_hid_answer(void);


/****************************************************************************
NAME    
    usb_send_hid_hangup

DESCRIPTION
    Sends a HID command to hang up a call.
    
*/
void usb_send_hid_hangup(void);


/****************************************************************************
NAME    
    usb_send_device_command_accept_call
    
DESCRIPTION
    Send accept call event to host
    
*/
bool usb_send_device_command_accept_call(void);


/****************************************************************************
NAME    
    usb_send_device_command_reject_call
    
DESCRIPTION
    Send reject call event to host
    
*/
bool usb_send_device_command_reject_call(void);


/****************************************************************************
NAME    
    usb_send_device_command_dial_number
    
DESCRIPTION
    Send number to dial to the Host
    
*/
bool usb_send_device_command_dial_number(uint16 size_number, uint8 *number);


/****************************************************************************
NAME    
    usb_send_device_command_dial_memory
    
DESCRIPTION
    Send memory location to dial to the Host
    
*/
bool usb_send_device_command_dial_memory(uint16 size_number, uint8 *number);


/****************************************************************************
NAME    
    usb_send_device_command_dial_last
    
DESCRIPTION
    Send last number dial to the Host
    
*/
bool usb_send_device_command_dial_last(void);


/****************************************************************************
NAME    
    usb_send_device_command_audio_state

DESCRIPTION
    Sends the audio connection state to the Host
    
*/
bool usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_T state);


/****************************************************************************
NAME    
    usb_send_device_command_current_calls

DESCRIPTION
    Sends the command the get the current call list to the Host
    
*/
bool usb_send_device_command_current_calls(void);


/****************************************************************************
NAME    
    usb_send_device_command_voice_recognition

DESCRIPTION
    Sends the voice recognition state to the Host.
*/    
bool usb_send_device_command_voice_recognition(bool enable);


/****************************************************************************
NAME    
    usb_get_speaker_sample_rate

DESCRIPTION
    Gets the configured USB sample rate for the speaker.
*/    
uint32 usb_get_speaker_sample_rate(void);


#endif /* _SOURCE_USB_H_ */
