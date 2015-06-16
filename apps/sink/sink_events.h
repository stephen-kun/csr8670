/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_events.h
    
DESCRIPTION
    Defines sink application user events
    
*/
#ifndef SINK_EVENTS_H
#define SINK_EVENTS_H


#ifndef BC4_HS_CONFIGURATOR
    #include <connection.h>
    #include <message.h>
    #include <app/message/system_message.h>
    #include <stdio.h>
#endif


#define EVENTS_MESSAGE_BASE (0x4000)
#define EVENTS_USR_MESSAGE_BASE (EVENTS_MESSAGE_BASE)
#define EVENTS_SYS_MESSAGE_BASE (EVENTS_USR_MESSAGE_BASE + 0x0700)

/*This enum is used as an index in an array - do not edit - without thinking*/
typedef enum sinkEventsTag
{
    /* USER EVENTS */    
    
/*0x4000*/    EventInvalid = EVENTS_USR_MESSAGE_BASE,    
/*0x4001*/    EventUsrPowerOn , 
/*0x4002*/    EventUsrPowerOff ,  
/*0x4003*/    EventUsrEnterPairing ,
    
/*0x4004*/    EventUsrInitateVoiceDial ,
/*0x4005*/    EventUsrInitateVoiceDial_AG2,            
/*0x4006*/    EventUsrLastNumberRedial ,
/*0x4007*/    EventUsrLastNumberRedial_AG2,
            
/*0x4008*/    EventUsrAnswer , 
/*0x4009*/    EventUsrReject ,     
/*0x400A*/    EventUsrCancelEnd , 
/*0x400B*/    EventUsrTransferToggle ,
           
/*0x400C*/    EventUsrMuteToggle   ,
/*0x400D*/    EventUsrVolumeUp  ,
/*0x400E*/    EventUsrVolumeDown ,
/*0x400F*/    EventUsrVolumeToggle,
            
/*0x4010*/    EventUsrThreeWayReleaseAllHeld,
/*0x4011*/    EventUsrThreeWayAcceptWaitingReleaseActive,    
/*0x4012*/    EventUsrThreeWayAcceptWaitingHoldActive  ,
/*0x4013*/    EventUsrThreeWayAddHeldTo3Way  ,
            
/*0x4014*/    EventUsrThreeWayConnect2Disconnect,  
/*0x4015*/    EventUsrLedsOnOffToggle ,    
/*0x4016*/    EventUsrLedsOn,
/*0x4017*/    EventUsrLedsOff,
            
/*0x4018*/    EventUsrEstablishSLC ,
/*0x4019*/    EventUsrMuteOn ,            
/*0x401A*/    EventUsrMuteOff ,           
/*0x401B*/    EventUsrEnterTXContTestMode,
            
/*0x401C*/    EventUsrEnterDUTState,            
/*0x401D*/    EventUsrBassBoostEnableDisableToggle,            
/*0x401E*/    EventUsrPlaceIncomingCallOnHold,
/*0x401F*/    EventUsrAcceptHeldIncomingCall,
            
/*0x4020*/    EventUsrRejectHeldIncomingCall,
/*0x4021*/    EventUsrEnterDFUMode,            
/*0x4022*/    EventUsrEnterDriverlessDFUMode,                        
/*0x4023*/	EventUsrEnterServiceMode,    
            
/*0x4024*/    EventUsrAudioPromptsOn,
/*0x4025*/    EventUsrAudioPromptsOff,              
/*0x4026*/	EventUsrDialStoredNumber,
/*0x4027*/    EventUsrUpdateStoredNumber,  
                       
/*0x4028*/	EventUsrRestoreDefaults,            
/*0x4029*/	EventUsrConfirmationAccept,
/*0x402A*/	EventUsrConfirmationReject,           
/*0x402B*/	EventUsrSelectAudioPromptLanguageMode,
            
/*0x402C*/	EventUsrUnused402C, /* Spare user event */            
/*0x402D*/	EventUsrMultipointOn,
/*0x402E*/	EventUsrMultipointOff,
/*0x402F*/    EventUsrSwitchAudioMode,
            
/*0x4030*/	EventUsrButtonLockingOn,           
/*0x4031*/	EventUsrButtonLockingOff,
/*0x4032*/	EventUsrButtonLockingToggle,   
/*0x4033*/    EventUsrPartyModeToggle,          
       
/*0x4034*/    EventUsrRssiPair,                    
/*0x4035*/    EventUsrBassBoostOn,            
/*0x4036*/	EventUsrBassBoostOff,            
/*0x4037*/	EventUsr3DEnhancementOn,
            
/*0x4038*/	EventUsr3DEnhancementOff,          
/*0x4039*/    EventUsrSelectAudioSourceNext,
/*0x403A*/    EventUsrSelectAudioSourceAnalog,   
/*0x403B*/    EventUsrSelectAudioSourceUSB,    
            
/*0x403C*/    EventUsrSelectAudioSourceAG1, 
/*0x403D*/    EventUsrSelectAudioSourceAG2,   
/*0x403E*/    EventUsrSelectFMAudioSource,  
/*0x403F*/    EventUsrSelectAudioSourceNone,                 
            
/*0x4040*/    EventUsrPbapDialIch, 
/*0x4041*/    EventUsrPbapDialMch,    
/*0x4042*/    EventUsrIntelligentPowerManagementOn,      
/*0x4043*/    EventUsrIntelligentPowerManagementOff,  
            
/*0x4044*/    EventUsrIntelligentPowerManagementToggle,                 
/*0x4045*/    EventUsrAvrcpPlayPause,            
/*0x4046*/    EventUsrAvrcpStop,
/*0x4047*/    EventUsrAvrcpSkipForward,
            
/*0x4048*/    EventUsrAvrcpSkipBackward,
/*0x4049*/    EventUsrAvrcpFastForwardPress,           
/*0x404A*/    EventUsrAvrcpFastForwardRelease,
/*0x404B*/    EventUsrAvrcpRewindPress,
            
/*0x404C*/    EventUsrAvrcpRewindRelease,    
/*0x404D*/    EventUsrAvrcpShuffleOff,
/*0x404E*/    EventUsrAvrcpShuffleAllTrack,
/*0x404F*/    EventUsrAvrcpShuffleGroup,
            
/*0x4050*/    EventUsrAvrcpRepeatOff,
/*0x4051*/    EventUsrAvrcpRepeatSingleTrack,
/*0x4052*/    EventUsrAvrcpRepeatAllTrack,
/*0x4053*/    EventUsrAvrcpRepeatGroup,
            
/*0x4054*/    EventUsrAvrcpPlay,
/*0x4055*/    EventUsrAvrcpPause,                
/*0x4056*/    EventUsrAvrcpToggleActive,
/*0x4057*/    EventUsrAvrcpNextGroup,
            
/*0x4058*/    EventUsrAvrcpPreviousGroup,                     
/*0x4059*/    EventUsrPbapSetPhonebook,            
/*0x405A*/    EventUsrPbapBrowseEntry,
/*0x405B*/    EventUsrPbapBrowseList,
            
/*0x405C*/    EventUsrPbapDownloadPhonebook,
/*0x405D*/	EventUsrPbapSelectPhonebookObject,            
/*0x405E*/	EventUsrPbapBrowseComplete,
/*0x405F*/    EventUsrPbapGetPhonebookSize,            

/*0x4060*/    EventUsrUsbPlayPause,
/*0x4061*/    EventUsrUsbStop,
/*0x4062*/    EventUsrUsbFwd,
/*0x4063*/    EventUsrUsbBack,       
                                 
/*0x4064*/    EventUsrUsbMute,
/*0x4065*/    EventUsrUsbLowPowerMode,              
/*0x4066*/    EventUsrTestModeAudio,   
/*0x4067*/    EventUsrTestModeTone,   
            
/*0x4068*/    EventUsrTestModeKey,     
/*0x4069*/    EventUsrTestDefrag,                  
/*0x406A*/	EventUsrDebugKeysToggle,   
/*0x406B*/	EventUsrSpeechRecognitionTuningStart,   
            
/*0x406C*/    EventUsrWbsTestSetCodecs,
/*0x406D*/    EventUsrWbsTestOverrideResponse,        
/*0x406E*/    EventUsrWbsTestSetCodecsSendBAC,
/*0x406F*/    EventUsrCreateAudioConnection,            
            
/*0x4070*/    EventUsrGaiaUser1,
/*0x4071*/    EventUsrGaiaUser2,
/*0x4072*/    EventUsrGaiaUser3,
/*0x4073*/    EventUsrGaiaUser4,

/*0x4074*/    EventUsrGaiaUser5,
/*0x4075*/    EventUsrGaiaUser6,
/*0x4076*/    EventUsrGaiaUser7,
/*0x4077*/    EventUsrGaiaUser8,            
          
/*0x4078*/    EventUsrFmRxOn,
/*0x4079*/    EventUsrFmRxOff,
/*0x407A*/    EventUsrFmRxTuneUp,
/*0x407B*/    EventUsrFmRxTuneDown,
            
/*0x407C*/    EventUsrFmRxStore,
/*0x407D*/    EventUsrFmRxTuneToStore,     
/*0x407E*/	  EventUsrFmRxErase,            
/*0x407F*/    EventUsrSwapA2dpMediaChannel,  
            
/*0x4080*/    EventUsrExternalMicConnected,            
/*0x4081*/    EventUsrExternalMicDisconnected,
/*0x4082*/    EventUsrSSROn,            
/*0x4083*/    EventUsrSSROff,   
            
/*0x4084*/    EventUsrNFCTagDetected,
/*0x4085*/    EventUsrSubwooferStartInquiry,
/*0x4086*/    EventUsrSubwooferVolumeDown,
/*0x4087*/    EventUsrSubwooferVolumeUp,     
            
/*0x4088*/    EventUsrSubwooferDeletePairing,
/*0x4089*/    EventUsrPeerSessionInquire,
/*0x408A*/    EventUsrPeerSessionConnDisc,
/*0x408B*/    EventUsrPeerSessionEnd,

/*0x408C*/    EventUsrBatteryLevelRequest ,
/*0x408D*/    EventUsrVolumeOrientationNormal,
/*0x408E*/    EventUsrVolumeOrientationInvert,
/*0x408F*/    EventUsrResetPairedDeviceList,

/*0x4090*/    EventUsrEnterDutMode ,
/*0x4091*/	  EventUsr3DEnhancementEnableDisableToggle,
/*0x4092*/    EventUsrRCVolumeUp,
/*0x4093*/    EventUsrRCVolumeDown,
              
/*0x4094*/    EventUsrEnterBootMode2,   
/*0x4095*/    EventUsrChargerConnected,
/*0x4096*/    EventUsrChargerDisconnected,    
/*0x4097*/    EventUsrSubwooferDisconnect,   

/*0x4098*/    EventUsrAnalogAudioConnected,
/*0x4099*/    EventUsrAnalogAudioDisconnected,
/*0x409A*/    EventUsrGaiaDFURequest,

/*0x409B*/    EventUsrStartIRLearningMode,
/*0x409C*/    EventUsrStopIRLearningMode,
/*0x409D*/    EventUsrClearIRCodes,
/*0x409E*/    EventUsrUserEqOn,
              
/*0x409F*/    EventUsrUserEqOff,
/*0x40A0*/    EventUsrUserEqOnOffToggle,

/*0x40A1*/    EventUsrBleEnablePairingMode,
/*0x40A2*/    EventUsrBleDisablePairingMode,
/*0x40A3*/    EventUsrBleEnablePtsTestMode,
/*0x40A4*/    EventUsrBleDisablePtsTestMode,
/*0x40A5*/    EventUsrBleConnectStoredRemote,
/*0x40A6*/    EventUsrBleDisconnectStoredRemote,
/*0x40A7*/    EventUsrBlePtsModeNext,
/*0x40A8*/    EventUsrBleChangeWriteModePriority,
/*0x40A9*/    EventUsrBleEnterSuspendMode,
/*0x40AA*/    EventUsrBleExitSuspendMode,
/*0x40AB*/    EventUsrBleEnableNotifications,
/*0x40AC*/    EventUsrBleDisableNotifications,

/*0x40AD*/    EventUsrSpdifAudioConnected,
/*0x40AE*/    EventUsrSpdifAudioDisconnected,
/*0x40AF*/    EventUsrSelectAudioSourceSpdif,

/*0x40B0*/    EventUsrChangeAudioRouting,
/*0x40B1*/    EventUsrMasterDeviceTrimVolumeUp,
/*0x40B2*/    EventUsrMasterDeviceTrimVolumeDown,
/*0x40B3*/    EventUsrSlaveDeviceTrimVolumeUp,
/*0x40B4*/    EventUsrSlaveDeviceTrimVolumeDown,


/* User events list cannot go past 0x40FF */   
              EventUsrLast,
            

            /* SYSTEM EVENTS */        
                  
/*0x4700*/    EventSysPairingFail = EVENTS_SYS_MESSAGE_BASE,
/*0x4701*/    EventSysPairingSuccessful,    
/*0x4702*/    EventSysSCOLinkOpen ,
/*0x4703*/    EventSysSCOLinkClose,

/*0x4704*/    EventSysBatteryLow,
/*0x4705*/    EventSysEndOfCall ,
/*0x4706*/    EventSysLEDEventComplete,
/*0x4707*/    EventSysAutoSwitchOff,

/*0x4708*/    EventSysChargeComplete,
/*0x4709*/    EventSysChargeInProgress,
/*0x470A*/    EventSysBatteryOk,
/*0x470B*/    EventSysBatteryCritical,

/*0x470C*/    EventSysChargeDisabled,
/*0x470D*/    EventSysGasGauge0,
/*0x470E*/    EventSysGasGauge1,
/*0x470F*/    EventSysGasGauge2,

/*0x4710*/    EventSysGasGauge3,
/*0x4711*/    EventSysChargerGasGauge0,		
/*0x4712*/    EventSysChargerGasGauge1,
/*0x4713*/    EventSysChargerGasGauge2,

/*0x4714*/    EventSysChargerGasGauge3,
/*0x4715*/    EventSysSLCConnected ,
/*0x4716*/    EventSysSLCDisconnected ,
/*0x4717*/    EventSysLinkLoss ,

/*0x4718*/    EventSysLimboTimeout ,
/*0x4719*/    EventSysNetworkOrServiceNotPresent,
/*0x471A*/    EventSysNetworkOrServicePresent,
/*0x471B*/    EventSysMuteReminder ,

/*0x471C*/    EventSysResetComplete,
/*0x471D*/    EventSysError,
/*0x471E*/    EventSysLongTimer,
/*0x471F*/    EventSysVLongTimer,

/*0x4720*/    EventSysEnablePowerOff,
/*0x4721*/	EventSysCancelLedIndication ,
/*0x4722*/    EventSysCallAnswered ,
/*0x4723*/    EventSysEnterPairingEmptyPDL,

/*0x4724*/	EventSysReconnectFailed,
/*0x4725*/    EventSysCheckForAudioTransfer,
/*0x4726*/	EventSysGaiaAlertLEDs,		
/*0x4727*/    EventSysServiceModeEntered ,

/*0x4728*/	EventSysAudioMessage1,
/*0x4729*/	EventSysAudioMessage2,		
/*0x472A*/	EventSysAudioMessage3,
/*0x472B*/	EventSysAudioMessage4,

/*0x472C*/    EventSysContinueSlcConnectRequest,
/*0x472D*/    EventSysSLCConnectedAfterPowerOn,
/*0x472E*/    EventSysEstablishSLCOnPanic,            
/*0x472F*/    EventSysConnectableTimeout, 
         
/*0x4730*/	EventSysTone1,
/*0x4731*/	EventSysTone2,
/*0x4732*/    EventSysStreamEstablish,
/*0x4733*/    EventSysResetLEDTimeout,

/*0x4734*/    EventSysStartPagingInConnState,      
/*0x4735*/    EventSysStopPagingInConnState,
/*0x4736*/    EventSysMultipointCallWaiting,
/*0x4737*/	EventSysRefreshEncryption,

/*0x4738*/	EventSysButtonBlockedByLock,
/*0x4739*/    EventSysSpeechRecognitionStart,
/*0x473A*/    EventSysSpeechRecognitionStop,
/*0x473B*/	EventSysSpeechRecognitionTuningYes,	

/*0x473C*/    EventSysSpeechRecognitionTuningNo,
/*0x473D*/    EventSysRssiPairReminder,
/*0x473E*/	EventSysRssiPairTimeout,
/*0x473F*/    EventSysRssiResume,

/*0x4740*/    EventSysCheckRole,
/*0x4741*/    EventSysMissedCall,
/*0x4742*/	EventSysA2dpConnected,
/*0x4743*/	EventSysA2dpDisconnected,

/*0x4744*/	EventSysVolumeMax,
/*0x4745*/	EventSysVolumeMin,
/*0x4746*/	EventSysCheckAudioRouting,
/*0x4747*/    EventSysConfirmationRequest,

/*0x4748*/    EventSysPasskeyDisplay,
/*0x4749*/    EventSysPinCodeRequest,           
/*0x474A*/    EventSysEstablishPbap,
/*0x474B*/    EventSysPbapDialFail,  
        
/*0x474C*/    EventSysMapcMsgNotification,
/*0x474D*/    EventSysMapcMnsSuccess,
/*0x474E*/    EventSysMapcMnsFailed,            
/*0x474F*/    EventSysPowerOnPanic,

/*0x4750*/    EventSysUsbDeadBatteryTimeout,
/*0x4751*/    EventSysRingtone1,
/*0x4752*/    EventSysRingtone2,
/*0x4753*/    EventSysPrimaryDeviceConnected,

/*0x4754*/    EventSysSecondaryDeviceConnected,                       
/*0x4755*/    EventSysUpdateAttributes,            
/*0x4756*/    EventSysResetAvrcpMode,
/*0x4757*/    EventSysCheckAudioAmpDrive,   
  
/*0x4758*/    EventSysCodecSbc,       
/*0x4759*/    EventSysCodecMp3,
/*0x475A*/    EventSysCodecAac,            
/*0x475B*/    EventSysCodecAptx,

/*0x475C*/    EventSysCodecAptxLL,        
/*0x475D*/    EventSysCodecFaststream,
/*0x475E*/    EventSysSubwooferCheckPairing,
/*0x475F*/    EventSysSubwooferOpenLLMedia,

/*0x4760*/    EventSysSubwooferOpenStdMedia,
/*0x4761*/    EventSysSubwooferCloseMedia,
/*0x4762*/    EventSysSubwooferStartStreaming,
/*0x4763*/    EventSysSubwooferSuspendStreaming,

/*0x4764*/    EventSysPartyModeTimeoutDevice1,
/*0x4765*/    EventSysPartyModeTimeoutDevice2,
/*0x4766*/    EventSysVolumeChangeTimer,
/*0x4767*/    EventSysStoreAudioPromptLanguage,

/*0x4768*/    EventSysIRCodeLearnSuccess,
/*0x4769*/    EventSysIRCodeLearnFail,
/*0x476a*/    EventSysIRLearningModeTimeout,
/*0x476b*/    EventSysIRLearningModeReminder,

/*0x476c*/    EventSysSetActiveAvrcpConnection,
/*0x476d*/    EventSysToneDigit0,
/*0x476e*/    EventSysToneDigit1,
/*0x476f*/    EventSysToneDigit2,
              
/*0x4770*/    EventSysToneDigit3,
/*0x4771*/    EventSysToneDigit4,
/*0x4772*/    EventSysToneDigit5,
/*0x4773*/    EventSysToneDigit6,
              
/*0x4774*/    EventSysToneDigit7,              
/*0x4775*/    EventSysToneDigit8,              
/*0x4776*/    EventSysToneDigit9,

/*0x4777*/    EventSysBleRemotePairingTimeout,
/*0x4778*/    EventSysBleRemotePairingSuccess,
/*0x4779*/    EventSysBleRemotePairingFailed,
/*0x477A*/    EventSysBleRemoteConnected,

/*0x477B*/    EventSysRemoteControlCodeReceived,

/*0x477C*/    EventSysPrimaryDeviceDisconnected,
/*0x477D*/    EventSysSecondaryDeviceDisconnected,
/*0x477E*/    EventSysSubwooferSetVolume,  
/*0x477F*/    EventSysTrimVolumeMax,
/*0x4780*/    EventSysTrimVolumeMin,

/*0x4781*/    EventSysBleRemoteAllDisconnected,
/*0x4782*/    EventSysGaiaEQChangesStoreTimeout,   
/*0x4783*/    EventSysCheckDefrag,   
/*0x4784*/    EventSysDefrag,              
/*0x4785*/    EventSysAmpPowerDown,
    EventSysLast
              
} sinkEvents_t; 

#define EVENTS_USR_LAST_EVENT EventUsrLast
#define EVENTS_SYS_LAST_EVENT EventSysLast
#define EVENTS_LAST_EVENT (EVENTS_SYS_LAST_EVENT)

#define EVENTS_MAX_EVENTS ( (EVENTS_LAST_EVENT - EVENTS_MESSAGE_BASE) + 1 )


/*************************************************************************
NAME    
    is_valid_event_id
    
DESCRIPTION
    Macro to determine if an Event ID is valid
    Note that EventInvalid is a valid Event ID used by state manager
   
*/ 
#define is_valid_event_id(id) \
    ((((id) >= EVENTS_USR_MESSAGE_BASE) && ((id) < EVENTS_USR_LAST_EVENT)) \
     || (((id) >= EVENTS_SYS_MESSAGE_BASE) && ((id) < EVENTS_SYS_LAST_EVENT)))

#endif
