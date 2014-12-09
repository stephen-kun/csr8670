/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_link_manager.c

DESCRIPTION
    The service manager provides commonly used functionality for accessing 
    services in hfp_task_data.

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_common.h"
#include "hfp_service_manager.h"
#include "hfp_link_manager.h"

/****************************************************************************
NAME    
    hfpGetServiceFromChannel

DESCRIPTION
    Get service data corresponding to a given RFC server channel

RETURNS
    Pointer to the corresponding hfp_service_data if successful. 
    Otherwise NULL.
*/
hfp_service_data* hfpGetServiceFromChannel(uint8 channel)
{
    hfp_service_data*  service;
    
    for_all_services(service)
        if(service->rfc_server_channel == channel)
            return service;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetServiceFromHandle

DESCRIPTION
    Get service data corresponding to a given service record handle

RETURNS
    Pointer to the corresponding hfp_service_data if successful. 
    Otherwise NULL.
*/
hfp_service_data* hfpGetServiceFromHandle(uint32 service_handle)
{
    hfp_service_data*  service;
    
    for_all_services(service)
        if(service->sdp_record_handle == service_handle)
            return service;
    
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetServiceFromProfile

DESCRIPTION
    Get service data for any service that supports given profile

RETURNS
    Pointer to the corresponding hfp_service_data if successful. 
    Otherwise NULL.
*/
hfp_service_data* hfpGetServiceFromProfile(hfp_profile profile)
{
    hfp_service_data*  service;
    
    for_all_services(service)
        if(service->profile & profile)
            return service;
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetDisconnectedServiceFromProfile

DESCRIPTION
    Get service data for any service that supports given profile and is not 
    in use by a link in hfp_slc_complete state

RETURNS
    Pointer to the corresponding hfp_service_data if successful. 
    Otherwise NULL.
*/
hfp_service_data* hfpGetDisconnectedServiceFromProfile(hfp_profile profile)
{
    hfp_service_data* service;
    
    for_all_services(service)
    {
        /* If service matches the profile */
        if(service->profile & profile)
        {
            /* If service is not connected then return it */
            hfp_link_data* link = hfpGetLinkFromService(service);
            if(link_is_disconnected(link))
            {
                return service;
            }
        }
    }
    return NULL;
}


/****************************************************************************
NAME    
    hfpGetVisibleServiceFromProfile

DESCRIPTION
    Get service data for any service that supports given profile and has a 
    visible SDP record

RETURNS
    Pointer to the corresponding hfp_service_data if successful. 
    Otherwise NULL.
*/
hfp_service_data* hfpGetVisibleServiceFromProfile(hfp_profile profile)
{
    hfp_service_data*  service;
    
    for_all_services(service)
        if((service->profile & profile) && service->sdp_record_handle)
            return service;
    return NULL;
}
