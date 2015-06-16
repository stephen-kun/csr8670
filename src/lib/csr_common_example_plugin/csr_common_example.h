/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_common_example.h

DESCRIPTION
    
    
NOTES
   
*/

#ifndef _CSR_COMMON_EXAMPLE_H_
#define _CSR_COMMON_EXAMPLE_H_

/*plugin functions*/
void CsrExamplePluginConnect( ExamplePluginTaskdata *task, Sink audio_sink ,AUDIO_SINK_T sink_type , Task codec_task , uint16 volume , uint32 rate , bool stereo , AUDIO_MODE_T mode , const void * params ) ;
void CsrExamplePluginDisconnect(ExamplePluginTaskdata *task) ;
void CsrExamplePluginSetVolume( ExamplePluginTaskdata *task, uint16 volume ) ;
void CsrExamplePluginSetMode ( ExamplePluginTaskdata *task, AUDIO_MODE_T mode , const void * params ) ;
void CsrExamplePluginPlayTone (ExamplePluginTaskdata *task, ringtone_note * tone , Task codec_task , uint16 tone_volume , bool stereo) ;
void CsrExamplePluginStopTone (  void) ;

/*internal plugin message functions*/
void CsrExamplePluginInternalMessage( ExamplePluginTaskdata *task ,uint16 id , Message message ) ;

void CsrExamplePluginToneComplete (ExamplePluginTaskdata *task) ;
#endif

