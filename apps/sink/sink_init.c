/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_init.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_init.h"
#include "sink_config.h"
#include "sink_statemanager.h"
#include "sink_led_manager.h"
#include "sink_tones.h"
#include "sink_dut.h"
#include "charger.h"
#include "sink_a2dp.h"
#include "sink_audio_prompts.h"
#include "sink_buttons.h"
#include "sink_slc.h"
#include "sink_callmanager.h"
#include "sink_display.h"
#include "sink_device_id.h"
#include "sink_powermanager.h"
#include "sink_wired.h"
#include "sink_debug.h"
#include "sink_volume.h"
#include "sink_peer.h"
#include "audio_plugin_common.h"
#include "sink_swat.h"


#include <ps.h>
#include <stdio.h>
#include <connection.h>
#include <hfp.h>
#include <pio.h>
#include <panic.h>
#include <stdlib.h>
#include <string.h>
#include <vm.h>
#include <codec.h>
#include <swat.h>


#ifdef DEBUG_INIT
#define INIT_DEBUG(x) DEBUG(x)
#else
#define INIT_DEBUG(x) 
#endif


/* PS keys */
#define PS_BDADDR           (0x001)
#define PS_HFP_POWER_TABLE  (0x360)


/****************************************************************************
NAME    
    SetupPowerTable

DESCRIPTION
    Attempts to obtain a low power table from the Ps Key store.  If no table 
    (or an incomplete one) is found in Ps Keys then the default is used.
    
RETURNS
    void
*/
void SetupPowerTable( void )
{
    uint16 size_ps_key;
    power_table *PowerTable;
    
    /* obtain the size of memory in words required to hold the contents of the pskey */
    size_ps_key = PsFullRetrieve(PS_HFP_POWER_TABLE, NULL, 0);

    /* initialise user power table */
    theSink.user_power_table = 0;

    /* check whether any pskey data exists */    
    if (size_ps_key)
    {
        /* malloc storage for power table entries */ 
        PowerTable = (power_table*)mallocPanic(size_ps_key);
        
        /* attempt to retrieve all power table entries from ps */
        size_ps_key = PsFullRetrieve(PS_HFP_POWER_TABLE, PowerTable, ((sizeof(lp_power_table) * MAX_POWER_TABLE_ENTRIES) + sizeof(uint16)));
     
        /* sanity check the number of entried and length of pskey data to ensure entries are complete */
        if(size_ps_key == ((sizeof(lp_power_table)*PowerTable->normalEntries)+
                           (sizeof(lp_power_table)*PowerTable->SCOEntries)+
                           (sizeof(lp_power_table)*PowerTable->A2DPStreamEntries)+                                 
                           (sizeof(uint16)))
          )
        {   
            /* Use user defined power table */
            theSink.user_power_table = PowerTable;
            /* pskey format is correct */
            INIT_DEBUG(("User Power Table - Norm[%x] Sco[%x] Stream[%x]\n",PowerTable->normalEntries,PowerTable->SCOEntries,PowerTable->A2DPStreamEntries));
        }
        else
        {   /* No/incorrect power table defined in Ps Keys - use default table */
            freePanic(PowerTable);
            PowerTable = NULL;
            INIT_DEBUG(("No User Power Table\n"));
        }
    }
    
}


/****************************************************************************
NAME    
    sinkHfpInit
    
DESCRIPTION
    Initialise HFP library

RETURNS
    void
*/

void sinkHfpInit( void )
{
    hfp_init_params hfp_params;
    
    memset(&hfp_params, 0, sizeof(hfp_init_params));
    
    sinkClearQueueudEvent(); 
    
    /* get the extra hfp supported features such as supported sco packet types 
       from pskey user 5 */
    configManagerHFP_SupportedFeatures();

    /* initialise the hfp library with parameters read from config*/    
    configManagerHFP_Init(&hfp_params);  
    
    theSink.hfp_profiles = hfp_params.supported_profile;
    
    /* store the link loss time in the app */
    theSink.linkLossReminderTime = hfp_params.link_loss_interval;

    /* initialise hfp library with pskey read configuration */
    HfpInit(&theSink.task, &hfp_params, NULL);
    
    /* initialise the audio library, uses one malloc slot */
    AudioLibraryInit();
}

/****************************************************************************
NAME    
    sinkInitComplete
    
DESCRIPTION
    Sink device initialisation has completed. 

RETURNS
    void
*/
void sinkInitComplete( const HFP_INIT_CFM_T *cfm )
{
    uint8 i;
    /* Make sure the profile instance initialisation succeeded. */
    if (cfm->status == hfp_init_success)
    {
        /* initialise connection status for this instance */            
        for(i=0;i<2;i++)
        {
            theSink.profile_data[i].status.list_id = INVALID_LIST_ID;
            theSink.a2dp_link_data->list_id[i] = INVALID_LIST_ID;
        }                
        
        /* Disable SDP security */
        ConnectionSmSetSecurityLevel(protocol_l2cap,1,ssp_secl4_l0,TRUE,FALSE,FALSE);
        
        /* WAE - no ACL, Debug keys - off, Legacy pair key missing - on */
        ConnectionSmSecModeConfig(&theSink.task, cl_sm_wae_acl_none, FALSE, TRUE);
        
        /* Require MITM on the MUX (incomming and outgoing)*/
        if(theSink.features.ManInTheMiddle)
        {
            ConnectionSmSetSecurityLevel(0,3,ssp_secl4_l3,TRUE,TRUE,FALSE);
        }          
            
        RegisterDeviceIdServiceRecord();

#ifdef ENABLE_PEER
        RegisterPeerDeviceServiceRecord();
        peerInitPeerStatus();
#endif
        
        /* Initialise Inquiry Data to NULL */
        theSink.inquiry.results = NULL;     
        
#ifdef ENABLE_AVRCP     
        /* initialise the AVRCP library */    
        sinkAvrcpInit();       
#endif

#ifdef ENABLE_SUBWOOFER
        /* Initialise the swat the library - Use library default service record - Library does not auto handles messages */
        if ( (theSink.rundata->subwoofer.esco_params.tx_bandwidth == 0) &&
             (theSink.rundata->subwoofer.esco_params.rx_bandwidth == 0) &&
             (theSink.rundata->subwoofer.esco_params.max_latency == 0) )
        {
            /* Use library default eSCO parameters */
            SwatInit(&theSink.task, SW_MAX_REMOTE_DEVICES, swat_role_source, FALSE, 0, 0, NULL);
        }
        else
        {
            /* Use custom eSCO parameters from configuration data */
            SwatInit(&theSink.task, SW_MAX_REMOTE_DEVICES, swat_role_source, FALSE, 0, 0, &theSink.rundata->subwoofer.esco_params);
        }
#endif

        /* No audio sources are gated at startup */
        theSink.gated_audio = 0;
        
        /*if we receive the init message in the correct state*/    
        if ( stateManagerGetState() == deviceLimbo )
        {                                           
#ifdef ENABLE_PBAP                      
            /* If hfp has been initialised successfully, start initialising PBAP */                 
            INIT_DEBUG(("INIT: PBAP Init start\n"));                     
            initPbap();
#else
            /*init the configurable parameters*/
            InitUserFeatures();                   
#endif        
        }

        /* try to get a power table entry from ps if one exists after having read the user features as
           A2DP enable state is used to determine size of power table entry */
        SetupPowerTable();
        
        
#ifdef ENABLE_MAPC
        /* if the map feature is enabled, start the map notification service at initialisation time */
        initMap();       
#endif        

        /* disable automatic mic bias control as this is handled by the audio plugins */
        AudioPluginSetMicPio(theSink.conf1->PIOIO.digital.mic_a, FALSE);
        AudioPluginSetMicPio(theSink.conf1->PIOIO.digital.mic_b, FALSE);

    }
    else
        /* If the profile initialisation has failed then things are bad so panic. */
        Panic();
    

    /* initialisation is complete */    
    theSink.SinkInitialising = FALSE;

}


/*************************************************************************
NAME    
    InitPreAmp
    
DESCRIPTION
    Enable the Pre Amp if configured to do so
    
    channel contains the audio channel that you want to enable the pre amp on 
    
RETURNS

*/
static void initPreAmp( audio_channel channel )
{
    Source source = NULL ;
    source = StreamAudioSource(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, channel);
    
    if( ((channel == AUDIO_CHANNEL_A) && (theSink.conf1->PIOIO.digital.mic_a.pre_amp)) || 
        ((channel == AUDIO_CHANNEL_B)&& (theSink.conf1->PIOIO.digital.mic_b.pre_amp)) )
    {
        /* Use the microphone pre-amp */
        if(!SourceConfigure(source, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE,TRUE ))
        {    
            INIT_DEBUG(("INIT: Init Pre Amp FAIL [%x]\n" , (int)channel )) ;
        }
   }
   
    /* Close the Source*/
    SourceClose(source);
}


/*************************************************************************
NAME    
    InitEarlyUserFeatures
    
DESCRIPTION
    This function initialises the configureation that is required early 
    on in the start-up sequence. 

RETURNS

*/
void InitEarlyUserFeatures ( void ) 
{   
    ChargerConfigure(CHARGER_SUPPRESS_LED0, TRUE);
    
        
    /* Initialise the Button Manager */
    buttonManagerInit() ;  
        
    /* Once system Managers are initialised, load up the configuration */
    configManagerInit(TRUE);   
    
    /* Init wired before USB or wired audio gets routed before init */
    wiredAudioInit(); 

    /* USB init can be done once power lib initialised */
    usbInit();
    
    /* initialise the display */
    displayInit();
    
    /* initialise DUT */
    dutInit();
    
    /*configure the audio Pre amp if enabled */
    initPreAmp( AUDIO_CHANNEL_A) ;
    initPreAmp( AUDIO_CHANNEL_B) ;


    /* Enter the limbo state as we may be ON due to a charger being plugged in */
    stateManagerEnterLimboState();    
}   

/*************************************************************************
NAME    
    InitUserFeatures
    
DESCRIPTION
    This function initialises all of the user features - this will result in a
    poweron message if a user event is configured correctly and the device will 
    complete the power on

RETURNS

*/
void InitUserFeatures ( void ) 
{
    /* Set to a known value*/
    theSink.VoiceRecognitionIsActive = hfp_invalid_link ;
    theSink.buttons_locked           = FALSE;
    theSink.last_outgoing_ag = hfp_primary_link;
    theSink.csr_speech_recognition_is_active = FALSE ;


    if (theSink.VolumeOrientationIsInverted)
    {
        MessageSend ( &theSink.task , EventUsrVolumeOrientationInvert , 0 ) ;
    }
    
    /* set the LED enable disable state which now persists over a reset */
    if (theSink.theLEDTask->gLEDSEnabled)
    {
        LedManagerEnableLEDS () ;
    }
    else
    {
        LedManagerDisableLEDS () ;
    }

    /* Set inquiry tx power and RSSI inquiry mode */
    ConnectionWriteInquiryTx(theSink.conf2->rssi.tx_power);
    ConnectionWriteInquiryMode(&theSink.task, inquiry_mode_eir);   /* RSSI with EIR data */
    
    /* Check if we're here as result of a watchdog timeout */
    powerManagerCheckPanic();

    /*automatically power on the heasdet as soon as init is complete*/
    if(theSink.panic_reconnect)
    {
        INIT_DEBUG(("INIT: Recover to state 0x%X\n", theSink.rundata->old_state));
        if(theSink.rundata->old_state != deviceLimbo)
            MessageSend( &theSink.task , EventSysPowerOnPanic , NULL ) ;
        else
            theSink.panic_reconnect = FALSE;
    }
    else if((theSink.features.AutoPowerOnAfterInitialisation && !powerManagerIsChargerConnected()))
    {
        INIT_DEBUG(("INIT: Power On\n"));
        MessageSend( &theSink.task , EventUsrPowerOn , NULL ) ;
    }
    
    /* initialise the default volume levels */    
    theSink.volume_levels->a2dp_volume[0].masterVolume = ((theSink.conf1->volume_config.volume_control_config.no_of_steps * theSink.features.DefaultA2dpVolLevel)/ VOLUME_NUM_VOICE_STEPS);
    theSink.volume_levels->a2dp_volume[1].masterVolume = ((theSink.conf1->volume_config.volume_control_config.no_of_steps * theSink.features.DefaultA2dpVolLevel)/ VOLUME_NUM_VOICE_STEPS);

    /* set task to receive system messages */
    MessageSystemTask(&theSink.task);

    INIT_DEBUG(("INIT: complete\n"));
}

