/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_cvc_common.c
    
DESCRIPTION
NOTES
*/

#ifndef SCO_DSP_BOUNDARIES
#define SCO_DSP_BOUNDARIES
#endif

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <stream.h>
#include <print.h>
#include <kalimba.h>
#include <file.h>
#include <stream.h>     /*for the ringtone_note*/
#include <connection.h> /*for the link_type */
#include <string.h>
#include <kalimba_standard_messages.h>
#include <source.h>
#include <transform.h>
#include <app/vm/vm_if.h>
#include <pblock.h>
#include <ps.h> 

#include "audio_plugin_if.h"        /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_cvc_common_if.h"      /*for things common to all CVC systems*/
#include "csr_cvc_common_plugin.h"
#include "csr_cvc_common.h"
#include "csr_i2s_audio_plugin.h"

/*helper functions*/
static void CvcConnectAudio (CvcPluginTaskdata *task);
static void CvcMicSetGain(audio_channel channel, bool digital, T_mic_gain gain);
static void CvcCodecMessage (CvcPluginTaskdata *task, T_mic_gain input_gain_l, T_mic_gain input_gain_r, uint16 output_gain ) ;
static void DisconnectMicNoDsp ( void );
static void DisconnectSpeakerNoDsp ( bool );
static void ConnectMicNoDsp ( void );
static void ConnectSpeakerNoDsp ( void ) ;
#ifdef CVC_ALL
static void ConnectSecondMicNoDsp ( void );
static void DisconnectSecondMicNoDsp ( void );
#endif


typedef struct audio_Tag
{
    /* vm task to send messages back to */
    TaskData* app_task;
    /*! The codec being used*/
    Task codec_task ; 
    /*! The audio sink being used*/
    Sink audio_sink ;
    /*! The audio source being used*/
    Source audio_source;
    /*! Over the air rate  */
    uint32 dac_rate;
    /*! Audio rate - used for mic switch */
    uint32 audio_rate;
    /*! Left microphone gain */
    T_mic_gain mic_gain_left;
    /*! Right microphone gain */
    T_mic_gain mic_gain_right;
#ifdef CVC_MULTI_KAP
    /*! Index of CVC kap file */
    FILE_INDEX app_index;
#endif
    const common_mic_params* digital;
    
    /*! The current volume level*/
    unsigned volume:8;
    /*! The current tone volume level*/
    unsigned tone_volume:8;
    
    /*! The current CVC mode */
    AUDIO_MODE_T mode:4 ;
    /*! The link_type being used*/
    AUDIO_SINK_T link_type:4 ;
    /*! CVC extended params */
    cvc_extended_parameters_t ext_params:1;
    /*! Whether or not CVC is running */
    unsigned cvc_running:1 ;
    /*! Set if in low power(CVC off) or no DSP mode*/
    unsigned no_dsp:1 ;
    /*! Indicates whether to switch to mic B (TRUE) or to mic A (FALSE) */
    unsigned switch_to_mic_b:1;
    /*! is tone mono or stereo*/
    unsigned tone_stereo:1;
    /* flag used to control the connecting of ports */
    unsigned ports_connected:1;
    /*! mono or stereo/use i2s output */
    AudioPluginFeatures features;      
}CVC_t ;

/* The CVC task instance pointer*/
static CVC_t * CVC = NULL;

/* dsp message structure*/
typedef struct
{
    uint16 id;
    uint16 a;
    uint16 b;
    uint16 c;
    uint16 d;
} DSP_REGISTER_T;

typedef struct
{
    uint16 id;
    uint16 size;
    char   buf[1];
} DSP_LONG_REGISTER_T;

static const char* csrCvcPluginGetKapFile(CVC_PLUGIN_TYPE_T variant)
{
#ifdef CVC_MULTI_KAP
    switch(variant)
    {
        case CVSD_CVC_1_MIC_HEADSET:
        case CVSD_CVC_1_MIC_HEADSET_BEX:
        case WBS_CVC_1_MIC_HEADSET:
            return "cvc_headset_share/cvc_headset_share.kap";
			
        case CVSD_CVC_2_MIC_HEADSET:
        case CVSD_CVC_2_MIC_HEADSET_BEX:
        case WBS_CVC_2_MIC_HEADSET:
            return "cvc_headset_2mic_share/cvc_headset_2mic_share.kap";
			
		case CVSD_CVC_1_MIC_HANDSFREE:
		case CVSD_CVC_1_MIC_HANDSFREE_BEX:
		case WBS_CVC_1_MIC_HANDSFREE:		
            return "cvc_handsfree_share/cvc_handsfree_share.kap";			
			
        default:
            Panic() ;
            return NULL;
    }
    
#else   
    switch(variant)
    {
        case CVSD_CVC_1_MIC_HEADSET:
        case CVSD_CVC_1_MIC_HEADSET_BEX:
        case WBS_CVC_1_MIC_HEADSET:
        case CVSD_CVC_1_MIC_HEADSET_ASR:
            return "cvc_headset/cvc_headset.kap";
			
        case CVSD_CVC_2_MIC_HEADSET:
        case CVSD_CVC_2_MIC_HEADSET_BEX:
        case WBS_CVC_2_MIC_HEADSET:
        case CVSD_CVC_2_MIC_HEADSET_ASR:
            return "cvc_headset_2mic/cvc_headset_2mic.kap";

		case CVSD_CVC_1_MIC_HANDSFREE:            
		case CVSD_CVC_1_MIC_HANDSFREE_BEX:
		case WBS_CVC_1_MIC_HANDSFREE:	
        case CVSD_CVC_1_MIC_HANDSFREE_ASR:
			return "cvc_handsfree/cvc_handsfree.kap";		
			
		case CVSD_CVC_2_MIC_HANDSFREE:            
		case CVSD_CVC_2_MIC_HANDSFREE_BEX:
		case WBS_CVC_2_MIC_HANDSFREE:		
        case CVSD_CVC_2_MIC_HANDSFREE_ASR:
			return "cvc_handsfree_2mic/cvc_handsfree_2mic.kap";		

        default:
            Panic() ;
            return NULL;
    }
#endif   
}

/****************************************************************************
NAME    
    CsrCvcPluginConnect

DESCRIPTION
    This function connects cvc to the stream subsystem

RETURNS
    void
*/
void CsrCvcPluginConnect( CvcPluginTaskdata *task, 
                          Sink audio_sink , 
                          AUDIO_SINK_T sink_type, 
                          Task codec_task , 
                          uint16 volume , 
                          uint32 rate ,
                          AudioPluginFeatures features , 
                          AUDIO_MODE_T mode,
                          AUDIO_POWER_T power,
                          Source audio_source,
                          const common_mic_params* digital,
                          TaskData * app_task)
{
    FILE_INDEX index=0; 
    const char* kap_file = NULL ;
    
    /*signal that the audio is busy until the kalimba / parameters are fully loaded so that no tone messages etc will arrive*/
    SetAudioBusy((TaskData*) task);
  
    PanicNotNull(CVC);
    CVC = PanicUnlessNew ( CVC_t ); 
    
    /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
    if (volume > 0xf)
        volume = 0xf;
    
    CVC->app_task        = (TaskData *) app_task;
    CVC->cvc_running     = FALSE;
    CVC->digital         = digital;
    CVC->codec_task      = codec_task;
    CVC->link_type       = sink_type;
    CVC->volume          = volume;
    CVC->audio_sink      = audio_sink;
    CVC->audio_source    = audio_source;
    CVC->mode            = mode;
    CVC->ext_params      = CSR_CVC_HFK_ENABLE;
    CVC->tone_volume     = volume;
    CVC->audio_rate      = rate;
    CVC->features        = features;
    CVC->switch_to_mic_b = TRUE;
    CVC->tone_stereo     = features.stereo;
    /* Check if this is the no dsp plugin or should be started in low power mode */
    CVC->no_dsp = (task->cvc_plugin_variant == CVSD_NO_DSP);
    
    /* Set clear mic pin */
    AudioPluginSetMicPio(CVC->digital->mic_a, TRUE);
    if(task->two_mic) 
        AudioPluginSetMicPio(CVC->digital->mic_b, TRUE);
    
    /* Don't drop to no DSP if meta data cannot be disabled */
    if(power <= LPIBM_THRESHOLD)
    {
        bool can_disable_meta = (task->encoder != LINK_ENCODING_SBC) && SourceConfigure(CVC->audio_source, VM_SOURCE_SCO_METADATA_ENABLE, 0);
        if(can_disable_meta && sink_type != AUDIO_SINK_USB)
            CVC->no_dsp = TRUE;
        else
            CVC->ext_params = CSR_CVC_PSTHRU_ENABLE;
    }
    
    PRINT(("CVC: connect [%x] [%x] [%x]\n", CVC->cvc_running , (int)CVC->audio_sink, (int)CVC->audio_source));
    
    /* Calculate the DAC rate based on the over-the-air rate value passed in from VM */
    if(CVC->no_dsp)
    {     /* force DAC rate to 8k if in low power mode and not WBS */
         CVC->dac_rate = 8000; 
    }
    else
    {
        /* Set ADC & DAC to 16 or 8 kHz  */   
        CVC->dac_rate = (task->adc_dac_16kHz)?16000:8000; 
    }
    
    /* Fow WBS set SBC Frame size, else sample-based */
    if(((CVC_PLUGIN_TYPE_T)task->encoder) == LINK_ENCODING_SBC)
    {
        SinkConfigure(CVC->audio_sink,VM_SINK_SCO_SET_FRAME_LENGTH,60); 
    } 

    /* If in no DSP mode then just connect the ports, if this is cVc then continue and load the DSP */
    if (CVC->no_dsp)
    {
        PRINT(("CVC: connect No DSP\n"));
    
        /* Disable MetaData */
        SourceConfigure(CVC->audio_source,VM_SOURCE_SCO_METADATA_ENABLE,0);
    
        CvcConnectAudio (task) ;   
            
        CsrCvcPluginSetVolume(task, volume);
        SetAudioBusy( NULL );
        SetCurrentDspStatus(DSP_NOT_LOADED);
        return;
    }  

    /* Enable MetaData - not supported for USB*/
    if((sink_type != AUDIO_SINK_USB)&&(CVC->audio_source))
        SourceConfigure(CVC->audio_source,VM_SOURCE_SCO_METADATA_ENABLE,1);   
    else
        (void) MessageCancelAll( (TaskData*) task, MESSAGE_FROM_KALIMBA);
       
    /*ensure that the messages received are from the correct kap file*/ 
    (void) MessageCancelAll( (TaskData*) task, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( (TaskData*) task );
    
    /* Select which Kap file to be loaded based on the plugin selected */
    kap_file = csrCvcPluginGetKapFile(task->cvc_plugin_variant);
    index = FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file));
    PRINT(("CVC: App File [0x%X] %s\n", index, kap_file));
    PanicFalse(index != FILE_NONE);

#ifdef CVC_MULTI_KAP
    /* Store app index for later */
    CVC->app_index = index;
    
    /* Start by loading the core kap file */
    kap_file = "cvc_core/cvc_core.kap";
    index = FileFind(FILE_ROOT, kap_file, strlen(kap_file));
    PRINT(("CVC: Core File [0x%X] %s\n", index, kap_file));
    PanicFalse(index != FILE_NONE);
#endif

    /* Load the cvc algorithm into Kalimba*/
    if( !KalimbaLoad( index ) )
    {
        PRINT(("CVC: Kalimba load fail\n"));
        Panic();
    }

    /* Now the kap file has been loaded, wait for the CVC_READY_MSG message from the
       dsp to be sent to the message_handler function. In the case of CVC_MULTI_KAP
       we wait for CVC_CORE_READY. */
    SetCurrentDspStatus(DSP_LOADING);

}


/****************************************************************************
NAME    
    CsrCvcPluginDisconnect

DESCRIPTION
    Disconnect CVC and power off the Kalimba DSP core
    
RETURNS
    void
*/
void CsrCvcPluginDisconnect( CvcPluginTaskdata *task )
{
    PanicNull(CVC);
    
    CodecSetOutputGainNow( CVC->codec_task, DAC_MUTE, left_and_right_ch );  

    if (CVC->no_dsp)
    {
        PRINT(("CVC: NO DSP: disconnect\n"));

        /* deteremine output type */
        switch(CVC->features.audio_output_type)
        {
            /* when using the i2s output in conjunction with external hardware */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {
                /* disconnect I2S output to dsp */
                CsrI2SAudioOutputDisconnect(CVC->features.stereo);  
            }
            break;
            
            /* using spdif audio output */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                /* obtain source to SPDIF hardware and disconnect it */
                Sink l_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
                Sink r_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
                StreamDisconnect(0, l_sink);
                SinkClose(l_sink);
                StreamDisconnect(0, r_sink);
                SinkClose(r_sink);
            }
            break;

            /* dac output */
            default:
            {
                DisconnectSpeakerNoDsp(FALSE) ;
            }
            break;
        }
        /* disconnect the microphones */
        DisconnectMicNoDsp() ;
        #ifdef CVC_ALL
        DisconnectSecondMicNoDsp() ;
        #endif
        /* set the DAC volume level */
        CodecSetOutputGainNow( CVC->codec_task, CVC->volume , left_and_right_ch );
    }
    else
    {
        Source mic_source_a = NULL;
        Source mic_source_b = NULL;
        Sink   spkr_sink_a  = NULL;
        Sink   spkr_sink_b  = NULL;
        /* check cvc running */
        PanicFalse(CVC->cvc_running);

        PRINT(("CVC: Destroy transforms\n")); 

        /* deteremine output type */
        switch(CVC->features.audio_output_type)
        {
            /* when using the i2s output in conjunction with external hardware */
            case OUTPUT_INTERFACE_TYPE_I2S:
            {
               /* connect I2S output to dsp */
               CsrI2SAudioOutputDisconnect(CVC->features.stereo);  
            }
            break;
        
            /* using spdif audio output */
            case OUTPUT_INTERFACE_TYPE_SPDIF:
            {
                /* obtain source to SPDIF hardware and disconnect it */
                Sink l_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A );
                Sink r_sink = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B );
                StreamDisconnect(0, l_sink);
                SinkClose(l_sink);
                StreamDisconnect(0, r_sink);
                SinkClose(r_sink);
            }
            break;

            /* DAC output type */
            default:
            {
                /* disconnect left DAC channel */
                spkr_sink_a = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A);
                StreamDisconnect(StreamKalimbaSource(CVC_LEFT_PORT), spkr_sink_a); 
                SinkClose(spkr_sink_a);        
                /* when operating in stereo mode, disconnect the second audio output channel */
                if(CVC->features.stereo)
                {
                    spkr_sink_b  = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                    StreamDisconnect(StreamKalimbaSource(CVC_RIGHT_PORT), spkr_sink_b);  
                    SinkClose(spkr_sink_b);
                }
            }                
            break;
        }                        
            
        /* disconnect left mic channel */
        mic_source_a = AudioPluginGetMic(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital);

        /* disconnect the streams */
        StreamDisconnect(mic_source_a, StreamKalimbaSink(CVC_LEFT_PORT)); 
        
        /* ensure sources are closed */
        SourceClose(mic_source_a);

        /* for the two mic variant disconnect the second microphone */
        if( task->two_mic )
        {
            mic_source_b = AudioPluginGetMic(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital);
            StreamDisconnect(mic_source_b, StreamKalimbaSink(CVC_RIGHT_PORT));  
            SourceClose(mic_source_b);
        }

        /* disconnect the in and out sco ports */
        StreamDisconnect(CVC->audio_source,StreamKalimbaSink(CVC_SCO_PORT)); /* SCO->DSP */  
        StreamDisconnect( StreamKalimbaSource(CVC_SCO_PORT), CVC->audio_sink ); /* DSP->SCO */
        
        PRINT(("CVC: Disconnected\n"));
    }
    
    CVC->cvc_running = FALSE;    
    CVC->audio_sink = NULL;
    CVC->link_type = 0;
    
    /* Cancel any outstanding cvc messages */
    MessageCancelAll( (TaskData*)task , MESSAGE_FROM_KALIMBA);
    MessageCancelAll( (TaskData*)task , MESSAGE_STREAM_DISCONNECT);
    MessageCancelAll( CVC->app_task , CSR_SR_WORD_RESP_UNKNOWN);
    MessageCancelAll( CVC->app_task , CSR_SR_WORD_RESP_YES);
    MessageCancelAll( CVC->app_task , CSR_SR_WORD_RESP_NO);
    MessageCancelAll( CVC->app_task , CSR_SR_WORD_RESP_FAILED_YES);
    MessageCancelAll( CVC->app_task , CSR_SR_WORD_RESP_FAILED_NO);
    
    /* Turn off Digital Mic PIO */
    AudioPluginSetMicPio(CVC->digital->mic_a, FALSE);
    if(task->two_mic) 
        AudioPluginSetMicPio(CVC->digital->mic_b, FALSE);

    free (CVC);
    CVC = NULL;
    
    KalimbaPowerOff();
    
    /* update current dsp status */
    SetCurrentDspStatus( DSP_NOT_LOADED );
    /* update the current audio state */
    SetAudioInUse(FALSE);
    SetAsrPlaying(FALSE);
}

/****************************************************************************
NAME    
    CsrCvcPluginSetVolume

DESCRIPTION
    Tell CVC to update the volume.

RETURNS
    void
*/
void CsrCvcPluginSetVolume( CvcPluginTaskdata *task, uint16 volume )
{
    PanicNull(CVC);
    
    /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
    if (volume > 0xf)
        volume = 0xf;

    CVC->volume = volume;
    
    if (CVC->no_dsp)
    {
        PRINT(("CVC: NO DSP: Set volume\n"));
        /*Set the output Gain immediately*/
        CodecSetOutputGainNow( CVC->codec_task, CVC->volume , left_and_right_ch );
        return;
    }
              
    PRINT(("CVC: DAC GAIN SET[%x]\n", CVC->volume ));
    
    /* Only update the volume if not in a mute mode */
    if ( CVC->cvc_running && !( (CVC->mode==AUDIO_MODE_MUTE_SPEAKER ) || (CVC->mode==AUDIO_MODE_MUTE_BOTH ) ) )
    { 
        KalimbaSendMessage(CVC_VOLUME_MSG, 0, 0, CVC->volume, CVC->tone_volume); 
    }
}

/****************************************************************************
NAME    
    CsrCvcPluginResetVolume

DESCRIPTION
    reset the volume back to stored values 

RETURNS
    void
*/
void CsrCvcPluginResetVolume( void )
{
    /* Only update the volume if not in a mute mode */
    if ( CVC && CVC->cvc_running && !( (CVC->mode==AUDIO_MODE_MUTE_SPEAKER ) || (CVC->mode==AUDIO_MODE_MUTE_BOTH ) ) )
    { 
        KalimbaSendMessage(CVC_VOLUME_MSG, 0, 0, CVC->volume, CVC->tone_volume); 
    }    
}

/****************************************************************************
NAME
    CsrCvcPluginSetModeNoDsp

DESCRIPTION
    Set the CSR_COMMON_NO_DSP mode

RETURNS
    void
*/
void CsrCvcPluginSetModeNoDsp ( AUDIO_MODE_T mode )
{
    PRINT(("CsrCvcPluginSetModeNoDsp mode = %d\n",mode));

    switch (mode)
    {
        case AUDIO_MODE_MUTE_SPEAKER :
        {
            PRINT(("CVC: NODSP: Set Mode MUTE SPEAKER\n"));
            DisconnectSpeakerNoDsp(FALSE);
        }
        break ;
        case AUDIO_MODE_CONNECTED :
        {
            PRINT(("CVC: NODSP: Set Mode CONNECTED\n"));
            ConnectMicNoDsp();
            ConnectSpeakerNoDsp();            
        }
        break ;
        case AUDIO_MODE_MUTE_MIC :
        {
            PRINT(("CVC: NODSP: Set Mode MUTE MIC\n"));
            DisconnectMicNoDsp() ;
        }
        break ;
        case AUDIO_MODE_MUTE_BOTH :
        {
            PRINT(("CVC: NODSP: Set Mode MUTE BOTH\n"));
            DisconnectMicNoDsp() ;
            DisconnectSpeakerNoDsp(FALSE) ;
        }
        break ;
        default :
        {    
            PRINT(("CVC: NODSP: Set Mode Invalid [0x%x]\n" , mode )) ;
        }
        break ;
    }
}


/****************************************************************************
NAME    
    CsrCvcPluginSetMode

DESCRIPTION
    Set the CVC mode

RETURNS
    void
*/
void CsrCvcPluginSetMode ( CvcPluginTaskdata *task, AUDIO_MODE_T mode , const void * params )
{
    /* pre-initialise with the most common parameters and adjust below as necessary */
    uint16 sysmode;
    uint16 call_state = CALLST_CONNECTED;
    uint16 volume;
    
    PRINT(("CsrCvcPluginSetMode mode = %d\n",mode));
    
    /* ensure CVC is valid and this is not a stale message left in the queue at disconnect */
    if(CVC)
    {
    
/* when using aptx dsp app with wbs back channel check for external mic support */    
#ifdef REMOVABLE_MIC 
        if (params)
        {
            /* if mode parameters supplied then use these */
            CVCPluginModeParams * mode_params = (CVCPluginModeParams *)params;
            
            /* external microphone connected */
            if(mode_params->external_mic_settings == EXTERNAL_MIC_FITTED)
            {
                /* choose pskey base address according to NB or WB dsp app */
                switch(task->cvc_plugin_variant)
                {
                    case CVSD_CVC_1_MIC_HEADSET:
                        PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_EXT_MIC_FITTED,CVC_SR_NB));
                        KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_EXT_MIC_FITTED, CVC_SR_NB, 0, 0);
                    break;
                     
                    case WBS_CVC_1_MIC_HEADSET:
                        PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_WBS_EXT_MIC_FITTED,CVC_SR_WB));
                        KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_WBS_EXT_MIC_FITTED, CVC_SR_WB, 0, 0);
                    break;
                }
            } 
            /* external microphone not connected */
            else
            {
                /* choose pskey base address according to NB or WB dsp app */
                switch(task->cvc_plugin_variant)
                {
                    case CVSD_CVC_1_MIC_HEADSET:
                        PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED,CVC_SR_NB));
                        KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED, CVC_SR_NB, 0, 0);
                    break;
                 
                    case WBS_CVC_1_MIC_HEADSET:
                        PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_WBS_EXT_MIC_NOT_FITTED,CVC_SR_WB));
                        KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_WBS_EXT_MIC_NOT_FITTED, CVC_SR_WB, 0, 0);
                    break;
                }
            }
        }            
#endif    
            
        /* Store current mode */
        CVC->mode = mode;
    
        /* check if in no dsp mode */
        if (CVC->no_dsp)
        {
            CsrCvcPluginSetModeNoDsp(mode) ;
            return;
        }

        PanicFalse(CVC->cvc_running);
        
        volume  = CVC->volume;
        sysmode = (CVC->ext_params == CSR_CVC_HFK_ENABLE) ? SYSMODE_HFK : SYSMODE_PSTHRGH;
    
        /* if using ASR feature, start it running */
        if((task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
           (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
        {
            PRINT(("CVC: SETMODE ASR: vol=%d\n", volume));

            /*send update to kalimba */ 
            KalimbaSendMessage(CVC_SETMODE_MSG, SYSMODE_ASR, 0, CALLST_CONNECTED, ( CVC->digital->mic_a.digital << 1 ) | CVC->digital->mic_b.digital );
            KalimbaSendMessage(CVC_VOLUME_MSG, 0, 0, volume, CVC->tone_volume);
        }
        /* for all modes excluding ASR mode */
        else
        {              
            switch (CVC->mode)
            {
                case AUDIO_MODE_MUTE_SPEAKER:
                {
                /* If HFK turn off the speaker block */
                    if(sysmode == SYSMODE_HFK) sysmode = SYSMODE_ASR;
                    /*call_state = CALLST_CONNECTED;*/
                    volume = DAC_MUTE;
                }
                break ;
                case AUDIO_MODE_CONNECTED:
                {
                    /*sysmode = (cvc_params == CSR_CVC_HFK_ENABLE) ? SYSMODE_HFK : SYSMODE_PSTHRGH;*/
                    /*call_state = CALLST_CONNECTED;*/    
                    /*volume = CVC->volume;*/
                }
                break ;
                case AUDIO_MODE_MUTE_MIC:
                {
                    /*sysmode = (cvc_params == CSR_CVC_HFK_ENABLE) ? SYSMODE_HFK : SYSMODE_PSTHRGH;*/
                    call_state = CALLST_MUTE;
                    /*volume = CVC->volume;*/
                }
                break ;
                case AUDIO_MODE_MUTE_BOTH:
                {
                    /* Always standby */
                    sysmode = SYSMODE_STANDBY;
                    call_state = 0;
                    volume = DAC_MUTE;
                }
                break;
                default:
                {
                /*do not send a message*/
                    PRINT(("CVC: Set Mode Invalid [0x%x]\n" , mode ));
                    return;
                }
            }
        
            /*send update to kalimba */
            PRINT(("CVC: SYSMODE 0x%x, CALLSTATE 0x%x, VOL 0x%x\n", sysmode, call_state, volume));
            KalimbaSendMessage(CVC_SETMODE_MSG, sysmode, 0, call_state, ( CVC->digital->mic_a.digital << 1 ) | CVC->digital->mic_b.digital );
            KalimbaSendMessage(CVC_VOLUME_MSG, 0, 0, volume, CVC->tone_volume);
        }                
    }
}

/****************************************************************************
NAME    
    CsrCvcPluginPlayTone

DESCRIPTION

    queues the tone if can_queue is TRUE and there is already a tone playing

RETURNS
    false if a tone is already playing
    
*/
void CsrCvcPluginPlayTone (CvcPluginTaskdata *task, ringtone_note * tone , uint16 tone_volume, bool stereo)  
{   
    Source lSource ;  
    Sink lSink ; 
        
    PanicNull(CVC);

    PRINT(("CVC: Tone Start\n"));
    
    if (CVC->no_dsp)
    {
        CVC->tone_stereo = stereo;
        
        if ( CVC->audio_sink )
        {
            DisconnectSpeakerNoDsp(FALSE) ;
        }    
        
        lSink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A);
        
        PanicFalse(SinkConfigure(lSink, STREAM_CODEC_OUTPUT_RATE, 8000));    
    }
    else
    {    
        /*check cvc running */
        PanicFalse(CVC->cvc_running);
    
        /* when mixing tones with ASR, mute the microphone as currently no echo removal */
        if((task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
           (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
        {   
           /* set gain to 0 */ 
           T_mic_gain input_gain;
           memset(&input_gain,0,sizeof(T_mic_gain));
           
           PRINT(("CVC: Mute Mic for tone play with ASR\n"));

           /* Set input gain(s) */
           CvcMicSetGain(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital, input_gain);
           if( task->two_mic ) 
               CvcMicSetGain(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital, input_gain);
        }       
        
        /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
        if (tone_volume > 0xf)
            tone_volume = 0xf;
            
        /* Configure prompt playback, indicate that all firmware tones are mono*/    
        KalimbaSendMessage(MESSAGE_SET_TONE_RATE_MESSAGE_ID, 8000 , 0/*Mono Bit 0 =0, TONE BIT 1 = 0*/, 0, 0);             

        /* set DAC gain to a suitable level for tone play */
        if (tone_volume != CVC->tone_volume)
        {
          CVC->tone_volume = tone_volume;
          KalimbaSendMessage(CVC_VOLUME_MSG, 0, 0, CVC->volume, CVC->tone_volume); 
        }

        lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
    }
    
    /*request an indication that the tone has completed / been disconnected*/
    MessageSinkTask ( lSink , (TaskData*) task );

    /*connect the tone*/
    lSource = StreamRingtoneSource( (const ringtone_note *) (tone) );    
 
    /* connect the tone (mix the tone if this is CVC) */    
    PanicFalse( StreamConnectAndDispose( lSource , lSink ) );
    
    if (CVC->no_dsp)
    {
        /* use the tone volume if present */
        CodecSetOutputGainNow( CVC->codec_task, tone_volume ? tone_volume : CVC->volume, left_and_right_ch );
    }
}

/****************************************************************************
NAME    
    CsrCvcPluginStopTone

DESCRIPTION
    Stop a tone from playing

RETURNS
    whether or not the tone was stopped successfully
*/
void CsrCvcPluginStopTone ( CvcPluginTaskdata *task ) 
{
    PRINT(("CVC: Stop Tone\n"));
    PanicNull(CVC);
        
    if (CVC->no_dsp)
    {
        DisconnectSpeakerNoDsp(TRUE) ;
        CsrCvcPluginSetModeNoDsp(CVC->mode);
    }    
    else
    {
        StreamDisconnect( 0 , StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) ) ; 

        /* when mixing tones with ASR, restore mic volume settins once tone is complete */
        if((task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
           (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
        {        
            /* restore microphone gain */
            CsrCvcPluginResetVolume();
        }       

    }
    /* update current tone playing status */
    SetTonePlaying(FALSE);

}

/****************************************************************************
DESCRIPTION
    Set mic gain
*/
static void CvcMicSetGain(audio_channel channel, bool digital, T_mic_gain gain)
{
    Source mic_source = AudioPluginGetMic(channel, digital);
    uint8 mic_gain = (digital ? gain.digital_gain : gain.analogue_gain);
    AudioPluginSetMicGain(mic_source, digital, mic_gain, gain.preamp_enable);
}

/****************************************************************************
DESCRIPTION
    Configure Speaker channel
*/
static Sink CvcSpkrSetup(audio_channel channel, uint32 dac_rate)
{
    Sink spkr_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, channel);
    PanicFalse(SinkConfigure(spkr_sink, STREAM_CODEC_OUTPUT_RATE,  dac_rate));
    return spkr_sink;
}

/****************************************************************************
DESCRIPTION
    Connect the audio stream (Speaker and Microphone)
*/
static void CvcConnectAudio (CvcPluginTaskdata *task)
{
    uint32 sample_rate;
   
    if ((CVC->audio_sink)||(task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
        (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
    {
        uint16 kal_port_a = CVC_LEFT_PORT;
        uint16 kal_port_b = CVC_RIGHT_PORT;
        Source mic_source_a = NULL;
        Source mic_source_b = NULL;
        Sink   spkr_sink_a  = NULL;
        Sink   spkr_sink_b  = NULL;
           
        /* Use plugin default encoder or overwrite if link type is USB */
        LINK_ENCODING_TYPE_T encoder = (CVC->link_type == AUDIO_SINK_USB) ? LINK_ENCODING_USB : task->encoder;
    
        /* Set DAC/ADC rate */
        uint32  dacrate = CVC->dac_rate;
        uint32  adcrate = dacrate;

        /* bandwidth extension variants require different adc rate to output sample rate */
        if((task->cvc_plugin_variant==CVSD_CVC_2_MIC_HEADSET_BEX)||(task->cvc_plugin_variant==CVSD_CVC_2_MIC_HANDSFREE_BEX))
            adcrate = 8000;
        
        /* update the current audio state */
        SetAudioInUse(TRUE);

        PRINT(("CVC: Use i2s input? %x\n",CVC->features.audio_input_routing == AUDIO_ROUTE_I2S));
        switch(CVC->features.audio_input_routing)
        {
			case AUDIO_ROUTE_INTERNAL:
				/* Configure mic A */
				mic_source_a = AudioPluginGetMic(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital);

				/* match input and output rates when using resampling */
				if((CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)&&(CsrI2SVoiceResamplingFrequency()))
					AudioPluginSetMicRate(mic_source_a, CVC->digital->mic_a.digital, CsrI2SVoiceResamplingFrequency());
				else
					AudioPluginSetMicRate(mic_source_a, CVC->digital->mic_a.digital, adcrate);

				/* configure mic B if applicable for 2 mic operation */
				if( task->two_mic )
				{
					PRINT(("CVC: Connect PCM source 2\n"));
					/* Configure mic B */
					mic_source_b = AudioPluginGetMic(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital);
					/* match input and output rates when using resampling */
					if((CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)&&(CsrI2SVoiceResamplingFrequency()))
						AudioPluginSetMicRate(mic_source_b, CVC->digital->mic_b.digital, CsrI2SVoiceResamplingFrequency());
					else
						AudioPluginSetMicRate(mic_source_b, CVC->digital->mic_b.digital, adcrate);
					/* synchronise both mics A and B */
					SourceSynchronise(mic_source_a, mic_source_b);
                    /* Connect mic A to DSP ports */
                    PanicFalse(StreamConnect(mic_source_a, StreamKalimbaSink(kal_port_a)));
                    /* if 2 mic enabled then connect Mic B */
                    if(task->two_mic)
                    {
                        /* Connect mic/speaker B to DSP ports */
                        PanicFalse(StreamConnect(mic_source_b, StreamKalimbaSink(kal_port_b)));
                    }
				}
                /* 1 mic, connect left mic only */
                else
                {   
                    /* Connect mic A to DSP ports, no DSP case is connected in ConnectMicNoDsp */
                    if(!CVC->no_dsp)
                    {                        
                        PanicFalse(StreamConnect(mic_source_a, StreamKalimbaSink(kal_port_a)));     
                    }          
                }
                break;
            case AUDIO_ROUTE_I2S:
				if( task->two_mic )
                    CsrI2SAudioInputConnect(CsrI2SVoiceResamplingFrequency(), TRUE, StreamKalimbaSink(0), StreamKalimbaSink(2) );
                else
                    CsrI2SAudioInputConnect(CsrI2SVoiceResamplingFrequency(), FALSE, StreamKalimbaSink(0), NULL );
                break;
            case AUDIO_ROUTE_SPDIF:
            case AUDIO_ROUTE_INTERNAL_AND_RELAY:
                {   /* Not currently supported */
                }
                break;
        }
        PRINT(("CVC: Use i2s output? %x\n",CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S));

        /* check whether SCO is present */
        if(CVC->audio_sink)
        {
            /* determine output tye */
            switch(CVC->features.audio_output_type)
            {                       
                /* when using the i2s output in conjunction with external hardware */
                case OUTPUT_INTERFACE_TYPE_I2S:
                {
                    PRINT(("CVC: Using i2s output, sample rate is %d\n",(uint16)CVC->dac_rate));
                    
                    /* when not using the dsp */
                    if(CVC->no_dsp)
                    {             
                        /* Set the mode */            
                        CsrCvcPluginSetModeNoDsp(CVC->mode);
                        CsrI2SAudioOutputSetVolume(CVC->features.stereo, CVC->volume, CVC->volume, FALSE);
                        return;
                    }
                    /* dsp CVC use */
                    else              
                    {
                        /* connect I2S output to dsp */
                        /* is a specified output frequency required? */
                        if(CsrI2SVoiceResamplingFrequency())
                            sample_rate = CsrI2SVoiceResamplingFrequency();
                        else
                            sample_rate = CVC->dac_rate;
                        /* two mic only supports stereo via i2s */
                        CsrI2SAudioOutputConnect(sample_rate, CVC->features.stereo, StreamKalimbaSource(CVC_LEFT_PORT), StreamKalimbaSource(CVC_RIGHT_PORT));
                    }
                }
                break;
                      
                /* using the spdif digital output hardware */
                case OUTPUT_INTERFACE_TYPE_SPDIF:
                {
                    /* must be stereo for spdif output */
                    spkr_sink_a = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
                    spkr_sink_b = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
                    /* configure channel to required rate */
                    PanicFalse(SinkConfigure(spkr_sink_a,  STREAM_SPDIF_OUTPUT_RATE, CVC->dac_rate));
                    PanicFalse(SinkConfigure(spkr_sink_b,  STREAM_SPDIF_OUTPUT_RATE, CVC->dac_rate));
                    /* synchronise both sinks for channels A & B */
                    PanicFalse(SinkSynchronise(spkr_sink_a, spkr_sink_b));
                    /* connect dsp ports */
                    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_LEFT_PORT),spkr_sink_a));
                    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_RIGHT_PORT),spkr_sink_b));
    
                    /* when not using the dsp just connect to spdif hardware */                    
                    if (CVC->no_dsp)
                    {
                        /* Set the mode */
                        CsrCvcPluginSetModeNoDsp(CVC->mode);
                        return;
                    }

                    PRINT(("DECODER: OUTPUT_INTERFACE_TYPE_SPDIF\n"));
                }
                break;

                /* using DAC hardware */
                default:
                {
                    /* Set DAC gain to minimum value before connecting streams */
                    CodecSetOutputGainNow( CVC->codec_task, 0 , left_and_right_ch );
                
                    /* if in no dsp mode then jump straight to set mode that will plug in the ports */
                    if (CVC->no_dsp)
                    {
                        /* Configure spkr A and B if stereo and not 2mic, otherwise just A */
                        spkr_sink_a = CvcSpkrSetup((CVC->features.stereo && !task->two_mic) ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A, dacrate);
                        /* Set the mode */
                        CsrCvcPluginSetModeNoDsp(CVC->mode);
                        CodecSetOutputGainNow( CVC->codec_task, CVC->volume, left_and_right_ch );
                        return;
                    }
                    else
                    {
                        /* Configure spkr A  */
                        spkr_sink_a = CvcSpkrSetup(AUDIO_CHANNEL_A, dacrate);
                        /* Configure spkr B if in stereo mode */
                        if(CVC->features.stereo)
                        {
                            spkr_sink_b = CvcSpkrSetup(AUDIO_CHANNEL_B, dacrate);
                            SinkSynchronise(spkr_sink_a,spkr_sink_b);
                        }
                    }
               
                    /* Connect speaker A to DSP ports */
                    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_LEFT_PORT), spkr_sink_a));
    
                    /* when operating in stereo mode connect the second audio channel */
                    if(CVC->features.stereo)
                    {
                        PanicFalse(StreamConnect(StreamKalimbaSource(CVC_RIGHT_PORT), spkr_sink_b));
                    }
                }
                break;
            }
        /* audio sink valid? */
        }    
        /* no audio sink, check for ASR use */
        else if((task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
                (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
        {     
            /* deteremine output type */
            switch(CVC->features.audio_output_type)
            {
                /* when using the i2s output in conjunction with external hardware */
                case OUTPUT_INTERFACE_TYPE_I2S:
                {
                    /* connect I2S output to dsp */
                    /* is a specified output frequency required? */
                    if(CsrI2SVoiceResamplingFrequency())
                        sample_rate = CsrI2SVoiceResamplingFrequency();
                    else
                        sample_rate = CVC->dac_rate;
                    /* two mic only supports stereo via i2s */
                    CsrI2SAudioOutputConnect(sample_rate, CVC->features.stereo, StreamKalimbaSource(CVC_LEFT_PORT), StreamKalimbaSource(CVC_RIGHT_PORT));  
                }
                break;
                
                /* when using spdif output */
                case OUTPUT_INTERFACE_TYPE_SPDIF:
                {
                    /* must be stereo for spdif output */
                    spkr_sink_a = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_A);
                    spkr_sink_b = StreamAudioSink(AUDIO_HARDWARE_SPDIF, AUDIO_INSTANCE_0, SPDIF_CHANNEL_B);
                    /* configure channel to required rate */
                    PanicFalse(SinkConfigure(spkr_sink_a,  STREAM_SPDIF_OUTPUT_RATE, CVC->dac_rate));
                    PanicFalse(SinkConfigure(spkr_sink_b,  STREAM_SPDIF_OUTPUT_RATE, CVC->dac_rate));
                    /* synchronise both sinks for channels A & B */
                    PanicFalse(SinkSynchronise(spkr_sink_a, spkr_sink_b));
                    /* connect dsp ports */
                    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_LEFT_PORT),spkr_sink_a));
                    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_RIGHT_PORT),spkr_sink_b));
                }
                break;

                /* when using DAC output */
                default:
                {
                    /* Set DAC gain to minimum value before connecting streams */
                    CodecSetOutputGainNow( CVC->codec_task, 0 , left_and_right_ch );
                    /* Configure spkr A  */
                    spkr_sink_a = CvcSpkrSetup(AUDIO_CHANNEL_A, dacrate);
                    /* Configure spkr B */
                    if(CVC->features.stereo)
                    {
                        spkr_sink_b = CvcSpkrSetup(AUDIO_CHANNEL_B, dacrate);
                        SinkSynchronise(spkr_sink_a,spkr_sink_b);
                    }
                    /* Connect mic/speaker A to DSP ports */
                    PanicFalse(StreamConnect(StreamKalimbaSource(CVC_LEFT_PORT), spkr_sink_a));
                    /* if operating as stereo connect the second port */
                    if(CVC->features.stereo)
                    {
                        PanicFalse(StreamConnect(StreamKalimbaSource(CVC_RIGHT_PORT), spkr_sink_b));
                    }
                }
            }
        }
        
        /* Flag DSP is up and running */
        CVC->ports_connected = TRUE;
        CVC->cvc_running = TRUE ;

        PRINT(("CVC: AUDIO_CONFIG_MSG 0x%x config 0x%x %s\n", encoder, task->sco_config, task->adc_dac_16kHz ? "16kHz" : "8kHz"));
        KalimbaSendMessage(CVC_AUDIO_CONFIG_MSG, encoder, task->sco_config , task->adc_dac_16kHz ? 128 : 64, 0);
        
        /* check whether SCO is present */
        if(CVC->audio_sink)
        {
            /* connect sco in/out to dsp ports */
            StreamConnect(CVC->audio_source,StreamKalimbaSink(CVC_SCO_PORT)); /* SCO->DSP */  
            StreamConnect( StreamKalimbaSource(CVC_SCO_PORT), CVC->audio_sink ); /* DSP->SCO */
        }
    
        /* The DSP must know the sampling rate for the ADC and DAC  (rate value sent = actual rate/10) */
        if((CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)&&(CsrI2SVoiceResamplingFrequency()))
        {           
            PRINT(("CVC: SET_SAMPLE_RATE rate[%d] rate_match[%x] interface[%x]\n",CsrI2SVoiceResamplingFrequency()/10, SW_RATE_MATCH_ENABLE_MASK, CVC_INTERFACE_I2S));
            /* apply software resampling */
            if(!KalimbaSendMessage(MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID, CsrI2SVoiceResamplingFrequency()/10, SW_RATE_MATCH_ENABLE_MASK, CVC_INTERFACE_I2S, 0))
            {
                PRINT(("CVC: Message MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID failed!\n"));
                Panic(); 
            }
        }
        /* not using the resampling ability of CVC */
        else
        {
            /* I2S output uses software rate matching */
            if(CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
            {
                PRINT(("CVC: SET_SAMPLE_RATE rate[%ld] rate_match[%x] interface[%x]\n",dacrate/10, SW_RATE_MATCH_ENABLE_MASK, CVC_INTERFACE_I2S));
                if(!KalimbaSendMessage(MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID, dacrate/10, SW_RATE_MATCH_ENABLE_MASK, CVC_INTERFACE_I2S, 0))
                {
                    PRINT(("CVC: Message MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID failed!\n"));
                    Panic();
                }
            }
            /* hardware rate matching available on internal codec */
            else
            {   
                PRINT(("CVC: SET_SAMPLE_RATE rate[%ld] rate_match[%x] interface[%x]\n",dacrate/10, HW_RATE_MATCH_ENABLE_MASK, CVC_INTERFACE_ANALOG));
                if(!KalimbaSendMessage(MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID, dacrate/10, HW_RATE_MATCH_ENABLE_MASK, CVC_INTERFACE_ANALOG, 0))
                {
                    PRINT(("CVC: Message MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID failed!\n"));
                    Panic();
                }
            }
        }
        
        /* Set the mode */
        CsrCvcPluginSetMode ( task, CVC->mode , NULL );
        
        /* if using ASR feature, start it running */
        if((task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
           (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
        {
            KalimbaSendMessage(ASR_START,0,0,0,0);
            PRINT(("ASR running msg %x busy [%x]\n",ASR_START,(uint16)IsAudioBusy()));
            /* update the current audio state */
            SetAsrPlaying(TRUE);
        }
    }
    else
    {   
        CVC->cvc_running = TRUE ;
        /*Power Down*/
        CsrCvcPluginDisconnect(task);
    }
}

/****************************************************************************
DESCRIPTION
    Handles a CVC_CODEC message received from CVC
*/
static void CvcCodecMessage (CvcPluginTaskdata *task, T_mic_gain input_gain_l, T_mic_gain input_gain_r, uint16 output_gain )
{   
    PRINT(("CVC: Output gain = 0x%x\n" , output_gain ));
    PRINT(("CVC: Input gain L:R = 0x%x : 0x%x \n", *(uint16*)&input_gain_l,*(uint16*)&input_gain_r));

    /* check pointer validity as there is a very small window where a message arrives
       as the result of playing a tone after CVC has been powered down */
    if(CVC)
    {
        /* set output volume level */
        if(CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
        {
            CsrI2SAudioOutputSetVolume(CVC->features.stereo, output_gain, output_gain, FALSE);
        }
        else
        {
            /*Set the output Gain immediately*/
            CodecSetOutputGainNow( CVC->codec_task, output_gain, left_and_right_ch);
        }
    
        /* Set input gain(s) */
        CvcMicSetGain(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital, input_gain_l);
        if( task->two_mic ) 
            CvcMicSetGain(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital, input_gain_r);
    }
}


/****************************************************************************
DESCRIPTION
    handles the internal cvc messages /  messages from the dsp
*/
void CsrCvcPluginInternalMessage( CvcPluginTaskdata *task ,uint16 id , Message message ) 
{
    switch(id)
    {
        case MESSAGE_FROM_KALIMBA:
        {
            const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
            PRINT(("CVC: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));
        
            switch ( m->id ) 
            {
#ifdef CVC_MULTI_KAP
                case CVC_CORE_READY:
                    PRINT(("CVC: Core Loaded, Load App [0x%X]\n", CVC->app_index));
                    KalimbaSendMessage(CVC_LOAD_INDEX, CVC->app_index, 0, 0, 0);
                break;
#endif
                case CVC_READY_MSG:
                {
                    /* determine PSKEY base address for tuning parameters, CVC 1 mic and SSR use a
                       different base address to allow coexistance with CVC 2 mic */
                    switch(task->cvc_plugin_variant)
                    {
#ifndef REMOVABLE_MIC
                        case CVSD_CVC_1_MIC_HEADSET:
                        case WBS_CVC_1_MIC_HEADSET:
                            if(CVC->dac_rate == 8000)
                            {
                                PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE,CVC_SR_NB));
                                KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE, CVC_SR_NB, 0, 0);
                            }
                            else if (CVC->dac_rate == 16000)
                            {
                                PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_WBS,CVC_SR_WB));
                                KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_WBS, CVC_SR_WB, 0, 0);
                            }
                            else
                            {
                                PRINT(("CVC: Unknown dac_rate.\n"));
                                Panic();
                            }
                        break;
#else
                        case CVSD_CVC_1_MIC_HEADSET:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED,CVC_SR_NB));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED, CVC_SR_NB, 0, 0);
                        break;
                 
                        case WBS_CVC_1_MIC_HEADSET:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_WBS_EXT_MIC_NOT_FITTED,CVC_SR_WB));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_WBS_EXT_MIC_NOT_FITTED, CVC_SR_WB, 0, 0);                    
                        break;
#endif
                        case CVSD_CVC_1_MIC_HEADSET_BEX:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE,CVC_SR_BEX));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE, CVC_SR_BEX, 0, 0);
                        break;
                        
                        case CVSD_CVC_2_MIC_HEADSET_BEX:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_2MIC_PS_BASE,CVC_SR_BEX));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_2MIC_PS_BASE, CVC_SR_BEX, 0, 0);
                        break;

                        case CVSD_CVC_1_MIC_HANDSFREE_BEX:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_2MIC_PS_BASE,CVC_SR_BEX));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_2MIC_PS_BASE, CVC_SR_BEX, 0, 0);
                        break;

                        case CVSD_CVC_2_MIC_HANDSFREE_BEX:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_2MIC_PS_BASE,CVC_SR_BEX));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_2MIC_PS_BASE, CVC_SR_BEX, 0, 0);
                        break;
        
                        /* ASR is a separate operating mode of CVC */
                        case CVSD_CVC_1_MIC_HEADSET_ASR:
                            PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED,CVC_SR_NB));
                            KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED, CVC_SR_NB, 0, 0);
                            /* configure CVC for use as ASR using CVC 1-mic NB*/
                            CvcConfigureASR(task);                        
                        break;
                        
                        case CVSD_CVC_2_MIC_HEADSET_ASR:
                                PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_2MIC_PS_BASE,CVC_SR_NB));
                                KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_2MIC_PS_BASE, CVC_SR_NB, 0, 0);
                            /* configure CVC for use as ASR using CVC 2-mic NB*/
                            CvcConfigureASR(task);                        
                        break;

                        /* handsfree and cvc 2-mic versions */
                        default:
                           if(CVC->dac_rate == 8000)
                           {
                                PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_2MIC_PS_BASE,CVC_SR_NB));
                                KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_2MIC_PS_BASE, CVC_SR_NB, 0, 0);
                           }
                           else if (CVC->dac_rate == 16000)
                           {
                               PRINT(("CVC: CVC_LOADPARAMS_MSG pskey[%x] mode[%x]\n",CVC_2MIC_PS_BASE_WBS,CVC_SR_WB));
                               KalimbaSendMessage(CVC_LOADPARAMS_MSG, CVC_2MIC_PS_BASE_WBS, CVC_SR_WB, 0, 0);
                           }
                           else
                           {
                               PRINT(("CVC: Unknown dac_rate.\n"));
                               Panic();
                           }
                        break;
                    }
                                       
                    SetCurrentDspStatus(DSP_LOADED_IDLE);

                    PRINT(("CVC: CVC_READY, SysId[%x] BuildVersion[%x] \n",m->a, m->b));
                    
                    CvcConnectAudio (task);
                }
                break;
            
                case CVC_CODEC_MSG:
                {
                    uint16 lOutput_gain;
                    T_mic_gain lInput_gain_l;
                    T_mic_gain lInput_gain_r;
                  
                    lOutput_gain = m->a;
                    lInput_gain_l = *(T_mic_gain*)&m->b;
                    lInput_gain_r = *(T_mic_gain*)&m->c;

                    CvcCodecMessage (task, lInput_gain_l,lInput_gain_r, lOutput_gain );    

                    SetCurrentDspStatus(DSP_RUNNING);

                 }
                break;
            
                case CVC_LOADPERSIST_MSG:
                {
                    /* a=sysid, b=len */
                    const pblock_entry* entry = PblockGet(m->a);
                    KalimbaSendLongMessage(CVC_LOADPERSIST_RESP, entry->size, entry->data);
                }
                break;

                case CVC_SECPASSED_MSG:
                PRINT(("CVC:  Sec passed.\n"));
                     /*cvc is now loaded, signal that tones etc can be scheduled*/
                    SetAudioBusy(NULL) ;
                break;
 
                case CVC_SECFAILED_MSG:
                PRINT(("CVC: Security has failed.\n"));
                    /*cvc is now loaded, signal that tones etc can be scheduled*/
                    SetAudioBusy(NULL) ;
                break;
               
                case (CSR_SR_WORD_RESP_YES - CSR_SPEECH_RECOGNITION_MESSAGE_BASE):
                {
                    PRINT(("ASR: YES\n")) ;

                    /*Send Message to VM app if VM app has been specified*/
                    if(CVC->app_task)
                        MessageSend ( CVC->app_task , CSR_SR_WORD_RESP_YES, 0 ) ;                
                }
                break;

                case (CSR_SR_WORD_RESP_NO - CSR_SPEECH_RECOGNITION_MESSAGE_BASE):
                {
                    PRINT(("ASR: NO\n")) ;              

                    /*Send Message to VM app if VM app has been specified*/
                    if(CVC->app_task)
                        MessageSend ( CVC->app_task , CSR_SR_WORD_RESP_NO, 0 ) ;                
                }
                break;

                case (CSR_SR_WORD_RESP_FAILED_YES - CSR_SPEECH_RECOGNITION_MESSAGE_BASE):
                {
                    PRINT(("ASR: FAILED YES\n")) ;

                    /*Send Message to VM app if VM app has been specified*/
                    if(CVC->app_task)
                        MessageSend ( CVC->app_task , CSR_SR_WORD_RESP_FAILED_YES, 0 ) ;                
                }
                break;

                case (CSR_SR_WORD_RESP_FAILED_NO - CSR_SPEECH_RECOGNITION_MESSAGE_BASE):
                {
                    PRINT(("ASR: FAILED NO\n")) ;              

                    /*Send Message to VM app if VM app has been specified*/
                    if(CVC->app_task)
                        MessageSend ( CVC->app_task , CSR_SR_WORD_RESP_FAILED_NO, 0 ) ;                
                }
                break;

                case (CSR_SR_WORD_RESP_UNKNOWN - CSR_SPEECH_RECOGNITION_MESSAGE_BASE):
                {
                    PRINT(("ASR: UNKNOWN\n")) ;
                    /*Send Message to VM app if VM app has been specified*/
                    if(CVC->app_task)
                        MessageSend ( CVC->app_task , CSR_SR_WORD_RESP_UNKNOWN, 0 ) ;                                    
                }
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

                default:
                break;
            }
        }
        break;

        case MESSAGE_FROM_KALIMBA_LONG:
        {
            const DSP_LONG_REGISTER_T *m = (const DSP_LONG_REGISTER_T*) message;
/*            PRINT(("CVC: LONG_MESSAGE_FROM_KALIMBA id[0x%x] l[0x%x] \n", m->id, m->size));*/
            switch (m->id)
            {
#ifdef CVC_MULTI_KAP
                case CVC_FILE_NAME:
                {
                    const char* filename = (const char*)m->buf;
                    FILE_INDEX index = FileFind(FILE_ROOT, filename, strlen(filename));
                    PRINT(("CVC: File Request [0x%X] %s\n", index, filename));
                    PanicFalse(index != FILE_NONE);
                    KalimbaSendMessage(CVC_LOAD_INDEX, index, 0, 0, 0);
                }
                break;
#endif
                case CVC_STOREPERSIST_MSG:
                    /* Set the DSP app's pblock */
/*                   PRINT(("CVC: StorePersist key[0x%x], data[0x%x] \n", m->buf[0], m->buf[1]));*/
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
    a tone has completed
*/
void CsrCvcPluginToneComplete( CvcPluginTaskdata *task ) 
{
    PRINT(("CVC: Tone Complete\n"));
    if (CVC->no_dsp)
    {    
        Sink speaker_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC,AUDIO_INSTANCE_0, CVC->tone_stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A);
        MessageSinkTask ( speaker_sink, NULL ) ;
        SinkClose(speaker_sink);
        
        if (( CVC->mode != AUDIO_MODE_MUTE_BOTH )&&
            ( CVC->mode != AUDIO_MODE_MUTE_SPEAKER))
        {
            /* reconnect sco audio if present */
            ConnectSpeakerNoDsp();
            
            /* check to see if the sco is still valid, if it is not then we will have received the
               message before the tone has completed playing due to some other issue, therefore
               allow tone to continue playing for an additional 1.5 seconds to allow the power off
               tone to be played to completion */
            if(SinkIsValid(CVC->audio_sink))
            {
                SetAudioBusy(NULL) ;
                CsrCvcPluginSetVolume(task, CVC->volume );
                PRINT(("CVC: Tone Complete SCO exists\n"));
            }
            else
            {
                MessageSendLater((TaskData*) task, MESSAGE_FORCE_TONE_COMPLETE, 0, 1500);
                PRINT(("CVC: Tone Complete SCO not exists [0x%x]\n", (uint16)CVC->audio_sink));
            }
        }
        else
        {
            SetAudioBusy(NULL) ;
            CsrCvcPluginSetVolume(task, CVC->volume );
        }
    }
    else
    {    /* DSP mode */
        /* Restore the DAC gain to mute if in mute mode */
        if ( CVC->cvc_running && (CVC->mode==AUDIO_MODE_MUTE_SPEAKER || CVC->mode==AUDIO_MODE_MUTE_BOTH ) )
            KalimbaSendMessage(CVC_VOLUME_MSG, 0, 0, DAC_MUTE, CVC->tone_volume);   
       
        /* We no longer want to receive stream indications */
        MessageSinkTask (StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) , NULL);
    }
    /* update current tone playing status */
    SetTonePlaying(FALSE);

}

/****************************************************************************
DESCRIPTION
    Reconnects the audio after a tone has completed in no DSP mode
*/
void CsrCvcPluginToneForceCompleteNoDsp ( CvcPluginTaskdata *task )
{
    PRINT(("CVC: Force Tone Complete No DSP\n"));
    
    if(CVC)
    {
        if(IsAudioBusy())
        {
            SetAudioBusy(NULL);
            
            DisconnectSpeakerNoDsp(TRUE);
            DisconnectMicNoDsp();
        }
        /* ensure volume is set to correct level after playing tone */
        CsrCvcPluginSetVolume(task, CVC->volume );
        /* update current tone playing status */
        SetTonePlaying(FALSE);
    }

}





/****************************************************************************
DESCRIPTION
    Disconnect the microphone path
*/
static void DisconnectMicNoDsp ( void )
{
    Source mic_source = AudioPluginGetMic(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital);
    PRINT(("CVC: NODSP: Disconnect Mic\n")) ;
    StreamDisconnect(mic_source, CVC->audio_sink);
    SourceClose(mic_source);
}

/****************************************************************************
DESCRIPTION
    Disconnect the Speaker path
*/
static void DisconnectSpeakerNoDsp ( bool tone )
{
    Sink speaker_sink;

    /* when using the i2s output in conjunction with external hardware */
    if(CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
    {
        CsrI2SAudioOutputDisconnect(CVC->features.stereo);

        CVC->ports_connected = FALSE;

        PRINT(("CVC: NODSP: Disconnect Speaker tone for I2S output[%d]\n", tone)) ;
    }
    else
    {
        if (tone)
            speaker_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC,AUDIO_INSTANCE_0, CVC->tone_stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A);
        else
            speaker_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC,AUDIO_INSTANCE_0, CVC->features.stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A);
        StreamDisconnect(CVC->audio_source, speaker_sink);
        SinkClose(speaker_sink);

        /* once tone has been disconnected, unassign the sink with the task */
        if(tone)
            MessageSinkTask ( speaker_sink, NULL ) ;

        PRINT(("CVC: NODSP: Disconnect Speaker tone[%d]\n", tone)) ;
    }
    
    
}

/****************************************************************************
DESCRIPTION
    Connect a SCO to the Microphone
*/
static void ConnectMicNoDsp ( void )
{
    /* configure microphone gain and preamp settings */
    Source mic_source = AudioPluginGetMic(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital);
    AudioPluginSetMicGain(mic_source, CVC->digital->mic_a.digital, CVC->digital->mic_a.gain, CVC->digital->mic_a.pre_amp);

    PRINT(("CVC: NODSP: Connect Mic\n")) ;

    if ( CVC->audio_sink )
        StreamConnect(AudioPluginGetMic(AUDIO_CHANNEL_A, CVC->digital->mic_a.digital), CVC->audio_sink );
}

/****************************************************************************
DESCRIPTION
    Connect a SCO to the Speaker
*/
static void ConnectSpeakerNoDsp ( void )
{
    Sink speaker_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, CVC->features.stereo ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A);
    Source audio_source = CVC->audio_source;

    /* when using the i2s output in conjunction with external hardware */
    if(CVC->features.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
    {                  
        PRINT(("CVC: NODSP: I2S: Connect Speaker[0x%x] speaker_sink[0x%x] audio_source[0x%x] stereo[%d]\n" ,(int)CVC->audio_sink, (int)speaker_sink, (int)audio_source, CVC->features.stereo));
        if (!(CVC->ports_connected)&&(CVC->audio_sink ))
        {
            /* connect I2S output to dsp */
            CsrI2SAudioOutputConnect(CVC->dac_rate, CVC->features.stereo, audio_source, NULL);  
            CVC->ports_connected = TRUE;
        }
    }
    /* use internal codec */
    else
    {
        PRINT(("CVC: NODSP: Connect Speaker[0x%x] speaker_sink[0x%x] audio_source[0x%x] stereo[%d]\n" ,(int)CVC->audio_sink, (int)speaker_sink, (int)audio_source, CVC->features.stereo));
        if ( CVC->audio_sink )
            StreamConnect( audio_source, speaker_sink);
    }
}

#ifdef CVC_ALL
/****************************************************************************
DESCRIPTION
    Disconnect the second microphone path
*/
static void DisconnectSecondMicNoDsp ( void )
{
    Source mic_source = AudioPluginGetMic(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital);
    PRINT(("CVC: NODSP: Disconnect Second Mic\n")) ;
    StreamDisconnect(mic_source, CVC->audio_sink);
    SourceClose(mic_source);
}

/****************************************************************************
DESCRIPTION
    Connect a SCO to the second Microphone
*/
static void ConnectSecondMicNoDsp ( void )
{
    /* configure microphone gain and preamp settings */
    Source mic_source = AudioPluginGetMic(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital);
    AudioPluginSetMicGain(mic_source, CVC->digital->mic_b.digital, CVC->digital->mic_b.gain, CVC->digital->mic_b.pre_amp);

    PRINT(("CVC: NODSP: Connect Second Mic\n")) ;
    if ( CVC->audio_sink )
    {
        StreamConnect(AudioPluginGetMic(AUDIO_CHANNEL_B, CVC->digital->mic_b.digital), CVC->audio_sink );        
    }
}
#endif

/****************************************************************************
NAME
    CsrCvcPluginMicSwitch

DESCRIPTION
    Swap between the microphone inputs for production test

RETURNS
    
*/
void CsrCvcPluginMicSwitch ( void )
{
#ifdef CVC_ALL
    PRINT(("CVC: NODSP: MicSwitch [%x]\n" , (int)CVC->audio_sink )) ;
    if ( CVC->audio_sink )
    {
        CodecSetOutputGainNow( CVC->codec_task, 0 , left_and_right_ch );
        
        /* disconnect speaker */
        DisconnectSpeakerNoDsp(FALSE);
        
        if ( CVC->switch_to_mic_b )
        {
            /* disconnect first mic */
            DisconnectMicNoDsp();
            
            /*connect second mic*/
            ConnectSecondMicNoDsp();
            
            /* mic B now in use; switch to mic A next time */
            CVC->switch_to_mic_b = FALSE;
        }
        else {
            /* disconnect second mic */
            DisconnectSecondMicNoDsp();
            
            /*connect first mic*/
            ConnectMicNoDsp();
            
            /* mic A now in use; switch to mic B next time */
            CVC->switch_to_mic_b = TRUE;
        }
        /*connect speaker*/
        ConnectSpeakerNoDsp();
        
        CodecSetOutputGainNow( CVC->codec_task, CVC->volume , left_and_right_ch );
        
    }
#endif    
}

/****************************************************************************
NAME
    CsrCvcPluginSetPower

DESCRIPTION
    Sets the power mode of the plugin

RETURNS
    
*/
void CsrCvcPluginSetPower( CvcPluginTaskdata *task,  AUDIO_POWER_T power)
{
    
    PRINT(("CVC : Set Power [0x%x]\n", power));  
    
    /* If actually using the NO DSP plugin disregard set power requests */
    if(!CVC || task->cvc_plugin_variant == CVSD_NO_DSP)
    {
        PRINT(("CVC : Set Power ignored\n"));
        return;
    }
    
    /*   These are the state transitions possible during an active SCO:
    
    CVC -> (low power) -> DSP Passthrough
    DSP Passthrough -> (normal power) -> CVC
    No DSP -> (normal power) -> CVC
    
    It's not possible to switch CVC or DSP Pass through to No DSP with an active SCO due to Metadata issues */   
    if(!CVC->no_dsp)
    {
        /* Default to normal power */
        CVC->ext_params = CSR_CVC_HFK_ENABLE;
        /* Back to low power unless above threshold */
        if(power <= LPIBM_THRESHOLD)
            CVC->ext_params = CSR_CVC_PSTHRU_ENABLE;
        
        if (IsAudioBusy())
        {
            /* Update mode once busy condition clear */
            MAKE_AUDIO_MESSAGE ( AUDIO_PLUGIN_SET_MODE_MSG) ;
            message->mode   = CVC->mode ;
            message->params = NULL ;
            MessageSendConditionally ( (Task)task, AUDIO_PLUGIN_SET_MODE_MSG , message ,(const uint16 *)AudioBusyPtr() ) ;
        }
        else
        {
            /* Update mode now */
            CsrCvcPluginSetMode((CvcPluginTaskdata*)task, CVC->mode , NULL) ;
        }
    }
}

/****************************************************************************
NAME
    CvcConfigureASR

DESCRIPTION
    configures CVC for use as ASR (speech recognition)

RETURNS
    nothing
*/
void CvcConfigureASR( CvcPluginTaskdata *task)
{
    uint16 ret_len = 0;
    uint16 psdata[4] ;
    
    /* Initialize clip detector */
    PanicFalse(KalimbaSendMessage(KALIMBA_MSG_CBOPS_SILENCE_CLIP_DETECT_INITIALISE_ID,1,0x7fff,1000,1));

    /* Read confidence threshold from from PS if it exists */
    /*needs to be stored somewhere else and not read every time*/
    ret_len = PsRetrieve(60, psdata, 4);

    /* Tell DSP to load Confidence Threshold */
    if(ret_len) 
    {
      PRINT(("Confidence Threshold from PS: len=0x%x, MSB=0x%x, LSB=0x%x, 3rd=0x%x\n\n", ret_len, psdata[0], psdata[1], psdata[2]));
      PanicFalse(KalimbaSendMessage(SET_CONFI_THRESH_MSG, psdata[0], psdata[1], psdata[2], psdata[3]));
    }
}


/****************************************************************************
NAME    
    CsrCvcPluginSetAsr

DESCRIPTION
    Start or restart the ASR engine

RETURNS
    void
*/
void CsrCvcPluginSetAsr ( CvcPluginTaskdata *task, AUDIO_MODE_T mode  )
{
    /* if using ASR feature, start it running */
    if((task->cvc_plugin_variant == CVSD_CVC_1_MIC_HEADSET_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HEADSET_ASR)||
       (task->cvc_plugin_variant == CVSD_CVC_1_MIC_HANDSFREE_ASR)||(task->cvc_plugin_variant == CVSD_CVC_2_MIC_HANDSFREE_ASR))
    {
        KalimbaSendMessage(ASR_START,0,0,0,0);
        PRINT(("ASR START MSG %x busy [%x]\n",ASR_START,(uint16)IsAudioBusy()));
        /* update the current audio state */
        SetAsrPlaying(TRUE);
    }    
}

