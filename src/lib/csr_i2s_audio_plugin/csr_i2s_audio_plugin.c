/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2013

FILE NAME
    csr_i2s_audio_plugin.c
DESCRIPTION
    plugin implentation which routes audio output via an external i2s device
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <print.h>
#include <file.h>
#include <stream.h> 
#include <kalimba.h>
#include <kalimba_standard_messages.h>
#include <message.h>
#include <Transform.h>
#include <string.h>
#include <i2c.h>

#include "csr_i2s_audio_plugin.h"
#include "csr_i2s_SSM2518_plugin.h"

/* I2S configuration data */
I2SConfiguration * I2S_config;

/****************************************************************************
DESCRIPTION: CsrI2SInitialisePlugin :

    This function gets a pointer to the application malloc'd slot
    containing the i2s configuration data

PARAMETERS:
    
    pointer to malloc'd slot
    
RETURNS:
    none
*/
void CsrI2SInitialisePlugin(I2SConfiguration * config)
{
    /* keep pointer to I2S pskey configuration in ram, not possible to read from
       ps on the fly everytime as interrupts audio */
    I2S_config = config;         
}


/****************************************************************************
DESCRIPTION: CsrI2SAudioOutputConnect :

    This function configures the I2S interface and connects the audio streams 
    from the dsp to I2S external hardware.

PARAMETERS:
    
    uint32 rate - sample rate of data coming from dsp
    bool   stereo - indicates whether to connect left or left and right channels
    Source dsp_left_port - audio stream from dsp for the left channel audio
    Source dsp_right_port - audio stream from dsp for the left channel audio

RETURNS:
    none
*/
Sink CsrI2SAudioOutputConnect(uint32 rate, bool stereo, Source left_port, Source right_port )
{
    Sink lSink_A;  


    /* initialise the device hardware via the i2c interface, device specific */
    CsrInitialiseI2SDevice(rate);

    /* obtain sink to I2S interface */
    lSink_A = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );

    /* configure the I2S interface operating mode, run in master or slave mode */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_MASTER_MODE, I2S_config->i2s_init_config.master_operation));
    
    /* set the sample rate of the dsp audio data */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_MASTER_CLOCK_RATE, (rate * I2S_config->i2s_init_config.master_clock_scaling_factor))); 

    /* set the sample rate of the dsp audio data */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_SYNC_RATE, rate));
              
    /* left justified or i2s data */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_JSTFY_FORMAT, I2S_config->i2s_init_config.left_or_right_justified));
     
    /* MSB of data occurs on the second SCLK */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_LFT_JSTFY_DLY, I2S_config->i2s_init_config.justified_bit_delay));

    /* data is LEFT channel when word clock is high */    
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_CHNL_PLRTY, 0));
     
    /* number of data bits per sample, 16 */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_BITS_PER_SAMPLE, I2S_config->i2s_init_config.bits_per_sample));
      
    /* if STEREO mode configured then connect the output channel B */
    if(stereo)
    {
        /* obtain sink for channel B I2S interface */
        Sink lSink_B = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0 );  
    
        /* configure the I2S interface operating mode, run in master mode */ 
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_MASTER_MODE, I2S_config->i2s_init_config.master_operation));
        /* set the master clock rate of the dsp audio data, this is  */
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_MASTER_CLOCK_RATE, (rate * I2S_config->i2s_init_config.master_clock_scaling_factor))); 
        /* set the sample rate of the dsp audio data */
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_SYNC_RATE, rate));   
        /* left justified i2s data */
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_JSTFY_FORMAT, I2S_config->i2s_init_config.left_or_right_justified));  
        /* MSB of data occurs on the second SCLK */
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_LFT_JSTFY_DLY, I2S_config->i2s_init_config.justified_bit_delay));
        /* data is LEFT channel when word clock is high */    
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_CHNL_PLRTY, 0));    
        /* number of data bits per sample, 16 */
        PanicFalse(SinkConfigure(lSink_B, STREAM_I2S_BITS_PER_SAMPLE, I2S_config->i2s_init_config.bits_per_sample));
        
        /* synchronise both sinks for channels A & B */
        PanicFalse(SinkSynchronise(lSink_A, lSink_B));
        /* connect dsp ports to i2s interface */
        PanicFalse(StreamConnect(left_port, lSink_A));
        PanicFalse(StreamConnect(right_port, lSink_B));

        PRINT(("I2S: CsrI2SAudioOutputConnect A&B\n"));
    }
    /* mono operation, only connect left port */
    else
    {
        /* connect dsp left channel port only */
        PanicFalse(StreamConnect(left_port, lSink_A));
        PRINT(("I2S: CsrI2SAudioOutputConnect A only\n"));
    }
    
    /* return the sink to the left channel */
    return lSink_A;
}


/****************************************************************************
DESCRIPTION: CsrI2SAudioOutputDisconnect :

    This function disconnects the audio streams from the dsp to I2S external hardware.

PARAMETERS:
    
    bool   stereo - indicates whether to connect left or left and right channels

RETURNS:
    none
*/
void CsrI2SAudioOutputDisconnect(bool stereo)
{
    /* obtain sink to I2S interface */
    Sink lSink_A = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );  


    /* mute the output before disconnecting streams */    
    CsrSetVolumeI2SDevice(0, 0, FALSE);
    
    /* prepare device for shutdown */
    CsrShutdownI2SDevice();

    
    /* if STEREO mode configured then connect the output channel B */
    if(stereo)
    {
        /* obtain sink for channel B I2S interface */
        Sink lSink_B = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0 );  
    
        /* disconnect i2s interface on channels A and B */
        StreamDisconnect(0, lSink_A);
        StreamDisconnect(0, lSink_B);

        SinkClose(lSink_A);
        SinkClose(lSink_B);
        
        PRINT(("I2S: CsrI2SAudioOutputDisconnect A&B\n"));
    }
    /* mono operation, only connect left port */
    else
    {
        /* disconnect i2s on channel A */
        StreamDisconnect(0, lSink_A);
        SinkClose(lSink_A);
        PRINT(("I2S: CsrI2SAudioOutputDisconnect A only\n"));

    }    
}

/****************************************************************************
DESCRIPTION: CsrI2SAudioOutputSetVolume :

    This function sets the volume level of the I2S external hardware if supported
    by the device being used.

PARAMETERS:
    
    bool   stereo - indicates whether to connect left or left and right channels

RETURNS:
    none
*/
void CsrI2SAudioOutputSetVolume(bool stereo, int16 left_volume, int16 right_volume, bool volume_in_dB)
{

    PRINT(("I2S: CsrI2SAudioOutputSetVolume\n"));

    /* mute the output before disconnecting streams */    
    if(stereo)
        CsrSetVolumeI2SDevice(left_volume, right_volume, volume_in_dB);
    else
        CsrSetVolumeI2SDevice(left_volume, left_volume, volume_in_dB);        
}

/****************************************************************************
DESCRIPTION: CsrI2SAudioOutputConnectAdpcm :

    This function configures the I2S interface and connects the audio streams 
    from the dsp to I2S external hardware.

PARAMETERS:
    
    uint32 rate - sample rate of data coming from dsp
    bool   stereo - indicates whether to connect left or left and right channels
    Source dsp_left_port - audio stream from dsp for the left channel audio
    

RETURNS:
    sink
*/
Sink CsrI2SAudioOutputConnectAdpcm(uint32 rate, bool stereo, Source left_port)
{
    Sink lSink_A;
    

    /* initialise the device hardware via the i2c interface, device specific */
    CsrInitialiseI2SDevice(rate);

    /* obtain sink to I2S interface */
    lSink_A = StreamAudioSink(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );

    /* configure the I2S interface operating mode, run in master mode */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_MASTER_MODE, I2S_config->i2s_init_config.master_operation));
    
    /* set the sample rate of the dsp audio data */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_MASTER_CLOCK_RATE, (rate * I2S_config->i2s_init_config.master_clock_scaling_factor))); 

    /* set the sample rate of the dsp audio data */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_SYNC_RATE, rate));              

    /* left justified or i2s data */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_JSTFY_FORMAT, I2S_config->i2s_init_config.left_or_right_justified));
     
    /* MSB of data occurs on the second SCLK */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_LFT_JSTFY_DLY, I2S_config->i2s_init_config.justified_bit_delay));
        
    /* data is LEFT channel when word clock is high */    
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_CHNL_PLRTY, 0));
     
    /* number of data bits per sample, 16 */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_BITS_PER_SAMPLE, I2S_config->i2s_init_config.bits_per_sample));

    /* TX sampling during phase of word clock : high */
    PanicFalse(SinkConfigure(lSink_A, STREAM_I2S_TX_START_SAMPLE, 1));    
      
    /* connect left channel port only */
    PanicFalse(TransformStart(TransformAdpcmDecode(left_port, lSink_A)));

    PRINT(("I2S: CsrI2SAudioOutputConnectAdpcm - A only\n"));

    /* return the sink to the left channel */
    return lSink_A;
}

/****************************************************************************
DESCRIPTION: CsrInitialiseI2SDevice :

    This function configures the I2S device 

PARAMETERS:
    
    uint32 sample_rate - sample rate of data coming from dsp

RETURNS:
    none
*/    
void CsrInitialiseI2SDevice(uint32 rate)
{      
    switch(I2S_config->i2s_init_config.plugin_type)
    {
        case i2s_plugin_none_use_pskey:
            /* use the configuration information retrieved from ps or constant if no ps */
            if((I2S_config->i2s_init_config.i2s_configuration_command_pskey_length)&&
               (I2S_config->i2s_init_config.number_of_initialisation_cmds))
            {
                /* configuration data available */
                uint8 i;                
                uint8 offset = 0;
                
                /* cycle through the configuration messages */
                for(i = 0;i < I2S_config->i2s_init_config.number_of_initialisation_cmds; i++)
                {
#ifdef DEBUG_PRINT_ENABLED
                    uint8 j;

                    PRINT(("I2S: Init Msg %x",I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset]));
                    for(j=0;j<I2S_config->i2s_data_config.data[PACKET_LENGTH + offset];j++)
                    {    
                        PRINT((" %x",I2S_config->i2s_data_config.data[PACKET_DATA + offset+j]));
                    }
                    PRINT(("\n"));                         
#endif                    

                    /* send out packets */
                    PanicFalse(I2cTransfer(I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset], &I2S_config->i2s_data_config.data[PACKET_DATA + offset], (I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1), NULL, 0));
                                        
                    /* move to next packet */
                    offset += (2 + I2S_config->i2s_data_config.data[PACKET_LENGTH  + offset]);
                }
            }
            /* no configuration data available so no need to send any i2c commands */
            
        break;
            
        case i2s_plugin_ssm2518:
            CsrInitialiseI2SDevice_SSM2518(rate);
        break;
    }
}


/****************************************************************************
DESCRIPTION: CsrShutdownI2SDevice :

    This function shuts down the I2S device 

PARAMETERS:
    
    none
    
RETURNS:
    none
*/    
void CsrShutdownI2SDevice(void)
{      
    PRINT(("I2S: Send Shutdown Msg\n"));
    
    /* determine I2S plugin type */
    switch(I2S_config->i2s_init_config.plugin_type)
    {
        case i2s_plugin_none_use_pskey:
            /* use the configuration information retrieved from ps or constant if no ps */
            if((I2S_config->i2s_init_config.i2s_configuration_command_pskey_length)&&
               (I2S_config->i2s_init_config.number_of_shutdown_cmds))
            {
                /* configuration data available */
                uint8 i;                
                uint8 offset = I2S_config->i2s_init_config.shutdown_cmds_offset;
                
                /* cycle through the configuration messages */
                for(i = 0;i < I2S_config->i2s_init_config.number_of_shutdown_cmds; i++)
                {
#ifdef DEBUG_PRINT_ENABLED
                    uint8 j;

                    PRINT(("I2S: Shutdown Msg %x",I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset]));
                    for(j=0;j<I2S_config->i2s_data_config.data[PACKET_LENGTH + offset];j++)
                    {    
                        PRINT((" %x",I2S_config->i2s_data_config.data[PACKET_DATA + offset+j]));
                    }
                    PRINT(("\n"));                         
#endif                    

                    /* send out packets */
                    PanicFalse(I2cTransfer(I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset], &I2S_config->i2s_data_config.data[PACKET_DATA + offset], (I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1), NULL, 0));
                    
                    /* move to next packet */
                    offset += (2 + I2S_config->i2s_data_config.data[PACKET_LENGTH  + offset]);
                }
            }
            /* no configuration data available so no need to send any i2c commands */
            
        break;
            
        case i2s_plugin_ssm2518:
            /* nothing to do for this variant */
        break;
    }
}
    
/****************************************************************************
DESCRIPTION: CsrSetVolumeI2SDevice 

    This function sets the I2S device volume via the I2C

PARAMETERS:
    
    uint16 volume - volume level required

RETURNS:
    none
*/    
void CsrSetVolumeI2SDevice(int16 left_vol, int16 right_vol, bool volume_in_dB)
{
     int32 volume = 0;
     int16 range = 0;
                 
     /* if using dB scaling,scale volumes to a base of 2 to reduce stack usage volume is converted from -1/60dB to
        1/10dB * 0.853 which makes full scale (-120dB) of 1024 counts to simplify the maths required
        to generate scaled volume level to be sent over i2c interface */
     if(volume_in_dB)          
     {
         PRINT(("I2S: SetVol dB[%x] ",left_vol)); 

         /* reduce resolution of dB values from 1/60th to 1/10th */
         left_vol /= 6;
         right_vol /= 6;
         /* multiply by 0.8533 to reduce to the range of 0 to 1024 */
         left_vol = (((0 - left_vol) * 17)/20);
         right_vol = (((0 - right_vol) * 17)/20);

         PRINT(("scaled[%x]\n",left_vol)); 
     }

     /* determine i2s plugin type in use */
     switch(I2S_config->i2s_init_config.plugin_type)
     {
        case i2s_plugin_none_use_pskey:

            /* use the configuration information retrieved from ps or constant if no ps */
            if((I2S_config->i2s_init_config.i2s_configuration_command_pskey_length)&&
               (I2S_config->i2s_init_config.number_of_volume_cmds))
            {
                /* volume commands data available */
                uint8 offset = I2S_config->i2s_init_config.volume_cmds_offset;                                                          
                                
                /* set left or master channel volume */
                if(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset])
                {
                   /* packet is valid, copy packet into ram, replace the volume level and send via i2c */
                   uint8 * data = malloc(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1);
                    
                   /* if memory available */
                   if(data)
                   {  
                      /* copy packet data excluding the id byte - normally two bytes */
                      memcpy( data, &I2S_config->i2s_data_config.data[PACKET_DATA + offset],(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1)); 
                            
                      /* scale volume to one of 16 available steps*/
                      if(I2S_config->i2s_init_config.volume_range_max < I2S_config->i2s_init_config.volume_range_min)
                      {
                          /* inverted range */
                          if(volume_in_dB)
                          { 
                              /* determine ext codec volume range */
                              range = (I2S_config->i2s_init_config.volume_range_min - I2S_config->i2s_init_config.volume_range_max);
                              /* convert from dB to volume range, left_vol is scaled as + 1/10dB * 0.85 which makes it divisible by 1024 */                                                                         
                              volume = (((uint32)range * (uint32)left_vol) / 1024);
                              PRINT(("I2S: Left Vol Inv dB = %d  vol = %x range = %x\n",left_vol,(uint16)volume,range)); 
                          }
                          else
                          {
                              volume = (((I2S_config->i2s_init_config.volume_range_min - I2S_config->i2s_init_config.volume_range_max) * left_vol) / CODEC_STEPS);
                              volume = (I2S_config->i2s_init_config.volume_range_min - volume);
                              PRINT(("I2S: Left Vol Inv  = %x \n",(uint16)volume)); 
                          }
                      }
                      /* non inverted range */
                      else
                      {                     
                          /* non inverted range */
                          if(volume_in_dB)
                          {
                              /* determine ext codec range */
                              range = (I2S_config->i2s_init_config.volume_range_max - I2S_config->i2s_init_config.volume_range_min);
                              /* convert from dB to volume range, left_vol is scaled as 1/10dB * 0.85 which makes it divisible by 1024 */                                                                         
                              volume = (((uint32)range * (uint32)left_vol) / 1024);
                              PRINT(("I2S: Left Vol dB  = %x range = %x\n",(uint16)volume,range)); 
                          }
                          else 
                          {
                              volume = (((I2S_config->i2s_init_config.volume_range_max - I2S_config->i2s_init_config.volume_range_min) * left_vol) / CODEC_STEPS);
                              PRINT(("I2S: Left Vol = %x \n",(uint16)volume)); 
                          }
                      }
                              
                      /* replace volume information */
                      if(I2S_config->i2s_init_config.volume_no_of_bits == 8)
                      {
                            /* replace a single byte of volume data */  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]] = volume;                         
                      }
                      /* if more than 16 bits and less than or equal to 24 bits */
                      else if((I2S_config->i2s_init_config.volume_no_of_bits > 16)&&(I2S_config->i2s_init_config.volume_no_of_bits <= 24))
                      {
                            /* replace three bytes of volume data */
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+1] = ((volume >> 16) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+2] = ((volume >> 8) & 0xff);
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+3] = (volume & 0xff);                                                  
                            
                      }
                      /* if more than 24 bits and less than or equal to 32 bits */
                      else if((I2S_config->i2s_init_config.volume_no_of_bits > 24)&&(I2S_config->i2s_init_config.volume_no_of_bits <= 32))
                      {
                            /* replace four bytes of volume data */
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]] = ((volume >> 24) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+1] = ((volume >> 16) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+2] = ((volume >> 8) & 0xff);
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+3] = (volume & 0xff);                                                  
                            
                      }
                      /* assume 16 bits default */
                      else
                      {
                            /* replace two bytes of volume data */
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]] = ((volume >> 8) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+1] = (volume & 0x00ff);                                                  
                      }

#ifdef DEBUG_PRINT_ENABLED
                      {
                        uint8 j;

                        PRINT(("I2S: Vol Msg Left %x",I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset]));
                        for(j=1;j<(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1);j++)
                        {    
                            PRINT((" %x",data[j]));
                        }
                        PRINT(("\n"));                         
                      }
#endif                    

                      /* send out packets, Packet Length includes ID byte so subtract 1 from length */
                      PanicFalse(I2cTransfer(I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset], data, (I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1), NULL, 0));
                      
                      /* dispose of temporary malloc'd memory */
                      free (data);
                   }
                   /* move to next packet */
                   offset += (2 + I2S_config->i2s_data_config.data[PACKET_LENGTH  + offset]);
                }
                
                /* is a right channel volume available? */
                if((I2S_config->i2s_init_config.number_of_volume_cmds > 1)&&(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]))
                {
                   /* packet is valid, copy packet into ram, replace the volume level and send via i2c */
                   uint8 * data = malloc(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1);
                    
                   /* if memory available */
                   if(data)
                   {
                      /* copy packet data excluding the id byte - normally two bytes */
                      memcpy( data, &I2S_config->i2s_data_config.data[PACKET_DATA + offset],(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1)); 
                              
                      /* scale volume to one of 16 available steps or dB range */
                      if(I2S_config->i2s_init_config.volume_range_max < I2S_config->i2s_init_config.volume_range_min)
                      {
                          /* inverted range */
                          if(volume_in_dB)
                          {
                               /* determine ext codec volume range */
                              range = (I2S_config->i2s_init_config.volume_range_min - I2S_config->i2s_init_config.volume_range_max);
                              /* convert from dB to volume range, right_vol is scaled as 1/10dB * 0.853 which makes it divisible by 1024 */                                                                         
                              volume = (((uint32)range * (uint32)right_vol) / 1024);
                          }
                          else
                          {
                                volume = (((I2S_config->i2s_init_config.volume_range_min - I2S_config->i2s_init_config.volume_range_max) * right_vol) / CODEC_STEPS);
                                volume = (I2S_config->i2s_init_config.volume_range_min - volume);
                          }
                      }
                      /* not inverted */
                      else
                      {                     
                          /* non inverted range */
                          if(volume_in_dB)
                          {
                              /* determine ext codec range */
                              range = (I2S_config->i2s_init_config.volume_range_max - I2S_config->i2s_init_config.volume_range_min);
                              /* convert from dB to volume range, right_vol is scaled as 1/10dB * 0.853 which makes it divisible by 1024 */                                                                         
                              volume = (((uint32)range * (uint32)right_vol) / 1024);
                          }
                          else 
                          {
                              volume = (((I2S_config->i2s_init_config.volume_range_max - I2S_config->i2s_init_config.volume_range_min) * right_vol) / CODEC_STEPS);
                          }
                      }                              

                      /* replace volume information */
                      if(I2S_config->i2s_init_config.volume_no_of_bits == 8)
                      {
                            /* replace a single byte of volume data */  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]] = volume;                         
                      }
                      /* if more than 16 bits and less than or equal to 24 bits */
                      else if((I2S_config->i2s_init_config.volume_no_of_bits > 16)&&(I2S_config->i2s_init_config.volume_no_of_bits <= 24))
                      {
                            /* replace three bytes of volume data */
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+1] = ((volume >> 16) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+2] = ((volume >> 8) & 0xff);
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+3] = (volume & 0xff);                                                  
                            
                      }
                      /* if more than 24 bits and less than or equal to 32 bits */
                      else if((I2S_config->i2s_init_config.volume_no_of_bits > 24)&&(I2S_config->i2s_init_config.volume_no_of_bits <= 32))
                      {
                            /* replace four bytes of volume data */
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]] = ((volume >> 24) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+1] = ((volume >> 16) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+2] = ((volume >> 8) & 0xff);
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+3] = (volume & 0xff);                                                  
                            
                      }
                      /* assume 16 bits default */
                      else
                      {
                            /* replace two bytes of volume data */
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]] = ((volume >> 8) & 0xff);                                                  
                            data[I2S_config->i2s_data_config.data[PACKET_VOLUME_OFFSET + offset]+1] = (volume & 0x00ff);                                                  
                      }

#ifdef DEBUG_PRINT_ENABLED
                      {
                        uint8 j;

                        PRINT(("I2S: Vol Msg Right %x",I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset]));
                        for(j=1;j<(I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1);j++)
                        {    
                            PRINT((" %x",data[j]));
                        }
                        PRINT(("\n"));                         
                      }
#endif                    

                      /* send out packets, Packet Length includes ID byte so subtract 1 from length */
                      PanicFalse(I2cTransfer(I2S_config->i2s_data_config.data[PACKET_ID_BYTE + offset], data, (I2S_config->i2s_data_config.data[PACKET_LENGTH + offset]-1), NULL, 0));
                      
                      /* dispose of temporary malloc'd memory */
                      free (data);
                   }
                   /* move to next packet */
                   offset += (2 + I2S_config->i2s_data_config.data[PACKET_LENGTH  + offset]);
                   
                   
               }
           }
         break;
        
        case i2s_plugin_ssm2518:
            CsrSetVolumeI2SDevice_SSM2518(left_vol, right_vol, volume_in_dB);
        break;
    }
}

/****************************************************************************
DESCRIPTION: CsrI2SMusicResamplingFrequency 

    This function returns the current resampling frequency for music apps,

PARAMETERS:
    
    none

RETURNS:
    frequency or 0 indicating no resampling required
*/    
uint16 CsrI2SMusicResamplingFrequency(void)
{
    return I2S_config->i2s_init_config.music_resampling_frequency;
}

/****************************************************************************
DESCRIPTION: CsrI2SVoiceResamplingFrequency 

    This function returns the current resampling frequency for voice apps,

PARAMETERS:
    
    none

RETURNS:
    frequency or 0 indicating no resampling required
*/    
uint16 CsrI2SVoiceResamplingFrequency(void)
{
    return I2S_config->i2s_init_config.voice_resampling_frequency;
}

/****************************************************************************
DESCRIPTION: CsrI2SAudioInputConnect 

    This function configures and connects the I2S to the dsp input ports 

PARAMETERS:
    
    none

RETURNS:
    none
*/    
void CsrI2SAudioInputConnect(uint32 rate, bool stereo, Sink left_port, Sink right_port )
{
    Source lSource_A;  

    /* initialise the device hardware via the i2c interface, device specific */
    CsrInitialiseI2SDevice(rate);

    /* obtain source to I2S interface */
    lSource_A = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_1 );

    /* configure the I2S interface operating mode, run in master or slave mode */
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_MASTER_MODE, I2S_config->i2s_init_config.master_operation));
    
    /* set the sample rate of the dsp audio data */
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_MASTER_CLOCK_RATE, (rate * I2S_config->i2s_init_config.master_clock_scaling_factor))); 

    /* set the sample rate of the dsp audio data */
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_SYNC_RATE, rate));
              
    /* left justified or i2s data */
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_JSTFY_FORMAT, I2S_config->i2s_init_config.left_or_right_justified));
     
    /* MSB of data occurs on the second SCLK */
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_LFT_JSTFY_DLY, I2S_config->i2s_init_config.justified_bit_delay));

    /* data is LEFT channel when word clock is high */    
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_CHNL_PLRTY, 0));
     
    /* number of data bits per sample, 16 */
    PanicFalse(SourceConfigure(lSource_A, STREAM_I2S_BITS_PER_SAMPLE, I2S_config->i2s_init_config.bits_per_sample));
      
    /* if STEREO mode configured then connect the output channel B */
    if(stereo)
    {
        /* obtain source for channel B I2S interface */
        Source lSource_B = StreamAudioSource(AUDIO_HARDWARE_I2S, AUDIO_INSTANCE_0, AUDIO_CHANNEL_SLOT_0 );  
    
        /* configure the I2S interface operating mode, run in master mode */ 
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_MASTER_MODE, I2S_config->i2s_init_config.master_operation));
        /* set the master clock rate of the dsp audio data, this is  */
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_MASTER_CLOCK_RATE, (rate * I2S_config->i2s_init_config.master_clock_scaling_factor))); 
        /* set the sample rate of the dsp audio data */
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_SYNC_RATE, rate));   
        /* left justified i2s data */
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_JSTFY_FORMAT, I2S_config->i2s_init_config.left_or_right_justified));  
        /* MSB of data occurs on the second SCLK */
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_LFT_JSTFY_DLY, I2S_config->i2s_init_config.justified_bit_delay));
        /* data is LEFT channel when word clock is high */    
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_CHNL_PLRTY, 0));    
        /* number of data bits per sample, 16 */
        PanicFalse(SourceConfigure(lSource_B, STREAM_I2S_BITS_PER_SAMPLE, I2S_config->i2s_init_config.bits_per_sample));
        
        /* synchronise both sources for channels A & B */
        PanicFalse(SourceSynchronise(lSource_A, lSource_B));
        /* connect dsp i2s interface to ports */
        PanicFalse(StreamConnect(lSource_A, left_port));
        PanicFalse(StreamConnect(lSource_B, right_port));

        PRINT(("I2S: CsrI2SAudioInputConnect A&B\n"));
    }
    /* mono operation, only connect left port */
    else
    {
        /* connect dsp left channel port only */
        PanicFalse(StreamConnect(lSource_A, left_port));
        PRINT(("I2S: CsrI2SAudioInputConnect A only\n"));
    }
}

