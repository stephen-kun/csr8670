/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    dm_ble_security.h      

DESCRIPTION
    This file contains the prototypes for BLE Dm Security functions.

NOTES

*/

/****************************************************************************
NAME    
    connectionHandleInternalBleDmSecurityReq

DESCRIPTION
    Deals with the internal message (see above). State lock for the task is 
    not required as it can be passed as the context for the Security message
    scenario.

RETURNS
   void
*/
void connectionHandleInternalBleDmSecurityReq(
        CL_INTERNAL_SM_DM_SECURITY_REQ_T *req
        );

/****************************************************************************
NAME    
    connectionHandleDmSmSecurityCfm

DESCRIPTION
    Handle the DM_SM_SECURITY_CFM message from Bluestack.

RETURNS
   void
*/
void connectionHandleDmSmSecurityCfm(DM_SM_SECURITY_CFM_T *cfm);        

