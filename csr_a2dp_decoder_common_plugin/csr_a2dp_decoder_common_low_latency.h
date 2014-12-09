/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_low_latency.h

DESCRIPTION
    
    
NOTES
   
*/
 
#ifndef _CSR_A2DP_DECODER_COMMON_LOW_LATENCY_H_
#define _CSR_A2DP_DECODER_COMMON_LOW_LATENCY_H_


extern void CsrA2dpDecoderPluginLowLatencyInternalMessage(A2dpPluginTaskdata *task ,uint16 id , Message message);
extern void CsrA2dpDecoderLowLatencyPluginSetEqMode(A2DP_MUSIC_PROCESSING_T music_processing);

        
#endif


