/*
  Copyright (C) Cambridge Silicon Radio Ltd. 2006 ~ 2014

  Basic example app for routing I2S audio through the DSP.
*/

#include <kalimba.h> 
#include <kalimba_standard_messages.h>
#include <file.h> 
#include <string.h>  
#include <panic.h>
#include <source.h>
#include <sink.h>
#include <stream.h>
#include <led.h>
#include <connection.h>
  
/* Define the macro "BYPASS_KALIMBA" to bypass Kalimba DSP otherwise direct I2S->I2S */
#define BYPASS_KALIMBAx

/* I2S Master / Slave switch. 1 = Master, 0 = Slave */
#define I2S_MASTER       0

/* I2S Interface frame rate*/
#define I2S_RATE     96000

/* Audio Bit Depth for use with the STREAM_AUDIO_PRECISION key */
#define BIT_DEPTH       24

/* Location of DSP kap file in the file system */
static const char kal[] = "my_first_24bit_dsp_app_kalimba/my_first_24bit_dsp_app_kalimba.kap";


void start_kalimba(void);
void connect_streams(void);
void led(void);

/* Main VM routine */
int main(void)
{
    /* Load the Kalimba */
    start_kalimba();

    /* Connect up audio ports */
    connect_streams();
    
    /* Turn on LED */
    led();

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
    /* Audio Interfaces */
    Source I2S_IN_0;
    Source I2S_IN_1;  
    
    Sink I2S_OUT_0;
    Sink I2S_OUT_1;
    
    /* I2S Setup */
    
    /* Source StreamAudioSource (audio_hardware hardware, audio_instance instance, audio_channel channel); */
    I2S_IN_0 = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0);
    I2S_IN_1 = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1);    
    
    /* Sink StreamAudioSink (audio_hardware hardware, audio_instance instance, audio_channel channel); */
    I2S_OUT_0 = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0);
    I2S_OUT_1 = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1);

    /* SinkConfigure (Sink sink, stream_config_key key, uint32 value) */
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_MASTER_MODE, I2S_MASTER));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_MASTER_MODE, I2S_MASTER));    
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_SYNC_RATE, I2S_RATE));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_SYNC_RATE, I2S_RATE));
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_AUDIO_PRECISION, BIT_DEPTH));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_AUDIO_PRECISION, BIT_DEPTH));

    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_MASTER_CLOCK_RATE, 0));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_MASTER_CLOCK_RATE, 0));
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_JSTFY_FORMAT, 0));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_JSTFY_FORMAT, 0));
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_LFT_JSTFY_DLY, 1));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_LFT_JSTFY_DLY, 1));
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_CHNL_PLRTY, 0));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_CHNL_PLRTY, 0));
    PanicFalse(SinkConfigure(I2S_OUT_0, STREAM_I2S_BITS_PER_SAMPLE, 24));
    PanicFalse(SinkConfigure(I2S_OUT_1, STREAM_I2S_BITS_PER_SAMPLE, 24));
    
    /* SourceConfigure (Source source, stream_config_key key, uint32 value) */
    PanicFalse(SourceConfigure(I2S_IN_0, STREAM_I2S_SYNC_RATE, I2S_RATE));
    PanicFalse(SourceConfigure(I2S_IN_1, STREAM_I2S_SYNC_RATE, I2S_RATE));
	
	/* Set Audio bit depth */
    PanicFalse(SourceConfigure(I2S_IN_0, STREAM_AUDIO_PRECISION, BIT_DEPTH));
    PanicFalse(SourceConfigure(I2S_IN_1, STREAM_AUDIO_PRECISION, BIT_DEPTH));
    
    /* Synchronise sink and source*/    
    PanicFalse(SinkSynchronise(I2S_OUT_0, I2S_OUT_1)); 
    PanicFalse(SourceSynchronise(I2S_IN_0, I2S_IN_1));
    

#ifdef BYPASS_KALIMBA
    /* I2S loopback without DSP */
    PanicFalse( StreamConnect(I2S_IN_0, I2S_OUT_0) );
    PanicFalse( StreamConnect(I2S_IN_1, I2S_OUT_1) );
#else
    /* Plug I2S in slot 0 into port 0 */
    PanicFalse( StreamConnect(I2S_IN_0, StreamKalimbaSink(0)) );
    /* Plug I2S in slot 1 into port 1 */
    PanicFalse( StreamConnect(I2S_IN_1, StreamKalimbaSink(1)) );
    /* Plug port 0 into I2S out slot 0 */
    PanicFalse( StreamConnect(StreamKalimbaSource(0), I2S_OUT_0) );
    /* Plug port 1 into I2S out slot 1 */
    PanicFalse( StreamConnect(StreamKalimbaSource(1), I2S_OUT_1) );
#endif
}

void led(void)
{
    /* LED indication */
    if(I2S_MASTER)
    {
        LedConfigure(LED_0, LED_ENABLE, 1);
    }
    else
    {
        LedConfigure(LED_1, LED_ENABLE, 1);
    }
}

