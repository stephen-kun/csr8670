/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_configmanager.c
    
DESCRIPTION
    Configuration manager for the device - resoponsible for extracting user information out of the 
    PSKEYs and initialising the configurable nature of the sink device components
    
*/

#include "sink_configmanager.h"
#include "sink_config.h"
#include "sink_buttonmanager.h"
#include "sink_led_manager.h"
#include "sink_statemanager.h"
#include "sink_powermanager.h"
#include "sink_volume.h"
#include "sink_devicemanager.h"
#include "sink_private.h"
#include "sink_events.h"
#include "sink_tones.h"
#include "sink_audio_prompts.h"
#include "sink_audio.h"
#include "sink_debug.h"
#include "sink_pio.h"
#include "sink_auth.h"
#include "sink_device_id.h"
#include <bdaddr.h>

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#ifndef GATT_DISABLED
#include "sink_gatt.h"
#endif
#if (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
#include "sink_ble_remote_control.h"
#endif
#ifdef ENABLE_IR_REMOTE
#include "sink_ir_remote_control.h"
#endif

#include <csrtypes.h>
#include <ps.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <panic.h>
#include <boot.h>
#include <csr_i2s_audio_plugin.h>

#ifdef DEBUG_CONFIG
#define CONF_DEBUG(x) DEBUG(x)
#else
#define CONF_DEBUG(x) 
#endif

#define HCI_PAGESCAN_INTERVAL_DEFAULT  (0x800)
#define HCI_PAGESCAN_WINDOW_DEFAULT   (0x12)
#define HCI_INQUIRYSCAN_INTERVAL_DEFAULT  (0x800)
#define HCI_INQUIRYSCAN_WINDOW_DEFAULT   (0x12)


#define DEFAULT_VOLUME_MUTE_REMINDER_TIME_SEC 10
#define PSKEY_BDADDR   0x0001

/****************************************************************************
NAME 
  	configManagerKeyLengths

DESCRIPTION
 	Read the lengths of other ps key configs
 
RETURNS
  	void
*/ 
static void configManagerKeyLengths( lengths_config_type * pLengths )
{		
	ConfigRetrieve( CONFIG_LENGTHS, pLengths, sizeof(lengths_config_type));
		
	CONF_DEBUG(("CONF: LENGTHS [%x][%x][%x][%x][%x][%x][%x][%x][%x][%x][%x,%x][%x,%x,%x]\n",
                                            pLengths->pdl_size,
                                            pLengths->num_audio_prompts,
											pLengths->num_audio_prompt_languages,
											pLengths->no_led_filter,
											pLengths->no_led_states,
											pLengths->no_led_events,
											pLengths->no_tones,
                                            pLengths->num_audio_prompts,
                                            pLengths->userTonesLength,
                                            pLengths->size_at_commands,
                                            pLengths->defrag.key_size,
                                            pLengths->defrag.key_minimum,
                                            pLengths->input_manager_size.input_manager_lookup_size,
                                            pLengths->input_manager_size.ble_remote_lookup_size,
                                            pLengths->input_manager_size.ir_remote_lookup_size)) ;
    
	/* Set led lengths straight away */											
	theSink.theLEDTask->gStatePatternsAllocated = pLengths->no_led_states;
	theSink.theLEDTask->gEventPatternsAllocated = pLengths->no_led_events;
	theSink.theLEDTask->gLMNumFiltersUsed = pLengths->no_led_filter;
    theSink.rundata->defrag = pLengths->defrag;
}

/****************************************************************************
NAME 
  	configManagerButtons

DESCRIPTION
 	Read the system event configuration from persistent store and configure
  	the buttons by mapping the associated events to them
 
RETURNS
  	void
*/  

static void configManagerButtons( void )
{  
	/* Allocate enough memory to hold event configuration */
    event_config_type* configA = (event_config_type*) mallocPanic(BM_EVENTS_PER_PS_BLOCK * sizeof(event_config_type));
    event_config_type* configB = (event_config_type*) mallocPanic(BM_EVENTS_PER_PS_BLOCK * sizeof(event_config_type));
    event_config_type* configC = (event_config_type*) mallocPanic(BM_EVENTS_PER_PS_BLOCK * sizeof(event_config_type));
       
    uint16 n;
    uint8  i = 0;
 
    ConfigRetrieve(CONFIG_EVENTS_A, configA, BM_EVENTS_PER_PS_BLOCK * sizeof(event_config_type)) ;
    ConfigRetrieve(CONFIG_EVENTS_B, configB, BM_EVENTS_PER_PS_BLOCK * sizeof(event_config_type)) ; 
    ConfigRetrieve(CONFIG_EVENTS_C, configC, BM_EVENTS_PER_PS_BLOCK * sizeof(event_config_type)) ;  
  
        /* Now we have the event configuration, map required events to system events */
    for(n = 0; n < BM_EVENTS_PER_PS_BLOCK; n++)
    { 
        CONF_DEBUG(("Co : AddMap indexes [%u,%u] Ev[%x][%x][%x]\n", n, i, configA[n].event , configB[n].event, configC[n].event )) ;
                       
           /* check to see if a valid pio mask is present, this includes the upper 2 bits of the state
              info as these are being used for bc5 as vreg enable and charger detect */
        if ( (configA[n].pio_mask)||(configA[n].state_mask & 0xC000))
            buttonManagerAddMapping ( &configA[n], i++ ); 
               
        if ( (configB[n].pio_mask)||(configB[n].state_mask & 0xC000))
            buttonManagerAddMapping ( &configB[n], i++ ); 
        
        if ( (configC[n].pio_mask)||(configC[n].state_mask & 0xC000))
            buttonManagerAddMapping ( &configC[n], i++ );         
                                                                 
   	}
    
    freePanic(configA) ;
    freePanic(configB) ; 
    freePanic(configC) ; 
    
    /* perform an initial pio check to see if any pio changes need processing following the completion
       of the configuration ps key reading */
    BMCheckButtonsAfterReadingConfig();


}
/****************************************************************************
NAME 
  	configManagerButtonPatterns

DESCRIPTION
  	Read and configure any buttonpattern matches that exist
 
RETURNS

*/
static void configManagerButtonPatterns( void ) 
{  
      		/* Allocate enough memory to hold event configuration */
    button_pattern_config_type* config = (button_pattern_config_type*) mallocPanic(BM_NUM_BUTTON_MATCH_PATTERNS * sizeof(button_pattern_config_type));
   
    CONF_DEBUG(("Co: No Button Patterns - %d\n", BM_NUM_BUTTON_MATCH_PATTERNS));
   
        /* Now read in event configuration */
    if(config)
    {     
        if(ConfigRetrieve(CONFIG_BUTTON_PATTERN_CONFIG, config, BM_NUM_BUTTON_MATCH_PATTERNS * sizeof(button_pattern_config_type)))
        {
            uint16 n;
     
           /* Now we have the event configuration, map required events to system events */
            for(n = 0; n < BM_NUM_BUTTON_MATCH_PATTERNS ; n++)
            {	 
     	      CONF_DEBUG(("Co : AddPattern Ev[%x]\n", config[n].event )) ;
                        
          			   /* Map PIO button event to system events in specified states */
          	    buttonManagerAddPatternMapping ( theSink.theButtonsTask , config[n].event , config[n].pattern, n ) ;
            }
        }
        else
 	    {
 	      CONF_DEBUG(("Co: !EvLen\n")) ;
        }
        freePanic(config) ;
    }    
}


/****************************************************************************
NAME 
  	configManagerLEDS

DESCRIPTION
  	Read the system LED configuration from persistent store and configure
  	the LEDS 
 
RETURNS
  	void
*/ 
static void configManagerLEDS( void )
{ 
  	/* 1. LED state configuration */
    	
    /* Providing there are states to configure */
    if((theSink.theLEDTask->gStatePatternsAllocated > 0) && (theSink.theLEDTask->gStatePatternsAllocated < SINK_NUM_STATES))
    {      		
   		ConfigRetrieve(CONFIG_LED_STATES, &theSink.theLEDTask->gStatePatterns, theSink.theLEDTask->gStatePatternsAllocated * sizeof(LEDPattern_t));
  	}      	    
    
    /* 2. LED event configuration */
      
    /* Providing there are events to configure */
    if((theSink.theLEDTask->gEventPatternsAllocated > 0) && (theSink.theLEDTask->gEventPatternsAllocated < EVENTS_MAX_EVENTS))
    {      		
   		ConfigRetrieve(CONFIG_LED_EVENTS, theSink.theLEDTask->pEventPatterns, theSink.theLEDTask->gEventPatternsAllocated * sizeof(LEDPattern_t));
  	} 	    

    /* 3. LED event filter configuration */
	
    /* Providing there are states to configure */
    if((theSink.theLEDTask->gLMNumFiltersUsed > 0) && (theSink.theLEDTask->gLMNumFiltersUsed < LM_NUM_FILTER_EVENTS))
    {                    
           /* read from ps straight into filter config structure */
    	ConfigRetrieve(CONFIG_LED_FILTERS, &theSink.theLEDTask->gEventFilters, theSink.theLEDTask->gLMNumFiltersUsed * sizeof(LEDFilter_t));
    }
     
    /*tri colour behaviour*/  	
  	ConfigRetrieve(CONFIG_TRI_COL_LEDS, &theSink.theLEDTask->gTriColLeds,  sizeof(uint16)) ; 	
  	CONF_DEBUG(("CONF: TRICOL [%x][%x][%x]\n" , theSink.theLEDTask->gTriColLeds.TriCol_a ,
  										   theSink.theLEDTask->gTriColLeds.TriCol_b ,
  										   theSink.theLEDTask->gTriColLeds.TriCol_c )) ;
    
    
}

/****************************************************************************
NAME 
  	configManagerFeatureBlock

DESCRIPTION
  	Read the system feature block and configure system accordingly
 
RETURNS
  	void
*/
static void configManagerFeatureBlock( void ) 
{
    uint8 i;
	
    
    /* Read the feature block from persistent store */
  	ConfigRetrieve(CONFIG_FEATURE_BLOCK, &theSink.features, sizeof(feature_config_type)) ; 

#ifdef ENABLE_PEER
    ValidatePeerUseDeviceIdFeature(); 
#endif
	
	/*Set the default volume level*/
    for(i=0;i<MAX_PROFILES;i++)
    {
        theSink.profile_data[i].audio.gSMVolumeLevel = theSink.features.DefaultVolume ;  
    }    
    
    /* if aptX Low Latency is enabled, automatically enable standard aptX */
    if(theSink.features.A2dpOptionalCodecsEnabled & (1<<APTX_SPRINT_CODEC_BIT))
    {
        theSink.features.A2dpOptionalCodecsEnabled |= (1<<APTX_CODEC_BIT);              
    }
    
}


/****************************************************************************
NAME 
  	configManagerUserDefinedTones

DESCRIPTION
  	Attempt to read the user configured tones, if data exists it will be in the following format:
    
    uint16 offset in array to user tone 1,
    uint16 offset in array to user tone ....,
    uint16 offset in array to user tone 8,
    uint16[] user tone data
    
    To play a particular tone it can be access via gVariableTones, e.g. to access tone 1
    
    theSink.gConfigTones->gVariableTones[0] + (uint16)*theSink.audioData.gConfigTones->gVariableTones[0]
    
    or to access tone 2

    theSink.gConfigTones->gVariableTones[0] + (uint16)*theSink.audioData.gConfigTones->gVariableTones[1]
    
    and so on
 
RETURNS
  	void
*/
static void configManagerUserDefinedTones( uint16 KeyLength ) 
{
    /* if the keyLength is zero there are no user tones so don't malloc any memory */
    if(KeyLength)
    {
        /* malloc only enough memory to hold the configured tone data */
        uint16 * configTone = mallocPanic(KeyLength * sizeof(uint16));
    
        /* retrieve pskey data up to predetermined max size */
        uint16 size_ps_key = ConfigRetrieve(CONFIG_USER_TONES , configTone , KeyLength );
      
        CONF_DEBUG(("Co : Configurable Tones Malloc size [%x]\n", KeyLength )) ;
        
        /* is there any configurable tone data, if present update pointer to tone data */
        if (size_ps_key)
        {
            /* the data is in the form of 8 x uint16 audio note start offsets followed by the 
               up to 8 lots of tone data */
            theSink.gConfigTones.gVariableTones = (ringtone_note*)&configTone[0];
        
        }
        /* no user configured tone data is available, so free previous malloc as not in use */
        else
        {
            /* no need to waste memory */
        	freePanic(configTone);      
        }
    }
    /* no tone data available, ensure data pointer is null */
    else
    {
            theSink.gConfigTones.gVariableTones = NULL;
    }
}

/****************************************************************************
NAME 
  configManagerConfiguration

DESCRIPTION
  Read configuration of pio i/o, timeouts, RSSI pairing and filter.
 
RETURNS
  void
*/ 
static void configManagerConfiguration ( void )
{
	ConfigRetrieve(CONFIG_TIMEOUTS, (void*)&theSink.conf1->timeouts, sizeof(Timeouts_t) ) ;    
	ConfigRetrieve(CONFIG_RSSI_PAIRING, (void*)&theSink.conf2->rssi, sizeof(rssi_pairing_t) ) ; 
}

/****************************************************************************
NAME 
  	configManagerButtonDurations

DESCRIPTION
  	Read the button configuration from persistent store and configure
  	the button durations
 
RETURNS
  	void
*/ 
static void configManagerButtonDurations( void )
{   
    if(ConfigRetrieve(CONFIG_BUTTON, &theSink.conf1->buttons_duration, sizeof(button_config_type)))
 	{
			/*buttonmanager keeps buttons block*/
  		buttonManagerConfigDurations ( theSink.theButtonsTask ,  &theSink.conf1->buttons_duration ); 
    }
}
    
/****************************************************************************
NAME 
  	configManagerButtonTranslations

DESCRIPTION
  	Read the button translation configuration from persistent store and configure
  	the button input assignments, these could be pio or capacitive touch sensors 
 
RETURNS
  	void
*/ 
static void configManagerButtonTranslations( void )
{
    /* get current input/button translations from eeprom or const if no eeprom */
    ConfigRetrieve(CONFIG_BUTTON_TRANSLATION, &theSink.theButtonsTask->gTranslations, (sizeof(button_translation_type) * BM_NUM_BUTTON_TRANSLATIONS));
}


/****************************************************************************
NAME 
 	configManagerPower

DESCRIPTION
 	Read the Power Manager configuration
 
RETURNS
 	void
*/ 
static void configManagerPower( void )
{
    sink_power_config power;
	power_pmu_temp_mon_config pmu_mon_config;

 	/* Read in the battery monitoring configuration */
	ConfigRetrieve(CONFIG_BATTERY, (void*)&power, sizeof(sink_power_config) ) ;
   
    /* Store power settings */
    theSink.conf1->power = power.settings;
    
    /* Setup the power manager */
    if (PsRetrieve(CONFIG_PMU_MONITOR_CONFIG, &pmu_mon_config, sizeof(pmu_mon_config)) == sizeof(pmu_mon_config))
        powerManagerConfig(&power.config, &pmu_mon_config);
    else
        powerManagerConfig(&power.config, NULL);
   
}

/****************************************************************************
NAME 
  	configManagerRadio

DESCRIPTION
  	Read the Radio configuration parameters
 
RETURNS
  	void
*/ 

static void configManagerRadio( void )
{ 
  	if(!ConfigRetrieve(CONFIG_RADIO, &theSink.conf2->radio, sizeof(radio_config_type)))
  	{
    	/* Assume HCI defaults */
    	theSink.conf2->radio.page_scan_interval = HCI_PAGESCAN_INTERVAL_DEFAULT;
    	theSink.conf2->radio.page_scan_window = HCI_PAGESCAN_WINDOW_DEFAULT;
    	theSink.conf2->radio.inquiry_scan_interval = HCI_INQUIRYSCAN_INTERVAL_DEFAULT;
    	theSink.conf2->radio.inquiry_scan_window  = HCI_INQUIRYSCAN_WINDOW_DEFAULT;
  	}
}

/****************************************************************************
NAME 
  	configManagerVolume

DESCRIPTION
  	Read the Volume Mappings and set them up
 
RETURNS
  	void
*/ 
static void configManagerVolume( void )
{ 
    /* get configuration for dsp volume control and volume settings from pskey */
    ConfigRetrieve(CONFIG_VOLUME_CONTROL, &theSink.conf1->volume_config, sizeof(volume_configuration_t)) ;
}

/****************************************************************************
NAME 
  	configManagerEventTone

DESCRIPTION
  	Configure an event tone only if one is defined
 
RETURNS
  	void
*/ 
static void configManagerEventTones( uint16 no_tones )
{ 
  	/* First read the number of events configured */	
  	if(no_tones)		
  	{
        /* Now read in tones configuration */
        if(ConfigRetrieve(CONFIG_TONES, &theSink.conf2->gEventTones, no_tones * sizeof(tone_config_type)))
        {
			/*set the last tone (empty) - used by the play tone routine to identify the last tone*/
			theSink.conf2->gEventTones[no_tones].tone = TONE_NOT_DEFINED ;			
        }  
     }                    
}            



/****************************************************************************
NAME 
  	configManagerAudioPromptEvents

DESCRIPTION
  	Configure an audio prompt event only if one is defined
 
RETURNS
  	void
*/ 
static void configManagerAudioPromptEvents( uint16 num_prompt_events )
{   
  	/* check the number of events configured */
	if(num_prompt_events)
  	{
    	/* Now read in Audio Prompt configuration */
        ConfigRetrieve(CONFIG_AUDIO_PROMPTS, &theSink.conf4->audioPromptEvents, num_prompt_events * sizeof(audio_prompts_config_type));
        
        /* Terminate the list */
        theSink.conf4->audioPromptEvents[num_prompt_events].prompt_id = AUDIO_PROMPT_NOT_DEFINED;
    }
}

#if defined ENABLE_SQIFVP || defined ENABLE_GAIA
void configManagerSqifPartitionsInit( void )
{
    /* read currently free SQIF partitions */                          
    uint16 ret_len;
    uint16 partition_data[2];
 
    /* Read partition information from PS */
    ret_len = ConfigRetrieve(CONFIG_SQIF_PARTITIONS, &partition_data, sizeof(partition_data));
     
#ifdef ENABLE_SQIFVP
    if(!ret_len)
    {            
        /* no key present - assume all partitions are in use */
        theSink.rundata->partitions_free = 0;
    }
    else
    {
        theSink.rundata->partitions_free = LOBYTE(partition_data[0]);
    }
    
    CONF_DEBUG(("CONF : Current SQIF partitions free 0x%x \n", theSink.rundata->partitions_free));
    
    /* Check that the currently selected languages partition is available */
    if((1<<theSink.audio_prompt_language) & theSink.rundata->partitions_free)
    {
        uint16 currentLang = theSink.audio_prompt_language;
        CONF_DEBUG(("CONF : Current SQIF VP partition (%u) not valid\n", currentLang));
        AudioPromptSelectLanguage();
        /* if the new selected language is the same then none could be found so disable audio prompts */
        if (currentLang == theSink.audio_prompt_language)
        {
            theSink.audio_prompts_enabled = FALSE;
            CONF_DEBUG(("CONF : Disabling Audio Prompts, no valid partitions\n"));
        }
    }
#endif  
    
#ifdef ENABLE_GAIA
    if(!ret_len)
    {            
        /* no key present - no DFU */
        theSink.rundata->gaia_data.dfu_partition = GAIA_ILLEGAL_PARTITION;
    }
    else
    {
        theSink.rundata->gaia_data.dfu_partition = partition_data[1];
    }    
#endif
}
#endif  

static void configManagerAudioPromptsInit( uint16 no_ap , uint16 num_audio_prompt_languages )
{
  	/* check the number of events configured and the supported audio prompt languages */
	if(no_ap)
  	{
        theSink.num_audio_prompt_languages = num_audio_prompt_languages;
        
#ifdef ENABLE_SQIFVP
        /* Initilaise as no partitions currently mounted */
        theSink.rundata->partitions_mounted = 0;
#endif /* ENABLE_SQIFVP */                              

        /* Pass configuration to the audio prompts plugin */
        AudioPromptConfigure(no_ap);

    }
}



/****************************************************************************
NAME 
 	InitConfigMemoryAtCommands

DESCRIPTION
    Dynamically allocate memory slot for AT commands (conf3)
 
RETURNS
 	void
*/ 
static void InitConfigMemoryAtCommands(uint16 atCmdsKeyLength)
{    
	/* Allocate memory for supported custom AT commands, malloc one extra word to ensure 
       a string terminator is present should the data read from ps be incorrect */
    theSink.conf3 = mallocPanic( sizeof(config_block3_t) + atCmdsKeyLength + 1);
    /* ensure that all data is set as string terminator in case of incorrect pskey 
       data being read */
    memset(theSink.conf3, 0, (sizeof(config_block3_t) + atCmdsKeyLength + 1));
	CONF_DEBUG(("INIT: Malloc size conf3: [%d]\n", sizeof(config_block3_t) + atCmdsKeyLength ));
}

/****************************************************************************
NAME 
 	InitConfigMemory

DESCRIPTION
    Dynamic allocate memory slots.  
    Memory slots available to the application are limited, so store multiple configuration items in one slot.
 
RETURNS
 	void
*/ 

static void InitConfigMemory(lengths_config_type * keyLengths)
{    
	/* Allocate memory for SSR, PIO and radio data, and Event Tone */
    theSink.conf2 = mallocPanic( sizeof(config_block2_t) + (keyLengths->no_tones * sizeof(tone_config_type)) );
 	CONF_DEBUG(("INIT: Malloc size conf2: [%d]\n", sizeof(config_block2_t) + (keyLengths->no_tones * sizeof(tone_config_type))));
    
    /* initialise the memory block to 0 */    
    memset(theSink.conf2,0,sizeof(config_block2_t) + (keyLengths->no_tones * sizeof(tone_config_type)));
    
    theSink.conf3 = NULL;

    /*Allocate memory for PEQ structure */
    theSink.PEQ = mallocPanic( sizeof(user_eq_bank_t));
    /* initialise structure to 0 */    
    memset(theSink.PEQ, 0, sizeof(user_eq_bank_t)); 
    
    /* Allocate memory for voice prompts config if required*/
    if(keyLengths->num_audio_prompt_events || keyLengths->num_audio_prompts)
    {
        theSink.conf4 = mallocPanic( sizeof(config_block4_t) + (keyLengths->num_audio_prompt_events * sizeof(audio_prompts_config_type)));
        CONF_DEBUG(("INIT: Malloc size conf4: [%d]\n", sizeof(config_block4_t) + (keyLengths->num_audio_prompt_events * sizeof(audio_prompts_config_type))));
    }
    else
    {
        theSink.conf4 = NULL;
    }

#if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
    /* Allocate enough memory to extract the input manager config (contains timers and the Input Manager lookup table (lookup can be of max size 255 entries) */
    theSink.rundata->inputManager.size_lookup_table = keyLengths->input_manager_size.input_manager_lookup_size;
    CONF_DEBUG(("INIT: Malloc size input manager: [%d]\n", sizeof(timerConfig_t) + (sizeof(eventLookupTable_t) * theSink.rundata->inputManager.size_lookup_table) ));
    theSink.rundata->inputManager.config = mallocPanic( sizeof(timerConfig_t) + (sizeof(eventLookupTable_t) * theSink.rundata->inputManager.size_lookup_table) );
#endif

#if defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED)
    /* Allocate enough memory to extract the configured BLE HID lookup table (can be of max size 16 entries) */
    theSink.rundata->bleInputMonitor.size_lookup_table = keyLengths->input_manager_size.ble_remote_lookup_size;
    CONF_DEBUG(("INIT: Malloc size BLE HOGP: [%d]\n", ((sizeof(bleHidRcConfig_t) - sizeof(bleLookupTable_t)) + (theSink.rundata->bleInputMonitor.size_lookup_table * sizeof(bleLookupTable_t))) + (sizeof(bleLookupTable_t) * theSink.rundata->bleInputMonitor.size_lookup_table) ));
    theSink.rundata->bleInputMonitor.config = mallocPanic( ((sizeof(bleHidRcConfig_t) - sizeof(bleLookupTable_t)) + (theSink.rundata->bleInputMonitor.size_lookup_table * sizeof(bleLookupTable_t))) + (sizeof(bleLookupTable_t) * theSink.rundata->bleInputMonitor.size_lookup_table) );
#endif
    
#ifdef ENABLE_IR_REMOTE
    /* Allocate enough memory to extract the configured IR lookup table (can be of max size 16 entries) */
    theSink.rundata->irInputMonitor.size_lookup_table = keyLengths->input_manager_size.ir_remote_lookup_size;
    CONF_DEBUG(("INIT: Malloc size IR: [%d]\n", (sizeof(irRcConfig_t)-sizeof(irLookupTableConfig_t)) + (sizeof(irLookupTableConfig_t) * theSink.rundata->irInputMonitor.size_lookup_table) ));
    theSink.rundata->irInputMonitor.config = mallocPanic( (sizeof(irRcConfig_t)-sizeof(irLookupTableConfig_t)) + (sizeof(irLookupTableConfig_t) * theSink.rundata->irInputMonitor.size_lookup_table) );
#endif
}


/****************************************************************************
NAME 
 	configManagerAtCommands

DESCRIPTION
    Retrieve configurable AT command data from PS
 
RETURNS
 	void
*/ 
static void configManagerAtCommands(uint16 length)
{
    ConfigRetrieve(CONFIG_AT_COMMANDS, theSink.conf3, length);
}


/****************************************************************************
NAME 
 	configManagerPioMap

DESCRIPTION
    Read PIO config and map in configured PIOs.
 
RETURNS
 	void
*/ 

void configManagerPioMap(void)
{
    pio_config_type* pio;

	/* Allocate memory for Button data, volume mapping */
    theSink.conf1 = mallocPanic( sizeof(config_block1_t) );
    memset(theSink.conf1, 0, sizeof (config_block1_t));
	CONF_DEBUG(("INIT: Malloc size conf1: [%d]\n",sizeof(config_block1_t)));    

    /* Retrieve config */
    pio = &theSink.conf1->PIOIO;
    ConfigRetrieve(CONFIG_PIO, pio, sizeof(pio_config_type));

    /* Make sure all references to mic parameters point to the right place */
    theSink.cvc_params.digital = &pio->digital;

    /* Map in any required pins */
    CONF_DEBUG(("INIT: Map PIO 0x%lX\n", pio->pio_map));
    PioSetMapPins32(pio->pio_map,pio->pio_map);
}



/****************************************************************************
NAME 
 	configManagerUsb

DESCRIPTION
    Retrieve USB config from PS
 
RETURNS
 	void
*/ 
#ifdef ENABLE_USB
void configManagerUsb(void)
{
    ConfigRetrieve(CONFIG_USB_CONFIG, &theSink.usb.config, sizeof(usb_config));
}
#endif

/****************************************************************************
NAME 
 	configManagerReadFmData

DESCRIPTION
    Retrieve FM config from PS
 
RETURNS
 	void
*/ 
#ifdef ENABLE_FM
void configManagerReadFmData(void)
{
    /* determine size of data required by fm library */
	int lSize = (sizeof(fm_rx_data_t) + FMRX_MAX_BUFFER_SIZE); 
	/*allocate the memory*/
	theSink.conf2->sink_fm_data.fm_plugin_data = mallocPanic( lSize );
    /* initialise structure */    
    memset(theSink.conf2->sink_fm_data.fm_plugin_data, 0, lSize);  
    /* get the FM config from pskey */
    ConfigRetrieve(CONFIG_FM_CONFIG, &theSink.conf2->sink_fm_data.fm_plugin_data->config, sizeof(fm_rx_config));

    /* get the FM stored freq from pskey */
    ConfigRetrieve(CONFIG_FM_FREQUENCY_STORE, &theSink.conf2->sink_fm_data.fmStoredFreq, sizeof(fm_stored_freq));   
}       
#endif
        
/****************************************************************************
NAME 
 	configManagerHFP_SupportedFeatures

DESCRIPTION
    Gets the HFP Supported features set from PS
 
RETURNS
 	void
*/
void configManagerHFP_SupportedFeatures( void )
{
    ConfigRetrieve(CONFIG_ADDITIONAL_HFP_SUPPORTED_FEATURES , &theSink.HFP_supp_features , sizeof( HFP_features_type ) ) ;
}

/****************************************************************************
NAME 
 	configManagerHFP_Init

DESCRIPTION
    Gets the HFP initialisation parameters from PS
 
RETURNS
 	void
*/
void configManagerHFP_Init( hfp_init_params * hfp_params )
{     
    ConfigRetrieve(CONFIG_HFP_INIT , hfp_params , sizeof( hfp_init_params ) ) ;
    
}

/*************************************************************************
NAME    
    ConfigManagerSetupSsr
    
DESCRIPTION
    This function attempts to retreive SSR parameters from the PS, setting
	them to zero if none are found

RETURNS

*/
static void configManagerSetupSsr( void  ) 
{
	CONF_DEBUG(("CO: SSR\n")) ;

	/* Get the SSR params from the PS/Config */
	ConfigRetrieve(CONFIG_SSR_PARAMS, &theSink.conf2->ssr_data, sizeof(subrate_t));
}

/****************************************************************************
NAME 
 	configManagerEnableMultipoint
*/ 
void configManagerEnableMultipoint(bool enable)
{
    CONF_DEBUG(("CONF: Multipoint %s\n", enable ? "Enable" : "Disable"));
    if(enable)
    {
        /* Check we can make HFP multi point */
        if(HfpLinkSetMaxConnections(2))
        {
            /* If A2DP disabled or we can make it multi point then we're done */
            if(!theSink.features.EnableA2dpStreaming || A2dpConfigureMaxRemoteDevices(2))
            {
                CONF_DEBUG(("CONF: Success\n"));
                theSink.MultipointEnable = TRUE;
                return;
            }
        }
    }
    else
    {
        /* Check we can make HFP single point */
        if(HfpLinkSetMaxConnections(1))
        {
            /* If A2DP disabled or we can make it single point then we're done */
            if(!theSink.features.EnableA2dpStreaming || A2dpConfigureMaxRemoteDevices(1))
            {
                CONF_DEBUG(("CONF: Success\n"));
                theSink.MultipointEnable = FALSE;
                return;
            }
        }
    }
    CONF_DEBUG(("CONF: Failed\n"));
    /* Setting failed, make sure HFP setting is restored */
    HfpLinkSetMaxConnections(theSink.MultipointEnable ? 2 : 1);
}

/****************************************************************************
NAME 
 	void configManagerReadI2SConfiguration(void)
    
    DESCRIPTION
    Gets the I2S pskey config and any associated I2C data packets
 
RETURNS
 	void

*/  
void configManagerReadI2SConfiguration(void)
{
    /* if the I2S output capability has been enabled, load its configuration */
    if((theSink.conf2->audio_routing_data.PluginFeatures.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)||
       (theSink.conf2->audio_routing_data.PluginFeatures.audio_input_routing == AUDIO_ROUTE_I2S))     
    {
        uint16 size;
        
        /* obtain size of pskey for I2S data */
        size = PsRetrieve(CONFIG_I2S_INIT_DATA, NULL, 0);
        /* now malloc slot to contain both the init config and the data */       
        CONF_DEBUG(("INIT: Malloc size conf5: [%d]\n",(sizeof(config_block5_t)+(size))));    
        theSink.conf5 = mallocPanic((sizeof(config_block5_t)+(size)));
        /* zero initialise data */
        memset(theSink.conf5, 0, (sizeof(config_block5_t)+(size)));        
        /* read the i2s init config pskey */
        ConfigRetrieve(CONFIG_I2S_INIT_CONFIGURATION, &theSink.conf5->i2s_ps_config.i2s_init_config, sizeof(i2s_init_config_t));
        /* if any data available */        
        if(size)
        {
            /* now retrieve the pskey i2c data */        
            ConfigRetrieve(CONFIG_I2S_INIT_DATA, &theSink.conf5->i2s_ps_config.i2s_data_config, size);
        }
        /* pass data to I2S library for future use */
        CsrI2SInitialisePlugin((I2SConfiguration *)theSink.conf5);
    }               
}

/****************************************************************************
NAME 
 	configManagerReadSessionData
*/ 
static void configManagerReadSessionData( void ) 
{
    session_data_type lTemp ;

    memset(&lTemp.user_eq, 0, sizeof(user_eq_bank_t));

    /*read in the Session data*/
    ConfigRetrieve(CONFIG_SESSION_DATA , &lTemp , sizeof( session_data_type ) ) ;
  
    theSink.VolumeOrientationIsInverted = lTemp.vol_orientation ;
    /* if the feature bit to reset led disable state after a reboot is set then enable the leds
       otherwise get the led enable state from ps */
    if(!theSink.features.ResetLEDEnableStateAfterReset)
    {
        theSink.theLEDTask->gLEDSEnabled    = lTemp.led_disable ;
    }
    else
    {
        theSink.theLEDTask->gLEDSEnabled    = TRUE;   
    }  
            
    theSink.audio_prompt_language                = lTemp.audio_prompt_language;
    theSink.audio_prompts_enabled                 = lTemp.audio_prompt_enable;
    theSink.lbipmEnable                 = lTemp.lbipm_enable;
    theSink.ssr_enabled                 = lTemp.ssr_enabled;
    configManagerEnableMultipoint(lTemp.multipoint_enable);
    theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing = (A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0 + (lTemp.audio_enhancements & A2DP_MUSIC_CONFIG_USER_EQ_SELECT));
    theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements = (lTemp.audio_enhancements & ~A2DP_MUSIC_CONFIG_USER_EQ_SELECT);
#ifdef ENABLE_FM
    theSink.conf2->sink_fm_data.fmRxTunedFreq = lTemp.fm_frequency;
    theSink.volume_levels->fm_volume.masterVolume = lTemp.fm_volume;
#endif   
    theSink.volume_levels->analog_volume.masterVolume = lTemp.analog_volume;
    theSink.volume_levels->spdif_volume.masterVolume  = lTemp.spdif_volume;
    theSink.volume_levels->usb_volume.masterVolume = lTemp.usb_volume;

    if(theSink.PEQ)
    {
        memcpy(theSink.PEQ, &lTemp.user_eq, sizeof(user_eq_bank_t) );
    }

    CONF_DEBUG(("CONF : Rd Vol Inverted [%c], LED Disable [%c], Multipoint Enable [%c], LBIPM Enable [%c] EQ[%x]\n", theSink.VolumeOrientationIsInverted ? 'T':'F' ,
 																							 lTemp.led_disable ? 'T':'F' ,
        																					 theSink.MultipointEnable ? 'T':'F',
                                                                                             theSink.lbipmEnable ? 'T':'F',
                                                                                             theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing)) ; 
    
    
}

/****************************************************************************
NAME 
 	configManagerWriteSessionData

*/ 
void configManagerWriteSessionData( void )
{
    session_data_type lTemp ;

    memset(&lTemp.user_eq, 0, sizeof(user_eq_bank_t));
    
    lTemp.vol_orientation   = theSink.gVolButtonsInverted;
    lTemp.led_disable       = theSink.theLEDTask->gLEDSEnabled;
	lTemp.audio_prompt_language      = theSink.audio_prompt_language;
    lTemp.audio_prompt_enable        = theSink.audio_prompts_enabled;
    lTemp.multipoint_enable = theSink.MultipointEnable;
    lTemp.lbipm_enable      = theSink.lbipmEnable;
    lTemp.ssr_enabled       = theSink.ssr_enabled;
    lTemp.unused1           = 0;
    lTemp.unused2           = 0;
    lTemp.unused3           = 0;
    lTemp.audio_enhancements = ((theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing - A2DP_MUSIC_PROCESSING_FULL_SET_EQ_BANK0) & A2DP_MUSIC_CONFIG_USER_EQ_SELECT)|
                               (theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_enhancements & ~A2DP_MUSIC_CONFIG_USER_EQ_SELECT);
#ifdef ENABLE_FM
    lTemp.fm_frequency      = theSink.conf2->sink_fm_data.fmRxTunedFreq;
    lTemp.fm_volume         = theSink.volume_levels->fm_volume.masterVolume;
#else
    lTemp.fm_frequency      = 0;
    lTemp.fm_volume         = 0;
#endif    
    
    lTemp.analog_volume = theSink.volume_levels->analog_volume.masterVolume;
    lTemp.spdif_volume = theSink.volume_levels->spdif_volume.masterVolume;
    lTemp.usb_volume = theSink.volume_levels->usb_volume.masterVolume;

    memcpy(&lTemp.user_eq, theSink.PEQ, sizeof(user_eq_bank_t) );

    CONF_DEBUG(("CONF : PS Write Vol Inverted[%c], LED Disable [%c], Multipoint Enable [%c], LBIPM Enable [%c] Enhancements[%x]\n" , 
						theSink.gVolButtonsInverted ? 'T':'F' , 
						lTemp.led_disable ? 'T':'F',
                        theSink.MultipointEnable ? 'T':'F',
                        theSink.lbipmEnable ? 'T':'F',
                        lTemp.audio_enhancements));
    
    (void) ConfigStore(CONFIG_SESSION_DATA, &lTemp, sizeof(session_data_type)); 
    
}


/****************************************************************************
NAME 
  	configManagerRestoreDefaults

DESCRIPTION
    Restores default PSKEY settings.
	This function restores the following:
		1. CONFIG_SESSION_DATA
		2. Enable Audio Prompts with default language
		3. Clears the paired device list
		4. Enables the LEDs
        5. Disable multipoint
        6. Disable lbipm
        7. Reset EQ
 
RETURNS
  	void
*/ 

void configManagerRestoreDefaults( void ) 
{
    CONF_DEBUG(("CO: Restore Defaults\n")) ;
    /*Set local values*/
	theSink.gVolButtonsInverted = FALSE ;
    
    theSink.audio_prompt_language = 0 ;
    theSink.audio_prompts_enabled = TRUE;
    configManagerEnableMultipoint(FALSE);
    theSink.lbipmEnable = FALSE ;
    theSink.a2dp_link_data->a2dp_audio_mode_params.music_mode_processing = A2DP_MUSIC_PROCESSING_FULL;
    
	/*Reset PSKEYS*/
	(void)ConfigStore( CONFIG_SESSION_DATA , 0 , 0 ) ;
    
	/*Call function to reset the PDL*/
	deviceManagerRemoveAllDevices();
    
#ifdef ENABLE_PEER
    /* Ensure permanently paired Peer device is placed back into PDL */
    AuthInitPermanentPairing();
#endif
	
	if	(!(theSink.theLEDTask->gLEDSEnabled))
	{
		/*Enable the LEDs*/
		MessageSend (&theSink.task , EventUsrLedsOn , 0) ;
	}
}


/****************************************************************************
NAME 
 	configManagerReadDspData
*/ 
static void configManagerReadDspData( void )
{
    /* Initialise DSP persistent store block */
    theSink.conf2->dsp_data.key.len   = CONFIG_DSP_SESSION_SIZE;
    theSink.conf2->dsp_data.key.key   = CONFIG_DSP_SESSION_KEY;
    theSink.conf2->dsp_data.key.cache = theSink.conf2->dsp_data.cache;
    PblockInit(&theSink.conf2->dsp_data.key);
}


/****************************************************************************
NAME 
 	configManagerWriteDspData
*/ 
void configManagerWriteDspData( void )
{
    /* Write DSP persistent store block */
    PblockStore();
}


/****************************************************************************
NAME 
  	configManagerFillPs

DESCRIPTION
  	Fill PS to the point defrag is required (for testing only)

RETURNS
  	void
*/
void configManagerFillPs(void)
{
    CONF_DEBUG(("CONF: Fill PS Size[%d]Min[%d]",theSink.rundata->defrag.key_size, theSink.rundata->defrag.key_minimum)) ;
    if(theSink.rundata->defrag.key_size)
    {
        uint16 count     = PsFreeCount(theSink.rundata->defrag.key_size);
        uint16* buff     = mallocPanic(theSink.rundata->defrag.key_size);
        CONF_DEBUG(("Count[%d]", count));
        if(count > theSink.rundata->defrag.key_minimum)
        {
            for(count = count - theSink.rundata->defrag.key_minimum ; count > 0; count --)
            {
                *buff = count;
                PsStore(CONFIG_DEFRAG_TEST, buff, theSink.rundata->defrag.key_size);
            }

        }
        CONF_DEBUG(("NowFree[%d]", PsFreeCount(theSink.rundata->defrag.key_size)));
    }
    CONF_DEBUG(("\n"));
}


/****************************************************************************
NAME 
  	configManagerDefragCheck

DESCRIPTION
  	Check if PS Defrag. is required.

RETURNS
  	bool  TRUE if defrag. required
*/
bool configManagerDefragCheck(void)
{
    CONF_DEBUG(("CONF: Defrag Check")) ;
    if(theSink.rundata->defrag.key_size)
    {
        uint16 count = PsFreeCount(theSink.rundata->defrag.key_size);
        CONF_DEBUG((", free [%d]", count)) ;
        if(count <= theSink.rundata->defrag.key_minimum)
        {
            CONF_DEBUG((" ,defrag required\n")) ;
            return TRUE;
        }
    }
    
    CONF_DEBUG(("\n")) ;
    return FALSE;
}

/****************************************************************************
NAME 
  	configManagerDefrag

DESCRIPTION
  	Flood PS to force a PS Defragment operation on next reboot.

PARAMS
    bool reboot  TRUE if the application should automatically reboot
    
RETURNS
  	void
*/
void configManagerDefrag(const bool reboot)
{
    CONF_DEBUG(("Flooding PS and reboot\n")) ;
    PsFlood();
    
    if(reboot)
    {
        /* try to set the same boot mode; this triggers the target to reboot.*/
        BootSetMode(BootGetMode());
    }
}

/****************************************************************************
NAME 
  	configManagerInitMemory

DESCRIPTION
  	Init static size memory blocks that are required early in the boot sequence

RETURNS
  	void
    
*/

void configManagerInitMemory( void )  
{ 
	/* Allocate memory for run time data*/
    theSink.rundata = mallocPanic( sizeof(runtime_block1_t) );
    memset(theSink.rundata, 0, sizeof (runtime_block1_t));
	CONF_DEBUG(("INIT: Malloc size runtime1: [%d]\n",sizeof(runtime_block1_t)));    
   
}


/****************************************************************************
NAME 
  	configManagerGetSubwooferConfig

DESCRIPTION
    Reads the PSKEY containing the Subwoofer configuration
 
RETURNS
  	TRUE if configuration data was retrieved from CONFIG_SUBWOOFER
*/
#ifdef ENABLE_SUBWOOFER
bool configManagerGetSubwooferConfig( void )
{
    uint16              size;
    subwooferConfig_t   sub_config;
    
    size = ConfigRetrieve(CONFIG_SUBWOOFER, (void *)&sub_config, sizeof(subwooferConfig_t));
    
    if ( size == sizeof(subwooferConfig_t) )
    {
        CONF_DEBUG(("CONF: Subwoofer addr[%04x %02x %04x%04x] eSCO[%lu, %lu, %x, %x, %x, %x]\n", 
                                sub_config.bd_addr.nap, sub_config.bd_addr.uap, (uint16)(sub_config.bd_addr.lap>>16), (uint16)sub_config.bd_addr.lap,
                                sub_config.esco_params.tx_bandwidth,
                                sub_config.esco_params.rx_bandwidth,
                                sub_config.esco_params.max_latency,
                                sub_config.esco_params.voice_settings,
                                sub_config.esco_params.retx_effort,
                                sub_config.esco_params.packet_type ));
        
        /* Copy the subwoofer config data to allocated runtime data */
        theSink.rundata->subwoofer.bd_addr     = sub_config.bd_addr;
        theSink.rundata->subwoofer.esco_params = sub_config.esco_params;
        
        return TRUE;
    }
    else
    {
        CONF_DEBUG(("CONF: Subwoofer config read failed (or PS data not present)\n"));
        memset(&theSink.rundata->subwoofer.bd_addr, 0, sizeof(bdaddr));
        memset(&theSink.rundata->subwoofer.esco_params, 0, sizeof(sync_config_params));
        return FALSE;
    }
}
#endif


/****************************************************************************
NAME 
  	configManagerWriteSubwooferBdaddr

DESCRIPTION
    Writes the Subwoofer BDADDR to PSKEY CONFIG_SUBWOOFER

RETURNS
    True if data was written to they PSKEY
    
NOTE
    This function will not check the value of the BDADDR requested to
    be written. If the *addr pointer is NULL, this function will write
    a zero padded bdaddr to the PS store.
*/
#ifdef ENABLE_SUBWOOFER
bool configManagerWriteSubwooferBdaddr( const bdaddr * addr )
{
    subwooferConfig_t   sub_config;
    uint16              size;

    /* DO NOT modify the eSCO params, they must remain unchanged */
    sub_config.esco_params = theSink.rundata->subwoofer.esco_params;
    
    /* Populate the Bluetooth address to be written */
    if (addr == NULL)
    {
        /* No address passed in, so zero pad the addr part of the key */
        memset(&sub_config.bd_addr, 0, sizeof(bdaddr));
    }
    else
    {
        memcpy(&sub_config.bd_addr, addr, sizeof(bdaddr));
    }
    
    /* Store the subwoofers Bluetooth address to PS */
    size = ConfigStore(CONFIG_SUBWOOFER, &sub_config, sizeof(sub_config));
    if (size == sizeof(sub_config))
    {
        CONF_DEBUG(("CONF: Wrote sub bdaddr to CONFIG_SUBWOOFER\n"));
        return TRUE;
    }
    else
    {
        CONF_DEBUG(("CONF: Error writing CONFIG_SUBWOOFER\n"))
        return FALSE;
    }
}
#endif


/****************************************************************************
NAME 
  	configManagerGattInit

DESCRIPTION
    Reads the PSKEY containing the GATT configuration
 
RETURNS
  	TRUE if configuration data was retrieved from CONFIG_GATT
*/
#ifndef GATT_DISABLED
bool configManagerGattInit( void )
{
    uint16 size;
    
    size = ConfigRetrieve(CONFIG_GATT, &theSink.rundata->gatt.config, sizeof(gattConfigData_t));
    
    if (size == sizeof(gattConfigData_t))
    {
        CONF_DEBUG(("CONF: GATT config mode[%x]  client[%x]\n", theSink.rundata->gatt.config.mode, theSink.rundata->gatt.config.client ));
        theSink.rundata->gatt.initialised = FALSE;
        return TRUE;
    }
    else
    {
        CONF_DEBUG(("CONF: GATT config read failed (or PS data not present)\n"));
        theSink.rundata->gatt.config.mode = gatt_mode_disabled;
        return FALSE;
    }
}
#endif /* GATT_DISABLED */


/****************************************************************************
NAME 
  	configManagerInputManagerInit

DESCRIPTION
    Reads the PSKEY containing the Input Manager configuration
 
RETURNS
  	void
*/ 
#if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
bool configManagerInputManagerInit( void )
{
    uint16  size;
    
    size = ConfigRetrieve(CONFIG_INPUT_MANAGER, theSink.rundata->inputManager.config, (sizeof(timerConfig_t) + (sizeof(eventLookupTable_t) * theSink.rundata->inputManager.size_lookup_table)) );
    
    /* Timer config should be the first bit of data in the config data, at a minimum, ensure that the timers have been read */
    if (size >= sizeof(timerConfig_t))
    {
        /* Config data for input manager matches the expected size */
        uint16 i;
        CONF_DEBUG(("CONF: InputManager Timers: MD[%x] S[%x] L[%x] VL[%x] VVL[%x] R[%x]\n",
                    theSink.rundata->inputManager.config->input_timers.multipleDetectTimer,
                    theSink.rundata->inputManager.config->input_timers.shortTimer,
                    theSink.rundata->inputManager.config->input_timers.longTimer,
                    theSink.rundata->inputManager.config->input_timers.vLongTimer,
                    theSink.rundata->inputManager.config->input_timers.vvLongTimer,
                    theSink.rundata->inputManager.config->input_timers.repeatTimer));
        
        CONF_DEBUG(("CONF: InputManager Lookup[%d]:\n", theSink.rundata->inputManager.size_lookup_table));
        for (i=0; i<theSink.rundata->inputManager.size_lookup_table; i++)
        {
            CONF_DEBUG(("CONF: [%02d]=[%04x][%04x][%02x][%02x]\n",
                        i,
                        theSink.rundata->inputManager.config->lookup_table[i].mask,
                        theSink.rundata->inputManager.config->lookup_table[i].state_mask,
                        theSink.rundata->inputManager.config->lookup_table[i].input_event,
                        theSink.rundata->inputManager.config->lookup_table[i].user_event));
        }
        return TRUE;
    }
    /* Input Manager config is not valid */
    return FALSE;
}
#endif


/****************************************************************************
NAME 
  	configManagerBleRemoteControlInit

DESCRIPTION
    Reads the PSKEY containing the BLE Remote Control lookup table
 
RETURNS
  	void
*/ 
#if(defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
void configManagerBleRemoteControlInit( void )
{
#ifdef DEBUG_CONFIG
    uint16 i;
#endif
    
    /* If there is a lookup table, get it */
    if (theSink.rundata->bleInputMonitor.size_lookup_table)
    {
        uint16 size=0;
        size = ConfigRetrieve(CONFIG_BLE_REMOTE_CONTROL, theSink.rundata->bleInputMonitor.config, ((sizeof(bleHidRcConfig_t) - sizeof(bleLookupTable_t)) + (theSink.rundata->bleInputMonitor.size_lookup_table * sizeof(bleLookupTable_t))) );
        
#ifdef DEBUG_CONFIG
        /* Print the lookup table in a readable format for debugging purposes */
        CONF_DEBUG(("CONF: BLE Max RC[%d], Pairing Timeout[%d], scan_interval[%x], scan_window[%x], Stored RC[%04x %02x %04x%04x], Lookup Size[%d]:\n", theSink.rundata->bleInputMonitor.config->max_remotes, theSink.rundata->bleInputMonitor.config->pairing_timeout, theSink.rundata->bleInputMonitor.config->scan_params.scan_interval, theSink.rundata->bleInputMonitor.config->scan_params.scan_window, theSink.rundata->bleInputMonitor.config->stored_addr.nap, theSink.rundata->bleInputMonitor.config->stored_addr.uap, (uint16)(theSink.rundata->bleInputMonitor.config->stored_addr.lap>>16), (uint16)theSink.rundata->bleInputMonitor.config->stored_addr.lap, theSink.rundata->bleInputMonitor.size_lookup_table));
        for (i=0; i<theSink.rundata->bleInputMonitor.size_lookup_table; i++)
        {
            CONF_DEBUG(("CONF: [0x%x]->[0x%03x]\n", theSink.rundata->bleInputMonitor.config->lookup_table[i].input_id, theSink.rundata->bleInputMonitor.config->lookup_table[i].hid_code));
        }
#endif
        
    }
    else
    {
        /* No BLE lookup table exists, so set max remotes to zero as there's nothing the BLE task can do without the lookup table */
        theSink.rundata->bleInputMonitor.config->max_remotes = 0;
    }
}
#endif

/****************************************************************************
NAME 
  	configManagerIrRemoteInit

DESCRIPTION
    Reads the PSKEY containing the IR Remote Lookup Table
 
RETURNS
  	void
*/ 
#ifdef ENABLE_IR_REMOTE
void configManagerIrRemoteControlInit( void )
{
#ifdef DEBUG_CONFIG
    uint16 i;
#endif
    
    /* If there is a lookup table, get it */
    if (theSink.rundata->irInputMonitor.size_lookup_table)
    {
        uint16 size=0;
        size = ConfigRetrieve( CONFIG_IR_REMOTE_CONTROL, theSink.rundata->irInputMonitor.config, (sizeof(irRcConfig_t) - sizeof(irLookupTableConfig_t)) + (sizeof(irLookupTableConfig_t) * theSink.rundata->irInputMonitor.size_lookup_table) );
        
#ifdef DEBUG_CONFIG
        /* Print the lookup table in a readable format for debugging purposes */
        CONF_DEBUG(("CONF: IR Protocol[%x], MaxLearningCodes[%x], LearnTimeout[%d], LearnReminder[%d], IR_PIO[%d], SizeLookup[%d]:\n", theSink.rundata->irInputMonitor.config->protocol, theSink.rundata->irInputMonitor.config->max_learning_codes, theSink.rundata->irInputMonitor.config->learning_mode_timeout, theSink.rundata->irInputMonitor.config->learning_mode_reminder, theSink.rundata->irInputMonitor.config->ir_pio, theSink.rundata->irInputMonitor.size_lookup_table));
        for (i=0; i<theSink.rundata->irInputMonitor.size_lookup_table; i++)
        {
            CONF_DEBUG(("CONF: ADDR[%x] , INPUT ID[0x%x] , IR CODE[0x%02x]\n", theSink.rundata->irInputMonitor.config->lookup_table[i].remote_address, theSink.rundata->irInputMonitor.config->lookup_table[i].input_id, theSink.rundata->irInputMonitor.config->lookup_table[i].ir_code));
        }
#endif
        
    }
    else
    {
        /* No IR lookup table exists, so set max remotes to zero as there's nothing the IR task can do without the lookup table */
        /* TODO */
    }
}
#endif


/****************************************************************************
NAME 
  	configManagerAudioRouting

DESCRIPTION
    Reads the PSKEY containing the audio routing information
 
RETURNS
  	void
*/ 
void configManagerAudioRouting( void )
{
    /* Get the audio routing params from the PS/Config */
	ConfigRetrieve(CONFIG_AUDIO_ROUTING, &theSink.conf2->audio_routing_data, sizeof(audio_routing_config_type));   
}

/****************************************************************************
NAME 
  	configManagerSetVersionNo

DESCRIPTION
    Reads the PSKEY containing the version number and checks if it needs to be
    set or reset, will not be written if already the correct value
 
RETURNS
  	void
*/ 
void configManagerSetVersionNo( void)
{
    uint16 version_id[2];
    
    /* read software version number pskey */
    if ((PsRetrieve(CONFIG_SOFTWARE_VERSION_ID, &version_id, 2) != 2)||
        (version_id[0] != PRODUCT_VERSION) ||
        (version_id[1] != CONFIG_SET_VERSION))
    {
        /* if not correct or missing then write constant values */
        version_id[0] = PRODUCT_VERSION;
        version_id[1] = CONFIG_SET_VERSION;
        PsStore(CONFIG_SOFTWARE_VERSION_ID, version_id, 2);
    }

}


/****************************************************************************
NAME 
  	getLocalBdAddrFromPs

DESCRIPTION
  	Retrieves the local BD Address of the sink device from the PS store.

RETURNS
  	bool
    
*/
static bool getLocalBdAddrFromPs(void)
{
    uint16 size = sizeof(theSink.local_bd_addr);
     
    if(size == PsFullRetrieve(PSKEY_BDADDR, &theSink.local_bd_addr, size))
    {
        CONF_DEBUG(("CONF: PSKEY_BDADDR [%04x %02x %06lx]\n", theSink.local_bd_addr.nap, theSink.local_bd_addr.uap, theSink.local_bd_addr.lap));
        return TRUE;
    }
    else
    {
        BdaddrSetZero(&theSink.local_bd_addr);
        return FALSE;
    }
}


/****************************************************************************
NAME 
  	configManagerInit

DESCRIPTION
  	The Configuration Manager is responsible for reading the user configuration
  	from the persistent store are setting up the system.  Each system component
  	is initialised in order.  Where appropriate, each configuration parameter
  	is limit checked and a default assigned if found to be out of range.

RETURNS
  	void
    
*/

void configManagerInit( bool full_init )  
{     
	/* use a memory allocation for the lengths data to reduce stack usage */
    lengths_config_type * keyLengths = mallocPanic(sizeof(lengths_config_type));
	
	/* Read key lengths */
    configManagerKeyLengths(keyLengths);			
    
    /* Allocate the memory required for the configuration data */
    InitConfigMemory(keyLengths);

    /*Read the local BD Address of the sink device */
    getLocalBdAddrFromPs();

    if (full_init)    
    {    
        /* Read and configure the button translations */
        configManagerButtonTranslations( );

        /* Read and configure the button durations */
        configManagerButtonDurations( );

        /* Read the system event configuration and configure the buttons */
        configManagerButtons( );

        /*configures the pattern button events*/
        configManagerButtonPatterns( ) ;
    }

    /*Read and configure the event tones*/
    configManagerEventTones( keyLengths->no_tones ) ;
    /* Read and configure the system features */
    configManagerFeatureBlock( );

    if (full_init)    
    { 
        /* read the audiorouting configuration */    
        configManagerAudioRouting();
    }
    
    /* Read and configure the automatic switch off time*/
    configManagerConfiguration( );

    if (full_init)    
    { 
        /* Must happen between features and session data... */
        InitA2dp();  
    }
 
    /* Read and configure the user defined tones */    
    configManagerUserDefinedTones( keyLengths->userTonesLength );	

    /* Read and configure the LEDs */
    configManagerLEDS();

    /* Read and configure the voume settings */
    configManagerVolume( );    

    if (full_init)    
    {
        /* Read and configure the power management system */
        configManagerPower( );

        /* Read and configure the radio parameters */
        configManagerRadio();

        /* init the volume levels storage before it gets used by wired or usb inputs */
        volumeInit();

        /* Read and configure the volume orientation, LED Disable state, and tts_language */
        configManagerReadSessionData ( ) ; 

        configManagerReadDspData();

        /* Read and configure the sniff sub-rate parameters */
        configManagerSetupSsr ( ) ; 

    configManagerAudioPromptEvents( keyLengths->num_audio_prompt_events ) ;

#if defined ENABLE_SQIFVP || defined ENABLE_GAIA
        /* Configure SQIF partitions */
        configManagerSqifPartitionsInit();
#endif

        /* Configure the voice prompts */
        configManagerAudioPromptsInit( keyLengths->num_audio_prompts, keyLengths->num_audio_prompt_languages );

        /* don't allocate memory for AT commands if they're not required */
        if (keyLengths->size_at_commands)
        {        
            InitConfigMemoryAtCommands(keyLengths->size_at_commands);
            configManagerAtCommands(keyLengths->size_at_commands + sizeof(config_block3_t) - 1);
        }

#ifdef ENABLE_FM
        /* read the fm configuration data */
        configManagerReadFmData();

#endif

        /* read the i2s pskey configuration */
        configManagerReadI2SConfiguration();
        
#ifdef ENABLE_SUBWOOFER
        /* Read the subwoofer configuration data */
        configManagerGetSubwooferConfig();
#endif
        
        /* Read the GATT configuration if required */
        #ifndef GATT_DISABLED
        {
            configManagerGattInit();
        }
        #endif
        
        /* Is the input manager required? If so, read the Input Manager configuration data */
        #if defined(ENABLE_IR_REMOTE)
        {
            /* Input manager is required for the IR functionality */
            configManagerInputManagerInit();
        }
        #elif defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED)
        {
            /* Has HID Over GATT profile been enabled? */
            if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
            {
                /* Input manager is required for the BLE HID Over GATT functionality */
                configManagerInputManagerInit();
            }
        }
        #endif
        
        /* Is the Infra Red configuration required? */
        #if defined(ENABLE_IR_REMOTE)
        {
            /* Read the lookup table for the IR Remote Control */
            configManagerIrRemoteControlInit();
            /* Now initialise the Infra Red Remote Controller Task */
            initIrInputMonitor( &theSink.rundata->inputManager.config->input_timers );
        }
        #endif
        
        /* Is the HID Over GATT Remote Control functionality required? */
        #if defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED)
        {
            /* Has HID Over GATT profile been enabled? */
            if (theSink.rundata->gatt.config.client & GATT_FLAG_CLIENT_HOGP)
            {
                /* Read the lookup table for the BLE HID Remote Control */
                configManagerBleRemoteControlInit();
            }
        }
        #endif
    }
    
    /* release the memory used for the lengths key */
    freePanic(keyLengths);
}


