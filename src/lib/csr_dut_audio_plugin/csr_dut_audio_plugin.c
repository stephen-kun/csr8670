/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_dut_audio_plugin.c
    
DESCRIPTION
    Audio plugin for DUT mode

*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <print.h>
#include <stream.h> /*for the ringtone_note*/

#include "audio_plugin_if.h" /*the messaging interface*/
#include "csr_dut_audio_plugin.h"
#include "csr_dut_audio.h"

    /*the task message handler*/
static void message_handler(Task task, MessageId id, Message message);

    /*the local message handling functions*/
static void handleAudioMessage(Task task, MessageId id, Message message);
static void handleInternalMessage(Task task, MessageId id, Message message);
    
    /*the plugin task*/
const TaskData csr_dut_audio_plugin = {message_handler};

/****************************************************************************
DESCRIPTION
    The main task message handler
*/
static void message_handler(Task task, MessageId id, Message message) 
{
    if ((id >= AUDIO_DOWNSTREAM_MESSAGE_BASE) && (id <= AUDIO_DOWNSTREAM_MESSAGE_TOP))
    {
        handleAudioMessage(task, id, message);
    }
    else
    {
        handleInternalMessage(task, id, message);
    }
}    

/****************************************************************************
DESCRIPTION

    messages from the audio library are received here. 
    and converted into function calls to be implemented in the 
    plugin module
*/ 
static void handleAudioMessage(Task task, MessageId id, Message message)     
{
    switch (id)
    {
        case (AUDIO_PLUGIN_CONNECT_MSG):
        {
            AUDIO_PLUGIN_CONNECT_MSG_T *connect_message = (AUDIO_PLUGIN_CONNECT_MSG_T *)message;
    
            if (IsAudioBusy())
            {         
                /*Queue the connect message until the audio task is available*/
                MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_CONNECT_MSG); 
                
                message->audio_sink = connect_message->audio_sink;
                message->sink_type  = connect_message->sink_type;
                message->codec_task = connect_message->codec_task;
                message->volume     = connect_message->volume;
                message->rate       = connect_message->rate;
                message->mode       = connect_message->mode;
                message->route      = connect_message->route;                
                message->features   = connect_message->features;
                message->params     = connect_message->params;
                message->app_task   = connect_message->app_task;
                
                MessageSendConditionally(task, AUDIO_PLUGIN_CONNECT_MSG, message, (const uint16 *)AudioBusyPtr());
            } 
            else
            {
                CsrDutAudioPluginConnect(connect_message->codec_task, connect_message->volume, connect_message->mode, connect_message->features.stereo, connect_message->rate, connect_message->params);            
            }            
        }    
        break ;
        
        case (AUDIO_PLUGIN_DISCONNECT_MSG):
        {
            if (IsAudioBusy())
            {
                MessageSendConditionally(task, AUDIO_PLUGIN_DISCONNECT_MSG, 0, (const uint16 *)AudioBusyPtr());
            }
            else
            {
                CsrDutAudioPluginDisconnect();
            }
        }    
        break ;
        
        case (AUDIO_PLUGIN_SET_MODE_MSG):
        {
            AUDIO_PLUGIN_SET_MODE_MSG_T *mode_message = (AUDIO_PLUGIN_SET_MODE_MSG_T *)message;            
            
            if (IsAudioBusy())
            {
                MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_SET_MODE_MSG);
                
                message->mode   = mode_message->mode;
                message->params = mode_message->params;
        
                MessageSendConditionally(task, AUDIO_PLUGIN_SET_MODE_MSG, message, (const uint16 *)AudioBusyPtr());
            }
            else
            {
                CsrDutAudioPluginSetMode(mode_message->mode);
            }
        }
        break ;
        
        case (AUDIO_PLUGIN_SET_VOLUME_MSG ): 
        {
            AUDIO_PLUGIN_SET_VOLUME_MSG_T *volume_message = (AUDIO_PLUGIN_SET_VOLUME_MSG_T *)message;            
            
            if (IsAudioBusy())
            {
                 MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_SET_VOLUME_MSG);
                 message->volume = volume_message->volume;
                 
                 MessageSendConditionally(task, AUDIO_PLUGIN_SET_VOLUME_MSG, message,(const uint16 *)AudioBusyPtr());        
            }
            else
            {
                CsrDutAudioPluginSetVolume(volume_message->volume);
            }            
        }        
        break ;
        
        case (AUDIO_PLUGIN_PLAY_TONE_MSG):
        {
            AUDIO_PLUGIN_PLAY_TONE_MSG_T *tone_message = (AUDIO_PLUGIN_PLAY_TONE_MSG_T *)message;
            
            if (!IsAudioBusy()) 
            {    
                SetAudioBusy((TaskData*) &csr_dut_audio_plugin);    
                CsrDutAudioPluginPlayTone(tone_message->tone, tone_message->codec_task,                       
                            tone_message->tone_volume, tone_message->features.stereo);                             
            }
        }
        break ;
        
        case (AUDIO_PLUGIN_STOP_TONE_MSG):
        {
            if (IsAudioBusy())
            {
                CsrDutAudioPluginStopTone();                
            }
        }
        break ;        
        
        default:
        {

        }
        break ;
    }
}

/****************************************************************************
DESCRIPTION
    Internal messages to the task are handled here
*/ 
static void handleInternalMessage(Task task, MessageId id, Message message)     
{
    switch (id)
    {
        case MESSAGE_STREAM_DISCONNECT: /*a tone has completed*/
        {   
            /* tone finished */
            SetAudioBusy(NULL);             
            
            if (!CsrDutAudioPluginToneComplete())
            {
                CsrDutAudioPluginRepeatTone(task);
            }
        }    
        break;
        
        default:
        {
            Panic();
        }
        break;
    }
}
