/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_plugin.h

DESCRIPTION
    
    
NOTES
   
*/
#ifndef _CSR_A2DP_DECODER_COMMON_PLUGIN_H_
#define _CSR_A2DP_DECODER_COMMON_PLUGIN_H_


#include <message.h> 
#include <a2dp.h>


/*!  CSR_A2DP_DECODER_COMMON plugin

    This is an A2DP plugin that can be used with the DSP library.
*/

typedef enum
{
     SBC_DECODER                = 1
    ,MP3_DECODER                = 2
    ,AAC_DECODER                = 3
    ,FASTSTREAM_SINK            = 4
    ,USB_DECODER                = 5
    ,APTX_DECODER               = 6
    ,APTX_ACL_SPRINT_DECODER    = 7
    ,ANALOG_DECODER             = 8
    ,SPDIF_DECODER              = 9                                  
	,TWS_SBC_DECODER			= 10
	,TWS_MP3_DECODER			= 11
	,TWS_AAC_DECODER			= 12
	,TWS_APTX_DECODER			= 13
	,FM_DECODER	         		= 14
	,NUM_DECODER_PLUGINS
}A2DP_DECODER_PLUGIN_TYPE_T;


typedef struct
{
    TaskData                    data;
    A2DP_DECODER_PLUGIN_TYPE_T  a2dp_plugin_variant:4 ; /* Selects the A2DP plugin variant */
    unsigned                    reserved:12 ;           /* Set the reserved bits to zero */
}A2dpPluginTaskdata;


typedef enum
{
    A2DP_MUSIC_PROCESSING_PASSTHROUGH,
    A2DP_MUSIC_PROCESSING_FULL,
    A2DP_MUSIC_PROCESSING_FULL_NEXT_EQ_BANK,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK1,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK2,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK3,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK4,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK5,
    A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK6
}A2DP_MUSIC_PROCESSING_T;

#define A2DP_MUSIC_MAX_EQ_BANK (6)

/* MSG: PLUGIN -> VM APP */
/* The VM app should use this message to restore the EQ bank after a power cycle. */
#define A2DP_MUSIC_MSG_CUR_EQ_BANK   1
#define A2DP_MUSIC_MSG_ENHANCEMENTS  2

/* lower 3 bits of enchancement uint16 are the EQ selected */
#define A2DP_MUSIC_CONFIG_USER_EQ_SELECT 7

#define MUSIC_CONFIG_DATA_VALID         (0x8000)
#define MUSIC_CONFIG_SUB_WOOFER_BYPASS  (0x0800)
#define MUSIC_CONFIG_SPKR_EQ_BYPASS     (0x0400)
#define MUSIC_CONFIG_EQFLAT             (0x0200)
#define MUSIC_CONFIG_USER_EQ_BYPASS     (0x0100)
#define MUSIC_CONFIG_BASS_BOOST_BYPASS  (0x0080)
#define MUSIC_CONFIG_SPATIAL_BYPASS     (0x0040)
#define MUSIC_CONFIG_COMPANDER_BYPASS   (0x0020)
#define MUSIC_CONFIG_DITHER_BYPASS      (0x0010)
#define MUSIC_CONFIG_USER_EQ_SELECT     (0x0007)

/* audio mode pararmeters external mic settings, applicable to APTX ll + back channel application only */
#define SEND_PATH_MUTE 0
#define SEND_PATH_UNMUTE 1
#define EXTERNAL_MIC_NOT_FITTED 1
#define EXTERNAL_MIC_FITTED 2

typedef struct
{
    A2DP_MUSIC_PROCESSING_T music_mode_processing;
    uint16 music_mode_enhancements;
    unsigned unused:8;
    unsigned external_volume_enabled:1;
    unsigned master_routing_mode:2;
    unsigned slave_routing_mode:2;
    unsigned external_mic_settings:2;
    unsigned mic_mute:1;
}A2dpPluginModeParams;

#define LATENCY_LAST_MULTIPLIER   1		/* 1ms resolution */
#define LATENCY_CHANGE_MULTIPLIER 5		/* 5ms resolution */
#define LATENCY_TARGET_MULTIPLIER 5		/* 5ms resolution */
#define LATENCY_PERIOD_MULTIPLIER 100	/* 100ms resolution */
typedef struct
{
	unsigned last:12;		 /* Last measured latency for the current codec, in ms. Zero implies no known last latency. */
	unsigned change:4;	 	 /* Minimum latency change before a report issued, in multiple of 5ms. */
	unsigned target:8;		 /* Target latency, in multiple of 5ms.  Zero implies no target latency. */
	unsigned period:8;		 /* Minimum time between reports, in multiple of 100ms.  Zero means latency reporting disabled. */
} A2dpPluginLatencyParams;

typedef struct
{
    uint16 clock_mismatch;
    uint16 currentEQ;
    uint16 enhancements;
    uint16 packet_size;
    uint16 silence_threshold ;   /* threshold (16 bit fractional value - aligned to MSB in DSP) */
    uint16 silence_trigger_time; /* trigger time in seconds (16 bit int) */
    uint16 speaker_pio;          /* pio to control on silence detection*/
    A2dpPluginModeParams *mode_params;
    const common_mic_params* mic_params;
    usb_common_params* usb_params;
    AUDIO_SUB_TYPE_T sub_woofer_type;
    Sink sub_sink;
	A2dpPluginLatencyParams latency;
    unsigned :6;
    unsigned delay_volume_message_sending:1; /* flag used to delay the setting of the volume message to allow a soft transitional fade in */
    unsigned sub_is_available:1;     /* flag to indicate if a subwoofer signalling connection is present, used for delaying audio unmuting */
    unsigned sub_connection_port:4;  /* inidicates which port is connected for the sub use */
    unsigned is_for_soundbar:1;      /* Required to identify soundbar as common library for both Soundbar and Sink app. */
    unsigned content_protection:1;
    unsigned channel_mode:2;
    unsigned format:8;
    unsigned bitpool:8;
    uint32 voice_rate;
    aptx_sprint_params_type aptx_sprint_params;
    spdif_ac3_configuration *spdif_ac3_config;
    spdif_target_latency *target_latency_config;         
} A2dpPluginConnectParams;


extern const A2dpPluginTaskdata csr_sbc_decoder_plugin;
extern const A2dpPluginTaskdata csr_mp3_decoder_plugin;
extern const A2dpPluginTaskdata csr_aac_decoder_plugin;
extern const A2dpPluginTaskdata csr_faststream_sink_plugin;
extern const A2dpPluginTaskdata csr_aptx_decoder_plugin;
extern const A2dpPluginTaskdata csr_aptx_acl_sprint_decoder_plugin;
extern const A2dpPluginTaskdata csr_tws_sbc_decoder_plugin;
extern const A2dpPluginTaskdata csr_tws_mp3_decoder_plugin;
extern const A2dpPluginTaskdata csr_tws_aac_decoder_plugin;
extern const A2dpPluginTaskdata csr_tws_aptx_decoder_plugin;
extern const A2dpPluginTaskdata csr_fm_decoder_plugin;

extern const uint8 sbc_caps_sink[16];
extern const uint8 mp3_caps_sink[16];
extern const uint8 aac_caps_sink[18];
extern const uint8 faststream_caps_sink[16];
extern const uint8 aptx_caps_sink[19]; 
extern const uint8 aptx_acl_sprint_caps_sink[29];
extern const uint8 tws_sbc_caps[26];
extern const uint8 tws_mp3_caps[26];
extern const uint8 tws_aac_caps[28];
extern const uint8 tws_aptx_caps[29];


uint32 AudioGetA2DPSampleRate(void);
uint32 AudioGetA2DPSubwooferSampleRate(void);
bool AudioGetLatency (Task audio_plugin, bool *estimated, uint16 *latency);

/* spdif specific messages */
#define ENABLE_SPDIF_MESSAGING 1    /* enable reporting of status messages from dsp */
#define SPDIF_MINIMUM_INACTIVITY_TIME_BEFORE_SENDING_MESSAGE 10 /* time in seconds before sending status messages */
 
#define MUTE_DISCONNECT_DELAY_WITH_SUB 250/* allow 250mS for outputs to mute before disconnecting dsp to prevent thuds/clicks */
#define MUTE_DISCONNECT_DELAY_WITHOUT_SUB 5/* allow 5mS for outputs to mute before disconnecting dsp to prevent thuds/clicks */
#define ALLOW_FULL_DSP_BUFFER_DELAY_FOR_SOFT_MUTE 100 /* allow 100ms for dsp buffers to fill to allow soft mute functionality to work */
#define SUBWOOFER_CONNECTION_FAILURE_TIMEOUT 5000 /* if subwoofer port hasn't connected within 5 seconds then assume it won't */

#define DIGITAL_VOLUME_DEFAULT_TONE_GAIN -600 /* use a default tone gain of -10dB */

#endif
