/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_decoder_common_low_latency.c
DESCRIPTION
    plugin implentation which routes the sco audio though the dsp
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <print.h>
#include <file.h>
#include <stream.h> /*for the ringtone_note*/
#include <kalimba.h>
#include <kalimba_standard_messages.h>
#include <message.h>
#include <ps.h>
#include <Transform.h>
#include <string.h>
#include <pio_common.h>
#include <pblock.h>

#include "csr_i2s_audio_plugin.h"
#include "audio_plugin_if.h" /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_a2dp_decoder_common_plugin.h"
#include "csr_a2dp_decoder_common.h"
#include "csr_a2dp_decoder_common_if.h"
#include "csr_a2dp_decoder_common_faststream.h"
#include "csr_a2dp_decoder_common_cvc_back_channel.h"
#include "csr_a2dp_decoder_common_low_latency.h"


/****************************************************************************
DESCRIPTION
    This function handles the messages for the low latency codec types including 
    FASTSTREAM and APTX LL, the message ID's overlap between the standard and 
    low latency dsp apps when the back channel is enabled and hence a separate 
    message handler is required   
    
****************************************************************************/
void CsrA2dpDecoderPluginLowLatencyInternalMessage(A2dpPluginTaskdata *task ,uint16 id , Message message)
{
    A2DP_DECODER_PLUGIN_TYPE_T variant = task->a2dp_plugin_variant;
    DECODER_t * DECODER = CsrA2dpDecoderGetDecoderData();

    /* dsp message handler, determine message id */
    switch(id)
    {
       /* message validity check */
       case MESSAGE_FROM_KALIMBA:
       {
            const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
            PRINT(("LOW_LATENCY DECODER: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));

            switch ( m->id )
            {
               case MUSIC_TONE_COMPLETE:
                {
                   SetAudioBusy(NULL) ;
                   CsrA2dpDecoderPluginToneComplete() ; 
                }
                break;
                /* get the pskey configuration data repsonse */
                case LOW_LATENCY_LOAD_PERSIST:
                {
                    /* a=sysid, b=len */
                    const pblock_entry* entry = PblockGet(m->a);
                    KalimbaSendLongMessage(LOW_LATENCY_LOAD_PERSIST_RESP, entry->size, entry->data);                       
                }
                break;                
                
                /* indication that the dsp is loaded and ready to accept configuration data */
                case LOW_LATENCY_READY_MSG:
                {
                    if (DECODER)
                    {
                        A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;

                        /* load configuration parameters from ps, different for low latency variants */
                        /* different pskey base address for cvc back channel support */
                        KalimbaSendMessage(LOW_LATENCY_LOADPARAMS_MSG, MUSIC_PS_BASE_WBS_BACK_CHANNEL, CVC_SR_WB, 0, 0);
                        
                        /* Set silence detection params for Soundbar*/
                        if(codecData->is_for_soundbar)
                        {
                            PRINT(("DECODER: Message SILENCE_DETECTION_PARAMS_MSG \n"));
                            PRINT(("Threshold %x, Timeout %x\n", codecData->silence_threshold, codecData->silence_trigger_time));
                            KalimbaSendMessage(LOW_LATENCY_SIGNAL_DET_SET_PARAMS_MSG, codecData->silence_threshold, codecData->silence_trigger_time, 0, 0);
                        }

                        /* Tell the DSP what plugin type is being used */
                        if(!KalimbaSendMessage(LOW_LATENCY_SET_PLUGIN_MSG, variant, 0, 0, 0))
                        {
                            PRINT(("DECODER: Message MUSIC_SET_PLUGIN_MSG failed!\n"));
                            Panic();
                        }
                        
                        PRINT(("DECODER: Message MUSIC_SET_PLUGIN_MSG variant = %x\n",variant));

                        /* update current dsp status */
                        {
                            /* send status message to app to indicate dsp is ready to accept data,
                               applicable to A2DP media streams only */
                            MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_READY_FOR_DATA, 0);
                            PRINT(("DECODER: Send CLOCK_MISMATCH_RATE\n"));
                            message->plugin = (TaskData *)task;
                            message->AUDIO_BUSY = (uint16)IsAudioBusy();
                            message->dsp_status = GetCurrentDspStatus();
                            message->media_sink = DECODER->media_sink;
                            MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_READY_FOR_DATA, message);
    
                            /*A2dp is now loaded, signal that tones etc can be scheduled*/
                            SetAudioBusy( NULL ) ;
                            PRINT(("DECODER: DECODER_READY \n"));

                            /* connect the dsp ports to the audio streams */
                            MusicConnectAudio (task);
                            /* update current dsp status */
                            SetCurrentDspStatus( DSP_RUNNING );
                        }
                    }
                    else
                    {
                        /* update current dsp status */
                        SetCurrentDspStatus( DSP_ERROR );
                    }
                }
                break;

                /* dsp confirmation that a volume change has been processed */
                case LOW_LATENCY_CODEC_MSG:
                {
                    uint16 lOutput_gain_l = m->a;
                    uint16 lOutput_gain_r = m->b;
                
                    if (DECODER)
                    {  
                        /* low latency codecs return the mic gain values and a combined left/right output level */
                        A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
                        T_mic_gain lInput_gain_l;
                        T_mic_gain lInput_gain_r;

                        /* if using the microphone or spdif/i2s back channel */   
                        if(isCodecLowLatencyBackChannel())
                        {
                            lInput_gain_l = *(T_mic_gain*)&m->b;
                            lInput_gain_r = *(T_mic_gain*)&m->c;                       

                            /* set the input gain values */
                            CvcMicSetGain(AUDIO_CHANNEL_A, codecData->mic_params->mic_a.digital, lInput_gain_l);
                            if(DECODER->features.use_two_mic_back_channel)
                                CvcMicSetGain(AUDIO_CHANNEL_B, codecData->mic_params->mic_b.digital, lInput_gain_r);
                        }

                        lOutput_gain_l = lOutput_gain_r = m->a;

                        /* when using the I2S audio output hardware */
                        if(DECODER->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
                        {
                            CsrI2SAudioOutputSetVolume(DECODER->features.stereo, lOutput_gain_l, lOutput_gain_r, FALSE);
                        }
                        /* built in audio output hardware */
                        else
                        {
                            CodecSetOutputGainNow(DECODER->codec_task, lOutput_gain_l, left_ch);
                            CodecSetOutputGainNow(DECODER->codec_task, lOutput_gain_r, right_ch);
                        }
                    }
                }
                break;

                /* dsp status information gets sent to the vm app */
                case KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE:
                {
                    if (DECODER)
                    {
                        MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_IND, 1);
                        PRINT(("DECODER: Send CLOCK_MISMATCH_RATE\n"));
                        message->id = KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE;
                        message->size_value = 1;
                        message->value[0] = m->a;
                        MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_IND, message);
                    }
                }
                break;

                case LOW_LATENCY_CUR_EQ_BANK:
                /* DSP tells plugin which EQ is active.  Send this value to the VM app
                   so the current EQ setting can be restored when the device is repowered.
                */
                {
                    if (DECODER)
                    {
                        MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_IND, 1);
                        PRINT(("DECODER: Current EQ setting: [%x][%x]\n", m->a, m->b));
                        message->id = A2DP_MUSIC_MSG_CUR_EQ_BANK;
                        message->size_value = 1;
                        message->value[0] = m->a;
                        MessageSend(DECODER->app_task, AUDIO_PLUGIN_DSP_IND, message);
                    }
                }
                break;

                case LOW_LATENCY_APTX_SEC_PASSED:
                {
                    PRINT(("aptX: Security passed.\n"));
/*                    KalimbaSendMessage(LOW_LATENCY_APTX_SECURITY_MSG, 1, 0, 0, 0);*/
                }
                break;

                case LOW_LATENCY_APTX_SEC_FAILED:
                {
                    PRINT(("aptX: Security failed.\n"));
/*                    KalimbaSendMessage(LOW_LATENCY_APTX_SECURITY_MSG, 0, 0, 0, 0);*/
                }
                break;

                case LOW_LATENCY_SIGNAL_DET_STATUS:
                /* DSP tells when signal detector status has changed
                Param1 == 0 => no audio - go into standby
                Param1 == 1 => receiving audio - come out of standby
                "no audio" message is sent when signal level has been below the
                threshold level for the trigger time out period "receiving audio"
                message is sent as soon as a signal is detected above the threshold level
                */

                {
                    A2dpPluginConnectParams *codecData = (A2dpPluginConnectParams *) DECODER->params;
                    uint16 signal = m->a;
                    PRINT(("SIGNAL_DETECTOR_STATUS_RESP: PARAM1 %x \n", signal));

                    /* Need to do only for Soundbar*/
                    if(codecData->is_for_soundbar)
                    {
                        if (signal)
                        {
                            /* Signal detected come out of standby */
                            PioCommonSetPin( codecData->speaker_pio, pio_drive, TRUE);
                        }
                        else
                        {
                            /* no audio go into standby */
                            PioCommonSetPin(codecData->speaker_pio, pio_drive, FALSE);
                        }
                    }
                }
                break;

                case LOW_LATENCY_CVC_SEC_PASSED:
                    PRINT(("CVC:  Sec passed.\n"));
                     /*cvc is now loaded, signal that tones etc can be scheduled*/
                    SetAudioBusy(NULL) ;
                break;

                case LOW_LATENCY_CVC_SEC_FAILED:
                    PRINT(("CVC: Security has failed.\n"));
                    /*cvc is now loaded, signal that tones etc can be scheduled*/
                    SetAudioBusy(NULL) ;
                break;

                case KALIMBA_MSG_CBOPS_SILENCE_CLIP_DETECT_CLIP_DETECTED_ID:
                {
                    PRINT(("\n\n\n\n\nInput level clipped.\n"));
                }
                break;                      

                case KALIMBA_MSG_CBOPS_SILENCE_CLIP_DETECT_SILENCE_DETECTED_ID:
                {
                    PRINT(("\n\n\n\n\nInput level silence.\n"));
                }
                break;   

                case KALIMBA_MSG_LATENCY_REPORT:
                {   /* DSP has sent us an audio latency measurement */
                    if (DECODER)
                    {
                    	CsrA2dpDecoderPluginSetAudioLatency(task, m->a);
                    }
                }
                break;

                default:
                    PRINT(("unhandled message id [%x]\n",m->id));
                break;
            }
        }
        break;

        case MESSAGE_FROM_KALIMBA_LONG:
        {
            const DSP_LONG_REGISTER_T *m = (const DSP_LONG_REGISTER_T*) message;
            PRINT(("CVC: LONG_MESSAGE_FROM_KALIMBA id[0x%x] l[0x%x] \n", m->id, m->size));
            switch (m->id)
            {
                case LOW_LATENCY_STOREPERSIST_MSG:
                    /* Set the DSP app's pblock */
                   PRINT(("CVC: StorePersist key[0x%x], data[0x%x] \n", m->buf[0], m->buf[1]));
                   PblockSet(m->buf[0], m->size-1, (uint16*)m->buf+1);
                break;
                
                default:
                break;
            }
        }
        break;
        default:
        break ;
    }    
}



/****************************************************************************
DESCRIPTION
    utility function to set the current EQ operating mode of the low latency bac channel apps

    @return void
*/
void CsrA2dpDecoderLowLatencyPluginSetEqMode(A2DP_MUSIC_PROCESSING_T music_processing)
{
    /* determine the music processing mode requirements, set dsp music mode appropriately */
    switch (music_processing)
    {
        case A2DP_MUSIC_PROCESSING_PASSTHROUGH:
            {
                KalimbaSendMessage (LOW_LATENCY_SET_EQ_MSG , MUSIC_SYSMODE_PASSTHRU , MUSIC_DO_NOT_CHANGE_EQ_BANK, 0, 0 );
                PRINT(("DECODER: Set Low Latency Mode SYSMODE_PASSTHRU\n"));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL:
            {
                KalimbaSendMessage (LOW_LATENCY_SET_EQ_MSG , MUSIC_DO_NOT_CHANGE_EQ_BANK, 0, 0, 0 );
                PRINT(("DECODER: Set Low Latency Mode SYSMODE_FULLPROC\n"));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_NEXT_EQ_BANK:
            {
                KalimbaSendMessage (LOW_LATENCY_SET_EQ_MSG , MUSIC_NEXT_EQ_BANK, 0, 0 ,0);
                PRINT(("DECODER: Set Low Latency Mode SYSMODE_FULLPROC and advance to next EQ bank\n"));
            }
            break;

        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0:
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK1:
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK2:
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK3:
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK4:
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK5:
        case A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK6:
            {
                KalimbaSendMessage (LOW_LATENCY_SET_EQ_MSG , MUSIC_SET_EQ_BANK, (music_processing - A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0), 0, 0);
                PRINT(("DECODER: Set Low Latency Mode SYSMODE_FULLPROC and set EQ bank\n"));
            }
            break;

        default:
            {
                PRINT(("DECODER: Set Low Latency Mode Invalid [%x]\n" , music_processing ));
            }
            break;
    }
}

