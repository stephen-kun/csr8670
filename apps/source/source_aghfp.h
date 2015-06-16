/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_aghfp.h

DESCRIPTION
    AGHFP profile functionality.
    
*/


#ifndef _SOURCE_AGHFP_H_
#define _SOURCE_AGHFP_H_


/* application header files */
#include "source_aghfp_msg_handler.h"
/* profile/library headers */
#include <aghfp.h>
#include <connection.h>
#include <csr_ag_audio_plugin.h>
/* VM headers */
#include <message.h>


/* AGHFP fixed values */
#define AGHFP_MAX_INSTANCES         1


/* loop through all HFP connection instances */
#define for_all_aghfp_instance(index) index = 0;/*for (index = 0; index < AGHFP_MAX_INSTANCES; index++)*/

/* check to see if HFP profile has been enabled */
#define AGHFP_PROFILE_IS_ENABLED (theSource->connection_data.supported_profiles & PROFILE_AGHFP)

/* Time between RING alerts */
#define AGHFP_RING_ALERT_DELAY  5000

/* AGHFP State Machine */
typedef enum
{  
    AGHFP_STATE_DISCONNECTED,
    AGHFP_STATE_CONNECTING_LOCAL,
    AGHFP_STATE_CONNECTING_REMOTE,
    AGHFP_STATE_CONNECTED,
    AGHFP_STATE_CONNECTING_AUDIO_LOCAL,
    AGHFP_STATE_CONNECTING_AUDIO_REMOTE,
    AGHFP_STATE_CONNECTED_AUDIO,
    AGHFP_STATE_DISCONNECTING_AUDIO,
    AGHFP_STATE_DISCONNECTING
} AGHFP_STATE_T;

#define AGHFP_STATES_MAX  (AGHFP_STATE_DISCONNECTING + 1)


/* Check of AGHFP connection state */
#define aghfp_is_connected(state) ((state >= AGHFP_STATE_CONNECTED) && (state < AGHFP_STATES_MAX))


/* Number of characters to store Network Operator Name */
#define AGHOST_MAX_NETWORK_OPERATOR_CHARACTERS 6


/* AGHFP supported values */
typedef enum
{
    AGHFP_SUPPORT_UNKNOWN,
    AGHFP_SUPPORT_YES
} AGHFP_SUPPORT_T;


typedef struct
{
    uint8 clip_type;
    uint8 size_clip_number;
    uint8 clip_number[1];
} AGHFP_RING_ALERT_T;

typedef struct
{
    aghfp_service_availability availability;
    aghfp_call_status call_status;
    aghfp_call_setup_status call_setup_status;
    aghfp_call_held_status call_held_status;
    uint16 signal;
    aghfp_roam_status roam_status;
    uint16 batt;
    uint8 network_operator[AGHOST_MAX_NETWORK_OPERATOR_CHARACTERS];
    uint16 size_network_operator;
    AGHFP_RING_ALERT_T *ring;
} AGHOST_T;

/* structure holding the AGHFP data */
typedef struct
{
    TaskData aghfpTask;
    AGHFP_STATE_T aghfp_state;    
    bdaddr addr;
    AGHFP *aghfp;
    sync_link_type link_type;
    Sink slc_sink;
	Sink audio_sink;
    unsigned using_wbs:1;
    unsigned cli_enable:1;
    unsigned unused:14;
    AGHFP_SUPPORT_T aghfp_support;
    uint16 aghfp_connection_retries;
    uint16 connecting_audio;
    uint16 disconnecting_audio;
    uint16 warp[CSR_AG_AUDIO_WARP_NUMBER_VALUES];
} aghfpInstance;

/* structure holding the AGHFP data */
typedef struct
{
    aghfpInstance *inst;  
    AGHFP *aghfp;
    AGHOST_T aghost_state;
} AGHFP_DATA_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    aghfp_init

DESCRIPTION
    Initialises the AGHFP profile libary and prepares the application so it can handle AGHFP connections.
    The application will allocate a memory block to hold connection related information.
    Each AGHFP connection with a remote device will be stored within the memory block as an AGHFP instance. 

*/
void aghfp_init(void);


/****************************************************************************
NAME    
    aghfp_get_instance_from_bdaddr

DESCRIPTION
    Finds and returns the AGHFP instance with address set to the addr passed to the function.
    
RETURNS
    If an AGHFP instance has address set as addr then that aghfpInstance will be returned.
    Otherwise NULL.

*/
aghfpInstance *aghfp_get_instance_from_bdaddr(const bdaddr addr);


/****************************************************************************
NAME    
    aghfp_get_instance_from_pointer

DESCRIPTION
    Finds and returns the AGHFP instance with AGHFP pointer set to the aghfp address passed to the function.
    
RETURNS
    If an AGHFP instance has the AGHFP pointer set as aghfp then that aghfpInstance will be returned.
    Otherwise NULL.

*/
aghfpInstance *aghfp_get_instance_from_pointer(AGHFP *aghfp);


/****************************************************************************
NAME    
    aghfp_get_free_instance

DESCRIPTION
    Finds and returns the a free AGHFP instance which has no current ongoing connection.
    
RETURNS
    If an AGHFP instance has no ongoing connection then that aghfpInstance will be returned.
    Otherwise NULL.

*/
aghfpInstance *aghfp_get_free_instance(void);



/****************************************************************************
NAME    
    aghfp_init_instance

DESCRIPTION
    Sets an AGHFP instance to a default state of having no ongoing connection.

*/
void aghfp_init_instance(aghfpInstance *inst);


/****************************************************************************
NAME    
    aghfp_start_connection

DESCRIPTION
    Initiates an AGHFP connection to the remote device with address stored in theSource->connection_data.remote_connection_addr. 

*/
void aghfp_start_connection(void);


/****************************************************************************
NAME    
    aghfp_get_number_connections

DESCRIPTION
    Returns the number of currently active AGHFP connections.
    
RETURNS
    The number of currently active AGHFP connections.

*/
uint16 aghfp_get_number_connections(void);


/****************************************************************************
NAME    
    aghfp_disconnect_all

DESCRIPTION
    Disconnects all active AGHFP connections.

*/
void aghfp_disconnect_all(void);


/****************************************************************************
NAME    
    aghfp_set_state

DESCRIPTION
    Sets the new state of an AGHFP connection.

*/
void aghfp_set_state(aghfpInstance *inst, AGHFP_STATE_T new_state);


/****************************************************************************
NAME    
    aghfp_get_state

DESCRIPTION
    Gets the current state of an AGHFP connection.

*/
AGHFP_STATE_T aghfp_get_state(aghfpInstance *inst);


/****************************************************************************
NAME    
    aghfp_route_all_audio

DESCRIPTION
    Routes audio for all AGHFP connections.

*/
void aghfp_route_all_audio(void);


/****************************************************************************
NAME    
    aghfp_suspend_all_audio

DESCRIPTION
    Suspends audio for all AGHFP connections.

*/
void aghfp_suspend_all_audio(void);


/****************************************************************************
NAME    
    aghfp_is_connecting

DESCRIPTION
    Returns if the AGHFP profile is currently connecting.

RETURNS
    TRUE - AGHFP profile is currently connecting
    FALSE - AGHFP profile is not connecting
    
*/
bool aghfp_is_connecting(void);


/****************************************************************************
NAME    
    aghfp_is_audio_active

DESCRIPTION
    Returns if the AGHFP profile has audio active.

RETURNS
    TRUE - AGHFP profile has audio active
    FALSE - AGHFP profile does not have audio active
    
*/
bool aghfp_is_audio_active(void);


/****************************************************************************
NAME    
    aghfp_call_ind_none

DESCRIPTION
    A call indication has been recieved from the host - no call.
    
*/
void aghfp_call_ind_none(void);


/****************************************************************************
NAME    
    aghfp_call_ind_incoming

DESCRIPTION
    A call indication has been recieved from the host - incoming call.
    
*/
void aghfp_call_ind_incoming(uint16 size_data, const uint8 *data);


/****************************************************************************
NAME    
    aghfp_call_ind_outgoing

DESCRIPTION
    A call indication has been recieved from the host - outgoing call.
    
*/
void aghfp_call_ind_outgoing(void);


/****************************************************************************
NAME    
    aghfp_call_ind_active

DESCRIPTION
    A call indication has been recieved from the host - active call.
    
*/
void aghfp_call_ind_active(void);


/****************************************************************************
NAME    
    aghfp_call_ind_waiting_active_call

DESCRIPTION
    A call indication has been recieved from the host - active call with call waiting.
    
*/
void aghfp_call_ind_waiting_active_call(uint16 size_data, const uint8 *data);


/****************************************************************************
NAME    
    aghfp_call_ind_held_active_call

DESCRIPTION    
    A call indication has been recieved from the host (active call with held call).
    
*/
void aghfp_call_ind_held_active_call(void);


/****************************************************************************
NAME    
    aghfp_call_ind_held

DESCRIPTION    
    A call indication has been recieved from the host (held call).
    
*/
void aghfp_call_ind_held(void);


/****************************************************************************
NAME    
    aghfp_signal_strength_ind

DESCRIPTION
    A signal strength indication has been received from the host.

*/
void aghfp_signal_strength_ind(uint8 signal_strength);


/****************************************************************************
NAME    
    aghfp_battery_level_ind

DESCRIPTION
    A battery level indication has been received from the host.

*/
void aghfp_battery_level_ind(uint8 battery_level);


/****************************************************************************
NAME    
    aghfp_audio_transfer_req

DESCRIPTION
    Transfers audio HF->AG or AG->HF

*/
void aghfp_audio_transfer_req(void);


/****************************************************************************
NAME    
    aghfp_network_operator_ind

DESCRIPTION
    A network operator indication has been received from the host.

*/
void aghfp_network_operator_ind(uint16 size_data, const uint8 *data);


/****************************************************************************
NAME    
    aghfp_network_availability_ind

DESCRIPTION
    A network availability indication has been received from the host.

*/
void aghfp_network_availability_ind(bool available);
  

/****************************************************************************
NAME    
    aghfp_network_roam_ind

DESCRIPTION
    A network roam indication has been received from the host.

*/
void aghfp_network_roam_ind(bool roam);       


/****************************************************************************
NAME    
    aghfp_error_ind

DESCRIPTION
    An error indication has been received from the host.

*/
void aghfp_error_ind(void);


/****************************************************************************
NAME    
    aghfp_ok_ind

DESCRIPTION
    An ok indication has been received from the host.

*/
void aghfp_ok_ind(void);


/****************************************************************************
NAME    
    aghfp_current_call_ind

DESCRIPTION
    A current call indication has been received from the host.
    
*/
void aghfp_current_call_ind(uint16 size_data, const uint8 *data);


/****************************************************************************
NAME    
    aghfp_voice_recognition_ind

DESCRIPTION
    A voice recognition indication has been received from the host.
    
*/
void aghfp_voice_recognition_ind(bool enable);


/****************************************************************************
NAME    
    aghfp_music_mode_end_call
    
DESCRIPTION
    Music mode should be entered and the current call ended by sending USB HID command to host.
    
*/
void aghfp_music_mode_end_call(void);


/****************************************************************************
NAME    
    aghfp_voip_mode_answer_call
    
DESCRIPTION
    VOIP mode should be entered and the current call answered by sending USB HID command to host.
    
*/
void aghfp_voip_mode_answer_call(void);


/****************************************************************************
NAME    
    aghfp_send_source_volume

DESCRIPTION
    Send locally stored volumes over AGHFP.
    
*/
void aghfp_send_source_volume(aghfpInstance *inst);


/****************************************************************************
NAME    
    aghfp_speaker_volume_ind

DESCRIPTION
    Receives speaker volume from the remote device.
    
*/
void aghfp_speaker_volume_ind(uint8 volume);


/****************************************************************************
NAME    
    aghfp_mic_gain_ind

DESCRIPTION
    Receives microphone gain from the remote device.
    
*/
void aghfp_mic_gain_ind(uint8 gain);


/****************************************************************************
NAME    
    aghfp_send_voice_recognition

DESCRIPTION
    Sends Voice Recognition command to the remote device
    
*/
void aghfp_send_voice_recognition(bool enable);


/****************************************************************************
NAME    
    aghfp_host_set_call_state

DESCRIPTION
    Sets the call state of the AG Host.

*/
void aghfp_host_set_call_state(aghfp_call_status status);


/****************************************************************************
NAME    
    aghfp_host_set_call_setup_state

DESCRIPTION
    Sets the call setup state of the AG Host.

*/
void aghfp_host_set_call_setup_state(aghfp_call_setup_status status);


/****************************************************************************
NAME    
    aghfp_host_set_call_held_state

DESCRIPTION
    Sets the call held state of the AG Host.

*/
void aghfp_host_set_call_held_state(aghfp_call_held_status status);



/****************************************************************************
NAME    
    aghfp_host_set_signal_strength

DESCRIPTION
    Sets the signal strength of the AG Host.

*/
void aghfp_host_set_signal_strength(uint8 signal_strength);


/****************************************************************************
NAME    
    aghfp_host_set_battery_level

DESCRIPTION
    Sets the battery level of the AG Host.

*/
void aghfp_host_set_battery_level(uint8 battery_level);


/****************************************************************************
NAME    
    aghfp_host_set_roam_status

DESCRIPTION
    Sets the roam status of the AG Host.

*/
void aghfp_host_set_roam_status(aghfp_roam_status roam_status);


/****************************************************************************
NAME    
    aghfp_host_set_network_availability

DESCRIPTION
    Sets the network availability of the AG Host.

*/
void aghfp_host_set_network_availability(aghfp_service_availability availability);


/****************************************************************************
NAME    
    aghfp_host_set_network_operator

DESCRIPTION
    Sets the network operator name of the AG Host.

*/
void aghfp_host_set_network_operator(uint16 size_name, const uint8 *name);


/****************************************************************************
NAME    
    aghfp_host_set_ring_indication

DESCRIPTION
    Stores the data associated with a RING indication.

*/
void aghfp_host_set_ring_indication(uint8 clip_type, uint8 size_clip_number, const uint8 *clip_number);


/****************************************************************************
NAME    
    aghfp_host_clear_ring_indication

DESCRIPTION
    Frees the data associated with a RING indication.
    
*/
void aghfp_host_clear_ring_indication(void);


/****************************************************************************
NAME    
    aghfp_store_warp_values

DESCRIPTION
    Stores the warp values for the current AGHFP audio connection.
    
*/
void aghfp_store_warp_values(uint16 number_warp_values, uint16 *warp);


/****************************************************************************
NAME    
    aghfp_send_audio_params

DESCRIPTION
    Sends the audio params to the AGHFP library for the current AGHFP audio connections.
    
*/
void aghfp_send_audio_params(void);


/****************************************************************************
NAME    
    aghfp_enter_state_connected_audio
    
DESCRIPTION
    Called on entering the AGHFP_STATE_CONNECTED_AUDIO state.
    
*/
void aghfp_enter_state_connected_audio(aghfpInstance *inst, AGHFP_STATE_T old_state);


#endif /* _SOURCE_AGHFP_H_ */
