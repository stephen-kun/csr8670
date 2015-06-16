/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_usb_descriptors.h
    
DESCRIPTION
    
*/
#ifndef _SINK_USB_DESCRIPTORS_H_
#define _SINK_USB_DESCRIPTORS_H_

#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)

#define SAMPLE_RATE_CVC    ((uint32) 8000)
#define SAMPLE_RATE_CVC_WB ((uint32) 16000)
#define SAMPLE_RATE_STEREO ((uint32) 48000)

/* Unit/Terminal IDs */
#define SPEAKER_IT  0x01
#define SPEAKER_FU  0x02
#define SPEAKER_OT  0x03
#define MIC_IT      0x04
#define MIC_FU      0x05
#define MIC_OT      0x06

/* Interface Descriptors for mono 8kHz. Do Not Modify. */
static const uint8 interface_descriptor_control_mic_and_speaker[] =
{
    /* Class Specific Header */
    0x0A,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = HEADER */
    0x00, 0x01,   /* bcdADC = Audio Device Class v1.00 */
    0x0A + 0x0c + 0x0b + 0x09 + 0x0c + 0x0b + 0x09, /* wTotalLength LSB */
    0x00,         /* wTotalLength MSB */
    0x02,         /* bInCollection = 2 AudioStreaming interfaces */
    0x01,         /* baInterfaceNr(1) - AS#1 id */
    0x02,         /* baInterfaceNr(2) - AS#2 id */

    /* Microphone IT */
    0x0c,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = INPUT_TERMINAL */
    MIC_IT,       /* bTerminalID */
    0x03, 0x02,   /* wTerminalType = Personal Microphone */
    0x00,         /* bAssocTerminal = none */
    0x01,         /* bNrChannels = 1 */
    0x00, 0x00,   /* wChannelConfig = mono */
    0x00,         /* iChannelName = no string */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Microphone Features */
    0x0b,           /*bLength*/
    0x24,           /*bDescriptorType = CS_INTERFACE */
    0x06,           /*bDescriptorSubType = FEATURE_UNIT*/
    MIC_FU,         /*bUnitId*/
    MIC_IT,         /*bSourceId - Microphone IT*/
    0x02,           /*bControlSize = 2 bytes per control*/
    0x01, 0x00,     /*bmaControls[0] = 0001 (Mute on Master Channel)*/
    0x00, 0x00,     /*bmaControls[1] = 0000 (No gain control)*/
    0x00,           /*iFeature = same as USB product string*/

    /* Microphone OT */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x03,         /* bDescriptorSubType = OUTPUT_TERMINAL */
    MIC_OT,       /* bTerminalID */
    0x01, 0x01,   /* wTerminalType = USB streaming */
    0x00,         /* bAssocTerminal = none */
    MIC_FU,       /* bSourceID - Microphone Features */
    0x00,         /* iTerminal = same as USB product string */

    /* Speaker IT */
    0x0c,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = INPUT_TERMINAL */
    SPEAKER_IT,   /* bTerminalID */
    0x01, 0x01,   /* wTerminalType = USB streaming */
    0x00,         /* bAssocTerminal = none */
    0x01,         /* bNrChannels = 1 */
    0x00, 0x00,   /* wChannelConfig = mono */
    0x00,         /* iChannelName = no string */
    0x00,         /* iTerminal = same as USB product string */
    
    /* Speaker Features */
    0x0b,           /*bLength*/
    0x24,           /*bDescriptorType = CS_INTERFACE */
    0x06,           /*bDescriptorSubType = FEATURE_UNIT*/
    SPEAKER_FU,     /*bUnitId*/
    SPEAKER_IT,     /*bSourceId - Speaker IT*/
    0x02,           /*bControlSize = 2 bytes per control*/
    0x01, 0x00,     /*bmaControls[0] = 0001 (Mute on Master Channel)*/
    0x02, 0x00,     /*bmaControls[1] = 0002 (Vol on Left Front)*/
    0x00,           /*iFeature = same as USB product string*/

    /* Speaker OT */
    0x09,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x03,         /* bDescriptorSubType = OUTPUT_TERMINAL */
    SPEAKER_OT,   /* bTerminalID */
    0x01, 0x03,   /* wTerminalType = Speaker */
    0x00,         /* bAssocTerminal = none */
    SPEAKER_FU,   /* bSourceID - Speaker Features*/
    0x00,         /* iTerminal = same as USB product string */
};

static const uint8 interface_descriptor_streaming_mic[] =
{
    /* Class Specific AS interface descriptor */
    0x07,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    MIC_OT,       /* bTerminalLink = Microphone OT */
    0x00,         /* bDelay */
    0x01, 0x00,   /* wFormatTag = PCM */

    /* Type 1 format type descriptor */
    0x08 + 0x03,  /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = FORMAT_TYPE */
    0x01,         /* bFormatType = FORMAT_TYPE_I */
    0x01,         /* bNumberOfChannels */
    0x02,         /* bSubframeSize = 2 bytes */
    0x10,         /* bBitsResolution */
    0x01,         /* bSampleFreqType = 1 discrete sampling freq */
    0xFF & (SAMPLE_RATE_CVC),       /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC >> 8),  /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC >> 16), /* tSampleFreq */

    /* Class specific AS isochronous audio data endpoint descriptor */
    0x07,         /* bLength */
    0x25,         /* bDescriptorType = CS_ENDPOINT */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    0x00,         /* bmAttributes = none */
    0x02,         /* bLockDelayUnits = Decoded PCM samples */
    0x00, 0x00     /* wLockDelay */
};

static const uint8 interface_descriptor_streaming_speaker[] =
{
    /* Class Specific AS interface descriptor */
    0x07,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    SPEAKER_IT,   /* bTerminalLink = Speaker IT */
    0x00,         /* bDelay */
    0x01, 0x00,   /* wFormatTag = PCM */

    /* Type 1 format type descriptor */
    0x08 + 0x03,/* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = FORMAT_TYPE */
    0x01,         /* bFormatType = FORMAT_TYPE_I */
    0x01,         /* bNumberOfChannels */
    0x02,         /* bSubframeSize = 2 bytes */
    0x10,         /* bBitsResolution */
    0x01,         /* bSampleFreqType = 1 discrete sampling freq */
    0xFF & (SAMPLE_RATE_CVC),       /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC >> 8),  /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC >> 16), /* tSampleFreq */

    /* Class specific AS isochronous audio data endpoint descriptor */
    0x07,         /* bLength */
    0x25,         /* bDescriptorType = CS_ENDPOINT */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    0x81,         /* bmAttributes = MaxPacketsOnly and SamplingFrequency control */
    0x02,         /* bLockDelayUnits = Decoded PCM samples */
    0x00, 0x00    /* wLockDelay */
};

static const uint8 audio_endpoint_user_data[] =
{
    0, /* bRefresh */
    0  /* bSyncAddress */
};


/*  Streaming Isochronous Endpoint. Maximum packet size 16 (mono at 8khz) */
static const EndPointInfo epinfo_streaming_speaker[] =
{
    {
        end_point_iso_in, /* address */
        end_point_attr_iso, /* attributes */
        16, /* max packet size */
        1, /* poll_interval */
        audio_endpoint_user_data, /* data to be appended */
        sizeof(audio_endpoint_user_data) /* length of data appended */      
    }
};


/* Streaming Isochronous Endpoint. Maximum packet size 16 (mono at 8khz) */
static const EndPointInfo epinfo_streaming_mic[] =
{
    {
        end_point_iso_out, /* address */
        end_point_attr_iso, /* attributes */
        16, /* max packet size */
        1, /* poll_interval */
        audio_endpoint_user_data, /* data to be appended */
        sizeof(audio_endpoint_user_data), /* length of data appended */
    }
};

static const usb_device_class_audio_config usb_cvc_config =
{
    {interface_descriptor_control_mic_and_speaker,
    sizeof(interface_descriptor_control_mic_and_speaker),
    NULL},
    {interface_descriptor_streaming_mic,
    sizeof(interface_descriptor_streaming_mic),
    epinfo_streaming_mic},
    {interface_descriptor_streaming_speaker,
    sizeof(interface_descriptor_streaming_speaker),
    epinfo_streaming_speaker}
};

static const uint8 interface_descriptor_streaming_mic_wb[] =
{
    /* Class Specific AS interface descriptor */
    0x07,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    MIC_OT,       /* bTerminalLink = Microphone OT */
    0x00,         /* bDelay */
    0x01, 0x00,   /* wFormatTag = PCM */

    /* Type 1 format type descriptor */
    0x08 + 0x03,  /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = FORMAT_TYPE */
    0x01,         /* bFormatType = FORMAT_TYPE_I */
    0x01,         /* bNumberOfChannels */
    0x02,         /* bSubframeSize = 2 bytes */
    0x10,         /* bBitsResolution */
    0x01,         /* bSampleFreqType = 1 discrete sampling freq */
    0xFF & (SAMPLE_RATE_CVC_WB),       /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC_WB >> 8),  /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC_WB >> 16), /* tSampleFreq */

    /* Class specific AS isochronous audio data endpoint descriptor */
    0x07,         /* bLength */
    0x25,         /* bDescriptorType = CS_ENDPOINT */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    0x00,         /* bmAttributes = none */
    0x02,         /* bLockDelayUnits = Decoded PCM samples */
    0x00, 0x00     /* wLockDelay */
};

static const uint8 interface_descriptor_streaming_speaker_wb[] =
{
    /* Class Specific AS interface descriptor */
    0x07,         /* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    SPEAKER_IT,   /* bTerminalLink = Speaker IT */
    0x00,         /* bDelay */
    0x01, 0x00,   /* wFormatTag = PCM */

    /* Type 1 format type descriptor */
    0x08 + 0x03,/* bLength */
    0x24,         /* bDescriptorType = CS_INTERFACE */
    0x02,         /* bDescriptorSubType = FORMAT_TYPE */
    0x01,         /* bFormatType = FORMAT_TYPE_I */
    0x01,         /* bNumberOfChannels */
    0x02,         /* bSubframeSize = 2 bytes */
    0x10,         /* bBitsResolution */
    0x01,         /* bSampleFreqType = 1 discrete sampling freq */
    0xFF & (SAMPLE_RATE_CVC_WB),       /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC_WB >> 8),  /* tSampleFreq */
    0xFF & (SAMPLE_RATE_CVC_WB >> 16), /* tSampleFreq */

    /* Class specific AS isochronous audio data endpoint descriptor */
    0x07,         /* bLength */
    0x25,         /* bDescriptorType = CS_ENDPOINT */
    0x01,         /* bDescriptorSubType = AS_GENERAL */
    0x81,         /* bmAttributes = MaxPacketsOnly and SamplingFrequency control */
    0x02,         /* bLockDelayUnits = Decoded PCM samples */
    0x00, 0x00    /* wLockDelay */
};

/*  Streaming Isochronous Endpoint. Maximum packet size 16 (mono at 8khz) */
static const EndPointInfo epinfo_streaming_speaker_wb[] =
{
    {
        end_point_iso_in, /* address */
        end_point_attr_iso, /* attributes */
        32, /* max packet size */
        1, /* poll_interval */
        audio_endpoint_user_data, /* data to be appended */
        sizeof(audio_endpoint_user_data) /* length of data appended */      
    }
};


/* Streaming Isochronous Endpoint. Maximum packet size 16 (mono at 8khz) */
static const EndPointInfo epinfo_streaming_mic_wb[] =
{
    {
        end_point_iso_out, /* address */
        end_point_attr_iso, /* attributes */
        32, /* max packet size */
        1, /* poll_interval */
        audio_endpoint_user_data, /* data to be appended */
        sizeof(audio_endpoint_user_data), /* length of data appended */
    }
};

static const usb_device_class_audio_config usb_cvc_wb_config =
{
    {interface_descriptor_control_mic_and_speaker,
    sizeof(interface_descriptor_control_mic_and_speaker),
    NULL},
    {interface_descriptor_streaming_mic_wb,
    sizeof(interface_descriptor_streaming_mic_wb),
    epinfo_streaming_mic_wb},
    {interface_descriptor_streaming_speaker_wb,
    sizeof(interface_descriptor_streaming_speaker_wb),
    epinfo_streaming_speaker_wb}
};

/* audio volume configuration */
#define MIC_MAX 0x0000 /* +00.00 */
#define MIC_MIN 0xD200 /* -45.00 */
#define MIC_RES 0x0300 /* +03.00 */
#define MIC_DEFAULT 0x0000

#define VOL_MIN 0x00C4
#define VOL_MAX 0x0000

static const usb_device_class_audio_volume_config usb_stereo_audio_volume_default = 
{  
    0xC400, /* speaker min -60dB */
    0x0000, /* speaker max 0dB */
    0x0100, /* resolution of 1dB */
    0xEC00, /* default volume */
    MIC_MIN,/* mic_min -45dB */
    MIC_MAX,/* mic_max 0dB */
    MIC_RES,/* mic resolution of 3dB to match hardware */
    MIC_DEFAULT /* mic default volume of max */
};

#endif

#endif /* _SINK_USB_DESCRIPTORS_H_ */
