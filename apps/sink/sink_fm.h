/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012-2014

FILE NAME
    sink_fm.h
    
DESCRIPTION
    This file provides interfaces between sink fm app and fm library
    
    
*/

#ifndef SINK_FM_H
#define SINK_FM_H

#ifdef ENABLE_FM
#include <sink.h>
#include <fm_plugin_if.h>

#define FM_SINK       ((Sink)0xFF00)

#define FM_RATE       48000

#define INVALID_FREQ (0x0000)
#define FM_DISPLAY_STR_LEN (12)

typedef enum
{
    FM_SHOW_STATION,
    FM_ADD_FAV_STATION, /*Add special char for favourite station*/
    FM_DEL_FAV_STATION
}fm_display_type;

typedef enum
{
    FM_ENABLE_RX,    
    FM_ENABLE_TX, 
    FM_ENABLE_RX_TX
} fm_mode;

typedef struct
{
    /* current FM operating state, on or off */
    bool fmRxOn;
    /* currently tuned freq*/
    uint16 fmRxTunedFreq;
    /* current FM audio sink */
    Sink sink;
    /* stored frequencies */
    fm_stored_freq fmStoredFreq;
    
    /* pointer to fm lib plugin data */
    fm_rx_data_t *fm_plugin_data;
} fm_data;


/****************************************************************************
NAME    
    FmInit
    
DESCRIPTION
    initialises the memory to be used by the fm library

RETURNS
    nothing
*/   
void fmInit(void);

/****************************************************************************
NAME    
    sinkFmInit

DESCRIPTION
    Initialises the FM RX chip

RETURNS
    void
*/
void sinkFmInit(fm_mode mode);


/****************************************************************************
NAME    
    sinkFmRxTuneUp

DESCRIPTION
    Tune the FM RX for higher frequencies

RETURNS
    void
*/
void sinkFmRxTuneUp(void);

/****************************************************************************
NAME    
    sinkFmRxTuneDown

DESCRIPTION
    Tune the FM RX for lower frequencies

RETURNS
    void
*/
void sinkFmRxTuneDown(void);


/****************************************************************************
NAME    
    sinkFmDisplayFreq
    
DESCRIPTION
    utility function for displaying FM station on LCD 
    A favourite station will be indicated by appending a (*)

RETURNS
    nothing
*/   
void sinkFmDisplayFreq(uint16 freq, fm_display_type type);

/****************************************************************************
NAME    
    sinkFmGetIndex
    
DESCRIPTION
    utility function to get a index for requested operation
    In case of STORE, returns a free index.
    In case of ERASE, returns index corresponding to the requested freq

RETURNS
    index in PS key 
*/   
uint8 sinkFmGetIndex(fm_stored_freq *stored_freq, uint16 freq);

/****************************************************************************
NAME    
    sinkFmUpdateAtIndex
    
DESCRIPTION
    utility function to update freq in Ps key at requested index

RETURNS
    nothing
*/   
void sinkFmUpdateAtIndex(uint8 index, uint16 freq, fm_stored_freq *stored_freq);


/****************************************************************************
NAME    
    sinkFmGetNextStoredFreq
    
DESCRIPTION
    utility function to get the next valid freq to tune to from the stored list

RETURNS
    frequency to tune to
*/  
uint16 sinkFmGetNextStoredFreq(uint16 curr_freq, fm_stored_freq *stored_freq);


/****************************************************************************
NAME    
    sinkFmRxStoreFreq

DESCRIPTION
    Store the currently tuned frequency into PS key

RETURNS
    void
*/
void sinkFmRxStoreFreq(uint16 freq);


/****************************************************************************
NAME    
    sinkFmRxTuneToStore

DESCRIPTION
    Get the stored frequency from PS key and tune to it

RETURNS
    void
*/
void sinkFmRxTuneToStore(uint16 freq);


/****************************************************************************
NAME    
    sinkFmRxEraseFreq

DESCRIPTION
    Erases the stored frequency from PS key

RETURNS
    void
*/
void sinkFmRxEraseFreq(uint16 freq);


/****************************************************************************
NAME    
    sinkFmRxAudioConnect

DESCRIPTION
    Handles connection and tuning of FM RX

RETURNS
    void
*/
void sinkFmRxAudioConnect(void);


/****************************************************************************
NAME    
    sinkFmRxAudioDisconnect

DESCRIPTION
    Handles disconnection of FM RX

RETURNS
    void
*/
void sinkFmRxAudioDisconnect(void);


/****************************************************************************
NAME    
    sinkFmRxUpdateVolume

DESCRIPTION
    Handles volume updates for FM RX

RETURNS
    void
*/
void sinkFmRxUpdateVolume(uint8 vol);


/****************************************************************************
NAME 
    sinkFmAudioSinkMatch
    
DESCRIPTION
    Compare sink to FM audio sink.
    
RETURNS
    TRUE if Sink matches, FALSE otherwise
*/ 
bool sinkFmAudioSinkMatch(Sink sink);


/****************************************************************************
NAME 
    IsSinkFmRxOn
    
DESCRIPTION
    Check if FM is active
    
RETURNS
    TRUE if FM is ON, FALSE otherwise
*/ 
bool IsSinkFmRxOn(void);

/****************************************************************************
NAME    
    sinkFmRxPowerOff

DESCRIPTION
    Power off the FM RX

RETURNS
    void
*/
void sinkFmRxPowerOff(void);


#endif

#endif /*SINK_FM_H*/
