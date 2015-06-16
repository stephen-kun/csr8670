/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
*/

/*!
@file    sink_a2dp.c
@brief   a2dp initialisation and control functions
*/

#include "sink_debug.h"
#include "sink_statemanager.h"
#include "sink_states.h"
#include "sink_private.h"
#include "sink_a2dp.h"
#include "sink_debug.h"
#include "sink_devicemanager.h"
#include "sink_link_policy.h"
#include "sink_audio.h"
#include "sink_usb.h"
#include "sink_wired.h"
#include "sink_scan.h"
#include "sink_audio_routing.h"
#include "sink_slc.h"
#include "sink_device_id.h"
#include "sink_partymode.h"
#include "sink_config.h"
#include "sink_auth.h"
#include "sink_peer.h"
#include "sink_avrcp.h"


#ifdef ENABLE_AVRCP
#include "sink_tones.h"
#endif        

#include <bdaddr.h>
#include <a2dp.h>
#include <codec.h>
#include <connection.h>
#include <hfp.h>
#include <stdlib.h>
#include <memory.h>
#include <panic.h>
#include <ps.h>
#include <message.h>
#include <kalimba.h>
#ifdef ENABLE_SOUNDBAR
#include <inquiry.h>
#endif /* ENABLE_SOUNDBAR */

#include <csr_a2dp_decoder_common_plugin.h>
#include "sink_slc.h"

#ifdef DEBUG_A2DP
#define A2DP_DEBUG(x) DEBUG(x)
#ifdef ENABLE_PEER
static const char * rdname[] = { "Unknown", "Non-Peer", "Peer" };
#endif
#else
#define A2DP_DEBUG(x) 
#endif

#ifdef DEBUG_PEER
#define PEER_DEBUG(x) DEBUG(x)
#else
#define PEER_DEBUG(x) 
#endif

#ifdef ENABLE_PEER
#define SBC_SAMPLING_FREQ_16000        128
#define SBC_SAMPLING_FREQ_32000         64
#define SBC_SAMPLING_FREQ_44100         32
#define SBC_SAMPLING_FREQ_48000         16
#define SBC_CHANNEL_MODE_MONO            8
#define SBC_CHANNEL_MODE_DUAL_CHAN       4
#define SBC_CHANNEL_MODE_STEREO          2
#define SBC_CHANNEL_MODE_JOINT_STEREO    1

#define SBC_BLOCK_LENGTH_4             128
#define SBC_BLOCK_LENGTH_8              64
#define SBC_BLOCK_LENGTH_12             32
#define SBC_BLOCK_LENGTH_16             16
#define SBC_SUBBANDS_4                   8
#define SBC_SUBBANDS_8                   4
#define SBC_ALLOCATION_SNR               2
#define SBC_ALLOCATION_LOUDNESS          1

#define SBC_BITPOOL_MIN                  2
#define SBC_BITPOOL_MAX                250
#define SBC_BITPOOL_MEDIUM_QUALITY      35
#define SBC_BITPOOL_HIGH_QUALITY        53

/* Codec caps to use for a TWS Source SEP when 16KHz SBC is required */
const uint8 sbc_caps_16k[8] = 
{
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_SBC,

    SBC_SAMPLING_FREQ_16000 |  SBC_CHANNEL_MODE_JOINT_STEREO,

    SBC_BLOCK_LENGTH_16 | SBC_SUBBANDS_8 | SBC_ALLOCATION_SNR,

    SBC_BITPOOL_MIN,
    SBC_BITPOOL_HIGH_QUALITY
};


/* Codec caps to use for a TWS Source SEP when 32KHz SBC is required */
const uint8 sbc_caps_32k[8] = 
{
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_SBC,

    SBC_SAMPLING_FREQ_32000 |  SBC_CHANNEL_MODE_JOINT_STEREO,

    SBC_BLOCK_LENGTH_16 | SBC_SUBBANDS_8 | SBC_ALLOCATION_SNR,

    SBC_BITPOOL_MIN,
    SBC_BITPOOL_HIGH_QUALITY
};


/* Codec caps to use for a TWS Source SEP when 44.1KHz SBC is required */
const uint8 sbc_caps_44k1[8] = 
{
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_SBC,

    SBC_SAMPLING_FREQ_44100 |  SBC_CHANNEL_MODE_JOINT_STEREO,

    SBC_BLOCK_LENGTH_16 | SBC_SUBBANDS_8 | SBC_ALLOCATION_SNR,

    SBC_BITPOOL_MIN,
    SBC_BITPOOL_HIGH_QUALITY
};


/* Codec caps to use for a TWS Source SEP when 48KHz SBC is required */
const uint8 sbc_caps_48k[8] = 
{
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_SBC,

    SBC_SAMPLING_FREQ_48000 |  SBC_CHANNEL_MODE_JOINT_STEREO,

    SBC_BLOCK_LENGTH_16 | SBC_SUBBANDS_8 | SBC_ALLOCATION_SNR,

    SBC_BITPOOL_MIN,
    SBC_BITPOOL_HIGH_QUALITY
};
#endif

static const sep_config_type sbc_sep_snk = { SBC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(sbc_caps_sink), sbc_caps_sink };
#ifdef ENABLE_PEER
	static const sep_config_type sbc_sep_src = { SOURCE_SEID_MASK | SBC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(sbc_caps_sink), sbc_caps_sink };   /* Source shares same caps as sink */
	static const sep_config_type tws_sbc_sep_snk = { TWS_SEID_MASK | SBC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(tws_sbc_caps), tws_sbc_caps };
	static const sep_config_type tws_sbc_sep_src = { SOURCE_SEID_MASK | TWS_SEID_MASK | SBC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(tws_sbc_caps), tws_sbc_caps };
#endif

/* not all codecs are available for some configurations, include this define to have access to all codec types  */
#ifdef INCLUDE_A2DP_EXTRA_CODECS
    static const sep_config_type mp3_sep_snk = { MP3_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(mp3_caps_sink), mp3_caps_sink };
    static const sep_config_type aac_sep_snk = { AAC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(aac_caps_sink), aac_caps_sink };
    static const sep_config_type aptx_sep_snk = { APTX_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(aptx_caps_sink), aptx_caps_sink };
#ifdef ENABLE_PEER
    static const sep_config_type mp3_sep_src = { SOURCE_SEID_MASK | MP3_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(mp3_caps_sink), mp3_caps_sink };   /* Source shares same caps as sink */
    static const sep_config_type aac_sep_src = { SOURCE_SEID_MASK | AAC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(aac_caps_sink), aac_caps_sink };   /* Source shares same caps as sink */
    static const sep_config_type aptx_sep_src = { SOURCE_SEID_MASK | APTX_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(aptx_caps_sink), aptx_caps_sink };   /* Source shares same caps as sink */
    static const sep_config_type tws_mp3_sep_snk = { TWS_SEID_MASK | MP3_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(tws_mp3_caps), tws_mp3_caps };
    static const sep_config_type tws_mp3_sep_src = { SOURCE_SEID_MASK | TWS_SEID_MASK | MP3_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(tws_mp3_caps), tws_mp3_caps };
    static const sep_config_type tws_aac_sep_snk = { TWS_SEID_MASK | AAC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(tws_aac_caps), tws_aac_caps };
    static const sep_config_type tws_aac_sep_src = { SOURCE_SEID_MASK | TWS_SEID_MASK | AAC_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(tws_aac_caps), tws_aac_caps };
    static const sep_config_type tws_aptx_sep_snk = { TWS_SEID_MASK | APTX_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(tws_aptx_caps), tws_aptx_caps };
    static const sep_config_type tws_aptx_sep_src = { SOURCE_SEID_MASK | TWS_SEID_MASK | APTX_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_source, 0, 0, sizeof(tws_aptx_caps), tws_aptx_caps };
#endif
#ifdef INCLUDE_FASTSTREAM                
    static const sep_config_type faststream_sep = { FASTSTREAM_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(faststream_caps_sink), faststream_caps_sink };
#endif
#ifdef INCLUDE_APTX_ACL_SPRINT
    static const sep_config_type aptx_sprint_sep = { APTX_SPRINT_SEID, KALIMBA_RESOURCE_ID, sep_media_type_audio, a2dp_sink, 1, 0, sizeof(aptx_acl_sprint_caps_sink), aptx_acl_sprint_caps_sink };
#endif
#endif


#define NUM_SEPS (sizeof(codecList)/sizeof(codec_list_element))

typedef struct
{
    unsigned                bit:8;      /* The bit position in CONFIG_USR_xxx to enable the codec. */
    const sep_config_type   *config;    /* The SEP config data. These configs are defined above. */
    TaskData                *plugin;    /* The audio plugin to use. */
} codec_list_element;

    /* Table which indicates which A2DP codecs are avaiable on the device.
       Add other codecs in priority order, from top to bottom of the table.
    */
    static const codec_list_element codecList[] = 
    {
#ifdef INCLUDE_A2DP_EXTRA_CODECS
#ifdef INCLUDE_APTX_ACL_SPRINT
		/* AptX Sprint (low latency) Sink SEP */
        {APTX_SPRINT_CODEC_BIT, &aptx_sprint_sep, (TaskData *)&csr_aptx_acl_sprint_decoder_plugin},
#endif
		/* High quality Sink SEPs */
        {APTX_CODEC_BIT, &aptx_sep_snk, (TaskData *)&csr_aptx_decoder_plugin},
        {AAC_CODEC_BIT, &aac_sep_snk, (TaskData *)&csr_aac_decoder_plugin},
        {MP3_CODEC_BIT, &mp3_sep_snk, (TaskData *)&csr_mp3_decoder_plugin},
#ifdef ENABLE_PEER
#ifdef PEER_AS
		/* ShareMe Source SEPs */
        {APTX_CODEC_BIT, &aptx_sep_src, (TaskData *)&csr_aptx_decoder_plugin},
        {AAC_CODEC_BIT, &aac_sep_src, (TaskData *)&csr_aac_decoder_plugin},
        {MP3_CODEC_BIT, &mp3_sep_src, (TaskData *)&csr_mp3_decoder_plugin},
#endif
#ifdef PEER_TWS		
		/* TWS Source and Sink SEPs */ /* TODO: These could be moved as they don't need to be part of default search order - create lists for when using A2dpMedisOpenReq() ? */
        {APTX_CODEC_BIT, &tws_aptx_sep_src, (TaskData *)&csr_tws_aptx_decoder_plugin},
        {APTX_CODEC_BIT, &tws_aptx_sep_snk, (TaskData *)&csr_tws_aptx_decoder_plugin},
        {AAC_CODEC_BIT, &tws_aac_sep_src, (TaskData *)&csr_tws_aac_decoder_plugin},
        {AAC_CODEC_BIT, &tws_aac_sep_snk, (TaskData *)&csr_tws_aac_decoder_plugin},
        {MP3_CODEC_BIT, &tws_mp3_sep_src, (TaskData *)&csr_tws_mp3_decoder_plugin},
        {MP3_CODEC_BIT, &tws_mp3_sep_snk, (TaskData *)&csr_tws_mp3_decoder_plugin},
#endif
#endif
#ifdef INCLUDE_FASTSTREAM                
		/* Faststream Sink SEP */
        {FASTSTREAM_CODEC_BIT, &faststream_sep, (TaskData *)&csr_faststream_sink_plugin},
#endif
#endif
#ifdef ENABLE_PEER
#ifdef PEER_TWS
		/* TWS Source and Sink SEPs */
        {SBC_CODEC_BIT, &tws_sbc_sep_src, (TaskData *)&csr_tws_sbc_decoder_plugin},
        {SBC_CODEC_BIT, &tws_sbc_sep_snk, (TaskData *)&csr_tws_sbc_decoder_plugin},
#endif		
		/* Mandatory SBC Source SEP for both ShareMe and TWS */
        {SBC_CODEC_BIT, &sbc_sep_src, (TaskData *)&csr_sbc_decoder_plugin},
#endif
		/* Mandatory SBC Sink SEP */
        {SBC_CODEC_BIT, &sbc_sep_snk, (TaskData *)&csr_sbc_decoder_plugin}
    };

/****************************************************************************
  FUNCTIONS
*/

#if 0
/* Calculates Volume = (Gain / Scale) * Range
   Gain is 0..Scale, thus Gain/Scale is 0..1  and hence Volume is 0..Range
   
   Method of calculation keeps everything as 16-bit arithmetic
*/
#define HI(n) ((uint8)((n) >> 8))
#define LO(n) ((uint8)(n))
static uint16 calculateVolume (uint16 gain, uint16 scale, uint16 range)
{
    volume = (HI(gain) * HI(range)) / HI(scale);
    volume += (HI(gain) * LO(range)) / HI(scale);
    volume += (LO(gain) * HI(range)) / LO(scale);
    volume += (LO(gain) * LO(range)) / LO(scale);
    
    return volume;
}
#endif


/*************************************************************************
NAME    
    findCurrentA2dpSource
    
DESCRIPTION
    Attempts to obtain index of a connected A2dp Source that has established
    a media channel

RETURNS
    TRUE if found, FALSE otherwise

**************************************************************************/
bool findCurrentA2dpSource (a2dp_link_priority* priority)
{
    PEER_DEBUG(("findCurrentA2dpSource\n"));
    
    if (theSink.a2dp_link_data)
    {
        uint16 i;
        for (i = 0; i<MAX_A2DP_CONNECTIONS; i++)
        {
            PEER_DEBUG(("... pri:%u\n", i));
            
            if ( theSink.a2dp_link_data->connected[i] )
            {   /* Found a connected device */
                uint16 device_id = theSink.a2dp_link_data->device_id[i];
                uint16 stream_id = theSink.a2dp_link_data->stream_id[i];
                
                PEER_DEBUG(("...... dev:%u str:%u state:%u\n", device_id, stream_id, A2dpMediaGetState(device_id, stream_id)));
            
                switch ( A2dpMediaGetState(device_id, stream_id) )
                {
                case a2dp_stream_opening:
                case a2dp_stream_open:
                case a2dp_stream_starting:
                case a2dp_stream_streaming:
                case a2dp_stream_suspending:
                    PEER_DEBUG(("......... role:%u\n",A2dpMediaGetRole(device_id, stream_id)));
                    if ( A2dpMediaGetRole(device_id, stream_id)==a2dp_sink )
                    {   /* We have a sink endpoint active to the remote device, therefore it is a source */
                        PEER_DEBUG(("............ found sink\n"));
                        
                        if (priority != NULL)
                        {
                            *priority = i;
                        }
                        return TRUE;
                    }
                    break;
                    
                default:
                    break;
                }
            }
        }
    }
    
    return FALSE;
}

/*************************************************************************
NAME    
    updateA2dpLinkLossManagement
    
DESCRIPTION
    Enables/disabled the A2DP library managed link loss recovery mechanism dependant on connection status.
    Non-Peer devices will 
    
RETURNS
    
**************************************************************************/
static void updateA2dpLinkLossManagement (uint16 id)
{
    if (theSink.a2dp_link_data)
    {
#ifdef ENABLE_PEER
        if (theSink.a2dp_link_data->peer_device[id] == remote_device_peer)
        {   /* A Peer device will not have HFP connected, thus A2DP library will need to be used to provide link loss management */
            a2dp_stream_state a2dp_state = A2dpMediaGetState(theSink.a2dp_link_data->device_id[id], theSink.a2dp_link_data->stream_id[id]);
            a2dp_role_type a2dp_role = A2dpMediaGetRole(theSink.a2dp_link_data->device_id[id], theSink.a2dp_link_data->stream_id[id]);
            
            if (((a2dp_state == a2dp_stream_starting) || (a2dp_state == a2dp_stream_streaming)) && 
                 (a2dp_role == a2dp_source) && 
                 !theSink.features.PeerLinkRecoveryWhileStreaming)
            {   /* Relaying audio to a Slave Peer - don't manage linkloss */
                A2DP_DEBUG(("A2DP: Device = %u (peer),  manage linkloss = FALSE\n", id));
                A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[id], FALSE);
            }
            else
            {   /* Either no audio relay or acting as a Slave Peer */
                A2DP_DEBUG(("A2DP: Device = %u (peer),  manage linkloss = TRUE\n", id));
                A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[id], TRUE);
            }
        }
        else
#endif
        {   /* Non Peer or unknown device type.  Base A2DP link loss management on any HFP connection */
            bdaddr HfpAddr;

            if ((HfpLinkGetBdaddr(hfp_primary_link, &HfpAddr) && BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[id], &HfpAddr)) ||
                (HfpLinkGetBdaddr(hfp_secondary_link, &HfpAddr) && BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[id], &HfpAddr)) )
            {   /* HFP library will manage link loss */
                A2DP_DEBUG(("A2DP: Device = %u (non-peer),  manage linkloss = FALSE\n", id));
                A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[id], FALSE);
            }
            else
            {   /* No HFP connection, so A2DP library manages link loss */
                A2DP_DEBUG(("A2DP: Device = %u (non-peer),  manage linkloss = TRUE\n", id));
                A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[id], TRUE);
            }
        }
    }
}


#ifdef ENABLE_PEER
/*************************************************************************
NAME    
    a2dpGetPeerIndex
    
DESCRIPTION
    Attempts to obtain the index into a2dp_link_data structure for a currently 
    connected Peer device.
    
RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool a2dpGetPeerIndex (uint16* index)
{
    uint8 i;
    
    /* go through A2dp connection looking for device_id match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its device id */
        if(theSink.a2dp_link_data && theSink.a2dp_link_data->connected[i])
        {
            /* if a device_id match is found return its value and a
               status of successful match found */
            if(theSink.a2dp_link_data->peer_device[i] == remote_device_peer)
            {
                if (index)
                {
                    *index = i;
                }
                
                return TRUE;
            }
        }
    }
    /* no matches found so return not successful */    
    return FALSE;
}


/*************************************************************************
NAME    
    a2dpGetSourceIndex
    
    Attempts to obtain the index into a2dp_link_data structure for a currently 
    connected A2dp Source device.
    
RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool a2dpGetSourceIndex (uint16* index)
{
    uint8 i;
    
    /* go through A2dp connection looking for device_id match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its device id */
        if(theSink.a2dp_link_data && theSink.a2dp_link_data->connected[i])
        {
            /* if a device_id match is found return its value and a
               status of successful match found */
            if(theSink.a2dp_link_data->peer_device[i] == remote_device_nonpeer)
            {
                if (index)
                {
                    *index = i;
                }
                
                return TRUE;
            }
        }
    }
    /* no matches found so return not successful */    
    return FALSE;
}


/*************************************************************************
NAME    
    a2dpGetSourceSink
    
DESCRIPTION
    Attempts to obtain the media sink for a currently connected A2dp Source.

RETURNS
    Handle to media sink if present, NULL otherwise
    
**************************************************************************/
Sink a2dpGetSourceSink (void)
{
    uint16 av_id;
    
    if (a2dpGetSourceIndex(&av_id))
    {
        return A2dpMediaGetSink(theSink.a2dp_link_data->device_id[av_id], theSink.a2dp_link_data->stream_id[av_id]);
    }
    
    return NULL;
}

/*************************************************************************
NAME    
    getCodecSettings
    
DESCRIPTION
    Attempts to obtain the locally supplied codec setting for the specified SEID

RETURNS
    Pointer to codec settings structure, if found. NULL otherwise

**************************************************************************/
static a2dp_codec_settings * getCodecSettings (uint8 seid)
{
    uint16 i;
    
    for (i=0; i<NUM_SEPS; i++)
    {
        if (codecList[i].config && (codecList[i].config->seid == seid))
        {
            a2dp_codec_settings * codec_settings = (a2dp_codec_settings *)PanicNull( malloc(sizeof(a2dp_codec_settings) + codecList[i].config->size_caps) );
            memset(codec_settings, 0, sizeof(a2dp_codec_settings) +  codecList[i].config->size_caps);  /* Zero the Codec settings */
            
            codec_settings->size_configured_codec_caps = codecList[i].config->size_caps;
            memmove(codec_settings->configured_codec_caps, codecList[i].config->caps, codecList[i].config->size_caps);
            
            codec_settings->seid = seid; 

            return codec_settings;
        }
    }
    
	return NULL;
}


/*************************************************************************
NAME    
    modifyCodecSettings
    
DESCRIPTION
    Modifies the supplied general codec capabilities to provide specific 
    capabilities for the rate specified.

RETURNS
    None

**************************************************************************/
static void modifyCodecSettings (uint8 * codec_caps, uint16 codec_caps_size, uint16 rate)
{
    A2DP_DEBUG(("A2DP: modifyCodecSettings   codec_caps=0x%X   size=%u   rate=%u\n",(uint16)codec_caps,codec_caps_size,rate));
    
    /* Scan through codec caps for the Media Codec service category */
    while (codec_caps_size && codec_caps && (codec_caps[0] != AVDTP_SERVICE_MEDIA_CODEC))
    {   
        uint16 category_size = codec_caps[1] + 2;
        
        codec_caps += category_size;
    }
    
    if (codec_caps_size && codec_caps && (codec_caps[0] == AVDTP_SERVICE_MEDIA_CODEC))
    {   /* Media Codec service category located */
        const uint8 *new_codec_caps = NULL;
        
        switch (rate)
        {
        case 16000:
            new_codec_caps = sbc_caps_16k;
            break;
        case 32000:
            new_codec_caps = sbc_caps_32k;
            break;
        case 44100:
            new_codec_caps = sbc_caps_44k1;
            break;
        case 48000:
            new_codec_caps = sbc_caps_48k;
            break;
        }
        
        A2DP_DEBUG(("A2DP: Found AVDTP_SERVICE_MEDIA_CODEC, attempting to modify caps...\n"));
        A2DP_DEBUG(("A2DP: new_caps=0x%X   codec_caps[1]=%u  codec_caps[3]=%u   new_caps[1]=%u  new_caps[3]=%u\n", (uint16)new_codec_caps, codec_caps[1], codec_caps[3], new_codec_caps[1], new_codec_caps[3]));
        if (new_codec_caps && (codec_caps[1] == new_codec_caps[1]) && (codec_caps[3] == new_codec_caps[3]))
        {   /* Check category size and seid of new caps match current caps, before updating */
            memcpy(codec_caps, new_codec_caps, new_codec_caps[1] + 2);
        }
    }
}


/*************************************************************************
NAME    
    handleA2dpCodecConfigureIndFromPeer
    
DESCRIPTION
    All Peer specific SEPs are configured to ask the app to provide the appropriate parameters
    when attempting to issue an AVDTP_SET_CONFIGURATION_CMD for the relay stream.
    This function obtains the codec settings for the current source (Wired, USB or A2DP) and uses
    these to set the configuration for the relay stream.

RETURNS
    None
    
**************************************************************************/
static void handleA2dpCodecConfigureIndFromPeer (A2DP_CODEC_CONFIGURE_IND_T* ind)
{
    a2dp_link_priority priority;
    a2dp_codec_settings* codec_settings = NULL;
    RelaySource current_source = theSink.peer.current_source;
    
    PEER_DEBUG(("A2DP: handleA2dpCodecConfigureIndFromPeer dev:%u seid:0x%X\n", ind->device_id, ind->local_seid));
    
    switch (current_source)
    {
    case RELAY_SOURCE_NULL:
        PEER_DEBUG(("... Streaming Av Src not found\n"));
        break;
        
    case RELAY_SOURCE_ANALOGUE:
    {
        uint16 sample_freq;
        
        codec_settings = getCodecSettings( SBC_SEID );
        analogGetAudioRate(&sample_freq);
        modifyCodecSettings(codec_settings->configured_codec_caps, codec_settings->size_configured_codec_caps, sample_freq);
        break;
    }    
    case RELAY_SOURCE_USB:
    {
        uint16 sample_freq;
        
        codec_settings = getCodecSettings( SBC_SEID );
        UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_SPEAKER_SAMPLE_FREQ, &sample_freq);
        modifyCodecSettings(codec_settings->configured_codec_caps, codec_settings->size_configured_codec_caps, sample_freq);
        break;
    }    
    case RELAY_SOURCE_A2DP:
        if (findCurrentA2dpSource( &priority ))
        {
            codec_settings = A2dpCodecGetSettings(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]);
        }
        break;
    }
    
    if (codec_settings)
    {
        if ( !(codec_settings->seid & (SOURCE_SEID_MASK | TWS_SEID_MASK)) &&	/* Double check AV Source is using a standard Sink SEP */
			  ((ind->local_seid & SOURCE_SEID_MASK) == SOURCE_SEID_MASK) &&		/* Double check Relay stream is using Source SEP */
		      (codec_settings->seid == (ind->local_seid & BASE_SEID_MASK)) )	/* Same base codec id being used by AV Source and Relay stream */
        {   /* Source and sink seids use matching codec */
            /* Request same codec configuration settings as AV Source for peer device */
            PEER_DEBUG(("... Configuring codec dev:%u local codec_caps_size=%u seid=0x%X\n",ind->device_id, ind->size_codec_service_caps, ind->local_seid));
            PEER_DEBUG(("remote codec_caps_size=%u seid=0x%X\n", codec_settings->size_configured_codec_caps, codec_settings->seid));

			if (ind->local_seid & TWS_SEID_MASK)
			{	/* TWS Source SEP - place Sink codec caps into TWS codec caps */
				memcpy(ind->codec_service_caps+12, codec_settings->configured_codec_caps+2, codec_settings->size_configured_codec_caps-2);	/* TODO: Copy each service capability separately */
				A2dpCodecConfigureResponse(ind->device_id, TRUE, ind->local_seid, ind->size_codec_service_caps, ind->codec_service_caps);
			}
			else
			{	/* ShareMe Source SEP - use Sink codec caps for ShareMe codec */
				A2dpCodecConfigureResponse(ind->device_id, TRUE, ind->local_seid, codec_settings->size_configured_codec_caps, codec_settings->configured_codec_caps);
			}
        }
        else
        {   /* Source and sink seids do not use matching codec */
            PEER_DEBUG(("... Non matching codecs dev:%u seid:0x%X\n",ind->device_id, ind->local_seid));
            A2dpCodecConfigureResponse(ind->device_id, FALSE, ind->local_seid, 0, NULL);
        }
        
        free(codec_settings);
    }
    else
    {   /* Reject as we don't have an active source */
        A2dpCodecConfigureResponse(ind->device_id, FALSE, ind->local_seid, 0, NULL);
    }
}


/*************************************************************************
NAME    
    openPeerStream
    
DESCRIPTION
    Requests to open a media channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise
    
**************************************************************************/
static bool openPeerStream (uint16 Id, uint8 base_seid)
{
    PEER_DEBUG(("openPeerStream Dev=%u base_seid=%02X",Id, base_seid));
    
	base_seid &= BASE_SEID_MASK;
	
    /* Don't open AAC based stream to a peer device supporting ShareMe only */
    if (!(theSink.a2dp_link_data->peer_features[Id] & remote_features_tws_a2dp_sink) && (base_seid == AAC_SEID))
	{
        PEER_DEBUG(("  unsuitable\n"));
		return FALSE;
	}

	if (base_seid)
	{	
		uint8 seid_list[3];
		uint8 seid_list_size = 0;
		
        PEER_DEBUG(("  seid_list=["));
#ifdef PEER_TWS
		seid_list[seid_list_size++] = base_seid | (SOURCE_SEID_MASK | TWS_SEID_MASK);
        PEER_DEBUG(("%02X, ", seid_list[seid_list_size-1]));
#endif
#ifdef PEER_AS
		seid_list[seid_list_size++] = base_seid | SOURCE_SEID_MASK;
        PEER_DEBUG(("%02X, ", seid_list[seid_list_size-1]));
#endif
		seid_list[seid_list_size++] = SBC_SEID | SOURCE_SEID_MASK;		/* Always request a standard SBC source SEP, to support standard sink devices */
        PEER_DEBUG(("%02X]  size=%u\n", seid_list[seid_list_size-1], seid_list_size));
		
		/*return A2dpMediaOpenRequestEx(theSink.a2dp_link_data->device_id[Id], seid_list_size, seid_list, sizeof(a2dp_media_conftab), a2dp_media_conftab);*/
		return A2dpMediaOpenRequest(theSink.a2dp_link_data->device_id[Id], seid_list_size, seid_list);
	}

    PEER_DEBUG(("  unsuitable\n"));
	return FALSE;
}


/*************************************************************************
NAME    
    a2dpIssuePeerOpenRequest
    
DESCRIPTION
    Issues a request to opens a media stream to a currently connected Peer
    
RETURNS
    TRUE if request issued, FALSE otherwise
    
**************************************************************************/
bool a2dpIssuePeerOpenRequest (void)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        uint8 seid = INVALID_SEID;
        uint16 av_id;
        RelaySource current_source = theSink.peer.current_source;
        
        PEER_DEBUG(("issuePeerOpenRequest peer=%u  av=%u\n",peer_id,current_source));
        
        switch (current_source)
        {
        case RELAY_SOURCE_NULL:
            break;
        case RELAY_SOURCE_ANALOGUE:
        case RELAY_SOURCE_USB:
            seid = SBC_SEID;
            break;
        case RELAY_SOURCE_A2DP:
            if (a2dpGetSourceIndex(&av_id))
            {
                seid = theSink.a2dp_link_data->seid[av_id];
            }
            break;
        }
        
        return openPeerStream(peer_id, seid);
    }
    
    return FALSE;
}


/*************************************************************************
NAME    
    a2dpIssuePeerCloseRequest
    
DESCRIPTION
    Issues a request to close the relay channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise

**************************************************************************/
bool a2dpIssuePeerCloseRequest (void)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        PEER_DEBUG(("issuePeerCloseRequest peer=%u\n",peer_id));
        
        /* Ensure suspend state is set as streaming has now ceased */
        a2dpSetSuspendState(peer_id, a2dp_local_suspended);
        avrcpUpdatePeerPlayStatus(avrcp_play_status_stopped);
        
        return A2dpMediaCloseRequest(theSink.a2dp_link_data->device_id[peer_id], theSink.a2dp_link_data->stream_id[peer_id]);
    }
    
    return FALSE;
}


/*************************************************************************
NAME    
    a2dpIssuePeerStartRequest
    
DESCRIPTION
    Issues a request to start the relay channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise

**************************************************************************/
bool a2dpIssuePeerStartRequest (void)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        PEER_DEBUG(("issuePeerStartRequest peer=%u  local_peer_status=0x%X  remote_peer_status=0x%X\n",peer_id,theSink.a2dp_link_data->local_peer_status[peer_id],theSink.a2dp_link_data->remote_peer_status[peer_id]));
        
        if ( peerIsRelayAvailable() )
        {
            if (theSink.a2dp_link_data->link_role[peer_id] != LR_CURRENT_ROLE_MASTER)
            {
                Sink signalling_sink = A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[peer_id]);
                
                PEER_DEBUG(("   requesting role check before issuing start...\n"));
                
                theSink.a2dp_link_data->link_role[peer_id] = LR_CHECK_ROLE_PENDING_START_REQ;
                linkPolicyGetRole(&signalling_sink);
                
                return TRUE;
            }
            else
            {
                PEER_DEBUG(("   issuing start request...\n"));
                avrcpUpdatePeerPlayStatus(avrcp_play_status_playing);
                return A2dpMediaStartRequest(theSink.a2dp_link_data->device_id[peer_id], theSink.a2dp_link_data->stream_id[peer_id]);
            }
        }
    }

    return FALSE;
}


/*************************************************************************
NAME    
    a2dpIssuePeerSuspendRequest
    
DESCRIPTIONDESCRIPTION
    Issues a request to suspend the relay channel to the currently connected Peer

RETURNS
    TRUE if request issued, FALSE otherwise

**************************************************************************/
bool a2dpIssuePeerSuspendRequest (void)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        PEER_DEBUG(("issuePeerSuspendRequest peer=%u\n",peer_id));
        
        /* Ensure suspend state is set as streaming has now ceased */
        a2dpSetSuspendState(peer_id, a2dp_local_suspended);
        avrcpUpdatePeerPlayStatus(avrcp_play_status_paused);
        
        return A2dpMediaSuspendRequest(theSink.a2dp_link_data->device_id[peer_id], theSink.a2dp_link_data->stream_id[peer_id]);
    }
    
    return FALSE;
}


/*************************************************************************
NAME    
    a2dpIssuePeerStartResponse
    
DESCRIPTION
    Issues a start response to a Peer based on availability of the relay channel

RETURNS
    TRUE if response sent, FALSE otherwise
    
**************************************************************************/
bool a2dpIssuePeerStartResponse (void)
{
    uint16 peer_id;
    
    if (a2dpGetPeerIndex(&peer_id))
    {
        PEER_DEBUG(("issuePeerStartResponse peer=%u\n",peer_id));
        
        if ( peerIsRelayAvailable() )
        {   /* Accept start request */
            return A2dpMediaStartResponse(theSink.a2dp_link_data->device_id[peer_id], theSink.a2dp_link_data->stream_id[peer_id], TRUE);
        }
        else
        {   /* Reject start request as not in a state to receive audio */
            return A2dpMediaStartResponse(theSink.a2dp_link_data->device_id[peer_id], theSink.a2dp_link_data->stream_id[peer_id], FALSE);
        }
    }
    
    return FALSE;
}


/*************************************************************************
NAME    
    a2dpSetPlayingState
    
DESCRIPTION
    Logs the current AVRCP play status for the specified A2DP connection and
    updates the Suspend State for the Media channel so that it reflects the true
    media playing status.

    The Suspend State defines the overall state (suspended or not suspended) of a media stream.  
    It is determined by using a combination of the AVDTP stream state and the AVRCP play status.
    Ultimately, the AVDTP stream state drives the suspend state far more strongly than the AVRCP 
    play status, as the AVDTP stream state tells us if data is actually being transmitted over 
    an A2DP media channel.
    Certainly, when the AVDTP stream state moves from a suspended to a streaming state, then we 
    take that as a definitive indication that streaming has started and the A2DP media stream is 
    not in a suspended state.  In this instance AVRCP play status often lags behind the AVDTP 
    stream state and we can receive actual indications from a Source that the play status is 
    still stopped/paused even though the AVDTP stream state is set to streaming.  This is 
    probably down to latency between layers of the OS and applications on the Source.
    When an AG stops streaming then behaviour is a little different.  Here AVRCP play status will 
    often lead AVDTP stream state by several seconds.  This is the one instance we allow the AVRCP 
    play status to drive the Suspend State.  This is to allow an A2DP source to be marked as 
    suspended and allow far faster automatic changes to another Source (analogue/USB) that may be 
    streaming.
   
RETURNS
    None
    
**************************************************************************/
void a2dpSetPlayingState (uint16 id, bool playing)
{
    if (theSink.a2dp_link_data && theSink.a2dp_link_data->playing[id] != playing)
    {
        theSink.a2dp_link_data->playing[id] = playing;
        
        if (!playing)
        {   /* Play state has changed from playing to not playing.  This change in AVRCP play status is likely to lead a change */
            /* to the AVDTP stream state by several seconds.  Mark the stream as suspended so we can allow automatic changes to */
            /* the relayed source far sooner than waiting for the AVDTP stream state to change.                                 */
            a2dpSetSuspendState(id, a2dp_remote_suspended);
        }
        else
        {   /* Play state has changed from not playing to playing.  In this instance we drive the suspend state directly from   */
            /* the AVDTP stream state                                                                                           */
            a2dp_stream_state a2dp_state = A2dpMediaGetState(theSink.a2dp_link_data->device_id[id], theSink.a2dp_link_data->stream_id[id]);
            
            if ((a2dp_state == a2dp_stream_starting) || (a2dp_state == a2dp_stream_streaming))
            {   /* A2DP media stream is streaming (or heading towards it) */
                a2dpSetSuspendState(id, a2dp_not_suspended);
                
                /*Ensure that the device is not currently streaming from a different A2DP, if its found to be streaming then pause this incoming stream  */
#ifdef ENABLE_AVRCP                
                a2dpPauseNonRoutedSource(id);
#endif
            }
            else
            {
                a2dpSetSuspendState(id, a2dp_remote_suspended);
            }
        }
    }
}


/*************************************************************************
NAME    
    sinkA2dpHandlePeerAvrcpConnectCfm
    
DESCRIPTION
    Configure initial relay availability when a Peer connects

RETURNS
    None
    
**************************************************************************/
void sinkA2dpHandlePeerAvrcpConnectCfm (uint16 peer_id, bool successful)
{
    if (successful)
    {   /* Set initial local status now peers have connected */
        if(theSink.routed_audio)
        {
            audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);
            
            if ((lAudioStatus->sinkAG1 && (lAudioStatus->stateAG1 > hfp_call_state_idle)) || (lAudioStatus->sinkAG2 && (lAudioStatus->stateAG2 > hfp_call_state_idle)))
            {   /* Call is active, so set flag to indicate that this device does not want the relay channel to be used */
                 peerUpdateLocalStatusChange(PEER_STATUS_CHANGE_CALL_ACTIVE | PEER_STATUS_CHANGE_RELAY_AVAILABLE | PEER_STATUS_CHANGE_RELAY_FREED);
            }
            else
            {   /* No call active, set rely channel as free for use */
                peerUpdateLocalStatusChange(PEER_STATUS_CHANGE_CALL_INACTIVE | PEER_STATUS_CHANGE_RELAY_AVAILABLE | PEER_STATUS_CHANGE_RELAY_FREED);
            }

            freePanic(lAudioStatus); 
        }
        else
        {   /* No audio routed, thus relay channel is completely free for use */
             peerUpdateLocalStatusChange(PEER_STATUS_CHANGE_CALL_INACTIVE | PEER_STATUS_CHANGE_RELAY_AVAILABLE | PEER_STATUS_CHANGE_RELAY_FREED);
        }
    }
}


/*************************************************************************
NAME    
    sinkA2dpSetPeerAudioRouting
    
DESCRIPTION
    Informs current Peer of the required routing modes and updates DSP

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool sinkA2dpSetPeerAudioRouting (PeerTwsAudioRouting master_routing_mode, PeerTwsAudioRouting slave_routing_mode)
{
    uint16 peer_id;
    
    if ( a2dpGetPeerIndex(&peer_id) )
    {
#ifdef ENABLE_AVRCP            
        uint16 avrcp_id;
        
        /* does the device support AVRCP and is AVRCP currently connected to this device? */
        for_all_avrcp(avrcp_id)
        {    
            /* ensure media is streaming and the avrcp channel is that requested to be paused */
            if ((theSink.avrcp_link_data->connected[avrcp_id])&& 
                (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[peer_id], &theSink.avrcp_link_data->bd_addr[avrcp_id])))
            {
                uint8 routing_modes[2];
                
                /* Swap routing modes around for other device.  This will mean that the same channels are rendered by both devices no matter which is the actual TWS Master */
                routing_modes[0] = (uint8)slave_routing_mode;
                routing_modes[1] = (uint8)master_routing_mode;
                
                sinkAvrcpVendorUniquePassthroughRequest( avrcp_id, AVRCP_PEER_CMD_TWS_AUDIO_ROUTING, sizeof(routing_modes), (const uint8 *)routing_modes );
                break;
            }
        }
#endif
        peerHandleAudioRoutingCmd( master_routing_mode, slave_routing_mode );
        
        return TRUE;
    }
    
    return FALSE;
}

#ifdef PEER_TWS
/****************************************************************************
NAME 
 a2dpCheckDeviceTrimVol

DESCRIPTION
 check whether any a2dp connections are present and if these are currently active
 and routing audio to the device, if that is the case adjust the volume up or down
 as appropriate

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
bool a2dpCheckDeviceTrimVol (volume_direction dir, tws_device_type tws_device)
{
    uint8 index;
    
    if (tws_device != tws_none)
    {
        /* check both possible instances of a2dp connection */
        for(index = a2dp_primary; index < (a2dp_secondary+1); index++)
        {
            /* is a2dp connected? */
            if(theSink.a2dp_link_data->connected[index])
            {
                /* check whether the a2dp connection is present and streaming data and that the audio is routed */
                if(theSink.routed_audio && (theSink.routed_audio == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index])))
                {
#ifdef ENABLE_AVRCP
                    if ((theSink.a2dp_link_data->peer_device[index] == remote_device_peer) && (theSink.a2dp_link_data->peer_features[index] & remote_features_tws_a2dp_source))
                    {
                        peerSendDeviceTrimVolume(index , dir , tws_device) ;                        
                    }
                    else
#endif
                    {
                        VolumeUpdateDeviceTrim(dir , tws_device);
            
                        /* Apply device trim */
                        VolumeSetA2dp(index, theSink.volume_levels->a2dp_volume[index].masterVolume, TRUE);
            
                        return TRUE;
                    }
                }
            }
        }
    }    
    return FALSE;
}
#endif

#endif  /* ENABLE_PEER */

/*************************************************************************
NAME    
    a2dpSetSuspendState
    
DESCRIPTION
    Sets the suspend state for the specified device

RETURNS
    None
    
**************************************************************************/
void a2dpSetSuspendState (uint16 id, uint16 state)
{
    if (state == a2dp_not_suspended)
    {   /* Returning to the unsuspended state */
        theSink.a2dp_link_data->SuspendState[id] = state;
    }
    else
    {   /* Check if we are already suspended before updating state */
        if (theSink.a2dp_link_data->SuspendState[id] == a2dp_not_suspended)
        {
            theSink.a2dp_link_data->SuspendState[id] = state;
        }
    }
    A2DP_DEBUG(("A2dp: SuspendState[%u] = %d\n",id,theSink.a2dp_link_data->SuspendState[id])); 
}

#ifdef ENABLE_AVRCP
/*************************************************************************
NAME    
    a2dpPauseNonRoutedSource
    
DESCRIPTION
    Check whether the a2dp connection is present and streaming data and that the audio is routed, 
    if thats true then pause/stop the incoming stream corresponding to the input deviceId.

RETURNS
    None
    
**************************************************************************/
void a2dpPauseNonRoutedSource(uint16 id)
{
    a2dp_link_priority  priority;  
    uint16 avrcpIndex;
#ifdef ENABLE_PEER     
    uint16 peerIndex;
#endif
    
    if(theSink.a2dp_link_data->SuspendState[id] == a2dp_not_suspended)
    {
        /* check whether the a2dp connection is present and streaming data and that the audio is routed, if thats true then pause the other incoming stream */
        if((theSink.a2dp_link_data->peer_device[id] == remote_device_nonpeer) && sinkAvrcpGetIndexFromBdaddr(&theSink.a2dp_link_data->bd_addr[id], &avrcpIndex, TRUE))
        {
            if( (theSink.routed_audio && findCurrentA2dpSource(&priority) && (A2dpMediaGetState(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]) == a2dp_stream_streaming) && (id != priority))
#ifdef ENABLE_PEER 
                ||(a2dpGetPeerIndex(&peerIndex) && theSink.features.TwsSingleDeviceOperation  && (theSink.a2dp_link_data->remote_peer_status[peerIndex] & PEER_STATUS_IN_CALL))
                || (!peerCheckSource(RELAY_SOURCE_A2DP))
#endif
                )
            {                
                A2DP_DEBUG(("A2dp: SuspendState - Stop playing Id = %d \n",id));
                /* cancel any queued ff or rw requests and then stop the streaming*/
                MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
                MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
                sinkAvrcpStopRequest(avrcpIndex);

                a2dpSetSuspendState(id , a2dp_local_suspended);
            }
        }
    }
}
#endif

/*************************************************************************
NAME    
    InitA2dp
    
DESCRIPTION
    This function initialises the A2DP library and supported codecs

RETURNS
    A2DP_INIT_CFM message returned, handled by A2DP message handler
**************************************************************************/
void InitA2dp(void)
{
    uint16 i;

    sep_data_type seps[NUM_SEPS];
    uint16 number_of_seps = 0;
    pio_config_type* pio;

    A2DP_DEBUG(("INIT: A2DP\n")); 
    A2DP_DEBUG(("INIT: NUM_SEPS=%u\n",NUM_SEPS)); 

  	/*allocate the memory for the a2dp link data */
#ifdef ENABLE_AVRCP
    theSink.a2dp_link_data = mallocPanic( sizeof(a2dp_data) + sizeof(avrcp_data) );
        /* initialise structure to 0 */    
    memset(theSink.a2dp_link_data, 0, ( sizeof(a2dp_data)  + sizeof(avrcp_data) ));  
#else    
	theSink.a2dp_link_data = mallocPanic( sizeof(a2dp_data));
    /* initialise structure to 0 */    
    memset(theSink.a2dp_link_data, 0, ( sizeof(a2dp_data)));      
#endif

    
    /* Make sure all references to mic parameters point to the right place */
    pio = &theSink.conf1->PIOIO;
    theSink.a2dp_link_data->a2dp_audio_connect_params.mic_params = &pio->digital;
    
    /* set default microphone source for back channel enabled dsp apps */
    theSink.a2dp_link_data->a2dp_audio_mode_params.external_mic_settings = EXTERNAL_MIC_NOT_FITTED;
    theSink.a2dp_link_data->a2dp_audio_mode_params.mic_mute = SEND_PATH_UNMUTE;
    
    /* Set default TWS audio routing modes */
    theSink.a2dp_link_data->a2dp_audio_mode_params.master_routing_mode = theSink.features.TwsMasterAudioRouting;
    theSink.a2dp_link_data->a2dp_audio_mode_params.slave_routing_mode = theSink.features.TwsSlaveAudioRouting;

    /* initialise device and stream id's to invalid as 0 is a valid value */
    theSink.a2dp_link_data->device_id[0] = INVALID_DEVICE_ID;
    theSink.a2dp_link_data->stream_id[0] = INVALID_STREAM_ID;   
    theSink.a2dp_link_data->device_id[1] = INVALID_DEVICE_ID;
    theSink.a2dp_link_data->stream_id[1] = INVALID_STREAM_ID;   

#ifdef ENABLE_SOUNDBAR
    theSink.a2dp_link_data->a2dp_audio_connect_params.silence_threshold = theSink.conf2->audio_routing_data.SilenceDetSettings.threshold;
    theSink.a2dp_link_data->a2dp_audio_connect_params.silence_trigger_time = theSink.conf2->audio_routing_data.SilenceDetSettings.trigger_time;
            
    theSink.a2dp_link_data->a2dp_audio_connect_params.is_for_soundbar = TRUE; 
    theSink.a2dp_link_data->a2dp_audio_connect_params.speaker_pio = theSink.conf1->PIOIO.pio_outputs.DeviceAudioActivePIO ;
#endif/*ENABLE_SOUNDBAR*/
    
    /* only continue and initialise the A2DP library if it's actually required,
       library functions will return false if it is uninitialised */
    if(theSink.features.EnableA2dpStreaming)
    {
        /* Currently, we just support MP3 as optional codec so it is enabled in features block
        If more optional codecs are supported, we need use seperate PSKEY to enable codec ! */	        
        for (i=0; i<NUM_SEPS; i++)
        {
#ifdef ENABLE_PEER
            bool include_sep = TRUE;
            
            /* Filter TWS source/sink SEPs and ShareMe source SEPs based on configuration */
            if (codecList[i].config && (codecList[i].config->seid & TWS_SEID_MASK))
            {   /* SEID indicates a TWS SEP */
                if (((codecList[i].config->seid & SOURCE_SEID_MASK) && !theSink.features.TwsSource) ||
                    (!(codecList[i].config->seid & SOURCE_SEID_MASK) && !theSink.features.TwsSink))
                {   /* Prevent TWS source or sink SEPs from being registered with the A2DP library if feature bits */
                    /* indicate no support for them.                                                               */
                    include_sep = FALSE;
                    
                    A2DP_DEBUG(("INIT: Codec removed (seid=0x%X)\n",codecList[i].config->seid));
                }
            }
            else
            {   /* SEID indicates a non-TWS SEP */
                if (((codecList[i].config->seid & SOURCE_SEID_MASK) && !theSink.features.ShareMeSource) &&
                    ((codecList[i].config->seid != SBC_SEID) || ((codecList[i].config->seid == SBC_SEID) && !theSink.features.TwsSource))) 
                {   /* Prevent ShareMe source SEPs from being registered with the A2DP library if feature bit */
                    /* indicates no support for them.                                                         */
                    /* SBC source SEP is always registered if we support any form of source role.             */
                    include_sep = FALSE;
                    
                    A2DP_DEBUG(("INIT: Codec removed (seid=0x%X)\n",codecList[i].config->seid));
                }
            }
            
            if (include_sep)
#endif
            {
                if (codecList[i].bit==SBC_CODEC_BIT || (theSink.features.A2dpOptionalCodecsEnabled & (1<<codecList[i].bit)))
                {
                    seps[number_of_seps].sep_config = codecList[i].config;
                    seps[number_of_seps].in_use = FALSE;
                    number_of_seps++;
                    
                    A2DP_DEBUG(("INIT: Codec included (seid=0x%X)\n",codecList[i].config->seid));
                }
            }
        }
        
        /* Initialise the A2DP library */
#ifdef ENABLE_PEER
        if (theSink.features.ShareMeSource || theSink.features.TwsSource)
        {   /* We support some form of source role, so ensure A2DP library advertises A2DP Source SDP record */
            A2dpInit(&theSink.task, A2DP_INIT_ROLE_SINK | A2DP_INIT_ROLE_SOURCE, NULL, number_of_seps, seps, theSink.conf1->timeouts.A2dpLinkLossReconnectionTime_s);
        }
        else
#endif
        {
            A2dpInit(&theSink.task, A2DP_INIT_ROLE_SINK, NULL, number_of_seps, seps, theSink.conf1->timeouts.A2dpLinkLossReconnectionTime_s);
        }
    }
}

/*************************************************************************
NAME    
    getA2dpIndex
    
DESCRIPTION
    This function tries to find a device id match in the array of a2dp links 
    to that device id passed in

RETURNS
    match status of true or false
**************************************************************************/
bool getA2dpIndex(uint16 DeviceId, uint16 * Index)
{
    uint8 i;
    
    /* go through A2dp connection looking for device_id match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its device id */
        if(theSink.a2dp_link_data->connected[i])
        {
            /* if a device_id match is found return its value and a
               status of successful match found */
            if(theSink.a2dp_link_data->device_id[i] == DeviceId)
            {
                *Index = i;
            	A2DP_DEBUG(("A2dp: getIndex = %d\n",i)); 
                return TRUE;
            }
        }
    }
    /* no matches found so return not successful */    
    return FALSE;
}

/*************************************************************************
NAME    
    getA2dpIndexFromPlugin
    
DESCRIPTION
    This function tries to find an A2dp instance based on the supplied active 
	audio plugin 

RETURNS
    match status of true or false
**************************************************************************/
bool getA2dpIndexFromPlugin(Task audio_plugin, uint16 *Index)
{
    uint8 i;
    
    if (!audio_plugin || !theSink.a2dp_link_data)
    {
        return FALSE;
    }
    
    /* go through A2dp connection looking for sink match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its device id */
        if(theSink.a2dp_link_data->connected[i])
        {
			if (theSink.a2dp_link_data->seid[i] && (getA2dpPlugin(theSink.a2dp_link_data->seid[i]) == audio_plugin))
			{
				*Index = i;
				return TRUE;
			}
        }
    }
    
    /* no matches found so return not successful */    
    return FALSE;
}


/*************************************************************************
NAME    
    getA2dpIndexFromSink
    
DESCRIPTION
    This function tries to find the a2dp device associated with the supplied 
    sink.  The supplied sink can be either a signalling or media channel.

RETURNS
    match status of true or false
**************************************************************************/
bool getA2dpIndexFromSink(Sink sink, uint16 * Index)
{
    uint8 i;
    
    if (!sink || !theSink.a2dp_link_data)
    {
        return FALSE;
    }
    
    /* go through A2dp connection looking for sink match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its device id */
        if(theSink.a2dp_link_data->connected[i])
        {
            /* if a device_id match is found return its value and a
               status of successful match found */
            if(A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[i]) == sink)
            {
                *Index = i;
                return TRUE;
            }
            
            if(A2dpMediaGetSink(theSink.a2dp_link_data->device_id[i], theSink.a2dp_link_data->stream_id[i]) == sink)
            {
                *Index = i;
                return TRUE;
            }
        }
    }
    
    /* no matches found so return not successful */    
    return FALSE;
}

/*************************************************************************
NAME    
    getA2dpStreamData
    
DESCRIPTION
    Function to retreive media sink and state for a given A2DP source

RETURNS
    void
**************************************************************************/
void getA2dpStreamData(a2dp_link_priority priority, Sink* sink, a2dp_stream_state* state)
{
    *state = a2dp_stream_idle;
    *sink  = NULL;

/*   	A2DP_DEBUG(("A2dp: getA2dpStreamData(%u)\n",(uint16)priority)); */
    if(theSink.a2dp_link_data)
    {
/*        A2DP_DEBUG(("A2dp: getA2dpStreamData - peer=%u connected=%u\n",theSink.a2dp_link_data->peer_device[priority],theSink.a2dp_link_data->connected[priority])); */
        if(theSink.a2dp_link_data->connected[priority])
        {
            *state = A2dpMediaGetState(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]) ;
            *sink  = A2dpMediaGetSink(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]) ;
/*            A2DP_DEBUG(("A2dp: getA2dpStreamData - state=%u sink=0x%X\n",*state, (uint16)*sink)); */
        }
    }
}

/*************************************************************************
NAME    
    getA2dpStreamRole
    
DESCRIPTION
    Function to retrieve the role (source/sink) for a given A2DP source

RETURNS
    void
**************************************************************************/
void getA2dpStreamRole(a2dp_link_priority priority, a2dp_role_type* role)
{
    *role = a2dp_role_undefined;
    
    if(theSink.a2dp_link_data)
    {
/*        A2DP_DEBUG(("A2dp: getA2dpStreamRole - peer=%u connected=%u\n",theSink.a2dp_link_data->peer_device[priority],theSink.a2dp_link_data->connected[priority])); */
        if(theSink.a2dp_link_data->connected[priority])
        {
            *role = A2dpMediaGetRole(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]) ;
/*            A2DP_DEBUG(("A2dp: getA2dpStreamRole - role=%u priority=%u\n",*role,priority)); */
        }
    }
}

/*************************************************************************
NAME    
    getA2dpPlugin
    
DESCRIPTION
    This function returns the task of the appropriate audio plugin to be used
    for the selected codec type when connecting audio

RETURNS
    task of relevant audio plugin
**************************************************************************/
Task getA2dpPlugin(uint8 seid)
{
    uint16 i;
    
    for (i=0; i<NUM_SEPS; i++)
    {
        if (codecList[i].config && (codecList[i].config->seid == seid))
        {
            return codecList[i].plugin;
        }
    }
    
	/* No plugin found so Panic */
	Panic();
	return 0;
}


/*************************************************************************
NAME    
    openStream
    
DESCRIPTION
    

RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
static bool openStream (uint16 Id, uint8 seid)
{
	if ((seid & SOURCE_SEID_MASK) == 0)
	{	/* Ensure a source SEID has not been requested */
		if (seid)
		{	/* Request to use the specified seid only */
			/*return A2dpMediaOpenRequestEx(theSink.a2dp_link_data->device_id[Id], 1, &seid, sizeof(a2dp_media_conftab), a2dp_media_conftab);*/
			return A2dpMediaOpenRequest(theSink.a2dp_link_data->device_id[Id], 1, &seid);
		}
		else
		{	/* Use default seid list, as specified in call to A2dpInit() */
			/*return A2dpMediaOpenRequestEx(theSink.a2dp_link_data->device_id[Id], 0, NULL, sizeof(a2dp_media_conftab), a2dp_media_conftab);*/
			return A2dpMediaOpenRequest(theSink.a2dp_link_data->device_id[Id], 0, NULL);
		}
	}
    
    return FALSE;
}


/****************************************************************************
NAME    
    sinkA2dpSetLinkRole
    
DESCRIPTION
    Updates stored BT role for specified device

RETURNS
    None
    
**************************************************************************/
void sinkA2dpSetLinkRole (Sink sink, hci_role role)
{
    uint16 index;

    A2DP_DEBUG(("sinkA2dpSetLinkRole  sink=0x%X  role=%s\n", (uint16)sink, (role == hci_role_master) ? "master" : "slave"));

    if (getA2dpIndexFromSink(sink, &index))
    {
#ifdef ENABLE_PEER
        a2dp_link_role last_role = theSink.a2dp_link_data->link_role[index];
#endif
        
        if (role == hci_role_master)
        {
            A2DP_DEBUG(("    setting  link_role[%u] = LR_CURRENT_ROLE_MASTER\n",index));
            theSink.a2dp_link_data->link_role[index] = LR_CURRENT_ROLE_MASTER;
        }
        else
        {
            A2DP_DEBUG(("    setting  link_role[%u] = LR_CURRENT_ROLE_SLAVE\n",index));
            theSink.a2dp_link_data->link_role[index] = LR_CURRENT_ROLE_SLAVE;
        }
        
#ifdef ENABLE_PEER
        if (last_role == LR_CHECK_ROLE_PENDING_START_REQ)
        {
            A2DP_DEBUG(("    start was pending...\n"));
            a2dpIssuePeerStartRequest();
        }
#endif
    }
}

/****************************************************************************
NAME    
    sinkA2dpInitComplete
    
DESCRIPTION
    Sink A2DP initialisation has completed, check for success. 

RETURNS
    void
**************************************************************************/
void sinkA2dpInitComplete(const A2DP_INIT_CFM_T *msg)
{   
    /* check for successful initialisation of A2DP libraray */
    if(msg->status == a2dp_success)
    {
        A2DP_DEBUG(("A2DP Init Success\n"));
    }
    else
    {
	    A2DP_DEBUG(("A2DP Init Failed [Status %d]\n", msg->status));
        Panic();
    }
}


/****************************************************************************
NAME    
    issueA2dpSignallingConnectResponse
    
DESCRIPTION
    Issue response to a signalling channel connect request, following discovery of the 
    remote device type. 

RETURNS
    void
**************************************************************************/
void issueA2dpSignallingConnectResponse(const bdaddr *bd_addr)
{
    A2DP_DEBUG(("issueA2dpSignallingConnectResponse\n"));
    
    if (theSink.a2dp_link_data)
    {
        uint16 idx;
        
        for_all_a2dp(idx)
        {
            if (!theSink.a2dp_link_data->connected[idx] && BdaddrIsSame(bd_addr, &theSink.a2dp_link_data->bd_addr[idx]))
            {
#ifdef ENABLE_PEER
                sink_attributes attributes;
                
                A2DP_DEBUG(("   peer = %u   features = %u\n",theSink.a2dp_link_data->peer_device[idx],theSink.a2dp_link_data->peer_features[idx]));
      
                deviceManagerGetDefaultAttributes(&attributes, FALSE);
                deviceManagerGetAttributes(&attributes, bd_addr);
                attributes.peer_device = theSink.a2dp_link_data->peer_device[idx];
                attributes.peer_features = theSink.a2dp_link_data->peer_features[idx];
                deviceManagerStoreAttributes(&attributes, bd_addr);
#endif

                A2DP_DEBUG(("Accept\n"));
                A2dpSignallingConnectResponse(theSink.a2dp_link_data->device_id[idx],TRUE);
                
#ifdef ENABLE_AVRCP
                sinkAvrcpCheckManualConnectReset((bdaddr *)bd_addr);        
#endif                
            }
        }
    }
}


/*************************************************************************
NAME    
    handleA2DPSignallingConnectInd
    
DESCRIPTION
    handle a signalling channel connect indication

RETURNS
    
**************************************************************************/
void handleA2DPSignallingConnectInd(uint16 DeviceId, bdaddr SrcAddr)
{
#ifdef ENABLE_PEER
    sink_attributes attributes;
#endif

    /* indicate that this is a remote connection */
    theSink.a2dp_link_data->remote_connection = TRUE;   
    
    /* before accepting check there isn't already a signalling channel connected to another AG */		
    if ( (theSink.features.EnableA2dpStreaming) &&
         ((!theSink.a2dp_link_data->connected[a2dp_primary]) || (!theSink.a2dp_link_data->connected[a2dp_secondary])) )
    {
        /* store the device_id for the new connection in the first available storage position */
        uint16 priority = (!theSink.a2dp_link_data->connected[a2dp_primary]) ? a2dp_primary : a2dp_secondary;
        
        A2DP_DEBUG(("Signalling Success, Device ID = %x\n",DeviceId));
        theSink.a2dp_link_data->connected[priority] = FALSE;
        theSink.a2dp_link_data->device_id[priority] = DeviceId;
        theSink.a2dp_link_data->bd_addr[priority] = SrcAddr;
        theSink.a2dp_link_data->list_id[priority] = 0;  
        
#ifdef ENABLE_PEER
        /* Check if the bd address of the connected Ag is the same as that connected to the peer,
            if so then disconnect the ag  */
        if(BdaddrIsSame(&theSink.remote_peer_ag_bd_addr , &SrcAddr))
        {
            A2DP_DEBUG(("Reject\n"));
            A2dpSignallingConnectResponse(DeviceId,FALSE);
            sinkDisconnectAllSlc();            
            return;
        }
    
        /* Get any known peer device attributes */
        deviceManagerGetDefaultAttributes(&attributes, FALSE);
        deviceManagerGetAttributes(&attributes, &SrcAddr);
        theSink.a2dp_link_data->peer_device[priority] = attributes.peer_device;
        theSink.a2dp_link_data->peer_features[priority] = attributes.peer_features;

        if (theSink.a2dp_link_data->peer_device[priority] == remote_device_unknown)
        {   /* Determine remote device type before accepting connection */
            if (theSink.features.PeerUseDeviceId)
            {
                A2DP_DEBUG(("Unknown device type - requesting device id record\n"));
                RequestRemoteDeviceId(&SrcAddr);
            }
            else
            {
                A2DP_DEBUG(("Unknown device type - requesting Peer Device service record\n"));
                if (!RequestRemotePeerServiceRecord(&SrcAddr))
                {   /* SDP record not requested */
                    if (theSink.inquiry.session == inquiry_session_peer)
                    {   /* We are initiating a Peer session */
                        A2DP_DEBUG(("Peer Device SDP record not requested, assuming Peer\n"));
                        
                        /* Assume device is a ShareMe sink without custom avrcp operation and allow to connect */
                        attributes.peer_device = remote_device_peer;
                        attributes.peer_features = remote_features_shareme_a2dp_sink;
                        deviceManagerStoreAttributes(&attributes, &SrcAddr);
                    }
                    else
                    {
                        /* Assume device is a standard source */
                        attributes.peer_device = remote_device_nonpeer;
                        attributes.peer_features = 0;
                        deviceManagerStoreAttributes(&attributes, &SrcAddr);
                    }
                    
                    A2DP_DEBUG(("Accept\n"));
                    A2dpSignallingConnectResponse(DeviceId,TRUE);
#ifdef ENABLE_AVRCP
                    sinkAvrcpCheckManualConnectReset(&SrcAddr);        
#endif                
                }
            }
        }
        else
#endif
        {   /* Accept the connection */
            A2DP_DEBUG(("Accept\n"));
            A2dpSignallingConnectResponse(DeviceId,TRUE);
#ifdef ENABLE_AVRCP
            sinkAvrcpCheckManualConnectReset(&SrcAddr);        
#endif                
        }
    }
    else
    {
        A2DP_DEBUG(("Reject\n"));
        A2dpSignallingConnectResponse(DeviceId,FALSE);
    }
}


/*************************************************************************
NAME    
    handleA2DPSignallingConnected
    
DESCRIPTION
    handle a successful confirm of a signalling channel connected

RETURNS
    
**************************************************************************/
void handleA2DPSignallingConnected(a2dp_status_code status, uint16 DeviceId, bdaddr SrcAddr, bool locally_initiated)
{
    /* Continue connection procedure */
    if(!theSink.a2dp_link_data->remote_connection)    
    {
        MessageSendLater(&theSink.task,EventSysContinueSlcConnectRequest,0,theSink.conf1->timeouts.SecondAGConnectDelayTime_s);
    }
    else
    {
        /* reset remote connection indication flag */    
        theSink.a2dp_link_data->remote_connection = FALSE;
    }
            
    /* check for successful connection */
    if (status != a2dp_success)
    {
        uint16 priority;
        
        A2DP_DEBUG(("Signalling Failed device=%u [Status %d]\n", DeviceId, status));
        
        /* If necessary, clear appropriate link data structure which will have been filled on an incoming connection */
        if ((status != a2dp_wrong_state) && (status != a2dp_max_connections))   /* TODO: Temp fix */
        if ( BdaddrIsSame(&SrcAddr,&theSink.a2dp_link_data->bd_addr[priority=a2dp_primary]) || 
             BdaddrIsSame(&SrcAddr,&theSink.a2dp_link_data->bd_addr[priority=a2dp_secondary]) )
        {
            A2DP_DEBUG(("Clearing link data for %u\n", priority));
            theSink.a2dp_link_data->peer_device[priority] = remote_device_unknown;
            theSink.a2dp_link_data->peer_features[priority] = 0;
            theSink.a2dp_link_data->local_peer_status[priority] = 0;
            theSink.a2dp_link_data->remote_peer_status[priority] = 0;
            theSink.a2dp_link_data->connected[priority] = FALSE;
            theSink.a2dp_link_data->device_id[priority] = INVALID_DEVICE_ID;
            BdaddrSetZero(&theSink.a2dp_link_data->bd_addr[priority]);
            theSink.a2dp_link_data->list_id[priority] = 0;
            theSink.a2dp_link_data->av_source[priority] = RELAY_SOURCE_NULL;
            theSink.a2dp_link_data->link_role[priority] = LR_UNKNOWN_ROLE;
        }
        
#ifdef ENABLE_AVRCP
        sinkAvrcpCheckManualConnectReset(&SrcAddr);        
#endif

        /* if a failed inquiry connect then restart it */
        if((theSink.inquiry.action == rssi_pairing)&&(theSink.inquiry.session == inquiry_session_peer))        
        {
            inquiryStop();
            inquiryPair( inquiry_session_peer, FALSE );
        }
    }
    /* connection was successful */
    else
    {
        /* Send a message to request a role indication and make necessary changes as appropriate, message
           will be delayed if a device initiated connection to another device is still in progress */
        A2DP_DEBUG(("handleA2DPSignallingConnected: Asking for role check\n"));
        
        /* cancel any link loss reminders */        
        MessageCancelAll(&theSink.task , EventSysLinkLoss );
        
        /* cancel any pending messages and replace with a new one */
        MessageCancelFirst(&theSink.task , EventSysCheckRole);    
        MessageSendConditionally (&theSink.task , EventSysCheckRole , NULL , &theSink.rundata->connection_in_progress  );
    
        /* check for a link loss condition, if the device has suffered a link loss and was
           succesfully reconnected by the a2dp library a 'signalling connected' event will be 
           generated, check for this and retain previous connected ID for this indication */
        if(((theSink.a2dp_link_data->connected[a2dp_primary])&&(BdaddrIsSame(&SrcAddr, &theSink.a2dp_link_data->bd_addr[a2dp_primary])))||
           ((theSink.a2dp_link_data->connected[a2dp_secondary])&&(BdaddrIsSame(&SrcAddr, &theSink.a2dp_link_data->bd_addr[a2dp_secondary]))))
        {
            /* reconnection is the result of a link loss, don't assign a new id */    		
            A2DP_DEBUG(("Signalling Connected following link loss [Status %d]\n", status));
        }
        else
        {
            /* store the device_id for the new connection in the first available storage position */
            if (BdaddrIsSame(&SrcAddr,&theSink.a2dp_link_data->bd_addr[a2dp_primary]) || 
                (BdaddrIsZero(&theSink.a2dp_link_data->bd_addr[a2dp_primary]) && !theSink.a2dp_link_data->connected[a2dp_primary]))
            {
            	A2DP_DEBUG(("Signalling Success, Primary ID = %x\n",DeviceId));
                theSink.a2dp_link_data->connected[a2dp_primary] = TRUE;
                theSink.a2dp_link_data->device_id[a2dp_primary] = DeviceId;
                theSink.a2dp_link_data->bd_addr[a2dp_primary] = SrcAddr;            
                theSink.a2dp_link_data->list_id[a2dp_primary] = deviceManagerSetPriority(&SrcAddr);
                theSink.a2dp_link_data->media_reconnect[a2dp_primary] = FALSE;
                theSink.a2dp_link_data->latency[a2dp_primary] = 0;
                theSink.a2dp_link_data->av_source[a2dp_primary] = RELAY_SOURCE_NULL;
                theSink.a2dp_link_data->local_peer_status[a2dp_primary] = 0;
                theSink.a2dp_link_data->remote_peer_status[a2dp_primary] = 0;
                theSink.a2dp_link_data->peer_features[a2dp_primary] = 0;
                theSink.a2dp_link_data->link_role[a2dp_primary] = LR_UNKNOWN_ROLE;
                theSink.a2dp_link_data->playing[a2dp_primary] = FALSE;
            }
            /* this is the second A2DP signalling connection */
            else if (BdaddrIsSame(&SrcAddr,&theSink.a2dp_link_data->bd_addr[a2dp_secondary]) || 
                     (BdaddrIsZero(&theSink.a2dp_link_data->bd_addr[a2dp_secondary]) && !theSink.a2dp_link_data->connected[a2dp_secondary]))
            {
            	A2DP_DEBUG(("Signalling Success, Secondary ID = %x\n",DeviceId));
                theSink.a2dp_link_data->connected[a2dp_secondary] = TRUE;
                theSink.a2dp_link_data->device_id[a2dp_secondary] = DeviceId;
                theSink.a2dp_link_data->bd_addr[a2dp_secondary] = SrcAddr;            
                theSink.a2dp_link_data->list_id[a2dp_secondary] = deviceManagerSetPriority(&SrcAddr);
                theSink.a2dp_link_data->media_reconnect[a2dp_secondary] = FALSE;
                theSink.a2dp_link_data->latency[a2dp_secondary] = 0;
                theSink.a2dp_link_data->av_source[a2dp_secondary] = RELAY_SOURCE_NULL;
                theSink.a2dp_link_data->local_peer_status[a2dp_secondary] = 0;
                theSink.a2dp_link_data->remote_peer_status[a2dp_secondary] = 0;
                theSink.a2dp_link_data->peer_features[a2dp_secondary] = 0;
                theSink.a2dp_link_data->link_role[a2dp_secondary] = LR_UNKNOWN_ROLE;
                theSink.a2dp_link_data->playing[a2dp_secondary] = FALSE;
            }
        }
        
  	 /* Ensure the underlying ACL is encrypted */       
        ConnectionSmEncrypt( &theSink.task , A2dpSignallingGetSink(DeviceId) , TRUE );
        ConnectionSetLinkSupervisionTimeout(A2dpSignallingGetSink(DeviceId), SINK_LINK_SUPERVISION_TIMEOUT);
	
	/* If the device is off then disconnect */
	if (stateManagerGetState() == deviceLimbo)
	{
            A2dpSignallingDisconnectRequest(DeviceId);
	}        
	else
	{
            a2dp_link_priority priority;
            sink_attributes attributes;
            
            /* Use default attributes if none exist is PS */
            deviceManagerGetDefaultAttributes(&attributes, FALSE);
            deviceManagerGetAttributes(&attributes, &SrcAddr);
                
            /* For a2dp connected Tone only */
            MessageSend(&theSink.task,  EventSysA2dpConnected, 0);	
					
            /* find structure index of deviceId */
            if(getA2dpIndex(DeviceId, (uint16*)&priority))
            {
#ifdef ENABLE_PARTYMODE
                /* check whether party mode is enabled */
                if((theSink.PartyModeEnabled)&&(theSink.features.PartyMode))
                {
                    /* start a timer when a device connects in party mode, if no music is played before the timeout
                       occurs the device will get disconnected to allow other devices to connect, currently set to 
                       2 minutes */
                    MessageSendLater(&theSink.task,(EventSysPartyModeTimeoutDevice1 + priority),0,PARTYMODE_MUSIC_TIMEOUT);                 
                    /* set paused flag */
                    if(priority == a2dp_primary)
                    {
                        theSink.rundata->partymode_pause.audio_source_primary_paused = FALSE;
                    }
                    else
                    {
                        theSink.rundata->partymode_pause.audio_source_secondary_paused = FALSE;
                    }
                }
#endif                        
                /* update master volume level */
                theSink.volume_levels->a2dp_volume[priority].masterVolume = attributes.a2dp.volume;
                theSink.a2dp_link_data->clockMismatchRate[priority] = attributes.a2dp.clock_mismatch;
                
#ifdef ENABLE_PEER
                if ((slcDetermineConnectAction() & AR_Rssi) && theSink.inquiry.results)
                {   /* Set attributes when connecting from a Peer Inquiry */
                    attributes.peer_device = theSink.inquiry.results[theSink.inquiry.attempting].peer_device;
                    
                    if (attributes.peer_device == remote_device_peer)
                    {
                        attributes.peer_features = theSink.inquiry.results[theSink.inquiry.attempting].peer_features;
                    }
                }
                
                if (attributes.peer_device != remote_device_unknown)
                {   /* Only update link data if device type is already known to us */
                    theSink.a2dp_link_data->peer_device[priority] = attributes.peer_device;
                    theSink.a2dp_link_data->peer_features[priority] = attributes.peer_features;
                }
                
            	A2DP_DEBUG(("Remote device type = %u\n",theSink.a2dp_link_data->peer_device[priority]));
            	A2DP_DEBUG(("Remote device features = 0x%x\n",theSink.a2dp_link_data->peer_features[priority]));
#endif

                /* We are now connected */      
                if (stateManagerGetState() < deviceConnected && stateManagerGetState() != deviceLimbo)
                {
#ifdef ENABLE_PEER                    
                    if (stateManagerGetState() == deviceConnDiscoverable && attributes.peer_device == remote_device_peer)
                    {
                        stateManagerEnterConnDiscoverableState(TRUE);
                    }
                    else
#endif                        
                    {
                        stateManagerEnterConnectedState(); 	
                    }
                }

                /* Make sure we store this device */
                attributes.profiles |= sink_a2dp;
                deviceManagerStoreAttributes(&attributes, &SrcAddr);
                
                /* Enable A2dp link loss management if remote device does not have HFP connected */
                updateA2dpLinkLossManagement(priority);
                
                /* check on signalling check indication if the a2dp was previously in a suspended state,
                   this can happen if the device has suspended a stream and the phone has chosen to drop
                   the signalling channel completely, open the media connection or the feature to open a media
                   channel on signalling connected option is enabled */
#ifdef ENABLE_PEER
                if (theSink.a2dp_link_data->peer_device[priority] != remote_device_peer)
#endif
                {   /* Unknown or non-peer device */
#ifdef ENABLE_PEER

                    /* Check if the bd address of the connected Ag is the same as that connected to the peer,
                         if so then disconnect the ag  */
                    if(BdaddrIsSame(&theSink.remote_peer_ag_bd_addr , &SrcAddr))
                    {
                        A2dpSignallingDisconnectRequest(DeviceId);
                        sinkDisconnectAllSlc();
                    }
                    
                    /*If the A2DP has connected successfully to a non-peer device then notify this to the peer device */
                    {
                        audio_src_conn_state_t  audioSrcStatus;
                        audioSrcStatus.src = A2DP_AUDIO;
                        audioSrcStatus.isConnected = TRUE;

                        /*Convert the BD Addess from the type bdaddr to byte_aligned_bd_addr_t for sending it the peer device 
                            through the vendor unique AVRCP passthrough command*/
                        audioSrcStatus.bd_addr.lap[0] = SrcAddr.lap & 0xFF;
                        audioSrcStatus.bd_addr.lap[1] = (SrcAddr.lap >>8)  & 0xFF;
                        audioSrcStatus.bd_addr.lap[2] = (SrcAddr.lap >>16) & 0xFF;
                        audioSrcStatus.bd_addr.uap = SrcAddr.uap;
                        audioSrcStatus.bd_addr.nap[0] = SrcAddr.nap & 0xFF;
                        audioSrcStatus.bd_addr.nap[1] = (SrcAddr.nap >> 8) & 0xFF ;
                        
                        updatePeerAudioConnStatus(audioSrcStatus);
                    }
                    
                    PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE CONNECTED");
#endif
                    if ((theSink.a2dp_link_data->SuspendState[priority] == a2dp_local_suspended) ||
                        (theSink.features.EnableA2dpMediaOpenOnConnection))
                    {
                        connectA2dpStream( priority, D_SEC(5) );
                    }
                }
#ifdef ENABLE_PEER
                else
                {   /* Peer device */
                    if (!(theSink.a2dp_link_data->peer_features[priority] & (remote_features_tws_a2dp_sink | remote_features_tws_a2dp_source)))
                    {   /* Peer does not support TWS, which would have priority over ShareMe */
                        uint16 av_id;
                        
                        /* Mark AAC as unavailable whilst in a ShareMe session */
                        A2dpCodecSetAvailable(a2dp_primary, AAC_SEID, FALSE);
                        A2dpCodecSetAvailable(a2dp_secondary, AAC_SEID, FALSE);
                        
                        /* Close any media stream to AV Source if it's using AAC */
                        if (a2dpGetSourceIndex(&av_id) && theSink.a2dp_link_data->seid[av_id]==AAC_SEID)
                        {
                            theSink.a2dp_link_data->media_reconnect[av_id] = TRUE;
                            A2dpMediaCloseRequest(theSink.a2dp_link_data->device_id[av_id], theSink.a2dp_link_data->stream_id[av_id]);
                        }
                    }
                    
                    peerUpdatePairing(priority, &attributes);
                    
                    /* Kick Peer state machine to start relaying audio, if necessary */
                    peerAdvanceRelayState(RELAY_EVENT_CONNECTED);
                }
#endif
            }
            
            /* if rssi pairing check to see if need to cancel rssi pairing or not */           
            if(theSink.inquiry.action == rssi_pairing)
            {
                /* if rssi pairing has completed then stop it progressing further */            
                if(!((theSink.features.PairIfPDLLessThan)&&( ConnectionTrustedDeviceListSize() < theSink.features.PairIfPDLLessThan )))
                {
                    inquiryStop();
                }
            }

#ifdef ENABLE_AVRCP
            {
                if(theSink.features.avrcp_enabled)
                {
                    if (theSink.avrcp_link_data->avrcp_manual_connect)
                    {
                        theSink.avrcp_link_data->avrcp_play_addr = SrcAddr;
                    }
                        
#ifdef ENABLE_PEER
                    /* Peer devices that support custom AVRCP operation do not need to delay initial AVRCP connection */
                    if ((theSink.a2dp_link_data->peer_device[priority] == remote_device_peer) && (theSink.a2dp_link_data->peer_features[priority] & remote_features_peer_avrcp) && locally_initiated)
                    {
                        sinkAvrcpConnect(&theSink.a2dp_link_data->bd_addr[priority], DEFAULT_AVRCP_NO_CONNECTION_DELAY);
                    }
                    else
#endif
                    {
                        sinkAvrcpConnect(&theSink.a2dp_link_data->bd_addr[priority], DEFAULT_AVRCP_1ST_CONNECTION_DELAY);     
                    }
                }
            }
#endif    
	}
    }
}


/*************************************************************************
NAME    
    connectA2dpStream
    
DESCRIPTION
    Issues a request to the A2DP library to establish a media stream to a
    remote device.  The request can be delayed by a certain amount of time 
    if required.

RETURNS
    
**************************************************************************/
void connectA2dpStream (a2dp_link_priority priority, uint16 delay)
{
    A2DP_DEBUG(("A2dp: connectA2dpStream[%u] delay=%u\n", priority, delay)); 
    
    if (!delay)
    {
        if (theSink.a2dp_link_data && theSink.a2dp_link_data->connected[priority])
        {
#ifdef ENABLE_PEER
            if (theSink.a2dp_link_data->peer_device[priority] == remote_device_unknown)
            {   /* Still waiting for Device Id SDP search outcome issued in handleA2DPSignallingConnected() */
                EVENT_STREAM_ESTABLISH_T *message = PanicUnlessNew(EVENT_STREAM_ESTABLISH_T);
                
                message->priority = priority;
                MessageSendLater(&theSink.task, EventSysStreamEstablish, message, 200);  /* Ideally we'd send conditionally, but there isn't a suitable variable */
                
                A2DP_DEBUG(("local device is unknown, re-issue stream establish event\n")); 
            }
            else if (theSink.a2dp_link_data->peer_device[priority] == remote_device_nonpeer)
#endif
            {   /* Open media channel to AV Source */
                A2DP_DEBUG(("local device is non-peer (AV Source)\n"));
                if (A2dpMediaGetState(theSink.a2dp_link_data->device_id[priority], 0) == a2dp_stream_idle)
                {
                    A2DP_DEBUG(("AV Source stream idle\n"));
                    A2DP_DEBUG(("Send open req to AV Source, using defualt seid list\n"));
                    openStream(priority, 0);
                }
            }
        }
    }
    else
    {
        EVENT_STREAM_ESTABLISH_T *message = PanicUnlessNew(EVENT_STREAM_ESTABLISH_T);
        
        message->priority = priority;
        MessageSendLater(&theSink.task, EventSysStreamEstablish, message, delay);
        
        A2DP_DEBUG(("... wait for %u msecs\n", delay)); 
    }
}


/*************************************************************************
NAME    
    handleA2DPOpenInd
    
DESCRIPTION
    handle an indication of an media channel open request, decide whether 
    to accept or reject it

RETURNS
    
**************************************************************************/
void handleA2DPOpenInd(uint16 DeviceId, uint8 seid)
{
   	A2DP_DEBUG(("A2dp: OpenInd DevId = %d, seid = 0x%X\n",DeviceId, seid)); 

#ifdef ENABLE_PEER
    {
        uint16 Id;
        
        if (getA2dpIndex(DeviceId, &Id))
        {   /* Always accept an open indication, regardless of whether it comes from an AV Source / Peer */
            theSink.a2dp_link_data->seid[Id] = seid;
            
            if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
            {
                peerAdvanceRelayState(RELAY_EVENT_OPENING);
            }
            
            A2DP_DEBUG(("Ind from %s,  Sending open resp\n", rdname[theSink.a2dp_link_data->peer_device[Id]]));
            A2dpMediaOpenResponse(DeviceId, TRUE);
        }
    }
#else        
    /* accept this media connection */
    if(A2dpMediaOpenResponse(DeviceId, TRUE))    
    {
        uint16 Id;
		A2DP_DEBUG(("Open Success\n"));
           
        /* find structure index of deviceId */
        if(getA2dpIndex(DeviceId, &Id))
            theSink.a2dp_link_data->device_id[Id] = DeviceId;

    }
#endif
}

/*************************************************************************
NAME    
    handleA2DPOpenCfm
    
DESCRIPTION
    handle a successful confirm of a media channel open

RETURNS
    
**************************************************************************/
void handleA2DPOpenCfm(uint16 DeviceId, uint16 StreamId, uint8 seid, a2dp_status_code status)
{
    bool status_avrcp = FALSE;
    
	/* ensure successful confirm status */
	if (status == a2dp_success)
	{        
        uint16 Id;
#ifdef ENABLE_AVRCP            
        uint16 i;
#endif
        A2DP_DEBUG(("Open Success\n"));
           
        /* find structure index of deviceId */
        if(getA2dpIndex(DeviceId, &Id))
        {
            A2DP_DEBUG(("Open Success - id=%u\n",Id));
            
            /* set the current seid */         
            theSink.a2dp_link_data->device_id[Id] = DeviceId;
            theSink.a2dp_link_data->stream_id[Id] = StreamId;
            theSink.a2dp_link_data->seid[Id] = seid;
            theSink.a2dp_link_data->media_reconnect[Id] = FALSE;
            
            /* update the link policy */      
            linkPolicyUseA2dpSettings(DeviceId, StreamId, A2dpSignallingGetSink(DeviceId));
       
#ifdef ENABLE_PEER
            if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
            {
                peerAdvanceRelayState(RELAY_EVENT_OPENED);
				
                /* Send the audio enhancement  and user eq settings(if present) to the peer(slave) if this device is a master*/
                peerSendAudioEnhancements();

#if defined ENABLE_GAIA && defined ENABLE_GAIA_PERSISTENT_USER_EQ_BANK                
                peerSendUserEqSettings();
#endif
            }
            else
            {
                PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE OPENED");
            }
#endif
        
           /* Start the Streaming if if in the suspended state.  Don't issue any AVRCP/AVDTP commands to a Peer device as these are managed separately */
           if ((theSink.a2dp_link_data->SuspendState[Id] == a2dp_local_suspended) && (theSink.a2dp_link_data->peer_device[Id] != remote_device_peer))
           {          
#ifdef ENABLE_AVRCP            
                /* does the device support AVRCP and is AVRCP currently connected to this device? */
                for_all_avrcp(i)
                {    
                    /* ensure media is streaming and the avrcp channel is that requested to be paused */
                    if ((theSink.avrcp_link_data->connected[i])&& 
                        (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[Id], &theSink.avrcp_link_data->bd_addr[i])))
                    {
                        /* attempt to resume playing the a2dp stream */
                        status_avrcp = sinkAvrcpPlayPauseRequest(i,AVRCP_PLAY);
                        A2DP_DEBUG(("Open Success - suspended - avrcp play\n"));
                        break;
                    }
                }
#endif
                /* if not avrcp enabled, use media start instead */
                if(!status_avrcp)
                {
                    A2dpMediaStartRequest(DeviceId, StreamId);
              		A2DP_DEBUG(("Open Success - suspended - start streaming\n"));
                }
    
                /* reset suspended state once start is sent*/            
                a2dpSetSuspendState(Id, a2dp_not_suspended);
            }
    	}
    }
   	else
   	{
   		A2DP_DEBUG(("Open Failure [result = %d]\n", status));
#ifdef ENABLE_PEER
        {
            uint16 Id;
           
            if (getA2dpIndex(DeviceId, &Id))
            {
                if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
                {
                    peerAdvanceRelayState(RELAY_EVENT_NOT_OPENED);
                }
                else
                {
                    PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE OPEN FAILED");
                }
            }
        }
#endif
	}	
}

/*************************************************************************
NAME    
    handleA2DPClose
    
DESCRIPTION
    handle the close of a media channel 

RETURNS
    
**************************************************************************/
static void handleA2DPClose(uint16 DeviceId, uint16 StreamId, a2dp_status_code status)
{		
    /* check the status of the close indication/confirm */    
    if((status == a2dp_success) || (status == a2dp_disconnect_link_loss))
    {
        Sink sink = A2dpSignallingGetSink(DeviceId);
        
       	A2DP_DEBUG(("A2dp: Close DevId = %d, StreamId = %d\n",DeviceId,StreamId)); 

        /* route the audio using the appropriate codec/plugin */
 	    audioHandleRouting(audio_source_none);
#ifdef ENABLE_SOUNDBAR
            /*Set back the LE SCAN priority to normal */
            InquirySetPriority(inquiry_normal_priority);
#endif /* ENABLE_SOUNDBAR */

        /* update the link policy */
	    linkPolicyUseA2dpSettings(DeviceId, StreamId, sink);

        /* change device state if currently in one of the A2DP specific states */
        if(stateManagerGetState() == deviceA2DPStreaming)
        {
            /* the enter connected state function will determine if the signalling
               channel is still open and make the approriate state change */
            stateManagerEnterConnectedState();
        }
        
        /* user configurable event notification */
        MessageSend(&theSink.task, EventSysA2dpDisconnected, 0);
 
#ifdef ENABLE_PEER
        {
            uint16 Id;
        
            if (getA2dpIndex(DeviceId, &Id))
            {
                /* Reset seid now that media channel has closed */
                theSink.a2dp_link_data->seid[Id] = 0;
                
                if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
                {   /* Peer device has closed its media channel, now look to see if AV source is trying to initiate streaming */
                    peerAdvanceRelayState(RELAY_EVENT_CLOSED);
                }
                else if (theSink.a2dp_link_data->peer_device[Id] == remote_device_nonpeer)
                {   /* AV Source closed it's media channel, update the required state */
                    PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE CLOSED");
                    
                    if (theSink.a2dp_link_data->media_reconnect[Id])
                    {   /* Disconnect signalling channel to AV Source (for IOP reasons) */
                        A2dpSignallingDisconnectRequest(theSink.a2dp_link_data->device_id[Id]);
                    }
                }
            }
        }
#endif
        
#ifdef ENABLE_AVRCP
        if(theSink.features.avrcp_enabled)
        {
            uint16 Id;
            /* assume device is stopped for AVRCP 1.0 devices */
            if(getA2dpIndex(DeviceId, &Id))
                sinkAvrcpSetPlayStatus(&theSink.a2dp_link_data->bd_addr[Id], avrcp_play_status_stopped);
        }
#endif 
	}
    else
    {
       	A2DP_DEBUG(("A2dp: Close FAILED status = %d\n",status)); 
    }
}

/*************************************************************************
NAME    
    handleA2DPSignallingDisconnected
    
DESCRIPTION
    handle the disconnection of the signalling channel
RETURNS
    
**************************************************************************/
void handleA2DPSignallingDisconnected(uint16 DeviceId, a2dp_status_code status,  bdaddr SrcAddr)
{
    uint16 Id;
    bool reconnect = FALSE;
#ifdef ENABLE_PEER
    bool peer_disconnected = FALSE;
#endif

    /* check for successful disconnection status */
    if(getA2dpIndex(DeviceId, &Id))
    {
      	A2DP_DEBUG(("A2dp: SigDiscon DevId = %d\n",DeviceId)); 
        
#ifdef ENABLE_PARTYMODE
        {
            /* check whether party mode is enabled */
            if((theSink.PartyModeEnabled)&&(theSink.features.PartyMode))
            {
                /* device disconnected, cancel its play music timeout */
                MessageCancelAll(&theSink.task,(EventSysPartyModeTimeoutDevice1 + Id));                 
            }
        }
#endif                        

#ifdef ENABLE_PEER
        if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
        {   /* A Peer device */
            if (peerObtainPairingMode(Id) == PEER_PAIRING_MODE_TEMPORARY)
            {   /* Pairing is temporary.  Ensure Peer device is removed from DM */
                A2DP_DEBUG(("Remove Peer %u from PDL\n", Id));
                ConnectionSmDeleteAuthDevice(&theSink.a2dp_link_data->bd_addr[Id]);
            }
            
            /* Store knowledge of Peer disconnecting to use later once a2dp parameters reset */
            peer_disconnected = TRUE;

            /* As the peer has disconnected, reset the remote_peer_ag_bd_addr*/
            BdaddrSetZero(&theSink.remote_peer_ag_bd_addr);
            theSink.remote_peer_audio_conn_status = 0; 
            
            /* Store the attributes in PS */
            deviceManagerUpdateAttributes(&SrcAddr, sink_a2dp, 0, Id);   
        }
        else
#endif
        {   /* Not a Peer device */
            
#ifdef ENABLE_PEER
            /*If the A2DP has disconnected from a non-peer device then notify this to the peer device */
            audio_src_conn_state_t  AudioSrcStatus;
            AudioSrcStatus.src = A2DP_AUDIO;
            AudioSrcStatus.isConnected = FALSE;
            updatePeerAudioConnStatus(AudioSrcStatus);
#endif

            if (theSink.a2dp_link_data->media_reconnect[Id])
            {   /* A reconnect of signalling and media channel has been requested, due to AAC not being supported by ShareMe */
                reconnect = TRUE;
            }
        
            /* Store the attributes in PS */
            deviceManagerUpdateAttributes(&SrcAddr, sink_a2dp, 0, Id);   
        }

        /* Reset the a2dp parameter values */
        theSink.a2dp_link_data->peer_device[Id] = remote_device_unknown;
        theSink.a2dp_link_data->peer_features[Id] = 0;
        if(!(theSink.a2dp_link_data->local_peer_status[Id] & PEER_STATUS_POWER_OFF))
        {
            theSink.a2dp_link_data->local_peer_status[Id] = 0;
        }
        theSink.a2dp_link_data->remote_peer_status[Id] = 0;
        theSink.a2dp_link_data->media_reconnect[Id] = FALSE;
        BdaddrSetZero(&theSink.a2dp_link_data->bd_addr[Id]);
        theSink.a2dp_link_data->connected[Id] = FALSE;
        a2dpSetSuspendState(Id, a2dp_not_suspended);
        theSink.a2dp_link_data->device_id[Id] = INVALID_DEVICE_ID;
        theSink.a2dp_link_data->stream_id[Id] = INVALID_STREAM_ID; 
        theSink.a2dp_link_data->list_id[Id] = INVALID_LIST_ID;
        theSink.a2dp_link_data->seid[Id] = 0;
        theSink.a2dp_link_data->av_source[Id] = RELAY_SOURCE_NULL;
        theSink.a2dp_link_data->playing[Id] = FALSE;
#ifdef ENABLE_AVRCP
        theSink.a2dp_link_data->avrcp_support[Id] = avrcp_support_unknown;
#endif        

        /* Sends the indication to the device manager to send an event out if a device has disconnected*/
        deviceManagerDeviceDisconnectedInd(&SrcAddr);
      
        /*if the device is off then this is disconnect as part of the power off cycle, otherwise check
          whether device needs to be made connectable */	
    	if ( stateManagerGetState() != deviceLimbo)
        {
            /* Kick role checking now a device has disconnected */
            linkPolicyCheckRoles();
            
            /* at least one device disconnected, re-enable connectable for another 60 seconds */
            sinkEnableMultipointConnectable();

            /* if the device state still shows connected and there are no profiles currently
               connected then update the device state to reflect the change of connections */
    	    if ((stateManagerIsConnected()) && (!deviceManagerNumConnectedDevs()))
    	    {
    	        stateManagerEnterConnectableState( FALSE ) ;
    	    }
        }
        
#ifdef ENABLE_PEER
        /* A Peer/Source disconnecting will/may affect relay state */
        if (peer_disconnected)
        {   /* Peer signalling channel has gone so media channel has also.  Let state machine know */
            peerAdvanceRelayState(RELAY_EVENT_DISCONNECTED);
            if(theSink.a2dp_link_data->local_peer_status[Id] & PEER_STATUS_POWER_OFF)
            {                
                MessageSend(&theSink.task, EventUsrPowerOff, 0);
            }
        }
        else
        {
            PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE DISCONNECTED");
        }
#endif            

#ifdef ENABLE_AVRCP
        if(theSink.features.avrcp_enabled)
        {
            sinkAvrcpDisconnect(&SrcAddr);     
        }
#endif
        
        if (reconnect)
        {   /* Kick off reconnect now */
            A2dpSignallingConnectRequest(&SrcAddr);
        }
#ifdef ENABLE_PEER
        else if (!a2dpGetPeerIndex(&Id))
        {   /* Mark AAC as available again now that any ShareMe sessions have ended */
            A2dpCodecSetAvailable(a2dp_primary, AAC_SEID, TRUE);
            A2dpCodecSetAvailable(a2dp_secondary, AAC_SEID, TRUE);
        }
#endif
    }    
    else
       	A2DP_DEBUG(("A2dp: Sig Discon FAILED status = %d\n",status)); 

}
       
/*************************************************************************
NAME    
    handleA2DPSignallingLinkloss
    
DESCRIPTION
    handle the indication of a link loss
RETURNS
    
**************************************************************************/
void handleA2DPSignallingLinkloss(uint16 DeviceId)
{
    uint16 Id;
    
    if (getA2dpIndex(DeviceId, &Id))
    {
        /* Kick role checking now a device has disconnected */
        linkPolicyCheckRoles();
        
        theSink.a2dp_link_data->connected[Id] = FALSE;
        
#ifdef ENABLE_PEER
        /* A Peer/Source disconnecting will/may affect relay state */
        if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
        {   /* Peer signalling channel has gone so media channel has also.  Let state machine know */
            PEER_UPDATE_REQUIRED_RELAY_STATE("PEER LINKLOSS");
            peerAdvanceRelayState(RELAY_EVENT_CLOSED);
        }
        else if (theSink.a2dp_link_data->peer_device[Id] == remote_device_nonpeer)
        {
            PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE LINKLOSS");
        }
#endif            
        audioHandleRouting(audio_source_none);
        
        if(theSink.features.GoConnectableDuringLinkLoss || (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer))
        {   /* Go connectable if feature enabled or remote is a peer device */
            sinkEnableConnectable(); 
            MessageCancelAll(&theSink.task, EventSysConnectableTimeout);   /* Ensure connectable mode does not get turned off */
        }

        /* Send an event to notify the user of link loss */
        MessageCancelAll(&theSink.task , EventSysLinkLoss );
        MessageSend(&theSink.task,  EventSysLinkLoss, 0);
    }
}

/*************************************************************************
NAME    
    handleA2DPStartStreaming
    
DESCRIPTION
    handle the indication of media start ind
RETURNS
    
**************************************************************************/
void handleA2DPStartInd(uint16 DeviceId, uint16 StreamId)
{
#ifdef ENABLE_PEER
    uint16 Id;

    if (getA2dpIndex(DeviceId, &Id))
    {
       /* update the link policy */
        linkPolicyUseA2dpSettings(DeviceId, StreamId, A2dpSignallingGetSink(DeviceId));
        
        /* Ensure suspend state is cleared now streaming has started/resumed */
        a2dpSetSuspendState(Id, a2dp_not_suspended);

        if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
        {   /* Just accept media stream from peer device */
            peerAdvanceRelayState(RELAY_EVENT_STARTING);
            A2dpMediaStartResponse(DeviceId, StreamId, TRUE);
        }
        else
        {   /* Open ind from true AV source */
            PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE STARTING");
            if ( !peerIsRelayAvailable() || !peerCheckSource(RELAY_SOURCE_A2DP) )
            {   /* Either no peer device connected or we have a peer that has control of the relay channel. In either case just accept the media stream */
                A2DP_DEBUG(("Relay channel NOT available\n"));
                A2DP_DEBUG(("Send start resp to AV Source\n"));
                A2dpMediaStartResponse(DeviceId, StreamId, TRUE);
            }
        }
    }
#else /* ENABLE_PEER */  

    /* Always accept the media stream */
    A2dpMediaStartResponse(DeviceId, StreamId, TRUE);
    
#ifdef ENABLE_PARTYMODE
    {
        uint16 Id;

        /* check whether party mode is enabled */
        if((getA2dpIndex(DeviceId, &Id))&&(theSink.PartyModeEnabled)&&(theSink.features.PartyMode))
        {
            /* device streaming, cancel its play music timeout */
            MessageCancelAll(&theSink.task,(EventSysPartyModeTimeoutDevice1 + Id));                 
        }
    }
#endif  /* ENABLE_PARTYMODE */                       

#endif /* ENABLE_PEER */
}

/*************************************************************************
NAME    
    handleA2DPStartStreaming
    
DESCRIPTION
    handle the indication of media start cfm
RETURNS
    
**************************************************************************/
void handleA2DPStartStreaming(uint16 DeviceId, uint16 StreamId, a2dp_status_code status)
{   
    /* check success status of indication or confirm */
    if(status == a2dp_success)
    {
        uint16 Id;     
        Sink sink = A2dpMediaGetSink(DeviceId, StreamId);
        
        A2DP_DEBUG(("A2dp: StartStreaming DevId = %d, StreamId = %d\n",DeviceId,StreamId));    
        /* find structure index of deviceId */
        if(getA2dpIndex(DeviceId, &Id))
        {          

#ifdef ENABLE_PARTYMODE
            /* check whether party mode is enabled */
            if((theSink.PartyModeEnabled)&&(theSink.features.PartyMode))
            {
                /* device streaming, cancel its play music timeout */
                MessageCancelAll(&theSink.task,(EventSysPartyModeTimeoutDevice1 + Id));                 
            }
#endif                        
            /* Ensure suspend state is cleared now streaming has started/resumed */
            a2dpSetSuspendState(Id, a2dp_not_suspended);

            /*Ensure that the device is not currently streaming from a different A2DP, if its found to be streaming then pause this incoming stream  */
#ifdef ENABLE_AVRCP            
            a2dpPauseNonRoutedSource(Id);
#endif

            /* route the audio using the appropriate codec/plugin */
            audioHandleRouting(audio_source_none);
            
            /* enter the stream a2dp state if not in a call */
            stateManagerEnterA2dpStreamingState();
            /* update the link policy */
            linkPolicyUseA2dpSettings(DeviceId, StreamId, sink);
            /* set the current seid */         
            theSink.a2dp_link_data->stream_id[Id] = StreamId;

#ifdef ENABLE_PEER
            if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
            {   /* Peer media channel has started */
                peerAdvanceRelayState(RELAY_EVENT_STARTED);
            }
            else
            {
                PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE STARTED");
            }
            
            updateA2dpLinkLossManagement(Id);
#endif
            
#ifdef ENABLE_AVRCP           
            if(theSink.features.avrcp_enabled)
            {
                /* assume device is playing for AVRCP 1.0 devices */
                sinkAvrcpSetPlayStatus(&theSink.a2dp_link_data->bd_addr[Id], avrcp_play_status_playing);
            }
#endif 

#ifdef ENABLE_PEER
            /* Only update EQ mode for non peer devices i.e. for streams to be rendered locally */
            if (theSink.a2dp_link_data->peer_device[Id] != remote_device_peer)
#endif
            {
                /* Set the Stored EQ mode, ensure the DSP is currently streaming A2DP data before trying to
               set EQ mode as it might be that the device has a SCO routed instead */
                if(theSink.routed_audio == sink)
                {
                    AUDIO_MODE_T mode = AUDIO_MODE_CONNECTED;
                
                    A2DP_DEBUG(("A2dp: StartStreaming Set EQ mode = %d\n",theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing)); 
                
					/* when the volume level is reduced to minimum level, i.e. MUTE, set the mute
                       state in the audio plugin */
					if ((theSink.volume_levels->a2dp_volume[Id].masterVolume) == VOLUME_A2DP_MUTE_GAIN)
                    {
                        mode = AUDIO_MODE_MUTE_SPEAKER;
                    }
                    
                    /* set both EQ and Enhancements enables */
                    AudioSetMode(mode, &theSink.a2dp_link_data->a2dp_audio_mode_params);
                }
                else
                {
                    A2DP_DEBUG(("A2dp: Wrong sink Don't Set EQ mode = %d\n",theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing)); 
                }
            }
            /* when using the Soundbar manual audio routing and subwoofer support, 
               check to see if the a2dp audio is being routed, if not check whether
               an esco subwoofer channel is currently in use, if this is the case it 
               will be necessary to pause this a2dp stream to prevent disruption
               of the subwoofer esco link due to link bandwidth limitations */
#if defined(ENABLE_SOUNDBAR) && defined(ENABLE_SUBWOOFER)
            suspendWhenSubwooferStreamingLowLatency(Id);
#endif            
        }
    }
    else
    {
       	A2DP_DEBUG(("A2dp: StartStreaming FAILED status = %d\n",status)); 
#ifdef ENABLE_PEER
        {
            uint16 Id;
            
            if (getA2dpIndex(DeviceId, &Id))
            {
                if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
                {   /* Peer has rejected start of media channel, need to respond to any outstanding request from AV source */
                    peerAdvanceRelayState(RELAY_EVENT_NOT_STARTED);
                }
                else
                {
                    PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE START FAILED");
                }
            }
        }
#endif
    }

}             

/*************************************************************************
NAME    
    handleA2DPSuspendStreaming
    
DESCRIPTION
    handle the indication of media suspend from either the ind or the cfm
RETURNS
    
**************************************************************************/
void handleA2DPSuspendStreaming(uint16 DeviceId, uint16 StreamId, a2dp_status_code status)
{
    Sink sink = A2dpMediaGetSink(DeviceId, StreamId);
    
#ifdef ENABLE_SOUNDBAR
    /*Set back the LE SCAN priority to normal */
    InquirySetPriority(inquiry_normal_priority);
#endif /* ENABLE_SOUNDBAR */

    /* if the suspend was not successful, issue a close instead */
    if(status == a2dp_rejected_by_remote_device)
    {
       	A2DP_DEBUG(("A2dp: Suspend Failed= %x, try close DevId = %d, StreamId = %d\n",status,DeviceId,StreamId)); 
        /* suspend failed so close media streaming instead */
        A2dpMediaCloseRequest(DeviceId, StreamId);
    }
    /* check success status of indication or confirm */
    else 
    {
        uint16 Id;
        
        A2DP_DEBUG(("A2dp: Suspend Ok DevId = %d, StreamId = %d\n",DeviceId,StreamId)); 
 
        if(getA2dpIndex(DeviceId, &Id)) 
        {
            /* no longer streaming so enter connected state if applicable */    	
            if(stateManagerGetState() == deviceA2DPStreaming)
            {
                /* the enter connected state function will determine if the signalling
                   channel is still open and make the approriate state change */
                stateManagerEnterConnectedState();
            }
            
            /* Ensure suspend state is set as streaming has now ceased */
            a2dpSetSuspendState(Id, a2dp_remote_suspended);
            
            /* route the audio using the appropriate codec/plugin */
            audioHandleRouting(audio_source_none);
            
            /* update the link policy */
            linkPolicyUseA2dpSettings(DeviceId, StreamId, sink);

#ifdef ENABLE_PEER
            if (theSink.a2dp_link_data->peer_device[Id] == remote_device_nonpeer)
            {   /* AV Source suspended it's media channel, update the required state */
                PEER_UPDATE_REQUIRED_RELAY_STATE("A2DP SOURCE SUSPENDED");
            }
            else if (theSink.a2dp_link_data->peer_device[Id] == remote_device_peer)
            {   /* Peer suspended it's media channel, look to see if local device has a streaming AV source */
                peerAdvanceRelayState(RELAY_EVENT_SUSPENDED);
            }
            
            updateA2dpLinkLossManagement(Id);
#endif
            
#ifdef ENABLE_AVRCP
            if (theSink.features.avrcp_enabled)
            {    
                /* assume device is paused for AVRCP 1.0 devices */
                sinkAvrcpSetPlayStatus(&theSink.a2dp_link_data->bd_addr[Id], avrcp_play_status_paused);
            }
#endif
        }
    }
}
  
/*************************************************************************
NAME    
    SuspendA2dpStream
    
DESCRIPTION
    called when it is necessary to suspend an a2dp media stream due to 
    having to process a call from a different AG. If the device supports
    AVRCP then issue a 'pause' which is far more reliable than trying a
    media_suspend request.
    
RETURNS
    
**************************************************************************/
void SuspendA2dpStream(a2dp_link_priority priority)
{
    if (theSink.a2dp_link_data && (theSink.a2dp_link_data->peer_device[priority] != remote_device_peer))
    {
        bool status = FALSE;

#ifdef ENABLE_AVRCP            
        uint16 i;
#endif    
        A2DP_DEBUG(("A2dp: Suspend A2DP Stream %x\n",priority)); 

        /* set the local suspend status indicator */
        a2dpSetSuspendState(priority, a2dp_local_suspended);

#ifdef ENABLE_AVRCP            
        /* does the device support AVRCP and is AVRCP currently connected to this device? */
        for_all_avrcp(i)
        {    
            /* ensure media is streaming and the avrcp channel is that requested to be paused */
            if ((theSink.avrcp_link_data->connected[i])&&(theSink.a2dp_link_data->connected[priority])&&
                (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[priority], &theSink.avrcp_link_data->bd_addr[i])))
            {
                /* check whether the a2dp connection is streaming data */
                if (A2dpMediaGetState(theSink.a2dp_link_data->device_id[i], theSink.a2dp_link_data->stream_id[i]) == a2dp_stream_streaming)
                {
                    /* attempt to pause the a2dp stream */
                    status = sinkAvrcpPlayPauseRequest(i,AVRCP_PAUSE);
                }
                break;
            }
        }
#endif
    
        /* attempt to suspend stream if avrcp pause was not successful, if not successful then close it */
        if(!status)
        {
            if(!A2dpMediaSuspendRequest(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]))
            {
                /* suspend failed so close media streaming */
                A2dpMediaCloseRequest(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]);
            }
        }

        /* no longer streaming so enter connected state if applicable */    	
        if(stateManagerGetState() == deviceA2DPStreaming)
        {
            /* the enter connected state function will determine if the signalling
               channel is still open and make the approriate state change */
            stateManagerEnterConnectedState();
        }
    }
}


/*************************************************************************
NAME    
    a2dpSuspended
    
DESCRIPTION
    Helper to indicate whether A2DP is suspended on given source
RETURNS
    TRUE if A2DP suspended, otherwise FALSE
**************************************************************************/
a2dp_suspend_state a2dpSuspended(a2dp_link_priority priority)
{
    if(!theSink.a2dp_link_data) return FALSE;
    return theSink.a2dp_link_data->SuspendState[priority];
}
   

/*************************************************************************
NAME    
    ResumeA2dpStream
    
DESCRIPTION
    Called to resume a suspended A2DP stream
RETURNS
    
**************************************************************************/
void ResumeA2dpStream(a2dp_link_priority priority, a2dp_stream_state state, Sink sink)
{
    if (theSink.a2dp_link_data && (theSink.a2dp_link_data->peer_device[priority] != remote_device_peer))
    {
        bool status_avrcp = FALSE;
#ifdef ENABLE_AVRCP            
        uint16 i;
#endif
    
        A2DP_DEBUG(("A2dp: ResumeA2dpStream\n" )) ;   

        /* need to check whether the signalling channel hsa been dropped by the AV/AG source */
        if(A2dpSignallingGetState(theSink.a2dp_link_data->device_id[priority]) == a2dp_signalling_connected)
        {
            /* is media channel still open? or is it streaming already? */
            if(state == a2dp_stream_open)
            {
#ifdef ENABLE_AVRCP            
                /* does the device support AVRCP and is AVRCP currently connected to this device? */
                for_all_avrcp(i)
                {    
                    /* ensure media is streaming and the avrcp channel is that requested to be paused */
                    if ((theSink.avrcp_link_data->connected[i])&&(theSink.a2dp_link_data->connected[priority])&&
                        (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[priority], &theSink.avrcp_link_data->bd_addr[i])))
                    {
                        /* attempt to resume playing the a2dp stream */
                        status_avrcp = sinkAvrcpPlayPauseRequest(i,AVRCP_PLAY);
                        /* update state */
                        a2dpSetSuspendState(priority, a2dp_not_suspended);
                        break;
                    }
                }
#endif
                /* if not successful in resuming play via avrcp try a media start instead */  
                if(!status_avrcp)
                {
                    A2DP_DEBUG(("A2dp: Media Start\n" )) ;   
                    A2dpMediaStartRequest(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]);
                    /* reset the SuspendState indicator */
                    a2dpSetSuspendState(priority, a2dp_not_suspended);
                }
            }
            /* media channel wasn't open, source not supporting suspend */            
            else if(state < a2dp_stream_open) 
            {
                A2DP_DEBUG(("A2dp: Media Open\n" )) ;   
                connectA2dpStream( priority, 0 );
            }
            /* recovery if media has resumed streaming reconnect its audio */
            else if(state == a2dp_stream_streaming)
            {
#ifdef ENABLE_AVRCP            
                /* does the device support AVRCP and is AVRCP currently connected to this device? */
                for_all_avrcp(i)
                {    
                    /* ensure media is streaming and the avrcp channel is that requested to be paused */
                    if ((theSink.avrcp_link_data->connected[i])&&(theSink.a2dp_link_data->connected[priority])&&
                        (BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[priority], &theSink.avrcp_link_data->bd_addr[i])))
                    {
                        /* attempt to resume playing the a2dp stream */
                        status_avrcp = sinkAvrcpPlayPauseRequest(i,AVRCP_PLAY);
                        break;
                    }
                }
#endif
                a2dpSetSuspendState(priority, a2dp_not_suspended);
                A2dpRouteAudio(priority, sink);
            }
        }
        /* signalling channel is no longer present so attempt to reconnect it */
        else
        {
            A2DP_DEBUG(("A2dp: Connect Signalling\n" )) ;   
            A2dpSignallingConnectRequest(&theSink.a2dp_link_data->bd_addr[priority]);
        }
    }
}


#ifdef ENABLE_AVRCP
/*************************************************************************
NAME    
    getA2dpVolume
    
DESCRIPTION
    Retrieve the A2DP volume for the connection to the device with the address specified.
    
RETURNS
    Returns TRUE if the volume was retrieved, FALSE otherwise.
    The actual volume is returned in the a2dp_volume variable.
    
**************************************************************************/
bool getA2dpVolume(const bdaddr *bd_addr, uint16 *a2dp_volume)
{
    uint8 i;
    
    /* go through A2dp connection looking for match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its bdaddr */
        if(theSink.a2dp_link_data->connected[i])
        {
            /* if a match is found return its volume level and a
               status of successful match found */
            if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[i], bd_addr))
            {
				*a2dp_volume = theSink.volume_levels->a2dp_volume[i].masterVolume;
            	A2DP_DEBUG(("A2dp: getVolume = %d\n", i)); 
                return TRUE;
            }
        }
    }
    /* no matches found so return not successful */    
    return FALSE;
}  


/*************************************************************************
NAME    
    setA2dpVolume
    
DESCRIPTION
    Sets the A2DP volume for the connection to the device with the address specified.
    
RETURNS
    Returns TRUE if the volume was set, FALSE otherwise.
    
**************************************************************************/
bool setA2dpVolume(const bdaddr *bd_addr, uint16 a2dp_volume)
{
    uint8 i;
    
    /* go through A2dp connection looking for match */
    for_all_a2dp(i)
    {
        /* if the a2dp link is connected check its bdaddr */
        if(theSink.a2dp_link_data->connected[i])
        {
            /* if a match is found set its volume level and a
               status of successful match found */
            if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[i], bd_addr))
            {
                /* get current volume for this profile */
				/* A2DP volume updated with the new volume info */
				uint16 lOldVol = theSink.volume_levels->a2dp_volume[i].masterVolume;
                theSink.volume_levels->a2dp_volume[i].masterVolume = a2dp_volume;
				
            	A2DP_DEBUG(("A2dp: setVolume = %d\n", i));
                
                if(theSink.routed_audio && (theSink.routed_audio == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[i], theSink.a2dp_link_data->stream_id[i])))
                {
					/* Check A2DP volume against max. value for event handling */ 
					if(theSink.volume_levels->a2dp_volume[i].masterVolume == (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1))
                        MessageSend ( &theSink.task , EventSysVolumeMax , 0 );
					/* Check A2DP volume against min. value for event handling */
					if(theSink.volume_levels->a2dp_volume[i].masterVolume == VOLUME_A2DP_MIN_LEVEL)				
                        MessageSend ( &theSink.task , EventSysVolumeMin , 0 );
                    /* after limit checking the volume, set the new volume level */           
                    VolumeSetA2dp(i, lOldVol, theSink.features.PlayLocalVolumeTone);
                }
                return TRUE;
            }
        }
    }
    /* no matches found so return not successful */    
    return FALSE;
}    
#endif

/*************************************************************************
NAME    
    handleA2DPStoreClockMismatchRate
    
DESCRIPTION
    handle storing the clock mismatch rate for the active stream
RETURNS
    
**************************************************************************/
void handleA2DPStoreClockMismatchRate(uint16 clockMismatchRate)   
{
    a2dp_stream_state a2dpStatePri = a2dp_stream_idle;
    a2dp_stream_state a2dpStateSec = a2dp_stream_idle;
    Sink a2dpSinkPri = 0;
    Sink a2dpSinkSec = 0;
        
    /* if a2dp connected obtain the current streaming state for primary a2dp connection */
    getA2dpStreamData(a2dp_primary, &a2dpSinkPri, &a2dpStatePri);

    /* if a2dp connected obtain the current streaming state for secondary a2dp connection */
    getA2dpStreamData(a2dp_secondary, &a2dpSinkSec, &a2dpStateSec);
 
    /* Determine which a2dp source this is for */
    if((a2dpStatePri == a2dp_stream_streaming) && (a2dpSinkPri == theSink.routed_audio))  
    {
        A2DP_DEBUG(("A2dp: store pri. clk mismatch = %x\n", clockMismatchRate));
        theSink.a2dp_link_data->clockMismatchRate[a2dp_primary] = clockMismatchRate;
    }
    else if((a2dpStateSec == a2dp_stream_streaming) && (a2dpSinkSec == theSink.routed_audio))  
    {
        A2DP_DEBUG(("A2dp: store sec. clk mismatch = %x\n", clockMismatchRate));
        theSink.a2dp_link_data->clockMismatchRate[a2dp_secondary] = clockMismatchRate;
    }
    else
    {
        A2DP_DEBUG(("A2dp: ERROR NO A2DP STREAM, clk mismatch = %x\n", clockMismatchRate));
    }
}
 

/*************************************************************************
NAME    
    handleA2DPStoreCurrentEqBank
    
DESCRIPTION
    handle storing the current EQ bank
RETURNS
    
**************************************************************************/
void handleA2DPStoreCurrentEqBank (uint16 currentEQ)   
{
    uint16 abs_eq = A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0 + currentEQ;
               
    A2DP_DEBUG(("A2dp: Current EQ = %x, store = %x\n", currentEQ, abs_eq));

    /* Make sure current EQ setting is no longer set to next and store it */
    if(theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing != abs_eq)
    {
        A2DP_DEBUG(("A2dp: Update Current EQ = %x\n", abs_eq));
        theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing = abs_eq;
#ifdef ENABLE_PEER
        /* Send the audio enhancement settings to the peer(slave) if this device is a master*/
        peerSendAudioEnhancements();
#endif        
        configManagerWriteSessionData () ; 
    }
}

/*************************************************************************
NAME    
    handleA2DPStoreEnhancments
    
DESCRIPTION
    handle storing the current enhancements settings
RETURNS
    
**************************************************************************/
void handleA2DPStoreEnhancements(uint16 enhancements)
{
    /* add in the data valid flag, this signifies that the user has altered the 3d or bass boost
       enhancements, these values should now be used instead of dsp default values that have been
       created by the ufe */
    enhancements |= (theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements & MUSIC_CONFIG_DATA_VALID); 
    
    A2DP_DEBUG(("A2dp: store enhancements = %x was %x\n", enhancements,theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements));

    /* Make sure current EQ setting is no longer set to next and store it */
    if(theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements != enhancements)
    {
        A2DP_DEBUG(("A2dp: update enhancements = %x\n", enhancements));
        theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements = enhancements;      
        configManagerWriteSessionData () ; 
    }
    
#ifdef ENABLE_PEER
        /* Send the audio enhancement settings to the peer(slave) if this device is a master*/
        peerSendAudioEnhancements();
#endif  

}

/*************************************************************************
 NAME    
    handleA2DPUserEqBankUpdate
    
DESCRIPTION
	Handle notification from an audio plugin for DSP ready for data message in order to update user defined EQ bank 
    when GAIA set EQ parameter commands are processed

RETURNS 
**************************************************************************/
void handleA2DPUserEqBankUpdate()
{
    if(theSink.PEQ)
    {        
        /* User EQ settings message buffer and buffer index for copy operation */
        uint16* dspSetEqMessage;
        uint16 i = 0;
        
        /* User EQ always operates on DSP EQ Bank 1, hence the param ID base maps to GAIA command ID for Filter type of Band 1 in EQ Bank 1 */        
#define PARAM_ID_BASE 0x0110  
    /* Set the Kalimba long message size taking the first and last word into account plus 2 words per parameter to update*/
#define MESSAGE_SIZE  46
            
        dspSetEqMessage = mallocPanic(MESSAGE_SIZE);
        memset(dspSetEqMessage, 0, MESSAGE_SIZE);
        /* First message element must contain the number of EQ parameters to update at all times */
        dspSetEqMessage[0]= 22; 
        
        /* Second message element contains parameter ID 0x0100 and the value which maps to the number of bands in user defined EQ Bank 1. 
        This data can be located anywhere in the message buffer, however, reading the GAIA message payload is easier this way
        while debugging */  
        dspSetEqMessage[1] = 0x0100;
        dspSetEqMessage[2] = 0x5;
        /* Third message element contains parameter ID 0x0101 and the value which maps to the master gain for user defined EQ Bank 1. 
        This data can be located anywhere in the message buffer, however, reading the GAIA message payload is easier this way
        while debugging */
        dspSetEqMessage[3] = 0x0101;
        dspSetEqMessage[4] = theSink.PEQ->preGain;            
         
        for(i=0; i<5; i++){
            dspSetEqMessage[(8*i)+5]= PARAM_ID_BASE + ((0x10)*i);
            dspSetEqMessage[(8*i)+6]= theSink.PEQ->bands[i].filter;
            dspSetEqMessage[(8*i)+7]= PARAM_ID_BASE + ((0x10)*i) +1;
            dspSetEqMessage[(8*i)+8]= theSink.PEQ->bands[i].freq;
            dspSetEqMessage[(8*i)+9]= PARAM_ID_BASE + ((0x10)*i) +2;
            dspSetEqMessage[(8*i)+10]= theSink.PEQ->bands[i].gain;
            dspSetEqMessage[(8*i)+11]= PARAM_ID_BASE + ((0x10)*i) +3;
            dspSetEqMessage[(8*i)+12]= theSink.PEQ->bands[i].Q;            
        }
        
        /* Parameter ID 0x0000 and the value which map to the number of active EQ banks, not for the time being but it may be needed in the future */
        /*KalimbaSendMessage(DSP_GAIA_MSG_SET_USER_PARAM, 0x0000, 6 , 0 , 0 );*/
        /*KalimbaSendMessage(DSP_GAIA_MSG_SET_USER_PARAM, 0x0101, theSink.PEQ->preGain, 0 , 0 );*/
        /*KalimbaSendMessage(DSP_GAIA_MSG_SET_USER_PARAM, 0x0100, 5 , 0 , 0 );*/
      
        /* Last message was intended for recalculation of filter coefficients, but is ignored in the existing GAIA DSP message handler implementation */
        dspSetEqMessage[45]= 0x0001;
        
        KalimbaSendLongMessage(DSP_GAIA_MSG_SET_USER_GROUP_PARAM,MESSAGE_SIZE,dspSetEqMessage);

        free(dspSetEqMessage);
    }
}

/*************************************************************************
NAME    
    getA2dpIndexFromBdaddr
    
DESCRIPTION
    Attempts to find a A2DP link data index based on the supplied bdaddr.
    
RETURNS
    TRUE if successful, FALSE otherwise
    
**************************************************************************/
bool getA2dpIndexFromBdaddr (const bdaddr *bd_addr, uint16 *index)
{
    /* go through A2dp connection looking for match */
    for_all_a2dp(*index)
    {
        /* if the a2dp link is connected check its bdaddr */
        if(theSink.a2dp_link_data /*&& theSink.a2dp_link_data->connected[*index]*/)
        {
            /* if a match is found indicate success */
            if(BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[*index], bd_addr))
            {
                return TRUE;
            }
        }
    }
    /* no matches found so return not successful */    
    return FALSE;
}

/*************************************************************************
NAME    
    disconnectAllA2dpAVRCP
    
DESCRIPTION
    disconnect any a2dp and avrcp connections
    
RETURNS
    
**************************************************************************/
void disconnectAllA2dpAvrcp (bool disconnect_peer)
{
    uint8 i;

#ifdef ENABLE_AVRCP
    if(theSink.features.avrcp_enabled)    
    {
        sinkAvrcpDisconnectAll(disconnect_peer);
    }
#endif  
    if(theSink.a2dp_link_data)
    {
        /* disconnect any a2dp signalling channels */
        for_all_a2dp(i)
        {
            /* if the a2dp link is connected, disconnect it */
            if(theSink.a2dp_link_data->connected[i])
            {
                if ((theSink.a2dp_link_data->peer_device[i]!=remote_device_peer) || disconnect_peer)
                {
                    A2dpSignallingDisconnectRequest(theSink.a2dp_link_data->device_id[i]);
                }
            }
        }
    }  
}               

/*************************************************************************
NAME    
    disconnectAllA2dpPeerDevices
    
DESCRIPTION
    Disconnect any a2dp connections to any peer devices
    
RETURNS
    TRUE is any peer devices disconnected, FALSE otherwise
    
**************************************************************************/
bool disconnectAllA2dpPeerDevices (void)
{
    uint8 i;
    bool disc_req = FALSE;

    if(theSink.a2dp_link_data)
    {
        /* disconnect any a2dp signalling channels to peer devices */
        for_all_a2dp(i)
        {
            /* if the a2dp link is connected, disconnect it */
            if ((theSink.a2dp_link_data->connected[i]) && (theSink.a2dp_link_data->peer_device[i]==remote_device_peer))
            {
                A2dpSignallingDisconnectRequest(theSink.a2dp_link_data->device_id[i]);
                disc_req = TRUE;
            }
        }
    }  
    
    return disc_req;
}


/*************************************************************************
NAME    
    handleA2DPSyncDelayInd
    
DESCRIPTION
	Handle request from A2DP library for a Sink device to supply an initial
	Synchronisation Delay (audio latency) report.

RETURNS
    
**************************************************************************/
void handleA2DPSyncDelayInd (uint16 device_id, uint8 seid)
{
	Task audio_plugin;
	
	if ((audio_plugin = getA2dpPlugin(seid)) != NULL)
	{
		uint16 index;
		uint16 latency;
        bool estimated;
		
		if ( AudioGetLatency(audio_plugin, &estimated, &latency) && getA2dpIndex(device_id, &index) )
		{
			A2dpMediaAvSyncDelayResponse(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->seid[index], latency);
		}
	}
}

/*************************************************************************
NAME    
    handleA2DPLatencyReport
    
DESCRIPTION
	Handle notification from an audio plugin raised due to the DSP providing
	a measured audio latency value.

RETURNS
    
**************************************************************************/
void handleA2DPLatencyReport (Task audio_plugin, bool estimated, uint16 latency)
{
	uint16 index;
	
	if (getA2dpIndexFromPlugin(audio_plugin, &index))
	{
		theSink.a2dp_link_data->latency[index] = latency;
		
		if (estimated)
		{
			A2dpMediaAvSyncDelayResponse(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->seid[index], latency);
		}
		else
		{
			A2dpMediaAvSyncDelayRequest(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->seid[index], latency);
		}
	}
}


/*************************************************************************
NAME    
    handleA2DPMessage
    
DESCRIPTION
    A2DP message Handler, this function handles all messages returned
    from the A2DP library and calls the relevant functions if required

RETURNS
    
**************************************************************************/
void handleA2DPMessage( Task task, MessageId id, Message message )
{
    A2DP_DEBUG(("A2DP_MSG id=%x : \n",id));
    
    switch (id)
    {
/******************/
/* INITIALISATION */
/******************/
        
        /* confirmation of the initialisation of the A2DP library */
        case A2DP_INIT_CFM:
            A2DP_DEBUG(("A2DP_INIT_CFM : \n"));
            sinkA2dpInitComplete((A2DP_INIT_CFM_T *) message);
        break;

/*****************************/        
/* SIGNALING CHANNEL CONTROL */
/*****************************/

        /* indication of a remote source trying to make a signalling connection */		
	    case A2DP_SIGNALLING_CONNECT_IND:
	        A2DP_DEBUG(("A2DP_SIGNALLING_CHANNEL_CONNECT_IND : \n"));
            handleA2DPSignallingConnectInd( ((A2DP_SIGNALLING_CONNECT_IND_T *)message)->device_id,
                                            ((A2DP_SIGNALLING_CONNECT_IND_T *)message)->addr );
		break;

        /* confirmation of a signalling connection attempt, successful or not */
	    case A2DP_SIGNALLING_CONNECT_CFM:
            A2DP_DEBUG(("A2DP_SIGNALLING_CHANNEL_CONNECT_CFM : \n"));
	    	handleA2DPSignallingConnected(((A2DP_SIGNALLING_CONNECT_CFM_T*)message)->status, 
	    								  ((A2DP_SIGNALLING_CONNECT_CFM_T*)message)->device_id, 
                                          ((A2DP_SIGNALLING_CONNECT_CFM_T*)message)->addr,
                                          ((A2DP_SIGNALLING_CONNECT_CFM_T*)message)->locally_initiated);
	    break;
        
        /* indication of a signalling channel disconnection having occured */
    	case A2DP_SIGNALLING_DISCONNECT_IND:
            A2DP_DEBUG(("A2DP_SIGNALLING_CHANNEL_DISCONNECT_IND : \n"));
        	handleA2DPSignallingDisconnected(((A2DP_SIGNALLING_DISCONNECT_IND_T*)message)->device_id,
                                             ((A2DP_SIGNALLING_DISCONNECT_IND_T*)message)->status,
                                             ((A2DP_SIGNALLING_DISCONNECT_IND_T*)message)->addr);
		break;
        
/*************************/        
/* MEDIA CHANNEL CONTROL */        
/*************************/
        
        /* indication of a remote device attempting to open a media channel */      
        case A2DP_MEDIA_OPEN_IND:
            A2DP_DEBUG(("A2DP_OPEN_IND : \n"));
        	handleA2DPOpenInd(((A2DP_MEDIA_OPEN_IND_T*)message)->device_id,
                              ((A2DP_MEDIA_OPEN_IND_T*)message)->seid);
        break;
		
        /* confirmation of request to open a media channel */
        case A2DP_MEDIA_OPEN_CFM:
            A2DP_DEBUG(("A2DP_OPEN_CFM : \n"));
        	handleA2DPOpenCfm(((A2DP_MEDIA_OPEN_CFM_T*)message)->device_id, 
    						  ((A2DP_MEDIA_OPEN_CFM_T*)message)->stream_id, 
    						  ((A2DP_MEDIA_OPEN_CFM_T*)message)->seid, 
    						  ((A2DP_MEDIA_OPEN_CFM_T*)message)->status);
        break;
        	
        /* indication of a request to close the media channel, remotely generated */
        case A2DP_MEDIA_CLOSE_IND:
            A2DP_DEBUG(("A2DP_CLOSE_IND : \n"));
            handleA2DPClose(((A2DP_MEDIA_CLOSE_IND_T*)message)->device_id,
                            ((A2DP_MEDIA_CLOSE_IND_T*)message)->stream_id,
                            ((A2DP_MEDIA_CLOSE_IND_T*)message)->status);
        break;

        /* confirmation of the close of the media channel, locally generated  */
        case A2DP_MEDIA_CLOSE_CFM:
           A2DP_DEBUG(("A2DP_CLOSE_CFM : \n"));
           handleA2DPClose(0,0,a2dp_success);
        break;

/**********************/          
/*  STREAMING CONTROL */
/**********************/          
        
        /* indication of start of media streaming from remote source */
        case A2DP_MEDIA_START_IND:
            A2DP_DEBUG(("A2DP_START_IND : \n"));
         	handleA2DPStartInd(((A2DP_MEDIA_START_IND_T*)message)->device_id,
                               ((A2DP_MEDIA_START_IND_T*)message)->stream_id);
        break;
		
        /* confirmation of a local request to start media streaming */
        case A2DP_MEDIA_START_CFM:
            A2DP_DEBUG(("A2DP_START_CFM : \n"));
    	    handleA2DPStartStreaming(((A2DP_MEDIA_START_CFM_T*)message)->device_id,
                                     ((A2DP_MEDIA_START_CFM_T*)message)->stream_id,
                                     ((A2DP_MEDIA_START_CFM_T*)message)->status);
        break;
        
        case A2DP_MEDIA_SUSPEND_IND:
            A2DP_DEBUG(("A2DP_SUSPEND_IND : \n"));
        	handleA2DPSuspendStreaming(((A2DP_MEDIA_SUSPEND_IND_T*)message)->device_id,
                                       ((A2DP_MEDIA_SUSPEND_IND_T*)message)->stream_id,
                                         a2dp_success);
        break;
		
        case A2DP_MEDIA_SUSPEND_CFM:
            A2DP_DEBUG(("A2DP_SUSPEND_CFM : \n"));
        	handleA2DPSuspendStreaming(((A2DP_MEDIA_SUSPEND_CFM_T*)message)->device_id,
                                       ((A2DP_MEDIA_SUSPEND_CFM_T*)message)->stream_id,
                                       ((A2DP_MEDIA_SUSPEND_CFM_T*)message)->status);
        break;

/*************************/
/* MISC CONTROL MESSAGES */
/*************************/
        
        case A2DP_MEDIA_AV_SYNC_DELAY_UPDATED_IND:
            A2DP_DEBUG(("A2DP_MEDIA_AV_SYNC_DELAY_UPDATED_IND : seid=0x%X delay=%u\n", ((A2DP_MEDIA_AV_SYNC_DELAY_UPDATED_IND_T*)message)->seid, 
                                                                                       ((A2DP_MEDIA_AV_SYNC_DELAY_UPDATED_IND_T*)message)->delay));
             /* Only received for source SEIDs.  Use delay value to aid AV synchronisation */                                                                        
        break;

        case A2DP_MEDIA_AV_SYNC_DELAY_IND:
            A2DP_DEBUG(("A2DP_MEDIA_AV_SYNC_DELAY_IND : seid=0x%X\n",((A2DP_MEDIA_AV_SYNC_DELAY_IND_T*)message)->seid));
			handleA2DPSyncDelayInd(((A2DP_MEDIA_AV_SYNC_DELAY_IND_T*)message)->device_id,
                                   ((A2DP_MEDIA_AV_SYNC_DELAY_IND_T*)message)->seid);
        break;
        
        case A2DP_MEDIA_AV_SYNC_DELAY_CFM:
            A2DP_DEBUG(("A2DP_MEDIA_AV_SYNC_DELAY_CFM : \n"));
        break;
        
        /* link loss indication */
        case A2DP_SIGNALLING_LINKLOSS_IND:
            A2DP_DEBUG(("A2DP_SIGNALLING_LINKLOSS_IND : \n"));
            handleA2DPSignallingLinkloss(((A2DP_SIGNALLING_LINKLOSS_IND_T*)message)->device_id);
        break;           
		
        case A2DP_CODEC_CONFIGURE_IND:
            A2DP_DEBUG(("A2DP_CODEC_CONFIGURE_IND : \n"));
#ifdef ENABLE_PEER
            handleA2dpCodecConfigureIndFromPeer((A2DP_CODEC_CONFIGURE_IND_T *)message);
#endif
        break;
            
	    case A2DP_ENCRYPTION_CHANGE_IND:
            A2DP_DEBUG(("A2DP_ENCRYPTION_CHANGE_IND : \n"));
		break;
			
        default:       
	    	A2DP_DEBUG(("A2DP UNHANDLED MSG: 0x%x\n",id));
        break;
    }    
}



#if defined(ENABLE_SOUNDBAR) && defined(ENABLE_SUBWOOFER)
/*************************************************************************
NAME    
    suspendWhenSubwooferStreamingLowLatency
    
DESCRIPTION
    funnction to determine if a2dp stream should be suspended due to the use
    of the low latency subwoofer link. Streaming a2dp media will adversely affect
    the quality of the sub low latency link due to bluetooth link bandwidth 
    limitations

RETURNS
    none
    
**************************************************************************/
void suspendWhenSubwooferStreamingLowLatency(uint16 Id)
{
    /* check whether this a2dp link got routed */
    if(theSink.rundata->routed_audio_source != audio_source_AG1 + Id)
    {
        /* this a2dp source is not currently routed, check for presence of subwoofer */                
        if (SwatGetMediaLLState(theSink.rundata->subwoofer.dev_id) == swat_media_streaming)
        {
            audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);  
                
            /* sub woofer is currently streaming and using an esco connection
               it is necessary to suspend this a2dp stream to prevent sub stream dissruption */
            audioSuspendDisconnectAllA2dpMedia(lAudioStatus);
            
            /* free malloc'd slot */
            free(lAudioStatus);
        }              
    }
}
#endif
