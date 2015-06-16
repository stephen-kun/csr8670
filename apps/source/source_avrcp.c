/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_avrcp.c

DESCRIPTION
    AVRCP profile functionality.
    
*/


/* header for this file */
#include "source_avrcp.h"
/* application header files */
#include "source_app_msg_handler.h"
#include "source_avrcp_msg_handler.h"
#include "source_debug.h"
#include "source_memory.h"
#include "source_private.h"
#include "source_usb.h"
/* profile/library headers */
#include <avrcp.h>
/* VM headers */
#include <stdlib.h>


#ifdef DEBUG_AVRCP
    #define AVRCP_DEBUG(x) DEBUG(x)

    const char *const avrcp_state_strings[AVRCP_STATES_MAX] = { "Disconnected",
                                                                "Connecting Local",
                                                                "Connecting Remote",
                                                                "Connected",
                                                                "Disconnecting"};
#else
    #define AVRCP_DEBUG(x)
#endif
    

/* Display unhandled states in Debug Mode */    
#define avrcp_unhandled_state(inst) AVRCP_DEBUG(("    AVRCP Unhandled State [%d] inst[0x%x]\n", avrcp_get_state(inst), (uint16)inst));    
        

/* AVRCP service search pattern */    
static const uint8 avrcp_service_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0E};


/* exit state functions*/
static void avrcp_exit_state(avrcpInstance *inst);
static void avrcp_enter_state(avrcpInstance *inst);    
static void avrcp_exit_state_disconnected(avrcpInstance *inst);
static void avrcp_exit_state_connecting_local(avrcpInstance *inst);
static void avrcp_exit_state_connecting_remote(avrcpInstance *inst);
static void avrcp_exit_state_connected(avrcpInstance *inst);
static void avrcp_exit_state_disconnecting(avrcpInstance *inst);
/* enter state functions */
static void avrcp_enter_state_disconnected(avrcpInstance *inst);
static void avrcp_enter_state_connecting_local(avrcpInstance *inst);
static void avrcp_enter_state_connecting_remote(avrcpInstance *inst);
static void avrcp_enter_state_connected(avrcpInstance *inst);
static void avrcp_enter_state_disconnecting(avrcpInstance *inst);


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    avrcp_init - Initialise AVRCP
*/  
void avrcp_init(void)
{
    avrcp_init_params params;
    uint16 index;
    
    /* allocate memory for A2DP instances */
    theSource->avrcp_data.inst = (avrcpInstance *)memory_get_block(MEMORY_GET_BLOCK_PROFILE_AVRCP);
    
    /* initialise each instance */
    for_all_avrcp_instance(index)
    {
        theSource->avrcp_data.inst[index].avrcp_state = AVRCP_STATE_DISCONNECTED;
        theSource->avrcp_data.inst[index].vendor_data = NULL;
        avrcp_init_instance(&theSource->avrcp_data.inst[index]);
    }
    
    /* initialise the AVRCP profile library */
    params.device_type = avrcp_target; /* TG device only */
    params.supported_controller_features = 0; /* not a CT so no features */
    params.supported_target_features = AVRCP_CATEGORY_1; /* category 1 for TG media control */   
    params.profile_extensions = 0; /* no extensions */
    
    AvrcpInit(&theSource->avrcp_data.inst[0].avrcpTask, &params);
}


/****************************************************************************
NAME    
    avrcp_set_state - Set AVRCP state
*/
void avrcp_set_state(avrcpInstance *inst, AVRCP_STATE_T new_state)
{
    if (new_state < AVRCP_STATES_MAX)
    {
        /* leaving current state */        
        avrcp_exit_state(inst);
        
        /* store new state */
        inst->avrcp_state = new_state;
        AVRCP_DEBUG(("AVRCP STATE: new state [%s]\n", avrcp_state_strings[new_state]));
        
        /* entered new state */
        avrcp_enter_state(inst);
    }
}


/****************************************************************************
NAME    
    avrcp_get_state - Gets AVRCP state
*/
AVRCP_STATE_T avrcp_get_state(avrcpInstance *inst)
{
    return inst->avrcp_state;
}


/****************************************************************************
NAME    
    avrcp_get_instance_from_pointer - Returns AVRCP instance from AVRCP pointer
*/
avrcpInstance *avrcp_get_instance_from_pointer(AVRCP *avrcp)
{
    uint16 index;
    avrcpInstance *inst = theSource->avrcp_data.inst;
    
    if (inst)
    {
        for_all_avrcp_instance(index)
        {
            if ((inst->avrcp != 0) && (inst->avrcp == avrcp))
                return inst;
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    avrcp_get_instance_from_bdaddr - Returns AVRCP instance from Bluetooth address
*/
avrcpInstance *avrcp_get_instance_from_bdaddr(const bdaddr addr)
{
    uint16 index;
    avrcpInstance *inst = theSource->avrcp_data.inst;
    
    if (inst)
    {
        for_all_avrcp_instance(index)
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
    avrcp_get_free_instance - Returns AVRCP unused instance
*/
avrcpInstance *avrcp_get_free_instance(void)
{
    uint16 index;
    avrcpInstance *inst = theSource->avrcp_data.inst;
    
    if (inst)
    {
        for_all_avrcp_instance(index)
        {
            if ((inst->avrcp == NULL))
                return inst;
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    avrcp_start_connection - Starts an AVRCP connection
*/
void avrcp_start_connection(const bdaddr addr)
{
    if (AVRCP_PROFILE_IS_ENABLED)
    {
        avrcpInstance *inst = avrcp_get_instance_from_bdaddr(addr);
    
        if (inst == NULL)
        {
            inst = avrcp_get_free_instance();
            if (inst != NULL)
            {
                /* store address of device it's attempting to connect to */                    
                inst->addr = addr;
                /* don't know if AVRCP is supported at the moment */
                inst->avrcp_support = AVRCP_SUPPORT_UNKNOWN;
            }
        }        
    
        AVRCP_DEBUG(("AVRCP: avrcp_start_connection\n"));
        
        if (inst != NULL)
        {        
            DEBUG_BDADDR(addr);
            MessageSendLater(&inst->avrcpTask, AVRCP_INTERNAL_CONNECT_REQ, 0, theSource->ps_config->ps_timers.avrcp_connection_delay_timer);
        }
    }
}


/****************************************************************************
NAME    
    avrcp_init_instance - Initialises AVRCP instance
*/
void avrcp_init_instance(avrcpInstance *inst)
{
    inst->avrcpTask.handler = avrcp_msg_handler;
    avrcp_set_state(inst, AVRCP_STATE_DISCONNECTED);
    BdaddrSetZero(&inst->addr);
    inst->avrcp = NULL;
    inst->pending_vendor_command = FALSE;
    inst->remote_vendor_support = AVRCP_SUPPORT_UNKNOWN;
    inst->avrcp_support = AVRCP_SUPPORT_UNKNOWN;
    inst->avrcp_connection_retries = 0;
    if (inst->vendor_data != NULL)
    {
        avrcp_free_vendor_data(inst);
    }    
}


/****************************************************************************
NAME    
    avrcp_disconnect_all - Disconnect all AVRCP connections
*/
void avrcp_disconnect_all(void)
{
    uint16 index;
    avrcpInstance *inst = theSource->avrcp_data.inst;
    
    if (inst)
    {
        for_all_avrcp_instance(index)
        {
            if (avrcp_is_connected(avrcp_get_state(inst)))
                avrcp_set_state(inst, AVRCP_STATE_DISCONNECTING);
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    avrcp_send_internal_vendor_command - Queue AVRCP_INTERNAL_VENDOR_COMMAND_REQ message
*/
void avrcp_send_internal_vendor_command(avrcpInstance *inst, avc_subunit_type subunit_type, avc_subunit_id subunit_id, uint8 ctype, uint32 company_id, uint16 cmd_id, uint16 size_data, Source data)
{
    MAKE_MESSAGE(AVRCP_INTERNAL_VENDOR_COMMAND_REQ);    
    message->subunit_type = subunit_type;
    message->subunit_id = subunit_id;
    message->ctype = ctype;
    message->company_id = company_id;
    message->cmd_id = cmd_id;
    message->size_data = size_data;
    message->data = data;
    MessageSendConditionally(&inst->avrcpTask, AVRCP_INTERNAL_VENDOR_COMMAND_REQ, message, &inst->pending_vendor_command);
}


/****************************************************************************
NAME    
    avrcp_send_vendor_command - Send AVRCP VENDORDEPENDENT command if connected
*/
void avrcp_send_vendor_command(Task task, const AVRCP_INTERNAL_VENDOR_COMMAND_REQ_T *req)
{
    avrcpInstance *inst = (avrcpInstance *) task;
    
    /* we can have vendor commands queued up, check that a previous command hasn't
       been rejected which should stop us sending any more */
    if ((inst) && (inst->remote_vendor_support == AVRCP_SUPPORT_NO))
        return;

    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_CONNECTED:
        {
            AVRCP_DEBUG(("AVRCP avrcp_send_vendor_command\n"));
            /* command is now pending */
            inst->pending_vendor_command = req->cmd_id;
            /* task to receive message when Source is emptied */
            MessageSinkTask(StreamSinkFromSource(req->data), &inst->avrcpTask);
            /* send AVRCP Vendor command */
            AvrcpVendorDependentRequest(inst->avrcp, req->subunit_type, req->subunit_id, req->ctype, req->company_id, req->size_data, req->data);
        }
        break;
        
        default:
        {        
            avrcp_unhandled_state(inst);
        }
        break;
    }    
}


/****************************************************************************
NAME    
    avrcp_free_vendor_data - Free memory used in AVRCP VENDORDEPENDENT command
*/
void avrcp_free_vendor_data(avrcpInstance *inst)
{
    if (inst->vendor_data != NULL)
    {
        AVRCP_DEBUG(("AVRCP avrcp_free_vendor_data\n"));
        memory_free(inst->vendor_data);
        inst->vendor_data = NULL;
    }
}


/****************************************************************************
NAME    
    avrcp_sdp_search_cfm - Handle Service Search response
*/
void avrcp_sdp_search_cfm(avrcpInstance *inst, const CL_SDP_SERVICE_SEARCH_CFM_T *message)
{
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_DISCONNECTED:
        case AVRCP_STATE_CONNECTING_LOCAL:
        case AVRCP_STATE_CONNECTING_REMOTE:
        {
            if (message->status == sdp_response_success)
            {
                if (inst->avrcp_support != AVRCP_SUPPORT_YES)
                {
                    AVRCP_DEBUG(("AVRCP SDP ok, issue connect\n"));
                    inst->avrcp_support = AVRCP_SUPPORT_YES;
                    /* now issue connect request */
                    AvrcpConnectRequest(&inst->avrcpTask, &inst->addr);
                }
                else
                {
                    /* Service search has already been done so don't need to connect again
                       as there should be an ongoing connection attempt */
                    AVRCP_DEBUG(("AVRCP SDP ok, already know support so currently connecting\n"));
                }
            }
            else
            {
                avrcp_init_instance(inst); 
            }
        }
        break;
        
        default:
        {
            
        }
        break;
    }
}




/****************************************************************************
NAME    
    avrcp_handle_vendor_ind - Handle AVRCP Vendor command sent from remote device
*/
void avrcp_handle_vendor_ind(uint8 mic_mute_eq)
{  
    bool mic_mute = mic_mute_eq & 0x01;
    uint8 eq_index = mic_mute_eq >> 1;
    uint16 old_eq_index = theSource->volume_data.eq_index;
    bool old_mic_mute_mode = theSource->volume_data.mic_mute;
 
    AVRCP_DEBUG(("AVRCP: Handle Vendor Headset -> Dongle; [Mic mute:0x%x] [EQ:0x%x]\n", mic_mute, eq_index));
    
    /* update mic mute status */
    volume_mute_mic(mic_mute ? TRUE : FALSE);
    /* update locally stored EQ index */
    volume_set_dongle_levels(theSource->volume_data.mic_vol, theSource->volume_data.speaker_vol, theSource->volume_data.sidetone_vol, eq_index);    
    /* send message to DSP to change EQ mode and update mute state if they have changed */
    if (theSource->audio_data.audio_routed == AUDIO_ROUTED_A2DP)
    {
        if ((old_eq_index != theSource->volume_data.eq_index) || 
            (old_mic_mute_mode != theSource->volume_data.mic_mute))
        {
            AVRCP_DEBUG(("  EQ mode[%d]\n", theSource->audio_data.audio_a2dp_mode_params.eq_mode));
            theSource->audio_data.audio_a2dp_mode_params.eq_mode = theSource->volume_data.eq_index;
            audio_update_mode_parameters();  
        }
    }    
}


/****************************************************************************
NAME    
    avrcp_send_source_volume - Send locally stored volumes over AVRCP
*/
void avrcp_send_source_volume(avrcpInstance *inst)
{
    const uint16 size_data = 5;
    uint8 data[5];                        
    uint16 index = 0;
    
    data[0] = AVRCP_SET_ABSOLUTE_VOLUME_PDU_ID;
    data[1] = 0x00;
    data[2] = 0x00;
    data[3] = 0x01; /* size of the following data */ 
    
    if (theSource->volume_data.speaker_mute)
    {
        /* speaker muted so send min volume */
        data[4] = 0;
    }
    else
    {
        /* speaker not muted so send current volume */
        data[4] = (theSource->volume_data.speaker_vol * AVRCP_ABS_VOL_STEP_CHANGE) & 0x7f;
    }
    
    if (inst)
    {
        avrcp_source_vendor_command(inst, AVRCP_BLUETOOTH_SIG_COMPANY_ID, AVRCP_SET_ABSOLUTE_VOLUME_PDU_ID, size_data, data);
    }
    else
    {
        inst = theSource->avrcp_data.inst;
    
        if (inst)
        {  
            for_all_avrcp_instance(index)
            {
                if ((inst->avrcp != 0))
                {
                    switch (inst->avrcp_state)
                    {
                        case AVRCP_STATE_CONNECTED:
                        {            
                            avrcp_source_vendor_command(inst, AVRCP_BLUETOOTH_SIG_COMPANY_ID, AVRCP_SET_ABSOLUTE_VOLUME_PDU_ID, size_data, data);                
                        }
                        break;
                
                        default:
                        {
                        }
                        break;
                    }
                }
                inst++;
            }
        }
    }
}


/****************************************************************************
NAME    
    avrcp_register_volume_changes - Register to receive volume changes from the remote end
*/
void avrcp_register_volume_changes(avrcpInstance *inst)
{
    const uint16 size_data = 9;
    uint8 data[9];                        
    uint16 index = 0;
    
    data[0] = AVRCP_REGISTER_NOTIFICATION_PDU_ID;
    data[1] = 0x00;
    data[2] = 0x00;
    data[3] = 0x05; /* size of the following data */ 
    data[4] = AVRCP_EVENT_VOLUME_CHANGED;
    data[5] = 0x00;
    data[6] = 0x00;
    data[7] = 0x00;
    data[8] = 0x00;
    
    if (inst)
    {
        avrcp_source_vendor_command(inst, AVRCP_BLUETOOTH_SIG_COMPANY_ID, AVRCP_REGISTER_NOTIFICATION_PDU_ID, size_data, data);
    }
    else
    {
        inst = theSource->avrcp_data.inst;
    
        if (inst)
        {  
            for_all_avrcp_instance(index)
            {
                if ((inst->avrcp != 0))
                {
                    switch (inst->avrcp_state)
                    {
                        case AVRCP_STATE_CONNECTED:
                        {            
                            avrcp_source_vendor_command(inst, AVRCP_BLUETOOTH_SIG_COMPANY_ID, AVRCP_REGISTER_NOTIFICATION_PDU_ID, size_data, data);                
                        }
                        break;
                
                        default:
                        {
                        }
                        break;
                    }
                }
                inst++;
            }
        }
    }
}


/****************************************************************************
NAME    
    avrcp_source_vendor_command - Build AVRCP Vendor command to send to remote device
*/
void avrcp_source_vendor_command(avrcpInstance *inst, uint32 company_id, uint16 cmd_id, uint16 size_data, const uint8 *data)
{
    Source data_source;
    uint16 index;
    
    /* only send Vendor commands if the feature is enabled and the remote device has not rejected them */
    if ((theSource->ps_config->features.avrcp_vendor_enable) && (inst->remote_vendor_support != AVRCP_SUPPORT_NO))
    {
        if (inst->vendor_data == NULL)
        {  
            inst->vendor_data = memory_create(size_data);
    
            if (inst->vendor_data != NULL)
            {                    
                for (index = 0; index < size_data; index++)
                {
                    inst->vendor_data[index] = data[index];
                }                                
        
                data_source = StreamRegionSource(inst->vendor_data, size_data);
                
#ifdef DEBUG_AVRCP                
                AVRCP_DEBUG(("AVRCP_DEBUG: Send Vendor Dongle -> Headset; "));
                for (index = 0; index < size_data; index++)
                {
                    AVRCP_DEBUG(("0x%x ", data[index]));                    
                }
                AVRCP_DEBUG(("\n"));
#endif                
            
                if (data_source)
                {
                    avrcp_send_internal_vendor_command(inst, subunit_vendor_unique, 0, AVRCP_CTYPE_NOTIFICATION, company_id, cmd_id, size_data, data_source);               
                    return;
                }
                avrcp_free_vendor_data(inst);
            }   
        }
        else
        {
            MAKE_MESSAGE_WITH_LEN(AVRCP_SOURCE_VENDOR_COMMAND_REQ, size_data);  
            MessageCancelAll(&inst->avrcpTask, AVRCP_SOURCE_VENDOR_COMMAND_REQ);
            message->company_id = company_id;
            message->cmd_id = cmd_id;
            message->size_data = size_data;
            for (index = 0; index < size_data; index++)
            {
                message->data[index] = data[index];
            }
            MessageSendConditionally(&inst->avrcpTask, AVRCP_SOURCE_VENDOR_COMMAND_REQ, message, (uint16 *)&inst->vendor_data);
        }
    }
}


/****************************************************************************
NAME    
    avrcp_exit_state - Exits an AVRCP state
*/
static void avrcp_exit_state(avrcpInstance *inst)
{
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_DISCONNECTED:
        {
            avrcp_exit_state_disconnected(inst);
        }
        break;
        
        case AVRCP_STATE_CONNECTING_LOCAL:
        {
            avrcp_exit_state_connecting_local(inst);
        }
        break;
        
        case AVRCP_STATE_CONNECTING_REMOTE:
        {
            avrcp_exit_state_connecting_remote(inst);
        }
        break;
        
        case AVRCP_STATE_CONNECTED:
        {
            avrcp_exit_state_connected(inst);
        }
        break;
        
        case AVRCP_STATE_DISCONNECTING:
        {
            avrcp_exit_state_disconnecting(inst);
        }
        break;
        
        default:
        {
            avrcp_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_enter_state - Enters an AVRCP state
*/
static void avrcp_enter_state(avrcpInstance *inst)
{
    switch (avrcp_get_state(inst))
    {
        case AVRCP_STATE_DISCONNECTED:
        {
            avrcp_enter_state_disconnected(inst);
        }
        break;
        
        case AVRCP_STATE_CONNECTING_LOCAL:
        {
            avrcp_enter_state_connecting_local(inst);
        }
        break;
        
        case AVRCP_STATE_CONNECTING_REMOTE:
        {
            avrcp_enter_state_connecting_remote(inst);
        }
        break;
        
        case AVRCP_STATE_CONNECTED:
        {
            avrcp_enter_state_connected(inst);
        }
        break;
        
        case AVRCP_STATE_DISCONNECTING:
        {
            avrcp_enter_state_disconnecting(inst);
        }
        break;
        
        default:
        {
            avrcp_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    avrcp_exit_state_disconnected - Called on exiting the AVRCP_STATE_DISCONNECTED state
*/
static void avrcp_exit_state_disconnected(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_exit_state_connecting_local - Called on exiting the AVRCP_STATE_CONNECTING_LOCAL state
*/
static void avrcp_exit_state_connecting_local(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_exit_state_connecting_remote - Called on exiting the AVRCP_STATE_CONNECTING_REMOTE state
*/
static void avrcp_exit_state_connecting_remote(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_exit_state_connected - Called on exiting the AVRCP_STATE_CONNECTED state
*/
static void avrcp_exit_state_connected(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_exit_state_disconnecting - Called on exiting the AVRCP_STATE_DISCONNECTING state
*/
static void avrcp_exit_state_disconnecting(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_enter_state_disconnected - Called on entering the AVRCP_STATE_DISCONNECTED state
*/
static void avrcp_enter_state_disconnected(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_enter_state_connecting_local - Called on entering the AVRCP_STATE_CONNECTING_LOCAL state
*/
static void avrcp_enter_state_connecting_local(avrcpInstance *inst)
{
    if (inst->avrcp_support != AVRCP_SUPPORT_YES)
    {
        AVRCP_DEBUG(("AVRCP unknown, issue SDP\n"));
        ConnectionSdpServiceSearchRequest(&inst->avrcpTask, &inst->addr, AVRCP_MAX_SDP_RECS, sizeof(avrcp_service_search_pattern), avrcp_service_search_pattern);
    }
    else
    {
        AVRCP_DEBUG(("AVRCP supported, issue connect\n"));
        AvrcpConnectRequest(&inst->avrcpTask, &inst->addr);
    }
}


/****************************************************************************
NAME    
    avrcp_enter_state_connecting_remote - Called on entering the AVRCP_STATE_CONNECTING_REMOTE state
*/
static void avrcp_enter_state_connecting_remote(avrcpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    avrcp_enter_state_connected - Called on entering the AVRCP_STATE_CONNECTED state
*/
static void avrcp_enter_state_connected(avrcpInstance *inst)
{
    /* need to send audio levels to the headset */
    usb_get_audio_levels_update_headset(FALSE);
    avrcp_register_volume_changes(inst);
    /* reset connection attempts */
    inst->avrcp_connection_retries = 0;
}


/****************************************************************************
NAME    
    avrcp_enter_state_disconnecting - Called on entering the AVRCP_STATE_DISCONNECTING state
*/
static void avrcp_enter_state_disconnecting(avrcpInstance *inst)
{
    AvrcpDisconnectRequest(inst->avrcp);
}
