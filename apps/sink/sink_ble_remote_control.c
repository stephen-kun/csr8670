/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2013-2014

FILE NAME
    sink_ble_remote_control.c

DESCRIPTION
    Interface with BLE HID Remote controller(s)
*/

#if defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED)

/* Application includes */
#include "sink_ble_remote_control.h"
#include "sink_private.h"
#include "sink_gap_ad_types.h"
#include "sink_debug.h"
#include "sink_utils.h"
#include "sink_ble_scanning.h"

/* Library includes */
#include <gatt.h>
#include <connection.h>

/* Firmware includes */
#include <string.h>
#include <stdlib.h>


/* Macro for BLE HID RC Debug */
#ifdef DEBUG_BLE_RC
#define BLE_RC_DEBUG(x) DEBUG(x)
#else
#define BLE_RC_DEBUG(x)
#endif

/* Define to enable ALL debug for BLE (without this enabled, only important debug is printed) */
#define DEBUG_BLE_RC_ALLx


/*******************************************************************************
NAME
    getDevice

DESCRIPTION
    Helper function to get the device from the CID
*/
static remoteController_t * getDevice(uint16 cid)
{
    uint16 i;
    
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if (theSink.rundata->bleInputMonitor.remotes[i].cid == cid)
        {
            return &theSink.rundata->bleInputMonitor.remotes[i];
        }
    }
    
    /* If function gets here, there is no device with the requested *cid* */
    return NULL;
}


/*******************************************************************************
NAME
    bdaddrToCid

DESCRIPTION
    Helper function to convert BDADDR to CID for a known device
*/
static uint16 bdaddrToCid(bdaddr addr)
{
    uint16 i;
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if ( BdaddrIsSame(&addr, &theSink.rundata->bleInputMonitor.remotes[i].taddr.addr) )
        {
            return theSink.rundata->bleInputMonitor.remotes[i].cid;
        }
    }
    /* Device not found */
    return 0xFFFF;
}


/*******************************************************************************
NAME
    deleteBleDevice

DESCRIPTION
    Helper function to remove a BLE device from the known devices list
*/
static void deleteBleDevice(uint16 cid)
{
    /* Find the device in the list and remove it */
    uint16 i;
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if (theSink.rundata->bleInputMonitor.remotes[i].cid == cid)
        {
            /* Update the state for the remote controller */
            memset( &theSink.rundata->bleInputMonitor.remotes[i], 0, sizeof(remoteController_t) );
            theSink.rundata->bleInputMonitor.active_remotes--;
            
            /* If scanning is allowed, start scanning so other remotes can be connected */
            if (!theSink.rundata->bleInputMonitor.ad_scan_disabled)
            {
                start_ble_scanning();
                break;
            }
        }
    }
    
    /* Indicate when all remote controllers have been disconnected */
    if (theSink.rundata->bleInputMonitor.active_remotes == 0)
    {
        MessageSend(&theSink.task, EventSysBleRemoteAllDisconnected, 0);
    }
}


/*************************************************************************
NAME
    setBleSpeedParameters

DESCRIPTION
    Request connection parameters to enable quick setup or to save energy
*/
static void setBleSpeedParameters(bool quick)
{
    ble_connection_params params;

    BLE_RC_DEBUG(("BLE : setBleSpeedParameters %u\n", quick));

    params.scan_interval = 320;
    params.scan_window = 8;
    params.supervision_timeout = 400;
    params.conn_attempt_timeout = 50;
    params.adv_interval_min = 32;
    params.adv_interval_max = 16384;
    params.conn_latency_max = 64;
    params.supervision_timeout_min = 400;
    params.supervision_timeout_max = 400;
    params.own_address_type = TYPED_BDADDR_PUBLIC;

    if (quick)
    {
        /* Connection interval in the range 30 to 50ms */
        params.conn_interval_min = 24;
        params.conn_interval_max = 40;
        params.conn_latency = 0;
    }
    else
    {
        /* Connection interval in the range 90 to 110ms */
        params.conn_interval_min = 72;
        params.conn_interval_max = 88;
        params.conn_latency = 8;
    }

    ConnectionDmBleSetConnectionParametersReq(&params);  
}

/*************************************************************************
NAME
    updateBleSpeedParameters

DESCRIPTION
    Update existing connection parameters to enable quick setup or to save energy
*/
static void updateBleSpeedParameters(bool quick, typed_bdaddr bd_addr)
{    
    uint16 min_interval;
    uint16 max_interval;
    uint16 latency;
    uint16 timeout = 400;
    uint16 min_ce_length = 0;
    uint16 max_ce_length = 160;
    
    BLE_RC_DEBUG(("BLE : setBleUpdateSpeedParameters %u\n", quick));
        
    if (quick)
    {
        /* Connection interval in the range 30 to 50ms */
        min_interval = 24;
        max_interval = 40;
        latency = 0;       
    }
    else
    {
        /* Connection interval in the range 90 to 110ms */
        min_interval = 72;
        max_interval = 88;
        latency = 8;
    }  
        
        
    ConnectionDmBleConnectionParametersUpdateReq(   &theSink.task,
                                                    &bd_addr,
                                                    min_interval,
                                                    max_interval,
                                                    latency,
                                                    timeout,
                                                    min_ce_length,
                                                    max_ce_length );

}


/*******************************************************************************
NAME
    handleTimedOutDevice

DESCRIPTION
    Helper function to handle when a connection to a remote device times out
*/
static void handleTimedOutDevice(uint16 cid)
{
    /* Which device is this timeout associated? */
    remoteController_t *dev = getDevice(cid);
    
    if (dev)
    {
        /* Is the device stuck in connecting state? */
        if (dev->state == rc_connecting)
        {
            BLE_RC_DEBUG(("BLE : RC [%04x %02x %06lu] failed to connect\n", dev->taddr.addr.nap, dev->taddr.addr.uap, dev->taddr.addr.lap));
            
            /* Error in connection; delete the device from the known devices list */
            deleteBleDevice(cid);
            
            /* Disable fast connection parameters to save power */
            updateBleSpeedParameters(FALSE, dev->taddr);
        }
    }
}


/*******************************************************************************
NAME
    connectBleRemote

DESCRIPTION
    Helper function to make a GATT connection request to a remote controller
*/
static void connectBleRemote(bdaddr bd_addr, uint8 bdaddr_type)
{
    uint16 i;
    
    /* Covert bd_addr to typed bdaddr */
    typed_bdaddr t_bd_addr;
    t_bd_addr.type = bdaddr_type;
    t_bd_addr.addr = bd_addr;
    
    /* Are the maximum number of BLE remotes already connected? */
    if (theSink.rundata->bleInputMonitor.active_remotes >= theSink.rundata->bleInputMonitor.config->max_remotes)
    {
        BLE_RC_DEBUG(("BLE : Cannot connect another BLE remote current[%d] max[%d]\n", theSink.rundata->bleInputMonitor.active_remotes, theSink.rundata->bleInputMonitor.config->max_remotes));
        return;
    }
    
    /* Ensure the requested device is not already connected / connecting */
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if (BdaddrIsSame(&bd_addr, &theSink.rundata->bleInputMonitor.remotes[i].taddr.addr))
        {
            BLE_RC_DEBUG(("BLE : RC [%04x %02x %06lu] already connected/connecting\n", bd_addr.nap, bd_addr.uap, bd_addr.lap));
            return;
        }
    }
    
    /* Connect the BLE remote controller */
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        /* Is the current entry empty? If so, connect the device */
        if (theSink.rundata->bleInputMonitor.remotes[i].state == rc_disconnected)
        {
            BLE_RC_DEBUG(("BLE : Connect RC[%04x %02x %06lu]\n", bd_addr.nap, bd_addr.uap, bd_addr.lap));
            
            /* Update the remote controllers state */
            theSink.rundata->bleInputMonitor.remotes[i].taddr = t_bd_addr;
            theSink.rundata->bleInputMonitor.remotes[i].state = rc_connecting;
            theSink.rundata->bleInputMonitor.active_remotes++;
            
            /* Enable fast connection parameters to speed up the connection process */
            setBleSpeedParameters(TRUE);
            
            /* Send a connection request to the remote controller */
            stop_ble_scanning();
            GattConnectRequest(&theSink.rundata->gatt.task, &t_bd_addr, gatt_connection_ble_master_directed, TRUE);
            
            /* Now wait for the connection to complete so can then discover what services / characteristics are supported by the remote controller */
            return;
        }
    }
}


/*************************************************************************/
static void handleBleRemoteGetAuthDevice( CL_SM_GET_AUTH_DEVICE_CFM_T * m )
{
    /* If the device is paired, make a connection request, otherwise just ignore it */
    if (m->status == success)
    {
        connectBleRemote(m->bd_addr, TYPED_BDADDR_PUBLIC);
    }
    else
    {
#ifdef DEBUG_BLE_RC_ALL
        /* BLE_RC_DEBUG(("BLE : Ignore unpaired RC[%04x %02x %06lu]\n", m->bd_addr.nap, m->bd_addr.uap, m->bd_addr.lap)); */
#endif
    }
}


/*******************************************************************************
NAME    
    hogpHandleGattConnectCfm
    
DESCRIPTION
    Function to handle GATT_CONNECT_CFM messages
*/
void hogpHandleGattConnectCfm( GATT_CONNECT_CFM_T * m )
{
    uint16 i;
    
    BLE_RC_DEBUG(("BLE : GATT_CONNECT_CFM [%x]\n", m->status));
    
    /* Which known remote controller has completed the GATT connection process? */
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if ( (theSink.rundata->bleInputMonitor.remotes[i].state == rc_connecting) && BdaddrTypedIsSame( &theSink.rundata->bleInputMonitor.remotes[i].taddr, &m->taddr ) )
        {
            if (m->status == gatt_status_success) 
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ);
                message->cid = m->cid;
                
                BLE_RC_DEBUG(("\nBLE : RC[%04x %02x %06lu] Connected; assigned cid[%x]\n", m->taddr.addr.nap, m->taddr.addr.uap, m->taddr.addr.lap, m->cid)); 
                
                /* Update the state for the remote controller and store the Connection ID */
                theSink.rundata->bleInputMonitor.remotes[i].state = rc_ready_for_discovery;
                theSink.rundata->bleInputMonitor.remotes[i].cid = m->cid;
                
                /* If running in PTS test mode, wait for user input before starting service discovery, otherwise auto start service discovery on the remote device */
                if (!theSink.rundata->bleInputMonitor.pts_test_mode)
                {
                    MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ, message);
                }
            }
            else if (m->status == gatt_status_initialising)
            {
                /* Can ignore this message; the connection is still being processed; start the timeout to ensure the device doesn't end up half connected */
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_CONNECTION_TIMEOUT_MSG);
                message->cid = m->cid;
                MessageSendLater(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_CONNECTION_TIMEOUT_MSG, message, BLE_HID_RC_CONNECTION_TIMEOUT);
                
                /* Store the GATT assigned CID for the remote controller device */
                theSink.rundata->bleInputMonitor.remotes[i].cid = m->cid;
            }
            else
            {
                /* Connection failed; remove the RC from devices list */
                BLE_RC_DEBUG(("\nBLE : RC[%04x %02x %06lu] Failed to connect [%x]\n", m->taddr.addr.nap, m->taddr.addr.uap, m->taddr.addr.lap, m->status));
                deleteBleDevice(m->cid);
            }
        }
    }
}


/****************************************************************************
NAME
    discoverAllPrimaryServices
    
DESCRIPTION
    Helper function to make a "Discover All Primary Services" request to the 
    remote device with connection ID *cid*
*/
static void discoverAllPrimaryServices(uint16 cid)
{
    /* Get a pointer to the remote controller */
    remoteController_t * dev = getDevice(cid);
    if (dev)
    {
        /* Check device state, if correct, update the state and get the primary services, otherwise ignore */
        if (dev->state == rc_ready_for_discovery)
        {
            BLE_RC_DEBUG(("BLE : Discovering primary services for RC[%x]\n", cid));
            dev->state = rc_service_discovery;
            GattDiscoverAllPrimaryServicesRequest( &theSink.rundata->gatt.task, cid );
        }
        else
        {
            BLE_RC_DEBUG(("BLE : State not valid for discovering primary services\n"));
        }
    }
}


/*****************************************************************************/
void hogpHandleGattDiscoverAllPrimaryServicesCfm( GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM_T * m )
{
    /* Get a pointer to the device data */
    remoteController_t * dev = getDevice(m->cid);
    
    /* If the status indicates a failure, return from the function without processing the message any further*/
    if(m->status != gatt_status_success)
        return;
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
    
    /* Check device is in the right state for this message */
    if (dev->state != rc_service_discovery)
    {
        BLE_RC_DEBUG(("BLE : Service discovery in wrong state[%x] expected[%x]\n", dev->state, rc_service_discovery));
        return;
    }
    
    /* Which service is this response for? (need to ensure RC supports the three mandatory HID Over GATT services) */
    switch (m->uuid_type)
    {
        case gatt_uuid16:
        {
            BLE_RC_DEBUG(("BLE : Primary service: uuid[%x] start[%02x] end[%02x]\n", (uint16)m->uuid[0], m->handle, m->end));
            
            if (m->uuid[0] == GATT_HID_SERVICE_UUID_T)
            {                
                dev->supports_hid = 1;
            }
            else if (m->uuid[0] == GATT_BATTERY_SERVICE_UUID_T)
            {
                dev->supports_battery = 1;
            }
            else if (m->uuid[0] == GATT_DEVICE_INFORMATION_SERVICE_UUID_T)
            {
                dev->supports_dev_info = 1;
            }
            
            /* Add the valid service */
            dev->services = realloc(dev->services, sizeof(gattService_t) * (dev->num_services+1));
            dev->services[dev->num_services].uuid  = m->uuid[0];
            dev->services[dev->num_services].start = m->handle;
            dev->services[dev->num_services].end   = m->end;
            dev->num_services++;
        }
        break;
        case gatt_uuid128:
        {
            /* Not interested in custom services */
            BLE_RC_DEBUG(("BLE : Found UUID128 [%lu] [%lu] [%lu] [%lu]\n", m->uuid[0], m->uuid[1], m->uuid[2], m->uuid[3]));
        }
        break;
        case gatt_uuid_none:
        default:
        {
            BLE_RC_DEBUG(("BLE : Discover all services: Invalid UUID\n"));
        }
    }
    
    /* Have all primary services been discovered for the remote device? */
    if (!m->more_to_come)
    {
        MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_PRIM_SERVICES_DISCOVERED);
        message->cid = m->cid;
        MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_PRIM_SERVICES_DISCOVERED, message);
    }
}


/*******************************************************************************
NAME
    handleAllPrimaryServicesDiscovered

DESCRIPTION
    Helper function to handle when all primary services have been discovered
*/
static void handleAllPrimaryServicesDiscovered( uint16 cid )
{
    /* Get a pointer to the device data */
    remoteController_t * dev = getDevice(cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        /* Update the state for the device */
        dev->state = rc_ready_for_include;
        
        /* If running in PTS mode, wait for a user event to progress (do not auto progress) */
        if (theSink.rundata->bleInputMonitor.pts_test_mode)
        {
            BLE_RC_DEBUG(("BLE : Found ALL primary services\n\n"));
            return;
        }
        
        /* Ensure the required "HID over GATT" services are supported by the RC; otherwise disconnect the RC (it's out of spec) */
        if ( (dev->num_services > 0) && (dev->supports_dev_info && dev->supports_hid && dev->supports_battery) )
        {
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ, message);
        }
        else
        {
            BLE_RC_DEBUG(("BLE : Disconnect out of spec remote [%x]\n", dev->cid));
            
            /* Also remove the device from the PDL */
            ConnectionSmDeleteAuthDevice(&dev->taddr.addr);
            
            /* Disconnect the remote controller */
            GattDisconnectRequest(dev->cid);
            
            /* Remove knowledge of the device */
            deleteBleDevice(dev->cid);
        }
    }
}


/****************************************************************************
NAME
    discoverIncludedServices
    
DESCRIPTION
    Helper function to make a "Discover All Included Services" request to the 
    remote device with connection ID *cid*
*/
static void discoverIncludedServices( uint16 cid )
{
    /* Get a pointer to the remote controller */
    remoteController_t * dev = getDevice(cid);
    if (dev)
    {
        /* Check device state, if correct, update the state and get the primary services, otherwise ignore */
        if (dev->state == rc_ready_for_include)
        {
            BLE_RC_DEBUG(("BLE : Discovering ALL included services for RC[%x]\n", cid));
            
            /* Update device state ready to discover ALL includes */
            dev->disco_counter = 0;
            dev->state = rc_included_discovery;
            
            /* Find included services for each primary service; start with the first primary service */
            if (dev->num_services > 0)
            {
                GattFindIncludedServicesRequest(&theSink.rundata->gatt.task, dev->cid, dev->services[0].start, dev->services[0].end);
            }
            else
            {
                /* Service discovery hasn't have been done yet (shouldn't ever get here) */
            }
        }
        else
        {
            BLE_RC_DEBUG(("BLE : State not valid for discovering included services\n"));
        }
    }
}


/******************************************************************************/
void hogpHandleGattFindIncludedServicesCfm( GATT_FIND_INCLUDED_SERVICES_CFM_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        /* Don't care about the includes (It's mandatory to discover all includes according to the HOGP spec) */    
        BLE_RC_DEBUG(("BLE : Included : UUID[%04x] start[%02x] end[%02x]\n", (uint16)m->uuid[0], m->handle, m->end));
        
        /* Have all includes been found for the current service? */
        if (!m->more_to_come)
        {
            dev->disco_counter++;
            
            /* Have includes for all services been discovered? */
            if (dev->disco_counter < dev->num_services)
            {
                /* Discover includes for the next service */
                GattFindIncludedServicesRequest(&theSink.rundata->gatt.task, dev->cid, dev->services[dev->disco_counter].start, dev->services[dev->disco_counter].end);
            }
            else
            {
                /* Finished finiding all included services */
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_INCLUDED_SERVICES_DISCOVERED);
                message->cid = m->cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_INCLUDED_SERVICES_DISCOVERED, message);
            }
        }
    }
}


/*******************************************************************************
NAME
    handleIncludedServicesDiscovered

DESCRIPTION
    Helper function to handle when all includes (for all services have been
    discovered)
*/
static void handleIncludedServicesDiscovered( uint16 cid )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        /* Update the state for the device */
        dev->state = rc_ready_for_chars;
        
        /* If PTS Test Mode is enabled, wait for user input before progressing, otherwise auto progress */
        if (!theSink.rundata->bleInputMonitor.pts_test_mode)
        {
            /* Now discover the characteristics for each service */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ, message);
        }
        else
        {
            BLE_RC_DEBUG(("BLE : Found ALL included services\n\n"));
        }
    }
}


/****************************************************************************
NAME
    discoverAllCharacteristics
    
DESCRIPTION
    Function to start characteristic discovery for all discovered services
    supported by the remote device
*/
static void discoverAllCharacteristics( uint16 cid )
{
    /* Get a pointer to the remote controller */
    remoteController_t * dev = getDevice(cid);
    if (dev)
    {
        /* Check device state, if correct, update the state and get the primary services, otherwise ignore */
        if (dev->state == rc_ready_for_chars)
        {
            BLE_RC_DEBUG(("BLE : Discover ALL characteristics for RC[%x]\n", cid));
            
            /* Update device state ready to discover ALL characteristics */
            dev->disco_counter = 0;
            dev->state = rc_char_discovery;
            
            /* Find included services for each primary service; start with the first primary service */
            if (dev->num_services > 0)
            {
                BLE_RC_DEBUG(("BLE : Discover characteristics for service UUID[%x]\n", dev->services[0].uuid));
                GattDiscoverAllCharacteristicsRequest(&theSink.rundata->gatt.task, dev->cid, dev->services[0].start, dev->services[0].end);
            }
            else
            {
                /* Include discovery hasn't have been done yet (shouldn't ever get here) */
            }
        }
        else
        {
            BLE_RC_DEBUG(("BLE : State not valid for discovering characteristics\n"));
        }
    }
}


/******************************************************************************/
void hogpHandleGattDiscoverAllCharacteristicsCfm( GATT_DISCOVER_ALL_CHARACTERISTICS_CFM_T * m)
{
    /* Get a pointer to the device data */
    remoteController_t * dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
    
    /* Check device is in the correct state */
    if (dev->state == rc_char_discovery)
    {
#ifdef DEBUG_BLE_RC_ALL
        BLE_RC_DEBUG(("BLE : cid[%02x] Characteristic: uuid[%04x] handle[%x]", m->cid, (uint16)m->uuid[0], m->handle));
#endif        
        /* Which service is this characteristic associated? */
        if (dev->services[dev->disco_counter].uuid == GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE)
        {
            /* Only interested in 16bit UUIDs */
            if (m->uuid_type == gatt_uuid16)
            {
                switch (m->uuid[0])
                {
                    /* Only interested in spec compliant HID characteristics */
                    case GATT_CHARACTERISTIC_UUID_HID_INFORMATION:
                    case GATT_CHARACTERISTIC_UUID_REPORT_MAP:
                    case GATT_CHARACTERISTIC_UUID_REPORT:
                    case GATT_CHARACTERISTIC_UUID_HID_CONTROL_POINT:
                    case GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_INPUT_REPORT:
                    case GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_OUTPUT_REPORT:
                    case GATT_CHARACTERISTIC_UUID_BOOT_MOUSE_INPUT_REPORT:
                    case GATT_CHARACTERISTIC_UUID_PROTOCOL_MODE:
                    {
                        /* Add the discovered HID characteristic value */
                        dev->characteristics = realloc(dev->characteristics, sizeof(gattChar_t) * (dev->num_characteristics+1));
                        if (dev->characteristics)
                        {
                            dev->characteristics[dev->num_characteristics].uuid         = m->uuid[0];
                            dev->characteristics[dev->num_characteristics].handle       = m->handle;
                            dev->characteristics[dev->num_characteristics].props        = 0;
                            dev->characteristics[dev->num_characteristics].report_id    = 0;
                            dev->characteristics[dev->num_characteristics].report_type  = 0;
                            dev->characteristics[dev->num_characteristics].suspend      = 0;
                            dev->characteristics[dev->num_characteristics].notify       = 0;
                            dev->num_characteristics++;
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG((" [Added]\n"));
#endif
                        }
                        else
                        {
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG((" [Error]\n"));
#endif
                        }
                    }
                    break;
                    default:
                    {
                        /* Ignore non-standard HID Characteristics, not interested in them */
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG((" [Ignored1]\n"));
#endif
                    }
                }
            }
            else
            {
                /* Non 16bit UUID's are ignored */
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Ignored2]\n"));
#endif
            }
        }
        else if (dev->services[dev->disco_counter].uuid == GATT_SERVICE_UUID_BATTERY_SERVICE)
        {
            /* Only interested in 16bit UUIDs */
            if (m->uuid_type == gatt_uuid16)
            {
                switch (m->uuid[0])
                {
                    case GATT_CHARACTERISTIC_UUID_BATTERY_LEVEL:
                    {
                        /* Add the discovered Battery characteristic */
                        dev->characteristics = realloc(dev->characteristics, sizeof(gattChar_t) * (dev->num_characteristics+1));
                        if (dev->characteristics)
                        {
                            dev->characteristics[dev->num_characteristics].uuid    = m->uuid[0];
                            dev->characteristics[dev->num_characteristics].handle  = m->handle;
                            dev->characteristics[dev->num_characteristics].props        = 0;
                            dev->characteristics[dev->num_characteristics].report_type  = 0;
                            dev->characteristics[dev->num_characteristics].suspend      = 0;
                            dev->characteristics[dev->num_characteristics].notify       = 0;
                            dev->num_characteristics++;
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG((" [Added]\n"));
#endif
                        }
                        else
                        {
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG((" [Error]\n"));
#endif
                        }
                    }
                    break;
                    default:
                    {
                        /* Ignore non-standard Battery Characteristics, not interested in them */
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG((" [Ignored1]\n"));
#endif
                    }
                }
            }
            else
            {
                /* Non 16bit UUID's are ignored */
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Ignored2]\n"));
#endif
            }
        }
        else if (dev->services[dev->disco_counter].uuid == GATT_SERVICE_UUID_DEVICE_INFORMATION)
        {
            /* Only interested in 16bit UUIDs */
            if (m->uuid_type == gatt_uuid16)
            {
                switch (m->uuid[0])
                {
                    case GATT_CHARACTERISTIC_UUID_SYSTEM_ID:
                    case GATT_CHARACTERISTIC_UUID_MODEL_NUMBER_STRING:                    
                    case GATT_CHARACTERISTIC_UUID_SERIAL_NUMBER_STRING:
                    case GATT_CHARACTERISTIC_UUID_FIRMWARE_REVISION_STRING:
                    case GATT_CHARACTERISTIC_UUID_HARDWARE_REVISION_STRING:
                    case GATT_CHARACTERISTIC_UUID_SOFTWARE_REVISION_STRING:
                    case GATT_CHARACTERISTIC_UUID_MANUFACTURER_NAME_STRING:
                    case GATT_CHARACTERISTIC_UUID_IEEE_11073:
                    case GATT_CHARACTERISTIC_UUID_PNP_ID:
                    {
                        /* Add the discovered Device Information characteristic value */
                        dev->characteristics = realloc(dev->characteristics, sizeof(gattChar_t) * (dev->num_characteristics+1));
                        if (dev->characteristics)
                        {
                            dev->characteristics[dev->num_characteristics].uuid    = m->uuid[0];
                            dev->characteristics[dev->num_characteristics].handle  = m->handle;
                            dev->characteristics[dev->num_characteristics].props        = 0;
                            dev->characteristics[dev->num_characteristics].report_type  = 0;
                            dev->characteristics[dev->num_characteristics].suspend      = 0;
                            dev->characteristics[dev->num_characteristics].notify       = 0;
                            dev->num_characteristics++;
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG((" [Added]\n"));
#endif
                        }
                        else
                        {
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG((" [Error]\n"));
#endif
                        }
                    }
                    break;
                    default:
                    {
                        /* Ignore non-standard Device Information characteristics, not interested in them */
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG((" [Ignored1]\n"));
#endif
                    }
                }
            }
        }
        else
        {
            /* Characteristics for other services are ignored */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG((" [Ignored3]\n"));
#endif
        }
        
        /* Have all characteristics for the current service been discovered? */
        if (!m->more_to_come)
        {
            dev->disco_counter++;
            
            /* Have characteristics for all services been discovered? */
            if (dev->disco_counter < dev->num_services)
            {
                BLE_RC_DEBUG(("\nBLE : Discover characteristics for service UUID[%x]\n", dev->services[dev->disco_counter].uuid));
                GattDiscoverAllCharacteristicsRequest(&theSink.rundata->gatt.task, dev->cid, dev->services[dev->disco_counter].start, dev->services[dev->disco_counter].end);
            }
            else
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_ALL_CHARACTERISTICS_DISCOVERED);
                message->cid = dev->cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_ALL_CHARACTERISTICS_DISCOVERED, message);
            }
        }
    }
}


/*******************************************************************************
NAME
    handleAllCharacteristicsDiscovered
    
DESCRIPTION
    Function to handle once all the characteristic (values) have been discovered
*/
static void handleAllCharacteristicsDiscovered( uint16 cid )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        /* Update the state for the device */
        dev->state = rc_ready_for_descriptors;
        
        /* If PTS Test Mode is enabled, wait for user input before progressing, otherwise auto progress */
        if (!theSink.rundata->bleInputMonitor.pts_test_mode)
        {
            /* Now discover the descriptors for each characteristic */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ, message);
        }
        else
        {
            BLE_RC_DEBUG(("BLE : Found ALL characteristics\n\n"));
        }
    }
}


/****************************************************************************
NAME
    discoverAllDescriptors
    
DESCRIPTION
    Function to start descriptor discovery for the remote device
*/
static void discoverAllDescriptors( uint16 cid )
{
    /* Get a pointer to the remote controller */
    remoteController_t * dev = getDevice(cid);
    if (dev)
    {
        /* Check device state, if correct, update the state and get the primary services, otherwise ignore */
        if (dev->state == rc_ready_for_descriptors)
        {
            BLE_RC_DEBUG(("BLE : Discover ALL descriptors for RC[%x]\n", cid));
            
            /* Update device state ready for descriptor discovery */
            dev->state = rc_descriptor_discovery;
            dev->disco_counter = 0;
            
            /* Find included services for each primary service; start with the first primary service */
            if (dev->num_services > 0)
            {
                BLE_RC_DEBUG(("BLE : Discover descriptors for service UUID[%x]\n", dev->services[0].uuid));
                GattDiscoverAllCharacteristicDescriptorsRequest(&theSink.rundata->gatt.task, dev->cid, dev->services[0].start, dev->services[0].end);
            }
            else
            {
                /* Characteristic discovery hasn't have been done yet (shouldn't ever get here) */
            }
        }
        else
        {
            BLE_RC_DEBUG(("BLE : State[%x] not valid for discovering descriptors; expected[%x]\n", dev->state, rc_char_discovery));
        }
    }
}


/*******************************************************************************
NAME
    processHidCharacteristicDescriptor

DESCRIPTION
    Helper function to process discovered HID characteristic descriptors
*/
static void processHidCharacteristicDescriptor( remoteController_t *dev, uint16 cid, uint16 uuid, uint16 handle )
{
    /* Only store HID characteristic values, declarations or descriptors */
    switch(uuid)
    {
        /* Characteristic values */
        case GATT_CHARACTERISTIC_UUID_HID_INFORMATION:
        case GATT_CHARACTERISTIC_UUID_REPORT_MAP:
        case GATT_CHARACTERISTIC_UUID_REPORT:
        case GATT_CHARACTERISTIC_UUID_HID_CONTROL_POINT:
        case GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_INPUT_REPORT:
        case GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_OUTPUT_REPORT:
        case GATT_CHARACTERISTIC_UUID_BOOT_MOUSE_INPUT_REPORT:
        case GATT_CHARACTERISTIC_UUID_PROTOCOL_MODE:
        {
            /* Have already discovered the characteristic values for the HID service */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG((" [VALUE]\n"));
#endif
        }
        break;
        /* Characteristic Declarations */
        case GATT_CHARACTERISTIC_DECLARATION_UUID:
        case GATT_INCLUDE_DECLARATION_UUID:
        case GATT_PRIMARY_SERVICE_DECLARATION_UUID:
        case GATT_SECONDARY_SERVICE_DECLARATION_UUID:
        /* Characteristic Descriptors */
        case GATT_CHARACTERISTIC_EXTENDED_PROPERTIES_UUID:
        case GATT_CHARACTERISTIC_USER_DESCRIPTION_UUID:
        case GATT_CLIENT_CHARACTERISTIC_CONFIGURATION_UUID:
        case GATT_CHARACTERISTIC_PRESENTATION_FORMAT_UUID:
        case GATT_CHARACTERISTIC_AGGREGATE_FORMAT_UUID:
        case GATT_VALID_RANGE_UUID:
        case GATT_EXTERNAL_REPORT_REFERENCE_UUID:
        case GATT_REPORT_REFERENCE_UUID:
        {
            /* Add the discovered HID declaration / descriptor */
            dev->descriptors = realloc(dev->descriptors, sizeof(gattChar_t) * (dev->num_descriptors+1));
            if (dev->descriptors)
            {
                dev->descriptors[dev->num_descriptors].handle = handle;
                dev->descriptors[dev->num_descriptors].uuid   = uuid;
                dev->num_descriptors++;
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Added]\n"));
#endif
            }
            else
            {
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Error]\n"));
#endif
            }
        }
        break;
        default:
        {
            /* Non mandatory HID characteristic can be ignored */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG((" [Ignored1]\n"));
#endif
        }
    }
}


/*******************************************************************************
NAME
    processBatteryCharacteristicDescriptor

DESCRIPTION
    Helper function to process discovered Battery characteristic descriptors
*/
static void processBatteryCharacteristicDescriptor( remoteController_t *dev, uint16 cid, uint16 uuid, uint16 handle )
{
    /* Only store Battery characteristic values, declarations or descriptors */
    switch(uuid)
    {
        /* Characteristic Values */
        case GATT_CHARACTERISTIC_UUID_BATTERY_LEVEL:
        {
            /* Characteristic values have already been discovered */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG((" [Value]\n"));
#endif
        }
        break;
        /* Characteristic Declarations */
        case GATT_CHARACTERISTIC_DECLARATION_UUID:
        case GATT_INCLUDE_DECLARATION_UUID:
        case GATT_PRIMARY_SERVICE_DECLARATION_UUID:
        case GATT_SECONDARY_SERVICE_DECLARATION_UUID:
        /* Characteristic Descriptors */
        case GATT_CHARACTERISTIC_EXTENDED_PROPERTIES_UUID:
        case GATT_CHARACTERISTIC_USER_DESCRIPTION_UUID:
        case GATT_CLIENT_CHARACTERISTIC_CONFIGURATION_UUID:
        case GATT_CHARACTERISTIC_PRESENTATION_FORMAT_UUID:
        case GATT_CHARACTERISTIC_AGGREGATE_FORMAT_UUID:
        case GATT_VALID_RANGE_UUID:
        case GATT_EXTERNAL_REPORT_REFERENCE_UUID:
        case GATT_REPORT_REFERENCE_UUID:
        {
            /* Add the discovered Battery characteristic descriptor */
            dev->descriptors = realloc(dev->descriptors, sizeof(gattChar_t) * (dev->num_descriptors+1));
            if (dev->descriptors)
            {
                dev->descriptors[dev->num_descriptors].handle = handle;
                dev->descriptors[dev->num_descriptors].uuid   = uuid;
                dev->num_descriptors++;
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Added]\n"));
#endif
            }
            else
            {
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Error]\n"));
#endif
            }
        }
        break;
        default:
        {
            /* Non mandatory Battery descriptor can be ignored */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG((" [Ignored1]\n"));
#endif
        }
    }
}


/******************************************************************************/
void hogpHandleGattDiscoverAllCharacteristicDescriptorsCfm( GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
    
    /* Check device is in the correct state */
    if (dev->state == rc_descriptor_discovery)
    {
#ifdef DEBUG_BLE_RC_ALL
        BLE_RC_DEBUG(("BLE : cid[%x] Descriptor: uuid[%04x] handle[%x]", dev->cid, (uint16)m->uuid[0], m->handle));
#endif
        
        /* Which service is this characteristic associated? */
        if (dev->services[dev->disco_counter].uuid == GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE)
        {
            /* Only interested in 16bit UUIDs */
            if (m->uuid_type == gatt_uuid16)
            {
                processHidCharacteristicDescriptor(dev, m->cid, (uint16)m->uuid[0], m->handle);
            }
            else
            {
                /* Ignore non 16bit Descriptors */
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Ignored2]\n"));
#endif
            }
            
        }
        else if (dev->services[dev->disco_counter].uuid == GATT_SERVICE_UUID_BATTERY_SERVICE)
        {
            /* Only interested in 16bit UUIDs */
            if (m->uuid_type == gatt_uuid16)
            {
                processBatteryCharacteristicDescriptor(dev, m->cid, (uint16)m->uuid[0], m->handle);
            }
            else
            {
                /* Ignore non 16bit Descriptors */
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG((" [Ignored2]\n"));
#endif
            }
        }
        else
        {
            /* Ignore descriptors from other services (not interested) */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG((" [Ignored3]\n"));
#endif
        }
    }
    
    /* Have all descriptors for the current service been discovered? */
    if (!m->more_to_come)
    {
        dev->disco_counter++;
        
        /* Have descriptors for all services been discovered? */
        if (dev->disco_counter < dev->num_services)
        {
            BLE_RC_DEBUG(("\nBLE : Discover descriptors for service UUID[%x]\n", dev->services[dev->disco_counter].uuid));
            GattDiscoverAllCharacteristicDescriptorsRequest(&theSink.rundata->gatt.task, dev->cid, dev->services[dev->disco_counter].start, dev->services[dev->disco_counter].end);
        }
        else
        {
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_ALL_DESCRIPTORS_DISCOVERED);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_ALL_DESCRIPTORS_DISCOVERED, message);
            
            /* Reset counter for its next use */
            dev->disco_counter = 0;
        }
    }
}


/*******************************************************************************
NAME
    handleAllDescriptorsDiscovered
    
DESCRIPTION
    Function to handle once all the characteristic descriptors have been 
    discovered
*/
static void handleAllDescriptorsDiscovered(uint16 cid)
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        /* Update the device state */
        dev->state = rc_ready_for_processing;
        
        /* If PTS Test Mode is enabled, wait for user input before progressing, otherwise auto progress */
        if (!theSink.rundata->bleInputMonitor.pts_test_mode)
        {
            /* Now that everything has been discovered, start processing the data */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_PROCESS_ALL_SERVICES_REQ);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_PROCESS_ALL_SERVICES_REQ, message);
        }
        else
        {
            BLE_RC_DEBUG(("BLE : Found ALL descriptors\n\n"));
        }
    }
}


/*******************************************************************************
NAME
    sendServiceProcessedEvent

DESCRIPTION
    Helper function to create and send the event to indicate that the 
    current service has been fully processed. For a service to be fully
    processed, the following tasks must have completed:
     - All its characteristics have been read
     - All its descriptors have been read
     - All its notifications have been enabled
*/
static void sendServiceProcessedEvent( remoteController_t * dev , bleHidRcSupportedServices_t service_type )
{
    MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_SERVICE_PROCESSED);
    message->cid          = dev->cid;
    message->service_type = service_type;
    
    /* Get ready to process the next service (if there is another service) */
    dev->service_search_index++;
    dev->reading_type = reading_none;
    dev->processing_index = 0;
    
    /* Avoid recursive function calling by sending a message to the BLE task */
    MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_SERVICE_PROCESSED, message);
}


/*******************************************************************************
NAME
    writeDataToCharacteristic

DESCRIPTION
    Helper function to write data to a characteristic, this function will
    decide which GATT write method to use depending on the data requested
    to be written and the properties for the characteristic the data should
    be written to.

RETURNS
    TRUE  : If write [W] was used to write data
    FALSE : If write without response [WWR] was used to write data
*/
static bool writeDataToCharacteristic( remoteController_t * dev, uint16 handle, uint16 size_data, uint8 * data )
{
    /* Write PTS test data to the feature report */
    if (dev)
    {
        /* Which write method gets priority? */
        if (theSink.rundata->bleInputMonitor.pts_write_with_response)
        {
            /* Write with response mode has priority (if supported) */
            if (dev->characteristics[dev->processing_index].props & gatt_char_prop_write)
            {
#ifdef DEBUG_BLE_RC_ALL
                uint16 i; BLE_RC_DEBUG(("BLE : Write [W] data[")); for (i=0;i<size_data;i++) { BLE_RC_DEBUG((" %02x ",data[i])); } BLE_RC_DEBUG(("]\n"));
#endif
                GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, handle, size_data, data);
                return TRUE;
            }
            /* Write with response is not supported for the requested characteristic, try write without response */
            else if (dev->characteristics[dev->processing_index].props & gatt_char_prop_write_no_response)
            {
#ifdef DEBUG_BLE_RC_ALL
                uint16 i; BLE_RC_DEBUG(("BLE : Write [WWR] data[")); for (i=0;i<size_data;i++) { BLE_RC_DEBUG((" %02x ",data[i])); } BLE_RC_DEBUG(("]\n"));
#endif
                GattWriteWithoutResponseRequest(&theSink.rundata->gatt.task, dev->cid, dev->characteristics[dev->processing_index].handle, size_data, data);
                return FALSE;
            }
        }
        else
        {
            /* Write without response mode has priority (if supported) */
            if (dev->characteristics[dev->processing_index].props & gatt_char_prop_write_no_response)
            {
#ifdef DEBUG_BLE_RC_ALL
                uint16 i; BLE_RC_DEBUG(("BLE : Write [WWR] data[")); for (i=0;i<size_data;i++) { BLE_RC_DEBUG((" %02x ",data[i])); } BLE_RC_DEBUG(("]\n"));
#endif
                GattWriteWithoutResponseRequest(&theSink.rundata->gatt.task, dev->cid, dev->characteristics[dev->processing_index].handle, size_data, data);
                return FALSE;
            }
            /* Write without response is not supported for the requested characteristic, try write with response */
            else if (dev->characteristics[dev->processing_index].props & gatt_char_prop_write)
            {
#ifdef DEBUG_BLE_RC_ALL
                uint16 i; BLE_RC_DEBUG(("BLE : Write [W] data[")); for (i=0;i<size_data;i++) { BLE_RC_DEBUG((" %02x ",data[i])); } BLE_RC_DEBUG(("]\n"));
#endif
                GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, handle, size_data, data);
                return TRUE;
            }
        }
    }
    
    /* If got here, no data was written so return false */
    return FALSE;
}


/*******************************************************************************
NAME
    writePtsCharacteristics

DESCRIPTION
    Helper function to write test data to characteristics

NOTE
    Before this function is called, the following variables must be setup
    according to the service that needs processing:
    
    dev->processing_start : The start handle for the service that needs
                            descriptors to be read
    dev->processing_end   : The end handle for the service that needs
                            descriptors to be read
*/
static void writePtsCharacteristicsForService( remoteController_t * dev , bleHidRcSupportedServices_t service_type )
{
    if (dev)
    {
        /* Search the discovered characteristics (for the current service), until one of interest is found */
        for ( ; dev->processing_index < dev->num_characteristics ; )
        {
            /* Is the current characteristic defined within the current service? */
            if ( (dev->characteristics[dev->processing_index].handle >= dev->processing_start) && 
                 (dev->characteristics[dev->processing_index].handle <= dev->processing_end) )
            {
                if (dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_REPORT)
                {
                    /* Is the report an INPUT, OUTPUT or FEATURE report? */
                    switch(dev->characteristics[dev->processing_index].report_type)
                    {
                        case type_input_report:
                        {
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG(("BLE : Write Input handle[%x]\n", dev->characteristics[dev->processing_index].handle));
#endif
                            /* Get ready to process the next characteristic */
                            dev->writing_pts_data = 1;
                            if (writeDataToCharacteristic(dev, dev->characteristics[dev->processing_index].handle, sizeof(pts_tspx_input_report_data), (uint8*)pts_tspx_input_report_data ))
                            {
                                /* Write [W] was used; wait for the write CFM before continuing */
                                dev->processing_index++;
                                return;
                            }
                            dev->processing_index++;
                        }
                        break;
                        case type_output_report:
                        {
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG(("BLE : Write Output REPORT handle[%x]\n", dev->characteristics[dev->processing_index].handle));
#endif
                            /* Get ready to process the next characteristic */
                            dev->writing_pts_data = 1;
                            if (writeDataToCharacteristic(dev, dev->characteristics[dev->processing_index].handle, sizeof(pts_tspx_output_report_data), (uint8*)pts_tspx_output_report_data ))
                            {
                                /* Write [W] was used; wait for the write CFM before continuing */
                                dev->processing_index++;
                                return;
                            }
                            dev->processing_index++;
                        }
                        break;
                        case type_feature_report:
                        {
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG(("BLE : Write Feature REPORT handle[%x]\n", dev->characteristics[dev->processing_index].handle));
#endif
                            /* Get ready to process the next characteristic */
                            dev->writing_pts_data = 1;
                            if (writeDataToCharacteristic(dev, dev->characteristics[dev->processing_index].handle, sizeof(pts_tspx_feature_report_data), (uint8*)pts_tspx_feature_report_data ))
                            {
                                /* Write [W] was used; wait for the write CFM before continuing */
                                dev->processing_index++;
                                return;
                            }
                            dev->processing_index++;
                        }
                        break;
                        case type_report_none:
                        default:
                        {
                        }
                    }
                }
                else if (dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_PROTOCOL_MODE)
                {
                    /* Ensure the protocol mode characteristic can be written to */
                    if (dev->characteristics[dev->processing_index].props & gatt_char_prop_write_no_response)
                    {
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG(("BLE : Write Protocol Mode handle[%x]\n",dev->characteristics[dev->processing_index].handle));
#endif
                        /* Get ready to process the next characteristic */
                        dev->writing_pts_data = 1;
                        if (writeDataToCharacteristic(dev, dev->characteristics[dev->processing_index].handle, sizeof(pts_set_protocol_mode_data), (uint8*)pts_set_protocol_mode_data ))
                        {
                            /* Wait for the write CFM before continuing */
                            dev->processing_index++;
                            return;
                        }
                        dev->processing_index++;
                    }
                }
            }
            /* Current characteristic either not of interest or it is not defined within the current service */
            dev->processing_index++;
        }
        /* All notifications for the current service have been enabled */
        sendServiceProcessedEvent(dev, service_type);
    }
}


/*******************************************************************************
NAME
    readCharacteristicsForService

DESCRIPTION
    Helper function to read the values of all characteristics for a service

NOTE
    Before this function is called, the following variables must be setup
    according to the service that needs processing:
    
    dev->processing_start : The start handle for the service that needs
                            characteristics to be read
    dev->processing_end   : The end handle for the service that needs
                            characteristics to be read
*/
static void readCharacteristicsForService( remoteController_t * dev , bleHidRcSupportedServices_t service_type )
{
    if (dev)
    {
        /* Ensure device is in the correct state to read characteristic values */
        if ( (dev->state == rc_processing_hid) || 
             (dev->state == rc_processing_battery) || 
             (dev->state == rc_processing_dinfo) )
        {
            /* Search the discovered characteristics to find each of the characteristics (for the current service) */
            for ( ; dev->processing_index < dev->num_characteristics ; )
            {
                /* Is the current characteristic defined within current service? */
                if ((dev->characteristics[dev->processing_index].handle >= dev->processing_start) && (dev->characteristics[dev->processing_index].handle <= dev->processing_end))
                {
                    dev->reading_handle = dev->characteristics[dev->processing_index].handle;
                    
                    /* Is current characteristic a "Report Map"? If so, read the characteristic to be able to setup notifications */
                    if (dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_REPORT_MAP)
                    {
                        dev->reading_type = reading_report_map;
                        GattReadLongCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->reading_handle);
                    }
                    else
                    {
                        dev->reading_type = reading_all_characteristics;
                        GattReadCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->reading_handle);
                    }
                    
                    /* Get ready to read the next characteristic (if one exists) */
                    dev->processing_index++;
                    
                    /* Wait for the read response before continuing */
                    return;
                }
                /* Either the descriptor is not a declaration OR it's not defined within the current service; Check the next characteristic */
                dev->processing_index++;
            }
            
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG(("\n"));
#endif
            /* For PTS qualification, need to write PTS test data to HID service characteristics (as defined by the PIXT values) to each of the report characteristics */
            if ((theSink.rundata->bleInputMonitor.pts_test_mode) && (service_type == service_hid))
            {
                BLE_RC_DEBUG(("BLE : Write PTS test data for HID service\n"));
                dev->processing_index = 0;
                writePtsCharacteristicsForService(dev, service_type);
            }
            else
            {
                /* All characteristics & descriptors the current service have been enabled */
                sendServiceProcessedEvent(dev, service_type);
            }
        }
    }
}


/*******************************************************************************
NAME
    readAllDescriptorssForService

DESCRIPTION
    Helper function to read the values of all descriptors for a single service

NOTE
    Before this function is called, the following variables must be setup
    according to the service that needs processing:
    
    dev->processing_start : The start handle for the service that needs
                            descriptors to be read
    dev->processing_end   : The end handle for the service that needs
                            descriptors to be read
*/
static void readDescriptorsForService( remoteController_t * dev , bleHidRcSupportedServices_t service_type )
{
    if (dev)
    {
        /* Ensure device is in the correct state to read characteristic values */
        if ( (dev->state == rc_processing_hid) || 
               (dev->state == rc_processing_battery) || 
               (dev->state == rc_processing_dinfo) )
        {
            /* Search the discovered descriptors to find each of the descriptors (for the current service) */
            for ( ; dev->processing_index < dev->num_descriptors ; )
            {
                /* Is the current descriptor defined within current service? */
                if ((dev->descriptors[dev->processing_index].handle >= dev->processing_start) && (dev->descriptors[dev->processing_index].handle <= dev->processing_end))
                {
                    /* Is the current descriptor a "characteristic declaration"? If so, read the properties from the declaration and store */
                    if (dev->descriptors[dev->processing_index].uuid == GATT_CHARACTERISTIC_DECLARATION_UUID)
                    {
                        dev->reading_type = reading_char_declaration;
                    }
                    /* Is current descriptor a "report reference"? If so, read the descriptor to find out whether the associated REPORT characteristic is an input, output or a feature report */
                    else if (dev->descriptors[dev->processing_index].uuid == GATT_REPORT_REFERENCE_UUID)
                    {
                        dev->reading_type = reading_report_reference;
                    }
                    else
                    {
                        /* Just read the descriptor (don't actually care about the value; PTS will fail if all descriptors are not read) */
                        dev->reading_type = reading_all_descriptors;
                    }
                    dev->reading_handle = dev->descriptors[dev->processing_index].handle;
                    GattReadCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->reading_handle);
                    
                    /* Increment the counter ready for the next characteristic */
                    dev->processing_index++;
                    
                    /* Wait for the read response before reading the next characteristic (if one exists) */
                    return;
                }
                /* Current descriptor is not defined within the current service, check next descriptor */
                dev->processing_index++;
            }
            
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG(("\n"));
#endif
            BLE_RC_DEBUG(("BLE : Read ALL characteristics for service uuid[%x] start[%x] end[%x]\n", dev->services[dev->service_search_index].uuid, dev->processing_start, dev->processing_end));
            dev->reading_type = reading_all_characteristics;
            dev->processing_index = 0;
            readCharacteristicsForService(dev, service_type);
            return;
        }
    }
}


/*******************************************************************************
NAME
    processAllServicesOfType

DESCRIPTION
    Helper function to search through the services list and process each
    service of type *service_type* that exists on the remote device.
*/
static void processAllServicesOfType( remoteController_t * dev , bleHidRcSupportedServices_t service_type )
{
    if (dev)
    {
        /* Check the device is in the correct state before processing the service(s) */
        if ((dev->state == rc_processing_hid) || 
            (dev->state == rc_processing_battery) || 
            (dev->state == rc_processing_dinfo))
        {
            /* Get the UUID for the service type so it can be matched against all discovered services on the device */
            gatt_uuid_t service_type_uuid = 0;
            switch(service_type)
            {
                case service_hid:
                {
                    service_type_uuid = GATT_HID_SERVICE_UUID_T;
                }
                break;
                case service_battery:
                {
                    service_type_uuid = GATT_BATTERY_SERVICE_UUID_T;
                }
                break;
                case service_dev_info:
                {
                    service_type_uuid = GATT_DEVICE_INFORMATION_SERVICE_UUID_T;
                }
                break;
                default:
                {
                    BLE_RC_DEBUG(("BLE : Service type [%x] not supported\n", service_type));
                    return;
                }
            }
            
            /* Search the discovered services list until a *service_type* service is found */
            for ( ; dev->service_search_index < dev->num_services ; )
            {
                if (dev->services[dev->service_search_index].uuid == service_type_uuid)
                {
                    /* Found a service of *service_type*. Process ALL descriptors for the current service */
                    dev->processing_start = dev->services[dev->service_search_index].start;
                    dev->processing_end   = dev->services[dev->service_search_index].end;
                    dev->processing_index = 0;
                    
#ifdef DEBUG_BLE_RC_ALL
                    BLE_RC_DEBUG(("\n"));
#endif
                    /* Read all descriptors for the current service */
                    BLE_RC_DEBUG(("BLE : Read ALL descriptors for service uuid[%x] start[%x] end[%x]\n", dev->services[dev->service_search_index].uuid, dev->processing_start, dev->processing_end));
                    dev->reading_type = reading_all_descriptors;
                    dev->processing_index = 0;
                    readDescriptorsForService(dev, service_type);
                    
                    return;
                }
                else
                {
                    /* Try next service, current service does not match *service_type* */
                    dev->service_search_index++;
                }
            }
            if (TRUE)
            {
                /* Finished processing data for all services of *service_type* */
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_PROCESS_ALL_SERVICES_REQ);
                message->cid = dev->cid;
                
                BLE_RC_DEBUG(("BLE : Finished processing service type [%x]\n", service_type));
                
                /* Update state and send message to process characteristics & descriptors for the next service (if there is another service to process) */
                switch(service_type)
                {
                    case service_hid:
                    {
                        dev->state = rc_ready_to_process_bat;
                    }
                    break;
                    case service_battery:
                    {
                        dev->state = rc_ready_to_process_dinfo;
                    }
                    break;
                    case service_dev_info:
                    {
                        dev->state = rc_setup_suspend_mode;
                    }
                    break;
                    case service_invalid:
                    break;
                }
                
                /* Process data for the next service_type (if one exists) */
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_PROCESS_ALL_SERVICES_REQ, message);
            }
        }
    }
}


/*******************************************************************************
NAME
    processAllDiscoveredServices

DESCRIPTION
    Function that will kick off processing for all discovered services on the
    remote controller device. This function will call helper functions to
    process services according to type.
    The processing jobs for each discovered service are:
    1. Read data from all characteristics
    2. Read data from all descriptors:
        a. For characteristic declarations, adds characteristic properties
        b. For report references, notes down report type for the characteristic
    3. For PTS Mode:
        a. For each discvoered input report, write PTS input report data to the
           report characteristic
        b. For each discovered output report, write PTS output report data to 
           the report characteristic
        c. For each discovered feature report, write PTS output report data to
           the report characteristic
        d. For each discovered Protocol Mode characteristic, write protocol mode
           data to the characteristic
    
    Once all services have been processed, the internal message
    BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED is sent to the task ready
*/
static void processAllDiscoveredServices( uint16 cid )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        switch(dev->state)
        {
            case rc_disconnected:
            case rc_connecting:
            case rc_ready_for_discovery:
            case rc_service_discovery:
            case rc_ready_for_include:
            case rc_included_discovery:
            case rc_ready_for_chars:
            case rc_char_discovery:
            case rc_ready_for_descriptors:
            case rc_descriptor_discovery:
            case rc_processing_hid:
            case rc_processing_battery:
            case rc_processing_dinfo:
            case rc_setup_notifications:
            case rc_connected:
            {
                /* Wrong state, ignore request */
                return;
            }
            break;
            case rc_ready_for_processing:
            {
                BLE_RC_DEBUG(("\nBLE : Process HID service(s)"));
                dev->state = rc_processing_hid;
                dev->service_search_index = 0;
                processAllServicesOfType(dev, service_hid);
            }
            break;
            case rc_ready_to_process_bat:
            {
                BLE_RC_DEBUG(("\nBLE : Process Battery service(s)"));
                dev->state = rc_processing_battery;
                dev->service_search_index = 0;
                processAllServicesOfType(dev, service_battery);
            }
            break;
            case rc_ready_to_process_dinfo:
            {
                BLE_RC_DEBUG(("\nBLE : Process Device Information service(s)"));
                dev->state = rc_processing_dinfo;
                dev->service_search_index = 0;
                processAllServicesOfType(dev, service_dev_info);
            }
            break;
            case rc_setup_suspend_mode:
            {
                /* Send message to indicate all services have now been processed */
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED);
                message->cid = dev->cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED, message);
            }
        }
    }
}


/*******************************************************************************
NAME
    handleAllServicesProcessed
    
DESCRIPTION
    Function to handle once all the services have been processed
*/
static void handleAllServicesProcessed( uint16 cid )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        /* Update the device state */
        dev->state = rc_setup_suspend_mode;
        dev->service_search_index = 0;
        
        /* If PTS Test Mode is enabled, wait for user input before progressing, otherwise auto progress */
        if (!theSink.rundata->bleInputMonitor.pts_test_mode)
        {
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_SETUP_SUSPEND_MODE_REQ);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_SETUP_SUSPEND_MODE_REQ, message);
        }
        else
        {
            BLE_RC_DEBUG(("BLE : All services processed\n\n"));
        }
    }
}


/*******************************************************************************
NAME
    findHidControlPointCharacteristic

DESCRIPTION
    Helper function to search through characteristics for a service
    until a HID_CONTROL_POINT characteristic exists.
    If a HID_CONTROL_POINT characteristic is discovered, this function will
    check to see if the characteristic supports HID Suspend Mode.

NOTE
    Before this function is called, the following variables must be setup
    according to the service that needs processing:
    
    dev->processing_start : The start handle for the service that needs
                            characteristics to be read
    dev->processing_end   : The end handle for the service that needs
                            characteristics to be read
*/
static void findHidControlPointCharacteristic( remoteController_t * dev )
{
    if (dev)
    {
        /* Search through all characteristics */
        uint16 i;
        for (i=0 ; i < dev->num_characteristics ; i++)
        {
            /* Only interested in characteristics for the current HID service that are HID control point characteristiscs */
            if ( ((dev->characteristics[i].handle >= dev->processing_start) && (dev->characteristics[i].handle <= dev->processing_end)) &&
                 (dev->characteristics[i].uuid == GATT_CHARACTERISTIC_UUID_HID_CONTROL_POINT) )
            {
                /* If the HID Control Point characteristic supports writing, then suspend mode is supported by the remote controller (only write without response is supported by HID Control Point characteristics) */
                if (dev->characteristics[i].props & gatt_char_prop_write_no_response)
                {
                    BLE_RC_DEBUG(("BLE : HID Control Point[%x] Supports SUSPEND mode\n", dev->characteristics[i].handle));
                    dev->characteristics[i].suspend = 1;
                }
                else
                {
                    BLE_RC_DEBUG(("BLE : HID Control Point[%x] Supports SUSPEND mode\n", dev->characteristics[i].handle));
                    dev->characteristics[i].suspend = 0;
                }
                /* HID Suspend mode support for the current service has been setup */
                return;
            }
        }
    }
}


/*******************************************************************************
NAME
    setupHidSuspendModeSupport

DESCRIPTION
    Helper function to setup suspend mode if the remote controller supports
    suspend mode
*/
static void setupHidSuspendModeSupport( uint16 cid )
{
    remoteController_t * dev = getDevice(cid);
    
    if (dev)
    {
        /* Search the discovered services list until a HID service is found */
        uint16 i;
        BLE_RC_DEBUG(("BLE : Setup Suspend mode for RC[%x]\n", dev->cid));
        for (i=0 ; i < dev->num_services ; i++)
        {
            if (dev->services[i].uuid == GATT_HID_SERVICE_UUID_T)
            {
                dev->processing_start = dev->services[i].start;
                dev->processing_end   = dev->services[i].end;
                dev->processing_index = 0;
                
                BLE_RC_DEBUG(("BLE : Check if HID service (start[%x], end[%x]) supports Suspend\n", dev->processing_start, dev->processing_end));
                findHidControlPointCharacteristic(dev);
            }
        }
        if (TRUE)
        {
            /* Inform task the suspend mode has been setup */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP);
            message->cid = dev->cid;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP, message);
        }
    }
}


/*******************************************************************************
NAME
    handleSuspendModeSetup

DESCRIPTION
    Helper function to handle once suspend mode has been setup for the remote
    controller *cid*
*/
static void handleSuspendModeSetup( uint16 cid )
{
    remoteController_t * dev = getDevice(cid);
    
    /* Update the device state */
    if (dev)
    {
        /* Update the device state */
        dev->state = rc_setup_notifications;
        dev->service_search_index = 0;
        
        /* If PTS Test Mode is enabled, wait for user input before progressing, otherwise auto progress */
        if (!theSink.rundata->bleInputMonitor.pts_test_mode)
        {
            /* Enable notifications */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_SETUP_NOTIFICATIONS_REQ);
            message->cid    = dev->cid;
            message->notify = TRUE;
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_SETUP_NOTIFICATIONS_REQ, message);
            
            /* Disable fast connection parameters to save power */
            updateBleSpeedParameters(FALSE, dev->taddr);
            
            /* Inform main app task that a BLE remote controller has now connected */
            MessageSend(&theSink.task, EventSysBleRemoteConnected, 0);
        }
        else
        {
            BLE_RC_DEBUG(("BLE : Suspend Mode has been setup for RC[%x]\n\n", dev->cid));
        }
    }
}


/*******************************************************************************
NAME
    setupBatteryNotifications

DESCRIPTION
    Helper function to setup Battery notifications for the remote controller.
    This function should be called once for each Battery service that is defined
    by the remote controller.
*/
static void setupBatteryNotifications( remoteController_t * dev, bool turn_on_notifications )
{
    if (dev)
    {
        /* Finished setting up notifications for the current HID service; setup notifications for the next service (if one exists) */
        MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP);
        message->cid    = dev->cid;
        message->notify = turn_on_notifications;        
        MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP, message);
        
        
        
        /* Search through each discovered characteristic */
        while (dev->processing_index < dev->num_characteristics)
        {
            /* Is the current characteristic defined within the current service? */
            if ( (dev->characteristics[dev->processing_index].handle >= dev->processing_start) &&
                 (dev->characteristics[dev->processing_index].handle <= dev->processing_end) )
            {
                /* Is the characteristic a Battery Level characteristic that supports notifications? */
                if ( (dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_BATTERY_LEVEL) && (dev->characteristics[dev->processing_index].props & gatt_char_prop_notify) )
                {
                    /* Find the Client Configuration descriptor that needs to be written to enable notifications for the characteristic */
                    uint16 j;
                    for (j=0; j<dev->num_descriptors; j++)
                    {
                        /* Is the descriptor a Client Configuration descriptor defined for the current service? */
                        if ( (dev->descriptors[j].handle >= dev->processing_start) && 
                             (dev->descriptors[j].handle <= dev->processing_end) && 
                             (dev->descriptors[j].uuid == GATT_CLIENT_CHARACTERISTIC_CONFIGURATION_UUID) )
                        {
                            /* Ensure current client configuration descriptor is defined for the report characteristic to enable notifications for */
                            if (dev->descriptors[j].handle > dev->characteristics[dev->processing_index].handle)
                            {
                                /* Enable or disable notifications? */
                                if (turn_on_notifications)
                                {
#ifdef DEBUG_BLE_RC_ALL
                                    BLE_RC_DEBUG(("BLE : Enable notifications for uuid[%x] handle[%x], Write client config handle[%x]\n", dev->characteristics[dev->processing_index].uuid, dev->characteristics[dev->processing_index].handle, dev->descriptors[j].handle));
#endif
                                    dev->write_bat_notify = 1;
                                    dev->notify_status    = 1;  /* Enabling notifications */
                                    GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->descriptors[j].handle, sizeof(enable_notifications_data), (uint8*)enable_notifications_data );
                                    
                                    /* Wait for the write CFM before checking the next characteristic in current service (if any more exist) */
                                    dev->processing_index++;
                                    return;
                                }
                                else
                                {
#ifdef DEBUG_BLE_RC_ALL
                                    BLE_RC_DEBUG(("BLE : Disable notifications for uuid[%x] handle[%x], Write client config handle[%x]\n", dev->characteristics[dev->processing_index].uuid, dev->characteristics[dev->processing_index].handle, dev->descriptors[j].handle));
#endif
                                    dev->write_bat_notify = 1;
                                    dev->notify_status    = 0;  /* Disabling notifications */
                                    GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->descriptors[j].handle, sizeof(disable_notifications_data), (uint8*)disable_notifications_data );
                                    
                                    /* Wait for the write CFM before checking the next characteristic in current service (if any more exist) */
                                    dev->processing_index++;
                                    return;
                                }
                            }
                        }
                    }
                }
            }
            /* Current characteristic is either not defined within current service or is not a characteristic that supports notifications, check the next characteristic (if any more exist) */
            dev->processing_index++;
        }
    }
}


/*******************************************************************************
NAME
    setupHidNotifications

DESCRIPTION
    Helper function to setup HID notifications for the remote controller.
    This function should be called once for each HID service that is defined
    by the remote controller.
*/
static void setupHidNotifications( remoteController_t * dev, bool turn_on_notifications )
{
    if (dev)
    {
        /* Search through each discovered characteristic */
        while (dev->processing_index < dev->num_characteristics)
        {
            /* Is the current characteristic defined within the current service? */
            if ( (dev->characteristics[dev->processing_index].handle >= dev->processing_start) &&
                 (dev->characteristics[dev->processing_index].handle <= dev->processing_end) )
            {
                /* Is the characteristic a REPORT (defined as type input) or a BOOT_KEYBOARD_INPUT_REPORT or a BOOT_MOUSE_INPUT_REPORT? If so, does it also support notifications?  */
                if ( ( ((dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_REPORT) && (dev->characteristics[dev->processing_index].report_type == type_input_report)) ||
                       (dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_INPUT_REPORT) ||
                       (dev->characteristics[dev->processing_index].uuid == GATT_CHARACTERISTIC_UUID_BOOT_MOUSE_INPUT_REPORT) )
                    && (dev->characteristics[dev->processing_index].props & gatt_char_prop_notify))
                {
                    /* Find the Client Configuration descriptor that needs to be written to enable notifications for the characteristic */
                    uint16 j;
                    for (j=0; j<dev->num_descriptors; j++)
                    {
                        /* Is the descriptor a Client Configuration descriptor defined for the current service? */
                        if ( (dev->descriptors[j].handle >= dev->processing_start) && 
                             (dev->descriptors[j].handle <= dev->processing_end) && 
                             (dev->descriptors[j].uuid == GATT_CLIENT_CHARACTERISTIC_CONFIGURATION_UUID) )
                        {
                            /* Ensure the client configuration descriptor is defined for the current report characteristic */
                            if (dev->descriptors[j].handle > dev->characteristics[dev->processing_index].handle)
                            {
                                /* Enable or disable notifications? */
                                if (turn_on_notifications)
                                {
                                    /* Rather than just enabling/disabling notifications for any report characteristic, only enable notifications from HID Consumer reports */
                                    if (dev->characteristics[dev->processing_index].notify == 1)
                                    {
#ifdef DEBUG_BLE_RC_ALL
                                        BLE_RC_DEBUG(("BLE : 1Enable notifications for uuid[%x] handle[%x], Write client config handle[%x]\n", dev->characteristics[dev->processing_index].uuid, dev->characteristics[dev->processing_index].handle, dev->descriptors[j].handle));
#endif
                                        dev->write_hid_notify = 1;
                                        dev->notify_status    = 1;  /* Enabling notifications */
                                        GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->descriptors[j].handle, sizeof(enable_notifications_data), (uint8*)enable_notifications_data );
                                    }
                                    else
                                    {
#ifdef DEBUG_BLE_RC_ALL
                                        BLE_RC_DEBUG(("BLE : 1Disable notifications for uuid[%x] handle[%x], Write client config handle[%x]\n", dev->characteristics[dev->processing_index].uuid, dev->characteristics[dev->processing_index].handle, dev->descriptors[j].handle));
#endif
                                        dev->write_hid_notify = 1;
                                        dev->notify_status    = 1;  /* Enabling notifications for this service (just not enabling them for this report) */
                                        GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->descriptors[j].handle, sizeof(disable_notifications_data), (uint8*)disable_notifications_data );
                                    }
                                    /* Wait for the write CFM before checking the next characteristic in current service (if any more exist) */
                                    dev->processing_index++;
                                    return;
                                }
                                else
                                {
#ifdef DEBUG_BLE_RC_ALL
                                    BLE_RC_DEBUG(("BLE : 2Disable notifications for uuid[%x] handle[%x], Write client config handle[%x]\n", dev->characteristics[dev->processing_index].uuid, dev->characteristics[dev->processing_index].handle, dev->descriptors[j].handle));
#endif
                                    dev->write_hid_notify = 1;
                                    dev->notify_status    = 0;  /* Disabling notifications */
                                    GattWriteCharacteristicValueRequest(&theSink.rundata->gatt.task, dev->cid, dev->descriptors[j].handle, sizeof(disable_notifications_data), (uint8*)disable_notifications_data );
                                    
                                    /* Wait for the write CFM before checking the next characteristic in current service (if any more exist) */
                                    dev->processing_index++;
                                    return;
                                }
                            }
                        }
                    }
                }
            }
            /* Current characteristic is either not defined within current service or is not a characteristic that supports notifications, check the next characteristic (if any more exist) */
            dev->processing_index++;
        }
        if (TRUE)
        {
            /* Finished setting up notifications for the current HID service; setup notifications for the next service (if one exists) */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP);
            message->cid    = dev->cid;
            message->notify = turn_on_notifications;        
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP, message);
        }
    }
}


/*******************************************************************************
NAME
    setupAllNotifications

DESCRIPTION
    Function to setup all notifications for the remote controller
    
    To turn on (enable) all notifications for the remote controller, set
    parameter "turn_on_notifications" to TRUE. 
    To turn off (disable) all notifications for the remote controller, set
    parameter "turn_on_notifications" to FALSE.
*/
static void setupAllNotifications( uint16 cid , bool turn_on_notifications )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(cid);
    
    if (dev)
    {
        /* Search through each discovered service looking for HID or Battery services and enable notifications for each */
        while (dev->service_search_index < dev->num_services)
        {
            /* Get handles for the current service */
            dev->processing_start = dev->services[dev->service_search_index].start;
            dev->processing_end   = dev->services[dev->service_search_index].end;
            dev->processing_index = 0;
            
            if (dev->services[dev->service_search_index].uuid == GATT_SERVICE_UUID_HUMAN_INTERFACE_DEVICE)
            {
                BLE_RC_DEBUG(("BLE : Setup Notifications [%x] for HID service start[%x] end[%x]\n", turn_on_notifications, dev->services[dev->service_search_index].start, dev->services[dev->service_search_index].end));
                setupHidNotifications(dev, turn_on_notifications);
                
                /* Get ready to process the next service */
                dev->service_search_index++;
                return;
            }
            else if (dev->services[dev->service_search_index].uuid == GATT_SERVICE_UUID_BATTERY_SERVICE)
            {
                BLE_RC_DEBUG(("BLE : Setup Notifications [%x] for Battery service start[%x] end[%x]\n", turn_on_notifications, dev->services[dev->service_search_index].start, dev->services[dev->service_search_index].end));
                setupBatteryNotifications(dev, turn_on_notifications);
                
                /* Get ready to process the next service */
                dev->service_search_index++;
                return;
            }
            else
            {
                BLE_RC_DEBUG(("BLE : Service[%x] start[%x] end[%x] does not support notifications\n", dev->services[dev->service_search_index].uuid, dev->services[dev->service_search_index].start, dev->services[dev->service_search_index].end ));
                /* Current service is neither HID nor Battery, so check the next service (if one exists) */
                dev->service_search_index++;
            }
        }
        if (TRUE)
        {
            /* Finished setting up notifications for ALL services */
            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_EVENT_ALL_NOTIFICATIONS_SETUP);
            message->cid    = dev->cid;       
            MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_EVENT_ALL_NOTIFICATIONS_SETUP, message);
        }
    }
}


/*******************************************************************************
NAME
    handleAllNotificationsSetup

DESCRIPTION
    Function to handle when all notifications have been setup (either enabled
    or disabled - depending on the request made).
*/
static void handleAllNotificationsSetup( uint16 cid )
{
    remoteController_t * dev = getDevice(cid);
    
    /* Update the device state */
    if (dev)
    {
        BLE_RC_DEBUG(("BLE : All Notifications setup for RC[%x]\n", dev->cid));
        dev->state = rc_connected;
        
        /* Are the maximum number of devices connected? If not, enable BLE scanning so other devices can be discovered & connected */
        if (theSink.rundata->bleInputMonitor.active_remotes < theSink.rundata->bleInputMonitor.config->max_remotes)
        {
            start_ble_scanning();
        }
    }
}


/*******************************************************************************
NAME
    handleReadReportReferenceDescriptor

DESCRIPTION
    Helper function to handle when a Report Reference characterisitic is being
    read.
    This will discover which type of report the associated Report characteristic
    is defined as and write the appropriate data.
*/
static void handleReadReportReferenceDescriptor( remoteController_t * dev, GATT_READ_CHARACTERISTIC_VALUE_CFM_T * m )
{
    if (dev)
    {
        /* Find the Report characteristic the report reference descriptor is associated and write the report type */
        uint16 i;
        for (i=0; i<dev->num_characteristics; i++)
        {
            /* Does the current characteristic belong to the current service that is being processed? */
            if ((dev->characteristics[i].handle >= dev->processing_start) && (dev->characteristics[i].handle <= dev->processing_end))
            {
                /* Is the current characteristic a Report? If so, is it the one associated with the report reference descriptor? (Not a nice conditional statement!) */
                if ( (dev->characteristics[i].uuid == GATT_CHARACTERISTIC_UUID_REPORT) && 
                     (dev->characteristics[i].handle < dev->reading_handle) &&
                     ((i == dev->num_characteristics-1) ? TRUE /* Last characteristic in list so do not check [i+1] */ : ((dev->characteristics[i+1].handle > dev->reading_handle ) ? TRUE : FALSE) ) )
                {
                    /* What report type is the report characteristic referenced by the report reference descriptor? */
                    if (m->size_value > 0)
                    {
                        /* Little endian; read the second octect of the first word (which is the report type) */
                        switch(m->value[1])
                        {
                            case gatt_report_reference_input_report:
                            {
                                dev->characteristics[i].report_type = type_input_report;
                            }
                            break;
                            case gatt_report_reference_output_report:
                            {
                                dev->characteristics[i].report_type = type_output_report;
                            }
                            break;
                            case gatt_report_reference_feature_report:
                            {
                                dev->characteristics[i].report_type = type_feature_report;
                            }
                            break;
                            case gatt_report_reference_reserved:
                            default:
                            {
                                dev->characteristics[i].report_type = type_report_none;
                            }
                        }
                        
                        /* Store the Report's ID */
                        dev->characteristics[i].report_id = m->value[0];
#ifdef DEBUG_BLE_RC_ALL
                            BLE_RC_DEBUG(("BLE : Report handle[%x] is report type [%x] ID is[%x]\n", dev->characteristics[i].handle, dev->characteristics[i].report_type, dev->characteristics[i].report_id));
#endif
                            return;
                    }
                    else
                    {
                        /* Report reference data is empty */
                        dev->characteristics[i].report_type = type_report_none;
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG(("BLE : Report handle[%x] is report type [UNDEFINED]\n", dev->characteristics[i].handle));
#endif
                        return;
                    }
                }
            }
        }
#ifdef DEBUG_BLE_RC_ALL
        BLE_RC_DEBUG(("BLE : Couldn't find report char for reference handle[%x]\n", dev->reading_handle));
#endif
    }
}


/*******************************************************************************
NAME
    handleReadCharacteristicDeclarationDescriptor

DESCRIPTION
    Helper function to handle when a characteristic declaration is being read.
    This will read the properties for the characteristic and add them to the 
    runtime data.
*/
static void handleReadCharacteristicDeclarationDescriptor( remoteController_t * dev, GATT_READ_CHARACTERISTIC_VALUE_CFM_T * m )
{
    if (dev)
    {
        /* Get the UUID of the characteristic value by reading the characteristic declaration */
        uint16 the_uuid = m->value[4]<<8 | m->value[3];
        
        /* Find the characteristic value and add the properties for that characteristic */
        uint16 i;
        for (i=0; i<dev->num_characteristics; i++)
        {
            /* Does the current characteristic belong to the current service that is being processed? */
            if ((dev->characteristics[i].handle >= dev->processing_start) && (dev->characteristics[i].handle <= dev->processing_end))
            {
                /* Is the current characteristic value the one that the properties are associated? */
                if ((dev->characteristics[i].uuid == the_uuid) && (dev->characteristics[i].handle == (dev->reading_handle + 1)) ) /* Characteristic declarations MUST always be the handle immediately before the characteristic value */
                {
                    /* Store the characteristic properties for the characteristic value */
                    dev->characteristics[i].props = (uint8)(m->value[0] & 0xFF);
                    
                    BLE_RC_DEBUG(("BLE : Added properties[%02x] for char[%x] handle[%x]\n", dev->characteristics[i].props, dev->characteristics[i].uuid, dev->characteristics[i].handle));
                    
                    return;
                }
            }
        }
    }
}


/*******************************************************************************
NAME
    parseReportMapCharacteristic

DESCRIPTION
    Helper function to parse a report map characteristic once it's value has
    been read.
*/
static void parseReportMapCharacteristic( remoteController_t * dev , bleHidRcSupportedServices_t service_type , GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T * m )
{
    /* If running in PTS test mode, don't bother parsing the report map to find out which reports to allow notifications from. Just allow notifications from all reports */
    if (theSink.rundata->bleInputMonitor.pts_test_mode)
    {
        uint16 j;
        for (j=0; j<dev->num_characteristics; j++)
        {
            /* If the characteristic is a REPORT or INPUT_REPORT, allow it to send notifications */
            if ((dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_REPORT) ||
                (dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_INPUT_REPORT) ||
                (dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_BOOT_MOUSE_INPUT_REPORT))
            {
                dev->characteristics[j].notify = 1;
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG(("Char handle[%x] - enable notifications\n", dev->characteristics[j].handle));
#endif
            }
        }
        return;
    }
    else
    {
        uint16 tag, size_el, el, i=0;
        
        if (!dev)
            return;
#ifdef DEBUG_BLE_RC_ALL
        BLE_RC_DEBUG(("\nBLE REPORT_MAP : Start parsing\n"));
#endif
        /* Check each element of the descriptor list */
        while (i<m->size_value)
        {
            /* Get the tag and the Value defined for the current element */
            tag      = (m->value[i] >> 2);
            size_el  = (m->value[i] & 0x03);
            /* If the tag has a value, get it */
            if (size_el)
                el = (size_el==1)  ?  (m->value[i+1])  :  ((m->value[i+2] << 8) | m->value[i+1]);
            else
                el = 0;
            i+= size_el;
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG(("BLE REPORT_MAP : data=%02x tag=%02x, size=%d val=%04x\n", (tag<<2 | size_el), tag, size_el, el));
#endif        
            switch(tag)
            {
                case USB_HID_TAG_USEAGE_PAGE:
                {
                    /* Is it a consumer page? If not, ignore it */
                    if (el == USB_USAGE_PAGE_CONSUMER)
                    {
                        /* Check the next tag is a usage tag */
                        i++;
                        tag      = (m->value[i] >> 2);
                        size_el  = (m->value[i] & 0x03);
                        /* If the tag has a value, get it */
                        if (size_el)
                            el = (size_el==1)  ?  (m->value[i+1])  :  ((m->value[i+2] << 8) | m->value[i+1]);
                        else
                            el = 0;
                        i+= size_el;
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG(("BLE REPORT_MAP : data=%02x tag=%02x, size=%d val=%04x\n", (tag<<2 | size_el), tag, size_el, el));
#endif                    
                        /* Is it a usage? otherwise ignore it */
                        switch(tag)
                        {
                            case USB_HID_TAG_USAGE:
                            {
                                /* What usage is it defining? Only interested in "Consumer control" usage */
                                switch(el)
                                {
                                    case USB_CONSUMER_USAGE_CONSUMER_CONTROL:
                                    {
                                        i++;
                                        tag      = (m->value[i] >> 2);
                                        size_el  = (m->value[i] & 0x03);
                                        /* If the tag has a value, get it */
                                        if (size_el)
                                            el = (size_el==1)  ?  (m->value[i+1])  :  ((m->value[i+2] << 8) | m->value[i+1]);
                                        else
                                            el = 0;
                                        i+= size_el;
#ifdef DEBUG_BLE_RC_ALL
                                        BLE_RC_DEBUG(("BLE REPORT_MAP : data=%02x tag=%02x, size=%d val=%04x\n", (tag<<2 | size_el), tag, size_el, el));
#endif
                                        
                                        /* Check the next tag is a collection */
                                        if (tag == USB_HID_TAG_COLLECTION)
                                        {
                                            uint16 sub_collection_depth = 0;  /* If sub collections are defined, need to know how deep into sub collections the parser is */
                                            BLE_RC_DEBUG(("BLE REPORT_MAP : Collection Start\n"));
                                            
                                            /* The Report ID (for HID consumer code transfer) should be contained within this collection, so find it */
                                            while (i<m->size_value)
                                            {
                                                bool finished_collection = FALSE;
                                                /* Need to process all the tags contained within the HID Consumer Control Collection, and find the report tag that will contain consumer HID codes sent from the remote controller */
                                                i++;
                                                tag      = (m->value[i] >> 2);
                                                size_el  = (m->value[i] & 0x03);
                                                /* If the tag has a value, get it */
                                                if (size_el)
                                                    el = (size_el==1)  ?  (m->value[i+1])  :  ((m->value[i+2] << 8) | m->value[i+1]);
                                                else
                                                    el = 0;
                                                i+= size_el;
#ifdef DEBUG_BLE_RC_ALL
                                                BLE_RC_DEBUG(("BLE REPORT_MAP : col: data=%02x tag=%02x, size=%d val=%04x\n", (tag<<2 | size_el), tag, size_el, el));
#endif
                                                
                                                switch(tag)
                                                {
                                                    case USB_HID_TAG_REPORT_ID:
                                                    {
                                                        uint16 j;
#ifdef DEBUG_BLE_RC_ALL
                                                        BLE_RC_DEBUG(("BLE REPORT_MAP : Found Consumer Report ID[%x] ", el));
#endif
                                                        /* Find the report characteristic with this ID */
                                                        for (j=0; j<dev->num_characteristics; j++)
                                                        {
                                                            if ( ((dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_REPORT) ||
                                                                  (dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_INPUT_REPORT) ||
                                                                  (dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_BOOT_MOUSE_INPUT_REPORT))
                                                                && 
                                                                 (dev->characteristics[j].report_id == el) )
                                                            {
                                                                /* Want to recieve notifications from this report (as it will contain Consumer HID data) */
                                                                dev->characteristics[j].notify = 1;
#ifdef DEBUG_BLE_RC_ALL
                                                                BLE_RC_DEBUG(("Char handle[%x] - enable notifications", dev->characteristics[j].handle));
#endif
                                                                break;
                                                            }
                                                        }
#ifdef DEBUG_BLE_RC_ALL
                                                        BLE_RC_DEBUG(("\n"));
#endif
                                                    }
                                                    break;
                                                    case USB_HID_TAG_COLLECTION:
                                                    {
#ifdef DEBUG_BLE_RC_ALL
                                                        BLE_RC_DEBUG(("BLE REPORT_MAP : Found sub-collection\n"));
#endif
                                                        sub_collection_depth++;
                                                    }
                                                    case USB_HID_TAG_END_COLLECTION:
                                                    {
                                                        if (sub_collection_depth)
                                                        {
                                                            sub_collection_depth--;
#ifdef DEBUG_BLE_RC_ALL
                                                            BLE_RC_DEBUG(("BLE REPORT_MAP : End of sub-collection\n"));
#endif
                                                        }
                                                        else
                                                        {
                                                            /* Finished processing current collection */
                                                            finished_collection = TRUE;
                                                        }
                                                    }
                                                    default:
                                                    {
                                                        /* Ignore unsupported descriptor element within the current collection */
                                                    }
                                                }
                                                if (finished_collection)
                                                {
#ifdef DEBUG_BLE_RC_ALL
                                                    BLE_RC_DEBUG(("BLE REPORT_MAP : Collection End\n"));
#endif
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    break;
                                    case USB_CONSUMER_USAGE_UNASSIGNED:
                                    case USB_CONSUMER_USAGE_NUMERIC_KEYPAD:
                                        /* Handle if supporting other usages for consumer usage pages */
                                    default:
                                    {
                                        /* Ignore */
                                    }
                                }
                            }
                            break;
                            default:
                            {
                            }
                        }
                    }
                    /* If required, support other Usage Page types */
                    else
                    {
#ifdef DEBUG_BLE_RC_ALL
                        BLE_RC_DEBUG(("BLE REPORT_MAP : USAGE PAGE [%x] ignored\n", el));
#endif
                    }
                }
                /* If required, support other Global/Main descriptor tags */
                break;
            }
            /* Check next element in descriptor list */
            i++;
        }
#ifdef DEBUG_BLE_RC_ALL
        BLE_RC_DEBUG(("BLE REPORT_MAP : DONE\n\n"));
#endif
    }
}


/*******************************************************************************
NAME
    getServiceTypeBeingProcessed
DESCRIPTION
    Helper function to get the current service being processed based on the dev
    state.
*/
static bleHidRcSupportedServices_t getServiceTypeBeingProcessed(remoteController_t * dev)
{
    /* What service type is being processed? */
    switch (dev->state)
    {
        case rc_processing_hid:
        {
            return service_hid;
        }
        break;
        case rc_processing_battery:
        {
            return service_battery;
        }
        break;
        case rc_processing_dinfo:
        {
            return service_dev_info;
        }
        break;
        default:
        {
            return service_invalid;
        }
    }
}


/******************************************************************************/
void hogpHandleGattReadCharacteristicValueCfm( GATT_READ_CHARACTERISTIC_VALUE_CFM_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
#ifdef DEBUG_BLE_RC_ALL
    else
    {
        uint16 i;
        BLE_RC_DEBUG(("BLE : Read from handle[%02x] size[%02d] data[ ", m->handle, m->size_value));
        for (i=0; i<m->size_value; i++)
        {
            BLE_RC_DEBUG(("%02x ", m->value[i]));
        }
        BLE_RC_DEBUG(("]\n"));
    }
#endif
    
    /* Check the message is for the expected handle */
    if (m->handle == dev->reading_handle)
    {
        /* What service type is being processed? */
        bleHidRcSupportedServices_t s_type = getServiceTypeBeingProcessed(dev);
        if (s_type != service_invalid)
        {
            /* Process the read data for the characteristic */
            switch(dev->reading_type)
            {
                case reading_all_characteristics:            
                {
                    /* Continue reading characteristics for the current service (Don't need to do anything with the read data for the current characteristic) */
                    readCharacteristicsForService(dev, s_type);
                }
                break;
                case reading_all_descriptors:
                {
                    /* Continue reading descriptors for the current service (Don't need to do anything with the read data for current descriptor) */
                    readDescriptorsForService(dev, s_type);
                }
                break;
                case reading_char_declaration:
                {
                    /* Read the characteristic declaration and add the properties for the characteristic */
                    handleReadCharacteristicDeclarationDescriptor(dev, m);
                    /* Continue reading descriptors for the current service */
                    readDescriptorsForService(dev, s_type);
                }
                break;
                case reading_report_reference:
                {
                    /* First of all read the report reference descriptor and add the report type & ID for the characteristic */ 
                    handleReadReportReferenceDescriptor(dev, m);
                    /* Continue reading descriptors for the current service */
                    readDescriptorsForService(dev, s_type);
                }
                break;
                default:
                {
                    BLE_RC_DEBUG(("BLE : ERROR, Read in wrong reading state [%x]\n", dev->reading_type));
                }
            }
        }
        else
        {
            BLE_RC_DEBUG(("BLE : Read characteristic in wrong state [%x]\n", dev->state));
        }
    }
    
    
}

/******************************************************************************/
void hogpHandleGattReadLongCharacteristicValueCfm(GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T * m)
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
#ifdef DEBUG_BLE_RC_ALL   
    else
    {
        uint16 i;
        BLE_RC_DEBUG(("BLE : Read from handle[%02x] size[%02d] data[ ", m->handle, m->size_value));
        for (i=0; i<m->size_value; i++)
        {
            BLE_RC_DEBUG(("%02x ", m->value[i]));
        }
        BLE_RC_DEBUG(("]\n"));
    }
#endif
    
    /* Check the message is for the expected handle */
    if (m->handle == dev->reading_handle)
    {
        /* What service type is being processed? */
        bleHidRcSupportedServices_t s_type = getServiceTypeBeingProcessed(dev);
        
        if (s_type != service_invalid)
        {
            /* Process the read data for the characteristic */
            switch(dev->reading_type)
            {
                case reading_report_map:
                {
                    /* Parse the report map characteristic to be able to understand incoming notifications from the device */
                    parseReportMapCharacteristic(dev, s_type, m);
                    /* Continue reading characteristics for the current service */
                    readCharacteristicsForService(dev, s_type);
                }
                break;
                default:
                {
                    BLE_RC_DEBUG(("BLE : ERROR, Read long in wrong reading state [%x]\n", dev->reading_type));
                }
            }
        }
        else
        {
            BLE_RC_DEBUG(("BLE : ERROR, Read long in wrong state [%x]\n", dev->state));
        }
    }

}


/******************************************************************************/
void hogpHandleGattWriteWithoutResponseCfm( GATT_WRITE_WITHOUT_RESPONSE_CFM_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    if (dev)
    {
        if (m->status != gatt_status_success)
        {
            BLE_RC_DEBUG(("BLE : Write [WWR] failed with status[%x] for handle[%x]\n", m->status, m->handle));
            return;
        }
        /* Write without response succeeded; no response required */
    }
}


/*******************************************************************************
NAME
    hogpHandleGattWriteCharacteristicCfm

DESCRIPTION
    Helper function to handle GATT write requests, handles GATT message:
    GATT_WRITE_CHARACTERISTIC_VALUE_CFM
*/
void hogpHandleGattWriteCharacteristicCfm( GATT_WRITE_CHARACTERISTIC_VALUE_CFM_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (dev)
    {
        switch(dev->state)
        {
            /* Depending on current state, decide how to continue */
            case rc_processing_hid:
            {
                if (dev->writing_pts_data)
                {
                    dev->writing_pts_data = 0;
                    writePtsCharacteristicsForService(dev, service_hid);
                }
            }
            break;
            case rc_processing_battery:
            {
                if (dev->writing_pts_data)
                {
                    dev->writing_pts_data = 0;
                    writePtsCharacteristicsForService(dev, service_battery);
                }
            }
            break;
            case rc_setup_notifications:
            {
                /* Enabling or Disabling notifications? */
                bool enable_notify = FALSE;
                if (dev->notify_status)
                {
                    enable_notify       = TRUE;
                    dev->notify_status  = 0;     /* Clear the flag ready for next use */
                }
                
                /* Which notifications are being enabled (HID or Battery)? */
                if (dev->write_hid_notify)
                {
                    /* Continue searching current HID service for more characteristics that support notifications */
                    dev->write_hid_notify = 0;  /* Clear the flag ready for next use */
                    setupHidNotifications(dev, enable_notify);
                }
                else if (dev->write_bat_notify)
                {
                    /* Continue searching current battery service for more characteristics that support notifications */
                    dev->write_bat_notify = 0;  /* Clear the flag ready for next use */
                    setupBatteryNotifications(dev, enable_notify);
                }
            }
            break;
            case rc_connected:
            {
                /* Written Suspend Mode? */
            }
            break;
            default:
            {
                BLE_RC_DEBUG(("BLE : Error, write CFM in wrong state [%x]\n", dev->state));
                return;
            }
        }
    }       
}


/******************************************************************************/
void hogpHandleGattNotificationInd( GATT_NOTIFICATION_IND_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
    
    /* Only process the notification if the remote controller is connected and all characteristics have been discovered */
    if (dev->state == rc_connected)
    {
        uint16 i;
        uint16 theUuid = 0;
        
        /* Check the characteristic that has been recieved is one that is supported */
        for ( i=0 ; i < dev->num_characteristics ; i++ )
        {
            if (dev->characteristics[i].handle == m->handle)
            {
                /* Ensure that the report is one that we want to recieve notifications from */
                if (dev->characteristics[i].notify)
                {
                    /* Get the UUID for the characteristic that was recieved */
                    theUuid = dev->characteristics[i].uuid;
                    break;
                }
                else
                {
                    /* Ignore the report, it's one that shouldn't have been sent by the HID device */
                    return;
                }
            }
        }
        
        /* Check the characteristic was found */
        if (theUuid == 0)
        {
            return;
            /* Can't handle a characteristic the device didn't sent as part of the "Discover Characteristics" (Device is out of spec) */
        }
        
        /* Process the characteristic */
        switch(theUuid)
        {
            /* HID UUID Characteristics */
            case GATT_CHARACTERISTIC_UUID_REPORT:
            {
                uint16                  i,j;
                bleHidRcMessageID_t     mID=0;              /* Message ID to send */
                uint16                  num_hid_codes=0;    /* Number of HID codes contained within the notification */
                uint16                  num_codes_found=0;  /* Number of HID codes that have been found within the notification */
                uint16                  current_mask=0;     /* This represents the RC button(s) that are pressed down when the notification was sent */
                
#ifdef DEBUG_BLE_RC_ALL  
                BLE_RC_DEBUG(("BLE : GATT_NOTIFY handle[%x] data[ ", m->handle));
                for (i=0; i<m->size_value; i++)
                {
                    BLE_RC_DEBUG(("%02x ", m->value[i]));
                }
                BLE_RC_DEBUG(("]\n"));
#endif
                
                /* Check the indication to see how many HID codes are contained within the message */
                for (i=0; i<m->size_value; i++)
                {
                    if (m->value[i] != 0)
                    {
                        num_hid_codes++;
                    }
                }
                
                /* If the message did not contain any HID codes, all buttons have been released */
                if (num_hid_codes == 0)
                {
                    MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_BUTTON_EVENT_MSG);
                    message->cid = m->cid;
                    message->mask = 0;
                    mID = BLE_HID_RC_BUTTON_UP_MSG;
                    
                    /* Send the button event off to be processed */
                    MessageSend( &theSink.rundata->bleInputMonitor.task, mID, message );
                }
                /* At least one HID code was sent by the remote controller */
                else
                {
                    /* Find the *known* HID codes that were sent and convert to an input mask */
                    for (i=0; i<m->size_value; i++)
                    {
                        if (m->value[i] != 0)
                        {
                            /* Found a HID code; use the lookup table to convert it to an "input mask" (if it's a known code, otherwise it will be ignored) */
                            for (j=0; j<theSink.rundata->bleInputMonitor.size_lookup_table; j++)
                            {
                                if (theSink.rundata->bleInputMonitor.config->lookup_table[j].hid_code == m->value[i])
                                {
                                    current_mask |= (1 << theSink.rundata->bleInputMonitor.config->lookup_table[j].input_id);
                                    break;
                                }
                            }
                        }
                        /* Have all the HID codes been found? */
                        if (num_hid_codes == num_codes_found)
                        {
                            break;
                        }
                    }
                    
                    /* Ensure that the HID code sent by the remote controller is one that is understood (exists in lookup table) */
                    if (current_mask)
                    {
                        /* Is this a single button press? */
                        if (dev->button_mask == 0)
                        {
                            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_BUTTON_EVENT_MSG);
                            mID = BLE_HID_RC_BUTTON_DOWN_MSG;
                            message->mask = current_mask;
                            message->cid = m->cid;
                            MessageSend( &theSink.rundata->bleInputMonitor.task, mID, message );
                        }
                        /* This notification indicates a button(s) release */
                        else if (current_mask & dev->button_mask)
                        {
                            /* Inform the input manager of the buttons that are still pressed down (if any) */
                            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_BUTTON_EVENT_MSG);
                            mID = BLE_HID_RC_BUTTON_UP_MSG;
                            message->cid = m->cid;
                            message->mask = current_mask;
                            MessageSend( &theSink.rundata->bleInputMonitor.task, mID, message );
                        }
                        /* This notification indicates other button(s) have been pressed */
                        else
                        {
                            /* Inform the input manager which new button(s) have been pressed */
                            MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_BUTTON_EVENT_MSG);
                            mID = BLE_HID_RC_BUTTON_DOWN_MSG;
                            message->cid = m->cid;
                            message->mask = current_mask;
                            MessageSend( &theSink.rundata->bleInputMonitor.task, mID, message );
                        }
                    }
                }
            }
            break;
            case GATT_CHARACTERISTIC_UUID_PROTOCOL_MODE:
            case GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_INPUT_REPORT:
            case GATT_CHARACTERISTIC_UUID_BOOT_KEYBOARD_OUTPUT_REPORT:
            case GATT_CHARACTERISTIC_UUID_BOOT_MOUSE_INPUT_REPORT:
            case GATT_CHARACTERISTIC_UUID_REPORT_MAP:
            case GATT_CHARACTERISTIC_UUID_HID_CONTROL_POINT:
            case GATT_CHARACTERISTIC_UUID_HID_INFORMATION:
            
            /* TODO : BATTERY Characteristics */
            
            default:
            {
                BLE_RC_DEBUG(("Ignoring characteristic handle[%x]\n", m->handle));
            }
        }
    }
}


/******************************************************************************/
void hogpHandleGattDisconnectInd( GATT_DISCONNECT_IND_T * m )
{
    BLE_RC_DEBUG(("BLE : RC[%x] Disconnected\n", m->cid));
    
    /* Delete the device that has disconnected */
    deleteBleDevice(m->cid);
}


/*******************************************************************************
    Helper function to create and send a message to the bleInputMonitorTask
    
    PARAMETERS:
    mid         - Message ID
    timer       - Timer ID to identify which timer this message is going to be
    mask        - input mask
    cid         - connection ID of the remote device whose button this message is associated (assigned by the GATT lib)
    delay_time  - delay sending the message by *timer* ms
*/
static void createBleHidRcButtonEventMessage(bleHidRcMessageID_t mid, bleHidRcTimerID_t timer, uint16 mask, uint16 cid, uint32 delay_time)
{
    /* Create a BLE_HID_RC_BUTTON_EVENT_MSG_T, this data type is generic for all "button event messages" sent to the Input monitor */
    MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_BUTTON_EVENT_MSG);
    message->timer  = timer;
    message->mask   = mask;
    message->cid    = cid;
    
    /* Dispatch the message */
    MessageSendLater(&theSink.rundata->bleInputMonitor.task, mid, message, delay_time);
}


/*******************************************************************************
NAME
    handleBleHidRcButtonEventMsg

DESCRIPTION
    Helper function to handle the BLE_HID_RC_BUTTON_EVENT_MSG
    At this point, the BLE HID code has been translated into an input mask
    and can be processed as a "normal" button.
*/
static void handleBleHidRcButtonEventMsg( bleHidRcMessageID_t messageId, BLE_HID_RC_BUTTON_EVENT_MSG_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
    
    /* Which button message has been sent? */
    switch(messageId)
    {
        case BLE_HID_RC_BUTTON_DOWN_MSG:
        {
            if (dev->d_state == inputNotDown)
            {
                /* Update the state for the input(s) and keep track of which button has been pressed down */
                dev->buttons_down = bitCounter16(m->mask);
                dev->d_state = inputMultipleDetect;
                dev->button_mask = m->mask;
                
                /* Start the M_DOWN button timer to allow multiple buttons to be detected; once this timer fires, multiple buttons will not be detected */
                createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_TIMER_MSG, BLE_HID_RC_TIMER_MULTIPLE, 0, m->cid, theSink.rundata->bleInputMonitor.timers->multipleDetectTimer);
            }
            /* Are there already buttons pressed? */
            else if (dev->d_state == inputMultipleDetect)
            {
                /* Add the newly pressed button to the mask to keep track of which multiple buttons are currently pressed down */
                dev->button_mask |= m->mask;
                dev->buttons_down += bitCounter16(m->mask);
            }
            else
            {
                /* Ignore the new button press */
            }
        }
        break;
        case BLE_HID_RC_BUTTON_TIMER_MSG:
        {
            /* Which timer has fired? */
            switch(m->timer)
            {
                case BLE_HID_RC_TIMER_MULTIPLE:
                {
                    /* Update the state for the input(s) */
                    dev->d_state = inputDownVShort;
                    
                    /* Notify the input manager of the input button press (only if the DOWN event hasn't already been sent - which can happen in very corner cases of very very fast multiple button press/release) */
                    if (dev->d_sent_in_m_state == 0)
                    {
                        notifyInputManager( inputMonitorBLEHIDRemote, inputEventDown, dev->button_mask, dev->cid );
                    }
                    
                    /* Start the SHORT and REPEAT button timers */
                    createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_TIMER_MSG, BLE_HID_RC_TIMER_SHORT, dev->button_mask, m->cid, (theSink.rundata->bleInputMonitor.timers->shortTimer - theSink.rundata->bleInputMonitor.timers->multipleDetectTimer) );
                    createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_REPEAT_MSG, 0, dev->button_mask, m->cid, (theSink.rundata->bleInputMonitor.timers->repeatTimer - theSink.rundata->bleInputMonitor.timers->multipleDetectTimer) );
                }
                break;
                case BLE_HID_RC_TIMER_SHORT:
                {
                    /* Update the button mask for the RC */
                    dev->d_state     = inputDownShort;
                    
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventShortTimer, m->mask, dev->cid );
                    
                    /* Start the LONG timer */
                    createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_TIMER_MSG,  BLE_HID_RC_TIMER_LONG, m->mask, m->cid, (theSink.rundata->bleInputMonitor.timers->longTimer - theSink.rundata->bleInputMonitor.timers->shortTimer) );
                }
                break;
                case BLE_HID_RC_TIMER_LONG:
                {
                    /* Update the button mask for the RC */
                    dev->d_state     = inputDownLong;
                    
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventLongTimer, m->mask, dev->cid );
                    
                    /* Start the VLONG timer */
                    createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_TIMER_MSG,  BLE_HID_RC_TIMER_VLONG, m->mask, m->cid, (theSink.rundata->bleInputMonitor.timers->vLongTimer - theSink.rundata->bleInputMonitor.timers->longTimer) );
                }
                break;
                case BLE_HID_RC_TIMER_VLONG:
                {
                    /* Update the button mask for the RC */
                    dev->d_state     = inputDownVLong;
                    
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventVLongTimer, m->mask, dev->cid );
                    
                    /* Start the VVLONG timer */
                    createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_TIMER_MSG,  BLE_HID_RC_TIMER_VVLONG, m->mask, m->cid, (theSink.rundata->bleInputMonitor.timers->vvLongTimer - theSink.rundata->bleInputMonitor.timers->vLongTimer) );
                }
                break;
                case BLE_HID_RC_TIMER_VVLONG:
                {
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventVVLongTimer, m->mask, dev->cid );
                    
                    /* Update the button mask for the RC */
                    dev->d_state     = inputDownVVLong;
                }
                break;
            }
        }
        break;
        case BLE_HID_RC_BUTTON_REPEAT_MSG:
        {
            /* Notify the input manager of the timer event */
            notifyInputManager( inputMonitorBLEHIDRemote, inputEventRepeatTimer, m->mask, dev->cid );
                    
            /* Keep sending REPEAT messages until the button(s) is/are released */
            createBleHidRcButtonEventMessage( BLE_HID_RC_BUTTON_REPEAT_MSG, 0, m->mask, m->cid, theSink.rundata->bleInputMonitor.timers->repeatTimer );
        }
        break;
        case BLE_HID_RC_BUTTON_UP_MSG:
        {
            /* Is this a valid release? The input mask should not be identical to the current pressed button(s) */
            if (m->mask == dev->button_mask)
            {
                /* Ignore the button release */
                return;
            }
            /* Are there any more buttons held down? */
            else if (m->mask == 0)
            {
                /* All buttons have been released */
                
                /* Cancel the (MULTIPLE,SHORT,LONG,VLONG or VVLONG) TIMER & REPEAT timers*/
                MessageCancelAll(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_BUTTON_TIMER_MSG);
                MessageCancelAll(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_BUTTON_REPEAT_MSG);
                
                /* Update the button state for the RC ready for the next button press */
                dev->buttons_down = 0;
            }
            else
            {
                /* Update the exact number of buttons still held down */
                dev->buttons_down -= bitCounter16(m->mask);
            }
                    
            /* Process the button(s) release, what state was the button when it was released? */
            switch(dev->d_state)
            {
                case inputNotDown:
                {
                    /* Will get here when a multiple button press has been detected but one of the buttons was released early, when the other buttons are released will end up here */
                }
                break;
                case inputMultipleDetect:
                {
                    if (dev->d_sent_in_m_state == 0)
                    {
                        /* This was a very very quick button(s) press; need to send the input manager a DOWN event to notify there was a button pressed down (before sending the release event) */
                        notifyInputManager( inputMonitorBLEHIDRemote, inputEventDown, dev->button_mask, dev->cid );
                        dev->d_sent_in_m_state = 1;
                    }
                }
                case inputDownVShort:
                {
                    /* Notify the input manager of the "very short button press" event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventVShortRelease, m->mask, dev->cid );
                }
                break;
                case inputDownShort:
                {
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventShortRelease, m->mask, dev->cid );
                }
                break;
                case inputDownLong:
                {
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventLongRelease, m->mask, dev->cid );
                }
                break;
                case inputDownVLong:
                {
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventVLongRelease, m->mask, dev->cid );
                }
                break;
                case inputDownVVLong:
                {
                    /* Notify the input manager of the timer event */
                    notifyInputManager( inputMonitorBLEHIDRemote, inputEventVVLongRelease, m->mask, dev->cid );
                }
                break;
            }
            
            /* Update the button mask for the device to keep track of the state of each of the buttons on the RC */
            dev->button_mask = m->mask;
            
            /* If no more buttons are down, update the state ready to  further button presses */
            if (dev->buttons_down == 0)
            {
                dev->d_state = inputNotDown;
                dev->d_sent_in_m_state = 0;
            }
        }
        break;
        default:
        {
            /* Ignore */
        }
    }
}


/******************************************************************************/
void hogpHandleGattIndicationInd( GATT_INDICATION_IND_T * m )
{
    /* Get the device this message is associated */
    remoteController_t *dev = getDevice(m->cid);
    
    /* Ensure the device pointer is valid */
    if (!dev)
    {
        return;
    }
    
    BLE_RC_DEBUG(("RC : Indication RC[%x] Handle[%x]\n", m->cid, m->handle));
    
    /* Respond to the indication */
    GattIndicationResponse(m->cid);
}


/*******************************************************************************
NAME
    ble_hid_rc_message_handler

DESCRIPTION
    BLE HID RC Task Handler
*/
static void ble_hid_rc_message_handler( Task task, MessageId id, Message message )
{
    if ( id == CL_SM_GET_AUTH_DEVICE_CFM )
    {
        handleBleRemoteGetAuthDevice( (CL_SM_GET_AUTH_DEVICE_CFM_T*)message );
    }
    /* Handle internal "BLE Input Monitor" messages */
    else if ( (id >= BLE_HID_RC_MSG_BASE) && (id < BLE_HID_RC_MSG_TOP) )
    {
        switch (id)
        {
            case BLE_HID_RC_BUTTON_DOWN_MSG:
            case BLE_HID_RC_BUTTON_TIMER_MSG:
            case BLE_HID_RC_BUTTON_REPEAT_MSG:
            case BLE_HID_RC_BUTTON_UP_MSG:
            {
                handleBleHidRcButtonEventMsg( id, (BLE_HID_RC_BUTTON_EVENT_MSG_T*)message );
            }
            break;
            case BLE_HID_RC_CONNECTION_TIMEOUT_MSG:
            {
                handleTimedOutDevice( ((BLE_HID_RC_CONNECTION_TIMEOUT_MSG_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ:
            {
                discoverAllPrimaryServices( ((BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_EVENT_PRIM_SERVICES_DISCOVERED:
            {
                handleAllPrimaryServicesDiscovered( ((BLE_HID_RC_EVENT_PRIM_SERVICES_DISCOVERED_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ:
            {
                discoverIncludedServices( ((BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_EVENT_INCLUDED_SERVICES_DISCOVERED:
            {
                handleIncludedServicesDiscovered( ((BLE_HID_RC_EVENT_INCLUDED_SERVICES_DISCOVERED_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ:
            {
                discoverAllCharacteristics( ((BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_EVENT_ALL_CHARACTERISTICS_DISCOVERED:
            {
                handleAllCharacteristicsDiscovered( ((BLE_HID_RC_EVENT_ALL_CHARACTERISTICS_DISCOVERED_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ:
            {
                discoverAllDescriptors( ((BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_EVENT_ALL_DESCRIPTORS_DISCOVERED:
            {
                handleAllDescriptorsDiscovered( ((BLE_HID_RC_EVENT_ALL_DESCRIPTORS_DISCOVERED_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_PROCESS_ALL_SERVICES_REQ:
            {
                processAllDiscoveredServices( ((BLE_HID_RC_PROCESS_ALL_SERVICES_REQ_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_EVENT_SERVICE_PROCESSED:
            {
                processAllServicesOfType( getDevice( ((BLE_HID_RC_EVENT_SERVICE_PROCESSED_T*)message)->cid ) , ((BLE_HID_RC_EVENT_SERVICE_PROCESSED_T*)message)->service_type );
            }
            break;
            case BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED:
            {
                handleAllServicesProcessed( ((BLE_HID_RC_EVENT_ALL_SERVICES_PROCESSED_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_SETUP_SUSPEND_MODE_REQ:
            {
                setupHidSuspendModeSupport( ((BLE_HID_RC_SETUP_SUSPEND_MODE_REQ_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP:
            {
                handleSuspendModeSetup( ((BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP_T*)message)->cid );
            }
            break;
            case BLE_HID_RC_SETUP_NOTIFICATIONS_REQ:
            {
                setupAllNotifications( ((BLE_HID_RC_SETUP_NOTIFICATIONS_REQ_T*)message)->cid, ((BLE_HID_RC_SETUP_NOTIFICATIONS_REQ_T*)message)->notify );
            }
            break;
            case BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP:
            {
                setupAllNotifications( ((BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP_T*)message)->cid, ((BLE_HID_RC_EVENT_SERVICE_NOTIFICATIONS_SETUP_T*)message)->notify );
            }
            break;
            case BLE_HID_RC_EVENT_ALL_NOTIFICATIONS_SETUP:
            {
                handleAllNotificationsSetup( ((BLE_HID_RC_EVENT_SUSPEND_MODE_SETUP_T*)message)->cid );
            }
            break;
            
            case BLE_HID_RC_ENTER_SUSPEND_MODE_REQ:
            {
                bleEnterSuspendMode();
            }
            break;
            case BLE_HID_RC_EXIT_SUSPEND_MODE_REQ:
            {
                bleExitSuspendMode();
            }
            break;
        }
    }
    else
    {
        BLE_RC_DEBUG(("BLE : Unhandled msg [%x]\n", id));
    }
}


/****************************************************************************/
void initBleHidInputMonitor( timerConfig_t * timers )
{
    /* The input monitor is only required if there's a lookup table to convert incoming HID events */
    if (theSink.rundata->bleInputMonitor.size_lookup_table)
    {
        BLE_RC_DEBUG(("BLE : Task Init\n"));
        
        /* Need to know about the configured timers */
        theSink.rundata->bleInputMonitor.timers = timers;
        
        /* Setup the message handler for the BLE RC Monitor */
        theSink.rundata->bleInputMonitor.task.handler = ble_hid_rc_message_handler;
        
        /* No remotes can be connected at this point */
        theSink.rundata->bleInputMonitor.active_remotes = 0;
        
        /* Initialise the data area used to store runtime data required by connected remote controllers */
        theSink.rundata->bleInputMonitor.remotes = mallocPanic(sizeof(remoteController_t) * theSink.rundata->bleInputMonitor.config->max_remotes);
        memset(theSink.rundata->bleInputMonitor.remotes, 0, sizeof(remoteController_t) * theSink.rundata->bleInputMonitor.config->max_remotes);
        
        /* Always give priority to Write method: write with response */
        theSink.rundata->bleInputMonitor.pts_write_with_response = 1;
        
        /* Allow remote controllers to connect */
        theSink.rundata->bleInputMonitor.ad_scan_disabled = 0;
        
        /* Set the BLE Scan parameters: enable_active_scanning=FALSE, random_own_address=FALSE, white_list_only=FALSE */
        ConnectionDmBleSetScanParametersReq(FALSE, FALSE, FALSE, theSink.rundata->bleInputMonitor.config->scan_params.scan_interval, theSink.rundata->bleInputMonitor.config->scan_params.scan_window);
    }
    else
    {
        BLE_RC_DEBUG(("BLE : Task Init (NOT Required)\n"));
        theSink.rundata->bleInputMonitor.remotes = NULL;
        
        /* Free BLE HOGP config data use as it's wasting memory use */
        free(theSink.rundata->bleInputMonitor.config);
    }
}


/*****************************************************************************/
void bleEnablePtsTestMode(void)
{
    BLE_RC_DEBUG(("BLE : PTS Test Mode enabled\n"));
    theSink.rundata->bleInputMonitor.pts_test_mode = 1;
}


/*****************************************************************************/
void bleDisablePtsTestMode(void)
{
    BLE_RC_DEBUG(("BLE : PTS Test Mode disabled\n"));
    theSink.rundata->bleInputMonitor.pts_test_mode = 0;
}


/*****************************************************************************/
void blePtsModeNext(void)
{
    BLE_RC_DEBUG(("BLE : PTS Test Mode next\n"));
    
    /* Depending on state, what event needs to be triggered? */
    switch(theSink.rundata->bleInputMonitor.remotes[0].state)
    {
        case rc_disconnected:
        {
            bleConnectStoredRemote();
        }
        break;
        case rc_ready_for_discovery:
        {
            /* Request to discover ALL primary services */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ);
                message->cid = cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_PRIMARY_SERVICES_REQ, message);
            }
        }
        break;
        case rc_ready_for_include:
        {
            /* Request to discover ALL included services */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ);
                message->cid = cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_INCLUDED_SERVICES_REQ, message);
            }
        }
        break;
        case rc_ready_for_chars:
        {
            /* Request to discover ALL characteristics (for all discovered services) */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ);
                message->cid = cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_ALL_CHARACTERISTICS_REQ, message);
            }
        }
        break;
        case rc_ready_for_descriptors:
        {
            /* Request to discover ALL descriptors (for all discovered services) */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ);
                message->cid = cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_DISCOVER_ALL_DESCRIPTORS_REQ, message);
            }
        }
        break;
        case rc_ready_for_processing:
        {
            /* Request to start processing the descriptors (for all discovered services; starting with HID) */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_PROCESS_ALL_SERVICES_REQ);
                message->cid = cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_PROCESS_ALL_SERVICES_REQ, message);
            }
        }
        break;
        case rc_setup_suspend_mode:
        {
            /* Request to setup the Suspend Mode for the device */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_SETUP_SUSPEND_MODE_REQ);
                message->cid = cid;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_SETUP_SUSPEND_MODE_REQ, message);
            }
        }
        break;
        case rc_setup_notifications:
        {
            /* Request to setup notifications for the device */
            uint16 cid = bdaddrToCid(theSink.rundata->bleInputMonitor.config->stored_addr);
            if (cid != 0xFFFF)
            {
                MAKE_BLE_RC_HID_MESSAGE(BLE_HID_RC_SETUP_NOTIFICATIONS_REQ);
                message->cid    = cid;
                message->notify = TRUE;
                MessageSend(&theSink.rundata->bleInputMonitor.task, BLE_HID_RC_SETUP_NOTIFICATIONS_REQ, message);
            }
        }
        break;
        /* States that are not valid for events to be triggered (task is busy doing some other operation) */
        case rc_connecting:
        case rc_service_discovery:
        case rc_included_discovery:
        case rc_char_discovery:
        case rc_descriptor_discovery:
        case rc_processing_hid:
        case rc_ready_to_process_bat:
        case rc_processing_battery:
        case rc_ready_to_process_dinfo:
        case rc_processing_dinfo:
        case rc_connected:
        {
        }
        break;
    }
}


/*****************************************************************************/
void bleChangeWriteModePriority(void)
{
    /* Change the write mode depending on its current state */
    if (theSink.rundata->bleInputMonitor.pts_write_with_response)
    {
        theSink.rundata->bleInputMonitor.pts_write_with_response = 0;
    }
    else
    {
        theSink.rundata->bleInputMonitor.pts_write_with_response = 1;
    }
}


/*****************************************************************************/
void bleEnablePairingMode(void)
{
    if(!theSink.rundata->bleInputMonitor.pairing_mode)
    {
        BLE_RC_DEBUG(("BLE : Pairing mode enabled\n"));
        theSink.rundata->bleInputMonitor.pairing_mode = 1;
    }
	else
	{
		BLE_RC_DEBUG(("BLE : Pairing mode re-enabled\n"));
		MessageCancelFirst(&theSink.task, EventSysBleRemotePairingTimeout);
	}
	
	MessageSendLater(&theSink.task, EventSysBleRemotePairingTimeout, 0, D_SEC(theSink.rundata->bleInputMonitor.config->pairing_timeout) );
  
}


/*****************************************************************************/
void bleDisablePairingMode(void)
{
    if(theSink.rundata->bleInputMonitor.pairing_mode)
    {
        BLE_RC_DEBUG(("BLE : Pairing mode disabled\n"));
        theSink.rundata->bleInputMonitor.pairing_mode = 0;
        MessageCancelFirst(&theSink.task, EventSysBleRemotePairingTimeout);
    }
}


/****************************************************************************/
void bleRemotePairingComplete(bool pairing_successful)
{
    /* If pairing was successful, disable pairing mode, otherwise wait for a successful pairing */
    if (pairing_successful)
    {
        bleDisablePairingMode();
    }
}


/****************************************************************************/
void handleBleRemotePairingComplete( CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND_T * m )
{
    /* Depending on whether pairing was successful or failed, send the appropriate event to be handled */
    if (m->status == success)
    {
        MessageSend(&theSink.task, EventSysBleRemotePairingSuccess, 0);
        /* mark this device as a priority device which will prevent it from getting
           removed from the PDL */
        ConnectionAuthSetPriorityDevice((const bdaddr *)&m->taddr.addr, TRUE);          
    }
    else
    {
        MessageSend(&theSink.task, EventSysBleRemotePairingFailed, 0);
    }
}


/****************************************************************************/
void hogpHandleRemoteAdvertisingReportInd(CL_DM_BLE_ADVERTISING_REPORT_IND_T * m)
{
    if (theSink.rundata->bleInputMonitor.config->max_remotes > 0)
    {
        /* Is the advertisement coming from a known BLE device? */
        uint16 i;
        for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
        {
            if (BdaddrTypedIsSame( &theSink.rundata->bleInputMonitor.remotes[i].taddr, &m->permanent_taddr) )
            {
#ifdef DEBUG_BLE_RC_ALL
                BLE_RC_DEBUG(("BLE : Ignore Advertisment from known RC[%04x %02x %06lu]\n", m->permanent_taddr.addr.nap, m->permanent_taddr.addr.uap, m->permanent_taddr.addr.lap));
#endif
                return;
            }
        }
    
        /* Is BLE pairing mode enabled? */
        if (theSink.rundata->bleInputMonitor.pairing_mode)
        {
            /* Allow any remote controller to be connected as pairing mode has been enabled */
#ifdef DEBUG_BLE_RC_ALL
            BLE_RC_DEBUG(("BLE : AD DATA [%x] : ", m->event_type));
            for (i=0; i < m->size_advertising_data; i++)
            {
                BLE_RC_DEBUG(("%x ", m->advertising_data[i]));
            }
            BLE_RC_DEBUG(("\n"));
#endif
        
            /* If the current Bluetooth device address has been set, use this for BLE connection */
            if (!BdaddrIsZero(&m->current_taddr.addr))
            {
                connectBleRemote(m->current_taddr.addr, m->current_taddr.type);
            }
            /* Check the permanent address for the device, if this is not zero, use this for BLE connection */
            else
            {
                if (!BdaddrIsZero(&m->permanent_taddr.addr))
                {
                    connectBleRemote(m->permanent_taddr.addr, m->permanent_taddr.type);
                }
                else
                {
                    BLE_RC_DEBUG(("BLE : Ignore device; no BDADDR available\n"));
                }
            }
        }
    }
    else
    {
        BLE_RC_DEBUG(("BLE : AD_IND, Ignored\n"));
    }
}


/****************************************************************************/
void bleConnectStoredRemote(void)
{
    BLE_RC_DEBUG(("BLE : Connect the stored BLE remote\n"));
    connectBleRemote(theSink.rundata->bleInputMonitor.config->stored_addr, TYPED_BDADDR_PUBLIC);
}


/****************************************************************************/
void bleEnterSuspendMode(void)
{
    /* Inform any connected remote controllers that low power mode is being entered */
    if (theSink.rundata->bleInputMonitor.active_remotes > 0)
    {
        uint16 i;
        for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
        {
            remoteController_t * dev = &theSink.rundata->bleInputMonitor.remotes[i];
            
            /* Check current entry in remote data has a remote */
            if ( !BdaddrIsZero(&theSink.rundata->bleInputMonitor.remotes[i].taddr.addr) )
            {
                /* Check each HID Control Point characteristic defined on the device */
                uint16 j;
                BLE_RC_DEBUG(("BLE : Put RC[%x] into suspend mode\n", dev->cid));
                for (j=0; j<dev->num_characteristics; j++)
                {
                    if ( (dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_HID_CONTROL_POINT) &&
                         (dev->characteristics[j].suspend) )
                    {
                        BLE_RC_DEBUG(("BLE : Write HID Control Point handle[%x]\n", dev->characteristics[j].handle ));
                        GattWriteWithoutResponseRequest(&theSink.rundata->bleInputMonitor.task, dev->cid, dev->characteristics[j].handle, sizeof(enter_suspend_mode), (uint8*)enter_suspend_mode );
                    }
                }
            }
        }
    }
}


/****************************************************************************/
void bleExitSuspendMode(void)
{
    /* Inform any connected remote controllers that low power mode is being exited */
    if (theSink.rundata->bleInputMonitor.active_remotes > 0)
    {
        uint16 i;
        for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
        {
            remoteController_t * dev = &theSink.rundata->bleInputMonitor.remotes[i];
            
            /* Check current entry in remote data has a remote */
            if ( !BdaddrIsZero(&theSink.rundata->bleInputMonitor.remotes[i].taddr.addr) )
            {
                /* Check each HID Control Point characteristic defined on the device */
                uint16 j;
                BLE_RC_DEBUG(("BLE : Take RC[%x] out of suspend mode\n", dev->cid));
                for (j=0; j<dev->num_characteristics; j++)
                {
                    if ( (dev->characteristics[j].uuid == GATT_CHARACTERISTIC_UUID_HID_CONTROL_POINT) &&
                         (dev->characteristics[j].suspend) )
                    {
                        BLE_RC_DEBUG(("BLE : Write HID Control Point handle[%x]\n", dev->characteristics[j].handle ));
                        GattWriteWithoutResponseRequest(&theSink.rundata->bleInputMonitor.task, dev->cid, dev->characteristics[j].handle, sizeof(exit_suspend_mode), (uint8*)exit_suspend_mode );
                    }
                }
            }
        }
    }
}


/****************************************************************************/
void bleEnableNotifications(void)
{
    /* Inform any connected remote controllers that low power mode is being exited */
    if (theSink.rundata->bleInputMonitor.active_remotes > 0)
    {
        uint16 i;
        for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
        {
            remoteController_t * dev = &theSink.rundata->bleInputMonitor.remotes[i];
            
            /* Check current entry in remote data has a remote */
            if ( !BdaddrIsZero(&theSink.rundata->bleInputMonitor.remotes[i].taddr.addr) )
            {
                BLE_RC_DEBUG(("BLE : Enable notifications on RC[%x]\n",dev->cid));
                dev->state = rc_setup_notifications;
                dev->service_search_index = 0;
                setupAllNotifications(dev->cid , TRUE);
            }
        }
    }
}


/****************************************************************************/
void bleDisableNotifications(void)
{
    /* Inform any connected remote controllers that low power mode is being exited */
    if (theSink.rundata->bleInputMonitor.active_remotes > 0)
    {
        uint16 i;
        for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
        {
            remoteController_t * dev = &theSink.rundata->bleInputMonitor.remotes[i];
            
            /* Check current entry in remote data has a remote */
            if ( !BdaddrIsZero(&theSink.rundata->bleInputMonitor.remotes[i].taddr.addr) )
            {
                BLE_RC_DEBUG(("BLE : Disable notifications on RC[%x]\n",dev->cid));
                dev->state = rc_setup_notifications;
                dev->service_search_index = 0;
                setupAllNotifications(dev->cid , FALSE);
            }
        }
    }
}


/****************************************************************************/
void bleDisconnectStoredRemote(void)
{
    /* Is the stored remote connected? If not, ignore this request, otherwise disconnect it */
    uint16 i;
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if (BdaddrIsSame( &theSink.rundata->bleInputMonitor.config->stored_addr, &theSink.rundata->bleInputMonitor.remotes[i].taddr.addr) )
        {
            BLE_RC_DEBUG(("BLE : Disconnect stored BLE Remote\n"));
            GattDisconnectRequest(theSink.rundata->bleInputMonitor.remotes[i].cid);
            return;
        }
    }
}


/****************************************************************************/
uint16 bleDisconnectAllConnectedRemotes(bool hard_reset)
{
    uint16 i, num_connected=0;
    
    /* If the device is powering off and about to hard reset, ensure RC's cannot reconnect */
    if (hard_reset)
    {
        theSink.rundata->bleInputMonitor.ad_scan_disabled = 1;
    }
    
    /* Cleanly disconnect any connected remote controllers */
    for (i=0; i<theSink.rundata->bleInputMonitor.config->max_remotes; i++)
    {
        if (theSink.rundata->bleInputMonitor.remotes[i].state != rc_disconnected)
        {
            BLE_RC_DEBUG(("BLE : Disconnect remote [%x]\n", theSink.rundata->bleInputMonitor.remotes[i].cid));
            num_connected++;
            GattDisconnectRequest(theSink.rundata->bleInputMonitor.remotes[i].cid);
        }
    }
    
    /* Return number of connected remote controllers before disconnection requests were sent */
    return num_connected;
}

#else /* defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED) */

static const int dummy_ble_hid_rc;  /* ISO C forbids an empty source file */

#endif /* defined(GATT_CLIENT_ENABLED) && defined(BLE_ENABLED) */
