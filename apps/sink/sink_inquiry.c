/****************************************************************************

Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_inquiry.c

DESCRIPTION
    manages inquiry/pairing with devices based on RSSI

NOTES

*/

/***************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_inquiry.h"
#include "sink_slc.h"
#include "sink_statemanager.h"
#include "sink_devicemanager.h"
#include "sink_device_id.h"
#include "sink_peer.h"

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#include <bdaddr.h>

static void inquiryConnect (uint8 index);

#ifdef DEBUG_INQ
    #define INQ_DEBUG(x) DEBUG(x)
#else
    #define INQ_DEBUG(x)
#endif

/* RSSI configuration block */
#define NUM_INQ_DEVS        ((uint8)RSSI_CONF.num_results)
#define NUM_INQ_RESULTS     (NUM_INQ_DEVS + 1)
/* Is RSSI action to connect or pair? */
#define RSSI_CONNECTING     (theSink.inquiry.action == rssi_connecting)
#define RSSI_PAIRING        (theSink.inquiry.action == rssi_pairing)
/* Get thresholds dependant on whether we're connecting or pairing */
#define RSSI_DIFF_THRESHOLD (RSSI_CONNECTING ? (int)(RSSI_CONF.conn_diff_threshold) : (int)(RSSI_CONF.diff_threshold))
#define RSSI_THRESHOLD      (RSSI_CONNECTING ? RSSI_CONF.conn_threshold : RSSI_CONF.threshold)
/* Check if device is in the PDL */
#define RSSI_CAN_CONNECT(x) (RSSI_CONF.connect_if_in_pdl ? deviceManagerGetAttributes(NULL, x) : TRUE)
#define RSSI_CAN_PAIR(x)    (RSSI_CONF.dont_pair_if_in_pdl ? !deviceManagerGetAttributes(NULL, x) : TRUE)
#define RSSI_CHECK_PDL(x)   (RSSI_CONNECTING ? RSSI_CAN_CONNECT(x) : RSSI_CAN_PAIR(x))

#define LIAC 0x9E8B00
#define GIAC 0x9E8B33

#ifdef ENABLE_PEER
/* Service search patterns */
/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), HSP AG(0x1112) */
static const uint8 hsp_service_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x12};
/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), HFP AG(0x111F) */
static const uint8 hfp_service_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x1F};
/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), Audio Source(0x110A) */
static const uint8 a2dp_service_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0A};
/* DataElSeq(0x35), Length(0x03), 16-bit UUID(0x19), AVRCP Target(0x110C) */
static const uint8 avrcp_service_search_pattern[] = {0x35, 0x03, 0x19, 0x11, 0x0C};

/* Service search list */
static const struct
{
    supported_profiles profile;
	uint16             size;
	const uint8 *const pattern;
} service_searches[] =
{
	{ profile_hsp  , sizeof(hsp_service_search_pattern)  , hsp_service_search_pattern   },
    { profile_hfp  , sizeof(hfp_service_search_pattern)  , hfp_service_search_pattern   },
	{ profile_a2dp , sizeof(a2dp_service_search_pattern) , a2dp_service_search_pattern  },
    { profile_avrcp, sizeof(avrcp_service_search_pattern), avrcp_service_search_pattern }
};
#endif


#ifdef ENABLE_PEER
static bool performSdpSearch (const bdaddr *bd_addr, uint16 search_idx)
{
    INQ_DEBUG(("INQ: performSdpSearch "));
	if (search_idx < SUPPORTED_PROFILE_COUNT)
	{
        INQ_DEBUG(("- profile %u\n", service_searches[search_idx].profile));
		ConnectionSdpServiceSearchRequest(&theSink.task, bd_addr, 1, service_searches[search_idx].size, service_searches[search_idx].pattern);
		return TRUE;
	}
    else
    {
        INQ_DEBUG(("- completed\n"));
        return FALSE;
    }
}
#endif

#ifdef ENABLE_PEER
static void initiateSdpSearch (const bdaddr *bd_addr)
{
    INQ_DEBUG(("INQ: initiateSdpSearch "));
	/*ConnectionSmSetSdpSecurityOut(TRUE, bd_addr);*/ /* Allow SDP searches to be performed without locally enforcing authentication */
	ConnectionSdpOpenSearchRequest(&theSink.task, bd_addr);  /* Generates a CL_SDP_OPEN_SEARCH_CFM */
    
    theSink.inquiry.profile_search_idx = 0;
    theSink.inquiry.remote_profiles = 0;
}
#endif

#ifdef ENABLE_PEER
static sink_link_type getFirstConnectableProfile (supported_profiles remote_profiles)
{
    INQ_DEBUG(("INQ: First connectable profile "));
    if (remote_profiles & (profile_hsp | profile_hfp))
    {
        INQ_DEBUG(("= hfp/hsp\n"));
        return sink_hfp;
    }
    else if (remote_profiles & profile_a2dp)
    {
        INQ_DEBUG(("= a2dp\n"));
        return sink_a2dp;
    }
    else
    {
        INQ_DEBUG(("= none\n"));
        return sink_none;
    }
}
#endif

#ifdef ENABLE_PEER
void handleSdpOpenCfm (CL_SDP_OPEN_SEARCH_CFM_T *cfm)
{
    uint8 index = theSink.inquiry.attempting;
    inquiry_result_t* device = &theSink.inquiry.results[index];
    performSdpSearch(&device->bd_addr, theSink.inquiry.profile_search_idx);
}

void handleSdpCloseCfm (CL_SDP_CLOSE_SEARCH_CFM_T *cfm)
{
    uint8 index = theSink.inquiry.attempting;
    inquiry_result_t* device = &theSink.inquiry.results[index];
    sink_link_type first_profile = getFirstConnectableProfile(theSink.inquiry.remote_profiles);
    
    if (first_profile)
    {   /* Attempt connection */
        INQ_DEBUG(("INQ: slcConnectDevice\n"));
        slcConnectDevice(&device->bd_addr, first_profile);
    }
    else
    {   /* Device does not support a profile we can connect to */
        INQ_DEBUG(("INQ: inquiryConnectNext\n"));
        inquiryConnectNext();
    }
}

void HandleSdpServiceSearchAttributeCfm (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm)
{
    if (theSink.inquiry.action == rssi_none)
    {   /* Not inquiring thus we are the acceptor of an incoming A2DP signalling channel connect request */
        uint16 index;
        
        if (getA2dpIndexFromBdaddr(&cfm->bd_addr, &index))
        {
            if (theSink.features.PeerUseDeviceId && (theSink.a2dp_link_data->peer_device[index] == remote_device_unknown))
            {   /* Response is due to a request for the Device Id service record */
                if ( (cfm->status==sdp_response_success) && !cfm->error_code )
                {   /* Response obtained, examine it */
                    theSink.a2dp_link_data->peer_device[index] = CheckRemoteDeviceId(cfm->attributes, cfm->size_attributes);
                }
                else
                {
                    theSink.a2dp_link_data->peer_device[index] = remote_device_nonpeer;
                }
                
                theSink.a2dp_link_data->peer_features[index] = 0;
            }
            else
            {   /* Response is due to a request for the Peer Device service record */
                if ( (cfm->status==sdp_response_success) && !cfm->error_code )
                {   /* Response obtained, examine it */
                    theSink.a2dp_link_data->peer_features[index] = GetCompatibleRemotePeerFeatures(cfm->attributes, cfm->size_attributes);
                    theSink.a2dp_link_data->peer_device[index] = remote_device_peer;
                }
                else
                {
                    theSink.a2dp_link_data->peer_features[index] = 0;
                    theSink.a2dp_link_data->peer_device[index] = remote_device_nonpeer;
                }
            }

            if ((theSink.a2dp_link_data->peer_device[index] == remote_device_peer) && (theSink.a2dp_link_data->peer_features[index] == 0))
            {   /* Remote device is a Peer, check to see what features it supports */
                RequestRemotePeerServiceRecord(&cfm->bd_addr);
            }
            else
            {   /* A non Peer device or a Peer with known features */
                issueA2dpSignallingConnectResponse(&cfm->bd_addr);
            }
        }
    }
    else
    {   /* We are inquiring, so no A2DP connect request has been issued yet to this device, thus there is no entry in a2dp_link_data */
        remote_features peer_features = 0;
        remote_device peer_device = remote_device_nonpeer;
        
         /* Response is due to a request for the Peer Device service record */
        if ( (cfm->status==sdp_response_success) && !cfm->error_code )
        {   /* Response obtained, examine it */
            peer_features = GetCompatibleRemotePeerFeatures(cfm->attributes, cfm->size_attributes);
            peer_device = remote_device_peer;
        }
        
        theSink.inquiry.results[theSink.inquiry.attempting].peer_device = peer_device;
        theSink.inquiry.results[theSink.inquiry.attempting].peer_features = peer_features;
        
        inquiryConnect(theSink.inquiry.attempting);
    }
}

void HandleSdpServiceSearchCfm (CL_SDP_SERVICE_SEARCH_CFM_T *cfm)
{
    if (cfm->status != sdp_search_busy)
    {
#ifdef DEBUG_PRINT_ENABLED
        uint16 n=cfm->size_records;
        uint16 i;
        INQ_DEBUG(("INQ: Sdp service search result [ "));
        for (i=0; i<n; i++)
        {
            INQ_DEBUG(("0x%X ",cfm->records[i]));
        }
        INQ_DEBUG(("]\n"));
#endif

        if (cfm->status == sdp_response_success)
        {
            INQ_DEBUG(("INQ: Device supports profile %u\n", service_searches[theSink.inquiry.profile_search_idx].profile));
            theSink.inquiry.remote_profiles |= service_searches[theSink.inquiry.profile_search_idx].profile;
        }
        else
        {
            INQ_DEBUG(("INQ: Device does NOT support %u\n", service_searches[theSink.inquiry.profile_search_idx].profile));
            theSink.inquiry.remote_profiles &= ~service_searches[theSink.inquiry.profile_search_idx].profile;
        }
        
        if ( !performSdpSearch(&cfm->bd_addr, ++theSink.inquiry.profile_search_idx) )
        {
            ConnectionSdpCloseSearchRequest(&theSink.task);  /* Generates a CL_SDP_CLOSE_SEARCH_CFM */
        }
    }
}
#endif

/****************************************************************************
NAME    
    inquiryResetEntry
    
DESCRIPTION
    Reset inquiry data to initial values
RETURNS
    void
*/
static void inquiryResetEntry(uint8 index)
{
    BdaddrSetZero(&theSink.inquiry.results[index].bd_addr);
    theSink.inquiry.results[index].rssi = RSSI_THRESHOLD;
}


/****************************************************************************
NAME    
    inquiryReset
    
DESCRIPTION
    Reset inquiry data to initial values
RETURNS
    void
*/
void inquiryReset(void)
{
    uint8 index;
    INQ_DEBUG(("INQ: Reset\n"));
    if(theSink.inquiry.results)
        for(index=0; index < NUM_INQ_RESULTS; index++)
            inquiryResetEntry(index);

    theSink.inquiry.attempting = 0;
}


/****************************************************************************
NAME    
    inquiryResume
    
DESCRIPTION
    Reset inquiry results and resume
RETURNS
    void
*/
void inquiryResume(void)
{
    if(theSink.inquiry.state == inquiry_idle)
    {
        inquiryReset();
        theSink.inquiry.state = inquiry_searching;
        
        if (theSink.inquiry.session == inquiry_session_normal)
        {
            INQ_DEBUG(("INQ: Resume GIAC %d, %d, 0x%lX\n", RSSI_CONF.max_responses, RSSI_CONF.timeout, RSSI_CONF.cod_filter));
            /* Using GIAC */
            ConnectionInquire(&theSink.task, GIAC, RSSI_CONF.max_responses, RSSI_CONF.timeout, RSSI_CONF.cod_filter);
        }
        else
        {
            if (theSink.features.PeerUseLiac)
            {
                INQ_DEBUG(("INQ: Resume LIAC %d, %d, 0x%lX\n", 4, 46, AUDIO_MAJOR_SERV_CLASS | AV_MAJOR_DEVICE_CLASS ));
                /* Obtain upto 4 responses, using LIAC with 46*1.28sec=58.88sec timeout */
                ConnectionInquire(&theSink.task, LIAC, 4, 46, AUDIO_MAJOR_SERV_CLASS | AV_MAJOR_DEVICE_CLASS );
            }
            else
            {
                INQ_DEBUG(("INQ: Resume GIAC %d, %d, 0x%lX\n", 4, 46, AUDIO_MAJOR_SERV_CLASS | AV_MAJOR_DEVICE_CLASS ));
                /* Obtain upto 4 responses, using GIAC with 46*1.28sec=58.88sec timeout */
                ConnectionInquire(&theSink.task, GIAC, 4, 46, AUDIO_MAJOR_SERV_CLASS | AV_MAJOR_DEVICE_CLASS );
            }
        }
    }
}


/****************************************************************************
NAME    
    inquiryPair
    
DESCRIPTION
    Kick off inquiry and pairing
RETURNS
    bool
*/
bool inquiryPair (inquiry_session session, bool req_disc)
{
    INQ_DEBUG(("INQ: Pair %d \n", theSink.inquiry.action));
    
    if(theSink.inquiry.action == rssi_none)
    {
        theSink.inquiry.action = rssi_pairing;
        theSink.inquiry.session = session;
        inquiryStart( req_disc );
        return TRUE;
    }
    return FALSE;
}


/****************************************************************************
NAME    
    inquiryStart
    
DESCRIPTION
    Kick off inquiry
RETURNS
    void
*/
void inquiryStart (bool req_disc)
{
    if(!theSink.inquiry.results)
    {
        INQ_DEBUG(("INQ: Start\n" )) ;
        
        /* Go discoverable (and disconnect any active SLC) */
        if(RSSI_PAIRING)
        {
            INQ_DEBUG(("INQ: RSSI Pairing\n" )) ;
            MessageCancelAll(&theSink.task, EventUsrEstablishSLC);
            stateManagerEnterConnDiscoverableState( req_disc ) ;
        }
        slcReset();
        
        /* Allocate space to store inquiry results */
        theSink.inquiry.results = mallocPanic(NUM_INQ_RESULTS * sizeof(inquiry_result_t));
        theSink.inquiry.state = inquiry_idle;

        /* Increase page timeout */
        ConnectionSetPageTimeout(16384);

        /* Start a periodic inquiry, this will keep going until we cancel */
        inquiryResume();

        /* Send a reminder event */
        MessageSendLater(&theSink.task, EventSysRssiPairReminder, 0, D_SEC(INQUIRY_REMINDER_TIMEOUT_SECS));

        /* Send timeout if enabled */
        if(theSink.conf1->timeouts.InquiryTimeout_s)
            MessageSendLater(&theSink.task, EventSysRssiPairTimeout, 0, D_SEC(theSink.conf1->timeouts.InquiryTimeout_s));
    }
}


/****************************************************************************
NAME    
    inquiryStop
    
DESCRIPTION
    Stop inquiry in progress.
RETURNS
    void
*/
void inquiryStop(void)
{
    /* Free space used for inquiry results */
    if(theSink.inquiry.results)
    {
        INQ_DEBUG(("INQ: Stopped\n"));

        /* Cancel the inquiry */
        ConnectionInquireCancel(&theSink.task);
        MessageCancelFirst(&theSink.task, EventSysRssiResume);
        MessageCancelFirst(&theSink.task, EventSysRssiPairReminder);
        MessageCancelFirst(&theSink.task, EventSysRssiPairTimeout);
        MessageCancelFirst(&theSink.task, EventSysContinueSlcConnectRequest);

        freePanic(theSink.inquiry.results);
        theSink.inquiry.results = NULL;
        theSink.inquiry.state = inquiry_idle;

        /* Restore Page Timeout */
        ConnectionSetPageTimeout(0);
        
        /* Continue standard connection procedure */
        if(theSink.inquiry.action == rssi_connecting)
            MessageSend(&theSink.task, EventSysContinueSlcConnectRequest, 0);
        
        theSink.inquiry.action = rssi_none;
    }

    /* Only change state if we are not in Limbo */
    if (stateManagerGetState() != deviceLimbo)
    {
        if(deviceManagerNumConnectedDevs())
        {
            /* We connected, enter correct state */
            theSink.inquiry.action = rssi_none;
            /* change to connected state if not in a call state */
            if (stateManagerGetState() < deviceConnected)
                stateManagerEnterConnectedState();
        }
        else
        {
            /*No connected devices, enter Connectable/Discoverable appropriately*/
            uint16 lNumDevices = ConnectionTrustedDeviceListSize();

            /* Check if we want to go discoverable */
            if ( lNumDevices < theSink.features.DiscoIfPDLLessThan )
            {
                theSink.inquiry.session = inquiry_session_normal;
                stateManagerEnterConnDiscoverableState ( TRUE );
            }
        }
    }
}


/****************************************************************************
NAME    
    inquiryTimeout
    
DESCRIPTION
    Inquiry process has timed out, wait for connections in progress to 
    complete and stop inquiring
RETURNS
    void
*/
void inquiryTimeout(void)
{
    INQ_DEBUG(("INQ: Timeout - "));
    if(theSink.inquiry.results)
    {
        /* Wait for connect attempts to complete */
        if(theSink.inquiry.state == inquiry_connecting)
        {
            INQ_DEBUG(("Wait for SLC Complete\n"));
            theSink.inquiry.state = inquiry_complete;
        }
        else
        {
            INQ_DEBUG(("Stop\n"));
            inquiryStop();
        }
    }
    else
    {
        INQ_DEBUG(("Stop\n"));
        inquiryStop();
    }
}


/****************************************************************************
NAME    
    inquiryCheckBdaddr
    
DESCRIPTION
    Helper function to check if an address is in inquiry results
*/
static bool inquiryCheckBdaddr(bdaddr *bd_addr, uint8* index)
{
    /* Check all devices for a previous entry */
    for((*index) = 0; (*index) < NUM_INQ_RESULTS; (*index)++)
        if(BdaddrIsSame(bd_addr, &theSink.inquiry.results[*index].bd_addr))
            return TRUE;
    return FALSE;
}


/****************************************************************************
NAME    
    inquiryGetIndex
    
DESCRIPTION
    Work out the correct index in inquiry data for a given RSSI value
*/
static void inquiryGetIndex(int16 rssi, uint8* index)
{
    for((*index) = 0; (*index) < NUM_INQ_RESULTS; (*index)++)
        if(rssi > theSink.inquiry.results[*index].rssi)
            return;
    (*index)++;
}


/****************************************************************************
NAME    
    inquiryConnect
    
DESCRIPTION
    Connect to the specified inquiry result
    
RETURNS
    void
*/
static void inquiryConnect (uint8 index)
{
    INQ_DEBUG(("INQ: State [%d\n]", theSink.inquiry.state));
    INQ_DEBUG(("INQ: Connecting [%d]\n", index));

    if(theSink.inquiry.results)
    {
        if(index < NUM_INQ_DEVS || (RSSI_CONF.try_all_discovered && index < NUM_INQ_RESULTS))
        {
            inquiry_result_t* device = &theSink.inquiry.results[index];
            INQ_DEBUG(("INQ: Address %04x,%02x,%06lx\n", device->bd_addr.nap, device->bd_addr.uap, device->bd_addr.lap));

            /* Check there's a valid result at position idx */
            if(!BdaddrIsZero(&device->bd_addr))
            {
                /* Allow 2 close devices if multipoint enabled, otherwise just one */
                int16 rssi = theSink.inquiry.results[theSink.MultipointEnable ? 2 : 1].rssi;
                INQ_DEBUG(("INQ: RSSI %d Difference %d (%d)\n", device->rssi, (device->rssi - rssi), RSSI_DIFF_THRESHOLD));

                /* Check that difference threshold criteria are met */
                if(RSSI_CONF.try_all_discovered || (device->rssi - rssi) >= RSSI_DIFF_THRESHOLD)
                {
                    /* Don't continue connecting after timeout if try_all_discovered enabled */
                    if(!RSSI_CONF.try_all_discovered || (theSink.inquiry.state != inquiry_complete))
                    {
                        INQ_DEBUG(("INQ: Connect\n"));
    
                        /* Ensure the link key for this device is deleted before the connection attempt,
                        prevents reconnection problems with BT2.1 devices.*/
                        if(theSink.inquiry.action == rssi_pairing)
                            deviceManagerRemoveDevice(&device->bd_addr);
    
                        theSink.inquiry.state = inquiry_connecting;
#ifdef ENABLE_PEER
                        if ((device->peer_device != remote_device_nonpeer) && (device->peer_features == 0))
                        {   /* A Peer device with unknown features or an unknown device (also with unknown features) */
                            RequestRemotePeerServiceRecord(&device->bd_addr);
                        }
                        else if (!device->remote_profiles)
                        {   /* Remote device supported profiles not contained in EIR data - search using SDP */
                            initiateSdpSearch(&device->bd_addr);
                        }
                        else
                        {
                            sink_link_type first_profile = getFirstConnectableProfile(device->remote_profiles);
                            
                            theSink.inquiry.remote_profiles = device->remote_profiles;   /* TODO: Refactor inquiry.remote_profiles out */
                                
                            if (first_profile)
                            {   /* Device supports a profile we can connect to - attempt connection */
                                INQ_DEBUG(("INQ: slcConnectDevice\n"));
                                slcConnectDevice(&device->bd_addr, first_profile);
                            }
                            else
                            {   /* TODO: Temporary mechanism until this routine is modified to allow for repetition */
                                /* Issue a connect request for HFP */
                                slcConnectDevice(&device->bd_addr, sink_hfp);
                            }
                        }
#else          
                        /* Issue a connect request for HFP */
                        slcConnectDevice(&device->bd_addr, sink_hfp);
#endif
                        return;
                    }
                }
            }
        }

        /* We're no longer attempting a connection */
        theSink.inquiry.attempting = 0;

        /* If complete, connecting or pairing with second AG failed - stop, otherwise - resume inquiry */
        if (theSink.inquiry.action == rssi_connecting || theSink.inquiry.state == inquiry_complete ||
            (deviceManagerNumConnectedDevs() && theSink.inquiry.session == inquiry_session_normal ))
        {
            inquiryStop();
        }
        else
        {
            theSink.inquiry.state = inquiry_idle;
            MessageSendLater(&theSink.task, EventSysRssiResume, 0, D_SEC(RSSI_CONF.resume_timeout));
        }
    }
}

static void inquiryConnectFirst(void)
{
    theSink.inquiry.attempting = 0;
    inquiryConnect(theSink.inquiry.attempting);
}

inquiry_result_t* inquiryGetConnectingDevice (void)
{
    inquiry_result_t* connecting_device = NULL;

    if(theSink.inquiry.results != NULL)
    {
        connecting_device = &theSink.inquiry.results[theSink.inquiry.attempting];
    }

    return connecting_device;
}

void inquiryConnectNext(void)
{
    inquiryConnect(++theSink.inquiry.attempting);
}

#ifdef ENABLE_PEER
static supported_profiles getEirRemoteProfiles (uint16 size_eir_data, const uint8 *eir_data)
{
    uint16 i;
    INQ_DEBUG(("\n"));
    for (i=0; i<size_eir_data; i++) { INQ_DEBUG(("0x%X ",eir_data[i])); }
    INQ_DEBUG(("\n"));
    
    INQ_DEBUG(("INQ: EIR Data Size = %u\n",size_eir_data));
    
    while (size_eir_data >= 4)  /* Min possible size for a 16-bit service class UUID list EIR record */
    {
        uint16 eir_record_size = eir_data[0] + 1;   /* Record size in eir_data[0] does not include length byte, just tag and data size */
    
        INQ_DEBUG(("INQ: EIR Record Size = %u, Tag = 0x%X\n",eir_record_size, eir_data[1]));
        if ((eir_data[1] == 0x02) || (eir_data[1] == 0x03))     /* Partial or complete list of 16-bit service class UUIDs */
        {
            supported_profiles remote_profiles = profile_none;
            
            do
            {
                eir_record_size -= 2;
                eir_data += 2;

                INQ_DEBUG(("INQ: EIR Service UUID:0x%X\n",((eir_data[1]<<8) + eir_data[0])));

                /* Attempt to match next service uuid in EIR record */
                switch ((eir_data[1]<<8) + eir_data[0])
                {
                case 0x110A:    /* A2DP Audio Source */
                    remote_profiles |= profile_a2dp;
                    break;
                case 0x110C:    /* AVRCP Target */
                    remote_profiles |= profile_avrcp;
                    break;
                case 0x1112:    /* HSP AG */
                    remote_profiles |= profile_hsp;
                    break;
                case 0x111F:    /* HFP AG */
                    remote_profiles |= profile_hfp;
                    break;
                }
            }
            while (eir_record_size);
            
            return remote_profiles;
        }
        
        if (size_eir_data > eir_record_size)  
        {
            size_eir_data -= eir_record_size;
            eir_data += eir_record_size;
        }
        else
        {
            size_eir_data = 0;
        }
    }
    
    return profile_none;
}
#endif

/****************************************************************************
NAME    
    inquiryHandleResult
    
DESCRIPTION
    Inquiry result received
RETURNS
    void
*/
void inquiryHandleResult( CL_DM_INQUIRE_RESULT_T* result )
{
#ifdef ENABLE_SUBWOOFER
    /* Is the inquiry action searching for a subwoofer device? */
    if (theSink.inquiry.action == rssi_subwoofer)
    {
        handleSubwooferInquiryResult(result);
        return; /* Nothing more to do here as the inquiry result has been handled */
    }
#endif
    
    /* Check inquiry data is valid (if not we must have cancelled) */
    if(theSink.inquiry.results)
    {
#ifdef DEBUG_INQ
        uint8 debug_idx;
        INQ_DEBUG(("INQ: Inquiry Result %x Addr %04x,%02x,%06lx RSSI: %d\n", result->status,
                                                                       result->bd_addr.nap,
                                                                       result->bd_addr.uap,
                                                                       result->bd_addr.lap, 
                                                                       result->rssi )) ;

        for(debug_idx=0; debug_idx<NUM_INQ_RESULTS; debug_idx++)
            INQ_DEBUG(("INQ: [Addr %04x,%02x,%06lx RSSI: %d]\n", theSink.inquiry.results[debug_idx].bd_addr.nap,
                                                                 theSink.inquiry.results[debug_idx].bd_addr.uap,
                                                                 theSink.inquiry.results[debug_idx].bd_addr.lap, 
                                                                 theSink.inquiry.results[debug_idx].rssi )) ;
#endif
        if(result->status == inquiry_status_result)
        {
#ifdef ENABLE_PEER
            remote_device peer_device = remote_device_unknown;
            
            if (theSink.features.PeerUseDeviceId)
            {   /* Check for a peer device by matching device id records */
                if (CheckEirDeviceIdData(result->size_eir_data, result->eir_data))
                {   /* Mark device as a peer */
                    INQ_DEBUG(("INQ: Matched device id record on remote device\n"));
                    peer_device = remote_device_peer;
                    result->rssi += 0x100; /* Bump rssi value by maxiumum possible range so peer devices will be at top of sorted list */
                }
                else
                {
                    INQ_DEBUG(("INQ: Did NOT match device id record on remote device\n"));
                    peer_device = remote_device_nonpeer;
                }
            }
#endif
            
#ifdef ENABLE_PEER
            /* Filter out peer/non-peer devices depending on inquiry session */
            INQ_DEBUG(("INQ:session=%u device=%u\n", theSink.inquiry.session, peer_device));
            if (((theSink.inquiry.session == inquiry_session_peer) && (peer_device != remote_device_nonpeer)) || 
                ((theSink.inquiry.session == inquiry_session_normal) && (peer_device != remote_device_peer)))
#endif
            {
                /* Check if device is in PDL */
                INQ_DEBUG(("RSSI_CHECK_PDL = %u\n",RSSI_CHECK_PDL(&result->bd_addr)));
                if(RSSI_CHECK_PDL(&result->bd_addr))
                {
                    uint8 old_index;
                    uint8 new_index;
                    inquiry_result_t res;
                    res.bd_addr = result->bd_addr;
                    res.rssi = result->rssi;
#ifdef ENABLE_PEER
                    res.peer_device = peer_device;
                    res.peer_features = 0;
                    res.remote_profiles = getEirRemoteProfiles(result->size_eir_data, result->eir_data);
                    INQ_DEBUG(("INQ: EIR Remote Profiles = %u\n",res.remote_profiles));
#endif
                    inquiryGetIndex(res.rssi, &new_index);
                    INQ_DEBUG(("INQ: new_index = %u\n",new_index));
                    
                    /* Check if an entry exists for this device */
                    if(inquiryCheckBdaddr(&res.bd_addr, &old_index))
                    {
                        /* Don't update if new entry further down the list */
                        if(new_index > old_index)
                            return;
                        /* Reset the old entry (it should fall out the bottom) */
                        inquiryResetEntry(old_index);
                    }

                    /* While new index is valid  */
                    while(new_index < NUM_INQ_RESULTS)
                    {
                        inquiry_result_t prev;
                        /* Remember the previous result for this index */
                        prev = theSink.inquiry.results[new_index];
                        /* Put this result in its place */
                        theSink.inquiry.results[new_index] = res;
                        res = prev;
                        /* Get the new index of previous result */
                        inquiryGetIndex(res.rssi, &new_index);
                    }
                }
            }
        }
        else
        {
            INQ_DEBUG(("INQ: Inquiry Complete\n"));
            /* Attempt to connect to device */
            inquiryConnectFirst();
        }
    }
}
