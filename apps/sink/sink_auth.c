/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_auth.c        

DESCRIPTION
    This file contains the Authentication functionality for the Sink 
    Application

NOTES

*/

/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_audio_prompts.h"
#include "sink_stateManager.h"
#include "sink_auth.h"

#include "sink_devicemanager.h"
#include "sink_debug.h"

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#include <ps.h>
#include <bdaddr.h>
#include <stdlib.h>
#include <sink.h>

#ifdef DEBUG_AUTH
    #define AUTH_DEBUG(x) DEBUG(x)    
#else
    #define AUTH_DEBUG(x) 
#endif   


#ifdef ENABLE_PEER
#define BD_ADDR_SIZE (sizeof(bdaddr))
#define LINK_KEY_SIZE 8
#define ATTRIBUTES_SIZE (sizeof(sink_attributes))
#define STATUS_LOC 0
#define BD_ADDR_LOC 1
#define LINK_KEY_LOC (BD_ADDR_LOC+BD_ADDR_SIZE)
#define ATTRIBUTES_LOC (LINK_KEY_LOC+LINK_KEY_SIZE)

static void readPsPermanentPairing (bdaddr *bd_addr, uint16 *link_key, uint16 *link_key_status, sink_attributes *attributes)
{
    uint16 * ps_key;
    
    /* Allocate and zero buffer to hold PS key */
    ps_key = mallocPanic(BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);
    memset(ps_key, 0, BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);
    
    /* Attempt to obtain current pairing data */
    PsRetrieve(CONFIG_PERMANENT_PAIRING, ps_key, BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);

    /* Return any requested fields */
    if (link_key_status)
    {
        *link_key_status = ps_key[STATUS_LOC];
    }
    
    if (bd_addr)
    {
        memcpy(bd_addr, &ps_key[BD_ADDR_LOC], BD_ADDR_SIZE);
    }
    
    if (link_key)
    {
        memcpy(link_key, &ps_key[LINK_KEY_LOC], LINK_KEY_SIZE);
    }
    
    if (attributes)
    {
        memcpy(attributes, &ps_key[ATTRIBUTES_LOC], ATTRIBUTES_SIZE);
    }
    
    free(ps_key);
}

static void writePsPermanentPairing (const bdaddr *bd_addr, uint16 *link_key, uint16 link_key_status, const sink_attributes *attributes)
{
    uint16 * ps_key;
    
    /* Allocate and zero buffer to hold PS key */
    ps_key = mallocPanic(BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);
    memset(ps_key, 0, BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);
    
    /* Attempt to obtain current pairing data */
    PsRetrieve(CONFIG_PERMANENT_PAIRING, ps_key, BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);
    
    /* Update supplied fields */
    if (link_key_status)
    {
        ps_key[STATUS_LOC] = link_key_status;
    }
    
    if (bd_addr)
    {
        memcpy(&ps_key[BD_ADDR_LOC], bd_addr, BD_ADDR_SIZE);
    }
    
    if (link_key)
    {
        memcpy(&ps_key[LINK_KEY_LOC], link_key, LINK_KEY_SIZE);
    }
    
    if (attributes)
    {
        memcpy(&ps_key[ATTRIBUTES_LOC], attributes, ATTRIBUTES_SIZE);
    }
    
    /* Store updated pairing data */
    PsStore(CONFIG_PERMANENT_PAIRING, ps_key, BD_ADDR_SIZE + LINK_KEY_SIZE + ATTRIBUTES_SIZE + 1);
    
    free(ps_key);
}

/****************************************************************************
NAME    
    AuthInitPermanentPairing
    
DESCRIPTION
    Add devices stored in CONFIG_PERMANENT_PAIRING to Connection library's PDL
    
RETURNS
    void
*/
void AuthInitPermanentPairing (void)
{
    bdaddr ps_bd_addr;
    
    AUTH_DEBUG(("AuthInitPermanentPairing\n"));
    
    /* Obtain just the bluetooth address of a permanently paired device */
    readPsPermanentPairing(&ps_bd_addr, 0, 0, 0);
    AUTH_DEBUG(("   ps bd_addr = [%x:%x:%lx]\n", ps_bd_addr.uap, ps_bd_addr.nap, ps_bd_addr.lap));
    
    if ( !BdaddrIsZero(&ps_bd_addr) )
    {   /* A valid address has been obtained, ask CL for info on it */
        ConnectionSmGetAuthDevice(&theSink.task, (const bdaddr *)&ps_bd_addr);
    }
}

/****************************************************************************
NAME    
    AuthRemovePermanentPairing
    
DESCRIPTION
    Removes permanent paired device from Connection library's PDL.
    Will also erase CONFIG_PERMANENT_PAIRING if erase_ps_key set TRUE.
    
RETURNS
    void
*/
void AuthRemovePermanentPairing (bool erase_ps_key)
{
    bdaddr ps_bd_addr;
    
    AUTH_DEBUG(("AuthRemovePermanentPairing  erase_ps_key = %u\n", erase_ps_key));
    
    readPsPermanentPairing(&ps_bd_addr, 0, 0, 0);
    AUTH_DEBUG(("   ps bd_addr = [%x:%x:%lx]\n", ps_bd_addr.uap, ps_bd_addr.nap, ps_bd_addr.lap));
    
    if ( !BdaddrIsZero(&ps_bd_addr) )
    {
        ConnectionSmDeleteAuthDeviceReq(TYPED_BDADDR_PUBLIC, (const bdaddr *)&ps_bd_addr);
    }
    
    if ( erase_ps_key )
    {
        PsStore(CONFIG_PERMANENT_PAIRING, 0, 0);
    }
}

/****************************************************************************
NAME    
    AuthUpdatePermanentPairing
    
DESCRIPTION
    Use supplied BDADDR to obtain linkkey from Connection library and update
    CONFIG_PERMANENT_PAIRING to retain this as the permanently paired device
    
RETURNS
    void
*/
void AuthUpdatePermanentPairing (const bdaddr *bd_addr, const sink_attributes *attributes)
{
    AUTH_DEBUG(("AuthUpdatePermanentPairing\n"));
    
    /* Update permanent pairing info */
    writePsPermanentPairing(0, 0, 0, attributes);
    
    ConnectionSmGetAuthDevice(&theSink.task, bd_addr);
}

/****************************************************************************
NAME    
    handleGetAuthDeviceCfm
    
DESCRIPTION
    Called in response to CL_SM_GET_AUTH_DEVICE_CFM message, which is generated
    due to calling updatePermanentPairing.
    Both the BDADDR and linkkey contained in CL_SM_GET_AUTH_DEVICE_CFM are used to
    update CONFIG_PERMANENT_PAIRING to retain this as the permanently paired device
    
RETURNS
    void
*/
void handleGetAuthDeviceCfm (CL_SM_GET_AUTH_DEVICE_CFM_T *cfm)
{
    AUTH_DEBUG(("handleGetAuthDeviceCfm\n"));
    AUTH_DEBUG(("   status = %u\n",cfm->status));
    AUTH_DEBUG(("   ps bd_addr = [%x:%x:%lx]\n", cfm->bd_addr.uap, cfm->bd_addr.nap, cfm->bd_addr.lap));
    AUTH_DEBUG(("   trusted = %u\n",cfm->trusted));
    AUTH_DEBUG(("   link key type = %u",cfm->link_key_type));
    AUTH_DEBUG(("   link key size = %u\n",cfm->size_link_key));
    
    if ( cfm->status == success )
    {   /* Device exists in CL PDL */
        sink_attributes attributes;
        uint16 link_key_status = ((cfm->trusted & 0xF)<<8) | ((cfm->link_key_type & 0xF)<<4) | (cfm->size_link_key & 0xF);
        
        /* Update permanent pairing info */
        writePsPermanentPairing(&cfm->bd_addr, cfm->link_key, link_key_status, 0);
        
        /* Update attributes */
        readPsPermanentPairing(0, 0, 0, &attributes);
        deviceManagerStoreAttributes(&attributes, (const bdaddr *)&cfm->bd_addr);
        
        /* Mark the device as trusted and push it to the top of the PDL */
        ConnectionSmUpdateMruDevice((const bdaddr *)&cfm->bd_addr);
#ifdef ENABLE_SOUNDBAR
        /* ensure priority devices are shifted back to top of PDL */
        ConnectionAuthSetPriorityDevice((const bdaddr *)&cfm->bd_addr, FALSE);            
#endif            
    }
    else
    {   /* Device *does not* exist in CL PDL */ 
        bdaddr ps_bd_addr;
        uint16 ps_link_key_status;
        uint16 ps_link_key[LINK_KEY_SIZE];
    
        readPsPermanentPairing(&ps_bd_addr, ps_link_key, &ps_link_key_status, 0);
    
        if ( !BdaddrIsZero(&ps_bd_addr) )
        {   /* We have permanently paired device, add it to CL PDL */
            bool trusted = (bool)((ps_link_key_status>>8) & 0xF);
            cl_sm_link_key_type key_type = (cl_sm_link_key_type)((ps_link_key_status>>4) & 0xF);
            uint16 size_link_key = ps_link_key_status & 0xF;
        
            ConnectionSmAddAuthDevice(&theSink.task, (const bdaddr *)&ps_bd_addr, trusted, TRUE, key_type, size_link_key, (const uint16 *)ps_link_key);
        }
    }
 }

/****************************************************************************
NAME    
    handleAddAuthDeviceCfm
    
DESCRIPTION
    Called in response to CL_SM_ADD_AUTH_DEVICE_CFM message, which is generated
    due to calling ConnectionSmAddAuthDevice.
    
RETURNS
    void
*/
void handleAddAuthDeviceCfm (CL_SM_ADD_AUTH_DEVICE_CFM_T *cfm)
{
    if ( cfm->status == success )
    {   /* Ask for device info again to allow write of attribute data */
        ConnectionSmGetAuthDevice(&theSink.task, (const bdaddr *)&cfm->bd_addr);  
    }
}
#endif  /* ENABLE_PEER */

/****************************************************************************
NAME    
    AuthCanSinkConnect 
    
DESCRIPTION
    Helper function to indicate if connecting is allowed

RETURNS
    bool
*/

bool AuthCanSinkConnect ( const bdaddr * bd_addr );

/****************************************************************************
NAME    
    AuthCanSinkPair 
    
DESCRIPTION
    Helper function to indicate if pairing is allowed

RETURNS
    bool
*/

bool AuthCanSinkPair ( void ) ;

/*************************************************************************
NAME    
     sinkHandlePinCodeInd
    
DESCRIPTION
     This function is called on receipt on an CL_PIN_CODE_IND message
     being recieved.  The Sink devices default pin code is sent back.

RETURNS
     
*/
void sinkHandlePinCodeInd(const CL_SM_PIN_CODE_IND_T* ind)
{
    uint16 pin_length = 0;
    uint8 pin[16];
    
    if ( AuthCanSinkPair() )
    {
	    
		AUTH_DEBUG(("auth: Can Pin\n")) ;
		
   		/* Do we have a fixed pin in PS, if not reject pairing */
    	if ((pin_length = PsFullRetrieve(PSKEY_FIXED_PIN, pin, 16)) == 0 || pin_length > 16)
   		{
   	    	/* Set length to 0 indicating we're rejecting the PIN request */
        	AUTH_DEBUG(("auth : failed to get pin\n")) ;
       		pin_length = 0; 
   		}	
        else if(theSink.features.VoicePromptPairing)
        {
            AudioPromptPlayEvent(EventSysPinCodeRequest);
            AudioPromptPlayNumString(pin_length, pin);
        }
	} 
    /* Respond to the PIN code request */
    ConnectionSmPinCodeResponse(&ind->taddr, pin_length, pin); 
}

/*************************************************************************
NAME    
     sinkHandleUserConfirmationInd
    
DESCRIPTION
     This function is called on receipt on an CL_SM_USER_CONFIRMATION_IND

RETURNS
     
*/
void sinkHandleUserConfirmationInd(const CL_SM_USER_CONFIRMATION_REQ_IND_T* ind)
{
	/* Can we pair? */
	if ( AuthCanSinkPair() && theSink.features.ManInTheMiddle)
    {
        theSink.confirmation = TRUE;
		AUTH_DEBUG(("auth: Can Confirm %ld\n",ind->numeric_value)) ;
		/* Should use text to speech here */
		theSink.confirmation_addr = mallocPanic(sizeof(typed_bdaddr));
		*theSink.confirmation_addr = ind->taddr;
        if(theSink.features.VoicePromptPairing)
        {
            AudioPromptPlayEvent(EventSysConfirmationRequest);
            AudioPromptPlayNumber(ind->numeric_value);
        }
	}
	else
    {
		/* Reject the Confirmation request */
		AUTH_DEBUG(("auth: Rejected Confirmation Req\n")) ;
		ConnectionSmUserConfirmationResponse(&ind->taddr, FALSE);
    }
}

/*************************************************************************
NAME    
     sinkHandleUserPasskeyInd
    
DESCRIPTION
     This function is called on receipt on an CL_SM_USER_PASSKEY_IND

RETURNS
     
*/
void sinkHandleUserPasskeyInd(const CL_SM_USER_PASSKEY_REQ_IND_T* ind)
{
	/* Reject the Passkey request */
	AUTH_DEBUG(("auth: Rejected Passkey Req\n")) ;
	ConnectionSmUserPasskeyResponse(&ind->taddr, TRUE, 0);
}


/*************************************************************************
NAME    
     sinkHandleUserPasskeyNotificationInd
    
DESCRIPTION
     This function is called on receipt on an CL_SM_USER_PASSKEY_NOTIFICATION_IND

RETURNS
     
*/
void sinkHandleUserPasskeyNotificationInd(const CL_SM_USER_PASSKEY_NOTIFICATION_IND_T* ind)
{
	AUTH_DEBUG(("Passkey: %ld \n", ind->passkey));
    if(theSink.features.ManInTheMiddle && theSink.features.VoicePromptPairing)
    {
        AudioPromptPlayEvent(EventSysPasskeyDisplay);
        AudioPromptPlayNumber(ind->passkey);
    }
	/* Should use text to speech here */
}

/*************************************************************************
NAME    
     sinkHandleIoCapabilityInd
    
DESCRIPTION
     This function is called on receipt on an CL_SM_IO_CAPABILITY_REQ_IND

RETURNS
     
*/
void sinkHandleIoCapabilityInd(const CL_SM_IO_CAPABILITY_REQ_IND_T* ind)
{	
	/* If not pairable should reject */
	if(AuthCanSinkPair())
	{
		cl_sm_io_capability local_io_capability = theSink.features.ManInTheMiddle ? cl_sm_io_cap_display_yes_no : cl_sm_io_cap_no_input_no_output;
		
		AUTH_DEBUG(("auth: Sending IO Capability \n"));
		
		/* Send Response and request to bond with device */
  		ConnectionSmIoCapabilityResponse(&ind->bd_addr,local_io_capability,theSink.features.ManInTheMiddle,TRUE,FALSE,0,0);
	}
	else
	{
		AUTH_DEBUG(("auth: Rejecting IO Capability Req \n"));
		ConnectionSmIoCapabilityResponse(&ind->bd_addr, cl_sm_reject_request,FALSE,FALSE,FALSE,0,0);
	}
}

/*************************************************************************
NAME    
     sinkHandleRemoteIoCapabilityInd
    
DESCRIPTION
     This function is called on receipt on an CL_SM_REMOTE_IO_CAPABILITY_IND

RETURNS
     
*/
void sinkHandleRemoteIoCapabilityInd(const CL_SM_REMOTE_IO_CAPABILITY_IND_T* ind)
{
	AUTH_DEBUG(("auth: Incoming Authentication Request\n"));
}

/****************************************************************************
NAME    
    sinkHandleAuthoriseInd
    
DESCRIPTION
    Request to authorise access to a particular service.

RETURNS
    void
*/
void sinkHandleAuthoriseInd(const CL_SM_AUTHORISE_IND_T *ind)
{
	
	bool lAuthorised = FALSE ;
	
	if ( AuthCanSinkConnect(&ind->bd_addr) )
	{
		lAuthorised = TRUE ;
	}
	
	AUTH_DEBUG(("auth: Authorised [%d]\n" , lAuthorised)) ;
	    
	/*complete the authentication with the authorised or not flag*/
    ConnectionSmAuthoriseResponse(&ind->bd_addr, ind->protocol_id, ind->channel, ind->incoming, lAuthorised);
}


/****************************************************************************
NAME    
    sinkHandleAuthenticateCfm
    
DESCRIPTION
    Indicates whether the authentication succeeded or not.

RETURNS
    void
*/
void sinkHandleAuthenticateCfm(const CL_SM_AUTHENTICATE_CFM_T *cfm)
{
#ifdef ENABLE_SUBWOOFER
    if (theSink.inquiry.action == rssi_subwoofer)
    {
        if ((cfm->status == auth_status_success) && (cfm->bonded))
        {           
            /* Mark the subwoofer as a trusted device */
            deviceManagerMarkTrusted(&cfm->bd_addr);
            
            /* Store the subwoofers BDADDR to PS */
            configManagerWriteSubwooferBdaddr(&cfm->bd_addr);
            
            /* update local store for subsequent reconnections */
            memmove(&theSink.rundata->subwoofer.bd_addr, &cfm->bd_addr, sizeof(bdaddr));
            
            /* Setup some default attributes for the subwoofer */
            deviceManagerStoreDefaultAttributes(&cfm->bd_addr, TRUE);
            
            /* mark the subwoofer device as DO NOT DELETE in PDL */
            ConnectionAuthSetPriorityDevice((const bdaddr *)&cfm->bd_addr, TRUE);
        }
        return;
    }
#endif
	/* Leave bondable mode if successful unless we got a debug key */
	if (cfm->status == auth_status_success && cfm->key_type != cl_sm_link_key_debug)
    {
        if ((theSink.inquiry.action != rssi_pairing) || (theSink.inquiry.session != inquiry_session_normal))
        {
            /* Mark the device as trusted */
            deviceManagerMarkTrusted(&cfm->bd_addr);
            MessageSend (&theSink.task , EventSysPairingSuccessful , 0 );
        }
    }
    
	/* Set up some default params and shuffle PDL */
	if(cfm->bonded)
	{
        deviceManagerStoreDefaultAttributes(&cfm->bd_addr, FALSE);
        
        ConnectionAuthSetPriorityDevice((const bdaddr *)&cfm->bd_addr, FALSE);
	}
	
	/* Reset pairing info if we timed out on confirmation */
	AuthResetConfirmationFlags();
}


/****************************************************************************
NAME    
    AuthCanSinkPair 
    
DESCRIPTION
    Helper function to indicate if pairing is allowed

RETURNS
    bool
*/

bool AuthCanSinkPair ( void )
{
	bool lCanPair = FALSE ;
	
    if (theSink.features.SecurePairing)
    {
	    	/*if we are in pairing mode*/
		if ((stateManagerGetState() == deviceConnDiscoverable)||(theSink.inquiry.action == rssi_subwoofer))
		{
			lCanPair = TRUE ;
			AUTH_DEBUG(("auth: is ConnDisco\n")) ;
		}
#ifdef ENABLE_PARTYMODE
        else if((theSink.features.PartyMode)&&(theSink.PartyModeEnabled))
        {
			lCanPair = TRUE ;
			AUTH_DEBUG(("auth: allow PartyMode pairing\n")) ;
        }
#endif        
    }
    else
    {
	    lCanPair = TRUE ;
    }
    
    return lCanPair ;
}



/****************************************************************************
NAME    
    AuthCanSinkConnect 
    
DESCRIPTION
    Helper function to indicate if connecting is allowed

RETURNS
    bool
*/

bool AuthCanSinkConnect ( const bdaddr * bd_addr )
{
	bool lCanConnect = FALSE ;
    uint8 NoOfDevices = deviceManagerNumConnectedDevs();
    
    /* if device is already connected via a different profile allow this next profile to connect */
    if(deviceManagerProfilesConnected(bd_addr))
    {
    	AUTH_DEBUG(("auth: already connected, CanConnect = TRUE\n")) ;
        lCanConnect = TRUE;
    }
    /* this bdaddr is not already connected, therefore this is a new device, ensure it is allowed 
       to connect, if not reject it */
    else
    {
        /* when multipoint is turned off, only allow one device to connect */
        if(((!theSink.MultipointEnable)&&(!NoOfDevices))||
           ((theSink.MultipointEnable)&&(NoOfDevices < MAX_MULTIPOINT_CONNECTIONS)))
        {
            /* is secure pairing enabled? */
            if (theSink.features.SecurePairing)
            {
    	        /* If page scan is enabled (i.e. we are either connectable/discoverable or 
    	    	connected in multi point) */
    	    	if ( theSink.page_scan_enabled )
    	    	{
    	    		lCanConnect = TRUE ;
    	    		AUTH_DEBUG(("auth: is connectable\n")) ;
    	    	}		
            }
            /* no secure pairing */
            else
            {
            	AUTH_DEBUG(("auth: MP CanConnect = TRUE\n")) ;
    	        lCanConnect = TRUE ;
            }
        }
    }
  
    AUTH_DEBUG(("auth:  CanConnect = %d\n",lCanConnect)) ;
  
    return lCanConnect ;
}

/****************************************************************************
NAME    
    sinkPairingAcceptRes 
    
DESCRIPTION
    Respond correctly to a pairing info request ind

RETURNS
    void
*/
void sinkPairingAcceptRes( void )
{		
    if(AuthCanSinkPair() && theSink.confirmation)
	{
		AUTH_DEBUG(("auth: Accepted Confirmation Req\n")) ;
		ConnectionSmUserConfirmationResponse(theSink.confirmation_addr, TRUE);
     }
	else
     {
		AUTH_DEBUG(("auth: Invalid state for confirmation\n"));
     }
}

/****************************************************************************
NAME    
    sinkPairingRejectRes 
    
DESCRIPTION
    Respond reject to a pairing info request ind

RETURNS
    void
*/
void sinkPairingRejectRes( void )
{
	if(AuthCanSinkPair() && theSink.confirmation)
	{	
		AUTH_DEBUG(("auth: Rejected Confirmation Req\n")) ;
		ConnectionSmUserConfirmationResponse(theSink.confirmation_addr, FALSE);
	}
	else
	{
		AUTH_DEBUG(("auth: Invalid state for confirmation\n"));
	}
}

/****************************************************************************
NAME    
    AuthResetConfirmationFlags
    
DESCRIPTION
    Helper function to reset the confirmations flag and associated BT address

RETURNS
     
*/

void AuthResetConfirmationFlags ( void )
{
	AUTH_DEBUG(("auth: Reset Confirmation Flags\n"));
	if(theSink.confirmation)
	{
		AUTH_DEBUG(("auth: Free Confirmation Addr\n"));
		freePanic(theSink.confirmation_addr);
	}
	theSink.confirmation_addr = NULL;
	theSink.confirmation = FALSE;
}

