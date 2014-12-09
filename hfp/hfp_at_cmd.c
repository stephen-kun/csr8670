/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_at_cmd.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_link_manager.h"
#include <string.h>


/****************************************************************************
NAME    
    HfpAtCmdRequest

DESCRIPTION
    Send an AT command from the application

MESSAGE RETURNED
    HFP_AT_CMD_CFM will be sent on OK/ERROR from the AG. Any other response 
    from the AG will be returned via HFP_UNRECOGNISED_AT_CMD_IND

RETURNS
    void
*/
void HfpAtCmdRequest(hfp_link_priority priority, const char* cmd)
{
    uint8 size_cmd = (cmd ? strlen(cmd) : 0);
    MAKE_HFP_MESSAGE_WITH_LEN(HFP_INTERNAL_AT_CMD_REQ, size_cmd);
    message->link = hfpGetLinkFromPriority(priority);
    message->size_cmd = size_cmd;
    if(cmd) strcpy(message->cmd, cmd);
    MessageSend(&theHfp->task, HFP_INTERNAL_AT_CMD_REQ, message);
}
