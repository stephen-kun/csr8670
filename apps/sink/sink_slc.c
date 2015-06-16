/****************************************************************************

Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_slc.c

DESCRIPTION
    manages the conenction / reconnection to the last / default users

NOTES

*/

/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_scan.h"
#include "sink_slc.h"
#include "sink_inquiry.h"
#include "sink_devicemanager.h"
#include "sink_link_policy.h"
#include "sink_statemanager.h"
#include "sink_configmanager.h"
#include "sink_callmanager.h"
#include "sink_volume.h"
#include "sink_led_manager.h"
#include "sink_a2dp.h"

#ifdef ENABLE_PBAP
#include "sink_pbap.h"
#endif
#ifdef ENABLE_MAPC
#include "sink_mapc.h"
#endif

#include <connection.h>
#include <hfp.h>
#include <panic.h>
#include <ps.h>
#include <bdaddr.h>
#include <stddef.h>
#include <sink.h>
#include <string.h> /* for memset */
#include <a2dp.h>

#ifdef DEBUG_SLC
    #define SLC_DEBUG(x) DEBUG(x)
    #ifdef DEBUG_PRINT_ENABLED
        static const char * const gDebugReconStrings[8] = { "AR_LastConnected",
                                                            "AR_List"    
                                                          };
    #endif
#else
    #define SLC_DEBUG(x) 
#endif   
        
        
typedef enum NextPagingTag 
{
    PageUnknown   ,
    PageLastAG    , 
    PageFromList  ,
    PageComplete
}NextPage_t;


typedef struct slcDataTag
{
    uint16 gSlcConnectRemote;
    unsigned gCallTransferInProgress:1 ;
    unsigned gListID:4 ;
    unsigned gPdlSize:4 ;
    unsigned unused:7;
}slcData_t;

static slcData_t gSlcData = {FALSE, FALSE, 0, 0, 0} ;

/****************************************************************************
NAME    
    slcConnectFail
    
DESCRIPTION
    SLC failed to connect
RETURNS
    void
*/
void slcConnectFail(void)
{
    SLC_DEBUG(("SLC: ConnFail\n" )) ;
    /* Send event to signify that all reconnection attempts failed */
    MessageSend(&theSink.task, EventSysReconnectFailed, 0);
        
    /*clear the queue*/
    sinkClearQueueudEvent() ;
        
    /* continue the connection sequence, this may or may not make any further
       connection attempts depending upon multipoint configuration */
    if(!gSlcData.gSlcConnectRemote)
    {
        /* continue trying to connect to next device in 2 seconds time to
           allow paging between connection attempts */
        MessageSendLater(&theSink.task,EventSysContinueSlcConnectRequest,0,theSink.conf1->timeouts.SecondAGConnectDelayTime_s);
    }
        
    /* if set to repeat a connection attempt decrement this as an attempt has occured */
    if(theSink.NoOfReconnectionAttempts)
        theSink.NoOfReconnectionAttempts--;
    
}


/****************************************************************************
NAME    
    sinkHandleSlcConnectInd
    
DESCRIPTION
    Handle a request to establish an SLC from the AG.

RETURNS
    void
*/
void sinkHandleSlcConnectInd( const HFP_SLC_CONNECT_IND_T *ind )
{
    if(ind->accepted)
    {
        /* Cancel inquiry and throw away results if one is in progress, allow subwoofer
           inquiry to continue*/
        if(theSink.inquiry.action != rssi_subwoofer)
            inquiryStop();

        /* set flag indicating a connection is in progress */
        gSlcData.gSlcConnectRemote = TRUE;
    }
}

/****************************************************************************
NAME    
    sinkHandleSlcDisconnectInd
    
DESCRIPTION
    Indication that the SLC has been released.

RETURNS
    void
*/
void sinkHandleSlcDisconnectInd( const HFP_SLC_DISCONNECT_IND_T *ind )
{	    
    conn_mask mask = deviceManagerProfilesConnected(&ind->bd_addr);

    SLC_DEBUG(("SLC: slc DiscInd for index %d, status = %d\n",ind->priority, ind->status)) ;     
        
    if(ind->status == hfp_disconnect_success || ind->status == hfp_disconnect_link_loss || ind->status == hfp_disconnect_abnormally)
    {
        /* store volume info */
        deviceManagerUpdateAttributes(&ind->bd_addr, sink_hfp, ind->priority, 0); 

        /* Sends the indication to the device manager to send an event out if a device has disconnected*/
        deviceManagerDeviceDisconnectedInd(&ind->bd_addr);
	
        /*if the device is off then this is disconnect as part of the power off cycle - dont re-enable connectable*/	
    	if ( stateManagerGetState() != deviceLimbo)
        {
            /* Enable A2dp link loss management if connected on remote device */
            if( theSink.a2dp_link_data && (theSink.a2dp_link_data->connected[a2dp_primary]) && BdaddrIsSame(&ind->bd_addr, &theSink.a2dp_link_data->bd_addr[a2dp_primary]) )
            {
                A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[a2dp_primary], TRUE);
            }
            else if( theSink.a2dp_link_data && (theSink.a2dp_link_data->connected[a2dp_secondary]) && BdaddrIsSame(&ind->bd_addr, &theSink.a2dp_link_data->bd_addr[a2dp_secondary]) )
            {
                A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[a2dp_secondary], TRUE);
            }

            /* Kick role checking now a device has disconnected */
            linkPolicyCheckRoles();

            /* at least one device disconnected, re-enable connectable for another 60 seconds */
            sinkEnableMultipointConnectable();
        }
    
        /*a disconnect in active call state is a call transfer*/
        if ( (stateManagerGetState() == deviceActiveCallSCO) || 
             (stateManagerGetState() == deviceActiveCallNoSCO) )
        {
		    gSlcData.gCallTransferInProgress = TRUE ;           
        }
        else
        {
		    gSlcData.gCallTransferInProgress = FALSE ;	
        }
    
        /* if not a link loss reset the last outgoing AG as AG1 will no longer exist now */        
        theSink.last_outgoing_ag = hfp_primary_link;

        /* reset the list id of the device just dropped */              
        theSink.profile_data[PROFILE_INDEX(ind->priority)].status.list_id = INVALID_LIST_ID;

        /* if device has now disconnected all profiles, mark as disconnected */
        if((ind->status != hfp_disconnect_link_loss)&&(!(mask & conn_hfp)))
            theSink.profile_data[PROFILE_INDEX(ind->priority)].status.connected = FALSE;
        
        /* If primary disconnected */
        if(ind->priority == hfp_primary_link)
        {
            /* ...and we have a secondary link it will be promoted to primary */
            if(theSink.profile_data[PROFILE_INDEX(hfp_secondary_link)].status.list_id != INVALID_LIST_ID)
            {
                /* Block copy secondary data to primary location */
                theSink.profile_data[PROFILE_INDEX(hfp_primary_link)] = theSink.profile_data[PROFILE_INDEX(hfp_secondary_link)];
                /* Secondary link no longer exists, set it to invalid */
                theSink.profile_data[PROFILE_INDEX(hfp_secondary_link)].status.list_id = INVALID_LIST_ID;
            }
        }
        /* send event slc disconnected only if the status of the indication is success or link loss indication */
        MessageSend(&theSink.task , ((ind->status == hfp_disconnect_link_loss) ? EventSysReconnectFailed : EventSysSLCDisconnected) , 0) ;
    }
    

    /*if the device is off then this is disconnect as part of the power off cycle, otherwise check
      whether device needs to be made connectable */	
	if ( stateManagerGetState() != deviceLimbo)
    {
	    /* if the device state still shows connected and there are no profiles currently
           connected then update the device state to reflect the change of connections */
	    if ((stateManagerIsConnected()) && (!deviceManagerNumConnectedDevs()))
	    {
	        stateManagerEnterConnectableState( FALSE ) ;
	    }
    }
    
}


/****************************************************************************
NAME    
    slcConnectionSetup
    
DESCRIPTION
    Perform link setup for a given SLC

RETURNS
    void
*/
static void slcConnectionSetup(hfp_link_priority priority, Sink sink, bdaddr* bd_addr)
{
    uint16 priorityIdx = PROFILE_INDEX(priority);
    
    /* Set timeout to 5 seconds */
    ConnectionSetLinkSupervisionTimeout(sink, SINK_LINK_SUPERVISION_TIMEOUT);
    
    /* Send our link policy settings */
	linkPolicyUseHfpSettings(priority, sink);
    
    /* Send a delayed message to request a role indication and make necessary changes as appropriate */
    MessageCancelFirst(&theSink.task , EventSysCheckRole);    
    MessageSendConditionally (&theSink.task , EventSysCheckRole , NULL , &theSink.rundata->connection_in_progress );
    
#ifdef ENABLE_PBAP 
    /* Connect the PBAP link of this device */
    pbapConnect(priority);
#endif
    
    /* Sync volume level and mute settings with AG */
    VolumeSendAndSetHeadsetVolume(theSink.profile_data[priorityIdx].audio.gSMVolumeLevel ,FALSE , priority) ;
    
    /* Enable +CLIP from AG if using Audio Prompt numbers/names or display, always request if using display */
#if !defined(ENABLE_DISPLAY)
    if(theSink.features.VoicePromptNumbers)
#endif
        HfpCallerIdEnableRequest(priority, TRUE);

    /* HS uses call waiting indications when AG SCO is not routed */
    HfpCallWaitingEnableRequest(priority, TRUE);
    
    /* Attempt to pull the audio across if not already present, delay by 5 seconds
       to prevent a race condition occuring with certain phones */
    MessageSendLater ( &theSink.task , EventSysCheckForAudioTransfer , 0 , 5000 ) ;

    /* Send different event if first connection since power on - allows different LED pattern */
    if((theSink.features.UseDiffConnectedEventAtPowerOn)&&(theSink.powerup_no_connection))
        MessageSend (&theSink.task , EventSysSLCConnectedAfterPowerOn , NULL );
    else
        MessageSend (&theSink.task , EventSysSLCConnected , NULL );    

    /* Reset the flag - first connection indicated */
    theSink.powerup_no_connection = FALSE;
}


/****************************************************************************
NAME    
    slcConnectionComplete
    
DESCRIPTION
    SLC connection has completed

RETURNS
    void
*/
static void slcConnectionComplete(hfp_link_priority priority, Sink sink, bdaddr* bd_addr)
{
    	
    /* mark as connected */
    theSink.profile_data[PROFILE_INDEX(priority)].status.connected = TRUE;

    /* Another connection made, update number of current connections */
 	SLC_DEBUG(("SLC: Pro Connected[%x], NoOfDev=%x\n", (int)sink,deviceManagerNumConnectedDevs())) ;

	/* Enter connected state if applicable */
    if(!stateManagerIsConnected())
        stateManagerEnterConnectedState();
    
    /* Ensure the underlying ACL is encrypted */
    if(theSink.features.EncryptOnSLCEstablishment)
        ConnectionSmEncrypt( &theSink.task , sink , TRUE );
            
    /* send message to do indicate a stop of the paging process when in connectable state */
    if(theSink.paging_in_progress)
        MessageSend(&theSink.task, EventSysStopPagingInConnState ,0);

    /* if device initiated connection */
    if(!gSlcData.gSlcConnectRemote)
    {
        /* If no event is queued send button press */
        if(!theSink.gEventQueuedOnConnection)
            HfpHsButtonPressRequest(priority);
            
        /* Continue trying to connect to next device in 0.1 seconds time to allow current device to finish connecting */
        MessageSendLater(&theSink.task,EventSysContinueSlcConnectRequest,0,theSink.conf1->timeouts.SecondAGConnectDelayTime_s);
    }

    /* Initialise call transfer flag */
    gSlcData.gCallTransferInProgress = FALSE ;
}       


/****************************************************************************
NAME    
    sinkHandleSlcConnectCfm
    
DESCRIPTION
    Confirmation that the SLC has been established (or not).

RETURNS
    void
*/
bool sinkHandleSlcConnectCfm( const HFP_SLC_CONNECT_CFM_T *cfm )
{
    sink_attributes attributes;
    bool lResult = FALSE;
    
#ifdef ENABLE_PEER    
    inquiry_result_t* connecting_device = inquiryGetConnectingDevice();
#endif
    
    deviceManagerGetDefaultAttributes(&attributes, FALSE);
    (void)deviceManagerGetAttributes(&attributes, &cfm->bd_addr);
    
    /* cancel any link loss reminders */        
    MessageCancelAll(&theSink.task , EventSysLinkLoss );

    /* Check the status of the SLC attempt */
    if (cfm->status == hfp_connect_success)
    {
        SLC_DEBUG(("SLC: ConnCfm - Success\n")) ;
        lResult = TRUE ;

        /* update the profile volume level */
        theSink.profile_data[PROFILE_INDEX(cfm->priority)].audio.gSMVolumeLevel = attributes.hfp.volume;     
        /* Handle new connection setup */
        slcConnectionComplete(cfm->priority, cfm->sink, (bdaddr *)&cfm->bd_addr);
        /* Handle common setup for new SLC/link loss */
        slcConnectionSetup(cfm->priority, cfm->sink, (bdaddr *)&cfm->bd_addr);
        /* Record the position of the device in the PDL - prevents reconnection later */
        theSink.profile_data[PROFILE_INDEX(cfm->priority)].status.list_id = deviceManagerSetPriority((bdaddr *)&cfm->bd_addr);
        
#ifdef ENABLE_PEER
        /* If RSSI pairing, check inquiry results for A2DP support */
        if (theSink.inquiry.action == rssi_pairing)
        {
            if ((connecting_device != NULL) && BdaddrIsSame(&connecting_device->bd_addr, &cfm->bd_addr) && (connecting_device->remote_profiles & profile_a2dp))
            {
                attributes.profiles |= sink_a2dp;
            }
        }
#endif
        
        /* Make sure we store this device */
        attributes.profiles |= sink_hfp;
        deviceManagerStoreAttributes(&attributes, &cfm->bd_addr);
                
        /* if rssi pairing check to see if need to cancel rssi pairing or not */           
        if(theSink.inquiry.action == rssi_pairing)
        {   
            /* if rssi pairing has completed and the device being connected currently doesn't support A2DP, then stop it progressing further */            
            if(!((theSink.features.PairIfPDLLessThan) && ( ConnectionTrustedDeviceListSize() < theSink.features.PairIfPDLLessThan )))
            {
#ifdef ENABLE_PEER                
                if(!((connecting_device != NULL) && BdaddrIsSame(&connecting_device->bd_addr, &cfm->bd_addr) && (connecting_device->remote_profiles & profile_a2dp)))
#endif
                {
                    inquiryStop();
                }
            }
        }

        /* Disable A2dp link loss management if connected on remote device */
        if( theSink.a2dp_link_data && (theSink.a2dp_link_data->connected[a2dp_primary]) && BdaddrIsSame(&cfm->bd_addr, &theSink.a2dp_link_data->bd_addr[a2dp_primary]) )
        {
            A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[a2dp_primary], FALSE);
        }
        else if( theSink.a2dp_link_data && (theSink.a2dp_link_data->connected[a2dp_secondary]) && BdaddrIsSame(&cfm->bd_addr, &theSink.a2dp_link_data->bd_addr[a2dp_secondary]) )
        {
            A2dpDeviceManageLinkloss(theSink.a2dp_link_data->device_id[a2dp_secondary], FALSE);
        }

        /* Auto answer call if ringing - only answer the incoming call if its 
           on the connecting AG */
        if ( (theSink.features.AutoAnswerOnConnect) && (HfpLinkPriorityFromCallState(hfp_call_state_incoming) == cfm->priority) && (stateManagerGetState() < deviceActiveCallSCO) )
        {
            MessageSend (&theSink.task , EventUsrAnswer , 0 ) ;
            SLC_DEBUG(("SLC: AutoAnswer triggered\n")) ;
        }
    }
    else
    {
        SLC_DEBUG(("SLC: ConnCfm - Fail\n")) ;
        
        /* a connection timeout will arrive here, need to report fail for multipoint
           connections also such that a link loss retry will be performed */
        if(!stateManagerIsConnected() || theSink.MultipointEnable)
        {
            /* Update local state to reflect this */
            slcConnectFail();
        }
    }
 
    /* if using multipoint and both devices are connected disable connectable */
    if((theSink.MultipointEnable) && (deviceManagerNumConnectedDevs() == MAX_MULTIPOINT_CONNECTIONS))
    {
        SLC_DEBUG(("SLC: disable Conn \n" ));
        MessageCancelAll(&theSink.task, EventSysConnectableTimeout);

#ifdef ENABLE_SUBWOOFER     
        if(SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id))
        {
           sinkDisableConnectable();            
        }        
#else
        sinkDisableConnectable();            
#endif        
    }
    
    SLC_DEBUG(("SLC: Connect A2DP? En=%d att=%d\n",theSink.features.EnableA2dpStreaming,attributes.profiles)) ;
    
    /* if the AG supports A2DP profile attempt to connect to it if auto reconnect is enabled */
    if ((theSink.features.EnableA2dpStreaming) && 
         ((!cfm->priority)||(cfm->status == hfp_connect_success) || (cfm->status == hfp_connect_sdp_fail) || (cfm->status == hfp_connect_rejected)) &&
         ((slcDetermineConnectAction() & AR_Rssi)||(attributes.profiles & sink_a2dp)) &&                         
         ((slcDetermineConnectAction() & AR_Rssi)||(stateManagerGetState()!=deviceConnDiscoverable)))                          
    {
        SLC_DEBUG(("SLC: Connecting A2DP Remote %x\n",gSlcData.gSlcConnectRemote)) ;
        /* attempt connection to device supporting A2DP */
        theSink.a2dp_link_data->remote_connection = gSlcData.gSlcConnectRemote;
        A2dpSignallingConnectRequest((bdaddr *)&cfm->bd_addr);
        MessageCancelFirst(&theSink.task, EventSysContinueSlcConnectRequest);
        /* if rssi pairing check to see if need to cancel rssi pairing or not */           
        if(theSink.inquiry.action == rssi_pairing)
        {
            /* if rssi pairing has completed then stop it progressing further */            
            if(!((theSink.features.PairIfPDLLessThan)&&( ConnectionTrustedDeviceListSize() < theSink.features.PairIfPDLLessThan )))
            {
#ifdef ENABLE_PEER                
                if(!((connecting_device != NULL) && BdaddrIsSame(&connecting_device->bd_addr, &cfm->bd_addr) && (connecting_device->remote_profiles & profile_a2dp)))
#endif                   
                {
                    inquiryStop();
                }
            }
        }
    }
    else
    {
        /* reset connection via remote ag instead of device flag */
        gSlcData.gSlcConnectRemote = FALSE;
    }

#ifdef ENABLE_MAPC
    mapcMasConnectRequest((bdaddr *)&cfm->bd_addr);    
#endif
    
    return lResult ;
}

 
/****************************************************************************
NAME    
    slcHandleLinkLossInd
    
DESCRIPTION
    Indication of change in link loss status.

RETURNS
    void
*/
void slcHandleLinkLossInd( const HFP_SLC_LINK_LOSS_IND_T *ind )
{
    typed_bdaddr ag_addr;

    Sink sink;
    /* Are we recovering or have we recovered? */
    if(ind->status == hfp_link_loss_recovery)
    {
        /* Send an event to notify the user */
        MessageCancelAll(&theSink.task , EventSysLinkLoss );
        MessageSend(&theSink.task , EventSysLinkLoss , 0);
        /* Go connectable if feature enabled */
        if(theSink.features.GoConnectableDuringLinkLoss)
            sinkEnableConnectable(); 
    }
    else if(ind->status == hfp_link_loss_none)
    {
        sink_attributes attributes;

        /* Get Sink and bdaddr for the link */
        HfpLinkGetSlcSink(ind->priority, &sink);
        SinkGetBdAddr(sink, &ag_addr);

            /* Carry out link setup */
        slcConnectionSetup(ind->priority, sink, &ag_addr.addr);
       
        /* Link loss recovered - disable connectable */
        if(theSink.features.GoConnectableDuringLinkLoss)
        {
#ifdef ENABLE_SUBWOOFER     
            if(SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id))
            {
               sinkDisableConnectable();            
            }        
#else
        sinkDisableConnectable();            
#endif        
        }

        /* Reconnect A2DP if appropriate */
        if( theSink.features.EnableA2dpStreaming && 
            deviceManagerGetAttributes(&attributes, (const bdaddr *)&ag_addr.addr) && 
            (attributes.profiles & sink_a2dp) )
        {  
            SLC_DEBUG(("SLC: Reconnecting A2DP\n")) ;
            /* attempt reconnection to device supporting A2DP */
            A2dpSignallingConnectRequest((bdaddr *)&ag_addr.addr);
        }
    }
}


/****************************************************************************
NAME    
    sinkDisconnectAllSlc
    
DESCRIPTION
    Disconnect all the SLC's 

RETURNS
    void
*/
void sinkDisconnectAllSlc( void )
{
#ifdef ENABLE_MAPC
    /* Disconnect all MAPC links */
    mapcDisconnectMns();
#endif
    
    SLC_DEBUG(("SLC: DisconAllSLC\n")) ;
    /* disconnect any connections */    
   	HfpSlcDisconnectRequest(hfp_primary_link);
   	HfpSlcDisconnectRequest(hfp_secondary_link);

#ifdef ENABLE_PBAP        
    /* Disconnect all PBAP links */
    pbapDisconnect();
#endif	
    
}

/****************************************************************************
NAME    
    slcEstablishSLCRequest
    
DESCRIPTION
    Request to create a connection to a remote AG.

RETURNS
    void
*/

void slcEstablishSLCRequest ( void )
{
    bool listId_available = FALSE;
    
    /* only attempt a connection is the device is able to do so, 1 connection without multipoint only */
    if(deviceManagerCanConnect())
    {
        ARAction_t reconnect_action;
        reconnect_action = slcDetermineConnectAction();
        
        /* set flag to block role switch requests until all connections are complete to avoid unneccesary switching */
        theSink.rundata->connection_in_progress = TRUE;

        if(reconnect_action & AR_Rssi)
        {
            theSink.inquiry.action = rssi_connecting;
            inquiryStart( TRUE );
        }
        else
        {
            SLC_DEBUG(("SLC: slcEstablishSLCRequest - MP = [%c] \n",theSink.MultipointEnable ? 'T':'F' ));

            /* Cancel inquiry and throw away results if one is in progress, allow subwoofer
               inquiry to continue*/
            if(theSink.inquiry.action != rssi_subwoofer)
                inquiryStop();

            if(reconnect_action == AR_LastConnected)
                theSink.NoOfReconnectionAttempts = theSink.features.ReconnectLastAttempts;
            else
                theSink.NoOfReconnectionAttempts = theSink.conf1->timeouts.ReconnectionAttempts ;
                
            /* reset connection via remote ag instead of device flag */
            gSlcData.gSlcConnectRemote = FALSE;
	
            /*Paging attempts as per PSKEY's complete*/            
            SLC_DEBUG(("SLC: List Id [%d]\n" , gSlcData.gListID)) ;
            
            /* reset list to start at beginning */    
            gSlcData.gListID = 0;
            
            /* get the number of devices in the PDL */
            gSlcData.gPdlSize = ConnectionTrustedDeviceListSize();

            listId_available = slcIsListIdAvailable(gSlcData.gListID);
            
            /* ensure device is available to connect to and not already connected */
            if(!listId_available)
            {
               /* move to next ID as that must be free */
               gSlcData.gListID++;  
               /* check whether next id is available for connection */               
               listId_available = slcIsListIdAvailable(gSlcData.gListID);
            }
            
            /* ensure device is available */
            if(listId_available)
            {
                /* attempt to connect to first item in list */ 
                slcAttemptConnection();
            }
            /* not able to find a device to connect to, abandon attempt */
            else
            {                
                SLC_DEBUG(("SLC: EstablishSLC - no devices found\n")) ;
                /* nothing to connect to, reset flag */
                theSink.rundata->connection_in_progress = FALSE;
            }
        }
    }
}


/****************************************************************************
NAME    
    slcContinueEstablishSLCRequest
    
DESCRIPTION
    continue the connection request to create a connection to a remote AG.

RETURNS
    void
*/

void slcContinueEstablishSLCRequest( void )
{
    SLC_DEBUG(("SLC: ContSLCReq, listId = %d\n",gSlcData.gListID)) ;

    /* is multipoint enabled ?, if so see if necessary to connect further devices, also check for 
       non multipoint and no devices, otherwise exit */
    if((!gSlcData.gSlcConnectRemote) && (deviceManagerCanConnect()) && 
#ifdef ENABLE_PARTYMODE
       (!((theSink.PartyModeEnabled)&&(theSink.features.PartyMode)))&&
#endif
       (stateManagerGetState() != deviceLimbo))
    {
        if(slcDetermineConnectAction() & AR_Rssi)
        {
            /* Connect next result*/
            inquiryConnectNext();
        }
        else
        {
            /* if there are more devices to connect to then continue */
            if(slcGetNextListID())
            {
                SLC_DEBUG(("SLC: PDL entry available for connection , listId = %d\n",gSlcData.gListID)) ;
                /* attempt to connect to next item in list */ 
                slcAttemptConnection();
            }
            /* otherwise check whether any connection attempt was successful, if not check feature
               to automatically enter pairing mode */
            else if(theSink.features.EnterPairingModeOnFailureToConnect && !stateManagerIsConnected())
            {
                SLC_DEBUG(("SLC: Failed to Connect to anything, enter pairing mode\n")) ;
                /* enter pairing mode */
                MessageSend(&theSink.task, EventUsrEnterPairing, 0);
                /* now allow role switches */
                theSink.rundata->connection_in_progress = FALSE;
            }
            /* all connection attempts now complete, allow role switching */
            else
            {
                /* now allow role switches */
                theSink.rundata->connection_in_progress = FALSE;
            }
        }
    }
    /* Need to handle this case to stop RSSI when all devs connected */
    else if(slcDetermineConnectAction() & AR_Rssi)
    {
        /* All done, stop inquiring */
        if(theSink.inquiry.action != rssi_subwoofer)
            inquiryStop();
        /* set flag to block role switch requests until all connections are complete to avoid unneccesary switching */
        theSink.rundata->connection_in_progress = FALSE;
    }
    /* connections complete, allow role switches to commence if necessary */
    else
    {
        /* set flag to block role switch requests until all connections are complete to avoid unneccesary switching */
        theSink.rundata->connection_in_progress = FALSE;
    }

    /* reset connection via remote ag instead of device flag */
    gSlcData.gSlcConnectRemote = FALSE;

    SLC_DEBUG(("SLC: StopReq\n")) ;
}       


/****************************************************************************
NAME    
    slcConnectDevice
    
DESCRIPTION
    Attempt to connect profiles (as defined in sink_devicemanager.h) to a 
    given device 

RETURNS
    void
*/
void slcConnectDevice(bdaddr* bd_addr, sink_link_type profiles)
{
    SLC_DEBUG(("SLC: Connect to %04x,%02x,%06lx\n", bd_addr->nap, bd_addr->uap, bd_addr->lap));

    /* During RSSI pairing with Peer devices, the actual profiles supported by a device are searched for, */
    /* thus the profiles bitmask is configured correctly and does not need to use the code below.         */
#ifndef ENABLE_PEER
    /* if performing an RSSI pair, attempt to connect both HFP and A2DP profiles as AG
       may support either or both */
    if(theSink.inquiry.action == rssi_pairing)
    {
        HfpSlcConnectRequest(bd_addr, hfp_handsfree_and_headset, hfp_handsfree_all);
        A2dpSignallingConnectRequest(bd_addr);
    }
    /* not in RSSI pairing mode */
    else
#endif
    {
        /* does device support HFP? */
        if(profiles & sink_hfp)
        {
            /* Assume network is present already so application notifies correctly if
               the device connects and notifies there is no network */
            theSink.NetworkIsPresent = TRUE;
            
            SLC_DEBUG(("SLC: Connecting HFP\n")) ;            
            HfpSlcConnectRequest(bd_addr, hfp_handsfree_and_headset, hfp_handsfree_all);
        }
        /* if the device does not support HFP, check for an A2DP only device */
        else if(theSink.features.EnableA2dpStreaming &&(profiles & sink_a2dp))
        {  
            SLC_DEBUG(("SLC: Connecting A2DP\n")) ;
            /* attempt connection to device supporting A2DP */
            A2dpSignallingConnectRequest(bd_addr);
        }
    }
}

/****************************************************************************
NAME    
    slcAttemptConnection
    
DESCRIPTION
    attemp connection to next item in pdl

RETURNS
    void
*/
void slcAttemptConnection(void)
{
    typed_bdaddr  ag_addr;
    sink_attributes attributes;      

    /* attempt to obtain the device attributes for the current ListID required */
    if(deviceManagerGetIndexedAttributes(gSlcData.gListID, &attributes, &ag_addr))
    {
        /* device exists, determine whether the device supports HFP/HSP, A2DP or both and connect
           as appropriate */
        SLC_DEBUG(("SLC: slcAttConn, listId = %d, attrib = %x\n",gSlcData.gListID,attributes.profiles)) ;

        /* ensure the device supports the required profiles before attempting to connect otherwise
           try to find another device */
        if(attributes.profiles & (sink_hfp | sink_a2dp | sink_avrcp))
        {
            /* attempt to connect to device */
            slcConnectDevice(&ag_addr.addr, attributes.profiles);
        }
        /* device does not support required profiles, try to find another device that does */
        else
        {
            /* attempts to find another paired device in the PDL */
            MessageCancelFirst(&theSink.task, EventSysContinueSlcConnectRequest);
            MessageSend(&theSink.task, EventSysContinueSlcConnectRequest, 0);
        }
    }
    else
    {
        /* attempts to find another paired device in the PDL */
        MessageCancelFirst(&theSink.task, EventSysContinueSlcConnectRequest);
        MessageSend(&theSink.task, EventSysContinueSlcConnectRequest, 0);
    }
    
    SLC_DEBUG(("SLC: slcAttConnm\n")) ;
                   
}

/****************************************************************************
NAME    
    slcDetermineConnectAction
    
DESCRIPTION
    Request to determine the connection action required, 

RETURNS
    required action based on current device state
*/

ARAction_t slcDetermineConnectAction( void )
{
    ARAction_t lARAction = AR_LastConnected ;
    
    /*handle call transfer action*/
    if ( gSlcData.gCallTransferInProgress )
    {
        lARAction = theSink.features.ActionOnCallTransfer ;
        SLC_DEBUG(("SLC: DCAction-Last-Call Tx[%d]\n" , lARAction));
    }
    else if( theSink.panic_reconnect )
    {
        lARAction = theSink.features.ActionOnPanicReset;
        SLC_DEBUG(("SLC: DCAction-Panic-Reset [%d]\n", lARAction));
    }
    else
    {
        /*we are freshly powered on / Not connected - use poweron action*/
        lARAction = theSink.features.ActionOnPowerOn ;
        SLC_DEBUG(("SLC: DCAction-PwrOn-[%d]\n", lARAction));
    }
    
    /* Mask out RSSI bit if rssi action has completed */
    if(theSink.inquiry.action == rssi_none)
        lARAction &= ~AR_Rssi;
    else if(theSink.inquiry.action == rssi_pairing)
        lARAction |= AR_Rssi;
    return lARAction;
}


/****************************************************************************
NAME    
    slcReset
    
DESCRIPTION
    reset the pdl connection pointer

RETURNS
    none
*/
void slcReset(void)
{
    /* reset back to start of pdl */
    gSlcData.gListID = 0;
}


/****************************************************************************
NAME    
    slcGetNextListID
    
DESCRIPTION
    selects the next available ListID for connection based on list id passed in and
    the type of profile requested, this could be 'not fussed', 'hfp' or 'a2dp', the 
    funtion will also check for the end of the pdl and wrap to the beggining if that 
    feature is enabled

RETURNS
    true or false success status
*/   
bool slcGetNextListID(void)
{
    /* determine reconnection action, last or list */
    if(slcDetermineConnectAction() == AR_List)
    {
   		SLC_DEBUG(("SLC: slcGetNextListID - LIST - rem att = %d\n",theSink.NoOfReconnectionAttempts)) ;

        /* move to next item in list */
        gSlcData.gListID++;

        /* if there are a maximum number of reconnection attempts configured then check to see if
           any attempts remain, if no reconnection attempts are configured then traverse the list
           once only */
        if((!theSink.conf1->timeouts.ReconnectionAttempts)||
           (theSink.conf1->timeouts.ReconnectionAttempts && theSink.NoOfReconnectionAttempts))
        {
           /* check whether the ID is available, if not and at end of PDL, consider wrapping */
           if((!slcIsListIdAvailable(gSlcData.gListID))&&(gSlcData.gListID == gSlcData.gPdlSize)&&(gSlcData.gPdlSize))
           {
                /* At end of PDL, is PDL wrapping available ? */           
               	if(theSink.conf1->timeouts.ReconnectionAttempts)
                {
                	SLC_DEBUG(("SLC: slcGetNextListID = %x - End of PDL - Wrap to 0\n",gSlcData.gListID)) ;
                    /* wrapping available, go to start of PDL */
                    gSlcData.gListID = 0;
                    /* check ListID 0 is available */
                    if(!slcIsListIdAvailable(gSlcData.gListID))
                    {
                        gSlcData.gListID = 1;
                        SLC_DEBUG(("SLC: slcGetNextListID = ID 0 not available use ID %x\n",gSlcData.gListID)) ;
                    }
                    /* success */
                    return TRUE;
                }
                /* PDL wrapping not allowed so stop here */
                else
              	{
              		SLC_DEBUG(("SLC: slcGetNextListID = %x - End of PDL - No Wrapping\n",gSlcData.gListID)) ;
                    return FALSE;
                }
           }
           /* also check if ID not allowed due to being already connected, in which case try the next one */
           else if(!slcIsListIdAvailable(gSlcData.gListID))
           {
               /* move to next ID and check that */
               gSlcData.gListID++;
               /* this should be available, if not it is end of PDL in which case stop as only
                  allow two connections to be made */
               if(slcIsListIdAvailable(gSlcData.gListID))
              	{
                   SLC_DEBUG(("SLC: slcGetNextListID = %x - Already Connected - try next\n",gSlcData.gListID)) ;
                   return TRUE;
               }
               /* not available, there is only one device in PDL so return failed status */
               else
               {
              		SLC_DEBUG(("SLC: slcGetNextListID = %x - Already Connected - no next so stop\n",gSlcData.gListID)) ;
                   return FALSE;
               }
           }
           /* new ListId is available for trying a connection */
           else
           {
          		SLC_DEBUG(("SLC: slcGetNextListID = %x - OK\n",gSlcData.gListID)) ;
               return TRUE;
           }
        }
        /* no further attempts remaining so stop */
        else
      	{
       		SLC_DEBUG(("SLC: slcGetNextListID = %x - No attempts remaining\n",gSlcData.gListID)) ;
            return FALSE;
        }
    }
    /* LAST reconnection type, device will connect to first two devices in PDL */
    else
    {
       if(!theSink.MultipointEnable)
       {
            if(theSink.NoOfReconnectionAttempts && !deviceManagerNumConnectedDevs())
                return TRUE;
            else
                return FALSE;
       }
       else
       {
            /* If no attempts remaining give up */
            if(!theSink.NoOfReconnectionAttempts)
                return FALSE;
            
            /* move to next id */
            gSlcData.gListID++;
                      
            /* ensure device is available, if a swat device is in the PDL then this will need
               to be skipped */
            if(!(slcIsListIdAvailable(gSlcData.gListID)))
            {
               gSlcData.gListID++;
            }
            
            SLC_DEBUG(("SLC: slcGetNextListID - LAST\n")) ;
            /* ensure device is available and return TRUE or FALSE status */
            return slcIsListIdAvailable(gSlcData.gListID);
        }
    }
}

/****************************************************************************
NAME    
    slcIsListIdAvailable
    
DESCRIPTION
    determine whether the ListID passed in is available in the PDL, the ID
    passed in could be out of range of the PDL so checks for that also

RETURNS
    true or false success status,
*/   
bool slcIsListIdAvailable(uint8 ListID)
{
    
    /* check ListID is a valid value within the range of the available devices in the PDL 
       and that it is not already connected */
    if((ListID < gSlcData.gPdlSize)&&(isPdlEntryAvailable(ListID)))
    {
        typed_bdaddr  ag_addr;
        sink_attributes attributes;      

        /* obtain attributes for passed in ID */   
        if(deviceManagerGetIndexedAttributes(ListID, &attributes, &ag_addr))
        {
            /* check whether device supports hfp, a2dp or avrcp */
            if(!(attributes.profiles & (sink_hfp | sink_a2dp | sink_avrcp)))
            {
                /* device does not support required profiles */
                SLC_DEBUG(("SLC: slcIsListIdAvailable - FALSE - no profile support - ListID = %x\n",ListID)) ;
                return FALSE;
            }
        }

        SLC_DEBUG(("SLC: slcIsListIdAvailable - TRUE - ListID = %x\n",ListID)) ;
        return TRUE;        
    }
    /* out of range value or already connected return failed status */
    else
    {
        SLC_DEBUG(("SLC: slcIsListIdAvailable - FALSE - ListID = %x\n",ListID)) ;
        return FALSE;
    }
}

/****************************************************************************
NAME    
    isPdlEntryAvailable
    
DESCRIPTION
    looks to see if passed in pdl index is already connected 

RETURNS
    TRUE or FALSE
*/
bool isPdlEntryAvailable( uint8 Id )
{      
    uint8 i;
    
    /* scan hfp and hsp profile instances looking for a match */
    for(i=0;i<MAX_PROFILES;i++)        
    {
        /* look for hfp profile that is connected and check its pdl listID */
        if((theSink.profile_data[i].status.list_id == Id)&&
           (theSink.a2dp_link_data->list_id[i] == Id))
           return FALSE;
    }
    /* no matches found so ID is available for use */
    SLC_DEBUG(("SLC: isPdlEntryAvailable for ID=%d is TRUE\n",Id ));    
    return TRUE;   
}

