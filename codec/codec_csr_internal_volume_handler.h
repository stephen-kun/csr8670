/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    codec_csr_internal_volume_handler.h
    
DESCRIPTION
	
*/

#ifndef CODEC_CSR_INTERNAL_VOLUME_HANDLER_H_
#define CODEC_CSR_INTERNAL_VOLUME_HANDLER_H_


/****************************************************************************
NAME	
	handleCsrInternalInputGainReq

DESCRIPTION
	Function to handle internal input gain request message, for the CSR internal
	codec.
*/
void handleCsrInternalInputGainReq(const CODEC_INTERNAL_INPUT_GAIN_REQ_T *req);


/****************************************************************************
NAME	
	handleCsrInternalOutputGainReq

DESCRIPTION
	Function to handle internal output gain request message, for the CSR internal
	codec.
*/
void handleCsrInternalOutputGainReq(const CODEC_INTERNAL_OUTPUT_GAIN_REQ_T *req);


#endif /* CODEC_CSR_INTERNAL_VOLUME_HANDLER_H */
