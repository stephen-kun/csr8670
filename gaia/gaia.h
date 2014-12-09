/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2010-2014
Part of ADK 3.5

*/
 
/*!
    @file gaia.h
    @brief Header file for the Generic Application Interface Architecture library

    This library implements the GAIA protocol.

    The library exposes a functional downstream API and a message-based upstream API.
*/

#ifndef _GAIA_H_
#define _GAIA_H_

#include <library.h>
#include <stdlib.h>
#include <bdaddr.h>
#include <message.h>

/*  API Version 2.0  */
#define GAIA_API_VERSION_MAJOR (2)
#define GAIA_API_VERSION_MINOR (0)

#define GAIA_PROTOCOL_FLAG_CHECK (0x01)

#define GAIA_VENDOR_CSR (0x000A)
#define GAIA_VENDOR_NONE (0x7FFE)

#define GAIA_HEADER_SIZE (8)
#define GAIA_MAX_PACKET (255)  /* It's theoretically 262, but ... */
#define GAIA_MAX_PAYLOAD (254)

#define GAIA_MAX_FEATURE_BIT (63)
#define GAIA_FEATURE_DATA_TRANSFER (25)
#define GAIA_FEATURE_ENABLE_SESSION (26)
#define GAIA_FEATURE_CUSTOM_SDP (27)
#define GAIA_FEATURE_CHANGE_CONFIGURATION (28)
#define GAIA_FEATURE_NOTIFY_START (29)
#define GAIA_FEATURE_DEBUG (30)
#define GAIA_FEATURE_DEBUG_MODIFY (31)

#define GAIA_FEATURE_DISABLED (0x00)
#define GAIA_FEATURE_ENABLED (0x01)

#define GAIA_ACK_MASK (0x8000)
#define GAIA_COMMAND_INTENT_GET (0x0080)

#define GAIA_COMMAND_TYPE_MASK (0x7F00)
#define GAIA_COMMAND_TYPE_CONFIGURATION (0x0100)
#define GAIA_COMMAND_TYPE_CONTROL (0x0200)
#define GAIA_COMMAND_TYPE_STATUS (0x0300)
#define GAIA_COMMAND_TYPE_FEATURE (0x0500)
#define GAIA_COMMAND_TYPE_DATA_TRANSFER (0x0600)
#define GAIA_COMMAND_TYPE_DEBUG (0x0700)
#define GAIA_COMMAND_TYPE_EXTENSION (0x2000)
#define GAIA_COMMAND_TYPE_NOTIFICATION (0x4000)

#define GAIA_COMMAND_SET_RAW_CONFIGURATION (0x0100)
#define GAIA_COMMAND_GET_RAW_CONFIGURATION (0x0180)
#define GAIA_COMMAND_SET_LED_CONFIGURATION (0x0101)
#define GAIA_COMMAND_GET_LED_CONFIGURATION (0x0181)
#define GAIA_COMMAND_SET_TONE_CONFIGURATION (0x0102)
#define GAIA_COMMAND_GET_TONE_CONFIGURATION (0x0182)
#define GAIA_COMMAND_SET_DEFAULT_VOLUME (0x0103)
#define GAIA_COMMAND_GET_DEFAULT_VOLUME (0x0183)
#define GAIA_COMMAND_FACTORY_DEFAULT_RESET (0x0104)
#define GAIA_COMMAND_GET_CONFIGURATION_ID (0x0184)
#define GAIA_COMMAND_SET_VIBRATOR_CONFIGURATION (0x0105)
#define GAIA_COMMAND_GET_VIBRATOR_CONFIGURATION (0x0185)
#define GAIA_COMMAND_SET_VOICE_PROMPT_CONFIGURATION (0x0106)
#define GAIA_COMMAND_GET_VOICE_PROMPT_CONFIGURATION (0x0186)
#define GAIA_COMMAND_SET_FEATURE_CONFIGURATION (0x0107)
#define GAIA_COMMAND_GET_FEATURE_CONFIGURATION (0x0187)
#define GAIA_COMMAND_SET_USER_EVENT_CONFIGURATION (0x0108)
#define GAIA_COMMAND_GET_USER_EVENT_CONFIGURATION (0x0188)
#define GAIA_COMMAND_SET_TIMER_CONFIGURATION (0x0109)
#define GAIA_COMMAND_GET_TIMER_CONFIGURATION (0x0189)
#define GAIA_COMMAND_SET_AUDIO_GAIN_CONFIGURATION (0x010A)
#define GAIA_COMMAND_GET_AUDIO_GAIN_CONFIGURATION (0x018A)
#define GAIA_COMMAND_SET_HFP_CONFIGURATION (0x010B)
#define GAIA_COMMAND_GET_HFP_CONFIGURATION (0x018B)
#define GAIA_COMMAND_SET_POWER_CONFIGURATION (0x010C)
#define GAIA_COMMAND_GET_POWER_CONFIGURATION (0x018C)
#define GAIA_COMMAND_SET_USER_TONE_CONFIGURATION (0x010E)
#define GAIA_COMMAND_GET_USER_TONE_CONFIGURATION (0x018E)
#define GAIA_COMMAND_SET_DEVICE_NAME (0x010F)
#define GAIA_COMMAND_GET_DEVICE_NAME (0x018F)
#define GAIA_COMMAND_SET_WLAN_CREDENTIALS (0x0110)
#define GAIA_COMMAND_GET_WLAN_CREDENTIALS (0x0190)
#define GAIA_COMMAND_GET_MOUNTED_PARTITIONS (0x01a0)

#define GAIA_LED_CONFIGURATION_STATE (0x01)
#define GAIA_LED_CONFIGURATION_EVENT (0x02)
#define GAIA_LED_CONFIGURATION_FILTER (0x03)

#define GAIA_LED_FILTER_CANCEL (0x01)
#define GAIA_LED_FILTER_SPEED (0x02)
#define GAIA_LED_FILTER_OVERRIDE (0x03)
#define GAIA_LED_FILTER_COLOUR (0x04)
#define GAIA_LED_FILTER_FOLLOW (0x05)

#define GAIA_COMMAND_CHANGE_VOLUME (0x0201)
#define GAIA_COMMAND_DEVICE_RESET (0x0202)
#define GAIA_COMMAND_GET_BOOTMODE (0x0282)
#define GAIA_COMMAND_SET_PIO_CONTROL (0x0203)
#define GAIA_COMMAND_GET_PIO_CONTROL (0x0283)
#define GAIA_COMMAND_POWER_OFF (0x0204)
#define GAIA_COMMAND_SET_VOLUME_ORIENTATION (0x0205)
#define GAIA_COMMAND_GET_VOLUME_ORIENTATION (0x0285)
#define GAIA_COMMAND_SET_VIBRATOR_CONTROL (0x0206)
#define GAIA_COMMAND_GET_VIBRATOR_CONTROL (0x0286)
#define GAIA_COMMAND_SET_LED_CONTROL (0x0207)
#define GAIA_COMMAND_GET_LED_CONTROL (0x0287)
#define GAIA_COMMAND_FM_CONTROL (0x0208)
#define GAIA_COMMAND_PLAY_TONE (0x0209)
#define GAIA_COMMAND_SET_VOICE_PROMPT_CONTROL (0x020A)
#define GAIA_COMMAND_GET_VOICE_PROMPT_CONTROL (0x028A)
#define GAIA_COMMAND_CHANGE_AUDIO_PROMPT_LANGUAGE (0x020B)
#define GAIA_COMMAND_SET_SPEECH_RECOGNITION_CONTROL (0x020C)
#define GAIA_COMMAND_GET_SPEECH_RECOGNITION_CONTROL (0x028C)
#define GAIA_COMMAND_ALERT_LEDS (0x020D)
#define GAIA_COMMAND_ALERT_TONE (0x020E)
#define GAIA_COMMAND_ALERT_EVENT (0x0210)
#define GAIA_COMMAND_ALERT_VOICE (0x0211)
#define GAIA_COMMAND_SET_AUDIO_PROMPT_LANGUAGE (0x0212)
#define GAIA_COMMAND_GET_AUDIO_PROMPT_LANGUAGE (0x0292)
#define GAIA_COMMAND_START_SPEECH_RECOGNITION (0x0213)
#define GAIA_COMMAND_SET_EQ_CONTROL (0x0214)
#define GAIA_COMMAND_GET_EQ_CONTROL (0x0294)
#define GAIA_COMMAND_SET_BASS_BOOST_CONTROL (0x0215)
#define GAIA_COMMAND_GET_BASS_BOOST_CONTROL (0x0295)
#define GAIA_COMMAND_SET_3D_ENHANCEMENT_CONTROL (0x0216)
#define GAIA_COMMAND_GET_3D_ENHANCEMENT_CONTROL (0x0296)
#define GAIA_COMMAND_SWITCH_EQ_CONTROL (0x0217)
#define GAIA_COMMAND_TOGGLE_BASS_BOOST_CONTROL (0x0218)
#define GAIA_COMMAND_TOGGLE_3D_ENHANCEMENT_CONTROL (0x0219)
#define GAIA_COMMAND_SET_USER_EQ_PARAMETER (0x021A)
#define GAIA_COMMAND_GET_USER_EQ_PARAMETER (0x029A)
#define GAIA_COMMAND_SET_USER_EQ_GROUP_PARAMETER (0x021B)
#define GAIA_COMMAND_GET_USER_EQ_GROUP_PARAMETER (0x029B)
#define GAIA_COMMAND_ENTER_BT_PAIRING_MODE (0x021D)
#define GAIA_COMMAND_SET_USER_EQ_CONTROL (0x0220)
#define GAIA_COMMAND_GET_USER_EQ_CONTROL (0x02A0)
#define GAIA_COMMAND_TOGGLE_USER_EQ_CONTROL (0x0221)
#define GAIA_COMMAND_SET_TWS_AUDIO_ROUTING (0x0224)
#define GAIA_COMMAND_GET_TWS_AUDIO_ROUTING (0x02A4)
#define GAIA_COMMAND_SET_TWS_VOLUME (0x0225)
#define GAIA_COMMAND_GET_TWS_VOLUME (0x02A5)
#define GAIA_COMMAND_TRIM_TWS_VOLUME (0x0226)

#define GAIA_COMMAND_GET_API_VERSION (0x0300)
#define GAIA_COMMAND_GET_CURRENT_RSSI (0x0301)
#define GAIA_COMMAND_GET_CURRENT_BATTERY_LEVEL (0x0302)
#define GAIA_COMMAND_GET_MODULE_ID (0x0303)
#define GAIA_COMMAND_GET_APPLICATION_VERSION (0x0304)
#define GAIA_COMMAND_GET_PIO_STATE (0x0306)

#define GAIA_COMMAND_GET_AUTH_BITMAPS (0x0580)
#define GAIA_COMMAND_AUTHENTICATE_REQUEST (0x0501)
#define GAIA_COMMAND_AUTHENTICATE_RESPONSE (0x0502)
#define GAIA_COMMAND_SET_FEATURE (0x0503)
#define GAIA_COMMAND_GET_FEATURE (0x0583)
#define GAIA_COMMAND_SET_SESSION_ENABLE (0x0504)
#define GAIA_COMMAND_GET_SESSION_ENABLE (0x0584)

#define GAIA_COMMAND_GET_STORAGE_PARTITION_STATUS (0x0610)
#define GAIA_COMMAND_OPEN_STORAGE_PARTITION (0x0611)
#define GAIA_COMMAND_WRITE_STORAGE_PARTITION (0x0615)
#define GAIA_COMMAND_CLOSE_STORAGE_PARTITION (0x0618)
#define GAIA_COMMAND_MOUNT_STORAGE_PARTITION (0x061A)
#define GAIA_COMMAND_OPEN_FILE (0x0621)
#define GAIA_COMMAND_READ_FILE (0x0624)
#define GAIA_COMMAND_CLOSE_FILE (0x0628)
#define GAIA_COMMAND_DFU_REQUEST (0x0630)
#define GAIA_COMMAND_DFU_BEGIN (0x0631)
#define GAIA_COMMAND_DFU_COMMIT (0x0633)

#define GAIA_COMMAND_NO_OPERATION (0x0700)
#define GAIA_COMMAND_GET_DEBUG_FLAGS (0x0701)
#define GAIA_COMMAND_SET_DEBUG_FLAGS (0x0702)
#define GAIA_COMMAND_RETRIEVE_PS_KEY (0x0710)
#define GAIA_COMMAND_RETRIEVE_FULL_PS_KEY (0x0711)
#define GAIA_COMMAND_STORE_PS_KEY (0x0712)
#define GAIA_COMMAND_FLOOD_PS (0x0713)
#define GAIA_COMMAND_SEND_DEBUG_MESSAGE (0x0720)
#define GAIA_COMMAND_SEND_APPLICATION_MESSAGE (0x0721)
#define GAIA_COMMAND_SEND_KALIMBA_MESSAGE (0x0722)
#define GAIA_COMMAND_GET_MEMORY_SLOTS (0x0730)
#define GAIA_COMMAND_GET_DEBUG_VARIABLE (0x0740)
#define GAIA_COMMAND_SET_DEBUG_VARIABLE (0x0741)
#define GAIA_COMMAND_DELETE_PDL (0x0750)

#define GAIA_COMMAND_REGISTER_NOTIFICATION (0x4001)
#define GAIA_COMMAND_GET_NOTIFICATION (0x4081)
#define GAIA_COMMAND_CANCEL_NOTIFICATION (0x4002)
#define GAIA_EVENT_NOTIFICATION (0x4003)

#define GAIA_DEBUG_MASK_LOCAL_DEBUG (0x01)
#define GAIA_DEBUG_MASK_REMOTE_DEBUG (0x02)

#define GAIA_EVENT_START (0x00)
#define GAIA_EVENT_RSSI_LOW_THRESHOLD (0x01)
#define GAIA_EVENT_RSSI_HIGH_THRESHOLD (0x02)
#define GAIA_EVENT_BATTERY_LOW_THRESHOLD (0x03)
#define GAIA_EVENT_BATTERY_HIGH_THRESHOLD (0x04)
#define GAIA_EVENT_DEVICE_STATE_CHANGED (0x05)
#define GAIA_EVENT_PIO_CHANGED (0x06)
#define GAIA_EVENT_DEBUG_MESSAGE (0x07)
#define GAIA_EVENT_BATTERY_CHARGED (0x08)
#define GAIA_EVENT_CHARGER_CONNECTION (0x09)
#define GAIA_EVENT_CAPSENSE_UPDATE (0x0A)
#define GAIA_EVENT_USER_ACTION (0x0B)
#define GAIA_EVENT_SPEECH_RECOGNITION (0x0C)
#define GAIA_EVENT_DFU_STATE (0x10)

#define GAIA_ASR_RESPONSE_UNRECOGNISED (0x00)
#define GAIA_ASR_RESPONSE_NO (0x01)
#define GAIA_ASR_RESPONSE_YES (0x02)
#define GAIA_ASR_RESPONSE_WAIT (0x03)
#define GAIA_ASR_RESPONSE_CANCEL (0x04)

#define GAIA_DFU_STATE_DOWNLOAD (0)
#define GAIA_DFU_STATE_DOWNLOAD_FAILURE (1)
#define GAIA_DFU_STATE_VERIFICATION (2)
#define GAIA_DFU_STATE_VERIFICATION_FAILURE (3)
#define GAIA_DFU_STATE_VERIFICATION_SUCCESS (4)

#define GAIA_STATUS_SUCCESS (0x00)
#define GAIA_STATUS_NOT_SUPPORTED (0x01)
#define GAIA_STATUS_NOT_AUTHENTICATED (0x02)
#define GAIA_STATUS_INSUFFICIENT_RESOURCES (0x03)
#define GAIA_STATUS_AUTHENTICATING (0x04)
#define GAIA_STATUS_INVALID_PARAMETER (0x05)
#define GAIA_STATUS_INCORRECT_STATE (0x06)

#define GAIA_PFS_MODE_READ (0x00)
#define GAIA_PFS_MODE_OVERWRITE (0x02)

/*! @brief Enumeration of types of transport which Gaia supports.
 */
typedef enum
{
    gaia_transport_none,                /*!< No transport assigned */
    gaia_transport_spp,                 /*!< Serial Port Profile (SPP) transport */
    gaia_transport_rfcomm,              /*!< RFCOMM using CSR GAIA UUID */
    gaia_transport_mfi                  /*!< Made For iPod (MFi) transport */
} gaia_transport_type;


/*! @brief Definition of MFi transport configuration.
 */
typedef struct
{
    const char *accessory_name;         /*!< Accessory name to appear on the iOS device */
    const char *manufacturer_name;      /*!< Manufacturer name to appear on the iOS device */
    const char *model_name;             /*!< Model name to appear on the iOS device */
    const uint8 *firmware_version;      /*!< Version of firmware used by the accessory. 3 bytes [Major, Minor, Point], i.e 1.2.3 */
    const uint8 *hardware_version;      /*!< Hardware version number of the accessory. 3 bytes [Major, Minor, Point], i.e. 1.2.3 */
    const char *protocol_string;        /*!< Reverse-DNS notation protocol name of data session protocol required by accessory */
    const char *bundle_seed_id;         /*!< Bundle Seed ID of the accessory iOS application */
} gaia_mfi_transport_config;

/*! @brief Enumeration of messages a client task may receive from the Gaia library.
 */
typedef enum
{
    GAIA_INIT_CFM = GAIA_MESSAGE_BASE,  /*!< Confirmation that the library has initialised */  
    GAIA_CONNECT_CFM,                   /*!< Confirmation of an outbound connection request */
    GAIA_CONNECT_IND,                   /*!< Indication of an inbound connection */
    GAIA_DISCONNECT_IND,                /*!< Indication that the connection has closed */
    GAIA_DISCONNECT_CFM,                /*!< Confirmation that a requested disconnection has completed */
    GAIA_START_SERVICE_CFM,             /*!< Confirmation that a Gaia server has started */
    GAIA_DEBUG_MESSAGE_IND,             /*!< Sent as a result of a GAIA_COMMAND_SEND_DEBUG_MESSAGE command */
    GAIA_UNHANDLED_COMMAND_IND,         /*!< Indication that an unhandled command has been received */
    GAIA_SEND_PACKET_CFM,               /*!< Confirmation that a GaiaSendPacket request has completed */
    GAIA_DFU_CFM,                       /*!< Confirmation of a Device Firmware Upgrade request */
	GAIA_DFU_IND,						/*!< Indication that a Device Firmware Upgrade has begun */
    GAIA_MESSAGE_TOP
} GaiaMessageId;


/*! @brief Definition of a GAIA_TRANSPORT handle.
 *
 * Used to identity a specific Gaia connection with a remote device over a specific transport instance.
 */
typedef struct __GAIA_TRANSPORT GAIA_TRANSPORT;


/*! @brief Message confirming status of Gaia library initialisation.
 */
typedef struct
{
    bool success;                       /*!< The success of the initialisation request */
} GAIA_INIT_CFM_T;

/*! @brief Message indicating an incoming connection attempt.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the connected instance */
    bool success;                       /*!< Indication of the success of the connection */
} GAIA_CONNECT_IND_T;

/*! @brief Message indicating a Gaia connection has been disconnected.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the disconnected instance */
} GAIA_DISCONNECT_IND_T;

/*! @brief Message confirming the status of a request by a client task to disconnect a Gaia connection.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the disconnected instance */
} GAIA_DISCONNECT_CFM_T;

/*! @brief Message confirming the status of a connection request initiated by a client task.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the connected instance */
    bool success;                       /*!< The success of the connection request */  
} GAIA_CONNECT_CFM_T;

/*! @brief Message confirming the status of a Start Service request initiated by a client task.
 */
typedef struct
{
    gaia_transport_type transport_type; /*!< Indicates the transport type */
    GAIA_TRANSPORT *transport;          /*!< Indicates the transport instance */
    bool success;                       /*!< The success of the request */  
} GAIA_START_SERVICE_CFM_T;

/*! @brief
 */
typedef struct
{
    uint8 message_length;               /*!< The length of the message */  
    uint8 message[1];                   /*!< The message octets unpacked into uint8s*/  
} GAIA_DEBUG_MESSAGE_T;

/*! @brief Message indicating an incoming Gaia command that cannot be handled by the Gaia library.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the originating instance */
    uint8 protocol_version;             /*!< The protocol version */  
    uint8 size_payload;               /*!< The length of the payload */
    uint16 vendor_id;                   /*!< The 16-bit Vendor ID */  
    uint16 command_id;                  /*!< The 16-bit command ID */
    uint8 payload[1];                   /*!< The payload octets unpacked into uint8s*/  
} GAIA_UNHANDLED_COMMAND_IND_T;

/*! @brief Message confirming the status of a request to transmit a Gaia packet by a client task.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the Gaia instance */
    uint8* packet;                      /*!< Pointer to the packet Gaia was given to transmit */
    bool success;                       /*!< Success/failure of transmission */
} GAIA_SEND_PACKET_CFM_T;

/*! @brief Message confirming the status of a request to perform a Device Firmware Upgrade.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the Gaia instance */
    bool success;                       /*!< Success/failure of request */
} GAIA_DFU_CFM_T;

/*! @brief Message indicating a Device Firmware Upgrade.
 *
 *  This message is sent when the DFU procedure begins.  It may be
 *  sent again if the procedure begins successfully but subsequently
 *  fails.
 */
typedef struct
{
    GAIA_TRANSPORT *transport;          /*!< Indicates the Gaia instance */
    uint8 state;                        /*!< Indicates the status of the Device Firmware Upgrade */
} GAIA_DFU_IND_T;



/*! 
    @brief Request a connection to the Gaia server at the given address

    @param address The Bluetooth device address of the remote Gaia server
*/
void GaiaBtConnectRequest(GAIA_TRANSPORT *transport, bdaddr *address);


/*! 
    @brief Disconnect from host
*/
void GaiaDisconnectRequest(GAIA_TRANSPORT *transport);


/*! 
    @brief Respond to a GAIA_DISCONNECT_IND message
*/
void GaiaDisconnectResponse(GAIA_TRANSPORT *transport);


/*! 
    @brief Return TRUE if the given command is to be passed to application code
    rather than being handled by the library

    @param command_id The Command ID
*/
bool GaiaGetAppWillHandleCommand(uint16 command_id);


/*! 
    @brief Return TRUE if the given notification event is to be raised by
    application code rather than by the library

    @param event_id The Event ID
*/
bool GaiaGetAppWillHandleNotification(uint8 event_id);


/*! 
    @brief Initialise the Gaia protocol handler library
    
    @param task The task that is responsible for handling messages sent from the library.
    @param max_connections The maximum number of concurrent connections to be accommodated.
*/
void GaiaInit(Task task, uint16 max_connections);


/*!
    @brief Build a GAIA_EVENT_NOTIFICATION packet
    
    @param buffer A buffer in which the packet is to be assembled
    The caller is responsible for allocating and freeing this buffer

    @param flags The protocol flags to include in the assembled packet
    
    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param event The Event ID to be included in the packet
    
    @param size_payload The length of the payload to be copied into the packet
    
    @param payload Pointer to the payload to be copied into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
*/
uint16 GaiaBuildNotification(uint16 *buffer, uint8 flags, uint16 vendor_id, uint8 event, uint8 size_payload, uint8 *payload);


/*! 
    @brief Build an arbitrary Gaia packet
    
    @param buffer A buffer in which the packet is to be assembled
    The caller is responsible for allocating and freeing this buffer

    @param flags The protocol flags to include in the assembled packet
    
    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param size_payload The length of the payload to be copied into the packet
    
    @param payload Pointer to the payload to be copied into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
    
*/
uint16 GaiaBuildPacket(uint8 *buffer, uint8 flags, uint16 vendor_id, uint16 command_id, uint8 size_payload, uint8 *payload);


/*! 
    @brief Build an arbitrary Gaia packet from a uint16 array payload
    
    @param buffer A buffer in which the packet is to be assembled
    The caller is responsible for allocating and freeing this buffer

    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param size_payload The length of the payload to be copied into the packet
    
    @param payload Pointer to the payload to be unpacked into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
    
*/
uint16 GaiaBuildPacket16(uint8 *buffer, uint8 flags, uint16 vendor_id, uint16 command_id, uint8 size_payload, uint16 *payload);


/*! 
    @brief Build a a Gaia acknowledgement packet

    @param buffer A buffer in which the packet is to be assembled
    The caller is responsible for allocating and freeing this buffer

    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param status The Status Code to include in the assembled packet
    
    @param size_payload The length of the payload (not including the Status
    Code) to be copied into the packet
    
    @param payload Pointer to the payload to be copied into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
    
*/
uint16 GaiaBuildResponse(uint8 *buffer, uint8 flags, uint16 vendor_id, uint16 command_id, uint8 status, uint8 size_payload, uint8 *payload);


/*! 
    @brief Build a a Gaia acknowledgement packet from a uint16 array payload

    @param buffer A buffer in which the packet is to be assembled
    The caller is responsible for allocating and freeing this buffer

    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param status The Status Code to include in the assembled packet
    
    @param size_payload The length of the payload (not including the Status
    Code) to be copied into the packet
    
    @param payload Pointer to the payload to be unpacked into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
    
*/
uint16 GaiaBuildResponse16(uint8 *buffer, uint8 flags, uint16 vendor_id, uint16 command_id, uint8 status, uint8 size_payload, uint16 *payload);

/*!
    @brief Request that the Gaia library transmit a Gaia command over a given transport.

    @param transport Pointer to a GAIA_TRANSPORT over which to transmit.

    @param packet_length Length of the 'packet' buffer containing the Gaia command to transmit.
    
    @param packet Pointer to a buffer containing the Gaia command to transmit.
*/
void GaiaSendPacket(GAIA_TRANSPORT *transport, uint16 packet_length, uint8 *packet);


/*!
    @brief Changes the API Minor Version reported by GAIA_COMMAND_GET_API_VERSION

    @param version the API Minor Version to be reported, 0 to 15
    
    Changes the API Minor Version reported by GAIA_COMMAND_GET_API_VERSION.
    
    Returns TRUE on success, FALSE if the value is out of range (0..15) or
    the GAIA library is not initialised.
*/
bool GaiaSetApiMinorVersion(uint8 version);


/*! 
    @brief Request that the given command be passed to application code
    rather than being handled by the library.  Returns TRUE on success.

    @param command_id The Command ID
    
    @param value TRUE if the command is to be handled by application code,
    FALSE if the library is to be responsible for performing this command
    
    Certain commands for which a library implementation is provided may instead
    be passed to the application code.  This is useful where an application
    implementation already exists or where the application wishes to perform
    extra processing above and beyond that provided by the library implementation.
    
    Returns TRUE on success.  Some commands must always be handled by the library
    and some are not implemented in the library.  Attempting to change the locus
    of these commands results in a FALSE return value.
*/
bool GaiaSetAppWillHandleCommand(uint16 command_id, bool value);


/*! 
    @brief Request that GAIA_COMMAND_REGISTER_NOTIFICATION commands for the
    given Event ID be passed to application code rather than being handled
    by the library.  Returns TRUE on success.

    @param event_id The Event ID
    
    @param value TRUE if the event is to be handled by application code,
    FALSE if the library is to be responsible for performing this action.
    
    Returns TRUE on success.
*/
bool GaiaSetAppWillHandleNotification(uint8 event_id, bool value);


/*! 
    @brief Starts the Gaia server for the transport type.
    
    @param transport_type The transport type which is to be served.
*/
void GaiaStartService(gaia_transport_type transport_type);


/*!
    @brief Provide the configuration required to use an MFi transport.

    Applications wishing to use Gaia over an MFi transport must call this function
    prior to calling GaiaBtConnectRequest(), such that the configuration can be used
    during connection establishment with iOS devices. GaiaBtConnectRequest() will fail
    if this function has not been called first.

    @param transport Pointer to a GAIA_TRANSPORT returned by successful GAIA_INIT_CFM message.
    @param config Pointer to a gaia_mfi_transport_config structure.
*/
void GaiaMfiTransportConfig(GAIA_TRANSPORT *transport, gaia_mfi_transport_config* config);


/*! 
    @brief Build a Gaia packet in the transport sink and flush it.
    The function completes synchronously and no confirmation message is sent
    to the calling task

    @param transport Pointer to a GAIA_TRANSPORT over which to transmit.
    
    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param status The Status Code to include in the assembled packet
    
    @param size_payload The length of the payload (not including the Status
    Code) to be copied into the packet
    
    @param payload Pointer to the uint8[] payload to be built into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
*/
void GaiaBuildAndSendSynch(GAIA_TRANSPORT *transport, uint16 vendor_id, uint16 command_id, uint8 status, uint8 size_payload, uint8 *payload);


/*! 
    @brief Build a Gaia packet in the transport sink and flush it.
    The function completes synchronously and no confirmation message is sent
    to the calling task

    @param transport Pointer to a GAIA_TRANSPORT over which to transmit.
    
    @param vendor_id The Vendor ID to include in the assembled packet
    
    @param command_id The Command ID to include in the assembled packet
    
    @param status The Status Code to include in the assembled packet
    
    @param size_payload The length of the payload (not including the Status
    Code) to be copied into the packet
    
    @param payload Pointer to the uint16[] payload to be unpacked into the assembled packet.
    If the payload length is zero this argument is not accessed and may be NULL
*/
void GaiaBuildAndSendSynch16(GAIA_TRANSPORT *transport, uint16 vendor_id, uint16 command_id, uint8 status, uint16 size_payload, uint16 *payload);


/*! 
    @brief Returns the control flags for the given transport instance

    @param transport Pointer to a GAIA_TRANSPORT instance.
*/
uint8 GaiaTransportGetFlags(GAIA_TRANSPORT *transport);


/*! 
    @brief Sets the control flags for the given transport instance

    @param transport Pointer to a GAIA_TRANSPORT instance.
    
    @param flags The new value for the transport flags
*/
void GaiaTransportSetFlags(GAIA_TRANSPORT *transport, uint8 flags);


/*! 
    @brief Returns TRUE if GAIA session is enabled for the given transport instance

    @param transport Pointer to a GAIA_TRANSPORT instance.
*/
bool GaiaGetSessionEnable(GAIA_TRANSPORT *transport);


/*! 
    @brief Enables or disables GAIA session for the given transport instance

    @param transport Pointer to a GAIA_TRANSPORT instance.
    
    @param enable TRUE to enable the session, FALSE to disable it
*/
void GaiaSetSessionEnable(GAIA_TRANSPORT *transport, bool enable);


/*! 
    @brief Returns the transport type for the given transport instance

    @param transport Pointer to a GAIA_TRANSPORT instance.
*/
gaia_transport_type GaiaTransportGetType(GAIA_TRANSPORT *transport);


/*!
    @brief Enables and requests Gaia Device Firmware Upgrade.

    @param transport Pointer to a GAIA_TRANSPORT instance.

    @param partition SQIF partition to store the DFU files

    @param period Period in seconds for which DFU will be enabled.
*/
void GaiaDfuRequest(GAIA_TRANSPORT *transport, uint16 partition, uint16 period);

#endif /* ifndef _GAIA_H_ */
