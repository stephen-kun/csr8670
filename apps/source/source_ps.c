/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_ps.c

DESCRIPTION
    Handles the PS Keys used by the application. Includes reading from and writing to PS.
    
*/


/* header for this file */
#include "source_ps.h"
/* application header files */
#include "source_connection_mgr.h"
#include "source_debug.h"
#include "source_defaults.h"
#include "source_memory.h"
#include "source_private.h"
#include "source_led_error.h"
/* VM headers */
#include <panic.h>
#include <ps.h>
#include <string.h>


#ifdef DEBUG_PS
    #define PS_DEBUG(x) DEBUG(x)
#else
    #define PS_DEBUG(x)
#endif


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    ps_read_user - Read a User PSKey 
*/
uint16 ps_read_user(uint16 ps_key, void *ps_data, uint16 ps_size)
{
    uint16 ps_retrieve = 0;
    
#ifdef DEBUG_PS     
    {
        PS_DEBUG(("PS: READ USER; key[0x%x] size[0x%x]\n", ps_key, ps_size));      
    }
#endif    
    
    /* attempt to read from User PSKey */
    ps_retrieve = PsRetrieve(ps_key, ps_data, ps_size);
    
    if (!ps_retrieve)
    {
        if ( ps_key == PS_KEY_PAIRED_DEVICE_LIST_SIZE )
        {
            /*
            Preserve the Paired Device List size as a default that can be read
            from const space until the use of the Connection Library can be
            reworked to align the Source with the changes in the Sink.
            */
            ps_retrieve = defaults_get_value(ps_key, ps_data, ps_size);
        }
        else
        {
            PS_DEBUG(("PS: No PSKEY[%x]\n", ps_key));
        }
    }
    
    return ps_retrieve;
}


/****************************************************************************
NAME    
    ps_read_full - Read a device PSKey 
*/
uint16 ps_read_full(uint16 ps_key, void *ps_data, uint16 ps_size)
{
#ifdef DEBUG_PS     
    {
        PS_DEBUG(("PS: READ FULL; key[0x%x] size[0x%x]\n", ps_key, ps_size));      
    }
#endif    
    
    /* attempt to read from full PSKey list */
    return PsFullRetrieve(ps_key, ps_data, ps_size);
}


/****************************************************************************
NAME    
    ps_write - Write a PSKey 
*/
uint16 ps_write(uint16 ps_key, const void *ps_data, uint16 ps_size)
{
#ifdef DEBUG_PS     
    {
        uint16 i;
        const uint8 *ch = ps_data;
        ch = ch;
        PS_DEBUG(("PS: WRITE; key[0x%x] size[0x%x] data[", ps_key, ps_size));
        for (i = 0; i < ps_size; i++)
        {
           PS_DEBUG(("%x ", ch[i])); 
        }
        PS_DEBUG(("]\n"));
    }
#endif        
    return PsStore(ps_key, ps_data, ps_size);
}

/****************************************************************************
NAME 
    ps_set_version

DESCRIPTION
    Reads the PSKEY containing the version type and number and checks if it 
    needs to be set or reset, will not be written if already the correct value.
 
RETURNS
    void
*/ 
void ps_set_version(void)
{
    uint16 cfg_set_version[2];
    
    /* read software version number pskey */
    if ((PsRetrieve(PS_KEY_CONFIG_SET_VERSION_ID, &cfg_set_version, 2) != 2)||
        (cfg_set_version[0] != CONFIG_SET_PRODUCT_TYPE) ||
        (cfg_set_version[1] != CONFIG_SET_VERSION))
    {
        /* if not correct or missing then write constant values */
        cfg_set_version[0] = CONFIG_SET_PRODUCT_TYPE;
        cfg_set_version[1] = CONFIG_SET_VERSION;
        PsStore(PS_KEY_CONFIG_SET_VERSION_ID, cfg_set_version, 2);
    }
}

/****************************************************************************
NAME    
    ps_get_configuration - Reads the PSKeys used to configure the device
*/
void ps_get_configuration(void)
{    
    uint16 sbc_config;
    uint16 faststream_config;
    uint16 aptx_config;
    uint16 aptxLowLatency_config;
    POWER_TABLE_T *power_table = NULL; 

    /* Read Bluetooth address of remote device that the source should connect to */
    CfgErrFalse(ps_read_user(PS_KEY_USER_BDADDR_REMOTE_DEVICE, &theSource->ps_config->bdaddr_remote_device, sizeof(bdaddr)),PS_KEY_USER_BDADDR_REMOTE_DEVICE);
    PS_DEBUG(("PS: Remote address;")); 
    DEBUG_BDADDR(theSource->ps_config->bdaddr_remote_device);
    
#ifdef INCLUDE_DUALSTREAM    
    /* Read Bluetooth address of additional A2DP device to connect with for DualStream operation */
    CfgErrFalse(ps_read_user(PS_KEY_USER_BDADDR_STREAM2_DEVICE, &theSource->ps_config->bdaddr_stream2_device, sizeof(bdaddr)),PS_KEY_USER_BDADDR_STREAM2_DEVICE);
    PS_DEBUG(("PS: Second Stream address;")); 
    DEBUG_BDADDR(theSource->ps_config->bdaddr_stream2_device);
    
    /* Read DualStream Configuration */
    CfgErrFalse(ps_read_user(PS_KEY_USER_DUALSTREAM, &theSource->ps_config->dualstream, sizeof(PS_DUALSTREAM_CONFIG_T)),PS_KEY_USER_DUALSTREAM); 
    
    PS_DEBUG(("PS: DualStream: enabled[%d] conect_both_devices[%d]\n",
                theSource->ps_config->dualstream.dual_stream_enable, 
                theSource->ps_config->dualstream.dual_stream_connect_both_devices));
#endif    
    
    /* Read number of stored Paired Devices */
    CfgErrFalse(ps_read_user(PS_KEY_PAIRED_DEVICE_LIST_SIZE, &theSource->ps_config->number_paired_devices, sizeof(uint16)),PS_KEY_PAIRED_DEVICE_LIST_SIZE);
    
    /* Read configurable timers */
    CfgErrFalse(ps_read_user(PS_KEY_USER_TIMERS, &theSource->ps_config->ps_timers, sizeof(PS_TIMERS_T)),PS_KEY_USER_TIMERS);
    
    /* Read company ID */
    ps_read_user(PS_KEY_USER_COMPANY_ID, &theSource->ps_config->company_id, sizeof(uint32)); 
    PS_DEBUG(("PS: Company ID [0x%lx]\n", theSource->ps_config->company_id));
    
    /* Read features */
    CfgErrFalse(ps_read_user(PS_KEY_USER_FEATURES, &theSource->ps_config->features, sizeof(PS_FEATURES_T)),PS_KEY_USER_FEATURES);      
    
    /* Read SBC configuration */
    sbc_config = ps_read_user(PS_KEY_USER_SBC_CONFIG, &theSource->ps_config->sbc_config, sizeof(PS_SBC_CONFIG_T));
    /* Read Faststream configuration */
    faststream_config = ps_read_user(PS_KEY_USER_FASTSTREAM_CONFIG, &theSource->ps_config->faststream_config, sizeof(PS_FASTSTREAM_CONFIG_T));
    /* Read APT-X configuration */
    aptx_config = ps_read_user(PS_KEY_USER_APTX_CONFIG, &theSource->ps_config->aptx_config, sizeof(PS_APTX_CONFIG_T));
    /* Read APT-X Low Latency configuration */
    aptxLowLatency_config = ps_read_user(PS_KEY_USER_APTX_LOW_LATENCY_CONFIG, &theSource->ps_config->aptxLowLatency_config, sizeof(PS_APTX_LOW_LATENCY_CONFIG_T));
    
    /* set to default configs */
    a2dp_set_sbc_config(TRUE);
    a2dp_set_faststream_config(TRUE);
    a2dp_set_aptx_config(TRUE);
    a2dp_set_aptxLowLatency_config(TRUE);
    
    if (sbc_config || faststream_config || aptx_config || aptxLowLatency_config)
    {
        /* create memory to hold all codec configurations */
        if (!memory_create_block(MEMORY_CREATE_BLOCK_CODECS))
        {
            Panic(); /* Panic if can't allocate memory */
        }   
        if (sbc_config)
        {
            theSource->a2dp_data.sbc_codec_config = (uint8 *)memory_get_block(MEMORY_GET_BLOCK_CODEC_SBC);
            a2dp_set_sbc_config(FALSE);
        }
        if (faststream_config)
        {
            theSource->a2dp_data.faststream_codec_config = (uint8 *)memory_get_block(MEMORY_GET_BLOCK_CODEC_FASTSTREAM);
            a2dp_set_faststream_config(FALSE);
        }
        if (aptx_config)
        {
            theSource->a2dp_data.aptx_codec_config = (uint8 *)memory_get_block(MEMORY_GET_BLOCK_CODEC_APTX);
            a2dp_set_aptx_config(FALSE);
        }
        if (aptxLowLatency_config)
        {
            theSource->a2dp_data.aptxLowLatency_codec_config = (uint8 *)memory_get_block(MEMORY_GET_BLOCK_CODEC_APTX_LOW_LATENCY);
            a2dp_set_aptxLowLatency_config(FALSE);
        }
    }
    
    /* Read A2DP Enabled Codecs */
    CfgErrFalse(ps_read_user(PS_KEY_USER_A2DP_CODECS, &theSource->ps_config->a2dp_codecs, sizeof(PS_A2DP_CODECS_T)),PS_KEY_USER_A2DP_CODECS); 
    
    /* Read Sniff configuration */  
    power_table = (POWER_TABLE_T *)memory_create(((sizeof(lp_power_table) * POWER_TABLE_ENTRIES) + sizeof(uint16)));	    
    if (power_table && ps_read_user(PS_KEY_USER_SNIFF, power_table, ((sizeof(lp_power_table) * POWER_TABLE_ENTRIES) + sizeof(uint16))))
    {
        theSource->ps_config->sniff.number_a2dp_entries = power_table->a2dp_entries;
        theSource->ps_config->sniff.number_aghfp_entries = power_table->aghfp_entries;
        theSource->ps_config->sniff.a2dp_powertable = power_table->powertable;
        theSource->ps_config->sniff.aghfp_powertable = &power_table->powertable[power_table->a2dp_entries];
#ifdef DEBUG_PS   
        {
            uint16 i;
            PS_DEBUG(("PS: Sniff; A2DP entries[%d]:\n", theSource->ps_config->sniff.number_a2dp_entries));
            for (i = 0; i < theSource->ps_config->sniff.number_a2dp_entries; i++)
            {
                PS_DEBUG(("    state:%d min:%d max:%d attempt:%d timeout:%d time:%d\n", 
                                             theSource->ps_config->sniff.a2dp_powertable[i].state,
                                             theSource->ps_config->sniff.a2dp_powertable[i].min_interval,
                                             theSource->ps_config->sniff.a2dp_powertable[i].max_interval,
                                             theSource->ps_config->sniff.a2dp_powertable[i].attempt,
                                             theSource->ps_config->sniff.a2dp_powertable[i].timeout,
                                             theSource->ps_config->sniff.a2dp_powertable[i].time));
            }
            PS_DEBUG(("PS: Sniff; AGHFP entries[%d]:\n", theSource->ps_config->sniff.number_aghfp_entries));
            for (i = 0; i < theSource->ps_config->sniff.number_aghfp_entries; i++)
            {
                PS_DEBUG(("    state:%d min:%d max:%d attempt:%d timeout:%d time:%d\n", 
                                             theSource->ps_config->sniff.aghfp_powertable[i].state,
                                             theSource->ps_config->sniff.aghfp_powertable[i].min_interval,
                                             theSource->ps_config->sniff.aghfp_powertable[i].max_interval,
                                             theSource->ps_config->sniff.aghfp_powertable[i].attempt,
                                             theSource->ps_config->sniff.aghfp_powertable[i].timeout,
                                             theSource->ps_config->sniff.aghfp_powertable[i].time));
            }
        }
#endif        
    }
    else
    {
        memory_free(power_table);
        PS_DEBUG(("PS: No sniff\n"));
    }
    
    /* Read HFP Audio Parameters */
    CfgErrFalse(ps_read_user(PS_KEY_USER_HFP_AUDIO, &theSource->ps_config->hfp_audio, sizeof(PS_HFP_AUDIO_T)),PS_KEY_USER_HFP_AUDIO); 
    
    PS_DEBUG(("PS: HFP Audio Config: sync_packets[0x%x] bandwidth[0x%lx] latency[%d] voice[%d] retx[%d] override_wbs[%d]\n",
                theSource->ps_config->hfp_audio.sync_pkt_types, 
                theSource->ps_config->hfp_audio.audio_params.bandwidth,
                theSource->ps_config->hfp_audio.audio_params.max_latency,
                theSource->ps_config->hfp_audio.audio_params.voice_settings,
                theSource->ps_config->hfp_audio.audio_params.retx_effort,
                theSource->ps_config->hfp_audio.audio_params.override_wbs));
    
    /* Read Bluetooth Profiles Enabled */
    CfgErrFalse(ps_read_user(PS_KEY_USER_BLUETOOTH_PROFILES, &theSource->ps_config->bt_profiles, sizeof(PS_BT_PROFILES_CONFIG_T)),PS_KEY_USER_BLUETOOTH_PROFILES);
    
#ifdef MS_LYNC_ONLY_BUILD   
    /* override configuration to only include HFP support for a Lync only build */
    theSource->ps_config->bt_profiles.hfp_profile = PS_HFP_PROFILE_1_6;
    theSource->ps_config->bt_profiles.a2dp_profile = PS_A2DP_PROFILE_DISABLED;
    theSource->ps_config->bt_profiles.avrcp_profile = PS_AVRCP_PROFILE_DISABLED;
#endif    
    
    PS_DEBUG(("PS: Bluetooth Profiles: a2dp[%d] avrcp[%d] hfp[%d]\n",
                theSource->ps_config->bt_profiles.a2dp_profile, 
                theSource->ps_config->bt_profiles.avrcp_profile, 
                theSource->ps_config->bt_profiles.hfp_profile)); 
    
    /* Read PIN code config */
    theSource->connection_data.connection_pin = memory_create(sizeof(CONNECTION_PIN_CODE_STORE_T));
    CfgErrFalse(ps_read_user(PS_KEY_USER_PIN_CODES, &theSource->connection_data.connection_pin->pin, sizeof(PS_PIN_CONFIG_T)),PS_KEY_USER_PIN_CODES);
    /* reset stored PIN codes */
    connection_mgr_reset_pin_codes(); 
    
#ifdef INCLUDE_POWER_READINGS    
    /* Read Power Reading Config */
    CfgErrFalse(ps_read_user(PS_KEY_USER_POWER_READINGS, &theSource->ps_config->pwr_config, sizeof(PS_POWER_CONFIG_T)),PS_KEY_USER_POWER_READINGS); 
#endif
    
    /* read PIO configuration */
    CfgErrFalse(ps_read_user(PS_KEY_USER_PIO, &theSource->ps_config->pio_config, sizeof(PS_PIO_CONFIG_T)), PS_KEY_USER_PIO);
    
}


/****************************************************************************
NAME    
    ps_get_time_critical_data - Reads PSKeys before application starts up
*/
void ps_get_time_critical_data(void)
{
#ifndef ANALOGUE_INPUT_DEVICE    
    /* Read USB configuration if not Analogue Input device */
    CfgErrFalse(ps_read_user(PS_KEY_USER_USB_CONFIG, &theSource->ps_config->usb_config, sizeof(PS_USB_CONFIG_T)),PS_KEY_USER_USB_CONFIG);    
#endif    
}

/****************************************************************************
NAME    
    ps_restore_timers - Sets the timers to the PS defaults
*/
void ps_restore_timers(void)
{
    if (theSource->timer_data.timers_stopped)
    {
        /* note that timers have been restored */
        theSource->timer_data.timers_stopped = FALSE;
        /* Read configurable timers from PS again as the values may have been changed */
        CfgErrFalse(ps_read_user(PS_KEY_USER_TIMERS, &theSource->ps_config->ps_timers, sizeof(PS_TIMERS_T)),PS_KEY_USER_TIMERS);
    }
}


/****************************************************************************
NAME    
    ps_write_new_remote_device - Write the device to PS and store it as last used device
*/
void ps_write_new_remote_device(const bdaddr *addr, PROFILES_T profile)
{
    /* check if the remote device needs to be stored as the one to always connect with */   
    if (!BdaddrIsZero(addr))
    {
        bool bdaddr_zero_main_device = BdaddrIsZero(&theSource->ps_config->bdaddr_remote_device);
        bool bdaddr_zero_stream2_device = BdaddrIsZero(&theSource->ps_config->bdaddr_stream2_device);
        
        /* set to be the most recently used device */
        ConnectionSmUpdateMruDevice(addr);
        
        if (!bdaddr_zero_main_device)
        {
            if (BdaddrIsSame(&theSource->ps_config->bdaddr_remote_device, addr))
            {
                /* this device already exists in PS so don't need to store the remote device address */
                PS_DEBUG(("PS: Write new device - addr already exists as main device\n"));
                return;
            }
        }
        if (A2DP_DUALSTREAM_ENABLED && !bdaddr_zero_stream2_device)
        {
            if (BdaddrIsSame(&theSource->ps_config->bdaddr_stream2_device, addr))
            {
                /* this device already exists in PS so don't need to store the remote device address */
                PS_DEBUG(("PS: Write new device - addr already exists as 2nd device\n"));
                return;
            }
        }
        
        if ((profile == PROFILE_AGHFP) || !A2DP_DUALSTREAM_ENABLED)
        {
            /* write as main device */
            ps_write(PS_KEY_USER_BDADDR_REMOTE_DEVICE, addr, sizeof(bdaddr));
            theSource->ps_config->bdaddr_remote_device = *addr;
            PS_DEBUG(("PS: Write new device - written as main device\n"));
        }
        else
        {
            /* DualStream enabled - have to check which address to update */
            if (a2dp_get_number_connections() > 1)
            {
                /* write 2nd A2DP device to PS and store locally */
                ps_write(PS_KEY_USER_BDADDR_STREAM2_DEVICE, addr, sizeof(bdaddr));
                theSource->ps_config->bdaddr_stream2_device = *addr;    
                PS_DEBUG(("PS: Write new device - written as 2nd device\n"));
            }
            else
            {
                /* this is the first connection but have to choose which device this is */
                if (bdaddr_zero_main_device)
                {
                    /* no PS Key written for the main device, so store this as the main device */
                    theSource->connection_data.connected_device_ps_slot = 0;
                }
                else if (bdaddr_zero_stream2_device)
                {
                    /* no PS Key written for the 2nd stream device, so store this as the 2nd stream device */
                    theSource->connection_data.connected_device_ps_slot = 1;                    
                }
            
                if (theSource->connection_data.connected_device_ps_slot == 0)                    
                {
                    /* write as first device */
                    ps_write(PS_KEY_USER_BDADDR_REMOTE_DEVICE, addr, sizeof(bdaddr));
                    theSource->ps_config->bdaddr_remote_device = *addr;  
                    /* update to write as 2nd device next time */
                    theSource->connection_data.connected_device_ps_slot = 1;
                    PS_DEBUG(("PS: Write new device - slot 0 written as main device\n"));
                }
                else
                {
                    /* write as 2nd stream device */
                    ps_write(PS_KEY_USER_BDADDR_STREAM2_DEVICE, addr, sizeof(bdaddr));
                    theSource->ps_config->bdaddr_stream2_device = *addr;
                    /* update to write as 1st device next time */
                    theSource->connection_data.connected_device_ps_slot = 0;
                    PS_DEBUG(("PS: Write new device - slot 1 written as 2nd device\n"));
                }             
            }
        }
    }
}


/****************************************************************************
NAME    
    ps_write_device_name - Write the device name to PS     
*/
void ps_write_device_name(const bdaddr *addr, uint16 size_name, const uint8 *name)
{
    /* store the local friendly name of the device with this address */
    ConnectionSmPutAttribute(PS_KEY_USER_PAIRED_NAME_BASE, addr, size_name, name);
}


/****************************************************************************
NAME    
    ps_write_device_attributes - Write the device attributes to PS     
*/
void ps_write_device_attributes(const bdaddr *addr, ATTRIBUTES_T attributes)
{
    /* store the attributes of the device with this address */
    ConnectionSmPutAttribute(PS_KEY_USER_PAIRED_ATTR_BASE, addr, sizeof(attributes), (uint8*)&attributes);
}
