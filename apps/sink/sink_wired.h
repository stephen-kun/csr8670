/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_wired.h
    
DESCRIPTION
    
*/
#ifndef _SINK_WIRED_H_
#define _SINK_WIRED_H_

#include <stdlib.h>

/****************************************************************************
NAME 
    wiredAudioInit
    
DESCRIPTION
    Set up wired audio PIOs and configuration
    
RETURNS
    void
*/ 
#ifdef ENABLE_WIRED
void wiredAudioInit(void);
#else
#define wiredAudioInit() ((void)(0))
#endif

/****************************************************************************
NAME 
    wiredAudioRoute
    
DESCRIPTION
    Route wired audio stream through DSP
    
RETURNS
    void
*/ 
#ifdef ENABLE_WIRED
void wiredAudioRoute(Sink audio_sink, int16 master_volume, AUDIO_SINK_T variant_type);
#else
#define wiredAudioRoute(x) ((void)(0))
#endif  
        
/****************************************************************************
NAME 
    analogAudioRoute
    
DESCRIPTION
    Route analog audio stream through DSP
    
RETURNS
    void
*/ 
#ifdef ENABLE_WIRED
void analogAudioRoute(void);
#else
#define analogAudioRoute() ((void)(0))
#endif  
        
        
/****************************************************************************
NAME 
    spdifAudioRoute
    
DESCRIPTION
    Route spdif audio stream through DSP
    
RETURNS
    void
*/ 
#ifdef ENABLE_WIRED
void spdifAudioRoute(void);
#else
#define spdifAudioRoute() ((void)(0))
#endif  


/****************************************************************************
NAME 
    wiredAudioDisconnect
    
DESCRIPTION
    Force disconnect of wired audio
    
RETURNS
    void
*/ 
#ifdef ENABLE_WIRED
void wiredAudioDisconnect(void);
#else
#define wiredAudioDisconnect() ((void)(0))
#endif


/****************************************************************************
NAME 
    analogAudioSinkMatch
    
DESCRIPTION
    Compare sink to analog audio sink.
    
RETURNS
    TRUE if Sink matches, FALSE otherwise
*/ 
#ifdef ENABLE_WIRED
bool analogAudioSinkMatch(Sink sink);
#else
#define analogAudioSinkMatch(x) (FALSE)
#endif

/****************************************************************************
NAME 
    spdifAudioSinkMatch
    
DESCRIPTION
    Compare sink to spdif audio sink.
    
RETURNS
    TRUE if Sink matches, FALSE otherwise
*/ 
#ifdef ENABLE_WIRED
bool spdifAudioSinkMatch(Sink sink);
#else
#define spdifAudioSinkMatch(x) (FALSE)
#endif

/****************************************************************************
NAME 
    wiredAudioUpdateVolume
    
DESCRIPTION
    Adjust wired audio volume if currently being routed
    
RETURNS
    TRUE if wired audio being routed, FALSE otherwise
*/ 
#ifdef ENABLE_WIRED
bool wiredAudioUpdateVolume(volume_direction dir);
#else
#define wiredAudioUpdateVolume(x) (FALSE)
#endif

/****************************************************************************
NAME
    wiredAudioSetVolume

DESCRIPTION
    Set Wired audio volume

RETURNS
    void
*/
#ifdef ENABLE_WIRED
void wiredAudioSetVolume(void);
#else
#define  wiredAudioSetVolume(void) (FALSE)
#endif


/****************************************************************************
NAME 
    wiredAudioCheckDeviceTrimVol
    
DESCRIPTION
    Adjust wired audio volume if currently being routed
    
RETURNS
    TRUE if wired audio being routed, FALSE otherwise
*/ 
#ifdef ENABLE_WIRED
bool wiredAudioCheckDeviceTrimVol(volume_direction dir, tws_device_type tws_device);
#else
#define wiredAudioCheckDeviceTrimVol(dir, tws_device) (FALSE)
#endif


/****************************************************************************
NAME 
    analogAudioConnected
    
DESCRIPTION
    Determine if wired audio input is connected
    
RETURNS
    TRUE if connected, otherwise FALSE
*/ 
#ifdef ENABLE_WIRED
bool analogAudioConnected(void);
#else
#define analogAudioConnected()   (FALSE)
#endif

/****************************************************************************
NAME 
    analogGetAudioSink
    
DESCRIPTION
    Check analog state and return sink if available
    
RETURNS
    Sink if available, otherwise NULL
*/ 
#ifdef ENABLE_WIRED
Sink analogGetAudioSink(void);
#else
#define analogGetAudioSink() ((void)(0))
#endif

/****************************************************************************
NAME 
    analogGetAudioRate
    
DESCRIPTION
    Obtains the current defined sample rate for wired audio
    
RETURNS
    None
*/ 
#ifdef ENABLE_WIRED
void analogGetAudioRate (uint16 *rate);
#else
#define analogGetAudioRate(x) (*(x) = 0)
#endif

/****************************************************************************
NAME 
    spdifAudioConnected
    
DESCRIPTION
    Determine if spdif audio input is connected
    
RETURNS
    TRUE if connected, otherwise FALSE
*/ 
#ifdef ENABLE_WIRED
bool spdifAudioConnected(void);
#else
#define spdifAudioConnected()   (FALSE)
#endif
Sink spdifGetAudioSink(void);

/****************************************************************************
NAME 
    analogAudioCanPowerOff
    
DESCRIPTION
    Determine if analog audio blocks power off
    
RETURNS
    TRUE if device can power off, otherwise FALSE
*/ 
#define analogAudioCanPowerOff() ((!analogAudioConnected()) || powerManagerIsVbatCritical())

/****************************************************************************
NAME 
    spdifAudioCanPowerOff
    
DESCRIPTION
    Determine if spdif audio blocks power off
    
RETURNS
    TRUE if device can power off, otherwise FALSE
*/ 
#define spdifAudioCanPowerOff() ((!spdifAudioConnected()) || powerManagerIsVbatCritical())

#endif /* _SINK_WIRED_H_ */
