/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2010

FILE NAME
    fm_rx_api.h
    
DESCRIPTION
    header file for the fm library api
*/

/*!
@file   fm_rx_api.h
@brief  Header file for the fm library.
    This defines the Application Programming interface to the FM plugin.
    
    i.e. the interface between the VM application and the FM plugin.
*/

#ifndef _FM_RX_API_H_
#define _FM_RX_API_H_

#include <message.h>
#include "fm_plugin_if.h"

/****************************************************************************
NAME    
    fmRxInit
    
DESCRIPTION
    initialises the FM hardware and tunes to the default stored channel

RETURNS
    nothing
*/   
void fmRxInit(Task fm_plugin, Task app_task, fm_rx_data_t * fm_rx_data);

/****************************************************************************
NAME    
    fmRxTuneUp
    
DESCRIPTION
    starts the autotune process searching in an increasing frequency

RETURNS
    nothing
*/   
void fmRxTuneUp(void);

/****************************************************************************
NAME    
    fmRxTuneDown
    
DESCRIPTION
    starts the autotune process searching in a decreasing frequency

RETURNS
    nothing
*/   
void fmRxTuneDown(void);

/****************************************************************************
NAME    
    fmRxPowerOff
    
DESCRIPTION
    powers down the fm receiver chip and free memory slot being used by fm 
    functionality

RETURNS
    nothing
*/   
void fmRxPowerOff(void);

/****************************************************************************
NAME    
    fmRxUpdateVolume
    
DESCRIPTION
    set the volume output from fm receiver 

RETURNS
    nothing
*/   
void fmRxUpdateVolume(uint8 vol);

/****************************************************************************
NAME    
    fmRxTuneFrequency
    
DESCRIPTION
    tunes the FM reciever to default stored frequency and configures I2S interface

RETURNS
    nothing
*/   
void fmRxTuneFrequency(uint16 frequency);

#endif /*_FM_RX_API_H_*/
