/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_ag_audio.h

DESCRIPTION
    
    
NOTES
   
*/

#ifndef _CSR_AG_AUDIO_H_
#define _CSR_AG_AUDIO_H_

/*plugin functions*/
void CsrAgAudioPluginConnect( CsrAgAudioPluginTaskData *task, Sink audio_sink ,AUDIO_SINK_T sink_type , Task codec_task , uint16 volume , uint32 rate , bool stereo , AUDIO_MODE_T mode , const void * params , Task app_task) ;
void CsrAgAudioPluginDisconnect(CsrAgAudioPluginTaskData *task) ;
void CsrAgAudioPluginSetVolume( CsrAgAudioPluginTaskData *task, uint16 volume ) ;
void CsrAgAudioPluginSetMode ( CsrAgAudioPluginTaskData *task, AUDIO_MODE_T mode , const void * params ) ;
void CsrAgAudioPluginPlayTone (CsrAgAudioPluginTaskData *task, ringtone_note * tone , Task codec_task , uint16 tone_volume , bool stereo) ;
void CsrAgAudioPluginStopTone (  void) ;

/*internal plugin message functions*/
void CsrAgAudioPluginInternalMessage( CsrAgAudioPluginTaskData *task ,uint16 id , Message message ) ;

void CsrAgAudioPluginToneComplete (CsrAgAudioPluginTaskData *task) ;
#endif

