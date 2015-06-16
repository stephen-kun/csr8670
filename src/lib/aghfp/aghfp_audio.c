/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
	aghfp_audio.c

DESCRIPTION
	

NOTES

*/


/****************************************************************************
	Header files
*/
#include "aghfp.h"
#include "aghfp_private.h"
#include "aghfp_audio_handler.h"
#include "aghfp_wbs_handler.h"

#include <panic.h>


/****************************************************************************
NAME	
	AghfpAudioTransferConnection

DESCRIPTION
    

MESSAGE RETURNED
    none.

RETURNS
	void
*/
void AghfpAudioTransferConnection(AGHFP *aghfp, aghfp_audio_transfer_direction direction, sync_pkt_type packet_type, const aghfp_audio_params *audio_params)
{
    MAKE_AGHFP_MESSAGE(AGHFP_INTERNAL_AUDIO_TRANSFER_REQ);
    
    AGHFP_DEBUG_ASSERT(aghfp, ("Null hfp task ptr passed in.\n"));
    AGHFP_DEBUG_ASSERT((direction<=aghfp_audio_transfer), ("Invalid direction passed in.\n"));
    
    /* Send an internal message */
    message->direction = direction;
    message->packet_type = packet_type;
    if ( audio_params )
    {
        message->audio_params = *audio_params;
    }
    else
    {
        message->audio_params = *aghfpGetDefaultAudioParams(packet_type);
    }    

    MessageSend(&aghfp->task, AGHFP_INTERNAL_AUDIO_TRANSFER_REQ, message);
}


/****************************************************************************
NAME	
	AghfpAudioConnect

DESCRIPTION
	Create an audio connection to a remote device for the specified profile instance. 
	
    The audio_params structure is used to specify the connection parameters for
    setting up either a SCO or eSCO link. It is the application's responsibility
    to ensure that the remote device supports the requested parameters.

MESSAGE RETURNED
	AGHFP_AUDIO_CONNECT_CFM.

RETURNS
	void
*/
void AghfpAudioConnect(AGHFP *aghfp, sync_pkt_type packet_type, const aghfp_audio_params *audio_params)
{
    MAKE_AGHFP_MESSAGE(AGHFP_INTERNAL_AUDIO_CONNECT_REQ);
    
    AGHFP_DEBUG_ASSERT(aghfp, ("Null aghfp task ptr passed in.\n"));
    
    /* Send an internal message */
	message->packet_type = packet_type;

    if ( audio_params )
    {
        message->audio_params = *audio_params;
    }
    else
    {
        message->audio_params = *aghfpGetDefaultAudioParams(packet_type);
    }    

    MessageSend(&aghfp->task, AGHFP_INTERNAL_AUDIO_CONNECT_REQ, message);
}


/****************************************************************************
NAME	
	AghfpAudioConnectResponse

DESCRIPTION
    Used by the application to respond to an incoming connection request from
    a remote device.  The application will receive an AGHFP_AUDIO_CONNECT_IND to 
    indicate that the remote device is attempting to initiate a connection.
    
	The response is used to accept or reject the incoming connection request.

    The audio_params structure is used to specify the acceptable range of
    connection parameters when accepting an incoming request. It is the 
    application's responsibility to ensure that the remote device supports the 
    specified parameters.

MESSAGE RETURNED
	AGHFP_AUDIO_CONNECT_CFM.

RETURNS
	void
*/
void AghfpAudioConnectResponse(AGHFP *aghfp, bool response, sync_pkt_type packet_type, const aghfp_audio_params *audio_params)
{
    MAKE_AGHFP_MESSAGE(AGHFP_INTERNAL_AUDIO_CONNECT_RES);
    
    AGHFP_DEBUG_ASSERT(aghfp, ("Null aghfp task ptr passed in.\n"));

    /* Send an internal message */
    message->packet_type = packet_type;
    message->response = response;
    if ( audio_params )
    {
        message->audio_params = *audio_params;
    }
    else
    {
        message->audio_params = *aghfpGetDefaultAudioParams(packet_type);
    }

    MessageSend(&aghfp->task, AGHFP_INTERNAL_AUDIO_CONNECT_RES, message);
}

/****************************************************************************
NAME	
	AghfpAudioDisconnect

DESCRIPTION
	Disconnect the audio connection to the remote device for the specified profile instance.
	
MESSAGE RETURNED
	AGHFP_AUDIO_DISCONNECT_IND.

RETURNS
	void
*/
void AghfpAudioDisconnect(AGHFP *aghfp)
{
    AGHFP_DEBUG_ASSERT(aghfp, ("Null hfp task ptr passed in.\n"));

    /* Send an internal message */
    MessageSend(&aghfp->task, AGHFP_INTERNAL_AUDIO_DISCONNECT_REQ, 0);
}

/****************************************************************************
NAME	
	AghfpSetAudioParams

DESCRIPTION
	Allow the app to set the audio parameters within the AG.
	
MESSAGE RETURNED
	None.

RETURNS
	void
*/
void AghfpSetAudioParams(AGHFP *aghfp, sync_pkt_type packet_type, const aghfp_audio_params *audio_params)
{
    MAKE_AGHFP_MESSAGE(AGHFP_INTERNAL_SET_AUDIO_PARAMS_REQ);
    
    AGHFP_DEBUG_ASSERT(aghfp, ("Null aghfp task ptr passed in.\n"));
    
	message->packet_type = packet_type;

    if ( audio_params )
    {
        message->audio_params = *audio_params;
    }
    else
    {
        message->audio_params = *aghfpGetDefaultAudioParams(packet_type);
    }    

    MessageSend(&aghfp->task, AGHFP_INTERNAL_SET_AUDIO_PARAMS_REQ, message);
}


