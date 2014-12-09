/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
   csr_ag_audio_plugin.h

DESCRIPTION
    
    
NOTES
   
*/
#ifndef _CSR_AG_AUDIO_PLUGIN_H_
#define _CSR_AG_AUDIO_PLUGIN_H_

#include <audio_plugin_if.h>
#include <message.h> 

/*!  audio plugin
   This is an audio plugin that can be used with the audio library.
*/


/* Number of warp values stored for AGHFP audio */
#define CSR_AG_AUDIO_WARP_NUMBER_VALUES 4


typedef struct
{
    Source usb_source;
    Sink usb_sink;  
} CsrAgAudioPluginUsbParams;

typedef struct
{
    common_mic_params *mic;
    CsrAgAudioPluginUsbParams *usb;
    uint16 warp[CSR_AG_AUDIO_WARP_NUMBER_VALUES];
} CsrAgAudioPluginConnectParams;

typedef struct
{
   TaskData   data;
   unsigned	  plugin_variant:4;          /* Selects the plugin variant */
   unsigned   two_mic:1;                 /* Set the bit if using 2mic plugin */
   unsigned   reserved:11;               /* Set the reserved bits to zero */
}CsrAgAudioPluginTaskData;

extern const CsrAgAudioPluginTaskData csr_ag_audio_cvsd_8k_1mic_plugin;     /* variant for CVSD at 8kHz rate */

extern const CsrAgAudioPluginTaskData csr_ag_audio_cvsd_48k_1mic_plugin;    /* variant for CVSD at 48kHz rate, with conversion for 8kHz Bluetooth audio */

extern const CsrAgAudioPluginTaskData csr_ag_audio_cvsd_8k_2mic_plugin;     

extern const CsrAgAudioPluginTaskData csr_ag_audio_sbc_16k_1mic_plugin;     /* variant for mSBC at 16kHz rate */

extern const CsrAgAudioPluginTaskData csr_ag_audio_sbc_48k_1mic_plugin;     /* variant for mSBC at 48kHz rate, with conversion for 16kHz Bluetooth audio */

extern const CsrAgAudioPluginTaskData csr_ag_audio_sbc_2mic_plugin;

#endif

