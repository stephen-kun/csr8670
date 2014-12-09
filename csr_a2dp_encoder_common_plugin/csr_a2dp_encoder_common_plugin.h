/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_encoder_common_plugin.h

DESCRIPTION
    
    
NOTES
   
*/

#ifndef _CSR_A2DP_ENCODER_COMMON_PLUGIN_H_
#define _CSR_A2DP_ENCODER_COMMON_PLUGIN_H_


#include <message.h>


#define CSR_A2DP_ENCODER_PLUGIN_MAX_A2DP_SINKS    2 /* handle 2 A2DP Sink maximum */


typedef enum
{
    A2dpEncoderInputDeviceUsb,
    A2dpEncoderInputDeviceAnalogue,
    A2dpEncoderInputDeviceSPDIF
} A2dpEncoderInputDeviceType;

typedef enum
{
    A2dpEncoderEqModeBypass,
    A2dpEncoderEqMode1,
    A2dpEncoderEqMode2,
    A2dpEncoderEqMode3,
    A2dpEncoderEqMode4
} A2dpEncoderEqMode;


typedef struct
{
    A2dpEncoderEqMode eq_mode;                              /* EQ mode to use */
    Sink connect_sink;                                      /* Will connect the audio for the device if this Sink is supplied */
    Sink disconnect_sink;                                   /* Will disconnect the audio for the device if this Sink is supplied */
    unsigned bitpool:8;                                     /* Bitpool value to use for streaming */
    unsigned bad_link_bitpool:8;                            /* Bitpool value to use for bad link streaming */
} A2dpEncoderPluginModeParams;


typedef struct
{
    unsigned input_device_type:4;                           /* USB or Analogue */
    unsigned unused:3;                                      /* Unused */
    unsigned content_protection:1;                          /* Enable content protection (SCMS-T) flag */
    unsigned bitpool:8;                                     /* Encoding Bitpool value in use by the codec */
    unsigned bad_link_bitpool:8;                            /* Encoding Bitpool value when in bad link situation */
    unsigned format:8;                                      /* Encoding format in use by the codec */
    uint16 packet_size;                                     /* Encode packet size to use */
    uint32 rate;                                            /* Additional rate */
    A2dpEncoderPluginModeParams *mode;                      /* Mode parameters */
    Sink a2dp_sink[CSR_A2DP_ENCODER_PLUGIN_MAX_A2DP_SINKS]; /* A2DP media Sinks */ 
    Source input_source;                                    /* Input Source (USB/Analogue) */
    Sink input_sink;                                        /* Input Sink (USB/Analogue) */
} A2dpEncoderPluginConnectParams;


typedef struct
{
    TaskData    data;
    unsigned    a2dp_plugin_variant:3 ;    /* Selects the A2DP plugin variant */
    unsigned    reserved:13 ;            /* Set the reserved bits to zero */
}A2dpEncoderPluginTaskdata;


extern const A2dpEncoderPluginTaskdata csr_a2dp_sbc_encoder_plugin;
extern const A2dpEncoderPluginTaskdata csr_a2dp_faststream_encoder_plugin;
extern const A2dpEncoderPluginTaskdata csr_a2dp_aptx_encoder_plugin;
extern const A2dpEncoderPluginTaskdata csr_a2dp_aptx_lowlatency_encoder_plugin;


#endif /* _CSR_A2DP_ENCODER_COMMON_PLUGIN_H_ */

