/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_slc_handler.h
    
DESCRIPTION
    
*/

#ifndef HFP_SLC_HANDLER_H_
#define HFP_SLC_HANDLER_H_


/****************************************************************************
NAME    
    hfpSendSlcConnectCfmToApp

DESCRIPTION
    Send a HFP_SLC_CONNECT_CFM message to the app telling it the outcome
    of the connect attempt.

RETURNS
    void
*/
void hfpSendSlcConnectCfmToApp(hfp_link_data* link, const bdaddr* bd_addr, hfp_connect_status status);


/****************************************************************************
NAME    
    hfpHandleBrsfRequest

DESCRIPTION
    Send AT+BRSF to the AG.

RETURNS
    void
*/
void hfpHandleBrsfRequest(hfp_link_data* link);


/****************************************************************************
NAME    
    hfpHandleBacRequest

DESCRIPTION
    Send AT+BAC= to the AG.

RETURNS
    void
*/
void hfpHandleBacRequest(hfp_link_data* link);


/****************************************************************************
NAME    
    hfpSlcCheckAtAck

DESCRIPTION
    Generic handler for AT Acks during SLC establishment

RETURNS
    TRUE if Ack was successful, FALSE otherwise
*/
bool hfpSlcCheckAtAck(hfp_link_data* link, hfp_lib_status status);


/****************************************************************************
NAME    
    hfpHandleSupportedFeaturesNotification

DESCRIPTION
    Store the AG's supported features.

RETURNS
    void
*/
void hfpHandleSupportedFeaturesNotification(hfp_link_data* link, uint16 features);


/****************************************************************************
NAME    
    hfpHandleBrsfAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+BRSF cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleBrsfAtAck(hfp_link_data* link, hfp_lib_status status);


/****************************************************************************
NAME    
    hfpHandleBacAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+BAC cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleBacAtAck(hfp_link_data* link, hfp_lib_status status);


/****************************************************************************
NAME    
    hfpHandleCindTestAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+CIND=? cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleCindTestAtAck(hfp_link_data* link, hfp_lib_status status);


/****************************************************************************
NAME    
    hfpHandleCindReadAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+CIND? cmd. This 
    indicates whether the AG recognised the cmd.

RETURNS
    void
*/
void hfpHandleCindReadAtAck(hfp_link_data* link, hfp_lib_status status);


/****************************************************************************
NAME    
    hfpHandleCmerAtAck

DESCRIPTION
    Called when we receive OK/ ERROR in response to the AT+CMER cmd. If we're
    not getting call hold params from the AG then the SLC is complete.

RETURNS
    void
*/
void hfpHandleCmerAtAck(hfp_link_data* link, hfp_lib_status status);


/****************************************************************************
NAME    
    hfpHandleDisconnectRequest

DESCRIPTION
    We're in the right state and have received a disconnect request, 
    handle it here.

RETURNS
    void
*/
void hfpHandleDisconnectRequest(hfp_link_data* link);


/****************************************************************************
NAME    
    hfpSendSlcDisconnectIndToApp

DESCRIPTION
    Send a HFP_SLC_DISCONNECT_IND message to the app notifying it that
    the SLC has been disconnected.

RETURNS
    void
*/
void hfpSendSlcDisconnectIndToApp(hfp_link_data* link, hfp_disconnect_status status);


#endif /* HFP_SLC_HANDLER_H_ */
