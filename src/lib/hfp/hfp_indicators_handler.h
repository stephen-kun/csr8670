/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    hfp_indicators_handler.h
    
DESCRIPTION
    
*/

#ifndef HFP_INDICATORS_HANDLER_H_
#define HFP_INDICATORS_HANDLER_H_

/****************************************************************************
NAME    
    hfpHandleSetActiveIndicatorsReq

DESCRIPTION
    Handle request to set active indicators from the app

AT INDICATION
    +BIA=

RETURNS
    void
*/
void hfpHandleSetActiveIndicatorsReq(hfp_link_data* link);


/****************************************************************************
NAME    
    hfpHandleBiaAtAck

DESCRIPTION
    Handle Ack from AG in response to AT+BIA=

RETURNS
    void
*/
void hfpHandleBiaAtAck(hfp_link_data* link, hfp_lib_status status);

#endif /* HFP_INDICATORS_HANDLER_H_ */
