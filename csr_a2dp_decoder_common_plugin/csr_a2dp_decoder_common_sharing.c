/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_subwoofer.c
DESCRIPTION
    subwoofer specific functions
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
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

#include "csr_i2s_audio_plugin.h"
#include "audio_plugin_if.h" /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_a2dp_decoder_common_plugin.h"
#include "csr_a2dp_decoder_common.h"
#include "csr_a2dp_decoder_common_if.h"
#include "csr_a2dp_decoder_common_sharing.h"


/****************************************************************************
DESCRIPTION
    disconnect the forwarding sink
*/
void CsrA2dpDecoderPluginDisconnectForwardingSink(void)
{        
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();  

	csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
	
    /* if connected, disconnect forwarding sink */
    if(DECODER->forwarding_sink)
    {
        Transform transform = TransformFromSink( DECODER->forwarding_sink );

		if (transform)
		{
			(void)TransformStop( transform );
			TransformDisconnect( transform );   /* TODO: Are both needed? */
		}
		
        StreamDisconnect( 0, DECODER->forwarding_sink);
		DECODER->forwarding_sink = NULL;
    }
}


/****************************************************************************
DESCRIPTION
    Control fowarding of undecoded audio frames to another device.
*/
void CsrA2dpDecoderPluginForwardUndecoded(A2dpPluginTaskdata *task , bool enable, Sink sink, bool content_protection)
{
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();
    
    /* ensure dsp is loaded */
    if (DECODER)
    {
        PRINT(("DECODER: Forward Undecoded (%u)\n" , enable ));
        /* check whether forwarding is enabled or not */
        if (enable)
        {
            PRINT(("DECODER: sink=0x%X forwarding_sink=0x%X sink_type=%u\n" , (uint16)sink, (uint16)DECODER->forwarding_sink, DECODER->sink_type));
            /* ensure sink is valid */            
            if ((sink != NULL) && (DECODER->forwarding_sink == NULL) && 
                ((DECODER->sink_type == AUDIO_SINK_AV) || (DECODER->sink_type == AUDIO_SINK_USB) || (DECODER->sink_type == AUDIO_SINK_ANALOG) || (DECODER->sink_type == AUDIO_SINK_SPDIF)))
            {
                DECODER->forwarding_sink = sink;

                /* determine codec type and start the data forwarding of the appropriate data type */
                switch ((A2DP_DECODER_PLUGIN_TYPE_T)task->a2dp_plugin_variant)
                {
                    case SBC_DECODER:
                    {
#ifdef SHAREME_MASTER
						Transform rtp_encode = 0;
						rtp_encode = rtp_encode;
                        StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
#else
                        Transform rtp_encode = TransformRtpSbcEncode(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);   /* Initialise the RTP SBC encoder */
                        TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_SBC_ENCODE_PACKET_SIZE, DECODER->packet_size);   /* Configure the RTP transform to generate the selected packet size */
                        TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_SBC_ENCODE_MANAGE_TIMING, FALSE);   /* Transform should not manage timings. */
                        TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_SCMS_ENABLE, content_protection);   /* Ensure transform supports content protection if reqd. */
                        (void)TransformStart( rtp_encode ) ;
#endif
						csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_SHAREME);
                        PRINT(("DECODER: SBC packet_size=%u scms=%u transform=0x%X\n",DECODER->packet_size,content_protection,(uint16)rtp_encode));
                        break;
                    }
                    case MP3_DECODER:
                    {
#ifdef SHAREME_MASTER
						Transform rtp_encode = 0;
						rtp_encode = rtp_encode;
                        StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
#else
                        Transform rtp_encode = TransformRtpMp3Encode(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);   /* Initialise the RTP SBC encoder */
                        TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_MP3_ENCODE_PACKET_SIZE, DECODER->packet_size);   /* Configure the RTP transform to generate the selected packet size */
                        TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_MP3_ENCODE_MANAGE_TIMING, FALSE);   /* Transform should not manage timings. */
                        TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_SCMS_ENABLE, content_protection);   /* Ensure transform supports content protection if reqd. */
                        (void)TransformStart( rtp_encode ) ;
#endif
 						csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_SHAREME);
                        PRINT(("DECODER: MP3 packet_size=%u scms=%u transform=0x%X\n",DECODER->packet_size,content_protection,(uint16)rtp_encode));
                        break;
                    }
                    case AAC_DECODER:
                    {
#ifdef SHAREME_MASTER
                        Transform rtp_encode = 0;
                        rtp_encode = rtp_encode;
                        StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
                        PRINT(("DECODER: AAC packet_size=%u scms=%u transform=0x%X\n",DECODER->packet_size,content_protection,(uint16)rtp_encode));
#else
                        /* Not currently supported */
                        PRINT(("DECODER: AAC\n"));
#endif
                        break;
                    }
                    case FASTSTREAM_SINK:
                        /* Not currently supported */
                        PRINT(("DECODER: FASTSTREAM\n"));
                        break;
                    case APTX_DECODER:
                        if (content_protection)
                        {
#ifdef SHAREME_MASTER
                            Transform rtp_encode = 0;
                            rtp_encode = rtp_encode;
                            StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
#else
                            Transform rtp_encode = TransformRtpEncode(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
                            TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_ENCODE_PACKET_SIZE, DECODER->packet_size);   /* Configure the RTP transform to generate the selected packet size */
                            TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_ENCODE_MANAGE_TIMING, FALSE);    /* Transform should not manage timings. */
                            TransformConfigure(rtp_encode, VM_TRANSFORM_RTP_SCMS_ENABLE, content_protection);   /* Ensure transform supports content protection if reqd. */
                            (void)TransformStart( rtp_encode ) ;
#endif
							csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_SHAREME);
                            PRINT(("DECODER: APTX packet_size=%u scms=%u transform=0x%X\n",DECODER->packet_size,content_protection,(uint16)rtp_encode));
                        }
                        else
                        {
                            StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
							csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_SHAREME);
                            PRINT(("DECODER: APTX packet_size=%u scms=%u transform=none\n",DECODER->packet_size,content_protection));
                        }
                        break;
                    case APTX_ACL_SPRINT_DECODER:
                        /* Not currently supported */
                        PRINT(("DECODER: APTX-LL\n"));
                        break;
					case TWS_SBC_DECODER:
						StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
						csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_TWS_MASTER);
                        csrA2dpDecoderSetTwsRoutingMode(DECODER->master_routing_mode, DECODER->slave_routing_mode);
						PRINT(("DECODER: TWS_SBC packet_size=%u scms=%u transform=none\n",DECODER->packet_size,content_protection));
						break;
					case TWS_MP3_DECODER:
						StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
						csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_TWS_MASTER);
                        csrA2dpDecoderSetTwsRoutingMode(DECODER->master_routing_mode, DECODER->slave_routing_mode);
						PRINT(("DECODER: TWS_MP3 packet_size=%u scms=%u transform=none\n",DECODER->packet_size,content_protection));
						break;
					case TWS_AAC_DECODER:
						StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
						csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_TWS_MASTER);
                        csrA2dpDecoderSetTwsRoutingMode(DECODER->master_routing_mode, DECODER->slave_routing_mode);
						PRINT(("DECODER: TWS_AAC packet_size=%u scms=%u transform=none\n",DECODER->packet_size,content_protection));
						break;
					case TWS_APTX_DECODER:
						StreamConnect(StreamKalimbaSource(DSP_FORWARDING_PORT),DECODER->forwarding_sink);
						csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_TWS_MASTER);
                        csrA2dpDecoderSetTwsRoutingMode(DECODER->master_routing_mode, DECODER->slave_routing_mode);
						PRINT(("DECODER: TWS_APTX packet_size=%u scms=%u transform=none\n",DECODER->packet_size,content_protection));
						break;
                    default:
                        PRINT(("DECODER: UNKNOWN\n"));
                        break;
                    }
                }
       }
       /* forwarding no longer enabled */       
       else
       {
			csrA2dpDecoderSetStreamRelayMode(RELAY_MODE_NONE);
			
			/* if forwarding connected then disconnect it */
			if (DECODER->forwarding_sink)
			{
				Transform transform = TransformFromSink( DECODER->forwarding_sink );
				if (transform)
				{
					(void)TransformStop( transform );
					TransformDisconnect( transform );   /* TODO: Are both needed? */
				}
    
				StreamDisconnect( 0, DECODER->forwarding_sink);
    
				PRINT(("DECODER: Disabling forwarding_sink=0x%X transform=0x%X\n", (uint16)DECODER->forwarding_sink,(uint16)transform));
				DECODER->forwarding_sink = NULL;
            }
        }
    }
}
