/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_dut_handler.h
    
DESCRIPTION

*/

#ifndef    CONNECTION_DM_DUT_HANDLER_H_
#define    CONNECTION_DM_DUT_HANDLER_H_


/****************************************************************************
NAME    
    connectionHandleEnterDutModeReq

DESCRIPTION
    Enter devuce under test (DUT) mode.

*/
void connectionHandleEnterDutModeReq(connectionReadInfoState *infoState);


/****************************************************************************
NAME    
    connectionHandleDutSecurityDisabled

DESCRIPTION
    Called when we have a confirmation that security mode has been disabled.

*/
void connectionHandleDutSecurityDisabled(Task appTask, const DM_SM_INIT_CFM_T *cfm);


/****************************************************************************
NAME    
    connectionHandleDutCfm

DESCRIPTION
    We've received a cfm from BlueStack indicating the outcome of the attempt
    to enter DUT mode.

*/
void connectionHandleDutCfm(Task appTask, const DM_HCI_ENABLE_DUT_MODE_CFM_T *cfm);


/****************************************************************************
NAME    
    connectionSendDutCfmToClient

DESCRIPTION
    Send a confirm message to the client (the task that initialised the 
    connection lib) indicating the outcome of the request to enter DUT mode.

*/
void connectionSendDutCfmToClient(Task appTask, connection_lib_status result);


#endif    /* CONNECTION_DM_DUT_HANDLER_H_ */
