/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common.c
DESCRIPTION
    plugin implentation which routes the sco audio though the dsp
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#ifndef DEBUG_PRINT_ENABLED
#define xDEBUG_PRINT_ENABLED
#endif
#include <print.h>
#include <file.h>
#include <stream.h> /*for the ringtone_note*/
#include <kalimba.h>
#include <kalimba_standard_messages.h>
#include <message.h>
#include <ps.h>
#include <Transform.h>
#include <string.h>
#include <pio_common.h>
#include <pblock.h>


#include "csr_i2s_audio_plugin.h"
#include "audio_plugin_if.h" /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_a2dp_decoder_common_plugin.h"
#include "csr_a2dp_decoder_common.h"
#include "csr_a2dp_decoder_common_if.h"

#include "csr_a2dp_decoder_common_aptx.h"
#include "csr_a2dp_decoder_common_aptx_ll.h"
#include "csr_a2dp_decoder_common_faststream.h"
#include "csr_a2dp_decoder_common_fm.h"
#include "csr_a2dp_decoder_common_subwoofer.h"
#include "csr_a2dp_decoder_common_sharing.h"
#include "csr_a2dp_decoder_common_cvc_back_channel.h"

#include "csr_a2dp_decoder_common_low_latency.h"

/*the synchronous audio data structure*/
static DECODER_t * DECODER = NULL ;

static bool pskey_read = FALSE;
static uint16 val_pskey_max_mismatch = 0;
static uint16 val_clock_mismatch = 0;

static const uint16 dsp_variant[NUM_DECODER_PLUGINS] =
{
    0,
    DSP_SBC_DECODER,                /* SBC_DECODER              */
    DSP_MP3_DECODER,                /* MP3_DECODER              */
    DSP_AAC_DECODER,                /* AAC_DECODER              */
    DSP_FASTSTREAM_SINK,            /* FASTSTREAM_SINK          */
    DSP_USB_DECODER,                /* USB_DECODER              */
    DSP_APTX_DECODER,               /* APTX_DECODER             */
    DSP_APTX_ACL_SPRINT_DECODER,    /* APTX_ACL_SPRINT_DECODER  */
    DSP_ANALOG_DECODER,             /* WIRED_DECODER            */
    DSP_SPDIF_DECODER,              /* SPDIF_DECODER            */
    DSP_SBC_DECODER,                /* TWS_SBC_DECODER          */
    DSP_MP3_DECODER,                /* TWS_MP3_DECODER          */
    DSP_AAC_DECODER,                /* TWS_AAC_DECODER          */
    DSP_APTX_DECODER,               /* TWS_APTX_DECODER         */
    DSP_SBC_DECODER                 /* FM_DECODER               */
};

/****************************************************************************
DESCRIPTION

    Translated VM variant id into something the DSP app understands
*/
static uint16 getDspVariant (uint16 variant)
{
    if (variant < NUM_DECODER_PLUGINS)
    {
        return dsp_variant[variant];
    }

    return 0xFFFF;
}


/****************************************************************************
DESCRIPTION

    Sends a latency report to the application
*/
static void sendLatencyReport (Task app_task, A2dpPluginTaskdata *audio_plugin, bool estimated, uint16 latency)
{
    MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_LATENCY_REPORT);
    PRINT(("DECODER: Latency report estimated:%u latency:%ums\n", estimated, latency));
    message->audio_plugin = (Task)audio_plugin;
    message->estimated = estimated;
    message->latency = latency;
    MessageSend(app_task, AUDIO_PLUGIN_LATENCY_REPORT, message);
}

/****************************************************************************
DESCRIPTION

    Stores latency reported by DSP and, if required, informs application
*/
void CsrA2dpDecoderPluginSetAudioLatency (A2dpPluginTaskdata *audio_plugin, uint16 latency)
{
    if (DECODER != NULL)
    {
        A2dpPluginLatencyParams *latencyParams = &((A2dpPluginConnectParams *)DECODER->params)->latency;
        latencyParams->last = latency;

        if (latencyParams->period || latencyParams->change)
        {
            sendLatencyReport(DECODER->app_task, audio_plugin, FALSE, latency);
        }
    }
}


/****************************************************************************
DESCRIPTION

    Provides an estimate of audio latency for a specific codec
*/
static uint16 estimateLatency (A2DP_DECODER_PLUGIN_TYPE_T variant)
{
    uint16 latency = 0;

    /* TODO: Temporary values atm, n.b. units are in 1/10th ms. */
    switch (variant)
    {
    case SBC_DECODER:
    case MP3_DECODER:
    case AAC_DECODER:
    case APTX_DECODER:
        latency = 150;
        break;
    case FASTSTREAM_SINK:
    case APTX_ACL_SPRINT_DECODER:
        latency = 45;
        break;
    case TWS_SBC_DECODER:
    case TWS_MP3_DECODER:
    case TWS_AAC_DECODER:
    case TWS_APTX_DECODER:
        latency = 300;
        break;
    default:
        break;
    }

    PRINT(("DECODER: estimateLatency variant=%u latency=%ums\n", variant, latency));
    return latency;
}


/****************************************************************************
DESCRIPTION

    Configures the DSP to start issuing audio latency measurements
*/
static void enableLatencyReporting (A2dpPluginTaskdata *audio_plugin)
{
    if (DECODER != NULL)
    {
        uint16 initial_latency;
        A2dpPluginLatencyParams *latencyParams = &((A2dpPluginConnectParams *)DECODER->params)->latency;

        if (latencyParams->period)
        {
            if (latencyParams->last)
            {
                initial_latency = (uint16)latencyParams->last * LATENCY_LAST_MULTIPLIER;
            }
            else if (latencyParams->target)
            {
                initial_latency = (uint16)latencyParams->target * LATENCY_TARGET_MULTIPLIER;
            }
            else
            {
                initial_latency = estimateLatency(audio_plugin->a2dp_plugin_variant);
            }

            /* Convert latency configuration parameters to single millisecond resolution before sending to DSP */
            PRINT(("DECODER: CONFIGURE_LATENCY_REPORTING Period=%ums, Change=%ums, Initial=%ums\n", (uint16)latencyParams->period * LATENCY_PERIOD_MULTIPLIER, (uint16)latencyParams->change * LATENCY_CHANGE_MULTIPLIER, initial_latency));
            KalimbaSendMessage(CONFIGURE_LATENCY_REPORTING, 1, (uint16)latencyParams->period * LATENCY_PERIOD_MULTIPLIER, (uint16)latencyParams->change * LATENCY_CHANGE_MULTIPLIER, initial_latency);
            /*KalimbaSendMessage(CONFIGURE_LATENCY_REPORTING, 0x8000 | ((uint16)latencyParams->target * LATENCY_TARGET_MULTIPLIER), (uint16)latencyParams->period * LATENCY_PERIOD_MULTIPLIER, (uint16)latencyParams->change * LATENCY_CHANGE_MULTIPLIER, initial_latency);*/
        }
    }
}

/****************************************************************************
DESCRIPTION

    Obtains a value for audio latency for the specified plugin

    This function can be called before the DSP is loaded.  In which case, the reported
    latency value is an initial estimate based on the audio_plugin provided.

    If the DSP has been loaded and latency reporting has been enabled, then the value reported is
    the last latency value measured by the DSP.

    The latency is reported in units of one tenth of a ms.
*/
bool CsrA2dpDecoderPluginGetLatency (A2dpPluginTaskdata *audio_plugin, bool *estimated, uint16 *latency)
{
    PRINT(("DECODER: CsrA2dpDecoderPluginGetLatency plugin=%X ", (uint16)audio_plugin));

    if (audio_plugin != NULL)
    {
        if (DECODER != NULL)
        {   /* DSP is loaded */
            A2dpPluginLatencyParams *latencyParams = &((A2dpPluginConnectParams *)DECODER->params)->latency;

            if ((latencyParams->period) && (latencyParams->last))
            {   /* Latency reporting enabled and DSP has provided a latency value */
                *estimated = FALSE;
                *latency = latencyParams->last;

                PRINT(("OK  estimated=%u latency=%u\n", *estimated, *latency));
                return TRUE;
            }
        }

        /* DSP not currently loaded or has not updated the latency */
        *estimated = TRUE;
        *latency = 10 * estimateLatency(audio_plugin->a2dp_plugin_variant);

        PRINT(("OK  estimated=%u latency=%u(1/10th ms)\n", *estimated, *latency));
        return TRUE;
    }

    /* Invalid plugin, return something to indicate an unknown latency */
    *estimated = TRUE;
    *latency = 0xFFFF;

    PRINT(("INVALID  estimated=%u latency=%u\n", *estimated, *latency));
    return FALSE;
}


/****************************************************************************
DESCRIPTION

    Issues a request to the DSP to change the TWS Audio Routing mode.
    
    The audio routing change will be queued if the DSP is not in the appropriate 
    state to accept a request.
*/
void csrA2dpDecoderEnableExternalVolume (bool enabled)
{
    PRINT(("DECODER: csrA2dpDecoderEnableExternalVolume  enabled=%u\n", enabled));
    if (DECODER != NULL)
    {
        DECODER->external_volume_enabled = enabled;
        KalimbaSendMessage(MESSAGE_ENABLE_EXT_VOLUME, enabled, 0, 0, 0);
    }
}


/****************************************************************************
DESCRIPTION

    Issues a request to the DSP to change the TWS Audio Routing mode.
    
    The audio routing change will be queued if the DSP is not in the appropriate 
    state to accept a request.
*/
void csrA2dpDecoderSetTwsRoutingMode (uint16 master_routing, uint16 slave_routing)
{
    PRINT(("DECODER: SetTwsRoutingMode  master=%u  slave=%u\n", master_routing, slave_routing));
    if (DECODER != NULL)
    {
        DECODER->master_routing_mode = master_routing;
        DECODER->slave_routing_mode = slave_routing;
        DECODER->routing_mode_change_pending = TRUE;
        
        if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) && !DECODER->relay_mode_change_pending)
        {   /* Only set routing mode if DSP is *currently* operating as a TWS Master */
            KalimbaSendMessage(MESSAGE_SET_TWS_ROUTING, master_routing, slave_routing, 0, 0);
            DECODER->routing_mode_change_pending = FALSE;
        }
    }
}


/****************************************************************************
DESCRIPTION

    Issues a request to the DSP to change the SBC Encoder parameters used for the TWS wired modes.
    
    The SBC encoder params change will be queued if the DSP is not in the appropriate 
    state to accept a request.
*/
void csrA2dpDecoderSetSbcEncoderParams (uint8 bitpool, uint8 format)
{
    PRINT(("DECODER: csrA2dpDecoderSetSbcEncoderParams  bitpool=%u  format=0x%X\n", bitpool, format));
    if (DECODER != NULL)
    {
        DECODER->sbc_encoder_bitpool = bitpool;
        DECODER->sbc_encoder_format = format;
        DECODER->sbc_encoder_params_pending = TRUE;
        
        if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) && !DECODER->relay_mode_change_pending)
        {   /* Only set routing mode if DSP is *currently* operating as a TWS Master */
            KalimbaSendMessage(KALIMBA_MSG_SBCENC_SET_PARAMS, format, 0, 0, 0);
            KalimbaSendMessage(KALIMBA_MSG_SBCENC_SET_BITPOOL, bitpool, 0, 0, 0);
            DECODER->sbc_encoder_params_pending = FALSE;
        }
    }
}


/****************************************************************************
DESCRIPTION

    Issues a request to the DSP to change the SBC Encoder parameters used for the TWS wired modes.
    
    The SBC encoder params change will be queued if the DSP is not in the appropriate 
    state to accept a request.
*/
void csrA2dpDecoderSetDeviceTrims (int16 device_trim_master, int16 device_trim_slave)
{
    PRINT(("DECODER: csrA2dpDecoderSetDeviceTrims  master_trim=%i  slave_trim=%i\n", device_trim_master, device_trim_slave));
    if (DECODER != NULL)
    {
        DECODER->volume.device_trim_master = device_trim_master;
        DECODER->volume.device_trim_slave = device_trim_slave;
        DECODER->device_trims_pending = TRUE;
        
        if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) && !DECODER->relay_mode_change_pending)
        {   /* Only set routing mode if DSP is *currently* operating as a TWS Master */
            KalimbaSendMessage(MESSAGE_SET_DEVICE_TRIMS, device_trim_master, device_trim_slave, 0, 0);
            DECODER->device_trims_pending = FALSE;
        }
    }
}


/****************************************************************************
DESCRIPTION

    Issues a request to the DSP to change the Stream Relay mode.  
    Any outstanding request will cause this new one to be queued.
    
*/
void csrA2dpDecoderSetStreamRelayMode (uint16 mode)
{
    PRINT(("DECODER: SetStreamRelayMode mode=%u\n", mode));

    if (DECODER != NULL)
    {
        PRINT(("DECODER:      last mode=%u  pending=%u\n", DECODER->stream_relay_mode, DECODER->relay_mode_change_pending));
        
#ifdef TWS_DEBUG
        if (mode==RELAY_MODE_TWS_MASTER)
        {
            mode = RELAY_MODE_SHAREME;
            PRINT(("DECODER: SetStreamRelayMode changed to mode=%u\n", mode));
        }

        if (mode==RELAY_MODE_TWS_SLAVE)
        {
            mode = RELAY_MODE_NONE;
            PRINT(("DECODER: SetStreamRelayMode changed to mode=%u\n", mode));
        }
#endif

        if (DECODER->stream_relay_mode != mode)
        {   /* Requested mode is different to current/queued mode */
            DECODER->stream_relay_mode = mode;
            
            if (!DECODER->relay_mode_change_pending)
            {   /* Not currently updating relay mode, so go ahead and issue a request */
                PRINT(("DECODER: Issuing DSP with MESSAGE_SET_RELAY_MODE=%u\n",DECODER->stream_relay_mode));
                
                KalimbaSendMessage(MESSAGE_SET_RELAY_MODE, DECODER->stream_relay_mode, 0, 0, 0);
                DECODER->relay_mode_change_pending = TRUE;
            }
        }
    }
}

/****************************************************************************
DESCRIPTION

    Handles notification from DSP that the Stream Relay mode has been updated.
    
    Result will contain either the mode that has been set or an error code.
    
    Will issue a further request to change mode if unsuccessful or a new mode has been queued.
    
    A successful change will update the TWS Audio Routing mode, if appropriate
*/
static void streamRelayModeUpdated (uint16 result)
{
    PRINT(("streamRelayModeUpdated  result=%u  required mode=%u\n", result, DECODER->stream_relay_mode));
    
    if (DECODER)
    {
        if (result == DECODER->stream_relay_mode)
        {
            DECODER->relay_mode_change_pending = FALSE;
            
            if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) && DECODER->routing_mode_change_pending)
            {   /* Only set routing mode if operating as a TWS Master */
                PRINT(("DECODER: Issuing DSP with MESSAGE_SET_TWS_ROUTING=%u,%u\n",DECODER->master_routing_mode, DECODER->slave_routing_mode));
                
                KalimbaSendMessage(MESSAGE_SET_TWS_ROUTING, DECODER->master_routing_mode, DECODER->slave_routing_mode, 0, 0);
                DECODER->routing_mode_change_pending = FALSE;
            }
            
            if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) && DECODER->sbc_encoder_params_pending)
            {   /* Only set SBC encoder paramsif operating as a TWS Master */
                PRINT(("DECODER: Issuing DSP with SBC Encoder params  bitpool=%u  format=0x%X\n",DECODER->sbc_encoder_bitpool, DECODER->sbc_encoder_format));
                
                KalimbaSendMessage(KALIMBA_MSG_SBCENC_SET_PARAMS, DECODER->sbc_encoder_format, 0, 0, 0);
                KalimbaSendMessage(KALIMBA_MSG_SBCENC_SET_BITPOOL, DECODER->sbc_encoder_bitpool, 0, 0, 0);
                DECODER->sbc_encoder_params_pending = FALSE;
            }
            
            if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) && DECODER->device_trims_pending)
            {   /* Only set device trims if operating as a TWS Master */
                PRINT(("DECODER: Issuing DSP with MESSAGE_SET_TWS_DEVICE_TRIMS  master_trim=%i  slave_trim=%i\n",DECODER->volume.device_trim_master, DECODER->volume.device_trim_slave));
                
                KalimbaSendMessage(MESSAGE_SET_DEVICE_TRIMS, DECODER->volume.device_trim_master, DECODER->volume.device_trim_slave, 0, 0);
                DECODER->device_trims_pending = FALSE;
            }
            
        }
        else
        {
            PRINT(("DECODER: Re-issuing DSP with MESSAGE_SET_RELAY_MODE=%u\n",DECODER->stream_relay_mode));
            
            KalimbaSendMessage(MESSAGE_SET_RELAY_MODE, DECODER->stream_relay_mode, 0, 0, 0);
            DECODER->relay_mode_change_pending = TRUE;
        }
    }
}

/****************************************************************************
DESCRIPTION
    This function allows the decoder information to be passed to the subwoofer and sharing
    functions
*/
DECODER_t * CsrA2dpDecoderGetDecoderData(void)
{
    return DECODER;
}

/****************************************************************************
DESCRIPTION
    This function returns the filename and path for the variant chosen
*/
static const char* csrA2dpDecoderGetKapFile(A2DP_DECODER_PLUGIN_TYPE_T variant)
{
    /* if using spdif input then use specific dsp app */
    if(DECODER->sink_type == AUDIO_SINK_SPDIF)
    {
        return "spdif_sink/spdif_sink.kap";
    }
    /* not using wired mode with spdif input */
    else
    {
        /* determine required dsp app based on variant required */
        switch (variant)
        {
        case SBC_DECODER:
        case TWS_SBC_DECODER:
        case FM_DECODER:
            return "sbc_decoder/sbc_decoder.kap";

        case MP3_DECODER:
        case TWS_MP3_DECODER:
            return "mp3_decoder/mp3_decoder.kap";

        case AAC_DECODER:
        case TWS_AAC_DECODER:
            return "aac_decoder/aac_decoder.kap";

        case APTX_DECODER:
        case TWS_APTX_DECODER:
            return "aptx_decoder/aptx_decoder.kap";

        /* aptx and faststream apps are now part of the low latency with optional
           back channel dsp apps, function is selectable at runtime */
        case APTX_ACL_SPRINT_DECODER:
        case FASTSTREAM_SINK:
               /* determine which kap file to load, 1 and 2 mic back channels
                   have their own dedicated apps, digital volume control is not
                   available in these apps, 16 steps of volume only */
                if(DECODER->features.use_one_mic_back_channel)
                    return "a2dp_low_latency_1mic/a2dp_low_latency_1mic.kap";
                else if(DECODER->features.use_two_mic_back_channel)
                    return "a2dp_low_latency_2mic/a2dp_low_latency_2mic.kap";
                /* when not using a back channel revert to standard dsp apps without
                   back channel support to give enhanced digital volume control */
                else
                {
                    if(variant == FASTSTREAM_SINK)
                        return "faststream_decoder/faststream_decoder.kap";
                    else
                        return "aptx_acl_sprint_decoder/aptx_acl_sprint_decoder.kap";
                }

        default:
            Panic();
            return NULL;
        }
    }
}

/****************************************************************************
DESCRIPTION
    This function connects a synchronous audio stream to the pcm subsystem
*/
void CsrA2dpDecoderPluginConnect( A2dpPluginTaskdata *task,
                                  Sink audio_sink ,
                                  AUDIO_SINK_T sink_type,
                                  Task codec_task ,
                                  uint16 volume ,
                                  uint32 rate ,
                                  AudioPluginFeatures features ,
                                  AUDIO_MODE_T mode ,
                                  const void * params,
                                  Task app_task)
{
    const char* kap_file;

    /* create malloc'd copy of audio connect parameters, free'd when audio plugin unloads */
    DECODER = (DECODER_t*)PanicUnlessMalloc (sizeof (DECODER_t) ) ;

    DECODER->task = task;
    DECODER->media_sink = audio_sink ;
    DECODER->forwarding_sink = NULL ;
    DECODER->packet_size = 0;
    DECODER->codec_task = codec_task ;

    /*  We use default values to mute volume on A2DP audio connection
        VM application is expected to send volume control right
        after attempting to establish A2DP media connection with the correct
        system and trim volume information along with master and tone volume
    */
    DECODER->volume.system_gain = CODEC_STEPS; /* st a default for DAC gain to allow tones to be heard before volume is set */
    DECODER->volume.tones_gain = volume; /* set the initial tones volume level */
    DECODER->volume.master_gain = DIGITAL_VOLUME_MUTE; /* -120dB , literally mute */
    DECODER->volume.trim_gain_left = 0; /* 0dB */
    DECODER->volume.trim_gain_right = 0; /* 0dB */
    DECODER->volume.device_trim_master = 0;
    DECODER->volume.device_trim_slave = 0;
    DECODER->device_trims_pending = FALSE;
    DECODER->volume.volume_type = DSP_VOLUME_CONTROL;
    DECODER->volume.mute_active = FALSE;
    
    DECODER->mode       = mode;
    DECODER->mode_params = 0;
    DECODER->features   = features;
    DECODER->params     = (uint16) params;
    DECODER->rate       = rate;
    DECODER->app_task   = app_task;
    DECODER->sink_type  = sink_type;

    DECODER->master_routing_mode = TWS_ROUTING_STEREO;
    DECODER->slave_routing_mode = TWS_ROUTING_STEREO;
    DECODER->routing_mode_change_pending = FALSE;
    DECODER->stream_relay_mode = RELAY_MODE_NONE;
    DECODER->relay_mode_change_pending = FALSE;
    
    DECODER->sbc_encoder_bitpool = 0;
    DECODER->sbc_encoder_format = 0;
    DECODER->sbc_encoder_params_pending = FALSE;
    
    DECODER->external_volume_enabled = FALSE;
   
    /* keep DAC gain in mute state until ports are connected to prevent pops and clicks */
    DECODER->dsp_ports_connected = FALSE;
    DECODER->DAC_Gain = CODEC_STEPS;
    
    /* get the filename of the kap file to load */
    kap_file = csrA2dpDecoderGetKapFile(task->a2dp_plugin_variant);

    /* Only need to read the PS Key value once */
    if (!pskey_read)
    {
        if (PsFullRetrieve(PSKEY_MAX_CLOCK_MISMATCH, &val_pskey_max_mismatch, sizeof(uint16)) == 0)
            val_pskey_max_mismatch = 0;
        pskey_read = TRUE;
    }

    /*ensure that the messages received are from the correct kap file*/
    (void) MessageCancelAll( (TaskData*) task, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( (TaskData*) task );

    /* audio busy until DSP returns ready message */
    SetAudioBusy((TaskData*)task);

    /* update current dsp status */
    SetCurrentDspStatus( DSP_LOADING );

    /* attempt to obtain file handle and load kap file, panic if not achieveable */
    PanicFalse(KalimbaLoad(PanicFalse(FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file)))));

    /* update current dsp status */
    SetCurrentDspStatus( DSP_LOADED_IDLE );

    if (((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant == AAC_DECODER) ||
        ((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant == TWS_AAC_DECODER))
    {
        /* Workaround for AAC+ sources that negotiate sampling frequency at half the actual value */
        if (rate < 32000)
            DECODER->rate = rate * 2;
    }

    /* For sinks disconnect the source in case its currently being disposed. */
    StreamDisconnect(StreamSourceFromSink(audio_sink), 0);

    /* set the DAC gain to mute to prevent any undesired clicks or pops, set to valid range after 
       DSP ports are connected */
    CsrA2DPDecoderSetDACGain(DAC_MUTE);

    PRINT(("DECODER: CsrA2dpDecoderPluginConnect completed\n"));
}

/****************************************************************************
DESCRIPTION
    Disconnect Sync audio
*/
void CsrA2dpDecoderPluginStartDisconnect(TaskData * task)
{

    PRINT(("DECODER: CsrA2dpDecoderPluginDisconnect start mute\n"));
    /* sample rate no longer valid as plugin is unloading, set to 0 to ensure subwoofer doesn't use it */
    DECODER->rate = 0;
    /* ensure nothing interrupts this sequence of events */
    SetAudioBusy((TaskData*) task);    
    /* start disconnect by muting output */
    DECODER->volume.master_gain = DIGITAL_VOLUME_MUTE; /* -120dB , literally mute */
    DECODER->volume.trim_gain_left = 0; /* 0dB */
    DECODER->volume.trim_gain_right = 0; /* 0dB */
    DECODER->volume.device_trim_master = 0;
    DECODER->volume.device_trim_slave = 0;
    DECODER->device_trims_pending = FALSE;

    /* set mute volume levels */
    CsrA2dpDecoderPluginSetLevels(&DECODER->volume, DECREASING, TRUE);                              

    /* sub is connected, use longer delay time to alow sub buffers to flush out to prevent pops */
    if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER)||(DECODER->stream_relay_mode == RELAY_MODE_TWS_SLAVE))
    {
        /* disconnect immediately when using TWS due to the need to keep the volumes synchronised between
           master and slave devices */
        MessageSend( task, AUDIO_PLUGIN_DISCONNECT_DELAYED_MSG, 0);       
    }
    /* not using TWS relay modes so apply soft volume ramp */
    else
    {
        MessageSendLater( task, AUDIO_PLUGIN_DISCONNECT_DELAYED_MSG, 0, MUTE_DISCONNECT_DELAY_WITH_SUB);
    }
}
/****************************************************************************
DESCRIPTION
    Disconnect Sync audio
*/
void CsrA2dpDecoderPluginDisconnect( A2dpPluginTaskdata *task )
{
    Source l_source, r_source;
    A2dpPluginConnectParams *codecData = NULL;

    if (!DECODER)
    {
        PRINT(("DECODER: CsrA2dpDecoderPluginDisconnect, nothing to disconnect\n"));
        return; /* nothing to disconnect */
    }
    
    codecData = (A2dpPluginConnectParams *) DECODER->params;

    /* now ok to set the DAC gain */
    CsrA2DPDecoderSetDACGain(DAC_MUTE);

    /* disconnect the subwoofer if currently connected */
    CsrA2dpDecoderPluginDisconnectSubwoofer();

    /* if using the microphone or spdif/i2s back channel */
    if(isCodecLowLatencyBackChannel())
    {
        /* check whether microphone back channel needs to be disconnected */
        CsrA2dpDecoderPluginDisconnectMic(codecData);
        /* reset the mic bias pio drive */
        AudioPluginSetMicPio(codecData->mic_params->mic_a, FALSE);
    }

    /* determine output type and disconnect it */
    switch(DECODER->features.audio_output_type)
    {
        /* no output type specified, default to DAC */
        case OUTPUT_INTERFACE_TYPE_NONE:
        /* using internal DAC's for audio output */
        case OUTPUT_INTERFACE_TYPE_DAC:
        {
            Sink audio_sink_a = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
            /* disconnect left channel */
            StreamDisconnect(0, audio_sink_a);
            SinkClose(audio_sink_a);
            /* if configured for stereo use, disconnect second mic and speaker channel B (right) */
            if(DECODER->features.stereo)
            {
                Sink audio_sink_b = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                /* disconnect right channel */
                StreamDisconnect(0, audio_sink_b);
                SinkClose(audio_sink_b);
            }
        }
        break;

        /* using i2s audio input */
        case OUTPUT_INTERFACE_TYPE_I2S:
        {
            /* if using I2S output */
            CsrI2SAudioOutputDisconnect(DECODER->features.stereo);
        }
        break;

        /* using spdif audio input */
        case OUTPUT_INTERFACE_TYPE_SPDIF:
        {
            /* obtain source to SPDIF hardware and disconnect it */
            Sink l_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
            Sink r_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
            StreamDisconnect(0, l_sink);
            SinkClose(l_sink);
            StreamDisconnect(0, r_sink);
            SinkClose(r_sink);
        }
        break;
    }

    /* determine input source from sink type and disconnect its ports */  
    switch(DECODER->sink_type)
    {
        case AUDIO_SINK_USB:
        case AUDIO_SINK_AV:
        {
            /* For sinks disconnect the source in case its currently being disposed. */
            StreamDisconnect(StreamSourceFromSink(DECODER->media_sink ), 0);
            StreamConnectDispose(StreamSourceFromSink(DECODER->media_sink));        
        }
        break;
 
        /* for analog input, determine the input routing and disconnect appropriate sources */
        case AUDIO_SINK_ANALOG:
        {    
            /* select input routing */
            switch(DECODER->features.audio_input_routing)
            {
                case AUDIO_ROUTE_INTERNAL_AND_RELAY:
                case AUDIO_ROUTE_INTERNAL:
                {
                    /* disconnect input A */
                    l_source = AudioPluginMicSetup(AUDIO_CHANNEL_A, codecData->mic_params->line_a, DECODER->rate);
                    StreamDisconnect(l_source, 0);
                    StreamConnectDispose(l_source);
                    /* if set for stereo use, disconnect the second input, mic/line B */
                    if(DECODER->features.stereo)
                    {
                        /* Configure analogue input B */
                        r_source = AudioPluginMicSetup(AUDIO_CHANNEL_B, codecData->mic_params->line_b, DECODER->rate);
                        StreamDisconnect(r_source, 0);
                        StreamConnectDispose(r_source);
                    }
                }
                break;

                /* using the I2S hardware for audio input */
                case AUDIO_ROUTE_I2S:
                {
                    l_source = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );
                    r_source = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0 );
                    StreamDisconnect(l_source, 0);
                    StreamConnectDispose(l_source);
                    StreamDisconnect(r_source, 0);
                    StreamConnectDispose(r_source);
                }
                break;
                
                default:
                break;
            }
        }
        break;

        /* disconnect the spdif sources */
        case AUDIO_SINK_SPDIF:
        {
            l_source = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
            r_source = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
            StreamDisconnect(l_source, 0);
            StreamConnectDispose(l_source);
            StreamDisconnect(r_source, 0);
            StreamConnectDispose(r_source);
        }
        break;

        /* disconnect FM i2s sources */
        case AUDIO_SINK_FM:
        {
            MusicDisconnectFM(codecData);
        }
        break;
        
        default:
        break;
    }

    /* disconnect forwarding sink if connected */
    CsrA2dpDecoderPluginDisconnectForwardingSink();

    /* Dispose of any outstanding audio forwarding messages */
    (void) MessageCancelAll((TaskData*) task, AUDIO_PLUGIN_START_FORWARDING_MSG);
    (void) MessageCancelAll((TaskData*) task, AUDIO_PLUGIN_STOP_FORWARDING_MSG);

     /* dispose of any outstanding volume/muting/fading messages */
    (void) MessageCancelAll((TaskData*) task, AUDIO_PLUGIN_ALLOW_VOLUME_CHANGES_MSG);    
    (void) MessageCancelAll((TaskData*) task, AUDIO_PLUGIN_SUBWOOFER_CONNECTION_TIMEOUT_MSG);  
    (void) MessageCancelAll((TaskData*) task, AUDIO_PLUGIN_DISCONNECT_DELAYED_MSG);  
    (void) MessageCancelAll((TaskData*) task, AUDIO_PLUGIN_DELAY_VOLUME_SET_MSG);  

     /* dispose of any remaining messages in the queue */
    (void) MessageCancelAll( (TaskData*) task, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( NULL );

    /* turn off dsp */
    KalimbaPowerOff() ;

    /* update current dsp status */
    SetCurrentDspStatus( DSP_NOT_LOADED );

    /* update the current audio state */
    SetAudioInUse(FALSE);
    SetAudioBusy(NULL);
    
    /* free plugin memory */
    free (DECODER);
    DECODER = NULL ;

    PRINT(("DECODER: CsrA2dpDecoderPluginDisconnect completed\n"));
}

/****************************************************************************
DESCRIPTION
    function to set the volume levels of the dsp after a preset delay
*/
void CsrA2dpDecoderPluginSetDspLevels(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T * VolumeMsg)
{
     PRINT(("DSP Hybrid Delayed Gains: System Gain = %d Master Gain = %d\n", VolumeMsg->system_gain, VolumeMsg->master_gain));

     /* set the dsp volume level */
     KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16*)VolumeMsg);   

     /* check the global mute state and ensure output remains muted if set */
     if(DECODER->volume.mute_active)
     { 
        /* mute dsp output */
        CsrA2dpDecoderPluginSetSoftMute(mute_sink_and_sub); 
     }
}

/****************************************************************************
DESCRIPTION
    function to set the volume levels of the appropriate volume control mechanism
*/
void CsrA2dpDecoderPluginSetLevels(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T * VolumeMsg, volume_change_direction_t direction, bool ForceSetVolume)
{
    int16 volume, tone_volume;
    A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;

    /* default DAC gain, this may change depending upon the volumt scheme chosen */
    DECODER->DAC_Gain = VolumeMsg->system_gain;
    
    /* determine if there is a subwoofer present, if it is present and the media stream is not
       yet present then leave volume in muted state, it will be unmuted when the subwoofer is present */
    if((!ForceSetVolume)&&(codecData->sub_is_available == TRUE)&&(!codecData->sub_connection_port))
    {
        /* a sub is available but it has yet to establish its media channel, hold the app in muted state
           until the sub channel is available and has been connected */
        PRINT(("DSP Set Levels - Sub available - wait for sub media\n"));
    }
    /* if no subwoofer connected and this is an initial volume set message sent from the vm then
       delay the setting of the volume to allow the dsp buffers to fill which allows a smooth
       fade in transistion of the audio, also don't change volume if in the middle of playing a tone otherwise
       a discrepancy will be heard */
    else if((!ForceSetVolume)&&((IsTonePlaying())||((codecData->sub_is_available == FALSE)&&(codecData->delay_volume_message_sending == TRUE))))
    {
        MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG ) ; 

        /* create message containing requested volume settings */
        memmove(message, &DECODER->volume, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T));       

        /* reschedule the volume setting to allow a full buffer of dsp data */                  
        MessageSendLater ( (TaskData *)DECODER->task , AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG, message, ALLOW_FULL_DSP_BUFFER_DELAY_FOR_SOFT_MUTE) ;

        PRINT(("DSP Set Levels - delay volume set - reschedule master= %d\n",DECODER->volume.master_gain));
    }
    /* not waiting for a subwoofer connection so set volume immediately */
    else
    {
        /* non-low latency applications use longer volume message which supports dsp digital
           volume control */
        if(isCodecLowLatencyBackChannel())
        {
            /* low latency apps using 16 levels of DAC volume control or I2S/SPDIF output */
    
            /* convert from dB values back to DAC gains */
            volume = (CODEC_STEPS + (DECODER->volume.master_gain/DB_TO_DAC));
            /* DAC gain only goes down to -45dB, dsp volume control goes to -60dB */
            if(volume <0) volume =0;
            /* set DAC gain */
            DECODER->DAC_Gain = volume;
            /* convert tones volume */
            tone_volume = (CODEC_STEPS + (DECODER->volume.tones_gain/DB_TO_DAC));
            if(tone_volume <0) tone_volume =0;
            /* send volume change message */
            KalimbaSendMessage(MUSIC_VOLUME_MSG, 0, 0, volume, tone_volume);        
    
            PRINT(("DSP LowLat Gains: Volume = %d TonesVol = %d\n", volume, tone_volume));
        }
        /* apps support digital volume control */
        else
        {
            /* if user has requested DAC volume control */
            if(VolumeMsg->volume_type == DAC_VOLUME_CONTROL)
            {
                /* convert dB master volume to DAC based system volume */
                volume = (CODEC_STEPS + (DECODER->volume.master_gain/DB_TO_DAC));
                /* DAC gain only goes down to -45dB, dsp volume control goes to -60dB */
                if(volume <0) volume =0;
                /* set system gain which will in turn be used to set the DAC gain via dsp message */
                VolumeMsg->system_gain = volume;
                /* set the master volume to full scale */
                VolumeMsg->master_gain = MAXIMUM_DIGITAL_VOLUME_0DB;
                /* set dsp volume levels */
                KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16*)VolumeMsg);
                /* update the device trim values */            
                csrA2dpDecoderSetDeviceTrims( VolumeMsg->device_trim_master, VolumeMsg->device_trim_slave );
                /* set DAC gain */
                DECODER->DAC_Gain = volume;
                
                PRINT(("DSP DAC Gains: System Gain = %d Master Gain = %d\n", VolumeMsg->system_gain, VolumeMsg->master_gain));
            }
            /* hybrid mixed volume control using both dac and dsp control */
            else if (VolumeMsg->volume_type == MIXED_VOLUME_CONTROL)
            {
                hybrid_gains_t gains;
                
                /* calculate the individual values for dsp gain (in dB) and dac gains */
                if(CodecCalcHybridValues(&gains, DECODER->volume.master_gain))
                {                                                
                    VolumeMsg->master_gain = gains.dsp_db_scaled;
                    VolumeMsg->system_gain = gains.dac_gain;
                            
                    /* if volume level is increasing, change dsp gain, wait a little then set DAC gain 
                       to prevent sudden changes in volume being heard */
                    if(direction == INCREASING)
                    {
                        /* set dsp gain */
                        KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16*)VolumeMsg);
                        /* set DAC gain a short while later */
                        CodecSetOutputGainLater(DECODER->codec_task, gains.dac_gain, left_and_right_ch, MIXED_MODE_INCREASING_DELAY);
                    }
                    /* if volume level is decreasing, change DAC gain, wait a little then set Dsp gain 
                       to prevent sudden changes in volume being heard */
                    else
                    {
                        MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG ) ; 
    
                        /* set DAC gain after a delay */
                        CodecSetOutputGainLater(DECODER->codec_task, gains.dac_gain, left_and_right_ch, MIXED_MODE_DECREASING_DELAY);
                       
                        message->master_gain = VolumeMsg->master_gain;
                        message->tones_gain = VolumeMsg->tones_gain;
                        message->system_gain = VolumeMsg->system_gain;
                        message->trim_gain_left = VolumeMsg->trim_gain_left;
                        message->trim_gain_right = VolumeMsg->trim_gain_right;
                        message->volume_type = VolumeMsg->volume_type;
                        message->device_trim_master = VolumeMsg->device_trim_master;
                        message->device_trim_slave = VolumeMsg->device_trim_slave;
                        message->mute_active = VolumeMsg->mute_active;
                        
                        /* set dsp gain immediately to reduce surges in volume */                  
                        if(GetAudioPlugin())
                            MessageSend ( GetAudioPlugin() , AUDIO_PLUGIN_DELAY_VOLUME_SET_MSG, message ) ;
                        else
                            free(message);
                    }                               
                    PRINT(("DSP Hybrid Master Gain = %d DAC Gain = %d DSP Gain = %d\n", (DECODER->volume.master_gain), gains.dac_gain, (gains.dsp_db_scaled)));
                }
                else
                {
                    PRINT(("DSP Hybrid OUT OF RANGE Master Gain = %d DAC Gain = %d DSP Gain = %d\n", DECODER->volume.master_gain, gains.dac_gain, gains.dsp_db_scaled));                
                }        
            }
            /* volume scheme that allows external devices such as an I2S amplifier which allow volume control
               by I2C commands to make use of the increased volume resolution settings of the digital volume control
               configuration */
            else if (VolumeMsg->volume_type == EXTERNAL_VOLUME_CONTROL)
            {   
                /* Full external volume control */
                PRINT(("DSP Ext Vol:  System = %d  Master = %d  Left = %d  Right = %d  TrimM = %d  TrimS = %d\n", VolumeMsg->system_gain, VolumeMsg->master_gain,  VolumeMsg->trim_gain_left, VolumeMsg->trim_gain_right, VolumeMsg->device_trim_master, VolumeMsg->device_trim_slave));
    
                /* when in TWS mode send the volume information to the DSP, it will return a kalimba ext_vol message
                   that is used to synchronise volume on both TWS master and TWS slave */
                if ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) || (DECODER->stream_relay_mode == RELAY_MODE_TWS_SLAVE))
                {   
                    /* Give DSP volume info so that it may deliver a synchronised KALIMBA_MSG_EXTERNAL_VOLUME message */
                    PRINT(("DSP Ext Vol: TWS relay active\n"));
                    KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16*)VolumeMsg);
                    csrA2dpDecoderSetDeviceTrims( VolumeMsg->device_trim_master, VolumeMsg->device_trim_slave );
                }
                /* non TWS use cases */
                else
                {   
                    /* Running standalone (or in ShareMe mode) thus all volume levels only affect local device and synchronisation is not supported */
                    PRINT(("DSP Ext Vol: TWS relay NOT active\n"));
                    
                    /* for I2S output that supports volume control by I2C interface, send the dB value
                       of the master gain +_ device trims to I2S plugin */
                    if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
                    {
                        PRINT(("CsrI2SAudioOutputSetVolume\n"));
                        CsrI2SAudioOutputSetVolume(DECODER->features.stereo, (VolumeMsg->master_gain + VolumeMsg->trim_gain_left), (VolumeMsg->master_gain + VolumeMsg->trim_gain_right), TRUE);
                    }
                    /* built in audio output hardware */
                    else if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_SPDIF)
                    {     
                        /* add some form of extra codec volume control here for SPDIF output if required */
                    }
                    
                    /* DSP needs to be set to pass audio un-attenuated. 
                       Tones are mixed and might want to be attenuated.
                       System volume can be used to drive on-board DACs, if required */
                    VolumeMsg->master_gain = MAXIMUM_DIGITAL_VOLUME_0DB;
                    VolumeMsg->trim_gain_left = 0;
                    VolumeMsg->trim_gain_right = 0;
                    KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16*)VolumeMsg);
                    /* MUSIC_CODEC_MSG will arrive from DSP and be a suitable point to apply any on-board DAC gains as well as drive external amp */
                }
            }
            /* dsp only volume control */
            else
            {
                PRINT(("DSP Dig Vol:  System = %d  Master = %d  Tone = %d Left = %d  Right = %d  TrimM = %d  TrimS = %d\n", VolumeMsg->system_gain, VolumeMsg->master_gain, VolumeMsg->tones_gain, VolumeMsg->trim_gain_left, VolumeMsg->trim_gain_right, VolumeMsg->device_trim_master, VolumeMsg->device_trim_slave));
    
                /* for I2S output that supports volume control by I2C interface, send the dB value
                   of the master gain +_ device trims to I2S plugin */
                if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
                {
                    PRINT(("CsrI2SAudioOutputSetVolume\n"));
                    CsrI2SAudioOutputSetVolume(DECODER->features.stereo, VolumeConvertDACGainToDB(VolumeMsg->system_gain), VolumeConvertDACGainToDB(VolumeMsg->system_gain), TRUE);
                }         
                
                /* set dsp volume levels */
                KalimbaSendLongMessage(MUSIC_VOLUME_MSG, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T), (const uint16*)VolumeMsg);
                csrA2dpDecoderSetDeviceTrims( VolumeMsg->device_trim_master, VolumeMsg->device_trim_slave );
    
                /* set DAC gain */
                DECODER->DAC_Gain = VolumeMsg->system_gain;
            }
        }
    
        /* set the DAC gain for volume schemes of DAC and digital, excluding hybrid, external (I2S) and TWS,
           don't do this until the dsp ports are connected otherwise a pop/click will be heard */
        if(DECODER->dsp_ports_connected)
        {   
            PRINT(("CodecSetOutputGainNow = %x\n", DECODER->DAC_Gain));
            CsrA2DPDecoderSetDACGain(DECODER->DAC_Gain);           
        }
        else
        {
            PRINT(("CodecSetOutputGainNow Fail vol type=%x op type=%x tws=%x\n",VolumeMsg->volume_type
                                                                               ,DECODER->features.audio_output_type,
                                                                               ((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER)||(DECODER->stream_relay_mode == RELAY_MODE_TWS_SLAVE))));
        }
    }

    /* check the global mute state and ensure output remains muted if set */
    if(DECODER->volume.mute_active)
    {
        /* mute dsp output */
        CsrA2dpDecoderPluginSetSoftMute(mute_sink_and_sub); 
    }   
}
        
/****************************************************************************
DESCRIPTION
    Indicate the volume has changed
*/
void CsrA2dpDecoderPluginSetVolume(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T *volumeDsp)
{
    if (DECODER && volumeDsp)
    {
        volume_change_direction_t dir = DECREASING;

        /* detemine direction of volume change */
        if(volumeDsp->master_gain > DECODER->volume.master_gain)
        {
            dir = INCREASING;
        }

        /* update stored volume levels */
        memmove(&DECODER->volume, volumeDsp, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T));
        
        PRINT(("DSP Gains : \nMute = %d\nMaster Gain = %d\nTones Gain = %d\nSystem Gain = %d\nLeft Trim Gain = %d\nRight Trim Gain = %d\n", volumeDsp->mute_active, volumeDsp->master_gain, volumeDsp->tones_gain, volumeDsp->system_gain,
                volumeDsp->trim_gain_left, volumeDsp->trim_gain_right));

        /* set the volume levels according to volume control type */
        CsrA2dpDecoderPluginSetLevels(volumeDsp, dir, FALSE);
    }
}

/****************************************************************************
DESCRIPTION
    reset the volume levels to that stored in the plugin
*/
void CsrA2dpDecoderPluginResetVolume(void)
{
    /* Return to last set plug-in volume values */
    MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG ) ; 

    /* create volume message contents */
    memmove(message, &DECODER->volume, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T));

    PRINT(("ResetVol :\nMaster Gain = %d\nTones Gain = %d\nSystem Gain = %d\nLeft Trim Gain = %d\nRight Trim Gain = %d\n", message->master_gain, message->tones_gain, message->system_gain, message->trim_gain_left, message->trim_gain_right));

    /* set dsp gain immediately to reduce surges in volume */                  
    if(GetAudioPlugin())
        MessageSend ( GetAudioPlugin() , AUDIO_PLUGIN_DELAY_VOLUME_SET_MSG, message ) ;
}

/****************************************************************************
DESCRIPTION
    Set the soft mute state for the sink / subwoofer
    Digital Mute L&R output of sink DSP
    Digital Mute Subwoofer output of sink DSP
*/
void CsrA2dpDecoderPluginSetSoftMute(AUDIO_SOFT_MUTE_TYPE_T mute_type)
{
    /* Ensure the mute type supplied is valid, otherwise ignore the bad request */
    switch(mute_type)
    {
        case unmute_sink_and_sub:
        case mute_sink_not_sub:
        case mute_sub_not_sink:
        case mute_sink_and_sub:
        {
            PRINT(("MUTE TYPE [%x] applied\n", mute_type));
            KalimbaSendMessage(LOW_LATENCY_SOFT_MUTE, mute_type, 0, 0, 0);
        }
        break;
        default:
        {
            PRINT(("MUTE TYPE [%x] Not valid - Soft mute request ignored\n", mute_type));
        }
    }
}

/****************************************************************************
DESCRIPTION
    Sets the audio mode
*/
void CsrA2dpDecoderPluginSetMode ( AUDIO_MODE_T mode , A2dpPluginTaskdata *task , const void * params )
{
    A2dpPluginModeParams *mode_params = NULL;
    A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
    A2DP_MUSIC_PROCESSING_T music_processing = A2DP_MUSIC_PROCESSING_PASSTHROUGH;

    if (!DECODER)
        Panic() ;

    /* mode not already set so set it */
    DECODER->mode = mode;

    /* check whether any operating mode parameters were passed in via the audio connect */
    if (params)
    {
        /* if mode parameters supplied then use these */
        mode_params = (A2dpPluginModeParams *)params;
        music_processing = mode_params->music_mode_processing;
        DECODER->mode_params = (uint16)params;
    }
    /* no operating mode params were passed in, use previous ones if available */
    else if (DECODER->mode_params)
    {
        /* if previous mode params exist then revert to back to use these */
        mode_params = (A2dpPluginModeParams *)DECODER->mode_params;
        music_processing = mode_params->music_mode_processing;
    }

    /* determine if this is the low latency back channel application using either aptx ll or faststream */
    if(isCodecLowLatencyBackChannel())
    {
        /* set the mode for the low latency codec types */
        CsrA2dpDecoderPluginSetLowLatencyMode(mode, task, mode_params, music_processing);
    }
    /* standard latency codecs including USB and WIRED (analogue/spdif) inputs */
    else
    {
        /* determine current operating mode */
        switch (mode)
        {
            /* speaker is muted, dsp mute function to ensure a quick glitch free muting effect */
            case AUDIO_MODE_MUTE_SPEAKER:
            case AUDIO_MODE_MUTE_BOTH:
                {
                    PRINT(("DECODER: Mute Output\n" ));
                    /* mute DSP output */
                    CsrA2dpDecoderPluginSetSoftMute(mute_sink_and_sub);
                    /* update current plugin mute state */
                    DECODER->volume.mute_active = TRUE;
                }
                break ;
                
            /* unmute the dsp output */
            case AUDIO_MODE_UNMUTE_SPEAKER:
                {
                    PRINT(("DECODER: UnMute Output\n" ));
                    /* unmute DSP output */
                    CsrA2dpDecoderPluginSetSoftMute(unmute_sink_and_sub);
                    /* update current plugin mute state */
                    DECODER->volume.mute_active = FALSE;
                }
                break;
                
            /* no mute required */
            case AUDIO_MODE_CONNECTED:
            case AUDIO_MODE_MUTE_MIC:
                {
                    /* ensure mode_params has been set before use */
                    if(mode_params)
                    {
                        /* Setup routing mode for both Master and Slave TWS devices */
                        csrA2dpDecoderSetTwsRoutingMode(mode_params->master_routing_mode, mode_params->slave_routing_mode);
                        
                        /* if using the microphone or spdif/i2s back channel */
                        if((mode != AUDIO_MODE_MUTE_MIC)&&(isCodecLowLatencyBackChannel()))
                        {
                            /*If Mic has been muted, then unmute , as this functionality is
                             not supported by DSP,Directly controlling the mic*/
                            CsrA2dpDecoderPluginMuteMic(codecData, (A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant, mode_params);
                        }

                        /* when sub woofer is enabled and a sub link is connected, put dsp into bassmanagement mode */
                        if(codecData->sub_woofer_type == AUDIO_SUB_WOOFER_NONE)
                        {
                            /* set the current EQ mode of operation */
                            if(DECODER->features.stereo)                               
                                CsrA2dpDecoderPluginSetEqMode(MUSIC_SYSMODE_FULLPROC, music_processing, mode_params);
                            else
                                CsrA2dpDecoderPluginSetEqMode(MUSIC_SYSMODE_FULLPROC_MONO, music_processing, mode_params);
                        }
                        else
                        {
                            /* set the current EQ mode of operation */
                            if(DECODER->features.stereo)                               
                                CsrA2dpDecoderPluginSetEqMode(MUSIC_SYSMODE_BASSMANAGEMENT, music_processing, mode_params);
                            else                            
                                CsrA2dpDecoderPluginSetEqMode(MUSIC_SYSMODE_BASSMANAGEMENT_MONO, music_processing, mode_params);                            
                        }


                        /* update the audio enhancements settings */
                        CsrA2dpDecoderPluginUpdateEnhancements(mode_params);
                    }
                }
                break;
            default:
                {
                    PRINT(("DECODER: Set Audio Mode Invalid [%x]\n" , mode ));
                }
                break;
        }
    }
}

/****************************************************************************
DESCRIPTION
    plays a tone using the audio plugin
*/
void CsrA2dpDecoderPluginPlayTone ( A2dpPluginTaskdata *task, ringtone_note * tone, Task codec_task, uint16 tone_volume, bool stereo)
{
    Source lSource ;
    Sink lSink ;
  
    if (DECODER)
    {
        PRINT(("DECODER: Tone Start, volume [%d]\n", tone_volume)) ;
    
        /* update current tone playing status */
        SetTonePlaying(TRUE);
        
        /* Configure prompt playback, tone is mono*/    
        KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, 8000 , 0/*Mono Bit 0 =0, TONE BIT 1 = 0*/, 0, 0); 
    
        /* mix the tone via the kalimba tone mixing port */
        lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) ;
    
        /*request an indication that the tone has completed / been disconnected*/
        MessageSinkTask ( lSink , (TaskData*) task ) ;
    
        /*connect the tone*/
        lSource = StreamRingtoneSource ( (const ringtone_note *) (tone) ) ;
    
        /*mix the tone to the SBC*/
        StreamConnectAndDispose( lSource , lSink ) ;
    }
    /* not valid to play tone at this time, clear busy flag */
    else
        SetAudioBusy(FALSE);
}

/****************************************************************************
DESCRIPTION
    Stop a tone from currently playing
*/
void CsrA2dpDecoderPluginStopTone ( void )
{
    PRINT(("DECODER: Stop Tone\n")) ;
    if (!DECODER)
        Panic() ;

     StreamDisconnect ( 0 , StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) ) ;

    /* update current tone playing status */
    SetTonePlaying(FALSE);

}

/****************************************************************************
DESCRIPTION
    Reconnects the audio after a tone has completed
*/
void CsrA2dpDecoderPluginToneComplete ( void )
{
    PRINT(("DECODER: Tone Complete\n")) ;

    /* ensure plugin hasn't unloaded before dsp message was received */
    if(DECODER)
    {
        /*we no longer want to receive stream indications*/
        MessageSinkTask ( StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) , NULL) ;
    
        /* update current tone playing status */
        SetTonePlaying(FALSE);
    }
}


/****************************************************************************
DESCRIPTION
    handles the internal cvc messages /  messages from the dsp
*/
void CsrA2dpDecoderPluginInternalMessage( A2dpPluginTaskdata *task ,uint16 id , Message message )
{
    /* determine codec type as message id's are different */
    if(isCodecLowLatencyBackChannel())
    {
        /* different message handler for low latency codec types as message id's are different */
        CsrA2dpDecoderPluginLowLatencyInternalMessage(task , id , message);
    }
    /* non low latency codec types use different message id's */
    else
    {
        /* dsp message handler, determine message id */
        switch(id)
        {
           /* message validity check */
           case MESSAGE_FROM_KALIMBA:
           {
               const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
                PRINT(("DECODER: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));

                switch ( m->id )
                {
#ifndef KOOVOX        
					/* send the heart rate msg to app task */
					case (HEART_RATE_MSG):
					{
						uint8* msg = PanicUnlessMalloc(sizeof(DSP_REGISTER_T));
						memcpy(msg, m, sizeof(DSP_REGISTER_T));
						PRINT(("message from dsp\n"));
						MessageSend(DECODER->app_task, EVENT_DSP_MESSAGE, msg);
					}
					break;
#endif
					
                    /* indication that the dsp is loaded and ready to accept configuration data */
                    case MUSIC_READY_MSG:
                        {
                            if (DECODER)
                            {
                                A2DP_DECODER_PLUGIN_TYPE_T variant;
                                A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;

                                /* Override the variant if using a USB or wired connection */
                                switch(DECODER->sink_type)
                                {
                                    case AUDIO_SINK_USB:
                                        variant = USB_DECODER;
                                    break;

                                    case AUDIO_SINK_FM:
                                    case AUDIO_SINK_ANALOG:
                                        variant = ANALOG_DECODER;
                                    break;

                                    case AUDIO_SINK_SPDIF:
                                        variant = SPDIF_DECODER;
                                    break;

                                    default:
                                        /* Use the (default) variant from task structure */
                                        variant = task->a2dp_plugin_variant;
                                    break;
                                }

                                /* Tell the DSP what plugin type is being used */
                                if(!KalimbaSendMessage(MUSIC_SET_PLUGIN_MSG, getDspVariant(variant), 0, 0, 0))
                                {
                                    PRINT(("DECODER: Message MUSIC_SET_PLUGIN_MSG failed!\n"));
                                    Panic();
                                }
                                PRINT(("DECODER: Message MUSIC_SET_PLUGIN_MSG variant = %x\n",variant));

                                /* load configuration parameters from ps, different for low latency variants */
                                /* pskey base address */
                                KalimbaSendMessage(MUSIC_LOADPARAMS_MSG, MUSIC_PS_BASE, 0, 0, 0);

                                /* Set silence detection params for Soundbar*/
                                if(codecData->is_for_soundbar)
                                {
                                    PRINT(("DECODER: Message SILENCE_DETECTION_PARAMS_MSG \n"));
                                    PRINT(("Threshold %x, Timeout %x\n", codecData->silence_threshold, codecData->silence_trigger_time));
                                    KalimbaSendMessage(MUSIC_SILENCE_DETECTION_PARAMS_MSG, codecData->silence_threshold, codecData->silence_trigger_time, 0, 0);
                                }

                                /* update current dsp status */
                                SetCurrentDspStatus( DSP_LOADED_IDLE );
                                
                                /* hold off setting VM app volume until dsp has full buffer of data to allow
                                   a smooth transitional fade in */
                                if ((DECODER->stream_relay_mode != RELAY_MODE_TWS_MASTER)&&(DECODER->stream_relay_mode != RELAY_MODE_TWS_SLAVE))
                                {
                                    /* delay the setting of the volume to allow smooth volume ramping */
                                    codecData->delay_volume_message_sending = TRUE;   
                                }
                                /* for TWS use case disable the delayed volume changes to maintain TWS volume synchronisation */
                                else
                                {
                                    /* don't delay volume changes, smooth volume ramping is disabled for TWS */
                                    codecData->delay_volume_message_sending = FALSE;   
                                }
                                /* subwoofer not connected yet */                                
                                codecData->sub_connection_port = 0;
                            }
                            else
                            {
                                /* update current dsp status */
                                SetCurrentDspStatus( DSP_ERROR );
                            }
                        }
                        break;

                    /* confirmation of the configuration data having been processed, ok to connect audio now */
                    case MUSIC_PARAMS_LOADED_MSG:
                        {
                            if (DECODER)
                            {
                                /* send status message to app to indicate dsp is ready to accept data,
                                   applicable to A2DP media streams only */
                                MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_READY_FOR_DATA, 0);
                                PRINT(("DECODER: Send CLOCK_MISMATCH_RATE\n"));
                                message->plugin = (TaskData *)task;
                                message->AUDIO_BUSY = (uint16)IsAudioBusy();
                                message->dsp_status = GetCurrentDspStatus();
                                message->media_sink = DECODER->media_sink;
                                MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_READY_FOR_DATA, message);
                                /* A2dp is now loaded, signal that tones etc can be scheduled*/
                                SetAudioBusy( NULL ) ;
                                PRINT(("DECODER: DECODER_READY \n"));
                                /* set initial volume levels to mute, ensure this happens regardless of sub connection state */
                                DECODER->volume.master_gain = DIGITAL_VOLUME_MUTE;                               
                                CsrA2dpDecoderPluginSetLevels(&DECODER->volume, INCREASING, TRUE);
                                /* connect the dsp ports to the audio streams */
                                MusicConnectAudio (task);                                
                                /* update current dsp status */
                                SetCurrentDspStatus( DSP_RUNNING );
                                /* If correctly configured, turn on latency reporting */
                                enableLatencyReporting(task);
                                /* disable soft volume ramping for TWS as needs too maintain volume level syncronisation
                                   between master and slave units */
                                if ((DECODER->stream_relay_mode != RELAY_MODE_TWS_MASTER)&&(DECODER->stream_relay_mode != RELAY_MODE_TWS_SLAVE))
                                {
                                    /* send message to release the lock on processing VM volume changes */
                                    MessageSendLater((TaskData *)DECODER->task, AUDIO_PLUGIN_ALLOW_VOLUME_CHANGES_MSG, 0 , ALLOW_FULL_DSP_BUFFER_DELAY_FOR_SOFT_MUTE);
                                    /* set a subwoofer port connection failure timeout */                                    
                                    MessageSendLater((TaskData *)DECODER->task, AUDIO_PLUGIN_SUBWOOFER_CONNECTION_TIMEOUT_MSG, 0 , SUBWOOFER_CONNECTION_FAILURE_TIMEOUT);                               
                                }
                            }
                            else
                            {
                                /* update current dsp status */
                                SetCurrentDspStatus( DSP_ERROR );
                            }
                        }
                        break;


                    /* dsp confirmation that a volume change has been processed */
                    case MUSIC_CODEC_MSG:
                        {
                            uint16 lOutput_gain_l = m->a;
                            uint16 lOutput_gain_r = m->b;

                            PRINT(("DECODER: MUSIC_CODEC_MSG  left=%u  right=%u\n",lOutput_gain_l,lOutput_gain_r));
                            
                            if (DECODER)
                            {
                                /* when using TWS with external volume control it is necessary to wait for the
                                   MUSIC_CODEC_MESSAGE before sending the volume change to the external codec
                                   to allow synchronisation of the volume changes on both TWS master and slave
                                   devices */
                                if((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER) || (DECODER->stream_relay_mode == RELAY_MODE_TWS_SLAVE))
                                {
                                    /* when using external volume control mechanism, send the master gain + trim
                                       values to the external codec */
                                    if (DECODER->volume.volume_type == EXTERNAL_VOLUME_CONTROL) 
                                    {   
                                        PRINT(("EXTERNAL_VOLUME_CONTROL\n"));
                                          
                                        /* when using the I2S audio output hardware */
                                        if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
                                        {
                                            PRINT(("CsrI2SAudioOutputSetVolume\n"));
                                            CsrI2SAudioOutputSetVolume(DECODER->features.stereo, (DECODER->volume.master_gain + DECODER->volume.trim_gain_left) , (DECODER->volume.master_gain + DECODER->volume.trim_gain_right), TRUE);
                                        }
                                        /* built in audio output hardware */
                                        else if(DECODER->features.audio_output_type != OUTPUT_INTERFACE_TYPE_SPDIF)
                                        {
                                        }
                                    }
                                    /* for DAC or DSP volume control, set the codec gain */
                                    else if (DECODER->volume.volume_type != MIXED_VOLUME_CONTROL)
                                    { 
                                        PRINT(("CodecSetOutputGainNow\n"));
                                        CodecSetOutputGainNow(DECODER->codec_task, lOutput_gain_l, left_ch);
                                        CodecSetOutputGainNow(DECODER->codec_task, lOutput_gain_r, right_ch);
                                    }
                                }
                            }
                        }
                        break;

                    /* dsp status information gets sent to the vm app */
                    case KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE:
                        {
                            if (DECODER)
                            {
                                MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_IND, 1);
                                PRINT(("DECODER: Send CLOCK_MISMATCH_RATE\n"));
                                message->id = KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE;
                                message->size_value = 1;
                                message->value[0] = m->a;
                                MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_IND, message);
                            }
                        }
                        break;

                    case MUSIC_CUR_EQ_BANK:
                        /* DSP tells plugin which EQ is active.  Send this value to the VM app
                           so the current EQ setting can be restored when the device is repowered.
                        */
                        {
                            if (DECODER)
                            {
                                MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_IND, 1);
                                PRINT(("DECODER: Current EQ setting: [%x][%x]\n", m->a, m->b));
                                message->id = A2DP_MUSIC_MSG_CUR_EQ_BANK;
                                message->size_value = 1;
                                message->value[0] = m->a;
                                MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_IND, message);
                            }
                        }
                        break;

                    case MUSIC_SETCONFIG_RESP:
                        /* DSP tells plugin which audio enhancements are active.  Send this value
                           to the VM app so the current enhancements setting can be restored when
                           the device is repowered.
                        */
                        {
                            if (DECODER)
                            {
                                MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_IND, 2);
                                PRINT(("DECODER: Enhancements setting: [%x][%x]\n", m->a, m->b));
                                message->id = A2DP_MUSIC_MSG_ENHANCEMENTS;
                                message->size_value = 2;
                                message->value[0] = m->a;
                                message->value[1] = m->b;
                                MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_IND, message);
                            }
                        }
                        break;

                    case APTX_SECPASSED_MSG:
                        PRINT(("aptX: Security passed.\n"));
                        KalimbaSendMessage(APTX_SECURITY_MSG, 1, 0, 0, 0);
                        break;

                    case APTX_SECFAILED_MSG:
                      PRINT(("aptX: Security failed.\n"));
                      KalimbaSendMessage(APTX_SECURITY_MSG, 0, 0, 0, 0);
                      break;

                    case MUSIC_SIGNAL_DETECTOR_STATUS_RESP:
                        /* DSP tells when signal detector status has changed
                        Param1 == 0 => no audio - go into standby
                        Param1 == 1 => receiving audio - come out of standby
                        "no audio" message is sent when signal level has been below the
                        threshold level for the trigger time out period "receiving audio"
                        message is sent as soon as a signal is detected above the threshold level
                        */

                        {
                            A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
                            uint16 signal = m->a;
                            PRINT(("SIGNAL_DETECTOR_STATUS_RESP: PARAM1 %x \n", signal));

                            /* Need to do only for Soundbar*/
                            if(codecData->is_for_soundbar)
                            {
                                if (signal)
                                {
                                    /* Signal detected come out of standby */
                                    PioCommonSetPin( codecData->speaker_pio, pio_drive, TRUE);
                                    /* unmute the output */
                                    CsrA2dpDecoderPluginSetSoftMute(unmute_sink_and_sub);
                                }
                                else
                                {
                                    /* no audio go into standby */
                                    PioCommonSetPin(codecData->speaker_pio, pio_drive, FALSE);
                                    /* mute the output */
                                    CsrA2dpDecoderPluginSetSoftMute(mute_sink_and_sub);
                                }
                            }
                        }
                        break;

                    case KALIMBA_MSG_LATENCY_REPORT:
                    {   /* DSP has sent us an audio latency measurement */
                        if (DECODER)
                        {
                        	CsrA2dpDecoderPluginSetAudioLatency(task, m->a);
                        }
                    }
                    break;

                    case KALIMBA_MSG_RELAY_MODE_RESP:
                    {   /* DSP has acknowledged the Relay Mode request */
                        PRINT(("KALIMBA_MSG_RELAY_MODE_RESP: %x\n", m->a));
                        streamRelayModeUpdated(m->a);
                    }
                    break;

                    case KALIMBA_MSG_CBOPS_SILENCE_CLIP_DETECT_CLIP_DETECTED_ID:
                    {
                        PRINT(("\n\n\n\n\nInput level clipped.\n"));
                    }
                    break;


                    case KALIMBA_MSG_CBOPS_SILENCE_CLIP_DETECT_SILENCE_DETECTED_ID:
                    {
                        PRINT(("\n\n\n\n\nInput level silence.\n"));
                    }
                    break;

                    /* message sent from DSP with SPDIF information including the calculated sample rate
                       of current stream, VM doesn't need to do anything with the sample rate as the DSP
                       talks directly to the firmware */
                    case KALIMBA_MSG_DSP_SPDIF_EVENT_MSG:
                    {
                        uint16 invalid = m->a;

                        /* check whether status information is valid before processing further */
                        if(!invalid)
                        {
                            PRINT(("SPDIF status message sample rate = %x \n", m->b));
                        }
                        else
                        {
                            PRINT(("SPDIF status message is invalid \n"));
                        }
                    }
                    break;

                    case DSP_GAIA_MSG_GET_USER_PARAM_RESP:
                    {
                        MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_GAIA_EQ_MSG, 2);
                        PRINT(("DECODER: User EQ Param from DSP: [%x][%x]\n", m->a, m->b));
                        message->size_value = 2;
                        message->value[0] = m->a;
                        message->value[1] = m->b;
                        MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_GAIA_EQ_MSG, message);
                    }
                    break;
                    
                    /* message from DSP when tone has completed playing */
                    case MUSIC_TONE_COMPLETE:
                    {
                        /*the tone has completed*/  
                      	SetAudioBusy(NULL) ;
                        /* stop tone and clear up status flags */
                        CsrA2dpDecoderPluginToneComplete() ; 
                    }
                }
            }
            break;

            case MESSAGE_FROM_KALIMBA_LONG:
            {
                /* recast message as this is a long message from the DSP */
                const uint16 *rcv_msg = (const uint16*) message;

                switch ( rcv_msg[0] )
                {
                    case DSP_GAIA_MSG_GET_USER_GROUP_PARAM_RESP:
                        {
                            uint16 i;

                            MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_GAIA_GROUP_EQ_MSG, rcv_msg[1]);
                            PRINT(("DECODER: User EQ Group Param from DSP: [%x][%x]...\n", rcv_msg[2],rcv_msg[3]));
                            message->size_value = rcv_msg[1];
                            for(i=0;i<rcv_msg[1];i++)
                                message->value[i] = rcv_msg[i+2];
                            MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_GAIA_GROUP_EQ_MSG, message);
                        }
                        break;
                        
                    case KALIMBA_MSG_EXTERNAL_VOLUME:
                    {
                        AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T VolumeMsg;
                        
                        PRINT(("KALIMBA_MSG_EXTERNAL_VOLUME\n"));
                        
                        memset(&VolumeMsg, 0, sizeof(VolumeMsg));
                        VolumeMsg.system_gain = (uint16)rcv_msg[1];
                        VolumeMsg.master_gain = (int16)rcv_msg[2];
                        VolumeMsg.tones_gain = (int16)rcv_msg[3];
                        VolumeMsg.trim_gain_left = (int16)rcv_msg[4];
                        VolumeMsg.trim_gain_right = (int16)rcv_msg[5];
                        /* Device trims have already been added to the left/right channel trims*/
                   
                        /* Now apply the system gain, if appropriate */
                        if (DECODER)
                        {
                            /* when using the I2S audio output hardware */
                            if( DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
                            {
                                CsrI2SAudioOutputSetVolume(DECODER->features.stereo, (VolumeMsg.master_gain +  VolumeMsg.trim_gain_left),(VolumeMsg.master_gain +  VolumeMsg.trim_gain_right), TRUE);
                            }
                            /* built in audio output hardware */
                            else if (DECODER->features.audio_output_type != OUTPUT_INTERFACE_TYPE_SPDIF)
                            {     
                                CodecSetOutputGainNow(DECODER->codec_task, VolumeMsg.system_gain, left_and_right_ch);
                            }
                        }
                    }
                }
            }

            default:
            break ;
        }
    }
}


/****************************************************************************
DESCRIPTION
    Connect the encoded audio input and pcm audio output streams
*/
void MusicConnectAudio (A2dpPluginTaskdata *task)
{
    A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
    A2dpPluginModeParams *mode_params = NULL;
    uint8 content_protection;
    uint16 scms_enabled = 0;
    Transform rtp_transform = 0;
    Sink speaker_snk_a = NULL;
    uint16 mismatch = val_pskey_max_mismatch;
    Source l_source = NULL;

    /* initialise the content protection and clock mismatch settings from pstore if available */
    if(codecData != NULL)
    {
        DECODER->packet_size = codecData->packet_size;
        val_clock_mismatch = codecData->clock_mismatch;
        content_protection = codecData->content_protection;
        if (codecData->mode_params != NULL)
            mode_params = codecData->mode_params;
    }
    /* otherwise initialise from scratch, the values will be relearnt and then stored */
    else
    {
        val_clock_mismatch = 0;
        content_protection = 0;
    }

    /* Attempt to connect any input (back channel) ports for sources such as USB/Wired or APTX/FASTSTREAM */
    switch(DECODER->sink_type)
    {
        /* for USB audio source, connect the back channel (input) port to dsp */
        case AUDIO_SINK_USB:
        {
            PRINT(("DECODER: USB Sink\n"));
            
            /* determine input type */
            switch(DECODER->features.audio_input_routing)
            {
                case AUDIO_ROUTE_INTERNAL_AND_RELAY:
                {   /* Encodes and then decodes audio locally, using SBC.  SBC encoded audio can also be relayed to another device */
                    PRINT(("DECODER:     AUDIO_ROUTE_INTERNAL_AND_RELAY  format=0x%X  bitpool=%u\n",codecData->format,codecData->bitpool));
                    csrA2dpDecoderSetSbcEncoderParams( codecData->bitpool, codecData->format );
                }
                /* **** Fall through to AUDIO_ROUTE_INTERNAL **** */
                
                /* using internal ADCs */
                case AUDIO_ROUTE_INTERNAL:
                {
                    PRINT(("DECODER:     AUDIO_ROUTE_INTERNAL\n"));
                    /* connect the USB audio to the dsp */
                    PanicFalse(StreamConnect(StreamSourceFromSink(DECODER->media_sink), StreamKalimbaSink(USB_AUDIO_TO_DSP_PORT)));
                    /* determine if USB has been configured to include a microphone back channel */
                    if(codecData)
                    {
                        /* Don't apply to USB - zero */
                        val_clock_mismatch = 0;
                        content_protection = 0;
                        /* If we have a USB Mic */
                        if(codecData->usb_params)
                        {
                            PRINT(("DECODER:         Back channel\n"));
                            /* Connect Mic -> KalSnk4, KalSrc2 -> USB(mic)*/
                            l_source = AudioPluginMicSetup(AUDIO_CHANNEL_A, codecData->mic_params->mic_a, DECODER->rate);
                            PanicFalse(StreamConnect(l_source, StreamKalimbaSink(USB_MIC_TO_DSP_PORT)));
                            PanicFalse(StreamConnect(StreamKalimbaSource(USB_DSP_TO_MIC_PORT), codecData->usb_params->usb_sink));
                        }
                    }
                }
                break;
            
                case AUDIO_ROUTE_I2S:
                case AUDIO_ROUTE_SPDIF:
                {   /* Not currently supported */
                }
                break;
            }
            
            csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
        }
        break;

        /* for wired input source, connect the back channel (input) port to dsp */
        case AUDIO_SINK_ANALOG:
        {
            PRINT(("DECODER: Analog/I2S Wired Sink\n"));

            /* determine input type */
            switch(DECODER->features.audio_input_routing)
            {
                case AUDIO_ROUTE_INTERNAL_AND_RELAY:
                {   /* Encodes and then decodes audio locally, using SBC.  SBC encoded audio can also be relayed to another device */
                    PRINT(("DECODER:     AUDIO_ROUTE_INTERNAL_AND_RELAY  format=0x%X  bitpool=%u\n",codecData->format,codecData->bitpool));
                    csrA2dpDecoderSetSbcEncoderParams( codecData->bitpool, codecData->format );
                }
                /* **** Fall through to AUDIO_ROUTE_INTERNAL **** */
                    
                /* using internal ADCs */
                case AUDIO_ROUTE_INTERNAL:
                {
                    PRINT(("DECODER:     AUDIO_ROUTE_INTERNAL\n"));
                    /* Configure analogue input A */
                    l_source = AudioPluginMicSetup(AUDIO_CHANNEL_A, codecData->mic_params->line_a, DECODER->rate);

                    /* if set for stereo use, configure the second in input, mic/line B */
                    if(DECODER->features.stereo)
                    {
                        /* Configure analogue input B */
                        Source r_source = AudioPluginMicSetup(AUDIO_CHANNEL_B, codecData->mic_params->line_b, DECODER->rate);
                        /* synchronise the two channels */
                        PanicFalse(SourceSynchronise(l_source, r_source));
                        /* connect mic/line B to the dsp */
                        PanicFalse(StreamConnect(r_source, StreamKalimbaSink(WIRED_LINE_B_TO_DSP_PORT)));
                        PRINT(("DECODER:         Stereo Input\n"));
                    }
                    /* connect mic/line A to the dsp */
                    PanicFalse(StreamConnect(l_source, StreamKalimbaSink(WIRED_LINE_A_TO_DSP_PORT)));
                }
                break;

                /* using the I2S hardware for audio input */
                case AUDIO_ROUTE_I2S:
                {
                    PRINT(("DECODER:     AUDIO_ROUTE_I2S\n"));
                    /* connect the I2S input */
                    CsrI2SAudioInputConnect(DECODER->rate, DECODER->features.stereo, StreamKalimbaSink(WIRED_LINE_A_TO_DSP_PORT), StreamKalimbaSink(WIRED_LINE_B_TO_DSP_PORT) );
                }
                break;
                
                default:
                break;
            }
            /* don't apply the stored values to a WIRED input */
            val_clock_mismatch = 0;
            content_protection = 0;
            /* disable rate matching for wired input */
            mismatch |= MUSIC_RATE_MATCH_DISABLE;
            
            csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
        }
        break;
        
        /* for spdif input source, connect the back channel (input) port to dsp */
        case AUDIO_SINK_SPDIF:
        {
            /* obtain source to SPDIF hardware */
            Source r_source = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
            l_source = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );

            PRINT(("DECODER: spdif Wired Sink\n"));

            /* when configured for tws audio sharing */
            switch(DECODER->features.audio_input_routing)
            {
                case AUDIO_ROUTE_INTERNAL_AND_RELAY:
                {   /* Encodes and then decodes audio locally, using SBC.  SBC encoded audio can also be relayed to another device */
                    PRINT(("DECODER:     AUDIO_ROUTE_INTERNAL_AND_RELAY  format=0x%X  bitpool=%u\n",codecData->format,codecData->bitpool));
                    csrA2dpDecoderSetSbcEncoderParams( codecData->bitpool, codecData->format );
                }
                
                default:
                break;
            }
            
            PRINT(("DECODER:     AUDIO_ROUTE_SPDIF\n"));
            /* configure the SPDIF interface operating mode, run in auto rate detection mode */
            PanicFalse(SourceConfigure(l_source, STREAM_SPDIF_AUTO_RATE_DETECT, TRUE));
            PanicFalse(SourceConfigure(l_source, STREAM_SPDIF_CHNL_STS_REPORT_MODE, TRUE));
            PanicFalse(SourceConfigure(r_source, STREAM_SPDIF_AUTO_RATE_DETECT, TRUE));
            PanicFalse(SourceConfigure(r_source, STREAM_SPDIF_CHNL_STS_REPORT_MODE, TRUE));

            /* synchronise the two channels */
            PanicFalse(SourceSynchronise(l_source, r_source));

            /* connect mic/line B to the dsp */
            PanicFalse(StreamConnect(r_source, StreamKalimbaSink(WIRED_LINE_B_TO_DSP_PORT)));

            /* connect mic/line A to the dsp */
            PanicFalse(StreamConnect(l_source, StreamKalimbaSink(WIRED_LINE_A_TO_DSP_PORT)));

            /* don't apply the stored values to a WIRED input */
            val_clock_mismatch = 0;
            content_protection = 0;
            /* disable rate matching for wired input */
            mismatch |= MUSIC_RATE_MATCH_DISABLE;
            
            csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
        }
        break;
                
        /* for BT connections, SBC,MP3,AAC,FASTREAM and APTX */
        case AUDIO_SINK_AV:
            PRINT(("DECODER: AV Sink\n"));

            /* determine the A2DP variant in use and see if a transform needs to be used */
            switch ((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant)
            {
                /* for SBC, start the SBC RTP transform on the incoming data and connect to dsp sink port 0 */
                case SBC_DECODER:
#ifdef SHAREME_SLAVE
                    StreamConnect(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#else
                    rtp_transform = TransformRtpSbcDecode(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#endif
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
                break;
                /* for MP3, start the MP3 RTP transform connection to dsp sink port 0 */
                case MP3_DECODER:
#ifdef SHAREME_SLAVE
                    StreamConnect(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#else
                    rtp_transform = TransformRtpMp3Decode(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#endif
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
                break;
                /* for AAC start the AAC RTP transform connecting to dsp sink port 0 */
                case AAC_DECODER:
#ifdef SHAREME_SLAVE
                    StreamConnect(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#else
                    rtp_transform = TransformRtpAacDecode(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
#endif
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
                break;
                /* for fastream data source */
                case FASTSTREAM_SINK:
                    /* connect dsp ports for the FASTSTREAM codec */
                    if (codecData)
                    {
                        MusicConnectFaststream(codecData);
                    }
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
                break;
                /* for APTX standard delay */
                case APTX_DECODER:
                    /* connect dsp ports for the standard APTX codec */
                    if (codecData)
                    {
                        MusicConnectAptx(codecData, content_protection);
                    }
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
                break;
                /* for APTX low delay */
                case APTX_ACL_SPRINT_DECODER:
                    /* connect dsp ports for low latency APTX codec */
                    if (codecData)
                    {
                        MusicConnectAptxLowLatency(codecData, content_protection);
                    }
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
                break;
                case TWS_SBC_DECODER:
                case TWS_MP3_DECODER:
                case TWS_AAC_DECODER:
                case TWS_APTX_DECODER:
                    /* TWS codecs do not use RTP.  Connect directly to DSP */
                    StreamConnect(StreamSourceFromSink(DECODER->media_sink) , StreamKalimbaSink(CODEC_TO_DSP_PORT));
                    csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_TWS_SLAVE);
                break;
               default:
               break;
            }
        break;

        /* for fm input source, connect the FM i2s input */
        case AUDIO_SINK_FM:
        {
            PRINT(("DECODER: FM Sink\n"));

            /* connect dsp ports for the FM */
            if (codecData)
            {
                MusicConnectFM(codecData);
            }
            /* no peer sharing */
            csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
            /* don't apply the stored values to an FM WIRED input */
            val_clock_mismatch = 0;
            content_protection = 0;
            /* disable rate matching for wired input */
            mismatch |= MUSIC_RATE_MATCH_DISABLE;
        }
        break;

        default:
            PRINT(("DECODER: Unsupported Sink\n"));
            Panic();
        break;
    }

    /* for audio sources that are not FASTSTREAM/APTX STD or APTX LD,
       connect dsp output ports here */
    if (((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant != FASTSTREAM_SINK)&&
        ((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant != FM_DECODER)&&
        ((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant != APTX_DECODER)&&
        ((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant != APTX_ACL_SPRINT_DECODER))
    {
        /* for sources that are NOT USB or WIRED, check the content protection requirements */
        /* No transform to configure for USB */
        if((DECODER->sink_type != AUDIO_SINK_USB)&&(DECODER->sink_type != AUDIO_SINK_SPDIF)&&
           (DECODER->sink_type != AUDIO_SINK_ANALOG)&&(DECODER->sink_type != AUDIO_SINK_FM)&&(rtp_transform))
        {
            /* Configure the content protection */
            if (content_protection)
                scms_enabled = 1;
            /* start or stop SCMS content protection */
            TransformConfigure(rtp_transform, VM_TRANSFORM_RTP_SCMS_ENABLE, scms_enabled);
            /*start the transform decode*/
            (void)TransformStart( rtp_transform ) ;
            PRINT(("DECODER: Transform started\n"));
        }

        /* determine the output hardware type */
        switch(DECODER->features.audio_output_type)
        {
            /* using the inbuilt dacs */
            case OUTPUT_INTERFACE_TYPE_NONE:
            case OUTPUT_INTERFACE_TYPE_DAC:
            {
                /* configure built-in audio hardware channel A */
                speaker_snk_a = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
                PanicFalse(SinkConfigure(speaker_snk_a, STREAM_CODEC_OUTPUT_RATE, DECODER->rate));                
                PanicFalse(SinkConfigure(speaker_snk_a, STREAM_AUDIO_MUTE_ENABLE, TRUE));
                 

                PRINT(("DECODER: OUTPUT_INTERFACE_TYPE_DAC  (rate=%lu)\n",DECODER->rate));
                /* if STEREO mode configured then connect the output channel B */
                if(DECODER->features.stereo)
                {
                    Sink speaker_snk_b = NULL;

                    PRINT(("DECODER:     Stereo\n"));

                    /* connect channels B */
                    speaker_snk_b = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                    /* configure channel to required rate */
                    PanicFalse(SinkConfigure(speaker_snk_b, STREAM_CODEC_OUTPUT_RATE, DECODER->rate));
                    PanicFalse(SinkConfigure(speaker_snk_b, STREAM_AUDIO_MUTE_ENABLE, TRUE));
                    /* synchronise both sinks for channels A & B */
                    PanicFalse(SinkSynchronise(speaker_snk_a, speaker_snk_b));
                    /* plug port 1 into Right DAC */
                    PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT),speaker_snk_a));
                    PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT),speaker_snk_b));
                    PanicFalse(SinkConfigure(speaker_snk_a, STREAM_AUDIO_MUTE_ENABLE, FALSE));
                    PanicFalse(SinkConfigure(speaker_snk_b, STREAM_AUDIO_MUTE_ENABLE, FALSE));
                }
                /* mono operation, only connect left port */
                else
                {
                    PRINT(("DECODER:     Mono\n"));
                    /* plug port 0 into Left DAC */
                    PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT),speaker_snk_a));
                    PanicFalse(SinkConfigure(speaker_snk_a, STREAM_AUDIO_MUTE_ENABLE, FALSE));
                }
            }
            break;

            /* using the spdif digital output hardware */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                Sink speaker_snk_b = NULL;
                /* configure spdif audio hardware channel 0 */
                speaker_snk_a = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
                speaker_snk_b = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
                PanicFalse(SinkConfigure(speaker_snk_a, STREAM_AUDIO_MUTE_ENABLE, TRUE));
                PanicFalse(SinkConfigure(speaker_snk_b, STREAM_AUDIO_MUTE_ENABLE, TRUE));
                /* configure channel to required rate */
                PanicFalse(SinkConfigure(speaker_snk_a,  STREAM_SPDIF_OUTPUT_RATE, DECODER->rate));
                PanicFalse(SinkConfigure(speaker_snk_b,  STREAM_SPDIF_OUTPUT_RATE, DECODER->rate));
                /* synchronise both sinks for channels A & B */
                PanicFalse(SinkSynchronise(speaker_snk_a, speaker_snk_b));
                /* plug port 1 into Right DAC */
                PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT),speaker_snk_a));
                PanicFalse(StreamConnect(StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT),speaker_snk_b));
                PanicFalse(SinkConfigure(speaker_snk_a, STREAM_AUDIO_MUTE_ENABLE, FALSE));
                PanicFalse(SinkConfigure(speaker_snk_b, STREAM_AUDIO_MUTE_ENABLE, FALSE));

                PRINT(("DECODER: OUTPUT_INTERFACE_TYPE_SPDIF  (rate=%lu)\n",DECODER->rate));
            }
            break;

            /* using the i2s digital output hardware */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {
                PRINT(("DECODER: OUTPUT_INTERFACE_TYPE_I2S\n"));
                /* is a specified output frequency required? use resampling*/
                if(CsrI2SMusicResamplingFrequency())
                    CsrI2SAudioOutputConnect(CsrI2SMusicResamplingFrequency(), DECODER->features.stereo, StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT), StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT));
                /* use the negotiated sample rate of the input, no resampling required */
                else
                    CsrI2SAudioOutputConnect(DECODER->rate, DECODER->features.stereo, StreamKalimbaSource(AUDIO_OUT_FROM_DSP_LEFT), StreamKalimbaSource(AUDIO_OUT_FROM_DSP_RIGHT));
            }
            break;
        }
    }
    /* for the low latency apps, connect the CVC back channel if 1 or two mic back channel has been defined */
    else if(isCodecLowLatencyBackChannel())

    {
        /* connect the one or two mics for back channel operation, if two mic is not defined it is assummed 1 mic */
        CsrA2dpDecoderConnectBackChannel(codecData, DECODER->features.use_two_mic_back_channel);
    }
    
    /* check to see if the subwoofer can be connected */
    CsrA2dpDecoderPluginConnectSubwoofer(codecData);
    
    /* DSP port now connected, ok to set DAC_GAIN, this eliminates the pop/clicks associated with port connection */
    DECODER->dsp_ports_connected = TRUE;
    
    /* now ok to set the DAC gain */
    CsrA2DPDecoderSetDACGain(DECODER->DAC_Gain);

    /* set the dsp into the correct operating mode with regards to mute and enhancements */
    CsrA2dpDecoderPluginSetMode(DECODER->mode, task, mode_params);

    /* when using wired input configured for spdif input, send the configuration message to the DSP */
    if(DECODER->sink_type == AUDIO_SINK_SPDIF)
    {
        uint8 resample_required = 0;

        /* is resampling of the output frequency for I2S required? */
        if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
        {
            if(CsrI2SMusicResamplingFrequency())
                resample_required = 1;
        }

        /* send message to DSP to configure the spdif app, the app will then auto detect the sample rate
           and inform the vm app of the current rate via a message */
        if(!KalimbaSendMessage(MESSAGE_SET_SPDIF_CONFIG_MSG,
                               ((DECODER->features.spdif_supported_data_types)|(DECODER->features.audio_output_type << 5)|((resample_required & 0x01)<<7)|(codecData->target_latency_config->target_latency << 8)) ,
                               (ENABLE_SPDIF_MESSAGING|(SPDIF_MINIMUM_INACTIVITY_TIME_BEFORE_SENDING_MESSAGE<<1)),
                               0,
                               0))
        {
            PRINT(("DECODER: Message MESSAGE_SET_SPDIF_CONFIG_MSG failed!\n"));
            Panic();
        }

        /* if AC3 is supported then send the configuration message */
        if(DECODER->features.spdif_supported_data_types & INPUT_TYPE_AC3)
        {
            if(!KalimbaSendMessage(MESSAGE_SET_AC3_CONFIG_MSG,
                                   codecData->spdif_ac3_config->configuration_word_1 ,
                                   codecData->spdif_ac3_config->configuration_word_2 ,
                                   0 ,
                                   0))
            {
                 PRINT(("DECODER: Message MESSAGE_SET_AC3_CONFIG_MSG failed!\n"));
                 Panic();
            }
        }
    }
    /* not using spdif input as a wired source */
    else
    {
        /* if using a digital output and a required frequency is specified then configure the
           dsp to use resampling */
        if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
        {
            /* Set the output sampling rate (I2S) */
            if(CsrI2SMusicResamplingFrequency())
            {
                if(!KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, CsrI2SMusicResamplingFrequency()/10 , mismatch, val_clock_mismatch, DECODER->features.audio_output_type))
                {
                    PRINT(("DECODER: Message MESSAGE_SET_DAC_SAMPLE_RATE failed!\n"));
                    Panic();
                }
            }
            /* no resampling frequency */
            else
            {
                /* Set the output sampling rate (DAC/I2S if no resampling required) */
                if(!KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, DECODER->rate/10 , mismatch, val_clock_mismatch, DECODER->features.audio_output_type))
                {
                    PRINT(("DECODER: Message MESSAGE_SET_DAC_SAMPLE_RATE failed!\n"));
                    Panic();
                }
            }
        }
        /* DAC */
        else
        {
            /* Set the output sampling rate (DAC/I2S if no resampling required) */
            if(!KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, DECODER->rate/10 , mismatch, val_clock_mismatch, DECODER->features.audio_output_type))
            {
                PRINT(("DECODER: Message MESSAGE_SET_DAC_SAMPLE_RATE failed!\n"));
                Panic();
            }
        }

        /* Set the codec sampling rate */
        if(!KalimbaSendMessage(MESSAGE_SET_CODEC_SAMPLE_RATE, DECODER->rate/10,  16000/10, 0, 0))
        {
            PRINT(("DECODER: Message MESSAGE_SET_CODEC_SAMPLE_RATE failed!\n"));
            Panic();
        }
    }

    PRINT(("DECODER: Send Go message to DSP now\n"));
    if(!KalimbaSendMessage(KALIMBA_MSG_GO,0,0,0,0))
    {
        PRINT(("DECODER: Message KALIMBA_MSG_GO failed!\n"));
        Panic();
    }
    /* update the current audio state */
    SetAudioInUse(TRUE);
}

/****************************************************************************
DESCRIPTION
    Utility function to Mute/Unmute Mic if back channel is enabled
    @Param  mute
            TRUE: Mic will be muted
            FALSE : Unmute Mic
    @Param  codecData
            A valid pointer to A2dpPluginConnectParams
    @return void
*/
void MicMuteUnmute(A2dpPluginConnectParams *codecData , bool mute)
{
    bool digital    = (DECODER->sink_type == AUDIO_SINK_ANALOG ? FALSE : codecData->mic_params->mic_a.digital);
    Source src      = AudioPluginGetMic(AUDIO_CHANNEL_A, digital);

    /* update the muteEnable status , according to mute value */
    if(src)
    {
        SourceConfigure(src,STREAM_AUDIO_MUTE_ENABLE,mute);
    }
    if(DECODER->features.stereo)
    {
        src = AudioPluginGetMic(AUDIO_CHANNEL_B, FALSE);
        /* Do mute/unmute on channel B */
        if(src)
        {
            SourceConfigure(src,STREAM_AUDIO_MUTE_ENABLE,mute);
        }
    }
}

/****************************************************************************
DESCRIPTION
    Utility function to obtain current plugin sample rate 

    @return current sample rate
*/
uint32 CsrA2DPGetDecoderSampleRate(void)
{
    /* if a2dp plugin loaded and rate is valid */
    if((DECODER)&&(DECODER->rate))
    {
        /* return current sample rate */
        PRINT(("DECODER: Sample Rate = %ld , decoder = %d\n",DECODER->rate,DECODER->sink_type));
        return DECODER->rate;
    }
    /* not yet loaded, sample rate unavailable so return 0 */
    else
    {
        PRINT(("DECODER: Sample Rate Not Available\n"));
        return 0;
    }
}

/****************************************************************************
DESCRIPTION
    Utility function to obtain current plugin sample rate for subwoofer use

    @return current sample rate
*/
uint32 CsrA2DPGetDecoderSubwooferSampleRate(void)
{
    /* if a2dp plugin loaded and rate is valid */
    if((DECODER)&&(DECODER->rate))
    {
        /* subwoofer runs at fixed rate 1.2 / 48 kHz */
        PRINT(("DECODER: Subwoofer Sample Rate = 48000\n"));
            return 48000;
        }
    /* not yet loaded, sample rate unavailable so return 0 */
    else
    {
        PRINT(("DECODER: Sample Rate Not Available\n"));
        return 0;
    }
}


/****************************************************************************
DESCRIPTION
    utility function to set the current EQ operating mode

    @return void
*/
void CsrA2dpDecoderPluginSetEqMode(uint16 operating_mode, A2DP_MUSIC_PROCESSING_T music_processing, A2dpPluginModeParams *mode_params)
{
    /* determine the music processing mode requirements, set dsp music mode appropriately */
    switch (music_processing)
    {
        case A2DP_MUSIC_PROCESSING_PASSTHROUGH:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , MUSIC_SYSMODE_PASSTHRU , MUSIC_DO_NOT_CHANGE_EQ_BANK, 0, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)) );
                PRINT(("DECODER: Set Music Mode SYSMODE_PASSTHRU\n"));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_DO_NOT_CHANGE_EQ_BANK, 0, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode SYSMODE_FULLPROC\n"));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_NEXT_EQ_BANK:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_NEXT_EQ_BANK, 0, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and advance to next EQ bank\n", operating_mode));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 0, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 0\n",operating_mode));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK1:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 1, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 1\n",operating_mode));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK2:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 2, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 2\n",operating_mode));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK3:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 3, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 3\n",operating_mode));
            }
            break;
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK4:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 4, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 4\n",operating_mode));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK5:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 5, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 5\n",operating_mode));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK6:
            {
                KalimbaSendMessage (MUSIC_SETMODE_MSG , operating_mode , MUSIC_SET_EQ_BANK, 6, ((mode_params->external_mic_settings << 1)+(mode_params->mic_mute)));
                PRINT(("DECODER: Set Music Mode %d and set EQ bank 6\n",operating_mode));
            }
            break;

        default:
            {
                PRINT(("DECODER: Set Music Mode Invalid [%x]\n" , music_processing ));
            }
            break;
    }
}

/****************************************************************************
DESCRIPTION
    utility function to set the current audio enhancments enables

    @return void
*/
void CsrA2dpDecoderPluginUpdateEnhancements(A2dpPluginModeParams *mode_params)
{
    /* update the enables of any audio enhancements */
    if(mode_params)
    {
        /* if data is valid set the enhancement enables for bass boost and 3d effect, the enables are inverted logic */
        if(mode_params->music_mode_enhancements & MUSIC_CONFIG_DATA_VALID)
        {
            PRINT(("DECODER: Set Audio Enhancements Configuration [%x] inverted [%x]\n" , mode_params->music_mode_enhancements , (~mode_params->music_mode_enhancements & 0x0fff)));
            KalimbaSendMessage(MUSIC_SETCONFIG , 0 , (MUSIC_CONFIG_USER_EQ_BYPASS|MUSIC_CONFIG_SUB_WOOFER_BYPASS|MUSIC_CONFIG_BASS_BOOST_BYPASS|MUSIC_CONFIG_SPATIAL_BYPASS), 0, ~mode_params->music_mode_enhancements);
        }
        /* always update the subwoofer status */
        else
        {
            KalimbaSendMessage(MUSIC_SETCONFIG , 0 , MUSIC_CONFIG_SUB_WOOFER_BYPASS, 0, ~mode_params->music_mode_enhancements);
        }
    }
}

/****************************************************************************
DESCRIPTION
    utility function to reset the VM volume change request block now that the 
    dsp has a full buffer of data 

    @return void
*/
void CsrA2dpDecoderPluginAllowVolChanges(void)
{
    A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;

    /* ensure plugin loaded and we are not waiting for the subwoofer to connect */
    if((DECODER)&&(codecData->sub_is_available == FALSE))
    {
        PRINT(("DECODER: Allow Volume Changes\n"));
        codecData->delay_volume_message_sending = FALSE;
    }
    else
        PRINT(("DECODER: Allow Volume Changes Ignored Due To Sub\n"));

}

/****************************************************************************
DESCRIPTION
    utility function to check whether the subwoofer port got connected within the 
    5 second timeout period, if it didn't the audio will still be in muted state
    so will need to be unmuted 

    @return void
*/
void CsrA2dpDecoderPluginSubCheckForConnectionFailure(void)
{
    /* ensure plugin loaded */
    if(DECODER)
    {
        A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
      
        /* check whether subwoofer is available, if not exit */
        if((codecData->sub_is_available == TRUE)&&(!codecData->sub_connection_port))
        {
            PRINT(("DECODER: SUB Failed to Connect, unmute\n"));
                    
            /* a sub is available but it has failed to establish its media channel, 
               unmute audio and set a failed sub channel to allow volume changes to 
               get processed */       
            codecData->sub_connection_port = DSP_SUB_PORT_FAILED;
            
            /* release tone playing/volume setting lock */            
            codecData->delay_volume_message_sending = FALSE;

            /* set volume levels */
            CsrA2dpDecoderPluginSetLevels(&DECODER->volume, INCREASING, TRUE);
        }                                  
    }
}

/****************************************************************************
DESCRIPTION
    utility function to set the DAC gain to the passed in gain value

    @return void
*/
void CsrA2DPDecoderSetDACGain(uint16 DAC_Gain)
{   
    /* set the DAC gain for volume schemes of DAC and digital, excluding hybrid, external (I2S) and TWS */
    if(((isCodecLowLatencyBackChannel())||(DECODER->volume.volume_type == DAC_VOLUME_CONTROL)||(DECODER->volume.volume_type == DSP_VOLUME_CONTROL))&&
       !((DECODER->stream_relay_mode == RELAY_MODE_TWS_MASTER)||(DECODER->stream_relay_mode == RELAY_MODE_TWS_SLAVE))&&
       (DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_DAC))
    {   
        PRINT(("CodecSetOutputGainNow = %x\n", DAC_Gain));
        CodecSetOutputGainNow(DECODER->codec_task, DAC_Gain, left_and_right_ch);
    }
}
