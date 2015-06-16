/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    audio_plugin_common.c
    
DESCRIPTION
    Implementation of audio plugin common library.
*/

#include <stream.h>
#include <source.h>
#include <micbias.h>
#include <pio.h>
#include <pio_common.h>

#include "audio_plugin_if.h"
#include "audio_plugin_common.h"


/****************************************************************************
DESCRIPTION
    Get analogue or digital mic
*/
Source AudioPluginGetMic(audio_channel channel, bool digital)
{
    return StreamAudioSource(digital ? AUDIO_HARDWARE_DIGITAL_MIC : AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, channel);
}


/****************************************************************************
DESCRIPTION
    Configure Mic channel
*/
void AudioPluginSetMicRate(Source mic_source, bool digital, uint32 adc_rate)
{
    PanicFalse(SourceConfigure(mic_source, digital ? STREAM_DIGITAL_MIC_INPUT_RATE : STREAM_CODEC_INPUT_RATE, adc_rate));
}


/****************************************************************************
DESCRIPTION
    Set mic gain
*/
void AudioPluginSetMicGain(Source mic_source, bool digital, uint16 gain, bool preamp)
{
    if (digital)
    {
        SourceConfigure(mic_source, STREAM_DIGITAL_MIC_INPUT_GAIN, gain);
    }
    else
    {
        SourceConfigure(mic_source, STREAM_CODEC_INPUT_GAIN, gain);
        SourceConfigure(mic_source, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, preamp);
    }
}


/****************************************************************************
DESCRIPTION
    Set mic bias or digital mic PIO on or off
*/
void AudioPluginSetMicPio(const audio_mic_params params, bool set)
{
    if(params.drive_pio)
    {
        if(params.bias)
        {
            PanicFalse(MicbiasConfigure((mic_bias_id)params.pio, MIC_BIAS_ENABLE, (set ? MIC_BIAS_FORCE_ON : MIC_BIAS_OFF)));
        }
        else
        {
            PanicFalse(PioCommonSetPin(params.pio, pio_drive, set));
        }
    }
}


/****************************************************************************
DESCRIPTION
    Apply mic configuration and set mic PIO
*/
Source AudioPluginMicSetup(audio_channel channel, const audio_mic_params params, uint32 rate)
{
    Source mic_source = AudioPluginGetMic(channel, params.digital);
    AudioPluginSetMicRate(mic_source, params.digital, rate);
    AudioPluginSetMicGain(mic_source, params.digital, params.gain, params.pre_amp);
    AudioPluginSetMicPio(params, TRUE);
    return mic_source;
}

