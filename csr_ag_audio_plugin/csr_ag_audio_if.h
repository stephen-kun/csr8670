/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_ag_audio_if.h

DESCRIPTION
   
*/

#ifndef _CSR_AG_AUDIO_INTERFACE_H_
#define _CSR_AG_AUDIO_INTERFACE_H_
  
/* Message ID for sending mode from VM to DSP */
#define MESSAGE_SETMODE         0x0004 

/* Message ID for sending warp values from VM to DSP */
#define MESSAGE_SEND_WARP       0x1026

/* Message ID for warp values sent from DSP to VM */
#define KALIMBA_MSG_WARP_VALUES 0x1025

/* Message ID for sending Bluetooth address from VM to DSP */
#define MESSAGE_REM_BT_ADDRESS  0x2001
 
#define SYSMODE_PSTHRGH         0

#define MINUS_45dB              0x0      /* value used with SetOutputGainNow VM trap */

#define CODEC_MUTE              MINUS_45dB

#define BYTES_PER_MSBC_FRAME    60

/* dsp message structure*/
typedef struct
{
    uint16 id;
    uint16 a;
    uint16 b;
    uint16 c;
    uint16 d;
} DSP_REGISTER_T;

/* Values for the selecting the plugin variant in the CsrAgAudioPluginTaskData structure  */
typedef enum
{
   CSR_AG_AUDIO_CVSD_8K_1_MIC  =  0,
   CSR_AG_AUDIO_CVSD_8K_2_MIC  =  1,
   CSR_AG_AUDIO_SBC_16K_1_MIC  =  2,
   CSR_AG_AUDIO_SBC_2_MIC      =  3,
   CSR_AG_AUDIO_CVSD_48K_1_MIC =  4,
   CSR_AG_AUDIO_SBC_48K_1_MIC  =  5
}CSR_AG_AUDIO_PLUGIN_TYPE_T;



typedef struct tag_mic_type
{
   unsigned preamp_enable:1; /* high bit */
   unsigned unused:6;
   unsigned digital_gain:4;
   unsigned analogue_gain:5;   /* low bits */
} T_mic_gain;

static const T_mic_gain MIC_MUTE = {0,0,8,0};  /* -45db, -24db, preamp=off */
static const T_mic_gain MIC_DEFAULT_GAIN = {1,0,0x1,0xa}; /* +3db for digital and analog, preamp=in */


#endif

