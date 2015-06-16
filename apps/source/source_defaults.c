/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_defaults.c

DESCRIPTION
    Handles User PSKey default values.
    
*/


/* header for this file */
#include "source_defaults.h"
#include "source_audio.h"
/* application header files */
#include "source_debug.h"
#include "source_ps.h"
/* VM headers */
#include <bdaddr.h>
#include <panic.h>
/* profile/library headers */
#include <power.h>

#ifdef DEBUG_DEFAULTS
    #define DEFAULTS_DEBUG(x) DEBUG(x)
#else
    #define DEFAULTS_DEBUG(x)
#endif


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    defaults_get_value - Returns the default value for a User PSKey
*/
uint16 defaults_get_value(uint16 ps_key, void *ps_data, uint16 ps_size)
{
    switch (ps_key)
    {
        case PS_KEY_USER_COMPANY_ID:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_COMPANY_ID\n"));
            /* company ID not found - set to default */
            if (ps_size >= sizeof(uint32))
            {
                uint32 *ID = (uint32 *)ps_data;
                *ID = 0xFFFFFF;                
                return sizeof(uint32);
            }
        }
        break;
        
        case PS_KEY_USER_BLUETOOTH_PROFILES:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_BLUETOOTH_PROFILES\n"));
            /* profiles not found - set to defaults */
            if (ps_size >= sizeof(PS_BT_PROFILES_CONFIG_T))
            {
                PS_BT_PROFILES_CONFIG_T *profiles = (PS_BT_PROFILES_CONFIG_T *)ps_data;
                profiles->a2dp_profile = PS_A2DP_PROFILE_1_2;/*PS_A2DP_PROFILE_DISABLED;*/
                profiles->avrcp_profile = PS_AVRCP_PROFILE_1_0;/*PS_AVRCP_PROFILE_DISABLED;*/
                profiles->hfp_profile = PS_HFP_PROFILE_1_6;/*PS_HFP_PROFILE_DISABLED;*/
                return sizeof(PS_BT_PROFILES_CONFIG_T);
            }
            else
            {
                Panic();
            }  
        }
        break;
        
        case PS_KEY_USER_DUALSTREAM:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_DUALSTREAM\n"));
            /* profiles not found - set to defaults */
            if (ps_size >= sizeof(PS_DUALSTREAM_CONFIG_T))
            {
                PS_DUALSTREAM_CONFIG_T *dualstream = (PS_DUALSTREAM_CONFIG_T *)ps_data;
                dualstream->dual_stream_enable = 1;
                dualstream->dual_stream_connect_both_devices = 1;               
                return sizeof(PS_DUALSTREAM_CONFIG_T);
            }
            else
            {
                Panic();
            }  
        }
        break;
        
        case PS_KEY_USER_FEATURES:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_FEATURES\n"));
            /* features not found - set to defaults */
            if (ps_size >= sizeof(PS_FEATURES_T))
            {
                PS_FEATURES_T *features = (PS_FEATURES_T *)ps_data;  
                features->input_source = A2dpEncoderInputDeviceUsb;
                features->connect_policy = /*PS_CONNECT_PAIRED_LIST;*/PS_CONNECT_LAST_DEVICE;
                features->avrcp_vendor_enable = 1;
                features->sbc_force_max_bitpool = 1;
                features->aghfp_max_connection_retries = 2;
                features->a2dp_max_connection_retries = 2;
                features->avrcp_max_connection_retries = 3;
                features->connection_max_retries = 0xffff;
                return sizeof(PS_FEATURES_T);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_USER_SBC_CONFIG:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_SBC_CONFIG\n"));
            /* this has no default value */            
        }
        break;
        
        case PS_KEY_USER_FASTSTREAM_CONFIG:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_FASTSTREAM_CONFIG\n"));
            /* this has no default value */            
        }
        break;
        
        case PS_KEY_USER_A2DP_CODECS:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_A2DP_CODECS\n"));
            /* codecs not found - set to defaults */
            if (ps_size >= sizeof(PS_A2DP_CODECS_T))
            {
                PS_A2DP_CODECS_T *codecs = (PS_A2DP_CODECS_T *)ps_data;
                codecs->faststream = 1; /* enable faststream */
                codecs->faststream_preference = 1; /* try first */
                codecs->sbc = 1; /* enable sbc */
                codecs->sbc_preference = 2; /* try second */
                codecs->aptx = 0; /* disable apt-x */
                codecs->aptx_preference = 3; /* try third */
                codecs->aptxLowLatency = 0; /* disable apt-x Low Latency */
                codecs->aptxLowLatency_preference = 4; /* try fourth */
                return sizeof(PS_A2DP_CODECS_T);
            }
            else
            {
                Panic();
            }         
        }
        break;        
        
        case PS_KEY_USER_BDADDR_REMOTE_DEVICE:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_BDADDR_REMOTE_DEVICE\n"));
            /* address not found - set to zeroed address */
            if (ps_size >= sizeof(bdaddr))
            {
                BdaddrSetZero((bdaddr *)ps_data);
                return sizeof(bdaddr);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_USER_TIMERS:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_TIMERS\n"));
            /* timers not found - set to defaults */
            if (ps_size >= sizeof(PS_TIMERS_T))
            {
                PS_TIMERS_T *timer = (PS_TIMERS_T *)ps_data;
                timer->inquiry_state_timer = 30;
                timer->inquiry_idle_timer = 10; 
                timer->connection_idle_timer = 15;
                timer->disconnect_idle_timer = 30;
                timer->aghfp_connection_failed_timer = 2000;
                timer->a2dp_connection_failed_timer = 2000;
                timer->avrcp_connection_failed_timer = 2000;
                timer->avrcp_connection_delay_timer = 3000;
                timer->profile_connection_delay_timer = 1000;
                timer->link_loss_reconnect_delay_timer = 0xffff;
                timer->media_repeat_timer = 2100;
                timer->audio_delay_timer = 2000;
                timer->usb_audio_active_timer = 0xffff;
                timer->power_on_connect_idle_timer = 0;
                timer->power_on_discover_idle_timer = 0;
                return sizeof(PS_TIMERS_T);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_USER_USB_CONFIG:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_USB_CONFIG\n"));
            /* codecs not found - set to defaults */
            if (ps_size >= sizeof(PS_USB_CONFIG_T))
            {
                PS_USB_CONFIG_T *usb = (PS_USB_CONFIG_T *)ps_data;
                usb->usb_hid_keyboard_interface = 1;
                usb->usb_hid_consumer_interface = 1;
                usb->usb_mic_interface = 1;
                usb->usb_speaker_interface = 1;               
                return sizeof(PS_USB_CONFIG_T);
            }
            else
            {
                Panic();
            }  
        }
        break;
 
        case PS_KEY_USER_APTX_CONFIG:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_APTX_CONFIG\n"));
            /* this has no default value */            
        }
        break;
        
        case PS_KEY_USER_APTX_LOW_LATENCY_CONFIG:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_APTX_LOW_LATENCY_CONFIG\n"));
            /* this has no default value */            
        }
        break;

        case PS_KEY_USER_SNIFF:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_SNIFF\n"));
            /* this has no default value */ 
        }
        break;
        
        case PS_KEY_USER_HFP_AUDIO:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_HFP_AUDIO\n"));
            /* parameters not found - set to defaults */
            if (ps_size >= sizeof(PS_HFP_AUDIO_T))
            {
                PS_HFP_AUDIO_T *audio = (PS_HFP_AUDIO_T *)ps_data;
                /* Including each EDR eSCO bit disables the options. This bitmap therefore enables EV3 and 2EV3 */
                audio->sync_pkt_types = sync_all_sco | sync_ev3 | sync_3ev5 | sync_2ev5 | sync_3ev3; 
                audio->audio_params.bandwidth = 8000;
                audio->audio_params.max_latency = 13;
                audio->audio_params.voice_settings = sync_air_coding_transparent;
                audio->audio_params.retx_effort = sync_retx_link_quality;
                audio->audio_params.override_wbs = 0;                
                return sizeof(PS_HFP_AUDIO_T);
            }
            else
            {
                Panic();
            }  
        }
        break;
 
        case PS_KEY_USER_BDADDR_STREAM2_DEVICE:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_BDADDR_STREAM2_DEVICE\n"));
            /* address not found - set to zeroed address */
            if (ps_size >= sizeof(bdaddr))
            {
                BdaddrSetZero((bdaddr *)ps_data);
                return sizeof(bdaddr);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_PAIRED_DEVICE_LIST_SIZE:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_PAIRED_DEVICE_LIST_SIZE\n"));
            /* paired list size not found - set to default */
            if (ps_size >= sizeof(uint16))
            {
                uint16 *size = (uint16 *)ps_data;
                *size = 8;    
                return sizeof(uint16);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_USER_PIN_CODES:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_PIN_CODES\n"));
            /* PIN code list size not found - set to default */
            if (ps_size >= sizeof(PS_PIN_CONFIG_T))
            {
                PS_PIN_CONFIG_T *pin = (PS_PIN_CONFIG_T *)ps_data;
                pin->number_pin_codes = 4;
                pin->pin_codes[0].code[0] = '0';
                pin->pin_codes[0].code[1] = '0';
                pin->pin_codes[0].code[2] = '0';
                pin->pin_codes[0].code[3] = '0';
                pin->pin_codes[1].code[0] = '1';
                pin->pin_codes[1].code[1] = '1';
                pin->pin_codes[1].code[2] = '1';
                pin->pin_codes[1].code[3] = '1';
                pin->pin_codes[2].code[0] = '1';
                pin->pin_codes[2].code[1] = '2';
                pin->pin_codes[2].code[2] = '3';
                pin->pin_codes[2].code[3] = '4';
                pin->pin_codes[3].code[0] = '8';
                pin->pin_codes[3].code[1] = '8';
                pin->pin_codes[3].code[2] = '8';
                pin->pin_codes[3].code[3] = '8';
                return sizeof(PS_PIN_CONFIG_T);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_USER_POWER_READINGS:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_POWER_READINGS\n"));
            /* PIN code list size not found - set to default */
            if (ps_size >= sizeof(PS_POWER_CONFIG_T))
            {
                PS_POWER_CONFIG_T *config = (PS_POWER_CONFIG_T *)ps_data;
                /* vref */
                config->power.vref.adc.source = adcsel_vref;
                config->power.vref.adc.period_chg = 20;
                config->power.vref.adc.period_no_chg = 20;
                /* vbat */
                config->power.vbat.adc.source = adcsel_vdd_bat;
                config->power.vbat.adc.period_chg = 20;
                config->power.vbat.adc.period_no_chg = 20;
                config->power.vbat.limits[0].notify_period = 0x01; /* Critical Battery */
                config->power.vbat.limits[0].limit = 0x87; /* Critical Battery */
                config->power.vbat.limits[1].notify_period = 0x05; /* Low Battery */
                config->power.vbat.limits[1].limit = 0x91; /* Low Battery */
                config->power.vbat.limits[2].notify_period = 0x00; /* end - Normal Battery for any other reading */                
                config->power.vbat.limits[2].limit = 0xFF; /* end - Normal Battery for any other reading */ 
                /* vthm */
                config->power.vthm.adc.source = adcsel_aio0;
                config->power.vthm.adc.period_chg = 20;
                config->power.vthm.adc.period_no_chg = 20;
                config->power.vthm.delay = 0;
                config->power.vthm.raw_limits = 1;
                config->power.vthm.drive_pio = 1; 
                config->power.vthm.pio = 3;
                config->power.vthm.limits[0] = 0x013D;
                config->power.vthm.limits[1] = 0x02D9;
                config->power.vthm.limits[2] = 0xFFFF; /* end */
                /* vchg */
                config->power.vchg.adc.source = adcsel_byp_vregin;
                config->power.vchg.adc.period_chg = 20;
                config->power.vchg.adc.period_no_chg = 20;
                config->power.vchg.limit = 0x109A; /* 4.25v */
                
                return sizeof(PS_POWER_CONFIG_T);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        case PS_KEY_USER_PIO:
        {
            DEFAULTS_DEBUG(("Defaults: PS_KEY_USER_PIO\n"));
            /* PIO config not found - set to default */
            if (ps_size >= sizeof(PS_PIO_CONFIG_T))
            {
                PS_PIO_CONFIG_T *config = (PS_PIO_CONFIG_T *)ps_data;
                config->spdif_input = 0xFE;      /* default is disabled */
                return sizeof(PS_PIO_CONFIG_T);
            }
            else
            {
                Panic();
            }
        }
        break;
        
        default:
        {
            DEFAULTS_DEBUG(("Defaults: Unknown Key [%d]\n", ps_key));
            Panic();
        }
        break;
    }
    
    return 0;
}
