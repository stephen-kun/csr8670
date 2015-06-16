/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
   csr_cvsd_8k_cvc_1mic_headset.c
    
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
#include <app/vm/vm_if.h>
#include "audio_plugin_if.h"        /*for the audio_mode*/
#include "audio_plugin_common.h"
#include "csr_common_example_if.h"  /*for things common to all CSR_COMMON_EXAMPLE systems*/
#include "csr_common_example_plugin.h"
#include "csr_common_example.h"

#include <csr_cvc_common_plugin.h> /* to get mic params from plugin params */


/*helper functions*/
static void ConnectAudio (ExamplePluginTaskdata *task,  bool stereo );
static void CodecMessage (ExamplePluginTaskdata *task, T_mic_gain input_gain_l,T_mic_gain input_gain_r, uint16 output_gain ) ;
uint32 CsrCalcDacRate ( EXAMPLE_PLUGIN_TYPE_T cvc_plugin_variant, uint32 rate );
static FILE_INDEX CsrSelectKapFile(EXAMPLE_PLUGIN_TYPE_T example_plugin_variant, uint32 dac_rate);


typedef struct audio_Tag
{
   /*! Whether or not CSR_COMMON_EXAMPLE is running */
   unsigned running:1;
   unsigned reserved:6;
   /*! mono or stereo*/
   unsigned stereo:1;
   /*! The current CSR_COMMON_EXAMPLE mode */
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
}EXAMPLE_t ;

/* The task instance pointer*/
static EXAMPLE_t * CSR_COMMON_EXAMPLE = NULL;



static FILE_INDEX CsrSelectKapFile(EXAMPLE_PLUGIN_TYPE_T example_plugin_variant, uint32 dac_rate)
{		
   FILE_INDEX index = 0;
   char* kap_file = NULL;
	
   switch(example_plugin_variant)
   {
      case CVSD_8K_1_MIC:
         kap_file = "one_mic_example_cvsd/one_mic_example_cvsd.kap";		
    	break;

      case CVSD_8K_2_MIC:
         kap_file = "two_mic_example_cvsd/two_mic_example_cvsd.kap";
      break;
    	
      case SBC_1_MIC:
         /* Tell firmware the size of the SBC frame */
         kap_file = "one_mic_example_16k/one_mic_example_16k.kap";
      break;
      
      case SBC_2_MIC:
         /* Tell firmware the size of the SBC frame */
         kap_file = "two_mic_example_16k/two_mic_example_16k.kap";
      break;
      
      default:
         PRINT(("CSR_COMMON_EXAMPLE: No Corresponding Kap file\n")) ;
         Panic() ;
    	break;
   }

   index = FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file));
    
   if( index == FILE_NONE )
   {
      PRINT(("CSR_COMMON_EXAMPLE: No File\n"));
      Panic();
   }
   
   return(index);
}

uint32 CsrCalcDacRate ( EXAMPLE_PLUGIN_TYPE_T cvc_plugin_variant, uint32 rate )
{
   uint32 dac_rate = 0 ;
   /* Calculate the DAC rate based on over the air rate value and the type of codec
   It holds true for both 8K and 16K connection and calculates the rate correctly */

   switch ( cvc_plugin_variant ) 
   {
      /* For SBC case, we are currently hard coding the dac_rate to be 16K */
      case SBC_1_MIC:
         dac_rate = 16000;
         
      break;

      case SBC_2_MIC:
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
   CsrCvcPluginConnect

DESCRIPTION
   This function connects cvc to the stream subsystem

RETURNS
   void
*/
void CsrExamplePluginConnect( ExamplePluginTaskdata *task, Sink audio_sink , AUDIO_SINK_T sink_type, Task codec_task , uint16 volume , uint32 rate , bool stereo , AUDIO_MODE_T mode , const void * params )
{
   FILE_INDEX index;
   typed_bdaddr rem_addr; 
	
   /*signal that the audio is busy until the kalimba / parameters are fully loaded so that no tone messages etc will arrive*/
   SetAudioBusy((TaskData*) task);    
    
   if (CSR_COMMON_EXAMPLE)
      Panic();
   
   CSR_COMMON_EXAMPLE = PanicUnlessNew ( EXAMPLE_t ); 
    
   /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
   if (volume > 0xf)
      volume = 0xf;

   CSR_COMMON_EXAMPLE->running         = FALSE;
   CSR_COMMON_EXAMPLE->codec_task      = codec_task;                                                        
   CSR_COMMON_EXAMPLE->link_type       = (sync_link_type)sink_type ;                                                        
   CSR_COMMON_EXAMPLE->volume          = volume;
   CSR_COMMON_EXAMPLE->audio_sink      = audio_sink;
   CSR_COMMON_EXAMPLE->mode            = mode;
   CSR_COMMON_EXAMPLE->stereo          = stereo;
   CSR_COMMON_EXAMPLE->tone_volume     = volume;
   CSR_COMMON_EXAMPLE->mic_gain_left   = MIC_DEFAULT_GAIN;
   CSR_COMMON_EXAMPLE->mic_gain_right  = MIC_DEFAULT_GAIN;
   CSR_COMMON_EXAMPLE->digital         = ((cvc_plugin_params*) params)->digital;
   
	
   PRINT(("CSR_COMMON_EXAMPLE: connect [%x] [%x]\n", CSR_COMMON_EXAMPLE->running , (int)CSR_COMMON_EXAMPLE->audio_sink));

    /* Set mic pin */
    AudioPluginSetMicPio(CSR_COMMON_EXAMPLE->digital->mic_a, TRUE);
    if(task->two_mic) 
        AudioPluginSetMicPio(CSR_COMMON_EXAMPLE->digital->mic_b, TRUE);

  /* For WBS set SBC Frame size, else sample-based */
    if( (task->example_plugin_variant == SBC_1_MIC) || (task->example_plugin_variant == SBC_2_MIC) )
    {
       SinkConfigure(CSR_COMMON_EXAMPLE->audio_sink, VM_SINK_SCO_SET_FRAME_LENGTH, BYTES_PER_MSBC_FRAME);
    }

   /* Enable MetaData */
   SourceConfigure(StreamSourceFromSink( CSR_COMMON_EXAMPLE->audio_sink ),VM_SOURCE_SCO_METADATA_ENABLE,1);

   /* Clear all routing to the PCM subsysytem*/
   /*TODO    PcmClearAllRouting();
   */

   /* Calculate the DAC rate based on the over-the-air rate value passed in from VM */
   CSR_COMMON_EXAMPLE->dac_rate = CsrCalcDacRate( (EXAMPLE_PLUGIN_TYPE_T)task->example_plugin_variant, rate );
   
   /*ensure that the messages received are from the correct kap file*/ 
   (void) MessageCancelAll( (TaskData*) task, MESSAGE_FROM_KALIMBA);
    MessageKalimbaTask( (TaskData*) task );

   /* Select which Kap file to be loaded based on the plugin selected */
   index = CsrSelectKapFile((EXAMPLE_PLUGIN_TYPE_T)task->example_plugin_variant, CSR_COMMON_EXAMPLE->dac_rate); 
    
   /* Load the cvc algorithm into Kalimba*/
   if( !KalimbaLoad( index ) )
   {
      PRINT(("Kalimba load fail\n"));
      Panic();
   }
    
   /* get remote address */
   SinkGetBdAddr(CSR_COMMON_EXAMPLE->audio_sink, &rem_addr);
   KalimbaSendMessage(MESSAGE_REM_BT_ADDRESS, rem_addr.addr.nap, (rem_addr.addr.lap >> 16) | (((unsigned int)rem_addr.addr.uap) << 8), rem_addr.addr.lap & 0xffff, 0 );

   ConnectAudio (task, CSR_COMMON_EXAMPLE->stereo) ;
   SetAudioBusy(NULL);
   SetCurrentDspStatus(DSP_LOADING);

 }

/****************************************************************************
NAME	
   CsrCvcPluginDisconnect

DESCRIPTION
   Disconnect CSR_COMMON_EXAMPLE and power off the Kalimba DSP core
     
RETURNS
   void
*/
void CsrExamplePluginDisconnect( ExamplePluginTaskdata *task )
{
    Source mic_src_a;
    Source mic_src_b;
    Sink audio_sink;
    
   if (!CSR_COMMON_EXAMPLE)
      Panic() ;
   if ( CSR_COMMON_EXAMPLE->running == FALSE )
      Panic() ;

   CodecSetOutputGainNow( CSR_COMMON_EXAMPLE->codec_task, CODEC_MUTE, left_and_right_ch ); 
   
   audio_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, ((CSR_COMMON_EXAMPLE->stereo && !task->two_mic) ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
   mic_src_a = AudioPluginGetMic(AUDIO_CHANNEL_A, CSR_COMMON_EXAMPLE->digital->mic_a.digital);
 
   StreamDisconnect(mic_src_a, StreamKalimbaSink(0));
   StreamDisconnect(StreamKalimbaSource(0), audio_sink);
   SourceClose(mic_src_a);
   SinkClose(audio_sink);   
     
   
   PRINT(("CSR_COMMON_EXAMPLE: Streams disconnected (left)\n")); 
   
   
    if( task->two_mic)
    {
       mic_src_b = AudioPluginGetMic(AUDIO_CHANNEL_B, CSR_COMMON_EXAMPLE->digital->mic_b.digital);
       StreamDisconnect(mic_src_b, StreamKalimbaSink(2));  
       SourceClose(mic_src_b); 
       if(CSR_COMMON_EXAMPLE->stereo)
       {
            audio_sink = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
            StreamDisconnect(StreamKalimbaSource(2), audio_sink);
            SinkClose(audio_sink); 
       }
       PRINT(("CSR_COMMON_EXAMPLE: Streams disconnected (Right)\n")); 
   }
    
   StreamDisconnect(StreamSourceFromSink( CSR_COMMON_EXAMPLE->audio_sink ),StreamKalimbaSink(1)); /* SCO->DSP */  
   StreamDisconnect( StreamKalimbaSource(1), CSR_COMMON_EXAMPLE->audio_sink );                    /* DSP->SCO */
    
   CSR_COMMON_EXAMPLE->running = FALSE;	
   CSR_COMMON_EXAMPLE->audio_sink = NULL;
   CSR_COMMON_EXAMPLE->link_type = 0;
    
   PRINT(("CSR_COMMON_EXAMPLE: Disconnect\n"));
 
   /* Cancel any outstanding cvc messages */
   MessageCancelAll( (TaskData*)task , MESSAGE_FROM_KALIMBA);
   MessageCancelAll( (TaskData*)task , MESSAGE_STREAM_DISCONNECT);

   
    /* Turn off Digital Mic PIO */
    AudioPluginSetMicPio(CSR_COMMON_EXAMPLE->digital->mic_a, FALSE);
    if(task->two_mic) 
        AudioPluginSetMicPio(CSR_COMMON_EXAMPLE->digital->mic_b, FALSE);   
    
   free (CSR_COMMON_EXAMPLE);
   CSR_COMMON_EXAMPLE = NULL;                
    
   KalimbaPowerOff();      
   
   /* update current dsp status */
   SetCurrentDspStatus( DSP_NOT_LOADED );
   /* update the current audio state */
   SetAudioInUse(FALSE);

}

/****************************************************************************
NAME
   CsrCvcPluginSetVolume

DESCRIPTION
   Tell CSR_COMMON_EXAMPLE to update the volume.

RETURNS
   void
*/
void CsrExamplePluginSetVolume( ExamplePluginTaskdata *task, uint16 volume )
{
   if (!CSR_COMMON_EXAMPLE)
      Panic() ;
 
   /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
   if (volume > 0xf)
      volume = 0xf;

   CSR_COMMON_EXAMPLE->volume = volume;
   PRINT(("CSR_COMMON_EXAMPLE: DAC GAIN SET[%x]\n", CSR_COMMON_EXAMPLE->volume ));
    
   /* Only update the volume if not in a mute mode */
   if ( CSR_COMMON_EXAMPLE->running && !( (CSR_COMMON_EXAMPLE->mode==AUDIO_MODE_MUTE_SPEAKER ) || (CSR_COMMON_EXAMPLE->mode==AUDIO_MODE_MUTE_BOTH ) ) )
   {
      CodecMessage (task, CSR_COMMON_EXAMPLE->mic_gain_left,CSR_COMMON_EXAMPLE->mic_gain_right, CSR_COMMON_EXAMPLE->volume  );
   }         
}

/****************************************************************************
NAME	
   CsrCvcPluginSetMode

DESCRIPTION
   Set the CSR_COMMON_EXAMPLE mode

RETURNS
   void
*/
void CsrExamplePluginSetMode ( ExamplePluginTaskdata *task, AUDIO_MODE_T mode , const void * params )
{    
   if (!CSR_COMMON_EXAMPLE)
      Panic();            
   if ( CSR_COMMON_EXAMPLE->running == FALSE )
      Panic();
    
   CSR_COMMON_EXAMPLE->mode = mode;
    
   switch (mode)
   {
      case AUDIO_MODE_MUTE_SPEAKER:
      {
         CodecMessage (task, CSR_COMMON_EXAMPLE->mic_gain_left,CSR_COMMON_EXAMPLE->mic_gain_right, CODEC_MUTE);
      }
      break;

      case AUDIO_MODE_CONNECTED:
      {
         KalimbaSendMessage(MESSAGE_SETMODE , SYSMODE_PSTHRGH , 0, 0, 0 );
         CodecMessage (task, CSR_COMMON_EXAMPLE->mic_gain_left,CSR_COMMON_EXAMPLE->mic_gain_right, CSR_COMMON_EXAMPLE->volume  );
         PRINT(("CSR_COMMON_EXAMPLE: Set Mode connected \n"));
      }
      break;

      case AUDIO_MODE_MUTE_MIC:
      {
         CodecMessage (task, MIC_MUTE, MIC_MUTE, CSR_COMMON_EXAMPLE->volume  );
         PRINT(("CSR_COMMON_EXAMPLE: Set Mode Mute Mic \n"));
      }
      break;

      case AUDIO_MODE_MUTE_BOTH:
      {
         CodecMessage (task, MIC_MUTE, MIC_MUTE, CODEC_MUTE );
         PRINT(("CSR_COMMON_EXAMPLE: Set Mode SYSMODE_HFK MUTE BOTH - Standby\n"));
      }
      break;
 
      default:
      {  /*do not send a message and return false*/ 
         PRINT(("CSR_COMMON_EXAMPLE: Set Mode Invalid [%x]\n" , mode ));
      }
      break;
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
void CsrExamplePluginPlayTone (ExamplePluginTaskdata *task, ringtone_note * tone , Task codec_task , uint16 tone_volume , bool stereo)  
{   
   Source lSource;  
   Sink lSink; 
        
   if (!CSR_COMMON_EXAMPLE)
      Panic() ;
   
   if ( CSR_COMMON_EXAMPLE->running == FALSE )
      Panic() ;       

   PRINT(("CSR_COMMON_EXAMPLE: Tone Start\n"));
   
   /* update current tone playing status */
   SetTonePlaying(TRUE);

   /* The DAC gain must be limited to 0 dB so that no distortion occurs and so the echo canceller works. */
   if (tone_volume > 0xf)
      tone_volume = 0xf;

   /* set DAC gain to a suitable level for tone play */
   if (tone_volume != CSR_COMMON_EXAMPLE->tone_volume)
   {
      CSR_COMMON_EXAMPLE->tone_volume = tone_volume;
      CodecMessage (task, CSR_COMMON_EXAMPLE->mic_gain_left,CSR_COMMON_EXAMPLE->mic_gain_right, CSR_COMMON_EXAMPLE->tone_volume  );
   }

   lSink = StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT);
    
   /*request an indication that the tone has completed / been disconnected*/
   MessageSinkTask ( lSink , (TaskData*) task );

   /*connect the tone*/
   lSource = StreamRingtoneSource ( (const ringtone_note *) (tone) );    
 
   /*mix the tone to the CSR_COMMON_EXAMPLE*/    
   StreamConnectAndDispose( lSource , lSink );

}

/****************************************************************************
NAME	
   CsrCvcPluginStopTone

DESCRIPTION
   Stop a tone from playing

RETURNS
   whether or not the tone was stopped successfully
*/
void CsrExamplePluginStopTone ( void ) 
{
   if (!CSR_COMMON_EXAMPLE)
      Panic() ;
        
   StreamDisconnect( 0 , StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) ) ; 
   
   /* update current tone playing status */
   SetTonePlaying(FALSE);

}


/****************************************************************************
DESCRIPTION
   Connect the audio stream (Speaker and Microphone)
*/
static void ConnectAudio (ExamplePluginTaskdata *task, bool stereo )
{             
    bool r1, r2 , r3 =0;
 
    if ( CSR_COMMON_EXAMPLE->audio_sink )
    {
        Source mic_src = NULL;
        Source mic_src2 = NULL;
        Sink speaker_snk =NULL;
		Sink spkr_sink_b=NULL;

        /* DSP is up and running */
        CSR_COMMON_EXAMPLE->running = TRUE ;
      
        /* update the current audio state */
        SetAudioInUse(TRUE);

        /* Set DAC gain to minimum value before connecting streams */
        CodecSetOutputGainNow( CSR_COMMON_EXAMPLE->codec_task, 0, left_and_right_ch );    

        /* Configure port 0 to be routed to internal ADC and DACs */  
        speaker_snk = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, ((stereo && !task->two_mic) ? AUDIO_CHANNEL_A_AND_B : AUDIO_CHANNEL_A));
        PanicFalse(SinkConfigure(speaker_snk, STREAM_CODEC_OUTPUT_RATE, CSR_COMMON_EXAMPLE->dac_rate));
        
        mic_src = AudioPluginGetMic(AUDIO_CHANNEL_A, CSR_COMMON_EXAMPLE->digital->mic_a.digital);
        AudioPluginSetMicRate(mic_src, CSR_COMMON_EXAMPLE->digital->mic_a.digital, CSR_COMMON_EXAMPLE->dac_rate);

        /* Connect Ports to DSP */
        if( task->two_mic )
        {
            PRINT(("CSR_COMMON_EXAMPLE: Connect PCM source 1\n"));
            mic_src2 = AudioPluginGetMic(AUDIO_CHANNEL_B, CSR_COMMON_EXAMPLE->digital->mic_b.digital);
            AudioPluginSetMicRate(mic_src2, CSR_COMMON_EXAMPLE->digital->mic_b.digital, CSR_COMMON_EXAMPLE->dac_rate);
            SourceSynchronise(mic_src,mic_src2);            
            if(stereo)
            {
                spkr_sink_b = StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B);
                PanicFalse(SinkConfigure(spkr_sink_b, STREAM_CODEC_OUTPUT_RATE, CSR_COMMON_EXAMPLE->dac_rate));
                SinkSynchronise(speaker_snk,spkr_sink_b);
            }
        }
        
        /* SP.  Must configure and sync ADC/DAC before connecting streams */
        
        r1 = (bool) StreamConnect( mic_src,StreamKalimbaSink(0));        /* ADC_LEFT->DSP */ 
        r2 = (bool) StreamConnect(StreamKalimbaSource(0),speaker_snk);   /* DSP->DAC */
        
        if( task->two_mic )
        {
            r3 = (bool) StreamConnect( mic_src2 ,StreamKalimbaSink(2));      /* ADC_RIGHT->DSP */
            if(stereo)
                r3 = (bool) StreamConnect(StreamKalimbaSource(2),spkr_sink_b);   /* DSP->DAC */
        }        
       
       PRINT(("CSR_COMMON_EXAMPLE: connect_mic_spkr %d %d %d \n",r1,r2,r3)); 

        r1 = (bool) StreamConnect(StreamSourceFromSink( CSR_COMMON_EXAMPLE->audio_sink ),StreamKalimbaSink(1)); /* SCO->DSP */  
        r2 = (bool) StreamConnect( StreamKalimbaSource(1), CSR_COMMON_EXAMPLE->audio_sink ); /* DSP->SCO */
        PRINT(("CSR_COMMON_EXAMPLE: connect_sco %d %d \n",r1,r2));  

        /* Set the mode */
        CsrExamplePluginSetMode ( task, CSR_COMMON_EXAMPLE->mode , NULL );
    }
    else
    {
        /*Power Down*/
        CsrExamplePluginDisconnect(task);
    }

    SetCurrentDspStatus(DSP_RUNNING);

}                

/****************************************************************************
DESCRIPTION
    Set mic gain
*/
static void CsrExampleMicSetGain(audio_channel channel, bool digital, T_mic_gain gain)
{
    Source mic_source = AudioPluginGetMic(channel, digital);
    uint8 mic_gain = (digital ? gain.digital_gain : gain.analogue_gain);
    AudioPluginSetMicGain(mic_source, digital, mic_gain, gain.preamp_enable);
}


/****************************************************************************
DESCRIPTION
   Handles a CVC_CODEC message received from CSR_COMMON_EXAMPLE
*/
static void CodecMessage (ExamplePluginTaskdata *task, T_mic_gain input_gain_l, T_mic_gain input_gain_r, uint16 output_gain )
{   
    PRINT(("CSR_COMMON_EXAMPLE: Output gain = 0x%x\n" , output_gain ));
    PRINT(("CSR_COMMON_EXAMPLE: Input gain L:R = 0x%x : 0x%x \n", *(uint16*)&input_gain_l, *(uint16*)&input_gain_r));

    /* check pointer validity as there is a very small window where a message arrives
       as the result of playing a tone after CSR_COMMON_EXAMPLE has been powered down */
    if(CSR_COMMON_EXAMPLE)
    {
        /*Set the output Gain immediately*/    
        CodecSetOutputGainNow( CSR_COMMON_EXAMPLE->codec_task, output_gain, left_and_right_ch);
    
        /* Set input gain(s) */
        CsrExampleMicSetGain(AUDIO_CHANNEL_A, CSR_COMMON_EXAMPLE->digital->mic_a.digital, input_gain_l);
        if( task->two_mic ) 
            CsrExampleMicSetGain(AUDIO_CHANNEL_B, CSR_COMMON_EXAMPLE->digital->mic_b.digital, input_gain_r);
    }
}


/****************************************************************************
DESCRIPTION
   handles the internal cvc messages /  messages from the dsp
*/
void CsrExamplePluginInternalMessage( ExamplePluginTaskdata *task ,uint16 id , Message message ) 
{
   switch(id)
   {
      case MESSAGE_FROM_KALIMBA:
	{
         const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
         PRINT(("CSR_CVSD_8K_1MIC: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));

         switch ( m->id )
         {
            /* Case statements for messages from the kalimba can be added here.
               The example application as shipped does not send any messages
               to the DSP. */
            default:
            break;
         }
      }
      break;
	
      /* Message is not from DSP.  The example plugin as shipped does not
         send any messages to this handler. */

      default:
      break;
   }		
}	

/****************************************************************************
DESCRIPTION
   a tone has completed
*/
void CsrExamplePluginToneComplete( ExamplePluginTaskdata *task) 
{
   /* Restore the DAC gain to mute if in mute mode */
   if ( CSR_COMMON_EXAMPLE->running && (CSR_COMMON_EXAMPLE->mode==AUDIO_MODE_MUTE_SPEAKER || CSR_COMMON_EXAMPLE->mode==AUDIO_MODE_MUTE_BOTH ) )
      CodecMessage (task, CSR_COMMON_EXAMPLE->mic_gain_left,CSR_COMMON_EXAMPLE->mic_gain_right, CODEC_MUTE );   
   else
      CodecMessage (task, CSR_COMMON_EXAMPLE->mic_gain_left,CSR_COMMON_EXAMPLE->mic_gain_right, CSR_COMMON_EXAMPLE->volume  );
   
   /* We no longer want to receive stream indications */
   MessageSinkTask (StreamKalimbaSink(TONE_VP_MIXING_DSP_PORT) , NULL);   
   
   /* update current tone playing status */
   SetTonePlaying(FALSE);

}
