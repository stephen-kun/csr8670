/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    codec_volume.c
    
DESCRIPTION
	
*/

#include <stdlib.h>


#include "codec.h"
#include "codec_private.h"
#include "codec_csr_internal_message_handler.h"
#include <codec.h>

/****************************************************************************
NAME
 VolumeConvertDACGainToDB

DESCRIPTION
 Converts dac gain to dB value

RETURNS
 dB value

*/
int16 VolumeConvertDACGainToDB(uint16 DAC_Gain)
{
    int32 Result;    
    
    /* convert from 0 to 15 DAC gain to -45 to 0dB */  
    Result = ((DAC_Gain / CODEC_STEPS) * (0 - MIN_CODEC_GAIN_DB));
    Result += MIN_CODEC_GAIN_DB;
    Result *= DB_DSP_SCALING_FACTOR;
    
    return (int16)Result;
}

/****************************************************************************
NAME
 VolumeConvertStepsToDB

DESCRIPTION
 Converts decimal step values into dB values for DSP volume control scheme

RETURNS
 dB value

*/
int16 VolumeConvertStepsToDB(int16 Volume, dsp_volume_user_config * volMappingConfig, int16 dbScale)
{
    /* Volume - volume number from 1 to no_of_steps (it is assumed that vol 0 will be mute)
     dbMin - minimum volume in integer dB returned when Volume is 1
     dbMax - maximum volume in integer dB returned when Volume is number of steps - 1
     Knee(2) - Volume at which volume curve changes
     dbKnee(2) - integer dB of volume at Knee changes
     dbScale - volume scaling for VM/DSP interface (60)

     if a single segment line is required, then set avrcpKnee to 0 and dbKnee to dbMin */

    int16 result;
    convert_volume_db_t * convert = PanicUnlessMalloc(sizeof(convert_volume_db_t));
    
    convert->volMax = (volMappingConfig->no_of_steps - 1);
    convert->volMin = 1;
    
    convert->x0 = volMappingConfig->volume_knee_value_1;
	convert->y0 = volMappingConfig->dB_knee_value_1;
	convert->x1 = volMappingConfig->volume_knee_value_2;
	convert->y1 = volMappingConfig->dB_knee_value_2;

    if (Volume < volMappingConfig->volume_knee_value_1)
    {
        convert->x0 = convert->volMin;
        convert->x1 = volMappingConfig->volume_knee_value_1;
        convert->y0 = volMappingConfig->dB_min;
        convert->y1 = volMappingConfig->dB_knee_value_1;
    }

    if (Volume > volMappingConfig->volume_knee_value_2)
    {
        convert->x0 = volMappingConfig->volume_knee_value_2;
        convert->x1 = convert->volMax;
        convert->y0 = volMappingConfig->dB_knee_value_2;
        convert->y1 = volMappingConfig->dB_max;
    }
    convert->dx = convert->x1 - convert->x0;
    convert->dy = convert->y1 - convert->y0;

    convert->e = (Volume-convert->x0)*convert->dy;
    convert->dB = ((1+2*convert->e/convert->dx)/2);
    convert->e -= convert->dB*convert->dx;
    convert->dB = (convert->y0+convert->dB)*dbScale + ((1+2*dbScale*convert->e/convert->dx)/2);

    result = convert->dB;
    
    /* free temporary memory */
    free (convert);
    
    return result;
}

/****************************************************************************
NAME
 codecCalcHybridValues

DESCRIPTION
 Converts dB volume (*60) into separate dsp gain of 0 to -3dB and a dac gain

RETURNS
 dac gain and dB dsp value

*/
bool CodecCalcHybridValues(hybrid_gains_t * gains, int16 volume)
{
    /* ensure volume is within allowed range */
    if((volume > MAXIMUM_DIGITAL_VOLUME_0DB)||(volume < MINIMUM_DIGITAL_VOLUME_80dB))
    {
        /* out of range volume level */
        return FALSE;
    }
    
    /* integer maths to get the next highest dac gain value in the range 0 to 15 whereby
       0 = -45dB and 15 = 0dB */
    if(volume < (MIN_CODEC_GAIN_DB * DB_DSP_SCALING_FACTOR))
    {
        /* < -45dB which is outside of the DAC gain control, therefore use
           min DAC gain and control the rest via the DSP */
        gains->dac_gain = 0;
    }
    /* volume required is within the range -45 to 0dB which is within the DAC control range */
    else
    {
        gains->dac_gain = (CODEC_STEPS + (volume/DB_TO_DAC));
    }
    
    /* dsp attenuation up to -3dB is now calculated */
    gains->dsp_db_scaled = (volume - ((CODEC_STEPS - gains->dac_gain) * DB_TO_DAC * -1));
    
    return TRUE;
}

void CodecSetInputGain(Task codecTask, uint16 volume, codec_channel channel)
{
	MAKE_CODEC_MESSAGE(CODEC_INTERNAL_INPUT_GAIN_REQ);
	message->volume = volume;
    message->channel = channel;
	MessageSend(codecTask, CODEC_INTERNAL_INPUT_GAIN_REQ, message);
}


void CodecSetInputGainNow(Task codecTask, uint16 volume, codec_channel channel)
{
    Source input_source;
    
	if (channel != right_ch)
	{
		input_source = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
		SourceConfigure(input_source, STREAM_CODEC_INPUT_GAIN, volume); 
		SourceClose(input_source);
	}
	if (channel != left_ch)
	{
		input_source = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
		SourceConfigure(input_source, STREAM_CODEC_INPUT_GAIN, volume); 			
		SourceClose(input_source);
	}
}


void CodecSetOutputGain(Task codecTask, uint16 volume, codec_channel channel)
{
	MAKE_CODEC_MESSAGE(CODEC_INTERNAL_OUTPUT_GAIN_REQ);
    message->volume = volume;
	message->channel = channel;
	MessageSend(codecTask, CODEC_INTERNAL_OUTPUT_GAIN_REQ, message);
}


void CodecSetOutputGainNow(Task codecTask, uint16 volume, codec_channel channel)
{
    Sink output_sink;
    
    if (channel == left_and_right_ch)
	{
		if (!StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A))
		{
			output_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A_AND_B);            
			SinkConfigure(output_sink, STREAM_CODEC_OUTPUT_GAIN, volume);
			SinkClose(output_sink);
			return;
		}            
	}
	
	if (channel != right_ch)
	{
		output_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
		SinkConfigure(output_sink, STREAM_CODEC_OUTPUT_GAIN, volume);
		SinkClose(output_sink);
	}
	if (channel != left_ch)
	{
		output_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
		SinkConfigure(output_sink, STREAM_CODEC_OUTPUT_GAIN, volume);	
		SinkClose(output_sink);
	}
}

/****************************************************************************
NAME
 CodecSetOutputGainLater

DESCRIPTION
 delayed setting of the DAC gains

RETURNS
 none

*/
void CodecSetOutputGainLater(Task codecTask, uint16 volume, codec_channel channel, uint16 delay)
{
	MAKE_CODEC_MESSAGE(CODEC_INTERNAL_OUTPUT_GAIN_REQ);
    message->volume = volume;
	message->channel = channel;
	MessageSendLater(codecTask, CODEC_INTERNAL_OUTPUT_GAIN_REQ, message, delay);
}   
    



