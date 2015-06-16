/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_dut.c

DESCRIPTION
    Place the sink device into Device Under Test (DUT) mode

NOTES


*/


/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_dut.h"
#include "sink_devicemanager.h"
#include "sink_device_id.h"
#include "sink_config.h"
#include "sink_pio.h"
#include "sink_tones.h"

#include <kalimba.h>
#include <file.h>
#include <led.h>
#include <test.h>


#include <ps.h>
#include <string.h>
#include "sink_configmanager.h"

#include <csr_dut_audio_plugin.h>


#ifdef DEBUG_DUT
#define DUT_DEBUG(x) DEBUG(x)
#else
#define DUT_DEBUG(x) 
#endif


#ifdef CVC_PRODTEST
    #define CVC_PRODTEST_PASS           0x0001
    #define CVC_PRODTEST_FAIL           0x0002
    #define CVC_PRODTEST_NO_CHECK       0x0003
    #define CVC_PRODTEST_FILE_NOT_FOUND 0x0004

    typedef struct
    {
        uint16 id;
        uint16 a;
        uint16 b;
        uint16 c;
        uint16 d;
    } DSP_REGISTER_T;

#endif


#define TX_START_TEST_MODE_LO_FREQ  (2441)
#define TX_START_TEST_MODE_LEVEL    (63)
#define TX_START_TEST_MODE_MOD_FREQ (0)
    
    
/* Sine Tone: 1000Hz */
static const ringtone_note sine_tone[] =
{
    RINGTONE_TEMPO(10), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
	RINGTONE_NOTE(B6  , SEMIBREVE),
    
    RINGTONE_END
};    


typedef enum
{
    dut_test_invalid,    
    dut_test_audio,
    dut_test_keys,
    dut_test_service,
    dut_test_tx,
    dut_test_dut
} dut_test_mode;

typedef enum
{
    key_test_led0_on,
    key_test_led0_off,
    key_test_led1_on,
    key_test_led1_off
} key_test_led_state;

typedef enum
{
    test_cvc,
    test_aptx,
    test_aptx_sprint,
    test_gaia
} security_test_type;

typedef struct
{
    unsigned led:2;
    unsigned mode:2;
    unsigned unused:12;
} DUT_T;


static DUT_T dut;
#ifdef CVC_PRODTEST
static security_test_type test_type;
#endif

/****************************************************************************
DESCRIPTION
    Gets the currently active DUT mode
*/
static dut_test_mode getDUTMode(void)
{
    return dut.mode;
}


/****************************************************************************
DESCRIPTION
    Sets the currently active DUT mode
*/
static void setDUTMode(dut_test_mode mode)
{
    if (dut.mode == dut_test_audio)
    {
        /* remove any test audio from previous mode */
        AudioStopTone();
        AudioDisconnect();
    }
    dut.mode = mode;   
}


/****************************************************************************
DESCRIPTION
    Gets the currently active test LED
*/
static key_test_led_state getDUTLed(void)
{
    return dut.led;
}


/****************************************************************************
DESCRIPTION
    Sets the currently active test LED
*/
static void setDUTLed(key_test_led_state led)
{
    dut.led = led;   
}
        
        
/****************************************************************************
DESCRIPTION
    Makes sure the device is powered on, eg. correct PIOs are enabled for DUT mode.
*/
static void enterDUTPowerOn(void)
{
    PioSetPowerPin(TRUE);
    
    PioSetPio(theSink.conf1->PIOIO.pio_outputs.PowerOnPIO, pio_drive, TRUE);
}


/****************************************************************************
DESCRIPTION
    Display current LED and then store next LED in the sequence
*/
static void switchDUTLed(void)
{   
    switch (getDUTLed())
   {
        case key_test_led0_off:
        {
            LedConfigure(LED_0, LED_ENABLE, FALSE);
            LedConfigure(LED_1, LED_ENABLE, FALSE);
            setDUTLed(key_test_led1_on);
        }
        break;

        case key_test_led1_on:
        {
            LedConfigure(LED_1, LED_ENABLE, TRUE);
            LedConfigure(LED_0, LED_ENABLE, FALSE);
            setDUTLed(key_test_led1_off);
        }
        break;
        
        case key_test_led1_off:
        {
            LedConfigure(LED_1, LED_ENABLE, FALSE);
            LedConfigure(LED_0, LED_ENABLE, FALSE);
            setDUTLed(key_test_led0_on);
        }
        break;
        
        case key_test_led0_on:
        default:
        {
            LedConfigure(LED_0, LED_ENABLE, TRUE);
            LedConfigure(LED_1, LED_ENABLE, FALSE);
            setDUTLed(key_test_led0_off);
        }
        break;
    }
}


/****************************************************************************
DESCRIPTION
    This function is called to place the sink device  into DUT mode
*/
void enterDutMode(void)
{
    /* set test mode */
    setDUTMode(dut_test_dut);
    
    ConnectionEnterDutMode();
}

/****************************************************************************
DESCRIPTION
    Entera continuous transmit test mode
*/
void enterTxContinuousTestMode ( void )
{
    /* set test mode */
    setDUTMode(dut_test_tx);
    
    TestTxStart (TX_START_TEST_MODE_LO_FREQ,
                 TX_START_TEST_MODE_LEVEL,
                 TX_START_TEST_MODE_MOD_FREQ) ;
}

/****************************************************************************
DESCRIPTION
    This function is called to determine if the device should enter DUT mode.
*/
bool checkForDUTModeEntry( void )
{
    if(PioGetPio(theSink.conf1->PIOIO.pio_inputs.dut_pio))
    {
        enterDutMode();
        return TRUE;
    }
    return FALSE;
}



/****************************************************************************
DESCRIPTION
    Enter service mode - device changers local name and enters discoverable
    mode
*/
void enterServiceMode( void )
{
    /* set test mode */
    setDUTMode(dut_test_service);
    
    /* Reset pair devices list */
    deviceManagerRemoveAllDevices();

        /* Entered service mode */
    MessageSend(&theSink.task, EventSysServiceModeEntered, 0);

        /* Power on immediately */
    MessageSend(&theSink.task, EventUsrPowerOn, 0);
        /* Ensure pairing never times out */
    theSink.conf1->timeouts.PairModeTimeout_s = 0;
    theSink.conf1->timeouts.PairModeTimeoutIfPDL_s = 0;

    MessageSend(&theSink.task, EventUsrEnterPairing, 0);

    ConnectionReadLocalAddr(&theSink.task);
}

/****************************************************************************
DESCRIPTION
    convert decimal to ascii
*/
static char hex(int hex_dig)
{
    if (hex_dig < 10)
        return '0' + hex_dig;
    else
        return 'A' + hex_dig - 10;
}

/****************************************************************************
DESCRIPTION
    handle a local bdaddr request and continue to enter service mode
*/
void DutHandleLocalAddr(CL_DM_LOCAL_BD_ADDR_CFM_T *cfm)
{
    char new_name[32];

    uint16 sw_version[SINK_DEVICE_ID_SW_VERSION_SIZE];
    uint16 i = 0;

    new_name[i++] = hex((cfm->bd_addr.nap & 0xF000) >> 12);
    new_name[i++] = hex((cfm->bd_addr.nap & 0x0F00) >> 8);
    new_name[i++] = hex((cfm->bd_addr.nap & 0x00F0) >> 4);
    new_name[i++] = hex((cfm->bd_addr.nap & 0x000F) >> 0);

    new_name[i++] = hex((cfm->bd_addr.uap & 0x00F0) >> 4);
    new_name[i++] = hex((cfm->bd_addr.uap & 0x000F) >> 0);

    new_name[i++] = hex((cfm->bd_addr.lap & 0xF00000) >> 20);
    new_name[i++] = hex((cfm->bd_addr.lap & 0x0F0000) >> 16);
    new_name[i++] = hex((cfm->bd_addr.lap & 0x00F000) >> 12);
    new_name[i++] = hex((cfm->bd_addr.lap & 0x000F00) >> 8);
    new_name[i++] = hex((cfm->bd_addr.lap & 0x0000F0) >> 4);
    new_name[i++] = hex((cfm->bd_addr.lap & 0x00000F) >> 0);

    new_name[i++] = ' ' ;

    GetDeviceIdFullVersion( sw_version );

    new_name[i++] = hex((sw_version[0] & 0xF000) >> 12) ;
    new_name[i++] = hex((sw_version[0] & 0x0F00) >> 8 ) ;
    new_name[i++] = hex((sw_version[0] & 0x00F0) >> 4 ) ;
    new_name[i++] = hex((sw_version[0] & 0x000F) >> 0 ) ;
    
    new_name[i++] = hex((sw_version[1] & 0xF000) >> 12) ;
    new_name[i++] = hex((sw_version[1] & 0x0F00) >> 8 ) ;
    new_name[i++] = ' ' ;
    new_name[i++] = hex((sw_version[1] & 0x00F0) >> 4 ) ;
    new_name[i++] = hex((sw_version[1] & 0x000F) >> 0 ) ;

    new_name[i++] = hex((sw_version[2] & 0xF000) >> 12) ;
    new_name[i++] = hex((sw_version[2] & 0x0F00) >> 8 ) ;
    new_name[i++] = hex((sw_version[2] & 0x00F0) >> 4 ) ;
    new_name[i++] = hex((sw_version[2] & 0x000F) >> 0 ) ;

    /* Some customers do not use the final word in their version number
       so omit it if not present */
    if(sw_version[3] != 0)
    {
        new_name[i++] = ' ' ;

        new_name[i++] = hex((sw_version[3] & 0xF000) >> 12) ;
        new_name[i++] = hex((sw_version[3] & 0x0F00) >> 8 ) ;
        new_name[i++] = hex((sw_version[3] & 0x00F0) >> 4 ) ;
        new_name[i++] = hex((sw_version[3] & 0x000F) >> 0 ) ;
    }

        /*terminate the string*/
    new_name[i] = 0;

    ConnectionChangeLocalName(i, (uint8 *)new_name);
}


#ifdef CVC_PRODTEST
/*************************************************************************
DESCRIPTION
    Perform the CVC production test routing and nothing else in the given
    boot mode
*/
void cvcProductionTestEnter ( void )
{
    /* check to see if license key checking is enabled */
    uint16 * buffer = mallocPanic( sizeof(uint16) * sizeof(feature_config_type));
    char* kap_file = NULL;
    uint16 audio_plugin;
    uint16 a2dp_optional_codecs_enabled;

    ConfigRetrieve(CONFIG_FEATURE_BLOCK, buffer, sizeof(feature_config_type)) ; 	
             
    audio_plugin = (buffer[3] >> 8) & 0x7;
    DUT_DEBUG(("CVCPT:buffer[3] = [%x]\n", buffer[3]));
    DUT_DEBUG(("CVCPT:audio_plugin = [%x]\n", audio_plugin));
    
    a2dp_optional_codecs_enabled = (buffer[5] >> 5) &  0xf;
    DUT_DEBUG(("CVCPT:buffer[5] = [%x]\n", buffer[5]));
    DUT_DEBUG(("CVCPT:a2dp_optional_codecs_enabled = [%x]\n", a2dp_optional_codecs_enabled));
    
    switch (audio_plugin)
    {
        case 2:
            /* 1 mic cvc */
            /* security check is the same in 1 mic */
            /* and 1 mic wideband */
            kap_file = "cvc_headset/cvc_headset.kap";
            test_type = test_cvc;
            break;
        case 3:
            /* 2 mic cvc */
            /* security check is the same in 2 mic */
            /* and 2 mic wideband */
            kap_file = "cvc_headset_2mic/cvc_headset_2mic.kap";
            test_type = test_cvc;
            break;
        default:
            /* no dsp */
            /* pass thru */
            /* default */
            
            /* check to see if Apt-X codec is enabled */
            
#ifdef USE_MULTI_DECODER
            /* ROM device may have Apt-X enabled, select multi-decoder kap file*/
            if (a2dp_optional_codecs_enabled & 0x8)
            {
                kap_file = "multi_decoder/multi_decoder.kap";
                test_type = test_aptx;
                break;
            }
#else            
#ifdef INCLUDE_APTX            
            /* may need to add extra code for Apt-X sprint decoder */
            if (a2dp_optional_codecs_enabled & 0x8)
            {
                kap_file = "aptx_decoder/aptx_decoder.kap";
                test_type = test_aptx;
                break;
            }
        
#endif
#endif /*USE_MULTI_DECODER */     
            
#ifdef ENABLE_GAIA                
            /* Initialise Gaia with a concurrent connection limit of 1 */
            GAIA_DEBUG(("GaiaInit\n"));
            GaiaInit(&theSink.task, 1);
            test_type = test_gaia;
            break;
#else
            DUT_DEBUG(("CVC_PRODTEST_NO_CHECK\n"));
            freePanic(buffer);
            exit(CVC_PRODTEST_NO_CHECK);
            break;
#endif /*ENABLE_GAIA */
    }
        
    /* don't attempt to load kalimba file if we are testing Gaia */
    if (test_type != test_gaia)
    {
        MessageKalimbaTask(&theSink.task);
            
        if (FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file)) == FILE_NONE)
        {
            DUT_DEBUG(("CVCPT: CVC_PRODTEST_FILE_NOT_FOUND\n"));
            freePanic(buffer);
            exit(CVC_PRODTEST_FILE_NOT_FOUND);
        }
        else
        {
            DUT_DEBUG(("CVCPT: KalimbaLoad [%s]\n", kap_file));
            KalimbaLoad(FileFind(FILE_ROOT,(const char *) kap_file ,strlen(kap_file)));
        }
            
        DUT_DEBUG(("CVCPT:StreamConnect\n"));
        StreamConnect(StreamKalimbaSource(0), StreamHostSink(0));
    }           
    freePanic(buffer);
               
}

/*************************************************************************
DESCRIPTION
    Handle the response from Kalimba to figure out if the CVC licence key exists    
*/
void cvcProductionTestKalimbaMessage ( Task task, MessageId id, Message message )
{
    const DSP_REGISTER_T *m = (const DSP_REGISTER_T *) message;
	DUT_DEBUG(("CVCPT: CVC: msg id[%x] a[%x] b[%x] c[%x] d[%x]\n", m->id, m->a, m->b, m->c, m->d));
    DUT_DEBUG(("CVCPT: test type = %x\n", test_type));

    switch (test_type)
    {
        case test_cvc:
        {
            switch (m->id)
            {
                case 0x1000:
                    DUT_DEBUG(("CVCPT: CVC_READY\n"));
                    /*CVC_LOADPARAMS_MSG, CVC_PS_BASE*/
                    KalimbaSendMessage(0x1012, 0x2280, 0, 0, 0);
                    break;
            
                case 0x1006:
                    DUT_DEBUG(("CVCPT: CVC_CODEC_MSG\n"));
                    /*MESSAGE_SCO_CONFIG, sco_encoder, sco_config*/
                    KalimbaSendMessage(0x2000, 0, 3, 0, 0);
                    break;
        
                case 0x100c:
                    DUT_DEBUG (("CVCPT: CVC_SECPASSED_MSG\n"));
                    exit(CVC_PRODTEST_PASS);
                    break;
            
                case 0x1013:
                    DUT_DEBUG (("CVCPT: CVC_SECFAILD_MSG\n"));
                    exit(CVC_PRODTEST_FAIL);
                    break;
            
                default:
                    DUT_DEBUG(("CVCPT: m->id [%x]\n", m->id));
                    break;    
             }
            break;
        }
        
        case test_aptx:
        {
            switch (m->id)
            {
                case 0x1000:
                    DUT_DEBUG(("CVCPT: MUSIC_READY_MSG\n"));
                    /*MUSIC_LOADPARAMS_MSG, MUSIC_PS_BASE*/
                    KalimbaSendMessage(0x1012, 0x8822, 0, 0, 0);
                    break;
            
                case 0x1015:
                    DUT_DEBUG(("CVCPT: MUSIC_PARAMS_LOADED_MSG\n"));
                    /*APTX_PARAMS_MSG, rate, channel_mode*/
                    KalimbaSendMessage(0x1016, 0xac44, 0x2, 0, 0);
                    
                    /*MUSIC_SET_PLUGIN_MSG, variant*/
                    KalimbaSendMessage(0x1020, 0x6, 0, 0, 0);
                    
                    /*MESSAGE_SET_DAC_SAMPLE_RATE, rate, mismatch, clock_mismatch*/
                    KalimbaSendMessage(0x1070,0x113A, 0, 0, 0);
                    
                    /*MESSAGE_SET_CODEC_SAMPLE_RATE, rate, mismatch, clock_mismatch*/
                    KalimbaSendMessage(0x1071,0x113A, 0, 0, 0);
                    
                    /*KALIMBA_MSG_GO*/
                    KalimbaSendMessage(0x7000, 0, 0, 0, 0);
                    break;
        
                case 0x100c:
                    DUT_DEBUG (("CVCPT: APTX_SECPASSED_MSG\n"));
                    exit(CVC_PRODTEST_PASS);
                    break;
            
                case 0x1013:
                    DUT_DEBUG (("CVCPT: APTX_SECFAILED_MSG\n"));
                    exit(CVC_PRODTEST_FAIL);
                    break;
            
                default:
                    DUT_DEBUG(("CVCPT: m->id [%x]\n", m->id));
                    break;    
             }
            break;
        }
        
        default:
        {
            DUT_DEBUG (("CVCPT: cvcProductionTestKalimbaMessage unknown test_type\n"));
            break;
        }
    }
            
}

#endif


/*************************************************************************
DESCRIPTION
    Audio Test Mode    
*/
void enterAudioTestMode(void)
{
    /* set test mode */
    setDUTMode(dut_test_audio);
    /* power on */
    enterDUTPowerOn();
    /* remove current audio */
    AudioDisconnect();
    /* use DUT audio plugin to route audio from mic to speaker */
    AudioConnect((TaskData *)&csr_dut_audio_plugin, 
                 0, 
                 AUDIO_SINK_INVALID, 
                 theSink.codec_task, 
                 theSink.features.DefaultVolume, 
                 8000, 
                 theSink.conf2->audio_routing_data.PluginFeatures, 
                 AUDIO_MODE_CONNECTED, 
                 0, 
                 powerManagerGetLBIPM(), 
                 &theSink.conf1->PIOIO.digital, 
                 &theSink.task);
}


/*************************************************************************
DESCRIPTION
    Tone Test Mode
*/
void enterToneTestMode(void)
{
    /* set test mode */
    setDUTMode(dut_test_audio);
    /* power on */
    enterDUTPowerOn();
    /* remove current audio */
    AudioDisconnect();
    /* use DUT audio plugin to route audio from mic to speaker */
    AudioConnect((TaskData *)&csr_dut_audio_plugin, 
                 0, 
                 AUDIO_SINK_INVALID, 
                 theSink.codec_task, 
                 theSink.features.DefaultVolume,                 
                 8000, 
                 theSink.conf2->audio_routing_data.PluginFeatures, 
                 AUDIO_MODE_MUTE_BOTH, 
                 0, 
                 powerManagerGetLBIPM(), 
                 NULL, 
                 &theSink.task);
    AudioPlayTone(sine_tone, theSink.features.QueueEventTones, theSink.codec_task, TonesGetToneVolume(FALSE), theSink.conf2->audio_routing_data.PluginFeatures); 
}


/*************************************************************************
DESCRIPTION
    Key Test Mode
*/
void enterKeyTestMode(void)
{
    /* set test mode */
    setDUTMode(dut_test_keys);
    /* power on */
    enterDUTPowerOn();
    /* init LEDs */
    LedConfigure(LED_0, LED_ENABLE, FALSE);
    LedConfigure(LED_1, LED_ENABLE, FALSE);
}


/*************************************************************************
DESCRIPTION
    A configured key has been pressed, check if this is in key test mode
*/
void checkDUTKeyPress(uint32 lNewState)
{
    if (getDUTMode() == dut_test_keys)
    {
        switchDUTLed();        
    }
}

/*************************************************************************
DESCRIPTION
    A configured key has been released, check if this is in key test mode
*/
void checkDUTKeyRelease(uint32 lNewState, ButtonsTime_t pTime)
{
    if (getDUTMode() == dut_test_keys)
    {
        switch (pTime)
        {
            case B_SHORT:         
            case B_DOUBLE:
            case B_LOW_TO_HIGH:
            case B_HIGH_TO_LOW:             
            case B_LONG_RELEASE:
            case B_VERY_LONG_RELEASE:    
            case B_VERY_VERY_LONG_RELEASE:
            {
                switchDUTLed();                
            }
            break;
            
            default:
            {
                /* Button time not handled */
            }
            break;        
        }
    }
}


/*************************************************************************
DESCRIPTION
    Initialise DUT mode
*/
void dutInit(void)
{
    /* set test mode */
    setDUTMode(dut_test_invalid);
    /* set initial LED */
    setDUTLed(key_test_led0_on);
}


/*************************************************************************
DESCRIPTION
    Return if DUT audio mode is running
*/
bool isDutAudioActive(void)
{
    if (getDUTMode() == dut_test_audio)
    {
        return TRUE;
    }
    return FALSE;
}
