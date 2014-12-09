/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_dut_audio.h

DESCRIPTION
    Audio plugin for DUT mode

*/

#ifndef _CSR_DUT_AUDIO_H_
#define _CSR_DUT_AUDIO_H_


void CsrDutAudioPluginConnect(Task codec_task, uint16 volume, AUDIO_MODE_T mode, bool stereo, uint32 rate, const void * params);

void CsrDutAudioPluginDisconnect(void);

void CsrDutAudioPluginSetMode(AUDIO_MODE_T mode);

void CsrDutAudioPluginSetVolume(uint16 volume);

void CsrDutAudioPluginPlayTone(ringtone_note *tone, Task codec_task, uint16 tone_volume, bool stereo);

void CsrDutAudioPluginStopTone(void);

bool CsrDutAudioPluginToneComplete(void);

void CsrDutAudioPluginRepeatTone(Task task);


#endif

