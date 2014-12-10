/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
   csr_ag_audio.c
    
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
#include <ps.h>
#include <app/vm/vm_if.h>
#include "audio_plugin_if.h"        /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_ag_audio_if.h"
#include "csr_ag_audio_plugin.h"
#include "csr_ag_audio.h"


/*helper functions*/
static void ConnectAudio (CsrAgAudioPluginTaskData *task,  bool stereo );
static void CodecMessage (CsrAgAudioPluginTaskData *task, T_mic_gain input_gain_l,T_mic_gain input_gain_r, uint16 output_gain ) ;
uint32 CsrCalcDacRate ( CSR_AG_AUDIO_PLUGIN_TYPE_T cvc_plugin_variant, uint32 rate );
static FILE_INDEX CsrSelectKapFile(CSR_AG_AUDIO_PLUGIN_TYPE_T plugin_variant, uint32 dac_rate);


typedef struct audio_Tag
{
   unsigned running:1;
   unsigned reserved:6;
   /*! mono or stereo*/
   unsigned stereo:1;
   /*! The current mode */
   unsigned mode:8;    
   /*! The codec being used*/
   Task codec_task; 
   /*! The audio sink being used*/
   Sink audio_sink;
   /*! The link_type being used*/
   sync_link_type link_type;
   /*! The current volume level*/
   uint16 volume;
   /*! The current tone volume level*/
   uint16 tone_volume;
   /*! Over the air rate  */
   uint32  dac_rate;	
   /*! Left microphone gain */
   T_mic_gain mic_gain_left;
   /*! Right microphone gain */
   T_mic_gain mic_gain_right;
   /*! Microphone configuration */
   const common_mic_params* digital;
   /* USB configuration */
   const CsrAgAudioPluginUsbParams *usb;
   /* Warp value */
   uint16 warp[CSR_AG_AUDIO_WARP_NUMBER_VALUES];
   /* The App Task */
   Task app_task;
} AG_AUDIO_T ;

/* The task instance pointer*/
static AG_AUDIO_T *CSR_AG_AUDIO = NULL;



static FILE_INDEX CsrSelectKapFile(CSR_AG_AUDIO_PLUGIN_TYPE_T plugin_variant, uint32 dac_rate)
{		
   FILE_INDEX index = 0;
   char* kap_file = NULL;
	
   switch(plugin_variant)
   {
      case CSR_AG_AUDIO_CVSD_8K_1_MIC:
         kap_file = "usb_dongle_8k_mono/usb_dongle_8k_mono.kap";		
    	break;
        
      case CSR_AG_AUDIO_CVSD_48K_1_MIC:
         kap_file = "usb_dongle_48_to_8k_stereo/usb_dongle_48_to_8k_stereo.kap";		
    	break;

      case CSR_AG_AUDIO_CVSD_8K_2_MIC:
         kap_file = "two_mic_example_cvsd/two_mic_example_cvsd.kap";
      break;
    	
      case CSR_AG_AUDIO_SBC_16K_1_MIC:         
         kap_file = "usb_dongle_16k_mono/usb_dongle_16k_mono.kap";
      break;
      
      case CSR_AG_AUDIO_SBC_48K_1_MIC:
         kap_file = "usb_dongle_48_to_16k_stereo/usb_dongle_48_to_16k_stereo.kap";
      break;
      
      case CSR_AG_AUDIO_SBC_2_MIC:
         kap_file = "two_mic_example_16k/two_mic_example_16k.kap";
      break;
      
      default:
         PRINT(("CSR_AG_AUDIO: No Corresponding Kap file\n")) ;
         Panic() ;
    	break;
   }

   index = FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file));
    
   if( index == FILE_NONE )
   {
      PRINT(("CSR_AG_AUDIO: No File\n"));
      Panic();
   }
   
   return(index);
}

uint32 CsrCalcDacRate ( CSR_AG_AUDIO_PLUGIN_TYPE_T cvc_plugin_variant, uint32 rate )
{
   uint32 dac_rate = 0 ;
   /* Calculate the DAC rate based on over the air rate value and the type of codec
   It holds true for both 8K and 16K connection and calculates the rate correctly */

   switch ( cvc_plugin_variant ) 
   {
      /* For SBC case, we are currently hard coding the dac_rate to be 16K */
      case CSR_AG_AUDIO_SBC_16K_1_MIC:
      case CSR_AG_AUDIO_SBC_48K_1_MIC:
         dac_rate = 16000;
         
      break;

      case CSR_AG_AUDIO_SBC_2_MIC:
         dac_rate = 16000;
      break;

      default:
         dac_rate = rate * 1;
      break;
   }

   return dac_rate ;
}

/****************************************************************************
NAME	
   CsrAgAudioPluginConnect

DESCRIPTION
   

RETURNS
   void
*/
void CsrAgAudioPluginConnect( CsrAgAudioPluginTaskData *task, Sink audio_sink , AUDIO_SINK_T sink_type, Task codec_task , uint16 volume , uint32 rate , bool stereo , AUDIO_MODE_T mode , const void * params , Task app_task)
{
   FILE_INDEX index;
   typed_bdaddr rem_addr; 
   uint16 i = 0;
   
   CsrAgAudioPluginConnectParams *audio_params = (CsrAgAudioPluginConnectParams *)params;
	
   /*signal that the audio is busy until the kalimba / parameters are fully loaded so that no tone messages etc will arrive*/
   SetAudioBusy((TaskData*) task);    
    
   if (CSR_AG_AUDIO)
      Panic();
   
   CSR_AG_AUDIO = PanicUnlessNew ( AG_AUDIO_T ); 
    
   /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
   if (volume > 0xf)
      volume = 0xf;

   CSR_AG_AUDIO->running         = FALSE;
   CSR_AG_AUDIO->codec_task      = codec_task;                                                        
   CSR_AG_AUDIO->link_type       = (sync_link_type)sink_type ;                                                        
   CSR_AG_AUDIO->volume          = volume;
   CSR_AG_AUDIO->audio_sink      = audio_sink;
   CSR_AG_AUDIO->mode            = mode;
   CSR_AG_AUDIO->stereo          = stereo;
   CSR_AG_AUDIO->tone_volume     = volume;
   CSR_AG_AUDIO->mic_gain_left   = MIC_DEFAULT_GAIN;
   CSR_AG_AUDIO->mic_gain_right  = MIC_DEFAULT_GAIN;
   CSR_AG_AUDIO->digital         = (const common_mic_params *) audio_params->mic;
   CSR_AG_AUDIO->usb             = (const CsrAgAudioPluginUsbParams *) audio_params->usb;
   CSR_AG_AUDIO->app_task        = app_task;
   
   for (i = 0; i < CSR_AG_AUDIO_WARP_NUMBER_VALUES; i++)
   {
       CSR_AG_AUDIO->warp[i]  = audio_params->warp[i];
   }
	
   PRINT(("CSR_AG_AUDIO: connect [%x] [%x]\n", CSR_AG_AUDIO->running , (int)CSR_AG_AUDIO->audio_sink));
   
    if (CSR_AG_AUDIO->digital)
    {
        /* Set mic pin */
        AudioPluginSetMicPio(CSR_AG_AUDIO->digital->mic_a, TRUE);
        if(task->two_mic) 
            AudioPluginSetMicPio(CSR_AG_AUDIO->digital->mic_b, TRUE);
    }

  /* For WBS set SBC Frame size, else sample-based */
    if ((task->plugin_variant == CSR_AG_AUDIO_SBC_16K_1_MIC) || 
        (task->plugin_variant == CSR_AG_AUDIO_SBC_48K_1_MIC) ||
        (task->plugin_variant == CSR_AG_AUDIO_SBC_2_MIC))
    {
       SinkConfigure(CSR_AG_AUDIO->audio_sink, VM_SINK_SCO_SET_FRAME_LENGTH, BYTES_PER_MSBC_FRAME);
    }

   /* Enable MetaData */
   SourceConfigure(StreamSourceFromSink( CSR_AG_AUDIO->audio_sink ),VM_SOURCE_SCO_METADATA_ENABLE,1);

   /* Clear all routing to the PCM subsysytem*/
   /*TODO    PcmClearAllRouting();
   */

   /* Calculate the DAC rate based on the over-the-air rate value passed in from VM */
   CSR_AG_AUDIO->dac_rate = CsrCalcDacRate( (CSR_AG_AUDIO_PLUGIN_TYPE_T)task->plugin_variant, rate );
   
   /*ensure that the messages received are from the correct kap file*/ 
   (void) MessageCancelAll( (TaskData*) task, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( (TaskData*) task );

   /* Select which Kap file to be loaded based on the plugin selected */
   index = CsrSelectKapFile((CSR_AG_AUDIO_PLUGIN_TYPE_T)task->plugin_variant, CSR_AG_AUDIO->dac_rate); 
    
   /* Load the cvc algorithm into Kalimba*/
   if( !KalimbaLoad( index ) )
   {
      PRINT(("Kalimba load fail\n"));
      Panic();
   }
    
   /* get remote address */
   SinkGetBdAddr(CSR_AG_AUDIO->audio_sink, &rem_addr);
   KalimbaSendMessage(MESSAGE_REM_BT_ADDRESS, rem_addr.addr.nap, (rem_addr.addr.lap >> 16) | (((unsigned int)rem_addr.addr.uap) << 8), rem_addr.addr.lap & 0xffff, 0 );
   
   /* Send warp values to DSP */
   KalimbaSendMessage(MESSAGE_SEND_WARP, CSR_AG_AUDIO->warp[0], CSR_AG_AUDIO->warp[1], CSR_AG_AUDIO->warp[2], CSR_AG_AUDIO->warp[3]);
   
   /* Connect audio */
   ConnectAudio (task, CSR_AG_AUDIO->stereo) ;
   SetAudioBusy(NULL);
 }

/****************************************************************************
NAME	
   CsrAgAudioPluginDisconnect

DESCRIPTION
   
     
RETURNS
   void
*/
void CsrAgAudioPluginDisconnect( CsrAgAudioPluginTaskData *task )
{
    Source mic_src_a;
    Source mic_src_b;
    Sink audio_sink;
    
    if (!CSR_AG_AUDIO)
        Panic() ;
    if ( CSR_AG_AUDIO->running == FALSE )
        Panic() ;
   
    if (CSR_AG_AUDIO->digital)
    {
        mic_src_a = AudioPluginGetMic(AUDIO_CHANNEL_A, CSR_AG_AUDIO->digital->mic_a.digital);
        mic_src_b = AudioPluginGetMic(AUDIO_CHANNEL_B, CSR_AG_AUDIO->digital->mic_b.digital);
   
        CodecSetOutputGainNow( CSR_AG_AUDIO->codec_task, CODEC_MUTE, left_and_right_ch );
   
        PRINT(("CSR_AG_AUDIO: discon_spkr\n"));
   
        audio_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, ((CSR_AG_AUDIO->stereo && !task->two_mic) ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
        StreamDisconnect(0, audio_sink);
        SinkClose(audio_sink);   
   
        if( task->two_mic && CSR_AG_AUDIO->stereo)
        {
            audio_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
            StreamDisconnect(0, audio_sink);
            SinkClose(audio_sink); 
        }        
   
        PRINT(("CSR_AG_AUDIO: discon_mic\n"));
 
        if (mic_src_a)
        {
            StreamDisconnect(mic_src_a, 0);
            SourceClose(mic_src_a);
        }
        /* Disconnect PCM stream from mic_2 if we are unloading 2mic CSR_AG_AUDIO  */
        if (mic_src_b)
        {
            if (task->two_mic)
            {
                PRINT(("CSR_AG_AUDIO: disconnect PCM source 1\n"));
                StreamDisconnect(mic_src_b, 0);
            }
            SourceClose(mic_src_b);
        } 
        
        /* Turn off Digital Mic PIO */
        AudioPluginSetMicPio(CSR_AG_AUDIO->digital->mic_a, FALSE);
        if(task->two_mic) 
            AudioPluginSetMicPio(CSR_AG_AUDIO->digital->mic_b, FALSE);   
    }
    
    StreamDisconnect(0, StreamKalimbaSink(0) );
    StreamDisconnect(StreamKalimbaSource(0), 0);
    StreamDisconnect(0, StreamKalimbaSink(1) );
    StreamDisconnect(StreamKalimbaSource(1), 0); 

   CSR_AG_AUDIO->running = FALSE;	
   CSR_AG_AUDIO->audio_sink = NULL;
   CSR_AG_AUDIO->link_type = 0;
    
   PRINT(("CSR_AG_AUDIO: Disconnect\n"));
 
   /* Cancel any outstanding cvc messages */
   MessageCancelAll( (TaskData*)task , MESSAGE_FROM_KALIMBA);
   MessageCancelAll( (TaskData*)task , MESSAGE_STREAM_DISCONNECT);
    
   free (CSR_AG_AUDIO);
   CSR_AG_AUDIO = NULL;                
    
   KalimbaPowerOff();      
}

/****************************************************************************
NAME
   CsrAgAudioPluginSetVolume

DESCRIPTION
   

RETURNS
   void
*/
void CsrAgAudioPluginSetVolume( CsrAgAudioPluginTaskData *task, uint16 volume )
{
   if (!CSR_AG_AUDIO)
      Panic() ;
 
   /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
   if (volume > 0xf)
      volume = 0xf;

   CSR_AG_AUDIO->volume = volume;
   PRINT(("CSR_AG_AUDIO: DAC GAIN SET[%x]\n", CSR_AG_AUDIO->volume ));
    
   /* Only update the volume if not in a mute mode */
   if ( CSR_AG_AUDIO->running && !( (CSR_AG_AUDIO->mode==AUDIO_MODE_MUTE_SPEAKER ) || (CSR_AG_AUDIO->mode==AUDIO_MODE_MUTE_BOTH ) ) )
   {
      CodecMessage (task, CSR_AG_AUDIO->mic_gain_left,CSR_AG_AUDIO->mic_gain_right, CSR_AG_AUDIO->volume  );
   }         
}

/****************************************************************************
NAME	
   CsrAgAudioPluginSetMode

DESCRIPTION
   

RETURNS
   void
*/
void CsrAgAudioPluginSetMode ( CsrAgAudioPluginTaskData *task, AUDIO_MODE_T mode , const void * params )
{    
   if (!CSR_AG_AUDIO)
      Panic();            
   if ( CSR_AG_AUDIO->running == FALSE )
      Panic();
    
   CSR_AG_AUDIO->mode = mode;
    
   switch (mode)
   {
      case AUDIO_MODE_MUTE_SPEAKER:
      {
         CodecMessage (task, CSR_AG_AUDIO->mic_gain_left,CSR_AG_AUDIO->mic_gain_right, CODEC_MUTE);
      }
      break;

      case AUDIO_MODE_CONNECTED:
      {
         KalimbaSendMessage(MESSAGE_SETMODE , SYSMODE_PSTHRGH , 0, 0, 0 );
         CodecMessage (task, CSR_AG_AUDIO->mic_gain_left,CSR_AG_AUDIO->mic_gain_right, CSR_AG_AUDIO->volume  );
         PRINT(("CSR_AG_AUDIO: Set Mode connected \n"));
      }
      break;

      case AUDIO_MODE_MUTE_MIC:
      {
         CodecMessage (task, MIC_MUTE, MIC_MUTE, CSR_AG_AUDIO->volume  );
         PRINT(("CSR_AG_AUDIO: Set Mode Mute Mic \n"));
      }
      break;

      case AUDIO_MODE_MUTE_BOTH:
      {
         CodecMessage (task, MIC_MUTE, MIC_MUTE, CODEC_MUTE );
         PRINT(("CSR_AG_AUDIO: Set Mode SYSMODE_HFK MUTE BOTH - Standby\n"));
      }
      break;
 
      default:
      {  /*do not send a message and return false*/ 
         PRINT(("CSR_AG_AUDIO: Set Mode Invalid [%x]\n" , mode ));
      }
      break;
   }
}

/****************************************************************************
NAME	
   CsrAgAudioPluginPlayTone

DESCRIPTION
   queues the tone if can_queue is TRUE and there is already a tone playing

RETURNS
   false if a tone is already playing
    
*/
void CsrAgAudioPluginPlayTone (CsrAgAudioPluginTaskData *task, ringtone_note * tone , Task codec_task , uint16 tone_volume , bool stereo)  
{   
   Source lSource;  
   Sink lSink; 
        
   if (!CSR_AG_AUDIO)
      Panic() ;
   
   if ( CSR_AG_AUDIO->running == FALSE )
      Panic() ;       

   PRINT(("CSR_AG_AUDIO: Tone Start\n"));
   
   /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
   if (tone_volume > 0xf)
      tone_volume = 0xf;

   /* set DAC gain to a suitable level for tone play */
   if (tone_volume != CSR_AG_AUDIO->tone_volume)
   {
      CSR_AG_AUDIO->tone_volume = tone_volume;
      CodecMessage (task, CSR_AG_AUDIO->mic_gain_left,CSR_AG_AUDIO->mic_gain_right, CSR_AG_AUDIO->tone_volume  );
   }

   lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
    
   /*request an indication that the tone has completed / been disconnected*/
   MessageSinkTask ( lSink , (TaskData*) task );

   /*connect the tone*/
   lSource = StreamRingtoneSource ( (const ringtone_note *) (tone) );    
 
   /*mix the tone to the CSR_AG_AUDIO*/    
   StreamConnectAndDispose( lSource , lSink );

}

/****************************************************************************
NAME	
   CsrAgAudioPluginStopTone

DESCRIPTION
   Stop a tone from playing

RETURNS
   whether or not the tone was stopped successfully
*/
void CsrAgAudioPluginStopTone ( void ) 
{
   if (!CSR_AG_AUDIO)
      Panic() ;
        
   StreamDisconnect( 0 , StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) ) ; 
}


/****************************************************************************
DESCRIPTION
   Connect the audio stream (Speaker and Microphone)
*/
static void ConnectAudio (CsrAgAudioPluginTaskData *task, bool stereo )
{             
    bool r1, r2 , r3 =0;
 
    if ( CSR_AG_AUDIO->audio_sink )
    {
        Source mic_src = NULL;
        Source mic_src2 = NULL;
        Sink speaker_snk =NULL;

        /* DSP is up and running */
        CSR_AG_AUDIO->running = TRUE ;
      
        /* Set DAC gain to minimum value before connecting streams */
        CodecSetOutputGainNow( CSR_AG_AUDIO->codec_task, 0, left_and_right_ch );   
        
        if (CSR_AG_AUDIO->digital)
        {
            /* Configure port 0 to be routed to internal ADC and DACs */  
            speaker_snk = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, ((stereo && !task->two_mic) ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
            
            PanicFalse(SinkConfigure(speaker_snk, STREAM_CODEC_OUTPUT_RATE, CSR_AG_AUDIO->dac_rate));
    
            mic_src = AudioPluginGetMic(AUDIO_CHANNEL_A, CSR_AG_AUDIO->digital->mic_a.digital);
            AudioPluginSetMicRate(mic_src, CSR_AG_AUDIO->digital->mic_a.digital, CSR_AG_AUDIO->dac_rate);

            /* Connect Ports to DSP */
            r2 = (bool) StreamConnect(StreamKalimbaSource(0),speaker_snk);   /* DSP->DAC */
    
            if( task->two_mic )
            {
                PRINT(("CSR_AG_AUDIO: Connect PCM source 1\n"));
                mic_src2 = AudioPluginGetMic(AUDIO_CHANNEL_B, CSR_AG_AUDIO->digital->mic_b.digital);
                AudioPluginSetMicRate(mic_src2, CSR_AG_AUDIO->digital->mic_b.digital, CSR_AG_AUDIO->dac_rate);
                SourceSynchronise(mic_src,mic_src2);
                r3 = (bool) StreamConnect( mic_src2 ,StreamKalimbaSink(2));  /* ADC_RIGHT->DSP */
                
                if(stereo)
                {
                    Sink spkr_sink_b = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                    PanicFalse(SinkConfigure(spkr_sink_b, STREAM_CODEC_OUTPUT_RATE, CSR_AG_AUDIO->dac_rate));
                    SinkSynchronise(speaker_snk,spkr_sink_b);
                    r3 = (bool) StreamConnect(StreamKalimbaSource(2),spkr_sink_b);   /* DSP->DAC */
                }
            }
           r1 = (bool) StreamConnect( mic_src,StreamKalimbaSink(0));  /* ADC_LEFT->DSP */ 
           PRINT(("CSR_AG_AUDIO: connect_mic_spkr %d %d %d \n",r1,r2,r3)); 
       }
        
        if (CSR_AG_AUDIO->usb)
        {
           /* connect DSP to USB */
           StreamConnect(CSR_AG_AUDIO->usb->usb_source, StreamKalimbaSink(0)); /* USB Source->DSP */
           StreamConnect(StreamKalimbaSource(0), CSR_AG_AUDIO->usb->usb_sink); /* DSP->USB Sink */
        }
        
        r1 = (bool) StreamConnect(StreamSourceFromSink( CSR_AG_AUDIO->audio_sink ),StreamKalimbaSink(1)); /* SCO->DSP */  
        r2 = (bool) StreamConnect( StreamKalimbaSource(1), CSR_AG_AUDIO->audio_sink ); /* DSP->SCO */
        PRINT(("CSR_AG_AUDIO: connect_sco %d %d \n",r1,r2));  

        /* Set the mode */
        CsrAgAudioPluginSetMode ( task, CSR_AG_AUDIO->mode , NULL );
    }
    else
    {
        /*Power Down*/
        CsrAgAudioPluginDisconnect(task);
    }
}                

/****************************************************************************
DESCRIPTION
    Set mic gain
*/
static void CsrAgAudioMicSetGain(audio_channel channel, bool digital, T_mic_gain gain)
{
    Source mic_source = AudioPluginGetMic(channel, digital);
    uint8 mic_gain = (digital ? gain.digital_gain : gain.analogue_gain);
    AudioPluginSetMicGain(mic_source, digital, mic_gain, gain.preamp_enable);
}


/****************************************************************************
DESCRIPTION
   Handles a CVC_CODEC message received from CSR_AG_AUDIO
*/
static void CodecMessage (CsrAgAudioPluginTaskData *task, T_mic_gain input_gain_l, T_mic_gain input_gain_r, uint16 output_gain )
{   
    PRINT(("CSR_AG_AUDIO: Output gain = 0x%x\n" , output_gain ));
    PRINT(("CSR_AG_AUDIO: Input gain L:R = 0x%x : 0x%x \n", *(uint16*)&input_gain_l, *(uint16*)&input_gain_r));

    /* check pointer validity as there is a very small window where a message arrives
       as the result of playing a tone after CSR_AG_AUDIO has been powered down */
    if(CSR_AG_AUDIO)
    {
        /*Set the output Gain immediately*/    
        CodecSetOutputGainNow( CSR_AG_AUDIO->codec_task, output_gain, left_and_right_ch);
        
        if (CSR_AG_AUDIO->digital)
        {    
            /* Set input gain(s) */
            CsrAgAudioMicSetGain(AUDIO_CHANNEL_A, CSR_AG_AUDIO->digital->mic_a.digital, input_gain_l);
            if( task->two_mic ) 
                CsrAgAudioMicSetGain(AUDIO_CHANNEL_B, CSR_AG_AUDIO->digital->mic_b.digital, input_gain_r);
        }
    }
}


/****************************************************************************
DESCRIPTION
   handles the internal cvc messages /  messages from the dsp
*/
void CsrAgAudioPluginInternalMessage( CsrAgAudioPluginTaskData *task ,uint16 id , Message message ) 
{
    switch(id)
    {
        case MESSAGE_FROM_KALIMBA:
        {
            const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
            PRINT(("CSR_AG_AUDIO: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));

            switch ( m->id )
            {
            
#ifndef KOOVOX        
				/* send the heart rate msg to app task */
				case (HEART_RATE_MSG):
				{
					uint8* msg = PanicUnlessMalloc(sizeof(DSP_REGISTER_T));
					memcpy(msg, m, sizeof(DSP_REGISTER_T));
					PRINT(("message from dsp\n"));
					MessageSend(CSR_AG_AUDIO->app_task, EVENT_DSP_MESSAGE, msg);
				}
				break;
#endif
				
				
                case KALIMBA_MSG_WARP_VALUES:
                    {
                        if (CSR_AG_AUDIO)
                        {
                            MAKE_AUDIO_MESSAGE_WITH_LEN(AUDIO_PLUGIN_DSP_IND, CSR_AG_AUDIO_WARP_NUMBER_VALUES);
                            PRINT(("CSR_AG_AUDIO: Send CLOCK_MISMATCH_RATE\n"));
                            message->id = KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE;
                            message->size_value = CSR_AG_AUDIO_WARP_NUMBER_VALUES;
                            message->value[0] = m->a;
                            message->value[1] = m->b;
                            message->value[2] = m->c;
                            message->value[3] = m->d;
                            MessageSend(CSR_AG_AUDIO->app_task, AUDIO_PLUGIN_DSP_IND, message);
                        }
                    }
                    break;
                    
                default:
                    break;
            }
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
   a tone has completed
*/
void CsrAgAudioPluginToneComplete( CsrAgAudioPluginTaskData *task) 
{
   /* Restore the DAC gain to mute if in mute mode */
   if ( CSR_AG_AUDIO->running && (CSR_AG_AUDIO->mode==AUDIO_MODE_MUTE_SPEAKER || CSR_AG_AUDIO->mode==AUDIO_MODE_MUTE_BOTH ) )
      CodecMessage (task, CSR_AG_AUDIO->mic_gain_left,CSR_AG_AUDIO->mic_gain_right, CODEC_MUTE );   
   else
      CodecMessage (task, CSR_AG_AUDIO->mic_gain_left,CSR_AG_AUDIO->mic_gain_right, CSR_AG_AUDIO->volume  );
   
   /* We no longer want to receive stream indications */
   MessageSinkTask (StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) , NULL);   
}
