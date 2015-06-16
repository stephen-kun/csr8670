/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_speech_recognition.c

DESCRIPTION
    Speech Recognition application interface.
        
NOTES

    This enables and disables the csr speech recognition plugin and
    converts the response into sink device user events. 
    
    Speech Recognition can be used for answering / rejecting a call and is 
    enabled when the sink device event EventSysSpeechRecognitionStart is received at 
    the application event handler. This calls speechRecognitionStart()
    which starts the speech recognition engine and registers a const task for the 
    callback message. 
    
    Once the callback is received, this is converted into an applcication message
    (user event) which actions the sink device application.
    
    No globals used 
    1 bit required in sink_private.h for storing whther the speech rec is active 
    or not - this is in turn used (via speechRecognitionIsActive() ) for the 
    sink_audio.c code to decide whether or not to process any audio stream 
    connections 
    
    

*/

#ifdef ENABLE_SPEECH_RECOGNITION

/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_speech_recognition.h"
#include "sink_configmanager.h"
#include "sink_audio.h"
#include "sink_statemanager.h"
#include "sink_audio_routing.h"

#ifdef ENABLE_GAIA
#include "sink_gaia.h"
#endif

#include <csr_cvc_common_plugin.h>
#include <audio.h>

#ifdef DEBUG_SPEECH_REC
#define SR_DEBUG(x) DEBUG(x)
#else
#define SR_DEBUG(x) 
#endif


static void speech_rec_handler(Task task, MessageId id, Message message);       

/* task for messages to be delivered */
static const TaskData speechRecTask = {speech_rec_handler};   


/*************************************************************************
NAME
    plugin_for_ssr
    
DESCRIPTION
    Determine the appropriate CVC plugin to run with SSR enabled
*/
static TaskData *plugin_for_ssr(void)
{
    TaskData *plugin;
    
    plugin = audioHfpGetPlugin(hfp_wbs_codec_mask_cvsd, theSink.features.audio_plugin);
    
    /* 1 mic headset? */
    if((plugin == (TaskData *) &csr_cvsd_cvc_1mic_headset_plugin) ||
       (plugin == (TaskData *) &csr_cvsd_cvc_1mic_headset_bex_plugin))
    {
        /* use the asr 1-mic task instead */
        return (TaskData *) &csr_cvsd_cvc_1mic_asr_plugin;
    }
    
    /* 2 mic headset? */
    if((plugin == (TaskData *) &csr_cvsd_cvc_2mic_headset_plugin) ||
       (plugin == (TaskData *) &csr_cvsd_cvc_2mic_headset_bex_plugin))
    {
        /* use the asr 2-mic task instead */
        return (TaskData *) &csr_cvsd_cvc_2mic_asr_plugin;
    }
    
    /* 1 mic handsfree? */
    if((plugin == (TaskData *) &csr_cvsd_cvc_1mic_handsfree_plugin) ||
       (plugin == (TaskData *) &csr_cvsd_cvc_1mic_handsfree_bex_plugin))
    {
        /* use the asr 1-mic hf task instead */
        return (TaskData *) &csr_cvsd_cvc_1mic_hf_asr_plugin;            
    }
    
    /* 2mic handsfree? */
    if((plugin == (TaskData *) &csr_cvsd_cvc_2mic_handsfree_plugin) ||
       (plugin == (TaskData *) &csr_cvsd_cvc_2mic_handsfree_bex_plugin))
    {
        /* use the asr 2-mic hf task instead */
        return (TaskData *) &csr_cvsd_cvc_2mic_hf_asr_plugin;
    }
    
    
    /* This shouldn't happen; all plugins known to the config tool are
     * accounted for above
     */
    SR_DEBUG(("Speech Rec using default plugin\n"));
    return (TaskData *) &csr_cvsd_cvc_1mic_asr_plugin;
}


/****************************************************************************
DESCRIPTION
  	This function is called to enable speech recognition mode
*/
void speechRecognitionStart(void)
{
    /* if not already running, start asr */
    if ( !theSink.csr_speech_recognition_is_active )
    {   
        TaskData *task;
        
        SR_DEBUG(("Speech Rec START - AudioConnect\n")) ;
    
        theSink.csr_speech_recognition_is_active = TRUE ;
    
        /*reconnect any audio streams that may need connecting*/
        if(theSink.routed_audio)
        {
            /* get status info in malloc'd memory slot */
            audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);        
            
            /* attempt to disconnect and/or suspend current source */
            if(!audioSuspendDisconnectSource(lAudioStatus))
                SR_DEBUG(("Speech Rec START - Audio Already Connected NOT disconnected\n")) ;
    
            /* release memory */        
            freePanic(lAudioStatus);
        }
            
        /* choose variant of cvc to run with asr enabled */
        task = plugin_for_ssr();
                
        /*connect the speech recognition plugin - this will be disconnected 
        automatically when a word has been recognised (successfully or unsuccessfully  */
        AudioConnect ( task,
                       theSink.routed_audio  ,
                       AUDIO_SINK_SCO ,
                       theSink.codec_task ,
                       theSink.features.DefaultVolume ,
                       8000 ,
                       theSink.conf2->audio_routing_data.PluginFeatures ,
                       AUDIO_MODE_CONNECTED,
                       AUDIO_ROUTE_INTERNAL,
                       powerManagerGetLBIPM(),
                       &theSink.cvc_params,
                       (TaskData*)&speechRecTask ) ;       
    }
    /* already running, just restart timeout timer */
    else
    {
       SR_DEBUG(("Speech Rec START - restart detected\n")) ;
    }
    
    /*post a timeout message to restart the SR if no recognition occurs*/
    if(!theSink.csr_speech_recognition_tuning_active)
        MessageSendLater((TaskData*)&speechRecTask , CSR_SR_APP_TIMEOUT , 0, theSink.conf1->timeouts.SpeechRecRepeatTime_ms ) ;
}

/****************************************************************************
DESCRIPTION
  	This function is called to reenable speech recognition mode
*/
void speechRecognitionReStart(void)
{
    TaskData *task;
    
    SR_DEBUG(("Speech Rec RESTART - AudioConnect\n")) ;

    theSink.csr_speech_recognition_is_active = TRUE ;

    /* choose variant of cvc to run with asr enabled */
    task = plugin_for_ssr();
            
    /*connect the speech recognition plugin - this will be disconnected 
    automatically when a word has been recognised (successfully or unsuccessfully  */
    AudioConnect ( task,
                   theSink.routed_audio  ,
                   AUDIO_SINK_SCO ,
                   theSink.codec_task ,
                   theSink.features.DefaultVolume ,
                   8000 ,
                   theSink.conf2->audio_routing_data.PluginFeatures ,
                   AUDIO_MODE_CONNECTED,
                   AUDIO_ROUTE_INTERNAL,
                   powerManagerGetLBIPM(),
                   &theSink.cvc_params,
                   (TaskData*)&speechRecTask ) ;       
           
}
/****************************************************************************
DESCRIPTION
  	This function is called to disable speech recognition mode
*/
void speechRecognitionStop(void)
{
    SR_DEBUG(("Speech Rec STOP\n")) ;

    /*if the SR plugin is attached / disconnect it*/
    if ( theSink.csr_speech_recognition_is_active )
    {
        SR_DEBUG(("Disconnect SR Plugin\n")) ; 
        AudioDisconnect() ;
    }

    theSink.csr_speech_recognition_is_active = FALSE ;
    
    /*cancel any potential APP timeout message */
    MessageCancelAll( (TaskData*)&speechRecTask , CSR_SR_APP_TIMEOUT ) ;

    /* cancel any queued start messages */    
    MessageCancelAll (&theSink.task , EventSysSpeechRecognitionStart) ;

    /*reconnect any audio streams that may need connecting*/
    audioHandleRouting(audio_source_none) ;

}

/****************************************************************************
DESCRIPTION
  	This function is called to determine if speech rec is currently running
RETURNS
    True if Speech Rec is active
*/
bool speechRecognitionIsActive(void)
{
    SR_DEBUG(("Speech Rec ACTIVE[%x]\n" , (int)theSink.csr_speech_recognition_is_active  )) ;

    return theSink.csr_speech_recognition_is_active ;
}

/****************************************************************************
DESCRIPTION
  	This function is called to determine if speech rec is enabled
RETURNS
    True if Speech Rec is enabled
*/
bool speechRecognitionIsEnabled(void) 
{
    /* Check if SR is enabled globally and return accordingly*/
    return (theSink.features.speech_rec_enabled && theSink.ssr_enabled);
}


/****************************************************************************
DESCRIPTION
  	This function is the message handler which receives the messages from the 
    SR library and converts them into suitable application messages 
*/
static void speech_rec_handler(Task task, MessageId id, Message message)
{
    SR_DEBUG(("ASR message received \n")) ;
    
    switch (id) 
    {
        case CSR_SR_WORD_RESP_YES:
        {
            SR_DEBUG(("\nSR: YES\n"));

            /* when in tuning mode, restart after a successful match */
            if(theSink.csr_speech_recognition_tuning_active)
            {
                /* recognition suceeded, restart */
                AudioDisconnect() ;
                theSink.routed_audio = NULL ;
                MessageSendLater((TaskData*)&speechRecTask , CSR_SR_APP_RESTART , 0, 100 ) ;
            }
            /* normal operation mode for incoming call answer */
            else if (stateManagerGetState() == deviceIncomingCallEstablish)
            {
                MessageSend (&theSink.task , EventUsrAnswer , 0) ;
            }

            MessageSend (&theSink.task , EventSysSpeechRecognitionTuningYes , 0) ;
        }
        break;

        case CSR_SR_WORD_RESP_NO:  
        {
            SR_DEBUG(("\nSR: NO\n"));

            /* when in tuning mode, restart after a successful match */
            if(theSink.csr_speech_recognition_tuning_active)
            {
                /* recognition suceeded, restart */
                AudioDisconnect() ;
                theSink.routed_audio = NULL ;
                MessageSendLater((TaskData*)&speechRecTask , CSR_SR_APP_RESTART , 0, 100 ) ;
            }
            /* normal operation mode for incoming call answer */
            else if (stateManagerGetState() == deviceIncomingCallEstablish)
            {
                MessageSend (&theSink.task , EventUsrReject , 0) ;
            }

            MessageSend (&theSink.task , EventSysSpeechRecognitionTuningNo , 0) ;
        }    
        break;

        case CSR_SR_WORD_RESP_FAILED_YES:
        case CSR_SR_WORD_RESP_FAILED_NO:
        case CSR_SR_WORD_RESP_UNKNOWN:
        {
            SR_DEBUG(("\nSR: Unrecognized word, reason %x\n",id));

            /* restart the ASR engine */            
            AudioStartASR(AUDIO_MODE_CONNECTED);
        }   
        break;
        
        case CSR_SR_APP_RESTART:
            SR_DEBUG(("SR: Restart\n"));
            /* recognition failed, try again */
            speechRecognitionReStart();
        break;
        
        case CSR_SR_APP_TIMEOUT:
        {
            SR_DEBUG(("\nSR: TimeOut - Restart\n"));
           
            /* disable the timeout when in tuning mode */
            if ((!theSink.csr_speech_recognition_tuning_active)&&(stateManagerGetState() == deviceIncomingCallEstablish))
            {
                MessageCancelAll (&theSink.task , EventSysSpeechRecognitionStart) ;
                MessageSend (&theSink.task , EventSysSpeechRecognitionStart , 0) ; 
            }                
        }
        break ;

        default:
            SR_DEBUG(("SR: Unhandled message 0x%x\n", id));
        /*    panic();*/
        break;
    }
    
#ifdef ENABLE_GAIA
    if (stateManagerGetState() != deviceIncomingCallEstablish)
    {
        gaiaReportSpeechRecResult(id);
    }
#endif
}


#else
static const int dummy ;

#endif


