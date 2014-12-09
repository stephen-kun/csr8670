/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2013

FILE NAME
    csr_i2s_SSM2518_plugin.c
DESCRIPTION
    plugin implentation which has chip specific i2c commands to configure the 
    i2s audio output device for use 
NOTES
*/

#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <panic.h>
#include <file.h>
#include <print.h>
#include <stream.h> 
#include <kalimba.h>
#include <kalimba_standard_messages.h>
#include <message.h>
#include <Transform.h>
#include <string.h>
#include <i2c.h>
#include <stdio.h>
 
#include "csr_i2s_SSM2518_plugin.h"

/****************************************************************************
DESCRIPTION: CsrInitialiseI2SDevice :

    This function configures the I2S device 

PARAMETERS:
    
    uint32 sample_rate - sample rate of data coming from dsp

RETURNS:
    none
*/    
void CsrInitialiseI2SDevice_SSM2518(uint32 sample_rate)
{
    uint8 i2c_data[2];
    /*uint16 ack;*/
   
    
    /* set to normal operation with external MCLK, configure for NO_BLCK, MCLK is 64 * sample rate */
    i2c_data[0] = RESET_POWER_CONTROL;
    i2c_data[1] = (S_RST|SPWDN); 
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));     

    /* operate at 256 * fs to allow operation at 8KHz */
    i2c_data[0] = RESET_POWER_CONTROL;
    /* determine sample rate */
    if(sample_rate <= 16000)
        i2c_data[1] = 0x00;         
    else if(sample_rate <= 32000)       
        i2c_data[1] = 0x02;         
    else if(sample_rate <= 48000)       
        i2c_data[1] = 0x04;         
    else 
        i2c_data[1] = 0x08;         
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));     

    /* set to automatic sample rate setting */
    i2c_data[0] = EDGE_CLOCK_CONTROL;
    i2c_data[1] = ASR;         
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));     

    /* set sample rate and to use i2s with default settings */
    i2c_data[0] = SERIAL_INTERFACE_SAMPLE_RATE_CONTROL;
    /* determine sample rate */
    if(sample_rate <= 12000)
        i2c_data[1] = 0x00;         
    else if(sample_rate <= 24000)       
        i2c_data[1] = 0x01;         
    else if(sample_rate <= 48000)       
        i2c_data[1] = 0x02;         
    else 
        i2c_data[1] = 0x03;         
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));     
    
    /* set to ext b_clk, rising edge, msb first */
    i2c_data[0] = SERIAL_INTERFACE_CONTROL;
    i2c_data[1] = 0x00;  
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));     

    /* set the master mute control to on */
    i2c_data[0] = VOLUME_MUTE_CONTROL;
    i2c_data[1] = M_MUTE;
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));     
}

/****************************************************************************
DESCRIPTION: CsrSetVolumeI2SDevice 

    This function sets the I2S device volume via the I2C

PARAMETERS:
    
    int16 volume - volume level required scaled as 0 to +1024 corresponding to 0 to -120dB

RETURNS:
    none
*/    
void CsrSetVolumeI2SDevice_SSM2518(int16 left_vol, int16 right_vol, bool volume_in_dB)
{
    int32 volume=0;
    uint8 i2c_data[2];

    PRINT(("VP: SSM2518 SetVol L[%x] R[%x] dB[%x]\n",left_vol, right_vol,volume_in_dB));

    /* set the left volume level */
    i2c_data[0] = LEFT_VOLUME_CONTROL;
    if(volume_in_dB)
    {
        /* left_vol is scaled 0 to 8192 to simplify the maths and reduce stack usage,
           0 = 0dB, 1024 = -1024dB, to convert this to the 0 to 255 required by the SSM2518
           simply divide by 4 */               
        volume = (left_vol/4);
        /* convert from dB to i2s amp range of 0 to 255 where 0 = max and 255 = min */
        i2c_data[1] = volume;             
    }
    else
        i2c_data[1] = (0xff - (((left_vol & 0xf)*0xff)/CODEC_STEPS));

    PRINT(("VP: SSM2518 SetVol data [%x]\n", i2c_data[1]));

    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));
    
    /* set the right volume level */
    i2c_data[0] = RIGHT_VOLUME_CONTROL;
    if(volume_in_dB)
    {
        /* right_vol is scaled 0 to 8192 to simplify the maths and reduce stack usage,
           0 = 0dB, 1024 = -120dB, to convert this to the 0 to 255 required by the SSM2518
           simply divide by 4 */               
        volume = (right_vol/4);
        /* convert from dB to i2s amp range of 0 to 255 where 0 = max and 255 = min */
        i2c_data[1] = volume;             
    }
    else
        i2c_data[1] = (0xff - (((right_vol & 0xf)*0xff)/CODEC_STEPS));
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));
    
    /* set the master mute control */
    i2c_data[0] = VOLUME_MUTE_CONTROL;
    /* if volumes are zero then set master mute */
    if((left_vol == 0xff) && (right_vol == 0xff))
        i2c_data[1] = 0x01;
    /* otherwise clear the master mute */    
    else
        i2c_data[1] = 0x00;
    PanicFalse(I2cTransfer(ADDR_WRITE, i2c_data, 2, NULL, 0));
}


