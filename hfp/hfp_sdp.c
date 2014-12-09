/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_sdp.c        

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_service_manager.h"
#include "hfp_link_manager.h"
#include "hfp_common.h"
#include "hfp_sdp.h"
#include "hfp_hs_service_record.h"
#include "hfp_service_record.h"
#include "hfp_slc_handler.h"
#include "hfp_rfc.h"
#include "hfp_init.h"
#include "bdaddr.h"

#include <panic.h>
#include <service.h>
#include <string.h>
#include <print.h>


/* Request the service handle(s) of the HSP service at the AG */
static const uint8 HspServiceRequest [] =
{
    0x35, /* type = DataElSeq */
    0x05, /* size ...5 bytes in DataElSeq */
    0x1a, 0x00, 0x00, 0x11, 0x12 /* 4 byte UUID - will be filled in by app */
};


/* Request the service handle(s) of the HFP service at the AG */
static const uint8 HfpServiceRequest [] =
{
    0x35, /* type = DataElSeq */
    0x05, /* size ...5 bytes in DataElSeq */
    0x1a, 0x00, 0x00, 0x11, 0x1F /* 4 byte UUID - will be filled in by app */
};


/* Request the RFCOMM channel number of the AG's service */
static const uint8 protocolAttributeRequest [] =
{
    0x35, /* type = DataElSeq */
    0x03, /* size ...3 bytes in DataElSeq */
    0x09, 0x00, 0x04/* 2 byte UINT attrID ProtocolDescriptorList */    
};


/* Request the supported features of the HFP AG */
static const uint8 supportedFeaturesAttributeRequest [] =
{
    0x35,               /* 0b00110 101 type=DataElSeq */
    0x03,               /* size = 6 bytes in DataElSeq */        
    0x09, 0x03, 0x11    /* 2 byte UINT attrID - SupportedFeatures */
};


/* Request the profile descriptor list of the HFP AG */
static const uint8 profileDescriptorRequest [] =
{
    0x35,               /* 0b00110 101 type=DataElSeq */
    0x03,               /* size = 3 bytes in DataElSeq */        
    0x09, 0x00, 0x09    /* 2 byte UINT attrID - BluetoothProfileDescriptorList */
};


/* Find the rfcomm server channel in a service record */
static bool findRfcommServerChannel(const uint8 *ptr, const uint8 *end, Region *value)
{
    ServiceDataType type;
    Region record, protocols, protocol;
    record.begin = ptr;
    record.end   = end;
    while(ServiceFindAttribute(&record, saProtocolDescriptorList, &type, &protocols))
        if(type == sdtSequence)
            while(ServiceGetValue(&protocols, &type, &protocol))
            if(type == sdtSequence
               && ServiceGetValue(&protocol, &type, value) 
               && type == sdtUUID
               && RegionMatchesUUID32(value, (uint32) UUID_RFCOMM)
               && ServiceGetValue(&protocol, &type, value)
               && type == sdtUnsignedInteger)
            {
                /* Hah! found the server channel field */
                return 1;
            }
    return 0; /* Failed */

}


/* Retrieve the rfcomm server channel */
static uint16 getRfcommChannelNumber(const uint8 *begin, const uint8 *end, uint16 *chan)
{
    Region value;
    if(findRfcommServerChannel(begin, end, &value))
    {
        *chan = (uint16) RegionReadUnsigned(&value);
        return 1;
    }
    return 0;
}


/* Find the supported features in a service record */
static bool findHfpSupportedFeatures(const uint8 *begin, const uint8 *end, Region *value)
{
    ServiceDataType type;
    Region record;
    record.begin = begin;
    record.end   = end;

    if (ServiceFindAttribute(&record, saSupportedFeatures, &type, value))
    {
        if(type == sdtUnsignedInteger)
            return 1;
    }
    return 0;
}


/* Get the supported features from the returned attribute list */
static uint16 getHfpAgSupportedFeatures(const uint8 *begin, const uint8 *end, uint16 *features)
{
    Region value;
    if(findHfpSupportedFeatures(begin, end, &value))
    {
        *features = (uint16) RegionReadUnsigned(&value);
        return 1;
    }
    return 0;
}


/****************************************************************************
NAME    
    hfpRegisterServiceRecord

DESCRIPTION
    Register the service record corresponding to the specified service

RETURNS
    void
*/
void hfpRegisterServiceRecord(hfp_service_data* service)
{
    /* Ignore this silently if service is already registered */
    if(service->sdp_record_handle == 0 && !hfpGetVisibleServiceFromProfile(service->profile))
    {
        if(!theHfp->busy_channel)
        {
            uint8*       service_record      = 0;
            uint16       size_service_record = 0;
            
            theHfp->busy_channel  = service->rfc_server_channel;
            
            /* Create a copy of the service record that we can modify */
            if (supportedProfileIsHsp(service->profile))
            {
                size_service_record = sizeof(hsp_service_record);
                service_record = (uint8 *)PanicUnlessMalloc(sizeof(hsp_service_record));
                memmove(service_record, hsp_service_record, sizeof(hsp_service_record));
                
                /* Insert RFCOMM channel */
                service_record[HSP_RFCOMM_IDX] = theHfp->busy_channel;
            }
            else if (supportedProfileIsHfp(service->profile))
            {
                uint16 features = BRSF_BITMAP_TO_SDP_BITMAP(theHfp->hf_supported_features);
                uint16 version = supportedProfileIsHfp106(service->profile) ? HFP_1_6_VERSION_NUMBER : HFP_1_5_VERSION_NUMBER;
                
                size_service_record = sizeof(hfp_service_record);
                service_record = (uint8 *)PanicUnlessMalloc(sizeof(hfp_service_record));
                memmove(service_record, hfp_service_record, sizeof(hfp_service_record));
                
                /* Insert RFCOMM channel */
                service_record[HFP_RFCOMM_IDX] = theHfp->busy_channel;

                /* Insert the profile version number */
                service_record[HFP_VERSION_MSB_IDX] = version >> 8;
                service_record[HFP_VERSION_LSB_IDX] = version &  0xFF;
                
                /* Insert the supported features into the service record. */
                service_record[HFP_FEATURES_MSB_IDX] = features >> 8;
                service_record[HFP_FEATURES_LSB_IDX] = features &  0xFF;
            }
            else
            {
                /* If this is going to fail it will be during init, send init fail */
                hfpInitSdpRegisterComplete(hfp_fail);
                return;
            }
            
            /* Send the service record to the connection lib to be registered with BlueStack */
            ConnectionRegisterServiceRecord(&theHfp->task, size_service_record, service_record);
        }
        else
        {
            /* Queue registering this service */
            MAKE_HFP_MESSAGE(HFP_INTERNAL_SDP_REGISTER_REQ);
            message->service = service;
            MessageSendConditionally(&theHfp->task, HFP_INTERNAL_SDP_REGISTER_REQ, message, (uint16*)&theHfp->busy_channel);
        }
    }
    else if(!theHfp->initialised && service == HFP_SERVICE_TOP)
    {
        /* Make sure we complete init if we're not registering the top service */
        theHfp->busy_channel = service->rfc_server_channel;
        hfpInitSdpRegisterComplete(hfp_success);
    }
}


/****************************************************************************
NAME    
    hfpUnregisterServiceRecord

DESCRIPTION
    Unregister the service record corresponding to the specified service

RETURNS
    void
*/
void hfpUnregisterServiceRecord(hfp_service_data* service)
{
    /* Only unregister if we have a service handle */
    if(service->sdp_record_handle)
        ConnectionUnregisterServiceRecord(&theHfp->task, service->sdp_record_handle);
}


/****************************************************************************
NAME    
    hfpHandleSdpRegisterCfm

DESCRIPTION
    Outcome of SDP service register request.

RETURNS
    void
*/
void hfpHandleSdpRegisterCfm(const CL_SDP_REGISTER_CFM_T *cfm)
{
    /* Get the service we were registering */
    hfp_service_data* service = hfpGetServiceFromChannel(theHfp->busy_channel);

    if(service)
    {
        hfp_link_data* link = hfpGetLinkFromService(service);
        
        /* Check the outcome of the register request */
        if (cfm->status == sds_status_success)
        {
            /* Store the service handle */
            service->sdp_record_handle = cfm->service_handle;
            theHfp->busy_channel = 0;
            
            /* Service has connected in the time it took to register, unregister again */
            if(link_is_connected(link))
                hfpUnregisterServiceRecord(service);
        }
    }
    else
    {
        /* This should never happen */
        HFP_ASSERT_FAIL(("Invalid channel registered with SDP\n"));
    }
}


/****************************************************************************
NAME    
    handleSdpUnregisterCfm

DESCRIPTION
    Outcome of SDP service unregister request.

RETURNS
    void
*/
void handleSdpUnregisterCfm(const CL_SDP_UNREGISTER_CFM_T *cfm)
{
    hfp_service_data* service = hfpGetServiceFromHandle(cfm->service_handle);
    
    if (service && cfm->status == sds_status_success)
    {
        hfp_profile profile = service->profile;
        /* Unregister succeeded reset the service record handle */
        service->sdp_record_handle = 0;
        /* If we're not showing a service record for this profile type */
        if(!hfpGetVisibleServiceFromProfile(profile))
        {
            /* If we have a service for this profile that isn't connected
               then register it */
            service = hfpGetDisconnectedServiceFromProfile(profile);
            if(service)
                hfpRegisterServiceRecord(service);
        }
    }
}


/****************************************************************************
NAME    
    hfpGetProfileServerChannel

DESCRIPTION
    Initiate a service search to get the rfcomm server channel of the 
    required service on the remote device. We need this before we can 
    initiate a service level connection.

RETURNS
    void
*/
void hfpGetProfileServerChannel(hfp_link_data* link, hfp_service_data* service, const bdaddr *bd_addr)
{
    /* Default to HFP search */
    uint16 sp_len = sizeof(HfpServiceRequest);
    uint8* sp_ptr = (uint8 *) HfpServiceRequest;

    /* Set up the link data */
    hfpLinkSetup(link, service, bd_addr, NULL, hfp_slc_searching);
    
    /* Check if we're searching for HSP */
    if (hfpLinkIsHsp(link))
    {
        sp_ptr = (uint8 *) HspServiceRequest;
        sp_len = sizeof(HspServiceRequest);
    }

    /* Kick off the search */
    ConnectionSdpServiceSearchAttributeRequest(&theHfp->task, bd_addr, 0x32, sp_len, sp_ptr, sizeof(protocolAttributeRequest), protocolAttributeRequest);
}


/* Helper function to try an HSP search if HFP failed */
static void hfpSdpRetry(hfp_link_data* link)
{
    hfp_service_data* service;
    
    /* Mask out the profile that just failed */
    link->ag_profiles_to_try &= ~link->service->profile;
    /* Get whichever profile is left to try */
    service = hfpGetServiceFromProfile(link->ag_profiles_to_try);
    
    if(service)
    {
        bdaddr bd_addr;
        /* Ignore the result, link must have a bd_addr */
        (void)hfpGetLinkBdaddr(link, &bd_addr);
        
        /* Try the next service... */
        hfpGetProfileServerChannel(link, service, &bd_addr);
        return;
    }
    
    /* Nothing more to do, SLC has failed */
    hfpSendSlcConnectCfmToApp(link, NULL, hfp_connect_sdp_fail);
}


/****************************************************************************
NAME    
    hfpHandleServiceSearchAttributeCfm

DESCRIPTION
    Service search has completed, check it has succeeded and get the required
    attrubutes from the returned list.

RETURNS
    void
*/
void hfpHandleServiceSearchAttributeCfm(const CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm)
{
    /* Get the link from the bdaddr */
    hfp_link_data* link = hfpGetLinkFromBdaddr(&cfm->bd_addr);
    
    /* The link may have been pulled from under us by an early
    disconnect request. If this has happened ignore SDP result */
    if(link)
    {
        /* Check the outcome of the service search */
        if (cfm->status == sdp_response_success)
        {
            uint16 sdp_data  =  0;
            
            if(link->ag_slc_state == hfp_slc_searching)
            {
                if (getRfcommChannelNumber(cfm->attributes, cfm->attributes+cfm->size_attributes, &sdp_data))
                {
                    /* We have an rfcomm channel we can proceed with the connection establishment */
                    hfpSetLinkSlcState(link, hfp_slc_outgoing);
                    /* Use the local channel to specify the security requirements for this connection */
                    ConnectionRfcommConnectRequest(&theHfp->task, &cfm->bd_addr, link->service->rfc_server_channel, sdp_data, 0);
                }
                else
                {
                    /* Received unexpected data.  Should never happen since we're issuing the search and should 
                       know what we're looking.  However, if it does, treat as SDP failure.   */
                    hfpSdpRetry(link);
                }
            }
            else if(link->ag_slc_state == hfp_slc_connected)
            {
                /* If SLC is up then this must be a features request */
                if (getHfpAgSupportedFeatures(cfm->attributes, cfm->attributes+cfm->size_attributes, &sdp_data))
                {    /* Send an internal message with the supported features. */
                    hfpHandleSupportedFeaturesNotification(link, sdp_data);
                }
                /*
                else
                {
                    Received unexpected data.  Should never happen since we're issuing the search and should 
                    know what we're looking.  However, if it does, just ignore since SLC setup is already 
                    being continued.
                }
                */
            }
        }
        else
        {
            /* RFCOMM channel search failed, tell the application */
            if(link->ag_slc_state == hfp_slc_searching)
            {
                if (cfm->status == sdp_no_response_data)
                {
                    /* Retry next profile if possible... */
                    hfpSdpRetry(link);
                }
                else
                {
                    /* Generic fail by default */
                    hfp_connect_status status = hfp_connect_failed;
                    
                    /* Was it a page timeout? */
                    if (cfm->status == sdp_connection_error)
                        status = hfp_connect_timeout;
                    
                    /* Tell the app */
                    hfpSendSlcConnectCfmToApp(link, NULL, status);
                }
            }
        }
    }
}


/****************************************************************************
NAME    
    hfpGetAgSupportedFeatures

DESCRIPTION
    AG does not support BRSF command so we need to perform an SDP search
    to get its supported features.

RETURNS
    void
*/
void hfpGetAgSupportedFeatures(hfp_link_data* link)
{
    bdaddr link_addr;
    
    if (hfpGetLinkBdaddr(link, &link_addr))
    {
        /* 
            Issue the search request to the connection lib. The max number of attribute bytes
            is set to an arbitrary number, however the aim is to set it to a value so that
            if the remote end returns this many bytes we still have a block big enough to
            copy the data into. 
        */
        ConnectionSdpServiceSearchAttributeRequest(&theHfp->task, &link_addr, 0x32, sizeof(HfpServiceRequest), (uint8 *) HfpServiceRequest, sizeof(supportedFeaturesAttributeRequest), supportedFeaturesAttributeRequest);
    }
    else
    {
        /* Something has gone wrong - panic */
        HFP_DEBUG(("Failed to get link addr\n"));
    }
}
