/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_encoder_common.c
    
DESCRIPTION
    Plugin implentation which routes audio though the dsp encoder
    
NOTES
*/

#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <print.h>
#include <file.h>
#include <stream.h>
#include <kalimba.h>
#include <kalimba_standard_messages.h>
#include <message.h> 
#include <transform.h> 
#include <string.h> 

#include "audio_plugin_if.h"
#include "csr_a2dp_encoder_common_plugin.h"
#include "csr_a2dp_encoder_common.h"
#include "csr_a2dp_encoder_common_if.h"
#include "audio.h"


#define KALIMBA_ENCODER_USB                 0x0001
#define KALIMBA_ENCODER_ANALOGUE            0x0002
#define KALIMBA_ENCODER_SPDIF               0x0003
#define KALIMBA_SET_SAMPLE_RATE             0x7050
#define KALIMBA_SBC_BITPOOL                 0x7070
#define KALIMBA_SBC_BITPOOL_BAD_LINK        0x7080
#define KALIMBA_PEQ_SELECT_CURVE_MESSAGE    0x7090
#define KALIMBA_MUTE_SPEAKER_MESSAGE        0x70A0
#define KALIMBA_MUTE_MIC_MESSAGE            0x70B0
#define KALIMBA_ENCODER_SELECT              0x7300
#define KALIMBA_CODEC_TYPE_MESSAGE          0x7303


#define MULTIPLE_STREAMS
#define USB_AUDIO
#define ANALOGUE_AUDIO
#define SPDIF_AUDIO

#ifdef MULTIPLE_STREAMS
#define MAX_BT_SINKS                2
#else
#define MAX_BT_SINKS                1
#endif


typedef enum
{
    CSR_ENCODER_CODEC_SBC = 0,
    CSR_ENCODER_CODEC_MP3 = 1,
    CSR_ENCODER_CODEC_FASTSTREAM = 2,
    CSR_ENCODER_CODEC_FASTSTREAM_BIDIR = 3,
    CSR_ENCODER_CODEC_APTX = 4,
    CSR_ENCODER_CODEC_APTX_LL = 5,
    CSR_ENCODER_CODEC_APTX_LL_BIDIR = 6
} CSR_ENCODER_CODEC_T;


typedef struct sync_Tag
{
    Sink a2dp_sink[MAX_BT_SINKS];    
    Transform t[MAX_BT_SINKS];
    Task codec_task;    
    uint16 packet_size;
    Source input_source;
    Sink input_sink;
    A2dpEncoderInputDeviceType input_device_type;
    bool bidirectional;
    bool mic_mute;
    bool speaker_mute;
    A2dpEncoderEqMode eq;
    uint16 plugin;
    uint32 rate;
    uint8 bitpool;
    uint8 bad_link_bitpool;
    bool content_protection;
} CSR_ENCODER_T;


/* the audio data structure */
static CSR_ENCODER_T *ENCODER = NULL;


/****************************************************************************
NAME    
    csr_encoder_aptx_set_sample_rate - Informs the APT-X DSP application of the configured sample rate
*/   
static void csr_encoder_aptx_set_sample_rate(uint32 rate)
{
    uint16 aptx_format = 0;
    
    switch (rate) 
    {
        case 48000: 
        {
           aptx_format = 3;
        }
        break;
        
        case 44100: 
        {
           aptx_format = 2;
        }
        break;
        
        case 32000:
        {
           aptx_format = 1;
        }
        break;
        
        case 16000:
        {
           aptx_format = 0;
        }
        break;
    }
    
    /* Configure encoding format */
    if (!KalimbaSendMessage(KALIMBA_SET_SAMPLE_RATE, aptx_format, 0, 0, 0))
    {
        /* If message fails to get through, Panic */
        Panic();
    }
}


/****************************************************************************
NAME    
    csr_encoder_load_dsp_application - Loads the DSP application for the configured Stream-End Point
*/   
static void csr_encoder_load_dsp_application(uint16 plugin)
{
    FILE_INDEX index = FILE_NONE;
    char* kap_file = NULL;
    
    switch (plugin)
    {
        case APTX_ENCODER:
        {
            kap_file = "aptx_encoder/aptx_encoder.kap";
        }
        break;
        
        case APTX_LOWLATENCY_ENCODER:
        {
            kap_file = "aptx_acl_sprint_encoder/aptx_acl_sprint_encoder.kap";
        }
        break;
        
        case SBC_ENCODER:
        case FASTSTREAM_ENCODER:
        {
            kap_file = "sbc_encoder/sbc_encoder.kap";
        }
        break;
        
        default:
        {
            Panic();
        }
        break;
    }
        
    index = FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file));

    if (index == FILE_NONE)
        Panic();
    if (!KalimbaLoad(index))
        Panic();        
}


/****************************************************************************
NAME    
    csr_encoder_route_incoming_data - Routes incoming Bluetooth data to the DSP, or discards unwanted data
*/   
static void csr_encoder_route_incoming_data(Sink sink, uint16 instance, uint16 dsp_port, bool bidirectional)
{
    if (instance == 0)
    {                
        if (bidirectional)
        {
            StreamDisconnect(StreamSourceFromSink(sink), 0);
            (void) StreamConnect(StreamSourceFromSink(sink), StreamKalimbaSink(dsp_port));
        }
        else
        {
            /* discard any incoming data */
            StreamConnectDispose(StreamSourceFromSink(sink));                   
        }
    }
    else
    {
        /* discard any incoming data */
        StreamConnectDispose(StreamSourceFromSink(sink));
    }
}


/****************************************************************************
NAME    
    csr_encoder_route_outgoinging_data - Route for outgoing encoded data and start encode
*/
static void csr_encoder_route_outgoinging_data(uint16 plugin, uint16 instance, uint16 dsp_port, Sink sink, uint32 rate)
{
    PRINT(("ENCODER: route_outgoing plugin[%d] instance[%d] dsp_port[%d] sink[0x%x] rate[0x%x]\n", plugin, instance, dsp_port, (uint16)sink, (uint16)rate));
    
    StreamDisconnect(StreamKalimbaSource(dsp_port), 0);
    
    switch (plugin)
    {
        case SBC_ENCODER:
        {
            bool transform_status;
            
            /* Send message to DSP that this is the SBC encoder */
            if (!KalimbaSendMessage(KALIMBA_CODEC_TYPE_MESSAGE, CSR_ENCODER_CODEC_SBC, (uint16)rate, 0, 0))
            {
                Panic();
            }
            
            /* Initialise the RTP SBC encoder */
            ENCODER->t[instance] = TransformRtpSbcEncode(StreamKalimbaSource(dsp_port), sink);

            /* Configure the RTP transform to generate the selected packet size */
            TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SBC_ENCODE_PACKET_SIZE, ENCODER->packet_size);
            /* Configure the RTP transform to use copy protection, if required */
            if (ENCODER->content_protection)
            {
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_ENABLE, 1);
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_SET_BITS, 0);
            }
            else
            {
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_ENABLE, 0);
            }

            /* Transform should not manage timings. */
            TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SBC_ENCODE_MANAGE_TIMING, FALSE);

            /* Start the transform */
            transform_status = TransformStart(ENCODER->t[instance]);
            
            /* discard any incoming data */
            StreamConnectDispose(StreamSourceFromSink(sink));
    
            PRINT(("ENCODER: SBC TransformStart sink:0x%x transform[0x%x] packet_size[0x%x] success[%d]\n",(uint16)sink, (uint16)ENCODER->t[instance], ENCODER->packet_size, transform_status));
        }
        break;
        
        case FASTSTREAM_ENCODER:
        {
            CSR_ENCODER_CODEC_T codec = CSR_ENCODER_CODEC_FASTSTREAM;
            
            if (ENCODER->bidirectional)
                codec = CSR_ENCODER_CODEC_FASTSTREAM_BIDIR;
            
            /* Send message to DSP that this is the FastStream encoder (uni or bi - directional) */
            if (!KalimbaSendMessage(KALIMBA_CODEC_TYPE_MESSAGE, codec, (uint16)rate, 0, 0))
            {
                Panic();
            }
            
            /* connect DSP source to sink */
            StreamConnect(StreamKalimbaSource(dsp_port), sink);
            
            /* check for routing of bi-directional Faststream */            
            csr_encoder_route_incoming_data(sink, instance, dsp_port, ENCODER->bidirectional);
            
            PRINT(("ENCODER: Faststream Connect sink:0x%x bidirectional:0x%x\n", (uint16)sink, ENCODER->bidirectional));
        }
        break;
        
        case APTX_ENCODER:
        {
            /* Send message to DSP that this is the APTX encoder */
            if (!KalimbaSendMessage(KALIMBA_CODEC_TYPE_MESSAGE, CSR_ENCODER_CODEC_APTX, (uint16)rate, 0, 0))
            {
                Panic();
            }

            /* Configure the RTP transform to use copy protection, if required */
            if (ENCODER->content_protection)
            {
                bool transform_status;

                /* Initialise the RTP encoder */
                ENCODER->t[instance] = TransformRtpEncode(StreamKalimbaSource(dsp_port), sink);

                /* Configure the RTP transform to generate the selected packet size */
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_ENCODE_PACKET_SIZE, ENCODER->packet_size);

                /* Configure the RTP transform to use copy protection */
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_ENABLE, 1);
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_SET_BITS, 0);

                /* Transform should not manage timings. */
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_ENCODE_MANAGE_TIMING, FALSE);

                /* Start the transform */
                transform_status = TransformStart(ENCODER->t[instance]);
            }
            else
            {
                /* No SCMS-T required, just connect up the streams */
                StreamConnect(StreamKalimbaSource(dsp_port), sink);
            }
            
            /* discard any incoming data */
            StreamConnectDispose(StreamSourceFromSink(sink));
            
            PRINT(("ENCODER: APTX connect sink:0x%x\n", (uint16)sink));
        }
        break;
        
        case APTX_LOWLATENCY_ENCODER:
        {
            CSR_ENCODER_CODEC_T codec = CSR_ENCODER_CODEC_APTX_LL;
            
            if (ENCODER->bidirectional)
                codec = CSR_ENCODER_CODEC_APTX_LL_BIDIR;
            
            /* Send message to DSP that this is the APTX Low Latency encoder (uni or bi - directional) */
            if (!KalimbaSendMessage(KALIMBA_CODEC_TYPE_MESSAGE, codec, (uint16)rate, 0, 0))
            {
                Panic();
            }
            
            /* Configure the RTP transform to use copy protection, if required */
            if (ENCODER->content_protection)
            {
                bool transform_status;

                /* Initialise the RTP encoder */
                ENCODER->t[instance] = TransformRtpEncode(StreamKalimbaSource(dsp_port), sink);

                /* Configure the RTP transform to generate the selected packet size */
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_ENCODE_PACKET_SIZE, ENCODER->packet_size);

                /* Configure the RTP transform to use copy protection */
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_ENABLE, 1);
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_SCMS_SET_BITS, 0);
                /* Transform should not manage timings. */
                TransformConfigure(ENCODER->t[instance], VM_TRANSFORM_RTP_ENCODE_MANAGE_TIMING, FALSE);

                /* Start the transform */
                transform_status = TransformStart(ENCODER->t[instance]);
            }
            else
            {
                /* No SCMS-T required, just connect up the streams */
                StreamConnect(StreamKalimbaSource(dsp_port), sink);
            }

            /* check for routing of bi-directional APT-X */            
            csr_encoder_route_incoming_data(sink, instance, dsp_port, ENCODER->bidirectional);
            
            /* inform APT-X DSP application of the sample rate */
            csr_encoder_aptx_set_sample_rate(rate);
            
            PRINT(("ENCODER: APTX Low Latency Connect sink:0x%x bidirectional:0x%x\n", (uint16)sink, ENCODER->bidirectional));
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
    csr_encoder_configure_encoding - Sends the encoding parameters to the DSP
*/
static void csr_encoder_configure_encoding(uint8 format, uint8 bitpool)
{
    PRINT(("ENCODER: configure_encoding format[0x%x] bitpool[0x%x]\n", format, bitpool));
    
    /* Configure SBC encoding format */
    if (!KalimbaSendMessage(KALIMBA_MSG_SBCENC_SET_PARAMS, format, 0, 0, 0))
    {
        /* If message fails to get through, abort */
        Panic();
    }

    /* Pass bit pool value to DSP */
    if (!KalimbaSendMessage(KALIMBA_MSG_SBCENC_SET_BITPOOL, bitpool, 0, 0, 0))
    {
        /* If message fails to get through, abort */
        Panic();
    }
}


/****************************************************************************
NAME    
    csr_encoder_connect_input_device - Routes USB \ Analogue input
*/
static void csr_encoder_connect_input_device(Source input_source, Sink input_sink, uint32 rate)
{
    PRINT(("ENCODER: connect_input_device type[%d] rate[0x%lx]\n", ENCODER->input_device_type, rate));
#ifdef USB_AUDIO    
        /* select the source type */
        if (ENCODER->input_device_type == A2dpEncoderInputDeviceUsb)
        {
            Transform transform_mic = 0;
            Transform transform_speaker = 0;
            
            ENCODER->input_source = input_source;
            ENCODER->input_sink = input_sink;
            if (ENCODER->input_source)
                transform_mic = StreamConnect(PanicNull(ENCODER->input_source), StreamKalimbaSink(DSP_PORT_USB_IN));
            if (ENCODER->input_sink)
                transform_speaker = StreamConnect(StreamKalimbaSource(DSP_PORT_USB_OUT), PanicNull(ENCODER->input_sink));
            
            /* Select the source type */
            PanicFalse(KalimbaSendMessage(KALIMBA_ENCODER_SELECT, KALIMBA_ENCODER_USB, 0, 0, 0));
            
            PRINT(("    usb connected mic[0x%x] speaker [0x%x]\n", (uint16)transform_mic, (uint16)transform_speaker));
        }
#endif  
#ifdef SPDIF_AUDIO
        /* select the source type */
        if (ENCODER->input_device_type == A2dpEncoderInputDeviceSPDIF)
        {
            /* obtain source to SPDIF hardware */
            Source l_Source_A = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0 );
            Source l_Source_B = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );

            /* Ensure both channels are synchronised */
            PanicFalse(SourceSynchronise(l_Source_A, l_Source_B));
            
            /* configure the SPDIF interface operating mode, run in auto rate detection mode */
            PanicFalse(SourceConfigure(l_Source_A, STREAM_SPDIF_AUTO_RATE_DETECT, TRUE));
            PanicFalse(SourceConfigure(l_Source_B, STREAM_SPDIF_AUTO_RATE_DETECT, TRUE));
    
            /* configure the SPDIF interface to report channel status (copy protection) */
            PanicFalse(SourceConfigure(l_Source_A, STREAM_SPDIF_CHNL_STS_REPORT_MODE, TRUE));
            PanicFalse(SourceConfigure(l_Source_B, STREAM_SPDIF_CHNL_STS_REPORT_MODE, TRUE));

            /* local copy of current connection information used for disconnection */
            ENCODER->input_source = input_source;
            ENCODER->input_sink = input_sink;
            
            /* connect SPDIF hardware to DSP ports */
            StreamConnect(l_Source_A, StreamKalimbaSink(DSP_PORT_SPDIF_IN_L));
            StreamConnect(l_Source_B, StreamKalimbaSink(DSP_PORT_SPDIF_IN_R));

            /* Select the source type */
            PanicFalse(KalimbaSendMessage(KALIMBA_ENCODER_SELECT, KALIMBA_ENCODER_SPDIF, 0, 0, 0));
            
            PRINT(("    spdif connected\n"));
        }
#endif        
#ifdef ANALOGUE_AUDIO    
        if (ENCODER->input_device_type == A2dpEncoderInputDeviceAnalogue)
        {
            Source mic_src_a;
            Source mic_src_b;
                                    
            mic_src_a = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
            mic_src_b = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);                
            
            /* Ensure both channels are synchronised */
            PanicFalse(SourceSynchronise(mic_src_a, mic_src_b));
            
            /* configure mic rate */
            StreamDisconnect(mic_src_a, 0);
            StreamDisconnect(mic_src_b, 0);
            PanicFalse(SourceConfigure(mic_src_a, STREAM_CODEC_INPUT_RATE, rate));
            PanicFalse(SourceConfigure(mic_src_b, STREAM_CODEC_INPUT_RATE, rate));
                
            /* plug Left ADC into port 0 */
            (void)StreamConnect(mic_src_a,StreamKalimbaSink(DSP_PORT_ANALOGUE_IN_L)); 

            /* plug Right ADC into port 1 */
            (void)StreamConnect(mic_src_b,StreamKalimbaSink(DSP_PORT_ANALOGUE_IN_R)); 
        
            /* Select the source type */
            PanicFalse(KalimbaSendMessage(KALIMBA_ENCODER_SELECT, KALIMBA_ENCODER_ANALOGUE, 0, 0, 0)); 
            
            PRINT(("    analogue connected\n"));
        }
#endif      
}


/****************************************************************************
NAME    
    csr_encoder_disconnect_input_device - Disconnects USB \ Analogue input
*/
static void csr_encoder_disconnect_input_device(void)
{
    PRINT(("ENCODER: disconnect_input_device type[%d]\n", ENCODER->input_device_type));
    
#ifdef USB_AUDIO      
    if (ENCODER->input_device_type == A2dpEncoderInputDeviceUsb)
    {
        if (ENCODER->input_source)
            StreamDisconnect(ENCODER->input_source, StreamKalimbaSink(DSP_PORT_USB_IN));
        if (ENCODER->input_sink)
            StreamDisconnect(StreamKalimbaSource(DSP_PORT_USB_OUT), ENCODER->input_sink);
    }
#endif    
#ifdef SPDIF_AUDIO
    if (ENCODER->input_device_type == A2dpEncoderInputDeviceSPDIF)
    {
        Source l_Source_A = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0 );
        Source l_Source_B = StreamAudioSource(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );
        
        /* disconnect dsp from SPDIF sources */
        StreamDisconnect(l_Source_A, StreamKalimbaSink(DSP_PORT_SPDIF_IN_L));
        StreamDisconnect(l_Source_B,StreamKalimbaSink(DSP_PORT_SPDIF_IN_R));             

        /* close the SPDIF sources */
        SourceClose(l_Source_A);
        SourceClose(l_Source_B);
    }    
#endif    
#ifdef ANALOGUE_AUDIO      
    if (ENCODER->input_device_type == A2dpEncoderInputDeviceAnalogue)
    {
        Source mic_src_a;
        Source mic_src_b;
                                    
        mic_src_a = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
        mic_src_b = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);                
        
        StreamDisconnect(mic_src_a, StreamKalimbaSink(DSP_PORT_ANALOGUE_IN_L));
        StreamDisconnect(mic_src_b,StreamKalimbaSink(DSP_PORT_ANALOGUE_IN_R));
        SourceClose(mic_src_a);
        SourceClose(mic_src_b);
}
#endif        
}


/****************************************************************************
NAME    
    csr_encoder_disconnect_bt_stream - Disconnects Bluetooth routing to DSP
*/
static void csr_encoder_disconnect_bt_stream(uint16 index)
{
    /* Disconnect the Kalimba source from the media sink */
    StreamDisconnect(StreamKalimbaSource(index + DSP_PORT_A2DP_DEV_A), ENCODER->a2dp_sink[index]);    
    /* Disconnect the media source from the Kalimba sink */
    StreamDisconnect(StreamSourceFromSink(ENCODER->a2dp_sink[index]), StreamKalimbaSink(index + DSP_PORT_A2DP_DEV_A));

    /* Dispose of incoming media data */
    StreamConnectDispose(StreamSourceFromSink(ENCODER->a2dp_sink[index]));
    
            
    PRINT(("ENCODER: Disconnect media i:%d sink:0x%x\n", index, (uint16)ENCODER->a2dp_sink[index]));
                
    /* clear the audio sink */    
    ENCODER->a2dp_sink[index] = 0;
}


/****************************************************************************
NAME    
    csr_encoder_mute_speaker - Mute speaker audio
*/
static void csr_encoder_mute_speaker(void)
{
    if (!ENCODER->speaker_mute)
    {
        /* mute the speaker audio */
        ENCODER->speaker_mute = TRUE;
        KalimbaSendMessage(KALIMBA_MUTE_SPEAKER_MESSAGE, 1, 0, 0, 0);
        PRINT(("ENCODER: Mute Speaker\n"));
    }
}


/****************************************************************************
NAME    
    csr_encoder_mute_mic - Mute microphone audio
*/
static void csr_encoder_mute_mic(void)
{
    if (!ENCODER->mic_mute)
    {
        /* mute the mic audio */
        ENCODER->mic_mute = TRUE;
        KalimbaSendMessage(KALIMBA_MUTE_MIC_MESSAGE, 1, 0, 0, 0);
        PRINT(("ENCODER: Mute Mic\n"));
    }
}


/****************************************************************************
NAME    
    csr_encoder_unmute_speaker - Un-mute speaker audio
*/
static void csr_encoder_unmute_speaker(void)
{
    if (ENCODER->speaker_mute)
    {
        /* un-mute the speaker audio */
        ENCODER->speaker_mute = FALSE;
        KalimbaSendMessage(KALIMBA_MUTE_SPEAKER_MESSAGE, 0, 0, 0, 0);
        PRINT(("ENCODER: Un-Mute Speaker\n"));
    }
}


/****************************************************************************
NAME    
    csr_encoder_unmute_mic - Un-mute microphone audio
*/
static void csr_encoder_unmute_mic(void)
{
    if (ENCODER->mic_mute)
    {
        /* un-mute the mic audio */
        ENCODER->mic_mute = FALSE;
        KalimbaSendMessage(KALIMBA_MUTE_MIC_MESSAGE, 0, 0, 0, 0);
        PRINT(("ENCODER: Un-Mute Mic\n"));
    }
}


/****************************************************************************
DESCRIPTION
    This function connects a synchronous audio stream to the pcm subsystem
*/ 
void CsrA2dpEncoderPluginConnect(A2dpEncoderPluginTaskdata *task, Task codec_task, uint16 volume, uint32 rate, bool stereo, AUDIO_MODE_T mode, const void *params) 
{    
    A2dpEncoderPluginConnectParams *codecData = (A2dpEncoderPluginConnectParams *)params;
    uint16 i = 0;

    if (!codecData)
        Panic();
    
    /* Register plugin task to receive messages from the DSP application */
    (void)MessageCancelAll((TaskData *)task, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask((TaskData *)task);

    /* load DSP kap file */
    csr_encoder_load_dsp_application(task->a2dp_plugin_variant);
    
    PRINT(("ENCODER: CsrA2dpEncoderPluginConnect rate[0x%lx]\n", rate));        

    ENCODER = (CSR_ENCODER_T *)PanicUnlessMalloc(sizeof(CSR_ENCODER_T));
        
    ENCODER->plugin = task->a2dp_plugin_variant;
    ENCODER->codec_task = codec_task;
    ENCODER->input_device_type = codecData->input_device_type;
    ENCODER->packet_size = 0;
    ENCODER->bidirectional = 0;
    ENCODER->rate = rate;
    ENCODER->bitpool = codecData->bitpool;
    ENCODER->bad_link_bitpool = codecData->bad_link_bitpool;
    if (codecData->mode)
        ENCODER->eq = codecData->mode->eq_mode;
    else
        ENCODER->eq = A2dpEncoderEqModeBypass;
        
    if ((mode == AUDIO_MODE_MUTE_SPEAKER) || (mode == AUDIO_MODE_MUTE_BOTH))
    {
        ENCODER->speaker_mute = TRUE;
    }
    else
    {
        ENCODER->speaker_mute = FALSE;
    }
    if ((mode == AUDIO_MODE_MUTE_MIC) || (mode == AUDIO_MODE_MUTE_BOTH))
    {
        ENCODER->mic_mute = TRUE;
    }
    else
    {
        ENCODER->mic_mute = FALSE;
    }
    
    for (i = 0; i < MAX_BT_SINKS; i++)
    {
        /* clear all Bluetooth Sinks */
        ENCODER->a2dp_sink[i] = 0;
        /* clear all Transforms */
        ENCODER->t[i] = 0;
    }
    /* do we need to enable SCMS-T for content protection? */
    ENCODER->content_protection = codecData->content_protection ? TRUE : FALSE;
    
    csr_encoder_connect_input_device(codecData->input_source, codecData->input_sink, rate);
       
    ENCODER->packet_size = codecData->packet_size;
    ENCODER->a2dp_sink[0] = codecData->a2dp_sink[0];
#ifdef MULTIPLE_STREAMS    
    ENCODER->a2dp_sink[1] = codecData->a2dp_sink[1];
#endif    

    /* Enable bidirectional mode for the encoder which support it */
    if ((task->a2dp_plugin_variant == FASTSTREAM_ENCODER) ||
        (task->a2dp_plugin_variant == APTX_ENCODER) ||
        (task->a2dp_plugin_variant == APTX_LOWLATENCY_ENCODER))
    {
        ENCODER->bidirectional = codecData->rate ? TRUE : FALSE;
    }

    if (ENCODER->a2dp_sink[0])
    {
        csr_encoder_route_outgoinging_data(task->a2dp_plugin_variant, 0, DSP_PORT_A2DP_DEV_A, ENCODER->a2dp_sink[0], rate);
    }

#ifdef MULTIPLE_STREAMS    
    if (ENCODER->a2dp_sink[1])
    {
        csr_encoder_route_outgoinging_data(task->a2dp_plugin_variant, 1, DSP_PORT_A2DP_DEV_B, ENCODER->a2dp_sink[1], rate);        
    }
#endif    

    if (codecData->format && codecData->bitpool)
    {
        csr_encoder_configure_encoding(codecData->format, codecData->bitpool);      
    }

    if(!KalimbaSendMessage(KALIMBA_MSG_GO,0,0,0,0))
    {
        PRINT(("ENCODER: Message KALIMBA_MSG_GO failed!\n"));
        Panic();
    }
    PRINT(("ENCODER: KALIMBA_MSG_GO\n"));

    /* update the current audio state */
    SetAudioInUse(TRUE);
    
    KalimbaSendMessage(KALIMBA_PEQ_SELECT_CURVE_MESSAGE, ENCODER->eq, 0, 0, 0);
    PRINT(("ENCODER: EQ %d\n", ENCODER->eq));
}

/****************************************************************************
DESCRIPTION
    Disconnect audio
*/
void CsrA2dpEncoderPluginDisconnect(void) 
{   
    uint16 i;
    
    if (!ENCODER)
        Panic() ;
    
    PRINT(("ENCODER: CsrA2dpEncoderPluginDisconnect\n"));
            
    for (i = 0; i < MAX_BT_SINKS; i++)
    {
        if (ENCODER->a2dp_sink[i] != 0)
        {                                        
            csr_encoder_disconnect_bt_stream(i);                      
        }
    }
    
    csr_encoder_disconnect_input_device();
    
    /* free plugin memory */
    free (ENCODER);
    ENCODER = NULL ; 
    
    /* turn off the DSP */
    KalimbaPowerOff();
    
    /* update the current audio state */
    SetAudioInUse(FALSE);    
}

/****************************************************************************
DESCRIPTION
    Indicate the volume has changed
*/
void CsrA2dpEncoderPluginSetVolume(uint16 volume) 
{
}

/****************************************************************************
DESCRIPTION
    Set the mode
*/
void CsrA2dpEncoderPluginSetMode(A2dpEncoderPluginTaskdata *task, AUDIO_MODE_T mode, const void *params) 
{    
    A2dpEncoderPluginModeParams *mode_params = (A2dpEncoderPluginModeParams *)params;
    A2dpEncoderEqMode eq = ENCODER->eq;
    Sink connect_sink = 0;
    Sink disconnect_sink = 0;
    uint8 bitpool = 0;
    uint8 bad_link_bitpool = 0;
    
    if (mode_params)
    {
        /* store new settings */
        eq = mode_params->eq_mode;
        connect_sink = mode_params->connect_sink;
        disconnect_sink = mode_params->disconnect_sink;
        bitpool = mode_params->bitpool;
        bad_link_bitpool = mode_params->bad_link_bitpool;
    }
    
    switch (mode)
    {
        case AUDIO_MODE_MUTE_SPEAKER:        
        {
            csr_encoder_unmute_mic();
            csr_encoder_mute_speaker();
        }
        break;
        
        case AUDIO_MODE_MUTE_MIC:        
        {
            csr_encoder_unmute_speaker();
            csr_encoder_mute_mic();
        }
        break;
        
        case AUDIO_MODE_MUTE_BOTH:        
        {
            csr_encoder_mute_speaker();
            csr_encoder_mute_mic();
        }
        break;
        
        case AUDIO_MODE_CONNECTED:
        {
            csr_encoder_unmute_speaker();
            csr_encoder_unmute_mic();
        }
        break;
                
        default:
        {
        }
        break;
    }
    
    if (eq != ENCODER->eq)
    {
        /* update the EQ mode */
        ENCODER->eq = eq;
        KalimbaSendMessage(KALIMBA_PEQ_SELECT_CURVE_MESSAGE, eq, 0, 0, 0);
        PRINT(("ENCODER: EQ %d\n", eq));
    }
    
#ifdef MULTIPLE_STREAMS    
    if (connect_sink)
    {
        uint16 i;
        for (i = 0; i < MAX_BT_SINKS; i++)
        {
            if ((ENCODER->a2dp_sink[i] == 0) && connect_sink)
            {                                    
                ENCODER->a2dp_sink[i] = connect_sink;
                csr_encoder_route_outgoinging_data(ENCODER->plugin, i, i == 0 ? DSP_PORT_A2DP_DEV_A : DSP_PORT_A2DP_DEV_B, ENCODER->a2dp_sink[i], ENCODER->rate);                      
                PRINT(("ENCODER: Connect Sink 0x%x\n", (uint16)connect_sink));
            }
        }
        mode_params->connect_sink = 0;
    }
    if (disconnect_sink)
    {
        uint16 i;
        for (i = 0; i < MAX_BT_SINKS; i++)
        {
            if (ENCODER->a2dp_sink[i] == disconnect_sink)
            {                                        
                csr_encoder_disconnect_bt_stream(i);  

                PRINT(("ENCODER: Disconnect Sink 0x%x\n", (uint16)disconnect_sink));
            }
        }
        mode_params->disconnect_sink = 0;
    }
    if (bitpool && (ENCODER->bitpool != bitpool))
    {
        ENCODER->bitpool = bitpool;
        /* send message to DSP to set new bitpool */
        KalimbaSendMessage(KALIMBA_SBC_BITPOOL, bitpool, 0, 0, 0);  
        PRINT(("ENCODER: SBC Bitpool:0x%x\n",bitpool));
    }
    if (bad_link_bitpool && (ENCODER->bad_link_bitpool != bad_link_bitpool))
    {
        ENCODER->bad_link_bitpool = bad_link_bitpool;
        /* send message to DSP to set new bad_link_bitpool */
        KalimbaSendMessage(KALIMBA_SBC_BITPOOL_BAD_LINK, bad_link_bitpool, 0, 0, 0);
        PRINT(("ENCODER: SBC Bad Link Bitpool:0x%x\n",bad_link_bitpool));
    }
#endif    
}

/****************************************************************************
FUNCTION
    CsrA2dpEncoderPluginInternalMessage

DESCRIPTION
    Handle internal messages and messages from the DSP
*/
void CsrA2dpEncoderPluginInternalMessage(A2dpEncoderPluginTaskdata *task, uint16 id, Message message)
{
    switch (id)
    {
        case MESSAGE_FROM_KALIMBA:
        {
            const DSP_REGISTER_T *m = (const DSP_REGISTER_T *)message;
            
            PRINT(("ENCODER: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));

            switch (m->id)
            {
                case KALIMBA_MSG_DSP_SPDIF_EVENT_MSG:
                {
                    if (m->a == SPDIF_EVENT_STREAM_VALID)
                    {

                        PRINT(("SPDIF EVENT - Stream Valid\n"));
                        
                        /* handle autodetected sample rate if present in the message */
                        if (m->b != 0)
                        {
                            PRINT(("SPDIF EVENT - SAMPLE RATE %x\n", m->b));
                        }

                        if (ENCODER->content_protection)
                        {
                            uint16 scms_bits = 0; /* must be initialised for later logic to work */

                            /* always process channel status, it may change and 0 is a valid state
                             * that we may need to tell the RTP transform about. */
                            PRINT(("SPDIF_EVENT - Channel Status L-bit[%x] Cp-bit[%x]\n", (m->c & CHANNEL_STATUS_L_BIT),
                                        (m->c & CHANNEL_STATUS_CP_BIT)));
                            /* setup SCMS bits parameter for RTP transform and configure it */
                            /* do we need to interpret the channel status as consumer or professional?
                             * the bits have different meanings... */
                            if ((m->c & CHANNEL_STATUS_CON_PRO_BIT) == CHANNEL_STATUS_CONSUMER)
                            {
                                /* always transfer the copy protect (CP) bit */
                                scms_bits = (m->c & CHANNEL_STATUS_CP_BIT) ? SCMS_BITS_CP_ON : 0x0000;
                                /* if CP bit is set, then there is no copy protection, just reflect the
                                 * original/copy bit (L-bit) in the output stream */
                                if (scms_bits)
                                {
                                    scms_bits |= (m->c & CHANNEL_STATUS_L_BIT) ? SCMS_BITS_L_ON : 0x0000;
                                }
                                /* else there is copy protection and need to ensure we set the output as
                                 * a copy, which is 0 for the L-bit. This is already the case from
                                 * initialisation */
                            }
                            /* else this is a professional stream, default to copy protection on and
                             * declare this is a copy. scms_bits is already setup like this from
                             * initialisation */

                            TransformConfigure(ENCODER->t[0], VM_TRANSFORM_RTP_SCMS_SET_BITS, scms_bits);
                            TransformConfigure(ENCODER->t[1], VM_TRANSFORM_RTP_SCMS_SET_BITS, scms_bits);
                        }

                        /* handle codec type */
                        if (m->d != 0)
                        {
                            PRINT(("SPDIF_EVENT - Codec Type %x\n", m->d));
                        }
                    }
                    else
                    {
                        PRINT(("SPDIF EVENT - Stream Invalid\n"));
                    }

                    break;
                }

            }
            break;
        }
    }
}
