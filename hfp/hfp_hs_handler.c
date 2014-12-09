/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_hs_handler.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_common.h"
#include "hfp_hs_handler.h"
#include "hfp_send_data.h"
#include "hfp_link_manager.h"

#include <panic.h>
#include <string.h>


/****************************************************************************
NAME    
    hfpSendHsButtonPress

DESCRIPTION
    Send a button press AT cmd to the AG.

RETURNS
    void
*/
void hfpSendHsButtonPress(hfp_link_data* link, hfp_at_cmd pending_cmd)
{
    /* Send the AT cmd over the air */
    char ckpd[] = "AT+CKPD=200\r";
    hfpSendAtCmd(link, strlen(ckpd), ckpd, pending_cmd);
}


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
void hfpHandleHsCkpdAtAck(hfp_link_data* link, hfp_lib_status status)
{
    /* Send a cfm message to the application. */
    hfpSendCommonCfmMessageToApp(HFP_HS_BUTTON_PRESS_CFM, link, status);
}
#endif
