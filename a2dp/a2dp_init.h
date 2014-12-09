/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    a2dp_init.h

DESCRIPTION


*/

#ifndef A2DP_INIT_H_
#define A2DP_INIT_H_

#include "a2dp.h"


/***************************************************************************
NAME
    a2dpSendInitCfmToClient

DESCRIPTION
    Send an A2DP_INIT_CFM message to the client task idicating the outcome
    of the library initialisation request.
*/
void a2dpSendInitCfmToClient(a2dp_status_code status);


/***************************************************************************
NAME
    a2dpInitTask

DESCRIPTION
    Initialise the a2dp task data structure with the supplied parameters.
*/
void a2dpInitTask(Task clientTask);


#endif /* A2DP_INIT_H_ */
