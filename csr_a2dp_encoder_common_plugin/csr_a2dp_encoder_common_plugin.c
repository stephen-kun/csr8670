/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_encoder_common_plugin.c
    
DESCRIPTION
    

NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <print.h>
#include <stream.h>

#include "audio_plugin_if.h"
#include "csr_a2dp_encoder_common_plugin.h"
#include "csr_a2dp_encoder_common_if.h"
#include "csr_a2dp_encoder_common.h"


/* the task message handler */
static void message_handler(Task task, MessageId id, Message message);

/* the local message handling functions */
static void handleAudioMessage(Task task, MessageId id, Message message);
static void handleInternalMessage(Task tas, MessageId id, Message message);
    
/* the plugin task */
const A2dpEncoderPluginTaskdata csr_a2dp_sbc_encoder_plugin = {{message_handler}, SBC_ENCODER};
const A2dpEncoderPluginTaskdata csr_a2dp_faststream_encoder_plugin = {{message_handler}, FASTSTREAM_ENCODER};
const A2dpEncoderPluginTaskdata csr_a2dp_aptx_encoder_plugin = {{message_handler}, APTX_ENCODER};
const A2dpEncoderPluginTaskdata csr_a2dp_aptx_lowlatency_encoder_plugin = {{message_handler}, APTX_LOWLATENCY_ENCODER};


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
        handleInternalMessage(task, id,message);
    }
}    

/****************************************************************************
DESCRIPTION

    Messages from the audio library are received here. 
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
                MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_CONNECT_MSG); 
                
                message->audio_sink = connect_message->audio_sink;
                message->codec_task = connect_message->codec_task;
                message->volume = connect_message->volume;
                message->rate  = connect_message->rate;
                message->mode = connect_message->mode;
                message->features = connect_message->features;
                message->params = connect_message->params;
                
                MessageSendConditionally(task, AUDIO_PLUGIN_CONNECT_MSG, message, (const uint16 *)AudioBusyPtr());
            } 
            else
            {        /*connect the audio*/
                CsrA2dpEncoderPluginConnect((A2dpEncoderPluginTaskdata *)task,
                                            connect_message->codec_task,
                                            connect_message->volume, 
                                            connect_message->rate,
                                            connect_message->features.stereo,
                                            connect_message->mode, 
                                            connect_message->params);
            }            
        }    
        break;
        
        case (AUDIO_PLUGIN_DISCONNECT_MSG):
        {
            MessageCancelAll(task, AUDIO_PLUGIN_CONNECT_MSG);
            
            if (IsAudioBusy())
            {
                MessageSendConditionally(task, AUDIO_PLUGIN_DISCONNECT_MSG,0 ,(const uint16 *)AudioBusyPtr());
            }
            else
            {
                CsrA2dpEncoderPluginDisconnect();
            }
        }    
        break;
        
        case (AUDIO_PLUGIN_SET_MODE_MSG):
        {
            AUDIO_PLUGIN_SET_MODE_MSG_T *mode_message = (AUDIO_PLUGIN_SET_MODE_MSG_T *)message;            
            
            if (IsAudioBusy())
            {
                MAKE_AUDIO_MESSAGE(AUDIO_PLUGIN_SET_MODE_MSG);
                message->mode = mode_message->mode;
                message->params = mode_message->params;
        
                MessageSendConditionally(task, AUDIO_PLUGIN_SET_MODE_MSG, message, (const uint16 *)AudioBusyPtr());        
            }
            else
            {
                CsrA2dpEncoderPluginSetMode((A2dpEncoderPluginTaskdata *)task, mode_message->mode, mode_message->params);
            }
        }
        break;
        
        case (AUDIO_PLUGIN_SET_VOLUME_MSG): 
        {
            AUDIO_PLUGIN_SET_VOLUME_MSG_T *volume_message = (AUDIO_PLUGIN_SET_VOLUME_MSG_T *)message;            
            
            if (IsAudioBusy())
            {
                 MAKE_AUDIO_MESSAGE (AUDIO_PLUGIN_SET_VOLUME_MSG);
                 message->volume = volume_message->volume;
                 
                 MessageSendConditionally(task, AUDIO_PLUGIN_SET_VOLUME_MSG, message, (const uint16 *)AudioBusyPtr() );  
            }
            else
            {
                CsrA2dpEncoderPluginSetVolume(volume_message->volume);
            }            
        }        
        break;
        
        case (AUDIO_PLUGIN_PLAY_TONE_MSG):
        {           
        }
        break;
        
        case (AUDIO_PLUGIN_STOP_TONE_MSG):
        {         
        }
        break;        
        
        default:
        {
        }
        break;
    }
}

/****************************************************************************
DESCRIPTION
    Internal messages to the task are handled here
*/ 
static void handleInternalMessage(Task task, MessageId id, Message message)     
{    
    /* should this really be cleared in all circumstances, or was only a single
     * message expected and this is the action?!? */
    SetAudioBusy( NULL );

    switch (id)
    {
        default:
        {
            CsrA2dpEncoderPluginInternalMessage((A2dpEncoderPluginTaskdata*)task, id, message);
            break;
        }
    }
}
