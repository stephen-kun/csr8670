/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    hfp_volume_handler.h
    
DESCRIPTION
    
*/

#ifndef HFP_SOUND_HANDLER_H_
#define HFP_SOUND_HANDLER_H_


/****************************************************************************
NAME    
    hfpHandleVgsRequest

DESCRIPTION
    Send a volume gain update to the AG.

RETURNS
    void
*/
void hfpHandleVgsRequest(hfp_link_data* link, uint8 gain);


/****************************************************************************
NAME    
    hfpHandleVgmRequest

DESCRIPTION
    Send the VGM request to the AG.

RETURNS
    void
*/
void hfpHandleVgmRequest(hfp_link_data* link, uint8 gain);


#endif /* HFP_SOUND_HANDLER_H_ */
