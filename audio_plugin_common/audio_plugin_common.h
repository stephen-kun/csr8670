/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    audio_plugin_common.h
    
DESCRIPTION
    Header file for the audio plugin common library.
*/

/*!
@file   audio_plugin_common.h
@brief  Header file for the audio plugin common library.
    
        This defines functionality common to all audio plugins.
*/

#ifndef _AUDIO_PLUGIN_COMMON_H_
#define _AUDIO_PLUGIN_COMMON_H_

/****************************************************************************
DESCRIPTION
    Get analogue or digital mic
*/
Source AudioPluginGetMic(audio_channel channel, bool digital);


/****************************************************************************
DESCRIPTION
    Configure Mic channel
*/
void AudioPluginSetMicRate(Source mic_source, bool digital, uint32 adc_rate);


/****************************************************************************
DESCRIPTION
    Set mic gain
*/
void AudioPluginSetMicGain(Source mic_source, bool digital, uint16 gain, bool preamp);


/****************************************************************************
DESCRIPTION
    Set mic bias or digital mic PIO on or off
*/
void AudioPluginSetMicPio(const audio_mic_params params, bool set);


/****************************************************************************
DESCRIPTION
    Apply mic configuration and set mic PIO
*/
Source AudioPluginMicSetup(audio_channel channel, const audio_mic_params params, uint32 rate);

#endif /* _AUDIO_PLUGIN_COMMON_H_ */
