/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    main.c        

DESCRIPTION
    This is main file for the application software for a sink device

NOTES

*/

/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_init.h"
#include "sink_auth.h"
#include "sink_scan.h"
#include "sink_slc.h" 
#include "sink_inquiry.h"
#include "sink_devicemanager.h"
#include "sink_link_policy.h"
#include "sink_indicators.h"
#include "sink_dut.h" 
#include "sink_pio.h" 
#include "sink_multipoint.h" 
#include "sink_led_manager.h"
#include "sink_buttonmanager.h"
#include "sink_configmanager.h"
#include "sink_events.h"
#include "sink_statemanager.h"
#include "sink_states.h"
#include "sink_powermanager.h"
#include "sink_callmanager.h"
#include "sink_csr_features.h"
#include "sink_usb.h"
#include "sink_display.h"
#include "sink_speech_recognition.h"
#include "sink_a2dp.h"
#include "sink_config.h"
#include "sink_audio_routing.h"
#include "sink_partymode.h"
#include "sink_leds.h"

#ifndef GATT_DISABLED
#include "sink_gatt.h"
#endif
#ifdef BLE_ENABLED
#include "sink_ble_advertising.h"
#ifdef GATT_CLIENT_ENABLED
#include "sink_ble_remote_control.h"
#endif
#endif
#ifdef ENABLE_IR_REMOTE
#include "sink_ir_remote_control.h"
#endif
#ifdef ENABLE_GAIA
#include "sink_gaia.h"
#include "gaia.h"
#endif
#ifdef ENABLE_PBAP
#include "sink_pbap.h"
#endif
#ifdef ENABLE_MAPC
#include "sink_mapc.h"
#endif
#ifdef ENABLE_AVRCP
#include "sink_avrcp.h"
#endif
#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif
#ifdef ENABLE_PEER
#include "sink_peer.h"
#endif

#include "sink_volume.h"
#include "sink_tones.h"
#include "sink_audio_prompts.h" 

#include "sink_audio.h"
#include "sink_at_commands.h"
#include "vm.h"

#ifdef TEST_HARNESS
#include "test_sink.h"
#include "vm2host_connection.h"
#include "vm2host_hfp.h"
#include "vm2host_a2dp.h"
#include "vm2host_avrcp.h"
#endif

#include <bdaddr.h>
#include <connection.h>
#include <panic.h>
#include <ps.h>
#include <pio.h>
#include <stdlib.h>
#include <stdio.h>
#include <stream.h>
#include <codec.h>
#include <boot.h>
#include <string.h>
#include <audio.h>
#include <sink.h>
#include <kalimba_standard_messages.h>
#include <audio_plugin_if.h>
#include <print.h>
#include <loader.h>
#include <pio_common.h>
#ifndef GATT_DISABLED
#include <gatt.h>
#endif

#ifdef ENABLE_FM
#include "sink_fm.h"
#include <fm_plugin_if.h>
#endif

#ifdef ENABLE_DISPLAY
#include <display.h>
#include <display_plugin_if.h>
#include <display_example_plugin.h>
#endif /* ENABLE_DISPLAY */

#ifdef DEBUG_MAIN
#define MAIN_DEBUG(x) DEBUG(x)
    #define TRUE_OR_FALSE(x)  ((x) ? 'T':'F')   
#else
    #define MAIN_DEBUG(x) 
#endif

#if defined ENABLE_PEER && defined PEER_TWS
static const uint16 tws_audio_routing[4] =
{
    (PEER_TWS_ROUTING_STEREO << 2) | (PEER_TWS_ROUTING_STEREO),  /* Master stereo, Slave stereo */
    (  PEER_TWS_ROUTING_LEFT << 2) | ( PEER_TWS_ROUTING_RIGHT),
    ( PEER_TWS_ROUTING_RIGHT << 2) | (  PEER_TWS_ROUTING_LEFT),
    (  PEER_TWS_ROUTING_DMIX << 2) | (  PEER_TWS_ROUTING_DMIX)
    
};
#endif

/* Single instance of the device state */
hsTaskData theSink;

static void handleHFPStatusCFM ( hfp_lib_status pStatus ) ;

extern void _init(void);
static void sinkInitCodecTask( void ) ;
static void storeCurrentSinkVolume(void);

/*************************************************************************
NAME    
    handleCLMessage
    
DESCRIPTION
    Function to handle the CL Lib messages - these are independent of state

RETURNS

*/
static void handleCLMessage ( Task task, MessageId id, Message message )
{
    MAIN_DEBUG(("CL = [%x]\n", id)) ;    
 
        /* Handle incoming message identified by its message ID */
    switch(id)
    {        
        case CL_INIT_CFM:
            MAIN_DEBUG(("CL_INIT_CFM [%d]\n" , ((CL_INIT_CFM_T*)message)->status ));
            if(((CL_INIT_CFM_T*)message)->status == success)
            {               
                /* Initialise the codec task */
                sinkInitCodecTask();

#if defined(GATT_SERVER_ENABLED) && defined(BLE_ENABLED)
                MAIN_DEBUG(("Setup CL for discoverable advertising\n"));
                ConnectionDmBleSetAdvertisingParamsReq(ble_adv_scan_ind, FALSE, 0, NULL);
#endif
                
#ifdef ENABLE_GAIA                
                /* Initialise Gaia with a concurrent connection limit of 1 */
                GaiaInit(task, 1);
#endif
            }
            else
            {
                Panic();
            }
        break;
        case CL_DM_WRITE_INQUIRY_MODE_CFM:
            /* Read the local name to put in our EIR data */
            ConnectionReadInquiryTx(&theSink.task);
        break;
        case CL_DM_READ_INQUIRY_TX_CFM:
            theSink.inquiry_tx = ((CL_DM_READ_INQUIRY_TX_CFM_T*)message)->tx_power;
            ConnectionReadLocalName(&theSink.task);
        break;
        case CL_DM_LOCAL_NAME_COMPLETE:
            MAIN_DEBUG(("CL_DM_LOCAL_NAME_COMPLETE\n"));
            /* Write EIR data and initialise the codec task */
            sinkWriteEirData((CL_DM_LOCAL_NAME_COMPLETE_T*)message);
#ifndef GATT_DISABLED
            /* Initialise any GATT services */
            initialise_gatt_for_device( ((CL_DM_LOCAL_NAME_COMPLETE_T*)message)->local_name, ((CL_DM_LOCAL_NAME_COMPLETE_T*)message)->size_local_name );
#endif
        break;
        case CL_SM_SEC_MODE_CONFIG_CFM:
            MAIN_DEBUG(("CL_SM_SEC_MODE_CONFIG_CFM\n"));
            /* Remember if debug keys are on or off */
            theSink.debug_keys_enabled = ((CL_SM_SEC_MODE_CONFIG_CFM_T*)message)->debug_keys;
        break;
        case CL_SM_PIN_CODE_IND:
            MAIN_DEBUG(("CL_SM_PIN_IND\n"));
            sinkHandlePinCodeInd((CL_SM_PIN_CODE_IND_T*) message);
        break;
        case CL_SM_USER_CONFIRMATION_REQ_IND:
            MAIN_DEBUG(("CL_SM_USER_CONFIRMATION_REQ_IND\n"));
            sinkHandleUserConfirmationInd((CL_SM_USER_CONFIRMATION_REQ_IND_T*) message);
        break;
        case CL_SM_USER_PASSKEY_REQ_IND:
            MAIN_DEBUG(("CL_SM_USER_PASSKEY_REQ_IND\n"));
            sinkHandleUserPasskeyInd((CL_SM_USER_PASSKEY_REQ_IND_T*) message);
        break;
        case CL_SM_USER_PASSKEY_NOTIFICATION_IND:
            MAIN_DEBUG(("CL_SM_USER_PASSKEY_NOTIFICATION_IND\n"));
            sinkHandleUserPasskeyNotificationInd((CL_SM_USER_PASSKEY_NOTIFICATION_IND_T*) message);
        break;
        case CL_SM_KEYPRESS_NOTIFICATION_IND:
        break;
        case CL_SM_REMOTE_IO_CAPABILITY_IND:
            MAIN_DEBUG(("CL_SM_IO_CAPABILITY_IND\n"));
            sinkHandleRemoteIoCapabilityInd((CL_SM_REMOTE_IO_CAPABILITY_IND_T*)message);
        break;
        case CL_SM_IO_CAPABILITY_REQ_IND:
            MAIN_DEBUG(("CL_SM_IO_CAPABILITY_REQ_IND\n"));
            sinkHandleIoCapabilityInd((CL_SM_IO_CAPABILITY_REQ_IND_T*) message);
        break;
        case CL_SM_AUTHORISE_IND:
            MAIN_DEBUG(("CL_SM_AUTHORISE_IND\n"));
            sinkHandleAuthoriseInd((CL_SM_AUTHORISE_IND_T*) message);
        break;            
        case CL_SM_AUTHENTICATE_CFM:
            MAIN_DEBUG(("CL_SM_AUTHENTICATE_CFM\n"));
            sinkHandleAuthenticateCfm((CL_SM_AUTHENTICATE_CFM_T*) message);
        break;           
#ifdef ENABLE_SUBWOOFER
        case CL_SM_GET_AUTH_DEVICE_CFM: /* This message should only be sent for subwoofer devices */
            MAIN_DEBUG(("CL_SM_GET_AUTH_DEVICE_CFM\n"));
            handleSubwooferGetAuthDevice((CL_SM_GET_AUTH_DEVICE_CFM_T*) message);
#endif
        break;
    
#ifdef ENABLE_PEER
        case CL_SM_GET_AUTH_DEVICE_CFM:
            MAIN_DEBUG(("CL_SM_GET_AUTH_DEVICE_CFM\n"));
            handleGetAuthDeviceCfm((CL_SM_GET_AUTH_DEVICE_CFM_T *)message);
        break;
        case CL_SM_ADD_AUTH_DEVICE_CFM:
            MAIN_DEBUG(("CL_SM_ADD_AUTH_DEVICE_CFM\n"));
            handleAddAuthDeviceCfm((CL_SM_ADD_AUTH_DEVICE_CFM_T *)message);
        break;
        /* SDP messges */
        case CL_SDP_OPEN_SEARCH_CFM:
            MAIN_DEBUG(("CL_SDP_OPEN_SEARCH_CFM\n"));
            handleSdpOpenCfm((CL_SDP_OPEN_SEARCH_CFM_T *) message);
        break;
        case CL_SDP_CLOSE_SEARCH_CFM:
            MAIN_DEBUG(("CL_SDP_CLOSE_SEARCH_CFM\n"));
            handleSdpCloseCfm((CL_SDP_CLOSE_SEARCH_CFM_T *) message);
        break;
        case CL_SDP_SERVICE_SEARCH_CFM:
            MAIN_DEBUG(("CL_SDP_SERVICE_SEARCH_CFM\n"));
            HandleSdpServiceSearchCfm ((CL_SDP_SERVICE_SEARCH_CFM_T*) message);
        break;
        case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM    :
            MAIN_DEBUG(("CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM\n"));
            HandleSdpServiceSearchAttributeCfm ((CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T*) message);
        break;
#endif
        case CL_DM_REMOTE_FEATURES_CFM:
            MAIN_DEBUG(("HS : Supported Features\n")) ;
        break ;
        case CL_DM_INQUIRE_RESULT:
            MAIN_DEBUG(("HS : Inquiry Result\n"));
            inquiryHandleResult((CL_DM_INQUIRE_RESULT_T*)message);
        break;
        case CL_SM_GET_ATTRIBUTE_CFM:
            MAIN_DEBUG(("HS : CL_SM_GET_ATTRIBUTE_CFM Vol:%d \n",((CL_SM_GET_ATTRIBUTE_CFM_T *)(message))->psdata[0]));
        break;
        case CL_SM_GET_INDEXED_ATTRIBUTE_CFM:
            MAIN_DEBUG(("HS: CL_SM_GET_INDEXED_ATTRIBUTE_CFM[%d]\n" , ((CL_SM_GET_INDEXED_ATTRIBUTE_CFM_T*)message)->status)) ;
        break ;    
        
        case CL_DM_LOCAL_BD_ADDR_CFM:
            DutHandleLocalAddr((CL_DM_LOCAL_BD_ADDR_CFM_T *)message);
        break ;
#if defined(ENABLE_MAPC) && !defined(ENABLE_PEER)
        case CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM:
            MAIN_DEBUG(("HS: CL_SM_GET_INDEXED_ATTRIBUTE_CFM[%d]\n" , ((CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T*)message)->status)) ;
            mapcHandleServiceSearchAttributeCfm( (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T*) message);
#endif
        break ;
        case CL_DM_ROLE_IND:
            linkPolicyHandleRoleInd((CL_DM_ROLE_IND_T *)message);
        break;
        case CL_DM_ROLE_CFM:
            linkPolicyHandleRoleCfm((CL_DM_ROLE_CFM_T *)message);
        break;

/* BLE Messages */
#ifdef BLE_ENABLED
        case CL_SM_BLE_IO_CAPABILITY_REQ_IND:
        {
            MAIN_DEBUG(("CL_SM_BLE_IO_CAPABILITY_REQ_IND\n"));
            #ifdef GATT_CLIENT_ENABLED
            {
                ConnectionSmBleIoCapabilityResponse( &((CL_SM_BLE_IO_CAPABILITY_REQ_IND_T*)message)->taddr, cl_sm_io_cap_no_input_no_output, KEY_DIST_RESPONDER_ENC_CENTRAL, FALSE, NULL);
            }
            #endif
            
            #ifdef GATT_SERVER_ENABLED
            {
                /* We requested to encrypt the link so need to distribute the IRK to the responder */
                ConnectionSmBleIoCapabilityResponse( &((CL_SM_BLE_IO_CAPABILITY_REQ_IND_T*)message)->taddr, cl_sm_io_cap_no_input_no_output, KEY_DIST_NONE, FALSE, NULL);
            }
            #endif
        }
        break;
        case CL_SM_BLE_REMOTE_IO_CAPABILITY_IND:
        {
            #ifdef DEBUG_MAIN
            {
                CL_SM_BLE_REMOTE_IO_CAPABILITY_IND_T * ind = (CL_SM_BLE_REMOTE_IO_CAPABILITY_IND_T*)message;
                MAIN_DEBUG(("CL_SM_BLE_REMOTE_IO_CAPABILITY_IND auth_reqs[%x] io_caps[%x]\n", ind->authentication_requirements, ind->io_capability));
            }
            #endif
        }
        break;
        case CL_DM_BLE_ADVERTISING_REPORT_IND:
        {
            #ifdef GATT_CLIENT_ENABLED
            {
                /* Handle an advertisment from a BLE HID Device */
                handle_ble_advertising_report( (CL_DM_BLE_ADVERTISING_REPORT_IND_T*)message );
            }
            #endif
        }
        break;
        case CL_DM_BLE_SET_ADVERTISING_DATA_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_SET_ADVERTISING_DATA_CFM\n"));
            #ifdef GATT_SERVER_ENABLED
            {
                handle_set_ble_ad_data_cfm( (CL_DM_BLE_SET_ADVERTISING_DATA_CFM_T*)message );
            }
            #endif
        }
        break;
        case CL_DM_BLE_SET_ADVERTISING_PARAMS_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_SET_ADVERTISING_PARAMS_CFM\n"));
        }
        break;
        case CL_DM_BLE_SECURITY_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_SECURITY_CFM [%x]\n", ((CL_DM_BLE_SECURITY_CFM_T*)message)->status ));
        }
        break;
        case CL_DM_BLE_SET_CONNECTION_PARAMETERS_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_SET_CONNECTION_PARAMETERS_CFM\n"));
        }
        break;
        case CL_DM_BLE_CONNECTION_PARAMETERS_UPDATE_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_CONNECTION_PARAMETERS_UPDATE_CFM\n"));
        }
        break;
        case CL_DM_BLE_SET_SCAN_PARAMETERS_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_SET_SCAN_PARAMETERS_CFM\n"));
        }
        break;
        case CL_DM_BLE_SET_SCAN_RESPONSE_DATA_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_SET_SCAN_RESPONSE_DATA_CFM\n"));
        }
        break;
        case CL_DM_BLE_READ_WHITE_LIST_SIZE_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_READ_WHITE_LIST_SIZE_CFM\n"));
        }
        break;
        case CL_DM_BLE_CLEAR_WHITE_LIST_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_CLEAR_WHITE_LIST_CFM\n"));
        }
        break;
        case CL_DM_BLE_ADD_DEVICE_TO_WHITE_LIST_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_ADD_DEVICE_TO_WHITE_LIST_CFM\n"));
        }
        break;
        case CL_DM_BLE_REMOVE_DEVICE_FROM_WHITE_LIST_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_REMOVE_DEVICE_FROM_WHITE_LIST_CFM\n"));
        }
        break;
        case CL_DM_BLE_CONFIGURE_LOCAL_ADDRESS_CFM:
        {
            MAIN_DEBUG(("CL_DM_BLE_CONFIGURE_LOCAL_ADDRESS_CFM\n"));
        }
        break;
        case CL_DM_BLE_ACCEPT_CONNECTION_PAR_UPDATE_IND:
        {
            CL_DM_BLE_ACCEPT_CONNECTION_PAR_UPDATE_IND_T * req = (CL_DM_BLE_ACCEPT_CONNECTION_PAR_UPDATE_IND_T*)message;
            bool accept = TRUE;         /* Accept or reject the parameter update; will be rejected if minimum latency requested is lower than minimum allowed */

            #ifdef GATT_CLIENT_ENABLED
            {
                /* BLE Role is master, can choose to accept or reject the parameter update */
                uint16 min_latency = 24;    /* Minimum allowed latency is 15ms, if requested latency is less than this then reject the parameter update request */
                
                /* Check the minimum latency requested is not too low: ensures that current BR profiles will have enough bandwidth */
                if (req->conn_interval_min < min_latency)
                {
                    MAIN_DEBUG(("CL_DM_BLE_ACCEPT_CONNECTION_PAR_UPDATE_IND - REJECT\n"));
                    accept = FALSE;
                }
                else
                {
                    MAIN_DEBUG(("CL_DM_BLE_ACCEPT_CONNECTION_PAR_UPDATE_IND - ACCEPT\n"));
                }
            }
            #else
            {
                /* BLE Role is slave; always accept the parameter update */
                accept = TRUE;
            }
            #endif
            
            /* Respond to the parameter update request */
            ConnectionDmBleAcceptConnectionParUpdateResponse(accept, &req->taddr, req->id, req->conn_interval_min, req->conn_interval_max, req->conn_latency, req->supervision_timeout);
        }
        break;
        case CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND:
        {
            MAIN_DEBUG(("CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND [%x]\n", ((CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND_T*)message)->status));
            
            #ifdef GATT_SERVER_ENABLED
            {
                /* If pairing failed, start advertising & prepare for new connection */
                if (  ((CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND_T*)message)->status != success )
                {
                    GattConnectRequest(&theSink.rundata->gatt.task, NULL, gatt_connection_ble_slave_undirected, FALSE); 
                }
            }
            #endif
            #ifdef GATT_CLIENT_ENABLED
            {
                /* Which client task should handle the pairing complete? */
                if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
                {
                    /* Ensure HOGP pairing mode is enabled before allowing to handle */
                    if (theSink.rundata->bleInputMonitor.pairing_mode)
                    {
                        handleBleRemotePairingComplete( (CL_SM_BLE_SIMPLE_PAIRING_COMPLETE_IND_T*)message );
                    }
                }
            }
            #endif
        }
        break;
#endif /* #ifdef BLE_ENABLED */
            

        case CL_SM_SET_TRUST_LEVEL_CFM:
            MAIN_DEBUG(("HS : CL_SM_SET_TRUST_LEVEL_CFM status %x\n",((CL_SM_SET_TRUST_LEVEL_CFM_T*)message)->status));
        break;
        case CL_DM_ACL_OPENED_IND:
            MAIN_DEBUG(("HS : ACL Opened\n"));
        break;
        case CL_DM_ACL_CLOSED_IND:
            MAIN_DEBUG(("HS : ACL Closed\n"));
#ifdef ENABLE_AVRCP
            if(theSink.features.avrcp_enabled)
            {                
                sinkAvrcpAclClosed(((CL_DM_ACL_CLOSED_IND_T *)message)->taddr.addr);    
            }
#endif  
        break;
            
            /*all unhandled connection lib messages end up here*/          
        default :
            MAIN_DEBUG(("Sink - Unhandled CL msg[%x]\n", id));
        break ;
    }
   
}

/*************************************************************************
NAME    
    handleUEMessage
    
DESCRIPTION
    handles messages from the User Events

RETURNS
    
*/
static void handleUEMessage  ( Task task, MessageId id, Message message )
{
    /* Event state control is done by the config - we will be in the right state for the message
    therefore messages need only be passed to the relative handlers unless configurable */
    sinkState lState = stateManagerGetState() ;
    
    /*if we do not want the event received to be indicated then set this to FALSE*/
    bool lIndicateEvent = TRUE ;
        
    /* Deal with user generated Event specific actions*/
    if ( id < EVENTS_LAST_EVENT)
    {   
            /*these are the events that are not user generated and can occur at any time*/
            /* If we have had an event then reset the timer - if it was the event then we will switch off anyway*/
            if (theSink.conf1->timeouts.AutoSwitchOffTime_s !=0)
            {
                /*MAIN_DEBUG(("HS: AUTOSent Ev[%x] Time[%d]\n",id , theSink.conf1->timeouts.AutoSwitchOffTime_s ));*/
                MessageCancelAll( task , EventSysAutoSwitchOff ) ;
                MessageSendLater( task , EventSysAutoSwitchOff , 0 , D_SEC(theSink.conf1->timeouts.AutoSwitchOffTime_s) ) ;                
            }
 
            /*cancel any missed call indicator on a user event (button press)*/
           MessageCancelAll(task , EventSysMissedCall ) ;
 
            /* check for led timeout/re-enable */

            LEDManagerCheckTimeoutState();
   
            /*  Swap the volume control messages if necessary  */
            if (((id == EventUsrVolumeUp) || (id == EventUsrVolumeDown)) && theSink.gVolButtonsInverted)
            {
                if (id == EventUsrVolumeUp)
                    id = EventUsrVolumeDown;
                
                else
                    id = EventUsrVolumeUp;
            }
            
#ifdef ENABLE_GAIA
            gaiaReportUserEvent(id);
#endif
    }
     
/*    MAIN_DEBUG (( "HS : UE[%x]\n", id )); */
     
    /* The configurable Events*/
    switch ( id )
    {   
        case (EventUsrDebugKeysToggle):
            MAIN_DEBUG(("HS: Toggle Debug Keys\n"));
            /* If the device has debug keys enabled then toggle on/off */
            ConnectionSmSecModeConfig(&theSink.task, cl_sm_wae_acl_none, !theSink.debug_keys_enabled, TRUE);
        break;
        case (EventUsrPowerOn):
        case (EventSysPowerOnPanic):
            MAIN_DEBUG(("HS: Power On\n" )) ;
            
            /* cancel any existing mute operations when powering up */
            theSink.sink_mute_status = FALSE;
                                 
            /* if this init occurs and in limbo wait for the display init */
            if (stateManagerGetState() == deviceLimbo)
            {                                          
                displaySetState(TRUE);                    
                displayShowText(DISPLAYSTR_HELLO,  strlen(DISPLAYSTR_HELLO), 2, DISPLAY_TEXT_SCROLL_SCROLL, 1000, 2000, FALSE, 10);
                displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * theSink.features.DefaultVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
#ifdef ENABLE_SUBWOOFER
                updateSwatVolume((theSink.features.DefaultVolume * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS);
#endif
                
                /* update battery display */
                displayUpdateBatteryLevel(powerManagerIsChargerConnected());
            }
            
          
                                        
            /*we have received the power on event- we have fully powered on*/
            stateManagerPowerOn();   

#ifdef ENABLE_FM      
            /*Initialise FM data structure*/
            theSink.conf2->sink_fm_data.fmRxOn = FALSE;
#endif /* ENABLE_FM */

            /* set flag to indicate just powered up and may use different led pattern for connectable state
               if configured, flag is cleared on first successful connection */
            theSink.powerup_no_connection = TRUE;
            
            /* If critical temperature immediately power off */
            if(powerManagerIsVthmCritical())
                MessageSend(&theSink.task, EventUsrPowerOff, 0);

            /* Take an initial battery reading (and power off if critical) */
            powerManagerReadVbat(battery_level_initial_reading);

            if(theSink.conf1->timeouts.EncryptionRefreshTimeout_m != 0)
                MessageSendLater(&theSink.task, EventSysRefreshEncryption, 0, D_MIN(theSink.conf1->timeouts.EncryptionRefreshTimeout_m));
            
            if ( theSink.features.DisablePowerOffAfterPowerOn )
            {
                theSink.PowerOffIsEnabled = FALSE ;
                MAIN_DEBUG(("DIS[%x]\n" , theSink.conf1->timeouts.DisablePowerOffAfterPowerOnTime_s  )) ;
                MessageSendLater ( &theSink.task , EventSysEnablePowerOff , 0 , D_SEC ( theSink.conf1->timeouts.DisablePowerOffAfterPowerOnTime_s ) ) ;
            }
            else
            {
                theSink.PowerOffIsEnabled = TRUE ;
            }

#ifdef ENABLE_SUBWOOFER
            /* check to see if there is a paired subwoofer device, if not kick off an inquiry scan */
            MessageSend(&theSink.task, EventSysSubwooferCheckPairing, 0);
#endif            
            
            /* kick off a timer to check the PS store fragmentation status */
            if(theSink.conf1->timeouts.DefragCheckTimer_s)
            {
                MessageSendLater(&theSink.task, EventSysCheckDefrag, 0, D_SEC(theSink.conf1->timeouts.DefragCheckTimer_s)); 
            }
            
        break ;          
        case (EventUsrPowerOff):
            MAIN_DEBUG(("HS: PowerOff - En[%c]\n" , ((theSink.PowerOffIsEnabled) ? 'T':'F') )) ;
#ifdef ENABLE_PEER
            {
                uint16 peerIndex = 0;
                /* If  a TWS peer device is connected, the TWS single device operation is enabled and the power off flag is not set,
                    send the power off command to the peer */
                if(a2dpGetPeerIndex(&peerIndex) &&(theSink.a2dp_link_data->peer_features[peerIndex] & (remote_features_tws_a2dp_sink|remote_features_tws_a2dp_source))
                    && theSink.features.TwsSingleDeviceOperation && !(theSink.a2dp_link_data->local_peer_status[peerIndex] & PEER_STATUS_POWER_OFF) )
                {
                    theSink.a2dp_link_data->local_peer_status[peerIndex] |= PEER_STATUS_POWER_OFF;
                    sinkAvrcpPowerOff();
                    lIndicateEvent = FALSE ;
                    break;
                }
            }
#endif 
            /* don't indicate event if already in limbo state */
            if(lState == deviceLimbo) lIndicateEvent = FALSE ;
                
            /* only power off if timer has expired or battery is low and the charger isn't connected or temperature high */            
            if ( theSink.PowerOffIsEnabled || (!powerManagerIsChargerConnected() && powerManagerIsVbatCritical()) || powerManagerIsVthmCritical())
            {
                /* store current volume levels for non bluetooth volumes */
                configManagerWriteSessionData () ;           

                /* Store DSP data */
                configManagerWriteDspData();

                stateManagerEnterLimboState();
                AuthResetConfirmationFlags();
                
                VolumeUpdateMuteStatus(FALSE);
                VolumeSetMicrophoneGain(hfp_invalid_link, VOLUME_MUTE_OFF);
                
                sinkClearQueueudEvent();
    
                if(theSink.conf1->timeouts.EncryptionRefreshTimeout_m != 0)
                    MessageCancelAll ( &theSink.task, EventSysRefreshEncryption) ;
                
                MessageCancelAll (&theSink.task, EventSysCheckDefrag);
                MessageCancelAll (&theSink.task, EventSysDefrag);
                
                MessageCancelAll (&theSink.task, EventSysPairingFail);
#ifdef ENABLE_AVRCP
                /* cancel any queued ff or rw requests */
                MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
                MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
#endif
#ifdef ENABLE_SPEECH_RECOGNITION
                /* if speech recognition is in tuning mode stop it */
                if(theSink.csr_speech_recognition_tuning_active)
                {
                    speechRecognitionStop();
                    theSink.csr_speech_recognition_tuning_active = FALSE;                   
                }
#endif
#ifdef ENABLE_FM
                if (theSink.conf2->sink_fm_data.fmRxOn)
                {               
                    MessageSend(&theSink.task, EventUsrFmRxOff, 0);                    
                }
#endif
                /* keep the display on if charging */
                if (powerManagerIsChargerConnected() && (stateManagerGetState() == deviceLimbo) )
                {
                    displaySetState(TRUE);
                    displayShowText(DISPLAYSTR_CHARGING,  strlen(DISPLAYSTR_CHARGING), 2, DISPLAY_TEXT_SCROLL_SCROLL, 1000, 2000, FALSE, 0);
                    displayUpdateVolume(0); 
                    displayUpdateBatteryLevel(TRUE);
                }          
                else
                {
                    displaySetState(FALSE);
                }
#ifdef ENABLE_SOUNDBAR
                /* set the active routed source back to none */
                audioSwitchToAudioSource(audio_source_none);    
#endif
#ifdef ENABLE_GAIA
                if (!theSink.features.GaiaRemainConnected)
                    gaiaDisconnect();
#endif
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
            
        
        break ;
        case (EventUsrInitateVoiceDial):
            MAIN_DEBUG(("HS: InitVoiceDial [%d]\n", theSink.VoiceRecognitionIsActive));            
                /*Toggle the voice dial behaviour depending on whether we are currently active*/
            if ( theSink.PowerOffIsEnabled )
            {
                
                if (theSink.VoiceRecognitionIsActive)
                {
                    sinkCancelVoiceDial(hfp_primary_link) ;
                    lIndicateEvent = FALSE ;
                    /* replumb any existing audio connections */                    
                    audioHandleRouting(audio_source_none);
                }
                else
                {         
                    sinkInitiateVoiceDial (hfp_primary_link) ;
                }            
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        break ;
        case (EventUsrInitateVoiceDial_AG2):
            MAIN_DEBUG(("HS: InitVoiceDial AG2[%d]\n", theSink.VoiceRecognitionIsActive));            
                /*Toggle the voice dial behaviour depending on whether we are currently active*/
            if ( theSink.PowerOffIsEnabled )
            {
                
                if (theSink.VoiceRecognitionIsActive)
                {
                    sinkCancelVoiceDial(hfp_secondary_link) ;                    
                    lIndicateEvent = FALSE ;
                    /* replumb any existing audio connections */                    
                    audioHandleRouting(audio_source_none);
                }
                else
                {                
                    sinkInitiateVoiceDial(hfp_secondary_link) ;
                }            
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        break ;
        case (EventUsrLastNumberRedial):
            MAIN_DEBUG(("HS: LNR\n" )) ;
            
            if ( theSink.PowerOffIsEnabled )
            {
                if (theSink.features.LNRCancelsVoiceDialIfActive)
                {
                    if ( theSink.VoiceRecognitionIsActive )
                    {
                        MessageSend(&theSink.task , EventUsrInitateVoiceDial , 0 ) ;
                        lIndicateEvent = FALSE ;
                    }
                    else
                    {
                        /* LNR on AG 1 */
                        sinkInitiateLNR(hfp_primary_link) ;
                    }
                }
                else
                {
                   /* LNR on AG 1 */
                    sinkInitiateLNR(hfp_primary_link) ;
                }
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        break ;   
        case (EventUsrLastNumberRedial_AG2):
            MAIN_DEBUG(("HS: LNR AG2\n" )) ;
            if ( theSink.PowerOffIsEnabled )
            {
                if (theSink.features.LNRCancelsVoiceDialIfActive)
                {
                    if ( theSink.VoiceRecognitionIsActive )
                    {
                        MessageSend(&theSink.task , EventUsrInitateVoiceDial , 0 ) ;
                        lIndicateEvent = FALSE ;
                    }
                    else
                    {
                        /* LNR on AG 2 */
                        sinkInitiateLNR(hfp_secondary_link) ;
                    }
                }
                else
                {
                   /* LNR on AG 2 */
                   sinkInitiateLNR(hfp_secondary_link) ;
                }
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        break ;  
        case (EventUsrAnswer):
            MAIN_DEBUG(("HS: Answer\n" )) ;
            /* don't indicate event if not in incoming call state as answer event is used
               for some of the multipoint three way calling operations which generate unwanted
               tones */
            if(stateManagerGetState() != deviceIncomingCallEstablish) lIndicateEvent = FALSE ;

            /* Call the HFP lib function, this will determine the AT cmd to send
               depending on whether the profile instance is HSP or HFP compliant. */ 
            sinkAnswerOrRejectCall( TRUE );      
        break ;   
        case (EventUsrReject):
            MAIN_DEBUG(("HS: Reject\n" )) ;
            /* Reject incoming call - only valid for instances of HFP */ 
            sinkAnswerOrRejectCall( FALSE );
        break ;
        case (EventUsrCancelEnd):
            MAIN_DEBUG(("HS: CancelEnd\n" )) ;
            /* Terminate the current ongoing call process */
            sinkHangUpCall();

        break ;
        case (EventUsrTransferToggle):
            MAIN_DEBUG(("HS: Transfer\n" )) ;
            sinkTransferToggle(id);
        break ;
        case EventSysCheckForAudioTransfer :
            MAIN_DEBUG(("HS: Check Aud Tx\n")) ;    
            sinkCheckForAudioTransfer();
            break ;
            
        case (EventUsrMuteToggle):
        {
            MAIN_DEBUG(("EventUsrMuteToggle")) ;
            VolumeToggleMute();
        }
        break ;
            
        case EventUsrMuteOn :
        {    
            MAIN_DEBUG(("EventUsrMuteOn")) ;
            VolumeUpdateMuteStatus(TRUE);
        }      
        break ;
        case EventUsrMuteOff:
        {
            MAIN_DEBUG(("EventUsrMuteOff\n")) ;
            VolumeUpdateMuteStatus(FALSE);
        }
        break;
        
        case (EventUsrVolumeUp):      
            MAIN_DEBUG(("EventUsrVolumeUp\n")) ;
            VolumeCheck(increase_volume);

            /* Check if the timer is enabled.*/
            if( theSink.conf1->timeouts.StoreCurrentSinkVolumeTimeout_s)
            {                
                /* Cancel and start again the timer*/
                MessageCancelAll( &theSink.task , EventSysVolumeChangeTimer) ;
                MessageSendLater(&theSink.task, EventSysVolumeChangeTimer, 0, D_SEC(theSink.conf1->timeouts.StoreCurrentSinkVolumeTimeout_s) );
            }            
            break;
            
        case (EventUsrVolumeDown):     
            MAIN_DEBUG(("EventUsrVolumeDown\n")) ;
            VolumeCheck(decrease_volume);

            /* Check if the timer is enabled.*/
            if( theSink.conf1->timeouts.StoreCurrentSinkVolumeTimeout_s)
            {  
                /* Cancel and start again the timer */
                MessageCancelAll( &theSink.task , EventSysVolumeChangeTimer) ;
                MessageSendLater(&theSink.task, EventSysVolumeChangeTimer, 0, D_SEC(theSink.conf1->timeouts.StoreCurrentSinkVolumeTimeout_s) );
            }
            break;

        case (EventSysVolumeChangeTimer):
            MAIN_DEBUG(("EventSysVolumeChangeTimer\n"));
            
            /* Check if the timer is enabled.*/
            if( theSink.conf1->timeouts.StoreCurrentSinkVolumeTimeout_s)
            {                     
                /* Store the Volume information of the currently streaming(either A2Dp or HFP) sink device into the PS Store. */
                storeCurrentSinkVolume();
                configManagerWriteSessionData();
            }
            break;
            
        case (EventSysEnterPairingEmptyPDL):        
        case (EventUsrEnterPairing):
            MAIN_DEBUG(("HS: EnterPair [%d]\n" , lState )) ;

            /*go into pairing mode*/ 
            if (( lState != deviceLimbo) && (lState != deviceConnDiscoverable ))
            {
                theSink.inquiry.session = inquiry_session_normal;
                stateManagerEnterConnDiscoverableState( TRUE );                
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        break ;
        case (EventSysPairingFail):
            /*we have failed to pair in the alloted time - return to the connectable state*/
            MAIN_DEBUG(("HS: Pairing Fail\n")) ;
            if (lState != deviceTestMode)
            {
                switch (theSink.features.PowerDownOnDiscoTimeout)
                {
                    case PAIRTIMEOUT_POWER_OFF:
                    {
#ifdef ENABLE_FM
                        if (!IsSinkFmRxOn())
#endif
                        {
                            MessageSend ( task , EventUsrPowerOff , 0) ;
                        }
                    }
                        break;
                    case PAIRTIMEOUT_POWER_OFF_IF_NO_PDL:
                        /* Power off if no entries in PDL list */
                        if (ConnectionTrustedDeviceListSize() == 0)
                        {
#ifdef ENABLE_FM
                            if (!IsSinkFmRxOn())
#endif
                            {
                                MessageSend ( task , EventUsrPowerOff , 0) ;
                            }
                        }
                        else
                        {
                            /* when not configured to stay disconverable at all times */                                
                            if(!theSink.features.RemainDiscoverableAtAllTimes)
                            {
                                /* enter connectable mode */
                                stateManagerEnterConnectableState(TRUE); 
                            }
#ifdef ENABLE_PEER
                            /* Attempt to establish connection with Peer */
                            peerConnectPeer();
#endif
                        }
                        break;
                    case PAIRTIMEOUT_CONNECTABLE:
                    default:
                        /* when not configured to stay disconverable at all times */                                
                        if(!theSink.features.RemainDiscoverableAtAllTimes)
                        {
                            /* enter connectable state */
                            stateManagerEnterConnectableState(TRUE);          
                        }
#ifdef ENABLE_PEER
                        /* Attempt to establish connection with Peer */
                        peerConnectPeer();
#endif
                        break;
                }
            }
            /* have attempted to connect following a power on and failed so clear the power up connection flag */                
            theSink.powerup_no_connection = FALSE;

        break ;                        
        case ( EventSysPairingSuccessful):
            MAIN_DEBUG(("HS: Pairing Successful\n")) ;
            if (lState == deviceConnDiscoverable)
            {
                stateManagerEnterConnectableState(FALSE);
#ifdef ENABLE_PEER
                /* Attempt to establish connection with Peer */
                peerConnectPeer();
#endif
            }
        break ;
        case ( EventUsrConfirmationAccept ):
            MAIN_DEBUG(("HS: Pairing Correct Res\n" )) ;
            sinkPairingAcceptRes();
        break;
        case ( EventUsrConfirmationReject ):
            MAIN_DEBUG(("HS: Pairing Reject Res\n" )) ;
            sinkPairingRejectRes();
        break;
        case ( EventUsrEstablishSLC ) :
                /* Make sure we're not using the Panic action */
                theSink.panic_reconnect = FALSE;
                /* Fall through */
        case ( EventSysEstablishSLCOnPanic ):
                            
#ifdef ENABLE_SUBWOOFER
            /* if performing a subwoofer inquiry scan then cancel the SLC connect request
               this will resume after the inquiry scan has completed */
            if(theSink.inquiry.action == rssi_subwoofer)
            {    
                lIndicateEvent = FALSE;
                break;
            }   
#endif                
            /* check we are not already connecting before starting */
            {
                DEBUG(("EventUsrEstablishSLC\n")) ;
                
                slcEstablishSLCRequest() ;
                
                /* don't indicate the event at first power up if the use different event at power on
                   feature bit is enabled, this enables the establish slc event to be used for the second manual
                   connection request */
                if(stateManagerGetState() == deviceConnectable)
                {
                    /* send message to do indicate a start of paging process when in connectable state */
                    MessageSend(&theSink.task, EventSysStartPagingInConnState ,0);  
                }   
            }  
        break ;
        case ( EventUsrRssiPair ):
            MAIN_DEBUG(("HS: RSSI Pair\n"));
            lIndicateEvent = inquiryPair( inquiry_session_normal, TRUE );
        break;
        case ( EventSysRssiResume ):
            MAIN_DEBUG(("HS: RSSI Resume\n"));
            inquiryResume();
        break;
        case ( EventSysRssiPairReminder ):
            MAIN_DEBUG(("HS: RSSI Pair Reminder\n"));
            if (stateManagerGetState() != deviceLimbo )
                MessageSendLater(&theSink.task, EventSysRssiPairReminder, 0, D_SEC(INQUIRY_REMINDER_TIMEOUT_SECS));
            else
                lIndicateEvent = FALSE;

        break;
        case ( EventSysRssiPairTimeout ):
            MAIN_DEBUG(("HS: RSSI Pair Timeout\n"));
            inquiryTimeout();
        break;
        case ( EventSysRefreshEncryption ):
            MAIN_DEBUG(("HS: Refresh Encryption\n"));
            {
                uint8 k;
                Sink sink;
                Sink audioSink;
                /* For each profile */
                for(k=0;k<MAX_PROFILES;k++)
                {
                    MAIN_DEBUG(("Profile %d: ",k));
                    /* If profile is connected */
                    if((HfpLinkGetSlcSink((k + 1), &sink))&&(sink))
                    {
                        /* If profile has no valid SCO sink associated with it */
                        HfpLinkGetAudioSink((k + hfp_primary_link), &audioSink);
                        if(!SinkIsValid(audioSink))
                        {
                            MAIN_DEBUG(("Key Refreshed\n"));
                            /* Refresh the encryption key */
                            ConnectionSmEncryptionKeyRefreshSink(sink);
                        }
#ifdef DEBUG_MAIN
                        else
                        {
                            MAIN_DEBUG(("Key Not Refreshed, SCO Active\n"));
                        }
                    }
                    else
                    {
                        MAIN_DEBUG(("Key Not Refreshed, SLC Not Active\n"));
#endif
                    }
                }
                MessageSendLater(&theSink.task, EventSysRefreshEncryption, 0, D_MIN(theSink.conf1->timeouts.EncryptionRefreshTimeout_m));
            }
        break;
        
        /* 60 second timer has triggered to disable connectable mode in multipoint
            connection mode */
        case ( EventSysConnectableTimeout ) :
#ifdef ENABLE_SUBWOOFER     
            if(!SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id))
            {
                MAIN_DEBUG(("SM: disable Connectable Cancelled due to lack of subwoofer\n" ));
                break;
            }        
#endif        
#ifdef ENABLE_PARTYMODE
            /* leave headset connectable when using party mode */
            if(!(theSink.PartyModeEnabled)&&(theSink.features.PartyMode))
#endif
            {
                /* only disable connectable mode if at least one hfp instance is connected */
                if(deviceManagerNumConnectedDevs())
                {
                    MAIN_DEBUG(("SM: disable Connectable \n" ));
                    /* disable connectability */
                    sinkDisableConnectable();
                }
            }
        break;
        
        case ( EventSysLEDEventComplete ) :
            /*the message is a ptr to the event we have completed*/
            MAIN_DEBUG(("HS : LEDEvCmp[%x]\n" ,  (( LMEndMessage_t *)message)->Event  )) ;
            
            switch ( (( LMEndMessage_t *)message)->Event )
            {
                case (EventUsrResetPairedDeviceList) :
                {      /*then the reset has been completed*/
                    MessageSend(&theSink.task , EventSysResetComplete , 0 ) ;
   
                        /*power cycle if required*/
                    if ((theSink.features.PowerOffAfterPDLReset )&&
                        (stateManagerGetState() > deviceLimbo )) 
                    {
                        MAIN_DEBUG(("HS: Reboot After Reset\n")) ;
#ifdef ENABLE_FM
                        if (!IsSinkFmRxOn())
#endif
                        {
                        MessageSend ( &theSink.task , EventUsrPowerOff , 0 ) ;
                        }
                    }
                }
                break ;            
                
                case EventUsrPowerOff:
                {
                    /* Determine if a reset is required because the PS needs defragmentation */                   
                    if(configManagerDefragCheck())
                    {
                        MAIN_DEBUG(("DEFRAG PS & Reset\n"));
                        /* a reset is required to defragment the PS Store */
                        configManagerDefrag(TRUE);
                    }        
                    
                    /*allows a reset of the device for those designs which keep the chip permanently powered on*/
                    if (theSink.features.ResetAfterPowerOffComplete )
                    {
                        MAIN_DEBUG(("Reset\n"));
                        /* Reboot always - set the same boot mode; this triggers the target to reboot.*/
                        BootSetMode(BootGetMode());
                    }

                    if(powerManagerIsVthmCritical())
                        stateManagerUpdateLimboState();
                }
                break ;
                
                default: 
                break ;
            }
            
            if (theSink.features.QueueLEDEvents )
            {
                    /*if there is a queueud event*/
                if (LedManagerQueuedEvent())
                {
                    MAIN_DEBUG(("HS : Play Q'd Ev [%x]\n", LedManagerQueuedEvent()));
                    LedManagerIndicateQueuedEvent();
                }
                else
                {
                    /* restart state indication */
                    LEDManagerIndicateState ( stateManagerGetState () ) ;
                }
            }
            else
                LEDManagerIndicateState ( stateManagerGetState () ) ;
                
        break ;   
        case (EventSysAutoSwitchOff):
            MAIN_DEBUG(("HS: Auto S Off[%d] sec elapsed\n" , theSink.conf1->timeouts.AutoSwitchOffTime_s )) ;
            switch ( lState )
            {   
                case deviceLimbo:
                case deviceConnectable:
                case deviceConnDiscoverable:
                    if ( (!usbIsAttached())
#ifdef ENABLE_FM
                         || (!IsSinkFmRxOn())
#endif
                        )
                        {
                        MessageSend (task, EventUsrPowerOff , 0);
                        }
                    break;
                case deviceConnected:
                    if(deviceManagerNumConnectedDevs() == deviceManagerNumConnectedPeerDevs())
                    {   /* Only connected to peer devices, so allow auto-switchoff to occur */
#ifdef ENABLE_FM
                        if (!IsSinkFmRxOn())
#endif

#ifdef ENABLE_PEER
                        /* Before Powering off make sure that there is no Audio source connected to the remote peer*/
                        if(theSink.remote_peer_audio_conn_status == 0)
#endif
                        {
                        	MessageSend (task, EventUsrPowerOff , 0);
                    	}
                    }
                    break;
                case deviceOutgoingCallEstablish:   
                case deviceIncomingCallEstablish:   
                case deviceActiveCallSCO:            
                case deviceActiveCallNoSCO:             
                case deviceTestMode:
                    break ;
                default:
                    MAIN_DEBUG(("HS : UE ?s [%d]\n", lState));
                    break ;
            }
        break;
        case (EventUsrChargerConnected):
        {
            MAIN_DEBUG(("HS: Charger Connected\n"));
            powerManagerChargerConnected();
            if ( lState == deviceLimbo )
            { 
                stateManagerUpdateLimboState();
            }
            
            /* indicate battery charging on the display */
            displayUpdateBatteryLevel(TRUE);  
        }
        break;
        case (EventUsrChargerDisconnected):
        {
            MAIN_DEBUG(("HS: Charger Disconnected\n"));
            powerManagerChargerDisconnected();
 
            /* if in limbo state, schedule a power off event */
            if (lState == deviceLimbo )
            {
                /* cancel existing limbo timeout and rescheduled another limbo timeout */
                MessageCancelAll ( &theSink.task , EventSysLimboTimeout ) ;
                MessageSendLater ( &theSink.task , EventSysLimboTimeout , 0 , D_SEC(theSink.conf1->timeouts.LimboTimeout_s) ) ;

                /* turn off the display if in limbo and no longer charging */
                displaySetState(FALSE);
            }            
            else
            {
                /* update battery display */
                displayUpdateBatteryLevel(FALSE); 
            }
        }
        break;
        case (EventUsrResetPairedDeviceList):
            {
                MAIN_DEBUG(("HS: --Reset PDL--")) ;                
                if ( stateManagerIsConnected () )
                {
                   /*disconnect any connected HFP profiles*/
                   sinkDisconnectAllSlc();
                   /*disconnect any connected A2DP/AVRCP profiles*/
                   disconnectAllA2dpAvrcp(TRUE);
                }                
#ifdef ENABLE_SOUNDBAR
#ifdef ENABLE_SUBWOOFER
                /* Also delete the subwoofers Bluetooth address; don't need to delete the link key as deviceManagerRemoveAllDevices() will do this */
                deleteSubwooferPairing(FALSE);
#endif
#endif /* ENABLE_SOUNDBAR */

#ifndef GATT_DISABLED
                 disconnect_all_gatt_devices();
#endif
                deviceManagerRemoveAllDevices();
#ifdef ENABLE_PEER
                /* Ensure permanently paired Peer device is placed back into PDL */
                AuthInitPermanentPairing();
#endif
                
                if(INQUIRY_ON_PDL_RESET)
                    MessageSend(&theSink.task, EventUsrRssiPair, 0);
            }
        break ;
        case ( EventSysLimboTimeout ):
            {
                /*we have received a power on timeout - shutdown*/
                MAIN_DEBUG(("HS: EvLimbo TIMEOUT\n")) ;
                if (lState != deviceTestMode)
                {
                    stateManagerUpdateLimboState();
                }
            }    
        break ;
        case EventSysSLCDisconnected: 
                MAIN_DEBUG(("HS: EvSLCDisconnect\n")) ;
            {
                theSink.VoiceRecognitionIsActive = FALSE ;
                MessageCancelAll ( &theSink.task , EventSysNetworkOrServiceNotPresent ) ;                
            }
        break ;
        case (EventSysLinkLoss):
            MAIN_DEBUG(("HS: Link Loss\n")) ;
            {
                /* should the device have been powered off prior to a linkloss event being
                   generated, this can happen if a link loss has occurred within 5 seconds
                   of power off, ensure the device does not attempt to reconnet from limbo mode */
                if(stateManagerGetState()== deviceLimbo)
                    lIndicateEvent = FALSE;

                /* If not using HFP, reschedule reminder */
                if((!theSink.hfp_profiles) && (theSink.linkLossReminderTime != 0))
                    MessageSendLater(&theSink.task,  EventSysLinkLoss, 0, D_SEC(theSink.linkLossReminderTime));
            }
        break ;
        case (EventSysMuteReminder) :        
            MAIN_DEBUG(("HS: Mute Remind\n")) ;
            /*arrange the next mute reminder tone*/
            MessageSendLater( &theSink.task , EventSysMuteReminder , 0 ,D_SEC(theSink.conf1->timeouts.MuteRemindTime_s ) )  ;            

            /* only play the mute reminder tone if AG currently having its audio routed is in mute state */ 
            if(!VolumePlayMuteToneQuery())
                lIndicateEvent = FALSE;
        break;

        case EventUsrBatteryLevelRequest:
          MAIN_DEBUG(("EventUsrBatteryLevelRequest\n")) ;
          powerManagerReadVbat(battery_level_user);
        break;

        case EventSysBatteryCritical:
            MAIN_DEBUG(("HS: EventSysBatteryCritical\n")) ;
        break;

        case EventSysBatteryLow:
            MAIN_DEBUG(("HS: EventSysBatteryLow\n")) ;
        break; 
        
        case EventSysGasGauge0 :
        case EventSysGasGauge1 :
        case EventSysGasGauge2 :
        case EventSysGasGauge3 :
            MAIN_DEBUG(("HS: EventSysGasGauge%d\n", id - EventSysGasGauge0)) ;
        break ;

        case EventSysBatteryOk:
            MAIN_DEBUG(("HS: EventSysBatteryOk\n")) ;
        break;   

        case EventSysChargeInProgress:
            MAIN_DEBUG(("HS: EventSysChargeInProgress\n")) ;
        break;

        case EventSysChargeComplete:  
            MAIN_DEBUG(("HS: EventSysChargeComplete\n")) ;
        break;

        case EventSysChargeDisabled:
            MAIN_DEBUG(("HS: EventSysChargeDisabled\n")) ;            
        break;

        case EventUsrEnterDUTState :
        {
            MAIN_DEBUG(("EnterDUTState \n")) ;
            stateManagerEnterTestModeState();                
        }
        break;        
        case EventUsrEnterDutMode :
        {
            MAIN_DEBUG(("Enter DUT Mode \n")) ;            
            if (lState !=deviceTestMode)
            {
                MessageSend( task , EventUsrEnterDUTState, 0 ) ;
            }
            enterDutMode () ;               
        }
        break;        
        case EventUsrEnterTXContTestMode :
        {
            MAIN_DEBUG(("Enter TX Cont \n")) ;        
            if (lState !=deviceTestMode)
            {
                MessageSend( task , EventUsrEnterDUTState , 0 ) ;
            }            
            enterTxContinuousTestMode() ;
        }
        break ;     
        case EventUsrVolumeOrientationNormal:
                theSink.gVolButtonsInverted = FALSE ;               
                MAIN_DEBUG(("HS: VOL ORIENT NORMAL [%d]\n", theSink.gVolButtonsInverted)) ;
                    /*write this to the PSKEY*/                
                /* also include the led disable state as well as orientation, write this to the PSKEY*/ 
                /* also include the selected AP language  */
                configManagerWriteSessionData () ;                          
        break;
        case EventUsrVolumeOrientationInvert:       
               theSink.gVolButtonsInverted = TRUE ;
               MAIN_DEBUG(("HS: VOL ORIENT INVERT[%d]\n", theSink.gVolButtonsInverted)) ;               
               /* also include the led disable state as well as orientation, write this to the PSKEY*/                
               /* also include the selected AP language  */
               configManagerWriteSessionData () ;           
        break;        
        case EventUsrVolumeToggle:                
                theSink.gVolButtonsInverted ^=1 ;    
                MAIN_DEBUG(("HS: Toggle Volume Orientation[%d]\n", theSink.gVolButtonsInverted)) ;                
        break ;        
        case EventSysNetworkOrServiceNotPresent:
            {       /*only bother to repeat this indication if it is not 0*/
                if ( theSink.conf1->timeouts.NetworkServiceIndicatorRepeatTime_s )
                {       /*make sure only ever one in the system*/
                    MessageCancelAll( task , EventSysNetworkOrServiceNotPresent) ;
                    MessageSendLater  ( task , 
                                        EventSysNetworkOrServiceNotPresent ,
                                        0 , 
                                        D_SEC(theSink.conf1->timeouts.NetworkServiceIndicatorRepeatTime_s) ) ;
                }                                    
                MAIN_DEBUG(("HS: NO NETWORK [%d]\n", theSink.conf1->timeouts.NetworkServiceIndicatorRepeatTime_s )) ;
            }                                
        break ;
        case EventSysNetworkOrServicePresent:
            {
                MessageCancelAll ( task , EventSysNetworkOrServiceNotPresent ) ;                
                MAIN_DEBUG(("HS: YES NETWORK\n")) ;
            }   
        break ;
        case EventUsrLedsOnOffToggle  :   
            MAIN_DEBUG(("HS: Toggle EN_DIS LEDS ")) ;
            MAIN_DEBUG(("HS: Tog Was[%c]\n" , theSink.theLEDTask->gLEDSEnabled ? 'T' : 'F')) ;
            
            LedManagerToggleLEDS();
            MAIN_DEBUG(("HS: Tog Now[%c]\n" , theSink.theLEDTask->gLEDSEnabled ? 'T' : 'F')) ;            
       
            break ;        
        case EventUsrLedsOn:
            MAIN_DEBUG(("HS: Enable LEDS\n")) ;
            LedManagerEnableLEDS ( ) ;
                /* also include the led disable state as well as orientation, write this to the PSKEY*/                
            configManagerWriteSessionData ( ) ;             
            break ;
        case EventUsrLedsOff:
            MAIN_DEBUG(("HS: Disable LEDS\n")) ;            
            LedManagerDisableLEDS ( ) ;
            
                /* also include the led disable state as well as orientation, write this to the PSKEY*/                
            configManagerWriteSessionData ( ) ;            
            break ;
        case EventSysCancelLedIndication:
            MAIN_DEBUG(("HS: Disable LED indication\n")) ;        
            LedManagerResetLEDIndications ( ) ;
            break ;
        case EventSysCallAnswered:
            MAIN_DEBUG(("HS: EventSysCallAnswered\n")) ;
        break;
        case EventSysSLCConnected:
        case EventSysSLCConnectedAfterPowerOn:
            
            MAIN_DEBUG(("HS: EventSysSLCConnected\n")) ;
            /*if there is a queued event - we might want to know*/                
            sinkRecallQueuedEvent();
        break;            
        case EventSysPrimaryDeviceConnected:
        case EventSysSecondaryDeviceConnected:
            /*used for indication purposes only*/
            MAIN_DEBUG(("HS:Device Connected [%c]\n " , (id - EventSysPrimaryDeviceConnected)? 'S' : 'P'  )); 
        break;
        case EventSysPrimaryDeviceDisconnected:
            /*used for indication purposes only*/
            MAIN_DEBUG(("HS:Device Disconnected [%c]\n " , (id - EventSysPrimaryDeviceDisconnected)? 'S' : 'P'  )); 
        break;
        case EventSysSecondaryDeviceDisconnected:
            /*used for indication purposes only*/
            MAIN_DEBUG(("HS:Device Disconnected [%c]\n " , (id - EventSysPrimaryDeviceDisconnected)? 'S' : 'P'  )); 
        break;        
        case EventSysVLongTimer:
        case EventSysLongTimer:
           if (lState == deviceLimbo)
           {
               lIndicateEvent = FALSE ;
           }
        break ;
            /*these events have no required action directly associated with them  */
             /*they are received here so that LED patterns and Tones can be assigned*/
        case EventSysSCOLinkOpen :        
            MAIN_DEBUG(("EventSysSCOLinkOpen\n")) ;
        break ;
        case EventSysSCOLinkClose:
            MAIN_DEBUG(("EventSysSCOLinkClose\n")) ;
        break ;
        case EventSysEndOfCall :        
            MAIN_DEBUG(("EventSysEndOfCall\n")) ;
#ifdef ENABLE_DISPLAY
            displayShowSimpleText(DISPLAYSTR_CLEAR,1);
            displayShowSimpleText(DISPLAYSTR_CLEAR,2);
#endif            
        break;    
        case EventSysResetComplete:        
            MAIN_DEBUG(("EventSysResetComplete\n")) ;
        break ;
        case EventSysError:        
            MAIN_DEBUG(("EventSysError\n")) ;
        break;
        case EventSysReconnectFailed:        
            MAIN_DEBUG(("EventSysReconnectFailed\n")) ;
        break;
        
#ifdef THREE_WAY_CALLING        
        case EventUsrThreeWayReleaseAllHeld:       
            MAIN_DEBUG(("HS3 : RELEASE ALL\n"));          
            /* release the held call */
            MpReleaseAllHeld();
        break;
        case EventUsrThreeWayAcceptWaitingReleaseActive:    
            MAIN_DEBUG(("HS3 : ACCEPT & RELEASE\n"));
            MpAcceptWaitingReleaseActive();
        break ;
        case EventUsrThreeWayAcceptWaitingHoldActive  :
            MAIN_DEBUG(("HS3 : ACCEPT & HOLD\n"));
            /* three way calling not available in multipoint usage */
            MpAcceptWaitingHoldActive();
        break ;
        case EventUsrThreeWayAddHeldTo3Way  :
            MAIN_DEBUG(("HS3 : ADD HELD to 3WAY\n"));
            /* check to see if a conference call can be created, more than one call must be on the same AG */            
            MpHandleConferenceCall(TRUE);
        break ;
        case EventUsrThreeWayConnect2Disconnect:  
            MAIN_DEBUG(("HS3 : EXPLICIT TRANSFER\n"));
            /* check to see if a conference call can be created, more than one call must be on the same AG */            
            MpHandleConferenceCall(FALSE);
        break ;
#endif      
        case (EventSysEnablePowerOff):
        {
            MAIN_DEBUG(("HS: EventSysEnablePowerOff \n")) ;
            theSink.PowerOffIsEnabled = TRUE ;
        }
        break;        
        case EventUsrPlaceIncomingCallOnHold:
            sinkPlaceIncomingCallOnHold();
        break ;
        
        case EventUsrAcceptHeldIncomingCall:
            sinkAcceptHeldIncomingCall();
        break ;
        case EventUsrRejectHeldIncomingCall:
            sinkRejectHeldIncomingCall();
        break;
        
        case EventUsrEnterDFUMode:       
        {
            MAIN_DEBUG(("EventUsrEnterDFUMode\n")) ;
            BootSetMode(BOOTMODE_DFU);
        }
        break;

        case EventUsrEnterServiceMode:
        {
            MAIN_DEBUG(("Enter Service Mode \n")) ;            

            enterServiceMode();
        }
        break ;
        case EventSysServiceModeEntered:
        {
            MAIN_DEBUG(("Service Mode!!!\n")) ; 
        }
        break;

        case EventSysAudioMessage1:
        case EventSysAudioMessage2:
        case EventSysAudioMessage3:
        case EventSysAudioMessage4:
        {
            if (theSink.routed_audio)
            {
                uint16 * lParam = mallocPanic( sizeof(uint16)) ;
                *lParam = (id -  EventSysAudioMessage1) ; /*0,1,2,3*/
                if(!AudioSetMode ( AUDIO_MODE_CONNECTED , (void *) lParam) )
                    freePanic(lParam);
            }
        }
        break ;
        
        case EventUsrUpdateStoredNumber:
            sinkUpdateStoredNumber();
        break;
        
        case EventUsrDialStoredNumber:
            MAIN_DEBUG(("EventUsrDialStoredNumber\n"));
            sinkDialStoredNumber();
        
        break;
        case EventUsrRestoreDefaults:
            MAIN_DEBUG(("EventUsrRestoreDefaults\n"));
            configManagerRestoreDefaults();
                
        break;
        
        case EventSysTone1:
        case EventSysTone2:
            MAIN_DEBUG(("HS: EventTone[%d]\n" , (id - EventSysTone1 + 1) )) ;
        break;
        
        case EventUsrSelectAudioPromptLanguageMode:
            if(theSink.audio_prompts_enabled) 
            {
                MAIN_DEBUG(("EventUsrSelectAudioPromptLanguageMode"));
                AudioPromptSelectLanguage();
            }
            else
            {
                lIndicateEvent = FALSE ;
            } 
        break;
        
        case EventSysStoreAudioPromptLanguage:
            if(theSink.audio_prompts_enabled) 
            {
                /* Store Prompt language in PS */
                configManagerWriteSessionData () ;
            }
        break;

        /* enable multipoint functionality */
        case EventUsrMultipointOn:
            MAIN_DEBUG(("EventUsrMultipointOn\n"));
            /* enable multipoint operation */
            configManagerEnableMultipoint(TRUE);
            /* and store in PS for reading at next power up */
            configManagerWriteSessionData () ;
        break;
        
        /* disable multipoint functionality */
        case EventUsrMultipointOff:
            MAIN_DEBUG(("EventUsrMultipointOff\n"));
            /* disable multipoint operation */
            configManagerEnableMultipoint(FALSE);
            /* and store in PS for reading at next power up */
            configManagerWriteSessionData () ;           
        break;
        
        /* disabled leds have been re-enabled by means of a button press or a specific event */
        case EventSysResetLEDTimeout:
            MAIN_DEBUG(("EventSysResetLEDTimeout\n"));
            LEDManagerIndicateState ( lState ) ;     
            theSink.theLEDTask->gLEDSStateTimeout = FALSE ;               
        break;
        /* starting paging whilst in connectable state */
        case EventSysStartPagingInConnState:
            MAIN_DEBUG(("EventSysStartPagingInConnState\n"));
            /* set bit to indicate paging status */
            theSink.paging_in_progress = TRUE;
        break;
        
        /* paging stopped whilst in connectable state */
        case EventSysStopPagingInConnState:
            MAIN_DEBUG(("EventSysStartPagingInConnState\n"));
            /* set bit to indicate paging status */
            theSink.paging_in_progress = FALSE;
        break;
        
        /* continue the slc connection procedure, will attempt connection
           to next available device */
        case EventSysContinueSlcConnectRequest:
            /* don't continue connecting if in pairing mode */
            if(stateManagerGetState() != deviceConnDiscoverable)
            {
                MAIN_DEBUG(("EventSysContinueSlcConnectRequest\n"));
                /* attempt next connection */
                slcContinueEstablishSLCRequest();
            }
        break;
        
        /* indication of call waiting when using two AG's in multipoint mode */
        case EventSysMultipointCallWaiting:
            MAIN_DEBUG(("EventSysMultipointCallWaiting\n"));
        break;
                   
        /* kick off a check the role of the device and make changes if appropriate by requesting a role indication */
        case EventSysCheckRole:
            linkPolicyCheckRoles();
        break;

        case EventSysMissedCall:
        {
            if(theSink.conf1->timeouts.MissedCallIndicateTime_s != 0)
            { 
                MessageCancelAll(task , EventSysMissedCall ) ;
                     
                theSink.MissedCallIndicated -= 1;               
                if(theSink.MissedCallIndicated != 0)
                {
                    MessageSendLater( &theSink.task , EventSysMissedCall , 0 , D_SEC(theSink.conf1->timeouts.MissedCallIndicateTime_s) ) ;
                }
            }   
        }
        break;
      
#ifdef ENABLE_PBAP                  
        case EventUsrPbapDialMch:
        {         
            /* pbap dial from missed call history */
            MAIN_DEBUG(("EventUsrPbapDialMch\n"));  
            
            if ( theSink.PowerOffIsEnabled )
            {
                /* If voice dial is active, cancel the voice dial if the feature bit is set */
                if (theSink.features.LNRCancelsVoiceDialIfActive   && 
                    theSink.VoiceRecognitionIsActive)
                {
                    MessageSend(&theSink.task , EventUsrInitateVoiceDial , 0 ) ;
                    lIndicateEvent = FALSE ;
                }
                else
                {                   
                    pbapDialPhoneBook(pbap_mch);
                }
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        }
        break;      
        
        case EventUsrPbapDialIch:
        {
            /* pbap dial from incoming call history */
            MAIN_DEBUG(("EventUsrPbapDialIch\n"));
            
            if ( theSink.PowerOffIsEnabled )
            {
                /* If voice dial is active, cancel the voice dial if the feature bit is set */
                if (theSink.features.LNRCancelsVoiceDialIfActive   && 
                    theSink.VoiceRecognitionIsActive)
                {
                    MessageSend(&theSink.task , EventUsrInitateVoiceDial , 0 ) ;
                    lIndicateEvent = FALSE ;
                }
                else
                {                   
                    pbapDialPhoneBook(pbap_ich);
                }
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        }
        break;
        
        case EventSysEstablishPbap:
        {
            MAIN_DEBUG(("EventSysEstablishPbap\n"));
            
            /* Connect to the primary and secondary hfp link devices */
            theSink.pbapc_data.pbap_command = pbapc_action_idle;
             
            pbapConnect( hfp_primary_link );
            pbapConnect( hfp_secondary_link );
        }
        break;
            
        case EventUsrPbapSetPhonebook:
        {
            MAIN_DEBUG(("EventUsrPbapSetPhonebook, active pb is [%d]\n", theSink.pbapc_data.pbap_active_pb));

            theSink.pbapc_data.PbapBrowseEntryIndex = 0;
            theSink.pbapc_data.pbap_command = pbapc_setting_phonebook;
            
            if(theSink.pbapc_data.pbap_active_link == pbapc_invalid_link)
            {
                pbapConnect( hfp_primary_link );
            }
            else
            {
                /* Set the link to active state */
                linkPolicySetLinkinActiveMode(PbapcGetSink(theSink.pbapc_data.pbap_active_link));

                PbapcSetPhonebookRequest(theSink.pbapc_data.pbap_active_link, theSink.pbapc_data.pbap_phone_repository, theSink.pbapc_data.pbap_active_pb);
            }
            
            lIndicateEvent = FALSE ;
        }
        break;
        
        case EventUsrPbapBrowseEntry:
        {
            MAIN_DEBUG(("EventUsrPbapBrowseEntry\n"));

            if(theSink.pbapc_data.pbap_command == pbapc_action_idle)
            {
                /* If Pbap profile does not connected, connect it first */
                if(theSink.pbapc_data.pbap_active_link == pbapc_invalid_link)
                {
                    pbapConnect( hfp_primary_link );
                    theSink.pbapc_data.pbap_browsing_start_flag = 1;
                }
                else
                {
                    /* Set the link to active state */
                    linkPolicySetLinkinActiveMode(PbapcGetSink(theSink.pbapc_data.pbap_active_link));
                    
                    if(theSink.pbapc_data.pbap_browsing_start_flag == 0)
                    {
                        theSink.pbapc_data.pbap_browsing_start_flag = 1;
                        PbapcSetPhonebookRequest(theSink.pbapc_data.pbap_active_link, theSink.pbapc_data.pbap_phone_repository, theSink.pbapc_data.pbap_active_pb);
                    }
                    else
                    {
                        MessageSend ( &theSink.task , PBAPC_APP_PULL_VCARD_ENTRY , 0 ) ;
                    }
                }
                
                theSink.pbapc_data.pbap_command = pbapc_browsing_entry;
            }
                
            lIndicateEvent = FALSE ;
        }
        break;
        
        case EventUsrPbapBrowseList:
        {
            MAIN_DEBUG(("EventUsrPbapBrowseList\n"));

            if(theSink.pbapc_data.pbap_command == pbapc_action_idle)
            {         
                if(theSink.pbapc_data.pbap_active_link == pbapc_invalid_link)
                {
                    pbapConnect( hfp_primary_link );
                }
                else
                {
                    /* Set the link to active state */
                    linkPolicySetLinkinActiveMode(PbapcGetSink(theSink.pbapc_data.pbap_active_link));

                    PbapcSetPhonebookRequest(theSink.pbapc_data.pbap_active_link, theSink.pbapc_data.pbap_phone_repository, theSink.pbapc_data.pbap_active_pb);
                }
                
                theSink.pbapc_data.pbap_command = pbapc_browsing_list;
            }
                
            lIndicateEvent = FALSE ;
        }
        break;
        
        case EventUsrPbapDownloadPhonebook:
        {
            MAIN_DEBUG(("EventUsrPbapDownloadPhonebook\n"));

            if(theSink.pbapc_data.pbap_command == pbapc_action_idle)
            {
                if(theSink.pbapc_data.pbap_active_link == pbapc_invalid_link)
                {
                    pbapConnect( hfp_primary_link );
                }
                else
                {
                    /* Set the link to active state */
                    linkPolicySetLinkinActiveMode(PbapcGetSink(theSink.pbapc_data.pbap_active_link));

                    MessageSend(&theSink.task , PBAPC_APP_PULL_PHONE_BOOK , 0 ) ;
                }
                
                theSink.pbapc_data.pbap_command = pbapc_downloading;
            }
                
            lIndicateEvent = FALSE ;
        }
        break;
        
        case EventUsrPbapGetPhonebookSize:
        {
            MAIN_DEBUG(("EventUsrPbapGetPhonebookSize"));

            if(theSink.pbapc_data.pbap_command == pbapc_action_idle)
            {
                if(theSink.pbapc_data.pbap_active_link == pbapc_invalid_link)
                {
                    pbapConnect( hfp_primary_link );
                }
                else
                {
                    /* Set the link to active state */
                    linkPolicySetLinkinActiveMode(PbapcGetSink(theSink.pbapc_data.pbap_active_link));

                    MessageSend(&theSink.task , PBAPC_APP_PHONE_BOOK_SIZE , 0 ) ;
                }
                
                theSink.pbapc_data.pbap_command = pbapc_phonebooksize;
            }
                
            lIndicateEvent = FALSE ;
        }
        break;        
        
        case EventUsrPbapSelectPhonebookObject:
        {
            MAIN_DEBUG(("EventUsrPbapSelectPhonebookObject\n"));  

            theSink.pbapc_data.PbapBrowseEntryIndex = 0;
            theSink.pbapc_data.pbap_browsing_start_flag = 0;
            
            if(theSink.pbapc_data.pbap_command == pbapc_action_idle)
            {
                theSink.pbapc_data.pbap_active_pb += 1;
                
                if(theSink.pbapc_data.pbap_active_pb > pbap_cch)
                {
                    theSink.pbapc_data.pbap_active_pb = pbap_pb;
                }
            } 

            lIndicateEvent = FALSE ;
        }    
        break; 
        
        case EventUsrPbapBrowseComplete:
        {
            MAIN_DEBUG(("EventUsrPbapBrowseComplete\n"));
        
            /* Set the link policy based on the HFP or A2DP state */
            linkPolicyPhonebookAccessComplete(PbapcGetSink(theSink.pbapc_data.pbap_active_link)); 
            
            theSink.pbapc_data.PbapBrowseEntryIndex = 0;
            theSink.pbapc_data.pbap_browsing_start_flag = 0;
            lIndicateEvent = FALSE ;
            
        }
        break;        
        
        
#endif        
        
#ifdef WBS_TEST
        /* TEST EVENTS for WBS testing */
        case EventUsrWbsTestSetCodecs:
            if(theSink.RenegotiateSco)
            {
                MAIN_DEBUG(("HS : AT+BAC = cvsd wbs\n")) ;
                theSink.RenegotiateSco = 0;
                HfpWbsSetSupportedCodecs((hfp_wbs_codec_mask_cvsd | hfp_wbs_codec_mask_msbc), FALSE);
            }
            else
            {
                MAIN_DEBUG(("HS : AT+BAC = cvsd only\n")) ;
                theSink.RenegotiateSco = 1;
                HfpWbsSetSupportedCodecs(hfp_wbs_codec_mask_cvsd , FALSE);           
            }
            
        break;
    
        case EventUsrWbsTestSetCodecsSendBAC:
            if(theSink.RenegotiateSco)
            {
                MAIN_DEBUG(("HS : AT+BAC = cvsd wbs\n")) ;
                theSink.RenegotiateSco = 0;
                HfpWbsSetSupportedCodecs((hfp_wbs_codec_mask_cvsd | hfp_wbs_codec_mask_msbc), TRUE);
            }
           else
           {
               MAIN_DEBUG(("HS : AT+BAC = cvsd only\n")) ;
               theSink.RenegotiateSco = 1;
               HfpWbsSetSupportedCodecs(hfp_wbs_codec_mask_cvsd , TRUE);           
           }
           break;
 
         case EventUsrWbsTestOverrideResponse:
                   
           if(theSink.FailAudioNegotiation)
           {
               MAIN_DEBUG(("HS : Fail Neg = off\n")) ;
               theSink.FailAudioNegotiation = 0;
           }
           else
           {
               MAIN_DEBUG(("HS : Fail Neg = on\n")) ;
               theSink.FailAudioNegotiation = 1;
           }
       break; 

#endif
    
       case EventUsrCreateAudioConnection:
           MAIN_DEBUG(("HS : Create Audio Connection\n")) ;
           
           CreateAudioConnection();
       break;

#ifdef ENABLE_MAPC
        case EventSysMapcMsgNotification:
            /* Generate a tone or audio prompt */
            MAIN_DEBUG(("HS : EventSysMapcMsgNotification\n")) ;
        break;
        case EventSysMapcMnsSuccess:
            /* Generate a tone to indicate the mns service success */
            MAIN_DEBUG(("HS : EventSysMapcMnsSuccess\n")) ;
        break;
        case EventSysMapcMnsFailed:
            /* Generate a tone to indicate the mns service failed */
            MAIN_DEBUG(("HS : EventSysMapcMnsFailed\n")) ;
        break;
#endif
            
       case EventUsrIntelligentPowerManagementOn:
           MAIN_DEBUG(("HS : Enable LBIPM\n")) ;           
            /* enable LBIPM operation */
           theSink.lbipmEnable = 1;          
           /* send plugin current power level */           
           AudioSetPower(powerManagerGetLBIPM());
            /* and store in PS for reading at next power up */
           configManagerWriteSessionData () ;     
       break;
       
       case EventUsrIntelligentPowerManagementOff:
           MAIN_DEBUG(("HS : Disable LBIPM\n")) ;           
            /* disable LBIPM operation */
           theSink.lbipmEnable = 0;
           /* notify the plugin Low power mode is no longer required */           
           AudioSetPower(powerManagerGetLBIPM());
            /* and store in PS for reading at next power up */
           configManagerWriteSessionData () ; 
       break;
       
       case EventUsrIntelligentPowerManagementToggle:
           MAIN_DEBUG(("HS : Toggle LBIPM\n")) ;
           if(theSink.lbipmEnable)
           {
               MessageSend( &theSink.task , EventUsrIntelligentPowerManagementOff , 0 ) ;
           }
           else
           {
               MessageSend( &theSink.task , EventUsrIntelligentPowerManagementOn , 0 ) ;
           }

       break; 
       
        case EventUsrUsbPlayPause:
           MAIN_DEBUG(("HS : EventUsrUsbPlayPause")) ;  
           usbPlayPause();
        break;
        case EventUsrUsbStop:
           MAIN_DEBUG(("HS : EventUsrUsbStop\n")) ;  
           usbStop();
        break;
        case EventUsrUsbFwd:
           MAIN_DEBUG(("HS : EventUsrUsbFwd\n")) ;  
           usbFwd();
        break;
        case EventUsrUsbBack:
           MAIN_DEBUG(("HS : EventUsrUsbBack\n")) ;  
           usbBck();
        break;
        case EventUsrUsbMute:
           MAIN_DEBUG(("HS : EventUsrUsbMute")) ;  
           usbMute(); 
        break;
        case EventUsrUsbLowPowerMode:
            /* USB low power mode */
            usbSetBootMode(BOOTMODE_USB_LOW_POWER);
        break;
        case EventSysUsbDeadBatteryTimeout:
            usbSetVbatDead(FALSE);
        break;

        case EventUsrAnalogAudioConnected:
            /* Start the timer here to turn off the device if this feature is enabled by the user*/
            if(theSink.features.PowerOffOnWiredAudioConnected)
            {
                /* cancel existing limbo timeout and reschedule another limbo timeout */
                MessageCancelAll ( &theSink.task , EventSysLimboTimeout ) ;
                MessageSendLater ( &theSink.task , EventSysLimboTimeout , 0 , D_SEC(theSink.conf1->timeouts.WiredAudioConnectedPowerOffTimeout_s) ) ;
            }
            else
            {
#ifdef ENABLE_PEER
                /*If the Analog Audio has connected then notify this to the peer device */
                audio_src_conn_state_t  AudioSrcStatus;
                AudioSrcStatus.src = ANALOG_AUDIO;
                AudioSrcStatus.isConnected = TRUE;
                updatePeerAudioConnStatus(AudioSrcStatus);

                PEER_UPDATE_REQUIRED_RELAY_STATE("ANALOG AUDIO CONNECTED");
#endif                    
                /* Update audio routing */
                audioHandleRouting(audio_source_none);
            }
            break;
            
        case EventUsrSpdifAudioConnected:
            /* Update audio routing */
            audioHandleRouting(audio_source_none);
        break;
        case EventUsrAnalogAudioDisconnected: 
#ifdef ENABLE_PEER
            {
                /*If the Analog Audio has disconnected then notify this to the peer device */
                audio_src_conn_state_t  AudioSrcStatus;
                AudioSrcStatus.src = ANALOG_AUDIO;
                AudioSrcStatus.isConnected = FALSE;
                updatePeerAudioConnStatus(AudioSrcStatus); 

                PEER_UPDATE_REQUIRED_RELAY_STATE("ANALOG AUDIO DISCONNECTED");                               
            }
#endif
            /* Update audio routing */
            audioHandleRouting(audio_source_none);
        break;

        case EventUsrSpdifAudioDisconnected:            
            /* Update audio routing */
            audioHandleRouting(audio_source_none);
        break;
            

#ifdef ENABLE_AVRCP   

       case EventUsrAvrcpPlayPause:
            MAIN_DEBUG(("HS : EventUsrAvrcpPlayPause\n")) ;  
            /* cancel any queued ff or rw requests */
            MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
            MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
            sinkAvrcpPlayPause();
       break;

      case EventUsrAvrcpPlay:
            MAIN_DEBUG(("HS : EventUsrAvrcpPlay\n")) ;  
            /* cancel any queued ff or rw requests */
            MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
            MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
            sinkAvrcpPlay();
       break;

       case EventUsrAvrcpPause:
            MAIN_DEBUG(("HS : EventUsrAvrcpPause\n")) ;  
            /* cancel any queued ff or rw requests */
            MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
            MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
            sinkAvrcpPause();
       break;
            
       case EventUsrAvrcpStop:
            MAIN_DEBUG(("HS : EventUsrAvrcpStop\n")) ; 
            /* cancel any queued ff or rw requests */
            MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
            MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
            sinkAvrcpStop();
       break;
            
       case EventUsrAvrcpSkipForward:
           MAIN_DEBUG(("HS : EventUsrAvrcpSkipForward\n")) ;  
           sinkAvrcpSkipForward();
       break;
 
       case EventUsrEnterBootMode2:
            MAIN_DEBUG(("Reboot into different bootmode [2]\n")) ;
           BootSetMode(BOOTMODE_CUSTOM) ;
       break ;
      
       case EventUsrAvrcpSkipBackward:
           MAIN_DEBUG(("HS : EventUsrAvrcpSkipBackward\n")) ; 
           sinkAvrcpSkipBackward();
       break;
            
       case EventUsrAvrcpFastForwardPress:
           MAIN_DEBUG(("HS : EventUsrAvrcpFastForwardPress\n")) ;  
           sinkAvrcpFastForwardPress();
           /* rescehdule a repeat of this message every 1.5 seconds */
           MessageSendLater( &theSink.task , EventUsrAvrcpFastForwardPress , 0 , AVRCP_FF_REW_REPEAT_INTERVAL) ;
       break;
            
       case EventUsrAvrcpFastForwardRelease:
           MAIN_DEBUG(("HS : EventUsrAvrcpFastForwardRelease\n")) ;
           /* cancel any queued FF repeat requests */
           MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
           sinkAvrcpFastForwardRelease();
       break;
            
       case EventUsrAvrcpRewindPress:
           MAIN_DEBUG(("HS : EventUsrAvrcpRewindPress\n")) ; 
           /* rescehdule a repeat of this message every 1.8 seconds */
           MessageSendLater( &theSink.task , EventUsrAvrcpRewindPress , 0 , AVRCP_FF_REW_REPEAT_INTERVAL) ;
           sinkAvrcpRewindPress();
       break;
            
       case EventUsrAvrcpRewindRelease:
           MAIN_DEBUG(("HS : EventUsrAvrcpRewindRelease\n")) ; 
           /* cancel any queued FF repeat requests */
           MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
           sinkAvrcpRewindRelease();
       break;
       
       case EventUsrAvrcpToggleActive:
           MAIN_DEBUG(("HS : EventUsrAvrcpToggleActive\n"));
           if (sinkAvrcpGetNumberConnections() > 1)
               sinkAvrcpToggleActiveConnection();
           else
               lIndicateEvent = FALSE;
       break;
       
       case EventUsrAvrcpNextGroup:
           MAIN_DEBUG(("HS : EventUsrAvrcpNextGroup\n"));
           sinkAvrcpNextGroup();
       break;
       
       case EventUsrAvrcpPreviousGroup:
           MAIN_DEBUG(("HS : EventUsrAvrcpPreviousGroup\n"));
           sinkAvrcpPreviousGroup();
       break;

       case EventUsrAvrcpShuffleOff:
           MAIN_DEBUG(("HS : EventUsrAvrcpShuffleOff\n"));
           sinkAvrcpShuffle(AVRCP_SHUFFLE_OFF);
        break;
        
       case EventUsrAvrcpShuffleAllTrack:
           MAIN_DEBUG(("HS : EventUsrAvrcpShuffleAllTrack\n"));
           sinkAvrcpShuffle(AVRCP_SHUFFLE_ALL_TRACK);
        break;
        
       case EventUsrAvrcpShuffleGroup:
           MAIN_DEBUG(("HS : EventUsrAvrcpShuffleGroup\n"));
           sinkAvrcpShuffle(AVRCP_SHUFFLE_GROUP);
        break;

       case EventUsrAvrcpRepeatOff:
           MAIN_DEBUG(("HS : EventUsrAvrcpRepeatOff\n"));
           sinkAvrcpRepeat(AVRCP_REPEAT_OFF);
        break;
        
       case EventUsrAvrcpRepeatSingleTrack:
           MAIN_DEBUG(("HS : EventUsrAvrcpRepeatSingleTrack\n"));
           sinkAvrcpRepeat(AVRCP_REPEAT_SINGLE_TRACK);
        break;        
            
       case EventUsrAvrcpRepeatAllTrack:
           MAIN_DEBUG(("HS : EventUsrAvrcpRepeatAllTrack\n"));           
           sinkAvrcpRepeat(AVRCP_REPEAT_ALL_TRACK);
        break;
        
       case EventUsrAvrcpRepeatGroup:
           MAIN_DEBUG(("HS : EventUsrAvrcpRepeatGroup\n"));
           sinkAvrcpRepeat(AVRCP_REPEAT_GROUP);
        break;
        case EventSysSetActiveAvrcpConnection:
        {
            sinkAvrcpSetActiveConnection(&((UpdateAvrpcMessage_t *)message)->bd_addr);
        }
        break;    
       case EventSysResetAvrcpMode:
        {  
            uint16 index = *(uint16 *) message;
            lIndicateEvent = FALSE ;
            theSink.avrcp_link_data->link_active[index] =  FALSE;
        }
        break;
        
#endif       
       
        case EventUsrSwitchAudioMode:           
        {
            /* If A2DP in use and muted set mute */
            AUDIO_MODE_T mode = VolumeCheckA2dpMute() ? AUDIO_MODE_MUTE_SPEAKER : AUDIO_MODE_CONNECTED;
            /* If USB in use set current USB mode */
            usbAudioGetMode(&mode);
            /* cycle through EQ modes */
            theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing = A2DP_MUSIC_PROCESSING_FULL_NEXT_EQ_BANK;
            MAIN_DEBUG(("HS : EventUsrSwitchAudioMode %x\n", theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing ));
            AudioSetMode(mode, &theSink.a2dp_link_data->a2dp_audio_mode_params);
        }
        break;              
       
       case EventUsrButtonLockingToggle:
            MAIN_DEBUG(("HS : EventUsrButtonLockingToggle (%d)\n",theSink.buttons_locked));
            if (theSink.buttons_locked)
            {                
                MessageSend( &theSink.task , EventUsrButtonLockingOff , 0 ) ;
            }
            else
            {                
                MessageSend( &theSink.task , EventUsrButtonLockingOn , 0 ) ;
            }
        break;
        
        case EventUsrButtonLockingOn:
            MAIN_DEBUG(("HS : EventUsrButtonLockingOn\n"));
            theSink.buttons_locked = TRUE;            
        break;
        
        case EventUsrButtonLockingOff:
            MAIN_DEBUG(("HS : EventUsrButtonLockingOff\n"));
            theSink.buttons_locked = FALSE;          
        break;
        
        case EventUsrAudioPromptsOff:
            MAIN_DEBUG(("HS : EventUsrAudioPromptsOff"));
            /* disable audio prompts */

            /* Play the disable audio prompts prompt before actually disabling them */
            if(theSink.audio_prompts_enabled == TRUE) /* Check if audio prompts are already enabled */
            {
                TonesPlayEvent( id );
            }

            theSink.audio_prompts_enabled = FALSE;
            /* write enable state to pskey user 12 */
            configManagerWriteSessionData () ;                          
        break;
                
        case EventUsrAudioPromptsOn:
            MAIN_DEBUG(("HS : EventUsrAudioPromptsOn"));
            /* enable audio prompts */
            theSink.audio_prompts_enabled = TRUE;            
            /* write enable state to pskey user 12 */
            configManagerWriteSessionData () ;                          
        break;

        case EventUsrTestModeAudio:
            MAIN_DEBUG(("HS : EventUsrTestModeAudio\n"));        
            if (lState != deviceTestMode)
            {
                MessageSend(task, EventUsrEnterDUTState, 0);
            }      
            enterAudioTestMode();
        break;
        
        case EventUsrTestModeTone:
            MAIN_DEBUG(("HS : EventUsrTestModeTone\n")); 
            if (lState != deviceTestMode)
            {
                MessageSend(task, EventUsrEnterDUTState, 0);
            }      
            enterToneTestMode();
        break;
        
        case EventUsrTestModeKey:
            MAIN_DEBUG(("HS : EventUsrTestModeKey\n")); 
            if (lState != deviceTestMode)
            {
                MessageSend(task, EventUsrEnterDUTState, 0);
            }      
            enterKeyTestMode();
        break;

#ifdef ENABLE_SPEECH_RECOGNITION
        case EventSysSpeechRecognitionStart:
        {
        
            if ( speechRecognitionIsEnabled() )
                speechRecognitionStart() ;
            else
                lIndicateEvent = FALSE; 
        }
        break ;    
        case EventSysSpeechRecognitionStop:
        {
            if(speechRecognitionIsEnabled() ) 
                speechRecognitionStop() ;    
            else
                lIndicateEvent = FALSE; 
        }    
        break ;
        /* to tune the Speech Recognition using the UFE generate this event */
        case EventUsrSpeechRecognitionTuningStart:
        {
            /* ensure speech recognition is enabled */
            if ( speechRecognitionIsEnabled() )
            {
                /* ensure not already in tuning mode */
                if(!theSink.csr_speech_recognition_tuning_active)
                {
                    theSink.csr_speech_recognition_tuning_active = TRUE;
                    speechRecognitionStart() ;
                }
            }
        } 
        break;       
        
        case EventSysSpeechRecognitionTuningYes:
        break;
        
        case EventSysSpeechRecognitionTuningNo:
        break;

#endif

        case EventUsrTestDefrag:
            MAIN_DEBUG(("HS : EventUsrTestDefrag\n")); 
            configManagerFillPs();
        break;

        case EventSysStreamEstablish:
            MAIN_DEBUG(("HS : EventSysStreamEstablish[%u]\n", ((EVENT_STREAM_ESTABLISH_T *)message)->priority)); 
            connectA2dpStream( ((EVENT_STREAM_ESTABLISH_T *)message)->priority, 0 );
        break;
        
        case EventSysA2dpConnected:
            MAIN_DEBUG(("HS : EventSysA2dpConnected\n"));
        break;
        
        case EventSysUpdateAttributes:
            deviceManagerDelayedUpdateAttributes((EVENT_UPDATE_ATTRIBUTES_T*)message);
        break;
        
        case EventUsrPeerSessionConnDisc:
            MAIN_DEBUG(("HS: PeerSessionConnDisc [%d]\n" , lState )) ;
            /*go into pairing mode*/ 
            if ( lState != deviceLimbo)
            {
                /* ensure there is only one device connected to allow peer dev to connect */
                if(deviceManagerNumConnectedDevs() < MAX_A2DP_CONNECTIONS)
                {
#ifdef ENABLE_PEER
                    uint16 index;  
                    uint16 srcIndex;
                    uint16 avrcpIndex;
                    /* check whether the a2dp connection is present and streaming data and that the audio is routed, if thats true then pause the stream */
                    if(theSink.routed_audio && getA2dpIndexFromSink(theSink.routed_audio, &index)  
                        && (A2dpMediaGetState(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index]) == a2dp_stream_streaming)
                        && a2dpGetSourceIndex(&srcIndex) && (srcIndex == index)
                        && sinkAvrcpGetIndexFromBdaddr(&theSink.a2dp_link_data->bd_addr[index], &avrcpIndex, TRUE))
                    {
                        /* cancel any queued ff or rw requests and then pause the streaming*/
                        MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
                        MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
                        sinkAvrcpPlayPauseRequest(avrcpIndex,AVRCP_PAUSE);                 
                    }                   
#endif  

                    theSink.inquiry.session = inquiry_session_peer;
                    stateManagerEnterConnDiscoverableState( FALSE );                
                }
                /* no free connections, indicate an error condition */
                else
                {
                    lIndicateEvent = FALSE;
                    MessageSend ( &theSink.task , EventSysError , 0 ) ;               
                }
            }
            else
            {
                lIndicateEvent = FALSE ;
            }
        break ;
        
        case ( EventUsrPeerSessionInquire ):
            MAIN_DEBUG(("HS: PeerSessionInquire\n"));
            
            /* ensure there is only one device connected to allow peer dev to connect */
            if(deviceManagerNumConnectedDevs() < MAX_A2DP_CONNECTIONS)
            {
#ifdef ENABLE_PEER
                uint16 index;  
                uint16 srcIndex;
                uint16 avrcpIndex;
                /* check whether the a2dp connection is present and streaming data and that the audio is routed, if thats true then pause the stream */
                if(theSink.routed_audio && getA2dpIndexFromSink(theSink.routed_audio, &index)  
                    && (A2dpMediaGetState(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index]) == a2dp_stream_streaming)
                    && a2dpGetSourceIndex(&srcIndex) && (srcIndex == index)
                    && sinkAvrcpGetIndexFromBdaddr(&theSink.a2dp_link_data->bd_addr[index], &avrcpIndex, TRUE))
                {
                    /* cancel any queued ff or rw requests and then pause the streaming*/
                    MessageCancelAll (&theSink.task, EventUsrAvrcpFastForwardPress);
                    MessageCancelAll (&theSink.task, EventUsrAvrcpRewindPress);
                    sinkAvrcpPlayPauseRequest(avrcpIndex,AVRCP_PAUSE);                 
                }                   
#endif                
                lIndicateEvent = inquiryPair( inquiry_session_peer, FALSE );
            }
            /* no free connections, indicate an error condition */
            else
            {
                lIndicateEvent = FALSE;
                MessageSend ( &theSink.task , EventSysError , 0 ) ;               
            }
                
        break;
        
        case EventUsrPeerSessionEnd:
        {
#ifdef PEER_SCATTERNET_DEBUG   /* Scatternet debugging only */
            uint16 i;
            for_all_a2dp(i)
            {
                if (theSink.a2dp_link_data)
                {
                    theSink.a2dp_link_data->invert_ag_role[i] = !theSink.a2dp_link_data->invert_ag_role[i];
                    MAIN_DEBUG(("HS: invert_ag_role[%u] = %u\n",i,theSink.a2dp_link_data->invert_ag_role[i]));
                    
                    if (theSink.a2dp_link_data->connected[i] && (theSink.a2dp_link_data->peer_device[i] != remote_device_peer))
                    {
                        linkPolicyUseA2dpSettings( theSink.a2dp_link_data->device_id[i], 
                                                   theSink.a2dp_link_data->stream_id[i], 
                                                   A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[i]) );
                    }
                }
            }
#else   /* Normal operation */
            MAIN_DEBUG(("HS: EventUsrPeerSessionEnd\n"));
            lIndicateEvent = disconnectAllA2dpPeerDevices();
#endif    
        }
        break;
        
        case EventUsrSwapA2dpMediaChannel:
            /* attempt to swap media channels, don't indicate event if not successful */
            if(!audioSwapMediaChannel())
                lIndicateEvent = FALSE;
        break;

        /* bass boost enable disable toggle */
        case EventUsrBassBoostEnableDisableToggle:
            if(theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements & MUSIC_CONFIG_BASS_BOOST_BYPASS)
            {
                /* disable bass boost */
                sinkAudioSetEnhancement(MUSIC_CONFIG_BASS_BOOST_BYPASS,FALSE);       
            }
            else
            {
                /* enable bass boost */
                sinkAudioSetEnhancement(MUSIC_CONFIG_BASS_BOOST_BYPASS,TRUE);       
            }
        break;
        
        /* bass boost enable indication */
        case EventUsrBassBoostOn:
            /* logic inverted in a2dp plugin lib, disable bypass to enable bass boost */
            sinkAudioSetEnhancement(MUSIC_CONFIG_BASS_BOOST_BYPASS,TRUE);
        break;
                
        /* bass boost disable indication */
        case EventUsrBassBoostOff:
            /* logic inverted in a2dp plugin lib, enable bypass to disable bass boost */
            sinkAudioSetEnhancement(MUSIC_CONFIG_BASS_BOOST_BYPASS,FALSE);
        break;

        /* 3D enhancement enable disable toggle */              
        case EventUsr3DEnhancementEnableDisableToggle:
            if(theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements & MUSIC_CONFIG_SPATIAL_BYPASS)
            {
                /* disable 3d */
                sinkAudioSetEnhancement(MUSIC_CONFIG_SPATIAL_BYPASS,FALSE);
            }
            else
            {
                /* enable 3d */
            sinkAudioSetEnhancement(MUSIC_CONFIG_SPATIAL_BYPASS,TRUE);
            }
        break;
        
        /* 3D enhancement enable indication */
        case EventUsr3DEnhancementOn:
            /* logic inverted in a2dp plugin lib, disable bypass to enable 3d */
            sinkAudioSetEnhancement(MUSIC_CONFIG_SPATIAL_BYPASS,TRUE);
        break;
        
        /* 3D enhancement disable indication */
        case EventUsr3DEnhancementOff:
            /* logic inverted in a2dp plugin lib, enable bypass to disable 3d */
            sinkAudioSetEnhancement(MUSIC_CONFIG_SPATIAL_BYPASS,FALSE);
        break;     
        
         /* User EQ enable disable toggle indication */              
        case EventUsrUserEqOnOffToggle:
            if(theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements & MUSIC_CONFIG_USER_EQ_BYPASS)
            {
                /* disable User EQ */
                sinkAudioSetEnhancement(MUSIC_CONFIG_USER_EQ_BYPASS, FALSE);
            }
            else
            {
                /* enable User EQ */
                sinkAudioSetEnhancement(MUSIC_CONFIG_USER_EQ_BYPASS, TRUE);
            }
        break;
        
       /* User EQ enable indication */
        case EventUsrUserEqOn:
            /* logic inverted in a2dp plugin lib, disable bypass to enable 3d */
            sinkAudioSetEnhancement(MUSIC_CONFIG_USER_EQ_BYPASS, TRUE);
        break;
        
        /* User EQ disable indication */
        case EventUsrUserEqOff:
            /* logic inverted in a2dp plugin lib, enable bypass to disable 3d */
            sinkAudioSetEnhancement(MUSIC_CONFIG_USER_EQ_BYPASS, FALSE);
        break;     
        
        /* check whether the Audio Amplifier drive can be turned off after playing
           a tone or voice prompt */
        case EventSysCheckAudioAmpDrive:
            /* cancel any pending messages */
            MessageCancelAll( &theSink.task , EventSysCheckAudioAmpDrive);
            /* when the device is no longer routing audio tot he speaker then
               turn off the audio amplifier */
            if((!IsAudioBusy()) && (!theSink.routed_audio))
            {
                MAIN_DEBUG (( "HS : EventSysCheckAudioAmpDrive turn off amp\n" ));     
                PioSetPio ( theSink.conf1->PIOIO.pio_outputs.DeviceAudioActivePIO , pio_drive, FALSE) ;
            }
            /* audio is still busy, check again later */            
            else
            {
                MAIN_DEBUG (( "HS : EventSysCheckAudioAmpDrive still busy, reschedule\n" ));     
                MessageSendLater(&theSink.task , EventSysCheckAudioAmpDrive, 0, CHECK_AUDIO_AMP_PIO_DRIVE_DELAY);    
            }
        break;

        /* external microphone has been connected */
        case EventUsrExternalMicConnected:
            theSink.a2dp_link_data->a2dp_audio_mode_params.external_mic_settings = EXTERNAL_MIC_FITTED;
            /* if routing audio update the mic source for dsp apps that support it */
            if(theSink.routed_audio)            
                AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
        break;
        
        /* external microphone has been disconnected */
        case EventUsrExternalMicDisconnected:
            theSink.a2dp_link_data->a2dp_audio_mode_params.external_mic_settings = EXTERNAL_MIC_NOT_FITTED;
            /* if routing audio update the mic source for dsp apps that support it */
            if(theSink.routed_audio)            
                AudioSetMode(AUDIO_MODE_CONNECTED, &theSink.a2dp_link_data->a2dp_audio_mode_params);
       break;

       /* event to enable the simple speech recognition functionality, persistant over power cycle */
       case EventUsrSSROn:
            theSink.ssr_enabled = TRUE;
       break;
       
       /* event to disable the simple speech recognition functionality, persistant over power cycle */
       case EventUsrSSROff:
            theSink.ssr_enabled = FALSE;
       break;

       /* NFC tag detected, determine action based on current connection state */
       case EventUsrNFCTagDetected:
            /* if not connected to an AG, go straight into pairing mode */
            if(stateManagerGetState() < deviceConnected)
                stateManagerEnterConnDiscoverableState( TRUE );
            /* otherwise see if audio is on the device and attempt
               to transfer audio if not present */
            else
               sinkCheckForAudioTransfer(); 
       break;

       /* check whether the current routed audio is still the correct one and
          change sources if appropriate */
       case EventSysCheckAudioRouting:
            /* check audio routing */
            audioHandleRouting(audio_source_none);    
            /* don't indicate event as may be generated by USB prior to configuration
               being loaded */
            lIndicateEvent = FALSE;
       break;
	   /* Audio amplifier is to be shut down by PIO for power saving purposes */
       case EventSysAmpPowerDown:
            stateManagerAmpPowerControl(POWER_DOWN);
       break;
               
#ifdef ENABLE_FM
       case EventUsrFmRxOn:
        {
            /* enable the FM hardware if not already enabled */           
            MAIN_DEBUG(("HS : EventUsrFmRxOn\n"));
            /* FM not available unless device is powered on */
            if(stateManagerGetState()!=deviceLimbo)
            {
                /* ensure fm is not already enabled */
                if(!theSink.conf2->sink_fm_data.fmRxOn)
                {
                    /* enable FM hardware */
                    sinkFmInit(FM_ENABLE_RX);
                }
                else
                {
                    MAIN_DEBUG (( "HS : Cannot enable FM as already enabled\n"));
                    lIndicateEvent=FALSE;
                }
            }
        }
        break;

       case EventUsrFmRxOff:
            MAIN_DEBUG(("HS : EventUsrFmRxOff\n"));
            
            if (theSink.conf2->sink_fm_data.fmRxOn)
            {
                sinkFmRxAudioDisconnect();
                sinkFmRxPowerOff();
                theSink.conf2->sink_fm_data.fmRxOn=FALSE;
                
                #ifdef ENABLE_DISPLAY   
                        displayShowSimpleText(DISPLAYSTR_CLEAR,1);
                        displayShowSimpleText(DISPLAYSTR_CLEAR,2);
                #endif           
            }
            else
            {
                MAIN_DEBUG (( "HS : FM already stopped \n"));
                lIndicateEvent=FALSE;
            }
        break;

       case EventUsrFmRxTuneUp:
            MAIN_DEBUG(("HS : EventUsrFmRxTuneUp\n")); 

            if (theSink.conf2->sink_fm_data.fmRxOn)
            {
                sinkFmRxTuneUp();
            }            
            else
            {
                MAIN_DEBUG (( "HS : Cannot tune up FM as audio is busy or FM is not ON \n"));
                lIndicateEvent=FALSE;
            }

        break;

       case EventUsrFmRxTuneDown:
            MAIN_DEBUG(("HS : EventUsrFmRxTuneDown\n")); 
            if (theSink.conf2->sink_fm_data.fmRxOn)
            {
                sinkFmRxTuneDown();
            }
            else
            {
                MAIN_DEBUG (( "HS : Cannot tune down FM as audio is busy or FM is not ON \n"));
                lIndicateEvent=FALSE;
            }
        break;
            
       case EventUsrFmRxStore:
            MAIN_DEBUG(("HS : EventUsrFmRxStore\n")); 
            if (theSink.conf2->sink_fm_data.fmRxOn)
            {
                sinkFmRxStoreFreq(theSink.conf2->sink_fm_data.fmRxTunedFreq);
            }            
            else
            {
                MAIN_DEBUG (( "HS : Cannot store FM freq as FM is not ON \n"));
                lIndicateEvent=FALSE;
            }
        break;

       case EventUsrFmRxTuneToStore:
            MAIN_DEBUG(("HS : EventUsrFmRxTuneToStore\n")); 
            if (theSink.conf2->sink_fm_data.fmRxOn)
            {
                sinkFmRxTuneToStore(theSink.conf2->sink_fm_data.fmRxTunedFreq);
            }
            else
            {
                MAIN_DEBUG (( "HS : Cannot playstore FM as FM is not ON \n"));
                lIndicateEvent=FALSE;
            }

        break;
        
       case EventUsrFmRxErase:
            MAIN_DEBUG(("HS : EventUsrFmRxErase\n")); 
            if (theSink.conf2->sink_fm_data.fmRxOn)
            {
                sinkFmRxEraseFreq(theSink.conf2->sink_fm_data.fmRxTunedFreq);
            }
            else
            {
                MAIN_DEBUG (( "HS : Cannot erase FM freq as FM is not ON \n"));
                lIndicateEvent=FALSE;
            }

        break;
#endif /* ENABLE_FM */
       
#if defined ENABLE_PEER && defined PEER_TWS
        case EventUsrSelectAudioSourceNext:
            /* Select next source based on the currently selected one */
            switch (peerGetSource())
            {
            case RELAY_SOURCE_NULL:
                MessageSend(&theSink.task, EventUsrSelectAudioSourceAnalog, 0);  
                break;
            case RELAY_SOURCE_ANALOGUE:
                MessageSend(&theSink.task, EventUsrSelectAudioSourceUSB, 0);  
                break;
            case RELAY_SOURCE_USB:
                MessageSend(&theSink.task, EventUsrSelectAudioSourceAG1, 0);  
                break;
            case RELAY_SOURCE_A2DP:
                MessageSend(&theSink.task, EventUsrSelectAudioSourceAnalog, 0);  
                break;
            }
            break;
            
        case EventUsrSelectAudioSourceAnalog:
            /* Analogue is used for the source to relay only */
            peerSetSource(RELAY_SOURCE_ANALOGUE);
            break;
            
        case EventUsrSelectAudioSourceUSB:
            /* USB is used for the source to relay only */
            peerSetSource(RELAY_SOURCE_USB);
            break;
            
        case EventUsrSelectAudioSourceAG1:
        case EventUsrSelectAudioSourceAG2:
            /* A2DP is used for the source to relay only */
            peerSetSource(RELAY_SOURCE_A2DP);
            break;
            
        case EventUsrSelectFMAudioSource:
            /* Not currently used for Peer devices */
            break;
            
        case EventUsrSelectAudioSourceNone:
            /* Actually used to enable automatic source selection */
            peerSetSource(RELAY_SOURCE_NULL);
            break;
#endif  /* ENABLE_PEER && PEER_TWS */
 
/* when using manual audio source routing, these events can be used to switch
   between audio sources */
#ifdef ENABLE_SOUNDBAR

       /* manually switch to analog audio source */
       case EventUsrSelectAudioSourceAnalog:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_ANALOG);
       break;
       
       /* manually switch to spdif audio source */
       case EventUsrSelectAudioSourceSpdif:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_SPDIF);
       break;

       /* manually switch to USB audio source */
       case EventUsrSelectAudioSourceUSB:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_USB);
       break;
       
       /* manually switch to AG1 audio source */
       case EventUsrSelectAudioSourceAG1:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_AG1);
       break;
       
       /* manually switch to AG2 audio source */
       case EventUsrSelectAudioSourceAG2:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_AG2);
       break;
       
       /* manually switch to AG2 audio source */
       case EventUsrSelectFMAudioSource:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_FM);
       break;
        
       /* manually switch to no audio source - disconnect any audio currently routed */
       case EventUsrSelectAudioSourceNone:
            if (stateManagerGetState() != deviceLimbo)
                audioSwitchToAudioSource(audio_source_none);
       break;

       /* Toggle between wired source and bluetooth source */
       case EventUsrSelectAudioSourceNext:  
            MAIN_DEBUG (( "HS : EventToggleSource for Soundbar\n"));     
            /* only allow source switching when powered on */
            if (stateManagerGetState() != deviceLimbo)
            {
                audioSwitchToNextAudioSource();
            }
            else
            {
                /* don't indicate event if not powered on */
                lIndicateEvent = FALSE;
            }
       break;


       case EventUsrRCVolumeDown:
            MAIN_DEBUG (( "HS : EventUsrRCVolumeDown for Soundbar\n"));
            MessageSendLater(&theSink.task, EventUsrVolumeDown, 0,200);
       break;
       
       case EventUsrRCVolumeUp:
            MAIN_DEBUG (( "HS : EventUsrRCVolumeUp for Soundbar\n"));
            MessageSendLater(&theSink.task, EventUsrVolumeUp, 0,200);
       break;
#endif /* ENABLE_SOUNDBAR */
       
#ifdef ENABLE_SUBWOOFER
       case EventUsrSubwooferStartInquiry:
            handleEventUsrSubwooferStartInquiry();
       break;
       
       case EventSysSubwooferCheckPairing:
            handleEventSysSubwooferCheckPairing();
       break;
       
       case EventSysSubwooferOpenLLMedia:
            /* open a Low Latency media connection */
            handleEventSysSubwooferOpenLLMedia();
       break;
       
       case EventSysSubwooferOpenStdMedia:
            /* open a standard latency media connection */
            handleEventSysSubwooferOpenStdMedia();
       break;
       
       case EventUsrSubwooferVolumeUp:
            handleEventUsrSubwooferVolumeUp();
       break;
       
       case EventUsrSubwooferVolumeDown:
            handleEventUsrSubwooferVolumeDown();
       break;
       
       case EventSysSubwooferCloseMedia:
            handleEventSysSubwooferCloseMedia();
       break;
       
       case EventSysSubwooferStartStreaming:
            handleEventSysSubwooferStartStreaming();
       break;
       
       case EventSysSubwooferSuspendStreaming:
            handleEventSysSubwooferSuspendStreaming();
       break;
       
       case EventUsrSubwooferDeletePairing:
            handleEventUsrSubwooferDeletePairing();
       break;
       
       /* set subwoofer volume level by message to maintain synchronisation with 
          audio plugins */
       case EventSysSubwooferSetVolume:
            /* send volume level change to subwoofer */
            updateSwatVolumeNow(((SWAT_VOLUME_CHANGE_MSG_T*)message)->new_volume);
       break;
#endif

       case EventUsrEnterDriverlessDFUMode:
            LoaderModeEnter();
       break;
       
#ifdef ENABLE_PARTYMODE       
       /* enabling or disabling the runtime control of the party mode feature */
       case EventUsrPartyModeToggle:
            /* ensure a party mode operating type has been selected in configuration 
               before enabling the feature */
            if(theSink.features.PartyMode)   
            {    
                theSink.PartyModeEnabled = !theSink.PartyModeEnabled;
                /* if party mode is enabled and more than one device is connected, 
                   drop the second device to allow a second one connect */
                if((theSink.PartyModeEnabled) && (deviceManagerNumConnectedDevs() > 1))
                   sinkPartyModeDisconnectDevice(a2dp_secondary);
                /* ensure headset is discoverable and connectable once enabled */                
                else if(theSink.PartyModeEnabled)
                    sinkEnableConnectable();
                /* ensure pairable */                
                sinkEnableDiscoverable();
            }
       break;   
             
       /* connected device hasn't played music before timeout, disconnect it to allow
          another device to connect */
       case EventSysPartyModeTimeoutDevice1:
            sinkPartyModeDisconnectDevice(a2dp_primary);
       break;
       
       /* connected device hasn't played music before timeout, disconnect it to allow
          another device to connect */
       case EventSysPartyModeTimeoutDevice2:
            sinkPartyModeDisconnectDevice(a2dp_secondary);      
       break;
#endif
       
#ifdef ENABLE_GAIA
        case EventUsrGaiaDFURequest:
        /*  GAIA DFU requires that audio not be busy, so disallow any tone  */
            lIndicateEvent = FALSE;
            gaiaDfuRequest();
        break;
#endif

#if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
        case EventSysRemoteControlCodeReceived:
             /* Display a led pattern*/ 
        break;
#endif
        
#ifdef ENABLE_IR_REMOTE
        case EventSysIRCodeLearnSuccess:
        {
            /* TODO : Play a tone or something */
        }
        break;
        case EventSysIRCodeLearnFail:
        {
            /* TODO : Play a tone or something */
        }
        break;
        case EventSysIRLearningModeTimeout:
        {
            irStopLearningMode();
        }
        break;
        case EventSysIRLearningModeReminder:
        {
            handleIrLearningModeReminder();
        }
        break;
        case EventUsrStartIRLearningMode:
        {
            irStartLearningMode();
        }
        break;
        case EventUsrStopIRLearningMode:
        {
            irStopLearningMode();
        }
        break;
        case EventUsrClearIRCodes:
        {
            irClearLearntCodes();
        }
        break;
#endif
        
#if defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED)
        /* User events for (HOGP) BLE Remote Control */
        case EventUsrBleEnablePairingMode:
        {
            bleEnablePairingMode();
        }
        break;
        case EventUsrBleDisablePairingMode:
        {
            bleDisablePairingMode();
        }
        break;
        case EventUsrBleConnectStoredRemote:
        {
            bleConnectStoredRemote();
        }
        break;
        case EventUsrBleDisconnectStoredRemote:
        {
            bleDisconnectStoredRemote();
        }
        break;
        
        /* User events for (HOGP) BLE Remote Control - Events required to pass HOGP PTS tests */
        case EventUsrBleEnablePtsTestMode:
        {
            bleEnablePtsTestMode();
        }
        break;
        case EventUsrBleDisablePtsTestMode:
        {
            bleDisablePtsTestMode();
        }
        break;
        case EventUsrBlePtsModeNext:
        {
            blePtsModeNext();
        }
        break;
        case EventUsrBleChangeWriteModePriority:
        {
            bleChangeWriteModePriority();
        }
        break;
        case EventUsrBleEnterSuspendMode:
        {
            bleEnterSuspendMode();
        }
        break;
        case EventUsrBleExitSuspendMode:
        {
            bleExitSuspendMode();
        }
        break;
        case EventUsrBleEnableNotifications:
        {
            bleEnableNotifications();
        }
        break;
        case EventUsrBleDisableNotifications:
        {
            bleDisableNotifications();
        }
        break;
        
        /* BLE Remote system events */
        case EventSysBleRemotePairingTimeout:
        {
            bleDisablePairingMode();
        }
        break;
        case EventSysBleRemotePairingSuccess:
        {
            bleRemotePairingComplete(TRUE);
        }
        break;
        case EventSysBleRemotePairingFailed:
        {
            bleRemotePairingComplete(FALSE);
        }
        break;
        case EventSysBleRemoteAllDisconnected:
        {
            /* If the device needs to be reset, all RCs are disconnected, so allow the reset to occur */
            if (theSink.rundata->bleInputMonitor.ad_scan_disabled)
            {
                LMEndMessage_t * lEventMessage  = mallocPanic ( sizeof(LMEndMessage_t) ) ; 
                lEventMessage->Event            = EventUsrPowerOff;
                lEventMessage->PatternCompleted = TRUE;
                MessageSend ( &theSink.task , EventSysLEDEventComplete , lEventMessage ) ;
            }
        }
        break;
        case EventSysBleRemoteConnected:
        /* Event used for indication */
        break;
#endif
        
#if defined ENABLE_PEER && defined PEER_TWS
        case EventUsrMasterDeviceTrimVolumeUp:
            VolumeCheckDeviceTrim(increase_volume, tws_master);
            break;
            
        case EventUsrMasterDeviceTrimVolumeDown:
            VolumeCheckDeviceTrim(decrease_volume, tws_master);
            break;
            
        case EventUsrSlaveDeviceTrimVolumeUp:
            VolumeCheckDeviceTrim(increase_volume, tws_slave);
            break;
            
        case EventUsrSlaveDeviceTrimVolumeDown:
            VolumeCheckDeviceTrim(decrease_volume, tws_slave);
            break;
            
        case EventUsrChangeAudioRouting:
        {
            uint16 current_routing = ((theSink.a2dp_link_data->a2dp_audio_mode_params.master_routing_mode & 0x3) << 2) | (theSink.a2dp_link_data->a2dp_audio_mode_params.slave_routing_mode & 0x3);
            uint16 distance = 16;
            uint16 index = 0;
            uint16 i;
            
            /* Find entry in tws_audio_routing table which is closest to current routing mode */
            for(i=0; i<sizeof(tws_audio_routing); i++)
            {
                if (tws_audio_routing[i] < current_routing)
                {
                    if ((current_routing - tws_audio_routing[i]) < distance)
                    {
                        distance = current_routing - tws_audio_routing[i];
                        index = i;
                    }
                }
                else
                {
                    if ((tws_audio_routing[i] - current_routing) < distance)
                    {
                        distance = tws_audio_routing[i] - current_routing;
                        index = i;
                    }
                }
            }
            
            /* Select next routing mode in table */
            index = (index + 1) % sizeof(tws_audio_routing);
            
            sinkA2dpSetPeerAudioRouting((tws_audio_routing[index] >> 2) & 0x3, tws_audio_routing[index] & 0x3);
            break;
        }
#endif
            
#ifdef ENABLE_GAIA_PERSISTENT_USER_EQ_BANK
            
        /* When timeout occurs, session data needs to be updated for new EQ settings */    
        case EventSysGaiaEQChangesStoreTimeout:            
            configManagerWriteSessionData (); 
            break;
#endif
            
        case EventSysCheckDefrag:
            {    
                /* if audio is routed, schedule a recheck when it's free */
                if(theSink.routed_audio)
                {    
                    MAIN_DEBUG (( "HS : EventSysCheckDefrag, audio routed, wait\n"));
                    MessageSendConditionally (&theSink.task , EventSysCheckDefrag , 0, (const uint16 *)&theSink.routed_audio);
                }
                else if(IsAudioBusy())
                {   
                    MAIN_DEBUG (( "HS : EventSysCheckDefrag, audio busy\n"));                    
                    /* check again when audio free */
                    MessageSendConditionally (&theSink.task , EventSysCheckDefrag , 0, (const uint16 *)AudioBusyPtr());                     
                }
#ifndef ENABLE_SOUNDBAR                
                 /* For headsets, only reset if the battery is connected */
                else if (!powerManagerIsChargerConnected())
                {
                    MAIN_DEBUG (( "HS : EventSysCheckDefrag, charger not connected\n"));  
                    MessageSendLater(&theSink.task, EventSysCheckDefrag, 0, D_SEC(theSink.conf1->timeouts.DefragCheckTimer_s)); 
                }
#endif                
                else
                {   
                    MAIN_DEBUG (( "HS : EventSysCheckDefrag, check\n"));                         
                    /* check PS Store */                                   
                    if(configManagerDefragCheck() )
                    {
                        /* defrag required, schedule a reboot */
                        MAIN_DEBUG (( "HS : EventSysCheckDefrag, defrag required\n"));  
                        MessageSendLater(&theSink.task, EventSysDefrag, 0, D_SEC(theSink.conf1->timeouts.DefragCheckTimer_s)); 
                    }
                    else
                    {
                        MAIN_DEBUG (( "HS : EventSysCheckDefrag, no defrag - reschedule on timer [%u]\n",theSink.conf1->timeouts.DefragCheckTimer_s));  
                        MessageSendLater(&theSink.task, EventSysCheckDefrag, 0, D_SEC(theSink.conf1->timeouts.DefragCheckTimer_s)); 
                    }
                }                
            }
            break;

        case EventSysDefrag:
            { 
                /* check if audio is busy before rebooting */
                if(theSink.routed_audio)
                {
                    MAIN_DEBUG (( "HS : EventSysDefrag, audio now routed, wait\n"));
                    MessageSendConditionally (&theSink.task , EventSysCheckDefrag , 0, (const uint16 *)&theSink.routed_audio);    
                }
                else if (IsAudioBusy())
                {
                    MAIN_DEBUG (( "HS : EventSysDefrag, audio busy, wait\n"));  
                    MessageSendConditionally (&theSink.task , EventSysCheckDefrag , 0, (const uint16 *)AudioBusyPtr()); 
                }
#ifndef ENABLE_SOUNDBAR                
                 /* For headsets, only reset if the battery is connected */
                else if (!powerManagerIsChargerConnected())
                {
                    MAIN_DEBUG (( "HS : EventSysCheckDefrag, charger not connected\n"));  
                    MessageSendLater(&theSink.task, EventSysCheckDefrag, 0, D_SEC(theSink.conf1->timeouts.DefragCheckTimer_s)); 
                }
#endif                 
                else
                {
                    /* defrag now */
                    MAIN_DEBUG (( "HS : EventSysDefrag, defrag now, will cause a reset\n")); 
                    configManagerDefrag(TRUE);   
                }
            }
            break;
       
        case EventSysToneDigit0:
        case EventSysToneDigit1:
        case EventSysToneDigit2:
        case EventSysToneDigit3:
        case EventSysToneDigit4:
        case EventSysToneDigit5:
        case EventSysToneDigit6:
        case EventSysToneDigit7:
        case EventSysToneDigit8:
        case EventSysToneDigit9:
            break;
        default :
            MAIN_DEBUG (( "HS : UE unhandled!! [%x]\n", id ));     
        break ;  
        
    }   
    
        /* Inform theevent indications that we have received a user event*/
        /* For all events except the end event notification as this will just end up here again calling itself...*/
    if ( lIndicateEvent )
    {
        if ( id != EventSysLEDEventComplete )
        {
            LEDManagerIndicateEvent ( id ) ;
        }           

        TonesPlayEvent ( id );
       
        ATCommandPlayEvent ( id ) ;
    }
    
#ifdef ENABLE_GAIA
    gaiaReportEvent(id);
#endif
    
#ifdef TEST_HARNESS 
    vm2host_send_event(id);
#endif
    
#ifdef DEBUG_MALLOC
    printf("MAIN: Event [%x] Available SLOTS:[%d]\n" ,id, VmGetAvailableAllocations() ) ;
#endif          
    
}


/*************************************************************************
NAME    
    handleHFPMessage

DESCRIPTION
    handles the messages from the user events

RETURNS

*/
static void handleHFPMessage  ( Task task, MessageId id, Message message )
{   
    MAIN_DEBUG(("HFP = [%x]\n", id)) ;   
    
    switch(id)
    {
        /* -- Handsfree Profile Library Messages -- */
    case HFP_INIT_CFM:              
        {
            /* Init configuration that is required now */
            uint32 ClassOfDevice = 0 ;

            InitEarlyUserFeatures();       
            MAIN_DEBUG(("HFP_INIT_CFM - enable streaming[%x]\n", theSink.features.EnableA2dpStreaming)) ;   
        
            PsFullRetrieve( 0x0003, &ClassOfDevice , sizeof(uint32) );    
                
            if (ClassOfDevice == 0 )
            {
                if(theSink.features.EnableA2dpStreaming)
                {
#ifdef ENABLE_SOUNDBAR                    
                    ConnectionWriteClassOfDevice(AUDIO_MAJOR_SERV_CLASS | AV_COD_RENDER | AV_MAJOR_DEVICE_CLASS | AV_MINOR_HIFI);  
#else
                    ConnectionWriteClassOfDevice(AUDIO_MAJOR_SERV_CLASS | AV_COD_RENDER | AV_MAJOR_DEVICE_CLASS | AV_MINOR_HEADPHONES);        
#endif                    
                }
                else
                {
                    ConnectionWriteClassOfDevice(AUDIO_MAJOR_SERV_CLASS | AV_MAJOR_DEVICE_CLASS | AV_MINOR_HEADSET);    
                }
        
            }
            else /*use the value from the PSKEY*/
            {
                ConnectionWriteClassOfDevice( ClassOfDevice ) ;
            }
            
            if  ( stateManagerGetState() == deviceLimbo ) 
            {
                if ( ((HFP_INIT_CFM_T*)message)->status == hfp_success )
                    sinkInitComplete( (HFP_INIT_CFM_T*)message );
                else
                    Panic();                
            }        
        }
        
    break;
 
    case HFP_SLC_CONNECT_IND:
        MAIN_DEBUG(("HFP_SLC_CONNECT_IND\n"));
        if (stateManagerGetState() != deviceLimbo)
        {   
            sinkHandleSlcConnectInd((HFP_SLC_CONNECT_IND_T *) message);
        }
    break;

    case HFP_SLC_CONNECT_CFM:
        MAIN_DEBUG(("HFP_SLC_CONNECT_CFM [%x]\n", ((HFP_SLC_CONNECT_CFM_T *) message)->status ));
        if (stateManagerGetState() == deviceLimbo)
        {
            if ( ((HFP_SLC_CONNECT_CFM_T *) message)->status == hfp_success )
            {
                /*A connection has been made and we are now logically off*/
                sinkDisconnectAllSlc();   
            }
        }
        else
        {
            sinkHandleSlcConnectCfm((HFP_SLC_CONNECT_CFM_T *) message);
        }
                            
        break;
        
    case HFP_SLC_LINK_LOSS_IND:
        MAIN_DEBUG(("HFP_SLC_LINK_LOSS_IND\n"));
        slcHandleLinkLossInd((HFP_SLC_LINK_LOSS_IND_T*)message);
    break;
    
    case HFP_SLC_DISCONNECT_IND:
        MAIN_DEBUG(("HFP_SLC_DISCONNECT_IND\n"));
        MAIN_DEBUG(("Handle Disconnect\n"));
        sinkHandleSlcDisconnectInd((HFP_SLC_DISCONNECT_IND_T *) message);
    break;
    case HFP_SERVICE_IND:
        MAIN_DEBUG(("HFP_SERVICE_IND [%x]\n" , ((HFP_SERVICE_IND_T*)message)->service  ));
        indicatorsHandleServiceInd ( ((HFP_SERVICE_IND_T*)message) ) ;       
    break;
    /* indication of call status information, sent whenever a change in call status 
       occurs within the hfp lib */
    case HFP_CALL_STATE_IND:
        /* the Call Handler will perform device state changes and be
           used to determine multipoint functionality */
        /* don't process call indications if in limbo mode */
        if(stateManagerGetState()!= deviceLimbo)
            sinkHandleCallInd((HFP_CALL_STATE_IND_T*)message);            
    break;

    case HFP_RING_IND:
        MAIN_DEBUG(("HFP_RING_IND\n"));     
        sinkHandleRingInd((HFP_RING_IND_T *)message);
    break;
    case HFP_VOICE_TAG_NUMBER_IND:
        MAIN_DEBUG(("HFP_VOICE_TAG_NUMBER_IND\n"));
        sinkWriteStoredNumber((HFP_VOICE_TAG_NUMBER_IND_T*)message);
    break;
    case HFP_DIAL_LAST_NUMBER_CFM:
        MAIN_DEBUG(("HFP_LAST_NUMBER_REDIAL_CFM\n"));       
        handleHFPStatusCFM (((HFP_DIAL_LAST_NUMBER_CFM_T*)message)->status ) ;
    break;      
    case HFP_DIAL_NUMBER_CFM:
        MAIN_DEBUG(("HFP_DIAL_NUMBER_CFM %d %d\n", stateManagerGetState(), ((HFP_DIAL_NUMBER_CFM_T *) message)->status));
        handleHFPStatusCFM (((HFP_DIAL_NUMBER_CFM_T*)message)->status ) ;    
    break;
    case HFP_DIAL_MEMORY_CFM:
        MAIN_DEBUG(("HFP_DIAL_MEMORY_CFM %d %d\n", stateManagerGetState(), ((HFP_DIAL_MEMORY_CFM_T *) message)->status));        
    break ;     
    case HFP_CALL_ANSWER_CFM:
        MAIN_DEBUG(("HFP_ANSWER_CALL_CFM\n"));
    break;
    case HFP_CALL_TERMINATE_CFM:
        MAIN_DEBUG(("HFP_TERMINATE_CALL_CFM %d\n", stateManagerGetState()));       
    break;
    case HFP_VOICE_RECOGNITION_IND:
        MAIN_DEBUG(("HS: HFP_VOICE_RECOGNITION_IND_T [%c]\n" ,TRUE_OR_FALSE( ((HFP_VOICE_RECOGNITION_IND_T* )message)->enable) )) ;            
            /*update the state of the voice dialling on the back of the indication*/
        theSink.VoiceRecognitionIsActive = ((HFP_VOICE_RECOGNITION_IND_T* ) message)->enable ;            
    break;
    case HFP_VOICE_RECOGNITION_ENABLE_CFM:
        MAIN_DEBUG(("HFP_VOICE_RECOGNITION_ENABLE_CFM s[%d] w[%d]i", (((HFP_VOICE_RECOGNITION_ENABLE_CFM_T *)message)->status ) , theSink.VoiceRecognitionIsActive));

            /*if the cfm is in error then we did not succeed - toggle */
        if  ( (((HFP_VOICE_RECOGNITION_ENABLE_CFM_T *)message)->status ) )
            theSink.VoiceRecognitionIsActive = 0 ;
            
        MAIN_DEBUG(("[%d]\n", theSink.VoiceRecognitionIsActive));
        
        handleHFPStatusCFM (((HFP_VOICE_RECOGNITION_ENABLE_CFM_T *)message)->status ) ;            
    break;
    case HFP_CALLER_ID_ENABLE_CFM:
        MAIN_DEBUG(("HFP_CALLER_ID_ENABLE_CFM\n"));
    break;
    case HFP_VOLUME_SYNC_SPEAKER_GAIN_IND:
    {
        HFP_VOLUME_SYNC_SPEAKER_GAIN_IND_T *ind = (HFP_VOLUME_SYNC_SPEAKER_GAIN_IND_T *) message;

        MAIN_DEBUG(("HFP_VOLUME_SYNC_SPEAKER_GAIN_IND %d\n", ind->volume_gain));        

        VolumeHandleSpeakerGainInd(ind);
    }
    break;
    case HFP_VOLUME_SYNC_MICROPHONE_GAIN_IND:
    {
        HFP_VOLUME_SYNC_MICROPHONE_GAIN_IND_T *ind = (HFP_VOLUME_SYNC_MICROPHONE_GAIN_IND_T*)message;
        MAIN_DEBUG(("HFP_VOLUME_SYNC_MICROPHONE_GAIN_IND %d\n", ind->mic_gain));
        if(theSink.features.EnableSyncMuteMicrophones)
        {
            VolumeSetMicrophoneGainCheckMute(ind->priority, ind->mic_gain);
        }
    }
    
    break;
    
    case HFP_CALLER_ID_IND:
        {
            HFP_CALLER_ID_IND_T *ind = (HFP_CALLER_ID_IND_T *) message;
 
            /* ensure this is not a HSP profile */
            MAIN_DEBUG(("HFP_CALLER_ID_IND number %s", ind->caller_info + ind->offset_number));
            MAIN_DEBUG((" name %s\n", ind->caller_info + ind->offset_name));
            
            /* Show name or number on display */
            if (ind->size_name)
                displayShowSimpleText((char *) ind->caller_info + ind->offset_name, 1);
            
            else
                displayShowSimpleText((char *) ind->caller_info + ind->offset_number, 1);
                
            /* Attempt to play caller name */
            if(!AudioPromptPlayCallerName (ind->size_name, ind->caller_info + ind->offset_name))
            {
                /* Caller name not present or not supported, try to play number */
                AudioPromptPlayCallerNumber(ind->size_number, ind->caller_info + ind->offset_number) ;
            }
        }
    
    break;           
    
    case HFP_UNRECOGNISED_AT_CMD_IND:
    {
        sinkHandleUnrecognisedATCmd( (HFP_UNRECOGNISED_AT_CMD_IND_T*)message ) ;
    }
    break ;

    case HFP_HS_BUTTON_PRESS_CFM:
        {
            MAIN_DEBUG(("HFP_HS_BUTTON_PRESS_CFM\n")) ;
        }
    break ;
     /*****************************************************************/

#ifdef THREE_WAY_CALLING    
    case HFP_CALL_WAITING_ENABLE_CFM :
            MAIN_DEBUG(("HS3 : HFP_CALL_WAITING_ENABLE_CFM_T [%c]\n", (((HFP_CALL_WAITING_ENABLE_CFM_T * )message)->status == hfp_success) ?'T':'F' )) ;
    break ;    
    case HFP_CALL_WAITING_IND:
        {
            /* pass the indication to the multipoint handler which will determine if the call waiting tone needs
               to be played, this will depend upon whether the indication has come from the AG with
               the currently routed audio */
            mpHandleCallWaitingInd((HFP_CALL_WAITING_IND_T *)message);
        }
    break;

#endif  
    case HFP_SUBSCRIBER_NUMBERS_CFM:
        MAIN_DEBUG(("HS3: HFP_SUBSCRIBER_NUMBERS_CFM [%c]\n" , (((HFP_SUBSCRIBER_NUMBERS_CFM_T*)message)->status == hfp_success)  ? 'T' :'F' )) ;
    break ;
    case HFP_SUBSCRIBER_NUMBER_IND:
#ifdef DEBUG_MAIN            
    {
        uint16 i=0;
            
        MAIN_DEBUG(("HS3: HFP_SUBSCRIBER_NUMBER_IND [%d]\n" , ((HFP_SUBSCRIBER_NUMBER_IND_T*)message)->service )) ;
        for (i=0;i< ((HFP_SUBSCRIBER_NUMBER_IND_T*)message)->size_number ; i++)
        {
            MAIN_DEBUG(("%c", ((HFP_SUBSCRIBER_NUMBER_IND_T*)message)->number[i])) ;
        }
        MAIN_DEBUG(("\n")) ;
    } 
#endif
    break ;
    case HFP_CURRENT_CALLS_CFM:
        MAIN_DEBUG(("HS3: HFP_CURRENT_CALLS_CFM [%c]\n", (((HFP_CURRENT_CALLS_CFM_T*)message)->status == hfp_success)  ? 'T' :'F' )) ;
    break ;
    case HFP_CURRENT_CALLS_IND:
        MAIN_DEBUG(("HS3: HFP_CURRENT_CALLS_IND id[%d] mult[%d] status[%d]\n" ,
                                        ((HFP_CURRENT_CALLS_IND_T*)message)->call_idx , 
                                        ((HFP_CURRENT_CALLS_IND_T*)message)->multiparty  , 
                                        ((HFP_CURRENT_CALLS_IND_T*)message)->status)) ;
    break;
    case HFP_AUDIO_CONNECT_IND:
        MAIN_DEBUG(("HFP_AUDIO_CONNECT_IND\n")) ;
        audioHandleSyncConnectInd( (HFP_AUDIO_CONNECT_IND_T *)message ) ;
    break ;
    case HFP_AUDIO_CONNECT_CFM:
        MAIN_DEBUG(("HFP_AUDIO_CONNECT_CFM[%x][%x][%s%s%s] r[%d]t[%d]\n", ((HFP_AUDIO_CONNECT_CFM_T *)message)->status ,
                                                      (int)((HFP_AUDIO_CONNECT_CFM_T *)message)->audio_sink ,
                                                      ((((HFP_AUDIO_CONNECT_CFM_T *)message)->link_type == sync_link_sco) ? "SCO" : "" )      ,  
                                                      ((((HFP_AUDIO_CONNECT_CFM_T *)message)->link_type == sync_link_esco) ? "eSCO" : "" )    ,
                                                      ((((HFP_AUDIO_CONNECT_CFM_T *)message)->link_type == sync_link_unknown) ? "unk?" : "" ) ,
                                                      (int)((HFP_AUDIO_CONNECT_CFM_T *)message)->rx_bandwidth ,
                                                      (int)((HFP_AUDIO_CONNECT_CFM_T *)message)->tx_bandwidth 
                                                      )) ;
        /* should the device receive a sco connect cfm in limbo state */
        if (stateManagerGetState() == deviceLimbo)
        {
            /* confirm that it connected successfully before disconnecting it */
            if (((HFP_AUDIO_CONNECT_CFM_T *)message)->status == hfp_audio_connect_no_hfp_link)
            {
                MAIN_DEBUG(("HFP_AUDIO_CONNECT_CFM in limbo state, disconnect it\n" ));
                ConnectionSyncDisconnect(((HFP_AUDIO_CONNECT_CFM_T *)message)->audio_sink, hci_error_oetc_user);
            }
        }
        /* not in limbo state, process sco connect indication */
        else
        {      
            audioHandleSyncConnectCfm((HFP_AUDIO_CONNECT_CFM_T *)message);            
        }               
    break ;
    case HFP_AUDIO_DISCONNECT_IND:
        MAIN_DEBUG(("HFP_AUDIO_DISCONNECT_IND [%x]\n", ((HFP_AUDIO_DISCONNECT_IND_T *)message)->status)) ;
        audioHandleSyncDisconnectInd ((HFP_AUDIO_DISCONNECT_IND_T *)message) ;
    break ;
    case HFP_SIGNAL_IND:
        MAIN_DEBUG(("HS: HFP_SIGNAL_IND [%d]\n", ((HFP_SIGNAL_IND_T* )message)->signal )) ; 
    break ;
    case HFP_ROAM_IND:
        MAIN_DEBUG(("HS: HFP_ROAM_IND [%d]\n", ((HFP_ROAM_IND_T* )message)->roam )) ;
    break; 
    case HFP_BATTCHG_IND:     
        MAIN_DEBUG(("HS: HFP_BATTCHG_IND [%d]\n", ((HFP_BATTCHG_IND_T* )message)->battchg )) ;
    break;
    
/*******************************************************************/
    
    case HFP_CSR_FEATURES_TEXT_IND:
        csr2csrHandleTxtInd () ;
    break ;
    
    case HFP_CSR_FEATURES_NEW_SMS_IND:
       csr2csrHandleSmsInd () ;   
    break ;
    
    case HFP_CSR_FEATURES_GET_SMS_CFM:
       csr2csrHandleSmsCfm() ;
    break ;
    
    case HFP_CSR_FEATURES_BATTERY_LEVEL_REQUEST_IND:
       csr2csrHandleAgBatteryRequestInd() ;
    break ;
    
/*******************************************************************/
    
/*******************************************************************/

    /*******************************/
    
    default :
        MAIN_DEBUG(("HS :  HFP ? [%x]\n",id)) ;
    break ;
    }
}

/*************************************************************************
NAME    
    handleCodecMessage
    
DESCRIPTION
    handles the codec Messages

RETURNS
    
*/
static void handleCodecMessage  ( Task task, MessageId id, Message message )
{
    MAIN_DEBUG(("CODEC MSG received [%x]\n", id)) ;
      
    if (id == CODEC_INIT_CFM ) 
    {       /* The codec is now initialised */
    
        if ( ((CODEC_INIT_CFM_T*)message)->status == codec_success) 
        {
            MAIN_DEBUG(("CODEC_INIT_CFM\n"));   
            sinkHfpInit();
            theSink.codec_task = ((CODEC_INIT_CFM_T*)message)->codecTask ;                   
        }
        else
        {
            Panic();
        }
    }
}

/* Handle any audio plugin messages */
static void handleAudioPluginMessage( Task task, MessageId id, Message message )
{
    switch (id)
    {        
        case AUDIO_PLUGIN_DSP_IND:
            /* Clock mismatch rate, sent from the DSP via the a2dp decoder common plugin? */
            if (((AUDIO_PLUGIN_DSP_IND_T*)message)->id == KALIMBA_MSG_SOURCE_CLOCK_MISMATCH_RATE)
            {
                handleA2DPStoreClockMismatchRate(((AUDIO_PLUGIN_DSP_IND_T*)message)->value[0]);
            }
            /* Current EQ bank, sent from the DSP via the a2dp decoder common plugin? */
            else if (((AUDIO_PLUGIN_DSP_IND_T*)message)->id == A2DP_MUSIC_MSG_CUR_EQ_BANK)
            {
                handleA2DPStoreCurrentEqBank(((AUDIO_PLUGIN_DSP_IND_T*)message)->value[0]);
            }
            /* Current enhancements, sent from the DSP via the a2dp decoder common plugin? */
            else if (((AUDIO_PLUGIN_DSP_IND_T*)message)->id == A2DP_MUSIC_MSG_ENHANCEMENTS)
            {
                handleA2DPStoreEnhancements(((~((AUDIO_PLUGIN_DSP_IND_T*)message)->value[1]) & (MUSIC_CONFIG_SUB_WOOFER_BYPASS|MUSIC_CONFIG_BASS_BOOST_BYPASS|MUSIC_CONFIG_SPATIAL_BYPASS|MUSIC_CONFIG_USER_EQ_BYPASS)));
            }
        break;
            
        /* indication that the DSP is ready to accept data ensuring no audio samples are disposed of */    
        case AUDIO_PLUGIN_DSP_READY_FOR_DATA:
            /* ensure dsp is up and running */
        
#if defined ENABLE_GAIA && defined ENABLE_GAIA_PERSISTENT_USER_EQ_BANK
            handleA2DPUserEqBankUpdate();
#endif

            if(((AUDIO_PLUGIN_DSP_READY_FOR_DATA_T*)message)->dsp_status == DSP_RUNNING)
            {
                MAIN_DEBUG(("HS :  DSP ready for data\n")) ;
#ifdef ENABLE_PEER                
                /*Request the connected peer device to send its current user EQ settings across if its a peer source.*/
                peerRequestUserEqSetings();
#endif
            }
            
#ifdef ENABLE_SUBWOOFER     
            /* configure the subwoofer type when the dsp is up and running */
            if(SwatGetMediaType(theSink.rundata->subwoofer.dev_id) == SWAT_MEDIA_STANDARD)            
                AudioConfigureSubWoofer(AUDIO_SUB_WOOFER_L2CAP, SwatGetMediaSink(theSink.rundata->subwoofer.dev_id));    
            else if(SwatGetMediaType(theSink.rundata->subwoofer.dev_id) == SWAT_MEDIA_LOW_LATENCY)                            
                AudioConfigureSubWoofer(AUDIO_SUB_WOOFER_ESCO, SwatGetMediaSink(theSink.rundata->subwoofer.dev_id));    
#endif            
        break;

#ifdef ENABLE_GAIA

        case AUDIO_PLUGIN_DSP_GAIA_EQ_MSG:
        {
            uint8 payload[4];
            payload[0] = (((AUDIO_PLUGIN_DSP_GAIA_EQ_MSG_T*)message)->value[0]) >> 8;
            payload[1] = (((AUDIO_PLUGIN_DSP_GAIA_EQ_MSG_T*)message)->value[0]) & 0x00ff;
            payload[2] = (((AUDIO_PLUGIN_DSP_GAIA_EQ_MSG_T*)message)->value[1]) >> 8;
            payload[3] = (((AUDIO_PLUGIN_DSP_GAIA_EQ_MSG_T*)message)->value[1]) & 0x00ff;
            gaia_send_response(GAIA_VENDOR_CSR, GAIA_COMMAND_GET_USER_EQ_PARAMETER, GAIA_STATUS_SUCCESS, 4, payload);
        }
        break;
        
        case AUDIO_PLUGIN_DSP_GAIA_GROUP_EQ_MSG:
        {
            uint8 payloadSize = ((AUDIO_PLUGIN_DSP_GAIA_GROUP_EQ_MSG_T*)message)->size_value;
            uint16 *payload = mallocPanic(payloadSize);
            if (payload)
            {
                memcpy(payload,((AUDIO_PLUGIN_DSP_GAIA_GROUP_EQ_MSG_T*)message)->value,payloadSize);
                gaia_send_response_16(GAIA_COMMAND_GET_USER_EQ_GROUP_PARAMETER,
                                  GAIA_STATUS_SUCCESS,
                                  payloadSize,
                                  payload);
                free(payload);
            }
        }
        break;
#endif    /* ENABLE_GAIA */
      
		case AUDIO_PLUGIN_LATENCY_REPORT:
			handleA2DPLatencyReport(((AUDIO_PLUGIN_LATENCY_REPORT_T *)message)->audio_plugin, ((AUDIO_PLUGIN_LATENCY_REPORT_T *)message)->estimated, ((AUDIO_PLUGIN_LATENCY_REPORT_T *)message)->latency);
		break;
        
        case AUDIO_PLUGIN_REFRESH_VOLUME:
        {
            MAIN_DEBUG(("HS :  AUDIO Refresh volume\n")) ;
            VolumeCheckA2dp(same_volume); 
        }
        break;
		
        default:
            MAIN_DEBUG(("HS :  AUDIO ? [%x]\n",id)) ;
        break ;           
    }   
}

#ifdef ENABLE_DISPLAY
/* Handle any display plugin messages */
static void handleDisplayPluginMessage( Task task, MessageId id, Message message )
{
    switch (id)
    {        
    case DISPLAY_PLUGIN_INIT_IND:
        {
            DISPLAY_PLUGIN_INIT_IND_T *m = (DISPLAY_PLUGIN_INIT_IND_T *) message;
            MAIN_DEBUG(("HS :  DISPLAY INIT: %u\n", m->result));
            if (m->result)
            {
                if (powerManagerIsChargerConnected() && (stateManagerGetState() == deviceLimbo) )
                {
                    /* indicate charging if in limbo */
                    displaySetState(TRUE);
                    displayShowText(DISPLAYSTR_CHARGING,  strlen(DISPLAYSTR_CHARGING), 2, DISPLAY_TEXT_SCROLL_SCROLL, 1000, 2000, FALSE, 0);
                    displayUpdateVolume(0); 
                    displayUpdateBatteryLevel(TRUE);  
                }
                else if (stateManagerGetState() != deviceLimbo)
                {          
                    /* if this init occurs and not in limbo, turn the display on */
                    displaySetState(TRUE);                    
                    displayShowText(DISPLAYSTR_HELLO,  strlen(DISPLAYSTR_HELLO), 2, DISPLAY_TEXT_SCROLL_SCROLL, 1000, 2000, FALSE, 10);
                    displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * theSink.features.DefaultVolume)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
                    /* update battery display */
                    displayUpdateBatteryLevel(FALSE); 
                }                             
            }
        }
        break;
        
    default:
        MAIN_DEBUG(("HS :  DISPLAY ? [%x]\n",id)) ;
        break ;           
    }   
}
#endif /* ENABLE_DISPLAY */

#ifdef ENABLE_FM
/* Handle any FM plugin messages */
static void handleFmPluginMessage(Task task, MessageId id, Message message)
{
    switch (id)
    {        
        /* received when the FM hardware has been initialised and tuned to the
           last used frequency */
        case FM_PLUGIN_INIT_IND:
        {
            FM_PLUGIN_INIT_IND_T *m = (FM_PLUGIN_INIT_IND_T*) message;
            MAIN_DEBUG(("HS: FM INIT: %d\n", m->result));

            if (m->result)
            {
                /* set the fm receiver hardware to default volume level (0x3F) */
                sinkFmRxUpdateVolume(theSink.volume_levels->fm_volume.masterVolume);
                /* set flag to indicate FM audio is now available */
                theSink.conf2->sink_fm_data.fmRxOn=TRUE;
                /* connect the FM audio if no other audio sources are avilable */
                audioHandleRouting(audio_source_none);
            }
        }
        break;

        /* received when tuning is complete, the frequency tunes to is returned
           within the message, this is stored in persistant store */
        case FM_PLUGIN_TUNE_COMPLETE_IND:
        {
            FM_PLUGIN_TUNE_COMPLETE_IND_T *m = (FM_PLUGIN_TUNE_COMPLETE_IND_T*) message;
            MAIN_DEBUG(("HS: FM_PLUGIN_TUNE_COMPLETE_IND: %d\n", m->result));

            if (m->result)
            {            
                /* valid the returned frequency and store for later writing to ps session data */
                if (m->tuned_freq!=0x0000) 
                {
                    theSink.conf2->sink_fm_data.fmRxTunedFreq=m->tuned_freq;

                    /*Display new frequency, clear older display*/
#ifdef ENABLE_DISPLAY  
                    {                            
                        /*If the freq is stored in the Ps key, add special char for user to identify as favourite station */
                        uint8 index=0;
                        fm_display_type type=FM_SHOW_STATION;

                        for (index=0;index<FM_MAX_PRESET_STATIONS;index++)                   
                        {
                            if (theSink.conf2->sink_fm_data.fmStoredFreq.freq[index]==m->tuned_freq)
                            {
                                type=FM_ADD_FAV_STATION;
                                break;
                            }
                        }

                        /*Display frequency*/
                        sinkFmDisplayFreq(m->tuned_freq, type);
                    }
#endif                  
                }
                MAIN_DEBUG(("FM RX currently tuned to freq (0x%x) (%d) \n", theSink.conf2->sink_fm_data.fmRxTunedFreq, 
                                                                            theSink.conf2->sink_fm_data.fmRxTunedFreq));
            }
        }
        break;

#ifdef ENABLE_FM_RDS

        /*Display RDS info*/
        case FM_PLUGIN_RDS_IND:
        {
#ifdef ENABLE_DISPLAY    
            FM_PLUGIN_RDS_IND_T *m = (FM_PLUGIN_RDS_IND_T*) message;
            MAIN_DEBUG(("HS: FM_PLUGIN_RDS_IND \n"));

            if ((m->data_len > 0) && (m->data != NULL))
            {
                MAIN_DEBUG(("HS:  data from msg (%s) (%d) \n", m->data, m->data_len));

                switch (m->rds_type)
                {
                    case FMRX_RDS_PROGRAM_SERVICE:
                        {
                            MAIN_DEBUG(("HS: PS data %s \n", m->data));
                            displayShowText((char*) m->data,  m->data_len,  2, DISPLAY_TEXT_SCROLL_STATIC, 500, 2000, FALSE, 0);
                        }
                        break;

                    case FMRX_RDS_RADIO_TEXT:
                        {
                            MAIN_DEBUG(("HS: RT data %s \n", m->data));
                            displayShowText((char*) m->data,  m->data_len,  2, DISPLAY_TEXT_SCROLL_SCROLL, 500, 2000, FALSE, 50);
                        }
                        break;

                    case FMRX_RDS_PROGRAM_TYPE:
                        {
                            MAIN_DEBUG(("HS: Program Type %s \n", m->data));
                            displayShowText((char*) m->data,  m->data_len,  2, DISPLAY_TEXT_SCROLL_SCROLL, 500, 2000, FALSE, 50);
                        }
                        break;

                    default:
                        break;                        
                }
            }

#endif
        }
        break;

#endif /*ENABLE_FM_RDS*/


        
        default:
        MAIN_DEBUG(("HS :  FM unhandled msg [%x]\n",id)) ;
        break ;           
    }   
}
#endif /* ENABLE_FM */


/*************************************************************************
NAME    
    app_handler
    
DESCRIPTION
    This is the main message handler for the Sink Application.  All
    messages pass through this handler to the subsequent handlers.

RETURNS

*/
static void app_handler(Task task, MessageId id, Message message)
{
/*    MAIN_DEBUG(("MSG [%x][%x][%x]\n", (int)task , (int)id , (int)&message)) ;*/
    
    /* determine the message type based on base and offset */
    if ( ( id >= EVENTS_MESSAGE_BASE ) && ( id <= EVENTS_LAST_EVENT ) )
    {
        handleUEMessage(task, id,  message);          
    }
    else  if ( (id >= CL_MESSAGE_BASE) && (id <= CL_MESSAGE_TOP) )
    {
        handleCLMessage(task, id,  message);        
    #ifdef TEST_HARNESS 
        vm2host_connection(task, id, message);
    #endif 
    }
    else if ( (id >= HFP_MESSAGE_BASE ) && (id <= HFP_MESSAGE_TOP) )
    {     
        handleHFPMessage(task, id,  message);     
    #ifdef TEST_HARNESS 
        vm2host_hfp(task, id, message);
    #endif 
    }    
    else if ( (id >= CODEC_MESSAGE_BASE ) && (id <= CODEC_MESSAGE_TOP) )
    {     
        handleCodecMessage (task, id, message) ;     
    }
    else if ( (id >= POWER_MESSAGE_BASE ) && (id <= POWER_MESSAGE_TOP) )
    {     
        handlePowerMessage (task, id, message) ;     
    }
#ifdef ENABLE_PBAP    
    else if ( ((id >= PBAPC_MESSAGE_BASE ) && (id <= PBAPC_MESSAGE_TOP)) ||
              ((id >= PBAPC_APP_MSG_BASE ) && (id <= PBAPC_APP_MSG_TOP)) )
    {     
        handlePbapMessages (task, id, message) ;     
    }
#endif
#ifdef ENABLE_MAPC 
    else if ( ((id >= MAPC_MESSAGE_BASE )    && (id <= MAPC_API_MESSAGE_END)) ||
              ((id >= MAPC_APP_MESSAGE_BASE) && (id <= MAPC_APP_MESSAGE_TOP)) )
    {     
        handleMapcMessages (task, id, message) ;     
    }    
#endif
#ifdef ENABLE_AVRCP
    else if ( (id >= AVRCP_INIT_CFM ) && (id <= SINK_AVRCP_MESSAGE_TOP) )
    {     
        sinkAvrcpHandleMessage (task, id, message) ;     
    #ifdef TEST_HARNESS 
        vm2host_avrcp(task, id, message);
    #endif 
    }
#endif
    
#ifdef CVC_PRODTEST
    else if (id == MESSAGE_FROM_KALIMBA)
    {
        cvcProductionTestKalimbaMessage (task, id, message);
    }
#endif
    else if ( (id >= A2DP_MESSAGE_BASE ) && (id <= A2DP_MESSAGE_TOP) )
    {     
        handleA2DPMessage(task, id,  message);
    #ifdef TEST_HARNESS 
        vm2host_a2dp(task, id, message);
    #endif 
        return;
    }
    else if ( (id >= AUDIO_UPSTREAM_MESSAGE_BASE ) && (id <= AUDIO_UPSTREAM_MESSAGE_TOP) )
    {     
        handleAudioPluginMessage(task, id,  message);
        return;
    }    
    else if( ((id >= MESSAGE_USB_ENUMERATED) && (id <= MESSAGE_USB_SUSPENDED)) || 
             ((id >= MESSAGE_USB_DECONFIGURED) && (id <= MESSAGE_USB_DETACHED)) ||
             ((id >= USB_DEVICE_CLASS_MSG_BASE) && (id <= USB_DEVICE_CLASS_MSG_TOP)) )
    {
        handleUsbMessage(task, id, message);
        return;
    }
#ifdef ENABLE_GAIA
    else if ((id >= GAIA_MESSAGE_BASE) && (id < GAIA_MESSAGE_TOP))
    {
        handleGaiaMessage(task, id, message);
        return;
    }
    else if (id == MESSAGE_DFU_SQIF_STATUS)
    {
        handleDfuSqifStatus((MessageDFUFromSQifStatus *) message);
        return;
    }
#endif
#ifdef ENABLE_DISPLAY    
    else if ( (id >= DISPLAY_UPSTREAM_MESSAGE_BASE ) && (id <= DISPLAY_UPSTREAM_MESSAGE_TOP) )
    {     
        handleDisplayPluginMessage(task, id,  message);
        return;
    }      
#endif   /* ENABLE DISPLAY */   
#ifdef ENABLE_SUBWOOFER
    else if ( (id >= SWAT_MESSAGE_BASE) && (id <= SWAT_MESSAGE_TOP) )
    {
        handleSwatMessage(task, id, message);
        return;
    }
#endif /* ENABLE_SUBWOOFER */
#ifdef ENABLE_FM  
    else if ( (id >= FM_UPSTREAM_MESSAGE_BASE ) && (id <= FM_UPSTREAM_MESSAGE_TOP) )
    {     
        handleFmPluginMessage(task, id, message);
        return;
    }      
#endif /* ENABLE_FM */    
    else 
    { 
        MAIN_DEBUG(("MSGTYPE ? [%x]\n", id)) ;
    }       
}

/* Time critical initialisation */
void _init(void)
{
    /* Set the application task */
    theSink.task.handler = app_handler;

    /* set flag to indicate that configuration is being read, use to prevent use of variables
       prior to completion of initialisation */
    theSink.SinkInitialising = TRUE;
    /* Read in any PIOs required */   
    configManagerPioMap();
    /* Time critical USB setup */
    usbTimeCriticalInit();    
}


/* The Sink Application starts here...*/
int main(void)
{
    DEBUG (("Main [%s]\n",__TIME__));

    /* check and update as necessary the software version pskey, this is used for ensuring maximum
       compatibility with the sinkg configuration tool */
    configManagerSetVersionNo();

    /* Initialise memory required early */
    configManagerInitMemory();

    /* Retrieve device state prior to reset */
    theSink.rundata->old_state = BootGetPreservedWord();

    /* initialise memory for the led manager */
    LedManagerMemoryInit();
    LEDManagerInit( ) ;

    /* Initialise device state */
    AuthResetConfirmationFlags();
    
    /*the internal regs must be latched on (smps and LDO)*/
    PioSetPowerPin ( TRUE ) ;

    switch (BootGetMode() )
    {
#ifdef CVC_PRODTEST 
        case BOOTMODE_CVC_PRODTEST:
            /*run the cvc prod test code and dont start the applicaiton */
            cvcProductionTestEnter() ;
        break ;
#endif        
        case BOOTMODE_DFU:
            /*do nothing special for the DFU boot mode, 
            This mode expects to have the appropriate host interfface enabled 
            Don't start the application */

            /* Initializing only the system components required for flashing the led pattern in the DFU mode*/
            configManagerInit(FALSE);
            LEDManagerIndicateEvent(EventUsrEnterDFUMode);
        break ;
        
        case BOOTMODE_DEFAULT:
        case BOOTMODE_CUSTOM:         
        case BOOTMODE_USB_LOW_POWER:  
        case BOOTMODE_ALT_FSTAB:  
        default:
        {
            /*the above are application boot modes so kick of the app init routines*/
            const msg_filter MsgFilter = {msg_group_acl};           
            
            /* read the lengths key into a temporary malloc to get pdl length */
            lengths_config_type * lengths_key = PanicUnlessMalloc(sizeof(lengths_config_type));
            
            /* The number of paired devices can be restricted using pskey user 40,  a number between 1 and 8 is allowed */
            ConfigRetrieve(CONFIG_LENGTHS, lengths_key , sizeof(lengths_config_type) );
          
            DEBUG (("PDLSize[%d]\n" , lengths_key->pdl_size ));

            /* Initialise the Connection Library with the options */
            ConnectionInitEx2(&theSink.task , &MsgFilter , lengths_key->pdl_size );

            /* free the malloc'd memory */
            free(lengths_key);
            
            #ifdef TEST_HARNESS
                test_init();
            #endif
        }
        break ;
    }
        /* Start the message scheduler loop */
    MessageLoop();
        /* Never get here...*/
    return 0;  
}



#ifdef DEBUG_MALLOC 

#include "vm.h"
void * MallocPANIC ( const char file[], int line , size_t pSize )
{    
    static uint16 lSize = 0 ;
    static uint16 lCalls = 0 ;
    void * lResult;
 
    lCalls++ ;
    lSize += pSize ;    
    printf("+%s,l[%d]c[%d] t[%d] a[%d] s[%d]",file , line ,lCalls, lSize , (uint16)VmGetAvailableAllocations(), pSize ); 
                
    lResult = malloc ( pSize ) ;
     
    printf("@[0x%x]\n", (uint16)lResult);
    
        /*and panic if the malloc fails*/
    if ( lResult == NULL )
    {
        printf("MA : !\n") ;
        Panic() ;
    }
    
    return lResult ; 
                
}

void FreePANIC ( const char file[], int line, void * ptr ) 
{
    static uint16 lCalls = 0 ;    
    lCalls++ ; 
    printf("-%s,l[%d]c[%d] a[%d] @[0x%x]\n",file , line ,lCalls, (uint16)VmGetAvailableAllocations()-1, (uint16)ptr); 
    /* panic if attempting to free a null pointer*/
    if ( ptr == NULL )
    {
        printf("MF : !\n") ;
        Panic() ;
    }
    free( ptr ) ;    
}
#endif

/*************************************************************************
NAME    
    sinkInitCodecTask
    
DESCRIPTION
    Initialises the codec task

RETURNS

*/
static void sinkInitCodecTask ( void ) 
{
    /* The Connection Library has been successfully initialised, 
       initialise the HFP library to instantiate an instance of both
       the HFP and the HSP */
                   
    /*init the codec task*/     	
    CodecInitCsrInternal (&theSink.rundata->codec, &theSink.task) ;
}

/*************************************************************************
NAME    
    storeCurrentSinkVolume
    
DESCRIPTION
    Stores the current volume level of the sink which is streaming audio (HFP or A2DP)

RETURNS

*/
static void storeCurrentSinkVolume( void )
{

    /* We should figure out the currently streaming sink device and the profile (HF or A2DP) it's conneced to */

    Sink sink_hf_pri, sink_hf_sec;
    uint8 index;
    typed_bdaddr SrcAddr;
    /* get current audio status */
    audio_source_status * lAudioStatus = audioGetStatus(theSink.routed_audio);

     /* check both possible instances of a2dp connection and store the volume information of the appropriate instance */
    for(index = a2dp_primary; index <= a2dp_secondary; index++)
    {
        /* is a2dp connected? */
        if(theSink.a2dp_link_data->connected[index])
        {
            /* check whether the a2dp connection is present and streaming data and that the audio is routed */
            if(theSink.routed_audio && (theSink.routed_audio == A2dpMediaGetSink(theSink.a2dp_link_data->device_id[index], theSink.a2dp_link_data->stream_id[index])))
            {
                SinkGetBdAddr(theSink.routed_audio, &SrcAddr);
                deviceManagerUpdateAttributes(&SrcAddr.addr, sink_a2dp, 0, index);
            }
        }
    }

   /* Check for the active SCO connection and store the volume information appropriately */
    if( audioActiveCallScoAvailable(lAudioStatus, hfp_primary_link))
    {
        HfpLinkGetSlcSink(hfp_primary_link, &sink_hf_pri);
        SinkGetBdAddr(sink_hf_pri, &SrcAddr);
        deviceManagerUpdateAttributes(&SrcAddr.addr, sink_hfp, hfp_primary_link, 0);        
    }

    if( audioActiveCallScoAvailable(lAudioStatus, hfp_secondary_link))
    {
        HfpLinkGetSlcSink(hfp_secondary_link, &sink_hf_sec);
        SinkGetBdAddr(sink_hf_sec, &SrcAddr);
        deviceManagerUpdateAttributes(&SrcAddr.addr, sink_hfp, hfp_secondary_link, 0); 
    }

    /* free malloc'd status memory slot */
    freePanic(lAudioStatus);   

}


/*************************************************************************
NAME    
    handleHFPStatusCFM
    
DESCRIPTION
    Handles a status response from the HFP and sends an error message if one was received

RETURNS

*/
static void handleHFPStatusCFM ( hfp_lib_status pStatus ) 
{
    if (pStatus != hfp_success )
    {
        MAIN_DEBUG(("HS: HFP CFM Err [%d]\n" , pStatus)) ;
        MessageSend ( &theSink.task , EventSysError , 0 ) ;
#ifdef ENABLE_PBAP
        if(theSink.pbapc_data.pbap_command == pbapc_dialling)
        {
            MessageSend ( &theSink.task , EventSysPbapDialFail , 0 ) ; 
        } 
#endif        
    }
    else
    {
         MAIN_DEBUG(("HS: HFP CFM Success [%d]\n" , pStatus)) ;
    }

#ifdef ENABLE_PBAP
    theSink.pbapc_data.pbap_command = pbapc_action_idle;
#endif
}



