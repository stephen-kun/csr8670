/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_a2dp.h

DESCRIPTION
    A2DP profile functionality.
    
*/

#ifndef _SOURCE_A2DP_H_
#define _SOURCE_A2DP_H_


/* profile/library headers */
#include <a2dp.h>
#include <csr_a2dp_encoder_common_plugin.h>
/* VM headers */
#include <bdaddr.h>
#include <message.h>


#define A2DP_INVALID_ID                 0xffff
#define A2DP_SEID_SBC                   1
#define A2DP_SEID_FASTSTREAM            2
#define A2DP_SEID_APTX                  3
#define A2DP_SEID_APTX_LOW_LATENCY      4
#define A2DP_KALIMBA_RESOURCE_ID        1
#define A2DP_LINKLOSS_RECONNECTION_TIME 0
#define A2DP_MAX_START_RETRIES          2
#define A2DP_MAX_SDP_RECS               50
#define A2DP_SERVICE_TRANSPORT_INDEX    0
#define A2DP_SERVICE_CODEC_INDEX        2
#define A2DP_MEDIA_CODEC_INDEX          5

/* CSR codec defines */
#define A2DP_CSR_VENDOR_ID0           0x0A
#define A2DP_CSR_VENDOR_ID1           0x00
#define A2DP_CSR_VENDOR_ID2           0x00
#define A2DP_CSR_VENDOR_ID3           0x00

/* SBC configuration bit fields */
#define A2DP_SBC_SAMPLING_FREQ_16000        128   /* Octet 0 */
#define A2DP_SBC_SAMPLING_FREQ_32000         64
#define A2DP_SBC_SAMPLING_FREQ_44100         32
#define A2DP_SBC_SAMPLING_FREQ_48000         16
#define A2DP_SBC_CHANNEL_MODE_MONO            8
#define A2DP_SBC_CHANNEL_MODE_DUAL_CHAN       4
#define A2DP_SBC_CHANNEL_MODE_STEREO          2
#define A2DP_SBC_CHANNEL_MODE_JOINT_STEREO    1
#define A2DP_SBC_BLOCK_LENGTH_4             128   /* Octet 1 */
#define A2DP_SBC_BLOCK_LENGTH_8              64
#define A2DP_SBC_BLOCK_LENGTH_12             32
#define A2DP_SBC_BLOCK_LENGTH_16             16
#define A2DP_SBC_SUBBANDS_4                   8
#define A2DP_SBC_SUBBANDS_8                   4
#define A2DP_SBC_ALLOCATION_SNR               2
#define A2DP_SBC_ALLOCATION_LOUDNESS          1
#define A2DP_SBC_BITPOOL_MIN                  2   /* Octet 2 (min bitpool)  /  Octet 3 (max bitpool) */
#define A2DP_SBC_BITPOOL_MAX                 53
#define A2DP_SBC_BITPOOL_LOW_QUALITY         20
#define A2DP_SBC_BITPOOL_MEDIUM_QUALITY      32
#define A2DP_SBC_BITPOOL_GOOD_QUALITY        40
#define A2DP_SBC_BITPOOL_HIGH_QUALITY        53
#define A2DP_SBC_SAMPLING_CHANNEL_INDEX       6
#define A2DP_SBC_MIN_BITPOOL_INDEX            8
#define A2DP_SBC_MAX_BITPOOL_INDEX            9

/* Faststream configuration bit fields */
#define A2DP_FASTSTREAM_CODEC_ID0            0x01
#define A2DP_FASTSTREAM_CODEC_ID1            0x00
#define A2DP_FASTSTREAM_MUSIC                0x01
#define A2DP_FASTSTREAM_VOICE                0x02
#define A2DP_FASTSTREAM_MUSIC_SAMP_48000     0x01
#define A2DP_FASTSTREAM_MUSIC_SAMP_44100     0x02
#define A2DP_FASTSTREAM_VOICE_SAMP_16000     0x20
#define A2DP_FASTSTREAM_DIRECTION_INDEX        12
#define A2DP_FASTSTREAM_SAMPLING_INDEX         13

/* Apt-x configuration bit fields */
#define A2DP_APTX_SAMPLING_FREQ_44100         32   /*aptX only supports 44.1Khz and 48Khz*/
#define A2DP_APTX_SAMPLING_FREQ_48000         16
#define A2DP_APTX_CHANNEL_MODE_STEREO          2
#define A2DP_APTX_VENDOR_ID0                0x4F   /* APT codec ID 79 */
#define A2DP_APTX_VENDOR_ID1                 0x0
#define A2DP_APTX_VENDOR_ID2                 0x0
#define A2DP_APTX_VENDOR_ID3                 0x0
#define A2DP_APTX_CODEC_ID0                  0x1
#define A2DP_APTX_CODEC_ID1                  0x0
#define A2DP_APTX_LOWLATENCY_CODEC_ID0       0x2
#define A2DP_APTX_LOWLATENCY_CODEC_ID1       0x0
#define A2DP_APTX_LOWLATENCY_VOICE_16000     0x1
#define A2DP_APTX_LOWLATENCY_NEW_CAPS        0x2
#define A2DP_APTX_LOWLATENCY_RESERVED        0x0
#define A2DP_APTX_LOWLATENCY_TCL_LSB        0xB4  /* Target codec level = 180 (0x0b4) */
#define A2DP_APTX_LOWLATENCY_TCL_MSB        0x00
#define A2DP_APTX_LOWLATENCY_ICL_LSB        0x7C  /* Initial codec level = 380 (0x17C) */
#define A2DP_APTX_LOWLATENCY_ICL_MSB        0x01
#define A2DP_APTX_LOWLATENCY_MAX_RATE       0x32  /* 50 (/10000) = 0.005 SRA rate */
#define A2DP_APTX_LOWLATENCY_AVG_TIME       0x01  /* SRA Averaging time = 1s */
#define A2DP_APTX_LOWLATENCY_GWBL_LSB       0xB4  /* Good working buffer level = 180 (0x0b4) */
#define A2DP_APTX_LOWLATENCY_GWBL_MSB       0x00
#define A2DP_APTX_SAMPLING_RATE_INDEX       12
#define A2DP_APTX_DIRECTION_INDEX           13


#ifdef INCLUDE_DUALSTREAM
#define A2DP_DUALSTREAM_ENABLED         (theSource->ps_config->dualstream.dual_stream_enable)
#define A2DP_DUALSTREAM_CONNECT_NEXT    (theSource->ps_config->dualstream.dual_stream_connect_both_devices)
#define A2DP_MAX_INSTANCES              2
#else
#define A2DP_DUALSTREAM_ENABLED         0
#define A2DP_DUALSTREAM_CONNECT_NEXT    0
#define A2DP_MAX_INSTANCES              1
#endif /* INCLUDE_DUALSTREAM */


#define A2DP_MAX_ENDPOINTS              4
#define A2DP_ENABLED_INSTANCES          (A2DP_DUALSTREAM_ENABLED ? 2 : 1)
#define A2DP_MEDIA_CLOSE_TIMEOUT        2000
#define A2DP_LOW_LATENCY_FLUSH_TIMEOUT  14

/* loop through all A2DP connection instances */
#define for_all_a2dp_instance(index) for (index = 0; index < A2DP_ENABLED_INSTANCES; index++)

/* check to see if A2DP profile has been enabled */
#define A2DP_PROFILE_IS_ENABLED (theSource->connection_data.supported_profiles & PROFILE_A2DP)

/* check codec from SEID */
#define a2dp_seid_is_sbc(seid)          (seid == A2DP_SEID_SBC)
#define a2dp_seid_is_faststream(seid)   (seid == A2DP_SEID_FASTSTREAM)
#define a2dp_seid_is_aptx(seid)         (seid == A2DP_SEID_APTX)


/* A2DP State Machine */
typedef enum
{  
    A2DP_STATE_DISCONNECTED,                                    /* No A2DP connection */
    A2DP_STATE_CONNECTING_LOCAL,                                /* Locally initiated connection in progress */
    A2DP_STATE_CONNECTING_REMOTE,                               /* Remotely initiated connection is progress */
    A2DP_STATE_CONNECTED_SIGNALLING,                            /* Signalling channel connected */
    A2DP_STATE_CONNECTING_MEDIA_LOCAL,                          /* Locally initiated media channel connection in progress */
    A2DP_STATE_CONNECTING_MEDIA_REMOTE,                         /* Remote initiated media channel connection in progress */
    A2DP_STATE_CONNECTED_MEDIA,                                 /* Media channel connected */
    A2DP_STATE_CONNECTED_MEDIA_STREAMING,                       /* Media channel streaming */
    A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL,                /* Locally initiated media channel suspend in progress */
    A2DP_STATE_CONNECTED_MEDIA_SUSPENDED,                       /* Media channel suspended */
    A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL,                  /* Locally initiated media channel start in progress */                                
    A2DP_STATE_DISCONNECTING_MEDIA,                             /* Locally initiated media channel disconnection in progress */
    A2DP_STATE_DISCONNECTING                                    /* Disconnecting signalling and media channels */
} A2DP_STATE_T;

#define A2DP_STATES_MAX  (A2DP_STATE_DISCONNECTING + 1)


/* Check of A2DP connection state */
#define a2dp_is_connected(state) ((state >= A2DP_STATE_CONNECTED_SIGNALLING) && (state < A2DP_STATES_MAX))
#define a2dp_is_media(state) ((state >= A2DP_STATE_CONNECTED_MEDIA) && (state < A2DP_STATE_DISCONNECTING_MEDIA))
#define a2dp_is_streaming(state) (state == A2DP_STATE_CONNECTED_MEDIA_STREAMING)


/* A2DP supported values */
typedef enum
{
    A2DP_SUPPORT_UNKNOWN,
    A2DP_SUPPORT_YES
} A2DP_SUPPORT_T;

/* Maximum supported audio quality for the media stream */
typedef enum
{
    A2DP_AUDIO_QUALITY_LOW,
    A2DP_AUDIO_QUALITY_MEDIUM,
    A2DP_AUDIO_QUALITY_GOOD,
    A2DP_AUDIO_QUALITY_HIGH,
    A2DP_AUDIO_QUALITY_UNKNOWN
} A2DP_AUDIO_QUALITY_T;


/* structure holding the A2DP Instance variables and state */
typedef struct
{
    TaskData a2dpTask;
    A2DP_STATE_T a2dp_state;
    bdaddr addr;
    uint16 a2dp_device_id;
    uint16 a2dp_stream_id;  
    Sink media_sink;
    A2DP_SUPPORT_T a2dp_support;
    uint16 a2dp_connection_retries;
    unsigned a2dp_reconfiguring:1;
    unsigned a2dp_reconfigure_codec:3;
    unsigned a2dp_role:3;
    unsigned unused:9;
    uint16 a2dp_suspending;
    A2DP_AUDIO_QUALITY_T a2dp_quality;
} a2dpInstance;

/* structure holding the A2DP data */
typedef struct
{
    a2dpInstance *inst; 
    uint8 *codec_config;
    sep_config_type sbc_caps;
    uint8 *sbc_codec_config;
    sep_config_type faststream_caps;
    uint8 *faststream_codec_config;
    sep_config_type aptx_caps;
    uint8 *aptx_codec_config;
    sep_config_type aptxLowLatency_caps;
    uint8 *aptxLowLatency_codec_config;
} A2DP_DATA_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    a2dp_init

DESCRIPTION
    Initialises the A2DP profile libary and prepares the application so it can handle A2DP connections.
    The application will allocate a memory block to hold connection related information.
    Each A2DP connection with a remote device will be stored within the memory block as an A2DP instance. 

*/
void a2dp_init(void);


/****************************************************************************
NAME    
    a2dp_set_state

DESCRIPTION
    Sets the new state of an A2DP connection.

*/
void a2dp_set_state(a2dpInstance *inst, A2DP_STATE_T new_state);


/****************************************************************************
NAME    
    a2dp_get_state

DESCRIPTION
    Gets the current state of an A2DP connection.

*/
A2DP_STATE_T a2dp_get_state(a2dpInstance *inst);


/****************************************************************************
NAME    
    a2dp_start_connection

DESCRIPTION
    Initiates an A2DP connection to the remote device with address stored in the Source.connection_data.remote_connection_addr. 

*/
void a2dp_start_connection(void);


/****************************************************************************
NAME    
    a2dp_get_instance_from_device_id

DESCRIPTION
    Finds and returns the A2DP instance with device ID set to the device_id passed to the function.
    
RETURNS
    If an A2DP instance has device ID set as device_id then that a2dpInstance will be returned.
    Otherwise NULL.

*/
a2dpInstance *a2dp_get_instance_from_device_id(uint16 device_id);


/****************************************************************************
NAME    
    a2dp_get_instance_from_bdaddr

DESCRIPTION
    Finds and returns the A2DP instance with address set to the addr passed to the function.
    
RETURNS
    If an A2DP instance has address set as addr then that a2dpInstance will be returned.
    Otherwise NULL.

*/
a2dpInstance *a2dp_get_instance_from_bdaddr(const bdaddr addr);


/****************************************************************************
NAME    
    a2dp_get_free_instance

DESCRIPTION
    Finds and returns the a free A2DP instance which has no current ongoing connection.
    
RETURNS
    If an A2DP instance has no ongoing connection then that a2dpInstance will be returned.
    Otherwise NULL.

*/
a2dpInstance *a2dp_get_free_instance(void);


/****************************************************************************
NAME    
    a2dp_init_instance

DESCRIPTION
    Sets an A2DP instance to a default state of having no ongoing connection.

*/
void a2dp_init_instance(a2dpInstance *inst);


/****************************************************************************
NAME    
    a2dp_get_number_connections

DESCRIPTION
    Returns the number of currently active A2DP connections.
    
RETURNS
    The number of currently active A2DP connections.

*/
uint16 a2dp_get_number_connections(void);


/****************************************************************************
NAME    
    a2dp_disconnect_all

DESCRIPTION
    Disconnects all active A2DP connections.

*/
void a2dp_disconnect_all(void);


/****************************************************************************
NAME    
    a2dp_set_sbc_config

DESCRIPTION
    Sets the SBC Stream-End Point configuration.
    If use_defaults is TRUE then the Stream-End Point will be set to the default configuration.
    If use_defaults is FALSE then the Stream-End Point will be set to the user defined configuration.

*/
void a2dp_set_sbc_config(bool use_defaults);


/****************************************************************************
NAME    
    a2dp_set_faststream_config

DESCRIPTION
    Sets the Faststream Stream-End Point configuration.
    If use_defaults is TRUE then the Stream-End Point will be set to the default configuration.
    If use_defaults is FALSE then the Stream-End Point will be set to the user defined configuration.

*/
void a2dp_set_faststream_config(bool use_defaults);


/****************************************************************************
NAME    
    a2dp_set_aptx_config

DESCRIPTION
    Sets the APT-X Stream-End Point configuration.
    If use_defaults is TRUE then the Stream-End Point will be set to the default configuration.
    If use_defaults is FALSE then the Stream-End Point will be set to the user defined configuration.

*/
void a2dp_set_aptx_config(bool use_defaults);


/****************************************************************************
NAME    
    a2dp_set_aptxLowLatency_config

DESCRIPTION
    Sets the APT-X Low Latency Stream-End Point configuration.
    If use_defaults is TRUE then the Stream-End Point will be set to the default configuration.
    If use_defaults is FALSE then the Stream-End Point will be set to the user defined configuration.
    
*/
void a2dp_set_aptxLowLatency_config(bool use_defaults);


/****************************************************************************
NAME    
    a2dp_get_sbc_caps_size

DESCRIPTION
    Gets the size of the SBC Stream-End Point configuration parameters.

*/
uint16 a2dp_get_sbc_caps_size(void);


/****************************************************************************
NAME    
    a2dp_get_faststream_caps_size

DESCRIPTION
    Gets the size of the Faststream Stream-End Point configuration parameters.

*/
uint16 a2dp_get_faststream_caps_size(void);


/****************************************************************************
NAME    
    a2dp_get_aptx_caps_size

DESCRIPTION
    Gets the size of the APT-X Stream-End Point configuration parameters.

*/
uint16 a2dp_get_aptx_caps_size(void);


/****************************************************************************
NAME    
    a2dp_get_aptxLowLatency_caps_size

DESCRIPTION
    Gets the size of the APT-X Low Latency Stream-End Point configuration parameters.

*/
uint16 a2dp_get_aptxLowLatency_caps_size(void);


/****************************************************************************
NAME    
    a2dp_sdp_search_cfm

DESCRIPTION
    Called when an A2DP Service Search has completed. This will determine if A2DP is supported by the remote device.

*/
void a2dp_sdp_search_cfm(a2dpInstance *inst, const CL_SDP_SERVICE_SEARCH_CFM_T *message);


/****************************************************************************
NAME    
    a2dp_remote_features_cfm

DESCRIPTION
    Called when the remote device features have been read.

*/
void a2dp_remote_features_cfm(a2dpInstance *inst, const CL_DM_REMOTE_FEATURES_CFM_T *message);


/****************************************************************************
NAME    
    a2dp_resume_audio

DESCRIPTION
    This is called to Resume the A2DP audio, normally when an (e)SCO audio connection has been removed.

*/
void a2dp_resume_audio(void);


/****************************************************************************
NAME    
    a2dp_route_all_audio

DESCRIPTION
    Routes audio for all A2DP connections.

*/
void a2dp_route_all_audio(void);


/****************************************************************************
NAME    
    a2dp_suspend_all_audio

DESCRIPTION
    Suspends audio for all A2DP connections.

*/
void a2dp_suspend_all_audio(void);


/****************************************************************************
NAME    
    a2dp_configure_sbc

DESCRIPTION
    Configures the SBC codec during the Media Open procedure.

RETURNS
    TRUE if the SBC codec has been configured.
    FALSE if the SBC codec could not be configured.
*/
bool a2dp_configure_sbc(A2DP_CODEC_CONFIGURE_IND_T *message);


/****************************************************************************
NAME    
    a2dp_configure_faststream

DESCRIPTION
    Configures the FastStream codec during the Media Open procedure.

RETURNS
    TRUE if the FastStream codec has been configured.
    FALSE if the FastStream codec could not be configured.
*/
bool a2dp_configure_faststream(A2DP_CODEC_CONFIGURE_IND_T *message);


/****************************************************************************
NAME    
    a2dp_configure_aptx

DESCRIPTION
    Configures the APT-X codec during the Media Open procedure.

RETURNS
    TRUE if the APT-X codec has been configured.
    FALSE if the APT-X codec could not be configured.
*/
bool a2dp_configure_aptx(A2DP_CODEC_CONFIGURE_IND_T *message);


/****************************************************************************
NAME    
    a2dp_configure_aptxLowLatency

DESCRIPTION
    Configures the APT-X Low Latency codec during the Media Open procedure.

RETURNS
    TRUE if the APT-X Low Latency codec has been configured.
    FALSE if the APT-X Low Latency codec could not be configured.
*/
bool a2dp_configure_aptxLowLatency(A2DP_CODEC_CONFIGURE_IND_T *message);


/****************************************************************************
NAME    
    a2dp_get_sbc_bitpool

DESCRIPTION
    Gets the SBC bitpool that should be used for the audio stream.

RETURNS
    The bitpool value to use.
*/
bool a2dp_get_sbc_bitpool(uint8 *bitpool, uint8 *bad_link_bitpool, bool *multiple_streams);


/****************************************************************************
NAME    
    a2dp_update_sbc_bitpool

DESCRIPTION
    Update the SBC bitpool that should be used for the audio stream.

*/
void a2dp_update_sbc_bitpool(void);


/****************************************************************************
NAME    
    a2dp_store_role

DESCRIPTION
    Stores the role for the link (Master/Slave).

*/
void a2dp_store_role(bdaddr addr, hci_role role);


/****************************************************************************
NAME    
    a2dp_is_connecting

DESCRIPTION
    Returns if the A2DP profile is currently connecting.

RETURNS
    TRUE - A2DP profile is currently connecting
    FALSE - A2DP profile is not connecting
    
*/
bool a2dp_is_connecting(void);


/****************************************************************************
NAME    
    a2dp_allow_more_connections

DESCRIPTION
    Returns if more A2DP connections are allowed. More connections will be allowed if DualStream is enabled
    but only one A2DP connection is active.

RETURNS
    TRUE - More A2DP connections are allowed
    FALSE - More A2DP connections are not allowed
    
*/
bool a2dp_allow_more_connections(void);


/****************************************************************************
NAME    
    a2dp_disconnect_media

DESCRIPTION
    This function closes all open A2DP media connections and returns if A2DP media needs to be closed.

RETURNS
    TRUE - A2DP media needs to be disconnected
    FALSE - A2DP media does not need to be disconnected
    
*/
bool a2dp_disconnect_media(void);


/****************************************************************************
NAME    
    a2dp_any_media_connections

DESCRIPTION
    This function returns if any media connections are still active.

RETURNS
    TRUE - A2DP media still connected
    FALSE - A2DP media not connected
    
*/
bool a2dp_any_media_connections(void);


/****************************************************************************
NAME    
    a2dp_get_connected_addr

DESCRIPTION
    This function returns the addresses of any connected A2DP devices.

RETURNS
    TRUE - An A2DP device is connected and at least addr_a will be set
    FALSE - No A2DP device is connected
    
*/
bool a2dp_get_connected_addr(bdaddr *addr_a, bdaddr *addr_b);


/****************************************************************************
NAME    
    a2dp_enter_state_connected_media_streaming

DESCRIPTION
    Called on entering the A2DP_STATE_CONNECTED_MEDIA_STREAMING state.
    
*/
void a2dp_enter_state_connected_media_streaming(a2dpInstance *inst, A2DP_STATE_T old_state);


#endif /* _SOURCE_A2DP_H_ */

