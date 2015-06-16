/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_if.h

DESCRIPTION
    Message definitions for A2DP plugins.

*/

/*!
@file csr_a2dp_decoder_common_if.h

@brief
   Definitions for A2DP plugins.

   @description


*/

#ifndef _CSR_A2DP_DECODER_COMMON_INTERFACE_H_
#define _CSR_A2DP_DECODER_COMMON_INTERFACE_H_

/* ports used by the low latency gaming applications */
#define CVC_1MIC_PORT           0
#define CVC_2MIC_PORT           1
#define CVC_BACK_CHANNEL_PORT   2

/* Port used by the DSP to route undecoded audio packets for transmission to another device */
#define DSP_FORWARDING_PORT     4
#define DSP_ESCO_SUB_PORT       2
#define DSP_L2CAP_SUB_PORT      3
#define DSP_SUB_PORT_FAILED     255

/* ports used by the USB audio app */
#define USB_AUDIO_TO_DSP_PORT   0
#define USB_MIC_TO_DSP_PORT     4
#define USB_DSP_TO_MIC_PORT     2

/* ports used by the wired input including FM input */
#define WIRED_LINE_A_TO_DSP_PORT 0
#define WIRED_LINE_B_TO_DSP_PORT 1

/* a2dp codec to dsp for standard latency apps */
#define CODEC_TO_DSP_PORT        0

/* a2dp codec to dsp for low latency apps */
#define LOW_LATENCY_CODEC_TO_DSP_PORT 2

/* dsp audio output ports, common to all apps */
#define AUDIO_OUT_FROM_DSP_LEFT  0
#define AUDIO_OUT_FROM_DSP_RIGHT 1



typedef enum
{
     DSP_SBC_DECODER                = SBC_DECODER
    ,DSP_MP3_DECODER                = MP3_DECODER
    ,DSP_AAC_DECODER                = AAC_DECODER
    ,DSP_FASTSTREAM_SINK            = FASTSTREAM_SINK
    ,DSP_USB_DECODER                = USB_DECODER
    ,DSP_APTX_DECODER               = APTX_DECODER
    ,DSP_APTX_ACL_SPRINT_DECODER    = APTX_ACL_SPRINT_DECODER
    ,DSP_ANALOG_DECODER             = ANALOG_DECODER
    ,DSP_SPDIF_DECODER              = SPDIF_DECODER                                  
} DSP_PLUGIN_TYPE;

/* dsp message structure*/
typedef struct
{
    uint16 id;
    uint16 a;
    uint16 b;
    uint16 c;
    uint16 d;
} DSP_REGISTER_T;



#endif

