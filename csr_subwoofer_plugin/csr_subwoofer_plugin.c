/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012

FILE NAME
    csr_subwoofer_plugin.c

DESCRIPTION
    An audio plugin for the subwoofer device
*/

/* Subwoofer plugin includes */
#include "csr_subwoofer_plugin.h"
#include "csr_subwoofer.h"

/* External library includes */
#include <audio_plugin_if.h>
#include <audio_plugin_common.h>

/* Firmware includes */
#include <audio.h>
#include <print.h>
#include <message.h>


/* The plugin message handler */
static void message_handler(Task task, MessageId id, Message message);

/* Handle messages from the Audio library */
static void handleAudioMessage(Task task, MessageId id, Message message);

/* The plugin task */
const TaskData csr_subwoofer_plugin = {message_handler};


/****************************************************************************
DESCRIPTION
	The main task message handler
*/
static void message_handler(Task task, MessageId id, Message message)
{
	if ( (id >= AUDIO_DOWNSTREAM_MESSAGE_BASE ) && (id <= AUDIO_DOWNSTREAM_MESSAGE_TOP) )
	{
		handleAudioMessage(task, id, message);
	}
    else
    {
        handleInternalPluginMessage(task, id, message);
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
    switch(id)
    {
        case AUDIO_PLUGIN_CONNECT_MSG:
        {
            CsrSubwooferPluginConnect( ((AUDIO_PLUGIN_CONNECT_MSG_T *)message)->audio_sink,
                                       ((AUDIO_PLUGIN_CONNECT_MSG_T *)message)->codec_task,
                                       ((AUDIO_PLUGIN_CONNECT_MSG_T *)message)->app_task,
                                       (subwooferPluginConnectParams *) ((AUDIO_PLUGIN_CONNECT_MSG_T*)message)->params );
        }
        break;
        case AUDIO_PLUGIN_DISCONNECT_MSG:
        {
            CsrSubwooferPluginDisconnect();
        }
        break;
        case AUDIO_PLUGIN_SET_VOLUME_MSG:
        {
            CsrSubwooferPluginSetVolume( ((AUDIO_PLUGIN_SET_VOLUME_MSG_T *)message)->volume );
        }
        break;
        case AUDIO_PLUGIN_SET_MODE_MSG:
        {
            CsrSubwooferPluginSetMode( (subwooferPluginModeParams *) ((AUDIO_PLUGIN_SET_MODE_MSG_T *)message)->params );
        }
        break;
        case AUDIO_PLUGIN_SET_ROUTE_MSG:
        {
            PRINT(("SubwooferAudioPlugin : AUDIO_PLUGIN_SET_ROUTE_MSG\n"));
        }
        break;
        case AUDIO_PLUGIN_PLAY_TONE_MSG:
        {
            PRINT(("SubwooferAudioPlugin : AUDIO_PLUGIN_PLAY_TONE_MSG\n"));
        }
        break;
        case AUDIO_PLUGIN_STOP_TONE_MSG:
        {
            PRINT(("SubwooferAudioPlugin : AUDIO_PLUGIN_STOP_TONE_MSG\n"));
        }
        break;
        default:
        {
            PRINT(("SubwooferAudioPlugin : Unhandled audio message ID[%x]\n", id));
        }
        break;
    }
}
