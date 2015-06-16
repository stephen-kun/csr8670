/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_security_init.h
    
DESCRIPTION

*/

#ifndef    CONNECTION_DM_SECURITY_INIT_H_
#define    CONNECTION_DM_SECURITY_INIT_H_


/****************************************************************************
NAME
    connectionSmInit

DESCRIPTION
    This Function is called to initialise SM. The config option is not 
    currently used but may be in future.

RETURNS
    Nothing.
*/
void connectionSmInit(cl_dm_bt_version version, connectionSmState *smState, uint8 flags);


#endif    /* CONNECTION_DM_SECURITY_INIT_H_ */
