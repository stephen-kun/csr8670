/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_speech_recognition.h
    
DESCRIPTION
	control the speech recogntion plugin from the device.
    
    If SR is enabled, the  plugin can be used to answer or reject an 
    incoming call. 
    
*/

#ifdef ENABLE_SPEECH_RECOGNITION

#ifndef _SINK_SR_H_
#define _SINK_SR_H_

#define CSR_SR_APP_TIMEOUT 0x0001
#define CSR_SR_APP_RESTART 0x0002

/****************************************************************************
DESCRIPTION
  	This function is called to enable speech recognition mode
*/
void speechRecognitionStart(void);

/****************************************************************************
DESCRIPTION
  	This function is called to reenable speech recognition mode
*/
void speechRecognitionReStart(void);

/****************************************************************************
DESCRIPTION
  	This function is called to enable speech recognition mode
*/
void speechRecognitionStop(void);


/****************************************************************************
DESCRIPTION
  	This function is called to determine if speech rec is currently running
RETURNS
    True if Speech Rec is active
*/
bool speechRecognitionIsActive(void) ;

/****************************************************************************
DESCRIPTION
  	This function is called to determine if speech rec is enabled
RETURNS
    True if Speech Rec is enabled
*/
bool speechRecognitionIsEnabled(void) ;

#endif /* _SINK_SR_H_ */


#endif /*ENABLE_SPEECH_RECOGNITION*/
