/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_encoder_common_if.h

DESCRIPTION
    Private interface for A2DP Encoder Plugin.

*/

#ifndef _CSR_A2DP_ENCODER_COMMON_INTERFACE_H_
#define _CSR_A2DP_ENCODER_COMMON_INTERFACE_H_


typedef enum
{
    SBC_ENCODER                 = 1
    ,FASTSTREAM_ENCODER         = 2
    ,APTX_ENCODER               = 3
    ,APTX_LOWLATENCY_ENCODER    = 4
}A2DP_ENCODER_PLUGIN_TYPE_T;

/* DSP message structure */
typedef struct
{
    uint16 id;
    uint16 a;
    uint16 b;
    uint16 c;
    uint16 d;
} DSP_REGISTER_T;

/* DSP SPDIF configuration and event messages */
#define MESSAGE_SET_SPDIF_CONFIG_MSG    (0x1073)    /* VM -> DSP */
#define KALIMBA_MSG_DSP_SPDIF_EVENT_MSG (0x1075)    /* DSP -> VM */

/* KALIMBA_MSG_DSP_SPDIF_EVENT_MSG Parameter 'a' */
#define SPDIF_EVENT_STREAM_VALID        (0x0000)

#endif /* _CSR_A2DP_ENCODER_COMMON_INTERFACE_H_ */
