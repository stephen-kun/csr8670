/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_subwoofer.h

DESCRIPTION
    
    
NOTES
   
*/
 
#ifndef _CSR_A2DP_DECODER_COMMON_SUBWOOFER_H_
#define _CSR_A2DP_DECODER_COMMON_SUBWOOFER_H_

extern void CsrA2dpDecoderPluginSetSubWoofer(AUDIO_SUB_TYPE_T sub_type, Sink sub_sink);
extern void CsrA2dpDecoderPluginDisconnectSubwoofer(void);
extern void CsrA2dpDecoderPluginConnectSubwoofer(A2dpPluginConnectParams *codecData);
extern void SubConnectedNowUnmuteVolume(DECODER_t * DECODER);

#endif


