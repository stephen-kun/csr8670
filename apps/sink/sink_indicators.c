/****************************************************************************

Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_indicators.c

DESCRIPTION
    Handles HFP indicators sent by the AG

NOTES

*/

/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_indicators.h"


/****************************************************************************
NAME    
    indicatorsHandleServiceInd
    
DESCRIPTION
    Interprets the service Indicator messages and sends the appropriate message 

RETURNS
    void
*/
void indicatorsHandleServiceInd ( const HFP_SERVICE_IND_T *pInd ) 
{
    /* only update the state if not set to network is present, this prevents repeated
       network is present indications from re-enabling the led's if they have gone to 
       sleep (timeout period) */  
    if(pInd->service != theSink.NetworkIsPresent)
    {
        if ( pInd->service )
        {
            MessageSend(&theSink.task , EventSysNetworkOrServicePresent , 0 ) ;
            theSink.NetworkIsPresent = TRUE ;
        }
        else /*the network service is OK*/
        {
            /*should only send this if not currently sending it*/
            if (theSink.NetworkIsPresent)
            {
                MessageSend(&theSink.task , EventSysNetworkOrServiceNotPresent  , 0 ) ;     
                theSink.NetworkIsPresent = FALSE ;
            }
        }
    }
}

