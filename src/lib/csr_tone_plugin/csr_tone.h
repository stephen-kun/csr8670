/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_tone_plugin.h

DESCRIPTION
    
    
NOTES
   
*/

#ifndef _CSR_TONE_H_
#define _CSR_TONE_H_

void CsrTonePluginPlayTone ( ringtone_note * tone , Task codec_task , uint16 tone_volume , AudioPluginFeatures features ) ;

void CsrTonePluginStopTone ( void ) ;

void CsrTonePluginToneComplete( void );

#endif

