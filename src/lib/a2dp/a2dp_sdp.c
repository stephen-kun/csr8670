/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_sdp.c

DESCRIPTION


NOTES

*/


/****************************************************************************
    Header files
*/
#include "a2dp.h"
#include "a2dp_init.h"
#include "a2dp_l2cap_handler.h"
#include "a2dp_private.h"
#include "a2dp_sdp.h"

#include <connection.h>


/*****************************************************************************/
void a2dpHandleSdpRegisterCfm(const CL_SDP_REGISTER_CFM_T *cfm)
{
    /* Log received cfm message */
    a2dp->sdp_register_outstanding--;

    if (cfm->status==success)
    {
        /* Register the l2cap psm if all service records have been registered */
        if ( a2dp->sdp_register_outstanding==0 )
        {
            a2dpRegisterL2cap();
        }
    }
    else
    {
        /* Send indication that the initialisation failed */
        a2dpSendInitCfmToClient(a2dp_sdp_fail);
    }
}
