/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_usb.c

DESCRIPTION
    USB functionality.
    
*/


/* header for this file */
#include "source_usb.h"
/* application header files */
#include "source_app_msg_handler.h"
#include "source_debug.h"
#include "source_memory.h"
#include "source_private.h"
#include "source_ps.h"
#include "source_volume.h"
/* profile/library headers */
#include <usb_device_class.h>
/* VM headers */
#include <boot.h>
#include <panic.h>
#include <stdlib.h>
#include <stream.h>
#include <string.h>


#ifdef DEBUG_USB
    #define USB_DEBUG(x) DEBUG(x)
#else
    #define USB_DEBUG(x)
#endif  


/* USB HID class descriptor - Consumer Transport Control Device*/
static const uint8 usb_interface_descriptor_hid_consumer_transport[] =
{
    USB_HID_DESCRIPTOR_LENGTH,                              /* bLength */
    USB_B_DESCRIPTOR_TYPE_HID,                              /* bDescriptorType */
    0x11, 0x01,                                             /* bcdHID */
    0,                                                      /* bCountryCode */
    1,                                                      /* bNumDescriptors */
    USB_B_DESCRIPTOR_TYPE_HID_REPORT,                       /* bDescriptorType */
    USB_HID_CONSUMER_TRANSPORT_REPORT_DESCRIPTOR_LENGTH,    /* wDescriptorLength */
    0                                                       /* wDescriptorLength */
};

/* HID Report Descriptor - Consumer Transport Control Device */
static const uint8 usb_report_descriptor_hid_consumer_transport[USB_HID_CONSUMER_TRANSPORT_REPORT_DESCRIPTOR_LENGTH] = 
{
    0x05, 0x0C,                  /* USAGE_PAGE (Consumer Devices) */
    0x09, 0x01,                  /* USAGE (Consumer Control) */
    0xa1, 0x01,                  /* COLLECTION (Application) */    
    0x85, 0x01,                  /*   REPORT_ID (1) */    
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                  /*   LOGICAL_MAXIMUM (1) */
    0x09, 0xcd,                  /*   USAGE (Play/Pause) */
    0x09, 0xb5,                  /*   USAGE (Scan Next Track) */
    0x09, 0xb6,                  /*   USAGE (Scan Previous Track) */
    0x09, 0xb7,                  /*   USAGE (Stop) */
    0x75, 0x01,                  /*   REPORT_SIZE (1) */
    0x95, 0x04,                  /*   REPORT_COUNT (4) */
    0x81, 0x02,                  /*   INPUT (Data,Var,Abs,Bit Field) */    
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                  /*   LOGICAL_MAXIMUM (1) */
    0x09, 0xb0,                  /*   USAGE (Play) */
    0x09, 0xb1,                  /*   USAGE (Pause) */
    0x09, 0xb3,                  /*   USAGE (Fast Forward) */
    0x09, 0xb4,                  /*   USAGE (Rewind) */
    0x75, 0x01,                  /*   REPORT_SIZE (1) */
    0x95, 0x04,                  /*   REPORT_COUNT (4) */    
    0x81, 0x22,                  /*   INPUT (Data,Var,Abs,Bit Field) */    
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                  /*   LOGICAL_MAXIMUM (1) */
    0x09, 0xe9,                  /*   USAGE (Volume Increment) */
    0x09, 0xea,                  /*   USAGE (Volume Decrement) */
    0x09, 0xe2,                  /*   USAGE (Mute) */
    0x75, 0x01,                  /*   REPORT_SIZE (1) */
    0x95, 0x03,                  /*   REPORT_COUNT (3) */    
    0x81, 0x22,                  /*   INPUT (Data,Var,Abs,Bit Field) */
    0x75, 0x05,                  /*   REPORT_SIZE (5) */
    0x95, 0x01,                  /*   REPORT_COUNT (1) */    
    0x81, 0x01,                  /*   INPUT (Const,Array,Abs,Bit Field) */    
    0xc0,                        /* END_COLLECTION */
    
    0x06, 0xa0, 0xff,            /* USAGE_PAGE (Vendor-defined 0xFFA0) */
    0x09, 0x01,                  /* USAGE (Vendor-defined 0x0001) */
    0xa1, 0x01,                  /* COLLECTION (Application) */  
    0x85, 0x02,                  /*   REPORT_ID (2) */  
    0x09, 0x01,                  /*   USAGE (Vendor-defined 0x0001) */
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x26, 0xff, 0x00,            /*   LOGICAL_MAXIMUM (255) */
    0x75, 0x08,                  /*   REPORT_SIZE (8) */
    0x95, 0x12,                  /*   REPORT_COUNT (18) */    
    0x91, 0x00,                  /*   OUTPUT (Data,Array,Abs,Non-volatile,Bit Field) */
    0x09, 0x02,                  /*   USAGE (Vendor-defined 0x0002) */    
    0x75, 0x08,                  /*   REPORT_SIZE (8) */
    0x95, 0x12,                  /*   REPORT_COUNT (18) */     
    0x81, 0x00,                  /*   INPUT (Const,Array,Abs,Bit Field) */
    
    0xc0
};

static const EndPointInfo usb_epinfo_hid_consumer_transport[] =
{
    {        
        end_point_int_out, /* address */
        end_point_attr_int, /* attributes */
        16, /* max packet size */
        1, /* poll_interval */
        0, /* data to be appended */
        0, /* length of data appended */
    }
};

static const usb_device_class_hid_consumer_transport_config usb_descriptor_hid_consumer_transport =
{
    {usb_interface_descriptor_hid_consumer_transport,
    sizeof(usb_interface_descriptor_hid_consumer_transport),
    usb_epinfo_hid_consumer_transport},
    {usb_report_descriptor_hid_consumer_transport,
    sizeof(usb_report_descriptor_hid_consumer_transport),
    NULL}
};


/* USB Audio Class Descriptors */
static const uint8 usb_interface_descriptor_control_mic_and_speaker[] =
{
    /* Class Specific Header */
    0x0A,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = HEADER */
    0x00, 0x01,   /* bcdADC = Audio Device Class v1.00 */
#ifdef USB_AUDIO_STEREO_SPEAKER    
    0x0A + 0x0c + 0x0a + 0x09 + 0x0c + 0x09 + 0x09, /* wTotalLength LSB */
#else
    0x0A + 0x0c + 0x09 + 0x09 + 0x0c + 0x09 + 0x09, /* wTotalLength LSB */
#endif    
    0x00,         /* wTotalLength MSB */
    0x02,         /* bInCollection = 2 AudioStreaming interfaces */
    0x01,         /* baInterfaceNr(1) - AS#1 id */
    0x02,         /* baInterfaceNr(2) - AS#2 id */
    
    /* Speaker IT */
    0x0c,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = INPUT_TERMINAL */
    USB_AUDIO_SPEAKER_IT,       /* bTerminalID */
    0x01, 0x01,   /* wTerminalType = USB streaming */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_CHANNELS_SPEAKER, /* bNrChannels */
    USB_AUDIO_CHANNEL_CONFIG_SPEAKER & 0xFF, USB_AUDIO_CHANNEL_CONFIG_SPEAKER >> 8,   /* wChannelConfig */
    0x00,         /* iChannelName = no string */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Speaker Features */
#ifdef USB_AUDIO_STEREO_SPEAKER    
    0x0a,           /*bLength*/
#else
    0x09,           /*bLength*/
#endif    
    0x24,           /*bDescriptorType = CS_INTERFACE */
    0x06,           /*bDescriptorSubType = FEATURE_UNIT*/
    USB_AUDIO_SPEAKER_FU,     /*bUnitId*/
    USB_AUDIO_SPEAKER_IT,     /*bSourceId - Speaker IT*/
    0x01,           /*bControlSize = 1 byte per control*/
    0x03,           /*bmaControls[0] = 03 (Master Channel - mute and volume)*/
    0x00,           /*bmaControls[1] = 00 (Logical Channel 1 - nothing)*/ 
#ifdef USB_AUDIO_STEREO_SPEAKER    
    0x00,           /*bmaControls[2] = 00 (Logical Channel 2 - nothing)*/
#endif    
    0x00,           /*iFeature = same as USB product string*/
    
    /* Speaker OT */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x03,         /* bDescriptorSubType = OUTPUT_TERMINAL */
    USB_AUDIO_SPEAKER_OT,   /* bTerminalID */
    0x01, 0x03,   /* wTerminalType = Speaker */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_SPEAKER_FU,   /* bSourceID - Speaker Features */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Microphone IT */
    0x0c,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = INPUT_TERMINAL */
    USB_AUDIO_MIC_IT,       /* bTerminalID */
    0x01, 0x02,   /* wTerminalType = Microphone */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_CHANNELS_MIC, /* bNrChannels */
    USB_AUDIO_CHANNEL_CONFIG_MIC & 0xFF, USB_AUDIO_CHANNEL_CONFIG_MIC >> 8,   /* wChannelConfig */
    0x00,         /* iChannelName = no string */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Microphone Features */
    0x09,           /*bLength*/
    0x24,           /*bDescriptorType = CS_INTERFACE */
    0x06,           /*bDescriptorSubType = FEATURE_UNIT*/
    USB_AUDIO_MIC_FU,         /*bUnitId*/
    USB_AUDIO_MIC_IT,         /*bSourceId - Microphone IT*/
    0x01,           /*bControlSize = 1 byte per control*/
    0x02,           /*bmaControls[0] = 02 (Master Channel - volume)*/
    0x00,           /*bmaControls[0] = 00 (Logical Channel 1 - nothing)*/
    0x00,           /*iFeature = same as USB product string*/

    /* Microphone OT */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x03,         /* bDescriptorSubType = OUTPUT_TERMINAL */
    USB_AUDIO_MIC_OT,       /* bTerminalID */
    0x01, 0x01,   /* wTerminalType = USB streaming */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_MIC_FU,       /* bSourceID - Microphone Features */
    0x00          /* iTerminal = same as USB product string */  
};

static const uint8 usb_interface_descriptor_control_mic[] =
{
    /* Class Specific Header */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = HEADER */
    0x00, 0x01, /* bcdADC = Audio Device Class v1.00 */
    0x09 + 0x0c + 0x09 + 0x09, /* wTotalLength LSB */
    0x00,         /* wTotalLength MSB */
    0x01,         /* bInCollection = 1 AudioStreaming interface */
    0x01,         /* baInterfaceNr(1) - AS#1 id */

    /* Microphone IT */
    0x0c,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = INPUT_TERMINAL */
    USB_AUDIO_MIC_IT, /* bTerminalID */
    0x01, 0x02,   /* wTerminalType = Microphone */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_CHANNELS_MIC, /* bNrChannels */
    USB_AUDIO_CHANNEL_CONFIG_MIC & 0xFF, USB_AUDIO_CHANNEL_CONFIG_MIC >> 8, /* wChannelConfig */
    0x00,         /* iChannelName = no string */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Microphone Features */
    0x09,           /*bLength*/
    0x24,           /*bDescriptorType = CS_INTERFACE */
    0x06,           /*bDescriptorSubType = FEATURE_UNIT*/
    USB_AUDIO_MIC_FU,         /*bUnitId*/
    USB_AUDIO_MIC_IT,         /*bSourceId - Microphone IT*/
    0x01,           /*bControlSize = 1 byte per control*/
    0x02,           /*bmaControls[0] = 0001 (Master Channel - volume)*/
    0x00,           /*bmaControls[1] = 0000 (Logical Channel 1 - nothing)*/
    0x00,           /*iFeature = same as USB product string*/

    /* Microphone OT */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x03,         /* bDescriptorSubType = OUTPUT_TERMINAL */
    USB_AUDIO_MIC_OT,       /* bTerminalID */
    0x01, 0x01,   /* wTerminalType = USB streaming */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_MIC_FU,       /* bSourceID - Microphone Features */
    0x00,         /* iTerminal = same as USB product string */
};


static const uint8 usb_interface_descriptor_control_speaker[] =
{
    /* Class Specific Header */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = HEADER */
    0x00, 0x01, /* bcdADC = Audio Device Class v1.00 */
#ifdef USB_AUDIO_STEREO_SPEAKER    
    0x09 + 0x0c + 0x0a + 0x09, /* wTotalLength LSB */
#else
    0x09 + 0x0c + 0x09 + 0x09, /* wTotalLength LSB */
#endif    
    0x00,         /* wTotalLength MSB */
    0x01,         /* bInCollection = 1 AudioStreaming interface */
    0x01,         /* baInterfaceNr(1) - AS#1 id */
    
    /* Speaker IT */
    0x0c,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = INPUT_TERMINAL */
    USB_AUDIO_SPEAKER_IT,   /* bTerminalID */
    0x01, 0x01,   /* wTerminalType = USB streaming */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_CHANNELS_SPEAKER, /* bNrChannels */
    USB_AUDIO_CHANNEL_CONFIG_SPEAKER & 0xFF, USB_AUDIO_CHANNEL_CONFIG_SPEAKER >> 8, /* wChannelConfig */
    0x00,         /* iChannelName = no string */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Speaker Features */
#ifdef USB_AUDIO_STEREO_SPEAKER    
    0x0a,           /*bLength*/
#else
    0x09,           /*bLength*/
#endif    
    0x24,           /*bDescriptorType = CS_INTERFACE */
    0x06,           /*bDescriptorSubType = FEATURE_UNIT*/
    USB_AUDIO_SPEAKER_FU,     /*bUnitId*/
    USB_AUDIO_SPEAKER_IT,     /*bSourceId - Speaker IT*/
    0x01,           /*bControlSize = 1 byte per control*/
    0x03,           /*bmaControls[0] = 03 (Master Channel - mute and volume)*/
    0x00,           /*bmaControls[1] = 00 (Logical Channel 1 - nothing)*/
#ifdef USB_AUDIO_STEREO_SPEAKER    
    0x00,           /*bmaControls[2] = 00 (Logical Channel 2 - nothing)*/
#endif    
    0x00,           /*iFeature = same as USB product string*/

    /* Speaker OT */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x03,         /* bDescriptorSubType = OUTPUT_TERMINAL */
    USB_AUDIO_SPEAKER_OT,   /* bTerminalID */
    0x01, 0x03,   /* wTerminalType = Speaker */
    0x00,         /* bAssocTerminal = none */
    USB_AUDIO_SPEAKER_FU,   /* bSourceID - Speaker Features*/
    0x00,         /* iTerminal = same as USB product string */
};


static const uint8 usb_interface_descriptor_streaming_mic[] =
{
    /* Class Specific AS interface descriptor */
    0x07,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    USB_AUDIO_MIC_OT,       /* bTerminalLink = Microphone OT */
    0x00,         /* bDelay */
    0x01, 0x00,   /* wFormatTag = PCM */

    /* Type 1 format type descriptor */
    0x08 + 0x03,  /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = FORMAT_TYPE */
    0x01,         /* bFormatType = FORMAT_TYPE_I */
    USB_AUDIO_CHANNELS_MIC, /* bNumberOfChannels */
    0x02,         /* bSubframeSize = 2 bytes */
    0x10,         /* bBitsResolution */
    0x01,         /* bSampleFreqType = 1 discrete sampling freq */
    0xFF & (USB_AUDIO_SAMPLE_RATE_MIC),       /* tSampleFreq */
    0xFF & (USB_AUDIO_SAMPLE_RATE_MIC >> 8),  /* tSampleFreq */
    0xFF & (USB_AUDIO_SAMPLE_RATE_MIC >> 16), /* tSampleFreq */

    /* Class specific AS isochronous audio data endpoint descriptor */
    0x07,         /* bLength */
    0x25,         /* bDescriptorType = CS_ENDPOINT */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    0x00,         /* bmAttributes = none */
    0x02,         /* bLockDelayUnits = Decoded PCM samples */
    0x00, 0x00     /* wLockDelay */
};

static const uint8 usb_interface_descriptor_streaming_speaker[] =
{
    /* Class Specific AS interface descriptor */
    0x07,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    USB_AUDIO_SPEAKER_IT,       /* bTerminalLink = Speaker IT */
    0x00,         /* bDelay */
    0x01, 0x00,   /* wFormatTag = PCM */

    /* Type 1 format type descriptor */
    0x08 + 0x03,/* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = FORMAT_TYPE */
    0x01,         /* bFormatType = FORMAT_TYPE_I */
    USB_AUDIO_CHANNELS_SPEAKER, /* bNumberOfChannels */
    0x02,         /* bSubframeSize = 2 bytes */
    0x10,         /* bBitsResolution */
    0x01,         /* bSampleFreqType = 1 discrete sampling freq */
    0xFF & (USB_AUDIO_SAMPLE_RATE_SPEAKER),       /* tSampleFreq */
    0xFF & (USB_AUDIO_SAMPLE_RATE_SPEAKER >> 8),  /* tSampleFreq */
    0xFF & (USB_AUDIO_SAMPLE_RATE_SPEAKER >> 16), /* tSampleFreq */

    /* Class specific AS isochronous audio data endpoint descriptor */
    0x07,         /* bLength */
    0x25,         /* bDescriptorType = CS_ENDPOINT */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    0x81,         /* bmAttributes = MaxPacketsOnly and SamplingFrequency control */
    0x02,         /* bLockDelayUnits = Decoded PCM samples */
    0x00, 0x00    /* wLockDelay */
};

static const uint8 usb_audio_endpoint_user_data[] =
{
    0, /* bRefresh */
    0  /* bSyncAddress */
};


/*  Streaming Isochronous Endpoint. Maximum packet size 192 (stereo at 48khz) */
static const EndPointInfo usb_epinfo_streaming_speaker[] =
{
    {
        end_point_iso_in, /* address */
        end_point_attr_iso, /* attributes */
        USB_AUDIO_MAX_PACKET_SIZE_SPEAKER, /* max packet size */
        1, /* poll_interval */
        usb_audio_endpoint_user_data, /* data to be appended */
        sizeof(usb_audio_endpoint_user_data) /* length of data appended */      
    }
};


/* Streaming Isochronous Endpoint. Maximum packet size 96 (mono at 48khz) */
static const EndPointInfo usb_epinfo_streaming_mic[] =
{
    {
        end_point_iso_out, /* address */
        end_point_attr_iso, /* attributes */
        USB_AUDIO_MAX_PACKET_SIZE_MIC, /* max packet size */
        1, /* poll_interval */
        usb_audio_endpoint_user_data, /* data to be appended */
        sizeof(usb_audio_endpoint_user_data), /* length of data appended */
    }
};

static const usb_device_class_audio_config usb_descriptor_audio =
{
    {usb_interface_descriptor_control_mic_and_speaker,
    sizeof(usb_interface_descriptor_control_mic_and_speaker),
    NULL},
    {usb_interface_descriptor_streaming_mic,
    sizeof(usb_interface_descriptor_streaming_mic),
    usb_epinfo_streaming_mic},
    {usb_interface_descriptor_streaming_speaker,
    sizeof(usb_interface_descriptor_streaming_speaker),
    usb_epinfo_streaming_speaker}
};

static const usb_device_class_audio_config usb_descriptor_mic =
{
    {usb_interface_descriptor_control_mic,
    sizeof(usb_interface_descriptor_control_mic),
    NULL},
    {usb_interface_descriptor_streaming_mic,
    sizeof(usb_interface_descriptor_streaming_mic),
    usb_epinfo_streaming_mic},
    {NULL, 
     0, 
     NULL}
};

static const usb_device_class_audio_config usb_descriptor_speaker =
{
    {usb_interface_descriptor_control_speaker,
    sizeof(usb_interface_descriptor_control_speaker),
    NULL},
    {NULL,
     0,
     NULL},
    {usb_interface_descriptor_streaming_speaker,
    sizeof(usb_interface_descriptor_streaming_speaker),
    usb_epinfo_streaming_speaker}
};

/* USB audio level configuration */
static const usb_device_class_audio_volume_config usb_audio_levels = {  0xf100, /* speaker_min */
                                                                        0x0000, /* speaker_max */
                                                                        0x0100, /* speaker_res */
                                                                        0xfb00, /* speaker_default */
                                                                        0x0000, /* mic_min */
                                                                        0x1f00, /* mic_max */
                                                                        0x0100, /* mic_res */
                                                                        0x1800  /* mic_default */
                                                                    };


/* Mic table for converting USB volume to local volume */
#define MIC_VOLUME_TABLE_START (9)
static const uint16 micVolumeTable[VOLUME_MAX_MIC_VALUE + 1] =
{
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START, 
    MIC_VOLUME_TABLE_START, 
    MIC_VOLUME_TABLE_START, 
    MIC_VOLUME_TABLE_START, 
    MIC_VOLUME_TABLE_START, 
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START,
    MIC_VOLUME_TABLE_START + 1,
    MIC_VOLUME_TABLE_START + 1, 
    MIC_VOLUME_TABLE_START + 1,
    MIC_VOLUME_TABLE_START + 1,
    MIC_VOLUME_TABLE_START + 1,
    MIC_VOLUME_TABLE_START + 1,
    MIC_VOLUME_TABLE_START + 1,
    MIC_VOLUME_TABLE_START + 2,
    MIC_VOLUME_TABLE_START + 2, 
    MIC_VOLUME_TABLE_START + 2, 
    MIC_VOLUME_TABLE_START + 2,
    MIC_VOLUME_TABLE_START + 2,
    MIC_VOLUME_TABLE_START + 3,
    MIC_VOLUME_TABLE_START + 3,
    MIC_VOLUME_TABLE_START + 3,
    MIC_VOLUME_TABLE_START + 3
};


/***************************************************************************
Functions
****************************************************************************
*/


/****************************************************************************
NAME    
    usb_unhandled_host_command - Unhandled command received from the Host
*/
static void usb_unhandled_host_command(uint8 cmd, uint8 sub_cmd)
{
    USB_DEBUG(("    USB Host Command Unhandled: Cmd[%d] Sub[%d]\n", cmd, sub_cmd));    
}


/****************************************************************************
NAME    
    usb_vol_mic_rounded - Convert USB Microphone volume to local volume level
*/
static uint16 usb_vol_mic_rounded(uint16 volume)
{
    int16 newVol = volume >> 8;
    
    if (newVol & 0x80)
    {
        /* sign extend */
        newVol |= 0xFF00;
    }

    if (volume == 0x8000)
    {
        return VOLUME_MIN_INDEX;
    }
    
    if ((newVol <= VOLUME_MAX_MIC_VALUE) &&
        (newVol >= VOLUME_MIN_MIC_VALUE))
    {
        return micVolumeTable[newVol];
    }
    
    return VOLUME_MIN_INDEX;
}


/****************************************************************************
NAME    
    usb_vol_speaker_rounded - Convert USB Speaker volume to local volume level
*/
static uint16 usb_vol_speaker_rounded(uint16 volume)
{
    /* convert USB volume to a volume index that can be sent to the remote side (0 - 16) */
    int16 newVol = volume >> 8;
    
    if (newVol & 0x80)
    {
        /* sign extend */
        newVol |= 0xFF00;
    }

    if (volume == 0x8000)
    {
        return VOLUME_MIN_INDEX;
    }
    
    if (volume == usb_audio_levels.speaker_max)
    {
        return VOLUME_MAX_INDEX;
    }
    
    if ((newVol <= VOLUME_MAX_SPEAKER_VALUE) &&
        (newVol >= VOLUME_MIN_SPEAKER_VALUE))
    {
        return (newVol - VOLUME_MIN_SPEAKER_VALUE);
    }
    
    return VOLUME_MIN_INDEX;
}


/****************************************************************************
NAME    
    usb_convert_report_state - Convert application state to a bit position for reporting current state to the USB host
*/
static USB_DEVICE_DATA_STATE_T usb_convert_report_state(SOURCE_STATE_T state)
{
    switch (state)
    {
        case SOURCE_STATE_CONNECTABLE:        
            return USB_DEVICE_DATA_STATE_PAGE_SCAN;
      
        case SOURCE_STATE_DISCOVERABLE:
            return USB_DEVICE_DATA_STATE_INQUIRY_SCAN;
       
        case SOURCE_STATE_CONNECTING:
            return USB_DEVICE_DATA_STATE_PAGE;
        
        case SOURCE_STATE_INQUIRING:
            return USB_DEVICE_DATA_STATE_INQUIRY;
        
        case SOURCE_STATE_CONNECTED:
            return USB_DEVICE_DATA_STATE_CONNECTED;
        
        default:
            return USB_DEVICE_DATA_STATE_UNKNOWN;
    }
}


/****************************************************************************
NAME    
    usb_clear_report_data - Clears a report by setting values to 0
*/
static void usb_clear_report_data(uint8 *report, uint16 report_size)
{
    uint16 index = 0;
    
    for (index = 0; index < report_size; index++)
    {
        report[index] = 0;
    }
}


/****************************************************************************
NAME    
    usb_send_device_command_status - Send application state to host
*/
static bool usb_send_device_command_status(void)
{
    USB_DEVICE_DATA_STATE_T status;
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];    
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Bytes 2-17 - Command Data
           
    */
    
    SOURCE_STATE_T current_state = states_get_state();
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    if (current_state == SOURCE_STATE_IDLE)
    {
        /* if IDLE state, use the pre IDLE state */
        current_state = theSource->app_data.pre_idle_state;
    }
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_STATE;
    report_bytes[1] = 0;
    
    status = usb_convert_report_state(current_state);
    
    if (status != USB_DEVICE_DATA_STATE_UNKNOWN)
    {
        /*  set data byte indicating status */   
        report_bytes[1] = status;        
    }
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_process_host_command_connection - Handles the Host command for current Host connection state
*/
static void usb_process_host_command_connection(uint8 data)
{
    if (data)
    {
        /* Host connected */
        usb_set_hid_mode(USB_HID_MODE_HOST);
    }
    else
    {
        /* Host disconnected */
        usb_set_hid_mode(USB_HID_MODE_CONSUMER);
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_status - Handles the Host command for current status
*/
static void usb_process_host_command_status(uint8 data)
{
    switch (data)
    {
        case USB_HOST_DATA_STATE_ENTER_DUT_MODE:
        {
            USB_DEBUG(("    --- Enter DUT Mode ---\n"));
            MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);
            states_set_state(SOURCE_STATE_TEST_MODE);
        }
        break;
        
        case USB_HOST_DATA_STATE_ENTER_DFU_MODE:
        {
            USB_DEBUG(("    --- Enter DFU Mode ---\n")); 
            BootSetMode(0);        
        }
        break;
        
        case USB_HOST_DATA_STATE_GET_STATE:
        {
            USB_DEBUG(("    --- Get State ---\n")); 
            /* return status to Host */
            usb_send_device_command_status();
        }    
        break;
        
        case USB_HOST_DATA_STATE_INQUIRY:
        {
            USB_DEBUG(("    --- Enter Inquiry ---\n"));
            /* cancel connecting timer */
            MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);  
            /* move to inquiry state */    
            states_set_state(SOURCE_STATE_INQUIRING);
            /* indicate this is a forced inquiry, and must remain in this state until a successful connection */
            theSource->inquiry_mode.force_inquiry_mode = TRUE;
        }
        break;
        
        case USB_HOST_DATA_STATE_INQUIRY_SCAN:
        {
            USB_DEBUG(("    --- Enter Inquiry Scan ---\n"));
            /* cancel connecting timer */
            MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);  
            /* move to discoverable state */    
            states_set_state(SOURCE_STATE_DISCOVERABLE);     
        }
        break;
        
        case USB_HOST_DATA_STATE_PAGE:
        {
            USB_DEBUG(("    --- Enter Page ---\n"));        
            if (states_get_state() == SOURCE_STATE_CONNECTED)
            {
                MessageSend(&theSource->app_data.appTask, APP_DISCONNECT_REQ, 0);
            }
            else if (states_get_state() != SOURCE_STATE_CONNECTING)
            {            
                theSource->inquiry_mode.force_inquiry_mode = FALSE;
                /* initialise the connection with the connection manager */
                connection_mgr_start_connection_attempt(&theSource->ps_config->bdaddr_remote_device, AGHFP_PROFILE_IS_ENABLED ? PROFILE_AGHFP : PROFILE_A2DP, 0);
            }
            /* set appropriate timers as it is being forced to stay in page state */
            states_no_timers();
        }
        break;
        
        case USB_HOST_DATA_STATE_PAGE_SCAN:
        {
            USB_DEBUG(("    --- Enter Page Scan ---\n"));  
            MessageCancelAll(&theSource->app_data.appTask, APP_CONNECT_REQ);
            states_set_state(SOURCE_STATE_CONNECTABLE); 
        }
        break;
        
        default:
        {
            usb_unhandled_host_command(USB_HOST_COMMAND_STATE, data);
        }
        break;
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_call - Handles the Host command for current call state
*/
static void usb_process_host_command_call(uint8 call_state, uint16 size_data, const uint8 *data)
{
    switch (call_state)
    {
       case USB_HOST_DATA_AG_CALL_STATE_NONE:
        {
            USB_DEBUG(("    --- No Call ---\n"));
            aghfp_call_ind_none();
        }
        break;
        
       case USB_HOST_DATA_AG_CALL_STATE_INCOMING:
        {
            USB_DEBUG(("    --- Incoming Call ---\n"));
            aghfp_call_ind_incoming(size_data, data);
        }
        break;
        
        case USB_HOST_DATA_AG_CALL_STATE_OUTGOING:
        {
            USB_DEBUG(("    --- Outgoing Call ---\n"));
            aghfp_call_ind_outgoing();
        }
        break;
        
        case USB_HOST_DATA_AG_CALL_STATE_ACTIVE:
        {
            USB_DEBUG(("    --- Active Call ---\n"));
            aghfp_call_ind_active();
        }
        break;
        
        case USB_HOST_DATA_AG_CALL_STATE_CALL_WAITING_ACTIVE_CALL:
        {
            USB_DEBUG(("    --- Call Waiting Active Call ---\n"));
            aghfp_call_ind_waiting_active_call(size_data, data);
        }
        break;
        
        case USB_HOST_DATA_AG_CALL_STATE_CALL_HELD_ACTIVE_CALL:
        {
            USB_DEBUG(("    --- Call Held Active Call ---\n"));
            aghfp_call_ind_held_active_call();
        }
        break;
        
        case USB_HOST_DATA_AG_CALL_STATE_CALL_HELD:
        {
            USB_DEBUG(("    --- Call Held ---\n"));
            aghfp_call_ind_held();
        }
        break;
        
        default:
        {
            usb_unhandled_host_command(USB_HOST_COMMAND_AG_CALL_STATE, call_state);
        }
        break;
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_signal_strength - Handles the Host command for signal strength
*/
static void usb_process_host_command_signal_strength(uint8 sub_cmd, uint16 size_data, const uint8 *data)
{
    if (sub_cmd == USB_HOST_DATA_AG_SIGNAL_STRENGTH_VALUE)
    {
        if (size_data >= 1)
        {
            USB_DEBUG(("    --- Signal Strength ---\n"));
            aghfp_signal_strength_ind(data[0]);
        }
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_battery_level - Handles the Host command for battery level
*/
static void usb_process_host_command_battery_level(uint8 sub_cmd, uint16 size_data, const uint8 *data)
{
    if (sub_cmd == USB_HOST_DATA_AG_BATTERY_LEVEL_VALUE)
    {
        if (size_data >= 1)
        {
            USB_DEBUG(("    --- Battery Level ---\n"));
            aghfp_battery_level_ind(data[0]);
        }
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_audio - Handles the Host command for audio
*/
static void usb_process_host_command_audio(uint8 data)
{
    switch (data)
    {
        case USB_HOST_DATA_AG_AUDIO_GET_STATE:
        {
            USB_DEBUG(("    --- Get Audio State ---\n"));  
            if (aghfp_is_audio_active())
                usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_CONNECTED);
            else if (aghfp_get_number_connections())
                usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_AUDIO_DISCONNECTED);
            else
                usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_NO_SLC_CONNECTION);
        }
        break;
        
        case USB_HOST_DATA_AG_AUDIO_TRANSFER:
        {
            USB_DEBUG(("    --- Transfer Audio ---\n"));  
            aghfp_audio_transfer_req();
        }
        break;
        
        default:
        {
            usb_unhandled_host_command(USB_HOST_COMMAND_AG_AUDIO, data);
        }
        break;
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_network - Handles the Host command for network state
*/
static void usb_process_host_command_network(uint8 command, uint16 size_data, const uint8 *data)
{
    switch (command)
    {
        case USB_HOST_DATA_AG_NETWORK_OPERATOR:
        {
            USB_DEBUG(("    --- Network Operator Name ---\n"));
            aghfp_network_operator_ind(size_data, data);
        }
        break;
        
        case USB_HOST_DATA_AG_NETWORK_AVAILABILITY:
        {
            if (size_data >= 1)
            {
                USB_DEBUG(("    --- Network Operator Availability ---\n"));
                aghfp_network_availability_ind(data[0]);
            }
        }
        break;
        
        case USB_HOST_DATA_AG_NETWORK_ROAM:
        {
            if (size_data >= 1)
            {
                USB_DEBUG(("    --- Network Operator Roam ---\n"));
                aghfp_network_roam_ind(data[0]);
            }
        }
        break;
        
        default:
        {
            usb_unhandled_host_command(USB_HOST_COMMAND_AG_NETWORK, command);
        }
        break;
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_ag_error - Handles the Host command for AG error status
*/
static void usb_process_host_command_ag_error(uint8 command)
{
    switch (command)
    {
        case USB_HOST_DATA_AG_ERROR_INVALID_MEMORY_LOCATION:
        {
            USB_DEBUG(("    --- AG Error Invalid Memory Location ---\n"));
            aghfp_error_ind();
        }
        break;
        
        case USB_HOST_DATA_AG_ERROR_INVALID_LAST_NUMBER_DIAL:
        {
            USB_DEBUG(("    --- AG Error Invalid Last Number Dial ---\n"));
            aghfp_error_ind();
        }
        break;
        
        default:
        {
            usb_unhandled_host_command(USB_HOST_COMMAND_AG_ERROR, command);
        }
        break;
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_ag_ok - Handles the Host command for AG ok status
*/
static void usb_process_host_command_ag_ok(uint8 command)
{
    switch (command)
    {            
        case USB_HOST_DATA_AG_OK_VALID_MEMORY_LOCATION:
        {
            USB_DEBUG(("    --- AG OK Valid Memory Location ---\n"));
            aghfp_ok_ind();
        }
        break;
        
        case USB_HOST_DATA_AG_OK_VALID_LAST_NUMBER_DIAL:
        {
            USB_DEBUG(("    --- AG OK Valid Last Number Dial ---\n"));
            aghfp_ok_ind();
        }
        break;
        
        case USB_HOST_DATA_AG_OK_SENT_ALL_CURRENT_CALLS:
        {
            USB_DEBUG(("    --- AG OK Sent All Current Calls ---\n"));
            aghfp_ok_ind();
        }
        break;
        
        default:
        {
            usb_unhandled_host_command(USB_HOST_COMMAND_AG_OK, command);
        }
        break;
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_current_call - Handles the Host command for current call status
*/
static void usb_process_host_command_current_call(uint8 sub_cmd, uint16 size_data, const uint8 *data)
{
    if (sub_cmd == USB_HOST_DATA_AG_CURRENT_CALL_DETAILS)
    {
        USB_DEBUG(("    --- AG Current Call ---\n"));
        aghfp_current_call_ind(size_data, data);
    }
}


/****************************************************************************
NAME    
    usb_process_host_command_ag_voice - Handles the Host command for voice recognition
*/
static void usb_process_host_command_ag_voice(uint8 command)
{
    USB_DEBUG(("    --- Voice Recognition ---\n"));
    aghfp_voice_recognition_ind(command ? TRUE : FALSE);
}


/****************************************************************************
NAME    
    usb_process_vendor_report - Handle host report
*/
static void usb_process_vendor_report(const uint16 size_data, const uint8 *data)
{
    if (size_data >= 2) /* expect SET_REPORT to have 2 bytes - first byte is report ID, second byte is command type */
    {        
        USB_DEBUG(("USB: Process SET_REPORT (Report ID = %d) command=[0x%x]\n", data[0], data[1]));
        
        /* Expected Report (ID=2) received from Host is to be the expected format:
           
           Byte 0 - Report ID
           
           Byte 1 - Host Command           
           
           Bytes 2-17 - Command Data
          
        */
        
        switch (data[1])
        {
            case USB_HOST_COMMAND_HOST_CONNECTION:
            {
                usb_process_host_command_connection(data[2]);
            }
            break;
            
            case USB_HOST_COMMAND_STATE:
            {        
                usb_process_host_command_status(data[2]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_CALL_STATE:
            {        
                usb_process_host_command_call(data[2], size_data - 3, &data[3]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_SIGNAL_STRENGTH:
            {            
                usb_process_host_command_signal_strength(data[2], size_data - 3, &data[3]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_BATTERY_LEVEL:
            {
                usb_process_host_command_battery_level(data[2], size_data - 3, &data[3]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_AUDIO:
            {
                usb_process_host_command_audio(data[2]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_NETWORK:
            {
                usb_process_host_command_network(data[2], size_data - 3, &data[3]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_ERROR:
            {
                usb_process_host_command_ag_error(data[2]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_OK:
            {
                usb_process_host_command_ag_ok(data[2]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_CURRENT_CALL:
            {
                usb_process_host_command_current_call(data[2], size_data - 3, &data[3]);
            }
            break;
            
            case USB_HOST_COMMAND_AG_VOICE_RECOGNITION:
            {
                usb_process_host_command_ag_voice(data[2]);
            }
            break;
            
            default:
            {
                USB_DEBUG(("USB: Host Command not recognised %d\n", data[1])); 
            }
            break;
        }
    }
}


/****************************************************************************
NAME    
    usb_time_critical_init - Enumerate as a USB device before the main application starts up
*/
void usb_time_critical_init(void)
{
    uint16 device_class = 0;
    usb_device_class_status status = usb_device_class_status_invalid_param_value;
    
    /* must retrieve USB configuration from PS now */
    ps_get_time_critical_data();
            
    USB_DEBUG(("USB usb_time_critical_init\n"));
    
    /* check which USB Device Classes have been enabled */
    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
    {
        device_class |= USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL;
          
        /* configure HID consumer transport */
        status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_HID_CONSUMER_TRANSPORT_DESCRIPTORS, 0, 0, (const uint8*)&usb_descriptor_hid_consumer_transport); 
        
        if(status != usb_device_class_status_success)
        {
            USB_DEBUG(("USB HID Config Descriptor Error %d\n", status));       
            return;
        }              
    }
    if (theSource->ps_config->usb_config.usb_hid_keyboard_interface)
    {
        device_class |= USB_DEVICE_CLASS_TYPE_HID_KEYBOARD;
    }
    if (theSource->ps_config->usb_config.usb_mic_interface)
    {
        device_class |= USB_DEVICE_CLASS_TYPE_AUDIO_MICROPHONE;
    }
    if (theSource->ps_config->usb_config.usb_speaker_interface)
    {
        device_class |= USB_DEVICE_CLASS_TYPE_AUDIO_SPEAKER;
    }
    
    USB_DEBUG(("    device class [0x%x]\n", device_class));
        
    if (theSource->ps_config->usb_config.usb_mic_interface || theSource->ps_config->usb_config.usb_speaker_interface)
    {
        /* configure Audio to include Vendor specific functionality */
        
        if (theSource->ps_config->usb_config.usb_mic_interface && theSource->ps_config->usb_config.usb_speaker_interface)
        {
            status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_AUDIO_INTERFACE_DESCRIPTORS, 0, 0, (const uint8*)&usb_descriptor_audio);
        }
        else if (theSource->ps_config->usb_config.usb_mic_interface)
        {
            status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_AUDIO_INTERFACE_DESCRIPTORS, 0, 0, (const uint8*)&usb_descriptor_mic);
        }
        else if (theSource->ps_config->usb_config.usb_speaker_interface)
        {
            status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_AUDIO_INTERFACE_DESCRIPTORS, 0, 0, (const uint8*)&usb_descriptor_speaker);
        }
    
        if(status != usb_device_class_status_success)
        {
            USB_DEBUG(("USB Audio Descriptor Config Error %d\n", status));
            return;
        } 
       
        /* configure Audio to set volume levels */
        status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_AUDIO_VOLUMES, 0, 0, (const uint8*)&usb_audio_levels); 
    
        if(status != usb_device_class_status_success)
        {
            USB_DEBUG(("USB Audio Volume Config Error %d\n", status));
            return;
        } 
       
    }
    
    if (device_class)
    {
        /* Attempt to enumerate - abort if failed */
        status = UsbDeviceClassEnumerate(&theSource->usbTask, device_class);

        if(status != usb_device_class_status_success)
        {
            USB_DEBUG(("USB Enumerate Error %d\n", status));
            return;
        }
    }
}


/****************************************************************************
NAME    
    usb_get_speaker_source - Get speaker Source
*/
Source usb_get_speaker_source(void)
{
    Source speaker_src = NULL;
    
    if (theSource->ps_config->usb_config.usb_speaker_interface)
    {    
        /* Speaker will be the USB Source data */
        UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_SOURCE, (uint16*)(&speaker_src));
    }
    
    return speaker_src;
}


/****************************************************************************
NAME    
    usb_get_mic_sink - Get mic Sink
*/
Sink usb_get_mic_sink(void)
{
    Sink mic_sink = NULL;
    
    if (theSource->ps_config->usb_config.usb_mic_interface)
    {
        /* Mic will be the USB Sink data */
        UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_SINK, (uint16*)(&mic_sink));
    }
    
    return mic_sink;
}


/****************************************************************************
NAME    
    usb_get_audio_levels_update_headset - Get USB audio levels which could be echoed to the remote device
*/
void usb_get_audio_levels_update_headset(bool only_if_volumes_changed)
{    
    usb_device_class_audio_levels levels;
    
    if (theSource->ps_config->usb_config.usb_speaker_interface || theSource->ps_config->usb_config.usb_mic_interface)
    {
        /* get the current USB audio levels */ 
        UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_LEVELS, (uint16*)&levels);
    
        /* convert raw USB audio levels to local volume settings */
        levels.out_l_vol = usb_vol_speaker_rounded(levels.out_l_vol);
        levels.out_r_vol = usb_vol_speaker_rounded(levels.out_r_vol);
        levels.in_vol = usb_vol_mic_rounded(levels.in_vol);

        USB_DEBUG(("USB Gain L [%X] R [%X] MIC [%X]\n", levels.out_l_vol, levels.out_r_vol, levels.in_vol));
        USB_DEBUG(("USB Mute M [%X] S [%X]\n", levels.in_mute, levels.out_mute));
        
        volume_usb_levels_changed_ind(levels.in_vol, levels.out_l_vol, levels.in_mute, levels.out_mute);    
    }
}


/****************************************************************************
NAME    
    usb_send_media_hid_command - Get USB media command to host
*/
void usb_send_media_hid_command(avc_operation_id op_id, bool state)
{
    USB_DEBUG(("USB Set Media HID cmd[%d] state[%d]\n", op_id, state));
    
    if ((op_id != opid_fast_forward) && theSource->usb_data.ffwd_press)
    {
        /* send a FFWD release event if another media command is activated without sending a release */
        MessageCancelAll(&theSource->app_data.appTask, APP_USB_FFWD_RELEASE);
        usb_fast_forward_release();
    }
    if ((op_id != opid_rewind) && theSource->usb_data.rew_press)
    {
        /* send a REW release event if another media command is activated without sending a release */
        MessageCancelAll(&theSource->app_data.appTask, APP_USB_REW_RELEASE);
        usb_rewind_release();
    }
    
    switch (op_id)
    {
        case opid_play:
        {
            if (!state)
            {
                /* play press */
                {
                    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                    {
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PLAY_PAUSE);
                    }
                }
            }
            else
            {
                /* play release */
            }
        }
        break;
        
        case opid_stop:
        {
            if (!state)
            {
                /* stop press */
                {
                    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                    {
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_STOP);
                    }
                }
            }
            else
            {
                /* stop release */
            }
        }
        break;
        
        case opid_pause:
        {
            if (!state)
            {
                /* play press */
                {
                    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                    {
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PLAY_PAUSE);
                    }
                }
            }
            else
            {
                /* play release */
            }
        }
        break;
        
        case opid_rewind:
        {
            if (!state)
            {
                if (!theSource->usb_data.rew_press)
                {                    
                    /* send REW event on first press */
                    theSource->usb_data.rew_press = TRUE;
                    {
                        if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                        {
                            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_REW_ON);
                            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_REW_OFF);
                        }
                    }
                }
                /* send release event after timeout if no further press commands received */
                MessageCancelAll(&theSource->app_data.appTask, APP_USB_REW_RELEASE);
                MessageSendLater(&theSource->app_data.appTask, APP_USB_REW_RELEASE, 0, theSource->ps_config->ps_timers.media_repeat_timer);
            }
        }
        break;
        
        case opid_fast_forward:
        {
            if (!state)
            {
                if (!theSource->usb_data.ffwd_press)
                {                  
                    /* send FFWD event on first press */
                    theSource->usb_data.ffwd_press = TRUE;
                    {
                        if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                        {
                            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_FFWD_ON);
                            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_FFWD_OFF);
                        }
                    }
                }
                /* send release event after timeout if no further press commands received */               
                MessageCancelAll(&theSource->app_data.appTask, APP_USB_FFWD_RELEASE);
                MessageSendLater(&theSource->app_data.appTask, APP_USB_FFWD_RELEASE, 0, theSource->ps_config->ps_timers.media_repeat_timer);               
            }
        }
        break;
        
        case opid_forward:
        {
            if (!state)
            {
                /* skip forward press */
                {
                    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                    {
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_NEXT_TRACK);
                    }
                }
            }
            else
            {
                /* forward release */
            }
        }
        break;
        
        case opid_backward:
        {
            if (!state)
            {
                /* skip backward press */
                {
                    if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                    {
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PREVIOUS_TRACK);
                    }
                }
            }
            else
            {
                /* backward release */
            }    
        }
        break;
        
        case opid_volume_up:
        {            
            if (!state)
            {
                usb_device_class_audio_levels levels;
    
                if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                {
                    /* get the current USB audio levels */ 
                    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_LEVELS, (uint16*)&levels);
                
                    if (levels.out_mute)
                    {
                        /* send mute over USB */
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_MUTE);
                    }
                    else
                    {
                        /* send volume up over USB */
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_UP);
                    }
                }
            }
        }
        break;
        
        case opid_volume_down:
        {
            if (!state)
            {
                usb_device_class_audio_levels levels;
                
                if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
                {    
                    /* get the current USB audio levels */ 
                    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_LEVELS, (uint16*)&levels);
                
                    if (levels.out_mute)
                    {
                        /* send mute over USB */
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_MUTE);
                    }
                    else
                    {
                        /* send volume down over USB */
                        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_DOWN);
                    }
                }
            }
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
    usb_get_hid_mode - Get USB HID mode
*/
USB_HID_MODE_T usb_get_hid_mode(void)
{
    return theSource->usb_data.hid_mode;
}


/****************************************************************************
NAME    
    usb_set_hid_mode - Set USB HID mode
*/
void usb_set_hid_mode(USB_HID_MODE_T mode)
{
    theSource->usb_data.hid_mode = mode;
    USB_DEBUG(("USB Set Mode [%d]\n", mode));
    if (usb_get_hid_mode() == USB_HID_MODE_CONSUMER)
    {
        /* restore timers read from PS */
        ps_restore_timers();
        /* no longer forcing inquiry mode */
        theSource->inquiry_mode.force_inquiry_mode = FALSE;
    }
}


/****************************************************************************
NAME    
    usb_send_vendor_state - Sends application state to host after a state change
*/
void usb_send_vendor_state(void)
{
    if (usb_get_hid_mode() == USB_HID_MODE_HOST)
    {
        usb_send_device_command_status();
    }
}


/****************************************************************************
NAME    
    usb_handle_report - Handles USB_DEVICE_CLASS_MSG_REPORT_IND message 
*/
void usb_handle_report(const USB_DEVICE_CLASS_MSG_REPORT_IND_T *msg)
{
    if (msg->class_type == USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL)
    {
        if ((msg->report_id & 0xf )== USB_CONSUMER_REPORT_ID)
        {
            /* this is a Vendor SET_REPORT received from the Host */
            usb_process_vendor_report(msg->size_report, msg->report);
        }        
    }
}


/****************************************************************************
NAME    
    usb_rewind_release - Send Rewind released to host
*/
void usb_rewind_release(void)
{
    theSource->usb_data.rew_press = FALSE;
    {
        if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
        {
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_REW_ON);
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_REW_OFF);
        }
    }
}


/****************************************************************************
NAME    
    usb_fast_forward_release - Send Fast Forward released to host
*/
void usb_fast_forward_release(void)
{
    theSource->usb_data.ffwd_press = FALSE;
    {
        if (theSource->ps_config->usb_config.usb_hid_consumer_interface)
        {            
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_FFWD_ON);
            UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_FFWD_OFF);
        }
    }
}


/****************************************************************************
NAME    
    usb_send_hid_answer - Sends a HID command to answer a call
*/
void usb_send_hid_answer(void)
{
    if (theSource->ps_config->usb_config.usb_hid_keyboard_interface)
    {
        /* send ALT+PGUP over USB */
        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_KEYBOARD_ALT_PGUP);
    }
}


/****************************************************************************
NAME    
    usb_send_hid_hangup - Sends a HID command to hang up a call
*/
void usb_send_hid_hangup(void)
{
    if (theSource->ps_config->usb_config.usb_hid_keyboard_interface)
    {
        /* send ALT+PGDN over USB */
        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_KEYBOARD_ALT_PGDN);
        /* send ALT+End over USB */
        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_KEYBOARD_ALT_END);
    }
}


/****************************************************************************
NAME    
    usb_send_device_command_accept_call - Send accept call event to host
*/
bool usb_send_device_command_accept_call(void)
{
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_AG_CALL;
    report_bytes[1] = USB_DEVICE_COMMAND_AG_CALL_ACCEPT;
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_reject_call - Send reject call event to host
*/
bool usb_send_device_command_reject_call(void)
{
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_AG_CALL;
    report_bytes[1] = USB_DEVICE_COMMAND_AG_CALL_REJECT;
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_dial_number - Send number to dial to the Host
*/
bool usb_send_device_command_dial_number(uint16 size_number, uint8 *number)
{
    uint16 index;
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    if (size_number > (USB_CONSUMER_REPORT_SIZE - 3))
    {
        size_number = USB_CONSUMER_REPORT_SIZE - 3;
    }    
    report_bytes[0] = USB_DEVICE_COMMAND_AG_CALL;
    report_bytes[1] = USB_DEVICE_COMMAND_AG_CALL_NUMBER_SUPPLIED; /* command */
    report_bytes[2] = size_number; /* size byte */
    for (index = 0; index < size_number; index ++)
    {
        report_bytes[index + 3] = number[index]; /* number to dial */
    }
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_dial_memory - Send memory location to dial to the Host
*/
bool usb_send_device_command_dial_memory(uint16 size_number, uint8 *number)
{
    uint16 index;
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    if (size_number > (USB_CONSUMER_REPORT_SIZE - 3))
    {
        size_number = USB_CONSUMER_REPORT_SIZE - 3;
    }    
    report_bytes[0] = USB_DEVICE_COMMAND_AG_CALL;
    report_bytes[1] = USB_DEVICE_COMMAND_AG_CALL_MEMORY; /* command */
    report_bytes[2] = size_number; /* size byte */
    for (index = 0; index < size_number; index ++)
    {
        report_bytes[index + 3] = number[index]; /* memory location to dial */
    }
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_dial_last - Send last number dial to the Host
    
*/
bool usb_send_device_command_dial_last(void)
{
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_AG_CALL;
    report_bytes[1] = USB_DEVICE_COMMAND_AG_CALL_LAST_NUMBER;
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_audio_state - Sends the audio connection state to the Host
    
*/
bool usb_send_device_command_audio_state(USB_DEVICE_DATA_AG_AUDIO_STATE_T state)
{
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_AG_AUDIO_STATE;
    report_bytes[1] = state;
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_current_calls - Sends the command the get the current call list to the Host
*/
bool usb_send_device_command_current_calls(void)
{
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_AG_CALL;
    report_bytes[1] = USB_DEVICE_COMMAND_AG_CALL_GET_CURRENT_CALLS;    
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_send_device_command_voice_recognition - Sends the voice recognition state to the Host
    
*/
bool usb_send_device_command_voice_recognition(bool enable)
{
    uint8 report_bytes[USB_CONSUMER_REPORT_SIZE];
    
    if (usb_get_hid_mode() != USB_HID_MODE_HOST)
    {
        /* only send USB message to Host if it is connected */
        return FALSE;
    }
    
    /* clear report data */
    usb_clear_report_data(report_bytes, USB_CONSUMER_REPORT_SIZE);
    
    /* Expected Report (ID=2) sent to Host is to be the expected format:
           
           Byte 0 - Report ID
         
           Byte 1 - Device Command
           
           Byte 2 - Device Sub-Command
           
           Bytes 3-17 - Command Data
           
    */
    
    /* initialise report */
    report_bytes[0] = USB_DEVICE_COMMAND_AG_VOICE_RECOGNITION;
    report_bytes[1] = enable ? USB_DEVICE_DATA_AG_VOICE_RECOGNITION_ENABLE : USB_DEVICE_DATA_AG_VOICE_RECOGNITION_DISABLE;
    
    USB_DEBUG(("USB: Send Vendor Report (Report ID = %d) data_0 = [0x%x] data_1 = [0x%x]\n", USB_CONSUMER_REPORT_ID, report_bytes[0], report_bytes[1]));
        
    /* send USB Report */        
    if (UsbDeviceClassSendReport(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, USB_CONSUMER_REPORT_ID, USB_CONSUMER_REPORT_SIZE, report_bytes) == usb_device_class_status_success)
        return TRUE;
    
    return FALSE;
}


/****************************************************************************
NAME    
    usb_get_speaker_sample_rate - Gets the configured USB sample rate for the speaker
*/    
uint32 usb_get_speaker_sample_rate(void)
{
#ifdef USB_AUDIO_SAMPLE_RATE_SPEAKER
    return USB_AUDIO_SAMPLE_RATE_SPEAKER;
#endif
    
    return 0;
}
