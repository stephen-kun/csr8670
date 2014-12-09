/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012

FILE NAME
    fm_rx_api.c        
    
DESCRIPTION
     This file presents an API to the VM application to allow the use of the FM functionality,
     
     The FM hardware used may be changed via the fm_plugin library leaving the API 
     unchanged.
     
*/ 
#include "fm_rx_api.h"

#include <stdlib.h>
#include <print.h>
#include <string.h>
#include <stdio.h>
#include <audio.h>

/*the global FM Rx library data structure*/
static Task gFmRxLib = {0} ;

/****************************************************************************
NAME    
    fmRxInit
    
DESCRIPTION
    initialises the FM hardware and tunes to the default stored channel

RETURNS
    nothing
*/   
void fmRxInit(Task fm_plugin, Task app_task, fm_rx_data_t * fm_rx_data)
{   
    /*Send a message to the plugin to initialise the FM recevier chip*/
    MAKE_FM_MESSAGE(FM_PLUGIN_INIT_MSG);

    /* assign parameters to the message to be passed to the plugin */
    message->app_task = app_task;  
    message->fm_data = fm_rx_data;
    
    /* store the FM receiver task */
    gFmRxLib = fm_plugin;

    /* send messag to plugin handler */
    MessageSend(fm_plugin, FM_PLUGIN_INIT_MSG, message);
}

/****************************************************************************
NAME    
    fmRxTuneUp
    
DESCRIPTION
    starts the autotune process searching in an increasing frequency

RETURNS
    nothing
*/   
void fmRxTuneUp(void)
{    
    if (gFmRxLib)   
    {      
        MessageSend (gFmRxLib, FM_PLUGIN_RX_TUNE_UP_MSG, NULL);
    }
}

/****************************************************************************
NAME    
    fmRxTuneDown
    
DESCRIPTION
    starts the autotune process searching in a decreasing frequency

RETURNS
    nothing
*/   
void fmRxTuneDown(void)
{
    if (gFmRxLib)   
    {      
        MessageSend (gFmRxLib, FM_PLUGIN_RX_TUNE_DOWN_MSG, NULL);
    }
}

/****************************************************************************
NAME    
    fmRxPowerOff
    
DESCRIPTION
    powers down the fm receiver chip and free memory slot being used by fm 
    functionality

RETURNS
    nothing
*/   
void fmRxPowerOff(void)
{
    if (gFmRxLib)   
    {      
        MessageSend (gFmRxLib, FM_PLUGIN_RX_POWER_OFF_MSG, NULL);
    }
}

/****************************************************************************
NAME    
    fmRxUpdateVolume
    
DESCRIPTION
    powers down the fm receiver chip and free memory slot being used by fm 
    functionality

RETURNS
    nothing
*/   
void fmRxUpdateVolume(uint8 vol)
{
    /*Send a message to the plugin to set the FM recevier chip output gain*/
    MAKE_FM_MESSAGE(FM_PLUGIN_RX_UPDATE_VOLUME_MSG);
    
    message->volume = vol;    

    if (gFmRxLib)   
    {      
        MessageSend (gFmRxLib, FM_PLUGIN_RX_UPDATE_VOLUME_MSG, message);
    }

}

/****************************************************************************
NAME    
    fmRxTuneFrequency
    
DESCRIPTION
    tunes the FM reciever to default stored frequency and configures I2S interface

RETURNS
    nothing
*/   
void fmRxTuneFrequency(uint16 frequency)
{
    /*Send a message to the plugin to tell the plugin what frequency to tune to*/
    MAKE_FM_MESSAGE(FMRX_TUNE_FREQ_MSG);   
    message->frequency = frequency;    

    if (gFmRxLib) 
    {        
        MessageSend (gFmRxLib, FMRX_TUNE_FREQ_MSG, message);
    }
}

