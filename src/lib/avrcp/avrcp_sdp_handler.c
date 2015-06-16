/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    avrcp_sdp_handler.c
    
DESCRIPTION
    This file includes function for registering the AVRCP Service Records and
    initiating the SDP search for supported features and profile descriptor 
    list.
*/
#include <Sink.h>
#include <Panic.h>
#include <memory.h>
#include <sdp_parse.h>
#include <connection.h>
#include "avrcp_sdp_handler.h"

/* Static Data structures for populating Service Records */
static const uint8 serviceClassController[] =
{
    0x09, 0x00, 0x01,           /* ServiceClassIDList(0x0001) */
        0x35, 0x06,             /* Data Element Sequence - 6 Bytes */
            0x19, 0x11, 0x0E,   /* UUID -  A/V Remote Control */
            0x19, 0x11, 0x0F    /* UUID - A/V Remote Control Controller */   
};

static const uint8 serviceClassTarget[] =
{
    0x09, 0x00, 0x01,           /* ServiceClassIDList(0x0001) */
        0x35, 0x03,             /* Data Element Sequence - 3 Bytes */
            0x19, 0x11, 0x0C    /* UUID -  A/V Remote Control Target */
};

static const uint8 protocolDescriptorList[] =
{
    0x09, 0x00, 0x04,           /* Protocol Descriptor List */
        0x35, 0x10,             /* Data Element Sequence - 16 Bytes */
            0x35, 0x06,         /* Data Element Sequence - 6 Bytes */
               0x19, 0x01, 0x00,/* L2CAP UUID */
               0x09, 0x00, 0x17,/* AVCTP PSM Value */
            0x035, 0x06,        /* Data Element Sequence - 6 Bytes */
               0x19, 0x00, 0x17,/* AVCTP UUID */
               0x09, 0x01, 0x04 /* AVCTP version 1.4 */
};

static const uint8 profileDescriptorList[] =
{
    0x09, 0x00, 0x09,           /* Profile Descriptor List */
        0x035, 0x08,            /* Data Element Sequence of 8 */
            0x035, 0x06,        /* Data Element Sequence of 6 */
               0x19, 0x11, 0x0E,/* A/V Remote Control UUID */
               0x09, 0x01, 0x05,/* AVRCP version 1.5 */
    0x09, 0x03 , 0x11,          /* Supported Features List */
        0x09, 0x00, 0x02        /* Default - Supports only Cat 2 */
};

/* Static data structures for SDP Attribute Request */
static const uint8 AvrcpAttributeRequest [] =
{
    0x35,0x06,                  /* Data Element Sequence of 6 */ 
        0x09, 0x00, 0x09,       /* ProfileDescriptorList Attribute ID */
        0x09, 0x03, 0x11        /* Supported Features Attribute ID*/
};

/* Static data structures for SDP Search from Controller */
static const uint8 AvrcpTargetServiceRequest [] =
{
    0x35, 0x03,                 /* Data Element Sequence of 3 */ 
        0x19, 0x11, 0x0C        /* AVRCP target service class UUID */
};

/* Request the service handle(s) of the AVRCP service at the CT */
static const uint8 AvrcpControllerServiceRequest [] =
{
    0x35, 0x03,                  /* Data Element Sequence of 3 */ 
        0x19, 0x11, 0x0E        /* AVRCP Controller service class UUID */
};

/*****************************************************************************
 *NAME    
 *  avrcpPrepareControllerRecord
 *
 *DESCRIPTION
 *  Allocate Memory and populate the Service Record for the Controller. 
 * 
 *PARAMETERS
 *  AVRCP*                  - Task
 *  uint16*                 - Length of the populated Service Record.  
 *
 *RETURN
 *  uint8*                  - Pointer to the populated Service Record.
 *****************************************************************************/
static uint8* avrcpPrepareControllerRecord(AvrcpDeviceTask *avrcp, 
                                           uint16 *record_len)
{
    uint8* service_record;
    uint16 size_record;

    size_record  =  sizeof(serviceClassController) + 
                    sizeof(protocolDescriptorList) +
                    sizeof(profileDescriptorList);

    /* Additional Protocol list of required if browsing is supported */
    if((avrcp->local_extensions & AVRCP_BROWSING_SUPPORTED) 
                            == AVRCP_BROWSING_SUPPORTED)
    {
         size_record += sizeof(protocolDescriptorList);
    }

    service_record = (uint8 *)PanicUnlessMalloc(size_record);

    /* Reset the size record to prepare for copy */
    size_record = 0;
    
    /* Copy the ServiceClassTarget */
    memmove(&service_record[size_record], serviceClassController,
            sizeof(serviceClassController));
    size_record +=  sizeof(serviceClassController);

    /* Copy the protocol Descriptor list */
    memmove(&service_record[size_record], protocolDescriptorList, 
            sizeof(protocolDescriptorList));
    size_record += sizeof(protocolDescriptorList);

    /* Populate Additional Protocol Descriptor list if required */
    if((avrcp->local_extensions & AVRCP_BROWSING_SUPPORTED)
                                 == AVRCP_BROWSING_SUPPORTED)
    {
        memmove(&service_record[size_record], protocolDescriptorList, 
                sizeof(protocolDescriptorList));
        service_record[size_record + AVRCP_PDL_ID_OFFSET] =
                                                 SDP_ADDITIONAL_PDL_ID;
        service_record[size_record + AVRCP_PDL_PSM_OFFSET] = 
                                                AVCTP_BROWSING_PSM;
        size_record += sizeof(protocolDescriptorList);
    }

    /* Copy the profile Descriptor List */
    memmove(&service_record[size_record],profileDescriptorList,
             sizeof(profileDescriptorList)); 
    service_record[size_record + AVRCP_SUPPORTED_FEATURES_OFFSET] =
                                avrcp->local_controller_features;

    *record_len = size_record +  sizeof(profileDescriptorList);

    return service_record;
}

/*****************************************************************************
 *NAME    
 *  avrcpPrepareTargetRecord
 *
 *DESCRIPTION
 *  Allocate Memory and populate the Service Record for the Target. 
 * 
 *PARAMETERS
 *  AVRCP*                  - Task
 *  uint16*                 - Length of the populated Service Record.  
 *
 *RETURN
 *  uint8*                  - Pointer to the populated Service Record.
 *****************************************************************************/
static uint8* avrcpPrepareTargetRecord(AvrcpDeviceTask *avrcp, 
                                       uint16 *record_len)
{
    uint8* service_record;
    uint16 size_record;
    uint8  version = AVRCP_PDL_VERSION_10; 

    size_record  =  sizeof(serviceClassTarget) + 
                    sizeof(protocolDescriptorList) +
                    sizeof(profileDescriptorList);

    
    /* If Browsing is not supported and not category 2 only, fall back to 
       version 1.3 , because Browsing is mandatory to support on Cat 1 or 3.
       If Player application settings and Group navigation are not supported 
       and not category 2 only, fall back to  version 1.0 */

    if((avrcp->local_target_features & AVRCP_CATEGORY_2) ||
      ((avrcp->local_extensions & AVRCP_BROWSING_SUPPORTED) == 
                                AVRCP_BROWSING_SUPPORTED))
    {
        version = AVRCP_PDL_VERSION_15;
    }
    else if(((avrcp->local_target_features & AVRCP_GROUP_NAVIGATION) 
                                          == AVRCP_GROUP_NAVIGATION) ||
            (avrcp->local_target_features & AVRCP_PLAYER_APPLICATION_SETTINGS)
                                         == AVRCP_PLAYER_APPLICATION_SETTINGS)
    {
        version = AVRCP_PDL_VERSION_13;
    }

    /* If SDP record indicates support for Category 1 or Category 3, 
       then SDP record shall contain the Additional Protocol Descriptor 
       List for the Browsing channel. Meta Data support will turn ON 
       Category 1 and 3 Support. */
    if((avrcp->local_target_features & (AVRCP_CATEGORY_1 | AVRCP_CATEGORY_3)) 
        && (version == AVRCP_PDL_VERSION_15))
    {
        size_record += sizeof(protocolDescriptorList);
    }

    service_record = (uint8 *)PanicUnlessMalloc(size_record);

    /* Reset the size record to prepare for copy */
    size_record = 0;
    
    /* Copy the ServiceClassTarget */
    memmove(&service_record[size_record], serviceClassTarget,
            sizeof(serviceClassTarget));
    size_record +=  sizeof(serviceClassTarget);
    /* Copy the protocol Descriptor list */
    memmove(&service_record[size_record], protocolDescriptorList, 
            sizeof(protocolDescriptorList));    
    if (version == AVRCP_PDL_VERSION_13)
        service_record[size_record + AVRCP_PROTOCOL_VERSION_OFFSET] = 2; /* AVCTP v1.2 for AVRCP v1.3 */
    else if (version == AVRCP_PDL_VERSION_10)
        service_record[size_record + AVRCP_PROTOCOL_VERSION_OFFSET] = 0; /* AVCTP v1.0 for AVRCP v1.0 */         
    size_record += sizeof(protocolDescriptorList);

    /* Copy the Additional Protocol List if required */
    if ((avrcp->local_target_features & (AVRCP_CATEGORY_1 | AVRCP_CATEGORY_3)) 
        && (version == AVRCP_PDL_VERSION_15))
    {
        memmove(&service_record[size_record], protocolDescriptorList, 
                sizeof(protocolDescriptorList));
        service_record[size_record + AVRCP_PDL_ID_OFFSET] =
                                                 SDP_ADDITIONAL_PDL_ID;
        service_record[size_record + AVRCP_PDL_PSM_OFFSET] = 
                                                AVCTP_BROWSING_PSM;
        size_record += sizeof(protocolDescriptorList);
    }

    /* Copy the profile Descriptor List */
    memmove(&service_record[size_record],profileDescriptorList,
             sizeof(profileDescriptorList)); 
    service_record[size_record + AVRCP_PDL_VERSION_OFFSET] = version;
    service_record[size_record + AVRCP_SUPPORTED_FEATURES_OFFSET] =
                                avrcp->local_target_features;

    *record_len = size_record +  sizeof(profileDescriptorList);

    return service_record;
}
/*****************************************************************************
 *NAME    
 *  avrcpSendGetSupportedFeaturesCfm
 *
 *DESCRIPTION
 *   Send GetSupportedFeatures confirmation message to the application task.
 * 
 *PARAMETERS
 *  AVRCP*                  - Task
 *  avrcp_status_code       - Status of AvrcpGetSupportedFeatures() request.
 *  features                - Supported features Attributes of the remote.
 *
 *RETURN
 *****************************************************************************/
void avrcpSendGetSupportedFeaturesCfm(AVRCP            *avrcp,
                                     avrcp_status_code status,
                                     uint16            features)
{
    MAKE_AVRCP_MESSAGE(AVRCP_GET_SUPPORTED_FEATURES_CFM);
    message->avrcp = avrcp;
    message->status = status;
    message->features = features;
    MessageSend(avrcp->clientTask, AVRCP_GET_SUPPORTED_FEATURES_CFM, message);
}

/*****************************************************************************
 *NAME    
 *  avrcpSendGetExtensionsCfm
 *
 *DESCRIPTION
 *   Send Profile extensions confirmation message to the application task.
 * 
 *PARAMETERS
 *  AVRCP*                  - Task
 *  avrcp_status_code       - Status of AvrcpGetProfileExtensions() request.
 *  extensions              - Extension flag showing remote support of 
 *                            AVRCP v1.3 or Browsing support.
 *
 *RETURN
 *****************************************************************************/
void avrcpSendGetExtensionsCfm(AVRCP             *avrcp,
                               avrcp_status_code status,
                               uint16            extensions)
{
    MAKE_AVRCP_MESSAGE(AVRCP_GET_EXTENSIONS_CFM);
    message->avrcp = avrcp;
    message->status = status;
    message->extensions = extensions;
    MessageSend(avrcp->clientTask, AVRCP_GET_EXTENSIONS_CFM, message);
}

/*****************************************************************************
 *NAME    
 *  avrcpRegisterServiceRecord
 *
 *DESCRIPTION
 *    Register the SDP Service Records for Avrcp.
 * 
 *PARAMETERS
 *  *                  - Task
 *
 *RETURN
 *****************************************************************************/
void avrcpRegisterServiceRecord(AvrcpDeviceTask *avrcp)
{
    uint16 size_record = 0;
    uint8 *service_record = 0;

   /* If the device_type is set to target and controller, Library registers 
      the Controller record first and set the state as registration is still
      in progress. Registration of Target will be completed when this function 
      is calling second time after a successfull CT record registration. */
   
    switch(avrcp->device_type)
    {
    /* Register TG record now. CT Registeration is completed. Set the 
       device_type showing that Target and Controller are enabled. */
    case avrcp_ct_tg_progress:  
        avrcp->device_type =  avrcp_ct_tg;  

    case avrcp_tg:              /* Fall Through */
        service_record = avrcpPrepareTargetRecord(avrcp, &size_record);
        break;
    
    /* Register CT record first and set the device_type as
       TG record registration is not yet completed. TG registation will be
       completed when this function is called next time after the successful
       CT registration. */   
    case avrcp_ct_tg:          
        avrcp->device_type = avrcp_ct_tg_progress; 

    case avrcp_ct:              /* Fall Through */
        service_record = avrcpPrepareControllerRecord(avrcp, &size_record);
        break;

    /* default: Not required. All enum values are covered. */ 
    }

    /* Register the service record */
    ConnectionRegisterServiceRecord(avrcpGetInitTask(),
                                    size_record, 
                                    service_record);
}

/*****************************************************************************
 *NAME    
 *  avrcpHandleSdpRegisterCfm
 *
 *DESCRIPTION
 *  This function is called on receipt of an CL_SDP_REGISTER_CFM
 *  indicating the outcome of registering a service record. 
 * 
 *PARAMETERS
 *  AVRCP*                  - Task
 *  CL_SDP_REGISTER_CFM_T*  - Register Cfm message from Connection library.
 *
 *RETURN
 *****************************************************************************/
void avrcpHandleSdpRegisterCfm(const CL_SDP_REGISTER_CFM_T *cfm)
{
    AvrcpDeviceTask* avrcp=  avrcpGetDeviceTask();

    if ((avrcp->device_type == avrcp_ct_tg_progress) && 
        (cfm->status == success))
    {
        /* One more service record to register */
        avrcpRegisterServiceRecord(avrcp);
    }
    else
    {
        /* Send an initialisation confirmation with the 
           result of the SDP registration */
        avrcpSendInitCfmToClient(avrcp_unreg_all, 0,
                           cfm->status==success ? avrcp_success : avrcp_fail);
    }
}

/*****************************************************************************
 *NAME    
 *  avrcpSdpStateOnConnect
 *
 *DESCRIPTION
 *  This function is called on establishing the L2CAP connection 
 *  for AVRCP to notify the SDP state machine to set its state on 
 *  AVRCP connection. 
 * 
 *PARAMETERS
 *  AVRCP*                  - Task
 *
 *RETURN
 *****************************************************************************/
void avrcpSdpStateOnConnect(AVRCP *avrcp)
{        
    typed_bdaddr tg_addr;

    switch(avrcp->sdp_search_mode)
    {
        case avrcp_sdp_search_and_connect_pending:
            avrcp->sdp_search_mode = avrcp_sdp_search_pending;
            break;

        case avrcp_sdp_search_done_connect_pending:
            avrcp->sdp_search_mode = avrcp_sdp_search_none;
            break;

        case avrcp_sdp_search_none:
          /* Initiate Search, only if the local device supports
             Controller role */
            if((!isAvrcpSdpDone(avrcp)) &&
               (SinkGetBdAddr(avrcp->sink, &tg_addr)) &&
                avrcpGetDeviceTask()->device_type != avrcp_tg)
            {
                avrcpSdpSearchRequest( avrcp, 
                                       &tg_addr.addr, 
                                       avrcp_sdp_search_pending);
            }
            break;

        default:
           break;

    }
}

/*****************************************************************************
 *NAME    
 *  avrcpHandleServiceSearchAttributeCfm
 *
 *DESCRIPTION
 *  Handle CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM for the SDP search
 * 
 *PARAMETERS
 *  AVRCP*                                  - Task
 *  CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T*  - Search Confirmation
 *
 *RETURN
 *****************************************************************************/
void avrcpHandleServiceSearchAttributeCfm(AVRCP *avrcp,
                     const CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm)
{
    uint16 version = 0;
    uint16 extensions = 0;
    uint16 features = 0;
    avrcp_status_code status = avrcp_fail;
    avrcp_device_role device_type = avrcpGetDeviceTask()->device_type; 
 
    if((cfm->status == sdp_no_response_data) && (!avrcp->sdp_search_repeat)
        && (device_type== avrcp_ct_tg))
    {
        /* Completed a Service Search by assuming that the remote device is 
           a Target. Repeat the search for Controller. This happens if the
           local device is initialized as target and controller */
           avrcp->sdp_search_repeat = 1;
           ConnectionSdpServiceSearchAttributeRequest(&avrcp->task,
                             (const bdaddr*) &cfm->bd_addr, 0x32, 
                             sizeof(AvrcpControllerServiceRequest),
                             (uint8*)AvrcpControllerServiceRequest,
                             sizeof(AvrcpAttributeRequest),
                             AvrcpAttributeRequest);
           return;
    }

    /* Extract the profile version from the Profile Descriptor list and
       Supported features on successfull attribute search */
    if (cfm->status == sdp_response_success)
    {
        /* Extract the Version */
        SdpParseGetProfileVersion(cfm->size_attributes,
                                  (uint8*)cfm->attributes, 
                                  0x110e, &version);

        /* Extract the supported Features */
        SdpParseGetSupportedFeatures(cfm->size_attributes,
                                     (uint8*)cfm->attributes, 
                                     &features);
    
        if(features)
        {
            status = avrcp_success;
            
            if ((version == AVRCP_PDL_FULL_VERSION_15) || (version == AVRCP_PDL_FULL_VERSION_14))
            {
                if (version == AVRCP_PDL_FULL_VERSION_15)
                {
                    extensions = AVRCP_VERSION_1_5;
                }
                else 
                {
                    extensions = AVRCP_VERSION_1_4;
                }                    

                /* Browsing is supported either 
                   1. File System browsing bit is set irrespective of TG or CT.
                   2. Remote 1.4 Target device supports CAT 1 or 3. To validate
                     the record is from Target, check local device is either 
                     Controller or library has not repeated the search for 
                     Controller record */
                if(((!avrcp->sdp_search_repeat && 
                     device_type != avrcp_tg) &&
                    (features & (AVRCP_CATEGORY_1 | AVRCP_CATEGORY_3))) ||
                    (features & AVRCP_VIRTUAL_FILE_SYSTEM_BROWSING))
                {
                    extensions |= AVRCP_BROWSING_SUPPORTED;
                }
            }
            else if(version == AVRCP_PDL_FULL_VERSION_13)
            {
                extensions = AVRCP_VERSION_1_3;
            }
        }
    }

    /* sdp_search_mode state machine is also accessed from l2cap_handler.c  
       using avrcpSdpStateOnConnect() while handling L2CAP_CONNECT_CFM  to
       set the state for  L2CAP connection status. */ 
    switch (avrcp->sdp_search_mode)
    {
    case avrcp_sdp_search_app_features:
        avrcpSendGetSupportedFeaturesCfm(avrcp, status, features);
        avrcp->sdp_search_mode = avrcp_sdp_search_none;
        break;

    case avrcp_sdp_search_app_profile_version:
        avrcpSendGetExtensionsCfm(avrcp, status, extensions);

    case avrcp_sdp_search_pending: /* Fall through */
        avrcp->sdp_search_mode = avrcp_sdp_search_none;
        break;

    /* L2CAP connection for AVRCP is not yet completed */
    case avrcp_sdp_search_and_connect_pending:
        avrcp->sdp_search_mode = avrcp_sdp_search_done_connect_pending;
        break;

    default:
        break;
    }

    avrcp->remote_extensions = extensions;
    avrcp->remote_features = features; 
    avrcp-> sdp_search_repeat = 0;

    /* Completed a Internal SDP query. Cancel any outstanding requests */
    MessageCancelAll(&avrcp->task, AVRCP_INTERNAL_SDP_SEARCH_REQ);
}

/*****************************************************************************
 *NAME    
 *  avrcpSdpSearchRequest
 *
 *DESCRIPTION
 *  Initiate an SDP Search Attriibute request to get the profile version and 
 *  supported features.
 * 
 *PARAMETERS
 *  AVRCP*            - Task
 *  bdaddr*           - BD ADDR of remote device
 *  avrcp_sdp_search  - SDP Search mode      
 *
 *RETURN
 *****************************************************************************/
void avrcpSdpSearchRequest(AVRCP           *avrcp, 
                     const bdaddr          *addr, 
                           avrcp_sdp_search mode)
{
    uint8* service_request= NULL;

      /* Set the search mode */
    avrcp->sdp_search_mode = mode;  

    if(avrcpGetDeviceTask()->device_type ==  avrcp_tg)
    {
        service_request = (uint8*)AvrcpControllerServiceRequest;
    }
    else /* Controller or Both */
    {
        service_request = (uint8*)AvrcpTargetServiceRequest;
    }
    
    ConnectionSdpServiceSearchAttributeRequest(&avrcp->task,
                             addr, 0x32, sizeof(AvrcpTargetServiceRequest),
                             service_request,
                             sizeof(AvrcpAttributeRequest),
                             AvrcpAttributeRequest);


}

/*****************************************************************************
 *NAME    
 *  avrcpGetProfileVersion
 *
 *DESCRIPTION
 *  Initiate an SDP Search Attriibute request to get the profile version. This 
 *  is triggered by the application. 
 * 
 *PARAMETERS
 *  AVRCP*            - Task
 *
 *RETURN
 *****************************************************************************/
void avrcpGetProfileVersion(AVRCP *avrcp)
{
    typed_bdaddr tg_addr;

    if (SinkGetBdAddr(avrcp->sink, &tg_addr))
    {
        avrcpSdpSearchRequest(avrcp, &tg_addr.addr, 
                              avrcp_sdp_search_app_profile_version);
    }
    else
    {   
        avrcpSendGetExtensionsCfm(avrcp, avrcp_device_not_connected, 0);  
    }
}

/*****************************************************************************
 *NAME    
 *  avrcpGetSupportedFeatures
 *
 *DESCRIPTION
 *  Initiate an SDP Search Attriibute request to get Supported features. This 
 *  is triggered by the application. 
 * 
 *PARAMETERS
 *  AVRCP*            - Task
 *
 *RETURN
 *****************************************************************************/
void avrcpGetSupportedFeatures(AVRCP *avrcp)
{
    typed_bdaddr tg_addr;

    if (SinkGetBdAddr(avrcp->sink, &tg_addr))
    {
        avrcpSdpSearchRequest(avrcp, &tg_addr.addr, avrcp_sdp_search_app_features);
    }
    else
    {
       avrcpSendGetSupportedFeaturesCfm(avrcp, avrcp_device_not_connected, 0);
    }
}

