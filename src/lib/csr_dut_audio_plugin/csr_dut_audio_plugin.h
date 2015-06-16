/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_dut_audio_plugin.h

DESCRIPTION
    Audio plugin for DUT mode
   
*/

/*!
@file   csr_dut_audio_plugin.h
@brief  Header file for audio playback in DUT mode plugin

*/

#ifndef _CSR_DUT_AUDIO_PLUGIN_H_
#define _CSR_DUT_AUDIO_PLUGIN_H_

#include <message.h>

/*! 
    The task used to receive the audio_plugin_if messages for the audio library    
*/
extern const TaskData csr_dut_audio_plugin;

#endif

