/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_private.h
    
DESCRIPTION
    
*/

/*!

@file   sink_private.h
@brief The private data structures used by the sink device application
    
    THe main application task and global data is declared here
*/


#ifndef _SINK_PRIVATE_H_
#define _SINK_PRIVATE_H_


#ifdef INCLUDE_A2DP_EXTRA_CODECS
#ifndef INCLUDE_MP3
#define INCLUDE_MP3
#endif
#ifndef INCLUDE_AAC
#define INCLUDE_AAC
#endif
#ifndef INCLUDE_FASTSTREAM
#define INCLUDE_FASTSTREAM
#endif
#ifndef INCLUDE_APTX
#define INCLUDE_APTX
#endif
#endif /* INCLUDE_A2DP_EXTRA_CODECS */


#if defined(ENABLE_USB) && defined(ENABLE_USB_AUDIO)
/* Needed to include csr_usb_decoder_plugin in csr_a2dp_decoder_common_plugin.h */
#define INCLUDE_USB
#endif

#include <connection.h>
#include <hfp.h>
#include <usb_device_class.h>
#include <message.h>
#include <app/message/system_message.h>
#include <stdio.h>
#include <stdlib.h>
#include <charger.h>
#include <audio.h>
#include <csr_cvc_common_plugin.h>
#include <codec.h>
#include <csr_i2s_audio_plugin.h>

#ifdef ENABLE_SUBWOOFER
#include <swat.h>
#endif

#include "sink_buttonmanager.h"
/*needed for the LED manager task definition*/
#include "sink_leddata.h"
#include "sink_powermanager.h"
#include "sink_volume.h"
#include "sink_usb.h"
#include "sink_debug.h"
#include "sink_inquiry.h"
#include "sink_configmanager.h"
#include "sink_wired.h"
#include "sink_a2dp.h"
#include "sink_audio_routing.h"
#include "sink_partymode.h"
#include "sink_fm.h"
#include "sink_devicemanager.h"

#ifdef ENABLE_GAIA
#include "sink_gaia.h"
#endif

#ifdef ENABLE_PBAP
#include "sink_pbap.h"
#endif
#ifdef ENABLE_MAPC
#include "sink_mapc.h"
#endif
    
#include "sink_a2dp.h"

#ifdef ENABLE_AVRCP
#include "sink_avrcp.h"
#endif

#ifndef GATT_DISABLED
#include "sink_gatt.h"
#endif


/* Input manager */
#if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
#include "sink_input_manager.h"
#if (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
#include "sink_ble_remote_control.h"
#endif
#ifdef ENABLE_IR_REMOTE
#include "sink_ir_remote_control.h"
#endif
#endif /* Input manager */



/*needed for the AUDIO_SINK_T*/
#include <audio.h>
/*needed for the a2dp plugin AudioConnect params*/
#include <csr_a2dp_decoder_common_plugin.h>

/*the number of AT commands we support sending on given events*/
#define MAX_AT_COMMANDS_TO_SEND (8)


/*! 
    @brief Class Of Device definitions 
*/
#define AUDIO_MAJOR_SERV_CLASS  0x200000
#define AV_MAJOR_DEVICE_CLASS   0x000400
#define AV_MINOR_HEADSET        0x000004
#define AV_MINOR_MICROPHONE     0x000010
#define AV_MINOR_SPEAKER        0x000014
#define AV_MINOR_HEADPHONES     0x000018
#define AV_MINOR_PORTABLE       0x00001c
#define AV_MINOR_HIFI           0x000028
#define AV_COD_RENDER           0x040000
#define AV_COD_CAPTURE          0x080000

/* Bootmodes */
#define BOOTMODE_DFU            0x00
#define BOOTMODE_DEFAULT        0x01
#define BOOTMODE_CUSTOM         0x02
#define BOOTMODE_USB_LOW_POWER  0x03
#define BOOTMODE_CVC_PRODTEST   0x04
#define BOOTMODE_ALT_FSTAB      0x05


/* swap between profiles, when called with primary will return secondary and vice versa */
#define OTHER_PROFILE(x) (x ^ 0x3)

/* hfp profiles have offset of 1, this needs to be removed to be used as index into data array */
#define PROFILE_INDEX(x) ((x == hfp_invalid_link) ? (0) : (x - 1))
        
/*! 
    @brief Feature Block
    
    Please refer to the device configuration user guide document for details on the 
    features listed here 
*/
typedef struct
{
    unsigned    ReconnectOnPanic:1; 
    unsigned    OverideFilterPermanentlyOn:1 ;
    unsigned    MuteSpeakerAndMic:1 ;
    unsigned    PlayTonesAtFixedVolume:1 ;
    
    unsigned    PowerOffAfterPDLReset:1 ;
    unsigned    RemainDiscoverableAtAllTimes:1;
    unsigned    DisablePowerOffAfterPowerOn:1;
    unsigned    AutoAnswerOnConnect:1;

    unsigned    EnterPairingModeOnFailureToConnect:1 ;
    unsigned    PartyMode:2;                            /* selection of 'PartyModes' available on soundbars */
    unsigned    AdjustVolumeWhilstMuted:1;              /*whether or not to update the global vol whilst muted*/   
    
    unsigned    VolumeChangeCausesUnMute:1 ;            /*whether or not to unmute if a vol msg is received*/
    unsigned    PowerOffOnlyIfVRegEnLow:1;    
    unsigned    LimitRssiSuboowferPairing:1;            /* Enable subwoofer RSSI pairing to ensure signal strenght is higher than the configured threshold */
    unsigned    pair_mode_en:1;
    
     /*---------------------------*/           
    unsigned    GoConnectableButtonPress:1;    
    unsigned    DisableAudioPromptTerminate:1;   
    unsigned    AutoReconnectPowerOn:1 ;
    unsigned    speech_rec_enabled:1 ;
    unsigned    SeparateLNRButtons:1 ;
    unsigned    SeparateVDButtons: 1;
    unsigned    batteryReporting:2;
    unsigned    PowerDownOnDiscoTimeout: 2;
    unsigned    ActionOnCallTransfer:2;    
    unsigned    LedTimeMultiplier: 2; /* multiply the times of the LED settings (x1 x2 x4 x8) */
    unsigned    ActionOnPowerOn:2;
    
     /*---------------------------*/   

    unsigned    DiscoIfPDLLessThan:4 ; 
    
    unsigned    DoNotDiscoDuringLinkLoss:1;
    unsigned    ManInTheMiddle:1;
    unsigned    UseDiffConnectedEventAtPowerOn:1;    
    unsigned    EncryptOnSLCEstablishment:1 ;    
    
    unsigned    UseLowPowerAudioCodecs:1;
    unsigned    PlayLocalVolumeTone:1;   
    unsigned    SecurePairing:1;
    unsigned    PowerOffOnWiredAudioConnected:1; /* If set, the Sink is powered off when the wired audio is connected*/  
    
    unsigned    QueueVolumeTones:1;
    unsigned    QueueEventTones:1;
    unsigned    QueueLEDEvents:1;
    unsigned    MuteToneFixedVolume:1;  /* play mute tone at default volume level when set */

     /*---------------------------*/   
    
    unsigned    ResetLEDEnableStateAfterReset:1;    /* if set the LED disable state is reset after boot */
    unsigned    ResetAfterPowerOffComplete:1 ;
    unsigned    AutoPowerOnAfterInitialisation:1 ;  
    unsigned    DisableRoleSwitching:1;     /* disable the device role switching in multipoint connections */
    unsigned    audio_plugin:4; /* which of the audio plugins we want to use */
    
    unsigned    DefaultVolume:4 ;     
    unsigned    IgnoreButtonPressAfterLedEnable:1 ; /* if set the button press that enabled the LED's is ignored */
    unsigned    LNRCancelsVoiceDialIfActive:1 ; 
    unsigned    GoConnectableDuringLinkLoss:1 ; 
    unsigned    unused:1 ; 
    
    /*------------------------------*/
    unsigned    ChargerTerminationLEDOveride:1; /* used to force trickle led on when full and stop led toggling */
    unsigned    FixedToneVolumeLevel:5;         /* the level at which the tones are played when using the play at fixed level */
    unsigned    EnableAvrcpAudioSwitching:1 ;   /* use AVRCP play status to speed up audio source switching */
    unsigned    ForceEV3S1ForSco2:1;            /* force use of EV3 safe settings for second sco */
    unsigned    VoicePromptPairing:1;           /* Read out PIN/Passkey/Confirmation using voice prompts */
    unsigned    avrcp_enabled:1;                  
    unsigned    PairIfPDLLessThan: 2;           /* Use RSSI on inquiry responses to pair to nearest AG */
    unsigned    EnableSyncMuteMicrophones: 1;
    unsigned    ActionOnPanicReset: 2 ;                
    unsigned    VoicePromptNumbers:1;           /* Read out numbers using voice prompts */
    
    /*------------------------------*/
    unsigned    DefaultA2dpVolLevel:4 ;         /* Default A2dp Vol Level */
    unsigned    pbap_enabled: 1 ;
    unsigned    EnableA2dpStreaming:1 ;         /* Enable A2DP streaming  */
    unsigned    A2dpOptionalCodecsEnabled:5;    /* Optional A2DP codecs */
    unsigned    EnableA2dpMediaOpenOnConnection:1;/*if enable will open media channel on a2dp connect */  
    unsigned    AssumeAutoSuspendOnCall:1;      /* Assume a device that supports both HF and A2DP will suspend itself in a non-idle call state */
    unsigned    ReconnectLastAttempts:3;        /* Number of times to attempt to connect last AG */
    
    /*------------------------------*/
    unsigned    ShareMeSource:1;                /* Device supports relay of audio to another ShareMe device */
    unsigned    ShareMeSink:1;                  /* Device supports receiving of audio relayed from another ShareMe device */
    unsigned    TwsSource:1;                    /* Device supports relay of audio to another TWS device */
    unsigned    TwsSink:1;                      /* Device supports receiving of audio relayed from another TWS device */
    unsigned    PeerUseLiac:1;                  /* Peer devices will use the LIAC, instead of the GIAC, for pairing */
    unsigned    PeerUseDeviceId:1;              /* Peer devices will use the Device Id record to filter suitable devices */
    unsigned    PeerUseCsrUuid:1;               /* Peer device SDP record will present a CSR defined 128 bit service UUID */
    unsigned    ShareMePairingMode:2;           /* How pairing information is retained for ShareMe devices */
    unsigned    TwsSingleDeviceOperation:1;     /* In a TWS session, devices behave as a single unit for AVRCP operation */
    unsigned    TwsMasterAudioRouting:2;        /* Audio channels rendered by a TWS Master, when in a TWS session */
    unsigned    TwsSlaveAudioRouting:2;         /* Audio channels rendered by a TWS Slave, when in a TWS session */
    unsigned    TwsPairingMode:2;               /* How pairing information is retained for TWS devices */

    /*------------------------------*/
    unsigned    ShareMePeerControlsSource:1;    /* AVRCP commands received from a ShareMe Peer are forwarded to an AV Source */
    unsigned    PeerSource:2;                   /* Initial source used for new TWS connections */
    unsigned    PeerLinkRecoveryWhileStreaming:1;  /* Master Peer device will attempt to page a Slave Peer during linkloss while streaming */
    unsigned    :9;                            /* Unused */
    unsigned    AmplifierShutDownByPIO:1;       /* TRUE: Audio amplifier shut down mode managed by PIO control, FALSE: Disable feature */
    unsigned    GaiaEnableSession:1;            /* GAIA session enabled on connection */
    unsigned    GaiaRemainConnected:1;          /* GAIA connection remains after power off */
    
}feature_config_type;

/*!
    @brief the custom UUIDs for peer devices
*/
typedef struct
{
    /*-------- WORDS 1..8 ---------*/
    uint16 ShareMeUuid[8];                      /* Custom UUID for identifying ShareMe capable devices.  Big Endian Ordering */
    /*-------- WORDS 9..16 --------*/
    uint16 TwsUuid[8];                          /* Custom UUID for identifying TWS capable devices.  Big Endian Ordering */
}peer_custom_uuid_type;

/*!
    @brief the audio routing configuration
*/
typedef struct
{
    /*-------- WORD 1 ----------------------*/
    AudioPluginFeatures PluginFeatures;         /* audio plugin features including input and output hardware selection */
    /*---------WORD 2/3 --------------------*/
    spdif_ac3_configuration SpdifAC3Settings;   /* two words of spdif AC3 configuration */
    /*---------WORD 4/5 ----------------------*/
    silence_detect_settings SilenceDetSettings; /* two words of silecnce detection settings */
    /*---------WORD 6 ----------------------*/
    spdif_target_latency TargetLatency;         /* one word of target latency, valid range of 0 to 150 */
}audio_routing_config_type;

#define TONE_NOT_DEFINED 0

/*!
    @brief the volume mapping structure - one for each volume level
*/
typedef struct  VolMappingTag
{
        /*! The hfp volume level to go to when volume up is pressed*/
    unsigned       IncVol:4;
        /*! The hfp volume level to go to when volume down is pressed*/
    unsigned       DecVol:4;
        /*! The tone associated with a given volume level*/
    unsigned       Tone:8;  
        /*! The a2dp gain index to use for the given volume level */
    unsigned       A2dpGain:8;
       /*! the hfp DAC gain to use for the given volume level */
    unsigned       VolGain:8;    
    
}VolMapping_t ;



/* volume configuration including both DAC and DSP volume control settings */
typedef struct
{
    dsp_volume_user_config volume_control_config;
    VolMapping_t           gVolMaps[VOL_NUM_VOL_SETTINGS];
}volume_configuration_t;

#define NUM_FIXED_TONES            (94)    
#define MAX_NUM_VARIABLE_TONES     (8)

typedef struct VarTonesDataTag
{
    ringtone_note    *gVariableTones;    
}ConfigTone_t;

/*!
    @brief Block containing the PIOs assigned to fixed events the bit fields define if a PIO has been set
*/
typedef struct PIO_block_t
{
    unsigned    CallActivePIO:8   ;
    unsigned    IncomingRingPIO:8 ;   
    unsigned    OutgoingRingPIO:8 ;
    unsigned    DeviceAudioActivePIO:8;
    
    unsigned    PowerOnPIO:8      ;
    unsigned    spdif_output:8;
    unsigned    LedEnablePIO:8 ;
    unsigned    AudioMutePIO:8;
    
} PIO_block_t ;

/* We need a fixed value to check if PIOs are mappped to the signals above or not before driving */
#define NO_PIO 0xFF

 /* We need a type to be used as part of audio amplifier power control for PowerOnPIO signal given above*/
typedef enum {
  POWER_DOWN = 0,
  POWER_UP
} power_control_dir ;

typedef struct
{
    unsigned spdif_detect:8;
    unsigned analog_input:8;
    unsigned charger_input:8;
    unsigned dut_pio:8;
    unsigned spdif_input:8;
    unsigned unused0:8;
}input_pio_config_type;

typedef struct
{
    input_pio_config_type   pio_inputs;
    PIO_block_t             pio_outputs;
    uint32                  pio_invert;      /* bit mask used to invert button pios, 1 = inverted */
    const common_mic_params digital;         /* Digitial mic enables/PIOs */
    uint32                  pio_map;         /* Pins to map (see PioSetMapPins32 in pio.h) */
}pio_config_type;

/* Radio configuration data */
typedef struct
{
    uint16  page_scan_interval;
    uint16  page_scan_window;
    uint16  inquiry_scan_interval;
    uint16  inquiry_scan_window;
}radio_config_type;

#define HFP_ADDITIONAL_AUDIO_PARAMS_ENABLED 0x8000U

typedef struct 
{
    /* Enable use of audio params */
    unsigned            additional_audio_params:1;
    unsigned            unused:5;
    /* Supported packet types */
    sync_pkt_type       packet_types:10;
    /* Audio parameters */
    hfp_audio_params    audio_params;
} HFP_features_type ;

    /*the application timeouts / counts */
typedef struct TimeoutsTag
{
    uint16 AutoSwitchOffTime_s ;
    uint16 LimboTimeout_s ;
    uint16 NetworkServiceIndicatorRepeatTime_s ;    
    uint16 DisablePowerOffAfterPowerOnTime_s ;
    uint16 PairModeTimeout_s ;
    uint16 MuteRemindTime_s ;
    uint16 ConnectableTimeout_s ;   
    uint16 PairModeTimeoutIfPDL_s;
    uint16 ReconnectionAttempts ;       /* number of times to try and reconnect before giving up */
    uint16 EncryptionRefreshTimeout_m ;
    uint16 InquiryTimeout_s ;
    uint16 SecondAGConnectDelayTime_s;
    uint16 MissedCallIndicateTime_s ;  /* The period in second between two indications */
    uint16 MissedCallIndicateAttemps ; /* number of times to indicate before stopping indication */
    uint16 A2dpLinkLossReconnectionTime_s; /* the amount of time in seconds to attempt to reconnect a2dp */
    uint16 LanguageConfirmTime_s;   /* The time between EventUsrSelectAudioPromptLanguageMode and storing the language in PS */
    uint16 SpeechRecRepeatTime_ms;  /* the between voice prompts ASR restarts */
    uint16 StoreCurrentSinkVolumeTimeout_s; /* The time in seconds elapsed after the last VolumeUp/Down button was pressed, 
                                                                                to store the volume information into PS Store*/
    uint16 WiredAudioConnectedPowerOffTimeout_s; /* The time in seconds elapsed before the device is powered off after the 
                                                                                    wired audio is connected */   
    uint16 StoreCurrentPEQSettingsTimeout_s; /* The time in seconds elapsed after the last GAIA command has been received to store EQ settings into PS Store */
    uint16 DefragCheckTimer_s;  /* the interval in seconds to check the status of the PS and defragment if necessary */
    uint16 AudioAmpPowerDownTimeoutInLimbo_s; /* The period in seconds for which the system waits before powering down audio amplifier for sound bar when in Limbo state  */
}Timeouts_t ;

#define MAX_POWER_TABLE_ENTRIES 8

typedef struct
{
    unsigned        normalRole:2;       /* Master (0), Slave (1) or passive (2) */
    unsigned        normalEntries:2;    /* 0-2 */

    unsigned        SCORole:2;          /* Master (0), Slave (1) or passive (2) */
    unsigned        SCOEntries:2;       /* 0-2 */
  
    unsigned        A2DPStreamRole:2;   /* Master (0), Slave (1) or passive (2) */
    unsigned        A2DPStreamEntries:2;/* 0-2 */
       
    /* pointers to arrays of lp_power_tables */
    lp_power_table powertable[1];

} power_table;


typedef struct
{
    uint16          max_remote_latency;
    uint16          min_remote_timeout;
    uint16          min_local_timeout;
} ssr_params;


typedef struct
{
    ssr_params      slc_params;
    ssr_params      sco_params;
} subrate_t;

typedef enum
{
    hfp_no_hf_initiated_audio_transfer,
    hfp_usual_hf_initiated_audio_transfer,
    hfp_power_on_hf_initiated_audio_transfer
} hfp_hf_initiated_audio_transfer_type;

#define MAX_MULTIPOINT_CONNECTIONS  2        /* max number of mulitpoint connections  */
#define MAX_PROFILES                2

typedef struct                              /* 1 word of storage for hfp status info */
{
    unsigned        list_id:8;               /* store the PDL list ID for this connection, used for link loss and preventing reconnection */
    unsigned        local_call_action:1;     /* call answered/rejected locally */
    unsigned        connected:1;             /* flag to signifiy that profile[?] is connected */
}profile_status_info;

/* this is the list of sco audio priorities, it is used to determine which audio is routed by the
   device in multipoint situations, the further up the list will get routed first so be careful
   not to change the order without careful thought of the implications of doing so */
typedef enum
{
    sco_none,
    sco_about_to_disconnect,
    sco_streaming_audio,
    sco_inband_ring,
    sco_held_call,
    sco_active_call    
}audio_priority;
        
typedef struct                              /* storage of audio connection data on a per hfp isntance basis */
{
    audio_priority      sco_priority;        /* the priority level of the sco */
    uint32              tx_bandwidth;       
    sync_link_type      link_type:2;          /* link type may be different between AG's and needs to be stored for reorouting audio */
    hfp_wbs_codec_mask  codec_selected:6; /* audio codec being used with this profile */
    unsigned            gSMVolumeLevel:7;   /* volume level for this profile */
    unsigned            gMuted:1;
}profile_audio_info;

typedef struct 
{
    profile_status_info status;         /* status for each profile, in hfp index order */
    profile_audio_info  audio;           /* audio connection details used for re-routing audio */   
}profile_data_t ;

#ifdef ENABLE_SUBWOOFER
typedef struct
{
    bdaddr              bd_addr;        /* The Bluetooth address of the paired subwoofer */
    sync_config_params  esco_params;    /* The SWAT eSCO parameters */
    
    unsigned        dev_id:4;           /* Store the subwoofer device ID for SWAT */
    unsigned        sub_trim_idx:8;     /* Used to store the current sub_trim index value */
    unsigned        check_pairing:1;    /* Flag set when a subwoofer exists as the only PDL so start pairing */
    
    unsigned        sub_trim:8;         /* 8 bits used to keep track of the subwoofer trim gain */
    unsigned        swat_volume:8;      /* 8 bits used to keep track of the SWAT system volume */
    
    unsigned        inquiry_attempts:8; /* number of times to try an inquiry scan */    
    
} subwooferData_t;
#endif

#ifdef ENABLE_GAIA
/*  Gaia settings  */
typedef struct
{
    GAIA_TRANSPORT *gaia_transport;
    
    uint32 pio_change_mask;
    uint32 pio_old_state;
    ringtone_note *alert_tone;
    
    unsigned notify_ui_event:1;
    unsigned notify_charger_connection:1;
    unsigned notify_battery_charged:1;
    unsigned notify_speech_rec:1;
    unsigned dfu_partition:4;
    unsigned dfu_boot_status:2;
    unsigned unused:6;
    
} gaia_settings_t;
#endif


/* runtime data stored in block */
typedef struct
{
#ifdef ENABLE_GAIA    
    gaia_settings_t        gaia_data;
#endif            
    sink_battery_limits battery_limits; 
    defrag_config          defrag;  
    uint16                 old_state;
    uint16                 connection_in_progress; /* flag used to block role switch requests until all connections are complete or abandoned */
    
#ifdef ENABLE_SQIFVP  
    unsigned               partitions_mounted:8;  /* mask of SQIF partitons currently mounted */
    unsigned               partitions_free:8;     /* mask of SQIF partitions available to use */
#endif
    
#ifdef ENABLE_MAPC
    /* Data for mapc feature */
    mapcData_t             mapc_data;    
#endif    
    /* runtime data for the currently routed audio source */
    audio_sources          requested_audio_source;
    audio_sources          routed_audio_source;

#ifdef ENABLE_PARTYMODE
    pty_pause_state_t       partymode_pause;
#endif
    
    /* task data for codec lib */
    CsrInternalCodecTaskData codec;
    /*WolfsonCodecTaskData     codec;*//* - if using Wolfson codec */


/* Input manager data */
#if defined(ENABLE_IR_REMOTE) || (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
    inputManagerTaskData_t  inputManager;
#if (defined(BLE_ENABLED) && defined(GATT_CLIENT_ENABLED))
    bleHidRCTaskData_t      bleInputMonitor;
#endif
#ifdef ENABLE_IR_REMOTE
    irRCTaskData_t          irInputMonitor;
#endif
#endif /* Input manager data */

#ifdef ENABLE_SUBWOOFER
    subwooferData_t         subwoofer;
#endif

#ifndef GATT_DISABLED
    gattRuntimeData_t       gatt;
#endif
    
    
}runtime_block1_t; 

/* Because of dynamically allocation constraints we have to use a single malloc for different PSKeys */
typedef struct
{
    button_config_type     buttons_duration;
    volume_configuration_t volume_config;
    Timeouts_t             timeouts;
    pio_config_type        PIOIO;   
    sink_power_settings power;   
} config_block1_t;

typedef struct
{
    audio_routing_config_type   audio_routing_data;
#ifdef ENABLE_FM
    fm_data                     sink_fm_data;
#endif
    subrate_t                   ssr_data;     
    radio_config_type           radio;
    rssi_pairing_t              rssi;
    dsp_data_type               dsp_data;
    /* Always one termination tone, additional space added in InitConfigMemory */
    tone_config_type            gEventTones[1]; 
    /* DONT ADD ANYTHING HERE OR IT WILL GET OVERWRITTEN BY THE TONES */
} config_block2_t;


typedef struct 
{
    uint16   event;
    unsigned unused:8;
    unsigned at_cmd:8;
} at_cmd_events_t ;

typedef struct 
{   
    at_cmd_events_t gEventATCommands[MAX_AT_COMMANDS_TO_SEND] ;    
    char            at_commands[1];
    /* don't add anything here, it will get overwritten by at command data */
} config_block3_t;

typedef struct
{
    /* Always one termination prompt, additional space added in InitConfigMemory */
    audio_prompts_config_type     audioPromptEvents[1];
    /* don't add anything here, it will get overwritten by the audio prompts data */
} config_block4_t;

/* config_block5_t is i2s pskey configuration combining both init and volume config pskeys and data */
typedef struct
{
    /* ps configuration data for the i2s output functionality */
    I2SConfiguration i2s_ps_config;
} config_block5_t;

typedef struct
{
    unsigned :1;
    unsigned current_state:3;
    unsigned current_source:2;
    unsigned target_state:3;
    unsigned target_source:2;
    unsigned required_state:3;
    unsigned required_source:2;
} peer_states_t;

/* Sink application data */
typedef struct
{
    /* Main task */
    TaskData                 task;
    
    /* Config variables */
    ButtonsTaskData          *theButtonsTask;
    LedTaskData              *theLEDTask;
    runtime_block1_t         *rundata;
    config_block1_t          *conf1;
    config_block2_t          *conf2;
    config_block3_t          *conf3;
    config_block4_t          *conf4;
    config_block5_t          *conf5;
   
    ConfigTone_t              gConfigTones;
    
    volume_levels_t          *volume_levels;        /* current operating volume levels for a2dp/usb/wired modes */
    
    power_table              *user_power_table;     /* pointer to user power table if available in ps */
    cvc_plugin_params        cvc_params;
    HFP_features_type        HFP_supp_features;
    feature_config_type      features;
    bdaddr                       local_bd_addr; /* Local BD Address of the sink device available in ps */

    /* Runtime variables */
    Task                     codec_task ;
    Sink                     routed_audio;
    uint16                   NoOfReconnectionAttempts;
    profile_data_t           profile_data[MAX_MULTIPOINT_CONNECTIONS];
    a2dp_data                *a2dp_link_data;
#ifdef ENABLE_AVRCP
    avrcp_data               *avrcp_link_data;
#endif    
    typed_bdaddr             *confirmation_addr;
    inquiry_data_t           inquiry;

#ifdef ENABLE_PBAP
    pbapc_data_t             pbapc_data;
#endif
#ifdef ENABLE_USB
    usb_info                 usb;
#endif
#ifdef ENABLE_PEER
    bdaddr remote_peer_ag_bd_addr;
#endif
    user_eq_bank_t        *PEQ;

    /*! Runtime flags*/
    /*word 1*/
    unsigned                 PowerOffIsEnabled:1; 
    unsigned                 SinkInitialising:1;
    unsigned                 VolumeOrientationIsInverted:1; /*whether or not the vol buttons are inverted*/
    unsigned                 NetworkIsPresent:1;
    
    unsigned                 inquiry_scan_enabled:1;
    unsigned                 page_scan_enabled:1 ;
    unsigned                 csr_speech_recognition_is_active:1 ;
    unsigned                 csr_speech_recognition_tuning_active:1 ;         
    
    unsigned                 panic_reconnect:1;              
    unsigned                 last_outgoing_ag:2 ;   /* which AG made the last outgoing call */
    unsigned                 audio_prompts_enabled:1;
    
    unsigned                 confirmation:1;
    unsigned                 debug_keys_enabled:1;
    unsigned                 RepeatCallerIDFlag:1;
    unsigned                 sink_mute_status:1;
    
    /*word 2*/
    unsigned                 audio_prompt_language:4; 
    unsigned                 num_audio_prompt_languages:4;
    unsigned                 MultipointEnable:1;
    unsigned                 powerup_no_connection:1;    /* bit to indicate device has powered and no connections yet */
    unsigned                 paging_in_progress:1;       /* bit to indicate that device is curretly paging whilst in connectable state */
    unsigned                 audioAmpPowerPin:1;		 /* bit to indicate logic state of audio amplifier power pin */
    
    unsigned                 battery_state:3;
    unsigned                 gVolButtonsInverted:1;    /*! whether or not the volume button operation is currently inverted*/  
   
    /*word 3*/
    unsigned                 FailAudioNegotiation:1;
    unsigned                 RenegotiateSco:1;       
    unsigned                 lbipmEnable:1;             /* enable Low Battery Intelligent Power Management feature */
    unsigned                 buttons_locked:1;          /* Flag to indicate if button locking is enabled */

    unsigned                 HeldCallIndex:4;           /* which call to route in the case of multiple held calls */ 

    unsigned                 inquiry_tx:8;

    /*word 4*/
    unsigned                 MissedCallIndicated:8;
    unsigned                 gEventQueuedOnConnection:8 ;

    /*word 5*/
    unsigned                 unused3:5 ;
    unsigned                 hfp_profiles:3;
    unsigned                 ssr_enabled:1;
    unsigned                 VoiceRecognitionIsActive:2;
    unsigned                 PartyModeEnabled:1;
#ifdef ENABLE_PEER    
    unsigned                 remote_peer_audio_conn_status:3; /* Flag to indicate which Audio sources are connected to the remote peer */
    unsigned                 unused4:1;
#else
    unsigned                 unused4:4;
#endif
    
    /* word 6 */
    unsigned                 gated_audio:8;              /* Bitmask indicating which audio sources are prevented from being routed */
    unsigned                 linkLossReminderTime:8;
    
    /* word 7 */
    peer_states_t            peer;
} hsTaskData;

/*malloc wrapper with added panic if malloc returns NULL*/


#ifdef DEBUG_MALLOC
    #define mallocPanic(x) MallocPANIC( __FILE__ , __LINE__ ,x) 
    void * MallocPANIC ( const char file[], int line, size_t pSize ) ;
    #define freePanic(x) FreePANIC( __FILE__ , __LINE__ ,x) 
    void FreePANIC ( const char file[], int line, void * ptr ) ;
#else
    #define mallocPanic(x) malloc(x)
    #define freePanic(x) free(x)
#endif


/*the device task data structure - visible to all (so don't pass it between functions!)*/
extern hsTaskData theSink ;


#endif /* SINK_PRIVATE_H_ */
