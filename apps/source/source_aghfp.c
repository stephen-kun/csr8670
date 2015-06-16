/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_aghfp.c

DESCRIPTION
    AGHFP profile functionality.
    
*/

/* header for this file */
#include "source_aghfp.h"
/* application header files */
#include "source_aghfp_msg_handler.h"
#include "source_app_msg_handler.h"
#include "source_debug.h"
#include "source_memory.h"
#include "source_private.h"
/* profile/library headers */
#include <aghfp.h>
/* VM headers */
#include <stdlib.h>


#ifdef DEBUG_AGHFP
    #define AGHFP_DEBUG(x) DEBUG(x)

    const char *const aghfp_state_strings[AGHFP_STATES_MAX] = { "Disconnected",
                                                                "Connecting Local",
                                                                "Connecting Remote",
                                                                "Connected",
                                                                "Connecting Audio Local",
                                                                "Connecting Audio Remote",
                                                                "Connected Audio",
                                                                "Disconnecting Audio",
                                                                "Disconnecting"
                                                                };
      
#else
    #define AGHFP_DEBUG(x)
#endif
    

/* Determines if in an audio active state */    
#define aghfp_is_audio(state) ((state >= AGHFP_STATE_CONNECTED_AUDIO) && (state <= AGHFP_STATE_DISCONNECTING_AUDIO))    
/* Display unhandled states in Debug Mode */    
#define aghfp_unhandled_state(inst) AGHFP_DEBUG(("    AGHFP Unhandled State [%d] inst[0x%x]\n", aghfp_get_state(inst), (uint16)inst));    


/* exit state functions */
static void aghfp_exit_state(aghfpInstance *inst);
static void aghfp_exit_state_disconnected(aghfpInstance *inst);
static void aghfp_exit_state_connecting_local(aghfpInstance *inst);
static void aghfp_exit_state_connecting_remote(aghfpInstance *inst);
static void aghfp_exit_state_connected(aghfpInstance *inst);
static void aghfp_exit_state_connecting_audio_local(aghfpInstance *inst);
static void aghfp_exit_state_connecting_audio_remote(aghfpInstance *inst);
static void aghfp_exit_state_connected_audio(aghfpInstance *inst);
static void aghfp_exit_state_disconnecting_audio(aghfpInstance *inst);
static void aghfp_exit_state_disconnecting(aghfpInstance *inst);
/* enter state functions */
static void aghfp_enter_state(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_disconnected(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_connecting_local(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_connecting_remote(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_connected(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_connecting_audio_local(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_connecting_audio_remote(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_disconnecting_audio(aghfpInstance *inst, AGHFP_STATE_T old_state);
static void aghfp_enter_state_disconnecting(aghfpInstance *inst, AGHFP_STATE_T old_state);
/* misc local functions */
static void aghfp_set_remote_volume(AGHFP *aghfp);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    aghfp_init - Initialise AGHFP
*/
void aghfp_init(void)
{    
    /* Init AGHFP library as HFP v1.6 profile. Enhanced call status is Mandatory for AG.
       Codec negotiation required for Wide Band Speech (WBS).
    */
    aghfp_profile profile = aghfp_handsfree_16_profile;
    uint16 features = aghfp_voice_recognition | aghfp_enhanced_call_status | aghfp_codec_negotiation;
    uint16 index;
    
    /* allocate memory for AGHFP instances */
    theSource->aghfp_data.inst = (aghfpInstance *)memory_get_block(MEMORY_GET_BLOCK_PROFILE_AGHFP);
    
    /* initialise each instance */
    for_all_aghfp_instance(index)
    {
        theSource->aghfp_data.inst[index].aghfp_state = AGHFP_STATE_DISCONNECTED;        
        aghfp_init_instance(&theSource->aghfp_data.inst[index]);
    }
    
    /* Register AGHFP library */
    AghfpInit(&theSource->aghfp_data.inst[0].aghfpTask, 
                profile, 
                features);  
}


/****************************************************************************
NAME    
    aghfp_get_instance_from_bdaddr - Returns AGHFP instance from Bluetooth address
*/
aghfpInstance *aghfp_get_instance_from_bdaddr(const bdaddr addr)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst)
    {
        for_all_aghfp_instance(index)
        {
            if (!BdaddrIsZero(&inst->addr) && BdaddrIsSame(&inst->addr, &addr))
                return inst;
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    aghfp_get_instance_from_pointer - Returns AGHFP instance from AGHFP pointer
*/
aghfpInstance *aghfp_get_instance_from_pointer(AGHFP *aghfp)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst)
    {
        for_all_aghfp_instance(index)
        {
            if ((inst->aghfp != 0) && (inst->aghfp == aghfp))
                return inst;
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    aghfp_get_free_instance - Returns AGHFP unused instance
*/
aghfpInstance *aghfp_get_free_instance(void)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst)
    {
        for_all_aghfp_instance(index)
        {
            if (BdaddrIsZero(&inst->addr))
                return inst;
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    aghfp_init_instance - Initialises AGHFP instance
*/
void aghfp_init_instance(aghfpInstance *inst)
{
    uint16 i = 0;
    
    inst->aghfpTask.handler = aghfp_msg_handler;
    MessageFlushTask(&inst->aghfpTask);
    aghfp_set_state(inst, AGHFP_STATE_DISCONNECTED);
    BdaddrSetZero(&inst->addr);
    inst->aghfp = 0;
    inst->link_type = sync_link_unknown;
    inst->slc_sink = 0;
	inst->audio_sink = 0;
    inst->using_wbs = 0;
    inst->cli_enable = 0;
    inst->aghfp_support = AGHFP_SUPPORT_UNKNOWN;
    inst->aghfp_connection_retries = 0;
    inst->connecting_audio = 0;
    inst->disconnecting_audio = 0;
    
    for (i = 0; i < CSR_AG_AUDIO_WARP_NUMBER_VALUES; i++)
    {
        inst->warp[i] = 0;
    }
}


/****************************************************************************
NAME    
    aghfp_start_connection - Starts an AGHFP connection
*/
void aghfp_start_connection(void)
{
    aghfpInstance *inst = NULL;
    
    if (!BdaddrIsZero(&theSource->connection_data.remote_connection_addr))
    {            
        inst = aghfp_get_instance_from_bdaddr(theSource->connection_data.remote_connection_addr);            
    
        if (inst == NULL)
        {
            inst = aghfp_get_free_instance();
            
            if (inst != NULL)
            {
                /* store address of device it's attempting to connect to */
                inst->addr = theSource->connection_data.remote_connection_addr;
                /* store library pointer */
                inst->aghfp = theSource->aghfp_data.aghfp;
                /* don't know if HFP is supported at the moment */
                inst->aghfp_support = AGHFP_SUPPORT_UNKNOWN;
            }
        }
    
        AGHFP_DEBUG(("AGHFP: aghfp_start_connection"));
        DEBUG_BDADDR(theSource->connection_data.remote_connection_addr);
    
        if (inst != NULL)
        {    
            /* there is a free AGHFP instance so initiate signalling connection */
            MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_REQ, 0);
        }
        else
        {
            /* there is no free AGHFP instance so signal to the app that the connection attempt has failed */            
            MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);
        }
    }
}


/****************************************************************************
NAME    
    aghfp_get_number_connections - Returns the number of AGHFP connections
*/
uint16 aghfp_get_number_connections(void)
{
    uint16 connections = 0;
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(aghfp_get_state(inst)))
                connections++;
            inst++;
        }
    }
    
    return connections;
}


/****************************************************************************
NAME    
    aghfp_disconnect_all - Disconnect all AGHFP connections
*/
void aghfp_disconnect_all(void)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(aghfp_get_state(inst)))
            {
                /* disconnect SLC */
                aghfp_set_state(inst, AGHFP_STATE_DISCONNECTING);
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_set_state - Set AGHFP state
*/
void aghfp_set_state(aghfpInstance *inst, AGHFP_STATE_T new_state)
{
    if (new_state < AGHFP_STATES_MAX)
    {
        AGHFP_STATE_T old_state = inst->aghfp_state;
        
        /* leaving current state */        
        aghfp_exit_state(inst);
        
        /* store new state */
        inst->aghfp_state = new_state;
        AGHFP_DEBUG(("AGHFP STATE: new state [%s]\n", aghfp_state_strings[new_state]));
        
        /* entered new state */
        aghfp_enter_state(inst, old_state);
    }
}


/****************************************************************************
NAME    
    aghfp_get_state - Gets AGHFP state
*/
AGHFP_STATE_T aghfp_get_state(aghfpInstance *inst)
{
    return inst->aghfp_state;
}

/****************************************************************************
NAME    
    aghfp_route_all_audio - Routes audio for all AGHFP connections
*/
void aghfp_route_all_audio(void)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            /* cancel pending disconnect audio requests */
            MessageCancelAll(&inst->aghfpTask, AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ);
            
            if (aghfp_is_connected(aghfp_get_state(inst)))
            {
                /* initiate the audio connection */    
                MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_AUDIO_REQ, 0);
            }
            inst++;
        }
    }
    
    /* reset audio delay flag */
    theSource->audio_data.audio_aghfp_connection_delay = FALSE;
}


/****************************************************************************
NAME    
    aghfp_suspend_all_audio - Suspends audio for all AGHFP connections
*/
void aghfp_suspend_all_audio(void)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_audio(aghfp_get_state(inst)))
                MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ, 0);
        }
        inst++;
    }
}


/****************************************************************************
NAME    
    aghfp_is_connecting - Returns if the AGHFP profile is currently connecting.
*/
bool aghfp_is_connecting(void)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    AGHFP_STATE_T state;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            state = aghfp_get_state(inst);
            if ((state == AGHFP_STATE_CONNECTING_LOCAL) || (state == AGHFP_STATE_CONNECTING_REMOTE))
                return TRUE;
            inst++;
        }
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    aghfp_is_audio_active - Returns if the AGHFP profile has audio active.
*/
bool aghfp_is_audio_active(void)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    bool aghfp_audio_present = FALSE;    
    
    if (inst != NULL)
    {
        if (AGHFP_PROFILE_IS_ENABLED)
        {
            for_all_aghfp_instance(index)
            {
                if (aghfp_is_audio(inst->aghfp_state))
                    aghfp_audio_present = TRUE;
                inst++;
            }
        }
    }
    
    return aghfp_audio_present;
}


/****************************************************************************
NAME    
    aghfp_call_ind_none - A call indication has been recieved from the host (no call)
*/
void aghfp_call_ind_none(void)
{
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_none);
    aghfp_host_set_call_setup_state(aghfp_call_setup_none);
    aghfp_host_set_call_held_state(aghfp_call_held_none);
    
}


/****************************************************************************
NAME    
    aghfp_call_ind_incoming - A call indication has been recieved from the host (incoming call)
    
*/
void aghfp_call_ind_incoming(uint16 size_data, const uint8 *data)
{
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_none);
    aghfp_host_set_call_setup_state(aghfp_call_setup_incoming);
    aghfp_host_set_call_held_state(aghfp_call_held_none);
    
    if (size_data >= 3)
    {
        aghfp_host_set_ring_indication(data[0], data[1], &data[2]);
    }
}


/****************************************************************************
NAME    
    aghfp_call_ind_outgoing - A call indication has been recieved from the host (outgoing call)
    
*/
void aghfp_call_ind_outgoing(void)
{
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_none);
    aghfp_host_set_call_setup_state(aghfp_call_setup_outgoing);
    aghfp_host_set_call_held_state(aghfp_call_held_none);
}


/****************************************************************************
NAME    
    aghfp_call_ind_active - A call indication has been recieved from the host (active call)
    
*/
void aghfp_call_ind_active(void)
{
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_active);
    aghfp_host_set_call_setup_state(aghfp_call_setup_none);
    aghfp_host_set_call_held_state(aghfp_call_held_none);
}


/****************************************************************************
NAME    
    aghfp_call_ind_waiting_active_call - A call indication has been recieved from the host (active call with call waiting)
    
*/
void aghfp_call_ind_waiting_active_call(uint16 size_data, const uint8 *data)
{
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_active);
    
    if (size_data >= 3)
    {
        aghfp_host_set_ring_indication(data[0], data[1], &data[2]);
    }
    
    aghfp_host_set_call_setup_state(aghfp_call_setup_incoming);
    aghfp_host_set_call_held_state(aghfp_call_held_none);    
}


/****************************************************************************
NAME    
    aghfp_call_ind_held_active_call - A call indication has been recieved from the host (active call with held call)
    
*/
void aghfp_call_ind_held_active_call(void)
{   
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_active);
    aghfp_host_set_call_setup_state(aghfp_call_setup_none);
    aghfp_host_set_call_held_state(aghfp_call_held_active);
}


/****************************************************************************
NAME    
    aghfp_call_ind_held - A call indication has been recieved from the host (held call)
    
*/
void aghfp_call_ind_held(void)
{
    /* update AG Host state */
    aghfp_host_set_call_state(aghfp_call_active);
    aghfp_host_set_call_setup_state(aghfp_call_setup_none);
    aghfp_host_set_call_held_state(aghfp_call_held_active);
}


/****************************************************************************
NAME    
    aghfp_signal_strength_ind - A signal strength indication has been received from the host
*/
void aghfp_signal_strength_ind(uint8 signal_strength)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                AghfpSendSignalIndicator(theSource->aghfp_data.aghfp, signal_strength);
            }
            inst++;
        }
    }
    
    aghfp_host_set_signal_strength(signal_strength);
}


/****************************************************************************
NAME    
    aghfp_battery_level_ind - A battery level indication has been received from the host

*/
void aghfp_battery_level_ind(uint8 battery_level)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                AghfpSendBattChgIndicator(theSource->aghfp_data.aghfp, battery_level);
            }
            inst++;
        }
    }
    
    aghfp_host_set_battery_level(battery_level);
}


/****************************************************************************
NAME    
    aghfp_audio_transfer_req - Transfers audio HF->AG or AG->HF

*/
void aghfp_audio_transfer_req(void)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            switch (aghfp_get_state(inst))
            {
                case AGHFP_STATE_CONNECTED_AUDIO:
                {
                    aghfp_set_state(inst, AGHFP_STATE_DISCONNECTING_AUDIO);
                }
                break;
                    
                case AGHFP_STATE_CONNECTED:
                {
                    audio_set_voip_music_mode(AUDIO_VOIP_MODE);
                    aghfp_set_state(inst, AGHFP_STATE_CONNECTING_AUDIO_LOCAL);
                }
                break;
                    
                default:
                {
                }
                break;
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_network_operator_ind - A network operator indication has been received from the host
*/
void aghfp_network_operator_ind(uint16 size_data, const uint8 *data)
{
    if (size_data >= 1)
    {
        aghfp_host_set_network_operator(data[0], &data[1]);
    }
    
}


/****************************************************************************
NAME    
    aghfp_network_availability_ind = A network availability indication has been received from the host
*/
void aghfp_network_availability_ind(bool available)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    aghfp_service_availability availability = available ? aghfp_service_present : aghfp_service_none;
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                AghfpSendServiceIndicator(theSource->aghfp_data.aghfp, availability);
            }
            inst++;
        }
    }
    
    aghfp_host_set_network_availability(availability);
}
  

/****************************************************************************
NAME    
    aghfp_network_roam_ind - A network roam indication has been received from the host
*/
void aghfp_network_roam_ind(bool roam)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    aghfp_roam_status roaming = roam ? aghfp_roam_active : aghfp_roam_none;
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                AghfpSendRoamIndicator(theSource->aghfp_data.aghfp, roaming);
            }
            inst++;
        }
    }
    
    aghfp_host_set_roam_status(roaming);
}


/****************************************************************************
NAME    
    aghfp_error_ind - An error indication has been received from the host
*/
void aghfp_error_ind(void)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                /* send ERROR to remote side */
                AghfpSendError(theSource->aghfp_data.aghfp);
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_ok_ind - An ok indication has been received from the host
*/
void aghfp_ok_ind(void)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                /* send OK to remote side */
                AghfpSendOk(theSource->aghfp_data.aghfp);
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_current_call_ind - A current call indication has been received from the host
*/
void aghfp_current_call_ind(uint16 size_data, const uint8 *data)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    aghfp_call_info call;
    
    call.type = 0;
    call.size_number = 0;
    call.number = 0;
    
    if (size_data >= 5)
    {
        call.idx = (uint8)data[0];
	    call.dir = data[1];
	    call.status = data[2];
	    call.mode = data[3];
	    call.mpty = data[4];
    
        if (size_data >=7)
        {    
	        call.type = data[5];
	        call.size_number = data[6];
            if (call.size_number)
            {
                call.number = memory_create(call.size_number);
                for (index = 0; index < call.size_number; index++)
                {
                    call.number[index] = data[index + 7];
                }
            }
        }
        
        if (inst != NULL)
        {
            for_all_aghfp_instance(index)
            {
                if (aghfp_is_connected(inst->aghfp_state))
                {
                    /* send OK to remote side */
                    AghfpSendCurrentCall(theSource->aghfp_data.aghfp, &call);
                }
                inst++;
            }
        }
    }
}


/****************************************************************************
NAME    
    aghfp_voice_recognition_ind - A voice recognition indication has been received from the host
*/
void aghfp_voice_recognition_ind(bool enable)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                /* send voice recognition to remote side */
                AghfpVoiceRecognitionEnable(theSource->aghfp_data.aghfp, enable);
            }
            inst++;
        }
    }
    
    if (enable)
    {
        /* switch to VOIP mode and enable audio connection */
        aghfp_voip_mode_answer_call();
    }
    
    /* send state to USB host */
    usb_send_device_command_voice_recognition(enable);
}


/****************************************************************************
NAME    
    aghfp_music_mode_end_call - Music mode should be entered and the current call ended by sending USB HID command to host
    
*/
void aghfp_music_mode_end_call(void)
{
    /* send USB HID command for HangUp */
    usb_send_hid_hangup();
    
    /* try a switch to MUSIC mode */
    audio_switch_voip_music_mode(AUDIO_MUSIC_MODE);
}


/****************************************************************************
NAME    
    aghfp_voip_mode_answer_call - VOIP mode should be entered and the current call answered by sending USB HID command to host
    
*/
void aghfp_voip_mode_answer_call(void)
{
    /* send USB HID command for Answer */
    usb_send_hid_answer();
    
    /* try a switch to VOIP mode */
    audio_switch_voip_music_mode(AUDIO_VOIP_MODE);
}


/****************************************************************************
NAME    
    aghfp_send_source_volume - Send locally stored volumes over AGHFP
*/
void aghfp_send_source_volume(aghfpInstance *inst)
{
    uint16 index = 0;
    
    if (inst)
    {
        aghfp_set_remote_volume(inst->aghfp);        
    }
    else
    {    
        inst = theSource->aghfp_data.inst;
        
        if (inst)
        {  
            for_all_aghfp_instance(index)
            {
                if ((inst->aghfp != 0))
                {
                    if (aghfp_is_connected(inst->aghfp_state))
                    {
                        aghfp_set_remote_volume(inst->aghfp);
                    }
                }
                inst++;
            }
        }
    }
}


/****************************************************************************
NAME    
    aghfp_speaker_volume_ind - Receives speaker volume from the remote device 
*/
void aghfp_speaker_volume_ind(uint8 volume)
{
    usb_device_class_audio_levels levels;
    
    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
    {
        /* get the current USB audio levels */ 
        UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_LEVELS, (uint16*)&levels);

        /* send USB HID command to the Host to update volume */
        if (levels.out_mute)
        {
            /* the volume was muted so unmute on receiving a volume command */
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_MUTE);
        }
        else if (theSource->volume_data.speaker_vol > volume)
        {
            /* the new volume is less than the current volume - can only send a volume decrement event to the host */
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_DOWN);
        } 
        else if (theSource->volume_data.speaker_vol < volume)
        {
            /* the new volume is more than the current volume - can only send a volume increment event to the host */
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_UP);
        } 
    }            
}


/****************************************************************************
NAME    
    aghfp_mic_gain_ind - Receives microphone gain from the remote device 
*/
void aghfp_mic_gain_ind(uint8 gain)
{
    
}


/****************************************************************************
NAME    
    aghfp_send_voice_recognition - Sends Voice Recognition command to the remote device
*/
void aghfp_send_voice_recognition(bool enable)
{
    uint16 index;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(aghfp_get_state(inst)))
            {
                /* initiate the audio connection */   
                MAKE_MESSAGE(AGHFP_INTERNAL_VOICE_RECOGNITION); 
                message->enable = enable;
                MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_VOICE_RECOGNITION, message);
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_host_set_call_state - Sets the call state of the AG Host
*/
void aghfp_host_set_call_state(aghfp_call_status status)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    aghfp_call_status old_call_state = theSource->aghfp_data.aghost_state.call_status;
    
    theSource->aghfp_data.aghost_state.call_status = status;
    AGHFP_DEBUG(("AGHFP: Host call state [%d]\n", status));
    
    if (inst != NULL && (theSource->aghfp_data.aghost_state.call_status != old_call_state))
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {                       
                MessageCancelFirst(&inst->aghfpTask, AGHFP_INTERNAL_RING_ALERT);
                AghfpSendCallIndicator(theSource->aghfp_data.aghfp, theSource->aghfp_data.aghost_state.call_status);
            }
            inst++;
        }
    }
    aghfp_host_clear_ring_indication();
}


/****************************************************************************
NAME    
    aghfp_host_set_call_setup_state - Sets the call setup state of the AG Host
*/
void aghfp_host_set_call_setup_state(aghfp_call_setup_status status)

{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    aghfp_call_setup_status old_setup_state = theSource->aghfp_data.aghost_state.call_setup_status;
    
    theSource->aghfp_data.aghost_state.call_setup_status = status;
    AGHFP_DEBUG(("AGHFP: Host call setup state [%d]\n", status));
    
    if (inst != NULL && (theSource->aghfp_data.aghost_state.call_setup_status != old_setup_state))
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {                       
                if (theSource->aghfp_data.aghost_state.call_setup_status == aghfp_call_setup_incoming)
                {                                        
                    if (theSource->aghfp_data.aghost_state.call_status == aghfp_call_active)
                    {
                        if (theSource->aghfp_data.aghost_state.ring)
                        {
                            AghfpSendCallWaitingNotification(theSource->aghfp_data.aghfp,
                                                             theSource->aghfp_data.aghost_state.ring->clip_type, 
                                                             theSource->aghfp_data.aghost_state.ring->size_clip_number, 
                                                             theSource->aghfp_data.aghost_state.ring->clip_number, 
                                                             0, 
                                                             NULL);
                        }
                        else
                        {
                            AghfpSendCallWaitingNotification(theSource->aghfp_data.aghfp,
                                                             0, 
                                                             0, 
                                                             0, 
                                                             0, 
                                                             NULL);
                        }
                    }
                    else
                    {
                        MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_RING_ALERT, 0); 
                    }
                }
                
                AghfpSendCallSetupIndicator(theSource->aghfp_data.aghfp, theSource->aghfp_data.aghost_state.call_setup_status);
            }
            inst++;
        }
    }    
}


/****************************************************************************
NAME    
    aghfp_host_set_call_held_state - Sets the call held state of the AG Host
*/
void aghfp_host_set_call_held_state(aghfp_call_held_status status)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;
    aghfp_call_held_status old_held_state = theSource->aghfp_data.aghost_state.call_held_status;
    
    theSource->aghfp_data.aghost_state.call_held_status = status;
    AGHFP_DEBUG(("AGHFP: Host call held state [%d]\n", status));
    
    if (inst != NULL && (theSource->aghfp_data.aghost_state.call_held_status != old_held_state))
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {                       
                AghfpSendCallHeldIndicator(theSource->aghfp_data.aghfp, theSource->aghfp_data.aghost_state.call_held_status);
            }
            inst++;
        }
    }        
}


/****************************************************************************
NAME    
    aghfp_host_set_signal_strength - Sets the signal strength of the AG Host
*/
void aghfp_host_set_signal_strength(uint8 signal_strength)
{
    theSource->aghfp_data.aghost_state.signal = signal_strength;
    AGHFP_DEBUG(("AGHFP: Host signal strength [%d]\n", signal_strength));
}


/****************************************************************************
NAME    
    aghfp_host_set_battery_level - Sets the battery level of the AG Host
*/
void aghfp_host_set_battery_level(uint8 battery_level)
{
    theSource->aghfp_data.aghost_state.batt = battery_level;
    AGHFP_DEBUG(("AGHFP: Host battery level [%d]\n", battery_level));
}


/****************************************************************************
NAME    
    aghfp_host_set_roam_status - Sets the roam status of the AG Host
*/
void aghfp_host_set_roam_status(aghfp_roam_status roam_status)
{
    theSource->aghfp_data.aghost_state.roam_status = roam_status;
    AGHFP_DEBUG(("AGHFP: Host roam status [%d]\n", roam_status));
}


/****************************************************************************
NAME    
    aghfp_host_set_network_availability - Sets the network availability of the AG Host
*/
void aghfp_host_set_network_availability(aghfp_service_availability availability)
{
    theSource->aghfp_data.aghost_state.availability = availability;
    AGHFP_DEBUG(("AGHFP: Host network availability [%d]\n", availability));
}


/****************************************************************************
NAME    
    aghfp_host_set_network_operator - Sets the network operator name of the AG Host
*/
void aghfp_host_set_network_operator(uint16 size_name, const uint8 *name)
{
    uint16 index;
    
    if (size_name > AGHOST_MAX_NETWORK_OPERATOR_CHARACTERS)
    {
        size_name = AGHOST_MAX_NETWORK_OPERATOR_CHARACTERS;
    }
    
    for (index = 0; index < size_name; index++)
    {
        theSource->aghfp_data.aghost_state.network_operator[index] = name[index];
    }
    theSource->aghfp_data.aghost_state.size_network_operator = size_name;
    
#ifdef DEBUG_AGHFP    
    AGHFP_DEBUG(("AGHFP: Host network operator size [%d] name [", size_name));
    for (index = 0; index < size_name; index++)
    {
        AGHFP_DEBUG(("%c",theSource->aghfp_data.aghost_state.network_operator[index]));
    }
    AGHFP_DEBUG(("]\n"));
#endif
    
}


/****************************************************************************
NAME    
    aghfp_host_set_ring_indication - Stores the data associated with a RING indication
*/
void aghfp_host_set_ring_indication(uint8 clip_type, uint8 size_clip_number, const uint8 *clip_number)
{
    uint16 index = 0;
    
    aghfp_host_clear_ring_indication();
   
    theSource->aghfp_data.aghost_state.ring = memory_create(sizeof(AGHFP_RING_ALERT_T) + size_clip_number);       
    
    theSource->aghfp_data.aghost_state.ring->clip_type = clip_type;
    theSource->aghfp_data.aghost_state.ring->size_clip_number = size_clip_number;
    
    AGHFP_DEBUG(("AGHFP: Ring Indication Set type[%d] size_no[%d]\n", clip_type, size_clip_number));
    
    for (index = 0; index < size_clip_number; index++)
    {
        theSource->aghfp_data.aghost_state.ring->clip_number[index] = clip_number[index];
    }
}


/****************************************************************************
NAME    
    aghfp_host_clear_ring_indication - Frees the data associated with a RING indication
*/
void aghfp_host_clear_ring_indication(void)
{
    if (theSource->aghfp_data.aghost_state.ring)
    {
        free(theSource->aghfp_data.aghost_state.ring);
        theSource->aghfp_data.aghost_state.ring = 0;
        
        AGHFP_DEBUG(("AGHFP: Ring Indication Cleared\n"));
    }
}


/****************************************************************************
NAME    
    aghfp_store_warp_values - Stores the warp values for the current AGHFP audio connection    
*/
void aghfp_store_warp_values(uint16 number_warp_values, uint16 *warp)
{
    uint16 index = 0;
    uint16 i = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;    
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                /* send message to update attributes in PS */
                MAKE_MESSAGE(APP_STORE_DEVICE_ATTRIBUTES);
                message->addr = inst->addr;
                for (i = 0; i < number_warp_values; i++)
                {
                    message->attributes.warp[i] = warp[i];
                    /* store the values locally */
                    inst->warp[i] = warp[i];
                }
                MessageSend(&theSource->app_data.appTask, APP_STORE_DEVICE_ATTRIBUTES, message);
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_send_audio_params - Sends the audio params to the AGHFP library for the current AGHFP audio connections
*/
void aghfp_send_audio_params(void)
{
    uint16 index = 0;
    aghfpInstance *inst = theSource->aghfp_data.inst;    
        
    if (inst != NULL)
    {
        for_all_aghfp_instance(index)
        {
            if (aghfp_is_connected(inst->aghfp_state))
            {
                /* remote side has initiated audio connection by sending AT+BCC */
                aghfp_set_state(inst, AGHFP_STATE_CONNECTING_AUDIO_REMOTE);
                AghfpSetAudioParams(inst->aghfp, theSource->ps_config->hfp_audio.sync_pkt_types, &theSource->ps_config->hfp_audio.audio_params);
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    aghfp_exit_state - Exits an AGHFP state
*/
static void aghfp_exit_state(aghfpInstance *inst)
{
    switch (aghfp_get_state(inst))
    {     
        case AGHFP_STATE_DISCONNECTED:
        {
            aghfp_exit_state_disconnected(inst);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_LOCAL:
        {
            aghfp_exit_state_connecting_local(inst);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_REMOTE:
        {
            aghfp_exit_state_connecting_remote(inst);
        }
        break;
        
        case AGHFP_STATE_CONNECTED:
        {
            aghfp_exit_state_connected(inst);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        {
            aghfp_exit_state_connecting_audio_local(inst);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        {
            aghfp_exit_state_connecting_audio_remote(inst);
        }
        break;
        
        case AGHFP_STATE_CONNECTED_AUDIO:
        {
            aghfp_exit_state_connected_audio(inst);
        }
        break;
        
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        {
            aghfp_exit_state_disconnecting_audio(inst);
        }
        break;
        
        case AGHFP_STATE_DISCONNECTING:
        {
            aghfp_exit_state_disconnecting(inst);
        }
        break;
        
        default:
        {
            aghfp_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    aghfp_exit_state_disconnected - Called on exiting the AGHFP_STATE_DISCONNECTED state
*/
static void aghfp_exit_state_disconnected(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_connecting_local - Called on exiting the AGHFP_STATE_CONNECTING_LOCAL state
*/
static void aghfp_exit_state_connecting_local(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_connecting_remote - Called on exiting the AGHFP_STATE_CONNECTING_REMOTE state
*/
static void aghfp_exit_state_connecting_remote(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_connected - Called on exiting the AGHFP_STATE_CONNECTED state
*/
static void aghfp_exit_state_connected(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_connecting_audio_local - Called on exiting the AGHFP_STATE_CONNECTING_AUDIO_LOCAL state
*/
static void aghfp_exit_state_connecting_audio_local(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_connecting_audio_remote - Called on exiting the AGHFP_STATE_CONNECTING_AUDIO_REMOTE state
*/
static void aghfp_exit_state_connecting_audio_remote(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_connected_audio - Called on exiting the AGHFP_STATE_CONNECTED_AUDIO state
*/
static void aghfp_exit_state_connected_audio(aghfpInstance *inst)
{
    /* disconnect any AGHFP audio */
    audio_aghfp_disconnect();
}


/****************************************************************************
NAME    
    aghfp_exit_state_disconnecting_audio - Called on exiting the AGHFP_STATE_DISCONNECTING_AUDIO state
*/
static void aghfp_exit_state_disconnecting_audio(aghfpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    aghfp_exit_state_disconnecting - Called on exiting the AGHFP_STATE_DISCONNECTING state
*/
static void aghfp_exit_state_disconnecting(aghfpInstance *inst)
{
    
}
        

/****************************************************************************
NAME    
    aghfp_enter_state - Enters an AGHFP state
*/
static void aghfp_enter_state(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    switch (aghfp_get_state(inst))
    {
        case AGHFP_STATE_DISCONNECTED:
        {
            aghfp_enter_state_disconnected(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_LOCAL:
        {
            aghfp_enter_state_connecting_local(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_REMOTE:
        {
            aghfp_enter_state_connecting_remote(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_CONNECTED:
        {
            aghfp_enter_state_connected(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_AUDIO_LOCAL:
        {
            aghfp_enter_state_connecting_audio_local(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_CONNECTING_AUDIO_REMOTE:
        {
            aghfp_enter_state_connecting_audio_remote(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_CONNECTED_AUDIO:
        {
            aghfp_enter_state_connected_audio(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_DISCONNECTING_AUDIO:
        {
            aghfp_enter_state_disconnecting_audio(inst, old_state);
        }
        break;
        
        case AGHFP_STATE_DISCONNECTING:
        {
            aghfp_enter_state_disconnecting(inst, old_state);
        }
        break;
        
        default:
        {
            aghfp_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    aghfp_enter_state_disconnected - Called on entering the AGHFP_STATE_DISCONNECTED state
*/
static void aghfp_enter_state_disconnected(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    if (aghfp_is_connected(old_state))
    {
        uint16 i = 0;
        /* update attributes on a disconnection */
        MAKE_MESSAGE(APP_STORE_DEVICE_ATTRIBUTES);
        message->addr = inst->addr;
        for (i = 0; i < CSR_AG_AUDIO_WARP_NUMBER_VALUES; i++)
        {
            message->attributes.warp[i] = inst->warp[i];
        }
        MessageSend(&theSource->app_data.appTask, APP_STORE_DEVICE_ATTRIBUTES, message);
        
        /* send message that has disconnection has occurred */    
        MessageSend(&theSource->app_data.appTask, APP_DISCONNECT_IND, 0); 
        /* cancel any audio connect requests */
        MessageCancelAll(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_AUDIO_REQ);
        /* reset audio delay flag */
        theSource->audio_data.audio_aghfp_connection_delay = FALSE;
        
        /* attempt to switch audio mode and end any active call */
        aghfp_music_mode_end_call();
    }
}


/****************************************************************************
NAME    
    aghfp_enter_state_connecting_local - Called on entering the AGHFP_STATE_CONNECTING_LOCAL state
*/
static void aghfp_enter_state_connecting_local(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    AghfpSlcConnect(inst->aghfp, &inst->addr);
}


/****************************************************************************
NAME    
    aghfp_enter_state_connecting_remote - Called on entering the AGHFP_STATE_CONNECTING_REMOTE state
*/
static void aghfp_enter_state_connecting_remote(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    
}


/****************************************************************************
NAME    
    aghfp_enter_state_connected - Called on entering the AGHFP_STATE_CONNECTED state
*/
static void aghfp_enter_state_connected(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    if ((old_state == AGHFP_STATE_CONNECTING_LOCAL) || (old_state == AGHFP_STATE_CONNECTING_REMOTE))
    {                              
        ATTRIBUTES_T attributes;
        
        /* store current device to PS */   
        ps_write_new_remote_device(&inst->addr, PROFILE_AGHFP);
        
        /* clear forced inquiry mode flag as is now connected to a device */
        theSource->inquiry_mode.force_inquiry_mode = FALSE;
        
        /* set WBS codec to be SBC which is mandatory for HFP v1.6 spec */
        AghfpSetCodecType(inst->aghfp, aghfp_wbs_codec_sbc);

        /* send message that has connection has occurred */    
        MessageSend(&theSource->app_data.appTask, APP_CONNECT_SUCCESS_CFM, 0); 
        
        /* register connection with connection manager */
        connection_mgr_set_profile_connected(PROFILE_AGHFP, &inst->addr);
        
        /* Retrieve the role of this device */
        ConnectionGetRole(&theSource->connectionTask, inst->slc_sink);
        
        /* Retrieve the device attributes */
        if (ConnectionSmGetAttributeNow(PS_KEY_USER_PAIRED_ATTR_BASE, &inst->addr, sizeof(ATTRIBUTES_T), (uint8*)&attributes))
        {
            uint16 i = 0;
            /* Store locally the attributes that were read */
            for (i = 0; i < CSR_AG_AUDIO_WARP_NUMBER_VALUES; i++)
            {
                inst->warp[i] = attributes.warp[i];
            }
        }
        else
        {
            /* Clear values as they couldn't be read from PS */
            inst->warp[0] = 0;
            inst->warp[1] = 0;
            inst->warp[2] = 0;
            inst->warp[3] = 0;
        }

        /* reset connection attempts */
        inst->aghfp_connection_retries = 0;
        
        /* send audio volumes over AGHFP */
        aghfp_send_source_volume(inst);
        
        /* for remote connections need to record that locally initiated audio connection 
            should be delayed incase remote end wants to initiate audio */
        if (old_state == AGHFP_STATE_CONNECTING_REMOTE)
        {
            theSource->audio_data.audio_aghfp_connection_delay = TRUE;
        }
        
        /* send RING alert on connection if there is an incoming call */
        if (theSource->aghfp_data.aghost_state.call_setup_status == aghfp_call_setup_incoming)
        {
            MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_RING_ALERT, 0);
        }
    }
    else if ((old_state == AGHFP_STATE_CONNECTING_AUDIO_LOCAL) || 
             ((old_state == AGHFP_STATE_CONNECTING_AUDIO_REMOTE) && (usb_get_hid_mode() != USB_HID_MODE_HOST))) /* Qual test TC_AG_ACS_BI_14_I doesn't want dongle to reconnect eSCO after a rejection */
    {
        /* try audio connection again after the PS delay */
        if (inst->aghfp_connection_retries < theSource->ps_config->features.aghfp_max_connection_retries)
        {
            inst->aghfp_connection_retries++;
            
            MessageSendLater(&inst->aghfpTask, AGHFP_INTERNAL_CONNECT_AUDIO_REQ, 0, theSource->ps_config->ps_timers.audio_delay_timer);  
        }
        else
        {
            /* send message to disconnect as audio connection can't be made */    
            MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_DISCONNECT_REQ, 0);
        }
    }
    else if ((old_state == AGHFP_STATE_DISCONNECTING_AUDIO) || (old_state == AGHFP_STATE_CONNECTED_AUDIO))
    {
        /* try a resume of A2DP audio after AGHFP audio has been removed */
        a2dp_resume_audio();
    }
    
    /* no audio connecting / disconnecting at this point */
    inst->connecting_audio = 0;
    inst->disconnecting_audio = 0;   
}


/****************************************************************************
NAME    
    aghfp_enter_state_connecting_audio_local - Called on entering the AGHFP_STATE_CONNECTING_AUDIO_LOCAL state
*/
static void aghfp_enter_state_connecting_audio_local(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    inst->connecting_audio = 1;
    
    AghfpAudioConnect(inst->aghfp, theSource->ps_config->hfp_audio.sync_pkt_types, &theSource->ps_config->hfp_audio.audio_params);
}


/****************************************************************************
NAME    
    aghfp_enter_state_connecting_audio_remote - Called on entering the AGHFP_STATE_CONNECTING_AUDIO_REMOTE state
*/
static void aghfp_enter_state_connecting_audio_remote(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    inst->connecting_audio = 1;
}


/****************************************************************************
NAME    
    aghfp_enter_state_disconnecting_audio - Called on entering the AGHFP_STATE_DISCONNECTING_AUDIO state
*/
static void aghfp_enter_state_disconnecting_audio(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    inst->disconnecting_audio = 1;
    
    AghfpAudioDisconnect(inst->aghfp);
}


/****************************************************************************
NAME    
    aghfp_enter_state_disconnecting - Called on entering the AGHFP_STATE_DISCONNECTING state
*/
static void aghfp_enter_state_disconnecting(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    AghfpSlcDisconnect(inst->aghfp);
}


/****************************************************************************
NAME    
    aghfp_set_remote_volume - Sets the remote volume
*/
static void aghfp_set_remote_volume(AGHFP *aghfp)
{
    AghfpSetRemoteSpeakerVolume(aghfp, theSource->volume_data.speaker_vol);
    AghfpSetRemoteMicrophoneGain(aghfp, theSource->volume_data.mic_vol);
}


/****************************************************************************
NAME    
    aghfp_enter_state_connected_audio

*/
void aghfp_enter_state_connected_audio(aghfpInstance *inst, AGHFP_STATE_T old_state)
{
    if (inst->audio_sink)
    {
        /* Disconnect all A2DP audio if it is routed */
        audio_a2dp_disconnect_all();
        
        if ((old_state == AGHFP_STATE_CONNECTING_AUDIO_REMOTE) && (theSource->audio_data.audio_voip_music_mode == AUDIO_MUSIC_MODE))
        {
            /* switch to VOIP mode from MUSIC mode as the remote side has initiated the audio */
            audio_set_voip_music_mode(AUDIO_VOIP_MODE);
        }
        
        if (theSource->audio_data.audio_voip_music_mode == AUDIO_VOIP_MODE)
        {                    
            if (states_get_state() == SOURCE_STATE_CONNECTED)
            {
                /* suspend A2DP stream */
                a2dp_suspend_all_audio();
                
                /* connect new audio */
                audio_aghfp_connect(inst->audio_sink, (inst->link_type == sync_link_esco) ? TRUE : FALSE, inst->using_wbs, CSR_AG_AUDIO_WARP_NUMBER_VALUES, inst->warp);
            
                /* set sniff mode if PS Key has been read */
                if (theSource->ps_config->sniff.number_aghfp_entries && theSource->ps_config->sniff.aghfp_powertable)
                {
                    ConnectionSetLinkPolicy(inst->audio_sink, theSource->ps_config->sniff.number_aghfp_entries ,theSource->ps_config->sniff.aghfp_powertable);
                }
            }
            else
            {
                /* if not connected then remove audio */
                MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ, 0);
            }        
        }
        else
        {
            /* VOIP mode not active so suspend AGHFP audio */
            MessageSend(&inst->aghfpTask, AGHFP_INTERNAL_DISCONNECT_AUDIO_REQ, 0);
        }
    }
    
    /* reset connection attempts */
    inst->aghfp_connection_retries = 0;
    
    /* no longer connecting audio */
    inst->connecting_audio = 0;
}
