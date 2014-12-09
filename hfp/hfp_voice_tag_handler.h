/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    hfp_voice_tag_handler.h
    
DESCRIPTION
    
*/

#ifndef HFP_VOICE_TAG_HANDLER_H_
#define HFP_VOICE_TAG_HANDLER_H_



/****************************************************************************
NAME    
    hfpHandleGetVoiceTagReq

DESCRIPTION
    Issue an "attach number to a voice tag" request to the AG to retrieve
    a phone number.

RETURNS
    void
*/
bool hfpHandleGetVoiceTagReq(hfp_link_data* link);


#endif /* HFP_VOICE_TAG_HANDLER_H_ */
