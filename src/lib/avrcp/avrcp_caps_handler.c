/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2004-2014
Part of ADK 3.5

FILE NAME
    avrcp_caps_handler.c        

DESCRIPTION
    This file defines the internal functions for handling GetCapabilities     

NOTES

*/


/****************************************************************************
    Header files
*/
#include <Panic.h>
#include "avrcp_caps_handler.h"
#include "avrcp_metadata_transfer.h"
#include "avrcp_init.h"

#ifndef AVRCP_TG_ONLY_LIB /* Disable CT for TG only lib */

/****************************************************************************
* NAME    
*   avrcpSendGetCapsCfm    
*
* DESCRIPTION
*   Internal function for sending AVRCP_GET_CAPS_CFM message to CT app. 
*
* RETURNS
*    void
********************************************************************************/
void avrcpSendGetCapsCfm(   AVRCP               *avrcp, 
                            avrcp_status_code   status, 
                            uint16              metadata_packet_type, 
                            avrcp_capability_id caps_id, 
                            uint16              number_of_caps, 
                            uint16              data_length, 
                            Source              source)
{
    /* Send successful confirmation message up to app. */
    MAKE_AVRCP_MESSAGE(AVRCP_GET_CAPS_CFM);

    message->avrcp = avrcp;    
    message->status = status;
    message->metadata_packet_type = metadata_packet_type;
    message->caps = caps_id;
    message->number_of_caps = number_of_caps;
    message->size_caps_list = data_length;
    message->caps_list = source;

#ifdef AVRCP_ENABLE_DEPRECATED 
    /* Deprecated fields and will be removed later */
    if(avrcp->av_msg)
    {
        message->transaction = (avrcp->av_msg[AVCTP_HEADER_START_OFFSET] >> 
                                AVCTP0_TRANSACTION_SHIFT);
    }
    message->no_packets = 1;
    message->ctp_packet_type = AVCTP0_PACKET_TYPE_SINGLE;
    message->data_offset = 0;
#endif

    MessageSend(avrcp->clientTask, AVRCP_GET_CAPS_CFM, message);
}


/****************************************************************************
* NAME    
*   avrcpHandleGetCapsResponse    
*
* DESCRIPTION
*   Handle the incoming GetCapabilities response from the TG
*
* RETURNS
*    void
********************************************************************************/
void avrcpHandleGetCapsResponse(AVRCP               *avrcp, 
                                avrcp_response_type response, 
                                uint16              meta_packet_type, 
                                const uint8*        ptr,
                                uint16              packet_size)
{
    Source source=0;
    avrcp_status_code status= convertResponseToStatus(response);
    avrcp_capability_id caps_id=0; 
    uint16  number_of_caps=0; 

    /*    
        Process the response PDU. Just ignore this response if it was not
        a pending event (ie. Check the command was sent in the first place).
    */
    if(response == avctp_response_rejected)
    {
        if(packet_size)
        {
            /* Get the avrcp_status_code value from the error status value */
            status = ptr[0]+  AVRCP_ERROR_STATUS_BASE;
            packet_size--;
        }
            
    }
    else if ((meta_packet_type == avrcp_packet_type_single) || 
             (meta_packet_type == avrcp_packet_type_start))
    {
            /* Extract the first 2 bytes which is capability ID and 
            capability length */
            if(packet_size < 2)
            {
                packet_size = 0;
            }
            else
            {
                caps_id = ptr[0];
                number_of_caps = ptr[1];
                packet_size-=2;
                ptr+=2;
            }
    }
            

    if(packet_size)
    {
        source = avrcpSourceFromConstData(avrcp, ptr, packet_size);
        if(!source)
           packet_size=0;    
    }

    avrcpSendGetCapsCfm(avrcp, status, meta_packet_type,
                        caps_id, number_of_caps, packet_size, source);

    return;
}

#endif /* !AVRCP_TG_ONLY_LIB */

#ifndef AVRCP_CT_ONLY_LIB /* Disable TG for CT only lib */
/****************************************************************************
* NAME    
*   avrcpHandleInternalGetCapsResponse    
*
* DESCRIPTION
*   Internal function for AvrcpGetCapabilitiesResponse
*
* RETURNS
*    void
*******************************************************************************/
void avrcpHandleInternalGetCapsResponse(AVRCP                         *avrcp, 
                                        AVRCP_INTERNAL_GET_CAPS_RES_T *res)
{
    uint16 size_mandatory_data = 1;  /* Just error code for failure */
    uint8 mandatory_data[5];
    AvrcpDeviceTask * avrcp_task = avrcpGetDeviceTask();
    
    /* Get the error status code */
    mandatory_data[0] = avrcpGetErrorStatusCode(&res->response,
                                                 AVRCP0_CTYPE_STATUS);

    if (res->response == avctp_response_stable)
    {
        uint16 size_mandatory_caps = 0; /* mandatory caps size */

        if (res->caps_id == avrcp_capability_event_supported)
        {
            /* determine the category AVRCP was initialised with and 
               format response accordingly */
            if(avrcp_task->local_target_features & AVRCP_CATEGORY_2)
            {
                /* category 2 */                
                if(avrcp_task->local_extensions & AVRCP_VERSION_1_4)
                    size_mandatory_caps = AVRCP_CAPS_EVENTS_SIZE_CAT_2;
            }
            else
            {
                /* categories 1, 3 and 4 */    
                size_mandatory_caps = AVRCP_CAPS_EVENTS_SIZE;
            }
        }
        else /* must be company ID */
        {
            size_mandatory_caps = AVRCP_CAPS_COMPANY_ID_SIZE;
        }

        /* cap id (1) + cap len (1) + mandatory caps */
        size_mandatory_data = 2 + size_mandatory_caps;


        /* Insert the mandatory ids */
        mandatory_data[0] = res->caps_id;

        if (res->caps_id == avrcp_capability_event_supported)
        {
            /*Insert the mandatory events supported data 
              if this is the capability being returned. */
            mandatory_data[1] = size_mandatory_caps + res->size_caps_list;

            /* return the mandatory features based on current category */
            if(avrcp_task->local_target_features & AVRCP_CATEGORY_2)              
            {  
                if(avrcp_task->local_extensions & AVRCP_VERSION_1_4)
                    mandatory_data[2] = avrcp_event_volume_changed;
            }
            else
            {
                /* categories 1, 3 and 4 */    
                mandatory_data[2] = avrcp_event_playback_status_changed;
                mandatory_data[3] = avrcp_event_track_changed;
            }
        }
        else
        {
            /* Must be Company ID request. No Defensive programming here */
            mandatory_data[1] = (res->size_caps_list/3) + 1;
            mandatory_data[2] = (AVRCP_BT_COMPANY_ID >> 16) & 0xff;
            mandatory_data[3] = (AVRCP_BT_COMPANY_ID >> 8) & 0xff;
            mandatory_data[4] = AVRCP_BT_COMPANY_ID & 0xff;
        }
    }
    else
    {
        res->size_caps_list=0;
    }


    prepareMetadataStatusResponse(  avrcp, 
                                    res->response, 
                                    AVRCP_GET_CAPS_PDU_ID, 
                                    size_mandatory_data + res->size_caps_list, 
                                    res->caps_list, 
                                    size_mandatory_data, 
                                    mandatory_data);
}


/****************************************************************************
* NAME    
*   avrcpHandleGetCapsCommand    
*
* DESCRIPTION
*   Handle the incoming GetCapabilities command and send AVRCP_GET_CAPS_IND
*   message to TG app.
*
* RETURNS
*    void
********************************************************************************/
void avrcpHandleGetCapsCommand(AVRCP *avrcp, avrcp_capability_id caps)
{
    /* Send an indication up to the app that this PDU command has arrived. */
    MAKE_AVRCP_MESSAGE(AVRCP_GET_CAPS_IND);
    message->avrcp = avrcp;
#ifdef AVRCP_ENABLE_DEPRECATED  
    message->transaction = avrcp->rsp_transaction_label;
#endif
    message->caps = caps;
    MessageSend(avrcp->clientTask, AVRCP_GET_CAPS_IND, message);
}

#endif /* !AVRCP_CT_ONLY_LIB*/

