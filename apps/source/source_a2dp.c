/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_a2dp.c

DESCRIPTION
    A2DP profile functionality.
    
*/


/* header for this file */
#include "source_a2dp.h"
/* application header files */
#include "source_a2dp_msg_handler.h"
#include "source_app_msg_handler.h"
#include "source_audio.h"
#include "source_debug.h"
#include "source_inquiry.h"
#include "source_memory.h"
#include "source_private.h"
/* profile/library headers */
#include <a2dp.h>
/* VM headers */
#include <bdaddr.h>
#include <stdlib.h>
#include <string.h>


/*  A2DP Service Search Pattern    
    DataEl(0x35), Length(0x03), UUID(0x19), Advanced Audio Distribution(0x110D) */
static const uint8 a2dp_service_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0D};


#ifdef DEBUG_A2DP
    #define A2DP_DEBUG(x) DEBUG(x)

    const char *const a2dp_state_strings[A2DP_STATES_MAX] = {   "Disconnected",
                                                                "Connecting Local",
                                                                "Connecting Remote",
                                                                "Connected Signalling",
                                                                "Connecting Media Local",
                                                                "Connecting Media Remote",
                                                                "Connected Media",
                                                                "Media Streaming",
                                                                "Media Suspending Local",
                                                                "Media Suspended",
                                                                "Media Starting Local",
                                                                "Disconnecting Media",
                                                                "Disconnecting"};
#else
    #define A2DP_DEBUG(x)
#endif
    
    
/* Display unhandled states in Debug Mode */
#define a2dp_unhandled_state(inst) A2DP_DEBUG(("    A2DP Unhandled State [%d] inst[0x%x]\n", a2dp_get_state(inst), (uint16)inst));    

    
/* SBC Stream-End Point Capabilities */ 
static const uint8 a2dp_sbc_caps_source[] = {
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_SBC,

#if (defined ANALOGUE_INPUT_DEVICE && defined BC5_MULTIMEDIA)
    A2DP_SBC_SAMPLING_FREQ_44100     |
#else
    A2DP_SBC_SAMPLING_FREQ_48000     |
#endif    
    A2DP_SBC_CHANNEL_MODE_MONO       | A2DP_SBC_CHANNEL_MODE_DUAL_CHAN | A2DP_SBC_CHANNEL_MODE_STEREO    | A2DP_SBC_CHANNEL_MODE_JOINT_STEREO,

    A2DP_SBC_BLOCK_LENGTH_4          | A2DP_SBC_BLOCK_LENGTH_8         | A2DP_SBC_BLOCK_LENGTH_12        | A2DP_SBC_BLOCK_LENGTH_16        |
    A2DP_SBC_SUBBANDS_4              | A2DP_SBC_SUBBANDS_8             | A2DP_SBC_ALLOCATION_SNR         | A2DP_SBC_ALLOCATION_LOUDNESS,

    A2DP_SBC_BITPOOL_MIN,
    A2DP_SBC_BITPOOL_MAX,
        
    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB
};


/* Faststream Stream-End Point Capabilities */ 
static const uint8 a2dp_faststream_caps_source[] = {
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    10,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,

    A2DP_CSR_VENDOR_ID0,
    A2DP_CSR_VENDOR_ID1,
    A2DP_CSR_VENDOR_ID2,
    A2DP_CSR_VENDOR_ID3,
    A2DP_FASTSTREAM_CODEC_ID0,
    A2DP_FASTSTREAM_CODEC_ID1,
    A2DP_FASTSTREAM_MUSIC | A2DP_FASTSTREAM_VOICE,
#if (defined ANALOGUE_INPUT_DEVICE && defined BC5_MULTIMEDIA)
    A2DP_FASTSTREAM_MUSIC_SAMP_44100 | A2DP_FASTSTREAM_VOICE_SAMP_16000,
#else
    A2DP_FASTSTREAM_MUSIC_SAMP_48000 | A2DP_FASTSTREAM_VOICE_SAMP_16000,
#endif    
};


/* APT-X Stream-End Point Capabilities */ 
static const uint8 a2dp_aptx_caps_source[] = {
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    9,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,
    
    A2DP_APTX_VENDOR_ID0,
    A2DP_APTX_VENDOR_ID1,
    A2DP_APTX_VENDOR_ID2,
    A2DP_APTX_VENDOR_ID3,
    A2DP_APTX_CODEC_ID0,
    A2DP_APTX_CODEC_ID1,
    
#if (defined ANALOGUE_INPUT_DEVICE && defined BC5_MULTIMEDIA)
    A2DP_APTX_SAMPLING_FREQ_44100 | A2DP_APTX_CHANNEL_MODE_STEREO,
#else    
    A2DP_APTX_SAMPLING_FREQ_48000 | A2DP_APTX_CHANNEL_MODE_STEREO,
#endif    
    
    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB
};


/* APT-X Low Latency Stream-End Point Capabilities */ 
static const uint8 a2dp_aptxLowLatency_caps_source[] = {
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    19,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,
    
    A2DP_CSR_VENDOR_ID0,
    A2DP_CSR_VENDOR_ID1,
    A2DP_CSR_VENDOR_ID2,
    A2DP_CSR_VENDOR_ID3,
    A2DP_APTX_LOWLATENCY_CODEC_ID0,
    A2DP_APTX_LOWLATENCY_CODEC_ID1,
    
#if (defined ANALOGUE_INPUT_DEVICE && defined BC5_MULTIMEDIA)
    A2DP_APTX_SAMPLING_FREQ_44100 | A2DP_APTX_CHANNEL_MODE_STEREO,
#else    
    A2DP_APTX_SAMPLING_FREQ_48000 | A2DP_APTX_CHANNEL_MODE_STEREO,
#endif    

    A2DP_APTX_LOWLATENCY_VOICE_16000 | A2DP_APTX_LOWLATENCY_NEW_CAPS,

    A2DP_APTX_LOWLATENCY_RESERVED,
    A2DP_APTX_LOWLATENCY_TCL_LSB,
    A2DP_APTX_LOWLATENCY_TCL_MSB,
    A2DP_APTX_LOWLATENCY_ICL_LSB,
    A2DP_APTX_LOWLATENCY_ICL_MSB,
    A2DP_APTX_LOWLATENCY_MAX_RATE,
    A2DP_APTX_LOWLATENCY_AVG_TIME,
    A2DP_APTX_LOWLATENCY_GWBL_LSB,
    A2DP_APTX_LOWLATENCY_GWBL_MSB,
    
    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB
};


/* exit state functions */    
static void a2dp_exit_state(a2dpInstance *inst);
static void a2dp_exit_state_disconnected(a2dpInstance *inst);
static void a2dp_exit_state_connecting_local(a2dpInstance *inst);
static void a2dp_exit_state_connecting_remote(a2dpInstance *inst);
static void a2dp_exit_state_connected_signalling(a2dpInstance *inst);
static void a2dp_exit_state_connecting_media_local(a2dpInstance *inst);
static void a2dp_exit_state_connecting_media_remote(a2dpInstance *inst);
static void a2dp_exit_state_connected_media(a2dpInstance *inst);
static void a2dp_exit_state_connected_media_streaming(a2dpInstance *inst);
static void a2dp_exit_state_connected_media_suspending_local(a2dpInstance *inst);
static void a2dp_exit_state_connected_media_suspended(a2dpInstance *inst);
static void a2dp_exit_state_connected_media_starting_local(a2dpInstance *inst);
static void a2dp_exit_state_disconnecting_media(a2dpInstance *inst);
static void a2dp_exit_state_disconnecting(a2dpInstance *inst);
/* enter state functions */
static void a2dp_enter_state(a2dpInstance *inst, A2DP_STATE_T old_state);    
static void a2dp_enter_state_disconnected(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connecting_local(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connecting_remote(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connected_signalling(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connecting_media_local(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connecting_media_remote(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connected_media(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connected_media_suspending_local(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connected_media_suspended(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_connected_media_starting_local(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_disconnecting_media(a2dpInstance *inst, A2DP_STATE_T old_state);
static void a2dp_enter_state_disconnecting(a2dpInstance *inst, A2DP_STATE_T old_state);

/* other local functions */
static bool a2dp_is_dualstream_reconfigure_needed(void);
static A2DP_AUDIO_QUALITY_T a2dp_get_lowest_quality(void);

/* Stream-End Point Definitions */
#ifdef INCLUDE_APPLICATION_A2DP_CODEC_CONFIGURATION
/* application must respond to A2DP_CODEC_CONFIGURE_IND message */
static const sep_config_type sbc_sep = {A2DP_SEID_SBC, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(a2dp_sbc_caps_source), a2dp_sbc_caps_source};
static const sep_config_type faststream_sep = {A2DP_SEID_FASTSTREAM, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(a2dp_faststream_caps_source), a2dp_faststream_caps_source};
static const sep_config_type aptx_sep = {A2DP_SEID_APTX, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(a2dp_aptx_caps_source), a2dp_aptx_caps_source};
static const sep_config_type aptxLowLatency_sep = {A2DP_SEID_APTX_LOW_LATENCY, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(a2dp_aptxLowLatency_caps_source), a2dp_aptxLowLatency_caps_source};

#else
/* no A2DP_CODEC_CONFIGURE_IND message sent to application, the A2DP library chooses the configuration based on the registered Stream End Points */
static const sep_config_type sbc_sep = {A2DP_SEID_SBC, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 1, 0, sizeof(a2dp_sbc_caps_source), a2dp_sbc_caps_source};
static const sep_config_type faststream_sep = {A2DP_SEID_FASTSTREAM, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 1, 0, sizeof(a2dp_faststream_caps_source), a2dp_faststream_caps_source};
static const sep_config_type aptx_sep = {A2DP_SEID_APTX, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 1, 0, sizeof(a2dp_aptx_caps_source), a2dp_aptx_caps_source};
static const sep_config_type aptxLowLatency_sep = {A2DP_SEID_APTX_LOW_LATENCY, A2DP_KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 1, 0, sizeof(a2dp_aptxLowLatency_caps_source), a2dp_aptxLowLatency_caps_source};

#endif /*INCLUDE_APPLICATION_A2DP_CODEC_CONFIGURATION */

/* The max bitpools for the different audio qualities */
static const uint16 a2dp_max_bitpool_array[] = {A2DP_SBC_BITPOOL_LOW_QUALITY, A2DP_SBC_BITPOOL_MEDIUM_QUALITY, A2DP_SBC_BITPOOL_GOOD_QUALITY, A2DP_SBC_BITPOOL_HIGH_QUALITY};
/* The max bitpools for the different audio qualities under pool link conditions */
static const uint16 a2dp_max_bitpool_poor_link_array[] = {A2DP_SBC_BITPOOL_LOW_QUALITY-10, A2DP_SBC_BITPOOL_MEDIUM_QUALITY, A2DP_SBC_BITPOOL_GOOD_QUALITY-15, A2DP_SBC_BITPOOL_HIGH_QUALITY};


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    a2dp_init - Initialise A2DP
*/    
void a2dp_init(void)
{
    sep_data_type seps[A2DP_MAX_ENDPOINTS];   
    uint16 index;
    uint16 num_endpoints = 0;
    
    /* allocate memory for A2DP instances */
    theSource->a2dp_data.inst = (a2dpInstance *)memory_get_block(MEMORY_GET_BLOCK_PROFILE_A2DP);
    
    /* initialise each instance */
    for_all_a2dp_instance(index)
    {
        theSource->a2dp_data.inst[index].a2dp_state = A2DP_STATE_DISCONNECTED;
        a2dp_init_instance(&theSource->a2dp_data.inst[index]);
    }
    
    /* initialise the A2DP profile library */
    
    if (theSource->ps_config->a2dp_codecs.sbc)
    {
	    seps[num_endpoints].in_use = FALSE;
        seps[num_endpoints++].sep_config = &theSource->a2dp_data.sbc_caps;
    }    
    if (theSource->ps_config->a2dp_codecs.faststream)
    {
        seps[num_endpoints].in_use = FALSE;
        seps[num_endpoints++].sep_config = &theSource->a2dp_data.faststream_caps; 
    }
    if (theSource->ps_config->a2dp_codecs.aptx)
    {
        seps[num_endpoints].in_use = FALSE;
        seps[num_endpoints++].sep_config = &theSource->a2dp_data.aptx_caps; 
    }
    if (theSource->ps_config->a2dp_codecs.aptxLowLatency)
    {
        seps[num_endpoints].in_use = FALSE;
        seps[num_endpoints++].sep_config = &theSource->a2dp_data.aptxLowLatency_caps; 
    }
    
    A2dpInit(&theSource->a2dp_data.inst[0].a2dpTask, A2DP_INIT_ROLE_SOURCE, NULL, num_endpoints, seps, 0);
}


/****************************************************************************
NAME    
    a2dp_set_state - Set A2DP state
*/
void a2dp_set_state(a2dpInstance *inst, A2DP_STATE_T new_state)
{
    if (new_state < A2DP_STATES_MAX)
    {
        A2DP_STATE_T old_state = inst->a2dp_state;
        
        /* leaving current state */        
        a2dp_exit_state(inst);
        
        /* store new state */
        inst->a2dp_state = new_state;
        A2DP_DEBUG(("A2DP STATE: new state [%s]\n", a2dp_state_strings[new_state]));
        
        /* entered new state */
        a2dp_enter_state(inst, old_state);
    }
}


/****************************************************************************
NAME    
    a2dp_get_state - Gets A2DP state
*/
A2DP_STATE_T a2dp_get_state(a2dpInstance *inst)
{
    return inst->a2dp_state;
}


/****************************************************************************
NAME    
    a2dp_start_connection - Starts an A2DP connection
*/
void a2dp_start_connection(void)
{
    a2dpInstance *inst = NULL;
    
    if (!BdaddrIsZero(&theSource->connection_data.remote_connection_addr))
    {            
        inst = a2dp_get_instance_from_bdaddr(theSource->connection_data.remote_connection_addr);            
    
        if (inst == NULL)
        {
            inst = a2dp_get_free_instance();
            
            if (inst != NULL)
            {
                /* store address of device it's attempting to connect to */
                inst->addr = theSource->connection_data.remote_connection_addr;
                /* don't know if A2DP is supported at the moment */
                inst->a2dp_support = A2DP_SUPPORT_UNKNOWN;
            }
        }
    
        A2DP_DEBUG(("A2DP: a2dp_start_connection"));
        DEBUG_BDADDR(theSource->connection_data.remote_connection_addr);
    
        if (inst != NULL)
        {           
            /* there is a free A2DP instance so initiate signalling connection */
            MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_CONNECT_REQ, 0);        
        }
        else
        {
            /* there is no free A2DP instance so signal to the app that the connection attempt has failed */            
            MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);
        }
    }
}


/****************************************************************************
NAME    
    a2dp_get_instance_from_device_id - Returns A2DP instance from Device ID
*/
a2dpInstance *a2dp_get_instance_from_device_id(uint16 device_id)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (inst->a2dp_device_id == device_id)
            {
                A2DP_DEBUG(("    instance from deviceID %d\n", device_id));
                return inst;
            }
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    a2dp_get_instance_from_bdaddr - Returns A2DP instance from Bluetooth address
*/
a2dpInstance *a2dp_get_instance_from_bdaddr(const bdaddr addr)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (!BdaddrIsZero(&inst->addr) && BdaddrIsSame(&inst->addr, &addr))
            {
                A2DP_DEBUG(("    instance from bdaddr\n"));
                return inst;
            }
            inst++;
        }
    }
    
    return NULL;
}


/****************************************************************************
NAME    
    a2dp_get_free_instance - Returns A2DP unused instance
*/
a2dpInstance *a2dp_get_free_instance(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (BdaddrIsZero(&inst->addr))
            {
                A2DP_DEBUG(("    got free instance\n"));
                return inst;
            }
            inst++;
        }
    }
    
    A2DP_DEBUG(("    no free instance\n"));
    
    return NULL;
}


/****************************************************************************
NAME    
    a2dp_init_instance - Initialises A2DP instance
*/
void a2dp_init_instance(a2dpInstance *inst)
{
    A2DP_DEBUG(("A2DP: a2dp_init_instance inst[0x%x]\n", (uint16)inst));
    inst->a2dpTask.handler = a2dp_msg_handler;
    a2dp_set_state(inst, A2DP_STATE_DISCONNECTED);
    inst->a2dp_device_id = A2DP_INVALID_ID;
    inst->a2dp_stream_id = A2DP_INVALID_ID; 
    inst->media_sink = 0;
    inst->a2dp_support = A2DP_SUPPORT_UNKNOWN;
    inst->a2dp_connection_retries = 0;
    inst->a2dp_suspending = 0;
    inst->a2dp_reconfiguring = FALSE;
    inst->a2dp_reconfigure_codec = 0;
    inst->a2dp_role = hci_role_master;
    inst->a2dp_quality = A2DP_AUDIO_QUALITY_UNKNOWN;
    BdaddrSetZero(&inst->addr);
}


/****************************************************************************
NAME    
    a2dp_get_number_connections - Returns the number of A2DP connections
*/
uint16 a2dp_get_number_connections(void)
{
    uint16 connections = 0;
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (a2dp_is_connected(a2dp_get_state(inst)))
                connections++;
            inst++;
        }
    }
    
    return connections;
}


/****************************************************************************
NAME    
    a2dp_disconnect_all - Disconnect all A2DP connections
*/
void a2dp_disconnect_all(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            A2DP_DEBUG(("A2DP: inst[0x%x]\n", (uint16)inst));
            if (a2dp_is_connected(a2dp_get_state(inst)))
            {
                A2DP_DEBUG(("A2DP: CONNECTED inst[0x%x] state[0x%d]\n", (uint16)inst, a2dp_get_state(inst)));
                /* cancel any suspending attempt */
                inst->a2dp_suspending = 0;
                /* cancel any reconfigure attempt */
                inst->a2dp_reconfiguring = FALSE;
         
                if (a2dp_is_media(a2dp_get_state(inst)))
                {
                    /* disconnect media first if it exists */
                    a2dp_set_state(inst, A2DP_STATE_DISCONNECTING_MEDIA);
                }
                else
                {
                    /* no media so disconnect signalling */
                    a2dp_set_state(inst, A2DP_STATE_DISCONNECTING);
                }
            }
            inst++;
        }
    }
}


/****************************************************************************
NAME    
    a2dp_set_sbc_config - Sets the SBC Stream-End Point configuration
*/
void a2dp_set_sbc_config(bool use_defaults)
{
    if (use_defaults)
    {
        theSource->a2dp_data.sbc_codec_config = NULL; /* no change in configuration */
        theSource->a2dp_data.sbc_caps = sbc_sep; /* default End Point data */ 
    }
    else
    {        
        if (theSource->a2dp_data.sbc_codec_config)
        {         
            uint16 i;
            /* copy the original codec settings to the memory location */
            for (i = 0; i < sizeof(a2dp_sbc_caps_source); i++)
            { 
                theSource->a2dp_data.sbc_codec_config[i] = a2dp_sbc_caps_source[i];
            }
            
            /* change as defined in PS Key data */
            /* if SPDIF is configured as an input, then only permit 44.1 or 48kHz sampling frequency. */
            if (theSource->ps_config->features.input_source == A2dpEncoderInputDeviceSPDIF)
            {
                /* clear out unsupported 16kHz and 32kHz frequency options if present,
                 * if neither of the permitted 44.1kHz or 48kHz are set, then default to 48kHz */
                theSource->ps_config->sbc_config.sampling_freq_ch_mode &= ~(A2DP_SBC_SAMPLING_FREQ_16000 | A2DP_SBC_SAMPLING_FREQ_32000);
                if (!(theSource->ps_config->sbc_config.sampling_freq_ch_mode & (A2DP_SBC_SAMPLING_FREQ_44100 | A2DP_SBC_SAMPLING_FREQ_48000)))
                {
                    theSource->ps_config->sbc_config.sampling_freq_ch_mode |= A2DP_SBC_SAMPLING_FREQ_48000;
                }
            }
            theSource->a2dp_data.sbc_codec_config[A2DP_SBC_SAMPLING_CHANNEL_INDEX] = theSource->ps_config->sbc_config.sampling_freq_ch_mode;
            theSource->a2dp_data.sbc_codec_config[A2DP_SBC_MIN_BITPOOL_INDEX] = theSource->ps_config->sbc_config.min_bitpool;
            theSource->a2dp_data.sbc_codec_config[A2DP_SBC_MAX_BITPOOL_INDEX] = theSource->ps_config->sbc_config.max_bitpool;
      
            /* update with the new caps */
            theSource->a2dp_data.sbc_caps.caps = theSource->a2dp_data.sbc_codec_config;           
        }
    }
}


/****************************************************************************
NAME    
    a2dp_set_faststream_config - Sets the Faststream Stream-End Point configuration
*/
void a2dp_set_faststream_config(bool use_defaults)
{
    if (use_defaults)
    {
        theSource->a2dp_data.faststream_codec_config = NULL; /* no change in configuration */
        theSource->a2dp_data.faststream_caps = faststream_sep; /* default End Point data */
        theSource->a2dp_data.faststream_caps.flush_timeout = A2DP_LOW_LATENCY_FLUSH_TIMEOUT; /* set flush timeout */
        
        A2DP_DEBUG(("A2DP: seid[0x%x] timeout[0x%x]\n", theSource->a2dp_data.faststream_caps.seid, theSource->a2dp_data.faststream_caps.flush_timeout));       
    }
    else
    {        
        if (theSource->a2dp_data.faststream_codec_config)
        {           
            uint16 i;
            /* copy the original codec settings to the memory location */
            for (i = 0; i < sizeof(a2dp_faststream_caps_source); i++)
            { 
                theSource->a2dp_data.faststream_codec_config[i] = a2dp_faststream_caps_source[i];
            }

            /* change as defined in PS Key data */
            theSource->a2dp_data.faststream_codec_config[A2DP_FASTSTREAM_DIRECTION_INDEX] = theSource->ps_config->faststream_config.music_voice;            
            theSource->a2dp_data.faststream_codec_config[A2DP_FASTSTREAM_SAMPLING_INDEX] = theSource->ps_config->faststream_config.sampling_freqs;            
            /* update with the new caps */
            theSource->a2dp_data.faststream_caps.caps = theSource->a2dp_data.faststream_codec_config;          
        }
    }
}


/****************************************************************************
NAME    
    a2dp_set_aptx_config - Sets the APT-X Stream-End Point configuration
*/
void a2dp_set_aptx_config(bool use_defaults)
{
    if (use_defaults)
    {
        theSource->a2dp_data.aptx_codec_config = NULL; /* no change in configuration */
        theSource->a2dp_data.aptx_caps = aptx_sep; /* default End Point data */
    }
    else
    {
        if (theSource->a2dp_data.aptx_codec_config)
        {        
            uint16 i;
            /* copy the original codec settings to the memory location */
            for (i = 0; i < sizeof(a2dp_aptx_caps_source); i++)
            { 
                theSource->a2dp_data.aptx_codec_config[i] = a2dp_aptx_caps_source[i];
            }

            /* change as defined in PS Key data */
            theSource->a2dp_data.aptx_codec_config[A2DP_APTX_SAMPLING_RATE_INDEX] = (theSource->ps_config->aptx_config.sampling_freqs & 0xf0) | A2DP_APTX_CHANNEL_MODE_STEREO;                        
            /* update with the new caps */
            theSource->a2dp_data.aptx_caps.caps = theSource->a2dp_data.aptx_codec_config;           
        }
    }
}


/****************************************************************************
NAME    
    a2dp_set_aptxLowLatency_config - Sets the APT-X Low Latency Stream-End Point configuration
*/
void a2dp_set_aptxLowLatency_config(bool use_defaults)
{
    if (use_defaults)
    {
        theSource->a2dp_data.aptxLowLatency_codec_config = NULL; /* no change in configuration */
        theSource->a2dp_data.aptxLowLatency_caps = aptxLowLatency_sep; /* default End Point data */
    }
    else
    {
        if (theSource->a2dp_data.aptxLowLatency_codec_config)
        {        
            uint16 i;
            /* copy the original codec settings to the memory location */
            for (i = 0; i < sizeof(a2dp_aptxLowLatency_caps_source); i++)
            { 
                theSource->a2dp_data.aptxLowLatency_codec_config[i] = a2dp_aptxLowLatency_caps_source[i];
            }

            /* change as defined in PS Key data */
            theSource->a2dp_data.aptxLowLatency_codec_config[A2DP_APTX_SAMPLING_RATE_INDEX] = (theSource->ps_config->aptxLowLatency_config.sampling_freqs & 0xf0) | A2DP_APTX_CHANNEL_MODE_STEREO;
            theSource->a2dp_data.aptxLowLatency_codec_config[A2DP_APTX_DIRECTION_INDEX] = A2DP_APTX_LOWLATENCY_NEW_CAPS;
            if (theSource->ps_config->aptxLowLatency_config.bidirectional)
            {
                theSource->a2dp_data.aptxLowLatency_codec_config[A2DP_APTX_DIRECTION_INDEX] |= A2DP_APTX_LOWLATENCY_VOICE_16000;
            }
            /* update with the new caps */
            theSource->a2dp_data.aptxLowLatency_caps.caps = theSource->a2dp_data.aptxLowLatency_codec_config;           
        }
    }
}


/****************************************************************************
NAME    
    a2dp_get_sbc_caps_size - Returns the SBC Stream-End Point configuration size
*/
uint16 a2dp_get_sbc_caps_size(void)
{
    return sizeof(a2dp_sbc_caps_source);
}


/****************************************************************************
NAME    
    a2dp_get_faststream_caps_size - Returns the Faststream Stream-End Point configuration size
*/
uint16 a2dp_get_faststream_caps_size(void)
{
    return sizeof(a2dp_faststream_caps_source);
}


/****************************************************************************
NAME    
    a2dp_get_aptx_caps_size - Returns the APT-X Stream-End Point configuration size
*/
uint16 a2dp_get_aptx_caps_size(void)
{
    return sizeof(a2dp_aptx_caps_source);
}


/****************************************************************************
NAME    
    a2dp_get_aptxLowLatency_caps_size - Returns the APT-X Low Latency Stream-End Point configuration size
*/
uint16 a2dp_get_aptxLowLatency_caps_size(void)
{
    return sizeof(a2dp_aptxLowLatency_caps_source);
}


/****************************************************************************
NAME    
    a2dp_sdp_search_cfm - Handles an A2DP service search result
*/
void a2dp_sdp_search_cfm(a2dpInstance *inst, const CL_SDP_SERVICE_SEARCH_CFM_T *message)
{
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_CONNECTING_LOCAL:
        {
            if (message->status == sdp_response_success)
            {
                A2DP_DEBUG(("A2DP SDP ok, issue connect\n"));
                inst->a2dp_support = A2DP_SUPPORT_YES;
                /* now issue connect request */
                if (!A2dpSignallingConnectRequest(&inst->addr))
                {
                    MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);         
                }                
            }
            else
            {
                MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);
                a2dp_init_instance(inst); 
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
    a2dp_remote_features_cfm - Called when the remote device features have been read
*/
void a2dp_remote_features_cfm(a2dpInstance *inst, const CL_DM_REMOTE_FEATURES_CFM_T *message)
{
    A2DP_AUDIO_QUALITY_T quality = A2DP_AUDIO_QUALITY_UNKNOWN;
    A2DP_AUDIO_QUALITY_T lowest_quality = a2dp_get_lowest_quality();
    
    /* Determine the sort of audio quality a link could support. */
    if ((message->features[1] & SUPPORTED_FEATURES_WORD2_EDR_ACL_2MBPS_3MBPS) && 
        (message->features[2] & SUPPORTED_FEATURES_WORD3_EDR_ACL_3SLOT_5SLOT))
    {
        /* Capable of supporting EDR ACL 2Mbps and/or 3Mbps with three or five slot packets */
        quality = A2DP_AUDIO_QUALITY_HIGH;
    }
    else if (message->features[0] & SUPPORTED_FEATURES_WORD1_5SLOT)
    {
        /* Capable of supporting BR ACL 1Mbps with five slot packets */
        quality = A2DP_AUDIO_QUALITY_MEDIUM;
    }
    else
    {
        /* All other data rate and slot size combinations only capable of supporting a low data rate */
        quality = A2DP_AUDIO_QUALITY_LOW;
    }
    
    /* store audio quality for A2DP link */
    inst->a2dp_quality = quality;

    /* check DualStream quality */
    if ((a2dp_get_number_connections() > 1) && (lowest_quality <= A2DP_AUDIO_QUALITY_MEDIUM))
    {
        /* If the quality is too low in DualStream mode then must disconnect A2DP for 2nd device */
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
        A2DP_DEBUG(("A2DP disconnecting 2nd link due to quality\n"));
    }
    else
    {
        /* may need to update bitpool for SBC links */
        a2dp_update_sbc_bitpool();
    }
    
    A2DP_DEBUG(("A2DP link quality [%d]\n", quality));
}


/****************************************************************************
NAME    
    a2dp_resume_audio - This is called to Resume the A2DP audio, normally when an (e)SCO audio connection has been removed
*/
void a2dp_resume_audio(void)
{
    a2dpInstance *inst = theSource->a2dp_data.inst;
    uint16 index = 0;
    
    A2DP_DEBUG(("A2DP a2dp_resume_audio\n"));
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            /* cancel pending suspend requests */
            MessageCancelAll(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_SUSPEND_REQ);
            
            switch (inst->a2dp_state)
            {
                case A2DP_STATE_CONNECTED_SIGNALLING:
                {
                    a2dp_set_state(inst, A2DP_STATE_CONNECTING_MEDIA_LOCAL);
                }
                return;
                
                case A2DP_STATE_CONNECTED_MEDIA:
                case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
                {
                    a2dp_set_state(inst, A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL); 
                }
                return;
                
                case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
                {
                    MessageSendConditionally(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_START_REQ, 0, &inst->a2dp_suspending);
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
    a2dp_route_all_audio - Routes audio for all A2DP connections
*/
void a2dp_route_all_audio(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {   
            if (a2dp_is_connected(a2dp_get_state(inst)))
            {
                /* initiate the audio connection */    
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_CONNECT_AUDIO_REQ, 0);
            }
            inst++;
        }
    }
    
    /* reset audio delay flag */
    theSource->audio_data.audio_a2dp_connection_delay = FALSE;
}


/****************************************************************************
NAME    
    a2dp_suspend_all_audio - Suspends audio for all A2DP connections
*/
void a2dp_suspend_all_audio(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {   
            if (a2dp_is_streaming(a2dp_get_state(inst)))
            {
                /* suspend the audio connection */    
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_SUSPEND_REQ, 0);
            }
            inst++;
        }
    }    
}


#ifdef INCLUDE_APPLICATION_A2DP_CODEC_CONFIGURATION
/****************************************************************************
NAME    
    a2dp_configure_sbc - Configures the SBC codec
*/
bool a2dp_configure_sbc(A2DP_CODEC_CONFIGURE_IND_T *message)
{
    uint16 local_index = 6;
    uint16 remote_index = 4;    
    uint8 min_bitpool = 0;
    uint8 max_bitpool = 0;
    
    /* Select Sample rate */
    if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x10) && 
        (message->codec_service_caps[remote_index] & 0x10) &&
        (theSource->audio_data.audio_a2dp_connect_params.input_device_type == A2dpEncoderInputDeviceUsb))
    {
        /* choose 48kHz */
        message->codec_service_caps[remote_index] &= 0x1f;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x20) && 
             (message->codec_service_caps[remote_index] & 0x20))
    {
        /* choose 44.1kHz */
        message->codec_service_caps[remote_index] &= 0x2f;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x40) && 
             (message->codec_service_caps[remote_index] & 0x40))
    {
        /* choose 32kHz */
        message->codec_service_caps[remote_index] &= 0x4f;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x80) && 
             (message->codec_service_caps[remote_index] & 0x80))
    {
        /* choose 16kHz */
        message->codec_service_caps[remote_index] &= 0x8f;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    /* Select Channel Mode */
    if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x01) && 
        (message->codec_service_caps[remote_index] & 0x01))
    {
        /* choose joint stereo */
        message->codec_service_caps[remote_index] &= 0xf1;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x02) && 
             (message->codec_service_caps[remote_index] & 0x02))
    {
        /* choose stereo */
        message->codec_service_caps[remote_index] &= 0xf2;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x04) && 
             (message->codec_service_caps[remote_index] & 0x04))
    {
        /* choose dual mode */
        message->codec_service_caps[remote_index] &= 0xf4;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x08) && 
             (message->codec_service_caps[remote_index] & 0x08))
    {
        /* choose dual mode */
        message->codec_service_caps[remote_index] &= 0xf8;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    /* process next data octet */
    local_index++;
    remote_index++;
    
    /* Select Block Length */
    if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x10) && 
        (message->codec_service_caps[remote_index] & 0x10))
    {
        /* choose 16 */
        message->codec_service_caps[remote_index] &= 0x1f;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x20) && 
             (message->codec_service_caps[remote_index] & 0x20))
    {
        /* choose 12 */
        message->codec_service_caps[remote_index] &= 0x2f;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x40) && 
             (message->codec_service_caps[remote_index] & 0x40))
    {
        /* choose 8 */
        message->codec_service_caps[remote_index] &= 0x4f;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x80) && 
             (message->codec_service_caps[remote_index] & 0x80))
    {
        /* choose 4 */
        message->codec_service_caps[remote_index] &= 0x8f;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
  
    /* Select Subbands */
    if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x04) && 
        (message->codec_service_caps[remote_index] & 0x04))
    {
        /* choose 8 */
        message->codec_service_caps[remote_index] &= 0xf7;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x08) && 
             (message->codec_service_caps[remote_index] & 0x08))
    {
        /* choose 4 */
        message->codec_service_caps[remote_index] &= 0xfb;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
      
    /* Select Allocation Method */
    if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x01) && 
        (message->codec_service_caps[remote_index] & 0x01))
    {
        /* choose Loudness */
        message->codec_service_caps[remote_index] &= 0xfd;
    }
    else if ((theSource->a2dp_data.sbc_caps.caps[local_index] & 0x02) && 
             (message->codec_service_caps[remote_index] & 0x02))
    {
        /* choose SNR */
        message->codec_service_caps[remote_index] &= 0xfe;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    /* process next data octet */
    local_index++;
    remote_index++;
    
    /* Select the minimum bitpool value based on local and remote settings */
    min_bitpool = theSource->a2dp_data.sbc_caps.caps[local_index];
    if (min_bitpool > message->codec_service_caps[remote_index])
        message->codec_service_caps[remote_index] = min_bitpool;
    
    /* process next data octet */
    local_index++;
    remote_index++;
    
    /* Select the maximum bitpool value based on local and remote settings */
    max_bitpool = theSource->a2dp_data.sbc_caps.caps[local_index];
    if (max_bitpool < message->codec_service_caps[remote_index])
        message->codec_service_caps[remote_index] = max_bitpool;
    
    return TRUE;
}


/****************************************************************************
NAME    
    a2dp_configure_faststream - Configures the FastStream codec
*/
bool a2dp_configure_faststream(A2DP_CODEC_CONFIGURE_IND_T *message)
{
    uint16 local_index = 12;
    uint16 remote_index = 10;
    bool audio_in_mic = FALSE;
    bool audio_out_music = FALSE;
    
    /* Choose audio direction */
    if ((theSource->a2dp_data.faststream_caps.caps[local_index] & 0x03) &&
        (message->codec_service_caps[remote_index] & 0x03))
    {
        /* bi-directional audio */
        message->codec_service_caps[remote_index] = 0x03;
        audio_in_mic = TRUE;
        audio_out_music = TRUE;
    }
    else if ((theSource->a2dp_data.faststream_caps.caps[local_index] & 0x01) &&
             (message->codec_service_caps[remote_index] & 0x01))
    {
        /* audio out music channel */
        message->codec_service_caps[remote_index] = 0x01;
        audio_out_music = TRUE;
    }
    else if ((theSource->a2dp_data.faststream_caps.caps[local_index] & 0x02) &&
             (message->codec_service_caps[remote_index] & 0x02))
    {
        /* audio in mic channel */
        message->codec_service_caps[remote_index] = 0x02;
        audio_in_mic = TRUE;
    }    
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    /* process next data octet */
    local_index++;
    remote_index++;
    
    /* Choose Sample rates */
    if ((theSource->a2dp_data.faststream_caps.caps[local_index] & 0x20) &&
        (message->codec_service_caps[remote_index] & 0x20))
    {
        /* audio in mic channel rate */
        message->codec_service_caps[remote_index] &= 0x2f;
    }
    else if (audio_in_mic)
    {
        /* audio in configured but no sample rate, return error */
        return FALSE;
    }
    else if ((theSource->a2dp_data.faststream_caps.caps[local_index] & 0x01) &&
             (message->codec_service_caps[remote_index] & 0x01) &&
             (theSource->audio_data.audio_a2dp_connect_params.input_device_type == A2dpEncoderInputDeviceUsb))
    {
        /* choose 48kHz audio out music rate */
        message->codec_service_caps[remote_index] &= 0xf1;
    }
    else if ((theSource->a2dp_data.faststream_caps.caps[local_index] & 0x02) &&
             (message->codec_service_caps[remote_index] & 0x01))
    {
        /* choose 44.1kHz audio out music rate */
        message->codec_service_caps[remote_index] &= 0xf2;
    }
    else if (audio_out_music)
    {
        /* audio out configured but no sample rate, return error */
        return FALSE;
    }   
    
    return TRUE;
}


/****************************************************************************
NAME    
    a2dp_configure_aptx - Configures the APT-X codec
*/
bool a2dp_configure_aptx(A2DP_CODEC_CONFIGURE_IND_T *message)
{
    uint16 local_index = 12;
    uint16 remote_index = 10; 
    
    /* Check Sample Rates */
    if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x10) &&
        (message->codec_service_caps[remote_index] & 0x10))
    {
        /* 48kHz */
        message->codec_service_caps[remote_index] &= 0x1f;
    }
    else if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x20) &&
             (message->codec_service_caps[remote_index] & 0x20))
    {
        /* 44.1kHz */
        message->codec_service_caps[remote_index] &= 0x2f;
    }
    else if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x40) &&
             (message->codec_service_caps[remote_index] & 0x40))
    {
        /* 32kHz */
        message->codec_service_caps[remote_index] &= 0x4f;
    }
    else if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x80) &&
             (message->codec_service_caps[remote_index] & 0x80))
    {
        /* 16kHz */
        message->codec_service_caps[remote_index] &= 0x8f;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    /* Select Channel Mode */
    if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x01) && 
        (message->codec_service_caps[remote_index] & 0x01))
    {
        /* choose joint stereo */
        message->codec_service_caps[remote_index] &= 0xf1;
    }
    else if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x02) && 
             (message->codec_service_caps[remote_index] & 0x02))
    {
        /* choose stereo */
        message->codec_service_caps[remote_index] &= 0xf2;
    }
    else if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x04) && 
             (message->codec_service_caps[remote_index] & 0x04))
    {
        /* choose dual mode */
        message->codec_service_caps[remote_index] &= 0xf4;
    }
    else if ((theSource->a2dp_data.aptx_caps.caps[local_index] & 0x08) && 
             (message->codec_service_caps[remote_index] & 0x08))
    {
        /* choose dual mode */
        message->codec_service_caps[remote_index] &= 0xf8;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    return TRUE;
}


/****************************************************************************
NAME    
    a2dp_configure_aptxLowLatency - Configures the APT-X Low Latency codec
*/
bool a2dp_configure_aptxLowLatency(A2DP_CODEC_CONFIGURE_IND_T *message)
{
    uint16 local_index = 12;
    uint16 remote_index = 10; 
    
    /* Check Sample Rates */
    if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x10) &&
        (message->codec_service_caps[remote_index] & 0x10))
    {
        /* 48kHz */
        message->codec_service_caps[remote_index] &= 0x1f;
    }
    else if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x20) &&
             (message->codec_service_caps[remote_index] & 0x20))
    {
        /* 44.1kHz */
        message->codec_service_caps[remote_index] &= 0x2f;
    }
    else if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x40) &&
             (message->codec_service_caps[remote_index] & 0x40))
    {
        /* 32kHz */
        message->codec_service_caps[remote_index] &= 0x4f;
    }
    else if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x80) &&
             (message->codec_service_caps[remote_index] & 0x80))
    {
        /* 16kHz */
        message->codec_service_caps[remote_index] &= 0x8f;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
    
    /* Select Channel Mode */
    if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x01) && 
        (message->codec_service_caps[remote_index] & 0x01))
    {
        /* choose joint stereo */
        message->codec_service_caps[remote_index] &= 0xf1;
    }
    else if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x02) && 
             (message->codec_service_caps[remote_index] & 0x02))
    {
        /* choose stereo */
        message->codec_service_caps[remote_index] &= 0xf2;
    }
    else if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x04) && 
             (message->codec_service_caps[remote_index] & 0x04))
    {
        /* choose dual mode */
        message->codec_service_caps[remote_index] &= 0xf4;
    }
    else if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x08) && 
             (message->codec_service_caps[remote_index] & 0x08))
    {
        /* choose dual mode */
        message->codec_service_caps[remote_index] &= 0xf8;
    }
    else
    {
        /* error occured so return failure */
        return FALSE;
    }
	
	/* process next data octet */
    local_index++;
    remote_index++;
	
    /* Check new low latency caps support */
	if ((theSource->a2dp_data.aptxLowLatency_caps.caps[local_index] & 0x02) && 
        (message->codec_service_caps[remote_index] & 0x02))
    {
        /* For the low latency parameters the source dongle sets the values
	       irrespective of what the remote device sends */ 
		remote_index = 13;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_TCL_LSB;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_TCL_MSB;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_ICL_LSB;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_ICL_MSB;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_MAX_RATE;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_AVG_TIME;
	    message->codec_service_caps[remote_index++] = A2DP_APTX_LOWLATENCY_GWBL_LSB;
	    message->codec_service_caps[remote_index]   = A2DP_APTX_LOWLATENCY_GWBL_MSB;
    }
  
    return TRUE;
}
#endif /* INCLUDE_APPLICATION_A2DP_CODEC_CONFIGURATION */


/****************************************************************************
NAME    
    a2dp_get_sbc_bitpool - Gets the SBC bitpool that should be used for the audio stream
*/
bool a2dp_get_sbc_bitpool(uint8 *bitpool, uint8 *bad_link_bitpool, bool *multiple_streams)
{
    a2dp_codec_settings *settings = NULL;
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    uint8 min_bitpool = 0;
    uint8 max_bitpool = 0;
    uint8 min_configured_bp = 0;
    uint8 max_configured_bp = 0;
    uint8 optimal_bitpool = 0;
    hci_role role = hci_role_master;
    A2DP_AUDIO_QUALITY_T quality = A2DP_AUDIO_QUALITY_HIGH;
    uint16 a2dp_media_streams = 0;
    
    *bitpool = 0;
    *bad_link_bitpool = 0;
    *multiple_streams = FALSE;
    
    if (!theSource->ps_config->a2dp_codecs.sbc)
    {
        /* return if SBC not enabled */
        return FALSE;
    }
    
    /* loop through all A2DP connections to look for open SBC media channels */
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (a2dp_is_media(a2dp_get_state(inst)))
            {
                settings = A2dpCodecGetSettings(inst->a2dp_device_id, inst->a2dp_stream_id);
            
                if (settings)
                {
                    if (a2dp_seid_is_sbc(settings->seid))
                    {
                        /* get min and max bitpools from configured codec settings */
                        min_configured_bp = 0;
                        max_configured_bp = 0;
                        if (settings->size_configured_codec_caps >= sizeof(a2dp_sbc_caps_source))
                        {
                            if ((settings->configured_codec_caps[A2DP_SERVICE_TRANSPORT_INDEX] == AVDTP_SERVICE_MEDIA_TRANSPORT) &&
                                (settings->configured_codec_caps[A2DP_SERVICE_CODEC_INDEX] == AVDTP_SERVICE_MEDIA_CODEC) &&
                                (settings->configured_codec_caps[A2DP_MEDIA_CODEC_INDEX] == AVDTP_MEDIA_CODEC_SBC))
                            {
                                min_configured_bp = settings->configured_codec_caps[A2DP_SBC_MIN_BITPOOL_INDEX];
                                max_configured_bp = settings->configured_codec_caps[A2DP_SBC_MAX_BITPOOL_INDEX];
                            }
                        }
                        
                        /* check if the bitpool limits need to be updated based on all configured A2DP streams */
                        if (!min_bitpool || (min_bitpool && min_configured_bp && (min_configured_bp > min_bitpool)))
                        {
                            /* store the new min bitpool */
                            min_bitpool = min_configured_bp;
                        }
                        if (!max_bitpool || (max_bitpool && max_configured_bp && (max_configured_bp < max_bitpool)))
                        {
                            /* store the new max and optimal bitpool */
                            max_bitpool = max_configured_bp;
                            optimal_bitpool = settings->codecData.bitpool;
                        }
                        /* store worst case audio quality */
                        if (inst->a2dp_quality < quality)
                            quality = inst->a2dp_quality;
                        if (inst->a2dp_role == hci_role_slave)
                            role = hci_role_slave;
                    
                        a2dp_media_streams++;
                    }
                
                    memory_free(settings);
                }
            }
            inst++;
        }
    }

    if (theSource->ps_config->features.sbc_force_max_bitpool && max_bitpool)
    {
        /* choose max bitpool */
        optimal_bitpool = max_bitpool;
        
        /* make sure chosen bitpool is not outside local bitpool settings */
        /* check min bitpool */
        if (theSource->a2dp_data.sbc_caps.caps[A2DP_SBC_MIN_BITPOOL_INDEX] > optimal_bitpool)
            optimal_bitpool = theSource->a2dp_data.sbc_caps.caps[A2DP_SBC_MIN_BITPOOL_INDEX];    
        /* check max bitpool */
        if (theSource->a2dp_data.sbc_caps.caps[A2DP_SBC_MAX_BITPOOL_INDEX] < optimal_bitpool)
            optimal_bitpool = theSource->a2dp_data.sbc_caps.caps[A2DP_SBC_MAX_BITPOOL_INDEX];
    }
    
    /* if there are multiple A2DP streams then might need to adjust bitpool further */
    if (a2dp_media_streams > 1)
    {
        if (role == hci_role_slave)
        {
            /* reduce quality futher if scatternet */
            if (quality > A2DP_AUDIO_QUALITY_LOW)
                quality--;
        }
        /* reduce bitpool if we need to stream at lower rate */
        if (a2dp_max_bitpool_array[quality] < optimal_bitpool)
        {
            optimal_bitpool = a2dp_max_bitpool_array[quality];                        
        }
        *bad_link_bitpool = a2dp_max_bitpool_poor_link_array[quality];

        /* make sure bitpool selection hasn't gone below the minimum */
        if (optimal_bitpool < min_bitpool)
            optimal_bitpool = min_bitpool;
        if (*bad_link_bitpool < min_bitpool)
            *bad_link_bitpool = min_bitpool;
        
        *multiple_streams = TRUE;
    }       
    
    /* return bitpools */
    if (a2dp_media_streams)
    {
        *bitpool = optimal_bitpool;
        if ((*bad_link_bitpool == 0) || (*bad_link_bitpool > *bitpool))
        {
            *bad_link_bitpool = *bitpool;
        }

        A2DP_DEBUG(("A2DP SBC bitpool [%d] bad_link_bitpool[%d]\n", *bitpool, *bad_link_bitpool));

        return TRUE;
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    a2dp_update_sbc_bitpool - Update the SBC bitpool that should be used for the audio stream
*/
void a2dp_update_sbc_bitpool(void)
{
    uint8 bitpool;
    uint8 bad_link_bitpool;
    bool multiple_streams;
          
    if (A2DP_DUALSTREAM_ENABLED)
    {
        if (a2dp_get_sbc_bitpool(&bitpool, &bad_link_bitpool, &multiple_streams))
        {
            if (multiple_streams)
            {
                /* Send new bitpool levels to DSP */
                audio_a2dp_update_bitpool(bitpool, bad_link_bitpool);
            }
        }
    }
}


/****************************************************************************
NAME    
    a2dp_store_role - Stores the role for the link (Master/Slave)
*/
void a2dp_store_role(bdaddr addr, hci_role role)
{
    a2dpInstance *inst = a2dp_get_instance_from_bdaddr(addr);
    
    if (inst != NULL)
    {
        inst->a2dp_role = role; 
        
        /* may need to update bitpool for SBC links */
        a2dp_update_sbc_bitpool();
        
        A2DP_DEBUG(("A2DP new role [%d]\n", role));
    }
}

/****************************************************************************
NAME    
    a2dp_is_connecting - Returns if the A2DP profile is currently connecting.
*/
bool a2dp_is_connecting(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    A2DP_STATE_T state;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            state = a2dp_get_state(inst);
            if ((state == A2DP_STATE_CONNECTING_LOCAL) || (state == A2DP_STATE_CONNECTING_REMOTE))
                return TRUE;
            inst++;
        }
    }
    
    return FALSE;
}

/****************************************************************************
NAME    
    a2dp_allow_more_connections - Check if more A2DP connections are allowed
*/
bool a2dp_allow_more_connections(void)
{
    if (A2DP_PROFILE_IS_ENABLED && 
        A2DP_DUALSTREAM_ENABLED &&
        (a2dp_get_number_connections() < A2DP_ENABLED_INSTANCES))
    {
        return TRUE;
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    a2dp_disconnect_media - Closes all open A2DP media connections and returns if A2DP media needs to be closed
*/
bool a2dp_disconnect_media(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    A2DP_STATE_T state;
    bool disconnect_required = FALSE;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            state = a2dp_get_state(inst);
            if (a2dp_is_media(state))
            {
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_CLOSE_REQ, 0);
                disconnect_required = TRUE;
            }
            inst++;
        }
    }
    
    return disconnect_required;
}


/****************************************************************************
NAME    
    a2dp_any_media_connections - This function returns if any media connections are still active
*/
bool a2dp_any_media_connections(void)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    A2DP_STATE_T state;
 
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            state = a2dp_get_state(inst);
            if (state >= A2DP_STATE_CONNECTED_MEDIA)
            {
                return TRUE;       
            }
            inst++;
        }
    }
    
    return FALSE;
}


/****************************************************************************
NAME    
    a2dp_get_connected_addr - This function returns the addresses of any connected A2DP devices.

*/
bool a2dp_get_connected_addr(bdaddr *addr_a, bdaddr *addr_b)
{
    uint16 index;
    a2dpInstance *inst = theSource->a2dp_data.inst;
    bool result = FALSE;
    uint16 count = 0;

    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (a2dp_is_connected(a2dp_get_state(inst)))
            {
                if (!count)
                {
                    *addr_a = inst->addr;
                }
                else
                {
                    *addr_b = inst->addr;
                }
                count++;
                result = TRUE;       
            }
            inst++;            
        }
    }
    
    return result;
}


/****************************************************************************
NAME    
    a2dp_exit_state - Exits an A2DP state
*/
static void a2dp_exit_state(a2dpInstance *inst)
{
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_DISCONNECTED:
        {
            a2dp_exit_state_disconnected(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTING_LOCAL:
        {
            a2dp_exit_state_connecting_local(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTING_REMOTE:
        {
            a2dp_exit_state_connecting_remote(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTED_SIGNALLING:
        {
            a2dp_exit_state_connected_signalling(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        {
            a2dp_exit_state_connecting_media_local(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTING_MEDIA_REMOTE:
        {
            a2dp_exit_state_connecting_media_remote(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA:
        {
            a2dp_exit_state_connected_media(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        {
            a2dp_exit_state_connected_media_streaming(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        {
            a2dp_exit_state_connected_media_suspending_local(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        {
            a2dp_exit_state_connected_media_suspended(inst);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        {
            a2dp_exit_state_connected_media_starting_local(inst);
        }
        break;
        
        case A2DP_STATE_DISCONNECTING_MEDIA:
        {
            a2dp_exit_state_disconnecting_media(inst);
        }
        break;
        
        case A2DP_STATE_DISCONNECTING:
        {
            a2dp_exit_state_disconnecting(inst);
        }
        break;
        
        default:
        {
            a2dp_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state - Enters an A2DP state
*/
static void a2dp_enter_state(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    switch (a2dp_get_state(inst))
    {
        case A2DP_STATE_DISCONNECTED:
        {
            a2dp_enter_state_disconnected(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTING_LOCAL:
        {
            a2dp_enter_state_connecting_local(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTING_REMOTE:
        {
            a2dp_enter_state_connecting_remote(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTED_SIGNALLING:
        {
            a2dp_enter_state_connected_signalling(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTING_MEDIA_LOCAL:
        {
            a2dp_enter_state_connecting_media_local(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTING_MEDIA_REMOTE:
        {
            a2dp_enter_state_connecting_media_remote(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA:
        {
            a2dp_enter_state_connected_media(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_STREAMING:
        {
            a2dp_enter_state_connected_media_streaming(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL:
        {
            a2dp_enter_state_connected_media_suspending_local(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_SUSPENDED:
        {
            a2dp_enter_state_connected_media_suspended(inst, old_state);
        }
        break;
        
        case A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL:
        {
            a2dp_enter_state_connected_media_starting_local(inst, old_state);
        }
        break;
        
        case A2DP_STATE_DISCONNECTING_MEDIA:
        {
            a2dp_enter_state_disconnecting_media(inst, old_state);
        }
        break;
        
        case A2DP_STATE_DISCONNECTING:
        {
            a2dp_enter_state_disconnecting(inst, old_state);
        }
        break;
        
        default:
        {
            a2dp_unhandled_state(inst);
        }
        break;
    }
}


/****************************************************************************
NAME    
    a2dp_exit_state_disconnected - Called on exiting the A2DP_STATE_DISCONNECTED state
*/
static void a2dp_exit_state_disconnected(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connecting_local - Called on exiting the A2DP_STATE_CONNECTING_LOCAL state
*/
static void a2dp_exit_state_connecting_local(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connecting_remote - Called on exiting the A2DP_STATE_CONNECTING_REMOTE state
*/
static void a2dp_exit_state_connecting_remote(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connected_signalling - Called on exiting the A2DP_STATE_CONNECTED_SIGNALLING state
*/
static void a2dp_exit_state_connected_signalling(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connecting_media_local - Called on exiting the A2DP_STATE_CONNECTING_MEDIA_LOCAL state
*/
static void a2dp_exit_state_connecting_media_local(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connecting_media_remote - Called on exiting the A2DP_STATE_CONNECTING_MEDIA_REMOTE state
*/
static void a2dp_exit_state_connecting_media_remote(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connected_media - Called on exiting the A2DP_STATE_CONNECTED_MEDIA state
*/
static void a2dp_exit_state_connected_media(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connected_media_streaming - Called on exiting the A2DP_STATE_CONNECTED_MEDIA_STREAMING state
*/
static void a2dp_exit_state_connected_media_streaming(a2dpInstance *inst)
{
    /* disconnect any audio */
    audio_a2dp_disconnect(inst->a2dp_device_id, inst->media_sink);
}


/****************************************************************************
NAME    
    a2dp_exit_state_connected_media_suspending_local - Called on exiting the A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL state
*/
static void a2dp_exit_state_connected_media_suspending_local(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connected_media_suspended - Called on exiting the A2DP_STATE_CONNECTED_MEDIA_SUSPENDED state
*/
static void a2dp_exit_state_connected_media_suspended(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_connected_media_starting_local - Called on exiting the A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL state
*/
static void a2dp_exit_state_connected_media_starting_local(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_disconnecting_media - Called on exiting the A2DP_STATE_DISCONNECTING_MEDIA state
*/
static void a2dp_exit_state_disconnecting_media(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_exit_state_disconnecting - Called on exiting the A2DP_STATE_DISCONNECTING state
*/
static void a2dp_exit_state_disconnecting(a2dpInstance *inst)
{
    
}


/****************************************************************************
NAME    
    a2dp_enter_state_disconnected - Called on entering the A2DP_STATE_DISCONNECTED state
*/
static void a2dp_enter_state_disconnected(a2dpInstance *inst, A2DP_STATE_T old_state)
{   
    if (a2dp_is_connected(old_state))
    {
        /* send message that has disconnection has occurred */    
        MessageSend(&theSource->app_data.appTask, APP_DISCONNECT_IND, 0); 
        /* cancel any media connect requests */
        MessageCancelAll(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_OPEN_REQ);
        /* reset audio delay flag */
        theSource->audio_data.audio_a2dp_connection_delay = FALSE;
        
        if (!a2dp_get_number_connections())
        {
            /* attempt to switch audio mode if this is the last A2DP device to disconnect */
            audio_switch_voip_music_mode(AUDIO_VOIP_MODE);
        }
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_connecting_local - Called on entering the A2DP_STATE_CONNECTING_LOCAL state
*/
static void a2dp_enter_state_connecting_local(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    if (inst->a2dp_support != A2DP_SUPPORT_YES)
    {
        /* attempt SDP search before issuing connect request */
        ConnectionSdpServiceSearchRequest(&inst->a2dpTask, &inst->addr, A2DP_MAX_SDP_RECS, sizeof(a2dp_service_search_pattern), a2dp_service_search_pattern);
    }
    else
    {
        /* it is known that A2DP is supported so try a connection */
        if (!A2dpSignallingConnectRequest(&inst->addr))
        {
            MessageSend(&theSource->app_data.appTask, APP_CONNECT_FAIL_CFM, 0);         
        }   
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_connecting_remote - Called on entering the A2DP_STATE_CONNECTING_REMOTE state
*/
static void a2dp_enter_state_connecting_remote(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    
}


/****************************************************************************
NAME    
    a2dp_enter_state_connected_signalling - Called on entering the A2DP_STATE_CONNECTED_SIGNALLING state
*/
static void a2dp_enter_state_connected_signalling(a2dpInstance *inst, A2DP_STATE_T old_state)
{    
    if ((old_state == A2DP_STATE_DISCONNECTED) ||
        (old_state == A2DP_STATE_CONNECTING_LOCAL) ||
        (old_state == A2DP_STATE_CONNECTING_REMOTE))
    {
        typed_bdaddr taddr;
        
        taddr.type = TYPED_BDADDR_PUBLIC;
        taddr.addr = inst->addr;
        
        /* Retrieve the role of this device */
        ConnectionGetRole(&theSource->connectionTask, A2dpSignallingGetSink(inst->a2dp_device_id));
  
        /* initiate an AVRCP connection to the device */
        avrcp_start_connection(inst->addr); 
        
        /* send message that has connection has occurred */    
        MessageSend(&theSource->app_data.appTask, APP_CONNECT_SUCCESS_CFM, 0); 
        
        /* register connection with connection manager */        
        connection_mgr_set_profile_connected(PROFILE_A2DP, &inst->addr);
        
        /* Send a request to find information about the connected device */
        ConnectionReadRemoteVersionBdaddr(&theSource->connectionTask, &taddr); 
        
        /* Read remote device features */
        ConnectionReadRemoteSuppFeatures(&inst->a2dpTask, A2dpSignallingGetSink(inst->a2dp_device_id));
        
        /* reset connection attempts */
        inst->a2dp_connection_retries = 0;
        
        /* for remote connections need to record that locally initiated audio connection 
            should be delayed incase remote end wants to initiate audio */
        if (old_state == A2DP_STATE_CONNECTING_REMOTE)
        {
            theSource->audio_data.audio_a2dp_connection_delay = TRUE;
        }
        
        /* check audio mode */
        if (theSource->audio_data.audio_voip_music_mode == AUDIO_VOIP_MODE)
        {
            /* attempt to switch audio mode from VOIP to MUSIC if A2DP connects */
            audio_set_voip_music_mode(AUDIO_MUSIC_MODE);
        }
    }
    else if (old_state == A2DP_STATE_DISCONNECTING_MEDIA)
    {
        /* The Source device disconnected the A2DP media */
        if (theSource->connection_data.disconnecting_a2dp_media_before_signalling)
        {
            /* The Source device wants to disconnect signalling after all A2DP media channels are removed.
               Check that all media has disconnected before removing signalling connections.
            */
            if (!a2dp_any_media_connections())
            {
                MessageCancelAll(&theSource->app_data.appTask, APP_DISCONNECT_SIGNALLING_REQ);
                MessageSend(&theSource->app_data.appTask, APP_DISCONNECT_SIGNALLING_REQ, 0);
            }
        }
        else
        {
            if (inst->a2dp_suspending)   
            {
                /* this was from a failed Suspend attempt, so remain in the connected state */
                inst->a2dp_suspending = 0;
            }
            if (inst->a2dp_reconfiguring)
            {
                /* this is a reconfigure so reopen media */
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_OPEN_REQ, 0);
            }
        }
    }
    else
    {
        if (inst->a2dp_connection_retries < theSource->ps_config->features.a2dp_max_connection_retries)
        {
            /* try to open media again after the PS delay */
            MessageSendLater(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_OPEN_REQ, 0, theSource->ps_config->ps_timers.audio_delay_timer);
            inst->a2dp_connection_retries++;
        }
        else
        {
            /* disconnect signalling as media couldn't be opened */
            MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
        }        
    }        
    
    /* no media sink at this point */
    inst->media_sink = 0;
}


/****************************************************************************
NAME    
    a2dp_enter_state_connecting_media_local - Called on entering the A2DP_STATE_CONNECTING_MEDIA_LOCAL state
*/
static void a2dp_enter_state_connecting_media_local(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    uint8 a2dp_seid_list[A2DP_MAX_ENDPOINTS];
    uint8 a2dp_seid_preference[A2DP_MAX_ENDPOINTS];
    uint16 current_endpoint = 0;
    uint16 i = 0;
    uint16 j = 0;
    uint16 k = 0;
    uint16 temp_id;
    uint16 temp_pref;
    uint16 preference = 1;
    
    if (inst->a2dp_reconfiguring)
    {
        /* this is a reconfigure so chose CODECS based on what is set as a2dp_reconfigure_codec */
        if (a2dp_seid_is_aptx(inst->a2dp_reconfigure_codec))
        {
            a2dp_seid_list[current_endpoint] = A2DP_SEID_APTX;
            a2dp_seid_preference[current_endpoint++] = preference++;                   
        }
        a2dp_seid_list[current_endpoint] = A2DP_SEID_SBC;
        a2dp_seid_preference[current_endpoint++] = preference++;
    }
    else
    {
        /* this is a standard A2DP Open so choose CODECS based on PS configuration */
        if (theSource->ps_config->a2dp_codecs.sbc)
        {
            a2dp_seid_list[current_endpoint] = A2DP_SEID_SBC;
            a2dp_seid_preference[current_endpoint++] = theSource->ps_config->a2dp_codecs.sbc_preference;
        }
        if (theSource->ps_config->a2dp_codecs.faststream)
        {
            a2dp_seid_list[current_endpoint] = A2DP_SEID_FASTSTREAM;
            a2dp_seid_preference[current_endpoint++] = theSource->ps_config->a2dp_codecs.faststream_preference;
        }    
        if (theSource->ps_config->a2dp_codecs.aptx)
        {
            a2dp_seid_list[current_endpoint] = A2DP_SEID_APTX;
            a2dp_seid_preference[current_endpoint++] = theSource->ps_config->a2dp_codecs.aptx_preference;
        }   
        if (theSource->ps_config->a2dp_codecs.aptxLowLatency)
        {
            a2dp_seid_list[current_endpoint] = A2DP_SEID_APTX_LOW_LATENCY;
            a2dp_seid_preference[current_endpoint++] = theSource->ps_config->a2dp_codecs.aptxLowLatency_preference;
        }  
    }
    
    /* sort list to try preferred codecs first */
    for (i = 1; i < current_endpoint; i++)
    {
        for (j = 0; j < i; j++)
        {
            if (a2dp_seid_preference[i] < a2dp_seid_preference[j])
            {
                temp_id = a2dp_seid_list[i];
                temp_pref = a2dp_seid_preference[i];
                for (k = i; k > j; k--)
                { 
                    a2dp_seid_list[k] = a2dp_seid_list[k - 1];
                    a2dp_seid_preference[k] = a2dp_seid_preference[k - 1];
                }
                a2dp_seid_list[j] = temp_id;
                a2dp_seid_preference[j] = temp_pref;
            }
        }
    }
    
#ifdef DEBUG_A2DP
    A2DP_DEBUG(("A2DP: Preferred List:\n"));
    for (i = 0; i < current_endpoint; i++)
    {
        A2DP_DEBUG(("    ID:[0x%x] Pref:[0x%x]\n", a2dp_seid_list[i], a2dp_seid_preference[i]));
    }
#endif    
    
    if (!A2dpMediaOpenRequest(inst->a2dp_device_id, current_endpoint, a2dp_seid_list))
    {
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_connecting_media_remote - Called on entering the A2DP_STATE_CONNECTING_MEDIA_REMOTE state
*/
static void a2dp_enter_state_connecting_media_remote(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    
}

/****************************************************************************
NAME    
    a2dp_enter_state_connected_media - Called on entering the A2DP_STATE_CONNECTED_MEDIA state
*/
static void a2dp_enter_state_connected_media(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    if ((old_state == A2DP_STATE_CONNECTING_MEDIA_LOCAL) || (old_state == A2DP_STATE_CONNECTING_MEDIA_REMOTE))
    {        
        if (!a2dp_is_dualstream_reconfigure_needed())
        {
            if (old_state == A2DP_STATE_CONNECTING_MEDIA_REMOTE)
            {
                /* start the media stream after a delay to see if remote side does the Start */
                MessageSendLater(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_START_REQ, 0, theSource->ps_config->ps_timers.audio_delay_timer);
                /* cancel any media connect requests */
                MessageCancelAll(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_OPEN_REQ);
            }
            else
            {
                /* start the media stream immediately after the media is opened */
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_START_REQ, 0);               
            }
        }
        
        /* reset connection attempts */
        inst->a2dp_connection_retries = 0;
        
        /* store media sink */
        inst->media_sink = A2dpMediaGetSink(inst->a2dp_device_id, inst->a2dp_stream_id);
    }
    if (old_state == A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL)
    {                
        if (inst->a2dp_connection_retries < theSource->ps_config->features.a2dp_max_connection_retries)
        {
            /* increase the number of times we've tried to issue an AVDTP_START */
            inst->a2dp_connection_retries++;
            /* issue start of the media stream again */
            MessageSendLater(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_START_REQ, 0, theSource->ps_config->ps_timers.audio_delay_timer);
        }
        else
        {
            /* start of media failed, must disconnect and begin connection again */
            MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
        }
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_connected_media_suspending_local - Called on entering the A2DP_STATE_CONNECTED_MEDIA_SUSPENDING_LOCAL state
*/
static void a2dp_enter_state_connected_media_suspending_local(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    if (!A2dpMediaSuspendRequest(inst->a2dp_device_id, inst->a2dp_stream_id))
    {
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
    }
    else
    {
        inst->a2dp_suspending = 1;
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_connected_media_suspended - Called on entering the A2DP_STATE_CONNECTED_MEDIA_SUSPENDED state
*/
static void a2dp_enter_state_connected_media_suspended(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    inst->a2dp_suspending = 0;
}


/****************************************************************************
NAME    
    a2dp_enter_state_connected_media_starting_local - Called on entering the A2DP_STATE_CONNECTED_MEDIA_STARTING_LOCAL state
*/
static void a2dp_enter_state_connected_media_starting_local(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    if (!A2dpMediaStartRequest(inst->a2dp_device_id, inst->a2dp_stream_id))
    {
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_disconnecting_media - Called on entering the A2DP_STATE_DISCONNECTING_MEDIA state
*/
static void a2dp_enter_state_disconnecting_media(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    if (!A2dpMediaCloseRequest(inst->a2dp_device_id, inst->a2dp_stream_id))
    {
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_SIGNALLING_DISCONNECT_REQ, 0);
    }
}


/****************************************************************************
NAME    
    a2dp_enter_state_disconnecting - Called on entering the A2DP_STATE_DISCONNECTING state
*/
static void a2dp_enter_state_disconnecting(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    if (!A2dpSignallingDisconnectRequest(inst->a2dp_device_id))
    {
        /* force disconnect by sending message which calls a2dp_init_instance(inst); */
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_FORCE_DISCONNECT_REQ, 0);
    }
}


/****************************************************************************
NAME    
    a2dp_is_dualstream_reconfigure_needed - Check if A2DP streams need to reconfigured due to DualStream operation
*/
static bool a2dp_is_dualstream_reconfigure_needed(void)
{
#ifdef INCLUDE_DUALSTREAM   
    
    a2dpInstance *inst = &theSource->profile_memory->a2dp[0];
    a2dp_codec_settings *codec_settings[A2DP_MAX_INSTANCES];
    bool reconfigure_needed = FALSE;
    uint16 index = 0;
    uint16 reconfigure_codec = A2DP_SEID_SBC;
    codec_settings[0] = codec_settings[1] = NULL;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {

            if (a2dp_is_media(inst->a2dp_state))
            {
                codec_settings[index] = A2dpCodecGetSettings(inst->a2dp_device_id, inst->a2dp_stream_id);
            }
            inst++;
        }
    }
    
    if (codec_settings[0] && codec_settings[1]) /* check if 2 A2DP streams are configured */
    {
        /* check CODECS in use */
        if (a2dp_seid_is_sbc(codec_settings[0]->seid) && a2dp_seid_is_sbc(codec_settings[1]->seid))
        {
            /* both SBC */
            reconfigure_codec = A2DP_SEID_SBC;
        }
        else if (a2dp_seid_is_faststream(codec_settings[0]->seid) && a2dp_seid_is_faststream(codec_settings[1]->seid))
        {
            /* both FastStream */
            reconfigure_codec = A2DP_SEID_FASTSTREAM;
        }
        else if (a2dp_seid_is_aptx(codec_settings[0]->seid) && a2dp_seid_is_aptx(codec_settings[1]->seid))
        {
            /* both APT-X */
            reconfigure_codec = A2DP_SEID_APTX; /* both support APT-X so can reopen with APT-X */
        }
        else
        {
            reconfigure_needed = TRUE; /* codecs different */    
        }
        
        if (codec_settings[0]->rate != codec_settings[1]->rate)
        {
            reconfigure_needed = TRUE; /* rates not the same */
        }  
        if (codec_settings[0]->channel_mode != codec_settings[1]->channel_mode)
        {
            reconfigure_needed = TRUE; /* channel modes not the same */
        }
        if (codec_settings[0]->codecData.content_protection != codec_settings[1]->codecData.content_protection)
        {
            reconfigure_needed = TRUE; /* content protection not the same */
        }
        if (codec_settings[0]->codecData.voice_rate != codec_settings[1]->codecData.voice_rate)
        {
            reconfigure_needed = TRUE; /* voice rate not the same */
        }
        if (codec_settings[0]->codecData.bitpool != codec_settings[1]->codecData.bitpool)
        {
            reconfigure_needed = TRUE; /* bitpool not the same */
        }
    }
    
    /* free memory */
    if (codec_settings[0])
        memory_free(codec_settings[0]);    
    if (codec_settings[1])
        memory_free(codec_settings[1]);
    
    /* decide if streams need to be reconfigured */
    if (reconfigure_needed)
    {
        inst = &theSource->profile_memory->a2dp[0];
        if (inst)
        {
            for_all_a2dp_instance(index)
            {
                /* close media so it can be re-opened with the correct configuration */
                inst->a2dp_reconfiguring = TRUE;
                inst->a2dp_reconfigure_codec = reconfigure_codec;
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_CLOSE_REQ, 0);               
                
                inst++;
            }
        }
        return TRUE;
    }

#endif /* INCLUDE_DUALSTREAM */
    
    return FALSE;
}


/****************************************************************************
NAME    
    a2dp_get_lowest_quality - Returns the lowest quality connection for all A2DP connections
*/
static A2DP_AUDIO_QUALITY_T a2dp_get_lowest_quality(void)
{
    uint16 index = 0;
    a2dpInstance *inst = &theSource->profile_memory->a2dp[0];
    A2DP_AUDIO_QUALITY_T lowest_quality = A2DP_AUDIO_QUALITY_UNKNOWN;
    
    if (inst)
    {
        for_all_a2dp_instance(index)
        {
            if (a2dp_is_connected(a2dp_get_state(inst)))
            {
                if (inst->a2dp_quality < lowest_quality)
                {
                    lowest_quality = inst->a2dp_quality;
                }
            }
            inst++;
        }
    }
    
    return lowest_quality;
}



/****************************************************************************
NAME    
    a2dp_enter_state_connected_media_streaming
*/
void a2dp_enter_state_connected_media_streaming(a2dpInstance *inst, A2DP_STATE_T old_state)
{
    Sink sink = A2dpMediaGetSink(inst->a2dp_device_id, inst->a2dp_stream_id);
    
    inst->media_sink = sink;

    /* reset reconfiguring flag */
    inst->a2dp_reconfiguring = FALSE;
    
    if (theSource->audio_data.audio_voip_music_mode == AUDIO_MUSIC_MODE)
    {        
        /* route A2DP audio */
        if (sink)
        {
            if (states_get_state() == SOURCE_STATE_CONNECTED)
            {             
                /* suspend AGHFP stream */
                aghfp_suspend_all_audio();
                
                if (!aghfp_is_audio_active())
                {
                    /* no AGHFP audio active */
                    if (A2DP_DUALSTREAM_ENABLED)
                    {
                        /* For Dual Stream, must make sure that if two A2DP device are connected they share the same Stream-End Point configuration */
                        if (!a2dp_is_dualstream_reconfigure_needed())
                        {                    
                            /* no reconfigure needed so okay to route A2DP audio */                
                            audio_a2dp_connect(sink, inst->a2dp_device_id, inst->a2dp_stream_id);
                        }
                    }
                    else
                    {
                        /* no AGHFP audio so okay to route A2DP audio */                
                        audio_a2dp_connect(sink, inst->a2dp_device_id, inst->a2dp_stream_id);
                    }
            
                    /* set sniff mode if PS Key has been read */
                    if (theSource->ps_config->sniff.number_a2dp_entries && theSource->ps_config->sniff.a2dp_powertable)
                    {
                        ConnectionSetLinkPolicy(A2dpSignallingGetSink(inst->a2dp_device_id), theSource->ps_config->sniff.number_a2dp_entries ,theSource->ps_config->sniff.a2dp_powertable);
                    }
                }
                else
                {
                    /* AGHFP audio is still active so suspend A2DP audio until AGHFP audio is fully disconnected
                        as remote devices can fail to route audio correctly */
                    MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_SUSPEND_REQ, 0);              
                }
            }
            else
            {
                /* not in connected state, so suspend A2DP audio */
                MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_SUSPEND_REQ, 0);              
            }
        }
    }
    else
    {
        /* MUSIC mode not active so suspend A2DP audio */
        MessageSend(&inst->a2dpTask, A2DP_INTERNAL_MEDIA_SUSPEND_REQ, 0);   
    }
    
    /* store current device to PS */   
    ps_write_new_remote_device(&inst->addr, PROFILE_A2DP);
            
    /* clear forced inquiry mode flag as is now streaming to a device */
    theSource->inquiry_mode.force_inquiry_mode = FALSE;
    
    /* reset connection attempts */
    inst->a2dp_connection_retries = 0;
}
