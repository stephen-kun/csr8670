/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_faststream.h

DESCRIPTION
    
    
NOTES
   
*/
 
#ifndef _CSR_A2DP_DECODER_COMMON_FASTSTREAM_H_
#define _CSR_A2DP_DECODER_COMMON_FASTSTREAM_H_

/* Select CVC sample rate for run-time selectable CVC kap files  */
typedef enum
{
    CVC_SR_NB    =  0,
    CVC_SR_RESVD =  1,
    CVC_SR_BEX   =  2,
    CVC_SR_WB    =  3
}CVC_SR_TYPE_T;

extern void MusicConnectFaststream(A2dpPluginConnectParams *codecData );


#endif


