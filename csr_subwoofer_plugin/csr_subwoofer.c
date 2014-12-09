/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012

FILE NAME
    csr_subwoofer.c

DESCRIPTION
    Contains the internal plugin functions to handle audio routing for the 
    CSR subwoofer application
*/

/* Subwoofer plugin includes */
#include "csr_subwoofer.h"
#include "csr_subwoofer_plugin.h"
#include "csr_subwoofer_if.h"

/* External library includes */
#include <kalimba_standard_messages.h>
#include <audio.h>
#include <audio_plugin_common.h>
#include <codec.h>
#include <csr_i2s_audio_plugin.h>

/* Firmware includes */
#include <stdlib.h>
#include <file.h>
#include <panic.h>
#include <print.h>
#include <sink.h>
#include <stream.h>
#include <source.h>
#include <kalimba.h>
#include <message.h>

/* Filepath to the Kalimba DSP 'subwoofer decoder application' */
static const char kal[] = "subwoofer/subwoofer.kap";

/* Setup a pointer to the plugin data */
static subwooferPluginData * plugin_data = NULL;



/****************************************************************************/
void CsrSubwooferPluginConnect(Sink audio_sink, Task codec_task, Task app_task, subwooferPluginConnectParams * params)
{
    FILE_INDEX index;
    
    /* Update the current DSP status */
    SetCurrentDspStatus(DSP_LOADING);
    
    /* Give Kalimba the plugin task so it knows where to send messages */
    (void) MessageCancelAll( (TaskData*)&csr_subwoofer_plugin, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( (TaskData*)&csr_subwoofer_plugin );
    
    /* Load the Subwofoer DSP application - Panic if it could not be loaded */
    index = PanicFalse( FileFind(FILE_ROOT, kal, sizeof(kal) - 1) );
    PanicFalse( KalimbaLoad(index) );
    
    /* update current DSP status */
    SetCurrentDspStatus(DSP_LOADED_IDLE);
    
    /* Allocate memory to store the plugin data */
    plugin_data = (subwooferPluginData*)PanicUnlessMalloc(sizeof(subwooferPluginData));
    
    /* Initialise the plugin data based on parameters supplied by the application */
    plugin_data->audio_source           = StreamSourceFromSink(audio_sink);
    plugin_data->swat_system_volume_db  = params->swat_system_volume_db;
    plugin_data->swat_trim_gain_db      = params->swat_trim_gain_db;
    plugin_data->adc_volume_index       = params->adc_volume;
    plugin_data->input                  = params->input;
    plugin_data->output                 = params->output;
    plugin_data->sample_rate            = params->sample_rate;
    plugin_data->adc_sample_rate        = params->adc_sample_rate;
    plugin_data->codec_task             = codec_task;
    plugin_data->app_task               = app_task;
    plugin_data->dsp_set_sample_rate    = 0; /* set later in response to AUDIO_PLUGIN_SET_MODE_MSG */
    
    /* Zero the codecs output gain */
    CodecSetOutputGainNow(plugin_data->codec_task, 0, left_and_right_ch);
    CodecSetInputGainNow(plugin_data->codec_task, 0, left_and_right_ch);
    
    
    /* If using the ADC, set the ADC source */
    if (plugin_data->input == SUBWOOFER_INPUT_ADC)
    {
        /* Get the ADC source */
        plugin_data->audio_source = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
    }
    
    
    /* Disconnect the source in case it's currently being disposed */
    StreamDisconnect(StreamSourceFromSink(audio_sink), 0);
    
    PRINT(("[SW_PLUGIN] : CsrSubwooferPluginConnect - complete\n"));
}


/****************************************************************************/
void CsrSubwooferPluginDisconnect(void)
{
    /* Disconnect the appropriate input to Kalimba */
    if (plugin_data->input == SUBWOOFER_INPUT_ADC)
    {
        PRINT(("[SW_PLUGIN : Disconnect ADC to Kalimba\n"));
        StreamDisconnect(plugin_data->audio_source, StreamKalimbaSink(DSP_INPUT_PORT_ADC));
    }
    else if (plugin_data->input == SUBWOOFER_INPUT_ESCO)
    {
        PRINT(("[SW_PLUGIN] Disconnect eSCO to Kalimba\n"));
        StreamDisconnect(plugin_data->audio_source, StreamKalimbaSink(DSP_INPUT_PORT_ESCO));
        StreamConnectDispose(plugin_data->audio_source);
    }
    else if (plugin_data->input == SUBWOOFER_INPUT_L2CAP)
    {
        PRINT(("[SW_PLUGIN] Disconnect L2CAP to Kalimba\n"));
        StreamDisconnect(plugin_data->audio_source, StreamKalimbaSink(DSP_INPUT_PORT_L2CAP));
        StreamConnectDispose(plugin_data->audio_source);
    }
    
    /* Disconnect the appropriate output from Kalimba */
    if (plugin_data->output == SUBWOOFER_OUTPUT_DAC)
    {
        PRINT(("[SW_PLUGIN] Disconnect Kalimba to DAC\n"));
        StreamDisconnect(StreamKalimbaSource(DSP_OUTPUT_PORT_DAC), plugin_data->codec_sink);
    }
    else if (plugin_data->output == SUBWOOFER_OUTPUT_I2S)
    {
        PRINT(("[SW_PLUGIN] Disconnect Kalimba to I2S\n"));
        CsrI2SAudioOutputDisconnect(TRUE);                                 
    }
    
    /* dispose of any remaining messages in the queue */
    (void) MessageCancelAll( (TaskData*)&csr_subwoofer_plugin, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( NULL );
   
    /* Everything has been disconnected so power down Kalimba */
    KalimbaPowerOff();
    
    /* reset flags */
    SetAudioInUse(FALSE);
    SetCurrentDspStatus(DSP_NOT_LOADED);

    /* Free the memory allocated to use for the plugin as it's no longer valid */
    free(plugin_data);
    plugin_data = NULL;
}


/****************************************************************************
NAME
    sendErrorToClient

DESCRIPTION
    Helper function to send the error message to the client task
*/
static void sendErrorToClient(void)
{
    /* Build the plugin error message to let the application know something serious in the plugin has failed */
    AUDIO_PLUGIN_DSP_IND_T * message = PanicUnlessNew(AUDIO_PLUGIN_DSP_IND_T);
    message->id = SUB_PLUGIN_FATAL_ERROR;
    message->size_value = 1;
    message->value[0] = 0;
    
    /* Ensure all streams have been disconnected and DSP turned off before sending error (also free's all memory used by the plugin to prevent memory leak) */
    CsrSubwooferPluginDisconnect();
    
    MessageSend(plugin_data->app_task, AUDIO_PLUGIN_DSP_IND, message);
}


/****************************************************************************
NAME
    connectAudioStreams

DESCRIPTION
    Helper function to connect the audio streams
*/
static void connectAudioStreams(void)
{
    /* Connect the appropriate input stream to Kalimba */
    if (plugin_data->input == SUBWOOFER_INPUT_ADC)
    {
        PRINT(("[SW_PLUGIN] : Plugging ADC to Kalimba [%u]\n", plugin_data->adc_sample_rate));
        
        /* Configure the ADC */
        PanicFalse( SourceConfigure(plugin_data->audio_source, STREAM_CODEC_INPUT_RATE, plugin_data->adc_sample_rate) );
        
        /* Plug the ADC sink into the Kalimba */
        PanicFalse( StreamConnect(plugin_data->audio_source, StreamKalimbaSink(DSP_INPUT_PORT_ADC)) );
    }
    else if (plugin_data->input == SUBWOOFER_INPUT_ESCO)
    {
        /* Enable meta-data on the audio input */
        if ( SourceConfigure(plugin_data->audio_source, VM_SOURCE_SCO_METADATA_ENABLE, 1))
        {
            /* Plug the eSCO sink into the Kalimba */
            if ( !StreamConnect(plugin_data->audio_source, StreamKalimbaSink(DSP_INPUT_PORT_ESCO)) )
            {
                PRINT(("[SW_PLUGIN] : Plugging ESCO to Kalimba [FAILED]\n"));
                sendErrorToClient();
                /* Nothing more can be done here */
                return;
            }
            else
            {
                PRINT(("[SW_PLUGIN] : ESCO connected to Kalimba\n"));
            }
        }
        else
        {
            PRINT(("[SW_PLUGIN] : Plugging ESCO to Kalimba [FAILED]\n"));
            sendErrorToClient();
            /* Nothing more can be done here */
            return;
        }
    }
    else if (plugin_data->input == SUBWOOFER_INPUT_L2CAP)
    {
        /* Plug the L2CAP sink into the Kalimba */
        if ( !StreamConnect(plugin_data->audio_source, StreamKalimbaSink(DSP_INPUT_PORT_L2CAP)) )
        {
            PRINT(("[SW_PLUGIN] : Plugging L2CAP to Kalimba [FAILED]\n"));
            sendErrorToClient();
            /* Nothing more can be done here */
            return;
        }
        else
        {
            PRINT(("[SW_PLUGIN] : L2CAP connected to Kalimba\n"));
        }
    }
    else
    {
        PRINT(("[SW_PLUGIN] : Plugin parameter INPUT[%x] is invalid\n", plugin_data->input));
        Panic();
    }
    
    /* Connect Kalimba to the appropriate output stream */
    if (plugin_data->output == SUBWOOFER_OUTPUT_DAC)
    {
        
        
        /* Get the Codec DAC sink & Configure output rate */
        plugin_data->codec_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A_AND_B);
        if ( !SinkConfigure(plugin_data->codec_sink, STREAM_CODEC_OUTPUT_RATE, plugin_data->sample_rate) )
        {
            PRINT(("[SW_PLUGIN] : Could not configure DAC [%u]\n", plugin_data->sample_rate));
            sendErrorToClient();
            /* Nothing more can be done here */
            return;
        }
        
        /* Plug the audio route from Kalimba to the DAC */
        if ( !StreamConnect(StreamKalimbaSource(DSP_OUTPUT_PORT_DAC), plugin_data->codec_sink) )
        {
            PRINT(("[SW_PLUGIN] : Could not connect DAC to Kalimba[%u]\n", plugin_data->sample_rate));
            sendErrorToClient();
            /* Nothing more can be done here */
            return;
        }
        
        PRINT(("[SW_PLUGIN] : Kalimba connected to DAC\n"));
    }
    else if (plugin_data->output == SUBWOOFER_OUTPUT_I2S)
    {
        PRINT(("[SW_PLUGIN] : Plugging Kalimba to I2S [%u]\n", plugin_data->sample_rate));
        
        CsrI2SAudioOutputConnect(plugin_data->sample_rate, FALSE, StreamKalimbaSource(DSP_OUTPUT_PORT_I2S), NULL);
    }
    else
    {
        PRINT(("[SW_PLUGIN] : Plugin parameter OUTPUT[%x] is invalid\n", plugin_data->output));
        Panic();
    }
    
    /* set dsp operating flags */
    SetCurrentDspStatus(DSP_RUNNING);
    SetAudioInUse(TRUE);
}


/****************************************************************************/
void CsrSubwooferPluginSetVolume(uint16 volume)
{
    if (plugin_data->input == SUBWOOFER_INPUT_ADC)
    {
        /* Use ADC volume */
        plugin_data->adc_volume_index = volume;
        
        PRINT(("[SW_PLUGIN] : Set ADC volume VOLUME[%x]\n", plugin_data->adc_volume_index));
        
        KalimbaSendMessage(MUSIC_VOLUME_MSG, 0, 0, plugin_data->adc_volume_index, 0);
    }
    else
    {
        /* Update the System gain and subwoofer trim */
        plugin_data->swat_system_volume_db  = volume & 0xFF;
        plugin_data->swat_trim_gain_db      = volume >> 8;
        
        PRINT(("[SW_PLUGIN] : Set volume SWAT_SYSTEM_VOLUME[%x] SUBWOOFER_TRIM[%x]\n", plugin_data->swat_system_volume_db, plugin_data->swat_trim_gain_db));
        
        KalimbaSendMessage(MUSIC_VOLUME_MSG, plugin_data->swat_system_volume_db, plugin_data->swat_trim_gain_db, 0, 0);
    }
}


/****************************************************************************/
void CsrSubwooferPluginSetMode(subwooferPluginModeParams * params)
{
    if (params)
    {
        if (plugin_data->input == SUBWOOFER_INPUT_ADC)
        {
            /* Check params */
            
            /*
            r2 (bank_state) can be 0, 1, or 2:
                0 = do not advance to next EQ bank
                1 = advance to next EQ bank
                2 = use eq Bank that is specified in r3
            r3 (eq_bank) is only used if r2 = 2:
                valid range: 1 through 3 (choose which EQ bank to use); 0 is flat curve (LPF disabled).
            */

            if (params->cycle_eq)
            {
                PRINT(("[SW_PLUGIN] : Set mode (Cycle to the next EQ bank)\n"));
                KalimbaSendMessage(MUSIC_SETMODE_MSG, 0, 1, 0, 0);
            }
            else
            {
                PRINT(("[SW_PLUGIN] : Set mode (Use EQ Bank[%d])\n", params->eq_bank));
                KalimbaSendMessage(MUSIC_SETMODE_MSG, 0, 2, params->eq_bank, 0);
            }
        }
        else
        {
            /* Set mode message is used to set the sample rate for the DSP */
            CsrSubwooferPluginSetSampleRate( params->sample_rate );
        }
    }
    else
    {
        PRINT(("[SW_PLUGIN] : ERROR - Set mode (params are NULL)\n"));
    }
}


/****************************************************************************/
void CsrSubwooferPluginSetSampleRate(uint16 sample_rate)
{
    /* Update the sample rate stored by the plugin (only if new sample rate is different) */
    if (plugin_data->dsp_set_sample_rate != sample_rate)
    {
        PRINT(("[SW_PLUGIN] : Update sample rate from [%u] to [%u]\n", plugin_data->sample_rate, sample_rate));
        
        /* Send sample rate to the Kalimba */
        KalimbaSendMessage(MESSAGE_SET_DAC_SAMPLE_RATE, sample_rate/10, 0,0,0);
        
        /* Store the new sample rate */
        plugin_data->dsp_set_sample_rate = sample_rate;
    }
    else
    {
        PRINT(("[SW_PLUGIN] : Sample rate not changed [%u]\n", plugin_data->sample_rate));
    }
}


/****************************************************************************/
void handleInternalPluginMessage(Task task, MessageId id, Message message)
{
    switch(id)
    {
        case MESSAGE_FROM_KALIMBA:
        {
            const DSP_REGISTER_T *msg = (const DSP_REGISTER_T *)message;
            
            /* Handle the message sent from Kalimba */
            switch(msg->id)
            {
                case MUSIC_READY_MSG:
                {
                    PRINT(("[SW_PLUGIN] : MUSIC_READY_MSG a[%x] b[%x] c[%x] d[%x]\n", msg->a, msg->b, msg->c, msg->d));
                    if (plugin_data)
                    {
                        /* Send parameters PSKEY to DSP */
                        KalimbaSendMessage(MUSIC_LOADPARAMS_MSG, MUSIC_PS_BASE, 0, 0, 0);
                    }
                    else
                    {
                        SetCurrentDspStatus(DSP_ERROR);
                    }
                }
                break;
                case MUSIC_PARAMS_LOADED_MSG:
                {
                    /* Send a message to the app to inform the number of subwoofer volume gains (for ADC mode) */
                    AUDIO_PLUGIN_DSP_IND_T * message = PanicUnlessNew(AUDIO_PLUGIN_DSP_IND_T);
                    message->id = SUB_PLUGIN_NUM_VOL_GAINS;
                    message->size_value = 1;
                    message->value[0] = msg->a;
                    MessageSend(plugin_data->app_task, AUDIO_PLUGIN_DSP_IND, message);
                    
                    PRINT(("[SW_PLUGIN] : MUSIC_PARAMS_LOADED_MSG a[%x] b[%x] c[%x] d[%x]\n", msg->a, msg->b, msg->c, msg->d));
                    
                    /* Connect input and output streams */
                    connectAudioStreams();
                    
                    /* Send Volume to DSP */
                    KalimbaSendMessage(MUSIC_VOLUME_MSG, plugin_data->swat_system_volume_db, plugin_data->swat_trim_gain_db, 0, plugin_data->adc_volume_index);
                    
                    /* Set the DSP status */
                    SetCurrentDspStatus(DSP_RUNNING);
                    
                    /* Send GO to DSP */
                    PanicFalse(KalimbaSendMessage(KALIMBA_MSG_GO, 0, 0, 0, 0));
                    
                    /* Send a message to the app to inform that the plugin is ready to recieve audio data */
                    MessageSend(plugin_data->app_task, AUDIO_PLUGIN_DSP_READY_FOR_DATA, 0);
                }
                break;
                case MUSIC_CODEC_MSG:
                {
                    PRINT(("[SW_PLUGIN] : MUSIC_CODEC_MSG a[%x] b[%x] c[%x] d[%x]\n", msg->a, msg->b, msg->c, msg->d));
                    
                    /* Parameters for this message :                */
                    /* msg->a BITS[0-3] = input gain                */
                    /* msg->a BIT[15]   = enable/disable mic preamp */
                    /* msg->b = output gain                         */
                    
                    /* Only set the input gain if using the ADC input (ESCO/L2CAP inputs don't use the ADC) */
                    if (plugin_data->input == SUBWOOFER_INPUT_ADC)
                    {
                        PRINT(("[SW PLUGIN] : Set ADC input GAIN[%x] Pre-amp enable[%x]\n", (msg->a & 0x1F), (msg->a>>15) & 0x1));
                        AudioPluginSetMicGain(plugin_data->audio_source, FALSE, (msg->a & 0x1F), (msg->a>>15) & 0x1);
                    }
                    
                    PRINT(("[SW PLUGIN] : Set DAC GAIN[%x]\n", msg->b));

                    /* Set the codec output gain according to what the DSP sent */
                    if (plugin_data->output == SUBWOOFER_OUTPUT_I2S)
                    {
                        CsrI2SAudioOutputSetVolume(FALSE, msg->b, msg->b, FALSE);
                    }
                    else
                    {
                        CodecSetOutputGainNow(plugin_data->codec_task, msg->b, left_and_right_ch);
                    }
                }
                break;
                case MUSIC_CUR_EQ_BANK:
                {
                    PRINT(("[SW_PLUGIN] : MUSIC_CUR_EQ_BANK a[%x] b[%x] c[%x] d[%x]\n", msg->a, msg->b, msg->c, msg->d));
                    
                    /* TODO */
                }
                break;
                case MUSIC_SIGNAL_DETECT_STATUS:
                {
                    /* msg->a = 1 if playing audio, 0 if audio is silent */
                    PRINT(("[SW_PLUGIN] : MUSIC_SIGNAL_DETECT_STATUS a[%x]\n", msg->a));
                    
                    if (msg->a)
                    {
                        /* Audio on wired input has been detected - Inform client task */
                        AUDIO_PLUGIN_DSP_IND_T * message = PanicUnlessNew(AUDIO_PLUGIN_DSP_IND_T);
                        message->id = SUB_PLUGIN_ADC_SIGNAL_ACTIVE;
                        message->size_value = 1;
                        message->value[0] = 0;
                        MessageSend(plugin_data->app_task, AUDIO_PLUGIN_DSP_IND, message);
                    }
                    else
                    {
                        /* Audio on wired input is now silent - Inform client task */
                        AUDIO_PLUGIN_DSP_IND_T * message = PanicUnlessNew(AUDIO_PLUGIN_DSP_IND_T);
                        message->id = SUB_PLUGIN_ADC_SIGNAL_IDLE;
                        message->size_value = 1;
                        message->value[0] = 0;
                        MessageSend(plugin_data->app_task, AUDIO_PLUGIN_DSP_IND, message);
                    }
                 }
                break;
                default:
                {
                    PRINT(("[SW_PLUGIN] : Unhandled message from Kalimba ID[%x]\n", msg->id));
                }
                break;
            }
        }
        break;
        default:
        {
            PRINT(("[SW_PLUGIN] : Unhandled internal message ID[%x]\n", id));
        }
        break;
    }
}

