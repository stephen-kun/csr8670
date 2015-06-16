/*
  Copyright (C) Cambridge Silicon Radio Ltd. 2010 ~ 2014

  An example app for routing audio through the Kalimba DSP from ADC to DAC

*/

#include <kalimba.h> 
#include <kalimba_standard_messages.h> 
#include <file.h> 
#include <string.h>  
#include <panic.h>
#include <source.h>
#include <sink.h>
#include <stream.h>
#include <connection.h>
#include <micbias.h>
#include <pio.h>

void PioSetPio (uint16 pPIO , bool pOnOrOff);

/* Select Amp PIO depending on board used.  If not defined, assume the CNS10001v4 board is assumed. */
#ifdef H13179V2
    #define POWER_AMP_PIO 14
#else  /* Assume CNS10001v4 */
    #define POWER_AMP_PIO 4
#endif 

/* Define the macro "BYPASS_KALIMBA" to bypass Kalimba DSP otherwise direct ADC->DAC */
/* #define BYPASS_KALIMBA */
/* Define the macro "MIC_INPUT" for microphone input otherwise line-in input */
/* #define MIC_INPUT */

/* Location of DSP kap file in the file system */
static const char kal[] = "my_second_dsp_app_kalimba/my_second_dsp_app_kalimba.kap";

uint16 sampleRate = 48000; 

void start_kalimba(void);
void connect_streams(void);

/* Main VM routine */
int main(void)
{
    /* Load the Kalimba */
    start_kalimba();

    /* Connect up the ADCs and DACS */
    connect_streams();

    /* Start the Kalimba */
    PanicFalse( KalimbaSendMessage(KALIMBA_MSG_GO,0,0,0,0) );

    /* Remain in MessageLoop (handles messages) */
    MessageLoop();

    return 0;
}

void start_kalimba(void)
{
    /* Find the codec file in the file system */
    FILE_INDEX index = FileFind( FILE_ROOT, (const char *)kal, strlen(kal) );

    /* Did we find the desired file? */
    PanicFalse( index != FILE_NONE );

    /* Load the codec into Kalimba */
    PanicFalse( KalimbaLoad( index ) );
}

void connect_streams(void)
{  
    /* Access left and right ADC and DAC */
    Source audio_source_a = StreamAudioSource( AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A );
    Source audio_source_b = StreamAudioSource( AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B );
    Sink audio_sink_a = StreamAudioSink( AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A );
    Sink audio_sink_b = StreamAudioSink( AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B );

    /* Configure sampling rate for both channels and synchronise left and right channels */
    PanicFalse( SourceConfigure(audio_source_a, STREAM_CODEC_INPUT_RATE, sampleRate) );
    PanicFalse( SourceConfigure(audio_source_b, STREAM_CODEC_INPUT_RATE, sampleRate) );
    PanicFalse( SourceSynchronise(audio_source_a, audio_source_b) );
    
    PanicFalse( SinkConfigure(audio_sink_a, STREAM_CODEC_OUTPUT_RATE, sampleRate) );
    PanicFalse( SinkConfigure(audio_sink_b, STREAM_CODEC_OUTPUT_RATE, sampleRate) );
    PanicFalse( SinkSynchronise(audio_sink_a, audio_sink_b) );

    /* Set up codec gains */
#ifdef MIC_INPUT 
    PanicFalse( SourceConfigure(audio_source_a, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, 1) );
    PanicFalse( SourceConfigure(audio_source_b, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, 1) );
    
    PanicFalse(MicbiasConfigure(MIC_BIAS_0, MIC_BIAS_ENABLE, MIC_BIAS_FORCE_ON));   
    PanicFalse(MicbiasConfigure(MIC_BIAS_1, MIC_BIAS_ENABLE, MIC_BIAS_FORCE_ON)); 
#else          
    PanicFalse( SourceConfigure(audio_source_a, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, 0) );
    PanicFalse( SourceConfigure(audio_source_b, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, 0) );
#endif
    
    PanicFalse( SourceConfigure(audio_source_a, STREAM_CODEC_INPUT_GAIN, 9) ); 
    PanicFalse( SourceConfigure(audio_source_b, STREAM_CODEC_INPUT_GAIN, 9) );
     
    PioSetPio(POWER_AMP_PIO, TRUE); 

    PanicFalse( SinkConfigure(audio_sink_a, STREAM_CODEC_OUTPUT_GAIN, 15) );
    PanicFalse( SinkConfigure(audio_sink_b, STREAM_CODEC_OUTPUT_GAIN, 15) );

#ifdef BYPASS_KALIMBA
    /* Plug Left ADC directly into left DAC */
    PanicFalse( StreamConnect(audio_source_a, audio_sink_a) );
    /* Plug Right ADC directly into right DAC */
    PanicFalse( StreamConnect(audio_source_b, audio_sink_b) );
#else
    /* Plug Left ADC into port 0 */
    PanicFalse( StreamConnect(audio_source_a, StreamKalimbaSink(0)) );
    /* Plug Right ADC into port 1 */
    PanicFalse( StreamConnect(audio_source_b, StreamKalimbaSink(1)) );
    /* Plug port 0 into Left DAC */
    PanicFalse( StreamConnect(StreamKalimbaSource(0), audio_sink_a) );
    /* Plug port 1 into Right DAC */
    PanicFalse( StreamConnect(StreamKalimbaSource(1), audio_sink_b) );
#endif
}

void PioSetPio (uint16 pPIO , bool pOnOrOff) 
{
    uint16 lPinVals = 0 ;
    uint16 lWhichPin  = (1<< pPIO) ;
        
    if ( pOnOrOff )    
    {
        lPinVals = lWhichPin  ;
    }
    else
    {
        lPinVals = 0x0000;/*clr the corresponding bit*/
    }

  	/*(mask,bits) setting bit to a '1' sets the corresponding port as an output*/
    PioSetDir32( lWhichPin , lWhichPin );   
  	/*set the value of the pin*/         
    PioSet32 ( lWhichPin , lPinVals ) ;     
}
