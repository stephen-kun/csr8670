/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common.h

DESCRIPTION
    
    
NOTES
   
*/
 
#ifndef _CSR_A2DP_DECODER_COMMON_H_
#define _CSR_A2DP_DECODER_COMMON_H_

#include "audio_plugin_if.h" /*for the audio_mode*/
#include "audio_plugin_common.h"

/*  The following PS Key can be used to define a non-default maximum clock mismatch between SRC and SNK devices.
    If the PS Key is not set, the default maximum clock mismatch value will be used.
    The default value has been chosen to have a very good THD performance and to avoid audible pitch shifting
    effect even during harsh conditions (big jitters, for example). While the default covers almost all phones
    and other streaming sources by a big margin, some phones could prove to have a larger percentage clock drift.
*/
#define PSKEY_MAX_CLOCK_MISMATCH    0x2258 /* PSKEY_DSP0 */

#define MIXED_MODE_INCREASING_DELAY 42 /* 42 ms optimum delay for increasing volume */
#define MIXED_MODE_DECREASING_DELAY 25 /* 25 ms optimum delay for decreasing volume */

typedef enum
{
    DECREASING,
    INCREASING
}volume_change_direction_t;

typedef struct
{
    uint16 id;
    uint16 size;
    char   buf[1];
} DSP_LONG_REGISTER_T;

typedef struct tag_mic_type
{
   unsigned preamp_enable:1; /* high bit */
   unsigned unused:6;
   unsigned digital_gain:4;
   unsigned analogue_gain:5;   /* low bits */
} T_mic_gain;

typedef struct sync_Tag
{
    A2dpPluginTaskdata *task;
    Sink media_sink ;
    Sink forwarding_sink ;
    Task codec_task ;
    /*! mono or stereo*/
    AudioPluginFeatures features;
    /* type of audio source, used to determine what port to connect to dsp */
    AUDIO_SINK_T sink_type:8;
    /*! The current mode */
    unsigned mode:8 ;
    unsigned master_routing_mode:2;
    unsigned slave_routing_mode:2;
    unsigned routing_mode_change_pending:1;
    unsigned stream_relay_mode:2;
    unsigned relay_mode_change_pending:1;
    
    unsigned sbc_encoder_bitpool:8;
    unsigned sbc_encoder_format:8;
    
    unsigned sbc_encoder_params_pending:1;
    unsigned external_volume_enabled:1;
    unsigned device_trims_pending:1;
    unsigned dsp_ports_connected:1;
    unsigned :2;
    unsigned packet_size:10;                /* Used to configure RTP transform when forwarding undecoded audio frames */

    /* Additional mode parameters */
    uint16 mode_params;
    /* digital volume structure including trim gains */    
    AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volume;
    uint16 DAC_Gain;
    uint16 params;
    uint32 rate;
    Task app_task;
}DECODER_t ;


/*plugin functions*/
void csrA2dpDecoderEnableExternalVolume (bool enabled);
void csrA2dpDecoderSetTwsRoutingMode (uint16 master_routing, uint16 slave_routing);
void csrA2dpDecoderSetSbcEncoderParams (uint8 bitpool, uint8 format);
void csrA2dpDecoderSetDeviceTrims (int16 device_trim_master, int16 device_trim_slave);
void csrA2dpDecoderSetStreamRelayMode (uint16 mode);
void CsrA2dpDecoderPluginConnect( A2dpPluginTaskdata *task, 
                                  Sink audio_sink , 
                                  AUDIO_SINK_T sink_type,
								  Task codec_task , 
								  uint16 volume , 
								  uint32 rate , 
                                  AudioPluginFeatures features,
                                  AUDIO_MODE_T mode , 
								  const void * params, 
								  Task app_task );
void CsrA2dpDecoderPluginDisconnect( A2dpPluginTaskdata *task ) ;
void CsrA2dpDecoderPluginSetVolume(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T *volumeDsp) ;
void CsrA2dpDecoderPluginResetVolume(void);
void CsrA2dpDecoderPluginSetSoftMute(AUDIO_SOFT_MUTE_TYPE_T mute_type);
void CsrA2dpDecoderPluginSetMode( AUDIO_MODE_T mode , A2dpPluginTaskdata *task , const void * params ) ;
void CsrA2dpDecoderPluginPlayTone ( A2dpPluginTaskdata *task, ringtone_note * tone , Task codec_task , uint16 tone_volume, bool stereo);
void CsrA2dpDecoderPluginStopTone ( void ) ;
void CsrA2dpDecoderPluginToneComplete ( void ) ;
void CsrA2dpDecoderPluginInternalMessage( A2dpPluginTaskdata *task ,uint16 id , Message message ) ;
bool CsrA2dpDecoderPluginGetLatency (A2dpPluginTaskdata *audio_plugin, bool *estimated, uint16 *latency);
DECODER_t * CsrA2dpDecoderGetDecoderData(void);
void CsrA2dpDecoderPluginSetEqMode(uint16 operating_mode, A2DP_MUSIC_PROCESSING_T music_processing, A2dpPluginModeParams *mode_params);
void CsrA2dpDecoderPluginUpdateEnhancements(A2dpPluginModeParams *mode_params);
void MicMuteUnmute(A2dpPluginConnectParams *codecData,bool mute);
void MusicConnectAudio (A2dpPluginTaskdata *task);
void CsrA2dpDecoderPluginSetDspLevels(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T * VolumeMsg);
void CsrA2dpDecoderPluginStartDisconnect(TaskData * task);
void CsrA2dpDecoderPluginSetLevels(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T * VolumeMsg, volume_change_direction_t direction, bool ForceSetVolume);
void CsrA2dpDecoderPluginAllowVolChanges(void);
void CsrA2dpDecoderPluginSubCheckForConnectionFailure(void);
void CsrA2dpDecoderPluginSetAudioLatency (A2dpPluginTaskdata *audio_plugin, uint16 latency);
void CsrA2DPDecoderSetDACGain(uint16 DAC_Gain);
uint32 CsrA2DPGetDecoderSampleRate(void);
uint32 CsrA2DPGetDecoderSubwooferSampleRate(void);

#endif


