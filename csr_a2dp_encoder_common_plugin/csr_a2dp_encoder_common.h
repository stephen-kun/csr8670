/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_encoder_common.h

DESCRIPTION
    
    
NOTES
   
*/

#ifndef _CSR_A2DP_ENCODER_COMMON_H_
#define _CSR_A2DP_ENCODER_COMMON_H_


#define DSP_PORT_USB_IN             0
#define DSP_PORT_USB_OUT            1
#define DSP_PORT_ANALOGUE_IN_L      0
#define DSP_PORT_ANALOGUE_IN_R      1
#define DSP_PORT_SPDIF_IN_L         0
#define DSP_PORT_SPDIF_IN_R         1
#define DSP_PORT_A2DP_DEV_A         2
#define DSP_PORT_A2DP_DEV_B         3

/* Defines used to parse channel status message from SPDIF input
 * and to set the corresponding SCMS bits in the RTP encoder */
/* Position of consumer/professional bit */
#define CHANNEL_STATUS_CON_PRO_BIT  (1)
#define CHANNEL_STATUS_CONSUMER     (0)
#define CHANNEL_STATUS_PROFESSIONAL (1)

/* Position of CP-bit in Channel Status message */
#define CHANNEL_STATUS_CP_BIT       (1<<2)      
/* Position of L-bit in Channel Status message */
#define CHANNEL_STATUS_L_BIT        (1<<15)
/* Enable CP-bit in SCMS parameter to RTP encoder transform */
#define SCMS_BITS_CP_ON             (1<<1)
/* Enable L-bit in SCMS parameter to RTP encoder transform */
#define SCMS_BITS_L_ON              (1)


void CsrA2dpEncoderPluginConnect(A2dpEncoderPluginTaskdata *task, Task codec_task, uint16 volume, uint32 rate, bool stereo, AUDIO_MODE_T mode, const void *params);
void CsrA2dpEncoderPluginDisconnect(void);
void CsrA2dpEncoderPluginSetVolume(uint16 volume);
void CsrA2dpEncoderPluginSetMode(A2dpEncoderPluginTaskdata *task, AUDIO_MODE_T mode, const void *params);

/****************************************************************************
FUNCTION
    CsrA2dpEncoderPluginInternalMessage

DESCRIPTION
    Handle internal messages and messages from the DSP
*/
void CsrA2dpEncoderPluginInternalMessage(A2dpEncoderPluginTaskdata *task, uint16 id, Message message);


#endif /* _CSR_A2DP_ENCODER_COMMON_H_ */
