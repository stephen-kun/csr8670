/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
Part of ADK 3.5
*/


#include "aghfp_common.h"

#include <panic.h>


/*****************************************************************************/
void aghfpSetState(AGHFP *aghfp, aghfp_state state)
{
	aghfp->state = state;
}


/*****************************************************************************
	Create a common cfm message (many AGHFP defined messages sent to the app
	have the form of the message below and a common function can be used to
	allocate them). Send the message not forgetting to set the correct 
	message id.
*/
void aghfpSendCommonCfmMessageToApp(uint16 message_id, AGHFP *aghfp, aghfp_lib_status status)
{
	MAKE_AGHFP_MESSAGE(AGHFP_COMMON_CFM_MESSAGE);
	message->status = status;
	message->aghfp = aghfp;
	MessageSend(aghfp->client_task, message_id, message);
}


/*****************************************************************************/
bool supportedProfileIsHfp(aghfp_profile profile)
{
    switch (profile)
    {
        case aghfp_handsfree_profile:
        case aghfp_handsfree_15_profile:
        case aghfp_handsfree_16_profile:
            return 1;
            
        default:
            return 0;
        }
    
    return 0;
}


/*****************************************************************************/
bool supportedProfileHasHfp15Features(aghfp_profile profile)
{
    switch (profile)
    {
        case aghfp_handsfree_15_profile:
        case aghfp_handsfree_16_profile:
            return 1;
            
        default:
            return 0;
        }
    
    return 0;
}


/*****************************************************************************/
bool supportedProfileIsHsp(aghfp_profile profile)
{
    if (profile == aghfp_headset_profile)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

