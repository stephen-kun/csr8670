/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    codec_csr_internal_volume_handler.c
    
DESCRIPTION
	
*/

#include "codec.h"
#include "codec_private.h"
#include "codec_csr_internal_volume_handler.h"


/****************************************************************************
NAME	
	handleCsrInternalInputGainReq

DESCRIPTION
	Function to handle internal input gain request message, for the CSR internal
	codec.
*/
void handleCsrInternalInputGainReq(const CODEC_INTERNAL_INPUT_GAIN_REQ_T *req)
{
    Source input_source;
            
    if (req->channel != right_ch)
	{
		input_source = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
		SourceConfigure(input_source, STREAM_CODEC_INPUT_GAIN, req->volume); 
        SourceClose(input_source);
	}
	
    if (req->channel != left_ch)
	{	
		input_source = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
        SourceConfigure(input_source, STREAM_CODEC_INPUT_GAIN, req->volume); 
        SourceClose(input_source);
	}
}


/****************************************************************************
NAME	
	handleCsrInternalOutputGainReq

DESCRIPTION
	Function to handle internal output gain request message, for the CSR internal
	codec.
*/
void handleCsrInternalOutputGainReq(const CODEC_INTERNAL_OUTPUT_GAIN_REQ_T *req)
{
    Sink output_sink;
    
    if (req->channel == left_and_right_ch)
    {
        if (!StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A))
        {
            output_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A_AND_B);
            SinkConfigure(output_sink, STREAM_CODEC_OUTPUT_GAIN, req->volume);
            SinkClose(output_sink);
            return;
        }            
    }
    
    if (req->channel != right_ch)
	{
        output_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
        SinkConfigure(output_sink, STREAM_CODEC_OUTPUT_GAIN, req->volume);		
        SinkClose(output_sink);
	}
	
    if (req->channel != left_ch)
    {
		output_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
        SinkConfigure(output_sink, STREAM_CODEC_OUTPUT_GAIN, req->volume); 
        SinkClose(output_sink);
	}
}


