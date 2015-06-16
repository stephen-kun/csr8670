/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2014

FILE NAME
    sink_ble_advertising.c

DESCRIPTION
    BLE Advertising functionality
*/

/* Application includes */
#include "sink_ble_advertising.h"
#include "sink_ble_remote_control.h"
#include "sink_private.h"
#include "sink_debug.h"
#include "sink_gatt_server.h"
#include "sink_gatt.h"
#include "sink_utils.h"

/* Library includes */
#include <connection.h>
#include <gatt.h>

/* Firmware includes */
#include <csrtypes.h>
#include <stdlib.h>
#include <string.h>

/* Macro for BLE AD Data Debug */
#ifdef DEBUG_BLE
#include <stdio.h>
#define BLE_AD_DEBUG(x) DEBUG(x)
#else
#define BLE_AD_DEBUG(x) 
#endif


#if defined(GATT_SERVER_ENABLED) && defined(BLE_ENABLED)

/*******************************************************************************
NAME    
    setup_flags_ad_data

DESCRIPTION
    Helper function to setup the advertising data, flags (MUST be advertised)
*/
static void setup_flags_ad_data(builtAdData_t * ad_data_ptr)
{
    #define FLAGS_AD_DATA_LENGTH 0x3
    
    /* Setup the advertising flags required to advertise data */
    ad_data_ptr->size = FLAGS_AD_DATA_LENGTH;
    
    /* Setup the flags ad data */
    ad_data_ptr->ptr = malloc(ad_data_ptr->size);
    ad_data_ptr->ptr[0] = 0x02;
    ad_data_ptr->ptr[1] = ble_ad_type_flags;
    ad_data_ptr->ptr[2] = BLE_FLAGS_GENERAL_DISCOVERABLE_MODE | BLE_FLAGS_DUAL_HOST;
    
#ifdef DEBUG_BLE
    {
        uint16 counter;
        BLE_AD_DEBUG(("AD Data: flags = ["));
        for (counter=0; counter < ad_data_ptr->size; counter++)
        {
            BLE_AD_DEBUG(("%02x,", ad_data_ptr->ptr[counter]));
        }
        BLE_AD_DEBUG(("]\n"));
    }
#endif
}


/*******************************************************************************
NAME    
    setup_flags_ad_data

DESCRIPTION
  Helper function to setup the services advertisement data
*/
static void setup_services_ad_data(builtAdData_t * ad_data_ptr, uint16 num_free_octets)
{
    /* How many services have been defined? */
    uint16 counter;
    uint16 num_services;
    uint8 ad_tag;
    bool complete_list;

#ifdef GATT_SERVER_BAS_ENABLED
    num_services = 1;
#else
    num_services = 0;
#endif
    
    /* Is there enough room to store the complete list of services defined for the device? */
    if ( (AD_DATA_HEADER_SIZE + (num_services*OCTETS_PER_SERVICE)) <= num_free_octets )  
    {
        /* Advertise complete list */
        ad_tag = ble_ad_type_complete_uuid16;
        complete_list = TRUE;
        
        /* Allocate enough memory to store the complete list of services defined for the device */
        ad_data_ptr->size = (AD_DATA_HEADER_SIZE + (num_services*OCTETS_PER_SERVICE));    
        ad_data_ptr->ptr = malloc(ad_data_ptr->size);
    }
    else
    {
        /* Advertise incomplete list (only advertise the first service based on alpabetical priority) */
        ad_tag = ble_ad_type_more_uuid16;
        complete_list = FALSE;
        
        /* Allocate enough memory to store the services defined for the device */
        ad_data_ptr->size = (AD_DATA_HEADER_SIZE + OCTETS_PER_SERVICE);
        ad_data_ptr->ptr = malloc(ad_data_ptr->size);
    }
    
    /* Setup AD data for the services */
    ad_data_ptr->ptr[0] = ad_data_ptr->size - 1;   /* Do not count the 'length' value; length is AD_TAG + AD_DATA */
    ad_data_ptr->ptr[1] = ad_tag;                  /* AD_TAG (either complete or incomplete list of uint16 UUIDs */
    
    /* Start adding services from this position in the ad_data memory */
    counter = AD_DATA_HEADER_SIZE;
    
    /* Depending on which services have been defined, build the AD data */
    BLE_AD_DEBUG(("AD Data: services num=%d, included=", num_services));  

    
#ifdef GATT_SERVER_BAS_ENABLED
        BLE_AD_DEBUG(("Battery Service, "));
        ad_data_ptr->ptr[counter] = (GATT_SERVICE_UUID_BATTERY_SERVICE & 0xFF);
        counter++;
        ad_data_ptr->ptr[counter] = (GATT_SERVICE_UUID_BATTERY_SERVICE >> 8);
        counter++;
        if (!complete_list) return;
#endif    
    
    BLE_AD_DEBUG(("\n"));
    
#ifdef DEBUG_BLE
    BLE_AD_DEBUG(("AD Data: services = ["));
    for (counter=0; counter < ad_data_ptr->size; counter++)
    {
        BLE_AD_DEBUG(("%02x,", ad_data_ptr->ptr[counter]));
    }
    BLE_AD_DEBUG(("]\n"));
#endif
}


/*******************************************************************************
NAME    
    setup_local_name_advertising_data

DESCRIPTION
    Helper function to setup advertising data to advertise the devices local 
    name used by remote devices scanning for BLE services
*/      
static void setup_local_name_advertising_data(builtAdData_t * ad_data_ptr, uint16 size_local_name, uint8 * local_name, uint16 ad_data_free_space)
{
    uint8 ad_tag, ad_name_length;
    
    /* Is there a local name to be advertised? If so, is there enough free space in AD Data to advertise it? */
    if (size_local_name == 0)
    {
        /* No local name to advertise */
        ad_data_ptr->size = 0;
        return;
    }
    else if (ad_data_free_space < AD_DATA_HEADER_SIZE + 1)
    {
        /* Not enough space in AD Data to advertise the local name (nor a shortened local name of just 1 char) */
        ad_data_ptr->size = 0;
        return;
    }
    else if ((AD_DATA_HEADER_SIZE + size_local_name) < ad_data_free_space)
    {
        /* Can advertise the complete local name */
        ad_tag = ble_ad_type_complete_local_name;
        ad_name_length = size_local_name;
    }
    else
    {
        /* Can advertise a shortened local name */
        ad_tag = ble_ad_type_shortened_local_name;
        ad_name_length = ad_data_free_space - 2;
    }
    
    /* Setup the local name advertising data */
    ad_data_ptr->size = ad_name_length + AD_DATA_HEADER_SIZE;
    ad_data_ptr->ptr = malloc(ad_data_ptr->size);
    ad_data_ptr->ptr[0] = ad_name_length + 1;
    ad_data_ptr->ptr[1] = ad_tag;
    memmove(&ad_data_ptr->ptr[2], local_name, ad_name_length);
    
#ifdef DEBUG_BLE
    {
        uint16 i;
        BLE_AD_DEBUG(("AD Data: local name=[%02x,%02x,", ad_data_ptr->ptr[0], ad_data_ptr->ptr[1]));
        for (i=2; i<ad_name_length + AD_DATA_HEADER_SIZE; i++)
        {
            BLE_AD_DEBUG(("%c,", ad_data_ptr->ptr[i]));
        }
        BLE_AD_DEBUG(("]\n"));
    }
#endif
}


/******************************************************************************/
void setup_ble_ad_data(uint16 size_local_name, uint8 *local_name)
{
    uint16 ad_data_index = 0;
    uint16 ad_data_num_free_octets = MAX_AD_DATA_SIZE_IN_OCTECTS;
    builtAdData_t temp;
    uint8 * ad_data;
    
    /* Setup the flags advertising data */
    setup_flags_ad_data(&temp);
    
    /* Add the flags to advertising data & update indexes/counters */
    ad_data = malloc(temp.size);
    memmove(&ad_data[ad_data_index], temp.ptr, temp.size);
    ad_data_num_free_octets -= temp.size;   /* Update number of free octets in AD data */
    ad_data_index += temp.size;             /* Update the ad_data index to point to the next free octet in AD data */
    free(temp.ptr);                         /* De-allocate memory ready for next advertising data chunk */
    
    BLE_AD_DEBUG(("AD Data: flags added, free=%d\n", ad_data_num_free_octets));
    
    /* Setup the services advertising data */
    setup_services_ad_data(&temp, ad_data_num_free_octets);
    ad_data = realloc(ad_data, (temp.size) + ad_data_index);
    memmove(&ad_data[ad_data_index], temp.ptr, temp.size);
    ad_data_num_free_octets -= temp.size;   /* Update number of free octets in AD data */
    ad_data_index += temp.size;             /* Update the ad_data index to point to the next free octet in AD data */
    free(temp.ptr);                         /* De-allocate memory ready for next advertising data chunk */
    
    BLE_AD_DEBUG(("AD Data: services added, free%d\n", ad_data_num_free_octets));
    
    /* Setup the local name advertising data */
    setup_local_name_advertising_data(&temp, size_local_name, local_name, ad_data_num_free_octets);
    
    /* Was there enough free space to add the local name to AD data? */
    if (temp.size)
    {
        ad_data = realloc(ad_data, temp.size + ad_data_index);
        memmove(&ad_data[ad_data_index], temp.ptr, temp.size);
        ad_data_num_free_octets -= temp.size;   /* Update number of free octets in AD data */
        ad_data_index += temp.size;             /* Update the ad data index so it now counts the total number of octets in the AD data */
        free(temp.ptr);                         /* Tidy up to avoid a memory leak */
        
        BLE_AD_DEBUG(("AD Data: local name added, free=%d\n", ad_data_num_free_octets));
    }
    
    /* Register AD data with the Connection library & Tidy up allocated memory*/
    ConnectionDmBleSetAdvertisingDataReq(ad_data_index, ad_data);
    free (ad_data);
}


/******************************************************************************/
void handle_set_ble_ad_data_cfm(CL_DM_BLE_SET_ADVERTISING_DATA_CFM_T * cfm)
{
    if (cfm->status == success)
    {
        BLE_AD_DEBUG(("CL : AD Data registered\n"));
        theSink.rundata->gatt.server.ad_data_valid = TRUE;
    }
    else
    {
        BLE_AD_DEBUG(("CL : AD Data failed to be registered [%x]\n", cfm->status));
        theSink.rundata->gatt.server.ad_data_valid = FALSE;
    }
}


/******************************************************************************/
bool start_ble_advertising(void)
{
    /* If AD Data has been registered, can start advertising */
    if (theSink.rundata->gatt.server.ad_data_valid)
    {
        BLE_AD_DEBUG(("BLE : Start AD\n"));
        ConnectionDmBleSetAdvertiseEnable(TRUE);
        return TRUE;
    }
    else
    {
        BLE_AD_DEBUG(("BLE : Start AD [AD Data not registered]\n"));
        return FALSE;
    }
}


/******************************************************************************/
void stop_ble_advertising(void)
{
    BLE_AD_DEBUG(("BLE : Stop AD\n"));
    ConnectionDmBleSetAdvertiseEnable(FALSE);
}



#elif defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED)


/*******************************************************************************
NAME
    handle_ble_connectable_discoverable_adverts
    
DESCRIPTION
    Helper function to handle connectable, undirected adverts
*/
static void handle_ble_connectable_discoverable_adverts(CL_DM_BLE_ADVERTISING_REPORT_IND_T * ind)
{
    /* Parse the incoming AD Data, for each AD_ELEMENT in AD_DATA:
                  AD_ELEMENT[0]    = len
                  AD_ELEMENT[1]    = tag
                  AD_ELEMENT[2..n] = data
    */
    uint16 i;
	/* Local data structure to be initialised */
	bleAdvertisingData_t ad_data;
	ad_data.flags = 0u;
    ad_data.appearance = 0u;
    ad_data.service = 0u;
    
	for (i=0; i<ind->size_advertising_data; i++)
    {
        /* Get the length of current AD_ELEMENT */
        uint16 len = ind->advertising_data[i];
        
        /* Which AD_TYPE is the current AD_ELEMENT? */
        switch(ind->advertising_data[i+1])
        {
            case ble_ad_type_flags:
            {
                ad_data.flags = ind->advertising_data[i+2];
                BLE_AD_DEBUG(("AD DATA : FLAGS=0x%02x [", ad_data.flags));
                
                /* What mode is this device running? */
                if (ad_data.flags & BLE_FLAGS_LIMITED_DISCOVERABLE_MODE)
                {
                    BLE_AD_DEBUG((" .LIMITED_DISCOVERABLE."));
                }
                if (ad_data.flags & BLE_FLAGS_GENERAL_DISCOVERABLE_MODE)
                {
                    BLE_AD_DEBUG((" .GENERAL_DISCOVERABLE."));
                }
                if (ad_data.flags & BLE_FLAGS_SINGLE_MODE)
                {
                    BLE_AD_DEBUG((" .SINGLE_MODE."));
                }
                if (ad_data.flags & BLE_FLAGS_DUAL_CONTROLLER)
                {
                    BLE_AD_DEBUG((" .DUAL_CONTROLLER."));
                }
                if (ad_data.flags & BLE_FLAGS_DUAL_HOST)
                {
                    BLE_AD_DEBUG((" .DUAL_HOST."));
                }
                BLE_AD_DEBUG((" ]\n"));
            }
            break;
            case ble_ad_type_complete_local_name:
            case ble_ad_type_shortened_local_name:
            {
                uint16 j;
                BLE_AD_DEBUG(("AD DATA : NAME="));
                for(j=0; j<(len-1); j++)
                {
                    BLE_AD_DEBUG(("%c", ind->advertising_data[i+2+j]));
                }
                BLE_AD_DEBUG((" \n"));
            }
            break;
            case ble_ad_type_complete_uuid16:
            {
                /* What services are supported by this device? */
                uint16 j;
                BLE_AD_DEBUG(("AD DATA : 16-bit UUIDs="));
                for(j=0; j<(len-1); j+=2)
                {
					uint16 tempService = ( (ind->advertising_data[i+j+3] << 8) | (ind->advertising_data[i+j+2] & 0xFF) );
                    
                    BLE_AD_DEBUG(("0x%04x ", tempService ));
					
					if( tempService != GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE)
					{
						BLE_AD_DEBUG(("Service Not Recognized as GATT HID, go to the next index in the advertisement parser loop"));
						continue;
					}
                    else
					{
						BLE_AD_DEBUG(("GATT HID Service Found, exiting advertisement parser loop"));
                        ad_data.service = tempService;
						break;
					}
                }
                BLE_AD_DEBUG((" \n"));
                
            }
            break;
            case ble_ad_type_appearance:
            {
                ad_data.appearance = (ind->advertising_data[i+3] << 8) | (ind->advertising_data[i+2] & 0xFF);
                BLE_AD_DEBUG(("AD DATA : Appearance=[%d]\n", ad_data.appearance));
            }
            break;
            /* PARSE any other AD_TYPEs that may be of interest */
            default:
            {
                BLE_AD_DEBUG(("AD DATA : AD_TYPE[%x] Ignored\n", ind->advertising_data[i+1]));
            }
        }
        /* Move counter to the last octet in current AD_ELEMENT */
        i+=len;
    }
    
    if (ad_data.flags == 0)
    {
        BLE_AD_DEBUG(("AD DATA: Flags empty\n"));
        return;
    }
    else
    {
        /* Has a service been supplied? */
        if (ad_data.service != 0)
        {
            switch (ad_data.service)
            {
                case GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE:
                {
                    /* For now, assume device supports the HID Over GATT profile; allow HOGP task to handle the advertisement */
                    BLE_AD_DEBUG(("AD DATA : Service HOGP\n"));
                    hogpHandleRemoteAdvertisingReportInd(ind);
                    return;
                }
                break;
                /* Handle future supported services here */
                default:
                {
                    BLE_AD_DEBUG(("AD DATA : Don't understand service uuid[%x]\n", ad_data.service));
                }
            }
        }
        
        /* Has appearance been supplied? */
        if (ad_data.appearance !=0)
        {
            switch(ad_data.appearance)
            {
                case gap_appearance_generic_remote_control:
                {
                    /* For now, assume device supports the HID Over GATT profile; allow HOGP task to handle the advertisement */
                    BLE_AD_DEBUG(("AD DATA : Appearance HOGP\n"));
                    hogpHandleRemoteAdvertisingReportInd(ind);
                    return;
                }
                break;
                /* Handle future supported appearances here */
                default:
                {
                    BLE_AD_DEBUG(("AD DATA : Don't understand appearance[%x]\n", ad_data.appearance));
                }
            }
        }
    }
}


/******************************************************************************/
void handle_ble_advertising_report(CL_DM_BLE_ADVERTISING_REPORT_IND_T * ind)
{
    switch(ind->event_type)
    {
        /* If connectable or discoverable, decide whether or not to connect the device */
        case ble_adv_event_discoverable:
        case ble_adv_event_connectable_undirected:
        {
            handle_ble_connectable_discoverable_adverts(ind);
        }
        case ble_adv_event_connectable_directed:
        {
            /* If the advertisement is from a paired device, request to connect it, otherwise ignore as pairing mode is not enabled */
            ConnectionSmGetAuthDevice(&theSink.rundata->bleInputMonitor.task, &ind->permanent_taddr.addr);            
        }
        break;
        case ble_adv_event_non_connectable:
        case ble_adv_event_scan_response:
        case ble_adv_event_unknown:
        {
            BLE_AD_DEBUG(("ble_adv_event_unknown\n"));
        }
        break;
    }
}



#else /* defined(GATT_SERVER_ENABLED) && defined(BLE_ENABLED) */

#include <csrtypes.h>
static const uint16 ble_advertising_dummy=0;

#endif /* defined(GATT_SERVER_ENABLED) && defined(BLE_ENABLED) */
