/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_hs_handler.h
    
DESCRIPTION
    
*/

#ifndef HFP_HS_HANDLER_H_
#define HFP_HS_HANDLER_H_


/****************************************************************************
NAME    
    hfpSendHsButtonPress

DESCRIPTION
    Send a button press AT cmd to the AG.

RETURNS
    void
*/
void hfpSendHsButtonPress(hfp_link_data* link, hfp_at_cmd pending_cmd);


#ifndef HFP_MIN_CFM
/****************************************************************************
NAME    
    hfpHandleHsCkpdAtAck

DESCRIPTION
    Send a button press cfm to the app telling it whether the AT+CKPD
    succeeded or not.

RETURNS
    void
*/
void hfpHandleHsCkpdAtAck(hfp_link_data* link, hfp_lib_status status);
#endif


#endif /* HFP_HS_HANDLER_H_ */
