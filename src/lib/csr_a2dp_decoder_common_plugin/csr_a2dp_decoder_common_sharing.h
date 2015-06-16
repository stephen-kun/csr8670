/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_subwoofer.h

DESCRIPTION
    
    
NOTES
   
*/
 
#ifndef _CSR_A2DP_DECODER_COMMON_SHARING_H_
#define _CSR_A2DP_DECODER_COMMON_SHARING_H_

extern void CsrA2dpDecoderPluginForwardUndecoded(A2dpPluginTaskdata *task , bool enable, Sink sink, bool content_protection);
extern void CsrA2dpDecoderPluginDisconnectForwardingSink(void);

#endif


