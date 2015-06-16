/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2012-2014

FILE NAME
    sink_gatt.c

DESCRIPTION
    Implements GATT Functionality for the sink device
*/
#ifndef GATT_DISABLED


/* Application includes */
#include "sink_gatt.h"
#include "sink_private.h"
#include "sink_debug.h"
#ifdef GATT_SERVER_ENABLED
#include "sink_gatt_server.h"
#include "sink_gatt_db.h"
#endif
#ifdef GATT_CLIENT_ENABLED
#include "sink_gatt_client.h"
#endif
#ifdef BLE_ENABLED
#include "sink_ble_advertising.h"
#include "sink_ble_scanning.h"
#endif

/* Library includes */
#include <gatt.h>
#include <connection.h>

/* Firmware includes */
#include <csrtypes.h>
#include <message.h>
#include "sink_tones.h"


/* Macro for GATT Debug */
#ifdef DEBUG_GATT
#include <stdio.h>
#define GATT_DEBUG(x) DEBUG(x)
#else
#define GATT_DEBUG(x) 
#endif


/******************************************************************************/
void initialise_gatt_for_device(uint8 *name, uint16 size_name)
{
    /* Ensure GATT is never initialised more than once */
    if (theSink.rundata->gatt.initialised == FALSE)
    {
        GATT_DEBUG(("Init GATT\n"));
        
        theSink.rundata->gatt.task.handler = gatt_message_handler;
        
        /* NOTE : The device cannot be both advertiser AND scanner simultaneously */
        #ifdef GATT_SERVER_ENABLED
        {
            /* Ensure GATT has been configured as GATT server */
            if (theSink.rundata->gatt.config.mode == gatt_mode_server)
            {
                /* Init the GATT library using the DB built from the .db files included by the project */
                uint16 size_db, *db;
                db = GattGetDatabase(&size_db);
                GattInit(&theSink.rundata->gatt.task, size_db, db);
                
                /* Initialise runtime data used by the GATT server */
                theSink.rundata->gatt.server.dev_name_req.busy = FALSE;
                theSink.rundata->gatt.server.dev_name_req.cid  = 0;
                
                /* Setup GATT advertising; for BLE, use AD_DATA, for BR/EDR, use SDP to advertise services on this device */
#ifdef BLE_ENABLED
                {
                    setup_ble_ad_data(size_name, name);
                }
#else
                {
                    GATT_DEBUG(("TODO : Init GATT BR/EDR server tasks\n"));
                }
#endif
            }
            else
            {
                GATT_DEBUG(("GATT: GATT_SERVER_ENABLED, configured GATT role = Client (GATT DISABLED)\n"));
                return;
            }
        }
        #elif defined(GATT_CLIENT_ENABLED)
        {
            /* Ensure GATT has been configured as GATT client */
            if (theSink.rundata->gatt.config.mode == gatt_mode_client)
            {
                /* Initialise any GATT client tasks that have been configured (which will also init the GATT library) */
                setup_gatt_client_tasks(theSink.rundata->gatt.config.client);
            }
            else
            {
                GATT_DEBUG(("GATT: GATT_CLIENT_ENABLED, configured GATT role = Server (GATT DISABLED)\n"));
                return;
            }
        }
        #endif
    }
}


/******************************************************************************/
void gatt_message_handler( Task task, MessageId id, Message message )
{
    switch(id)
    {
        case GATT_INIT_CFM:
        {
            GATT_DEBUG(("GATT_INIT_CFM [%x]\n", ((GATT_INIT_CFM_T*)message)->status));
            
            #if defined(GATT_SERVER_ENABLED)
            {
                server_handle_gatt_init_cfm( (GATT_INIT_CFM_T*)message );
            }
            #elif defined(GATT_CLIENT_ENABLED)
            {
                client_handle_gatt_init_cfm( (GATT_INIT_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_CONNECT_CFM:
        {
            GATT_CONNECT_CFM_T * cfm = (GATT_CONNECT_CFM_T*)message;
            
            GATT_DEBUG(("GATT_CONNECT_CFM [%x]\n", cfm->status));
            
            #if defined(GATT_SERVER_ENABLED)
            {
                /* If the connection was successful, request to encrypt the link */
                if (cfm->status == gatt_status_success)
                {
                    #ifdef BLE_ENABLED
                    {
                        GATT_DEBUG(("Start BLE security\n"));
                        ConnectionDmBleSecurityReq(&theSink.task, &cfm->taddr, ble_security_encrypted, ble_connection_slave_directed);
                    }
                    #endif
                }
                server_handle_gatt_connect_cfm( (GATT_CONNECT_CFM_T*)message );
				TonesPlayEvent(EventSysRingtone1);
            }
            #elif defined(GATT_CLIENT_ENABLED)
            {
                /* If the connection was successful, re.quest to encrypt the link */
                if (cfm->status == gatt_status_success)
                {
                    #ifdef BLE_ENABLED
                    {
                        /* If HOGP feature is enabled and HOGP pairing mode is not enabled, set the security for the connection */
                        if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
                        {
                            if (theSink.rundata->bleInputMonitor.pairing_mode)
                            {
                                /* As HID Over GATT pairing mode is enabled, request to pair */
                                GATT_DEBUG(("BONDED REQ\n"));
                                ConnectionDmBleSecurityReq(&theSink.task, &cfm->taddr, ble_security_authenticated_bonded, ble_connection_master_directed);
                            }
                            else
                            {
                                /* Pairing mode disabled, so just encrypt the link (device will be already bonded) */
                                GATT_DEBUG(("ENCRYPT REQ\n"));
                                ConnectionDmBleSecurityReq(&theSink.task, &cfm->taddr, ble_security_encrypted, ble_connection_master_directed);
                            }
                        }
                    }
                    #endif
                }
                client_handle_gatt_connect_cfm( (GATT_CONNECT_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_DISCONNECT_IND:
        {
            GATT_DEBUG(("GATT_DISCONNECT_IND [%x]\n", ((GATT_DISCONNECT_IND_T*)message)->status));
            
            #if defined(GATT_SERVER_ENABLED)
            {
                server_handle_gatt_disconnect_ind( (GATT_DISCONNECT_IND_T*)message );
            }
            #elif defined(GATT_CLIENT_ENABLED)
            {
                client_handle_gatt_disconnect_ind( (GATT_DISCONNECT_IND_T*)message );
            }
            #endif
        }
        case GATT_EXCHANGE_MTU_IND:
        {
            GATT_DEBUG(("GATT_EXCHANGE_MTU_IND\n"));
            GattExchangeMtuResponse( ((GATT_EXCHANGE_MTU_IND_T*)message)->cid, 0);
        }
        break;
        case GATT_ACCESS_IND:
        {
            #ifdef GATT_SERVER_ENABLED
            {
                server_handle_gatt_access_ind( (GATT_ACCESS_IND_T*)message );
            }
            #endif
        }
        break;
        case GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_discover_all_primary_services_cfm( (GATT_DISCOVER_ALL_PRIMARY_SERVICES_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_DISCOVER_ALL_CHARACTERISTICS_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_discover_all_characteristics_cfm( (GATT_DISCOVER_ALL_CHARACTERISTICS_CFM_T*)message );
            }
            #endif
        }
        break;
        
        case GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_discover_all_characteristic_descriptors_cfm( (GATT_DISCOVER_ALL_CHARACTERISTIC_DESCRIPTORS_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_FIND_INCLUDED_SERVICES_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_find_included_services_cfm( (GATT_FIND_INCLUDED_SERVICES_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_READ_CHARACTERISTIC_VALUE_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_read_characteristic_value_cfm( (GATT_READ_CHARACTERISTIC_VALUE_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_read_long_characteristic_value_cfm( (GATT_READ_LONG_CHARACTERISTIC_VALUE_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_WRITE_WITHOUT_RESPONSE_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_write_without_response_cfm( (GATT_WRITE_WITHOUT_RESPONSE_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_WRITE_CHARACTERISTIC_VALUE_CFM:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_write_characteristic_value_cfm( (GATT_WRITE_CHARACTERISTIC_VALUE_CFM_T*)message );
            }
            #endif
        }
        break;
        case GATT_NOTIFICATION_IND:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_notification_ind( (GATT_NOTIFICATION_IND_T*)message );
            }
            #endif
        }
        break;
        case GATT_INDICATION_IND:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                client_handle_gatt_indication_ind( (GATT_INDICATION_IND_T*)message );
            }
            #endif
        }
        break;
        case GATT_INDICATION_CFM:
        {
            #ifdef GATT_SERVER_ENABLED
            {
                server_handle_gatt_indication_cfm( (GATT_INDICATION_CFM_T*)message );
            }
            #endif
        }
        break;
        
        /* This message should be returned when inquiring what the Local Name has been set to */
        case CL_DM_LOCAL_NAME_COMPLETE:
        {
            #ifdef GATT_SERVER_ENABLED
            {
                respond_gap_local_name_req( (CL_DM_LOCAL_NAME_COMPLETE_T*)message );
            }
            #endif
        }
        break;
        
        default:
        {
            GATT_DEBUG(("GATT: Unhandled MSG[%x]\n", id));
        }
    }
}


/******************************************************************************/
void disconnect_all_gatt_devices( void )
{
    #ifdef GATT_SERVER_ENABLED
    {
        disconnect_all_gatt_clients();
    }
    #endif
    
    #ifdef GATT_CLIENT_ENABLED
    {
        disconnect_all_gatt_servers();
    }
    #endif
}


#else /* GATT_DISABLED */

#include <csrtypes.h>
static const uint16 dummy_gatt = 0;

#endif /* GATT_DISABLED */

