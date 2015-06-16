/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    dm_dut_handler.c        

DESCRIPTION    

NOTES

*/


/****************************************************************************
	Header files
*/
#include "connection.h"
#include "connection_private.h"
#include "dm_dut_handler.h"

#include <vm.h>


/****************************************************************************/
void connectionSendDutCfmToClient(Task appTask, connection_lib_status result)
{
    if (appTask)
    {
        /* Send a cfm to the app task. */
        MAKE_CL_MESSAGE(CL_DM_DUT_CFM);
        message->status = result;
        MessageSend(appTask, CL_DM_DUT_CFM, message);
    }
}


/****************************************************************************/
void connectionHandleEnterDutModeReq(connectionReadInfoState *infoState)
{
	/* Make device discoverable and connectable */
	ConnectionWriteScanEnable(hci_scan_enable_inq_and_page);

	/* Disable security */

	if(infoState->version < bluetooth2_1)
	{
		ConnectionSmSetSecurityMode(connectionGetCmTask(), sec_mode0_off, hci_enc_mode_off);
	}
	else
	{
		MAKE_PRIM_C(DM_HCI_ENABLE_DUT_MODE_REQ);
		VmSendDmPrim(prim);
	}
}

/****************************************************************************/
void connectionHandleDutSecurityDisabled(Task appTask, const DM_SM_INIT_CFM_T *cfm)
{
	/* If we have successfully disabled security, enter DUT mode */
	if (cfm->status == HCI_SUCCESS)
	{
		MAKE_PRIM_C(DM_HCI_ENABLE_DUT_MODE_REQ);
		VmSendDmPrim(prim);
	}
	else
		connectionSendDutCfmToClient(appTask, fail);
}


/****************************************************************************/
void connectionHandleDutCfm(Task appTask, const DM_HCI_ENABLE_DUT_MODE_CFM_T *cfm)
{
	if (cfm->status == HCI_SUCCESS)
		connectionSendDutCfmToClient(appTask, success);
	else
		connectionSendDutCfmToClient(appTask, fail);
}
